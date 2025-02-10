#!/usr/bin/env python3

import argparse
import json
import pathlib
import sys

if __name__ == "__main__":

    hparser='Motion quality assurance. Metrics are written to JSON:\n' \
        +'        MeanMotion (mean framewise displacement from fmovalues.txt)\n' \
        +'        MaxMotion (maximum framewise displacement from fmovalues.txt)\n' \
        +'        InvalidScans (total # spikes)\n' \
        +'        ValidScans (total # volumes - InvalidScans)\n' \
        +'        ProbValidScans (ValidScans / total # volumes)\n'
    parser=argparse.ArgumentParser(description=hparser,formatter_class=argparse.RawTextHelpFormatter)

    hfmovalues='Framewise motion outlier values. Single column of framewise displacements.'
    parser.add_argument('--fmovalues','-fmovalues',dest='fmovalues',metavar='<fmovalues.txt>',help=hfmovalues)

    hfmospikes='Framewise motion outlier spikes. Multiple columns ok. Frame with spike=1. Frame without spike=0.'
    parser.add_argument('--fmospikes','-fmospikes',dest='fmospikes',metavar='<fmospikes.txt>',help=hfmospikes)

    #START230411 https://stackoverflow.com/questions/22368458/how-to-make-argparse-print-usage-when-no-option-is-given-to-the-code
    if len(sys.argv)==1:
        parser.print_help()
        # parser.print_usage() # for just the usage line
        parser.exit()
    args, unknown = parser.parse_known_args()
