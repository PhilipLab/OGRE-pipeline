#!/usr/bin/env bash

shebang="#!/usr/bin/env bash"

#Hard coded location of freesurfer installations
[ -z ${FREESURFDIR+x} ] && FREESURFDIR=/Applications/freesurfer

##Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2
#[ -z ${FREESURFVER+x} ] && FREESURFVER=7.3.2
#START231114
#Hard coded freesurfer version options: 5.3.0-HCP 7.2.0 7.3.2 7.4.0
[ -z ${FREESURFVER+x} ] && FREESURFVER=7.4.0


root0=${0##*/}
helpmsg(){
    echo "From the pipeline<7.4.0> folder, the T1w, T2w and all <BOLD run> folders are removed."
    echo "A *fileout.sh is created and that is the one to execute if you choose not to -AUTORUN"
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
    echo "        Flag. Automatically execute script. Default is not execute *_autorun.sh"
    echo "    -b --batchscript -batchscript"
    echo "        *_autorun.sh scripts are collected in the executable batchscript."

    #echo "    -F --FREESURFVER -FREESURFVER --freesurferVersion -freesurferVersion"
    #START231114
    echo "    -V --VERSION -VERSION --FREESURFVER -FREESURFVER --freesurferVersion -freesurferVersion"
    echo "        5.3.0-HCP, 7.2.0, 7.3.2, or 7.4.0. Default is 7.4.0 unless set elsewhere via variable FREESURFVER."


    #echo "        5.3.0-HCP, 7.2.0, 7.3.2 or 7.4.0. Default is 7.3.2 unless set elsewhere via variable FREESURFVER."
    #START231114
    echo "        5.3.0-HCP, 7.2.0, 7.3.2 or 7.4.0. Default is 7.3.2 unless set elsewhere via variable FREESURFVER."

    echo "    -m --HOSTNAME"
    echo "        Flag. Use machine name instead of user named file."
    echo "    -D --DATE -DATE --date -date"
    echo "        Flag. Add date (YYMMDD) to name of output script."
    echo "    -DL --DL --DATELONG -DATELONG --datelong -datelong"
    echo "        Flag. Add date (YYMMDDHHMMSS) to name of output script."
    echo "    -h --help -help"
    echo "        Echo this help message."
    exit
    }
if((${#@}<1));then
    helpmsg
    exit
fi
echo $0 $@

lcautorun=0;bs=;lchostname=0;lcdate=0 #do not set dat or unexpected

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
            #echo "lcautorun=$lcautorun"
            ;;
        -b | --batchScript | -batchscript)
            bs=${arg[((++i))]}
            echo "bs=$bs"
            ;;

        #-F | --FREESURFVER | -FREESURFVER | --freesurferVersion | -freesurferVersion)
        #START231114
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
    IFS=$'\r\n' read -d '' -ra csv0 < ${dat[i]}
    csv+=("${csv0[@]}")
done
#printf '%s\n' "${csv[@]}"

#START230622
#if [[ "${FREESURFVER}" != "5.3.0-HCP" && "${FREESURFVER}" != "7.2.0" && "${FREESURFVER}" != "7.3.2" ]];then
#    echo "Unknown version of freesurfer. FREESURFVER=${FREESURFVER}"
#    exit
#fi

if [ -n "${bs}" ];then

    #bs0=${bs%/*}
    #mkdir -p ${bs0}
    #START230622
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

    dir0=${line[1]}${FREESURFVER}
    if [ ! -d "${dir0}" ];then
        echo "${dir0} does not exist"
        continue
    fi

    if((lcdate==1));then
        date0=$(date +%y%m%d)
    elif((lcdate==2));then
        date0=$(date +%y%m%d%H%M%S)
    fi
    #echo "date0=${date0}"

    F0=
    ((lcdate==0)) && F0stem=${dir0}/${line[0]////_}_clean || F0stem=${dir0}/${line[0]////_}_clean_${date0}
    F0[0]=${F0stem}.sh

    #F1=${F0stem}_autorun.sh
    #START
    F1=${F0stem}_fileout.sh

    for((j=0;j<${#F0[@]};++j));do

        #echo -e "$shebang\n" > ${F0[j]} 
        #START230622
        echo -e "$shebang\nset -e\n" > ${F0[j]} 

        echo -e "#$0 $@\n" >> ${F0[j]}
    done 
    echo -e "$shebang\n" > ${F1}

    echo "FREESURFVER=${FREESURFVER}" >> ${F0[0]}   
    echo "sf0=${line[1]}"'${FREESURFVER}' >> ${F0[0]}
    sf0=${line[1]}${FREESURFVER}

    echo -e '\nrm -rf ${sf0}/T1w' >> ${F0[0]}
    [ -d ${sf0}/T2w ] && echo 'rm -rf ${sf0}/T2w' >> ${F0[0]}
    for((j=7;j<=23;j+=2));do
        str0=${line[j]##*/}
        str0=${str0%.nii*}
        #echo "j=${j} ${sf0}/${str0}"
        [ -d ${sf0}/${str0} ] && echo 'rm -rf ${sf0}/'${str0} >> ${F0[0]}
    done

    if [ -f "${F0[0]}" ];then
        echo "${F0[0]} > ${F0[0]}.txt 2>&1 &" >> ${F1}
        for((j=0;j<${#F0[@]};++j));do
            chmod +x ${F0[j]}
            echo "    Output written to ${F0[j]}"
        done
        chmod +x ${F1}
        echo "    Output written to ${F1}"
    else
        rm -f ${F1}
    fi

    if [ -n "${bs}" ];then
        echo "cd ${dir0}" >> $bs

        #echo -e "${F0[0]} > ${F0[0]}.txt 2>&1 &\n" >> $bs
        #START230622
        echo -e "${F0[0]} > ${F0[0]}.txt 2>&1\n" >> $bs #run serially

    fi
    if((lcautorun==1 && lcmakeregdironly==0));then
        cd ${dir0}
        ${F1}
        echo "    ${F1} has been executed"
        cd ${wd0} #"cd -" echoes the path
    fi
done
if [ -n "${bs}" ];then
    chmod +x $bs
    echo "Output written to $bs"
fi
