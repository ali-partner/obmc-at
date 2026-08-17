#!/bin/sh
  
. /usr/local/bin/openbmc-utils.sh

pca9534_ee_sel=0x22
pca9534_spi_sel=0x26
output_reg=0x1
mode_reg=0x3
debug=0
m95m02_page_size=256
m95m02_page_count=1024
SPI_PIN_ARGS="--cs 5387_EEPROM_CS --clk 5387_EEPROM_SCK \
              --mosi 5387_EEPROM_MOSI --miso 5387_EEPROM_MISO"

#trap cleanup_spi INT TERM QUIT EXIT

# $1: sysfs path, $2: value
function set_sysfs_value() {
    local path=$1
    local val=$(printf 0x%x $2)
    local ret=-1
    local retry=3
    echo "set $val to $path."
    while [ $ret != $val ] && [ $retry -gt 0 ];
    do
        echo $val > $path
        usleep 100
        ret=$(head -n1 $path 2> /dev/null)
        ((retry--))
    done
    if [ $ret != $val ]; then
        echo "debug cmd: set_sysfs_value fail, val=$val, ret=$ret"
        return -1
    fi
}


function check_flash_info()
{
    spi_no=$1
    flashrom -p linux_spi:dev=/dev/spidev${spi_no}.0
}

function get_flash_first_type()
{
    ori_str=$(check_flash_info ${spi_no})
    type=$(echo ${ori_str} | cut -d '"' -f 2)
    if [ $type ];then
        echo $type
        return 0
    else
        echo "Get flash type error: [$ori_str]"
        exit -1
    fi
}

function get_flash_size()
{
    spi_no=$1
    ori_str=$(check_flash_info ${spi_no})
    #flash_sz=$(echo ${ori_str} | cut -d '(' -f 3 | cut -d ' ' -f 1)
    flash_sz=$(echo ${ori_str} | cut -d '(' -f 4 | cut -d ' ' -f 1)
    echo $flash_sz | egrep -q '^[0-9]+$'
    num_ret=$?
    if [ $num_ret -eq 0 ];then
        echo $flash_sz
        return 0
    else
        echo "Get flash size error: [$ori_str]"
        return -1
    fi
}

# $1: input file size $2: flash size $3: output file path
function pad_ff()
{
    out_file=$3
    pad_size=$(($2 - $1))
    dd if=/dev/zero bs=$pad_size count=1 | tr "\000" "\377" >> $out_file
}

function resize_file()
{
    in_file=$1
    out_file=$2
    spi_no=$3
    storage_type=$4
    in_file_sz=`stat -c%s $in_file`
    storage_sz=0
    if [ $storage_type -a $storage_type = "m95m02" ];then
        storage_sz=$(($m95m02_page_count * $m95m02_page_size))
    else
        flash_sz=$(get_flash_size $spi_no)
        if [ $? -eq 0 ];then
            storage_sz=$(($flash_sz * 1024))
        else
            echo -e "debug message:\n $flash_sz"
            exit -1
        fi
    fi

    if [ $in_file_sz -ne $storage_sz ];then
        cp $in_file $out_file
        pad_ff $in_file_sz $storage_sz $out_file
    else
        ln -s $(realpath ${in_file}) ${out_file}
    fi
}

function dump_gpio_config(){
    if [ $debug = 0 ]; then
        return 0
    fi
    echo "Dump SPI configurations..."
    if [ $1 = "SPI1" ];then
        openbmc_gpio_util.py dump | grep SPI1
    else
        openbmc_gpio_util.py dump | grep SPI2
    fi
}

function set_spi1_to_spi(){
    devmem_clear_bit $(scu_addr 90) 6  
    devmem_set_bit $(scu_addr 70) 12  
    dump_gpio_config SPI1
}

function read_flash_to_file()
{
    spi_no=$1
    file=$2
    modprobe -r spidev
    modprobe spidev
    type=$(get_flash_first_type $spi_no)
    flashrom -p linux_spi:dev=/dev/spidev${spi_no}.0 -r $file -c $type
    if [ $? -ne 0 ];then
        echo "debug cmd: [flashrom -p linux_spi:dev=/dev/spidev${spi_no}.0 -r $file -c $type]"
    fi
}

