#!/bin/sh

# swarm -f ~/gaze_scripts/preprocess/preprocess_swarm --gres=lscratch:1 --logdir=/data/haqueru/output --merge-output -g 3 -b 4 -p 2

# define variables
root_dir=$1 
subj=$2
tool_dir=$3
crop="MIT"

# define directories
subj_zip="$root_dir""_raw/""$subj"".tar.gz"
subj_zip="/data/haqueru/Emory/""$subj"".tar.gz"
subj_zip="/data/haqueru/Emory/""$subj"".zip"
subj_dir="$root_dir/""$subj"
frames_dir="$subj_dir/""frames"
face_dir="$subj_dir""/appleFace"
face_file="$subj_dir/""appleFace_""$crop"".json"


# # unzip subject and frames_dir within subject
# echo $subj_dir
# if [ ! -e "$subj_dir" ]; then 
#     echo $subj_dir
#     unzip -o "$subj_zip" -d "$root_dir"
#     #tar xvzf "$subj_zip" -C "$root_dir"
# fi
# if [ ! -e "$frames_dir" ]; then 
#     unzip -o "$frames_dir"".zip" -d "$subj_dir"
# fi

# # detect faces and eyes using openCV
# echo "FACE FILE:""$face_file"
# if [ ! -f "$face_file" ]; then
#    source /data/haqueru/conda/etc/profile.d/conda.sh
#    conda activate object_detection
#    python "$tool_dir"detect_face.py $subj_dir $tool_dir $crop
#    conda deactivate
# fi

# create image crops and face grid
echo "FACE DIR:""$face_dir"
if [ ! -f "$face_dir" ]; then
    "$tool_dir"run_generateCrops.sh /usr/local/matlab-compiler/v94 "$subj_dir" "$crop"
fi



