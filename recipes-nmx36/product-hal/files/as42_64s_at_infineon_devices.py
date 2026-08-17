# Copyright (C) 2023, Ruijie Networks Co., Ltd. All rights reserved.
# No part of this script may be reproduced, distributed,
# or transmitted in any form or by any means,
# without the prior written permission of the author.

class Unit:
    Temperature = "C"
    Voltage = "V"
    Current = "A"
    Power =  "W"
    Speed = "RPM"

class threshold:
    PSU_TEMP_MIN =   0
    PSU_TEMP_MAX = 100

    PSU_FAN_SPEED_MIN = 2000
    PSU_FAN_SPEED_MAX = 35000

    PSU_OUTPUT_VOLTAGE_MIN = 12
    PSU_OUTPUT_VOLTAGE_MAX = 12.8

    PSU_INPUT_VOLTAGE_MIN =  90
    PSU_INPUT_VOLTAGE_MAX = 264

    ERR_VALUE =  -99999000

    PSU_OUTPUT_POWER_MIN  = 0
    PSU_OUTPUT_POWER_MAX  = 2700

    PSU_INPUT_POWER_MIN = 0
    PSU_INPUT_POWER_MAX = 2700

    PSU_OUTPUT_CURRENT_MIN = 0
    PSU_OUTPUT_CURRENT_MAX = 161.3

    PSU_INPUT_CURRENT_MIN = 0
    PSU_INPUT_CURRENT_MAX = 9

    FAN_SPEED_MAX = 20700
    FAN_SPEED_MIN = 4050

    FAN_ROTOR1_SPEED_MAX = 20700
    FAN_ROTOR1_SPEED_MIN = 4050

    FAN_ROTOR2_SPEED_MAX = 18400
    FAN_ROTOR2_SPEED_MIN = 3834

class fan_cpld_reg:
    FANCPLD_I2C_ADDR = 0xd
    FANCPLD_WATCHDOG = 0xc
    FANCPLD_FAN1_PRE_STA = 0x27
    FANCPLD_FAN2_PRE_STA = 0x37
    FANCPLD_FAN3_PRE_STA = 0x47
    FANCPLD_FAN4_PRE_STA = 0x57
    FANCPLD_FAN5_PRE_STA = 0x67

    FANCPLD_FAN1_F2B = 0x2b
    FANCPLD_FAN2_F2B = 0x3b
    FANCPLD_FAN3_F2B = 0x4b
    FANCPLD_FAN4_F2B = 0x5b
    FANCPLD_FAN5_F2B = 0x6b

    FANCPLD_FAN1_ROTOR1_SPEED = 0x20
    FANCPLD_FAN2_ROTOR1_SPEED = 0x30
    FANCPLD_FAN3_ROTOR1_SPEED = 0x40
    FANCPLD_FAN4_ROTOR1_SPEED = 0x50
    FANCPLD_FAN5_ROTOR1_SPEED = 0x60

    FANCPLD_FAN1_ROTOR2_SPEED = 0x22
    FANCPLD_FAN2_ROTOR2_SPEED = 0x32
    FANCPLD_FAN3_ROTOR2_SPEED = 0x42
    FANCPLD_FAN4_ROTOR2_SPEED = 0x52
    FANCPLD_FAN5_ROTOR2_SPEED = 0x62

    FANCPLD_FAN1_LEDCTL = 0x25
    FANCPLD_FAN2_LEDCTL = 0x35
    FANCPLD_FAN3_LEDCTL = 0x45
    FANCPLD_FAN4_LEDCTL = 0x55
    FANCPLD_FAN5_LEDCTL = 0x65

    FANCPLD_FAN1_PWM = 0x24
    FANCPLD_FAN2_PWM = 0x34
    FANCPLD_FAN3_PWM = 0x44
    FANCPLD_FAN4_PWM = 0x54
    FANCPLD_FAN5_PWM = 0x64

class base_cpld_reg:
    BASECPLD_I2C_ADDR = 0xd
    BASECPLD_PSU_OUTPUT_OK = 0x40
    BASECPLD_PSU_VINPG = 0x41
    BASECPLD_PSU_PRESENT = 0x42
    BASECPLD_PSU_POWERON = 0x43
