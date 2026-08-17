/*
 * switchfpga.c - The i2c driver for SWITCHFPGA
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

// #define DEBUG

#include <linux/errno.h>
#include <linux/module.h>
#include <linux/i2c.h>
#include "i2c_dev_sysfs.h"

#ifdef DEBUG

#define SWITCH_DEBUG(fmt, ...) do {                   \
  printk(KERN_DEBUG "%s:%d " fmt "\n",            \
         __FUNCTION__, __LINE__, ##__VA_ARGS__);  \
} while (0)

#else /* !DEBUG */

#define SWITCH_DEBUG(fmt, ...)

#endif

#define INDIRECT_ADDR_REG    0xe0
#define INDIRECT_WRITE_REG   0xe4
#define INDIRECT_READ_REG    0xe8
#define INDIRECT_ACCESS_REG  0xec

static ssize_t fpga_write(struct device *dev,
                                  struct device_attribute *attr,
                                  const char *buf, size_t count)
{
  struct i2c_client *client = to_i2c_client(dev);
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
  const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
  int i, mask, ret;
  uint32_t val, result = 0;
  uint8_t values[4];

  if (sscanf(buf, "%i", &val) <= 0) {
    SWITCH_DEBUG("val\n");
    return -EINVAL;
  }

  if (dev_attr->ida_reg != INDIRECT_ADDR_REG &&
      dev_attr->ida_reg != INDIRECT_WRITE_REG ) {
    mask = (1 << dev_attr->ida_n_bits) - 1;
    val &= mask;
    ret = i2c_dev_read_nbytes(dev, attr, values, 4);
    if (ret < 0) {
      /* error case */
      return ret;
    }

    result = (values[0] << 24) | (values[1] << 16) |
             (values[2] << 8) | values[3];
    result &= ~(mask << dev_attr->ida_bit_offset);
  }

  result |= val << dev_attr->ida_bit_offset;

  values[0] = (result >> 24) & 0xff;
  values[1] = (result >> 16) & 0xff;
  values[2] = (result >> 8) & 0xff;
  values[3] = result & 0xff;

  mutex_lock(&data->idd_lock);
  for (i = 0; i < 4; i++) {
    ret = i2c_smbus_write_byte_data(client, dev_attr->ida_reg + i, values[i]);
    if (ret < 0) {
      /* error case */
      mutex_unlock(&data->idd_lock);
      SWITCH_DEBUG("I2C write error, ret: %d, byte cnt: %d\n", ret, i);
      return ret;
    }
  }

  if (dev_attr->ida_reg == INDIRECT_WRITE_REG) {
    ret = i2c_smbus_write_byte_data(client, INDIRECT_ACCESS_REG, 1);
    if (ret < 0) {
      /* error case */
      mutex_unlock(&data->idd_lock);
      SWITCH_DEBUG("I2C write error, ret: %d\n", ret);
      return ret;
    }
  }
  mutex_unlock(&data->idd_lock);

  return count;
}

static ssize_t fpga_read(struct device *dev,
                                 struct device_attribute *attr,
                                 char *buf)
{
  struct i2c_client *client = to_i2c_client(dev);
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
  const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
  int result;
  int mask, ret;
  uint8_t values[4];
  uint32_t reg_val = 0;

  if (dev_attr->ida_reg == INDIRECT_READ_REG) {
    mutex_lock(&data->idd_lock);
    ret = i2c_smbus_write_byte_data(client, INDIRECT_ACCESS_REG, 0);
    mutex_unlock(&data->idd_lock);
    if (ret < 0) {
      /* error case */
      SWITCH_DEBUG("I2C read error, ret: %d\n", ret);
      return ret;
    }
  }

  ret = i2c_dev_read_nbytes(dev, attr, values, 4);
  if (ret < 0) {
    /* error case */
    return ret;
  }

  mask = (1 << (dev_attr->ida_n_bits)) - 1;
  reg_val = (values[0] << 24) | (values[1] << 16) |
           (values[2] << 8) | values[3];
  result = (reg_val >> dev_attr->ida_bit_offset) & mask;

  return scnprintf(buf, PAGE_SIZE,
                   "%#x\n\nNote:\n%s\n"
                   "Bit[%d:%d] @ register %#x, register value %#x\n",
                   result, (dev_attr->ida_help) ? dev_attr->ida_help : "",
                   dev_attr->ida_bit_offset + dev_attr->ida_n_bits - 1,
                   dev_attr->ida_bit_offset, dev_attr->ida_reg, reg_val);
}


