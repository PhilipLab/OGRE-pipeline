#!/usr/bin/env bash

STUDYPATH=/Users/Shared/10_Connectivity
PIPE=pipeline7.3.2
T1=1
ATLAS=2

helpmsg(){
    echo "    -s --sub -sub           Subject name, e.g. 10_2000." 
    echo "                            If the option is not used, the first argument is assumed to be the subject name." 
    echo "    -r --run -run           Run name, e.g. run1_LH." 
    echo "                            If the option is not used, the second argument is assumed to be the run name." 
    echo "    -a --analysis -analysis Optional. Analysis name is the suffix on the saved directory, e.g. basic." 
    echo "                            If the option is not used, the third argument is assumed to be the analysis name." 
    echo ""
    echo "    -S --study -study       Optional. STUDYPATH. Default is /Users/Shared/10_Connectivity" 
    echo "                            Syntax: if full path is "/Users/Shared/10_Connectivity/10_2000/pipeline7.3.2", STUDYPATH is /Users/Shared/10_Connectivity   
    echo "    -p --pipe -pipe         Optional. PIPELINE_DIRECTORY. Default is pipeline7.3.2." 
    echo "                            Syntax: if full path is "/Users/Shared/10_Connectivity/10_2000/pipeline7.3.2", PIPELINE_DIRECTORY is 7.3.2
    echo ""
    echo "    -t --t1 -t1             T1 resolution (ie FEAT highres). 1 or 2. Default is 1mm."
    echo "                            If 1mm, then MNINonLinear/T1w_restore and MNINonLinear/T1w_restore_brain are used."
    echo "                            If 2mm, then MNINonLinear/Results/T1w_restore.2 and MNINonLinear/Results/T1w_restore_brain.2 are used."
    echo "                                NOTE: MNINonLinear/T1w_restore.2 is not the correct image. It is a so-called subcortical T1 for surface analysis."
    echo "    --t1highreshead -t1highreshead --t1hireshead -t1hireshead"
    echo "                            Input your own whole head T1."
    echo "                            Ex. --t1highreshead /Users/Shared/10_Connectivity/10_1001/pipelineTest7.3.2/MNINonLinear/T1w_restore.nii.gz"
    echo "    --t1highres -t1highres --t1hires -t1hires"
    echo "                            Input your own brain masked T1."
    echo "                            Ex. --t1highres /Users/Shared/10_Connectivity/10_1001/pipelineTest7.3.2/MNINonLinear/T1w_restore_brain.nii.gz"
    echo ""
    echo "    -u --atlas -atlas       Standard image resolution (ie FEAT standard). 1 or 2. Default is 2mm."
    echo "                            If 1mm, then ${FSLDIR}/data/standard/MNI152_T1_1mm and ${FSLDIR}/data/standard/MNI152_T1_1mm_brain are used."
    echo "                            If 2mm, then ${FSLDIR}/data/standard/MNI152_T1_2mm and ${FSLDIR}/data/standard/MNI152_T1_2mm_brain are used."
    echo "    --standardhead -standardhead"
    echo "                            Input your own whole head standard image."
    echo "                            Ex. --standardhead /Users/Shared/10_Connectivity/10_1001/pipelineTest7.3.2/MNINonLinear/T1w_restore.nii.gz"
    echo "    --standard -standard    Input your own brain masked standard image."
    echo "                            Ex. --standard /Users/Shared/10_Connectivity/10_1001/pipelineTest7.3.2/MNINonLinear/T1w_restore_brain.nii.gz"
    echo ""
    echo "    -h --help -help         Echo this help message."
    exit
    }
