# Copyright 2018-present Facebook. All Rights Reserved.
#
# I2C paths of CPLDs
#
OCMCPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 16-000d)
BASECPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 0-000d)
SWB_MISCCPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 66-0031)
SWB_PORT1CPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 64-0031)
SWB_PORT2CPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 65-0031)
LED_CPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 68-0031)
FAN2CPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 3-000d)
FAN1CPLD_SYSFS_DIR=$(i2c_device_sysfs_abspath 8-000d)
SWITCHFPGA_SYSFS_DIR=$(i2c_device_sysfs_abspath 67-0032)
#
# I2C paths of FRU
#
BMC_FRU_DIR=$(i2c_device_sysfs_abspath 2-0052)
BASE_FRU_DIR=$(i2c_device_sysfs_abspath 24-0051)
OCM_FRU_DIR=$(i2c_device_sysfs_abspath 16-0056)
SWITCH_FRU_DIR=$(i2c_device_sysfs_abspath 32-0050)
FAN1_BOARD_FRU_DIR=$(i2c_device_sysfs_abspath 94-0056)
FAN1_BOARD_FAN1_FRU_DIR=$(i2c_device_sysfs_abspath 88-0050)
FAN1_BOARD_FAN2_FRU_DIR=$(i2c_device_sysfs_abspath 89-0050)
FAN1_BOARD_FAN3_FRU_DIR=$(i2c_device_sysfs_abspath 90-0050)
FAN1_BOARD_FAN4_FRU_DIR=$(i2c_device_sysfs_abspath 91-0050)
FAN2_BOARD_FRU_DIR=$(i2c_device_sysfs_abspath 46-0056)
FAN2_BOARD_FAN1_FRU_DIR=$(i2c_device_sysfs_abspath 40-0050)
FAN2_BOARD_FAN2_FRU_DIR=$(i2c_device_sysfs_abspath 41-0050)
FAN2_BOARD_FAN3_FRU_DIR=$(i2c_device_sysfs_abspath 42-0050)
FAN2_BOARD_FAN4_FRU_DIR=$(i2c_device_sysfs_abspath 43-0050)

PSU4_MODLE_DIR=$(i2c_device_sysfs_abspath 72-0058)
PSU3_MODLE_DIR=$(i2c_device_sysfs_abspath 73-0058)
PSU2_MODLE_DIR=$(i2c_device_sysfs_abspath 74-0058)
PSU1_MODLE_DIR=$(i2c_device_sysfs_abspath 75-0058)

PWR_SP4_RST_SYSFS="${BASECPLD_SYSFS_DIR}/cpld_mac_reset"

SYSFS_I2C_DEVICES="/sys/bus/i2c/devices"
PSU_NUM=4

FAN_BOARD_TYPE_SYSFS="${BASECPLD_SYSFS_DIR}/fan_board_type"

get_product_name() {
    echo "AS42-64S-AT"
}
#################################################################################
#Sensor configs
#################################################################################
lm75_sensor_configs=(
    "16   0x0048  Temp_OCM_Inlet_Sensor       -1 75"
    # "76   0x0048  Temp_PSU_Inlet_Sensor       0 57"
    "95   0x0048  Temp_FAN1_Outlet_#1_Sensor   -1 60"
    "95   0x0049  Temp_FAN1_Outlet_#2_Sensor   -1 60"
    "47   0x0048  Temp_FAN2_Outlet_#1_Sensor   -1 60"
    "47   0x0049  Temp_FAN2_Outlet_#2_Sensor   -1 60"
    "2    0x0049  Temp_BMC_Sensor              -1 60"
    "34   0x0048  Temp_MGMT_Sensor             -1 60"
    "109  0x0048  Temp_SWITCH_Outlet_Sensor1  -1 97"
    "110  0x0048  Temp_SWITCH_Outlet_Sensor2  -1 97"
    "7    0x001f  Temp_MAC                    -1 100  temp_input"
    "75   0x0058  Temp_PSU1_Temp1_Ambient   -1 63"
    "74   0x0058  Temp_PSU2_Temp1_Ambient   -1 63"
    "73   0x0058  Temp_PSU3_Temp1_Ambient   -1 63"
    "72   0x0058  Temp_PSU4_Temp1_Ambient   -1 63"

    "17  0x0027 Temp_TPS544B25_IIC_17_0x27     -1   120"
    "17  0x0058 Temp_XDPE12284_IIC_17_0x58     -1   120"
    "17  0x0060 Temp_XDPE12284_IIC_17_0x60     -1   120"
    "17  0x006e Temp_XDPE12284_IIC_17_0x6e     -1   120"
    "56  0x0063 Temp_MP2985B_IIC_56_0x63      -1   120"
    "57  0x0064 Temp_MP2985B_IIC_57_0x64      -1   120"
    "58  0x0065 Temp_MP2985B_IIC_58_0x65      -1   120"
    "59  0x0066 Temp_MP2985B_IIC_59_0x66      -1   120"
    "53  0x0062 Temp_MP2985B_IIC_53_0x62      -1   120"
    "54  0x006b Temp_MP2985B_IIC_54_0x6B      -1   120"
    "55  0x006e Temp_MP2985B_IIC_55_0x6E      -1   120"
    "60  0x0067 Temp_MP2985B_IIC_60_0x67      -1   120"
    "61  0x0068 Temp_MP2985B_IIC_61_0x68      -1   120"
    "62  0x0069 Temp_MP2985B_IIC_62_0x69      -1   120"
    "63  0x006a Temp_MP2985B_IIC_63_0x6a      -1   120"
    "49  0x0063 Temp_MP29816_IIC_49_0x63      -1   120"
    "50  0x0064 Temp_MP29816_IIC_50_0x64      -1   120"
    "51  0x0065 Temp_MP29816_IIC_51_0x65      -1   120"
    "52  0x0066 Temp_MP29816_IIC_52_0x66      -1   120"
    "48  0x0060 Temp_MP29816_IIC_48_0x60      -1   120"
    "104  0x0067 Temp_MP2985B_IIC_104_0x67      -1   120"
    "105  0x0068 Temp_MP2985B_IIC_105_0x68      -1   120"
    "106  0x0069 Temp_MP2985B_IIC_106_0x69      -1   120"
    "107  0x006a Temp_MP2985B_IIC_107_0x6a      -1   120"
)

