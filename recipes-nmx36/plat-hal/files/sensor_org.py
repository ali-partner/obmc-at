# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/sensor.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 4473 bytes
from .devicebase import devicebase

class sensor(devicebase):
    _sensor__Name = None
    _sensor__Value = None
    _sensor__Min = None
    _sensor__Max = None
    _sensor__ValueConfig = None
    _sensor__Unit = None
    _sensor__format = None
    _sensor__Min_config = None
    _sensor__Max_config = None

    @property
    def name(self):
        return self._sensor__Name

    @name.setter
    def name(self, val):
        self._sensor__Name = val

    @property
    def Min_config(self):
        return self._sensor__Min_config

    @Min_config.setter
    def Min_config(self, val):
        self._sensor__Min_config = val

    @property
    def Max_config(self):
        return self._sensor__Max_config

    @Max_config.setter
    def Max_config(self, val):
        self._sensor__Max_config = val

    @property
    def Unit(self):
        return self._sensor__Unit

    @Unit.setter
    def Unit(self, val):
        self._sensor__Unit = val

    @property
    def format(self):
        return self._sensor__format

    @format.setter
    def format(self, val):
        self._sensor__format = val

    @property
    def ValueConfig(self):
        return self._sensor__ValueConfig

    @ValueConfig.setter
    def ValueConfig(self, val):
        self._sensor__ValueConfig = val

    def get_command_value(self, namestr, cmdstr):
        retcode, output = self.command(cmdstr)
        if retcode != 0:
            return (False, output)

        if namestr == "CPU_TEMP":
            data = output.split("The CPU temperature:", 1)[-1].strip()
            value = int(float(data))
            return (True, value)
        elif namestr == "SWITCH_TEMP":
            data = output.split("The MAC temperature:", 1)[-1].strip()
            value = int(data)
            return (True, value)
        else:
            return (True, output)

    @property
    def Value(self):
        try:
            config = self.ValueConfig
            way = config.get("way")
            if way == "sysfs":
                loc_config = config.get("real_loc", None)
                if loc_config is None:
                    ret, ind = self.find_real_file_path(config.get("loc"))
                    loc_config = ind if ret is True else None
                    self.ValueConfig["real_loc"] = loc_config
                ret, val = self.read_real_sysfs(loc_config)
            elif way == "command":
                cmd_line = config.get("loc")
                sensor_name = self.name
                ret, val = self.get_command_value(sensor_name, cmd_line)

            if ret is False:
                raise Exception(str(val))

            if self.format is None:
                self._sensor__Value = int(val)
            else:
                self._sensor__Value = eval(self.format % val)

            if self._sensor__Value <= -9999:
                raise Exception("value is illegal")
        except:
            self._sensor__Value = None
            return self._sensor__Value

        return self._sensor__Value

    @Value.setter
    def Value(self, val):
        self._sensor__Value = val

    @property
    def Min(self):
        self._sensor__Min = self.Min_config
        return self._sensor__Min

    @Min.setter
    def Min(self, val):
        self._sensor__Min = val

    @property
    def Max(self):
        self._sensor__Max = self.Max_config
        return self._sensor__Max

    @Max.setter
    def Max(self, val):
        self._sensor__Max = val

    def __init__(self, conf=None):
        self.ValueConfig = conf.get("value", None)
        self.Min_config = conf.get("Min", None)
        self.Max_config = conf.get("Max", None)
        self.Unit = conf.get("Unit", None)
        self.format = conf.get("format", None)
        self.name = conf.get("name", None)

    def __str__(self):
        formatstr = "ValueConfig:                : %s \nMin :          %s \nMax : %s \nUnit  : %s \nformat:       : %s \n"
        sensor_str = formatstr % (self.ValueConfig, self.Min,
         self.Max, self.Unit,
         self.format)
        return sensor_str
