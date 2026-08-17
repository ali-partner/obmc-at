#!/bin/bash

i2c_path=/sys/bus/i2c/devices

# [0]device_name   [1]slave_addr  [2]bus  [3]parent_index
i2c_device_0=("basecpld"  "0x0d"  0  "")        # SYS_CPLD                (Base Board)
i2c_device_1=("pca9548"   "0x71"  1  "")        # BASE_PCA9548            (Base Board)
    i2c_device_2=("ocmcpld"  "0x0d" 16  1)      # OCM_CPLD                (OCM Board)
    i2c_device_3=("pca9548"  "0x70" 17  1)      # OCM_PCA9548             (OCM Board)
        i2c_device_4=("lm75b"   "0x48" 112  3)  # OCM_LM75BD              (OCM Board)
        i2c_device_5=("24c64"   "0x56" 113  3)  # OCM_EEPROM              (OCM Board)
        i2c_device_6=("mp2978"  "0x1f" 114  3)  # OCM_MP2978              (OCM Board)
        i2c_device_7=("mp2976"  "0x20" 114  3)  # OCM_MP2976              (OCM Board)
        i2c_device_8=("mp2976"  "0x2f" 114  3)  # OCM_MP2976              (OCM Board)
        i2c_device_9=("mp2940b" "0x3f" 114  3)  # OCM_MP2940B             (OCM Board)
        i2c_device_10=("tps544b25"  "0x26" 115  3)  # OCM_TPS544B25       (OCM Board)
        i2c_device_11=("tps544b25"  "0x27" 115  3)  # OCM_TPS544B25       (OCM Board)
i2c_device_12=("24c64"    "0x52"  2  "")        # BMC_EEPROM              (BMC Board)
i2c_device_13=("24c64"    "0x51"  2  "")        # BASE_EEPROM             (Base Board)
i2c_device_14=("pca9548"  "0x71"  2  "")        # BASE_PCA9548            (Base Board)
    i2c_device_15=("24c64"    "0x50" 24  14)    # SWITCH_EEPROM           (Switch Board)
    i2c_device_16=("24c64"    "0x53" 25  14)    # LINE_EEPROM             (Line Board)
i2c_device_17=("rx8010"   "0x51"  3  "")        # BMC_RTC                 (Base Board)
i2c_device_18=("pca9548"  "0x71"  4  "")        # BASE_PCA9548            (Base Board)
    i2c_device_19=("ina3221"    "0x40" 32  18)  # BASE_INA3221            (Base Board)
    i2c_device_20=("ina3221"    "0x40" 33  18)  # BASE_INA3221            (Base Board)
    i2c_device_21=("ina3221"    "0x40" 34  18)  # BASE_INA3221            (Base Board)
    i2c_device_22=("ina3221"    "0x40" 35  18)  # BASE_INA3221            (Base Board)
i2c_device_23=("pca9548"  "0x72"  4  "")        # SWITCH_PCA9548          (Switch Board)
    i2c_device_24=("mp2975"     "0x62" 40  23)  # SWITCH_MP2975           (Switch Board)
    i2c_device_25=("mp2975"     "0x63" 41  23)  # SWITCH_MP2975           (Switch Board)
    i2c_device_26=("mp2975"     "0x64" 42  23)  # SWITCH_MP2975           (Switch Board)
    i2c_device_27=("mp2975"     "0x65" 43  23)  # SWITCH_MP2975           (Switch Board)
    i2c_device_28=("mp2975"     "0x66" 44  23)  # SWITCH_MP2975           (Switch Board)
    i2c_device_29=("mp2975"     "0x6b" 45  23)  # SWITCH_MP2975           (Switch Board)
    i2c_device_30=("mp2975"     "0x6e" 46  23)  # SWITCH_MP2975           (Switch Board)
i2c_device_31=("pca9548"  "0x73"  4  "")        # SWITCH_PCA9548          (Switch Board)
    i2c_device_32=("mp2975"     "0x67" 48  31)  # SWITCH_MP2975           (Switch Board)
    i2c_device_33=("mp2975"     "0x68" 49  31)  # SWITCH_MP2975           (Switch Board)
    i2c_device_34=("ina3221"    "0x40" 50  31)  # SWITCH_INA3221          (Switch Board)
    i2c_device_35=("mp2975"     "0x67" 51  31)  # SWITCH_MP2975           (Switch Board)
    i2c_device_36=("mp2975"     "0x68" 52  31)  # SWITCH_MP2975           (Switch Board)
    i2c_device_37=("mp2975"     "0x69" 53  31)  # SWITCH_MP2975           (Switch Board)
    i2c_device_38=("mp2975"     "0x6a" 54  31)  # SWITCH_MP2975           (Switch Board)
