#!/usr/bin/env bash

shebang="#!/usr/bin/env bash"

root0=${0##*/}
helpmsg(){
    echo "Required: ${root0} PIPEDIR"
    echo "    -p PIPEDIR: pipeline directory of OGRE working outputs. "
    echo "                An optionless argument is assumed to be the pipeline directory."
    echo "        e.g. /Users/Shared/10_Connectivity/derivatives/sub-1001/pipeline7.4.1"
    echo "    -s Subject (optional)"
    echo "        e.g. sub-1001. If not set, will extract from PIPEDIR path '/sub-X/'"
    echo "    -T1wTemplateLow <my reference image> (optional)"
    echo "        Default is to export T1wTemplateLow from  PIPEDIR/templates/export_templates.sh"
    echo "        As the reference image, this can be a blank image with just the proper dimensions and voxel size."
    echo "    -O --OGREDIR -OGREDIR --ogredir -ogredir"
    echo "        OGRE directory. Location of OGRE software package (e.g. ~/GitHub/OGRE-pipeline)."
    echo "        Defaults to variable OGREDIR if set elsewhere. If set in both places, this one overrides."
    echo "        NOTE: you must either set -O or the variable OGREDIR."
    echo "    -H --HCPDIR -HCPDIR --hcpdir -hcpdir"
    echo "        HCP directory. Optional; default location is OGREDIR/lib/HCP"
    echo "    -h --help -help"
    echo "        Echo this help message."
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi

unset T1wTemplateLow help #do not set unexpected

arg=("$@")
for((i=0;i<${#@};++i));do
    case "${arg[i]}" in
        -p | --p)
            PIPEDIR=${arg[((++i))]}
            ;;
        -s | --s)
            SUBJECT=${arg[((++i))]}
            ;;
        -T1wTemplateLow | --T1wTemplateLow)
            T1wTemplateLow=${arg[((++i))]}
            ;;
        -O | --OGREDIR | -OGREDIR | --ogredir | -ogredir)
            OGREDIR=${arg[((++i))]}
            ;;
        -H | --HCPDIR | -HCPDIR | --hcpdir | -hcpdir)
            HCPDIR=${arg[((++i))]}
            ;;
        -h | --help | -help)
            help=True
            ;;
        *) unexpected+=(${arg[i]})
            ;;
    esac
done
if [[ -n "$help" ]];then
    helpmsg
    exit
fi
echo $0 $@

if [ -z "${OGREDIR}" ];then
    echo "OGREDIR not set. Abort!"
    echo "Before calling this script: export OGREDIR=<OGRE directory>"
    echo "or via an option to this script: -OGREDIR <OGRE directory>"
    exit
fi
#if HCPDIR unset, use default location (this is down here b/c needs $OGREDIR)
[ -z ${HCPDIR+x} ] && HCPDIR=$OGREDIR/lib/HCP


[ -n "${unexpected}" ] && PIPEDIR+=(${unexpected[@]})
if [ -z "${PIPEDIR}" ];then
    echo "Error in ${root0} must provide PIPEDIR"
    exit
fi

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

#START241008
if [ -z "${T1wTemplateLow}" ];then
    if [ ! -f "$PIPEDIR/templates/export_templates.sh" ];then
        echo "Please run OGREstructpipeSETUP.sh to set up the templates. Abort!"
        exit
    fi
    echo "Running $PIPEDIR/templates/export_templates.sh"
    source $PIPEDIR/templates/export_templates.sh
    #echo "T1wTemplate = $T1wTemplate"
    #echo "T1wTemplateBrain = $T1wTemplateBrain"
    echo "T1wTemplateLow = $T1wTemplateLow"
    #echo "T2wTemplate = $T2wTemplate"
    #echo "T2wTemplateBrain = $T2wTemplateBrain"
    #echo "T2wTemplateLow = $T2wTemplateLow"
    #echo "TemplateMask = $TemplateMask"
    #echo "TemplateMaskLow = $TemplateMaskLow"
    echo "FinalfMRIResolution = $FinalfMRIResolution"
fi


masks=(graymatter whitematter cerebrospinalfluid)
for i in ${masks[@]};do 
    in=$PIPEDIR/MNINonLinear/gm_wm_csf/${SUBJECT}_$i.nii.gz
    out=$PIPEDIR/MNINonLinear/gm_wm_csf/${SUBJECT}_$i.${FinalfMRIResolution}.nii.gz
    if [ ! -f "$in" ];then
        echo $in does not exist. Skipping ...
        continue
    fi
    ${FSLDIR}/bin/applywarp --rel --interp=nn -i $in -r ${T1wTemplateLow} --premat=$FSLDIR/etc/flirtsch/ident.mat -o $out 
    echo Output written to $out
done
