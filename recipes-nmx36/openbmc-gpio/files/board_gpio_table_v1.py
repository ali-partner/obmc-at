# Copyright 2019-present Facebook. All rights reserved.
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

from openbmc_gpio_table import BoardGPIO


# The following table is generated using:
# python openbmc_gpio_parser.py data/wedge400-bmc-gpio-evta.csv
# DO NOT MODIFY THE TABLE!!!
# Manual modification will be overridden!!!

board_gpio_table_v1 = [
    #BoardGPIO('GPIOA1', 'BMC_EMMC_RESET', "high"),
    #BoardGPIO('GPIOA0', 'MDC3'),
    #BoardGPIO('GPIOA1', 'MDIO3'),
    # BoardGPIO('GPIOF4', 'BMC_NMI_N'),
    BoardGPIO('GPIOAA4', 'BMC_I2C_RESET_OUT', "high"),
    BoardGPIO('GPIOF0', 'INT_IN_FROM_CPLD'),
    # BoardGPIO('GPIOB7', 'BMC_SMI_N'),
    BoardGPIO('GPIOC7', 'BMC_MGMT_PHY_RST', "high"),
    BoardGPIO('GPIOB4', 'FM_CPU_ERR0_LVT3_N'),
    BoardGPIO('GPIOB6', 'FM_CPU_ERR1_LVT3_N'),
    BoardGPIO('GPIOC0', 'FM_CPU_ERR2_LVT3_N'),
    BoardGPIO('GPIOC4', 'FM_CPU_MSMI_CATERR_LVT3_N'),
    BoardGPIO('GPIOB5', 'FM_PCH_BMC_THERMTRIP_R_N'),
    BoardGPIO('GPIOB7', 'FM_NMI_EVENT_N'),
    BoardGPIO('GPIOAA3', 'FM_SMI_ACTIVE_N'),
    BoardGPIO('GPIOAA0', 'CPU_RST_OUT', "high"),
    #BoardGPIO('GPIOZ4', 'SPI1CS0'),
    #BoardGPIO('GPIOZ5', 'SPI1CLK'),
    #BoardGPIO('GPIOZ6', 'SPI1MOSI'),
    #BoardGPIO('GPIOZ7', 'SPI1MISO'),
    #BoardGPIO('GPIOJ0', 'SGPMCK', "low"),
    BoardGPIO('GPIOG6', 'CPU_PWRBTN', "high"),
    #BoardGPIO('GPIOP1', 'FLASH_SCK'),
    #BoardGPIO('GPIOP2', 'FLASH_MISO'),
    #BoardGPIO('GPIOP3', 'FLASH_MOSI'),
    BoardGPIO('GPIOH0', 'Online_JTAG_SEL2', "low"),
    BoardGPIO('GPIOH1', 'Online_JTAG_SEL3', "low"),
    BoardGPIO('GPIOQ3', 'GPIO_JTAG_TCK', "low"),
    BoardGPIO('GPIOQ5', 'GPIO_JTAG_TDI', "low"),
    BoardGPIO('GPIOQ4', 'GPIO_JTAG_TMS', "low"),
    BoardGPIO('GPIOQ6', 'GPIO_JTAG_TDO'),
    BoardGPIO('GPIOG7', 'Online_JTAG_SEL1', "low"),
    BoardGPIO('GPIOF3', 'BMC_SPI_UPDATE_CTRL', "low"),
    BoardGPIO('GPIOAA6', 'BMC_WDO'),
    BoardGPIO('GPIOAA7', 'BMCINT_OUT'),
    #BoardGPIO('GPIOQ7', 'FPGA_MAC_SPI_CS'),
    BoardGPIO('GPIOF2', 'BIOS_FLASH_SEL', "high"),
    BoardGPIO('GPIOC1', 'BMC_EEPROM_WP', "low"),
    # BoardGPIO('GPIOP1', 'GPIO_SPI_SCK', 'high'),
    # BoardGPIO('GPIOP2', 'GPIO_SPI_MOSI', 'high'),
    # BoardGPIO('GPIOP3', 'GPIO_SPI_MISO'),
    # BoardGPIO('GPIOP6', 'GPIO_SPI_CS1', 'high'),
    # BoardGPIO('GPIOS2', 'BMC_PE_WAKEN'),
    #BoardGPIO('GPIOR2', 'SPI2CS0'),
    #BoardGPIO('GPIOR3', 'SPI2CLK'),
    #BoardGPIO('GPIOR4', 'SPI2MOSI'),
    #BoardGPIO('GPIOR5', 'SPI2MISO'),
    #BoardGPIO('GPIOR6', 'MDC1'),
    #BoardGPIO('GPIOR7', 'MDIO1'),
    # BoardGPIO('GPIOS3', 'BMC_RSTIND_N', "high"),
    #BoardGPIO('GPIOZ4', 'GPIOZ4'),
    #BoardGPIO('GPIOZ5', 'GPIOZ5'),
    #BoardGPIO('GPIOZ6', 'GPIOZ6', "high"),
    # BoardGPIO('GPIOZ7', 'GPIOZ7'),
]