#!/bin/bash
RESULT_FILE=/var/log/temperature_screening_result.log
RESULT_NAME=/var/log/temperature_screening_result
#1.Only when the fan is fully loaded or at high temperatures to enable thermal sensor screening in ESS and burn-in test.
#2.Only when PSU_INLET temperature is above 32,It cannot be used for judgment at low temperatures.
#3.The difference between the maximum temperature (including serdes) read by MAC and the temperature read by the PSU_INLET sensor should be less than or equal to 40C
do_start() {

    if [ ! -f ${RESULT_FILE} ];then
        echo "${RESULT_FILE} file no exist"
        touch ${RESULT_FILE}
    fi
    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$time_stamp TEMPERATURE_SCREENING - INFO: The TEMP_ALARM_VALUE_SDK=($TEMP_ALARM_VALUE_SDK),TEMP_ALARM_VALUE_SENSOR=($TEMP_ALARM_VALUE_SENSOR)." >> ${RESULT_FILE}
    d_temp_over_cnt_sdk=0
    times_cnt_sdk=0
    d_temp_over_cnt_sensor=0
    times_cnt_sensor=0
    while :
    do
        ((times_cnt_sdk++))
        ((times_cnt_sensor++))
        inlet_temp_value=`cat /sys/bus/i2c/devices/i2c-76/76-0048/hwmon/hwmon*/temp1_input`
        if [[ $? -eq 0 && "$inlet_temp_value" != "" ]]; then
            ((vol_value=$inlet_temp_value/1000))
        else
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp TEMPERATURE_SCREENING - INFO: The PSU_INLET temperature read abnomal." >> ${RESULT_FILE}
            sleep 5
            continue
        fi
        sleep 30
    
        #2.Only when PSU_INLET temperature is above 32,It cannot be used for judgment at low temperatures.
        if [[ vol_value -le 32 ]]; then
            continue
        fi

        cnt=0
        while true
        do
            ((cnt++))
            if [ $cnt -eq 4 ]; then
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp TEMPERATURE_SCREENING - INFO: The ASIC temperature read abnomal." >> ${RESULT_FILE}
                sleep 5
                break
            fi
            echo "get MAC SDK value"
            mac_sdk_temp_value=`/usr/local/bin/get_thermal_sensor.sh --mac_sdk | awk '{print $4}'`
            echo "mac_sdk_temp_value:$mac_sdk_temp_value"
            if [[ $? -ne 0 || "$mac_sdk_temp_value" == "" || $mac_sdk_temp_value -le 5 ]]; then
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp TEMPERATURE_SCREENING - INFO: The MAC SDK temperature read abnomal(ret=$?,mac_temp=$mac_sdk_temp_value,count=${cnt})." >> ${RESULT_FILE}
                sleep 5
                continue
            fi
            echo "get MAC SENSOR value"
            mac_sensor_temp_value=`/usr/local/bin/get_thermal_sensor.sh --mac_sensor | awk '{print $4}'`
            echo "mac_sensor_temp_value:$mac_sensor_temp_value"
            if [[ $? -ne 0 || "$mac_sensor_temp_value" == "" || $mac_sensor_temp_value -le 5 ]]; then
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp TEMPERATURE_SCREENING - INFO: The MAC SENSOR temperature read abnomal(ret=$?,mac_temp=$mac_sensor_temp_value,count=${cnt})." >> ${RESULT_FILE}
                sleep 5
                continue
            else
                break
            fi
        done

        ((d_temp_value_sdk=$mac_sdk_temp_value - $vol_value))
    	# echo "The MAC temperature: $mac_sdk_temp_value" >> /var/log/temperature_screening_result.log
    	# echo "The PSU_INLET temperature: $vol_value" >> /var/log/temperature_screening_result.log
        # echo "The D-value temperature: $d_temp_value" >> /var/log/temperature_screening_result.log
         if [[ $d_temp_value_sdk -gt $TEMP_ALARM_VALUE_SDK ]]; then
            ((d_temp_over_cnt_sdk++))
            num=$((d_temp_over_cnt_sdk % 3))
            if [[ $num -eq 0 ]]; then
                d_temp_over_cnt_sdk=0
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp TEMPERATURE_SCREENING - ERROR: The D-value-sdk exceeded upper high, value is $d_temp_value_sdk, upper high is $TEMP_ALARM_VALUE_SDK." >> ${RESULT_FILE}
                echo "$time_stamp TEMPERATURE_SCREENING - ERROR: D_value_sdk = MAC_SDK_TEMP - PSU_INLET_TEMP,($d_temp_value_sdk = $mac_sdk_temp_value - $vol_value). " >> ${RESULT_FILE}
                sync
            else
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp TEMPERATURE_SCREENING - WARNING: The D-value-sdk exceeded upper high, value is $d_temp_value_sdk, upper high is $TEMP_ALARM_VALUE_SDK." >> ${RESULT_FILE}
                echo "$time_stamp TEMPERATURE_SCREENING - WARNING: D_value_sdk = MAC_SDK_TEMP - PSU_INLET_TEMP,($d_temp_value_sdk = $mac_sdk_temp_value - $vol_value). " >> ${RESULT_FILE}
                sync
            fi
        else
            num=$((times_cnt % 2))
            if [[ $num -eq 0 ]]; then
                times_cnt=0
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp TEMPERATURE_SCREENING - INFO:  D-value-sdk = MAC_SDK_TEMP - PSU_INLET_TEMP,($d_temp_value_sdk = $mac_sdk_temp_value - $vol_value)." >> ${RESULT_FILE}
                sync
            fi
        fi

        ((d_temp_value_sensor=$mac_sensor_temp_value - $vol_value))
    	# echo "The MAC temperature: $mac_sdk_temp_value" >> /var/log/temperature_screening_result.log
    	# echo "The PSU_INLET temperature: $vol_value" >> /var/log/temperature_screening_result.log
        # echo "The D-value temperature: $d_temp_value" >> /var/log/temperature_screening_result.log
         if [[ $d_temp_value_sensor -gt $TEMP_ALARM_VALUE_SENSOR ]]; then
            ((times_cnt_sensor++))
            num=$((times_cnt_sensor % 3))
            if [[ $num -eq 0 ]]; then
                times_cnt_sensor=0
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp TEMPERATURE_SCREENING - ERROR: The D-value-sensor exceeded upper high, value is $d_temp_value_sensor, upper high is $TEMP_ALARM_VALUE_SENSOR." >> ${RESULT_FILE}
                echo "$time_stamp TEMPERATURE_SCREENING - ERROR: D_value_sensor = MAC_SENSOR_TEMP - PSU_INLET_TEMP,($d_temp_value_sensor = $mac_sensor_temp_value - $vol_value). " >> ${RESULT_FILE}
                sync
            else
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp TEMPERATURE_SCREENING - WARNING: The D-value-sensor exceeded upper high, value is $d_temp_value_sensor, upper high is $TEMP_ALARM_VALUE_SENSOR." >> ${RESULT_FILE}
                echo "$time_stamp TEMPERATURE_SCREENING - WARNING: D_value_sensor = MAC_SENSOR_TEMP - PSU_INLET_TEMP,($d_temp_value_sensor = $mac_sensor_temp_value - $vol_value). " >> ${RESULT_FILE}
                sync
            fi
        else
            num=$((times_cnt % 2))
            if [[ $num -eq 0 ]]; then
                times_cnt=0
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp TEMPERATURE_SCREENING - INFO:  D_value_sensor = MAC_SENSOR_TEMP - PSU_INLET_TEMP,($d_temp_value_sensor = $mac_sensor_temp_value - $vol_value). " >> ${RESULT_FILE}
                sync
            fi
        fi
    done
}

