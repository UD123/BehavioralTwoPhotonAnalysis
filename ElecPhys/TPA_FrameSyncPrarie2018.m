function  [Par,FrameStart] = TPA_FrameSyncPrarie2018(Par,RecordedValues)
%TPA_FrameSyncPrarie2018 - Prarie 2018 selection frame sync for resonant scanning.
% Y-Feedback looks good with sharp rise times. Pockel designates end of the sequence.
% Inputs:
%   Par             - structure additional params
%	RecordedValues  - N x K matrix of K channels
% Outputs:
%   Par             - additional params
%	FrameStart      - Mx1 vector of frame start indices

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 28.13 19.03.18 UD     Fadi  WTF
% 16.04 27.10.14 UD     New frame sync for Maria
%-----------------------------


% time to estimates thresholds - should not include data end

%%%%%%
% params
%%%%%%

chanName             = Par.chanName;
stimSampleTime       = Par.stimSampleTime;
stimSampleRate       = 1/stimSampleTime;


startSignalIgnorNum  = round(0.09 * stimSampleRate); % ignore start time effects
signalEstimSampleNum = round(2 * stimSampleRate);    % ignore end effects

[recordNum,chanNum]  = size(RecordedValues);


%%%%%%
% get pockels data
%%%%%%
blankId         = find(strcmp(chanName,'Blanking'));
blankValues     = RecordedValues(:,blankId);

% above
blankValThr      = mean(blankValues(startSignalIgnorNum:signalEstimSampleNum)); %blankValues < blankValThr;
if  blankValThr < 0.01
    error('LoadRecords:Blank Signal : The signal is too low or is not connected')
end

% find last pockel index
%lastPockelPos   = find(blankValues > blankValThr,1,'last');


%%%%%%
% get y feedback data
%%%%%%

yFeedbackId         = find(strcmp(chanName,'Y feedback'));
yFeedbackValues     = RecordedValues(:,yFeedbackId);
yFeedbackValThr     = mean(yFeedbackValues(startSignalIgnorNum:signalEstimSampleNum)); %blankValues < blankValThr;

if yFeedbackValThr < -0.5,
    error('LoadRecords:yFeedbackValThr Signal : The signal is too low or is not connected')
end

% if max(yFeedbackValues) < yFeedbackValThr,
%     error('LoadRecords:Y Feedback : The signal is too low or is not connected')
% end;
% if mean(yFeedbackValues(1:5)) < yFeedbackValThr,
%     warning('LoadRecords:Y Feedback : Y Feedback signal starts from low value. Could indicate sync problem')
% end;
% if mean(yFeedbackValues(end-5:end)) < yFeedbackValThr,
%     warning('LoadRecords:BlankSignal',' : Blank signal terminates with low value. Could indicate sync problem')
% end;
%
%

%%%%%%
% extract blanking signals
%%%%%%
% % there are experiments that it starts from high values - lets ignore them
% yFeedbackValuesSmooth = yFeedbackValues;
% numSamplesToDelete    = ceil(0.024 * stimSampleRate); % almost one frame
% yFeedbackValuesSmooth(1:numSamplesToDelete)   = 0;
%
%
% smooth
alpha = 0.3;
yFeedbackValuesSmooth = filtfilt(alpha,[1 -(1-alpha)],yFeedbackValues);
yFeedbackGrad         = abs(gradient(yFeedbackValuesSmooth));
%
%

% estimate threshold values in the feedback in order to get the transitions correctly
estSupportInd          = 1000:min(signalEstimSampleNum,ceil(recordNum*0.3));
maxVal                 = max(yFeedbackGrad(estSupportInd));
% minVal                 = min(yFeedbackGrad(estSupportInd));
% diffMaxMin             = maxVal - minVal;
% %maxPeakPos             = find(yFeedbackValuesSmooth(2:end-1) > maxVal & yFeedbackValuesSmooth(1:end-2) < yFeedbackValuesSmooth(2:end-1) & yFeedbackValuesSmooth(2:end-1) >= yFeedbackValuesSmooth(3:end));
%
% min peak position designate possible location of the v. syncs
maxPeakPos             = find(yFeedbackGrad(2:end-1) > maxVal / 2 & ...
                              yFeedbackGrad(1:end-2) < yFeedbackGrad(2:end-1) & ...
                              yFeedbackGrad(2:end-1) >= yFeedbackGrad(3:end));
%

