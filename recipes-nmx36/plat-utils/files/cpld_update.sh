#!/bin/bash
prog="$0"
JTAG_CTRL_NODE="/sys/bus/i2c/devices/0-000d/jtag_sel"


usage() {
    echo "Usage: "
    echo "$prog update <cpld> <file>"
    echo "$prog refresh <cpld> <file>"
    echo
    echo "Commands:"
    echo "  update: Update cpld."
    echo
    echo "  refresh: Refresh to apply.BMC reboot at last."   
    echo
    echo "  cpld: basecpld/ocmcpld/fancpld/misccpld/portcpld1/portcpld2/lccpld"  
    echo
}


jtag_ctrl(){
    cpld_type="$1"
    case "$cpld_type" in
        basecpld)
		    value=0x3f
		    ;;
        ocmcpld)
		    value=0x3e
		    ;;
        fancpld)
		    value=0x3d
		    ;;
        misccpld)
		    value=0xbb
		    ;;
        portcpld1)
		    value=0x9b
		    ;;
        portcpld2)
		    value=0xab
		    ;;
        lccpld)
		    value=0xb3
		    ;;
        *)
		    usage
		    exit -1
		    ;;
    esac
    echo $value > $JTAG_CTRL_NODE
    jtag_sel_s=`cat $JTAG_CTRL_NODE`
    jtag_sel=${jtag_sel_s:0:4}
    #echo "jtag_sel:$jtag_sel"
    if [[ "$value" != "$jtag_sel" ]]; then
        echo "jtag select fail.read $jtag_sel ecpect:$value"
        exit -1
    fi
}

cpld_update(){
    cpld="$1"
    img="$2"
    ispvm "$cpld" "$img"
    result=$?
    #recovery GPIO default status
    #gpio_set_value Online_JTAG_SEL1 0
    #gpio_set_value Online_JTAG_SEL2 0
    # 1 is returned upon upgrade success

    if [ $result -eq 1 ]; then
        #echo "Upgrade successful."
        return 0
    else
        #echo "Upgrade failure. Return code from utility : result"
        return 1
    fi
}

source /usr/local/bin/openbmc-utils.sh

command="$1"
cpld="$2"
image="$3"

case "$command" in
    update)
        if [ $# -gt 3 ]; then
            usage
            exit -1
        fi
        jtag_ctrl $cpld
        cpld_update $cpld $image
        if [ "$?" -eq "0" ]; then
            echo "Upgrade $cpld $image DONE."
            echo "Upgrade successful."
        else
            echo "Upgrade $cpld $image FAILED."
            echo "Upgrade failure. Return code from utility : result"
        fi
        ;;
    refresh)
        if [ $# -ne 3 ]; then
            usage
            exit -1
        fi
        jtag_ctrl $cpld
        if [ "$cpld" == "basecpld" ]; then
            ##GPIOP2 BASE CPLD IO Mode
            echo "Set GPIOP2 1"
            gpio_set_value BMC_SPI_UPDATE_CTRL 1
        fi
        cpld_update $cpld $image
        if [ "$?" -eq "0" ]; then
            echo "Refresh $cpld $image DONE."
            echo "Upgrade successful."
        else
            echo "Refresh $cpld $image FAILED."
            echo "Upgrade failure. Return code from utility : result"
        fi
        if [ "$cpld" == "basecpld" ]; then
            ##GPIOP2 BASE CPLD IO Mode
            echo "Set GPIOP2 0"
            gpio_set_value BMC_SPI_UPDATE_CTRL 0
        fi
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?

