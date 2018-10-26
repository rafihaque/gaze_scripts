#This program detects and returns bounding boxes for face frames and eyes
# import the necessary packages
from imutils import face_utils
import numpy as np
import argparse
import imutils
import dlib
import cv2
from skimage import io
from scipy.spatial import distance as dist
import sys
import json
import scipy.io as sio
from os import listdir
from os.path import join, isdir, isfile
import pdb

# construct the argument parser and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("subj_dir", type=str, help="Subject Directory")
ap.add_argument("tool_dir", type=str, help="Face Landmark Model")
ap.add_argument("anal", type=str, help="Face Landmark Model")
args = ap.parse_args()
subj_dir = args.subj_dir
tool_dir = args.tool_dir
anal = args.anal

# initialize dlib's face detector (HOG-based) and then create
# the facial landmark predictor
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(join(tool_dir,"shape_predictor_68_face_landmarks.dat"))
 
# define two constants, one for the eye aspect ratio to indicate
# blink and then a second constant for the number of consecutive
# frames the eye must be below the threshold
EYE_AR_THRESH = 0.1
EYE_AR_CONSEC_FRAMES = 2
 
# initialize the frame counters and the total number of blinks
COUNTER = 0
FaceDict = {"X":[],"Y":[],"H":[],"W":[],"IsValid":[]}
LeftEyeDict = {"X":[],"Y":[],"H":[],"W":[],"IsValid":[]}
RightEyeDict = {"X":[],"Y":[],"H":[],"W":[],"IsValid":[]}


#Define a function to get face bounding boxes, given a dlib face:
#https://www.pyimagesearch.com/2017/04/03/facial-landmarks-dlib-opencv-python/
def rect_to_bb(rect):
	# take a bounding predicted by dlib and convert it
	# to the format (x, y, w, h) as we would normally do
	# with OpenCV
	x = rect.left()
	y = rect.top()
	w = rect.right() - x
	h = rect.bottom() - y
 
	# return a tuple of (x, y, w, h)
	return (x, y, w, h)
#Define a function to detect blinks given eye inputs:
#https://www.pyimagesearch.com/2017/04/24/eye-blink-detection-opencv-python-dlib/
def eye_aspect_ratio(eye):
	# compute the euclidean distances between the two sets of
	# vertical eye landmarks (x, y)-coordinates
	A = dist.euclidean(eye[1], eye[5])
	B = dist.euclidean(eye[2], eye[4])

	# compute the euclidean distance between the horizontal
	# eye landmark (x, y)-coordinates
	C = dist.euclidean(eye[0], eye[3])

	# compute the eye aspect ratio
	ear = (A + B) / (2.0 * C)

	# return the eye aspect ratio
	return ear

def append_defaults(frame):
	FaceDict["X"].append(0) 
	FaceDict["Y"].append(0)
	FaceDict["W"].append(0)
	FaceDict["H"].append(0)
	FaceDict["IsValid"].append(0)


	LeftEyeDict["X"].append(0) 
	LeftEyeDict["Y"].append(0)
	LeftEyeDict["W"].append(0)
	LeftEyeDict["H"].append(0)
	LeftEyeDict["IsValid"].append(0)


	RightEyeDict["X"].append(0) 
	RightEyeDict["Y"].append(0)
	RightEyeDict["W"].append(0)
	RightEyeDict["H"].append(0)
	RightEyeDict["IsValid"].append(0)


    
# get frames
frames = listdir(join(subj_dir,'frames'))
tmpframes = [x[:-4] for x in frames]
frames = [x for _,x in sorted(zip(tmpframes,frames))]