i2c_device_39=("pca9548"  "0x74"  4  "")        # LINE_PCA9548            (Line Board)
    i2c_device_40=("ina3221"    "0x40" 56  39)  # LINE_INA3221            (Line Board)
    i2c_device_41=("mp2975"     "0x6b" 57  39)  # LINE_MP2975             (Line Board)
i2c_device_42=("switchfpga"  "0x32"  5  "")     # SWITCH_FPGA             (Switch Board)
i2c_device_43=("pca9548"     "0x71"  5  "")     # SWITCH_PCA9548          (Switch Board)
    i2c_device_44=("portcpld"   "0x31" 64  43)  # PORT1_CPLD              (Switch Board)
    i2c_device_45=("portcpld"   "0x31" 65  43)  # PORT2_CPLD              (Switch Board)
    i2c_device_46=("misccpld"   "0x31" 66  43)  # MISC_CPLD               (Switch Board)
    i2c_device_47=("lccpld"     "0x31" 67  43)  # LINE_CPLD               (Line Board)
i2c_device_48=("pca9548"     "0x71"  6  "")     # PDB_PCA9548             (PDB Board)
    i2c_device_49=("psu_driver" "0x58" 72  48)  # PSU1                    (PDB Board)
    i2c_device_50=("psu_driver" "0x58" 73  48)  # PSU2                    (PDB Board)
    i2c_device_51=("psu_driver" "0x58" 74  48)  # PSU3                    (PDB Board)
    i2c_device_52=("psu_driver" "0x58" 75  48)  # PSU4                    (PDB Board)
	i2c_device_53=("tmp275"     "0x48" 76  48)  # PDB_TMP275              (PDB Board)
i2c_device_54=("pca9548"     "0x71"  7  "")     # SWITCH_PCA9548          (Switch Board)
i2c_device_55=("fancpld"     "0x0d"  8  "")     # FAN_CPLD                (Fan Board)
i2c_device_56=("pca9548"     "0x71"  8  "")     # FAN_PCA9548             (Fan Board)
    i2c_device_57=("24c64"      "0x50" 88  56)  # FAN5_EEPROM             (Fan Board)
    i2c_device_58=("24c64"      "0x50" 89  56)  # FAN4_EEPROM             (Fan Board)
    i2c_device_59=("24c64"      "0x50" 90  56)  # FAN3_EEPROM             (Fan Board)
    i2c_device_60=("24c64"      "0x50" 91  56)  # FAN2_EEPROM             (Fan Board)
    i2c_device_61=("24c64"      "0x50" 92  56)  # FAN1_EEPROM             (Fan Board)
    i2c_device_62=("24c02"      "0x56" 94  56)  # FAN_FRU_EEPROM          (Fan Board)
    i2c_device_63=("tmp275"     "0x48" 95  56)  # FAN_TEMP1               (Fan Board)
    i2c_device_64=("tmp275"     "0x49" 95  56)  # FAN_TEMP2               (Fan Board)
i2c_device_65=("pca9548"     "0x70"  13  "")    # PCIE_PCA9548            (Fan Board)
i2c_device_66=("pca9548"     "0x71"  13  "")    # SWITCH_PCA9548          (Fan Board)

device_max_num=66

