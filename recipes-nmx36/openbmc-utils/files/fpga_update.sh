#!/bin/bash
prog="$0"


usage() {
    echo "Usage: "
    echo "$prog <file>"
    echo
}

do_fpga_flash_bind() {
    if [ -d "/sys/class/gpio/gpio645" ]; then
        echo 645 > /sys/class/gpio/unexport
    fi
    if [ -d "/sys/class/gpio/gpio647" ]; then
        echo 647 > /sys/class/gpio/unexport
    fi
    if [ -d "/sys/class/gpio/gpio646" ]; then
        echo 646 > /sys/class/gpio/unexport
    fi
    if [ -d "/sys/class/gpio/gpio650" ]; then
        echo 650 > /sys/class/gpio/unexport
    fi
    echo 0 > ${BASECPLD_SYSFS_DIR}/bmc_fpga_update; sync
    # echo 0 > ${BASECPLD_SYSFS_DIR}/fpga_flash_wp; sync
    if [ -d "/sys/bus/platform/drivers/spi_gpio/spi" ]; then
        echo spi > /sys/bus/platform/drivers/spi_gpio/unbind
        sleep 1
    fi
    echo spi > /sys/bus/platform/drivers/spi_gpio/bind
}


do_fpga_flash_unbind() {
    # echo 1 > ${BASECPLD_SYSFS_DIR}/fpga_flash_wp; sync
    echo 1 > ${BASECPLD_SYSFS_DIR}/bmc_fpga_update; sync
    if [ -d "/sys/bus/platform/drivers/spi_gpio/spi" ]; then
        echo spi > /sys/bus/platform/drivers/spi_gpio/unbind
    fi
    echo "done."
}


do_update_fpga() {
    image=$1
    do_fpga_flash_bind
    mtd_name=`cat /proc/mtd | grep  "\"spi_gpio_flash\"" | cut -d ":" -f1 2> /dev/null`
    echo "mtd: $mtd_name"
    flashcp -v $image /dev/${mtd_name} 
    ret=$?
    if [ $ret == 0 ]; then
        echo "update FPGA success."
    else
        echo "update FPGA fail."
    fi
    do_fpga_flash_unbind
    exit $ret
}


source /usr/local/bin/openbmc-utils.sh

if [ $# -lt 1 ]; then
    usage
    exit -1
fi

image="$1"
 
do_update_fpga $image




