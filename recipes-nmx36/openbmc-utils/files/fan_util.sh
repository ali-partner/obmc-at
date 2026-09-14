#!/bin/bash
. /usr/local/bin/openbmc-utils.sh
source /usr/local/bin/board-utils.sh

prog="$0"
usage() {
    echo "Usage: "
    echo "    $prog get <fan_index> speed"
    echo "    $prog get <fan_index> pwm"
    echo "    $prog get <fan_index> status"
    echo "    $prog get <fan_index> powergood"
    echo "    $prog get <fan_index> direction"
    echo "    $prog set <fan_index> pwm <pwm_value>"
    #echo "$prog set <fan_index> led <color>"
    echo
    echo "Commands:"
    if [ "$fan_board_type" == "0" ]; then
        echo "    fan_index: 1/2/3/4/5/6/7/8/all."
        echo
    else
        echo "    fan_index: 1/2/3/4/5/all."
        echo
    fi
    echo "    pwm_value: 30-100."
    echo
    #echo "  color: green/blink_green/red/blink_red/yellow/blink_yellow"
    #echo
}

do_get_fan_speed_by_fan_index()
{
    index=$1
    local_index=""
    FANCPLD_SYSFS_DIR=""

    echo "index: $index"
    if [[ "$fan_board_type" == "0" ]]; then
        if (( index % 2 == 1 )); then
            local_index=$(((index + 1) / 2))
            FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
        else
            local_index=$((index / 2))
            FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        local_index=$index
        FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
    fi

    speed1=`cat ${FANCPLD_SYSFS_DIR}/fan${local_index}_speed_1`
    speed2=`cat ${FANCPLD_SYSFS_DIR}/fan${local_index}_speed_2`
    echo "FAN$index speed1: $speed1"
    echo "FAN$index speed2: $speed2"
}

do_get_fan_speed()
{
    echo "get fan speed:"
    if [[ "$fan_board_type" == "0" ]]; then
        if [[ "$1" == "all" ]]; then
            # if [[ ${FAN_BOARD_TYPE_SYSFS} == 0 ]]
            do_get_fan_speed_by_fan_index 1
            do_get_fan_speed_by_fan_index 2
            do_get_fan_speed_by_fan_index 3
            do_get_fan_speed_by_fan_index 4
            do_get_fan_speed_by_fan_index 5
            do_get_fan_speed_by_fan_index 6
            do_get_fan_speed_by_fan_index 7
            do_get_fan_speed_by_fan_index 8
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 8 ]]; then
            do_get_fan_speed_by_fan_index $1
        else
            usage
            exit -1
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        if [[ "$1" == "all" ]]; then
            # if [[ ${FAN_BOARD_TYPE_SYSFS} == 0 ]]
            do_get_fan_speed_by_fan_index 1
            do_get_fan_speed_by_fan_index 2
            do_get_fan_speed_by_fan_index 3
            do_get_fan_speed_by_fan_index 4
            do_get_fan_speed_by_fan_index 5
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 5 ]]; then
            do_get_fan_speed_by_fan_index $1
        else
            usage
            exit -1
        fi
    fi
}

do_get_fan_pwm_by_fan_index()
{
    index=$1
    local_index=""
    FANCPLD_SYSFS_DIR=""

    if [[ "$fan_board_type" == "0" ]]; then
        if (( index % 2 == 1 )); then
            local_index=$(((index + 1) / 2))
            FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
        else
            local_index=$((index / 2))
            FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        local_index=$index
        FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
    fi

    pwm=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_pwm`
    echo "FAN$index pwm: $pwm"
}

do_get_fan_pwm()
{
    echo "get fan pwm:"
    if [[ "$fan_board_type" == "0" ]]; then
        if [[ "$1" == "all" ]]; then
            do_get_fan_pwm_by_fan_index 1
            do_get_fan_pwm_by_fan_index 2
            do_get_fan_pwm_by_fan_index 3
            do_get_fan_pwm_by_fan_index 4
            do_get_fan_pwm_by_fan_index 5
            do_get_fan_pwm_by_fan_index 6
            do_get_fan_pwm_by_fan_index 7
            do_get_fan_pwm_by_fan_index 8
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 8 ]]; then
            do_get_fan_pwm_by_fan_index $1
        else
            usage
            exit -1
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        if [[ "$1" == "all" ]]; then
            do_get_fan_pwm_by_fan_index 1
            do_get_fan_pwm_by_fan_index 2
            do_get_fan_pwm_by_fan_index 3
            do_get_fan_pwm_by_fan_index 4
            do_get_fan_pwm_by_fan_index 5
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 5 ]]; then
            do_get_fan_pwm_by_fan_index $1
        else
            usage
            exit -1
        fi
    fi
}

do_get_fan_status_by_fan_index()
{
    index=$1
    local_index=""
    FANCPLD_SYSFS_DIR=""

    if [[ "$fan_board_type" == "0" ]]; then
        if (( index % 2 == 1 )); then
            local_index=$(((index + 1) / 2))
            FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
        else
            local_index=$((index / 2))
            FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        local_index=$index
        FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
    fi

    status_str=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_present`
    status=${status_str:0:3}
    if [[ "$status" == "0x0" ]]; then
        echo "FAN$index status: Alive"
    elif [[ "$status" == "0x1" ]]; then
        echo "FAN$index status: Bad"
    fi

}

