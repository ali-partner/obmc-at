#!/bin/bash
prog="$0"


usage() {
    echo "Usage: "
    echo "$prog 88E6361 <file>"
    echo
}


do_update_88e6361() {
    image=$1
    echo 1 > ${BASECPLD_SYSFS_DIR}/88e6361_update_en
    echo 0 > ${BASECPLD_SYSFS_DIR}/88e6361_eeprom_wp
    if [ ! -f "/sys/bus/i2c/devices/20-0050/eeprom" ]; then
        echo 20-0050 > /sys/bus/i2c/drivers/at25/unbind
        sleep 1
        echo 20-0050 > /sys/bus/i2c/drivers/at25/bind
    fi
    dd if=$image of=/sys/bus/i2c/devices/20-0050/eeprom bs=256 count=8 2>/dev/null
    ret=$?
    if [ $ret == 0 ]; then
        echo "update 88E6361 success."
    else
        echo "update 88E6361 fail."
    fi
    echo 1 > ${BASECPLD_SYSFS_DIR}/88e6361_eeprom_wp
    echo 0 > ${BASECPLD_SYSFS_DIR}/88e6361_update_en
    return $ret
}


source /usr/local/bin/openbmc-utils.sh

if [ $# -gt 2 ]; then
    usage
    exit -1
fi

chip="$1"
image="$2"
 
case "$chip" in
    88E6361)
        do_update_88e6361 $image
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?


