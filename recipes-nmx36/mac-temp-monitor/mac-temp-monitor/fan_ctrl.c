#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <syslog.h>
#include "fan_default.h"
#include "fan_ctrl.h"

#define DEBUG   1

#ifdef DEBUG
#define DEBUG_PRINT(x...)           \
    do {                            \
        printf(x);              \
    } while(0)
#endif


extern board_s g_board;
extern sensor_s g_sensor[];
extern fan_s g_fan[];

void historyTempReset(int sensorId)
{
    g_sensor[sensorId].historyTemp[0] = TEMP_INIT_VAL;
    g_sensor[sensorId].historyTemp[1] = TEMP_INIT_VAL;
    g_sensor[sensorId].historyTemp[2] = TEMP_INIT_VAL;
}

void historyTempUpdate(int sensorId, int temp)
{
    g_sensor[sensorId].historyTemp[2] = g_sensor[sensorId].historyTemp[1];
    g_sensor[sensorId].historyTemp[1] = g_sensor[sensorId].historyTemp[0];
    g_sensor[sensorId].historyTemp[0] = temp;
}


int getTemp(int sensorId, int* temp)
{
    int ret = OK;
    ret = g_sensor[sensorId].getTemp(sensorId, temp);
    return ret;
}


bool getSensorPresent(int sensorId, int* present)
{
    int ret;
    ret = g_sensor[sensorId].getPresent(sensorId, present);
    return ret;
}


int getPwm(int fanId, int* pwm)
{
    int ret = OK;
    ret = g_fan[fanId].getPwm(fanId, pwm);
    return ret;
}


int setPwm(int fanId, int pwm)
{
    int ret = OK;
    ret = g_fan[fanId].setPwm(fanId, pwm);
    return ret;
}


int getFanPresent(int fanId, int* prensent)
{
    int ret = OK;
    ret = g_fan[fanId].getPresent(fanId, prensent);
    return ret;
}

int getFanSpeed(int fanId, int speedId, int* speed)
{
    int ret = OK;
    ret = g_fan[fanId].getSpeed(fanId, speedId, speed);
    return ret;
}

bool fanctrlStart()
{
    return g_board.fanCtrlStart();
}

void watchdogEnable()
{
    g_board.wdtEnable();
    return;
}

void setPwmToAllFan(int newPwm)
{
    int i;
    int ret;

    for (i = 0; i < g_board.fanNum; i++) {
        ret = setPwm(i, newPwm);
        if (ret) {
            //todo
        }
    }
    return;
}



int sensorHwmonInit(int sensorId)
{
    if (g_sensor[sensorId].path != NULL) {
        g_sensor[sensorId].hwmon = getDeviceHwmon(g_sensor[sensorId].path);
    }
    return OK;
}

int fanHwmonInit(int fanId)
{
    g_fan[fanId].hwmon = getDeviceHwmon(g_fan[fanId].path);
    return OK;
}


int boardInfoInit(){
    int i;
    if (g_board.fanCtrlStart == NULL) {
        g_board.fanCtrlStart = fanCtrlStartDefault;
    }
    if (g_board.wdtEnable == NULL) {
        g_board.wdtEnable = wdtEnableDefault;
    }
    syslog(LOG_INFO,"Sensor info:\n");
    for (i = 0; i < g_board.sensorNum; i++) {
        sensorHwmonInit(i);
        g_sensor[i].lastPwm = g_board.minPwm;
        historyTempReset(i);
        if (g_sensor[i].getTemp == NULL) {
            g_sensor[i].getTemp = getTempDefault;
        }
        if (g_sensor[i].getPresent == NULL) {
            g_sensor[i].getPresent = getSensorPresentDefault;
        }
        syslog(LOG_INFO,"name:%-15s P:%.1lf I:%.1lf D:%.1lf set point:%d major:%d fatal:%d hwmon:%d",
                g_sensor[i].sensorName, g_sensor[i].P, g_sensor[i].I, g_sensor[i].D,
                g_sensor[i].setPoint, g_sensor[i].major, g_sensor[i].fatal, g_sensor[i].hwmon);
    }
    syslog(LOG_INFO,"Fan info:\n");
    for (i = 0; i < g_board.fanNum; i++) {
        g_fan[i].hwmon = getDeviceHwmon(g_fan[i].path);
        if (g_fan[i].getPwm == NULL) {
            g_fan[i].getPwm = getPwmDefault;
        }
        if (g_fan[i].setPwm == NULL) {
            g_fan[i].setPwm = setPwmDefault;
        }
        if (g_fan[i].getPresent == NULL) {
            g_fan[i].getPresent = getPresentDefault;
        }
        if (g_fan[i].getSpeed == NULL) {
            g_fan[i].getSpeed = getFanSpeedDefault;
        }
        syslog(LOG_INFO,"name:%s hwmon:%d", g_fan[i].name, g_fan[i].hwmon);
    }
    return OK;
}


