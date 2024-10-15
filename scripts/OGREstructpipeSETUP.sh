#!/usr/bin/env bash

shebang="#!/usr/bin/env bash"

#Hard coded location of freesurfer installations
[ -z ${FREESURFDIR+x} ] && FREESURFDIR=/Applications/freesurfer

#Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2 7.4.0 7.4.1
[ -z ${FREESURFVER+x} ] && FREESURFVER=7.4.1

#Hard coded HCP batch scripts
PRE=OGREPreFreeSurferPipelineBatch.sh
FREE=OGREFreeSurferPipelineBatch.sh
POST=OGREPostFreeSurferPipelineBatch.sh
SETUP=OGRESetUpHCPPipeline.sh
MASKS=OGRESplitFreeSurferMasks.sh

#Resolution. MNI152  options: 1, 0.7 or 0.8
#            mni_sym options: 1, 0.7, 0.8 #or 0.5
Hires=1

T1SEARCHSTR=T1w
T2SEARCHSTR=T2w

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

root0=${0##*/}
helpmsg(){
    echo "Required: ${root0} <scanlist.csv file(s)>"
    echo "    -s --scanlist -scanlist"
    echo "        scanlist.csv file(s). Arguments without options are assumed to be scanlist.csv files."
    echo "        Two columns. First column identifies the dicom directory. Second column is the output name of the nifti."
    echo "        Columns may be separated by commas, spaces and/or tabs."
    echo "        Ex. 7,/Users/Shared/10_Connectivity/raw_data/sub-2035/anat/sub-2035_t1_mpr_1mm_p2_pos50"
    echo "            8,/Users/Shared/10_Connectivity/raw_data/sub-2035/fmap/sub-2035_SpinEchoFieldMap2_AP-1"
    echo "            9,/Users/Shared/10_Connectivity/raw_data/sub-2035/fmap/sub-2035_SpinEchoFieldMap2_PA-1"
    echo "            10,/Users/Shared/10_Connectivity/raw_data/sub-2035/func/sub-2035_task-drawRH_run-1_SBRef"
    echo "            11,/Users/Shared/10_Connectivity/raw_data/sub-2035/func/sub-2035_task-drawRH_run-1"
    echo "    -A --autorun -autorun --AUTORUN -AUTORUN"
    echo "        Flag. Automatically execute *_fileout.sh script. Default is to not execute."
    echo "    -O --OGREDIR -OGREDIR --ogredir -ogredir"
    echo "        OGRE directory. Location of OGRE software package (e.g. ~/GitHub/OGRE-pipeline)."
    echo "        Defaults to variable OGREDIR if set elsewhere. If set in both places, this one overrides."
    echo "        NOTE: you must either set -O or the variable OGREDIR."
    echo "    -H --HCPDIR -HCPDIR --hcpdir -hcpdir"
    echo "        HCP directory. Optional; default location is OGREDIR/lib/HCP"
    echo "    -V --VERSION -VERSION --FREESURFVER -FREESURFVER --freesurferVersion -freesurferVersion"
    echo "        5.3.0-HCP, 7.2.0, 7.3.2, 7.4.0 or 7.4.1. Default is 7.4.1 unless set elsewhere via variable FREESURFVER."
    echo "    -m --HOSTNAME"
    echo "        Flag. Append machine name to pipeline directory. Ex. pipeline7.4.0_3452-AD-05003"
    echo "    -D --DATE -DATE --date -date"
    echo "        Flag. Add date (YYMMDD) to name of output script."
    echo "    -DL --DL --DATELONG -DATELONG --datelong -datelong"
    echo "        Flag. Add date (YYMMDDHHMMSS) to name of output script."
    echo "    -b --batchscript -batchscript"
    echo "        *_fileout.sh scripts are collected in an executable batchscript, one for each scanlist.csv."
    echo "        This permits the struct and fMRI scripts to be run sequentially and seamlessly."
    echo "        If a filename is provided, then in addition, the *OGREbatch.sh scripts are written to the provided filename (an across-subjects script)."
    echo "        This across-subjects script permits multiple subjects to be run sequentially and seamlessly."
    echo "    -e --erosion -erosion --ero -ero"
    echo "        Default is 2. For the brain mask, the number or erosions that follow the three dilations. Ex. -e 2, will result in two erosions"
    echo "        See OGRE-pipeline/lib/OGREFreeSurfer2CaretConvertAndRegisterNonlinear.sh"
    echo "    -dil --dil -dilation --dilation"
    echo "        Default is 3. For the brain mask, the number of dilations (fslmaths dilD) before erosions"
    echo "    -ht --ht --highres-template -highres-template"
    echo "        Optional. High resolution registration templates. Default is MNI152 1mm asymmetric (HCP/FSL version)"
    echo "        Full path of a folder containing 4 files: T1w, T1w_brain and/or T1_brain_mask, T2w, T2w_brain (brain_mask may be used instead of _brain)"
    echo "        e.g. $OGREDIR/lib/templates/mni-hcp_asym_1mm/"
    echo "    -lt --lt --lowres-template -lowres-template"
    echo "        Optional. Low resolution registration templates. Default is MNI152 2mm asymmetric (HCP/FSL version)"
    echo "        Full path of a folder containing 4 files: T1w, T1w_brain or T1w_brain_mask, T2w (brain_mask may be used instead of _brain)"
    echo '        If T1w_brain_mask does not include "dil" in its name, then it is dilated.'
    echo "        e.g. $OGREDIR/lib/templates/mni-hcp_asym_2mm/"

    #echo "    -n --name -name"
    #echo "        Use with -pipedir to provide the subject name. Default is root of scanlist.csv."
    #echo "    -d -p -directory --directory --pipedir -pipedir"
    #echo "        OGRE pipeline output directory. Output of OGRE scripts will be written to this location at pipeline<freesurferVersion>."
    #echo "        Optional. Default is <scanlist.csv path>."
    #echo "    --append -append"
    #echo "        Append string to pipeline output directory. Ex. -append debug, will result in pipeline7.4.1debug. Overridden by -d."
    #START240813
    echo "    --container_directory -container_directory --cd -cd"
    echo "        Ex. /Users/Shared/10_Connectivity/derivatives/preprocessed/sub-1019_OGRE-preproc"
    echo "            func, anat, regressors, pipeline7.4.1 are created inside this directory"
    echo "    -n --name -name"
    echo "        Use with --container_directory to provide the subject name. Default is root of scanlist.csv."

    if [ -z "$1" ];then
        echo "    --helpall -helpall"
        echo "        Show all options."
    else
        echo "    -r --hires -hires"
        echo "        Resolution. Should match that for the structural pipeline. options : 0.7, 0.8 or 1mm. Default is 1mm."
        echo "    -T1 --T1 -t1 --t1" 
        echo "        Default is MNI152_T1_${hires}mm.nii.gz. This will overwrite -ht."
        echo "    -T1brain --T1brain -t1brain --t1brain -t1b --t1b -T1b --T1b" 
        echo "        Default is MNI152_T1_${hires}mm_brain.nii.gz. This will overwrite -ht."
        echo "    -T1low --T1low -t1low --t1low -t1l --t1l -T1l --T1l" 
        echo "        Default is MNI152_T1_2mm.nii.gz. This will overwrite -lt."
        echo "    -T2 --T2 -t2 --t2" 
        echo "        Default is MNI152_T2_${hires}mm.nii.gz. This will overwrite -ht."
        echo "    -T2brain --T2brain -t2brain --t2brain -t2b --t2b -T2b --T2b" 
        echo "        Default is MNI152_T2_${hires}mm_brain.nii.gz. This will overwrite -ht."
        echo "    -T2low --T2low -t2low --t2low -t2l --t2l -T2l --T2l" 
        echo "        Default is MNI152_T2_2mm.nii.gz. This will overwrite -lt."
        echo "    -T1brainmask --T1brainmask -t1brainmask --t1brainmask -t1bm --t1bm -T1bm --T1bm" 
        echo "        Default is MNI152_T1_${hires}mm_brain_mask.nii.gz. This will overwrite -ht."
        echo "    -T1brainmasklow --T1brainmasklow -t1brainmasklow --t1brainmasklow -t1bml --t1bml -T1bml --T1bml" 
        echo "        Default is MNI152_T1_2mm_brain_mask_dil.nii.gz. This will overwrite -lt."
        echo '        Mask is dilated if name does not include "dil".'
    fi
    echo "    -h --help -help"
    echo "        Echo this help message."
    }
if((${#@}<1));then
    helpmsg
    exit
fi

lcautorun=0;lchostname=0;lcdate=0;erosion=2;dilation=3 #do not set dat;unexpected
unset bs cd0 name helpall help t1 t1b t1l t2 t2b t2l t1bm t1bml ht lt
unset T1wTemplate T1wTemplateBrain T1wTemplateLow T2wTemplate T2wTemplateBrain T2wTemplateLow TemplateMask TemplateMaskLow 

arg=("$@")
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -s | --scanlist | -scanlist)
            dat+=(${arg[((++i))]})
            for((j=i;j<${#@};++i));do #i is incremented only if dat is appended
                dat0=(${arg[((++j))]})
                [ "${dat0::1}" = "-" ] && break
                dat+=(${dat0[@]})
            done
            ;;
        -A | --autorun | -autorun | --AUTORUN | -AUTORUN)
            lcautorun=1
            echo "lcautorun=$lcautorun"
            ;;
        -O | --OGREDIR | -OGREDIR | --ogredir | -ogredir)
            OGREDIR=${arg[((++i))]}
            #echo "OGREDIR=$OGREDIR"
            ;;
        -H | --HCPDIR | -HCPDIR | --hcpdir | -hcpdir)
            HCPDIR=${arg[((++i))]}
            echo "HCPDIR=$HCPDIR"
            ;;
        -V | --VERSION | -VERSION | --FREESURFVER | -FREESURFVER | --freesurferVersion | -freesurferVersion)
            FREESURFVER=${arg[((++i))]}
            #echo "FREESURFVER=$FREESURFVER"
            ;;
        -m | --HOSTNAME)
            lchostname=1
            echo "lchostname=$lchostname"
            ;;
        -D | --DATE | -DATE | --date | -date)
            lcdate=1
            #echo "lcdate=$lcdate"
            ;;
        -DL | --DL | --DATELONG | -DATELONG | --datelong | -datelong)
            lcdate=2
            echo "lcdate=$lcdate"
            ;;
        -b | --batchscript | -batchscript)
            bs=True
            ((((i+i))<${#@})) && [[ ${arg[i+1]:0:1} != "-" ]] && bs=${arg[((++i))]}
            #echo "bs=$bs"
            ;;
        -e | --erosion | -erosion | --ero | -ero)
            erosion=${arg[((++i))]}
            echo "erosion=$erosion"
            ;;
        -dil | --dilation | -dilation | --dil)
            dilation=${arg[((++i))]}
            echo "dilation=$dilation"
            ;;
        -ht | --ht | --highres-template | -highres-template)
            ht=${arg[((++i))]}
            echo "ht=$ht"
            ;;
        -lt | --lt | --lowres-template | -lowres-template)
            lt=${arg[((++i))]}
            echo "lt=$lt"
            ;;
        --helpall | -helpall)
            helpall=True
            #echo "helpall=$helpall"
            ;;
        -r | --hires | -hires)
            Hires=${arg[((++i))]}
            echo "Hires=$Hires"
            ;;
        -T1 | --T1 | -t1 | --t1)
            t1=${arg[((++i))]}
            ;;
        -T1brain | --T1brain | -t1brain | --t1brain | -t1b | --t1b | -T1b | --T1b)
            t1b=${arg[((++i))]}
            ;;
        -T1low | --T1low | -t1low | --t1low | -t1l | --t1l | -T1l | --T1l)
            t1l=${arg[((++i))]}
            ;;
        -T2 | --T2 | -t2 | --t2)
            t2=${arg[((++i))]}
            ;;
        -T2brain | --T2brain | -t2brain | --t2brain | -t2b | --t2b | -T2b | --T2b)
            t2b=${arg[((++i))]}
            ;;
        -T2low | --T2low | -t2low | --t2low | -t2l | --t2l | -T2l | --T2l)
            t2l=${arg[((++i))]}
            ;;
        -T1brainmask | --T1brainmask | -t1brainmask | --t1brainmask | -t1bm | --t1bm | -T1bm | --T1bm)
            t1bm=${arg[((++i))]}
            ;;
        -T1brainmasklow | --T1brainmasklow | -t1brainmasklow | --t1brainmasklow | -t1bml | --t1bml | -T1bml | --T1bml)
            t1bml=${arg[((++i))]}
            ;;

        #-p | --pipedir | -pipedir | -d | -directory | --directory)
        #    pipedir=${arg[((++i))]}
        #    #https://stackoverflow.com/questions/17542892/how-to-get-the-last-character-of-a-string-in-a-shell
        #    #https://stackoverflow.com/questions/27658675/how-to-remove-last-n-characters-from-a-string-in-bash
        #    [[ ${pipedir: -1} == "/" ]] && pipedir=${pipedir::-1}
        #    echo "pipedir=$pipedir"
        #    ;;
        #--append | -append)
        #    append=${arg[((++i))]}
        #    echo "append=$append"
        #    ;;
        #-n | --name | -name)
        #    name=${arg[((++i))]}
        #    echo "name=$name"
        #    ;;
        #START240813
        -p | --pipedir | -pipedir | -d | -directory | --directory)
            echo ${arg[i]} is archaic. Use --container_directory instead.
            exit
            ;;
        --append | -append)
            echo ${arg[i]} is archaic. Use --container_directory instead.
            exit
            ;;
        --container_directory | -container_directory | --cd | -cd)
            cd0=${arg[((++i))]}
            #echo cd0=${cd0}
            ;;
        -n | --name | -name)
            name=${arg[((++i))]}
            echo "name=$name"
            ;;


        -h | --help | -help)
            #helpmsg
            #exit
            help=True
            ;;
        *) unexpected+=(${arg[i]})
            ;;
    esac
