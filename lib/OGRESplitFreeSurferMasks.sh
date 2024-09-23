#!/usr/bin/env bash

root0=${0##*/}
helpmsg(){
    echo "Identifies GM/WM/CSF from FreeSurfer results within OGRE."
    echo "Based on wmparc and the values in Freesurfer7.4.1/FreeSurferColorLUT.txt."
    echo " This table doesn't locate CSF within sulci, so an additional approach is used to find sulcal CSF:"
    echo "  1) Calculate a conservative upper bounds of CSF magnitude in T1w image (lower of: CSF mean + 0.5SD, or GM mean - 3SD)"
    echo "  2) Erode your T1w_brain aggressiveley (erosion *6) to avoid dura"
    echo "  3) Mask your eroded-T1 with unlabeled voxels from wmparc"
    echo "  4) All (eroded unlabeled voxels) in T1 with magnitude < (CSF conservative bounds) defined as Sulcal CSF and included"
    echo " "
    #echo "Usage: OGRESplitFreeSurferMasks.sh -p PIPEDIR [-s SUBJECT]"
    echo "Usage: OGRESplitFreeSurferMasks.sh [-p] PIPEDIR [-s SUBJECT]"

    echo "      -p PIPEDIR: pipeline directory of OGRE working outputs. "
    echo "                  An optionless argument is assumed to be the pipeline directory."
    echo "          e.g. /Users/Shared/10_Connectivity/derivatives/sub-1001/pipeline7.4.1"
    echo "      -s Subject (optional)"
    echo "          e.g. sub-1001. If not set, will extract from PIPEDIR path '/sub-X/'"
    echo "      -f Firm (optional)"
    echo "          Flag. If you set it, will OMIT the extra CSF detection described above."  
    exit   
    }
if((${#@}<1));then
    helpmsg
    exit
fi

# defaults
parcelFile=wmparc; EXTRA=1; DEBUG=0
#grayFile=aparc+aseg

arg=("$@")
for((i=0;i<${#@};++i));do
    case "${arg[i]}" in
        -p | --p)
            PIPEDIR=${arg[((++i))]}
            ;;
        -s | --s)
            SUBJECT=${arg[((++i))]}
            ;;
        -f | --f)
            EXTRA=0
            ;;
        -d | --d)
            DEBUG=1
            ;;
        *) unexpected+=(${arg[i]})
            ;;

    esac
done

[ -n "${unexpected}" ] && PIPEDIR+=(${unexpected[@]})
if [ -z "${PIPEDIR}" ];then
    echo "Error in ${root0}: must provide PIPEDIR"
    exit
fi

#temp1=${PIPEDIR##*/pipeline} #everything after the last /pipeline
if [ -z "${SUBJECT}" ];then
    regcheck='/sub-[0-9]+/' # regular expression for /sub-[numbers]/
    if [[ $PIPEDIR =~ $regcheck ]];then
        subjSlashes="${BASH_REMATCH[0]}"
        subLastSlash="${subjSlashes:1}" # drop 1st char
        SUBJECT="${subLastSlash%/*}" # drop trailing /
        echo "${root0} determined subject to be ${SUBJECT}"
    else
        echo "Error in ${root0}: PIPEDIR contains no /sub-X/, and subject not set externally"
        exit
    fi
fi

inputDir=${PIPEDIR}/MNINonLinear
outDir=${PIPEDIR}/MNINonLinear/gm_wm_csf
partialDir=${outDir}/partials
mkdir -p ${partialDir}

gmLong=graymatter
wmLong=whitematter
csfLong=cerebrospinalfluid

originalFile=${inputDir}/${parcelFile}.nii.gz


if [ $DEBUG == 0 ];then
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
outWM=${outDir}/${SUBJECT}_${wmLong}.nii.gz
c0="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${wmLong}_combinedValues.nii.gz -bin ${outWM}"
$c0
#echo "finished labeling WM"
echo -e "finished labeling WM\n    $outWM"


l0=(4 14 24 43 72 122 213 221 223 257 701 920)
u0=(5 15 24 44 72 122 213 221 223 257 701 920)
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
outCSF=${outDir}/${SUBJECT}_${csfLong}.nii.gz
binarize="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${csfLong}_combinedValues.nii.gz -bin ${outCSF}"
$binarize
#echo "finished labeling CSF"
echo -e "finished labeling CSF\n    $outCSF"

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
outGM=${outDir}/${SUBJECT}_${gmLong}.nii.gz
c0="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_${gmLong}_combinedValues.nii.gz -bin ${outGM}"
$c0
#echo "finished labeling GM"
echo -e "finished labeling GM\n    $outGM"
else # debug mode: calculate nothing, just set variable names
outWM=${outDir}/${SUBJECT}_${wmLong}.nii.gz
outGM=${outDir}/${SUBJECT}_${gmLong}.nii.gz
outCSF=${outDir}/${SUBJECT}_${csfLong}.nii.gz

fi

# find additional CSF
if [ $EXTRA == 1 ]; then
    gmMasked="${partialDir}/${SUBJECT}_T1w_onlyGM"
    g0="${FSLDIR}/bin/fslmaths $inputDir/T1w_restore_brain -mas ${outGM} ${gmMasked}" # brain (GM only)
    $g0
    csfMasked="${partialDir}/${SUBJECT}_T1w_onlyCSF_fromLUT"
    c0="${FSLDIR}/bin/fslmaths $inputDir/T1w_restore_brain -mas ${outCSF} ${csfMasked}" # brain (CSF only)
    $c0
    gmMean=$(${FSLDIR}/bin/fslstats ${gmMasked} -M)
    gmSD=$(${FSLDIR}/bin/fslstats ${gmMasked} -S)
    gmMeanRound=${gmMean%.*} # Round to integer. For some reason, math (parameter expansion) doesn't work without this
    gmSDRound=${gmSD%.*}
    gmThreeSD=$(( 3*gmSDRound ))
    gmFloor=$(( gmMeanRound-gmThreeSD )) # one barrier: mean-3sd of GM
    csfMean=$(${FSLDIR}/bin/fslstats ${csfMasked} -M)
    csfSD=$(${FSLDIR}/bin/fslstats ${csfMasked} -S)
    csfMeanRound=${csfMean%.*}
    csfSDRound=${csfSD%.*}
    csfHalfSD=$(( csfSDRound/2 ))
    csfCeil=$(( csfMeanRound+csfHalfSD)) # another barrier: mean+0.5sd of CSF
    mostConservativeCSF=$( (( $csfCeil <= $gmFloor )) && echo "$csfCeil" || echo "$gmFloor" )
    # now make sure you're not getting any dura-etc by aggressively eroding
    erodedFile=${partialDir}/${SUBJECT}_erodedMask
    e0="${FSLDIR}/bin/fslmaths $inputDir/T1w_restore_brain -ero -ero -ero -ero -ero -ero -bin ${erodedFile}"
    $e0
    # identify unlabeled voxels
    unlabeledFile="${partialDir}/${SUBJECT}_unlabeled"
    u0="${FSLDIR}/bin/fslmaths ${originalFile} -add 1 ${parcelFile}_add_1"
    u1="${FSLDIR}/bin/fslmaths ${parcelFile}_add_1 -uthr 1 ${unlabeledFile}"
    $u0
    $u1
    # mask eroded-brain with unlabeled
    erodedUnlabeled="${partialDir}/${SUBJECT}_unlabeled_eroded"
    m0="${FSLDIR}/bin/fslmaths ${erodedFile} -mas ${unlabeledFile} ${erodedUnlabeled}"
    $m0
    # now do the thresholding: eroded-unlabeled < CSFthresh
    t0="${FSLDIR}/bin/fslmaths ${erodedUnlabeled} -uthr ${mostConservativeCSF} ${partialDir}/${SUBJECT}_cerebrospinalfluid_partialSulcal"
    $t0
    cp $outCSF ${partialDir}/${SUBJECT}_${wmLong}_LUTonly # backup
    a0="${FSLDIR}/bin/fslmaths ${outCSF} -add ${partialDir}/${SUBJECT}_cerebrospinalfluid_partialSulcal ${partialDir}/${SUBJECT}_combinedValuesAndSulcal"
    a1="${FSLDIR}/bin/fslmaths ${partialDir}/${SUBJECT}_combinedValuesAndSulcal -bin ${outCSF}"
    $a0
    $a1
    echo "OGRESplitFreeSurderMasks finished adding sulcal CSF"
fi
