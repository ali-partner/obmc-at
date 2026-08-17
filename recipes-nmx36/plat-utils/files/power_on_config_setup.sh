#!/bin/bash
. /usr/local/bin/openbmc-utils.sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin


#create cache fru directory
if [ ! -L /run/eeprom ]; then
    sleep 1
    mkdir -p /run/eeprom
fi
sleep 3

#check i2c channel
source /usr/local/bin/i2c_topology_create.sh
i2c_topology_create

/usr/local/bin/gpio_jtag_init.sh

/usr/local/bin/kcsd.sh start
/usr/local/bin/ipmid > /dev/null 2>&1 &

#set driver init finished flag
echo 1 > /run/driver_init_ok
exit 0
