/*
 * psu_driver.c - The i2c driver to get following PSU information:
 *
 * PFE1100-12-054NA, PFE1500-12-054NAC, DDM1500BH12AXF
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
#include <linux/delay.h>
#include <linux/kernel.h>
#include "i2c_dev_sysfs.h"


#ifdef DEBUG
#define PSU_DEBUG(fmt, ...) do {                  \
  printk(KERN_DEBUG "%s:%d " fmt "\n",            \
         __FUNCTION__, __LINE__, ##__VA_ARGS__);  \
} while (0)

#else /* !DEBUG */

#define PSU_DEBUG(fmt, ...)
#endif

#define POW2(x) (1 << (x))

#define PSU_DELAY        15
#define PMBUS_MFR_MODEL  0x9a

typedef enum {
    LITEON_2200,
    DELTA_1600,
    DELTA_2000,
    GW_2000,
    GW_2700,
    APLUS_2700,
    UNKNOWN
} model_name;

#define LITERON_MODEL_LEN     14  /* PS-2162-15L### */
#define DELTA_MODEL_LEN       16  /* DPS-1600AB-35 A# */
#define DELTA_ES_MODEL_LEN    14  /* DPST-1630AB A# */
#define DELTA_CRPS_MODEL_LEN  13  /* DPST-2030AB D# */
#define GW_MODEL_LEN          14  /* GW-CRPS2000DWA# */
#define GW_MODEL_2700_LEN     13  /* CRPS2700T2W-A */
#define APLUS_MODEL_LEN       14  /* APLUSPOWER## */

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
	  //printk("data_y : 0x%04x data_n : 0x%04x value_x : 0x%04x \n",data_y, data_n, value_x);
    } else {
        if (n != 0) {
            value_x = (n < 0) ? (value * 1000) / POW2(abs(n))
                        : (value * 1000) * POW2(n);
        }
    }

    return value_x;
}

static int psu_convert(struct device *dev, struct device_attribute *attr)
{
    struct i2c_client *client = to_i2c_client(dev);
    i2c_dev_data_st *data = i2c_get_clientdata(client);
    i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
    const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
    int value = -1;
    int count = 10;
    int ret = -1;
    u8 length, model_chr;

    mutex_lock(&data->idd_lock);

    /*
     * If read block length byte > 32, it will cause kernel panic.
     * Using read word to replace read block to identifer PSU model.
     */
    ret = i2c_smbus_read_word_data(client, PMBUS_MFR_MODEL);
    length = ret & 0xff;
    if (ret < 0 || length > 32) {
        PSU_DEBUG("Failed to read Manufacturer Model\n");
    } else {
        while((value < 0 || value == 0xffff) && count--) {
            value = i2c_smbus_read_word_data(client, (dev_attr->ida_reg));
        }
    }

    mutex_unlock(&data->idd_lock);

    if (value < 0) {
        /* error case */
        PSU_DEBUG("I2C read error, value: %d\n", value);
        return -1;
    }

    model_chr = (ret >> 8) & 0xff;
    if (length == LITERON_MODEL_LEN && model_chr == 'P') {
        /* PSU model name: PS-2162-15L */
        model = LITEON_2200;
    } else if (length == DELTA_MODEL_LEN && model_chr == 'D') {
        /* PSU model name: DPS-1600AB- */
        model = DELTA_1600;
    } else if (length == DELTA_ES_MODEL_LEN && model_chr == 'D') {
        /* PSU model name: DPS-1600AB- */
        model = DELTA_1600;
    } else if (length == DELTA_CRPS_MODEL_LEN && model_chr == 'D') {
        /* PSU model name: DPST-2030AB D */
        model = DELTA_2000;
    } else if (length == GW_MODEL_LEN && model_chr == 'G') {
        /* PSU model name: GW-CRPS2000DWA */
        model = GW_2000;
    } else if (length == GW_MODEL_2700_LEN && model_chr == 'C') {
        /* PSU model name: CRPS2700T2W-A */
        model = GW_2700;
    } else if (length == APLUS_MODEL_LEN && model_chr == 'A') {
        /* PSU model name: APLUSPOWER */
        model = APLUS_2700;
    } else {
        model = UNKNOWN;
    }
    return value;
}

