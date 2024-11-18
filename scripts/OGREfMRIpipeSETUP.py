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
#P4='OGRESplitFreeSurferMasks.sh'
#P5='OGREMasksLow.sh'

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
                print(f'ERROR: {p0} does not exist. Skipping!')
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
                            p0 = pathlib.Path(line1)
                            if not p0.exists():
                                print(f'{p0} does not exist. Skipping!')
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
                                print(f'{line1} is neither a directory of file. Skipping!')
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


    #hd='Pipeline directory. Optional. BIDS directories are assumed to be at the same level on the directory tree.\n' \
    #    +'Ex. /Users/Shared/10_Connectivity/derivatives/preprocessed/sub-1001/pipeline7.4.1\n' \
    #    +'        BIDS directories are /Users/Shared/10_Connectivity/derivatives/preprocessed/sub-1001/anat\n' \
    #    +'                             /Users/Shared/10_Connectivity/derivatives/preprocessed/sub-1001/func\n'
    #parser.add_argument('-d','--dir','-dir',dest='dir',metavar='Pipeline directory',help=hd)
    #happend='Append string to pipeline output directory. Ex. -append debug, will result in pipeline7.4.1debug'
    #parser.add_argument('-append','--append',dest='append',metavar='mystr',help=happend,default='')
    #START240813    
    #hd='Archaic. Use --container_directory instead.'
    #parser.add_argument('-d','--dir','-dir',dest='dir',metavar='Pipeline directory',help=hd,type=abort)
    #happend='Archaic. Use --container_directory instead.'
    #parser.add_argument('-append','--append',dest='append',metavar='mystr',help=happend,default='',type=abort)

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

    #START240923
    #print(f'args={args}')

