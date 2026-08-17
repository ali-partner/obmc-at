# Copyright 2021 XLT. All Rights Reserved.

SUMMARY = "mac temp monitor"
SECTION = "base"
PR = "r1"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://COPYING;md5=eb723b61539feef013de476e68b5c50a"


TARGET_NAME = "mac_temp_monitord"

LDFLAGS += ""
INSANE_SKIP:${PN} = "ldflags"

SRC_URI += "file://mac_temp_monitor.c \
            file://Makefile \
            file://mac_temp_monitor.service \
            file://COPYING \
           "


S = "${UNPACKDIR}"
inherit systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "mac_temp_monitor.service"

do_compile() {
    make -f Makefile
}

do_install() {
  install -m 0755 -d ${D}${bindir}
  install -m 0755 ${TARGET_NAME} ${D}${bindir}
  install -d ${D}${systemd_unitdir}/system
  install -m 644 ${S}/mac_temp_monitor.service ${D}${systemd_unitdir}/system
}


FILES:${PN} += "/usr/local ${sysconfdir} ${systemd_unitdir}"




