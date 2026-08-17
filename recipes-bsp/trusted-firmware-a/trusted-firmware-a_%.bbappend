FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://platform_def.h"

do_compile:prepend() {
    cp ${UNPACKDIR}/platform_def.h ${S}/plat/aspeed/ast2700/include/platform_def.h
}