static int psu_ascii_convert(struct device *dev, struct device_attribute *attr, u8 *buf)
{
    struct i2c_client *client = to_i2c_client(dev);
    i2c_dev_data_st *data = i2c_get_clientdata(client);
    i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
    const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
    int value = -1;
    int count = 10;
    int ret = -1;
    u8 length, model_chr;

    mutex_lock(&data->idd_lock);

    /*
     * If read block length byte > 32, it will cause kernel panic.
     * Using read word to replace read block to identifer PSU model.
     */
    ret = i2c_smbus_read_word_data(client, PMBUS_MFR_MODEL);
    length = ret & 0xff;

    if (ret < 0 || length > 32) {
        PSU_DEBUG("Failed to read Manufacturer Model\n");
    } else {
        while((value < 0 || value == 0xffff) && count--) {
            //value = i2c_smbus_read_word_data(client, (dev_attr->ida_reg));
            value = i2c_smbus_read_block_data(client, (dev_attr->ida_reg), buf);
        }
    }

    mutex_unlock(&data->idd_lock);

    if (value < 0) {
        /* error case */
        PSU_DEBUG("I2C read error, value: %d\n", value);
        return -1;
    }

    //printk("psu_ascii_convert length : 0x%04x \n",length);
    model_chr = (ret >> 8) & 0xff;
    if (length == LITERON_MODEL_LEN && model_chr == 'P') {
        /* PSU model name: PS-2162-15L */
        model = LITEON_2200;
    } else if (length == DELTA_MODEL_LEN && model_chr == 'D') {
        /* PSU model name: DPS-1600AB-35-A */
        model = DELTA_1600;
    } else if (length == DELTA_ES_MODEL_LEN && model_chr == 'D') {
        /* PSU model name: DPS-1600AB- */
        model = DELTA_1600;
    } else if (length == DELTA_CRPS_MODEL_LEN && model_chr == 'D') {
        /* PSU model name: DPST-2030AB D */
        model = DELTA_2000;
    } else if (length == GW_MODEL_LEN && model_chr == 'G') {
        /* PSU model name: GW-CRPS2000DWA */
        model = GW_2000;
    } else if (length == GW_MODEL_2700_LEN && model_chr == 'C') {
        /* PSU model name: CRPS2700T2W-A */
        model = GW_2700;
    } else if (length == APLUS_MODEL_LEN && model_chr == 'A') {
        /* PSU model name: APLUSPOWER */
        model = APLUS_2700;
    } else {
        model = UNKNOWN;
    }

    return value;
}

static ssize_t psu_vin_show(struct device *dev,
                                struct device_attribute *attr,
                                char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0);
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_max_speed(struct device *dev,
                                struct device_attribute *attr,
                                char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    printk(KERN_DEBUG "result = 0x%04x \n", result);
    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0) / 1000;
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_min_speed(struct device *dev,
                                struct device_attribute *attr,
                                char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }
    printk("result = 0x%04x",result);
    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0) / 1000;
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t fan_command_rd(struct device *dev,
                                struct device_attribute *attr,
                                char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0);
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t fan_command_wr(struct device *dev,
                                    struct device_attribute *attr,
                                    const char *buf, size_t count)
{
    struct i2c_client *client = to_i2c_client(dev);
    i2c_dev_data_st *data = i2c_get_clientdata(client);
    i2c_sysfs_attr_st *i2c_attr = TO_I2C_SYSFS_ATTR(attr);
    const i2c_dev_attr_st *dev_attr = i2c_attr->isa_i2c_attr;
    int speed = 0;
    int ret;
    u8 length;

    if(sscanf(buf,"%i",&speed)<0){
  	    return -1;
    }

    if((speed > 100)||(speed < 0)){
  	    PSU_DEBUG("speed value err!\n");
  	    return -1;
    }

    PSU_DEBUG("get speed value %d !\n",speed);
    mutex_lock(&data->idd_lock);
    /*
     * If read block length byte > 32, it will cause kernel panic.
     * Using read word to replace read block to identifer PSU model.
     */
    ret = i2c_smbus_read_word_data(client, PMBUS_MFR_MODEL);
    length = ret & 0xff;

    if (ret < 0 || length > 32) {
      PSU_DEBUG("Failed to read Manufacturer Model\n");
	  mutex_unlock(&data->idd_lock);
	  return -1;
    }
    //printk("start write speed value 0x%04x !\n",speed);
    //data2.word = speed;
    //printk("start write speed data.word 0x%04x data2.byte =0x%02x !\n",data2.word,data2.byte);
    ret = i2c_smbus_write_word_data(client, dev_attr->ida_reg,speed);
    if (ret<0) {
        mutex_unlock(&data->idd_lock);
        PSU_DEBUG("write speed word err!\n");
        return ret;
    }

    mutex_unlock(&data->idd_lock);
    return count;
}

