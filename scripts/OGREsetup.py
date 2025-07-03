#!/usr/bin/env python3

import argparse
import json
import pathlib
import shutil
import subprocess
import sys
import threading

#from opl.rou import run_cmd
#START241214
#from opl.rou import run_cmd,Envvars

#https://stackoverflow.com/questions/60687577/trying-to-read-json-file-within-a-python-package
#https://docs.python.org/3/library/importlib.resources.html
import importlib.resources
with importlib.resources.files("opl").joinpath("OGREdefault.json").open('r',encoding="utf8") as file:
    dict0 = json.load(file)

def run_script(cmd):
    subprocess.run(cmd,shell=True)
def run_thread(cmd):
    #print(f'Running: {cmd}')
    threading.Thread(target=run_script(cmd)).start()

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
        try:
            with open(i,encoding="utf8",errors='ignore') as f0:
                #https://docs.python.org/3/library/stdtypes.html#dict.setdefault
                dict1 = dict0
                print(f'Reading {i}')
                dict1.update(json.load(f0))
                #print(dict1)
                [print(j) for j in dict1.items()]
                print()
        except FileNotFoundError:
            print(f'    Error: {i} does not exist. Abort!')
            exit()

        if not dict1["ScanList"]: 
            print('{i} is missing ScanList. Abort!')
            exit()

        str_both = ' ' + dict1["ScanList"] 

        #START250604
        #if dict1["AutoRun"]: str_both+=' -A' 

        if dict1["OGREDIR"]: str_both+=' -O ' + dict1["OGREDIR"]
        if dict1["HCPDIR"]: str_both+=' -H ' + dict1["HCPDIR"] 
        if dict1["FreeSurferVersion"]: str_both+=' -V ' + dict1["FreeSurferVersion"] 
        if dict1["HostName"]: str_both+=' -m'
        if dict1["Date"]: str_both+=' -D'
        if dict1["DateLong"]: str_both+=' -DL'
        if dict1["BatchScript"]: 
            str_both+=' -b'                    
            if dict1["BatchScript"]!=True: str_both+=' ' +  dict1["BatchScript"]

        #if dict1["ContainerDirectory"]: str_both+=' -cd ' + dict1["ContainerDirectory"] 
        #START250613
        if dict1["Parent"]: str_both+=' -cd ' + dict1["Parent"] 

        if dict1["Name"]: str_both+=' -n ' + dict1["Name"] 

        str_stru=''
        if dict1["OGREstructpipeSETUP"]:
            if dict1["Erosion"]: str_stru+=' -e ' + dict1["Erosion"] 
            if dict1["Dilation"]: str_stru+=' -dil ' + dict1["Dilation"] 
            if dict1["HighResolutionTemplateDirectory"]: str_stru+=' -ht ' + dict1["HighResolutionTemplateDirectory"] 
            if dict1["LowResolutionTemplateDirectory"]: str_stru+=' -lt ' + dict1["LowResolutionTemplateDirectory"] 
            if dict1["Resolution"]: str_stru+=' -r ' + dict1["Resolution"]
            if dict1["T1HighResolutionWholeHead"]: str_stru+=' -t1 ' + dict1["T1HighResolutionWholeHead"] 
            if dict1["T1HighResolutionBrainOnly"]: str_stru+=' -t1b ' + dict1["T1HighResolutionBrainOnly"] 
            if dict1["T1HighResolutionBrainMask"]: str_stru+=' -t1bm ' + dict1["T1HighResolutionBrainMask"] 
            if dict1["T1LowResolutionWholeHead"]: str_stru+=' -t1l ' + dict1["T1LowResolutionWholeHead"] 
            if dict1["T1LowResolutionBrainOnly"]: str_stru+=' -t1bl ' + dict1["T1LowResolutionBrainOnly"] 
            if dict1["T1LowResolutionBrainMask"]: str_stru+=' -t1bml ' + dict1["T1LowResolutionBrainMask"] 
            if dict1["T2HighResolutionWholeHead"]: str_stru+=' -t2 ' + dict1["T2HighResolutionWholeHead"] 
            if dict1["T2HighResolutionBrainOnly"]: str_stru+=' -t2b ' + dict1["T2HighResolutionBrainOnly"] 
            if dict1["T2HighResolutionBrainMask"]: str_stru+=' -t2bm ' + dict1["T2HighResolutionBrainMask"] 
            if dict1["T2LowResolutionWholeHead"]: str_stru+=' -t2l ' + dict1["T2LowResolutionWholeHead"] 

            #START250604
            if dict1["AutoRun"] and not dict1["OGREfMRIpipeSETUP"]: str_stru+=' -A' 


        str_func=''
        if dict1["OGREfMRIpipeSETUP"]:
            if dict1["FWHM"]: str_func+=' -f ' + str(dict1["FWHM"])
            if dict1["HPFcutoff_sec"]: str_func+=' -hpf_sec ' + str(dict1["HPFcutoff_sec"])
            if dict1["LPFcutoff_sec"]: str_func+=' -lpf_sec ' + str(dict1["LPFcutoff_sec"])
            if dict1["HPFcutoff_Hz"]: str_func+=' -hpf_Hz ' + str(dict1["HPFcutoff_Hz"])
            if dict1["LPFcutoff_Hz"]: str_func+=' -lpf_Hz ' + str(dict1["LPFcutoff_Hz"])
            if dict1["SmoothOnly"]: str_func+=' -smoothonly'
            if dict1["donotsmoothrest"]: str_func+=' -donotsmoothrest'
            if dict1["donotuseIntendedFor"]: str_func+=' -donotuseIntendedFor'
            if dict1["Feat"]: str_func+=' -feat ' + dict1["Feat"]
            if dict1["FeatAdapter"]: str_func+=' -F'
            if dict1["UseRefinement"]: str_func+=' -userefinement'

            #if dict1["FSLMotionOutliers"]: str_func+=' -fslmo ' + dict1["FSLMotionOutliers"]  
            #START250623
            if dict1["fsl_motion_outliers"]: str_func+=' -fslmo ' + dict1["fsl_motion_outliers"]  

            if dict1["StartIntensityNormalization"]: str_func+=' -sin' 

            #START250604
            if dict1["AutoRun"]: str_func+=' -A' 

        if dict1["OGREstructpipeSETUP"]:
            cmd = f'{dict1["OGREDIR"]}/scripts/OGREstructpipeSETUP.sh{str_both}{str_stru}'
            run_thread(cmd)

        if dict1["OGREfMRIpipeSETUP"]:
            if dict1["OGREstructpipeSETUP"]: print()
            cmd = f'{dict1["OGREDIR"]}/scripts/OGREfMRIpipeSETUP.py{str_both}{str_func}'
            run_thread(cmd)

        #START241214
        #KEEP
        #if dict1["ContainerDirectory"]:
        #    #use the shell to evaluate the directory name in case it includes $(date +%y%m%d)
        #    cd0 = dict1["ContainerDirectory"]
        #    cd1 = run_cmd(f'echo "{cd0}"')
        #    print(f'container directory = {cd1}')
        #    d0 = str(pathlib.Path(cd1).resolve())
        #    print(f'd0 = {d0}')
        #
        #    gev = Envvars()
        #    if dict1["FreeSurferVersion"]: gev.FREESURFVER =  dict1["FreeSurferVersion"]
        #    dir0 = d0 + '/pipeline' + gev.FREESURFVER
        #
        #    dest = shutil.copy2(i,f'{dir0}/scripts/{pathlib.Path(i).name}')
        #    print(f'JSON copied to {dest}')
        #START241214
        tmp='.OGREtmp'
        try:
            with open(tmp,encoding="utf8",errors='ignore') as f0:
                cd0 = f0.read().strip()
            pathlib.Path.unlink(tmp)
        except FileNotFoundError:
            print(f'    Error: {tmp} does not exist. Abort!')
            exit()
        dest = shutil.copy2(i,f'{cd0}/scripts/{pathlib.Path(i).name}')
        print(f'JSON copied to {dest}')