int checkFanUnpresentAlarm(int fanId)
{
    int ret;
    int prensent;

    ret = getFanPresent(fanId, &prensent);
    if (ret != OK) {
        syslog(LOG_CRIT,"get fan%d present status fail.\n", fanId);
        return FAN_UNPRESENT_ERR;
    }

    if (prensent == FAN_UNPRESENT) {
        syslog(LOG_CRIT,"fan%d is not present.present status:%d.\n", fanId, prensent);
        return FAN_UNPRESENT_ERR;
    } else {
        return OK;
    }
}
int checkFanPlugBySpeedId(int fanId,int speedId)
{
    int ret;
    int i;
    int speed;
    int maxSpeed;

    if (speedId == 0) {
        maxSpeed = g_fan[fanId].maxSpeed;
    }
    if (speedId == 1) {
        maxSpeed = g_fan[fanId].maxSpeed2;
    }
    ret = getFanSpeed(fanId, speedId, &speed);
    if (ret != OK) {
        syslog(LOG_CRIT,"Fan%d speed is ABNORMAL:get speed fail.\n", fanId);
        return FAN_PLUG_ERR;
    }

    if (speed <= (maxSpeed * 0.1)) {
        for (i = 0; i < TEMP_READ_RETRY_LIMIT; i++) {
            getFanSpeed(fanId, speedId, &speed);
            if (speed > (maxSpeed * 0.1)) {
                return OK;
            }
            syslog(LOG_CRIT,"Fan%d speed%d is ABNORMAL:less than 10 percent of max speed.speed:%d", fanId, speedId, speed);
            sleep(10);
        }
        if (i == TEMP_READ_RETRY_LIMIT) {
            syslog(LOG_CRIT,"[Fan ALARM]:fan%d speed%d is less than 10 percent of max speed for 30 seconeds.", fanId, speedId);
            return FAN_PLUG_ERR;
        }
    }
    return OK;
}


int checkFanPlugAlarm(int fanId)
{
    int ret = OK;

    ret |= checkFanPlugBySpeedId(fanId, 0);
    if (ret != OK) {
        return ret;
    }
    if (g_board.fanType == FAN_DOUBLE_ROTOR) {
        ret |= checkFanPlugBySpeedId(fanId, 1);
    }

    return ret;
}

int checkHugeDifferentAlarm(int fanId)
{
    int ret = OK;
    int i;
    int speed;
    int speed2;
    int speedHigh;

    if (g_board.fanType != FAN_DOUBLE_ROTOR) {
        return OK;
    }

    ret |= getFanSpeed(fanId, 0, &speed);
    ret |= getFanSpeed(fanId, 1, &speed2);
    if (ret != OK) {
        syslog(LOG_CRIT,"Fan%d speed is ABNORMAL:get speed fail.\n", fanId);
        return FAN_HUGE_DIFFERENT;
    }
    speed > speed2 ? speedHigh = speed : speedHigh = speed2;
    if (abs(speed - speed2) > (speedHigh * 0.3)) {
        for (i = 0; i < TEMP_READ_RETRY_LIMIT; i++) {
            getFanSpeed(fanId, 0, &speed);
            getFanSpeed(fanId, 1, &speed2);
            speed > speed2 ? speedHigh = speed : speedHigh = speed2;
            if (abs(speed - speed2) < (speedHigh * 0.3)) {
                return OK;
            }
            syslog(LOG_CRIT,"Fan%d speed is ABNORMAL:huge difference between speed_f:%d and speed_b:%d\n", fanId, speed, speed2);
            sleep(10);
        }
        if (i == TEMP_READ_RETRY_LIMIT) {
            syslog(LOG_CRIT,"[Fan ALARM]:Fan%d have huge difference between speed_f and speed_b for 30 seconds.\n", fanId);
            return FAN_HUGE_DIFFERENT;
        }

    }

    return OK;

}


int checkFanDirectionAlarm(int fanId)
{
    //todo
    return OK;
}

int checkFanAlarm(int fanId)
{
    int alarmFlag = OK;
    int alarmEvent = g_board.alarmEvent;
    if (!alarmFlag && (alarmEvent & FAN_UNPRESENT_ERR)) {
        alarmFlag = checkFanUnpresentAlarm(fanId);
    }
    if (!alarmFlag && (alarmEvent & FAN_PLUG_ERR)) {
        alarmFlag |= checkFanPlugAlarm(fanId);
    }
    if (!alarmFlag && (alarmEvent & FAN_HUGE_DIFFERENT)) {
        alarmFlag |= checkHugeDifferentAlarm(fanId);
    }
    return alarmFlag;
}


