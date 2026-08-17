#!/bin/bash


usage() {
    echo "Usage: $0 [flash|uboot]"
    echo "  Show BMC device MTD Number"
    echo
}

flash_mtd(){
    mtd1=`cat /proc/mtd | grep "main-bmc" | cut -d ":" -f 1 | cut -d "d" -f 2`
    echo "BMC main-bmc mtd number: ${mtd1}"
    mtd2=`cat /proc/mtd | grep "alt-bmc" | cut -d ":" -f 1 | cut -d "d" -f 2`
    echo "BMC alt-bmc mtd number: ${mtd2}"
}

uboot_mtd(){
    mtd1=`cat /proc/mtd | grep '"u-boot"' | cut -d ":" -f 1 | cut -d "d" -f 2`
    echo "BMC flash1 u-boot mtd number: ${mtd1}"
    mtd2=`cat /proc/mtd | grep "alt-u-boot" | cut -d ":" -f 1 | cut -d "d" -f 2`
    echo "BMC flash2 alt-u-boot mtd number: ${mtd2}"
}


if [ $# -ne 1 ]; then
    usage
    exit -1
fi

object=$1

case "$object" in
    flash)
        flash_mtd
        ;;
    uboot)
        uboot_mtd
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
