% generateCgenerateCropsrops.m
% This script generates all of the image crops required to train iTracker.
% It will create three subdirectories in each subject directory:
% "appleFace," "appleLeftEye," and "appleRightEye."
% mcc2 -R -singleCompThread -R -nojvm -mv generateCrops.m
function generateCrops(subj,anal)

if ~exist(subj, 'dir')
    error(['The specified base directory does not exist. Please edit ' ...
           'the script to specify the subjPath.']);
end

% create directories 
s = loadSubject(subj,anal);
save(fullfile(subj,sprintf('subj_info_%s.mat',anal)),'s')

appleFaceDir     = fullfile(subj, sprintf('appleFace_%s',anal));
appleLeftEyeDir  = fullfile(subj, sprintf('appleLeftEye_%s',anal));
appleRightEyeDir = fullfile(subj, sprintf('appleRightEye_%s',anal));
appleGridDir     = fullfile(subj, sprintf('appleGrid_%s',anal));
mkdir(appleGridDir);
mkdir(appleFaceDir);
mkdir(appleLeftEyeDir);
mkdir(appleRightEyeDir);

% loop through frames
all_grid = nan(4,length(s.frames),'single');
for i = 1:length(s.frames)
  fprintf('FRAME: %s \n',s.frames{i})
  if isnan(s.appleFace.x(i)) || isnan(s.appleLeftEye.x(i)) || isnan(s.appleRightEye.x(i))
    continue;
  end
  frame = imread(fullfile(subj, 'frames', s.frames{i}));
  
  % generate grid (Make sur
  shortEdge = 480; longEdge  = 640; gridSize = 25;
  modifiedLabelFaceX = s.appleFace.x(i);
  modifiedLabelFaceY = s.appleFace.y(i);
  % portrait
  if s.screen.orientation(i)==1 | s.screen.orientation(i)==2
      modifiedLabelFaceX = modifiedLabelFaceX+(longEdge - shortEdge) / 2;
  elseif s.screen.orientation(i)==3 | s.screen.orientation(i)==4
      modifiedLabelFaceY = modifiedLabelFaceY+(longEdge - shortEdge) / 2;
  end
  grid = faceGridFromFaceRect(longEdge, longEdge, gridSize, gridSize, ...
			      modifiedLabelFaceX, modifiedLabelFaceY, s.appleFace.w(i), s.appleFace.h(i), false);
  grid = reshape(grid,[625 1 1]);
  %m=matfile(fullfile(appleGridDir,strrep(s.frames{i},'.jpg','.mat')),'writable',true);
  %m.grid=grid;
  save(fullfile(appleGridDir,strrep(s.frames{i},'.jpg','.mat')),'grid')
  
  % generate crops
  faceImage = cropRepeatingEdge(frame, round([s.appleFace.x(i) s.appleFace.y(i) s.appleFace.w(i) s.appleFace.h(i)]));
  leftEyeImage = cropRepeatingEdge(faceImage, round([s.appleLeftEye.x(i) s.appleLeftEye.y(i) s.appleLeftEye.w(i) s.appleLeftEye.h(i)]));
  rightEyeImage = cropRepeatingEdge(faceImage, round([s.appleRightEye.x(i) s.appleRightEye.y(i) s.appleRightEye.w(i) s.appleRightEye.h(i)]));
  
  
  imwrite(faceImage, fullfile(appleFaceDir, s.frames{i}))
  imwrite(leftEyeImage, fullfile(appleLeftEyeDir, s.frames{i}));
  imwrite(rightEyeImage, fullfile(appleRightEyeDir, s.frames{i}));
end
%s.grid = all_grid;
save(fullfile(subj,sprintf('subj_info_%s.mat',anal)),'s')