# iterate through frames
for i,frame in enumerate(frames):
    if ".jpg" not in frame:
        continue
    else:
        # load the input image and convert it to grayscale    	
        frame_path = join(subj_dir,'frames',frame)
        image = cv2.imread(frame_path)
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
        # detect faces in the grayscale image, if no face append defaults
        rects = detector(gray, 1)
        if bool(rects) == False:
            append_defaults(frame)
            continue
            

        for (i, rect) in enumerate(rects):
            if i>0:
                continue
                    
            # determine the facial landmarks for the face region, then
            # convert the landmark (x, y)-coordinates to a NumPy array
            shape = predictor(gray, rect)
            shape = face_utils.shape_to_np(shape)
                        
            # grab the indexes of the facial landmarks for the left and
            # right eye, respectively
            (lStart, lEnd) = face_utils.FACIAL_LANDMARKS_IDXS["left_eye"]
            (rStart, rEnd) = face_utils.FACIAL_LANDMARKS_IDXS["right_eye"]
                    
            leftEye = shape[lStart:lEnd]
            rightEye = shape[rStart:rEnd]
            leftEAR = eye_aspect_ratio(leftEye)
            rightEAR = eye_aspect_ratio(rightEye)
                
            # check to see if the eye aspect ratio is below the blink
            # threshold, and if so, increment the blink frame counter
            if (leftEAR < EYE_AR_THRESH) | (rightEAR < EYE_AR_THRESH):
                COUNTER += 1
                
            # otherwise, the eye aspect ratio is not below the blink
            # threshold
            # if the eyes were closed for a sufficient number of
            # then increment the total number of blinks
            if COUNTER >= EYE_AR_CONSEC_FRAMES:			 
                # reset the eye frame counter
                append_defaults(frame)
                COUNTER = 0
                break							

            # append face 
            (fx, fy, fw, fh) = face_utils.rect_to_bb(rect)
            FaceDict["X"].append(fx) 
            FaceDict["Y"].append(fy)
            FaceDict["W"].append(fw)
            FaceDict["H"].append(fh)
            FaceDict["IsValid"].append(1)
            
            # append right eye 
            (x, y, w, h) = cv2.boundingRect(np.array([shape[rStart:rEnd]]))
            x = x-fx
            y = y-fy
            RightEyeDict["X"].append((x-(w/2))) 
            RightEyeDict["Y"].append((y-(w/2)-(w/4)))
            RightEyeDict["W"].append(2*w)
            RightEyeDict["H"].append(2*w)
            RightEyeDict["IsValid"].append(1)
        
            # append left eye
            (x, y, w, h) = cv2.boundingRect(np.array([shape[lStart:lEnd]]))
            x = x-fx
            y = y-fy
            LeftEyeDict["X"].append((x-(w/2))) 
            LeftEyeDict["Y"].append((y-(w/2)-(w/4)))
            LeftEyeDict["W"].append(2*w)
            LeftEyeDict["H"].append(2*w)
            LeftEyeDict["IsValid"].append(1)
            



print("SUMMARY: {}".format(len(frames)))
print("FRAMES: {}".format(len(frames)))
print("FACE: {}".format(len(FaceDict["X"])))
print("LEYE: {}".format(len(LeftEyeDict["X"])))
print("REYE: {}".format(len(RightEyeDict["X"])))
print("VALID:{}".format(sum(RightEyeDict["IsValid"])))


with open(join(subj_dir,'frames_%s.json' % anal), 'w') as outfile:
    json.dump(frames, outfile, indent = 4, ensure_ascii = False)

with open(join(subj_dir,'appleFace_%s.json' % anal), 'w') as outfile:
    json.dump(FaceDict, outfile, sort_keys = True, indent = 4,
               ensure_ascii = False)
with open(join(subj_dir,'appleRightEye_%s.json' % anal), 'w') as outfile:
    json.dump(RightEyeDict, outfile, sort_keys = True, indent = 4,
               ensure_ascii = False)
with open(join(subj_dir,'appleLeftEye_%s.json' % anal), 'w') as outfile:
    json.dump(LeftEyeDict, outfile, sort_keys = True, indent = 4,
              ensure_ascii = False)

