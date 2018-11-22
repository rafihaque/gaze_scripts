%This function makes subject metaData and stores a boolean for retraining that partitions train/test/val

function  makeSubjectMetaDataWithFilters(sub,percentCalibration,transitionError,loadThisXY,nameOfExperiment)

[dataDir,sub,text] = fileparts(sub);

%When bash passes argumets, they are string. Hard cast to double
typ=class(percentCalibration);
class(transitionError)
if strcmp(typ,'double')==false
    percentCalibration=str2double(percentCalibration);
    c=str2double(transitionError);
else
    c=transitionError;
end

%Set filters
testIfEyesMoved=true;
testFixOnly=true;
testMSEFilter=true;
prctileThreshold=75;
makeQAGraphs=true;
isFigureVisable='off'; %Toggle 'off' or 'on'
RedoCam2Screen=true;

Pts2cm=0.02;

%Set paths
raw_dirM = fullfile(dataDir,sub);
save_file = fullfile(raw_dirM,'outPut',nameOfExperiment,'events.mat')
%save_file = fullfile(raw_dirM,['eventsFiltered3.mat']);
saveOutputPath=fullfile(raw_dirM,'outPut',nameOfExperiment);
saveOutputPath2=fullfile(dataDir,'AllSubjExperimentOutput',nameOfExperiment,sub);

%Make experiment output directory
if exist(saveOutputPath) == 0
    mkdir(saveOutputPath);
end
if exist(saveOutputPath2) == 0
    mkdir(saveOutputPath2);
end
disp([ 'getting sub events: ' sub])
if exist(save_file,'file')
    load(save_file)
end

% load subject info struct
dataDir
sub
s = loadSubject(fullfile(dataDir,sub),nameOfExperiment);

% load pytorch xy predictions
pytorchxy=load(fullfile(dataDir,sub,loadThisXY));
xy=pytorchxy.xy;

%Prepare arrays for cam2screen
camx = xy(:,1);
camy = xy(:,2);
screenw = ones(length(xy),1)*728; ev.screenw=screenw;
screenh = ones(length(xy),1)*1024; ev.screenh=screenh;
orient = ones(length(xy),1)*1; ev.orient=orient;
device = cell(length(xy), 1); device(:) = {'iPad Air 2'}; ev.device=device;

% convert to screen coordinates
fileExisting  = exist(fullfile(save_file), 'file');
screenCoord = NaN(length(camx),2);
if fileExisting == 0 | RedoCam2Screen
    %Convert and smooth points
    [screenCoord(:,1),screenCoord(:,2)] = cam2screen(camx,camy,orient,device,screenw,screenh,true);

    ev.xy=nan(length(camx),2);

    [ev.xy(:,1),...
        ev.xy(:,2)] = customlowpass(screenCoord(:,1),screenCoord(:,2),10,30);
    save(save_file,'ev')
else
    %Smooth points
    [ev.xy(:,1),ev.Torch_MIT_ipad_FineTuneClinicFiltered3_xy(:,2)] = ...
        customlowpass(ev.Torch_MIT_ipad_FineTuneClinic_xy(:,1),ev.Torch_MIT_ipad_FineTuneClinic_xy(:,2),10,30);
end

%Now that xy have been transformed and smoothed, let's look at calibration
%portion of task

%Load calib json
calInfo = Json_to_Struct(raw_dirM,'**/*CalibrationInfo.json');
taskInfo=Json_to_Struct(raw_dirM,'/*TaskImageInfo.json');
ev.name=sub;

%Get indices of calibration start and end.
calibrationStartIdx = calInfo.instructionsFrameCount+1;
calStrt2Fin=(calibrationStartIdx:calibrationStartIdx+sum(calInfo.faceFramePerDot)-1);
ev.calibrationStartIdx=calibrationStartIdx;
ev.calStrt2Fin=calStrt2Fin;
%calStret2FinNoNan=(calStrt2Fin(()))

%Re-construct true XY (allDots) from metaCalInfo
[allDots,thisManyFramesPerDot]=getDotInfo(calInfo);
ev.allDots = allDots;
ev.thisManyFramesPerDot=thisManyFramesPerDot;

