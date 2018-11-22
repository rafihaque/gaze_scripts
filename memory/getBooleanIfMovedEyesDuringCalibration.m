%This function traverses the xy gaze array of a subject and estimates if
%they did not move their eyes during calibration dot. 
%1 means eyes moved, 0 means eyes didn't move

function [booleanGaze, bGTrans]= getBooleanIfMovedEyesDuringCalibration(x,y,thisManyValidFramesPerDot,transitionCutOff,percentCalibration)
       trackerGaze=[];
       %Intialize boolean
       booleanGaze = [];
       bGTrans=[];
       %h=zeros(1,length(thisManyValidFramesPerDot));
       c=transitionCutOff;
       
       ExpR=0.75;
       rankSumThr=.01;
       ChiThr=.01;
       %Get the intervals that correspond to each calibration dot
       CalibrationFrameIdxs = cumsum(thisManyValidFramesPerDot);
       %Compare gaze-frame A to gaze-frame B
       startIdxA=0; endIdxA=0;
       startIdxB=0; endIdxB=0;
       numCalibrationDots= (length(thisManyValidFramesPerDot)*percentCalibration)-1;
       for num = 1:length(thisManyValidFramesPerDot)-1
           if num == 1 
               %startIdxA=1+c - (~ev.sortedValid(1:ev.CalInstrFrames+1));
               startIdxA=1+c;
               endIdxA=CalibrationFrameIdxs(num);
               
               startIdxB=endIdxA+c;
               endIdxB=endIdxA+thisManyValidFramesPerDot(num+1)+1;
               
               frameA_x = x(startIdxA:endIdxA);
               frameB_x = x(startIdxB:endIdxB);
               
               frameA_y = y(startIdxA:endIdxA);
               frameB_y = y(startIdxB:endIdxB);
               %Estimate if gaze frame B is similar to gaze frame A
                    %Get euclidean distance of each point to mean of Frame
                    %A
                    
                    %Get mean
                    meanA_x = mean(frameA_x(~isnan(frameA_x)));
                    meanA_y = mean(frameA_y(~isnan(frameA_y)));
                    
                    %Calculate distance from mean distributoins
                    distA = sqrt( (meanA_x - frameA_x).^2 + (meanA_y - frameA_y ).^2 );
                    distB = sqrt( (meanA_x - frameB_x).^2 + (meanA_y - frameB_y ).^2 );
                    
                    %Check if distances come from different distributions
                    %[booleanGaze(num),p,ci,stats]=ttest2(distA,distB);
                    try
                        [p,~,stats]=ranksum(distA,distB,'alpha',rankSumThr);
                    catch
			    bGTrans=[bGTrans zeros(1,thisManyValidFramesPerDot(num))];
			    continue
                        %keyboard
                    end
                    %Try chi-squared test
                    xbounds=[min(frameA_x), max(frameA_x)];
                    ybounds=[min(frameA_y), max(frameA_y)];
                    E=length(distA)*ExpR; 
                    O=sum( (frameB_x >= xbounds(1) & frameB_x <= xbounds(2)) ...
                           & (frameB_y >= ybounds(1) & frameB_y <= ybounds(2)) );
                    T = sum( ((O-E).^2)/E );
                    Tp = chi2pdf(T,1);
                    if Tp>1
                        Tp=1;
                    end
                    if p > rankSumThr & Tp > ChiThr %If the distributions are the same then eyes probably didn't move
                        plot = false;
                        if plot == true
                            figure
                            histogram(distA);hold on; histogram(distB);
                            title({ ['Calibration Interval: ' num2str(num)],... 
                                ['Wilx Test p: ' num2str(p)], ...

                                } )
                            hold off;

                            %Plot 2d scatter of 
                            figure; scatter(frameA_x,frameA_y); hold on; ...
                            scatter(frameB_x,frameB_y); scatter(mean(frameA_x),mean(frameA_y),200,'filled')
                            title({['Calibration Interval: ', num2str(num)]...
                                ['Chi Test: ', num2str(T)],...
                                ['Chi p: ', num2str(Tp)],...
                                });
                        end
                    
                        %booleanGaze=[booleanGaze zeros(1,length(frameA_x)+length(frameB_x))];
                        booleanGaze=[booleanGaze zeros(1,length(frameA_x))];
                        trackerGaze=[trackerGaze length(frameA_x)];
                        
                        bGTrans=[bGTrans zeros(1,thisManyValidFramesPerDot(num))];
                    else
                        booleanGaze=[booleanGaze ones(1,length(frameA_x))];
                        trackerGaze=[trackerGaze length(frameA_x)];
                        
                        bGTrans=[bGTrans ones(1,thisManyValidFramesPerDot(num))];
                    end
                     
           end
       if num > 1
            %Edge case when transition cut more than valid frames
               if c<thisManyValidFramesPerDot(num)
                startIdxA=CalibrationFrameIdxs(num-1)+c;
                endIdxA=CalibrationFrameIdxs(num);
               else
                startIdxA=CalibrationFrameIdxs(num-1);
                endIdxA=CalibrationFrameIdxs(num);
               end
               
               startIdxB=endIdxA+c;
               endIdxB=endIdxA+thisManyValidFramesPerDot(num+1);
               if c > thisManyValidFramesPerDot(num+1)+1 %edge case
                   booleanGaze=[booleanGaze zeros(1,length(frameA_x))];
                   trackerGaze=[trackerGaze length(frameA_x)];
                   bGTrans=[bGTrans zeros(1,thisManyValidFramesPerDot(num))];
                   endIdxB=startIdxB;
                   continue
               end
               
               %endIdxB=CalibrationFrameIdxs(num+2);
               %endIdxB=endIdxA+thisManyValidFramesPerDot(num+1);
               frameA_x = x(startIdxA:endIdxA);
               frameB_x = x(startIdxB:endIdxB);
               
               frameA_y = y(startIdxA:endIdxA);
               frameB_y = y(startIdxB:endIdxB);
               %Estimate if gaze frame B is similar to gaze frame A
                    %Get euclidean distance of each point to mean of Frame
                    %A
                    
                    %Get mean
                    meanA_x = mean(frameA_x(~isnan(frameA_x)));
                    meanA_y = mean(frameA_y(~isnan(frameA_y)));
                    
                    %Calculate distance from meanA
                    distA = sqrt( (meanA_x - frameA_x).^2 + (meanA_y - frameA_y ).^2 );
                    distB = sqrt( (meanA_x - frameB_x).^2 + (meanA_y - frameB_y ).^2 );
                    
                    %Check if distances come from different distributions
                    %[h(num),p,ci,stats]=ttest2(distA,distB);
                    %Before performing ranksum, check if the interval is
                    %all nan
                    
                    try
                        [p,~,stats]=ranksum(distA,distB,'alpha',rankSumThr);
                    catch
			bGTrans=[bGTrans zeros(1,thisManyValidFramesPerDot(num))];
		    	continue	
                        keyboard
                    end
                    %Try chi-squared test
                    xbounds=[min(frameA_x), max(frameA_x)];
                    ybounds=[min(frameA_y), max(frameA_y)];
                    E=length(distA)*ExpR;  
                    O=sum( (frameB_x >= xbounds(1) & frameB_x <= xbounds(2)) ...
                           & (frameB_y >= ybounds(1) & frameB_y <= ybounds(2)) );
                    T = sum( ((O-E).^2)/E );
                    Tp = chi2pdf(T,1);
                    
                    if num ==2 | num==3
                       
			    % keyboard
                    end
                    
                    if Tp>1
                        Tp=1;
                    end
                    
                    
                    if  p > rankSumThr & Tp > ChiThr
                        showplots=false;
                     if showplots == true
                         figure
                         histogram(distA);hold on; histogram(distB);
                         title({ ['Calibration Interval: ' num2str(num)],... 
                            ['Wilx Test p: ' num2str(p)], ...
                            } )
                         hold off;

                         figure; scatter(frameA_x,frameA_y); hold on; 
                         scatter(frameB_x,frameB_y); scatter(mean(frameA_x),mean(frameA_y),200,'filled')
                         title( {['Calibration Interval: ', num2str(num)],...
                            ['Chi Test: ', num2str(T)],...
                            ['Chi p: ', num2str(Tp)],...
                             });
                     end
                        booleanGaze=[booleanGaze zeros(1,length(frameA_x))];
                        trackerGaze=[trackerGaze length(frameA_x)];
                        
                        bGTrans=[bGTrans zeros(1,thisManyValidFramesPerDot(num))];
                        if num >= length(thisManyValidFramesPerDot)-1
                            %Add another row of zeros because we can't
                            %confirm they actually looked
                            booleanGaze=[booleanGaze zeros(1,length(frameB_x))];
                            trackerGaze=[trackerGaze length(frameB_x)];
                            
                            bGTrans=[bGTrans zeros(1,thisManyValidFramesPerDot(num))];
                        end
                    else
                        booleanGaze=[booleanGaze ones(1,length(frameA_x))];
                        bGTrans=[bGTrans ones(1,thisManyValidFramesPerDot(num))];
                        if num >= length(thisManyValidFramesPerDot)-1
                            %Add another row of ones to count for last dot
                            booleanGaze=[booleanGaze ones(1,length(frameB_x))];
                            trackerGaze=[trackerGaze length(frameB_x)];
                            
                            bGTrans=[bGTrans ones(1,thisManyValidFramesPerDot(num))];
                        end
                    end
                    
                    
       end
       if num >= length(thisManyValidFramesPerDot)-1
           
           booleanGaze=logical(booleanGaze);
	   bGTrans=logical(bGTrans(1:length(x)));
           %display(trackerGaze)
           %keyboard
           break
       end
       end
end


