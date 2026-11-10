# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/cpu.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 14388 bytes
from .devicebase import devicebase
import time

class cpu(devicebase):

    def __init__(self, conf=None):
        if conf is not None:
            self.name = conf.get("name", None)
            # self.cpu_status_s3 = conf.get("CpuStatus_S3", None)
            self.cpu_status_s45 = conf.get("CpuStatus_S45", None)
            self.cpu_reset = conf.get("CpuReset", None)
            self.cpu_mcerr = conf.get("CpuMCERR", None)
            self.cpu_ierr = conf.get("CpuIERR", None)
            self.cpu_aer0 = conf.get("CpuAER_err0", None)
            self.cpu_aer1 = conf.get("CpuAER_err1", None)
            self.cpu_aer2 = conf.get("CpuAER_err2", None)
            self.cpu_reset_type = conf.get("CpuResetType", None)

    def get_state(self):
        """
        Get CPU current status.

        @return 'S0', ..., 'S5', or 'N/A' for failure
        """
        cpu_state_dict = {"cpu_last_state" : 0, "cpu_now_state" : 0}
        for index in range(len(cpu_state_dict)):
            # ret, val = self.read_sysfs_value(self.cpu_status_s3)
            # if ret == False:
            #     return "N/A"
            # else:
            #     cpu_state_S3_value = val

            ret, val = self.read_sysfs_value(self.cpu_status_s45)
            if ret == False:
                return "N/A"
            else:
                cpu_state_S45_value = val

            ret, val = self.read_sysfs_value(self.cpu_reset)
            if ret == False:
                return "N/A"
            else:
                cpu_state_reset_value = val

            if cpu_state_S45_value == 0 and cpu_state_reset_value == 0:
                if index == 0:
                    cpu_state_dict["cpu_last_state"] = 0
                else:
                    cpu_state_dict["cpu_now_state"] = 0
            elif cpu_state_S45_value == 1 and cpu_state_reset_value == 1:
                if index == 0:
                    cpu_state_dict["cpu_last_state"] = 1
                else:
                    cpu_state_dict["cpu_now_state"] = 1

            time.sleep(1)

        if cpu_state_dict["cpu_last_state"] != cpu_state_dict["cpu_now_state"]:
            if cpu_state_dict["cpu_last_state"] == 0:
                cpu_state = "S0"
            else:
                cpu_state = "S5"
        else:
            if cpu_state_dict["cpu_now_state"] == 1:
                cpu_state = "S0"
            else:
                cpu_state = "S5"

        return cpu_state

    def get_mca_error(self):
        """
        Get CPU MCA error count.
        @return List of MCERR and IERR counts, or None for failure
                Example:
                {
                    "MCErr": 0,         # -99999
                    "IErr": 0           # -99999
                }
        """
        cpu_mca_error_dict = {"MCErr": 0, "IErr": 0}
        ret, val = self.read_sysfs_value(self.cpu_mcerr)
        if ret == True:
            cpu_mca_error_dict['MCErr'] = val
        else:
            cpu_mca_error_dict['MCErr'] = -99999

        ret, val = self.read_sysfs_value(self.cpu_ierr)
        if ret == True:
            cpu_mca_error_dict['IErr'] = val
        else:
            cpu_mca_error_dict['IErr'] = -99999

        return cpu_mca_error_dict

    def get_aer_error(self):
        """
        Get CPU AER error vector.

        @return List of AER error vector or None for failure
                Example:
                [ERR[0], ERR[1], ERR[2]]
        """
        cpu_aer_error_list = [0, 0, 0]
        ret, val = self.read_sysfs_value(self.cpu_aer0)
        if ret == True:
            cpu_aer_error_list[0] = val
        else:
            return None

        ret, val = self.read_sysfs_value(self.cpu_aer1)
        if ret == True:
            cpu_aer_error_list[1] = val
        else:
            return None

        ret, val = self.read_sysfs_value(self.cpu_aer2)
        if ret == True:
            cpu_aer_error_list[2] = val
        else:
            return None

        return cpu_aer_error_list

    def get_last_reset(self):
        """
        Get last CPU reset type, WARM/COLD.

        @return Last CPU reset type, "WARM"/"COLD", "N/A" for failure
        """
        ret, val = self.read_sysfs_value(self.cpu_reset_type)
        if ret == True and val == 1:
            last_reset_type = "WARM"
        elif ret == True and val == 2:
            last_reset_type = "COLD"
        else:
            last_reset_type = "N/A"

        return last_reset_type

    def set_host_cpu_power(self, power_command):
        """
        Control host cpu power

        @param power_command Control command of host CPU's power,
                             should be "cpu on"/"cpu off"/"cpu cycle"/"cpu reset"

        @return 0 for success, -1 for failure
        """
        power_command_list = ["on", "off", "cycle", "reset"]
        if power_command not in power_command_list:
            return -1

        if power_command == "cycle":
            real_command = "cpu_pwr_cycle"
        else:
            real_command = power_command

        cmd = '/usr/local/bin/power.sh %s' % (real_command)
        status, output = self.command(cmd)
        if "Failed" in output:
            return -1
        else:
            return 0

    def get_host_cpu_power_status(self):
        """
        Get host cpu power status

        @return Power status of CPU(and affiliates), value should be
                "on"/"off", or "N/A" for failure
        """
        cmd = '/usr/local/bin/power.sh status'
        status, output = self.command(cmd)
        if status == 0 and "on" in output:
            power_status = "on"
        elif status == 1 and "off" in output:
            power_status = "off"
        else:
            power_status = "N/A"

        return power_status

    def enable_host_cpu_power_force_control(self, enable):
        """
        Force control host cpu power
        @param enable: enable/disable force control host cpu power,
                       enable: 1; disable: 0
        @return 0 for success, -1 for failure

        """
        if enable == 1:
            opt_str = "on"
        elif enable == 0:
            opt_str = "off"
        else:
            return -1

        cmd_str = '/usr/local/bin/power.sh %s -f' % (opt_str)
        status, output = self.command(cmd_str)
        if status == 0:
            return 0
        else:
            return -1

    def get_host_cpu_power_force_control_status(self):
        """
        Get force control host cpu power status
        @return 1 for enable, 0 for disable, -1 for failure
        """
        cmd_str = '/usr/local/bin/power.sh status'
        status, output = self.command(cmd_str)
        if output is not None and output != '':
            if 'on' in output:
                return 1
            elif "off" in output:
                return 0
            else:
                return -1
        else:
            return -1

    def enable_power_force_control(self, enable):
        """
        Force control host cpu power
        @param enable: enable/disable force control host cpu power,
                       enable: 1; disable: 0
        @return 0 for success, -1 for failure

        """
        if enable == 1:
            opt_str = "enable"
        elif enable == 0:
            opt_str = "disable"
        else:
            return -1

        cmd_str = '/usr/local/bin/power_force_ctrl.sh %s' % (opt_str)
        status, output = self.command(cmd_str)
        if status == 0:
            return 0
        else:
            return -1

    def get_power_force_control_status(self):
        """
        Get force control host cpu power status
        @return 1 for enable, 0 for disable, -1 for failure
        """
        cmd_str = '/usr/local/bin/power_force_ctrl.sh status'
        status, output = self.command(cmd_str)
        if output is not None and output != '' and status == 0:
            if "Enable" in output:
                return 1
            elif "Disable" in output:
                return 0
            else:
                return -1
        else:
            return -1

    def set_switch_port_power_status(self, status):
        """
        Control switch port power
        @param status: Control switch port power,
                        should be “on”/“off”
        @return 0 for success, -1 for failure
        """
        if status not in ["on", "off"]:
            return -1

        if self.enable_power_force_control(1) == -1:
            return -1

        cmd_str = '/usr/local/bin/power_force_ctrl.sh port %s' % (status)
        status, output = self.command(cmd_str)
        if status == 0:
            return 0
        else:
            return -1

    def get_switch_port_power_status(self):
        """
        Get switch port power status
        @return switch port power status, value should be
                        “on”/“off”, or “N/A” for failure
        """
        cmd_str = '/usr/local/bin/power_force_ctrl.sh port status'
        status, output = self.command(cmd_str)
        if output is not None and output != '' and status == 0:
            if "ON" in output:
                return "on"
            elif "OFF" in output:
                return "off"
            else:
                return "N/A"
        else:
            return "N/A"

    def set_switch_chip_power_status(self, status):
        """
        Control switch chip power
        @param status: Control switch chip power,
                            should be “on”/“off”
        @return 0 for success, -1 for failure
        """
        if status not in ["on", "off"]:
            return -1

        if self.enable_power_force_control(1) == -1:
            return -1

        cmd_str = '/usr/local/bin/power_force_ctrl.sh switch %s' % (status)
        status, output = self.command(cmd_str)
        if status == 0:
            return 0
        else:
            return -1

    def get_switch_chip_power_status(self):
        """
        Get switch chip status
        @return switch chip power status, value should be
                            “on”/“off”, or “N/A” for failure
        """
        cmd_str = '/usr/local/bin/power_force_ctrl.sh switch status'
        status, output = self.command(cmd_str)
        if output is not None and output != '' and status == 0:
            if "ON" in output:
                return "on"
            elif "OFF" in output:
                return "off"
            else:
                return "N/A"
        else:
            return "N/A"

    def set_ssd_power_status(self, status):
        """
        Control SSD power
        @param status: Control SSD power,
                        should be “on”/“off”
        @return 0 for success, -1 for failure
        """
        if status not in ["on", "off"]:
            return -1

        if self.enable_power_force_control(1) == -1:
            return -1

        cmd_str = '/usr/local/bin/power_force_ctrl.sh ssd %s' % (status)
        status, output = self.command(cmd_str)
        if status == 0:
            return 0
        else:
            return -1

    def get_ssd_power_status(self):
        """
        Get SSD status
        @return SSD power status, value should be
                        “on”/“off”, or “N/A” for failure
        """
        cmd_str = '/usr/local/bin/power_force_ctrl.sh ssd status'
        status, output = self.command(cmd_str)
        if output is not None and output != '' and status == 0:
            if "ON" in output:
                return "on"
            elif "OFF" in output:
                return "off"
            else:
                return "N/A"
        else:
            return "N/A"

