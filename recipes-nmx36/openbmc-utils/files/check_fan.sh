#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

usage(){
    if [ "$fan_board_type" == "0" ]; then
        echo "Usage: $0 [fan:1, 2, 3, 4, 5, 6, 7, 8]"
    else
        echo "Usage: $0 [fan:1, 2, 3, 4, 5]"
    fi
}

fan_board_type=$(get_fan_board_type)

if [ $# -ne 1 ]; then
    usage
    exit -1
fi

if [ "$fan_board_type" == "0" ]; then
    if [[ "$1" != "1" && "$1" != "2" && "$1" != "3" && "$1" != "4" && "$1" != "5" && "$1" != "6" && "$1" != "7" && "$1" != "8" ]]; then
        usage
        exit -1
    fi
else
    if [[ "$1" != "1" && "$1" != "2" && "$1" != "3" && "$1" != "4" && "$1" != "5" ]]; then
        usage
        exit -1
    fi
fi

fan=$1


local_index=""
FANCPLD_SYSFS_DIR=""

if [[ "$fan_board_type" == "0" ]]; then
    if (( $1 % 2 == 1 )); then
        local_index=$((($1 + 1) / 2))
        FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
    else
        local_index=$(($1 / 2))
        FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
    fi
elif [[ "$fan_board_type" == "1" ]]; then
    local_index=$fan
    FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
fi

en_pwr=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_en | sed -n 1p`
pwr_good=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_pgb | sed -n 1p`
present=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_present | sed -n 1p`

if [[ "$en_pwr" == "0x0" && "$pwr_good" == "0x1" && "$present" == "0x0" ]]; then
    echo "FAN${fan} EFUSE status: normal"
else
    echo "FAN${fan} EFUSE status: abnormal"
    echo 0 > ${FANCPLD_SYSFS_DIR}/fantray${local_index}_en
    sleep 3
    echo 1 > ${FANCPLD_SYSFS_DIR}/fantray${local_index}_en
fi
