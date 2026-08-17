#!/bin/bash

PECI_CPU_ID="0x00 0x40 0x00 0x00 0x00 0x00 0x00 0x00"
has_error=0

read_PECI_CPU(){
    PECI_string=`peci_cmds raw 0x30 0x01 0x08 0xf7 | awk '{gsub(/^\s+|\s+$/, "");print}'`
    if [ "$PECI_string" != "$PECI_CPU_ID" ]; then
        echo "get CPU temperature fail"
        exit -1
    fi

    PECI_str=`peci_cmds raw 0x30 0x1 0x2 0x1 | awk '{gsub(/^\s+|\s+$/, "");print}'`
    PECI_val1=`echo $PECI_str | awk '{print $2}'`
    PECI_val2=`echo $PECI_str | awk '{print $1}'`
    BMC_PECI_CPU $PECI_val1 $PECI_val2

    echo "The CPU temperature: $temp"
    exit $has_error
}

BMC_PECI_CPU(){
    CPU_val1=`printf "%02x" $1`
    CPU_val2=`printf "%02x" $2`
    CPU_val=0x${CPU_val1}${CPU_val2}
    sign_bit=0x`echo ${CPU_val1:0:1}`

    if [ "$(($sign_bit & 0x8))" == 8 ];then
        m=$((~$(($CPU_val-1)) & 0xffff))
        n=`awk -v x=$m -v y=64 'BEGIN {printf "%.2f\n",x/y}'`
        temp=`awk -v x=$Tjmax -v y=$n 'BEGIN {printf "%d\n",x-y}'`
    else
        ((m=$CPU_val))
        n=`awk -v x=$m -v y=64 'BEGIN {printf "%.2f\n",x/y}'`
        temp=`awk -v x=$Tjmax -v y=$n 'BEGIN {printf "%d\n",x+y}'`
    fi

    ret=`awk -v x=$temp -v y=0 'BEGIN{print(x>y)?"0":"1"}'`
    if [ $ret -ne 0 ]; then
        has_error=-1
    fi
}

Tjmax_val=`peci_cmds raw 0x30 0x05 0x05 0xa1 0x00 0x10 0x00 0x00 | awk '{print $4}'`
((Tjmax=Tjmax_val))
sleep 0.5

read_PECI_CPU
