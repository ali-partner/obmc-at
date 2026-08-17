FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SECTION = "base"
PR = "r1"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=eb723b61539feef013de476e68b5c50a"

DEPENDS:append = " update-rc.d-native"

SRC_URI = "file://cpu-peci-space.c \
           file://cpu-peci-space.h \
           file://Rules.mk \
           file://Makefile \
           file://COPYING"

S = "${UNPACKDIR}"
inherit systemd

do_install:append() {
    localbindir="/usr/local/bin"
    install -d ${D}${localbindir}/
    install -m 755 ${UNPACKDIR}//build/cpu-peci-space ${D}${localbindir}/cpu-peci-space

}

FILES:${PN} += "/usr/local"
RDEPENDS:${PN} = "bash"
