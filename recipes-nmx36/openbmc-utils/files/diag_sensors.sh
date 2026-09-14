#!/bin/sh
#
# Copyright 2018-present Facebook. All Rights Reserved.
#
# This program file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program in a file named COPYING; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

. /usr/local/bin/openbmc-utils.sh
source /usr/local/bin/board-utils.sh

SYSFS_I2C_DEVICES="/sys/bus/i2c/devices"
SYSFS_I2C_DRIVERS="/sys/bus/i2c/drivers"
SYSFS_BRDCTL_PATH="${SYSFS_I2C_DEVICES}/1-0001"
# FANCPLD_PATH="${SYSFS_I2C_DEVICES}/8-000d"
ADC_PATH_BASE="/sys/devices/platform/ahb/ahb:apb"
BASECPLD_PATH="${SYSFS_I2C_DEVICES}/0-000d"
ERROR_FILE="/run/error_journal.tmp"
SENSORS_FILE="/run/sensors_journal.tmp"
SENSORS_LOG_FILE="/var/log/sensors_log"
has_error=0
PROGRAM_TITLE=`basename $0`
##Switch AVS chips MPS MFR ID
VENDOR_ID_MP29=0x0025

IPMB_OBJ="xyz.openbmc_project.Ipmi.Channel.Ipmb"
IPMB_PATH="/xyz/openbmc_project/Ipmi/Channel/Ipmb"
IPMB_INTF="org.openbmc.Ipmb"
IPMB_CALL="sendRequest yyyyay"
IPMB_TAIL="| awk '{gsub(/^\s+|\s+$/, "");print}'"

# Delete temporary file when exit script
trap cleanup INT TERM QUIT EXIT
cleanup(){
    echo " "
    has_error=0
    rm -rf $ERROR_FILE $SENSORS_FILE
}
i2c_check_driver_bind_opt() {
    local retry=0
    local retry_max=5
    local bus=$1
    local addr=$2
    local name=$3

    while true
    do
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        if [ $retry -ge ${retry_max} ]; then
            #echo "failed to bind ${name}(${bus}-${addr}) after ${retry} retries"
            echo "$time_stamp INFO: failed to bind ${name}(${bus}-${addr}) after ${retry} retries" >> /var/volatile/log/syslog; sync
            return 1
        fi
        i2c_driver_bind_device_check ${bus} ${addr} ${name}
        if [ "$?" -eq "0" ]; then
            break
        else
            i2c_device_rebind ${bus} ${addr} ${name}
        fi
        sleep 0.2
        retry=$((retry + 1))
    done
    return 0
}
printUsage() {
    echo "Usage: $PROGRAM_TITLE [options]"
    echo ""
    echo "Options are:"
    echo "  -h: display the help and exit."
    echo "  --help"
    echo "  -t: show all thermal sensors information."
    echo "  --temp"
    echo "  -p: show all PSUs information."
    echo "  --psu"
    echo "  -d: show all DC information."
    echo "  --dc"
    echo "  -f: show all FANs information."
    echo "  --fan"
    # echo "  -v: show all voltage information."
    # echo "  --voltage"
    echo "  -c: show all clock information."
    echo "  --clock"
    echo "  -a: show all sensors information."
    echo "  --all"
    echo ""
}


