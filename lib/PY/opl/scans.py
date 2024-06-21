#!/usr/bin/env python3

import re
import pathlib
import json

from opl.rou import run_cmd,SHEBANG

#SHEBANG = "#!/usr/bin/env bash"

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
                #if not os.path.isfile(file0):
                if not pathlib.Path(file0).is_file():
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

    #def write_copy_script(self,file,s0,pathstr,fwhm,paradigm_hp_sec):
    #START240608
    def write_copy_script(self,file,s0,pathstr,fwhm,paradigm_hp_sec,FREESURFVER):

        with open(file,'w') as f0:
            f0.write(f'{SHEBANG}\nset -e\n\n')          
            f0.write(f'FREESURFVER={FREESURFVER}\n\n')
            f0.write(pathstr+'\n') # s0, bids and sf0
            f0.write('mkdir -p ${bids}/func ${bids}/anat\n\n')


            #bold_bash = [i.replace(s0,'${s0}') for i in list(zip(*self.bold))[0]]
            #f0.write('BOLD=(\\\n')
            #for j in range(len(bold_bash)-1):
            #    str0 = pathlib.Path(bold_bash[j]).name.split('.nii')[0]
            #    f0.write(f'    {str0} \\\n')
            #str0 = pathlib.Path(bold_bash[j+1]).name.split('.nii')[0]
            #f0.write(f'    {str0})\n\n')
            #START240608
            self.write_bold_bash(f0,s0,self.bold)


            f0.write('for i in ${BOLD[@]};do\n')
            f0.write('    file=${sf0}/MNINonLinear/Results/${i}/${i}.nii.gz\n')
            f0.write('    if [ ! -f "${file}" ];then\n')
            f0.write('        echo ${file} not found.\n')
            f0.write('        continue\n')
            f0.write('    fi\n')
            f0.write('    cp -f -p $file ${bids}/func/${i%bold*}OGRE-preproc_bold.nii.gz\n')
            f0.write('done\n\n')
            f0.write('for i in ${BOLD[@]};do\n')
            f0.write('    file=${sf0}/MNINonLinear/Results/${i}/brainmask_fs.2.nii.gz\n')
            f0.write('    if [ ! -f "${file}" ];then\n')
            f0.write('        echo ${file} not found.\n')
            f0.write('        continue\n')
            f0.write('    fi\n')
            f0.write('    cp -f -p $file ${bids}/func/${i%bold*}OGRE-preproc_res-2_label-brain_mask.nii.gz\n')
            f0.write('done\n\n')
            f0.write('ANAT=(T1w_restore T1w_restore_brain T2w_restore T2w_restore_brain)\n')
            f0.write('OUT=(OGRE-preproc_desc-restore_T1w OGRE-preproc_desc-restore_T1w_brain OGRE-preproc_desc-restore_T2w OGRE-preproc_desc-restore_T2w_brain)\n')
            f0.write('for((i=0;i<${#ANAT[@]};++i));do\n')
            f0.write('    file=${sf0}/MNINonLinear/${ANAT[i]}.nii.gz\n')
            f0.write('    if [ ! -f "${file}" ];then\n')
            f0.write('        echo ${file} not found.\n')
            f0.write('        continue\n')
            f0.write('    fi\n')
            f0.write('    cp -f -p $file ${bids}/anat/${s0}_${OUT[i]}.nii.gz\n')
            f0.write('done\n')

    def write_smooth(self,f0,s0,fwhm,paradigm_hp_sec):
        f0.write("# --TR= is only needed for high pass filtering --paradigm_hp_sec\n")
        f0.write("# If the files have json's that include the TR as the field RepetitionTime, then --TR= can be omitted.\n")
        f0.write("# Eg. sub-2035_task-drawRH_run-1_OGRE-preproc_bold.json includes the field RepetitionTime.\n")
        f0.write("# Ex.1  6 mm SUSAN smoothing and high pass filtering with a 60s cutoff\n")
        f0.write("#           OGRESmoothingProcess.sh --fMRITimeSeriesResults=sub-2035_task-drawRH_run-1_OGRE-preproc_bold.nii.gz --fwhm=6 --paradigm_hp_sec=60\n")
        f0.write("# Ex.2  6 mm SUSAN smoothing only\n") 
        f0.write("#           OGRESmoothingProcess.sh --fMRITimeSeriesResults=sub-2035_task-drawRH_run-1_OGRE-preproc_bold.nii.gz --fwhm=6\n\n")
        boldtask = [self.bold[j] for j in self.taskidx]


        #bold_bash = [i.replace(s0,'${s0}') for i in list(zip(*boldtask))[0]]
        #f0.write('BOLD=(\\\n')
        #for j in range(len(bold_bash)-1):
        #    str0 = pathlib.Path(bold_bash[j]).name.split('.nii')[0]
        #    f0.write(f'    {str0} \\\n')
        #str0 = pathlib.Path(bold_bash[j+1]).name.split('.nii')[0]
        #f0.write(f'    {str0})\n')
        #START240608
        self.write_bold_bash(f0,s0,boldtask)


        f0.write(f'TR=({' '.join([str(get_TR(self.bold[j][0])) for j in self.taskidx])})\n\n')
        f0.write('for((i=0;i<${#BOLD[@]};++i));do\n')
        f0.write('    file=${bids}/func/${BOLD[i]%bold*}OGRE-preproc_bold.nii.gz\n')
        f0.write('    ${SMOOTH} \\\n')
        f0.write('        --fMRITimeSeriesResults="$file"\\\n')

        #if args.fwhm: f0.write(f'        --fwhm="{' '.join(args.fwhm)}" \\\n')
        #if args.paradigm_hp_sec:
        #    f0.write(f'        --paradigm_hp_sec="{args.paradigm_hp_sec}" \\\n')
        #START240608
        if fwhm: f0.write(f'        --fwhm="{' '.join(fwhm)}" \\\n')
        if paradigm_hp_sec:
            f0.write(f'        --paradigm_hp_sec="{paradigm_hp_sec}" \\\n')



            f0.write('        --TR="${TR[i]}" \n')
        f0.write('done\n\n')

    #START240608
    def write_bold_bash(self,f0,s0,bolds):
        bold_bash = [i.replace(s0,'${s0}') for i in list(zip(*bolds))[0]]
        f0.write('BOLD=(\\\n')
        for j in range(len(bold_bash)-1):
            str0 = pathlib.Path(bold_bash[j]).name.split('.nii')[0]
            f0.write(f'    {str0} \\\n')
        str0 = pathlib.Path(bold_bash[j+1]).name.split('.nii')[0]
        f0.write(f'    {str0})\n')



