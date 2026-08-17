#!/bin/sh
#
# Copyright 2018-present Facebook. All Rights Reserved.
#
# This program file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program in a file named COPYING; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA
#


echo "fan and power threshold: "


#FAN1,FAN2,FAN3,FAN4
#fan*_1_L is front fan LowThd
#fan*_1_H is rear fan HighThd
echo "fan1_1_L: 4050"
echo "fan1_1_H: 16500"
echo "fan1_2_L: 3834"
echo "fan1_2_H: 15620"

echo "fan2_1_L: 4050"
echo "fan2_1_H: 16500"
echo "fan2_2_L: 3834"
echo "fan2_2_H: 15620"

echo "fan3_1_L: 4050"
echo "fan3_1_H: 16500"
echo "fan3_2_L: 3834"
echo "fan3_2_H: 15620"

echo "fan4_1_L: 4050"
echo "fan4_1_H: 16500"
echo "fan4_2_L: 3834"
echo "fan4_2_H: 15620"

echo "fan5_1_L: 4050"
echo "fan5_1_H: 16500"
echo "fan5_2_L: 3834"
echo "fan5_2_H: 15620"

#L is LowThd, H is HighThd

#TEMP
echo "outlet1_temp_L: -10"
echo "outlet1_temp_H: 60"
echo "outlet2_temp_L: -10"
echo "outlet2_temp_H: 60"

echo "server_temp_1_L: -10"
echo "server_temp_1_H: 90"
echo "server_temp_2_L: -10"
echo "server_temp_2_H: 90"
echo "server_temp_3_L: -10"
echo "server_temp_3_H: 105"

echo "inlet1_temp_L: -5"
echo "inlet1_temp_H: 45"
echo "inlet2_temp_L: -5"
echo "inlet2_temp_H: 45"

echo "switch_temp_L: -10"
echo "switch_temp_H: 105"

#get value of PSU1 and PSU2 iin/iout/pin/pout HighThd
psu_iin_H=`cat /var/tmp/psu_th_iin`
psu_pin_H=`cat /var/tmp/psu_th_pin`
psu_iout_H=`cat /var/tmp/psu_th_iout`
psu_pout_H=`cat /var/tmp/psu_th_pout`

#PSU1
PSU1_INPUT_TYPE=`psu-util psu1 --get_psu_info | sed -n 15p | cut -d ":" -f2`
psu1_INPUT_TYPE_cut=`echo $PSU1_INPUT_TYPE | cut -d " " -f2`
if [ "$psu1_INPUT_TYPE_cut" == "AC" ]; then
    psu1_vin_L=200
    psu1_vin_H=240
elif [ "$psu1_INPUT_TYPE_cut" == "DC" ]; then
    psu1_vin_L=190
    psu1_vin_H=290
else
    psu1_vin_L="N/A"
    psu1_vin_H="N/A"
fi
echo "psu1_vin_L: " $psu1_vin_L
echo "psu1_vin_H: " $psu1_vin_H
echo "psu1_iin_L: 0"
echo "psu1_iin_H: " $psu_iin_H
echo "psu1_pin_L: 0"
echo "psu1_pin_H: " $psu_pin_H

echo "psu1_vout_L: 11"
echo "psu1_vout_H: 13"
echo "psu1_iout_L: 0"
echo "psu1_iout_H: " $psu_iout_H
echo "psu1_pout_L: 0"
echo "psu1_pout_H: " $psu_pout_H

PSU1_MFR_MODEL=`psu-util psu1 --get_eeprom_info | sed -n 5p | cut -d ":" -f2`
psu1_MFR_MODEL_cut=`echo $PSU1_MFR_MODEL | cut -d " " -f1`
if [ "$psu1_MFR_MODEL_cut" == "DPST-1630AB" ]; then
    psu1_fan_H=31800
elif [ "$psu1_MFR_MODEL_cut" == "DPST-2030AB" ]; then
    psu1_fan_H=37375
else
    psu1_fan_H="N/A"
fi
echo "psu1_fan_L: 1000"
echo "psu1_fan_H: " $psu1_fan_H

echo "psu1_temp_1_L: -5"
echo "psu1_temp_1_H: 50"
echo "psu1_temp_2_L: -5"
echo "psu1_temp_2_H: 110"
echo "psu1_temp_3_L: -5"
echo "psu1_temp_3_H: 110"


