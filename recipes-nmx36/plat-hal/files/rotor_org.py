# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/rotor.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 4073 bytes
from .devicebase import devicebase
from plat_hal.smbus import SMBus

class rotor(devicebase):
    _rotor__SpeedMin = None
    _rotor__SpeedMax = None
    _rotor__SpeedUnit = None
    _rotor__SpeedValueConfig = None
    _rotor__SpeedValue = None

    def __init__(self, conf=None, smbus_obj=None):
        self.name = conf.get("name", None)
        self.SpeedMin = conf.get("SpeedMin", None)
        self.SpeedMax = conf.get("SpeedMax", None)
        self.SpeedUnit = conf.get("SpeedUnit", None)
        self.SpeedValueConfig = conf.get("SpeedValue", None)
        self.smbus_obj = smbus_obj

    @property
    def SpeedMin(self):
        return self._rotor__SpeedMin

    @SpeedMin.setter
    def SpeedMin(self, val):
        self._rotor__SpeedMin = val

    @property
    def SpeedMax(self):
        return self._rotor__SpeedMax

    @SpeedMax.setter
    def SpeedMax(self, val):
        self._rotor__SpeedMax = val

    @property
    def SpeedUnit(self):
        return self._rotor__SpeedUnit

    @SpeedUnit.setter
    def SpeedUnit(self, val):
        self._rotor__SpeedUnit = val

    @property
    def SpeedValueConfig(self):
        return self._rotor__SpeedValueConfig

    @SpeedValueConfig.setter
    def SpeedValueConfig(self, val):
        self._rotor__SpeedValueConfig = val

    @property
    def SpeedValue(self):
        ret, val_l = self.get_i2cbits_by_smbus(self.smbus_obj, self.SpeedValueConfig)
        if ret == False:
            self._rotor__SpeedValue = None
            return self._rotor__SpeedValue
        offset =  self.SpeedValueConfig.get("offset")
        self.SpeedValueConfig["offset"] = offset + 1
        ret, val_h = self.get_i2cbits_by_smbus(self.smbus_obj, self.SpeedValueConfig)
        if ret == False:
            self._rotor__SpeedValue = None
            return self._rotor__SpeedValue
        self.SpeedValueConfig["offset"] = offset
        
        val = (val_h << 8) + val_l;
        self._rotor__SpeedValue = int(60000000 / (val * 2 * 2))
        return self._rotor__SpeedValue

    @SpeedValue.setter
    def SpeedValue(self, val):
        self._rotor__SpeedValue = val

