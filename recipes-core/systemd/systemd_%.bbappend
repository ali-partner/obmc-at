FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:fb-compute = " \
    file://serial-getty@.conf \
"

do_install:append:fb-compute() {
    install -m 644 -D \
        ${UNPACKDIR}/serial-getty@.conf \
        ${D}${systemd_system_unitdir}/serial-getty@.service.d/serial-getty@.conf
}