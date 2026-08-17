#!/bin/sh

. /usr/local/bin/openbmc-utils.sh

# Disable the dual boot watch dog
echo "Disable the boot watch dog 1"
devmem_clear_bit 0x14c3728c 0
echo "Disable the boot watch dog 2"
devmem_clear_bit 0x14c372a0 0
#echo "Disable the boot watch dog 3"
#devmem_clear_bit 0x1e78504c 0