int checkSensorAlarm(int sensorId, int* tempValue)
{
    int i, retryTimes;
    int alarmFlag = OK;
    int temp;
    int lastTemp;
    int thresholdLow;
    int thresholdHigh;
    int alarmEvent = g_board.alarmEvent;
    //read temp
    getTemp(sensorId, &temp);
    //read err
    if (!alarmFlag && (alarmEvent & TEMP_READ_ERR)) {
        if (temp == TEMP_DATA_ERR) {
            syslog(LOG_CRIT,"sensor %d read ERR.\n", sensorId);
            for (retryTimes = 0; retryTimes < TEMP_READ_RETRY_LIMIT; retryTimes++) {
                getTemp(sensorId, &temp);
                if (temp != TEMP_DATA_ERR) {
                    break;
                }
                syslog(LOG_CRIT,"sensor%d read err for %d times.\n", sensorId, retryTimes);
                sleep(10);
            }
            if (retryTimes == TEMP_READ_RETRY_LIMIT) {
                alarmFlag = TEMP_READ_ERR;
            }
        }
    }
    //value valid
    if (!alarmFlag && (alarmEvent & TEMP_VALUE_VALID)) {
        if((temp < THERMAL_VALUE_LOW || temp > THERMAL_VALUE_HIGH)) {
            syslog(LOG_CRIT,"sensor %d temp is ABNORMAL. temp:%d.\n", sensorId, temp);
            for (retryTimes = 0; retryTimes < TEMP_READ_RETRY_LIMIT; retryTimes++) {
                getTemp(sensorId, &temp);
                if ((temp > THERMAL_VALUE_LOW) && (temp < THERMAL_VALUE_HIGH)) {
                    break;
                }
                syslog(LOG_CRIT,"sensor %d temp is ABNORMAL for %d times. temp:%d.\n", sensorId, retryTimes, temp);
                sleep(10);
            }
            if (retryTimes == TEMP_READ_RETRY_LIMIT) {
                alarmFlag = TEMP_VALUE_VALID;
            }
        }
    }
    //temp sudden change
    if (!alarmFlag && (alarmEvent & TEMP_SUDDEN_CHANGE)) {
        lastTemp = (g_sensor[sensorId].historyTemp[0] != THERMAL_INIT_VAL) ? g_sensor[sensorId].historyTemp[0] : temp;
        thresholdLow = lastTemp - TEMP_BURST_LIMIT;
        thresholdHigh = lastTemp + TEMP_BURST_LIMIT;
        if (temp < thresholdLow || temp > thresholdHigh) {
            syslog(LOG_CRIT,"sensor %d temp is ABNORMAL. temp:%d. last temp:%d threshold: %d - %d\n", sensorId, temp, lastTemp, thresholdLow, thresholdHigh);
            for (retryTimes = 0; retryTimes < TEMP_READ_RETRY_LIMIT; retryTimes++) {
                getTemp(sensorId, &temp);
                if (temp <= thresholdHigh && temp >= thresholdLow) {
                    break;
                }
                syslog(LOG_CRIT,"sensor %d temp is ABNORMAL for %d times. temp:%d. last temp:%d  threshold: %d - %d\n", sensorId, retryTimes, temp, lastTemp, thresholdLow, thresholdHigh);
                sleep(10);
            }
            if (retryTimes == TEMP_READ_RETRY_LIMIT) {
                alarmFlag = TEMP_SUDDEN_CHANGE;
            }
        }
    }
    //temp over major/fatal
    if (!alarmFlag) {
        if (alarmEvent & TEMP_OVER_FATAL) {
            if (temp >= g_sensor[sensorId].fatal) {
                alarmFlag |= TEMP_OVER_FATAL;
            }
        }
        if (alarmEvent & TEMP_OVER_MAJOR) {
            if (temp >= g_sensor[sensorId].major) {
                alarmFlag |= TEMP_OVER_MAJOR;
            }
        }
    }

    *tempValue = temp;
    return alarmFlag;
}


int checkBoardAlarm()
{
    int ret = OK;
    int i, present, temp;

    //sensor
    for (i = 0; i < g_board.sensorNum; i++) {
        getSensorPresent(i, &present);
        g_sensor[i].present = present;
        if (present == SENSOR_UNPRESENT) {
            printf("sensor%d is not present.\n",i);
            historyTempReset(i);
            continue;
        }

        g_sensor[i].alarmFlag = checkSensorAlarm(i, &temp);
        ret |= g_sensor[i].alarmFlag;

        if (g_sensor[i].alarmFlag) {
            syslog(LOG_CRIT,"sensor ID:%d alarmFlag:%d temp:%d\n", i, g_sensor[i].alarmFlag, temp);
            historyTempUpdate(i, TEMP_INIT_VAL);
        } else {
            historyTempUpdate(i, temp);
        }
    }

    //fan
    for (i = 0; i < g_board.fanNum; i++) {
        g_fan[i].alarmFlag = checkFanAlarm(i);
        if (g_fan[i].alarmFlag) {
            syslog(LOG_CRIT,"Fan%d alarm:%d.\n", i, g_fan[i].alarmFlag);
        }
        ret |= g_fan[i].alarmFlag;
    }

    return ret;
}


