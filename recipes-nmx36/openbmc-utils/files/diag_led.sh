#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

SYSFS_I2C_DEVICES="/sys/bus/i2c/devices"
SYSCPLD_PATH="${SYSFS_I2C_DEVICES}/0-000d"
FAN1CPLD_PATH="${SYSFS_I2C_DEVICES}/8-000d"
FAN2CPLD_PATH="${SYSFS_I2C_DEVICES}/3-000d"
GPIO_PATH="/sys/class/gpio/gpio147" # GPIOS3: BMC_RSTIND_N
fan_air="1 2 3 4 5 6 7 8"
fan_liquid="1 2 3 4 5"
system="sys psu fan"


usage(){
    echo
    echo "Usage: $0 get"
    echo "  get: show FAN/SYSTEM LED status"
    echo
    if [ "$fan_board_type" == "0" ]; then
        echo "Usage: $0 set [FAN:1-8,all] [mode:0-6]"
    else
        echo "Usage: $0 set [FAN:1-5,all] [mode:0-6]"
    fi
    echo "    0: off"
    echo "    1: green blinking"
    echo "    2: green"
    echo "    3: yellow blinking"
    echo "    4: yellow"
    echo "    5: red blinking"
    echo "    6: red"
    echo
    echo "Usage: $0 set [SYSTEM:sys,psu,fan] [mode:0-4]"
    echo "  set: set SYSTEM LED status"
    echo "    0: off"
    echo "    1: green blinking"
    echo "    2: green"
    echo "    3: yellow blinking"
    echo "    4: yellow"
    echo
    echo "Usage: $0 set mgmt [mode:0-1]"
    echo "  set: set SYSTEM LED status"
    echo "    0: off"
    echo "    1: green"
    echo
}

