#!/usr/bin/env bash 

P0=${OGREDIR}/lib/OGREPostFreeSurferPipeline.sh

get_batch_options() {
    local arguments=("$@")

    unset command_line_specified_study_folder
    unset command_line_specified_subj
    unset command_line_specified_run_local

    erosion=2
    dilation=3

    unset command_line_specified_EnvironmentScript

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
            --erosion=*)
                erosion=${argument#*=}
                index=$(( index + 1 ))
                ;;

            --dilation=*)
                dilation=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --EnvironmentScript=*)
                command_line_specified_EnvironmentScript=${argument#*=}
                index=$(( index + 1 ))
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

get_batch_options "$@"

#StudyFolder="${HOME}/projects/Pipelines_ExampleData" #Location of Subject folders (named by subjectID)
#Subjlist="100307" #Space delimited list of subject IDs

#EnvironmentScript="${HOME}/projects/Pipelines/Examples/Scripts/SetUpHCPPipeline.sh" #Pipeline environment script
if [ -n "${command_line_specified_EnvironmentScript}" ]; then
    EnvironmentScript="${command_line_specified_EnvironmentScript}"
else
    echo "MUST PROVIDE EnvironmentScript"
    echo "    Ex. --EnvironmentScript=OGREDIR/lib/OGRESetUpHCPPipeline.sh" # swap 240425
    exit
fi


if [ -n "${command_line_specified_study_folder}" ]; then
    StudyFolder="${command_line_specified_study_folder}"
fi

if [ -n "${command_line_specified_subj}" ]; then
    Subjlist="${command_line_specified_subj}"
fi

# Requirements for this script
#  installed versions of: FSL (version 5.0.6), FreeSurfer (version 5.3.0-HCP), gradunwarp (HCP version 1.0.2)
#  environment: FSLDIR , FREESURFER_HOME , HCPPIPEDIR , CARET7DIR , PATH (for gradient_unwarp.py)

#Set up pipeline environment variables and software
source ${EnvironmentScript}

#START220211
#P0=${HCPMOD}/${P0}

# Log the originating call
echo "$@"

#if [ X$SGE_ROOT != X ] ; then
#    QUEUE="-q long.q"
    QUEUE="-q hcp_priority.q"
#fi

#QUEUE="-q veryshort.q"


########################################## INPUTS ########################################## 

#Scripts called by this script do assume they run on the outputs of the FreeSurfer Pipeline

######################################### DO WORK ##########################################


for Subject in $Subjlist ; do
  echo $Subject

  #Input Variables
  SurfaceAtlasDIR="${HCPPIPEDIR_Templates}/standard_mesh_atlases"
  GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/91282_Greyordinates"
  GrayordinatesResolutions="2" #Usually 2mm, if multiple delimit with @, must already exist in templates dir
  HighResMesh="164" #Usually 164k vertices
  LowResMeshes="32" #Usually 32k vertices, if multiple delimit with @, must already exist in templates dir
  SubcorticalGrayLabels="${HCPPIPEDIR_Config}/FreeSurferSubcorticalLabelTableLut.txt"
  FreeSurferLabels="${HCPPIPEDIR_Config}/FreeSurferAllLut.txt"
  ReferenceMyelinMaps="${HCPPIPEDIR_Templates}/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"
  # RegName="MSMSulc" #MSMSulc is recommended, if binary is not available use FS (FreeSurfer)
  RegName="FS" 

  if [ -n "${command_line_specified_run_local}" ] ; then
      echo "About to run ${P0}"
      queuing_command=""
  else
      echo "About to use fsl_sub to queue or run ${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh"
      queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
  fi

  ${queuing_command} ${P0} \
      --path="$StudyFolder" \
      --subject="$Subject" \
      --surfatlasdir="$SurfaceAtlasDIR" \
      --grayordinatesdir="$GrayordinatesSpaceDIR" \
      --grayordinatesres="$GrayordinatesResolutions" \
      --hiresmesh="$HighResMesh" \
      --lowresmesh="$LowResMeshes" \
      --subcortgraylabels="$SubcorticalGrayLabels" \
      --freesurferlabels="$FreeSurferLabels" \
      --refmyelinmaps="$ReferenceMyelinMaps" \
      --regname="$RegName" \
      --erosion="$erosion" \
      --dilation="$dilation"

  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...
  
   echo -e "set -- --path="$StudyFolder" \n\
       --subject="$Subject" \n\
       --surfatlasdir="$SurfaceAtlasDIR" \n\
       --grayordinatesdir="$GrayordinatesSpaceDIR" \n\
       --grayordinatesres="$GrayordinatesResolutions" \n\
       --hiresmesh="$HighResMesh" \n\
       --lowresmesh="$LowResMeshes" \n\
       --subcortgraylabels="$SubcorticalGrayLabels" \n\
       --freesurferlabels="$FreeSurferLabels" \n\
       --refmyelinmaps="$ReferenceMyelinMaps" \n\
       --regname="$RegName" \n\
       --dilation="$dilation" \n\
       --erosion="$erosion"" #second " matches one before set
      
   echo ". ${EnvironmentScript}"
done
