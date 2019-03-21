function  [Par,FrameStart] = TPA_FrameSyncPrarieOneChannel(Par,RecordedValues)
%TPA_FrameSyncPrarieOneChannel - uses only last channel as electrophy records.
% Inputs:
%   Par             - structure additional params
%	RecordedValues  - N x K matrix of K channels
% Outputs:
%   Par             - additional params
%	FrameStart      - Mx1 vector of frame start indices

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 28.14 01.04.18 UD     One channel processong
% 28.13 19.03.18 UD     Fadi  WTF
% 16.04 27.10.14 UD     New frame sync for Maria
%-----------------------------


% time to estimates thresholds - should not include data end

%%%%%%
% params
%%%%%%

chanName             = Par.chanName;
stimSampleTime       = Par.stimSampleTime;
frameNum             = Par.frameNum; % video
stimSampleRate       = 1/stimSampleTime;
stimRecordTime       = Par.recordTime ;
[recordNum,chanNum]  = size(RecordedValues);

samplesPerFrame      = ceil(recordNum./frameNum);
vertSyncInd          = samplesPerFrame*(0:frameNum-1) + 1;


% Output
validInd                = vertSyncInd < recordNum;
FrameStart              = vertSyncInd(validInd); %ft_ind(1:height:vertSyncNum);


return

