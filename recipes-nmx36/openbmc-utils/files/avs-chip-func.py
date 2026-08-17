#!/usr/bin/env python

try:
    import os
    import sys
    import subprocess
    import signal
    import time
    import math
    import logging
    import threading
    #import logging.config
except ImportError as e:
    raise ImportError('%s - required module not found' % str(e))

def log_info_init():
    log_dir = "/var/log"
    log_file_path = os.path.join(log_dir, "avs_current_monitor.log")
    
    logging.basicConfig(
        level=logging.INFO,
        filename=log_file_path,
        filemode='a',
        format='%(asctime)s - %(levelname)s - %(message)s'  # Log message format
    )

def get_product_model():
    try:
        ret, output = getstatusoutput("cat /etc/openbmc/product_name")
        if ret == 0:
            return output.strip()
    except Exception as e:
        logging.error(f"Get product name fail: {e}")
    return "UNKNOWN"
###############################################################################
FUNCTION_NAME = 'diag_asic_voltage'
LINEAR11_MASK=0x7FF
ULINEAR16_MASK=0xFFFF
STORE_CODE_FLAG=0x321
g_voltage_level = 0 #high:1/standard:0/low:-1
g_store_code_flag = 0


#To Read phase Iout info
multiphase_iout_info_as42_64s_at  = [
                         {'name':'SWITCH_C0_VDDC',            'bus':41, 'addr':0x60, 'rail':1, 'ph_cnt':8,  'LowThd':-2, 'HighThd':47},#LOOPA:8相
                         {'name':'SWITCH_C3_VDDC(0.7V)',      'bus':41, 'addr':0x60, 'rail':2, 'ph_cnt':8,  'LowThd':-2, 'HighThd':45},#LOOPB:8相
                         {'name':'SWITCH_VDDC',               'bus':40, 'addr':0x62, 'rail':1, 'ph_cnt':10, 'LowThd':-2, 'HighThd':40},#LOOPA:10相
                         {'name':'SWITCH_HBM_VDD',            'bus':40, 'addr':0x62, 'rail':2, 'ph_cnt':2,  'LowThd':-2, 'HighThd':40},#LOOPB:2相
                         {'name':'SWITCH_C12_IFG_VDDS',       'bus':43, 'addr':0x64, 'rail':1, 'ph_cnt':4,  'LowThd':-2, 'HighThd':40},#LOOPA:4相
                         {'name':'SWITCH_IFG_VDDA',           'bus':43, 'addr':0x64, 'rail':2, 'ph_cnt':4,  'LowThd':-2, 'HighThd':35},#LOOPB:4相
                         {'name':'SWITCH_C03_IFG_VDDS',       'bus':42, 'addr':0x66, 'rail':1, 'ph_cnt':4,  'LowThd':-2, 'HighThd':40},#LOOPA:4相
                         {'name':'SWITCH_IFG_VDDM',           'bus':42, 'addr':0x66, 'rail':2, 'ph_cnt':2,  'LowThd':-2, 'HighThd':45},#LOOPB:2相
                         {'name':'VCC3V3_QSFP1',              'bus':44, 'addr':0x68, 'rail':1, 'ph_cnt':4,  'LowThd':-2, 'HighThd':40},#LOOPA:4相
                         {'name':'VCC3V3_QSFP2',              'bus':45, 'addr':0x6A, 'rail':1, 'ph_cnt':4,  'LowThd':-2, 'HighThd':40},#LOOPA:4相
                         {'name':'D2D_VDDA',                  'bus':45, 'addr':0x6A, 'rail':2, 'ph_cnt':2,  'LowThd':-2, 'HighThd':40},#LOOPB:2相
                         {'name':'SWITCH_C2_VDDC',            'bus':46, 'addr':0x6C, 'rail':1, 'ph_cnt':8,  'LowThd':-2, 'HighThd':47},#LOOPA:8相
                         {'name':'SWITCH_C1_VDDC',            'bus':46, 'addr':0x6C, 'rail':2, 'ph_cnt':8,  'LowThd':-2, 'HighThd':47},#LOOPB:8相
                         {'name':'VCC3V3_QSFP1(line)',        'bus':57, 'addr':0x70, 'rail':1, 'ph_cnt':3,  'LowThd':-2, 'HighThd':30},#LOOPA:3相
                         {'name':'VCC3V3_QSFP2(line)',        'bus':57, 'addr':0x70, 'rail':2, 'ph_cnt':3,  'LowThd':-2, 'HighThd':30}]#LOOPB:3相

PRODUCT_CONFIG_MAP = {
    "AS42-64S-AT": multiphase_iout_info_as42_64s_at,
}
#To Read ASIC Vol/Iout/Pout info
singlephase_iout_info = []
###############################################################################
command_lock = threading.Lock()
def getstatusoutput(cmd):
    with command_lock:
        if sys.version_info.major == 2:
            # python2
            import commands
            status, output = commands.getstatusoutput(cmd)
        else:
            # python3
            status, output = subprocess.getstatusoutput(cmd)

    return status, output

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

def hex_to_signed_int(hex_value, bits=16):
    signed_value = 0
    if isinstance(hex_value, str):
        unsigned_value = int(hex_value,16)
    else:
        unsigned_value = hex_value

    sign_bit = (unsigned_value) >> (bits -1)
    if sign_bit == 1:
        mask = (1 << bits) - 1 
        signed_value = -((~unsigned_value + 1) & mask)
    else:
        signed_value = unsigned_value
    print("hex_to_signed_int unsigned_value=0x%x, signed_value=%d ." % (unsigned_value, signed_value))
    return(signed_value)
###############################################################################################################################
###############################################################################################################################
g_LowThd = 0
g_HighThd = 0
MOD0_PHASE_MAP_REG = 0x70000C04
MOD1_PHASE_MAP_REG = 0x70001004
MOD0_PHASE_MAP_MASK = 0x000000ff #bit0->bit7 === ph1->ph7
MOD1_PHASE_MAP_MASK = 0x000000ff #bit7->bit0 === ph1->ph7

