# Copyright 2020 ATC. All Rights Reserved.

SUMMARY = "Startup"
SECTION = "base"
PR = "r1"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://COPYING;md5=eb723b61539feef013de476e68b5c50a"





FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI += "file://init-platform.service \
            file://sensor-mon.service \
            file://temperature-screening.service \
            file://emmc-initfs.service \
            file://COPYING \
           "

S = "${UNPACKDIR}"
inherit systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "\
                         init-platform.service \
                         sensor-mon.service \
                         temperature-screening.service \
                         emmc-initfs.service \
                        "

do_install() {
  # init
  install -d ${D}${systemd_unitdir}/system
  install -m 644 ${UNPACKDIR}/init-platform.service ${D}${systemd_unitdir}/system
  install -m 644 ${UNPACKDIR}/sensor-mon.service ${D}${systemd_unitdir}/system
  install -m 644 ${UNPACKDIR}/temperature-screening.service ${D}${systemd_unitdir}/system
  install -m 644 ${UNPACKDIR}/emmc-initfs.service ${D}${systemd_unitdir}/system
}

FILES:${PN} += "/usr/local ${sysconfdir} ${systemd_unitdir}"