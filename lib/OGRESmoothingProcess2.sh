#!/usr/bin/env bash
set -e

# https://stackoverflow.com/questions/3869072/test-for-non-zero-length-string-in-bash-n-var-or-var/49825114#49825114
# https://stackoverflow.com/questions/73885999/how-to-create-a-json-file-with-jq
# https://stackoverflow.com/questions/48470049/build-a-json-string-with-bash-variables

root0=${0##*/}
helpmsg(){
    echo "Required: ${root0} <scanlist.csv file(s)>"
    echo "    --fMRITimeSeriesResults -fMRITimeSeriesResults"
    echo "        Time series files (eg BOLD.ni or BOLD.nii.gz). Arguments without options are assumed to be scanlist.csv files."
    echo "    -f --fwhm -fwhm"
    echo "        Smoothing (mm) for SUSAN. Multiple values ok." 
    echo "    -p --paradigm_hp_sec -paradigm_hp_sec"
    echo "        High pass filter cutoff in seconds. Optional." 
    echo "    --TR -TR"
    echo "        Sampling rate. Optional if time series includes JSON." 
    echo "    -h --help -help"
    echo "        Echo this help message."
    }
if((${#@}<1));then
    helpmsg
    exit
fi

unset paradigm_hp_sec TR #DON'T SET fwhm dat unexpected

arg=("$@")
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        --fMRITimeSeriesResults | -fMRITimeSeriesResults)
            dat+=(${arg[((++i))]})
            for((j=i;j<${#@};++i));do #i is incremented only if dat is appended
                tmp=(${arg[((++j))]})
                [ "${tmp::1}" = "-" ] && break
                dat+=(${tmp[@]})
            done
            ;;
        -f | --fwhm | -fwhm)
            fwhm+=(${arg[((++i))]})
            for((j=i;j<${#@};++i));do #i is incremented only if fwhm is appended
                tmp=(${arg[((++j))]})
                [ "${tmp::1}" = "-" ] && break
                fwhm+=(${tmp[@]})
            done
            ;;
        -p | --paradigm_hp_sec | -paradigm_hp_sec)
            paradigm_hp_sec=${arg[((++i))]}
            ;;
        --TR | -TR)
            TR=${arg[((++i))]}
            ;;
        -h | --help | -help)
            helpmsg
            exit
            ;;
        *) unexpected+=(${arg[i]})
            ;;
    esac
done
echo $0 $@

STARTHERE








get_batch_options() {
    local arguments=("$@")

    unset command_line_specified_fMRITimeSeriesResults
    unset command_line_specified_fwhm
    unset command_line_specified_paradigm_hp_sec
    unset command_line_specified_TR

    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --fMRITimeSeriesResults=*)
                command_line_specified_fMRITimeSeriesResults=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --fwhm=*)
                command_line_specified_fwhm=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --paradigm_hp_sec=*)
                command_line_specified_paradigm_hp_sec=${argument#*=}
                index=$(( index + 1 ))
                ;;
            --TR=*)
                command_line_specified_TR=${argument#*=}
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

if [ -n "${command_line_specified_fMRITimeSeriesResults}" ]; then

    fMRITimeSeriesResults=($command_line_specified_fMRITimeSeriesResults)
    #START220721
    #prefiltered_func_data_unwarp=($command_line_specified_fMRITimeSeriesResults)

else
    echo "Need to specify --fMRITimeSeriesResults"
    exit
fi
if [ -n "${command_line_specified_fwhm}" ]; then
    FWHM=($command_line_specified_fwhm)
else
    echo "Need to specify --fwhm"
    exit
fi


if [ -n "${command_line_specified_paradigm_hp_sec}" ]; then
    PARADIGM_HP_SEC=$command_line_specified_paradigm_hp_sec
    if [ -n "${command_line_specified_TR}" ]; then
        TR=($command_line_specified_TR)

        #START240521
        if((${#fMRITimeSeriesResults[@]}!=${#TR[@]}));then
            echo "fMRITimeSeriesResults has ${#fMRITimeSeriesResults[@]} elements, but TR has ${#TR[@]} elements. Must be equal. Abort!"
            exit
        fi

    else
        #echo "Need to specify --TR"
        #exit
        #START240521
        echo "--TR not provided. Will look for it in the json files."
    fi
fi


#if [ -n "${command_line_specified_EnvironmentScript}" ]; then
#    EnvironmentScript=$command_line_specified_EnvironmentScript
#else
#    echo "Need to specify --EnvironmentScript"
#    exit
#fi
#if((${#fMRITimeSeriesResults[@]}!=${#TR[@]}));then
#    echo "fMRITimeSeriesResults has ${#fMRITimeSeriesResults[@]} elements, but TR has ${#TR[@]} elements. Must be equal. Abort!"
#    exit
#fi
#if [ -n "${command_line_specified_SmoothFolder}" ]; then
#    SmoothFolder=${command_line_specified_SmoothFolder}/
#else
#    SmoothFolder=
#fi
#source $EnvironmentScript

echo "**** Running $0 ****"

for((i=0;i<${#fMRITimeSeriesResults[@]};++i));do

    if [ ! -f "${fMRITimeSeriesResults[i]}" ];then
        echo ${fMRITimeSeriesResults[i]} not found
        continue
    fi

    #START240521
    if [ -n "${command_line_specified_paradigm_hp_sec}" ];then
        if [ -n "${command_line_specified_TR}" ];then
            TR0=${TR[i]}
        else

            #json=${fMRITimeSeriesResults[i]%%.*}.json
            #START241109
            json=${fMRITimeSeriesResults[i]//nii.gz/json}

            if [ ! -f $json ];then
                echo " $json not found"
                continue
            fi
            IFS=$' ,' read -ra line0 < <( grep RepetitionTime $json )
            TR0=${line0[1]}
            echo "Found TR=${TR0}"
        fi
    fi


    prefiltered_func_data_unwarp=${fMRITimeSeriesResults[i]}
    #od0=${fMRITimeSeriesResults[i]%/*}
    sd0=${fMRITimeSeriesResults[i]%/*}/SCRATCH$(date +%y%m%d%H%M%S)
    echo "sd0=${sd0}"
    #root0=${fMRITimeSeriesResults[i]%.nii*}
    root0=${fMRITimeSeriesResults[i]%_bold.nii*}
    #echo "od0=${od0}"
    echo "root0=${root0}"
    #exit

    mkdir -p ${sd0}

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_unwarp -Tmean mean_func
    #${FSLDIR}/bin/fslmaths $prefiltered_func_data_unwarp -Tmean mean_func
    ${FSLDIR}/bin/fslmaths $prefiltered_func_data_unwarp -Tmean ${sd0}/mean_func

    ##/usr/local/fsl/bin/bet2 mean_func mask -f 0.3 -n -m; /usr/local/fsl/bin/immv mask_mask mask
    #${FSLDIR}/bin/bet2 mean_func mask -f 0.3 -n -m; ${FSLDIR}/bin/immv mask_mask mask
    ${FSLDIR}/bin/bet2 ${sd0}/mean_func ${sd0}/mask -f 0.3 -n -m; ${FSLDIR}/bin/immv ${sd0}/mask_mask ${sd0}/mask

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_unwarp -mas mask prefiltered_func_data_bet
    #${FSLDIR}/bin/fslmaths $prefiltered_func_data_unwarp -mas mask prefiltered_func_data_bet
    ${FSLDIR}/bin/fslmaths $prefiltered_func_data_unwarp -mas ${sd0}/mask ${sd0}/prefiltered_func_data_bet

    #/usr/local/fsl/bin/fslstats prefiltered_func_data_bet -p 2 -p 98
    #p98=($(${FSLDIR}/bin/fslstats prefiltered_func_data_bet -p 2 -p 98))
    p98=($(${FSLDIR}/bin/fslstats ${sd0}/prefiltered_func_data_bet -p 2 -p 98))
    declare -p p98 

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_bet -thr [97333.005859 / 10] -Tmin -bin mask -odt char
    thr=($(echo "scale=6; ${p98[1]} / 10" | bc))
    declare -p thr
    #${FSLDIR}/bin/fslmaths prefiltered_func_data_bet -thr $thr -Tmin -bin mask -odt char
    ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_bet -thr $thr -Tmin -bin ${sd0}/mask -odt char

    ##/usr/local/fsl/bin/fslstats prefiltered_func_data_unwarp -k mask -p 50
    #p50=($(${FSLDIR}/bin/fslstats $prefiltered_func_data_unwarp -k mask -p 50))
    p50=($(${FSLDIR}/bin/fslstats $prefiltered_func_data_unwarp -k ${sd0}/mask -p 50))
    declare -p p50 

    ##/usr/local/fsl/bin/fslmaths mask -dilF mask
    #${FSLDIR}/bin/fslmaths mask -dilF mask
    ${FSLDIR}/bin/fslmaths ${sd0}/mask -dilF ${sd0}/mask

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_unwarp -mas mask prefiltered_func_data_thresh
    #${FSLDIR}/bin/fslmaths $prefiltered_func_data_unwarp -mas mask prefiltered_func_data_thresh
    ${FSLDIR}/bin/fslmaths $prefiltered_func_data_unwarp -mas ${sd0}/mask ${sd0}/prefiltered_func_data_thresh

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_thresh -Tmean mean_func
    #${FSLDIR}/bin/fslmaths prefiltered_func_data_thresh -Tmean mean_func
    ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_thresh -Tmean ${sd0}/mean_func

    for((j=0;j<${#FWHM[@]};++j));do

        ##/usr/local/fsl/bin/susan prefiltered_func_data_thresh [8218.408203 * 0.75] [filter FWHM converted to sigma] 3 1 1 mean_func [8218.408203 * 0.75] prefiltered_func_data_smooth
        bt=($(echo "scale=6; ${p50} * 0.75" | bc))
        declare -p bt 
        sigma=($(echo "scale=6; ${FWHM[j]} / 2.354820" | bc)) #https://brainder.org/2011/08/20/gaussian-kernels-convert-fwhm-to-sigma/ sigma=FWHM/sqrt(8ln2) for gaussian kernels
        declare -p sigma 
        #${FSLDIR}/bin/susan prefiltered_func_data_thresh $bt $sigma 3 1 1 mean_func $bt prefiltered_func_data_smooth
        ${FSLDIR}/bin/susan ${sd0}/prefiltered_func_data_thresh $bt $sigma 3 1 1 ${sd0}/mean_func $bt ${sd0}/prefiltered_func_data_smooth

        #/usr/local/fsl/bin/fslmaths prefiltered_func_data_smooth -mas mask prefiltered_func_data_smooth
        #${FSLDIR}/bin/fslmaths prefiltered_func_data_smooth -mas mask prefiltered_func_data_smooth
        ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_smooth -mas ${sd0}/mask ${sd0}/prefiltered_func_data_smooth

        ##global intensity normalize to a value of 10000
        ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_smooth -mul {10000/8218.408203=1.21678064085} prefiltered_func_data_intnorm
        mul=($(echo "scale=6; 10000 / ${p50} " | bc))
        declare -p mul 
        #${FSLDIR}/bin/fslmaths prefiltered_func_data_smooth -mul $mul prefiltered_func_data_intnorm
        ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_smooth -mul $mul ${sd0}/prefiltered_func_data_intnorm

        ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_intnorm -Tmean tempMean
        #${FSLDIR}/bin/fslmaths prefiltered_func_data_intnorm -Tmean tempMean
        ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_intnorm -Tmean ${sd0}/tempMean

        #/usr/local/fsl/bin/fslmaths prefiltered_func_data_intnorm -bptf 45.4545454545 -1 -add tempMean prefiltered_func_data_tempfilt
        #bptf=($(echo "scale=6; ${PARADIGM_HP_SEC} / (2*${TR[i]})" | bc))
        #declare -p bptf 
        #out0=${root0}_susan-${FWHM[j]}mm_hptf-${PARADIGM_HP_SEC}s_bold
        #${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_intnorm -bptf ${bptf} -1 -add ${sd0}/tempMean ${out0}
        #START240521
        if [ -n "${command_line_specified_paradigm_hp_sec}" ];then
            bptf=($(echo "scale=6; ${PARADIGM_HP_SEC} / (2*${TR0})" | bc))
            declare -p bptf 
            out0=${root0}_susan-${FWHM[j]}mm_hptf-${PARADIGM_HP_SEC}s_bold
            ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_intnorm -bptf ${bptf} -1 -add ${sd0}/tempMean ${out0}
        else
            out0=${root0}_susan-${FWHM[j]}mm_bold
            ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_intnorm -add ${sd0}/tempMean ${out0}
        fi

        echo "Output written to ${out0}"

        #START241109
        OGREjson.py -f "${out0}.nii.gz" -j "${fMRITimeSeriesResults[i]//nii.gz/json}"

    done

    rm -r ${sd0}
done
echo "**** Finished $0 ****"