#PSU2
PSU2_INPUT_TYPE=`psu-util psu2 --get_psu_info | sed -n 15p | cut -d ":" -f2`
psu2_INPUT_TYPE_cut=`echo $PSU2_INPUT_TYPE | cut -d " " -f2`
if [ "$psu2_INPUT_TYPE_cut" == "AC" ]; then
    psu2_vin_L=200
    psu2_vin_H=240
elif [ "$psu2_INPUT_TYPE_cut" == "DC" ]; then
    psu2_vin_L=190
    psu2_vin_H=290
else
    psu2_vin_L="N/A"
    psu2_vin_H="N/A"
fi
echo "psu2_vin_L: " $psu2_vin_L
echo "psu2_vin_H: " $psu2_vin_H
echo "psu2_iin_L: 0"
echo "psu2_iin_H: " $psu_iin_H
echo "psu2_pin_L: 0"
echo "psu2_pin_H: " $psu_pin_H

echo "psu2_vout_L: 11"
echo "psu2_vout_H: 13"
echo "psu2_iout_L: 0"
echo "psu2_iout_H: " $psu_iout_H
echo "psu2_pout_L: 0"
echo "psu2_pout_H: " $psu_pout_H

PSU2_MFR_MODEL=`psu-util psu2 --get_eeprom_info | sed -n 5p | cut -d ":" -f2`
psu2_MFR_MODEL_cut=`echo $PSU2_MFR_MODEL | cut -d " " -f1`
if [ "$psu2_MFR_MODEL_cut" == "DPST-1630AB" ]; then
    psu2_fan_H=31800
elif [ "$psu2_MFR_MODEL_cut" == "DPST-2030AB" ]; then
    psu2_fan_H=37375
else
    psu2_fan_H="N/A"
fi
echo "psu2_fan_L: 1000"
echo "psu2_fan_H: " $psu2_fan_H

echo "psu2_temp_1_L: -5"
echo "psu2_temp_1_H: 50"
echo "psu2_temp_2_L: -5"
echo "psu2_temp_2_H: 110"
echo "psu2_temp_3_L: -5"
echo "psu2_temp_3_H: 110"


#RISER
echo "slot_1&2&3_vout_L: 2.97"
echo "slot_1&2&3_vout_H: 3.63"
echo "slot_1&2&3_iout_L: -1"
echo "slot_1&2&3_iout_H: 9"
echo "slot_1&2&3_pout_L: -1"
echo "slot_1&2&3_pout_H: 30"
echo "slot_4&5&6_vout_L: 2.97"
echo "slot_4&5&6_vout_H: 3.63"
echo "slot_4&5&6_iout_L: -1"
echo "slot_4&5&6_iout_H: 9"
echo "slot_4&5&6_pout_L: -1"
echo "slot_4&5&6_pout_H: 30"


#SERVER
echo "pch_pvnn_vout_L: 0.9"
echo "pch_pvnn_vout_H: 1.1"
echo "pch_pvnn_iout_L: 0"
echo "pch_pvnn_iout_H: 21"
echo "pch_pvnn_pout_L: 0"
echo "pch_pvnn_pout_H: 22"
echo "pch_pvnn_temp_L: 0"
echo "pch_pvnn_temp_H: 90"

echo "pch_1v05_vout_L: 0.95"
echo "pch_1v05_vout_H: 1.16"
echo "pch_1v05_iout_L: 0"
echo "pch_1v05_iout_H: 15"
echo "pch_1v05_pout_L: 0"
echo "pch_1v05_pout_H: 16.2"
echo "pch_1v05_temp_L: 0"
echo "pch_1v05_temp_H: 90"

echo "pch_1v8_vout_L: 1.62"
echo "pch_1v8_vout_H: 1.98"
echo "pch_1v8_iout_L: 0"
echo "pch_1v8_iout_H: 1.5"
echo "pch_1v8_pout_L: 0"
echo "pch_1v8_pout_H: 2.8"

echo "p3v3_stby_vout_L: 2.97"
echo "p3v3_stby_vout_H: 3.63"
echo "p3v3_stby_iout_L: 0"
echo "p3v3_stby_iout_H: 7"
echo "p3v3_stby_pout_L: 0"
echo "p3v3_stby_pout_H: 24"

echo "p3v3_vout_L: 2.97"
echo "p3v3_vout_H: 3.63"
echo "p3v3_iout_L: 0"
echo "p3v3_iout_H: 7"
echo "p3v3_pout_L: 0"
echo "p3v3_pout_H: 24"

echo "p5v_vout_L: 4.5"
echo "p5v_vout_H: 5.5"
echo "p5v_iout_L: 0"
echo "p5v_iout_H: 2.5"
echo "p5v_pout_L: 0"
echo "p5v_pout_H: 12.5"

