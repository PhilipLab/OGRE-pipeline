#!/usr/bin/env bash

shebang="#!/usr/bin/env bash"

##Hard coded location of dcm2niix
#[ -z ${DCM2NIIXDIR+x} ] && DCM2NIIXDIR=/Users/Shared/pipeline
#P0="${DCM2NIIXDIR}/dcm2niix -w 0 -z i -ba n" #-w 0 skip duplicates
#START240107 User should just set their PATH environment variable.
P0="dcm2niix -w 0 -z i -ba n" #-w 0 skip duplicates

root0=${0##*/}
helpmsg(){
    echo "Required: ${root0} <scanslist.csv file(s)>"
    echo "    -s --scanlist -scanlist"
    echo "        scanlist.csv file(s). Arguments without options are assumed to be scanlist.csv files."
    echo "        Two columns. First column identifies the dicom directory. Second column is the output name of the nifti."
    echo "        Columns may be separated by commas, spaces and/or tabs."
    echo "        Ex. 7,/Users/Shared/10_Connectivity/raw_data/sub-2035/anat/sub-2035_t1_mpr_1mm_p2_pos50"
    echo "            8,/Users/Shared/10_Connectivity/raw_data/sub-2035/fmap/sub-2035_SpinEchoFieldMap2_AP-1"
    echo "            9,/Users/Shared/10_Connectivity/raw_data/sub-2035/fmap/sub-2035_SpinEchoFieldMap2_PA-1"
    echo "            10,/Users/Shared/10_Connectivity/raw_data/sub-2035/func/sub-2035_task-drawRH_run-1_SBRef"
    echo "            11,/Users/Shared/10_Connectivity/raw_data/sub-2035/func/sub-2035_task-drawRH_run-1"
    echo "    -i --indir -indir"
    echo "        Input directory. Default is /<scans.csv path>/dicom."
    echo "    -b --batchscript -batchscript"
    echo "        Name of output script. Default is /<scans.csv path>/<subject directory>_dcm2niix.sh."
    echo "    -w --w"
    echo "        Flag. Puts output script in working directory; overrides -b"
    echo "    --Aoff -Aoff --autorunoff -autorunoff --AUTORUNOFF -AUTORUNOFF"
    echo "        Flag. Do not automatically execute script. Default is to execute. When not executed, *_fileout.sh is created with output redirect."

    #START240107
    echo "    --voff -voff --verboseoff -verboseoff"
    echo "        Flag. Don't echo messages to command line."

    echo "    -h --help -help"
    echo "        Echo this help message."
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi

#START240107
#echo $0 $@

#do not set dat;unexpected
lcautorun=1;lcverbose=1;wkdir=0

arg=("$@")
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -s | -scanlist | --scanlist)
            dat+=(${arg[((++i))]})
            for((j=i;j<${#@};++i));do #i is incremented only if dat is appended
                dat0=(${arg[((++j))]})
                [ "${dat0::1}" = "-" ] && break
                dat+=(${dat0[@]})
            done
            ;;
        -i | --indir | -indir)
            id=${arg[((++i))]}
            id0=$id
            ;;
        -b | --batchscript | -batchscript)
            bs=${arg[((++i))]}
            bs0=$bs
            ;;
        -w | --w )
            wkdir=1
            ;;
        --Aoff | -Aoff | --autorunoff | -autorunoff | --AUTORUNOFF | -AUTORUNOFF)
            lcautorun=0
            #echo "lcautorun=$lcautorun"
            ;;

        #START240107
        --voff | -voff | --verboseoff | -verboseoff)
            lcverbose=0
            #echo "lcverbose=$lcverbose"
            ;;

        -h | --help | -help)
            helpmsg
            exit
            ;;
        *) unexpected+=(${arg[i]})
            ;;
    esac
done

#START240107
((lcverbose==1)) && echo $0 $@ 

[ -n "${unexpected}" ] && dat+=(${unexpected[@]})
if [ -z "${dat}" ];then
    echo "Need to provide dat file"
    exit
fi
#echo "dat[@]=${dat[@]}"
#echo "#dat[@]=${#dat[@]}"

