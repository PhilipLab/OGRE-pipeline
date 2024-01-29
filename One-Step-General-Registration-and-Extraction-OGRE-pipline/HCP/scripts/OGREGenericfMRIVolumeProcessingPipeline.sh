#!/usr/bin/env bash 
set -e

#P0=${HCPMOD}/OGREDistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased.sh
#P1=${HCPMOD}/OGREOneStepResampling.sh
#P2=${HCPMOD}/OGREIntensityNormalization.sh
#P3=${HCPMOD}/OGREMotionCorrection.sh
#START240111
P0=${OGREDIR}/HCP/scripts/OGREDistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased.sh
P1=${OGREDIR}/HCP/scripts/OGREOneStepResampling.sh
P2=${OGREDIR}/HCP/scripts/OGREIntensityNormalization.sh
P3=${OGREDIR}/HCP/scripts/OGREMotionCorrection.sh

echo "******  START $0 ******"

do_GradientDistortionCorrection=1
do_MotionCorrection=1
do_P0=1
do_P1=1
do_P2=1

# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP) , gradunwarp (HCP version 1.0.2) 
#  environment: use SetUpHCPPipeline.sh  (or individually set FSLDIR, FREESURFER_HOME, HCPPIPEDIR, PATH - for gradient_unwarp.py)

########################################## PIPELINE OVERVIEW ########################################## 

# TODO

########################################## OUTPUT DIRECTORIES ########################################## 

# TODO

# --------------------------------------------------------------------------------
#  Load Function Libraries
# --------------------------------------------------------------------------------

source $HCPPIPEDIR/global/scripts/log.shlib  # Logging related functions
source $HCPPIPEDIR/global/scripts/opts.shlib # Command line option functions

################################################ SUPPORT FUNCTIONS ##################################################

# --------------------------------------------------------------------------------
#  Usage Description Function
# --------------------------------------------------------------------------------

show_usage() {
    echo "Usage information To Be Written"
    exit 1
}

# --------------------------------------------------------------------------------
#   Establish tool name for logging
# --------------------------------------------------------------------------------
#log_SetToolName "GenericfMRIVolumeProcessingPipeline.sh"
#START221103
log_SetToolName "$0"

################################################## OPTION PARSING #####################################################

opts_ShowVersionIfRequested $@

if opts_CheckForHelpRequest $@; then
    show_usage
fi

log_Msg "Parsing Command Line Options"

# parse arguments
Path=`opts_GetOpt1 "--path" $@`
log_Msg "Path: ${Path}"

Subject=`opts_GetOpt1 "--subject" $@`
log_Msg "Subject: ${Subject}"

NameOffMRI=`opts_GetOpt1 "--fmriname" $@`
log_Msg "NameOffMRI: ${NameOffMRI}"

fMRITimeSeries=`opts_GetOpt1 "--fmritcs" $@`
log_Msg "fMRITimeSeries: ${fMRITimeSeries}"

fMRIScout=`opts_GetOpt1 "--fmriscout" $@`
log_Msg "fMRIScout: ${fMRIScout}"

SpinEchoPhaseEncodeNegative=`opts_GetOpt1 "--SEPhaseNeg" $@`
log_Msg "SpinEchoPhaseEncodeNegative: ${SpinEchoPhaseEncodeNegative}"

SpinEchoPhaseEncodePositive=`opts_GetOpt1 "--SEPhasePos" $@`
log_Msg "SpinEchoPhaseEncodePositive: ${SpinEchoPhaseEncodePositive}"

MagnitudeInputName=`opts_GetOpt1 "--fmapmag" $@`  # Expects 4D volume with two 3D timepoints
log_Msg "MagnitudeInputName: ${MagnitudeInputName}"

PhaseInputName=`opts_GetOpt1 "--fmapphase" $@`  
log_Msg "PhaseInputName: ${PhaseInputName}"

GEB0InputName=`opts_GetOpt1 "--fmapgeneralelectric" $@`
log_Msg "GEB0InputName: ${GEB0InputName}"

EchoSpacing=`opts_GetOpt1 "--echospacing" $@`  # *Effective* Echo Spacing of fMRI image, in seconds
log_Msg "EchoSpacing: ${EchoSpacing}"

deltaTE=`opts_GetOpt1 "--echodiff" $@`  
log_Msg "deltaTE: ${deltaTE}"

UnwarpDir=`opts_GetOpt1 "--unwarpdir" $@`  
log_Msg "UnwarpDir: ${UnwarpDir}"

FinalfMRIResolution=`opts_GetOpt1 "--fmrires" $@`  
log_Msg "FinalfMRIResolution: ${FinalfMRIResolution}"

# FIELDMAP, SiemensFieldMap, GeneralElectricFieldMap, or TOPUP
# Note: FIELDMAP and SiemensFieldMap are equivalent
DistortionCorrection=`opts_GetOpt1 "--dcmethod" $@`
log_Msg "DistortionCorrection: ${DistortionCorrection}"

