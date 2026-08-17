#!/bin/bash

i2c_path=/sys/bus/i2c/devices

# [0]device_name   [1]slave_addr  [2]bus  [3]parent_index
i2c_device_0=("basecpld"  "0x0d"  0  "")        # SYS_CPLD                (Base Board)
i2c_device_1=("pca9548"   "0x71"  1  "")        # BASE_PCA9548            (Base Board)
    i2c_device_2=("lm75b"    "0x48" 16  1)      # OCM_LM75BD              (OCM Board)
    i2c_device_3=("24c64"    "0x56" 16  1)      # OCM_EEPROM              (OCM Board)
    i2c_device_4=("ocmcpld"  "0x0d" 16  1)      # OCM_CPLD                (OCM Board)
    i2c_device_5=("ucd90160" "0x5f" 17  1)      # OCM_UCD90160            (OCM Board)
    i2c_device_6=("tps544b25"    "0x27" 17  1)  # OCM_TPS544B25           (OCM Board)
    i2c_device_7=("xdpe12284"    "0x58" 17  1)  # SWITCH_XDPE12284        (OCM Board)
    i2c_device_8=("xdpe12284"    "0x60" 17  1)  # SWITCH_XDPE12284        (OCM Board)
    i2c_device_9=("xdpe12284"    "0x6e" 17  1)  # SWITCH_XDPE12284        (OCM Board)
i2c_device_10=("24c64"    "0x52"  2  "")        # BMC_EEPROM              (BMC Board)
i2c_device_11=("lm75b"    "0x49"  2  "")        # BMC_LM75BD              (BMC Board)
i2c_device_12=("pca9548"  "0x71"  2  "")        # BASE_PCA9548            (Base Board)
    i2c_device_13=("24c64"     "0x51" 24  12)   # BASE_EEPROM             (Base Board)
    i2c_device_14=("pcf85063"  "0x51" 25  12)   # BMC_RTC                 (Base Board)
    i2c_device_15=("ucd90160"  "0x68" 28  12)   # BMC_UCD90160            (BMC Board)
    i2c_device_16=("ina3221"   "0x40" 29  12)   # BASE_INA3221            (Base Board)
    i2c_device_17=("ina3221"   "0x40" 30  12)   # BASE_INA3221            (Base Board)
    i2c_device_18=("ina3221"   "0x40" 31  12)   # BASE_INA3221            (Base Board)
i2c_device_19=("pca9548"  "0x72"  2  "")        # BASE_PCA9548            (Base Board)
    i2c_device_20=("24c64"    "0x50" 32  19)    # SWITCH_EEPROM           (Switch Board)
    i2c_device_21=("24c64"    "0x60" 33  19)    # FPGA_EEPROM             (Switch Board)
    i2c_device_22=("tmp275"   "0x48" 34  19)    # MGMT_TMP                (MGMT Board)
    i2c_device_23=("ina3221"  "0x40" 35  19)    # SWITCH_INA3221          (Switch Board)
    i2c_device_24=("ina3221"  "0x40" 36  19)    # SWITCH_INA3221          (Switch Board)
    i2c_device_25=("ina3221"  "0x40" 37  19)    # SWITCH_INA3221          (Switch Board)
    i2c_device_26=("ina3221"  "0x40" 38  19)    # SWITCH_INA3221          (Switch Board)
    i2c_device_27=("ina3221"  "0x40" 39  19)    # SWITCH_INA3221          (Switch Board)
i2c_device_28=("fancpld"  "0x0d"  3  "")        # FAN_CPLD                (Fan Board)
i2c_device_29=("pca9548"  "0x71"  3  "")        # FAN_PCA9548             (Fan Board)
    i2c_device_30=("24c64"   "0x50" 40  29)     # FAN1_EEPROM             (Fan Board)
    i2c_device_31=("24c64"   "0x50" 41  29)     # FAN2_EEPROM             (Fan Board)
    i2c_device_32=("24c64"   "0x50" 42  29)     # FAN3_EEPROM             (Fan Board)
    i2c_device_33=("24c64"   "0x50" 43  29)     # FAN4_EEPROM             (Fan Board)
    i2c_device_34=("24c02"   "0x56" 46  29)     # FAN_FRU_EEPROM          (Fan Board)
    i2c_device_35=("tmp275"  "0x48" 47  29)     # FAN_TEMP1               (Fan Board)
    i2c_device_36=("tmp275"  "0x49" 47  29)     # FAN_TEMP2               (Fan Board)