for((i=0;i<${#dat[@]};++i));do

    #https://stackoverflow.com/questions/17577093/how-do-i-get-the-absolute-directory-of-a-file-in-bash
    #https://stackoverflow.com/questions/284662/how-do-you-normalize-a-file-path-in-bash
    datf=$(realpath ${dat[i]})
    dir0=${datf%/*}
    IFS='/' read -ra subj <<< "${dir0}"
    subj=${subj[${#subj[@]}-1]}

    [ -z "${id0}" ] && id=${dir0}/dicom 
    if [ ! -d "$id" ];then
        echo "**** ERROR: $id does not exist. ****"
        exit
    fi


    if [ "${wkdir}" -eq 1 ];then # added 240325 by BP
        bs=$(pwd)/${subj}_dcm2niix.sh
        F1=$(pwd)/${subj}_dcm2niix_fileout.sh
    elif [ -z "${bs0}" ];then

        #START240325
        bs=${dir0}/${subj}_dcm2niix.sh
        F1=${dir0}/${subj}_dcm2niix_fileout.sh
        #START240123
        #bs=$(pwd)/${subj}_dcm2niix.sh
        #F1=$(pwd)/${subj}_dcm2niix_fileout.sh
    fi

    if [[ "${bs}" == *"/"* ]];then
        dirbs=${bs%/*}
        mkdir -p $dirbs
        if [ ! -d "$dirbs" ];then
            echo "**** ERROR: Unable to create $dirbs. Please check your permissions. ****"
            exit
        fi
    else
        bs=$(pwd)/${bs}   
    fi

    if [ -z "${F1}" ];then
        F1=${bs%%.*}_fileout.sh
        #echo "F1=${F1}"
    fi

    if [ -z "${bs0}" ] || ((i==0));then 
        echo -e "$shebang\n\n#$0 $@\n" > $bs
        ((lcautorun==0)) && echo -e "$shebang\n\n#$0 $@\n" > ${F1}
    fi

    if [ ! -f "$bs" ];then
        echo "**** ERROR: Unable to create $bs. Please check your permissions. ****"
        exit
    fi

    #echo "dat=${dat[i]}"

    #https://stackoverflow.com/questions/24537483/bash-loop-to-get-lines-in-a-file-skipping-comments-and-blank-lines
    #https://mywiki.wooledge.org/BashFAQ/024
    while IFS=$'\t, ' read -ra line; do
        dir1=$id/${line[0]}/DICOM
        od=${line[1]%/*}
        #echo "od=$od"
        if [ ! -d "$od" ];then
            mkdir -p ${od}
            if [ ! -d "${od}" ];then
                echo "**** ERROR: Unable to create ${od}. Please check your permissions. ****"
                exit
            fi
        fi
        echo -e "${P0} -o ${od} -f ${line[1]##*/} ${dir1}\n" >> $bs
    done < <(grep -vE '^(\s*$|#)' ${dat[i]})

    tr -d '\r' <${bs} >${bs}.new && mv ${bs}.new ${bs} 
    chmod +x $bs

    #echo "Output written to $bs"
    #START240107
    ((lcverbose==1)) && echo "Output written to $bs"

    if((lcautorun==1)) && [ -z "${bs0}" ];then
        [[ "${dir0}" != ".." ]] && cd ${dir0} || cd $(pwd)
        $bs > $bs.txt 2>&1 & 
        cd ${wd0} #"cd -" echoes the path

        #echo "$bs has been executed"
        #START240107
        ((lcverbose==1)) && echo "$bs has been executed"

    fi

    if((lcautorun==0));then
        [[ "${dir0}" != ".." ]] && echo "cd ${dir0}" >> ${F1} || echo "cd $(pwd)" >> ${F1}
        echo -e "${bs} > ${bs}.txt 2>&1 &\n" >> ${F1}
    fi

done
if((lcautorun==1)) && [ -n "${bs0}" ];then
    cd ${dir0}
    $bs > $bs.txt 2>&1 & 
    cd ${wd0} #"cd -" echoes the path

    #echo "$bs has been executed"
    #START240107
    ((lcverbose==1)) && echo "$bs has been executed"

fi
if((lcautorun==0));then 
    chmod +x ${F1}

    #echo "Output written to ${F1}"
    #START240107
    ((lcverbose==1)) && echo "Output written to ${F1}"

fi
