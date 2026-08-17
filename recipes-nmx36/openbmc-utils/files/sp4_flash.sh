#!/bin/bash

. /usr/local/bin/openbmc-utils.sh
#32M = 32 * 1024 * 1024 Byte
MAX_BYTE=33554432
MAX_BIT=$((($MAX_BYTE)*8))
READ_MAX_BIT=16384
prog="$0"

usage() {
    echo "Usage: $prog <command>"
    echo
    echo "Commands:"
    echo "  erase: Erase SP4 MAC's flash."
    echo
    echo "  read: Read SP4 MAC's flash to bin file."
    echo
    echo "  write: Write bin file to SP4 MAC's flash."
    echo
    echo "  readid: Read SP4 MAC's flash id ."
    echo
}

flash_wr() {
    local tmp_file;local i; local j; local cnt=0
    wr_file=$2

    tmp_file="/var/log/tmp_file"

    echo -n "Preparing data file ..."
    #/usr/bin/hexdump -C -v $wr_file > $tmp_file
    #sed -i "s/[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f] //g" $tmp_file
    #sed -i "s/|.*|//g" $tmp_file
    #sed -i "s/  / /g" $tmp_file
    #sed -i '$d' $tmp_file
    #sed -i 's/[ \t]*$//g' $tmp_file
    #sed -i "s/ / 0x/g" $tmp_file
    echo "done."

    #Enable bmc update MAC channel
    echo 1 > ${BASECPLD_SYSFS_DIR}/bmc_mac_spi_sel; sync

    echo -n "Writing MAC's flash ..."
    line_max=`cat $tmp_file | wc -l`
    i=0
    j=0
    k=0
	n=0
	cnt_sum=0
	# WREN (write enable) 0x06 set Write Enable
	spi-bb -s 650 -S low -c 645 -C low -o 646 -O rising -i 647 -I falling -w 8 0x06 > /dev/null 2>&1
	/usr/bin/fpgaupdate-spi $wr_file

#    while read LINE
#    do
#		cnt=`echo $LINE | grep -o 0x | wc -l`
#		value[$n]=$LINE
#		cnt_sum=$cnt+$cnt_sum
#		let n=n+1
#		let i=i+1
#        if [[ ${n} -eq 16 || ${n} -eq ${line_max} ]]; then 
#		    n=0
#		    #write data + write command(1Byte)+ Address(3Byte)
#            cnt_sum=$((($cnt_sum+4)*8))
#            #/home/root/spi-bb -s 125 -S low -c 105 -C low -o 107 -O rising -i 106 -I falling -w $cnt_sum 0x02 $k $j 00 ${value[0]} ${value[1]} ${value[2]} ${value[3]} ${value[4]} ${value[5]} ${value[6]} ${value[7]} ${value[8]} ${value[9]} ${value[10]} ${value[11]} ${value[12]} ${value[13]} ${value[14]} ${value[15]} > /dev/null 2>&1
#			let j=j+1
#			#echo "spi-bb -s 125 -S low -c 105 -C low -o 107 -O rising -i 106 -I falling -w $cnt_sum 0x02 $k $j 00 ${value[0]} ${value[1]} ${value[2]} ${value[3]} ${value[4]} ${value[5]} ${value[6]} ${value[7]} ${value[8]} ${value[9]} ${value[10]} ${value[11]} ${value[12]} ${value[13]} ${value[14]} ${value[15]}"
#
#            if [ $j -eq 256 ]; then
#                j=0
#                let k=k+1
#                echo "spi-bb -s 125 -S low -c 105 -C low -o 107 -O rising -i 106 -I falling -w $cnt_sum 0x02 $k $j 00 ${value[0]} ${value[1]} ${value[2]} ${value[3]} ${value[4]} ${value[5]} ${value[6]} ${value[7]} ${value[8]} ${value[9]} ${value[10]} ${value[11]} ${value[12]} ${value[13]} ${value[14]} ${value[15]}"
#			    echo "......"
#            fi
#		    cnt_sum=0
#		fi
# 
#    done  < $tmp_file

    # WRDI (write disable) 0x04 set Write Disable
    spi-bb -s 650 -S low -c 645 -C low -o 646 -O rising -i 647 -I falling -w 8 0x04 > /dev/null 2>&1

    #rm -rf $tmp_file
    #Disable bmc update MAC channel
    echo 0 > ${BASECPLD_SYSFS_DIR}/bmc_mac_spi_sel; sync
    echo "done."
}

