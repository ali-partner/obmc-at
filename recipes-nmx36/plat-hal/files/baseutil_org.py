# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/baseutil.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 2111 bytes
import json, importlib.util, re, syslog
SYSLOG_IDENTIFIER = "BMC"
SENSOR_CHIP_NAME = "/sys/bus/i2c/devices/17-0058/name"
PRODUCT_NAME = "/etc/openbmc/product_name"

class baseutil:
    CONFIG_PATH_FORMAT = "/usr/lib/python3.14/site-packages/product_hal/%s/%s_devices.py"
    CONFIG_NAME = "devices"
    UBOOT_ENV_URL = "/etc/device/uboot_env"

    @staticmethod
    def get_config():
        fullname = baseutil.get_product_fullname()
        productname = baseutil.get_productname()
        if productname == "AS42-64S-AT":
            with open(SENSOR_CHIP_NAME, 'r') as file:
                content = file.read()
                if "xdpe12284" in content:
                    fullname = fullname + "_infineon"
                else:
                    fullname = fullname + "_mps"
        real_path = baseutil.CONFIG_PATH_FORMAT % (productname, fullname)
        #devices = imp.load_source(baseutil.CONFIG_NAME, real_path)
        spec = importlib.util.spec_from_file_location(baseutil.CONFIG_NAME, real_path)
        devices = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(devices)
        return devices.devices

    @staticmethod
    def get_productname():
        with open(PRODUCT_NAME, 'r') as file:
            product_name = file.read()
        product_name = product_name.rstrip("\n")
        return product_name

    @staticmethod
    def get_platform():
        product_name = baseutil.get_productname()
        product_name = product_name.rstrip("-AT")
        platform = product_name.lower()
        return platform

    @staticmethod
    def get_product_fullname():
        product_fullname = baseutil.get_productname()
        product_fullname = product_fullname.lower().replace("-", "_")
        return product_fullname

    @staticmethod
    def logger_debug(msg):
        syslog.openlog(SYSLOG_IDENTIFIER)
        syslog.syslog(syslog.LOG_DEBUG, msg)
        syslog.closelog()
