#!/bin/bash

. /usr/local/bin/openbmc-utils.sh
do_store_version() {
    local boot_source
    ret=$(devmem 0x14c3744c 32)
	boot_source=${ret:9:1}
    if [ $boot_source -eq 0 ]; then
        rm /var/volatile/log/primary_version
        cat /etc/issue | sed -n 1p | cut -d ' ' -f3 > /var/volatile/log/primary_version
    else
        rm /var/volatile/log/secondary_version
        cat /etc/issue | sed -n 1p | cut -d ' ' -f3 > /var/volatile/log/secondary_version
    fi
}

do_store_version
exit $?