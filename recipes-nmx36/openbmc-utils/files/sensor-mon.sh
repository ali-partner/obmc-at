#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

times_err0=0
times_err1=0
times_err2=0
AER_ERR0_last=0
AER_ERR1_last=0
AER_ERR2_last=0
AERR_LOG_CNT=4

#ERRORO_N - Correctable Error
#ERROR1_N - Non-Fatal Error
#ERROR2_N - Fatal Error
CPU_ERR0_COUNT="/var/volatile/log/CPU_ERR0_cnt"
CPU_ERR1_COUNT="/var/volatile/log/CPU_ERR1_cnt"
CPU_ERR2_COUNT="/var/volatile/log/CPU_ERR2_cnt"

do_aer_monitor() {
    AER_ERR0=`cat /tmp/gpionames/FM_CPU_ERR0_LVT3_N/value`
    AER_ERR1=`cat /tmp/gpionames/FM_CPU_ERR1_LVT3_N/value`
    AER_ERR2=`cat /tmp/gpionames/FM_CPU_ERR2_LVT3_N/value`

    if [ ! -f $CPU_ERR0_COUNT ]; then
        echo 0 > $CPU_ERR0_COUNT
    fi
    if [ ! -f $CPU_ERR1_COUNT ]; then
        echo 0 > $CPU_ERR1_COUNT
    fi
    if [ ! -f $CPU_ERR2_COUNT ]; then
        echo 0 > $CPU_ERR2_COUNT
    fi
    CPU_ERR0_count=`cat $CPU_ERR0_COUNT`
    CPU_ERR1_count=`cat $CPU_ERR1_COUNT`
    CPU_ERR2_count=`cat $CPU_ERR2_COUNT`

    if [[ $AER_ERR0_last -eq 1 ]] && [[ $AER_ERR0 -eq 0 ]]; then
        # Check CPU/PCH is power on first
        val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
        if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
            let times_err0=times_err0+1
            if [ $times_err0 -eq $AERR_LOG_CNT ]; then
                times_err0=1
            fi
            let CPU_ERR0_count=CPU_ERR0_count+1
            echo $CPU_ERR0_count > $CPU_ERR0_COUNT
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp BMC ERROR: ERR[0] asserted, CPU hardware correctable error detected." >> /var/volatile/log/syslog
            /usr/local/bin/dump_AER.sh > /var/volatile/log/dump_ERR0_$times_err0
            sync
        fi
    fi

    if [[ $AER_ERR1_last -eq 1 ]] && [[ $AER_ERR1 -eq 0 ]]; then
        # Check CPU/PCH is power on first
        val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
        if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
            let times_err1=times_err1+1
            if [ $times_err1 -eq $AERR_LOG_CNT ]; then
                times_err1=1
            fi
            let CPU_ERR1_count=CPU_ERR1_count+1
            echo $CPU_ERR1_count > $CPU_ERR1_COUNT
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp BMC CRITICAL: ERR[1] asserted, Non-fatal error detected." >> /var/volatile/log/syslog
            /usr/local/bin/dump_AER.sh > /var/volatile/log/dump_ERR1_$times_err1
            sync
        fi
    fi

    if [[ $AER_ERR2_last -eq 1 ]] && [[ $AER_ERR2 -eq 0 ]]; then
        # Check CPU/PCH is power on first
        val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
        if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
            let times_err2=times_err2+1
            if [ $times_err2 -eq $AERR_LOG_CNT ]; then
                times_err2=1
            fi
            let CPU_ERR2_count=CPU_ERR2_count+1
            echo $CPU_ERR2_count > $CPU_ERR2_COUNT
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp BMC FATAL: ERR[2] asserted, Fatal error detected." >> /var/volatile/log/syslog
            /usr/local/bin/dump_AER.sh > /var/volatile/log/dump_ERR2_$times_err2
            sync
        fi
    fi

    AER_ERR0_last=$AER_ERR0
    AER_ERR1_last=$AER_ERR1
    AER_ERR2_last=$AER_ERR2

    sleep 1
}

MCERR_FLAG="/var/tmp/mcerr_flag"
IERR_FLAG="/var/tmp/ierr_flag"

MCERR_counts_FLAG="/var/volatile/log/MCERR_cnt"
IERR_counts_FLAG="/var/volatile/log/IERR_cnt"