dc_sensor_configs=(
    # ------------- OCM board -------------
    # TPS544B25
    "17 27 in1_input    GRR_P5V_DDR_VOUT   1000    Volts  4.85  5.15"
    "17 27 curr2_input  GRR_P5V_DDR_IOUT   1000    Amps   -2    12.6"

    # xdpe12284
    "17 58 in3_input    GRR_PVCCIN_VOUT    1000    Volts  1.4  1.8"
    "17 58 in4_input    GRR_PVNN_VOUT      1000    Volts  0.55 1.1"
    "17 58 curr3_input  GRR_PVCCIN_IOUT    1000    Amps   -2  135"
    "17 58 curr4_input  GRR_PVNN_IOUT      1000    Amps   -2  49.5"

    # xdpe12284
    "17 60 in3_input    GRR_P1V1_VOUT       1000    Volts  1.04  1.16"
    "17 60 in4_input    GRR_PVNN_PCH_VOUT   1000    Volts  0.55  1.1"
    "17 60 curr3_input  GRR_P1V1_IOUT       1000    Amps   -2  13.5"
    "17 60 curr4_input  GRR_PVNN_PCH_IOUT   1000    Amps   -2  10.8"

    # xdpe12284
    "17 6e in3_input    GRR_P0V9_VOUT       1000    Volts  0.84  0.96"
    "17 6e in4_input    GRR_PVCCINF_VOUT    1000    Volts  0.55  1.1"
    "17 6e curr3_input  GRR_P0V9_IOUT       1000    Amps   -2  22.5"
    "17 6e curr4_input  GRR_PVCCINF_IOUT    1000    Amps   -2  31.5"

    # ucd90160
    "17 5f in1_input    GRR_PVNN_UCD_VOUT        1000    Volts  0.539   1.122"
    "17 5f in2_input    GRR_PVNN_PCH_UCD_VOUT    1000    Volts  0.539   1.122"
    "17 5f in3_input    GRR_P0V9_UCD_VOUT        1000    Volts  0.8232  0.9792"
    "17 5f in4_input    GRR_PVCCINF_UCD_VOUT     1000    Volts  0.539   1.122"
    "17 5f in5_input    GRR_PVCCIN_UCD_VOUT      1000    Volts  1.372   1.836"
    "17 5f in6_input    GRR_P1V8_CPU_UCD_VOUT    1000    Volts  1.6954  1.9074"
    "17 5f in7_input    GRR_P1V025_UCD_VOUT      1000    Volts  0.9751  1.122"
    "17 5f in8_input    GRR_P1V1_UCD_VOUT        1000    Volts  1.0192  1.1832"
    "17 5f in9_input    GRR_P5V_DDR_UCD_VOUT     1000    Volts  4.753   5.253"
    "17 5f in10_input   GRR_P3V3_STBY_UCD_VOUT   1000    Volts  2.9106  3.7026"
    "17 5f in11_input   GRR_P1V8_STBY_UCD_VOUT   1000    Volts  1.5876  2.0196"
    # "17 5f in12_input   GRR_P3V3_CLK_UCD_VOUT    1000    Volts  3.0772  3.5394"
    # "17 5f in13_input   GRR_P1V8_CLK_UCD_VOUT    1000    Volts  1.6758  1.9278"
    "17 5f in14_input   GRR_P5V_STBY_UCD_VOUT    1000    Volts  4.508   5.508"
    "17 5f in15_input   GRR_OCM_VIN12_UCD_VOUT   1000    Volts  10.8  13.8"

    # ------------- BMC board -------------
    # ucd90160
    "28 68 in1_input    BMC_VCC_0V8_VOUT        1000    Volts  0.8085   0.918"
    "28 68 in2_input    BMC_VCC_1V1_VOUT        1000    Volts  1.1074   1.1934"
    "28 68 in3_input    BMC_VCC_3V3_VOUT        1000    Volts  3.1458   3.4476"
    "28 68 in4_input    BMC_VCC_1V8_VOUT        1000    Volts  1.715    1.887"
    "28 68 in5_input    BMC_VCC_1V2_VOUT        1000    Volts  1.1662   1.2852"
    "28 68 in6_input    BMC_VCC_1V0_VOUT	    1000    Volts  0.931    1.2546"
    "28 68 in7_input    BMC_VCC_DDRVDDQ_VOUT    1000    Volts  1.0486   1.1934"
    "28 68 in8_input    BMC_VCC3V3_EMMC_VOUT    1000    Volts  2.646    3.672"
    "28 68 in9_input    BMC_VCC1V8_EMMC_VOUT    1000    Volts  1.666    1.989"

    # ------------- BASE board -------------
    # ina3221
    "31 40 in1_input        BASE_CLKGEN_1V8_VOUT      1000    Volts  1.62  1.98"
    "31 40 in2_input        BASE_BMC_3V3_VOUT         1000    Volts  2.97  3.63"
    "31 40 in3_input        BASE_SSD_1_3V3_VOUT       1000    Volts  2.97  3.63"
    "31 40 curr1_input      BASE_CLKGEN_1V8_IOUT      1000    Amps   -2     1"
    "31 40 curr2_input      BASE_BMC_3V3_IOUT         1000    Amps   -2     2"
    "31 40 curr3_input      BASE_SSD_1_3V3_IOUT       1000    Amps   -2     1.5"

    # ina3221
    "29 40 in1_input        BASE_SSD_2_3V3_VOUT      1000    Volts  2.97   3.63"
    "29 40 in2_input        BASE_PHY_1V5_VOUT        1000    Volts  1.35   1.65"
    "29 40 in3_input        BASE_PHY_1V05_VOUT       1000    Volts  0.94   1.16"
    "29 40 curr1_input      BASE_SSD_2_3V3_IOUT      1000    Amps   -2      1.5"
    "29 40 curr2_input      BASE_PHY_1V5_IOUT        1000    Amps   -2      1.5"
    "29 40 curr3_input      BASE_PHY_1V05_IOUT       1000    Amps   -2      3"

    # ina3221
    "30 40 in1_input        BASE_PHY_3V3_VOUT      1000    Volts  2.97   3.63"
    "30 40 in2_input        BASE_STB_3V3_VOUT      1000    Volts  2.97   3.63"
    "30 40 in3_input        BASE_GRR_12V_VOUT      1000    Volts  10.8   13.8"
    "30 40 curr1_input      BASE_PHY_3V3_IOUT      1000    Amps   -2      1"
    "30 40 curr2_input      BASE_STB_3V3_IOUT      1000    Amps   -2      4"
    "30 40 curr3_input      BASE_GRR_12V_IOUT      1000    Amps   -2      18.3"

    # ------------- SWITCH board -------------
    # ina3221
    "36 40 in1_input        MAIN_SB_3V3_VOUT        1000    Volts  2.97  3.65"
    "36 40 in2_input        MAIN_SB_1V8_VOUT        1000    Volts  1.62  1.98"
    "36 40 curr1_input      MAIN_SB_3V3_IOUT        1000    Amps   -2     4.4"
    "36 40 curr2_input      MAIN_SB_1V8_IOUT        1000    Amps   -2     1.43"

    # ina3221
    "35 40 in1_input        MAIN_CPLD_3V3_VOUT     1000    Volts  2.97  3.65"
    "35 40 in2_input        MAIN_PLL_1V8_VOUT      1000    Volts  1.62  1.98"
    "35 40 in3_input        MAIN_PLL_3V3_VOUT      1000    Volts  2.97  3.65"
    "35 40 curr1_input      MAIN_CPLD_3V3_IOUT     1000    Amps   -2     4.4"
    "35 40 curr2_input      MAIN_PLL_1V8_IOUT      1000    Amps   -2     1.1"
    "35 40 curr3_input      MAIN_PLL_3V3_IOUT      1000    Amps   -2     0.66"

    # ina3221
    "38 40 in1_input        MAIN_FPGA_3V3_VOUT     1000    Volts  2.97  3.65"
    "38 40 in2_input        MAIN_FPGA_1V8_VOUT     1000    Volts  1.62  1.98"
    "38 40 in3_input        MAIN_FPGA_1V2_VOUT     1000    Volts  1.08  1.32"
    "38 40 curr1_input      MAIN_FPGA_3V3_IOUT     1000    Amps   -2     0.33"
    "38 40 curr2_input      MAIN_FPGA_1V8_IOUT     1000    Amps   -2     0.55"
    "38 40 curr3_input      MAIN_FPGA_1V2_IOUT     1000    Amps   -2     0.11"

    # ina3221
    "37 40 in1_input        MAIN_DRMOS_5V_VOUT    1000    Volts  4.5    5.5"
    "37 40 in3_input        MAIN_QPS_1V8_VOUT     1000    Volts  1.62   1.98"
    "37 40 curr1_input      MAIN_DRMOS_5V_IOUT    1000    Amps   -2      6.6"
    "37 40 curr3_input      MAIN_QPS_1V8_IOUT     1000    Amps   -2      0.352"

    # ina3221
    "39 40 in1_input        MAIN_FPGA_1V0_VOUT    1000    Volts  0.9     1.1"
    "39 40 in2_input        MAIN_AVDD_1V1_VOUT    1000    Volts  0.9975  1.1025"
    "39 40 in3_input        MAIN_DVDD_0V7_VOUT    1000    Volts  0.665   0.735"
    "39 40 curr1_input      MAIN_FPGA_1V0_IOUT    1000    Amps   -2       0.5"
    "39 40 curr2_input      MAIN_AVDD_1V1_IOUT    1000    Amps   -2       2.2"
    "39 40 curr3_input      MAIN_DVDD_0V7_IOUT    1000    Amps   -2       2.2"

    # MP2985B
    "56 63 in2_input    SP6_AVDD_T0_1V05_VOUT   1000    Volts  0.9025   1.1025"
    "56 63 in3_input    SP6_AVDD_T1_1V05_VOUT   1000    Volts  0.9025   1.1025"
    "56 63 curr2_input  SP6_AVDD_T0_1V05_IOUT   1000    Amps   -2        24.2"
    "56 63 curr3_input  SP6_AVDD_T1_1V05_IOUT   1000    Amps   -2        24.2"

    # MP2985B
    "57 64 in2_input    SP6_AVDD_T2_1V05_VOUT   1000    Volts  0.9025   1.1025"
    "57 64 in3_input    SP6_AVDD_T3_1V05_VOUT   1000    Volts  0.9025   1.1025"
    "57 64 curr2_input  SP6_AVDD_T2_1V05_IOUT   1000    Amps   -2        24.2"
    "57 64 curr3_input  SP6_AVDD_T3_1V05_IOUT   1000    Amps   -2        24.2"

    # MP2985B
    "58 65 in2_input    SP6_AVDD_T4_1V05_VOUT   1000    Volts  0.9025   1.1025"
    "58 65 in3_input    SP6_AVDD_T5_1V05_VOUT   1000    Volts  0.9025   1.1025"
    "58 65 curr2_input  SP6_AVDD_T4_1V05_IOUT   1000    Amps   -2        24.2"
    "58 65 curr3_input  SP6_AVDD_T5_1V05_IOUT   1000    Amps   -2        24.2"

    # MP2985B
    "59 66 in2_input    SP6_AVDD_T6_1V05_VOUT   1000    Volts  0.9025   1.1025"
    "59 66 in3_input    SP6_AVDD_T7_1V05_VOUT   1000    Volts  0.9025   1.1025"
    "59 66 curr2_input  SP6_AVDD_T6_1V05_IOUT   1000    Amps   -2        24.2"
    "59 66 curr3_input  SP6_AVDD_T7_1V05_IOUT   1000    Amps   -2        24.2"

    # MP2985B
    "53 62 in2_input    SP6_HVDD_T03_1V2_VOUT   1000    Volts  1.14   1.26"
    "53 62 in3_input    SP6_HVDD_T47_1V2_VOUT   1000    Volts  1.14   1.26"
    "53 62 curr2_input  SP6_HVDD_T03_1V2_IOUT   1000    Amps   -2      34.1"
    "53 62 curr3_input  SP6_HVDD_T47_1V2_IOUT   1000    Amps   -2      34.1"

    # MP2985B
    "54 6b in2_input    SP6_VDDHBID_T12_0V78_VOUT   1000    Volts  0.741   0.819"
    "54 6b in3_input    SP6_VDDHBID_T37_0V78_VOUT   1000    Volts  0.741   0.819"
    "54 6b curr2_input  SP6_VDDHBID_T12_0V78_IOUT   1000    Amps   -2       78.1"
    "54 6b curr3_input  SP6_VDDHBID_T37_0V78_IOUT   1000    Amps   -2       78.1"

    # MP2985B
    "55 6e in2_input    SP6_VDDHBID_T04_0V78_VOUT   1000    Volts  0.741   0.819"
    "55 6e in3_input    SP6_VDDHBID_T56_0V78_VOUT   1000    Volts  0.741   0.819"
    "55 6e curr2_input  SP6_VDDHBID_T04_0V78_IOUT   1000    Amps   -2       78.1"
    "55 6e curr3_input  SP6_VDDHBID_T56_0V78_IOUT   1000    Amps   -2       78.1"

    # MP2985B
    "104 67 in2_input    OSFP_1_8_3V3_VOUT   1000    Volts  2.97   3.65  3"
    "104 67 in3_input    OSFP9_16_3V3_VOUT   1000    Volts  2.97   3.65  3"
    "104 67 curr2_input  OSFP_1_8_3V3_IOUT   1000    Amps   -2     117.7"
    "104 67 curr3_input  OSFP9_16_3V3_IOUT   1000    Amps   -2     117.7"

    # MP2985B
    "105 68 in2_input    OSFP17_24_3V3_VOUT   1000    Volts  2.97   3.65  3"
    "105 68 in3_input    OSFP25_32_3V3_VOUT   1000    Volts  2.97   3.65  3"
    "105 68 curr2_input  OSFP17_24_3V3_IOUT   1000    Amps   -2     117.7"
    "105 68 curr3_input  OSFP25_32_3V3_IOUT   1000    Amps   -2     117.7"

    # MP2985B
    "106 69 in2_input    OSFP33_40_3V3_VOUT   1000    Volts  2.97   3.65  3"
    "106 69 in3_input    OSFP41_48_3V3_VOUT   1000    Volts  2.97   3.65  3"
    "106 69 curr2_input  OSFP33_40_3V3_IOUT   1000    Amps   -2     117.7"
    "106 69 curr3_input  OSFP41_48_3V3_IOUT   1000    Amps   -2     117.7"

    # MP2985B
    "107 6a in2_input    OSFP49_56_3V3_VOUT   1000    Volts  2.97   3.65  3"
    "107 6a in3_input    OSFP57_64_3V3_VOUT   1000    Volts  2.97   3.65  3"
    "107 6a curr2_input  OSFP49_56_3V3_IOUT   1000    Amps   -2     117.7"
    "107 6a curr3_input  OSFP57_64_3V3_IOUT   1000    Amps   -2     117.7"

    # MP29816
    "49 63 in2_input    SP6_VDD_T0_0V75_VOUT   1000    Volts  0.589   0.80625"
    "49 63 in3_input    SP6_VDD_T1_0V75_VOUT   1000    Volts  0.589   0.80625"
    "49 63 curr3_input  SP6_VDD_T0_0V75_IOUT   1000    Amps   -2        58.3"
    "49 63 curr4_input  SP6_VDD_T1_0V75_IOUT   1000    Amps   -2        58.3"

    # MP29816
    "50 64 in2_input    SP6_VDD_T2_0V75_VOUT   1000    Volts  0.589   0.80625"
    "50 64 in3_input    SP6_VDD_T3_0V75_VOUT   1000    Volts  0.589   0.80625"
    "50 64 curr3_input  SP6_VDD_T2_0V75_IOUT   1000    Amps   -2        58.3"
    "50 64 curr4_input  SP6_VDD_T3_0V75_IOUT   1000    Amps   -2        58.3"

    # MP29816
    "51 65 in2_input    SP6_VDD_T4_0V75_VOUT   1000    Volts  0.589   0.80625"
    "51 65 in3_input    SP6_VDD_T5_0V75_VOUT   1000    Volts  0.589   0.80625"
    "51 65 curr3_input  SP6_VDD_T4_0V75_IOUT   1000    Amps   -2        58.3"
    "51 65 curr4_input  SP6_VDD_T5_0V75_IOUT   1000    Amps   -2        58.3"

    # MP29816
    "52 66 in2_input    SP6_VDD_T6_0V75_VOUT   1000    Volts  0.589   0.80625"
    "52 66 in3_input    SP6_VDD_T7_0V75_VOUT   1000    Volts  0.589   0.80625"
    "52 66 curr3_input  SP6_VDD_T6_0V75_IOUT   1000    Amps   -2        58.3"
    "52 66 curr4_input  SP6_VDD_T7_0V75_IOUT   1000    Amps   -2        58.3"

    # MP29816
    "48 60 in2_input    SP6_VDDM_0V75_VOUT   1000    Volts  0.608   0.817"
    "48 60 curr3_input  SP6_VDDM_0V75_IOUT   1000    Amps   -2        896.5"

    # MP2985B
    "60 67 in2_input    SP6_DVDD_T0_0V7_VOUT   1000    Volts  0.5225   0.735"
    "60 67 in3_input    SP6_DVDD_T1_0V7_VOUT   1000    Volts  0.5225   0.735"
    "60 67 curr2_input  SP6_DVDD_T0_0V7_IOUT   1000    Amps   -2       41.8"
    "60 67 curr3_input  SP6_DVDD_T1_0V7_IOUT   1000    Amps   -2       41.8"

    # MP2985B
    "61 68 in2_input    SP6_DVDD_T2_0V7_VOUT   1000    Volts  0.5225   0.735"
    "61 68 in3_input    SP6_DVDD_T3_0V7_VOUT   1000    Volts  0.5225   0.735"
    "61 68 curr2_input  SP6_DVDD_T2_0V7_IOUT   1000    Amps   -2       41.8"
    "61 68 curr3_input  SP6_DVDD_T3_0V7_IOUT   1000    Amps   -2       41.8"

    # MP2985B
    "62 69 in2_input    SP6_DVDD_T4_0V7_VOUT   1000    Volts  0.5225   0.735"
    "62 69 in3_input    SP6_DVDD_T5_0V7_VOUT   1000    Volts  0.5225   0.735"
    "62 69 curr2_input  SP6_DVDD_T4_0V7_IOUT   1000    Amps   -2       41.8"
    "62 69 curr3_input  SP6_DVDD_T5_0V7_IOUT   1000    Amps   -2       41.8"

    # MP2985B
    "63 6a in2_input    SP6_DVDD_T6_0V7_VOUT   1000    Volts  0.5225   0.735"
    "63 6a in3_input    SP6_DVDD_T7_0V7_VOUT   1000    Volts  0.5225   0.735"
    "63 6a curr2_input  SP6_DVDD_T6_0V7_IOUT   1000    Amps   -2       41.8"
    "63 6a curr3_input  SP6_DVDD_T7_0V7_IOUT   1000    Amps   -2       41.8"

    # ------------- MGMT board -------------
    # ina3221
    "108 40 in1_input        MGMT_GEPHY_1V_VOUT      1000    Volts  0.9    1.1"
    "108 40 in2_input        MGMT_STB_5V_VOUT        1000    Volts  4.5    5.5"
    "108 40 in3_input        MGMT_STB_3V3_VOUT       1000    Volts  2.97   3.63"
    "108 40 curr1_input      MGMT_GEPHY_1V_IOUT      1000    Amps   -2      0.5"
    "108 40 curr2_input      MGMT_STB_5V_IOUT        1000    Amps   -2      1.2"
    "108 40 curr3_input      MGMT_STB_3V3_IOUT       1000    Amps   -2      5"
)


