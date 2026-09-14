#!/bin/bash


source /usr/local/bin/openbmc-utils.sh
debug=0
BIOS_CHIP="W25Q512JV"
FPGA_ID="ff c2 20 19"
SPI_RESULT_FILE="/tmp/spi_test_result_file"
BIOS_FLASH_INIT=0

usage() {
    echo "Usage: $0 [check|stress]"
    echo
}

function cleanup_spi(){
    echo "Unbind spi flash"
    echo "14010000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/unbind
    echo "Caught Signal: reset spi selecth"
    /usr/local/bin/switch_cpld.sh write 1 0x28 0x59
    set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_update_ctl 7
    set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_sel 0
    /usr/local/bin/switch_cpld.sh write 1 0x28 0x4e
}

# $1: sysfs path, $2: value
function set_sysfs_value() {
    local path=$1
    local val=$(printf 0x%x $2)
    local ret=-1
    local retry=3
    echo "set $val to $path."
    while [ $ret != $val ] && [ $retry -gt 0 ];
    do
        echo $val > $path
        usleep 100
        ret=$(head -n1 $path 2> /dev/null)
        ((retry--))
    done
    if [ $ret != $val ]; then
        echo "debug cmd: set_sysfs_value fail, val=$val, ret=$ret"
        return -1
    fi
}

function dump_gpio_config(){
    if [ $debug = 0 ]; then
        return 0
    fi
    echo "Dump SPI configurations..."
    if [ $1 = "SPI1" ];then
        openbmc_gpio_util.py dump | grep SPI1
    else
        openbmc_gpio_util.py dump | grep SPI2
    fi
}

function set_spi1_to_spi(){
    devmem_clear_bit $(scu_addr 90) 6
    devmem_set_bit $(scu_addr 70) 12
    dump_gpio_config SPI1
}

function config_spi0_pin_and_path(){
    dev=$1

    case ${dev} in
        "MAIN_BIOS")
            /usr/local/bin/switch_cpld.sh write 1 0x28 0x59
            set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_sel 1 ### select update bios
            set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_update_ctl 13 ### 0xd select bmc update main bios
            /usr/local/bin/switch_cpld.sh write 1 0x28 0x4e
            if [ -d "/sys/bus/platform/drivers/spi-aspeed-smc/14010000.spi" ]; then
                echo "14010000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/unbind
            fi
            sleep 1
            echo "14010000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/bind

        ;;
        "BACKUP_BIOS")
            /usr/local/bin/switch_cpld.sh write 1 0x28 0x59
            set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_sel 1 ### select update bios
            set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_update_ctl 14 ### 0xe select bmc update backup bios
            /usr/local/bin/switch_cpld.sh write 1 0x28 0x4e
            if [ -d "/sys/bus/platform/drivers/spi-aspeed-smc/14010000.spi" ]; then
                echo "14010000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/unbind
            fi
            sleep 1
            echo "14010000.spi" > /sys/bus/platform/drivers/spi-aspeed-smc/bind

        ;;
        *)
            echo "Please enter {MAIN_BIOS, BACKUP_BIOS}"
            exit -1
        ;;
    esac
    echo "Config SPI0 Done."
}

do_cpu_me_recovery(){
    cnt=0
    date_time=`date`
    echo "Before set ME recovery $date_time"
    ##config ME to recovery mode
    ipmb-util 13 0x2c 0xb8 0xdf 0x57 0x1 0x00 0x1
    while true
    do
        sleep 0.5
        ##check ME recovery mode
        me_status_str=`ipmb-util 13 0x2c 0x18 0x04`
        me_status=${me_status_str:0:5}
        echo $me_status
        if [ "$me_status" == "81 02" ]; then
            echo "Set ME recovery mode success."
            break
        else
            ((cnt++))
        fi
        if [ $cnt -eq 30 ]; then
            echo "Set ME recovery mode fail."
            return -1
        fi
    done
    return 0
}

