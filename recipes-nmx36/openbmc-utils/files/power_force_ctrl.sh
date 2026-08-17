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

FORCE_CTRL_NODE=${BASECPLD_SYSFS_DIR}/power_force_ctrl_en
prog="$0"
force=0
usage() {
    echo "Usage: $prog <port/switch/ssd> <command> [command options]"
    echo "Usage: $prog <enable/disable/status>"
    echo
    echo "Commands:"
    echo "  status: Get the current power status"
    echo
    echo "  on: Power on if force control status is enable"
    echo "    options:"
    echo "      -f: Enable force control and power on"
    echo
    echo "  off: Power off if force control status is enable"
    echo "    options:"
    echo "      -f: Enable force control and power off"
    echo
    echo "  cycle: Power cycle if force control status is enable"
    echo "    options:"
    echo "      -f: Enable force control and power cycle"
    echo
    echo "enable: Enable port switch and ssd force control"
    echo
    echo "disable: Disable Enable port switch and ssd force control"
    echo
    echo "status: Get the current force control status"
    echo
}

do_get_force_status()
{
    force_status_s=`cat ${FORCE_CTRL_NODE}`
    force_status=${force_status_s:0:4}
    if [[ "$force_status" == "0x4e" ]]; then
        echo "force control status: Disable"
    elif [[ "$force_status" == "0x59" ]]; then
        echo "force control status: Enable"
    else
        echo "force control status: N/A"
    fi
}

do_force_ctrl_enable()
{
    echo 0x59 > ${FORCE_CTRL_NODE}
}

do_force_ctrl_disable()
{
    echo 0x4e > ${FORCE_CTRL_NODE}
}

do_get_status()
{
    obj=$1
    node=${BASECPLD_SYSFS_DIR}/${obj}_power_force_ctrl
    power_status_s=`cat ${node}`
    power_status=${power_status_s:0:3}
    if [[ "$power_status" == "0x0" ]]; then
        echo "$obj power status: OFF"
    elif [[ "$power_status" == "0x1" ]]; then
        echo "$obj power status: ON"
    else
        echo "$obj power status: N/A"
    fi
}

do_log()
{
    cmd=$1
    obj=$2
    return_code=$3 
    if [ $return_code -eq 1 ]; then
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "BMC force to power $cmd $obj"
        echo "$time_stamp WARNING: BMC force to power $cmd $obj" >> /var/volatile/log/syslog; sync
    elif [ $return_code -eq 3 ]; then
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "force control status is enable, BMC power $cmd $obj."
        echo "$time_stamp WARNING: force control status is enable, BMC power $cmd $obj." >> /var/volatile/log/syslog; sync
     elif [ $return_code -eq 2 ]; then
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "force control status is disable, BMC failed to power $cmd $obj."
        echo "$time_stamp WARNING: force control status is disable, BMC failed to power $cmd $obj." >> /var/volatile/log/syslog; sync
    else
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "BMC failed to power $cmd $obj."
        echo "$time_stamp CRITICAL: BMC failed to power $cmd $obj." >> /var/volatile/log/syslog; sync
    fi
}


do_power_on()
{
    obj=$1
    return_code=0
    node=${BASECPLD_SYSFS_DIR}/${obj}_power_force_ctrl
    if [[ $force -eq 1 ]]; then
        do_force_ctrl_enable
        echo 0x1 > ${node}
        return_code=1
    else
        force_status_s=`cat ${FORCE_CTRL_NODE}`
        force_status=${force_status_s:0:4}
        if [[ "$force_status" == "0x4e" ]]; then
            return_code=2
        elif [[ "$force_status" == "0x59" ]]; then
            echo 0x1 > ${node}
            return_code=3
        fi
    fi
    do_log on $obj $return_code
}

do_power_off()
{
    obj=$1
    return_code=0
    node=${BASECPLD_SYSFS_DIR}/${obj}_power_force_ctrl
    if [[ $force -eq 1 ]]; then
        do_force_ctrl_enable
        echo 0x0 > ${node}
        return_code=1
    else
        force_status_s=`cat ${FORCE_CTRL_NODE}`
        force_status=${force_status_s:0:4}
        if [[ "$force_status" == "0x4e" ]]; then
            return_code=2
        elif [[ "$force_status" == "0x59" ]]; then
            echo 0x0 > ${node}
            return_code=3
        fi
    fi
    do_log off $obj $return_code
}

do_power_cycle()
{
    obj=$1
    return_code=0
    node=${BASECPLD_SYSFS_DIR}/${obj}_power_force_ctrl
    if [[ $force -eq 1 ]]; then
        do_force_ctrl_enable
        echo 0x0 > ${node}
        sleep 1
        echo 0x1 > ${node}
        return_code=1
    else
        force_status_s=`cat ${FORCE_CTRL_NODE}`
        force_status=${force_status_s:0:4}
        if [[ "$force_status" == "0x4e" ]]; then
            return_code=2
        elif [[ "$force_status" == "0x59" ]]; then
            echo 0x0 > ${node}
            sleep 1
            echo 0x1 > ${node}
            return_code=3
        fi
    fi
    do_log cycle $obj $return_code
}

if [ $# -lt 1 ]; then
    usage
    exit -1
fi

obj="$1"
command="$2"
opt="$3"
if [[ $opt == "-f" ]]; then
    force=1
fi

case "$obj" in
    enable)
        do_force_ctrl_enable
        ;;
    disable)
        do_force_ctrl_disable
        ;;
    status)
        do_get_force_status
        ;;
    switch|port|ssd)
        case "$command" in
            status)
                do_get_status $obj
                ;;
            on)
                do_power_on $obj
                ;;
            off)
                do_power_off $obj
                ;;
            cycle)
                do_power_cycle $obj
                ;;
            *)
                usage
                exit -1
                ;;
        esac
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
