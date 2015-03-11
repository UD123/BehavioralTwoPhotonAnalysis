% Test Continuous Motion Extraction
% Trying to block matching from Matlab R2014b.

%addpath(genpath('C:\LabUsers\Uri\Projects\Maria\DendritesTwoPhoton\TwoPhotonAnalysis'));
%addpath(genpath('C:\Uri\Code\Matlab\ImageProcessing\People\piotr_toolbox_V3.25'));

% ========================================
% Ver   Date        Who  Descr.
%------------------------------
% 0301  04.02.15    UD   Motion blocks
% 0101  25.01.15    UD   Linkage is 2D
% 0100  04.01.15    UD   Created
% ========================================


%%%
% Params
%%%
% Par.binSize = 32;
% Par.nOrient = 8;
testType    = 12;
dffThr      = 50;       % threshold for large object detection
minAreaThr  = 20*20;  % object size at least 3 frames 50x50 at XY plane 
filtThr     = ones(5,5,3); filtThr = filtThr./sum(filtThr(:));
blockSize   = 15;

figNum      = 1;

% init objects
%dm          = TPA_MotionCorrectionManager();
hbm         = vision.BlockMatcher('ReferenceFrameSource', 'Input port', 'BlockSize', [blockSize blockSize]);
hbm.OutputValue = 'Horizontal and vertical components in complex form';
hbm.Overlap  = floor(blockSize/2)*[1 1];
hbm.MaximumDisplacement = hbm.Overlap;
halphablend = vision.AlphaBlender('Opacity',0.5 );


%%% Data 0
%load('mri.mat','D');
% dm          = dm.GenData(13,1);
% D           = dm.ImgData;
doLoad  = true;
if exist('testTypePrev','var'), doLoad = testTypePrev ~= testType; end
if doLoad,
switch testType,
    case 1, % full movie combine
                    
        fileDirName = 'C:\Uri\DataJ\Janelia\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_014.avi';
        %fileDirName = 'C:\UsersJ\Uri\Data\Videos\m2\4_4_14\Basler_side_04_04_2014_m2_014.avi';
        %fileDirName = 'C:\LabUsers\Uri\Data\Janelia\Videos\D16a\7_30_14\Basler_30_07_2014_d16_005\movie_comb.avi';
        readerobj   = VideoReader(fileDirName);
        imgD        = read(readerobj);
        
        % use side info only
        imgD        = single(squeeze(imgD(:,:,1,:)));
        imgD        = imresize(imgD,0.5);
        
        refInd      = 100:400;

    case 2, % only sub image
        fileDirName = 'C:\LabUsers\Uri\Data\Janelia\Videos\D16a\7_30_14\Basler_30_07_2014_d16_005\movie_comb.avi';
        readerobj   = VideoReader(fileDirName);
        imgD        = read(readerobj);
        % use side info only
        imgD        = single(squeeze(imgD(:,1:500,1,:)));
        refInd      = 100:400;
        
    case 3, % only sub image with resize
        fileDirName = 'C:\LabUsers\Uri\Data\Janelia\Videos\D16a\7_30_14\Basler_30_07_2014_d16_005\movie_comb.avi';
        readerobj   = VideoReader(fileDirName);
        imgD        = read(readerobj);
        % use side info only
        imgD        = single(squeeze(imgD(:,1:500,1,:)));
        imgD        = imresize(imgD,0.5);
        refInd      = 100:400;
        
        
    case 11, % testing
        dm          = TPA_MotionCorrectionManager();
        dm          = GenData(dm, 6, 7); % moving circle
        imgD        = single(dm.ImgData);
        refInd      = 1:4;

    case 12, % testing
        dm          = TPA_MotionCorrectionManager();
        dm          = GenData(dm, 5, 4); % moving rect
        imgD        = single(dm.ImgData);
        refInd      = 1:5; %size(imgD,3);
        minAreaThr  = 10;
        dffThr      = 20;
        
        
    otherwise
        error('Bad testType')
