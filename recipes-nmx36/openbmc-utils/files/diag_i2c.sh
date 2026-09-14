#!/bin/bash


PROGRAM_TITLE=`basename $0`
has_error=0
WRITE_VALUE1=0x00
WRITE_VALUE2=0x01
# 08000000=0x0025
VENDOR_ID_IF=0x4602
VENDOR_ID_IF_1A2GxB=0x0002
SYSFS_I2C_DEVICES="/sys/bus/i2c/devices"
I2C_Freq_SCL=98
I2CS_FILE="/tmp/i2c_file"
BASECPLD_PATH="/sys/bus/i2c/devices/0-000d"
PMBUS_TIMEOUT_TIME=0x3d30

. /usr/local/bin/openbmc-utils.sh

# Delete temporary file when exit script
trap cleanup INT TERM QUIT EXIT
cleanup(){
    has_error=0
    rm -rf $I2CS_FILE
}

usage() {
    echo
    echo "Usage: $PROGRAM_TITLE [check|stress|speed] <i2c:0-8,11> <count>"
    echo
    echo "Paramter:"
    echo "    i2c      --Means i2c0-i2c8,i2c11,ONLY for set parameter"
    echo "    count    --Set stress test counts"
    echo
    echo "Example:"
    echo "    diag_i2c.sh check          --Check all i2c device"
    echo "    diag_i2c.sh check 2        --Check i2c2 device"
    echo "    diag_i2c.sh stress         --Do all i2c device stress test, default 50 counts"
    echo "    diag_i2c.sh stress 100     --Do all i2c device stress test 100 counts"
    echo "    diag_i2c.sh stress 4 10    --Do i2c4 device stress test 10 counts"
    echo "    diag_i2c.sh speed          --Check i2c bus frequency"
    echo
}

# i2c_read_write [i2c] [name] [bus] [address] [register] [write value] <read value>
i2c_read_write(){
    local i2c=$1
    local name=$2
    local bus=$3
    local addr=$4
    local reg=$5
    local write_val=$6
    local read_val=$7

    defval=`i2cget -f -y $bus $addr $reg`
    if [ $? -ne 0 ]; then
        echo "$i2c ${name}(${bus}, ${addr}, ${reg}) read(${retval}) error."
        return -1
    fi
    i2cset -f -y $bus $addr $reg $write_val
    if [ $? -ne 0 ]; then
        echo "$i2c ${name}(${bus}, ${addr}, ${reg}) write(${write_val}) error."
        return -1
    fi

    # retval=`i2cget -f -y $bus $addr $reg`
    # if [ "$read_val" == "" ]; then
    #     if [ "$retval" != "$write_val" ]; then
    #         echo "$i2c ${name}(${bus}, ${addr}, ${reg}) check error. Value: ${retval}, Expect: ${write_val}"
    #         return -1
    #     fi
    # else
    #     if [ "$retval" != "$read_val" ]; then
    #         echo "$i2c ${name}(${bus}, ${addr}, ${reg}) check error. Value: ${retval}, Expect: ${read_val}"
    #         return -1
    #     fi
    # fi
    i2cset -f -y $bus $addr $reg $defval
    if [ $? -ne 0 ]; then
        echo "$i2c ${name}(${bus}, ${addr}, ${reg}) write defval(${defval}) error."
        return -1
    fi
    printf "%-6s %-24s bus%-4s %-4s - OK\n" $i2c $name $bus $addr >> $I2CS_FILE
}

get_eeprom_ctrl() {
    echo 1 > ${BASECPLD_PATH}/88e6361_update_en
    echo 0 > ${BASECPLD_PATH}/88e6361_eeprom_wp
    echo 1 > ${BASECPLD_PATH}/rtl8111_update_en
    echo 0 > ${BASECPLD_PATH}/rtl8111_eeprom_wp
    echo 24c64 0x50 > /sys/bus/i2c/devices/i2c-20/new_device
    echo 24c64 0x51 > /sys/bus/i2c/devices/i2c-21/new_device
}

