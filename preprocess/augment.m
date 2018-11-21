% wiggle.m
% Given a data folder, augment each subject so they have new data folders.
% Augmentation happens by modifying the eye detections in five different
% directions.

function augment(metadataPath, anal)
if nargin <1
    anal='CV'
    metadataPath=['/home/apongos/gaze_scripts/preprocess/metadata_' anal '.mat'];
    analOut='x25';
end
imageDir='/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/';
saveDir='/home/apongos/gaze_scripts/preprocess/';
outputDir=imageDir;
gridSize = 25;
includeGrids = true; %May cause memory issues

%% Setup
rng('shuffle');
%if parpool('size') == 0
%  parpool open;
%end
old = load(metadataPath);
%if ~exist(outputDir, 'dir')
%  mkdir(outputDir);
%end
% Create image directories.
uniqueRecs = unique(old.labelSubj);
for recNum = uniqueRecs'
  recNumStr = recNum{1}; %sprintf('%.5d', recNum);
  frameDir = [outputDir recNumStr '/frames/'];
  faceDir = [outputDir recNumStr '/appleFace_25/'];
  leftEyeDir = [outputDir recNumStr '/appleLeftEye_25/'];
  rightEyeDir = [outputDir recNumStr '/appleRightEye_25/'];
  gridDir = [outputDir recNumStr '/appleGrid_25/'];
%   if ~exist(frameDir, 'dir')
%     mkdir(frameDir);
%   end
  if ~exist(faceDir, 'dir')
    mkdir(faceDir);
  end
  if ~exist(leftEyeDir, 'dir')
    mkdir(leftEyeDir);
  end
  if ~exist(rightEyeDir, 'dir')
    mkdir(rightEyeDir);
  end
  if ~exist(gridDir, 'dir')
    mkdir(gridDir);
  end
end

% Create new label vectors. The rest will be copied using labelAugmentationIdx
% later. These are actually cell arrays to be used in the parfor, but will be
% cell2mat'd later.
oldSize = length(old.labelSubj);
labelAugmentationIdx = cell(oldSize, 1);  % Augmented references to pre-augmentation indices.
labelLeftEyeX = cell(oldSize, 1);
labelLeftEyeY = cell(oldSize, 1);
labelLeftFilename = cell(oldSize, 1);
labelRightEyeX = cell(oldSize, 1);
labelRightEyeY = cell(oldSize, 1);
labelRightFilename = cell(oldSize, 1);
labelFaceX = cell(oldSize, 1);
labelFaceY = cell(oldSize, 1);
labelFaceFilename = cell(oldSize, 1);
labelFrameFilename = cell(oldSize, 1);
idx1_5 = cell(oldSize,1);

tmpFrames=old.labelFrames;
validNums=cellfun(@(c)strrep(c,'.jpg',''),tmpFrames,'uni',false);
validFramesJpg=tmpFrames;

%noNan=logical(vertcat(old.appleFace.IsValid) & vertcat(old.appleLeftEye.IsValid) & vertcat(old.appleRightEye.IsValid));
% Create copies of old data vectors so the entire old struct doesn't need to be
% copied to all workers.
%oldValidFramesJpg=validNums(:);
oldLabelFrameFilename = strcat(old.labelSubj(:),'/frames/',validFramesJpg(:));
oldLabelFaceFilename = strcat(old.labelSubj(:),['/appleFace_' anal '/'],validFramesJpg(:));
oldLabelFaceX = old.appleFaceX;
oldLabelFaceY = old.appleFaceY;
oldLabelFaceW = old.appleFaceW;
oldLabelFaceH = old.appleFaceH;
oldLabelLeftEyeX = old.appleLeftEyeX;
oldLabelLeftEyeY = old.appleLeftEyeY;
oldLabelLeftEyeW = old.appleLeftEyeW;
oldLabelLeftEyeH = old.appleLeftEyeH;
oldLabelLeftFilename = strcat(old.labelSubj(:),['/appleLeftEye_' anal '/'],validFramesJpg(:));
oldLabelRightEyeX = old.appleRightEyeX;
oldLabelRightEyeY = old.appleRightEyeY;
oldLabelRightEyeW = old.appleRightEyeW;
oldLabelRightEyeH = old.appleRightEyeH;
oldLabelRightFilename = strcat(old.labelSubj(:),['/appleRightEye_' anal '/'],validFramesJpg(:));

