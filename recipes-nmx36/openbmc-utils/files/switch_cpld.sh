. /usr/local/bin/openbmc-utils.sh
prog="$0"

product_name=$(cat /etc/openbmc/product_name)

CS_OCM_CPLD=0
CS_SYS_CPLD=1
CS_FAN1_CPLD=2
CS_FAN2_CPLD=3
CS_MISC_CPLD=4
CS_PORT_CPLD1=5
CS_PORT_CPLD2=6
CS_LED_CPLD=7
CS_SWITCH_FPGA=8

usage() {
    echo "Usage: "
    echo "$prog read <cs> <offset>"
    echo "$prog write <cs> <offset> <data>"
    echo
    echo "cs value:"
    echo "  $CS_OCM_CPLD: OCM CPLD"
    echo "  $CS_SYS_CPLD: SYS(Base) CPLD"
    echo "  $CS_FAN1_CPLD: FAN1 CPLD"
    echo "  $CS_FAN2_CPLD: FAN2 CPLD"
    echo "  $CS_MISC_CPLD: MISC CPLD"
    echo "  $CS_PORT_CPLD1: PORT CPLD1"
    echo "  $CS_PORT_CPLD2: PORT CPLD2"
    echo "  $CS_LED_CPLD: LED CPLD"
    echo "  $CS_SWITCH_FPGA: Switch FPGA"
    echo
}


do_read_cpld()
{
    cs=$1
    offset=$2
    bus=(16 0 8 3 66 64 65 68 67)
    addr=(0xd 0xd 0xd 0xd 0x31 0x31 0x31 0x31 0x32)
    data=`i2cget -f -y ${bus[$cs]} ${addr[$cs]} $offset`
    echo "Read: cs($cs) offset($offset) data = $data"
}

do_write_cpld()
{
    cs=$1
    offset=$2
	value=$3
    bus=(16 0 8 3 66 64 65 68 67)
    addr=(0xd 0xd 0xd 0xd 0x31 0x31 0x31 0x31 0x32)
    data=`i2cset -f -y ${bus[$cs]} ${addr[$cs]} $offset $value`
    echo "Write: cs($cs) offset($offset) data = $value"
}

if [ "$#" -ne 3 ] && [ "$#" -ne 4 ]; then
    usage
    exit 1
fi
commond="$1"
cs=$2
offset=$3

if [ $cs -gt $CS_SWITCH_FPGA ]; then
    echo -e "Wrong parameter, cs is larger than $CS_SWITCH_FPGA.\n"
    usage
    exit -1
fi


case "$commond" in
    read)
        do_read_cpld $cs $offset
        ;;
    write)
        data=$4
        do_write_cpld $cs $offset $data
        ;;
    *)
        echo "cmd err"
        usage
        exit -1
        ;;
esac
