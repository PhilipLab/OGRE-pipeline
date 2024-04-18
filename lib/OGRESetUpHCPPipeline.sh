#!/usr/bin/env bash 

[ -z ${HCPDIR+x} ] && export HCPDIR=/Users/Shared/pipeline/HCP

[ -z ${FSLDIR+x} ] && export FSLDIR=/usr/local/fsl

[ -z ${FREESURFDIR+x} ] && export FREESURFDIR=/Applications/freesurfer
[ -z ${FREESURFVER+x} ] && export FREESURFVER=7.4.0
if [ -z ${FREESURFER_HOME+x} ];then
    echo "FREESURFER_HOME not set. Setting to FREESURFER_HOME=${FREESURFDIR}/${FREESURFVER}"
    export FREESURFER_HOME=${FREESURFDIR}/${FREESURFVER}
fi

echo "    **** OGRESetUpHCPPipeline.sh FREESURFER_HOME=${FREESURFER_HOME} ****"
echo "    **** OGRESetUpHCPPipeline.sh OGREDIR=${OGREDIR} ****"

#echo "This script must be SOURCED to correctly setup the environment prior to running any of the other HCP scripts contained here"

# Set up FSL (if not already done so in the running environment)
source ${FSLDIR}/etc/fslconf/fsl.sh

# Let FreeSurfer know what version of FSL to use
# FreeSurfer uses FSL_DIR instead of FSLDIR to determine the FSL version
export FSL_DIR="${FSLDIR}"

# Set up FreeSurfer (if not already done so in the running environment)
source ${FREESURFER_HOME}/SetUpFreeSurfer.sh > /dev/null 2>&1

# Set up specific environment variables for the HCP Pipeline
export HCPPIPEDIR=$HCPDIR/HCPpipelines-3.27.0

export CARET7DIR=/Users/Shared/pipeline/HCP/workbench-mac/bin_macosx64

export MSMBINDIR=${HOME}/pipeline_tools/MSM-2015.01.14
export MSMCONFIGDIR=${HCPPIPEDIR}/MSMConfig
export MATLAB_COMPILER_RUNTIME=/media/myelin/brainmappers/HardDrives/1TB/MATLAB_Runtime/v901
export FSL_FIXDIR=/media/myelin/aahana/fix1.06

export HCPPIPEDIR_Templates=${HCPPIPEDIR}/global/templates
export HCPPIPEDIR_Bin=${HCPPIPEDIR}/global/binaries
export HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config

export HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts
export HCPPIPEDIR_FS=${HCPPIPEDIR}/FreeSurfer/scripts
export HCPPIPEDIR_PostFS=${HCPPIPEDIR}/PostFreeSurfer/scripts
export HCPPIPEDIR_fMRISurf=${HCPPIPEDIR}/fMRISurface/scripts
export HCPPIPEDIR_fMRIVol=${HCPPIPEDIR}/fMRIVolume/scripts
export HCPPIPEDIR_tfMRI=${HCPPIPEDIR}/tfMRI/scripts
export HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts
export HCPPIPEDIR_dMRITract=${HCPPIPEDIR}/DiffusionTractography/scripts
export HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts
export HCPPIPEDIR_tfMRIAnalysis=${HCPPIPEDIR}/TaskfMRIAnalysis/scripts

#try to reduce strangeness from locale and other environment settings
export LC_ALL=C
export LANGUAGE=C
#POSIXLY_CORRECT currently gets set by many versions of fsl_sub, unfortunately, but at least don't pass it in if the user has it set in their usual environment
unset POSIXLY_CORRECT
