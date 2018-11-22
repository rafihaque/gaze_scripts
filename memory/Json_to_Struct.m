%Json_to_Struct. file type is used with dir() to find that specific type of
%file. Ex. jsonFile=dir('**/faceGrid*.json')

function output=Json_to_Struct(path, filetype)

tmp=strrep(filetype,'*','');
fpath=fullfile(path, tmp)

output=struct; 
% cd(path)
if contains(fpath,'frames.json') || contains(fpath,'info.json') || contains(fpath,'screen.json') || contains(filetype, 'ImageInfo.json')  
    jsonFile=dir([path filetype]);
    rawPatientString=fileread(fullfile(jsonFile.folder,jsonFile.name));
    output=jsondecode(rawPatientString);
    
    if contains(fpath,'screen.json')
        output.H = output.H;
        output.W = output.W;
        output.Orientation = output.Orientation;
    end
        
  
    if contains(fpath, 'TaskImageInfo.json')
        output.framesPerImage = output.FramesPerImage;
        output.imageLabels = output.ImageLabels;

    end
    
    return
end

if contains(fpath,'CalibrationInfo.json')
    jsonFile=dir([path '/*CalibrationInfo.json']);
    rawPatientString=fileread(fullfile(jsonFile.folder,jsonFile.name));
    output=jsondecode(rawPatientString);
    %output.trueX = cell2mat(output.trueX);
    %output.trueY = cell2mat(output.trueY);
    %output.faceFramePerDot = cell2mat(output.faceFramePerDot);
    return
end

if contains(fpath,'appleFace.json') & ~contains(fpath,'TESTappleFace.json') 
    jsonFile=dir([path '/appleFace.json']);
    output=getCropInfo(jsonFile);
end
if contains(fpath,'appleLeftEye.json') & ~contains(fpath,'TESTappleLeftEye.json') 
    jsonFile=dir([path '/appleLeftEye.json']);
    output=getCropInfo(jsonFile); 
end
if contains(fpath,'RightEye.json') & ~contains(fpath,'RightEye.jsonTEST') 
    jsonFile=dir([path '/appleRightEye.json']);
    output=getCropInfo(jsonFile)
end


function output = getCropInfo(jsonFile)
%Face to Facegrid
    rawPatientString=fileread(fullfile(jsonFile.folder,jsonFile.name));
    output=parse_json(rawPatientString);
    output.H=cell2mat(output.H);
    output.W=cell2mat(output.W);
    output.X=cell2mat(output.X);
    output.Y=cell2mat(output.Y);
    output.IsValid=cell2mat(output.IsValid);
    %output.ImageFile = (output.ImageFile);
end

%Below is for testing, can comment out
if contains(fpath,'TESTappleFace.json')
    jsonFile=dir([path '/TESTappleFace.json']);
    output=getCropInfo2(jsonFile);
end
if contains(fpath,'TESTappleLeftEye.json')
    jsonFile=dir([path '/TESTappleLeftEye.json']);
    output=getCropInfo2(jsonFile);
end
if contains(fpath,'TESTappleRightEye.json')
    jsonFile=dir([path '/TESTappleRightEye.json']);
    output=getCropInfo2(jsonFile);
end
function output = getCropInfo2(jsonFile)
%Face to Facegrid
    rawPatientString=fileread(fullfile(jsonFile.folder,jsonFile.name));
    output=parse_json(rawPatientString);
    output.H=cell2mat(output.H);
    output.W=cell2mat(output.W);
    output.X=cell2mat(output.X);
    output.Y=cell2mat(output.Y);
    output.IsValid=cell2mat(output.IsValid);
end
end
