#!/bin/bash
#
# Copyright 2018-present Facebook. All Rights Reserved.
#
# This program file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program in a file named COPYING; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA
#

. /usr/local/bin/openbmc-utils.sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

prog="$0"
#board_rev=$(board_rev)

PWR_CPU_RST_SYSFS="${BASECPLD_SYSFS_DIR}/cpu_reset"
PWR_CPU_UP_EN_SYSFS="${BASECPLD_SYSFS_DIR}/cpu_pwr_up_en"
PWR_CPU_OFF_EN_SYSFS="${BASECPLD_SYSFS_DIR}/cpu_force_pwr_off"

PWR_PSU_ON_CTRL_SYSFS="${BASECPLD_SYSFS_DIR}/psu_power_on" 
PWR_PSU1_ON_CTRL_SYSFS="${BASECPLD_SYSFS_DIR}/psu1_power_on" 
PWR_PSU2_ON_CTRL_SYSFS="${BASECPLD_SYSFS_DIR}/psu2_power_on" 
PWR_PSU3_ON_CTRL_SYSFS="${BASECPLD_SYSFS_DIR}/psu3_power_on" 
PWR_PSU4_ON_CTRL_SYSFS="${BASECPLD_SYSFS_DIR}/psu4_power_on" 

PWR_CYCLE_DELAY=10
PWR_OFF_DELAY=200    # wait sonic power off

usage() {
    echo "Usage: $prog <command> [command options]"
    echo
    echo "Commands:"
    echo "  status: Get the current microserver power status"
    echo
    echo "  on: Power on microserver if not powered on already"
    echo "    options:"
    echo "      -f: Re-do power on sequence no matter if microserver has "
    echo "          been powered on or not."
    echo
    echo "  off: Power off microserver ungracefully"
    echo "    options:"
    echo "      -f: force power off "
    echo
    echo "  reset: Power reset microserver ungracefully"
    echo
    echo "  cpu_pwr_cycle: Power cycle microserver ungracefully"
    echo
    echo "  sys_pwr_cycle: Power cycle system ungracefully"
    echo
}

main_power_status() {
    return 0
}

do_status() {
    #echo "TBD(ctrl-CPLD)"
    echo -n "Microserver power is "
    return_code=0

    if is_us_on; then
        echo "on"
    else
        echo "off"
        return_code=1
    fi

    return $return_code
}

do_on_ocm() {
	#i2cset -y -f 00 0x0d 0x10 0x95
	echo 1 > $PWR_CPU_UP_EN_SYSFS
	#usleep 100
    return $?
}

do_on_main_pwr() {
    # OCM main power is controlled by BASECPLD
    return 0
}

do_on() {
    local force opt ret
    force=0
    while getopts "f" opt; do
        case $opt in
            f)
                force=1
                ;;
            *)
                usage
                exit -1
                ;;
        esac
    done
    echo -n "Power on microserver ..."
#######################################################
     if [ $force -eq 0 ]; then
        ## need to check if uS is on or not
         if is_us_on; then
             echo " Already on. Skip!"
             return 2
         fi
     fi
#######################################################
    # power on sequence
    do_on_ocm
    ret=$?
    if [ $ret -eq 0 ]; then
        echo " Done"
	logger "Successfully power on micro-server"
    else
        echo " Failed"
        logger "Failed to power on micro-server"
    fi
    return $ret
}

do_off_ocm() {
	echo 0 > $PWR_CPU_OFF_EN_SYSFS
    return $?
}

do_off_ocm_f() {
    echo 0 > $PWR_CPU_OFF_EN_SYSFS
}

do_off() {
    local force opt ret
    force=0
    while getopts "f" opt; do
        case $opt in
            f)
                force=1
                ;;
            *)
                usage
                exit -1
                ;;
        esac
    done
    if [ $force -eq 0 ]; then
		local cnt=0
	    echo -n "Power off microserver ..."
	    if ! is_us_on ; then
	        echo " Already off. Skip!"
	        return 2
	    fi
	    do_off_ocm

	    while is_us_on
	    do
	        cnt=$((cnt+1))
	        sleep 1

	        if [ $cnt -ge $PWR_OFF_DELAY ]; then
	            echo " Failed"
	            return 1
	        fi
	    done

	    echo " Done"
	    return 0
    else
    	echo -n "Force power off microserver ..."
        do_off_ocm_f
   	    while is_us_on
	    do
	        cnt=$((cnt+1))
	        sleep 1
	        if [ $cnt -ge $PWR_OFF_DELAY ]; then
	            echo " Failed"
	            return 1
	        fi
	    done

        echo " Done"
        return 0
    fi
}