get_psu_input_type() {
    local psu_num=$1
    local bus=""
    local addr=""

    if [ $psu_num -eq 1 ]; then
        bus=75
        addr=58
    elif [ $psu_num -eq 2 ]; then
        bus=74
        addr=58
    elif [ $psu_num -eq 3 ]; then
        bus=73
        addr=58
    elif [ $psu_num -eq 4 ]; then
        bus=72
        addr=58
    fi

    node_path=${SYSFS_I2C_DEVICES}/${bus}-00${addr}/input_type
    local value=`cat ${node_path}`
    echo $value
}



psu1_ac_configs=(
    "75  58   in1_input      PSU1_VIN       1000        Volts   90    264"
    "75  58   in2_input      PSU1_VOUT      1000        Volts   12    12.8"
    "75  58   curr1_input    PSU1_IIN       1000        Amps    0     9"
    "75  58   curr2_input    PSU1_IOUT      1000        Amps    0     161.3"
    "75  58   power1_input   PSU1_PIN       1000000     Watts   0     2700"
    "75  58   power2_input   PSU1_POUT      1000000     Watts   0     2700"
)

psu2_ac_configs=(
    "73  58   in1_input      PSU2_VIN       1000        Volts   90    264"
    "73  58   in2_input      PSU2_VOUT      1000        Volts   12    12.8"
    "73  58   curr1_input    PSU2_IIN       1000        Amps    0     9"
    "73  58   curr2_input    PSU2_IOUT      1000        Amps    0     161.3"
    "73  58   power1_input   PSU2_PIN       1000000     Watts   0     2700"
    "73  58   power2_input   PSU2_POUT      1000000     Watts   0     2700"
)