%Compare predictions to true XY
x2 = ev.xy(calStrt2Fin,1); %We only want coordinates of calibration task, not instructions
y2 = ev.xy(calStrt2Fin,2);
Tx = allDots(:,1);
Ty = allDots(:,2); %true coordinates

%Eliminate: transition, distraction, and same state frames.
%Get the Boolean to estimate if eyes moved during new calibration dot
if testIfEyesMoved == true
    [~,boolXYEyesMoved] = getBooleanIfMovedEyesDuringCalibration(x2,y2,thisManyFramesPerDot,c,percentCalibration);

    %QA test if eye moved
    if makeQAGraphs == true
    %Plot graphs
    title='Comparing PreIfEyesMoved to PostIfEyesMoved';
    saveXName='ifEyesMoved_X.jpg';
    saveYName='ifEyesMoved_Y.jpg';
    legendT={'True','PreSVM','Bool','PostSVM'};
    try
    customPlot(x2,y2,boolXYEyesMoved,allDots,title,legendT,dataDir,sub,saveXName,saveYName,isFigureVisable,saveOutputPath,saveOutputPath2)
    catch ME
	    warning(ME.message)
    end
    end
end
if testFixOnly == true
    %fixDist=ev.Torch_MIT_ipad_FineTuneClinicFiltered_stdTop*3;
    f=get_fix_mobile(x2,y2,3,3,1.9);
    boolXYFixOnly=f.bool;
    %QA test if eye moved
    if makeQAGraphs == true
        title='Comparing PreIfFix to PostIfFix';
        saveXName='ifFix_X.jpg';
        saveYName='ifFix_Y.jpg';
        legendT={'True','PreSVM','Bool','PostSVM'};
	try
        customPlot(x2,y2,boolXYFixOnly,allDots,title,legendT,dataDir,sub,saveXName,saveYName,isFigureVisable,saveOutputPath,saveOutputPath2)
    	catch ME
		warning(ME.message)
	end
    end
end

if testMSEFilter==true
    xDist =  (Tx-x2).^2;
    yDist = (Ty-y2).^2;
    EDist = sqrt(xDist+yDist);

    thresholdE=prctile(EDist,prctileThreshold);
    MSEBool=EDist<thresholdE;

    %QA test if eye moved
    if makeQAGraphs == true
        title='Comparing PreMSE to PostMSE';
        saveXName='MSE_X.jpg';
        saveYName='MSE_Y.jpg';
        legendT={'True','PreSVM','Bool','PostSVM'};
	try
        customPlot(x2,y2,MSEBool,allDots,title,legendT,dataDir,sub,saveXName,saveYName,isFigureVisable,saveOutputPath,saveOutputPath2)
    	catch ME
   	 warning(ME.message)
	end
	end
end

%Remove any nans
%calFaceFrameLabels=s.appleFace.ImageFile(calStrt2Fin);
%noNAN= ~isnan(calFaceFrameLabels);


lt=min([length(boolXYEyesMoved),length(boolXYFixOnly),length(MSEBool)]);%,length(noNAN)]);
if sum(boolXYFixOnly)> length(boolXYFixOnly)/2
	TBool= boolXYEyesMoved(1:lt) & boolXYFixOnly(1:lt) & MSEBool(1:lt)';% & noNAN;
else
	TBool= boolXYEyesMoved(1:lt) & MSEBool(1:lt)';% & noNAN;
end

%Store variables to make metaData construction easier
combBool = TBool(:) & s.appleFace.IsValid(calStrt2Fin);
ev.FilteredTrueX=Tx(combBool);
ev.FilteredTrueY=Ty(combBool);
sOrient=orient(calStrt2Fin);
calFaceFrameLabels=s.frames(calStrt2Fin);

ev.FilteredCalibFrameIndex=calFaceFrameLabels(combBool)';
[ev.FilteredTrueCamX, ev.FilteredTrueCamY] = screen2cam(Tx(combBool), Ty(combBool), sOrient(combBool), ...
    						device(combBool), screenw(combBool), screenh(combBool), true)
[ev.TrueCamX, ev.TrueCamY] = screen2cam(Tx, Ty, sOrient(1:length(Ty)), ...
					device(1:length(Ty)), screenw(1:length(Ty)), screenh(1:length(Ty)), true)
