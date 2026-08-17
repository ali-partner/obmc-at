#!/bin/bash

. /usr/local/bin/openbmc-utils.sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

usage() {
    echo "Usage: $prog <command>"
    echo
    echo "Commands:"
    echo
    echo "  state: show current state."
    echo
    echo "  bmc: Serial port switch to BMC UART."
    echo
    echo "  cpu: Serial port switch to CPU UART."
    echo
}

if [ $# -lt 1 ]; then
    usage
    exit -1
fi

uart_state() {
    local uart_state

    uart_state=`cat ${BASECPLD_SYSFS_DIR}/uart_status | head -n 1`
    if [ $uart_state == "0x1" ]; then
        echo -e "BMC\n"
    else
        echo -e "CPU\n"
    fi
    exit 0
}

switch_uart() {
    local sel
    local uart_state

    uart_state=`cat ${BASECPLD_SYSFS_DIR}/uart_status | head -n 1`
    if [ $1 == "bmc" ]; then
        if [ $uart_state == "0x1" ]; then
            echo -e "Already BMC Mode! Quit!\n"
            exit 1
        fi
        sel=1
        echo -n "Switch to BMC UART ..."
    else
        if [ $uart_state == "0x0" ]; then
            echo -e "Already CPU Mode! Quit!\n"
            exit 1
        fi
        sel=0
        echo -n "Switch to CPU UART ..."
    fi
    echo $sel > ${BASECPLD_SYSFS_DIR}/uart_sel
    echo 0x1 > ${BASECPLD_SYSFS_DIR}/uart_sel_update
    echo -e "Done\n"
    exit 0
}

command="$1"
case "$command" in
    state)
        uart_state $@
        ;;
    bmc)
        switch_uart $@
        ;;
    cpu)
        switch_uart $@
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?