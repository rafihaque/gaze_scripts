#!/bin/sh

PATH=/home/apongos/gaze_scripts/train:/usr/lib64/mpich/bin:/usr/local/cuda/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/apongos/.local/bin:/home/apongos/bin


subject=$1
workDir=$2
modelName='best_checkpointBMI_GazeAllLong_FineTuneIpad_OurCrops.pth.tar'
rawDataPath='/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/'
metaPath='/home/apongos/gaze_scripts/train/metadata.mat'

#Run pytorch finetuned model and events
filePath="$subject""/xyTorch_MIT_ipad_FineTuneClinic3.mat"
# if [ ! -e "$filePath" ]; then
	echo running pytorch
	"$workDir"exec_pyTorch_all.sh -s "$subject" -m "$metaPath" -c "$modelName" -a "Baseline"
