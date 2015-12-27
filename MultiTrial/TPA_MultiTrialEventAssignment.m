function [Par] = TPA_MultiTrialEventAssignment(Par,FigNum)
% TPA_MultiTrialEventAssignment - loads Event data from all trials.
% Ask user about new event info.
% Adds it to the event list for each trial.
% Inputs:
%   Par         - control structure 
%  Event        - data bases
% Outputs:
%   Par         - control structure updated
%  Event        - data bases

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 21.08 03.11.15 UD     Number of files 
% 21.07 13.10.15 UD     Adjusting to EventManager  and ValidTrials according to number of BDA files
% 20.05 19.05.15 UD     Use VideoFile numbers to create new events
% 20.04 17.05.15 UD     Adjusted to support new event structure
% 19.32 12.05.15 UD     Specific trials
% 17.08 05.03.14 UD     Extend to all video files. Fixing bug in old index file generation - inpolygon must be run again
% 17.02 10.03.14 UD     Created
%-----------------------------

if nargin < 1,  error('Need Par structure');        end;
if nargin < 2,  FigNum      = 11;                  end;


% attach
%global SData SGui

%%%%%%%%%%%%%%%%%%%%%%
% Load Trial
%%%%%%%%%%%%%%%%%%%%%%
Par.DMT                     = Par.DMT.CheckData(true);
if isa(Par.DMT,'TPA_DataManagerPrarie'),
    validTrialNum           = Par.DMT.ValidTrialNum;
    Par                     = ExpandEvents(Par);
else
    validTrialNum      = length(Par.DMB.EventFileNames);
end
%validTrialNum      = Par.DMB.VideoFileNum;
if validTrialNum < 1,
    DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder. ',Par.DMB.EventDir),  'E' ,0);
    validTrialNum           = Par.DMT.ValidTrialNum;
    if validTrialNum < 1,
        DTP_ManageText([], sprintf('Multi Trial : No ROI data in folder %s. New event data will be created.',Par.DMT.RoiDir),  'E' ,0);
        %return
    end
    Par             = ExpandEvents(Par);
    DTP_ManageText([], sprintf('Multi Trial : Manual Events will be created in folder %s. ',Par.DMB.EventDir),  'W' ,0);
    validTrialNum   = Par.DMB.EventFileNum;

else
    DTP_ManageText([], sprintf('Multi Trial : Found %d Events Analysis files. ',validTrialNum),  'I' ,0);
end

%%%%%%%%%%%%%%%%%%%%%%
% Guess numbmer of frames in Behavioral data
%%%%%%%%%%%%%%%%%%%%%%
maxBehaveFrameNum       = 2400;
% detect Prarie experiment
if isa(Par.DMT,'TPA_DataManagerPrarie'),
    maxBehaveFrameNum = size(Par.DMT.VideoFileNames,1);
end
DTP_ManageText([], sprintf('Multi Trial : Found %d behavioral frames. ',maxBehaveFrameNum),  'I' ,0);


%%%%%%%%%%%%%%%%%%%%%%
% Setup & Get important parameters for event
%%%%%%%%%%%%%%%%%%%%%%
isOK                  = false; % support next level function
options.Resize        ='on';
options.WindowStyle   ='modal';
options.Interpreter   ='none';
prompt                = {'Event Name',...
                         'Event Start and Duration [Video Frame Numbers]',...            
                         'Trial Numbers [any subset]',...            
                        };
name                = 'Add New Event to specific trials:';
numlines            = 1;
defaultanswer       ={'Tone',num2str([100 50]),num2str((1:validTrialNum))};
answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
if isempty(answer), return; end;


% try to configure
newEventName        = answer{1};
newEventFrameNum    = str2num(answer{2});
newEventTrialInd    = str2num(answer{3});

% check
if numel(newEventFrameNum) ~= 2,
    errordlg('You must provide two frame numbers for event start and duration')
    return
end
if sum(newEventFrameNum) > maxBehaveFrameNum,
    errordlg('Event frame numbers exceed max number of valid frames %d',maxBehaveFrameNum)
    return
end
if numel(newEventTrialInd) < 1,
    errordlg('You must provide number of trial indexes')
    return
end
if min(newEventTrialInd) < 1,
    errordlg('Minimal trial number should be 1')
    return
end
if max(newEventTrialInd) > validTrialNum,
    errordlg('Maximal trial number should be %d',validTrialNum)
    return
end

eventLast            = TPA_EventManager();

% prepare ROI prototype 
eventLast.Type        = eventLast.ROI_TYPES.RECT; % ROI_TYPES.RECT should be
%eventLast.Active      = true;   % designates if this pointer structure is in use
%eventLast.NameShow    = false;       % manage show name
%eventLast.zInd        = 1;           % location in Z stack
%eventLast.tInd        = 1;           % location in T stack
pos                     = [newEventFrameNum(1) 50 newEventFrameNum(2) 100];
xy                      = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
%eventLast.Position    = pos;   
%eventLast.xyInd       = xy;          % shape in xy plane
eventLast.Name        = newEventName;
eventLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
eventLast.SeqNum      = 1;           % designates Event number
eventLast.Color       = [0 1 0];           % designates Event color
eventLast.Data        = zeros(maxBehaveFrameNum,2);        
eventLast.Data(eventLast.tInd(1):eventLast.tInd(2),:) = 50; % no reason               
                
%%%%%%%%%%%%%%%%%%%%%%
% Run over all files/trials and load the Analysis data
%%%%%%%%%%%%%%%%%%%%%%
for trialInd = 1:validTrialNum,
    
        % check if included
        if ~any(trialInd == newEventTrialInd), continue; end;
    
        [Par.DMB, strEvent]         = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
        % this code helps with sequential processing of the ROIs: use old one in the new image
        % add new event
        %strEvent{end+1}                    = Add(strEvent);
        strEvent{end+1}             = eventLast;                 
        Par.DMB                     = Par.DMB.SaveAnalysisData(trialInd,'strEvent',strEvent);


end
DTP_ManageText([], sprintf('Multi Trial : New Event assignment completed.'),  'I' ,0);

return

%%%%%%%%%%%%%%%%%%%%%%%%%
% Expand for empty events
%%%%

function Par = ExpandEvents(Par)

validTrialNum           = Par.DMT.RoiFileNum;
Par.DMB.EventDir        = Par.DMT.RoiDir;
Par.DMB.EventFileNum    = validTrialNum;
for m = 1:validTrialNum,
    if isempty(Par.DMT.RoiFileNames{m}), continue; end;
    Par.DMB.EventFileNames{m}  = sprintf('BDA_%s',Par.DMT.RoiFileNames{m}(5:end));
end
return

