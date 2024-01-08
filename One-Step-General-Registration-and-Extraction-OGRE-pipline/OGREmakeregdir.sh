#!/usr/bin/env bash

STUDYPATH=/Users/Shared/10_Connectivity
T1=1
ATLAS=2

helpmsg(){

    #START231218
    echo "Required: ${root0} <Feat directory>"

    #echo "    -f --feat -feat       REQUIRED. Feat directory."
    #START231219
    echo "    -f --feat -feat       Feat directory. If no option provided, then assumed to be the FEAT directory."
    echo "                          E.g. /Users/Shared/10_Connectivity/derivatives/analysis/sub-1001/sub-1001_model-OGRE-7.4.0/sub-1001_RHflip_susan-6_run-1.feat/"

    #START231218
    #echo "    -s --sub -sub         REQUIRED. Subject name, e.g. 2000. No need to add sub-" 
    #echo "                          Used to find anatomical and other data in BIDS"
    #echo "                      ** FUTURE VERSIONS SHOULD USE REGEXP TO EXTRACT -s FROM -f ** "
    #START231219
    echo "    -s --sub -sub         Subject name, e.g. 2000, is read from the FEAT directory. This option will override that of the FEAT directory." 
    echo "                          Used to find anatomical and other data in BIDS"


    echo "    -y -S --study -study     OPTIONAL. Study path. Default is /Users/Shared/10_Connectivity" 
    echo "                          Syntax: if full path is /Users/Shared/10_Connectivity/10_2000/pipeline7.4.0, STUDYPATH is /Users/Shared/10_Connectivity"  
    echo " "
    echo "      Everything below here is OPTIONAL. Defaults to BIDS based on sub/study info"
    echo "    -t --t1 -t1             T1 resolution (ie FEAT highres). 1 or 2. Default is 1mm."
    echo "                            If 1mm, then MNINonLinear/T1w_restore and MNINonLinear/T1w_restore_brain are used."
    echo "                            If 2mm, then MNINonLinear/Results/T1w_restore.2 and MNINonLinear/Results/T1w_restore_brain.2 are used."
    echo "                                NOTE: MNINonLinear/T1w_restore.2 is not the correct image. It is a so-called subcortical T1 for surface analysis."
    echo "    --t1highreshead -t1highreshead --t1hireshead -t1hireshead"
    echo "                            Input your own whole head T1."
    echo "                            Ex. --t1highreshead /Users/Shared/10_Connectivity/10_1001/pipelineTest7.4.0/MNINonLinear/T1w_restore.nii.gz"
    echo "    --t1highres -t1highres --t1hires -t1hires"
    echo "                            Input your own brain masked T1."
    echo "                            Ex. --t1highres /Users/Shared/10_Connectivity/10_1001/pipelineTest7.4.0/MNINonLinear/T1w_restore_brain.nii.gz"
    echo ""
    echo "    -u --atlas -atlas       Standard image resolution (ie FEAT standard). 1 or 2. Default is 2mm."
    echo "                            If 1mm, then ${FSLDIR}/data/standard/MNI152_T1_1mm and ${FSLDIR}/data/standard/MNI152_T1_1mm_brain are used."
    echo "                            If 2mm, then ${FSLDIR}/data/standard/MNI152_T1_2mm and ${FSLDIR}/data/standard/MNI152_T1_2mm_brain are used."
    echo "    --standardhead -standardhead"
    echo "                            Input your own whole head standard image."
    echo "                            Ex. --standardhead /Users/Shared/10_Connectivity/10_1001/pipelineTest7.4.0/MNINonLinear/T1w_restore.nii.gz"
    echo "    --standard -standard    Input your own brain masked standard image."
    echo "                            Ex. --standard /Users/Shared/10_Connectivity/10_1001/pipelineTest7.4.0/MNINonLinear/T1w_restore_brain.nii.gz"
    echo ""
    echo "    -h --help -help         Echo this help message."
    exit
    }


