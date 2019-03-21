% TPA_ShaharAnalysis - Behavioral and Imaging Around certain times

% ========================================
% Ver   Date        Who  Descr.
%------------------------------
% 0104  06.06.18    UD   Fixing ranges
% 0103  31.05.18    UD   Fixing ranges
% 0102  28.05.18    UD   Adding position point
% 0101  25.05.18    UD   Adding Overlay of a cell response
% 0100  17.05.18    UD   Created
% ========================================


%% Params
% 
timeWindow      = 1;   % sec : window arround the center of the selected point in sec
figNum          = 1;
roiName         = 'ROI:Z:1:007';


%% Table to check : trial versus image frame number
systemType      = 2;     % 1-Tho Photon Janelia, 2-Prarie
analysDirName   = 'C:\LabUsers\Uri\Data\Prarie\Analysis\PT3\3_13_18_1';
analysTime      = [4 12];




%% Read Directories
Par             = TPA_ParInit();
switch systemType
    case 1, Par.DMT             = TPA_DataManagerTwoPhoton(); %TPA_DataManagerTwoPhoton();
    case 2, Par.DMT             = TPA_DataManagerPrarie();
    otherwise 
        error('bad systemType')
end
Par.DMB             = TPA_DataManagerBehavior(); 

% need to init video data since analysis name is decoded from it
%Par.DMT         = Par.DMT.SelectTwoPhotonData(testImDir);
Par.DMT         = Par.DMT.SelectAnalysisData(analysDirName);
%Par.DMB         = Par.DMB.SelectBehaviorData(testViDir);
Par.DMB         = Par.DMB.SelectAnalysisData(analysDirName);

% init
MTDM            = TPA_MultiTrialDataManager();
MTDM            = MTDM.Init(Par);

% load
MTDM            = MTDM.CheckDataFromTrials();
MTDM            = MTDM.LoadDataFromTrials();



%% check
% switch systemType
%     case 1
%         assert(Par.DMB.VideoFrontFileNum == MTDM.ValidTrialNum,'Trial number missmatch in the selected directory');
%     case 2 
%         assert(DMB.VideoFrontFileNum == DMT.VideoDirNum,'Trial number missmatch in the selected directory');        
% end
assert(MTDM.ValidTrialNum > 0,'Trial number exceed existent one');


%% Analysis per trial
grabInd     = find(startsWith(MTDM.UniqueEventNames,'Grab'));
eventName   = MTDM.UniqueEventNames{grabInd(1)};
roiInds     = 1:MTDM.UniqueRoiNum;
%dataStr     = {}; 
traceData   = [];
eventNum = zeros(MTDM.ValidTrialNum,1);
for trialInd = 1:MTDM.ValidTrialNum
    dataStr     = TracesPerTrial(MTDM, trialInd);
    eventNum(trialInd) = sum(startsWith(dataStr.Event(:,3),'Grab'));
    meanRoi     = dataStr.Roi{1,4};
    for k = 2:MTDM.UniqueRoiNum
        meanRoi     = meanRoi + dataStr.Roi{k,4};
    end
    traceData  = cat(2,traceData,meanRoi./MTDM.UniqueRoiNum);
end


%% Show
figure,stairs(eventNum),title('Event per Trial'),xlabel('Trial [#]')
figure,imagesc(traceData),title('Averaged Trace per Trial'),xlabel('Trial [#]')

%% Compute the parameter
[sv,si]     = sort(traceData(:),'ascend');
baseLine    = mean(sv(1:ceil(0.1*numel(traceData))));

%% how much above the baseline
traceBool   = traceData > baseLine*3;
traceActiv  = sum(traceData.*traceBool);

%% show
figure,plot(traceActiv),title('Grab Activity per Trial'),xlabel('Trial [#]')



