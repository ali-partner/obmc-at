DESCRIPTION = "Iperf is a tool to measure maximum TCP bandwidth, allowing the tuning of various parameters and UDP characteristics"
HOMEPAGE = "http://dast.nlanr.net/Projects/Iperf/"
SECTION = "console/network"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://COPYING;md5=e136a7b2560d80bcbf0d9b3e1356ecff"

SRC_URI = " ${SOURCEFORGE_MIRROR}/iperf2/${BP}.tar.gz \
          "

SRC_URI[md5sum] = "34bb6ac1abeb801bf3f729794dc5ac36"
SRC_URI[sha256sum] = "16810a9575e4c6dd65e4a18ab5df3cdac6730b3c832cf080a8990f132f68364a"

S = "${UNPACKDIR}/${BP}"

inherit autotools pkgconfig

EXTRA_OECONF = "--exec-prefix=${STAGING_DIR_HOST}${layout_exec_prefix}"

