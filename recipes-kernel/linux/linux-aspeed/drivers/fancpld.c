/*
 * fancpld.c - The i2c driver for FANBOARDCPLD
 *
 * Copyright 2015-present Facebook. All Rights Reserved.
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

#define FANTRAY_PWM_HELP                        \
  "each value represents 1/32 duty cycle"
#define FANTRAY_LED_CTRL_HELP                   \
  "bit0: Red led on/off\n"                     \
  "bit1: Green led on/off\n"                     \
  "bit2: Blink on/off\n"                     \
  "bit3: Yellow led on/off"                  \
  "0x3: Yellow" \
  "0x7: Yellow bilink" \
  "0x9: Green" \
  "0xd: Green blink" \
  "0xa: Red" \
  "0xe: Red blink" \

static ssize_t fancpld_fan_rpm_show(struct device *dev,
                                    struct device_attribute *attr,
                                    char *buf)
{
  struct i2c_client *client = to_i2c_client(dev);
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
  const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
  int val_l = 0;
  int val_h = 0;
  int val = 0;
  int speed;
  int val_mask;

  val_mask = ~(((-1) >> (dev_attr->ida_n_bits)) << (dev_attr->ida_n_bits));

  mutex_lock(&data->idd_lock);

  val_l = i2c_smbus_read_byte_data(client, dev_attr->ida_reg);

  val_h = i2c_smbus_read_byte_data(client, dev_attr->ida_reg + 1);

  mutex_unlock(&data->idd_lock);

  val = (val_h << 8) + val_l;

  if (val == 0xffff) {
    speed = 0;
  } else {
    speed = 60000000 / (val * 2 * 2);
  }

  return scnprintf(buf, PAGE_SIZE, "%d\n", speed);
}


static ssize_t show_fan_pwm(struct device *dev,
                            struct device_attribute *attr,
                            char *buf)
{
  struct i2c_client *client = to_i2c_client(dev);
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
  const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
  int pwm;
  int value = 0;

  mutex_lock(&data->idd_lock);

  value = i2c_smbus_read_byte_data(client, dev_attr->ida_reg);

  mutex_unlock(&data->idd_lock);
  if (value < 0)
  {
      /* error case */
      return value;
  }
  pwm = (value + 2) * 100 / 256;
  return scnprintf(buf, PAGE_SIZE, "%d\n", pwm);
}

static ssize_t store_fan_pwm(struct device *dev,
                             struct device_attribute *attr,
                             const char *buf,
                             size_t count)
{
  struct i2c_client *client = to_i2c_client(dev);
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
  const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
  int value = 0;
  unsigned int pwm = 0;
  unsigned int reg_val;
  /* parse the buffer */
  if (sscanf(buf, "%i", &pwm) <= 0) {
      return -EINVAL;
  }
  pwm = (pwm > 100)?100:pwm;
  reg_val = pwm * 255 / 100;
  mutex_lock(&data->idd_lock);

  value = i2c_smbus_write_byte_data(client, dev_attr->ida_reg, reg_val);

  mutex_unlock(&data->idd_lock);
  if (value < 0)
  {
      /* error case */
      return value;
  }

  return count;
}

