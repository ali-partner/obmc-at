#!/usr/bin/env python3
import argparse
import os
import sys
import json

###############################################################################
EXIT_SUCCESS = 0
EXIT_FAILED = -1
UPGRADE_REFRESH_RESULT_FILE="/var/log/fw/upgrade_refresh_result"

###############################################################################
def json_parser(file):
    """
    Get a json file and create a dictionary
    """
    with open(file) as fd:
        data = json.load(fd)
    return data

def json_parser_from_file(file, div=":"):
    """
    Get file and create a dictionary
    """
    data = {}
    with open(file) as fd:
        for line in fd.readlines():
            if div in line:
                line_list = line.split(div, 1)
                data[line_list[0].strip()] = line_list[1].strip()

    print(data)
    return data

###############################################################################


def get_cpld_last_upgrade_result():
    if not os.path.exists(UPGRADE_REFRESH_RESULT_FILE):
        return (-1, None)
    dict_ver = json_parser_from_file(UPGRADE_REFRESH_RESULT_FILE)
    if dict_ver == None:
        return (-1, dict_ver)
    return (0, dict_ver)

def arg_parser():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('--get', default='upgrade_result', type=str, help='Get upgrade result')

    return parser.parse_args()

if __name__ == "__main__":
    args = arg_parser()
    output = "ERR: parameter does wrong"
    ret = EXIT_FAILED

    if args.get:
        if args.get == "upgrade_result":
            ret, output = get_cpld_last_upgrade_result()
        else:
            output = "ERR:raw_object parameter illegal, cmd=%s" % argv
            ret = EXIT_FAILED

