#!/bin/bash
# shellcheck source=/dev/null
source "/usr/local/bin/gpio_utils.sh"
# gpio_line_export 580 BMC_GPIOO1  #H0
# gpio_set_direction BMC_GPIOO1 out
# #gpio_set_direction BMC_GPIOO1 out
# #gpio_set_value BMC_GPIOO1 1
# gpio_line_export 579 onlineJTAG_sel1  #G7
# gpio_set_direction onlineJTAG_sel1 out
# #gpio_set_direction onlineJTAG_sel1 out
# #gpio_set_value onlineJTAG_sel1 0
# gpio_line_export 658 GPIO_JTAG_TDO  #Q6
# gpio_line_export 657 GPIO_JTAG_TDI  #Q5
# gpio_set_direction GPIO_JTAG_TDI in
# gpio_set_direction GPIO_JTAG_TDI out
# gpio_line_export 656 GPIO_JTAG_TMS  #Q4
# gpio_set_direction GPIO_JTAG_TMS in
# gpio_set_direction GPIO_JTAG_TMS out
# gpio_line_export 655 GPIO_JTAG_TCK  #Q3
# gpio_set_direction GPIO_JTAG_TCK in
# gpio_set_direction GPIO_JTAG_TCK out

gpio_line_export 645 GPIO_SPI_SCK  #P1
gpio_set_direction GPIO_SPI_SCK out

gpio_line_export 647 GPIO_SPI_MISO #P3
gpio_set_direction GPIO_SPI_MISO in


gpio_line_export 646 GPIO_SPI_MOSI  #P2
gpio_set_direction GPIO_SPI_MOSI out

gpio_line_export 650 GPIO_SPI_CS1  #P6
gpio_set_direction GPIO_SPI_CS1 out
# devmem 0x1e6e251c 32 0x00000080
# devmem 0x1e6e24b4 32 0x000000ff
