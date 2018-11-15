%This script reads the liveL2Loss.txt file and plots the progress of
%training

% fname='liveL2LossGazeCaptAll_fineTune_OurCrops_Val.txt';
% T= strrep(fscanf(fopen(fname),'%c'),'Epoch','\n Epoch');
% fileID = fopen('test.txt','w');
% fprintf(fileID, T);
% fname='test.txt';

root='/home/haqueru/gaze_scripts/train/models';



BATCH = [16 32 64 128];

for j = 1:length(BATCH)

  
  fname=fullfile(root,sprintf('train_MIT_None_MIT_B%d',BATCH(j)));
  T = readtable(fname, 'Delimiter','\t','ReadVariableNames',false);

  %Find the indices with (val) in them
  loss    =  T.Var4;
  headers = T.Var1;
  IndexC = strfind(headers, '(train)');
  Index = find(not(cellfun('isempty', IndexC)));
  loss2=loss(Index);

  %Grab only average loss
  avgLoss=zeros(1,length(Index));
  for i=1:length(loss2)
    [token, token2 ]= strtok(loss2{i,1},{'('});
    avgLoss(i)=str2double(token2(2:end-1));
  end
  
  plot((1:length(avgLoss))*BATCH(j)*1000,sqrt(avgLoss),'LineWidth',2)
  hold on

end



ft=16;
figuresize(10,10,'inches')
xlabel('Number of Frames','FontSize',ft)
ylabel('L2 Loss (cm)','FontSize',ft)
title(' Training Error (Original Dataset)','FontSize',ft)
%ylim([0 11]);
%xlim([0 length(avgLoss)])
set(gca,'FontSize',16)
legend('16','32','64','128')
keyboard