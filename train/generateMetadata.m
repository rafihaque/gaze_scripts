function generateMetadata(raw,anal)

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

for i = 1:length(subjs)
  subj_info = fullfile(raw,subjs{i},sprintf('subj_info_%s.mat',anal));
  fprintf('SUBJ: %s \n',subjs{i})
  if exist(subj_info,'file')
    load(subj_info)
    allSubjs = [allSubjs; s];

    % get all xCam, yCam, grid, 
    labelDotXCam  = [s.dot.xCam]';
    labelDotYCam  = [s.dot.yCam]';
    labelFaceGrid = [s.grid]';
    labelSubj     = [s.subj]';
    labelFrames   = [s.frames]';
    labelValid    = vertcat(s.appleFace.IsValid) & vertcat(s.appleLeftEye.IsValid) & vertcat(s.appleRightEye.IsValid);

    % apply filters use signal cleaning here if necessary
    labelDotXCam  = labelDotXCam(labelValid==1);
    labelDotYCam  = labelDotYCam(labelValid==1);
    labelFaceGrid = labelFaceGrid(labelValid==1,:);
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
    
    save(fullfile(raw,subjs{i},sprintf('metadata_%s.mat',anal)),'labelDotXCam','labelDotYCam','labelFaceGrid','labelSubj','labelFrames','labelTrain','labelVal','labelTest')

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



save(fullfile(raw,sprintf('metadata_%s.mat',anal)),'labelDotXCam','labelDotYCam','labelFaceGrid','labelSubj','labelFrames','labelTrain','labelVal','labelTest')

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






  % label
  
  % recNum1 = str2num(subjs{i});
  
  % rFrames = length(s.frames);
  
  % f = [s.appleFace];
  % l = [s.appleLeftEye];
  % r = [s.appleRightEye];
  
  
  % sum1 = sum([f.IsValid]'&vertcat(l.isValid)&vertcat(r.isValid));
  % % sum2 = sum(labelRecNum==recNum1);
  % % if sum1~=sum2;
  % %   keyboard
  % % end
  % counter1 = counter1+sum1;
  % %counter2 = counter2+sum2;
  % %if counter1~=counter2
  %  % keyboard
  %   %end
  % %length(rFrames([f.IsValid]'&vertcat(l.isValid)&vertcat(r.isValid)))
  % %length(frameIndex(labelRecNum==recNum1))


