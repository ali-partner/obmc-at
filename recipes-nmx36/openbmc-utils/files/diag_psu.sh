#!/bin/bash


SYSFS_I2C_DEVICES="/sys/bus/i2c/devices"
BASECPLD_PATH="${SYSFS_I2C_DEVICES}/0-000d"
PSU_PIN=(0 0 0 0)
PSU_POUT=(0 0 0 0)


usage() {
    echo "Usage: $0 [status|info|fan]"
    echo
}

psu_status(){
    echo "Judge PSU status: "

    psu="1 2 3 4"
    bitval=(1 2 4 8)
    alarmval=`i2cget -f -y 0 0xd 0x44`
    psonval=`i2cget -f -y 0 0xd 0x43`
    for i in ${psu}
    do
        alive=`cat ${BASECPLD_PATH}/psu${i}_present | sed -n 1p`
        if [ "$alive" == "0x0" ]; then
            echo "PSU${i}: alive"
            psu_pwrok $i
            psu_pg $i
            psu_alarm $alarmval ${bitval[i-1]} $i
            psu_pson $psonval ${bitval[i-1]} $i
        else
            echo "PSU${i}: bad"
        fi
        sleep 0.1
        echo
    done
}

psu_pwrok(){
    alive=`cat ${BASECPLD_PATH}/psu${1}_output_ok | sed -n 1p`
    if [ "$alive" == "0x0" ]; then
        echo "PSU${1} output status: abnormal"
    else
        echo "PSU${1} output status: normal"
    fi
}

psu_pg(){
    alive=`cat ${BASECPLD_PATH}/psu${1}_vin_pg | sed -n 1p`
    if [ "$alive" == "0x0" ]; then
        echo "PSU${1} vin status: abnormal"
    else
        echo "PSU${1} vin status: normal"
    fi
}

psu_alarm(){
    alarm=$(($1 & ${2}))
    if [ "$alarm" == "${2}" ]; then
        echo "PSU${3} SMB ALART alarm signal: normal"
    else
        echo "PSU${3} SMB ALART alarm signal: abnormal"
    fi
}

psu_pson(){
    pson=$(($1 & ${2}))
    if [ "$pson" == "${2}" ]; then
        echo "PSU${3} output control: abnormal"
    else
        echo "PSU${3} output control: normal"
    fi
}

