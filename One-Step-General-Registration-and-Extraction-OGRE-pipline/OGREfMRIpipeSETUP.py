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
            i=-1
            for line0 in f0:
                i+=1
                if not line0.strip() or line0.startswith('#'): continue
                #https://stackoverflow.com/questions/44785374/python-re-split-string-by-commas-and-space
                line1 = re.findall(r'[^,\s]+', line0)
                print(line1[1])
                file0 = line1[1] + '.nii.gz'
                if not os.path.isfile(file0):
                    print(f'Error: {file0} does not exist. Please place a # at the beginning of line {i+1}')
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
                            self.taskidx.append(i)
                        else:
                            self.restidx.append(i)

        if len(self.sbref) != len(self.bold):
            print(f'There are {len(self.sbref)} reference files and {len(self.bold)} bolds. Must be equal. Abort!')
            exit()
        print(f'self.fmap={self.fmap}')
        print(f'self.sbref={self.sbref}')
        print(f'self.bold={self.bold}')
        print(f'self.taskidx={self.taskidx}')
        print(f'self.restidx={self.restidx}')

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

        print(f'bsbref={self.bsbref}')
        print(f'ped={self.ped}')
        print(f'dim={self.dim}')

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

        print(f'bfmap={self.bfmap}')
        print(f'ped_fmap={self.ped_fmap}')
        print(f'dim_fmap={self.dim_fmap}')

    def check_ped_dims(self,bold,fmap):
        self.bbold_fmap=[False]*len(self.ped)
        if any(self.bfmap):
            for j in range(len(self.ped)):
                if self.bfmap[bold[j][1]]:
                    if self.ped[j][0] != self.ped_fmap[bold[j][1]][0]:
                        print(f'    ERROR: {bold[j][0]} {self.ped[j][0]}')
                        #print(f'    ERROR: {fmap[bold[j][1]]} {self.ped_fmap[bold[j][1]][0]}')
                        print(f'    ERROR: {fmap[bold[j][1]*2]} {self.ped_fmap[bold[j][1]][0]}')
                        print(f"           Fieldmap encoding direction must be the same! Fieldmap won't be applied.")
                        continue
                    if self.dim[j] != self.dim_fmap[bold[j][1]]:
                        print(f'    ERROR: {bold[j][0]} {self.dim[j]}')
                        #print(f'    ERROR: {fmap[bold[j][1]]} {self.dim_fmap[bold[j][1]]}')
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
        print(f'bbold_fmap={self.bbold_fmap}')




def run_cmd(cmd):
    return subprocess.run(cmd, capture_output=True, shell=True).stdout.decode().strip()

def get_phase(file):
    jsonf = file.split('.')[0] + '.json'
    if not os.path.isfile(jsonf):
        print(f'    {jsonf} does not exist. Abort!')
        return 'ERROR'
    print(f'get_phase jsonf={jsonf}')

    #line0 = run_cmd(f'grep PhaseEncodingDirection {jsonf}')
    #print(f'get_phase line0={line0}')
    #dict0 = json.loads(line0)

    with open(jsonf,encoding="utf8",errors='ignore') as f0:
        dict0 = json.load(f0)

    print(f"get_phase {dict0['PhaseEncodingDirection']}")

    return dict0['PhaseEncodingDirection']

def get_dim(file):
    line0 = run_cmd(f'fslinfo {file} | grep -w dim[1-3]')
    line1=line0.split()
    return (line1[1],line1[3],line1[5])


