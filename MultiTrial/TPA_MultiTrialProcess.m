function Par = TPA_MultiTrialProcess(Par,FigNum)
% TPA_MultiTrialProcess - loads Two Photon data from the experiment.
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
if validTrialNum < 1,
    DTP_ManageText([], sprintf('Multi Trial : Missing data in directory %s. Please check the folder or run Data Check',Par.DMT.RoiDir),  'E' ,0);
    return
else
    DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI. Processing ...',validTrialNum),  'I' ,0);
end
     

for trialInd = 1:validTrialNum,
    
        %%%%%%%%%%%%%%%%%%%%%%
        % Load Trial
        %%%%%%%%%%%%%%%%%%%%%%
        [Par.DMT,isOK]                    = Par.DMT.SetTrial(trialInd);
        [Par.DMT, SData.strROI]           = Par.DMT.LoadAnalysisData(trialInd,'strROI');
        [Par.DMT, SData.imTwoPhoton]      = Par.DMT.LoadTwoPhotonData(trialInd);
        
        % this code helps with sequential processing of the ROIs: use old one in the new image
        numROI                          = length(SData.strROI);
        if numROI < 1,
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
        % dF/F Analysis
        %%%%%%%%%%%%%%%%%%%%%%
        tmpFigNum                       = Par.Debug.DeltaFOverFigNum; % show some progress
        [Par,SData.strROI]              = TPA_ProcessROI(Par,SData.strROI,tmpFigNum);
         
        %%%%%%%%%%%%%%%%%%%%%%
        % Save back
        %%%%%%%%%%%%%%%%%%%%%%
        % start save
        Par.DMT                         = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strROI',SData.strROI);                

end
DTP_ManageText([], sprintf('Multi Trial : dF/F is computed for %d trials.',validTrialNum),  'I' ,0);


return

