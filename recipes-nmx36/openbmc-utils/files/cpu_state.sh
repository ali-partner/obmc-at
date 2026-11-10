#!/bin/bash
#3 GPIO: SUS_S3_N, SUS_S4_N, CPU_PLTRST
#S5: all are 0, power off
#S0: all are 1, power on

. /usr/local/bin/openbmc-utils.sh

PROGRAM_TITLE=`basename $0`

#Bit[1:1] @ register 0x13, 0: Not entered S3 state, 1: Entered S3 state
# CPU_STATE_S3_STATE1="${BASECPLD_SYSFS_DIR}/cpu_slp_s3_state"
#Bit[2:2] @ register 0x13, 0: Not entered S45 state,1: Entered S45 state
CPU_STATE_S4_STATE2="${BASECPLD_SYSFS_DIR}/cpu_slp_s45_state"
#Bit[0:0] @ register 0x30, 0: abnormal 1: normal
CPU_STATE_PLTRST_STATE3="${BASECPLD_SYSFS_DIR}/cpu_reset"

state_last=0
state_now=0

cpu_state_last(){

    # CMD_STATE1=`cat $CPU_STATE_S3_STATE1 | sed -n 1p`
    CMD_STATE2=`cat $CPU_STATE_S4_STATE2 | sed -n 1p`
    CMD_STATE3=`cat $CPU_STATE_PLTRST_STATE3 | sed -n 1p`

    if [[ $CMD_STATE2 -eq 0 ]] && [[ $CMD_STATE3 -eq 0 ]]; then
        state_last=0
    fi

    if [[ $CMD_STATE2 -eq 1 ]] && [[ $CMD_STATE3 -eq 1 ]]; then
        state_last=1
    fi
}

cpu_state_now(){

    # CMD_STATE1=`cat $CPU_STATE_S3_STATE1 | sed -n 1p`
    CMD_STATE2=`cat $CPU_STATE_S4_STATE2 | sed -n 1p`
    CMD_STATE3=`cat $CPU_STATE_PLTRST_STATE3 | sed -n 1p`

    if [[ $CMD_STATE2 -eq 0 ]] && [[ $CMD_STATE3 -eq 0 ]]; then
        state_now=0
    fi

    if [[ $CMD_STATE2 -eq 1 ]] && [[ $CMD_STATE3 -eq 1 ]]; then
        state_now=1
    fi
}
#S0-开机,S3-待机,S4-休眠,S5-关机
do_get_cpu_state() {
    cpu_state_last
    sleep 1
    cpu_state_now
    if [ $state_last -ne $state_now ]; then
        if [ $state_last -eq 0 ]; then
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp WARNING: CPU state changed to S0." >> /var/volatile/log/syslog
            echo "S0"
        else
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp CRITICAL: CPU state changed to power saving mode S5." >> /var/volatile/log/syslog
            echo "S5"
        fi
    else
        if [ $state_now -eq 1 ]; then
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            #echo "$time_stamp WARNING: CPU state changed to S0" >> /var/volatile/log/syslog
            echo "S0"
        else
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp CRITICAL: CPU state changed to power saving mode S5." >> /var/volatile/log/syslog
            echo "S5"
        fi
    fi
}

usage() {
    echo "Usage: $PROGRAM_TITLE [get]"
    echo
    echo "Example:"
    echo "    $PROGRAM_TITLE get          --Get CPU state"
    #echo "    $PROGRAM_TITLE monitor      --Monitor CPU state"
    echo
}

if [[ $# -gt 1 ]]; then
    usage
    exit -1
fi

if [[ $# -eq 0 ]]; then
    do_get_cpu_state
    exit 0
fi

object=$1

case "$object" in
    get)
        do_get_cpu_state
        ret=$?
        #if [ $ret -eq 0 ]; then
        #    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        #    echo "$time_stamp INFO: BMC get CPU state successful" >> /var/volatile/log/syslog; sync
        #else
        #    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
		#	echo "$time_stamp INFO: BMC get CPU state failed" >> /var/volatile/log/syslog; sync
        #fi
        exit $ret
        ;;
    #monitor)
    #    do_monitor_cpu_state
    #    ret=$?
    #    #if [ $ret -eq 0 ]; then
    #    #    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
    #    #    echo "$time_stamp INFO: BMC get CPU state successful" >> /var/volatile/log/syslog; sync
    #    #else
    #    #    time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
	#	#	echo "$time_stamp INFO: BMC get CPU state failed" >> /var/volatile/log/syslog; sync
    #    #fi
    #    exit $ret
    #    ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?



