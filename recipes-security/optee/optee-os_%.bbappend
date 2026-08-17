FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://platform_config.h"

do_compile:prepend() {
    cp ${UNPACKDIR}/platform_config.h ${S}/core/arch/arm/plat-aspeed/platform_config.h
}