def drv_avs_phase_iout_cnt_get(bus, addr, rail):
    #print("drv_avs_phase_iout_cnt_get")
    #Firs switch pages based on the rail
    page = rail - 1
    if(page == 0):
        reg_addr = MOD0_PHASE_MAP_REG
        PHASE_MAP_MASK = MOD0_PHASE_MAP_MASK
    else:
        reg_addr = MOD1_PHASE_MAP_REG
        PHASE_MAP_MASK = MOD1_PHASE_MAP_MASK

    # 0x000000C7 -> 0x0c 0x00 0x00 0x00
    addrs_list = []
    for i in range(4):
        byte_value = (reg_addr >> (i * 8)) & 0xFF
        addrs_list.append(byte_value)
    #Python ≥ 3.6 #address_str = ' '.join([f"0x{b:02x}" for b in addrs_list])
    address_str = ' '.join(["0x%02x" % b for b in addrs_list])
    #address_str = ' '.join(["0x{:02x}".format(b) for b in addrs_list])
    # Read
    cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s' % (bus, addr, page, bus, addr, address_str)
    cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w1@0x%x 0xdf r5' % (bus, addr, page, bus, addr)
    cmd = '%s;%s' % (cmd1, cmd2)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    # 0x04: 0x00 0x04 0x00 0xba -> 0xba000400
    arr_info = output.split()[1:]
    #print("output=%s arr_info=%s)" % (output, arr_info))
    regval_32bit = 0
    for i, byte in enumerate(arr_info):
        regval_32bit |= int(byte, 16) << (i * 8)

    # 0xba000400 -> 0x8a000400
    regval_wr_32bit = regval_32bit & (PHASE_MAP_MASK)

    n = regval_wr_32bit
    count = 0
    while n:
        count += n & 1
        n >>= 1
    print("drv_avs_phase_iout_cnt_get : regval_32bit=0x%x, regval_wr_32bit=0x%x, count=%d)" % (regval_32bit, regval_wr_32bit,count))

    return count

# All_Phase_Count = 8 LoopA 4 + LoopB 4
# IPH_ADC_LPF_REG = 0x7000746C  -- LoopB Phase1 | LoopB Phase2

# All_Phase_Count = 12 LoopA 6 + LoopB 6
# IPH_ADC_LPF_REG = 0x70007460   -- LoopA Phase2 | LoopA Phase1
# ....
# IPH_ADC_LPF_REG = 0x70007474  -- LoopB Phase1 | LoopB Phase2

# All_Phase_Count = 16 LoopA 8 + LoopB 8
# IPH_ADC_LPF_REG1 = 0x70007460   -- LoopA Phase2 | LoopA Phase1
# IPH_ADC_LPF_REG2 = 0x70007464
# IPH_ADC_LPF_REG3 = 0x70007468
# IPH_ADC_LPF_REG4 = 0x7000746C
# IPH_ADC_LPF_REG5 = 0x70007470
# IPH_ADC_LPF_REG6 = 0x70007474
# IPH_ADC_LPF_REG7 = 0x70007478
# IPH_ADC_LPF_REG8 = 0x7000747C  -- LoopB Phase1 | LoopB Phase2

IPH_LPF_IOUT_ODD =  0x00003FFF
IPH_LPF_IOUT_EVEN = 0x0FFFC000
IOUT_VALUE_STEP = 0.021875

