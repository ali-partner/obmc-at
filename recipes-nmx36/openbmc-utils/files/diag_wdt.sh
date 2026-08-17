#!/bin/bash

PROGRAM_TITLE=`basename $0`

###############################################################################
# Function.
source /usr/local/bin/diag_wdt_func.sh

usage() {
    echo "Usage: $PROGRAM_TITLE [WDT_INDEX] [on senconds/off]"
    echo ""
    echo "Examples:"
    echo "      $PROGRAM_TITLE              show all WDT status."
    echo "      $PROGRAM_TITLE 1            show WDT #1 status."
    echo "      $PROGRAM_TITLE 1 on 30      enable WDT #1, and system 30s will be reset."
    echo "      $PROGRAM_TITLE 1 off        disable WDT #1."
}

###############################################################################
# Start of the script.

# Start of the script.
if [ $# -gt 3 ]; then
    usage
    exit -1
fi

# Show all WDT status.
if [ $# -eq 0 ]; then
    show_wdt_status 1
    show_wdt_status 2
    show_wdt_status 3
    exit 0
fi


wdt_index=$1
if [[ "X$wdt_index" != "X1" && "X$wdt_index" != "X2" && "X$wdt_index" != "X3" ]]; then
    if [ "X$1" != "X-h" ]; then
        echo "WDT_INDEX is out of range, should be 1~3."
    fi
    usage
    exit -1
fi
# Show single WDT status.
if [ $# -eq 1 ]; then
    show_wdt_status $wdt_index
    exit 0
fi


wdt_state=$2
wdt_timeout=$3
case "$wdt_state" in
    on)
        set_wdt_status_on $wdt_index $wdt_timeout
        ;;
    off)
        set_wdt_status_off $wdt_index
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?