echo $0 $@
arg=($@)
narg=${#@}

SUBNAME=;RUNNAME=;ANALYSISNAME=;idx=0;T1HIGHRESHEAD=;T1HIGHRES=;STANDARDHEAD=;STANDARD=

if((${#@}<2));then
    helpmsg
    exit
fi
for((i=0;i<${#@};++i));do
    case "${arg[i]}" in
        -s | --sub | -sub)
            SUBNAME=${arg[((++i))]}
            echo "SUBNAME=$SUBNAME"
            ((idx+=2))
            ;;
        -r | --run | -run)
            RUNNAME=${arg[((++i))]}
            echo "RUNNAME=$RUNNAME"
            ((idx+=2))
            ;;
        -a | --analysis | -analysis)
            ANALYSISNAME=${arg[((++i))]}
            echo "ANALYSISNAME=$ANALYSISNAME"
            ;;
        -S | --study | -study)
            STUDYPATH=${arg[((++i))]}
            echo "STUDYPATH=$STUDYPATH"
            ((narg-=2))
            ;;
        -p | --pipe | -pipe)
            PIPE=${arg[((++i))]}
            echo "PIPE=$PIPE"
            ((narg-=2))
            ;;
        -t | --t1 | -t1)
            T1=${arg[((++i))]}
            echo "T1=$T1"
            ((narg-=2))
            ;;
        --t1highreshead | -t1highreshead | --t1hireshead | -t1hireshead)
            T1HIGHRESHEAD=${arg[((++i))]}
            echo "T1HIGHRESHEAD=$T1HIGHRESHEAD"
            ((narg-=2))
            ;;
        --t1highres | -t1highres | --t1hires | -t1hires)
            T1HIGHRES=${arg[((++i))]}
            echo "T1HIGHRES=$T1HIGHRES"
            ((narg-=2))
            ;;
        -u | --atlas | -atlas)
            ATLAS=${arg[((++i))]}
            echo "ATLAS=$ATLAS"
            ((narg-=2))
            ;;
        --standardhead | -standardhead)
            STANDARDHEAD=${arg[((++i))]}
            echo "STANDARDHEAD=$STANDARDHEAD"
            ((narg-=2))
            ;;
        --standard | -standard)
            STANDARD=${arg[((++i))]}
            echo "STANDARD=$STANDARD"
            ((narg-=2))
            ;;
        -h | --help | -help)
            helpmsg
            exit
            ;;

        ##START230314
        #*) unused[((j++))]]=${arg[((i))]} 
        #    exit
        #    ;;

    esac
done

if [ -z "${SUBNAME}" ];then
    SUBNAME=$1
    ((++idx))
    echo "SUBNAME=${SUBNAME}"
