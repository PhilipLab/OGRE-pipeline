#!/usr/bin/env python3

import argparse
from datetime import datetime
import glob
import os
import pathlib
import sys

import opl

P0='OGREGenericfMRIVolumeProcessingPipelineBatch.sh' 
P2='OGRESmoothingProcess.sh'
P3='OGREmakeregdir.sh'
SETUP='OGRESetUpHCPPipeline.sh'
P4='OGRESplitFreeSurferMasks.sh'

from contextlib import ExitStack
def open_files(filenames,mode):
    #https://www.rath.org/on-the-beauty-of-pythons-exitstack.html
    #https://docs.python.org/3/library/contextlib.html#contextlib.ExitStack
    with ExitStack() as stack:
        files = [stack.enter_context(open(fname,mode)) for fname in filenames]
        stack.pop_all()
        return files

def get_feat(arg):
    if not arg: return False
    feat = Feat(arg)
    if not feat.fsf: return False
    return feat
class Feat:
    def __init__(self,arg):
        self.outputdir = []
        self.level = []
        self.fsf = []
        for i in arg:
            #print(f'Reading {i} ...') 
            p0 = pathlib.Path(i)
            if not p0.exists():
                print(f'ERROR: {i} does not exist. Skipping!')
                continue 
            if p0.is_dir():
                fsf0 = p0.glob('*.fsf') 
                #if fsf0: for j in fsf0: self.__grep_fsf(j.as_posix())
                if fsf0: 
                    for j in fsf0: 
                        #print(f'j.as_posix()={j.as_posix()}')
                        self.__grep_fsf(j.as_posix())

            elif p0.is_file():
                if p0.suffix=='.fsf': 

                    #print(f'p0.as_posix()={p0.as_posix()}')

                    self.__grep_fsf(p0.as_posix())
                else:
                    with open(p0,encoding="utf8",errors='ignore') as f0:
                        for line0 in f0:
                            line1=line0.strip()
                            if not line1 or line1.startswith('#'): continue

                            p0 = pathlib.Path(line0)
                            if not p0.exists():
                                print(f'{line0} does not exist. Skipping!')
                                continue
                            if p0.is_dir():
                                fsf0 = p0.glob('*.fsf')
                                if fsf0:
                                    #for j in fsf0: __grep_fsf(self,j.as_posix())
                                    for j in fsf0: self.__grep_fsf(j.as_posix())
                            elif p0.is_file():
                                if p0.suffix=='.fsf':
                                    self.__grep_fsf(p0.as_posix())
                            else:
                                print(f'{i} is neither a directory of file. Skipping!')
            else:
                print(f'{i} is neither a directory of file. Skipping!')
        #print(f'self.outputdir = {self.outputdir}') 
        #print(f'self.level = {self.level}') 
        #print(f'self.fsf = {self.fsf}') 

    def __grep_fsf(self,fsf):
        line0 = opl.rou.run_cmd(f'grep "set fmri(outputdir)" {fsf}')
        self.outputdir.append(line0.split('"')[1])
        line0 = opl.rou.run_cmd(f'grep "set fmri(level)" {fsf}')

        #print(f'line0 = {line0}')
        #junk=line0.split('"')
        #print(f'junk = {junk}')

        #self.level.append(line0.split('"')[1])
        self.level.append(line0.split()[2])
        self.fsf.append(fsf)

    def write_script(self,filename,gev):
        if not gev:
            gev = opl.rou.get_env_vars(args)
            if not gev: exit()
        with open(filename,'w',encoding="utf8",errors='ignore') as f0:

            f0.write(f'{gev.SHEBANG}\nset -e\n\n')

            #if cmd_line_call: f0.write(f'#{cmd_line_call}\n\n')

            f0.write(f'FSLDIR={gev.FSLDIR}\nexport FSLDIR='+'${FSLDIR}\n\n')

            # https://favtutor.com/blogs/get-list-index-python
            #index = [i for i ,e in enumerate(self.level) if e == 1]
            index = [i for i ,e in enumerate(self.level) if e == '1']

            #print(f'index={index}')

            if index:
                f0.write(f'OGREDIR={gev.OGREDIR}\n'+'MAKEREGDIR=${OGREDIR}/lib/'+P3+'\n')
                for i in index: f0.write('\n${FSLDIR}/bin/feat '+self.fsf[i]+'\n${MAKEREGDIR} '+self.outputdir[i])

            #index = [i for i ,e in enumerate(self.level) if e == 2]
            index = [i for i ,e in enumerate(self.level) if e == '2']

            #print(f'index={index}')

            if index:
                for i in index: f0.write('\n${FSLDIR}/bin/feat '+self.fsf[i])

        opl.rou.make_executable(filename)

