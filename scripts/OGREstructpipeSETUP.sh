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
MASKSLOW=OGREMasksLow.sh

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
    echo "    -V --VERSION -VERSION --FREESURFVER -FREESURFVER --freesurferVersion -freesurferVersion --freesurferversion -freesurferversion"
    echo "        5.3.0-HCP, 7.2.0, 7.3.2, 7.4.0 or 7.4.1. Default is 7.4.1 unless set elsewhere via variable FREESURFVER."
    echo "    -m --HOSTNAME -HOSTNAME --hostname -hostname"
    echo "        Flag. Append machine name to pipeline directory. Ex. pipeline7.4.1_3452-AD-05003"
    echo "    -D --DATE -DATE --date -date"
    echo "        Flag. Add date (YYMMDD) to name of output script."
    echo "    -L -DL --DL --DATELONG -DATELONG --datelong -datelong"
    echo "        Flag. Add date (YYMMDDHHMMSS) to name of output script."
    echo "    -b --batchscript -batchscript"
    echo "        *_fileout.sh scripts are collected in an executable batchscript."
    echo "        This permits the struct and fMRIvol scripts to be run sequentially and seamlessly."
    echo "        If a filename is provided, then in addition, the batchscripts are written to the provided filename."
    echo "        This facilitates the creation of an across-subjects script such that multiple subjects can be run sequentially and seamlessly."
    echo "    -d --dilation -dilation --dil -dil"
    echo "        Dilate the brain mask. Default is 3. Number of dilations (fslmaths dilD) that precede the erosions."
    echo "        Ex. -d 3, will result in three dilations"
    echo "    -e --erosion -erosion --ero -ero"
    echo "        Erode the brain mask. Default is 2. Number of erosions that follow the dilations."
    echo "        Ex. -e 2, will result in two erosions"
    echo "        See OGRE-pipeline/lib/OGREFreeSurfer2CaretConvertAndRegisterNonlinear.sh"
    echo "    -ht --ht --highres-template -highres-template --HighResolutionTemplateDirectory -HighResolutionTemplateDirectory"
    echo "        Optional. High resolution registration templates. Default is MNI152 1mm asymmetric (HCP/FSL)"
    echo "        Full path of a folder containing 2 files: T1w (whole-head), T1w_brain and/or T1_brain_mask"
    echo "        Optionally, two T2-weighted images can be included: T2w (whole-head), T2w_brain and/or T2_brain_mask"
    echo "        e.g. $OGREDIR/lib/templates/mni-hcp_asym_1mm"
    echo "    -lt --lt --lowres-template -lowres-template --LowResolutionTemplateDirectory -LowResolutionTemplateDirectory"
    echo "        Optional. Low resolution registration templates. Default is MNI152 2mm asymmetric (HCP/FSL version)"
    echo "        Full path of a folder containing 2 files: T1w (whole-head), T1w_brain and/or T1w_brain_mask"
    echo '        If T1w_brain_mask does not include "dil" in its name, then it is dilated.'
    echo "        Optionally, a single T2-weighted image can be included: T2w (whole head)"
    echo "        e.g. $OGREDIR/lib/templates/mni-hcp_asym_2mm"
    echo "    -P --projectdirectory -projectdirectory --container_directory -container_directory --cd -cd"
    echo "        Ex. /Users/Shared/10_Connectivity/derivatives/preprocessed/sub-1019_OGRE-preproc"
    echo "            func, anat, regressors, pipeline7.4.1 are created inside this directory"
    echo "    -n --name -name"
    echo "        Use with --parent to provide the subject name. Default is root of scanlist.csv."

    if [ -z "$1" ];then
        echo "    --helpall -helpall"
        echo "        Show all options."
        echo "    -h --help -help"
        echo "        Echo this help message."
    else
        echo "    -r --hires -hires"
        echo "        High resolution in mm: 0.7, 0.8 or 1. Default is 1. Applies only to default MNI152 asymmetric (HCP/FSL) templates."

        echo "    -T1 --T1 -t1 --t1 --T1HighResolutionWholeHead -T1HighResolutionWholeHead"
        echo "        Default is MNI152_T1_${Hires}mm.nii.gz. This will override -ht."
        echo "    -T1brain --T1brain -t1brain --t1brain -t1b --t1b -T1b --T1b -T1HighResolutionBrainOnly --T1HighResolutionBrainOnly"
        echo "        Default is MNI152_T1_${Hires}mm_brain.nii.gz. This will override -ht."
        echo "    -T1brainmask --T1brainmask -t1brainmask --t1brainmask -t1bm --t1bm -T1bm --T1bm -T1HighResolutionBrainMask --T1HighResolutionBrainMask"
        echo "        Default is MNI152_T1_${Hires}mm_brain_mask.nii.gz. This will override -ht."

        echo "    -T1low --T1low -t1low --t1low -t1l --t1l -T1l --T1l -T1LowResolutionWholeHead --T1LowResolutionWholeHead"
        echo "        Default is MNI152_T1_2mm.nii.gz. This will overide -lt."
        echo "    -T1brainlow --T1brainlow -t1brainlow --t1brainlow -t1bl --t1bl -T1bl --T1bl -T1LowResolutionBrainOnly --T1LowResolutionBrainOnly"
        echo "        No default. If provided, this will be used to make the low resolution mask. This will override -lt."
        echo "    -T1brainmasklow --T1brainmasklow -t1brainmasklow --t1brainmasklow -t1bml --t1bml -T1bml --T1bml -T1LowResolutionBrainMask --T1LowResolutionBrainMask"
        echo "        Default is MNI152_T1_2mm_brain_mask_dil.nii.gz. This will override -lt."
        echo '        Mask is dilated if name does not include "dil".'

        echo "    -T2 --T2 -t2 --t2 -T2HighResolutionWholeHead --T2HighResolutionWholeHead"
        echo "        Default is MNI152_T2_${Hires}mm.nii.gz. This will override -ht."
        echo "    -T2brain --T2brain -t2brain --t2brain -t2b --t2b -T2b --T2b -T2HighResolutionBrainOnly --T2HighResolutionBrainOnly"
        echo "        Default is MNI152_T2_${Hires}mm_brain.nii.gz. This will override -ht."
        echo "    -T2brainmask --T2brainmask -t2brainmask --t2brainmask -t2bm --t2bm -T2bm --T2bm -T2HighResolutionBrainMask --T2HighResolutionBrainMask" 
        echo "        No default. If provided, this will be used to make the T2brain image. This will override -ht."
        echo "    -T2low --T2low -t2low --t2low -t2l --t2l -T2l --T2l -T2LowResolutionWholeHead --T2LowResolutionWholeHead"
        echo "        Default is MNI152_T2_2mm.nii.gz. This will override -lt."

        echo "    -h --help -help"
        echo "        Echo the short list."
        echo "    --helpall -helpall"
        echo "        Echo this help message."
    fi

    #START250606
    #echo "    -h --help -help"
    #echo "        Echo this help message."

    }
