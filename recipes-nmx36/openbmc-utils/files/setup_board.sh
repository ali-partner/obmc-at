#!/bin/sh
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

### BEGIN INIT INFO
# Provides:          setup_board.sh
# Required-Start:
# Required-Stop:
# Default-Start:     S
# Default-Stop:
# Short-Description: Setup the board
### END INIT INFO

. /usr/local/bin/openbmc-utils.sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

# In case gadget driver is compiled as module
#modprobe ast-udc
modprobe g_cdc host_addr=02:00:00:00:00:02 dev_addr=02:00:00:00:00:01
# For g-ether interface, if the remote side brings down the interface, BMC side
# still treats it as up. In this case, all packets through usb0 (i.e. NDP) will
# be queued in the kernel for this interface. Ether interface has the default
# TX queue length as 1000, which means there could be up to 1000 package queued
# in kernel for that. In our case, kmalloc-192 is exhausted when 298 packets
# are queued.
# To solve this issue, we change the TX queue length for usb0 to 64 to avoid
# memory exhaust.
ifconfig usb0 txqueuelen 64

# Set usb0 static MAC
echo "Set usb0 static MAC..."
# ifconfig usb0 down
# ifconfig usb0 hw ether 02:00:00:00:00:01
# ifconfig usb0 199.168.1.1 netmask 255.255.255.0
# ifconfig usb0 fe80::1/64 up
ip link set usb0 down
ip link set dev usb0 address 02:00:00:00:00:01
ip addr add 199.168.1.1/24 dev usb0
# ip addr add fe80::1/64 dev usb0
ip addr add fe80::ff:fe00:1/64 dev usb0
ip link set usb0 up

#board_rev=$(wedge_board_rev)