do_get_fan_status()
{
    echo "get fan status:"
    if [[ "$fan_board_type" == "0" ]]; then
        if [[ "$1" == "all" ]]; then
            do_get_fan_status_by_fan_index 1
            do_get_fan_status_by_fan_index 2
            do_get_fan_status_by_fan_index 3
            do_get_fan_status_by_fan_index 4
            do_get_fan_status_by_fan_index 5
            do_get_fan_status_by_fan_index 6
            do_get_fan_status_by_fan_index 7
            do_get_fan_status_by_fan_index 8
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 8 ]]; then
            do_get_fan_status_by_fan_index $1
        else
            usage
            exit -1
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        if [[ "$1" == "all" ]]; then
            do_get_fan_status_by_fan_index 1
            do_get_fan_status_by_fan_index 2
            do_get_fan_status_by_fan_index 3
            do_get_fan_status_by_fan_index 4
            do_get_fan_status_by_fan_index 5
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 5 ]]; then
            do_get_fan_status_by_fan_index $1
        else
            usage
            exit -1
        fi
    fi
}

do_get_fan_direction_by_fan_index()
{
    index=$1
    local_index=""
    FANCPLD_SYSFS_DIR=""

    if [[ "$fan_board_type" == "0" ]]; then
        if (( index % 2 == 1 )); then
            local_index=$(((index + 1) / 2))
            FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
        else
            local_index=$((index / 2))
            FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        local_index=$index
        FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
    fi

    direction_str=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_direction`
    direction=${direction_str:0:3}
    if [[ "$direction" == "0x0" ]]; then
        echo "$board board FAN$index direction: F2B"
    elif [[ "$direction" == "0x1" ]]; then
        echo "$board board FAN$index direction: B2F"
    fi
}

do_get_fan_direction()
{
    echo "get fan direction:"
    if [[ "$fan_board_type" == "0" ]]; then
        if [[ "$1" == "all" ]]; then
            do_get_fan_direction_by_fan_index 1
            do_get_fan_direction_by_fan_index 2
            do_get_fan_direction_by_fan_index 3
            do_get_fan_direction_by_fan_index 4
            do_get_fan_direction_by_fan_index 5
            do_get_fan_direction_by_fan_index 6
            do_get_fan_direction_by_fan_index 7
            do_get_fan_direction_by_fan_index 8
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 8 ]]; then
            do_get_fan_direction_by_fan_index $1
        else
            usage
            exit -1
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        if [[ "$1" == "all" ]]; then
            do_get_fan_direction_by_fan_index 1
            do_get_fan_direction_by_fan_index 2
            do_get_fan_direction_by_fan_index 3
            do_get_fan_direction_by_fan_index 4
            do_get_fan_direction_by_fan_index 5
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 5 ]]; then
            do_get_fan_direction_by_fan_index $1
        else
            usage
            exit -1
        fi
    fi
}

do_get_fan_powergood_by_fan_index()
{
    index=$1
    local_index=""
    FANCPLD_SYSFS_DIR=""

    if [[ "$fan_board_type" == "0" ]]; then
        if (( index % 2 == 1 )); then
            local_index=$(((index + 1) / 2))
            FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
        else
            local_index=$((index / 2))
            FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        local_index=$index
        FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
    fi

    powergood_str=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_pgb`
    powergood=${powergood_str:0:3}
    if [[ "$powergood" == "0x0" ]]; then
        echo "$board board FAN$index powergood: Warning"
    elif [[ "$powergood" == "0x1" ]]; then
        echo "$board board FAN$index powergood: Normal"
    fi
}