% % sync pos
% blankBool               = blankValues > blankValThr;
% maxPeakPos              = find(blankBool(1:end-1) & ~blankBool(2:end));


% checks
vertSyncNumFromYfeed    = numel(maxPeakPos);
DTP_ManageText([], sprintf('yFeedback - Vertical Frame num    : %d',vertSyncNumFromYfeed),  'I' ,0);
vertSyncInd             = maxPeakPos;


%%%%%%
% Sync YFeedback with Blanking when YFeedback detects fields
%%%%%%

%if strcmp(Par.syncType, 'ROI Galvo Only') || strcmp(Par.syncType,'ROI Galvo + Blank'),

% WORKS GOOD FOR ROI Galvo Only


% maxPeakPos - encodes row info not a frame sync
% in order to fet a frame sync we need to find blanks and interval between them - field length


% % estimate field time
% fieldSampleNum          = median(diff(vertSyncInd));
% searchNum               = round(0.85*fieldSampleNum); % less than field
% % check the last one
% if (vertSyncInd(end) + searchNum) > recordNum, vertSyncInd = vertSyncInd(1:end-1); end;
% vertSyncNum             = numel(vertSyncInd);
% 
% 
% % find all places where there is a Vertical Sync but no Blanking before and after at least fieldSampleNum
% %blankBool               = blankValues > blankValThr;
% validBool               = vertSyncInd > 0;
% for k = 1:vertSyncNum,
%     %validBool(k)        = all(blankBool(vertSyncInd(k)-searchNum:vertSyncInd(k)+searchNum) == false);
%     validBool(k)        = all(blankBool(vertSyncInd(k)+1:vertSyncInd(k)+searchNum) == false);
% end;
% vertSyncInd             = vertSyncInd(validBool);
% vertSyncNum             = length(vertSyncInd);
% if vertSyncNum < 10,
%     error('LoadRecords:FindFrameSync: Too many syncs removed')
% end;

%end;

%%%%%%
% Sync YFeedback with Blanking
%%%%%%
%if strcmp(Par.syncType, 'Fast Z'),

% WORKS GOOD FOR Fast Z

% at the beginning - frame start should begin after blanking
% determine when the blank signal is stopped
firstBlankInd    = find(blankValues > blankValThr,1,'first');
if isempty(firstBlankInd)
    error('LoadRecords:Blank Values: Major problem in signal connections - 1.')
end

% valid frame start positions
ii               = find(vertSyncInd > firstBlankInd);
if isempty(ii)
    error('LoadRecords:Blank Values: No frame syncs after first blank.')
end
vertSyncInd             = vertSyncInd(ii);

% determine when the blank signal is stopped
lastBlankInd    = find(blankValues > blankValThr,1,'last');
if isempty(lastBlankInd)
    error('LoadRecords:Blank Values: Can not find last blank.')
end

% count all the vertical that have blanking inside +1 to add last frame
vertSyncNum             = numel(vertSyncInd);
vertSyncNumCut          = numel(find(vertSyncInd < lastBlankInd)) + 1;
if vertSyncNum <= vertSyncNumCut,
    vertSyncNumCut = vertSyncNum;
    %warning('LoadRecords:Vertical Sync: Blanking has shorter length than Vertical Sync.')
    txt = sprintf('Blanking has shorter length than yFeedback. Cutting blanks.');
    DTP_ManageText([], txt,   'W' ,0);
    
end;
vertSyncNum       = vertSyncNumCut;
vertSyncInd       = vertSyncInd(1:vertSyncNum);




% Deal with YFeedback and blanking does not appear
% applicable when Z-Stack is in the move - we have two frame lost

% estimate frame time
frameSampleNum   = median(diff(vertSyncInd));
searchNum        = round(0.75*frameSampleNum);

% find all places where there is a Vertical Sync but no Blanking before at least frameSampleNum
blankBool          = blankValues > blankValThr;
validBool          = vertSyncInd > 0;
for k = 1:vertSyncNum,
    validBool(k)   = any(blankBool(vertSyncInd(k)-searchNum:vertSyncInd(k)));
end;
vertSyncInd         = vertSyncInd(validBool);
vertSyncNum         = length(vertSyncInd);
if vertSyncNum < 10,
    error('LoadRecords:FindFrameSync: Too many syncs removed')
end;

% Output
FrameStart              = vertSyncInd; %ft_ind(1:height:vertSyncNum);


return

