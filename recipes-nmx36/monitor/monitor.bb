# Copyright 2021 XLT. All Rights Reserved.

DESCRIPTION = "Thermal Plan - Montara Monitord Voltage"
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

#inherit obmc-phosphor-systemd
#inherit obmc-phosphor-dbus-service
inherit systemd

TARGET_NAME = "monitord"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
LDFLAGS += ""
INSANE_SKIP:${PN} = "ldflags"

#DEPENDS += "sdbusplus"
#DEPENDS += "sdeventplus"
#DEPENDS += "sdbusplus-native"
#DEPENDS += "phosphor-logging"
#DEPENDS += "phosphor-dbus-interfaces"
#DEPENDS += "phosphor-dbus-interfaces-native"
DEPENDS += "libcereal"
DEPENDS += "cli11"
DEPENDS += "nlohmann-json"
DEPENDS:append = " update-rc.d-native"
DEPENDS += "json-c"

SRC_URI += "file://monitor.cpp \
            file://monitor_common.cpp \
            file://monitor_common.hpp \
            file://monitor_others.cpp \
            file://monitor_others.hpp \
            file://Makefile \
            file://monitor.service \
           "

S = "${UNPACKDIR}"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "monitor.service"

EXTRA_OEMAKE = "CFLAGS='${CFLAGS} ${DEBUG_PREFIX_MAP}' CXXFLAGS='${CXXFLAGS} ${DEBUG_PREFIX_MAP}'"

do_compile() {
    oe_runmake -f Makefile
}

do_install() {
  install -d ${D}${systemd_unitdir}/system
  install -m 0644 ${UNPACKDIR}/monitor.service ${D}${systemd_unitdir}/system
  install -m 0755 -d ${D}${bindir}
  install -m 0755 ${TARGET_NAME} ${D}${bindir}
}

# Install package
FILES:${PN} = " ${bindir} ${systemd_unitdir}"
