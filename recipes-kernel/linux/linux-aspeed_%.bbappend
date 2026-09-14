FILESEXTRAPATHS:prepend := "${THISDIR}/linux-aspeed:"

#SRC_URI:append = " \
#    file://1000-Arm64-aspeed-dts-add-yosemite5-dts.patch \
#    file://defconfig \
#    file://yosemite5a7.cfg \
#"

SRC_URI:append = " \
    file://defconfig \
    file://yosemite5a7.cfg \
    file://dts/ast2700-evb.dts \
    file://dts/aspeed-g7.dtsi \
    file://dts/aspeed-g7-pinctrl.dtsi \
    file://dts/ast2700-reserved-mem.dtsi \
    file://dts/aspeed-evb-flash0-layout-128.dtsi \
    file://dts/aspeed-evb-flash1-layout-128.dtsi \
    file://dts/aspeed-e2m-ic.h \
    file://patches/0001-add-hwmon-driver.patch \
    file://patches/0002-add-peci-legacy.patch \
    file://drivers/i2c_dev_sysfs.h \
    file://drivers/i2c_dev_sysfs.c \
    file://drivers/basecpld.c \
    file://drivers/ocmcpld.c \
    file://drivers/switchfpga.c \
    file://drivers/portcpld.c \
    file://drivers/misccpld.c \
    file://drivers/fancpld.c \
    file://drivers/ledcpld.c \
    file://drivers/psu_driver.c \
    file://drivers/tps544b25.c \
    file://drivers/ina3221.c \
    file://drivers/mp2985.c \
    file://drivers/mp2869.c \
    file://drivers/ucd90000.c \
    file://drivers/xdpe12284.c \
    file://drivers/asictemp_driver.c \
    file://drivers/faraday/ftgmac100.c \
    file://drivers/faraday/ftgmac100.h \
    file://drivers/ipmi/bt-bmc.c \
    file://drivers/ipmi/ipmb_dev_int.c \
    file://drivers/ipmi/ipmi_ipmb.c \
    file://drivers/ipmi/ipmi_msghandler.c \
    file://drivers/ipmi/ipmi_si_intf.c \
    file://drivers/ipmi/ipmi_ssif.c \
    file://drivers/ipmi/kcs_bmc_aspeed.c \
    file://drivers/ipmi/ssif_bmc.c \
    file://drivers/watchdog/aspeed_wdt.c \
    file://drivers/rtc/rtc-aspeed.c \
    file://drivers/pinctrl/pinctrl-aspeed-g7-soc0.c \
    file://drivers/pinctrl/pinctrl-aspeed-g7-soc1.c \
    file://drivers/pinctrl/pinctrl-aspeed.c \
    file://drivers/pinctrl/pinctrl-aspeed.h \
    file://drivers/pinctrl/pinmux-aspeed.c \
    file://drivers/pinctrl/pinmux-aspeed.h \
    file://drivers/peci/peci-ioctl.h \
    file://drivers/peci/peci-legacy.h \
    file://drivers/peci-legacy \
    file://drivers/usb/gadget/core.c \
    file://drivers/usb/gadget/dev.c \
    file://drivers/usb/gadget/epn.c \
    file://drivers/usb/gadget/hub.c \
    file://drivers/usb/gadget/vhub.h \
    file://drivers/usb/host/ehci-brcm.c \
    file://drivers/usb/host/ehci-platform.c \
    file://drivers/usb/host/uhci-platform.c \
    file://drivers/usb/host/uhci-hcd.c \
    file://drivers/usb/host/uhci-hcd.h \
    file://drivers/usb/host/uhci-q.c \
    file://drivers/usb/host/ohci-platform.c \
    file://drivers/usb/host/xhci-ring.c \
    file://drivers/usb/host/xhci-sideband.c \
    file://drivers/usb/host/xhci-tegra.c \
    file://drivers/usb/host/xhci.c \
    file://drivers/spi/spi-aspeed-smc.c \
    file://drivers/spi/spi-gpio.c \
    file://drivers/soc/aspeed-bmc-dev.c \
    file://drivers/soc/aspeed-pcie-mmbi.c \
    file://drivers/soc/aspeed-pcie-mmbi.h \
    file://drivers/soc/aspeed-xdma.c \
    file://drivers/soc/aspeed-usb-hp.c \
    file://drivers/soc/Kconfig \
    file://drivers/soc/Makefile \
    file://drivers/phy/aspeed/aspeed-usb-phy3.c \
    file://drivers/phy/aspeed/phy-aspeed-pcie.c \
    file://drivers/phy/aspeed/phy-aspeed-sgmii.c \
    file://drivers/phy/aspeed/Kconfig \
    file://drivers/phy/aspeed/Makefile \
    file://drivers/phy/Kconfig \
    file://drivers/phy/Makefile \
    file://drivers/clk/clk-ast2700.c \
    file://drivers/reset/reset-aspeed.c \
    file://drivers/mmc/sdhci-of-aspeed.c \
    file://drivers/i2c/i2c-mux-pca954x.c \
    file://drivers/spi-nor/core.c \
    file://drivers/spi-nor/core.h \
    file://drivers/spi-nor/debugfs.c \
    file://drivers/spi-nor/gigadevice.c \
    file://drivers/spi-nor/macronix.c \
    file://drivers/spi-nor/sfdp.c \
    file://drivers/spi-nor/sfdp.h \
    file://drivers/spi-nor/sst.c \
    file://drivers/spi-nor/swp.c \
    file://drivers/spi-nor/winbond.c \
    file://drivers/spi-nor/spi-nor.h \
    file://drivers/adc/aspeed_adc.c \
"

