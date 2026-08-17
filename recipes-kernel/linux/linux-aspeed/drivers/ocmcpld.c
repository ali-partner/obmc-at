/*
 * ocmcpld.c - The i2c driver for ocmcpld
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
#include "i2c_dev_sysfs.h"


#ifdef DEBUG

#define PP_DEBUG(fmt, ...) do {                   \
  printk(KERN_DEBUG "%s:%d " fmt "\n",            \
         __FUNCTION__, __LINE__, ##__VA_ARGS__);  \
} while (0)

#else /* !DEBUG */

#define PP_DEBUG(fmt, ...)

#endif
static const i2c_dev_attr_st ocmcpld_attr_table[] = {
  {
    "cpld_board_info",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0, 0, 4,
  },
  {
    "cpld_major_ver",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    1, 0, 8,
  },
  {
    "cpld_minor_ver",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    2, 0, 8,
  },
  {
    "cpld_ver",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    1, 0, 16,
  },
  {
    "cpld_year",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    3, 0, 8,
  },
  {
    "cpld_month",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    4, 0, 8,
  },
  {
    "cpld_date",
    NULL,
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    5, 0, 8,
  },
  // {
  //   "cpld_test",
  //   NULL,
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0xf7, 0, 8,
  // },
  // {
  //   "CPU_prochot",
  //   "1: CPU protect hot\n"
  //   "0: CPU protect hot (PROCHOT_LATCH)\n",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   0x10, 0, 2,
  // },
};

/*
 * ocmcpld i2c addresses.
 */
static const unsigned short normal_i2c[] = {
  0x0d, I2C_CLIENT_END
};

/* ocmcpld id */
static const struct i2c_device_id ocmcpld_id[] = {
  { "ocmcpld", 0 },
  { },
};
MODULE_DEVICE_TABLE(i2c, ocmcpld_id);

/* Return 0 if detection is successful, -ENODEV otherwise */
static int ocmcpld_detect(struct i2c_client *client,
                          struct i2c_board_info *info)
{
  /*
   * We don't currently do any detection of the ocmcpld
   */
  strscpy(info->type, "ocmcpld", I2C_NAME_SIZE);
  return 0;
}

static int ocmcpld_probe(struct i2c_client *client)
{
  int n_attrs = sizeof(ocmcpld_attr_table) / sizeof(ocmcpld_attr_table[0]);
  struct device *dev = &client->dev;
  i2c_dev_data_st *data;
  int ret = 0;

  data = devm_kzalloc(dev, sizeof(i2c_dev_data_st), GFP_KERNEL);
  if (!data) {
    return -ENOMEM;
  }

  ret = i2c_dev_sysfs_data_init(client, data,
                                 ocmcpld_attr_table, n_attrs);
  return ret;
}

static void ocmcpld_remove(struct i2c_client *client)
{
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_dev_sysfs_data_clean(client, data);
}

static struct i2c_driver ocmcpld_driver = {
  .class  = I2C_CLASS_HWMON,
  .driver = {
    .name = "ocmcpld",
  },
  .probe    = ocmcpld_probe,
  .remove   = ocmcpld_remove,
  .id_table = ocmcpld_id,
  .detect   = ocmcpld_detect,
  .address_list = normal_i2c,
};

static int __init ocmcpld_mod_init(void)
{
  return i2c_add_driver(&ocmcpld_driver);
}

static void __exit ocmcpld_mod_exit(void)
{
  i2c_del_driver(&ocmcpld_driver);
}

MODULE_AUTHOR("Cray <cray@accton.com.cn>");
MODULE_DESCRIPTION("ocmcpld Driver");
MODULE_LICENSE("GPL");

module_init(ocmcpld_mod_init);
module_exit(ocmcpld_mod_exit);
