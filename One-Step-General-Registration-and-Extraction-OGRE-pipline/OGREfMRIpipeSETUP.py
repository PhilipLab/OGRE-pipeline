#!/usr/bin/env python3

#https://docs.python.org/3/tutorial/classes.html
#https://www.digitalocean.com/community/tutorials/how-to-construct-classes-and-define-objects-in-python-3
#https://www.sanfoundry.com/python-program-form-dictionary-object-class/
#https://www.geeksforgeeks.org/python-initialize-a-dictionary-with-only-keys-from-a-list/
#https://stackoverflow.com/questions/209840/make-a-dictionary-dict-from-separate-lists-of-keys-and-values
#https://www.geeksforgeeks.org/how-to-change-a-dictionary-into-a-class/
#https://pynative.com/python-class-variables/
#https://docs.python.org/3/howto/argparse.html
#https://stackoverflow.com/questions/31127366/single-dash-for-argparse-long-options
#https://stackoverflow.com/questions/42818876/python-3-argparse-call-function
#https://ioflood.com/blog/python-get-environment-variable/#:~:text=To%20get%20an%20environment%20variable,with%20your%20system's%20environment%20variables.
#python3 equivalent to grep on a file
#https://docs.python.org/3/library/os.html
#https://docs.python.org/3/c-api/datetime.html
#https://blog.devgenius.io/the-weird-side-effects-of-modifying-python-variables-inside-a-function-ba1e5ca65192
#https://stackoverflow.com/questions/986006/how-do-i-pass-a-variable-by-reference
#https://docs.python.org/3/library/json.html

import os
import subprocess
import pathlib
from datetime import datetime
import json
import re
import glob

#**** default global variables **** 

SHEBANG = "#!/usr/bin/env bash"

P0='OGREGenericfMRIVolumeProcessingPipelineBatch.sh' 
P1='OGRET1w_restore.sh'
P2='OGRESmoothingProcess.sh'
P3='OGREmakeregdir.sh'
SETUP='OGRESetUpHCPPipeline.sh'

#**** These are overwritten by their environment variables in get_env_vars ****
WBDIR='/Users/Shared/pipeline/HCP/workbench-mac/bin_macosx64'
HCPDIR='/Users/Shared/pipeline/HCP'
FSLDIR='/usr/local/fsl'
FREESURFDIR='/Applications/freesurfer'
FREESURFVER='7.4.0'

#**** These overwrite the default global variables and are overwritten in options ****
def get_env_vars():
    try:
        global OGREDIR
        OGREDIR = os.environ['OGREDIR'] 
    except KeyError:
        pass 
    try:
        global WBDIR
        WBDIR = os.environ['WBDIR'] 
    except KeyError:
        pass 
    try:
        global HCPDIR
        HCPDIR = os.environ['HCPDIR'] 
    except KeyError:
        pass 
    try:
        global FSLDIR
        FSLDIR = os.environ['FSLDIR'] 
    except KeyError:
        pass 
    try:
        global FREESURFDIR
        FREESURFDIR = os.environ['FREESURFDIR'] 
    except KeyError:
        pass 
    try:
        global FREESURFVER
        FREESURFVER = os.environ['FREESURFVER'] 
    except KeyError:
        pass 


class Scans:
    def __init__(self,file):
        self.fmap = []
        self.sbref = []
        self.bold = [] 
        self.taskidx = []
        self.restidx = []

        with open(file,encoding="utf8",errors='ignore') as f0:
            i,j = 0,0
            for line0 in f0:
                i+=1
                if not line0.strip() or line0.startswith('#'): continue
                #https://stackoverflow.com/questions/44785374/python-re-split-string-by-commas-and-space
                line1 = re.findall(r'[^,\s]+', line0)
                #print(line1[1])
                file0 = line1[1] + '.nii.gz'
                if not os.path.isfile(file0):
                    print(f'Error: {file0} does not exist. Please place a # at the beginning of line {i}')
                    exit()

                line2=file0.split('/')
                if line2[-2] == 'fmap':
                    if line2[-1].find('dbsi') == -1:
                        self.fmap.append(file0)
                elif line2[-2] == 'func':
                    if line2[-1].find('sbref') != -1:
                        self.sbref.append((file0,int(len(self.fmap)/2-1)))
                    else:
                        self.bold.append((file0,int(len(self.fmap)/2-1)))
                        if line2[-1].find('task-rest') != -1:
                            self.restidx.append(j)
                        else:
                            self.taskidx.append(j)
                        j+=1

        if len(self.sbref) != len(self.bold):
            print(f'There are {len(self.sbref)} reference files and {len(self.bold)} bolds. Must be equal. Abort!')
            exit()
        #print(f'self.fmap={self.fmap}')
        #print(f'self.sbref={self.sbref}')
        #print(f'self.bold={self.bold}')
        #print(f'self.taskidx={self.taskidx}')
        #print(f'self.restidx={self.restidx}')

