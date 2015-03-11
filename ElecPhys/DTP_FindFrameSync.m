function [Par,FrameStart] = DTP_FindFrameSync(Par,RecordedValues,FigNum)
%DTP_FindFrameSync - uses physiology data from different experiments and different configurations
% and determines the frame sync
% Inputs:
%   Par             - structure additional params
%	RecordedValues  - N x K matrix of K channels 
%   FigNum - display options
% Outputs:
%   Par             - additional params
%	FrameStart      - Mx1 vector of frame start indices

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 11.05 30.07.13 UD     created to support multiple configurations .
%-----------------------------

if nargin < 1,  Par =  [];              end;
if nargin < 2, 	RecordedValues = randn(1000,4);             end;
if nargin < 3, 	FigNum = 1;             end;


%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%
%blankValThr                  = 0.1; % determines threshold of the blanking signal
yFeedbackValThr              = 0;    % when to detect the y feedback signal
FrameStart                   = 1;
%syncType                     = 'ROI Galvo + Blank';
Par.syncType                     = 'ROI Galvo Only';

%%%%%%%%%%%%%%%%%%%%%%
% Select appropriate configuration
%%%%%%%%%%%%%%%%%%%%%%
switch Par.syncType,
    case 'Fast Z',
        Par.ChanConfig{1}.Name      = 'Pockel';
        Par.ChanConfig{1}.ChanId    = 2; % Id in the system
        Par.ChanConfig{2}.Name      = 'Y feedback';
        Par.ChanConfig{2}.ChanId    = 3;
        Par.ChanConfig{3}.Name      = 'Piezo 1';    % electro physiology data
        Par.ChanConfig{3}.ChanId    = 5;
        Par.ChanConfig{4}.Name      = 'Piezo 2';    % electro physiology data
        Par.ChanConfig{4}.ChanId    = 6;
        Par.ChanConfig{5}.Name      = 'Electrophysiology';
        Par.ChanConfig{5}.ChanId    = 7;
        
    case 'ROI Galvo Only',
        Par.ChanConfig{1}.Name      = 'Pockel';
        Par.ChanConfig{1}.ChanId    = 2; % Id in the system
        Par.ChanConfig{2}.Name      = 'Y feedback';
        Par.ChanConfig{2}.ChanId    = 3;
        Par.ChanConfig{3}.Name      = 'Piezo 1';    % electro physiology data
        Par.ChanConfig{3}.ChanId    = 5;
        Par.ChanConfig{4}.Name      = 'Piezo 2';    % electro physiology data
        Par.ChanConfig{4}.ChanId    = 6;
        Par.ChanConfig{5}.Name      = 'Electrophysiology';
        Par.ChanConfig{5}.ChanId    = 7;

    case 'ROI Galvo + Blank',
        ii = 1;
        Par.ChanConfig{ii}.Name      = 'Blanking';       
        Par.ChanConfig{ii}.ChanId    = 1;     ii = ii + 1; % Id in the system 
        Par.ChanConfig{ii}.Name      = 'Pockel';         
        Par.ChanConfig{ii}.ChanId    = 2;     ii = ii + 1; % Id in the system
        Par.ChanConfig{ii}.Name      = 'Y feedback';     
        Par.ChanConfig{ii}.ChanId    = 3;     ii = ii + 1;
        Par.ChanConfig{ii}.Name      = 'Piezo 1';         % electro physiology data
        Par.ChanConfig{ii}.ChanId    = 5;     ii = ii + 1;
        Par.ChanConfig{ii}.Name      = 'Piezo 2';         % electro physiology data
        Par.ChanConfig{ii}.ChanId    = 6;     ii = ii + 1;
        Par.ChanConfig{ii}.Name      = 'Electrophysiology'; 
        Par.ChanConfig{ii}.ChanId    = 7;     ii = ii + 1;
        
    otherwise
        error('Unknwon syncType')
end;


% extract
ChanConfig                  = Par.ChanConfig;
stimSampleTime              = Par.stimSampleTime;
stimSampleRate              = 1/stimSampleTime;


%%%%%%
% get all the data
%%%%%%
[recordNum,chanNum]         = size(RecordedValues);



if chanNum ~= length(ChanConfig),
   error('ChanConfig does not match number of recorded channels. Please determine correct Par.syncType.') 
end
chanName = cell(chanNum,1); chanIndx = zeros(1,chanNum);
for c = 1:chanNum,
    chanName{c} = ChanConfig{c}.Name;
    chanIndx(c) = ChanConfig{c}.ChanId;
end

% sort them according to the channel order
[chanIndx,ind]          = sort(chanIndx);
[chanName{1:chanNum}]   = deal(chanName{ind});
    

% show data
% show all data
if FigNum > 0 ,  

tt          = (1:recordNum)'*stimSampleTime;
figure(FigNum),set(gcf,'Tag','AnalysisROI'),clf;
plot(tt, RecordedValues),
hold on;
hFrame = stem(tt(FrameStart),FrameStart*0+3,'k');
hold off;
title('Electro Data')
%xlabel('Sample number'),
xlabel('Time [sec]'),
ylabel('Channel [Volt]')
chanName{chanNum+1} = 'Frame Start';
legend(chanName)

end;

if recordNum < 10, 
    error('Can not find enough data');
end;


% stimValuesNum   = numel(stimValues );
% blankValuesNum  = numel(blankValues );


% time to estimates thresholds - should not include data end

startSignalIgnorNum  = round(0.09 * stimSampleRate); % ignore start time effects
signalEstimSampleNum = round(2 * stimSampleRate);    % ignore end effects

%%%%%%
% get pockels data
%%%%%%
blankId         = find(strcmp(chanName,'Pockel'));
blankValues     = RecordedValues(:,blankId);

