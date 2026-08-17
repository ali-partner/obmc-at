###############################################################################
#
# Hardware Abstraction Layer APIs -- Temperature APIs.
#
# Copyright (C) Alibaba, INC.
#
###############################################################################
from plat_hal.interface import interface

HAL_DCDC_SENSOR = "DCDC_SENSORS"

"""
class for HAL DC/DC APIs.
"""

class HalDcdc(object):
    def __init__(self, sensor_obj):
        """
        @param sensor_obj Instance of HalSensor from hal_sensor module
        """
        self.sensors = sensor_obj
        self.int_case = interface()

    def get_dcdc_sensors(self):
        sensor_dict = None
        if HAL_DCDC_SENSOR in self.sensors.config:
            dcdc_sensors = self.sensors.config[HAL_DCDC_SENSOR]
            sensor_dict = {}
            for name in dcdc_sensors:
                sensor_dict[name] = dcdc_sensors[name]

        return sensor_dict

    def get_dcdc_sensor_value(self, name):
        """
        Get DCDC sonsor.

        @return voltage_dict for DCDC or None for failure
        """
        return self.int_case.get_monitor_dcdc(name)

    def get_dcdc_sensor_descr(self, name):
        """
        Get DCDC sensor's description.

        @return description string or None for failure
        """
        if name in self.sensors.config[HAL_DCDC_SENSOR]:
            sensor = self.sensors.config[HAL_DCDC_SENSOR][name]
            return sensor["Descr"]
        else:
            return None

    def get_dcdc_all_info(self):
        """
        Get all DCDC sensor info

        @return dict for all DCDC info or None for failure
        """
        return self.int_case.get_dcdc_all_info()