#echo $0 $@
#arg=($@)
#narg=${#@}
#SUBJECT=;FEATDIR=;idx=0;T1HIGHRESHEAD=;T1HIGHRES=;STANDARDHEAD=;STANDARD=
#if((${#@}<2));then
#    helpmsg
#    exit
#fi
#START231218
if((${#@}<1));then
    helpmsg
    exit
fi
echo $0 $@

#idx=0 #do not set FEATDIR or unexpected
#START231219
#do not set FEATDIR or unexpected

unset SUBJECT T1HIGHRESHEAD T1HIGHRES STANDARDHEAD STANDARD
arg=("$@")


for((i=0;i<${#@};++i));do
    case "${arg[i]}" in



        #-s | --sub | -sub)
        #    SUBJECT=${arg[((++i))]}
        #    echo "SUBJECT=$SUBJECT"
        #    ((idx+=2))
        #    ;;
        #START231219
        -s | --sub | -sub)
            SUBJECT=${arg[((++i))]}
            #echo "SUBJECT=$SUBJECT"
            ;;




        -f | --feat | -feat)
            FEATDIR=${arg[((++i))]}
            #echo "FEATDIR=$FEATDIR"

            #START231219
            #((idx+=2))

            ;;


        -S | -y | --study | -study)
            STUDYPATH=${arg[((++i))]}
            echo "STUDYPATH=$STUDYPATH"

            #START231218
            #((narg-=2))

            ;;
        -t | --t1 | -t1)
            T1=${arg[((++i))]}
            echo "T1=$T1"


            #START231218
            #((narg-=2))

            ;;
        --t1highreshead | -t1highreshead | --t1hireshead | -t1hireshead)
            T1HIGHRESHEAD=${arg[((++i))]}
            echo "T1HIGHRESHEAD=$T1HIGHRESHEAD"

            #START231218
            #((narg-=2))

            ;;
        --t1highres | -t1highres | --t1hires | -t1hires)
            T1HIGHRES=${arg[((++i))]}
            echo "T1HIGHRES=$T1HIGHRES"

            #START231218
            #((narg-=2))

            ;;
        -u | --atlas | -atlas)
            ATLAS=${arg[((++i))]}
            echo "ATLAS=$ATLAS"

            #START231218
            #((narg-=2))

            ;;
        --standardhead | -standardhead)
            STANDARDHEAD=${arg[((++i))]}
            echo "STANDARDHEAD=$STANDARDHEAD"

            #START231218
            #((narg-=2))

            ;;
        --standard | -standard)
            STANDARD=${arg[((++i))]}
            echo "STANDARD=$STANDARD"

            #START231218
            #((narg-=2))

            ;;
        -h | --help | -help)
            helpmsg
            exit
            ;;

        #START231218
        *) unexpected+=(${arg[i]})
            ;;

    esac
done


#if [ -z "${SUBJECT}" ];then
#    echo "Please specify subject number with -s"
#    exit
#fi
#if [ -z "${FEATDIR}" ];then
#    echo "Please specify FEAT directory with -f"
#    exit
#fi
#START231218
[ -n "${unexpected}" ] && FEATDIR+=(${unexpected[@]})
if [ -z "${FEATDIR}" ];then
    echo "Need to provide FEATDIR"
    exit
fi
echo "FEATDIR=$FEATDIR"


#SUBJECT=$(awk -F'/sub-' '{print $2}' <<< "$FEATDIR")
#START231219
if [ -z "${SUBJECT}" ];then
    SUBJECT=$(awk -F'/sub-' '{print $2}' <<< "$FEATDIR")
fi
echo "SUBJECT=$SUBJECT"


# update 231227 to check pipelinedir AND anat dir (default: anat)
OUTDIR=${FEATDIR}/reg
ANATDIR=${STUDYPATH}/derivatives/preprocessed/sub-${SUBJECT}/anat/
PIPEDIR=${STUDYPATH}/derivatives/preprocessed/sub-${SUBJECT}/pipeline7.4.0/MNINonLinear/Results/

if [ -z "${T1HIGHRESHEAD}" ];then
    if((T1==1));then
        if [ -f ${ANATDIR}/sub-${SUBJECT}_T1w_restore.nii.gz ]; then
            T1HIGHRESHEAD=${ANATDIR}/sub-${SUBJECT}_T1w_restore.nii.gz
        elif [ -f ${PIPEDIR}/sub-${SUBJECT}_T1w_restore.nii.gz ]; then
            T1HIGHRESHEAD=${PIPEDIR}/sub-${SUBJECT}_T1w_restore.nii.gz
        else
            echo "T1 not found: ${T1}"
            exit
        fi
    elif((T1==2));then # currently these are in separate locations, but we should probably fix that instead
        if [ -f ${ANATDIR}/sub-${SUBJECT}_T1w_restore.2.nii.gz ]; then
            T1HIGHRESHEAD=${ANATDIR}/sub-${SUBJECT}_T1w_restore.2.nii.gz
        elif [ -f ${PIPEDIR}/sub-${SUBJECT}_T1w_restore.2.nii.gz ]; then
            T1HIGHRESHEAD=${PIPEDIR}/sub-${SUBJECT}_T1w_restore.2.nii.gz
        else
            echo "T1 not found: ${T1}"
            exit
        fi
        #T1HIGHRESHEAD=${STUDYPATH}/derivatives/preprocessed/sub-${SUBJECT}/anat/sub-${SUBJECT}_T1w_restore.2.nii.gz
        #T1HIGHRESHEAD=${STUDYPATH}/derivatives/preprocessed/sub-${SUBJECT}/pipeline7.4.0/MNINonLinear/Results/T1w_restore.2.nii.gz
    else
        echo "Unknown value for T1=${T1}"
        exit
    fi 
