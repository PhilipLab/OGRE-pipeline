#!/usr/bin/env python3


#https://realpython.com/python-import/
#https://www.geeksforgeeks.org/python-import-module-from-different-directory/
# python how to import module from another directory
# https://stackoverflow.com/questions/49039436/how-to-import-a-module-from-a-different-folder
#     https://stackoverflow.com/questions/14132789/relative-imports-for-the-billionth-time
# python3 how to import global variables
# https://stackoverflow.com/questions/15959534/visibility-of-global-variables-in-imported-modules

import argparse
import sys
import libpy


if __name__ == "__main__":

    parser=argparse.ArgumentParser(description=f'Create bids json files for nii. Required: scanlist2json.py <scanlist.csv>',formatter_class=argparse.RawTextHelpFormatter)

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
    #print(f'args.dat={args.dat}')


    """
    #START240605
    sys.path.insert(0,OGREDIR+'/lib')
    from ScansPar import Scans,Par #,run_cmd,SHEBANG

    for i in args.dat:

        #print(f'i={i}')
        #print(f'pathlib.Path(i).parent={pathlib.Path(i).parent}')
        #os.makedirs(pathlib.Path(i).parent, exist_ok=True)

        print(f'Reading {i}')
        scans = Scans(i)

        print(f'scans.fmap={scans.fmap}')
    """