BiasCorrection=`opts_GetOpt1 "--biascorrection" $@`
# Convert BiasCorrection value to all UPPERCASE (to allow the user the flexibility to use NONE, None, none, legacy, Legacy, etc.)
BiasCorrection="$(echo ${BiasCorrection} | tr '[:lower:]' '[:upper:]')"
log_Msg "BiasCorrection: ${BiasCorrection}"

GradientDistortionCoeffs=`opts_GetOpt1 "--gdcoeffs" $@`  
log_Msg "GradientDistortionCoeffs: ${GradientDistortionCoeffs}"

TopupConfig=`opts_GetOpt1 "--topupconfig" $@`  # NONE if Topup is not being used
log_Msg "TopupConfig: ${TopupConfig}"

dof=`opts_GetOpt1 "--dof" $@`
dof=`opts_DefaultOpt $dof 6`
log_Msg "dof: ${dof}"

RUN=`opts_GetOpt1 "--printcom" $@`  # use ="echo" for just printing everything and not running the commands (default is to run)
log_Msg "RUN: ${RUN}"

#NOTE: the jacobian option only applies the jacobian of the distortion corrections to the fMRI data, and NOT from the nonlinear T1 to template registration
UseJacobian=`opts_GetOpt1 "--usejacobian" $@`
# Convert UseJacobian value to all lowercase (to allow the user the flexibility to use True, true, TRUE, False, False, false, etc.)
UseJacobian="$(echo ${UseJacobian} | tr '[:upper:]' '[:lower:]')"
log_Msg "UseJacobian: ${UseJacobian}"

MotionCorrectionType=`opts_GetOpt1 "--mctype" $@`  # use = "FLIRT" to run FLIRT-based mcflirt_acc.sh, or "MCFLIRT" to run MCFLIRT-based mcflirt.sh
MotionCorrectionType=`opts_DefaultOpt $MotionCorrectionType MCFLIRT` #use mcflirt by default

Analysis=`opts_GetOpt1 "--analysis" $@`  
log_Msg "Analysis: ${Analysis}"
startOneStepResampling=`opts_GetOpt1 "--startOneStepResampling" $@`
log_Msg "startOneStepResampling: ${startOneStepResampling}"
startIntensityNormalization=`opts_GetOpt1 "--startIntensityNormalization" $@`
log_Msg "startIntensityNormalization: ${startIntensityNormalization}"
freesurferVersion=`opts_GetOpt1 "--freesurferVersion" $@`
log_Msg "freesurferVersion: ${freesurferVersion}"

echo "startOneStepResampling = $startOneStepResampling"
echo "startIntensityNormalization = $startIntensityNormalization"
echo "freesurferVersion = $freesurferVersion"

if [ "${startOneStepResampling}" = "TRUE" ];then
#if [ -n "${startOneStepResampling}" ];then
    do_GradientDistortionCorrection=0
    do_MotionCorrection=0
    do_P0=0
    do_P1=1
    do_P2=1
fi
if [ "${startIntensityNormalization}" = "TRUE" ];then
#if [ -n "${startIntensityNormalization}" ];then
    do_GradientDistortionCorrection=0
    do_MotionCorrection=0
    do_P0=0
    do_P1=0
    do_P2=1
fi
echo "do_GradientDistortionCorrection = $do_GradientDistortionCorrection"
echo "do_MotionCorrection = $do_MotionCorrection"
echo "do_P0 = $do_P0"
echo "do_P1 = $do_P1"
echo "do_P2 = $do_P2"


#error check
case "$MotionCorrectionType" in
    MCFLIRT|FLIRT)
        #nothing
    ;;
    
    *)
		log_Err_Abort "--mctype must be 'MCFLIRT' (default) or 'FLIRT'"
    ;;
esac

JacobianDefault="true"
if [[ $DistortionCorrection != "TOPUP" ]]
then
    #because the measured fieldmap can cause the warpfield to fold over, default to doing nothing about any jacobians
    JacobianDefault="false"
    #warn if the user specified it
    if [[ $UseJacobian == "true" ]]
    then
        log_Msg "WARNING: using --jacobian=true with --dcmethod other than TOPUP is not recommended, as the distortion warpfield is less stable than TOPUP"
    fi
fi
log_Msg "JacobianDefault: ${JacobianDefault}"

UseJacobian=`opts_DefaultOpt $UseJacobian $JacobianDefault`
log_Msg "After taking default value if necessary, UseJacobian: ${UseJacobian}"

if [[ -n $HCPPIPEDEBUG ]]
then
    set -x
fi

#sanity check the jacobian option
if [[ "$UseJacobian" != "true" && "$UseJacobian" != "false" ]]
then
	log_Err_Abort "the --usejacobian option must be 'true' or 'false'"
fi

# Setup PATHS
PipelineScripts=${HCPPIPEDIR_fMRIVol}
GlobalScripts=${HCPPIPEDIR_Global}

#Naming Conventions
T1wImage="T1w_acpc_dc"
T1wRestoreImage="T1w_acpc_dc_restore"
T1wRestoreImageBrain="T1w_acpc_dc_restore_brain"
T1wFolder="T1w" #Location of T1w images