cleanup_eeprom_ctrl() {
    echo 0 > ${BASECPLD_PATH}/88e6361_update_en
    echo 1 > ${BASECPLD_PATH}/88e6361_eeprom_wp
    echo 0 > ${BASECPLD_PATH}/rtl8111_update_en
    echo 1 > ${BASECPLD_PATH}/rtl8111_eeprom_wp
    echo 0x50 > /sys/bus/i2c/devices/i2c-20/delete_device
    echo 0x51 > /sys/bus/i2c/devices/i2c-21/delete_device
}


i2c_test_by_test_reg() {
    local bus_name=$1
    local check_count=$2
    local name=$3
    local bus=$4
    local addr=$5
    local reg=$6
    local num_type=$(($check_count%2))
    if [ $num_type -eq 0 ]; then
        WRITE_VALUE=$WRITE_VALUE1
    else
        WRITE_VALUE=$WRITE_VALUE2
    fi
    cnt=0
    while true
    do
        ((cnt++))
        if [ $cnt -eq 4 ]; then
            echo "${bus_name} ${name[i]}(${bus[i]}, ${addr[i]}) read/write error."
            return -1
        fi
        retval=`i2c_read_write $bus_name $name $bus $addr $reg $WRITE_VALUE`
        if [ $? -ne 0 ]; then
               echo "${bus_name} $name($bus, $addr) read/write error(count=${cnt})."
               sleep 0.1
            continue
        else
            return 0
        fi
    done
}



i2c_test_by_hwmon() {
    local bus_name=$1
    local name=$2
    local bus=$3
    local addr=$4
    local node=$5

    if [ -f ${SYSFS_I2C_DEVICES}/i2c-${bus}/${bus}-00${addr}/hwmon/hwmon*/${node} ]; then
        node_path=${SYSFS_I2C_DEVICES}/i2c-${bus}/${bus}-00${addr}/hwmon/hwmon*/${node}
    elif [ -f ${SYSFS_I2C_DEVICES}/i2c-${bus}/${bus}-00${addr}/${node} ]; then
        node_path=${SYSFS_I2C_DEVICES}/i2c-${bus}/${bus}-00${addr}/${node}
    else
        node_path=${SYSFS_I2C_DEVICES}/i2c-${bus}/${bus}-00${addr}/hwmon/hwmon*/${node}
    fi

    cnt=0
    while true
    do
        ((cnt++))
        if [ $cnt -eq 4 ]; then
            echo "${bus_name} ${name}(${bus}, 0x${addr}) device node error."
            return -1
        fi
        retval=`cat ${node_path}`
        if [ $? -eq 0 ]; then
            printf "%-6s %-24s bus%-4s 0x%-2s - OK\n" ${bus_name} ${name} ${bus} ${addr} >> $I2CS_FILE
            return 0
        else
            echo "${bus_name} ${name}(${bus}, 0x${addr}) device node error(count=${cnt})."
            sleep 0.1
            continue
        fi
    done
}

i2c_test_eeprom() {
    local bus_name=$1
    local name=$2
    local bus=$3
    local addr=$4
    cnt=0
    while true
    do
        ((cnt++))
        if [ $cnt -eq 4 ]; then
            echo "$bus_name ${name}(${bus}, 0x${addr}) hexdump error."
            return -1
        fi
        retval=`hexdump -C -n 256 ${SYSFS_I2C_DEVICES}/${bus}-00${addr}/eeprom | grep "00000000"`
        if [[ $? -eq 0 && "$retval" != "" ]]; then
            printf "%-6s %-24s bus%-4s 0x%-2s - OK\n" $bus_name ${name} ${bus} ${addr} >> $I2CS_FILE
            return 0
        else
            echo "$bus_name ${name}(${bus}, 0x${addr}) hexdump error(count=${cnt})."
            sleep 0.1
            continue
        fi
    done
}


i2c_device_test_func() {
    local bus_name=$1
    local check_count=$2
    local test_type=$3
    local name=$4
    local bus=$5
    local addr=$6

    case "$test_type" in
        TEST_REG)
            local reg=$7
            i2c_test_by_test_reg $bus_name $check_count $name $bus $addr $reg
            ret=$?
            ;;
        HWMON)
            local node=$7
            i2c_test_by_hwmon $bus_name $name $bus $addr $node
            ret=$?
            ;;
        EEPROM)
            i2c_test_eeprom $bus_name $name $bus $addr
            ret=$?
            ;;
    esac
    return $ret
}

