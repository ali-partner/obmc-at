#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <syslog.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>
#include <pthread.h>
#include <sys/mman.h>
#include <math.h>
#include "monitor_common.hpp"
#include "monitor_others.hpp"

int main(int argc, char **argv)
{
    int value = 0;
    int wait_time = 0;
    int s;
    sigset_t set;
    pthread_t other_thread;
    syslog(LOG_INFO,"NMX36 monitor init....");

    while (wait_time < 120) {
        monitor_com_get_node_val_i("/run/driver_init_ok", &value);
        if (value == SENSOR_DRIVER_INIT_OK) {
            syslog(LOG_WARNING,"i2c driver init success!");
            break;
        }
        wait_time++;
        syslog(LOG_WARNING,"Wait for i2c driver init.... wait count:%d", wait_time);
        sleep(5);
    }

    // signal(SIGTERM, sig_handler);
    // signal(SIGINT, sig_handler);

    sigemptyset(&set);
    sigaddset(&set, SIGTERM);

    s = pthread_sigmask(SIG_BLOCK, &set, NULL);

    s = pthread_create(&other_thread, NULL, &other_handling_thread, NULL);
    if(s != 0)
    {
        perror("create other handing thread failed\r\n");
        return ERR;
    }

    pthread_join(other_thread, NULL);

    return 0;
}