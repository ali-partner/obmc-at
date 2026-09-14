#!/usr/bin/env python

try:
    import os
    import sys
    import subprocess
    import signal
    import time
    import math
    #import logging
    #import logging.config
except ImportError as e:
    raise ImportError('%s - required module not found' % str(e))

###############################################################################
FUNCTION_NAME = 'diag_asic_voltage'
LINEAR11_MASK=0x7FF
ULINEAR16_MASK=0xFFFF
STORE_CODE_FLAG=0x321
g_voltage_level = 0 #high:1/standard:0/low:-1
g_store_code_flag = 0
g_rev2_set_enable = 0

#ASIC all avs voltage
avs_voltage_address_all =  [{'name':'VDD_PVS_MBIN',        'bus':72, 'addr':0x62, 'rail':1},  #MP2891
                            {'name':'DVDD_CVB',            'bus':77, 'addr':0x6E, 'rail':2},  #MP2975
                            {'name':'VDD_PVS_MBIN_TILE_0', 'bus':80, 'addr':0x63, 'rail':1},  #MP2891
                            {'name':'DVDD_CVB_TILE_0',     'bus':73, 'addr':0x67, 'rail':1},  #MP2975
                            {'name':'VDD_PVS_MBIN_TILE_1', 'bus':80, 'addr':0x63, 'rail':2},  #MP2891
                            {'name':'DVDD_CVB_TILE_1',     'bus':73, 'addr':0x67, 'rail':2},  #MP2975
                            {'name':'VDD_PVS_MBIN_TILE_2', 'bus':81, 'addr':0x64, 'rail':1},  #MP2891
                            {'name':'DVDD_CVB_TILE_2',     'bus':74, 'addr':0x68, 'rail':1},  #MP2975
                            {'name':'VDD_PVS_MBIN_TILE_3', 'bus':81, 'addr':0x64, 'rail':2},  #MP2891
                            {'name':'DVDD_CVB_TILE_3',     'bus':74, 'addr':0x68, 'rail':2},  #MP2975
                            {'name':'VDD_PVS_MBIN_TILE_4', 'bus':82, 'addr':0x65, 'rail':1},  #MP2891
                            {'name':'DVDD_CVB_TILE_4',     'bus':75, 'addr':0x69, 'rail':1},  #MP2975
                            {'name':'VDD_PVS_MBIN_TILE_5', 'bus':82, 'addr':0x65, 'rail':2},  #MP2891
                            {'name':'DVDD_CVB_TILE_5',     'bus':75, 'addr':0x69, 'rail':2},  #MP2975
                            {'name':'VDD_PVS_MBIN_TILE_6', 'bus':83, 'addr':0x66, 'rail':1},  #MP2891
                            {'name':'DVDD_CVB_TILE_6',     'bus':76, 'addr':0x6A, 'rail':1},  #MP2975
                            {'name':'VDD_PVS_MBIN_TILE_7', 'bus':83, 'addr':0x66, 'rail':2},  #MP2891
                            {'name':'DVDD_CVB_TILE_7',     'bus':76, 'addr':0x6A, 'rail':2},  #MP2975
                            {'name':'VDDSCC',              'bus':77, 'addr':0x6E, 'rail':1},  #MP2975
                            {'name':'HVDD_T03',            'bus':84, 'addr':0x6B, 'rail':1},  #MP2975
                            {'name':'HVDD_T47',            'bus':84, 'addr':0x6B, 'rail':2}]  #MP2975

#ASIC avs voltage need regulation
avs_voltage_address_all =  [{'name':'vdd',  'die':'main',   'bus':48, 'addr':0x60, 'rail':1},
                        {'name':'vdd',  'die':'tile[0]',  'bus':49, 'addr':0x63, 'rail':1},
                        {'name':'vdd',  'die':'tile[1]',  'bus':49, 'addr':0x63, 'rail':2},
                        {'name':'vdd',  'die':'tile[2]',  'bus':50, 'addr':0x64, 'rail':1},
                        {'name':'vdd',  'die':'tile[3]',  'bus':50, 'addr':0x64, 'rail':2},
                        {'name':'vdd',  'die':'tile[4]',  'bus':51, 'addr':0x65, 'rail':1},
                        {'name':'vdd',  'die':'tile[5]',  'bus':51, 'addr':0x65, 'rail':2},
                        {'name':'vdd',  'die':'tile[6]',  'bus':52, 'addr':0x66, 'rail':1},
                        {'name':'vdd',  'die':'tile[7]',  'bus':52, 'addr':0x66, 'rail':2},
                        {'name':'pl_avdd', 'die':'tile[0]',  'bus':56, 'addr':0x63, 'rail':1},
                        {'name':'pl_avdd', 'die':'tile[1]',  'bus':56, 'addr':0x63, 'rail':2},
                        {'name':'pl_avdd', 'die':'tile[2]',  'bus':57, 'addr':0x64, 'rail':1},
                        {'name':'pl_avdd', 'die':'tile[3]',  'bus':57, 'addr':0x64, 'rail':2},
                        {'name':'pl_avdd', 'die':'tile[4]',  'bus':58, 'addr':0x65, 'rail':1},
                        {'name':'pl_avdd', 'die':'tile[5]',  'bus':58, 'addr':0x65, 'rail':2},
                        {'name':'pl_avdd', 'die':'tile[6]',  'bus':59, 'addr':0x66, 'rail':1},
                        {'name':'pl_avdd', 'die':'tile[7]',  'bus':59, 'addr':0x66, 'rail':2},
                        {'name':'pl_dvdd', 'die':'tile[0]',  'bus':60, 'addr':0x67, 'rail':1},
                        {'name':'pl_dvdd', 'die':'tile[1]',  'bus':60, 'addr':0x67, 'rail':2},
                        {'name':'pl_dvdd', 'die':'tile[2]',  'bus':61, 'addr':0x68, 'rail':1},
                        {'name':'pl_dvdd', 'die':'tile[3]',  'bus':61, 'addr':0x68, 'rail':2},
                        {'name':'pl_dvdd', 'die':'tile[4]',  'bus':62, 'addr':0x69, 'rail':1},
                        {'name':'pl_dvdd', 'die':'tile[5]',  'bus':62, 'addr':0x69, 'rail':2},
                        {'name':'pl_dvdd', 'die':'tile[6]',  'bus':63, 'addr':0x6A, 'rail':1},
                        {'name':'pl_dvdd', 'die':'tile[7]',  'bus':63, 'addr':0x6A, 'rail':2}]

avs_voltage_address =  [{'name':'pl_avdd', 'die':'tile[0]',  'bus':56, 'addr':0x63, 'rail':1},
                        {'name':'pl_avdd', 'die':'tile[1]',  'bus':56, 'addr':0x63, 'rail':2},
                        {'name':'pl_avdd', 'die':'tile[2]',  'bus':57, 'addr':0x64, 'rail':1},
                        {'name':'pl_avdd', 'die':'tile[3]',  'bus':57, 'addr':0x64, 'rail':2},
                        {'name':'pl_avdd', 'die':'tile[4]',  'bus':58, 'addr':0x65, 'rail':1},
                        {'name':'pl_avdd', 'die':'tile[5]',  'bus':58, 'addr':0x65, 'rail':2},
                        {'name':'pl_avdd', 'die':'tile[6]',  'bus':59, 'addr':0x66, 'rail':1},
                        {'name':'pl_avdd', 'die':'tile[7]',  'bus':59, 'addr':0x66, 'rail':2},
                        {'name':'pl_dvdd', 'die':'tile[0]',  'bus':60, 'addr':0x67, 'rail':1},
                        {'name':'pl_dvdd', 'die':'tile[1]',  'bus':60, 'addr':0x67, 'rail':2},
                        {'name':'pl_dvdd', 'die':'tile[2]',  'bus':61, 'addr':0x68, 'rail':1},
                        {'name':'pl_dvdd', 'die':'tile[3]',  'bus':61, 'addr':0x68, 'rail':2},
                        {'name':'pl_dvdd', 'die':'tile[4]',  'bus':62, 'addr':0x69, 'rail':1},
                        {'name':'pl_dvdd', 'die':'tile[5]',  'bus':62, 'addr':0x69, 'rail':2},
                        {'name':'pl_dvdd', 'die':'tile[6]',  'bus':63, 'addr':0x6A, 'rail':1},
                        {'name':'pl_dvdd', 'die':'tile[7]',  'bus':63, 'addr':0x6A, 'rail':2}]

#qsfp avs voltage
osfp_voltage_address =  [{'name':'VR_V33_OSFP1_R1',    'bus':24, 'addr':0x68, 'rail':1},
                         {'name':'VR_V33_OSFP2_R2',    'bus':24, 'addr':0x68, 'rail':2},
                         {'name':'VR_V33_OSFP3_R1',    'bus':25, 'addr':0x6a, 'rail':1},
                         {'name':'VR_V33_OSFP4_R2',    'bus':25, 'addr':0x6a, 'rail':2},
                         {'name':'VR_V33_OSFP5_R1',    'bus':26, 'addr':0x6c, 'rail':1},
                         {'name':'VR_V33_OSFP6_R2',    'bus':26, 'addr':0x6c, 'rail':2},
                         {'name':'VR_V33_OSFP7_R1',    'bus':27, 'addr':0x6e, 'rail':1},
                         {'name':'VR_V33_OSFP8_R2',    'bus':27, 'addr':0x6e, 'rail':2},
                         {'name':'VR_V33_OSFP9_R1',    'bus':28, 'addr':0x60, 'rail':1},
                         {'name':'VR_V33_OSFP10_R2',    'bus':28, 'addr':0x60, 'rail':2},
                         {'name':'VR_V33_OSFP11_R1',    'bus':29, 'addr':0x62, 'rail':1},
                         {'name':'VR_V33_OSFP12_R2',    'bus':29, 'addr':0x62, 'rail':2},
                         {'name':'VR_V33_OSFP13_R1',    'bus':30, 'addr':0x64, 'rail':1},
                         {'name':'VR_V33_OSFP14_R2',    'bus':30, 'addr':0x64, 'rail':2},
                         {'name':'VR_V33_OSFP15_R1',    'bus':31, 'addr':0x66, 'rail':1},
                         {'name':'VR_V33_OSFP16_R2',    'bus':31, 'addr':0x66, 'rail':2}]



