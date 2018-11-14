%This script reads the liveL2Loss.txt file and plots the progress of
%training

% fname='liveL2LossGazeCaptAll_fineTune_OurCrops_Val.txt';
% T= strrep(fscanf(fopen(fname),'%c'),'Epoch','\n Epoch');
% fileID = fopen('test.txt','w');
% fprintf(fileID, T);
% fname='test.txt';

fold="/Users/apongos/Downloads";
fname=fullfile(fold,'liveLossVal_Test.txt');
T = readtable(fname, 'Delimiter','\t','ReadVariableNames',false);

loss=T.Var4;

%Find the indices with (val) in them
headers=T.Var1;
IndexC = strfind(headers, '(val)');
Index = find(not(cellfun('isempty', IndexC)));
loss2=loss(Index);

%Grab only average loss
avgLoss=zeros(1,length(Index));
for i=1:length(loss2)
    [token, token2 ]= strtok(loss2{i,1},{'('});
    avgLoss(i)=str2double(token2(2:end-1));
end

ft=16;
plot(1:length(avgLoss),avgLoss,'LineWidth',2)
xlabel('Iteration','FontSize',ft)
ylabel('L2 Loss (cm)','FontSize',ft)
title('Validation Error (Fine-Tune Research atop MIT, 625x1)','FontSize',ft)
ylim([0 11]);
xlim([0 length(avgLoss)])