#AtlasSpaceFolder="MNINonLinear"
#START190725
if ! [ ${Analysis} = "NATIVE" ] ; then
    AtlasSpaceFolder="MNINonLinear"
else
    AtlasSpaceFolder=${T1wFolder}
fi

ResultsFolder="Results"
BiasField="BiasField_acpc_dc"

#BiasFieldMNI="BiasField"
#START190725
if ! [ ${Analysis} = "NATIVE" ] ; then
    BiasFieldMNI="BiasField"
else
    BiasFieldMNI=${BiasField}
fi

#T1wAtlasName="T1w_restore"
#START190725
if ! [ ${Analysis} = "NATIVE" ] ; then
    T1wAtlasName="T1w_restore"
else
    T1wAtlasName="T1w_acpc_dc_restore"
fi

MovementRegressor="Movement_Regressors" #No extension, .txt appended
MotionMatrixFolder="MotionMatrices"
MotionMatrixPrefix="MAT_"
FieldMapOutputName="FieldMap"
MagnitudeOutputName="Magnitude"
MagnitudeBrainOutputName="Magnitude_brain"
ScoutName="Scout"
OrigScoutName="${ScoutName}_orig"
OrigTCSName="${NameOffMRI}_orig"
FreeSurferBrainMask="brainmask_fs"
fMRI2strOutputTransform="${NameOffMRI}2str"
RegOutput="Scout2T1w"
AtlasTransform="acpc_dc2standard"
OutputfMRI2StandardTransform="${NameOffMRI}2standard"
Standard2OutputfMRITransform="standard2${NameOffMRI}"
QAImage="T1wMulEPI"
JacobianOut="Jacobian"
#SubjectFolder="$Path"/"$Subject"
SubjectFolder="$Path"/
#note, this file doesn't exist yet, gets created by ComputeSpinEchoBiasField.sh during DistortionCorrectionAnd...
sebasedBiasFieldMNI="$SubjectFolder/$AtlasSpaceFolder/Results/$NameOffMRI/${NameOffMRI}_sebased_bias.nii.gz"

fMRIFolder="$Path"/"$NameOffMRI"
#fMRIFolder="$Path"/"$Subject"/"$NameOffMRI"

#echo TEST1
#echo $Path #/Users/bphilip/Documents/10_Connectivity/10_200/pipeline
#echo $Subject #10_200
#echo $NameOffMRI #rest03
#echo TEST2


#error check bias correction opt
case "$BiasCorrection" in
    NONE)
        UseBiasFieldMNI=""
		;;
    LEGACY)
        UseBiasFieldMNI="${fMRIFolder}/${BiasFieldMNI}.${FinalfMRIResolution}"
		;;    
    SEBASED)
        if [[ "$DistortionCorrection" != "TOPUP" ]]
        then
            log_Err_Abort "SEBASED bias correction is only available with --dcmethod=TOPUP"
        fi
        UseBiasFieldMNI="$sebasedBiasFieldMNI"
		;;
    "")
        log_Err_Abort "--biascorrection option not specified"
		;;
    *)
        log_Err_Abort "unrecognized value for bias correction: $BiasCorrection"
		;;
esac


########################################## DO WORK ########################################## 

T1wFolder="$Path"/"$T1wFolder"
AtlasSpaceFolder="$Path"/"$AtlasSpaceFolder"
ResultsFolder="$AtlasSpaceFolder"/"$ResultsFolder"/"$NameOffMRI"

mkdir -p ${T1wFolder}/Results/${NameOffMRI}

if [ ! -e "$fMRIFolder" ] ; then
  log_Msg "mkdir ${fMRIFolder}"
  mkdir "$fMRIFolder"
fi
cp "$fMRITimeSeries" "$fMRIFolder"/"$OrigTCSName".nii.gz

#Create fake "Scout" if it doesn't exist
if [ $fMRIScout = "NONE" ] ; then
  ${RUN} ${FSLDIR}/bin/fslroi "$fMRIFolder"/"$OrigTCSName" "$fMRIFolder"/"$OrigScoutName" 0 1
else
  cp "$fMRIScout" "$fMRIFolder"/"$OrigScoutName".nii.gz
fi




