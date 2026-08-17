# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/osutil.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 7761 bytes
import subprocess
import glob
import time
import functools
from plat_hal.smbus import SMBus

def retry(maxretry=6, delay=0.01):
    """
        maxretry:  max retry times
        delay   :  interval after last retry
    """
    def decorator_retry(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            time_retry = maxretry
            time_delay = delay
            result_msg = ""
            while time_retry:
                try:
                    val, result_msg = func(*args, **kwargs)
                    if val is False:
                        time_retry -= 1
                        time.sleep(time_delay)
                        continue
                    else:
                        return (val, result_msg)
                except Exception as e:
                    time_retry -= 1
                    result_msg = str(e)
                    time.sleep(time_delay)
            return (False, "last retry errmsg is {}".format(result_msg))
        return wrapper
    return decorator_retry


class osutil(object):
    __doc__ = "\n       osutil\n    "

    @staticmethod
    def write_sysfs_node_value(node_path, value):
        if not os.path.isfile(node_path):
            return (False, "sysfs node not exist")

        value_str = str(value)
        try:
            with open(node_path, 'w') as file:
                file.write(value_str)
        except Exception as e:
            return (False, str(e))

        return (True, "")

    @staticmethod
    def read_file(file_name):
        try:
            with open(file_name, 'r') as file:
                content = file.read().strip()
        except Exception as e:
                return (False, str(e) + " file_name[%s]" % file_name)

        return (True, content)

    @staticmethod
    def command(cmdstr):
        retcode, output = subprocess.getstatusoutput(cmdstr)
        return (retcode, output)

    @staticmethod
    def get_i2c_bysmbus(smbus_obj, addr, offset):
        retrytime = 6
        val = ""
        for i in range(retrytime):
            ret, val  = smbus_obj.read_byte_data(addr, offset, True)
            if ret == True:
                return (True, val)
            time.sleep(0.1)

        return (False, val)

    @staticmethod
    def i2cgetbyte_i2ctool(bus, devno, address):
        command_line = "i2cget -f -y %d 0x%02x 0x%02x" % (bus, devno, address)
        retrytime = 6
        ret_t = ""
        for i in range(retrytime):
            ret, ret_t = osutil.command(command_line)
            if ret == 0:
                return (True, int(ret_t, 16))
            time.sleep(0.1)

        return (False, ret_t)

    @staticmethod
    def i2csetbyte_i2ctool(bus, devno, address, byte):
        command_line = "i2cset -f -y %d 0x%02x 0x%02x 0x%02x" % (bus, devno, address, byte)
        retrytime = 6
        ret_t = ""
        for i in range(retrytime):
            ret, ret_t = osutil.command(command_line)
            if ret == 0:
                return (True, ret_t)
            time.sleep(0.1)

        return (False, ret_t)

    @staticmethod
    def geti2cword_i2ctool(bus, addr, offset):
        command_line = "i2cget -f -y %d 0x%02x 0x%02x w" % (bus, addr, offset)
        retrytime = 6
        ret_t = ""
        for i in range(retrytime):
            ret, ret_t = osutil.command(command_line)
            if ret == 0:
                return (True, int(ret_t, 16))
            time.sleep(0.1)

        return (False, ret_t)

    @staticmethod
    def seti2cword_i2ctool(bus, addr, offset, val):
        command_line = "i2cset -f -y %d 0x%02x 0x%0x 0x%04x w" % (bus, addr, offset, val)
        retrytime = 6
        ret_t = ""
        for i in range(retrytime):
            ret, ret_t = osutil.command(command_line)
            if ret == 0:
                return (True, ret_t)
            time.sleep(0.1)

        return (False, ret_t)

    @staticmethod
    def byteTostr(val):
        strtmp = ""
        for i in range(len(val)):
            strtmp += chr(val[i])

        return strtmp

    @staticmethod
    def find_real_file_path(location):
        try:
            locations = glob.glob(location)
            if len(locations) > 0:
                return (True, locations[0])
            else:
                return (False, 'not found')
        except Exception as e:
            return (False, str(e) + " location[%s] not found" % location)

    @staticmethod
    def read_real_sysfs(location):
        """
        Get sys value by full file path
        """
        max_retries = 10
        for attempt in range(max_retries):
            try:
                with open(location, 'r') as file:
                    first_line = file.readline().strip()
                    if "0x" in first_line:
                        value = int(first_line, 16)
                    else:
                        value = int(first_line)
                break
            except Exception as e:
                if attempt < max_retries - 1:
                    time.sleep(0.3)
                    continue
                else:
                    return (False, str(e) + " location[%s]" % location)

        return (True, value)

    @staticmethod
    def write_real_sysfs(location, value):
        """
        Set sys value by full file path
        """
        try:
            with open(location, "r+") as fd:
                write_len = fd.write(str(value))
        except Exception as e:
            return (False, str(e) + " location[%s]" % location)

        return (True, write_len)

    @staticmethod
    def readsysfs(location, size):
        """
        Get sys value by Flexible file path
          such as   /*/*/test
        """
        try:
            locaitons = glob.glob(location)
            with open(locaitons[0], "rb") as fd1:
                if size is None:
                    tmp = fd1.read()
                else:
                    tmp = fd1.read(size)
            retval = osutil.byteTostr(tmp)
        except Exception as e:
            return (False, str(e) + " location[%s]" % location)

        return (True, retval)

    @staticmethod
    def getdevmem(addr, digit, mask):
        command_line = "devmem 0x%02x %d" % (addr, digit)
        retrytime = 6
        ret_t = ""
        for i in range(retrytime):
            ret, ret_t = osutil.command(command_line)
            if ret == 0 and mask != None:
                ret_t = str(int(ret_t, 16) & mask)
            return (True, ret_t)

        return (False, ret_t)

    @staticmethod
    def set_i2c_bysmbus(smbus_obj, addr, offset, val):
        retrytime = 6
        for i in range(retrytime):
            ret, val = smbus_obj.write_byte_data(addr, offset, val, True)
            if ret == True:
                return True
            time.sleep(0.1)

        return False