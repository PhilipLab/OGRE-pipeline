#!/usr/bin/env python3

text='Convert *scanlist.csv to *.dat. Multiple *scanlist.csv for a single subject are ok. Each subject is demarcated by -s|--sub.'
#print(text)

import argparse
parser=argparse.ArgumentParser(description=text,formatter_class=argparse.RawTextHelpFormatter)

#START230410
#parser.add_argument('sub0',nargs='*',help='Input scanlist.csv(s) are assumed all to belong to the same subject.')
parser.add_argument('sub0',action='extend',nargs='*',help='Input scanlist.csv(s) are assumed all to belong to the same subject.')

parser.add_argument('-s','--sub',action='append',nargs='+',help='Input scanlist.csv(s). Each subject is written to its own file (eg 10_1002.dat and 10_2002.dat).\nEx. -s 10_1002_scanlist.csv -s 10_2002a_scanlist.csv 10_2002b_scanlist.csv')
parser.add_argument('-a','--all',help='Write all subjects to a single file. Individual files are still written.')
parser.add_argument('-o','--out',help='Write all subjects to a single file. Individual files are not written.')

#START230411 https://stackoverflow.com/questions/22368458/how-to-make-argparse-print-usage-when-no-option-is-given-to-the-code
import sys
if len(sys.argv)==1:
    parser.print_help()
    # parser.print_usage() # for just the usage line
    parser.exit()




args=parser.parse_args()

#print(f'args={args}')
#print(parser.parse_args([]))

#if args.sub:
#    print(f'-s --sub {args.sub}')
#    #if args.all: print(f'-a --all {args.all}')
#    print(f'args.all={args.all}')
#    if args.out: print(f'-o --out {args.out}')
#    print(f'args.out={args.out}')
#else:
#    exit()
#START230410
if args.sub:
    #print(f'-s --sub {args.sub}')
    #if args.all: print(f'-a --all {args.all}')
    #print(f'args.all={args.all}')
    if args.out: print(f'-o --out {args.out}')
    #print(f'args.out={args.out}')
    if args.sub0:
        args.sub.append(args.sub0)
    #print(f'-s --sub {args.sub}')
elif args.sub0:
    args.sub=[args.sub0]
    #print(f'-s --sub {args.sub}')
else:
    exit()

import re
import pathlib

import csv
#START230410
#import pandas

str0='#Scans can be labeled NONE or NOTUSEABLE. Lines beginning with a # are ignored.\n'
str1='#SUBNAME OUTDIR T1 T2 FM1 FM2 run1_LH_SBRef run1_LH run1_RH_SBRef run1_RH run2_LH_SBRef run2_LH run2_RH_SBRef run2_RH run3_LH_SBRef run3_LH run3_RH_SBRef run3_RH rest01_SBRef rest01 rest02_SBRef rest02 rest03_SBRef rest03\n'
str2='#----------------------------------------------------------------------------------------------------------------------------------------------\n'

if args.all or args.out:
    if args.all:
        str3=args.all
    elif args.out:
        str3=args.out
    f2=open(str3,mode='wt',encoding="utf8")
    f2.write(str0+str1+str2)


for i in args.sub:
    #print(f'i={i} len(i)={len(i)}') 

    d0={"SUBNAME":"NONE",
        "OUTDIR":"NONE",
        "t1_mpr_1mm_p2_pos50":"NONE",
        "t2_spc_sag_p2_iso_1.0":"NONE",
        "SpinEchoFieldMap2_AP":"NONE",
        "SpinEchoFieldMap2_PA":"NONE",
        "run1_LH_SBRef":"NONE",
        "run1_LH":"NONE",
        "run1_RH_SBRef":"NONE",
        "run1_RH":"NONE",
        "run2_LH_SBRef":"NONE",
        "run2_LH":"NONE",
        "run2_RH_SBRef":"NONE",
        "run2_RH":"NONE",
        "run3_LH_SBRef":"NONE",
        "run3_LH":"NONE",
        "run3_RH_SBRef":"NONE",
        "run3_RH":"NONE",
        "rest01_SBRef":"NONE",
        "rest01":"NONE",
        "rest02_SBRef":"NONE",
        "rest02":"NONE",
        "rest03_SBRef":"NONE",
        "rest03":"NONE"}

   
    n0=pathlib.Path(i[0]).stem
    #print(f'here0 n0={n0}')

    #m=re.match('([0-9_]+?)[a-zA-Z]_scanlist|([0-9_]+?)[a-zA-Z]',n0)
    m=re.match('([0-9_]+?)[a-zA-Z]_scanlist|([0-9_]+?)_scanlist|([0-9_]+?)[a-zA-Z]',n0)

    if m is not None: n0=m[m.lastindex]
    subname=n0
    ext='.dat'
    if pathlib.Path(i[0]).suffix=='.dat':ext+=ext
    n0=pathlib.Path(i[0]).with_name(n0+ext)
    #print(f'here1 n0={n0}')

    #p0=pathlib.Path(i[0]).parent
    #START230410
    p0=pathlib.Path(i[0]).resolve().parent
    #print(f'here2 p0={p0}')


    d0['SUBNAME']=subname
    d0['OUTDIR']=str(p0)+'/pipeline'

    for j in range(len(i)):

        #print(f'i[{j}]={i[j]}')

        with open(i[j],encoding="utf8",errors='ignore') as f1:

            csv1=csv.DictReader(f1)
            #START230410
            #csv1=pandas.read_csv(f1,sep=', ',engine='python')

            for row in csv1:
                #print(f'row={row}')
                if row['Scan'].casefold()=='none'.casefold():continue
                for k in d0:

                    #if k==row['nii']:
                    #START230411
                    if k==row['nii'].strip():

                        #print(f'k={k}')
                        d0[k]=str(p0)+'/nifti/'+k+'.nii.gz'
                        break


    if args.out is None:
        with open(n0,mode='wt',encoding="utf8") as f0:
            f0.write(str0+str1+str2)
            f0.write(' '.join(d0.values()))
            f0.write('\n')
        print(f'Output written to {n0}')

    if args.all or args.out:
        f2.write(' '.join(d0.values()))
        f2.write('\n')

if args.all or args.out:
    f2.close() 
    print(f'Output written to {str3}')
