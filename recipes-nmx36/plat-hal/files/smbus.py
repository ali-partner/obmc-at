#!/usr/bin/python
# smbus2 - A drop-in replacement for smbus-cffi/smbus-python
# The MIT License (MIT)
# Copyright (c) 2017 Karl-Petter Lindegaard
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
import sys
from fcntl import ioctl
from ctypes import c_uint32, c_uint8, c_uint16, c_char, c_ulong, POINTER, Structure, Array, Union, create_string_buffer, string_at
import time

# Commands from uapi/linux/i2c-dev.h
I2C_SLAVE = 0x0703  # Use this slave address
I2C_SLAVE_FORCE = 0x0706  # Use this slave address, even if it is already in use by a driver!
I2C_FUNCS = 0x0705  # Get the adapter functionality mask
I2C_RDWR = 0x0707  # Combined R/W transfer (one STOP only)
I2C_SMBUS = 0x0720  # SMBus transfer. Takes pointer to i2c_smbus_ioctl_data
I2C_PEC = 0x0708

# SMBus transfer read or write markers from uapi/linux/i2c.h
I2C_SMBUS_WRITE = 0
I2C_SMBUS_READ = 1

# Size identifiers uapi/linux/i2c.h
I2C_SMBUS_QUICK = 0
I2C_SMBUS_BYTE = 1
I2C_SMBUS_BYTE_DATA = 2
I2C_SMBUS_WORD_DATA = 3
I2C_SMBUS_PROC_CALL = 4
# This isn't supported by Pure-I2C drivers with SMBUS emulation, like those in RaspberryPi, OrangePi, etc :(
I2C_SMBUS_BLOCK_DATA = 5
I2C_SMBUS_BLOCK_PROC_CALL = 7  # Like I2C_SMBUS_BLOCK_DATA, it isn't supported by Pure-I2C drivers either.
I2C_SMBUS_I2C_BLOCK_DATA = 8
I2C_SMBUS_BLOCK_MAX = 32

# To determine what functionality is present (uapi/linux/i2c.h)
try:
    from enum import IntFlag
except ImportError:
    IntFlag = int


class I2cFunc(IntFlag):
    """
    These flags identify the operations supported by an I2C/SMBus device.

    You can test these flags on your `smbus.funcs`

    On newer python versions, I2cFunc is an IntFlag enum, but it
    falls back to class with a bunch of int constants on older releases.
    """
    I2C = 0x00000001
    ADDR_10BIT = 0x00000002
    PROTOCOL_MANGLING = 0x00000004  # I2C_M_IGNORE_NAK etc.
    SMBUS_PEC = 0x00000008
    NOSTART = 0x00000010  # I2C_M_NOSTART
    SLAVE = 0x00000020
    SMBUS_BLOCK_PROC_CALL = 0x00008000  # SMBus 2.0
    SMBUS_QUICK = 0x00010000
    SMBUS_READ_BYTE = 0x00020000
    SMBUS_WRITE_BYTE = 0x00040000
    SMBUS_READ_BYTE_DATA = 0x00080000
    SMBUS_WRITE_BYTE_DATA = 0x00100000
    SMBUS_READ_WORD_DATA = 0x00200000
    SMBUS_WRITE_WORD_DATA = 0x00400000
    SMBUS_PROC_CALL = 0x00800000
    SMBUS_READ_BLOCK_DATA = 0x01000000
    SMBUS_WRITE_BLOCK_DATA = 0x02000000
    SMBUS_READ_I2C_BLOCK = 0x04000000  # I2C-like block xfer
    SMBUS_WRITE_I2C_BLOCK = 0x08000000  # w/ 1-byte reg. addr.
    SMBUS_HOST_NOTIFY = 0x10000000

    SMBUS_BYTE = 0x00060000
    SMBUS_BYTE_DATA = 0x00180000
    SMBUS_WORD_DATA = 0x00600000
    SMBUS_BLOCK_DATA = 0x03000000
    SMBUS_I2C_BLOCK = 0x0c000000
    SMBUS_EMUL = 0x0eff0008


