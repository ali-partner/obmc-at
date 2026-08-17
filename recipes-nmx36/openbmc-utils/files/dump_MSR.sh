#!/bin/bash
# echo out > /tmp/gpionames/PECI_SEL_BMC_ANA/direction
# echo 1 > /tmp/gpionames/PECI_SEL_BMC_ANA/value
# This file is to gerenrate the crash_dump file for peci-util.
# dump_MSR.sh > dump_file ;  peci-util --file dump_file
CPU_ID=0x30

BANK_NAME=("CTL" "STATUS" "ADDR" "MISC" "CTL2")
# BANK MODULE NAMES
CTL=0
STATUS=1
ADDR=2
MISC=3
CTL2=4
MAX_BANK_MODULE=5

CPU_NUM=1

for (( i=0;i<$CPU_NUM;i++ ))
do
    echo "echo 'CPU$i COREID DUMP:'"
    echo "echo '==============='"
    echo "echo"

    echo "echo '< CPUID READ >'"
    echo "${CPU_ID} 0x05 0x05 0xa1 0x00 0x00 0x00 0x00"

    echo "echo '< CPU Microcode Update Revision Read>'"
    echo "${CPU_ID} 0x05 0x05 0xa1 0x00 0x00 0x04 0x00"

    echo "echo '< MCA ERROR SOURCE LOG Read -- The socket which MCA_ERR_SRC_LOG[30]=0 is the socket that asserted IERR first >'"
    echo "${CPU_ID} 0x05 0x05 0xa1 0x00 0x00 0x05 0x00"

    echo "echo '********************************************************'"
    echo "echo '*                   IERRLOGGINGREG                     *'"
    echo "echo '********************************************************'"
    echo "${CPU_ID} 0x06 0x05 0x61 0x00 0xa4 0x00 0xe0 0x0f"

    echo "echo '********************************************************'"
    echo "echo '*                   MCERRLOGGINGREG                    *'"
    echo "echo '********************************************************'"
    echo "${CPU_ID} 0x06 0x05 0x61 0x00 0xa8 0x00 0xe0 0x0f"

    num_core=`/usr/local/bin/peci-util ${CPU_ID} 0x05 0x05 0xa1 0x00 0x00 0x03 0x00`

    ret=`echo $num_core | awk '{print $1}'`
    if [ $ret == "40" ];then
        num_core=`echo $num_core | awk '{print $2}'`
        num_core=$((16#`echo $num_core`))
    else
        echo "PECI fail! Maybe PECI_SEL_BMC_ANA is HIGH ?"
        exit -1
    fi


    echo "echo"
    echo "echo 'MSR DUMP CPU$i:'"
    echo "echo '========='"
    echo "echo num_core=${num_core}"
    #num_core_h=`printf '0x%x' $num_core`
    #echo "echo num_core_h=${num_core_h}"

    ##################
    #0 É¾³ýCPU_ID[$i]
    #1 CoreIdx 0~0x13 °üÀ¨0x13
    #2 É¾³ý MISC2=4 MCG_STATUS=5 -> MAX_BANK_MODULE=5
    #3 MCx_CTL2   0x280 + x    "$(($j*4 + 128)) 0x02"
    #  MCx_CTL    0x400 + x*4  "$(($j*4 + 0)) 0x04"
    #  MCx_STATUS 0x401 + x*4  "$(($j*4 + 01)) 0x04"
    #  MCx_ADDR   0x402 + x*4  "$(($j*4 + 02)) 0x04"
    #  MCx_MISC   0x403 + x*4  "$(($j*4 + 03)) 0x04"
    #4 BANK 5 7 8 19 Ìø¹ý
    ##################


    for ((j=0;j<20;j++))
    do
        jj=$(printf "%02d" $j)
        echo "echo '********************************************************'"
        echo "echo '*                    MC index $jj                       *'"
        echo "echo '********************************************************'"

        for ((m=$CTL;m<$MAX_BANK_MODULE;m++))
        do
            echo "echo"
            echo "echo '<<< IA32_MC${j}_${BANK_NAME[$m]}, ProcessorID from 0 to $num_core >>>'"
            for (( CoreIdx=0; CoreIdx<=$num_core; CoreIdx++))
            do
                if [ $m -eq $CTL2 ]; then
                    cmd_1byte="$(($j+128))"
                    cmd_2byte=0x02
                else
                    cmd_1byte="$(($j*4 + $m))"
                    cmd_2byte=0x04
                fi
                CoreIdx_h=`printf '0x%x' $CoreIdx`
                cmd_1byte_h=`printf '0x%x' $cmd_1byte`
                echo "${CPU_ID} 0x05 0x09 0xb1 0x00 $CoreIdx_h $cmd_1byte_h $cmd_2byte"
            done
        done
    done
done

