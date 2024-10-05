#!/usr/bin/env bash

P0=${OGREDIR}/lib/OGREPreFreeSurferPipeline.sh

echo "**** Running $0 ****"
set -e

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # PreFreeSurferPipelineBatch.sh
#
# ## Copyright Notice
#
# Copyright (C) 2013-2018 The Human Connectome Project
#
# * Washington University in St. Louis
# * University of Minnesota
# * Oxford University
#
# ## Author(s)
#
# * Matthew F. Glasser, Department of Anatomy and Neurobiology,
#   Washington University in St. Louis
# * Timothy B. Brown, Neuroinformatics Research Group,
#   Washington University in St. Louis
#
# ## Product
#
# [Human Connectome Project][HCP] (HCP) Pipelines
#
# ## License
#
# See the [LICENSE](https://github.com/Washington-University/Pipelines/blob/master/LICENSE.md) file
#
# ## Description:
#
# Example script for running the Pre-FreeSurfer phase of the HCP Structural
# Preprocessing pipeline
#
# See [Glasser et al. 2013][GlasserEtAl].
#
# ## Prerequisites
#
# ### Installed software
#
# * FSL (version 5.0.6)
# * FreeSurfer (version 5.3.0-HCP)
# * gradunwarp (HCP version 1.0.2) - if doing gradient distortion correction
#
# ### Environment variables
#
# Should be set in script file pointed to by EnvironmentScript variable.
# See setting of the EnvironmentScript variable in the main() function
# below.
#
# * FSLDIR - main FSL installation directory
# * FREESURFER_HOME - main FreeSurfer installation directory
# * HCPPIPEDIR - main HCP Pipelines installation directory
# * CARET7DIR - main Connectome Workbench installation directory
# * PATH - must point to where gradient_unwarp.py is if doing gradient unwarping
#
# <!-- References -->
# [HCP]: http://www.humanconnectome.org
# [GlasserEtAl]: http://www.ncbi.nlm.nih.gov/pubmed/23668970
#
#~ND~END~

# Function: get_batch_options
# Description
#
#   Retrieve the following command line parameter values if specified
#
#   --StudyFolder= - primary study folder containing subject ID subdirectories
#   --Subjlist=    - quoted, space separated list of subject IDs on which
#                    to run the pipeline
#   --runlocal     - if specified (without an argument), processing is run
#                    on "this" machine as opposed to being submitted to a
#                    computing grid
#
#   Set the values of the following global variables to reflect command
#   line specified parameters
#
#   command_line_specified_study_folder
#   command_line_specified_subj_list
#   command_line_specified_run_local
#
#   These values are intended to be used to override any values set
#   directly within this script file
get_batch_options() {
	local arguments=("$@")

	unset command_line_specified_study_folder
	unset command_line_specified_subj
	unset command_line_specified_run_local
        unset command_line_specified_T1
        unset command_line_specified_T2
        unset command_line_specified_GREfieldmapMag
        unset command_line_specified_GREfieldmapPhase     
        unset command_line_specified_EnvironmentScript
        #unset command_line_specified_Hires

        cls_startT2="FALSE"
        cls_startAtlasRegistrationToMNI152="FALSE"
        unset cls_BrainSize

        #START240721
        unset T1wTemplate T1wTemplateBrain T1wTemplate2mm T2wTemplate T2wTemplateBrain T2wTemplate2mm TemplateMask Template2mmMask


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
                        --T1=*)
                                command_line_specified_T1=${argument#*=}
				index=$(( index + 1 ))
				;;
                        --T2=*)
                                command_line_specified_T2=${argument#*=}
				index=$(( index + 1 ))
				;;
                        --GREfieldmapMag=*)
                                command_line_specified_GREfieldmapMag=${argument#*=}
				index=$(( index + 1 ))
				;;
                        --GREfieldmapPhase=*)
                                command_line_specified_GREfieldmapPhase=${argument#*=}
				index=$(( index + 1 ))
				;;
                        --EnvironmentScript=*)
                                command_line_specified_EnvironmentScript=${argument#*=}
				index=$(( index + 1 ))
				;;

                        --startT2)
                            cls_startT2="TRUE"
                            index=$(( index + 1 ))
                            ;;
                        --startAtlasRegistrationToMNI152)
                            cls_AtlasRegistrationToMNI152="TRUE"
                            index=$(( index + 1 ))
                            ;;
                        --BrainSize=*)
                            cls_BrainSize=${argument#*=}
                            index=$(( index + 1 ))
                            ;;

                        #--Hires=*)
                        #        command_line_specified_Hires=${argument#*=}
			#	index=$(( index + 1 ))
			#	;;
                        --T1wTemplate=*)
                            T1wTemplate=${argument#*=}
                            ((++index))
                            ;;
                        --T1wTemplateBrain=*)
                            T1wTemplateBrain=${argument#*=}
                            ((++index))
                            ;;
                        --T1wTemplateLow=*)
                            T1wTemplate2mm=${argument#*=}
                            ((++index))
                            ;;
                        --T2wTemplate=*)
                            T2wTemplate=${argument#*=}
                            ((++index))
                            ;;
                        --T2wTemplateBrain=*)
                            T2wTemplateBrain=${argument#*=}
                            ((++index))
                            ;;
                        --T2wTemplateLow=*)
                            T2wTemplate2mm=${argument#*=}
                            ((++index))
                            ;;
                        --TemplateMask=*)
                            TemplateMask=${argument#*=}
                            ((++index))
                            ;;
                        --TemplateMaskLow=*)
                            Template2mmMask=${argument#*=}
                            ((++index))
                            ;;


			*)
				echo ""
				echo "ERROR: Unrecognized Option: ${argument}"
				echo ""
				exit 1
				;;
		esac
	done
}

