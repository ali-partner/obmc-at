#!/bin/bash
RESULT_FILE=/var/log/avs_current_monitor.log
RESULT_NAME=/var/log/avs_current_monitor
SWITCH_FILE=/tmp/avs_current_monitor_switch
do_start() {

    if [ ! -f ${RESULT_FILE} ];then
        echo "${RESULT_FILE} file no exist"
        touch ${RESULT_FILE}
    fi
    if [ ! -f ${SWITCH_FILE} ];then
        echo "${SWITCH_FILE} file no exist"
        touch ${SWITCH_FILE}
    fi
    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
    # echo "$time_stamp avs_current_monitor - INFO: The avs_current_monitor disable all chips fault ." >> ${RESULT_FILE}
    # disable_fault_str=`python /usr/local/bin/avs-chip-func.py disable_fault all`
    #echo "$disable_fault_str"
    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$time_stamp avs_current_monitor - INFO: The avs_current_monitor start." >> ${RESULT_FILE}
    write_switch=`echo 0 > ${SWITCH_FILE}`
    while :
    do
        if [[ "$switch_flag" == "1" ]]; then
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp avs_current_monitor - INFO: The avs_current_monitor stop." >> ${RESULT_FILE}
            break;
        fi
        # check_value=`python /usr/local/bin/avs-chip-func.py check_fault all`
        # sleep 10
        check_value=`python /usr/local/bin/avs-chip-func.py check all`
        switch_flag=`cat /tmp/avs_current_monitor_switch`
        sleep 20
        sensor_value=`diag_sensors.sh -a`
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp avs_current_monitor - INFO: \n $sensor_value\n" >> ${RESULT_FILE}
        sleep 30
    done
    exit 0
}

do_check() {
    if [ ! -f ${RESULT_FILE} ];then
        echo "${RESULT_FILE} file no exist"
        touch ${RESULT_FILE}
    else
        has_error=0
        read_result1=`cat ${RESULT_FILE} | grep -iE "failed" | tail -n 10`
        read_result2=`cat ${RESULT_FILE} | grep -iE "error" | tail -n 10`
        read_result3=`cat ${RESULT_FILE} | grep -iE "abnormal" | tail -n 10`
        if [[ "$read_result1" != "" ]]; then
            echo "$read_result1"
            has_error=-1
        fi
        if [[ "$read_result2" != "" ]]; then
            echo "$read_result2"
            has_error=-1
        fi
        if [[ "$read_result3" != "" ]]; then
            echo "$read_result3"
            has_error=-1
        fi
        if [ $has_error -eq -1 ]; then
            echo "The avs_current_monitor occur abnormal."
            return -1
        fi
    fi
    echo "The avs_current_monitor is normal."
    return 0
}

do_check_all() {
    if [ ! -f ${RESULT_FILE} ];then
        echo "${RESULT_FILE} file no exist"
        touch ${RESULT_FILE}
    else
        has_error=0
        read_result1=`cat ${RESULT_FILE} | grep -iE "failed" | tail -n 10`
        read_result2=`cat ${RESULT_FILE} | grep -iE "error" | tail -n 10`
        read_result3=`cat ${RESULT_FILE} | grep -iE "abnormal" | tail -n 10`
        read_result4=`cat ${RESULT_FILE} | grep -iE "not normal" | tail -n 10`
        if [[ "$read_result1" != "" ]]; then
            echo "$read_result1"
            has_error=-1
        fi
        if [[ "$read_result2" != "" ]]; then
            echo "$read_result2"
            has_error=-1
        fi
        if [[ "$read_result3" != "" ]]; then
            echo "$read_result3"
            has_error=-1
        fi
        if [[ "$read_result4" != "" ]]; then
            echo "$read_result4"
            has_error=-1
        fi
        if [ $has_error -eq -1 ]; then
            echo "The avs_current_monitor occur abnormal."
            return -1
        fi
    fi
    echo "The avs_current_monitor is normal."
    return 0
}

do_stop() {
    if [ ! -f ${SWITCH_FILE} ];then
        echo "${SWITCH_FILE} file no exist"
        touch ${SWITCH_FILE}
    fi
    write_switch=`echo 1 > ${SWITCH_FILE}`
    echo "The avs_current_monitor is stop."
    return 0
}
do_result_backup() {
    if [ ! -f ${RESULT_FILE} ];then
        echo "${RESULT_FILE} file no exist"
        echo "The avs_current_monitor result file does not need backup."
    else
        time_str=$(date +%Y%m%d%H)
        mv ${RESULT_FILE} ${RESULT_NAME}_${time_str}.log
        echo "The avs_current_monitor result file backup completed."
    fi

    return 0
}

usage() {
    echo "Usage: "
    echo "$0 start"
    echo
    echo "$0 check"
    echo
    echo "$0 stop"
    echo
    echo "$0 result_backup"
    echo
}

if [ $# -ne 1 ]; then
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
    check_all)
        do_check_all
        ;;
    stop)
        do_stop
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

