#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

FAN_RESULT_NAME=/var/log/fan_rpm_result
FAN_RESULT_FILE=/var/log/fan_rpm_result.log

do_start() {

    if [ ! -f ${FAN_RESULT_FILE} ];then
        echo "${FAN_RESULT_FILE} file no exist"
        touch ${FAN_RESULT_FILE}
    fi
    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$time_stamp FAN RPM Monitor - INFO: The RPM_ALARM_VALUE=($RPM_ALARM_VALUE)." >> ${FAN_RESULT_FILE}

    times_cnt=0
    while :
    do
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        ((times_cnt++))
        if [[ "$fan_board_type" == "0" ]]; then
            for((i=1; i<9; i++))
            do
                index=$i
                cnt=0
                while true
                do
                    ((cnt++))
                    if [ $cnt -eq 3 ]; then
                        echo "$time_stamp FAN RPM Monitor - ERROR: FAN$index status: Bad. " >> ${FAN_RESULT_FILE}
                        break
                    fi

                    if [[ "$i" -ge 1 ]] && [[ "$i" -le 4 ]]; then
                        local_index=$i
                        FANCPLD_SYSFS_DIR=$FAN1CPLD_SYSFS_DIR
                    elif [[ "$i" -ge 5 ]] && [[ "$i" -le 8 ]]; then
                        local_index=$((i - 4))
                        FANCPLD_SYSFS_DIR=$FAN2CPLD_SYSFS_DIR
                    fi

                    status_str=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_present`
                    status=${status_str:0:3}
                    if [[ "$status" == "0x1" ]]; then
                        echo "$time_stamp FAN RPM Monitor - INFO: The FAN$index status read abnomal(count=${cnt})." >> ${FAN_RESULT_FILE}
                        sleep 0.1
                        continue
                    else
                        pwm=`cat ${FANCPLD_SYSFS_DIR}/fantray${local_index}_pwm`
                        speed1=`cat ${FANCPLD_SYSFS_DIR}/fan${local_index}_speed_1`
                        speed2=`cat ${FANCPLD_SYSFS_DIR}/fan${local_index}_speed_2`
                        if [[ $? -ne 0 || $speed1 -lt $RPM_ALARM_VALUE || $speed2 -lt $RPM_ALARM_VALUE ]]; then
                            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                            echo "$time_stamp FAN RPM Monitor - ERROR: The FAN$index RPM is abnormal, The RPM less than $RPM_ALARM_VALUE(pwm: $pwm,speed1: $speed1,speed2: $speed2)." >> ${FAN_RESULT_FILE}
                            sync
                        fi
                        num=$((times_cnt % 5))
                        if [[ $num -eq 0 ]]; then
                            times_cnt=0
                            echo "$time_stamp FAN RPM Monitor - INFO: The FAN$index RPM is normal(pwm: $pwm,speed1: $speed1,speed2: $speed2)." >> ${FAN_RESULT_FILE}
                            sync
                        fi

                        break
                    fi
                done
                sleep 0.1
            done
        elif [[ "$fan_board_type" == "1" ]]; then
            for((i=1; i<6; i++))
            do
                index=$i
                cnt=0
                while true
                do
                    ((cnt++))
                    if [ $cnt -eq 3 ]; then
                        echo "$time_stamp FAN RPM Monitor - ERROR: FAN$index status: Bad. " >> ${FAN_RESULT_FILE}
                        break
                    fi
                    status_str=`cat ${FAN2CPLD_SYSFS_DIR}/fantray${index}_present`
                    status=${status_str:0:3}
                    if [[ "$status" == "0x1" ]]; then
                        echo "$time_stamp FAN RPM Monitor - INFO: The FAN$index status read abnomal(count=${cnt})." >> ${FAN_RESULT_FILE}
                        sleep 0.1
                        continue
                    else
                        pwm=`cat ${FAN2CPLD_SYSFS_DIR}/fantray${index}_pwm`
                        speed1=`cat ${FAN2CPLD_SYSFS_DIR}/fan${index}_speed_1`
                        speed2=`cat ${FAN2CPLD_SYSFS_DIR}/fan${index}_speed_2`
                        if [[ $? -ne 0 || $speed1 -lt $RPM_ALARM_VALUE || $speed2 -lt $RPM_ALARM_VALUE ]]; then
                            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                            echo "$time_stamp FAN RPM Monitor - ERROR: The FAN$index RPM is abnormal, The RPM less than $RPM_ALARM_VALUE(pwm: $pwm,speed1: $speed1,speed2: $speed2)." >> ${FAN_RESULT_FILE}
                            sync
                        fi
                        num=$((times_cnt % 5))
                        if [[ $num -eq 0 ]]; then
                            times_cnt=0
                            echo "$time_stamp FAN RPM Monitor - INFO: The FAN$index RPM is normal(pwm: $pwm,speed1: $speed1,speed2: $speed2)." >> ${FAN_RESULT_FILE}
                            sync
                        fi

                        break
                    fi
                done
                sleep 0.1
            done
        fi
        #one loop 120s 
        sleep 120
    done
}

do_check() {
    if [ ! -f ${FAN_RESULT_FILE} ];then
        echo "${FAN_RESULT_FILE} file no exist"
        touch ${FAN_RESULT_FILE}
    else
        read_result=`cat ${FAN_RESULT_FILE} | grep -iE "ERROR" | tail -n 10`
        if [[ "$read_result" != "" ]]; then
           echo "$read_result"
           echo "The FAN RPM_VALUE occur abnormal."
           return -1
        fi
    fi

    echo "The FAN RPM_VALUE is normal."
    return 0
}

do_result_backup() {
    if [ ! -f ${FAN_RESULT_FILE} ];then
        echo "${FAN_RESULT_FILE} file no exist"
        echo "The FAN RPM result file does not need backup."
    else
        time_str=$(date +%Y%m%d%H)
        mv ${FAN_RESULT_FILE} ${FAN_RESULT_NAME}_${time_str}.log
        echo "The FAN RPM result file backup completed."
    fi

    return 0
}

usage() {
    echo "Usage: "
    echo "$0 start [RPM_ALARM_VALUE]"
    echo
    echo "$0 check"
    echo
    echo "$0 result_backup"
    echo
}

if [ $# -ne 2 ]; then
    RPM_ALARM_VALUE=3000
elif [ $# -ne 3 ]; then
    RPM_ALARM_VALUE=$2
else
    usage
    exit -1
fi

command="$1"

case "$command" in
    start)
        do_start $RPM_ALARM_VALUE
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




