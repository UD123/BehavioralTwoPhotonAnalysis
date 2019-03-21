% TPA_BehavioralSniplets - Behavioral and Imaging Around certain times

% ========================================
% Ver   Date        Who  Descr.
%------------------------------
% 0103  31.05.18    UD   Fixing ranges
% 0102  28.05.18    UD   Adding position point
% 0101  25.05.18    UD   Adding Overlay of a cell response
% 0100  17.05.18    UD   Created
% ========================================


%% Params
% 
timeWindow      = 3;   % sec : window arround the center of the selected point in sec
figNum          = 1;
roiName         = 'ROI:Z:1:007';


%% Table to check : trial versus image frame number
systemType      = 2;     % 1-Tho Photon Janelia, 2-Prarie
imageDirName    = '\\jackie-backup\D\Maria\Layer 2-3\Imaging\M26\9_28_17';
analysDirName   = '\\jackie-backup\D\Maria\Layer 2-3\Analysis\M26\9_28_17';
videoDirName    = '\\jackie-backup\D\Maria\Layer 2-3\Videos\M26\2017-09-28';
tableTrialFrame = [
    69 167;...
    68 177;...
    66 147;...
    61 173;...
    57 133;...
    54 318;...
    52 169;...
    48 152;...
    43 137;...
    38 140;...
    35 175;...
    33 153;...
    32 187;...
    29 147;...
    27 154;...
    25 192;...
    19 166;...
    16 198;...
    ];

% 
% %% Table to check : trial versus image frame number
% systemType      = 1;     % 1-Tho Photon Janelia, 2-Prarie
% videoDirName    = 'D:\Uri\Data\Technion\Videos\D10\8_6_14';
% tableTrialFrame = [
%     1 107;...
%     2 077;...
%     3 87;...
%     4 97;...
%     5 56;...
%     ];
% 


%% Read Directories

switch systemType
    case 1, DMT             = TPA_DataManagerTwoPhoton(); %TPA_DataManagerTwoPhoton();
    case 2, DMT             = TPA_DataManagerPrarie();
    otherwise 
        error('bad systemType')
end
DMB             = TPA_DataManagerBehavior(); 

DMT             = DMT.SelectAllData(imageDirName);
DMB             = DMB.SelectAllData(videoDirName,'side'); % side, front, all

% check
switch systemType
    case 1
        assert(DMB.VideoFileNum == DMT.ValidTrialNum,'Trial number missmatch in the selected directory');
    case 2 
        assert(DMB.VideoFileNum == DMT.VideoDirNum,'Trial number missmatch in the selected directory');        
end
assert(DMB.VideoFileNum >= max(tableTrialFrame(:,1)),'Trial number exceed existent one');
%% Read Data & Snipets
convertFactor   = DMB.VideoFrameRate./DMT.VideoFrameRate;
timeStart       = tableTrialFrame(:,2)/DMT.VideoFrameRate - timeWindow/2;
timeFinish      = timeStart + timeWindow;
dataVideo       = []; roiInd = 0;
for k = 1:size(tableTrialFrame,1)
   trialInd         = tableTrialFrame(k,1);
   videoFileName    = fullfile(DMB.VideoDir,DMB.VideoSideFileNames{trialInd});
   [DMT, strROI]    = DMT.LoadAnalysisData(trialInd,'strROI');   
   % find which roi
   if roiInd < 1 
       for m = 1:length(strROI) 
           if strcmp(strROI{m}.Name,roiName), roiInd = m; break; 
           end 
       end
       if roiInd < 1, error('%s can not find this ROI. Please check the name',roiName); end
   end
   %indexToRead      = [round(timeStart(k)*DMT.VideoFrameRate) round(timeFinish(k)*DMT.VideoFrameRate)];
   %dffLen           = diff(indexToRead)+1;
   dffData          = strROI{roiInd}.Data(:,2); 
   dffLen           = length(dffData);
   vidLenMax        = ceil(dffLen*convertFactor);
       
   indexToRead      = [round(timeStart(k)*DMB.VideoFrameRate) round(timeFinish(k)*DMB.VideoFrameRate)];
   indexToRead      = max(1,min(indexToRead,vidLenMax));
   vidLen           = diff(indexToRead)+1;
   
   % interpolate data
   imgInd           = 1:dffLen;
   %imgInd           = linspace(timeStart(k),timeFinish(k),dffLen);
   vidInd           = linspace(1,dffLen,vidLenMax);
   dffDataInt       = interp1(imgInd,dffData,vidInd,'pchip');
   localVR          = VideoReader(videoFileName);
   
   dataVideoTmp     = read(localVR,indexToRead);
   nR               = size(dataVideoTmp,1);
   nC               = size(dataVideoTmp,2);
   for m = 1:size(dataVideoTmp,4)
        vidFrameRGB  = insertText(dataVideoTmp(:,:,:,m),[10 10],sprintf('%s : T-%d,F-%d',roiName,trialInd,indexToRead(1)+m));
        
        % insert indicator
        xc           = linspace(5,nC-5,numel(dffDataInt));
        yc           = nR-5 - dffDataInt*20; %linspace(nR-5,nR-50,numel(dffDataInt));
        vidFrameRGB  = insertShape(vidFrameRGB,'line',reshape([xc(:) yc(:)]',[],1)');
        xm           = xc(indexToRead(1) + m - 1);
        ym           = yc(indexToRead(1) + m - 1);
        vidFrameRGB  = insertMarker(vidFrameRGB,[xm ym],'o','color','red');
        dataVideo    = cat(4,dataVideo,vidFrameRGB);
   end
end

implay(dataVideo);


%% Save video
[p,f,~] = fileparts(videoDirName);
v       = VideoWriter([f,'.mp4'],'MPEG-4' );
open(v);
writeVideo(v,dataVideo);
close(v);

return





%% Read Data
%convertFactor   = DMB.VideoFrameRate./DMT.VideoFrameRate;
timeStart       = tableTrialFrame(:,2)/DMT.VideoFrameRate - timeWindow/2;
timeFinish      = timeStart + timeWindow;
dataVideo       = [];
for k = 1:size(tableTrialFrame,1)
   trialInd         = tableTrialFrame(k,1);
   videoFileName    = fullfile(DMB.VideoDir,DMB.VideoSideFileNames{trialInd});
   localVR          = VideoReader(videoFileName);
   indexToRead      = [round(timeStart(k)*DMB.VideoFrameRate) round(timeFinish(k)*DMB.VideoFrameRate)];
   dataVideoTmp     = read(localVR,indexToRead);
   for m = 1:size(dataVideoTmp,4)
        vidFrameRGB  = insertText(dataVideoTmp(:,:,:,m),[10 10],sprintf('T-%d,F-%d',trialInd,indexToRead(1)+m));
        dataVideo    = cat(4,dataVideo,vidFrameRGB);
   end
end

implay(dataVideo);


