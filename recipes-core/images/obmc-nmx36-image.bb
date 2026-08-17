require common/images/fb-openbmc-image.inc

IMAGE_INSTALL:append = " apml"
#IMAGE_INSTALL:append = " addc"
IMAGE_INSTALL:append = " dimm-util"
IMAGE_INSTALL:append = " stress-ng"

IMAGE_CLASSES:append = " image_types_phosphor_aspeed_g7"


IMAGE_INSTALL += " \
  packagegroup-openbmc-base \
  packagegroup-openbmc-net \
  packagegroup-openbmc-python3 \
  packagegroup-openbmc-rest3 \
  ipmitool \
  mterm \
  fruid \
  name-util \
  log-util-v2 \
  openbmc-utils \
  fan-util \
  fscd \
  guid-util \
  sensor-util \
  sensor-mon \
  fpc-util \
  i2craw \
  cfg-util \
  threshold-util \
  libncsi \
  ncsid-v2 \
  ncsi-util \
  ipmb-util \
  power-util \
  usbutils \
  usb-console \
  crashdump \
  bios-util \
  ipmi-util \
  bic-util \
  otp \
  mctp-util \
  modprobe \
  tpm-factory-upd \
  cpldupdate \
  libcpldupdate-dll-gpio \
  libcpldupdate-dll-echo \
  bitbang \
  e2fsprogs \
  fpgaupdate-spi \
  startup \
  peci-util \
  dhcpcd \
  libbic \
  openbmc-gpio \
  mac-temp-monitor \
  memtester \
  iperf \
  fio \
  hal-at \
  plat-hal \
  product-hal \
  hal-unittest \
  fanctrl \
  restful \
  devmon \
  stressapptest \
  "