psu3_ac_configs=(
    "74  58   in1_input      PSU3_VIN       1000        Volts   90    264"
    "74  58   in2_input      PSU3_VOUT      1000        Volts   12    12.8"
    "74  58   curr1_input    PSU3_IIN       1000        Amps    0     9"
    "74  58   curr2_input    PSU3_IOUT      1000        Amps    0     161.3"
    "74  58   power1_input   PSU3_PIN       1000000     Watts   0     2700"
    "74  58   power2_input   PSU3_POUT      1000000     Watts   0     2700"
)

psu4_ac_configs=(
    "72  58   in1_input      PSU4_VIN       1000        Volts   90    264"
    "72  58   in2_input      PSU4_VOUT      1000        Volts   12    12.8"
    "72  58   curr1_input    PSU4_IIN       1000        Amps    0     9"
    "72  58   curr2_input    PSU4_IOUT      1000        Amps    0     161.3"
    "72  58   power1_input   PSU4_PIN       1000000     Watts   0     2700"
    "72  58   power2_input   PSU4_POUT      1000000     Watts   0     2700"
)

psu1_dc_configs=(
    "75  58   in1_input      PSU1_VIN       1000        Volts   180    320"
    "75  58   in2_input      PSU1_VOUT      1000        Volts   12    12.8"
    "75  58   curr1_input    PSU1_IIN       1000        Amps    0     9"
    "75  58   curr2_input    PSU1_IOUT      1000        Amps    0     161.3"
    "75  58   power1_input   PSU1_PIN       1000000     Watts   0     2700"
    "75  58   power2_input   PSU1_POUT      1000000     Watts   0     2700"
)