psu_info(){
    bus=(75 74 73 72)
    has_error=0
    total_pin=0
    total_pout=0

    for((i=1; i<=4; i++))
    do
        alive=`cat ${BASECPLD_PATH}/psu${i}_present | sed -n 1p`
        if [ "$alive" == "0x0" ]; then
            echo "PSU${i} Information"
            psu_alive_info ${bus[i-1]} 58 PSU${i}
            if [ $? -ne 0 ]; then
                has_error=-1
            fi

            total_pin=`echo "${total_pin} ${PSU_PIN[i-1]}" | awk '{printf("%0.2f\n", $1+$2)}'`
            total_pout=`echo "${total_pout} ${PSU_POUT[i-1]}" | awk '{printf("%0.2f\n", $1+$2)}'`
            echo

            psu_mfr_info ${bus[i-1]} 58 PSU${i}
            printf "\n\n"
        else
            echo "PSU${i} Absent"
            printf "\n\n"
            has_error=-1
        fi
    done

    echo "PSU total Pin: ${total_pin}W"
    echo "PSU total Pout: ${total_pout}W"
    total_pout_L=`awk -v x=${total_pout} -v y=0 'BEGIN{print(x>=y)?"0":"1"}'`
    total_pout_H=`awk -v x=${total_pout} -v y=4000 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $total_pout_L -eq 1 || $total_pout_H -eq 3 ]]; then
        echo "PSU total Pout exceeds threshold, value is ${total_pout}W, range is 0W~4000W"
        has_error=-1
    fi

    if [ $has_error -eq 0 ]; then
        echo -e "\nPSU check result: PASS\n"
    else
        echo -e "\nPSU check result: FAIL\n"
    fi
}

function psu_alive_info(){
    AC_cnt=0

    #Get PSU vin/vout1/iin/iout1/pin/pout1/temp1/temp2/fan1 value
    in1_name="VIN"
    in1_val=`cat ${SYSFS_I2C_DEVICES}/${1}-00${2}/in1_input`
    in1_value=`echo "${in1_val} 1000"|awk '{printf("%0.2f\n", $1/$2)}'`
    in2_name="VOUT"
    in2_val=`cat ${SYSFS_I2C_DEVICES}/${1}-00${2}/in2_input`
    in2_value=`echo "${in2_val} 1000"|awk '{printf("%0.2f\n", $1/$2)}'`

    curr1_name="IIN"
    curr1_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/curr1_input`
    curr1_value=`echo "${curr1_val} 1000"|awk '{printf("%0.2f\n", $1/$2)}'`
    curr2_name="IOUT"
    curr2_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/curr2_input`
    curr2_value=`echo "${curr2_val} 1000"|awk '{printf("%0.2f\n", $1/$2)}'`

    power1_name="PIN"
    power1_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/power1_input`
    power1_value=`echo "${power1_val} 1000000"|awk '{printf("%0.2f\n", $1/$2)}'`
    power2_name="POUT"
    power2_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/power2_input`
    power2_value=`echo "${power2_val} 1000000"|awk '{printf("%0.2f\n", $1/$2)}'`
    psu_name=$3
    psu_num=${psu_name:0-1:1}
    PSU_PIN[${psu_num}-1]=$power1_value
    PSU_POUT[${psu_num}-1]=$power2_value

    temp1_name="temp1"
    temp1_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/temp1_input`
    temp1_value=`echo "${temp1_val} 1000"|awk '{printf("%0.1f\n", $1/$2)}'`
    temp2_name="temp2"
    temp2_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/temp2_input`
    temp2_value=`echo "${temp2_val} 1000"|awk '{printf("%0.1f\n", $1/$2)}'`
    temp3_name="temp3"
    temp3_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/temp3_input`
    temp3_value=`echo "${temp3_val} 1000"|awk '{printf("%0.1f\n", $1/$2)}'`

    fan1_name="fan1_input"
    fan1_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/fan1_input`
    fan1_value=`echo "${fan1_val} 1"|awk '{printf("%0.1f\n", $1/$2)}'`

    input_type_name="input_type"
    input_type_value=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/input_type`

    printf "%-10s %10.2f V\n" ${in1_name}: ${in1_value}
    printf "%-10s %10.2f V\n" ${in2_name}: ${in2_value}
    printf "%-10s %10.2f A\n" ${curr1_name}: ${curr1_value}
    printf "%-10s %10.2f A\n" ${curr2_name}: ${curr2_value}
    printf "%-10s %10.2f W\n" ${power1_name}: ${power1_value}
    printf "%-10s %10.2f W\n" ${power2_name}: ${power2_value}
    printf "%-10s %10.2f C\n" ${temp1_name}: ${temp1_value}
    printf "%-10s %10.2f C\n" ${temp2_name}: ${temp2_value}
    printf "%-10s %10.2f C\n" ${temp3_name}: ${temp3_value}
    printf "%-10s %10.2f R\n" ${fan1_name}: ${fan1_value}
    printf "%-10s %10s\n" ${input_type_name}: ${input_type_value}
    #Check PSU values status
    if [ "$input_type_value" == "AC" ];then
        in1_L=`awk -v x=${in1_value} -v y=90 'BEGIN{print(x>=y)?"0":"1"}'`
        in1_H=`awk -v x=${in1_value} -v y=264 'BEGIN{print(x<=y)?"2":"3"}'`
        if [[ $in1_L -eq 1 || $in1_H -eq 3 ]]; then
            let AC_cnt=AC_cnt+1
            echo "$3 $in1_name exceeds threshold, value is ${in1_value}V, range is 90V~264V"
        fi
    else
        in1_L=`awk -v x=${in1_value} -v y=180 'BEGIN{print(x>=y)?"0":"1"}'`
        in1_H=`awk -v x=${in1_value} -v y=320 'BEGIN{print(x<=y)?"2":"3"}'`
        if [[ $in1_L -eq 1 || $in1_H -eq 3 ]]; then
            let AC_cnt=AC_cnt+1
            echo "$3 $in1_name exceeds threshold, value is ${in1_value}V, range is 180V~320V"
        fi
    fi

    in2_L=`awk -v x=${in2_value} -v y=12 'BEGIN{print(x>=y)?"0":"1"}'`
    in2_H=`awk -v x=${in2_value} -v y=12.8 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $in2_L -eq 1 || $in2_H -eq 3 ]]; then
        let AC_cnt=AC_cnt+1
        echo "$3 $in2_name exceeds threshold, value is ${in2_value}V, range is 12V~12.8V"
    fi

    curr1_L=`awk -v x=${curr1_value} -v y=0 'BEGIN{print(x>=y)?"0":"1"}'`
    curr1_H=`awk -v x=${curr1_value} -v y=9 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $curr1_L -eq 1 || $curr1_H -eq 3 ]]; then
        let AC_cnt=AC_cnt+1
        echo "$3 $curr1_name exceeds threshold, value is ${curr1_value}A, range is 0A~9A"
    fi

    curr2_L=`awk -v x=${curr2_value} -v y=0 'BEGIN{print(x>=y)?"0":"1"}'`
    curr2_H=`awk -v x=${curr2_value} -v y=161.3 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $curr2_L -eq 1 || $curr2_H -eq 3 ]]; then
        let AC_cnt=AC_cnt+1
        echo "$3 $curr2_name exceeds threshold, value is ${curr2_value}A, range is 1A~161.3A"
    fi

    power1_L=`awk -v x=${power1_value} -v y=0 'BEGIN{print(x>=y)?"0":"1"}'`
    power1_H=`awk -v x=${power1_value} -v y=2700 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $power1_L -eq 1 || $power1_H -eq 3 ]]; then
        let AC_cnt=AC_cnt+1
        echo "$3 $power1_name exceeds threshold, value is ${power1_value}W, range is 0W~2700W"
    fi

    power2_L=`awk -v x=${power2_value} -v y=0 'BEGIN{print(x>=y)?"0":"1"}'`
    power2_H=`awk -v x=${power2_value} -v y=2700 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $power2_L -eq 1 || $power2_H -eq 3 ]]; then
        let AC_cnt=AC_cnt+1
        echo "$3 $power2_name exceeds threshold, value is ${power2_value}W, range is 0W~2700W"
    fi

    temp1_L=`awk -v x=${temp1_value} -v y=0 'BEGIN{print(x>=y)?"0":"1"}'`
    temp1_H=`awk -v x=${temp1_value} -v y=60 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $temp1_L -eq 1 || $temp1_H -eq 3 ]]; then
        let AC_cnt=AC_cnt+1
        echo "$3 $temp1_name exceeds threshold, value is ${temp1_value}C, range is 0C~60C"
    fi

    temp2_L=`awk -v x=${temp2_value} -v y=0 'BEGIN{print(x>=y)?"0":"1"}'`
    temp2_H=`awk -v x=${temp2_value} -v y=100 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $temp2_L -eq 1 || $temp2_H -eq 3 ]]; then
        let AC_cnt=AC_cnt+1
        echo "$3 $temp2_name exceeds threshold, value is ${temp2_value}C, range is 0C~100C"
    fi

    temp3_L=`awk -v x=${temp3_value} -v y=0 'BEGIN{print(x>=y)?"0":"1"}'`
    temp3_H=`awk -v x=${temp3_value} -v y=100 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $temp3_L -eq 1 || $temp3_H -eq 3 ]]; then
        let AC_cnt=AC_cnt+1
        echo "$3 $temp3_name exceeds threshold, value is ${temp3_value}C, range is 0C~100C"
    fi

    mfr_id=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/mfr_id | grep "DELTA"`
    if [ "$mfr_id" != "" ]; then
        fan1_min=6500
        fan1_max=35500
    else
        fan1_min=1500
        fan1_max=37550
    fi
    fan1_L=`awk -v x=${fan1_value} -v y=${fan1_min} 'BEGIN{print(x>=y)?"0":"1"}'`
    fan1_H=`awk -v x=${fan1_value} -v y=${fan1_max} 'BEGIN{print(x<=y)?"2":"3"}'`
    if [[ $fan1_L -eq 1 || $fan1_H -eq 3 ]]; then
        let AC_cnt=AC_cnt+1
        echo "$3 $fan1_name exceeds threshold, value is ${fan1_value}RPM, range is ${fan1_min}RPM~${fan1_max}RPM"
    fi

    sleep 0.5

    return $AC_cnt
}

psu_mfr(){
    bus=(75 74 73 72)

    for((i=1; i<=4; i++))
    do
        alive=`cat ${BASECPLD_PATH}/psu${i}_present | sed -n 1p`
        if [ "$alive" == "0x0" ]; then
            echo "PSU${i} MFR"
            psu_mfr_info ${bus[i-1]} 58 PSU${i}
        else
            echo "PSU${i} Absent"
            printf "\n\n"
        fi
    done
}

function psu_mfr_info(){
    date_name="MFR_DATE"
    date_val=`cat ${SYSFS_I2C_DEVICES}/${1}-00${2}/mfr_date`

    id_name="MFR_ID"
    id_val=`cat ${SYSFS_I2C_DEVICES}/${1}-00${2}/mfr_id`

    location_name="MFR_LOCATION"
    location_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/mfr_location`

    model_name="MFR_MODEL"
    model_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/mfr_model`

    revision_name="MFR_REVISION"
    revision_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/mfr_revision`

    serial_name="MFR_SERIAL"
    serial_val=`cat ${SYSFS_I2C_DEVICES}/i2c-${1}/${1}-00${2}/mfr_serial`

    printf "%-15s: %-s\n" "${date_name}"     "${date_val}"
    printf "%-15s: %-s\n" "${id_name}"       "${id_val}"
    printf "%-15s: %-s\n" "${location_name}" "${location_val}"
    printf "%-15s: %-s\n" "${model_name}"    "${model_val}"
    printf "%-15s: %-s\n" "${revision_name}" "${revision_val}"
    printf "%-15s: %-s\n" "${serial_name}"   "${serial_val}"

    sleep 0.5
}

