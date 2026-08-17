/*
 * basecpld.c - The i2c driver for basecpld
 *
 * Copyright 2018-present Facebook. All Rights Reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

//#define DEBUG

#include <linux/errno.h>
#include <linux/module.h>
#include <linux/i2c.h>
#include <i2c_dev_sysfs.h>


#ifdef DEBUG

#define PP_DEBUG(fmt, ...) do {                   \
  printk(KERN_DEBUG "%s:%d " fmt "\n",            \
         __FUNCTION__, __LINE__, ##__VA_ARGS__);  \
} while (0)

#else /* !DEBUG */

#define PP_DEBUG(fmt, ...)

#endif
static const i2c_dev_attr_st basecpld_attr_table[] = {  
  {
    "cpld_major_ver",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0, 4, 4,
  },
  {
    "cpld_minor_ver",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0, 0, 4,
  },
  {
    "cpld_year",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    1, 0, 8,
  },
  {
    "cpld_month",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    2, 0, 8,
  },
  {
    "cpld_date",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    3, 0, 8,
  },
  {
    "fan_board_type",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    7, 2, 2,
  },
  {
    "cpld_test",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xf7, 0, 8,
  },
  {
    "cpu_reset_type",
    "cpu S3 state\n"
    "0x01: warm reset\n"
    "0x02: cold reset",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x10, 0, 2,
  },
  {
    "cpu_slp_s3_state",
    "cpu S3 state\n"
    "0: Not entered S3 state\n"
    "1: Entered S3 state",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x13, 1, 1,
  },
  {
    "cpu_slp_s45_state",
    "cpu S45 state\n"
    "0: Not entered S45 state\n"
    "1: Entered S45 state",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x13, 2, 1,
  },
  {
    "cpu_force_pwr_off",
    "cpu force power off status\n"
    "0: enable\n"
    "1: disable",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x14, 0, 1,
  },
  {
    "cpu_pwr_up_en",
    "cpu pwr up\n"
    "0: disable\n"
    "1: enable",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x15, 0, 1,
  },
  {
    "cpu_pwr_down_en",
    "cpu pwr down\n"
    "0: disable\n"
    "1: enable",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x15, 1, 1,
  },
  {
    "bios_flash_sel",
    "bios flash sel\n"
    "0: CPU boot\n"
    "1: update(contry by BMC/CPU write reg)",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x17, 0, 1,
  },
  {
    "bios_flash_update_ctl",
    "bios flash update ctl\n"
    "0x7: CPU update primary bios\n"
    "0xb: CPU update secondary bios\n"
    "0xd: BMC update primary bios\n"
    "0xe: BMC update secondary bios",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x18, 0, 4,
  },
  {
    "dual_bios_watchdog_en",
    "dual bios watchdog en\n"
    "0: disable\n"
    "1: enable",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x19, 0, 1,
  },
  {
    "bios_boot_sel",
    "bios boot sel\n"
    "0x7:  CPU select primary bios\n"
    "0xb: CPU select secondary bios\n"
    "0xd: BMC select primary bios\n"
    "0xe: BMC select secondary bios",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x1a, 0, 4,
  },
  {
    "bios_sel_status",
    "bios sel status\n"
    "0: primary\n"
    "1: secondary",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x1E, 0, 1,
  },
  {
    "bios_manual_switch",
    "bios manual switch\n"
    "0: primary\n"
    "1: secondary",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x1F, 0, 1,
  },
  {
    "bmc_reset_cnt",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x20, 0, 8,
  },
  {
    "bios_flash_update_ctl_wp",
    "bios flash update ctl write protect\n"
    "0x4e: enable bios flash update ctl write protect\n"
    "0x59: disable bios flash update ctl write protect\n",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x28, 0, 8,
  },
  {
    "cpu_reset",
    "cpu reset ctrl\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x30, 0, 1,
  },
  {
    "cpld_mac_reset",
    "mac reset ctrl\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x34, 2, 1,
  },

  {
    "psu4_output_ok",
    "psu4 output status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x40, 0, 1,
  },
  {
    "psu3_output_ok",
    "psu3 output status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x40, 1, 1,
  },
  {
    "psu2_output_ok",
    "psu2 output status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x40, 2, 1,
  },
  {
    "psu1_output_ok",
    "psu2 output status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x40, 3, 1,
  },
  {
    "psu4_vin_pg",
    "psu4 vin status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x41, 0, 1,
  },
  {
    "psu3_vin_pg",
    "psu3 vin status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x41, 1, 1,
  },
  {
    "psu2_vin_pg",
    "psu2 vin status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x41, 2, 1,
  },
  {
    "psu1_vin_pg",
    "psu1 vin status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x41, 3, 1,
  },
  {
    "psu4_present",
    "psu4 present\n"
    "0: normal\n"
    "1: abnormal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x42, 0, 1,
  },
  {
    "psu3_present",
    "psu3 present\n"
    "0: normal\n"
    "1: abnormal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x42, 1, 1,
  },
  {
    "psu2_present",
    "psu2 present\n"
    "0: normal\n"
    "1: abnormal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x42, 2, 1,
  },
  {
    "psu1_present",
    "psu1 present\n"
    "0: normal\n"
    "1: abnormal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x42, 3, 1,
  },
  {
    "psu_power_on",
    "psu power ctrl\n"
    "0x00: All PSU power on\n"
    "0x0f: All PSU power off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x43, 0, 4,
  },
  {
    "psu4_power_on",
    "psu4 power ctrl\n"
    "0: power on\n"
    "1: power off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x43, 0, 1,
  },
  {
    "psu3_power_on",
    "psu3 power ctrl\n"
    "0: power on\n"
    "1: power off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x43, 1, 1,
  },
  {
    "psu2_power_on",
    "psu2 power ctrl\n"
    "0: power on\n"
    "1: power off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x43, 2, 1,
  },
  {
    "psu1_power_on",
    "psu1 power ctrl\n"
    "0: power on\n"
    "1: power off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x43, 3, 1,
  },
  {
    "pwr4_output_ok_r",
    "pwr4 output interrupt\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x45, 0, 1,
  },
  {
    "pwr3_output_ok_r",
    "pwr3 output interrupt\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x45, 1, 1,
  },
  {
    "pwr2_output_ok_r",
    "pwr2 output interrupt\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x45, 2, 1,
  },
  {
    "pwr1_output_ok_r",
    "pwr1 output interrupt\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x45, 3, 1,
  },
  {
    "pwr4_vinpg_r",
    "pwr4 vin pg interrupt\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x45, 4, 1,
  },
  {
    "pwr3_vinpg_r",
    "pwr3 vin pg interrupt\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x45, 5, 1,
  },
  {
    "pwr2_vinpg_r",
    "pwr2 vin pg interrupt\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x45, 6, 1,
  },
  {
    "pwr1_vinpg_r",
    "pwr1 vin pg interrupt\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x45, 7, 1,
  },
  {
    "pwr4_output_ok_mask",
    "pwr4 output interrupt mask\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x47, 0, 1,
  },
  {
    "pwr3_output_ok_mask",
    "pwr3 output interrupt mask\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x47, 1, 1,
  },
  {
    "pwr2_output_ok_mask",
    "pwr2 output interrupt mask\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x47, 2, 1,
  },
  {
    "pwr1_output_ok_mask",
    "pwr1 output interrupt mask\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x47, 3, 1,
  },
  {
    "pwr4_vinpg_mask",
    "pwr4 vin pg interrupt mask\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x47, 4, 1,
  },
  {
    "pwr3_vinpg_mask",
    "pwr3 vin pg interrupt mask\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x47, 5, 1,
  },
  {
    "pwr2_vinpg_mask",
    "pwr2 vin pg interrupt mask\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x47, 6, 1,
  },
  {
    "pwr1_vinpg_mask",
    "pwr1 vin pg interrupt mask\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x47, 7, 1,
  },
  {
    "psu4_plug_his",
    "psu4 plug history status\n"
    "0: plugged\n"
    "1: unplugged",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x49, 0, 1,
  },
  {
    "psu3_plug_his",
    "psu3 plug history status\n"
    "0: plugged\n"
    "1: unplugged",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x49, 1, 1,
  },
  {
    "psu2_plug_his",
    "psu2 plug history status\n"
    "0: plugged\n"
    "1: unplugged",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x49, 2, 1,
  },
  {
    "psu1_plug_his",
    "psu1 plug history status\n"
    "0: plugged\n"
    "1: unplugged",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x49, 3, 1,
  },
  {
    "sys_led_ctrl_status",
    "sys led ctrl status\n"
    "0: ctrl by cpu or cpld\n"
    "1: ctrl by bmc",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x50, 3, 1,
  },
  {
    "sys_led_ctrl",
    "sys led ctrl\n"
    "3: green blink\n"
    "4: green\n"
	"5: yellow blink\n"
	"6: yellow\n"
	"others: off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x50, 0, 3,
  },
  {
    "psu_led_ctrl_status",
    "psu led ctrl status\n"
    "0: ctrl by hw\n"
    "1: ctrl by sw",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x51, 3, 1,
  },
  {
    "psu_led_ctrl",
    "psu led ctrl\n"
    "3: green blink\n"
    "4: green\n"
	"5: yellow blink\n"
	"6: yellow\n"
	"others: off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x51, 0, 3,
  },
  {
    "fan_led_ctrl",
    "fan led ctrl\n"
    "27: fan1 green blink fan2 green blink\n"
    "28: fan1 green fan2 green blink\n"
    "29: fan1 yellow blink fan2 green blink\n"
    "30: fan1 yellow fan2 green blink\n"
    "35: fan1 green blink fan2 green\n"
    "36: fan1 green fan2 green\n"
    "37: fan1 yellow blink fan2 green\n"
    "38: fan1 yellow fan2 green\n"
    "43: fan1 green blink fan2 yellow blink\n"
    "44: fan1 green fan2 yellow blink\n"
    "46: fan1 yellow fan2 yellow blink\n"
    "51: fan1 green blink fan2 yellow\n"
    "52: fan1 green fan2 yellow\n"
    "53: fan1 yellow blink fan2 yellow\n"
    "54: fan1 yellow fan2 yellow\n"
	  "others: off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x52, 0, 3,
  },
  {
    "cpu_12v_ctrl",
    "cpu 12v ctrl\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x75, 0, 1,
  },
  {
    "bmc_vpvdd_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7B, 0, 1,
  },
  {
    "bmc_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7B, 1, 1,
  },
  {
    "bmc_vdd3v3_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7B, 2, 1,
  },
  {
    "m2_vdd3v3_2_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7B, 3, 1,
  },
  {
    "m2_vdd3v3_1_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7B, 4, 1,
  },
  {
    "vcc1v5_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7B, 5, 1,
  },
  {
    "cpu_vdd12v_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7B, 6, 1,
  },
  {
    "vdd3v3_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7B, 7, 1,
  },
  
  {
    "1v8_ldo_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7C, 0, 1,
  },
  {
    "vdd3v3_phy_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7C, 1, 1,
  },
  {
    "vcc1v05_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7C, 2, 1,
  },
  {
    "vcc3v3_sb_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7C, 3, 1,
  },
  {
    "vcc3v3_p_aux_pg",
    "pg status\n"
    "0: abnormal\n"
    "1: normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x7C, 4, 1,
  },
  {
    "uart_status",
    "uart status\n"
    "0: cpu\n"
    "1: bmc",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0xA1, 0, 2,
  },
  {
    "uart_sel",
    "uart sel\n"
    "0: cpu\n"
    "1: bmc",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xA7, 0, 2,
  },
  {
    "uart_sel_update",
    "1: uart sel update",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xA7, 3, 1,
  },
  {
    "pcie4_clk_alarm_clr",
    "0: clear PCIe4.0 CLK alarm(R/C reg0xB4)",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0xB0, 0, 1,
  },
  {
    "pcie4_clk_monitor_cnt",
    "0: counter of PCIe4.0 CLK errs",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0xB3, 0, 8,
  },
  {
    "pcie4_clk_monitor_alarm_state",
    "0: PCIe4.0 CLK alarm(reg0xB3) normal\n"
    "1: PCIe4.0 CLK alarm(reg0xB3) abnormal\n",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0xB4, 0, 1,
  },
  {
    "pcie_clk_alarm_clr",
    "0: clear PCIe3.0 CLK alarm(R/C reg0xB9)",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0xB5, 0, 1,
  },
  {
    "pcie_clk_monitor_cnt",
    "0: counter of PCIe3.0 CLK errs",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0xB8, 0, 8,
  },
  {
    "pcie_clk_monitor_alarm_state",
    "0: PCIe3.0 CLK alarm(reg0xB8) normal\n"
    "1: PCIe3.0 CLK alarm(reg0xB8) abnormal\n",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0xB9, 0, 1,
  },
  {
    "base_eeprom_wp",
    "0: Not protected\n"
    "1: Protected",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xE6, 0, 1,
  },
  {
    "88e6361_eeprom_wp",
    "0: Not protected\n"
    "1: Protected",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xE6, 2, 1,
  },
  // {
  //   "fpga_flash_wp",
  //   "0: Not protected\n"
  //   "1: Protected",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0xE6, 3, 1,
  // },
  {
    "rtl8111_eeprom_wp",
    "0: Not protected\n"
    "1: Protected",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xE6, 4, 1,
  },
  {
    "bmc_fpga_update",
    "0: enbale bmc update fpga flash\n"
    "1: disable bmc update fpga flash",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xE7, 3, 1,
  },
  {
    "rtl8111_update_en",
    "0: disable 88e6361 update\n"
    "1: enable 88e6361 update",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xE7, 6, 1,
  },
  // {
  //   "bmc_mac_spi_sel",
  //   "0: disable bmc access mac flash\n"
  //   "1: enbale bmc access mac flash",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0xE7, 4, 1,
  // },
  {
    "rtc_battery_vol_en",
    "0: disable rtc battery vol check\n"
    "1: enbale rtc battery vol check",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xE8, 0, 1,
  },
  {
    "88e6361_update_en",
    "0: disable 88e6361 update\n"
    "1: enable 88e6361 update",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xE8, 3, 1,
  },
  {
    "rtc_battery_state",
    "0: Abnormal\n"
    "1: Normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xEA, 0, 1,
  },
  {
    "me_mode",
    "0: ME recovery\n"
    "1: Normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xEB, 0, 1,
  },
  {
    "jtag_sel",
    "0x7f: base cpld\n"
    "0x7e: ocm cpld\n"
    "0x7d: fan1 cpld\n"
    "0x3f: fan2 cpld\n"
    "0xfb: misc cpld\n"
    "0xdb: port cpld1\n"
    "0xeb: port cpld2\n"
    "0xcb: led cpld",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xE9, 0, 8,
  },
  {
    "power_force_ctrl_en",
    "power force ctrl enable for port/switch/ssd\n"
    "0x4E: disable\n"
    "0x59: enable",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x70, 0, 7,
  },
  {
    "port_power_force_ctrl",
    "power force ctrl for port\n"
    "0x1: power on\n"
    "0x0: power off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x71, 0, 1,
  },
  {
    "switch_power_force_ctrl",
    "power force ctrl for switch\n"
    "0x1: power on\n"
    "0x0: power off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x72, 0, 1,
  },
  {
    "ssd_power_force_ctrl",
    "power force ctrl for ssd\n"
    "0x1: power on\n"
    "0x0: power off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x72, 1, 1,
  },
};

