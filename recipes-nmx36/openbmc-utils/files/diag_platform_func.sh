#!/bin/bash

. /usr/local/bin/openbmc-utils.sh

has_error=0

usage() {
    echo "Usage: $0"
    echo
}

check_platform_functions() {
	local cpld_name=$1
    local i2c_bus=$2
    local i2c_addr=$3
	local type_name=$4
    local reg_addr=$5
    local bit_pos=$6
    local signal_name=$7
    local expected_val=$8

    local reg_value
    reg_value=$(i2cget -f -y "$i2c_bus" "$i2c_addr" "$reg_addr" 2>/dev/null)
    local read_exit_code=$?

    if [ $read_exit_code -ne 0 ] || [ -z "$reg_value" ]; then
        return 3
    fi

    if ! [[ "$reg_value" =~ ^0x[0-9a-fA-F]+$ ]]; then
        return 4
    fi

    local reg_dec=$((reg_value))
    local actual_val=$(( (reg_dec >> bit_pos) & 1 ))

    if [ $actual_val -eq $expected_val ]; then
        printf "%-6s %s reg(%s): 0x%-2x, Bit[%d]: %s, %-30s : normal\n" ${type_name} ${cpld_name} ${reg_addr} ${reg_value} ${bit_pos} ${actual_val} ${signal_name} 
        return 0
    else
        printf "%-6s %s reg(%s): 0x%-2x, Bit[%d]: %s, %-30s : abnormal\n" ${type_name} ${cpld_name} ${reg_addr} ${reg_value} ${bit_pos} ${actual_val} ${signal_name} 
        has_error=-1
        return 1
    fi
}

if [ $# -ne 0 ];then
    usage
    exit -1
fi

for check_config in "${PLATFORM_CHECKS_CONFIG[@]}"; do
    check_platform_functions $check_config
done

if [ $has_error -eq 0 ];then
    echo "Check platform functions: PASS"
else
    echo "Check platform functions: FAIL"
fi
exit $has_error