%Remove nans
%oldLabelFaceX=oldLabelFaceX(noNan);
%oldLabelFaceY=oldLabelFaceY(noNan);
%oldLabelFaceW=oldLabelFaceW(noNan);
%oldLabelFaceH=oldLabelFaceH(noNan);
%oldLabelLeftEyeX=oldLabelLeftEyeX(noNan);
%oldLabelLeftEyeY=oldLabelLeftEyeY(noNan);
%oldLabelLeftEyeW=oldLabelLeftEyeW(noNan);
%oldLabelLeftEyeH=oldLabelLeftEyeH(noNan);
%oldLabelRightEyeX=oldLabelRightEyeX(noNan);
%oldLabelRightEyeY=oldLabelRightEyeY(noNan);
%oldLabelRightEyeW=oldLabelRightEyeW(noNan);
%oldLabelRightEyeH=oldLabelRightEyeH(noNan);


%% Run
for i = 1:oldSize  % All old samples.
  % Configure all possible faces/eyes in the following order:
  % original, N, E, W, S.
  faceDiff = 640 / 25;
  newFaceX = [oldLabelFaceX(i);
              oldLabelFaceX(i);
              oldLabelFaceX(i) + faceDiff;
              oldLabelFaceX(i) - faceDiff;
              oldLabelFaceX(i)];
  newFaceY = [oldLabelFaceY(i);
              oldLabelFaceY(i) - faceDiff;
              oldLabelFaceY(i);
              oldLabelFaceY(i);
              oldLabelFaceY(i) + faceDiff];
  % No clamping, since we repeat edge pixels for face detections.

  % This assumes faces are square and that the facegrid is 25x25.
  faceSize = oldLabelFaceW(i);
  eyeDiff = faceSize / gridSize;  % How much to wiggle. Try to shift one grid unit.
  % Create four variations of eye detections (and the original).
  newLeftX = [oldLabelLeftEyeX(i);
              oldLabelLeftEyeX(i);
              oldLabelLeftEyeX(i) + eyeDiff;
              oldLabelLeftEyeX(i) - eyeDiff;
              oldLabelLeftEyeX(i)];
  newLeftY = [oldLabelLeftEyeY(i);
              oldLabelLeftEyeY(i) - eyeDiff;
              oldLabelLeftEyeY(i);
              oldLabelLeftEyeY(i);
              oldLabelLeftEyeY(i) + eyeDiff];
  newRightX = [oldLabelRightEyeX(i);
               oldLabelRightEyeX(i);
               oldLabelRightEyeX(i) + eyeDiff;
               oldLabelRightEyeX(i) - eyeDiff;
               oldLabelRightEyeX(i)];
  newRightY = [oldLabelRightEyeY(i);
               oldLabelRightEyeY(i) - eyeDiff;
               oldLabelRightEyeY(i);
               oldLabelRightEyeY(i);
               oldLabelRightEyeY(i) + eyeDiff];
  % Clamp the eye values just in case they go outside of the face box. Assume
  % left and right eyes are the same width. No repeated edge pixels here because
  % eyes should never be detected outside of the face box.
  newLeftX = max(0, min(faceSize - oldLabelLeftEyeW(i), newLeftX));
  newLeftY = max(0, min(faceSize - oldLabelLeftEyeH(i), newLeftY));
  newRightX = max(0, min(faceSize - oldLabelRightEyeW(i), newRightX));
  newRightY = max(0, min(faceSize - oldLabelRightEyeH(i), newRightY));

  % Create new filenames.
  newFacePrefix = oldLabelFaceFilename{i};
  newValidPrefix = validNums{i};
  newFacePrefix = strrep(newFacePrefix, 'appleFace_x25', 'face');
  newFacePrefix = newFacePrefix(1:end-4);  % Cut off .jpg.
  newFaceFilename = {[newFacePrefix '_0.jpg'];
                     [newFacePrefix '_1.jpg'];
                     [newFacePrefix '_2.jpg'];
                     [newFacePrefix '_3.jpg'];
                     [newFacePrefix '_4.jpg']};
  newLeftPrefix = oldLabelLeftFilename{i};
  newLeftPrefix = strrep(newLeftPrefix, 'appleLeftEye_x25', 'leftEye');
  newLeftPrefix = newLeftPrefix(1:end-4);  % Cut off .jpg.
  newLeftFilename = {[newLeftPrefix '_0.jpg'];
                     [newLeftPrefix '_1.jpg'];
                     [newLeftPrefix '_2.jpg'];
                     [newLeftPrefix '_3.jpg'];
                     [newLeftPrefix '_4.jpg']};
  newRightPrefix = oldLabelRightFilename{i};
  newRightPrefix = strrep(newRightPrefix, 'appleRightEye_x25', 'rightEye');
  newRightPrefix = newRightPrefix(1:end-4);  % Cut off .jpg.
  newRightFilename = {[newRightPrefix '_0.jpg'];
                      [newRightPrefix '_1.jpg'];
                      [newRightPrefix '_2.jpg'];
                      [newRightPrefix '_3.jpg'];
                      [newRightPrefix '_4.jpg']};
                  
    new1_5idx = {[newValidPrefix '_0']; 
                         [newValidPrefix '_1'];
                         [newValidPrefix '_2'];
                         [newValidPrefix '_3'];
                         [newValidPrefix '_4']};

  % Check if the output files already exist to skip file creation.
  skipFiles = true;
  for j = 1:length(newLeftFilename)
    if ~exist([outputDir newFaceFilename{j}], 'file') || ~exist([outputDir newLeftFilename{j}], 'file') || ~exist([outputDir newRightFilename{j}], 'file')
      skipFiles = false;
      break;
    end
  end

  if ~skipFiles
     % Copy over existing files.
    %copyfile([imageDir oldLabelFrameFilename{i}], [outputDir oldLabelFrameFilename{i}]);
    copyfile([imageDir oldLabelFaceFilename{i}], [outputDir newFaceFilename{1}]);
    copyfile([imageDir oldLabelLeftFilename{i}], [outputDir newLeftFilename{1}]);
    copyfile([imageDir oldLabelRightFilename{i}], [outputDir newRightFilename{1}]);

    % Crop out new files (1 is the original).
    for j = 2:length(newLeftFilename)
      % Face crops (repeat edge pixels).
      frameImage = imread([imageDir oldLabelFrameFilename{i}]);
      newFaceImage = cropRepeatingEdge(frameImage, round([newFaceX(j), ...
        newFaceY(j), oldLabelFaceW(i), oldLabelFaceH(i)]));

      % Eye crops (already clamped, though we'll use cropRepeatingEdge anyway).
      faceImage = imread([imageDir oldLabelFaceFilename{i}]);
      newLeftEyeImage = cropRepeatingEdge(faceImage, round([newLeftX(j), ...
        newLeftY(j), oldLabelLeftEyeW(i), oldLabelLeftEyeH(i)]));
      newRightEyeImage = cropRepeatingEdge(faceImage, round([newRightX(j), ...
        newRightY(j), oldLabelRightEyeW(i), oldLabelRightEyeH(i)]));

      imwrite(newFaceImage, [outputDir newFaceFilename{j}], 'jpg', 'Quality', 90);
      imwrite(newLeftEyeImage, [outputDir newLeftFilename{j}], 'jpg', 'Quality', 90);
      imwrite(newRightEyeImage, [outputDir newRightFilename{j}], 'jpg', 'Quality', 90);
    end
  end

  % Update new metadata vectors to account for 5 face wiggles * 5 eye wiggles.
  labelAugmentationIdx{i} = repmat(i, [25, 1]);
  labelFrameFilename{i} = repmat(oldLabelFrameFilename(i), [25, 1]);
  %labelValidFramesJpg = repmat(oldLabelFrameFilename(i), [25, 1]);
  %labelValidFramesJpg{i} = repmat(oldValidFramesJpg(i), [25,1]);
  
  for j = 1:5
    % As the face detection wiggles, we still want the original eye detection to
    % remain the same, so we will offset according to the face movement.
    faceDiffX = newFaceX(j) - oldLabelFaceX(i);
    faceDiffY = newFaceY(j) - oldLabelFaceY(i);
    labelLeftEyeX{i} = [labelLeftEyeX{i}; newLeftX - faceDiffX];
    labelLeftEyeY{i} = [labelLeftEyeY{i}; newLeftY - faceDiffY];
    labelLeftFilename{i} = [labelLeftFilename{i}; newLeftFilename];
    labelRightEyeX{i} = [labelRightEyeX{i}; newRightX - faceDiffX];
    labelRightEyeY{i} = [labelRightEyeY{i}; newRightY - faceDiffY];
    labelRightFilename{i} = [labelRightFilename{i}; newRightFilename];
    labelFaceX{i} = [labelFaceX{i}; repmat(newFaceX(j), [5, 1])];
    labelFaceY{i} = [labelFaceY{i}; repmat(newFaceY(j), [5, 1])];
    labelFaceFilename{i} = [labelFaceFilename{i}; repmat(newFaceFilename(j), [5, 1])];
    idx1_5{i} = [idx1_5{i}; repmat(new1_5idx(j), [5, 1])];
  end
end
% Un-cell stuff now that parfor is done.
labelAugmentationIdx = cell2mat(labelAugmentationIdx);
labelFaceX = cell2mat(labelFaceX);
labelFaceY = cell2mat(labelFaceY);
labelFrameFilename = vertcat(labelFrameFilename{:});
labelFaceFilename = vertcat(labelFaceFilename{:});
idx1_5 = vertcat(idx1_5{:});
%preAugmentationStats = old.stats;

%labelTimestamp = old.labelTimestamp(labelAugmentationIdx);
oldDotXCam=old.labelDotXCam;
oldDotYCam=old.labelDotYCam;
oldLabelOrientation=old.screenOrientation;% oldLabelOrientation=oldLabelOrientation(noNan);
oldLabelActiveScreenW=old.screenW;% oldLabelActiveScreenW=oldLabelActiveScreenW(noNan);
oldLabelActiveScreenH=old.screenH; %oldLabelActiveScreenH=oldLabelActiveScreenH(noNan);
oldLabelTrain=old.labelTest;
oldLabelTest=old.labelTrain;
oldLabelVal=old.labelVal;
%oldLabelDeviceName=old.info.deviceName;


labelRecNum = old.labelSubj(labelAugmentationIdx);

labelDotXCam = oldDotXCam(labelAugmentationIdx);
labelDotYCam = oldDotYCam(labelAugmentationIdx);
labelFaceH = oldLabelFaceH(labelAugmentationIdx);
labelFaceW = oldLabelFaceW(labelAugmentationIdx);

labelOrientation = oldLabelOrientation(labelAugmentationIdx);
%labelDeviceName = oldLabelDeviceName(labelAugmentationIdx);
labelActiveScreenW = oldLabelActiveScreenW(labelAugmentationIdx);
labelActiveScreenH = oldLabelActiveScreenH(labelAugmentationIdx);
labelTrain = oldLabelTrain(labelAugmentationIdx);
labelVal = oldLabelVal(labelAugmentationIdx);
labelTest = oldLabelTest(labelAugmentationIdx);

clear old;  % Before generating the grids.

% Generate new stuff.

% Shuffle and save indices of train/test.
trainIdx = find(labelTrain);
trainIdx = trainIdx(randperm(length(trainIdx)));
valIdx = find(labelVal);
valIdx = valIdx(randperm(length(valIdx)));
testIdx = find(labelTest);
testIdx = testIdx(randperm(length(testIdx)));

if includeGrids
  shortEdge = 480;
  longEdge = 640;
  labelPortrait = labelOrientation == 1 | labelOrientation == 2;
  labelLandscape = labelOrientation == 3 | labelOrientation == 4;
  % Shift coordinates so that portrait and landscape frames are both centered in
  % a longEdge x longEdge frame.
  modifiedLabelFaceX = labelFaceX;
  modifiedLabelFaceY = labelFaceY;
  modifiedLabelFaceX(labelPortrait) = modifiedLabelFaceX(labelPortrait) ...
    + (longEdge - shortEdge) / 2;
  modifiedLabelFaceY(labelLandscape) = modifiedLabelFaceY(labelLandscape) ...
    + (longEdge - shortEdge) / 2;

uniqueGrid=unique(idx1_5,'rows')
for i=1:5:length(modifiedLabelFaceX) %Skip every 5 since it repeats
  grid = faceGridFromFaceRect(longEdge, longEdge, gridSize, gridSize, ...
    modifiedLabelFaceX(i), modifiedLabelFaceY(i), labelFaceW(i), labelFaceH(i), false);

    m=matfile(fullfile([outputDir labelRecNum{i} '/appleGrid_25/'],[idx1_5{i} '.mat']),'writable',true)
    m.grid=grid;
    keyboard
    %save(fullfile([outputDir labelRecNum{i} '/appleGrid_25/'],[idx1_5{i} '.mat']),'labelFaceGrid')
end

end

%[labelDotXCam, labelDotYCam] = screen2cam(labelDotXPts(:), labelDotYPts(:), labelOrientation(:), labelDeviceName(:),...
%        labelActiveScreenW(:), labelActiveScreenH(:));

    
%% Save Metadata

metadata25.labelDotXCam = labelDotXCam;
metadata25.labelDotYCam = labelDotYCam;
metadata25.labelSubj = labelRecNum;
metadata25.labelFrames = idx1_5;
metadata25.labelTrain = labelTrain;
metadata25.labelTest= labelTest;
metadata25.labelVal= labelVal;

keyboard
save([saveDir 'metadata_' analOut '.mat'], '-struct','metadata25');

keyboard

end
