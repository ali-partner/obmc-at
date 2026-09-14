#!/bin/bash

WDT_BASE_REG=0x14C37000

WDT_REG_OFFSET=0x80

WDT_COUNTER_STATUS=0x00
WDT_COUNTER_RELOAD=0x04
WDT_COUNTER_RESTART=0x08
WDT_CONTROL=0x0C
WDT_TIMEOUT_STATUS=0x10
WDT_TIMEOUT_CLEAR=0x14
WDT_RESET_MASK=0x1C

###############################################################################
# Function.

read_reg()
{
    reg=$1
    reg_str=`printf "0x%08X" $reg`

    reg_val_str=`busybox devmem $reg_str 32`
    echo "$reg_val_str"
}

write_reg()
{
    reg=$1
    reg_val_str=$2

    reg_str=`printf "0x%08X" $reg`
    busybox devmem $reg_str 32 $reg_val_str
    return $?
}

set_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%08X' $bit_mask`
    reg_new_val=$(($reg_val|$bit_mask_str))
    write_reg $reg $reg_new_val
    return $?
}

clr_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%08X' $((~$bit_mask))`
    reg_new_val=$(($reg_val&$bit_mask_str))
    write_reg $reg $reg_new_val
    return $?
}

get_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%08X' $bit_mask`
    reg_new_val=$(($reg_val&$bit_mask_str))
    [ 0 -eq $reg_new_val ] && ret=0 || ret=1

    return $ret
}


get_wdt_reg_addr()
{
    index=$1
    reg=$2

    wdt_reg=$(( $WDT_BASE_REG + $WDT_REG_OFFSET * ($index - 1) + $reg))
    printf "0x%08X" $wdt_reg
}

show_wdt_status()
{
    index=$1
    wdt_reg=`get_wdt_reg_addr $index $WDT_CONTROL`

    get_reg_bit $wdt_reg 0

    if [ $? -eq 0 ]; then
        # disable
        echo "WDT $index: off"
    else
        # enable
        echo "WDT $index: on"
    fi

    wdt_reg=`get_wdt_reg_addr $index $WDT_COUNTER_STATUS`
    printf "            status  (0x%08X) = 0x%08X\n" $wdt_reg `read_reg $wdt_reg`

    wdt_reg=`get_wdt_reg_addr $index $WDT_COUNTER_RELOAD`
    printf "            reload  (0x%08X) = 0x%08X\n" $wdt_reg `read_reg $wdt_reg`

    wdt_reg=`get_wdt_reg_addr $index $WDT_CONTROL`
    printf "            ctrl    (0x%08X) = 0x%08X\n" $wdt_reg `read_reg $wdt_reg`

    wdt_reg=`get_wdt_reg_addr $index $WDT_TIMEOUT_STATUS`
    printf "            timeout (0x%08X) = 0x%08X\n" $wdt_reg `read_reg $wdt_reg`

    wdt_reg=`get_wdt_reg_addr $index $WDT_RESET_MASK`
    printf "            mask    (0x%08X) = 0x%08X\n" $wdt_reg `read_reg $wdt_reg`
}

set_wdt_off()
{
    index=$1

    # 1. disable the watchdog timer
    wdt_reg=`get_wdt_reg_addr $index $WDT_CONTROL`
    clr_reg_bit $wdt_reg 0
    clr_reg_bit $wdt_reg 1

    # 2. show the watchdog status
    show_wdt_status $index
}


set_wdt_on()
{
    index=$1

    # 1. disable watchdog timer
    set_wdt_off $index

    # 2. set Reload register
    timeout=$2 #  seconds timeout, wait for 'systemctl exit'
    wdt_reg=`get_wdt_reg_addr $index $WDT_COUNTER_RELOAD`
    timeout_str=`printf "0x%X" $((1000000*$timeout))`
    write_reg $wdt_reg $timeout_str

    # 3. write 0x4755 to Restart register
    wdt_reg=`get_wdt_reg_addr $index $WDT_COUNTER_RESTART`
    write_reg $wdt_reg 0x4755

    # 4. set WDT CONTROL.
    wdt_reg=`get_wdt_reg_addr $index $WDT_CONTROL`
    #set_reg_bit $wdt_reg 4 # WDT# 0C[4] can not be changed.
    #clr_reg_bit $wdt_reg 6
    #set_reg_bit $wdt_reg 5
    set_reg_bit $wdt_reg 1
    set_reg_bit $wdt_reg 3

    # 5. enable watchdog timer
    wdt_reg=`get_wdt_reg_addr $index $WDT_CONTROL`
    set_reg_bit $wdt_reg 0

    # 6. show the watchdog status
    show_wdt_status $index

    # 7. disable the watchdog timer now??

    echo "BMC SOC will be reset..."

    return 0
    # Below is DEBUG code.
    timeout=1
    while true
    do
        sleep 1
        echo "time: $timeout"
        timeout=$((1+$timeout))
        show_wdt_status $index
    done
}


set_wdt_status_off()
{
    set_wdt_off $1
}

set_wdt_status_on()
{
    set_wdt_on $1 $2
}

