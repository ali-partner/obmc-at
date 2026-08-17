#!/bin/bash


PROGRAM_TITLE=`basename $0`


usage() {
    echo "Usage: $PROGRAM_TITLE [cpu|machine] [status|reset|on|off|cycle]"
    echo "Option:"
    echo "     cycle     --Power cycle host CPU or whole machine"
    echo "     status    --Show host CPU, this parameter ONLY for CPU"
    echo "     reset     --Reset host CPU, this parameter ONLY for CPU"
    echo "     on        --Power on host CPU, this parameter ONLY for CPU"
    echo "     off       --Power off host CPU, this parameter ONLY for CPU"
    echo
    echo "Example:"
    echo "     $PROGRAM_TITLE machine cycle    --Power cycle whole machine"
    echo "     $PROGRAM_TITLE cpu status       --Show host CPU status"
    echo "     $PROGRAM_TITLE cpu cycle        --Power cycle host CPU"
    echo
}


if [ $# -ne 1 ] && [ $# -ne 2 ]; then
    usage
    exit -1
fi

object="$1"
mode="$2"

case "$object" in
    cpu)
        case "$mode" in
            status)
                power.sh status
                ;;
            reset)
                power.sh reset
                ;;
            on)
                power.sh on
                ;;
            off)
                power.sh off
                ;;
            cycle)
                power.sh cpu_pwr_cycle
                ;;
            *)
                usage
                exit -1
                ;;
        esac
        ;;
    machine)
        case "$mode" in
            cycle)
                power.sh sys_pwr_cycle
                ;;
            *)
                usage
                exit -1
                ;;
        esac
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
