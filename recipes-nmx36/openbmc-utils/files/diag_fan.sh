#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

#FANCPLD_PATH="/sys/bus/i2c/devices/8-000d"
fan_air="1 2 3 4 5 6 7 8"
fan_liquid="1 2 3 4 5"

usage() {
    echo "Usage: $0 [status|get]"
    echo
    echo "Usage: $0 set [fan:air:1-8,all;liquid:1-5,all] [pwm:30-100]"
    if [ "$fan_board_type" == "0" ]; then
        echo "Usage: $0 set [fan:1-8,all] [pwm:30-100]"
    else
        echo "Usage: $0 set [fan:1-5,all] [pwm:30-100]"
    fi
    echo "    30-100: set fan PWM to 30-100"
    echo
    echo "Usage: $0 switch [manu|auto]"
    echo "    manu: Fans switch to control speed manually"
    echo "    auto: Fans switch to control speed automatically"
    echo
}

fan_status(){
    echo "Judge fan presence: "

    if [[ "$fan_board_type" == "0" ]]; then
        for i in ${fan_air}
        do
            if (( i % 2 == 1 )); then
                local_index=$(((i + 1) / 2))
                FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
            else
                local_index=$((i / 2))
                FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
            fi

            alive=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_present | sed -n 1p`
            if [ "$alive" == "0x0" ]; then
                echo "fan${i}: alive"
            else
                echo "fan${i}: bad"
            fi
            sleep 0.1
        done
    elif [[ "$fan_board_type" == "1" ]]; then
        for i in ${fan_liquid}
        do
            alive=`cat ${FAN2CPLD_SYSFS_DIR}/fantray${i}_present | sed -n 1p`
            if [ "$alive" == "0x0" ]; then
                echo "fan${i}: alive"
            else
                echo "fan${i}: bad"
            fi
            sleep 0.1
        done
    fi
}

get_speed(){
    if [[ "$fan_board_type" == "0" ]]; then
        for i in ${fan_air}
        do
            if (( i % 2 == 1 )); then
                local_index=$(((i + 1) / 2))
                FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
            else
                local_index=$((i / 2))
                FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
            fi

            front_rpm=`cat ${FANCPLD_SYSFS_DIR}/fan${local_index}_speed_1`
            rear_rpm=`cat ${FANCPLD_SYSFS_DIR}/fan${local_index}_speed_2`
            echo "Fan $i RPMs: ${front_rpm}, ${rear_rpm}"
            sleep 0.1
        done
    elif [[ "$fan_board_type" == "1" ]]; then
        for i in ${fan_liquid}
        do
            front_rpm=`cat ${FAN2CPLD_SYSFS_DIR}/fan${i}_speed_1`
            rear_rpm=`cat ${FAN2CPLD_SYSFS_DIR}/fan${i}_speed_2`
            echo "Fan $i RPMs: ${front_rpm}, ${rear_rpm}"
            sleep 0.1
        done
    fi
}

set_pwm(){
    if [ "$fan_board_type" == "0" ]; then
        if [[ "$1" != "all" && "$1" != "1" && "$1" != "2" && "$1" != "3" && "$1" != "4" && "$1" != "5" && "$1" != "6" && "$1" != "7" && "$1" != "8" ]]; then
            usage
            exit -1
        fi
    else
        if [[ "$1" != "all" && "$1" != "1" && "$1" != "2" && "$1" != "3" && "$1" != "4" && "$1" != "5" ]]; then
            usage
            exit -1
        fi
    fi

    if [ -n "`echo $2 | sed 's/[0-9]//g'`" ]; then
        usage
        exit -1
    fi

    if [[ $2 -lt 30 || $2 -gt 100 ]]; then
        usage
        exit -1
    else
        pwm=$2
    fi

    if [[ "$fan_board_type" == "0" ]]; then
        if [ "$1" == "all" ]; then
            for i in ${fan_air}
            do
                if (( i % 2 == 1 )); then
                    local_index=$(((i + 1) / 2))
                    FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
                else
                    local_index=$((i / 2))
                    FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
                fi
                echo "Set fan${i} pwm to ${pwm}"
                echo $pwm > ${FANCPLD_SYSFS_DIR}/fantray${local_index}_pwm
            done
        else
            if (( $1 % 2 == 1 )); then
                local_index=$((($1 + 1) / 2))
                FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
            else
                local_index=$(($1 / 2))
                FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
            fi
            echo "Set fan${1} pwm to ${pwm}"
            echo $pwm > ${FANCPLD_SYSFS_DIR}/fantray${local_index}_pwm
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        if [ "$1" == "all" ]; then
            for i in ${fan_liquid}
            do
                echo "Set fan${i} pwm to ${pwm}"
                echo $pwm > ${FAN2CPLD_SYSFS_DIR}/fantray${i}_pwm
            done
        else
            echo "Set ${fan_board} board fan${1} pwm to ${pwm}"
            echo $pwm > ${FAN2CPLD_SYSFS_DIR}/fantray${1}_pwm
        fi
    fi
}

do_fan_status()
{
    count_num=`ps -w | grep -iE 'fand.pyc' | sed -n '$='`
	if [ "$count_num" == "1" ]; then
		echo "The fanctrl status is manu"
	else
		echo "The fanctrl status is auto"
	fi
    exit 0
}
#systemctl status fanctrl
switch_pattern(){
    if [ "$1" == "manu" ]; then
        fan_watchdog.sh disable
        systemctl stop fanctrl.service
        sleep 0.5
        diag_wdt.sh 1 off
    elif [ "$1" == "auto" ]; then
        fan_watchdog.sh enable
        systemctl start fanctrl.service
        sleep 0.5
    elif [ "$1" == "status" ]; then
        do_fan_status
	else
        usage
        exit -1
    fi
}


fan_board_type=$(get_fan_board_type)

if [ $# -ne 1 ] && [ $# -ne 2 ] &&[ $# -ne 3 ]; then
    usage
    exit -1
fi

object="$1"

case "$object" in
    status)
        fan_status
        ;;
    get)
        get_speed
        ;;
    set)
        set_pwm $2 $3
        ;;
    switch)
        switch_pattern $2
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
