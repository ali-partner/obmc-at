#!/bin/bash


usage(){
    echo "Usage: $0 [check/set]"
    echo
}

boot_spi_check(){
    regval=`devmem 0x1E6E2510`
    echo "SCU510 Hardware Strap2 Register(0x1E6E2510): " $regval
    calval=$(($(($regval >> 11)) & 0x3))
    if [ $calval -eq 1 ]; then
        echo "Check OTP boot: PASS"
    else
        echo "Check OTP boot: FAIL"
        exit -1
    fi
}

boot_spi_set(){
    echo "Set OTP boot ... "
    echo -e 'YES' | otp pb strap 2B 1
    sleep 1
    echo -e 'YES' | otp pb strap 2C 0
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