function fan_info(){

    fan_name=$3
    fan_val=`cat ${SYSFS_I2C_DEVICES}/${1}-00${2}/fan_direction | sed -n 1p`
    if [[ "$fan_val" == "0x0" ]]; then
        val_str='FAN less'
    elif [[ "$fan_val" == "0x1" ]]; then
        #air from output connector to AC connector
        val_str='F2B'
    elif [[ "$fan_val" == "0x2" ]]; then
        #air from AC connector to output connector
        val_str='B2F'
    else
        val_str='unknown'
    fi
    printf "%-15s: %-s\n" "${fan_name} fan direction"     "${val_str}"

    sleep 0.5
}

psu_fan(){
    bus=(75 74 73 72)

    for((i=1; i<=4; i++))
    do
        alive=`cat ${BASECPLD_PATH}/psu${i}_present | sed -n 1p`
        if [ "$alive" == "0x0" ]; then
            #echo "PSU${i} fan direction"
            fan_info ${bus[i-1]} 58 PSU${i}
        else
            echo "PSU${i} Absent"
            printf "\n\n"
        fi
    done
}

if [ $# -ne 1 ]; then
    usage
    exit -1
fi

object="$1"

case "$object" in
    status)
        psu_status
        ;;
    info)
        psu_info
        ;;
    fan)
        psu_fan
        ;;
    *)
        usage
        exit -1
        ;;
esac

exit $?