fi
if [ -z "${RUNNAME}" ];then
    if((${#@}>=((idx+1))));then
        RUNNAME=${arg[idx]}
        ((++idx))
        echo "RUNNAME=${RUNNAME}"
    else
        echo "Please specify run name with -r | --run"
        exit
    fi
fi


#if [ -z "${ANALYSISNAME}" ];then
#    ((${narg}>=((idx+1)))) && ANALYSISNAME=${RUNNAME}_${arg[idx]} || ANALYSISNAME=${RUNNAME}
#    echo "ANALYSISNAME=$ANALYSISNAME"
#fi
#START230510
if [ -z "${ANALYSISNAME}" ];then
    ((${narg}>=((idx+1)))) && ANALYSISNAME=${RUNNAME}_${arg[idx]} || ANALYSISNAME=${RUNNAME}
    runanal=$ANALYSISNAME
    echo "ANALYSISNAME=$ANALYSISNAME"
else
    runanal=${RUNNAME}_${ANALYSISNAME}
fi

SUBJDIR=${STUDYPATH}/${SUBNAME}/${PIPE}
echo "SUBJDIR=$SUBJDIR"

#FEATDIR=${SUBJDIR}/model/${ANALYSISNAME}.feat
#START230510
FEATDIR=${SUBJDIR}/model/${runanal}.feat

echo "FEATDIR=${FEATDIR}"
OUTDIR=${FEATDIR}/reg
echo "OUTDIR=${OUTDIR}"

if [ -z "${T1HIGHRESHEAD}" ];then
    if((T1==1));then
        T1HIGHRESHEAD=${SUBJDIR}/MNINonLinear/T1w_restore.nii.gz
    elif((T1==2));then
        T1HIGHRESHEAD=${SUBJDIR}/MNINonLinear/Results/T1w_restore.2.nii.gz
    else
        echo "Unknown value for T1=${T1}"
        exit
    fi 
fi
if [ -z "${T1HIGHRES}" ];then
    if((T1==1));then
        T1HIGHRES=${SUBJDIR}/MNINonLinear/T1w_restore_brain.nii.gz
    elif((T1==2));then
        T1HIGHRES=${SUBJDIR}/MNINonLinear/Results/T1w_restore_brain.2.nii.gz
    else
        echo "Unknown value for T1=${T1}"
        exit
    fi
fi
if [ -z "${STANDARDHEAD}" ];then
    if((ATLAS==1));then
        STANDARDHEAD=${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz
    elif((ATLAS==2));then
        STANDARDHEAD=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
    else
        echo "Unknown value for ATLAS=${ATLAS}"
        exit
    fi
fi
if [ -z "${STANDARD}" ];then
    if((ATLAS==1));then
        STANDARD=${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz
    elif((ATLAS==2));then
        STANDARD=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
    else
        echo "Unknown value for ATLAS=${ATLAS}"
        exit
    fi
fi


# First, slide any preexisting reg/reg_standard folder off to to a datestamped backup
#REGSTD=${SUBJDIR}/model/${ANALYSISNAME}.feat/reg
THEDATE=`date +%y%m%d_%H%M`
if [[ -d "$OUTDIR" ]];then
    echo "storing ${OUTDIR} as ${THEDATE}"
    mv ${OUTDIR} ${OUTDIR}_${THEDATE}
fi
#if [[ -d "$REGSTD" ]];then
#    echo "storing ${REGSTD} as ${THEDATE}"
#    mv ${REGSTD} ${REGSTD}_${THEDATE}
#fi

mkdir -p ${OUTDIR}

#START220510
if [ ! -f ${FEATDIR}/example_func.nii.gz ];then
    echo "ERROR: ${FEATDIR}/example_func.nii.gz does not exist. Abort!"
    exit
fi
cp -p ${FEATDIR}/example_func.nii.gz ${OUTDIR}/example_func.nii.gz

cp $STANDARDHEAD ${OUTDIR}/standard_head.nii.gz
cp $STANDARD ${OUTDIR}/standard.nii.gz
cp -p $T1HIGHRESHEAD ${OUTDIR}/highres_head.nii.gz 
cp -p $T1HIGHRES ${OUTDIR}/highres.nii.gz 

##cp -p ${SUBJDIR}/MNINonLinear/Results/${RUNNAME}/example_func2standard_susan4.mat ${OUTDIR}/example_func2standard.mat
##cp -p ${SUBJDIR}/MNINonLinear/Results/${RUNNAME}/highres2standard.mat ${OUTDIR}/highres2standard.mat
## cp -p ${SUBJDIR}/MNINonLinear/Results/${RUNNAME}/example_func_susan4.nii.gz ${OUTDIR}/example_func.nii.gz 
##cp -p ${FEATDIR}/example_func.nii.gz ${OUTDIR}/example_func.nii.gz;
##cp -p ${SUBJDIR}/MNINonLinear/T1w_restore.nii.gz ${OUTDIR}/highres_head.nii.gz # 1mm
##cp -p ${SUBJDIR}/MNINonLinear/T1w_restore_brain.nii.gz ${OUTDIR}/highres.nii.gz # Jan 2023: 1mm
##cp ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${OUTDIR}/standard_head.nii.gz
##cp ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz ${OUTDIR}/standard.nii.gz

# make HR2STD
echo "Starting transformations for "${SUBNAME}", "${RUNNAME}", "${ANALYSISNAME}

#${FSLDIR}/bin/flirt -in ${OUTDIR}/highres.nii.gz -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz -out ${OUTDIR}/highres2standard.nii.gz -omat ${OUTDIR}/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear
#START230310
${FSLDIR}/bin/flirt -in ${OUTDIR}/highres.nii.gz -ref ${OUTDIR}/standard.nii.gz -out ${OUTDIR}/highres2standard.nii.gz -omat ${OUTDIR}/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear


# make EF2HR
${FSLDIR}/bin/epi_reg --epi=${OUTDIR}/example_func --t1=${OUTDIR}/highres_head --t1brain=${OUTDIR}/highres --out=${OUTDIR}/example_func2highres
# make EF2S
${FSLDIR}/bin/convert_xfm -omat ${OUTDIR}/example_func2standard.mat -concat ${OUTDIR}/highres2standard.mat ${OUTDIR}/example_func2highres.mat
echo "Registration complete for "${SUBNAME}", "${RUNNAME}", "${ANALYSISNAME}
