#ifndef _FAN_CTRL_HEADER_
#define _FAN_CTRL_HEADER_

#define THERMAL_INIT_VAL            (0-1000000)

static int overFatalCnt = 0;


enum TEMP_INDEX
{
    CB_TEMP_INLET_INDEX            = 0,
    SW_TEMP_INLET1_INDEX           = 1,
    SW_TEMP_MAC_INDEX              = 2,
    X86_TEMP_INDEX                 = 3,
    QSFP_MAX_INDEX                 = 4
};

typedef struct node {
    char* nodeName;
    char* path;
    int hwmon;
} node_s;


typedef struct board {
    char* name;
    int sensorNum;
    int fanNum;
    int fanType;
    int minPwm;
    int alarmEvent;
    bool (*fanCtrlStart)(void);
    void (*wdtEnable)(void);
} board_s;


typedef struct sensor {
    int index;
    char* sensorName;
    char* path;
    char* node;
    int hwmon;
    int setPoint;
    float P;
    float I;
    float D;
    int major;
    int fatal;
    int alarmFlag;
    int historyTemp[3];
    int lastPwm;
    int present;
    int (*getTemp)(int sensorId, int* temp);
    int (*getPresent)(int sensorId, int* present);
} sensor_s;



typedef struct fan {
    int fanId;
    char* name;
    int maxSpeed;
    int maxSpeed2;
    char* path;
    char* pwmNode;
    char* presentNode;
    char* directionNode;
    char* speedNode;
    char* speedNode2;
    int alarmFlag;
    int hwmon;
    int (*getPwm)(int fanId, int* pwm);
    int (*setPwm)(int fanId, int pwm);
    int (*getPresent)(int fanId, int* present);
    int (*getSpeed)(int fanId, int speedId, int* speed);
} fan_s;
#endif

