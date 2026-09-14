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
#include <filesystem>
#include <fstream>
#include <sys/mman.h>
#include <math.h>
#include "monitor_common.hpp"
#include "monitor_others.hpp"

/**
 * Macro definitions
 */
// Define mount point and script path for detection (adjust according to actual situation)
#define EMMC_MOUNT_POINT "/var/volatile/log"
#define RECOVERY_SCRIPT  "emmc_cycle.sh"
#define CMD_BUFFER_SIZE  256
#define TEMP_TEST_FILE   "/var/volatile/log/.emmc_rw_test"
// Static global variable: record execution count of eMMC recovery script (valid for entire program lifecycle)
static int emmc_retry_count = 0;
#define MAX_RETRY_TIMES  3   // Max retry 3 times


void monitor_check_emmc()
{

    FILE *fp = NULL;
    char cmd[CMD_BUFFER_SIZE] = {0};
    char mount_line[256] = {0};
    int is_readonly = 1;
    int ret = -1;

    snprintf(cmd, sizeof(cmd), "mount | grep '%s'", EMMC_MOUNT_POINT);
    fp = popen(cmd, "r");
    if (fp == NULL) {
        syslog(LOG_WARNING, "monitor_check_emmc: popen failed, errno=%d, msg=%s", errno, strerror(errno));
        goto check_by_write;
    }


    if (fgets(mount_line, sizeof(mount_line), fp) != NULL) {
        if (strstr(mount_line, "rw") != NULL) {
            is_readonly = 0;
            DEBUG_SYSLOG( "monitor_check_emmc: %s is rw (mount check)", EMMC_MOUNT_POINT);
        } else if (strstr(mount_line, "ro") != NULL) {
            is_readonly = 1;
        }
    }
    pclose(fp);
    fp = NULL;


check_by_write:
    if (!is_readonly) {
        int fd = open(TEMP_TEST_FILE, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd >= 0) {
            close(fd);
            unlink(TEMP_TEST_FILE);
            DEBUG_SYSLOG( "monitor_check_emmc: %s write test success (rw confirmed)", EMMC_MOUNT_POINT);
            return;
        } else {
            is_readonly = 1;
            syslog(LOG_WARNING, "monitor_check_emmc: %s mount says rw but write failed, errno=%d", EMMC_MOUNT_POINT, errno);
        }
    }

    if (is_readonly) {
                // Judge if max retry limit is reached
        if (emmc_retry_count >= MAX_RETRY_TIMES) {
            syslog(LOG_CRIT, "[eMMC] max retry %d times reached, stop recovery script", MAX_RETRY_TIMES);
            return;
        }

        DEBUG_SYSLOG( "monitor_check_emmc: %s confirm readonly, execute recovery script: %s", EMMC_MOUNT_POINT, RECOVERY_SCRIPT);
        ret = system(RECOVERY_SCRIPT);
        emmc_retry_count++;
        if (ret == -1) {
            syslog(LOG_ERR, "monitor_check_emmc: execute script failed, errno=%d, msg=%s", errno, strerror(errno));
        } else {
            int exit_code = WEXITSTATUS(ret);
            syslog(LOG_INFO, "monitor_check_emmc: script executed, exit code=%d", exit_code);
            syslog(LOG_CRIT, "[eMMC ALARM] monitor_check_emmc: %s is ro (mount check)", EMMC_MOUNT_POINT);
        }
        syslog(LOG_WARNING,"exec RECOVERY_SCRIPT");
    }

    return;
}

void* other_handling_thread(void *arg)
{
    while(1) {
        DEBUG_SYSLOG( 
                    "other_handling_thread");
        monitor_check_emmc();
        sleep(1);
    }
    return NULL;
}