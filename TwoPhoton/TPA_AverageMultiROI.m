function [Par,StrROI] = TPA_AverageMultiROI(Par,StrROI,FigNum)
% TPA_AverageMultiROI - computes ROI for differnt regions. Uses lines for averaging of alongated regions.
% 
% Inputs:
%   Par         - control structure 
%   SData.imTwoPhoton     -  nR x nC x nZstack x nTime  image data (global)
%	StrROI     - collection of ROi's
%   FigNum     - controls if you want to show > 0 figure
%   
% Outputs:
%   Par         - control structure updated
%   strROI      - updated with nTime x nLen mean value at each ROI line 

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 16.11 24.02.14 UD     Janelia structure support
% 15.01 14.01.14 UD     new roi structure changes
% 13.03 20.12.13 UD     Support Z stack emnpty for channel 1 - Janelia
% 12.01 14.09.13 UD     Support Z stack
% 11.09 20.08.13 UD     export measurements of cursors to data directory
% 11.08 13.08.13 UD 	artifact management
% 11.06 06.08.13 UD 	support two channel processing
% 11.04 23.07.13 UD     average type is defined per ROI 
% 10.10 02.07.13 UD     improve show 
% 10.08 29.06.13 UD     compute big ROI 
%-----------------------------

if nargin < 1,  Par         = TPA_ParInit;                  end;
if nargin < 2,  StrROI      = {};                           end;
if nargin < 3,  FigNum      = Par.Debug.AverFluorFigNum;    end;


global SData;


% checks
[nR,nC,nZ,nT] = size(SData.imTwoPhoton);

%%%%
% Check
%%%%

% check for multiple Z ROIs
numROI              = length(StrROI);
if numROI < 1,
    DTP_ManageText([], sprintf('ROI Mean : No ROI data is found. Please select/load ROIs'),  'E' ,0);
    return
end
% check for multiple Z ROIs
if ~isfield(StrROI{1},'Ind') ,
    DTP_ManageText([], sprintf('ROI Mean :Something wrong with ROI data. Export is not done properly'),  'E' ,0);
    return
end


% mark that Artifact processing is not valid
%Par.ArtifactCorrected  = false;

%%%%
% RUN
%%%%


DTP_ManageText([], sprintf('ROI Mean : Started ...'),  'I' ,0), tic;


    
for k = 1:numROI,
    % preproces ROI - filter using averaging with certain radius
    pixInd           = StrROI{k}.Ind; % BUG in old files
    zInd             = StrROI{k}.zInd; % whic Z it belongs
    
    % define mask = old code compatability
    imMask          = false(nR,nC);
    imMask(pixInd)  = true;
    
    % type of averaging - pass the info inside
    if Par.Roi.ImposeAverageType,
        Par.Roi.AverageType         = Par.ROI_AVERAGE_TYPES.MEAN;        
    else
        Par.Roi.AverageType         = StrROI{k}.AverType;
    end
    
    % init line 
    [Par,RoiData]       = TPA_AverageROI(Par, 'Init', 0,imMask,0);
    if isempty(RoiData), continue; end;
        
    % this info is used for iteration process
    Par.Roi.TmpData         = RoiData; % save it
    
    % center of the ROI
    lineInd         = RoiData.LineInd;
    % skeleton

    lineLen         = numel(lineInd);
    meanROI         = zeros(nT,lineLen);
%     
%     Par.RoiLineInd  = lineInd;

    for m = 1:nT,
        
        % image data for specific Z stack
        imFrame                 = squeeze(SData.imTwoPhoton(:,:,zInd,m));
        [Par,meanVal]           = TPA_AverageROI(Par, 'Process', imFrame,imMask,0);
        meanROI(m,:)            = meanVal;
        
    end;
    
    
    % save
    StrROI{k}.meanROI   = meanROI;
    StrROI{k}.procROI   = []; %procROI;
    StrROI{k}.lineInd   = lineInd;
    
end;
%Par.RoiAverageType         = saveRoiAverageType;

Par.Roi.TmpData         = []; % cleanup
% output
% DataROI     = meanROI;
%Par.strROI  = strROI;
DTP_ManageText([], sprintf('ROI Mean : computed in %4.3f [sec]',toc),  'I' ,0)


if FigNum < 1, return; end;
    
%%% Concatenate all the ROIs in one Image
meanROI             = StrROI{1}.meanROI;
namePos             = ones(numROI,1);  % where to show the name

for k = 2:numROI,
    meanROI         = [meanROI StrROI{k}.meanROI];
    namePos(k)      = namePos(k-1) +length(StrROI{k}.lineInd);
end;


figure(FigNum),set(gcf,'Tag','AnalysisROI'),clf;
imagesc(meanROI',Par.DataRange), colorbar; colormap(gray);
hold on
for k = 1:numROI,
    text(10,namePos(k),StrROI{k}.Name,'color','y')
end
hold off
ylabel('ROI Line Pixels'),xlabel('Frame Num')
title(sprintf('Fo - Mean Fluorescence for Trial%s',Par.DMT.VideoFileNames{Par.DMT.Trial}), 'interpreter','none'),
    


return




