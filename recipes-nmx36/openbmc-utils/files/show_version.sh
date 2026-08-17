#!/bin/bash


usage() {
    echo "Usage: $0 [OPTION]"
    echo "  show all version information."
    echo
    echo "OPTION:"
    echo "  bmc_date    show BMC release date"
    echo
}


if [ $# -eq 0 ]; then
    version.sh
    exit 0
fi

object=$1

case "$object" in
    bmc_date)
        cat /etc/version
        ;;
    *)  
        usage
        exit -1
        ;;
esac