% above
blankValThr      = mean(blankValues(startSignalIgnorNum:signalEstimSampleNum)); %blankValues < blankValThr;

if  blankValThr < 0.01,
    error('LoadRecords:Blank Signal : The signal is too low or is not connected')
end;
% if mean(blankValues(1:5)) < blankValThr,
%     warning('LoadRecords:BlankSignal',' : Blank signal starts from low value. Could indicate sync problem')
% end;
% if mean(blankValues(end-5:end)) < blankValThr,
%     warning('LoadRecords:BlankSignal',' : Blank signal terminates with low value. Could indicate sync problem')
% end;


%%%%%%
% get y feedback data
%%%%%%
yFeedbackId         = find(strcmp(chanName,'Y feedback'));
yFeedbackValues     = RecordedValues(:,yFeedbackId);

if max(yFeedbackValues) < yFeedbackValThr,
    error('LoadRecords:Y Feedback : The signal is too low or is not connected')
end;
% if mean(yFeedbackValues(1:5)) < yFeedbackValThr,
%     warning('LoadRecords:Y Feedback : Y Feedback signal starts from low value. Could indicate sync problem')
% end;
% if mean(yFeedbackValues(end-5:end)) < yFeedbackValThr,
%     warning('LoadRecords:BlankSignal',' : Blank signal terminates with low value. Could indicate sync problem')
% end;


%%%%%%
% extract blanking signals
%%%%%%
% there are experiments that it starts from high values - lets ignore them
yFeedbackValuesSmooth = yFeedbackValues; 
numSamplesToDelete    = ceil(0.024 * stimSampleRate); % almost one frame
yFeedbackValuesSmooth(1:numSamplesToDelete)   = 0;


% smooth
alpha = 0.3;
yFeedbackValuesSmooth = filtfilt(alpha,[1 -(1-alpha)],yFeedbackValuesSmooth);
yFeedbackGrad         = abs(gradient(yFeedbackValuesSmooth));



% estimate threshold values in the feedback in order to get the transitions correctly
estSupportInd          = 1000:min(signalEstimSampleNum,ceil(recordNum*0.3));
maxVal                 = max(yFeedbackGrad(estSupportInd));
minVal                 = min(yFeedbackGrad(estSupportInd));
diffMaxMin             = maxVal - minVal;
%maxPeakPos             = find(yFeedbackValuesSmooth(2:end-1) > maxVal & yFeedbackValuesSmooth(1:end-2) < yFeedbackValuesSmooth(2:end-1) & yFeedbackValuesSmooth(2:end-1) >= yFeedbackValuesSmooth(3:end));

% min peak position designate possible location of the v. syncs
maxPeakPos             = find(yFeedbackGrad(2:end-1) > maxVal / 2 & ...    
                              yFeedbackGrad(1:end-2) < yFeedbackGrad(2:end-1) & ...
                              yFeedbackGrad(2:end-1) >= yFeedbackGrad(3:end));

% checks
vertSyncNumFromYfeed     = numel(maxPeakPos);
DTP_ManageText([], sprintf('yFeedback - Vertical Frame num    : %d',vertSyncNumFromYfeed),  'I' ,0);

vertSyncInd         = maxPeakPos;
vertSyncNum         = numel(vertSyncInd);                   


%%%%%%
% Sync YFeedback with Blanking when YFeedback detects fields
%%%%%%

if strcmp(Par.syncType, 'ROI Galvo Only') || strcmp(Par.syncType,'ROI Galvo + Blank'),
    
    % WORKS GOOD FOR ROI Galvo Only
    
    
% maxPeakPos - encodes row info not a frame sync
% in order to fet a frame sync we need to find blanks and interval between them - field length
        

% estimate field time
fieldSampleNum      = median(diff(vertSyncInd));
searchNum           = round(0.35*fieldSampleNum); % less than half field

% find all places where there is a Vertical Sync but no Blanking before and after at least fieldSampleNum
blankBool          = blankValues > blankValThr;
validBool          = vertSyncInd > 0;
for k = 1:vertSyncNum,
    validBool(k)   = all(blankBool(vertSyncInd(k)-searchNum:vertSyncInd(k)+searchNum) == false);
end;
vertSyncInd         = vertSyncInd(validBool);
vertSyncNum         = length(vertSyncInd);
if vertSyncNum < 10,
    error('LoadRecords:FindFrameSync: Too many syncs removed')
end;

end;

%%%%%%
% Sync YFeedback with Blanking
%%%%%%
%if strcmp(Par.syncType, 'Fast Z'),
    
    % WORKS GOOD FOR Fast Z
    
% at the beginning - frame start should begin after blanking
% determine when the blank signal is stopped     
firstBlankInd    = find(blankValues > blankValThr,1,'first');
if isempty(firstBlankInd),
    error('LoadRecords:Blank Values: Major problem in signal connections - 1.')    
end;

% valid frame start positions
ii               = find(vertSyncInd > firstBlankInd);
if isempty(ii),
    error('LoadRecords:Blank Values: No frame syncs after first blank.')    
end;
vertSyncInd             = vertSyncInd(ii);

% determine when the blank signal is stopped     
lastBlankInd    = find(blankValues > blankValThr,1,'last');
if isempty(lastBlankInd),
    error('LoadRecords:Blank Values: Can not find last blank.')    
end;

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
    
%end;


% Output
FrameStart                      = vertSyncInd; %ft_ind(1:height:vertSyncNum);

txt = sprintf('Found %d Frame Starts.',length(FrameStart));
DTP_ManageText([], txt,   'I' ,0);


% show all data
if FigNum < 1 , return; end;

set(hFrame,'xdata',tt(FrameStart),'ydata',FrameStart*0+3);


return;

