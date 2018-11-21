% generateCrops.m
% This script generates all of the image crops required to train iTracker.
% It will create three subdirectories in each subject directory:
% "appleFace," "appleLeftEye," and "appleRightEye."
% swarm -f /home/haqueru/gaze_scripts/preprocess_swarm -g 3 -p 2 --gres=lscratch:1 --merge-output --time 04:00:00 --logdir=/data/haqueru/output/

function create_swarm(raw)

% change later
subjs = dir(raw);
subjs = {subjs.name};
subjs(~contains(subjs,'.tar.gz')) =[];

fileID = fopen('preprocess_swarm','w');
for i = 1:length(subjs)
  r = subjs{i};
  
  fprintf(fileID,'cd /home/haqueru/gaze_scripts/preprocess; sh preprocess.sh /data/haqueru/gaze %s /home/haqueru/gaze_scripts/preprocess/;\n',r(1:5));
end
fclose(fileID)


% save(fullfile(subj,'grid.mat'))


