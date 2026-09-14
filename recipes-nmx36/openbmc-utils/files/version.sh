#!/bin/bash

trap cleanup INT TERM QUIT EXIT
function cleanup(){
    rm -rf /tmp/cpld_ver
}

product_name=$(cat /etc/openbmc/product_name)


# 定义设备信息映射表（SCU004, SCU014 与 Device_ID 的对应关系）
declare -A device_map=(
    ["0x000000200"]="AST1100-A0"
    ["0x000000201"]="AST1100-A1"
    ["0x000000202"]="AST1100-A2,AST1100-A3,AST2050-A0,AST2050-A1,AST2050-A2,AST2050-A3,AST2150-A0,AST2150-A1"
    ["0x000000300"]="AST2100-A0"
    ["0x000000301"]="AST2100-A1"
    ["0x000000302"]="AST2100-A2,AST2100-A3"
    ["0x000000102"]="AST2200-A0,AST2200-A1"
    ["0x00000102"]="AST2200-A0,AST2200-A1"
    ["0x01000003"]="AST2300-A0"
    ["0x01010303"]="AST2300-A1"
    ["0x01010003"]="AST1300-A0,AST1300-A1"
    ["0x01010203"]="AST1300-A1"
    ["0x02000303"]="AST2400-A0"
    ["0x02010303"]="AST2400-A1"
    ["0x02010003"]="AST2400-A0"
    ["0x02010303"]="AST2400-A1,AST1250-A1"
    ["0x04000303"]="AST2500-A0"
    ["0x04000103"]="AST2510-A0"
    ["0x04000203"]="AST2520-A0"
    ["0x04000403"]="AST2530-A0"
    ["0x04010303"]="AST2500-A1"
    ["0x04010103"]="AST2510-A1"
    ["0x04010203"]="AST2520-A1"
    ["0x04010403"]="AST2530-A1"
    ["0x04030303"]="AST2500-A2"
    ["0x04030103"]="AST2510-A2"
    ["0x04030203"]="AST2520-A2"
    ["0x04030403"]="AST2530-A2"
    ["0x05000303,0x05000303"]="AST2600-A0"
    ["0x05010303,0x05010303"]="AST2600-A1"
    ["0x05010203,0x05010203"]="AST2620-A1"
    ["0x05030303,0x05030303"]="AST2600-A3,AST2620-A3"
    ["0x05030203,0x05030203"]="AST2620-A3"
    ["0x05010303,0x05020303"]="AST2600-A2"
    ["0x05010203,0x05020203"]="AST2620-A2"
    ["0x06010303,0x06010303"]="AST2700-A1"
    ["0x06010203,0x06010203"]="AST2720-A1"
    ["0x06010303,0x06020303"]="AST2700-A2"
    ["0x06010203,0x06020203"]="AST2720-A2"
)

# echo "Hardware Version"
# printf "%-18s%-s" "Device" ":"
# fruid-util base | grep "Product Version" | cut -d ':' -f2

# echo
# echo "Software Version"
# echo "BMC version       : V00.00.01h"

# printf "%-18s%-s " "Device_ID" ":"
# 读取寄存器值并处理
# scu000=$(devmem 0x12c02000)

# 生成匹配键并查询映射表
# match_key="${scu000}"
# device_id="${device_map[$match_key]}"

# # 未匹配时尝试仅用SCU004匹配
# if [ -z "$device_id" ]; then
#     match_key="${scu004}"
#     device_id="${device_map[$match_key]}"
# fi

# 输出结果（未匹配时显示NA）
# echo "${device_id:-NA}"

bios_ver=$(ipmitool mc getsysinfo system_fw_version | awk -F'.' '{print $(NF-1)"."$NF}')

printf "%-18s%-s  %s\n" "Device" ":" "NMX-36"
printf "%-18s%-s  %s\n" "BMC" ":" "00.04"
printf "%-18s%-s  %s\n" "BIOS" ":" "$bios_ver"
printf "%-18s%-s  %s\n" "Device ID" ":" "ast2700"

/usr/local/bin/cpld_ver.sh > /tmp/cpld_ver

# echo
# echo "PLDs Version"
# 处理OCM_CPLD（双引号包裹变量）
ctrl=$(cat /tmp/cpld_ver | grep "OCM_CPLD" | cut -d ':' -f2)
ctrl_0=$(echo "$ctrl" | cut -d '.' -f1)
ctrl_1=$(echo "$ctrl" | cut -d '.' -f2)
printf "%-18s%-s %s.%s\n" "OCM_CPLD" ":" "$ctrl_0" "$ctrl_1"

# 处理Base_CPLD
ctrl=$(cat /tmp/cpld_ver | grep "Base_CPLD" | cut -d ':' -f2)
ctrl_0=$(echo "$ctrl" | cut -d '.' -f1)
ctrl_1=$(echo "$ctrl" | cut -d '.' -f2)
printf "%-18s%-s %s.%s\n" "Base_CPLD" ":" "$ctrl_0" "$ctrl_1"

# 处理MISC_CPLD
ctrl=$(cat /tmp/cpld_ver | grep "MISC_CPLD" | cut -d ':' -f2)
ctrl_0=$(echo "$ctrl" | cut -d '.' -f1)
ctrl_1=$(echo "$ctrl" | cut -d '.' -f2)
printf "%-18s%-s %s.%s\n" "MISC_CPLD" ":" "$ctrl_0" "$ctrl_1"

# 处理Port1_CPLD
ctrl=$(cat /tmp/cpld_ver | grep "Port1_CPLD" | cut -d ':' -f2)
ctrl_0=$(echo "$ctrl" | cut -d '.' -f1)
ctrl_1=$(echo "$ctrl" | cut -d '.' -f2)
printf "%-18s%-s %s.%s\n" "Port1_CPLD" ":" "$ctrl_0" "$ctrl_1"

# 处理Port2_CPLD
ctrl=$(cat /tmp/cpld_ver | grep "Port2_CPLD" | cut -d ':' -f2)
ctrl_0=$(echo "$ctrl" | cut -d '.' -f1)
ctrl_1=$(echo "$ctrl" | cut -d '.' -f2)
printf "%-18s%-s %s.%s\n" "Port2_CPLD" ":" "$ctrl_0" "$ctrl_1"

# 处理LED_CPLD
ctrl=$(cat /tmp/cpld_ver | grep "LED_CPLD" | cut -d ':' -f2)
ctrl_0=$(echo "$ctrl" | cut -d '.' -f1)
ctrl_1=$(echo "$ctrl" | cut -d '.' -f2)
printf "%-18s%-s %s.%s\n" "LED_CPLD" ":" "$ctrl_0" "$ctrl_1"

# 处理FAN1_CPLD
fan1=$(cat /tmp/cpld_ver | grep "FAN1_CPLD" | cut -d ':' -f2)
fan1_0=$(echo "$fan1" | cut -d '.' -f1)
fan1_1=$(echo "$fan1" | cut -d '.' -f2)
printf "%-18s%-s %s.%s\n" "FAN1_CPLD" ":" "$fan1_0" "$fan1_1"

# 处理FAN2_CPLD
fan2=$(cat /tmp/cpld_ver | grep "FAN2_CPLD" | cut -d ':' -f2)
fan2_0=$(echo "$fan2" | cut -d '.' -f1)
fan2_1=$(echo "$fan2" | cut -d '.' -f2)
printf "%-18s%-s %s.%s\n" "FAN2_CPLD" ":" "$fan2_0" "$fan2_1"

echo