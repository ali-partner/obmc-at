#!/bin/bash


SCRATCH_FILE="/tmp/scratch_file"


trap cleanup INT TERM QUIT EXIT
cleanup(){
    rm -rf $SCRATCH_FILE
}

usage() {
    echo "Usage: $0"
    echo
}


if [[ $# -ne 0 ]]; then
    usage
    exit -1
fi

Diag_batt.sh cpld >> $SCRATCH_FILE
Diag_batt.sh bmc >> $SCRATCH_FILE
cat $SCRATCH_FILE 
ret1=`cat $SCRATCH_FILE | grep "The RTC battery vol state by cpld : normal"`
ret2=`cat $SCRATCH_FILE | grep "RTC test Pass"`
if [[ "$ret1" != "" && "$ret2" != "" ]]; then
    echo "RTC test: PASS"
fi
