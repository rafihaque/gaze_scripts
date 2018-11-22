function [f] = get_fix_mobile(x,y,t,start_bin,d)

dt = 1/30 * 1000; 
% initialize variables
bin  = start_bin;
i = 1;
j = 1;
isFixation = false;
xrange = [-5 20];
yrange = [-5 20];

% fixation vectors 
pX = []; % x of fixation center 
pY = []; % y of fixation center   
pI = []; % index of fixation start
pL = []; % length of fixation in indices
pD = []; % fixation duration 
pS = [];
boolIdx=[];
% time interval 


% correct for zeros
x(x==0)=NaN;
y(y==0)=NaN;
x(x<xrange(1) | x>xrange(2) |y<yrange(1) | y>yrange(2)) = NaN;
y(x<xrange(1) | x>xrange(2) |y<yrange(1) | y>yrange(2)) = NaN;

% dispersion 
while length(x) > i + bin
  % bin indices
  idx = i:i+bin;
  
  % get distance between max and min point within the bin
  dx = max(x(idx)) - min(x(idx));
  dy = max(y(idx)) - min(y(idx));
  dis = sqrt(dx.^2 + dy.^2);
  
  % debug
  % plot(x(idx),y(idx),'yo','MarkerSize',10,'LineWidth',5);
  % dx
  % dy
  % num_nans = max([sum(isnan(x(idx))) sum(isnan(y(idx)))]);
  % x(idx)
  % y(idx)

  % increase bin size if fixation conditions met
  % 
  if dis < d & dis ~= 0 & dis ~= NaN 
    bin = bin +1;
    isFixation = true;
    %boolX=[boolX 0];
    %boolY=[boolY 0];
  
  % once fixations conditions broken
  elseif isFixation
    
    % remove nans from points outside 
    tmp1 = x(idx); tmp1(isnan(tmp1)) = [];
    tmp2 = y(idx); tmp2(isnan(tmp2)) = [];
    
    % store x
    pX = [pX median(tmp1)];
    pY = [pY median(tmp2)];
    pI = [pI i];
    pL = [pL bin-1];
    pD = [pD (bin-1)*dt];
    pS = [pS i];
    isFixation = false;
    i = i+bin+1;
    bin = start_bin;
    
    boolIdx=[boolIdx idx];
    %text(median(tmp1),median(tmp2),'FIX','FontSize',16)  
  else
    pS = [pS i];
    i = i+1;  
  end
end

if isFixation
  tmp1 = x(idx); tmp1(isnan(tmp1)) = [];
  tmp2 = y(idx); tmp2(isnan(tmp2)) = [];
  
  pX = [pX median(tmp1)];
  pY = [pY median(tmp2)];
  pI = [pI i];
  pL = [pL bin];
  pD = [pD bin*dt];
  
  boolIdx=[boolIdx idx];
end
f.x = pX; f.X =pX;
f.y = pY; f.Y=pY;
f.sta = pI;
f.len = pL;
f.dur = pD;

%Turn boolean Idxs to boolean
bool=false(1,length(x)); 
bool(boolIdx)=true;

f.bool=bool;
  
  
    


