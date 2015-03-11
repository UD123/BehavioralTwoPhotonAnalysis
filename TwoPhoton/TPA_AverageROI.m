function [Par,RoiData]    = TPA_AverageROI(Par, Cmnd, ImFrame, ImMask,FigNum)
% TPA_AverageROI - performs different ROI averaging operations when the ROI is defined
% manualy.
% Inputs:
%        Par - different params for use
%       Cmnd - command - what to do 
%    ImFrame,ImMask - image data and mask
% Outputs:
%        Par - different params for next use
%    RoiData - image data after processing

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 11.08 13.08.13 UD     using gradient function for line orthogonal
% 11.02 15.07.13 UD     rename
% 11.01 09.07.13 UD     dealing with small ROIs requested for orth computations
% 10.11 08.07.13 UD     Update for small ROI
% 10.10 02.07.13 UD     Averaging ROI by different functions
%-----------------------------

%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1,     Par      = TPA_ParInit;      end;
if nargin < 2,     Cmnd     = 'Init';           end;
if nargin < 3,     ImFrame  = rand(300,300);    end;
if nargin < 4,     ImMask   = zeros(size(ImFrame)); ImMask(:,140:150) = 1;   end;
if nargin < 5,     FigNum   = 1;                end;


%%%%%%%%%%%%%%%%%%%%%%
% Check Init 
%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Cmnd,'Init'),
    
    switch Par.Roi.AverageType,

        case Par.ROI_AVERAGE_TYPES.MEAN,       % ffilter all pixels inside ROI
            [Par,RoiData]    = local_InitPointROI(Par,ImFrame,ImMask);
             Par.Roi.TmpData         = RoiData;
            
        case Par.ROI_AVERAGE_TYPES.LOCAL_MAXIMA,
            [Par,RoiData]   = local_InitLineMaxROI(Par,ImFrame,ImMask);
            Par.Roi.TmpData         = RoiData;

        case Par.ROI_AVERAGE_TYPES.LINE_ORTHOG, 
            [Par,RoiData]   = local_InitLineOrthogROI(Par,ImFrame,ImMask);
            Par.Roi.TmpData         = RoiData;
            
        otherwise
            error('Unknown RoiProcessType')
    end;
    
    return;
    
end;


%%%%%%%%%%%%%%%%%%%%%%
% Compute 
%%%%%%%%%%%%%%%%%%%%%%
switch Par.Roi.AverageType,
    
    case Par.ROI_AVERAGE_TYPES.MEAN,       % ffilter all pixels inside ROI
        [Par,RoiData]   = local_PointROI(Par,ImFrame,ImMask);
    
    
    case Par.ROI_AVERAGE_TYPES.LOCAL_MAXIMA,
        [Par,RoiData]   = local_LineMaxROI(Par,ImFrame,ImMask);
        
        
    case Par.ROI_AVERAGE_TYPES.LINE_ORTHOG,        % filtering using line 
        [Par,RoiData]   = local_LineOrthogROI(Par,ImFrame,ImMask);

        
    otherwise
        error('Unknown RoiProcessType')
end;

%ImgData          = (ImgDataF - ImgDataBL)./(ImgDataStd + eps);



%%%%%%%%%%%%%%%%%%%%%%
% Output
%%%%%%%%%%%%%%%%%%%%%%
% Par.ColStart     = ColStart;
% Par.ColEnd       = ColEnd;
% Par.ColColor     = ColColor;
% Par.ColName      = ColName;
% Par.CellLabelNum = CellLabelNum;

if FigNum < 1, return; end;

% show
figure(FigNum + 1),
imagesc(ImFrame),colormap(gray),colorbar
xlabel('Columns')
ylabel('Rows')
title('Original Image Data')
impixelinfo


% show
figure(FigNum + 2),
imagesc(ImMask),colormap(gray),colorbar
xlabel('Columns')
ylabel('Rows')
title('Mask Data dF/F')
impixelinfo


return

%%%%%%%%%%%%%%%%%%%%%%
% Local Functions
%%%%%%%%%%%%%%%%%%%%%%

