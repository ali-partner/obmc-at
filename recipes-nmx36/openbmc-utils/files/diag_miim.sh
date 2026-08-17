#!/bin/bash


SYSFS_MDIO_DEVICES="/sys/bus/mdio_bus/devices"
has_error=0
# PHY addr 0x01/0x09 --BCM54210S
phy_addr="09"
PHY1_ID1=0x600d
PHY1_ID2=0x8595
# PHY addr 0x02 --88E6361
PHY2_ID=0x2610


usage() {
    echo "Usage: $0"
    echo
}


if [ $# -ne 0 ]; then
    usage
    exit -1
fi

phy1_id_val1=`ast-mdio.py --mdio 2 --phy 0x09 read 0x2 | cut -d ":" -f 2 | awk '{gsub(/^\s+|\s+$/,"");print'}`
phy1_id_val2=`ast-mdio.py --mdio 2 --phy 0x09 read 0x3 | cut -d ":" -f 2 | awk '{gsub(/^\s+|\s+$/,"");print'}`
echo "Read PHY(0x09) ID value is $phy1_id_val1 $phy1_id_val2"
if [[ "$phy1_id_val1" != "$PHY1_ID1" || "$phy1_id_val2" != "$PHY1_ID2" ]]; then
    echo "Check PHY(0x09) ID failed"
    has_error=-1
fi


ast-mdio.py --mdio 2 --phy 0x02 write 0x0 0x9803
phy_id_val=`ast-mdio.py --mdio 2 --phy 0x02 read 0x1 | cut -d ":" -f 2 | awk '{gsub(/^\s+|\s+$/,"");print'}`
echo "Read PHY(0x02) ID value is $phy_id_val"
if [ "$phy_id_val" != "$PHY2_ID" ]; then
    echo "Check PHY(0x02) ID failed"
    has_error=-1
fi

if [ $has_error -eq 0 ]; then
    echo "Check BMC SMI: PASS"
else
    echo "Check BMC SMI: FAIL"
    exit -1
fi
