% TPA_ShowEventsRois
% Script to show how to use ROI and Event data structures.
% Select analysis directory that contains TPA_*.mat and BDA_*.mat files, load them and display.
% Inputs:
%       directory to be analysed
% Outputs:
%        view of the data

% Event structure description:
% strEvent.Type        = 1;             % ROI_TYPES.RECT 
% strEvent.Active      = true;          % designates if this pointer structure is in use
% strEvent.NameShow    = false;         % manage show name
% strEvent.zInd        = 1;             % location in Z stack
% strEvent.tInd        = 1;             % location in T stack
% strEvent.Position    = pos;           % rect position
% strEvent.xyInd       = xy;            % shape in xy plane
% strEvent.Name        = Name from the list and animal name;
% strEvent.TimeInd     = [start stop];  % time/frame indices
% strEvent.SeqNum      = 1;             % designates Event sequence number in one trial
% strEvent.Color       = [0 1 0];       % designates Event color


%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 28.03 07.01.18 UD     Removing TimeInd field - make event class manager .
% 19.09 14.10.14 UD     Adding more events
% 19.08 11.10.14 UD     Adding enumeration to event names and sequence nummber
% 18.12 11.07.14 UD     created
%-----------------------------

%%%
% Parameters
%%%
% directory where TPA and BDA files located (Change it if you need)
%analysisDir         = 'C:\Uri\DataJ\Janelia\Analysis\d13\14_08_14\';
analysisDir         = 'C:\LabUsers\Uri\Data\Janelia\Analysis\m2\4_4_14';
% special trial (repetition) to show (Change it if you need)
trialIndShow        = 11;
% frame rate ratio between Two Photon imaging and Behavior
frameRateRatio      = 6; % (do not touch)
% Common names to be converted to Ids
eventNameList      = {'Lift','Grab','Sup','Atmouth','Chew','Sniff','Handopen','Botharm','Tone','Table'}; % (do not touch)

%%%
% Load Two Photon ROI data
%%%
fileNames        = dir(fullfile(analysisDir,'TPA_*.mat'));
fileNum          = length(fileNames);
if fileNum < 1,
    error('TwoPhoton : Can not find data files in the directory %s. Check file or directory names.',analysisDir);
end;
[fileNamesRoi{1:fileNum,1}] = deal(fileNames.name);
fileNumRoi                  = fileNum;

allTrialRois                    = cell(fileNumRoi,1);
for trialInd = 1:fileNumRoi,
    fileToLoad                 = fullfile(analysisDir,fileNamesRoi{trialInd});
    usrData                    = load(fileToLoad);
    allTrialRois{trialInd}     = usrData.strROI;
end


%%%
% Load Behavioral Event data
%%%
fileNames        = dir(fullfile(analysisDir,'BDA_*.mat'));
fileNum          = length(fileNames);
if fileNum < 1,
    error('Behavior : Can not find data files in the directory %s. Check file or directory names.',analysisDir);
end;
[fileNamesEvent{1:fileNum,1}] = deal(fileNames.name);
fileNumEvent                  = fileNum;

allTrialEvents                = cell(fileNumEvent,1);
for trialInd = 1:fileNumEvent,
    fileToLoad                 = fullfile(analysisDir,fileNamesEvent{trialInd});
    usrData                    = load(fileToLoad);
    allTrialEvents{trialInd}   = usrData.strEvent;
end

%%%
% Convert Event names to Ids
%%%
% add field Id
eventNameList                  = lower(eventNameList);
for trialInd = 1:fileNumEvent,
    eventNum                   = length(allTrialEvents{trialInd});
    for m = 1:eventNum,
        eName                      = lower(allTrialEvents{trialInd}{m}.Name);
        eBool                      = strncmp(eName, eventNameList,3);
        eInd                       = find(eBool);
        if isempty(eInd),
            fprintf('W : Trial %d, Event %d has undefined name %s. Set Id = 0.\n',trialInd,m,allTrialEvents{trialInd}{m}.Name)
            eInd = 0;
        end
        allTrialEvents{trialInd}{m}.Id = eInd;
    end
end



%%%
% Extract specific trial data for Two Photon ROI
%%%
% check
if trialIndShow < 1 || trialIndShow > fileNumRoi, 
    error('Requested trial should be in range [1:%d]',fileNumRoi)
end
if trialIndShow < 1 || trialIndShow > fileNumEvent, 
    error('Requested trial should be in range [1:%d]',fileNumEvent)
end

% extract ROI dF/F data
roisPerTrialNum   = length(allTrialRois{trialIndShow});
if roisPerTrialNum < 1,
    error('Could not find ROI data for trial %d',trialIndShow)
end
dffData          = allTrialRois{trialIndShow}{1}.procROI; % actual data
[framNum,~]      = size(dffData);
dffDataArray     = repmat(dffData,1,roisPerTrialNum);
roiNames         = cell(1,roisPerTrialNum);
% collect
for m = 1:roisPerTrialNum,
    if isempty(allTrialRois{trialIndShow}{m}.procROI),
        error('Two Photon data is not complete. Can not find dF/F results.')
    end
    dffDataArray(:,m) = allTrialRois{trialIndShow}{m}.procROI;
    roiNames{m}       = allTrialRois{trialIndShow}{m}.Name;
end

%%%
% Extract specific trial data for Behavioral Events
%%%
% extract Event Time data
eventsPerTrialNum   = length(allTrialEvents{trialIndShow});
if eventsPerTrialNum < 1,
    warning('Could not find Event data for trial %d',trialIndShow);
end
timeData         = allTrialEvents{trialIndShow}{1}.tInd; % actual data
eventDataArray   = zeros(framNum,eventsPerTrialNum);
eventNames       = cell(1,eventsPerTrialNum);

% collect
for m = 1:eventsPerTrialNum,
%    timeInd     = allTrialEvents{trialIndShow}{m}.TimeInd;
    timeInd     = allTrialEvents{trialIndShow}{m}.tInd;
    timeInd     = round(timeInd./frameRateRatio); % transfers to time of the two photon
    timeInd     = max(1,min(framNum,timeInd));
    % assign to vector
    eventDataArray(timeInd(1):timeInd(2),m) = 1;
    eventNames{m} = sprintf('%s - %d',allTrialEvents{trialIndShow}{m}.Name, allTrialEvents{trialIndShow}{m}.SeqNum); 
end

%%%
% Show
%%%
timeImage       = 1:framNum;
figure(1),
plot(timeImage,dffDataArray),legend(roiNames)
xlabel('Time [Frame]'), ylabel('dF/F'), title(sprintf('Two Photon data for trial %d',trialIndShow))

figure(2),
plot(timeImage,eventDataArray),legend(eventNames)
xlabel('Time [Frame]'), ylabel('Events'), title(sprintf('Event duration data for trial %d',trialIndShow))





return
