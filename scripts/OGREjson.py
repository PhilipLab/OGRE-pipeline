#!/usr/bin/env python3

import argparse
import json
import pathlib
import sys

if __name__ == "__main__":

    parser=argparse.ArgumentParser(description=f'Create json files. Required: OGREjson.py -f <files needing jsons> -j <json template for each file>', \
        formatter_class=argparse.RawTextHelpFormatter)

    hf='Files needing jsons.'
    parser.add_argument('-f','--file','-file','--files','-file',dest='files',metavar='files needing jsons',action='extend',nargs='+',help=hf)

    hj='json templates. One for each file.'
    parser.add_argument('-j','--json','-json','--jsons','-jsons',dest='jsons',metavar='json templates',action='extend',nargs='+',help=hj)

    #START230411 https://stackoverflow.com/questions/22368458/how-to-make-argparse-print-usage-when-no-option-is-given-to-the-code
    if len(sys.argv)==1:
        parser.print_help()
        # parser.print_usage() # for just the usage line
        parser.exit()
    args, unknown = parser.parse_known_args()

    #print(f'args={args}')
    #print(f'{' '.join(sys.argv)}')          

    if not args.files:
        print(f'Need to specify files in need of jsons with -f') 
        exit()
    if not args.jsons:
        print(f'Need to specify json templates with -j') 
        exit()

    if len(args.files) != len(args.jsons):
        print(f'{len(args.files)} files but {len(args.jsons)} jsons. Must be equal. Abort!')
        exit()
    #print(f'len(args.files)={len(args.files)} len(args.jsons)={len(args.jsons)}')
    

    args.files = [str(pathlib.Path(i).resolve()) for i in args.files]
    args.jsons = [str(pathlib.Path(i).resolve()) for i in args.jsons]
    #print(f'args.files={args.files}')
    #print(f'args.jsons={args.jsons}')

    for i in range(len(args.files)):
        try:
            with open(args.jsons[i],encoding="utf8",errors='ignore') as f0:
                dict0 = json.load(f0)
        except FileNotFoundError:
            print(f'    INFO: {args.jsons[i]} does not exist. Skipping {args.files[i]} ...')
            continue

        jsonf = (f'{args.files[i].split('.nii')[0]}.json')
        #print(f'jsonf={jsonf}')

        try:
            with open(jsonf, 'w', encoding='utf-8') as f:
                json.dump(dict0, f, ensure_ascii=False, indent=4)

        except FileNotFoundError:
            print(f'    INFO: {args.jsons[i]} does not exist. Skipping {args.files[i]} ...')
            continue

        print(f'Output written to {jsonf}')
