function parForGenCrops(raw, anal)

% change later
subjs = dir(raw);
subjs = {subjs.name};
subjs(1:2) =[];
allSubjs = [];
allLabelTrain = [];
allLabelTest = [];
allLabelValid  = [];
% loop through subjects
subjs = subjs(contains(subjs,'FaceFrames'));
rawPath='/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/'
count=0;

parfor i = 1:length(subjs)
 disp(subjs{i})
 %Check if crops have not been made, but detect face has 
 %if exist(fullfile(rawPath,subjs{i},['appleFace_' anal]),'dir') == 0 && ...
	% exist(fullfile(rawPath,subjs{i},['appleFace_' anal '.json']),'file') > 0
  %[~,list] = system(['ls ' fullfile(rawPath,subjs{i},['appleFace_' anal])]);	 
  %if length(list) < 3
   try
       generateCrops(fullfile(raw,subjs{i}),anal)
       %count=count+1;
   catch ME
	warning(ME.message)
   end
  %end
 %end
end
disp(['Count ' num2str(count)])
end
