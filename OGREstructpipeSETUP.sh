#!/usr/bin/env bash

shebang="#!/usr/bin/env bash"

#Hard coded location of HCP scripts
[ -z ${HCPDIR+x} ] && HCPDIR=/Users/Shared/pipeline/HCP

#Hard coded location of freesurfer installations
[ -z ${FREESURFDIR+x} ] && FREESURFDIR=/Applications/freesurfer

#Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2 7.4.0
[ -z ${FREESURFVER+x} ] && FREESURFVER=7.4.0

#Hard coded HCP batch scripts
pre0=OGREPreFreeSurferPipelineBatch.sh
free0=OGREFreeSurferPipelineBatch.sh
post0=OGREPostFreeSurferPipelineBatch.sh

#Hard coded pipeline settings
setup0=OGRESetUpHCPPipeline.sh

#Resolution. options: 1, 0.7 or 0.8
Hires=1

root0=${0##*/}
helpmsg(){
    echo "Required: ${root0} <mydatfile>"
    echo "    -d --dat -dat"
    echo "        dat file(s). Arguments without options are assumed to be dat files."
    echo "        Ex 1. ${root0} 1001.dat 2000.dat"
    echo "        Ex 2. ${root0} \"1001.dat -d 2000.dat\""
    echo "        Ex 3. ${root0} -d 1001.dat 2000.dat"
    echo "        Ex 4. ${root0} -d \"1001.dat 2000.dat\""
    echo "        Ex 5. ${root0} -d 1001.dat -d 2000.dat"
    echo "        Ex 6. ${root0} 1001.dat -d 2000.dat"
    echo "    -A --autorun -autorun --AUTORUN -AUTORUN"
    echo "        Flag. Automatically execute *_fileout.sh script. Default is to not execute."
    echo "    -b --batchscript -batchscript"
    echo "        *_fileout.sh scripts are collected in the executable batchscript."
    echo "    -H --HCPDIR -HCPDIR --hcpdir -hcpdir"
    echo "        HCP directory. Optional if set at the top of this script or elsewhere via variable HCPDIR."
    echo "    -V --VERSION -VERSION --FREESURFVER -FREESURFVER --freesurferVersion -freesurferVersion"
    echo "        5.3.0-HCP, 7.2.0, 7.3.2, or 7.4.0. Default is 7.3.2 unless set elsewhere via variable FREESURFVER."
    echo "    -m --HOSTNAME"
    echo "        Flag. Use machine name instead of user named file."
    echo "    -D --DATE -DATE --date -date"
    echo "        Flag. Add date (YYMMDD) to name of output script."
    echo "    -DL --DL --DATELONG -DATELONG --datelong -datelong"
    echo "        Flag. Add date (YYMMDDHHMMSS) to name of output script."
    echo "    -r  --hires"
    echo "        Resolution. Should match that for the sturctural pipeline. options : 0.7, 0.8 or 1mm. Default is 1mm."
    echo "    -h --help -help"
    echo "        Echo this help message."
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi
echo $0 $@

#lcautorun=0;bs=;lchostname=0;lcdate=0 #do not set dat;unexpected
#START230712
lcautorun=0;lchostname=0;lcdate=0 #do not set dat;unexpected
unset bs

arg=("$@")
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in
        -d | --dat | -dat)
            dat+=(${arg[((++i))]})
            for((j=i;j<${#@};++i));do #i is incremented only if dat is appended
                dat0=(${arg[((++j))]})
                [ "${dat0::1}" = "-" ] && break
                dat+=(${dat0[@]})
            done
            ;;
        -A | --autorun | -autorun | --AUTORUN | -AUTORUN)
            lcautorun=1
            echo "lcautorun=$lcautorun"
            ;;
        -b | --batchscript | -batchscript)
            bs=${arg[((++i))]}
            echo "bs=$bs"
            ;;
        -H | --HCPDIR | -HCPDIR | --hcpdir | -hcpdir)
            HCPDIR=${arg[((++i))]}
            echo "HCPDIR=$HCPDIR"
            ;;
        -V | --VERSION | -VERSION | --FREESURFVER | -FREESURFVER | --freesurferVersion | -freesurferVersion)
            FREESURFVER=${arg[((++i))]}
            echo "FREESURFVER=$FREESURFVER"
            ;;
        -m | --HOSTNAME)
            lchostname=1
            echo "lchostname=$lchostname"
            ;;
        -D | --DATE | -DATE | --date | -date)
            lcdate=1
            echo "lcdate=$lcdate"
            ;;
        -DL | --DL | --DATELONG | -DATELONG | --datelong | -datelong)
            lcdate=2
            echo "lcdate=$lcdate"
            ;;
        -r | --hires)
            Hires=${arg[((++i))]}
            echo "Hires=$Hires"
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

