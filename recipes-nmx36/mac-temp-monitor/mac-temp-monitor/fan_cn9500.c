
#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <unistd.h>
#include "fan_ctrl.h"
#include "fan_default.h"


#define FUNC_FOR_CN9500
#ifdef FUNC_FOR_CN9500

#define TH5_UP_FAN_PATH     "/sys/bus/i2c/devices/159-0050"
#define TH5_LOW_FAN_PATH    "/sys/bus/i2c/devices/143-0050"
#define TH5_DRIVER_OK_FLAG  "/run/driver_init_ok"
#define FAN_MAX_SPEED_F 16100
#define FAN_MAX_SPEED_B 18400
int getLswTemp(int sensorId, int* temp);
int getTempBase1(int sensorId, int* temp);
int getQsfpPresent(int sensorId, int* present);
bool cn9500FanCtrlStart();
#endif


board_s g_board = {
    .name = "CN9500",
    .sensorNum = 5,
    .fanNum = 8,
    .fanType = FAN_DOUBLE_ROTOR,
    .minPwm = 50,
    .alarmEvent = TEMP_SUDDEN_CHANGE | TEMP_READ_ERR | TEMP_VALUE_VALID | TEMP_OVER_FATAL | TEMP_OVER_MAJOR | FAN_UNPRESENT_ERR | FAN_PLUG_ERR | FAN_HUGE_DIFFERENT,
    .fanCtrlStart = cn9500FanCtrlStart,
};


sensor_s g_sensor[] = {
    //lm75 in main board
    {
        .index = CB_TEMP_INLET_INDEX,
        .sensorName = "CB_TEMP_INLET",
        .path = "/sys/bus/i2c/drivers/lm75/112-004a/",
        .node = "temp1_input",
        .setPoint = 41,
        .P = 4,
        .I = 0.4,
        .D = 0.3,
        .major = 50,
        .fatal = 60,
    },
    {
        .index = SW_TEMP_INLET1_INDEX,
        .sensorName = "SW_TEMP_INLET1",
        .path = "/sys/bus/i2c/drivers/lm75/135-0048/",
        .node = "temp1_input",
        .setPoint = 41,
        .P = 4,
        .I = 0.4,
        .D = 0.3,
        .major = 52,
        .fatal = 62,
    },
    {
        .index = SW_TEMP_MAC_INDEX,
        .sensorName = "SW_TEMP_MAC",
        .path = "/sys/bus/i2c/devices/1-0004/",
        .node = "temp1_input",
        .setPoint = 85,
        .P = 4,
        .I = 0.4,
        .D = 0.3,
        .major = 100,
        .fatal = 105,
    },
    {
        .index = X86_TEMP_INDEX,
        .sensorName = "X86_TEMP",
        .path = "/sys/bus/platform/drivers/peci_cputemp/peci-cputemp.0",
        .node = "temp1_input",
        .setPoint = 81,
        .P = 4,
        .I = 0.4,
        .D = 0.3,
        .major = 93,
        .fatal = 99,
        //.getTemp = getTempBase1,
    },
    {
        .index = QSFP_MAX_INDEX,
        .sensorName = "QSFP_MAX",
        .path = "/sys/bus/i2c/devices/1-0003/",
        .node = "temp1_input",
        .setPoint = 62,
        .P = 4,
        .I = 0.4,
        .D = 0.3,
        .major = 70,
        .fatal = 75,
        .getTemp = getTempBase1,
        .getPresent = getQsfpPresent,
    },

};