def drv_avs_phase_iout_read(bus, addr, rail, count):
    print("drv_avs_phase_iout_read")
    #Firs switch pages based on the rail
    page = 0
    ret_val = 0
    # read phase_iout_cnt
    #count = drv_avs_phase_iout_cnt_get(bus, addr, rail)
    iph_iout_sum = 0
    regval_32bit = 0
    if(rail == 1):
        IPH_ADC_LPF_REG_LOOPA = 0x70007460
        for j in range(int(count)):
            if((j + 1) % 2 != 0):
                Reg_Addr = IPH_ADC_LPF_REG_LOOPA + ((j // 2) * 4)
                #print("Reg_Addr=0x%x )" % (Reg_Addr))
                addrs_list = []
                for i in range(4):
                    byte_value = (Reg_Addr >> (i * 8)) & 0xFF
                    addrs_list.append(byte_value)
                
                address_str = ' '.join(["0x%02x" % b for b in addrs_list])
                # Read
                cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s' % (bus, addr, page, bus, addr, address_str)
                cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w1@0x%x 0xdf r5' % (bus, addr, page, bus, addr)
                cmd  = '%s;%s' % (cmd1, cmd2)
                print(cmd)
                ret, output = getstatusoutput(cmd)
                ret_val |= ret
                # 0x04: 0x00 0x04 0x00 0xba -> 0xba000400
                arr_info = output.split()[1:]
                regval_32bit = 0
                for i, byte in enumerate(arr_info):
                    regval_32bit |= int(byte, 16) << (i * 8)
        
                int_Value = hex_to_signed_int((regval_32bit & (IPH_LPF_IOUT_ODD)), 14)
                iph_IOUT_Value = int_Value * IOUT_VALUE_STEP
            else:
                int_Value = hex_to_signed_int(((regval_32bit & IPH_LPF_IOUT_EVEN) >> 14), 14)
                iph_IOUT_Value = int_Value * IOUT_VALUE_STEP
        
            iph_IOUT_Value = round(iph_IOUT_Value, 2)
            iph_iout_sum = iph_iout_sum + iph_IOUT_Value
        
            print("The(%d-0x%x) get loop%d-phase%d iout=%0.2f, output=%s, regval_32bit=0x%x." % (bus, addr, rail, (j+1), iph_IOUT_Value, output, regval_32bit))
    elif(rail == 2):
        if 1 <= count <= 4:
            IPH_ADC_LPF_REG_LOOPB = 0x7000746C
        elif 5 <= count <= 6:
            IPH_ADC_LPF_REG_LOOPB = 0x70007474
        else:
            IPH_ADC_LPF_REG_LOOPB = 0x7000747C
        for j in range(int(count)):
            if((j + 1) % 2 != 0):
                Reg_Addr = IPH_ADC_LPF_REG_LOOPB - ((j // 2) * 4)
                #print("Reg_Addr=0x%x )" % (Reg_Addr))
                addrs_list = []
                for i in range(4):
                    byte_value = (Reg_Addr >> (i * 8)) & 0xFF
                    addrs_list.append(byte_value)
                
                address_str = ' '.join(["0x%02x" % b for b in addrs_list])
                # Read
                cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s' % (bus, addr, page, bus, addr, address_str)
                cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w1@0x%x 0xdf r5' % (bus, addr, page, bus, addr)
                cmd  = '%s;%s' % (cmd1, cmd2)
                print(cmd)
                ret, output = getstatusoutput(cmd)
                ret_val |= ret
                # 0x04: 0x00 0x04 0x00 0xba -> 0xba000400
                arr_info = output.split()[1:]
                regval_32bit = 0
                for i, byte in enumerate(arr_info):
                    regval_32bit |= int(byte, 16) << (i * 8)
                int_Value = hex_to_signed_int(((regval_32bit & IPH_LPF_IOUT_EVEN) >> 14), 14)
                iph_IOUT_Value = int_Value * IOUT_VALUE_STEP

            else:
                int_Value = hex_to_signed_int((regval_32bit & (IPH_LPF_IOUT_ODD)), 14)
                iph_IOUT_Value = int_Value * IOUT_VALUE_STEP
        
            iph_IOUT_Value = round(iph_IOUT_Value, 2)
            iph_iout_sum = iph_iout_sum + iph_IOUT_Value
        
            print("The(%d-0x%x) get loop%d-phase%d iout=%0.2f, output=%s, regval_32bit=0x%x." % (bus, addr, rail, (j+1), iph_IOUT_Value, output, regval_32bit))

    print("The(%d-0x%x) get iph_iout_sum iout=%0.2f ." % (bus, addr, iph_iout_sum))
    return ret_val

def drv_read_iout_info(bus, addr, rail):
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
        #print("[drv_read_iout_info] (%d-0x%x) iout=%d mA." % (bus, addr, current_val))
        return(current_val)
    else:
        return -1

def drv_avs_phase_iout_read_by_vddname(vdd_name):
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    name_result = 255
    for index in phase_iout_info:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            count = index['ph_cnt']
            ret_val = drv_avs_phase_iout_read(bus, addr, rail, count)
            if(ret_val == -1):
                print("The %s(%d-0x%x) get phase iout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get phase iout passed." % (name, bus, addr))
    
    if(name_result != 0):
        print("The %s can not find,To get phase iout failed." % (name))
        return -1
    else:
        return 0

def drv_avs_phase_iout_read_multiphase():
    for index in multiphase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        count = index['ph_cnt']
        ret_val = drv_avs_phase_iout_read(bus, addr, rail, count)
        if(ret_val == -1):
            print("The %s(%d-0x%x) get phase iout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get phase iout passed." % (name, bus, addr))
    return 0

def drv_avs_phase_iout_read_singlephase():
    for index in singlephase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        current_val = drv_read_iout_info(bus, addr, rail)
        if(current_val == -1):
            print("The %s(%d-0x%x) get phase iout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get phase iout passed(%d mA)." % (name, bus, addr, current_val))
    return 0

def drv_avs_phase_iout_read_all():
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        count = index['ph_cnt']
        ret_val = drv_avs_phase_iout_read(bus, addr, rail, count)
        if(ret_val == -1):
            print("The %s(%d-0x%x) get phase iout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get phase iout passed." % (name, bus, addr))
    return 0


###############################################################################################################################
def drv_avs_phase_iout_check(bus, addr, rail, count):
    print("drv_avs_phase_iout_check")
    ret_val = 0
    #Firs switch pages based on the rail
    page = 0
    # read phase_iout_cnt
    #count = drv_avs_phase_iout_cnt_get(bus, addr, rail)
    iph_iout_sum = 0
    regval_32bit = 0
    global g_LowThd
    global g_HighThd
    if(rail == 1):
        IPH_ADC_LPF_REG_LOOPA = 0x70007460
        for j in range(int(count)):
            if((j+1)%2 != 0):
                Reg_Addr = IPH_ADC_LPF_REG_LOOPA + ((j // 2) * 4)
                #print("Reg_Addr=0x%x )" % (Reg_Addr))
                addrs_list = []
                for i in range(4):
                    byte_value = (Reg_Addr >> (i * 8)) & 0xFF
                    addrs_list.append(byte_value)
                
                address_str = ' '.join(["0x%02x" % b for b in addrs_list])
                # Read
                cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s' % (bus, addr, page, bus, addr, address_str)
                cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w1@0x%x 0xdf r5' % (bus, addr, page, bus, addr)
                cmd = '%s;%s' % (cmd1, cmd2)
                print(cmd)
                ret, output = getstatusoutput(cmd)
                ret_val |= ret
                # 0x04: 0x00 0x04 0x00 0xba -> 0xba000400
                arr_info = output.split()[1:]
                regval_32bit = 0
                for i, byte in enumerate(arr_info):
                    regval_32bit |= int(byte, 16) << (i * 8)
        
                int_Value = hex_to_signed_int((regval_32bit & (IPH_LPF_IOUT_ODD)), 14)
                iph_IOUT_Value = int_Value * IOUT_VALUE_STEP
            else:
                int_Value = hex_to_signed_int(((regval_32bit & IPH_LPF_IOUT_EVEN) >> 14), 14)
                iph_IOUT_Value = int_Value * IOUT_VALUE_STEP
        
            iph_IOUT_Value = round(iph_IOUT_Value, 2)
            iph_iout_sum = iph_iout_sum + iph_IOUT_Value
            if ((iph_IOUT_Value < g_LowThd) or (iph_IOUT_Value > g_HighThd)):
                ret_val |= -1
                logging.error("The(%d-0x%x) loop%d-phase%d iout check failed, The IOUT %0.2f outside the range [%d, %d] (output=%s, Reg_value=0x%x)." % (bus, addr, rail, (j+1), iph_IOUT_Value, g_LowThd, g_HighThd, output, regval_32bit))
            else:
                logging.info("The(%d-0x%x) loop%d-phase%d iout check passed, The IOUT %0.2f inside the range [%d, %d] (output=%s, Reg_value=0x%x)." % (bus, addr, rail, (j+1), iph_IOUT_Value, g_LowThd, g_HighThd, output, regval_32bit))
    elif(rail == 2):
        if 1 <= count <= 4:
            IPH_ADC_LPF_REG_LOOPB = 0x7000746C
        elif 5 <= count <= 6:
            IPH_ADC_LPF_REG_LOOPB = 0x70007474
        else:
            IPH_ADC_LPF_REG_LOOPB = 0x7000747C

        for j in range(int(count)):
            if((j+1)%2 != 0):
                Reg_Addr = IPH_ADC_LPF_REG_LOOPB - ((j // 2) * 4)
                #print("Reg_Addr=0x%x )" % (Reg_Addr))
                addrs_list = []
                for i in range(4):
                    byte_value = (Reg_Addr >> (i * 8)) & 0xFF
                    addrs_list.append(byte_value)
                
                address_str = ' '.join(["0x%02x" % b for b in addrs_list])
                # Read
                cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s' % (bus, addr, page, bus, addr, address_str)
                cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w1@0x%x 0xdf r5' % (bus, addr, page, bus, addr)
                cmd = '%s;%s' % (cmd1, cmd2)
                print(cmd)
                ret, output = getstatusoutput(cmd)
                ret_val |= ret
                # 0x04: 0x00 0x04 0x00 0xba -> 0xba000400
                arr_info = output.split()[1:]
                regval_32bit = 0
                for i, byte in enumerate(arr_info):
                    regval_32bit |= int(byte, 16) << (i * 8)
                int_Value = hex_to_signed_int(((regval_32bit & IPH_LPF_IOUT_EVEN) >> 14), 14)
                iph_IOUT_Value = int_Value * IOUT_VALUE_STEP
            else:
                int_Value = hex_to_signed_int((regval_32bit & (IPH_LPF_IOUT_ODD)), 14)
                iph_IOUT_Value = int_Value * IOUT_VALUE_STEP
        
            iph_IOUT_Value = round(iph_IOUT_Value, 2)
            iph_iout_sum = iph_iout_sum + iph_IOUT_Value

            if ((iph_IOUT_Value < g_LowThd) or (iph_IOUT_Value > g_HighThd)):
                ret_val |= -1
                logging.error("The(%d-0x%x) loop%d-phase%d iout check failed, The IOUT %0.2f outside the range [%d, %d] (output=%s, Reg_value=0x%x)." % (bus, addr, rail, (j+1), iph_IOUT_Value, g_LowThd, g_HighThd, output, regval_32bit))
            else:
                logging.info("The(%d-0x%x) loop%d-phase%d iout check passed, The IOUT %0.2f inside the range [%d, %d] (output=%s, Reg_value=0x%x)." % (bus, addr, rail, (j+1), iph_IOUT_Value, g_LowThd, g_HighThd, output, regval_32bit))
    logging.info("The(%d-0x%x) get iph_iout_sum: %0.2f." % (bus, addr, iph_iout_sum))
    return ret_val

def drv_avs_phase_iout_check_by_vddname(vdd_name):
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    name_result = 255
    for index in phase_iout_info:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            count = index['ph_cnt']
            global g_LowThd
            global g_HighThd
            g_LowThd = index['LowThd']
            g_HighThd = index['HighThd']
            ret_val = drv_avs_phase_iout_check(bus, addr, rail, count)
            if(ret_val != 0):
                print("The %s(%d-0x%x) check phase iout failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) check phase iout passed." % (name, bus, addr))
    
    if(name_result != 0):
        print("The %s can not find,To check phase iout failed." % (name))
        return -1
    else:
        return 0

def drv_avs_phase_iout_check_multiphase():
    for index in multiphase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        count = index['ph_cnt']
        global g_LowThd
        global g_HighThd
        g_LowThd = index['LowThd']
        g_HighThd = index['HighThd']
        ret_val = drv_avs_phase_iout_check(bus, addr, rail, count)
        if(ret_val != 0):
            print("The %s(%d-0x%x) check phase iout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) check phase iout passed." % (name, bus, addr))
    return 0

def drv_avs_phase_iout_check_singlephase():
    for index in singlephase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        count = index['ph_cnt']
        global g_LowThd
        global g_HighThd
        g_LowThd = index['LowThd']
        g_HighThd = index['HighThd']
        ret_val = drv_avs_phase_iout_check(bus, addr, rail, count)
        if(ret_val != 0):
            print("The %s(%d-0x%x) check phase iout failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) check phase iout passed." % (name, bus, addr))
    return 0

def drv_avs_phase_iout_check_all():
    logging.info("drv_avs_phase_iout_check_all")
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        count = index['ph_cnt']
        global g_LowThd
        global g_HighThd
        g_LowThd = index['LowThd']
        g_HighThd = index['HighThd']

        ret_val = drv_avs_phase_iout_check(bus, addr, rail, count)
        if(ret_val != 0):
            logging.info("The %s(%d-0x%x) check phase iout failed." % (name, bus, addr))
            continue
        else:
            logging.info("The %s(%d-0x%x) check phase iout passed." % (name, bus, addr))
    return 0

###############################################################################################################################
###############################################################################################################################
###############################################################################################################################
#MFR_COMMON_FAULT_STATUS1
MFR_COMMON_FAULT_STATUS1 = 0x000000C7
FAULTED_PHASE_MASK = 0xFFFFFFFF
#i2cset -y -f 42 0x64 0x00 0x00;i2ctransfer -f -y 42 w1@0x64 0xc7 r5 
#20250612 need modify
def drv_avs_check_fault(bus, addr, rail):
    print("drv_avs_check_fault")
    #Firs switch pages based on the rail
    page = rail - 1
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w1@0x%x 0xc7 r5' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    # 0x04: 0x00 0x04 0x00 0xba -> 0xba000400
    arr_info = output.split()[1:]
    print("output=%s arr_info=%s)" % (output, arr_info))
    regval_32bit = 0
    for i, byte in enumerate(arr_info):
        regval_32bit |= int(byte, 16) << (i * 8)

    # 0xba000400 -> 0x8a000400
    if((regval_32bit & FAULTED_PHASE_MASK) != 0x0):
        logging.info("The (%d-0x%x) loop%d faulted phase is abnormal (Reg_value=0x%08x)." % (bus, addr, rail, regval_32bit))
        ret = -1
    else:
        logging.info("The (%d-0x%x) loop%d faulted phase is normal (Reg_value=0x%08x)." % (bus, addr, rail, regval_32bit))

    return ret

def drv_avs_check_fault_by_vddname(vdd_name):
    #print("drv_avs_check_fault_by_vddname")
    name_result = 255
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            ret_val = drv_avs_check_fault(bus, addr, rail)
            if(ret_val != 0):
                print("The %s(%d-0x%x) check faulted phase failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) check faulted phase passed." % (name, bus, addr))
    
    if(name_result != 0):
        print("The %s can not find,To check faulted phase failed." % (name))
        return -1
    else:
        return 0

def drv_avs_check_fault_all():
    #print("drv_avs_check_fault_all")
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        ret_val = drv_avs_check_fault(bus, addr, rail)
        if(ret_val != 0):
            print("The %s(%d-0x%x) check faulted phase failed." % (name, bus, addr))
            logging.info("The %s(%d-0x%x) check faulted phase failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) check faulted phase passed." % (name, bus, addr))
            logging.info("The %s(%d-0x%x) check faulted phase passed." % (name, bus, addr))
    return 0

###############################################################################################################################
###############################################################################################################################
# ##Read 0x2005DF04
# i2cset -y -f 42 0x64 0x00 0x00;i2ctransfer -f -y 42 w6@0x64 0xce 0x04 0x04 0xdf 0x05 0x20
# i2cset -y -f 42 0x64 0x00 0x00;i2ctransfer -f -y 42 w1@0x64 0xdf r5
# 0x04 0x40 0x00 0x00 0x00
# ##Write 0x2005DF04
# i2cset -y -f 42 0x64 0x00 0x00;i2ctransfer -f -y 42 w6@0x64 0xce 0x04 0x04 0xdf 0x05 0x20
# i2cset -y -f 42 0x64 0x00 0x00;i2ctransfer -f -y 42 w6@0x64 0xde 0x04 0x40 0x40 0x00 0x00
###############################################################################################################################
IPS_OCP_REG_LOOPA = 0x2005DF04
IPS_OCP_REG_LOOPB = 0x2005DF08
IPS_OCP_MASK = 0x00004000

MON_REG_LOOPA = 0x2005DF0C
MON_REG_LOOPB = 0x2005DF10
MON_MASK = 0x38000000
###############################################################################################################################
def drv_enable_mon_fault_mask(bus, addr, rail):
    print("drv_enable_mon_fault_mask")
    #Firs switch pages based on the rail
    page = rail - 1
    if(rail == 2):
        MON_REG = MON_REG_LOOPB
    else:
        MON_REG = MON_REG_LOOPA
    # 0x2005DF0C -> 0x0c 0xdf 0x05 0x20
    addrs_list = []
    for i in range(4):
        byte_value = (MON_REG >> (i * 8)) & 0xFF
        addrs_list.append(byte_value)
    #Python ≥ 3.6 #address_str = ' '.join([f"0x{b:02x}" for b in addrs_list])
    address_str = ' '.join(["0x%02x" % b for b in addrs_list])
    #address_str = ' '.join(["0x{:02x}".format(b) for b in addrs_list])
    # Read
    cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, address_str)
    cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w1@0x%x 0xdf r5;usleep 2000' % (bus, addr, page, bus, addr)
    cmd = '%s;%s' % (cmd1, cmd2)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    # 0x04: 0x00 0x04 0x00 0xba -> 0xba000400
    arr_info = output.split()[1:]
    #print("output=%s arr_info=%s)" % (output, arr_info))
    # regval_32bit = 0
    # for index in arr_info:
        # regval_32bit = (regval_32bit << 8) | int(index, 16)
    regval_32bit = 0
    for i, byte in enumerate(arr_info):
        regval_32bit |= int(byte, 16) << (i * 8)

    if(MON_MASK == (regval_32bit & MON_MASK)):
        # 0xba000400 -> 0x8a000400
        regval_wr_32bit = regval_32bit & ~(MON_MASK)
        print("regval_32bit=0x%x regval_wr_32bit=0x%x)" % (regval_32bit, regval_wr_32bit))
        # 0x8a000400 ->   0x00 0x40 0x00 0x8a
        regval_list = []
        for i in range(4):
            byte_value = (regval_wr_32bit >> (i * 8)) & 0xFF
            regval_list.append(byte_value)
        regval_str = ' '.join(["0x%02x" % b for b in regval_list])
        
        # Write
        cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, address_str)
        cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xde 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, regval_str)
        cmd = '%s;%s' % (cmd1, cmd2)
        print(cmd)
        ret, output = getstatusoutput(cmd)
        logging.info("The (%d-0x%x) loop%d enable mon_fault regval_32bit=0x%x regval_wr_32bit=0x%x" % (bus, addr, rail, regval_32bit, regval_wr_32bit))
    else:
        logging.info("The (%d-0x%x) loop%d already enable mon_fault" % (bus, addr, rail))
    return ret

def drv_enable_ips_ocp_fault_mask(bus, addr, rail):
    print("drv_enable_ips_ocp_fault_mask")
    #Firs switch pages based on the rail
    page = rail - 1
    if(rail == 2):
        IPS_OCP_REG = IPS_OCP_REG_LOOPB
    else:
        IPS_OCP_REG = IPS_OCP_REG_LOOPA
    # 0x2005DF04 -> 0x04 0xdf 0x05 0x20
    addrs_list = []
    for i in range(4):
        byte_value = (IPS_OCP_REG >> (i * 8)) & 0xFF
        addrs_list.append(byte_value)
    address_str = ' '.join(["0x%02x" % b for b in addrs_list])

    # Read
    cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, address_str)
    cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w1@0x%x 0xdf r5;usleep 2000' % (bus, addr, page, bus, addr)
    cmd = '%s;%s' % (cmd1, cmd2)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    # 0x04: 0x40 0x40 0x00 0x00 -> 0x00004040
    arr_info = output.split()[1:]
    #print("output=%s arr_info=%s)" % (output, arr_info))
    regval_32bit = 0
    for i, byte in enumerate(arr_info):
        regval_32bit |= int(byte, 16) << (i * 8)

    if(IPS_OCP_MASK == (regval_32bit & IPS_OCP_MASK)):
        # 0x00004040 -> 0x00000040
        regval_wr_32bit = regval_32bit & ~(IPS_OCP_MASK)
        print("regval_32bit=0x%x regval_wr_32bit=0x%x)" % (regval_32bit, regval_wr_32bit))
        # 0x00000040 -> 0x40 0x00 0x00 0x00
        regval_list = []
        for i in range(4):
            byte_value = (regval_wr_32bit >> (i * 8)) & 0xFF
            regval_list.append(byte_value)
        regval_str = ' '.join(["0x%02x" % b for b in regval_list])
        
        # Write
        cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, address_str)
        cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xde 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, regval_str)
        cmd = '%s;%s' % (cmd1, cmd2)
        print(cmd)
        ret, output = getstatusoutput(cmd)
        logging.info("The (%d-0x%x) loop%d enable ips_ocp_fault regval_32bit=0x%x regval_wr_32bit=0x%x" % (bus, addr, rail, regval_32bit, regval_wr_32bit))
    else:
        logging.info("The (%d-0x%x) loop%d already enable ips_ocp_fault"% (bus, addr, rail))
    return ret

def drv_enable_fault_mask(bus, addr, rail):
    ret = drv_enable_ips_ocp_fault_mask(bus, addr, rail)
    ret |= drv_enable_mon_fault_mask(bus, addr, rail)
    return ret
###############################################################################################################################

#ips_ocp_fault default=0x40
IPS_OCP_DISABLE_CONFIG = 0x00004040
#mon_fault default1=0x82000400
#mon_fault default2=0x8a000400
MON_DISABLE_CONFIG = 0xBA000400

def drv_disable_mon_fault_mask(bus, addr, rail):
    print("drv_disable_mon_fault_mask")
    #Firs switch pages based on the rail
    page = rail - 1
    if(rail == 2):
        MON_REG = MON_REG_LOOPB
    else:
        MON_REG = MON_REG_LOOPA
    # 0x2005DF0C -> 0x0c 0xdf 0x05 0x20
    addrs_list = []
    for i in range(4):
        byte_value = (MON_REG >> (i * 8)) & 0xFF
        addrs_list.append(byte_value)
    address_str = ' '.join(["0x%02x" % b for b in addrs_list])
    # Read
    cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, address_str)
    cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w1@0x%x 0xdf r5;usleep 2000' % (bus, addr, page, bus, addr)
    cmd = '%s;%s' % (cmd1, cmd2)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    # 0x04: 0x00 0x04 0x00 0x8a -> 0x8a000400
    arr_info = output.split()[1:]
    #print("output=%s arr_info=%s)" % (output, arr_info))
    # regval_32bit = 0
    # for index in arr_info:
        # regval_32bit = (regval_32bit << 8) | int(index, 16)
    regval_32bit = 0
    if(0 == ret):
        for i, byte in enumerate(arr_info):
            regval_32bit |= int(byte, 16) << (i * 8)
        
        if(MON_MASK != (regval_32bit & MON_MASK)):
            # 0x8a000400 -> 0xba000400
            #regval_wr_32bit = regval_32bit | MON_MASK
            regval_wr_32bit = MON_DISABLE_CONFIG
            print("regval_32bit=0x%x regval_wr_32bit=0x%x)" % (regval_32bit, regval_wr_32bit))
            # 0xba000400 -> 0x00 0x04 0x00 0xba
            regval_list = []
            for i in range(4):
                byte_value = (regval_wr_32bit >> (i * 8)) & 0xFF
                regval_list.append(byte_value)
            regval_str = ' '.join(["0x%02x" % b for b in regval_list])
            
            # Write
            cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, address_str)
            cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xde 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, regval_str)
            cmd = '%s;%s' % (cmd1, cmd2)
            print(cmd)
            ret, output = getstatusoutput(cmd)
            logging.info("The (%d-0x%x) loop%d disable mon_fault regval_32bit=0x%x regval_wr_32bit=0x%x" % (bus, addr, rail, regval_32bit, regval_wr_32bit))
        else:
            logging.info("The (%d-0x%x) loop%d already disable mon_fault" % (bus, addr, rail))
    return ret

