#!/usr/bin/env bash

pdf2scanlist.py /Users/Shared/10_Connectivity/raw_data/sub-2025/sub-2025_CNDA.pdf -p /Users/mcavoy/repo/NRL-misc/10_Connectivity_protocol.csv

OGREdcm2niix.sh /Users/Shared/10_Connectivity/raw_data/sub-2025/sub-2025_scanlist.csv -i /Volumes/NRLbackup/10_Connectivity/dicom/sub-2025

export OGREDIR=/path/to/OGRE-pipeline

pipedir=/Users/Shared/10_Connectivity/derivatives/preprocessed/sub-2025/pipeline7.4.1

OGREfMRIpipeSETUP.py /Users/Shared/10_Connectivity/raw_data/sub-2025/sub-2025_scanlist.csv -b

OGREfMRIpipeSETUP.py /Users/Shared/10_Connectivity/raw_data/sub-2025/sub-2025_scanlist.csv -b -f 6 -p 60 -o ${pipedir}/sub-2025_locatorOne.txt -t {pipedir}/sub-2025_locatorTwo.txt
