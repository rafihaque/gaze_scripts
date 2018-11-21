#!/bin/bash
#PBS -l nodes=1:ppn=1
#PBS -q batch
#PBS -d /home/apongos/gaze_scripts/train
#PBS -o outPutFiles
#PBS -e outPutFiles

workPath=/home/apongos/gaze_scripts/train/

python "$workPath"main.py --meta $meta --check $check --anal $anal