echo "cpu0_vccin_vout_L: 1.5"
echo "cpu0_vccin_vout_H: 2"
echo "cpu0_vccin_iout_L: 0"
echo "cpu0_vccin_iout_H: 228"
echo "cpu0_vccin_pout_L: 0"
echo "cpu0_vccin_pout_H: 364.8"
echo "cpu0_vccin_temp_L: 0"
echo "cpu0_vccin_temp_H: 90"

echo "cpu0_vccsa_vout_L: 0.45"
echo "cpu0_vccsa_vout_H: 1.2"
echo "cpu0_vccsa_iout_L: 0"
echo "cpu0_vccsa_iout_H: 16"
echo "cpu0_vccsa_pout_L: 0"
echo "cpu0_vccsa_pout_H: 17"
echo "cpu0_vccsa_temp_L: 0"
echo "cpu0_vccsa_temp_H: 90"

echo "cpu0_vccio_vout_L: 0.9"
echo "cpu0_vccio_vout_H: 1.1"
echo "cpu0_vccio_iout_L: 0"
echo "cpu0_vccio_iout_H: 21"
echo "cpu0_vccio_pout_L: 0"
echo "cpu0_vccio_pout_H: 21"
echo "cpu0_vccio_temp_L: 0"
echo "cpu0_vccio_temp_H: 90"

echo "cpu0_vddq_abc_vout_L: 0.7"
echo "cpu0_vddq_abc_vout_H: 1.4"
echo "cpu0_vddq_abc_iout_L: 0"
echo "cpu0_vddq_abc_iout_H: 25"
echo "cpu0_vddq_abc_pout_L: 0"
echo "cpu0_vddq_abc_pout_H: 30"
echo "cpu0_vddq_abc_temp_L: 0"
echo "cpu0_vddq_abc_temp_H: 90"

echo "cpu0_vpp_abc_vout_L: 2.25"
echo "cpu0_vpp_abc_vout_H: 2.75"
echo "cpu0_vpp_abc_iout_L: -1"
echo "cpu0_vpp_abc_iout_H: 8"
echo "cpu0_vpp_abc_pout_L: -1"
echo "cpu0_vpp_abc_pout_H: 20"
echo "cpu0_vpp_abc_temp_L: 0"
echo "cpu0_vpp_abc_temp_H: 90"

echo "cpu0_vddq_def_vout_L: 0.7"
echo "cpu0_vddq_def_vout_H: 1.4"
echo "cpu0_vddq_def_iout_L: 0"
echo "cpu0_vddq_def_iout_H: 25"
echo "cpu0_vddq_def_pout_L: 0"
echo "cpu0_vddq_def_pout_H: 30"
echo "cpu0_vddq_def_temp_L: 0"
echo "cpu0_vddq_def_temp_H: 90"

echo "cpu0_vpp_def_vout_L: 2.25"
echo "cpu0_vpp_def_vout_H: 2.75"
echo "cpu0_vpp_def_iout_L: -1"
echo "cpu0_vpp_def_iout_H: 8"
echo "cpu0_vpp_def_pout_L: -1"
echo "cpu0_vpp_def_pout_H: 20"
echo "cpu0_vpp_def_temp_L: 0"
echo "cpu0_vpp_def_temp_H: 90"

echo "cpu1_vccin_vout_L: 1.5"
echo "cpu1_vccin_vout_H: 2"
echo "cpu1_vccin_iout_L: 0"
echo "cpu1_vccin_iout_H: 228"
echo "cpu1_vccin_pout_L: 0"
echo "cpu1_vccin_pout_H: 364.8"
echo "cpu1_vccin_temp_L: 0"
echo "cpu1_vccin_temp_H: 90"

echo "cpu1_vcccsa_vout_L: 0.45"
echo "cpu1_vcccsa_vout_H: 1.2"
echo "cpu1_vcccsa_iout_L: 0"
echo "cpu1_vcccsa_iout_H: 16"
echo "cpu1_vcccsa_pout_L: 0"
echo "cpu1_vcccsa_pout_H: 17"
echo "cpu1_vcccsa_temp_L: 0"
echo "cpu1_vcccsa_temp_H: 90"

echo "cpu1_vccio_vout_L: 0.9"
echo "cpu1_vccio_vout_H: 1.1"
echo "cpu1_vccio_iout_L: 0"
echo "cpu1_vccio_iout_H: 21"
echo "cpu1_vccio_pout_L: 0"
echo "cpu1_vccio_pout_H: 21"
echo "cpu1_vccio_temp_L: 0"
echo "cpu1_vccio_temp_H: 90"