function write_flash_to_file(){
    spi_no=$1
    in_file=$2
    out_file="/tmp/${3}_spi${1}_tmp"
    modprobe -r spidev
    modprobe spidev
    resize_file $in_file $out_file $spi_no
    type=$(get_flash_first_type $spi_no)
    flashrom -p linux_spi:dev=/dev/spidev${spi_no}.0 -w $out_file -c $type
    if [ $? -ne 0 ];then
        echo "debug cmd: [flashrom -p linux_spi:dev=/dev/spidev${spi_no}.0 -w $out_file -c $type]"
    fi
}

function erase_flash(){
    spi_no=$1
    modprobe -r spidev
    modprobe spidev
    type=$(get_flash_first_type $spi_no)
    flashrom -p linux_spi:dev=/dev/spidev${spi_no}.0 -E -c $type
    if [ $? -ne 0 ];then
        echo "debug cmd: [flashrom -p linux_spi:dev=/dev/spidev${spi_no}.0 -E -c $type]"
    fi
}

function read_spi1_dev(){
    spi_no=1
    dev=$1
    file=$2
    case ${dev} in
        "MAIN_BIOS" | "BACKUP_BIOS")
            read_flash_to_file $spi_no $file $dev
        ;;
    esac
}

function write_spi1_dev(){
    spi_no=1
    dev=$1
    file=$2
    case ${dev} in
        "MAIN_BIOS" | "BACKUP_BIOS")
            write_flash_to_file $spi_no $file $dev
        ;;
    esac
}

function erase_spi1_dev(){
    spi_no=1
    dev=$1
    file=$2
    case ${dev} in
        "MAIN_BIOS" | "BACKUP_BIOS")
            erase_flash $spi_no
        ;;
    esac
}


function config_spi1_pin_and_path(){
    dev=$1
    # /usr/local/bin/power.sh off
    # sleep 12
    # ocm_pwr=`/usr/local/bin/power.sh status`
    # echo $ocm_pwr
    # if [ "$ocm_pwr" != "Microserver power is off" ]; then
        # echo "power off cpu fail."
        # exit -1
    # fi
    cnt=0
    date_time=`date`
    echo "Before set ME recovery $date_time"
    ##config ME to recovery mode 
    ##ipmb-util 13 0x2c 0xb8 0xdf 0x57 0x1 0x00 0x1
    #echo 0 > /sys/bus/i2c/drivers/basecpld/0-000d/me_mode
    set_sysfs_value $BASECPLD_SYSFS_DIR/me_mode 0 
    cat $BASECPLD_SYSFS_DIR/me_mode
    while true
    do
        sleep 0.5
        ##check ME recovery mode
        me_status_str=`ipmb-util 13 0x2c 0x18 0x04`
        me_status=${me_status_str:0:5}
        echo $me_status
        if [ "$me_status" == "81 00" ]; then
            echo "Set me recovery mode success."
            break
        else
            ((cnt++))
        fi
        if [ $cnt -eq 30 ]; then
            echo "Set me recovery mode fail."
            return -1
        fi
    done
    date_time=`date`
    echo "After set ME recovery $date_time"
    case ${dev} in
        "MAIN_BIOS")
            set_spi1_to_spi ##SPI mode selection 01: Enable SPI Master
            /usr/local/bin/switch_cpld.sh write 1 0x28 0x59
            set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_sel 1 ### select update bios
            set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_update_ctl 13 ### 0xd select bmc update main bios
            /usr/local/bin/switch_cpld.sh write 1 0x28 0x4e
        ;;
        "BACKUP_BIOS")
            set_spi1_to_spi ##SPI mode selection 01: Enable SPI Master
            /usr/local/bin/switch_cpld.sh write 1 0x28 0x59
            set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_sel 1 ### select update bios
            set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_update_ctl 14 ### 0xe select bmc update backup bios
            /usr/local/bin/switch_cpld.sh write 1 0x28 0x4e
        ;;      
        *)
            echo "Please enter {MAIN_BIOS, BACKUP_BIOS}"
            exit -1
        ;;
    esac
    echo "Config SPI1 Done."
}



function operate_spi1_dev(){
    op=$1
    dev=$2
    file=$3
    ## Operate devices ##
    case ${op} in
        "read")
                read_spi1_dev $dev $file
        ;;
        "write")
                write_spi1_dev $dev $file
        ;;
        "erase")
                erase_spi1_dev $dev
        ;;
        *)
            echo "Operation $op is not defined."
        ;;
    esac
}

