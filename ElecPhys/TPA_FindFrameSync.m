function [Par,FrameStart, RecordedValues] = TPA_FindFrameSync(Par,RecordedValues,FigNum)
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
% 28.13 19.03.18 UD     Fadi  WTF
% 24.07 25.10.16 UD     Fadi frame sync is inverted + fixing number of frames
% 21.21 15.12.15 UD     Adopted from TwoPhotonTSeries_1604
% 16.04 27.10.14 UD     New frame sync for Maria
% 11.05 30.07.13 UD     created to support multiple configurations .
%-----------------------------

if nargin < 1,  Par                 = DTP_ParInit;      end
if nargin < 2, 	RecordedValues      = randn(1000,4);    end
if nargin < 3, 	FigNum              = 1;                end


%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%
%blankValThr                  = 0.1; % determines threshold of the blanking signal
% yFeedbackValThr              = -1;    % when to detect the y feedback signal
% FrameStart                   = 1;

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
        
    case 'System 2014',
        Par.ChanConfig{1}.Name      = 'Blanking';
        Par.ChanConfig{1}.ChanId    = 0;
        Par.ChanConfig{2}.Name      = 'Pockel';
        Par.ChanConfig{2}.ChanId    = 1; % Id in the system
        Par.ChanConfig{3}.Name      = 'Y feedback';
        Par.ChanConfig{3}.ChanId    = 2;
        Par.ChanConfig{4}.Name      = 'Piezo 1';    % electro physiology data
        Par.ChanConfig{4}.ChanId    = 5;
        Par.ChanConfig{5}.Name      = 'Piezo 2';    % electro physiology data
        Par.ChanConfig{5}.ChanId    = 6;
        Par.ChanConfig{6}.Name      = 'Electrophysiology';
        Par.ChanConfig{6}.ChanId    = 7;
        
    case 'Resonant 2014'
        Par.ChanConfig{1}.Name      = 'Blanking';
        Par.ChanConfig{1}.ChanId    = 0;
        Par.ChanConfig{2}.Name      = 'Pockel';
        Par.ChanConfig{2}.ChanId    = 1; % Id in the system
        Par.ChanConfig{3}.Name      = 'Y feedback';
        Par.ChanConfig{3}.ChanId    = 2;
        Par.ChanConfig{4}.Name      = 'Piezo 1';    % electro physiology data
        Par.ChanConfig{4}.ChanId    = 5;
        Par.ChanConfig{5}.Name      = 'Piezo 2';    % electro physiology data
        Par.ChanConfig{5}.ChanId    = 6;
        Par.ChanConfig{6}.Name      = 'Electrophysiology';
        Par.ChanConfig{6}.ChanId    = 7;
        
    case 'Prarie 2018'
        Par.ChanConfig{1}.Name      = 'Pockel';
        Par.ChanConfig{1}.ChanId    = 0; % Id in the system
        Par.ChanConfig{2}.Name      = 'Blanking';
        Par.ChanConfig{2}.ChanId    = 1;
        Par.ChanConfig{3}.Name      = 'Y feedback';
        Par.ChanConfig{3}.ChanId    = 2;
        Par.ChanConfig{4}.Name      = 'Piezo 1';    % electro physiology data
        Par.ChanConfig{4}.ChanId    = 5;
        Par.ChanConfig{5}.Name      = 'Electrophysiology';
        Par.ChanConfig{5}.ChanId    = 7;
        
    case 'Prarie 1 channel'
        Par.ChanConfig{1}.Name      = 'Electrophysiology';
        Par.ChanConfig{1}.ChanId    = 1;
        
        % cut the records
        RecordedValues              = RecordedValues(:,end);
       
        
    otherwise
        error('Unknwon syncType')
end


% extract
ChanConfig                  = Par.ChanConfig;
%stimSampleRate              = 1/stimSampleTime;


%%%%%%
% get all the data
%%%%%%
[recordNum,chanNum]         = size(RecordedValues);
if recordNum < 10,     error('Can not find enough data'); end;

if chanNum ~= length(ChanConfig)
    error('ChanConfig does not match number of recorded channels. Please determine correct Par.syncType.')
end
chanName = cell(chanNum,1); chanIndx = zeros(1,chanNum);
for c = 1:chanNum
    chanName{c} = ChanConfig{c}.Name;
    chanIndx(c) = ChanConfig{c}.ChanId;
end

% sort them according to the channel order
[chanIndx,ind]          = sort(chanIndx);
[chanName{1:chanNum}]   = deal(chanName{ind});

% save
Par.chanName            = chanName;


%%%%%%
% Find Syncs using different system config
%%%%%%
switch Par.syncType
    case 'Fast Z'
        [Par,FrameStart] = TPA_FrameSyncSystem2014(Par,RecordedValues);
        
    case 'ROI Galvo Only'
        [Par,FrameStart] = TPA_FrameSyncSystem2014(Par,RecordedValues);
        
    case 'ROI Galvo + Blank'
        [Par,FrameStart] = TPA_FrameSyncSystem2014(Par,RecordedValues);
        
    case 'System 2014'
        [Par,FrameStart] = TPA_FrameSyncSystem2014(Par,RecordedValues);
        
    case 'Resonant 2014'
        [Par,FrameStart] = TPA_FrameSyncResonant2014(Par,RecordedValues);
        
   case 'Prarie 2018'
        [Par,FrameStart] = TPA_FrameSyncPrarie2018(Par,RecordedValues);

   case 'Prarie 1 channel'
        [Par,FrameStart] = TPA_FrameSyncPrarieOneChannel(Par,RecordedValues);
        
        
        
    otherwise
        error('Unknwon syncType')
end



txt = sprintf('Found %d Frame Starts.',length(FrameStart));
DTP_ManageText([], txt,   'I' ,0);



% show data
if FigNum < 1 , return; end


stimSampleTime              = Par.stimSampleTime;
tt                          = (1:recordNum)'*stimSampleTime;

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

%set(hFrame,'xdata',tt(FrameStart),'ydata',FrameStart*0+3);

return

