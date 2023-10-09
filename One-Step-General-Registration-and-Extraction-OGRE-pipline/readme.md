# Connectome Operations For FSL ExEcution (COFFEE) Pipeline  

Ben Philip in Occupational Therapy at Washington University created a fMRI processing pipeline to integrate HCP preprocessing (including Freesurfer) with FSL on the Mac, for analysis of task MRI data.

In the HCP/scripts directory are a number of bash programs that are modified versions of the HCP originals. Install the stock HCP v3.27 minimal processing pipeline (https://github.com/Washington-University/HCPpipelines/tree/v3.27.0) and insert the "scripts" directory.

Besides the elimination of the hard coded paths and file names expected in by the stock scripts, the structural pipeline can run without a T2w image and the resolution can be specified to be either 0.7mm, 0.8mm or 1mm.  The pipeline can be run with Freesurfer versions 7.2.0, 7.3.2 and 7.4.0 as well as 5.3.0-HCP.  The Freesurfer can be edited, and an option reruns just the necessary parts of the structural pipeline.

For further information see the included manual and linked publication.

Consider examples/10_2000_scanlist.csv. The first step is to create the driving file for the set-up scripts.  
&emsp;&emsp;% **scanlist2dat.py 10_2000_scanlist.csv**  
This will create examples/10_2000.dat. The functional and structural pipelines can then be created  
&emsp;&emsp;% **OGREstructpipeSETUP.sh 10_2000.dat -b 10_2000_batch.sh**  
&emsp;&emsp;% **OGREfMRIpipeSETUPT.sh 10_2000.dat -f 4 6 -p 60 -b 10_2000_batch.sh**  
This includes 4 and 6mm spatial smoothing along with a high pass filter with a 60s cutoff. Then run  
&emsp;&emsp;% **./10_2000_batch_fileout.sh**
