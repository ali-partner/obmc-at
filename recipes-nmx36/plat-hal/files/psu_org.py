# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/psu.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 32827 bytes
from .devicebase import devicebase
from .sensor import sensor
from plat_hal.smbus import SMBus

class psu(devicebase):
    _psu__present = None
    _psu__productManufacturer = None
    _psu__productName = None
    _psu__productPartModelName = None
    _psu__productVersion = None
    _psu__productSerialNumber = None
    _psu__AirFlow = None
    _psu__AirFlowconfig = None
    _psu__InputStatus_config = None
    _psu__OutputStatus_config = None
    _psu__FanSpeed_config = None
    _psu__Temperature_config = None
    _psu__InputStatus = None
    _psu__OutputStatus = None
    _psu__FanSpeed = None
    _psu__Temperature = None
    _psu__InputsVoltage_config = None
    _psu__InputsCurrent_config = None
    _psu__InputsPower_config = None
    _psu__OutputsVoltage_config = None
    _psu__OutputsCurrent_config = None
    _psu__OutputsPower_config = None
    _psu__InputsVoltage = None
    _psu__InputsCurrent = None
    _psu__InputsPower = None
    _psu__OutputsVoltage = None
    _psu__OutputsCurrent = None
    _psu__OutputsPower = None
    _psu__InputsType_config = None
    _psu__InputsType = None
    _psu__PowerOn_config = None
    _psu__PowerOn = None
    _psu__FanSpeedPWM_config = None
    _psu__FanSpeedPWM = None

    def __init__(self, conf=None):
        self.name = conf.get("name", None)
        self._psu__present_config = conf.get("present", None)
        self._psu__productManufacturer_config = conf.get("PM", None)
        self._psu__productName_config = conf.get("PN", None)
        self._psu__productPartModelName_config = conf.get("PPN", None)
        self._psu__productVersion_config = conf.get("PV", None)
        self._psu__productSerialNumber_config = conf.get("SN", None)
        self.AirFlowconfig = conf.get("airflow", None)
        self.FanSpeed_config = conf.get("FanSpeed", None)
        self.FanSpeed = sensor(self.FanSpeed_config)
        self.Temperature_config = conf.get("Temperature", None)
        self.Temperature = sensor(self.Temperature_config)
        self._psu__InputsVoltage_config = conf.get("InputsVoltage", None)
        self.InputsVoltage = sensor(self._psu__InputsVoltage_config)
        self._psu__InputsCurrent_config = conf.get("InputsCurrent", None)
        self.InputsCurrent = sensor(self._psu__InputsCurrent_config)
        self._psu__InputsPower_config = conf.get("InputsPower", None)
        self.InputsPower = sensor(self._psu__InputsPower_config)
        self._psu__OutputsVoltage_config = conf.get("OutputsVoltage", None)
        self.OutputsVoltage = sensor(self._psu__OutputsVoltage_config)
        self._psu__OutputsCurrent_config = conf.get("OutputsCurrent", None)
        self.OutputsCurrent = sensor(self._psu__OutputsCurrent_config)
        self._psu__OutputsPower_config = conf.get("OutputsPower", None)
        self.OutputsPower = sensor(self._psu__OutputsPower_config)
        self._psu__InputStatus_config = conf.get("InputsStatus", None)
        self._psu__OutputStatus_config = conf.get("OutputsStatus", None)
        self._psu__InputsType_config = conf.get("InputsType", None)
        self._psu__PowerOn_config = conf.get("PowerOnStatus", None)
        self._psu__FanSpeedPWM_config = conf.get("FanSpeedPWM", None)
        self.smbus_obj = SMBus(conf.get("cpldi2cbus", None))


    @property
    def InputsVoltage(self):
        return self._psu__InputsVoltage

    @InputsVoltage.setter
    def InputsVoltage(self, val):
        self._psu__InputsVoltage = val

    @property
    def InputsCurrent(self):
        return self._psu__InputsCurrent

    @InputsCurrent.setter
    def InputsCurrent(self, val):
        self._psu__InputsCurrent = val

    @property
    def InputsPower(self):
        return self._psu__InputsPower

    @InputsPower.setter
    def InputsPower(self, val):
        self._psu__InputsPower = val

    @property
    def OutputsVoltage(self):
        return self._psu__OutputsVoltage

    @OutputsVoltage.setter
    def OutputsVoltage(self, val):
        self._psu__OutputsVoltage = val

    @property
    def OutputsCurrent(self):
        return self._psu__OutputsCurrent

    @OutputsCurrent.setter
    def OutputsCurrent(self, val):
        self._psu__OutputsCurrent = val

    @property
    def OutputsPower(self):
        return self._psu__OutputsPower

    @OutputsPower.setter
    def OutputsPower(self, val):
        self._psu__OutputsPower = val

    @property
    def InputStatus(self):
        if self.present == False:
            self._psu__InputStatus = False
            return self._psu__InputStatus

        if self.PowerOn == False:
            self._psu__InputStatus = False
            return self._psu__InputStatus

        ret, val = self.get_i2cbits_by_smbus(self.smbus_obj, self._psu__InputStatus_config)
        if ret == True and val == 1:
            self._psu__InputStatus = True
        else:
            self._psu__InputStatus = False
        return self._psu__InputStatus

    @InputStatus.setter
    def InputStatus(self, val):
        self._psu__InputStatus = val

    @property
    def InputsType(self):
        InputTypeList = ["AC", "DC"]
        ret, val = self.get_value(self._psu__InputsType_config)
        if ret == True and val in InputTypeList:
            self._psu__InputsType = val
        else:
            self._psu__InputsType = "N/A"
        return self._psu__InputsType

    @InputsType.setter
    def InputsType(self, val):
        self._psu__InputsType = val

    @property
    def OutputStatus(self):
        if self.present == False:
            self._psu__OutputStatus = False
            return self._psu__OutputStatus

        if self.PowerOn == False:
            self._psu__OutputStatus = False
            return self._psu__OutputStatus

        ret, val = self.get_i2cbits_by_smbus(self.smbus_obj, self._psu__OutputStatus_config)
        if ret == True and val == 1:
            self._psu__OutputStatus = True
        else:
            self._psu__OutputStatus = False

        return self._psu__OutputStatus

    @OutputStatus.setter
    def OutputStatus(self, val):
        self._psu__OutputStatus = val

    @property
    def FanSpeed(self):
        return self._psu__FanSpeed

    @FanSpeed.setter
    def FanSpeed(self, val):
        self._psu__FanSpeed = val

    @property
    def FanSpeed_config(self):
        return self._psu__FanSpeed_config

    @FanSpeed_config.setter
    def FanSpeed_config(self, val):
        self._psu__FanSpeed_config = val

    @property
    def Temperature(self):
        return self._psu__Temperature

    @Temperature.setter
    def Temperature(self, val):
        self._psu__Temperature = val

    @property
    def Temperature_config(self):
        return self._psu__Temperature_config

    @Temperature_config.setter
    def Temperature_config(self, val):
        self._psu__Temperature_config = val

    @property
    def AirFlow(self):
        if self.AirFlowconfig == None:
            self._psu__AirFlow = "N/A"
        else:
            self._psu__AirFlow = self.AirFlowconfig
        return self._psu__AirFlow

    @AirFlow.setter
    def AirFlow(self, val):
        self._psu__AirFlow = val

    @property
    def AirFlowconfig(self):
        return self._psu__AirFlowconfig

    @AirFlowconfig.setter
    def AirFlowconfig(self, val):
        self._psu__AirFlowconfig = val

    @property
    def present(self):
        ret, val = self.get_i2cbits_by_smbus(self.smbus_obj, self._psu__present_config)
        if ret == True and val == 0:
            self._psu__present = True
        else:
            self._psu__present = False

        return self._psu__present

    @present.setter
    def present(self, val):
        self._psu__present = val

    @property
    def PowerOn(self):
        ret, val = self.get_i2cbits_by_smbus(self.smbus_obj, self._psu__PowerOn_config)
        if ret == True and val == 0:
            return True
        else:
            return False

    @PowerOn.setter
    def PowerOn(self, val):
        self._psu__PowerOn = val

    @property
    def FanSpeedPWM(self):
        ret, val = self.get_value(self._psu__FanSpeedPWM_config)
        if ret == True:
            self._psu__FanSpeedPWM = val/1000
        else:
            self._psu__FanSpeedPWM = -1
        return self._psu__FanSpeedPWM

    @FanSpeedPWM.setter
    def FanSpeedPWM(self, val):
        self._psu__FanSpeedPWM = val

    @property
    def productManufacturer(self):
        ret, val = self.get_value(self._psu__productManufacturer_config)
        if ret == True and len(val) != 0:
            self._psu__productManufacturer = val
        else:
            self._psu__productManufacturer = "N/A"
        return self._psu__productManufacturer

    @productManufacturer.setter
    def productManufacturer(self, val):
        self._psu__productManufacturer = val

    @property
    def productName(self):
        ret, val = self.get_value(self._psu__productName_config)
        if ret == True and len(val) != 0:
            self._psu__productName = val
        else:
            self._psu__productName = "N/A"
        return self._psu__productName

    @productName.setter
    def productName(self, val):
        self._psu__productName = val

    @property
    def productPartModelName(self):
        ret, val = self.get_value(self._psu__productPartModelName_config)
        if ret == True and len(val) != 0:
            self._psu__productPartModelName = val
        else:
            self._psu__productPartModelName = "N/A"
        return self._psu__productPartModelName

    @productPartModelName.setter
    def productPartModelName(self, val):
        self._psu__productPartModelName = val

    @property
    def productVersion(self):
        ret, val = self.get_value(self._psu__productVersion_config)
        if ret == True and len(val) != 0:
            self._psu__productVersion = val
        else:
            self._psu__productVersion = "N/A"
        return self._psu__productVersion

    @productVersion.setter
    def productVersion(self, val):
        self._psu__productVersion = val

    @property
    def productSerialNumber(self):
        ret, val = self.get_value(self._psu__productSerialNumber_config)
        if ret == True and len(val) != 0:
            self._psu__productSerialNumber = val
        else:
            self._psu__productSerialNumber = "N/A"
        return self._psu__productSerialNumber

    @productSerialNumber.setter
    def productSerialNumber(self, val):
        self._psu__productSerialNumber = val

    @property
    def psu_temp_dict(self):
        self._psu__psu_temp_dict = {}
        try:
            self._psu__psu_temp_dict["Min"] = self.Temperature.Min
            self._psu__psu_temp_dict["Max"] = self.Temperature.Max
            self._psu__psu_temp_dict["Value"] = self.Temperature.Value
        except Exception as e:
            self._psu__psu_temp_dict = None

        return self._psu__psu_temp_dict

    @psu_temp_dict.setter
    def psu_temp_dict(self, val):
        self._psu__psu_temp_dict = val

    @property
    def psu_temp_sensor_dict(self):
        self._psu__psu_temp_sensor_dict = {}
        try:
            self._psu__psu_temp_sensor_dict["Min"] = self.Temperature.Min
            self._psu__psu_temp_sensor_dict["Max"] = self.Temperature.Max
            self._psu__psu_temp_sensor_dict["Value"] = self.Temperature.Value
            self._psu__psu_temp_sensor_dict["Unit"] = self.Temperature.Unit
        except Exception as e:
            self._psu__psu_temp_sensor_dict = None

        return self._psu__psu_temp_sensor_dict

    @psu_temp_sensor_dict.setter
    def psu_temp_sensor_dict(self, val):
        self._psu__psu_temp_sensor_dict = val

    @property
    def psu_fanspeed_dict(self):
        self._psu__psu_fanspeed_dict = {}
        try:
            self._psu__psu_fanspeed_dict["Min"] = self.FanSpeed.Min
            self._psu__psu_fanspeed_dict["Max"] = self.FanSpeed.Max
            self._psu__psu_fanspeed_dict["Value"] = self.FanSpeed.Value
        except Exception as e:
            self._psu__psu_fanspeed_dict = None

        return self._psu__psu_fanspeed_dict

    @psu_fanspeed_dict.setter
    def psu_fanspeed_dict(self, val):
        self._psu__psu_fanspeed_dict = val

    @property
    def psu_fanspeed_sensor_dict(self):
        self._psu__psu_fanspeed_sensor_dict = {}
        try:
            self._psu__psu_fanspeed_sensor_dict["Min"] = self.FanSpeed.Min
            self._psu__psu_fanspeed_sensor_dict["Max"] = self.FanSpeed.Max
            self._psu__psu_fanspeed_sensor_dict["Value"] = self.FanSpeed.Value
            self._psu__psu_fanspeed_sensor_dict["Unit"] = self.FanSpeed.Unit
        except Exception as e:
            self._psu__psu_fanspeed_sensor_dict = None

        return self._psu__psu_fanspeed_sensor_dict

    @psu_fanspeed_sensor_dict.setter
    def psu_fanspeed_sensor_dict(self, val):
        self._psu__psu_fanspeed_sensor_dict = val

    @property
    def psu_input_voltage_dict(self):
        self._psu__psu_input_voltage_dict = {}
        try:
            self._psu__psu_input_voltage_dict["Value"] = self.InputsVoltage.Value
            if(self._psu__InputsType == 'N/A'):
                self._psu__psu_input_voltage_dict["LowAlarm"] = -99999
                self._psu__psu_input_voltage_dict["HighAlarm"] = -99999
            elif(self._psu__InputsType == 'AC'):
                self._psu__psu_input_voltage_dict["LowAlarm"] = 90
                self._psu__psu_input_voltage_dict["HighAlarm"] = 264
            elif(self._psu__InputsType == 'DC'):
                self._psu__psu_input_voltage_dict["LowAlarm"] = 180
                self._psu__psu_input_voltage_dict["HighAlarm"] = 320
            else:
                self._psu__psu_input_voltage_dict["LowAlarm"] = -99999
                self._psu__psu_input_voltage_dict["HighAlarm"] = -99999
            self._psu__psu_input_voltage_dict["Unit"] = self.InputsVoltage.Unit
        except Exception as e:
            self._psu__psu_input_voltage_dict = None

        return self._psu__psu_input_voltage_dict

    @psu_input_voltage_dict.setter
    def psu_input_voltage_dict(self, val):
        self._psu__psu_input_voltage_dict = val

    @property
    def psu_input_voltage_sensor_dict(self):
        self._psu__psu_input_voltage_sensor_dict = {}
        try:
            self._psu__psu_input_voltage_sensor_dict["Value"] = self.InputsVoltage.Value
            if(self._psu__InputsType == 'N/A'):
                self._psu__psu_input_voltage_sensor_dict["Min"] = -99999
                self._psu__psu_input_voltage_sensor_dict["Max"] = -99999
            elif(self._psu__InputsType == 'AC'):
                self._psu__psu_input_voltage_sensor_dict["LowAlarm"] = 90
                self._psu__psu_input_voltage_sensor_dict["HighAlarm"] = 264
            elif(self._psu__InputsType == 'DC'):
                self._psu__psu_input_voltage_sensor_dict["LowAlarm"] = 180
                self._psu__psu_input_voltage_sensor_dict["HighAlarm"] = 320
            else:
                self._psu__psu_input_voltage_sensor_dict["Min"] = -99999
                self._psu__psu_input_voltage_sensor_dict["Max"] = -99999
            self._psu__psu_input_voltage_sensor_dict["Unit"] = self.InputsVoltage.Unit
        except Exception as e:
            self._psu__psu_input_voltage_sensor_dict = None

        return self._psu__psu_input_voltage_sensor_dict

    @psu_input_voltage_sensor_dict.setter
    def psu_input_voltage_sensor_dict(self, val):
        self._psu__psu_input_voltage_sensor_dict = val

    @property
    def psu_input_current_dict(self):
        self._psu__psu_input_current_dict = {}
        try:
            self._psu__psu_input_current_dict["Value"] = self.InputsCurrent.Value
            self._psu__psu_input_current_dict["LowAlarm"] = self.InputsCurrent.Min
            self._psu__psu_input_current_dict["HighAlarm"] = self.InputsCurrent.Max
            self._psu__psu_input_current_dict["Unit"] = self.InputsCurrent.Unit
        except Exception as e:
            self._psu__psu_input_current_dict = None

        return self._psu__psu_input_current_dict

    @psu_input_current_dict.setter
    def psu_input_current_dict(self, val):
        self._psu__psu_input_current_dict = val

    @property
    def psu_input_current_sensor_dict(self):
        self._psu__psu_input_current_sensor_dict = {}
        try:
            self._psu__psu_input_current_sensor_dict["Value"] = self.InputsCurrent.Value
            self._psu__psu_input_current_sensor_dict["Min"] = self.InputsCurrent.Min
            self._psu__psu_input_current_sensor_dict["Max"] = self.InputsCurrent.Max
            self._psu__psu_input_current_sensor_dict["Unit"] = self.InputsCurrent.Unit
        except Exception as e:
            self._psu__psu_input_current_sensor_dict = None

        return self._psu__psu_input_current_sensor_dict

    @psu_input_current_sensor_dict.setter
    def psu_input_current_sensor_dict(self, val):
        self._psu__psu_input_current_sensor_dict = val

    @property
    def psu_input_power_dict(self):
        self._psu__psu_input_power_dict = {}
        try:
            self._psu__psu_input_power_dict["Value"] = self.InputsPower.Value
            self._psu__psu_input_power_dict["LowAlarm"] = self.InputsPower.Min
            self._psu__psu_input_power_dict["HighAlarm"] = self.InputsPower.Max
            self._psu__psu_input_power_dict["Unit"] = self.InputsPower.Unit
        except Exception as e:
            self._psu__psu_input_power_dict = None

        return self._psu__psu_input_power_dict

    @psu_input_power_dict.setter
    def psu_input_power_dict(self, val):
        self._psu__psu_input_power_dict = val

    @property
    def psu_input_power_sensor_dict(self):
        self._psu__psu_input_power_sensor_dict = {}
        try:
            self._psu__psu_input_power_sensor_dict["Value"] = self.InputsPower.Value
            self._psu__psu_input_power_sensor_dict["Min"] = self.InputsPower.Min
            self._psu__psu_input_power_sensor_dict["Max"] = self.InputsPower.Max
            self._psu__psu_input_power_sensor_dict["Unit"] = self.InputsPower.Unit
        except Exception as e:
            self._psu__psu_input_power_sensor_dict = None

        return self._psu__psu_input_power_sensor_dict

    @psu_input_power_sensor_dict.setter
    def psu_input_power_sensor_dict(self, val):
        self._psu__psu_input_power_sensor_dict = val

    @property
    def psu_output_voltage_dict(self):
        self._psu__psu_output_voltage_dict = {}
        try:
            self._psu__psu_output_voltage_dict["Value"] = self.OutputsVoltage.Value
            self._psu__psu_output_voltage_dict["LowAlarm"] = self.OutputsVoltage.Min
            self._psu__psu_output_voltage_dict["HighAlarm"] = self.OutputsVoltage.Max
            self._psu__psu_output_voltage_dict["Unit"] = self.OutputsVoltage.Unit
        except Exception as e:
            self._psu__psu_output_voltage_dict = None

        return self._psu__psu_output_voltage_dict

    @psu_output_voltage_dict.setter
    def psu_output_voltage_dict(self, val):
        self._psu__psu_output_voltage_dict = val

    @property
    def psu_output_voltage_sensor_dict(self):
        self._psu__psu_output_voltage_sensor_dict = {}
        try:
            self._psu__psu_output_voltage_sensor_dict["Value"] = self.OutputsVoltage.Value
            self._psu__psu_output_voltage_sensor_dict["Min"] = self.OutputsVoltage.Min
            self._psu__psu_output_voltage_sensor_dict["Max"] = self.OutputsVoltage.Max
            self._psu__psu_output_voltage_sensor_dict["Unit"] = self.OutputsVoltage.Unit
        except Exception as e:
            self._psu__psu_output_voltage_sensor_dict = None

        return self._psu__psu_output_voltage_sensor_dict

    @psu_output_voltage_sensor_dict.setter
    def psu_output_voltage_sensor_dict(self, val):
        self._psu__psu_output_voltage_sensor_dict = val

    @property
    def psu_output_current_dict(self):
        self._psu__psu_output_current_dict = {}
        try:
            self._psu__psu_output_current_dict["Value"] = self.OutputsCurrent.Value
            self._psu__psu_output_current_dict["LowAlarm"] = self.OutputsCurrent.Min
            self._psu__psu_output_current_dict["HighAlarm"] = self.OutputsCurrent.Max
            self._psu__psu_output_current_dict["Unit"] = self.OutputsCurrent.Unit
        except Exception as e:
            self._psu__psu_output_current_dict = None

        return self._psu__psu_output_current_dict

    @psu_output_current_dict.setter
    def psu_output_current_dict(self, val):
        self._psu__psu_output_current_dict = val

    @property
    def psu_output_current_sensor_dict(self):
        self._psu__psu_output_current_sensor_dict = {}
        try:
            self._psu__psu_output_current_sensor_dict["Value"] = self.OutputsCurrent.Value
            self._psu__psu_output_current_sensor_dict["Min"] = self.OutputsCurrent.Min
            self._psu__psu_output_current_sensor_dict["Max"] = self.OutputsCurrent.Max
            self._psu__psu_output_current_sensor_dict["Unit"] = self.OutputsCurrent.Unit
        except Exception as e:
            self._psu__psu_output_current_sensor_dict = None

        return self._psu__psu_output_current_sensor_dict

    @psu_output_current_sensor_dict.setter
    def psu_output_current_sensor_dict(self, val):
        self._psu__psu_output_current_sensor_dict = val

    @property
    def psu_output_power_dict(self):
        self._psu__psu_output_power_dict = {}
        try:
            self._psu__psu_output_power_dict["Value"] = self.OutputsPower.Value
            self._psu__psu_output_power_dict["LowAlarm"] = self.OutputsPower.Min
            self._psu__psu_output_power_dict["HighAlarm"] = self.OutputsPower.Max
            self._psu__psu_output_power_dict["Unit"] = self.OutputsPower.Unit
        except Exception as e:
            self._psu__psu_output_power_dict = None

        return self._psu__psu_output_power_dict

    @psu_output_power_dict.setter
    def psu_output_power_dict(self, val):
        self._psu__psu_output_power_dict = val

    @property
    def psu_output_power_sensor_dict(self):
        self._psu__psu_output_power_sensor_dict = {}
        try:
            self._psu__psu_output_power_sensor_dict["Value"] = self.OutputsPower.Value
            self._psu__psu_output_power_sensor_dict["Min"] = self.OutputsPower.Min
            self._psu__psu_output_power_sensor_dict["Max"] = self.OutputsPower.Max
            self._psu__psu_output_power_sensor_dict["Unit"] = self.OutputsPower.Unit
        except Exception as e:
            self._psu__psu_output_power_sensor_dict = None

        return self._psu__psu_output_power_sensor_dict

    @psu_output_power_sensor_dict.setter
    def psu_output_power_sensor_dict(self, val):
        self._psu__psu_output_power_sensor_dict = val

    @property
    def psu_power_status_dict(self):
        dic = {}
        inputdic = {}
        Outputsdic = {}
        dic["Name"] = self.name
        inputdic["Type"] = self.InputsType
        inputdic["Status"] = self.InputStatus
        inputdic["Voltage"] = self.psu_input_voltage_dict
        inputdic["Current"] = self.psu_input_current_dict
        inputdic["Power"] = self.psu_input_power_dict
        Outputsdic["Status"] = self.OutputStatus
        Outputsdic["Voltage"] = self.psu_output_voltage_dict
        Outputsdic["Current"] = self.psu_output_current_dict
        Outputsdic["Power"] = self.psu_output_power_dict
        dic["Inputs"] = inputdic
        dic["Outputs"] = Outputsdic
        self._psu__psu_power_status_dict = dic
        return self._psu__psu_power_status_dict

    @psu_power_status_dict.setter
    def psu_power_status_dict(self, val):
        self._psu__psu_power_status_dict = val

    @property
    def psu_status_dict(self):
        dic = {}
        dic["Name"] = self.name
        dic["InputType"] = self.InputsType
        dic["InputStatus"] = self.InputStatus
        dic["OutputStatus"] = self.OutputStatus
        dic["Temperature"] = self.psu_temp_dict
        dic["FanSpeed"] = self.psu_fanspeed_dict
        self._psu__psu_status_dict = dic
        return self._psu__psu_status_dict

    @psu_status_dict.setter
    def psu_status_dict(self, val):
        self._psu__psu_status_dict = val

    @property
    def psu_sensor_info_dict(self):
        dic = {}
        dic["%s_%s" % (self.name, "TEMP")] = self.psu_temp_sensor_dict
        dic["%s_%s" % (self.name, "FAN")] = self.psu_fanspeed_sensor_dict
        dic["%s_%s" % (self.name, "Input_V")] = self.psu_input_voltage_sensor_dict
        dic["%s_%s" % (self.name, "Input_C")] = self.psu_input_current_sensor_dict
        dic["%s_%s" % (self.name, "Input_P")] = self.psu_input_power_sensor_dict
        dic["%s_%s" % (self.name, "Output_V")] = self.psu_output_voltage_sensor_dict
        dic["%s_%s" % (self.name, "Output_C")] = self.psu_output_current_sensor_dict
        dic["%s_%s" % (self.name, "Output_P")] = self.psu_output_power_sensor_dict
        self._psu__psu_sensor_info_dict = dic
        return self._psu__psu_sensor_info_dict

    @psu_sensor_info_dict.setter
    def psu_sensor_info_dict(self, val):
        self._psu__psu_sensor_info_dict = val

    def __str__(self):
        formatstr = "name                : %s \nproductManufacturer : %s \nproductName         : %s \nproductPartModelName: %s \nproductVersion      : %s \nproductSerialNumber : %s \nAirFlow             : %s \n"
        tmpstr = formatstr % (self.name, self.productManufacturer,
         self.productName, self.productPartModelName,
         self.productVersion, self.productSerialNumber, self.AirFlow)
        return tmpstr

    def get_fan_speed_pwm(self):
        """
        Get a specific PSU's fan's speed

        @return pwm duty cycle, unit is 1%, -1 for failure
        """
        return self.FanSpeedPWM

    def set_fan_speed_pwm(self, pwm):
        """
        Set a specific PSU's fan's speed

        @param pwm duty cycle, unit is 1%

        @return 0 for success, -1 for failure
        """
        if pwm < 0 or pwm > 100:
            return -1

        ret, val = self.set_value(self._psu__FanSpeedPWM_config, pwm)
        if ret == True:
            return 0
        else:
            return -1

