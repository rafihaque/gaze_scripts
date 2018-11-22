#!/bin/sh

#PBS -N "pbsdsh"
#PBS -l nodes=10:ppn=11
#PBS -q batch
#PBS -d /home/apongos/gaze_scripts/train/
#PBS -e outPutFiles
#PBS -o outPutFiles

pbsdsh -c 10 sh /home/apongos/gaze_scripts/train/split_pbsdsh.sh
