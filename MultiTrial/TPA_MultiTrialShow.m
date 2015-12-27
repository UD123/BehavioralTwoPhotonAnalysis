function [Par,dbROI,dbEvent] = TPA_MultiTrialShow(Par,FigNum)
% TPA_MultiTrialShow - loads data from the experiment.
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
           dbRoiRowCount = dbRoiRowCount + 1;
           dbROI{dbRoiRowCount,1} = trialInd;
           dbROI{dbRoiRowCount,2} = rInd;                   % roi num
           dbROI{dbRoiRowCount,3} = strROI{rInd}.Name;      % name 
           dbROI{dbRoiRowCount,4} = strROI{rInd}.procROI;
           newRoiExist = newRoiExist | isempty(strROI{rInd}.procROI);
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
           dbEvent{dbEventRowCount,4} = strEvent{eInd}.TimeInd;
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
namesEvent          = unique(strvcat(dbEvent{:,3}),'rows');

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



[nR,nC,nZ,nT]           = size(ImStack);
zStackInd               = 1; %Par.ZStackInd;

timeImage               = (1:nT);

% fixed with correct record load
frameTime               = median(diff(timeImage));  % time between consequitive frames



%%%%%%%%%%%%%%%%%%%%%%
% Show
%%%%%%%%%%%%%%%%%%%%%%
hcross = []; hrect = []; hRoiLine = []; hDetect = [];
ax     = zeros(3,numROI);
% FOR MARIA
for k = 1:numROI,
    %subplot(numROI,1,k),
    figure(FigNum + k),set(gcf,'Tag','AnalysisROI'),clf;
    subplot(7,1,[1 4]),imagesc(timeImage,1:size(strROI{k}.procROI,1),strROI{k}.procROI,Par.Roi.dFFRange), %colorbar;
    colorbar('NorthOutside')
    hold on;
    hcross(k) = plot([0 0],[0 0],'color','k','LineStyle','-.','LineWidth',2);
    hold off;
    ax(1,k) = gca;
    title(sprintf('dF/F : %s',strROI{k}.name)),
    ylabel('Line Pix'),
    
    subplot(7,1,[5 6]),plot(timeImage, timeImage*0);
    hold on;
    hrect(k) = plot([0 0],[0 0],'color','k','LineStyle',':');
    hold off;
    ax(2,k) = gca;
    ylabel('Amp [Volt]'),
    
    
    subplot(7,1,[7]),
    hRoiLine(k) = plot(timeImage, strROI{k}.procROI(1,:)); hold on;
    hDetect(k)  = plot(timeImage(1), strROI{k}.procROI(1,1),'.k','MarkerSize',14);
    ylim(Par.Roi.dFFRange)
    ax(3,k) = gca;

    ylabel(sprintf('dF/F : %d',1)),
    xlabel('Time [sec]'),


    linkaxes(ax(:,k),'x')
    
    % Install Cross Probing
    set(gcf,'WindowButtonDownFcn',@hFig1_wbdcb)
    %set(gcf,'WindowButtonMotionFcn',@hFig1_wbdcb)
    
    set(ax(:,k),'DrawMode','fast');

    
end;

% Prepare image data

% selection
m = 1;
k = k + 1;  % figure numbering    
figure(FigNum + k),hFig2 = gcf; set(hFig2,'Tag','AnalysisROI')
hIm  = imagesc(ImStack(:,:,zStackInd,m),Par.DataRange);  colorbar('east'); colormap(gray);
hTtl = title(sprintf('Fluorescence Image %s Time %d, ZStack %d',Par.expName,m,zStackInd),'interpreter','none');
hold on
roiNames = cell(numROI,1);
hRoi     = []; hLine = [];
for k = 1:numROI,
        
    hRoi(k)  = plot(strROI{k}.xy(:,1),strROI{k}.xy(:,2),'color',strROI{k}.color);
    roiNames{k} = strROI{k}.name; %sprintf('Border : %s',strROI{k}.name);