static ssize_t psu_iin_show(struct device *dev,
                                struct device_attribute *attr,
                                char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0);
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_vout_show(struct device *dev,
                                 struct device_attribute *attr,
                                 char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_16, result, -9);
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_iout_show(struct device *dev,
                                 struct device_attribute *attr,
                                 char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0);
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_temp_show(struct device *dev,
                                 struct device_attribute *attr,
                                 char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0);
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_fan_show(struct device *dev,
                                struct device_attribute *attr,
                                char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0) / 1000;
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_power_show(struct device *dev,
                                  struct device_attribute *attr,
                                  char *buf)
{
    int result = psu_convert(dev, attr);
    unsigned int power;

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            power = (unsigned int)linear_convert(LINEAR_11, result, 0) * 1000;
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%u\n", power);
}

static ssize_t psu_ascii_show(struct device *dev,
                                  struct device_attribute *attr,
                                  char *buf)
{
    u8 asc_buf[I2C_SMBUS_BLOCK_MAX + 1] = {0};
    int result = psu_ascii_convert(dev, attr , asc_buf);

    if (result < 0) {
      /* error case */
      return -1;
    }

    return scnprintf(buf, PAGE_SIZE, "%s\n", asc_buf);
}

static ssize_t psu_vstby_show(struct device *dev,
                                 struct device_attribute *attr,
                                 char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0);
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_istby_show(struct device *dev,
                                 struct device_attribute *attr,
                                 char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0);
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_pstby_show(struct device *dev,
                                  struct device_attribute *attr,
                                  char *buf)
{
    int result = psu_convert(dev, attr);

    if (result < 0) {
        /* error case */
        return -1;
    }

    switch (model) {
        case LITEON_2200:
        case DELTA_1600:
        case DELTA_2000:
        case GW_2000:
        case GW_2700:
        case APLUS_2700:
            result = linear_convert(LINEAR_11, result, 0);
            break;
        default:
            break;
    }

    return scnprintf(buf, PAGE_SIZE, "%d\n", result);
}

static ssize_t psu_input_type_show(struct device *dev,
                                struct device_attribute *attr,
                                char *buf)
{
    int result = psu_convert(dev, attr);
    int ac = 0, dc = 0;

    if (result < 0) {
        /* error case */
        return -1;
    }

    ac = result & 0x1;
    dc = result & 0x2;

    if (dc == 2 && ac == 0) {
        return scnprintf(buf, PAGE_SIZE, "DC\n");
    } else if (dc == 0 && ac == 1) {
        return scnprintf(buf, PAGE_SIZE, "AC\n");
    } else {
        return scnprintf(buf, PAGE_SIZE, "UNKNOW\n");
    }
}

