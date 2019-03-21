function [data,recordedValues] =  TPA_ReadStimFile(data,stimFileLocation)
% Loads different stimulas files
%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 21.21 15.12.15 UD     Adopted from TwoPhotonTSeries_1604
% 10.01 29.06.13 UD     data is local.
% 10.00 13.11.12 UD     Adapted for Maria.
% 03.0B 09.02.10 UD     Blanking is taking outside
% 03.0A 09.02.10 UD     Interpolation removed and CT_  renamed
%-----------------------------
numOfFiles = size(stimFileLocation,1);
recordedValues = []; 
data = initPrefferedChannel(data,stimFileLocation);
for i=1:numOfFiles
    [data,recordedValuesTmp] = stimFileReader(data,stimFileLocation);
    recordedValues = [recordedValues ; recordedValuesTmp];
end


return;


%the stimuli file is built of columns - each one matches a channel that was
%read in the triggerSync software.
function [data,recordedValues] = stimFileReader(data,stimFileLocation)
%global data
stimFileContent = [];
stimFH = fopen(stimFileLocation,'r','b');
if(stimFH == -1)
    return;
end
fread(stimFH,616 ,'int8');% header
numOfColumns        = fread(stimFH,1,'int32');
pointsPerColumn     = fread(stimFH,1,'int32') ;
recordedValues      = fread(stimFH,pointsPerColumn*numOfColumns,'float32');
fclose(stimFH);


recordedValues = reshape(recordedValues, pointsPerColumn, numOfColumns);

% blankingContent = [];
% for cI=1:numOfColumns
%     if(data.recordingData.activeChannels(cI) == data.preferedChannel)
%         data.recording.preferedChannelIndex = cI;
%         stimFileContent = recordedValues(:, cI);
%     end
%     if(data.recordingData.activeChannels(cI) == 7) %7 is the blanking channel
%         data.recording.blankingChannelIndex = cI;
%         blankingContent = recordedValues(:, cI);
%     end
% end
% % protect when no optic data is found
% if ~isempty(stimFileContent),
%     if(~isempty(blankingContent))
%         %UD stimFileContent = stimFileContent(blankingContent < 1.0);
%     end
%     data.recording.values = [data.recording.values ; recordedValues];
% end;


function data = initPrefferedChannel(data,stimFileLocation)
%global data
data.recordingData = getRecordingData(stimFileLocation);
if(data.preferedChannel < 0) && false, % UD
    if(numel(data.recordingData.activeChannels) > 1)
        channelsString = num2str(data.recordingData.activeChannels(1));
        for cI=2:numel(data.recordingData.activeChannels)
            channelsString = [channelsString ', ' num2str(data.recordingData.activeChannels(cI))];
        end
        prompt = {['the acquired channels are ' channelsString ', enter the relevant channel number (7 is the blanking signal)']};
        dlg_title = 'Channel selection';
        def = {num2str(data.recordingData.activeChannels(1))};
        answer = inputdlg(prompt,dlg_title,1,def);
        data.preferedChannel = str2num(answer{1});
    else
        data.preferedChannel = data.recordingData.activeChannels(1);
    end
end


function recordingData = getRecordingData(stimFlieLocation)
prmFileLoc = strrep(stimFlieLocation,'.dat','.prm');
prmFH = fopen(prmFileLoc,'r');
recordingData = {};
recordingData.samplingRate = 0.0001;
recordingData.activeChannels = [];
if(prmFH == -1)
    return;
end
result = [];
while(1)
    theLine = fgetl(prmFH);
    
    [token, remain] = strtok(theLine, '=');
    if(strcmp(token,'Acquisition Rate'))
        theRate = strtok(remain,'=');
        recordingData.samplingRate = str2double(theRate);
    end
    if(strcmp(token,'[Channel Status]'))
        for channelNum = 0:7
            theLine = fgetl(prmFH);
            if(isempty(findstr(theLine,'FALSE')))
                recordingData.activeChannels = [recordingData.activeChannels ; channelNum];
            end
        end
        break;
    end
end
fclose(prmFH);