% ----------------------------------------------------------------
function [Par,RoiData]    = local_InitPointROI(Par,ImFrame,ImMask)
% average all

%MeanROI                   = 0;

%[rowNum,colNum]            = size(ImFrame);

ii                       = find(ImMask);
if isempty(ii),
    error('ROI must have positive values')
end;
stat                    = regionprops(ImMask, 'Centroid');
centr                   = round(stat(1).Centroid);
centrInd                = sub2ind(size(ImMask),centr(2),centr(1));
% ROI center

RoiData.LineInd          = centrInd;

return


% ----------------------------------------------------------------
function [Par,MeanROI]    = local_PointROI(Par,ImFrame,ImMask)
% average all

%MeanROI                   = 0;

%[rowNum,colNum]            = size(ImFrame);

ii                       = find(ImMask);
if isempty(ii),
    error('ROI must have positive values')
end;

MeanROI                 = sum(ImFrame(ii))/length(ii);

return

% ----------------------------------------------------------------
function [Par,RoiData]    = local_InitLineMaxROI(Par,ImFrame,ImMask)
% estimate base line of the data

% check LineInd exists
%if ~isfield(Par,'RoiLineInd') || isempty(Par.RoiLineInd),
    % init index
BWthin                  = bwmorph(ImMask,'thin',Inf);
LineInd                 = find(BWthin);

% project for each ROI
RoiData.H              = fspecial('disk',Par.Roi.AverageRadius);
% design max filter
RoiData.domain         = fspecial('disk',Par.Roi.MaxMovementRadius) > 0;
RoiData.order          = nnz(RoiData.domain);
RoiData.LineInd         = LineInd;

return


% ----------------------------------------------------------------
function [Par,MeanROI]    = local_LineMaxROI(Par,ImFrame,ImMask)
% estimate base line of the data

lineInd         = Par.Roi.TmpData.LineInd;    
H               = Par.Roi.TmpData.H;    
order           = Par.Roi.TmpData.order;    
domain          = Par.Roi.TmpData.domain;    
%lineLen         = numel(lineInd);


% image data for specific Z stack
imFrame         = double(ImFrame);
imFrameFilt     = roifilt2(H,imFrame,ImMask);
imFrameFilt     = imFrameFilt.*ImMask;  % ignore high vlues at the ends

% take maxima in the region
imFrameMax      = ordfilt2(imFrameFilt, order, domain);
%imFrameMax      = imFrameFilt;

MeanROI         = imFrameMax(lineInd);       



return


% ----------------------------------------------------------------
function [Par,RoiData]    = local_InitLineOrthogROI(Par,ImFrame,ImMask)
% estimate base line of the data

figNum                  = 0;
RoiData                 = [];

[nR,nC]                 = size(ImMask);

% check LineInd exists
%if ~isfield(Par,'RoiLineInd') || isempty(Par.RoiLineInd),
    % init index
    
% order is not known
%BWthin                  = bwmorph(ImMask,'skel',Inf);
BWthin                  = bwmorph(ImMask,'thin',Inf);
BWbranch                = bwmorph(BWthin,'branchpoints');
% try to resolve it by dilation with big strel
k                       = 1;
while ~isempty(find(BWbranch)) && k < 10,
    strelSize           = 3*k;
    BWthin              = imdilate(BWthin,ones(strelSize));
    BWthin              = bwmorph(BWthin,'thin',Inf);    
    BWbranch            = bwmorph(BWthin,'branchpoints');
    k = k + 1;
end;

if ~isempty(find(BWbranch)),
    warndlg('ROI contains splitted/branching points')
    return;
end;
    
BWend                   = bwmorph(BWthin,'endpoints');
[rowStart, colStart]    = find(BWend);
if numel(rowStart) ~= 2, 
    warndlg('ROI Contains more than 2 end points. Result will be unpredictable and fatal'); 
    rowStart    = rowStart(1:2);
    colStart    = colStart(1:2);
end;

% arrange pixels by order of the line
contour                 = bwtraceboundary(BWthin, [rowStart(1), colStart(1)],'E');

