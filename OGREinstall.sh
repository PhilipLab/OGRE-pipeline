#!/usr/bin/env bash

REPO=/Users/mcavoy/repo/OGRE-pipeline/One-Step-General-Registration-and-Extraction-OGRE-pipline

root0=${0##*/}
helpmsg(){
    echo "Required: ${root0} <OGRE directory> -v <version number>"
    echo "    -i --install -install"
    echo "        OGRE will be installed at this location as <install>/<version>."
    echo "        An argument without an option is assumed to be the OGRE directory."
    echo "    -v --version -version"
    echo "        Version number."
    echo "    -h --help -help"
    echo "        Echo this help message."
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi
echo $0 $@

#do not set install;unexpected
unset v 

arg=("$@")
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -i | --install | -install)
            install=${arg[((++i))]}
            #echo "install=$install"
            ;;
        -v | --version | --version)
            version=${arg[((++i))]}
            #echo "version=$version"
            ;;
        -h | --help | -help)
            helpmsg
            exit
            ;;
        *) unexpected+=(${arg[i]})
            ;;
    esac
done

[ -n "${unexpected}" ] && install=(${unexpected[@]})
if [ -z "${install}" ];then
    echo "install not set. Abort!"
    exit
fi
#echo "install=$install"
#echo "version=$version"
id=$install/$version

 
if [ -d "$id" ];then
    #https://stackoverflow.com/questions/18544359/how-do-i-read-user-input-into-a-variable-in-bash
    read -p "$id exists. Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
    #read -p "$id exists. Continue? (Y/N): " confirm && [[ ${confirm^^} == 'YES' ]] || exit 1
fi

mkdir -p $id

files=(OGREcleanSETUP.sh \
       OGREfMRIpipeSETUP.sh \
       OGREmakeregdir.sh \
       OGREstructpipeSETUP.sh \
       dbsipdf2scanlist.py \
       dcm2niix.sh \
       pdf2scanlist.py)
for i in ${files[@]};do
    cp -p $REPO/$i $id
done

mkdir -p $id/HCP/scripts
files=(OGREAtlasRegistrationToMNI152_FLIRTandFNIRT.sh \
       OGREBiasFieldCorrection_sqrtT1wXT1w.sh \
       OGRECreateMyelinMaps.sh \
       OGREDistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased.sh \
       OGREFreeSurfer2CaretConvertAndRegisterNonlinear.sh \
       OGREFreeSurferHiresPial.sh \
       OGREFreeSurferHiresWhite.sh \
       OGREFreeSurferPipeline.sh \
       OGREFreeSurferPipelineBatch.sh \
       OGREGenericfMRIVolumeProcessingPipeline.sh \
       OGREGenericfMRIVolumeProcessingPipelineBatch.sh \
       OGREIntensityNormalization.sh \
       OGREMotionCorrection.sh \
       OGREOneStepResampling.sh \
       OGREPostFreeSurferPipeline.sh \
       OGREPostFreeSurferPipelineBatch.sh \
       OGREPreFreeSurferPipeline.sh \
       OGREPreFreeSurferPipelineBatch.sh \
       OGRESetUpHCPPipeline.sh \
       OGRESmoothingProcess.sh \
       OGRET1w_restore.sh \
       OGRET2wToT1wReg.sh \
       OGREmakeregdir.sh \
       OGREmcflirt.sh)
for i in ${files[@]};do
    cp -p $REPO/HCP/scripts/$i $id/HCP/scripts
done

echo "Installation $id complete." 
