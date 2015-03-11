% Test Continuous Motion Extraction
% Trying to use frame difference to find moving regions.
% Then region properties are shown.

%addpath(genpath('C:\LabUsers\Uri\Projects\Maria\DendritesTwoPhoton\TwoPhotonAnalysis'));
%addpath(genpath('C:\Uri\Code\Matlab\ImageProcessing\People\piotr_toolbox_V3.25'));

% ========================================
% Ver   Date        Who  Descr.
%------------------------------
% 0105  05.02.15    UD   Linkage is 3D
% 0100  04.01.15    UD   Created
% ========================================


%%%
% Params
%%%
testType    = 11;
dffThr      = 50;       % threshold for large object detection
minTimeThr  = 4;        % min duration in time
minAreaThr  = 1*20*20;  % object size at least 3 frames 50x50 at XY plane 
filtThr     = ones(3,3,5);  filtThr = filtThr./sum(filtThr(:));
figNum      = 1;

% init
%dm          = TPA_MotionCorrectionManager();


%%%
% Data setup
%%%
doLoad  = true;
if exist('testTypePrev','var'), doLoad = testTypePrev ~= testType; end
if doLoad,


switch testType,
    
    case 1, % side video
        fileDirName     = 'C:\Uri\DataJ\Janelia\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_014.avi';
        %fileDirName = 'C:\UsersJ\Uri\Data\Videos\m2\4_4_14\Basler_front_04_04_2014_m2_014.avi';
        %fileDirName = 'C:\LabUsers\Uri\Data\Janelia\Videos\D16a\7_30_14\Basler_30_07_2014_d16_005\movie_comb.avi';
        readerobj   = VideoReader(fileDirName);
        imgD        = read(readerobj);
        % use side info only
        imgD        = single(squeeze(imgD(:,:,1,:)));
        refInd      = 10:100;

    case 11, % only sub image
        %fileDirName = 'C:\LabUsers\Uri\Data\Janelia\Videos\D16a\7_30_14\Basler_30_07_2014_d16_005\movie_comb.avi';
        
        fileDirName     = 'C:\Uri\DataJ\Janelia\Videos\d13\15_08_14\Basler_15_08_2014_arch5_003\movie_comb.avi';
        readerobj   = VideoReader(fileDirName);
        imgD        = read(readerobj);
        % use side info only
        imgD        = single(squeeze(imgD(:,1:500,1,:)));
        imgD        = imresize(imgD,0.5);

        refInd      = 10:100;
        
        
    case 12, % side video 
        fileDirName     = 'C:\Uri\DataJ\Janelia\Videos\M75\2_21_14\Basler_side_21_02_2014_m75_8.avi';
        readerobj   = VideoReader(fileDirName);
        imgD        = read(readerobj);
        % use side info only
        imgD        = single(squeeze(imgD(:,1:500,1,:)));
        imgD        = imresize(imgD,0.5);

        refInd      = 10:100;
        
    case 51, % testing
        dm          = TPA_MotionCorrectionManager();
        dm          = GenData(dm, 6, 7); % moving circle
        imgD        = single(dm.ImgData);
        refInd      = 1:4;

    case 52, % testing
        dm          = TPA_MotionCorrectionManager();
        dm          = GenData(dm, 5, 4); % moving rect
        imgD        = single(dm.ImgData);
        refInd      = 1:size(imgD,3);
        minAreaThr  = 10;
        dffThr      = 20;
        
        
    otherwise
        error('Bad testType')
end
testTypePrev = testType;
end

[nR,nC,nT]  = size(imgD);

%%% 
% Find backg image at the beginning
%%% 
imgRefS      = mean(imgD(:,:,refInd),3);
imgStdS      = mean(abs(bsxfun(@minus,imgD(:,:,refInd),imgRefS)),3);

figure(figNum + 1),
imagesc(imgRefS),colorbar,title('Ref S Mean')
figure(figNum + 2),
imagesc(imgStdS),colorbar,title('Ref S Std')

%%% 
% Find backg image at the end
%%% 
imgRefF      = mean(imgD(:,:,nT-refInd),3);
imgStdF      = mean(abs(bsxfun(@minus,imgD(:,:,nT-refInd),imgRefF)),3);

figure(figNum + 3),
imagesc(imgRefF),colorbar,title('Ref F Mean')
figure(figNum + 4),
imagesc(imgStdF),colorbar,title('Ref F Std')


%%% 
% Substract background and segment
%%% 
% threshold and filter
imgDmB          = bsxfun(@minus,imgD,imgRefS);
%implay(imgDmB)
imgDmBThr       = single(imgDmB > dffThr);
imgDmBThr       = imfilter(imgDmBThr,filtThr);

% threshold again
imgDmBS         = imgDmBThr > 0.85;

% filter F 
imgDmB          = bsxfun(@minus,imgD,imgRefF);
imgDmBThr       = single(imgDmB > dffThr);
imgDmBThr       = imfilter(imgDmBThr,filtThr);

% threshold again
imgDmBF         = imgDmBThr > 0.85;

% keep only objects that are different in both
imgDmBF         = imgDmBS & imgDmBF;


% fill small holes
%imgDmBThr      = imfill(imgDmBThr,'holes');
%implay(imgDmBF);

%%% 
% Label and Link
%%% 

% label
%[imgL, cellNum] = bwlabeln(imgMeanThr);
CC              = bwconncomp(imgDmBF,26);
cellNum         = CC.NumObjects;

% filter objects by their duration and size
isValid         = false(cellNum,1);
for k = 1:cellNum,
    [y,x,t] = ind2sub(size(imgDmBThr),CC.PixelIdxList{k});
    dy      = max(y) - min(y);
    dx      = max(x) - min(x);
    dt      = max(t) - min(t);
    pNum    = length(y);

    % conditions
    isValid(k) = dt > minTimeThr;
    isValid(k) = isValid(k) && (dx*dy > minAreaThr);
end
CC.PixelIdxList = CC.PixelIdxList(isValid);
CC.NumObjects   = sum(isValid);

% output
%EventCC         = CC;
imgDmBSegm      = labelmatrix(CC);
%implay(imgDmBSegm)

%%% 
% Compute trajectories
%%% 
CC.TrajList = cell(1,CC.NumObjects);
for k = 1:CC.NumObjects,
    [y,x,t] = ind2sub(size(imgDmBThr),CC.PixelIdxList{k});
    
    xyt = [];
    for mt = min(t):max(t),
        ii = t == mt;
        mx = mean(x(ii));
        my = mean(y(ii));
        xyt = [xyt ;[mx my mt]];
    end
    CC.TrajList{k} = xyt;
    
end
    
%%% 
% Insert objects on image
%%% 
imgRGB  = zeros(nR,nC,3,nT,'uint8');
cmap    = flag(CC.NumObjects)*255;

for t = 1:nT,
    
    RGB       = repmat(uint8(imgD(:,:,t)),[1 1 3]);
    for k = 1:CC.NumObjects,
        ii = find(CC.TrajList{k}(:,3) == t);
        if ~isempty(ii),
        cShape      = 'circle';
        cPosition   = [CC.TrajList{k}(ii,1:2) 8];
        cLabel      = num2str(k);
        RGB         = insertObjectAnnotation(RGB,cShape,cPosition,cLabel,'Color',cmap(k,:),'TextColor', 'y');
        end
    end
    imgRGB(:,:,:,t) = RGB;
end
% show
implay(imgRGB)

return
