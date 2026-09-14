#ifndef _MONITOR_COMMON_
#define _MONITOR_COMMON_
#include <pthread.h>

#define OK 0
#define ERR -1
#define SENSOR_DRIVER_INIT_OK   1
#define SENSOR_DRIVER_INIT_ERR  0

#define DEBUG_SYSLOG_ENABLE  0
#if DEBUG_SYSLOG_ENABLE
    #define DEBUG_SYSLOG(fmt, ...)  syslog(LOG_WARNING, fmt, ##__VA_ARGS__)
#else
    #define DEBUG_SYSLOG(fmt, ...)  do {} while(0)
#endif

extern int debug_print_flag;
#define DEBUG_FILE_FLAG    "/run/monitor.debug"
#define DEBUG_PRINT(x...)           \
    do {                            \
        if(debug_print_flag) {      \
            syslog(LOG_WARNING, x); \
        }                           \
    } while(0)


int monitor_com_get_node_val_i(char* node_path, int* value);

#endif