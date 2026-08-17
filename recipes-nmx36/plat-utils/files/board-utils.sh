# Copyright 2018-present Facebook. All Rights Reserved.
#
# I2C paths of CPLDs
#
OCMCPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 16-000d)
BASECPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 0-000d)
SWB_MISCCPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 66-0031)
SWB_PORT1CPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 64-0031)
SWB_PORT2CPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 65-0031)
LINE_PORT3CPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 67-0031)
FANCPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 8-000d)
SWITCHFPGA_SYSFS_DIR=$(i2c_device_sysfs_abspath 5-0032)
#
# I2C paths of FRU
#
BMC_FRU_DIR=$(i2c_device_sysfs_abspath 2-0052)
BASE_FRU_DIR=$(i2c_device_sysfs_abspath 2-0051)
OCM_FRU_DIR=$(i2c_device_sysfs_abspath 113-0056)
SWITCH_FRU_DIR=$(i2c_device_sysfs_abspath 24-0050)
LINE_FRU_DIR=$(i2c_device_sysfs_abspath 25-0053)
FAN_FRU_DIR=$(i2c_device_sysfs_abspath 94-0056)
FAN1_FRU_DIR=$(i2c_device_sysfs_abspath 92-0050)
FAN2_FRU_DIR=$(i2c_device_sysfs_abspath 91-0050)
FAN3_FRU_DIR=$(i2c_device_sysfs_abspath 90-0050)
FAN4_FRU_DIR=$(i2c_device_sysfs_abspath 89-0050)
FAN5_FRU_DIR=$(i2c_device_sysfs_abspath 88-0050)

PSU1_MODLE_DIR=$(i2c_device_sysfs_abspath 72-0058)
PSU2_MODLE_DIR=$(i2c_device_sysfs_abspath 73-0058)
PSU3_MODLE_DIR=$(i2c_device_sysfs_abspath 74-0058)
PSU4_MODLE_DIR=$(i2c_device_sysfs_abspath 75-0058)

PWR_SP4_RST_SYSFS="${BASECPLD_SYSFS_DIR}/cpld_mac_reset"


#################################################################################
#SoC addr
#################################################################################
wdt_addr() {
    echo $((0x1E785000 + 0x$1))
}

adc_addr() {
    echo $((0x1E6E9000 + 0x$1))
}

#################################################################################
iso_buf_enable() {
    # TODO, no isolation buffer
    return 0
}

iso_buf_disable() {
    # TODO, no isolation buffer
    return 0
}

is_us_on() {
    local val

     val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
     if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
         return 0            # powered on
     else
         return 1
     fi

    # default is power on
    return 0
}

board_type() {
    echo 'Hodori'
}

slot_id() {
    printf "1\n"
}


# Should we enable OOB interface or not
should_enable_oob() {
    # minipack uses BMC MAC since beginning
    return -1
}

power_on_board() {
    # minipack SCM power is controlled by SCMCPLD
    return 0
}
