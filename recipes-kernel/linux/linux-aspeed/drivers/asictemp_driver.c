/*
 * asictemp_driver.c - The i2c driver to get following ASIC tempature information:
 * 
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

#include <linux/device.h>
#include <linux/errno.h>
#include <linux/kernel.h>	/* for ARRAY_SIZE */
#include <linux/module.h>
#include <linux/i2c.h>
#include <linux/delay.h>
#include <linux/string.h>
#include "i2c_dev_sysfs.h"

#define ASIC_TEMP_MIN          0
#define ASIC_TEMP_MAX          120
#define TEMP_FILTER_WINDOW     3
#define MAX_CONTINUE_ERROR     5
#define INVALID_TEMP_VAL       0xFF
#define ASIC_TEMP_DEFAULT      25

struct asic_temp_filter {
    int history[TEMP_FILTER_WINDOW];
    int smooth_temp;
    u8 err_continuous_cnt;
    u8 initialized;
};

struct asictemp_priv {
    i2c_dev_data_st sysfs_data;
    struct asic_temp_filter filter;
};

static inline struct asictemp_priv *to_asictemp_priv(i2c_dev_data_st *data)
{
    return container_of(data, struct asictemp_priv, sysfs_data);
}

static void asic_temp_filter_init(struct asic_temp_filter *filter)
{
    int i;

    filter->smooth_temp = ASIC_TEMP_DEFAULT;
    filter->err_continuous_cnt = 0;
    filter->initialized = 0;
    for (i = 0; i < TEMP_FILTER_WINDOW; i++)
        filter->history[i] = INVALID_TEMP_VAL;
}

static void asic_temp_process(struct asic_temp_filter *filter, int raw_temp)
{
    int i, sum = 0, valid_data_num = 0;

    if (raw_temp < 0 || raw_temp == INVALID_TEMP_VAL ||
        raw_temp < ASIC_TEMP_MIN || raw_temp > ASIC_TEMP_MAX) {
        filter->err_continuous_cnt++;
        return;
    }

    filter->err_continuous_cnt = 0;

    for (i = TEMP_FILTER_WINDOW - 1; i > 0; i--)
        filter->history[i] = filter->history[i - 1];
    filter->history[0] = raw_temp;

    for (i = 0; i < TEMP_FILTER_WINDOW; i++) {
        if (filter->history[i] != INVALID_TEMP_VAL) {
            sum += filter->history[i];
            valid_data_num++;
        }
    }

    if (valid_data_num)
        filter->smooth_temp = sum / valid_data_num;

    printk("filter->initialized = %d\n");
    if (!filter->initialized)
        filter->initialized = 1;
}

#ifdef DEBUG
#define ASICTEMP_DEBUG(fmt, ...) do {                   \
  printk(KERN_DEBUG "%s:%d " fmt "\n",            \
         __FUNCTION__, __LINE__, ##__VA_ARGS__);  \
} while (0)

#else /* !DEBUG */
#define ASICTEMP_DEBUG(fmt, ...)
#endif


static ssize_t asic_temp_show(struct device *dev,
                            struct device_attribute *attr,
                            char *buf)
{
  struct i2c_client *client = to_i2c_client(dev);
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  struct asictemp_priv *priv = to_asictemp_priv(data);
  struct asic_temp_filter *filter = &priv->filter;
  i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
  const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
  int temp_value;
  int value = 0;
  int retry = 0;

  do {
    mutex_lock(&data->idd_lock);
    value = i2c_smbus_read_byte_data(client, dev_attr->ida_reg);
    mutex_unlock(&data->idd_lock);

    printk("asic_temp_show value = %d\n", value);
    if (value > 0)
        break;

    retry++;
    msleep(100);
  } while (retry < 3);

  asic_temp_process(filter, value);

  if (filter->err_continuous_cnt == MAX_CONTINUE_ERROR)
    dev_warn(dev, "ASIC temp read failed continuously %u times\n",
             filter->err_continuous_cnt);

  if (!filter->initialized)
    temp_value = ASIC_TEMP_DEFAULT;
  else
    temp_value = filter->smooth_temp;

  return scnprintf(buf, PAGE_SIZE, "%d\n", temp_value);
}

static const i2c_dev_attr_st asictemp_attr_table[] = {
  
  {
    "temp_input",
    NULL,
    asic_temp_show,
    NULL,
    0x01, 0, 8,
  },
};

/*
 * psu i2c addresses.
 */
static const unsigned short normal_i2c[] = {
  0x1f, I2C_CLIENT_END
};

/* psu_driver id */
static const struct i2c_device_id asictemp_id[] = {
  {"asictemp_driver", 0},
  { },
};
MODULE_DEVICE_TABLE(i2c, asictemp_id);

/* Return 0 if detection is successful, -ENODEV otherwise */
static int asictemp_detect(struct i2c_client *client,
                         struct i2c_board_info *info)
{
  /*
   * We don't currently do any detection of the driver
   */
  strscpy(info->type, "asictemp_driver", I2C_NAME_SIZE);
  return 0;
}

static int asictemp_probe(struct i2c_client *client)
{
  int n_attrs = sizeof(asictemp_attr_table) / sizeof(asictemp_attr_table[0]);
  struct device *dev = &client->dev;
  struct asictemp_priv *priv;

  priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
  if (!priv)
    return -ENOMEM;

  asic_temp_filter_init(&priv->filter);

  return i2c_dev_sysfs_data_init(client, &priv->sysfs_data,
                                 asictemp_attr_table, n_attrs);
}

static void asictemp_remove(struct i2c_client *client)
{
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_dev_sysfs_data_clean(client, data);
}

static const struct of_device_id asictemp_driver_of_match[] = {
    { .compatible = "asictemp_driver" },
    {}
};

static struct i2c_driver asictemp_driver = {
  .class    = I2C_CLASS_HWMON,
  .driver = {
    .name = "asictemp_driver",
    .of_match_table = asictemp_driver_of_match,
  },
  .probe    = asictemp_probe,
  .remove   = asictemp_remove,
  .id_table = asictemp_id,
  .detect   = asictemp_detect,
  .address_list = normal_i2c,
};

static int __init asictemp_mod_init(void)
{
  return i2c_add_driver(&asictemp_driver);
}

static void __exit asictemp_mod_exit(void)
{
  i2c_del_driver(&asictemp_driver);
}

module_init(asictemp_mod_init);
module_exit(asictemp_mod_exit);

MODULE_AUTHOR("Cray");
MODULE_DESCRIPTION("ASIC tempature Driver");
MODULE_LICENSE("GPL");