def drv_disable_ips_ocp_fault_mask(bus, addr, rail):
    print("drv_disable_ips_ocp_fault_mask")
    #Firs switch pages based on the rail
    page = rail - 1
    if(rail == 2):
        IPS_OCP_REG = IPS_OCP_REG_LOOPB
    else:
        IPS_OCP_REG = IPS_OCP_REG_LOOPA
    # 0x2005DF04 -> 0x04 0xdf 0x05 0x20
    addrs_list = []
    for i in range(4):
        byte_value = (IPS_OCP_REG >> (i * 8)) & 0xFF
        addrs_list.append(byte_value)
    address_str = ' '.join(["0x%02x" % b for b in addrs_list])

    # Read
    cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, address_str)
    cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w1@0x%x 0xdf r5;usleep 2000' % (bus, addr, page, bus, addr)
    cmd = '%s;%s' % (cmd1, cmd2)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    # 0x04 : 0x40 0x00 0x00 0x00 -> 0x00000040
    arr_info = output.split()[1:]
    #print("output=%s arr_info=%s)" % (output, arr_info))
    regval_32bit = 0
    if(0 == ret):
        for i, byte in enumerate(arr_info):
            regval_32bit |= int(byte, 16) << (i * 8)
        if(IPS_OCP_MASK != (regval_32bit & IPS_OCP_MASK)):
            # 0x00000040 -> 0x00004040
            #regval_wr_32bit = regval_32bit | IPS_OCP_MASK
            regval_wr_32bit = IPS_OCP_DISABLE_CONFIG
            print("regval_32bit=0x%x regval_wr_32bit=0x%x)" % (regval_32bit, regval_wr_32bit))
            # 0x00004040 -> 0x04 0x40 0x00 0x00
            regval_list = []
            for i in range(4):
                byte_value = (regval_wr_32bit >> (i * 8)) & 0xFF
                regval_list.append(byte_value)
            regval_str = ' '.join(["0x%02x" % b for b in regval_list])
            
            # Write
            cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, address_str)
            cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w6@0x%x 0xde 0x04 %s;usleep 2000' % (bus, addr, page, bus, addr, regval_str)
            cmd = '%s;%s' % (cmd1, cmd2)
            print(cmd)
            ret, output = getstatusoutput(cmd)
            logging.info("The (%d-0x%x) loop%d disable ips_ocp_fault regval_32bit=0x%x regval_wr_32bit=0x%x" % (bus, addr, rail, regval_32bit, regval_wr_32bit))
        else:
            logging.info("The (%d-0x%x) loop%d already disable ips_ocp_fault" % (bus, addr, rail))
    return ret

