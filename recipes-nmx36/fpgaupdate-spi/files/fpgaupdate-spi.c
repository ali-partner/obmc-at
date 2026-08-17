/*
 * cpldupdate-i2c.c - Update Lattice CPLD through I2c
 *
 * Copyright 2018-present Facebook. All Rights Reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/stat.h>


#define DEBUG
#define DATA_LENGTH 256
#define DATA_MAX_BYTES 256
//#define DATA_MAX_BYTES 16384

typedef enum {
    CS      = 644,  /* AST2700 GPIOP0 */
    CLK     = 645,  /* AST2700 GPIOP1 */
    MOSI    = 646,  /* AST2700 GPIOP2 */
    MISO    = 647   /* AST2700 GPIOP3 */
} spi_bit_bang;

#ifdef DEBUG
#define FPGA_BEBUG(fmt, args...) printf(fmt, ##args);
#else
#define FPGA_BEBUG(fmt, args...)
#endif

#define ERR_PRINT(fmt, args...) \
        fprintf(stderr, fmt ": %s\n", ##args, strerror(errno));


static int
program_fpga_flash(const char *file_path) {
  int fd = -1;
  uint64_t i = 0;
  struct stat st;
  uint64_t file_len= 0;
  int j = 0, k = 0, cnt = 0, byte_index = 0, add_step = 0;
  char *wr_data;
  char *data_str;
  char *cmd_str;
  char *cmd_str_1;
  int ret;

  fd = open(file_path, O_RDONLY, 0666);
  if (fd < 0) {
    FPGA_BEBUG("The function open failed.");
    return -1;
  }

  stat(file_path, &st);
  file_len = st.st_size;

  //uint8_t file_buf[file_len];
  char *file_buf;
  file_buf = (char *) malloc(file_len);
  if (!file_buf) {
    FPGA_BEBUG("The file_buf malloc error.");
    return ENOMEM;
  }
  memset(file_buf,0,file_len);

  if (read(fd, file_buf, file_len) < 0) {
    FPGA_BEBUG("The function read failed.");
    return -1;
  }
  wr_data = (char *) malloc(16);
  if (!wr_data) {
    FPGA_BEBUG("The wr_data malloc error.");
    return ENOMEM;
  }
  memset(wr_data,0,16);
  data_str = (char *) malloc(6*DATA_MAX_BYTES);
  if (!data_str) {
    FPGA_BEBUG("The data_str malloc error.");
	free(wr_data);
    return ENOMEM;
  }
  memset(data_str,0,6*DATA_MAX_BYTES);
  
  cmd_str = (char *) malloc(6*DATA_MAX_BYTES);
  if (!cmd_str) {
    FPGA_BEBUG("The cmd_str malloc error.");
	free(data_str);
	free(wr_data);
    return ENOMEM;
  }
  memset(cmd_str,0,6*DATA_MAX_BYTES);
  
  cmd_str_1 = (char *) malloc(DATA_LENGTH);
  if (!cmd_str_1) {
    FPGA_BEBUG("The cmd_str_1 malloc error.");
	free(cmd_str_1);
	free(data_str);
	free(wr_data);
    return ENOMEM;
  }
  memset(cmd_str_1,0,DATA_LENGTH);
  printf("\nTo program FPGA flash start SPI write (%lu)...\n",file_len);

  for (i = 0; i < file_len; i++) {
    byte_index = i%DATA_MAX_BYTES;
	snprintf(wr_data, 6, "0x%02x ", file_buf[i]);
    strcat(data_str, wr_data);
    //printf("wr_data2[%d]= %s;\n",byte_index,wr_data);
    memset(wr_data,0,16);
    if((byte_index == (DATA_MAX_BYTES - 1)) || (i == file_len -1)) {
		//printf("wr_data:\n%s\n",data_str);
		snprintf(cmd_str_1, DATA_LENGTH, "spi-bb -s %d -S low -c %d -C low -o %d -O rising -i %d -I falling -w 8 0x%x ", CS, CLK, MOSI, MISO, 06);
		ret = system(cmd_str_1);
        if (ret != 0) {
            printf("cmd_str_1 cammand:\n%s\n",cmd_str_1);
        }
        //printf("cmd_str_1 cammand:\n%s\n",cmd_str_1);
        memset(cmd_str_1,0,DATA_LENGTH);
        
		//write command(1Byte)+ Address(3Byte) + write data
		cnt = ((byte_index + 1) + 1 + 3) * 8;
		snprintf(cmd_str_1, DATA_LENGTH, "spi-bb -s %d -S low -c %d -C low -o %d -O rising -i %d -I falling -w %d 0x02 %d %d 00 ", CS, CLK, MOSI, MISO, cnt, k, j);
		snprintf(cmd_str, 6*DATA_MAX_BYTES, "%s %s", cmd_str_1,data_str);
        add_step = DATA_MAX_BYTES / 256;
		j = j + add_step;
		if( j == 256 ){
			j = 0;
			k = k + 1;
		}
		//printf("The (%lld) (data_str:%d)(cmd_str:%d) cammand:\n%s\n",i,strlen(data_str),strlen(cmd_str),cmd_str);
		ret = system(cmd_str);
        if (ret != 0) {
            printf("cmd_str cammand:\n%s\n",cmd_str);
        }
        memset(data_str,0,6*DATA_MAX_BYTES);
        memset(cmd_str_1,0,DATA_LENGTH);
        memset(cmd_str,0,6*DATA_MAX_BYTES);
	}
  }
  free(wr_data);
  free(data_str);
  free(cmd_str_1);
  free(cmd_str);
  printf("...Done!\n");
  return 0;
}

static void
print_usage(const char *name) {
  printf("Usage: %s <file_path>\n", name);  
}

int
main(int argc, const char *argv[]) {

  int pid_file = 0;
  int ret;

  if(argc != 2){
    print_usage(argv[0]);
	exit(EXIT_FAILURE);
  }
  
  pid_file = open("/var/run/fpgaupdate-spi.pid", O_CREAT | O_RDWR, 0666);
  if(flock(pid_file, LOCK_EX | LOCK_NB) && (errno == EWOULDBLOCK)) {
    printf("Another fpgaupdate-spi instance is running...\n");
    exit(EXIT_FAILURE);
  }

  ret = program_fpga_flash(argv[1]);
  if (ret) {
    ERR_PRINT("Program FPGA flash failed.");
    return -1;  	
  }
  
  return 0;
}
