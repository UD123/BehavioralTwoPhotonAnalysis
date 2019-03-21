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
% 23.14 21.05.16  UD  	Adding xyEffInd - effective index support
% 23.02 06.02.16  UD  	Debug roi class 
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
% check if old style roi - structure
if isfield(StrROI{1},'Ind') ,
    DTP_ManageText([], sprintf('ROI Mean : Old ROI data structure is detected. Open and close TwoPhotonXY editor.'),  'E' ,0);
    return
end

%%%%
% Compute Pixel indeces
%%%%
if ~isprop(StrROI{1},'PixInd'),
    DTP_ManageText([], sprintf('ROI Mean : Bad ROI - must have PixInd property. Call 911.'),  'E' ,0);
    return;
end
% init all if required
%if isempty(StrROI{1}.PixInd),
% Do not trust old values
[X,Y]       = meshgrid(1:nC,1:nR);  % 
for i = 1:numROI,
    xy          = StrROI{i}.xyInd;
    if Par.Roi.UseEffectiveROI && ~isempty(StrROI{i}.xyEffInd),
        xy  = StrROI{i}.xyEffInd;
    end
    maskIN      = inpolygon(X,Y,xy(:,1),xy(:,2));
    StrROI{i}.PixInd  = find(maskIN);
end
%end

% mark that Artifact processing is not valid
%Par.ArtifactCorrected  = false;

%%%%
% RUN
%%%%


DTP_ManageText([], sprintf('ROI Mean : Started ...'),  'I' ,0), tic;


    
for k = 1:numROI,
    % preproces ROI - filter using averaging with certain radius
    pixInd           = StrROI{k}.PixInd; % 
    zInd             = StrROI{k}.zInd; % whic Z it belongs
    if isempty(pixInd),
        DTP_ManageText([], sprintf('ROI %s : No region is found',StrROI{k}.Name),  'W' ,0);
        continue;
    end
    if zInd < 1 || zInd > nZ,
        DTP_ManageText([], sprintf('ROI %s : Does not belong to the particular z-stack',StrROI{k}.Name),  'W' ,0);
        continue;
    end
    
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
    StrROI{k}.Data      = meanROI;
    %StrROI{k}.procROI   = []; %procROI;
    StrROI{k}.LineInd   = lineInd;
    
end;
%Par.RoiAverageType         = saveRoiAverageType;
Par.Roi.ArtifactCorrected = false;
Par.Roi.TmpData         = []; % cleanup
% output
% DataROI     = meanROI;
%Par.strROI  = strROI;
DTP_ManageText([], sprintf('ROI Mean : computed in %4.3f [sec]',toc),  'I' ,0)


if FigNum < 1, return; end;
    
%%% Concatenate all the ROIs in one Image
meanROI             = StrROI{1}.Data;
namePos             = ones(numROI,1);  % where to show the name

for k = 2:numROI,
    meanROI         = [meanROI StrROI{k}.Data];
    namePos(k)      = namePos(k-1) + length(StrROI{k}.LineInd);
end;


figure(FigNum),set(gcf,'Tag','AnalysisROI'),clf; colordef(gcf,'none'),
if any(mean(meanROI) > Par.Roi.DataRange(2))
    imagesc(meanROI'), colorbar; colormap(gray); % when the brightness is out of range
else
    imagesc(meanROI',Par.Roi.DataRange), colorbar; colormap(gray);
end
hold on
for k = 1:numROI,
    text(10,namePos(k),StrROI{k}.Name,'color','y')
end
hold off
ylabel('ROI Line Pixels'),xlabel('Frame Num')
title(sprintf('Fo - Mean Fluorescence for Trial%s',Par.DMT.VideoFileNames{Par.DMT.Trial}), 'interpreter','none'),
    


return




for k = 1:numROI,
    %subplot(numROI,1,k),
    figure(FigNum + k),set(gcf,'Tag','AnalysisROI'),clf;
    %imagesc(strROI{k}.meanROI,Par.DataRange), colorbar;
    imagesc(StrROI{k}.meanROI,Par.Roi.DataRange), colorbar;
    title(sprintf('Ch. %d, F. Mean %s',chanInd,StrROI{k}.name), 'interpreter','none'),
    ylabel('Line Pix'),xlabel('Frame Num')
end;
%title(sprintf(' Chan-%d :Z-%d : Mean Energy of ROI per Time : %d',ChanNum,ZStackInd));
%end;


figure(FigNum+numROI+1),set(gcf,'Tag','AnalysisROI'),clf;
meanProject         = squeeze(mean(mean(ImStack,4),3));
imagesc(meanProject,Par.Roi.DataRange), colorbar; colormap(gray);
hold on
roiNames = cell(2*numROI,1);
for k = 1:numROI,
    %subplot(numROI,1,k),
        
    plot(StrROI{k}.xy(:,1),StrROI{k}.xy(:,2),'color',StrROI{k}.color);
    [rLine,cLine] = ind2sub([nR,nC],StrROI{k}.lineInd);
    plot(cLine,rLine,'color',StrROI{k}.color,'LineWidth',2);
    roiNames{2*k -1} = sprintf('Border : %s',StrROI{k}.name);
    roiNames{2*k}    = sprintf('Center : %s',StrROI{k}.name);

end;
hold off
legend(roiNames,'interpreter','none')
title(sprintf(' F. Mean Projection with ROIs : Z = %d',zInd),'interpreter','none');

return