done
if [[ -n "$help" || -n "$helpall" ]];then
    helpmsg $helpall
    exit
fi

echo $0 $@

if [ -z "${OGREDIR}" ];then
    echo "OGREDIR not set. Abort!"
    echo "Before calling this script: export OGREDIR=<OGRE directory>"
    echo "or via an option to this script: -OGREDIR <OGRE directory>"
    exit
fi
#echo "OGREDIR=$OGREDIR"

#if HCPDIR unset, use default location (this is down here b/c needs $OGREDIR)
[ -z ${HCPDIR+x} ] && HCPDIR=$OGREDIR/lib/HCP

[ -n "${unexpected}" ] && dat+=(${unexpected[@]})
if [ -z "${dat}" ];then
    echo "Need to provide dat file"
    exit
fi

#START240727
if((${#dat[@]}>1));then
    echo Only a single scanlist.csv file is accepted. Abort!
    echo "    ${dat[@]}"
    exit
fi

#echo "dat[@]=${dat[@]}"
#echo "#dat[@]=${#dat[@]}"

lcsinglereconall=0;lctworeconall=0

if [[ "${FREESURFVER}" != "5.3.0-HCP" && "${FREESURFVER}" != "7.2.0" && "${FREESURFVER}" != "7.3.2" && "${FREESURFVER}" != "7.4.0" && "${FREESURFVER}" != "7.4.1" ]];then
    echo "Unknown version of freesurfer. FREESURFVER=${FREESURFVER}"
    exit
fi
[[ "${FREESURFVER}" = "7.2.0" || "${FREESURFVER}" = "7.3.2" || "${FREESURFVER}" = "7.4.0" || "${FREESURFVER}" = "7.4.1" ]] && lctworeconall=1

if [ -n "${bs}" ];then
    if [[ "${bs}" != True ]];then
        [[ $bs == *"/"* ]] && mkdir -p ${bs%/*}
        #https://stackoverflow.com/questions/284662/how-do-you-normalize-a-file-path-in-bash
        #bs=$(realpath ${bs}) # cut this 240425 - this required the file to already exist, which it shouldn't b/c this is a new file.
        bs_fileout=${bs%.sh*}_fileout.sh  #everything before .sh
        echo bs_fileout=${bs_fileout}
        [[ ! -f ${bs} ]] && echo -e "$shebang\n" > $bs
        [[ ! -f ${bs_fileout} ]] && echo -e "$shebang\n" > $bs_fileout
    fi
fi

echo "Reading ${dat}"
sed -i '' $'s/\r$//' ${dat}
unset T1f T2f
cnt=0
#https://stackoverflow.com/questions/24537483/bash-loop-to-get-lines-in-a-file-skipping-comments-and-blank-lines
#https://mywiki.wooledge.org/BashFAQ/024
while IFS=$'\t, ' read -ra line; do
    if [[ "${line[1]}" == *"${T1SEARCHSTR}"* ]];then
        T1f=${line[1]}
        ((cnt++))
    elif [[ "${line[1]}" == *"${T2SEARCHSTR}"* ]];then
        T2f=${line[1]}
        ((cnt++))
    fi
    ((cnt==2)) && break
done < <(grep -vE '^(\s*$|#)' ${dat})

if [ -z "${T1f}" ];then
    echo -e "    T1 not found with searchstr = \"${T1SEARCHSTR}\" Abort!"
    exit 
else
    T1f+=.nii.gz 
    if [ ! -f "$T1f" ];then
        echo "    ${T1f} not found. Abort!"
        exit
    fi
fi
if [ -z "${T2f}" ];then 
    echo -e "    WARNING: T2 not found with searchstr = \"${T2SEARCHSTR}\""
else
    T2f+=.nii.gz 
    if [ ! -f "$T2f" ];then
        echo "    WARNING: ${T2f} not found."
        unset T2f
    fi
fi

datf=$(realpath ${dat[0]})
dir0=${datf%/*}
IFS='/' read -ra subj <<< "${dir0}"
s0=${subj[${#subj[@]}-1]}
if [ -z "${cd0}" ];then
    T1f=${T1f//${s0}/'${s0}'}
    T2f=${T2f//${s0}/'${s0}'}
    if ! [[ $(echo ${subj[@]} | fgrep -w "raw_data") ]];then
        dir0=/$(join_by / ${subj[@]::${#subj[@]}-1})/${s0}/pipeline${FREESURFVER}
        dir1=/$(join_by / ${subj[@]::${#subj[@]}-1})/'${s0}'/pipeline'${FREESURFVER}'
    else
        for j in "${!subj[@]}";do
            if [[ "${subj[j]}" = "raw_data" ]];then
                dir0=/$(join_by / ${subj[@]::j})/derivatives/preprocessed/${s0}/pipeline${FREESURFVER}
                dir1=/$(join_by / ${subj[@]::j})/derivatives/preprocessed/'${s0}'/pipeline'${FREESURFVER}'
                break
            fi
        done
    fi
else
    dir0=${cd0}/pipeline${FREESURFVER}
    dir1=${cd0}/pipeline'${FREESURFVER}'
fi




[ -n "$name" ] && s0=$name
if((lchostname==1));then
    dir0+=_$(hostname)
    dir1+=_'$(hostname)'
fi
mkdir -p ${dir0}
datestr=''
if((lcdate==1));then
    datestr=_$(date +%y%m%d)
elif((lcdate==2));then
    datestr=_$(date +%y%m%d%H%M%S)
fi
F0stem=${dir0}/${s0}_OGREstruct${datestr} 
F0=${F0stem}.sh
F1=${F0stem}_fileout.sh
F0name='${s0}'_OGREstruct${datestr}.sh

if [ -n "${bs}" ];then
    bs0stem=${dir0}/${s0}_OGREbatch${datestr} 
    bs0=${bs0stem}.sh
    echo -e "$shebang\nset -e\n" > ${bs0} 
    bs1=${bs0stem}_fileout.sh
    echo -e "$shebang\nset -e\n" > ${bs1} 
fi

if [[ -n "$ht" || -n "$lt" ]];then
    if [[ -z "$ht" ]];then
        echo You have only provided -lt. -ht is also required. Abort!
        exit
    fi
    if [[ -z "$lt" ]];then
        echo You have only provided -ht. -lt is also required. Abort!
        exit
    fi
    for i in $ht/*;do
        if [[ "$i" == *"T1w.nii.gz" ]];then
            T1wTemplate=$i
        elif [[ "$i" == *"T1w_brain.nii.gz" ]];then
            T1wTemplateBrain=$i
        elif [[ "$i" == *"T1w_brain_mask"* ]];then # .nii.gz excluded to allow "dil" at end
            TemplateMask=$i
        elif [[ "$i" == *"T2w.nii.gz" ]];then
            T2wTemplate=$i
        elif [[ "$i" == *"T2w_brain.nii.gz" ]];then
            T2wTemplateBrain=$i
        elif [[ "$i" == *"T2w_brain_mask.nii.gz" ]];then
            T2wTemplateMask=$i
        else
            echo Ignoring $i
            continue
        fi
        echo Fetching $i
    done
    for i in $lt/*;do
        if [[ "$i" == *"T1w.nii.gz" ]];then
            T1wTemplateLow=$i
        elif [[ "$i" == *"T1w_brain_mask.nii.gz" ]];then
            TemplateMaskLow=$i
            #TemplateMaskLowUndil=$i
        elif [[ "$i" == *"T2w.nii.gz" ]];then
            T2wTemplateLow=$i
        else
            echo Ignoring $i
            continue
        fi
        echo Fetching $i
    done
    if [[ -z "$T1wTemplate" ]];then
        echo T1wTemplate not provided. Abort!
        exit
    fi
    if [[ -z "$T1wTemplateBrain" && -z "$TemplateMask" ]];then
        echo T1wTemplateBrain and TemplateMask not provided. One is needed to compute the other. Abort!
        exit
    fi
    if [[ -z "$T1wTemplateBrain" ]];then
        mkdir -p ${dir0}/templates
        T1wTemplateBrain=${T1wTemplate##*/}
        T1wTemplateBrain=${dir0}/templates/${T1wTemplateBrain%%.nii.gz}_brain.nii.gz
        #fslmaths HEAD -mas MASK BRAIN
        fslmaths $T1wTemplate -mas $TemplateMask $T1wTemplateBrain
    fi
    if [[ -z "$TemplateMask" ]];then
        mkdir -p ${dir0}/templates
        TemplateMask=${T1wTemplate##*/}
        TemplateMask=${dir0}/templates/${TemplateMask%%.nii.gz}_brain_mask.nii.gz
        #fslmaths BRAIN -bin MASK
        fslmaths $T1wTemplateBrain -bin $TemplateMask
    fi

    if [[ -z "$T1wTemplateLow" ]];then
        echo T1wTemplateLow not provided. Abort!
        exit
    fi
    if [[ -z "$TemplateMaskLow" ]];then
        echo TemplateMaskLow not provided. Abort!
        exit
    fi

    if [ -n "${T2f}" ];then
        if [[ -z "$T2wTemplate" ]];then
            echo T2wTemplate not provided. Abort!
            exit
        fi
        if [[ -z "$T2wTemplateBrain" ]];then
            if [[ -z "$T2wTemplateMask" ]];then
                echo T2wTemplateMask is needed to create T2wTemplateBrain. Abort!
                exit
            fi
            mkdir -p ${dir0}/templates
            T2wTemplateBrain=${T2wTemplate##*/}
            T2wTemplateBrain=${dir0}/templates/${T2wTemplate%%.nii.gz}_brain.nii.gz
            #fslmaths HEAD -mas MASK BRAIN
            fslmaths $T2wTemplate -mas $T2wTemplateMask $T2wTemplateBrain
        fi
        if [[ -z "$T2wTemplateLow" ]];then
            echo T2wTemplateLow not provided. Abort!
            exit
        fi
    fi

else
    ## Hires T1w MNI template
    HCPPIPEDIR_Templates=${OGREDIR}/lib/HCP/HCPpipelines-3.27.0/global/templates
    T1wTemplate="${HCPPIPEDIR_Templates}/MNI152_T1_${Hires}mm.nii.gz"
    ## Hires brain extracted MNI template
    T1wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T1_${Hires}mm_brain.nii.gz"
    ## Lowres T1w MNI template
    T1wTemplateLow="${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz"
    ## Hires T2w MNI Template
    T2wTemplate="${HCPPIPEDIR_Templates}/MNI152_T2_${Hires}mm.nii.gz"
    ## Hires T2w brain extracted MNI Template
    T2wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T2_${Hires}mm_brain.nii.gz"
    ## Lowres T2w MNI Template
    T2wTemplateLow="${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz"
    ## Hires MNI brain mask template
    TemplateMask="${HCPPIPEDIR_Templates}/MNI152_T1_${Hires}mm_brain_mask.nii.gz"
    ## Lowres MNI brain mask template
    TemplateMaskLow="${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz"
fi

[ -n "${t1}" ] && T1wTemplate=${t1}
[ -n "${t1b}" ] && T1wTemplateBrain=${t1b}
[ -n "${t1l}" ] && T1wTemplateLow=${t1l}
[ -n "${t2}" ] && T2wTemplate=${t2}
[ -n "${t2b}" ] && T2wTemplateBrain=${t2b}
[ -n "${t2l}" ] && T2wTemplateLow=${t2l}
[ -n "${t1bm}" ] && TemplateMask=${t1bm}
[ -n "${t1bml}" ] && TemplateMaskLow=${t1bml}

#START241002
mkdir -p ${dir0}/templates

if [[ "$TemplateMaskLow" != *"dil"* ]];then
    TemplateMaskLowUndil=$TemplateMaskLow
    echo Dilating $TemplateMaskLowUndil

    #START241002
    #mkdir -p ${dir0}/templates

    TemplateMaskLow=${TemplateMaskLow##*/}
    TemplateMaskLow0=templates/${TemplateMaskLow%%.nii.gz}_dil.nii.gz
    TemplateMaskLow=${dir0}/${TemplateMaskLow0}

    # https://neurostars.org/t/how-to-dilate-a-binary-mask-using-fsl/29033
    fslmaths $TemplateMaskLowUndil -dilM -bin $TemplateMaskLow

    TemplateMaskLow='${sf0}'/${TemplateMaskLow0}

#fi
#START241002
else
    cp -p -f $TemplateMaskLow ${dir0}/templates
fi
cp -p -f $T1wTemplate ${dir0}/templates
cp -p -f $T1wTemplateBrain ${dir0}/templates
cp -p -f $T1wTemplateLow ${dir0}/templates
cp -p -f $T2wTemplate ${dir0}/templates
cp -p -f $T2wTemplateBrain ${dir0}/templates
cp -p -f $T2wTemplateLow ${dir0}/templates
cp -p -f $TemplateMask ${dir0}/templates
#We might consider adding an option to softlink instead copying.

#FT=${dir0}/templates/export_templates.sh
#echo -e "$shebang\nset -e\n" > ${FT} 
#echo export T1wTemplate=${dir0}/templates/${T1wTemplate##*/} >> ${FT}
#echo export T1wTemplateBrain=${dir0}/templates/${T1wTemplateBrain##*/} >> ${FT}
#echo export T1wTemplateLow=${dir0}/templates/${T1wTemplateLow##*/} >> ${FT}
#echo export T2wTemplate=${dir0}/templates/${T2wTemplate##*/} >> ${FT}
#echo export T2wTemplateBrain=${dir0}/templates/${T2wTemplateBrain##*/} >> ${FT}
#echo export T2wTemplateLow=${dir0}/templates/${T2wTemplateLow##*/} >> ${FT}
#echo export TemplateMask=${dir0}/templates/${TemplateMask##*/} >> ${FT}
#echo export TemplateMaskLow=${dir0}/templates/${TemplateMaskLow##*/} >> ${FT}
#START241013
FT=${dir0}/templates/export_templates.sh
echo -e "$shebang\nset -e\n" > ${FT}
echo "export T1wTemplate=${dir0}/templates/${T1wTemplate##*/}" >> ${FT}
echo "export T1wTemplateBrain=${dir0}/templates/${T1wTemplateBrain##*/}" >> ${FT}
echo "export T1wTemplateLow=${dir0}/templates/${T1wTemplateLow##*/}" >> ${FT}
echo "export T2wTemplate=${dir0}/templates/${T2wTemplate##*/}" >> ${FT}
echo "export T2wTemplateBrain=${dir0}/templates/${T2wTemplateBrain##*/}" >> ${FT}
echo "export T2wTemplateLow=${dir0}/templates/${T2wTemplateLow##*/}" >> ${FT}
echo "export TemplateMask=${dir0}/templates/${TemplateMask##*/}" >> ${FT}
echo -e "export TemplateMaskLow=${dir0}/templates/${TemplateMaskLow##*/}\n" >> ${FT}
#https://stackoverflow.com/questions/11426529/reading-output-of-a-command-into-an-array-in-bash
echo "IFS=$'\r\n\t, ' read -r -d '' -a arr < <( fslinfo "'$T1wTemplateLow'" | fgrep pixdim1 && printf '\0' )" >> ${FT}
#https://stackoverflow.com/questions/18714645/how-can-i-remove-leading-and-trailing-zeroes-from-numbers-with-sed-awk-perl
echo export FinalfMRIResolution='$'"(sed -e 's/^[0]*//' -e 's/[0]*"'$'"//' -e 's/\."'$'"//g' <<< "'$'"{arr[1]})" >> ${FT}











echo -e "$shebang\nset -e\n" > ${F0} 
echo -e "#$0 $@\n" >> ${F0}
echo "FREESURFVER=${FREESURFVER}" >> ${F0}
echo -e export FREESURFER_HOME=${FREESURFDIR}/'${FREESURFVER}'"\n" >> ${F0}

echo -e "export HCPDIR=${HCPDIR}\n" >> ${F0}

echo export OGREDIR=${OGREDIR} >> ${F0}
echo PRE='${OGREDIR}'/lib/${PRE} >> ${F0}
echo FREE='${OGREDIR}'/lib/${FREE} >> ${F0}
echo POST='${OGREDIR}'/lib/${POST} >> ${F0}
echo SETUP='${OGREDIR}'/lib/${SETUP} >> ${F0}
echo -e MASKS='${OGREDIR}'/lib/${MASKS}'\n' >> ${F0}

echo "s0=${s0}" >> ${F0}
echo -e "sf0=${dir1}\n" >> ${F0}

#START241002
#echo -e "Hires=${Hires}" >> ${F0}

echo "erosion=${erosion}" >> ${F0}
echo -e "dilation=${dilation}\n" >> ${F0}

echo 'freesurferdir=${sf0}/T1w/${s0}' >> ${F0}
echo 'if [ ! -d "$freesurferdir" ];then' >> ${F0}
echo '    ${PRE} \' >> ${F0}
echo '        --StudyFolder=${sf0} \' >> ${F0}
echo '        --Subject=${s0} \' >> ${F0}
echo '        --runlocal \' >> ${F0}
echo '        --T1='${T1f}' \' >> ${F0}
echo '        --T2='${T2f}' \' >> ${F0}
echo '        --GREfieldmapMag="NONE" \' >> ${F0}
echo '        --GREfieldmapPhase="NONE" \' >> ${F0}


#START241002 Get the hires and lowres from the templates
#echo '        --Hires=${Hires} \' >> ${F0}
#echo '        --T1wTemplate='${T1wTemplate}' \' >> ${F0}
#echo '        --T1wTemplateBrain='${T1wTemplateBrain}' \' >> ${F0}
#echo '        --T1wTemplateLow='${T1wTemplateLow}' \' >> ${F0}
#echo '        --T2wTemplate='${T2wTemplate}' \' >> ${F0}
#echo '        --T2wTemplateBrain='${T2wTemplateBrain}' \' >> ${F0}
#echo '        --T2wTemplateLow='${T2wTemplateLow}' \' >> ${F0}
#echo '        --TemplateMask='${TemplateMask}' \' >> ${F0}
#echo '        --TemplateMaskLow='${TemplateMaskLow}' \' >> ${F0}


echo '        --EnvironmentScript=${SETUP}' >> ${F0}
echo 'else' >> ${F0}
echo '    dirdate=$(date -r $freesurferdir)' >> ${F0}
echo '    newname=${freesurferdir}_${dirdate// /_}' >> ${F0}
echo '    mv "$freesurferdir" "$newname"' >> ${F0}
echo '    echo "$freesurferdir renamed to $newname"' >> ${F0}
echo -e 'fi\n' >> ${F0}

echo '${FREE} \' >> ${F0}
echo '    --StudyFolder=${sf0} \' >> ${F0}
echo '    --Subject=${s0} \' >> ${F0}
echo '    --runlocal \' >> ${F0}

#START241002
#echo '    --Hires=${Hires} \' >> ${F0}

echo '    --freesurferVersion=${FREESURFVER} \' >> ${F0}
((lcsinglereconall)) && echo '    --singlereconall \' >> ${F0}
((lctworeconall)) && echo '    --tworeconall \' >> ${F0}
echo -e '    --EnvironmentScript=${SETUP}\n' >> ${F0}

echo '${POST} \' >> ${F0}
echo '    --StudyFolder=${sf0} \' >> ${F0}
echo '    --Subject=${s0} \' >> ${F0}
echo '    --runlocal \' >> ${F0}
echo '    --erosion=${erosion} \' >> ${F0}
echo '    --dilation=${dilation} \' >> ${F0}
echo -e '    --EnvironmentScript=${SETUP}\n' >> ${F0}
echo '${MASKS} ${sf0}' >> ${F0}

#START240806
echo -e '\necho -e "Finshed $0\\nOGRE structural pipeline completed."' >> ${F0}

echo -e "$shebang\nset -e\n" > ${F1} 
echo -e "FREESURFVER=${FREESURFVER}\ns0=${s0}\nsf0=${dir1}\n"F0='${sf0}'/${F0name}"\n"out='${F0}'.txt >> ${F1}
echo 'if [ -f "${out}" ];then' >> ${F1}
echo '    echo -e "\n\n**********************************************************************" >> ${out}' >> ${F1}
echo '    echo "    Reinstantiation $(date)" >> ${out}' >> ${F1}
echo '    echo -e "**********************************************************************\n\n" >> ${out}' >> ${F1}
echo "fi" >> ${F1}

echo 'cd ${sf0}' >> ${F1}
echo '${F0} >> ${out} 2>&1 &' >> ${F1}

chmod +x ${F0}
chmod +x ${F1}
echo "    Output written to ${F0}"
echo "    Output written to ${F1}"

if [ -n "${bs}" ];then
    echo -e "FREESURFVER=${FREESURFVER}\ns0=${s0}\nsf0=${dir1}\n"F0='${sf0}'/${F0name}"\n"out='${F0}'.txt >> ${bs0}
    echo 'if [ -f "${out}" ];then' >> ${bs0}
    echo '    echo -e "\n\n**********************************************************************" >> ${out}' >> ${bs0}
    echo '    echo "    Reinstantiation $(date)" >> ${out}' >> ${bs0}
    echo '    echo -e "**********************************************************************\n\n" >> ${out}' >> ${bs0}
    echo "fi" >> ${bs0}
    echo 'cd ${sf0}' >> ${bs0}
    echo '${F0} >> ${out} 2>&1' >> ${bs0} #no ampersand at end

    echo "${bs0} > ${bs0}.txt 2>&1 &" >> ${bs1}
    chmod +x ${bs0}
    chmod +x ${bs1}
    echo "    Output written to ${bs0}"
    echo "    Output written to ${bs1}"
    [[ ${bs} != True ]] && echo ${bs0} >> ${bs}
fi
if((lcautorun==1));then
    ${F1}
    echo "    ${F1} has been executed"
fi

if [ -n "${bs}" ];then
    if [[ ${bs} != True ]];then
        echo "${bs} > ${bs}.txt 2>&1 &" >> ${bs_fileout}
        chmod +x $bs $bs_fileout
        echo "Output written to $bs"
        echo "Output written to $bs_fileout"
    fi
fi

# added by Ben 240707
cp -p -f ${dat} ${dir0}

echo "OGRE structural pipeline setup completed."
