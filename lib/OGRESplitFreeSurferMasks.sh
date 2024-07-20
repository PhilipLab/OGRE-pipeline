#!/bin/bash

helpmsg(){
    echo "Identifies GM/WM/CSF from FreeSurfer results within OGRE."
    echo "Based on the values in Freesurfer7.4.1/FreeSurferColorLUT.txt."
    echo " "

    #echo "Usage: OGRESplitFreeSurferMashks.sh -p PIPEDIR [-s SUBJECT]"
    echo "Usage: OGRESplitFreeSurferMashks.sh [-p] PIPEDIR [-s SUBJECT]"

    echo "      -p PIPEDIR: pipeline directory of OGRE working outputs. "
    echo "                  An optionless argument is assumed to be the pipeline directory."
    echo "          e.g. /Users/Shared/10_Connectivity/derivatives/sub-1001/pipeline7.4.1"


    echo "      -s Subject (optional)"
    echo "          e.g. sub-1001. If not set, will extract from PIPEDIR path '/sub-X/'"
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi

parcelFile=wmparc; grayFile=aparc+aseg

arg=("$@")
for((i=0;i<${#@};++i));do
    case "${arg[i]}" in
        -p | --p)
            PIPEDIR=${arg[((++i))]}
            ;;
        -s | --s)
            SUBJECT=${arg[((++i))]}
            ;;
        *) unexpected+=(${arg[i]})
            ;;

    esac
done

[ -n "${unexpected}" ] && PIPEDIR+=(${unexpected[@]})
if [ -z "${PIPEDIR}" ];then
    echo "Error in OGRESplitFreeSurferMasks.sh: must provide PIPEDIR"
    exit
fi


#temp1=${PIPEDIR##*/pipeline} #everything after the last /pipeline
if [ -z "${SUBJECT}" ];then
    regcheck='/sub-[0-9]+/' # regular expression for /sub-[numbers]/
    if [[ $PIPEDIR =~ $regcheck ]];then
        subjSlashes="${BASH_REMATCH[0]}"
        subLastSlash="${subjSlashes:1}" # drop 1st char
        SUBJECT="${subLastSlash%/*}" # drop trailing /
        echo "OGRESplitFreeSurferMasks.sh determined subject to be ${SUBJECT}"
    else
        echo "Error in OGRESplitFreeSurferMasks.sh: PIPEDIR contains no /sub-X/, and subject not set externally"
    fi
fi

inputDir=${PIPEDIR}/MNINonLinear
outDir=${PIPEDIR}/MNINonLinear/gm_wm_csf
partialDir=${outDir}/partials
mkdir -p ${partialDir}
    
originalFile=${inputDir}/${parcelFile}.nii.gz

wmLong=whitematter
l0=(2 7 28 41 46 60 77 155 192 219 3000 4000 5001 250 703 3000 4100 5100)
u0=(2 7 28 41 46 60 82 158 192 219 3035 4035 5002 255 703 3210 4210 6080)
for k in ${!l0[@]};do
    c0="${FSLDIR}/bin/fslmaths ${originalFile} -thr ${l0[k]} -uthr ${u0[k]} ${partialDir}/${SUBJECT}_${wmLong}_partial${l0[k]}-${u0[k]}.nii.gz";#echo $c0
    $c0   
done
c0="cp ${partialDir}/${SUBJECT}_${wmLong}_partial${l0[0]}-${u0[0]}.nii.gz ${partialDir}/${SUBJECT}_${wmLong}_combinedValues.nii.gz";#echo $c0
$c0
for((k=1;k<${#l0[@]};k++));do
    c0="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${wmLong}_combinedValues.nii.gz -add ${partialDir}/${SUBJECT}_${wmLong}_partial${l0[k]}-${u0[k]}.nii.gz ${partialDir}/${SUBJECT}_${wmLong}_combinedValues.nii.gz";#echo $c0
    $c0
done
#c0="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${wmLong}_combinedValues.nii.gz -bin ${outDir}/${SUBJECT}_${wmLong}.nii.gz";#echo $c0
out=${outDir}/${SUBJECT}_${wmLong}.nii.gz
c0="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${wmLong}_combinedValues.nii.gz -bin ${out}"
$c0
#echo "finished labeling WM"
echo -e "finished labeling WM\n    $out"


csfLong=cerebrospinalfluid
l0=(4 14 24 43 72 122 213 221 223 701)
u0=(5 15 24 44 72 122 213 221 223 701)
for k in ${!l0[@]};do
    c0="${FSLDIR}/bin/fslmaths ${originalFile} -thr ${l0[k]} -uthr ${u0[k]} ${partialDir}/${SUBJECT}_${csfLong}_partial${l0[k]}-${u0[k]}.nii.gz";#echo $c0
    $c0
done
c0="cp ${partialDir}/${SUBJECT}_${csfLong}_partial${l0[0]}-${u0[0]}.nii.gz ${partialDir}/${SUBJECT}_${csfLong}_combinedValues.nii.gz";#echo $c0
$c0
for((k=1;k<${#l0[@]};k++));do
    c0="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${csfLong}_combinedValues.nii.gz -add ${partialDir}/${SUBJECT}_${csfLong}_partial${l0[k]}-${u0[k]}.nii.gz ${partialDir}/${SUBJECT}_${csfLong}_combinedValues.nii.gz";#echo $c0
    $c0
done
#binarize="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${csfLong}_combinedValues.nii.gz -bin ${outDir}/${SUBJECT}_${csfLong}.nii.gz"
out=${outDir}/${SUBJECT}_${csfLong}.nii.gz
binarize="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${csfLong}_combinedValues.nii.gz -bin ${out}"
$binarize
#echo "finished labeling CSF"
echo -e "finished labeling CSF\n    $out"

gmLong=graymatter
l0=(3 8 16 26 42 47 96 135 193 214 220 222 225 270 370 500 702 1000)
u0=(3 13 20 27 42 59 97 139 212 218 220 222 246 277 439 691 702 2035)
for k in ${!l0[@]};do
    c0="${FSLDIR}/bin/fslmaths ${originalFile} -thr ${l0[k]} -uthr ${u0[k]} ${partialDir}/${SUBJECT}_${gmLong}_partial${l0[k]}-${u0[k]}.nii.gz";#echo $c0
    $c0   
done
c0="cp ${partialDir}/${SUBJECT}_${gmLong}_partial${l0[0]}-${u0[0]}.nii.gz ${partialDir}/${SUBJECT}_${gmLong}_combinedValues.nii.gz";#echo $c0
$c0
for((k=1;k<${#l0[@]};k++));do
    c0="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${gmLong}_combinedValues.nii.gz -add ${partialDir}/${SUBJECT}_${gmLong}_partial${l0[k]}-${u0[k]}.nii.gz ${partialDir}/${SUBJECT}_${gmLong}_combinedValues.nii.gz";#echo $c0
    $c0
done
#c0="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${gmLong}_combinedValues.nii.gz -bin ${outDir}/${SUBJECT}_${gmLong}.nii.gz";#echo $c0
out=${outDir}/${SUBJECT}_${gmLong}.nii.gz
c0="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${gmLong}_combinedValues.nii.gz -bin ${out}"
$c0
#echo "finished labeling GM"
echo -e "finished labeling GM\n    $out"