echo "cpu1_vddq_ghj_vout_L: 0.7"
echo "cpu1_vddq_ghj_vout_H: 1.4"
echo "cpu1_vddq_ghj_iout_L: 0"
echo "cpu1_vddq_ghj_iout_H: 25"
echo "cpu1_vddq_ghj_pout_L: 0"
echo "cpu1_vddq_ghj_pout_H: 30"
echo "cpu1_vddq_ghj_temp_L: 0"
echo "cpu1_vddq_ghj_temp_H: 90"

echo "cpu1_vpp_ghj_vout_L: 2.25"
echo "cpu1_vpp_ghj_vout_H: 2.75"
echo "cpu1_vpp_ghj_iout_L: -1"
echo "cpu1_vpp_ghj_iout_H: 8"
echo "cpu1_vpp_ghj_pout_L: -1"
echo "cpu1_vpp_ghj_pout_H: 20"
echo "cpu1_vpp_ghj_temp_L: 0"
echo "cpu1_vpp_ghj_temp_H: 90"

echo "cpu1_vddq_klm_vout_L: 0.7"
echo "cpu1_vddq_klm_vout_H: 1.4"
echo "cpu1_vddq_klm_iout_L: 0"
echo "cpu1_vddq_klm_iout_H: 25"
echo "cpu1_vddq_klm_pout_L: 0"
echo "cpu1_vddq_klm_pout_H: 30"
echo "cpu1_vddq_klm_temp_L: 0"
echo "cpu1_vddq_klm_temp_H: 90"

echo "cpu1_vpp_klm_vout_L: 2.25"
echo "cpu1_vpp_klm_vout_H: 2.75"
echo "cpu1_vpp_klm_iout_L: -1"
echo "cpu1_vpp_klm_iout_H: 8"
echo "cpu1_vpp_klm_pout_L: -1"
echo "cpu1_vpp_klm_pout_H: 20"
echo "cpu1_vpp_klm_temp_L: 0"
echo "cpu1_vpp_klm_temp_H: 90"

echo "p12v_psu_efuse_vin_L: 11"
echo "p12v_psu_efuse_vin_H: 13"
echo "p12v_psu_efuse_iin_L: 1.7"
echo "p12v_psu_efuse_iin_H: " $psu_iout_H
echo "p12v_psu_efuse_pin_L: 24.7"
echo "p12v_psu_efuse_pin_H: " $psu_pout_H
echo "p12v_psu_efuse_temp_L: 0"
echo "p12v_psu_efuse_temp_H: 90"
echo "p12v_psu_efuse_vout_L: 11"
echo "p12v_psu_efuse_vout_H: 13"

echo "p12v_slot1_res_efuse_vin_L: 11"
echo "p12v_slot1_res_efuse_vin_H: 13"
echo "p12v_slot1_res_efuse_iin_L: -1"
echo "p12v_slot1_res_efuse_iin_H: 6.3"
echo "p12v_slot1_res_efuse_pin_L: -1"
echo "p12v_slot1_res_efuse_pin_H: 75"
echo "p12v_slot1_res_efuse_temp_L: 0"
echo "p12v_slot1_res_efuse_temp_H: 90"
echo "p12v_slot1_res_efuse_vout_L: 11"
echo "p12v_slot1_res_efuse_vout_H: 13"

echo "p12v_slot1_efuse_vin_L: 11"
echo "p12v_slot1_efuse_vin_H: 13"
echo "p12v_slot1_efuse_iin_L: -1"
echo "p12v_slot1_efuse_iin_H: 6.3"
echo "p12v_slot1_efuse_pin_L: -1"
echo "p12v_slot1_efuse_pin_H: 75"
echo "p12v_slot1_efuse_temp_L: 0"
echo "p12v_slot1_efuse_temp_H: 90"
echo "p12v_slot1_efuse_vout_L: 11"
echo "p12v_slot1_efuse_vout_H: 13"

echo "p12v_slot2_efuse_vin_L: 11"
echo "p12v_slot2_efuse_vin_H: 13"
echo "p12v_slot2_efuse_iin_L: -1"
echo "p12v_slot2_efuse_iin_H: 6.3"
echo "p12v_slot2_efuse_pin_L: -1"
echo "p12v_slot2_efuse_pin_H: 75"
echo "p12v_slot2_efuse_temp_L: 0"
echo "p12v_slot2_efuse_temp_H: 90"
echo "p12v_slot2_efuse_vout_L: 11"
echo "p12v_slot2_efuse_vout_H: 13"

