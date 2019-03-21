function [Par,strROI]    = TPA_FixArtifactsROI(Par, strROI,FigNum)
% TPA_FixArtifactsROI - removes long term time and spatial effects in mean ROI values between two channel ROIs
% Inputs:
%        Par    - different params for use
%    strROI1    - ROI info from the channel
% Outputs:
%        Par    - different params for next use
%   strROI      - updated with nTime x nLen mean value at each ROI line 

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 23.02 06.02.16 UD  	Debug roi class 
% 13.03 04.10.13 UD     lineScan continued
% 11.09 20.08.13 UD     remove bleaching and motion - leave Offset/baseline
% 11.06 06.08.13 UD     rename
% 11.01 09.07.13 UD     dealing with small ROIs requested for orth computations
% 10.11 08.07.13 UD     Update for small ROI
% 10.10 02.07.13 UD     Averaging ROI by different functions
%-----------------------------

%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2,     error('Requires input params');          end;
if nargin < 3,     FigNum   = 1;                            end;


%%%%
% Check
%%%%

% check for multiple Z ROIs
numROI              = length(strROI);
if numROI < 1,
    DTP_ManageText([], sprintf('ROI Artifact : No ROI data is found. Please select/load ROIs'),  'E' ,0);
    return
end
% check for multiple Z ROIs
if ~isprop(strROI{1},'Data') ,
    DTP_ManageText([], sprintf('ROI Artifact :Something wrong with ROI data. Export is not done properly'),  'E' ,0);
    return
end
% check for multiple Z ROIs
if isempty(strROI{1}.Data) ,
    DTP_ManageText([], sprintf('ROI Artifact : No average fluorescence data found. May be you need to do averaging first.'),  'E' ,0);
    return
end

% check if the artifacts are corrected already
if Par.Roi.ArtifactCorrected,
    warndlg('Artifacts are already corrected. Please run ROI averaging one more time to use this procedure')
    return;
end;

% save all the troubles
if Par.Roi.ArtifactType == Par.ROI_ARTIFACT_TYPES.NONE,
    DTP_ManageText([], sprintf('ROI Artifact : No correction is required.'),  'I' ,0);
    return
end
    
%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%

nR                  = size(strROI{1}.Data,1);
imgDataMean         = zeros(nR,numROI);
imgDataProc         = zeros(nR,numROI);
imgDataDebug        = zeros(nR,numROI);

%%%%%%%%%%%%%%%%%%%%%%
% Compute 
%%%%%%%%%%%%%%%%%%%%%%

   
for k = 1:numROI,
    
    
    % get ROI data   
    meanROI               = strROI{k}.Data(:,1);
    [lineLen,nT2]          = size(meanROI);
    
    if nR ~= lineLen,
        DTP_ManageText([], sprintf('ROI Artifact : ROI %d data length missmatch. Check first ROi or the rest',k),  'E' ,0);
        continue;
    end
    
    % save for debug
    %meanAvROI              = strROI{k}.meanROI*0;
    imgDataMean(:,k)        = meanROI;
    
    
    % Compute 
    switch Par.Roi.ArtifactType,
        
        
        case Par.ROI_ARTIFACT_TYPES.NONE,            % do nothing

        
        case Par.ROI_ARTIFACT_TYPES.BLEACHING,       % filter all pixels inside ROI Ch1
            
            
            processType         = 'bleach1';
            [Par.Roi,meanROI]       = TPA_ImageProcessing(Par.Roi,meanROI,processType,0);
            
            
