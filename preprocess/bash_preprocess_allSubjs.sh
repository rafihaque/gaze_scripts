#!/bin/bash
#This script will preprocess all subjs
#Example: bash bash_pyTorch_feedForward_allSubjs.sh
dataDir='/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/'


#Get list of all subjects
declare -a subjectArray
for dir in $dataDir*
	do
	#echo $dir
	base=${dir##*/}
	#if [[ ${base} =~ ^[0-9]+$ ]] && [[ ${base##*/} != *".zip"* ]]; then
      if [[ ${base##*/} == *"FaceFrames"* ]] && [[ ${base##*/} != *".zip"* ]]; then   
      	subjectArray[i++]=${base}
   	#else
	#     if [[ ${base##*/} == *"FaceFrames"* ]] && [[ ${base##*/} != *".zip"* ]]; then
	#	     subjectArray[i++]=${base}
	 #    fi	     
        fi
done
echo subjectArray "${subjectArray[@]}"

declare -a jobID
delay=100
i=0
#length=20
length=${#subjectArray[@]}

while [ $i -lt $length ]; do
	sub="${subjectArray[i]}"
    	if [ $i -lt $delay ]; then
		jobID[i]=$(qsub -N "$sub" -v sub="$sub",crop='CV' /home/apongos/gaze_scripts/preprocess/preprocess.sh)
	else
		jobID[i]=$(qsub -N "$sub" -v sub="$sub",crop='CV' -W depend=afterany:"${jobID[(i - $delay)]}" /home/apongos/gaze_scripts/preprocess/preprocess.sh)
	fi
	i=$((i + 1))
	echo $i
done

#echo $#{subjectArray[@]:0:3}