fi
if [ -z "${T1HIGHRES}" ];then
    if((T1==1));then
        if [ -f ${ANATDIR}/sub-${SUBJECT}_T1w_restore_brain.nii.gz ]; then
            T1HIGHRES=${ANATDIR}/sub-${SUBJECT}_T1w_restore_brain.nii.gz
        elif [ -f ${PIPEDIR}/sub-${SUBJECT}_T1w_restore_brain.nii.gz ]; then
            T1HIGHRES=${PIPEDIR}/sub-${SUBJECT}_T1w_restore_brain.nii.gz
        else
            echo "T1 not found: ${T1}"
            exit
        fi
    elif((T1==2));then # currently these are in separate locations, but we should probably fix that instead
        if [ -f ${ANATDIR}/sub-${SUBJECT}_T1w_restore.2_brain.nii.gz ]; then
            T1HIGHRES=${ANATDIR}/sub-${SUBJECT}_T1w_restore.2_brain.nii.gz
        elif [ -f ${PIPEDIR}/sub-${SUBJECT}_T1w_restore.2_brain.nii.gz ]; then
            T1HIGHRES=${PIPEDIR}/sub-${SUBJECT}_T1w_restore.2_brain.nii.gz
        else
            echo "T1 not found: ${T1}"
            exit
        fi
        #T1HIGHRESHEAD=${STUDYPATH}/derivatives/preprocessed/sub-${SUBJECT}/anat/sub-${SUBJECT}_T1w_restore.2.nii.gz
        #T1HIGHRESHEAD=${STUDYPATH}/derivatives/preprocessed/sub-${SUBJECT}/pipeline7.4.0/MNINonLinear/Results/T1w_restore.2.nii.gz
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
    #mkdir -p ${OUTDIR}_${THEDATE}
    #mv ${OUTDIR}/ ${OUTDIR}_${THEDATE}/
    #rm -rf ${OUTDIR}
fi

mkdir -p ${OUTDIR}

#START220510
if [ ! -f ${FEATDIR}/example_func.nii.gz ];then
    echo "ERROR: ${FEATDIR}/example_func.nii.gz does not exist. Abort!"
    exit
fi
cp -p ${FEATDIR}/example_func.nii.gz ${OUTDIR}/example_func.nii.gz
cp $STANDARDHEAD ${OUTDIR}/standard_head.nii.gz
cp $STANDARD ${OUTDIR}/standard.nii.gz
cp -p $T1HIGHRESHEAD ${OUTDIR}/highres_head.nii.gz # this is still broken under BIDS
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
echo "Starting transformations for "${FEATDIR}

#${FSLDIR}/bin/flirt -in ${OUTDIR}/highres.nii.gz -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz -out ${OUTDIR}/highres2standard.nii.gz -omat ${OUTDIR}/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear
#START230310
${FSLDIR}/bin/flirt -in ${OUTDIR}/highres.nii.gz -ref ${OUTDIR}/standard.nii.gz -out ${OUTDIR}/highres2standard.nii.gz -omat ${OUTDIR}/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear


# make EF2HR
${FSLDIR}/bin/epi_reg --epi=${OUTDIR}/example_func --t1=${OUTDIR}/highres_head --t1brain=${OUTDIR}/highres --out=${OUTDIR}/example_func2highres
# make EF2S
${FSLDIR}/bin/convert_xfm -omat ${OUTDIR}/example_func2standard.mat -concat ${OUTDIR}/highres2standard.mat ${OUTDIR}/example_func2highres.mat
echo "Registration complete for "${FEATDIR}