psu2_dc_configs=(
    "73  58   in1_input      PSU2_VIN       1000        Volts   180    320"
    "73  58   in2_input      PSU2_VOUT      1000        Volts   12    12.8"
    "73  58   curr1_input    PSU2_IIN       1000        Amps    0     9"
    "73  58   curr2_input    PSU2_IOUT      1000        Amps    0     161.3"
    "73  58   power1_input   PSU2_PIN       1000000     Watts   0     2700"
    "73  58   power2_input   PSU2_POUT      1000000     Watts   0     2700"
)

psu3_dc_configs=(
    "74  58   in1_input      PSU3_VIN       1000        Volts   180    320"
    "74  58   in2_input      PSU3_VOUT      1000        Volts   12    12.8"
    "74  58   curr1_input    PSU3_IIN       1000        Amps    0     9"
    "74  58   curr2_input    PSU3_IOUT      1000        Amps    0     161.3"
    "74  58   power1_input   PSU3_PIN       1000000     Watts   0     2700"
    "74  58   power2_input   PSU3_POUT      1000000     Watts   0     2700"
)

psu4_dc_configs=(
    "72  58   in1_input      PSU4_VIN       1000        Volts   180    320"
    "72  58   in2_input      PSU4_VOUT      1000        Volts   12    12.8"
    "72  58   curr1_input    PSU4_IIN       1000        Amps    0     9"
    "72  58   curr2_input    PSU4_IOUT      1000        Amps    0     161.3"
    "72  58   power1_input   PSU4_PIN       1000000     Watts   0     2700"
    "72  58   power2_input   PSU4_POUT      1000000     Watts   0     2700"
)

psu_ac_configs=(
    "psu1_ac_configs"
    "psu2_ac_configs"
    "psu3_ac_configs"
    "psu4_ac_configs"
)

psu_dc_configs=(
    "psu1_dc_configs"
    "psu2_dc_configs"
    "psu3_dc_configs"
    "psu4_dc_configs"
)

MAC_TEMP_SENSOR_BUS_NUMBERS=(7)
MAC_TEMP_SENSOR_DEVICE_ADDR="1f"
MAC_TEMP_SENSOR_INPUTS=("temp_input")

i2c0_device_configs=(
    "TEST_REG    SYS_CPLD    0    0xd    0xf7"
)

i2c1_device_configs=(
    # "TEST_REG    OCM_CPLD          16    0xd     0xf7"
    "TEST_REG    OCM_LM75BD        16   0x48    0x3"
    "EEPROM      OCM_FRU           16   56"
    "EEPROM      88E6361_EEPROM    20    50"
    "EEPROM      RTL8111_EEPROM    21    51"
    "HWMON       OCM_TPS544B25_27  17    27      in1_input"
    "HWMON       OCM_XDPE12284_58  17    58      in1_input"
    "HWMON       OCM_XDPE12284_60  17    60      in1_input"
    "HWMON       OCM_XDPE12284_6e  17    6e      in1_input"
)

i2c2_device_configs=(
    "EEPROM      BMC_FRU           2     52"
    "TEST_REG    BMC_LM75BD        2     0x49    0x3"
    "EEPROM      BASE_FRU          24    51"
    "HWMON       28_BMC_UCD90160   28    68    in1_input"
    "HWMON       29_BASE_INA3221A  29    40    in1_input"
    "HWMON       30_BASE_INA3221A  30    40    in1_input"
    "HWMON       31_BASE_INA3221A  31    40    in1_input"
    "EEPROM      SWITCH_FRU        32    50"
#    "EEPROM      FPGA_FRU          33    60"
    "TEST_REG    MGMT_TMP275A      34    0x48  0x3"
    "HWMON       35_SWITCH_INA3221A  35    40    in1_input"
    "HWMON       36_SWITCH_INA3221A  36    40    in1_input"
    "HWMON       37_SWITCH_INA3221A  37    40    in1_input"
    "HWMON       38_SWITCH_INA3221A  38    40    in1_input"
    "HWMON       39_SWITCH_INA3221A  39    40    in1_input"
)

i2c3_device_configs=(
    "TEST_REG    FAN2_BOARD_CPLD         3     0x0d    0xf"
    "EEPROM      FAN2_BOARD_FAN1_FRU     40    50"
    "EEPROM      FAN2_BOARD_FAN2_FRU     41    50"
    "EEPROM      FAN2_BOARD_FAN3_FRU     42    50"
    "EEPROM      FAN2_BOARD_FAN4_FRU     43    50"
    "EEPROM      FAN2_BOARD_FRU          46    56"
    "TEST_REG    FAN2_BOARD_TMP275A_48   47    0x48    0x3"
    "TEST_REG    FAN2_BOARD_TMP275A_49   47    0x49    0x3"
)

i2c4_device_configs=(
    "HWMON    VDDM                48    60    in1_input"
    "HWMON    VDDT0_VDDT1         49    63    in1_input"
    "HWMON    VDDT2_VDDT3         50    64    in1_input"
    "HWMON    VDDT4_VDDT5         51    65    in1_input"
    "HWMON    VDDT6_VDDT7         52    66    in1_input"
    "HWMON    HVDDT07             53    62    in1_input"
    "HWMON    VHHBIAT1237         54    6b    in1_input"
    "HWMON    VHHBIAT0456         55    6e    in1_input"
    "HWMON    AVDDT01             56    63    in1_input"
    "HWMON    AVDDT23             57    64    in1_input"
    "HWMON    AVDDT45             58    65    in1_input"
    "HWMON    AVDDT67             59    66    in1_input"
    "HWMON    DVDDT01             60    67    in1_input"
    "HWMON    DVDDT23             61    68    in1_input"
    "HWMON    DVDDT45             62    69    in1_input"
    "HWMON    DVDDT67             63    6a    in1_input"
)

i2c5_device_configs=(
    "TEST_REG    PORT1_CPLD      64    0x31    0xf"
    "TEST_REG    PORT2_CPLD      65    0x31    0xf"
    "TEST_REG    MISC_CPLD       66    0x31    0xf"
    "TEST_REG    SWITCH_FPGA     67    0x32    0x74"
    "TEST_REG    LED_CPLD        68    0x31    0xf"
)

i2c6_device_configs=(
    "HWMON       PSU1          72    58      in1_input"
    "HWMON       PSU2          73    58      in1_input"
    "HWMON       PSU3          74    58      in1_input"
    "HWMON       PSU4          75    58      in1_input"
    # "TEST_REG    PSU_TMP75A    76    0x48    0x3"
)

i2c7_device_configs=(
    "TEST_REG    MAC_TEMP_SENSER_1f    7    0x1f    0x01"
)

i2c8_device_configs=(
    "TEST_REG    FAN1_BOARD_CPLD         8      0x0d    0xf"
    "EEPROM      FAN1_BOARD_FAN1_FRU     88     50"
    "EEPROM      FAN1_BOARD_FAN2_FRU     89     50"
    "EEPROM      FAN1_BOARD_FAN3_FRU     90     50"
    "EEPROM      FAN1_BOARD_FAN4_FRU     91     50"
    "EEPROM      FAN1_BOARD_FRU          94     56"
    "TEST_REG    FAN1_BOARD_TMP275A_48   95     0x48    0x3"
    "TEST_REG    FAN1_BOARD_TMP275A_49   95     0x49    0x3"
)

