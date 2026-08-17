#!/bin/sh
. /usr/local/bin/openbmc-utils.sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

product_name=$(cat /etc/openbmc/product_name)

# default clear Si5361B Int
# i2ctransfer -f -y 104 w4@0x58 0xF0 0x0F 0x14 0x03 r1
# i2ctransfer -f -y 104 w3@0x58 0xF0 0x0F 0x2A r1
#switch_cpld.sh read 3 0x31

#Clear CPLD PG ALARM Int
# cs value:
# 0:ocm cpld
# 1:sys cpld
# 2:fan1 cpld
# 3:fan2 cpld
# 4:misc cpld
# 5:port cpld1
# 6:port cpld2
# 7:led cpld
# 8:switch fpga
do_clear_cpld_pg_reg_alarm_function_as42_64s_at() {
    local name=(ocm_cpld ocm_cpld sys_cpld sys_cpld fan1_cpld fan2_cpld misc_cpld misc_cpld misc_cpld misc_cpld misc_cpld misc_cpld)
    local cs_index=(0 0 1 1 2 3 4 4 4 4 4 4)
    local pg_reg=(0x11 0x12 0x77 0x78 0x77 0x77 0x4c 0x4d 0x50 0x51 0x52 0x53)
    local reg_val=(0xff 0x0f 0xff 0x0f 0x1f 0x1f 0xff 0x03 0xff 0xff 0xff 0xff)
    for((i=0; i<11; i++))
    do
        ret_val=`read_cpld_reg ${cs_index[i]} ${pg_reg[i]}`
        #echo "${name[i]}-1:${ret_val} = read_cpld_reg ${cs_index[i]} ${pg_reg[i]}"
        write_cpld_reg ${cs_index[i]} ${pg_reg[i]} ${reg_val[i]}
        echo "${name[i]}:write_cpld_reg ${cs_index[i]} ${pg_reg[i]} ${reg_val[i]}, The read value ${ret_val}."
    done
}

# if [ $product_name == "AS42-64S-AT" ]; then
    do_clear_cpld_pg_reg_alarm_function_as42_64s_at
    #clear CPLD_TS1_78.125M_CLK
    read_cpld_reg 4 0x7B
# fi

## Make FRU cache file here.
FRUID_SIZE=256
echo "Copy BMC FRU to /tmp/fruid_bmc.bin"
dd if=${BMC_FRU_DIR}/eeprom of=/tmp/fruid_bmc.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy Base FRU to /tmp/fruid_base.bin"
dd if=${BASE_FRU_DIR}/eeprom of=/tmp/fruid_base.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy Base FRU to /tmp/fruid_ocm.bin"
dd if=${OCM_FRU_DIR}/eeprom of=/tmp/fruid_ocm.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy Switch FRU to /tmp/fruid_switch.bin"
dd if=${SWITCH_FRU_DIR}/eeprom of=/tmp/fruid_switch.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN1 Board FRU to /tmp/fruid_fanboard1.bin"
dd if=${FAN1_BOARD_FRU_DIR}/eeprom of=/tmp/fruid_fanboard1.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN1 Board FAN1 FRU to /tmp/fruid_fan1.bin"
dd if=${FAN1_BOARD_FAN1_FRU_DIR}/eeprom of=/tmp/fruid_fan1.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN1 Board FAN2 FRU to /tmp/fruid_fan2.bin"
dd if=${FAN1_BOARD_FAN2_FRU_DIR}/eeprom of=/tmp/fruid_fan2.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN1 Board FAN3 FRU to /tmp/fruid_fan3.bin"
dd if=${FAN1_BOARD_FAN3_FRU_DIR}/eeprom of=/tmp/fruid_fan3.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN1 Board FAN4 FRU to /tmp/fruid_fan4.bin"
dd if=${FAN1_BOARD_FAN4_FRU_DIR}/eeprom of=/tmp/fruid_fan4.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN2 Board FRU to /tmp/fruid_fanboard2.bin"
dd if=${FAN2_BOARD_FRU_DIR}/eeprom of=/tmp/fruid_fanboard2.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN2 Board FAN1 FRU to /tmp/fruid_fan5.bin"
dd if=${FAN2_BOARD_FAN1_FRU_DIR}/eeprom of=/tmp/fruid_fan5.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN2 Board FAN2 FRU to /tmp/fruid_fan6.bin"
dd if=${FAN2_BOARD_FAN2_FRU_DIR}/eeprom of=/tmp/fruid_fan6.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN2 Board FAN3 FRU to /tmp/fruid_fan7.bin"
dd if=${FAN2_BOARD_FAN3_FRU_DIR}/eeprom of=/tmp/fruid_fan7.bin bs=$FRUID_SIZE count=1 2>/dev/null
echo "Copy FAN2 Board FAN4 FRU to /tmp/fruid_fan8.bin"
dd if=${FAN2_BOARD_FAN4_FRU_DIR}/eeprom of=/tmp/fruid_fan8.bin bs=$FRUID_SIZE count=1 2>/dev/null

#Set BMC login timeout
echo "To setup platform ..."
echo "TMOUT=300" >> /etc/profile
echo "export TMOUT" >> /etc/profile

#Kick FAN-CPLD WDT
echo 0 > ${FAN1CPLD_SYSFS_DIR}/fan_watchdog_en
echo 1 > ${FAN1CPLD_SYSFS_DIR}/fan_watchdog_en
echo 0 > ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_en
echo 1 > ${FAN2CPLD_SYSFS_DIR}/fan_watchdog_en

echo "green" > /tmp/sysfanled
echo 7 >/proc/sys/kernel/printk

echo -n "Setting BASE CPLD register SYS_LED(0x50) to green..."
/usr/sbin/i2cset -f -y 0 0xd 0x50 0x4
echo "Done."

