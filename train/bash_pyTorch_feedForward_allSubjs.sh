#!/bin/bash
#This script will feedforward all subjs in batches and in parallel jobs. Assume crops and Grids already made
#Example: bash bash_pyTorch_feedForward_allSubjs.sh eyemobile
 
    qsub -N "FeedForwardAll_$1" -v meta=$1,check=$2,anal=$3 /home/apongos/EHAS/server_scripts/Retrain_CNN_Pipeline/toolBox/pytorch/bash_pyTorch_feedForward_allSubjs_chain.sh

