#!/usr/bin/env python3


#https://realpython.com/python-import/
#https://www.geeksforgeeks.org/python-import-module-from-different-directory/
# python how to import module from another directory
# https://stackoverflow.com/questions/49039436/how-to-import-a-module-from-a-different-folder
#     https://stackoverflow.com/questions/14132789/relative-imports-for-the-billionth-time
# python3 how to import global variables
# https://stackoverflow.com/questions/15959534/visibility-of-global-variables-in-imported-modules

# python3 list of lists
# https://www.geeksforgeeks.org/python-list-of-lists/

import argparse
import json
import pathlib
import sys

import opl 


if __name__ == "__main__":

    hp=f'Create bids json files for nii. Required: scanlist2json.py <scanlist.csv>'
    parser=argparse.ArgumentParser(description=hp,formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('dat0',metavar='<scanlist.csv(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be scanlist.csv files.')
    hdat = 'Ex 1. '+parser.prog+' sub-1001_scanlist.csv sub-2000_scanlist.csv\n' \
         + 'Ex 2. '+parser.prog+' "sub-1001_scanlist.csv -s sub-2000_scanlist.csv"\n' \
         + 'Ex 3. '+parser.prog+' -s sub-1001_scanlist.csv sub-2000_scanlist.csv\n' \
         + 'Ex 4. '+parser.prog+' -s "sub-1001_scanlist.csv sub-2000_scanlist.csv"\n' \
         + 'Ex 5. '+parser.prog+' -s sub-1001_scanlist.csv -s sub-2000_scanlist.csv\n' \
         + 'Ex 6. '+parser.prog+' sub-1001_scanlist.csv -s sub-2000_scanlist.csv\n'
    parser.add_argument('-s','--scanlist','-scanlist',dest='dat',metavar='scanlist.csv',action='extend',nargs='+',help=hdat)

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

        #scans = opl.scans.Scans(i)
        #par = opl.scans.Par(len(scans.bold),int(len(scans.fmap)))
        #par = opl.scans.Par(len(scans.bold),int(len(scans.fmap)))
        #par.check_phase_dims(list(zip(*scans.bold))[0],list(zip(*scans.sbref))[0])
        #par.check_phase_dims_fmap(scans.fmap[0::2],scans.fmap[1::2])
        #fmap = scans.fmap #if dims don't match bold, fieldmap pairs maybe resampled and new files created
        #par.check_ped_dims(scans.bold,fmap)
        #START240706
        par = opl.scans.Par(i)
        par.check_phase_dims()
        par.check_phase_dims_fmap()
        par.check_ped_dims()
        par.check_ped_dims_dwi()

        #print(i)
      
        if par.fmap:

            if any(par.bfmap):
                if any(par.bbold_fmap):

                    print(f'par.fmap={par.fmap}')
                    print(f'len(par.fmap)={len(par.fmap)}')

                    for j in range(len(par.fmap)):

                        print(f'j={j}')

                        jsonf = (f'{par.fmap[j].split('.nii')[0]}.json')

                        try:
                            with open(jsonf,encoding="utf8",errors='ignore') as f0:
                                dict0 = json.load(f0)
                        except FileNotFoundError:
                            print(f'    INFO: {jsonf} does not exist. Creating dictionary ...')
                            dict0 = {'PhaseEncodingDirection':par.ped_fmap[j]}

                        val=[]
                        val += [(f'func{par.bold[par.fmap_bold[j][k]][0].split('/func')[1]}') for k in range(len(par.fmap_bold[j]))]

                        dict0['IntendedFor'] = val
                        with open(jsonf, 'w', encoding='utf-8') as f:
                            json.dump(dict0, f, ensure_ascii=False, indent=4)
                        print(f'Output written to {jsonf}')

            if any(par.bdwi_fmap):

                print(f'par.dwifmap={par.dwifmap}')

                for j in range(len(par.dwifmap)):
                    print(f'j={j}')
                    jsonf = (f'{par.dwifmap[j].split('.nii')[0]}.json')

                    try:
                        with open(jsonf,encoding="utf8",errors='ignore') as f0:
                            dict0 = json.load(f0)
                    except FileNotFoundError:
                        print(f'    INFO: {jsonf} does not exist. Creating dictionary ...')
                        dict0 = {'PhaseEncodingDirection':par.ped_dwifmap[j]}

                    val=[]
                    val += [(f'func{par.dwi[par.fmap_dwi[j][k]][0].split('/dwi')[1]}') for k in range(len(par.fmap_dwi[j]))]

                    dict0['IntendedFor'] = val
                    with open(jsonf, 'w', encoding='utf-8') as f:
                        json.dump(dict0, f, ensure_ascii=False, indent=4)
                    print(f'Output written to {jsonf}')