flash_rd() {
    rd_file=$2
    local temp_file
    local a

    temp_file="/var/tmp/MAC_tmp.txt"
    if [ -f $rd_file ]; then
        rm -f $rd_file
    fi

    echo -n "Reading MAC's flash ..."
    echo 1 > ${BASECPLD_SYSFS_DIR}/bmc_mac_spi_sel; sync
    #ֻ��ǰ16KB����
    spi-bb -s 650 -S low -c 645 -C low -o 646 -O rising -i 647 -I falling -r $READ_MAX_BIT -w 32 0x3 0x0 0x0 0x0 |  grep "Read" > $temp_file
    echo "done."
    echo 0 > ${BASECPLD_SYSFS_DIR}/bmc_mac_spi_sel; sync

    echo -n "Storing to bin file ..."
    sed -i "s/Read [0-9]* bits: ff ff ff//g" $temp_file
    sed -i "s/ /\\\x/g" $temp_file
    a=`cat $temp_file`
    echo -e -n $a > $rd_file
    #rm -rf $temp_file
    echo "done."
}

flash_erase() {
    local i;local j;local rem;local idx;local regs
    #Enable bmc update MAC channel
    echo 1 > ${BASECPLD_SYSFS_DIR}/bmc_mac_spi_sel; sync

    echo -n "Erasing MAC's flash ..."
    # WREN (write enable) 0x06 set Write Enable
    spi-bb -s 650 -S low -c 645 -C low -o 646 -O rising -i 647 -I falling -w 8 0x06 > /dev/null 2>&1
    # RDSR (read status register)   0x05
    spi-bb -s 650 -S low -c 645 -C low -o 646 -O rising -i 647 -I falling -r 16 -w 8 0x05 > /dev/null 2>&1
    # CE (chip erase)  60 or C7 (hex)
    spi-bb -s 650 -S low -c 645 -C low -o 646 -O rising -i 647 -I falling -w 8 0x60 > /dev/null 2>&1
    # RDSR (read status register)   0x05
    spi-bb -s 650 -S low -c 645 -C low -o 646 -O rising -i 647 -I falling -r 16 -w 8 0x05 > /dev/null 2>&1
    
    # WRDI (write disable) 0x04 set Write Disable
    spi-bb -s 650 -S low -c 645 -C low -o 646 -O rising -i 647 -I falling -w 8 0x04 > /dev/null 2>&1
    #Disable bmc update MAC channel
    echo 0 > ${BASECPLD_SYSFS_DIR}/bmc_mac_spi_sel; sync
    echo "done."
}

flash_rdid() {
    local i;local j;local rem;local idx;local regs
    #Enable bmc update MAC channel
    echo 1 > ${BASECPLD_SYSFS_DIR}/bmc_mac_spi_sel; sync

    echo -n "Read MAC's flash ID..."
    spi-bb -s 650 -S low -c 645 -C low -o 646 -O rising -i 647 -I falling -r 32 -w 8 0x9F
    echo 0 > ${BASECPLD_SYSFS_DIR}/bmc_mac_spi_sel; sync
    echo "done."
}

if [ $# -lt 1 ]; then
    usage
    exit -1
fi

command="$1"

case "$command" in
    erase)
        flash_erase $@
        ;;
    read)
        flash_rd $@
        ;;
    write)
        flash_wr $@
        ;;
    readid)
        flash_rdid $@
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?

