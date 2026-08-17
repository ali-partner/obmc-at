#!/bin/bash


BMC_PECI_CPU_ID_str="00 40 00 00 00 00 00 00"
BMC_PCH_PECI_CPU_ID_str="57 01 00 90 00 00 00 00 00 00 00"
has_error=0

Tjmax_str=`peci-util 0x30 0x05 0x05 0xa1 0x00 0x10 0x00 0x00`
sleep 1
Tjmax_val=0x`echo ${Tjmax_str:0-6:2}`
((Tjmax=Tjmax_val))

read_PECI_CPU(){
    PECI_string=`peci-util 0x30 0x01 0x08 0xf7`
    sleep 1
    PECI_str=`echo ${PECI_string:0:23}`
    if [ "$PECI_str" == "$BMC_PECI_CPU_ID_str" ]; then
        echo "CPU ID: Ture"
    else
        echo "CPU ID: False"
        has_error=-1
    fi
}

read_PCH_PECI_CPU(){
    PECI_string=`ipmb-util 13 0x2c 0xb8 0x40 0x57 0x01 0x00 0x30 0x01 0x08 0xf7`
    sleep 1
    PECI_str=`echo ${PECI_string:0:32}`
    if [ "$PECI_str" == "$BMC_PCH_PECI_CPU_ID_str" ]; then
        echo "CPU ID: Ture"
    else
        echo "CPU ID: False"
        has_error=-1
    fi
}

BMC_PECI_CPU(){
    CPU_str=$1
    CPU_val1=`echo ${CPU_str:0-3:2}`
    CPU_val2=`echo ${CPU_str:0-6:2}`
    CPU_val=0x${CPU_val1}${CPU_val2}
    sign_bit1=`echo ${CPU_str:0-3:1}`
    sign_bit=0x${sign_bit1}

    if [ "$(($sign_bit & 0x8))" == 8 ];then
        m=$((~$(($CPU_val-1)) & 0xffff))
        n=`awk -v x=$m -v y=64 'BEGIN {printf "%.2f\n",x/y}'`
        temp=`awk -v x=$Tjmax -v y=$n 'BEGIN {printf "%.2f\n",x-y}'`
    else
        ((m=$CPU_val))
        n=`awk -v x=$m -v y=64 'BEGIN {printf "%.2f\n",x/y}'`
        temp=`awk -v x=$Tjmax -v y=$n 'BEGIN {printf "%.2f\n",x+y}'`
    fi

    ret=`awk -v x=$temp -v y=0 'BEGIN{print(x>y)?"0":"1"}'`
    if [ $ret -ne 0 ]; then
        has_error=-1
    fi
    return $has_error
}

do_read_bmc_peci_cpu_temp(){

    echo "BMC -> PECI -> CPU test: "
    read_PECI_CPU
    PECI_CPU0_cmd=`peci-util 0x30 0x1 0x2 0x1`
    sleep 1
    BMC_PECI_CPU "$PECI_CPU0_cmd"
    echo "CPU temp: $temp"
    if [ $has_error -eq 0 ]; then
        echo "Check PECI bus: PASS"
    else
        echo "Check PECI bus: FAIL"
    fi
    return $has_error
}

do_read_bmc_peci_pch_temp(){

    echo "BMC -> PCH -> PECI -> CPU test: "
    echo out > direction
    echo 0 > value
    sleep 1
    read_PCH_PECI_CPU
    PCH_PECI_CPU0_cmd=`ipmb-util 13 0x2c 0xb8 0x40 0x57 0x01 0x00 0x30 0x01 0x02 0x01`
    sleep 1
    BMC_PECI_CPU "$PCH_PECI_CPU0_cmd"
    echo "CPU0 temp: $temp"
    if [ $has_error -eq 0 ]; then
        echo "Check PECI bus: PASS"
    else
        echo "Check PECI bus: FAIL"
    fi
    return $has_error
}

usage() {
    echo "Usage: $PROGRAM_TITLE [cpu|pch]"
    echo ""
    echo "Examples:"
    echo "      $PROGRAM_TITLE              BMC -> PECI -> CPU & BMC -> PCH -> PECI -> CPU test."
    echo "      $PROGRAM_TITLE cpu          BMC -> PECI -> CPU test."
    echo "      $PROGRAM_TITLE pch          BMC -> PCH -> PECI -> CPU test."
}

# BMC -> PECI -> CPU & BMC -> PCH -> PECI -> CPU test
if [[ $# -eq 0 ]]; then
    do_read_bmc_peci_cpu_temp
    do_read_bmc_peci_pch_temp
    exit $has_error
fi

if [[ $# -ne 1 && $# -ne 2 ]]; then
    usage
    exit -1
fi

mode=$1

case "$mode" in
    cpu)
        do_read_bmc_peci_cpu_temp
        ret=$?
        exit $ret
        ;;
    pch)
        do_read_bmc_peci_pch_temp
        ret=$?
        exit $ret
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?





