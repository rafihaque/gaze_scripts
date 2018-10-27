% generateCrops.m
% This script generates all of the image crops required to train iTracker.
% It will create three subdirectories in each subject directory:
% "appleFace," "appleLeftEye," and "appleRightEye."
function generateMetadata(raw,anal)

% change later
subjs = dir(raw);
subjs = {subjs.name};
subjs(1:2) =[];
allSubjs = [];
for i = 1:length(subjs)
  subj_info = fullfile(raw,subjs{i},sprintf('subj_info_%s.mat',anal))
  if exist(subj_info,'file')
    load(subj_info)
    allSubjs = [allSubjs; s];
  end
end
allDot   = [allSubjs.dot];
allFaces = [allSubjs.appleFace];
keyboard

% get all xCam, yCam, grid, 
labelDotXCam  = [allDot.xCam]';
labelDotYCam  = [allDot.yCam]';
labelFaceGrid = [allSubjs.grid]';
labelSubj     = [allSubjs.subj]';
labelFrames   = [allSubjs.frames]';
labelValid    = [allFaces.IsValid]';

% apply filters use signal cleaning here if necessary
labelDotXCam  = labelDotXCam(labelValid==1);
labelDotYCam  = labelDotYCam(labelValid==1);
labelFaceGrid = labelFaceGrid(labelValid==1,:);
labelSubj     = labelSubj(labelValid==1);
labelFrames   = labelFrames(labelValid==1);



save(fullfile(raw,sprintf('metadata_%s.mat',anal)),'labelDotXCam','labelDotYCam','labelFaceGrid','labelSubj','labelFrames')
keyboard
% % quantiy % subjects missing
% crops = 0; detect = 0;
% for i = 1:length(subjs)
%   appleFaceDetect = fullfile(raw,subjs{i},sprintf('appleFace_%s.json',anal))
%   appleFaceCrop = fullfile(raw,subjs{i},sprintf('appleFace_%s',anal))

%   if exist(appleFaceDetect,'file'); detect = detect + 1; end
%   if exist(appleFaceCrop,'dir');    crops = crops+1; end
% end

% detect/length(subjs)
% crops/length(subjs)