end
testTypePrev = testType;
end
[nR,nC,nT]  = size(imgD);


%%%
% Track Motion
%%%
% block pos
blockSizeWin    = hbm.Overlap+1;
[X,Y]           = meshgrid(1:blockSizeWin(2):nC, 1:blockSizeWin(1):nR);
% small correction
% X               = X + hbm.Overlap(2);
% Y               = Y + hbm.Overlap(1);
funBlock        = @(block_struct) std2(block_struct.data); % * ones(size(block_struct.data));
for k = 2:nT-1,
    img1    = imgD(:,:,k-1);
    img2    = imgD(:,:,k);
    motion  = step(hbm, img1, img2);
    
    % estimate if there is a variability in the block
    imgStd = blockproc(img2,blockSizeWin,funBlock);
    %motion(imgStd < 3) = 0;
    motionMak = single(imgStd(:) > 2);
    dH     = real(motion(:)).*motionMak;
    dV     = imag(motion(:)).*motionMak;
    
    % show 
    %img12 = step(halphablend, img2, img1);
    img12 = img2;
    figure(figNum + 1),
    imshow(uint8(img12)); 
    hold on;
    quiver(X(:), Y(:), dH, dV, 0,'r'); 
    hold off;
    drawnow
end


return

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

%%% 
% Label objects frame by frame
%%% 
objectNum       = 0;
imgDmL          = zeros(nR,nC,nT,'uint16'); % labeled objects
imgL            = zeros(nR,nC); % labeling matrix of objects
imgC            = zeros(nR,nC); % life time of the active objects
trajList        = cell(100,1);
for t = 1:nT,
    
    % predict active objects
    imgNewBW     = imgDmBF(:,:,t);
    for k = 1:objectNum,
        
        % mark the ground below previous
        imgNewBW(imgL == k) = false;
        
    end
    % mark new areas
    for k = 1:objectNum,
        
        % return pixels back
        imgObjBW    = (imgL == k);
        % pick additional pixels around that are not marked by the objects
        [r,c]       = find(imgObjBW);
        imgObjBW    = imgNewBW | imgObjBW;
        imgObjNewBW = bwselect(imgObjBW,c,r);
        
        % return back
        imgL(imgObjBW)      = 0;
        imgL(imgObjNewBW)   = k;
        imgC(imgObjNewBW)   = imgC(imgObjNewBW) + 1; % count hits
    end
    
    % create new
    [imgNewL,objNewNum]        = bwlabel(imgNewBW,8);
    countNew                   = 0;
    for k = 1:objNewNum,
        imgObjNewBW            = (imgNewL == k);
        if sum(imgObjNewBW(:)) < minAreaThr, continue; end;
        countNew               = countNew + 1;
        imgL(imgObjNewBW)      = objectNum + countNew;
        imgC(imgObjNewBW)      = 1; % init hits
    end
    objectNum                  = objectNum + countNew;
    
    % remove small objects
    stats               = regionprops(imgL,'Area','PixelIdxList');
    for k = 1:length(stats),
       if  stats(k).Area < minAreaThr,
           imgL(stats(k).PixelIdxList) = 0;
           imgC(stats(k).PixelIdxList) = 0;
       end
    end
    
    % compute centroids for the rest
    stats               = regionprops(imgL,'Centroid');
    for k = 1:length(stats),
        if any(isnan(stats(k).Centroid)), continue; end;
        if isempty(trajList{k}), 
            trajList{k} = [stats(k).Centroid t];
        else
            trajList{k} = [trajList{k}; [stats(k).Centroid t]];
        end
    end
    
    % save
    imgDmL(:,:,t)       = uint16(imgL);
    
end
% show
implay(imgDmL)


return

% label
%[imgL, cellNum] = bwlabeln(imgMeanThr);
CC              = bwconncomp(imgDmBThr,26);
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
    isValid(k) = dt > 5;
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
