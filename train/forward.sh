#!/bin/sh
#PBS -l nodes=1:ppn=2
#PBS -q batch
#PBS -d /home/apongos/gaze_scripts/train
#PBS -o outPutFiles
#PBS -e outPutFiles

# define variables
rawDataPath='/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData'
tool_dir='/home/apongos/gaze_scripts/train/'
c='MIT_B16'

python "$tool_dir"forward.py -s $sub -m $anal -c $c -a $anal


