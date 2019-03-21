function Par = TPA_MultiTrialRoiProcess(Par,FigNum)
% TPA_MultiTrialRoiProcess - loads Two Photon data from the experiment.
% Preprocess it to extract dF/F and save it to disk back
% Inputs:
%   Par         - control structure 
%   TPA_XXX.mat -           files on the disk
%   
% Outputs:
%   Par         - control structure updated
%   TPA_XXX.mat -           files on the disk

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 28.06 25.01.18 UD     Multi trial Baseline support
% 28.05 20.01.18 UD     Inhibitiry cell support
% 25.02 15.03.17 UD     rename from TPA_MultiTrialProcess
% 21.19 08.12.15 UD     Adding MinFluorLevel
% 21.04 25.08.15 UD     Adding artifact support
% 17.09 07.04.14 UD     Support different methods of dF/F
% 17.01 08.03.14 UD     Adding registration results
% 16.17 24.02.14 UD     Created
%-----------------------------

if nargin < 1,  error('Need Par structure');        end;
if nargin < 2,  FigNum      = 11;                  end;

if FigNum < 1, return; end;

% attach
global SData 
                
%%%%%%%%%%%%%%%%%%%%%%
% Run over all files/trials and load the Analysis data
%%%%%%%%%%%%%%%%%%%%%%
Par.DMT                 = Par.DMT.CheckData(false);    % important step to validate number of valid trials    
validTrialNum           = Par.DMT.ValidTrialNum;
if validTrialNum < 1
    DTP_ManageText([], sprintf('Multi Trial : Missing data in directory %s. Please check the folder or run Data Check',Par.DMT.RoiDir),  'E' ,0);
    return
else
    DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI. Processing ...',validTrialNum),  'I' ,0);
end
     
% load and compute average
strRoiArray         = {};
%validTrialNum = 3;
for trialInd = 1:validTrialNum
    
        %%%%%%%%%%%%%%%%%%%%%%
        % Load Trial
        %%%%%%%%%%%%%%%%%%%%%%
        [Par.DMT,isOK]                    = Par.DMT.SetTrial(trialInd);
        [Par.DMT, SData.strROI]           = Par.DMT.LoadAnalysisData(trialInd,'strROI');
        [Par.DMT, SData.imTwoPhoton]      = Par.DMT.LoadTwoPhotonData(trialInd);
        
        % this code helps with sequential processing of the ROIs: use old one in the new image
        numROI                          = length(SData.strROI);
        if numROI < 1
            DTP_ManageText([], sprintf('Multi Trial : There are no ROIs in trial %d. Trying to continue',trialInd),  'E' ,0);
            continue
        end
        
        % apply shift
        [Par.DMT, strShift]               = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strShift');
        [Par.DMT, SData.imTwoPhoton]      = Par.DMT.ShiftTwoPhotonData(SData.imTwoPhoton,strShift);
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Average
        %%%%%%%%%%%%%%%%%%%%%%
        Par.Roi.ImposeAverageType       = true;   % override individual assignments
        Par.Roi.AverageType             = Par.ROI_AVERAGE_TYPES.MEAN; % only mean on all rois
        [Par,SData.strROI]              = TPA_AverageMultiROI(Par,SData.strROI,0);
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Artifact removal
        %%%%%%%%%%%%%%%%%%%%%%
        tmpFigNum                       = Par.Debug.ArtifactFigNum;
        [Par,SData.strROI]              = TPA_FixArtifactsROI(Par, SData.strROI,tmpFigNum);
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Save for dF/F
        %%%%%%%%%%%%%%%%%%%%%%
        for r = 1:numROI
            strRoiArray{trialInd,r}  = SData.strROI{r};
        end
        
end

% compute baseline - only for certain type
if Par.Roi.ProcessType == Par.ROI_DELTAFOVERF_TYPES.MANY_TRIAL
    baseLine    = Inf(validTrialNum,numROI);
    for trialInd = 1:validTrialNum
        for r = 1:numROI
            if isempty(strRoiArray{trialInd,r}), continue; end
            meanData                = strRoiArray{trialInd,r}.Data(:,1);
            meanData                = sort(meanData,'ascend');
            baseLine(trialInd,r)    = mean(meanData(1:ceil(numel(meanData)*0.1)));
        end
    end
    baseLine                        = sort(baseLine,'ascend');
    baseLineMean                    = mean(baseLine(1:ceil(validTrialNum*0.75),:));
    
    % assign to all ROIs
    for trialInd = 1:validTrialNum
        for r = 1:numROI
            strRoiArray{trialInd,r}.DataBaseLine = baseLineMean(r);
        end
    end    
end

% compute dF/F
for trialInd = 1:validTrialNum
    
    
        %%%%%%%%%%%%%%%%%%%%%%
        % Recover after baseline
        %%%%%%%%%%%%%%%%%%%%%%
        for r = 1:numROI
            SData.strROI{r}                   = strRoiArray{trialInd,r};
        end

        
        %%%%%%%%%%%%%%%%%%%%%%
        % dF/F Analysis
        %%%%%%%%%%%%%%%%%%%%%%
        tmpFigNum                       = Par.Debug.DeltaFOverFigNum; % show some progress
        [Par,SData.strROI]              = TPA_ProcessROI(Par,SData.strROI,tmpFigNum);
         
        %%%%%%%%%%%%%%%%%%%%%%
        % Save back
        %%%%%%%%%%%%%%%%%%%%%%
        % start save
        [Par.DMT,isOK]                  = Par.DMT.SetTrial(trialInd);
        Par.DMT                         = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strROI',SData.strROI);                

end
DTP_ManageText([], sprintf('Multi Trial : dF/F is computed for %d trials.',validTrialNum),  'I' ,0);


return