if __name__ == "__main__":

    print('here0')

    parser=argparse.ArgumentParser(description=f'Create OGRE fMRI pipeline script. Required: OGREfMRIpipeSETUP.py <scanlist.csv>',formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('dat0',metavar='<scanlist.csv(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be scanlist.csv files.')
    hdat = 'Ex 1. '+parser.prog+' sub-1001_scanlist.csv sub-2000_scanlist.csv\n' \
         + 'Ex 2. '+parser.prog+' "sub-1001_scanlist.csv -s sub-2000_scanlist.csv"\n' \
         + 'Ex 3. '+parser.prog+' -s sub-1001_scanlist.csv sub-2000_scanlist.csv\n' \
         + 'Ex 4. '+parser.prog+' -s "sub-1001_scanlist.csv sub-2000_scanlist.csv"\n' \
         + 'Ex 5. '+parser.prog+' -s sub-1001_scanlist.csv -s sub-2000_scanlist.csv\n' \
         + 'Ex 6. '+parser.prog+' sub-1001_scanlist.csv -s sub-2000_scanlist.csv\n'
    parser.add_argument('-s','--scanlist','-scanlist',dest='dat',metavar='scanlist.csv',action='extend',nargs='+',help=hdat)

    hlcautorun='Flag. Automatically execute *_fileout.sh script. Default is to not execute.'
    parser.add_argument('-A','--autorun','-autorun','--AUTORUN','-AUTORUN',dest='lcautorun',action='store_true',help=hlcautorun)

    hOGREDIR='OGRE directory. Location of OGRE scripts.\n' \
        +'Optional if set at the top of this script or elsewhere via variable OGREDIR.\n' \
        +'The path provided by this option will be used instead of any other setting.\n'
    parser.add_argument('-O','--OGREDIR','-OGREDIR','--ogredir','-ogredir',dest='OGREDIR',metavar='OGREdirectory',help=hOGREDIR)

    hHCPDIR='HCP directory. Optional if set at the top of this script or elsewhere via variable HCPDIR.'
    parser.add_argument('-H','--HCPDIR','-HCPDIR','--hcpdir','-hcpdir',dest='HCPDIR',metavar='HCPdirectory',help=hHCPDIR)

    hFREESURFVER='5.3.0-HCP, 7.2.0, 7.3.2, 7.4.0 or 7.4.1. Default is 7.4.1 unless set elsewhere via variable FREESURFVER.'
    parser.add_argument('-V','--VERSION','-VERSION','--FREESURFVER','-FREESURFVER',dest='FREESURFVER',metavar='FreeSurferVersion', \
        help=hFREESURFVER,choices=['5.3.0-HCP', '7.2.0', '7.3.2', '7.4.0', '7.4.1'])

    hbhostname='Flag. Append machine name to pipeline directory. Ex. pipeline7.4.0_3452-AD-05003'
    parser.add_argument('-m','--HOSTNAME',dest='bhostname',action='store_true',help=hbhostname)

    hlcdate='Flag. Add date (YYMMDD) to name of output script.'
    parser.add_argument('-D','--DATE','-DATE','--date','-date',dest='lcdate',action='store_const',const=1,help=hlcdate,default=0)

    hlcdateL='Flag. Add date (YYMMDDHHMMSS) to name of output script.'
    parser.add_argument('-DL','--DL','--DATELONG','-DATELONG','--datelong','-datelong',dest='lcdate',action='store_const',const=2,help=hlcdateL,default=0)

    hfwhm='Smoothing (mm) for SUSAN. Multiple values ok.'
    mfwhm='FWHM'
    parser.add_argument('-f','--fwhm',dest='fwhm',metavar=mfwhm,action='append',nargs='+',help=hfwhm)

    hparadigm_hp_sec='High pass filter cutoff in seconds'
    mparadigm_hp_sec='HPFcutoff'
    parser.add_argument('-p','--paradigm_hp_sec',dest='paradigm_hp_sec',metavar=mparadigm_hp_sec,help=hparadigm_hp_sec)

    hlcsmoothonly='Flag. Only do SUSAN smoothing and high pass filtering.\n' \
        + 'If you want to execute smoothing/filtering on individual runs, edit the .sh run script.'
    parser.add_argument('--smoothonly','-smoothonly','--SMOOTHONLY','-SMOOTHONLY',dest='lcsmoothonly',action='store_true',help=hlcsmoothonly)

    hfeat='Path to fsf files, text file which lists fsf files or directories with fsf files, one or more fsf files, or a combination thereof.\n' \
        +'An OGREfeat.sh call is created for each fsf.'
    parser.add_argument('--feat','-feat','--fsf','-fsf','-o','-fsf1','--fsf1','-t','-fsf2','--fsf2',dest='feat',metavar='path, text file or *.fsf',action='extend',
        nargs='+',help=hfeat)

    hlcfeatadapter='Flag. Only write the feat adapter scripts.'
    parser.add_argument('-F','--FEATADAPTER','-FEATADAPTER','--featadapter','-featadapter',dest='lcfeatadapter',action='store_true',help=hlcfeatadapter)

    hbs = '*_fileout.sh scripts are collected in an executable batchscript, one for each scanlist.csv.\n' \
        + 'This permits the struct and fMRI scripts to be run sequentially and seamlessly.\n' \
        + 'If a filename is provided, then in addition, the *OGREbatch.sh scripts are written to the provided filename.\n' \
        + 'This permits multiple subjects to be run sequentially and seamlessly.\n'
    parser.add_argument('-b','--batchscript','-batchscript',dest='bs',metavar='batchscript',nargs='?',const=True,help=hbs)

    huserefinement='Flag. Use the freesurfer refinement in the warp for one step resampling.\n' \
        + 'Defaut is not use the refinement as this was found to misregister the bolds.\n'
    parser.add_argument('-userefinement','--userefinement','-USEREFINEMENT','--USEREFINEMENT',dest='userefinement',action='store_true',help=huserefinement)

    hfslmo='Run fsl_motion_outliers on raw data, with optional comma-separated arguments.\n' \
        +'Ex. -fslmo "--fd,--thresh=2"\n' \
        +'Ex. -fslmo --fd,--thresh=2\n'
    parser.add_argument('-fslmo','--fslmo',dest='fslmo',action='store_true',help=hfslmo)

    hdil='Dilate masks applied to fMRI at output.'
    mdil='Dilate output masks'
    parser.add_argument('-dil','--dil','-dilation','--dilation',dest='dilation',metavar=mdil,help=hdil,default=0)

    hstartIntensityNormalization='Flag. Start at IntensityNormalization. Defaut is to run the whole script.\n'
    parser.add_argument('-startIntensityNormalization','--startIntensityNormalization','-sin','--sin',dest='startIntensityNormalization',action='store_true',help=hstartIntensityNormalization)

    hd='Archaic. Use --container_directory instead.'
    parser.add_argument('-d','--dir','-dir',dest='dir',metavar='Pipeline directory',help=hd)
    flagdsir=['-d','--dir','-dir']

    happend='Archaic. Use --container_directory instead.'
    parser.add_argument('-append','--append',dest='append',metavar='mystr',help=happend)
    flagsappend=['-append','--append']

    hcd0='Container directory\n' \
        +'    Ex. /Users/Shared/10_Connectivity/derivatives/preprocessed/sub-1019_OGRE-preproc\n' \
        +'        func, anat, regressors, pipeline7.4.1 are created inside this directory'
    parser.add_argument('--container_directory','-container_directory','--cd','-cd',dest='cd0',metavar='mystr',help=hcd0)

    #START230411 https://stackoverflow.com/questions/22368458/how-to-make-argparse-print-usage-when-no-option-is-given-to-the-code
    if len(sys.argv)==1:
        parser.print_help()
        # parser.print_usage() # for just the usage line
        parser.exit()
    args, unknown = parser.parse_known_args()

    #print(f'unknown={unknown}')
    #print(f'args.fslmo={args.fslmo}')
    #print(f'args.bs={args.bs}')

    if args.dir:
        #print(f'sys.argv={sys.argv}')
        matches = [x for x in flagsdir if x in sys.argv]
        #print(f'matches={matches}')
        print(f'Your option list includes "{matches[0]} {args.dir}". Archaic. Use --container_directory instead. Abort!\n')
        exit()
    if args.append:
        #print(f'sys.argv={sys.argv}')
        matches = [x for x in flagsappend if x in sys.argv]
        #print(f'matches={matches}')
        print(f'Your option list includes "{matches[0]} {args.append}". Archaic. Use --container_directory instead. Abort!\n')
        exit()

    print(f'{' '.join(sys.argv)}')

    if args.dat:
        if args.dat0:
            args.dat += args.dat0
    elif args.dat0:
        args.dat=args.dat0
    else:
        exit()
    args.dat = [str(pathlib.Path(i).resolve()) for i in args.dat]

    gev = opl.rou.get_env_vars(args)
    if not gev: exit()

    if not args.lcfeatadapter:
        if not args.fwhm:
            print(f'{mfwhm} has not been specified. SUSAN noise reduction will not be performed.')
        else:
            args.fwhm = sum(args.fwhm,[])
        if not args.paradigm_hp_sec: print(f'{mparadigm_hp_sec} has not been specified. High pass filtering will not be performed.')

    feat = get_feat(args.feat)

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
            l0 = 'OGREfMRIvol'
        else:
            l0 = 'smooth'
    else:
        l0 = 'FEATADAPTER'

    if args.bs:
        if args.bs!=True: #this explicit check is needed!
            args.bs = pathlib.Path(args.bs).resolve()
            if "/" in str(args.bs): os.makedirs(pathlib.Path(args.bs).resolve().parent,exist_ok=True)
            bs_fileout = str(args.bs).split('.sh')[0] + '_fileout.sh'
            batchscriptf = open_files([args.bs,bs_fileout],'w')
            for i in batchscriptf: i.write(f'{gev.SHEBANG}\n\n')

    if args.fslmo:
        if unknown:
            #https://stackoverflow.com/questions/44785374/python-re-split-string-by-commas-and-space
            #args.fslmo = ' '.join(re.findall(r'[^,\s]+',' '.join(str(i) for i in unknown)))
            #args.fslmo = ' '+' '.join(c.strip() for c in ' '.join(i for i in unknown).split(',') if not c.isspace())
            args.fslmo = ' '.join(c.strip() for c in ' '.join(i for i in unknown).split(',') if not c.isspace())
        #print(f'args.fslmo={args.fslmo}')

    for i in args.dat:
        print(f'Reading {i}')

        if not args.lcfeatadapter:
            par = opl.scans.Par(i)
        else:
            par = opl.scans.Scans(i)

        idx = i.find('sub-')

        if idx != -1:
            s0 = i[idx: idx + i[idx:].find('/')]
            #print(f's0={s0}')
            #print(f'{s0}')

        if args.cd0:
            p0=pathlib.Path(args.cd0)

            d0 = str(p0.resolve())
            dir0 = d0 + '/pipeline' + gev.FREESURFVER
            bids = d0
            dir1 = '${bids}/pipeline${FREESURFVER}'
            dir2 = bids + '/pipeline${FREESURFVER}'

            exists=False
            if p0.exists():
                for j in par.bold:
                    #print(f'{dir0}/MNINonLinear/Results/{pathlib.Path(j[0]).name.split('.nii')[0]}')
                    if pathlib.Path(f'{dir0}/MNINonLinear/Results/{pathlib.Path(j[0]).name.split('.nii')[0]}').exists():
                        exists=True
                        break

            print('here5')
            ynq = input('junk')
            #ynq = input('')

            #if p0.root:
            #    #TRAP 1
            #    if exists:
            #        str0=f'    \nContainer directory = {args.cd0}\n    Your container directory has preexisting functional outputs (MNINonLinear/Results) that will get overwritten.' \
            #            + ' Would you like to continue? y, n '
            #        print(f'str0={str0}')
            # 
            #        #ynq = input(str0).casefold()
            #        #ynq = input('junk').casefold()
            #        #if ynq=='q' or ynq=='quit' or ynq=='exit' or ynq=='n' or ynq=='no': exit()
            #        ynq = input('junk')