# $1: driver name  $2: slave addr $3: bus num
new_i2c_device() {
    name=$1
    addr=$2
    bus=$3

    local -i _CNT="1"
    local -ir _MAX="5"
    local -r _PERIOD="0.01"   # period 10ms

    parent_path=$i2c_path/i2c-$bus
    device=$bus-00${addr:$((-2))}
    device_path=$i2c_path/$device

    if [ "$4" == "new" ]; then
        while [[ "${_CNT}" -le "${_MAX}" ]]; do
            # check parent path exist
            if [ -d $parent_path ] ;then
                # check if exist
                if [ ! -d "$device_path" ]; then
                    echo "Create i2c device: $name $device"
                    /usr/bin/logger "Create i2c device: $name $device"
                    echo $name $addr > $parent_path/new_device
                    sleep "${_PERIOD}"
                fi

                if [ -d $device_path/gpio ]; then
                    echo "$device_path find gpio  outside"
                    /usr/bin/logger "$device_path find gpio"
                    break
                fi
                if [ -e $device_path/eeprom ]; then
                    echo "$device_path find eeprom outside"
                    /usr/bin/logger "$device_path find eeprom"
                    break
                fi
                if [ -d $device_path/channel-0 ]; then
                    echo "$device_path find channel-0 outside"
                    /usr/bin/logger "$device_path find channel-0"
                    break
                fi
                if [ -d $device_path/hwmon ]; then
                    echo "$device_path find hwmon outside"
                    /usr/bin/logger "$device_path find hwmon"
                    break
                fi
                if [ -d $device_path/rtc ]; then
                    echo "$device_path find rtc"
                    /usr/bin/logger "$device_path find rtc"
                    break
                fi

                echo "Destory i2c device: $name $device"
                /usr/bin/logger "Destory i2c device: $name $device"
                echo $addr > $parent_path/delete_device
                sleep "${_PERIOD}"
            fi
            let "_CNT++"
            sleep "${_PERIOD}"
        done
    else
        if [ -d "$device_path" ]; then
            echo "Destory i2c device: $name $device"
            /usr/bin/logger "Destory i2c device: $name $device"
            echo $addr > $parent_path/delete_device
        fi
    fi
}

i2c_find_child() {
    local id=$1
    local index

    for ((index=0;index<$device_max_num;index++));
    do
        local device=()
        local new_del=$2
        local paramter_index

        eval parent_arry=\${i2c_device_${index}[@]}
        for paramter_index in ${parent_arry}; do
            device[${#device[*]}]=$paramter_index
        done

        local dev_parent=${device[3]}

        # find depends
        if [[ "$dev_parent" == $1 ]];
        then
            local dev_name=${device[0]}
            local dev_addr=${device[1]}
            local dev_bus=${device[2]}

            # new device
            if [ "$2" == "new" ]; then
                new_i2c_device $dev_name $dev_addr $dev_bus $new_del
                i2c_find_child $index $new_del
            else
                i2c_find_child $index $new_del
                new_i2c_device $dev_name $dev_addr $dev_bus $new_del
            fi
        fi
    done
}

i2c_device_manager() {
    local index=$1
    local device=()
    local paramter_index

    eval parent_arry=\${i2c_device_${index}[@]}
    for paramter_index in ${parent_arry}; do
        device[${#device[*]}]=$paramter_index
    done

    if [ "$2" == "new" ]; then
        new_i2c_device ${device[0]} ${device[1]} ${device[2]} $2
        i2c_find_child $index $2
    else
        i2c_find_child $index $2
        new_i2c_device ${device[0]} ${device[1]} ${device[2]} $2
    fi
}

i2c_topology_create() {
    echo "I2c topology create started."
    /usr/bin/logger "I2c topology create started."
    for ((dev_index=0;dev_index<=$device_max_num;dev_index++));
    do
        local index=$dev_index
        local device=()
        local paramter_index

        eval parent_arry=\${i2c_device_${index}[@]}
        for paramter_index in ${parent_arry}; do
            device[${#device[*]}]=$paramter_index
        done

        if [ ${#device[*]} -eq 3 ]; then
            echo "creat top level i2c device $dev_index"
            /usr/bin/logger "creat top level i2c device $dev_index"
            i2c_device_manager $dev_index "new"
        else
            continue
        fi
    done
    echo "I2c topology create finished."
    /usr/bin/logger "I2c topology create finished."
}

i2c_topology_destory() {
    echo "I2c topology destory started."
    /usr/bin/logger "I2c topology destory started."
    for ((dev_index=0;dev_index<=$device_max_num;dev_index++));
    do
        local index=$dev_index
        local device=()
        local paramter_index

        eval parent_arry=\${i2c_device_${index}[@]}
        for paramter_index in ${parent_arry}; do
            device[${#device[*]}]=$paramter_index
        done

        if [ ${#device[*]} -eq 3 ]; then
            echo "delete top level i2c device $dev_index"
            /usr/bin/logger "delete top level i2c device $dev_index"
            i2c_device_manager $dev_index "del"
        else
            continue
        fi
    done
    echo "I2c topology destory finished."
    /usr/bin/logger "I2c topology destory finished."
}
