#!/usr/bin/env python3

import argparse
import json
import pandas as pd
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
    parser.add_argument('-s','--fmovalues','-fmovalues',dest='fmovalues',metavar='<fmovalues.txt>',help=hfmovalues)

    hfmospikes='Framewise motion outlier spikes. Multiple columns ok. Frame with spike=1. Frame without spike=0.'
    parser.add_argument('-o','--fmospikes','-fmospikes',dest='fmospikes',metavar='<fmospikes.txt>',help=hfmospikes)

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

    #print(f'jsonf = {jsonf}')

    try:
        with open(jsonf,'w',encoding="utf8",errors='ignore') as f0:
            dict0={}
            if args.fmovalues:
                df = pd.read_fwf(args.fmovalues) #don't set header=None because we want to ignore the first value which is always 0
                #print(f'df[df.keys()[0]].mean()={df[df.keys()[0]].mean()}')
                #print(f'df[df.keys()[0]].max()={df[df.keys()[0]].max()}')
                dict0['MeanMotion'] = df[df.keys()[0]].mean()
                dict0['MaxMotion'] = df[df.keys()[0]].max() 
        
            if args.fmospikes:
                df = pd.read_fwf(args.fmospikes,header=None)
                #print(f'df={df}')
                #The number of columns equals the number of InvalidScans, but we're going to play it safe and sum all the values in the dataframe.
                #print(f'df.to_numpy().sum()={df.to_numpy().sum()}')
                dict0['InvalidScans'] = df.to_numpy().sum()
                dict0['ValidScans'] = len(df.index) - dict0['InvalidScans']
                dict0['ProbValidScans'] = dict0['ValidScans'] / len(df.index)

            #print(f'dict0={dict0}')
            #print(f"dict0['InvalidScans']={dict0['InvalidScans']}")
            #https://stackoverflow.com/questions/50916422/python-typeerror-object-of-type-int64-is-not-json-serializable
            json.dump(dict0, f0, ensure_ascii=False, indent=4, default=int)
            

    except Exception as e:
        print(f'Error: Unable to write to {jsonf}: {e}')

    print(f'Output written to {jsonf}') 