echo "p12v_slot3_efuse_vin_L: 11"
echo "p12v_slot3_efuse_vin_H: 13"
echo "p12v_slot3_efuse_iin_L: -1"
echo "p12v_slot3_efuse_iin_H: 6.3"
echo "p12v_slot3_efuse_pin_L: -1"
echo "p12v_slot3_efuse_pin_H: 75"
echo "p12v_slot3_efuse_temp_L: 0"
echo "p12v_slot3_efuse_temp_H: 90"
echo "p12v_slot3_efuse_vout_L: 11"
echo "p12v_slot3_efuse_vout_H: 13"

echo "p12v_slot4_res_efuse_vin_L: 11"
echo "p12v_slot4_res_efuse_vin_H: 13"
echo "p12v_slot4_res_efuse_iin_L: -1"
echo "p12v_slot4_res_efuse_iin_H: 6.3"
echo "p12v_slot4_res_efuse_pin_L: -1"
echo "p12v_slot4_res_efuse_pin_H: 75"
echo "p12v_slot4_res_efuse_temp_L: 0"
echo "p12v_slot4_res_efuse_temp_H: 90"
echo "p12v_slot4_res_efuse_vout_L: 11"
echo "p12v_slot4_res_efuse_vout_H: 13"

echo "p12v_slot4_efuse_vin_L: 11"
echo "p12v_slot4_efuse_vin_H: 13"
echo "p12v_slot4_efuse_iin_L: -1"
echo "p12v_slot4_efuse_iin_H: 6.3"
echo "p12v_slot4_efuse_pin_L: -1"
echo "p12v_slot4_efuse_pin_H: 75"
echo "p12v_slot4_efuse_temp_L: 0"
echo "p12v_slot4_efuse_temp_H: 90"
echo "p12v_slot4_efuse_vout_L: 11"
echo "p12v_slot4_efuse_vout_H: 13"


#SWITCH
echo "MAC_CORE_Vin_L: 11"
echo "MAC_CORE_Vin_H: 13"
echo "MAC_CORE_Iin_L: 0"
echo "MAC_CORE_Iin_H: 28"
echo "MAC_CORE_Pin_L: 0"
echo "MAC_CORE_Pin_H: 310"
echo "MAC_CORE_Vout_L: 0.65"
echo "MAC_CORE_Vout_H: 1.1"
echo "MAC_CORE_Cout_L: 0"
echo "MAC_CORE_Cout_H: 322.5"
echo "MAC_CORE_Pout_L: 0"
echo "MAC_CORE_Pout_H: 306"

echo "MAC_ANLG_Vin_L: 11"
echo "MAC_ANLG_Vin_H: 13"
echo "MAC_ANLG_Iin_L: 0"
echo "MAC_ANLG_Iin_H: 6.7"
echo "MAC_ANLG_Pin_L: 0"
echo "MAC_ANLG_Pin_H: 80"
echo "MAC_ANLG_Vout_L: 0.81"
echo "MAC_ANLG_Vout_H: 0.99"
echo "MAC_ANLG_Iout_L: 0"
echo "MAC_ANLG_Iout_H: 57.6"
echo "MAC_ANLG_Pout_L: 0"
echo "MAC_ANLG_Pout_H: 51.3"

echo "QSFP28_Vin_L: 11"
echo "QSFP28_Vin_H: 13"
echo "QSFP28_Iin_L: -1"
echo "QSFP28_Iin_H: 11.6"
echo "QSFP28_Pin_L: -1"
echo "QSFP28_Pin_H: 147"
echo "QSFP28_Vout_L: 2.97"
echo "QSFP28_Vout_H: 3.63"
echo "QSFP28_Iout_L: -1"
echo "QSFP28_Iout_H: 40"
echo "QSFP28_Pout_L: -1"
echo "QSFP28_Pout_H: 133"