set_err_flag() {
	MCERR_count=`cat $MCERR_counts_FLAG`
	IERR_count=`cat $IERR_counts_FLAG`

	MSR_CMD=`/usr/sbin/i2cget -f -y 0 0x0d 0x4A`
        #[bit1] MCERR_r/[bit0] IERR_r
	bit0_msr=$(($MSR_CMD & 0x1))
	bit1_msr=$(($MSR_CMD & 0x2))
	if [ $bit1_msr -eq 0 ]; then
		# write clear 0x4A bit 0
		/usr/sbin/i2cset -f -y 0 0x0d 0x4A 0x3

		# Check CPU/PCH is power on first
		val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
		if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
			time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
			echo "$time_stamp BMC FATAL: CPU MCERR detected, CPU_CARD_STA(${val}),MCERR_IERR_LATCH(${MSR_CMD})." >> /var/volatile/log/syslog

			let MCERR_count=MCERR_count+1
			echo $MCERR_count > $MCERR_counts_FLAG

			flock -x $MCERR_FLAG -c "echo 1 > $MCERR_FLAG"
		fi
	fi

	if [ $bit0_msr -eq 0 ]; then
		# write clear 0x4A bit 1
		/usr/sbin/i2cset -f -y 0 0x0d 0x4A 0x03

		# Check CPU/PCH is power on first
		val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
		if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
			time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
			echo "$time_stamp BMC FATAL: CPU IERR detected, CPU_CARD_STA(${val}),MCERR_IERR_LATCH(${MSR_CMD})." >> /var/volatile/log/syslog

			let IERR_count=IERR_count+1
			echo $IERR_count > $IERR_counts_FLAG

			flock -x $IERR_FLAG -c "echo 1 > $IERR_FLAG"
		fi
	fi

	sleep 1
}

times_MCERR=0
times_IERR=0
MCERR_LOG_CNT=4
IERR_LOG_CNT=4

dump_msr() {
	if [ -f $MCERR_FLAG ]; then
		flock -x $MCERR_FLAG -c "cat $MCERR_FLAG > /var/tmp/mcerr"
		mcerr=`cat /var/tmp/mcerr`
		if [ $mcerr -eq 1 ] ; then
			flock -x $MCERR_FLAG -c "echo 0 > $MCERR_FLAG"
			let times_MCERR=times_MCERR+1
			if [ $times_MCERR -eq $MCERR_LOG_CNT ]; then
				times_MCERR=1
			fi
			/usr/local/bin/dump_MSR.sh > /var/volatile/log/dump_msr_file
			/usr/local/bin/peci-util --file /var/volatile/log/dump_msr_file > /var/volatile/log/dump_MCERR_$times_MCERR
			/usr/local/bin/dump_MSR_reg.sh >> /var/volatile/log/dump_MCERR_$times_MCERR
			sync
		fi
	fi

	if [ -f $IERR_FLAG ]; then
		flock -x $IERR_FLAG -c "cat $IERR_FLAG > /var/tmp/ierr"
		ierr=`cat /var/tmp/ierr`
		if [ $ierr -eq 1 ]; then
			flock -x $IERR_FLAG -c "echo 0 > $IERR_FLAG"
			let times_IERR=times_IERR+1
			if [ $times_IERR -eq $IERR_LOG_CNT ]; then
				times_IERR=1
			fi
			/usr/local/bin/dump_MSR.sh > /var/volatile/log/dump_msr_file
			/usr/local/bin/peci-util --file /var/volatile/log/dump_msr_file > /var/volatile/log/dump_IERR_$times_IERR
			/usr/local/bin/dump_MSR_reg.sh >> /var/volatile/log/dump_IERR_$times_IERR
			sync
		fi
	fi
}

do_msr_monitor() {
    #Check if cpld can detect MCERR/IERR.
    MSR_NASK_GET_CMD=`/usr/sbin/i2cget -f -y 0 0x0d 0x4B`
    if [ $MSR_NASK_GET_CMD != "0x00" ]; then
        echo "CPLD need to set MCERR IERR MASK"
        # Pass through interrupt, donot mask.
        MSR_NASK_SET_CMD=`/usr/sbin/i2cset -f -y 0 0x0d 0x4B 0x00`
    fi
    if [ ! -f $MCERR_FLAG ]; then
        echo 0 > $MCERR_FLAG
    fi
    if [ ! -f $IERR_FLAG ]; then
        echo 0 > $IERR_FLAG
    fi
    if [ ! -f $MCERR_counts_FLAG ]; then
        echo 0 > $MCERR_counts_FLAG
    fi
    if [ ! -f $IERR_counts_FLAG ]; then
        echo 0 > $IERR_counts_FLAG
    fi
    set_err_flag
    dump_msr
    sleep 1
}

echo -n "Start monitoring CPU MCA/AER... "
do_monitor_init() {

	echo 0 > $MCERR_counts_FLAG
	time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$time_stamp BMC INFO: Clear MCERR_cnt Done." >> /var/volatile/log/syslog

	echo 0 > $IERR_counts_FLAG
	time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$time_stamp BMC INFO: Clear IERR_cnt Done." >> /var/volatile/log/syslog

	echo 0 > $CPU_ERR0_COUNT
	time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$time_stamp BMC INFO: Clear CPU_ERR0_cnt Done." >> /var/volatile/log/syslog

	echo 0 > $CPU_ERR1_COUNT
	time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$time_stamp BMC INFO: Clear CPU_ERR1_cnt Done." >> /var/volatile/log/syslog

	echo 0 > $CPU_ERR2_COUNT
	time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$time_stamp BMC INFO: Clear CPU_ERR2_cnt Done." >> /var/volatile/log/syslog

}

do_monitor_init

while true; do
    #AER ERR monitor
    do_aer_monitor
    #MSR ERR monitor
    do_msr_monitor
    sleep 1
done
