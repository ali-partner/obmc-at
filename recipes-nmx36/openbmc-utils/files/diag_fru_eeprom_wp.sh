#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

usage() {
    echo "Usage: $0 [status|enable|disable]"
    echo "Option:"
    echo "  status    --Get all EEPROM's protected status"
    echo "  enable    --Enable all EEPROM's protected"
    echo "  disable   --Disable all EEPROM's protected"
    echo
}



do_status() {
    device_info=$1
    eeprom_wp_path=$2
	eeprom_wp_status=`head -n 1 ${eeprom_wp_path} 2> /dev/null`
	#echo "The ${eeprom_wp_path} EEPROM status: unknown ${eeprom_wp_status}"
    if [[ "$eeprom_wp_status" == "0x0" ]]; then
        echo "The ${device_info} EEPROM status: Not protected"
    elif [[ "$eeprom_wp_status" == "0x1" ]]; then
        echo "The ${device_info} EEPROM status: protected"
    else
	    echo "The ${device_info} EEPROM status: unknown"
	    return -1
    fi
	ret=$?
	return $ret
}

do_eeprom_wp_enable() {
    device_info=$1
    eeprom_wp_path=$2
    echo -n "To enable the ${device_info} EEPROM WP ..."
    echo 0x1 > ${eeprom_wp_path}
    ret=$?
	echo "Done"
    if [ $ret -eq 0 ]; then
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "$time_stamp INFO: BMC enable the ${device} EEPROM WP successful" >> /var/volatile/log/syslog; sync
    else
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
		echo "$time_stamp INFO: BMC enable the ${device} EEPROM WP failed" >> /var/volatile/log/syslog; sync
    fi
	return $ret
}

do_eeprom_wp_disable() {
    device_info=$1
    eeprom_wp_path=$2
    echo -n "To disable the ${device_info} EEPROM WP ..."
    echo 0x0 > ${eeprom_wp_path}
    ret=$?
	echo "Done"
    ret=$?
    if [ $ret -eq 0 ]; then
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "$time_stamp INFO: BMC disable the ${device} EEPROM WP successful" >> /var/volatile/log/syslog; sync
    else
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
		echo "$time_stamp INFO: BMC disable the ${device} EEPROM WP failed" >> /var/volatile/log/syslog; sync
    fi
	return $ret
}

do_all_status() {
    local has_error
    local ret_status
    for fru_config in "${fru_wp_config[@]}"; do
        do_status $fru_config
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

do_all_eeprom_wp_enable() {
    local has_error
    local ret_status
    for fru_config in "${fru_wp_config[@]}"; do
        do_eeprom_wp_enable $fru_config
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

do_all_eeprom_wp_disable() {
    local has_error
    local ret_status
    switch_cpld.sh write 1 0xe6 0x16
    for fru_config in "${fru_wp_config[@]}"; do
        do_eeprom_wp_disable $fru_config
        ret_status=$?
        if [ $ret_status -ne 0 ]; then
            has_error=-1
        fi
    done
    return $has_error
}

if [ $# -ne 1 ]; then
    usage
    exit -1
fi

object=$1

case "$object" in
    status)
        do_all_status
        ;;
    enable)
        do_all_eeprom_wp_enable
        ;;
     disable)
        do_all_eeprom_wp_disable
        ;;  
    *)
        usage
        ;;
esac

exit $?
