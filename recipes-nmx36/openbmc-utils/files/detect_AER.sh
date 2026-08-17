#!/bin/bash
. /usr/local/bin/openbmc-utils.sh

times_err0=0
times_err1=0
times_err2=0

AERR_LOG_CNT=4

while :
do
    AER_ERR0=`cat /tmp/gpionames/FM_CPU_ERR0_LVT3_N/value`
    AER_ERR1=`cat /tmp/gpionames/FM_CPU_ERR1_LVT3_N/value`
    AER_ERR2=`cat /tmp/gpionames/FM_CPU_ERR2_LVT3_N/value`

    if [[ $AER_ERR0_last -eq 1 ]] && [[ $AER_ERR0 -eq 0 ]]; then
        # Check CPU/PCH is power on first
        val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
        if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
            let times_err0=times_err0+1
            if [ $times_err0 -eq $AERR_LOG_CNT ]; then
                times_err0=1
            fi

            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp ERROR: ERR[0] asserted, CPU hardware correctable error detected." >> /var/volatile/log/syslog
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

            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp CRITICAL: ERR[1] asserted, Non-fatal error detected." >> /var/volatile/log/syslog
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

            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp FATAL: ERR[2] asserted, Fatal error detected." >> /var/volatile/log/syslog
            /usr/local/bin/dump_AER.sh > /var/volatile/log/dump_ERR2_$times_err2
            sync
        fi
    fi

    AER_ERR0_last=$AER_ERR0
    AER_ERR1_last=$AER_ERR1
    AER_ERR2_last=$AER_ERR2

    sleep 1
done
