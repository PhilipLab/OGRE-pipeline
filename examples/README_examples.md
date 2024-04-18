List of example files. For further details on all of these, see the COFFEE manual. In all cases, "XX_XXXX" is the subject number, and can be any format whatsoever.

XX_XXXX.dat: An example "dat" file specifying the names of all relevant files for a single participant. You can generate this automatically from the _scanlist.csv file via scanlist2dat.py 

XX_XXXX_scanlist.csv: A spreadsheet used by dcm2niix.sh to convert dicom files into nifti files. Needs "Scan" (the scan #), "Series Desc" (from dicom info), and "nii" (the name you want for the created nifti file).

adapterOne.txt: A text file to use with the -o input to OGREfMRIpipeSETUP.sh. Contains the paths of first-level .fsf files (from FSL FEAT) you want to run automatically on the COFFEE outputs. OGRE will run these .fsf files, and then the FEAT adapter (OGREmakeregdir.sh).

adapterTwo.txt: A text file to use with the -t input to OGREfMRIpipeSETUP.sh. Contains the paths of higher-level .fsf files (from FSL FEAT) you want to run automatically after adapterOne (and its subsequent FEAT adapter call).
