#!/bin/bash


# echo out > /tmp/gpionames/PECI_SEL_BMC_ANA/direction
# echo 1 > /tmp/gpionames/PECI_SEL_BMC_ANA/value

# Set a default value at the beginning to prevent errors in comparison.
ret="00"


#lspci -s f3:04.0 -v peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x32 0x0f
#f3:04.0 PCI bridge: Intel Corporation Device 18d1  (0xf3 << 4 | 0x04 >> 1)
#lspci -s 00:06.0 -v peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x03 0x00
#00:06.0 PCI bridge: Intel Corporation Device 18da (rev 11)
#lspci -s 00:10.0 -v peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x08 0x00
#00:10.0 PCI bridge: Intel Corporation Device 18a8 (rev 11)
#lspci -s 00:12.0 -v peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x09 0x00
#00:12.0 PCI bridge: Intel Corporation Device 18aa (rev 11)
#lspci -s 00:14.0 -v peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x0a 0x00
#00:14.0 PCI bridge: Intel Corporation Device 18ad (rev 11)


echo
echo "AER DUMP:"
echo "========="
echo
echo "********************************************************"
echo "*                     CPU0 00:06.0                    *"
echo "********************************************************"
for (( i=0; i<=24; i=i+4)) 
do
    aer=`/usr/local/bin/peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x03 0x00`
    ret=`echo $aer | awk '{print $1}'`
    if [ $ret == "40" ];then
        data=`echo $aer | awk '{print $5 $4 $3 $2}'`
        ii=$(printf "%02x" $i);
        echo "offet 0x${ii}h: $data"
    else
        echo "PECI fail! Maybe PECI_SEL_BMC_ANA is HIGH ?"
    fi
done

echo "********************************************************"
echo "*                     CPU0 00:10.0                     *"
echo "********************************************************"
for (( i=0; i<=24; i=i+4))
do
    aer=`/usr/local/bin/peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x08 0x00`
    ret=`echo $aer | awk '{print $1}'`
    if [ $ret == "40" ];then
        data=`echo $aer | awk '{print $5 $4 $3 $2}'`
        ii=$(printf "%02x" $i);
        echo "offet 0x${ii}h: $data"
    else
        echo "PECI fail! Maybe PECI_SEL_BMC_ANA is HIGH ?"
    fi
done

echo "********************************************************"
echo "*                     CPU0 00:12.0                    *"
echo "********************************************************"
for (( i=0; i<=24; i=i+4))
do
    aer=`/usr/local/bin/peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x09 0x00`
    ret=`echo $aer | awk '{print $1}'`
    if [ $ret == "40" ];then
        data=`echo $aer | awk '{print $5 $4 $3 $2}'`
        ii=$(printf "%02x" $i);
        echo "offet 0x${ii}h: $data"
    else
        echo "PECI fail! Maybe PECI_SEL_BMC_ANA is HIGH ?"
    fi
done

echo "********************************************************"
echo "*                     CPU0 00:14.0                    *"
echo "********************************************************"
for (( i=0; i<=24; i=i+4))
do
    aer=`/usr/local/bin/peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x0a 0x00`
    ret=`echo $aer | awk '{print $1}'`
    if [ $ret == "40" ];then
        data=`echo $aer | awk '{print $5 $4 $3 $2}'`
        ii=$(printf "%02x" $i);
        echo "offet 0x${ii}h: $data"
    else
        echo "PECI fail! Maybe PECI_SEL_BMC_ANA is HIGH ?"
    fi
done

echo "********************************************************"
echo "*                     CPU0 f3:04.0                   *"
echo "********************************************************"
for (( i=0; i<=24; i=i+4))
do
    aer=`/usr/local/bin/peci-util 0x30 0x06 0x05 0x61 0x00 $i 0x01 0x32 0x0f`
    ret=`echo $aer | awk '{print $1}'`
    if [ $ret == "40" ];then
        data=`echo $aer | awk '{print $5 $4 $3 $2}'`
        ii=$(printf "%02x" $i);
        echo "offet 0x${ii}h: $data"
    else
        echo "PECI fail! Maybe PECI_SEL_BMC_ANA is HIGH ?"
    fi
done