###############################################################################################################################
def drv_disable_fault_mask(bus, addr, rail):
    ret = drv_disable_ips_ocp_fault_mask(bus, addr, rail)
    ret |= drv_disable_mon_fault_mask(bus, addr, rail)
    return ret

###############################################################################################################################
##
###############################################################################################################################
#‒ 1. fault_enable_mask_loop_fw_loop0 (0x2005DF04) set bit 14 to 1
#‒ 2. fault_enable_mask_loop_hw_loop0 (0x2005DF0C) set bit 29/28/27 to 1
###Read 0x2005DF04/ 0x2005DF0C
def drv_avs_enable_fault_mask_by_vddname(vdd_name):
    #print("drv_avs_enable_fault_mask_by_vddname")
    name_result = 255
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            ret_val = drv_enable_fault_mask(bus, addr, rail)
            if(ret_val != 0):
                print("The %s(%d-0x%x) enable fault failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) enable fault passed." % (name, bus, addr))
    
    if(name_result != 0):
        print("The %s can not find,To enable fault failed." % (name))
        return -1
    else:
        return 0

def drv_avs_enable_fault_mask_all():
    #print("drv_avs_enable_fault_mask_all")
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        ret_val = drv_enable_fault_mask(bus, addr, rail)
        if(ret_val != 0):
            print("The %s(%d-0x%x) enable fault failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) enable fault passed." % (name, bus, addr))
    return 0

