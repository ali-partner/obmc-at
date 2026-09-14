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

int monitor_com_get_node_val_i(char* node_path, int* value)
{
    int val;
    int ret;
    FILE *io = NULL;

    io = fopen(node_path, "r");
    if ( !io ) {
        //printf("\r\n debug:fopen fail %s\r\n", node_path);
        return ERR;
    }
    ret = std::fscanf(io, "%d", &val);
    fclose(io);
    if ( ret > 0 ) {
        *value = val;
        return OK;
    }
    else {
        return ERR;
    }
}