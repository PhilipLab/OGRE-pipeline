#!/usr/bin/env bash 

P0=${OGREDIR}/lib/OGREGenericfMRIVolumeProcessingPipeline.sh

echo "**** Running $0 ****"

get_batch_options() {
    local arguments=("$@")

    unset command_line_specified_study_folder
    unset command_line_specified_subj
    unset command_line_specified_run_local
    unset command_line_specified_TaskList
    unset command_line_specified_fMRITimeSeries
    unset command_line_specified_MagnitudeInputName
    unset command_line_specified_PhaseInputName
    unset command_line_specified_fMRISBRef
    unset command_line_specified_EchoSpacing
    unset command_line_specified_SpinEchoPhaseEncodeNegative
    unset command_line_specified_SpinEchoPhaseEncodePositive
    unset command_line_specified_native
    unset command_line_specified_FinalFMRIResolution
    unset command_line_specified_UnwarpDirection
    unset command_line_specified_json
    unset command_line_specified_EnvironmentScript
    unset cls_freesurferVersion
    cls_userefinement="false"
    cls_startOneStepResampling="FALSE"
    cls_startIntensityNormalization="FALSE"

    #START240730
    dilation=0

    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --StudyFolder=*)
                command_line_specified_study_folder=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --Subject=*)
                command_line_specified_subj=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --runlocal)
                command_line_specified_run_local="TRUE"
                index=$(( index + 1 ))
                ;;
            --TaskList=*)
                command_line_specified_TaskList=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --fMRITimeSeries=*)
                command_line_specified_fMRITimeSeries=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --fMRISBRef=*)
                command_line_specified_fMRISBRef=${argument#*=}
                index=$(( index + 1 ))
                ;;

        #START191030
        #EchoSpacing: If the json is in the same directory as the bold AND includes "EffectiveEchoSpacing", then ignore these options, as this field will be read from the json. 
        #If --EchoSpacing is provided then it is used instead.
        #Or, if the json is not in the same directory as the bold (eg bold has been slice timed), then provide the complete path with filename to the json after --json (see below).
            --EchoSpacing=*)
                command_line_specified_EchoSpacing=${argument#*=}
                index=$(( index + 1 ))
                ;;

            --MagnitudeInputName=*) 
                command_line_specified_MagnitudeInputName=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --PhaseInputName=*)
                command_line_specified_PhaseInputName=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --SpinEchoPhaseEncodeNegative=*)
                command_line_specified_SpinEchoPhaseEncodeNegative=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --SpinEchoPhaseEncodePositive=*)
                command_line_specified_SpinEchoPhaseEncodePositive=${argument#*=}
                index=$(( index + 1 ))
                ;;

            --native)
                command_line_specified_native="TRUE"
                index=$(( index + 1 ))
                ;;
            --FinalFMRIResolution=*)
                command_line_specified_FinalFMRIResolution=${argument#*=}
                index=$(( index + 1 ))
                ;;

            #START190724
            #--PhaseEncodingDirection=*)
            #    command_line_specified_PhaseEncodingDirection=${argument#*=}
            #    index=$(( index + 1 ))
            #    ;;
            #START191030
        #UnwarpDir: If the json is in the same directory as the bold, then ignore these options, as the PhaseEncodingDirection will be read from the json and converted to the unwarp direction. 
        #If --UnwarpDirection is provided then it is used instead. Possible values: x, x-, y, y-
        #Or, if the json is not in the same directory as the bold (eg bold has been slice timed), then provide the complete path with filename to the json after --json.
            --UnwarpDirection=*)
                command_line_specified_UnwarpDirection=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --json=*)
                command_line_specified_json=${argument#*=}
                index=$(( index + 1 ))
                ;;

            --EnvironmentScript=*)
                command_line_specified_EnvironmentScript=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --freesurferVersion=*)
                cls_freesurferVersion=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --userefinement)
                cls_userefinement="true"
                index=$(( index + 1 ))
                ;;
            --startOneStepResampling)
                cls_startOneStepResampling="TRUE"
                index=$(( index + 1 ))
                ;;
            --startIntensityNormalization)
                cls_startIntensityNormalization="TRUE"
                index=$(( index + 1 ))
                ;;

            --dilation=*)
                dilation=${argument#*=}
                index=$(( index + 1 ))
                ;;

	    *)
		echo ""
		echo "ERROR: Unrecognized Option: ${argument}"
		echo ""

		exit 1
                #START230625
                #[[ -n "${argument}" ]] && exit 1

		;;
        esac
    done
}
get_batch_options "$@"