def drv_avs_disable_fault_mask_by_vddname(vdd_name):
    #print("drv_avs_disable_fault_mask_by_vddname")
    name_result = 255
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            ret_val = drv_disable_fault_mask(bus, addr, rail)
            if(ret_val != 0):
                print("The %s(%d-0x%x) disable fault failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) disable fault passed." % (name, bus, addr))
    
    if(name_result != 0):
        print("The %s can not find,To disable fault failed." % (name))
        return -1
    else:
        return 0

def drv_avs_disable_fault_mask_all():
    #print("drv_avs_disable_fault_mask_all")
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        ret_val = drv_disable_fault_mask(bus, addr, rail)
        if(ret_val != 0):
            logging.info("The %s(%d-0x%x) disable fault failed." % (name, bus, addr))
            print("The %s(%d-0x%x) disable fault failed." % (name, bus, addr))
            continue
        else:
            logging.info("The %s(%d-0x%x) disable fault passed." % (name, bus, addr))
            print("The %s(%d-0x%x) disable fault passed." % (name, bus, addr))
    return 0

###############################################################################################################################
#change page 0, FEh写1DH，read FDh
#0x1D FW_CONFIG_UPDATED

#i2cset -f -y 49 0x68 0x0 0 b;usleep 500;i2cset -f -y 49 0x68 0xFE 0x1D b;
#i2cset -f -y 49 0x68 0x0 0 b;usleep 500;i2ctransfer -f -y 49 w1@0x68 0xFD r5

def drv_avs_fw_config_update(bus, addr, rail):
    print("drv_avs_fw_config_update")
    #Firs switch pages based on the rail
    page = rail - 1
    # Write
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2cset -f -y %d 0x%x 0xFE 0x1D;usleep 500' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    logging.info("The (%d-0x%x) loop%d fw_config_update." % (bus, addr, rail))
    # Read
    cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2ctransfer -f -y %d w1@0x%x 0xFD r5;usleep 1000' % (bus, addr, page, bus, addr)
    print(cmd1)
    ret, output = getstatusoutput(cmd1)
    # 0x04 : 0x40 0x00 0x00 0x00 -> 0x00000040
    arr_info = output.split()[1:]
    #print("output=%s arr_info=%s)" % (output, arr_info))
    regval_32bit = 0
    if(0 == ret):
        for i, byte in enumerate(arr_info):
            regval_32bit |= int(byte, 16) << (i * 8)
        logging.info("The (%d-0x%x) loop%d read MFR_FIRMWARE_COMMAND_DATA regval_32bit=0x%x." % (bus, addr, rail, regval_32bit))
    return ret