selectedX=x2(TBool);
selectedY=y2(TBool);
selectedTX=Tx(TBool);
selectedTY=Ty(TBool);

selectedY=selectedY(selectedTY<650*Pts2cm);
selectedX=selectedX(selectedTY<650*Pts2cm);
selectedTX=selectedTX(selectedTY<650*Pts2cm);
selectedTY=selectedTY(selectedTY<650*Pts2cm);

%Now do dynamic time warping
%bX=selectedX; bY=selectedY;
%btx=selectedTX; bty=selectedTY;

%[~,ix,itx] = dtw(selectedX,selectedTX);
%selectedX=selectedX(ix);
%selectedTX=selectedTX(itx);

%[~,iy,ity] = dtw(selectedY,selectedTY);
%selectedY=selectedY(iy);
%selectedTY=selectedTY(ity);



%Train the SVM
mn=round(min(length(selectedX),length(selectedTX)/2));
MdlX = fitrsvm(selectedX(1:mn),selectedTX(1:mn));
MdlY = fitrsvm(selectedY(1:mn),selectedTY(1:mn));

%Use SVM model to calibrate to all points
    calibratedX = predict(MdlX,ev.xy(:,1));
    calibratedY = predict(MdlY,ev.xy(:,2));

    %Select calibration
    calX = calibratedX(calStrt2Fin);
    calY = calibratedY(calStrt2Fin);

    %Get the Boolean to estimate if eyes moved during new calibration dot
    if testIfEyesMoved == true
     [~,boolXYEyesMoved] = getBooleanIfMovedEyesDuringCalibration(calX,calY,thisManyFramesPerDot,c,percentCalibration);
    end
    if testFixOnly == true
     %fixDist=ev.Torch_MIT_ipad_FineTuneClinicFiltered_stdTop*3;
     f=get_fix_mobile(calX,calY,4,4,1.9);
     boolXYFixOnly=f.bool;
    end
    if testMSEFilter==true
     xDist =  (Tx-x2).^2;
     yDist = (Ty-y2).^2;
     EDist = sqrt(xDist+yDist);

     thresholdE=prctile(EDist,prctileThreshold);
     MSEBool=EDist<thresholdE;
    end

    lt=min(length(boolXYEyesMoved),length(boolXYFixOnly));

    %Boolean to select only the later half of the calibration dots
    TF=[false(1,ceil(lt/2)) true(1,ceil(lt/2))];

    %Combine booleans
    TBool2= boolXYEyesMoved(1:lt) & boolXYFixOnly(1:lt) &...
        MSEBool' & TF(1:lt);


    %Construct raw EucX
    selectedRawEucX=x2(TBool2);
    selectedRawEucY=y2(TBool2);

    selectedEucX=calX(TBool2);
    selectedEucY=calY(TBool2);
    selectedEucTX=Tx(TBool2);
    selectedEucTY=Ty(TBool2);

    %Get upper and lower iPad points to compare accuracy in top/bottom
    %hemispheres
    for index = 1:length(selectedEucTY)
        selectedCoordUpperiPad = selectedEucTY < 650*Pts2cm;
        selectedCoordButtomiPad = ~selectedCoordUpperiPad;
    end
%Find Euclidean Error on last half of rounds.
    Xdif = (selectedEucX-selectedEucTX) .^2;
    Ydif = (selectedEucY-selectedEucTY) .^2;

    euclDist = mean(sqrt(Xdif+Ydif));
    stdCal = std(sqrt(Xdif+Ydif));

    euclDist = euclDist;
    stdCal = stdCal;

%Find Euclidean Error comparing upper and lower  dots.
    %Top
    XdifTop = (selectedEucX(selectedCoordUpperiPad)-selectedEucTX(selectedCoordUpperiPad)) .^2;
    YdifTop = (selectedEucY(selectedCoordUpperiPad)-selectedEucTY(selectedCoordUpperiPad)) .^2;

    euclDistTop = mean(sqrt(XdifTop+YdifTop));
    stdCalTop = std(sqrt(XdifTop+YdifTop));

    euclDistTop = euclDistTop;
    stdCalTop = stdCalTop;
    ev.euclTop = euclDistTop;
    ev.stdTop = stdCalTop;

    %Bottom
    XdifB = (selectedEucX(selectedCoordButtomiPad)-selectedEucTX(selectedCoordButtomiPad)) .^2;
    YdifB = (selectedEucY(selectedCoordButtomiPad)-selectedEucTY(selectedCoordButtomiPad)) .^2;

    euclDistB = mean(sqrt(XdifB+YdifB));
    stdCalB = std(sqrt(XdifB+YdifB));

    euclDistB = euclDistB;
    stdCalB = stdCalB;
    ev.euclBot = euclDistB;
    ev.stdBot = stdCalB;