PMBUS_TIMEOUT_TIME=0x3d30
ocm_mp_device_set_timeout() {
    local name2=(OCM_MP2976_2F OCM_MP2978 OCM_MP2976_20)
    local bus2=(114 114 114)
    local addr2=(2f 1f 20)
    for((i=0; i<3; i++))
    do
        cnt=0
        while true
        do
            pnbus_timeout_get=`i2cset -f -y ${bus2[i]} 0x${addr2[i]} 0x0 0x0 b;i2cget -f -y ${bus2[i]} 0x${addr2[i]} 0xc5 w`
            if [ $? -ne 0 ]; then
                echo "i2c-1 ${name2[i]}(${bus2[i]}, 0x${addr2[i]}) read PMBUS TIMEOUT time(count=${cnt})." >> $SENSORS_LOG_FILE
                sleep 0.1
                continue
            fi
            if [ "$pnbus_timeout_get" == "${PMBUS_TIMEOUT_TIME}" ]; then
                #echo "i2c-1 ${name2[i]}(${bus2[i]}, 0x${addr2[i]}) check PMBUS TIMEOUT time. Value: ${pnbus_timeout_get}, Expect: ${PMBUS_TIMEOUT_TIME} (count=${cnt})."
                break
            fi
            ((cnt++))
            if [ $cnt -eq 11 ]; then
                echo "i2c-1 ${name2[i]}(${bus2[i]}, 0x${addr2[i]}) set PMBUS TIMEOUT time failed." >> $SENSORS_LOG_FILE
                break
            fi
            pnbus_timeout_set=`i2cset -f -y ${bus2[i]} 0x${addr2[i]} 0x0 0x0 b;i2cset -f -y ${bus2[i]} 0x${addr2[i]} 0xc5 ${PMBUS_TIMEOUT_TIME} w`
            if [ $? -ne 0 ]; then
                echo "i2c-1 ${name2[i]}(${bus2[i]}, 0x${addr2[i]}) set PMBUS TIMEOUT time(count=${cnt})." >> $SENSORS_LOG_FILE
                sleep 0.1
                continue
            fi

        done
    done
}

#
# print an lm75 device value.
# $1 - parent bus number
# $2 - device address
# $3 - device name
#
lm75_device_print() {
    local bus
    local addr
    local name
    local status
    local upper_limit
    local lower_limit
    local current_t
    local node
    bus=$"$1"
    addr="$2"
    addr=`echo ${addr#*0x}`
    name="$3"
    lower_limit=$"$4"
    upper_limit=$"$5"
    if [ -z "$6" ]; then
        node="temp1_input"
    else
        node="$6"
    fi
    lower_limit=`echo "${lower_limit}"|awk '{printf("%0.3f\n", $1)}'`
    upper_limit=`echo "${upper_limit}"|awk '{printf("%0.3f\n", $1)}'`

    if [ -f ${SYSFS_I2C_DEVICES}/i2c-${bus}/${bus}-${addr}/hwmon/hwmon*/${node} ]; then
        node_path=${SYSFS_I2C_DEVICES}/i2c-${bus}/${bus}-${addr}/hwmon/hwmon*/${node}
    elif [ -f ${SYSFS_I2C_DEVICES}/i2c-${bus}/${bus}-${addr}/${node} ]; then
        node_path=${SYSFS_I2C_DEVICES}/i2c-${bus}/${bus}-${addr}/${node}
    else
        has_error=-1
        printf "%-36s device node not exist\n" ${name} >> $ERROR_FILE
        printf "%-36s | %-10s | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} "NA" "degrees C" "NA" ${lower_limit} ${upper_limit} >> $SENSORS_FILE
        return 0
    fi

    if [ ${name} = "X86_CORE" ]; then
        current_t=`cat ${SYSFS_I2C_DEVICES}/i2c-4/4-1010/hwmon/hwmon*/host_tjmax`
    fi
    if [ ${name} = "xSFP_MAX_TEMP" ]; then
        xSFP_p=`cat ${SYSFS_I2C_DEVICES}/i2c-1/1-0003/hwmon/hwmon*/qsfp_present`
        if [ ${xSFP_p} = 0 ]; then
            return
        fi
    fi
    local current=`cat ${node_path}`
    cat ${node_path} 1>/dev/null 2>&1
    if [ $? -ne 0 ]; then
        has_error=-1
        printf "%-36s device error\n" ${name} >> $ERROR_FILE
        printf "%-36s | %-10s | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} "NA" "degrees C" "NA" ${lower_limit} ${upper_limit} >> $SENSORS_FILE
    elif [[ ${name} = "X86_CORE" && ${current} = -1 && ${current_t} = -1 ]]; then
        has_error=-1
        printf "%-36s device node not exist\n" ${name} >> $ERROR_FILE
        printf "%-36s | %-10s | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} "NA" "degrees C" "NA" ${lower_limit} ${upper_limit} >> $SENSORS_FILE
    else
        if [[ ${name} = "Temp_TPS544B25_IIC_17_0x27" || ${name} == "Temp_MAC" ]];then
            current=`echo "${current}"|awk '{printf("%0.3f\n", $1)}'`
        else
            current=`echo "${current} 1000"|awk '{printf("%0.3f\n", $1/$2)}'`
        fi
        if [[ ${name} = "xSFP_MAX_TEMP" || ${name} = "X86_CORE" ]]; then
            current=`echo "${current} 1000"|awk '{printf("%0.3f\n", $1*$2)}'`
        fi
        flag_L=`awk -v x=${current} -v y=${lower_limit} 'BEGIN{print(x>=y)?"0":"1"}'`
        flag_H=`awk -v x=${current} -v y=${upper_limit} 'BEGIN{print(y>=x)?"0":"1"}'`
        if [[ ${flag_L} -eq 1 || ${flag_H} -eq 1 ]]; then
            status="ABNORMAL"
            has_error=-1
            if [[ ${name} = "X86_CORE" && ${current} = 449.000 ]]; then
                printf "%-36s ME returns 'C1h'-Invalid Command. Used to indicate an unrecognized or unsupported command.\n" ${name} >> $ERROR_FILE
            else
                printf "%-36s NOT in range: [%-12.3f, %-12.3f]\n" ${name} ${lower_limit} ${upper_limit} >> $ERROR_FILE
            fi
        else
            status="OK"
        fi
        printf "%-36s | %-10.3f | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} ${current} "degrees C" ${status} ${lower_limit} ${upper_limit} >> $SENSORS_FILE
    fi

}



