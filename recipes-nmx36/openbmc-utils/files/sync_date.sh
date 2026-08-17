#!/bin/bash

. /usr/local/bin/openbmc-utils.sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin

if [ -f /tmp/cache_store/time_sync ] ; then
      # ND Server Time Sync by IPMI command
      output=$(cat /tmp/cache_store/time_sync)
      if [ ${#output} == 11 ] ; then
        echo Syncing up BMC time with server...
        date -s @$((16#$(echo "$output" | awk '{print $4$3$2$1}')))
		test -x /etc/init.d/hwclock.sh && /etc/init.d/hwclock.sh stop
      fi
fi
