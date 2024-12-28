#!/usr/bin/env bash

root0=${0##*/}
helpmsg(){

    echo "Copy scripts and lib directories from local OGRE-pipeline repository for testing."
    echo "Required: ${root0} -r <repository directory> -v <version number>"
    echo "    -r --repo -repo --repository -repository"
    echo "        Repository directory. All code for the install will be pulled from this directory."
    echo "    -i --install -install"
    echo "        OGRE will be installed at this location as <install>/<version>. Default is the working directory."
    echo "        An argument without an option is assumed to be the install directory."
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
unset version repo

arg=("$@")
for((i=0;i<${#@};++i));do
    #echo "i=$i ${arg[i]}"
    case "${arg[i]}" in

        #START240420
        -r | --repo | -repo | --repository | -repository)
            repo=${arg[((++i))]}
            #echo "install=$install"
            ;;

        -i | --install | -install)
            install=${arg[((++i))]}
            #echo "install=$install"
            ;;
        -v | --version | --version)
            version=${arg[((++i))]}
            #echo "version=$version"
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

if [ -z "${version}" ];then
    echo "-version not set. Abort!"
    exit
fi
if [ -z "${repo}" ];then
    echo "-repository not set. Abort!"
    exit
fi
if [ -z "${install}" ];then
    install=$PWD
    if [[ "$install" == "$repo" ]];then
        echo "You cannot install in the same location as your repository $repo Abort!"
        exit
    fi
fi



#echo "install=$install"
#echo "version=$version"
id=$install/$version

 
if [ -d "$id" ];then
    #https://stackoverflow.com/questions/18544359/how-do-i-read-user-input-into-a-variable-in-bash
    read -p "$id exists. Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
    #read -p "$id exists. Continue? (Y/N): " confirm && [[ ${confirm^^} == 'YES' ]] || exit 1

    rm -rf $id
fi



#mkdir -p $id/scripts
#files=(OGREcleanSETUP.sh \
#       OGREfMRIpipeSETUP.py \
#       OGREstructpipeSETUP.sh \
#       OGREdcm2niix.sh \
#       pdf2scanlist.py)
#for i in ${files[@]};do
#    cp -p $repo/scripts/$i $id/scripts
#done
#mkdir -p $id/lib
#files=(OGREAtlasRegistrationToMNI152_FLIRTandFNIRT.sh \
#       OGREBiasFieldCorrection_sqrtT1wXT1w.sh \
#       OGRECreateMyelinMaps.sh \
#       OGREDistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased.sh \
#       OGREFreeSurfer2CaretConvertAndRegisterNonlinear.sh \
#       OGREFreeSurferHiresPial.sh \
#       OGREFreeSurferHiresWhite.sh \
#       OGREFreeSurferPipeline.sh \
#       OGREFreeSurferPipelineBatch.sh \
#       OGREGenericfMRIVolumeProcessingPipeline.sh \
#       OGREGenericfMRIVolumeProcessingPipelineBatch.sh \
#       OGREIntensityNormalization.sh \
#       OGREMotionCorrection.sh \
#       OGREOneStepResampling.sh \
#       OGREPostFreeSurferPipeline.sh \
#       OGREPostFreeSurferPipelineBatch.sh \
#       OGREPreFreeSurferPipeline.sh \
#       OGREPreFreeSurferPipelineBatch.sh \
#       OGRESetUpHCPPipeline.sh \
#       OGRESmoothingProcess.sh \
#       OGRET1w_restore.sh \
#       OGRET2wToT1wReg.sh \
#       OGREmcflirt.sh \
#       OGREmakeregdir.sh)
#for i in ${files[@]};do
#    cp -p $repo/lib/$i $id/lib
#done
#START241226
#mkdir -p $id
#cp -r -p $repo $id

#echo "repo=$repo"
#for i in $repo/*;do
#    echo "i=$i"
#done   

mkdir -p $id
echo "Copying $repo/scripts to $id"
cp -Rp $repo/scripts $id
echo "Copying $repo/lib to $id"
cp -Rp $repo/lib $id




echo "Installation $id complete." 
