function Par = TPA_MultiTrialRegistration(Par,FigNum)
% TPA_MultiTrialRegistration - loads Two Photon data from the experiment.
% Preprocess it to find motion Registration
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
% 21.10 10.11.15 UD     Do not check directories again
% 19.19 11.01.15 UD     Fixing bug with shifts
% 19.16 30.12.14 UD     Multi Dim data support
% 17.01 08.03.14 UD     Created
%-----------------------------

if nargin < 1,  error('Need Par structure');        end;
if nargin < 2,  FigNum      = 11;                  end;

if FigNum < 1, return; end;

% attach
global SData 

% motion correction manager :  different from MainGUI
mcObj                   = TPA_MotionCorrectionManager();

% mean image over all trials
meanData                = [];


%%%%%%%%%%%%%%%%%%%%%%
% Run over all files/trials and load the Analysis data
%%%%%%%%%%%%%%%%%%%%%%
Par.DMT                 = Par.DMT.CheckData(false);    % do not check dirs - use user selection   
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
        [Par.DMT, SData.imTwoPhoton]      = Par.DMT.LoadTwoPhotonData(trialInd);
        
        % one time init
        if trialInd == 1,
            [nR,nC,nZ,nT]   = size(SData.imTwoPhoton);
            meanData        = zeros(nR,nC,nZ,validTrialNum);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Registration on single trial
        %%%%%%%%%%%%%%%%%%%%%%
%        mcObj                           = mcObj.SetData(SData.imTwoPhoton);
%        [mcObj,estShift]                = AlgMultipleImageBox(mcObj, 3);
        
        % shift is multi dimensional
        [mcObj,estShift,imgData]         = AlgApply(mcObj, SData.imTwoPhoton ,4);        

        % save shift
        [Par.DMT, usrData]             = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strShift',estShift);
        
        % estimate mean
        meanData(:,:,:,trialInd)       = mean(imgData,4);
        
end
DTP_ManageText([], sprintf('Multi Trial : Trial Registration is computed for %d trials.',validTrialNum),  'I' ,0);
        

%%%%%%%%%%%%%%%%%%%%%%
% Estimate shift over entire experiment
%%%%%%%%%%%%%%%%%%%%%%
% mcObj                           = mcObj.SetData(meanData);
% [mcObj,estShift]                = AlgMultipleImageBox(mcObj, 3);
[mcObj,estShift]                = AlgApply(mcObj, meanData ,4);


figNum                          = Par.FigNum + 10;
mcObj.CheckResult(figNum, estShift*0, estShift);   
globalShift                     = estShift;

DTP_ManageText([], sprintf('Multi Trial : Registration over mean images is computed.'),  'I' ,0);


        
%%%%%%%%%%%%%%%%%%%%%%
% Adding shift to entire experiment
%%%%%%%%%%%%%%%%%%%%%%
for trialInd = 1:validTrialNum,
    
        %%%%%%%%%%%%%%%%%%%%%%
        % Load Trial
        %%%%%%%%%%%%%%%%%%%%%%
        [Par.DMT,isOK]                 = Par.DMT.SetTrial(trialInd);
        % load shift
        [Par.DMT, estShift]            = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strShift');
        
        % global correction
        estShift(:,1,:)                = bsxfun(@plus,estShift(:,1,:) , globalShift(trialInd,1,:));
        estShift(:,2,:)                = bsxfun(@plus,estShift(:,2,:) , globalShift(trialInd,2,:));
%         estShift(:,1)                   = estShift(:,1) + globalShift(trialInd,1);
%         estShift(:,2)                   = estShift(:,2) + globalShift(trialInd,2);
        
        % save shift
        [Par.DMT, usrData]             = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strShift',estShift);
        
        % estimate mean
        %meanData(:,:,1,trialInd)       = mean(mcObj.ImgData,3);
        
end
DTP_ManageText([], sprintf('Multi Trial : Global Registration is computed and saved for %d trials.',validTrialNum),  'I' ,0);
                 


return

