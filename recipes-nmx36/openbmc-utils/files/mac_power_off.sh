#!/bin/bash
power_status=`/usr/local/bin/power_force_ctrl.sh switch status`
if [[ "$power_status" == *OFF* ]]; then
    echo "[switch power ctrl]Switch power status: OFF." > /dev/ttyS4
	echo "[switch power ctrl]Switch power status: OFF." >> /var/log/messages
    exit 0
fi

power_ctrl_status=`power_force_ctrl.sh status`
if [[ "$power_ctrl_status" == *Disable* ]]; then
    echo "[switch power ctrl]Enable power force ctrl, done." > /dev/ttyS4
    echo "[switch power ctrl]Enable power force ctrl, done." >> /var/log/messages
    /usr/local/bin/power_force_ctrl.sh enable
fi

power_status=`/usr/local/bin/power_force_ctrl.sh switch status`
echo $power_status > /dev/ttyS4
echo $power_status > /var/log/messages

echo "[switch power ctrl]Power off switch......" > /dev/ttyS4
echo "[switch power ctrl]Power off switch......" >> /var/log/messages
power_status=`/usr/local/bin/power_force_ctrl.sh switch off`

power_status=`/usr/local/bin/power_force_ctrl.sh switch status`
echo $power_status > /dev/ttyS4
echo $power_status > /var/log/messages
if [[ "$power_status" == *OFF* ]]; then
    echo "[switch power ctrl]Power off switch, done." > /dev/ttyS4
	echo "[switch power ctrl]Power off switch, done." >> /var/log/messages
else
    echo "[switch power ctrl]Power off switch, Fail." > /dev/ttyS4
	echo "[switch power ctrl]Power off switch, Fail." >> /var/log/messages
fi