fan_s g_fan[] = {
    {
        .name = "fan1",
        .maxSpeed = FAN_MAX_SPEED_F,
        .maxSpeed2 = FAN_MAX_SPEED_B,
        .path = TH5_UP_FAN_PATH,
        .pwmNode = "pwm_1",
        .presentNode = "fan1_presence",
        .speedNode = "fan1_input",
        .speedNode2 = "fan2_input",
    },
    {
        .name = "fan2",
        .maxSpeed = FAN_MAX_SPEED_F,
        .maxSpeed2 = FAN_MAX_SPEED_B,
        .path = TH5_LOW_FAN_PATH,
        .pwmNode = "pwm_1",
        .presentNode = "fan1_presence",
        .speedNode = "fan1_input",
        .speedNode2 = "fan2_input",
    },
    {
        .name = "fan3",
        .maxSpeed = FAN_MAX_SPEED_F,
        .maxSpeed2 = FAN_MAX_SPEED_B,
        .path = TH5_UP_FAN_PATH,
        .pwmNode = "pwm_2",
        .presentNode = "fan2_presence",
        .speedNode = "fan3_input",
        .speedNode2 = "fan4_input",
    },
    {
        .name = "fan4",
        .maxSpeed = FAN_MAX_SPEED_F,
        .maxSpeed2 = FAN_MAX_SPEED_B,
        .path = TH5_LOW_FAN_PATH,
        .pwmNode = "pwm_2",
        .presentNode = "fan2_presence",
        .speedNode = "fan3_input",
        .speedNode2 = "fan4_input",
    },
    {
        .name = "fan5",
        .maxSpeed = FAN_MAX_SPEED_F,
        .maxSpeed2 = FAN_MAX_SPEED_B,
        .path = TH5_UP_FAN_PATH,
        .pwmNode = "pwm_3",
        .presentNode = "fan3_presence",
        .speedNode = "fan5_input",
        .speedNode2 = "fan6_input",
    },
    {
        .name = "fan6",
        .maxSpeed = FAN_MAX_SPEED_F,
        .maxSpeed2 = FAN_MAX_SPEED_B,
        .path = TH5_LOW_FAN_PATH,
        .pwmNode = "pwm_3",
        .presentNode = "fan3_presence",
        .speedNode = "fan5_input",
        .speedNode2 = "fan6_input",
    },
    {
        .name = "fan7",
        .maxSpeed = FAN_MAX_SPEED_F,
        .maxSpeed2 = FAN_MAX_SPEED_B,
        .path = TH5_UP_FAN_PATH,
        .pwmNode = "pwm_4",
        .presentNode = "fan4_presence",
        .speedNode = "fan7_input",
        .speedNode2 = "fan8_input",
    },
    {
        .name = "fan8",
        .maxSpeed = FAN_MAX_SPEED_F,
        .maxSpeed2 = FAN_MAX_SPEED_B,
        .path = TH5_LOW_FAN_PATH,
        .pwmNode = "pwm_4",
        .presentNode = "fan4_presence",
        .speedNode = "fan7_input",
        .speedNode2 = "fan8_input",
    },
};

int getLswTemp(int sensorId, int* temp)
{
    int value;
    int ret;
    char node[NODE_PATH_LEN] = {0};

    sprintf(node, NODE_PATH_FMT, g_sensor[sensorId].hwmon, g_sensor[sensorId].node);
    ret = getNodeVal(node, &value);
    if (ret) {
        *temp = TEMP_DATA_ERR;
        return ERR;
    }
    //LSW-Tj=1.2*Ttmp75-i2c-141-4b+10

    *temp = (value * 1200) / 1000 / 1000 + 10;
    return OK;
}

int getTempBase1(int sensorId, int* temp)
{
    int value;
    int ret;
    char node[NODE_PATH_LEN] = {0};

    sprintf(node, NODE_PATH_FMT, g_sensor[sensorId].hwmon, g_sensor[sensorId].node);
    ret = getNodeVal(node, &value);
    if (ret) {
        *temp = TEMP_DATA_ERR;
        return ERR;
    }
    *temp = value / 1000;
    return OK;
}

int getQsfpPresent(int sensorId, int* present)
{
    int presntSta;
    int ret;
    char node[NODE_PATH_LEN] = {0};

    sprintf(node, NODE_PATH_FMT, g_sensor[sensorId].hwmon, "qsfp_present");
    ret = getNodeVal(node, &presntSta);
    if (ret) {
        return ERR;
    }
    if (presntSta == 1) {
        *present = SENSOR_PRESENT;
        return OK;
    } else if (presntSta == 0) {
        *present = SENSOR_UNPRESENT;
        return OK;
    } else {
        return ERR;
    }
}

bool cn9500FanCtrlStart()
{
    int ret;
    int flag;
    char node[NODE_PATH_LEN] = {0};
    sprintf(node, "%s", TH5_DRIVER_OK_FLAG);
    while(1) {
        sleep(5);
        ret = getNodeVal(node, &flag);
        if (ret) {
            syslog(LOG_INFO,"wait for driver init ok.\n");
            continue;
        }
        if (flag != 1) {
            syslog(LOG_INFO,"wait for driver init ok.\n");
            continue;
        }else {
            break;
        }
    }
    syslog(LOG_INFO,"driver init ok.fan ctrl start.\n");
    return true;
}

