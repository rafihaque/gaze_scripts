function [xx,yy] = customlowpass(x,y,passband,fs)
% This is a custom lowpass function that utilizes a zero-phase digital 
% filtering process (i.e. filtfilt() ) in order to avoid a phase shift on 
% the signal. By default, it sets the following values:
%       Stopband Freq:   0.05 pi rad/s higher than the passband frequency.
%       Passband Ripple: 0.5 dB
%       Stopband Atten:  65  dB
%       Design Method:   Kaiser Window


%Handle 0 if there is nan, but put nan back later
putInTheseIdx=find(isnan(x));
x(putInTheseIdx)=0; 
y(putInTheseIdx)=0;


pb = passband;
F = designfilt('lowpassfir',...
    'PassbandFrequency',pb/fs,...
    'StopbandFrequency',pb/fs + 0.05,...
    'PassbandRipple',0.5,'StopbandAttenuation',65,...
    'DesignMethod','kaiserwin');
xx = filtfilt(F,x); yy=filtfilt(F,y);

xx(putInTheseIdx)=nan;
yy(putInTheseIdx)=nan;
end
