function generateAugmentHelperStruct(raw,anal)

% change later
subjs = dir(raw);
subjs = {subjs.name};
subjs(1:2) =[];
allSubjs = [];
allLabelTrain = [];
allLabelTest = [];
allLabelValid  = [];
% loop through subjects
subjs = subjs(~contains(subjs,'Face'));

for i = 1:3 %length(subjs)
  subj_info = fullfile(raw,subjs{i},sprintf('subj_info_%s.mat',anal));
  fprintf('SUBJ: %s \n',subjs{i})
  if exist(subj_info,'file')
    load(subj_info)
    allSubjs = [allSubjs; s];

    % get all xCam, yCam, grid, 
    labelDotXCam  = [s.dot.xCam]';
    labelDotYCam  = [s.dot.yCam]';
    %labelFaceGrid = [s.grid]';
    labelSubj     = [s.subj]';
    labelFrames   = [s.frames]';
    labelValid    = vertcat(s.appleFace.IsValid) & vertcat(s.appleLeftEye.IsValid) & vertcat(s.appleRightEye.IsValid);

    % apply filters use signal cleaning here if necessary
    labelDotXCam  = labelDotXCam(labelValid==1);
    labelDotYCam  = labelDotYCam(labelValid==1);
    %labelFaceGrid = labelFaceGrid(labelValid==1,:);
    labelSubj     = labelSubj(labelValid==1);
    labelFrames   = labelFrames(labelValid==1);
    
    % train 
    labelTrain = false(length(labelFrames),1);
    labelVal   = false(length(labelFrames),1);
    r = randperm(length(labelFrames));
    
    numTrain  = round(length(r)*.80);
    numValid  = round((length(r)-numTrain)/2);

    labelTrain(r(1:numTrain)) = true;
    labelVal(r(numTrain+1:numTrain+numValid))=true;
    labelTest = ~(labelTrain|labelVal);
    
    % check
    if ~sum(labelTrain+labelVal+labelTest==1)==length(r);
      keyboard
    end
    
    %save(fullfile(raw,subjs{i},sprintf('metadata_%s.mat',anal)),'labelDotXCam',...
    %'labelDotYCam','labelSubj','labelFrames','labelTrain','labelVal','labelTest')

    allLabelTrain = [allLabelTrain; labelTrain];
    allLabelValid = [allLabelTest; labelVal];
    allLabelTest  = [allLabelTest; labelTest];

  end
end

allDot   = [allSubjs.dot];
allFaces = [allSubjs.appleFace];
allLEye  = [allSubjs.appleLeftEye];
allREye  = [allSubjs.appleRightEye];

% get all xCam, yCam, grid, 
labelDotXCam  = [allDot.xCam]';
labelDotYCam  = [allDot.yCam]';
%labelFaceGrid = [allSubjs.grid]';
labelSubj     = [allSubjs.subj]';
labelFrames   = [allSubjs.frames]';
labelValid    = vertcat(allFaces.IsValid) & vertcat(allLEye.IsValid) & vertcat(allREye.IsValid);

% apply filters use signal cleaning here if necessary
labelDotXCam  = labelDotXCam(labelValid==1);
labelDotYCam  = labelDotYCam(labelValid==1);
%labelFaceGrid = labelFaceGrid(labelValid==1,:);
labelSubj     = labelSubj(labelValid==1);
labelFrames   = labelFrames(labelValid==1);

labelTrain = allLabelTrain;
labelTest = allLabelTest;
labelVal = allLabelValid;

appleFace=allFaces;
appleLeftEye=allLEye;
appleRightEye=allREye;

screen=[allSubjs.screen];
screenW = vertcat(screen.w); screenW = screenW(labelValid==1);
screenH = vertcat(screen.h); screenH = screenH(labelValid==1);
screenOrientation = vertcat(screen.orientation); screenOrientation = screenOrientation(labelValid==1);


appleFaceX = vertcat(allFaces.x); appleFaceX=appleFaceX(labelValid==1);
appleFaceY = vertcat(allFaces.y); appleFaceY=appleFaceY(labelValid==1);
appleFaceW = vertcat(allFaces.w); appleFaceW=appleFaceW(labelValid==1);
appleFaceH = vertcat(allFaces.h); appleFaceH=appleFaceH(labelValid==1);

appleLeftEyeX = vertcat(allLEye.x); appleLeftEyeX=appleLeftEyeX(labelValid==1);
appleLeftEyeY = vertcat(allLEye.y); appleLeftEyeY=appleLeftEyeY(labelValid==1);
appleLeftEyeW = vertcat(allLEye.w); appleLeftEyeW=appleLeftEyeW(labelValid==1);
appleLeftEyeH = vertcat(allLEye.h); appleLeftEyeH=appleLeftEyeH(labelValid==1);

appleRightEyeX = vertcat(allREye.x); appleRightEyeX=appleRightEyeX(labelValid==1);
appleRightEyeY = vertcat(allREye.y); appleRightEyeY=appleRightEyeY(labelValid==1);
appleRightEyeW = vertcat(allREye.w); appleRightEyeW=appleRightEyeW(labelValid==1);
appleRightEyeH = vertcat(allREye.h); appleRightEyeH=appleRightEyeH(labelValid==1);


saveDir='/home/apongos/gaze_scripts/preprocess';
save(fullfile(saveDir,sprintf('metadata_%s.mat',anal)),'labelDotXCam',...
'labelDotYCam','labelSubj','labelFrames','labelTrain','labelVal','labelTest',...
'appleFaceX','appleFaceY','appleFaceW','appleFaceH',...
'appleLeftEyeX','appleLeftEyeY','appleLeftEyeW','appleLeftEyeH',...
'appleRightEyeX','appleRightEyeY','appleRightEyeW','appleRightEyeH',...
'screenW','screenH','screenOrientation')





