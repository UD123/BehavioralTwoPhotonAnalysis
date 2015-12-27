function Par = TPA_MultiTrialEventProcess(Par,FigNum)
% TPA_MultiTrialEventProcess - loads Behavior data from the experiment.
% Preprocess it to compute motion for each Event and save it to disk back
% Inputs:
%   Par         - control structure 
%   EDA_XXX.mat -           files on the disk
%   
% Outputs:
%   Par         - control structure updated
%   EDA_XXX.mat -           files on the disk

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 20.02 07.03.15 UD     Created
%-----------------------------

if nargin < 1,  error('Need Par structure');        end;
if nargin < 2,  FigNum      = 11;                  end;

if FigNum < 1, return; end;

% attach
global SData 
                
%%%%%%%%%%%%%%%%%%%%%%
% Run over all files/trials and load the Analysis data
%%%%%%%%%%%%%%%%%%%%%%
Par.DMB                 = Par.DMB.CheckData();    % important step to validate number of valid trials    
validTrialNum           = Par.DMB.ValidTrialNum;
if validTrialNum < 1,
    DTP_ManageText([], sprintf('Multi Trial : Missing data in directory %s. Please check the folder or run Data Check',Par.DMB.EventDir),  'E' ,0);
    return
else
    DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI. Processing ...',validTrialNum),  'I' ,0);
end
     

for trialInd = 1:validTrialNum,
    
        %%%%%%%%%%%%%%%%%%%%%%
        % Load Trial
        %%%%%%%%%%%%%%%%%%%%%%
        [Par.DMB,isOK]                    = Par.DMB.SetTrial(trialInd);
        [Par.DMB, SData.strEvent]         = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
        [Par.DMB, SData.imBehavior]       = Par.DMB.LoadBehaviorData(trialInd);
        
        % this code helps with sequential processing of the ROIs: use old one in the new image
        numROI                          = length(SData.strROI);
        if numROI < 1,
            DTP_ManageText([], sprintf('Multi Trial : There are no Events in trial %d. Trying to continue',trialInd),  'E' ,0);
            continue
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Process
        %%%%%%%%%%%%%%%%%%%%%%
        [Par,SData.strEvent]           = TPA_AnalysisEvents(Par,SData.strEvent,0);
        
         
        %%%%%%%%%%%%%%%%%%%%%%
        % Save back
        %%%%%%%%%%%%%%%%%%%%%%
        % start save
        Par.DMB                         = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'strEvent',SData.strEvent);                

end
DTP_ManageText([], sprintf('Multi Trial : Event activity is computed for %d trials.',validTrialNum),  'I' ,0);


return

