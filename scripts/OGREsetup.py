#!/usr/bin/env python3


import argparse
import json
import pathlib
import sys

#https://stackoverflow.com/questions/60687577/trying-to-read-json-file-within-a-python-package
#https://docs.python.org/3/library/importlib.resources.html
import importlib.resources
with importlib.resources.files("opl").joinpath("OGREdefault.json").open('r',encoding="utf8") as file:
    dict0 = json.load(file)  


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
    #START240908
    #hp='Setup OGRE scripts. Required: OGREsetup.py <scanlist.csv>'
    #parser=argparse.ArgumentParser(description=hp,formatter_class=argparse.RawTextHelpFormatter)
    #parser.add_argument('dat0',metavar='<scanlist.csv(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be scanlist.csv files.')
    #hdat = 'Ex 1. '+parser.prog+' sub-1001_scanlist.csv sub-2000_scanlist.csv\n' \
    #     + 'Ex 2. '+parser.prog+' "sub-1001_scanlist.csv -s sub-2000_scanlist.csv"\n' \
    #     + 'Ex 3. '+parser.prog+' -s sub-1001_scanlist.csv sub-2000_scanlist.csv\n' \
    #     + 'Ex 4. '+parser.prog+' -s "sub-1001_scanlist.csv sub-2000_scanlist.csv"\n' \
    #     + 'Ex 5. '+parser.prog+' -s sub-1001_scanlist.csv -s sub-2000_scanlist.csv\n' \
    #     + 'Ex 6. '+parser.prog+' sub-1001_scanlist.csv -s sub-2000_scanlist.csv\n'
    #parser.add_argument('-s','--scanlist','-scanlist',dest='dat',metavar='scanlist.csv',action='extend',nargs='+',help=hdat)
    #
    #hOGREDIR='OGRE directory. Location of OGRE scripts.\n' \
    #    +'Optional if set at the top of this script or elsewhere via variable OGREDIR.\n' \
    #    +'The path provided by this option will be used instead of any other setting.\n'
    #parser.add_argument('-O','--OGREDIR','-OGREDIR','--ogredir','-ogredir',dest='OGREDIR',metavar='OGREdirectory',help=hOGREDIR)
    #
    #hjson = 'Your json file overwrites OGREdefault.json. Your options overwrite your json file.'
    #parser.add_argument('-j','--json','-json',dest='json',metavar='json',help=hjson)
    #
    #hcd0='Container directory\n' \
    #    +'    Ex. /Users/Shared/10_Connectivity/derivatives/preprocessed/sub-1019_OGRE-preproc\n' \
    #    +'        func, anat, regressors, pipeline7.4.1 are created inside this directory'
    #parser.add_argument('--container_directory','-container_directory','--cd','-cd',dest='cd0',metavar='mystr',help=hcd0)
    #
    #hfeat='Path to fsf files, text file which lists fsf files or directories with fsf files, one or more fsf files, or a combination thereof.\n' \
    #    +'An OGREfeat.sh call is created for each fsf.'
    #parser.add_argument('--feat','-feat','--fsf','-fsf','-o','-fsf1','--fsf1','-t','-fsf2','--fsf2',dest='feat',metavar='path, text file or *.fsf',action='extend',
    #    nargs='+',help=hfeat)

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
                #dict0 = json.load(f0)
        
                #if dict0['OGREstructpipeSETUP']:
                #    print(f"OGREstructpipeSETUP={dict0['OGREstructpipeSETUP']}")
                #if dict0['fakekey']:
                #    print(f"fakekey={dict0['fakekey']}")
        
                #if 'OGREstructpipeSETUP' in dict0:
                #    print(f"OGREstructpipeSETUP={dict0['OGREstructpipeSETUP']}")
                #if 'FWHM' in dict0:
                #    print(f"FWHM={dict0['FWHM']}")
        
                #dict1 = json.load(f0)
        
                #https://docs.python.org/3/library/stdtypes.html#dict.setdefault
                dict1 = dict0
                #print(f'{dict1}\n')
                dict1.update(json.load(f0))
                print(dict1)
        
                #print(dict0 == dict1)
                #print(dict0.values() == dict1.values())
        
        except FileNotFoundError:
            #print(f'    INFO: {i} does not exist.')
            print(f'    Error: {i} does not exist. Abort!')
            exit()


    #START240908
    #dict1 = dict0
    #if args.json:
    #    print(f'args.json={args.json}')
    #    try:
    #        with open(args.json,encoding="utf8",errors='ignore') as f0:
    #            dict1.update(json.load(f0))
    #    except FileNotFoundError:
    #        print(f'    Error: {args.json} does not exist. Abort!')
    #        exit()
    #print(dict1)

