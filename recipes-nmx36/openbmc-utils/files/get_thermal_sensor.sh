#!/bin/sh
#
# Copyright 2018-present Facebook. All Rights Reserved.
#
# This program file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program in a file named COPYING; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA
#
# Parse the command line and set variables to control logic

printUsage() {
    echo "Usage: $PROGRAM_TITLE [options]"
    echo ""
    echo "Options are:"
    echo "  -h: display the help and exit."
    echo "  --help"
    echo "  -c: show CPU thermal information."
    echo "  --cpu"
    echo "  -m: show MAC max thermal information."
    echo "  --mac"
    echo "  --mac_sdk: show MAC SDK thermal information."
    echo "  --mac_sensor: show MAC sensor thermal information."
    echo "  -i: show inlet thermal information."
    echo "  --inlet"
    echo "  -a: show all thermal sensors information."
    echo "  --all"
    echo ""
}

get_cpu_temp(){
    has_error=0
    Tjmax_str=`peci-util 0x30 0x05 0x05 0xa1 0x00 0x10 0x00 0x00`
    Tjmax_val=0x`echo ${Tjmax_str:0-6:2}`
    ((Tjmax=Tjmax_val))

    CPU_str=`peci-util 0x30 0x1 0x2 0x1`
    CPU_val1=`echo ${CPU_str:0-3:2}`
    CPU_val2=`echo ${CPU_str:0-6:2}`
    CPU_val=0x${CPU_val1}${CPU_val2}
    sign_bit1=`echo ${CPU_str:0-3:1}`
    sign_bit=0x${sign_bit1}

    if [ "$(($sign_bit & 0x8))" == 8 ];then
        m=$((~$(($CPU_val-1)) & 0xffff))
        n=`awk -v x=$m -v y=64 'BEGIN {printf "%.2f\n",x/y}'`
        temp=`awk -v x=$Tjmax -v y=$n 'BEGIN {printf "%d\n",x-y}'`
    else
        ((m=$CPU_val))
        n=`awk -v x=$m -v y=64 'BEGIN {printf "%.2f\n",x/y}'`
        temp=`awk -v x=$Tjmax -v y=$n 'BEGIN {printf "%d\n",x+y}'`
    fi

    ret=`awk -v x=$temp -v y=0 'BEGIN{print(x>y)?"0":"1"}'`
    if [ $ret -ne 0 ]; then
        has_error=-1
    fi
    echo "The CPU temperature: $temp"
    return $has_error
}



temperatures=()
read_device_temperatures() {
    local bus=$1
    local addr=$2
    local device_path="/sys/bus/i2c/devices/${bus}-00${addr}"
    if [ ! -d "$device_path" ]; then
        return
    fi  
    for temp_input in "${MAC_TEMP_SENSOR_INPUTS[@]}"; do
        temp_file="${device_path}/hwmon/hwmon*/${temp_input}" 
        temp_value=`cat ${temp_file}`
        temp_value=`echo "${temp_value} 1000"|awk '{printf("%d\n", $1/$2)}'`
        temperatures+=("$temp_value")
    done
}
# I2C总线编号
I2C_BUS=7
# 芯片reg
CHIP_ADDR=0xf
# 基础reg
BASE_ADDR=0x80000
# 要读取的寄存器数量
REG_COUNT=23

convert_to_temperature() {
    local byte1=$1
    local byte2=$2
    
    # 将两个字节组合成16位整数（大端序：第一个字节为高位，第二个字节为低位）
    local combined=$(( (byte1 << 8) | byte2 ))
    
    local temperature=$(awk "BEGIN {printf \"%.d\", $combined / 10}")
    
    echo "$temperature"
}

