#!/usr/bin/env python3

import argparse
from datetime import datetime
import glob
import os
import pathlib
import sys
import opl


#**** default global variables **** 

P0='OGREGenericfMRIVolumeProcessingPipelineBatch.sh' 
P1='OGRET1w_restore.sh'
P2='OGRESmoothingProcess.sh'
P3='OGREmakeregdir.sh'
SETUP='OGRESetUpHCPPipeline.sh'

from contextlib import ExitStack
def open_files(filenames,mode):
    #https://www.rath.org/on-the-beauty-of-pythons-exitstack.html
    #https://docs.python.org/3/library/contextlib.html#contextlib.ExitStack
    with ExitStack() as stack:
        files = [stack.enter_context(open(fname,mode)) for fname in filenames]
        stack.pop_all()
        return files

class Feat:
    def __init__(self,arg):
        self.outputdir = []
        self.fsf = []
        #print(f'arg={arg}')
        for i in arg:
            #print(f'i={i}')
            if i[-4:]=='feat':
                #if os.path.isdir(i):
                if pathlib.Path(i).exists():
                    fsf0 = glob.glob(f'{i}/*.fsf')
                    if fsf0:

                        #if len(fsf0)==1:
                        #    line0 = run_cmd(f'grep "set fmri(outputdir)" {fsf0[0]}')
                        #    self.outputdir.append(line0.split('"')[1])
                        #    self.fsf.append(fsf0)
                        #START240514
                        if not pathlib.Path(i).is_file():
                            print(f'{fsf0[0]} does not exist. Abort!')
                            exit()
                        line0 = run_cmd(f'grep "set fmri(outputdir)" {fsf0[0]}')
                        self.outputdir.append(line0.split('"')[1])
                        self.fsf.append(fsf0)


            elif i[-3:]=='fsf':
                if not pathlib.Path(i).is_file():
                    print(f'{i} does not exist. Abort!')
                    exit()
                line0 = run_cmd(f'grep "set fmri(outputdir)" {i}')
                #print(f'line0={line0}')
                #dummy=line0.split('"')[1]
                #print(f'dummy={dummy}')
                self.outputdir.append(line0.split('"')[1])
                self.fsf.append(i)

            #START240514 Can't distinguish between level and 2
            #elif pathlib.Path(i).exists():
            #    fsf0 = glob.glob(f'{i}/*.fsf')
            #    #print(f'fsf0={fsf0}')
            #    for j in fsf0:
            #        #print(f'j={j}')
            #        line0 = run_cmd(f'grep "set fmri(outputdir)" {j}')
            #        self.outputdir.append(line0.split('"')[1])
            #        self.fsf.append(j)

            else:
                with open(i,encoding="utf8",errors='ignore') as f0:
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

                                        #line0 = run_cmd(f'grep "set fmri(outputdir)" {fsf0[0]}')
                                        #self.outputdir.append(line0.split('"')[1])
                                        #START240514
                                        if not pathlib.Path(fsf0[0]).is_file():
                                            print(f'{line1} does not exist. Abort!')
                                            exit()
                                        line2 = run_cmd(f'grep "set fmri(outputdir)" {fsf0[0]}')
                                        self.outputdir.append(line2.split('"')[1])

                                        self.fsf.append(fsf0)
                        elif line1[-3:]=='fsf':

                            #line0 = run_cmd(f'grep "set fmri(outputdir)" {line1}')
                            #self.outputdir.append(line0.split('"')[1])
                            #START240514
                            #print('************* here2 ****************')
                            if not pathlib.Path(line1).is_file():
                                print(f'{line1} does not exist. Abort!')
                                exit()
                            line2 = run_cmd(f'grep "set fmri(outputdir)" {line1}')
                            #print(f'line2={line2}')
                            self.outputdir.append(line2.split('"')[1])

                            self.fsf.append(line1)
        #print(f'self.outputdir={self.outputdir}')
        #print(f'self.fsf={self.fsf}')

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
    parser.add_argument('-V','--VERSION','-VERSION','--FREESURFVER','-FREESURFVER','--freesurferVersion','-freesurferVersion',dest='FREESURFVER',metavar='FreeSurferVersion', \
        help=hFREESURFVER,choices=['5.3.0-HCP', '7.2.0', '7.3.2', '7.4.0', '7.4.1'])

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
    #START240502
    #parser.add_argument('-f','--fwhm',dest='fwhm',metavar=mfwhm,action='extend',nargs='+',help=hfwhm)

    hparadigm_hp_sec='High pass filter cutoff in seconds'
    mparadigm_hp_sec='HPFcutoff'
    #parser.add_argument('-p','--paradigm_hp_sec',dest='paradigm_hp_sec',metavar=mparadigm_hp_sec,help=hparadigm_hp_sec,type=float)
    parser.add_argument('-p','--paradigm_hp_sec',dest='paradigm_hp_sec',metavar=mparadigm_hp_sec,help=hparadigm_hp_sec)

    hlct1copymaskonly='Flag. Only copy the T1w_restore.2 and mask to create T1w_restore_brain.2'
    parser.add_argument('-T','--T1COPYMASKONLY',dest='lct1copymaskonly',action='store_true',help=hlct1copymaskonly)

    hlcsmoothonly='Flag. Only do SUSAN smoothing and high pass filtering.\n' \
        + 'If you want to execute smoothing/filtering on individual runs, edit the .sh run script.'
    parser.add_argument('--smoothonly','-smoothonly','--SMOOTHONLY','-SMOOTHONLY',dest='lcsmoothonly',action='store_true',help=hlcsmoothonly)

    hfsf1='fsf files for first-level FEAT analysis. An OGREmakeregdir call is created for each fsf.'
    #parser.add_argument('-o','-fsf1','--fsf1',dest='fsf1',metavar='*.fsf',action='append',nargs='+',help=hfsf1)
    #START240502
    parser.add_argument('-o','-fsf1','--fsf1',dest='fsf1',metavar='*.fsf',action='extend',nargs='+',help=hfsf1)

    hfsf2='fsf files for second-level FEAT analysis. An OGREmakeregdir call is created for each fsf.'
    #parser.add_argument('-t','-fsf2','--fsf2',dest='fsf2',metavar='*.fsf',action='append',nargs='+',help=hfsf2)
    #START240502
    parser.add_argument('-t','-fsf2','--fsf2',dest='fsf2',metavar='*.fsf',action='extend',nargs='+',help=hfsf2)

    hlcfeatadapter='Flag. Only write the feat adapter scripts.'
    parser.add_argument('-F','--FEATADAPTER','-FEATADAPTER','--featadapter','-featadapter',dest='lcfeatadapter',action='store_true',help=hlcfeatadapter)

    hbs = '*_fileout.sh scripts are collected in an executable batchscript, one for each scanlist.csv.\n' \
        + 'This permits the struct and fMRI scripts to be run sequentially and seamlessly.\n' \
        + 'If a filename is provided, then in addition, the *OGREbatch.sh scripts are written to the provided filename.\n' \
        + 'This permits multiple subjects to be run sequentially and seamlessly.\n'
    parser.add_argument('-b','--batchscript','-batchscript',dest='bs',metavar='batchscript',nargs='?',const=True,help=hbs)

    happend='Append string to pipeline output directory. Ex. -append debug, will result in pipeline7.4.0debug'
    parser.add_argument('-append','--append',dest='append',metavar='mystr',help=happend,default='')

    hnobidscopy='Flag. Do not copy output files from OGRE pipeline directory to bids directories.'
    parser.add_argument('-nobidscopy','--nobidscopy','-nobidscp','--nobidscp',dest='lcnobidscopy',action='store_true',help=hnobidscopy)

    huserefinement='Flag. Use the freesurfer refinement in the warp for one step resampling.\n' \
        + 'Defaut is not use the refinement as this was found to misregister the bolds.\n'
    parser.add_argument('-userefinement','--userefinement','-USEREFINEMENT','--USEREFINEMENT',dest='userefinement',action='store_true',help=huserefinement)

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
            l0 = 'OGREfMRIvol' 
        else: 
            l0 = 'smooth'
    else:
        l0 = 'FEATADAPTER'

    if args.bs:
        if args.bs!=True: #this explicit check is needed!

            #args.bs = os.path.abspath(args.bs)
            args.bs = pathlib.Path(args.bs).resolve()

            if "/" in args.bs: os.makedirs(pathlib.Path(args.bs).resolve().parent,exist_ok=True)
            bs_fileout = args.bs.split('.sh')[0] + '_fileout.sh'
            #print(f'bs_fileout={bs_fileout}')
            batchscriptf = open_files([args.bs,bs_fileout],'w') 
            for i in batchscriptf: i.write(f'{SHEBANG}\n\n')          


    for i in args.dat:

        #print(f'i={i}')  
        #print(f'pathlib.Path(i).parent={pathlib.Path(i).parent}')  
        #os.makedirs(pathlib.Path(i).parent, exist_ok=True)

        print(f'Reading {i}')
        scans = opl.scans.Scans(i)

        #print(f'i={i}')
        #print(f'type(i)={type(i)}')

        idx = i.find('sub-')

        if idx != -1:
            s0 = i[idx: idx + i[idx:].find('/')]
            #print(f's0={s0}')
            #print(f'{s0}')
        

        idx = i.find('raw_data')
        if idx == -1:
            pass
        else:
            #print(i[:idx])

            #dir0 = i[:idx] + 'derivatives/preprocessed/' + s0 + '/pipeline' + FREESURFVER + args.append
            dir0 = i[:idx] + 'derivatives/preprocessed/' + s0 + '/pipeline' + gev.FREESURFVER + args.append
            bids = i[:idx] + 'derivatives/preprocessed/${s0}'
            #dir1 = bids + '/pipeline${FREESURFVER}' + args.append
            dir1 = bids + '/pipeline${gev.FREESURFVER}' + args.append

            #print(f'dir0={dir0}\ndir1={dir1}')

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
        if not args.lcnobidscopy:
            F2 = stem0 + '_bidscp' + datestr + '.sh' 
            F2name = '${s0}_bidscp' + datestr + '.sh'
        F0name = '${s0}_' + l0 + datestr + '.sh'

        #START240607
        Fclean = stem0 + '_cleanup' + datestr + '.sh'

        if args.bs:
            str0 = stem0 + '_OGREbatch' + datestr
            bs0 = str0 + '.sh'

            #if not os.path.isfile(bs0):
            if not pathlib.Path(bs0).is_file():
                mode0 = 'wt'
            else:
                mode0 = 'at'

            bs1 = str0 + '_fileout.sh'

        if not args.lcfeatadapter:

            par = opl.scans.Par(len(scans.bold),int(len(scans.fmap)))
            par.check_phase_dims(list(zip(*scans.bold))[0],list(zip(*scans.sbref))[0])

            #print(f'par.fmapnegidx={par.fmapnegidx}')
            #print(f'par.fmapposidx={par.fmapposidx}')

            if not args.lcsmoothonly and not args.lct1copymaskonly: 
                par.check_phase_dims_fmap(scans.fmap[0::2],scans.fmap[1::2])
                fmap = scans.fmap #if dims don't match bold, fieldmap pairs maybe resampled and new files created
                par.check_ped_dims(scans.bold,fmap)

        os.makedirs(pathlib.Path(F0[0]).parent, exist_ok=True)

        from contextlib import ExitStack
        with ExitStack() as fs:
            F0f = [fs.enter_context(open(fn, "w")) for fn in F0]
            F1f = fs.enter_context(open(F1, "w"))
            if args.bs: 
                bs0f = fs.enter_context(open(bs0, mode0))
                bs1f = fs.enter_context(open(bs1, "w"))

            #START240607
            Fcleanf = fs.enter_context(open(Fclean, "w"))


            #for fn in F0f: fn.write(f'{SHEBANG}\nset -e\n\n#{' '.join(sys.argv)}\n\n')          
            for fn in F0f: fn.write(f'{gev.SHEBANG}\nset -e\n\n#{' '.join(sys.argv)}\n\n')          

            if not args.lcfeatadapter:
                #F0f[0].write(f'FREESURFDIR={FREESURFDIR}\nFREESURFVER={FREESURFVER}\nexport FREESURFER_HOME='+'${FREESURFDIR}/${FREESURFVER}\n\n')
                F0f[0].write(f'FREESURFDIR={gev.FREESURFDIR}\nFREESURFVER={gev.FREESURFVER}\nexport FREESURFER_HOME='+'${gev.FREESURFDIR}/${gev.FREESURFVER}\n\n')
                F0f[0].write(f'export HCPDIR={gev.HCPDIR}\n\n')

            if args.fsf1 or args.fsf2:
                #for fn in F0f: fn.write(f'FSLDIR={FSLDIR}\nexport FSLDIR='+'${FSLDIR}\n\n')          
                for fn in F0f: fn.write(f'FSLDIR={gev.FSLDIR}\nexport FSLDIR='+'${gev.FSLDIR}\n\n')          
            else:
                if not args.lcfeatadapter:
                    if scans.taskidx and not args.lct1copymaskonly and (args.fwhm or args.paradigm_hp_sec):
                        #F0f[0].write(f'FSLDIR={FSLDIR}\nexport FSLDIR='+'${FSLDIR}\n\n')          
                        F0f[0].write(f'FSLDIR={gev.FSLDIR}\nexport FSLDIR='+'${gev.FSLDIR}\n\n')          

            if not args.lcfeatadapter:
                F0f[0].write(f'export OGREDIR={gev.OGREDIR}\n')
                if not args.lcsmoothonly and not args.lct1copymaskonly: 
                    F0f[0].write('P0=${OGREDIR}/lib/'+P0+'\n')
                if not args.lcsmoothonly:
                    F0f[0].write('P1=${OGREDIR}/lib/'+P1+'\n')

                if scans.taskidx and not args.lct1copymaskonly and (args.fwhm or args.paradigm_hp_sec):
                    F0f[0].write('SMOOTH=${OGREDIR}/lib/'+P2+'\n')


            if args.fsf1:
                #if len(F0f)>1:F0f[1].write(f'OGREDIR={OGREDIR}\n')
                #for fn in F0f: fn.write('MAKEREGDIR=${OGREDIR}/lib/'+P3+'\n')          
                for fn in F0f: fn.write(f'OGREDIR={OGREDIR}\n'+'MAKEREGDIR=${OGREDIR}/lib/'+P3+'\n')          

            if not args.lcfeatadapter:

                #F0f[0].write('SETUP=${OGREDIR}/lib/'+SETUP+'\n\n')
                if not args.lcsmoothonly: 
                    F0f[0].write('SETUP=${OGREDIR}/lib/'+SETUP+'\n\n')
                else:
                    F0f[0].write('\n')

                pathstr=f's0={s0}\nbids={bids}\nsf0={dir1}\n'
                F0f[0].write(pathstr+'\n') # s0, bids and sf0
                if len(F0f)>1: F0f[1].write(f's0={s0}\n')
                if not args.lcsmoothonly and not args.lct1copymaskonly: 

                    if not args.lcnobidscopy: F0f[0].write('COPY=${sf0}/'+f'{F2name}\n\n')

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
              
                    if args.userefinement:
                        F0f[0].write('    --userefinement \\\n')

                    F0f[0].write('    --EnvironmentScript=${SETUP}\n\n')


                #if scans.taskidx and not args.lct1copymaskonly and (args.fwhm or args.paradigm_hp_sec): 
                #    scans.write_copy_script(F2,s0,pathstr,args.fwhm,args.paradigm_hp_sec)
                #START240608
                if scans.taskidx and not args.lct1copymaskonly:
                    scans.write_copy_script(F2,s0,pathstr,args.fwhm,args.paradigm_hp_sec,gev.FREESURFVER)


                    #if not args.lcnobidscopy: F0f[0].write('${COPY}\n\n')
                    if not args.lcnobidscopy and not args.lcsmoothonly: F0f[0].write('${COPY}\n\n')

                    scans.write_smooth(F0f[0],s0,args.fwhm,args.paradigm_hp_sec)





            #START240514
            if args.fsf1:
                for fn in F0f: 
                    #for j in feat1.fsf: fn.write('\n${FSLDIR}/bin/feat '+f'{j}')
                    for j in feat1.fsf: fn.write('\n${gev.FSLDIR}/bin/feat '+f'{j}')
                    for j in feat1.outputdir: fn.write('\n${MAKEREGDIR} '+f'{pathlib.Path(j).stem}')
                    fn.write('\n')

            if args.fsf2:
                for fn in F0f: 
                    #for j in feat2.fsf: fn.write('\n${FSLDIR}/bin/feat '+f'{j}')
                    for j in feat2.fsf: fn.write('\n${gev.FSLDIR}/bin/feat '+f'{j}')


            #if not os.path.isfile(F0[0]):
            if not pathlib.Path(F0[0]).is_file():

                #for j in F0: _=run_cmd(f'rm -f {j}')
                #_=run_cmd(f'rm -f {F1}')
                #if not args.lcnobidscopy: _=run_cmd(f'rm -f {F2}')
                #if arg.bs: _=run_cmd(f'rm -f {bs0}')
                #START240515
                for j in F0: pathlib.Path.unlink(j) 
                pathlib.Path.unlink(F1)
                if not args.lcnobidscopy: pathlib.Path.unlink(F2) 
                if arg.bs: pathlib.Path.unlink(bs0) 

            else:

                F1f.write(f'{gev.SHEBANG}\nset -e\n\n')
                F1f.write(f'FREESURFVER={gev.FREESURFVER}\ns0={s0}\nsf0={dir1}\n')
                F1f.write('F0=${sf0}/'+f'{F0name}\n'+'out=${F0}.txt\n')
                F1f.write('if [ -f "${out}" ];then\n')
                F1f.write('    echo -e "\\n\\n**********************************************************************" >> ${out}\n')
                F1f.write('    echo "    Reinstantiation $(date)" >> ${out}\n')
                F1f.write('    echo -e "**********************************************************************\\n\\n" >> ${out}\n')
                F1f.write('fi\n')
                F1f.write('cd ${sf0}\n')
                F1f.write('${F0} >> ${out} 2>&1 &\n')
                    
                for j in F0: 
                    _=opl.rou.run_cmd(f'chmod +x {j}')
                    print(f'    Output written to {j}')
                _=opl.rou.run_cmd(f'chmod +x {F1}')
                print(f'    Output written to {F1}')

                if not args.lcnobidscopy:
                    _=opl.rou.run_cmd(f'chmod +x {F2}')
                    print(f'    Output written to {F2}')

                if args.bs: 
                    if mode0=='wt': bs0f.write(f'{gev.SHEBANG}\nset -e\n')
                    bs0f.write(f'\nFREESURFVER={gev.FREESURFVER}\ns0={s0}\nsf0={dir1}\n')
                    bs0f.write('F0=${sf0}/'+f'{F0name}\n'+'out=${F0}.txt\n')
                    bs0f.write('if [ -f "${out}" ];then\n')
                    bs0f.write('    echo -e "\\n\\n**********************************************************************" >> ${out}\n')
                    bs0f.write('    echo "    Reinstantiation $(date)" >> ${out}\n')
                    bs0f.write('    echo -e "**********************************************************************\\n\\n" >> ${out}\n')
                    bs0f.write('fi\n')
                    bs0f.write('cd ${sf0}\n')
                    bs0f.write('${F0} >> ${out} 2>&1\n') #no ampersand at end

                    _=run_cmd(f'chmod +x {bs0}')
                    print(f'    Output written to {bs0}')

                    bs1f.write(f'{gev.SHEBANG}\n\n')
                    bs1f.write(f'{bs0} >> {bs0}.txt 2>&1 &\n')
                    _=run_cmd(f'chmod +x {bs1}')
                    print(f'    Output written to {bs1}')

                    if 'batchscriptf' in locals(): batchscriptf[0].write(f'{bs0}\n')

                #START240608
                Fcleanf.write(f'{gev.SHEBANG}\n\n')
                Fcleanf.write(f'FREESURFVER={gev.FREESURFVER}\ns0={s0}\nsf0={dir1}\n\n')
                #Fcleanf.write('rm -rf ${sf0}/*/\n')
                Fcleanf.write('rm -rf ${sf0}/MNINonLinear\n')
                Fcleanf.write('rm -rf ${sf0}/T1w\n')
                Fcleanf.write('rm -rf ${sf0}/T2w\n')
                scans.write_bold_bash(Fcleanf,s0,scans.bold)
                Fcleanf.write('for i in ${BOLD[@]};do\n')
                Fcleanf.write('    rm -rf ${sf0}/${i}\n')
                Fcleanf.write('done\n\n')
                _=opl.rou.run_cmd(f'chmod +x {Fclean}')
                print(f'    Output written to {Fclean}')



    if 'batchscriptf' in locals(): 
        _=run_cmd(f'chmod +x {args.bs}')
        print(f'    Output written to {args.bs}')

        batchscriptf[1].write(f'{args.bs} >> {args.bs}.txt 2>&1 &\n')
        _=run_cmd(f'chmod +x {bs_fileout}')
        print(f'    Output written to {bs_fileout}')