#CPU/DIMM temp LowThd and HighThd
echo "cpu0_temp_L: 0"
echo "cpu0_temp_H: 93"
echo "cpu1_temp_L: 0"
echo "cpu1_temp_H: 93"
echo "cpu0_dimm0_temp_L: 0"
echo "cpu0_dimm0_temp_H: 85"
echo "cpu0_dimm1_temp_L: 0"
echo "cpu0_dimm1_temp_H: 85"
echo "cpu0_dimm2_temp_L: 0"
echo "cpu0_dimm2_temp_H: 85"
echo "cpu0_dimm3_temp_L: 0"
echo "cpu0_dimm3_temp_H: 85"
echo "cpu0_dimm4_temp_L: 0"
echo "cpu0_dimm4_temp_H: 85"
echo "cpu0_dimm5_temp_L: 0"
echo "cpu0_dimm5_temp_H: 85"
echo "cpu0_dimm6_temp_L: 0"
echo "cpu0_dimm6_temp_H: 85"
echo "cpu0_dimm7_temp_L: 0"
echo "cpu0_dimm7_temp_H: 85"
echo "cpu1_dimm0_temp_L: 0"
echo "cpu1_dimm0_temp_H: 85"
echo "cpu1_dimm1_temp_L: 0"
echo "cpu1_dimm1_temp_H: 85"
echo "cpu1_dimm2_temp_L: 0"
echo "cpu1_dimm2_temp_H: 85"
echo "cpu1_dimm3_temp_L: 0"
echo "cpu1_dimm3_temp_H: 85"
echo "cpu1_dimm4_temp_L: 0"
echo "cpu1_dimm4_temp_H: 85"
echo "cpu1_dimm5_temp_L: 0"
echo "cpu1_dimm5_temp_H: 85"
echo "cpu1_dimm6_temp_L: 0"
echo "cpu1_dimm6_temp_H: 85"
echo "cpu1_dimm7_temp_L: 0"
echo "cpu1_dimm7_temp_H: 85"


#ina3221 LowThd and HighThd
echo "5VDCVIN_L: 11"
echo "5VDCVIN_H: 13"
echo "VCC5P0_L: 4.5"
echo "VCC5P0_H: 5.5"
echo "2P5VDCVIN_L: 11"
echo "2P5VDCVIN_H: 13"
echo "VDDH_2P5V_L: 2.25"
echo "VDDH_2P5V_H: 2.75"
echo "1P2VDCVIN_L: 11"
echo "1P2VDCVIN_H: 13"
echo "VDD1P2_L: 1.08"
echo "VDD1P2_H: 1.32"
echo "3P3V2DCVIN_L: 11"
echo "3P3V2DCVIN_H: 13"
echo "VDD3P3_2_L: 2.97"
echo "VDD3P3_2_H: 3.63"
echo "1VDCVIN_L: 11"
echo "1VDCVIN_H: 13"
echo "VDD1P0_L: 0.9"
echo "VDD1P0_H: 1.1"
echo "1P8VDCVIN_L: 11"
echo "1P8VDCVIN_H: 13"
echo "VDD1P8_L: 1.62"
echo "VDD1P8_H: 1.98"
echo "3P3V3DCVIN_L: 11"
echo "3P3V3DCVIN_H: 13"
echo "VDD3P33DCVIN_L: 2.97"
echo "VDD3P33DCVIN_H: 3.63"
echo "USB5VDCVIN_L: 11"
echo "USB5VDCVIN_H: 13"
echo "USB_VCC5P0_L: 4.5"
echo "USB_VCC5P0_H: 5.5"

echo "P12V_ATX1_LM25066A_Vin_L: 11"
echo "P12V_ATX1_LM25066A_Vin_H: 13"
echo "P12V_ATX1_LM25066A_Iin_L: -1"
echo "P12V_ATX1_LM25066A_Iin_H: 25"
echo "P12V_ATX1_LM25066A_Pin_L: -1"
echo "P12V_ATX1_LM25066A_Pin_H: 300"
echo "P12V_ATX1_LM25066A_Vout_L: 11"
echo "P12V_ATX1_LM25066A_Vout_H: 13"
echo "p12v_ATX1_LM25066A_temp_L: 0"
echo "p12v_ATX1_LM25066A_temp_H: 90"
echo "P12V_ATX2_LM25066A_Vin_L: 11"
echo "P12V_ATX2_LM25066A_Vin_H: 13"
echo "P12V_ATX2_LM25066A_Iin_L: -1"
echo "P12V_ATX2_LM25066A_Iin_H: 25"
echo "P12V_ATX2_LM25066A_Pin_L: -1"
echo "P12V_ATX2_LM25066A_Pin_H: 300"
echo "P12V_ATX2_LM25066A_Vout_L: 11"
echo "P12V_ATX2_LM25066A_Vout_H: 13"
echo "p12v_ATX2_LM25066A_temp_L: 0"
echo "p12v_ATX2_LM25066A_temp_H: 90"
