#!/bin/bash


has_error=0


read_cpld_reg()
{
    reg=$1
    reg_str=`printf "0x%02X" $reg`
    reg_val_str=`switch_cpld.sh read 1 $reg_str | awk '{print $6}'`
    echo "$reg_val_str"
}

get_cpld_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_cpld_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%02X' $bit_mask`
    reg_new_val=$(($reg_val&$bit_mask_str))
    [ 0 -eq $reg_new_val ] && ret=0 || ret=1
    #echo ""
    echo "reg_val=$reg_val,bit_mask_str=$bit_mask_str,reg_new_val=$reg_new_val,ret=$ret" >>reg_read
    return $ret
}

BMC_STATUS=0x22
BMC_POWER_EN=0x23
CPU_RST_BUTTON=0x30

BMC_PG=1
BMC_WDO_L=0
BMC_WDO_H=1
BMC_PRESENT_N=0
BMC_EMMC_PGDOWN_N=1
BMC_POWER_FORCE_OFF=1
BMC_CPU_RST_OUT=1

do_gpio_check()
{
    local ral
    ral=0

    get_cpld_reg_bit $BMC_STATUS 0
    bmc_pg_value=$?
    if [[ ${bmc_pg_value} -ne ${BMC_PG} ]]; then
        echo "The GPIO BMC_PG check failed, reg_value:$bmc_pg_value,verify:$BMC_PG"
		ral=$(($ral+1))
    else
        echo "The GPIO BMC_PG check succeeded"
    fi
    echo out > /tmp/gpionames/BMC_WDO/direction
    echo $BMC_WDO_L > /tmp/gpionames/BMC_WDO/value
    get_cpld_reg_bit $BMC_STATUS 1
    bmc_wdt_value_l=$?
    echo $BMC_WDO_H > /tmp/gpionames/BMC_WDO/value
    get_cpld_reg_bit $BMC_STATUS 1
    bmc_wdt_value_h=$?
    if [[ ( ${bmc_wdt_value_l} -ne ${BMC_WDO_L} ) || ( ${bmc_wdt_value_h} -ne ${BMC_WDO_H} ) ]]; then
        echo "The GPIO BMC_WDO check failed, reg_value:$bmc_wdt_value_l,verify:$BMC_WDO_L reg_value:$bmc_wdt_value_h,verify:$BMC_WDO_H" 
		ral=$(($ral+1))
    else
        echo "The GPIO BMC_WDO check succeeded"
    fi
    echo in > /tmp/gpionames/BMC_WDO/direction
    get_cpld_reg_bit $BMC_STATUS 2
    bmc_present_value=$?
    if [[ ${bmc_present_value} -ne ${BMC_PRESENT_N} ]]; then
        echo "The GPIO BMC_PRESENT_N check failed, reg_value:$bmc_present_value,verify:$BMC_PRESENT_N"
		ral=$(($ral+1))
    else
        echo "The GPIO BMC_PRESENT_N check succeeded"
    fi
    get_cpld_reg_bit $BMC_POWER_EN 1
    bmc_emmc_pgdown_value=$?
    if [[ ${bmc_emmc_pgdown_value} -ne ${BMC_EMMC_PGDOWN_N} ]]; then
        echo "The GPIO BMC_EMMC_PGDOWN_N check failed, reg_value:$bmc_emmc_pgdown_value,verify:$BMC_EMMC_PGDOWN_N"
		ral=$(($ral+1))
    else
        echo "The GPIO BMC_EMMC_PGDOWN_N check succeeded"
    fi
    get_cpld_reg_bit $BMC_POWER_EN 2
    bmc_pwr_en_value=$?
    if [[ ${bmc_pwr_en_value} -ne ${BMC_POWER_FORCE_OFF} ]]; then
        echo "The GPIO BMC_POWER_FORCE_OFF check failed, reg_value:$bmc_pwr_en_value,verify:$BMC_POWER_FORCE_OFF"
		ral=$(($ral+1))
    else
        echo "The GPIO BMC_POWER_FORCE_OFF check succeeded"
    fi
    get_cpld_reg_bit $CPU_RST_BUTTON 1
    cpu_reset_button_value=$?
    if [[ ${cpu_reset_button_value} -ne ${BMC_CPU_RST_OUT} ]]; then
        echo "The GPIO BMC_CPU_RST_OUT check failed, reg_value:$cpu_reset_button_value,verify:$BMC_CPU_RST_OUT"
		ral=$(($ral+1))
    else
        echo "The GPIO BMC_CPU_RST_OUT check succeeded"
    fi
    if [[ $ral -ne 0 ]]; then
        echo "The GPIO check failed"
        return -1
    else
        echo "The GPIO check succeeded"
        return 0
    fi
}

usage() {
    echo "Usage: $0"
    echo
}

if [ $# -gt 1 ]; then
    usage
    exit -1
fi

do_gpio_check

exit $?




# GPIOB0 BMC_NMI_N
# GPIOB3 BMC_SMI_N
# GPIO: B0 B3
#for loop in 8 11
#do
#    cd /sys/class/gpio/gpio$loop
#    echo out > direction
#    echo 1 > value
#    test_value=`cat value`
#    if [ "$test_value" != "1" ]; then
#        echo "error gpio${loop}: value write 1, read is $test_value"
#        has_error=1
#    fi
#
#    echo 0 > value
#    test_value2=`cat value`
#    if [ "$test_value2" != "0" ]; then
#        echo "error gpio${loop}: value write 0, read is $test_value"
#        has_error=1
#    fi
#
#    if [ $has_error -eq 0 ]; then
#        echo "gpio$loop test OK"
#    fi
#done
#
#if [ $has_error -eq 0 ]; then
#    echo "Check BMC GPIO: PASS"
#fi