#STARTHERE
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

  
    #START240914
    print(f'{' '.join(sys.argv)}')          


    if args.dat:
        if args.dat0:
            args.dat += args.dat0
    elif args.dat0:
        args.dat=args.dat0
    else:
        exit()
    #args.dat = [os.path.abspath(i) for i in args.dat]
    #args.dat = [pathlib.Path(i).resolve() for i in args.dat]
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

        #print(f'i={i}')  
        #print(f'pathlib.Path(i).parent={pathlib.Path(i).parent}')  
        #os.makedirs(pathlib.Path(i).parent, exist_ok=True)

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
            #d0 = str(pathlib.Path(args.cd0).resolve())
            #print(f'pathlib.Path(args.cd0)={pathlib.Path(args.cd0)}')
            #print(f'pathlib.Path(args.cd0).resolve()={pathlib.Path(args.cd0).resolve()}')
            #print(f'pathlib.Path(args.cd0).absolute()={pathlib.Path(args.cd0).absolute()}')
            #p0=pathlib.Path(args.cd0)
            #print(f'p0.resolve()={p0.resolve()}')
            #print(f'pathlib.Path(args.cd0).is_absolute()={pathlib.Path(args.cd0).is_absolute()}')
            #print(f'os.path.abspath(args.cd0)={os.path.abspath(args.cd0)}')
            #print(f'pathlib.Path(args.cd0).root={pathlib.Path(args.cd0).root}')
            #print(f'pathlib.Path(args.cd0).drive={pathlib.Path(args.cd0).drive}')
            #print(f'd0={d0}')

            p0=pathlib.Path(args.cd0) 

            #START240909
            d0 = str(p0.resolve())
            dir0 = d0 + '/pipeline' + gev.FREESURFVER
            bids = d0 
            dir1 = '${bids}/pipeline${FREESURFVER}'
            dir2 = bids + '/pipeline${FREESURFVER}'

            #START240911
            exists=False
            if p0.exists():
                for j in par.bold:
                    #print(f'{dir0}/MNINonLinear/Results/{pathlib.Path(j[0]).name.split('.nii')[0]}')
                    if pathlib.Path(f'{dir0}/MNINonLinear/Results/{pathlib.Path(j[0]).name.split('.nii')[0]}').exists(): 
                        exists=True
                        break

            if p0.root:
                #TRAP 1

                #if p0.exists():
                #    #ynq = input(f'    \nContainer directory = {args.cd0}\n    Your container directory exists. Contents will be overwritten.' \
                #    #    + ' Would you like to continue? y, n ').casefold()
                #    #if ynq=='q' or ynq=='quit' or ynq=='exit' or ynq=='n' or ynq=='no': exit()
                #    #START240909
                #    #exists=False
                #    #for j in par.bold:
                #    #    #print(f'{dir0}/MNINonLinear/Results/{pathlib.Path(j[0]).name.split('.nii')[0]}')
                #    #    if pathlib.Path(f'{dir0}/MNINonLinear/Results/{pathlib.Path(j[0]).name.split('.nii')[0]}').exists(): 
                #    #        exists=True
                #    #        break
                #START240911
                if exists:
                    ynq = input(f'    \nContainer directory = {args.cd0}\n    Your container directory has preexisting functional outputs (MNINonLinear/Results) that will get overwritten.' \
                        + ' Would you like to continue? y, n ').casefold()
                    ##ynq = input(f'Container directory = {args.cd0} Your container directory has preexisting functional outputs (MNINonLinear/Results) that will get overwritten. Would you like to continue? y, n ').casefold()
                    ##ynq = input('My question here???')
                    if ynq=='q' or ynq=='quit' or ynq=='exit' or ynq=='n' or ynq=='no': exit()
                    #START240923
                    ##exit()

            else:

                ##TRAP 2
                #if p0.exists():
                #    ynq = input(f'    \nContainer directory = {args.cd0}\n    Your container directory is a relative path. Resolving ...\n' \
                #        + f'        {pathlib.Path(args.cd0).resolve()}\n    Directory exists. Contents will be overwritten.' 
                #        + ' Would you like to continue? y, n ').casefold()
                #    if ynq=='q' or ynq=='quit' or ynq=='exit' or ynq=='n' or ynq=='no': exit()
                #START240911
                #TRAP 2
                if exists:
                    ynq = input(f'    \nContainer directory = {args.cd0}\n    Your container directory is a relative path. Resolving ...\n' \
                        + f'        {d0}\n    Your container directory has preexisting functional outputs (MNINonLinear/Results) that will get overwritten.' \
                        + ' Would you like to continue? y, n ').casefold()
                    if ynq=='q' or ynq=='quit' or ynq=='exit' or ynq=='n' or ynq=='no': exit()


                #TRAP 3
                if pathlib.Path(f'/{p0}').exists():
                    print(f'    \nContainer directory = {args.cd0}\n' \
                        + '    Your container directory is missing the forward slash at the beginning.\n' \
                        + '    However, the directory with the added forward slash already exists. Danger of overwrite! Please correct. Abort!')
                    exit()
                #TRAP 4
                if pathlib.Path(f'/{p0.parts[0]}').exists():
                    print(f'    \nContainer directory = {args.cd0}\n' \
                        + '    Your container directory is missing the forward slash at the beginning. Please correct the typo. Abort!\n') 
                    exit()
                else:
                    #TRAP 5
                    ynq = input(f'    \nContainer directory = {args.cd0}\n' \
                        + '    Your container directory is missing the root (i.e. is a relative path, not an absolute path).\n' \
                        + '    The following root will be added:\n' \
                        + f'        {pathlib.Path.cwd()}\n' \
                        + f'    New container directory:\n    {pathlib.Path(args.cd0).resolve()}\n' \
                        + f'    Is this what you want? y, n ').casefold()
                    if ynq=='q' or ynq=='quit' or ynq=='exit' or ynq=='n' or ynq=='no': exit()
        else:
            idx = i.find('raw_data')
            if idx == -1:
                d0 = str(pathlib.Path(i).resolve().parent) + '/'
            else:
                d0 = i[:idx]
            dir0 = d0 + 'derivatives/preprocessed/' + s0 + '/pipeline' + gev.FREESURFVER
            bids = d0 + 'derivatives/preprocessed/${s0}'
            dir1 = '${bids}/pipeline${FREESURFVER}'
            dir2 = bids + '/pipeline${FREESURFVER}'

        if args.bhostname:
            hostname = opl.rou.run_cmd('hostname')
            dir0 += '_' + hostname
            dir1 += '_$(hostname)'

        #print(f'dir0={dir0}\ndir1={dir1}\ndir2={dir2}')

        #stem0 = dir0 + '/' + s0
        #START241117
        stem0 = dir0 + '/scripts/' + s0

        str0 = stem0 + '_' + l0 + datestr

        F0 = [str0 + '.sh']
        F1 = str0 + '_fileout.sh'

        if not args.lcfeatadapter and feat: 
            Ffeat = stem0 + '_FEATADAPTER' + datestr + '.sh'
            Ffeatname = '${s0}_FEATADAPTER' + datestr + '.sh' 

        F2 = stem0 + '_bidscp' + datestr + '.sh' 
        F2name = '${s0}_bidscp' + datestr + '.sh'
        F0name = '${s0}_' + l0 + datestr + '.sh'
        Fclean = stem0 + '_cleanup' + datestr + '.sh'

        if args.bs:
            str0 = stem0 + '_OGREbatch' + datestr
            bs0 = str0 + '.sh'

            if not pathlib.Path(bs0).is_file():
                mode0 = 'wt'
            else:
                mode0 = 'at'

            bs1 = str0 + '_fileout.sh'

        if not args.lcfeatadapter:
            par.check_phase_dims()
            if not args.lcsmoothonly: 
                par.check_phase_dims_fmap()
                par.check_ped_dims()

        os.makedirs(pathlib.Path(F0[0]).parent, exist_ok=True)

        from contextlib import ExitStack
        with ExitStack() as fs:
            F0f = [fs.enter_context(open(fn, "w")) for fn in F0]
            F1f = fs.enter_context(open(F1, "w"))
            if args.bs: 
                bs0f = fs.enter_context(open(bs0, mode0))
                bs1f = fs.enter_context(open(bs1, "w"))

            Fcleanf = fs.enter_context(open(Fclean, "w"))

            for fn in F0f: fn.write(f'{gev.SHEBANG}\nset -e\n\n#{' '.join(sys.argv)}\n\n')          

            if not args.lcfeatadapter:
                #F0f[0].write(f'FREESURFDIR={FREESURFDIR}\nFREESURFVER={FREESURFVER}\nexport FREESURFER_HOME='+'${FREESURFDIR}/${FREESURFVER}\n\n')
                F0f[0].write(f'FREESURFDIR={gev.FREESURFDIR}\nFREESURFVER={gev.FREESURFVER}\nexport FREESURFER_HOME='+'${FREESURFDIR}/${FREESURFVER}\n\n')
                F0f[0].write(f'export HCPDIR={gev.HCPDIR}\n\n')

            if not feat:
                if not args.lcfeatadapter:
                    if par.taskidx and (args.fwhm or args.paradigm_hp_sec):
                        F0f[0].write(f'FSLDIR={gev.FSLDIR}\nexport FSLDIR='+'${FSLDIR}\n\n')          
            else:
                feat.write_script(Ffeat,gev)

            fi0=0
            if not args.lcfeatadapter:
                F0f[0].write(f'export OGREDIR={gev.OGREDIR}\n')
                fi0+=1
                if not args.lcsmoothonly: 
                    F0f[0].write('VOLPROC=${OGREDIR}/lib/'+P0+'\n')

                    #START240917
                    #F0f[0].write('GM_WM_CSF=${OGREDIR}/lib/'+P4+'\n')
                    #START241008
                    #F0f[0].write('GM_WM_CSF_LOW=${OGREDIR}/lib/'+P5+'\n')


                if par.taskidx and (args.fwhm or args.paradigm_hp_sec):
                    F0f[0].write('SMOOTH=${OGREDIR}/lib/'+P2+'\n')

            if not args.lcfeatadapter:
                if not args.lcsmoothonly: 
                    F0f[0].write('SETUP=${OGREDIR}/lib/'+SETUP+'\n')
                F0f[0].write('\n')
                pathstr=f's0={s0}\nbids={bids}\nsf0={dir1}\n'
                F0f[0].write(pathstr) # s0, bids and sf0

                if len(F0f)>1: F0f[1].write(f's0={s0}\n')

                if not args.lcsmoothonly: 
                    F0f[0].write('COPY=${sf0}/'+f'{F2name}\n')
                    if feat: F0f[0].write('FEAT=${sf0}/'+f'{Ffeatname}\n')
                    F0f[0].write(f'dilation={args.dilation}\n')

                    F0f[0].write('\nRAW_BOLD=(\\\n')
                    j=-1 #default value needed for a single bold
                    for j in range(len(par.bold)-1): F0f[0].write(f'        {par.bold[j][0]} \\\n')
                    F0f[0].write(f'        {par.bold[j+1][0]})\n')

                    F0f[0].write('\n${VOLPROC} \\\n')
                    F0f[0].write('    --StudyFolder=${sf0} \\\n')
                    F0f[0].write('    --Subject=${s0} \\\n')
                    F0f[0].write('    --runlocal \\\n')
                    F0f[0].write('    --fMRITimeSeries="${RAW_BOLD[*]}" \\\n')
                    if par.sbref:
                        if any(par.bsbref):
                            F0f[0].write('    --fMRISBRef="\\\n')
                            for j in range(len(par.bold)-1): 
                                if par.bsbref[j]: 
                                    F0f[0].write(f'        {par.sbref[j][0]} \\\n')
                                else:
                                    F0f[0].write('        NONE \\\n')
                            if par.bsbref[j+1]: 
                                F0f[0].write(f'        {par.sbref[j+1][0]}" \\\n')
                            else:
                                F0f[0].write('        NONE" \\\n')
                    if par.fmap:
                        if any(par.bfmap):
                            if any(par.bbold_fmap):
                                F0f[0].write('    --SpinEchoPhaseEncodeNegative="\\\n')
                                for j in range(len(par.bold)-1): 
                                    if par.bbold_fmap[j]: 
                                        F0f[0].write(f'        {par.fmap[par.bold[j][1]*2+par.fmapnegidx[par.bold[j][1]]]} \\\n')
                                    else:
                                        F0f[0].write('        NONE \\\n')
                                if par.bbold_fmap[j+1]: 
                                    F0f[0].write(f'        {par.fmap[par.bold[j+1][1]*2+par.fmapnegidx[par.bold[j][1]]]}" \\\n')
                                else:
                                    F0f[0].write('        NONE"\n')
                                F0f[0].write('    --SpinEchoPhaseEncodePositive="\\\n')
                                for j in range(len(par.bold)-1): 
                                    if par.bbold_fmap[j]: 
                                        F0f[0].write(f'        {par.fmap[par.bold[j][1]*2+par.fmapposidx[par.bold[j][1]]]} \\\n')
                                    else:
                                        F0f[0].write('        NONE \\\n')
                                if par.bbold_fmap[j+1]: 
                                    F0f[0].write(f'        {par.fmap[par.bold[j+1][1]*2+par.fmapposidx[par.bold[j][1]]]}" \\\n')
                                else:
                                    F0f[0].write('        NONE"\n')

                    F0f[0].write('    --freesurferVersion=${FREESURFVER} \\\n')
                    if args.userefinement: F0f[0].write('    --userefinement \\\n')
                    F0f[0].write('    --dilation=${dilation} \\\n')
                    if args.startIntensityNormalization: F0f[0].write('    --startIntensityNormalization \\\n')
                    F0f[0].write('    --EnvironmentScript=${SETUP}\n\n')

                    #F0f[0].write('${GM_WM_CSF} ${sf0}\n')
                    #START241008
                    #F0f[0].write('${GM_WM_CSF_LOW} ${sf0}\n')

                if par.taskidx:
                    par.write_copy_script(F2,s0,pathstr,args.fwhm,args.paradigm_hp_sec,gev.FREESURFVER)
                    if not args.lcsmoothonly: F0f[0].write('${COPY}\n\n')
                    par.write_smooth(F0f[0],s0,args.fwhm,args.paradigm_hp_sec)

            if feat: F0f[0].write('${FEAT}\n\n')

            if args.fslmo:
                F0f[0].write('mkdir -p ${bids}/regressors\n\n')
                F0f[0].write(f'OPTIONS="-v {args.fslmo}"\n')
                F0f[0].write('\nfor i in ${RAW_BOLD[@]};do\n')
                F0f[0].write('    if [ ! -f "${i}" ];then\n')
                F0f[0].write('        echo ${i} not found.\n')
                F0f[0].write('        continue\n')
                F0f[0].write('    fi\n')
                F0f[0].write('    root=${i##*/}\n')
                F0f[0].write('    root=${root%.nii*}\n')
                F0f[0].write('    fmospikes=${bids}/regressors/${root}_fmospikes.txt\n')

                #cmd='fsl_motion_outliers -i ${i} -s ${bids}/regressors/${root}_fmovalues.txt -o ${fmospikes} $OPTIONS'
                #START240824
                F0f[0].write('    cmd="fsl_motion_outliers -i ${i} -s ${bids}/regressors/${root}_fmovalues.txt -o ${fmospikes} $OPTIONS"\n')

                #F0f[0].write(f'    echo Running {cmd}\n')
                #START240823
                #F0f[0].write(f'    echo -e "\\nRunning {cmd}"\n')
                #START240824
                F0f[0].write('    echo -e "\\nRunning ${cmd}"\n')

                #F0f[0].write(f'    {cmd}\n')
                #START240824
                F0f[0].write('    ${cmd}\n')

                #F0f[0].write('    if [ ! -f "${fmospikes}" ];then\n')
                #F0f[0].write('        echo ${fmospikes} not found.\n')
                #F0f[0].write('        fmospikes=\n')
                #F0f[0].write('    fi\n')
                #START240823
                F0f[0].write('    [ ! -f "${fmospikes}" ] && unset fmospikes\n')

                F0f[0].write('    paste ${bids}/regressors/${root}_mc.par ${fmospikes} > ${bids}/regressors/${root}_confoundevs.txt\n')
                F0f[0].write('done\n\n')
            else:
                #https://stackoverflow.com/questions/11795181/merging-two-files-horizontally-and-formatting
                F0f[0].write('\nfor i in ${RAW_BOLD[@]};do\n')
                F0f[0].write('    root=${i##*/}\n')
                F0f[0].write('    root=${root%.nii*}\n')
                F0f[0].write('    mcpar=${bids}/regressors/${root}_mc.par\n')
                F0f[0].write('    if [ ! -f "${mcpar}" ];then\n')
                F0f[0].write('        echo ${mcpar} not found.\n')
                F0f[0].write('        continue\n')
                F0f[0].write('    fi\n')
                F0f[0].write('    fmospikes=${bids}/regressors/${root}_fmospikes.txt\n')

                #F0f[0].write('    if [ ! -f "${fmospikes}" ];then\n')
                #F0f[0].write('        echo ${fmospikes} not found.\n')
                #F0f[0].write('        fmospikes=\n')
                #F0f[0].write('    fi\n')
                #START240823
                F0f[0].write('    [ ! -f "${fmospikes}" ] && unset fmospikes\n')


                F0f[0].write('    paste ${mcpar} ${fmospikes} > ${bids}/regressors/${root}_confoundevs.txt\n')
                F0f[0].write('done\n\n')

            #START240806
            F0f[0].write('echo -e "Finshed $0\\nOGRE functional pipeline completed."')


            if not pathlib.Path(F0[0]).is_file():
                for j in F0: pathlib.Path.unlink(j) 
                pathlib.Path.unlink(F1)
                pathlib.Path.unlink(F2) 
                if arg.bs: pathlib.Path.unlink(bs0) 
            else:
                F1f.write(f'{gev.SHEBANG}\nset -e\n\n')
                F1f.write(f'FREESURFVER={gev.FREESURFVER}\ns0={s0}\nsf0={dir2}\n')
                F1f.write('F0=${sf0}/'+f'{F0name}\n'+'out=${F0}.txt\n')
                F1f.write('if [ -f "${out}" ];then\n')
                F1f.write('    echo -e "\\n\\n**********************************************************************" >> ${out}\n')
                F1f.write('    echo "    Reinstantiation $(date)" >> ${out}\n')
                F1f.write('    echo -e "**********************************************************************\\n\\n" >> ${out}\n')
                F1f.write('fi\n')
                F1f.write('cd ${sf0}\n')
                F1f.write('${F0} >> ${out} 2>&1 &\n')
                    
                for j in F0:
                    opl.rou.make_executable(j)
                    print(f'    Output written to {j}')
                opl.rou.make_executable(F1)
                print(f'    Output written to {F1}')
                opl.rou.make_executable(F2)
                print(f'    Output written to {F2}')
                if feat: print(f'    Output written to {Ffeat}')

                if args.bs: 
                    if mode0=='wt': bs0f.write(f'{gev.SHEBANG}\nset -e\n')

                    #bs0f.write(f'\nFREESURFVER={gev.FREESURFVER}\ns0={s0}\nsf0={dir1}\n')
                    #START240802
                    bs0f.write(f'\nFREESURFVER={gev.FREESURFVER}\n{pathstr}')

                    bs0f.write('F0=${sf0}/'+f'{F0name}\n'+'out=${F0}.txt\n')
                    bs0f.write('if [ -f "${out}" ];then\n')
                    bs0f.write('    echo -e "\\n\\n**********************************************************************" >> ${out}\n')
                    bs0f.write('    echo "    Reinstantiation $(date)" >> ${out}\n')
                    bs0f.write('    echo -e "**********************************************************************\\n\\n" >> ${out}\n')
                    bs0f.write('fi\n')
                    bs0f.write('cd ${sf0}\n')
                    bs0f.write('${F0} >> ${out} 2>&1\n') #no ampersand at end
                    opl.rou.make_executable(bs0)
                    print(f'    Output written to {bs0}')
                    bs1f.write(f'{gev.SHEBANG}\n\n')
                    bs1f.write(f'{bs0} >> {bs0}.txt 2>&1 &\n')
                    opl.rou.make_executable(bs1)
                    print(f'    Output written to {bs1}')
                    if 'batchscriptf' in locals(): batchscriptf[0].write(f'{bs0}\n')

                Fcleanf.write(f'{gev.SHEBANG}\n\n')

                #Fcleanf.write(f'FREESURFVER={gev.FREESURFVER}\ns0={s0}\nsf0={dir1}\n\n')
                #Fcleanf.write('rm -rf ${sf0}/MNINonLinear\n')
                #START241103
                Fcleanf.write(f'FREESURFVER={gev.FREESURFVER}\n{pathstr}')
                Fcleanf.write('\nmkdir -p ${sf0}/MNINonLinearSave\n')
                Fcleanf.write('cp -r ${sf0}/MNINonLinear/gm_wm_csf ${sf0}/MNINonLinearSave\n')
                Fcleanf.write('cp -r ${sf0}/MNINonLinear/Results ${sf0}/MNINonLinearSave\n')
                Fcleanf.write('rm -rf ${sf0}/MNINonLinear\n')
                Fcleanf.write('mv ${sf0}/MNINonLinearSave ${sf0}/MNINonLinear\n\n')


                Fcleanf.write('rm -rf ${sf0}/T1w\n')
                Fcleanf.write('rm -rf ${sf0}/T2w\n')
                par.write_bold_bash(Fcleanf,s0,par.bold)
                Fcleanf.write('for i in ${BOLD[@]};do\n')
                Fcleanf.write('    rm -rf ${sf0}/${i}\n')
                Fcleanf.write('done\n\n')
                opl.rou.make_executable(Fclean)
                print(f'    Output written to {Fclean}')

    if 'batchscriptf' in locals(): 
        opl.rou.make_executable(args.bs)
        print(f'    Output written to {args.bs}')
        batchscriptf[1].write(f'{args.bs} >> {args.bs}.txt 2>&1 &\n')
        opl.rou.make_executable(bs_fileout)
        print(f'    Output written to {bs_fileout}')

    print('OGRE functional pipeline setup completed.')