do_cpu_me_default(){
    cnt=0
    date_time=`date`
    echo "Before set ME default $date_time"
    ##config ME recovery mode to default
    ipmb-util 13 0x2c 0x18 0x02
    while true
    do
        sleep 0.5
        ##check ME default mode
        me_status_str=`ipmb-util 13 0x2c 0x18 0x04`
        me_status=${me_status_str:0:5}
        echo $me_status
        if [ "$me_status" == "80 03" ]; then
            echo "Exit ME recovery mode success."
            break
        else
            ((cnt++))
        fi
        if [ $cnt -eq 30 ]; then
            echo "Exit ME recovery mode fail."
            return -1
        fi
    done
    return 0
}
files=("/dev/mtd12"  "/dev/mtdblock12"  "/dev/mtd12ro")
spi0_dev_check()
{
    local obj=$1
    local count=0
    local flag=0
    local check_num=0
    config_spi0_pin_and_path $obj

    while [ $count -lt 10 ]
    do
        for file in "${files[@]}"; do
            if [ -e "$file" ]; then
                echo "DEBUG: spi0_dev_check $dev $file OK"
                flag=$((1+flag))
                if [ $flag -eq 3 ];then
                    #echo "find all device"
                    cleanup_spi
                    sleep 2
                    return 0
                fi
            else
                echo "$obj probe: The target string $file is not found."
                sleep 1
                flag=0
                break
            fi
        done
        count=$((1+count))
        #echo "check device ....$count"
    done
    cleanup_spi
    return 1
}

spi0_check(){
    has_error=0
    for dev in MAIN_BIOS BACKUP_BIOS
    do
        #echo "Check SPI0 $dev ..."
        cnt=0
        while true
        do
            ((cnt++))
            if [ $cnt -eq 3 ]; then
                echo "Check SPI0 $dev failed."
                has_error=-1
                break
            fi
            spi0_dev_check $dev
            status=$?
            if [ $status == 0 ]; then
                echo "Check SPI0 $dev passed."
                break
            else
                echo "Check SPI0 $dev failed(count=${cnt})."
                sleep 0.1
                continue
            fi
        done
    done

    return $has_error
}



simulate_spi_check(){
    local has_error=0
    local cnt=0
    while true
    do
        ((cnt++))
        retval=`/usr/local/bin/fpga_flash.sh readid`
        echo $retval
        if [ $cnt -eq 3 ]; then
            echo $retval >> $SPI_RESULT_FILE
            echo "Check FPGA simulate SPI  failed."
            has_error=-1
            break
        fi
        readid=`echo $retval | grep "$FPGA_ID"`
        if [ "$readid" != "" ]; then
            echo "Check FPGA simulate SPI  passed."
            break
        else
            echo "Check FPGA simulate SPI (count=${cnt})."
            sleep 0.2
            continue
        fi
    done
    return $has_error
}

spi_check_result(){

    RESULT_STR=`cat $SPI_RESULT_FILE | grep "fail"`
    if [ "$RESULT_STR" == "" ]; then
        echo "SPI test: PASS."
    else
        echo "$RESULT_STR"
        echo "SPI test: FAIL"
    fi
    return 0
}

spi_check(){
    local has_error=0
    echo "" >  $SPI_RESULT_FILE
    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$time_stamp" >> $SPI_RESULT_FILE
    simulate_spi_check >> $SPI_RESULT_FILE
    if [ $? -ne 0 ];then
        echo "Check FPGA simulate SPI failed"  >> $SPI_RESULT_FILE
        has_error=-1
    fi
    /usr/local/bin/switch_cpld.sh  write 1 0x14 0x0
    sleep 8
    if [ $? -ne 0 ];then
        has_error=-1
    fi
    /usr/local/bin/switch_cpld.sh write 1 0x75 0x0
    if [ $? -ne 0 ];then
        has_error=-1
    fi
    sleep 2
    BIOS_FLASH_INIT=`cat $BASECPLD_SYSFS_DIR/bios_flash_update_ctl | sed -n 1p`
    echo "spi_check BIOS_FLASH_INIT: $BIOS_FLASH_INIT"
    #do_cpu_me_recovery
    spi0_check >> $SPI_RESULT_FILE
    if [ $? -ne 0 ];then
        echo "Check SPI1 failed"  >> $SPI_RESULT_FILE
        has_error=-1
    fi
    #cleanup_spi
    #do_cpu_me_default
    /usr/local/bin/switch_cpld.sh write 1 0x75 0x1
    if [ $? -ne 0 ];then
        has_error=-1
    fi
    sleep 5
    /usr/local/bin/switch_cpld.sh write 1 0x15 0x1
    if [ $? -ne 0 ];then
        has_error=-1
    fi
    sleep 8
    if [ $has_error -eq 0 ];then
        echo "Check SPI bus: PASS" >> $SPI_RESULT_FILE
    else
        echo "Check SPI bus: FAIL" >> $SPI_RESULT_FILE
    fi
    return $has_error
}

