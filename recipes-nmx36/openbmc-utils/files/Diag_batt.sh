#/bin/bash

. /usr/local/bin/openbmc-utils.sh

prog="$0"

usage() {
    echo "Usage: $prog <command>"
    echo
    echo "Commands:"
    echo "  cpld: RTC battery voltage detects by CPLD."
    echo
    echo "  bmc: RTC battery voltage detects by BMC ADC."
    echo
}

RTC_BATTERY_EN_SYSFS="${BASECPLD_SYSFS_DIR}/rtc_battery_vol_en"
RTC_BATTERY_STATE_SYSFS="${BASECPLD_SYSFS_DIR}/rtc_battery_state"

do_battery_vol_detect_by_cpld() {
    echo -e "RTC battery detects the enable signal ...\n"
    echo 1 > $RTC_BATTERY_EN_SYSFS
    usleep 100000

    batt_state_cpld=`cat $RTC_BATTERY_STATE_SYSFS | sed -n 1p`

    echo 0 > $RTC_BATTERY_EN_SYSFS
    if [ "$batt_state_cpld" == "0x1" ]; then
        echo -e "The RTC battery voltage state by CPLD : normal\n"
    else
	    echo -e "The RTC battery voltage state by CPLD : abnormal\n"
		echo -e "The RTC battery voltage state detects fail.\n"
		exit -1
	fi
	exit 0
}


IN_VOLTAGE_PATH="/sys/devices/platform/soc@14000000/14c00000.adc/iio:device0"

do_battery_vol_detect_by_bmc(){
    # 打开开关
    echo 1 > $RTC_BATTERY_EN_SYSFS
    usleep 100000

    # 读BMC ADC0输入电压及其系数
    raw_data=$(cat ${IN_VOLTAGE_PATH}/in_voltage0_raw)
    raw_scale=$(cat ${IN_VOLTAGE_PATH}/in_voltage_scale)
    adc_offset=$(cat ${IN_VOLTAGE_PATH}/in_voltage_offset)

    echo "Read BMC system voltage is ${raw_data}"

    # 测完后关掉
    echo 0 > $RTC_BATTERY_EN_SYSFS

    # 计算电压值，其中分压系数为2
    cal_value=$(echo "$raw_data  $adc_offset $raw_scale 1000" | awk '{printf("%0.9f\n", ($1-$2)*$3/$4)}')
    vol_value=$(echo "$cal_value 2" | awk '{printf("%0.3f\n", $1*$2)}')
    echo "BMC ADC0 voltage: $vol_value"

    # 硬件提供的电压阈值范围2.0~3.3V
    LowThd=2.0
    HighThd=3.4
    echo "BMC ADC0 voltage threshold: ${LowThd}~${HighThd}"

    # 判断电压是否超出阈值
    THD_L=$(awk -v x="$vol_value" -v y=$LowThd 'BEGIN{print(x>=y)?"0":"1"}')
    THD_H=$(awk -v x="$vol_value" -v y=$HighThd 'BEGIN{print(x<=y)?"0":"1"}')
    if [[ $THD_L -eq 1 || $THD_H -eq 1 ]]; then
        echo "BMC ADC0 voltage: $vol_value not within threshold: ${LowThd}~${HighThd}"
        echo "RTC test Failed"
        exit 1
    fi
    echo "RTC test Pass"
    exit 0
}



if [ $# -lt 1 ]; then
    usage
    exit -1
fi

command="$1"
shift

case "$command" in
    cpld)
        do_battery_vol_detect_by_cpld $@
        ;;
    bmc)
        do_battery_vol_detect_by_bmc $@
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?