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
exitCode=0
value=0

product_name=$(cat /etc/openbmc/product_name)


dump_cpld_version() {
    local cpld_dir=$1
    local cpld_name=$2
	retCode=0
	#echo "dump_cpld_version ${cpld_dir}:${cpld_name}"

	cpld_major_ver=`head -n 1 ${cpld_dir}/cpld_major_ver 2> /dev/null`
	if [ $? -ne 0 ]; then
		echo "${cpld_name} is not detected"
		exitCode=1
		retCode=1
	fi
	cpld_minor_ver=`head -n 1 ${cpld_dir}/cpld_minor_ver 2> /dev/null`
	if [ $? -ne 0 ]; then
		echo "${cpld_name} is not detected"
		exitCode=1
		retCode=1
	fi
	if [ "$retCode" -eq 0 ]; then 
      printf "%-18s%-s %02x.%02x\n" ${cpld_name} : $cpld_major_ver $cpld_minor_ver
	  #echo "${cpld_name}: $cpld_major_ver.$cpld_minor_ver"
	fi
}
dump_fancpld_version() {
    local cpld_dir=$1
    local cpld_name=$2
    local retCode=0
    #echo "dump_fancpld_version ${cpld_dir}:${cpld_name}"
    cpld_ver=`head -n 1 ${cpld_dir}/cpld_ver 2> /dev/null`
    if [ $? -ne 0 ]; then
        echo "${cpld_name} is not detected"
        exitCode=1
	retCode=1
    fi
    if [ "$retCode" -eq 0 ]; then 
      echo "${cpld_name}: $cpld_ver"
    fi
}

