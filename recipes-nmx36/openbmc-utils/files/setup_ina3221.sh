#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

echo "$SETUP_INA3221_SHUNT_CONFIG_LIST" | while read bus addr node val; do
    [ -z "$bus" ] && continue

    addr_hex=${addr#0x}
    base="/sys/bus/i2c/devices/${bus}-00${addr_hex}/hwmon/hwmon*"
    node_path=$(ls -d ${base}/${node} 2>/dev/null | head -n 1)

    if [ -z "$node_path" ]; then
        echo "Not find $node"
        continue
    fi

    echo "$val" > "$node_path"
    read_val=$(cat "$node_path")

    if [ "$read_val" = "$val" ]; then
        continue
    else
        echo "Set up ina3221 shunt failed: bus=$bus, addr=$addr, node=$node | write=$val, read=$read_val" > /dev/ttyS0
    fi
done