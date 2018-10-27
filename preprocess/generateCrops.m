% generateCrops.m
% This script generates all of the image crops required to train iTracker.
% It will create three subdirectories in each subject directory:
% "appleFace," "appleLeftEye," and "appleRightEye."
function generateCrops(subj,anal)

if ~exist(subj, 'dir')
    error(['The specified base directory does not exist. Please edit ' ...
           'the script to specify the subjPath.']);
end

% create directories 
s = loadSubject(subj,anal);

appleFaceDir     = fullfile(subj, sprintf('appleFace_%s',anal));
appleLeftEyeDir  = fullfile(subj, sprintf('appleLeftEye_%s',anal));
appleRightEyeDir = fullfile(subj, sprintf('appleRightEye_%s',anal));
appleGridDir     = fullfile(subj, sprintf('appleGrid_%s',anal));

mkdir(appleGridDir);
mkdir(appleFaceDir);
mkdir(appleLeftEyeDir);
mkdir(appleRightEyeDir);

% loop through frames
grid = nan(4,length(s.frames),'single');
for i = 1:length(s.frames)
  fprintf('FRAME: %s \n',s.frames{i})
  if isnan(s.appleFace.x(i)) || isnan(s.appleLeftEye.x(i)) || isnan(s.appleRightEye.x(i))
    continue;
  end
  frame = imread(fullfile(subj, 'frames', s.frames{i}));
  
  % generate grid
  mx = max(size(frame,1),size(frame,2));
  grid(:,i) = faceGridFromFaceRect(mx, mx, 25, 25, s.appleFace.x(i),...
			      s.appleFace.y(i), s.appleFace.w(i),...
			      s.appleFace.h(i), true,s.screen.orientation(i));
  
  % generate crops
  faceImage = cropRepeatingEdge(frame, round([s.appleFace.x(i) s.appleFace.y(i) s.appleFace.w(i) s.appleFace.h(i)]));
  leftEyeImage = cropRepeatingEdge(faceImage, round([s.appleLeftEye.x(i) s.appleLeftEye.y(i) s.appleLeftEye.w(i) s.appleLeftEye.h(i)]));
  rightEyeImage = cropRepeatingEdge(faceImage, round([s.appleRightEye.x(i) s.appleRightEye.y(i) s.appleRightEye.w(i) s.appleRightEye.h(i)]));
  
  
  imwrite(faceImage, fullfile(appleFaceDir, s.frames{i}))
  imwrite(leftEyeImage, fullfile(appleLeftEyeDir, s.frames{i}));
  imwrite(rightEyeImage, fullfile(appleRightEyeDir, s.frames{i}));
end
s.grid = grid;

save(fullfile(subj,sprintf('subj_info_%s.mat',anal)),'s')


