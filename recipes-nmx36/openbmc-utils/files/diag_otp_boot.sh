#!/bin/bash


usage(){
    echo "Usage: $0 [check/set]"
    echo
}

boot_spi_check(){
    regval=`devmem 0x14c02030`
    echo "SCU1_030 Hardware Strap2 Register(0x14c02030): " $regval
    calval1=$(($(($regval >> 0)) & 0x1))
    calval2=$(($(($regval >> 27)) & 0x1))
    if [ $calval1 -eq 1 ] && [ $calval2 -eq 1 ]; then
        echo "Check OTP boot: PASS"
    else
        echo "Check OTP boot: FAIL"
        exit -1
    fi
}

boot_spi_set(){
    echo "Set OTP boot ... "
    echo -e 'YES' | otp 0 pb strap-ext 0x20 1
    sleep 1
    echo -e 'YES' | otp 0 pb strap-ext-vld 0x20 1
    sleep 1
    echo -e 'YES' | otp 0 pb strap-ext 0x3B 1
    sleep 1
    echo -e 'YES' | otp 0 pb strap-ext-vld 0x3B 1
    sleep 1
    echo "Done."
}


if [ $# -ne 1 ]; then
    usage
    exit -1
fi

if [ "$1" == "check" ]; then
    boot_spi_check
elif [ "$1" == "set" ]; then
    boot_spi_set
else
    usage
    exit -1
fi
