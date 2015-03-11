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
validTrialNum      = length(Par.DMB.EventFileNames);
if validTrialNum < 1,
    DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder. ',Par.DMB.EventDir),  'E' ,0);
    validTrialNum           = Par.DMT.ValidTrialNum;
    if validTrialNum < 1,
        DTP_ManageText([], sprintf('Multi Trial : No ROI data in folder %s. New event data will be created.',Par.DMT.RoiDir),  'E' ,0);
        return
    end
    Par             = ExpandEvents(Par);
    DTP_ManageText([], sprintf('Multi Trial : Manual Events will be created in folder %s. ',Par.DMB.EventDir),  'W' ,0);

else
    DTP_ManageText([], sprintf('Multi Trial : Found %d Events Analysis files. ',validTrialNum),  'I' ,0);
end



%%%%%%%%%%%%%%%%%%%%%%
% Setup & Get important parameters for event
%%%%%%%%%%%%%%%%%%%%%%
isOK                  = false; % support next level function
options.Resize        ='on';
options.WindowStyle   ='modal';
options.Interpreter   ='none';
prompt                = {'Event Name',...
                         'Event Start and Duration [Video Frame Numbers]',...            
                        };
name                ='Add New Event to all trials:';
numlines            = 1;
defaultanswer       ={'Tone',num2str([100 50])};
answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
if isempty(answer), return; end;


% try to configure
newEventName        = answer{1};
newEventFrameNum    = str2num(answer{2});

% check
if numel(newEventFrameNum) ~= 2,
    errordlg('You must provide two frame numbers for event start and duration')
    return
end

% prepare ROI prototype 
roiLast.Type        = 1; % ROI_TYPES.RECT should be
roiLast.Active      = true;   % designates if this pointer structure is in use
roiLast.NameShow    = false;       % manage show name
roiLast.zInd        = 1;           % location in Z stack
roiLast.tInd        = 1;           % location in T stack
pos                 = [newEventFrameNum(1) 50 newEventFrameNum(2) 100];
xy                  = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
roiLast.Position    = pos;   
roiLast.xyInd       = xy;          % shape in xy plane
roiLast.Name        = newEventName;
roiLast.TimeInd     = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
roiLast.SeqNum      = 1;           % designates Event number
roiLast.Color       = [0 1 0];           % designates Event color
        
                
                
%%%%%%%%%%%%%%%%%%%%%%
% Run over all files/trials and load the Analysis data
%%%%%%%%%%%%%%%%%%%%%%
for trialInd = 1:validTrialNum,
    
        [Par.DMB, strEvent]         = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
        % this code helps with sequential processing of the ROIs: use old one in the new image
        numEvent                    = length(strEvent);
        strEvent{numEvent + 1}      = roiLast;
        
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
for m = 1:validTrialNum
    Par.DMB.EventFileNames{m}  = sprintf('BDA_%s',Par.DMT.RoiFileNames{m}(5:end));
end
return