check_temp_sensors() {
    for sensor_config in "${lm75_sensor_configs[@]}"; do
        lm75_device_print $sensor_config  # 无 *，正常执行
    done
}

check_cpu_temp() {
    local CPU_str; local CPU_val1; local CPU_val2; local CPU_val; local sign_bit1; local sign_bit
    local m; local n; local temp
    # CPU0_TEMP_CMD=`/usr/local/bin/ipmb-util 13 0x2c 0xb8 0x40 0x57 0x01 0x00 0x30 0x01 0x02 0x01`
    # CPU_str=$CPU0_TEMP_CMD


    # CPU_val1=`echo $CPU_str | grep -i Com_code`
    # if [ $? -eq 0 ]; then
    #     SENSOR_TEMP=0.000
    #     return
    # fi

    # CPU_val1=`echo ${CPU_str:0-3:2}`
    # CPU_val2=`echo ${CPU_str:0-6:2}`
    # CPU_val=0x${CPU_val1}${CPU_val2}
    # sign_bit1=`echo ${CPU_str:0-3:1}`
    # sign_bit=0x${sign_bit1}

    # CPU0_TEMP_CMD=`peci_cmds raw 0x30 0x1 0x2 0x1 | awk '{gsub(/^\s+|\s+$/, "");print}'`
    # CPU_val1=`echo $CPU0_TEMP_CMD | awk '{print substr($2, 3)}'`
    # CPU_val2=`echo $CPU0_TEMP_CMD | awk '{print substr($1, 3)}'`
    # CPU_val=0x${CPU_val1}${CPU_val2}
    # sign_bit=0x`echo ${CPU_val1:0:1}`

    # if [ "$CPU_val1" == "FF" ] && [ "$CPU_val2" == "FF" ]; then
    #     SENSOR_TEMP="N/A"
    # fi

    # Tjmax_str=`/usr/local/bin/ipmb-util 13 0x2c 0xb8 0x40 0x57 0x01 0x00 0x30 0x05 0x05 0xa1 0x00 0x10 0x00 0x00`
    # Tjmax_val=0x`echo ${Tjmax_str:0-6:2}`
    # ((Tjmax=Tjmax_val))
    # Tjmax=105

    # if [ "$(($sign_bit & 0x8))" == 8 ];then
    #     m=$((~$(($CPU_val-1)) & 0xffff))
    #     n=`awk -v x=$m -v y=64 'BEGIN {printf "%.3f\n",x/y}'`
    #     SENSOR_TEMP=`awk -v x=$Tjmax -v y=$n 'BEGIN {printf "%.3f\n",x-y}'`
    # else
    #     ((m=$CPU_val))
    #     n=`awk -v x=$m -v y=64 'BEGIN {printf "%.3f\n",x/y}'`
    #     SENSOR_TEMP=`awk -v x=$Tjmax -v y=$n 'BEGIN {printf "%.3f\n",x+y}'`
    # fi

    Tjmax_str=`peci_cmds -a 0x30 RdPkgConfig 0x10 0 | awk '{print $NF}' | sed 's/0x//' | cut -c3-4`
    Tjmax_val=0x`echo ${Tjmax_str}`
    ((Tjmax=Tjmax_val))

    CPU_val=`peci_cmds GetTemp | awk -F'[()]' '{print $2}' | sed 's/C$//'`
    SENSOR_TEMP=`awk -v x=$Tjmax -v y=$CPU_val 'BEGIN {printf "%.2f\n",x+y}'`


    name="Temp_CPU"
    lower_limit=-1
    upper_limit=87
    if [[ ${SENSOR_TEMP} = "N/A" ]]; then
        has_error=-1
        printf "%-36s device node not exist\n" ${name} >> $ERROR_FILE
        printf "%-36s | %-10s | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} "NA" "degrees C" "NA" ${lower_limit} ${upper_limit} >> $SENSORS_FILE
    else
        flag_L=`awk -v x=${SENSOR_TEMP} -v y=${lower_limit} 'BEGIN{print(x>=y)?"0":"1"}'`
        flag_H=`awk -v x=${SENSOR_TEMP} -v y=${upper_limit} 'BEGIN{print(y>=x)?"0":"1"}'`
        if [[ ${flag_L} -eq 1 || ${flag_H} -eq 1 ]]; then
            status="ABNORMAL"
            has_error=-1
            printf "%-36s NOT in range: [%-12.3f, %-12.3f]\n" ${name} ${lower_limit} ${upper_limit} >> $ERROR_FILE
        else
            status="OK"
        fi
        printf "%-36s | %-10.3f | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} ${SENSOR_TEMP} "degrees C" ${status} ${lower_limit} ${upper_limit} >> $SENSORS_FILE
    fi
}