StudyFolder="${HOME}/projects/Pipelines_ExampleData" #Location of Subject folders (named by subjectID)
Subjlist="100307" #Space delimited list of subject IDs

if [ -n "${command_line_specified_study_folder}" ]; then
    StudyFolder="${command_line_specified_study_folder}"
fi

if [ -n "${command_line_specified_subj}" ]; then
    Subjlist="${command_line_specified_subj}"
fi

if [ -n "${command_line_specified_fMRITimeSeries}" ]; then
    #arr=($command_line_specified_fMRITimeSeries)
    fMRITimeSeries=($command_line_specified_fMRITimeSeries)
fi

if [ -n "${command_line_specified_fMRISBRef}" ]; then
    arr1=($command_line_specified_fMRISBRef)
    #echo "arr1 = ${arr1[@]}"
fi

if [ -n "${command_line_specified_EchoSpacing}" ]; then
    arr2=($command_line_specified_EchoSpacing)
    #echo "arr2 = ${arr2[@]}"
fi

if [ -n "${command_line_specified_SpinEchoPhaseEncodeNegative}" ]; then
    arr3=($command_line_specified_SpinEchoPhaseEncodeNegative)
    #echo "arr3 = ${arr3[@]}"
fi
if [ -n "${command_line_specified_SpinEchoPhaseEncodePositive}" ]; then
    arr4=($command_line_specified_SpinEchoPhaseEncodePositive)
    #echo "arr4 = ${arr4[@]}"
fi

if [ -n "${command_line_specified_UnwarpDirection}" ]; then
    arr6=($command_line_specified_UnwarpDirection)
fi
if [ -n "${command_line_specified_json}" ]; then
    arr5=($command_line_specified_json)
fi

if [ -n "${command_line_specified_EnvironmentScript}" ]; then
    EnvironmentScript="${command_line_specified_EnvironmentScript}"
else
    echo "MUST PROVIDE EnvironmentScript"
    #echo "    Ex. --EnvironmentScript=/home/usr/mcavoy/HCP/scripts/SetUpHCPPipeline_mm.sh"
    echo "    Ex. --EnvironmentScript=OGREDIR/lib/OGRESetUpHCPPipeline.sh" # swap 240425
    exit
fi


# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP) , gradunwarp (HCP version 1.0.1)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#START190724
echo "************* Sourcing ${EnvironmentScript} ***********************"

#Set up pipeline environment variables and software
source ${EnvironmentScript}

#START220211
#P0=${HCPMOD}/${P0}

#START190724
echo "*******************************************************************"

# Log the originating call
echo "************* Log the originating call ***********************"
echo "$0"
echo "$@"
echo "**************************************************************"

#if [ X$SGE_ROOT != X ] ; then
#    QUEUE="-q long.q"
    QUEUE="-q hcp_priority.q"
#fi

if [[ -n $HCPPIPEDEBUG ]]
then
    set -x
fi

PRINTCOM=""
#PRINTCOM="echo"
#QUEUE="-q veryshort.q"

########################################## INPUTS ########################################## 

