#!/bin/sh
. /usr/local/bin/openbmc-utils.sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

SYSFS_I2C_DEVICES="/sys/bus/i2c/devices"

function retry_check_bus_status_ready()
{
    #while true
    #do
    #    rvalue1=`i2cget -f -y 0 0x0d 0x05`
    #    ret=$?
    #    if [ $ret != 0 ]; then
    #        echo "The bus(IIC0) is not ready,It can't read slave device."
    #        sleep 1
    #    else
    #        break
    #    fi
    #done

    while true
    do
        local dir_status=-1
        local bus=(1 2 4 5 6 7 8 13 17)
        local addr=(71 71 74 71 71 71 71 71 70)
        for((i=0; i<9; i++))
        do
            dir_info=${SYSFS_I2C_DEVICES}/${bus[i]}-00${addr[i]}
            if [ ! -d ${dir_info} ];then
                dir_status=-1
            else
                dir_status=0
            fi
        done
		if [ $dir_status -eq 0 ]; then
			echo "The pca954x driver is ready."
			break
		else
			continue
		fi
        sleep 3
    done

}

function retry_check_base_cpld_id()
{
    while true
    do
        rvalue1=`i2cget -f -y 0 0x0d 0x05`
        rvalue2=`i2cget -f -y 0 0x0d 0x05`
        echo "get two value ${rvalue1}, ${rvalue2}"

        if [ "$rvalue1" = "$rvalue2" ];then
            break
        fi
        sleep 1
    done
}

sys_init_early()
{
    echo -n "To sys_init_early ..."
    retry_check_bus_status_ready
    #retry_check_base_cpld_id
    # Add RTC driver here, because BMC must add timestamp in syslog when power on CPU.
    echo "To add i2c device rx8010 ..."
    i2c_device_add 3 0x51 rx8010
    /sbin/hwclock -u -s
    echo "To disable SuperIO"
    devmem_set_bit 0x1e6e2070 20
}

#read three time equle, for i2c residue
sys_init_early
echo "after sys_init_early ... "

# install kernel i2c device driver
#modprobe i2c-dev
#modprobe i2c-mux
modprobe lm75
modprobe pmbus

# install common driver
#modprobe i2c-mux-pca954x ignore_probe=1

# install common driver
#modprobe at24
#modprobe ina3221
#modprobe tps53622
#modprobe ir3580
#modprobe isl68127
#modprobe max34461

exit 0
