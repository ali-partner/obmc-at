#!/bin/bash


usage() {
    echo "Usage: $0 [bmc|bios] [primary|secondary]"
    echo
    echo "Examples:"
    echo "    boot_util.sh                   --Show BMC and BIOS boot status"
    echo "    boot_util.sh bmc               --Show BMC boot status"
    echo "    boot_util.sh bmc primary       --Set BMC to boot from primary after reboot"
    echo "    boot_util.sh bios              --Show BIOS boot status"
    echo "    boot_util.sh bios secondary    --Set BIOS to boot from secondary after reboot"
    echo
}

bmc_boot_status(){
    status=`boot_area.sh bmc status`
    retval1=`echo $status | grep "Primary"`
    retval2=`echo $status | grep "Secondary"`

    if [ "$retval1" != "" ]; then
        echo "BMC  boot: primary"
    elif [ "$retval2" != "" ]; then
        echo "BMC  boot: secondary"
    else
        echo "BMC  boot: unknown"
        exit -1
    fi    
}

bios_boot_status(){
    status=`boot_area.sh bios status`
    retval1=`echo $status | grep "Primary"`
    retval2=`echo $status | grep "Secondary"`

    if [ "$retval1" != "" ]; then
        echo "BIOS boot: primary"
    elif [ "$retval2" != "" ]; then
        echo "BIOS boot: secondary"
    else
        echo "BIOS boot: unknown"
        exit -1
    fi    
}


if [[ $# -gt 2 ]]; then
    usage
    exit -1
fi

if [[ $# -eq 0 ]]; then
    bmc_boot_status
    bios_boot_status
    exit 0
fi

object=$1
mode=$2

case "$object" in
    bmc)
        if [ "$mode" == "" ]; then
            bmc_boot_status
        elif [ "$mode" == "primary" ]; then
            boot_area.sh bmc primary
        elif [ "$mode" == "secondary" ]; then
            boot_area.sh bmc secondary
        else
            usage
            exit -1
        fi
        ;;
    bios)
        if [ "$mode" == "" ]; then
            bios_boot_status
        elif [ "$mode" == "primary" ]; then
            boot_area.sh bios primary
        elif [ "$mode" == "secondary" ]; then
            boot_area.sh bios secondary
        else
            usage
            exit -1
        fi
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
