# uncompyle6 version 3.9.2
# Python bytecode version base 3.5.2 (3351)
# Decompiled from: Python 2.7.17 (default, Mar  8 2023, 18:40:28) 
# [GCC 7.5.0]
# Embedded file name: /usr/lib/python3.5/site-packages/plat_hal/devicebase.py
# Compiled at: 2024-04-26 01:38:48
# Size of source mod 2**32: 8813 bytes
from .osutil import osutil
from .baseutil import baseutil

class devicebase:
    _name = None

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, val):
        self._name = val

    def get_value(self, config):
        """
            get value by config way
            way  i2c/sysfs/lpc
        """
        if config is None:
            return (False, None)

        way = config.get("way")
        if way == "sysfs":
            sysfs_node = config.get("loc")
            return self.get_sysfs_value(sysfs_node)
        if way == "command":
            cmd_line = config.get("loc")
            return self.get_command_value(cmd_line)
        if way == "file":
            file_name = config.get("loc")
            return self.read_file(file_name)
        if way == "i2c":
            bus = config.get("bus")
            addr = config.get("addr")
            offset = config.get("offset")
            return self.get_i2c(bus, addr, offset)
        if way == "i2cword":
            bus = config.get("bus")
            addr = config.get("addr")
            offset = config.get("offset")
            return self.get_i2cword(bus, addr, offset)
        if way == "devmem":
            addr = config.get("addr")
            digit = config.get("digit")
            mask = config.get("mask", None)
            return self.get_devmem(addr, digit, mask)
        raise Exception("cannot found way deal")

    def find_real_file_path(self, loc):
        return osutil.find_real_file_path(loc)

    def read_real_sysfs(self, loc):
        return osutil.read_real_sysfs(loc)

    def get_sysfs_value(self, sysfs_node):
        ret, val = self.find_real_file_path(sysfs_node)
        if ret == False:
            return (ret, val)

        location = val
        ret, val = self.read_real_sysfs(location)
        return (ret, val)

    def read_sysfs_value(self, config):
        location = config.get("loc")
        ret, val = self.read_real_sysfs(location)
        return (ret, val)

    def command(self, cmd):
        ret, output = osutil.command(cmd)
        return (ret, output)

    def get_command_value(self, cmd):
        ret, output = self.command(cmd)
        if ret != 0:
            return (False, output)
        else:
            return (True, output)

    def read_file(self, name):
        ret, output = osutil.read_file(name)
        return (ret, output)

    def get_devmem(self, addr, digit, mask):
        return osutil.getdevmem(addr, digit, mask)

    def get_i2c(self, bus, addr, offset):
        return osutil.i2cgetbyte_i2ctool(bus, addr, offset)

    def get_i2cword(self, bus, addr, offset):
        return osutil.geti2cword_i2ctool(bus, addr, offset)

    def get_i2cbits_by_smbus(self, smbus_obj, config):
        addr = config.get("addr")
        offset = config.get("offset")
        start_bit = config.get("bit")
        bit_count = config.get("bits")
        ret, val = osutil.get_i2c_bysmbus(smbus_obj, addr, offset)
        if ret != True:
            return ret, val
        mask = ((1 << bit_count) - 1) << start_bit
        masked_value = val & mask
        result = masked_value >> start_bit
        return ret, result

    def get_i2cbit(self, bus, addr, offset, bit):
        ret, val = self.get_i2c(bus, addr, offset)
        if ret == False:
            bit_val = val
        else:
            bit_val = (val & 1 << bit) >> bit
        return (ret, bit_val)

    def get_data_shift(self, bus, addr, offset, mask, shift, direction):
        ret, val = self.get_i2c(bus, addr, offset)
        if ret == False:
            return (ret, val)
        data = self.get_reg_data(val, mask, shift, direction)
        return (ret, data)

    def get_reg_data(self, val, mask, shift, direction):
        data = val
        if mask == None:
            if direction == "right":
                data = val >> shift
            else:
                data = val << shift
        elif direction == "right":
            data = (val & mask) >> shift
        else:
            data = (val & mask) << shift
        return data

    def get_fru_item(self, name, item):
        cmd = 'fruid-util %s' % (name)
        ret, output = osutil.command(cmd)
        if ret != 0 or output is None or output == '':
            return (False, "N/A")

        info = "N/A"
        for line in output.splitlines():
            if item in line:
                info = line.split(':', 1)[-1].strip()
                break

        if info == "N/A" or len(info) == 0:
            return (False, "N/A")
        return (True, info)

    def get_fru_basic_info(self, name):
        basic_info_dict = {
            "Board Mfg"             : "N/A",
            "Board Product"         : "N/A",
            "Board Serial"          : "N/A",
            "Board Part Number"     : "N/A",
            "Product Manufacturer"  : "N/A",
            "Product Name"          : "N/A",
            "Product Part Number"   : "N/A",
            "Product Version"       : "N/A",
            "Product Serial"        : "N/A",
        }
        
        cmd = 'fruid-util %s' % (name)
        ret, output = osutil.command(cmd)
        if ret != 0 or output is None or output == '':
            return basic_info_dict

        for item in basic_info_dict:
            for line in output.splitlines():
                if item in line:
                    basic_info_dict[item] = line.split(':', 1)[-1].strip()
                    break

        return basic_info_dict


    def set_value(self, config, val):
        """
            get value by config way
            way  i2c/sysfs/lpc
        """
        way = config.get("way")
        if way == "sysfs":
            sysfs_node = config.get("loc")
            return self.set_sysfs_value(sysfs_node, val)
        elif way == "i2c":
            bus = config.get("bus")
            addr = config.get("addr")
            offset = config.get("offset")
            return self.set_i2c(bus, addr, offset, val)
        if way == "i2cpec":
            bus = config.get("bus")
            addr = config.get("addr")
            offset = config.get("offset")
            return self.seti2c_byte_pec(bus, addr, offset, val)
        if way == "i2cword":
            bus = config.get("bus")
            addr = config.get("addr")
            offset = config.get("offset")
            return self.set_i2cword(bus, addr, offset, val)
        if way == "i2cwordpec":
            bus = config.get("bus")
            addr = config.get("addr")
            offset = config.get("offset")
            return self.set_i2cwordpec(bus, addr, offset, val)
        if way == "i2cbit":
            bus = config.get("bus")
            addr = config.get("addr")
            offset = config.get("offset")
            bit = config.get("bit", 0)
            return self.set_i2cbit(bus, addr, offset, bit, val)
        if way == "i2cbitblock":
            bus = config.get("bus")
            addr = config.get("addr")
            offset = config.get("offset")
            mask = config.get("mask", None)
            return self.set_data_shift(bus, addr, offset, mask, val)

    def write_real_sysfs(self, loc, value):
        return osutil.write_real_sysfs(loc, value)

    def set_sysfs_value(self, sysfs_node, value):
        ret, val = self.write_real_sysfs(sysfs_node, value)
        return (ret, val)

    def set_i2cword(self, bus, addr, offset, val):
        return self.seti2cword(bus, addr, offset, val)

    def seti2cword(self, bus, addr, offset, val):
        return osutil.seti2cword(bus, addr, offset, val)

    def set_i2cwordpec(self, bus, addr, offset, val):
        return osutil.seti2cwordpec(bus, addr, offset, val)

    def seti2c_byte_pec(self, bus, addr, offset, val):
        return osutil.seti2c_byte_pec(bus, addr, offset, val)

    def set_i2c(self, bus, addr, offset, val):
        return self.seti2c(bus, addr, offset, val)

    def seti2c(self, bus, addr, offset, val):
        ret, val = osutil.rji2cset(bus, addr, offset, val)
        return (ret, val)

    def set_i2cbit(self, bus, addr, offset, bit, val):
        returnmsg = ""
        ret = False
        if val != 1 and val != 0:
            returnmsg = "ERR: illegal parameter %d" % val
            return (ret, returnmsg)
        ret, read_val = self.get_i2c(bus, addr, offset)
        if ret == False:
            returnmsg = read_val
            self.logger_debug("end set_i2cbit, get i2c bus:%d addr:0x%x offset:0x%x failed" % (bus, addr, offset))
        elif val == 1:
            set_value = read_val | 1 << bit
        else:
            set_value = read_val & ~(1 << bit)
        ret, returnmsg = self.set_i2c(bus, addr, offset, set_value)
        return (ret, returnmsg)

    def logger_debug(self, msg):
        baseutil.logger_debug(msg)

    def set_i2cbits_by_smbus(self, smbus_obj, config, value):
        addr = config.get("addr")
        offset = config.get("offset")
        start_bit = config.get("bit")
        bit_count = config.get("bits")
        ret, val = osutil.get_i2c_bysmbus(smbus_obj, addr, offset)
        if ret != True:
            return ret
        mask = ((1 << bit_count) - 1) << start_bit
        clear_mask = ~mask & 0xFF
        cleared_byte = val & clear_mask
        new_bits = value << start_bit
        setvalue = cleared_byte | new_bits

        ret = osutil.set_i2c_bysmbus(smbus_obj, addr, offset, setvalue)
        return ret