/*
 * basecpld i2c addresses.
 */
static const unsigned short normal_i2c[] = {
  0x0d, I2C_CLIENT_END
};

/* basecpld id */
static const struct i2c_device_id basecpld_id[] = {
  { "basecpld", 0 },
  { },
};
MODULE_DEVICE_TABLE(i2c, basecpld_id);

/* Return 0 if detection is successful, -ENODEV otherwise */
static int basecpld_detect(struct i2c_client *client,
                          struct i2c_board_info *info)
{
  /*
   * We don't currently do any detection of the basecpld
   */
  strscpy(info->type, "basecpld", I2C_NAME_SIZE);
  return 0;
}

static int basecpld_probe(struct i2c_client *client)
{
  int n_attrs = sizeof(basecpld_attr_table) / sizeof(basecpld_attr_table[0]);
  struct device *dev = &client->dev;
  i2c_dev_data_st *data;
  int ret = 0;

  printk("basecpld_probe enter\n");
  data = devm_kzalloc(dev, sizeof(i2c_dev_data_st), GFP_KERNEL);
  if (!data) {
    return -ENOMEM;
  }

  ret = i2c_dev_sysfs_data_init(client, data,
                                 basecpld_attr_table, n_attrs);
  return ret;
}

static void basecpld_remove(struct i2c_client *client)
{
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_dev_sysfs_data_clean(client, data);
}

static struct i2c_driver basecpld_driver = {
  .class  = I2C_CLASS_HWMON,
  .driver = {
    .name = "basecpld",
  },
  .probe    = basecpld_probe,
  .remove   = basecpld_remove,
  .id_table = basecpld_id,
  .detect   = basecpld_detect,
  .address_list = normal_i2c,
};

static int __init basecpld_mod_init(void)
{
  return i2c_add_driver(&basecpld_driver);
}

static void __exit basecpld_mod_exit(void)
{
  i2c_del_driver(&basecpld_driver);
}

MODULE_AUTHOR("Cray <cray@accton.com.cn>");
MODULE_DESCRIPTION("basecpld Driver");
MODULE_LICENSE("GPL");

module_init(basecpld_mod_init);
module_exit(basecpld_mod_exit);
