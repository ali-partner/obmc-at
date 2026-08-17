#!/bin/bash
prog="$0"
JTAG_CTRL_NODE="/sys/bus/i2c/devices/0-000d/jtag_sel"

product_name=$(cat /etc/openbmc/product_name)

usage() {
    echo "Usage: "
    echo "$prog update <cpld> <file>"
    echo "$prog refresh <cpld> <file>"
    echo
    echo "Commands:"
    echo "  update: Update CPLD."
    echo
    echo "  refresh: Refresh to apply. BMC will reboot at last."
    echo
    echo "  cpld: basecpld / ocmcpld / fan1cpld / fan2cpld / misccpld / portcpld1 / portcpld2 / ledcpld"
    echo
}


jtag_ctrl(){
    cpld_type="$1"
    case "$cpld_type" in
        basecpld)
		    value=0x7f
		    ;;
        ocmcpld)
		    value=0x7e
		    ;;
        fan1cpld)
		    value=0x7d
		    ;;
        fan2cpld)
		    value=0x3f
		    ;;
        misccpld)
		    value=0xfb
		    ;;
        portcpld1)
		    value=0xdb
		    ;;
        portcpld2)
		    value=0xeb
		    ;;
        ledcpld)
		    value=0xcb
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
    #ispvm "$cpld" "$img"
    if [ $cpld == "basecpld" ];then
        gpio_set_value Online_JTAG_SEL1 1
        gpio_set_value Online_JTAG_SEL2 1
    else
        gpio_set_value Online_JTAG_SEL1 0
        gpio_set_value Online_JTAG_SEL2 1
    fi
    ispvm dll /usr/lib/libcpldupdate_dll_gpio.so "$img" --tms GPIO_JTAG_TMS --tdo GPIO_JTAG_TDO  --tdi GPIO_JTAG_TDI  --tck GPIO_JTAG_TCK
    result=$?
    #recovery GPIO default status
    gpio_set_value Online_JTAG_SEL1 0
    gpio_set_value Online_JTAG_SEL2 0
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

if [ ! -f $image ]; then
    echo -e "The file $image does not exist.\n"
    exit -1
fi


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
            echo "Set GPIOF3 1"
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
            echo "Set GPIOF3 0"
            gpio_set_value BMC_SPI_UPDATE_CTRL 0
        fi
        ;;

    *)
        usage
        exit -1
        ;;
esac

exit $?

