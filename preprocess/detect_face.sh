#!/bin/bash
export CUDA_VISIBLE_DEVICES=0
python "$2"openCV_DetectFace.py $1 $4
