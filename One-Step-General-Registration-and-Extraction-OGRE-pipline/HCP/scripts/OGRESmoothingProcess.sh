#!/usr/bin/env bash
set -e

#echo -e "\nRunning $0"
echo "**** Running $0 ****"

get_batch_options() {
    local arguments=("$@")

    unset command_line_specified_fMRITimeSeriesResults
    unset command_line_specified_fwhm
    unset command_line_specified_paradigm_hp_sec
    unset command_line_specified_TR
    #unset command_line_specified_SmoothFolder
    unset command_line_specified_EnvironmentScript

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
            #--SmoothFolder=*)
            #    command_line_specified_SmoothFolder=${argument#*=}
            #    index=$(( index + 1 ))
            #    ;;
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
    #PARADIGM_HP_SEC=($command_line_specified_paradigm_hp_sec)
    PARADIGM_HP_SEC=$command_line_specified_paradigm_hp_sec
else
    echo "Need to specify --paradigm_hp_sec"
    exit
fi
if [ -n "${command_line_specified_TR}" ]; then
    TR=($command_line_specified_TR)
else
    echo "Need to specify --TR"
    exit
fi
if [ -n "${command_line_specified_EnvironmentScript}" ]; then
    EnvironmentScript=$command_line_specified_EnvironmentScript
else
    echo "Need to specify --EnvironmentScript"
    exit
fi
if((${#fMRITimeSeriesResults[@]}!=${#TR[@]}));then
    echo "fMRITimeSeriesResults has ${#fMRITimeSeriesResults[@]} elements, but TR has ${#TR[@]} elements. Must be equal. Abort!"
    exit
fi

#if [ -n "${command_line_specified_SmoothFolder}" ]; then
#    SmoothFolder=${command_line_specified_SmoothFolder}/
#else
#    SmoothFolder=
#fi

source $EnvironmentScript

for((i=0;i<${#fMRITimeSeriesResults[@]};++i));do

    if [ ! -f "${fMRITimeSeriesResults[i]}" ];then
        echo ${fMRITimeSeriesResults[i]} not found.
        continue
    fi


    prefiltered_func_data_unwarp=${fMRITimeSeriesResults[i]}
    #od0=${fMRITimeSeriesResults[i]%/*}
    sd0=${fMRITimeSeriesResults[i]%/*}/SCRATCH$(date +%y%m%d%H%M%S)
    echo "sd0=${sd0}"
    root0=${fMRITimeSeriesResults[i]%.nii*}
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
        bptf=($(echo "scale=6; ${PARADIGM_HP_SEC} / (2*${TR[i]})" | bc))
        declare -p bptf 
        #${FSLDIR}/bin/fslmaths prefiltered_func_data_intnorm -bptf ${bptf} -1 -add tempMean prefiltered_func_data_tempfilt
        #${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_intnorm -bptf ${bptf} -1 -add ${sd0}/tempMean ${root0}_SUSAN${FWHM[j]}mmHPTF${PARADIGM_HP_SEC}s 
        ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_intnorm -bptf ${bptf} -1 -add ${sd0}/tempMean ${root0}_SUSAN-${FWHM[j]}_filt-${PARADIGM_HP_SEC}
    done

    rm -r ${sd0}
done
echo "**** Finished $0 ****"
