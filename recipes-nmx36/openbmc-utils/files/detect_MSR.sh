#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

MCERR_FLAG="/var/tmp/mcerr_flag"
IERR_FLAG="/var/tmp/ierr_flag"

MCERR_counts_FLAG="/var/volatile/log/MCERR_cnt"
IERR_counts_FLAG="/var/volatile/log/IERR_cnt"

#Check if cpld can detect MCERR/IERR.
MSR_NASK_GET_CMD=`/usr/sbin/i2cget -f -y 0 0x0d 0x4B`
if [ $MSR_NASK_GET_CMD != "0x00" ]; then
	echo "CPLD need set MCERR IERR MASK"
	MSR_NASK_SET_CMD=`/usr/sbin/i2cset -f -y 0 0x0d 0x4B 0x00`
fi
echo 0 > $MCERR_FLAG
echo 0 > $IERR_FLAG

set_err_flag() {

    if [ ! -f $MCERR_counts_FLAG ]; then
        echo 0 > $MCERR_counts_FLAG
    fi
    if [ ! -f $IERR_counts_FLAG ]; then
        echo 0 > $IERR_counts_FLAG
    fi

    # Pass through interrupt, donot mask.
    /usr/sbin/i2cset -f -y 0 0x0d 0x4B 0x00

    while :
    do
        MCERR_count=`cat $MCERR_counts_FLAG`
        IERR_count=`cat $IERR_counts_FLAG`

        MSR_CMD=`/usr/sbin/i2cget -f -y 0 0x0d 0x4A`
        bit0_msr=$(($MSR_CMD & 0x1))
        bit1_msr=$(($MSR_CMD & 0x2))
        if [ $bit0_msr -eq 0 ]; then
            # write clear 0x4A bit 0
            /usr/sbin/i2cset -f -y 0 0x0d 0x4A 0x3

            # Check CPU/PCH is power on first
            val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
            if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp FATAL: CPU MCERR detected." >> /var/volatile/log/syslog

                let MCERR_count=MCERR_count+1
                echo $MCERR_count > $MCERR_counts_FLAG

                flock -x $MCERR_FLAG -c "echo 1 > $MCERR_FLAG"
            fi
        fi

        if [ $bit1_msr -eq 0 ]; then
            # write clear 0x4A bit 1
            /usr/sbin/i2cset -f -y 0 0x0d 0x4A 0x03

            # Check CPU/PCH is power on first
            val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
            if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
                time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$time_stamp FATAL: CPU IERR detected." >> /var/volatile/log/syslog

                let IERR_count=IERR_count+1
                echo $IERR_count > $IERR_counts_FLAG

                flock -x $IERR_FLAG -c "echo 1 > $IERR_FLAG"
            fi
        fi

        sleep 1
    done
}

times_MCERR=0
times_IERR=0
MCERR_LOG_CNT=4
IERR_LOG_CNT=4

dump_msr() {
    while :
    do
        if [ -f $MCERR_FLAG ]; then
            flock -x $MCERR_FLAG -c "cat $MCERR_FLAG > /var/tmp/mcerr"
            mcerr=`cat /var/tmp/mcerr`

            if [ $mcerr -eq 1 ] ; then
                flock -x $MCERR_FLAG -c "echo 0 > $MCERR_FLAG"
                let times_MCERR=times_MCERR+1
                if [ $times_MCERR -eq $MCERR_LOG_CNT ]; then
                    times_MCERR=1
                fi
                /usr/local/bin/dump_MSR.sh > /var/volatile/log/dump_MCERR_$times_MCERR
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
                /usr/local/bin/dump_MSR.sh > /var/volatile/log/dump_IERR_$times_IERR
                sync
            fi
        fi

        sleep 1
    done
}

set_err_flag &
dump_msr &