#        bSBRef,ped,dim = check_phase_dims(list(zip(*bold2))[0],list(zip(*SBRef2))[0])
#        bfmap,ped_fmap,dim_fmap = check_phase_dims_fmap(fmap[0::2],fmap[1::2])
#        bbold_fmap = check_ped_dims(bold2,ped,dim,bfmap,ped_fmap,dim_fmap,fmap[0::2])
class Par:
    def __init__(self,lenbold,lenfmap0):
        self.bsbref = [False]*lenbold
        self.ped = []
        self.dim = []
        self.bfmap = [False]*int(lenfmap0/2)
        self.ped_fmap = []
        self.dim_fmap = []
        self.bbold_fmap = []

        #START240207 
        self.fmapnegidx = [0]*int(lenfmap0/2)  #j- 0 or 1, for pos subtract 1 and take abs
        self.fmapposidx = [1]*int(lenfmap0/2)  #j+ 0 or 1, for pos subtract 1 and take abs

    def check_phase_dims(self,bold,sbref):
        for j in range(len(bold)):
            self.ped.append(get_phase(bold[j]))
            ped0 = get_phase(sbref[j])

            if ped0 != self.ped[j]:
                print(f'    ERROR: {bold[j]} {self.ped[j]}')
                print(f'    ERROR: {sbref[j]} {ped0}')
                print(f'           Phases should be the same. Will not use this SBRef.')
                continue

            self.dim.append(get_dim(bold[j]))
            dim0 = get_dim(sbref[j])
    
            if dim0 != self.dim[j]:
                print(f'    ERROR: {bold[j]} {self.dim[j]}')
                print(f'    ERROR: {sbref[j]} {dim0}')
                print(f'           Dimensions should be the same. Will not use this SBRef.')
                continue

            self.bsbref[j]=True

        #print(f'bsbref={self.bsbref}')
        #print(f'ped={self.ped}')
        #print(f'dim={self.dim}')

    def check_phase_dims_fmap(self,fmap0,fmap1):
        for j in range(len(fmap0)):
            self.ped_fmap.append(get_phase(fmap0[j]))
            ped0 = get_phase(fmap1[j])

            #print(f'ped0[0]={ped0[0]}')

            if ped0[0] != self.ped_fmap[j][0]:
                print(f'    ERROR: {fmap0[j]} {self.ped_fmap[j][0]}')
                print(f'    ERROR: {fmap1[j]} {ped0[0]}')
                print(f'           Fieldmap encoding direction must be the same!')
                continue
            if ped0 == self.ped_fmap[j]:
                print(f'    ERROR: {fmap0[j]} {self.ped_fmap[j]}')
                print(f'    ERROR: {fmap1[j]} {ped0}')
                print(f'           Fieldmap phases must be opposite!')
                continue

            self.dim_fmap.append(get_dim(fmap0[j]))
            dim0 = get_dim(fmap1[j])

            if dim0 != self.dim_fmap[j]:
                print(f'    ERROR: {fmap0[j]} {self.dim_fmap[j]}')
                print(f'    ERROR: {fmap1[j]} {dim0}')
                print(f'           Dimensions must be the same. Will not use these fieldmaps.')
                continue

            self.bfmap[j]=True
            if self.ped_fmap[j][1] == '+': 
                self.fmapnegidx[j]=1
                self.fmapposidx[j]=0

        #print(f'bfmap={self.bfmap}')
        #print(f'ped_fmap={self.ped_fmap}')
        #print(f'dim_fmap={self.dim_fmap}')

    def check_ped_dims(self,bold,fmap):
        self.bbold_fmap=[False]*len(self.ped)
        if any(self.bfmap):
            for j in range(len(self.ped)):
                if self.bfmap[bold[j][1]]:
                    if self.ped[j][0] != self.ped_fmap[bold[j][1]][0]:
                        print(f'    ERROR: {bold[j][0]} {self.ped[j][0]}')
                        print(f'    ERROR: {fmap[bold[j][1]*2]} {self.ped_fmap[bold[j][1]][0]}')
                        print(f"           Fieldmap encoding direction must be the same! Fieldmap won't be applied.")
                        continue
                    if self.dim[j] != self.dim_fmap[bold[j][1]]:
                        print(f'    ERROR: {bold[j][0]} {self.dim[j]}')
                        print(f'    ERROR: {fmap[bold[j][1]*2]} {self.dim_fmap[bold[j][1]]}')
                        print(f"           Dimensions must be the same. Fieldmap won't be applied unless it is resampled.")
                        ynq = input('    Would like to resample the field maps? y, n, q').casefold()
                        if ynq=='q' or ynq=='quit' or ynq=='exit': exit()
                        if ynq=='n' or ynq=='no': continue
                        for i in bold[j][1]*2,bold[j][1]*2+1:
                            fmap0 = pathlib.Path(fmap[i]).stem + '_resampled' + 'x'.join(self.dim[j]) + '.nii.gz'
                            junk = run_cmd(f'{WBDIR}/wb_command -volume-resample {fmap[i]} {bold[j][0]} CUBIC {fmap0}')
                            self.dim_fmap[bold[j][1]] = self.dim[j]
                            fmap[j] = fmap0
                    self.bbold_fmap[j]=True
        #print(f'bbold_fmap={self.bbold_fmap}')




