function [Par,dbROI,dbEvent] = TPA_MultiTrialDetectShowSpikes(Par,FigNum)
% TPA_MultiTrialDetectShowSpikes - loads data from the experiment.
% Preprocess it to build some sort of data base.
% Shows two photon events - detections of the spikes
% Inputs:
%   Par         - control structure 
%   
% Outputs:
%   Par         - control structure updated
%  dbEvent,dbROI - data bases

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 19.22 12.02.15 UD     Show spike data in delay form 
%-----------------------------

if nargin < 1,  error('Need Par structure');        end;
if nargin < 2,  FigNum      = 11;                  end;



% containers of events and rois
obj.MngrData                = TPA_MultiTrialDataManager();
obj.MngrData                = Init(obj.MngrData,Par);


% select traces per roi and event
isAligned                   = false;
[obj, dataStr]              = TraceTablePerRoiEvent(obj,roiName,eventName,isAligned);    



%%%%%%%%%%%%%%%%%%%%%%
% Select Unique names
%%%%%%%%%%%%%%%%%%%%%%
namesROI            = unique(strvcat(dbROI{:,3}),'rows');
namesEvent          = unique(strvcat(dbEvent{:,3}),'rows');

frameNum            = size(dbROI{1,4},1);
timeTwoPhoton       = (1:frameNum)';
        

[s,ok] = listdlg('PromptString','Select Cell / ROI :','ListString',namesROI,'SelectionMode','single');
if ~ok, return; end;

nameRefROI          = dbROI{s,3}; %namesROI(s,:);

figure(FigNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
procROI             = []; trialCount = 0;
trialSkip           = max(Par.dFFRange)/2;

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
    eventInd = find(trialInd == [dbEvent{:,1}]);
    
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