##Gradient Distortion Correction of fMRI
#log_Msg "Gradient Distortion Correction of fMRI"
#if [ ! $GradientDistortionCoeffs = "NONE" ] ; then
#    log_Msg "mkdir -p ${fMRIFolder}/GradientDistortionUnwarp"
#    mkdir -p "$fMRIFolder"/GradientDistortionUnwarp
#    ${RUN} "$GlobalScripts"/GradientDistortionUnwarp.sh \
#		   --workingdir="$fMRIFolder"/GradientDistortionUnwarp \
#		   --coeffs="$GradientDistortionCoeffs" \
#		   --in="$fMRIFolder"/"$OrigTCSName" \
#		   --out="$fMRIFolder"/"$NameOffMRI"_gdc \
#		   --owarp="$fMRIFolder"/"$NameOffMRI"_gdc_warp
#	
#    log_Msg "mkdir -p ${fMRIFolder}/${ScoutName}_GradientDistortionUnwarp"	
#    mkdir -p "$fMRIFolder"/"$ScoutName"_GradientDistortionUnwarp
#    ${RUN} "$GlobalScripts"/GradientDistortionUnwarp.sh \
#		   --workingdir="$fMRIFolder"/"$ScoutName"_GradientDistortionUnwarp \
#		   --coeffs="$GradientDistortionCoeffs" \
#		   --in="$fMRIFolder"/"$OrigScoutName" \
#		   --out="$fMRIFolder"/"$ScoutName"_gdc \
#		   --owarp="$fMRIFolder"/"$ScoutName"_gdc_warp
#	
#	if [[ $UseJacobian == "true" ]]
#	then
#	    ${RUN} ${FSLDIR}/bin/fslmaths "$fMRIFolder"/"$NameOffMRI"_gdc -mul "$fMRIFolder"/"$NameOffMRI"_gdc_warp_jacobian "$fMRIFolder"/"$NameOffMRI"_gdc
#	    ${RUN} ${FSLDIR}/bin/fslmaths "$fMRIFolder"/"$ScoutName"_gdc -mul "$fMRIFolder"/"$ScoutName"_gdc_warp_jacobian "$fMRIFolder"/"$ScoutName"_gdc
#	fi
#else
#    log_Msg "NOT PERFORMING GRADIENT DISTORTION CORRECTION"
#    ${RUN} ${FSLDIR}/bin/imcp "$fMRIFolder"/"$OrigTCSName" "$fMRIFolder"/"$NameOffMRI"_gdc
#    ${RUN} ${FSLDIR}/bin/fslroi "$fMRIFolder"/"$NameOffMRI"_gdc "$fMRIFolder"/"$NameOffMRI"_gdc_warp 0 3
#    ${RUN} ${FSLDIR}/bin/fslmaths "$fMRIFolder"/"$NameOffMRI"_gdc_warp -mul 0 "$fMRIFolder"/"$NameOffMRI"_gdc_warp
#    ${RUN} ${FSLDIR}/bin/imcp "$fMRIFolder"/"$OrigScoutName" "$fMRIFolder"/"$ScoutName"_gdc
#    #make fake jacobians of all 1s, for completeness
#    ${RUN} ${FSLDIR}/bin/fslmaths "$fMRIFolder"/"$OrigScoutName" -mul 0 -add 1 "$fMRIFolder"/"$ScoutName"_gdc_warp_jacobian
#    ${RUN} ${FSLDIR}/bin/fslroi "$fMRIFolder"/"$NameOffMRI"_gdc_warp "$fMRIFolder"/"$NameOffMRI"_gdc_warp_jacobian 0 1
#    ${RUN} ${FSLDIR}/bin/fslmaths "$fMRIFolder"/"$NameOffMRI"_gdc_warp_jacobian -mul 0 -add 1 "$fMRIFolder"/"$NameOffMRI"_gdc_warp_jacobian
#fi
#START190805
if [ "$do_GradientDistortionCorrection" -eq "1" ];then
    #Gradient Distortion Correction of fMRI
    log_Msg "Gradient Distortion Correction of fMRI"
    if [ ! $GradientDistortionCoeffs = "NONE" ] ; then
        log_Msg "mkdir -p ${fMRIFolder}/GradientDistortionUnwarp"
        mkdir -p "$fMRIFolder"/GradientDistortionUnwarp
        ${RUN} "$GlobalScripts"/GradientDistortionUnwarp.sh \
		       --workingdir="$fMRIFolder"/GradientDistortionUnwarp \
		       --coeffs="$GradientDistortionCoeffs" \
		       --in="$fMRIFolder"/"$OrigTCSName" \
		       --out="$fMRIFolder"/"$NameOffMRI"_gdc \
		       --owarp="$fMRIFolder"/"$NameOffMRI"_gdc_warp
	    
        log_Msg "mkdir -p ${fMRIFolder}/${ScoutName}_GradientDistortionUnwarp"	
        mkdir -p "$fMRIFolder"/"$ScoutName"_GradientDistortionUnwarp
        ${RUN} "$GlobalScripts"/GradientDistortionUnwarp.sh \
		       --workingdir="$fMRIFolder"/"$ScoutName"_GradientDistortionUnwarp \
		       --coeffs="$GradientDistortionCoeffs" \
		       --in="$fMRIFolder"/"$OrigScoutName" \
		       --out="$fMRIFolder"/"$ScoutName"_gdc \
		       --owarp="$fMRIFolder"/"$ScoutName"_gdc_warp
	    
	    if [[ $UseJacobian == "true" ]];then
	        ${RUN} ${FSLDIR}/bin/fslmaths "$fMRIFolder"/"$NameOffMRI"_gdc -mul "$fMRIFolder"/"$NameOffMRI"_gdc_warp_jacobian "$fMRIFolder"/"$NameOffMRI"_gdc
	        ${RUN} ${FSLDIR}/bin/fslmaths "$fMRIFolder"/"$ScoutName"_gdc -mul "$fMRIFolder"/"$ScoutName"_gdc_warp_jacobian "$fMRIFolder"/"$ScoutName"_gdc
	    fi
    else
        log_Msg "NOT PERFORMING GRADIENT DISTORTION CORRECTION"
        ${RUN} ${FSLDIR}/bin/imcp "$fMRIFolder"/"$OrigTCSName" "$fMRIFolder"/"$NameOffMRI"_gdc

        ${RUN} ${FSLDIR}/bin/fslroi "$fMRIFolder"/"$NameOffMRI"_gdc "$fMRIFolder"/"$NameOffMRI"_gdc_warp 0 3
        #START220815 This change blows up in 220814OneStepResampling.sh
        #${RUN} ${FSLDIR}/bin/fslroi "$fMRIFolder"/"$NameOffMRI"_gdc "$fMRIFolder"/"$NameOffMRI"_gdc_warp 0 1

        ${RUN} ${FSLDIR}/bin/fslmaths "$fMRIFolder"/"$NameOffMRI"_gdc_warp -mul 0 "$fMRIFolder"/"$NameOffMRI"_gdc_warp
        ${RUN} ${FSLDIR}/bin/imcp "$fMRIFolder"/"$OrigScoutName" "$fMRIFolder"/"$ScoutName"_gdc
        #make fake jacobians of all 1s, for completeness
        ${RUN} ${FSLDIR}/bin/fslmaths "$fMRIFolder"/"$OrigScoutName" -mul 0 -add 1 "$fMRIFolder"/"$ScoutName"_gdc_warp_jacobian
        ${RUN} ${FSLDIR}/bin/fslroi "$fMRIFolder"/"$NameOffMRI"_gdc_warp "$fMRIFolder"/"$NameOffMRI"_gdc_warp_jacobian 0 1
    
    fi