void checkPowerOffEvent()
{
    // N FAN UNPRESENT and 1-N sensor over fatal
    if (g_sensor[SW_TEMP_MAC_INDEX].alarmFlag & TEMP_OVER_FATAL){
        overFatalCnt++;
        syslog(LOG_CRIT,"SW_TEMP_MAC over fatal, count %d", overFatalCnt);
    } else {
        overFatalCnt = 0;
    }

    if (overFatalCnt >= 3) {
        syslog(LOG_CRIT,"SW_TEMP_MAC over fatal adn count over 3, device power cycle.");
        //MAC temp over fatal, power cycle.
        system("/usr/bin/power_util.sh machine cycle");
    }

    return;
}

void fanCtrlbyAlarm()
{
    int i;
    for (i = 0; i < g_board.fanNum; i++) {
        if (g_fan[i].alarmFlag & FAN_DIRECTION_ERR) {
            setPwm(i, g_board.minPwm);
            syslog(LOG_CRIT,"fan ctrl by alarm: set min pwd:%d to fan%d", g_board.minPwm, i);
        } else {
            setPwm(i, MAX_PWM);
            syslog(LOG_CRIT,"fan ctrl by alarm: set max pwd:%d to fan%d", MAX_PWM, i);
        }
    }
    return;
}



void fanCtrlByPid()
{
    int sensorId;
    int pwm, newPwm, fanPwm, lastPwm;
    int temp, lasttemp1, lasttemp2;
    float P, I, D;
    float Kp, Ki, Kd;
    int setPoint;
    int present;
    fanPwm = 0;
    newPwm = 0;
    //syslog(LOG_CRIT,"PID:");
    for (sensorId = 0; sensorId < g_board.sensorNum; sensorId++) {
        if (g_sensor[sensorId].present == SENSOR_UNPRESENT) {
            continue;
        }
        lastPwm = g_sensor[sensorId].lastPwm;
        setPoint = g_sensor[sensorId].setPoint;
        Kp = g_sensor[sensorId].P;
        Ki = g_sensor[sensorId].I;
        Kd = g_sensor[sensorId].D;
        temp = g_sensor[sensorId].historyTemp[0];
        lasttemp1 = (g_sensor[sensorId].historyTemp[1] != THERMAL_INIT_VAL) ? g_sensor[sensorId].historyTemp[1] : temp;
        lasttemp2 = (g_sensor[sensorId].historyTemp[2] != THERMAL_INIT_VAL) ? g_sensor[sensorId].historyTemp[2] : lasttemp1;
        lastPwm = (lastPwm > g_board.minPwm) ? lastPwm : g_board.minPwm;

        P = Kp * (temp - lasttemp1);
        I = Ki * (temp - setPoint);
        D = Kd * (temp - 2 * lasttemp1 + lasttemp2 );
        pwm = lastPwm + P + I + D + 0.5;//float型转int为向零舍入, +0.5做四舍五入
        pwm = (pwm > MAX_PWM) ? MAX_PWM : pwm;
        pwm = (pwm < g_board.minPwm) ? g_board.minPwm : pwm;

        g_sensor[sensorId].lastPwm = pwm;
        newPwm = (pwm > newPwm) ? pwm : newPwm;
        //syslog(LOG_CRIT,"sensor:%15s history:[%d, %d ,%d] P:%.1f I:%.1f D%.1f lastPwm:%d pwm:%d\n",
                    //g_sensor[sensorId].sensorName, temp, lasttemp1, lasttemp2, P, I, D, lastPwm, pwm);
    }
    getPwm(0, &fanPwm);
    if (newPwm != fanPwm) {
        syslog(LOG_CRIT,"setting pwm %d, old pwm %d.",newPwm, fanPwm);
        setPwmToAllFan(newPwm);
    }
    return;
}





void fanCtrlFunc()
{
    int alarmFlag;

    alarmFlag = checkBoardAlarm();

    checkPowerOffEvent();

    if (alarmFlag) {
        fanCtrlbyAlarm();
    } else {
        fanCtrlByPid();
    }

    return;
}





int main(int argc, char **argv)
{
    int ret = OK;
    syslog(LOG_CRIT,"fan ctrl start.\n");

    if(fanctrlStart() == false)
    {
        //log
        return OK;
    }

    boardInfoInit();


    //watchdogEnable();

    while(1) {
        //pingWatchdog();
        fanCtrlFunc();

        sleep(10);
    }

    //watchdogDisable(); watchdogEnable(disable);
    return OK;
}