class Par:
    def __init__(self,lenbold,lenfmap0):
        self.bsbref = [False]*lenbold
        self.ped = []
        self.dim = []
        self.bfmap = [False]*int(lenfmap0/2)
        self.ped_fmap = []
        self.dim_fmap = []
        self.bbold_fmap = []
        self.fmapnegidx = [0]*int(lenfmap0/2)  #j- 0 or 1, for pos subtract 1 and take abs
        self.fmapposidx = [1]*int(lenfmap0/2)  #j+ 0 or 1, for pos subtract 1 and take abs

        #START240615
        self.fmap_bold = [ [] for i in range(lenfmap0)] 


    def __get_phase(self,file):

        #jsonf = file.split('.')[0] + '.json'
        ##if not os.path.isfile(jsonf):
        #if not pathlib.Path(jsonf).is_file():
        #    print(f'    ERROR: {jsonf} does not exist. Abort!')
        #    exit()
        #with open(jsonf,encoding="utf8",errors='ignore') as f0:
        #    dict0 = json.load(f0)
        #return dict0['PhaseEncodingDirection']
        #START240619
        jsonf = (f'{file.split('.nii')[0]}.json')
        try:
            with open(jsonf,encoding="utf8",errors='ignore') as f0:
                dict0 = json.load(f0)
        except FileNotFoundError:
            print(f'    ERROR: __get_phase {jsonf} does not exist. Abort!')
            exit() 
        return dict0['PhaseEncodingDirection']


    def __get_dim(self,file):
        line0 = run_cmd(f'fslinfo {file} | grep -w dim[1-3]')
        line1=line0.split()
        return (line1[1],line1[3],line1[5])


    def check_phase_dims(self,bold,sbref):
        for j in range(len(bold)):
            self.ped.append(self.__get_phase(bold[j]))
            ped0 = self.__get_phase(sbref[j])

            if ped0 != self.ped[j]:
                print(f'    ERROR: {bold[j]} {self.ped[j]}')
                print(f'    ERROR: {sbref[j]} {ped0}')
                print(f'           Phases should be the same. Will not use this SBRef.')
                continue

            self.dim.append(self.__get_dim(bold[j]))
            dim0 = self.__get_dim(sbref[j])
    
            if dim0 != self.dim[j]:
                print(f'    ERROR: {bold[j]} {self.dim[j]}')
                print(f'    ERROR: {sbref[j]} {dim0}')
                print(f'           Dimensions should be the same. Will not use this SBRef.')
                continue

            self.bsbref[j]=True

        #print(f'check_phase_dims bsbref={self.bsbref}')
        #print(f'check_phase_dims ped={self.ped}')
        #print(f'check_phase_dims dim={self.dim}')

    def check_phase_dims_fmap(self,fmap0,fmap1):
        for j in range(len(fmap0)):
            self.ped_fmap.append(self.__get_phase(fmap0[j]))

            #ped0 = self.__get_phase(fmap1[j])
            #START240615
            self.ped_fmap.append(self.__get_phase(fmap1[j]))

            #if ped0[0] != self.ped_fmap[j][0]:
            #    print(f'    ERROR: {fmap0[j]} {self.ped_fmap[j][0]}')
            #    print(f'    ERROR: {fmap1[j]} {ped0[0]}')
            #    print(f'           Fieldmap encoding direction must be the same!')
            #    continue
            #START240615
            if self.ped_fmap[2*j+1][0] != self.ped_fmap[2*j][0]:
                print(f'    ERROR: {fmap0[j]} {self.ped_fmap[2*j][0]}')
                print(f'    ERROR: {fmap1[j]} {self.ped_fmap[2*j+1][0]}')
                print(f'           Fieldmap encoding direction must be the same!')
                continue

            #if ped0 == self.ped_fmap[j]:
            #    print(f'    ERROR: {fmap0[j]} {self.ped_fmap[j]}')
            #    print(f'    ERROR: {fmap1[j]} {ped0}')
            #    print(f'           Fieldmap phases must be opposite!')
            #    continue
            #START240615
            if self.ped_fmap[2*j+1] == self.ped_fmap[2*j]:
                print(f'    ERROR: {fmap0[j]} {self.ped_fmap[2*j]}')
                print(f'    ERROR: {fmap1[j]} {self.ped_fmap[2*j]+1}')
                print(f'           Fieldmap phases must be opposite!')
                continue

            self.dim_fmap.append(self.__get_dim(fmap0[j]))
            dim0 = self.__get_dim(fmap1[j])

            if dim0 != self.dim_fmap[j]:
                print(f'    ERROR: {fmap0[j]} {self.dim_fmap[j]}')
                print(f'    ERROR: {fmap1[j]} {dim0}')
                print(f'           Dimensions must be the same. Will not use these fieldmaps.')
                continue

            self.bfmap[j]=True

            #if self.ped_fmap[j][1] == '+': 
            #START240615
            if self.ped_fmap[2*j][1] == '+': 

                self.fmapnegidx[j]=1
                self.fmapposidx[j]=0

        #print(f'bfmap={self.bfmap}')
        #print(f'ped_fmap={self.ped_fmap}')
        #print(f'dim_fmap={self.dim_fmap}')

    def check_ped_dims(self,bold,fmap):
        self.bbold_fmap=[False]*len(self.ped)

        #print(f'here0 bbold_fmap={self.bbold_fmap}')
        #print(f'here0 len(self.ped)={len(self.ped)}')
        #print(f'here0 len(fmap)={len(fmap)}')


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
                            fmap[i] = fmap0
                    self.bbold_fmap[j]=True

                    #START240615
                    self.fmap_bold[bold[j][1]*2].append(j)
                    self.fmap_bold[bold[j][1]*2+1].append(j)

        #print(f'here1 bbold_fmap={self.bbold_fmap}')
        #print(f'here1 fmap_bold={self.fmap_bold}')

def get_TR(file):
    jsonf = file.split('.')[0] + '.json'
    #if not os.path.isfile(jsonf):
    if not pathlib.Path(jsonf).is_file():
        print(f'    ERROR: {jsonf} does not exist. Abort!')
        #return 'ERROR'
        exit()

    with open(jsonf,encoding="utf8",errors='ignore') as f0:
        dict0 = json.load(f0)

    return dict0['RepetitionTime']
