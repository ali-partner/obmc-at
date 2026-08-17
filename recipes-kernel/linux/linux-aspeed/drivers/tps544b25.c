/*
 * tps544b25.c - The i2c driver to get following tps information:
 * 
 */

// #define DEBUG

#include <linux/errno.h>
#include <linux/module.h>
#include <linux/i2c.h>
#include <linux/delay.h>

#include "i2c_dev_sysfs.h"

#ifdef DEBUG
#define TPS_DEBUG(fmt, ...) do {                   \
  printk(KERN_DEBUG "%s:%d " fmt "\n",            \
         __FUNCTION__, __LINE__, ##__VA_ARGS__);  \
} while (0)

#else /* !DEBUG */

#define TPS_DEBUG(fmt, ...)
#endif

#define POW2(x) (1 << (x))

#define TPS_DELAY        15
#define PMBUS_MFR_MODEL  0xad

typedef enum {
    TPS544B25,
    UNKNOWN
} model_name;

static model_name model;

enum {
    LINEAR_11,
    LINEAR_16
};

/*
 * PMBus Linear-11 Data Format
 * X = Y*2^N
 * X is the "real world" value;
 * Y is an 11 bit, two's complement integer;
 * N is a 5 bit, two's complement integer.
 *
 * PMBus Linear-16 Data Format
 * X = Y*2^N
 * X is the "real world" value;
 * Y is a 16 bit unsigned binary integer;
 * N is a 5 bit, two's complement integer.
 */
static int linear_convert(int type, int value, int n)
{
    int msb_y, msb_n, data_y, data_n;
    int value_x = 0;

    if (type == LINEAR_11) {
        msb_y = (value >> 10) & 0x1;
        data_y = msb_y ? -1 * ((~value & 0x3ff) + 1)
                   : value & 0x3ff;

        if (n != 0) {
            value_x = (n < 0) ? (data_y * 1000) / POW2(abs(n))
                        : (data_y * 1000) * POW2(n);
        } else {
            msb_n = (value >> 15) & 0x1;

            if (msb_n) {
                data_n = (~(value >> 11) & 0xf) + 1;
                value_x = (data_y * 1000) / POW2(data_n);
            } else {
                data_n = ((value >> 11) & 0xf);
                value_x = (data_y * 1000) * POW2(data_n);
            }
        }
    } else {
        if (n != 0) {
            value_x = (n < 0) ? (value * 1000) / POW2(abs(n))
                        : (value * 1000) * POW2(n);
        }
    }

    return value_x;
}

static int tps_convert(struct device *dev, struct device_attribute *attr)
{
    struct i2c_client *client = to_i2c_client(dev);
    i2c_dev_data_st *data = i2c_get_clientdata(client);
    i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
    const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
    int value = -1;
    int count = 10;
    int ret = -1;
    u8 length;

    mutex_lock(&data->idd_lock);

    ret = i2c_smbus_read_word_data(client, PMBUS_MFR_MODEL);
    length = ret & 0xff;

    if (ret < 0 || length > 32) {
        TPS_DEBUG("Failed to read Manufacturer Model\n");
    } else {
        while((value < 0 || value == 0xffff) && count--) {
            value = i2c_smbus_read_word_data(client, (dev_attr->ida_reg));
        }
    }

    mutex_unlock(&data->idd_lock);

    if (value < 0) {
        TPS_DEBUG("I2C read error, value: %d\n", value);
        return -1;
    }

    return value;
}

