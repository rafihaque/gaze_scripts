#!/bin/bash

qsub -N 'test' -v meta='CV',check='best_checkpoint_MIT_B16',anal='CV' /home/apongos/gaze_scripts/train/bash_train_chain.sh
