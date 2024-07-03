#!/usr/bin/env bash

T1=1
ATLAS=2
OVERWRITE=0

#START240417
#Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2 7.4.0 7.4.1
[ -z ${FREESURFVER+x} ] && FREESURFVER=7.4.1

helpmsg(){
    echo "Builds reg directory within a .feat folder, from OGRE results."
    echo "Defaults will work correctly if your .feat folder is in STUDY/derivatives/analysis/sub-X and your OGRE output is in STUDY/derivatives/preprocessed/sub-X"
    echo "Required: ${root0} <Feat directory>:"
    echo "    -f --feat -feat       Feat directory. If no -argument provided, then input is assumed to be this."
    echo "                          E.g. /Users/Shared/10_Connectivity/derivatives/analysis/sub-1001/sub-1001_model-OGRE-7.4.1/sub-1008_task-drawLH_run-1.feat"
    echo "                          If you want the script to look for a relative path in current directory (rather than a full path), omit the final .feat"
    echo " "
    echo "  Everything below here is OPTIONAL. Defaults to pulling from your feat directory path & assuming it is in BIDS "
    echo "    -v --overwrite        Flag. If set, overwrite existing makeregdir output. Otherwise, if makeregdir output exists, script does nothing."
    echo "    -s --sub -sub         Subject name, e.g. sub-2000. This option will override that of the FEAT directory." 
    echo "                          Used to find anatomical and other data in BIDS"
    echo "    -o --ogredir          Specify location of OGRE subject directory (i.e. dir that contains subdirectories pipelineVVV, func, anat...)"

    echo " "

    #START240417
    echo "    -V --VERSION -VERSION --FREESURFVER -FREESURFVER --freesurferVersion -freesurferVersion"
    echo "        5.3.0-HCP, 7.2.0, 7.3.2, 7.4.0 or 7.4.1. Default is 7.4.1 unless set elsewhere via variable FREESURFVER."


    echo "    -t --t1 -t1             T1 resolution (ie FEAT highres). 1 or 2. Default is 1mm."
    echo "                            If 1mm, then MNINonLinear/T1w_restore and MNINonLinear/T1w_restore_brain are used (or equivalent in "func" dir)"

    #echo "                            If 2mm, then MNINonLinear/Results/T1w_restore.2 and MNINonLinear/Results/T1w_restore_brain.2 are used."
    #START240417
    echo "                            If 2mm, then Results/T1w_restore.2 and Results/T1w_restore_brain.2 are used."

    echo "                                NOTE: MNINonLinear/T1w_restore.2 is not the correct image. It is a so-called subcortical T1 for surface analysis."
    echo "    --t1highreshead -t1highreshead --t1hireshead -t1hireshead"
    echo "                            Input your own whole head T1."
    echo "                            Ex. --t1highreshead /Users/Shared/10_Connectivity/sub-1001/pipeline7.4.1/func/sub-1001_OGRE-preproc_desc-restore_T1w.nii.gz"
    echo "    --t1highres -t1highres --t1hires -t1hires"
    echo "                            Input your own brain masked T1."
    echo "                            Ex. --t1highres /Users/Shared/10_Connectivity/10_1001/pipelineTest7.4.0/MNINonLinear/T1w_restore_brain.nii.gz"
    echo ""
    echo "    -u --atlas -atlas       Standard image resolution (ie FEAT standard). 1 or 2. Default is 2mm."
    echo "                            If 1mm, then FSLDIR/data/standard/MNI152_T1_1mm and FSLDIR/data/standard/MNI152_T1_1mm_brain are used."
    echo "                            If 2mm, then FSLDIR/data/standard/MNI152_T1_2mm and FSLDIR/data/standard/MNI152_T1_2mm_brain are used."
    echo "    --standardhead -standardhead"
    echo "                            Input your own whole head standard image."
    echo "                            Ex. --standardhead /Users/Shared/10_Connectivity/sub-1001/pipelineTest7.4.0/MNINonLinear/T1w_restore.nii.gz"
    echo "    --standard -standard    Input your own brain masked standard image."
    echo "                            Ex. --standard /Users/Shared/10_Connectivity/sub-1001/pipelineTest7.4.0/MNINonLinear/T1w_restore_brain.nii.gz"
    echo ""
    echo "    -h --help -help         Echo this help message."
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi
echo $0 $@

#do not set FEATDIR or unexpected
unset SUBJECT T1HIGHRESHEAD T1HIGHRES STANDARDHEAD STANDARD

arg=("$@")
for((i=0;i<${#@};++i));do
    case "${arg[i]}" in
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
        -v | --v | --overwrite | -overwrite)
            OVERWRITE=1
            ;;
        -o | --o | --ogredir | -ogredir)
            OGRESUBDIR=${arg[((++i))]}
            ;;
        #START240417
        -V | --VERSION | -VERSION | --FREESURFVER | -FREESURFVER | --freesurferVersion | -freesurferVersion)
            FREESURFVER=${arg[((++i))]}
            echo "FREESURFVER=$FREESURFVER"
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

#START240417
if [[ "${FREESURFVER}" != "5.3.0-HCP" && "${FREESURFVER}" != "7.2.0" && "${FREESURFVER}" != "7.3.2" && "${FREESURFVER}" != "7.4.0" && "${FREESURFVER}" != "7.4.1" ]];then
    echo "Unknown version of freesurfer. FREESURFVER=${FREESURFVER}"
    exit
fi


[ -n "${unexpected}" ] && FEATDIR+=(${unexpected[@]})
if [ -z "${FEATDIR}" ];then
    echo "Error in OGREmakeregdir.sh: must provide FEATDIR"
    exit
fi

# Ben update 240521 to handle either full path or relative file
if [[ $FEATDIR == *".feat" ]];then # if ends in .feat, reduces it to relative file 
    FEATDIR_LONG=${FEATDIR}
    DIRTEMP=${FEATDIR##*/} #everything after the last /
    FEATDIR_SHORT=${DIRTEMP%%.*} #everthing before the last .
else # if a relative path, then get info from current directory location (which should be a subject dir)
    CURDIR=`pwd`
    DERIVDIR="${CURDIR%%derivatives*}derivatives"
    TEMPSUBJECT=${CURDIR##*/} #everything after the last /
    SUBJECT=${TEMPSUBJECT%%_*} #everthing before the first _
    FEATDIR_LONG=${DERIVDIR}/analysis/${SUBJECT}/${SUBJECT}_model-OGRE/${FEATDIR}.feat
    FEATDIR_SHORT=${FEATDIR}
fi

#echo "FEATDIR_LONG=$FEATDIR_LONG"
#echo "FEATDIR_SHORT=$FEATDIR_SHORT"

if [ -z "${SUBJECT}" ];then
    #SUBJECT=$(awk -F'/sub-' '{print $2}' <<< "$FEATDIR")
    TEMPSUBJECT=${FEATDIR_SHORT##*/} #everything after the last /
    SUBJECT=${TEMPSUBJECT%%_*} #everthing before the first _
fi
echo "SUBJECT=$SUBJECT"

if [ -z "${OGRESUBDIR}" ]; then
    STUDYPATH=${FEATDIR_LONG%%/derivatives*}
    DERIVDIR="${FEATDIR_LONG%%derivatives*}derivatives"
    OGRESUBDIR=${DERIVDIR}/preprocessed/${SUBJECT}
fi

ANATDIR=${OGRESUBDIR}/anat
MNLDIR=${OGRESUBDIR}/pipeline${FREESURFVER}/MNINonLinear
OUTDIR=${FEATDIR_LONG}/reg

echo "OUTDIR=$OUTDIR"

MRDFILE="${OUTDIR}/makeregdir.txt"
if [ -f $MRDFILE ];then
    echo "Makeregdir output already exists; aborted."
    exit
fi

exit
#echo $DERIVDIR

if [ -z "${T1HIGHRESHEAD}" ];then
    if((T1==1));then

        #START240519
        t1bids=${ANATDIR}/${SUBJECT}_OGRE-preproc_desc-restore_T1w.nii.gz
        t1ogre=${MNLDIR}/T1w_restore.nii.gz
        if [ -f "${t1bids}" ];then
            T1HIGHRESHEAD=${t1bids}
        elif [ -f "${t1ogre}" ];then
            T1HIGHRESHEAD=${t1ogre}
        else
            echo -e "T1 head 1mm not found.Looked for\n    ${t1bids}\n    ${t1ogre}"
            exit
        fi


    elif((T1==2));then # currently these are in separate locations, but we should probably fix that instead
        if [ -f ${ANATDIR}/sub-${SUBJECT}_T1w_restore.2.nii.gz ]; then
            T1HIGHRESHEAD=${ANATDIR}/sub-${SUBJECT}_OGRE-preproc_desc-restore_res-2_T1w.nii.gz
        elif [ -f ${MNLDIR}/T1w_restore.2.nii.gz ]; then
            T1HIGHRESHEAD=${MNLDIR}/T1w_restore.2.nii.gz
        else
            echo "T1 head 2mm not found: ${T1}"
            exit
        fi
    else
        echo "Unknown value for T1=${T1}"
        exit
    fi 
fi
if [ -z "${T1HIGHRES}" ];then
    if((T1==1));then

        #START240519
        t1bids=${ANATDIR}/${SUBJECT}_OGRE-preproc_desc-restore_T1w_brain.nii.gz
        t1ogre=${MNLDIR}/T1w_restore_brain.nii.gz
        if [ -f "${t1bids}" ];then
            T1HIGHRES=${t1bids}
        elif [ -f "${t1ogre}" ];then
            T1HIGHRES=${t1ogre}
        else
            echo -e "T1 brain 1mm not found.Looked for\n    ${t1bids}\n    ${t1ogre}"
            exit
        fi

    elif((T1==2));then # currently these are in separate locations, but we should probably fix that instead
        if [ -f ${ANATDIR}/sub-${SUBJECT}_T1w_restore.2_brain.nii.gz ]; then
            T1HIGHRES=${ANATDIR}/sub-${SUBJECT}_T1w_restore.2_brain.nii.gz
        elif [ -f ${MNLDIR}/T1w_restore.2_brain.nii.gz ]; then
            T1HIGHRES=${MNLDIR}/T1w_restore.2_brain.nii.gz
        else
            echo "T1 brain 2mm not found: ${T1}"
            exit
        fi
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
    echo "Reg already found in ${FEATDIR_LONG}. Backing up old ${OUTDIR} as ${THEDATE}"
    mv ${OUTDIR} ${OUTDIR}_${THEDATE}
    #mkdir -p ${OUTDIR}_${THEDATE}
    #mv ${OUTDIR}/ ${OUTDIR}_${THEDATE}/
    #rm -rf ${OUTDIR}
fi

# copy motion correction - DOES NOT WORK b/c feat will create a brand new confoundevs.txtß
# MOCOFILE=${MNLDIR}/../${FEATDIR}_bold/MotionCorrection/${FEATDIR}_bold_mc.par
# echo "MOCINPUT = ${MOCOFILE}"
# cp -fp ${MOCOFILE} ${FEATPATH}/confoundevs.txt

mkdir -p ${OUTDIR}

#if [ ! -f ${FEATDIR}/example_func.nii.gz ];then
#    echo "ERROR: ${FEATDIR}/example_func.nii.gz does not exist. Abort!"
#    exit
#fi
#cp -p ${FEATDIR}/example_func.nii.gz ${OUTDIR}/example_func.nii.gz
#START240519
if [ ! -f ${FEATDIR_LONG}/example_func.nii.gz ];then
    echo "ERROR: ${FEATDIR_LONG}/example_func.nii.gz does not exist. Abort!"
    exit
fi
cp -p ${FEATDIR_LONG}/example_func.nii.gz ${OUTDIR}/example_func.nii.gz




cp $STANDARDHEAD ${OUTDIR}/standard_head.nii.gz
cp $STANDARD ${OUTDIR}/standard.nii.gz
cp -p $T1HIGHRESHEAD ${OUTDIR}/highres_head.nii.gz # this is still broken under BIDS
cp -p $T1HIGHRES ${OUTDIR}/highres.nii.gz 

# make HR2STD
echo "Starting transformations for "${FEATDIR_LONG}

${FSLDIR}/bin/flirt -in ${OUTDIR}/highres.nii.gz -ref ${OUTDIR}/standard.nii.gz -out ${OUTDIR}/highres2standard.nii.gz -omat ${OUTDIR}/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear

# make EF2HR
${FSLDIR}/bin/epi_reg --epi=${OUTDIR}/example_func --t1=${OUTDIR}/highres_head --t1brain=${OUTDIR}/highres --out=${OUTDIR}/example_func2highres
# make EF2S
${FSLDIR}/bin/convert_xfm -omat ${OUTDIR}/example_func2standard.mat -concat ${OUTDIR}/highres2standard.mat ${OUTDIR}/example_func2highres.mat
echo "Registration complete for "${FEATDIR_LONG}

echo "Registration folder created by OGREmakeregdir.sh on ${THEDATE}" > ${MRDFILE}
chmod 775 ${MRDFILE}