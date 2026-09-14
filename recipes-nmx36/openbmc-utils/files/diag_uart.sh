#!/bin/bash


PROGRAM_TITLE=`basename $0`
SYSCPLD_PATH="/sys/bus/i2c/devices/0-000d"


usage() {
    echo "Usage: $PROGRAM_TITLE [retry_time]"
    echo ""
}

uartCommandLine() {
    # Start of the script.
    if [ $# -ne 1 ]; then
        usage
        exit -1
    fi
    echo 1 > ${SYSCPLD_PATH}/uart_sel
    echo 1 > ${SYSCPLD_PATH}/uart_sel_update
    num=$1
    for((i=1;i<=$num;i++));
    do 
        echo "machine UART test success" > /dev/ttyS0
        echo "The BMC set time {$i}"
        sleep 1
    done
    echo 0 > ${SYSCPLD_PATH}/uart_sel
    echo 1 > ${SYSCPLD_PATH}/uart_sel_update
    echo "The BMC set value to /dev/ttyS0"
    exit 0
}


# Start of the script.
uartCommandLine "$@"

exit $?