#!/bin/bash

. /usr/local/bin/openbmc-utils.sh

#bind base fru eeprom
echo 24c64 0x51 > /sys/bus/i2c/devices/i2c-24/new_device
#bind base cpld
echo basecpld 0x0d > /sys/bus/i2c/devices/i2c-0/new_device


#get product name from base fru
# FRUID_SIZE=256
# echo "Copy Base FRU to /tmp/fruid_base.bin"
# dd if=${BASE_FRU_DIR}/eeprom of=/tmp/fruid_base.bin bs=$FRUID_SIZE count=1 2>/dev/null
# product_name=$(fruid-util base 2>/dev/null | grep 'Product Name' 2>/dev/null | cut -d' ' -f17 2>/dev/null)
# echo "Get Product Name: $product_name" > /dev/ttyS4

# echo $product_name > /etc/openbmc/product_name

