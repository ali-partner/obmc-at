# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/bmc.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 27525 bytes
"""
class for Platfrom HAL for implement Hal_bmc APIs.
"""
import os
import re

from .devicebase import devicebase

class bmc(devicebase):

    def __init__(self, conf=None):
        if conf is not None:
            self.name = conf.get("name", None)
            self.version_file = conf.get("FwVersion", None)
            self.current_boot_info = conf.get("CurrentBoot", None)
            self.next_boot_info = conf.get("NextBoot", None)
            self.master_version_file = conf.get("MasterVersion", None)
            self.slave_version_file = conf.get("SlaveVersion", None)
            self.bmc_upgrade = conf.get("BmcFwUpdata", None)
            self.sys_airflow = conf.get("SysAirFlow", None)
            self.sys_led_state = conf.get("SysLedState", None)
            self.sys_led_attrs = conf.get("SysLedAttrs", None)
            self.pwr_led_ctrl = conf.get("PwrLedCtrl", None)
            self.pwr_led_state = conf.get("PwrLedState", None)
            self.pwr_led_attrs = conf.get("PwrLedAttrs", None)
            self.sys_fan_led_ctrl = conf.get("SysFanLedCtrl", None)
            self.sys_fan_led_state = conf.get("SysFanLedState", None)
            self.sys_fan_led_attrs = conf.get("SysFanLedAttrs", None)
            self.port_led_status_1 = conf.get("PortLedState_1", None)
            self.port_led_status_2 = conf.get("PortLedState_2", None)
            self.port_led_status_3 = conf.get("PortLedState_3", None)
            self.port_led_attrs = conf.get("PortLedAttrs", None)

    def get_info(self):
        """
        Get BMC info

        @return dict of BMC info or None for failure
                    "Version": "1.1.1", # "N/A"
                    "Flash": "master",  # "N/A"
                    "Next": "master"    # "N/A"
        """
        bmc_info_dict = {"Version": "N/A", "Flash": "N/A", "Next": "N/A"}

        ret, output = self.get_value(self.version_file)
        if ret == True and "OpenBMC Release" in output:
            bmc_info_dict["Version"] = output.split("OpenBMC Release ", 1)[-1]

        ret, val = self.get_value(self.current_boot_info)
        if ret == True and "Primary SPI" in val:
            bmc_info_dict["Flash"] = "master"
        elif ret == True and "Secondary SPI" in val:
            bmc_info_dict["Flash"] = "slave"

        ret, val = self.get_value(self.next_boot_info)
        if ret == True and "Primary SPI" in val:
            bmc_info_dict["Next"] = "master"
        elif ret == True and "Secondary SPI" in val:
            bmc_info_dict["Next"] = "slave"

        return bmc_info_dict

    def get_version_all(self):
        """
        @return dict of BMCs
                {
                    "MasterVersion": "1.1.1",   # "N/A"
                    "SlaveVersion": "1.1.1"     # "N/A"
                }
        """
        bmc_version_dict = {"MasterVersion": "N/A", "SlaveVersion": "N/A"}
        ret, output = self.get_value(self.master_version_file)
        if ret == True:
            bmc_version_dict["MasterVersion"] = output

        ret, output = self.get_value(self.slave_version_file)
        if ret == True:
            bmc_version_dict["SlaveVersion"] = output

        return bmc_version_dict

    def get_status(self):
        r"""
        Get BMC system status

        @return dict of system status or None for failure
                # "N/A" for invalid outputs
                {
                    "CPU": {
                        "StateOutputs": "output of command 'top -bn 1'"
                        "Usage": "10.0"
                    },
                    "MEMORY": {
                        "StateOutputs": "output of command 'free -m'"
                        "Usage": "15.0"   # caculate: "free -t | grep "buffers/cache" | awk '{ printf "mem usage  : %.1f%%\n",$3/($3+$4) * 100}'"
                    },
                    "DISK": {
                        "StateOutputs": "output of command 'df -h'"
                        "Usage": "12.5"
                    }
                }
        """

        bmc_status_dict = {
            "CPU": {
                "StateOutputs": "N/A",
                "Usage": "N/A"
            },
            "MEMORY": {
                "StateOutputs": "N/A",
                "Usage": "N/A"
            },
            "DISK": {
                "StateOutputs": "N/A",
                "Usage": "N/A"
            }
        }

        try:
            cmd = "top -bn 1"
            ret, output = self.command(cmd)
            if ret == 0 and output is not None and output != '':
                bmc_status_dict["CPU"]["StateOutputs"] = output
                value, count = re.subn("[\\S\\s]*nic\\s+(\\d+)%\\sidle[\\S\\s]*", "\\g<1>", output)
                if count == 1:
                    usage_cpu = 100 - int(value)
                    bmc_status_dict["CPU"]["Usage"] = "%s" % str(usage_cpu)

            cmd = "free -m"
            ret, output = self.command(cmd)
            if ret == 0 and output is not None and output != '':
                bmc_status_dict["MEMORY"]["StateOutputs"] = output
                cmd = 'free -tm | grep "buffers/cache" | awk \'{ printf "%.1f",$3/($3+$4) * 100}\''
                ret, output = self.command(cmd)
                if ret == 0:
                    bmc_status_dict["MEMORY"]["Usage"] = output

            cmd = "df -h"
            ret, output = self.command(cmd)
            if ret == 0 and output is not None and output != '':
                bmc_status_dict["DISK"]["StateOutputs"] = output
                cmd = 'df | grep mmc | awk \'{print $2"\t"$3}\''
                ret, output = self.command(cmd)
                if ret == 0:
                    diskinfo_str = output.split()
                    if len(diskinfo_str) == 2:
                        toltal_size = int(diskinfo_str[0])
                        used_size = int(diskinfo_str[1])
                        bmc_status_dict["DISK"]["Usage"] = str("%.1f" % (used_size / toltal_size * 100))
        except:
            print("error occurred while getting bmc status")
        return bmc_status_dict

    def get_next_boot(self):
        """
        Get next booting flash of BMC

        @return 'master'/'slave' on success, "N/A" for failure
        """
        ret, val = self.get_value(self.next_boot_info)
        if ret == True and "Primary SPI" in val:
            nextboot = "master"
        elif ret == True and "Secondary SPI" in val:
            nextboot = "slave"
        else:
            nextboot = "N/A"

        return nextboot

    def set_next_boot(self, flash):
        """
        Set flash from which next BMC boot

        @param flash Booting flash of BMC, "master" or "slave"

        @return 0 on success, -1 for failure
        """
        if flash == "master":
            boot_area = "nextboot_primary"
        elif flash == "slave":
            boot_area = "nextboot_secondary"
        else:
            return -1
 
        cmd = '/usr/local/bin/boot_area.sh bmc %s' % boot_area
        ret, output = self.command(cmd)
        if ret != 0:
            ret = -1

        return ret

    def reboot(self):
        """
        Reboot running BMC
        """
        ret, output = self.command("/usr/local/bin/boot_area.sh bmc action")
        if ret != 0:
            return -1

        return ret

    def program_bmc_firmware(self, flash, image):
        """
        Program BMC flash witch specific image

        @param flash 'master' or 'slave' BMC flash
        @param image Absolute path of BMC image file

        @return 0 for success, -1 for failure
        """
        if flash == "master":
            device = "primary"
        elif flash == "slave":
            device = "secondary"
        else:
            return -1

        if os.path.isfile(image) == False:
            return -1

        command_str = self.bmc_upgrade.get("cmdline", None)
        if command_str == None:
            return -1

        command_line = command_str % (device, image)
        status, output = self.command(command_line)
        if status == 0:
            for line in output.strip().splitlines():
                if re.search(r"Verifying kb: \d+/\d+ \(100%\)", line):
                    ret = 0
                    break
                else:
                    ret = -1
        else:
            ret = -1

        return ret

    def set_system_fan_led(self, color, blink=False):
        """
        Set system fan LED color
        The 40D device does not support setting red light, set the red light to go out??

        @param color The color of system fan LED, "green"/"yellow"/"off"
        @param blink True for blinking, False for steady

        @return 0 for success, -1 for failure
        """
        sys_fan_led_status = ["green", "yellow", "off"]
        if color not in sys_fan_led_status:
            return -1

        ret, val = self.set_value(self.sys_fan_led_ctrl, 1)
        if ret == False:
            return -1

        if blink:
            led_attr = "blink"
        else:
            led_attr = "steady"
        ret, val = self.set_value(self.sys_fan_led_state, self.sys_fan_led_attrs[color][led_attr])
        if ret == False:
            return -1

        return 0

    def set_system_led(self, color, blink):
        """
        Set system LED color, system LED indicates status of the whole system
        The 40D device does not support setting red light, set the red light to go out

        @param color The color of system fan LED, "green"/"yellow"/"off"
        @param blink True for blinking, False for steady

        @return 0 for success, -1 for failure
        """
        sys_led_status = ["green", "yellow", "off"]
        if color not in sys_led_status:
            return -1

        if blink:
            led_attr = "blink"
        else:
            led_attr = "steady"
        ret, val = self.set_value(self.sys_led_state, self.sys_led_attrs[color][led_attr])
        if ret == False:
            return -1

        return 0

    def get_system_power_led_available(self):
        """
        Get system power LED availability

        @return True if available, False otherwise.
        """
        ret, val = self.get_value(self.pwr_led_state)
        if ret == False:
            return False

        return True

    def set_system_power_led(self, color, blink):
        """
        Set system power LED color, power LED indicates PSU, DC/DC status
        The 40D device does not support setting red light, set the red light to go out

        @param color The color of system fan LED, "green"/"yellow"/"off"
        @param blink True for blinking, False for steady

        @return 0 for success, -1 for failure
        """
        pwr_led_status = ["green", "yellow", "off"]
        if color not in pwr_led_status:
            return -1

        ret, val = self.set_value(self.pwr_led_ctrl, 1)
        if ret == False:
            return -1

        if blink:
            led_attr = "blink"
        else:
            led_attr = "steady"
        ret, val = self.set_value(self.pwr_led_state, self.pwr_led_attrs[color][led_attr])
        if ret == False:
            return -1

        return 0

    def set_location_led(self, command):
        """
        Set location LED admin status

        @param cmd Control command, "on"/"off"

        @return 0 for success, -1 for failure
        """
        local_led_status = ["on", "off"]
        if command not in local_led_status:
            return -1

        ret_1, val_1 = self.set_value(self.port_led_status_1, self.port_led_attrs[command])
        # ret_2, val_2 = self.set_value(self.port_led_status_2, self.port_led_attrs[command])
        if ret_1 == False:
            return -1

        return 0

    def get_location_led(self):
        """
        Get location LED admin status

        @return status of location LED, "on"/"off" or "N/A" for failure
        """
        ret_1, val_1 = self.get_value(self.port_led_status_1)
        ret_2, val_2 = self.get_value(self.port_led_status_1)
        ret_3, val_3 = self.get_value(self.port_led_status_1)
        if ret_1 == False or ret_2 == False or ret_3 == False:
            return "N/A"

        if val_1 == 0x3 and val_2 == 0x3 and val_3 == 0x3:
            return "on"
        elif val_1 == 0x0 and val_2 == 0x0 and val_3 == 0x0:
            return "off"
        else:
            return "N/A"

    def get_system_airflow(self):
        """
        Get system air flow.

        @return "F2B"/"B2F" on success, "N/A" for failure
        """
        if self.sys_airflow == None:
            return "N/A"

        return self.sys_airflow

    def get_productname(self):
        """
        Get platform name

        @return platform name string, e.g. AS13-32H-F-$(VENDOR_NAME)
        """
        status, output = self.get_fru_item("base", "Product Name")
        if status == False:
            info = "N/A"
        else:
            info = output

        return info

    def get_sys_eeprom(self):
        """
        Get SYSEEPROM
        @return SYSEEPROM content dict or None for failure.

        """
        result = {}
        cmd = 'fruid-util base'
        status, output = self.command(cmd)
        if output is not None and output != '' and status == 0:
            for line in output.splitlines():
                if "Board" in line or "Product" in line:
                    sdata = line.split(':', 1)
                    result[sdata[0].rstrip()] = sdata[1].lstrip()
        else:
            return None

        return result

    def get_uboot_boot_status(self):
        """
        Get lastest U-Boot boot status, include boot_flash and result
        
        @return Dict of U-Boot boot status or None for failure
            Example:
            {
                "Flash": "master",      # "slave" or 'N/A'
                "Result": "success"     # "failed" or 'N/A'
            }
        """
        uboot_boot_info = {"Flash": "N/A", "Result": "N/A"}
        cmd_line = '/usr/local/bin/boot_area.sh bmc status'
        status, output = self.command(cmd_line)
        if status == 0 and "Primary SPI" in output:
            uboot_boot_info["Flash"] = "master"
            uboot_boot_info["Result"] = "success"
        elif status == 0 and "Secondary SPI" in output:
            uboot_boot_info["Flash"] = "slave"
            uboot_boot_info["Result"] = "success"
        else:
            uboot_boot_info["Result"] = "failed"

        return uboot_boot_info

    def get_bmc_boot_status(self):
        """
        Get BMC latest boot status

        @return "master"/"slave" for boot successfully from master/slave flash
                "N/A" for read failed
        """
        cmd_line = '/usr/local/bin/boot_area.sh bmc status'
        status, output = self.command(cmd_line)
        if status == 0 and "Primary SPI" in output:
            flash = "master"
        elif status == 0 and "Secondary SPI" in output:
            flash = "slave"
        else:
            flash = "N/A"

        return flash