static const i2c_dev_attr_st fancpld_attr_table[] = {
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
    "banka_id",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    4, 0, 4,
  },
  {
    "cpld_id",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    5, 0, 8,
  },
  {
    "board_id",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    7, 0, 4,
  },
  {
    "fan_led_ctrl_status",
    "fan led ctrl status\n"
    "0: ctrl by hw\n"
    "1: ctrl by sw",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x8, 4, 1,
  },
  {
    "fan_led_ctrl",
    "fan led ctrl\n"
    "3: green blink\n"
    "4: green\n"
    "5: yellow blink\n"
    "6: yellow\n"
    "others: off",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x8, 0, 3,
  },
  {
    "fan_watchdog_normal",
    "fan watchdog status:\n"
    "0: fan watchdog status: normal\n",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xc, 2, 1,
  },
  {
    "fan_watchdog_timeout",
    "fan watchdog status:\n"
    "0: fan watchdog status:s timeout\n",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xc, 1, 1,
  },
  {
    "fan_watchdog_en",
    "fan watchdog enable\n"
    "0: disable\n"
    "1: enable",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xc, 0, 1,
  },
  {
    "cpld_test",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x0f, 0, 8,
  },
  {
    "fan1_sp_l",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x20, 0, 8,
  },
  {
    "fan1_sp_h",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x21, 0, 8,
  },
  {
    "fan1_sp_l2",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x22, 0, 8,
  },
  {
    "fan1_sp_h2",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x23, 0, 8,
  },
  {
    "fan1_speed_1",
    NULL,
    fancpld_fan_rpm_show,
    NULL,
    0x20, 0, 8,
  },
  {
    "fan1_speed_2",
    NULL,
    fancpld_fan_rpm_show,
    NULL,
    0x22, 0, 8,
  },
  {
    "fantray1_pwm",
    NULL,
    show_fan_pwm,
    store_fan_pwm,
    0x24, 0, 8,
  },
  {
    "fantray1_led_ctrl",
    FANTRAY_LED_CTRL_HELP,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x25, 0, 4,
  },
  {
    "fantray1_eeprom_wp",
    "0: Not protected\n"
    "1: Protected",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x26, 0, 1,
  },
  {
    "fantray1_present",
    "0: Alive\n"
    "1: Bad",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x27, 0, 1,
  },
  {
    "fantray1_plugin_his",
    "0: Not pluged\n"
    "1: Pluged\n"
    "read clear",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x28, 0, 1,
  },
  {
    "fantray1_en",
    "0: Normal\n"
    "1: Warning",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x29, 0, 1,
  },
  {
    "fantray1_pgb",
    "0: Warning\n"
    "1: Normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x2a, 0, 1,
  },
  {
    "fantray1_direction",
    "0: front to back\n"
    "1: back to front",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x2B, 0, 1,
  },
  {
    "fan2_sp_l",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x30, 0, 8,
  },
  {
    "fan2_sp_h",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x31, 0, 8,
  },
  {
    "fan2_sp_l2",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x32, 0, 8,
  },
  {
    "fan2_sp_h2",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x33, 0, 8,
  },
  {
    "fan2_speed_1",
    NULL,
    fancpld_fan_rpm_show,
    NULL,
    0x30, 0, 8,
  },
  {
    "fan2_speed_2",
    NULL,
    fancpld_fan_rpm_show,
    NULL,
    0x32, 0, 8,
  },
  {
    "fantray2_pwm",
    NULL,
    show_fan_pwm,
    store_fan_pwm,
    0x34, 0, 8,
  },
  {
    "fantray2_led_ctrl",
    FANTRAY_LED_CTRL_HELP,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x35, 0, 4,
  },
  {
    "fantray2_eeprom_wp",
    "0: Not protected\n"
    "1: Protected",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x36, 0, 1,
  },
  {
    "fantray2_present",
    "0: Alive\n"
    "1: Bad",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x37, 0, 1,
  },
  {
    "fantray2_plugin_his",
    "0: Not pluged\n"
    "1: Pluged\n"
    "read clear",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x38, 0, 1,
  },
  {
    "fantray2_en",
    "0: Normal\n"
    "1: Warning",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x39, 0, 1,
  },
  {
    "fantray2_pgb",
    "0: Warning\n"
    "1: Normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x3a, 0, 1,
  },
  {
    "fantray2_direction",
    "0: front to back\n"
    "1: back to front",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x3B, 0, 1,
  },
  {
    "fan3_sp_l",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x40, 0, 8,
  },
  {
    "fan3_sp_h",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x41, 0, 8,
  },
  {
    "fan3_speed_1",
    NULL,
    fancpld_fan_rpm_show,
    NULL,
    0x40, 0, 8,
  },
  {
    "fan3_speed_2",
    NULL,
    fancpld_fan_rpm_show,
    NULL,
    0x42, 0, 8,
  },
  {
    "fan3_sp_l2",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x42, 0, 8,
  },
  {
    "fan3_sp_h2",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x43, 0, 8,
  },
  {
    "fantray3_pwm",
    NULL,
    show_fan_pwm,
    store_fan_pwm,
    0x44, 0, 8,
  },
  {
    "fantray3_led_ctrl",
    FANTRAY_LED_CTRL_HELP,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x45, 0, 4,
  },
  {
    "fantray3_eeprom_wp",
    "0: Not protected\n"
    "1: Protected",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x46, 0, 1,
  },
  {
    "fantray3_present",
    "0: Alive\n"
    "1: Bad",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x47, 0, 1,
  },
  {
    "fantray3_plugin_his",
    "0: Not pluged\n"
    "1: Pluged\n"
    "read clear",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x48, 0, 1,
  },
  {
    "fantray3_en",
    "0: Normal\n"
    "1: Warning",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x49, 0, 1,
  },
  {
    "fantray3_pgb",
    "0: Warning\n"
    "1: Normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x4a, 0, 1,
  },
  {
    "fantray3_direction",
    "0: front to back\n"
    "1: back to front",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x4B, 0, 1,
  },
  {
    "fan4_sp_l",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x50, 0, 8,
  },
  {
    "fan4_sp_h",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x51, 0, 8,
  },
  {
    "fan4_sp_l2",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x52, 0, 8,
  },
  {
    "fan4_sp_h2",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x53, 0, 8,
  },
  {
    "fan4_speed_1",
    NULL,
    fancpld_fan_rpm_show,
    NULL,
    0x50, 0, 8,
  },
  {
    "fan4_speed_2",
    NULL,
    fancpld_fan_rpm_show,
    NULL,
    0x52, 0, 8,
  },
  {
    "fantray4_pwm",
    NULL,
    show_fan_pwm,
    store_fan_pwm,
    0x54, 0, 8,
  },
  {
    "fantray4_led_ctrl",
    FANTRAY_LED_CTRL_HELP,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x55, 0, 4,
  },
  {
    "fantray4_eeprom_wp",
    "0: Not protected\n"
    "1: Protected",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x56, 0, 1,
  },
  {
    "fantray4_present",
    "0: Alive\n"
    "1: Bad",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x57, 0, 1,
  },
  {
    "fantray4_plugin_his",
    "0: Not pluged\n"
    "1: Pluged\n"
    "read clear",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x58, 0, 1,
  },
  {
    "fantray4_en",
    "0: Normal\n"
    "1: Warning",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x59, 0, 1,
  },
  {
    "fantray4_pgb",
    "0: Warning\n"
    "1: Normal",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x5a, 0, 1,
  },
  {
    "fantray4_direction",
    "0: front to back\n"
    "1: back to front",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x5B, 0, 1,
  },
  // {
  //   "fan5_sp_l",
  //   NULL,
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   NULL,
  //   0x60, 0, 8,
  // },
  // {
  //   "fan5_sp_h",
  //   NULL,
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   NULL,
  //   0x61, 0, 8,
  // },
  // {
  //   "fan5_sp_l2",
  //   NULL,
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   NULL,
  //   0x62, 0, 8,
  // },
  // {
  //   "fan5_sp_h2",
  //   NULL,
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   NULL,
  //   0x63, 0, 8,
  // },
  // {
  //   "fan5_speed_1",
  //   NULL,
  //   fancpld_fan_rpm_show,
  //   NULL,
  //   0x60, 0, 8,
  // },
  // {
  //   "fan5_speed_2",
  //   NULL,
  //   fancpld_fan_rpm_show,
  //   NULL,
  //   0x62, 0, 8,
  // },
  // {
  //   "fantray5_pwm",
  //   NULL,
  //   show_fan_pwm,
  //   store_fan_pwm,
  //   0x64, 0, 8,
  // },
  // {
  //   "fantray5_led_ctrl",
  //   FANTRAY_LED_CTRL_HELP,
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0x65, 0, 4,
  // },
  // {
  //   "fantray5_eeprom_wp",
  //   "0: Not protected\n"
  //   "1: Protected",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0x66, 0, 1,
  // },
  // {
  //   "fantray5_present",
  //   "0: Alive\n"
  //   "1: Bad",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0x67, 0, 1,
  // },
  // {
  //   "fantray5_plugin_his",
  //   "0: Not pluged\n"
  //   "1: Pluged\n"
  //   "read clear",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0x68, 0, 1,
  // },
  // {
  //   "fantray5_en",
  //   "0: Normal\n"
  //   "1: Warning",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0x69, 0, 1,
  // },
  // {
  //   "fantray5_pgb",
  //   "0: Warning\n"
  //   "1: Normal",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0x6a, 0, 1,
  // },
  // {
  //   "fantray5_direction",
  //   "0: front to back\n"
  //   "1: back to front",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0x6B, 0, 1,
  // },
  {
    "fan_eeprom_wp",
    "0: Not protected\n"
    "1: Protected",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xf0, 0, 1,
  },

};