i2c_device_37=("pca9548"  "0x71"  4  "")        # BASE_PCA9548            (Base Board)
    i2c_device_38=("mp29816"    "0x60" 48  37)  # SWITCH_MP29816          (Switch Board)
    i2c_device_39=("mp29816"    "0x63" 49  37)  # SWITCH_MP29816          (Switch Board)
    i2c_device_40=("mp29816"    "0x64" 50  37)  # SWITCH_MP29816          (Switch Board)
    i2c_device_41=("mp29816"    "0x65" 51  37)  # SWITCH_MP29816          (Switch Board)
    i2c_device_42=("mp29816"    "0x66" 52  37)  # SWITCH_MP29816          (Switch Board)
    i2c_device_43=("mp2985"    "0x62" 53  37)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_44=("mp2985"    "0x6b" 54  37)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_45=("mp2985"    "0x6e" 55  37)  # SWITCH_MP2985B          (Switch Board)
i2c_device_46=("pca9548"  "0x72"  4  "")        # SWITCH_PCA9548          (Switch Board)
    i2c_device_47=("mp2985"    "0x63" 56  46)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_48=("mp2985"    "0x64" 57  46)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_49=("mp2985"    "0x65" 58  46)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_50=("mp2985"    "0x66" 59  46)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_51=("mp2985"    "0x67" 60  46)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_52=("mp2985"    "0x68" 61  46)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_53=("mp2985"    "0x69" 62  46)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_54=("mp2985"    "0x6a" 63  46)  # SWITCH_MP2985B          (Switch Board)
i2c_device_55=("pca9548"  "0x71"  5  "")        # SWITCH_PCA9548          (Switch Board)
    i2c_device_56=("portcpld"   "0x31" 64  55)  # PORT1_CPLD              (Switch Board)
    i2c_device_57=("portcpld"   "0x31" 65  55)  # PORT2_CPLD              (Switch Board)
    i2c_device_58=("misccpld"   "0x31" 66  55)  # MISC_CPLD               (Switch Board)
    i2c_device_59=("switchfpga" "0x32" 67  55)  # SWITCH_FPGA             (Switch Board)
    i2c_device_60=("ledcpld"    "0x31" 68  55)  # LED_CPLD                (LED Board)
i2c_device_61=("pca9548"  "0x71"  6  "")        # PDB_PCA9548             (PDB Board)
    i2c_device_62=("psu_driver" "0x58" 72  61)  # PSU4                    (PDB Board)
    i2c_device_63=("psu_driver" "0x58" 73  61)  # PSU3                    (PDB Board)
    i2c_device_64=("psu_driver" "0x58" 74  61)  # PSU2                    (PDB Board)
    i2c_device_65=("psu_driver" "0x58" 75  61)  # PSU1                    (PDB Board)
    i2c_device_66=("tmp275"     "0x48" 76  61)  # PDB_TMP275              (PDB Board)
i2c_device_67=("asictemp_driver"   "0x1f"  7  "")        # SWITCH_tmp432           (Switch Board)
i2c_device_68=("fancpld"  "0x0d"  8  "")        # FAN_CPLD                (Fan Board)
i2c_device_69=("pca9548"  "0x71"  8  "")        # FAN_PCA9548             (Fan Board)
    i2c_device_70=("24c64"   "0x50" 88  69)     # FAN1_EEPROM             (Fan Board)
    i2c_device_71=("24c64"   "0x50" 89  69)     # FAN2_EEPROM             (Fan Board)
    i2c_device_72=("24c64"   "0x50" 90  69)     # FAN3_EEPROM             (Fan Board)
    i2c_device_73=("24c64"   "0x50" 91  69)     # FAN4_EEPROM             (Fan Board)
    i2c_device_74=("24c02"   "0x56" 94  69)     # FAN_FRU_EEPROM          (Fan Board)
    i2c_device_75=("tmp275"  "0x48" 95  69)     # FAN_TEMP1               (Fan Board)
    i2c_device_76=("tmp275"  "0x49" 95  69)     # FAN_TEMP2               (Fan Board)
i2c_device_77=("pca9548"  "0x71"  11  "")       # SWITCH_PCA9548          (Switch Board)
i2c_device_78=("pca9548"  "0x72"  11  "")       # SWITCH_PCA9548          (Switch Board)
    i2c_device_79=("mp2985"   "0x67" 104  78)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_80=("mp2985"   "0x68" 105  78)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_81=("mp2985"   "0x69" 106  78)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_82=("mp2985"   "0x6a" 107  78)  # SWITCH_MP2985B          (Switch Board)
    i2c_device_83=("ina3221"   "0x40" 108  78)  # MGMT_INA3221            (MGMT Board)
    i2c_device_84=("tmp275"    "0x48" 109  78)  # SWITCH_TMP275           (Switch Board)
    i2c_device_85=("tmp275"    "0x48" 110  78)  # SWITCH_TMP275           (Switch Board)

device_max_num=86


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
                    if [ $addr == 32 || $addr == 34 ]; then
                        sleep 1
                    fi
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