def run_cmd(cmd):
    return subprocess.run(cmd, capture_output=True, shell=True).stdout.decode().strip()

def get_phase(file):
    jsonf = file.split('.')[0] + '.json'
    if not os.path.isfile(jsonf):
        print(f'    ERROR: {jsonf} does not exist. Abort!')
        #return 'ERROR'
        exit()
    #print(f'get_phase jsonf={jsonf}')

    with open(jsonf,encoding="utf8",errors='ignore') as f0:
        dict0 = json.load(f0)

    #print(f"get_phase {dict0['PhaseEncodingDirection']}")

    return dict0['PhaseEncodingDirection']

def get_dim(file):
    line0 = run_cmd(f'fslinfo {file} | grep -w dim[1-3]')
    line1=line0.split()
    return (line1[1],line1[3],line1[5])

def get_TR(file):
    jsonf = file.split('.')[0] + '.json'
    if not os.path.isfile(jsonf):
        print(f'    ERROR: {jsonf} does not exist. Abort!')
        #return 'ERROR'
        exit()

    with open(jsonf,encoding="utf8",errors='ignore') as f0:
        dict0 = json.load(f0)

    return dict0['RepetitionTime']

class Feat:
    def __init__(self,arg):
        self.outputdir = []
        self.fsf = []
        for i in arg:
            #print(f'i={i}')
            for j in i:
                #print(f'j={j}')
                if j[-4:]=='feat':
                    #if os.path.isdir(j):
                    if pathlib.Path(j).exists():
                        fsf0 = glob.glob(f'{j}/*.fsf')
                        if fsf0:
                            if len(fsf0)==1:
                                line0 = run_cmd(f'grep "set fmri(outputdir)" {fsf0[0]}')
                                self.outputdir.append(line0.split('"')[1])
                                self.fsf.append(fsf0)
                elif j[-3:]=='fsf':
                    line0 = run_cmd(f'grep "set fmri(outputdir)" {j}')
                    self.outputdir.append(line0.split('"')[1])
                    self.fsf.append(fsf0)
                else:
                    with open(j,encoding="utf8",errors='ignore') as f0:
                        for line0 in f0:
                            line1=line0.strip()
                            #print(f'line1={line1}')
                            if not line1 or line1.startswith('#'): continue
                            if line1[-4:]=='feat':
                                #if os.path.isdir(line0):
                                if pathlib.Path(line1).exists():
                                    fsf0 = glob.glob(f'{line1}/*.fsf')
                                    if fsf0:
                                        if len(fsf0)==1:
                                            line0 = run_cmd(f'grep "set fmri(outputdir)" {fsf0[0]}')
                                            self.outputdir.append(line0.split('"')[1])
                                            self.fsf.append(fsf0)
                            elif line1[-3:]=='fsf':
                                line0 = run_cmd(f'grep "set fmri(outputdir)" {line1}')
                                self.outputdir.append(line0.split('"')[1])
                                self.fsf.append(line1)
        #print(f'self.outputdir={self.outputdir}')
        #print(f'self.fsf={self.fsf}')