static const i2c_dev_attr_st psu_attr_table[] = {
    {
        "psu_operation",
        NULL,
        I2C_DEV_ATTR_SHOW_DEFAULT,
        I2C_DEV_ATTR_STORE_DEFAULT,
        0x01, 0, 8,
    },
    {
        "psu_on_off_config",
        NULL,
        I2C_DEV_ATTR_SHOW_DEFAULT,
        I2C_DEV_ATTR_STORE_DEFAULT,
        0x02, 0, 8,
    },
    {
        "fan_command",
        NULL,
        fan_command_rd,
        fan_command_wr,
        0x3b, 0, 8,
    },
    {
        "in1_input",
        NULL,
        psu_vin_show,
        NULL,
        0x88, 0, 8,
    },
    {
        "curr1_input",
        NULL,
        psu_iin_show,
        NULL,
        0x89, 0, 8,
    },
    {
        "in2_input",
        NULL,
        psu_vout_show,
        NULL,
        0x8b, 0, 8,
    },
    {
        "curr2_input",
        NULL,
        psu_iout_show,
        NULL,
        0x8c, 0, 8,
    },
    {
        "temp1_input",
        NULL,
        psu_temp_show,
        NULL,
        0x8d, 0, 8,
    },
    {
        "temp2_input",
        NULL,
        psu_temp_show,
        NULL,
        0x8e, 0, 8,
    },
    {
        "temp3_input",
        NULL,
        psu_temp_show,
        NULL,
        0x8f, 0, 8,
    },
    {
        "fan1_input",
        NULL,
        psu_fan_show,
        NULL,
        0x90, 0, 8,
    },
    {
        "power2_input",
        NULL,
        psu_power_show,
        NULL,
        0x96, 0, 8,
    },
    {
        "power1_input",
        NULL,
        psu_power_show,
        NULL,
        0x97, 0, 8,
    },
    {
        "mfr_id",
        NULL,
        psu_ascii_show,
        NULL,
        0x99, 0, 8,
    },
    {
        "mfr_model",
        NULL,
        psu_ascii_show,
        NULL,
        0x9a, 0, 8,
    },
    {
        "mfr_revision",
        NULL,
        psu_ascii_show,
        NULL,
        0x9b, 0, 8,
    },
    {
        "mfr_location",
        NULL,
        psu_ascii_show,
        NULL,
        0x9c, 0, 8,
    },
    {
        "mfr_date",
        NULL,
        psu_ascii_show,
        NULL,
        0x9d, 0, 8,
    },
    {
        "mfr_serial",
        NULL,
        psu_ascii_show,
        NULL,
        0x9e, 0, 8,
    },
    {
        "max_fan",
        NULL,
        psu_max_speed,
        NULL,
        0xd0, 0, 8,
    },
    {
        "min_fan",
        NULL,
        psu_min_speed,
        NULL,
        0xd1, 0, 8,
    },
    {
        "fan_direction",
        NULL,
        I2C_DEV_ATTR_SHOW_DEFAULT,
        NULL,
        0xd2, 3, 2,
    },
    {
        "input_type",
        NULL,
        psu_input_type_show,
        NULL,
        0x80, 0, 8,
    },
};

/*
 * psu i2c addresses.
 */
static const unsigned short normal_i2c[] = {
    0x58, I2C_CLIENT_END
};

/* psu_driver id */
static const struct i2c_device_id psu_id[] = {
    {"psu_driver", 0},
    { },
};
MODULE_DEVICE_TABLE(i2c, psu_id);

/* Return 0 if detection is successful, -ENODEV otherwise */
static int psu_detect(struct i2c_client *client,
                         struct i2c_board_info *info)
{
    /*
     * We don't currently do any detection of the driver
     */
    strscpy(info->type, "psu_driver", I2C_NAME_SIZE);
    return 0;
}

static int psu_probe(struct i2c_client *client)
{
    int n_attrs = sizeof(psu_attr_table) / sizeof(psu_attr_table[0]);
    struct device *dev = &client->dev;
    i2c_dev_data_st *data;

    data = devm_kzalloc(dev, sizeof(i2c_dev_data_st), GFP_KERNEL);
    if (!data) {
        return -ENOMEM;
    }

    return i2c_dev_sysfs_data_init(client, data,
                                 psu_attr_table, n_attrs);
}

static void psu_remove(struct i2c_client *client)
{
    i2c_dev_data_st *data = i2c_get_clientdata(client);
    i2c_dev_sysfs_data_clean(client, data);
}

static struct i2c_driver psu_driver = {
    .class    = I2C_CLASS_HWMON,
    .driver = {
        .name = "psu_driver",
    },
    .probe    = psu_probe,
    .remove   = psu_remove,
    .id_table = psu_id,
    .detect   = psu_detect,
    .address_list = normal_i2c,
};

static int __init psu_mod_init(void)
{
    return i2c_add_driver(&psu_driver);
}

static void __exit psu_mod_exit(void)
{
    i2c_del_driver(&psu_driver);
}

MODULE_AUTHOR("Mickey Zhan");
MODULE_DESCRIPTION("PSU Driver");
MODULE_LICENSE("GPL");

module_init(psu_mod_init);
module_exit(psu_mod_exit);
