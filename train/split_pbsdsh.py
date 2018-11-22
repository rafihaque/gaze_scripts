#This script reads $PBS_VNODENUM variables and splits job up
import os
from numpy import linspace
from math import floor
from forward import main
import multiprocessing as mp

def test(meta,check,anal,subj):
    print('TEST:',meta,check,anal,subj)
    return

def main():
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

    pool = mp.Pool(processes=10)

    results=[pool.apply_async(main, args=('CV','MIT_B16','CV',sub)) for sub in doList]

    #pool.wait(timeout=10)
    #parpool these subjects
    #main(meta='CV',check='MIT_B16',anal='CV',subj=)

if __name__ == "__main__":
    main()