/*
 * FANCPLD i2c addresses.
 */
static const unsigned short normal_i2c[] = {
  0x0d, I2C_CLIENT_END
};

/* FANCPLD id */
static const struct i2c_device_id fancpld_id[] = {
  { "fancpld", 0 },
  { },
};
MODULE_DEVICE_TABLE(i2c, fancpld_id);

/* Return 0 if detection is successful, -ENODEV otherwise */
static int fancpld_detect(struct i2c_client *client,
                          struct i2c_board_info *info)
{
  /*
   * We don't currently do any detection of the FANCPLD
   */
  strscpy(info->type, "fancpld", I2C_NAME_SIZE);
  return 0;
}

static int fancpld_probe(struct i2c_client *client)
{
  int n_attrs = sizeof(fancpld_attr_table) / sizeof(fancpld_attr_table[0]);
  struct device *dev = &client->dev;
  i2c_dev_data_st *data;

  data = devm_kzalloc(dev, sizeof(i2c_dev_data_st), GFP_KERNEL);
  if (!data) {
    return -ENOMEM;
  }

  return i2c_dev_sysfs_data_init(client, data,
                                 fancpld_attr_table, n_attrs);
}

static void fancpld_remove(struct i2c_client *client)
{
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_dev_sysfs_data_clean(client, data);
}

static struct i2c_driver fancpld_driver = {
  .class    = I2C_CLASS_HWMON,
  .driver = {
    .name = "fancpld",
  },
  .probe    = fancpld_probe,
  .remove   = fancpld_remove,
  .id_table = fancpld_id,
  .detect   = fancpld_detect,
  .address_list = normal_i2c,
};

static int __init fancpld_mod_init(void)
{
  return i2c_add_driver(&fancpld_driver);
}

static void __exit fancpld_mod_exit(void)
{
  i2c_del_driver(&fancpld_driver);
}

MODULE_AUTHOR("Cray <cray@accton.com.cn>");
MODULE_DESCRIPTION("FANCPLD Driver");
MODULE_LICENSE("GPL");

module_init(fancpld_mod_init);
module_exit(fancpld_mod_exit);