spi_stress(){
    echo "" >  $SPI_RESULT_FILE
    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$time_stamp" >> $SPI_RESULT_FILE
    echo "Start SPI stress test..." >> $SPI_RESULT_FILE
    LOOP_MAX=100
    loop_count=0
    local has_error=0
    while [ $loop_count -lt $LOOP_MAX ]
    do
        simulate_spi_check >> $SPI_RESULT_FILE
        if [ $? -ne 0 ];then
            has_error=-1
        fi
        sleep 0.05
        if [ $has_error -ne 0 ];then
            echo "Check FPGA simulate SPI bus stress test failed (loop $loop_count)." >> $SPI_RESULT_FILE
            break
        fi

        loop_count=$((1+$loop_count))
        if [ 0 -eq $(($loop_count%20)) ]; then
            echo "test FPGA simulate SPI bus loop: $loop_count"
            echo "test FPGA simulate SPI bus loop: $loop_count" >> $SPI_RESULT_FILE
        fi
    done

    /usr/local/bin/switch_cpld.sh write 1 0x14 0x0
    sleep 8
    if [ $? -ne 0 ];then
        has_error=-1
    fi
    /usr/local/bin/switch_cpld.sh write 1 0x75 0x0
    if [ $? -ne 0 ];then
        has_error=-1
    fi
    sleep 2
    BIOS_FLASH_INIT=`cat $BASECPLD_SYSFS_DIR/bios_flash_update_ctl | sed -n 1p`
    echo "spi_stress BIOS_FLASH_INIT: $BIOS_FLASH_INIT"
    #do_cpu_me_recovery
    loop_count=0
    while [ $loop_count -lt $LOOP_MAX ]
    do
        spi0_check >>  $SPI_RESULT_FILE
        if [ $? -ne 0 ];then
            has_error=-1
        fi
        if [ $has_error -ne 0 ];then
            echo "Check SPI0 bus failed (loop $loop_count)." >> $SPI_RESULT_FILE
            break
        fi

        loop_count=$((1+$loop_count))
        if [ 0 -eq $(($loop_count%20)) ]; then
            echo "test SPI0 bus loop: $loop_count"
            echo "test SPI0 bus loop: $loop_count" >> $SPI_RESULT_FILE
        fi
    done
    #cleanup_spi
    #do_cpu_me_default
    /usr/local/bin/switch_cpld.sh write 1 0x75 0x1
    if [ $? -ne 0 ];then
        has_error=-1
    fi
    sleep 5
    /usr/local/bin/switch_cpld.sh write 1 0x15 0x1
    if [ $? -ne 0 ];then
        has_error=-1
    fi
    sleep 8
    if [ $has_error -eq 0 ];then
        echo "SPI stress test: PASS" >> $SPI_RESULT_FILE
    else
        echo "SPI stress test: FAIL" >> $SPI_RESULT_FILE
    fi

    return $has_error
}

if [ $# -ne 1 ]; then
    usage
    exit -1
fi

spi_gpio_init() {
    if [ -d /sys/bus/platform/drivers/spi_gpio/spi ]; then
        echo spi > /sys/bus/platform/drivers/spi_gpio/unbind
	fi
    gpio_export_by_name aspeed-gpio GPIOP6 GPIO_SPI_CS1
	gpio_export_by_name aspeed-gpio GPIOP1 GPIO_SPI_SCK
	gpio_export_by_name aspeed-gpio GPIOP3 GPIO_SPI_MISO
	gpio_export_by_name aspeed-gpio GPIOP2 GPIO_SPI_MOSI
}

spi_gpio_cleanup() {
    gpio_unexport GPIO_SPI_CS1
    gpio_unexport GPIO_SPI_SCK
    gpio_unexport GPIO_SPI_MISO
    gpio_unexport GPIO_SPI_MOSI
    if [ ! -d /sys/bus/platform/drivers/spi_gpio/spi ]; then
        echo spi > /sys/bus/platform/drivers/spi_gpio/bind
	fi
}

spi_gpio_init

object=$1

case "$object" in
    check)
        spi_check
        ;;
    stress)
        spi_stress
        ;;
    check_result)
        spi_check_result
        ;;
    *)
        usage
        exit -1
        ;;
esac

spi_gpio_cleanup
exit $?
