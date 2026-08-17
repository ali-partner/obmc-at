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
SUMMARY = "PLAT HAL."
DESCRIPTION = "PLAT HAL func."
SECTION = "base"
PR = "r1"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://COPYING;md5=1ebbd3e34237af26da5dc08a4e440464"

SRC_URI = " \
    file://COPYING \
    file://__init__.py \
    file://baseutil.py \
    file://baseutil_org.py \
    file://osutil.py \
    file://osutil_org.py \
    file://devicebase.py \
    file://devicebase_org.py \
    file://interface.py \
    file://interface_org.py \
    file://chassisbase.py \
    file://chassisbase_org.py \
    file://sensor.py \
    file://sensor_org.py \
    file://bios.py \
    file://bios_org.py \
    file://bmc.py \
    file://bmc_org.py \
    file://cpu.py \
    file://cpu_org.py \
    file://cpld.py \
    file://cpld_org.py \
    file://firmware.py \
    file://firmware_org.py \
    file://rotor.py \
    file://rotor_org.py \
    file://fan.py \
    file://fan_org.py \
    file://psu.py \
    file://psu_org.py \
    file://smbus.py \
"
S = "${UNPACKDIR}"
DEPENDS = "python3"
inherit python3-dir

do_install () {
    mkdir -p ${D}/${PYTHON_SITEPACKAGES_DIR}/plat_hal

    install -m 644 __init__.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 baseutil.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 baseutil_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 osutil.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 osutil_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 devicebase.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 devicebase_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 interface.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 interface_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 chassisbase.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 chassisbase_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 sensor.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 sensor_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 bios.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 bios_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 bmc.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 bmc_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 cpu.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 cpu_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 cpld.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 cpld_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 firmware.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 firmware_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 rotor.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 rotor_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 fan.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 fan_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 psu.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 psu_org.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
    install -m 644 smbus.py ${D}${PYTHON_SITEPACKAGES_DIR}/plat_hal/
}

FILES:${PN} = "${PYTHON_SITEPACKAGES_DIR}"