dump_portcpld_reg() {
	local portcpld_addr=$1
	local portcpld_name=$2
	local check_addr=$3

	reg_rd=$(printf "0x%x" $((($portcpld_addr)<<1)))
	reg_wr=$(printf "0x%x" $(((($portcpld_addr)<<1) + 1)))
	#echo "reg_rd: $reg_rd"
	#echo "reg_wr: $reg_wr"	
	if [ "${portcpld_name}" = "PORT1 CPLD" ];then
		addr_add=0x00
	else
		addr_add=0x20
	fi		
	#echo "addr_add : $addr_add"
	#echo "portcpld_name : ${portcpld_name}"
	#echo "check_addr : $check_addr"
	reg_1=$(printf "0x%x" $((0x80c + $addr_add)))
	reg_2=$(printf "0x%x" $((0x810 + $addr_add)))
	#echo "reg_1 : $reg_1"
	#echo "reg_2 : $reg_2"
	echo $reg_1 > ${SWITCHFPGA_SYSFS_DIR}/indirect_addr
	echo $reg_rd > ${SWITCHFPGA_SYSFS_DIR}/indirect_write
	echo $reg_2 > ${SWITCHFPGA_SYSFS_DIR}/indirect_addr
	echo 0x90 > ${SWITCHFPGA_SYSFS_DIR}/indirect_write
	echo $reg_1 > ${SWITCHFPGA_SYSFS_DIR}/indirect_addr
	echo $check_addr > ${SWITCHFPGA_SYSFS_DIR}/indirect_write
	echo $reg_2 > ${SWITCHFPGA_SYSFS_DIR}/indirect_addr
	echo 0x10 > ${SWITCHFPGA_SYSFS_DIR}/indirect_write
	echo $reg_1 > ${SWITCHFPGA_SYSFS_DIR}/indirect_addr
	echo $reg_wr > ${SWITCHFPGA_SYSFS_DIR}/indirect_write
	echo $reg_2 > ${SWITCHFPGA_SYSFS_DIR}/indirect_addr
	echo 0x90 > ${SWITCHFPGA_SYSFS_DIR}/indirect_write
	echo $reg_2 > ${SWITCHFPGA_SYSFS_DIR}/indirect_addr
	echo 0x68 > ${SWITCHFPGA_SYSFS_DIR}/indirect_write
	echo $reg_1 > ${SWITCHFPGA_SYSFS_DIR}/indirect_addr
	value=`head -n 1 ${SWITCHFPGA_SYSFS_DIR}/indirect_read 2> /dev/null`
	if [ $? -ne 0 ]; then
		echo "${portcpld_name} reg ${check_addr} err"
		exitCode=1
	fi
}
dump_portcpld_version() {
	local port1_major
	local port1_minor
	local port2_major
	local port2_minor
	dump_portcpld_reg 0x62 "PORT1 CPLD" 0x01
	port1_major=$value
	#port1_major=$(dump_portcpld_reg 0x62 "PORT1 CPLD" 0x01)
	usleep 30000
	dump_portcpld_reg 0x62 "PORT1 CPLD" 0x02
	port1_minor=$value
	#port1_minor=$(dump_portcpld_reg 0x62 "PORT1 CPLD" 0x02)	
	if [ "$exitCode" -eq 0 ];  then
		echo "PORT1 CPLD: $port1_major.$port1_minor"
	fi
	usleep 30000
	exitCode=0
	dump_portcpld_reg 0x64 "PORT2 CPLD" 0x01
	port2_major=$value
	#port2_major=$(dump_portcpld_reg 0x64 "PORT2 CPLD" 0x01)	
	usleep 30000
	dump_portcpld_reg 0x64 "PORT2 CPLD" 0x02
	port2_minor=$value
	#port2_minor=$(dump_portcpld_reg 0x64 "PORT2 CPLD" 0x02)
	if [ "$exitCode" -eq 0 ]; then
		echo "PORT2 CPLD: $port2_major.$port2_minor"
	fi
}
dump_cpld_version ${OCMCPLD_SYSFS_DIR} "OCM_CPLD"
usleep 50000
dump_cpld_version ${BASECPLD_SYSFS_DIR} "Base_CPLD"
usleep 50000
dump_cpld_version ${SWB_MISCCPLD_SYSFS_DIR} "MISC_CPLD"
usleep 50000
dump_cpld_version ${SWB_PORT1CPLD_SYSFS_DIR} "Port1_CPLD"
usleep 50000
dump_cpld_version ${SWB_PORT2CPLD_SYSFS_DIR} "Port2_CPLD"
usleep 50000
dump_cpld_version ${FAN1CPLD_SYSFS_DIR} "FAN1_CPLD"
usleep 5000
dump_cpld_version ${FAN2CPLD_SYSFS_DIR} "FAN2_CPLD"
usleep 5000
dump_cpld_version ${LED_CPLD_SYSFS_DIR} "LED_CPLD"
usleep 5000

# if [ $product_name != "AS74-64O-AT" ]; then
#     dump_cpld_version ${LINE_PORT3CPLD_SYSFS_DIR} "Line_CPLD"
#     usleep 50000
# fi

#all=$1
#if [ ! -z $all ] && [ $all = "all" ];then
#dump_portcpld_version
#usleep 50000
#fi

# dump_cpld_version ${FANCPLD_SYSFS_DIR} "FAN_CPLD"
# usleep 5000

#dump_cpld_version ${SMBCPLD_SYSFS_DIR} "SMBCPLD"
#usleep 50000
#
#
#
#dump_cpld_version ${BOTTOM_FCMCPLD_SYSFS_DIR} "Bottom FCMCPLD"
#usleep 50000
#
#board_rev=$(wedge_board_rev)
#if [ $board_rev -ne 4 ]; then
#    dump_cpld_version ${LEFT_PDBCPLD_SYSFS_DIR} "Left PDBCPLD"
#    usleep 50000
#
#    dump_cpld_version ${RIGHT_PDBCPLD_SYSFS_DIR} "Right PDBCPLD"
#fi

if [ "$exitCode" -ne 0 ]; then
  echo "Since all the CPLDs didn't succeed with the name listed above... exit."
  exit 1
fi
