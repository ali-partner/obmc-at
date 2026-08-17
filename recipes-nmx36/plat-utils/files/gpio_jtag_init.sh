#!/bin/bash
# shellcheck source=/dev/null
source "/usr/local/bin/gpio_utils.sh"
gpio_line_export 885 BMC_GPIOO1  #I5
gpio_set_direction BMC_GPIOO1 out
#gpio_set_direction BMC_GPIOO1 out
#gpio_set_value BMC_GPIOO1 1
gpio_line_export 886 onlineJTAG_sel1  #I6
gpio_set_direction onlineJTAG_sel1 out
#gpio_set_direction onlineJTAG_sel1 out
#gpio_set_value onlineJTAG_sel1 0
gpio_line_export 884 GPIO_JTAG_TDO  #I4
gpio_line_export 881 GPIO_JTAG_TDI  #I1
gpio_set_direction GPIO_JTAG_TDI in
gpio_set_direction GPIO_JTAG_TDI out
gpio_line_export 883 GPIO_JTAG_TMS  #I3
gpio_set_direction GPIO_JTAG_TMS in
gpio_set_direction GPIO_JTAG_TMS out
gpio_line_export 882 GPIO_JTAG_TCK  #I2
gpio_set_direction GPIO_JTAG_TCK in
gpio_set_direction GPIO_JTAG_TCK out

gpio_line_export 937 GPIO_SPI_SCK  #P1
gpio_set_direction GPIO_SPI_SCK out

gpio_line_export 938 GPIO_SPI_MISO #P2
gpio_set_direction GPIO_SPI_MISO in


gpio_line_export 939 GPIO_SPI_MOSI  #P3
gpio_set_direction GPIO_SPI_MOSI out

gpio_line_export 951 GPIO_SPI_CS1  #P4
gpio_set_direction GPIO_SPI_CS1 out
devmem 0x1e6e251c 32 0x00000080
devmem 0x1e6e24b4 32 0x000000ff
