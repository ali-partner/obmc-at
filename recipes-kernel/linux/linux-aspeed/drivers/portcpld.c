/*
 * portcpld.c - The i2c driver for PDBCPLD
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

static const i2c_dev_attr_st portcpld_attr_table[] = {
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
    "cpld_ver",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0, 0, 8,
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
    "cpld_test",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0xf, 0, 8,
  },
  // {
  //   "led_ctrl",
  //   NULL,
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0x2f, 0, 2,
  // },
};

/*
 * PORTCPLD i2c addresses.
 */
static const unsigned short normal_i2c[] = {
  0x31, I2C_CLIENT_END
};

/* PORTCPLD id */
static const struct i2c_device_id portcpld_id[] = {
  { "portcpld", 0 },
  { },
};
MODULE_DEVICE_TABLE(i2c, portcpld_id);

/* Return 0 if detection is successful, -ENODEV otherwise */
static int portcpld_detect(struct i2c_client *client,
                          struct i2c_board_info *info)
{
  /*
   * We don't currently do any detection of the PORTCPLD
   */
  strscpy(info->type, "portcpld", I2C_NAME_SIZE);
  return 0;
}

static int portcpld_probe(struct i2c_client *client)
{
  int n_attrs = sizeof(portcpld_attr_table) / sizeof(portcpld_attr_table[0]);
  struct device *dev = &client->dev;
  i2c_dev_data_st *data;

  data = devm_kzalloc(dev, sizeof(i2c_dev_data_st), GFP_KERNEL);
  if (!data) {
    return -ENOMEM;
  }

  return i2c_dev_sysfs_data_init(client, data,
                                 portcpld_attr_table, n_attrs);
}

static void portcpld_remove(struct i2c_client *client)
{
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_dev_sysfs_data_clean(client, data);
}

static struct i2c_driver portcpld_driver = {
  .class    = I2C_CLASS_HWMON,
  .driver = {
    .name = "portcpld",
  },
  .probe    = portcpld_probe,
  .remove   = portcpld_remove,
  .id_table = portcpld_id,
  .detect   = portcpld_detect,
  .address_list = normal_i2c,
};

static int __init portcpld_mod_init(void)
{
  return i2c_add_driver(&portcpld_driver);
}

static void __exit portcpld_mod_exit(void)
{
  i2c_del_driver(&portcpld_driver);
}

MODULE_AUTHOR("Tian Fang <tfang@fb.com>");
MODULE_DESCRIPTION("PORTCPLD Driver");
MODULE_LICENSE("GPL");

module_init(portcpld_mod_init);
module_exit(portcpld_mod_exit);