i2c11_device_configs=(
    "HWMON       V33_QSFP1          104    67    in1_input"
    "HWMON       V33_QSFP2          105    68    in1_input"
    "HWMON       V33_QSFP3          106    69    in1_input"
    "HWMON       V33_QSFP4          107    6a    in1_input"
    "HWMON       108_MGMT_INA3221A  108    40    in1_input"
    "TEST_REG    SWITCH_TMP75A_48   109    0x48    0x3"
    "TEST_REG    SWITCH_TMP75A_48   110    0x48    0x3"
)

set_fpga_write_enable() {
    mode=$1
    case $mode in
        enable)
            i2cset -f -y 67 0x32 0x70 0xbc # SWITCH_FPGA: BMC Write Enable
            ;;
        disable)
            i2cset -f -y 67 0x32 0x70 0x00 # SWITCH_FPGA: BMC Write Protect
            ;;
        *)
            return -1
            ;;
    esac
}

fru_wp_config=(
    "base     ${BASECPLD_SYSFS_DIR}/base_eeprom_wp"
    "fan1     ${FAN1CPLD_SYSFS_DIR}/fan_eeprom_wp"
    "fan2     ${FAN2CPLD_SYSFS_DIR}/fan_eeprom_wp"
    "switch   ${SWB_MISCCPLD_SYSFS_DIR}/switch_eeprom_wp"
)

MAC_POWER_SENSORS=(
    "48:0x60:in2_input:curr3_input:VDD_M"
    "49:0x63:in2_input:curr3_input:VDD_T0"
    "49:0x63:in3_input:curr4_input:VDD_T1"
    "50:0x64:in2_input:curr3_input:VDD_T2"
    "50:0x64:in3_input:curr4_input:VDD_T3"
    "51:0x65:in2_input:curr3_input:VDD_T4"
    "51:0x65:in3_input:curr4_input:VDD_T5"
    "52:0x66:in2_input:curr3_input:VDD_T6"
    "52:0x66:in3_input:curr4_input:VDD_T7"
    "60:0x67:in2_input:curr2_input:DVDD_T0"
    "60:0x67:in3_input:curr3_input:DVDD_T1"
    "61:0x68:in2_input:curr2_input:DVDD_T2"
    "61:0x68:in3_input:curr3_input:DVDD_T3"
    "62:0x69:in2_input:curr2_input:DVDD_T4"
    "62:0x69:in3_input:curr3_input:DVDD_T5"
    "63:0x6a:in2_input:curr2_input:DVDD_T6"
    "63:0x6a:in3_input:curr3_input:DVDD_T7"
    "56:0x63:in2_input:curr2_input:AVDD_T0"
    "56:0x63:in3_input:curr3_input:AVDD_T1"
    "57:0x64:in2_input:curr2_input:AVDD_T2"
    "57:0x64:in3_input:curr3_input:AVDD_T3"
    "58:0x65:in2_input:curr2_input:AVDD_T4"
    "58:0x65:in3_input:curr3_input:AVDD_T5"
    "59:0x66:in2_input:curr2_input:AVDD_T6"
    "59:0x66:in3_input:curr3_input:AVDD_T7"
    "54:0x6b:in2_input:curr2_input:VDDHBID_T12"
    "54:0x6b:in3_input:curr3_input:VDDHBID_T37"
    "55:0x6e:in2_input:curr2_input:VDDHBID_T04"
    "55:0x6e:in3_input:curr3_input:VDDHBID_T56"
    "53:0x62:in2_input:curr2_input:HVDD_T03"
    "53:0x62:in3_input:curr3_input:HVDD_T47"
)

OSFP_POWER_SENSORS=(
    "104:0x67:in2_input:curr2_input:OSFP1_1_8_3V3"
    "104:0x67:in3_input:curr3_input:OSFP1_9_16_3V3"
    "105:0x68:in2_input:curr2_input:OSFP2_17_24_3V3"
    "105:0x68:in3_input:curr3_input:OSFP2_25_32_3V3"
    "106:0x69:in2_input:curr2_input:OSFP3_1_8_3V3"
    "106:0x69:in3_input:curr3_input:OSFP3_9_16_3V3"
    "107:0x6a:in2_input:curr2_input:OSFP4_17_24_3V3"
    "107:0x6a:in3_input:curr3_input:OSFP4_25_32_3V3"
)

