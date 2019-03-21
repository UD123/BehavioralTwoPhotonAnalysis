function [Par,dbROI,dbEvent] = TPA_MultiTrialRoiShow(Par,FigNum)
% TPA_MultiTrialRoiShow - loads data from the experiment.
% Preprocess it to build some sort of data base
% Inputs:
%   Par         - control structure 
%   
% Outputs:
%   Par         - control structure updated
%  dbEvent,dbROI - data bases

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 25.04 19.03.17 UD     Rename from TPA_MultiTrialShow
% 23.02 06.02.16 UD     Adding ROI Class suppport
% 22.02 12.01.16 UD     Adapted for new events   
% 19.07 03.10.14 UD     If proc data is empty - fix 
% 19.04 12.08.14 UD     Fixing bug of name comparison
% 17.08 05.04.14 UD     Support no behavioral data
% 17.02 10.03.14 UD     Compute database only when FigNum < 1
% 16.04 24.02.14 UD     Created
%-----------------------------

if nargin < 1,  error('Need Par structure');        end;
if nargin < 2,  FigNum      = 11;                  end;


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
%validTrialNum           = min(validTrialNum,length(Par.DMB.EventFileNames));
validBahaveTrialNum      = min(validTrialNum,length(Par.DMB.EventFileNames));
if validBahaveTrialNum < 1,
    DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder. Create this data or run Data Check',Par.DMB.EventDir),  'E' ,0);
    %return
else
    DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI and Events. Reading ...',validTrialNum),  'I' ,0);
end
     
newRoiExist = false; % estimate
for trialInd = 1:validTrialNum,
    
    
        [Par.DMT, strROI]           = Par.DMT.LoadAnalysisData(trialInd,'strROI');
        % this code helps with sequential processing of the ROIs: use old one in the new image
        numROI                      = length(strROI);
        if numROI < 1,
            DTP_ManageText([], sprintf('Multi Trial : There are no ROIs in trial %d. Trying to continue',trialInd),  'E' ,0);
        end
        
        
        % read the info
        for rInd = 1:numROI,
            
            if size(strROI{rInd}.Data,2)< 2,
                DTP_ManageText([], sprintf('Multi Trial : Trial %d, dF/F is not computed for ROI %s. Trying to continue',trialInd,strROI{rInd}.Name),  'E' ,0);
                continue;
            end
            
            
           dbRoiRowCount = dbRoiRowCount + 1;
           dbROI{dbRoiRowCount,1} = trialInd;
           dbROI{dbRoiRowCount,2} = rInd;                   % roi num
           dbROI{dbRoiRowCount,3} = strROI{rInd}.Name;      % name 
           dbROI{dbRoiRowCount,4} = strROI{rInd}.Data(:,2);
           newRoiExist = newRoiExist | isempty(strROI{rInd}.Data);
           %dbROI{dbRoiRowCount,4} = strROI{rInd}.meanROI;
        end
        
        if trialInd > validBahaveTrialNum, continue; end
        
        [Par.DMB, strEvent]         = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
        % this code helps with sequential processing of the ROIs: use old one in the new image
        numEvent                    = length(strEvent);
        if numEvent < 1,
            DTP_ManageText([], sprintf('Multi Trial : There are no events in trial %d. Trying to continue',trialInd),  'E' ,0);
        end
        
        
        % read the info
        for eInd = 1:numEvent,
           dbEventRowCount = dbEventRowCount + 1;
           dbEvent{dbEventRowCount,1} = trialInd;
           dbEvent{dbEventRowCount,2} = eInd;                   % roi num
           dbEvent{dbEventRowCount,3} = strEvent{eInd}.Name;      % name 
           dbEvent{dbEventRowCount,4} = strEvent{eInd}.tInd;
        end
        

end
DTP_ManageText([], sprintf('Multi Trial : Database Ready.'),  'I' ,0);

if FigNum < 1, return; end;

% check new names
if newRoiExist,
    DTP_ManageText([], sprintf('Preview : You need to rerun dF/F analysis. '), 'E' ,0)   ; 
    return
end


%%%%%%%%%%%%%%%%%%%%%%
% Find Unique names
%%%%%%%%%%%%%%%%%%%%%%
namesROI            = unique(strvcat(dbROI{:,3}),'rows');
%namesEvent          = unique(strvcat(dbEvent{:,3}),'rows');

frameNum            = size(dbROI{1,4},1);
timeTwoPhoton       = (1:frameNum)';
        

[s,ok] = listdlg('PromptString','Select Cell / ROI :','ListString',namesROI,'SelectionMode','single');
if ~ok, return; end;

nameRefROI          = dbROI{s,3}; %namesROI(s,:);

figure(FigNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
procROI             = []; trialCount = 0;
trialSkip           = max(Par.Roi.dFFRange)/2;

for p = 1:size(dbROI,1),
    
    if ~strcmp(nameRefROI,dbROI{p,3}), continue; end;
    
    procROI = dbROI{p,4};
    if isempty(procROI), text(10,p*10,'No dF/F data found'); continue; end;
    
    % get the data
    %procROI = [procROI dbROI{p,4}];
    
    % get trial and get events
    trialInd    = dbROI{p,1};
    trialCount  = trialCount + 1;
    
    % find all the events taht are in trial p
    if validBahaveTrialNum > 0,
        eventInd = find(trialInd == [dbEvent{:,1}]);
    else
        eventInd = [];
    end
    
    % show trial with shift
    pos  = trialSkip*(trialCount - 1);
    clr  = rand(1,3);
    plot(timeTwoPhoton,procROI+pos,'color',clr); hold on;
    plot(timeTwoPhoton,zeros(frameNum,1) + pos,':','color',[.7 .7 .7]);
    
    for m = 1:length(eventInd),
        tt = dbEvent{eventInd(m),4} / timeConvertFact; %/timeConvertFact;
        if isempty(tt),continue; end
        %plot(tt,-ones(1,2)/2,'*','color',clr);
        h = rectangle('pos',[tt(1) pos-0.5 diff(tt) 0.1 ])   ;
        set(h,'FaceColor',clr)
    end
    
end
ylabel('Trial Num'),xlabel('Frame Num')
hold off
%ylim([-1.5 2])
title(sprintf('Trials and Events for %s',nameRefROI))

return


