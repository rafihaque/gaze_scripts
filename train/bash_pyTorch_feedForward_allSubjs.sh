#!/bin/bash
#This script will preprocess all subjs
#Example: bash bash_pyTorch_feedForward_allSubjs.sh
dataDir='/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/'
anal='CV'

#Get list of all subjects
declare -a subjectArray
for dir in $dataDir*
	do
	#echo $dir
	base=${dir##*/}
	#if [[ ${base} =~ ^[0-9]+$ ]] && [[ ${base##*/} != *".zip"* ]]; then
      if [[ ${base##*/} == *"FaceFrames"* ]] && [[ ${base##*/} != *".zip"* ]]; then   
      	#echo "$dataDir""$base/""metadata_$anal.mat"
	if [ -e "$dataDir""$base/""metadata_$anal.mat" ]; then
		subjectArray[i++]=${base}
   	#else
	#     if [[ ${base##*/} == *"FaceFrames"* ]] && [[ ${base##*/} != *".zip"* ]]; then
	#	     subjectArray[i++]=${base}
	 #    fi
	fi

        fi
done
echo subjectArray "${subjectArray[@]}"

#exit
declare -a jobID
delay=50
i=0
#length=5
length=${#subjectArray[@]}

while [ $i -lt $length ]; do
	sub="${subjectArray[i]}"
    	if [ $i -lt $delay ]; then
		jobID[i]=$(qsub -N "$sub" -v sub="$sub",anal="$anal" /home/apongos/gaze_scripts/train/forward.sh)
	else
		jobID[i]=$(qsub -N "$sub" -v sub="$sub",anal="$anal" -W depend=afterany:"${jobID[(i - $delay)]}" /home/apongos/gaze_scripts/train/forward.sh)
	fi
	i=$((i + 1))
	echo $i
	#sleep 1
done

#echo $#{subjectArray[@]:0:3}