do_reset() {
    local system timer wake_t opt pulse_us
    system=0
    timer=0
    wake_t=0
    while getopts "st:" opt; do
        case $opt in
            s)
                system=1
                ;;
            # t)
                # timer=1
                # wake_t=$OPTARG
                # ;;
            *)
                usage
                exit -1
                ;;
        esac
    done

    if [ $system -eq 1 ]; then
        # if [ $timer -eq 1 ]; then
            # do_config_reset_timer $wake_t
        # fi
        logger "Power reset the whole system ..."
        echo  "Power reset the whole system ..."
        echo 0xf > $PWR_PSU_ON_CTRL_SYSFS
        # Control should not reach here, but if it failed to reset
        # the system through PSU, then run a workaround to reset
        # most of the system instead (if not all)
        logger "Failed to reset the system. Running a workaround"
        echo "Failed to reset the system. Running a workaround"
#        i2cset -f -y 1 0x3a 0x12 0
    else
        if ! is_us_on; then
            echo "Power resetting microserver that is powered off has no effect."
            echo "Use '$prog on' to power the microserver on"
            return -1
        fi
        echo -n "Power reset microserver ..."
        echo 0 > $PWR_CPU_RST_SYSFS
        logger "Successfully power reset micro-server"
    fi
    echo " Done"
    return 0
}

do_cpu_pwr_cycle() {
    do_off
    sleep $PWR_CYCLE_DELAY
    do_on
}

do_sys_pwr_cycle() {
    echo -n "Power cycle system ..."
    #The PSON can not be power down completely by CPLD
    #echo 0xf > $PWR_PSU_ON_CTRL_SYSFS
    #New Solution
    echo 0x48 > ${PSU1_MODLE_DIR}/psu_on_off_config
    echo 0x40 > ${PSU1_MODLE_DIR}/psu_operation
    echo 0x48 > ${PSU2_MODLE_DIR}/psu_on_off_config
    echo 0x40 > ${PSU2_MODLE_DIR}/psu_operation
    echo 0x48 > ${PSU3_MODLE_DIR}/psu_on_off_config
    echo 0x40 > ${PSU3_MODLE_DIR}/psu_operation
    echo 0x48 > ${PSU4_MODLE_DIR}/psu_on_off_config
    echo 0x40 > ${PSU4_MODLE_DIR}/psu_operation
    echo "Done"
}


if [ $# -lt 1 ]; then
    usage
    exit -1
fi

command="$1"
shift

case "$command" in
    status)
        do_status $@
        ;;
    on)
        do_on $@
        ret=$?
        if [ $ret -eq 2 ]; then
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp WARNING: BMC try to power on CPU, already on, skip" >> /var/volatile/log/syslog; sync
        elif [ $ret -eq 0 ]; then
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp WARNING: BMC power on CPU successful." >> /var/volatile/log/syslog; sync
        else
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp CRITICAL: BMC failed to power on CPU ." >> /var/volatile/log/syslog; sync
        fi
        exit $ret
        ;;
    off)
        do_off $@
        ret=$?
        if [ $ret -eq 2 ]; then
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp WARNING: BMC try to power off CPU, already off, skip" >> /var/volatile/log/syslog; sync
        elif [ $ret -eq 0 ]; then
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp WARNING: BMC power off CPU successful" >> /var/volatile/log/syslog; sync
        else
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp CRITICAL: BMC failed to power off CPU ." >> /var/volatile/log/syslog; sync
        fi
        exit $ret
        ;;
    reset)
        do_reset $@
        ret=$?
        if [ $ret -eq 0 ]; then
            time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "$time_stamp WARNING: BMC reset CPU successful." >> /var/volatile/log/syslog; sync
        else
            echo "$time_stamp WARNING: BMC failed to reset CPU, maybe CPU is already off." >> /var/volatile/log/syslog; sync
        fi
        ;;
    cpu_pwr_cycle)
        do_cpu_pwr_cycle $@
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "$time_stamp WARNING: BMC power cycle CPU" >> /var/volatile/log/syslog; sync
        ;;
    sys_pwr_cycle)
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "$time_stamp WARNING: BMC power cycle SYSTEM by turning off/on PSU" >> /var/volatile/log/syslog; sync
        do_sys_pwr_cycle $@
        ;;
    # pimreset)
        # do_pimreset $@
        # exit $?
        # ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
