function [Par,StrEvent] = TPA_AnalysisEvents(Par,StrEvent,FigNum)
% TPA_AnalysisEvents - computes Event info for differnt regions.
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
% 20.00 24.02.15 UD     Event difference over the time
%-----------------------------

if nargin < 1,  Par         = TPA_ParInit;                  end;
if nargin < 2,  StrEvent    = {};                           end;
if nargin < 3,  FigNum      = 1;    end;


global SData;


% checks
[nR,nC,nZ,nT] = size(SData.imBehaive);

%%%%
% Check
%%%%

% check for multiple Z ROIs
numEvents              = length(StrEvent);
if numEvents < 1,
    DTP_ManageText([], sprintf('Behavior : No Event data is found. Please select/load Eventss'),  'E' ,0);
    return
end
% check for multiple Z ROIs
if ~isfield(StrEvent{1},'Ind') ,
    DTP_ManageText([], sprintf('Behavior :Something wrong with Event data. Export is not done properly'),  'E' ,0);
    return
end


% mark that Artifact processing is not valid
%Par.ArtifactCorrected  = false;

%%%%
% RUN
%%%%


DTP_ManageText([], sprintf('Event analysis : Started ...'),  'I' ,0), tic;


    
for k = 1:numEvents,
    % preproces ROI - filter using averaging with certain radius
    pixInd           = StrEvent{k}.Ind; % BUG in old files
    zInd             = StrEvent{k}.zInd; % whic Z it belongs
    
%     % define mask = old code compatability
%     imMask          = false(nR,nC);
%     imMask(pixInd)  = true;
    
%     % type of averaging - pass the info inside
%     if Par.Roi.ImposeAverageType,
%         Par.Roi.AverageType         = Par.ROI_AVERAGE_TYPES.MEAN;        
%     else
%         Par.Roi.AverageType         = StrEvent{k}.AverType;
%     end
%     
%     % init line 
%     [Par,RoiData]       = TPA_AverageROI(Par, 'Init', 0,imMask,0);
%     if isempty(RoiData), continue; end;
%         
%     % this info is used for iteration process
%     Par.Roi.TmpData         = RoiData; % save it
%     
%     % center of the ROI
%     lineInd         = RoiData.LineInd;
    % skeleton

    meanROI                     = zeros(nT,1);
    imFramePrev                 = squeeze(SData.imBehaive(:,:,zInd,1));
    for m = 1:nT,
        
        % image data for specific Z stack
        imFrame                 = squeeze(SData.imBehaive(:,:,zInd,m));
        %[Par,meanVal]           = TPA_AverageROI(Par, 'Process', imFrame,imMask,0);
        meanVal                 = mean(abs(imFrame(pixInd) - imFramePrev(pixInd)));
        meanROI(m,:)            = meanVal;
        imFramePrev             = imFrame;
        
    end;
    
    
    % save
    StrEvent{k}.meanROI   = meanROI;
    StrEvent{k}.procROI   = meanROI./max(meanROI);
    
end;
%Par.RoiAverageType         = saveRoiAverageType;

%Par.Roi.TmpData         = []; % cleanup
% output
% DataROI     = meanROI;
%Par.strROI  = strROI;
DTP_ManageText([], sprintf('Behavior : computed in %4.3f [sec]',toc),  'I' ,0)


if FigNum < 1, return; end;
    
%%% Concatenate all the ROIs in one Image
figure(FigNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
cmap  = jet(numEvents); eventNames = cell(1,numEvents);
for k = 1:numEvents,
    plot(1:nT,StrEvent{k}.meanROI,'color',cmap(k,:)); hold on;
    eventNames{k} = StrEvent{k}.Name;
end
hold off;
title('Behavior Motion Analysis'), axis tight;
xlabel('Frame [#]'), ylabel('Average motion between frames')
legend(eventNames);


return