%         case 'VerySlowWaveRemove',       % remove slow changing waves
%             
%             processType  = 'timeFiltVerySlow';
%             [Par,meanAvROI]       = TPA_ImageProcessing(Par,meanROI,processType,0);
%              meanROI             = meanROI - meanAvROI;
            
        
        case Par.ROI_ARTIFACT_TYPES.SLOW_TIME_WAVE,       % remove slow changing waves
            
            processType          = 'timeFiltSlow';
            [Par.Roi,meanAvROI]  = TPA_ImageProcessing(Par.Roi,meanROI,processType,0);
             meanROI             = meanROI - meanAvROI;
                         % for debug
            imgDataDebug(:,k)    = meanAvROI;

            
        case Par.ROI_ARTIFACT_TYPES.FAST_TIME_WAVE,       % remove slow changing waves
            
            processType          = 'timeFiltFast';
            [Par.Roi,meanAvROI]  = TPA_ImageProcessing(Par.Roi,meanROI,processType,0);
             meanROI             = meanROI - meanAvROI;
                         % for debug
            imgDataDebug(:,k)    = meanAvROI;
             

      %  case 'Neurophil',           % filter removes remove bleaching and motion - leave Offset/baseline
            
            %meanROI             = meanROI - strROI{k}.meanNPhil;

            
        case Par.ROI_ARTIFACT_TYPES.POLYFIT2,     % computes 2'nd degree fit
            
            x                   = (1:nR)';
            ylog                = log(meanROI + eps);
            p                   = polyfit(x,ylog,2);
            ylogp               = polyval(p,x);
            yp                  = exp(ylogp);
            meanROI             = meanROI - yp;
            
            % for debug
            imgDataDebug(:,k)    = yp;
            
