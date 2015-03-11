function [Par,dbROI,dbEvent] = TPA_MultiTrialScattering(Par,FigNum)
% TPA_MultiTrialScattering - uses routines from ALB
% 
% Inputs:
%   Par         - control structure 
%   
% Outputs:
%   Par         - control structure updated
%  dbEvent,dbROI - data bases

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 16.04 24.02.14 UD     Created
%-----------------------------

if nargin < 1,  error('Need Par structure');        end;
if nargin < 2,  FigNum      = 11;                  end;

if FigNum < 1, return; end;

% attach
%global SData SGui

% containers of events and rois
dbROI               = {};
dbRoiRowCount       = 0;
dbEvent             = {};
dbEventRowCount     = 0;


%%%%%%%%%%%%%%%%%%%%%%
% Setup & Get important parameters
%%%%%%%%%%%%%%%%%%%%%%
%tpSize          = Par.DMT.VideoSize;
%bhSize          = Par.DMB.VideoSideSize;
timeConvertFact      = Par.DMB.Resolution(4)/Par.DMT.Resolution(4);
                
                
%%%%%%%%%%%%%%%%%%%%%%
% Run over all files/trials and load the Analysis data
%%%%%%%%%%%%%%%%%%%%%%
validTrialNum           = length(Par.DMT.RoiFileNames);
if validTrialNum < 1,
    DTP_ManageText([], sprintf('Multi Trial : No TwoPhoton Analysis data in directory %s. Please check the folder or run Data Check',Par.DMT.RoiDir),  'E' ,0);
    return
end
validTrialNum           = min(validTrialNum,length(Par.DMB.EventFileNames));
if validTrialNum < 1,
    DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder or run Data Check',Par.DMB.EventDir),  'E' ,0);
    return
else
    DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI and Events. Reading ...',validTrialNum),  'I' ,0);
end
     

for trialInd = 1:validTrialNum,
    
    
        [Par.DMT, strROI]           = Par.DMT.LoadAnalysisData(trialInd,'strROI');
        % this code helps with sequential processing of the ROIs: use old one in the new image
        numROI                      = length(strROI);
        if numROI < 1,
            DTP_ManageText([], sprintf('Multi Trial : There are no ROIs in trial %d. Trying to continue',trialInd),  'E' ,0);
        end
        
        [Par.DMB, strEvent]         = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
        % this code helps with sequential processing of the ROIs: use old one in the new image
        numEvent                    = length(strEvent);
        if numEvent < 1,
            DTP_ManageText([], sprintf('Multi Trial : There are no events in trial %d. Trying to continue',trialInd),  'E' ,0);
        end
        
        % read the info
        for rInd = 1:numROI,
           dbRoiRowCount = dbRoiRowCount + 1;
           dbROI{dbRoiRowCount,1} = trialInd;
           dbROI{dbRoiRowCount,2} = rInd;                   % roi num
           dbROI{dbRoiRowCount,3} = strROI{rInd}.Name;      % name 
           dbROI{dbRoiRowCount,4} = strROI{rInd}.procROI;
        end
        
        % read the info
        for eInd = 1:numEvent,
           dbEventRowCount = dbEventRowCount + 1;
           dbEvent{dbEventRowCount,1} = trialInd;
           dbEvent{dbEventRowCount,2} = eInd;                   % roi num
           dbEvent{dbEventRowCount,3} = strEvent{eInd}.Name;      % name 
           dbEvent{dbEventRowCount,4} = strEvent{eInd}.TimeInd;
        end
        

end
DTP_ManageText([], sprintf('Multi Trial : Database Ready.'),  'I' ,0);


%%%%%%%%%%%%%%%%%%%%%%
% Find Unique names
%%%%%%%%%%%%%%%%%%%%%%
namesROI            = unique(strvcat(dbROI{:,3}),'rows');
namesEvent          = unique(strvcat(dbEvent{:,3}),'rows');

frameNum            = size(dbROI{1,4},1);
timeTwoPhoton       = (1:frameNum)';
        

[s,ok] = listdlg('PromptString','Select Cell / ROI :','ListString',namesROI,'SelectionMode','single');
if ~ok, return; end;

nameRefROI = namesROI(s,:);

figure(FigNum),set(gcf,'Tag','AnalysisROI'),clf;
procROI     = []; trialCount = 0;


%%%%%%%%%%%%%%%%%%%%%%
% Stuck them together
%%%%%%%%%%%%%%%%%%%%%%

for p = 1:size(dbROI,1),
    
    if ~strcmp(nameRefROI,dbROI{p,3}), continue; end;
    
    % get the data
    procROI = [procROI dbROI{p,4}];
    
end

%%%%%%%%%%%%%%%%%%%%%%
% Run classification
%%%%%%%%%%%%%%%%%%%%%%
ParALB          = ALB_InitParams;
ALB_ContinuousRun(ParALB, procROI);


return

