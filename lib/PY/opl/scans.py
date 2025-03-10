#/usr/bin/env python3

import json
import pathlib
import re

#from opl.rou import run_cmd,SHEBANG
#START250307
#from opl.rou import run_cmd
import opl

class Scans:
    def __init__(self,file,lcdonotsmoothrest=False,lcdonotuseIntendedFor=False):

        self.fmap = []
        self.sbref = [] #(filename,scanlist fmap idx, json first fmap idx, json second fmap idx)
        self.bold = []  #(filename,scanlist fmap idx, json first fmap idx, json second fmap idx) #will check PED later
        self.taskidx = []
        self.restidx = []
        self.dwifmap = []
        self.dwi = []
        self.T2 = []

        #START250308
        self.taskflag=[]

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
                    else:
                        self.dwifmap.append(file0)
                elif line2[-2] == 'func':
                    if line2[-1].find('sbref') != -1:
                        self.sbref.append((file0,int(len(self.fmap)/2-1)))
                    else:
                        self.bold.append((file0,int(len(self.fmap)/2-1)))

                        #if lcdonotsmoothrest:
                        #    if line2[-1].find('task-rest') != -1:
                        #        self.restidx.append(j)
                        #    else:
                        #        self.taskidx.append(j)
                        #else:
                        #    self.taskidx.append(j)
                        #START250308
                        if lcdonotsmoothrest:
                            if line2[-1].find('task-rest') != -1:
                                self.restidx.append(j)
                                self.taskflag.append(0)
                            else:
                                self.taskidx.append(j)
                                self.taskflag.append(1)
                        else:
                            self.taskidx.append(j)
                            self.taskflag.append(1)



                        j+=1
                elif line2[-2] == 'dwi':
                    self.dwi.append((file0,int(len(self.dwifmap)-1))) #double parentheses for tuple
                elif line2[-2] == 'anat':
                    if line2[-1].find('T2w') != -1:
                        self.T2.append(file0)

        if len(self.sbref) != len(self.bold):
            print(f'There are {len(self.sbref)} reference files and {len(self.bold)} bolds. Must be equal. Abort!')
            exit()
        #print(f'self.fmap={self.fmap}')
        #print(f'self.sbref={self.sbref}')
        #print(f'self.bold={self.bold}')
        print(f'self.taskidx={self.taskidx}')
        #print(f'self.restidx={self.restidx}')
        #print(f'self.dwifmap={self.dwifmap}')
        #print(f'self.dwi={self.dwi}')
        print(f'self.taskflag={self.taskflag}')

        if not lcdonotuseIntendedFor: self.__check_IntendedFor_fmap()


    #START250110
    def __check_IntendedFor_fmap(self):
        for k in range(len(self.fmap)):
            jsonf = (f'{self.fmap[k].split('.nii')[0]}.json')
            try:
                with open(jsonf,encoding="utf8",errors='ignore') as f0:
                    #print(f'    Loading {jsonf}')
                    dict0 = json.load(f0)
            except FileNotFoundError:
                print(f'    INFO: {jsonf} does not exist.')

            if 'IntendedFor' in dict0:
                #print('        Key IntendedFor found')
                print(f'    {jsonf}: Key "IntendedFor" found')
                #print(f'dict0["IntendedFor"]={dict0["IntendedFor"]}')

                #https://www.geeksforgeeks.org/python-finding-strings-with-given-substring-in-list/
                #https://stackoverflow.com/questions/53984406/efficient-way-to-add-elements-to-a-tuple

                for i in range(len(dict0["IntendedFor"])):
                    found=0
                    for j in range(len(self.bold)):
                        try:
                            index = self.bold[j][0].index(dict0["IntendedFor"][i])
                            #print(f'{i} found at {index}')
                            self.sbref[j] += (k,)
                            self.bold[j] += (k,)
                            found=1
                            break
                        except ValueError:
                            pass
                    #print(f'j={j} len(self.bold)={len(self.bold)}')
                    if found == 0:
                        print(f'{dict0["IntendedFor"][i]} not found in bold. Abort!')
                        exit()

        #print(f'self.sbref={self.sbref}')
        #print(f'self.bold={self.bold}')
        #print(f'len(self.bold)={len(self.bold)}')   


    #def write_copy_script(self,file,s0,pathstr,FREESURFVER):
    #START250307
    def write_copy_script(self,file,s0,pathstr,gev):

        with open(file,'w') as f0:

            #f0.write(f'{SHEBANG}\nset -e\n\n')
            #f0.write(f'FREESURFVER={FREESURFVER}\n\n')
            #START250307
            f0.write(f'{gev.SHEBANG}\nset -e\n\n')
            f0.write(f'FREESURFVER={gev.FREESURFVER}\n\n')

            f0.write(pathstr+'\n') # s0, bids and sf0
            f0.write('mkdir -p ${bids}/func\n\n')
            self.write_bold_bash(f0,s0,self.bold)
            f0.write('\nJSON=(\\\n')
            j=-1 #default value needed for a single bold
            for j in range(len(self.bold)-1): f0.write(f'        {self.bold[j][0].split('.nii')[0]}.json \\\n')
            f0.write(f'        {self.bold[j+1][0].split('.nii')[0]}.json)\n')
            f0.write('\nfor i in "${!BOLD[@]}";do\n')
            f0.write('    file=${sf0}/MNINonLinear/Results/${BOLD[i]}/${BOLD[i]}.nii.gz\n')
            f0.write('    if [ ! -f "${file}" ];then\n')
            f0.write('        echo ${file} not found.\n')
            f0.write('        continue\n')
            f0.write('    fi\n')
            f0.write('    file1=${bids}/func/${BOLD[i]%bold*}OGRE-preproc_bold.nii.gz\n')
            f0.write('    cp -f -p $file ${file1}\n')
            f0.write('    echo -e "${file}\\n    copied to ${file1}"\n')
            f0.write('    OGREjson.py -f "${file1}" -j "${JSON[i]}"\n')
            f0.write('done\n')
            f0.write('\nfor i in "${!BOLD[@]}";do\n')
            f0.write('    file=${sf0}/MNINonLinear/Results/${BOLD[i]}/brainmask_fs.2.nii.gz\n')
            f0.write('    if [ ! -f "${file}" ];then\n')
            f0.write('        echo ${file} not found.\n')
            f0.write('        continue\n')
            f0.write('    fi\n')
            f0.write('    file1=${bids}/func/${BOLD[i]%bold*}OGRE-preproc_res-2_label-brain_mask.nii.gz\n')
            f0.write('    cp -f -p $file ${file1}\n')
            f0.write('    echo -e "${file}\\n    copied to ${file1}"\n')
            f0.write('    OGREjson.py -f "${file1}" -j "${JSON[i]}"\n')
            f0.write('done\n\n')
            f0.write('mkdir -p ${bids}/regressors\n')
            f0.write('MC=(Movement_Regressors.txt Movement_Regressors_dt.txt)\n')
            f0.write('OUT=(mc-withderiv.txt mc-withdetrendderiv.txt)\n')
            f0.write('for i in ${BOLD[@]};do\n')
            f0.write('    file=${sf0}/${i}/MotionCorrection/${i}_mc.par\n')
            f0.write('    if [ ! -f "${file}" ];then\n')
            f0.write('        echo ${file} not found.\n')
            f0.write('    else\n')
            f0.write('        file1=${bids}/regressors/${i}_mc.par\n')
            f0.write('        cp -f -p ${file} ${file1}\n')
            f0.write('        echo -e "${file}\\n    copied to ${file1}"\n')
            f0.write('    fi\n')
            f0.write('    for((j=0;j<${#MC[@]};++j));do\n')
            f0.write('        file=${sf0}/${i}/${MC[j]}\n')
            f0.write('        if [ ! -f "${file}" ];then\n')
            f0.write('            echo ${file} not found.\n')
            f0.write('        else\n')
            f0.write('            file1=${bids}/regressors/${i}_${OUT[j]}\n')
            f0.write('            cp -f -p ${file} ${file1}\n')
            f0.write('            echo -e "${file}\\n    copied to ${file1}"\n')
            f0.write('        fi\n')
            f0.write('    done\n')
            f0.write('done\n')

        #START250307
        opl.rou.make_executable(file)

    def write_smooth(self,f0,s0,fwhm,paradigm_hp_sec):
        f0.write("# --TR= is only needed for high pass filtering --paradigm_hp_sec\n")
        f0.write("# If the files have json's that include the TR as the field RepetitionTime, then --TR= can be omitted.\n")
        f0.write("# Eg. sub-2035_task-drawRH_run-1_OGRE-preproc_bold.json includes the field RepetitionTime.\n")
        f0.write("# Ex.1  6 mm SUSAN smoothing and high pass filtering with a 60s cutoff\n")
        f0.write("#           OGRESmoothingProcess.sh --fMRITimeSeriesResults=sub-2035_task-drawRH_run-1_OGRE-preproc_bold.nii.gz --fwhm=6 --paradigm_hp_sec=60\n")
        f0.write("# Ex.2  6 mm SUSAN smoothing only\n") 
        f0.write("#           OGRESmoothingProcess.sh --fMRITimeSeriesResults=sub-2035_task-drawRH_run-1_OGRE-preproc_bold.nii.gz --fwhm=6\n")
        f0.write("# Edit the BOLD (bash) array below to change which runs are smoothed.\n")
        boldtask = [self.bold[j] for j in self.taskidx]
        self.write_bold_bash(f0,s0,boldtask)
        f0.write('for((i=0;i<${#BOLD[@]};++i));do\n')
        f0.write('    file=${bids}/func/${BOLD[i]%bold*}OGRE-preproc_bold.nii.gz\n')
        f0.write('    ${SMOOTH} \\\n')
        f0.write('        --fMRITimeSeriesResults="$file"\\\n')
        if fwhm: f0.write(f'        --fwhm="{' '.join(fwhm)}" \\\n')
        if paradigm_hp_sec:
            f0.write(f'        --paradigm_hp_sec="{paradigm_hp_sec}" \n')
        f0.write('done\n\n')
    def write_smooth2(self,f0,s0,fwhm,hpf_sec,lpf_sec):
        f0.write("# -TR is only needed for high pass (-hpf_sec) and low pass (-lpf_sec) filtering \n")
        f0.write("# If the file to be filtered has a JSON that includes the TR as the field RepetitionTime, then -TR can be omitted, and the TR is read from the JSON.\n")
        f0.write("# Ex1. sub-2052_task-drawLH_run-1_OGRE-preproc_bold.json includes the field RepetitionTime.\n")
        f0.write("#      6mm SUSAN smoothing and high pass filtering with a 60s cutoff\n")
        f0.write("#           OGRESmoothingProcess2.sh sub-2052_task-drawLH_run-1_OGRE-preproc_bold.nii.gz -fwhm 6 -hpf_sec 60\n")
        f0.write("# Ex2. sub-2052_task-drawLH_run-1_OGRE-preproc_bold.json does not include the field RepetitionTime.\n")
        f0.write("#      6mm SUSAN smoothing and high pass filtering with a 60s cutoff\n")
        f0.write("#           OGRESmoothingProcess2.sh sub-2052_task-drawLH_run-1_OGRE-preproc_bold.nii.gz -fwhm 6 -hpf_sec 60 -TR 0.662\n")
        f0.write("# Edit the BOLD (bash) array below to change which runs are smoothed.\n")
        boldtask = [self.bold[j] for j in self.taskidx]
        self.write_bold_bash(f0,s0,boldtask)
        cmd='${SMOOTH} ${bids}/func/${BOLD[i]%bold*}OGRE-preproc_bold.nii.gz -fwhm '+f'{' '.join(fwhm)}'
        if hpf_sec: cmd+=f' -hpf_sec {hpf_sec}'
        if lpf_sec: cmd+=f' -lpf_sec {lpf_sec}'
        f0.write('for((i=0;i<${#BOLD[@]};++i));do\n'+f'    {cmd}\ndone\n\n')

    #def write_smooth_script(self,file,s0,pathstr,gev,P1,fwhm,hpf_sec,lpf_sec):
    def write_smooth_script(self,file,s0,bids,gev,P1,fwhm,hpf_sec,lpf_sec):
        if not gev:
            gev = opl.rou.get_env_vars(args)
            if not gev: exit()
        with open(file,'w') as f0:
            f0.write(f'{gev.SHEBANG}\nset -e\n\n')
            f0.write(f'FSLDIR={gev.FSLDIR}\nexport FSLDIR='+'${FSLDIR}\n\n')
            f0.write(f'export OGREDIR={gev.OGREDIR}\n')
            f0.write('SMOOTH=${OGREDIR}/lib/'+P1+'\n\n')
            f0.write(f's0={s0}\nbids={bids}\n\nFWHM="{' '.join(fwhm)}"\n')

            if hpf_sec:
                f0.write(f'HPF_SEC="{hpf_sec}"\n')
            else:
                f0.write('HPF_SEC=\n')
            if lpf_sec:
                f0.write(f'LPF_SEC="{lpf_sec}"\n\n')
            else:
                f0.write('LPF_SEC=\n\n')

            #f0.write('\n[[ $FWHM ]] && fwhm="-fwhm $FWHM"\n[[ $HPF_SEC ]] && hpf="-hpf_sec $HPF_SEC"\n[[ $LPF_SEC ]] && lpf="-lpf_sec $LPF_SEC"\n')

            f0.write("# -TR is only needed for high pass (-hpf_sec) and low pass (-lpf_sec) filtering \n")
            f0.write("# If the file to be filtered has a JSON that includes the TR as the field RepetitionTime, then -TR can be omitted, and the TR is read from the JSON.\n")
            f0.write("# Ex1. sub-2052_task-drawLH_run-1_OGRE-preproc_bold.json includes the field RepetitionTime.\n")
            f0.write("#      6mm SUSAN smoothing and high pass filtering with a 60s cutoff\n")
            f0.write("#           OGRESmoothingProcess2.sh sub-2052_task-drawLH_run-1_OGRE-preproc_bold.nii.gz -fwhm 6 -hpf_sec 60\n")
            f0.write("# Ex2. sub-2052_task-drawLH_run-1_OGRE-preproc_bold.json does not include the field RepetitionTime.\n")
            f0.write("#      6mm SUSAN smoothing and high pass filtering with a 60s cutoff\n")
            f0.write("#           OGRESmoothingProcess2.sh sub-2052_task-drawLH_run-1_OGRE-preproc_bold.nii.gz -fwhm 6 -hpf_sec 60 -TR 0.662\n\n")
            #f0.write("# Edit the BOLD (bash) array below to change which runs are smoothed.\n")

            #boldtask = [self.bold[j] for j in self.taskidx]
            #self.write_bold_bash(f0,s0,boldtask)
            #cmd='${SMOOTH} ${bids}/func/${BOLD[i]%bold*}OGRE-preproc_bold.nii.gz -fwhm '+f'{' '.join(fwhm)}'
            #if hpf_sec: cmd+=f' -hpf_sec {hpf_sec}'
            #if lpf_sec: cmd+=f' -lpf_sec {lpf_sec}'
            #f0.write('for((i=0;i<${#BOLD[@]};++i));do\n'+f'    {cmd}\ndone\n\n')
            #START250308
            #for i in self.bold:
            #    b0=f'BOLD={pathlib.Path(i[0]).name.split('.nii')[0]}'
            #    cmd='${SMOOTH} ${bids}/func/${BOLD%bold*}OGRE-preproc_bold.nii.gz -fwhm $FWHM -hpf_sec $HPF_SEC -lpf_sec $LPF_SEC'
            #    f0.write(f'{b0}\n{cmd}\n\n')
            for i,j in enumerate(self.bold):
                cmd=''
                if self.taskflag[i]==0: cmd='#'
                b0=f'BOLD={pathlib.Path(j[0]).name.split('.nii')[0]}'
                cmd+='${SMOOTH} ${bids}/func/${BOLD%bold*}OGRE-preproc_bold.nii.gz -fwhm $FWHM -hpf_sec $HPF_SEC -lpf_sec $LPF_SEC'
                f0.write(f'{b0}\n{cmd}\n\n')

        opl.rou.make_executable(file)


    def write_bold_bash(self,f0,s0,bolds):
        bold_bash = [i.replace(s0,'${s0}') for i in list(zip(*bolds))[0]]
        f0.write('BOLD=(\\\n')
        j=-1 #default value needed for single bold
        for j in range(len(bold_bash)-1):
            str0 = pathlib.Path(bold_bash[j]).name.split('.nii')[0]
            f0.write(f'    {str0} \\\n')
        str0 = pathlib.Path(bold_bash[j+1]).name.split('.nii')[0]
        f0.write(f'    {str0})\n')


