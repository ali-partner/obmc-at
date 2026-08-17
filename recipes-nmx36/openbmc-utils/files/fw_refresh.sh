#!/bin/bash
prog="$0"

product_name=$(cat /etc/openbmc/product_name)

usage() {
    echo "Usage: "
    echo "$prog init "
    echo "$prog refresh <type_files> <image_files>"
    echo
    echo "Commands:"
    echo "  init: init upgrade refresh result."
    echo
    echo "  refresh: Refresh to apply files."
    echo
    echo "  type_files: bios/fpga/basecpld/ocmcpld/fan1cpld/fan2cpld/misccpld/portcpld1/portcpld2/ledcpld"
    echo
}

UPGRADE_RESULT_DIR="/var/log/fw"
UPGRADE_REFRESH_RESULT_FILE="/var/log/fw/upgrade_refresh_result"
UPGRADE_CPLD_RESULT_FILE="/tmp/upgrade_cpld_result"
g_board_cpld_flag=0

function init_upgrade_refresh_result() {
    if [ ! -d $UPGRADE_RESULT_DIR ];then
        mkdir -p $UPGRADE_RESULT_DIR
        echo -ne "" > $UPGRADE_REFRESH_RESULT_FILE
    else
        echo -ne "" > $UPGRADE_REFRESH_RESULT_FILE
    fi
    return 0
}

function get_cpu_power_status() {
    local val

     val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
     if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
         return 0            # powered on
     else
         return 1
     fi
    # default is power on
    return 0
}

function power_off_cpu() {
    if get_cpu_power_status; then
        /usr/local/bin/switch_cpld.sh write 1 0x14 0x0
        if [ $? -ne 0 ]; then
            return 1
        fi
        sleep 10
        /usr/local/bin/switch_cpld.sh write 1 0x75 0x0
        if [ $? -ne 0 ]; then
            return 1
        fi
        sleep 5
    fi
    return 0
}

function power_on_cpu() {
    if get_cpu_power_status; then
        return 0
    else
        /usr/local/bin/switch_cpld.sh write 1 0x75 0x1
        if [ $? -ne 0 ]; then
            return 1
        fi
        sleep 5
        /usr/local/bin/switch_cpld.sh write 1 0x15 0x1
        if [ $? -ne 0 ]; then
            return 1
        fi
        sleep 10
        # write clear 0x4A bit 0
        /usr/sbin/i2cset -f -y 0 0x0d 0x4A 0x3
        # read clear 0x4A bit 0
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        MSR_CMD=`/usr/sbin/i2cget -f -y 0 0x0d 0x4A`
        echo "$time_stamp BMC power_on_cpu: MCERR_IERR_LATCH(${MSR_CMD})." >> /var/volatile/log/syslog
    fi
    return 0
}

function restore_system() {
    power_on_cpu
    echo "restore_system, power on CPU"
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo "restore_system, BMC reboot"
    reboot #reboot BMC
    exit 0
}

function get_switch_board_cpld_status() {
    local val

     val=$(/usr/local/bin/switch_cpld.sh read 3 0x48 2> /dev/null | head -n 1)
     if [ "$((${val} & 0x01))" != "0" ] && [ "$((${val} & 0x02))" != "0" ]; then
         return 0            # powered on
     else
         return 1
     fi
    # default is power on
    return 0
}

function power_off_switch_board_cpld() {
    if get_switch_board_cpld_status; then
        /usr/local/bin/switch_cpld.sh write 3 0x48 0x00
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    return 0
}

function power_on_switch_board_cpld() {
    if get_switch_board_cpld_status; then
        return 0
    else
        /usr/local/bin/switch_cpld.sh write 3 0x48 0x03
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    return 0
}

function system_disbale_cpu_service() {
    systemctl stop fanctrl.service
    /usr/local/bin/diag_fan.sh switch manu
    /usr/local/bin/diag_fan.sh set all 100
    # stop cpu MCERR/IERR
    systemctl stop sensor-mon.service
    sleep 1
    systemctl stop cpumon.service
    sleep 1
    systemctl stop powermon.service
    sleep 1
    systemctl stop fanctrl.service
    sleep 1
    systemctl stop dcdcmon.service
    sleep 1
    if [ $? -ne 0 ]; then
        return 1
    fi
    sleep 2
    return 0
}

# Upgrade FPGA refresh file
function upgrade_fpga_refresh() {
    power_off_cpu
    if [ $? == 0 ] ; then
        echo "FPGA : DONE" >> $UPGRADE_REFRESH_RESULT_FILE
        echo "FPGA refresh successful."
    else
        echo "FPGA : FAILED" >> $UPGRADE_REFRESH_RESULT_FILE
        echo "FPGA refresh failure."
    fi
}

function upgrade_bios_refresh() {
    power_off_cpu
    if [ $? == 0 ] ; then
        echo "BIOS : DONE" >> $UPGRADE_REFRESH_RESULT_FILE
        echo "BIOS refresh successful."
    else
        echo "BIOS : FAILED" >> $UPGRADE_REFRESH_RESULT_FILE
        echo "BIOS refresh failure."
    fi
}

function upgrade_cpld_refresh() {
    file_type=$1
    refresh_file=$2
    power_off_cpu
    ret=$?

    if [[ $file_type == "ocmcpld" || $file_type == "portcpld1" || $file_type == "portcpld2" || $file_type == "ledcpld" ]]; then
        if [ $ret == 0 ]; then
            echo "$file_type : DONE" >> $UPGRADE_REFRESH_RESULT_FILE
            echo "$file_type refresh successful."
        else
            echo "$file_type : FAILED" >> $UPGRADE_REFRESH_RESULT_FILE
            echo "$file_type refresh failure."
        fi
    else
        /usr/local/bin/cpld_update.sh refresh $file_type $refresh_file |tee $UPGRADE_CPLD_RESULT_FILE
        keyword=$(grep -c "DONE" $UPGRADE_CPLD_RESULT_FILE)
        if [ $keyword != 0 ]; then
            echo "$file_type : DONE" >> $UPGRADE_REFRESH_RESULT_FILE
            echo "$file_type refresh successful."
        else
            echo "$file_type : FAILED" >> $UPGRADE_REFRESH_RESULT_FILE
            echo "$file_type refresh failure."
        fi
    fi

    return 0
}

function fw_refresh() {
    system_disbale_cpu_service
    types_array=(${type_files//:/ })
    files_array=(${image_files//:/ })
    for i in "${!types_array[@]}";
    do
        file_type=${types_array[$i]}
        refresh_file=${files_array[$i]}
        echo "fw_refresh $file_type $refresh_file"
        if [[ $file_type == "bios" ]]; then
            upgrade_bios_refresh $refresh_file
        elif [[ $file_type == "fpga" ]]; then
            upgrade_fpga_refresh $refresh_file
        else
            upgrade_cpld_refresh $file_type $refresh_file
        fi
    done

    #cpu power on and reboot bmc
    restore_system
    return 0
}

command="$1"
type_files="$2"
image_files="$3"

case "$command" in
    init)
        if [ $# -ne 1 ]; then
            usage
            exit -1
        fi
        init_upgrade_refresh_result
        ret=$?
        exit $ret
        ;;
    refresh)
        if [ $# -ne 3 ]; then
            usage
            exit -1
        fi

        fw_refresh $type_files $image_files
        ret=$?
        exit $ret
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?

