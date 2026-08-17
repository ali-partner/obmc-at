FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append = " file://yosemite5a7.cfg \
                   file://ast2700-evb.dts \
                   file://otp_ast2700.c \
                   file://otp_info_ast2700.h"


do_compile:prepend () {
    cp -rf ${UNPACKDIR}/ast2700-evb.dts ${S}/arch/arm/dts/ast2700-evb.dts
    cp -rf ${UNPACKDIR}/otp_ast2700.c ${S}/cmd/aspeed/otp_ast2700.c
    cp -rf ${UNPACKDIR}/otp_info_ast2700.h ${S}/cmd/aspeed/otp_info_ast2700.h
}