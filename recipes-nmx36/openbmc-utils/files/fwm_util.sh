#!/bin/bash


PROGRAM_TITLE=`basename $0`
MAIN_ZONE="primary"
BACKUP_ZONE="secondary"
CHECK_PRODUCT_NAME="NA"

product_name=$(cat /etc/openbmc/product_name)

usage() {
    echo "Usage: $PROGRAM_TITLE [bmc|bios] [primary|secondary] <file> [sign|unsign]"
    echo "Usage: $PROGRAM_TITLE cpld [basecpld|ocmcpld|fan1cpld|fan2cpld|misccpld|portcpld1|portcpld2|ledcpld] <file> [sign|unsign]"

    echo "Usage: $PROGRAM_TITLE phy 88E6361 <file>"
    echo
    echo "Examples:"
    echo "      $PROGRAM_TITLE bmc  secondary <file>       # upgrade BMC secondary image."
    echo "      $PROGRAM_TITLE bios primary <file>         # upgrade BIOS primary image."
    echo "      $PROGRAM_TITLE cpld misccpld <file>        # upgrade MISC CPLD image."
}

test_image_file()
{
    FILE_NAME=$1
    FILE_SIZE=$2

    if [ -f $FILE_NAME ]; then
        image_file_size=`du -a $FILE_NAME | cut -f 1`
        if [ $image_file_size -ne $FILE_SIZE ]; then
            echo "The image file '$FILE_NAME' size is not correct($image_file_size bytes), must be $FILE_SIZE KBytes, quit."
            exit -1
        fi
    else
        echo "The image file '$FILE_NAME' does not exist, quit."
        exit -1
    fi

}

get_bmc_boot_status()
{
    ret=$(devmem 0x14c3744c 32)
    boot_source=${ret:9:1}
    if [ $boot_source -eq 0 ]; then
        ret=0
    else
        ret=1
    fi
    return $ret
}

check_component_sign() {
    local tmp_component=$1
    local file_name=$2
    local out_fw_file=$3
    local output
    local ret

    #output=$(unsign_fw.sh $CHECK_PRODUCT_NAME $tmp_component $file_name $out_fw_file)
    echo "$tmp_component start unsign process, file name: $file_name"
    unsign_fw.sh $CHECK_PRODUCT_NAME $tmp_component $file_name $out_fw_file
    ret=$?
    # echo "${output}"
    if [ "${ret}" -ne 0 ];then
        echo "$tmp_component unsign process failed, return code = ${ret}"
    else
        echo "$tmp_component unsign process success"
    fi
    return $ret
}

upgrade_bmc_image()
{
    zone=$1
    fw_file=$2
    target_zone=$zone

    get_bmc_boot_status
    if [ $? -ne 0 ]; then
        # Now the system is running in the BACKUP_ZONE(i.e. the secondary one),
        # so it's necessary to switch the upgrade target zone to the correct one.
        [[ "X$zone" == "X$MAIN_ZONE" ]] && target_zone=$BACKUP_ZONE || target_zone=$MAIN_ZONE
    fi

    if [ "X$target_zone" == "X$MAIN_ZONE" ]; then
        mtd_name="main-bmc"
    else
        mtd_name="alt-bmc"
    fi

    mtd_val=`cat /proc/mtd | grep -w "$mtd_name" | cut -d ":" -f 1`
    if [ -z "$mtd_val" ];then
        echo "BMC target partition not found.".
        echo "$PROGRAM_TITLE $* Failed."
        exit -1
    else
        echo "BMC target partition $mtd_val found.".
        flashcp -v $fw_file /dev/$mtd_val
        ret=$?
        if [ $ret -ne 0 ]; then
            echo "$PROGRAM_TITLE $* Failed."
            exit -1
        fi
    fi
}


sign_mode="sign"

