# Copyright 2020-present Facebook. All Rights Reserved.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " \
    file://setup-ipmbd.sh \
    file://run-ipmbd_13.sh \
    file://ipmbd.service \
    "
#DEPENDS:append = " plat-utils "
CFLAGS:prepend = " -DTIMEOUT_IPMB=3 "
S = "${UNPACKDIR}"
inherit systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "ipmbd.service"

do_install:append() {
  #install -d ${D}${sysconfdir}/init.d
  #install -d ${D}${sysconfdir}/rcS.d
  #install -d ${D}${sysconfdir}/sv
  #install -d ${D}${sysconfdir}/sv/ipmbd_13

  #install -m 755 ${S}/setup-ipmbd.sh ${D}${sysconfdir}/init.d/setup-ipmbd.sh
  #install -m 755 ${S}/run-ipmbd_13.sh ${D}${sysconfdir}/sv/ipmbd_13/run
  #update-rc.d -r ${D} setup-ipmbd.sh start 65 5 .
  install -d ${D}${systemd_unitdir}/system
  localbindir="${D}/usr/local/bin"
  install -d ${localbindir}
  install -m 644 ${S}/ipmbd.service  ${D}${systemd_unitdir}/system
  install -m 755 ${S}/setup-ipmbd.sh  ${localbindir}/setup-ipmbd.sh
}

FILES:${PN} += "/usr/local ${sysconfdir} ${systemd_unitdir}"