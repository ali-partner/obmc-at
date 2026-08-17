#!/bin/bash

echo "
    User commands:
        boot_util.sh           --Show and set the BMC or BIOS boot sequence
        fruid_util             --Show and modify the fru content
        power_util.sh          --Show and control platform power
        sol.sh                 --Switch BMC uart to host CPU uart    
        led_util.sh            --Show location led status
        ipmitool raw 0x36 [80|81|82]
                               --80 indicates the I2C channel switchover status 
                                 If 0 is returned, the I2C channel is in host
                                 If 1 is returned, the I2C channel is in BMC
                                 If ff is returned, the I2C channel is failed 
                               --81 The I2C channel is switched to host
                                 If 0 is returned, the I2C channel fails to switch to host
                                 If 1 is returned, the I2C channel successfully to switch to host
                               --82 The I2C channel is switched to BMC   
                                 If 0 is returned, the I2C channel fails to switch to BMC
                                 If 1 is returned, the I2C channel successfully to switch to BMC
     "