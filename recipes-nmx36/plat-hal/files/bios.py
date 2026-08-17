#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import runpy
import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
if __name__ == '__main__':
    runpy.run_module('bios_org', run_name="__main__")
else:
    from plat_hal.bios_org import *
