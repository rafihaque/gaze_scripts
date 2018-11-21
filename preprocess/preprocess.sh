#!/bin/sh
#PBS -l nodes=1:ppn=1
#PBS -q batch
#PBS -d /home/apongos/gaze_scripts/preprocess
#PBS -o outPutFiles
#PBS -e outPutFiles

# define variables
rawDataPath='/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData'
tool_dir='/home/apongos/gaze_scripts/preprocess/'

# define directories
subj_dir="$rawDataPath/""$sub"
subj_zip="$subj_dir""/frames.zip"
frames_dir="$subj_dir/""frames"
face_dir="$subj_dir""/appleFace_""$crop"
face_file="$subj_dir/""appleFace_""$crop"".json"


# unzip subject and frames_dir within subject
#echo $subj_dir
#if [ ! -e "$subj_dir" ]; then
if [ -z "$(ls -A $frames_dir)" ]; then	
    unzip "$subj_zip" -d "$subj_dir"
    #tar xvzf "$subj_zip" -C "$root_dir"
fi
#if [ ! -e "$frames_dir" ]; then 
#    unzip -o "$frames_dir"".zip" -d "$subj_dir"
#fi

# # detect faces and eyes using openCV
# echo "FACE FILE:""$face_file"
 if [ ! -e "$face_file" ]; then
  echo "Detecting face"
    python "$tool_dir"detect_face.py $subj_dir $tool_dir $crop
 fi

# create image crops and face grid
#echo "FACE DIR:""$face_dir"
#if [ ! -d "$face_dir" ]; then
#  echo "Making crops"
#    "$tool_dir"run_generateCrops.sh /opt/matlab/MCR/2017b/ "$subj_dir" "$crop"
#fi



