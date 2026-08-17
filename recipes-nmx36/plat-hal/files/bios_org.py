# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/bios.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 4769 bytes
from .devicebase import devicebase
import os
class bios(devicebase):

    def __init__(self, conf=None):
        if conf is not None:
            self.name = conf.get("name", None)
            self.version_file = conf.get("FwVersion", None)
            self.bios_status = conf.get("BiosStatus", None)
            self.bios_upgrade = conf.get("BiosFwUpdata", None)
            self.bios_nextboot = conf.get("BiosNextBoot", None)
            self.nextboot_setting = conf.get("NextBootSetting", None)

    def get_bios_boot_status(self):
        dict_bios_info = {"Flash": "N/A", "Result": "N/A"}
        ret_boot, val_boot = self.get_value(self.bios_status)
        if ret_boot == True and val_boot == 0:
            dict_bios_info["Flash"] = "master"
            dict_bios_info["Result"] = "success"
        elif ret_boot == True and val_boot == 1:
            dict_bios_info["Flash"] = "slave"
            dict_bios_info["Result"] = "success"
        else:
            dict_bios_info["Result"] = "failed"

        return dict_bios_info

    def get_bios_version(self):
        dict_version_info = {"MasterBiosVersion": "N/A", "SlaveBiosVersion": "N/A"}
        return dict_version_info

    def program_bios_firmware(self, flash, image):
        """
        Program BIOS flash with specific image

        @param flash 'master' or 'slave' BIOS flash
        @param image Absolute path of the BIOS image file

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

        command_str = self.bios_upgrade.get("cmdline", None)
        if command_str == None:
            return -1

        command_line = command_str % (device, image)
        status, output = self.command(command_line)
        if status == 0 and (("fwm_util.sh bios" in output) and ("Success" in output)):
            ret = 0
        else:
            ret = -1

        return ret

    def get_bios_next_boot(self):
        """
        Get next booting flash of BIOS

        @return "master"/"slave" on success, "N/A" for failure
        """
        ret, val = self.get_value(self.bios_nextboot)
        if ret == True and val == 0:
            next_boot = "master"
        elif ret == True and val == 1:
            next_boot = "slave"
        else:
            next_boot = "N/A"

        return next_boot

    def set_bios_next_boot(self, flash):
        """
        Set flash from which next BIOS boot

        @param flash Booting flash of BIOS, "master" or "slave"

        @return 0 on success, -1 for failure
        """
        if flash != "master" and flash != "slave":
            return -1

        if flash == "master":
            boot_area = "nextboot_primary"
        else:
            boot_area = "nextboot_secondary"

        command_str = self.nextboot_setting.get("cmdline", None)
        if command_str == None:
            return -1

        command_line = command_str % boot_area
        status, output = self.command(command_line)
        if status == 0:
            ret = 0
        else:
            ret = -1

        return ret