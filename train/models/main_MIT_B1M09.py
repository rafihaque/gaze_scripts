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
CHECKPOINTS_PATH = '/home/haqueru/gaze_scripts/train/models/'
TRAIN_PATH = '/home/haqueru/gaze_scripts/train/'
DATASET_PATH = '/data/haqueru/gaze/'
doTest = False
# params
workers = 4
epochs  = 10
batch_size = 1#torch.cuda.device_count()*32 # Change if out of cuda 
base_lr = 0.0001
momentum = 0.09
weight_decay = 1e-4
print_freq = 10
prec1 = 1e-15
best_prec1 = 1e20
lr = base_lr
count_test = 0
count = 0
train_txt = ''
valid_txt = ''



def main(meta,check,anal):
    global args, best_prec1, weight_decay, momentum, train_txt, valid_txt
    
    train_txt = os.path.join(CHECKPOINTS_PATH,'train_%s_%s_%s' % (meta, check, anal))
    valid_txt = os.path.join(CHECKPOINTS_PATH,'valid_%s_%s_%s' % (meta, check, anal))
    if not os.path.isfile(train_txt):
        open(train_txt,'w')
        open(valid_txt,'w')

    copyfile(os.path.join(TRAIN_PATH,'main.py'),os.path.join(CHECKPOINTS_PATH,'main_%s.py' % anal) )
    
    model = ITrackerModel()
    model = torch.nn.DataParallel(model)
    model.cuda()
    imSize=(224,224)
    cudnn.benchmark = True   
    print(batch_size)
    epoch = 0
    if check != 'None':

        saved = load_checkpoint('checkpoint_%s.pth.tar' % check)
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


    dataTrain = ITrackerData(split='train', imSize = imSize, META_NAME='metadata_%s' % meta,DATASET_PATH=DATASET_PATH,METADATA_PATH=DATASET_PATH)
    dataVal   = ITrackerData(split='test', imSize = imSize, META_NAME='metadata_%s' % meta, DATASET_PATH=DATASET_PATH,METADATA_PATH=DATASET_PATH)
   
    train_loader = torch.utils.data.DataLoader(
        dataTrain,
        batch_size=batch_size, shuffle=True,
        num_workers=workers, pin_memory=True)

    val_loader = torch.utils.data.DataLoader(
        dataVal,
        batch_size=batch_size, shuffle=False,
        num_workers=workers, pin_memory=True)


    criterion = nn.MSELoss().cuda()

    optimizer = torch.optim.SGD(model.parameters(), lr,
                                momentum=momentum,
                                weight_decay=weight_decay)

    # Quick test
        
    if doTest:
        validate(val_loader, model, criterion, epoch)
        return

    for epoch in range(0, epoch):
        adjust_learning_rate(optimizer, epoch)
        
    for epoch in range(epoch, epochs):
        adjust_learning_rate(optimizer, epoch)
        
        # train for one epoch
        train(train_loader, model, criterion, optimizer, epoch)

        # evaluate on validation set
        prec1 = validate(val_loader, model, criterion, epoch)

        # remember best prec@1 and save checkpoint
        is_best = prec1 < best_prec1
        best_prec1 = min(prec1, best_prec1)

        save_checkpoint({
            'epoch': epoch + 1,
            'state_dict': model.state_dict(),
            'best_prec1': best_prec1,
        }, is_best,'checkpoint_%s.pth.tar' % anal)


def write2(filename,option,writeThis):
    testLossF = open(filename,option)
    testLossF.write(writeThis)
    testLossF.flush()
    testLossF.close()

def train(train_loader, model, criterion,optimizer, epoch):
    global count
    batch_time = AverageMeter()
    data_time = AverageMeter()
    losses = AverageMeter()

    # switch to train mode
    model.train()

    end = time.time()

    for i, (row, imFace, imEyeL, imEyeR, faceGrid, gaze) in enumerate(train_loader):
        
        # measure data loading time
        data_time.update(time.time() - end)
        imFace = imFace.cuda(async=True)
        imEyeL = imEyeL.cuda(async=True)
        imEyeR = imEyeR.cuda(async=True)
        faceGrid = faceGrid.cuda(async=True)
        gaze = gaze.cuda(async=True)
        
        imFace = torch.autograd.Variable(imFace)
        imEyeL = torch.autograd.Variable(imEyeL)
        imEyeR = torch.autograd.Variable(imEyeR)
        faceGrid = torch.autograd.Variable(faceGrid)
        gaze = torch.autograd.Variable(gaze)

        # compute output
        output = model(imFace, imEyeL, imEyeR, faceGrid)

        loss = criterion(output, gaze)
        
        losses.update(loss.data[0], imFace.size(0))

        # compute gradient and do SGD step
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        # measure elapsed time
        batch_time.update(time.time() - end)
        end = time.time()



        if count % 1000 == 0: 

            print('Epoch (train): [{0}][{1}/{2}]\t'
                  'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
                  'Data {data_time.val:.3f} ({data_time.avg:.3f})\t'
                  'Loss {loss.val:.4f} ({loss.avg:.4f})\t'.format(
                   epoch, i, len(train_loader), batch_time=batch_time,
                   data_time=data_time, loss=losses))

            writeThis='Epoch (train): [{0}][{1}/{2}]\t' \
                'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t' \
                'Data {data_time.val:.3f} ({data_time.avg:.3f})\t' \
                'Loss {loss.val:.4f} ({loss.avg:.4f})\n'.format(
                    epoch, i, len(train_loader), batch_time=batch_time,
                    data_time=data_time, loss=losses)
            write2(train_txt,"a",writeThis)

        count=count+1
