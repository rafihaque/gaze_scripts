#!/bin/bash/

PATH=/home/apongos/gaze_scripts/train:/usr/lib64/mpich/bin:/usr/local/cuda/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/apongos/.local/bin:/home/apongos/bin

workDir='/home/apongos/gaze_scripts/train/'
echo "submitting: "$PBS_VNODENUM
python "$workDir"split_pbsdsh.py
