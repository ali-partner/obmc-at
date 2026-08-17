# Copyright 2018-present Facebook. All Rights Reserved.

CFLAGS += -Wall -Werror

all: fpgaupdate-spi

cpldupdate-i2c: fpgaupdate-spi.o
	$(CC) $(CFLAGS) -std=gnu99 -o $@ $^ $(LDFLAGS)

.PHONY: clean

clean:
	rm -rf *.o fpgaupdate-spi