fan_led_get(){
    echo "Get FAN LED status: "
    if [[ "$fan_board_type" == "0" ]]; then
        for i in ${fan_air}
        do
            if [[ "$i" -ge 1 ]] && [[ "$i" -le 4 ]]; then
                local_index=$i
                FANCPLD_SYSFS_DIR=$FAN1CPLD_PATH
            elif [[ "$i" -ge 5 ]] && [[ "$i" -le 8 ]]; then
                local_index=$((i - 4))
                FANCPLD_SYSFS_DIR=$FAN2CPLD_PATH
            fi
            val=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_led_ctrl | sed -n 1p`
            if [ "$val" == "0x3" ]; then
                st="yellow"
            elif [ "$val" == "0x7" ]; then
                st="yellow blinking"
            elif [ "$val" == "0x9" ]; then
                st="green"
            elif [ "$val" == "0xd" ]; then
                st="green blinking"
            elif [ "$val" == "0xa" ]; then
                st="red"
            elif [ "$val" == "0xe" ]; then
                st="red blinking"
            else
                st="off"
            fi
            echo "  LED fan${i} status: $st"
        done
    elif [[ "$fan_board_type" == "1" ]]; then
        for i in ${fan_liquid}
        do
            val=`cat ${FAN2CPLD_PATH}/fantray${i}_led_ctrl | sed -n 1p`
            if [ "$val" == "0x3" ]; then
                st="yellow"
            elif [ "$val" == "0x7" ]; then
                st="yellow blinking"
            elif [ "$val" == "0x9" ]; then
                st="green"
            elif [ "$val" == "0xd" ]; then
                st="green blinking"
            elif [ "$val" == "0xa" ]; then
                st="red"
            elif [ "$val" == "0xe" ]; then
                st="red blinking"
            else
                st="off"
            fi
            echo "  LED fan${i} status: $st"
        done
    fi
}

fan_led_set(){
    mode="$2"
    status=("off" "green blinking" "green" "yellow blinking" "yellow" "red blinking" "red")
    value=("0xb" "0xd" "0x9" "0x7" "0x3" "0xe" "0xa")

    if [[ "$mode" != "0" && "$mode" != "1" && "$mode" != "2" && "$mode" != "3" && "$mode" != "4" && "$mode" != "5" && "$mode" != "6" ]]; then
        usage
        exit -1
    fi

    if [[ "$fan_board_type" == "0" ]]; then
        if [ "$1" == "all" ]; then
            for i in ${fan_air}
            do
                if [[ "$i" -ge 1 ]] && [[ "$i" -le 4 ]]; then
                    local_index=$i
                    FANCPLD_SYSFS_DIR=$FAN1CPLD_PATH
                elif [[ "$i" -ge 5 ]] && [[ "$i" -le 8 ]]; then
                    local_index=$((i - 4))
                    FANCPLD_SYSFS_DIR=$FAN2CPLD_PATH
                fi
                echo "Set LED fan${i} to ${status[mode]}"
                echo ${value[mode]} > ${FANCPLD_SYSFS_DIR}/fantray${local_index}_led_ctrl
                sleep 0.1
            done
        else
            if [[ "$1" -ge 1 ]] && [[ "$1" -le 4 ]]; then
                local_index=$index
                FANCPLD_SYSFS_DIR=$FAN1CPLD_PATH
            elif [[ "$1" -ge 5 ]] && [[ "$1" -le 8 ]]; then
                local_index=$((index - 4))
                FANCPLD_SYSFS_DIR=$FAN2CPLD_PATH
            fi
            echo "Set ${fan_board} board LED fan${1} to ${status[mode]}"
            echo ${value[mode]} > ${FANCPLD_SYSFS_DIR}/fantray${local_index}_led_ctrl
        fi
    elif [[ "$fan_board_type" == "1" ]]; then
        if [ "$1" == "all" ]; then
            for i in ${fan_liquid}
            do
                echo "Set LED fan${i} to ${status[mode]}"
                echo ${value[mode]} > ${FAN2CPLD_PATH}/fantray${i}_led_ctrl
                sleep 0.1
            done
        else
            echo "Set LED fan${1} to ${status[mode]}"
            echo ${value[mode]} > ${FAN2CPLD_PATH}/fantray${1}_led_ctrl
        fi
    fi
}

system_led_status(){
    val=$2
    if [ "$val" == "0x3" ]; then
        st="green blinking"
    elif [ "$val" == "0x4" ]; then
        st="green"
    elif [ "$val" == "0x5" ]; then
        st="yellow blinking"
    elif [ "$val" == "0x6" ]; then
        st="yellow"
    else
        st="off"
    fi
    echo "  LED $1 status: $st"
}

system_led_get(){
    echo "Get SYSTEM LED status: "

    for i in ${system}
    do
        if [ "$i" == "fan" ]; then
            ctl=`cat ${FAN2CPLD_PATH}/${i}_led_ctrl_status | sed -n 1p`
            value=`cat ${FAN2CPLD_PATH}/${i}_led_ctrl | sed -n 1p`
        else
            ctl=`cat ${SYSCPLD_PATH}/${i}_led_ctrl_status | sed -n 1p`
            value=`cat ${SYSCPLD_PATH}/${i}_led_ctrl | sed -n 1p`
        fi

        if [ "$ctl" == "0x1" ]; then
            if [[ "$fan_board_type" == "0" ]]; then
                ctl=`cat ${FAN1CPLD_PATH}/${i}_led_ctrl_status | sed -n 1p`
                value=`cat ${FAN1CPLD_PATH}/${i}_led_ctrl | sed -n 1p`
                system_led_status fan1 $value

                ctl=`cat ${FAN2CPLD_PATH}/${i}_led_ctrl_status | sed -n 1p`
                value=`cat ${FAN2CPLD_PATH}/${i}_led_ctrl | sed -n 1p`
                system_led_status fan2 $value
            elif [[ "$fan_board_type" == "1" ]]; then
                system_led_status $i $value
            fi
        else
            if [ "$i" == "sys" ]; then
                st="cpu or cpld control"
            else
                st="hardware control"
            fi
            echo "  LED $i status: $st"
        fi
    done
}

system_led_set(){
    mode="$2"
    status=("off" "green blinking" "green" "yellow blinking" "yellow")
    value=("0x0" "0x3" "0x4" "0x5" "0x6")

    if [[ "$mode" != "0" && "$mode" != "1" && "$mode" != "2" && "$mode" != "3" && "$mode" != "4" ]]; then
        usage
        exit -1
    fi

    echo "Set LED ${1} to ${status[mode]}"
    if [ "$1" == "fan" ]; then
        if [[ "$fan_board_type" == "0" ]]; then
            echo "0x1" > ${FAN1CPLD_PATH}/${1}_led_ctrl_status
            echo ${value[mode]} > ${FAN1CPLD_PATH}/${1}_led_ctrl
            echo "0x1" > ${FAN2CPLD_PATH}/${1}_led_ctrl_status
            echo ${value[mode]} > ${FAN2CPLD_PATH}/${1}_led_ctrl
        elif [[ "$fan_board_type" == "1" ]]; then
            echo "0x1" > ${FAN2CPLD_PATH}/${1}_led_ctrl_status
            echo ${value[mode]} > ${FAN2CPLD_PATH}/${1}_led_ctrl
        fi
    else
        if [ "$1" == "psu" ]; then
            echo "0x1" > ${SYSCPLD_PATH}/${1}_led_ctrl_status
        fi
        echo ${value[mode]} > ${SYSCPLD_PATH}/${1}_led_ctrl
    fi
}

mgmt_led_get(){
    echo "Get MGMT LED status: "

    val=`ast-mdio.py --mdio 3 --phy 0x09 read 0x0 | cut -d ":" -f 2 | awk '{gsub(/^\s+|\s+$/,"");print'}`
    if [ "$val" == "0x1940" ]; then
        echo "  LED MGMT status: off"
    elif [ "$val" == "0x1140" ]; then
        echo "  LED MGMT status: green"
    else
        echo "  LED MGMT status: unknown"
    fi
}

mgmt_led_set(){
    mode="$2"
    status=("off" "green")
    value=("0x1940" "0x1140")

    if [[ "$mode" != "0" && "$mode" != "1" ]]; then
        usage
        exit -1
    fi

    echo "Set LED ${1} to ${status[mode]}"
    ast-mdio.py --mdio 3 --phy 0x09 write 0x0 ${value[mode]}
}


fan_board_type=$(get_fan_board_type)

if [ $# -ne 1 ] && [ $# -ne 3 ]; then
    usage
    exit -1
fi

if [ "$1" == "get" ]; then
    fan_led_get
    echo
    system_led_get
    echo
    mgmt_led_get
elif [ "$1" == "set" ]; then
    if [[ "$2" == "1" || "$2" == "2" || "$2" == "3" || "$2" == "4" || "$2" == "5" || "$2" == "6" || "$2" == "7" || "$2" == "8" || "$2" == "all" ]]; then
        if [ "$fan_board_type" == "0" ]; then
            if [[ "$2" != "all" ]] && ([[ "$2" -lt 1 ]] || [[ "$2" -gt 8 ]]); then
                usage
                exit -1
            fi
        else
            if [[ "$2" != "all" ]] && ([[ "$2" -lt 1 ]] || [[ "$2" -gt 5 ]]); then
                usage
                exit -1
            fi
        fi
        fan_led_set $2 $3
    elif [[ "$2" == "sys" || "$2" == "psu" || "$2" == "fan" ]]; then
        system_led_set $2 $3
    elif [ "$2" == "mgmt" ]; then
        mgmt_led_set $2 $3
    else
        usage
        exit -1
    fi
else
    usage
    exit -1
fi