end;
hMark = plot(1,0,'oy','MarkerSize',1);

hold off
legend(roiNames,'interpreter','none')
%set(hFig2,'WindowButtonDownFcn',@hFig2_wbdcb)
%set(hFig2,'WindowButtonMotionFcn',@hFig2_wbdcb)



%%%%%%%%%%%%%%%%%%%%%%
% Install Cross Probing
%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%
    % hFig1 - Callbacks
    %%%%%%%%%%%%%%
    function hFig1_wbdcb(src,evnt)
        hFig1       = src;
        roiInd      = hFig1 - FigNum;  % which image has been clicked
        if strcmp(get(hFig1,'SelectionType'),'normal')
            %set(src,'pointer','circle')
            cp = get(ax(1,roiInd),'CurrentPoint');
            
            xinit = cp(1,1);
            xinit = (xinit) + [1 1]*0;
            XLim = get(gca,'XLim');        
            % check the point location
            if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
            
            %yinit = [yinit yinit];
            yinit = cp(1,2);
            yinit = round(yinit) + [1 1]*0;
            YLim = get(gca,'YLim');         
            if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
            
            % get all the info
            lineInd     = yinit(1);        % which ROI line index
            frameInd    = min(nT,ceil(xinit(1)/frameTime));        % frame number in time
            zStackInd   = strROI{roiInd}.zInd;
            
            % show cross
            figure(hFig1),
            axes(ax(1,roiInd))
            lineX     = [xinit NaN XLim];
            lineY     = [YLim NaN  yinit];
            set(hcross(roiInd),'XData',lineX,'YData',lineY);
            
            axes(ax(2,roiInd))
            YLim      = get(gca,'YLim'); 
            rectX     = [xinit xinit + frameTime xinit(1)];
            rectY     = [YLim YLim([2 1])         YLim(1)];
            set(hrect(roiInd),'XData',rectX,'YData',rectY);
            
            
            % show selected line of ROI
            axes(ax(3,roiInd))
            set(hRoiLine(roiInd) ,'ydata', strROI{roiInd}.procROI(lineInd,:));
            ylabel(sprintf('dF/F : %d',lineInd))
            
            % show detections
            ii         = find(strROI{roiInd}.procROI(lineInd,:) > Par.ResponseDetectThr); 
            respNum    = length(ii);
            if respNum < 1,
                DTP_ManageText([], sprintf('ROI %d : no responses found for Threshold %4.3f',roiInd, Par.ResponseDetectThr),  'W' ,0);
            elseif respNum > 1000,
                DTP_ManageText([], sprintf('ROI %d : %d too many responses found for Threshold %4.3f',roiInd, respNum,Par.ResponseDetectThr),  'W' ,0);
                respNum = 1000;                 ii = ii(1:respNum);
            else
                DTP_ManageText([], sprintf('ROI %d : %d responses found for Threshold %4.3f',roiInd, respNum,Par.ResponseDetectThr),  'I' ,0);
            end;
            set(hDetect(roiInd),'xdata',timeImage(ii),'ydata',strROI{roiInd}.procROI(lineInd,ii));
            
            % update image
            figure(hFig2),
            set(hIm,'cdata',ImStack(:,:,zStackInd,frameInd));
            %set(hTtl,'string',sprintf('Image %s  : Frame %d, ZStack %d',Par.expName,frameInd,zStackInd),'interpreter','none')
            set(hTtl,'string',sprintf('Image %s  : Time %4.2f, ZStack %d',Par.expName,xinit(1),zStackInd),'interpreter','none')
            % highlight appropritae ROI
            set(hRoi,'Visible','off');
            set(hRoi(roiInd),'Visible','on');
            
            
            
            % draw mark of location
            [rLine,cLine] = ind2sub([nR,nC],strROI{roiInd}.lineInd);
            set(hMark, 'xdata',cLine(lineInd),'ydata',rLine(lineInd),'MarkerSize',16);

            % return attention to figure 1
            figure(hFig1), 
            
            
        end
    end



end