fi


#log_Msg "mkdir -p ${fMRIFolder}/MotionCorrection"
#mkdir -p "$fMRIFolder"/MotionCorrection
#${RUN} "$PipelineScripts"/MotionCorrection.sh \
#       "$fMRIFolder"/MotionCorrection \
#       "$fMRIFolder"/"$NameOffMRI"_gdc \
#       "$fMRIFolder"/"$ScoutName"_gdc \
#       "$fMRIFolder"/"$NameOffMRI"_mc \
#       "$fMRIFolder"/"$MovementRegressor" \
#       "$fMRIFolder"/"$MotionMatrixFolder" \
#       "$MotionMatrixPrefix" \
#       "$MotionCorrectionType"
#START190805
#if [ "$do_MotionCorrection" -eq "1" ];then
#    log_Msg "mkdir -p ${fMRIFolder}/MotionCorrection"
#    mkdir -p "$fMRIFolder"/MotionCorrection
#    ${RUN} "$PipelineScripts"/MotionCorrection.sh \
#           "$fMRIFolder"/MotionCorrection \
#           "$fMRIFolder"/"$NameOffMRI"_gdc \
#           "$fMRIFolder"/"$ScoutName"_gdc \
#           "$fMRIFolder"/"$NameOffMRI"_mc \
#           "$fMRIFolder"/"$MovementRegressor" \
#           "$fMRIFolder"/"$MotionMatrixFolder" \
#           "$MotionMatrixPrefix" \
#           "$MotionCorrectionType"
#fi
#START220215
if [ "$do_MotionCorrection" -eq "1" ];then
    log_Msg "mkdir -p ${fMRIFolder}/MotionCorrection"
    mkdir -p "$fMRIFolder"/MotionCorrection
    ${RUN} ${P3} \
           "$fMRIFolder"/MotionCorrection \
           "$fMRIFolder"/"$NameOffMRI"_gdc \
           "$fMRIFolder"/"$ScoutName"_gdc \
           "$fMRIFolder"/"$NameOffMRI"_mc \
           "$fMRIFolder"/"$MovementRegressor" \
           "$fMRIFolder"/"$MotionMatrixFolder" \
           "$MotionMatrixPrefix" \
           "$MotionCorrectionType"
fi