%Now do Raw Euc Error
    %Top
    XdifTop = (selectedRawEucX(selectedCoordUpperiPad)-selectedEucTX(selectedCoordUpperiPad)) .^2;
    YdifTop = (selectedRawEucY(selectedCoordUpperiPad)-selectedEucTY(selectedCoordUpperiPad)) .^2;

    euclDistTop = mean(sqrt(XdifTop+YdifTop));
    stdCalTop = std(sqrt(XdifTop+YdifTop));

    euclDistTop = euclDistTop;
    stdCalTop = stdCalTop;
    ev.euclRawTop = euclDistTop;
    ev.stdRawTop = stdCalTop;

    %Bottom
    XdifB = (selectedEucX(selectedCoordButtomiPad)-selectedEucTX(selectedCoordButtomiPad)) .^2;
    YdifB = (selectedEucY(selectedCoordButtomiPad)-selectedEucTY(selectedCoordButtomiPad)) .^2;

    euclDistB = mean(sqrt(XdifB+YdifB));
    stdCalB = std(sqrt(XdifB+YdifB));

    euclDistB = euclDistB;
    stdCalB = stdCalB;
    ev.euclRawBot = euclDistB;
    ev.stdRawBot = stdCalB;
%store events struct

%ev.Torch_MIT_ipad_FineTuneClinicFiltered_labels = s.frames;
ev.meanEuclDist = euclDist;
%ev.ImageFile = sort(s.appleFace.ImageFile);
ev.stdCalError = stdCal;
ev.calibratedX = calibratedX;
ev.calibratedY = calibratedY;
ev.calFrameCount = calInfo.calibrationFrameCount;
%ev.sortedValid=sortedValid;
ev.framesPerImage = taskInfo.framesPerImage;
ev.imageLabels = taskInfo.imageLabels;
save(save_file,'ev')
ev
%keyboard


%QA graph
if makeQAGraphs==true
    titleT='Comparing PreAllSVM to PostAllSVM';
    legendT={'True','Pre-SVM','Bool','Post-SVM'};
    saveXName='All_X.jpg';
    saveYName='All_Y.jpg';

    customPlot(x2,y2,TBool,allDots,titleT,legendT,dataDir,sub,saveXName,saveYName,isFigureVisable,saveOutputPath,saveOutputPath2)
end

%Make metadata

%Only make new metadata if subject does not already have one
if true %exist(fullfile(dataDir,sub,'subjMetaData4RetrainingCNN.mat')) == 0
	metadata=struct();

	metadata.frameIndex=imageLabel2FrameIndex(calFaceFrameLabels);
	metadata.labelDotXCam=ev.TrueCamX;
	metadata.labelDotYCam=ev.TrueCamY;
	metadata.labelFaceGrid=getSubFaceGrid(fullfile(dataDir,sub),calFaceFrameLabels);
	metadata.labelRecNum=repmat(ev.name,[length(ev.TrueCamX),1]);
	metadata.labelTrain=zeros(length(ev.TrueCamX),1);
	metadata.labelVal=zeros(length(ev.TrueCamX),1);
	metadata.labelTest=zeros(length(ev.TrueCamX),1);

	for i=1:length(ev.TrueCamX)
        	r=rand;
        	if r>0 & r<.85
         		metadata.labelTrain(i)=1;
        	elseif r>=.85 & r<.95
         		metadata.labelVal(i)=1;
        	else
         		metadata.labelTest(i)=1;
        	end
	end
	%Save base metadata at subject directory base
	save(fullfile(dataDir,sub,'subjMetaData4RetrainingCNN.mat'),'-struct','metadata')
	
	%Save metadata2 with filters in experiment directory
	metadata2=metadata;
	metadata2.labelTrain=metadata2.labelTrain(:) & TBool(:);
	metadata2.labelTest=metadata2.labelTest(:) & TBool(:) ;
	metadata2.labelVal=metadata2.labelVal(:) & TBool(:);
	subModelPath=fullfile(dataDir,sub,'outPut',nameOfExperiment);
        if exist(subModelPath) == 0
                mkdir(subModelPath)
        end
	save(fullfile(subModelPath,'subjMetaData4RetrainingCNN.mat'),'-struct','metadata2')

