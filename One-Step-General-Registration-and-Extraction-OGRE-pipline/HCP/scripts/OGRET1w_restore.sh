#!/usr/bin/env bash
set -e

echo -e "\nRunning $0"

get_batch_options() {
    local arguments=("$@")

    unset command_line_specified_t1
    unset command_line_specified_mask
    unset command_line_specified_outpath
    unset command_line_specified_EnvironmentScript

    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --t1=*)
                command_line_specified_t1=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --mask=*)
                command_line_specified_mask=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --outpath=*)
                command_line_specified_outpath=${argument#*=}
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

if [ -n "${command_line_specified_t1}" ]; then
    t1=$command_line_specified_t1
else
    echo "Need to specify --t1"
    exit
fi
if [ -n "${command_line_specified_mask}" ]; then
    mask=$command_line_specified_mask
else
    echo "Need to specify --mask"
    exit
fi
if [ -n "${command_line_specified_outpath}" ]; then
    outpath=$command_line_specified_outpath
else
    echo "Need to specify --outpath"
    exit
fi
if [ -n "${command_line_specified_EnvironmentScript}" ]; then
    EnvironmentScript=$command_line_specified_EnvironmentScript
else
    echo "Need to specify --EnvironmentScript"
    exit
fi

cp -p $t1 $outpath 

source $EnvironmentScript

${FSLDIR}/bin/fslmaths $t1 -mas $mask $outpath/T1w_restore_brain.2.nii.gz 

echo "Finished $0"