## EPI Distortion Correction and EPI to T1w Registration
#log_Msg "EPI Distortion Correction and EPI to T1w Registration"
#DCFolderName=DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased
#DCFolder=${fMRIFolder}/${DCFolderName}
#if [ -e ${DCFolder} ] ; then
#    ${RUN} rm -r ${DCFolder}
#fi
#log_Msg "mkdir -p ${DCFolder}"
#mkdir -p ${DCFolder}
#${RUN} ${P0} \
#       --workingdir=${DCFolder} \
#       --scoutin=${fMRIFolder}/${ScoutName}_gdc \
#       --t1=${T1wFolder}/${T1wImage} \
#       --t1restore=${T1wFolder}/${T1wRestoreImage} \
#       --t1brain=${T1wFolder}/${T1wRestoreImageBrain} \
#       --fmapmag=${MagnitudeInputName} \
#       --fmapphase=${PhaseInputName} \
#       --fmapgeneralelectric=${GEB0InputName} \
#       --echodiff=${deltaTE} \
#       --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
#       --SEPhasePos=${SpinEchoPhaseEncodePositive} \
#       --echospacing=${EchoSpacing} \
#       --unwarpdir=${UnwarpDir} \
#       --owarp=${T1wFolder}/xfms/${fMRI2strOutputTransform} \
#       --biasfield=${T1wFolder}/${BiasField} \
#       --oregim=${fMRIFolder}/${RegOutput} \
#       --freesurferfolder=${T1wFolder} \
#       --freesurfersubjectid=${Subject} \
#       --gdcoeffs=${GradientDistortionCoeffs} \
#       --qaimage=${fMRIFolder}/${QAImage} \
#       --method=${DistortionCorrection} \
#       --topupconfig=${TopupConfig} \
#       --ojacobian=${fMRIFolder}/${JacobianOut} \
#       --dof=${dof} \
#       --fmriname=${NameOffMRI} \
#       --subjectfolder=${SubjectFolder} \
#       --biascorrection=${BiasCorrection} \
#       --usejacobian=${UseJacobian}
#START190807
DCFolderName=DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased
DCFolder=${fMRIFolder}/${DCFolderName}
if [ "$do_P0" -eq "1" ];then
    # EPI Distortion Correction and EPI to T1w Registration
    log_Msg "EPI Distortion Correction and EPI to T1w Registration"
    if [ -e ${DCFolder} ] ; then
        ${RUN} rm -r ${DCFolder}
    fi
    log_Msg "mkdir -p ${DCFolder}"
    mkdir -p ${DCFolder}
    ${RUN} ${P0} \
           --workingdir=${DCFolder} \
           --scoutin=${fMRIFolder}/${ScoutName}_gdc \
           --t1=${T1wFolder}/${T1wImage} \
           --t1restore=${T1wFolder}/${T1wRestoreImage} \
           --t1brain=${T1wFolder}/${T1wRestoreImageBrain} \
           --fmapmag=${MagnitudeInputName} \
           --fmapphase=${PhaseInputName} \
           --fmapgeneralelectric=${GEB0InputName} \
           --echodiff=${deltaTE} \
           --SEPhaseNeg=${SpinEchoPhaseEncodeNegative} \
           --SEPhasePos=${SpinEchoPhaseEncodePositive} \
           --echospacing=${EchoSpacing} \
           --unwarpdir=${UnwarpDir} \
           --owarp=${T1wFolder}/xfms/${fMRI2strOutputTransform} \
           --biasfield=${T1wFolder}/${BiasField} \
           --oregim=${fMRIFolder}/${RegOutput} \
           --freesurferfolder=${T1wFolder} \
           --freesurfersubjectid=${Subject} \
           --gdcoeffs=${GradientDistortionCoeffs} \
           --qaimage=${fMRIFolder}/${QAImage} \
           --method=${DistortionCorrection} \
           --topupconfig=${TopupConfig} \
           --ojacobian=${fMRIFolder}/${JacobianOut} \
           --dof=${dof} \
           --fmriname=${NameOffMRI} \
           --subjectfolder=${SubjectFolder} \
           --biascorrection=${BiasCorrection} \
           --usejacobian=${UseJacobian} \
           --freesurferVersion=$freesurferVersion
fi


