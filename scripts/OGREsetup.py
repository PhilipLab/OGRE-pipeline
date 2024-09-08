#!/usr/bin/env python3


import argparse
import json
import pathlib
import sys

if __name__ == "__main__":

    hp=f'Setup OGRE scripts from a json.  Required: OGREsetup.py <json>'
    parser=argparse.ArgumentParser(description=hp,formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('dat0',metavar='<json(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be json files.')
    hdat = 'Ex 1. '+parser.prog+' sub-1001_OGRE.json sub-2000_OGRE.json\n' \
         + 'Ex 2. '+parser.prog+' "sub-1001_OGRE.json -j sub-2000_OGRE.json"\n' \
         + 'Ex 3. '+parser.prog+' -j sub-1001_OGRE.json sub-2000_OGRE.json\n' \
         + 'Ex 4. '+parser.prog+' -j "sub-1001_OGRE.json sub-2000_OGRE.json"\n' \
         + 'Ex 5. '+parser.prog+' -j sub-1001_OGRE.json -j sub-2000_OGRE.json\n' \
         + 'Ex 6. '+parser.prog+' sub-1001_OGRE.json -j sub-2000_OGRE.json\n'
    parser.add_argument('-j','--json','-json',dest='dat',metavar='json',action='extend',nargs='+',help=hdat)

    hverbose='Echo messages to terminal.'
    parser.add_argument('-v','--verbose','-verbose',dest='verbose',action='store_true',help=hverbose)

    #https://stackoverflow.com/questions/22368458/how-to-make-argparse-print-usage-when-no-option-is-given-to-the-code
    if len(sys.argv)==1:
        parser.print_help()
        # parser.print_usage() # for just the usage line
        parser.exit()
    args=parser.parse_args()
    if args.dat:
        if args.dat0:
            args.dat += args.dat0
    elif args.dat0:
        args.dat=args.dat0
    else:
        exit()
    args.dat = [str(pathlib.Path(i).resolve()) for i in args.dat]


    for i in args.dat:
        print(f'Reading {i}')
      
        try:
            with open(i,encoding="utf8",errors='ignore') as f0:
                dict0 = json.load(f0)

                #if dict0['OGREstructpipeSETUP']:
                #    print(f"OGREstructpipeSETUP={dict0['OGREstructpipeSETUP']}")
                #if dict0['fakekey']:
                #    print(f"fakekey={dict0['fakekey']}")

                if 'OGREstructpipeSETUP' in dict0:
                    print(f"OGREstructpipeSETUP={dict0['OGREstructpipeSETUP']}")
                if 'FWHM' in dict0:
                    print(f"FWHM={dict0['FWHM']}")



        except FileNotFoundError:
            print(f'    INFO: {i} does not exist.')