if __name__ == "__main__":
    get_env_vars()

    import argparse
    parser=argparse.ArgumentParser(description=f'Create OGRE fMRI pipeline script. Required: OGREfMRIpipeSETUP.py <scanlist.csv>',formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('dat0',metavar='<scanlist.csv(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be scanlist.csv files.')
    hdat = 'Ex 1. '+parser.prog+' sub-1001_scanlist.csv sub-2000_scanlist.csv\n' \
         + 'Ex 2. '+parser.prog+' "sub-1001_scanlist.csv -d sub-2000_scanlist.csv"\n' \
         + 'Ex 3. '+parser.prog+' -s sub-1001_scanlist.csv sub-2000_scanlist.csv\n' \
         + 'Ex 4. '+parser.prog+' -s "sub-1001_scanlist.csv sub-2000_scanlist.csv"\n' \
         + 'Ex 5. '+parser.prog+' -s sub-1001_scanlist.csv -d sub-2000_scanlist.csv\n' \
         + 'Ex 6. '+parser.prog+' sub-1001_scanlist.csv -d sub-2000_scanlist.csv\n'
    parser.add_argument('-s','--scanlist','-scanlist',dest='dat',metavar='scanlist.csv',action='append',nargs='+',help=hdat)

    hlcautorun='Flag. Automatically execute *_fileout.sh script. Default is to not execute.'
    parser.add_argument('-A','--autorun','-autorun','--AUTORUN','-AUTORUN',dest='lcautorun',action='store_true',help=hlcautorun)

    hbs='*_fileout.sh scripts are collected in the executable batchscript.'
    parser.add_argument('-b','--batchscript','-batchscript',dest='bs',metavar='batchscript',help=hbs)
    #sbs = ['-b','--batchscript','-batchscript']
    #parser.add_argument(sbs,dest='bs',metavar='batchscript',help=hbs)

    hOGREDIR='OGRE directory. Location of OGRE scripts.\n' \
        +'Optional if set at the top of this script or elsewhere via variable OGREDIR.\n' \
        +'The path provided by this option will be used instead of any other setting.\n'
    parser.add_argument('-O','--OGREDIR','-OGREDIR','--ogredir','-ogredir',dest='OGREDIR',metavar='OGREdirectory',help=hOGREDIR)

    hHCPDIR='HCP directory. Optional if set at the top of this script or elsewhere via variable HCPDIR.'
    parser.add_argument('-H','--HCPDIR','-HCPDIR','--hcpdir','-hcpdir',dest='HCPDIR',metavar='HCPdirectory',help=hHCPDIR)

    hFREESURFVER='5.3.0-HCP, 7.2.0, 7.3.2, or 7.4.0. Default is 7.4.0 unless set elsewhere via variable FREESURFVER.'
    parser.add_argument('-V','--VERSION','-VERSION','--FREESURFVER','-FREESURFVER','--freesurferVersion','-freesurferVersion',dest='FREESURFVER',metavar='FreeSurferVersion', \
        help=hFREESURFVER,choices=['5.3.0-HCP', '7.2.0', '7.3.2', '7.4.0'])

    hbhostname='Flag. Append machine name to pipeline directory. Ex. pipeline7.4.0_3452-AD-05003'
    parser.add_argument('-m','--HOSTNAME',dest='bhostname',action='store_true',help=hbhostname)

    hlcdate='Flag. Add date (YYMMDD) to name of output script.'
    parser.add_argument('-D','--DATE','-DATE','--date','-date',dest='lcdate',action='store_const',const=1,help=hlcdate,default=0)

    hlcdateL='Flag. Add date (YYMMDDHHMMSS) to name of output script.'
    parser.add_argument('-DL','--DL','--DATELONG','-DATELONG','--datelong','-datelong',dest='lcdate',action='store_const',const=2,help=hlcdateL,default=0)

    hfwhm='Smoothing (mm) for SUSAN. Multiple values ok.'
    mfwhm='FWHM'
    #parser.add_argument('-f','--fwhm',dest='fwhm',metavar=mfwhm,action='append',nargs='+',help=hfwhm,type=int)
    parser.add_argument('-f','--fwhm',dest='fwhm',metavar=mfwhm,action='append',nargs='+',help=hfwhm)

    hparadigm_hp_sec='High pass filter cutoff in seconds'
    mparadigm_hp_sec='HPFcutoff'
    #parser.add_argument('-p','--paradigm_hp_sec',dest='paradigm_hp_sec',metavar=mparadigm_hp_sec,help=hparadigm_hp_sec,type=float)
    parser.add_argument('-p','--paradigm_hp_sec',dest='paradigm_hp_sec',metavar=mparadigm_hp_sec,help=hparadigm_hp_sec)

    hlct1copymaskonly='Flag. Only copy the T1w_restore.2 and mask to create T1w_restore_brain.2'
    parser.add_argument('-T','--T1COPYMASKONLY',dest='lct1copymaskonly',action='store_true',help=hlct1copymaskonly)

    hlcsmoothonly='Flag. Only do SUSAN smoothing and high pass filtering.'
    parser.add_argument('--smoothonly','-smoothonly','--SMOOTHONLY','-SMOOTHONLY',dest='lcsmoothonly',action='store_true',help=hlcsmoothonly)

    hfsf1='fsf files for first-level FEAT analysis. An OGREmakeregdir call is created for each fsf.'
    parser.add_argument('-o','-fsf1','--fsf1',dest='fsf1',metavar='*.fsf',action='append',nargs='+',help=hfsf1)

    hfsf2='fsf files for second-level FEAT analysis. An OGREmakeregdir call is created for each fsf.'
    parser.add_argument('-t','-fsf2','--fsf2',dest='fsf2',metavar='*.fsf',action='append',nargs='+',help=hfsf2)

    hlcfeatadapter='Flag. Only write the feat adapter scripts.'
    parser.add_argument('-F','--FEATADAPTER','-FEATADAPTER','--featadapter','-featadapter',dest='lcfeatadapter',action='store_true',help=hlcfeatadapter)


    #START230411 https://stackoverflow.com/questions/22368458/how-to-make-argparse-print-usage-when-no-option-is-given-to-the-code
    import sys
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
    args.dat = [os.path.abspath(i) for i in args.dat]

    if args.OGREDIR: OGREDIR = args.OGREDIR
    if not 'OGREDIR' in locals():
        print('OGREDIR not set. Abort!\nBefore calling this script: export OGREDIR=<OGRE directory>\nor via an option to this script: -OGREDIR <OGRE directory>\n')
        exit()

    if not args.lcfeatadapter: 
        if not args.fwhm: 
            print(f'{mfwhm} has not been specified. SUSAN noise reduction will not be performed.') 
        else:
            args.fwhm = sum(args.fwhm,[])
        if not args.paradigm_hp_sec: print(f'{mparadigm_hp_sec} has not been specified. High pass filtering will not be performed.') 

    if args.HCPDIR: HCPDIR = args.HCPDIR 
    if args.FREESURFVER: FREESURFVER = args.FREESURFVER

    #print(f'HCPDIR={HCPDIR}')
    #print(f'FREESURFVER={FREESURFVER}')

    #if args.fsf1: outputdir1 = get_feat(args.fsf1)
    #if args.fsf2: outputdir2 = get_feat(args.fsf2)
    if args.fsf1: feat1 = Feat(args.fsf1)
    if args.fsf2: feat2 = Feat(args.fsf2)

    """
    if not args.bs:
        num_sub = 0
        for i in args.dat:
            for j in range(len(i)):
                with open(i[j],encoding="utf8",errors='ignore') as f0:
                    num_sub0 = 0 #dat could be empty or just have a line of keys
                    for line0 in f0:
                        if not line0.strip() or line0.startswith('#'): continue
                        num_sub0 += 1
                    if num_sub0 > 0 : num_sub += num_sub0 - 1 #first line is the keys
        num_cores = int(run_cmd('sysctl -n hw.ncpu'))
        print(f'num_cores = {num_cores}')
        if num_sub > num_cores:
            hostname = run_cmd('hostname')
            print(f'{num_sub} will be run, however {hostname} only has {num_cores}. Please consider using a batchscript -b.')
    else:
        if "/" in args.bs: os.makedirs(pathlib.Path(args.bs).resolve().parent, exist_ok=True)
        bs=open(args.bs,mode='wt',encoding="utf8")
        bs.write(f'{SHEBANG}\n')
    """

    datestr = ''
    if args.lcdate > 0:
        if args.lcdate == 1:
            date0 = datetime.today().strftime("%y%m%d")
        elif args.lcdate == 2:
            date0 = datetime.today().strftime("%y%m%d%H%M%S")
        #print(f'date0 = {date0}')
        datestr = '_' + date0


    if not args.lcfeatadapter: 
        if not args.lcsmoothonly: 
            #l0 = 'hcp3.27fMRIvol' 
            l0 = 'OGREfMRIvol' 
        else: 
            l0 = 'smooth'
    else:
        l0 = 'FEATADAPTER'

    for i in args.dat:

        scans = Scans(i)
        idx = i.find('sub-')
        if idx != -1:
            s0 = i[idx: idx + i[idx:].find('/')]
            #print(f's0={s0}')
            print(f'{s0}')
        

        idx = i.find('raw_data')
        if idx == -1:
            pass
        else:
            #print(i[:idx])
            dir0 = i[:idx] + 'derivatives/preprocessed/' + s0 + '/pipeline' + FREESURFVER
            dir1 = i[:idx] + 'derivatives/preprocessed/${s0}/pipeline${FREESURFVER}'
            #print(f'dir0={dir0}\ndir1={dir1}')

            #START240217
            dir2 = i[:idx] + 'derivatives/preprocessed/${s0}'

        if args.bhostname:
            hostname = run_cmd('hostname')
            dir0 += '_' + hostname 
            dir1 += '_$(hostname)' 

        stem0 = dir0 + '/' + s0

        str0 = stem0 + '_' + l0 + datestr
        F0 = [str0 + '.sh']
        F1 = str0 + '_fileout.sh'
        if not args.lcfeatadapter and args.fsf1: 
            F0.append(stem0 + '_FEATADAPTER' + datestr + '.sh')


        #START240217
        F2 = stem0 + '_copy' + datestr + '.sh' 


        if args.bs:
            #str0 = stem0 + '_hcp3.27batch' + datestr
            str0 = stem0 + '_OGREbatch' + datestr
            bs0 = str0 + '.sh'
            if not os.path.isfile(bs0):
                mode0 = 'wt'
            else:
                mode0 = 'at'
            bsf0 = open(bs0,mode=mode0,encoding="utf8")
            if not os.path.isfile(bs0): bsf0.write(f'{SHEBANG}\n')
            bs1 = str0 + '_fileout.sh'
            bsf1 = open(bs1,mode='wt',encoding="utf8") #ok to crush, because nothing new is written
            bsf1.write(f'{SHEBANG}\nset -e\n')

        if not args.lcfeatadapter:
            par = Par(len(scans.bold),int(len(scans.fmap)))
            par.check_phase_dims(list(zip(*scans.bold))[0],list(zip(*scans.sbref))[0])
            if not args.lcsmoothonly and not args.lct1copymaskonly: 
                par.check_phase_dims_fmap(scans.fmap[0::2],scans.fmap[1::2])
                fmap = scans.fmap #if dims don't match bold, fieldmap pairs maybe resampled and new files created
                par.check_ped_dims(scans.bold,fmap)


        from contextlib import ExitStack
        with ExitStack() as fs:
            F0f = [fs.enter_context(open(fn, "w")) for fn in F0]
            F1f = fs.enter_context(open(F1, "w"))

            #START240217
            F2f = fs.enter_context(open(F2, "w"))

            for fn in F0f: fn.write(f'{SHEBANG}\nset -e\n\n#{' '.join(sys.argv)}\n\n')          
            F1f.write(f'{SHEBANG}\nset -e\n\n')          

            #START240217
            F2f.write(f'{SHEBANG}\nset -e\n\n')          

            if not args.lcfeatadapter:
                F0f[0].write(f'FREESURFDIR={FREESURFDIR}\nFREESURFVER={FREESURFVER}\nexport FREESURFER_HOME='+'${FREESURFDIR}/${FREESURFVER}\n\n')

            if args.fsf1 or args.fsf2:
                for fn in F0f: fn.write(f'FSLDIR={FSLDIR}\nexport FSLDIR='+'${FSLDIR}\n\n')          

            if not args.lcfeatadapter:
                F0f[0].write(f'export OGREDIR={OGREDIR}\n')
                if not args.lcsmoothonly and not args.lct1copymaskonly: 
                    F0f[0].write('P0=${OGREDIR}/HCP/scripts/'+P0+'\n')
                if not args.lcsmoothonly:
                    F0f[0].write('P1=${OGREDIR}/HCP/scripts/'+P1+'\n')
                if not args.lct1copymaskonly:
                    F0f[0].write('P2=${OGREDIR}/HCP/scripts/'+P2+'\n')

            if args.fsf1:
                for fn in F0f: fn.write(f'P3=${OGREDIR}/HCP/scripts/'+P3+'\n')          

            if not args.lcfeatadapter:
                F0f[0].write('SETUP=${OGREDIR}/HCP/scripts/'+SETUP+'\n\n')
                F0f[0].write(f's0={s0}\nsf0={dir1}\n\n')

                if not args.lcsmoothonly and not args.lct1copymaskonly: 
                    F0f[0].write('${P0} \\\n')
                    F0f[0].write('    --StudyFolder=${sf0} \\\n')
                    F0f[0].write('    --Subject=${s0} \\\n')
                    F0f[0].write('    --runlocal \\\n')
                    F0f[0].write('    --fMRITimeSeries="\\\n')
                    for j in range(len(scans.bold)-1): F0f[0].write(f'        {scans.bold[j][0]} \\\n')
                    F0f[0].write(f'        {scans.bold[j+1][0]}" \\\n')
                    
                    if scans.sbref:
                        if any(par.bsbref):
                            F0f[0].write('    --fMRISBRef="\\\n')
                            for j in range(len(scans.bold)-1): 
                                if par.bsbref[j]: 
                                    F0f[0].write(f'        {scans.sbref[j][0]} \\\n')
                                else:
                                    F0f[0].write('        NONE \\\n')
                            if par.bsbref[j+1]: 
                                F0f[0].write(f'        {scans.sbref[j+1][0]}" \\\n')
                            else:
                                F0f[0].write('        NONE" \\\n')
                            
                    if scans.fmap:
                        if any(par.bfmap):
                            if any(par.bbold_fmap):
                                F0f[0].write('    --SpinEchoPhaseEncodeNegative="\\\n')
                                for j in range(len(scans.bold)-1): 
                                    if par.bbold_fmap[j]: 
                                        F0f[0].write(f'        {fmap[scans.bold[j][1]*2+par.fmapnegidx[scans.bold[j][1]]]} \\\n')
                                    else:
                                        F0f[0].write('        NONE \\\n')
                                if par.bbold_fmap[j+1]: 
                                    F0f[0].write(f'        {fmap[scans.bold[j+1][1]*2+par.fmapnegidx[scans.bold[j][1]]]}" \\\n')
                                else:
                                    F0f[0].write('        NONE"\n')
                                F0f[0].write('    --SpinEchoPhaseEncodePositive="\\\n')
                                for j in range(len(scans.bold)-1): 
                                    if par.bbold_fmap[j]: 
                                        F0f[0].write(f'        {fmap[scans.bold[j][1]*2+par.fmapposidx[scans.bold[j][1]]]} \\\n')
                                    else:
                                        F0f[0].write('        NONE \\\n')
                                if par.bbold_fmap[j+1]: 
                                    F0f[0].write(f'        {fmap[scans.bold[j+1][1]*2+par.fmapposidx[scans.bold[j][1]]]}" \\\n')
                                else:
                                    F0f[0].write('        NONE"\n')

                    F0f[0].write('    --freesurferVersion=${FREESURFVER} \\\n')
                    F0f[0].write('    --EnvironmentScript=${SETUP}\n\n')

                if not args.lcsmoothonly: 
                    F0f[0].write('${P1} \\\n')
                    str0 = pathlib.Path(scans.bold[0][0]).name.split('.nii')[0]
                    F0f[0].write('    --t1=${sf0}/'+f'{str0}/T1w_restore.2.nii.gz \\\n')
                    F0f[0].write('    --mask=${sf0}/'+f'{str0}/brainmask_fs.2.nii.gz \\\n')
                    F0f[0].write('    --outpath=${sf0}/MNINonLinear/Results \\\n')
                    F0f[0].write('    --EnvironmentScript=${SETUP}\n\n')

                if scans.taskidx and not args.lct1copymaskonly: 
                    F0f[0].write('${P2} \\\n')
                    F0f[0].write('    --fMRITimeSeriesResults="\\\n')
                    for j in range(len(scans.taskidx)-1): 
                        str0 = pathlib.Path(scans.bold[scans.taskidx[j]][0]).name.split('.nii')[0]
                        F0f[0].write('        ${sf0}/MNINonLinear/Results/'+f'{str0}/{str0}.nii.gz \\\n')
                    str0 = pathlib.Path(scans.bold[scans.taskidx[j+1]][0]).name.split('.nii')[0]
                    F0f[0].write('        ${sf0}/MNINonLinear/Results/'+f'{str0}/{str0}.nii.gz" \\\n')
                    if args.fwhm: F0f[0].write(f'    --fwhm="{' '.join(args.fwhm)}" \\\n')
                    if args.paradigm_hp_sec: 
                        F0f[0].write(f'    --paradigm_hp_sec="{args.paradigm_hp_sec}" \\\n')
                        F0f[0].write(f'    --TR="{' '.join([str(get_TR(scans.bold[scans.taskidx[j]][0])) for j in scans.taskidx])}" \\\n') 
                    F0f[0].write('    --EnvironmentScript=${SETUP}\n')

                if args.fsf1:
                    for fn in F0f: 
                        for j in feat1.fsf: fn.write('\n${FSLDIR}/bin/feat '+f'{j}')
                        for j in feat1.outputdir: fn.write('\n${P3} ${s0} '+f'{pathlib.Path(j).stem}')
                        fn.write('\n')

                if args.fsf2:
                    for fn in F0f: 
                        for j in feat2.fsf: fn.write('\n${FSLDIR}/bin/feat '+f'{j}')

                #START240217
                #F2f.write(f's0={s0}\nsf0={dir1}\n\n')
                F2f.write(f's0={s0}\nsf0={dir1}\nsf1={dir2}\n\n')
                F2f.write('FILES=(\\\n')
                for j in range(len(scans.bold)-1): 
                    str0 = pathlib.Path(scans.bold[j][0]).name.split('.nii')[0]
                    F2f.write('    ${sf0}/MNINonLinear/Results/'+f'{str0}/{str0}_OGRE.nii.gz \\\n')
                str0 = pathlib.Path(scans.bold[j+1][0]).name.split('.nii')[0]
                F2f.write('    ${sf0}/MNINonLinear/Results/'+f'{str0}/{str0}_OGRE.nii.gz)\n\n')
                F2f.write('for i in ${FILES};do\n')
                F2f.write('    if [ ! -f "${i}" ];then\n')
                F2f.write('        ${i} not found.\n')
                F2f.write('        continue\n')
                F2f.write('    fi\n')
                F2f.write('    cp -p $i ${sf1}/func\n')
                F2f.write('done\n')




                if not os.path.isfile(F0[0]):
                    for j in F0: _=run_cmd(f'rm -f {j}')
                    _=run_cmd(f'rm -f {F1}')
                    _=run_cmd(f'rm -f {F2}')
                else:
                    F1f.write(f'F0={F0[0]}\n\n'+'out=${F0}.txt\n')
                    F1f.write('if [ -f "${out}" ];then\n')
                    F1f.write('    echo -e "\\n\\n**********************************************************************" >> ${out}\n')
                    F1f.write('    echo "    Reinstantiation $(date)" >> ${out}\n')
                    F1f.write('    echo -e "**********************************************************************\\n\\n" >> ${out}\n')
                    F1f.write('fi\n')
                    F1f.write('${F0} >> ${out} 2>&1 &\n')
                    
                    for j in F0: 
                        junk=run_cmd(f'chmod +x {j}')
                        print(f'    Output written to {j}')
                    _=run_cmd(f'chmod +x {F1}')
                    print(f'    Output written to {F1}')

                    #START240217
                    _=run_cmd(f'chmod +x {F2}')
                    print(f'    Output written to {F2}')

        exit()
