function create_swarm_BMI(raw)
if nargin<1
	raw='/labs/cliffordlab/data/ipad_art_gaze/EHAS/server_scripts/eyemobile/rawData/'
end

%Get list of subject and select only valid folder names
subjs = dir(raw);
subjs = {subjs.name};
%Indices where MIT only
MITIdx = cellfun(@(c) ~isnan(str2double(c)),subjs);
MITsubjs = subjs(MITIdx);
subjs=MITsubjs;
%subjs(~contains(subjs,'.tar.gz')) =[];

fileID = fopen('preprocess_swarm_BMI','w');
fprintf(fileID,'#!/bin/bash\n');

[jobID{1:length(subjs)}] = deal('NaN');
delay=3;
for i = 1:3%length(subjs)
  r = subjs{i}
  
  if i<delay
  	bashCMD=sprintf('qsub -N %s -v sub=%s,crop=%s /home/apongos/gaze_scripts/preprocess/preprocess.sh %s%s',r(1:5),strcat("'",r(1:5),"'"),"'CV'",';');
  	[~,jobID{i}] = system(bashCMD)

  else
   	bashCMD=sprintf('qsub -N %s -v sub=%s,crop=%s -W depend=afterok:%s /home/apongos/gaze_scripts/preprocess/preprocess.sh %s%s',r(1:5),strcat("'",r(1:5),"'"),jobID{i-delay+1},"'CV'",';')
	[~,jobID{i}] = system(bashCMD)   
 end
  %fprintf(fileID,'qsub -N %s -v sub=%s,crop=%s /home/apongos/gaze_scripts/preprocess/preprocess.sh %s%s',r(1:5),strcat("'",r(1:5),"'"),"'CV'",';');
end
fclose(fileID)
