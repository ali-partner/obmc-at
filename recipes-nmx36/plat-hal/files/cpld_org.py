# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/cpld.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 3102 bytes
from .devicebase import devicebase

class cpld(devicebase):

    def __init__(self, conf=None):
        if conf is not None:
            self.name = conf.get("name", None)
            self.user_reg = conf.get("UserReg", None)
            self.console_sel = conf.get("ConsoleSel", None)
            self.console_sel_update = conf.get("ConsoleSelUpdate", None)
            self.console_sel_attrs = conf.get("ConsoleSelAttrs", None)
            self.major_version_file = conf.get("MajorVerFile", None)
            self.minor_version_file = conf.get("MinorVerFile", None)
            self.upgrade_command = conf.get("UpgradeCommand", None)
            self.upgrade_result = conf.get("UpgradeResultFile", None)

    def get_user_reg(self):
        """
        Get user register value, 1 byte value

        @return unsigned value, 1 byte, None for failure
        """
        if self.user_reg == None:
            return None

        ret, val = self.get_value(self.user_reg)
        if ret == False:
            return None

        return val

    def set_user_reg(self, value):
        """
        Set user register value, 1 byte

        @return 0 for success, -1 for failure
        """
        if self.user_reg == None:
            return -1

        if type(value) != int or value > 255 or value < 0:
            return -1

        byte = value & 255
        ret, val = self.set_value(self.user_reg, byte)
        if ret == False:
            return -1

        return 0

    def set_console_owner(self, owner):
        """
        Set console I/O owner

        @param owner I/O owner of the console, either "cpu" or "bmc"

        @return 0 for success, -1 for failure
        """
        tmpattr = self.console_sel_attrs.get(owner, None)
        if tmpattr == None:
            return -1

        ret_sel, val_sel = self.set_value(self.console_sel, tmpattr)
        ret_update, val_update = self.set_value(self.console_sel_update, 1)
        if ret_sel == False or ret_update == False:
            return -1

        return 0

    def get_version(self):
        ret_maj_ver, val_maj_ver = self.get_value(self.major_version_file)
        ret_min_ver, val_min_ver = self.get_value(self.minor_version_file)
        if ret_maj_ver == False or ret_min_ver == False:
            cpld_version = "N/A"
        else:
            cpld_version = ("%02x.%02x" % (val_maj_ver, val_min_ver))

        return cpld_version

    def program_cpld_firmware(self, name, image):
        """
        Program CPLD flash with specific image

        @param name CPLD aliase name
        @param image Absolute path of the CPLD image file

        @return 0 for success, -1 for failure
        """
        if os.path.isfile(image) == False:
            return -1

        command_str = self.upgrade_command.get("cmdline", None)
        if command_str == None:
            return -1

        command_line = command_str % (name, image)
        status, output = self.command(command_line)
        if status == 0 and ("Upgrade successful" in output):
            ret = 0
        else:
            ret = -1

        return ret

    def get_last_upgrade_result(self):
        r"""
        Get last upgrade result for CPLD\BIOS\FPGA refresh
        @return Get last upgrade content dict or None for failure.
        """
        if not os.path.exists(self.upgrade_result):
            return (-1, None)

        ret, output = self.read_file(self.upgrade_result)
        if ret == False or self.name not in output:
            return (-1, None)

        dict_ver = {}
        for line in output.split('\n'):
            if self.name in line:
                dict_ver[self.name] = line.split(":", 1)[-1].strip()

        return (0, dict_ver)