# Function: main
# Description: main processing work of this script
main()
{
	get_batch_options "$@"

	# Set variable values that locate and specify data to process

        #START241002
	StudyFolder="${HOME}/projects/Pipelines_ExampleData" # Location of Subject folders (named by subjectID)


	Subjlist="100307"                                    # Space delimited list of subject IDs

	## Use any command line specified options to override any of the variable settings above
	#if [ -n "${command_line_specified_study_folder}" ]; then
	#	StudyFolder="${command_line_specified_study_folder}"
	#fi
        #START241002
	if [ -z "${command_line_specified_study_folder}" ]; then
            echo "MUST PROVIDE StudyFolder"
            echo "    Ex. --StudyFolder=/Users/Shared/10_Connectivity/derivatives/preprocessed/sub-1001/sub-1001_symatlas/pipeline7.4.1"
	    exit
        fi
	StudyFolder="${command_line_specified_study_folder}"


	if [ -n "${command_line_specified_subj}" ]; then
		Subjlist="${command_line_specified_subj}"
	fi

	# Set variable value that sets up environment
	#EnvironmentScript="${HOME}/projects/Pipelines/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script
	if [ -n "${command_line_specified_EnvironmentScript}" ]; then
	    EnvironmentScript="${command_line_specified_EnvironmentScript}"
        else
            echo "MUST PROVIDE EnvironmentScript"
            echo "    Ex. --EnvironmentScript=/home/usr/mcavoy/HCP/scripts/SetUpHCPPipeline_mm.sh"
	    exit
	fi

        #Hires="0.7"
	#if [ -n "${command_line_specified_Hires}" ]; then
	#	Hires="${command_line_specified_Hires}"
	#fi
        #echo "Hires: ${Hires}"
   

	# Report major script control variables to user
	echo "StudyFolder: ${StudyFolder}"
	echo "Subjlist: ${Subjlist}"
	echo "EnvironmentScript: ${EnvironmentScript}"
	echo "Run locally: ${command_line_specified_run_local}"

	# Set up pipeline environment variables and software
	source ${EnvironmentScript}

        #START240107
        #P0=${HCPMOD}/${P0}

	# Define processing queue to be used if submitted to job scheduler
	# if [ X$SGE_ROOT != X ] ; then
	#    QUEUE="-q long.q"
	#    QUEUE="-q veryshort.q"
	QUEUE="-q hcp_priority.q"
	# fi

	# If PRINTCOM is not a null or empty string variable, then
	# this script and other scripts that it calls will simply
	# print out the primary commands it otherwise would run.
	# This printing will be done using the command specified
	# in the PRINTCOM variable
	PRINTCOM=""
	# PRINTCOM="echo"

	#
	# Inputs:
	#
	# Scripts called by this script do NOT assume anything about the form of the
	# input names or paths. This batch script assumes the HCP raw data naming
	# convention, e.g.
	#
	# ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_T1w_MPR1.nii.gz
	# ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR2/${Subject}_3T_T1w_MPR2.nii.gz
	#
	# ${StudyFolder}/${Subject}/unprocessed/3T/T2w_SPC1/${Subject}_3T_T2w_SPC1.nii.gz
	# ${StudyFolder}/${Subject}/unprocessed/3T/T2w_SPC2/${Subject}_3T_T2w_SPC2.nii.gz
	#
	# ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Magnitude.nii.gz
	# ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Phase.nii.gz

	# Scan settings:
	#
	# Change the Scan Settings (e.g. Sample Spacings and $UnwarpDir) to match your
	# structural images. These are set to match the HCP-YA ("Young Adult") Protocol by default.
	# (i.e., the study collected on the customized Connectom scanner).

	# Readout Distortion Correction:
	#
	# You have the option of using either gradient echo field maps or spin echo
	# field maps to perform readout distortion correction on your structural
	# images, or not to do readout distortion correction at all.
	#
	# The HCP Pipeline Scripts currently support the use of gradient echo field
	# maps or spin echo field maps as they are produced by the Siemens Connectom
	# Scanner. They also support the use of gradient echo field maps as generated
	# by General Electric scanners.
	#
	# Change either the gradient echo field map or spin echo field map scan
	# settings to match your data. This script is setup to use gradient echo
	# field maps from the Siemens Connectom Scanner collected using the HCP-YA Protocol.

	# Gradient Distortion Correction:
	#
	# If using gradient distortion correction, use the coefficents from your
	# scanner. The HCP gradient distortion coefficents are only available through
	# Siemens. Gradient distortion in standard scanners like the Trio is much
	# less than for the HCP Connectom scanner.

	# DO WORK

	# Cycle through specified subjects
	for Subject in $Subjlist ; do
		echo $Subject

		# Input Images

		## Detect Number of T1w Images and build list of full paths to
		## T1w images
		#numT1ws=`ls ${StudyFolder}/${Subject}/unprocessed/3T | grep 'T1w_MPR.$' | wc -l`
		#echo "Found ${numT1ws} T1w Images for subject ${Subject}"
		#T1wInputImages=""
		#i=1
		#while [ $i -le $numT1ws ] ; do
		#	T1wInputImages=`echo "${T1wInputImages}${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR${i}/${Subject}_3T_T1w_MPR${i}.nii.gz@"`
		#	i=$(($i+1))
		#done
		## Detect Number of T2w Images and build list of full paths to
		## T2w images
		#numT2ws=`ls ${StudyFolder}/${Subject}/unprocessed/3T | grep 'T2w_SPC.$' | wc -l`
		#echo "Found ${numT2ws} T2w Images for subject ${Subject}"
		#T2wInputImages=""
		#i=1
		#while [ $i -le $numT2ws ] ; do
		#	T2wInputImages=`echo "${T2wInputImages}${StudyFolder}/${Subject}/unprocessed/3T/T2w_SPC${i}/${Subject}_3T_T2w_SPC${i}.nii.gz@"`
		#	i=$(($i+1))
		#done
                #START181203
                if [ -n "${command_line_specified_T1}" ]; then
                    T1wInputImages="${command_line_specified_T1}"
                    numT1ws=${#T1wInputImages[@]}
                    echo "T1wInputImages = ${#T1wInputImages[@]}"
                else
		    # Detect Number of T1w Images and build list of full paths to
		    # T1w images
		    numT1ws=`ls ${StudyFolder}/${Subject}/unprocessed/3T | grep 'T1w_MPR.$' | wc -l`
		    echo "Found ${numT1ws} T1w Images for subject ${Subject}"
		    T1wInputImages=""
		    i=1
		    while [ $i -le $numT1ws ] ; do
			    T1wInputImages=`echo "${T1wInputImages}${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR${i}/${Subject}_3T_T1w_MPR${i}.nii.gz@"`
			    i=$(($i+1))
		    done
                fi

                #START200305
                #T2wInputImages=

                if [ -n "${command_line_specified_T2}" ]; then
                    T2wInputImages="${command_line_specified_T2}"
                    numT2ws=${#T2wInputImages[@]}
                    echo "T2wInputImages = ${#T2wInputImages[@]}"

                #START200305
                #else
		#    # Detect Number of T2w Images and build list of full paths to
		#    # T2w images
		#    numT2ws=`ls ${StudyFolder}/${Subject}/unprocessed/3T | grep 'T2w_SPC.$' | wc -l`
		#    echo "Found ${numT2ws} T2w Images for subject ${Subject}"
		#    T2wInputImages=""
		#    i=1
		#    while [ $i -le $numT2ws ] ; do
		#	    T2wInputImages=`echo "${T2wInputImages}${StudyFolder}/${Subject}/unprocessed/3T/T2w_SPC${i}/${Subject}_3T_T2w_SPC${i}.nii.gz@"`
		#	    i=$(($i+1))
		#    done

                fi
         


		# Readout Distortion Correction:
		#
		#   Currently supported Averaging and readout distortion correction
		#   methods: (i.e. supported values for the AvgrdcSTRING variable in this
		#   script and the --avgrdcmethod= command line option for the
		#   PreFreeSurferPipeline.sh script.)
		#
		#   "NONE"
		#     Average any repeats but do no readout distortion correction
		#
		#   "FIELDMAP"
		#     This value is equivalent to the "SiemensFieldMap" value described
		#     below. Use of the "SiemensFieldMap" value is prefered, but
		#     "FIELDMAP" is included for backward compatibility with the versions
		#     of these scripts that only supported use of Siemens-specific
		#     Gradient Echo Field Maps and did not support Gradient Echo Field
		#     Maps from any other scanner vendor.
		#
		#   "TOPUP"
		#     Average any repeats and use Spin Echo Field Maps for readout
		#     distortion correction
		#
		#   "GeneralElectricFieldMap"
		#     Average any repeats and use General Electric specific Gradient
		#     Echo Field Map for readout distortion correction
		#
		#   "SiemensFieldMap"
		#     Average any repeats and use Siemens specific Gradient Echo
		#     Field Maps for readout distortion correction
		#
		# Current Setup is for Siemens specific Gradient Echo Field Maps
		#
		#   The following settings for AvgrdcSTRING, MagnitudeInputName,
		#   PhaseInputName, and TE are for using the Siemens specific
		#   Gradient Echo Field Maps that are collected and used in the
		#   standard HCP-YA protocol.
		#
		#   Note: The AvgrdcSTRING variable could also be set to the value
		#   "FIELDMAP" which is equivalent to "SiemensFieldMap".

		#AvgrdcSTRING="SiemensFieldMap"
                #START181206
		AvgrdcSTRING="NONE"

		# ----------------------------------------------------------------------
		# Variables related to using Siemens specific Gradient Echo Field Maps
		# ----------------------------------------------------------------------

		## The MagnitudeInputName variable should be set to a 4D magitude volume
		## with two 3D timepoints or "NONE" if not used
		#MagnitudeInputName="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Magnitude.nii.gz"
                #
		## The PhaseInputName variable should be set to a 3D phase difference
		## volume or "NONE" if not used
		#PhaseInputName="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Phase.nii.gz"
                #
		## The TE variable should be set to 2.46ms for 3T scanner, 1.02ms for 7T
		## scanner or "NONE" if not using
		#TE="2.46"
                #START181205
                # The MagnitudeInputName variable should be set to a 4D magitude volume
                # with two 3D timepoints or "NONE" if not used
                if [ -n "${command_line_specified_GREfieldmapMag}" ]; then
                    MagnitudeInputName="${command_line_specified_GREfieldmapMag}"
                else
                    MagnitudeInputName="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Magnitude.nii.gz"
                fi

                # The PhaseInputName variable should be set to a 3D phase difference
                # volume or "NONE" if not used
                if [ -n "${command_line_specified_GREfieldmapPhase}" ]; then
                    PhaseInputName="${command_line_specified_GREfieldmapPhase}"                    
                else
                    PhaseInputName="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_FieldMap_Phase.nii.gz"
                fi

                # The TE variable should be set to 2.46ms for 3T scanner, 1.02ms for 7T
                # scanner or "NONE" if not using
                echo "MagnitudeInputName = ${MagnitudeInputName}"
                echo "PhaseInputName = ${PhaseInputName}"
                if [ "${MagnitudeInputName}" == "NONE" ] || [ "${PhaseInputName}" == "NONE" ]; then
                    MagnitudeInputName="NONE";PhaseInputName="NONE";TE="NONE";
                else
                    TE="2.46"
                fi
                    


		# ----------------------------------------------------------------------
		# Variables related to using Spin Echo Field Maps
		# ----------------------------------------------------------------------

		# The following variables would be set to values other than "NONE" for
		# using Spin Echo Field Maps (i.e. when AvgrdcSTRING="TOPUP")

		# The SpinEchoPhaseEncodeNegative variable should be set to the
		# spin echo field map volume with a negative phase encoding direction
		# (LR if using a pair of LR/RL Siemens Spin Echo Field Maps (SEFMs);
		# AP if using a pair of AP/PA Siemens SEFMS)
		# and set to "NONE" if not using SEFMs
		# (i.e. if AvgrdcSTRING is not equal to "TOPUP")
		#
		# Example values for when using Spin Echo Field Maps from a Siemens machine:
		#   ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_SpinEchoFieldMap_LR.nii.gz
		#   ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_SpinEchoFieldMap_AP.nii.gz
		SpinEchoPhaseEncodeNegative="NONE"

		# The SpinEchoPhaseEncodePositive variable should be set to the
		# spin echo field map volume with positive phase encoding direction
		# (RL if using a pair of LR/RL SEFMs; PA if using a AP/PA pair),
		# and set to "NONE" if not using Spin Echo Field Maps
		# (i.e. if AvgrdcSTRING is not equal to "TOPUP")
		#
		# Example values for when using Spin Echo Field Maps from a Siemens machine:
		#   ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_SpinEchoFieldMap_RL.nii.gz
		#   ${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_SpinEchoFieldMap_PA.nii.gz
		SpinEchoPhaseEncodePositive="NONE"

		# Echo Spacing or Dwelltime of spin echo EPI MRI image. Specified in seconds.
		# Set to "NONE" if not used.
		#
		# Dwelltime = 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples)
		# DICOM field (0019,1028) = BandwidthPerPixelPhaseEncode
		# DICOM field (0051,100b) = AcquisitionMatrixText first value (# of phase encoding samples).
		# On Siemens, iPAT/GRAPPA factors have already been accounted for.
		#
		# Example value for when using Spin Echo Field Maps:
		#   0.000580002668012
		DwellTime="NONE"

		# Spin Echo Unwarping Direction
		# x or y (minus or not does not matter)
		# "NONE" if not used
		#
		# Example values for when using Spin Echo Field Maps: x, -x, y, -y
		# Note: +x or +y are not supported. For positive values, DO NOT include the + sign
		## MPH: Why do we say that "minus or not does not matter", but then list -x and -y as example values??
		SEUnwarpDir="NONE"

		# Topup Configuration file
		# "NONE" if not used
		TopupConfig="NONE"

		# ----------------------------------------------------------------------
		# Variables related to using General Electric specific Gradient Echo
		# Field Maps
		# ----------------------------------------------------------------------

		# The following variables would be set to values other than "NONE" for
		# using General Electric specific Gradient Echo Field Maps (i.e. when
		# AvgrdcSTRING="GeneralElectricFieldMap")

		# Example value for when using General Electric Gradient Echo Field Map
		#
		# GEB0InputName should be a General Electric style B0 fieldmap with two
		# volumes
		#   1) fieldmap in deg and
		#   2) magnitude,
		# set to NONE if using TOPUP or FIELDMAP/SiemensFieldMap
		#
		#   GEB0InputName="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${Subject}_3T_GradientEchoFieldMap.nii.gz"
		GEB0InputName="NONE"

		# Templates
                if [ -f $StudyFoler/templates/export_templates.sh ];then
                    echo Running $StudyFoler/templates/export_templates.sh
                    source $StudyFoler/templates/export_templates.sh 
                else
                    # Hires T1w MNI template
                    if [ -z "T1wTemplate" ];then
                        echo No value for T1wTemplate. Abort!
                        exit
                    fi
                    # Hires brain extracted MNI template
                    if [ -z "T1wTemplateBrain" ];then
                        echo No value for T1wTemplateBrain. Abort!
                        exit
                    fi
                    # Lowres T1w MNI template
                    if [ -z "T1wTemplate2mm" ];then
                        echo No value for T1wTemplate2mm. Abort!
                        exit
                    fi
                    # Hires T2w MNI Template
                    if [ -z "T2wTemplate" ];then
                        echo No value for T2wTemplate. Abort!
                        exit
                    fi
                    # Hires T2w brain extracted MNI Template
                    if [ -z "T2wTemplateBrain" ];then
                        echo No value for T2wTemplateBrain. Abort!
                        exit
                    fi
                    # Lowres T2w MNI Template
                    if [ -z "T2wTemplate2mm" ];then
                        echo No value for T2wTemplate2mm. Abort!
                        exit
                    fi
                    # Hires MNI brain mask template
                    if [ -z "TemplateMask" ];then
                        echo No value for TemplateMask. Abort!
                        exit
                    fi
                    # Lowres MNI brain mask template
                    if [ -z "Template2mmMask" ];then
                        echo No value fo Template2mmMask. Abort!
                        exit
                    fi
                fi
                echo T1wTemplate = $T1wTemplate
                echo T1wTemplateBrain = $T1wTemplateBrain
                echo T1wTemplate2mm = $T1wTemplate2mm
                echo T2wTemplate = $T2wTemplate
                echo T2wTemplateBrain = $T2wTemplateBrain
                echo T2wTemplate2mm = $T2wTemplate2mm
                echo TemplateMask = $TemplateMask
                echo Template2mmMask = $Template2mmMask
                


		# Structural Scan Settings
		#
		# Note that "UnwarpDir" is the *readout* direction of the *structural* (T1w,T2w)
		# images, and should not be confused with "SEUnwarpDir" which is the *phase* encoding direction
		# of the Spin Echo Field Maps (if using them).
		#
		# set all these values to NONE if not doing readout distortion correction
		#
		# Sample values for when using General Electric structurals
		#   T1wSampleSpacing="0.000011999" # For General Electric scanners, 1/((0018,0095)*(0028,0010))
		#   T2wSampleSpacing="0.000008000" # For General Electric scanners, 1/((0018,0095)*(0028,0010))
		#   UnwarpDir="y"  ## MPH: This doesn't seem right. Is this accurate??

		# The values set below are for the HCP-YA Protocol using the Siemens
		# Connectom Scanner

		# DICOM field (0019,1018) in s or "NONE" if not used
		#T1wSampleSpacing="0.0000074"
                #START181205
		T1wSampleSpacing="NONE"

		# DICOM field (0019,1018) in s or "NONE" if not used
		#T2wSampleSpacing="0.0000021"
                #START181205
		T2wSampleSpacing="NONE"

		# z appears to be the appropriate polarity for the 3D structurals collected on Siemens scanners
		# or "NONE" if not used
		#UnwarpDir="z"
                #START181205
		UnwarpDir="NONE"

		# Other Config Settings

		## BrainSize in mm, 150 for humans
		#BrainSize="150"
                #START201105
                if [ -n "${cls_BrainSize}" ] ; then
                    BrainSize=${cls_BrainSize}
                else
                    BrainSize="150" 
                fi
                echo "BrainSize = ${BrainSize}"


		# FNIRT 2mm T1w Config
		FNIRTConfig="${HCPPIPEDIR_Config}/T1_2_MNI152_2mm.cnf"

		# Location of Coeffs file or "NONE" to skip
		# GradientDistortionCoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad"

		# Set to NONE to skip gradient distortion correction
		GradientDistortionCoeffs="NONE"

		# Establish queuing command based on command line option
		if [ -n "${command_line_specified_run_local}" ] ; then

			#echo "About to run ${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh"
                        #START220203
			echo "About to run ${P0}"

			queuing_command=""
		else
			#echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh"
                        #START220502 
                        echo "About to use fsl_sub to queue or run ${P0}"

			queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
		fi

		# Run (or submit to be run) the PreFreeSurferPipeline.sh script
		# with all the specified parameter values

		#${queuing_command} ${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh \
                #START200305
                echo "cls_startT2 = $cls_startT2"
                echo "cls_AtlasRegistrationToMNI152 = $cls_AtlasRegistrationToMNI152"

                ${queuing_command} ${P0} \
                    --path="$StudyFolder" \
                    --subject="$Subject" \
                    --t1="$T1wInputImages" \
                    --t2="$T2wInputImages" \
                    --t1template="$T1wTemplate" \
                    --t1templatebrain="$T1wTemplateBrain" \
                    --t1template2mm="$T1wTemplate2mm" \
                    --t2template="$T2wTemplate" \
                    --t2templatebrain="$T2wTemplateBrain" \
                    --t2template2mm="$T2wTemplate2mm" \
                    --templatemask="$TemplateMask" \
                    --template2mmmask="$Template2mmMask" \
                    --brainsize="$BrainSize" \
                    --fnirtconfig="$FNIRTConfig" \
                    --fmapmag="$MagnitudeInputName" \
                    --fmapphase="$PhaseInputName" \
                    --fmapgeneralelectric="$GEB0InputName" \
                    --echodiff="$TE" \
                    --SEPhaseNeg="$SpinEchoPhaseEncodeNegative" \
                    --SEPhasePos="$SpinEchoPhaseEncodePositive" \
                    --echospacing="$DwellTime" \
                    --seunwarpdir="$SEUnwarpDir" \
                    --t1samplespacing="$T1wSampleSpacing" \
                    --t2samplespacing="$T2wSampleSpacing" \
                    --unwarpdir="$UnwarpDir" \
                    --gdcoeffs="$GradientDistortionCoeffs" \
                    --avgrdcmethod="$AvgrdcSTRING" \
                    --topupconfig="$TopupConfig" \
                    --printcom=$PRINTCOM \
                    --startT2=$cls_startT2 \
                    --startAtlasRegistrationToMNI152=$cls_startAtlasRegistrationToMNI152
	done
}

# Invoke the main function to get things started
main "$@"

#START230608
echo -e "**** Exiting $0 ****\n"
