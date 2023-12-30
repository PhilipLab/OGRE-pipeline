#!/usr/bin/env bash

shebang="#!/usr/bin/env bash"

#Hard coded location of dcm2niix
[ -z ${DCM2NIIXDIR+x} ] && DCM2NIIXDIR=/Users/Shared/pipeline

#P0="${DCM2NIIXDIR}/dcm2niix -w 0 -z i" #-w 0 skip duplicates
#START231229
P0="${DCM2NIIXDIR}/dcm2niix -w 0 -z i -ba n" #-w 0 skip duplicates

root0=${0##*/}
helpmsg(){
    echo "Required: ${root0} </STUDYPATH/SUBJDIR/scanlist.csv>"
    echo "              Dicoms read from /STUDYPATH/SUBJDIR/dicom"
    echo "              Niftis written to /STUDYPATH/SUBJDIR/nifti"
    echo "              A script is created and executed: /STUDYPATH/SUBJDIR/SUBJDIR_dcm2niix.sh"
    echo "          ${root0} scanlist.csv"
    echo "              Current working directory is assumed to be of the form /STUDYPATH/SUBJDIR"
    echo ""
    echo "Ex. ${root0} /Users/Shared/10_Connectivity/10_2000/10_2000_scanlist.csv"
    echo "    ${root0} 10_2000_scanlist.csv from within /Users/Shared/10_Connectivity/10_2000"
    echo "        STUDYPATH is /Users/Shared/10_Connectivity"
    echo "        SUBJDIR is 10_2000"
    echo ""
    echo "    -s --sub -sub"
    #echo "        scanlist.csv file(s). Arguments without options are assumed to be scanlist.csv files."
    echo "        scans.csv file(s). Arguments without options are assumed to be scans.csv files."
    #echo "        First row is labels which is currently not used."
    #echo "        Two or more columns. First column identifies the dicom directory. Last column is the output name of the nifti."
    echo "         Two columns. First column identifies the dicom directory. Second column is the output name of the nifti."
    #echo "        Fields may be separated by commas, spaces /or tabs."
    echo "        Fields may be separated by commas, spaces and/or tabs."
    echo "            Ex. Scan,nii"
    echo "                16,run1_RH_SBRef"
    echo "                17 run1_RH"
    echo "            This would produce two niftis: 1) <outdir>/run1_RH_SBRef.nii.gz from dicoms <indir>/16/DICOM"
    echo "                                           2) <outdir>/run1_RH.nii.gz from dicoms <indir>/17/DICOM"

    echo "         Ex. 7,/Users/Shared/10_Connectivity/raw_data/sub-2035/anat/sub-2035_t1_mpr_1mm_p2_pos50"
    echo "             8,/Users/Shared/10_Connectivity/raw_data/sub-2035/fmap/sub-2035_SpinEchoFieldMap2_AP-1"
    echo "             9,/Users/Shared/10_Connectivity/raw_data/sub-2035/fmap/sub-2035_SpinEchoFieldMap2_PA-1"
    echo "             10,/Users/Shared/10_Connectivity/raw_data/sub-2035/func/sub-2035_task-drawRH_run-1_SBRef"
    echo "             11,/Users/Shared/10_Connectivity/raw_data/sub-2035/func/sub-2035_task-drawRH_run-1"


    echo "    -i --indir -indir"
    #echo "        Input directory. Default is /STUDYPATH/SUBJDIR/dicom."
    echo "        Input directory. Default is /<scans.csv path>/dicom."
    #echo "    -o --outdir -outdir"
    #echo "        Output directory. Default is /STUDYPATH/SUBJDIR/nifti"
    #echo "        Output directory. Default is /STUDYPATH/SUBJDIR/nifti"
    echo "    -b --batchscript -batchscript"
    echo "        Name of output script. Default is /STUDYPATH/SUBJDIR/SUBJDIR_dcm2niix.sh."
    echo "    --Aoff -Aoff --autorunoff -autorunoff --AUTORUNOFF -AUTORUNOFF"
    echo "        Flag. Do not automatically execute script. Default is to execute. When not executed, *_fileout.sh is created with output redirect."
    echo "    -h --help -help"
    echo "        Echo this help message."
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi
echo $0 $@

#do not set dat;unexpected
lcautorun=1

arg=("$@")
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -s | --sub | -sub)
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

        #START231229
        #-o | --outdir | -outdir)
        #    od=${arg[((++i))]}
        #    od0=$od
        #    ;;

        -b | --batchscript | -batchscript)
            bs=${arg[((++i))]}
            bs0=$bs
            ;;
        --Aoff | -Aoff | --autorunoff | -autorunoff | --AUTORUNOFF | -AUTORUNOFF)
            lcautorun=0
            #echo "lcautorun=$lcautorun"
            ;;
        -h | --help | -help)
            helpmsg
            exit
            ;;
        *) unexpected+=(${arg[i]})
            ;;
    esac
done
[ -n "${unexpected}" ] && dat+=(${unexpected[@]})
if [ -z "${dat}" ];then
    echo "Need to provide dat file"
    exit
fi
#echo "dat[@]=${dat[@]}"
#echo "#dat[@]=${#dat[@]}"

for((i=0;i<${#dat[@]};++i));do

    [[ "${dat[i]}" == *"/"* ]] && dir0=${dat[i]%/*} || dir0=$(pwd)
    #echo "dir0=${dir0}"

    [ -z "${id0}" ] && id=${dir0}/dicom 
    if [ ! -d "$id" ];then
        echo "**** ERROR: $id does not exist. ****"
        exit
    fi

    #START231229
    #[ -z "${od0}" ] && od=${dir0}/nifti
    #mkdir -p $od
    #if [ ! -d "$od" ];then
    #    echo "**** ERROR: Unable to create $od. Please check your permissions. ****"
    #    exit
    #fi

    if [ -z "${bs0}" ];then
        IFS='/' read -ra subj <<< "${dir0}"
        subj=${subj[${#subj[@]}-1]}
        bs=${dir0}/${subj}_dcm2niix.sh
        F1=${dir0}/${subj}_dcm2niix_fileout.sh
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

    IFS=$'\r\n' read -d '' -ra csv < ${dat[i]}
    #printf '%s\n' "${csv[@]}"

    #for((j=1;j<${#csv[@]};++j));do
    #START231229
    for((j=0;j<${#csv[@]};++j));do

        IFS=$'\t, ' read -ra line <<< ${csv[j]}

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
   
        #echo -e "${P0} -o ${od} -f ${line[((${#line[@]}-1))]} ${dir1}\n" >> $bs
        #START231229
        echo -e "${P0} -o ${od} -f ${line[1]##*/} ${dir1}\n" >> $bs

    done
    tr -d '\r' <${bs} >${bs}.new && mv ${bs}.new ${bs} 
    chmod +x $bs
    echo "Output written to $bs"

    if((lcautorun==1)) && [ -z "${bs0}" ];then
        [[ "${dir0}" != ".." ]] && cd ${dir0} || cd $(pwd)
        $bs > $bs.txt 2>&1 & 
        cd ${wd0} #"cd -" echoes the path
        echo "$bs has been executed"
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
    echo "$bs has been executed"
fi
if((lcautorun==0));then 
    chmod +x ${F1}
    echo "Output written to ${F1}"
fi
