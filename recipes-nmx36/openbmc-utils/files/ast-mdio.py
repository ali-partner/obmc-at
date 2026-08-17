#!/usr/bin/env python
#
# Copyright 2014-present Facebook. All Rights Reserved.
#
# This program file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program in a file named COPYING; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA
#

import subprocess
import time
from argparse import ArgumentParser


IO_BASE = 0x14040000
PHYCR_REG_OFFSET = [0x00, 0x08, 0x10]
PHYDATA_REG_OFFSET = [0x04, 0x0c, 0x14]
PHYCR_READ_BIT = 0x1 << 27
PHYCR_WRITE_BIT = 0x1 << 26
phycr_reg = lambda mdio: PHYCR_REG_OFFSET[mdio - 1] + IO_BASE
phydata_reg = lambda mdio: PHYDATA_REG_OFFSET[mdio - 1] + IO_BASE


devmem_read_cmd = lambda reg: ["devmem", hex(reg)]
devmem_write_cmd = lambda reg, val: ["devmem", hex(reg), "32", hex(val)]


def devmem_read(reg):
    cmd = devmem_read_cmd(reg)
    #print('Cmd: {}'.format(cmd))
    out = subprocess.Popen(cmd, stdout=subprocess.PIPE).communicate()[0]
    return int(out, 0)


def devmem_write(reg, val):
    cmd = devmem_write_cmd(reg, val)
    #print('Cmd: {}'.format(cmd))
    subprocess.Popen(cmd, stdout=subprocess.PIPE).communicate()[0]


def wait_for_mdio_done(args):
    reg = phycr_reg(args.mdio)
    while devmem_read(reg) & (PHYCR_READ_BIT | PHYCR_WRITE_BIT):
        time.sleep(0.010)  # 10ms


def read_mdio(args):
    reg = phycr_reg(args.mdio)
    #ctrl = devmem_read(reg)
    ctrl = 0x90000000
    ctrl |= (args.phy & 0x1F) << 21
    ctrl |= (args.register & 0x1F) << 16
    ctrl |= PHYCR_READ_BIT
    devmem_write(reg, ctrl)
    #wait_for_mdio_done(args)
    val = devmem_read(phydata_reg(args.mdio)) & 0xffff
    print(
        "Read from PHY ({}.{}): {}".format(hex(args.phy), hex(args.register), hex(val))
    )


def write_mdio(args):
    ctrl_reg = phycr_reg(args.mdio)
    #ctrl = devmem_read(ctrl_reg)
    ctrl = 0x90000000
    ctrl |= (args.phy & 0x1F) << 21
    ctrl |= (args.register & 0x1F) << 16
    ctrl |= PHYCR_WRITE_BIT
    ctrl |= args.value
    data_reg = phydata_reg(args.mdio)
    # write data first
    #devmem_write(data_reg, args.value)
    # then ctrl
    devmem_write(ctrl_reg, ctrl)
    #wait_for_mdio_done(args)
    print(
        "Write to PHY ({}.{}): {}".format(
            hex(args.phy), hex(args.register), hex(args.value)
        )
    )


def auto_int(x):
    return int(x, 0)


if __name__ == "__main__":
    ap = ArgumentParser()
    ap.add_argument("--mdio", "-m", type=int, default=2, help="The MDC/MDIO")
    ap.add_argument("--phy", "-p", type=auto_int, default=0x1F, help="The PHY address")

    subparsers = ap.add_subparsers()

    read_parser = subparsers.add_parser("read", help="read MDIO")
    read_parser.set_defaults(func=read_mdio)
    read_parser.add_argument(
        "register", type=auto_int, help="The register to read from"
    )

    write_parser = subparsers.add_parser("write", help="write MDIO")
    write_parser.set_defaults(func=write_mdio)
    write_parser.add_argument(
        "register", type=auto_int, help="The register to write to"
    )
    write_parser.add_argument("value", type=auto_int, help="The value to write to")

    args = ap.parse_args()

    if args.mdio != 2 and args.mdio != 1 and args.mdio != 3 and args.mdio != 4:
        print("MAC can only be either 1 or 2.")
        exit(-1)

    if args.phy > 0x1F:
        printf("PHY address must be smaller than 0x1f.")
        exit(-2)

    args.func(args)
