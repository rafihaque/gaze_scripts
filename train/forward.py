import math, shutil, os, time
import numpy as np
import scipy.io as sio

import torch
import torch.nn as nn
import torch.nn.parallel
import torch.backends.cudnn as cudnn
import torch.optim
import torch.utils.data
import torchvision.transforms as transforms
import torchvision.datasets as datasets
import torchvision.models as models
import argparse
from ITrackerData import ITrackerData
from ITrackerModel import ITrackerModel
from shutil import copyfile
import pdb
'''
Train/test code for iTracker.

Author: Petr Kellnhofer ( pkel_lnho (at) gmai_l.com // remove underscores and spaces), 2018. 

Website: http://gazecapture.csail.mit.edu/

Cite:

Eye Tracking for Everyone
K.Krafka*, A. Khosla*, P. Kellnhofer, H. Kannan, S. Bhandarkar, W. Matusik and A. Torralba
IEEE Conference on Computer Vision and Pattern Recognition (CVPR), 2016

@inproceedings{cvpr2016_gazecapture,
Author = {Kyle Krafka and Aditya Khosla and Petr Kellnhofer and Harini Kannan and Suchendra Bhandarkar and Wojciech Matusik and Antonio Torralba},
Title = {Eye Tracking for Everyone},
Year = {2016},
Booktitle = {IEEE Conference on Computer Vision and Pattern Recognition (CVPR)}
}

'''


# paths 
CHECKPOINTS_PATH = 'home/apongos/gaze_scripts/train/models/'
TRAIN_PATH = '/home/apongos/gaze_scripts/train/'
DATASET_PATH = '/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/'

# params
workers = 2
batch_size = 1



def main(meta,check,anal):
    global args, best_prec1, weight_decay, momentum, train_txt, valid_txt
    
    # load model
    model = ITrackerModel()
    model = torch.nn.DataParallel(model)
    imSize=(224,224)
    saved = load_checkpoint('best_checkpoint_%s.pth.tar' % check)
    if saved:
        print('Loading checkpoint for epoch %05d with loss %.5f (which is L2 = mean of squares)...' % (saved['epoch'], saved['best_prec1']))
        state = saved['state_dict']
        try:
            model.module.load_state_dict(state)
        except:
            model.load_state_dict(state)
    
        epoch = saved['epoch']
        best_prec1 = saved['best_prec1']
    else:
        print('Warning: Could not read checkpoint!');


    # generate subject metadata
    subj_path  = os.path.join(DATASET_PATH,args.subj)
    data_val   = ITrackerData(split='all', imSize = imSize, META_NAME='metadata_%s' % meta,DATASET_PATH=DATASET_PATH,METADATA_PATH=subj_path)
    val_loader = torch.utils.data.DataLoader(data_val,batch_size=batch_size, shuffle=False, num_workers=workers, pin_memory=True)



    # forward model
    out = np.empty((len(data_val.metadata['labelTrain']),2))
    out[:]=np.nan
    for i, (row, imFace, imEyeL, imEyeR, faceGrid, gaze) in enumerate(val_loader):
        imFace = torch.autograd.Variable(imFace, volatile = True)
        imEyeL = torch.autograd.Variable(imEyeL, volatile = True)
        imEyeR = torch.autograd.Variable(imEyeR, volatile = True)
        faceGrid = torch.autograd.Variable(faceGrid, volatile = True)
        gaze = torch.autograd.Variable(gaze, volatile = True)

        # compute output
        output = model(imFace, imEyeL, imEyeR, faceGrid)
        out[i,:] = output.data.cpu().numpy()
        pdb.set_trace()
    pdb.set_trace()
    sio.savemat(os.path.join(subj_path,'gaze_%s' % check),{'xy':out})


def load_checkpoint(filename):
    filename = os.path.join(CHECKPOINTS_PATH, filename)
    print(filename)
    if not os.path.isfile(filename):
        return None
    state = torch.load(filename)
    return state




if __name__ == "__main__":
    #Set a default path to research
    parser = argparse.ArgumentParser(description='Training Script')
    parser.add_argument('-s','--subj',help='Load Subject')    
    parser.add_argument('-m','--meta',help='Load Metadata')    
    parser.add_argument('-c','--check',help='Load Checkpoint')
    parser.add_argument('-a','--anal',help='Model Name')
    args = parser.parse_args()
    main(args.meta,args.check,args.anal)
    print('DONE')