devices = {
    "psus": [
        {
            "name": "PSU1",
            "cpldi2cbus": 0,
            "present": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_PRESENT, 'bit': 3, 'bits':1, 'way': 'smbusbits'},
            "PM": {"loc": "/sys/bus/i2c/devices/75-0058/mfr_id", "way": "file"},
            "PPN": {"loc": "/sys/bus/i2c/devices/75-0058/mfr_model", "way": "file"},
            "PV": {"loc": "/sys/bus/i2c/devices/75-0058/mfr_revision", "way": "file"},
            "SN": {"loc": "/sys/bus/i2c/devices/75-0058/mfr_serial", "way": "file"},
            "airflow": "F2B",
            "FanSpeedPWM": {"loc": "/sys/bus/i2c/devices/75-0058/fan_command", "way": "sysfs"},
            "PowerOnStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_POWERON, 'bit': 3, 'bits':1, 'way': 'smbusbits'},
            "Temperature": {
                            "value": {"loc": "/sys/bus/i2c/devices/75-0058/temp1_input", "way": "sysfs"},
                            "Min": threshold.PSU_TEMP_MIN,
                            "Max": threshold.PSU_TEMP_MAX,
                            "Unit": Unit.Temperature,
                            "format":"float(float(%d)/1000)"
                        },
            "FanSpeed": {
                         "value": {"loc": "/sys/bus/i2c/devices/75-0058/fan1_input", "way": "sysfs"},
                         "Min": threshold.PSU_FAN_SPEED_MIN,
                         "Max": threshold.PSU_FAN_SPEED_MAX,
                         "Unit": Unit.Speed
                        },
            "InputsType": {"loc": "/sys/bus/i2c/devices/75-0058/input_type", "way": "file"},
            "InputsStatus":{'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_VINPG, 'bit': 3, 'bits':1, 'way': 'smbusbits'},
            "InputsVoltage": {
                              "value": {"loc": "/sys/bus/i2c/devices/75-0058/in1_input", "way": "sysfs"},
                              "Min": threshold.PSU_INPUT_VOLTAGE_MIN,
                              "Max": threshold.PSU_INPUT_VOLTAGE_MAX,
                              "Unit": Unit.Voltage,
                              "format":"float(float(%d)/1000)"
                        },
            "InputsCurrent": {
                              "value": {"loc": "/sys/bus/i2c/devices/75-0058/curr1_input", "way": "sysfs"},
                              "Min": threshold.PSU_INPUT_CURRENT_MIN,
                              "Max": threshold.PSU_INPUT_CURRENT_MAX,
                              "Unit": Unit.Current,
                              "format":"float(float(%d)/1000)"
                        },
            "InputsPower": {
                            "value": {"loc": "/sys/bus/i2c/devices/75-0058/power1_input", "way": "sysfs"},
                            "Min": threshold.PSU_INPUT_POWER_MIN,
                            "Max": threshold.PSU_INPUT_POWER_MAX,
                            "Unit": Unit.Power,
                            "format":"float(float(%d)/1000000)"
                        },
            "OutputsStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_OUTPUT_OK, 'bit': 3, 'bits':1, 'way': 'smbusbits'},
            "OutputsVoltage": {
                               "value": {"loc": "/sys/bus/i2c/devices/75-0058/in2_input", "way": "sysfs"},
                               "Min": threshold.PSU_OUTPUT_VOLTAGE_MIN,
                               "Max": threshold.PSU_OUTPUT_VOLTAGE_MAX,
                               "Unit": Unit.Voltage,
                               "format":"float(float(%d)/1000)"
                        },
            "OutputsCurrent": {
                               "value": {"loc": "/sys/bus/i2c/devices/75-0058/curr2_input", "way": "sysfs"},
                               "Min": threshold.PSU_OUTPUT_CURRENT_MIN,
                               "Max": threshold.PSU_OUTPUT_CURRENT_MAX,
                               "Unit": Unit.Current,
                               "format":"float(float(%d)/1000)"
                        },
            "OutputsPower": {
                             "value": {"loc": "/sys/bus/i2c/devices/75-0058/power2_input", "way": "sysfs"},
                             "Min": threshold.PSU_OUTPUT_POWER_MIN,
                             "Max": threshold.PSU_OUTPUT_POWER_MAX,
                             "Unit": Unit.Power,
                             "format":"float(float(%d)/1000000)"
                        },
        },
        {
            "name": "PSU2",
            "cpldi2cbus": 0,
            "present": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_PRESENT, 'bit': 2, 'bits':1, 'way': 'smbusbits'},
            "PM": {"loc": "/sys/bus/i2c/devices/74-0058/mfr_id", "way": "file"},
            "PPN": {"loc": "/sys/bus/i2c/devices/74-0058/mfr_model", "way": "file"},
            "PV": {"loc": "/sys/bus/i2c/devices/74-0058/mfr_revision", "way": "file"},
            "SN": {"loc": "/sys/bus/i2c/devices/74-0058/mfr_serial", "way": "file"},
            "airflow": "F2B",
            "FanSpeedPWM": {"loc": "/sys/bus/i2c/devices/74-0058/fan_command", "way": "sysfs"},
            "PowerOnStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_POWERON, 'bit': 2, 'bits':1, 'way': 'smbusbits'},
            "Temperature": {
                            "value": {"loc": "/sys/bus/i2c/devices/74-0058/temp1_input", "way": "sysfs"},
                            "Min": threshold.PSU_TEMP_MIN,
                            "Max": threshold.PSU_TEMP_MAX,
                            "Unit": Unit.Temperature,
                            "format":"float(float(%d)/1000)"
                        },
            "FanSpeed": {
                         "value": {"loc": "/sys/bus/i2c/devices/74-0058/fan1_input", "way": "sysfs"},
                         "Min": threshold.PSU_FAN_SPEED_MIN,
                         "Max": threshold.PSU_FAN_SPEED_MAX,
                         "Unit": Unit.Speed
                        },
            "InputsType": {"loc": "/sys/bus/i2c/devices/74-0058/input_type", "way": "file"},
            "InputsStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_VINPG, 'bit': 2, 'bits':1, 'way': 'smbusbits'},
            "InputsVoltage": {
                              "value": {"loc": "/sys/bus/i2c/devices/74-0058/in1_input", "way": "sysfs"},
                              "Min": threshold.PSU_INPUT_VOLTAGE_MIN,
                              "Max": threshold.PSU_INPUT_VOLTAGE_MAX,
                              "Unit": Unit.Voltage,
                              "format":"float(float(%d)/1000)"
                        },
            "InputsCurrent": {
                              "value": {"loc": "/sys/bus/i2c/devices/74-0058/curr1_input", "way": "sysfs"},
                              "Min": threshold.PSU_INPUT_CURRENT_MIN,
                              "Max": threshold.PSU_INPUT_CURRENT_MAX,
                              "Unit": Unit.Current,
                              "format":"float(float(%d)/1000)"
                        },
            "InputsPower": {
                            "value": {"loc": "/sys/bus/i2c/devices/74-0058/power1_input", "way": "sysfs"},
                            "Min": threshold.PSU_INPUT_POWER_MIN,
                            "Max": threshold.PSU_INPUT_POWER_MAX,
                            "Unit": Unit.Power,
                            "format":"float(float(%d)/1000000)"
                        },
            "OutputsStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_OUTPUT_OK, 'bit': 2, 'bits':1, 'way': 'smbusbits'},
            "OutputsVoltage": {
                               "value": {"loc": "/sys/bus/i2c/devices/74-0058/in2_input", "way": "sysfs"},
                               "Min": threshold.PSU_OUTPUT_VOLTAGE_MIN,
                               "Max": threshold.PSU_OUTPUT_VOLTAGE_MAX,
                               "Unit": Unit.Voltage,
                               "format":"float(float(%d)/1000)"
                        },
            "OutputsCurrent": {
                               "value": {"loc": "/sys/bus/i2c/devices/74-0058/curr2_input", "way": "sysfs"},
                               "Min": threshold.PSU_OUTPUT_CURRENT_MIN,
                               "Max": threshold.PSU_OUTPUT_CURRENT_MAX,
                               "Unit": Unit.Current,
                               "format":"float(float(%d)/1000)"
                        },
            "OutputsPower": {
                             "value": {"loc": "/sys/bus/i2c/devices/74-0058/power2_input", "way": "sysfs"},
                             "Min": threshold.PSU_OUTPUT_POWER_MIN,
                             "Max": threshold.PSU_OUTPUT_POWER_MAX,
                             "Unit": Unit.Power,
                             "format":"float(float(%d)/1000000)"
                        },
        },
        {
            "name": "PSU3",
            "cpldi2cbus": 0,
            "present": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_PRESENT, 'bit': 1, 'bits':1, 'way': 'smbusbits'},
            "PM": {"loc": "/sys/bus/i2c/devices/73-0058/mfr_id", "way": "file"},
            "PPN": {"loc": "/sys/bus/i2c/devices/73-0058/mfr_model", "way": "file"},
            "PV": {"loc": "/sys/bus/i2c/devices/73-0058/mfr_revision", "way": "file"},
            "SN": {"loc": "/sys/bus/i2c/devices/73-0058/mfr_serial", "way": "file"},
            "airflow": "F2B",
            "FanSpeedPWM": {"loc": "/sys/bus/i2c/devices/73-0058/fan_command", "way": "sysfs"},
            "PowerOnStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_POWERON, 'bit': 1, 'bits':1, 'way': 'smbusbits'},
            "Temperature": {
                            "value": {"loc": "/sys/bus/i2c/devices/73-0058/temp1_input", "way": "sysfs"},
                            "Min": threshold.PSU_TEMP_MIN,
                            "Max": threshold.PSU_TEMP_MAX,
                            "Unit": Unit.Temperature,
                            "format":"float(float(%d)/1000)"
                        },
            "FanSpeed": {
                         "value": {"loc": "/sys/bus/i2c/devices/73-0058/fan1_input", "way": "sysfs"},
                         "Min": threshold.PSU_FAN_SPEED_MIN,
                         "Max": threshold.PSU_FAN_SPEED_MAX,
                         "Unit": Unit.Speed
                        },
            "InputsType": {"loc": "/sys/bus/i2c/devices/73-0058/input_type", "way": "file"},
            "InputsStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_VINPG, 'bit': 1, 'bits':1, 'way': 'smbusbits'},
            "InputsVoltage": {
                              "value": {"loc": "/sys/bus/i2c/devices/73-0058/in1_input", "way": "sysfs"},
                              "Min": threshold.PSU_INPUT_VOLTAGE_MIN,
                              "Max": threshold.PSU_INPUT_VOLTAGE_MAX,
                              "Unit": Unit.Voltage,
                              "format":"float(float(%d)/1000)"
                        },
            "InputsCurrent": {
                              "value": {"loc": "/sys/bus/i2c/devices/73-0058/curr1_input", "way": "sysfs"},
                              "Min": threshold.PSU_INPUT_CURRENT_MIN,
                              "Max": threshold.PSU_INPUT_CURRENT_MAX,
                              "Unit": Unit.Current,
                              "format":"float(float(%d)/1000)"
                        },
            "InputsPower": {
                            "value": {"loc": "/sys/bus/i2c/devices/73-0058/power1_input", "way": "sysfs"},
                            "Min": threshold.PSU_INPUT_POWER_MIN,
                            "Max": threshold.PSU_INPUT_POWER_MAX,
                            "Unit": Unit.Power,
                            "format":"float(float(%d)/1000000)"
                        },
            "OutputsStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_OUTPUT_OK, 'bit': 1, 'bits':1, 'way': 'smbusbits'},
            "OutputsVoltage": {
                               "value": {"loc": "/sys/bus/i2c/devices/73-0058/in2_input", "way": "sysfs"},
                               "Min": threshold.PSU_OUTPUT_VOLTAGE_MIN,
                               "Max": threshold.PSU_OUTPUT_VOLTAGE_MAX,
                               "Unit": Unit.Voltage,
                               "format":"float(float(%d)/1000)"
                        },
            "OutputsCurrent": {
                               "value": {"loc": "/sys/bus/i2c/devices/73-0058/curr2_input", "way": "sysfs"},
                               "Min": threshold.PSU_OUTPUT_CURRENT_MIN,
                               "Max": threshold.PSU_OUTPUT_CURRENT_MAX,
                               "Unit": Unit.Current,
                               "format":"float(float(%d)/1000)"
                        },
            "OutputsPower": {
                             "value": {"loc": "/sys/bus/i2c/devices/73-0058/power2_input", "way": "sysfs"},
                             "Min": threshold.PSU_OUTPUT_POWER_MIN,
                             "Max": threshold.PSU_OUTPUT_POWER_MAX,
                             "Unit": Unit.Power,
                             "format":"float(float(%d)/1000000)"
                        },
        },
        {
            "name": "PSU4",
            "cpldi2cbus": 0,
            "present": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_PRESENT, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "PM": {"loc": "/sys/bus/i2c/devices/72-0058/mfr_id", "way": "file"},
            "PPN": {"loc": "/sys/bus/i2c/devices/72-0058/mfr_model", "way": "file"},
            "PV": {"loc": "/sys/bus/i2c/devices/72-0058/mfr_revision", "way": "file"},
            "SN": {"loc": "/sys/bus/i2c/devices/72-0058/mfr_serial", "way": "file"},
            "airflow": "F2B",
            "FanSpeedPWM": {"loc": "/sys/bus/i2c/devices/72-0058/fan_command", "way": "sysfs"},
            "PowerOnStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_POWERON, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "Temperature": {
                            "value": {"loc": "/sys/bus/i2c/devices/72-0058/temp1_input", "way": "sysfs"},
                            "Min": threshold.PSU_TEMP_MIN,
                            "Max": threshold.PSU_TEMP_MAX,
                            "Unit": Unit.Temperature,
                            "format":"float(float(%d)/1000)"
                        },
            "FanSpeed": {
                         "value": {"loc": "/sys/bus/i2c/devices/72-0058/fan1_input", "way": "sysfs"},
                         "Min": threshold.PSU_FAN_SPEED_MIN,
                         "Max": threshold.PSU_FAN_SPEED_MAX,
                         "Unit": Unit.Speed
                        },
            "InputsType": {"loc": "/sys/bus/i2c/devices/72-0058/input_type", "way": "file"},
            "InputsStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_VINPG, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "InputsVoltage": {
                              "value": {"loc": "/sys/bus/i2c/devices/72-0058/in1_input", "way": "sysfs"},
                              "Min": threshold.PSU_INPUT_VOLTAGE_MIN,
                              "Max": threshold.PSU_INPUT_VOLTAGE_MAX,
                              "Unit": Unit.Voltage,
                              "format":"float(float(%d)/1000)"
                        },
            "InputsCurrent": {
                              "value": {"loc": "/sys/bus/i2c/devices/72-0058/curr1_input", "way": "sysfs"},
                              "Min": threshold.PSU_INPUT_CURRENT_MIN,
                              "Max": threshold.PSU_INPUT_CURRENT_MAX,
                              "Unit": Unit.Current,
                              "format":"float(float(%d)/1000)"
                        },
            "InputsPower": {
                            "value": {"loc": "/sys/bus/i2c/devices/72-0058/power1_input", "way": "sysfs"},
                            "Min": threshold.PSU_INPUT_POWER_MIN,
                            "Max": threshold.PSU_INPUT_POWER_MAX,
                            "Unit": Unit.Power,
                            "format":"float(float(%d)/1000000)"
                        },
            "OutputsStatus": {'addr' : base_cpld_reg.BASECPLD_I2C_ADDR, 'offset': base_cpld_reg.BASECPLD_PSU_OUTPUT_OK, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "OutputsVoltage": {
                               "value": {"loc": "/sys/bus/i2c/devices/72-0058/in2_input", "way": "sysfs"},
                               "Min": threshold.PSU_OUTPUT_VOLTAGE_MIN,
                               "Max": threshold.PSU_OUTPUT_VOLTAGE_MAX,
                               "Unit": Unit.Voltage,
                               "format":"float(float(%d)/1000)"
                        },
            "OutputsCurrent": {
                               "value": {"loc": "/sys/bus/i2c/devices/72-0058/curr2_input", "way": "sysfs"},
                               "Min": threshold.PSU_OUTPUT_CURRENT_MIN,
                               "Max": threshold.PSU_OUTPUT_CURRENT_MAX,
                               "Unit": Unit.Current,
                               "format":"float(float(%d)/1000)"
                        },
            "OutputsPower": {
                             "value": {"loc": "/sys/bus/i2c/devices/72-0058/power2_input", "way": "sysfs"},
                             "Min": threshold.PSU_OUTPUT_POWER_MIN,
                             "Max": threshold.PSU_OUTPUT_POWER_MAX,
                             "Unit": Unit.Power,
                             "format":"float(float(%d)/1000000)"
                        },
        }
    ],
    "temps":[
        {
            "name": "CPU_TEMP",
            "Min": -5,
            "Max": 87,
            "value": {
                "loc":"/usr/local/bin/get_thermal_sensor.sh --cpu",
                 "way":"command"
            },
            "Unit": Unit.Temperature
        },
        {
            "name": "SWITCH_TEMP",
            "Min": -5,
            "Max": 100,
            "value": {
                "loc": "/usr/local/bin/get_thermal_sensor.sh --mac",
                "way": "command"
            },
            "Unit": Unit.Temperature
        },
        {
            "name": "INLET_TEMP",
            "format": "float(float(%d)/1000)",
            "Min": 0,
            "Max": 57,
            "value": {
                "loc": "/sys/bus/i2c/devices/76-0048/hwmon/hwmon*/temp1_input",
                "way": "sysfs"
            },
            "Unit": Unit.Temperature
        }
    ],
    "dcdc":[
        {
            "name": "GRR_PVCCIN_V",
            "format": "float(float(%d)/1000)",
            "Min": 1.4,
            "Max": 1.8,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-0058/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_PVNN_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.55,
            "Max": 1,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-0058/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_PVCCIN_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 150.0,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-0058/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_PVNN_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 55.0,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-0058/hwmon/hwmon*/curr3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_P1V1_V",
            "format": "float(float(%d)/1000)",
            "Min": 1.04,
            "Max": 1.16,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-0060/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_PVNN_PCH_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.55,
            "Max": 1.0,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-0060/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_P1V1_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 15.0,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-0060/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_PVNN_PCH_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 12.0,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-0060/hwmon/hwmon*/curr6_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_P0V9_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.84,
            "Max": 0.96,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-006e/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_PVCCINF_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.55,
            "Max": 1.0,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-006e/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_P0V9_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 25.0,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-006e/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_PVCCINF_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 35.0,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-006e/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_P5V_DDR_V",
            "format": "float(float(%d)/1000)",
            "Min": 4.85,
            "Max": 5.15,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-002f/in1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "GRR_P5V_DDR_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 14.0,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/17-002f/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T0_1V05_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.9975,
            "Max": 1.1025,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/56-0063/hwmon/hwmon*/in1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T1_1V05_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.9975,
            "Max": 1.1025,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/56-0063/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T0_1V05_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 24.2,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/56-0063/hwmon/hwmon*/curr1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T1_1V05_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 24.2,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/56-0063/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T2_1V05_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.9975,
            "Max": 1.1025,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/57-0064/hwmon/hwmon*/in1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T3_1V05_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.9975,
            "Max": 1.1025,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/57-0064/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T2_1V05_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 24.2,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/57-0064/hwmon/hwmon*/curr1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T3_1V05_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 24.2,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/57-0064/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T4_1V05_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.9975,
            "Max": 1.1025,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/58-0065/hwmon/hwmon*/in1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T5_1V05_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.9975,
            "Max": 1.1025,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/58-0065/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T4_1V05_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 24.2,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/58-0065/hwmon/hwmon*/curr1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T5_1V05_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 24.2,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/58-0065/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T6_1V05_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.9975,
            "Max": 1.1025,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/59-0066/hwmon/hwmon*/in1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T7_1V05_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.9975,
            "Max": 1.1025,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/59-0066/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T6_1V05_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 24.2,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/59-0066/hwmon/hwmon*/curr1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_AVDD_T7_1V05_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 24.2,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/59-0066/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_HVDD_T03_1V2_V",
            "format": "float(float(%d)/1000)",
            "Min": 1.14,
            "Max": 1.26,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/53-0062/hwmon/hwmon*/in1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_HVDD_T47_1V2_V",
            "format": "float(float(%d)/1000)",
            "Min": 1.14,
            "Max": 1.26,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/53-0062/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_HVDD_T03_1V2_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 34.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/53-0062/hwmon/hwmon*/curr1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_HVDD_T47_1V2_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 34.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/53-0062/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDHBID_T12_0V78_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.741,
            "Max": 0.819,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/54-006b/hwmon/hwmon*/in1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDHBID_T37_0V78_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.741,
            "Max": 0.819,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/54-006b/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDHBID_T12_0V78_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 78.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/54-006b/hwmon/hwmon*/curr1_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDHBID_T37_0V78_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 78.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/54-006b/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDHBID_T04_0V78_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.741,
            "Max": 0.819,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/55-006e/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDHBID_T56_0V78_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.741,
            "Max": 0.819,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/55-006e/hwmon/hwmon*/in4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDHBID_T04_0V78_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 78.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/55-006e/hwmon/hwmon*/curr3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDHBID_T56_0V78_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 78.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/55-006e/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP_1_8_3V3_V",
            "format": "float(float(%d)/1000)",
            "Min": 2.97,
            "Max": 3.65,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/60-0067/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP9_16_3V3_V",
            "format": "float(float(%d)/1000)",
            "Min": 2.97,
            "Max": 3.65,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/60-0067/hwmon/hwmon*/in4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP_1_8_3V3_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 117.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/60-0067/hwmon/hwmon*/curr3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP9_16_3V3_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 117.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/60-0067/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP17_24_3V3_V",
            "format": "float(float(%d)/1000)",
            "Min": 2.97,
            "Max": 3.65,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/61-0068/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP25_32_3V3_V",
            "format": "float(float(%d)/1000)",
            "Min": 2.97,
            "Max": 3.65,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/61-0068/hwmon/hwmon*/in4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP17_24_3V3_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 117.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/61-0068/hwmon/hwmon*/curr3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP25_32_3V3_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 117.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/61-0068/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP33_40_3V3_V",
            "format": "float(float(%d)/1000)",
            "Min": 2.97,
            "Max": 3.65,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/62-0069/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP41_48_3V3_V",
            "format": "float(float(%d)/1000)",
            "Min": 2.97,
            "Max": 3.65,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/62-0069/hwmon/hwmon*/in4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP33_40_3V3_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 117.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/62-0069/hwmon/hwmon*/curr3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP41_48_3V3_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 117.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/62-0069/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP49_56_3V3_V",
            "format": "float(float(%d)*2/1000)",
            "Min": 2.97,
            "Max": 3.65,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/63-006a/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP57_64_3V3_V",
            "format": "float(float(%d)/1000)",
            "Min": 2.97,
            "Max": 3.65,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/63-006a/hwmon/hwmon*/in4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP49_56_3V3_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 117.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/63-006a/hwmon/hwmon*/curr3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "OSFP57_64_3V3_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 117.1,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/63-006a/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T0_0V75_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.7125,
            "Max": 0.7875,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/49-0063/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T1_0V75_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.7125,
            "Max": 0.7875,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/49-0063/hwmon/hwmon*/in4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T0_0V75_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 58.3,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/49-0063/hwmon/hwmon*/curr3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T1_0V75_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 58.3,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/49-0063/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T2_0V75_V",
            "format": "float(float(%d)*2/1000)",
            "Min": 0.7125,
            "Max": 0.7875,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/50-0064/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T3_0V75_V",
            "format": "float(float(%d)*2/1000)",
            "Min": 0.7125,
            "Max": 0.7875,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/50-0064/hwmon/hwmon*/in4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T2_0V75_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 58.3,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/50-0064/hwmon/hwmon*/curr3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T3_0V75_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 58.3,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/50-0064/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T4_0V75_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.7125,
            "Max": 0.7875,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/51-0065/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T5_0V75_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.7125,
            "Max": 0.7875,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/51-0065/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T4_0V75_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 58.3,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/51-0065/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T5_0V75_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 58.3,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/51-0065/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T6_0V75_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.7125,
            "Max": 0.7875,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/52-0066/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T7_0V75_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.7125,
            "Max": 0.7875,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/52-0066/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T6_0V75_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 58.3,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/52-0066/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDD_T7_0V75_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 58.3,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/52-0066/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDM_0V75_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.7125,
            "Max": 0.7875,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/48-0060/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_VDDM_0V75_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 896.5,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/48-0060/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T0_0V7_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.665,
            "Max": 0.735,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/104-0067/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T1_0V7_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.665,
            "Max": 0.735,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/104-0067/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T0_0V7_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 41.8,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/104-0067/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T1_0V7_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 41.8,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/104-0067/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T2_0V7_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.665,
            "Max": 0.735,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/105-0068/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T3_0V7_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.665,
            "Max": 0.735,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/105-0068/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T2_0V7_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 41.8,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/105-0068/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T3_0V7_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 41.8,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/105-0068/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T4_0V7_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.665,
            "Max": 0.735,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/106-0069/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T5_0V7_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.665,
            "Max": 0.735,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/106-0069/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T4_0V7_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 41.8,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/106-0069/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T5_0V7_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 41.8,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/106-0069/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T6_0V7_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.665,
            "Max": 0.735,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/107-006a/hwmon/hwmon*/in2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T7_0V7_V",
            "format": "float(float(%d)/1000)",
            "Min": 0.665,
            "Max": 0.735,
            "Unit": "V",
            "value": {
                "loc": "/sys/bus/i2c/devices/107-006a/hwmon/hwmon*/in3_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T6_0V7_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 41.8,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/107-006a/hwmon/hwmon*/curr2_input",
                "way": "sysfs"
            }
        },
        {
            "name": "SP6_DVDD_T7_0V7_C",
            "format": "float(float(%d)/1000)",
            "Min": 0.0,
            "Max": 41.8,
            "Unit": "A",
            "value": {
                "loc": "/sys/bus/i2c/devices/107-006a/hwmon/hwmon*/curr4_input",
                "way": "sysfs"
            }
        },
    ],
    "fans": [
        {
            "name": "FAN1",
            "i2cbus" : 8,
            "airflow": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_F2B, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "present": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_PRE_STA, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "SpeedMin": threshold.FAN_SPEED_MIN,
            "SpeedMax": threshold.FAN_SPEED_MAX,
            "led": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_LEDCTL, 'bit': 0, 'bits':4, 'way': 'smbusbits'},
            "led_attrs": {"off": {"blink": 0x0b, "steady": 0x0b}, "green": {"blink": 0x0d, "steady": 0x09}, "yellow": {"blink": 0x07, "steady": 0x03}, "red": {"blink": 0x0e, "steady": 0x0a}},
            "EnableWatchdogConf": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_WATCHDOG, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "EnableWatchdogAttr": {"enable": 0x01, "disable": 0x00},
            "WatchdogNormal": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_WATCHDOG, 'bit': 2, 'bits':1, 'way': 'smbusbits'},
            "WatchdogTimeout": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_WATCHDOG, 'bit': 1, 'bits':1, 'way': 'smbusbits'},
            "SpeedPWM": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_PWM, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
            "Rotor": {
                        "Rotor1_config": {
                                            "name": "Rotor1",
                                            "SpeedValue":{'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_ROTOR1_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR1_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR1_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                        "Rotor2_config": {
                                            "name": "Rotor2",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_ROTOR2_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR2_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR2_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                    },
        },
        {
            "name": "FAN2",
            "i2cbus" : 8,
            "airflow": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_F2B, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "present": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_PRE_STA, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "SpeedMin": threshold.FAN_SPEED_MIN,
            "SpeedMax": threshold.FAN_SPEED_MAX,
            "led": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_LEDCTL, 'bit': 0, 'bits':4, 'way': 'smbusbits'},
            "led_attrs": {"off": {"blink": 0x0b, "steady": 0x0b}, "green": {"blink": 0x0d, "steady": 0x09}, "yellow": {"blink": 0x07, "steady": 0x03}, "red": {"blink": 0x0e, "steady": 0x0a}},
            "SpeedPWM": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_PWM, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
            "Rotor": {
                        "Rotor1_config": {
                                            "name": "Rotor1",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_ROTOR1_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR1_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR1_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                        "Rotor2_config": {
                                            "name": "Rotor2",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_ROTOR2_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR2_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR2_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                    },
        },
        {
            "name": "FAN3",
            "i2cbus" : 8,
            "airflow": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_F2B, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "present": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_PRE_STA, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "SpeedMin": threshold.FAN_SPEED_MIN,
            "SpeedMax": threshold.FAN_SPEED_MAX,
            "led": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_LEDCTL, 'bit': 0, 'bits':4, 'way': 'smbusbits'},
            "led_attrs": {"off": {"blink": 0x0b, "steady": 0x0b}, "green": {"blink": 0x0d, "steady": 0x09}, "yellow": {"blink": 0x07, "steady": 0x03}, "red": {"blink": 0x0e, "steady": 0x0a}},
            "SpeedPWM": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_PWM, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
            "Rotor": {
                        "Rotor1_config": {
                                            "name": "Rotor1",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_ROTOR1_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR1_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR1_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                        "Rotor2_config": {
                                            "name": "Rotor2",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_ROTOR2_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR2_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR2_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                    },
        },
        {
            "name": "FAN4",
            "i2cbus" : 8,
            "airflow": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_F2B, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "present": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_PRE_STA, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "SpeedMin": threshold.FAN_SPEED_MIN,
            "SpeedMax": threshold.FAN_SPEED_MAX,
            "led": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_LEDCTL, 'bit': 0, 'bits':4, 'way': 'smbusbits'},
            "led_attrs": {"off": {"blink": 0x0b, "steady": 0x0b}, "green": {"blink": 0x0d, "steady": 0x09}, "yellow": {"blink": 0x07, "steady": 0x03}, "red": {"blink": 0x0e, "steady": 0x0a}},
            "SpeedPWM": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_PWM, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
            "Rotor": {
                        "Rotor1_config": {
                                            "name": "Rotor1",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_ROTOR1_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR1_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR1_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                        "Rotor2_config": {
                                            "name": "Rotor2",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_ROTOR2_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR2_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR2_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                    },
        },
        {
            "name": "FAN5",
            "i2cbus" : 3,
            "airflow": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_F2B, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "present": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_PRE_STA, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "SpeedMin": threshold.FAN_SPEED_MIN,
            "SpeedMax": threshold.FAN_SPEED_MAX,
            "led": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_LEDCTL, 'bit': 0, 'bits':4, 'way': 'smbusbits'},
            "led_attrs": {"off": {"blink": 0x0b, "steady": 0x0b}, "green": {"blink": 0x0d, "steady": 0x09}, "yellow": {"blink": 0x07, "steady": 0x03}, "red": {"blink": 0x0e, "steady": 0x0a}},
            "SpeedPWM": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_PWM, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
            "Rotor": {
                        "Rotor1_config": {
                                            "name": "Rotor1",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_ROTOR1_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR1_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR1_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                        "Rotor2_config": {
                                            "name": "Rotor2",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN1_ROTOR2_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR2_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR2_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                    },
        },
        {
            "name": "FAN6",
            "i2cbus" : 3,
            "airflow": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_F2B, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "present": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_PRE_STA, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "SpeedMin": threshold.FAN_SPEED_MIN,
            "SpeedMax": threshold.FAN_SPEED_MAX,
            "led": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_LEDCTL, 'bit': 0, 'bits':4, 'way': 'smbusbits'},
            "led_attrs": {"off": {"blink": 0x0b, "steady": 0x0b}, "green": {"blink": 0x0d, "steady": 0x09}, "yellow": {"blink": 0x07, "steady": 0x03}, "red": {"blink": 0x0e, "steady": 0x0a}},
            "SpeedPWM": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_PWM, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
            "Rotor": {
                        "Rotor1_config": {
                                            "name": "Rotor1",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_ROTOR1_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR1_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR1_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                        "Rotor2_config": {
                                            "name": "Rotor2",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN2_ROTOR2_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR2_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR2_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                    },
        },
        {
            "name": "FAN7",
            "i2cbus" : 3,
            "airflow": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_F2B, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "present": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_PRE_STA, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "SpeedMin": threshold.FAN_SPEED_MIN,
            "SpeedMax": threshold.FAN_SPEED_MAX,
            "led": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_LEDCTL, 'bit': 0, 'bits':4, 'way': 'smbusbits'},
            "led_attrs": {"off": {"blink": 0x0b, "steady": 0x0b}, "green": {"blink": 0x0d, "steady": 0x09}, "yellow": {"blink": 0x07, "steady": 0x03}, "red": {"blink": 0x0e, "steady": 0x0a}},
            "SpeedPWM": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_PWM, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
            "Rotor": {
                        "Rotor1_config": {
                                            "name": "Rotor1",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_ROTOR1_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR1_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR1_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                        "Rotor2_config": {
                                            "name": "Rotor2",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN3_ROTOR2_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR2_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR2_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                    },
        },
        {
            "name": "FAN8",
            "i2cbus" : 3,
            "airflow": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_F2B, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "present": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_PRE_STA, 'bit': 0, 'bits':1, 'way': 'smbusbits'},
            "SpeedMin": threshold.FAN_SPEED_MIN,
            "SpeedMax": threshold.FAN_SPEED_MAX,
            "led": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_LEDCTL, 'bit': 0, 'bits':4, 'way': 'smbusbits'},
            "led_attrs": {"off": {"blink": 0x0b, "steady": 0x0b}, "green": {"blink": 0x0d, "steady": 0x09}, "yellow": {"blink": 0x07, "steady": 0x03}, "red": {"blink": 0x0e, "steady": 0x0a}},
            "SpeedPWM": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_PWM, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
            "Rotor": {
                        "Rotor1_config": {
                                            "name": "Rotor1",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_ROTOR1_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR1_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR1_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                        "Rotor2_config": {
                                            "name": "Rotor2",
                                            "SpeedValue": {'addr' : fan_cpld_reg.FANCPLD_I2C_ADDR, 'offset': fan_cpld_reg.FANCPLD_FAN4_ROTOR2_SPEED, 'bit': 0, 'bits':8, 'way': 'smbusbits'},
                                            "SpeedMin": threshold.FAN_ROTOR2_SPEED_MIN,
                                            "SpeedMax": threshold.FAN_ROTOR2_SPEED_MAX,
                                            "SpeedUnit": Unit.Speed,
                                         },
                    },
        }
    ],
    "cplds": [
        {
            "name": "BASE_CPLD",
            "UserReg": {"loc": "/sys/bus/i2c/devices/0-000d/cpld_test", "way": "sysfs"},
            "ConsoleSel": {"loc": "/sys/bus/i2c/devices/0-000d/uart_sel", "way": "sysfs"},
            "ConsoleSelState": {"loc": "/sys/bus/i2c/devices/0-000d/uart_status", "way": "sysfs"},
            "ConsoleSelUpdate": {"loc": "/sys/bus/i2c/devices/0-000d/uart_sel_update", "way": "sysfs"},
            "ConsoleSelAttrs" : {"cpu": 0x00, "bmc": 0x01},
            "MajorVerFile": {"loc": "/sys/bus/i2c/devices/0-000d/cpld_major_ver", "way": "sysfs"},
            "MinorVerFile": {"loc": "/sys/bus/i2c/devices/0-000d/cpld_minor_ver", "way": "sysfs"},
            "UpgradeCommand": {"cmdline": "/usr/local/bin/cpld_update.sh update %s %s"},
            "UpgradeResultFile": "/var/log/fw/upgrade_refresh_result",
        },
        {
            "name": "FAN1_CPLD",
            "MajorVerFile": {"loc": "/sys/bus/i2c/devices/8-000d/cpld_major_ver", "way": "sysfs"},
            "MinorVerFile": {"loc": "/sys/bus/i2c/devices/8-000d/cpld_minor_ver", "way": "sysfs"},
            "UpgradeCommand": {"cmdline": "/usr/local/bin/cpld_update.sh update %s %s"},
            "UpgradeResultFile": "/var/log/fw/upgrade_refresh_result",
        },
        {
            "name": "FAN2_CPLD",
            "MajorVerFile": {"loc": "/sys/bus/i2c/devices/3-000d/cpld_major_ver", "way": "sysfs"},
            "MinorVerFile": {"loc": "/sys/bus/i2c/devices/3-000d/cpld_minor_ver", "way": "sysfs"},
            "UpgradeCommand": {"cmdline": "/usr/local/bin/cpld_update.sh update %s %s"},
            "UpgradeResultFile": "/var/log/fw/upgrade_refresh_result",
        },
        {
            "name": "OCM_CPLD",
            "MajorVerFile": {"loc": "/sys/bus/i2c/devices/16-000d/cpld_major_ver", "way": "sysfs"},
            "MinorVerFile": {"loc": "/sys/bus/i2c/devices/16-000d/cpld_minor_ver", "way": "sysfs"},
            "UpgradeCommand": {"cmdline": "/usr/local/bin/cpld_update.sh update %s %s"},
            "UpgradeResultFile": "/var/log/fw/upgrade_refresh_result",
        },
        {
            "name": "PORT1_CPLD",
            "MajorVerFile": {"loc": "/sys/bus/i2c/devices/64-0031/cpld_major_ver", "way": "sysfs"},
            "MinorVerFile": {"loc": "/sys/bus/i2c/devices/64-0031/cpld_minor_ver", "way": "sysfs"},
            "UpgradeCommand": {"cmdline": "/usr/local/bin/cpld_update.sh update %s %s"},
            "UpgradeResultFile": "/var/log/fw/upgrade_refresh_result",
        },
        {
            "name": "PORT2_CPLD",
            "MajorVerFile": {"loc": "/sys/bus/i2c/devices/65-0031/cpld_major_ver", "way": "sysfs"},
            "MinorVerFile": {"loc": "/sys/bus/i2c/devices/65-0031/cpld_minor_ver", "way": "sysfs"},
            "UpgradeCommand": {"cmdline": "/usr/local/bin/cpld_update.sh update %s %s"},
            "UpgradeResultFile": "/var/log/fw/upgrade_refresh_result",
        },
        {
            "name": "MISC_CPLD",
            "MajorVerFile": {"loc": "/sys/bus/i2c/devices/66-0031/cpld_major_ver", "way": "sysfs"},
            "MinorVerFile": {"loc": "/sys/bus/i2c/devices/66-0031/cpld_minor_ver", "way": "sysfs"},
            "UpgradeCommand": {"cmdline": "/usr/local/bin/cpld_update.sh update %s %s"},
            "UpgradeResultFile": "/var/log/fw/upgrade_refresh_result",
        },
        {
            "name": "LED_CPLD",
            "MajorVerFile": {"loc": "/sys/bus/i2c/devices/68-0031/cpld_major_ver", "way": "sysfs"},
            "MinorVerFile": {"loc": "/sys/bus/i2c/devices/68-0031/cpld_minor_ver", "way": "sysfs"},
            "UpgradeCommand": {"cmdline": "/usr/local/bin/cpld_update.sh update %s %s"},
            "UpgradeResultFile": "/var/log/fw/upgrade_refresh_result",
        },
    ],
    "bioss": [
        {
            "name": "master",
            "FwVersion": "/var/log/fw/fw_version",
            "BiosStatus": {"loc": "/sys/bus/i2c/devices/0-000d/bios_sel_status", "way": "sysfs"},
            "BiosFwUpdata": {"cmdline": "/usr/local/bin/fwm_util.sh bios %s %s"},
            "BiosNextBoot": {"loc": "/sys/bus/i2c/devices/0-000d/bios_manual_switch", "way": "sysfs"},
            "NextBootSetting": {"cmdline": "/usr/local/bin/boot_area.sh bios %s"},
        },
    ],
    "bmcs": [
        {
            "name": "master",
            "FwVersion": {"loc": "/etc/issue","way": "file"},
            "CurrentBoot": {"loc": "/usr/local/bin/boot_area.sh bmc status", "way": "command"},
            "NextBoot": {"loc": "/usr/local/bin/boot_area.sh bmc nextboot", "way": "command"},
            "MasterVersion": {"loc": "/var/volatile/log/primary_version", "way": "file"},
            "SlaveVersion": {"loc": "/var/volatile/log/secondary_version", "way": "file"},
            "BmcFwUpdata": {"cmdline": "/usr/local/bin/fwm_util.sh bmc %s %s"},
            "SysAirFlow": "F2B",
            "SysLedState": {"loc": "/sys/bus/i2c/devices/0-000d/sys_led_ctrl", "way": "sysfs"},
            "SysLedAttrs": {"off": {"blink": 0x00, "steady": 0x00}, "green": {"blink": 0x03, "steady": 0x04}, "yellow": {"blink": 0x05, "steady": 0x06}},
            "PwrLedCtrl": {"loc": "/sys/bus/i2c/devices/0-000d/psu_led_ctrl_status", "way": "sysfs"},
            "PwrLedState": {"loc": "/sys/bus/i2c/devices/0-000d/psu_led_ctrl", "way": "sysfs"},
            "PwrLedAttrs": {"off": {"blink": 0x00, "steady": 0x00}, "green": {"blink": 0x03, "steady": 0x04}, "yellow": {"blink": 0x05, "steady": 0x06}},
            "SysFanLedCtrl": {"loc": "/sys/bus/i2c/devices/8-000d/fan_led_ctrl_status", "way": "sysfs"},
            "SysFanLedState": {"loc": "/sys/bus/i2c/devices/8-000d/fan_led_ctrl", "way": "sysfs"},
            "SysFanLedAttrs": {"off": {"blink": 0x00, "steady": 0x00}, "green": {"blink": 0x03, "steady": 0x04}, "yellow": {"blink": 0x05, "steady": 0x06}},
            "PortLedState_1": {"loc": "/sys/bus/i2c/devices/64-0031/led_ctrl", "way": "sysfs"},
            "PortLedState_2": {"loc": "/sys/bus/i2c/devices/65-0031/led_ctrl", "way": "sysfs"},
            "PortLedAttrs": {"off": 0x00, "on": 0x03},
        },
    ],
    "cpu": [
        {
            "name": "master",
            "CpuStatus_S3": {"loc": "/sys/bus/i2c/devices/0-000d/cpu_slp_s3_state", "way": "sysfs"},
            "CpuStatus_S45": {"loc": "/sys/bus/i2c/devices/0-000d/cpu_slp_s45_state", "way": "sysfs"},
            "CpuReset": {"loc": "/sys/bus/i2c/devices/0-000d/cpu_reset", "way": "sysfs"},
            "CpuMCERR": {"loc": "/var/volatile/log/MCERR_cnt", "way": "sysfs"},
            "CpuIERR": {"loc": "/var/volatile/log/IERR_cnt", "way": "sysfs"},
            "CpuAER_err0": {"loc": "/var/volatile/log/CPU_ERR0_cnt", "way": "sysfs"},
            "CpuAER_err1": {"loc": "/var/volatile/log/CPU_ERR1_cnt", "way": "sysfs"},
            "CpuAER_err2": {"loc": "/var/volatile/log/CPU_ERR2_cnt", "way": "sysfs"},
            "CpuResetType": {"loc": "/sys/bus/i2c/devices/0-000d/cpu_reset_type", "way": "sysfs"},
        }
    ],
}
