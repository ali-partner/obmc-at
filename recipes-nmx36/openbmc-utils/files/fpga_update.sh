#!/bin/bash
prog="$0"
CHECK_PRODUCT_NAME="NA"


usage() {
    echo "Usage: "
    echo "$prog <file> [sign|unsign]"
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


check_component_sign() {
    local tmp_component=$1
    local file_name=$2
    local out_fw_file=$3
    local output
    local ret

    echo "$tmp_component start unsign process, file name: $file_name"
    # output=$(unsign_fw.sh $CHECK_PRODUCT_NAME $tmp_component $file_name $out_fw_file)
    unsign_fw.sh $CHECK_PRODUCT_NAME $tmp_component $file_name $out_fw_file
    ret=$?
    # echo "${output}"
    if [ "${ret}" -ne 0 ];then
        echo "$tmp_component unsign process failed, return code = ${ret}"
    else
        echo "$tmp_component unsign process success"
    fi
    return $ret
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
}


source /usr/local/bin/openbmc-utils.sh

sign_mode="sign"

if [ $# -eq 2 ]; then
    if [[ "$2" == "sign" || "$2" == "unsign" ]]; then
        sign_mode="$2"
    else
        echo "ERROR: Invalid last argument: $2. Must be 'sign' or 'unsign'."
        usage
        exit -1
    fi
elif [ $# -ne 1 ]; then
    usage
    exit -1
fi

image="$1"


if [[ "$sign_mode" == "sign" ]]; then
    out_fw_file="/tmp/tmp_fpga_flash.bin"
    check_component_sign FPGA $image $out_fw_file
    if [ $? -ne 0 ];then
        exit -1
    fi
    do_update_fpga $out_fw_file
    if [ -f "${out_fw_file}" ]; then
        rm -f "${out_fw_file}"
    fi
else
    do_update_fpga $image
fi

exit 0



