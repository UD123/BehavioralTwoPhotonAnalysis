function Par = DTP_LoadRecords(Par,dataPath, FigNum)
%DTP_LoadRecords - load physiology data which must be in sync with image data in the directory.
% Inputs:
%   Par             - structure additional params
%	dataPath        - string specifies the experiment directory
%   FigNum          - display options
% Outputs:
%   Par             - additional params
%	strRecord.RecordedValues  - NxK image that conatins N data samples over K channels
%   strRecord.FrameStart      - nFrames x 1 frame start index (samples)

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 11.04 23.07.13 UD     delete start yfeedback data to prevent frame sync at the beginning.
% 11.01 09.07.13 UD     changing putput interface.
% 10.03 06.03.13 UD     Clear the interface. Redesign frame sync.
% 10.02 10.12.12 UD     Make ChanConfig according to indices.
% 10.01 27.11.12 UD     changing folder.
% 10.00 13.11.12 UD     Adapted for Maria.
%-----------------------------

if nargin < 1, Par =  DTP_ParInit; end;
if nargin < 2, 	dataPath = pwd; end
if nargin < 3, 	FigNum = 1; end

% extract
%ChanConfig                  = Par.ChanConfig;
usedPath                    = dataPath;

%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%

% global data 

%%%%%%%%%%%%%%%%%%%%%%
% Init Data container
%%%%%%%%%%%%%%%%%%%%%%
data.usedColors         = [];
data.currentPosition    = -1;
data.stimGhoustAxis     = [];
data.imageUndoStack     = [];
data.objects.zoom       = [];
% state.settingPosition   = 0;
% state.data              = 'noData';
data.preferedChannel    = -1;
data.recording.values   = [];
data.nextColIndex       = 1;

% init
data.files.lsd      = '';
data.files.dat      = '';
data.files.cfg      = '';
data.files.lsdPath  = usedPath;

%ImgData             = 0;

%function lsdBrowse_Callback(hObject, eventdata, handles)
%global data usedPath
%[FileName,PathName] = uigetfile(strcat(usedPath,'*.lsd'),'Select Line Scan Data File');
direc = dir(strcat(usedPath,'\*.prm')); filenames = {};
[filenames{1:length(direc),1}] = deal(direc.name);
if isempty(filenames),
	fprintf(' W: Selected path %s does not contains data files\n',usedPath);
    error(' Please check the directory E: , C:, Path')
end




%%%%%%%%%%%%%%%%%%%%%%
% Load Channel 2 - Neurons
%%%%%%%%%%%%%%%%%%%%%%
ChanNum                 = 1;
FileName                = filenames{ChanNum};
PathName                = usedPath;
stimFileLoc             = fullfile(PathName,FileName);


if(~strcmp('',data.files.dat))
	stimFileLoc = data.files.dat;
else
	stimFileLoc = strrep(stimFileLoc,'.prm','.dat');
%	stimFileLoc = strcat({data.files.lsdPath},stimFileLoc);
end


%%%%%%
% Load all the data
%%%%%%
[data,RecordedValues]   = DTP_ReadStimFile(data,stimFileLoc);

% Freq os the sampling
stimSampleRate          = data.recordingData.samplingRate; % Rate is like time Yoav's code
stimSampleTime          = 1/stimSampleRate;

% time required by DTP_FindFrameSync
Par.stimSampleTime      = stimSampleTime;


%%%%%%
% Determine Frame Sync
%%%%%%
[Par,FrameStart]         = DTP_FindFrameSync(Par,RecordedValues,FigNum);

ChanConfig               = Par.ChanConfig;

[recordNum,chanNum]      = size(RecordedValues);
if chanNum ~= length(ChanConfig),
   error('ChanConfig does not match number of recorded channels') 
end
chanName = cell(chanNum,1); chanIndx = zeros(1,chanNum);
for c = 1:chanNum,
    chanName{c} = ChanConfig{c}.Name;
    chanIndx(c) = ChanConfig{c}.ChanId;
end
    

%%%%%%
% Get image data
%%%%%%
imNamePattern               = '*_Ch2_*.tif';        % pattern that matches image names
imNameTest                  = fullfile(usedPath,imNamePattern);
imDirec                     = dir(imNameTest); imFilenames = {};
imNum                       = length(imDirec);
if imNum < 1,
    error('Can not find images in specified directory. Check directory name');
end;

[imFilenames{1:imNum,1}]    = deal(imDirec.name);
% check image params
imName                      = fullfile(usedPath,imFilenames{1});
% imInfoData                  = imfinfo(imName);
% height                      = imInfoData.Height;

% to ignore warning
[height,width]              = size(imread(imName));


% adjust to image row number
% blank_num                   = min(blank_num,height);
%blankValuesNum  = numel(blankValues );
blankImNum                      = length(FrameStart);
if imNum < blankImNum,
    txt = sprintf('Image number is less than blank number. Cutting blanks.');
    DTP_ManageText([], txt,   'W' ,0);
    blankImNum                  = imNum;
    FrameStart                  = FrameStart(1:blankImNum);
end;
if imNum > blankImNum,
    txt = sprintf('There are more images than blanks. Cutting images.');
    DTP_ManageText([], txt,   'E' ,0);
end;


DTP_ManageText([], sprintf('Image number found    : %d',imNum),     'I' ,0)
DTP_ManageText([], sprintf('Image blank number    : %d',blankImNum),'I' ,0)
DTP_ManageText([], sprintf('Image row number      : %d',height),    'I' ,0)
DTP_ManageText([], sprintf('Physiology total time : %5.2f [sec]',recordNum*stimSampleTime),  'I' ,0)


% fprintf('Expected Blank number : %d\n',imNum*height)
% fprintf('Blank number found    : %d\n',blank_num)

% output frame start time
Par.stimSampleTime      = stimSampleTime;
Par.chanName            = chanName;

% Output
Par.recordValue         = RecordedValues;
Par.frameStart          = FrameStart;
Par.recordNum           = recordNum;
Par.chanNum             = chanNum;

% show all data
if FigNum > 0 ,
    tt          = (1:recordNum)'*stimSampleTime;
    %frameStart  = FrameStart; %ft_ind(1:height:blank_num);
    %frameMarks  = zeros(size(tt));
    
	figure(FigNum),set(gcf,'Tag','AnalysisROI')
    plot(tt, RecordedValues),
    hold on;
    stem(tt(FrameStart),FrameStart*0+3,'k')
    hold off;
	title('Electro Data')
    %xlabel('Sample number'),
    xlabel('Time [sec]'),
    ylabel('Channel [Volt]')
    chanName{chanNum+1} = 'Frame Start';
    legend(chanName)
end;





return