# 循环读取寄存器
get_mac_temp_from_core() {
    for ((i=0; i<REG_COUNT; i++))
    do
        # 计算当前寄存器reg
        current_addr=$((BASE_ADDR + i*4))
        
        # 将reg分解为四个字节（大端序）
        byte0=$(( (current_addr >> 24) & 0xFF ))
        byte1=$(( (current_addr >> 16) & 0xFF ))
        byte2=$(( (current_addr >> 8) & 0xFF ))
        byte3=$(( current_addr & 0xFF ))
        
        # 执行i2ctransfer命令
        result=$(i2ctransfer -y $I2C_BUS w4@$CHIP_ADDR $byte0 $byte1 $byte2 $byte3 r4 2>/dev/null)
        
        # 检查命令是否成功执行
        if [ $? -eq 0 ] && [ -n "$result" ]; then
            # 提取4个字节的数据
            # 假设结果格式为：0xXX 0xXX 0xXX 0xXX
            bytes=($result)
            
            if [ ${#bytes[@]} -eq 4 ]; then
                # 去除"0x"前缀，获取十六进制值
                hex1=${bytes[0]#0x}
                hex2=${bytes[1]#0x}
                hex3=${bytes[2]#0x}
                hex4=${bytes[3]#0x}
                
                # 将十六进制转换为十进制
                byte1=$((16#$hex1))
                byte2=$((16#$hex2))
                byte3=$((16#$hex3))
                byte4=$((16#$hex4))
                
                # 转换前两个字节为温度值
                temp1=$(convert_to_temperature $byte1 $byte2)
                
                # 转换后两个字节为温度值
                temp2=$(convert_to_temperature $byte3 $byte4)
                temperatures+=("$temp1")
                temperatures+=("$temp2")
            else
                echo "reg $(printf "0x%x" $current_addr): invalid data - $result"
            fi
        else
            echo "reg $(printf "0x%x" $current_addr): FAIL!"
        fi
    done

}

read_once() {
    # Read 08 register (32-bit low)
    low=$(i2ctransfer -y 7 w4@0xf 0x00 0x08 0x01 0x08 r4 2>/dev/null)
    # Read 0c register (32-bit high)
    high=$(i2ctransfer -y 7 w4@0xf 0x00 0x08 0x01 0x0c r4 2>/dev/null)

    # Parse to 32-bit hex (remove 0x, combine 4 bytes)
    low_hex=$(echo "$low" | awk '{gsub(/0x/,"");printf "%s%s%s%s",$1,$2,$3,$4}')
    high_hex=$(echo "$high" | awk '{gsub(/0x/,"");printf "%s%s%s%s",$1,$2,$3,$4}')

    # Convert to decimal and combine 64-bit value (high<<32 + low)
    low_dec=$((0x${low_hex}))
    high_dec=$((0x${high_hex}))
    echo $(( (high_dec << 32) + low_dec ))
}
get_mac_heartbeat() {
# Perform two readings
    val1=$(read_once)
    sleep 1
    val2=$(read_once)
# Compare and output results

    if [ $val1 -gt $val2 ]; then
        echo "val1=$val1, val2=$val2" >&2
        echo 1
    elif [ $val1 -lt $val2 ]; then
        echo 0
    else
        echo "val1=$val1, val2=$val2" >&2
        echo 1
fi
}
get_mac_temp(){
    echo 1 > /sys/bus/i2c/drivers/misccpld/66-0031/mac_temp_en
    heartbeat=1
    for retry in {1..3}; do
        heartbeat=$(get_mac_heartbeat)
        if [ $heartbeat -eq 0 ]; then
            break
        fi
        sleep 1
    done
    has_error=0
    local bus
    for bus in "${MAC_TEMP_SENSOR_BUS_NUMBERS[@]}"; do
        read_device_temperatures $bus $MAC_TEMP_SENSOR_DEVICE_ADDR
    done 
    if [ $heartbeat -eq 0 ]; then
        get_mac_temp_from_core
    fi
    if [ ${#temperatures[@]} -eq 0 ]; then
        has_error=-1
    else
        max_temp=$(printf "%d\n" "${temperatures[@]}" | sort -nr | head -n1)
        echo "The MAC temperature: $max_temp"
    fi
    return $has_error
}

get_mac_sdk_temp(){
    echo 1 > /sys/bus/i2c/drivers/misccpld/66-0031/mac_temp_en
    heartbeat=1
    for retry in {1..3}; do
        heartbeat=$(get_mac_heartbeat)
        if [ $heartbeat -eq 0 ]; then
            break
        fi
        sleep 1
    done
    has_error=0
    if [ $heartbeat -eq 0 ]; then
        get_mac_temp_from_core
    fi
    if [ ${#temperatures[@]} -eq 0 ]; then
        has_error=-1
    else
        max_temp=$(printf "%d\n" "${temperatures[@]}" | sort -nr | head -n1)
        echo "The MAC temperature: $max_temp"
    fi
    return $has_error
}

get_mac_sensor_temp(){
    has_error=0
    local bus
    for bus in "${MAC_TEMP_SENSOR_BUS_NUMBERS[@]}"; do
        read_device_temperatures $bus $MAC_TEMP_SENSOR_DEVICE_ADDR
    done 
    if [ ${#temperatures[@]} -eq 0 ]; then
        has_error=-1
    else
        max_temp=$(printf "%d\n" "${temperatures[@]}" | sort -nr | head -n1)
        echo "The MAC temperature: $max_temp"
    fi
    return $has_error
}

#/sys/bus/i2c/devices/i2c-76/76-0048/hwmon/hwmon*/temp1_input
get_inlet_temp(){
    has_error=0
    temp=`cat /sys/bus/i2c/devices/i2c-76/76-0048/hwmon/hwmon*/temp1_input`
    if [[ $? -eq 0 && "$temp" != "" ]]; then
        #vol_value=`echo "$temp 1000" | awk '{printf("%0f.0\n",$1/$2)}'`
        ((vol_value=$temp/1000))
        echo "The PSU_INLET temperature: $vol_value"
    else
        has_error=-1
    fi
    return $has_error
}

parseCommandLine() {

    # Special case that nothing was provided on the command line so print usage
    if [[ $# -ne 1 && $# -ne 2 ]]; then
        printUsage
        exit 0
    fi

    # Indicate specification for single character options
    # - 1 colon after an option indicates that an argument is required
    # - 2 colons after an option indicates that an argument is optional, must use -o=argument syntax
    optstring="hcmia"

    # Indicate specification for long options
    # - 1 colon after an option indicates that an argument is required
    # - 2 colons after an option indicates that an argument is optional, must use --option=argument syntax
    optstringLong="help,cpu,mac,mac_sdk,mac_sensor,inlet,all"

    GETOPT_OUT=`getopt --options ${optstring} --long ${optstringLong} -- "$@"`
    if [ $? != 0 ]; then
        echo ""
        printUsage
        exit 1
    fi

    eval set -- "${GETOPT_OUT}"

    while true
    do
        case "$1" in
            -h|--help)
                printUsage
                exit 0
                ;;
            -c|--cpu)
                get_cpu_temp
                if [ $? -ne 0 ]; then
                    echo "to get cpu thermal fail."
                    exit -1
                fi
                shift
                ;;
            -m|--mac)
                get_mac_temp
                if [ $? -ne 0 ]; then
                    echo "to get mac thermal fail."
                    exit -1
                fi
                shift
                ;;
            --mac_sdk)
                get_mac_sdk_temp
                if [ $? -ne 0 ]; then
                    echo "to get mac_sdk thermal fail."
                    exit -1
                fi
                shift
                ;;
            --mac_sensor)
                get_mac_sensor_temp
                if [ $? -ne 0 ]; then
                    echo "to get mac_sensor thermal fail."
                    exit -1
                fi
                shift
                ;;
            -i|--inlet)
                get_inlet_temp
                if [ $? -ne 0 ]; then
                    echo "to get inlet thermal fail."
                    exit -1
                fi
                shift
                ;;
            -a|--all)
                get_cpu_temp
                get_mac_temp
                get_inlet_temp
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo ""
                echo "Invalid option $1." >&2
                printUsage
                exit 1
                ;;
            \?)
                printUsage
                exit 0
                ;;
        esac
    done
}

# Start of the script.
. /usr/local/bin/openbmc-utils.sh
parseCommandLine "$@"

exit 0
