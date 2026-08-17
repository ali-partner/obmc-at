# Copyright 2018-present Facebook. All Rights Reserved.
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
SUMMARY = "HAL AT."
DESCRIPTION = "HAL func."
SECTION = "base"
PR = "r1"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://COPYING;md5=1ebbd3e34237af26da5dc08a4e440464"

SRC_URI = " \
    file://COPYING \
    file://hal_fan.py \
    file://hal_bmc.py \
    file://hal_psu.py \
    file://hal_misc.py \
    file://hal_sensor.py \
    file://hal_dcdc.py \
    file://hal_temp.py \
    file://hal_cpu.py \
    file://hal_firmware.py \
    file://AS42-64S-AT_sensors_config.json \
"
S = "${UNPACKDIR}"
DEPENDS = "python3"
inherit python3-dir

do_install () {
  mkdir -p ${D}/${PYTHON_SITEPACKAGES_DIR}/hal

  install -m 644 hal_fan.py ${D}${PYTHON_SITEPACKAGES_DIR}/hal/
  install -m 644 hal_bmc.py ${D}${PYTHON_SITEPACKAGES_DIR}/hal/
  install -m 644 hal_psu.py ${D}${PYTHON_SITEPACKAGES_DIR}/hal/
  install -m 644 hal_misc.py ${D}${PYTHON_SITEPACKAGES_DIR}/hal/
  install -m 644 hal_sensor.py ${D}${PYTHON_SITEPACKAGES_DIR}/hal/
  install -m 644 hal_dcdc.py ${D}${PYTHON_SITEPACKAGES_DIR}/hal/
  install -m 644 hal_temp.py ${D}${PYTHON_SITEPACKAGES_DIR}/hal/
  install -m 644 hal_cpu.py ${D}${PYTHON_SITEPACKAGES_DIR}/hal/
  install -m 644 hal_firmware.py ${D}${PYTHON_SITEPACKAGES_DIR}/hal/
  mkdir -p ${D}/etc/openbmc/devices/AS42-64S-AT/
  install -m 644 AS42-64S-AT_sensors_config.json ${D}/etc/openbmc/devices/AS42-64S-AT/sensors_config.json
}

FILES:${PN} = "${PYTHON_SITEPACKAGES_DIR} /etc"