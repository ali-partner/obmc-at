#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

emmc_cycle() {
    sync
    sleep 3
    systemctl stop syslog.socket
    systemctl stop rsyslog
    systemctl stop mTerm_server
    umount /var/volatile/log
    power_util.sh emmc cycle
    mount -o rw /dev/mmcblk0 /var/volatile/log
    systemctl start syslog.socket
    systemctl start mTerm_server
}
emmc_cycle