PLATFORM_CHECKS_CONFIG=(
    # clock
    "BASE_CPLD 0  0xd  clock 0xb4 0 PCIE_CLK_ALARM_CLR   0"
    "BASE_CPLD 0  0xd  clock 0xb9 0 PECLK_MONITOR_ALARM  0"
    "MISC_CPLD 66 0x31 clock 0x7f 0 CPLD_CLK_156M25_MONITOR_ALARM 0"

    # power
    # "BASE_CPLD 0  0xd power 0x13 1 SLP_S3_N    1"
    "BASE_CPLD 0  0xd power 0x13 2 SLP_S45_N   1"
    "BASE_CPLD 0  0xd power 0x13 3 THERMTRIP_N 1"

    # pg
    "MISC_CPLD 66 0x31 pg 0x50 3 VCC3V3_FPGA_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x50 2 VCC1V8_FPGA_PG_R  1"
    "MISC_CPLD 66 0x31 pg 0x50 1 VCC1V2_FPGA_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x50 0 VCC1V0_FPGA_PG_R  1"
    "MISC_CPLD 66 0x31 pg 0x51 3 VDD1V8_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x51 2 VDD_M_PG_R  1"
    "MISC_CPLD 66 0x31 pg 0x51 1 R_1V8_VDDQPS_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x51 0 P_AVDD_PG_R  1"
    "MISC_CPLD 66 0x31 pg 0x52 5 HVDD_T0_3_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x52 4 HVDD_T4_7_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x52 3 VDDHBID_T1_T2_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x52 2 VDDHBID_T0_T4_PG_R  1"
    "MISC_CPLD 66 0x31 pg 0x52 1 VDDHBID_T5_T6_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x52 0 VDDHBID_T3_T7_PG_R  1"
    "MISC_CPLD 66 0x31 pg 0x53 7 VDD_T0_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x53 6 VDD_T1_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x53 5 VDD_T2_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x53 4 VDD_T3_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x53 3 VDD_T4_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x53 2 VDD_T5_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x53 1 VDD_T6_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x53 0 VDD_T7_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x54 7 AVDD_T0_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x54 6 AVDD_T1_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x54 5 AVDD_T2_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x54 4 AVDD_T3_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x54 3 AVDD_T4_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x54 2 AVDD_T5_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x54 1 AVDD_T6_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x54 0 AVDD_T7_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x55 7 VCC2V1_LDO_IN_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x55 6 VCC3V6_LDO_IN_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x55 5 VCC3V3_SB_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x55 4 VDD3V3_PLL_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x55 3 VDD1V8_PLL_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x55 2 VDD3V3_LED_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x55 1 VCC5V_MOS_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x55 0 P_DVDD_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x56 7 DVDD_T0_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x56 6 DVDD_T1_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x56 5 DVDD_T2_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x56 4 DVDD_T3_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x56 3 DVDD_T4_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x56 2 DVDD_T5_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x56 1 DVDD_T6_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x56 0 DVDD_T7_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x57 7 VCC3V3_OSFP_1_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x57 6 VCC3V3_OSFP_2_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x57 5 VCC3V3_OSFP_3_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x57 4 VCC3V3_OSFP_4_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x57 3 VCC3V3_OSFP_5_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x57 2 VCC3V3_OSFP_6_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x57 1 VCC3V3_OSFP_7_PG_R 1"
    "MISC_CPLD 66 0x31 pg 0x57 0 VCC3V3_OSFP_8_PG_R 1"

    # alert
    "MISC_CPLD 66 0x31 alert 0x5A 2 HVDD_T03T47_VRFAULT_C  1"
    "MISC_CPLD 66 0x31 alert 0x5A 1 HVDD_T03T47_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5A 0 HVDD_T03T47_VRHOT_C  1"
    "MISC_CPLD 66 0x31 alert 0x5B 5 VDDHBID_VRFAULT_1_C 1"
    "MISC_CPLD 66 0x31 alert 0x5B 4 VDDHBID_PINALERT_1_C 1"
    "MISC_CPLD 66 0x31 alert 0x5B 3 VDDHBID_VRHOT_1_C 1"
    "MISC_CPLD 66 0x31 alert 0x5B 2 VDDHBID_VRFAULT_2_C  1"
    "MISC_CPLD 66 0x31 alert 0x5B 1 VDDHBID_PINALERT_2_C 1"
    "MISC_CPLD 66 0x31 alert 0x5B 0 VDDHBID_VRHOT_2_C  1"
    "MISC_CPLD 66 0x31 alert 0x5C 5 AVDD_T0T1_VRFAULT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5C 4 AVDD_T0T1_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5C 3 AVDD_T0T1_VRHOT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5C 2 AVDD_T2T3_VRFAULT_C  1"
    "MISC_CPLD 66 0x31 alert 0x5C 1 AVDD_T2T3_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5C 0 AVDD_T2T3_VRHOT_C  1"
    "MISC_CPLD 66 0x31 alert 0x5D 5 AVDD_T4T5_VRFAULT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5D 4 AVDD_T4T5_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5D 3 AVDD_T4T5_VRHOT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5D 2 AVDD_T6T7_VRFAULT_C  1"
    "MISC_CPLD 66 0x31 alert 0x5D 1 AVDD_T6T7_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5D 0 AVDD_T6T7_VRHOT_C  1"
    "MISC_CPLD 66 0x31 alert 0x5E 5 DVDD_T0T1_VRFAULT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5E 4 DVDD_T0T1_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5E 3 DVDD_T0T1_VRHOT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5E 2 DVDD_T2T3_VRFAULT_C  1"
    "MISC_CPLD 66 0x31 alert 0x5E 1 DVDD_T2T3_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5E 0 DVDD_T2T3_VRHOT_C  1"
    "MISC_CPLD 66 0x31 alert 0x5F 5 DVDD_T4T5_VRFAULT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5F 4 DVDD_T4T5_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5F 3 DVDD_T4T5_VRHOT_1_C 1"
    "MISC_CPLD 66 0x31 alert 0x5F 2 DVDD_T6T7_VRFAULT_C  1"
    "MISC_CPLD 66 0x31 alert 0x5F 1 DVDD_T6T7_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x5F 0 DVDD_T6T7_VRHOT_C  1"
    "MISC_CPLD 66 0x31 alert 0x60 5 VCC3V3_OSFP1_16_VRFAULT_C 1"
    "MISC_CPLD 66 0x31 alert 0x60 4 VCC3V3_OSFP1_16_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x60 3 VCC3V3_OSFP1_16_VRHOT_C 1"
    "MISC_CPLD 66 0x31 alert 0x60 2 VCC3V3_OSFP17_32_VRFAULT_C  1"
    "MISC_CPLD 66 0x31 alert 0x60 1 VCC3V3_OSFP17_32_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x60 0 VCC3V3_OSFP17_32_VRHOT_C  1"
    "MISC_CPLD 66 0x31 alert 0x61 5 VCC3V3_OSFP33_48_VRFAULT_C 1"
    "MISC_CPLD 66 0x31 alert 0x61 4 VCC3V3_OSFP33_48_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x61 3 VCC3V3_OSFP33_48_VRHOT_C 1"
    "MISC_CPLD 66 0x31 alert 0x61 2 VCC3V3_OSFP49_64_VRFAULT_C  1"
    "MISC_CPLD 66 0x31 alert 0x61 1 VCC3V3_OSFP49_64_PINALERT_C 1"
    "MISC_CPLD 66 0x31 alert 0x61 0 VCC3V3_OSFP49_64_VRHOT_C  1"

    # int
    "MISC_CPLD 66 0x31 int 0xF1 6 S_ASIC_TEMP_SHTDN 1"
    "MISC_CPLD 66 0x31 int 0xF1 5 S_ASIC_TEMP_WARN 1"
    "MISC_CPLD 66 0x31 int 0xF1 4 S_HEALTH 1"
    "MISC_CPLD 66 0x31 int 0xF1 3 TS2_INT_C 1"
    "MISC_CPLD 66 0x31 int 0xF1 2 TS1_INT_C 1"
    "MISC_CPLD 66 0x31 int 0xF1 1 PLL_INT_N_R 1"
    "MISC_CPLD 66 0x31 int 0xF1 0 TMP275_ALERT_R 1"

    # en
    "MISC_CPLD 66 0x31 en 0x65 1 VCC3V3_PLL_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x65 0 VCC1V8_PLL_EN_R  1"
    "MISC_CPLD 66 0x31 en 0x66 5 VCC1V8_FPGA_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x66 4 VCC1V2_FPGA_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x66 3 VCC1V0_FPGA_EN_R  1"
    "MISC_CPLD 66 0x31 en 0x66 2 VCC3V3_FPGA_EN_R  1"
    "MISC_CPLD 66 0x31 en 0x66 1 VCC3V3_LED_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x66 0 VCC3V3_LEDCPLD_EN_R  1"
    "MISC_CPLD 66 0x31 en 0x67 4 R_1V8_VDDIO_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x67 3 VDD_T_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x67 2 VDD_M_EN_R  1"
    "MISC_CPLD 66 0x31 en 0x67 1 R_1V8_VDDQPS_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x67 0 HVDD_T_EN_R  1"
    "MISC_CPLD 66 0x31 en 0x68 4 VDDHBID_T_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x68 3 P_AVDD_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x68 2 AVDD_T_EN_R  1"
    "MISC_CPLD 66 0x31 en 0x68 1 P_DVDD_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x68 0 DVDD_T_EN_R  1"
    "MISC_CPLD 66 0x31 en 0x69 7 VCC3V3_OSFP1_8_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x69 6 VCC3V3_OSFP9_16_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x69 5 VCC3V3_OSFP17_24_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x69 4 VCC3V3_OSFP25_32_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x69 3 VCC3V3_OSFP33_40_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x69 2 VCC3V3_OSFP41_48_EN_R  1"
    "MISC_CPLD 66 0x31 en 0x69 1 VCC3V3_OSFP49_56_EN_R 1"
    "MISC_CPLD 66 0x31 en 0x69 0 VCC3V3_OSFP57_64_EN_R  1"
)

