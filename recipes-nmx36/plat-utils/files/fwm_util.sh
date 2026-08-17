#!/bin/bash


PROGRAM_TITLE=`basename $0`
MAIN_ZONE="primary"
BACKUP_ZONE="secondary"

BMC_FILE="/run/initramfs/image-bmc"

usage() {
    echo "Usage: $PROGRAM_TITLE [bmc|bios] [primary|secondary] <file>"
    echo "Usage: $PROGRAM_TITLE cpld [basecpld|ocmcpld|fancpld|misccpld|portcpld1|portcpld2|lccpld] <file>"
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
    boot_status=`boot_area.sh bmc status | grep "Primary SPI"`
    if [ "$boot_status" != "" ]; then
        ret=0
    else
        ret=1
    fi
    return $ret
}

upgrade_bmc_image()
{
    zone=$1
    target_zone=$zone
    image_file=$2

    get_bmc_boot_status
    if [ $? -ne 0 ]; then
        # Now the system is running in the BACKUP_ZONE(i.e. the secondary one),
        # so it's necessary to switch the upgrade target zone to the correct one.
        [[ "X$zone" == "X$MAIN_ZONE" ]] && target_zone=$BACKUP_ZONE || target_zone=$MAIN_ZONE
    fi

    if [ "X$target_zone" == "X$MAIN_ZONE" ]; then
        fw_setenv openbmconce copy-files-to-ram copy-base-filesystem-to-ram
        fw_setenv openbmconce copy-files-to-ram copy-base-filesystem-to-ram
        [ $? -eq 0 ] || exit -1

        cp $image_file $BMC_FILE
        sleep 1
        echo "$PROGRAM_TITLE bmc $* Going to reboot to start the upgrade." && reboot
    else
        mtd=`cat /proc/mtd | grep -w alt-bmc | awk '{print $1}'`
        mtd_val=`echo ${mtd:0:4}`
        if [ -z "$mtd_val" ];then
            echo "BMC target partition not found.".
            exit -1
        else
            echo "BMC target partition $mtd_val found.".
            flashcp -v $image_file /dev/$mtd_val
            ret=$?
            [ $ret -eq 0 ] || exit -1
        fi
    fi
}


# Start of the script.
if [[ $# -ne 3 ]]; then
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
            upgrade_bmc_image $upgrade_zone $current_file
        else
            usage
            exit -1
        fi
        ;;
    bios)
        if [[ "X$upgrade_zone" == "X$MAIN_ZONE" ]]; then
            spi_util.sh write spi1 MAIN_BIOS $current_file
        elif [[ "X$upgrade_zone" == "X$BACKUP_ZONE" ]]; then
            spi_util.sh write spi1 BACKUP_BIOS $current_file
        else
            usage
            exit -1
        fi
        ;;
    cpld)
        cpld_update.sh update $upgrade_zone $current_file
        ;;
    phy)
        phy_update.sh $upgrade_zone $current_file
        ;;
    *)
        usage
        exit -1
        ;;
esac

echo "$PROGRAM_TITLE $* Success."

exit 0