PRE=${HCPDIR}/scripts/${pre0}
FREE=${HCPDIR}/scripts/${free0}
POST=${HCPDIR}/scripts/${post0}
ES=${HCPDIR}/scripts/${setup0}

for((i=0;i<${#dat[@]};++i));do
    IFS=$'\r\n' read -d '' -ra csv0 < ${dat[i]}
    #printf '%s\n' "${csv0[@]}"
    #echo ''
    csv+=("${csv0[@]}")
done
#printf '%s\n' "${csv[@]}"

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

#if [[ "${FREESURFVER}" != "5.3.0-HCP" && "${FREESURFVER}" != "7.2.0" && "${FREESURFVER}" != "7.3.2" ]];then
#    echo "Unknown version of freesurfer. FREESURFVER=${FREESURFVER}"
#    exit
#fi
#[[ "${FREESURFVER}" = "7.2.0" || "${FREESURFVER}" = "7.3.2" ]] && lctworeconall=1
#START230607
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

for((i=0;i<${#csv[@]};++i));do
    IFS=$'\r\n\t, ' read -ra line <<< ${csv[i]}
    if [[ "${line[0]:0:1}" = "#" ]];then
        #echo "Skiping line $((i+1))"
        continue
    fi

    echo ${line[0]}

    T1f=${line[2]}
    if [[ "${T1f}" = "NONE" || "${T1f}" = "NOTUSEABLE" ]];then
        echo "    T1 ${T1f}"
        continue
    fi
    if [ ! -f "$T1f" ];then
        echo "    T1 ${T1f} not found"
        continue
    fi
    echo "    T1 ${T1f}"

    T2f=;T20=${line[3]}
    if [[ "${T20}" = "NONE" || "${T20}" = "NOTUSEABLE" ]];then
        echo "    T2 ${T20}"
    elif [ ! -f "${T20}" ];then
        echo "    T2 ${T20} not found"
    else
        T2f=${T20}
        echo "    T2 ${T2f}"
    fi

    dir0=${line[1]}${FREESURFVER}
    mkdir -p ${dir0}

    if((lchostname==0));then
        IFS=$'/' read -ra line2 <<< ${line[1]}
        #echo "line2=${line2[@]}"
        sub0=${line2[-2]}
        #echo "sub0=${sub0}"
    fi

    ((lcdate==0)) && F0stem=${dir0}/${line[0]////_}_hcp3.27struct || F0stem=${dir0}/${line[0]////_}_hcp3.27struct_$(date +%y%m%d) 
    F0=${F0stem}.sh
    F1=${F0stem}_fileout.sh
    #echo  "F0=${F0}"
    #echo  "F1=${F1}"

    #[ -n "${bs}" ] && echo "    ${F0}"
    #START230625
    if [ -n "${bs}" ];then
        echo "    ${F0}"
        ((lcdate==0)) && bs0stem=${dir0}/${line[0]////_}_hcp3.27batch || bs0stem=${dir0}/${line[0]////_}_hcp3.27batch_$(date +%y%m%d) 
        bs0=${bs0stem}.sh
        echo -e "$shebang\nset -e\n" > ${bs0} 
        bs1=${bs0stem}_fileout.sh
        echo -e "$shebang\nset -e\n" > ${bs1} 
    fi

    #echo -e "$shebang\n" > ${F0} 
    #echo -e "$shebang\n" > ${F1} 
    #START230609
    echo -e "$shebang\nset -e\n" > ${F0} 
    echo -e "$shebang\nset -e\n" > ${F1} 


    echo -e "#$0 $@\n" >> ${F0}

    echo "FREESURFVER=${FREESURFVER}" >> ${F0}
    echo -e export FREESURFER_HOME=${FREESURFDIR}/'${FREESURFVER}'"\n" >> ${F0}
    echo 'PRE='${PRE} >> ${F0}
    echo 'FREE='${FREE} >> ${F0}
    echo 'POST='${POST} >> ${F0}
    echo -e "ES=${ES}\n" >> ${F0}
    echo "sf0=${line[1]}"'${FREESURFVER}' >> ${F0}

    if((lchostname==1));then
        echo 's0=$(hostname)' >> ${F0}
    else
        echo "s0=${sub0}" >> ${F0}
    fi
    echo -e "Hires=${Hires}\n" >> ${F0}

    echo '${PRE} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    echo '    --Subject=${s0} \' >> ${F0}
    echo '    --runlocal \' >> ${F0}
    echo '    --T1='${T1f}' \' >> ${F0}
    echo '    --T2='${T2f}' \' >> ${F0}
    echo '    --GREfieldmapMag="NONE" \' >> ${F0}
    echo '    --GREfieldmapPhase="NONE" \' >> ${F0}
    echo '    --EnvironmentScript=${ES} \' >> ${F0}
    echo '    --Hires=${Hires} \' >> ${F0}
    echo -e '    --EnvironmentScript=${ES}\n' >> ${F0}

    echo '${FREE} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    echo '    --Subject=${s0} \' >> ${F0}
    echo '    --runlocal \' >> ${F0}
    echo '    --Hires=${Hires} \' >> ${F0}
    echo '    --freesurferVersion=${FREESURFVER} \' >> ${F0}
    ((lcsinglereconall)) && echo '    --singlereconall \' >> ${F0}
    ((lctworeconall)) && echo '    --tworeconall \' >> ${F0}
    echo -e '    --EnvironmentScript=${ES}\n' >> ${F0}

    echo '${POST} \' >> ${F0}
    echo '    --StudyFolder=${sf0} \' >> ${F0}
    echo '    --Subject=${s0} \' >> ${F0}
    echo '    --runlocal \' >> ${F0}
    echo '    --EnvironmentScript=${ES}' >> ${F0}

    #echo "${F0} > ${F0}.txt 2>&1 &" >> ${F1}
    #START230623
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

        #echo "cd ${dir0}" >> $bs
        #echo -e "${F0} > ${F0}.txt 2>&1 &\n" >> $bs
        #START230624
        #echo "cd ${dir0}" >> $bs
        #echo -e "${F0} > ${F0}.txt 2>&1\n" >> $bs
        #START230625
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

        #${F0[0]} > ${F0[0]}.txt 2>&1 &
        #START230409
        ${F1}
        echo "    ${F1} has been executed"

        cd ${wd0} #"cd -" echoes the path

        #START230409
        #echo "    ${F0[0]} has been executed"

    fi

done

#chmod +x $bs
#echo "Output written to $bs"
#START230303
if [ -n "${bs}" ];then

    #chmod +x $bs
    #echo "Output written to $bs"
    #START230712
    [[ $bs != *"/"* ]] && bs=$(pwd)/${bs}
    bs2=${bs%.*}_fileout.sh
    echo -e "$shebang\n" > $bs2
    echo "${bs} > ${bs}.txt 2>&1 &" >> ${bs2}
    chmod +x $bs $bs2
    echo "Output written to $bs"
    echo "Output written to $bs2"

fi