else
	%if Subject already has metaData, then load it and append filters
	metadata=load(fullfile(dataDir,sub,'subjMetaData4RetrainingCNN.mat'))
	
	metadata2=metadata;
        metadata2.labelTrain=metadata2.labelTrain(:) & TBool(:);
        metadata2.labelTest=metadata2.labelTest(:) & TBool(:);
        metadata2.labelVal=metadata2.labelVal(:) & TBool(:);
	
	subModelPath=fullfile(dataDir,sub,'outPut',nameOfExperiment);
        if exist(subModelPath) == 0
                mkdir(subModelPath)
        end
        save(fullfile(subModelPath,'subjMetaData4RetrainingCNN.mat'),'-struct','metadata2')
	metadata=metadata2
end


end

function  customPlot(x2,y2,boolXY,allDots,titleT,legendT,dataDir,sub,saveXName,saveYName,isFigureVisable,saveOutputPath,saveOutputPath2)
    Tx=allDots(:,1);
    Ty=allDots(:,2);
    tmpX1 = x2(boolXY); tmpTX1=Tx(boolXY);
    tmpY1 = y2(boolXY); tmpTY1=Ty(boolXY);

    mn=min(round(length(Tx)/2),round(length(tmpX1)));
    tmpMdlX2 = fitrsvm(tmpX1(1:mn),tmpTX1(1:mn));
    tmpMdlY2 = fitrsvm(tmpY1(1:mn),tmpTY1(1:mn));

    %Use SVM model to calibrate to all points
    calibratedX = predict(tmpMdlX2,x2);
    calibratedY = predict(tmpMdlY2,y2);

    f1=figure('visible',isFigureVisable);
    l1=plot(allDots(:,1),'LineWidth',3,'Color','b'); hold on;
    l2=plot(x2, 'LineWidth',3,'Color','y');
    l3=scatter(find(~boolXY),x2(~boolXY),'Xr','LineWidth',2);
    l4=plot(1:length(calibratedX),calibratedX,'Color','g','LineWidth',1);
    xlabel('Time'); ylabel('X-Position (cm)');
    title([titleT ' X'])% ['Post-error:' num2str(ev.euclTop)]});
    if ~isempty(l3)
        legend([l1 l2 l3 l4], legendT)
    else
        legend([l1 l2 l4], legendT([1,2,4]))
    end
    set(gcf, 'Position', [10, 10, 400, 400])
    %saveOutputPath=fullfile(dataDir,sub,'outPut','Baseline');
    %saveOutputPath2=fullfile(dataDir,'AllSubjExperimentOutput','Baseline',sub);

    saveas(f1,fullfile(saveOutputPath,saveXName))
    saveas(f1,fullfile(saveOutputPath2,saveXName))

    %Do Y
    f1=figure('visible',isFigureVisable);
    l1=plot(allDots(:,2),'LineWidth',3,'Color','b'); hold on;
    l2=plot(y2, 'LineWidth',2,'Color','y');
    l3=scatter(find(~boolXY),y2(~boolXY),'Xr','LineWidth',2);
    l4=plot(1:length(calibratedY),calibratedY,'Color','g','LineWidth',1);
    xlabel('Time'); ylabel('Y-Position (cm)');
    title([titleT ' Y'])% ['Post-error:' num2str(ev.euclTop)]});
    if ~isempty(l3)
        legend([l1 l2 l3 l4], legendT)
    else
        legend([l1 l2 l4], legendT([1,2,4]))
    end
    set(gcf, 'Position', [10, 10, 400, 400])
    %saveOutputPath=fullfile(dataDir,sub,'outPut','Baseline');
    %saveOutputPath2=fullfile(dataDir,'AllSubjExperimentOutput','Baseline',sub);

    saveas(f1,fullfile(saveOutputPath,saveYName))
    saveas(f1,fullfile(saveOutputPath2,saveYName))

    close all
