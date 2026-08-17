#!/bin/bash
# Copyright (C) 2023, Accton Networks Co., Ltd. All rights reserved.
# No part of this script may be reproduced, distributed,
# or transmitted in any form or by any means,
# without the prior written permission of the author.

ip link set dev eth0 up
# sleep 3
# dhclient -i eth0
# sleep 5

config=`ifconfig eth0.4088`
subconfig2="240.1.1.1"
str_up="UP"

wait_restful()
{
    count=0
    while [ $count -lt 60 ]
    do
        result=`curl http://240.1.1.1:8080/api/bmc/info 2>&1| grep "Connection refused" | wc -l`
        if [ $result -eq 0 ];then
            break
        else
            sleep 3s
            let count+=1
        fi
    done
    logger -p DEBUG "wait restful time: $count *3s"
}

IFACE=eth0
vlan=4088
intf="${IFACE}.${vlan}"

until [[ $config =~ $subconfig2 ]]
do
    ip link add link $IFACE name $intf type vlan id $vlan
    ip addr add 240.1.1.1/30 dev $intf
    wait_restful
    sleep 1
    config=`ifconfig eth0.4088`
done

until [[ $config =~ $str_up ]]
do
    ip link set dev $intf up
    sleep 1
    config=`ifconfig eth0.4088`
done
ping 240.1.1.2 -c 2 >/dev/null
exit 0
