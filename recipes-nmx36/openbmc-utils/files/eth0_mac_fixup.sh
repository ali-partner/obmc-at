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

### BEGIN INIT INFO
# Provides:          eth0_mac_fixup.sh
# Required-Start:
# Required-Stop:
# Default-Start:     S
# Default-Stop:
# Short-Description:  Fixup the MAC address for eth0 based on SYS FRU EEPROM
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin


# get the base MAC from SYS FRU EEPROM
base_mac=$(fruid-util base 2>/dev/null | grep 'Product Custom Data 2' 2>/dev/null | cut -d' ' -f10 2>/dev/null)
tmp=$((16#$base_mac+0x01))
mac=`printf "%012x" $tmp`

# get the MAC from u-boot environment
ethaddr=$(fw_printenv ethaddr 2>/dev/null | cut -d'=' -f2 2>/dev/null)

if [ -z "$mac" ] && [ -n "$ethaddr" ]; then
    # no MAC from EEPROM, use the one from u-boot environment
    mac="$ethaddr"
fi
echo "mac:$mac"
if [ -n "$mac" ]; then
    echo "To set MAC ..."
    # ifconfig eth0 down
    ip link set eth0 down
    sleep 1
    # ifconfig eth0 hw ether $mac
    ip link set eth0 address "${mac:0:2}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
    sleep 1
    # ifconfig eth0 up
    ip link set eth0 up
else
    # no MAC from either EEPROM or u-boot environment
    mac=$(ifconfig eth0 2>/dev/null |grep HWaddr 2>/dev/null |awk '{ print $5 }')

fi

if [ "$ethaddr" != "$mac" ]; then
    # set the MAC from EEPROM or ifconfig back to u-boot environment so that u-boot
    # can use it
    fw_setenv "ethaddr" "$mac"
fi
