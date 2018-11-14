%This script reads the liveL2Loss.txt file and plots the progress of
%training

fname='liveL2LossGazeCaptAll_fineTune.txt';
T = readtable(fname, 'Delimiter','\t','ReadVariableNames',false);

loss=T.Var4;

%Grab only average loss
avgLoss=zeros(1,length(loss));
for i=1:length(loss)
    [token, token2 ]= strtok(loss{i,1},{'('});
    avgLoss(i)=str2double(token2(2:end-1));
end

ft=16;
plot(1:length(avgLoss),avgLoss,'LineWidth',2)
xlabel('Iteration (x1000)','FontSize',ft)
ylabel('L2 Loss (cm)','FontSize',ft)
title('Training Error Using MIT All (Fine Tune Ipad atop all, 625x1)','FontSize',ft)
ylim([0 20]);
xlim([0 length(avgLoss)])