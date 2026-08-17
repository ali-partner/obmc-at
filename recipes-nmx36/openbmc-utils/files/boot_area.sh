#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

prog="$0"

usage() {
    echo "Usage: $prog <bmc/bios> <command>"
    echo
    echo "Commands:"
    echo "  status: Get the current boot area status."
    echo
    echo "  secondary: BMC/BIOS boot from secondary SPI flash next time. BMC auto reboot in 10s."
    echo
    echo "  primary: BMC/BIOS boot from primary SPI flash next time. BMC auto reboot in 10s."
    echo
    echo "  nextboot_secondary: BMC/BIOS boot from secondary SPI flash next time."
    echo
    echo "  nextboot_primary: BMC/BIOS boot from primary SPI flash next time."
    echo
    echo "  action: BMC boot from next boot flash. BMC auto reboot in 10s."
    echo
    echo "  nextboot: Get BMC/BIOS next boot area status."
    echo
}

set_wdta() {
    # Set bit_1 to 1 : Use second boot code whenever WDT reset.
    devmem 0x14c37408 32 0x00004755
    devmem 0x14c3740c 32 0x13
}

do_status() {
	ret=$(devmem 0x14c3744c 32)
	boot_source=${ret:9:1}
	[ $boot_source -eq 0 ] && boot_img="Primary" || boot_img="Secondary"
	echo "BMC  boot: $boot_img SPI"
	return 0
}


show_bmc_boot_status()
{
	ret=$(devmem 0x14c3744c 32)
	boot_source=${ret:9:1}
	[ $boot_source -eq 0 ] && boot_img="primary" || boot_img="secondary"
	echo "BMC  boot: $boot_img"
	return $boot_source
}

set_bmc_boot_code()
{
    boot_img=$1
    #暂时不同flash标志位判断主备启动
    #set_bmc_boot_flag $boot_img

    if [[ "X$boot_img" == "Xsecondary" ]]; then
        mtd=`cat /proc/mtd | grep -w alt-bmc | awk '{print $1}'`
        mtd_val=`echo ${mtd:0:4}`
        if [ -z "$mtd_val" ];then
            echo "flash alt-bmc not found."
            exit -1
        fi
    fi

    devmem 0x14c37404 32 0x014FB180
    devmem 0x14c37408 32 0x00004755

    if [[ "X$boot_img" != "Xsecondary" ]]; then
        # devmem 0x14c3744c 32 0x02
        devmem 0x14c3740c 32 0x13
    else
        # devmem 0x14c3744c 32 0x00
        devmem 0x14c3740c 32 0x13
    fi

    # WDT will reset system.
    echo ""
    echo "Changing BMC to boot from \"$boot_img\", system will reset..."
    echo ""
    
    #record reset reason
    #echo 0x8 > ${I2C_BUS_PATH}/1-0001/REG_BMC_RST_INT_RECORD
    # Enable WDT to reboot to the designated boot image.
    
    # Stop all tasks and umount filesystem, because some tasks may access SPI flash
    systemctl exit
}

do_set_bmc_boot_code() {
    boot_image=$1
    if [[ "X$boot_image" == "Xprimary" || "X$boot_image" == "Xsecondary" ]]; then
        show_bmc_boot_status $boot_image
        ret=$?
        if [[ $ret -eq 0 && "X$boot_image" == "Xprimary" ]]; then
            echo "BMC boot code is $boot_image, exiting..."
            exit 0
        elif [[ $ret -eq 1 && "X$boot_image" == "Xsecondary" ]]; then
            echo "BMC boot code is $boot_image, exiting..."
            exit 0
        else
            set_bmc_boot_code $boot_image
        fi
    fi
}


do_nextboot_primary() {
    ret=$(devmem 0x14c3744c 32)
	boot_source=${ret:9:1}

    if [ $boot_source -eq 0 ]; then
        devmem 0x14c37404 32 0x0
    else
        devmem 0x14c37404 32 0x4C4B40
    fi
    echo "SET next bmc boot primary"
}


do_nextboot_secondary() {
    ret=$(devmem 0x14c3744c 32)
	boot_source=${ret:9:1}

    if [ $boot_source -eq 0 ]; then
        devmem 0x14c37404 32 0x4C4B40
    else
        devmem 0x14c37404 32 0x0
    fi
    echo "SET next bmc boot secondary"
}


do_get_bmc_next_boot() {
    ret=$(devmem 0x14c3744c 32)
	boot_source=${ret:9:1}

    if [ $boot_source -eq 0 ]; then
        wdt2_cr=$(devmem 0x14c37404)
        if [ "${wdt2_cr}" != "0x00000000" ]; then
            echo "Secondary SPI"
        else
            echo "Primary SPI"
        fi
        return 0
    else
        wdt2_cr=$(devmem 0x14c37404)
        if [ "${wdt2_cr}" != "0x00000000" ]; then
            echo "Primary SPI"
        else
            echo "Secondary SPI"
        fi
        return 0
    fi
}