# Scripts called by this script do NOT assume anything about the form of the input names or paths.
# This batch script assumes the HCP raw data naming convention.
#
# For example, if phase encoding directions are LR and RL, for tfMRI_EMOTION_LR and tfMRI_EMOTION_RL:
#
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_LR/${Subject}_3T_tfMRI_EMOTION_LR.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_LR/${Subject}_3T_tfMRI_EMOTION_LR_SBRef.nii.gz
#
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_RL/${Subject}_3T_tfMRI_EMOTION_RL.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_RL/${Subject}_3T_tfMRI_EMOTION_RL_SBRef.nii.gz
#
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_LR/${Subject}_3T_SpinEchoFieldMap_LR.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_LR/${Subject}_3T_SpinEchoFieldMap_RL.nii.gz
#
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_RL/${Subject}_3T_SpinEchoFieldMap_LR.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_RL/${Subject}_3T_SpinEchoFieldMap_RL.nii.gz
#
# If phase encoding directions are PA and AP:
#
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_PA/${Subject}_3T_tfMRI_EMOTION_PA.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_PA/${Subject}_3T_tfMRI_EMOTION_PA_SBRef.nii.gz
#
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_AP/${Subject}_3T_tfMRI_EMOTION_AP.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_AP/${Subject}_3T_tfMRI_EMOTION_AP_SBRef.nii.gz
#
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_PA/${Subject}_3T_SpinEchoFieldMap_PA.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_PA/${Subject}_3T_SpinEchoFieldMap_AP.nii.gz
#
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_AP/${Subject}_3T_SpinEchoFieldMap_PA.nii.gz
#	${StudyFolder}/${Subject}/unprocessed/3T/tfMRI_EMOTION_AP/${Subject}_3T_SpinEchoFieldMap_AP.nii.gz
#
#
# Change Scan Settings: EchoSpacing, FieldMap DeltaTE (if not using TOPUP),
# and $TaskList to match your acquisitions
#
# If using gradient distortion correction, use the coefficents from your scanner.
# The HCP gradient distortion coefficents are only available through Siemens.
# Gradient distortion in standard scanners like the Trio is much less than for the HCP 'Connectom' scanner.
#
# To get accurate EPI distortion correction with TOPUP, the phase encoding direction
# encoded as part of the ${TaskList} name must accurately reflect the PE direction of
# the EPI scan, and you must have used the correct images in the
# SpinEchoPhaseEncode{Negative,Positive} variables.  If the distortion is twice as
# bad as in the original images, either swap the
# SpinEchoPhaseEncode{Negative,Positive} definition or reverse the polarity in the
# logic for setting UnwarpDir.
# NOTE: The pipeline expects you to have used the same phase encoding axis and echo
# spacing in the fMRI data as in the spin echo field map acquisitions.

######################################### DO WORK ##########################################

SCRIPT_NAME=`basename ${0}`
echo $SCRIPT_NAME




#if [ -n "${command_line_specified_TaskList}" ]; then
#    TaskList=(${command_line_specified_TaskList})
#else
#    if [ -n "${command_line_specified_fMRITimeSeries}" ]; then
#        TaskList=(${command_line_specified_fMRITimeSeries})
#        for i in ${!TaskList[@]};do
#            j=${TaskList[i]%%.*}
#            TaskList[i]=${j##*/}
#        done 
#    else
#        echo "Error: Need to specify --TaskList or --fMRITimeSeries"
#        exit 1
#    fi
#fi
#echo "TaskList = ${TaskList[@]}"
if [ -n "${command_line_specified_TaskList}" ]; then
    fMRIName=(${command_line_specified_TaskList})