do_check() {
    if [ ! -f ${RESULT_FILE} ];then
        echo "${RESULT_FILE} file no exist"
        touch ${RESULT_FILE}
    else
        read_result=`cat ${RESULT_FILE} | grep -iE "ERROR" | tail -n 6`
        if [[ "$read_result" != "" ]]; then
           echo "$read_result"
           echo "The TEMPERATURE_SCREENING occur abnormal."
           return -1
        fi
    fi

    echo "The TEMPERATURE_SCREENING is normal."
    return 0
}

do_result_backup() {
    if [ ! -f ${RESULT_FILE} ];then
        echo "${RESULT_FILE} file no exist"
        echo "The TEMPERATURE_SCREENING result file does not need backup."
    else
        time_str=$(date +%Y%m%d%H)
        mv ${RESULT_FILE} ${RESULT_NAME}_${time_str}.log
        echo "The TEMPERATURE_SCREENING result file backup completed."
    fi

    return 0
}

usage() {
    echo "Usage: "
    echo "$0 start [TEMP_ALARM_VALUE]"
    echo
    echo "$0 check"
    echo
    echo "$0 result_backup"
    echo
}
if [ $# -eq 1 ]; then
    TEMP_ALARM_VALUE_SDK=55
    TEMP_ALARM_VALUE_SENSOR=55
elif [ $# -eq 3 ]; then
    TEMP_ALARM_VALUE_SDK=$2
    TEMP_ALARM_VALUE_SENSOR=$3
else
    usage
    exit -1
fi

command="$1"

case "$command" in
    start)
        do_start
        ;;
    check)
        do_check 
        ;;
    result_backup)
        do_result_backup
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?