def validate(val_loader, model, criterion, epoch):
    global count_test
    batch_time = AverageMeter()
    data_time = AverageMeter()
    losses = AverageMeter()
    lossesLin = AverageMeter()

    # switch to evaluate mode
    model.eval()
    end = time.time()


    oIndex = 0
    for i, (row, imFace, imEyeL, imEyeR, faceGrid, gaze) in enumerate(val_loader):
        # measure data loading time
        data_time.update(time.time() - end)
        imFace = imFace.cuda(async=True)
        imEyeL = imEyeL.cuda(async=True)
        imEyeR = imEyeR.cuda(async=True)
        faceGrid = faceGrid.cuda(async=True)
        gaze = gaze.cuda(async=True)
        
        imFace = torch.autograd.Variable(imFace, volatile = True)
        imEyeL = torch.autograd.Variable(imEyeL, volatile = True)
        imEyeR = torch.autograd.Variable(imEyeR, volatile = True)
        faceGrid = torch.autograd.Variable(faceGrid, volatile = True)
        gaze = torch.autograd.Variable(gaze, volatile = True)

        # compute outputx
        output = model(imFace, imEyeL, imEyeR, faceGrid)

        loss = criterion(output, gaze)
        
        lossLin = output - gaze
        lossLin = torch.mul(lossLin,lossLin)
        lossLin = torch.sum(lossLin,1)
        lossLin = torch.mean(torch.sqrt(lossLin))

        losses.update(loss.data[0], imFace.size(0))
        lossesLin.update(lossLin.data[0], imFace.size(0))
     
        # compute gradient and do SGD step
        # measure elapsed time
        batch_time.update(time.time() - end)
        end = time.time()


        print('Epoch (val): [{0}][{1}/{2}]\t'
                  'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
                  'Loss {loss.val:.4f} ({loss.avg:.4f})\t'
                  'Error L2 {lossLin.val:.4f} ({lossLin.avg:.4f})\t'.format(
                    epoch, i, len(val_loader), batch_time=batch_time,
                   loss=losses,lossLin=lossesLin))
        writeThis='Epoch (val): [{0}][{1}/{2}]\t' \
            'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t' \
            'Loss {loss.val:.4f} ({loss.avg:.4f})\t' \
            'Error L2 {lossLin.val:.4f} ({lossLin.avg:.4f})\n'.format(
             epoch, i, len(val_loader), batch_time=batch_time,
             loss=losses,lossLin=lossesLin)
            
        write2(valid_txt,"a",writeThis)

    return lossesLin.avg



def load_checkpoint(filename):
    filename = os.path.join(CHECKPOINTS_PATH, filename)
    print(filename)
    if not os.path.isfile(filename):
        return None
    state = torch.load(filename)
    return state

def save_checkpoint(state, is_best, filename):
    if not os.path.isdir(CHECKPOINTS_PATH):
        os.makedirs(CHECKPOINTS_PATH, 0o777)
    bestFilename = os.path.join(CHECKPOINTS_PATH, 'best_' + filename)
    filename = os.path.join(CHECKPOINTS_PATH, filename)
    torch.save(state, filename)
    if is_best:
        shutil.copyfile(filename, bestFilename)


class AverageMeter(object):
    """Computes and stores the average and current value"""
    def __init__(self):
        self.reset()

    def reset(self):
        self.val = 0
        self.avg = 0
        self.sum = 0
        self.count = 0

    def update(self, val, n=1):
        self.val = val
        self.sum += val * n
        self.count += n
        self.avg = self.sum / self.count


def adjust_learning_rate(optimizer, epoch):
    """Sets the learning rate to the initial LR decayed by 10 every 30 epochs"""
    lr = base_lr * (0.1 ** (epoch // 5))
    for param_group in optimizer.state_dict()['param_groups']:
        param_group['lr'] = lr


if __name__ == "__main__":
    #Set a default path to research
    parser = argparse.ArgumentParser(description='Training Script')
    
    parser.add_argument('-m','--meta',help='Load Metadata')    
    parser.add_argument('-c','--check',help='Load Checkpoint')
    parser.add_argument('-a','--anal',help='Model Name')


    args = parser.parse_args()
    main(args.meta,args.check,args.anal)
    print('DONE')
