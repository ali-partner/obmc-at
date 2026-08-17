#!/bin/bash

COPPER_STATUS_REG=0x09
COPPER_CONTROL_REG=0x00
###############################################################################
# Function.
#RDB REG
read_rdb_reg()
{
    reg=$1
    reg_str=`printf "0x%04X" $reg`
    reg_write=`ast-mdio.py --mdio 3 --phy 0x09 write 0x1e $reg_str`
    reg_val_str=`ast-mdio.py --mdio 3 --phy 0x09 read 0x1f | awk '{print $5}'`
    echo "$reg_val_str"
}

write_rdb_reg()
{
    reg=$1
    reg_val_str=$2
    reg_str=`printf "0x%04X" $reg`
    ast-mdio.py --mdio 3 --phy 0x09 write 0x1e $reg
    ast-mdio.py --mdio 3 --phy 0x09 write 0x1f $reg_val_str
    return $?
}

set_rdb_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_rdb_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%04X' $bit_mask`
    #echo "bit_mask_str=$bit_mask_str"
    reg_new_val=$(($reg_val | $bit_mask_str))
    write_rdb_reg $reg $reg_new_val
    return $?
}

clr_rdb_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_rdb_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%04X' $((~$bit_mask))`
    reg_new_val=$(($reg_val & $bit_mask_str))
    write_rdb_reg $reg $reg_new_val
    return $?
}

get_rdb_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_rdb_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%04X' $bit_mask`
    reg_new_val=$(($reg_val & $bit_mask_str))
    #echo "reg_val ${reg_new_val}"
    [ 0 -eq $reg_new_val ] && ret=0 || ret=1

    return $ret
}

#IEEE REG
read_reg()
{
    reg=$1
    reg_str=`printf "0x%04X" $reg`
    reg_val_str=`ast-mdio.py --mdio 3 --phy 0x09 read $reg_str | awk '{print $5}'`
    echo "$reg_val_str"
}

write_reg()
{
    reg=$1
    reg_val_str=$2
    reg_str=`printf "0x%04X" $reg`
    ast-mdio.py --mdio 3 --phy 0x09 write $reg $reg_val_str
    return $?
}

set_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%04X' $bit_mask`
    reg_new_val=$(($reg_val | $bit_mask_str))
    write_reg $reg $reg_new_val
    return $?
}

clr_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%04X' $((~$bit_mask))`
    reg_new_val=$(($reg_val & $bit_mask_str))
    write_reg $reg $reg_new_val
    return $?
}

get_reg_bit()
{
    reg=$1
    bit=$2

    reg_val=`read_reg $reg`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%04X' $bit_mask`
    reg_new_val=$(($reg_val & $bit_mask_str))
    [ 0 -eq $reg_new_val ] && ret=0 || ret=1

    return $ret
}

###############################################################################

do_read_phy_check()
{
    status_reg=0x36
    set_rdb_reg_bit $status_reg 3

    if [ $? -eq 0 ]; then
        echo "write success"
    else
        echo "write failed"
    fi
}

do_read_port_link_status()
{
    status_reg=$COPPER_STATUS_REG
    #1'b1 Link is up 
    #1'b0 Link is up 
    get_rdb_reg_bit $status_reg 2

    if [ $? -eq 1 ]; then
        # Link is up
        echo "Link is up"
    else
        # Link is down
        echo "Link is down"
    fi
}

do_read_get_port_speed()
{
    status_reg=$COPPER_STATUS_REG
    reg_val=`read_rdb_reg $status_reg`
    speed_val=$((($reg_val >> 8) & 0x7))
    #echo "speed_val ${speed_val}"

    case "$speed_val" in
        0)
            echo "NO highest common denominator or auto-negotiaton not complete"
            ;;
        1)
            echo "100BASE half-duplex"
            ;;
        2)
            echo "100BASE full-duplex"
            ;;
        3)
            echo "100BASE-TX half-duplex"
            ;;
        4)
            echo "100BASE-T4"
            ;;
        5)
            echo "100BASE-TX full-duplex"
            ;;
        6)
            echo "1000BASE-T half-duplex"
            ;;
        7)
            echo "1000BASE-T full-duplex"
            ;;
        *)
            echo "unknown"
            exit -1
            ;;
    esac
}

LSB_SPEED_BIT=13
MSB_SPEED_BIT=6
COPPER_AN_BIT=12

do_read_set_port_speed()
{
    speed=$2
    status_reg=$COPPER_CONTROL_REG
    echo "speed: $speed"
    reg_val=`read_reg $status_reg`
    echo "reg value: $reg_val"
    case "$speed" in
        100)
            #Copper auto-negotiation disable 
            #clr_reg_bit $status_reg 12
            #Set 100BASE-TX
            #clr_reg_bit $status_reg 6
            #set_reg_bit $status_reg 13
            #Copper auto-negotiation disable 
            bit_mask3=$((1<<$COPPER_AN_BIT))
            bit_mask_str3=`printf '0x%04X' $((~$bit_mask3))`
            reg_new_val=$(($reg_val&$bit_mask_str3))

            #Set 100BASE-TX
            bit_mask1=$((1<<$LSB_SPEED_BIT ))
            bit_mask_str1=`printf '0x%04X' $bit_mask1`
            reg_new_val=$(($reg_new_val|$bit_mask_str1))

            bit_mask2=$((1<<$MSB_SPEED_BIT))
            bit_mask_str2=`printf '0x%04X' $((~$bit_mask2))`
            reg_new_val=$(($reg_new_val&$bit_mask_str2))

            ;;
        1000)
            #Copper auto-negotiation enable 
            #set_reg_bit $status_reg 12
            #Set 1000BASE-T
            #set_reg_bit $status_reg 6
            #clr_reg_bit $status_reg 13

            #Copper auto-negotiation enable 
            bit_mask3=$((1<<$COPPER_AN_BIT))
            bit_mask_str3=`printf '0x%04X' $bit_mask3`
            reg_new_val=$(($reg_val|$bit_mask_str3))

            #Set 1000BASE-T
            bit_mask1=$((1<<$LSB_SPEED_BIT ))
            bit_mask_str1=`printf '0x%04X' $((~$bit_mask1))`
            reg_new_val=$(($reg_new_val&$bit_mask_str1))

            bit_mask2=$((1<<$MSB_SPEED_BIT))
            bit_mask_str2=`printf '0x%04X' $bit_mask2`
            reg_new_val=$(($reg_new_val|$bit_mask_str2))

            ;;
        *)
            echo "unknown"
            exit -1
            ;;
    esac
    write_reg $status_reg $reg_new_val
    return $?

}

prog="$0"

usage() {
    echo "Usage: $prog <command>"
    echo
    echo "Commands:"
    echo " status: MGMT link status "
    echo
    echo " speed: MGMT speed "
    echo
    echo " set <1000/100> : Set MGMT speed "
    echo
}

if [ $# -gt 3 ]; then
    usage
    exit -1
fi

command=$1

case "$command" in
    status)
        do_read_port_link_status $@
        ;;
    speed)
        do_read_get_port_speed $@
        ;;
    set)
        do_read_set_port_speed $@
        ;;
    check)
        do_read_phy_check $@
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?