check_i2c0(){
    check_count=$1
    local has_error=0
    for i2c_dev_cfg in "${i2c0_device_configs[@]}"; do
        i2c_device_test_func i2c-0 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

check_i2c1(){
    check_count=$1
    local has_error=0
    get_eeprom_ctrl
    for i2c_dev_cfg in "${i2c1_device_configs[@]}"; do
        i2c_device_test_func i2c-1 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    cleanup_eeprom_ctrl
    return $has_error
}

check_i2c2(){
    check_count=$1
    local has_error=0
    for i2c_dev_cfg in "${i2c2_device_configs[@]}"; do
        i2c_device_test_func i2c-2 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

check_i2c3() {
    check_count=$1
    local has_error=0
    for i2c_dev_cfg in "${i2c3_device_configs[@]}"; do
        i2c_device_test_func i2c-3 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

check_i2c4() {
    check_count=$1
    local has_error=0
    for i2c_dev_cfg in "${i2c4_device_configs[@]}"; do
        i2c_device_test_func i2c-4 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

check_i2c5() {
    set_fpga_write_enable enable
    check_count=$1
    local has_error=0
    for i2c_dev_cfg in "${i2c5_device_configs[@]}"; do
        i2c_device_test_func i2c-5 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    set_fpga_write_enable disable
    return $has_error
}

check_i2c6() {
    check_count=$1
    local has_error=0
    for i2c_dev_cfg in "${i2c6_device_configs[@]}"; do
        i2c_device_test_func i2c-6 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

check_i2c7() {
    check_count=$1
    local has_error=0
    for i2c_dev_cfg in "${i2c7_device_configs[@]}"; do
        i2c_device_test_func i2c-7 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

check_i2c8() {
    check_count=$1
    local has_error=0
    for i2c_dev_cfg in "${i2c8_device_configs[@]}"; do
        i2c_device_test_func i2c-8 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

check_i2c11(){
    # local has_error=0
    # cnt=0
    # while true
    # do
    #     ((cnt++))
    #     if [ $cnt -eq 4 ]; then
    #         echo "i2c-13 SI52208(13, 0x69) device node error."
    #         has_error=-1
    #         break
    #     fi

    #     ##SI52208 0x69  ${ret_byte:5:6}
    #     # exec i2ctransfer read data
    #     raw_output=$(i2ctransfer -f -y 11 w1@0x69 0x05 r6 2>/dev/null)
    #     ret_status=$?
    #     read_byte=$(echo "$raw_output" | awk '{print $5}')
    #     #echo $read_byte
    #     # check command exec OR str null OR str is not 0x**
    #     if [ $ret_status -ne 0 ] || [ -z "$read_byte" ] || ! [[ "$read_byte" =~ ^0[xX][0-9A-Fa-f]{1,2}$ ]]; then
    #         echo "i2c-13 SI52208(13, 0x69) read error(count=${cnt})."
    #         sleep 0.1
    #         continue
    #     else
    #         printf "%-6s %-24s bus%-4s 0x%-2s - OK\n" i2c-13 SI52208 13 69 >> $I2CS_FILE
    #         break
    #     fi
    # done

    # cnt=0
    # while true
    # do
    #     ((cnt++))
    #     if [ $cnt -eq 4 ]; then
    #         echo "i2c-13 SI5361B(104, 0x58) device node error."
    #         has_error=-1
    #         break
    #     fi

    #     ##SI5361B 0x58
    #     # exec i2ctransfer read data : 0x80 0x62 0x53 0x41 0x41 0xdf 0x41 0x00 0x00 0x00 0x00 0x01 0x0a 0x02
    #     raw_output=$(i2ctransfer -f -y 104 w3@0x58 0xF0 0x0F 0x08 r14 2>/dev/null)
    #     ret_status=$?
    #     read_byte=$(echo "$raw_output" | awk '{print $2}')
    #     #echo $read_byte
    #     # check command exec OR str null OR str is not 0x**
    #     if [ $ret_status -ne 0 ] || ! [ "x$read_byte" == "x0x62" ]; then
    #         echo "i2c-13 SI5361B(104, 0x58) read error(count=${cnt})."
    #         sleep 0.1
    #         continue
    #     else
    #         printf "%-6s %-24s bus%-4s 0x%-2s - OK\n" i2c-13 SI5361B 104 58 >> $I2CS_FILE
    #         break
    #     fi
    # done
    # return $has_error

    check_count=$1
    local has_error=0
    for i2c_dev_cfg in "${i2c11_device_configs[@]}"; do
        i2c_device_test_func i2c-11 $check_count $i2c_dev_cfg
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

check_all_i2c(){
    local total_count=$1
    local has_error=0
    check_i2c0 $total_count
    if [ $? -ne 0 ]; then
        has_error=-1
    fi

    check_i2c1 $total_count
    if [ $? -ne 0 ]; then
        has_error=-1
    fi

    check_i2c2 $total_count
    if [ $? -ne 0 ]; then
        has_error=-1
    fi

    check_i2c3 $total_count
    if [ $? -ne 0 ]; then
        has_error=-1
    fi

    check_i2c4 $total_count
    if [ $? -ne 0 ]; then
        has_error=-1
    fi

    check_i2c5 $total_count
    if [ $? -ne 0 ]; then
        has_error=-1
    fi

    check_i2c6 $total_count
    if [ $? -ne 0 ]; then
        has_error=-1
    fi

    check_i2c7 $total_count
    if [ $? -ne 0 ]; then
        has_error=-1
    fi

    check_i2c8 $total_count
    if [ $? -ne 0 ]; then
        has_error=-1
    fi

    check_i2c11
    if [ $? -ne 0 ]; then
        has_error=-1
    fi
    return $has_error
}

i2c_stress(){
    local i2c_num=$1
    local total_count=$2
    if [ "$i2c_num" == "" ] && [ "$total_count" == "" ]; then
        total_count=50
    elif [ "$i2c_num" != "" ] && [ "$total_count" == "" ]; then
        total_count=$1
        i2c_num=$2
    elif [ -n "`echo $total_count | sed 's/[0-9]//g'`" ] || [ "$total_count" == "" ]; then
        usage
        exit -1
    fi

    local loop_count=0
    while [[ $loop_count -lt $total_count ]]
    do
        case "$i2c_num" in
            0)
                check_i2c0 $loop_count
                if [ $? -ne 0 ]; then
                    echo "i2c stress test loop $loop_count failed."
                    exit -1
                fi
                ;;
            1)
                check_i2c1 $loop_count
                if [ $? -ne 0 ]; then
                    echo "i2c stress test loop $loop_count failed."
                    exit -1
                fi
                ;;
            2)
                check_i2c2 $loop_count
                if [ $? -ne 0 ]; then
                    echo "i2c stress test loop $loop_count failed."
                    exit -1
                fi
                ;;
            3)
                check_i2c3 $loop_count
                if [ $? -ne 0 ]; then
                    echo "i2c stress test loop $loop_count failed."
                    exit -1
                fi
                ;;
            4)
                check_i2c4 $loop_count
                if [ $? -ne 0 ]; then
                    exit -1
                fi
                ;;
            5)
                check_i2c5 $loop_count
                if [ $? -ne 0 ]; then
                    echo "i2c stress test loop $loop_count failed."
                    exit -1
                fi
                ;;
            6)
                check_i2c6 $loop_count
                if [ $? -ne 0 ]; then
                    exit -1
                fi
                ;;
            7)
                check_i2c7 $loop_count
                if [ $? -ne 0 ]; then
                    echo "i2c stress test loop $loop_count failed."
                    exit -1
                fi
                ;;
            8)
                check_i2c8 $loop_count
                if [ $? -ne 0 ]; then
                    echo "i2c stress test loop $loop_count failed."
                    exit -1
                fi
                ;;
            11)
                check_i2c11
                if [ $? -ne 0 ]; then
                    echo "i2c stress test loop $loop_count failed."
                    exit -1
                fi
                ;;
            '')
                check_all_i2c $loop_count
                if [ $? -ne 0 ]; then
                    echo "i2c stress test loop $loop_count failed."
                    exit -1
                fi
                ;;
            *)
                usage
                exit -1
                ;;
        esac

        loop_count=$((1+$loop_count))
        if [ $(($loop_count%10)) -eq 0 ]; then
            echo "i2c$i2c_num stress test: loop $loop_count."
        fi
    done

    echo "I2C stress test: PASS"
}