% 
%             meanAvROI           = Par.totMeanROI;
%             meanROI             = meanROI - Par.totMeanROI;
%             
%             % show coeff
%             %DTP_ManageText([], sprintf('ROI %d : Alpha %5.3f, Gamma %5.3f, Betta %5.3f ',k,coeff(1),coeff(2),coeff(3)),  'I' ,0)
%             
%             
%         case 'SmoothSpatial',       % filter all pixels inside ROI Ch1
%             
%             if lineLen1 > 1,
%             
%             Par.RoiProcessType  = 'smooth5';
%             [Par,meanROI]       = DTP_ProcessingROI(Par,meanROI1',FigNum);
%             meanROI1            = meanROI';
%             
%             end;
%         
% 
%         case 'BleachingMotion',           % filter removes remove bleaching and motion - leave Offset/baseline
%             
%             mtrxTime            = repmat(1:nT1,lineLen1,1)';
%             mtrxConst           = ones(lineLen1,nT1)';
%             meanROI1            = meanROI1';
%             meanROI2            = meanROI2';
%             
%             % build matrix for 
%             F2                  = meanROI2(:);  % columnwise
%             F1T1                = [meanROI1(:) mtrxTime(:) mtrxConst(:)];
%             
%             % find coeff
%             coeff               = pinv(F1T1)*F2;
%             
%             % remove effect
%             F2predict           = F1T1*coeff;
%             % predicted values
%             meanROI2predict     = reshape(F2predict,nT1,lineLen1)';
%             
%             % recove dim back
%             meanROI1            = meanROI1';
%             meanROI2            = meanROI2' - meanROI2predict;
%             
%             % adding offset
%             meanROI2            = meanROI2 + repmat(mean(meanROI2predict,2),1,nT1);
%             
%             % show coeff
%             DTP_ManageText([], sprintf('ROI %d : Alpha %5.3f, Gamma %5.3f, Betta %5.3f ',k,coeff(1),coeff(2),coeff(3)),  'I' ,0)
% 
%             
%         case 'DeCorrelation',     % remove effects of channel 1 from channel 2
%             
%             % assume that F2 = alpha*F1 + t*gamma + betta 
%             
%             mtrxTime            = repmat(1:nT1,lineLen1,1)';
%             mtrxConst           = ones(lineLen1,nT1)';
%             meanROI1            = meanROI1';
%             meanROI2            = meanROI2';
%             
%             % build matrix for 
%             F2                  = meanROI2(:);  % columnwise
%             F1T1                = [meanROI1(:) mtrxTime(:) mtrxConst(:)];
%             
%             % find coeff
%             coeff               = pinv(F1T1)*F2;
%             
%             % remove effect
%             F2predict           = F1T1*coeff;
%             % predicted values
%             meanROI2predict     = reshape(F2predict,nT1,lineLen1)';
%             
%             % recove dim back
%             meanROI1            = meanROI1';
%             meanROI2            = meanROI2' - meanROI2predict;
%             
%             % show coeff
%             DTP_ManageText([], sprintf('ROI %d : Alpha %5.3f, Gamma %5.3f, Betta %5.3f ',k,coeff(1),coeff(2),coeff(3)),  'I' ,0)
%            
            
% 
%         case 'Movements',     % remove movements effect from two channel
%             
%             meanROI2            = meanROI2  - meanROI1;
            
           
        otherwise
            error('Unknown Cmnd')
    end;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Debug
    %%%%%%%%%%%%%%%%%%%%%%

%    if FigNum > 0 && k == showCellId, 
        
        %errMeanROI1      = strROI1{k}.meanROI - meanROI1;
        %errMeanROI2      = strROI2{k}.meanROI - meanROI2;
        
%         figure(FigNum + k),set(gcf,'Tag','AnalysisROI'),clf;
%         subplot(3,1,1),imagesc(StrROI{k}.meanROI,Par.DataRange), colorbar;
%         title(sprintf('Ch. 2:  F. Aver Before Processing : %s',strROI{k}.name),'interpreter','none');
%         ylabel('Line Pix'),xlabel('Frame Num')
%         subplot(3,1,2),imagesc(meanROI2predict,Par.DataRange), colorbar;
%         title(sprintf('Ch. 2:  F. Predicted from Ch1 : %s',strROI{k}.name),'interpreter','none');
%         ylabel('Line Pix'),xlabel('Frame Num')
%         subplot(3,1,3),imagesc(meanROI), colorbar;
%         title(sprintf('Ch. 2:  F. Difference original and Predicted : %s',strROI2{k}.name),'interpreter','none');
%         ylabel('Line Pix'),xlabel('Frame Num')

        
%         figure(FigNum),set(gcf,'Tag','AnalysisROI'),clf;
%         plot([strROI{k}.meanROI,meanAvROI]);
%         title(sprintf('ROI %s',strROI{k}.name),'interpreter','none')
%         legend('Fluorescence','Average')
        
        
%    end;
    
    % save
    strROI{k}.Data(:,1)       = meanROI;
    %strROI{k}.meanAvROI     = meanAvROI;
    
    % debug
    imgDataProc(:,k)        = meanROI;
    
end
%Par.strROI  = strROI;
Par.Roi.ArtifactCorrected = true;

% output
artifactOptions    = fieldnames(Par.ROI_ARTIFACT_TYPES);
DTP_ManageText([], sprintf('ROI Artifact : Artifacts of type %s are fixed.',artifactOptions{Par.Roi.ArtifactType}),  'I' ,0)

if FigNum < 1, return; end;


%%% Concatenate all the ROIs in one Image
meanROI             = strROI{1}.Data(:,1);
namePos             = ones(numROI,1);  % where to show the name

for k = 2:numROI,
    meanROI         = [meanROI strROI{k}.Data(:,1)];
    namePos(k)      = namePos(k-1) +length(strROI{k}.LineInd);
end;


figure(FigNum),set(gcf,'Tag','AnalysisROI'),clf; colordef(gcf,'none')
imagesc(meanROI',Par.Roi.DataRange), colorbar; colormap(gray);
hold on
for k = 1:numROI,
    text(10,namePos(k),strROI{k}.Name,'color','y')
end
hold off
ylabel('ROI Line Pixels'),xlabel('Frame Num')
title(sprintf('Corercted Fluorescence for Trial%s',Par.DMT.VideoFileNames{Par.DMT.Trial}), 'interpreter','none'),


figure(FigNum+1),set(gcf,'Tag','AnalysisROI'),clf; colordef(gcf,'none')
plot(imgDataMean),
hold on;
plot(imgDataDebug,':'),
hold off;
title('Original and Fitted fluorescence for all ROIs')

return
