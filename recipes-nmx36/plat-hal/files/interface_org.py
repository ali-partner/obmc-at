# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/interface.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 62999 bytes
from .chassisbase import chassisbase
from .baseutil import baseutil
from .osutil import osutil
from .sensor import sensor
import sys, time


def Singleton(cls):
    _instance = {}

    def _singleton(*args, **kargs):
        if cls not in _instance:
            _instance[cls] = cls(*args, **kargs)
        return _instance[cls]

    return _singleton

@Singleton
class interface(object):
    _interface__chas = None
    _interface__error_ret = None
    _interface__na_ret = None

    def __init__(self):
        self.chas = chassisbase()
        self._interface__error_ret = -99999
        self._interface__na_ret = "N/A"

    @property
    def na_ret(self):
        return self._interface__na_ret

    @na_ret.setter
    def na_ret(self, val):
        self._interface__na_ret = val

    @property
    def error_ret(self):
        return self._interface__error_ret

    @error_ret.setter
    def error_ret(self, val):
        self._interface__error_ret = val

    @property
    def chas(self):
        return self._interface__chas

    @chas.setter
    def chas(self, val):
        self._interface__chas = val

    def get_product_name(self):
        return baseutil.get_productname()

    def get_temp_total_number(self):
        templist = self.chas.temp_list
        return len(templist)

    def temp_test(self):
        templist = self.chas.temp_list
        dicret = {}
        for temp in templist:
            dic = {}
            dic["Value"] = temp.Value if temp.Value is not None else self.error_ret
            dic["LowAlarm"] = temp.Min
            dic["HighAlarm"] = temp.Max
            dicret[temp.name] = dic

        return dicret

    def get_temp_all_info(self):
        temp_info_dict = {}
        templist = self.chas.temp_list
        for temp in templist:
            dicttmp = {}
            dicttmp["Min"] = temp.Min
            dicttmp["Max"] = temp.Max
            dicttmp["Value"] = temp.Value if temp.Value is not None else self.error_ret
            dicttmp["Unit"] = temp.Unit
            temp_info_dict[temp.name] = dicttmp

        return temp_info_dict

    def get_dcdc_all_info(self):
        """
        Get all DCDC sensor info

        @return dict for all DCDC info or None for failure
        """
        dcdc_info_dict = {}
        dcdclist = self.chas.dcdc_list
        for dcdc in dcdclist:
            dicttmp = {}
            dicttmp["Min"] = dcdc.Min
            dicttmp["Max"] = dcdc.Max
            dicttmp["Value"] = dcdc.Value if dcdc.Value is not None else self.error_ret
            dicttmp["Unit"] = dcdc.Unit
            dcdc_info_dict[dcdc.name] = dicttmp

        return dcdc_info_dict

    def get_monitor_temp(self, name):
        temp = self.chas.get_temp_byname(name)
        if temp is None:
            return None

        dic = {}
        dic["Min"] = temp.Min
        dic["Max"] = temp.Max
        dic["Value"] = temp.Value if temp.Value is not None else self.error_ret
        dic["Unit"] = temp.Unit
        return dic

    def get_monitor_dcdc(self, name):
        dcdc = self.chas.get_dcdc_byname(name)
        if dcdc is None:
            return None

        dic = {}
        dic["Min"] = dcdc.Min
        dic["Max"] = dcdc.Max
        dic["Value"] = dcdc.Value if dcdc.Value is not None else self.error_ret
        dic["Unit"] = dcdc.Unit
        return dic

    def get_monitor_sensor(self, name):
        ret = self.get_monitor_temp(name)
        if ret != None:
            return ret

        ret = self.get_monitor_dcdc(name)
        if ret != None:
            return ret

        return None

    def get_sensor_info(self):
        """
        @return dict of sensors' information
                {
                    "SensorName1": {
                        "Value": 1.0,       # -99999.0
                        "Min": 0.0,         # -99999.0
                        "Max": 2.0,         # -99999.0
                        "Unit": "C"         # "N/A"
                    }
                }
        """
        sensor_info_dict = {}
        sensor_info_dict.update(self.get_temp_all_info())
        sensor_info_dict.update(self.get_dcdc_all_info())
        return sensor_info_dict

    def get_psu_total_number(self):
        """
        Get system's total number of PSU

        @return Total number of PSU, -1 for failure
        """
        psulist = self.chas.psu_list
        if psulist is None:
            return -1

        return len(psulist)

    def get_psu_presence(self, psu_name):
        """
        Get a specific PSU's presence status

        @return True if present, False for NOT present or failure
        """
        psu = self.chas.get_psu_byname(psu_name)
        if psu is None:
            return False

        return psu.present

    def get_psu_fru_info(self, psu_name):
        """
        Get FRU info of a specific PSU

        @return dict of the specific PSU's info, None for failure
                Example return value(all keys are mandatory)
                {
                    "Name": "PSU1",
                    "SN": "serial_number_example",    # 'N/A'
                    "PN": "part_number_example",      # 'N/A'
                    "AirFlow": "B2F"                  # 'N/A'
                }
        """
        psu = self.chas.get_psu_byname(psu_name)
        if psu is None:
            return None

        if psu.present == False:
            return None

        psu_fru_dict = {}
        psu_fru_dict["Name"] = psu.name
        psu_fru_dict["SN"] = psu.productSerialNumber
        psu_fru_dict["PN"] = psu.productPartModelName
        psu_fru_dict["AirFlow"] = psu.AirFlow
        return psu_fru_dict

    def get_psu_status(self, psu_name):
        """
        Get status of a specific PSU

        @return dict of the specific PSU's status, None for failure
                Example return value(all keys are mandatory)
                {
                    "Name": "PSU1",
                    "InputType": "DC",    # "AC" or 'N/A'
                    "InputStatus": True,  # H/W status bit
                    "OutputStatus": True  # H/W status bit
                    "FanSpeed": {
                        "Value": 4000,    # -99999
                        "Min": 2000,      # -99999
                        "Max": 10000      # -99999
                    },
                    "Temperature": {
                        "Value": 40.0,    # -99999.0
                        "Min": -30.0,     # -99999.0
                        "Max": 50.0       # -99999.0
                    }
                }
        """
        psu = self.chas.get_psu_byname(psu_name)
        if psu is None:
            return None

        return psu.psu_status_dict

    def get_psu_power_status(self, psu_name):
        """
        Get power status of a specific PSU

        @return dict of the specific PSU's power status, None for failure
                Example return value
                {
                    "Name": "PSU1",
                    "Inputs": {
                        "Status": True, # H/W status bit
                        "Type": "DC",   # or "AC" or "N/A"
                        "Voltage": {
                            "Value": 220,       # -1
                            "LowAlarm": 200,    # -1
                            "HighAlarm": 240,   # -1
                            "Unit": "V"
                        },
                        "Current": {
                            "Value": 6.0,       # -99999.0
                            "LowAlarm": 0.2,    # -99999.0
                            "HighAlarm": 7.0,   # -99999.0
                            "Unit": "A"
                        },
                        "Power": {
                            "Value": 1000,      # -99999
                            "LowAlarm": -1,     # -99999
                            "HighAlarm": 1400,  # -99999
                            "Unit": "W"
                       }
                    },
                    "Outputs": {
                        "Status": True,
                        "Voltage": {
                            "Value": 220,
                            "LowAlarm": 200,
                            "HighAlarm": 240,
                            "Unit": "V"
                        },
                        "Current": {
                            "Value": 6.0,
                            "LowAlarm": 0.2,
                            "HighAlarm": 7.0,
                            "Unit": "A"
                        },
                        "Power": {
                            "Value": 1000,
                            "LowAlarm": -1,  # Don't care
                            "HighAlarm": 1400,
                            "Unit": "W"
                        }
                    }
                }
        """
        psu = self.chas.get_psu_byname(psu_name)
        if psu is None:
            return None

        return psu.psu_power_status_dict

    def set_psu_fan_speed_pwm(self, psu_name, pwm):
        """
        Set a specific PSU's fan's speed

        @param pwm duty cycle, unit is 1%

        @return 0 for success, -1 for failure
        """
        psu = self.chas.get_psu_byname(psu_name)
        if psu is None:
            return -1

        return psu.set_fan_speed_pwm(pwm)

    def get_psu_fan_speed_pwm(self, psu_name):
        """
        Get a specific PSU's fan's speed

        @return pwm duty cycle, unit is 1%, -1 for failure
        """
        psu = self.chas.get_psu_byname(psu_name)
        if psu is None:
            return -1

        return psu.get_fan_speed_pwm()

    def get_psu_info_all(self):
        """
        Get all system PSU's info

        @return dict of all PSUs or None for failure
                {
                    "Number": 2,
                    "PSU1": {
                        "SN": "serial_number_example",  # 'N/A'
                        "PN": "part_number_example",    # 'N/A'
                        "AirFlow": "F2B",               # 'N/A'
                        "Present": "yes"                # "no"

                        "FanSpeed": {
                            "Value": 4000,
                            "Min": 2000,
                            "Max": 30000
                        },
                        "Temperature": {
                            "Value": 35.0,
                            "Min": -20.0,
                            "Max": 45.0
                        },
                        "Inputs": {
                            "Status": True, # H/W status bit
                            "Type": "DC",   # or "AC"
                            "Voltage": {
                                "Value": 220,
                                "LowAlarm": 200,
                                "HighAlarm": 240,
                                "Unit": "V"
                            },
                            "Current": {
                                "Value": 6.0,
                                "LowAlarm": 0.2,
                                "HighAlarm": 7.0,
                                "Unit": "A"
                            },
                            "Power": {
                                "Value": 1000,
                                "LowAlarm": -1,
                                "HighAlarm": 1400,
                                "Unit": "W"
                           }
                        },
                        "Outputs": {
                            "Status": True,
                            "Voltage": {
                                "Value": 220,
                                "LowAlarm": 200,
                                "HighAlarm": 240,
                                "Unit": "V"
                            },
                            "Current": {
                                "Value": 6.0,
                                "LowAlarm": 0.2,
                                "HighAlarm": 7.0,
                                "Unit": "A"
                            },
                            "Power": {
                                "Value": 1000,
                                "LowAlarm": -1,  # Don't care
                                "HighAlarm": 1400,
                                "Unit": "W"
                            }
                        }
                    }
                }
        """
        psu_all_info_dict = {}
        psu_all_info_dict["Number"] = len(self.chas.psu_list)
        psus = self.chas.psu_list
        for psu in psus:
            dicttmp = {}
            dicttmp["SN"] = psu.productSerialNumber
            dicttmp["PN"] = psu.productPartModelName
            dicttmp["AirFlow"] = psu.AirFlow
            dicttmp["Present"] = "yes" if psu.present is True else "no"
            dicttmp["FanSpeed"] = psu.psu_fanspeed_dict
            dicttmp["Temperature"] = psu.psu_temp_dict
            dicttmp.update(self.get_psu_power_status(psu.name))
            psu_all_info_dict[psu.name] = dicttmp

        return psu_all_info_dict

    def get_fan_total_number(self):
        """
        Get total fan number count

        @return total number of fan in the system, -1 for failure
        """
        fanlist = self.chas.fan_list
        if fanlist is None:
            return -1

        return len(fanlist)

    def get_fan_rotor_number(self, fan_name):
        """
        Get fan's rotor count for specific fan_name

        @return total rotor count of specific fan, -1 for failure
        """
        fan = self.chas.get_fan_byname(fan_name)
        if fan is None:
            return -1

        ret = fan.rotors
        if ret is None:
            return -1

        return ret

    def get_fan_speed(self, fan_name, rotor_index):
        """
        Get current speed for specific fan and rotor

        @return speed of the specific fan and rotor, unit is RPM,
                -1 for failure
        """
        fan = self.chas.get_fan_byname(fan_name)
        if fan is None:
            return -1

        if fan.present == False:
            return -1

        val = fan.get_speed(rotor_index)
        if val is None:
            return -1

        return val

    def set_fan_speed(self, fan_name, rotor_index, speed):
        """
        Get current speed for specific fan and rotor

        @param speed of the specific fan and rotor, unit is RPM

        @return 0 for success, -1 for failure
        """
        fan = self.chas.get_fan_byname(fan_name)
        if fan is None:
            return -1

        if fan.present == False:
            return -1

        ret = fan.set_speed(rotor_index, speed)
        if ret == False:
            return -1

        return 0

    def get_fan_speed_pwm(self, fan_name, rotor_index):
        """
        Get current PWM duty cycle for specific fan's specific rotor

        @return PWM duty cycle, unit is 1%, -1 for failure
        """
        fan = self.chas.get_fan_byname(fan_name)
        if fan is None:
            return -1

        if fan.present == False:
            return -1

        val = fan.get_speed_pwm(rotor_index)
        if val is None:
            return -1

        return val

    def set_fan_speed_pwm(self, fan_name, rotor_index, pwm):
        """
        Set PWM for specific fan's specific rotor

        @param pwm duty cycle, unit is 1%, -1 for failure

        @return 0 for success, -1 for failure
        """
        fan = self.chas.get_fan_byname(fan_name)
        if fan is None:
            return -1

        if fan.present == False:
            return -1

        ret = fan.set_speed_pwm(rotor_index, pwm)
        if ret == False:
            return -1

        return 0

    def get_fan_watchdog_status(self):
        """
        Get Fan watchdog status.

        @return 'Normal'/'Abnormal'/'N/A' for status good/bad/read-failed.
        """
        list_temp = self.chas.fan_list
        if list_temp:
            fan = list_temp[0]
            return fan.get_watchdog_status()
        else:
            return "N/A"

    def enable_fan_watchdog(self, enable=True, timeout_sec=10):
        """
        Enable Fan watchdog

        @return 0 for success, -1 for failure
        """
        list_temp = self.chas.fan_list
        if list_temp:
            fan = list_temp[0]
            return fan.enable_watchdog(enable, timeout_sec)
        else:
            return -1

    def feed_fan_watchdog(self, pwm):
        """
        Feed watchdog

        @param pwm duty cycle, unit is 1%, -1 for failure

        @return 0 for success, -1 for failure
        """
        if pwm < 0 or pwm > 100:
            return -1

        fan_list = self.chas.fan_list
        if not fan_list:
            return -1

        if fan_list is None:
            return -1

        for fan in fan_list:
            ret = fan.feed_watchdog(pwm)
            if ret is False:
                return -1

        return 0

    def set_fan_led(self, fan_name, color, blink=False):
        """
        Set fan LED

        @param color The color of system fan LED, "green"/"yellow"/"off"
        @param blink True for blinking, False for steady

        @return 0 for success, -1 for failure
        """
        fan = self.chas.get_fan_byname(fan_name)
        if fan is None:
            return -1

        ret = fan.set_led(color, blink)
        if ret == False:
            return -1

        return 0

    def get_fan_presence(self, fan_name):
        """
        Get a specific fan's presence status

        @return True for present, False for not present or failure
        """
        fan = self.chas.get_fan_byname(fan_name)
        if fan is None:
            return False

        return fan.present

    def get_fan_fru_info(self, fan_name):
        """
        Get specific fan's information

        @return dict for specific fan on success, None for failure
                Example return value(all keys are mandatory)
                {
                    # Properties
                    "Name": "FAN1",
                    "SN": "serial_number_example",  # 'N/A'
                    "PN": "part_number_exampple",   # 'N/A'
                    "Rotors": 2,                    # -1
                    "AirFlow": "F2B",               # 'N/A'
                    "SpeedMin": 2000,               # -1
                    "SpeedMax": 30000               # -1
                }
        """
        fan = self.chas.get_fan_byname(fan_name)
        if fan is None:
            return None

        if fan.present == False:
            return None

        fan.get_fru_info()
        fan_fru_dict = {}
        fan_fru_dict["Name"] = fan.name
        fan_fru_dict["SN"] = fan.productSerialNumber
        fan_fru_dict["PN"] = fan.productPartModelName
        fan_fru_dict["Rotors"] = fan.rotors
        fan_fru_dict["AirFlow"] = fan.AirFlow
        fan_fru_dict["SpeedMin"] = fan.SpeedMin
        fan_fru_dict["SpeedMax"] = fan.SpeedMax
        return fan_fru_dict

    def get_fan_status(self, fan_name):
        """
        Get status of specific fan

        @return dict for specific fan for success, None for failure
                Example return value(all keys are mandatory)
                {
                    "Rotor1": {
                        "Running": "no",        # 'N/A'
                        "HwAlarm": "yes",       # 'N/A'
                        "speed": 0              # -1
                    },
                    "Rotor2": {
                        "Running": "yes",
                        "HwAlarm": "no",
                        "Speed": 6800
                    }
                }
        """
        fan = self.chas.get_fan_byname(fan_name)
        if fan is None:
            return None

        if fan.present == False:
            return None

        fan_status_dict = {}
        rotorlist = fan.rotor_list
        for rotor in rotorlist:
            fan_status_dict[rotor.name] = {}
            speed = rotor.SpeedValue
            if speed != None and speed > 0:
                fan_status_dict[rotor.name]["Running"] = "yes"
            else:
                fan_status_dict[rotor.name]["Running"] = "no"

            if speed < rotor.SpeedMin or speed > rotor.SpeedMax:
                fan_status_dict[rotor.name]["HwAlarm"] = "yes"
            else:
                fan_status_dict[rotor.name]["HwAlarm"] = "no"

            fan_status_dict[rotor.name]["Speed"] = speed

        return fan_status_dict

    def get_fan_info_all(self):
        """
        Get all fans' info

        @return dict of all system fans' infor for success, None for failure
                Example return value(all keys are mandatory)
                {
                    "Number": 2,                 # -99999
                    "WatchdogStatus": "Normal",  # "Abnormal"/"N/A"
                    "FAN1": {
                        # Properties
                        "Name": FAN1,
                        "SN": "serial_number_example",  # 'N/A'
                        "PN": "part_number_exampple",   # 'N/A'
                        "Present": "yes",               # 'N/A'
                        "Rotors": 2,                    # -99999
                        "AirFlow": "F2B",               # 'N/A'

                        # Status, dynamic data
                        "Rotor1": {
                            "Running": "yes",           # 'N/A'
                            "HwAlarm": "no",            # 'N/A'
                            "Speed": 7000               # -99999
                            "SpeedMin": 2000,           # -99999
                            "SpeedMax": 30000,          # -99999
                        },
                        "Rotor2": {
                            "Running": "yes",
                            "HwAlarm": "no"
                            "Speed": 8000
                            "SpeedMin": 2000,
                            "SpeedMax": 30000,
                        }
                    },
                    "FAN2": {
                        # Properties
                        "Name": FAN2,
                        "SN": "serial_number_example",
                        "PN": "part_number_exampple",
                        "Present": "yes"
                        "Rotors": 2,
                        "AirFlow": "F2B",
                        "SpeedMin": 2000,
                        "SpeedMax": 30000,

                        # Status, dynamic data
                        "Rotor1": {
                            "Running": "no",
                            "HwAlarm": "yes",
                            "Speed": 0
                        },
                        "Rotor2": {
                            "Running": "yes",
                            "HwAlarm": "no",
                            "Speed": 6800
                        }
                    }
                }
        """
        fanlist = self.chas.fan_list
        fan_info_dict = {}
        fan_info_dict["Number"] = len(fanlist)
        fan_info_dict["WatchdogStatus"] = self.get_fan_watchdog_status()
        for fan in fanlist:
            fan.get_fru_info()
            fan_info_dict[fan.name] = {}
            fan_info_dict[fan.name]["Name"] = fan.name
            fan_info_dict[fan.name]["SN"] = fan.productSerialNumber
            fan_info_dict[fan.name]["PN"] = fan.productPartModelName
            fan_info_dict[fan.name]["Present"] = "yes" if fan.present is True else "no"
            fan_info_dict[fan.name]["Rotors"] = fan.rotors
            fan_info_dict[fan.name]["AirFlow"] = fan.AirFlow
            for rotor in fan.rotor_list:
                fan_info_dict[fan.name][rotor.name] = {}
                speed = rotor.SpeedValue
                if speed != None and speed > 0:
                    fan_info_dict[fan.name][rotor.name]["Running"] = "yes"
                else:
                    fan_info_dict[fan.name][rotor.name]["Running"] = "no"

                if speed < rotor.SpeedMin or speed > rotor.SpeedMax:
                    fan_info_dict[fan.name][rotor.name]["HwAlarm"] = "yes"
                else:
                    fan_info_dict[fan.name][rotor.name]["HwAlarm"] = "no"
                fan_info_dict[fan.name][rotor.name]["Speed"] = speed
                fan_info_dict[fan.name][rotor.name]["SpeedMin"] = rotor.SpeedMin
                fan_info_dict[fan.name][rotor.name]["SpeedMax"] = rotor.SpeedMax

        return fan_info_dict

    def get_bios_boot_status(self):
        """
        Get lastest BIOS boot status, include boot_flash and result

        @return Dict of BIOS boot status or None for failure
                Example:
                {
                    "Flash": "master",      # "slave" or 'N/A'
                    "Result": "success"     # "failed" or 'N/A'
                }
        """
        boot_status_dict = {"Flash": "N/A", "Result": "N/A"}
        bios = self.chas.get_bios_byname("master")
        if bios == None:
            return boot_status_dict

        return bios.get_bios_boot_status()

    def upgrade_bios_fw(self, flash, image):
        """
        Program BIOS flash with specific image

        @param flash 'master' or 'slave' BIOS flash
        @param image Absolute path of the BIOS image file

        @return 0 for success, -1 for failure
        """
        bios = self.chas.get_bios_byname("master")
        if bios == None:
            return -1

        return bios.program_bios_firmware(flash, image)

    def get_bios_next_boot(self):
        """
        Get next booting flash of BIOS

        @return "master"/"slave" on success, "N/A" for failure
        """
        bios = self.chas.get_bios_byname("master")
        if bios == None:
            return "N/A"

        return bios.get_bios_next_boot()

    def set_bios_next_boot(self, flash):
        """
        Set flash from which next BIOS boot

        @param flash Booting flash of BIOS, "master" or "slave"

        @return 0 on success, -1 for failure
        """
        bios = self.chas.get_bios_byname("master")
        if bios == None:
            return -1

        return bios.set_bios_next_boot(flash)

    def get_cpld_user_reg(self):
        """
        Get user register value, 1 byte value

        @return unsigned value, 1 byte, None for failure
        """
        cpld = self.chas.get_cpld_byname("BASE_CPLD")
        if cpld == None:
            return None

        return cpld.get_user_reg()

    def set_cpld_user_reg(self, value):
        """
        Set user register value, 1 byte

        @return 0 for success, -1 for failure
        """
        cpld = self.chas.get_cpld_byname("BASE_CPLD")
        if cpld == None:
            return -1
        
        return cpld.set_user_reg(value)

    def set_cpld_console_owner(self, owner):
        """
        Set console I/O owner

        @param owner I/O owner of the console, either "cpu" or "bmc"

        @return 0 for success, -1 for failure
        """
        cpld = self.chas.get_cpld_byname("BASE_CPLD")
        if cpld == None:
            return -1

        return cpld.set_console_owner(owner)

    def get_cpld_all_version(self):
        """
        Get version of all CPLDs' that can be read from BMC

        @return dict of CPLDs' version or None for failure.
                example outputs:
                {
                    "BASE_CPLD": "0.1",     # or "N/A" for read failure
                    "FAN_CPLD": "0.2"
                }
        """
        cpld_list = self.chas.cpld_list
        if not cpld_list:
            return None

        cpld_version = {}
        for index, cpld in enumerate(cpld_list):
            cpld_name = cpld.name
            if cpld_name is None:
                cpld_name = "cpld%d" % (index+1)
            cpld_version[cpld_name] = cpld.get_version()

        return cpld_version

    def get_bmc_info(self):
        """
        Get BMC info

        @return dict of BMC info or None for failure
                    "Version": "1.1.1", # "N/A"
                    "Flash": "master",  # "N/A"
                    "Next": "master"    # "N/A"
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            bmc_info_dict = {"Version": "N/A", "Flash": "N/A", "Next": "N/A"}
            return bmc_info_dict

        return bmc.get_info()

    def get_bmc_version_all(self):
        """
        @return dict of BMCs
                {
                    "MasterVersion": "1.1.1",   # "N/A"
                    "SlaveVersion": "1.1.1"     # "N/A"
                }
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            bmc_version_dict = {"MasterVersion": "N/A", "SlaveVersion": "N/A"}
            return bmc_version_dict

        return bmc.get_version_all()

    def get_bmc_boot_status(self):
        """
        Get BMC latest boot status

        @return "master"/"slave" for boot successfully from master/slave flash
                "N/A" for read failed
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return "N/A"

        return bmc.get_bmc_boot_status()

    def get_bmc_status(self):
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
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
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
            return bmc_status_dict

        return bmc.get_status()

    def get_bmc_next_boot(self):
        """
        Get next booting flash of BMC

        @return 'master'/'slave' on success, "N/A" for failure
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return "N/A"

        return bmc.get_next_boot()

    def set_bmc_next_boot(self, flash):
        """
        Set flash from which next BMC boot

        @param flash Booting flash of BMC, "master" or "slave"

        @return 0 on success, -1 for failure
        """
        if flash != "master" and flash != "slave":
            return -1

        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return -1

        return bmc.set_next_boot(flash)

    def reboot_bmc(self):
        """
        Reboot running BMC
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return -1

        return bmc.reboot()

    def upgrade_bmc_fw(self, flash, image):
        """
        Program BMC flash witch specific image

        @param flash 'master' or 'slave' BMC flash
        @param image Absolute path of BMC image file

        @return 0 for success, -1 for failure
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return -1

        return bmc.program_bmc_firmware(flash, image)

    def get_bmc_productname(self):
        """
        Get product name

        @return product name string, e.g. AS13-32H-F-$(VENDOR_NAME), if error return "N/A"
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return "N/A"

        return bmc.get_productname()

    def get_bmc_sys_eeprom(self):
        """
        Get SYSEEPROM

        @return SYSEEPROM content dict or None for failure.
                example outputs:
                {
                    "Product Name": "AS23-128H",
                    "Product Manufacturer": "Manufacturer Name",
                    "Product Serial": "ABC0123456789",
                    "Product Part Number": "P10-F0001-01"

                    # Optional keys
                }
        @note value string should be "N/A" on read failure.
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return None

        return bmc.get_sys_eeprom()

    def bmc_execute_command(self, cmd_str):
        """
        Excute user specified command string.

        @param cmd_str command string from user

        @return (0, outputs) for success, (-1, outputs) for failure.
        """
        ret, output = osutil.command(cmd_str)
        if ret == 0:
            return (0, output)
        else:
            return (-1, output)

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
        boot_status_dict = {"Flash": "N/A", "Result": "N/A"}
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return boot_status_dict
        
        return bmc.get_uboot_boot_status()

    def get_uboot_next_boot(self):
        """
        Get next booting flash of UBOOT

        @return "master"/"slave" on success, "N/A" for failure
        """
        return self.get_bmc_next_boot()

    def set_uboot_next_boot(self, flash):
        """
        Set flash from which next U-Boot boot

        @param flash Booting flash of U-Boot, "master" or "slave"

        @return 0 on success, -1 for failure
        """
        return self.set_bmc_next_boot(flash)

    def set_misc_system_fan_led(self, color, blink):
        """
        Set system fan LED color

        @param color The color of system fan LED, "green"/"yellow"/"off"
        @param blink True for blinking, False for steady

        @return 0 for success, -1 for failure
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return -1

        return bmc.set_system_fan_led(color, blink)

    def set_misc_system_led(self, color, blink):
        """
        Set system LED color, system LED indicates status of the whole system

        @param color The color of system fan LED, "green"/"yellow"/"off"
        @param blink True for blinking, False for steady

        @return 0 for success, -1 for failure
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return -1

        return bmc.set_system_led(color, blink)

    def get_misc_system_power_led_available(self):
        """
        Get system power LED availability

        @return True if available, False otherwise.
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return False

        return bmc.get_system_power_led_available()

    def set_misc_system_power_led(self, color, blink):
        """
        Set system power LED color, power LED indicates PSU, DC/DC status

        @param color The color of system fan LED, "green"/"yellow"/"off"
        @param blink True for blinking, False for steady

        @return 0 for success, -1 for failure
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return -1

        return bmc.set_system_power_led(color, blink)

    def set_misc_location_led(self, command):
        """
        Set location LED admin status

        @param cmd Control command, "on"/"off"

        @return 0 for success, -1 for failure
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return -1

        return bmc.set_location_led(command)

    def get_misc_location_led(self):
        """
        Get location LED admin status

        @return status of location LED, "on"/"off" or "N/A" for failure
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return -1

        return bmc.get_location_led()

    def get_misc_system_airflow(self):
        """
        Get system air flow.

        @return "F2B"/"B2F" on success, "N/A" for failure
        """
        bmc = self.chas.get_bmc_byname("master")
        if bmc == None:
            return "N/A"

        return bmc.get_system_airflow()

    def get_cpu_status(self):
        """
        Get CPU current status.

        @return 'S0', ..., 'S5', or 'N/A' for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return "N/A"

        return cpu.get_state()

    def get_cpu_mca_error(self):
        """
        Get CPU MCA error count.
        @return List of MCERR and IERR counts, or None for failure
                Example:
                {
                    "MCErr": 0,         # -99999
                    "IErr": 0           # -99999
                }
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return None

        return cpu.get_mca_error()

    def get_cpu_aer_error(self):
        """
        Get CPU AER error vector.

        @return List of AER error vector or None for failure
                Example:
                [ERR[0], ERR[1], ERR[2]]
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return None

        return cpu.get_aer_error()

    def get_cpu_last_reset(self):
        """
        Get last CPU reset type, WARM/COLD.
        @return Last CPU reset type, WARM/COLD, N/A for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return "N/A"

        return cpu.get_last_reset()

    def set_host_cpu_power(self, power_command):
        """
        Control host cpu power

        @param power_command Control command of host CPU's power,
                             should be "cpu on"/"cpu off"/"cpu cycle"/"cpu reset"

        @return 0 for success, -1 for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return -1

        return cpu.set_host_cpu_power(power_command)

    def get_host_cpu_power_status(self):
        """
        Get host cpu power status

        @return Power status of CPU(and affiliates), value should be
                "on"/"off", or "N/A" for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return -1

        return cpu.get_host_cpu_power_status()

    def enable_host_cpu_power_force_control(self, enable):
        """
        Force control host cpu power
        @param enable: enable/disable force control host cpu power,
                       enable: 1; disable: 0
        @return 0 for success, -1 for failure

        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return -1

        return cpu.enable_host_cpu_power_force_control(enable)

    def get_host_cpu_power_force_control_status(self):
        """
        Get force control host cpu power status
        @return 1 for enable, 0 for disable, -1 for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return -1

        return cpu.get_host_cpu_power_force_control_status()

    def enable_power_force_control(self, enable):
        """
        Force control host cpu power
        @param enable: enable/disable force control host cpu power,
                       enable: 1; disable: 0
        @return 0 for success, -1 for failure

        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return -1

        return cpu.enable_power_force_control(enable)

    def get_power_force_control_status(self):
        """
        Get force control host cpu power status
        @return 1 for enable, 0 for disable, -1 for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return -1

        return cpu.get_power_force_control_status()

    def set_switch_port_power_status(self, status):
        """
        Control switch port power
        @param status: Control switch port power,
                        should be “on”/“off”
        @return 0 for success, -1 for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return -1

        return cpu.set_switch_port_power_status(status)

    def get_switch_port_power_status(self):
        """
        @return port power status, on/off, N/A for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return "N/A"

        return cpu.get_switch_port_power_status()

    def set_switch_chip_power_status(self, status):
        """
        Control switch chip power
        @param status: Control switch chip power,
                            should be “on”/“off”
        @return 0 for success, -1 for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return -1

        return cpu.set_switch_chip_power_status(status)

    def get_switch_chip_power_status(self):
        """
        Get switch chip status
        @return switch chip power status, value should be
                            “on”/“off”, or “N/A” for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return "N/A"

        return cpu.get_switch_chip_power_status()

    def set_ssd_power_status(self, status):
        """
        Control SSD power
        @param status: Control SSD power,
                        should be “on”/“off”
        @return 0 for success, -1 for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return -1

        return cpu.set_ssd_power_status(status)

    def get_ssd_power_status(self):
        """
        Get SSD status
        @return SSD power status, value should be
                        “on”/“off”, or “N/A” for failure
        """
        cpu = self.chas.get_cpu_byname("cpu")
        if cpu == None:
            return "N/A"

        return cpu.get_ssd_power_status()
