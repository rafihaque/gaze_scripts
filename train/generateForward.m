function generateForward(raw, anal)
  
subjs = dir(raw);
subjs = {subjs.name};
subjs(1:2) =[];
allSubjs = [];
allLabelTrain = [];
allLabelTest = [];
allLabelValid  = [];
% loop through subjects
subjs = subjs(contains(subjs,'FaceFrames'));

fileID = fopen('forward_swarm_BMI','w');
fprintf(fileID,'#!/bin/bash\n');

m='CV';
c='best_checkpoint_MIT_B16';
for i = 1:length(subjs)
 subjPath=fullfile(raw,subjs{i})
 if exist(fullfile(subjPath,['metadata_' anal '.mat'])) > 0
	 fprintf(fileID, ['python forward.py -s ' subjs{i} ' -m ' m ' -c ' c ' -a ' anal '\n'])
 end
end

end
