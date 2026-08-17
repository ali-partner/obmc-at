#!/bin/bash
. /usr/bin/openbmc-utils.sh

prog="$0"

usage() {
    echo "Usage: $prog <bmc/bios> <command>"
    echo
    echo "Commands:"
    echo "  status: Get the current boot area status."
    echo
    echo "  secondary: Bmc/bios boot from secondary SPI flash next time. Bmc auto reboot in 10s."
    echo
    echo "  primary: Bmc/bios boot from primary SPI flash next time. Bmc auto reboot in 10s."
    echo
    echo "  nextboot_secondary: Bmc boot from secondary SPI flash next time."
    echo
    echo "  nextboot_primary: Bmc boot from primary SPI flash next time."
    echo
    echo "  action: Bmc boot from next boot flash. Bmc auto reboot in 10s."
    echo
    echo "  nextboot: Get bios next boot area status."
    echo
}

set_wdt2() {
    # Set WDT2 time out 10s, 0x00989680 = 10,000,000 us
    devmem $(wdt_addr 24) 32 0x00989680

    # WDT2 magic number to restart WDT counter to decrease.
    devmem $(wdt_addr 28) 32 0x4755

    # No matter BMC boot from any one of master and slave.
    # Set bit_7 to 1 : Use second boot code whenever WDT reset.
    # And the "second boot code" stands for the other boot source.
    devmem_set_bit $(wdt_addr 2c) 0
}

do_status() {
    local val1
    local val2
    local tmp1
    local tmp2
    local tmp
    val1=$(devmem $(wdt_addr 10))
    val2=$(devmem $(wdt_addr 30))
    tmp1=$((val1 & (0x1 << 1)))
    tmp2=$((val2 & (0x1 << 1)))
    tmp=$((tmp1 | tmp2))
    if [ $tmp -eq 0 ]; then
        echo "Primary SPI"
    else
        echo "Secondary SPI"
    fi
}

# Please refer to reg WDT1/WDT2 Control Register definition to
# understand this code block, WDT1 is on page 646 of ast2500v16.pdf
# and WDT2 is on page 649 of ast2500v16.pdf
# Enable watchdog reset_system_after_timeout bit and WDT_enable_signal bit.
# Refer to ast2500v16.pdf page 650th.

do_primary() {
    local val1
    local val2
    local tmp1
    local tmp2
    local tmp
    
    val1=$(devmem $(wdt_addr 10))
    val2=$(devmem $(wdt_addr 30))
    tmp1=$((val1 & (0x1 << 1)))
    tmp2=$((val2 & (0x1 << 1)))
    tmp=$((tmp1 | tmp2))

    if [ $tmp -eq 0 ]; then
        echo "Current boot area is Primary SPI."
        exit
    else
        devmem $(wdt_addr 2c) 32 0xb2
    fi
    set_wdt2
    echo "BMC will reboot from primary SPI next time. Auto reboot in #10s."
    echo "system will reset..."
}

do_secondary() {
    local val1
    local val2
    local tmp1
    local tmp2
    local tmp
    
    val1=$(devmem $(wdt_addr 10))
    val2=$(devmem $(wdt_addr 30))
    tmp1=$((val1 & (0x1 << 1)))
    tmp2=$((val2 & (0x1 << 1)))
    tmp=$((tmp1 | tmp2))

    if [ $tmp -eq 0 ]; then
        devmem $(wdt_addr 2c) 32 0xb2
    else
        echo "Current boot area is Secondary SPI."
        exit
    fi
    set_wdt2
    echo "BMC will reboot from secondary SPI next time. Auto reboot #in 10s."
    echo "system will reset..."
}


do_nextboot_primary() {
    local val1
    local val2
    local tmp1
    local tmp2
    local tmp
    
    val1=$(devmem $(wdt_addr 10))
    val2=$(devmem $(wdt_addr 30))
    tmp1=$((val1 & (0x1 << 1)))
    tmp2=$((val2 & (0x1 << 1)))
    tmp=$((tmp1 | tmp2))

    if [ $tmp -eq 0 ]; then
        devmem $(wdt_addr 2c) 32 0x32
    else
        devmem $(wdt_addr 2c) 32 0xb2
    fi
    echo "SET next bmc boot primary"
}