function cleanup_spi(){
    echo "Caught Signal: reset spi selecth"
    /usr/local/bin/switch_cpld.sh write 1 0x28 0x59
    set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_update_ctl 7
    set_sysfs_value $BASECPLD_SYSFS_DIR/bios_flash_sel 0
    /usr/local/bin/switch_cpld.sh write 1 0x28 0x4e
    cnt=0
    date_time=`date`
    echo "Before set ME default $date_time"
    ##config ME recovery mode to default
    #ipmb-util 13 0x2c 0x18 0x02
    set_sysfs_value $BASECPLD_SYSFS_DIR/me_mode 1 
    cat $BASECPLD_SYSFS_DIR/me_mode
    while true
    do
        sleep 0.5
        ##check ME default mode 
        me_status_str=`ipmb-util 13 0x2c 0x18 0x04`
        me_status=${me_status_str:0:5}
        echo $me_status
        if [ "$me_status" == "80 03" ]; then
            echo "Exit me recovery mode success."
            break
        else
            ((cnt++))
        fi
        if [ $cnt -eq 30 ]; then
            echo "Exit me recovery mode fail."
            #return -1
        fi
    done
    date_time=`date`
    echo "After set ME default $date_time"
    # /usr/local/bin/power.sh on
    # sleep 5
    # ocm_pwr=`/usr/local/bin/power.sh status`
    # echo $ocm_pwr
    # if [ "$ocm_pwr" != "Microserver power is on" ]; then
        # echo "power on cpu fail."
    # fi
    rm -rf /tmp/*_spi*_tmp
    #rm -rf /tmp/layout
}
function make_layout(){
    op=$1
    if [ $op = "erase" ]; then
        echo "00400000:00FFFFFF PRI" > /tmp/layout
    else
        file=$2
        size=`ls $file -l | awk '{print $5}'`
        size_16=`printf "%08x" $size`
        echo "00400000:$size_16 PRI" > /tmp/layout
    fi
}
function ui(){
    . /usr/local/bin/openbmc-utils.sh
    op=$1
    spi=$2

    # SPI 1.0 speed
    devmem 0x1e630010 32 0x407
    # SPI 2.0 speed
    devmem 0x1e631010 32 0x407
    # SPI 2.1 speed
    devmem 0x1e631014 32 0x2007
    ## Open the path to device ##
    case ${spi} in
        "spi1")
            dev=$3
            file=$4
            config_spi1_pin_and_path $dev
            operate_spi1_dev $op $dev $file
            cleanup_spi
        ;;
        *)      
            echo "No such SPI bus."
            return -1
        ;;
    esac
}

function usage(){
    program=`basename "$0"`
    echo "Usage:"
    echo "$program <op> spi1 <spi1 device> <file>"  
    echo "  <op>          : read, write, erase"
    echo "  <spi1 device> :  MAIN_BIOS, BACKUP_BIOS"
    echo ""
    echo "MAIN_BIOS, BACKUP_BIOS will program whole flash "
    echo ""
    echo "Examples:"
    echo "  $program write spi1 MAIN_BIOS iob.bit"
    echo "  $program write spi1 BACKUP_BIOS iob.bit"
    echo ""
}

function check_parameter(){
    program=`basename "$0"`
    op=$1
    spi=$2
    case ${op} in
        "read" | "write" | "erase")
            ;;
        *)
            return -1
            ;;
    esac
    if [ ${spi} -a ${spi} = "spi1" ] || [ ${spi} = "spix" ]; then
        dev=$3
        file=$4
        ## Check device
        case ${dev} in
            "MAIN_BIOS" | "BACKUP_BIOS")
                ## Check operation
                case ${op} in
                    "read" | "write")
                        if [ $# -ne 4 ]; then
                            return -1
                        fi
                        ;;
                    "erase")
                        if [ $# -ne 3 ]; then
                            return -1
                        fi
                        ;;
                esac
                ;;
            *)
                return -1
                ;;
        esac
    else
        return -1
    fi

    return 0
}

check_parameter $@
is_par_ok=$?

if [ $is_par_ok -eq 0 ]; then
    ui $@
else
    usage
    exit -1
fi
