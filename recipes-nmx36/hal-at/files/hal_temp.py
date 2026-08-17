###############################################################################
#
# Hardware Abstraction Layer APIs -- Temperature APIs.
#
# Copyright (C) Alibaba, INC.
#
###############################################################################
#from plat_hal.interface import interface

HAL_TEMP_SENSOR = "TEMPERATURE_SENSORS"
HAL_TEMP_CPU = "CPU_TEMP"
HAL_TEMP_INLET = "INLET_TEMP"
HAL_TEMP_SWITCH = "SWITCH_TEMP"

"""
class for HAL temperature APIs.

@param temp_dict Dictionary of temperature, in Celcius degress and floating
                 point number.
                 Example:
                 {
                     "Value": 30.0,     # -99999.0
                     "Min": -10.0,      # -99999.0
                     "Max": 50.0        # -99999.0
                 }
"""

class HalTemperature(object):
    def __init__(self, sensor_obj):
        """
        @param sensor_obj Instance of HalSensor from hal_sensor module

        @note Raise Exception when temperature sensors' name map is not
              loaded successfully
        """
        self.sensors = sensor_obj
        #self.int_case = interface()
        self.temp_name = [HAL_TEMP_CPU, HAL_TEMP_INLET, HAL_TEMP_SWITCH]
        self.temp_name_maps = {}
        if self.load_temp_sensors() != 0:
            raise Exception("Invalid temperature sensors configuration")

    def load_temp_sensors(self):
        """
        Load temperature sensors' map

        @return 0 for success, -1 for failure
        """
        if HAL_TEMP_SENSOR not in self.sensors.config:
            return -1

        temp_sensor_dict = self.sensors.config[HAL_TEMP_SENSOR]
        for name in self.temp_name:
            if name not in temp_sensor_dict:
                return -1
            self.temp_name_maps[name] = temp_sensor_dict[name]

        return 0

    def get_cpu_temp(self):
        """
        Get CPU temperature.

        @return temp_dict for tempperature or None for failure
        """
        name = self.temp_name_maps[HAL_TEMP_CPU]["Name"]
        #return self.int_case.get_monitor_temp(name)
        return self.sensors.get_sensor(name)

    def get_inlet_temp(self):
        """
        Get Inlet temperature.

        @return temp_dict for tempperature or None for failure
        """
        name = self.temp_name_maps[HAL_TEMP_INLET]["Name"]
        #return self.int_case.get_monitor_temp(name)
        return self.sensors.get_sensor(name)

    def get_switch_temp(self):
        """
        Get Switch ASIC temperature.

        @return temp_dict for tempperature or None for failure
        """
        name = self.temp_name_maps[HAL_TEMP_SWITCH]["Name"]
        #return self.int_case.get_monitor_temp(name)
        return self.sensors.get_sensor(name)