if((${#@}<1));then
    helpmsg
    exit
fi

lcautorun=0;lchostname=0;lcdate=0;erosion=2;dilation=3 #DON'T SET dat unexpected

#unset bs cd0 name helpall help t1 t1b t1bm t1l t1bl t1bml t2 t2b t2bm t2l ht lt
#START250705
unset bs cd0 bids name helpall help t1 t1b t1bm t1l t1bl t1bml t2 t2b t2bm t2l ht lt s1


unset T1wTemplate T1wTemplateBrain TemplateMask T1wTemplateLow T1wTemplateBrainLow TemplateMaskLow T2wTemplate T2wTemplateBrain T2wTemplateMask T2wTemplateLow 

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
        -V | --VERSION | -VERSION | --FREESURFVER | -FREESURFVER | --freesurferVersion | -freesurferVersion | --freesurferversion | -freesurferversion)
            FREESURFVER=${arg[((++i))]}
            #echo "FREESURFVER=$FREESURFVER"
            ;;
        -m | --HOSTNAME | -HOSTNAME | --hostname | -hostname)
            lchostname=1
            echo "lchostname=$lchostname"
            ;;
        -D | --DATE | -DATE | --date | -date)
            lcdate=1
            #echo "lcdate=$lcdate"
            ;;
        -L | -DL | --DL | --DATELONG | -DATELONG | --datelong | -datelong)
            lcdate=2
            echo "lcdate=$lcdate"
            ;;
        -b | --batchscript | -batchscript)
            bs=True
            ((((i+i))<${#@})) && [[ ${arg[i+1]:0:1} != "-" ]] && bs=${arg[((++i))]}
            #echo "bs=$bs"
            ;;
        -d | --dilation | -dilation | --dil | -dil)
            dilation=${arg[((++i))]}
            echo "dilation=$dilation"
            ;;
        -e | --erosion | -erosion | --ero | -ero)
            erosion=${arg[((++i))]}
            echo "erosion=$erosion"
            ;;
        -ht | --ht | --highres-template | -highres-template | --HighResolutionTemplateDirectory | -HighResolutionTemplateDirectory)
            ht=${arg[((++i))]}
            echo "ht=$ht"
            ;;
        -lt | --lt | --lowres-template | -lowres-template | --LowResolutionTemplateDirectory | -LowResolutionTemplateDirectory)
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
        -T1 | --T1 | -t1 | --t1 | --T1HighResolutionWholeHead | -T1HighResolutionWholeHead)
            t1=${arg[((++i))]}
            ;;
        -T1brain | --T1brain | -t1brain | --t1brain | -t1b | --t1b | -T1b | --T1b | -T1HighResolutionBrainOnly | --T1HighResolutionBrainOnly)
            t1b=${arg[((++i))]}
            ;;
        -T1brainmask | --T1brainmask | -t1brainmask | --t1brainmask | -t1bm | --t1bm | -T1bm | --T1bm | -T1HighResolutionBrainMask | --T1HighResolutionBrainMask)
            t1bm=${arg[((++i))]}
            ;;
        -T1low | --T1low | -t1low | --t1low | -t1l | --t1l | -T1l | --T1l | -T1LowResolutionWholeHead | --T1LowResolutionWholeHead)
            t1l=${arg[((++i))]}
            ;;
        -T1brainlow | --T1brainlow | -t1brainlow | --t1brainlow | -t1bl | --t1bl | -T1bl | --T1bl | -T1LowResolutionBrainOnly | --T1LowResolutionBrainOnly)
            t1bl=${arg[((++i))]}
            ;;
        -T1brainmasklow | --T1brainmasklow | -t1brainmasklow | --t1brainmasklow | -t1bml | --t1bml | -T1bml | --T1bml | -T1LowResolutionBrainMask | --T1LowResolutionBrainMask)
            t1bml=${arg[((++i))]}
            ;;
        -T2 | --T2 | -t2 | --t2 | -T2HighResolutionWholeHead | --T2HighResolutionWholeHead)
            t2=${arg[((++i))]}
            ;;
        -T2brain | --T2brain | -t2brain | --t2brain | -t2b | --t2b | -T2b | --T2b | -T2HighResolutionBrainOnly | --T2HighResolutionBrainOnly)
            t2b=${arg[((++i))]}
            ;;
        -T2brainmask | --T2brainmask | -t2brainmask | --t2brainmask | -t2bm | --t2bm | -T2bm | --T2bm | -T2HighResolutionBrainMask | --T2HighResolutionBrainMask) 
            t2bm=${arg[((++i))]}
            ;;
        -T2low | --T2low | -t2low | --t2low | -t2l | --t2l | -T2l | --T2l | -T2LowResolutionWholeHead | --T2HighResolutionWholeHead)
            t2l=${arg[((++i))]}
            ;;
        -p | --pipedir | -pipedir | -d | -directory | --directory)
            echo ${arg[i]} is archaic. Use --projectdirectory instead.
            exit
            ;;
        --append | -append)
            echo ${arg[i]} is archaic. Use --projectdirectory instead.
            exit
            ;;
        -P | --projectdirectory | -projectdirectory | --container_directory | -container_directory | --cd | -cd)
            cd0=${arg[((++i))]}
            bids=${cd0}
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