static ssize_t tps_vin_show(struct device *dev,
                                struct device_attribute *attr,
                                char *buf)
{
    int result = tps_convert(dev, attr);
    if (result < 0) {
        return -1;
    }

    result = linear_convert(LINEAR_11, result, 0);

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t tps_iin_show(struct device *dev,
                                struct device_attribute *attr,
                                char *buf)
{
    int result = tps_convert(dev, attr);

    if (result < 0) {
        return -1;
    }

    result = linear_convert(LINEAR_11, result, 0);

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t tps_vout_show(struct device *dev,
                                 struct device_attribute *attr,
                                 char *buf)
{
    int result = tps_convert(dev, attr);

    if (result < 0) {
        return -1;
    }
    result = linear_convert(LINEAR_16, result, -9);
    //vout=result;
    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t tps_iout_show(struct device *dev,
                                 struct device_attribute *attr,
                                 char *buf)
{
    int result = tps_convert(dev, attr);

    if (result < 0) {
        return -1;
    }
    result = linear_convert(LINEAR_11, result, 0);
    //iout=result;
    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t tps_power_show(struct device *dev,
                                  struct device_attribute *attr,
                                  char *buf)
{
    int result = 10000;//10mW  float
    struct i2c_client *client = to_i2c_client(dev);
    i2c_dev_data_st *data = i2c_get_clientdata(client);
    i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
    int value1 = -1;
    int value2 = -1;
    int count = 10;
    int ret = -1;
    u8 length;
    int v = 0;
    int i =0;

    mutex_lock(&data->idd_lock);

    ret = i2c_smbus_read_word_data(client, PMBUS_MFR_MODEL);
    length = ret & 0xff;

    if (ret < 0 || length > 32) {
        TPS_DEBUG("Failed to read Manufacturer Model\n");
    } else {
        while((value1 < 0 || value1 == 0xffff) && count--) {
            value1 = i2c_smbus_read_word_data(client, 0x8b);
        }
    }
    v = linear_convert(LINEAR_16, value1, -9);

    if (ret < 0 || length > 32) {
        TPS_DEBUG("Failed to read Manufacturer Model\n");
    } else {
        while((value2 < 0 || value2 == 0xffff) && count--) {
            value2 = i2c_smbus_read_word_data(client, 0x8c);
        }
    }
    i = linear_convert(LINEAR_11, value2, 0);

    mutex_unlock(&data->idd_lock);

    if ((value1 < 0)||(value2 < 0)) {
        TPS_DEBUG("I2C read error, value1: %d, value2: %d\n", value1, value2);
        return -1;
    }
#if 0
//  result=(float)vout*(float)iout;
//  return scnprintf(buf, PAGE_SIZE*2, "%.0f\n", result);
//  result=vout *iout;
#endif
    return scnprintf(buf, PAGE_SIZE*2, "%d\n", v * i);
}

static const i2c_dev_attr_st tps_attr_table[] = {
    {
        "in1_input",
        NULL,
        tps_vout_show,
        NULL,
        0x8b, 0, 8,
    },
    {
        "curr2_input",
        NULL,
        tps_iout_show,
        NULL,
        0x8c, 0, 8,
    },
    {
        "power2_input",
        NULL,
        tps_power_show,
        NULL,
        0x7d, 0, 8,
    },
};


/*
 * tps i2c addresses.
 */
static const unsigned short normal_i2c[] = {
    0x24, 0x25, I2C_CLIENT_END
};

/* tps_driver id */
static const struct i2c_device_id tps_id[] = {
    {"tps544b25", 0},
    { },
};
MODULE_DEVICE_TABLE(i2c, tps_id);

/* Return 0 if detection is successful, -ENODEV otherwise */
static int tps_detect(struct i2c_client *client,
                         struct i2c_board_info *info)
{
    /*
     * We don't currently do any detection of the driver
     */
    strscpy(info->type, "tps544b25", I2C_NAME_SIZE);
    return 0;
}

static int tps_probe(struct i2c_client *client)
{
    int n_attrs = sizeof(tps_attr_table) / sizeof(tps_attr_table[0]);
    struct device *dev = &client->dev;
    i2c_dev_data_st *data;

    data = devm_kzalloc(dev, sizeof(i2c_dev_data_st), GFP_KERNEL);
    if (!data) {
        return -ENOMEM;
    }

    return i2c_dev_sysfs_data_init(client, data, tps_attr_table, n_attrs);
}

static void tps_remove(struct i2c_client *client)
{
    i2c_dev_data_st *data = i2c_get_clientdata(client);
    i2c_dev_sysfs_data_clean(client, data);
}

static struct i2c_driver tps_driver = {
    .class    = I2C_CLASS_HWMON,
    .driver = {
        .name = "tps544b25",
    },
    .probe    = tps_probe,
    .remove   = tps_remove,
    .id_table = tps_id,
    .detect   = tps_detect,
    .address_list = normal_i2c,
};

static int __init tps_mod_init(void)
{
    return i2c_add_driver(&tps_driver);
}

static void __exit tps_mod_exit(void)
{
    i2c_del_driver(&tps_driver);
}

MODULE_AUTHOR("Mickey Zhan");
MODULE_DESCRIPTION("PSU Driver");
MODULE_LICENSE("GPL");

module_init(tps_mod_init);
module_exit(tps_mod_exit);