check_dimm_temp() {
    lower_limit=-3
    upper_limit=85
    DIMM_TEMP_12=`/usr/local/bin/ipmb-util 13 0x2c 0xb8 0x4B 0x57 0x01 0x00 0x00 0x33 0x30 0x33 0x30 0x00 0x00 0x00 0x00`
    DIMM_RD_TEMP[0]=$((16#`echo $DIMM_TEMP_12 | cut -d ' ' -f4`))
    DIMM_RD_TEMP[2]=$((16#`echo $DIMM_TEMP_12 | cut -d ' ' -f6`))

    name="Temp_DIMM_#1"
    if [[ ${DIMM_RD_TEMP[0]} = "N/A" ]]; then
        has_error=-1
        printf "%-36s device node not exist\n" ${name} >> $ERROR_FILE
        printf "%-36s | %-10s | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} "NA" "degrees C" "NA" ${lower_limit} ${upper_limit} >> $SENSORS_FILE
    else
        flag_L=`awk -v x=${DIMM_RD_TEMP[0]} -v y=${lower_limit} 'BEGIN{print(x>=y)?"0":"1"}'`
        flag_H=`awk -v x=${DIMM_RD_TEMP[0]} -v y=${upper_limit} 'BEGIN{print(y>=x)?"0":"1"}'`
        if [[ ${flag_L} -eq 1 || ${flag_H} -eq 1 ]]; then
            status="ABNORMAL"
            has_error=-1
            printf "%-36s NOT in range: [%-12.3f, %-12.3f]\n" ${name} ${lower_limit} ${upper_limit} >> $ERROR_FILE
        else
            status="OK"
        fi
        printf "%-36s | %-10.3f | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} ${DIMM_RD_TEMP[0]} "degrees C" ${status} ${lower_limit} ${upper_limit} >> $SENSORS_FILE
    fi

    name="Temp_DIMM_#2"
    if [[ ${DIMM_RD_TEMP[2]} = "N/A" ]]; then
        has_error=-1
        printf "%-36s device node not exist\n" ${name} >> $ERROR_FILE
        printf "%-36s | %-10s | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} "NA" "degrees C" "NA" ${lower_limit} ${upper_limit} >> $SENSORS_FILE
    else
        flag_L=`awk -v x=${DIMM_RD_TEMP[2]} -v y=${lower_limit} 'BEGIN{print(x>=y)?"0":"1"}'`
        flag_H=`awk -v x=${DIMM_RD_TEMP[2]} -v y=${upper_limit} 'BEGIN{print(y>=x)?"0":"1"}'`
        if [[ ${flag_L} -eq 1 || ${flag_H} -eq 1 ]]; then
            status="ABNORMAL"
            has_error=-1
            printf "%-36s NOT in range: [%-12.3f, %-12.3f]\n" ${name} ${lower_limit} ${upper_limit} >> $ERROR_FILE
        else
            status="OK"
        fi
        printf "%-36s | %-10.3f | %-10s | %-8s | %-12.3f | %-12.3f\n" ${name} ${DIMM_RD_TEMP[2]} "degrees C" ${status} ${lower_limit} ${upper_limit} >> $SENSORS_FILE
    fi
}



dc_device_print() {
    bus=$1
    addr=$2
    node=$3
    name=$4
    base=$5
    type=$6
    lower_limit=$7
    upper_limit=$8
    if [ -z "$9" ]; then
        multiply=1
    else
        multiply=$9
    fi
    if [ -f ${SYSFS_I2C_DEVICES}/${bus}-00${addr}/hwmon/hwmon*/${node} ]; then
        node_path=${SYSFS_I2C_DEVICES}/${bus}-00${addr}/hwmon/hwmon*/${node}
    elif [ -f ${SYSFS_I2C_DEVICES}/${bus}-00${addr}/${node} ]; then
        node_path=${SYSFS_I2C_DEVICES}/${bus}-00${addr}/${node}
    else
        has_error=-1
        printf "%-36s device node not exist\n" ${name} >> $ERROR_FILE
        printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" "${name}" "NA" "$type" "NA" "NA" "NA" >> $SENSORS_FILE
        return 0
    fi
    cnt=0
    while true
    do
        ((cnt++))
        if [ $cnt -eq 4 ]; then
            has_error=-1
            printf "%-36s device error\n" ${name} >> $ERROR_FILE
            printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" "${name}" "NA" "$type" "NA" "NA" "NA" >> $SENSORS_FILE
            break
        fi

        local value=`cat ${node_path}`
        echo "cat ${node_path} value ${value}"  >> $SENSORS_LOG_FILE
        cat ${node_path} 1>/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "cat ${node_path} operate failed"  >> $SENSORS_LOG_FILE
            continue
        else
            value=`echo "${value} ${base} ${multiply}"|awk '{printf("%0.3f\n", $1/$2*$3)}'`
            lower_limit=`echo "${lower_limit}"|awk '{printf("%0.3f\n", $1)}'`
            upper_limit=`echo "${upper_limit}"|awk '{printf("%0.3f\n", $1)}'`
            flag_L=`awk -v x=${value} -v y=${lower_limit} 'BEGIN{print(x>=y)?"0":"1"}'`
            flag_H=`awk -v x=${value} -v y=${upper_limit} 'BEGIN{print(y>=x)?"0":"1"}'`
            if [[ ${flag_L} -eq 1 || ${flag_H} -eq 1 ]]; then
                if [ $cnt -ge 3 ]; then
                    status="FAULT"
                    has_error=-1
                    printf "%-36s %-10.3f NOT in range: [%-12.3f, %-12.3f]\n" ${name} ${value} ${lower_limit} ${upper_limit} >> $ERROR_FILE
                else
                    continue
                fi
            else
                status="OK"
            fi
            printf "%-36s | %-10.3f | %-10s | %-8s | %-12.3f | %-12.3f\n" "${name}" ${value} "${type}" ${status} ${lower_limit} ${upper_limit} >> $SENSORS_FILE
            break
        fi
    done
}

check_dc_sensors() {
    for dc_config in "${dc_sensor_configs[@]}"; do
        dc_device_print $dc_config
    done
}


load_single_psu_config() {
    local config_array_name=$1
    local psu_num=$2
    local config_elements
    eval "config_elements=("\"\${${config_array_name}[@]}\"")"
    for config_item in "${config_elements[@]}"; do
        dc_device_print $config_item
    done
}
check_psu_sensors() {
    for ((psu_num=1; psu_num<=$PSU_NUM; psu_num++)); do
        local input_type=$(get_psu_input_type $psu_num)
        local config_index=$((psu_num - 1))
        local current_config_array=""
        case "$input_type" in
            "AC")
                current_config_array=${psu_ac_configs[$config_index]}
                ;;
            "DC")
                current_config_array=${psu_dc_configs[$config_index]}
                ;;
            *)
                current_config_array=${psu_ac_configs[$config_index]}
                ;;
        esac
        load_single_psu_config "$current_config_array" "$psu_num"
    done
}


