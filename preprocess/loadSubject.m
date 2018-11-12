% loadSubject.m
%
% This loads subject data into a struct given a path to a subject
% directory. This requires the MATLAB gason wrapper to read JSON files. You
% can get it from https://github.com/pdollar/coco/tree/master/MatlabAPI.

function output = loadSubject(path,crop)
% Apple Face Detections


if strcmp(crop,'MIT')
  input=jsondecode(fscanf(fopen(fullfile(path,'appleFace.json'),'r'),'%c'));
else
  input=jsondecode(fscanf(fopen(fullfile(path,sprintf('appleFace_%s.json',crop)),'r'),'%c'));
end
output.appleFace.x = input.X;
output.appleFace.x(~input.IsValid) = NaN;
output.appleFace.y = input.Y;
output.appleFace.y(~input.IsValid) = NaN;
output.appleFace.w = input.W;
output.appleFace.w(~input.IsValid) = NaN;
output.appleFace.h = input.H;
output.appleFace.h(~input.IsValid) = NaN;
output.appleFace.IsValid = input.IsValid;

% Apple Left Eye Detections


if strcmp(crop,'MIT')
  input=jsondecode(fscanf(fopen(fullfile(path,'appleLeftEye.json'),'r'),'%c'))
else
  input=jsondecode(fscanf(fopen(fullfile(path,sprintf('appleLeftEye_%s.json',crop)),'r'),'%c'));
end
output.appleLeftEye.x = input.X;
output.appleLeftEye.x(~input.IsValid) = NaN;
output.appleLeftEye.y = input.Y;
output.appleLeftEye.y(~input.IsValid) = NaN;
output.appleLeftEye.w = input.W;
output.appleLeftEye.w(~input.IsValid) = NaN;
output.appleLeftEye.h = input.H;
output.appleLeftEye.h(~input.IsValid) = NaN;
output.appleLeftEye.IsValid = input.IsValid;

% Apple Right Eye Detections
if strcmp(crop,'MIT')
  input=jsondecode(fscanf(fopen(fullfile(path,'appleRightEye.json'),'r'),'%c'))
else
  input=jsondecode(fscanf(fopen(fullfile(path,sprintf('appleRightEye_%s.json',crop)),'r'),'%c'));
end
output.appleRightEye.x = input.X;
output.appleRightEye.x(~input.IsValid) = NaN;
output.appleRightEye.y = input.Y;
output.appleRightEye.y(~input.IsValid) = NaN;
output.appleRightEye.w = input.W;
output.appleRightEye.w(~input.IsValid) = NaN;
output.appleRightEye.h = input.H;
output.appleRightEye.h(~input.IsValid) = NaN;
output.appleRightEye.IsValid = input.IsValid;


if ~contains(path,'FaceFrames')
  % Dot Information
  input=jsondecode(fscanf(fopen(fullfile(path,'dotInfo.json'),'r'),'%c'));
  output.dot.xPts = input.XPts';
  output.dot.yPts = input.YPts';
  output.dot.xCam = input.XCam';
  output.dot.yCam = input.YCam';
  numFrames = length(output.appleFace.IsValid);
  taskLabels{1,numFrames}=[];
  output.taskLabels = taskLabels;

else

  % load image and calibration info
  imInfo=dir([path '/*ImageInfo.json']);
  input=jsondecode(fscanf(fopen(fullfile(imInfo.folder, imInfo.name),'r'),'%c'));
  calInfo=dir([path '/*CalibrationInfo.json']);
  calInfo=jsondecode(fscanf(fopen(fullfile(calInfo.folder, calInfo.name),'r'),'%c'));
  taskInfo = dir([path  '/*TaskImageInfo.json']);
  taskInfo=jsondecode(fscanf(fopen(fullfile(taskInfo.folder, taskInfo.name),'r'),'%c'));
  
 
  % reconstruct dot array
  allDotsCalPts = nan(sum(calInfo.faceFramePerDot),2,'single');
  c = 0;
  for i=1:length(calInfo.faceFramePerDot)  
    numCalPts = calInfo.faceFramePerDot(i);
    allDotsCalPts(c+1:c+numCalPts,1) = calInfo.trueX(i);
    allDotsCalPts(c+1:c+numCalPts,2) = calInfo.trueY(i);
    c = c+numCalPts

  end
  allDotsCalPts=allDotsCalPts+17.5;  

  % convert screen to cam
  numFrames = length(output.appleFace.IsValid);
  calStrt   = calInfo.instructionsFrameCount+1;
  calFin    = calStrt+sum(calInfo.faceFramePerDot)-1;
  lenCal    = length(calStrt:calFin);

  % convert screen to cam
  % MAKE SURE TO CHANGE FOR DIFFERENCE DEVICES %
  
  
  allDotsPts=nan(numFrames,2,'single');
  screenw = ones(lenCal,1)*728;
  screenh = ones(lenCal,1)*1024;
  orient = ones(lenCal,1);
  device = cell(lenCal, 1); 
  device(:) = {'iPad Air 2'};
  [allDotsPts(calStrt:calFin,1),allDotsPts(calStrt:calFin,2)] = screen2cam(allDotsCalPts(:,1),allDotsCalPts(:,2),...
						  orient,device,screenw,screenh,false);
  
  %% MAKE SURE TO CHANGE FOR DIFFERENT DEVICES % 
  allDotsCM = allDotsPts/50;
  
  %Store the data
  output.dot.xPts = allDotsPts(:,1)';
  output.dot.yPts = allDotsPts(:,2)';
  output.dot.xCam = allDotsCM(:,1)';
  output.dot.yCam = allDotsCM(:,2)';
  
  taskLabels{1,numFrames}=[];
  c = calInfo.calibrationFrameCount;
  for i = 1:length(taskInfo.ImageLabels)
    numTaskPts = taskInfo.FramesPerImage(i);
    taskLabels(c+1:c+numTaskPts) = taskInfo.ImageLabels(i);
    c = c+numTaskPts;

  end
 
  output.taskLabels = taskLabels;
end

% Frames
if strcmp(crop,'MIT')
  input=jsondecode(fscanf(fopen(fullfile(path,'frames.json'),'r'),'%c'));
  output.frames = input';
else
  input=jsondecode(fscanf(fopen(fullfile(path,sprintf('frames_%s.json',crop)),'r'),'%c'));
  output.frames = input';
end


% Info
input=jsondecode(fscanf(fopen(fullfile(path,'info.json'),'r'),'%c'));
output.info.totalFrames = input.TotalFrames;
output.info.numFaceDetections = input.NumFaceDetections;
output.info.numEyeDetections = input.NumEyeDetections;
output.info.dataset = input.Dataset;
output.info.deviceName = input.DeviceName;

% Screen
input=jsondecode(fscanf(fopen(fullfile(path,'screen.json'),'r'),'%c'));
if ~contains(path,'FaceFrames')
  output.screen.w = input.W;
  output.screen.h = input.H;
  output.screen.orientation = input.Orientation;
else
  output.screen.w = screenw;
  output.screen.h = screenh;
  output.screen.orientation = orient;
end

% Subj
[~,ext] = fileparts(path);
output.subj = repmat({ext},1,length(output.frames));



