# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/firmware.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 16051 bytes
"""
class for Platfrom HAL for implement Firmware APIs.
"""
from .devicebase import devicebase
import os

class firmware(devicebase):

    def __init__(self):
        pass

    def program_cpld(self, names, files):
        """
        Program CPLD

        @param names List of CPLD/FPGA names
        @param files List of refresh files for CPLD/FPGA

        @return 0 on success, -1 for failure
        """
        if type(names) != list or type(files) != list:
            return -1

        if len(names) != len(files):
            return -1

        for index in range(len(names)):
            if os.path.isfile(files[index]) == False:
                return -1
            if "cpld" in names[index]:
                command_line = "/usr/local/bin/cpld_update.sh update %s %s" % (names[index], files[index])
                status, output = self.command(command_line)
                if status == 0 and ("Upgrade successful" in output):
                    continue
                else:
                    return -1
            elif "fpga" in names[index]:
                command_line = "/usr/local/bin/fpga_update.sh %s" % (files[index])
                status, output = self.command(command_line)
                if "update fpga success." in output:
                    continue
                else:
                    return -1
            else:
                return -1

        return 0

    def refresh_firmware(self, names, files):
        """
        Refresh CPLD/FPGA/BIOS(reload ME) if applicable

        @param names List of CPLD/FPGA/BIOS names
        @param files List of refresh files for CPLD/FPGA

        @return 0 on success, -1 for failure
        """
        if type(names) != list or type(files) != list:
            return -1

        if len(names) != len(files):
            return -1

        status, output = self.command("/usr/local/bin/fw_refresh.sh init")
        if status != 0:
            return -1

        fw_names = ""
        fw_files = ""
        for i in range(len(names)):
            if len(fw_files) == 0:
                fw_names = names[i]
                fw_files = files[i]
            else:
                fw_names = fw_names + ":" + names[i]
                fw_files = fw_files + ":" + files[i]

        cmd_str = '/usr/local/bin/fw_refresh.sh refresh %s %s' % (fw_names, fw_files)
        status, output = self.command(cmd_str)
        if status != 0:
            return -1

        return 0