# Start of the script.
if [[ $# -eq 4 ]]; then
    if [[ "$4" == "sign" || "$4" == "unsign" ]]; then
        sign_mode="$4"
    else
        echo "ERROR: Invalid last argument: $4. Must be 'sign' or 'unsign'."
        usage
        exit -1
    fi
elif [[ $# -ne 3 ]]; then
    usage
    exit -1
fi

upgrade_module=$1
upgrade_zone=$2
current_file=$3


case "$upgrade_module" in
    bmc)
        #test_image_file $current_file 32768
        if [[ "X$upgrade_zone" == "X$MAIN_ZONE" || "X$upgrade_zone" == "X$BACKUP_ZONE" ]]; then
            if [[ "$sign_mode" == "sign" ]]; then
                out_fw_file="/tmp/tmp_bmc_flash.bin"
                check_component_sign BMC $current_file $out_fw_file
                if [ $? -ne 0 ];then
                    echo "$PROGRAM_TITLE $* Failed."
                    exit -1
                fi
                upgrade_bmc_image $upgrade_zone $out_fw_file
                if [ -f "${out_fw_file}" ]; then
                    rm -f "${out_fw_file}"
                fi
            else
                upgrade_bmc_image $upgrade_zone $current_file
            fi
        else
            usage
            exit -1
        fi
        ;;
    bios)
        if [[ "X$upgrade_zone" == "X$MAIN_ZONE" ]]; then
            if [[ "$sign_mode" == "sign" ]]; then
                out_fw_file="/tmp/tmp_bios_flash.bin"
                check_component_sign BIOS $current_file $out_fw_file
                if [ $? -ne 0 ]; then
                    echo "$PROGRAM_TITLE $* Failed."
                    exit -1
                fi
                spi_util.sh write spi1 MAIN_BIOS $out_fw_file
                if [ $? -ne 0 ]; then
                    echo "$PROGRAM_TITLE $* Failed."
                    exit -1
                fi
                if [ -f "${out_fw_file}" ]; then
                    rm -f "${out_fw_file}"
                fi
            else
                spi_util.sh write spi1 MAIN_BIOS $current_file
                if [ $? -ne 0 ]; then
                    echo "$PROGRAM_TITLE $* Failed."
                    exit -1
                fi
            fi
        elif [[ "X$upgrade_zone" == "X$BACKUP_ZONE" ]]; then
            if [[ "$sign_mode" == "sign" ]]; then
                out_fw_file="/tmp/tmp_bios_flash.bin"
                check_component_sign BIOS $current_file $out_fw_file
                if [ $? -ne 0 ]; then
                    echo "$PROGRAM_TITLE $* Failed."
                    exit -1
                fi
                spi_util.sh write spi1 BACKUP_BIOS $out_fw_file
                if [ $? -ne 0 ]; then
                    echo "$PROGRAM_TITLE $* Failed."
                    exit -1
                fi
                if [ -f "${out_fw_file}" ]; then
                    rm -f "${out_fw_file}"
                fi
            else
                spi_util.sh write spi1 BACKUP_BIOS $current_file
                if [ $? -ne 0 ]; then
                    echo "$PROGRAM_TITLE $* Failed."
                    exit -1
                fi
            fi
        else
            usage
            echo "$PROGRAM_TITLE $* Failed."
            exit -1
        fi
        ;;
    cpld)
        if [[ "$sign_mode" == "sign" ]]; then
            case "$upgrade_zone" in
                basecpld)   cpld_type="SYS_CPLD" ;;
                ocmcpld)    cpld_type="OCM_CPLD" ;;
                fan1cpld)   cpld_type="FAN_CPLD" ;;
                fan2cpld)   cpld_type="FAN_CPLD" ;;
                misccpld)   cpld_type="MISC_CPLD" ;;
                portcpld1)  cpld_type="PORT_CPLD1" ;;
                portcpld2)  cpld_type="PORT_CPLD2" ;;
                ledcpld)    cpld_type="LED_CPLD" ;;
                *)
                    echo "ERROR: invalid cpld zone: $upgrade_zone"
                    usage
                    echo "$PROGRAM_TITLE $* Failed."
                    exit -1
                    ;;
            esac

            out_fw_file="/tmp/tmp_${upgrade_zone}_flash.vme"
            check_component_sign "$cpld_type" "$current_file" "$out_fw_file"
            if [ $? -ne 0 ]; then
                echo "$PROGRAM_TITLE $* Failed."
                exit -1
            fi
            cpld_update.sh update $upgrade_zone $out_fw_file
            if [ $? -ne 0 ]; then
                echo "$PROGRAM_TITLE $* Failed."
                exit -1
            fi
            if [ -f "${out_fw_file}" ]; then
                rm -f "${out_fw_file}"
            fi
        else
            cpld_update.sh update $upgrade_zone $current_file
            if [ $? -ne 0 ]; then
                echo "$PROGRAM_TITLE $* Failed."
                exit -1
            fi
        fi
        ;;
    phy)
        phy_update.sh $upgrade_zone $current_file
        if [ $? -ne 0 ]; then
            echo "$PROGRAM_TITLE $* Failed."
            exit -1
        fi
        ;;
    *)
        usage
        exit -1
        ;;
esac

echo "$PROGRAM_TITLE $* Success."

exit 0
