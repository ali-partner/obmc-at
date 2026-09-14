# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/fan.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 11508 bytes
from .devicebase import devicebase
from .rotor import rotor
from plat_hal.smbus import SMBus

class fan(devicebase):
    _fan__rotor_list = []
    _fan__rotors = None
    _fan__AirFlow = None
    _fan__present = None
    _fan__SpeedMin = None
    _fan__SpeedMax = None
    _fan__SpeedPWM = None
    _fan__SpeedPWMConfig = None
    _fan__productName = None
    _fan__productSerialNumber = None
    _fan__productPartModelName = None
    _fan__EnableWatchdogConf = None
    _fan__Rotor_config = None

    def __init__(self, conf=None):
        if conf is not None:
            self.name = conf.get("name", None)
            self.SpeedMin = conf.get("SpeedMin", None)
            self.SpeedMax = conf.get("SpeedMax", None)
            self.SpeedPWMConfig = conf.get("SpeedPWM", None)
            self.AirFlowconfig = conf.get("airflow", None)
            self.PresentConfig = conf.get("present", None)
            self.EnableWatchdogConf = conf.get("EnableWatchdogConf", None)
            self.EnableWatchdogAttr = conf.get("EnableWatchdogAttr", None)
            self.WatchdogNormal = conf.get("WatchdogNormal", None)
            self.WatchdogTimeout = conf.get("WatchdogTimeout", None)
            self.led_attrs_config = conf.get("led_attrs", None)
            self.led_config = conf.get("led", None)
            self.Rotor_config = conf.get("Rotor", None)
            self.smbus_obj = SMBus(conf.get("i2cbus", None))
            rotor_tmp = []
            for key, value in self.Rotor_config.items():
                rotor_tmp.append(rotor(value, self.smbus_obj))

            rotor_tmp.sort(key=(lambda x: x.name), reverse=False)
            self.rotor_list = rotor_tmp
            self.rotors = len(self.rotor_list)


    @property
    def SpeedMin(self):
        return self._fan__SpeedMin

    @SpeedMin.setter
    def SpeedMin(self, val):
        self._fan__SpeedMin = val

    @property
    def SpeedMax(self):
        return self._fan__SpeedMax

    @SpeedMax.setter
    def SpeedMax(self, val):
        self._fan__SpeedMax = val

    @property
    def SpeedPWMConfig(self):
        return self._fan__SpeedPWMConfig

    @SpeedPWMConfig.setter
    def SpeedPWMConfig(self, val):
        self._fan__SpeedPWMConfig = val

    @property
    def AirFlow(self):
        fru = self.get_fru_basic_info(self.name.lower())
        productName = fru.get("Product Name", "N/A")
        if productName.endswith("-F"):
            self._fan__AirFlow = "F2B"
        elif productName.endswith("-B"):
            self._fan__AirFlow = "B2F"
        else:
            self._fan__AirFlow = "N/A"

        return self._fan__AirFlow

    @AirFlow.setter
    def AirFlow(self, val):
        self._fan__AirFlow = val

    @property
    def present(self):
        ret, val = self.get_i2cbits_by_smbus(self.smbus_obj, self.PresentConfig)
        if ret == False:
            self._fan__present = False

        if val == 0:
            self._fan__present = True
        else:
            self._fan__present = False

        return self._fan__present

    @present.setter
    def present(self, val):
        self._fan__present = val

    @property
    def EnableWatchdogConf(self):
        return self._fan__EnableWatchdogConf

    @EnableWatchdogConf.setter
    def EnableWatchdogConf(self, val):
        self._fan__EnableWatchdogConf = val

    @property
    def rotor_list(self):
        return self._fan__rotor_list

    @rotor_list.setter
    def rotor_list(self, val):
        self._fan__rotor_list = val

    @property
    def rotors(self):
        return self._fan__rotors

    @rotors.setter
    def rotors(self, val):
        self._fan__rotors = val

    @property
    def Rotor_config(self):
        return self._fan__Rotor_config

    @Rotor_config.setter
    def Rotor_config(self, val):
        self._fan__Rotor_config = val

    @property
    def productName(self):
        return self._fan__productName

    @productName.setter
    def productName(self, val):
        self._fan__productName = val

    @property
    def productSerialNumber(self):
        return self._fan__productSerialNumber

    @productSerialNumber.setter
    def productSerialNumber(self, val):
        self._fan__productSerialNumber = val

    @property
    def productPartModelName(self):
        return self._fan__productPartModelName

    @productPartModelName.setter
    def productPartModelName(self, val):
        self._fan__productPartModelName = val

    def get_fru_info(self):
        try:
            fru = self.get_fru_basic_info(self.name.lower())
            self.productName = fru.get("Product Name", "N/A")
            self.productSerialNumber = fru.get("Board Serial", "N/A")
            self.productPartModelName = fru.get("Product Part Number", "N/A")
        except Exception as e:
            self.productName = "N/A"
            self.productSerialNumber = "N/A"
            self.productPartModelName = "N/A"
            return False

        return True

    def get_rotor_index(self, rotor_index):
        if rotor_index > len(self.rotor_list):
            return None

        rotor = self.rotor_list[rotor_index - 1]
        return rotor

    def get_speed(self, rotor_index):
        rotor = self.get_rotor_index(rotor_index)
        if rotor is None:
            return None

        return rotor.SpeedValue

    def set_speed(self, rotor_index, speed):
        rotor = self.get_rotor_index(rotor_index)
        if rotor is None:
            return False

        SpeedMin = rotor.SpeedMin
        SpeedMax = rotor.SpeedMax
        if speed > SpeedMax or speed < SpeedMin:
            return False

        pwm = speed * 100 // SpeedMax
        reg_val = int(pwm * 255 / 100);
        ret = self.set_i2cbits_by_smbus(self.smbus_obj, self.SpeedPWMConfig, reg_val)
        return ret

    def get_speed_pwm(self, rotor_index):
        rotor = self.get_rotor_index(rotor_index)
        if rotor is None:
            return None

        ret, value = self.get_i2cbits_by_smbus(self.smbus_obj, self.SpeedPWMConfig)
        if ret == False:
            self._fan__SpeedPWM = None
        else:
            self._fan__SpeedPWM = int((value + 2) * 100 / 256);

        return self._fan__SpeedPWM

    def set_speed_pwm(self, rotor_index, pwm):
        """
        Set PWM for specific fan's specific rotor

        @param pwm duty cycle, unit is 1%, -1 for failure

        @return 0 for success, -1 for failure
        """
        rotor = self.get_rotor_index(rotor_index)
        if rotor is None:
            return False

        if pwm < 0 or pwm > 100:
            return False
        reg_val = int(pwm * 255 / 100);
        ret = self.set_i2cbits_by_smbus(self.smbus_obj, self.SpeedPWMConfig, reg_val)
        return ret

    def get_watchdog_status(self):
        """
        Get Fan watchdog status.

        @return 'Normal'/'Abnormal'/'N/A' for status good/bad/read-failed.
        """
        ret_normal, val_normal = self.get_i2cbits_by_smbus(self.smbus_obj, self.WatchdogNormal)
        ret_timeout, val_timeout = self.get_i2cbits_by_smbus(self.smbus_obj, self.WatchdogTimeout)
        ret_enable, val_enable = self.get_i2cbits_by_smbus(self.smbus_obj, self.EnableWatchdogConf)
        if ret_normal == False or ret_timeout == False or ret_enable == False:
            return "N/A"
        if val_enable == 0:
            watchdog_st = "Normal"
        elif val_enable == 1:
            if val_normal == 0 and val_timeout == 1:
                watchdog_st = "Normal"
            elif val_normal == 1 and val_timeout == 0:
                watchdog_st = "Abnormal"
            else:
                watchdog_st = "N/A"
        else:
            watchdog_st = "N/A"
        return watchdog_st

    def enable_watchdog(self, enable, timeout_sec):
        """
        Enable Fan watchdog

        @return 0 for success, -1 for failure
        """
        if enable == True:
            value = self.EnableWatchdogAttr.get("enable", None)
        elif enable == False:
            value = self.EnableWatchdogAttr.get("disable", None)
        else:
            return -1

        ret = self.set_i2cbits_by_smbus(self.smbus_obj, self.EnableWatchdogConf, value)
        if ret != True:
            return -1

        return 0

    def feed_watchdog(self, pwm):
        """
        Feed watchdog

        @param pwm duty cycle, unit is 1%, -1 for failure

        @return 0 for success, -1 for failure
        """
        if pwm < 0 or pwm > 100:
            return False
        reg_val = int(pwm * 255 / 100);
        ret = self.set_i2cbits_by_smbus(self.smbus_obj, self.SpeedPWMConfig, reg_val)
        return ret

    def set_led(self, color, blink):
        """
        Set fan LED

        @param color The color of system fan LED, "green"/"yellow"/"off"
        @param blink True for blinking, False for steady

        @return 0 for success, -1 for failure
        """
        if self.present == False:
            return False

        status = self.led_attrs_config.get(color, None)
        if status == None:
            return False

        if blink == True:
            led_state = self.led_attrs_config[color].get("blink", None)
        elif blink == False:
            led_state = self.led_attrs_config[color].get("steady", None)
        if led_state == None:
            return False

        ret = self.set_i2cbits_by_smbus(self.smbus_obj, self.led_config, led_state)
        return ret

    def get_rotor_byname(self, rotor_index):
        for rotor in self.rotor_list:
            if rotor.name == rotor_index:
                return rotor