//fpga寄存器地址使用的大端，需做转换
static const i2c_dev_attr_st switchfpga_attr_table[] = {
  {
    "minor_ver",
    "fpga minor ver",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x03, 0, 8,
  },
  {
    "major_ver",
    "fpga major ver",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x02, 0, 8,
  },
  {
    "fpga_date_ver",
    "fpga date info",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x04, 0, 32,
  },
  {
    "fpga_test",
    "fpga test register",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x08, 0, 32,
  }, 
  {
    "golden_fpga_ver",
    "golden fpga version",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x0c, 0, 32,
  },
  {
    "hard_ver",
    "Hard version",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    NULL,
    0x27, 0, 4,
  },
  {
    "bmc_write_enable",
    "0x00: BMC Write Protect\n"
    "0xbc: BMC Write Enable",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x70, 24, 8,
  },
  {
    "bmc_scratch_pad",
    "BMC scratch pad",
    I2C_DEV_ATTR_SHOW_DEFAULT,
    I2C_DEV_ATTR_STORE_DEFAULT,
    0x74, 24, 8,
  },
  // {
  //   "indirect_addr",
  //   "Indirect Access Address register",
  //   fpga_read,
  //   fpga_write,
  //   INDIRECT_ADDR_REG, 0, 32,
  // },
  // {
  //   "indirect_write",
  //   "Indirect Access Write data register",
  //   fpga_read,
  //   fpga_write,
  //   INDIRECT_WRITE_REG, 0, 32,
  // },
  // {
  //   "indirect_read",
  //   "Indirect Access Read data",
  //   fpga_read,
  //   NULL,
  //   INDIRECT_READ_REG, 0, 32,
  // },
  //  {
  //   "indirect_commad",
  //   "Indirect commad Reg",
  //   I2C_DEV_ATTR_SHOW_DEFAULT,
  //   I2C_DEV_ATTR_STORE_DEFAULT,
  //   INDIRECT_ACCESS_REG, 0, 8,
  // },
};

/*
 * SWITCHFPGA i2c addresses.
 */
static const unsigned short normal_i2c[] = {
  0x32, I2C_CLIENT_END
};

/* SWITCHFPGA id */
static const struct i2c_device_id switchfpga_id[] = {
  { "switchfpga", 0 },
  { },
};
MODULE_DEVICE_TABLE(i2c, switchfpga_id);

/* Return 0 if detection is successful, -ENODEV otherwise */
static int switchfpga_detect(struct i2c_client *client,
                          struct i2c_board_info *info)
{
  /*
   * We don't currently do any detection of the SWITCHFPGA
   */
  strscpy(info->type, "switchfpga", I2C_NAME_SIZE);
  return 0;
}

static int switchfpga_probe(struct i2c_client *client)
{
  int n_attrs = sizeof(switchfpga_attr_table) / sizeof(switchfpga_attr_table[0]);
  struct device *dev = &client->dev;
  i2c_dev_data_st *data;

  data = devm_kzalloc(dev, sizeof(i2c_dev_data_st), GFP_KERNEL);
  if (!data) {
    return -ENOMEM;
  }

  return i2c_dev_sysfs_data_init(client, data,
                                 switchfpga_attr_table, n_attrs);
}

static void switchfpga_remove(struct i2c_client *client)
{
  i2c_dev_data_st *data = i2c_get_clientdata(client);
  i2c_dev_sysfs_data_clean(client, data);
}

static struct i2c_driver switchfpga_driver = {
  .class    = I2C_CLASS_HWMON,
  .driver = {
    .name = "switchfpga",
  },
  .probe    = switchfpga_probe,
  .remove   = switchfpga_remove,
  .id_table = switchfpga_id,
  .detect   = switchfpga_detect,
  .address_list = normal_i2c,
};

static int __init switchfpga_mod_init(void)
{
  return i2c_add_driver(&switchfpga_driver);
}

static void __exit switchfpga_mod_exit(void)
{
  i2c_del_driver(&switchfpga_driver);
}

MODULE_AUTHOR("Cray <cray@accton.com.cn>");
MODULE_DESCRIPTION("SWITCHFPGA Driver");
MODULE_LICENSE("GPL");

module_init(switchfpga_mod_init);
module_exit(switchfpga_mod_exit);