if __name__ == "__main__":
    get_env_vars()

    fwhm=0
    paradigm_hp_sec=0
    bhostname=False

    import argparse
    parser=argparse.ArgumentParser(description='Create OGRE fMRI pipeline script.\nRequired: <datfile(s)>',formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('dat0',metavar='<datfile(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be dat files.')
    hdat = '-d --dat -dat\n' \
         + '        Ex 1. '+parser.prog+' 1001.dat 2000.dat\n' \
         + '        Ex 2. '+parser.prog+' "1001.dat -d 2000.dat"\n' \
         + '        Ex 3. '+parser.prog+' -d 1001.dat 2000.dat\n' \
         + '        Ex 4. '+parser.prog+' -d "1001.dat 2000.dat"\n' \
         + '        Ex 5. '+parser.prog+' -d 1001.dat -d 2000.dat\n' \
         + '        Ex 6. '+parser.prog+' 1001.dat -d 2000.dat\n'
    parser.add_argument('-d','--dat','-dat',dest='dat',metavar='*.dat',action='append',nargs='+',help=hdat)

    hlcautorun='Flag. Automatically execute *_fileout.sh script. Default is to not execute.'
    parser.add_argument('-A','--autorun','-autorun','--AUTORUN','-AUTORUN',dest='lcautorun',action='store_true',help=hlcautorun)

    hbs='*_fileout.sh scripts are collected in the executable batchscript.'
    parser.add_argument('-b','--batchscript','-batchscript',dest='bs',metavar='batchscript',help=hbs)
    #sbs = ['-b','--batchscript','-batchscript']
    #parser.add_argument(sbs,dest='bs',metavar='batchscript',help=hbs)


    #START240114
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
    parser.add_argument('-f','--fwhm',dest='fwhm',metavar=mfwhm,action='append',nargs='+',help=hfwhm)

    hparadigm_hp_sec='High pass filter cutoff (s)'
    mparadigm_hp_sec='HPFcutoff'
    parser.add_argument('-p','--paradigm_hp_sec',dest='paradigm_hp_sec',metavar=mparadigm_hp_sec,help=hparadigm_hp_sec)

    hlct1copymaskonly='Flag. Only copy the T1w_restore.2 and mask to create T1w_restore_brain.2'
    parser.add_argument('-T','--T1COPYMASKONLY',dest='lct1copymaskonly',action='store_true',help=hlct1copymaskonly)

    hlcsmoothonly='Flag. Only do SUSAN smoothing and high pass filtering.'
    parser.add_argument('-s','--SMOOTHONLY',dest='lcsmoothonly',action='store_true',help=hlcsmoothonly)

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

    if fwhm==0 and not args.lcfeatadapter: 
        print(f'{mfwhm} has not been specified. SUSAN noise reduction will not be performed.') 

    if paradigm_hp_sec==0 and not args.lcfeatadapter:
        print(f'{mparadigm_hp_sec} has not been specified. High pass filtering will not be performed.') 

    if args.HCPDIR: HCPDIR = args.HCPDIR 
    if args.FREESURFVER: FREESURFVER = args.FREESURFVER


    print(f'HCPDIR={HCPDIR}')
    print(f'FREESURFVER={FREESURFVER}')

    if args.fsf1:
        outputdir1 = []
        for i in args.fsf1:
            line0 = run_cmd(f'grep "set fmri(outputdir)" {str(i).strip("[]")}')
            outputdir1.append(line0.split('"')[1])
        print(f'outputdir1 = {outputdir1}')

    if args.fsf2:
        outputdir2 = []
        for i in args.fsf1:
            #line0 = subprocess.check_output(f'grep "set fmri(outputdir)" {str(i).strip("[]")}',shell=True,text=True)
            line0 = run_cmd(f'grep "set fmri(outputdir)" {str(i).strip("[]")}')
            outputdir2.append(line0.split('"')[1])
        print(f'outputdir2 = {outputdir2}')


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
        print(f'date0 = {date0}')
        datestr = '_' + date0


    if not args.lcfeatadapter: 
        if not args.lcsmoothonly: 
            l0 = 'hcp3.27fMRIvol' 
        else: 
            l0 = 'smooth'
    else:
        l0 = 'FEATADAPTER'

    for i in args.dat:

        scans = Scans(i)
        idx = i.find('sub-')
        if idx != -1:
            s0 = i[idx: idx + i[idx:].find('/')]
            print(f's0={s0}')
        

        idx = i.find('raw_data')
        if idx == -1:
            pass
        else:
            print(i[:idx])
            dir0 = i[:idx] + 'derivatives/preprocessed/' + s0 + '/pipeline' + FREESURFVER
            dir1 = i[:idx] + 'derivatives/preprocessed/${s0}/pipeline${FREESURFVER}'
            print(f'dir0={dir0}\ndir1={dir1}')

        if bhostname:
            hostname = run_cmd('hostname')
            dir0 += '_' + hostname 
            dir1 += '_$(hostname)' 

        stem0 = dir0 + '/' + s0
        #str0 = stem0 + '_' + l0
        #if args.lcdate > 0: str0 += '_' + date0 
        str0 = stem0 + '_' + l0 + datestr

        F0 = [str0 + '.sh']
        F1 = str0 + '_fileout.sh'
        print(f'F0={F0}\nF1={F1}')

        if not args.lcfeatadapter and args.fsf1: 
            str0 = stem0 + '_FEATADAPTER' + datestr
            F0.append(str0 + '.sh')

        if args.bs:
            str0 = stem0 + '_hcp3.27batch' + datestr
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

            #print(f'len(scans.bold)={len(scans.bold)}')

            par = Par(len(scans.bold),int(len(scans.fmap)))
            par.check_phase_dims(list(zip(*scans.bold))[0],list(zip(*scans.sbref))[0])

            if not args.lcsmoothonly and not args.lct1copymaskonly: 
                par.check_phase_dims_fmap(scans.fmap[0::2],scans.fmap[1::2])

                fmap = scans.fmap #if dims don't match bold, fieldmap pairs maybe resampled and new files created
                par.check_ped_dims(scans.bold,fmap)



        #STARTHERE
        from contextlib import ExitStack
        with ExitStack() as fs:
            F0f = [fs.enter_context(open(fn, "w")) for fn in F0]
            F1f = fs.enter_context(open(F1, "w"))

            for fn in F0f: fn.write(f'{SHEBANG}\nset -e\n\n#{' '.join(sys.argv)}\n\n')          
            F1f.write("{SHEBANG}\nset -e\n\n")          

            if not args.lcfeatadapter:
                F0f[0].write(f'FREESURFDIR={FREESURFDIR}\nFREESURFVER={FREESURFVER}\nexport FREESURFER_HOME='+'${FREESURFDIR}/${FREESURFVER}\n\n')

            if args.fsf1 or args.fsf2:
                for fn in F0f: fn.write(f'FSLDIR={FSLDIR}\nexport FSLDIR='+'${FSLDIR}\n\n')          

            if not args.lcfeatadapter:
                F0f[0].write(f'export OGREDIR={OGREDIR}\n')
                if not args.lcsmoothonly and not args.lct1copymaskonly: 
                    F0f[0].write('P0={OGREDIR}/HCP/scripts/'+P0+'\n')
                if not args.lcsmoothonly:
                    F0f[0].write('P1={OGREDIR}/HCP/scripts/'+P1+'\n')
                if not args.lct1copymaskonly:
                    F0f[0].write('P2={OGREDIR}/HCP/scripts/'+P2+'\n')

            if args.fsf1:
                for fn in F0f: fn.write(f'P3={OGREDIR}/HCP/scripts/'+P3+'\n')          

            if not args.lcfeatadapter:
                F0f[0].write('SETUP={OGREDIR}/HCP/scripts/'+SETUP+'\n\n')
                F0f[0].write(f's0={s0}\nsf0={dir1}\n\n')

                if not args.lcsmoothonly and not args.lct1copymaskonly: 
                    F0f[0].write('${P0} \\\n')
                    F0f[0].write('    --StudyFolder=${sf0} \\\n')
                    F0f[0].write('    --Subject=${s0} \\\n')
                    F0f[0].write('    --runlocal \\\n')
                    F0f[0].write('    --fMRITimeSeries="\\\n')
                    for j in range(len(scans.bold)-1): F0f[0].write(f'        {scans.bold[j][0]} \\\n')
                    F0f[0].write(f'        {scans.bold[j+1][0]}"\n')
                    
                    if scans.sbref:
                        if any(par.bsbref):
                            F0f[0].write('    --fMRISBRef="\\\n')
                            for j in range(len(scans.bold)-1): 
                                if par.bsbref[j]: 
                                    F0f[0].write(f'        {scans.sbref[j][0]} \\\n')
                                else:
                                    F0f[0].write('        NONE \\\n')
                            if par.bsbref[j+1]: 
                                F0f[0].write(f'        {scans.sbref[j+1][0]}"\n')
                            else:
                                F0f[0].write('        NONE"\n')
                            
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
                                    F0f[0].write(f'        {fmap[scans.bold[j+1][1]*2+par.fmapnegidx[scans.bold[j][1]]]} \\\n')
                                else:
                                    F0f[0].write('        NONE \\\n')
                                F0f[0].write('    --SpinEchoPhaseEncodePositive="\\\n')
                                for j in range(len(scans.bold)-1): 
                                    if par.bbold_fmap[j]: 
                                        F0f[0].write(f'        {fmap[scans.bold[j][1]*2+par.fmapposidx[scans.bold[j][1]]]} \\\n')
                                    else:
                                        F0f[0].write('        NONE \\\n')
                                if par.bbold_fmap[j+1]: 
                                    F0f[0].write(f'        {fmap[scans.bold[j+1][1]*2+par.fmapposidx[scans.bold[j][1]]]} \\\n')
                                else:
                                    F0f[0].write('        NONE \\\n')

        exit()

"""
    echo "s0=${s0}" >> ${F0}
    echo "sf0=${dir1}" >> ${F0}


    if args.fsf1:
        outputdir1 = []
        for i in args.fsf1:
            line0 = run_cmd(f'grep "set fmri(outputdir)" {str(i).strip("[]")}')
            outputdir1.append(line0.split('"')[1])
        print(f'outputdir1 = {outputdir1}')

    if args.fsf2:
        outputdir2 = []
        for i in args.fsf1:
            #line0 = subprocess.check_output(f'grep "set fmri(outputdir)" {str(i).strip("[]")}',shell=True,text=True)
            line0 = run_cmd(f'grep "set fmri(outputdir)" {str(i).strip("[]")}')
            outputdir2.append(line0.split('"')[1])
        print(f'outputdir2 = {outputdir2}')


from contextlib import ExitStack
with ExitStack() as stack:
    files = [
        stack.enter_context(open(filename))
        for filename in filenames
    ]



filenames = "file1.txt", "file2.txt", "file3.txt", "file4.txt"
with ExitStack() as fs:
    file1, file2, file3, file4 = (fs.enter_context(open(fn, "w")) for fn in filenames)
    ...
    file2.write("Some text")
"""


"""
            with open(i[j],encoding="utf8",errors='ignore') as f0:
                for line0 in f0:
                    if not line0.strip() or line0.startswith('#'): continue
                    if not 'keys' in locals():
                        keys = line0.split()
                        continue
                    d0 = Dat(dict(zip(keys,line0.split())))
                    dir0 = d0.OUTDIR + FREESURFVER

                    if args.lcdate == 1:
                        date0 = datetime.today().strftime("%y%m%d")
                    elif args.lcdate == 2:
                        date0 = datetime.today().strftime("%y%m%d%H%M%S")
                    #print(f'date0 = {date0}')

                    #stem0 = dir0 + '/' + line0.split()[0].replace("/","_")
                    stem0 = dir0 + '/' + d0.SUBNAME.split()[0].replace("/","_")

                    if not args.lcfeatadapter: 
                        if not args.lcsmoothonly: 
                            l0 = 'hcp3.27fMRIvol' 
                        else: 
                            l0 = 'smooth'
                    else:
                        l0 = 'FEATADAPTER'
                    str0 = stem0 + l0
                    if args.lcdate > 0: str0 += '_' + date0 
                    F0 = [str0 + '.sh']
                    F1 = str0 + '_fileout.sh'

                    if not args.lcfeatadapter and args.fsf1: 
                        str0 = stem0 + '_FEATADAPTER'
                        if args.lcdate > 0: str0 += '_' + date0 
                        F0.append(str0 + '.sh')

                    if args.bs:
                        str0 = stem0 + '_hcp3.27batch'
                        if args.lcdate > 0: str0 += '_' + date0
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
         
                    ind_task = check_bolds(d0.task, d0.task_SBRef)
                    print(f'ind_task = {ind_task}')
                    print(f'd0.task = {d0.task}')
                    print(f'd0.task_SBRef = {d0.task_SBRef}') 

                    ind_rest = check_bolds(d0.rest, d0.rest_SBRef)
                    print(f'ind_rest = {ind_rest}')
                    print(f'd0.rest = {d0.rest}')
                    print(f'd0.rest_SBRef = {d0.rest_SBRef}') 

                    if not args.lcfeatadapter: 
                        ind_task_SBRef, ped_task = check_phase_dims(d0.task,d0.task_SBRef,ind_task)                    
                        ind_rest_SBRef, ped_rest = check_phase_dims(d0.rest,d0.rest_SBRef,ind_rest)                    

            del keys



#        self.task_SBRef = []
#        self.task = []
#        self.rest_SBRef = []
#        self.rest = []

if args.bs: bs0.close()
"""

#if __name__ == "__main__":
#    #file = '/Users/Shared/10_Connectivity/10_2000/10_2000_new.dat'
#    #main(file)
#
#    get_env_vars()

#d0={"SUBNAME":"NONE",
#    "OUTDIR":"NONE",
#    "t1_mpr_1mm_p2_pos50":"NONE",
#    "t2_spc_sag_p2_iso_1.0":"NONE",
#    "SpinEchoFieldMap2_AP":"NONE",
#    "SpinEchoFieldMap2_PA":"NONE",
#    "run1_LH_SBRef":"NONE",
#    "run1_LH":"NONE",
#    "run1_RH_SBRef":"NONE",
#    "run1_RH":"NONE",
#    "run2_LH_SBRef":"NONE",
#    "run2_LH":"NONE",
#    "run2_RH_SBRef":"NONE",
#    "run2_RH":"NONE",
#    "run3_LH_SBRef":"NONE",
#    "run3_LH":"NONE",
#    "run3_RH_SBRef":"NONE",
#    "run3_RH":"NONE",
#    "rest01_SBRef":"NONE",
#    "rest01":"NONE",
#    "rest02_SBRef":"NONE",
#    "rest02":"NONE",
#    "rest03_SBRef":"NONE",
#    "rest03":"NONE"}
#
#
#def readdat(file):






"""
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

                        #d0[k]=str(p0)+'/nifti/'+k+'.nii.gz'
                        #START231018
                        file=str(p0)+'/nifti/'+k+'.nii.gz' 
                        if pathlib.Path(file).exists():
                            d0[k]=file
                        else:
                            print(f'{file} does not exist!')

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
"""
