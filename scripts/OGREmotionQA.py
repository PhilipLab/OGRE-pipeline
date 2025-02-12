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

    if args.fmovalues:
        #dval = str(pathlib.Path(args.fmovalues).resolve().parent) #+ '/'
        pval = pathlib.Path(args.fmovalues).resolve()
        #dval = pathlib.Path(args.fmovalues).resolve().parent
        #print(f'dval = {dval}')
        #jsonf = f'{args.fmovalues.split('fmo')[0]}fmoQA.json'
        jsonf = f'{str(pval).split('fmo')[0]}fmoQA.json'
    if args.fmospikes:
        #dspi = str(pathlib.Path(args.fmospikes).resolve().parent) #+ '/'
        #dspi = pathlib.Path(args.fmospikes).resolve().parent
        pspi = pathlib.Path(args.fmospikes).resolve()
        #print(f'dspi = {dspi}')
        #if 'dval' in locals():
        if 'pval' in locals():
            #if dval != dspi:
            if pval.parent != pspi.parent:
                #print(f'Error: fmovalues directory is {dval}\n       fmospikes directory is {dspi}\n       Must be the same. Abort!\n')
                print(f'Error: fmovalues directory is {pval.parent}\n       fmospikes directory is {pspi.parent}\n       Must be the same. Abort!\n')
                exit()
        #jsonf = f'{args.fmospikes.split('fmo')[0]}fmoQA.json'
        jsonf = f'{str(pspi).split('fmo')[0]}fmoQA.json'

    print(f'jsonf = {jsonf}')

    try:
        print(f'here0')
        with open(jsonf,'w',encoding="utf8",errors='ignore') as f0:

            if args.fmovalues:
                print(f'here1')
                try:
                    print(f'args.fmovalues = {args.fmovalues}')
                    with open(args.fmovalues,'r',encoding="utf8",errors='ignore') as f0:
                        pass
                except Exception as e:
                    print(f'Error: Unable to open {args.fmovalues}: {e}')
                    
        
        
            if args.fmospikes:
                pass

    except Exception as e:
        print(f'Error: Unable to write to {jsonf}: {e}')