SETUP_INA3221_SHUNT_CONFIG_LIST="
29  0x40  shunt1_resistor  2000
29  0x40  shunt2_resistor  2000
29  0x40  shunt3_resistor  2000
30  0x40  shunt1_resistor  2000
30  0x40  shunt2_resistor  2000
30  0x40  shunt3_resistor  2000
31  0x40  shunt1_resistor  2000
31  0x40  shunt2_resistor  2000
31  0x40  shunt3_resistor  2000
35  0x40  shunt1_resistor  2000
35  0x40  shunt2_resistor  2000
35  0x40  shunt3_resistor  2000
36  0x40  shunt1_resistor  2000
36  0x40  shunt2_resistor  2000
36  0x40  shunt3_resistor  2000
37  0x40  shunt1_resistor  2000
37  0x40  shunt2_resistor  2000
37  0x40  shunt3_resistor  2000
38  0x40  shunt1_resistor  2000
38  0x40  shunt2_resistor  2000
38  0x40  shunt3_resistor  2000
39  0x40  shunt1_resistor  2000
39  0x40  shunt2_resistor  2000
39  0x40  shunt3_resistor  2000
108  0x40  shunt1_resistor  10000
108  0x40  shunt2_resistor  10000
108  0x40  shunt3_resistor  10000
"
#################################################################################
#SoC addr
#################################################################################
wdt_addr() {
    echo $((0x14C37280 + 0x$1))
}

adc_addr() {
    echo $((0x14C00000 + 0x$1))
}

#################################################################################
iso_buf_enable() {
    # TODO, no isolation buffer
    return 0
}

iso_buf_disable() {
    # TODO, no isolation buffer
    return 0
}

is_us_on() {
    local val

     val=$(i2cget -y -f 0 0x0d 0x12 2> /dev/null | head -n 1)
     if [ "$((${val} & 0x01))" != "1" ] && [ "$((${val} & 0x10))" != "0" ]; then
         return 0            # powered on
     else
         return 1
     fi

    # default is power on
    return 0
}

board_type() {
    echo 'Qcat'
}

slot_id() {
    printf "1\n"
}

board_rev() {
    # local val0 val1 val2
    # val0=$(gpio_get_value BMC_CPLD_BOARD_REV_ID0)
    # val1=$(gpio_get_value BMC_CPLD_BOARD_REV_ID1)
    # val2=$(gpio_get_value BMC_CPLD_BOARD_REV_ID2)
    # echo $((val0 | (val1 << 1) | (val2 << 2)))

    local val
    val=$(cat $SCMCPLD_SYSFS_DIR/board_ver | head -1)

    echo $val
}

# Should we enable OOB interface or not
should_enable_oob() {
    # minipack uses BMC MAC since beginning
    return -1
}

power_on_board() {
    # minipack SCM power is controlled by SCMCPLD
    return 0
}

i2c_driver_bind_device_check() {
    local bus=$1
    local addr=$2
    local name=$3
    local driver_dir="${SYSFS_I2C_DEVICES}/${bus}-00${addr}/hwmon/hwmon*"
    local time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
	if [ ! -d ${driver_dir} ]; then
        #echo "unable to locate i2c driver ${driver_dir} in sysfs"
        echo "$time_stamp INFO: unable to locate i2c driver ${driver_dir} in sysfs" >> /var/volatile/log/syslog; sync
        return 1
    fi
    retval=`cat ${SYSFS_I2C_DEVICES}/${bus}-00${addr}/hwmon/hwmon*/name`
    if [ $? -ne 0 ]; then
        #echo "The ${name}(${bus}-${addr}) read operation error."
        echo "$time_stamp INFO: The ${name}(${bus}-${addr}) read operation error." >> /var/volatile/log/syslog; sync
        return 1
    else
        if [ "$retval" != "$name" ]; then
            #echo "The ${name}(${bus}-${addr}) read name(${retval}) info check error."
            echo "$time_stamp INFO: The ${name}(${bus}-${addr}) read name(${retval}) info check error." >> /var/volatile/log/syslog; sync
            return 1
        fi
    fi
    return 0
}

i2c_device_rebind() {
    local bus=$1
    local addr=$2
    local name=$3
    i2c_device_delete ${bus} 0x${addr} 2> /dev/null
    sleep 0.1
    i2c_device_add ${bus} 0x${addr} ${name}
    return 0
}

i2c_check_driver_bind_opt() {
    local retry=0
    local retry_max=5
    local bus=$1
    local addr=$2
    local name=$3

    while true
    do
        time_stamp=$(date "+%Y-%m-%d %H:%M:%S")
        if [ $retry -ge ${retry_max} ]; then
            #echo "failed to bind ${name}(${bus}-${addr}) after ${retry} retries"
            echo "$time_stamp INFO: failed to bind ${name}(${bus}-${addr}) after ${retry} retries" >> /var/volatile/log/syslog; sync
            return 1
        fi
        i2c_driver_bind_device_check ${bus} ${addr} ${name}
        if [ "$?" -eq "0" ]; then
            break
        else
            i2c_device_rebind ${bus} ${addr} ${name}
        fi
        sleep 0.2
        retry=$((retry + 1))
    done
    return 0
}


CPLD_NAME=(ocm_cpld sys_cpld fan1_cpld fan2_cpld misc_cpld port_cpld1 port_cpld2 led_cpld switch_fpga)
CPLD_BUS=(16 0 8 3 66 64 65 68 67)
CPLD_ADDR=(0xd 0xd 0xd 0xd 0x31 0x31 0x31 0x31 0x32)

###############################################################################
# Function.

read_cpld_reg()
{
    cs=$1
    offset=$2
    reg_val_str=`i2cget -f -y ${CPLD_BUS[$cs]} ${CPLD_ADDR[$cs]} $offset`
    echo "$reg_val_str"
}

write_cpld_reg()
{
    cs=$1
    offset=$2
	value=$3
    i2cset -f -y ${CPLD_BUS[$cs]} ${CPLD_ADDR[$cs]} $offset $value
    return $?
}

get_cpld_reg_bit()
{
    cs=$1
    offset=$2
    bit=$3

    reg_val=`read_cpld_reg $cs $offset`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%08X' $bit_mask`
    reg_new_val=$(($reg_val&$bit_mask_str))
    [ 0 -eq $reg_new_val ] && ret=0 || ret=1

    return $ret
}

set_cpld_reg_bit()
{
    cs=$1
    offset=$2
    bit=$3

    reg_val=`read_cpld_reg $cs $offset`
    #echo "set_cpld_reg_bit reg_val = $reg_val"
    bit_mask=$((1<<$bit))
    #echo "set_cpld_reg_bit bit_mask = $bit_mask"
    bit_mask_str=`printf '0x%08X' $bit_mask`
    #echo "set_cpld_reg_bit bit_mask_str = $bit_mask_str"
    reg_new_val=$(($reg_val|$bit_mask_str))
    #echo "set_cpld_reg_bit reg_new_val = $reg_new_val"
    write_cpld_reg $cs $offset $reg_new_val
    return $?
}

clr_cpld_reg_bit()
{
    cs=$1
    offset=$2
    bit=$3

    reg_val=`read_cpld_reg $cs $offset`
    bit_mask=$((1<<$bit))
    bit_mask_str=`printf '0x%08X' $((~$bit_mask))`
    reg_new_val=$(($reg_val&$bit_mask_str))
    write_cpld_reg $cs $offset $reg_new_val
    return $?
}

#获取fan board类型，0:风冷 1:液冷
get_fan_board_type()
{
    if [ -r "$FAN_BOARD_TYPE_SYSFS" ]; then
        read value < "$FAN_BOARD_TYPE_SYSFS" 2> /dev/null
        printf '%d\n' "$value"
    else
        printf ''
    fi
}
