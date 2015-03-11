function [Par,strROI1,strROI2]    = DTP_FixArtifactsROI(Par, Cmnd, strROI1,strROI2,FigNum)
% DTP_FixArtifactsROI - removes long term time and spatial effects in mean ROI values between two channel ROIs
% Inputs:
%        Par    - different params for use
%       Cmnd    - command - what to do 
%    strROI1,strROI2 - ROI info from two channels
% Outputs:
%        Par    - different params for next use
%   strROI      - updated with nTime x nLen mean value at each ROI line 

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 11.09 20.08.13 UD     remove bleaching and motion - leave Offset/baseline
% 11.06 06.08.13 UD     rename
% 11.01 09.07.13 UD     dealing with small ROIs requested for orth computations
% 10.11 08.07.13 UD     Update for small ROI
% 10.10 02.07.13 UD     Averaging ROI by different functions
%-----------------------------

%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4,     error('Requires input params');          end;
if nargin < 5,     FigNum   = 1;                            end;


%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%
% params
%ZStackInd           = Par.ZStackInd;
% checks
% check for multiple Z ROIs
numROI              = length(strROI2);
% if numROI > 1,
%     if numROI < ZStackInd,
%         errordlg('ZStackROIs contains less length than requested')
%         return;
%     else
%         %strROI          = ZStackROIs{ZStackInd};
%         strROI1          = ZStackROI1;
%         strROI2          = ZStackROI2;
%     end;
% else
%         strROI1          = ZStackROI1;
%         strROI2          = ZStackROI2;
% end


% check if the artifacts are corrected already
if Par.ArtifactCorrected,
    warndlg('Artifacts are already corrected. Please run ROI averaging one more time to use this procedure')
    return;
end;


%%%%%%%%%%%%%%%%%%%%%%
% Compute 
%%%%%%%%%%%%%%%%%%%%%%

   
for k = 1:numROI,
    
    
    % get ROI data
     meanROI1           = strROI1{k}.meanROI;
    [lineLen1,nT1]        = size(meanROI1);
    
     meanROI2           = strROI2{k}.meanROI;
    [lineLen2,nT2]        = size(meanROI2);
    
    if lineLen1 ~= lineLen2 || nT1 ~= nT2,
        error('ROI %d, Something terrible wrong with ROI data. Channels 1 could be missing',k)
    end;
    
    
    % Compute 
    switch Cmnd,
        
        case 'SmoothSpatial',       % filter all pixels inside ROI Ch1
            
            if lineLen1 > 1,
            
            Par.RoiProcessType  = 'smooth5';
            [Par,meanROI]       = DTP_ProcessingROI(Par,meanROI1',FigNum);
            meanROI1            = meanROI';
            
            end;
        

        case 'BleachingMotion',           % filter removes remove bleaching and motion - leave Offset/baseline
            
            mtrxTime            = repmat(1:nT1,lineLen1,1)';
            mtrxConst           = ones(lineLen1,nT1)';
            meanROI1            = meanROI1';
            meanROI2            = meanROI2';
            
            % build matrix for 
            F2                  = meanROI2(:);  % columnwise
            F1T1                = [meanROI1(:) mtrxTime(:) mtrxConst(:)];
            
            % find coeff
            coeff               = pinv(F1T1)*F2;
            
            % remove effect
            F2predict           = F1T1*coeff;
            % predicted values
            meanROI2predict     = reshape(F2predict,nT1,lineLen1)';
            
            % recove dim back
            meanROI1            = meanROI1';
            meanROI2            = meanROI2' - meanROI2predict;
            
            % adding offset
            meanROI2            = meanROI2 + repmat(mean(meanROI2predict,2),1,nT1);
            
            % show coeff
            DTP_ManageText([], sprintf('ROI %d : Alpha %5.3f, Gamma %5.3f, Betta %5.3f ',k,coeff(1),coeff(2),coeff(3)),  'I' ,0)

            
        case 'DeCorrelation',     % remove effects of channel 1 from channel 2
            
            % assume that F2 = alpha*F1 + t*gamma + betta 
            
            mtrxTime            = repmat(1:nT1,lineLen1,1)';
            mtrxConst           = ones(lineLen1,nT1)';
            meanROI1            = meanROI1';
            meanROI2            = meanROI2';
            
            % build matrix for 
            F2                  = meanROI2(:);  % columnwise
            F1T1                = [meanROI1(:) mtrxTime(:) mtrxConst(:)];
            
            % find coeff
            coeff               = pinv(F1T1)*F2;
            
            % remove effect
            F2predict           = F1T1*coeff;
            % predicted values
            meanROI2predict     = reshape(F2predict,nT1,lineLen1)';
            
            % recove dim back
            meanROI1            = meanROI1';
            meanROI2            = meanROI2' - meanROI2predict;
            
            % show coeff
            DTP_ManageText([], sprintf('ROI %d : Alpha %5.3f, Gamma %5.3f, Betta %5.3f ',k,coeff(1),coeff(2),coeff(3)),  'I' ,0)
           
            

        case 'Movements',     % remove movements effect from two channel
            
            meanROI2            = meanROI2  - meanROI1;


        otherwise
            error('Unknown Cmnd')
    end;
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Debug
    %%%%%%%%%%%%%%%%%%%%%%

    if FigNum > 0, 
        
        %errMeanROI1      = strROI1{k}.meanROI - meanROI1;
        %errMeanROI2      = strROI2{k}.meanROI - meanROI2;
        
        figure(FigNum + k),set(gcf,'Tag','AnalysisROI'),clf;
        subplot(3,1,1),imagesc(strROI2{k}.meanROI,Par.DataRange), colorbar;
        title(sprintf('Ch. 2:  F. Aver Before Processing : %s',strROI1{k}.name),'interpreter','none');
        ylabel('Line Pix'),xlabel('Frame Num')
        subplot(3,1,2),imagesc(meanROI2predict,Par.DataRange), colorbar;
        title(sprintf('Ch. 2:  F. Predicted from Ch1 : %s',strROI1{k}.name),'interpreter','none');
        ylabel('Line Pix'),xlabel('Frame Num')
        subplot(3,1,3),imagesc(meanROI2), colorbar;
        title(sprintf('Ch. 2:  F. Difference original and Predicted : %s',strROI2{k}.name),'interpreter','none');
        ylabel('Line Pix'),xlabel('Frame Num')
        
        
    end;
    
    % save
    strROI1{k}.meanROI   = meanROI1;
    strROI2{k}.meanROI   = meanROI2;
    
end;
% output
% DataROI     = meanROI;
%Par.strROI  = strROI;
DTP_ManageText([], sprintf('Command %s is executed on both channels',Cmnd),  'I' ,0)
Par.ArtifactCorrected = true;


%ImgData          = (ImgDataF - ImgDataBL)./(ImgDataStd + eps);


return