##One Step Resampling
#log_Msg "One Step Resampling"
#log_Msg "mkdir -p ${fMRIFolder}/OneStepResampling"
#mkdir -p ${fMRIFolder}/OneStepResampling
#${RUN} ${P1} \
#       --workingdir=${fMRIFolder}/OneStepResampling \
#       --infmri=${fMRIFolder}/${OrigTCSName}.nii.gz \
#       --t1=${AtlasSpaceFolder}/${T1wAtlasName} \
#       --fmriresout=${FinalfMRIResolution} \
#       --fmrifolder=${fMRIFolder} \
#       --fmri2structin=${T1wFolder}/xfms/${fMRI2strOutputTransform} \
#       --struct2std=${AtlasSpaceFolder}/xfms/${AtlasTransform} \
#       --owarp=${AtlasSpaceFolder}/xfms/${OutputfMRI2StandardTransform} \
#       --oiwarp=${AtlasSpaceFolder}/xfms/${Standard2OutputfMRITransform} \
#       --motionmatdir=${fMRIFolder}/${MotionMatrixFolder} \
#       --motionmatprefix=${MotionMatrixPrefix} \
#       --ofmri=${fMRIFolder}/${NameOffMRI}_nonlin \
#       --freesurferbrainmask=${AtlasSpaceFolder}/${FreeSurferBrainMask} \
#       --biasfield=${AtlasSpaceFolder}/${BiasFieldMNI} \
#       --gdfield=${fMRIFolder}/${NameOffMRI}_gdc_warp \
#       --scoutin=${fMRIFolder}/${OrigScoutName} \
#       --scoutgdcin=${fMRIFolder}/${ScoutName}_gdc \
#       --oscout=${fMRIFolder}/${NameOffMRI}_SBRef_nonlin \
#       --ojacobian=${fMRIFolder}/${JacobianOut}_MNI.${FinalfMRIResolution} \
#       --analysis=${Analysis}
#START190807
#One Step Resampling
if [ "$do_P1" -eq "1" ];then
    log_Msg "One Step Resampling"
    log_Msg "mkdir -p ${fMRIFolder}/OneStepResampling"
    mkdir -p ${fMRIFolder}/OneStepResampling
    ${RUN} ${P1} \
           --workingdir=${fMRIFolder}/OneStepResampling \
           --infmri=${fMRIFolder}/${OrigTCSName}.nii.gz \
           --t1=${AtlasSpaceFolder}/${T1wAtlasName} \
           --fmriresout=${FinalfMRIResolution} \
           --fmrifolder=${fMRIFolder} \
           --fmri2structin=${T1wFolder}/xfms/${fMRI2strOutputTransform} \
           --struct2std=${AtlasSpaceFolder}/xfms/${AtlasTransform} \
           --owarp=${AtlasSpaceFolder}/xfms/${OutputfMRI2StandardTransform} \
           --oiwarp=${AtlasSpaceFolder}/xfms/${Standard2OutputfMRITransform} \
           --motionmatdir=${fMRIFolder}/${MotionMatrixFolder} \
           --motionmatprefix=${MotionMatrixPrefix} \
           --ofmri=${fMRIFolder}/${NameOffMRI}_nonlin \
           --freesurferbrainmask=${AtlasSpaceFolder}/${FreeSurferBrainMask} \
           --biasfield=${AtlasSpaceFolder}/${BiasFieldMNI} \
           --gdfield=${fMRIFolder}/${NameOffMRI}_gdc_warp \
           --scoutin=${fMRIFolder}/${OrigScoutName} \
           --scoutgdcin=${fMRIFolder}/${ScoutName}_gdc \
           --oscout=${fMRIFolder}/${NameOffMRI}_SBRef_nonlin \
           --ojacobian=${fMRIFolder}/${JacobianOut}_MNI.${FinalfMRIResolution} \
           --analysis=${Analysis}
fi




log_Msg "mkdir -p ${ResultsFolder}"
mkdir -p ${ResultsFolder}

#now that we have the final MNI fMRI space, resample the T1w-space sebased bias field related outputs
#the alternative is to add a bunch of optional arguments to OneStepResampling that just do the same thing
#we need to do this before intensity normalization, as it uses the bias field output

#if [[ ${DistortionCorrection} == "TOPUP" ]]; then
#START190807
if [[ ${DistortionCorrection} == "TOPUP" && "${Analysis}" != "NATIVE" ]]; then

    #create MNI space corrected fieldmap images
    ${FSLDIR}/bin/applywarp --rel --interp=spline --in=${DCFolder}/PhaseOne_gdc_dc_unbias -w ${AtlasSpaceFolder}/xfms/${AtlasTransform} -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin -o ${ResultsFolder}/${NameOffMRI}_PhaseOne_gdc_dc
    ${FSLDIR}/bin/applywarp --rel --interp=spline --in=${DCFolder}/PhaseTwo_gdc_dc_unbias -w ${AtlasSpaceFolder}/xfms/${AtlasTransform} -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin -o ${ResultsFolder}/${NameOffMRI}_PhaseTwo_gdc_dc
    
    #create MNINonLinear final fMRI resolution bias field outputs
    if [[ ${BiasCorrection} == "SEBASED" ]]; then
        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${DCFolder}/ComputeSpinEchoBiasField/sebased_bias_dil.nii.gz -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin -w ${AtlasSpaceFolder}/xfms/${AtlasTransform} -o ${ResultsFolder}/${NameOffMRI}_sebased_bias.nii.gz
        ${FSLDIR}/bin/fslmaths ${ResultsFolder}/${NameOffMRI}_sebased_bias.nii.gz -mas ${fMRIFolder}/${FreeSurferBrainMask}.${FinalfMRIResolution}.nii.gz ${ResultsFolder}/${NameOffMRI}_sebased_bias.nii.gz
        
        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${DCFolder}/ComputeSpinEchoBiasField/sebased_reference_dil.nii.gz -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin -w ${AtlasSpaceFolder}/xfms/${AtlasTransform} -o ${ResultsFolder}/${NameOffMRI}_sebased_reference.nii.gz
        ${FSLDIR}/bin/fslmaths ${ResultsFolder}/${NameOffMRI}_sebased_reference.nii.gz -mas ${fMRIFolder}/${FreeSurferBrainMask}.${FinalfMRIResolution}.nii.gz ${ResultsFolder}/${NameOffMRI}_sebased_reference.nii.gz
        
        ${FSLDIR}/bin/applywarp --interp=trilinear -i ${DCFolder}/ComputeSpinEchoBiasField/${NameOffMRI}_dropouts.nii.gz -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin -w ${AtlasSpaceFolder}/xfms/${AtlasTransform} -o ${ResultsFolder}/${NameOffMRI}_dropouts.nii.gz
    fi