class Par(Scans):
    def __init__(self,file,**kwargs):
        super().__init__(file,**kwargs)

        self.bsbref = [False]*len(self.bold)
        self.ped = []
        self.dim = []
        self.bfmap = [False]*int(len(self.fmap)/2)
        self.ped_fmap = []
        self.ped_dwifmap = []
        self.dim_fmap = []
        self.bbold_fmap = []
        self.bdwi_fmap = []
        self.fmapnegidx = [0]*int(len(self.fmap)/2)  #j-

        #self.fmapposidx = [0]*int(len(self.fmap)/2)  #j+ 0 or 1, for pos subtract 1 and take abs
        #START250110 BIG BAD BUG
        self.fmapposidx = [1]*int(len(self.fmap)/2)  #j

        self.fmap_bold = [ [] for i in range(len(self.fmap))]
        self.fmap_dwi = [ [] for i in range(len(self.dwifmap))]

        #print(f'len(self.fmap_bold)={self.fmap_bold}')

    def __get_phase(self,file):
        jsonf = (f'{file.split('.nii')[0]}.json')
        try:
            with open(jsonf,encoding="utf8",errors='ignore') as f0:
                dict0 = json.load(f0)
        except FileNotFoundError:
            print(f'    ERROR: __get_phase {jsonf} does not exist. Abort!')
            exit() 
        return dict0['PhaseEncodingDirection']

    def __get_dim(self,file):

        #line0 = run_cmd(f'fslinfo {file} | grep -w dim[1-3]')
        #START250307
        line0 = opl.rou.run_cmd(f'fslinfo {file} | grep -w dim[1-3]')

        line1=line0.split()
        return (line1[1],line1[3],line1[5])

    def check_phase_dims(self):
        bold = list(zip(*self.bold))[0]
        sbref = list(zip(*self.sbref))[0]

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


    def check_phase_dims_fmap(self):
        fmap0 = self.fmap[0::2]
        fmap1 = self.fmap[1::2]
    
        #print(f'fmap0={fmap0}')
        #print(f'fmap1={fmap1}')
    
        for j in range(len(fmap0)):
            self.ped_fmap.append(self.__get_phase(fmap0[j]))
            self.ped_fmap.append(self.__get_phase(fmap1[j]))
            if self.ped_fmap[2*j+1][0] != self.ped_fmap[2*j][0]:
                print(f'    ERROR: {fmap0[j]} {self.ped_fmap[2*j][0]}')
                print(f'    ERROR: {fmap1[j]} {self.ped_fmap[2*j+1][0]}')
                print(f'           Fieldmap encoding direction must be the same!')
                continue
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
    
            #print(f'self.ped_fmap[{2*j}][1]={self.ped_fmap[2*j][1]}')
            #if self.ped_fmap[2*j][1] == '+': 
            #START250110
            #First field map is 'j' so the second one is 'j-', so flip the index
            if self.ped_fmap[2*j][1] != '-': 
                self.fmapnegidx[j]=1
                self.fmapposidx[j]=0
    
        #print(f'bfmap={self.bfmap}')
        #print(f'ped_fmap={self.ped_fmap}')
        #print(f'dim_fmap={self.dim_fmap}')



    def check_ped_dims(self):
        self.bbold_fmap=[False]*len(self.ped)
        if any(self.bfmap):
            #print(f'self.dim_fmap={self.dim_fmap}')
            for j in range(len(self.ped)):
                if self.bfmap[self.bold[j][1]]:
                    if len(self.bold[0]) == 2:
                        # ped letter bold != ped letter fmap
                        if self.ped[j][0] != self.ped_fmap[self.bold[j][1]][0]:
                            print(f'    ERROR: {self.bold[j][0]} {self.ped[j][0]}')
                            print(f'    ERROR: {self.fmap[self.bold[j][1]*2]} {self.ped_fmap[self.bold[j][1]][0]}')
                            print(f"           Fieldmap encoding direction must be the same! Fieldmap won't be applied.")
                            continue
                        if self.dim[j] != self.dim_fmap[self.bold[j][1]]:
                            print(f'    ERROR: {self.bold[j][0]} {self.dim[j]}')
                            print(f'    ERROR: {self.fmap[self.bold[j][1]*2]} {self.dim_fmap[self.bold[j][1]]}')
                            print(f"           Dimensions must be the same. Fieldmap won't be applied unless it is resampled.")
                            ynq = input('    Would like to resample the field maps? y, n, q').casefold()
                            if ynq=='q' or ynq=='quit' or ynq=='exit': exit()
                            if ynq=='n' or ynq=='no': continue
                            for i in self.bold[j][1]*2,self.bold[j][1]*2+1:
                                fmap0 = pathlib.Path(self.fmap[i]).stem + '_resampled' + 'x'.join(self.dim[j]) + '.nii.gz'

                                #junk = run_cmd(f'{WBDIR}/wb_command -volume-resample {self.fmap[i]} {self.bold[j][0]} CUBIC {fmap0}')
                                junk = opl.rou.run_cmd(f'{WBDIR}/wb_command -volume-resample {self.fmap[i]} {self.bold[j][0]} CUBIC {fmap0}')

                                self.dim_fmap[self.bold[j][1]] = self.dim[j]
                                self.fmap[i] = fmap0
                        self.bbold_fmap[j]=True
                        self.fmap_bold[self.bold[j][1]*2].append(j)
                        self.fmap_bold[self.bold[j][1]*2+1].append(j)
                    else: #len(self.bold[0])==4
                        # ped letter bold != ped letter fmap
                        if self.ped[j][0] != self.ped_fmap[self.bold[j][2]][0]:
                            print(f'    ERROR: {self.bold[j][0]} {self.ped[j][0]}')
                            print(f'    ERROR: {self.fmap[self.bold[j][2]*2]} {self.ped_fmap[self.bold[j][2]][0]}')
                            print(f"           Fieldmap encoding direction must be the same! Fieldmap won't be applied.")
                            continue
                        #print(f'self.bold[{j}][2]={self.bold[j][2]}')
                        #print(f'int(self.bold[{j}][2]/2)={int(self.bold[j][2]/2)}')
                        if self.dim[j] != self.dim_fmap[int(self.bold[j][2]/2)]:
                            print(f'    ERROR: {self.bold[j][0]} {self.dim[j]}')
                            print(f'    ERROR: {self.fmap[self.bold[j][2]*2]} {self.dim_fmap[self.bold[j][2]]}')
                            print(f"           Dimensions must be the same. Fieldmap won't be applied unless it is resampled.")
                            ynq = input('    Would like to resample the field maps? y, n, q').casefold()
                            if ynq=='q' or ynq=='quit' or ynq=='exit': exit()
                            if ynq=='n' or ynq=='no': continue
                            for i in self.bold[j][2],self.bold[j][3]:
                                fmap0 = pathlib.Path(self.fmap[i]).stem + '_resampled' + 'x'.join(self.dim[j]) + '.nii.gz'

                                #junk = run_cmd(f'{WBDIR}/wb_command -volume-resample {self.fmap[i]} {self.bold[j][0]} CUBIC {fmap0}')
                                #START250307
                                junk = opl.rou.run_cmd(f'{WBDIR}/wb_command -volume-resample {self.fmap[i]} {self.bold[j][0]} CUBIC {fmap0}')

                                self.dim_fmap[self.bold[j][1]] = self.dim[j]
                                self.fmap[i] = fmap0
                        self.bbold_fmap[j]=True
                        self.fmap_bold[self.bold[j][2]].append(j)
                        self.fmap_bold[self.bold[j][3]].append(j)


    def check_ped_dims_dwi(self):
        self.bdwi_fmap=[False]*len(self.dwi)
        for j in range(len(self.dwi)):
            #print(f'check_ped_dims_dwi here0 j={j}')
            ped_dwi = self.__get_phase(self.dwi[j][0])
            ped_dwifmap = self.__get_phase(self.dwifmap[self.dwi[j][1]])
            #print(f'check_ped_dims_dwi {self.dwi[j][0]} {ped_dwi}')
            #print(f'check_ped_dims_dwi {self.dwifmap[self.dwi[j][1]]} {ped_dwifmap}')
            if ped_dwi[0] != ped_dwifmap[0]:
                print(f'    ERROR: {self.dwi[j][0]} {ped_dwi}')
                print(f'    ERROR: {self.dwifmap[self.dwi[j][1]]} {ped_dwifmap}')
                print(f"           Fieldmap encoding direction must be the same! Fieldmap won't be applied.")
                continue
            dim_dwi = self.__get_dim(self.dwi[j][0])
            dim_dwifmap = self.__get_dim(self.dwifmap[self.dwi[j][1]])
            if dim_dwi != dim_dwifmap:
                print(f'    ERROR: {self.dwi[j][0]} {dim_dwi}')
                print(f'    ERROR: {self.dwifmap[self.dwi[j][1]]} {dim_dwifmap}')
                print(f"           Dimensions must be the same. Fieldmap won't be applied unless it is resampled.")
                ynq = input('    Would like to resample the field maps? y, n, q').casefold()
                if ynq=='q' or ynq=='quit' or ynq=='exit': exit()
                if ynq=='n' or ynq=='no': continue
                fmap0 = pathlib.Path(self.dwifmap[self.dwi[j][1]]).stem + '_resampled' + 'x'.join(dim_dwi) + '.nii.gz'

                #junk = run_cmd(f'{WBDIR}/wb_command -volume-resample {self.dwifmap[self.dwi[j][1]]} {self.dwi[j][0]} CUBIC {fmap0}')
                #START250307
                junk = opl.rou.run_cmd(f'{WBDIR}/wb_command -volume-resample {self.dwifmap[self.dwi[j][1]]} {self.dwi[j][0]} CUBIC {fmap0}')

                self.dwifmap[self.dwi[j][1]] = fmap0
            self.bdwi_fmap[j]=True
            self.fmap_dwi[self.dwi[j][1]].append(j)
            self.ped_dwifmap.append(ped_dwifmap)


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