end

function customPlotDTW(bX,ix,itx,bY,iy,ity,btx,bty,titleT,legendT,dataDir,sub,saveXName,saveYName,isFigureVisable,saveOutputPath,saveOutputPath2)
    f1=figure('visible',isFigureVisable);
    l1=plot(btx,'LineWidth',3,'Color','b'); hold on; %Truex
    l2=plot(bX, 'LineWidth',3,'Color','y'); %predictedX
    l3=plot(btx(itx),'r','LineWidth',1);%dtw'd True
    l4=plot(bX(ix),'Color','g','LineWidth',1);%dtw'd predicted
    xlabel('Time'); ylabel('X-Position');
    title([titleT ' X'])% ['Post-error:' num2str(ev.euclTop)]});
    if ~isempty(l3)
        legend([l1 l2 l3 l4], legendT)
    else
        legend([l1 l2 l4], legendT([1,2,4]))
    end

    set(gcf, 'Position', [10, 10, 400, 400])
    %saveOutputPath=fullfile(dataDir,sub,'outPut','Baseline');
    %saveOutputPath2=fullfile(dataDir,'AllSubjExperimentOutput','Baseline',sub);

    saveas(f1,fullfile(saveOutputPath,saveXName))
    saveas(f1,fullfile(saveOutputPath2,saveXName))

    %Do Y
    f1=figure('visible',isFigureVisable);
    l1=plot(bty,'LineWidth',1,'Color','b'); hold on;
    l2=plot(bY, 'LineWidth',1,'Color','y');
    l3=plot(bty(ity),'r','LineWidth',2);
    l4=plot(bY(iy),'Color','g','LineWidth',2);
    xlabel('Time'); ylabel('Y-Position');
    title([titleT ' Y'])% ['Post-error:' num2str(ev.euclTop)]});
    if ~isempty(l3)
        legend([l1 l2 l3 l4], legendT)
    else
        legend([l1 l2 l4], legendT([1,2,4]))
    end
    set(gcf, 'Position', [10, 10, 400, 400])
    %saveOutputPath=fullfile(dataDir,sub,'outPut','Baseline');
    %saveOutputPath2=fullfile(dataDir,'AllSubjExperimentOutput','Baseline',sub);

    saveas(f1,fullfile(saveOutputPath,saveYName))
    saveas(f1,fullfile(saveOutputPath2,saveYName))

    close all
end

function [allDots,thisManyFramesPerDot]=getDotInfo(calInfo)
    indx = 1;
    allDots=[];
    thisManyFramesPerDot = [];
    num = calInfo.faceFramePerDot(1:end);

    for j = 1:length(calInfo.trueX)%calInfo.faceFramePerDot(1:end)
        allDots = [allDots; repmat(calInfo.trueX(j),num(j),1), repmat(calInfo.trueY(j),num(j),1)];
        thisManyFramesPerDot = [thisManyFramesPerDot, num];
        %indx = indx + 1;
    end

    %Convert AllDots from Pts2mm
allDots=allDots*0.02;

%Store these values to struct
    %ev.thisManyFramesPerDot=thisManyValidFramesPerDot;
    %Plus 17.5 because ipad draws box from top left instead of center, and the
    %the w,h of box was 35.

    allDots = allDots+(17.5*0.02);

end

function frameIndex=imageLabel2FrameIndex(filteredImageLabel)
        reduced=strrep(filteredImageLabel,'.jpg','');
        frameIndex=cellfun(@str2num,reduced);
end

function fGArray=getSubFaceGrid(subPath,filteredImageLabel)
        fGLabels=strrep(filteredImageLabel,'.jpg','.mat');
        fGPath=fullfile(subPath,'appleGrid');

        fGArray=zeros(length(filteredImageLabel),625);
        for i=1:length(filteredImageLabel)
		try
                t=load(fullfile(fGPath,fGLabels{i}));
                fGArray(i,:)=t.grid;
		catch ME
		 warning(ME.message)
		end
        end
end