# Check bus frequency
# APB frequency: 24.75 MHz
# 1MHz = 1000kHz

i2c_speed(){
    APB_clock=100000

    # val=`busybox devmem 0x14c0f104 32`
    # val=$((${val} & 0xfffff))
    # Basecyc=$((2**($val & 0xf)))
    # CK_low=$(((($val & 0xf000)>>12)+1))
    # CK_high=$(((($val & 0xf0000)>>16)+1))

    # Freq_SCL=$(($APB_clock/$(($Basecyc * ($CK_low+$CK_high)))))
    # echo "I2C: Freq_SCL $Freq_SCL kHz"
    # if [[ $Freq_SCL -ne $I2C_Freq_SCL ]]; then
    #     echo "Check I2C bus frequency: FAIL"
    #     exit -1
    # fi
    # echo "Check I2C bus frequency: PASS"

    val=`busybox devmem 0x14c0f104 32`
    # 提取 TBASECLK (低 8 位)
    baseclk_idx=$((val & 0xFF))

    # 提取 SCL_LOW (位 15:12) 和 SCL_HIGH (位 19:16)
    scl_low=$(((val >> 12) & 0xF))
    scl_high=$(((val >> 16) & 0xF))

    # 计算基时钟频率
    base_clk=$((APB_clock / (baseclk_idx + 1)))

    # SCL 周期数 = (scl_low+1) + (scl_high+1) = scl_low + scl_high + 2
    Freq_SCL=$((base_clk / (scl_low + scl_high + 2)))

    echo "I2C: Freq_SCL $Freq_SCL kHz"
    if [[ $Freq_SCL -ne $I2C_Freq_SCL ]]; then
        echo "Check I2C bus frequency: FAIL"
        exit -1
    fi
    echo "Check I2C bus frequency: PASS"
}


