#!/bin/bash

# Configure 17 sensors with their bus, address, input files and names
# Format: "bus:addr:voltage_input:current_input:sensor_name"
. /usr/local/bin/openbmc-utils.sh
# Initialize debug flag
debug=0

# Parse command line arguments
while getopts "d" opt; do
    case $opt in
        d)
            debug=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Initialize total power to 0
total_mac_power=0
total_osfp_power=0

# Print header if debug mode is enabled
if [ $debug -eq 1 ]; then
    printf "%-20s %-15s %-15s %s\n" "Sensor Name" "Voltage (mV)" "Current (mA)" "Power (W)"
    printf "%-20s %-15s %-15s %s\n" "-----------" "------------" "------------" "---------"
fi

# Process each sensor in a loop
for sensor in "${MAC_POWER_SENSORS[@]}"; do
    # Parse sensor configuration
    bus=$(echo "$sensor" | cut -d':' -f1)
    addr=$(echo "$sensor" | cut -d':' -f2)
    voltage_input=$(echo "$sensor" | cut -d':' -f3)
    current_input=$(echo "$sensor" | cut -d':' -f4)
    sensor_name=$(echo "$sensor" | cut -d':' -f5)

    # Calculate device path
    device_addr_hex=$(printf "%04x" $((16#${addr:2})))
    device_path="/sys/bus/i2c/devices/${bus}-${device_addr_hex}"

    # Check if device exists
    if [ ! -d "$device_path" ]; then
        echo "Warning: $sensor_name (bus: $bus, addr: $addr) does not exist at path $device_path"
        continue
    fi

    # Read voltage value
    voltage_file="${device_path}/hwmon/hwmon*/${voltage_input}"

    voltage=`cat ${voltage_file}`

    # Read current value
    current_file="${device_path}/hwmon/hwmon*/${current_input}"

    current=`cat ${current_file}`

    # Convert units and calculate power (voltage is usually in mV, current in mA)
    # Convert to V and A: Power(W) = (voltage(mV)/1000) * (current(mA)/1000) = voltage*current/(1000000)
    power=$(echo "${voltage} ${current}" | awk '{printf "%.6f\n", ($1 * $2) / 1000000}')

    # Accumulate total power
    total_mac_power=$(echo "${total_mac_power} ${power}" | awk '{printf "%.6f\n", $1 + $2}')

    # Print sensor details with aligned format only if debug flag is set
    if [ $debug -eq 1 ]; then
        printf "%-20s %-15s %-15s %.6f\n" "$sensor_name" "$voltage" "$current" "$power"
    fi
done

for sensor in "${OSFP_POWER_SENSORS[@]}"; do
    # Parse sensor configuration
    bus=$(echo "$sensor" | cut -d':' -f1)
    addr=$(echo "$sensor" | cut -d':' -f2)
    voltage_input=$(echo "$sensor" | cut -d':' -f3)
    current_input=$(echo "$sensor" | cut -d':' -f4)
    sensor_name=$(echo "$sensor" | cut -d':' -f5)

    # Calculate device path
    device_addr_hex=$(printf "%04x" $((16#${addr:2})))
    device_path="/sys/bus/i2c/devices/${bus}-${device_addr_hex}"

    # Check if device exists
    if [ ! -d "$device_path" ]; then
        echo "Warning: $sensor_name (bus: $bus, addr: $addr) does not exist at path $device_path"
        continue
    fi

    # Read voltage value
    voltage_file="${device_path}/hwmon/hwmon*/${voltage_input}"

    voltage=`cat ${voltage_file}`

    # Read current value
    current_file="${device_path}/hwmon/hwmon*/${current_input}"

    current=`cat ${current_file}`

    # Convert units and calculate power (voltage is usually in mV, current in mA)
    # Convert to V and A: Power(W) = (voltage(mV)/1000) * (current(mA)/1000) = voltage*current/(1000000)
    power=$(echo "${voltage} ${current}" | awk '{printf "%.6f\n", (3 * $1 * $2) / 1000000}')

    # Accumulate total power
    total_osfp_power=$(echo "${total_osfp_power} ${power}" | awk '{printf "%.6f\n", $1 + $2}')

    # Print sensor details with aligned format only if debug flag is set
    if [ $debug -eq 1 ]; then
        printf "%-20s %-15s %-15s %.6f\n" "$sensor_name" "$voltage" "$current" "$power"
    fi
done

# total_mac_power=$(echo "${total_mac_power} 3.796" | awk '{printf "%.6f\n", $1 + $2}')

echo -e "Total MAC Power: $(printf "%.3f" $total_mac_power) W"
echo -e "Total OSFP Power: $(printf "%.3f" $total_osfp_power) W"