do_nextboot_secondary() {
    local val1
    local val2
    local tmp1
    local tmp2
    local tmp
    
    val1=$(devmem $(wdt_addr 10))
    val2=$(devmem $(wdt_addr 30))
    tmp1=$((val1 & (0x1 << 1)))
    tmp2=$((val2 & (0x1 << 1)))
    tmp=$((tmp1 | tmp2))

    if [ $tmp -eq 0 ]; then
        devmem $(wdt_addr 2c) 32 0xb2
    else
        devmem $(wdt_addr 2c) 32 0x32
    fi

    echo "SET next bmc boot secondary"
}


do_get_bmc_next_boot() {
    local val1
    local val2
    local tmp1
    local tmp2
    local tmp

    val1=$(devmem $(wdt_addr 10))
    val2=$(devmem $(wdt_addr 30))
    tmp1=$((val1 & (0x1 << 1)))
    tmp2=$((val2 & (0x1 << 1)))
    tmp=$((tmp1 | tmp2))

    if [ $tmp -eq 0 ]; then
        wdt2_cr=$(devmem $(wdt_addr 2c))
        switch_bmc_flag=$((${wdt2_cr} & 0x00000080))
        if [ ${switch_bmc_flag} != 0 ]; then
            echo "Secondary SPI"
        else
            echo "Primary SPI"
        fi
        return 0
    else
        wdt2_cr=$(devmem $(wdt_addr 2c))
        switch_bmc_flag=$((${wdt2_cr} & 0x00000080))
        if [ ${switch_bmc_flag} != 0 ]; then
            echo "Primary SPI"
        else
            echo "Secondary SPI"
        fi
        return 0
    fi
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

do_set_bios_next_boot() {
    next_boot=$1
    if [[ "$next_boot" == "primary" ]]; then
        echo "set bios next boot: primary bios."
        echo 0 > ${BASECPLD_SYSFS_DIR}/cpu_force_pwr_off
        echo 0 > ${BASECPLD_SYSFS_DIR}/bios_manual_switch
        echo 1 > ${BASECPLD_SYSFS_DIR}/bios_manual_switch_update
        sleep 10 #todo
        echo 1 > ${BASECPLD_SYSFS_DIR}/cpu_pwr_up_en
    elif [[ "$next_boot" == "secondary" ]]; then
        echo "set bios next boot: secondary bios."
        echo 0 > ${BASECPLD_SYSFS_DIR}/cpu_force_pwr_off
        echo 1 > ${BASECPLD_SYSFS_DIR}/bios_manual_switch
        echo 1 > ${BASECPLD_SYSFS_DIR}/bios_manual_switch_update
        sleep 10 #todo
        echo 1 > ${BASECPLD_SYSFS_DIR}/cpu_pwr_up_en
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
            do_secondary $@
        else
            usage
            exit -1
        fi
        ;;
    primary)
        if [[ $type == "bios" ]]; then
            do_set_bios_next_boot primary
        elif [[ $type == "bmc" ]]; then
            do_primary $@
        else
            usage
            exit -1
        fi
        ;;
    nextboot_secondary)
        if [[ $type == "bios" ]]; then
            usage
            exit -1
        elif [[ $type == "bmc" ]]; then
            do_nextboot_secondary $@
        else
            usage
            exit -1
        fi
        ;;
    nextboot_primary)
        if [[ $type == "bios" ]]; then
            usage
            exit -1
        elif [[ $type == "bmc" ]]; then
            do_nextboot_primary $@
        else
            usage
            exit -1
        fi
        ;;
    action)
        if [[ $type == "bios" ]]; then
            usage
        elif [[ $type == "bmc" ]]; then
            set_wdt2
            echo "BMC will reboot from next boot. Auto reboot #in 10s."
            echo "system will reset..."
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
