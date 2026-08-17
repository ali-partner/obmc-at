# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/chassisbase.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 9618 bytes
from .psu import psu
from .fan import fan
from .bmc import bmc
from .cpu import cpu
from .cpld import cpld
from .bios import bios
from .sensor import sensor
from .baseutil import baseutil

class chassisbase:
    _chassisbase__temp_list = []
    _chassisbase__dcdc_list = []
    _chassisbase__psu_list = []
    _chassisbase__fan_list = []
    _chassisbase__bios_list = []
    _chassisbase__cpld_list = []
    _chassisbase__bmc_list = []
    _chassisbase__cpu = None

    def __init__(self, conftype=0, conf=None):
        """
        init chassisbase as order

        type  = 0  use default conf, maybe auto find by platform
        type  = 1  use given conf,  conf is not None

        BITMAP
              bit 16
                      bit 0    PSU
                      bit 1    LED
                      bit 2    TEMP
                      bit 3    fan
                      bit 4    card
                      bit 5    sensor
        """
        _chassisbase__confTemp = None
        if conftype == 0:
            _chassisbase__confTemp = baseutil.get_config()
        elif conftype == 1:
            _chassisbase__confTemp = conf

        temptemp = []
        tempconfig = _chassisbase__confTemp.get("temps")
        for i in range(len(tempconfig)):
            temp1 = sensor(tempconfig[i])
            temptemp.append(temp1)
        self.temp_list = temptemp

        dcdctemp = []
        dcdcconfig = _chassisbase__confTemp.get("dcdc")
        for i in range(len(dcdcconfig)):
            dcdc1 = sensor(dcdcconfig[i])
            dcdctemp.append(dcdc1)
        self.dcdc_list = dcdctemp

        psutemp = []
        psuconfig = _chassisbase__confTemp.get("psus")
        for i in range(len(psuconfig)):
            psu1 = psu(psuconfig[i])
            psutemp.append(psu1)
        self.psu_list = psutemp

        fantemp = []
        fanconfig = _chassisbase__confTemp.get("fans")
        for i in range(len(fanconfig)):
            fan1 = fan(fanconfig[i])
            fantemp.append(fan1)
        self.fan_list = fantemp

        biostemp = []
        biosconfig = _chassisbase__confTemp.get("bioss")
        for i in range(len(biosconfig)):
            bios1 = bios(biosconfig[i])
            biostemp.append(bios1)
        self.bios_list = biostemp

        cpldtemp = []
        cpldconfig = _chassisbase__confTemp.get("cplds")
        for i in range(len(cpldconfig)):
            cpld1 = cpld(cpldconfig[i])
            cpldtemp.append(cpld1)
        self.cpld_list = cpldtemp

        bmctemp = []
        bmcconfig = _chassisbase__confTemp.get("bmcs")
        for i in range(len(bmcconfig)):
            bmc1 = bmc(bmcconfig[i])
            bmctemp.append(bmc1)
        self.bmc_list = bmctemp

        cpuconfig = _chassisbase__confTemp.get("cpu")
        self.cpu = cpu(cpuconfig[0])

    @property
    def temp_list(self):
        return self._chassisbase__temp_list

    @temp_list.setter
    def temp_list(self, val):
        self._chassisbase__temp_list = val

    def get_temp_byname(self, name):
        tmp = self.temp_list
        for i in range(len(tmp)):
            if name == tmp[i].name:
                return tmp[i]

    @property
    def dcdc_list(self):
        return self._chassisbase__dcdc_list

    @dcdc_list.setter
    def dcdc_list(self, val):
        self._chassisbase__dcdc_list = val

    def get_dcdc_byname(self, name):
        tmp = self.dcdc_list
        for i in range(len(tmp)):
            if name == tmp[i].name:
                return tmp[i]

    @property
    def psu_list(self):
        return self._chassisbase__psu_list

    @psu_list.setter
    def psu_list(self, val):
        self._chassisbase__psu_list = val

    def get_psu_byname(self, name):
        tmp = self.psu_list
        for i in range(len(tmp)):
            if name == tmp[i].name:
                return tmp[i]

    @property
    def fan_list(self):
        return self._chassisbase__fan_list

    @fan_list.setter
    def fan_list(self, val):
        self._chassisbase__fan_list = val

    def get_fan_byname(self, name):
        tmp = self.fan_list
        for i in range(len(tmp)):
            if name == tmp[i].name:
                return tmp[i]

    @property
    def bios_list(self):
        return self._chassisbase__bios_list

    @bios_list.setter
    def bios_list(self, val):
        self._chassisbase__bios_list = val

    def get_bios_byname(self, name):
        tmp = self.bios_list
        for i in range(len(tmp)):
            if name == tmp[i].name:
                return tmp[i]

    @property
    def cpld_list(self):
        return self._chassisbase__cpld_list

    @cpld_list.setter
    def cpld_list(self, val):
        self._chassisbase__cpld_list = val

    def get_cpld_byname(self, name):
        tmp = self.cpld_list
        for i in range(len(tmp)):
            if name == tmp[i].name:
                return tmp[i]

    @property
    def bmc_list(self):
        return self._chassisbase__bmc_list

    @bmc_list.setter
    def bmc_list(self, val):
        self._chassisbase__bmc_list = val

    def get_bmc_byname(self, name):
        tmp = self.bmc_list
        for i in range(len(tmp)):
            if name == tmp[i].name:
                return tmp[i]

    @property
    def cpu(self):
        return self._chassisbase__cpu

    @cpu.setter
    def cpu(self, val):
        self._chassisbase__cpu = val

    def get_cpu_byname(self, name):
        return self.cpu