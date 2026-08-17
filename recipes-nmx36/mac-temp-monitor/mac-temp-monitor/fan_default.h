#ifndef _FAN_DEFAULT_HEADER_
#define _FAN_DEFAULT_HEADER_

#define OK 0
#define ERR -1
#define FAN_PRESENT 0
#define FAN_UNPRESENT 1
#define SENSOR_PRESENT 0
#define SENSOR_UNPRESENT 1
#define NODE_PATH_LEN 128
#define NODE_PATH_FMT "/sys/class/hwmon/hwmon%d/%s"
#define TEMP_INIT_VAL            (0-1000000)
#define TEMP_DATA_ERR            (0-900000)
#define MAX_PWM 100

#define TEMP_READ_RETRY_LIMIT    3
#define THERMAL_VALUE_HIGH          125
#define THERMAL_VALUE_LOW           -30
#define TEMP_BURST_LIMIT         10
//fan type
#define FAN_SINGLE_ROTOR 1
#define FAN_DOUBLE_ROTOR 2

#define BIT(x) (1 << x)
#define TEMP_OVER_MAJOR BIT(0)
#define TEMP_OVER_FATAL BIT(1)
#define TEMP_READ_ERR   BIT(2)
#define TEMP_VALUE_VALID BIT(3)
#define TEMP_SUDDEN_CHANGE BIT(4)
#define FAN_UNPRESENT_ERR BIT(8)
#define FAN_PLUG_ERR    BIT(9)
#define FAN_HUGE_DIFFERENT BIT(10)
#define FAN_DIRECTION_ERR BIT(11)
    
int getDeviceHwmon(char* i2cDevPath);
int getNodeVal(char* nodePath, int* value);
/* default function */
bool fanCtrlStartDefault();
void wdtEnableDefault();
int getSensorPresentDefault(int sensorId, int* present);
int getTempDefault(int sensorId, int* temp);
int getPwmDefault(int fanId, int* pwm);
int setPwmDefault(int fanId, int pwm);
int getPresentDefault(int fanId, int* present);
int getDirectionDefault(int fanId, int* direction);
int getFanSpeedDefault(int fanId, int speedId, int* speed);
#endif
