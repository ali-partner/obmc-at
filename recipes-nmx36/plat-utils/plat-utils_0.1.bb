# Copyright 2020-present Facebook. All Rights Reserved.
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
SUMMARY = "Utilities"
DESCRIPTION = "Various utilities"
SECTION = "base"
PR = "r1"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://COPYING;md5=eb723b61539feef013de476e68b5c50a"

S = "${UNPACKDIR}"
LOCAL_URI = " \
    file://sol-util \
    file://COPYING \
    file://ast-functions \
    file://power-on.sh \
    file://run_power_on.sh \
    file://check_pal_sku.sh \
    file://setup-platform.sh \
    file://sync_date.sh \
    file://check_bmc_ready.sh \
    file://check_2nd_source.sh \
    file://ast-mdio.py \
    file://power_on_config_setup.sh \
    file://i2c_topology_create.sh \
    file://i2c-utils.sh \
    file://board-utils.sh \
    file://openbmc-utils.sh \
    file://boot_area.sh \
    file://boot_util.sh \
    file://fwm_util.sh \
    file://cmd_list.sh \
    file://power.sh \
    file://power_util.sh \
    file://show_cpu_temp.sh \
    file://gpio_jtag_init.sh \
    file://gpio_utils.sh \
    file://cpld_update.sh \
    file://fpga_flash.sh \
    "

pkgdir = "utils"


# the tools for BMC will be installed in the image
binfiles = " sol-util power-on.sh check_pal_sku.sh sync_date.sh check_bmc_ready.sh check_2nd_source.sh ast-mdio.py i2c_topology_create.sh \
power_on_config_setup.sh power_util.sh power.sh cpld_update.sh gpio_utils.sh gpio_jtag_init.sh fpga_flash.sh"

DEPENDS:append = "update-rc.d-native"
RDEPENDS:${PN} += "bash python3 gpiocli "

do_install() {
  # install the package dir
  dst="${D}/usr/local/fbpackages/${pkgdir}"
  install -d $dst

  # install ast-functions
  install -m 644 ast-functions ${dst}/ast-functions

  # create linkages to those binaries
  localbindir="${D}/usr/local/bin"
  install -d ${localbindir}
  for f in ${binfiles}; do
      install -m 755 $f ${dst}/${f}
      ln -s ../fbpackages/${pkgdir}/${f} ${localbindir}/${f}
  done
  
  # init
  install -d ${D}${sysconfdir}/init.d
  install -d ${D}${sysconfdir}/rcS.d
  install -m 755 run_power_on.sh ${D}${sysconfdir}/init.d/run_power_on.sh
  update-rc.d -r ${D} run_power_on.sh start 99 5 .
  install -m 755 setup-platform.sh ${D}${sysconfdir}/init.d/setup-platform.sh
  update-rc.d -r ${D} setup-platform.sh start 92 5 .
  
  # install check_bmc_ready.sh
  install -m 755 check_bmc_ready.sh ${D}${sysconfdir}/init.d/check_bmc_ready.sh
  update-rc.d -r ${D} check_bmc_ready.sh start 100 5 .
}

FILES:${PN} += "/usr/local ${sysconfdir}"
