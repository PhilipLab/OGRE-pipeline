#!/usr/bin/env bash

shebang="#!/usr/bin/env bash"

#Hard coded location of HCP scripts
[ -z ${HCPDIR+x} ] && HCPDIR=/Users/Shared/pipeline/HCP

#Hard coded location of freesurfer installations
[ -z ${FREESURFDIR+x} ] && FREESURFDIR=/Applications/freesurfer

#Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2 7.4.0
[ -z ${FREESURFVER+x} ] && FREESURFVER=7.4.0

##Hard coded HCP batch scripts
#pre0=OGREPreFreeSurferPipelineBatch.sh
#free0=OGREFreeSurferPipelineBatch.sh
#post0=OGREPostFreeSurferPipelineBatch.sh
##Hard coded pipeline settings
#setup0=OGRESetUpHCPPipeline.sh
#START231230
PRE=OGREPreFreeSurferPipelineBatch.sh
FREE=OGREFreeSurferPipelineBatch.sh
POST=OGREPostFreeSurferPipelineBatch.sh
SETUP=OGRESetUpHCPPipeline.sh

#Resolution. options: 1, 0.7 or 0.8
Hires=1

#START231231
T1SEARCHSTR=t1
T2SEARCHSTR=t2

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

root0=${0##*/}
helpmsg(){
    echo "Required: ${root0} <OGRE directory> -v <version number>"
    echo "    -i --install -install"
    echo "        OGRE will be installed at this location as <install>/<version>."
    echo "        An argument without an option is assumed to be the OGRE directory."
    echo "    -v --version -version"
    echo "        Version number."
    echo "    -h --help -help"
    echo "        Echo this help message."
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi
echo $0 $@

#do not set install;unexpected
unset v 

arg=("$@")
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -i | --install | -install)
            install=${arg[((++i))]}
            echo "install=$install"
            ;;
        -v | --version | --version)
            version=${arg[((++i))]}
            echo "version=$version"
            ;;
        -h | --help | -help)
            helpmsg
            exit
            ;;
        *) unexpected+=(${arg[i]})
            ;;
    esac
done

[ -n "${unexpected}" ] && install=(${unexpected[@]})
if [ -z "${install}" ];then
    echo "install not set. Abort!"
    exit
fi
echo "install=$install"
echo "version=$version"
 
if [ -d "$install/$version"]
    #https://stackoverflow.com/questions/18544359/how-do-i-read-user-input-into-a-variable-in-bash
    #read -p "$install/$version exists. Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
    read -p "$install/$version exists. Continue? (Y/N): " confirm && [[ ${confirm^^} == 'YES' ]] || exit 1
fi

STARTHERE