do_patch:append () {
    install -D ${UNPACKDIR}/drivers/soc/Kconfig ${STAGING_KERNEL_DIR}/drivers/soc/aspeed/Kconfig
    install -D ${UNPACKDIR}/drivers/phy/Kconfig ${STAGING_KERNEL_DIR}/drivers/phy/Kconfig
    install -D ${UNPACKDIR}/drivers/phy/aspeed/Kconfig ${STAGING_KERNEL_DIR}/drivers/phy/aspeed/Kconfig
}

do_kernel_configme:prepend () {
    cp -rf ${UNPACKDIR}/drivers/peci/peci-ioctl.h ${STAGING_KERNEL_DIR}/include/uapi/linux/peci-ioctl.h
    cp -rf ${UNPACKDIR}/drivers/peci/peci-legacy.h  ${STAGING_KERNEL_DIR}/include/linux/peci-legacy.h
    cp -rf ${UNPACKDIR}/drivers/peci-legacy ${STAGING_KERNEL_DIR}/drivers/peci-legacy
}

do_compile:prepend () {
    cp -rf ${UNPACKDIR}/dts/ast2700-evb.dts ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/aspeed/ast2700-evb.dts
    cp -rf ${UNPACKDIR}/dts/aspeed-g7.dtsi ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/aspeed/aspeed-g7.dtsi
    cp -rf ${UNPACKDIR}/dts/aspeed-g7-pinctrl.dtsi ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/aspeed/aspeed-g7-pinctrl.dtsi
    cp -rf ${UNPACKDIR}/dts/ast2700-reserved-mem.dtsi ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/aspeed/ast2700-reserved-mem.dtsi
    cp -rf ${UNPACKDIR}/dts/aspeed-evb-flash0-layout-128.dtsi ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/aspeed/aspeed-evb-flash0-layout-128.dtsi
    cp -rf ${UNPACKDIR}/dts/aspeed-evb-flash1-layout-128.dtsi ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/aspeed/aspeed-evb-flash1-layout-128.dtsi
    cp -rf ${UNPACKDIR}/dts/aspeed-e2m-ic.h ${STAGING_KERNEL_DIR}/include/dt-bindings/interrupt-controller/aspeed-e2m-ic.h
    cp -rf ${UNPACKDIR}/drivers/i2c_dev_sysfs.h ${STAGING_KERNEL_DIR}/drivers/hwmon/i2c_dev_sysfs.h
    cp -rf ${UNPACKDIR}/drivers/i2c_dev_sysfs.c ${STAGING_KERNEL_DIR}/drivers/hwmon/i2c_dev_sysfs.c
    cp -rf ${UNPACKDIR}/drivers/basecpld.c ${STAGING_KERNEL_DIR}/drivers/hwmon/basecpld.c
    cp -rf ${UNPACKDIR}/drivers/ocmcpld.c ${STAGING_KERNEL_DIR}/drivers/hwmon/ocmcpld.c
    cp -rf ${UNPACKDIR}/drivers/switchfpga.c ${STAGING_KERNEL_DIR}/drivers/hwmon/switchfpga.c
    cp -rf ${UNPACKDIR}/drivers/portcpld.c ${STAGING_KERNEL_DIR}/drivers/hwmon/portcpld.c
    cp -rf ${UNPACKDIR}/drivers/misccpld.c ${STAGING_KERNEL_DIR}/drivers/hwmon/misccpld.c
    cp -rf ${UNPACKDIR}/drivers/fancpld.c ${STAGING_KERNEL_DIR}/drivers/hwmon/fancpld.c
    cp -rf ${UNPACKDIR}/drivers/ledcpld.c ${STAGING_KERNEL_DIR}/drivers/hwmon/ledcpld.c
    cp -rf ${UNPACKDIR}/drivers/psu_driver.c ${STAGING_KERNEL_DIR}/drivers/hwmon/psu_driver.c
    cp -rf ${UNPACKDIR}/drivers/tps544b25.c ${STAGING_KERNEL_DIR}/drivers/hwmon/tps544b25.c
    cp -rf ${UNPACKDIR}/drivers/asictemp_driver.c ${STAGING_KERNEL_DIR}/drivers/hwmon/asictemp_driver.c
    cp -rf ${UNPACKDIR}/drivers/ina3221.c ${STAGING_KERNEL_DIR}/drivers/hwmon/pmbus/ina3221.c
    cp -rf ${UNPACKDIR}/drivers/mp2985.c ${STAGING_KERNEL_DIR}/drivers/hwmon/pmbus/mp2985.c
    cp -rf ${UNPACKDIR}/drivers/mp2869.c ${STAGING_KERNEL_DIR}/drivers/hwmon/pmbus/mp2869.c
    cp -rf ${UNPACKDIR}/drivers/ucd90000.c ${STAGING_KERNEL_DIR}/drivers/hwmon/pmbus/ucd90000.c
    cp -rf ${UNPACKDIR}/drivers/xdpe12284.c ${STAGING_KERNEL_DIR}/drivers/hwmon/pmbus/xdpe12284.c
#    cp -rf ${UNPACKDIR}/drivers/ipmb_dev_int.c ${STAGING_KERNEL_DIR}/drivers/char/ipmi/ipmb_dev_int.c
    cp -rf ${UNPACKDIR}/drivers/faraday/ftgmac100.c ${STAGING_KERNEL_DIR}/drivers/net/ethernet/faraday/ftgmac100.c
    cp -rf ${UNPACKDIR}/drivers/faraday/ftgmac100.h ${STAGING_KERNEL_DIR}/drivers/net/ethernet/faraday/ftgmac100.h
    cp -rf ${UNPACKDIR}/drivers/ipmi/bt-bmc.c ${STAGING_KERNEL_DIR}/drivers/char/ipmi/bt-bmc.c
    cp -rf ${UNPACKDIR}/drivers/ipmi/ipmb_dev_int.c ${STAGING_KERNEL_DIR}/drivers/char/ipmi/ipmb_dev_int.c
    cp -rf ${UNPACKDIR}/drivers/ipmi/ipmi_ipmb.c ${STAGING_KERNEL_DIR}/drivers/char/ipmi/ipmi_ipmb.c
    cp -rf ${UNPACKDIR}/drivers/ipmi/ipmi_msghandler.c ${STAGING_KERNEL_DIR}/drivers/char/ipmi/ipmi_msghandler.c
    cp -rf ${UNPACKDIR}/drivers/ipmi/ipmi_si_intf.c ${STAGING_KERNEL_DIR}/drivers/char/ipmi/ipmi_si_intf.c
    cp -rf ${UNPACKDIR}/drivers/ipmi/ipmi_ssif.c ${STAGING_KERNEL_DIR}/drivers/char/ipmi/ipmi_ssif.c
    cp -rf ${UNPACKDIR}/drivers/ipmi/kcs_bmc_aspeed.c ${STAGING_KERNEL_DIR}/drivers/char/ipmi/kcs_bmc_aspeed.c
    cp -rf ${UNPACKDIR}/drivers/ipmi/ssif_bmc.c ${STAGING_KERNEL_DIR}/drivers/char/ipmi/ssif_bmc.c
    cp -rf ${UNPACKDIR}/drivers/watchdog/aspeed_wdt.c ${STAGING_KERNEL_DIR}/drivers/watchdog/aspeed_wdt.c
    cp -rf ${UNPACKDIR}/drivers/rtc/rtc-aspeed.c ${STAGING_KERNEL_DIR}/drivers/rtc/rtc-aspeed.c
    cp -rf ${UNPACKDIR}/drivers/pinctrl/pinctrl-aspeed-g7-soc0.c ${STAGING_KERNEL_DIR}/drivers/pinctrl/aspeed/pinctrl-aspeed-g7-soc0.c
    cp -rf ${UNPACKDIR}/drivers/pinctrl/pinctrl-aspeed-g7-soc1.c ${STAGING_KERNEL_DIR}/drivers/pinctrl/aspeed/pinctrl-aspeed-g7-soc1.c
    cp -rf ${UNPACKDIR}/drivers/pinctrl/pinctrl-aspeed.c ${STAGING_KERNEL_DIR}/drivers/pinctrl/aspeed/pinctrl-aspeed.c
    cp -rf ${UNPACKDIR}/drivers/pinctrl/pinctrl-aspeed.h ${STAGING_KERNEL_DIR}/drivers/pinctrl/aspeed/pinctrl-aspeed.h
    cp -rf ${UNPACKDIR}/drivers/pinctrl/pinmux-aspeed.c ${STAGING_KERNEL_DIR}/drivers/pinctrl/aspeed/pinmux-aspeed.c
    cp -rf ${UNPACKDIR}/drivers/pinctrl/pinmux-aspeed.h ${STAGING_KERNEL_DIR}/drivers/pinctrl/aspeed/pinmux-aspeed.h
    cp -rf ${UNPACKDIR}/drivers/peci/peci-ioctl.h ${STAGING_KERNEL_DIR}/include/uapi/linux/peci-ioctl.h
    cp -rf ${UNPACKDIR}/drivers/peci/peci-legacy.h  ${STAGING_KERNEL_DIR}/include/linux/peci-legacy.h
    cp -rf ${UNPACKDIR}/drivers/peci-legacy ${STAGING_KERNEL_DIR}/drivers/peci-legacy
    cp -rf ${UNPACKDIR}/drivers/usb/gadget/core.c ${STAGING_KERNEL_DIR}/drivers/usb/gadget/udc/aspeed-vhub/core.c
    cp -rf ${UNPACKDIR}/drivers/usb/gadget/dev.c ${STAGING_KERNEL_DIR}/drivers/usb/gadget/udc/aspeed-vhub/dev.c
    cp -rf ${UNPACKDIR}/drivers/usb/gadget/epn.c ${STAGING_KERNEL_DIR}/drivers/usb/gadget/udc/aspeed-vhub/epn.c
    cp -rf ${UNPACKDIR}/drivers/usb/gadget/hub.c ${STAGING_KERNEL_DIR}/drivers/usb/gadget/udc/aspeed-vhub/hub.c
    cp -rf ${UNPACKDIR}/drivers/usb/gadget/vhub.h ${STAGING_KERNEL_DIR}/drivers/usb/gadget/udc/aspeed-vhub/vhub.h
    cp -rf ${UNPACKDIR}/drivers/usb/host/ehci-brcm.c ${STAGING_KERNEL_DIR}/drivers/usb/host/ehci-brcm.c
    cp -rf ${UNPACKDIR}/drivers/usb/host/ehci-platform.c ${STAGING_KERNEL_DIR}/drivers/usb/host/ehci-platform.c
    cp -rf ${UNPACKDIR}/drivers/usb/host/uhci-platform.c ${STAGING_KERNEL_DIR}/drivers/usb/host/uhci-platform.c
    cp -rf ${UNPACKDIR}/drivers/usb/host/uhci-hcd.c ${STAGING_KERNEL_DIR}/drivers/usb/host/uhci-hcd.c
    cp -rf ${UNPACKDIR}/drivers/usb/host/uhci-hcd.h ${STAGING_KERNEL_DIR}/drivers/usb/host/uhci-hcd.h
    cp -rf ${UNPACKDIR}/drivers/usb/host/uhci-q.c ${STAGING_KERNEL_DIR}/drivers/usb/host/uhci-q.c
    cp -rf ${UNPACKDIR}/drivers/usb/host/ohci-platform.c ${STAGING_KERNEL_DIR}/drivers/usb/host/ohci-platform.c
    cp -rf ${UNPACKDIR}/drivers/usb/host/xhci-ring.c ${STAGING_KERNEL_DIR}/drivers/usb/host/xhci-ring.c
    cp -rf ${UNPACKDIR}/drivers/usb/host/xhci-sideband.c ${STAGING_KERNEL_DIR}/drivers/usb/host/xhci-sideband.c
    cp -rf ${UNPACKDIR}/drivers/usb/host/xhci-tegra.c ${STAGING_KERNEL_DIR}/drivers/usb/host/xhci-tegra.c
    cp -rf ${UNPACKDIR}/drivers/usb/host/xhci.c ${STAGING_KERNEL_DIR}/drivers/usb/host/xhci.c
    cp -rf ${UNPACKDIR}/drivers/spi/spi-aspeed-smc.c ${STAGING_KERNEL_DIR}/drivers/spi/spi-aspeed-smc.c
    cp -rf ${UNPACKDIR}/drivers/spi/spi-gpio.c ${STAGING_KERNEL_DIR}/drivers/spi/spi-gpio.c
    cp -rf ${UNPACKDIR}/drivers/soc/aspeed-bmc-dev.c ${STAGING_KERNEL_DIR}/drivers/soc/aspeed/aspeed-bmc-dev.c
    cp -rf ${UNPACKDIR}/drivers/soc/aspeed-pcie-mmbi.c ${STAGING_KERNEL_DIR}/drivers/soc/aspeed/aspeed-pcie-mmbi.c
    cp -rf ${UNPACKDIR}/drivers/soc/aspeed-pcie-mmbi.h ${STAGING_KERNEL_DIR}/drivers/soc/aspeed/aspeed-pcie-mmbi.h
    cp -rf ${UNPACKDIR}/drivers/soc/aspeed-xdma.c ${STAGING_KERNEL_DIR}/drivers/soc/aspeed/aspeed-xdma.c
    cp -rf ${UNPACKDIR}/drivers/soc/aspeed-usb-hp.c ${STAGING_KERNEL_DIR}/drivers/soc/aspeed/aspeed-usb-hp.c
    cp -rf ${UNPACKDIR}/drivers/soc/Makefile ${STAGING_KERNEL_DIR}/drivers/soc/aspeed/Makefile
    cp -rf ${UNPACKDIR}/drivers/phy/Makefile ${STAGING_KERNEL_DIR}/drivers/phy/Makefile
    cp -rf ${UNPACKDIR}/drivers/phy/aspeed/aspeed-usb-phy3.c ${STAGING_KERNEL_DIR}/drivers/phy/aspeed/aspeed-usb-phy3.c
    cp -rf ${UNPACKDIR}/drivers/phy/aspeed/phy-aspeed-pcie.c ${STAGING_KERNEL_DIR}/drivers/phy/aspeed/phy-aspeed-pcie.c
    cp -rf ${UNPACKDIR}/drivers/phy/aspeed/phy-aspeed-sgmii.c ${STAGING_KERNEL_DIR}/drivers/phy/aspeed/phy-aspeed-sgmii.c
    cp -rf ${UNPACKDIR}/drivers/phy/aspeed/Makefile ${STAGING_KERNEL_DIR}/drivers/phy/aspeed/Makefile
    cp -rf ${UNPACKDIR}/drivers/clk/clk-ast2700.c ${STAGING_KERNEL_DIR}/drivers/clk/clk-ast2700.c
    cp -rf ${UNPACKDIR}/drivers/reset/reset-aspeed.c ${STAGING_KERNEL_DIR}/drivers/reset/reset-aspeed.c
    cp -rf ${UNPACKDIR}/drivers/mmc/sdhci-of-aspeed.c ${STAGING_KERNEL_DIR}/drivers/mmc/host/sdhci-of-aspeed.c
    cp -rf ${UNPACKDIR}/drivers/i2c/i2c-mux-pca954x.c ${STAGING_KERNEL_DIR}/drivers/i2c/muxes/i2c-mux-pca954x.c
    cp -rf ${UNPACKDIR}/drivers/spi-nor/core.c ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/core.c
    cp -rf ${UNPACKDIR}/drivers/spi-nor/core.h ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/core.h
    cp -rf ${UNPACKDIR}/drivers/spi-nor/debugfs.c ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/debugfs.c
    cp -rf ${UNPACKDIR}/drivers/spi-nor/gigadevice.c ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/gigadevice.c
    cp -rf ${UNPACKDIR}/drivers/spi-nor/macronix.c ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/macronix.c
    cp -rf ${UNPACKDIR}/drivers/spi-nor/sfdp.c ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/sfdp.c
    cp -rf ${UNPACKDIR}/drivers/spi-nor/sfdp.h ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/sfdp.h
    cp -rf ${UNPACKDIR}/drivers/spi-nor/sst.c ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/sst.c
    cp -rf ${UNPACKDIR}/drivers/spi-nor/swp.c ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/swp.c
    cp -rf ${UNPACKDIR}/drivers/spi-nor/winbond.c ${STAGING_KERNEL_DIR}/drivers/mtd/spi-nor/winbond.c
    cp -rf ${UNPACKDIR}/drivers/spi-nor/spi-nor.h ${STAGING_KERNEL_DIR}/include/linux/mtd/spi-nor.h
    cp -rf ${UNPACKDIR}/drivers/adc/aspeed_adc.c ${STAGING_KERNEL_DIR}/drivers/iio/adc/aspeed_adc.c
}