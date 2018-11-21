#!/bin/sh
#PBS -l nodes=1:ppn=20
#PBS -q batch
#PBS -d /home/apongos/gaze_scripts/preprocess
#PBS -o outPutFiles
#PBS -e outPutFiles

PATH=/home/apongos/gaze_scripts/preprocess:/usr/lib64/mpich/bin:/usr/local/cuda/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/apongos/.local/bin:/home/apongos/bin

#Directories where toolbox are located
workDir="/home/apongos/gaze_scripts/preprocess/"
toolDir="/home/apongos/gaze_scripts/preprocess/"
rawDataPath="/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/"

"$toolDir"run_parForGenCrops.sh /opt/matlab/MCR/2017b/ "$rawDataPath" "CV" 
# "$tool_dir"run_generateSubjInfo.sh /opt/matlab/MCR/2017b/ "$rawDataPath" "CV"