###############################################################################################################################
#IOUT_OC_FAULT_LIMIT  0x46 LINEAR11
def drv_avs_set_iout_oc_fault_limit(bus, addr, rail, iout_oc_value):
    print("drv_avs_set_iout_oc_fault_limit")
    #Firs switch pages based on the rail
    page = rail - 1

    # Write
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2cset -f -y %d 0x%x 0x46 0x%04x w;usleep 500' % (bus, addr, page, bus, addr, iout_oc_value)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    logging.info("The (%d-0x%x) loop%d set iout_oc_fault_limit 0x%04x." % (bus, addr, rail, iout_oc_value))
    # Read
    # cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2cget -f -y %d 0x%x 0x46 w' % (bus, addr, page, bus, addr)
    # print(cmd)
    # ret, output = getstatusoutput(cmd)
    # #print(output)
    # reg_val = pmbus_reg2data_linear11(output)
    # current_val = int(reg_val)
    # logging.info("The (%d-0x%x) loop%d read iout_oc_fault_limit regval=%s, current=%d." % (bus, addr, rail, output, current_val))
    return ret

def drv_setup_disable_fault_mask(bus, addr, rail, iout_oc_value):
    ret = drv_disable_ips_ocp_fault_mask(bus, addr, rail)
    ret |= drv_disable_mon_fault_mask(bus, addr, rail)
    #IOUT_OC_FAULT_LIMIT
    ret |= drv_avs_set_iout_oc_fault_limit(bus, addr, rail, iout_oc_value)
    ret |= drv_avs_fw_config_update(bus, addr, rail)
    return ret

def drv_avs_setup_disable_fault_mask_by_vddname(vdd_name):
    #print("drv_avs_disable_fault_mask_by_vddname")
    name_result = 255
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            iout_oc_value = index['IoutThd']
            ret_val = drv_setup_disable_fault_mask(bus, addr, rail, iout_oc_value)
            if(ret_val != 0):
                print("The %s(%d-0x%x) setup disable fault failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) setup disable fault passed." % (name, bus, addr))
    
    if(name_result != 0):
        print("The %s can not find,To setup disable fault failed." % (name))
        return -1
    else:
        return 0

def drv_avs_setup_disable_fault_mask_all():
    #print("drv_avs_disable_fault_mask_all")
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        iout_oc_value = index['IoutThd']
        ret_val = drv_setup_disable_fault_mask(bus, addr, rail, iout_oc_value)
        if(ret_val != 0):
            logging.info("The %s(%d-0x%x) setup disable fault failed." % (name, bus, addr))
            print("The %s(%d-0x%x) setup disable fault failed." % (name, bus, addr))
            continue
        else:
            logging.info("The %s(%d-0x%x) setup disable fault passed." % (name, bus, addr))
            print("The %s(%d-0x%x) setup disable fault passed." % (name, bus, addr))
    return 0

###############################################################################################################################
#IOUT_OC_FAULT_LIMIT  0x46 LINEAR11
def drv_avs_get_iout_oc_fault_limit(bus, addr, rail, iout_oc_value):
    print("drv_avs_get_iout_oc_fault_limit")
    #Firs switch pages based on the rail
    page = rail - 1

    # Read
    cmd = 'i2cset -f -y %d 0x%x 0x0 %d b;usleep 500;i2cget -f -y %d 0x%x 0x46 w;usleep 500' % (bus, addr, page, bus, addr)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    #print(output)
    reg_val = pmbus_reg2data_linear11(output)
    current_val = int(reg_val)
    print("The (%d-0x%x) loop%d read iout_oc_fault_limit regval=%s, current=%d, iout_oc_value=0x%04x." % (bus, addr, rail, output, current_val, iout_oc_value))
    logging.info("The (%d-0x%x) loop%d read iout_oc_fault_limit regval=%s, current=%d, iout_oc_value=0x%04x." % (bus, addr, rail, output, current_val, iout_oc_value))
    return ret

def drv_avs_get_iout_oc_fault_limit_by_vddname(vdd_name):
    #print("drv_avs_get_iout_oc_fault_limit_by_vddname")
    name_result = 255
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            iout_oc_value = index['IoutThd']
            ret_val = drv_avs_get_iout_oc_fault_limit(bus, addr, rail, iout_oc_value)
            if(ret_val != 0):
                print("The %s(%d-0x%x) get iout_oc_fault_limit failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get iout_oc_fault_limit passed." % (name, bus, addr))
    
    if(name_result != 0):
        print("The %s can not find,To get iout_oc_fault_limit failed." % (name))
        return -1
    else:
        return 0

def drv_avs_get_iout_oc_fault_limit_all():
    #print("drv_avs_get_iout_oc_fault_limit_all")
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        iout_oc_value = index['IoutThd']
        ret_val = drv_avs_get_iout_oc_fault_limit(bus, addr, rail, iout_oc_value)
        if(ret_val != 0):
            logging.info("The %s(%d-0x%x) get iout_oc_fault_limit failed." % (name, bus, addr))
            print("The %s(%d-0x%x) get iout_oc_fault_limit failed." % (name, bus, addr))
            continue
        else:
            logging.info("The %s(%d-0x%x) get iout_oc_fault_limit passed." % (name, bus, addr))
            print("The %s(%d-0x%x) get iout_oc_fault_limit passed." % (name, bus, addr))
    return 0

###############################################################################################################################
def drv_get_fault_status_mon_fault(bus, addr, rail):
    print("drv_get_fault_status_mon_fault")
    #Firs switch pages based on the rail
    page = rail - 1
    if(rail == 2):
        MON_REG = MON_REG_LOOPB
    else:
        MON_REG = MON_REG_LOOPA
    # 0x2005DF0C -> 0x0c 0xdf 0x05 0x20
    addrs_list = []
    for i in range(4):
        byte_value = (MON_REG >> (i * 8)) & 0xFF
        addrs_list.append(byte_value)
    address_str = ' '.join(["0x%02x" % b for b in addrs_list])
    # Read
    cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s' % (bus, addr, page, bus, addr, address_str)
    cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w1@0x%x 0xdf r5' % (bus, addr, page, bus, addr)
    cmd = '%s;%s' % (cmd1, cmd2)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    # 0x04: 0x00 0x04 0x00 0x8a -> 0x8a000400
    arr_info = output.split()[1:]
    #print("output=%s arr_info=%s)" % (output, arr_info))
    # regval_32bit = 0
    # for index in arr_info:
        # regval_32bit = (regval_32bit << 8) | int(index, 16)
    regval_32bit = 0
    for i, byte in enumerate(arr_info):
        regval_32bit |= int(byte, 16) << (i * 8)

    if(MON_MASK != (regval_32bit & MON_MASK)):
        logging.info("The (%d-0x%x) loop%d mon_fault enable; regval_32bit=0x%x " % (bus, addr, rail, regval_32bit))
    else:
        logging.info("The (%d-0x%x) loop%d mon_fault disable" % (bus, addr, rail))
    return ret

