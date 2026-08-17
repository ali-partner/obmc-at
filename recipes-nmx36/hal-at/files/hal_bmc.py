###############################################################################
#
# Hardware Abstraction Layer APIs -- BMC APIs.
#
# Copyright (C) Alibaba, INC.
#
###############################################################################

"""
class for HAL BMC APIs
Note:
    For a failed request(GET and POST), response.json() should be:
    {
        "status": "ERROR",
        "messages": "Detailed message for the failure",
        "data": {}    # Empty
    }

    For a POST request, successful response.json() should be:
    {
        "status": "OK",
        "messages": "OK"
        "data": {}
    }

"""

from plat_hal.interface import interface

class HalBmc(object):
    __int_case = None

    def __init__(self):
        self.int_case = interface()

    @property
    def int_case(self):
        return self.__int_case

    @int_case.setter
    def int_case(self, val):
        self.__int_case = val

    def get_info(self):
        """
        Get BMC info

        @return dict of BMC info or None for failure
                {
                    "Version": "1.1.1", # "N/A"
                    "Flash": "master",  # "N/A"
                    "Next": "master"    # "N/A"
                }
        """
        return self.int_case.get_bmc_info()

    def get_version_all(self):
        """
        @return dict of BMCs
                {
                    "MasterVersion": "1.1.1",   # "N/A"
                    "SlaveVersion": "1.1.1"     # "N/A"
                }
        """
        return self.int_case.get_bmc_version_all()

    def get_status(self):
        """
        Get BMC system status

        @return dict of system status or None for failure
                # "N/A" for invalid outpouts
                {
                    "CPU": {
                        "StateOutputs": "output of command 'top -bn 1'"
                        "Usage": "10.0"
                    },
                    "MEMORY": {
                        "StateOutputs": "output of command 'free -m'"
                        "Usage": "15.0"   # caculate: "free -t | grep \"buffers/cache\" | awk '{ printf \"mem usage  : %.1f%%\\n\",$3/($3+$4) * 100}'"
                    },
                    "DISK": {
                        "StateOutput": "output of command 'df -h'"
                        "Usage": "12.5"
                    }
                }
        """
        return self.int_case.get_bmc_status()

    def get_next_boot(self):
        """
        Get next booting flash of BMC

        @return 'master'/'slave' on success, "N/A" for failure
        """
        return self.int_case.get_bmc_next_boot()

    def set_next_boot(self, flash):
        """
        Set flash from which next BMC boot

        @param flash Booting flash of BMC, "master" or "slave"

        @return 0 on success, -1 for failure
        """
        return self.int_case.set_bmc_next_boot(flash)

    def reboot(self):
        """
        Reboot running BMC
        """
        return self.int_case.reboot_bmc()
