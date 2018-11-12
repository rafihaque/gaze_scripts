#!/bin/sh
#PBS -l nodes=1:ppn=15
##PBS -l nodes=1:ppn=12:pascal,walltime=168:00:00
#PBS -q batch
#PBS -d /home/apongos/EHAS/server_scripts/Retrain_CNN_Pipeline/toolBox/pytorch/
#PBS -o outPutFiles
#PBS -e outPutFiles

#This script takes a subject from bash_master_script.sh and does these processing jobs on them
# 1) Unzip frames.zip
# 2) Detect Faces (Python)
# 3) Get Crops (Matlab)
#Example run bash_pyTorch_feedForward_allSubjs.sh eyemobile <true/false> <modelName> 

PATH=/home/apongos/gaze_scripts/train:/usr/lib64/mpich/bin:/usr/local/cuda/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/apongos/.local/bin:/home/apongos/bin

#Directories where toolbox are located
workDir="/home/apongos/gaze_scripts/train/"
toolDir="/home/apongos/gaze_scripts/train"
rawDataPath="/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/"

#getSubjsFromTxt=$2 #Grabs from ./selectedSubject2Processes.txt
if [ -z "$modelName" ]; then
 modelName="best_checkpointBMI_GazeAllLong_FineTuneIpad_OurCrops_Clinic.pth.tar"
fi

#Now that path is set, get subjects in that path
#Get all valid subject Folders
declare -a subjectArray
i=1

#Find all subjects
#echo rawDataPathWild: $rawDataPath*
#getSubjsFromTxt=true #grabs from ./selectedSubject2Processes.txt
if [ "$getSubjsFromTxt" = false ] ; then
 for dir in $rawDataPath*
 do
   #Uncomment below to correctly identify MIT dataset
   #echo "$dir"
   #dir=${dir%*/}
   #dir=${dir:(-5)}
   #echo "$dir"
   #if [[ ${dir} =~ ^[0-9]+$ ]] && [[ ${dir##*/} != *".zip"* ]]; then
   
   #Get only base of path to determine if subject folder
   dir2=${dir##*/}
   #Key word is "FaceFrames" for clinic and research
   if [[ ${dir2##*/} == *"FaceFrames"* ]] && [[ ${dir2##*/} != *".zip"* ]]; then
	   subjectArray[i++]=${dir}
	   #echo appending ${dir2} 
   else
   #Key word is subject folder consisting of only numbers for MIT dataset
	  if [[ ${dir2} =~ ^[0-9]+$ ]] && [[ ${dir2##*/} != *".zip"* ]]; then
	   subjectArray[i++]=${dir}
	  fi
    fi
  done
else
 IFS=$'\r\n' GLOBIGNORE='*' command eval  'subjectArray=($(cat ./selectedSubject2Processes.txt))'
 cnt=${#subjectArray[@]}
 for ((i=0;i<cnt;i++)); do
    subjectArray[i]="$rawDataPath""${subjectArray[i]}"
done

fi
echo "subjectArray:" "${subjectArray[@]}"

#exit

#Send subjects to process
#Prepare variables

#declare -a testArray
#testArray='FaceFrames-dffd835b364800645e8c6837f9015ae37afdacc3e031c3de99db5263478d8b75'
#for sub in "${testArray[@]}"

batchSize=8
jobCount=1
subCount=0
#This for-block is for pytorch and is limited to gpu resources (batch size lower)
for sub in "${subjectArray[@]}"
  do
  #  echo "Already processed $sub. Delete events.mat file if you wish to reprocess."
    filePath="$rawDataPath"$sub"/"*xyTorch_MIT_ipad_scratch.mat
    #if [ ! -e "$filePath" ]; then  
    echo "Sending $sub files to get processed"
        bash pyTorchAndEventsProcesses.sh "$sub" "$workDir" "$modelName" &
        jobCount=$((jobCount+1))
        echo "jobCount" $jobCount
    #fi
    subCount=$((subCount+1))
    if (( (jobCount % 8) == 0 )); then
        echo 'Waiting for Batch to finish' "$jobCount"
        wait
       # break

    fi
    if (( (subCount) >= ${#subjectArray[@]} )) ; then
        echo 'checking last ge'
        wait
	#break
    fi
done

#Compile all events to a single struct
#"$workDir"run_gatherAllEyeFeats.sh /opt/matlab/MCR/2017b/

#Upload finished events to Box subject dirs
#bash "$workDir"uploadFinishedFiles.sh "$subject"