def drv_get_fault_status_ips_ocp_fault(bus, addr, rail):
    print("drv_get_fault_status_ips_ocp_fault")
    #Firs switch pages based on the rail
    page = rail - 1
    if(rail == 2):
        IPS_OCP_REG = IPS_OCP_REG_LOOPB
    else:
        IPS_OCP_REG = IPS_OCP_REG_LOOPA
    # 0x2005DF04 -> 0x04 0xdf 0x05 0x20
    addrs_list = []
    for i in range(4):
        byte_value = (IPS_OCP_REG >> (i * 8)) & 0xFF
        addrs_list.append(byte_value)
    address_str = ' '.join(["0x%02x" % b for b in addrs_list])

    # Read
    cmd1 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w6@0x%x 0xce 0x04 %s' % (bus, addr, page, bus, addr, address_str)
    cmd2 = 'i2cset -f -y %d 0x%x 0x0 %d b;i2ctransfer -f -y %d w1@0x%x 0xdf r5' % (bus, addr, page, bus, addr)
    cmd = '%s;%s' % (cmd1, cmd2)
    print(cmd)
    ret, output = getstatusoutput(cmd)
    # 0x04 : 0x40 0x00 0x00 0x00 -> 0x00000040
    arr_info = output.split()[1:]
    #print("output=%s arr_info=%s)" % (output, arr_info))
    regval_32bit = 0
    for i, byte in enumerate(arr_info):
        regval_32bit |= int(byte, 16) << (i * 8)
    if(IPS_OCP_MASK != (regval_32bit & IPS_OCP_MASK)):
        logging.info("The (%d-0x%x) loop%d ips_ocp_fault enable; regval_32bit=0x%x " % (bus, addr, rail, regval_32bit))
    else:
        logging.info("The (%d-0x%x) loop%d ips_ocp_fault disable"% (bus, addr, rail))
    return ret

def drv_get_fault_status(bus, addr, rail):
    ret = drv_get_fault_status_ips_ocp_fault(bus, addr, rail)
    ret |= drv_get_fault_status_mon_fault(bus, addr, rail)
    return ret

def drv_avs_fault_status_by_vddname(vdd_name):
    #print("drv_avs_enable_fault_mask_by_vddname")
    name_result = 255
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        if(name != vdd_name):
            continue
        else:
            name_result = 0
            bus  = index['bus']
            addr = index['addr']
            rail = index['rail']
            ret_val = drv_get_fault_status(bus, addr, rail)
            if(ret_val != 0):
                print("The %s(%d-0x%x) get fault status failed." % (name, bus, addr))
                return -1
            else:
                print("The %s(%d-0x%x) get fault status passed." % (name, bus, addr))
    
    if(name_result != 0):
        print("The %s can not find,To get fault status failed." % (name))
        return -1
    else:
        return 0

def drv_avs_fault_status_all():
    #print("drv_avs_fault_status_mask_all")
    phase_iout_info = singlephase_iout_info + multiphase_iout_info
    for index in phase_iout_info:
        name = index['name']
        bus  = index['bus']
        addr = index['addr']
        rail = index['rail']
        ret_val = drv_get_fault_status(bus, addr, rail)
        if(ret_val != 0):
            print("The %s(%d-0x%x) get fault status failed." % (name, bus, addr))
            continue
        else:
            print("The %s(%d-0x%x) get fault status passed." % (name, bus, addr))
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

def drv_avs_chip_func_usage():
    print("Usage: ")
    print("./avs-chip-func.py read/check <VDD_Name/all/singlephase/multiphase>")
    print("./avs-chip-func.py disable_fault/enable_fault/check_fault/get_fault_status/setup_disable_fault/get_iout_value <VDD_Name/all>")
    print("The VDD name:")
    print("VDD_PVS_MBIN/DVDD_CVB/VDD_PVS_MBIN_TILE_0/DVDD_CVB_TILE_0/VDD_PVS_MBIN_TILE_1/DVDD_CVB_TILE_1/VDD_PVS_MBIN_TILE_2/DVDD_CVB_TILE_2/VDD_PVS_MBIN_TILE_3")
    print("DVDD_CVB_TILE_3/VDD_PVS_MBIN_TILE_4/DVDD_CVB_TILE_4/VDD_PVS_MBIN_TILE_5/DVDD_CVB_TILE_5/VDD_PVS_MBIN_TILE_6/DVDD_CVB_TILE_6/VDD_PVS_MBIN_TILE_7/DVDD_CVB_TILE_7")
    print("VDDSCC/HVDD_T03/HVDD_T47")
    return 0

def main(argv):
    global g_voltage_level
    global g_store_code_flag
    global multiphase_iout_info
    product_model = get_product_model()
    multiphase_iout_info = PRODUCT_CONFIG_MAP.get(product_model, [])

    if len(sys.argv) == 3 :
        Operation = argv[1];
        vdd_name = argv[2];
    else:
        drv_avs_chip_func_usage()
        return -1
    log_info_init()

    if (Operation == 'read'):
        if (vdd_name == 'all'):
            drv_avs_phase_iout_read_all()
        elif (vdd_name == 'singlephase'):
            drv_avs_phase_iout_read_singlephase()
        elif (vdd_name == 'multiphase'):
            drv_avs_phase_iout_read_multiphase()
        else:
            drv_avs_phase_iout_read_by_vddname(vdd_name)
    elif (Operation == 'check'):
        drv_platform_service_opt(0)
        if (vdd_name == 'all'):
            drv_avs_phase_iout_check_all()
        elif (vdd_name == 'singlephase'):
            drv_avs_phase_iout_check_singlephase()
        elif (vdd_name == 'multiphase'):
            drv_avs_phase_iout_check_multiphase()
        else:
            drv_avs_phase_iout_check_by_vddname(vdd_name)
    elif (Operation == 'check_fault'):
        if (vdd_name == 'all'):
            drv_avs_check_fault_all()
        else:
            drv_avs_check_fault_by_vddname(vdd_name)
    elif (Operation == 'disable_fault'):
        drv_platform_service_opt(0)
        if (vdd_name == 'all'):
            drv_avs_disable_fault_mask_all()
        else:
            drv_avs_disable_fault_mask_by_vddname(vdd_name)
    elif (Operation == 'enable_fault'):
        if (vdd_name == 'all'):
            drv_avs_enable_fault_mask_all()
        else:
            drv_avs_enable_fault_mask_by_vddname(vdd_name)
        drv_platform_service_opt(1)
    elif (Operation == 'get_fault_status'):
        if (vdd_name == 'all'):
            drv_avs_fault_status_all()
        else:
            drv_avs_fault_status_by_vddname(vdd_name)
    elif (Operation == 'setup_disable_fault'):
        if (vdd_name == 'all'):
            drv_avs_setup_disable_fault_mask_all()
        else:
            drv_avs_setup_disable_fault_mask_by_vddname(vdd_name)
    elif (Operation == 'get_iout_value'):
        if (vdd_name == 'all'):
            drv_avs_get_iout_oc_fault_limit_all()
        else:
            drv_avs_get_iout_oc_fault_limit_by_vddname(vdd_name)
    else:
        print("The parameter error")
        drv_avs_chip_func_usage()
        return -1
    return 0

if __name__ == '__main__':
    main(sys.argv)