# i2c_msg flags from uapi/linux/i2c.h
I2C_M_RD = 0x0001

# Pointer definitions
LP_c_uint8 = POINTER(c_uint8)
LP_c_uint16 = POINTER(c_uint16)
LP_c_uint32 = POINTER(c_uint32)


#############################################################
# Type definitions as in i2c.h


class i2c_smbus_data(Array):
    """
    Adaptation of the i2c_smbus_data union in ``i2c.h``.

    Data for SMBus messages.
    """
    _length_ = I2C_SMBUS_BLOCK_MAX + 2
    _type_ = c_uint8


class union_i2c_smbus_data(Union):
    _fields_ = [
        ("byte", c_uint8),
        ("word", c_uint16),
        ("block", i2c_smbus_data)
    ]


union_pointer_type = POINTER(union_i2c_smbus_data)


class i2c_smbus_ioctl_data(Structure):
    """
    As defined in ``i2c-dev.h``.
    """
    _fields_ = [
        ('read_write', c_uint8),
        ('command', c_uint8),
        ('size', c_uint32),
        ('data', union_pointer_type)]
    __slots__ = [name for name, type in _fields_]

    @staticmethod
    def create(read_write=I2C_SMBUS_READ, command=0, size=I2C_SMBUS_BYTE_DATA):
        u = union_i2c_smbus_data()
        return i2c_smbus_ioctl_data(
            read_write=read_write, command=command, size=size,
            data=union_pointer_type(u))