else
    if [ -n "${command_line_specified_fMRITimeSeries}" ]; then
        fMRIName=(${command_line_specified_fMRITimeSeries})
        for i in ${!fMRIName[@]};do
            j=${fMRIName[i]%%.*}
            fMRIName[i]=${j##*/}
        done
    else
        echo "Error: Need to specify --TaskList or --fMRITimeSeries"
        exit 1
    fi
fi
echo "fMRIName = ${fMRIName[@]}"







# Start or launch pipeline processing for each subject
for Subject in $Subjlist ; do
  echo "${SCRIPT_NAME}: Processing Subject: ${Subject}"

  i=0

  #for fMRIName in ${TaskList[@]} ; do
  #  echo -e "\n${SCRIPT_NAME}: Processing Scan: ${fMRIName}"
  #  fMRITimeSeries=${arr[$i]}
  #  echo "    fMRITimeSeries = ${fMRITimeSeries}"
  #START240720
  for((i=0;i<${#fMRIName[@]};++i));do
    echo -e "\n${SCRIPT_NAME}: Processing Scan: ${fMRIName[i]}"
    echo "    fMRITimeSeries = ${fMRITimeSeries[i]}"
    #continue

        # Susceptibility distortion correction method (required for accurate processing)
        # Values: TOPUP, SiemensFieldMap (same as FIELDMAP), GeneralElectricFieldMap
    DistortionCorrection=NONE
    if [ -n "${command_line_specified_MagnitudeInputName}" ] && [ -n "${command_line_specified_PhaseInputName}" ]; then
        DistortionCorrection="SiemensFieldMap"
    elif [ -n "${command_line_specified_SpinEchoPhaseEncodeNegative}" ] && [ -n "${command_line_specified_SpinEchoPhaseEncodePositive}" ]; then
        DistortionCorrection="TOPUP"
    fi
    echo "DistortionCorrection = ${DistortionCorrection}"
    if [ ${DistortionCorrection} != "NONE" ];then
        if [ -n "${command_line_specified_UnwarpDirection}" ]; then
            UnwarpDir=${arr6[$i]}
            case ${UnwarpDir} in
              "y")
                   ;;
              "y-")
                   ;;
              "x")
                   ;;
              "x-")
                   ;;
              *)
                   echo "${SCRIPT_NAME}: Unrecognized Phase Encoding (=UnwarpDir) Direction: ${PhaseEncodingDir}"
                   exit 1
            esac
        else
            if [ -n "${command_line_specified_json}" ]; then
                json=${arr5[$i]}
            else
                #json=${fMRITimeSeries%%.*}.json
                json=${fMRITimeSeries[i]%%.*}.json
            fi
            mapfile -t PhaseEncodingDirection < <( grep PhaseEncodingDirection $json )
            IFS=$' ,' read -ra line0 <<< ${PhaseEncodingDirection}
            IFS=$'"' read -ra line <<< ${line0[1]}
            PhaseEncodingDir=${line[1]}
            echo "PhaseEncodingDir = ${PhaseEncodingDir}"
            case ${PhaseEncodingDir} in
              "j")
                   UnwarpDir="y"
                   ;;
              "j-")
                   UnwarpDir="y-"
                   ;;
              "i")
                   UnwarpDir="x"
                   ;;
              "i-")
                   UnwarpDir="x-"
                   ;;
              *)
                   echo "${SCRIPT_NAME}: Unrecognized Phase Encoding Direction: ${PhaseEncodingDir}"
                   exit 1
            esac
        fi
        echo "UnwarpDir = ${UnwarpDir}"

            # "Effective" Echo Spacing of fMRI image (specified in *sec* for the fMRI processing)
            # EchoSpacing = 1/(BWPPPE * ReconMatrixPE)
            #   where BWPPPE is the "BandwidthPerPixelPhaseEncode" = DICOM field (0019,1028) for Siemens, and
            #   ReconMatrixPE = size of the reconstructed image in the PE dimension
            # In-plane acceleration, phase oversampling, phase resolution, phase field-of-view, and interpolation
            # all potentially need to be accounted for (which they are in Siemen's reported BWPPPE)
        #EchoSpacing="0.00058" 
        #EchoSpacing=".0000078" #This was the Ben Philip setting.
        if [ -n "${command_line_specified_EchoSpacing}" ]; then
            EchoSpacing=${arr2[$i]}
        else
            if [ -n "${command_line_specified_json}" ]; then
                json=${arr5[$i]}
            else
                #json=${fMRITimeSeries%%.*}.json
                json=${fMRITimeSeries[i]%%.*}.json
            fi
            mapfile -t EffectiveEchoSpacing < <( grep EffectiveEchoSpacing $json )
            IFS=$' ,' read -ra line <<< ${EffectiveEchoSpacing}
            EchoSpacing=${line[1]}
        fi
        echo "EchoSpacing = ${EchoSpacing}"
    fi

	# A single band reference image (SBRef) is recommended if available
	# Set to NONE if you want to use the first volume of the timeseries for motion correction
    if [ -n "${command_line_specified_fMRISBRef}" ]; then
        fMRISBRef=${arr1[$i]}
        echo "fMRISBRef = ${fMRISBRef}"
    else
        fMRISBRef="NONE"
    fi


	# Receive coil bias field correction method
	# Values: NONE, LEGACY, or SEBASED
	#   SEBASED calculates bias field from spin echo images (which requires TOPUP distortion correction)
	#   LEGACY uses the T1w bias field (method used for 3T HCP-YA data, but non-optimal; no longer recommended).
    BiasCorrection="NONE" 
    if [ -n "${command_line_specified_SpinEchoPhaseEncodeNegative}" ] && [ -n "${command_line_specified_SpinEchoPhaseEncodePositive}" ]; then
        BiasCorrection="SEBASED"
    fi
    echo "BiasCorrection = ${BiasCorrection}"

	# For the spin echo field map volume with a 'negative' phase encoding direction
	# (LR in HCP-YA data; AP in 7T HCP-YA and HCP-D/A data)
	# Set to NONE if using regular FIELDMAP
    SpinEchoPhaseEncodeNegative="NONE"
    if [ -n "${command_line_specified_SpinEchoPhaseEncodeNegative}" ]; then
        SpinEchoPhaseEncodeNegative=${arr3[$i]}
    fi
    echo "SpinEchoPhaseEncodeNegative = ${SpinEchoPhaseEncodeNegative}"

	# For the spin echo field map volume with a 'positive' phase encoding direction
	# (RL in HCP-YA data; PA in 7T HCP-YA and HCP-D/A data)
	# Set to NONE if using regular FIELDMAP
    SpinEchoPhaseEncodePositive="NONE"
    if [ -n "${command_line_specified_SpinEchoPhaseEncodePositive}" ]; then
        SpinEchoPhaseEncodePositive=${arr4[$i]}
    fi
    echo "SpinEchoPhaseEncodePositive = ${SpinEchoPhaseEncodePositive}"

	# Topup configuration file (if using TOPUP)
	# Set to NONE if using regular FIELDMAP
    TopUpConfig="NONE"
    if [ -n "${command_line_specified_SpinEchoPhaseEncodeNegative}" ] && [ -n "${command_line_specified_SpinEchoPhaseEncodePositive}" ]; then
        TopUpConfig="${HCPPIPEDIR_Config}/b02b0.cnf"
    fi
    echo "TopUpConfig = ${TopUpConfig}"

	# Not using Siemens Gradient Echo Field Maps for susceptibility distortion correction
	# Set following to NONE if using TOPUP
    MagnitudeInputName="NONE" #Expects 4D Magnitude volume with two 3D volumes (differing echo times)
    PhaseInputName="NONE" #Expects a 3D Phase difference volume (Siemen's style)
    DeltaTE="NONE" #2.46ms for 3T, 1.02ms for 7T
    if [ -n "${command_line_specified_MagnitudeInputName}" ] && [ -n "${command_line_specified_PhaseInputName}" ]; then
        MagnitudeInputName=${command_line_specified_MagnitudeInputName}
        PhaseInputName=${command_line_specified_PhaseInputName}
        DeltaTE=2.46 #2.46ms for 3T, 1.02ms for 7T
    fi
    echo "MagnitudeInputName = ${MagnitudeInputName}" 
    echo "PhaseInputName = ${PhaseInputName}" 
    echo "DeltaTE = ${DeltaTE}"

    # Path to General Electric style B0 fieldmap with two volumes
    #   1. field map in degrees
    #   2. magnitude
    # Set to "NONE" if not using "GeneralElectricFieldMap" as the value for the DistortionCorrection variable
    #
    # Example Value: 
    #  GEB0InputName="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName}/${Subject}_3T_GradientEchoFieldMap.nii.gz" 
    #  GEB0InputName="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName[i]}/${Subject}_3T_GradientEchoFieldMap.nii.gz" 
    GEB0InputName="NONE"

	# Target final resolution of fMRI data
	# 2mm is recommended for 3T HCP data, 1.6mm for 7T HCP data (i.e. should match acquisition resolution)
	# Use 2.0 or 1.0 to avoid standard FSL templates
    if [ -n "${command_line_specified_native}" ] ; then
        Analysis="NATIVE"
    else
        Analysis="MNI"
    fi
    echo "Analysis = ${Analysis}"
    if [ -n "${command_line_specified_FinalFMRIResolution}" ] ; then
        FinalFMRIResolution=${command_line_specified_FinalFMRIResolution}
    else
        FinalFMRIResolution="2"
    fi
    echo "FinalFMRIResolution = ${FinalFMRIResolution}"

	# Gradient distortion correction
	# Set to NONE to skip gradient distortion correction
	# (These files are considered proprietary and therefore not provided as part of the HCP Pipelines -- contact Siemens to obtain)
    # GradientDistortionCoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad"
    GradientDistortionCoeffs="NONE"

    # Type of motion correction
	# Values: MCFLIRT (default), FLIRT
	# (3T HCP-YA processing used 'FLIRT', but 'MCFLIRT' now recommended)
    MCType="MCFLIRT"
		
    if [ -n "${command_line_specified_run_local}" ] ; then
        echo "About to run ${P0}"
        queuing_command=""
    else
        echo "About to use fsl_sub to queue or run ${P0}"
        queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
    fi

    echo "cls_startOneStepResampling = $cls_startOneStepResampling"
    echo "cls_startIntensityNormalization = $cls_startIntensityNormalization"
    echo "cls_freesurferVersion = $cls_freesurferVersion"

    ${queuing_command} ${P0} \
      --path=$StudyFolder \
      --subject=$Subject \
      --fmriname=${fMRIName[i]} \
      --fmritcs=${fMRITimeSeries[i]} \
      --fmriscout=$fMRISBRef \
      --SEPhaseNeg=$SpinEchoPhaseEncodeNegative \
      --SEPhasePos=$SpinEchoPhaseEncodePositive \
      --fmapmag=$MagnitudeInputName \
      --fmapphase=$PhaseInputName \
      --fmapgeneralelectric=$GEB0InputName \
      --echospacing=$EchoSpacing \
      --echodiff=$DeltaTE \
      --unwarpdir=$UnwarpDir \
      --fmrires=$FinalFMRIResolution \
      --dcmethod=$DistortionCorrection \
      --gdcoeffs=$GradientDistortionCoeffs \
      --topupconfig=$TopUpConfig \
      --printcom=$PRINTCOM \
      --biascorrection=$BiasCorrection \
      --mctype=${MCType} \
      --analysis=$Analysis \
      --freesurferVersion=$cls_freesurferVersion \
      --userefinement=$cls_userefinement \
      --startOneStepResampling=$cls_startOneStepResampling \
      --startIntensityNormalization=$cls_startIntensityNormalization \
      --dilation="$dilation"

  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  #echo -e "--path=$StudyFolder\n \
  #    --subject=$Subject\n \
  #    --fmriname=${fMRIName[i]}\n \
  #    --fmritcs=${fMRITimeSeries[i]}\n \
  #    --fmriscout=$fMRISBRef\n \
  #    --SEPhaseNeg=$SpinEchoPhaseEncodeNegative\n \
  #    --SEPhasePos=$SpinEchoPhaseEncodePositive\n \
  #    --fmapmag=$MagnitudeInputName\n \
  #    --fmapphase=$PhaseInputName\n \
  #    --fmapgeneralelectric=$GEB0InputName\n \
  #    --echospacing=$EchoSpacing\n \
  #    --echodiff=$DeltaTE\n \
  #    --unwarpdir=$UnwarpDir\n \
  #    --fmrires=$FinalFMRIResolution\n \
  #    --dcmethod=$DistortionCorrection\n \
  #    --gdcoeffs=$GradientDistortionCoeffs\n \
  #    --topupconfig=$TopUpConfig\n \
  #    --printcom=$PRINTCOM\n \
  #    --biascorrection=$BiasCorrection\n \
  #    --mctype=${MCType}\n \
  #    --analysis=$Analysis\n \
  #    --freesurferVersion=$cls_freesurferVersion\n \
  #    --userefinement=$cls_userefinement\n \
  #    --startOneStepResampling=$cls_startOneStepResampling\n \
  #    --startIntensityNormalization=$cls_startIntensityNormalization\n"

    #i=$(($i+1))
  done
done
echo "**** Exiting $0 ****"