# i2cset -f -y 24 0x68 0x0 0 b;i2cget -f -y 24 0x68 0x99 w
# i2cset -f -y 25 0x6a 0x0 0 b;i2cget -f -y 25 0x6a 0x99 w
# i2cset -f -y 26 0x6c 0x0 0 b;i2cget -f -y 26 0x6c 0x99 w
# i2cset -f -y 27 0x6e 0x0 0 b;i2cget -f -y 27 0x6e 0x99 w

# i2cset -f -y 28 0x60 0x0 0 b;i2cget -f -y 28 0x60 0x99 w
# i2cset -f -y 29 0x62 0x0 0 b;i2cget -f -y 29 0x62 0x99 w
# i2cset -f -y 30 0x64 0x0 0 b;i2cget -f -y 30 0x64 0x99 w
# i2cset -f -y 31 0x66 0x0 0 b;i2cget -f -y 31 0x66 0x99 w

###############################################################################################################################
#Common Function
###############################################################################################################################
def getstatusoutput(cmd):
    if sys.version_info.major == 2:
        # python2
        import commands
        return commands.getstatusoutput(cmd)
    else:
        # python3
        return subprocess.getstatusoutput(cmd)

def get_voltage_from_file(file_name, name, die):
    """从新格式文件中读取指定 name+die 对应的电压值(mV)"""
    cmd = "awk -v n='%s' -v d='%s' '$1==n && $2==d {print $3}' %s" % (name, die, file_name)
    ret, output = getstatusoutput(cmd)
    if ret != 0 or not output:
        return None
    # 输出可能带有单位 "mV"，仅取数字部分
    try:
        vol = float(output.strip().split()[0])
        return int(vol)
    except:
        return None

