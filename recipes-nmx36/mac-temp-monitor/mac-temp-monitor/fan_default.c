 /****************************************************************************
  * Copyright 2020 EDGE-CORE Corp.
  *
  * This program is free software; you can redistribute it and/or modify
  * it under the terms of the GNU General Public License as published by
  * the Free Software Foundation; either version 2 of the License, or
  * (at your option) any later version.
  *
  *  Description:
  *      This daemon is monitor fan & thermal sensor, then using fan policy
  *  and thermal policy to control fan speed or shutdown mainboard when
  *  temperature is too high.
  *
  *  First version: 2020/03/10
  *         Author: Michael Shih
  ******************************************************************************/

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include <map>
#include <string.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/watchdog.h>
#include <functional>
#include <iostream>
#include <iomanip>
#include <sstream>
#include "fan_default.h"
#include "fan_ctrl.h"


/* extern */
extern board_s g_board;
extern sensor_s g_sensor[];
extern fan_s g_fan[];


int getNodeVal(char* nodePath, int* value)
{
    int val;
    int ret;
    FILE *io = NULL;
    
    io = fopen(nodePath, "r");
    if ( !io ) {
        //debug
        printf("%s open fail\n", nodePath);
        return ERR;
    }
    ret = std::fscanf(io, "%d", &val);
    fclose(io);
    if ( ret > 0 ) {
        *value = val;
        return OK;
    }
    else {
        printf("%s read fail\n", nodePath);
        return ERR;
    }
}

int getNodeValHex(char* nodePath, int* value)
{
    int val;
    int ret;
    FILE *io = NULL;

    io = fopen(nodePath, "r");
    if ( !io ) {
        //debug
        printf("%s open fail\n", nodePath);
        return ERR;
    }
    ret = std::fscanf(io, "0x%x", &val);
    fclose(io);
    if ( ret > 0 ) {
        *value = val;
        return OK;
    }
    else {
        printf("%s read fail\n", nodePath);
        return ERR;
    }
}


int setNodeVal(char* nodePath, int value)
{
    int ret;
    FILE *io = NULL;
    
    io = fopen(nodePath, "w");
    if ( !io ) {
        //printf("\r\n debug:fopen fail %s\r\n", node_path);
        return ERR;
    }
    ret = fprintf(io, "%d\n", value);
    fclose(io);
    if ( ret > 0 ) {
        return OK;
    }
    else {
        return -2;
    }
}


int getDeviceHwmon(char* i2cDevPath)
{
    FILE *io = NULL;
    DIR  *dirPtr = NULL;
    struct dirent *dir = NULL;
    char path[128] = {0};
    int hwmIdx = 0;

    sprintf(path, "%s/hwmon", i2cDevPath);
    
    io = fopen(path, "r");
    if ( !io ) {
        return ERR;
    }

    dirPtr = opendir(path);
    if ( dirPtr ) {
        while ((dir = readdir(dirPtr)) != NULL) {
            if( strstr(dir->d_name, "hwmon") ) {
                sscanf(dir->d_name, "hwmon%d", &hwmIdx);
                closedir(dirPtr);
                fclose(io);
                return hwmIdx;
            }
        }
        closedir(dirPtr);
        fclose(io);
        return ERR;
    }
    closedir(dirPtr);
    fclose(io);
    return ERR;
}



/* default function */

bool fanCtrlStartDefault()
{
    return true;
}


void wdtEnableDefault()
{
    return;
}


int getSensorPresentDefault(int sensorId, int* present)
{
    *present = SENSOR_PRESENT;
    return OK;
}


int getTempDefault(int sensorId, int* temp)
{
    int value;
    int ret;
    char node[NODE_PATH_LEN] = {0};
    int i;
    
    sprintf(node, NODE_PATH_FMT, g_sensor[sensorId].hwmon, g_sensor[sensorId].node);
    for (i = 0; i < 3; i++){
        ret = getNodeVal(node, &value);
        if (ret == OK) {
            break;
        }
    }
    if (ret) {
        *temp = TEMP_DATA_ERR;
        return ERR;
    }
    *temp = value/1000;
    return OK;
}


int getPwmDefault(int fanId, int* pwm)
{
    int value;
    int ret;
    char node[NODE_PATH_LEN] = {0};
    int i;
    
    sprintf(node, NODE_PATH_FMT, g_fan[fanId].hwmon, g_fan[fanId].pwmNode);
    for (i = 0; i < 3; i++){
        ret = getNodeVal(node, &value);
        if (ret == OK) {
            break;
        }
    }
    if (ret) {
        return ERR;
    }
    *pwm = value;
    return OK;
}


int setPwmDefault(int fanId, int pwm)
{
    int ret;
    char node[NODE_PATH_LEN] = {0};
    
    sprintf(node, NODE_PATH_FMT, g_fan[fanId].hwmon, g_fan[fanId].pwmNode);
    ret = setNodeVal(node, pwm);
    if (ret) {
        return ERR;
    }
    return OK;
}

int getPresentDefault(int fanId, int* present)
{
    int value;
    int ret;
    char node[NODE_PATH_LEN] = {0};
    
    sprintf(node, NODE_PATH_FMT, g_fan[fanId].hwmon, g_fan[fanId].presentNode);
    ret = getNodeValHex(node, &value);
    if (ret) {
        return ERR;
    }
    *present = value;
    return OK;
}

int getDirectionDefault(int fanId, int* direction)
{
    int value;
    int ret;
    char node[NODE_PATH_LEN] = {0};
    
    sprintf(node, NODE_PATH_FMT, g_fan[fanId].hwmon, g_fan[fanId].directionNode);
    ret = getNodeVal(node, &value);
    if (ret) {
        return ERR;
    }
    *direction = value;
    return OK;
}

int getFanSpeedDefault(int fanId, int speedId, int* speed)
{
    int value;
    int ret;
    char node[NODE_PATH_LEN] = {0};

    if (speedId == 0) {
        sprintf(node, NODE_PATH_FMT, g_fan[fanId].hwmon, g_fan[fanId].speedNode);
    } else if (speedId == 1) {
        sprintf(node, NODE_PATH_FMT, g_fan[fanId].hwmon, g_fan[fanId].speedNode2);
    }
    
    ret = getNodeVal(node, &value);
    if (ret) {
        return ERR;
    }
    *speed = value;
    return OK;
}

