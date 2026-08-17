#!/bin/bash

PROGRAM_TITLE=`basename $0`

usage() {
    echo "Usage: $PROGRAM_TITLE [String]"
    echo ""
    echo "Examples:"
    echo "   $PROGRAM_TITLE "String"         #Search "string" info."
    echo "   -h: display this help and exit."
}
# Start of the script.
if [ $# -ne 1 ]; then
    usage
    exit -1
fi

check_syslog(){
	str_info=$str
	echo "To search syslog \"${str_info}\"."
	status_num=`cat /var/volatile/log/syslog | grep "${str_info}" | wc -l`
	if [ $status_num -ge 1 ]; then
		echo "\"${str_info}\" to be searched $status_num time/times"
		echo "There are abnormal records in BMC OS syslog"
		echo "The BMC OS system exception"
		echo "LOG as follows:"
		cat /var/volatile/log/syslog | grep "${str_info}"
		exit -1
	fi
	echo "There are normal records in BMC OS syslog"
	echo "The BMC OS system normal"
	exit 0
}

check_str1=$1
check_str2=$2
check_str3=$3
check_str4=$4
check_str5=$5

if [ "$1" == "-h" ]; then
	usage
	exit -1
else
	if [ -n "$check_str5" ]; then
		str="$check_str1 $check_str2 $check_str3 $check_str4 $check_str5"
	fi
	if [ -n "$check_str4" ]; then
		str="$check_str1 $check_str2 $check_str3 $check_str4"
	fi
	if [ -n "$check_str3" ]; then
		str="$check_str1 $check_str2 $check_str3"
	fi
	if [ -n "$check_str2" ]; then
		str="$check_str1 $check_str2"
	fi
	if [ -n "$check_str1" ]; then
		str="$check_str1"
	fi
	#echo $str
	check_syslog $str
fi

exit 0
