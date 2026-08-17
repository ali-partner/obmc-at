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

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

S = "${UNPACKDIR}"
LOCAL_URI += " \
    file://mTerm1/run \
    file://mTerm2/run \
    file://mTerm_server.service \
    file://mTerm_server.c \
    file://mTerm_client.c \
    file://mTerm_helper.c \
    file://mTerm_helper.h \
    file://tty_helper.c \
    file://tty_helper.h \
    file://baudrate.conf \
    "

MTERM_SERVICES = "mTerm1 \
                  mTerm2 \
                 "

CFLAGS:prepend = "-D_GNU_SOURCE"

# Go with default names of mTerm for MTERM_SERVICES
# since we have just one console.

inherit systemd
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " mTerm_server.service"



etcdevdir = "/etc/device"
do_install:append() {
    install -d ${D}${systemd_unitdir}/system
    install -d ${D}${etcdevdir}
    localbindir="/usr/local/bin"
    install -d ${D}${localbindir}/
    install -m 644 ${UNPACKDIR}/mTerm_server.service ${D}${systemd_unitdir}/system
    install -m 644 ${UNPACKDIR}/baudrate.conf ${D}${etcdevdir}
    rm -f ${D}/usr/local/bin/sol.sh
}

RDEPENDS:${PN} = "bash"
FILES:${PN} += "${systemd_unitdir} /usr/local/bin"