class SMBus(object):

    def __init__(self, bus=None, force=False):
        """
        Initialize and (optionally) open an i2c bus connection.

        :param bus: i2c bus number (e.g. 0 or 1)
            or an absolute file path (e.g. `/dev/i2c-42`).
            If not given, a subsequent  call to ``open()`` is required.
        :type bus: int or str
        :param force: force using the slave address even when driver is
            already using it.
        :type force: boolean
        """
        self.fd = None
        self.funcs = I2cFunc(0)
        if bus is not None:
            self.open(bus)
        self.address = None
        self.force = force
        self._force_last = None

    def __enter__(self):
        """Enter handler."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Exit handler."""
        self.close()
    
    def __del__(self):
        self.close()

    def open(self, bus):
        """
        Open a given i2c bus.

        :param bus: i2c bus number (e.g. 0 or 1)
            or an absolute file path (e.g. '/dev/i2c-42').
        :type bus: int or str
        :raise TypeError: if type(bus) is not in (int, str)
        """
        if isinstance(bus, int):
            filepath = "/dev/i2c-{}".format(bus)
        elif isinstance(bus, str):
            filepath = bus
        else:
            raise TypeError("Unexpected type(bus)={}".format(type(bus)))

        self.fd = os.open(filepath, os.O_RDWR)
        self.funcs = self._get_funcs()

    def close(self):
        """
        Close the i2c connection.
        """
        if self.fd:
            os.close(self.fd)
            self.fd = None

    def _set_address(self, address, force=None):
        """
        Set i2c slave address to use for subsequent calls.

        :param address:
        :type address: int
        :param force:
        :type force: Boolean
        """
        force = force if force is not None else self.force
        if self.address != address or self._force_last != force:
            if force is True:
                ioctl(self.fd, I2C_SLAVE_FORCE, address)
            else:
                ioctl(self.fd, I2C_SLAVE, address)
            self.address = address
            self._force_last = force

    def _get_funcs(self):
        """
        Returns a 32-bit value stating supported I2C functions.

        :rtype: int
        """
        f = c_ulong()
        ioctl(self.fd, I2C_FUNCS, f)
        return f.value & 0xFFFFFFFF

    def write_quick(self, i2c_addr, force=None):
        """
        Perform quick transaction. Throws IOError if unsuccessful.
        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param force:
        :type force: Boolean
        """
        self._set_address(i2c_addr, force=force)
        msg = i2c_smbus_ioctl_data.create(
            read_write=I2C_SMBUS_WRITE, command=0, size=I2C_SMBUS_QUICK)
        ioctl(self.fd, I2C_SMBUS, msg)

    def read_byte(self, i2c_addr, force=None):
        """
        Read a single byte from a device.

        :rtype: int
        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param force:
        :type force: Boolean
        :return: Read byte value
        """
        self._set_address(i2c_addr, force=force)
        msg = i2c_smbus_ioctl_data.create(
            read_write=I2C_SMBUS_READ, command=0, size=I2C_SMBUS_BYTE
        )
        ioctl(self.fd, I2C_SMBUS, msg)
        return msg.data.contents.byte

    def write_byte(self, i2c_addr, value, force=None):
        """
        Write a single byte to a device.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param value: value to write
        :type value: int
        :param force:
        :type force: Boolean
        """
        self._set_address(i2c_addr, force=force)
        msg = i2c_smbus_ioctl_data.create(
            read_write=I2C_SMBUS_WRITE, command=value, size=I2C_SMBUS_BYTE
        )
        ioctl(self.fd, I2C_SMBUS, msg)

    def read_byte_data(self, i2c_addr, register, force=None):
        """
        Read a single byte from a designated register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Register to read
        :type register: int
        :param force:
        :type force: Boolean
        :return: Read byte value
        :rtype: int
        """
        val_t = -1
        returnmsg = ""
        try:
            self._set_address(i2c_addr, force=force)
            msg = i2c_smbus_ioctl_data.create(
                read_write=I2C_SMBUS_READ, command=register, size=I2C_SMBUS_BYTE_DATA
            )
            val_t = ioctl(self.fd, I2C_SMBUS, msg)
        except Exception as e:
            self.close()
            returnmsg = str(e)
        if val_t < 0:
            return False, returnmsg
        return True, msg.data.contents.byte

    def write_byte_data(self, i2c_addr, register, value, force=None):
        """
        Write a byte to a given register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Register to write to
        :type register: int
        :param value: Byte value to transmit
        :type value: int
        :param force:
        :type force: Boolean
        :rtype: None
        """
        val_t = -1
        returnmsg = ""
        try:
            self._set_address(i2c_addr, force=force)
            msg = i2c_smbus_ioctl_data.create(
                read_write=I2C_SMBUS_WRITE, command=register, size=I2C_SMBUS_BYTE_DATA
            )
            msg.data.contents.byte = value
            val_t = ioctl(self.fd, I2C_SMBUS, msg)
        except Exception as e:
            returnmsg = str(e)
            self.close()
        if val_t < 0:
            return False, returnmsg or ""
        return True, ""

    def write_byte_data_pec(self, i2c_addr, register, value, force=None):
        """
        Write a byte to a given register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Register to write to
        :type register: int
        :param value: Byte value to transmit
        :type value: int
        :param force:
        :type force: Boolean
        :rtype: None
        """
        val_t = -1
        returnmsg = ""
        try:
            val_t = ioctl(self.fd, I2C_PEC, 1)
            if val_t < 0:
                raise Exception("set pec mod error")
            self._set_address(i2c_addr, force=force)
            msg = i2c_smbus_ioctl_data.create(
                read_write=I2C_SMBUS_WRITE, command=register, size=I2C_SMBUS_BYTE_DATA
            )
            msg.data.contents.byte = value
            val_t = ioctl(self.fd, I2C_SMBUS, msg)
        except Exception as e:
            returnmsg = str(e)
            self.close()
        if val_t < 0:
            return False, returnmsg or ""
        return True, ""

    def read_word_data(self, i2c_addr, register, force=None):
        """
        Read a single word (2 bytes) from a given register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Register to read
        :type register: int
        :param force:
        :type force: Boolean
        :return: 2-byte word
        :rtype: int
        """
        val_t = -1
        returnmsg = ""
        try:
            self._set_address(i2c_addr, force=force)
            msg = i2c_smbus_ioctl_data.create(
                read_write=I2C_SMBUS_READ, command=register, size=I2C_SMBUS_WORD_DATA
            )
            val_t = ioctl(self.fd, I2C_SMBUS, msg)
        except Exception as e:
            returnmsg = str(e)
            self.close()
        if val_t < 0:
            return False, returnmsg or ""
        return True, msg.data.contents.word

    def write_word_data_pec(self, i2c_addr, register, value, force=None):
        """
        Write a byte to a given register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Register to write to
        :type register: int
        :param value: Word value to transmit
        :type value: int
        :param force:
        :type force: Boolean
        :rtype: None
        """
        val_t = -1
        returnmsg = ""
        try:
            val_t = ioctl(self.fd, I2C_PEC, 1)
            if val_t < 0:
                raise Exception("set pec mod error")
            self._set_address(i2c_addr, force=force)
            msg = i2c_smbus_ioctl_data.create(
                read_write=I2C_SMBUS_WRITE, command=register, size=I2C_SMBUS_WORD_DATA
            )
            msg.data.contents.word = value
            val_t = ioctl(self.fd, I2C_SMBUS, msg)
        except Exception as e:
            returnmsg = str(e)
            self.close()
        if val_t < 0:
            return False, returnmsg or ""
        return True, ""

    def write_word_data(self, i2c_addr, register, value, force=None):
        """
        Write a byte to a given register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Register to write to
        :type register: int
        :param value: Word value to transmit
        :type value: int
        :param force:
        :type force: Boolean
        :rtype: None
        """
        val_t = -1
        returnmsg = ""
        try:
            self._set_address(i2c_addr, force=force)
            msg = i2c_smbus_ioctl_data.create(
                read_write=I2C_SMBUS_WRITE, command=register, size=I2C_SMBUS_WORD_DATA
            )
            msg.data.contents.word = value
            val_t = ioctl(self.fd, I2C_SMBUS, msg)
        except Exception as e:
            returnmsg = str(e)
            self.close()
        if val_t < 0:
            return False, returnmsg or ""
        return True, ""

    def process_call(self, i2c_addr, register, value, force=None):
        """
        Executes a SMBus Process Call, sending a 16-bit value and receiving a 16-bit response

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Register to read/write to
        :type register: int
        :param value: Word value to transmit
        :type value: int
        :param force:
        :type force: Boolean
        :rtype: int
        """
        self._set_address(i2c_addr, force=force)
        msg = i2c_smbus_ioctl_data.create(
            read_write=I2C_SMBUS_WRITE, command=register, size=I2C_SMBUS_PROC_CALL
        )
        msg.data.contents.word = value
        ioctl(self.fd, I2C_SMBUS, msg)
        return msg.data.contents.word

    def read_block_data(self, i2c_addr, register, force=None):
        """
        Read a block of up to 32-bytes from a given register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Start register
        :type register: int
        :param force:
        :type force: Boolean
        :return: List of bytes
        :rtype: list
        """
        val_t = -1
        try:
            self._set_address(i2c_addr, force=force)
            msg = i2c_smbus_ioctl_data.create(
                read_write=I2C_SMBUS_READ, command=register, size=I2C_SMBUS_BLOCK_DATA
            )
            val_t = ioctl(self.fd, I2C_SMBUS, msg)
            length = msg.data.contents.block[0]
        except Exception as e:
            returnmsg = str(e)
            self.close()
            return False, returnmsg or ""
        if val_t < 0:
            return False, "ioctl fail" or ""
        return True, msg.data.contents.block[1:length + 1]

    def write_block_data(self, i2c_addr, register, data, force=None):
        """
        Write a block of byte data to a given register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Start register
        :type register: int
        :param data: List of bytes
        :type data: list
        :param force:
        :type force: Boolean
        :rtype: None
        """
        length = len(data)
        if length > I2C_SMBUS_BLOCK_MAX:
            raise ValueError("Data length cannot exceed %d bytes" % I2C_SMBUS_BLOCK_MAX)
        self._set_address(i2c_addr, force=force)
        msg = i2c_smbus_ioctl_data.create(
            read_write=I2C_SMBUS_WRITE, command=register, size=I2C_SMBUS_BLOCK_DATA
        )
        msg.data.contents.block[0] = length
        msg.data.contents.block[1:length + 1] = data
        ioctl(self.fd, I2C_SMBUS, msg)

    def block_process_call(self, i2c_addr, register, data, force=None):
        """
        Executes a SMBus Block Process Call, sending a variable-size data
        block and receiving another variable-size response

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Register to read/write to
        :type register: int
        :param data: List of bytes
        :type data: list
        :param force:
        :type force: Boolean
        :return: List of bytes
        :rtype: list
        """
        length = len(data)
        if length > I2C_SMBUS_BLOCK_MAX:
            raise ValueError("Data length cannot exceed %d bytes" % I2C_SMBUS_BLOCK_MAX)
        self._set_address(i2c_addr, force=force)
        msg = i2c_smbus_ioctl_data.create(
            read_write=I2C_SMBUS_WRITE, command=register, size=I2C_SMBUS_BLOCK_PROC_CALL
        )
        msg.data.contents.block[0] = length
        msg.data.contents.block[1:length + 1] = data
        ioctl(self.fd, I2C_SMBUS, msg)
        length = msg.data.contents.block[0]
        return msg.data.contents.block[1:length + 1]

    def read_i2c_block_data(self, i2c_addr, register, length, force=None):
        """
        Read a block of byte data from a given register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Start register
        :type register: int
        :param length: Desired block length
        :type length: int
        :param force:
        :type force: Boolean
        :return: List of bytes
        :rtype: list
        """
        val_t = -1
        if length > I2C_SMBUS_BLOCK_MAX:
            raise ValueError("Desired block length over %d bytes" % I2C_SMBUS_BLOCK_MAX)
        try:
            self._set_address(i2c_addr, force=force)
            msg = i2c_smbus_ioctl_data.create(
                read_write=I2C_SMBUS_READ, command=register, size=I2C_SMBUS_I2C_BLOCK_DATA
            )
            msg.data.contents.byte = length
            val_t = ioctl(self.fd, I2C_SMBUS, msg)
        except Exception as e:
            returnmsg = str(e)
            self.close()
        if val_t < 0:
            return False, returnmsg or ""
        return True, msg.data.contents.block[1:length + 1]

    def write_i2c_block_data(self, i2c_addr, register, data, force=None):
        """
        Write a block of byte data to a given register.

        :param i2c_addr: i2c address
        :type i2c_addr: int
        :param register: Start register
        :type register: int
        :param data: List of bytes
        :type data: list
        :param force:
        :type force: Boolean
        :rtype: None
        """
        length = len(data)
        if length > I2C_SMBUS_BLOCK_MAX:
            raise ValueError("Data length cannot exceed %d bytes" % I2C_SMBUS_BLOCK_MAX)
        self._set_address(i2c_addr, force=force)
        msg = i2c_smbus_ioctl_data.create(
            read_write=I2C_SMBUS_WRITE, command=register, size=I2C_SMBUS_I2C_BLOCK_DATA
        )
        msg.data.contents.block[0] = length
        msg.data.contents.block[1:length + 1] = data
        ioctl(self.fd, I2C_SMBUS, msg)

    def i2c_rdwr(self, *i2c_msgs):
        """
        Combine a series of i2c read and write operations in a single
        transaction (with repeated start bits but no stop bits in between).

        This method takes i2c_msg instances as input, which must be created
        first with :py:meth:`i2c_msg.read` or :py:meth:`i2c_msg.write`.

        :param i2c_msgs: One or more i2c_msg class instances.
        :type i2c_msgs: i2c_msg
        :rtype: None
        """
        ioctl_data = i2c_rdwr_ioctl_data.create(*i2c_msgs)
        ioctl(self.fd, I2C_RDWR, ioctl_data)



if __name__ == "__main__":
    sb = SMBus(0)
    print("hello smbus")
    timestamp = time.time()
    print(" time1 %f" % timestamp)
    val , ind  = sb.read_byte_data(0xd, 0x13, True)
    timestamp = time.time()
    print(" time1 %f" % timestamp)
    print("%s %x" %(val, ind))
    
