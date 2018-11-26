#This script reads $PBS_VNODENUM variables and splits job up
import os
from numpy import linspace
from math import floor
import forward
import multiprocessing as mp

def test(meta,check,anal,subj):
    print('TEST:',meta,check,anal,subj)
    return

def ppool():
    #Grab parallel num
    PBS_VNODENUM=int(os.environ["PBS_VNODENUM"])

    #Get list of subjs
    rawDataPath="/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/"
    anal='CV'

    subList=[]
    for sub in os.listdir(rawDataPath):
        if ("FaceFrames" in sub) and ("zip" not in sub):
            if os.path.exists(os.path.join(rawDataPath,sub,'metadata_'+anal+'.mat')):
                subList.append(sub)

    subList.sort()

    #for every 10
    intervals=[int(floor(x)) for x in linspace(0,len(subList),11)]
    print('intervals',intervals)
    print('PBS_VNODENU:',PBS_VNODENUM)
    print('intervals[PBS_VNODENUm]',intervals[PBS_VNODENUM])
    print('subList(splice)',subList[intervals[PBS_VNODENUM]:intervals[PBS_VNODENUM+1]])

    doList=subList[intervals[PBS_VNODENUM]:intervals[PBS_VNODENUM+1]]

    pool = mp.pool.ThreadPool(processes=5)
    argSets=[["-s",sub,"-m","CV","-c","MIT_B16","-a","CV"] for sub in doList]
    #print(argSets)
    results=pool.map(forward.main1,argSets)


if __name__ == "__main__":
    ppool()
