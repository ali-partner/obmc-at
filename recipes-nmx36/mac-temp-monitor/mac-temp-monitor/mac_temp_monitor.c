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
#include <syslog.h>
#define DEBUG   1

#ifdef DEBUG
#define DEBUG_PRINT(x...)           \
    do {                            \
        printf(x);              \
    } while(0)
#endif

#define OK 0
#define ERR -1
#define NMX36_DRIVER_OK_FLAG  "/run/driver_init_ok"
typedef struct sensor {
    int index;
    char* sensorName;
    char* path;
    char* node;
    int hwmon;
} sensor_s;

sensor_s g_sensor[] = {
    //mac temp in switch board
    {
        .index = 0,
        .sensorName = "mac_temp0",
        .path = "/sys/bus/i2c/devices/7-001f/",
        .node = "temp_input",
    },
};






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


int sensorHwmonInit(int sensorId)
{
    if (g_sensor[sensorId].path != NULL) {
        g_sensor[sensorId].hwmon = getDeviceHwmon(g_sensor[sensorId].path);
    }
    return OK;
}



#define NODE_PATH_FMT "%s/%s"
#define NODE_PATH_LEN 128
#define TEMP_DATA_ERR            (0-900000)
int getTempDefault(int sensorId, int* temp)
{
    int value;
    int ret;
    char node[NODE_PATH_LEN] = {0};
    int i;

    sprintf(node, NODE_PATH_FMT, g_sensor[sensorId].path, g_sensor[sensorId].node);
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
    *temp = value;
    return OK;
}



int getTemp(int sensorId, int* temp)
{
    int ret = OK;
    ret = getTempDefault(sensorId, temp);
    return ret;
}





int boardInfoInit(){
	syslog(LOG_INFO,"boardInfoInit.");
    int i;
    for (i = 0; i < 6; i++) {
        sensorHwmonInit(i);
		syslog(LOG_INFO,"sensor%d hwmon:%d",i,g_sensor[i].hwmon);
    }
    return OK;
}



int get_max_mac_temp()
{
	int i;
	int temp = 0;
	int max_temp = 0;
    int temps[6] = {0};
    //sensor
    for (i = 0; i < 6; i++) {
        getTemp(0, &temp);
		temps[i] = temp;
		max_temp = max_temp < temp? temp:max_temp;
    }
	syslog(LOG_INFO,"mac temp monitor:[%d,%d,%d,%d,%d,%d],max_temp:%d",temps[0],temps[1],temps[2],temps[3],temps[4],temps[5],max_temp);
	return max_temp;
}


int power_off_switch_board() {
    system("/usr/local/bin/power.sh sys_pwr_cycle");
	return OK;
	//todo
}

bool mac_monitor_start()
{
    int ret;
    int flag;
    char node[NODE_PATH_LEN] = {0};
    sprintf(node, "%s", NMX36_DRIVER_OK_FLAG);
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

int main()
{
	syslog(LOG_INFO,"mac temp monitor start.");
	int max_temp;
	int alarm_temp = 105;
    mac_monitor_start();
	//boardInfoInit();
	while (true) {
		max_temp = get_max_mac_temp();

		if (max_temp > alarm_temp) {
            syslog(LOG_INFO,"mac temp:%d > alarm temp:%d. Power off switch....\n",max_temp,alarm_temp);
			power_off_switch_board();
		}
		sleep(10);
	}
}


