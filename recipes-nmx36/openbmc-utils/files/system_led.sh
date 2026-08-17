usage(){
    echo "--system_led help"
    echo -e "Usage:\t$0 [get or set] [LED:diag,psu,fan] [LED state:0,1,2,3,4,5,6,7]"
    echo -e "\tIf you choose 'get', it will print all LED states. Eg:$0 get"
    echo -e "\tIf you choose 'set', it will set one LED states. Eg:$0 set [LED:diag,psu,fan] [LED state:0,1,2,3,4,5,6,7]"
    echo -e "\tled state:"
    echo -e "\t\t1: Green"
    echo -e "\t\t2: Green with twinkle(4Hz)"
    echo -e "\t\t3: Amber"
    echo -e "\t\t4: Amber with twinkle(4Hz)"
    echo -e "\t\t0,5,6,7: OFF"
}

led_state_get(){
    if [ $2 -eq 1 ]; then
        echo -e "LED $1 state:\tGreen"
    elif [ $2 -eq 2 ]; then
        echo -e "LED $1 state:\tGreen with twinkle(4Hz)"
    elif [ $2 -eq 3 ]; then
        echo -e "LED $1 state:\tAmber"
    elif [ $2 -eq 4 ]; then
        echo -e "LED $1 state:\tAmber with twinkle(4Hz)"
    else
        echo -e "LED $1 state:\tOFF"
    fi
}

led_state_set(){
    echo 1 > /sys/class/i2c-adapter/i2c-3/i2c-42/42-0062/LED_${1}_control
    echo $2 > /sys/class/i2c-adapter/i2c-3/i2c-42/42-0062/LED_${1}_state
    if [ $2 -eq 1 ]; then
        echo "Successfully set $1 LED to Green"
    elif [ $2 -eq 2 ]; then
        echo "Successfully set $1 LED to Green with twinkle(4Hz)"
    elif [ $2 -eq 3 ]; then
        echo "Successfully set $1 LED to Amber"
    elif [ $2 -eq 4 ]; then
        echo "Successfully set $1 LED to Amber with twinkle(4Hz)"
    else
        echo "Successfully set $1 LED to OFF"
    fi
}

if [ "$#" -ne 3 ] && [ "$#" -ne 2 ] && [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

if [ "$1" == "get" ]; then
    ret=$(i2cget -f -y 42 0x62 0xA2)
    state=$((ret&0x07))
    led_state_get diag $state
    ret=$(i2cget -f -y 42 0x62 0xA3)
    state=$((ret&0x07))
    led_state_get psu $state
    ret=$(i2cget -f -y 42 0x62 0xA1)
    state=$((ret&0x07))
    led_state_get fan $state
fi

if [ "$1" == "set" ]; then
    if [ -z $3 ]; then
        usage
        exit 1
    fi
    led_state_set $2 $3
fi