do_bmc_nextboot_action() {
    wdt2_cr=$(devmem 0x14c37404)
    if [ "${wdt2_cr}" != "0x00000000" ]; then
        set_wdta
    else
        sleep 5
		reboot
    fi
    return 0
}

do_status_bios() {
    bios_status_str=`cat ${BASECPLD_SYSFS_DIR}/bios_sel_status`
    bios_status=${bios_status_str:0:3}
    if [[ "$bios_status" == "0x0" ]]; then
        echo "Primary SPI"
    else
        echo "Secondary SPI"
    fi
}

do_bios_nextboot_setting() {
    next_boot=$1
    if [[ "$next_boot" == "primary" ]]; then
        echo "set BIOS next boot: primary BIOS."
        echo 0 > ${BASECPLD_SYSFS_DIR}/bios_manual_switch
        sleep 1
        echo out > /tmp/gpionames/BIOS_FLASH_SEL/direction
        sleep 1
        echo 1 > /tmp/gpionames/BIOS_FLASH_SEL/value
        sleep 1
        echo 0 > /tmp/gpionames/BIOS_FLASH_SEL/value
        sleep 1
        echo 1 > /tmp/gpionames/BIOS_FLASH_SEL/value
        sleep 1
    elif [[ "$next_boot" == "secondary" ]]; then
        echo "set BIOS next boot: secondary BIOS."
        echo 1 > ${BASECPLD_SYSFS_DIR}/bios_manual_switch
        sleep 1
        echo out > /tmp/gpionames/BIOS_FLASH_SEL/direction
        sleep 1
        echo 1 > /tmp/gpionames/BIOS_FLASH_SEL/value
        sleep 1
        echo 0 > /tmp/gpionames/BIOS_FLASH_SEL/value
        sleep 1
        echo 1 > /tmp/gpionames/BIOS_FLASH_SEL/value
        sleep 1
    fi
}

do_bios_nextboot_action() {
    echo "action BIOS next boot setting"
    echo 0 > ${BASECPLD_SYSFS_DIR}/cpu_force_pwr_off
    sleep 10
    echo 0 > ${BASECPLD_SYSFS_DIR}/cpu_12v_ctrl
    sleep 3
    echo 1 > ${BASECPLD_SYSFS_DIR}/cpu_12v_ctrl
    sleep 3
    echo 1 > ${BASECPLD_SYSFS_DIR}/cpu_pwr_up_en
}

do_set_bios_next_boot() {
    next_boot=$1
    if [[ "$next_boot" == "primary" ]]; then
        do_bios_nextboot_setting primary
        do_bios_nextboot_action
    elif [[ "$next_boot" == "secondary" ]]; then
        do_bios_nextboot_setting secondary
        do_bios_nextboot_action
    fi
}

do_get_bios_next_boot() {
    next_boot_status=`cat ${BASECPLD_SYSFS_DIR}/bios_manual_switch`
    next_boot=${next_boot_status:0:3}
    if [[ "$next_boot" == "0x0" ]]; then
        echo "Primary SPI"
    elif [[ "$next_boot" == "0x1" ]]; then
        echo "Secondary SPI"
    fi
}

if [ $# -lt 2 ]; then
    usage
    exit -1
fi

type="$1"
command="$2"
shift


case "$command" in
    status)
        if [[ $type == "bios" ]]; then
            do_status_bios
        elif [[ $type == "bmc" ]]; then
            do_status $@
        else
            usage
            exit -1
        fi
        ;;
    secondary)
        if [[ $type == "bios" ]]; then
            do_set_bios_next_boot secondary
        elif [[ $type == "bmc" ]]; then
            do_set_bmc_boot_code $command
        else
            usage
            exit -1
        fi
        ;;
    primary)
        if [[ $type == "bios" ]]; then
            do_set_bios_next_boot primary
        elif [[ $type == "bmc" ]]; then
            do_set_bmc_boot_code $command
        else
            usage
            exit -1
        fi
        ;;
    nextboot_secondary)
        if [[ $type == "bios" ]]; then
            do_bios_nextboot_setting secondary
        elif [[ $type == "bmc" ]]; then
            do_nextboot_secondary $@
        else
            usage
            exit -1
        fi
        ;;
    nextboot_primary)
        if [[ $type == "bios" ]]; then
            do_bios_nextboot_setting primary
        elif [[ $type == "bmc" ]]; then
            do_nextboot_primary $@
        else
            usage
            exit -1
        fi
        ;;
    action)
        if [[ $type == "bios" ]]; then
            do_bios_nextboot_action
            echo "BIOS will reboot from next boot. Please waiting ..."
        elif [[ $type == "bmc" ]]; then  
            echo "BMC will reboot from next boot. Auto reboot #in 10s."
            echo "system will reset..."
            do_bmc_nextboot_action
        else
            usage
            exit -1
        fi
        ;;
    nextboot)
        if [[ $type == "bios" ]]; then
            do_get_bios_next_boot
        else
            do_get_bmc_next_boot
        fi
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