check_fan_sensors(){
    thd=(0 0 20000 20000) #threshold: front_LowThd back_LowThd front_HighThd back_HighThd
    speed=() #speed: front_speed back_speed
    name=("rotor1" "rotor2")

    if [[ "$fan_board_type" == "0" ]]; then
        fan="1 2 3 4 5 6 7 8"
    elif [[ "$fan_board_type" == "1" ]]; then
        fan="1 2 3 4 5"
    fi

    for i in ${fan}
    do
        if [[ "$fan_board_type" == "0" ]]; then
            if [[ "$i" -ge 1 ]] && [[ "$i" -le 4 ]]; then
                local_index=$i
                FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
            elif [[ "$i" -ge 5 ]] && [[ "$i" -le 8 ]]; then
                local_index=$((i - 4))
                FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
            fi
            fan_index=$i
        elif [[ "$fan_board_type" == "1" ]]; then
            local_index=$i
            fan_index=$i
            FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
        fi

        dir=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_direction | sed -n 1p`
        if [ "$dir" == "0x0" ]; then
            thd=(0 0 20700 18400) #F2B
        fi

        speed[0]=`cat ${FANCPLD_SYSFS_DIR}/fan${local_index}_speed_1`
        speed[1]=`cat ${FANCPLD_SYSFS_DIR}/fan${local_index}_speed_2`

        for ((j=0; j<2; j++))
        do
            THD_L=`awk -v x=${speed[j]} -v y=${thd[j]} 'BEGIN{print(x>=y)?"0":"1"}'`
            THD_H=`awk -v x=${speed[j]} -v y=${thd[j+2]} 'BEGIN{print(x<=y)?"0":"1"}'`
            if [[ $THD_L -eq 1 || $THD_H -eq 1 ]]; then
                status="FAULT"
                has_error=-1
                printf "%-36s %-10.3f NOT in range: [%-12.3f, %-12.3f]\n" SPEED_fan${fan_index}_${name[j]} ${speed[j]} ${thd[j]} ${thd[j+2]} >> $ERROR_FILE
            else
                status="OK"
            fi
            printf "%-36s | %-10.3f | %-10s | %-8s | %-12.3f | %-12.3f\n" SPEED_fan${fan_index}_${name[j]} ${speed[j]} "RPM" ${status} ${thd[j]} ${thd[j+2]} >> $SENSORS_FILE
        done
    done
}

check_clock_sensors(){
    node=("pcie_clk_monitor_alarm_state" "pcie4_clk_monitor_alarm_state")
    rc_node=("pcie_clk_alarm_clr" "pcie4_clk_alarm_clr")
    name=("PCIe3p0_CLK" "PCIe4p0_CLK")

    for((j=0; j<${#node[*]}; j++))
    do
        node_val=`cat ${BASECPLD_PATH}/${node[j]} | head -n 1`
        if [ "${node_val}" == "0x0" ]; then
            status="OK"
        else
            status="FAULT"
            has_error=-1
            printf "%-36s status not correct\n" ${name[j]} >> $ERROR_FILE
            #read clear alarm
            read_clear=`cat ${BASECPLD_PATH}/${rc_node[j]} | head -n 1`
        fi
        printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" ${name[j]} ${node_val} "NA" ${status} "NA" "NA" >> $SENSORS_FILE
    done

}

gpio_export_dir_num_val() {
    direct=$1
    num=$"$2"
    val=$"$3"
    if [ ! -d "/sys/class/gpio/gpio${num}/" ]; then
        echo "$num" > /sys/class/gpio/export
    fi
    echo "$direct" > /sys/class/gpio/gpio"${num}"/direction
    echo "$val" > /sys/class/gpio/gpio"${num}"/value
    sleep 1
}

gpio_num_val_unexport() {
    num=$"$1"
    val=$"$2"
    echo "$val" > /sys/class/gpio/gpio"${num}"/value
    echo "$num" > /sys/class/gpio/unexport
}


adc_device_print() {
    local bus=$1
    local addr=$2
    local addr=${addr#*0x}
    local node
    node=$3
    local name
    name=$4
    local base=$5
    local type=$6
    local lower_limit=$7
    local upper_limit=$8

    addr="${addr,,}"

    if [ -z "$9" ]; then
        multiply=1
    else
        multiply=$9
    fi

    #echo "${ADC_PATH_BASE}/${bus}.adc/iio:device${addr}"

    if [[ ! -d "$ADC_PATH_BASE/$bus.adc/iio:device$addr" ]]; then
        has_error=-1
        printf "%-36s device node not exist\n" "${name}" >> $ERROR_FILE
        printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" "${name}" "NA" "$type" "NA" "NA" "NA" >> $SENSORS_FILE
    else
        value_raw=$(cat ${ADC_PATH_BASE}/"${bus}".adc/iio:device"${addr}"/"${node}")
        #echo $value_raw
        adc_scale=$(cat ${ADC_PATH_BASE}/"${bus}".adc/iio:device"${addr}"/in_voltage_scale)
        #echo $adc_scale

        #echo $adc_offset
        if ! adc_offset=$(cat ${ADC_PATH_BASE}/"${bus}".adc/iio:device"${addr}"/in_voltage_offset); then
            has_error=-1
            printf "%-36s device error\n" "${name}" >> $ERROR_FILE
            printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" "${name}" "NA" "$type" "NA" "NA" "NA" >> $SENSORS_FILE
        else
            #value=`echo "${value} ${base} ${multiply}"|awk '{printf("%0.3f\n", $1/$2*$3)}'`
            #val[i]=`echo "$adc_raw $adc_offset $adc_scale 1000" | awk '{printf("%0.9f\n", ($1-$2)*$3/$4)}'`
            value_1=$(echo "$value_raw $adc_offset $adc_scale $base" | awk '{printf("%0.3f\n", ($1+$2)*$3/$4)}')
            #echo "$value_1 $value_raw $adc_offset $adc_scale $base"
            value=$(echo "${value_1} ${multiply}"|awk '{printf("%0.3f\n", $1*$2)}')
            lower_limit=$(echo "${lower_limit}"|awk '{printf("%0.3f\n", $1)}')
            upper_limit=$(echo "${upper_limit}"|awk '{printf("%0.3f\n", $1)}')
            #echo "$value $lower_limit $upper_limit ${multiply}"
            flag_L=$(awk -v x="${value}" -v y="${lower_limit}" 'BEGIN{print(x>=y)?"0":"1"}')
            flag_H=$(awk -v x="${value}" -v y="${upper_limit}" 'BEGIN{print(y>=x)?"0":"1"}')
            if [[ ${flag_L} -eq 1 || ${flag_H} -eq 1 ]]; then
                status="FAULT"
                has_error=-1
                printf "%-36s %-10.3f NOT in range: [%-12.3f, %-12.3f]\n" "${name}" "${value}" "${lower_limit}" "${upper_limit}" >> $ERROR_FILE
            else
                status="OK"
            fi
            printf "%-36s | %-10.3f | %-10s | %-8s | %-12.3f | %-12.3f\n" "${name}" "${value}" "${type}" "${status}" "${lower_limit}" "${upper_limit}" >> $SENSORS_FILE
        fi
    fi
}

check_voltage_bmc_adc() {
    adc_device_print    1e6e9100  1    in_voltage1_raw     BMC_P3V3_RGM        1000                Volts       3.135     3.465     2.000
    gpio_export_dir_num_val out 829 1
    adc_device_print    1e6e9100  1    in_voltage2_raw     VCC_BAT_3V          1000                Volts       2.000     3.400     2.000
    gpio_num_val_unexport 829 0
    adc_device_print    1e6e9100  1    in_voltage3_raw     BMC_P1V2            1000                Volts       1.140     1.260
    adc_device_print    1e6e9100  1    in_voltage4_raw     BMC_P1V0            1000                Volts       0.950     1.050
    adc_device_print    1e6e9100  1    in_voltage5_raw     BMC_P1V8            1000                Volts       1.656     1.944     1.667
    adc_device_print    1e6e9100  1    in_voltage6_raw     BMC_P0V6            1000                Volts       0.570     0.630
    adc_device_print    1e6e9100  1    in_voltage7_raw     BMC_P2V5            1000                Volts       2.375     2.625     1.667
}

# Parse the command line and set variables to control logic
parseCommandLine() {

    # Special case that nothing was provided on the command line so print usage
    if [ "$#" -eq 0 ]; then
        printUsage
        exit 0
    fi

    # Indicate specification for single character options
    # - 1 colon after an option indicates that an argument is required
    # - 2 colons after an option indicates that an argument is optional, must use -o=argument syntax
    optstring="htpdfvca"

    # Indicate specification for long options
    # - 1 colon after an option indicates that an argument is required
    # - 2 colons after an option indicates that an argument is optional, must use --option=argument syntax
    optstringLong="help,temp,psu,dc,fan,voltage,clock,all"

    GETOPT_OUT=`getopt --options ${optstring} --long ${optstringLong} -- "$@"`
    if [ $? != 0 ]; then
        echo ""
        printUsage
        exit 1
    fi

    eval set -- "${GETOPT_OUT}"

    while true
    do
        case "$1" in
            -h|--help)
                printUsage
                exit 0
                ;;
            -t|--temp)
                printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" Name Value Units Status Lower_Limit Upper_Limit
                check_cpu_temp
                # check_dimm_temp
                check_temp_sensors
                cat $SENSORS_FILE
                if [ $has_error -eq -1 ]; then
                    printf "\nTemperature sensor abnormal:\n"
                    cat $ERROR_FILE
                fi
                shift
                ;;
            -p|--psu)
                printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" Name Value Units Status Lower_Limit Upper_Limit
                check_psu_sensors
                cat $SENSORS_FILE
                if [ $has_error -eq -1 ]; then
                    printf "\nPSU sensor abnormal:\n"
                    cat $ERROR_FILE
                fi
                shift
                ;;
            -d|--dc)
                printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" Name Value Units Status Lower_Limit Upper_Limit
                check_dc_sensors
                cat $SENSORS_FILE
                if [ $has_error -eq -1 ]; then
                    printf "\nDC sensor abnormal:\n"
                    cat $ERROR_FILE
                fi
                shift
                ;;
            -f|--fan)
                printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" Name Value Units Status Lower_Limit Upper_Limit
                check_fan_sensors
                cat $SENSORS_FILE
                if [ $has_error -eq -1 ]; then
                    printf "\nFAN sensor abnormal:\n"
                    cat $ERROR_FILE
                fi
                shift
                ;;
            # -v|--voltage)
            #     printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" Name Value Units Status Lower_Limit Upper_Limit
            #     check_voltage_bmc_adc
            #     cat $SENSORS_FILE
            #     if [ $has_error -eq -1 ]; then
            #         printf "\nVoltage sensor abnormal:\n"
            #         cat $ERROR_FILE
            #     fi
            #     shift
            #     ;;
            -c|--clock)
                printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" Name Value Units Status Lower_Limit Upper_Limit
                check_clock_sensors
                cat $SENSORS_FILE
                if [ $has_error -eq -1 ]; then
                    printf "\nClock sensor abnormal:\n"
                    cat $ERROR_FILE
                fi
                shift
                ;;
            -a|--all)
                printf "%-36s | %-10s | %-10s | %-8s | %-12s | %-12s\n" Name Value Units Status Lower_Limit Upper_Limit
                check_psu_sensors
                check_dc_sensors
                check_fan_sensors
                check_cpu_temp
                # check_dimm_temp
                check_temp_sensors
                # check_voltage_bmc_adc
                check_clock_sensors
                cat $SENSORS_FILE
                if [ $has_error -eq -1 ]; then
                    printf "\nSensor abnormal:\n"
                    cat $ERROR_FILE
                fi
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo ""
                echo "Invalid option $1." >&2
                printUsage
                exit 1
                ;;
            \?)
                printUsage
                exit 0
                ;;
        esac
    done
}

# Start of the script.
. /usr/local/bin/openbmc-utils.sh
fan_board_type=$(get_fan_board_type)
parseCommandLine "$@"

exit 0
