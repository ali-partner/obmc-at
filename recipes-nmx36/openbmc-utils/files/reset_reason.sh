#!/bin/bash


usage() {
    echo "Usage: $0 [cpu]"
    echo
}

cpu_rst_reason(){
    rst=`i2cget -f -y 0 0xd 0x10`
    rst1=$(($rst >> 1 & 0x1))
    rst2=$(($rst & 0x1))
    if [ $rst1 -eq 1 ]; then
        echo "CPU reset reason: cold reset"
    elif [ $rst2 -eq 1 ]; then
        echo "CPU reset reason: warm reset"
    else
        echo "CPU reset reason: no reset"
    fi
}


if [ $# -ne 1 ]; then
    usage
    exit -1
fi

object="$1"

case "$object" in
    cpu)
        cpu_rst_reason
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
