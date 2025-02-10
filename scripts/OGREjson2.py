#!/usr/bin/env python3

import argparse
import json
import pathlib
import sys

if __name__ == "__main__":

    parser=argparse.ArgumentParser(description=f'Create json files. Required: OGREjson.py <files needing jsons> -j <JSON(s)>', \
        formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('dat0',metavar='<file(s) needing JSON(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be files needing JSONs.')
    hdat = 'Ex 1. '+parser.prog+' file1.nii.gz file2.nii.gz\n' \
         + 'Ex 2. '+parser.prog+' "file1.nii.gz -i file2.nii.gz"\n' \
         + 'Ex 3. '+parser.prog+' -i file1.nii.gz file2.nii.gz\n' \
         + 'Ex 4. '+parser.prog+' -i "file1.nii.gz file2.nii.gz"\n' \
         + 'Ex 5. '+parser.prog+' -i file1.nii.gz -i file2.nii.gz\n' \
         + 'Ex 6. '+parser.prog+' file1.nii.gz -i file2.nii.gz\n'
    parser.add_argument('-f','-i','--in','-in','--file','-file','--files','-files',dest='dat',metavar='<file needing JSON>',action='extend',nargs='+',help=hdat)

    hj='All JSONs are combined to a single JSON that is matched to each <file needing JSON>.'
    parser.add_argument('-j','--json','-json','--jsons','-jsons',dest='json',metavar='JSONs',action='extend',nargs='+',help=hj)

    #START230411 https://stackoverflow.com/questions/22368458/how-to-make-argparse-print-usage-when-no-option-is-given-to-the-code
    if len(sys.argv)==1:
        parser.print_help()
        # parser.print_usage() # for just the usage line
        parser.exit()
    args, unknown = parser.parse_known_args()

    if args.dat:
        if args.dat0:
            args.dat += args.dat0
    elif args.dat0:
        args.dat=args.dat0
    else:
        exit()
    args.dat = [str(pathlib.Path(i).resolve()) for i in args.dat]

    if not args.json:
        print(f'Need to specify JSONs with -j') 
        exit()
    args.json = [str(pathlib.Path(i).resolve()) for i in args.json]

    print(f'Running {parser.prog}')
    #print(f'args.json = {args.json}')
    #print(f'args.dat = {args.dat}')

    dict0={}
    for i in args.json:
        try:
            with open(i,encoding="utf8",errors='ignore') as f0:
                dict0.update(json.load(f0)) 
        except FileNotFoundError:
            print(f'    ERROR: {i} does not exist. Abort!')
            exit() 
    #print(f'dict0 = {dict0})')

    for i in args.dat:
        jsonf = (f'{i.split('.nii')[0]}.json')
        with open(jsonf, 'w', encoding='utf-8') as f0:
            json.dump(dict0, f0, ensure_ascii=False, indent=4)
        print(f'Output written to {jsonf}')
