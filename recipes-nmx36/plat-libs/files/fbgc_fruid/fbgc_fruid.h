/*
 *
 * Copyright 2020-present Facebook. All Rights Reserved.
 *
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

#ifndef __FBGC_FRUID_H__
#define __FBGC_FRUID_H__

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_FRU_NAME_STR  64
#define MAX_BIN_FILE_STR  32
#define MAX_FILE_PATH     64

#define FRUID_HEADER_SIZE     (8)
#define FRUID_HEADER_EMPTY    (0x07)

#define FRUID_OFFSET_MULTIPLIER                        8
#define FRUID_HEADER_OFFSET_PRODUCT_INFO               0x04
#define FRUID_PRODUCT_OFFSET_SERIAL                    0x58
#define ACCTON_PATH_FRU_EEPROM_BMC_BOARD    "/sys/bus/i2c/devices/2-0052/eeprom"
#define ACCTON_PATH_FRU_EEPROM_BASE_BOARD   "/sys/bus/i2c/devices/24-0051/eeprom"
#define ACCTON_PATH_FRU_EEPROM_OCM_BOARD    "/sys/bus/i2c/devices/16-0056/eeprom"
#define ACCTON_PATH_FRU_EEPROM_SWITCH_BOARD "/sys/bus/i2c/devices/32-0050/eeprom"
// #define ACCTON_PATH_FRU_EEPROM_LINE_BOARD   "/sys/class/i2c-adapter/i2c-25/25-0053/eeprom"
#define ACCTON_PATH_FRU_EEPROM_FAN2_BOARD    "/sys/bus/i2c/devices/46-0056/eeprom"
#define ACCTON_PATH_FRU_EEPROM_FAN1_BOARD    "/sys/bus/i2c/devices/94-0056/eeprom"

#define ACCTON_PATH_FRU_EEPROM_FAN1 "/sys/bus/i2c/devices/88-0050/eeprom"
#define ACCTON_PATH_FRU_EEPROM_FAN2 "/sys/bus/i2c/devices/89-0050/eeprom"
#define ACCTON_PATH_FRU_EEPROM_FAN3 "/sys/bus/i2c/devices/90-0050/eeprom"
#define ACCTON_PATH_FRU_EEPROM_FAN4 "/sys/bus/i2c/devices/91-0050/eeprom"
#define ACCTON_PATH_FRU_EEPROM_FAN5 "/sys/bus/i2c/devices/40-0050/eeprom"
#define ACCTON_PATH_FRU_EEPROM_FAN6 "/sys/bus/i2c/devices/41-0050/eeprom"
#define ACCTON_PATH_FRU_EEPROM_FAN7 "/sys/bus/i2c/devices/42-0050/eeprom"
#define ACCTON_PATH_FRU_EEPROM_FAN8 "/sys/bus/i2c/devices/43-0050/eeprom"

int fbgc_get_fruid_name(uint8_t fru, char *name);
int fbgc_get_fruid_path(uint8_t fru, char *path);
int fbgc_get_fruid_eeprom_path(uint8_t fru, char *path);
int fbgc_fruid_write(uint8_t fru, char *path);
int fbgc_check_fru_is_valid(const char * bin_file, int log_level);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* __FBGC_FRUID_H__ */
