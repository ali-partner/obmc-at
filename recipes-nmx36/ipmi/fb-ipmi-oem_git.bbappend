FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://appcommands.cpp \
           "

do_compile:prepend() {
    cp ${UNPACKDIR}/appcommands.cpp ${S}/src/appcommands.cpp
}