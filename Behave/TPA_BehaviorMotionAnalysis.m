% TPA_BehaviorMotionAnalysis Continuous Motion Extraction in multiple ROIs
% Optical flow from Matlab R2015a.

% ========================================
% Ver   Date        Who  Descr.
%------------------------------
% 0402  17.05.18    UD   Adding more ROIs
% 0401  29.04.18    UD   ROI editor
% 0302  27.07.15    UD   Optical flow
% 0301  04.02.15    UD   Motion blocks
% 0101  25.01.15    UD   Linkage is 2D
% 0100  04.01.15    UD   Created
% ========================================


%%
% Params
%%%
diffThr         = 0.3;       % threshold for large flow detection
figNum          = 1;
fileDirName     = 'C:\LabUsers\Uri\Data\Janelia\Videos\D8\7_12_14\Basler_12_07_2014_d8_032\movie_comb.avi';

%%
% init objects
%%%
%hOptical                = opticalFlowLKDoG('NumFrames',3); %opticalFlow( 'OutputValue', 'Horizontal and vertical components in complex form');
hOptical                = opticalFlowLK('NoiseThreshold',0.001); %opticalFlow( 'OutputValue', 'Horizontal and vertical components in complex form');
hVideoOut               = vision.VideoPlayer;
hVideoOut.Name          = 'Motion Detected Video';


%% 
% Load Data
%%%
doLoad          = true;
if exist('fileDirNamePrev','var'), doLoad = ~strcmp(fileDirNamePrev,fileDirName); end
if doLoad
    readerobj   = VideoReader(fileDirName);
    imgD        = read(readerobj);
    % use side info only
    %imgD        = (squeeze(imgD(:,1:500,1,:)));
    %refInd      = 100:400;
    fileDirNamePrev  = fileDirName;
end
[nR,nC,nD,nT]  = size(imgD);

%%
% Select ROI
%%%
newRoi = true;
if exist('rect1','var')
    newRoi = strcmp(questdlg('Would you like to define new ROIs'),'Yes');
end
figure(1)
imshow(imgD(:,:,:,10)),title('Select ROI')
if newRoi
    isAdd = true; rect1 = [];
    while isAdd
        [Imc,rectTmp] = imcrop(gcf); 
        rect1         = cat(1,rect1,rectTmp);
        isAdd         = strcmp(questdlg('Would you like to add another ROIs'),'Yes');
        imshow(insertShape(imgD(:,:,:,10),'Rectangle',rect1,'color','y'))
    end
end
roiNum  = size(rect1,1);
imgDROI = insertShape(imgD(:,:,:,10),'Rectangle',rect1,'color','y');
imgDROI = insertText(imgDROI,rect1(:,1:2),(1:roiNum)');
imshow(imgDROI)
title('Current ROIs')



%%
% Estimate Motion
%
motionData  = zeros(nT,roiNum);
r           = 1:3:nR;
c           = 1:3:nC;
[Y, X]      = meshgrid(c,r);
scaleFact   = 20;
for k = 1:nT
    %img1    = imgD(:,:,k-1);
    frameGray   = imgD(:,:,1,k);
    flow        = estimateFlow(hOptical,frameGray);
    %optFlow     = step(hOptical, single(img));
    flowValid   = flow.Magnitude > diffThr;
    V           = flow.Vx(r,c) .* flowValid(r,c) * scaleFact;
    H           = flow.Vy(r,c) .* flowValid(r,c) * scaleFact;
    
    % remenber
    for m = 1:roiNum
        imgM            = imcrop(flow.Magnitude,rect1(m,:));
        motionData(k,m) = sum(imgM(:));
    end
    
    % Draw lines on top of image
    linesFlow       = int16([Y(:)'; X(:)'; Y(:)'+V(:)'; X(:)'+H(:)'])';
    imgRgb          = insertShape(frameGray, 'Line', linesFlow, 'color','r');

    % Send image data to video player
    step(hVideoOut, imgRgb);
    
end
release(hVideoOut);

%% show
motionData(1:3,:) = 0;
figure(2)
plot(motionData),xlabel('Frame Num'),legend(num2str((1:roiNum)'))
title('Motion Data versus Frame Number')

%% save
xlswrite('RoiMotion.xlsx',motionData);

%% Play movie
implay(imgD)