if [[ $# -ne 1 && $# -ne 2 && $# -ne 3 && $# -ne 4 ]]; then
    usage
    exit -1
fi

mode=$1
object=$2
count=$3
time=$4

if [[ "$time" != "" ]]; then
    PMBUS_TIMEOUT_TIME=$time
    echo "PMBUS_TIMEOUT_TIME=${PMBUS_TIMEOUT_TIME}"
fi

case "$mode" in
    check)
        case "$object" in
            0)
                check_i2c0 1
                cat $I2CS_FILE
                ;;
            1)
                check_i2c1 1
                cat $I2CS_FILE
                ;;
            2)
                check_i2c2 1
                cat $I2CS_FILE
                ;;
            3)
                check_i2c3 1
                cat $I2CS_FILE
                ;;
            4)
                check_i2c4 1
                cat $I2CS_FILE
                ;;
            5)
                check_i2c5 1
                cat $I2CS_FILE
                ;;
            6)
                check_i2c6 1
                cat $I2CS_FILE
                ;;
            7)
                check_i2c7 1
                cat $I2CS_FILE
                ;;
            8)
                check_i2c8 1
                cat $I2CS_FILE
                ;;
            11)
                check_i2c11
                cat $I2CS_FILE
                ;;
            '')
                check_all_i2c 1
                has_error=$?
                cat $I2CS_FILE
                if [ $has_error -eq 0 ]; then
                    echo "Check I2C bus: PASS"
                else
                    echo "Check I2C bus: FAIL"
                fi
                ;;
            *)
                usage
                exit -1
                ;;
        esac
        ;;
    stress)
        i2c_stress $object $count
        ;;
    speed)
        i2c_speed
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
