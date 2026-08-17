#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

FAN_WATCHDOG_ENABLE="0x1"
FAN_WATCHDOG_DISABLE="0x0"

usage() {
    echo "Usage: "
    echo "$prog enable"
    echo "$prog disable"
    echo "$prog status"
}

do_enable_fan_watchdong()
{
    if [[ "$fan_board_type" == "0" ]]; then
        echo ${FAN_WATCHDOG_ENABLE} > ${FAN1CPLD_SYSFS_DIR}/fan_watchdog_en
        echo ${FAN_WATCHDOG_ENABLE} > ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_en
    elif [[ "$fan_board_type" == "1" ]]; then
        echo ${FAN_WATCHDOG_ENABLE} > ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_en
    fi
}

do_disable_fan_watchdong()
{
    if [[ "$fan_board_type" == "0" ]]; then
        echo ${FAN_WATCHDOG_DISABLE} > ${FAN1CPLD_SYSFS_DIR}/fan_watchdog_en
        echo ${FAN_WATCHDOG_DISABLE} > ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_en
    elif [[ "$fan_board_type" == "1" ]]; then
        echo ${FAN_WATCHDOG_DISABLE} > ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_en
    fi
}

do_get_fan_watchdog_status()
{
    if [[ "$fan_board_type" == "0" ]]; then
        st1_str=`cat ${FAN1CPLD_SYSFS_DIR}/fan_watchdog_normal`
        st0_str=`cat ${FAN1CPLD_SYSFS_DIR}/fan_watchdog_timeout`
        enable_str=`cat ${FAN1CPLD_SYSFS_DIR}/fan_watchdog_en`
        st1=${st1_str:0:3}
        st0=${st0_str:0:3}
        enable_st=${enable_str:0:3}
        if [ "$enable_st" == "0x0" ]; then
            echo "Fan1 board Fan watchdog status: Disable"
        else
            if [ "$st1" == "0x0" ] && [ "$st0" == "0x1" ]; then
                echo "Fan1 board Fan watchdog status: Normal"
            elif [ "$st1" == "0x1" ] && [ "$st0" == "0x0" ]; then
                echo "Fan1 board Fan watchdog status: Timeout"
            else
                echo "Fan1 board Fan watchdog status: N/A"
            fi
        fi

        st1_str=`cat ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_normal`
        st0_str=`cat ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_timeout`
        enable_str=`cat ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_en`
        st1=${st1_str:0:3}
        st0=${st0_str:0:3}
        enable_st=${enable_str:0:3}
        if [ "$enable_st" == "0x0" ]; then
            echo "Fan2 board Fan watchdog status: Disable"
        else
            if [ "$st1" == "0x0" ] && [ "$st0" == "0x1" ]; then
                echo "Fan2 board Fan watchdog status: Normal"
            elif [ "$st1" == "0x1" ] && [ "$st0" == "0x0" ]; then
                echo "Fan2 board Fan watchdog status: Timeout"
            else
                echo "Fan2 board Fan watchdog status: N/A"
            fi
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        st1_str=`cat ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_normal`
        st0_str=`cat ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_timeout`
        enable_str=`cat ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_en`
        st1=${st1_str:0:3}
        st0=${st0_str:0:3}
        enable_st=${enable_str:0:3}
        if [ "$enable_st" == "0x0" ]; then
            echo "Fan watchdog status: Disable"
            return 0
        fi
        if [ "$st1" == "0x0" ] && [ "$st0" == "0x1" ]; then
            echo "Fan watchdog status: Normal"
        elif [ "$st1" == "0x1" ] && [ "$st0" == "0x0" ]; then
            echo "Fan watchdog status: Timeout"
        else
            echo "Fan watchdog status: N/A"
        fi
    fi
}


if [ $# -lt 1 ]; then
    usage
    exit -1
fi

command="$1"

fan_board_type=$(get_fan_board_type)

case "$command" in
    enable)
        do_enable_fan_watchdong
        ;;
    disable)
        do_disable_fan_watchdong
        ;;
    status)
        do_get_fan_watchdog_status
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
