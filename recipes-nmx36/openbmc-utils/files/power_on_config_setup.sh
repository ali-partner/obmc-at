#!/bin/bash
. /usr/local/bin/openbmc-utils.sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

#clear wdt timer
devmem 0x14c37404 32 0x0

#create cache fru directory
if [ ! -L /run/eeprom ]; then
    sleep 1
    mkdir -p /run/eeprom
fi
sleep 3

echo -n "Get product name from FRU ... " > /dev/ttyS4
/usr/local/bin/set_product_name.sh


MAX_RETRY=100
retry_time=0
while [ $retry_time -lt $MAX_RETRY ]
do
    cpu_status=`power_util.sh cpu status`
    if [[ "$cpu_status" == *on* ]]; then
        break;
    else
        echo "Wait for CPU power on..." > /dev/ttyS4
        ((retry_time++))
        sleep 6
    fi
done

/usr/local/bin/gpio_jtag_init.sh

loop_count=0
LOOP_MAX=24
while [ $loop_count -lt $LOOP_MAX ]
do
    cpu_status=`power_util.sh cpu status`
    if [[ "$cpu_status" == *on* ]]; then
        break
    fi
    loop_count=$((1+$loop_count))
    sleep 5
done
if [  $loop_count -eq $LOOP_MAX ];then
    /usr/bin/power_util.sh cpu on
fi
sleep 3

if [ ! -d "/sys/bus/i2c/drivers/pca954x/5-0071" ]; then
    echo "SW board may not be powered on, now re-bind PCA9546 on SW board." > /dev/ttyS4
    echo 5-0071 > /sys/bus/i2c/drivers/pca954x/bind
    if [ -d "/sys/bus/i2c/drivers/pca954x/5-0071" ]; then
        echo "Re-bind PCA9546 on SW board, done." > /dev/ttyS4
    else
        echo "Re-bind PCA9546 on SW board, FAIL!" > /dev/ttyS4
    fi
else
    echo "I2c devices on SW board have been mounted." > /dev/ttyS4
fi


# if [ ! -d "/sys/bus/peci/drivers/intel_peci_client/0-30" ]; then
#     echo "OCM board may not be powered on, now re-bind PECI-driver on OCM board." > /dev/ttyS4
#     echo peci-client 0x30 > /sys/bus/peci/devices/peci-0/new_device
#     if [ -d "/sys/bus/peci/drivers/intel_peci_client/0-30" ]; then
#         echo "Re-bind PECI-driver, done." > /dev/ttyS4
#     else
#         echo "Re-bind PECI-driver, FAIL!" > /dev/ttyS4
#     fi
# fi


PMBUS_TIMEOUT_TIME=0x3d30
ocm_mp_device_set_timeout() {
    local name2=(OCM_TPS544B25_2F OCM_XDPE12284_58 OCM_XDPE12284_60)
    local bus2=(17 17 17)
    local addr2=(27 58 60)
    for((i=0; i<3; i++))
    do
        cnt=0
        while true
        do
            pnbus_timeout_get=`i2cset -f -y ${bus2[i]} 0x${addr2[i]} 0x0 0x0 b;i2cget -f -y ${bus2[i]} 0x${addr2[i]} 0xc5 w`
            if [ $? -ne 0 ]; then
                echo "i2c-1 ${name2[i]}(${bus2[i]}, 0x${addr2[i]}) read PMBUS TIMEOUT time(count=${cnt})."
                sleep 0.1
                continue
            fi
            if [ "$pnbus_timeout_get" == "${PMBUS_TIMEOUT_TIME}" ]; then
                echo "i2c-1 ${name2[i]}(${bus2[i]}, 0x${addr2[i]}) check PMBUS TIMEOUT time. Value: ${pnbus_timeout_get}, Expect: ${PMBUS_TIMEOUT_TIME} (count=${cnt})."
                break
            fi
            ((cnt++))
            if [ $cnt -eq 4 ]; then
                echo "i2c-1 ${name2[i]}(${bus2[i]}, 0x${addr2[i]}) set PMBUS TIMEOUT time failed."
                break
            fi
            pnbus_timeout_set=`i2cset -f -y ${bus2[i]} 0x${addr2[i]} 0x0 0x0 b;i2cset -f -y ${bus2[i]} 0x${addr2[i]} 0xc5 ${PMBUS_TIMEOUT_TIME} w`
            if [ $? -ne 0 ]; then
                echo "i2c-1 ${name2[i]}(${bus2[i]}, 0x${addr2[i]}) set PMBUS TIMEOUT time(count=${cnt})."
                sleep 0.1
                continue
            fi

        done
    done
}

#ocm_mp_device_set_timeout



# product_name=`/usr/local/bin/show_product_name.sh`
# echo $product_name > /dev/ttyS4
# if [ $product_name == "AS42-64S-AT" ]; then
#     cp /usr/local/bin/AS42-64S-AT_board-utils.sh /usr/local/bin/board-utils.sh
#     source /usr/local/bin/i2c_topology_create_AS42-64S-AT.sh
#     i2c_topology_create
# else
#     echo "Unknow product name,exit config setup." > /dev/ttyS4
#     exit 0
# fi

cp /usr/local/bin/AS42-64S-AT_board-utils.sh /usr/local/bin/board-utils.sh
source /usr/local/bin/i2c_topology_create_AS42-64S-AT.sh
i2c_topology_create

#set driver init finished flag
echo 1 > /run/driver_init_ok

/sbin/hwclock -u -s

/usr/local/bin/setup_platform.sh

echo -n "To fix up ina3221 ... " > /dev/ttyS4
/usr/local/bin/setup_ina3221.sh
echo " DONE." > /dev/ttyS4
echo -n "To fix up eth0 ... " > /dev/ttyS4
/usr/local/bin/eth0_mac_fixup.sh
echo " DONE." > /dev/ttyS4
echo -n "To store version ... " > /dev/ttyS4
/usr/local/bin/store_version.sh
echo " DONE." > /dev/ttyS4
echo -n "To fix up eth0 vlan ..." > /dev/ttyS4
/usr/local/bin/eth0_create_vlan.sh
echo " DONE." > /dev/ttyS4

echo -n "To setup board ..." > /dev/ttyS4
/usr/local/bin/setup_board.sh
echo " DONE." > /dev/ttyS4

exit 0
