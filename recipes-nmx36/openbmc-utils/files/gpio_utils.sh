#!/bin/bash
# Copyright 2015-present Facebook. All Rights Reserved.
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

GPIODIR="/sys/class/gpio"
GPIOEXPORT="$GPIODIR/export"
SHADOW_GPIO=/tmp/gpionames

#
# Set gpio pin with the given value.
# $1 - GPIO line num 834
#
gpio_line_dir() {
    echo "$GPIODIR/gpio$1"
}

#
# Set gpio pin with the given value.
# $1 - GPIO line num 834
# $2 - GPIO pin shadow name
#
gpio_line_export() {
    local gpio
    if [ $# -ne 2 ]; then
      echo "need 2 param: gpioxxx shadowname"
      exit 1
    fi
    gpio=$1
    dir=$(gpio_line_dir "$gpio")
    if [ ! -d "${dir}" ]; then
        echo "$gpio" > $GPIOEXPORT
    fi
    
    if [[ -d "${dir}" && "$#" -gt 1 ]]; then
        if [ ! -d  $SHADOW_GPIO ]; then
            mkdir -p $SHADOW_GPIO
        fi
        ln -s "$dir" $SHADOW_GPIO/"$2"
    fi
}


#
# Set gpio pin with the given value.
# $1 - GPIO pin shadow name 
# $2 - GPIO value   0/1
#
gpio_set_value() {
    local value=${2}

    if [ -L ${SHADOW_GPIO}/"$1" ]; then
       echo "${value}" > ${SHADOW_GPIO}/"$1"/value
    else
       echo "${SHADOW_GPIO}/$1  does't exist."
    fi	
	
}

#
# Get value of the given gpio pin.
# $1 - GPIO pin shadow name 
#
gpio_get_value() {

    if [ -L ${SHADOW_GPIO}/"$1" ]; then
       cat ${SHADOW_GPIO}/"$1"/value
    else
       echo "${SHADOW_GPIO}/$1  does't exist."
    fi
}


#
# Set the GPIO pin with given direction.
# $1 - GPIO pin shadow name 
# $2 - GPIO pin direction: "in" or "out"
#
gpio_set_direction() {
    local direction=${2}

    if [ -L ${SHADOW_GPIO}/"$1" ]; then
       echo "${direction}" > ${SHADOW_GPIO}/"$1"/direction
    else
       echo "${SHADOW_GPIO}/$1  does't exist."
    fi
}


#
# Get base pin number managed by the given gpio chip.
# $1 - GPIO pin shadow name.
#
gpiochip_get_direction() {

    if [ -L ${SHADOW_GPIO}/"$1" ]; then
        cat ${SHADOW_GPIO}/"$1"/direction
    else
       echo "${SHADOW_GPIO}/$1  does't exist."
    fi	
}
