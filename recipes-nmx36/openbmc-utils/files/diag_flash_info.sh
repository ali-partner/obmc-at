#!/bin/bash

PROGRAM_TITLE=`basename $0`

FLASH_SIZE_STR="08000000"

usage() {
    echo "Usage: diag_flash_info.sh"
    echo ""
}

# Start of the script.
if [ $# -ge 1 ]; then
    usage
    exit -1
fi

check_flash_info(){
    has_error=0

    #first Exist ?
    flash_name=`cat /proc/mtd | grep -w main-bmc`
    if [ ! -n "$flash_name" ];then
        echo "$bmc_flash flash BMC not found"
        echo "Failed"
        has_error=1
    fi

    #first Size ?
    flash_size=`cat /proc/mtd | grep -w main-bmc | awk '{print $2}'`
    echo "$bmc_flash flash BMC size : $flash_size"
    if [ X$flash_size == "X$FLASH_SIZE_STR" ];then
        echo "check $bmc_flash flash bmc PASS"
    else
        echo "check $bmc_flash flash bmc FAIL"
    fi

    #second Exist ?
    flash_name=`cat /proc/mtd  | grep -w alt-bmc`
    if [ ! -n "$flash_name" ];then
        echo "$alt_bmc_flash flash alt-bmc not found"
        echo "Failed"
        has_error=1
    fi

    #second Size ?
    flash_size=`cat /proc/mtd | grep -w alt-bmc | awk '{print $2}'`
    echo "$alt_bmc_flash flash alt-bmc size : $flash_size"
    if [ X$flash_size == "X$FLASH_SIZE_STR" ];then
        echo "check $alt_bmc_flash flash alt-bmc PASS"
    else
        echo "check $alt_bmc_flash flash alt-bmc FAIL"
        has_error=2
    fi

    if [ $has_error -eq 0 ]; then
        echo "Check BMC flash: PASS"
        exit $has_error
    fi
}


boot_status=`boot_area.sh bmc status`
if [ "$boot_status" == "BMC  boot: Primary SPI" ]; then
    bmc_flash="primary"
    alt_bmc_flash="secondary"
else
    bmc_flash="secondary"
    alt_bmc_flash="primary"
fi

check_flash_info

exit 0