% we went twice on this line - back and forward.
lineLen                 = round(size(contour,1)/2);
% take only half
rLine                   = contour(1:lineLen,1);
cLine                   = contour(1:lineLen,2);
LineInd                 = sub2ind([nR,nC],rLine,cLine);

%LineInd                 = find(BWthin);

if figNum > 0,
    ImMask          = double(ImMask);
    ImMask(LineInd) = 5;   
    figure(figNum),imagesc(ImMask)
    
end


% check if the regio is too small
if numel(LineInd) < 7,
    RoiData.LineInd      = LineInd(ceil(numel(LineInd)/2));
    return
end;


% define orthoganal directions
%[rLine,cLine]           = ind2sub([nR,nC],LineInd);

% interpolate line - smooth them over
pixNum                  = length(rLine);
tt                      = (1:pixNum)';
rLine                   = interp1(tt,rLine,tt,'cubic');
cLine                   = interp1(tt,cLine,tt,'cubic');
% alpha                   = 0.1;
% rLine                   = filtfilt(alpha,[1 -(1-alpha)],rLine);
% cLine                   = filtfilt(alpha,[1 -(1-alpha)],cLine);


% gradC                   = diff(cLine);  gradC  = [gradC(1); gradC];
% gradR                   = diff(rLine);  gradR  = [gradR(1); gradR];
gradC                   = gradient(cLine);  %gradC  = [gradC(1); gradC];
gradR                   = gradient(rLine);  %gradR  = [gradR(1); gradR];
gradAbs                 = sqrt(gradR.^2 + gradC.^2);
cNormOrth               = gradR./gradAbs;
rNormOrth               = -gradC./gradAbs;

% define orthoganal line
lineHalfLen             = ceil(min(nR,nC)/3);
widthPix                = Par.Roi.OrthRoiWidthPix;
% cLineOrth               = - lineHalfLen : lineHalfLen;
% rLineOrth               = cLineOrth*0;

% define wide region to cover
[cLineOrth,rLineOrth]   = meshgrid(- lineHalfLen : lineHalfLen, -widthPix:widthPix);
cLineOrth               = cLineOrth(:);
rLineOrth               = rLineOrth(:);

% for each pixel 
OrthLineInd             = {};
for k = 1:pixNum,
    
    cLineOrthRot        = cNormOrth(k) * cLineOrth  - rNormOrth(k) * rLineOrth  + cLine(k);
    rLineOrthRot        = rNormOrth(k) * cLineOrth  + cNormOrth(k) * rLineOrth  + rLine(k);
    
    
    % convert to coordinates
    cLineOrthRot        = round(cLineOrthRot);
    rLineOrthRot        = round(rLineOrthRot);
    validBool           = 1 <= cLineOrthRot & cLineOrthRot <= nC & 1 <= rLineOrthRot & rLineOrthRot <= nR;
    
    % save the valid only that match mask
    orthInd             = sub2ind([nR,nC],rLineOrthRot(validBool),cLineOrthRot(validBool));
    validMaskInd        = find(ImMask(orthInd) > 0);
    
    OrthLineInd{k}      = orthInd(validMaskInd);
    
    if figNum > 0,
        ImMask = double(ImMask);
        ImMask(OrthLineInd{k}) = 7;    
        figure(figNum),imagesc(ImMask)
    end
    
    
end;

RoiData.LineInd         = LineInd;
RoiData.OrthLineInd     = OrthLineInd;


return


% ----------------------------------------------------------------
function [Par,MeanROI]    = local_LineOrthogROI(Par,ImFrame,ImMask)
% estimate base line of the data


lineInd         = Par.Roi.TmpData.LineInd;    

% check if the regio is too small
if numel(lineInd) < 7,
    [Par,MeanROI]   = local_PointROI(Par,ImFrame,ImMask);
    return
end;
orthLineInd     = Par.Roi.TmpData.OrthLineInd; 



pixNum          = length(lineInd);
MeanROI         = zeros(1,pixNum);
for k = 1:pixNum,
    
    ii                  = orthLineInd{k};
    if isempty(ii),continue; end;
    %MeanROI(k)          = sum(ImFrame(ii))/length(ii);
    MeanROI(k)          = mean(ImFrame(ii));
    
end;


return

