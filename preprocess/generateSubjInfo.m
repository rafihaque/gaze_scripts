function generateSubjInfo(raw,anal)

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

for i = 1:length(subjs)
  subj_info = fullfile(raw,subjs{i},sprintf('subj_info_%s.mat',anal));
  fprintf('SUBJ: %s \n',subjs{i})

  if ~exist(subj_info,'file')
	  try
    		s = loadSubject(fullfile(raw,subjs{i}),'CV');
    		save(fullfile(raw,subjs{i},sprintf('subj_info_%s.mat',anal)),'s')
  	catch ME
		warning(ME.message)
	end
   end
end