fi

##Intensity Normalization and Bias Removal
#log_Msg "Intensity Normalization and Bias Removal"
#${RUN} ${PipelineScripts}/IntensityNormalization.sh \
#START190726
#${RUN} ${P2} \
#       --infmri=${fMRIFolder}/${NameOffMRI}_nonlin \
#       --biasfield=${UseBiasFieldMNI} \
#       --jacobian=${fMRIFolder}/${JacobianOut}_MNI.${FinalfMRIResolution} \
#       --brainmask=${fMRIFolder}/${FreeSurferBrainMask}.${FinalfMRIResolution} \
#       --ofmri=${fMRIFolder}/${NameOffMRI}_nonlin_norm \
#       --inscout=${fMRIFolder}/${NameOffMRI}_SBRef_nonlin \
#       --oscout=${fMRIFolder}/${NameOffMRI}_SBRef_nonlin_norm \
#       --usejacobian=${UseJacobian}
#START190807
#Intensity Normalization and Bias Removal
if [ "${Analysis}" != "NATIVE" ]; then
    jacobian0=${JacobianOut}_MNI.${FinalfMRIResolution}    
else
    jacobian0=${JacobianOut}
fi

if [ "$do_P2" -eq "1" ];then
    log_Msg "Intensity Normalization and Bias Removal"
    ${RUN} ${P2} \
           --infmri=${fMRIFolder}/${NameOffMRI}_nonlin \
           --biasfield=${UseBiasFieldMNI} \
           --jacobian=${fMRIFolder}/${jacobian0} \
           --brainmask=${fMRIFolder}/${FreeSurferBrainMask}.${FinalfMRIResolution} \
           --ofmri=${fMRIFolder}/${NameOffMRI}_nonlin_norm \
           --inscout=${fMRIFolder}/${NameOffMRI}_SBRef_nonlin \
           --oscout=${fMRIFolder}/${NameOffMRI}_SBRef_nonlin_norm \
           --usejacobian=${UseJacobian}
fi


# MJ QUERY: WHY THE -r OPTIONS BELOW?
# TBr Response: Since the copy operations are specifying individual files
# to be copied and not directories, the recursive copy options (-r) to the
# cp calls below definitely seem unnecessary. They should be removed in 
# a code clean up phase when tests are in place to verify that removing them
# has no unexpected bad side-effect.
${RUN} cp -r ${fMRIFolder}/${NameOffMRI}_nonlin_norm.nii.gz ${ResultsFolder}/${NameOffMRI}.nii.gz
${RUN} cp -r ${fMRIFolder}/${MovementRegressor}.txt ${ResultsFolder}/${MovementRegressor}.txt
${RUN} cp -r ${fMRIFolder}/${MovementRegressor}_dt.txt ${ResultsFolder}/${MovementRegressor}_dt.txt
${RUN} cp -r ${fMRIFolder}/${NameOffMRI}_SBRef_nonlin_norm.nii.gz ${ResultsFolder}/${NameOffMRI}_SBRef.nii.gz

#${RUN} cp -r ${fMRIFolder}/${JacobianOut}_MNI.${FinalfMRIResolution}.nii.gz ${ResultsFolder}/${NameOffMRI}_${JacobianOut}.nii.gz
#START910807
#${RUN} cp -p ${fMRIFolder}/${jacobian0}.nii.gz ${ResultsFolder}/${NameOffMRI}_${JacobianOut}.nii.gz
#START200204
if [ -f "${fMRIFolder}/${jacobian0}.nii.gz" ];then
    ${RUN} cp -p ${fMRIFolder}/${jacobian0}.nii.gz ${ResultsFolder}/${NameOffMRI}_${JacobianOut}.nii.gz
fi

${RUN} cp -r ${fMRIFolder}/${FreeSurferBrainMask}.${FinalfMRIResolution}.nii.gz ${ResultsFolder}
###Add stuff for RMS###
${RUN} cp -r ${fMRIFolder}/Movement_RelativeRMS.txt ${ResultsFolder}/Movement_RelativeRMS.txt
${RUN} cp -r ${fMRIFolder}/Movement_AbsoluteRMS.txt ${ResultsFolder}/Movement_AbsoluteRMS.txt
${RUN} cp -r ${fMRIFolder}/Movement_RelativeRMS_mean.txt ${ResultsFolder}/Movement_RelativeRMS_mean.txt
${RUN} cp -r ${fMRIFolder}/Movement_AbsoluteRMS_mean.txt ${ResultsFolder}/Movement_AbsoluteRMS_mean.txt
###Add stuff for RMS###

#Basic Cleanup
rm ${fMRIFolder}/${NameOffMRI}_nonlin_norm.nii.gz

#Econ
#rm "$fMRIFolder"/"$OrigTCSName".nii.gz
#rm "$fMRIFolder"/"$NameOffMRI"_gdc.nii.gz
#rm "$fMRIFolder"/"$NameOffMRI"_mc.nii.gz

log_Msg "Completed"

echo "****** END $0 ******"