do_get_fan_powergood()
{
    echo "get fan powergood:"
    if [[ "$fan_board_type" == "0" ]]; then
        if [[ "$1" == "all" ]]; then
            do_get_fan_powergood_by_fan_index 1
            do_get_fan_powergood_by_fan_index 2
            do_get_fan_powergood_by_fan_index 3
            do_get_fan_powergood_by_fan_index 4
            do_get_fan_powergood_by_fan_index 5
            do_get_fan_powergood_by_fan_index 6
            do_get_fan_powergood_by_fan_index 7
            do_get_fan_powergood_by_fan_index 8
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 8 ]]; then
            do_get_fan_powergood_by_fan_index $1
        else
            usage
            exit -1
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        if [[ "$1" == "all" ]]; then
            do_get_fan_powergood_by_fan_index 1
            do_get_fan_powergood_by_fan_index 2
            do_get_fan_powergood_by_fan_index 3
            do_get_fan_powergood_by_fan_index 4
            do_get_fan_powergood_by_fan_index 5
        elif [[ "$1" -ge 1 ]] && [[ "$1" -le 5 ]]; then
            do_get_fan_powergood_by_fan_index $1
        else
            usage
            exit -1
        fi
    fi
}


do_set_fan_pwm_by_fan_index()
{
    index=$1
    local_index=""
    FANCPLD_SYSFS_DIR=""

    if [[ "$fan_board_type" == "0" ]]; then
        if (( index % 2 == 1 )); then
            local_index=$(((index + 1) / 2))
            FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
        else
            local_index=$((index / 2))
            FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        local_index=$index
        FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
    fi

    pwm_value=$2
    echo ${pwm_value} > ${FANCPLD_SYSFS_DIR}/fantray${local_index}_pwm
}

do_set_fan_pwm()
{
    if [[ "$fan_board_type" == "0" ]]; then
        if [[ "$1" == "all" ]]; then
            do_set_fan_pwm_by_fan_index 1 $2
            do_set_fan_pwm_by_fan_index 2 $2
            do_set_fan_pwm_by_fan_index 3 $2
            do_set_fan_pwm_by_fan_index 4 $2
            do_set_fan_pwm_by_fan_index 5 $2
            do_set_fan_pwm_by_fan_index 6 $2
            do_set_fan_pwm_by_fan_index 7 $2
            do_set_fan_pwm_by_fan_index 8 $2
        else
            do_set_fan_pwm_by_fan_index $1 $2
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        if [[ "$1" == "all" ]]; then
            do_set_fan_pwm_by_fan_index 1 $2
            do_set_fan_pwm_by_fan_index 2 $2
            do_set_fan_pwm_by_fan_index 3 $2
            do_set_fan_pwm_by_fan_index 4 $2
        else
            do_set_fan_pwm_by_fan_index $1 $2
        fi
    fi
}


fan_board_type=$(get_fan_board_type)

if [ $# -lt 3 ]; then
    usage
    exit -1
fi

command="$1"
fan_index="$2"
attr="$3"

case "$command" in
    get)
        if [ $# -ne 3 ]; then
            echo $#
            usage
            exit -1
        fi
        case "$attr" in
            speed)
                do_get_fan_speed $fan_index
                ;;
            pwm)
                do_get_fan_pwm $fan_index
                ;;
            status)
                do_get_fan_status $fan_index
                ;;
            powergood)
                do_get_fan_powergood $fan_index
                ;;
            direction)
                do_get_fan_direction $fan_index
                ;;
            *)
                usage
                exit -1
                ;;
        esac
        ;;
    set)
        if [ $# -ne 4 ]; then
            usage
            exit -1
        fi
        case "$attr" in
            pwm)
                pwm_value=$4
                do_set_fan_pwm $fan_index $pwm_value
                ;;
            *)
                usage
                exit -1
                ;;
        esac
        ;;
    *)
        echo $command
        usage
        exit -1
        ;;
esac

exit $?