def drv_registers_page_get(bus, addr):
    cmd = 'i2cget -f -y %d 0x%x 0x0 b' % (bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #print(output)
    if(ret == 0):
        return(output)
    else:
        return("Unknown" if (ret == 0) else "Undetected")

def drv_registers_page_set(bus, addr, page):
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b' % (bus, addr, page)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    if(ret == 0):
        return(ret)
    else:
        return("Unknown" if (ret == 0) else "Undetected")

###############################################################################################################################
#Infineon  XDPE12284C
#STORE_USER_ALL 0x15
def drv_pmbus_store_user_code(bus, addr, rail):
    #print("drv_pmbus_store_user_code")
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cset -f -y %d 0x%x 0x15 cp' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    if(ret == 0):
        print("[drv_vout_command_set] (%d-0x%x) page(%d) STORE_USER_ALL successed." % (bus, addr, page))
        return(ret)
    else:
        print("[drv_vout_command_set] (%d-0x%x) page(%d) STORE_USER_ALL filed." % (bus, addr, page))
        return -1

def pmbus_reg2data_linear11(reg_val):
    #LINEAR11 
    reg_value = int(reg_val,16)
    exponent = (reg_value) >> 11
    sign_exponent = 0
    if((exponent >> 4) & 0x01):
        temp_value = (((exponent & 0xF) - 1) ^ 0xF)
        sign_exponent = int(0 - temp_value)
    else:
        sign_exponent = int(exponent & 0x0F)

    mantissa = (((reg_value & LINEAR11_MASK) << 5)) >> 5
    sign_mantissa = 0
    if((mantissa >> 10) & 0x01):
        temp_value = (((mantissa & 0x03FF) - 1) ^ 0x03FF)
        sign_mantissa = int(0 - temp_value)
    else:
        sign_mantissa = int(mantissa & 0x03FF)

    val = round((sign_mantissa * 1000 * pow(2,sign_exponent)),2)
    #if(sign_exponent >= 0):
        #val <<= exponent
    #else:
        #val >>= -exponent
    #reg_value=0xBE40,mantissa=-448,exponent=-9,val=-875. 
    #reg_value=0xB200,mantissa=512,exponent=-10,val=500. 
    #reg_value=0xDA08,mantissa=520,exponent=-5,val=16250
    print("pmbus_reg2data_linear11 reg_value=0x%x, sign_exponent=%d, sign_mantissa=%d, val=%d ." % (reg_value, sign_exponent, sign_mantissa, val))
    return(val)

#VOUT_COMMAND 0x21 ULINEAR16
def drv_vout_command_ulinear16_get(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x21 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #ULINEAR16 
    reg_val = (int(output,16) & ULINEAR16_MASK)
    if(ret == 0):
        vol_value = int((reg_val * 1000) / pow(2,9))
        print("[drv_vout_command_ulinear16_get] (%d-0x%x) output=%s,reg_value=0x%x,vout=%d mV." % (bus, addr, output, reg_val, vol_value))
        return(vol_value)
    else:
        return -1

def drv_vout_command_ulinear16_set(bus, addr, rail, vol_value):
    #Firs switch pages based on the rail
    page = rail - 1
    #vout_command 
    reg_value = int(vol_value * pow(2,9) / 1000)
    print(reg_value)
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cset -f -y %d 0x%x 0x21 0x%x w' % (bus, addr, page, bus, addr, reg_value)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    if(ret == 0):
        print("[drv_vout_command_ulinear16_set] (%d-0x%x) set VID(0x%x) successed." % (bus, addr, reg_value))
        return(ret)
    else:
        print("[drv_vout_command_ulinear16_set] (%d-0x%x) set VID(0x%x) failed." % (bus, addr, reg_value))
        return -1

###############################################################################################################################
#Infineon  XDPE12284C
#Rail1 0x88 page0
#Rail2 0x88 page1
#READ_VIN 0x88 LINEAR11
def drv_read_vin_linear11_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x88 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #VIN_PMBUS_LSB=0.25V, Range=128V
    #print(output)
    reg_val = pmbus_reg2data_linear11(output)
    voltage_val = int(reg_val)
    #print(voltage_val)
    if(ret == 0):
        #print("[drv_read_vin_linear11_info] (%d-0x%x) vin=%d mV." % (bus, addr, voltage_val))
        return(voltage_val)
    else:
        return -1

#Rail1 0x89 page0
#Rail2 0x89 page1
#READ_IIN 0x89 LINEAR11
def drv_read_iin_linear11_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x89 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #print(output)
    reg_val = pmbus_reg2data_linear11(output)
    current_val = int(reg_val)
    #print(current_val)
    if(ret == 0):
        #print("[drv_read_iin_linear11_info] (%d-0x%x) iin=%d mA." % (bus, addr, current_val))
        return(current_val)
    else:
        return -1

#Rail1 0x8B/0x21 page0
#Rail2 0x8B/0x21 page1
#READ_VOUT 0x8B ULINEAR16
def drv_read_vout_linear16_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x8B w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #ULINEAR16 
    reg_val = int(output,16)
    if(ret == 0):
        voltage_val = int((reg_val * 1000) / pow(2,9))
        print("The read value output=%s, reg_val=0x%x, voltage_val=0x%x ." % (output, reg_val, voltage_val))
        return(voltage_val)
    else:
        return -1

#Rail1 0x8C page0
#Rail2 0x8C page1
#READ_IOUT 0x8C LINEAR11
def drv_read_iout_linear11_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x8C w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #print(output)
    reg_val = pmbus_reg2data_linear11(output)
    current_val = int(reg_val)
    #print(current_val)
    if(ret == 0):
        #print("[drv_read_iout_linear11_info] (%d-0x%x) iout=%d mA." % (bus, addr, current_val))
        return(current_val)
    else:
        return -1

#Rail1 0x96 page0
#Rail2 0x96 page1
#READ_POUT 0x96 LINEAR11
def drv_read_pout_linear11_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x96 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #print(output)
    reg_val = pmbus_reg2data_linear11(output)
    power_val = int(reg_val)
    #print(power_val)
    if(ret == 0):
        #print("[drv_read_pout_linear11_info] (%d-0x%x) pout=%d mW." % (bus, addr, power_val))
        return(power_val)
    else:
        return -1

#Rail1 0x97 page0
#Rail2 0x97 page1
#READ_PIN 0x97  LINEAR11
def drv_read_pin_linear11_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x97 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #print(output)
    reg_val = pmbus_reg2data_linear11(output)
    power_val = int(reg_val)
    #print(power_val)
    if(ret == 0):
        #print("[drv_read_pin_linear11_info] (%d-0x%x) pin=%d mW." % (bus, addr, power_val))
        return(power_val)
    else:
        return -1

###############################################################################################################################
#Infineon  XDPE12284C
#OPERATION  0x01 
def drv_operation_state_get(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x1 b' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)

    if(ret == 0):
        reg_val = (int(output,16))
        print("[drv_operation_state_get] (%d-0x%x) reg_value=0x%x." % (bus, addr, reg_val))
        return(reg_val)
    else:
        return -1

def drv_operation_state_set(bus, addr, rail, state_value):
    #Firs switch pages based on the rail
    page = rail - 1
    reg_val = (int(state_value,16))
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cset -f -y %d 0x%x 0x1 0x%x b' % (bus, addr, page, bus, addr, reg_val)
    print(cmd)
    ret=0
    #ret, output = getstatusoutput(cmd)
    if(ret == 0):
        print("[drv_operation_state_set] (%d-0x%x) set operational state value(0x%x) successed." % (bus, addr, reg_val))
        return(ret)
    else:
        print("[drv_operation_state_set] (%d-0x%x) set operational state value(0x%x) failed." % (bus, addr, reg_val))
        return -1

#Infineon ulinear16 VOUT_COMMAND 0x21
def drv_asic_voltage_get_infineon_by_vddname(vdd_name):
    #print("drv_asic_voltage_get_infineon_by_vddname")
    name_result = 255
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            voltage_val = drv_vout_command_ulinear16_get(bus, addr, rail)
            if(voltage_val == -1):
                print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get vout:%d mV." % (name, bus, addr, voltage_val))
    
    if(name_result != 0):
        print("The %s voltage can not find,To get vout failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_asic_voltage_get_infineon_all():
    #print("drv_asic_voltage_get_infineon_all")
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        voltage_val = drv_vout_command_ulinear16_get(bus, addr, rail)
        if(voltage_val == -1):
            print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get vout:%d mV." % (name, bus, addr, voltage_val))
    return 0

#Set VOUT_COMMAND 0x21
def drv_asic_voltage_set_infineon_by_vddname(vdd_name, file_name):
    #print("drv_asic_voltage_set_infineon_by_vddname")
    ret = -1
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        if(name != vdd_name):
            continue
        else:
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            cmd = 'cat %s | grep -iE "%s:" | awk \'{print $2}\'' %(file_name, name)
            #print(cmd)
            ret, output = getstatusoutput(cmd)
            print(output)
            if(ret == 0):
                if(len(output) == 0):
                    print("[drv_asic_voltage_set_infineon_by_vddname] The %s(%d-0x%x) can not find, set avs voltage failed." % (name, bus, addr))
                    return -1
            else:
                print("[drv_asic_voltage_set_infineon_by_vddname] The %s(%d-0x%x) find failed." % (name, bus, addr))
                return -1
            voltage_read_val = int(output)
            #g_voltage_level#high:1/standard:0/low:-1
            global g_voltage_level
            if(g_voltage_level == -1):
                voltage_val = int(voltage_read_val * 0.97)
            elif(g_voltage_level == 1):
                voltage_val = int(voltage_read_val * 1.03)
            else:
                voltage_val = voltage_read_val
            
            print("The drv_asic_voltage_set_infineon_by_vddname %s(%d-0x%x) set vout(%d) voltage_read_val(%d) g_voltage_level(%d)." % (name, bus, addr, voltage_val, voltage_read_val, g_voltage_level))
            
            state_value = drv_operation_state_get(bus, addr, rail)
            if(state_value != 0x80):
                ret = drv_operation_state_set(bus, addr, rail, 0x80)
                if(ret == -1):
                    print("The %s(%d-0x%x) set operational state(0x%x) failed." % (name, bus, addr, 0x80))
                    return -1
            ret = drv_vout_command_ulinear16_set(bus, addr, rail, voltage_val)
            if(ret == -1):
                print("The %s(%d-0x%x) set vout(%d) failed." % (name, bus, addr, voltage_val))
                return -1
            global g_store_code_flag
            if(g_store_code_flag == STORE_CODE_FLAG):
                ret = drv_pmbus_store_user_code(bus, addr, rail)
                if(ret == -1):
                    print("The %s(%d-0x%x) set store user code failed." % (name, bus, addr))
                    return -1
    if(ret != 0):
        print("[drv_asic_voltage_set_infineon_by_vddname] The %s can not find in the %s, set avs voltage failed." % (vdd_name, file_name))
        return -1
    return 0

#cat asic_voltage_result | grep -iE "DVDD_CVB" | awk '{print $2}'
def drv_asic_voltage_set_infineon_all(file_name):
    #print("drv_asic_voltage_set_infineon_all")
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        cmd = 'cat %s | grep -iE "%s:" | awk \'{print $2}\'' %(file_name, name)
        #print(cmd)
        ret, output = getstatusoutput(cmd)
        print(output)
        if(ret == 0):
            if(len(output) == 0):
                print("[drv_asic_voltage_set_infineon_all] The %s(%d-0x%x) can not find, set avs voltage failed." % (name, bus, addr))
                continue
        else:
            print("[drv_asic_voltage_set_infineon_all] The %s(%d-0x%x) find failed." % (name, bus, addr))
            continue
        voltage_read_val = int(output)
        #g_voltage_level#high:1/standard:0/low:-1
        global g_voltage_level
        if(g_voltage_level == -1):
            voltage_val = int(voltage_read_val * 0.97)
        elif(g_voltage_level == 1):
            voltage_val = int(voltage_read_val * 1.03)
        else:
            voltage_val = voltage_read_val

        print("The drv_asic_voltage_set_infineon_all %s(%d-0x%x) set vout(%d) voltage_read_val(%d) g_voltage_level(%d)." % (name, bus, addr, voltage_val, voltage_read_val, g_voltage_level))

        state_value = drv_operation_state_get(bus, addr, rail)
        if(state_value != 0x80):
            ret = drv_operation_state_set(bus, addr, rail, 0x80)
            if(ret == -1):
                print("The %s(%d-0x%x) set operational state(0x%x) failed." % (name, bus, addr, 0x80))
                continue
        ret = drv_vout_command_ulinear16_set(bus, addr, rail, voltage_val)
        time.sleep(0.1)
        if(ret == -1):
            print("The %s(%d-0x%x) set vout(%d) failed." % (name, bus, addr, voltage_val))
            continue
        global g_store_code_flag
        if(g_store_code_flag == STORE_CODE_FLAG):
            ret = drv_pmbus_store_user_code(bus, addr, rail)
            if(ret == -1):
                print("The %s(%d-0x%x) set store user code failed." % (name, bus, addr))
                continue
    return 0

#Check VOUT_COMMAND 0x21
def drv_asic_voltage_check_infineon_by_vddname(vdd_name, file_name):
    #print("drv_asic_voltage_check_infineon_by_vddname")
    ret = -1
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        if(name != vdd_name):
            continue
        else:
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            cmd = 'cat %s | grep -iE "%s:" | awk \'{print $2}\'' %(file_name, name)
            #print(cmd)
            ret, output = getstatusoutput(cmd)
            #print(output)
            if(ret == 0):
                if(len(output) == 0):
                    print("[drv_asic_voltage_check_infineon_by_vddname] The %s(%d-0x%x) can not find, check avs voltage failed." % (name, bus, addr))
                    return -1
            else:
                print("[drv_asic_voltage_check_infineon_by_vddname] The %s(%d-0x%x) find failed." % (name, bus, addr))
                return -1
            voltage_read_val = int(output)

            #g_voltage_level#high:1/standard:0/low:-1
            global g_voltage_level
            if(g_voltage_level == -1):
                voltage_val = int(voltage_read_val * 0.97)
            elif(g_voltage_level == 1):
                voltage_val = int(voltage_read_val * 1.03)
            else:
                voltage_val = voltage_read_val
            print("The drv_asic_voltage_check_infineon_by_vddname %s(%d-0x%x) check vout(%d) voltage_read_val(%d) g_voltage_level(%d)." % (name, bus, addr, voltage_val, voltage_read_val, g_voltage_level))

            vout_command_val = drv_vout_command_ulinear16_get(bus, addr, rail)
            read_vout_val = drv_read_vout_linear16_info(bus, addr, rail)
            if((vout_command_val == -1) or (read_vout_val == -1)):
                print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
                return -1
            else:
                diff_value = vout_command_val - voltage_val
                diff_value1 = read_vout_val - voltage_val
                if((diff_value < -5) or (diff_value > 5) or (diff_value1 < -20) or (diff_value1 > 20)):
                    print("The %s(%d-0x%x) check vout(VOUT_COMMAND value:%d mV,READ_VOUT value:%d mV,verify:%d mV) failed." % (name, bus, addr, vout_command_val, read_vout_val, voltage_val))
                    return -1
                else:
                    print("The %s(%d-0x%x) check vout(VOUT_COMMAND value:%d mV,READ_VOUT value:%d mV,verify:%d mV) successed." % (name, bus, addr, vout_command_val, read_vout_val, voltage_val))
                    return 0
    if(ret != 0):
        print("[drv_asic_voltage_check_infineon_by_vddname] The %s can not find in the %s, check avs voltage failed." % (vdd_name, file_name))
        return -1

    return 0

def drv_asic_voltage_check_infineon_all(file_name):
    global g_rev2_set_enable
    print("drv_asic_voltage_check_infineon_all g_rev2_set_enable=%d" % (g_rev2_set_enable))
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        cmd = 'cat %s | grep -iE "%s:" | awk \'{print $2}\'' %(file_name, name)
        #print(cmd)
        ret, output = getstatusoutput(cmd)
        print(output)
        if(ret == 0):
            if(len(output) == 0):
                print("[drv_asic_voltage_check_infineon_all] The %s(%d-0x%x) can not find, check avs voltage failed." % (name, bus, addr))
                continue
        else:
            print("[drv_asic_voltage_check_infineon_all] The %s(%d-0x%x) find failed." % (name, bus, addr))
            continue
        voltage_read_val = int(output)
        #g_voltage_level#high:1/standard:0/low:-1
        global g_voltage_level
        if(g_voltage_level == -1):
            voltage_val = int(voltage_read_val * 0.97)
        elif(g_voltage_level == 1):
            voltage_val = int(voltage_read_val * 1.03)
        else:
            voltage_val = voltage_read_val
        
        print("The drv_asic_voltage_check_infineon_all %s(%d-0x%x) check vout(%d) voltage_read_val(%d) g_voltage_level(%d)." % (name, bus, addr, voltage_val, voltage_read_val, g_voltage_level))
        
        vout_command_val = drv_vout_command_ulinear16_get(bus, addr, rail)
        read_vout_val = drv_read_vout_linear16_info(bus, addr, rail)
        if((vout_command_val == -1) or (read_vout_val == -1)):
            print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
            continue
        else:
            diff_value = vout_command_val - voltage_val
            diff_value1 = read_vout_val - voltage_val
            if((diff_value < -5) or (diff_value > 5) or (diff_value1 < -20) or (diff_value1 > 20)):
                print("The %s(%d-0x%x) check vout(VOUT_COMMAND value:%d mV,READ_VOUT value:%d mV,verify:%d mV) failed." % (name, bus, addr, vout_command_val, read_vout_val, voltage_val))
                continue
            else:
                print("The %s(%d-0x%x) check vout(VOUT_COMMAND value:%d mV,READ_VOUT value:%d mV,verify:%d mV) successed." % (name, bus, addr, vout_command_val, read_vout_val, voltage_val))
    return 0
###############################################################################################################################

###############################################################################################################################

#i2cset -f -y 75 0x66 0x0 0 b;i2cget -f -y 75 0x66 0x99 w
MP2891_MFR_MODEL=0x5303 
MP2985_MFR_MODEL=0x8502
def drv_mps_mfr_model_get(bus, addr, rail):
    #Firs switch pages based on the rail
    page = 0
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x9A w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    reg_val = int(output,16)
    if(ret == 0):
        print("[drv_mps_mfr_model_get] (%d-0x%x) mfr_model=0x%x." % (bus, addr, reg_val))
        return(reg_val)
    else:
        return -1

#MPS MPS2975
#STORE_USER_CODE 0x17
def drv_mps_store_normal_code(bus, addr, rail):
    #print("drv_mps_store_normal_code")
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    #cmd = 'i2cset -f -y %d 0x%x 0x17 0 b' % (bus, addr)
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cset -f -y %d 0x%x 0x15 cp' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    if(ret == 0):
        return(ret)
    else:
        print("To set (%d-0x%x) page(%d) STORE_USER_CODE filed." % (bus, addr, page))
        return -1

#MFR_VR_MULTI_CONFIG_R1 
#RAIL1 0x0d page2 [12:5] VBOOT_SET
#RAIL2 0x1d page2 [11:4] VBOOT_SET
def drv_mps_mfr_vr_multi_config_vboot_set(bus, addr, rail, vol_value):
    #先根据rail来确定reg/bit
    if (rail == 1):
        vboot_set_reg = 0x0d
        start_bit = 5
        mask_val = 0x3FE0
    elif(rail == 2):
        vboot_set_reg = 0x1d
        start_bit = 4
        mask_val = 0x1FF0
    else:
        print("[drv_mps_mfr_vr_multi_config_vboot_set] (%d-0x%x) the rail(%d) parameter error." % (bus, addr, rail))
        return -1
    mfr_model = drv_mps_mfr_model_get(bus, addr, 1)
    if mfr_model != MP2985_MFR_MODEL:
        print("[drv_mps_mfr_vr_multi_config_vboot_set] (%d-0x%x) rail(%d), the mfr_model(0x%x) do not support VBOOT_SET." % (bus, addr, rail, mfr_model))
        return 0

    #切换page
    page = 2
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    #先读出reg default value
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x%x w' % (bus, addr, page, bus, addr, vboot_set_reg)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #1-VID step/LSB 
    print(output)
    def_reg_val = int(output,16)
    #print(def_reg_val)
    if(ret != 0):
        print("[drv_mps_mfr_vr_multi_config_vboot_set] (%d-0x%x) vboot set reg(0x%x) read failed." % (bus, addr, vboot_set_reg))
        return -1

    #First clear vout_command 
    vid_value = 0
    reg_value = (def_reg_val & ~mask_val) | (vid_value << start_bit)
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cset -f -y %d 0x%x 0x%x 0x%x w' % (bus, addr, page, bus, addr, vboot_set_reg, reg_value)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    if(ret == 0):
        print("[drv_mps_mfr_vr_multi_config_vboot_set] (%d-0x%x) clear vboot_set(0x%x) VID(0x%x) successed." % (bus, addr, vboot_set_reg, reg_value))
    else:
        print("[drv_mps_mfr_vr_multi_config_vboot_set] (%d-0x%x) clear vboot_set(0x%x) VID(0x%x) failed." % (bus, addr, vboot_set_reg, reg_value))
        return -1
    time.sleep(0.2)
    temp = vol_value/5 - 49
    #print(temp)
    vid_value = int(vol_value/5 - 49)
    #(def_reg_val & ~mask_val) | (vid_value << start_bit)
    reg_value = (def_reg_val & ~mask_val) | (vid_value << start_bit)
    #print("[drv_mps_mfr_vr_multi_config_vboot_set] (%d-0x%x) set def_reg_val(0x%x),val1(0x%x),val2(0x%x),reg_value(0x%x)." % (bus, addr, def_reg_val, (def_reg_val & ~mask_val),(vid_value << start_bit), reg_value))
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cset -f -y %d 0x%x 0x%x 0x%x w' % (bus, addr, page, bus, addr, vboot_set_reg, reg_value)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    if(ret == 0):
        print("[drv_mps_mfr_vr_multi_config_vboot_set] (%d-0x%x) set vboot_set(0x%x) VID(0x%x) successed." % (bus, addr, vboot_set_reg, reg_value))
        return(ret)
    else:
        print("[drv_mps_mfr_vr_multi_config_vboot_set] (%d-0x%x) set vboot_set(0x%x) VID(0x%x) failed." % (bus, addr, vboot_set_reg, reg_value))
        return -1
        

###############################################################################################################################
#MPS MPS2975
#MFR_VR_MULTI_CONFIG_R2 (1Dh on page 2). 1 VID step/LSB.
#VID_STEP_SEL  1’b0: 10mV per VID step /1‘b1: 5mV per VID step
#VOUT_COMMAND 0x21
def drv_vout_command_vid_get(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x21 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #1 VID step/LSB 
    vid_val = int(output,16)
    if(ret == 0):
        mfr_model = drv_mps_mfr_model_get(bus, addr, 1)
        if mfr_model != MP2985_MFR_MODEL:
            #MPS MPS2891
            vol_value = (vid_val) * 2.5
        else:
            #MPS MPS2975
            vol_value = (vid_val + 49) * 5
        print("[drv_vout_command_vid_get] (%d-0x%x) VID=0x%x,vout=%d mV." % (bus, addr, vid_val, vol_value))
        return(vol_value)
    else:
        return -1

def drv_vout_command_vid_set(bus, addr, rail, vol_value):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    #First clear vout_command 
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cset -f -y %d 0x%x 0x21 0x%x w' % (bus, addr, page, bus, addr, 0)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    if(ret == 0):
        print("[drv_vout_command_vid_set] (%d-0x%x) clear VID(0x%x) successed." % (bus, addr, 0))
    else:
        print("[drv_vout_command_vid_set] (%d-0x%x) clear VID(0x%x) failed." % (bus, addr, 0))
        return -1
    time.sleep(0.2)
    #temp = vol_value/5 - 49
    #print(temp)
    mfr_model = drv_mps_mfr_model_get(bus, addr, 1)
    if mfr_model != MP2985_MFR_MODEL:
        #MPS MPS2891
        reg_value = int(vol_value/2.5)
    else:
        #MPS MPS2975
        reg_value = int(vol_value/5 - 49)

    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cset -f -y %d 0x%x 0x21 0x%x w' % (bus, addr, page, bus, addr, reg_value)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    if(ret == 0):
        print("[drv_vout_command_vid_set] (%d-0x%x) set VID(0x%x) successed." % (bus, addr, reg_value))
        return(ret)
    else:
        print("[drv_vout_command_vid_set] (%d-0x%x) set VID(0x%x) failed." % (bus, addr, reg_value))
        return -1

###############################################################################################################################
#MPS MPS2975
#Rail1 0x88 page0
#Rail2 0x88 page1
#READ_VIN 0x88 0.25V/LSB
def drv_read_vin_direct_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x88 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #0.25V/LSB VIN_PMBUS_LSB = 1 
    #print(output)
    mask_val = 0x7F
    reg_val = int(output,16) & mask_val
    voltage_val = (reg_val/4)*1000
    #print(voltage_val)
    if(ret == 0):
        #print("[drv_read_vin_direct_info] (%d-0x%x) vin=%d mV." % (bus, addr, voltage_val))
        return(voltage_val)
    else:
        return -1

#Rail1 0x89 page0
#Rail2 0x89 page1
#READ_IIN 0x89 0.25A/LSB
def drv_read_iin_direct_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x89 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #0.25A/LSB IIN_PMBUS_LSB = 1 
    #print(output)
    mask_val = 0x7FF
    reg_val = int(output,16) & mask_val
    current_val = reg_val/4
    #print(current_val)
    if(ret == 0):
        #print("[drv_read_iin_direct_info] (%d-0x%x) iin=%d A." % (bus, addr, current_val))
        return(current_val)
    else:
        return -1

#Rail1 0x8B/0x21 page0
#Rail2 0x8B/0x21 page1
#READ_VOUT 0x8B 1mV/LSB1 
#VID step/LSB if VOUT_PMBUS_LSB = 1
#1mV/LSB if VOUT_PMBUS_LSB = 0
def drv_read_vout_direct_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x8B w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #1mV/LSB VOUT_PMBUS_LSB = 1 
    #print(output)
    mask_val = 0xFFF
    voltage_val = int(output,16) & mask_val
    #print(voltage_val)
    if(ret == 0):
        #print("[drv_read_vout_direct_info] (%d-0x%x) vout=%d mV." % (bus, addr, voltage_val))
        return(voltage_val)
    else:
        return -1

#Rail1 0x8C page0
#Rail2 0x8C page1
#READ_IOUT 0x8C 1A/LSB
def drv_read_iout_direct_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x8C w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #1A/LSB IOUT_PMBUS_LSB = 1 
    #print(output)
    mask_val = 0x7FF
    reg_val = int(output,16) & mask_val
    current_val = round(float(reg_val*0.0625), 2)
    #print(current_val)
    if(ret == 0):
        #print("[drv_read_iout_direct_info] (%d-0x%x) iout=%d A." % (bus, addr, current_val))
        return(current_val)
    else:
        return -1

#Rail1 0x96 page0
#Rail2 0x96 page1
#READ_POUT 0x96 1W/LSB
def drv_read_pout_direct_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x96 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #1W/LSB POUT_PMBUS_LSB = 1 
    #print(output)
    mask_val = 0x7FF
    power_val = (int(output,16) & mask_val) * 1000
    #print(power_val)
    if(ret == 0):
        #print("[drv_read_pout_direct_info] (%d-0x%x) pout=%d mW." % (bus, addr, power_val))
        return(power_val)
    else:
        return -1

#Rail1 0x97 page0
#Rail2 0x97 page1
#READ_PIN 0x97  1W/LSB.
def drv_read_pin_direct_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x97 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #1W/LSB PIN_PMBUS_LSB = 1 
    #print(output)
    mask_val = 0x7FF
    power_val = int(output,16) & mask_val
    #print(power_val)
    if(ret == 0):
        #print("[drv_read_pin_direct_info] (%d-0x%x) pin=%d W." % (bus, addr, power_val))
        return(power_val)
    else:
        return -1
###############################################################################################################################
#MPS MPS2891
#Rail1 0x88 page0
#Rail2 0x88 page1
#READ_VIN 0x88 31.25mV/LSB
def drv_read_vin_direct2_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x88 w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #0.25V/LSB VIN_PMBUS_LSB = 1 
    #print(output)
    mask_val = 0x3FF
    reg_val = int(output,16) & mask_val
    voltage_val = reg_val * 31.25
    print(voltage_val)
    if(ret == 0):
        #print("[drv_read_vin_direct2_info] (%d-0x%x) vin=%d mV." % (bus, addr, voltage_val))
        return(voltage_val)
    else:
        return -1

#Rail1 0x89 page0
#Rail2 0x89 page1
#READ_IIN MPS2891 Not Support

#Rail1 0x8B/0x21 page0
#Rail2 0x8B/0x21 page1
#READ_VOUT Vout=READ_VOUT(8Bh)*VID_STEP
#BDh bits [15:14] Reg_value=0x53f2 VID_STEP 5mV 
def drv_read_vout_direct2_info(bus, addr, rail):
    #Firs switch pages based on the rail
    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x8B w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #READ_VOUT(8Bh)*VID_STEP
    #print(output)
    mask_val = 0xFFF
    reg_val = int(output,16) & mask_val
    voltage_val = reg_val * 2.5
    #print(voltage_val)
    if(ret == 0):
        #print("[drv_read_vout_direct_info] (%d-0x%x) vout=%d mV." % (bus, addr, voltage_val))
        return(voltage_val)
    else:
        return -1

#Rail1 0x8C page0
#READ_IOUT 0x8C page0 IOUT_SCALE_BIT (bit[2:0], 65h, page0) Reg_value=0x001b  (1/8) A/LSB
# 3'b000: 1 A/LSB
# 3'b001: (1/32) A/LSB
# 3'b010: (1/16) A/LSB
# 3'b011: (1/8) A/LSB
# 3'b100: (1/4) A/LSB
# 3'b101: (1/2) A/LSB
# 3'b110: 1 A/LSB
# 3'b111: 2 A/LSB

#Rail2 0x8C page1 11bit linear mode data
def drv_read_iout_direct2_info(bus, addr, rail):
    #Firs switch pages based on the rail
    #Rail2 0x8C page1 11bit linear mode data
    # if rail == 2:
    #     current_val = drv_read_iout_linear11_info(bus, addr, rail)
    #     return current_val

    page = rail - 1
    # ret = drv_registers_page_set(bus, addr, page)
    # if ret != 0:
        # return -1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2cget -f -y %d 0x%x 0x8C w' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #(1/8) A/LSB
    #print(output)
    mask_val = 0x7FF
    reg_val = int(output,16) & mask_val
    current_val = round(float(reg_val*2), 2)
    #print(current_val)
    if(ret == 0):
        #print("[drv_read_iout_direct_info] (%d-0x%x) iout=%d A." % (bus, addr, current_val))
        return(current_val)
    else:
        return -1

#Rail1 0x96 page0
#Rail2 0x96 page1
#READ_POUT 0x96 Linear11 mode
#drv_read_pout_linear11_info

#Rail1 0x97 page0
#Rail2 0x97 page1
#READ_PIN 0x97 Linear11 mode
#drv_read_pin_linear11_info

###############################################################################################################################
#MPS 
#READ_VIN 0x88
def drv_read_vin_info(bus, addr, rail):
    mfr_model = drv_mps_mfr_model_get(bus, addr, 1)
    if mfr_model < 0:
        print("[drv_read_vin_info] (%d-0x%x) mfr_model=%d get failed." % (bus, addr, mfr_model))
        return -1
    if mfr_model != MP2985_MFR_MODEL:
        #MPS MPS2891
        voltage_val = drv_read_vin_direct2_info(bus, addr, rail)
    else:
        #MPS MPS2975
        voltage_val = drv_read_vin_direct_info(bus, addr, rail)
    return voltage_val

#READ_IIN 0x89
def drv_read_iin_info(bus, addr, rail):
    mfr_model = drv_mps_mfr_model_get(bus, addr, 1)
    if mfr_model < 0:
        print("[drv_read_iin_info] (%d-0x%x) mfr_model=%d get failed." % (bus, addr, mfr_model))
        return -1
    if mfr_model != MP2985_MFR_MODEL:
        #MPS MPS2891 READ_IIN Not Support
        current_val = 0
        print("[drv_read_iin_info] (%d-0x%x) mfr_model=%d not support READ_IIN." % (bus, addr, mfr_model))
    else:
        #MPS MPS2975
        current_val = drv_read_iin_direct_info(bus, addr, rail)
    return current_val

#READ_VOUT 0x8B 
def drv_read_vout_info(bus, addr, rail):
    mfr_model = drv_mps_mfr_model_get(bus, addr, 1)
    if mfr_model < 0:
        print("[drv_read_vout_info] (%d-0x%x) mfr_model=%d get failed." % (bus, addr, mfr_model))
        return -1
    if mfr_model != MP2985_MFR_MODEL:
        #MPS MPS2891
        voltage_val = drv_read_vout_direct2_info(bus, addr, rail)
    else:
        #MPS MPS2975
        voltage_val = drv_read_vout_direct_info(bus, addr, rail)
    return voltage_val 

#READ_IOUT 0x8C 
def drv_read_iout_info(bus, addr, rail):
    mfr_model = drv_mps_mfr_model_get(bus, addr, 1)
    if mfr_model < 0:
        print("[drv_read_iout_info] (%d-0x%x) mfr_model=%d get failed." % (bus, addr, mfr_model))
        return -1
    if mfr_model != MP2985_MFR_MODEL:
        #MPS MPS2891
        current_val = drv_read_iout_direct2_info(bus, addr, rail)
    else:
        #MPS MPS2975
        current_val = drv_read_iout_direct_info(bus, addr, rail)
    return current_val 

#READ_POUT 0x96
def drv_read_pout_info(bus, addr, rail):
    mfr_model = drv_mps_mfr_model_get(bus, addr, 1)
    if mfr_model < 0:
        print("[drv_read_pout_info] (%d-0x%x) mfr_model=%d get failed." % (bus, addr, mfr_model))
        return -1
    if mfr_model != MP2985_MFR_MODEL:
        #MPS MPS2891
        power_val = drv_read_pout_linear11_info(bus, addr, rail)
    else:
        #MPS MPS2975
        power_val = drv_read_pout_linear11_info(bus, addr, rail)
    return power_val 

#READ_PIN 0x97
def drv_read_pin_info(bus, addr, rail):
    mfr_model = drv_mps_mfr_model_get(bus, addr, 1)
    if mfr_model < 0:
        print("[drv_read_pin_info] (%d-0x%x) mfr_model=%d get failed." % (bus, addr, mfr_model))
        return -1
    if mfr_model != MP2985_MFR_MODEL:
        #MPS MPS2891
        power_val = drv_read_pin_linear11_info(bus, addr, rail)
    else:
        #MPS MPS2975
        power_val = drv_read_pin_direct_info(bus, addr, rail)
    return power_val 

###############################################################################################################################
##20251030 pin/vin/iin
def drv_asic_read_pin_read_by_vddname(vdd_name):
    name_result = 255
    for index in avs_voltage_address_all:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            power_val = drv_read_pin_info(bus, addr, rail)
            if(power_val == -1):
                print("The %s(%d-0x%x) get pin failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get pin:%d W." % (name, bus, addr, power_val))
    
    if(name_result != 0):
        print("The %s power can not find,To get pin failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_asic_read_pin_read_all():
    #print("drv_asic_read_pin_read_all")
    power_sum = 0
    for index in avs_voltage_address_all:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        power_val = drv_read_pin_info(bus, addr, rail)
        if(power_val == -1):
            print("The %s(%d-0x%x) get pin failed." % (name, bus, addr))
            continue
        else:
            power_sum = power_sum + power_val
            print("The %s(%d-0x%x) get pin:%d W." % (name, bus, addr, power_val))
    print("The total power:%d W." % (power_sum))
    return 0

def drv_asic_read_iin_read_by_vddname(vdd_name):
    name_result = 255
    for index in avs_voltage_address_all:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            current_val = drv_read_iin_info(bus, addr, rail)
            if(current_val == -1):
                print("The %s(%d-0x%x) get iin failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get iin:%d A." % (name, bus, addr, current_val))
    
    if(name_result != 0):
        print("The %s current can not find,To get iin failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_asic_read_iin_read_all():
    #print("drv_asic_read_iin_read_all")
    for index in avs_voltage_address_all:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        current_val = drv_read_iin_info(bus, addr, rail)
        if(current_val == -1):
            print("The %s(%d-0x%x) get iin failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get iin:%d A." % (name, bus, addr, current_val))
    return 0

def drv_asic_read_vin_read_by_vddname(vdd_name):
    name_result = 255
    for index in avs_voltage_address_all:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            voltage_val = drv_read_vin_info(bus, addr, rail)
            if(voltage_val == -1):
                print("The %s(%d-0x%x) get vin failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get vin:%d mV." % (name, bus, addr, voltage_val))
    
    if(name_result != 0):
        print("The %s current can not find,To get iin failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_asic_read_vin_read_all():
    #print("drv_asic_read_vin_read_all")
    for index in avs_voltage_address_all:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        voltage_val = drv_read_vin_info(bus, addr, rail)
        if(voltage_val == -1):
            print("The %s(%d-0x%x) get vin failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get vin:%d mV." % (name, bus, addr, voltage_val))
    return 0

def drv_asic_read_pout_read_by_vddname(vdd_name):
    name_result = 255
    for index in avs_voltage_address_all:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            power_val = drv_read_pout_info(bus, addr, rail)
            if(power_val == -1):
                print("The %s(%d-0x%x) get pout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get pout:%d mW." % (name, bus, addr, power_val))
    
    if(name_result != 0):
        print("The %s power can not find,To get pout failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_asic_read_pout_read_all():
    #print("drv_asic_read_pout_read_all")
    power_sum = 0
    for index in avs_voltage_address_all:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        power_val = drv_read_pout_info(bus, addr, rail)
        if(power_val == -1):
            print("The %s(%d-0x%x) get pout failed." % (name, bus, addr))
            continue
        else:
            power_sum = power_sum + power_val
            print("The %s(%d-0x%x) get pout:%d mW." % (name, bus, addr, power_val))
    print("The total power:%d mW." % (power_sum))
    return 0

def drv_asic_read_iout_read_by_vddname(vdd_name):
    name_result = 255
    for index in avs_voltage_address_all:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            current_val = drv_read_iout_info(bus, addr, rail)
            if(current_val == -1):
                print("The %s(%d-0x%x) get iout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get iout:%d A." % (name, bus, addr, current_val))
    
    if(name_result != 0):
        print("The %s current can not find,To get iout failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_asic_read_iout_read_all():
    #print("drv_asic_read_iout_read_all")
    for index in avs_voltage_address_all:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        current_val = drv_read_iout_info(bus, addr, rail)
        if(current_val == -1):
            print("The %s(%d-0x%x) get iout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get iout:%.2f A." % (name, bus, addr, current_val))
    return 0

def drv_asic_read_vout_read_by_vddname(vdd_name):
    name_result = 255
    for index in avs_voltage_address_all:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            voltage_val = drv_read_vout_info(bus, addr, rail)
            if(voltage_val == -1):
                print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get vout:%d mV." % (name, bus, addr, voltage_val))
    
    if(name_result != 0):
        print("The %s voltage can not find,To get vout failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_asic_read_vout_read_all():
    #print("drv_asic_read_vout_read_all")
    for index in avs_voltage_address_all:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        voltage_val = drv_read_vout_info(bus, addr, rail)
        if(voltage_val == -1):
            print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get vout:%d mV." % (name, bus, addr, voltage_val))
    return 0

###############################################################################################################################
#MPS VOUT_COMMAND 0x21
def drv_asic_voltage_vout_command_get_by_vddname(vdd_name):
    #print("drv_asic_voltage_vout_command_get_by_vddname")
    name_result = 255
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            voltage_val = drv_vout_command_vid_get(bus, addr, rail)
            if(voltage_val == -1):
                print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get vout:%d mV." % (name, bus, addr, voltage_val))
    
    if(name_result != 0):
        print("The %s voltage can not find,To get vout failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_asic_voltage_vout_command_get_all():
    #print("drv_asic_voltage_vout_command_get_all")
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        voltage_val = drv_vout_command_vid_get(bus, addr, rail)
        if(voltage_val == -1):
            print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get vout:%d mV." % (name, bus, addr, voltage_val))
    return 0

#Set VOUT_COMMAND 0x21
def drv_asic_voltage_set_by_vddname(vdd_name, file_name):
    #print("drv_asic_voltage_set_by_vddname")
    ret = -1
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        if(name != vdd_name):
            continue
        else:
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            cmd = 'cat %s | grep -iE "%s:" | awk \'{print $2}\'' %(file_name, name)
            #print(cmd)
            ret, output = getstatusoutput(cmd)
            print(output)
            if(ret == 0):
                if(len(output) == 0):
                    print("[drv_asic_voltage_set_by_vddname] The %s(%d-0x%x) can not find, set avs voltage failed." % (name, bus, addr))
                    return -1
            else:
                print("[drv_asic_voltage_set_by_vddname] The %s(%d-0x%x) find failed." % (name, bus, addr))
                return -1
            voltage_read_val = int(output)
            #g_voltage_level#high:1/standard:0/low:-1
            global g_voltage_level
            if(g_voltage_level == -1):
                voltage_val = int(voltage_read_val * 0.97)
            elif(g_voltage_level == 1):
                voltage_val = int(voltage_read_val * 1.03)
            else:
                voltage_val = voltage_read_val
            
            print("The drv_asic_voltage_set_by_vddname %s(%d-0x%x) set vout(%d) voltage_read_val(%d) g_voltage_level(%d)." % (name, bus, addr, voltage_val, voltage_read_val, g_voltage_level))
            
            ret = drv_vout_command_vid_set(bus, addr, rail, voltage_val)
            if(ret == -1):
                print("The %s(%d-0x%x) set vout(%d) failed." % (name, bus, addr, voltage_val))
                return -1
            global g_store_code_flag
            if(g_store_code_flag == STORE_CODE_FLAG):
                ret = drv_mps_mfr_vr_multi_config_vboot_set(bus, addr, rail, voltage_val)
                if(ret == -1):
                    print("The %s(%d-0x%x) set mfr_vr_multi_config vboot set failed." % (name, bus, addr))
                    return -1
                ret = drv_mps_store_normal_code(bus, addr, rail)
                if(ret == -1):
                    print("The %s(%d-0x%x) set store normal code failed." % (name, bus, addr))
                    return -1
    if(ret != 0):
        print("[drv_asic_voltage_set_by_vddname] The %s can not find in the %s, set avs voltage failed." % (vdd_name, file_name))
        return -1
    return 0

#cat asic_voltage_result | grep -iE "DVDD_CVB" | awk '{print $2}'
def drv_asic_voltage_set_all(file_name):
    #print("drv_asic_voltage_set_all")
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        die = index['die']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        # cmd = 'cat %s | grep -iE "%s:" | awk \'{print $2}\'' %(file_name, name)
        # #print(cmd)
        # ret, output = getstatusoutput(cmd)
        # print(output)
        # if(ret == 0):
        #     if(len(output) == 0):
        #         print("[drv_asic_voltage_set_all] The %s(%d-0x%x) can not find, set avs voltage failed." % (name, bus, addr))
        #         continue
        # else:
        #     print("[drv_asic_voltage_set_all] The %s(%d-0x%x) find failed." % (name, bus, addr))
        #     continue
        # voltage_read_val = int(output)
        voltage_read_val = get_voltage_from_file(file_name, name, die)
        if voltage_read_val is None:
            print("[...] The %s(%s) voltage not found in file." % (name, die))
            return -1
        #g_voltage_level#high:1/standard:0/low:-1
        global g_voltage_level
        if(g_voltage_level == -1):
            voltage_val = int(voltage_read_val * 0.97)
        elif(g_voltage_level == 1):
            voltage_val = int(voltage_read_val * 1.03)
        else:
            voltage_val = voltage_read_val

        print("The drv_asic_voltage_set_all %s(%d-0x%x) set vout(%d) voltage_read_val(%d) g_voltage_level(%d)." % (name, bus, addr, voltage_val, voltage_read_val, g_voltage_level))

        ret = drv_vout_command_vid_set(bus, addr, rail, voltage_val)
        time.sleep(0.1)
        if(ret == -1):
            print("The %s(%d-0x%x) set vout(%d) failed." % (name, bus, addr, voltage_val))
            continue
        global g_store_code_flag
        if(g_store_code_flag == STORE_CODE_FLAG):
            ret = drv_mps_mfr_vr_multi_config_vboot_set(bus, addr, rail, voltage_val)
            if(ret == -1):
                print("The %s(%d-0x%x) set mfr_vr_multi_config vboot set failed." % (name, bus, addr))
                continue
            ret = drv_mps_store_normal_code(bus, addr, rail)
            if(ret == -1):
                print("The %s(%d-0x%x) set store normal code failed." % (name, bus, addr))
                continue
    return 0

#Check VOUT_COMMAND 0x21
def drv_asic_voltage_check_by_vddname(vdd_name, file_name):
    #print("drv_asic_voltage_check_by_vddname")
    ret = -1
    global g_rev2_set_enable
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        if(name != vdd_name):
            continue
        else:
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            cmd = 'cat %s | grep -iE "%s:" | awk \'{print $2}\'' %(file_name, name)
            #print(cmd)
            ret, output = getstatusoutput(cmd)
            #print(output)
            if(ret == 0):
                if(len(output) == 0):
                    print("[drv_asic_voltage_check_by_vddname] The %s(%d-0x%x) can not find, check avs voltage failed." % (name, bus, addr))
                    return -1
            else:
                print("[drv_asic_voltage_check_by_vddname] The %s(%d-0x%x) find failed." % (name, bus, addr))
                return -1
            voltage_read_val = int(output)

            #g_voltage_level#high:1/standard:0/low:-1
            global g_voltage_level
            if(g_voltage_level == -1):
                voltage_val = int(voltage_read_val * 0.97)
            elif(g_voltage_level == 1):
                voltage_val = int(voltage_read_val * 1.03)
            else:
                voltage_val = voltage_read_val
            print("The drv_asic_voltage_check_by_vddname %s(%d-0x%x) check vout(%d) voltage_read_val(%d) g_voltage_level(%d)." % (name, bus, addr, voltage_val, voltage_read_val, g_voltage_level))

            vout_command_val = drv_vout_command_vid_get(bus, addr, rail)
            read_vout_val = drv_read_vout_info(bus, addr, rail)
            if((vout_command_val == -1) or (read_vout_val == -1)):
                print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
                return -1
            else:
                diff_value = vout_command_val - voltage_val
                diff_value1 = read_vout_val - voltage_val
                if((diff_value < -5) or (diff_value > 5) or (diff_value1 < -20) or (diff_value1 > 20)):
                    print("The %s(%d-0x%x) check vout(VOUT_COMMAND value:%d mV,READ_VOUT value:%d mV,verify:%d mV) failed." % (name, bus, addr, vout_command_val, read_vout_val, voltage_val))
                    return -1
                else:
                    print("The %s(%d-0x%x) check vout(VOUT_COMMAND value:%d mV,READ_VOUT value:%d mV,verify:%d mV) successed." % (name, bus, addr, vout_command_val, read_vout_val, voltage_val))
                    return 0
    if(ret != 0):
        print("[drv_asic_voltage_check_by_vddname] The %s can not find in the %s, check avs voltage failed." % (vdd_name, file_name))
        return -1

    return 0

def drv_asic_voltage_check_all(file_name):
    global g_rev2_set_enable
    print("drv_asic_voltage_check_all g_rev2_set_enable=%d" % (g_rev2_set_enable))
    for index in avs_voltage_address:
        name = index['name' if g_rev2_set_enable == 0 else 'name2']
        die = index['die']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        # cmd = 'cat %s | grep -iE "%s:" | awk \'{print $2}\'' %(file_name, name)
        # #print(cmd)
        # ret, output = getstatusoutput(cmd)
        # print(output)
        # if(ret == 0):
        #     if(len(output) == 0):
        #         print("[drv_asic_voltage_check_all] The %s(%d-0x%x) can not find, check avs voltage failed." % (name, bus, addr))
        #         continue
        # else:
        #     print("[drv_asic_voltage_check_all] The %s(%d-0x%x) find failed." % (name, bus, addr))
        #     continue
        # voltage_read_val = int(output)
        voltage_read_val = get_voltage_from_file(file_name, name, die)
        if voltage_read_val is None:
            print("[...] The %s(%s) voltage not found in file." % (name, die))
            return -1
        #g_voltage_level#high:1/standard:0/low:-1
        global g_voltage_level
        if(g_voltage_level == -1):
            voltage_val = int(voltage_read_val * 0.97)
        elif(g_voltage_level == 1):
            voltage_val = int(voltage_read_val * 1.03)
        else:
            voltage_val = voltage_read_val
        
        print("The drv_asic_voltage_check_all %s(%d-0x%x) check vout(%d) voltage_read_val(%d) g_voltage_level(%d)." % (name, bus, addr, voltage_val, voltage_read_val, g_voltage_level))
        
        vout_command_val = drv_vout_command_vid_get(bus, addr, rail)
        read_vout_val = drv_read_vout_info(bus, addr, rail)
        if((vout_command_val == -1) or (read_vout_val == -1)):
            print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
            continue
        else:
            diff_value = vout_command_val - voltage_val
            diff_value1 = read_vout_val - voltage_val
            if((diff_value < -5) or (diff_value > 5) or (diff_value1 < -20) or (diff_value1 > 20)):
                print("The %s(%d-0x%x) check vout(VOUT_COMMAND value:%d mV,READ_VOUT value:%d mV,verify:%d mV) failed." % (name, bus, addr, vout_command_val, read_vout_val, voltage_val))
                continue
            else:
                print("The %s(%d-0x%x) check vout(VOUT_COMMAND value:%d mV,READ_VOUT value:%d mV,verify:%d mV) successed." % (name, bus, addr, vout_command_val, read_vout_val, voltage_val))
    return 0

###############################################################################################################################
###############################################################################################################################
##20501030 add PIN/VIN/IIN
def drv_osfp_read_pin_read_by_vddname(vdd_name):
    name_result = 255
    for index in osfp_voltage_address:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            power_val = drv_read_pin_linear11_info(bus, addr, rail)
            if(power_val == -1):
                print("The %s(%d-0x%x) get pin failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get pin:%d mW." % (name, bus, addr, power_val))
    
    if(name_result != 0):
        print("The %s power can not find,To get pin failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_osfp_read_pin_read_all():
    #print("drv_asic_read_pin_read_all")
    power_sum = 0
    for index in osfp_voltage_address:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        power_val = drv_read_pin_linear11_info(bus, addr, rail)
        if(power_val == -1):
            print("The %s(%d-0x%x) get pin failed." % (name, bus, addr))
            continue
        else:
            power_sum = power_sum + power_val
            print("The %s(%d-0x%x) get pin:%d mW." % (name, bus, addr, power_val))
    print("The total power:%d mW." % (power_sum))
    return 0

def drv_osfp_read_iin_read_by_vddname(vdd_name):
    name_result = 255
    for index in osfp_voltage_address:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            current_val = drv_read_iin_linear11_info(bus, addr, rail)
            if(current_val == -1):
                print("The %s(%d-0x%x) get iin failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get iin:%d mA." % (name, bus, addr, current_val))
    
    if(name_result != 0):
        print("The %s current can not find,To get iin failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_osfp_read_iin_read_all():
    #print("drv_osfp_read_iin_read_all")
    for index in osfp_voltage_address:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        current_val = drv_read_iin_linear11_info(bus, addr, rail)
        if(current_val == -1):
            print("The %s(%d-0x%x) get iin failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get iin:%d mA." % (name, bus, addr, current_val))
    return 0

def drv_osfp_read_vin_read_by_vddname(vdd_name):
    name_result = 255
    for index in osfp_voltage_address:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            voltage_val = drv_read_vin_linear11_info(bus, addr, rail)
            if(voltage_val == -1):
                print("The %s(%d-0x%x) get vin failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get vin:%d mV." % (name, bus, addr, voltage_val))
    
    if(name_result != 0):
        print("The %s current can not find,To get iin failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_osfp_read_vin_read_all():
    #print("drv_osfp_read_vin_read_all")
    for index in osfp_voltage_address:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        voltage_val = drv_read_vin_linear11_info(bus, addr, rail)
        if(voltage_val == -1):
            print("The %s(%d-0x%x) get vin failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get vin:%d mV." % (name, bus, addr, voltage_val))
    return 0

###############################################################################################################################
#VOUT/IOUT/POUT
def drv_osfp_read_pout_read_by_vddname(vdd_name):
    name_result = 255
    for index in osfp_voltage_address:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            power_val = drv_read_pout_linear11_info(bus, addr, rail)
            if(power_val == -1):
                print("The %s(%d-0x%x) get pout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get pout:%d mW." % (name, bus, addr, power_val))
    
    if(name_result != 0):
        print("The %s power can not find,To get pout failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_osfp_read_pout_read_all():
    #print("drv_osfp_read_pout_read_all")
    power_sum = 0
    for index in osfp_voltage_address:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        power_val = drv_read_pout_linear11_info(bus, addr, rail)
        if(power_val == -1):
            print("The %s(%d-0x%x) get pout failed." % (name, bus, addr))
            continue
        else:
            power_sum = power_sum + power_val
            print("The %s(%d-0x%x) get pout:%d mW." % (name, bus, addr, power_val))
    print("The total power:%d mW." % (power_sum))
    return 0

def drv_osfp_read_iout_read_by_vddname(vdd_name):
    name_result = 255
    for index in osfp_voltage_address:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            current_val = drv_read_iout_linear11_info(bus, addr, rail)
            if(current_val == -1):
                print("The %s(%d-0x%x) get iout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get iout:%d mA." % (name, bus, addr, current_val))
    
    if(name_result != 0):
        print("The %s current can not find,To get iout failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_osfp_read_iout_read_all():
    #print("drv_asic_read_iout_read_all")
    for index in osfp_voltage_address:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        current_val = drv_read_iout_linear11_info(bus, addr, rail)
        if(current_val == -1):
            print("The %s(%d-0x%x) get iout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get iout:%d mA." % (name, bus, addr, current_val))
    return 0

def drv_osfp_read_vout_read_by_vddname(vdd_name):
    name_result = 255
    for index in osfp_voltage_address:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            voltage_val = drv_read_vout_linear16_info(bus, addr, rail)
            if(voltage_val == -1):
                print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get vout:%d mV." % (name, bus, addr, voltage_val))
    
    if(name_result != 0):
        print("The %s voltage can not find,To get vout failed." % (vdd_name))
        return -1
    else:
        return 0

def drv_osfp_read_vout_read_all():
    #print("drv_osfp_read_vout_read_all")
    for index in osfp_voltage_address:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        voltage_val = drv_read_vout_linear16_info(bus, addr, rail)
        if(voltage_val == -1):
            print("The %s(%d-0x%x) get vout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get vout:%d mV." % (name, bus, addr, voltage_val))
    return 0
###############################################################################################################################
#systemctl stop cpumon.service
#systemctl stop powermon.service
#systemctl stop fanctrl.service
#systemctl stop dcdcmon.service
#systemctl stop restful.service
arr_info = ['cpumon.service','powermon.service','fanctrl.service','dcdcmon.service','restful.service']
def drv_platform_service_opt(opt):
    for index in arr_info:
        if (opt == 0):
            cmd = 'systemctl stop %s' % (index)
        else:
            cmd = 'systemctl restart %s' % (index)
        print(cmd)
        ret = 0
        ret, output = getstatusoutput(cmd)
        if(ret == 0):
            print("[drv_platform_service_opt] The %s opt successed." % (index))
        else:
            print("[drv_platform_service_opt] The %s opt failed." % (index))
            return -1
        time.sleep(0.1)
    return 0

def drv_fuses_rev2_type_get(file_name):
    name = 'REV2_SET_ENABLE'
    if not os.path.exists(file_name):
        print("Error: The (%s) does not exist." % (file_name))
        return -1

    cmd = 'cat %s | grep -iE "%s:" | awk \'{print $2}\'' %(file_name, name)
    try:
        ret = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, timeout=5)
        output = ret.stdout.strip()
        if ret.returncode != 0:
            print("[drv_fuses_rev2_type_get] It cannot find %s in the %s (output=%s)." % (name, file_name, output))
            return -1
        global g_rev2_set_enable
        g_rev2_set_enable = int(output, 16)
        print("[drv_fuses_rev2_type_get] g_rev2_set_enable=%d ." % (g_rev2_set_enable))
        return 0
    except Exception as e:
        print("[drv_fuses_rev2_type_get] exception: %s" % str(e))
        return -1

def drv_asic_voltage_usage():
    print("Usage: ")
    print("./diag_asic_voltage.py read <VDD_Name/all/qsfp> <vout/iout/pout/vin/iin/pin>")
    print("./diag_asic_voltage.py get <VDD_Name/all>")
    print("./diag_asic_voltage.py set <VDD name/all> <file name> <voltage level> <write option>")
    print("./diag_asic_voltage.py check <VDD name/all> <file name> <voltage level>")
    print("The VDD name:")
    print("VDD_PVS_MBIN/DVDD_CVB/VDD_PVS_MBIN_TILE_0/DVDD_CVB_TILE_0/VDD_PVS_MBIN_TILE_1/DVDD_CVB_TILE_1/VDD_PVS_MBIN_TILE_2/DVDD_CVB_TILE_2/VDD_PVS_MBIN_TILE_3")
    print("DVDD_CVB_TILE_3/VDD_PVS_MBIN_TILE_4/DVDD_CVB_TILE_4/VDD_PVS_MBIN_TILE_5/DVDD_CVB_TILE_5/VDD_PVS_MBIN_TILE_6/DVDD_CVB_TILE_6/VDD_PVS_MBIN_TILE_7/DVDD_CVB_TILE_7")
    print("The VDD REV2 name:")
    print("VDD_PVS_MBIN_REV2/DVDD_CVB_REV2/VDD_PVS_MBIN_REV2_TILE_0/DVDD_CVB_REV2_TILE_0/VDD_PVS_MBIN_REV2_TILE_1/DVDD_CVB_REV2_TILE_1/VDD_PVS_MBIN_REV2_TILE_2/DVDD_CVB_REV2_TILE_2/VDD_PVS_MBIN_REV2_TILE_3")
    print("DVDD_CVB_REV2_TILE_3/VDD_PVS_MBIN_REV2_TILE_4/DVDD_CVB_REV2_TILE_4/VDD_PVS_MBIN_REV2_TILE_5/DVDD_CVB_TILE_REV2_5/VDD_PVS_MBIN_REV2_TILE_6/DVDD_CVB_REV2_TILE_6/VDD_PVS_MBIN_REV2_TILE_7/DVDD_CVB_REV2_TILE_7")
    print("VDDSCC/HVDD_T03/HVDD_T47")
    print("The Voltage Level:")
    print("high/standard/low")
    print("The write to OTP options:")
    print("write/others")
    print("Note: The read/get only support the VDD name")
    return 0

def main(argv):
    global g_voltage_level
    global g_store_code_flag
    if len(sys.argv) == 3 :
        Operation = argv[1];
        vdd_name = argv[2];
    elif len(sys.argv) == 4 :
        Operation = argv[1];
        vdd_name = argv[2];
        file_name = argv[3];
    elif len(sys.argv) == 5 :
        Operation = argv[1];
        vdd_name = argv[2];
        file_name = argv[3];
        voltage_level = argv[4];
        if (Operation != 'set') and (Operation != 'get') and (Operation != 'check'):
            print("The parameter error")
            drv_asic_voltage_usage()
            return -1
        # ret = drv_fuses_rev2_type_get(file_name)
        # if ret != 0:
        #     print("Error: drv_fuses_rev2_type_get(%s) failed with return code: %d" % (file_name, ret))
        #     return -1
        #Add voltage level set/check
        if (voltage_level == 'high'):
            g_voltage_level = 1
        elif (voltage_level == 'low'):
            g_voltage_level = -1
        else:
            g_voltage_level = 0
    elif len(sys.argv) == 6 :
        Operation = argv[1];
        vdd_name = argv[2];
        file_name = argv[3];
        voltage_level = argv[4];
        if (Operation != 'set'):
            print("The parameter error")
            drv_asic_voltage_usage()
        #voltage level set
        if (voltage_level == 'high'):
            g_voltage_level = 1
        elif (voltage_level == 'low'):
            g_voltage_level = -1
        else:
            g_voltage_level = 0
        #store user code write flag
        write_flag = argv[5];
        if (write_flag == 'write'):
            g_store_code_flag = STORE_CODE_FLAG
        else:
            g_store_code_flag = 0
    else:
        drv_asic_voltage_usage()
        return -1

    if (Operation == 'set'):
        if (vdd_name == 'all'):
            drv_platform_service_opt(0)
            drv_asic_voltage_set_all(file_name)
            drv_platform_service_opt(1)
        else:
            drv_asic_voltage_set_by_vddname(vdd_name, file_name)
    elif (Operation == 'get'):
        if (vdd_name == 'all'):
            drv_asic_voltage_vout_command_get_all()
        else:
            drv_asic_voltage_vout_command_get_by_vddname(vdd_name)
    elif (Operation == 'check'):
        if (vdd_name == 'all'):
            drv_platform_service_opt(0)
            drv_asic_voltage_check_all(file_name)
            drv_platform_service_opt(1)
        else:
            drv_asic_voltage_check_by_vddname(vdd_name, file_name)
    elif (Operation == 'read'):
        if (vdd_name == 'all'):
            if (file_name == 'vout'):
                drv_asic_read_vout_read_all()
            elif  (file_name == 'iout'):
                drv_asic_read_iout_read_all()
            elif  (file_name == 'pout'):
                drv_asic_read_pout_read_all()
            elif  (file_name == 'vin'):
                drv_asic_read_vin_read_all()
            elif  (file_name == 'iin'):
                drv_asic_read_iin_read_all()
            elif  (file_name == 'pin'):
                drv_asic_read_pin_read_all()
        elif (vdd_name == 'osfp'):
            if (file_name == 'vout'):
                drv_osfp_read_vout_read_all()
            elif  (file_name == 'iout'):
                drv_osfp_read_iout_read_all()
            elif  (file_name == 'pout'):
                drv_osfp_read_pout_read_all()
            elif  (file_name == 'vin'):
                drv_osfp_read_vin_read_all()
            elif  (file_name == 'iin'):
                drv_osfp_read_iin_read_all()
            elif  (file_name == 'pin'):
                drv_osfp_read_pin_read_all()
        else:
            if (file_name == 'vout'):
                drv_asic_read_vout_read_by_vddname(vdd_name)
            elif  (file_name == 'iout'):
                drv_asic_read_iout_read_by_vddname(vdd_name)
            elif  (file_name == 'pout'):
                drv_asic_read_pout_read_by_vddname(vdd_name)
            elif (file_name == 'vin'):
                drv_asic_read_vin_read_by_vddname(vdd_name)
            elif  (file_name == 'iin'):
                drv_asic_read_iin_read_by_vddname(vdd_name)
            elif  (file_name == 'pin'):
                drv_asic_read_pin_read_by_vddname(vdd_name)
    else:
        print("The parameter error")
        drv_asic_voltage_usage()
        return -1
    return 0

if __name__ == '__main__':
    main(sys.argv)