if [ -z "${bs}" ];then
    num_sub=0
    for((i=0;i<${#csv[@]};++i));do
        IFS=$'\r\n\t, ' read -ra line <<< ${csv[i]}
        if [[ "${line[0]:0:1}" = "#" ]];then
            #echo "Skipping line $((i+1))"
            continue
        fi
        ((num_sub++))
    done
    num_cores=$(sysctl -n hw.ncpu)
    ((num_sub>num_cores)) && echo "${num_sub} will be run, however $(hostname) only has ${num_cores}. Please consider -b <batchscript>."
fi    

lcsinglereconall=0;lctworeconall=0
if [[ "${FREESURFVER}" != "5.3.0-HCP" && "${FREESURFVER}" != "7.2.0" && "${FREESURFVER}" != "7.3.2" && "${FREESURFVER}" != "7.4.0" ]];then
    echo "Unknown version of freesurfer. FREESURFVER=${FREESURFVER}"
    exit
fi
[[ "${FREESURFVER}" = "7.2.0" || "${FREESURFVER}" = "7.3.2" || "${FREESURFVER}" = "7.4.0" ]] && lctworeconall=1

if [ -n "${bs}" ];then
    [[ $bs == *"/"* ]] && mkdir -p ${bs%/*}
    echo -e "$shebang\n" > $bs
fi
wd0=$(pwd) 

#for((i=0;i<${#csv[@]};++i));do
#START231230
for((i=0;i<${#dat[@]};++i));do

    #START231231
    unset T1f T2f
    cnt=0

    #https://stackoverflow.com/questions/24537483/bash-loop-to-get-lines-in-a-file-skipping-comments-and-blank-lines
    #https://mywiki.wooledge.org/BashFAQ/024
    while IFS=$'\t, ' read -ra line; do
        if [[ "${line[1]}" == *"${T1SEARCHSTR}"* ]];then
            T1f=${line[1]}
            ((cnt++))
        elif [[ "${line[1]}" == *"${T2SEARCHSTR}"* ]];then
            T2f=${line[1]}
            ((cnt++))
        fi
        ((cnt==2)) && break
    done < <(grep -vE '^(\s*$|#)' ${dat[i]})


    #T1f=${line[2]}
    #if [[ "${T1f}" = "NONE" || "${T1f}" = "NOTUSEABLE" ]];then
    #    echo "    T1 ${T1f}"
    #    continue
    #fi
    #if [ ! -f "$T1f" ];then
    #    echo "    T1 ${T1f} not found"
    #    continue
    #fi
    #echo "    T1 ${T1f}"
    #T2f=;T20=${line[3]}
    #if [[ "${T20}" = "NONE" || "${T20}" = "NOTUSEABLE" ]];then
    #    echo "    T2 ${T20}"
    #elif [ ! -f "${T20}" ];then
    #    echo "    T2 ${T20} not found"
    #else
    #    T2f=${T20}
    #    echo "    T2 ${T2f}"
    #fi
    #START231231
    #if [ -z "${T1f}" ];then
    #    echo -e "T1 not found with searchstr = \"${T1SEARCHSTR}\" Abort!"
    #    continue 
    #fi
    #echo "T1f = ${T1f}"
    #[ -z "${T2f}" ] && echo "T2 not found with searchstr = ${T2SEARCHSTR} " || echo "T2f = ${T2f}"
    #START240107
    if [ -z "${T1f}" ];then
        echo -e "    T1 not found with searchstr = \"${T1SEARCHSTR}\" Abort!"
        continue 
    else
        T1f+=.nii.gz 
        if [ ! -f "$T1f" ];then
            echo "    ${T1f} not found. Abort!"
            continue
        fi
    fi
    echo "T1f = ${T1f}"
    if [ -z "${T2f}" ];then 
        echo -e "    WARNING: T2 not found with searchstr = \"${T2SEARCHSTR}\""
    else
        T2f+=.nii.gz 
        if [ ! -f "$T2f" ];then
            echo "    WARNING: ${T2f} not found."
            unset T2f
        fi
    fi


    #dir0=${line[1]}${FREESURFVER}
    #START231231
    [[ "${dat[i]}" == *"/"* ]] && dir0=${dat[i]%/*} || dir0=$(pwd)
    echo "initial dir0=${dir0}"

    IFS='/' read -ra subj <<< "${dir0}"
    s0=${subj[${#subj[@]}-1]}
    #echo "subj=${subj[@]}"

    #START240107
    T1f=${T1f//${s0}/'${s0}'}
    T2f=${T2f//${s0}/'${s0}'}
    

    #START240107
    #dir1=$(join_by / ${subj[@]::${#subj[@]}-1})
    dir1=/$(join_by / ${subj[@]::${#subj[@]}-1})/'${s0}'/pipeline'${FREESURFVER}'
    echo "dir1=${dir1}"


    dir0+=/pipeline${FREESURFVER}
    #START240107
    #dir0+=/pipeline'${FREESURFVER}'

    #if((lchostname==0));then
    #    IFS=$'/' read -ra line2 <<< ${line[1]}
    #    #echo "line2=${line2[@]}"
    #    sub0=${line2[-2]}
    #    #echo "sub0=${sub0}"
    #fi
    #START231231
    #((lchostname==1)) && dir0+=_$(hostname)
    #START240107
    if((lchostname==1));then
        dir0+=_$(hostname)
        dir1+=_'$(hostname)'
    fi

    #echo "dir0=${dir0}"
    #exit

    mkdir -p ${dir0}

    #START240101
    if((lcdate==1));then
        date0=$(date +%y%m%d)
    elif((lcdate==2));then
        date0=$(date +%y%m%d%H%M%S)
    fi

    #((lcdate==0)) && F0stem=${dir0}/${line[0]////_}_hcp3.27struct || F0stem=${dir0}/${line[0]////_}_hcp3.27struct_${date0} 
    #((lcdate==0)) && F0stem=${dir0}/${subj}_hcp3.27struct || F0stem=${dir0}/${subj}_hcp3.27struct_${date0} 
    #START240107
    ((lcdate==0)) && F0stem=${dir0}/${s0}_hcp3.27struct || F0stem=${dir0}/${s0}_hcp3.27struct_${date0} 

    F0=${F0stem}.sh
    F1=${F0stem}_fileout.sh
    echo  "F0=${F0}"
    echo  "F1=${F1}"

    if [ -n "${bs}" ];then
        echo "    ${F0}"

        #((lcdate==0)) && bs0stem=${dir0}/${line[0]////_}_hcp3.27batch || bs0stem=${dir0}/${line[0]////_}_hcp3.27batch_$(date +%y%m%d) 
        #START240101
        #((lcdate==0)) && bs0stem=${dir0}/${subj}_hcp3.27batch || bs0stem=${dir0}/${subj}_hcp3.27batch_${date0} 
        #START240107
        ((lcdate==0)) && bs0stem=${dir0}/${s0}_hcp3.27batch || bs0stem=${dir0}/${s0}_hcp3.27batch_${date0} 

        bs0=${bs0stem}.sh

        #echo -e "$shebang\nset -e\n" > ${bs0} 
        #START240110
        echo -e "$shebang\nset -e\nexport OGREDIR=$OGREDIR\n" > ${bs0} 

        bs1=${bs0stem}_fileout.sh
        echo -e "$shebang\nset -e\n" > ${bs1} 
    fi

    echo -e "$shebang\nset -e\n" > ${F0} 
    echo -e "$shebang\nset -e\n" > ${F1} 


    echo -e "#$0 $@\n" >> ${F0}

    echo "FREESURFVER=${FREESURFVER}" >> ${F0}
    echo -e export FREESURFER_HOME=${FREESURFDIR}/'${FREESURFVER}'"\n" >> ${F0}
    echo 'PRE='${PRE} >> ${F0}
    echo 'FREE='${FREE} >> ${F0}
    echo 'POST='${POST} >> ${F0}
    echo -e "SETUP=${SETUP}\n" >> ${F0}

    #echo "sf0=${line[1]}"'${FREESURFVER}' >> ${F0}
    #START240107
    echo "s0=${s0}" >> ${F0}
    echo "sf0=${dir1}" >> ${F0}

    #if((lchostname==1));then
    #    echo 's0=$(hostname)' >> ${F0}
    #else
    #    echo "s0=${sub0}" >> ${F0}
    #fi
    #START240107
    #echo "s0=${subj}" >> ${F0}
    #echo "s0=${s0}" >> ${F0}

    echo -e "Hires=${Hires}\n" >> ${F0}

    echo '${PRE} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    echo '    --Subject=${s0} \' >> ${F0}
    echo '    --runlocal \' >> ${F0}
    echo '    --T1='${T1f}' \' >> ${F0}
    echo '    --T2='${T2f}' \' >> ${F0}
    echo '    --GREfieldmapMag="NONE" \' >> ${F0}
    echo '    --GREfieldmapPhase="NONE" \' >> ${F0}
    echo '    --EnvironmentScript=${SETUP} \' >> ${F0}
    echo '    --Hires=${Hires} \' >> ${F0}
    echo -e '    --EnvironmentScript=${SETUP}\n' >> ${F0}

    echo '${FREE} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    echo '    --Subject=${s0} \' >> ${F0}
    echo '    --runlocal \' >> ${F0}
    echo '    --Hires=${Hires} \' >> ${F0}
    echo '    --freesurferVersion=${FREESURFVER} \' >> ${F0}
    ((lcsinglereconall)) && echo '    --singlereconall \' >> ${F0}
    ((lctworeconall)) && echo '    --tworeconall \' >> ${F0}
    echo -e '    --EnvironmentScript=${SETUP}\n' >> ${F0}

    echo '${POST} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    echo '    --Subject=${s0} \' >> ${F0}
    echo '    --runlocal \' >> ${F0}
    echo '    --EnvironmentScript=${SETUP}' >> ${F0}
    echo "out=${F0}.txt" >> ${F1}
    echo 'if [ -f "${out}" ];then' >> ${F1}
    echo '    echo -e "\n\n**********************************************************************" >> ${out}' >> ${F1}
    echo '    echo "    Reinstantiation $(date)" >> ${out}' >> ${F1}
    echo '    echo -e "**********************************************************************\n\n" >> ${out}' >> ${F1}
    echo "fi" >> ${F1}
    echo ${F0}' >> ${out} 2>&1 &' >> ${F1}

    chmod +x ${F0}
    chmod +x ${F1}
    echo "    Output written to ${F0}"
    echo "    Output written to ${F1}"
    if [ -n "${bs}" ];then
        echo "cd ${dir0}" >> $bs
        echo -e "${bs0} > ${bs0}.txt 2>&1\n" >> $bs
        echo -e "${F0} > ${F0}.txt 2>&1\n" >> $bs0
        echo "${bs0} > ${bs0}.txt 2>&1 &" >> ${bs1}
        chmod +x ${bs0}
        chmod +x ${bs1}
        echo "    Output written to ${bs0}"
        echo "    Output written to ${bs1}"
    fi
    if((lcautorun==1));then
        cd ${dir0}
        echo "    ${F1} has been executed"
        cd ${wd0} #"cd -" echoes the path
    fi
done

if [ -n "${bs}" ];then
    [[ $bs != *"/"* ]] && bs=$(pwd)/${bs}
    bs2=${bs%.*}_fileout.sh
    echo -e "$shebang\n" > $bs2
    echo "${bs} > ${bs}.txt 2>&1 &" >> ${bs2}
    chmod +x $bs $bs2
    echo "Output written to $bs"
    echo "Output written to $bs2"
fi