#sed -i '' $'s/\r$//' ${dat}
#START241106
#https://stackoverflow.com/questions/40393643/preserve-timestamp-in-sed-command
#cp -p ${dat} tmp; sed -i '' $'s/\r$//' ${dat}; touch -r tmp ${dat}; rm -f tmp
#t=$(stat -c %y "${dat}"); sed -i '' $'s/\r$//' ${dat}; touch -d "$t" "${dat}" #does not preserve timestamp
#https://stackoverflow.com/questions/34432514/preserve-timestamp-when-editing-file
#touch -r ${dat} tmp; sed -i '' $'s/\r$//' ${dat}; touch -r tmp ${dat}; rm -f tmp
#START250524
#sed command that works on darwin and linux
#https://stackoverflow.com/questions/4247068/sed-command-with-i-option-failing-on-mac-but-works-on-linux
#tested on mac and WSL-Ubuntu
touch -r ${dat} tmp; perl -i -pe$'s/\r$//' ${dat}; touch -r tmp ${dat}; rm -f tmp




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


#if [ -z "${cd0}" ];then
#    T1f=${T1f//${s0}/'${s0}'}
#    T2f=${T2f//${s0}/'${s0}'}
#    if ! [[ $(echo ${subj[@]} | fgrep -w "raw_data") ]];then
#        dir0=/$(join_by / ${subj[@]::${#subj[@]}-1})/${s0}/pipeline${FREESURFVER}
#        dir1=/$(join_by / ${subj[@]::${#subj[@]}-1})/'${s0}'/pipeline'${FREESURFVER}'
#    else
#        for j in "${!subj[@]}";do
#            if [[ "${subj[j]}" = "raw_data" ]];then
#                dir0=/$(join_by / ${subj[@]::j})/derivatives/preprocessed/${s0}/pipeline${FREESURFVER}
#                dir1=/$(join_by / ${subj[@]::j})/derivatives/preprocessed/'${s0}'/pipeline'${FREESURFVER}'
#                break
#            fi
#        done
#    fi
#else
#    dir0=${cd0}/pipeline${FREESURFVER}
#    dir1=${cd0}/pipeline'${FREESURFVER}'
#fi
#START250705
if [ -z "${cd0}" ];then
    T1f=${T1f//${s0}/'${s0}'}
    T2f=${T2f//${s0}/'${s0}'}
    if ! [[ $(echo ${subj[@]} | fgrep -w "raw_data") ]];then
        #dir0=/$(join_by / ${subj[@]::${#subj[@]}-1})/${s0}/pipeline${FREESURFVER}
        #dir1=/$(join_by / ${subj[@]::${#subj[@]}-1})/'${s0}'/pipeline'${FREESURFVER}'
        d0=/$(join_by / ${subj[@]::${#subj[@]}})
        str0=
        bids=${d0}${str0}
        #echo "here0 bids=$bids"
    else
        for j in "${!subj[@]}";do
            if [[ "${subj[j]}" = "raw_data" ]];then
                #dir0=/$(join_by / ${subj[@]::j})/derivatives/preprocessed/${s0}/pipeline${FREESURFVER}
                #dir1=/$(join_by / ${subj[@]::j})/derivatives/preprocessed/'${s0}'/pipeline'${FREESURFVER}'
                d0=/$(join_by / ${subj[@]::j})
                str0=derivatives/preprocessed/${s0}
                bids=${d0}${str0}'${s0}'
                break
            fi
        done
    fi
    dir0=${d0}${str0}/pipeline${FREESURFVER}
    dir1='${bids}/pipeline${FREESURFVER}'
else
    dir0=${cd0}/pipeline${FREESURFVER}
    dir1=${cd0}/pipeline'${FREESURFVER}'
fi

if [[ -n $name ]];then
    s0=$name
elif [[ -z ${subj[j]} ]];then
    r0=${datf##*/}
    s0=${r0%scanlist*}
    [[ ${s0: -1} == _ ]] && s0=${s0%_*} #space required
fi
[[ -n ${s0} ]] && s1=${s0}_

if((lchostname==1));then
    dir0+=_$(hostname)
    dir1+=_'$(hostname)'
fi

datestr=''
if((lcdate==1));then
    datestr=_$(date +%y%m%d)
elif((lcdate==2));then
    datestr=_$(date +%y%m%d%H%M%S)
fi

mkdir -p ${dir0}/scripts ${dir0}/templates 

tmp='.OGREtmp'
rm -Rf $tmp 
echo ${dir0} > $tmp 


F0stem=${dir0}/scripts/${s1}OGREstruct${datestr} 
F0=${F0stem}.sh
F1=${F0stem}_fileout.sh

#F0name='${s0}'_OGREstruct${datestr}.sh
#START250711
F0name='${s0}'OGREstruct${datestr}.sh

Fcopy=${dir0}/scripts/${s1}bidscp_struct${datestr}.sh


#Fcopyname='${s0}'_bidscp_struct${datestr}.sh
#START250711
Fcopyname='${s1}'bidscp_struct${datestr}.sh


if [ -n "${bs}" ];then
    bs0stem=${dir0}/scripts/${s0}_OGREbatch${datestr} 
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

        #START241228
        elif [[ "$i" == *"T1w_brain.nii.gz" ]];then
            T1wTemplateBrainLow=$i

        elif [[ "$i" == *"T1w_brain_mask.nii.gz" ]];then
            TemplateMaskLow=$i
        elif [[ "$i" == *"T2w.nii.gz" ]];then
            T2wTemplateLow=$i
        else
            echo Ignoring $i
            continue
        fi
        echo Fetching $i
    done
    if [[ -z "$T1wTemplate" ]];then
        echo "T1wTemplate not provided. Abort!"
        exit
    fi
    if [[ -z "$T1wTemplateBrain" && -z "$TemplateMask" ]];then
        echo "T1wTemplateBrain and TemplateMask not provided. One is needed to compute the other. Abort!"
        exit
    fi
    if [[ -z "$T1wTemplateBrain" ]];then
        #mkdir -p ${dir0}/templates
        T1wTemplateBrain=${T1wTemplate##*/}
        T1wTemplateBrain=${dir0}/templates/${T1wTemplateBrain%%.nii.gz}_brain.nii.gz
        #fslmaths HEAD -mas MASK BRAIN
        fslmaths $T1wTemplate -mas $TemplateMask $T1wTemplateBrain
    fi
    if [[ -z "$TemplateMask" ]];then
        #mkdir -p ${dir0}/templates
        TemplateMask=${T1wTemplate##*/}
        TemplateMask=${dir0}/templates/${TemplateMask%%.nii.gz}_brain_mask.nii.gz
        #fslmaths BRAIN -bin MASK
        fslmaths $T1wTemplateBrain -bin $TemplateMask
    fi

    if [[ -z "$T1wTemplateLow" ]];then
        echo "T1wTemplateLow not provided. Abort!"
        exit
    fi

    #if [[ -z "$TemplateMaskLow" ]];then
    #    echo TemplateMaskLow not provided. Abort!
    #    exit
    #fi
    #START241228
    if [[ -z "$TemplateMaskLow" ]];then
        if [[ -z "$T1wTemplateBrainLow" ]];then
            echo "TemplateMaskLow and T1wTemplateBrainLow not provided. Please provide either one. Abort!"
            exit
        fi
        TemplateMaskLow=${T1wTemplateBrainLow##*/}
        TemplateMaskLow=${dir0}/templates/${TemplateMaskLow%%.nii.gz}_mask.nii.gz
        [[ -f "$TemplateMaskLow" ]] && TemplateMaskLow=${TemplateMaskLow%%.nii.gz}_low.nii.gz
        echo "Writing $TemplateMask ..."
        #fslmaths BRAIN -bin MASK
        fslmaths $T1wTemplateBrainLow -bin $TemplateMaskLow
    fi


    if [[ -n "${T2f}" ]];then
        if [[ -z "$T2wTemplate" ]];then
            echo "T2wTemplate not provided. Abort!"
            exit
        fi
        if [[ -z "$T2wTemplateBrain" ]];then
            if [[ -z "$T2wTemplateMask" ]];then
                echo "T2wTemplateMask is needed to create T2wTemplateBrain. Abort!"
                exit
            fi
            #mkdir -p ${dir0}/templates
            T2wTemplateBrain=${T2wTemplate##*/}
            T2wTemplateBrain=${dir0}/templates/${T2wTemplate%%.nii.gz}_brain.nii.gz
            #fslmaths HEAD -mas MASK BRAIN
            fslmaths $T2wTemplate -mas $T2wTemplateMask $T2wTemplateBrain
        fi
        if [[ -z "$T2wTemplateLow" ]];then
            echo "T2wTemplateLow not provided. Abort!"
            exit
        fi
    fi

else
    ## Hires T1w MNI template
    HCPPIPEDIR_Templates=${OGREDIR}/lib/HCP/HCPpipelines-3.27.0/global/templates
    T1wTemplate="${HCPPIPEDIR_Templates}/MNI152_T1_${Hires}mm.nii.gz"
    ## Hires brain extracted MNI template
    T1wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T1_${Hires}mm_brain.nii.gz"
    ## Lowres MNI brain mask template
    TemplateMaskLow="${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz"

    ## Lowres T1w MNI template
    T1wTemplateLow="${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz"
    ## Hires MNI brain mask template
    TemplateMask="${HCPPIPEDIR_Templates}/MNI152_T1_${Hires}mm_brain_mask.nii.gz"

    ## Hires T2w MNI Template
    T2wTemplate="${HCPPIPEDIR_Templates}/MNI152_T2_${Hires}mm.nii.gz"
    ## Hires T2w brain extracted MNI Template
    T2wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T2_${Hires}mm_brain.nii.gz"
    ## Lowres T2w MNI Template
    T2wTemplateLow="${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz"
fi



#[ -n "${t1}" ] && T1wTemplate=${t1}
#[ -n "${t1b}" ] && T1wTemplateBrain=${t1b}
#[ -n "${t1l}" ] && T1wTemplateLow=${t1l}
#[ -n "${t2}" ] && T2wTemplate=${t2}
#[ -n "${t2b}" ] && T2wTemplateBrain=${t2b}
#[ -n "${t2l}" ] && T2wTemplateLow=${t2l}
#[ -n "${t1bm}" ] && TemplateMask=${t1bm}
#[ -n "${t1bml}" ] && TemplateMaskLow=${t1bml}
#START241228
[ -n "${t1}" ] && T1wTemplate=${t1}
[ -n "${t1b}" ] && T1wTemplateBrain=${t1b}
[ -n "${t1bm}" ] && TemplateMask=${t1bm}
if [[ -n "${t1b}" && -n "${t1bm}" ]];then
    : #do nothing
elif [[ -n "${t1b}" ]];then
    [[ -n "$TemplateMask" ]] && echo "Overwriting $TemplateMask ..."
    TemplateMask=${T1wTemplateBrain##*/}
    TemplateMask=${dir0}/templates/${TemplateMask%%.nii.gz}_mask.nii.gz
    echo "Writing $TemplateMask ..."
    #fslmaths BRAIN -bin MASK
    fslmaths $T1wTemplateBrain -bin $TemplateMask
elif [[ -n "${t1bm}" ]];then
    [[ -n "T1wTemplateBrain" ]] && echo "Overwriting $T1wTemplateBrain ..."
    T1wTemplateBrain=${T1wTemplate##*/}
    T1wTemplateBrain=${dir0}/templates/${T1wTemplateBrain%%.nii.gz}_brain.nii.gz
    echo "Writing $T1wTemplateBrain ..."
    #fslmaths HEAD -mas MASK BRAIN
    fslmaths $T1wTemplate -mas $TemplateMask $T1wTemplateBrain
fi

[ -n "${t1l}" ] && T1wTemplateLow=${t1l}
[ -n "${t1bl}" ] && T1wTemplateBrainLow=${t1bl}
[ -n "${t1bml}" ] && TemplateMaskLow=${t1bml}
if [[ -n "${t1bml}" ]];then
    : #do nothing
elif [[ -n "${t1bl}" ]];then
    [[ -n "$TemplateMaskLow" ]] && echo "Overwriting $TemplateMaskLow ..."
    TemplateMaskLow=${T1wTemplateBrainLow##*/}
    TemplateMaskLow=${dir0}/templates/${TemplateMaskLow%%.nii.gz}_mask.nii.gz
    [[ -f "$TemplateMaskLow" ]] && TemplateMaskLow=${TemplateMaskLow%%.nii.gz}_low.nii.gz
    echo "Writing $TemplateMask ..."
    #fslmaths BRAIN -bin MASK
    fslmaths $T1wTemplateBrainLow -bin $TemplateMaskLow
fi

[ -n "${t2}" ] && T2wTemplate=${t2}
[ -n "${t2b}" ] && T2wTemplateBrain=${t2b}
[ -n "${t2bm}" ] && T2wTemplateMask=${t2bm}
if [[ -n "${t2b}" ]];then
    : #do nothing
elif [[ -n "${t2bm}" ]];then
    [[ -n "$T2wTemplateBrain" ]] && echo "Overwriting $T2wTemplateBrain ..."
    T2wTemplateBrain=${T2wTemplate##*/}
    T2wTemplateBrain=${dir0}/templates/${T2wTemplateBrain%%.nii.gz}_brain.nii.gz
    echo "Writing $T2wTemplateBrain ..."
    #fslmaths HEAD -mas MASK BRAIN
    fslmaths $T2wTemplate -mas $T2wTemplateMask $T2wTemplateBrain
fi




[ -n "${t2l}" ] && T2wTemplateLow=${t2l}


#START241228
#mkdir -p ${dir0}/templates

if [[ "$TemplateMaskLow" != *"dil"* ]];then
    TemplateMaskLowUndil=$TemplateMaskLow
    echo Dilating $TemplateMaskLowUndil

    TemplateMaskLow=${TemplateMaskLow##*/}
    TemplateMaskLow0=templates/${TemplateMaskLow%%.nii.gz}_dil.nii.gz
    TemplateMaskLow=${dir0}/${TemplateMaskLow0}

    # https://neurostars.org/t/how-to-dilate-a-binary-mask-using-fsl/29033
    fslmaths $TemplateMaskLowUndil -dilM -bin $TemplateMaskLow

    TemplateMaskLow='${sf0}'/${TemplateMaskLow0}
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
echo MASKS='${OGREDIR}'/lib/${MASKS} >> ${F0}
echo -e MASKSLOW='${OGREDIR}'/lib/${MASKSLOW}'\n' >> ${F0}

echo "s0=${s0}" >> ${F0}

#echo "bids=${cd0}" >> ${F0}
#START250705
echo "bids=${bids}" >> ${F0}

echo -e 'sf0=${bids}/pipeline${FREESURFVER}\n' >> ${F0}

#START250711
echo 'unset s1'  >> ${F0}
echo '[[ -n ${s0} ]] && s1=${s0}_'  >> ${F0}

echo -e COPY='${sf0}'/scripts/${Fcopyname}'\n' >> ${F0}
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

#echo -e '${MASKSLOW} ${sf0}\n' >> ${F0}
#START250705
echo '${MASKSLOW} ${sf0}' >> ${F0}




#echo 'mkdir -p ${bids}/anat' >> ${F0}
#echo 'source ${sf0}/templates/export_templates.sh #->FinalfMRIResolution' >> ${F0}
#echo 'ANAT=(T1w_restore \' >> ${F0}
#echo '      T1w_restore_brain \'  >> ${F0}
#echo '      T1w_restore.${FinalfMRIResolution} \' >> ${F0}
#[ -n "${T2f}" ] && ender=' \' || ender=')'
#echo '      T1w_restore_brain.${FinalfMRIResolution}'$ender  >> ${F0}
#if [ -n "${T2f}" ];then
#    echo '      T2w_restore \'  >> ${F0}
#    echo '      T2w_restore_brain)'  >> ${F0}
#fi
#echo 'OUT=(OGRE-preproc_desc-restore_T1w \' >> ${F0}
#echo '     OGRE-preproc_desc-restore_T1w_brain \' >> ${F0}
#echo '     OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w \' >> ${F0}
#echo '     OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w_brain'$ender >> ${F0}
#if [ -n "${T2f}" ];then
#    echo '     OGRE-preproc_desc-restore_T2w \' >> ${F0}
#    echo '     OGRE-preproc_desc-restore_T2w_brain)' >> ${F0}
#fi
#echo 'for((i=0;i<${#ANAT[@]};++i));do' >> ${F0}
#echo '    anat=${sf0}/MNINonLinear/${ANAT[i]}.nii.gz' >> ${F0}
#echo '    if [ ! -f "${anat}" ];then' >> ${F0}
#echo '        echo ${anat} not found.' >> ${F0}
#echo '        continue' >> ${F0}
#echo '    fi' >> ${F0}
#echo '    out=${bids}/anat/${s0}_${OUT[i]}.nii.gz' >> ${F0}
#echo '    cp -f -p ${anat} ${out}' >> ${F0}
#echo '    echo -e "${anat}\n    copied to ${out}"' >> ${F0}
#echo 'done' >> ${F0}
#T1j=${T1f//nii.gz/json}
#[ -n "${T2f}" ] && T2j=${T2f//nii.gz/json}
#echo -e '\nFILE=(${bids}/anat/${s0}_OGRE-preproc_desc-restore_T1w.nii.gz \' >> ${F0}
#echo '     ${bids}/anat/${s0}_OGRE-preproc_desc-restore_T1w_brain.nii.gz \' >> ${F0}
#echo '     ${bids}/anat/${s0}_OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w.nii.gz \' >> ${F0}
#echo '     ${bids}/anat/${s0}_OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w_brain.nii.gz'$ender >> ${F0}
#if [ -n "${T2f}" ];then
#    echo '     ${bids}/anat/${s0}_OGRE-preproc_desc-restore_T2w.nii.gz \' >> ${F0}
#    echo '     ${bids}/anat/${s0}_OGRE-preproc_desc-restore_T2w_brain.nii.gz)' >> ${F0}
#fi
#echo 'JSON=('${T1j}' \' >> ${F0}
#echo '      '${T1j}' \' >> ${F0}
#echo '      '${T1j}' \' >> ${F0}
#[ -n "${T2j}" ] && ender=' \' || ender=')'
#echo '      '${T1j}$ender >> ${F0}
#if [ -n "${T2j}" ];then
#    echo '      '${T2j}' \' >> ${F0}
#    echo '      '${T2j}')' >> ${F0}
#fi
#echo 'OGREjson.py -f "${FILE[@]}" -j "${JSON[@]}"' >> ${F0} #@ needed for python to see arrays
#START250705
echo -e "$shebang\nset -e\n" > ${Fcopy} 
echo "FREESURFVER=${FREESURFVER}" >> ${Fcopy}
echo "s0=${s0}" >> ${Fcopy}
echo "bids=${bids}" >> ${Fcopy}
echo -e 'sf0=${bids}/pipeline${FREESURFVER}\n' >> ${Fcopy}

#START250711
echo '[[ -n ${s0} ]] && s0+=_'  >> ${Fcopy} 

echo 'mkdir -p ${bids}/anat' >> ${Fcopy}
echo 'source ${sf0}/templates/export_templates.sh #->FinalfMRIResolution' >> ${Fcopy}
echo 'ANAT=(T1w_restore \' >> ${Fcopy}
echo '      T1w_restore_brain \'  >> ${Fcopy}
echo '      T1w_restore.${FinalfMRIResolution} \' >> ${Fcopy}
[ -n "${T2f}" ] && ender=' \' || ender=')'
echo '      T1w_restore_brain.${FinalfMRIResolution}'$ender  >> ${Fcopy}
if [ -n "${T2f}" ];then
    echo '      T2w_restore \'  >> ${Fcopy}
    echo '      T2w_restore_brain)'  >> ${Fcopy}
fi
echo 'OUT=(OGRE-preproc_desc-restore_T1w \' >> ${Fcopy}
echo '     OGRE-preproc_desc-restore_T1w_brain \' >> ${Fcopy}
echo '     OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w \' >> ${Fcopy}
echo '     OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w_brain'$ender >> ${Fcopy}
if [ -n "${T2f}" ];then
    echo '     OGRE-preproc_desc-restore_T2w \' >> ${Fcopy}
    echo '     OGRE-preproc_desc-restore_T2w_brain)' >> ${Fcopy}
fi
echo 'for((i=0;i<${#ANAT[@]};++i));do' >> ${Fcopy}
echo '    anat=${sf0}/MNINonLinear/${ANAT[i]}.nii.gz' >> ${Fcopy}
echo '    if [ ! -f "${anat}" ];then' >> ${Fcopy}
echo '        echo ${anat} not found.' >> ${Fcopy}
echo '        continue' >> ${Fcopy}
echo '    fi' >> ${Fcopy}

#echo '    out=${bids}/anat/${s0}_${OUT[i]}.nii.gz' >> ${Fcopy}
#START250711
echo '    out=${bids}/anat/${s0}${OUT[i]}.nii.gz' >> ${Fcopy}

echo '    cp -f -p ${anat} ${out}' >> ${Fcopy}
echo '    echo -e "${anat}\n    copied to ${out}"' >> ${Fcopy}
echo 'done' >> ${Fcopy}
T1j=${T1f//nii.gz/json}
[ -n "${T2f}" ] && T2j=${T2f//nii.gz/json}


#echo -e '\nFILE=(${bids}/anat/${s0}_OGRE-preproc_desc-restore_T1w.nii.gz \' >> ${Fcopy}
#echo '     ${bids}/anat/${s0}_OGRE-preproc_desc-restore_T1w_brain.nii.gz \' >> ${Fcopy}
#echo '     ${bids}/anat/${s0}_OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w.nii.gz \' >> ${Fcopy}
#echo '     ${bids}/anat/${s0}_OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w_brain.nii.gz'$ender >> ${Fcopy}
#if [ -n "${T2f}" ];then
#    echo '     ${bids}/anat/${s0}_OGRE-preproc_desc-restore_T2w.nii.gz \' >> ${Fcopy}
#    echo '     ${bids}/anat/${s0}_OGRE-preproc_desc-restore_T2w_brain.nii.gz)' >> ${Fcopy}
#fi
#START250711
echo -e '\nFILE=(${bids}/anat/${s0}OGRE-preproc_desc-restore_T1w.nii.gz \' >> ${Fcopy}
echo '     ${bids}/anat/${s0}OGRE-preproc_desc-restore_T1w_brain.nii.gz \' >> ${Fcopy}
echo '     ${bids}/anat/${s0}OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w.nii.gz \' >> ${Fcopy}
echo '     ${bids}/anat/${s0}OGRE-preproc_res-${FinalfMRIResolution}_desc-restore_T1w_brain.nii.gz'$ender >> ${Fcopy}
if [ -n "${T2f}" ];then
    echo '     ${bids}/anat/${s0}OGRE-preproc_desc-restore_T2w.nii.gz \' >> ${Fcopy}
    echo '     ${bids}/anat/${s0}OGRE-preproc_desc-restore_T2w_brain.nii.gz)' >> ${Fcopy}
fi


echo 'JSON=('${T1j}' \' >> ${Fcopy}
echo '      '${T1j}' \' >> ${Fcopy}
echo '      '${T1j}' \' >> ${Fcopy}
[ -n "${T2j}" ] && ender=' \' || ender=')'
echo '      '${T1j}$ender >> ${Fcopy}
if [ -n "${T2j}" ];then
    echo '      '${T2j}' \' >> ${Fcopy}
    echo '      '${T2j}')' >> ${Fcopy}
fi
echo 'OGREjson.py -f "${FILE[@]}" -j "${JSON[@]}"' >> ${Fcopy} #@ needed for python to see arrays


echo '${COPY}' >> ${F0} #F0 is correct
echo "    Output written to ${Fcopy}"




echo -e '\necho -e "Finshed $0\\nOGRE structural pipeline completed."' >> ${F0}

echo -e "$shebang\nset -e\n" > ${F1} 

echo "FREESURFVER=${FREESURFVER}" >> ${F1}
echo "s0=${s0}" >> ${F1}
echo "bids=${bids}" >> ${F1}
echo -e 'sf0=${bids}/pipeline${FREESURFVER}\n' >> ${F1}

#START250711
echo '[[ -n ${s0} ]] && s0+=_'  >> ${F1}

echo -e F0='${sf0}'/scripts/${F0name}'\nout=${F0}'.txt >> ${F1}


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

    #echo -e ${e0} >> ${bs0}
    #START250706
    echo "FREESURFVER=${FREESURFVER}" >> ${F1}
    echo "s0=${s0}" >> ${F1}
    echo "bids=${bids}" >> ${F1}
    echo -e 'sf0=${bids}/pipeline${FREESURFVER}\n' >> ${F1}
    echo -e F0='${sf0}'/scripts/${F0name}'\nout=${F0}'.txt >> ${F1}


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

cp -p -f ${dat} ${dir0}/scripts
echo "OGRE structural pipeline setup completed."
