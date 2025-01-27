#!/usr/bin/env bash
set -e

# https://stackoverflow.com/questions/3869072/test-for-non-zero-length-string-in-bash-n-var-or-var/49825114#49825114
# https://stackoverflow.com/questions/73885999/how-to-create-a-json-file-with-jq
# https://stackoverflow.com/questions/48470049/build-a-json-string-with-bash-variables

echo "**** Running $0 ****"

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

unset paradigm_hp_sec #DON'T SET dat fwhm TR unexpected

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
            TR+=(${arg[((++i))]})
            for((j=i;j<${#@};++i));do #i is incremented only if TR is appended
                tmp=(${arg[((++j))]})
                [ "${tmp::1}" = "-" ] && break
                TR+=(${tmp[@]})
            done
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

[[ ${unexpected} ]] && dat+=(${unexpected[@]})
if [[ ! ${dat} ]];then
    echo "Need to provide --fMRITimeSeriesResults"
    exit
fi
if [[ ! ${fwhm} ]];then
    echo "Need to provide --fwhm"
    exit
fi

if [[ ${paradigm_hp_sec} ]];then
    if [[ ! ${TR} ]];then
        echo "--TR not provided. Will look for it in the json files."
    else 
        if((${#dat[@]}!=${#TR[@]}));then
            if((${#TR[@]}==1));then
                echo "fMRITimeSeriesResults has ${#dat[@]} elements, but TR has ${#TR[@]} element with value ${TR[@]}."
                echo "We will use TR=$TR for all fMRITimeSeriesResults."
                for((i=0;i<${#dat[@]};++i));do
                    TR+=(${TR[0]})
                done
            elif((${#dat[@]}<${#TR[@]}));then 
                echo "fMRITimeSeriesResults has ${#dat[@]} elements, but TR has ${#TR[@]} elements with values ${TR[@]}."
                echo "We will use the first ${#dat[@]} elements."
            else #dat has more elements than TR, but TR has more than one element
                echo "fMRITimeSeriesResults has ${#dat[@]} elements, but TR has ${#TR[@]} elements with values ${TR[@]}."
                echo "The number of elements for both must be the same. Abort!"
                exit
            fi
        fi
    fi
fi

#echo "TR = ${TR[@]}"


for((i=0;i<${#dat[@]};++i));do
    if [[ ! -f ${dat[i]} ]];then
        echo ${dat[i]} not found
        continue
    fi

    if [[ $paradigm_hp_sec ]];then
        #if [[ ${TR[i]} ]];then
        #    TR0=${TR[i]}
        #else
        #    json=${dat[i]//nii.gz/json}
        #    if [[ ! -f $json ]];then
        #        echo " $json not found"
        #        continue
        #    fi
        #    IFS=$' ,' read -ra line0 < <( grep RepetitionTime $json )
        #    TR0=${line0[1]}
        #    echo "Found TR=${TR0}"
        #fi
        if [[ ! ${TR[i]} ]];then
            json=${dat[i]//nii.gz/json}
            if [[ ! -f $json ]];then
                echo " $json not found"
                continue
            fi
            IFS=$' ,' read -ra line0 < <( grep RepetitionTime $json )
            TR[i]=${line0[1]}
            echo "Found TR[$i]=${TR[i]}"
        fi
    fi


    #prefiltered_func_data_unwarp=${fMRITimeSeriesResults[i]}
    prefiltered_func_data_unwarp=${dat[i]}
    #sd0=${fMRITimeSeriesResults[i]%/*}/SCRATCH$(date +%y%m%d%H%M%S)
    sd0=${dat[i]%/*}/SCRATCH$(date +%y%m%d%H%M%S)
    echo "sd0=${sd0}"
    #root0=${fMRITimeSeriesResults[i]%_bold.nii*}
    root0=${dat[i]%_bold.nii*}
    echo "root0=${root0}"

    mkdir -p ${sd0}

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_unwarp -Tmean mean_func
    ${FSLDIR}/bin/fslmaths $prefiltered_func_data_unwarp -Tmean ${sd0}/mean_func

    ##/usr/local/fsl/bin/bet2 mean_func mask -f 0.3 -n -m; /usr/local/fsl/bin/immv mask_mask mask
    ${FSLDIR}/bin/bet2 ${sd0}/mean_func ${sd0}/mask -f 0.3 -n -m; ${FSLDIR}/bin/immv ${sd0}/mask_mask ${sd0}/mask

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_unwarp -mas mask prefiltered_func_data_bet
    ${FSLDIR}/bin/fslmaths $prefiltered_func_data_unwarp -mas ${sd0}/mask ${sd0}/prefiltered_func_data_bet

    #/usr/local/fsl/bin/fslstats prefiltered_func_data_bet -p 2 -p 98
    p98=($(${FSLDIR}/bin/fslstats ${sd0}/prefiltered_func_data_bet -p 2 -p 98))
    #declare -p p98 
    echo "p98 = ${p98}"

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_bet -thr [97333.005859 / 10] -Tmin -bin mask -odt char
    thr=($(echo "scale=6; ${p98[1]} / 10" | bc))
    #declare -p thr
    echo "thr = $thr"
    ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_bet -thr $thr -Tmin -bin ${sd0}/mask -odt char

    ##/usr/local/fsl/bin/fslstats prefiltered_func_data_unwarp -k mask -p 50
    p50=($(${FSLDIR}/bin/fslstats $prefiltered_func_data_unwarp -k ${sd0}/mask -p 50))
    #declare -p p50 
    echo "p50 = $p50"

    ##/usr/local/fsl/bin/fslmaths mask -dilF mask
    ${FSLDIR}/bin/fslmaths ${sd0}/mask -dilF ${sd0}/mask

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_unwarp -mas mask prefiltered_func_data_thresh
    ${FSLDIR}/bin/fslmaths $prefiltered_func_data_unwarp -mas ${sd0}/mask ${sd0}/prefiltered_func_data_thresh

    ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_thresh -Tmean mean_func
    ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_thresh -Tmean ${sd0}/mean_func

    #for((j=0;j<${#FWHM[@]};++j));do
    for((j=0;j<${#fwhm[@]};++j));do

        ##/usr/local/fsl/bin/susan prefiltered_func_data_thresh [8218.408203 * 0.75] [filter FWHM converted to sigma] 3 1 1 mean_func [8218.408203 * 0.75] prefiltered_func_data_smooth
        bt=($(echo "scale=6; ${p50} * 0.75" | bc))
        #declare -p bt 
        #sigma=($(echo "scale=6; ${FWHM[j]} / 2.354820" | bc)) #https://brainder.org/2011/08/20/gaussian-kernels-convert-fwhm-to-sigma/ sigma=FWHM/sqrt(8ln2) for gaussian kernels
        sigma=($(echo "scale=6; ${fwhm[j]} / 2.354820" | bc)) #https://brainder.org/2011/08/20/gaussian-kernels-convert-fwhm-to-sigma/ sigma=FWHM/sqrt(8ln2) for gaussian kernels
        #declare -p sigma 
        #${FSLDIR}/bin/susan prefiltered_func_data_thresh $bt $sigma 3 1 1 mean_func $bt prefiltered_func_data_smooth
        echo "bt = $bt sigma = $sigma"
        ${FSLDIR}/bin/susan ${sd0}/prefiltered_func_data_thresh $bt $sigma 3 1 1 ${sd0}/mean_func $bt ${sd0}/prefiltered_func_data_smooth

        ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_smooth -mas ${sd0}/mask ${sd0}/prefiltered_func_data_smooth

        ##global intensity normalize to a value of 10000
        ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_smooth -mul {10000/8218.408203=1.21678064085} prefiltered_func_data_intnorm
        mul=($(echo "scale=6; 10000 / ${p50} " | bc))
        #declare -p mul 
        echo "mul = $mul"
        ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_smooth -mul $mul ${sd0}/prefiltered_func_data_intnorm

        echo "here0"

        ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_intnorm -Tmean tempMean
        ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_intnorm -Tmean ${sd0}/tempMean

        echo "here1 paradigm_hp_sec=$paradigm_hp_sec"

        #if [ -n "${command_line_specified_paradigm_hp_sec}" ];then
        if [[ $paradigm_hp_sec ]];then

            ##/usr/local/fsl/bin/fslmaths prefiltered_func_data_intnorm -bptf 45.4545454545 -1 -add tempMean prefiltered_func_data_tempfilt

            #bptf=($(echo "scale=6; ${PARADIGM_HP_SEC} / (2*${TR0})" | bc))
            bptf=($(echo "scale=6; ${paradigm_hp_sec} / (2*${TR[i]})" | bc))

            #declare -p bptf 
            echo "bptf = $bptf"

            #out0=${root0}_susan-${FWHM[j]}mm_hptf-${PARADIGM_HP_SEC}s_bold
            out0=${root0}_susan-${fwhm[j]}mm_hptf-${paradigm_hp_sec}s_bold

            ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_intnorm -bptf ${bptf} -1 -add ${sd0}/tempMean ${out0}

            jq -n --arg fwhm $fwhm '$ARGS.named' \
                  --arg paradigm_hp_sec $paradigm_hp_sec '$ARGS.named' > ${sd0}/tmp.json 

        else
            #out0=${root0}_susan-${FWHM[j]}mm_bold
            out0=${root0}_susan-${fwhm[j]}mm_bold
            ${FSLDIR}/bin/fslmaths ${sd0}/prefiltered_func_data_intnorm -add ${sd0}/tempMean ${out0}

            jq -n --arg fwhm $fwhm '$ARGS.named' > ${sd0}/tmp.json 
        fi

        echo "Output written to ${out0}"

        #OGREjson.py -f "${out0}.nii.gz" -j "${fMRITimeSeriesResults[i]//nii.gz/json}"
        echo "OGREjson2.py ${out0}.nii.gz -j ${dat[i]//nii.gz/json} ${sd0}/tmp.json"
        OGREjson2.py ${out0}.nii.gz -j ${dat[i]//nii.gz/json} ${sd0}/tmp.json

    done

#    rm -r ${sd0}
done
echo "**** Finished $0 ****"
