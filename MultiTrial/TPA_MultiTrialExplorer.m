function [Par] = TPA_MultiTrialExplorer(Par)
%
% TPA_MultiTrialExplorer - Graphical interface to see the results of behavioral and two photon experiments
%
% Depend:     Analysis data set from behavioral and two photon trials.
%
% Input:      Par               - structure of differnt constants
%             TPA_XXX.mat       - results of multiple trials -
%             BDA_YYY.mat       - results of multiple trials
%

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 28.14 01.04.18 UD     Range for Behavioral data
% 28.04 15.01.18 UD     Fixing export
% 27.10 08.11.17 UD     Ading averaging
% 27.03 18.10.17 UD     Fixing show for Trajectories
% 26.04 02.07.17 UD     Browsing improved
% 26.02 13.06.17 UD     Show spatial position
% 25.09 30.04.17 UD     Review behavior show
% 25.06 05.04.17 UD     Efficient behavior show
% 25.05 03.04.17 UD     Adding button for fluorescence
% 25.04 19.03.17 UD     Adapting for Brightness
% 24.10 15.11.16 UD     Max of dF/F for Shahar.
% 24.05 16.08.16 UD     Resolution is not an integer.
% 23.13 03.05.16 UD     manual Edit spike save fixed
% 23.12 19.04.16 UD     manual Edit spike heigh
% 23.11 05.04.16 UD     Text fix and Ethogram with Roi traces (Option 2)
% 23.04 29.03.16 UD     Ethogram + Spike editor
% 23.03 15.02.16 UD     Spike detection save
% 22.02 12.01.16 UD     Fixing title
% 21.22 29.12.15 UD     Changing Spike Detect interface
% 21.14 24.11.15 UD     Spike Detect configuration.
% 21.13 24.11.15 UD     Fixing text - interpreter
% 20.12 27.07.15 UD     Crossprobing
% 20.04 17.05.15 UD     Event data is continuos
% 19.28 28.04.15 UD     Togle image view.
% 19.23 17.02.15 UD     Togle text labels.
% 19.22 15.02.15 UD     Spike detection.
% 19.21 27.01.15 UD     Adding Axis change.
% 19.17 06.01.15 UD     Fixing title bug.
% 19.16 23.12.14 UD     adding another coursor.
% 19.15 18.12.14 UD     adding coursors.
% 19.13 03.11.14 UD     high quality image extraction and color addition.
% 19.11 16.10.14 UD     changes in IF of the data manager. Events and Roi names become cell arrays
% 19.00 12.07.14 UD     Query support
% 18.10 09.07.14 UD     Group support. Adding traces per Event
% 18.09 06.07.14 UD     Traces per ROI. Support of Analysis load without TwoPhoton data
% 18.04 28.04.14 UD     Export to Excel
% 17.05 24.03.14 UD     Alignment bug fix
% 17.04 23.03.14 UD     No Event Protection
% 16.16 24.02.14 UD     Created
%-----------------------------

%
global SGui SData;

% Init Data manager
mngrData        = TPA_MultiTrialDataManager();
mngrData        = mngrData.Init(Par);

% checks
[mngrData,IsOK] = mngrData.CheckDataFromTrials();
if ~IsOK, return; end
 mngrData       = mngrData.LoadDataFromTrials();
 
% spike detect management : inside mngrData
%mngrTPED        = TPA_TwoPhotonEventDetect();



% % prepare for Test
% if nargin < 1,
%     Par         = [];
%     mngrData    = mngrData.TestLoad(); % get the test data
% else
% end

roiNames    = mngrData.GetRoiNames();
eventNames  = mngrData.GetEventNames();
% protect
if isempty(eventNames), eventNames{1} = 'None'; end;
%eventNames = char(eventNames,'Query');

% number of frames in the image - updated by axis rendering
imFrameNum          = 2; % communication between axis

% structure with GUI handles
handStr             = [];

% GUI Constants
PLOT_TYPES          = {'ROIs & Events per Trial','Traces per ROI & Event','Traces per Event, ROIs & Trials','Traces Aligned per Event, ROIs & Trials','Traces Averaged per Event, ROIs & Trials','Traces per ROI','Traces per Events (Ethogram)'};
aW                  = 0.72;
axisViewPosUp       = [[0.05 0.05 aW 0.1];[0.05 0.16 aW 0.05];[0.05 0.22 aW 0.73]]; % spatial loc
axisViewPosDwn      = [[0.05 0.05 aW 0.7];[0.05 0.76 aW 0.05];[0.05 0.82 aW 0.15]];
axisViewPosMid      = [[0.05 0.05 aW 0.4];[0.05 0.45 aW 0.05];[0.05 0.5 aW 0.45]];

% handle to plots
handSpikePlot       = [];

% color management
TraceColorMap       = Par.Roi.TraceColorMap ;
MaxColorNum         = size(TraceColorMap,1); %Par.Roi.MaxColorNum;
trialSkip           = max(Par.Roi.dFFRange)/2;  % the distance between lines

EthogramColorMap       = [1 1 1;... % white background
                          0 0 1;... % lift
                          0 1 0;... % grab
                          1 0 0;... % at mouth
                          1 0 0;... % chew
                          0 0.8 0.8;... % table
                          0.7 0.7 0.7;... % back to perch
                          ];



% pass info from render to Export
dataStrForExport    = [];
cursorPosition      = [1 1]; % two cursor data 
lastClickPosition   = [1 1]; % x,y coordintaes
cursorSelection     = 0; % which cursor to move 
enableTextLabel     = true;
enableImageShow     = false;  % show image data instead of plots
enableSpikeShow     = false;  % show image data instead of plots
enableCursorShow    = false;  % show cursors
enableSpikeEdit     = false;  % enable spike edit tool
enableBrightShow    = false;  % show brightness patterns
enableElectroShow   = true;  % keeps the show of the behavioral data as lot lines
enableEthogram      = false;  % show ethogram

trialIdPrev         = 0;      % previous trial index
sliceIdPrev         = 1;      % save previous trial

% Render all
fCreateGUI();
fUpdateGUI();

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% Fun starts here


% ----------------------------------------------------------------
% Update Roi and Aver axis

    function fRenderRoiTraceAxis(DataStr)
        % draw cell traces
        if nargin < 1, error('DataStr is required'); end;
        if ~isfield(DataStr,'Roi'), 
            errordlg('Must have Roi structure. Could be that no Events or ROIs are found'); 
            return
        end
        
        dbROI               = DataStr.Roi ;
        axes(handStr.hAxTraces), cla, hold on; %set(handStr.hAxTraces,'nextplot','add') % current view
        xlim([1 imFrameNum]);
         %set(handStr.hAxTraces,'nextplot','add') % current view
        handSpikePlot       = [];

        if isempty(dbROI),
             set(handStr.hTtl,'string','No Trace data found for this selection','color','r')
             DTP_ManageText([], sprintf('Multi Trial : No ROI data found for this selection.'),  'W' ,0);
             %plot(handStr.hAxAver,1:imFrameNum,zeros(1,imFrameNum),'color','r');    % remove old trace
             axes(handStr.hAxAver), cla, xlim([1 imFrameNum]);
             return
        end

        frameNum            = size(dbROI{1,4},1);
        traceNum            = size(dbROI,1);
        trialSkip           = max(Par.Roi.dFFRange(2))/2;  % the distance between lines

        
        % stupid protect when no dF/F data
        if frameNum < 1
            mtrxTraces      = [dbROI(:,4)];
            frameNum        = max(100,size(mtrxTraces,1));
        end
         timeTwoPhoton      = (1:frameNum)';
         imFrameNum         = max(1,frameNum);  % communicates info to the second axis manager
       
        % ------------------------------------------        
        meanTrace           = zeros(frameNum,1);
        currTraces          = zeros(frameNum,traceNum);
        meanTraceCnt        = 0;
        
        % show image
        if enableImageShow && ~enableBrightShow
            trialSpace       = trialSkip;
        elseif enableBrightShow
            trialSpace       = Par.Roi.DataRange(2);
        else
            trialSpace       = trialSkip;
        end
        

        for p = 1:traceNum
                        
            % show trial with shift
            pos     = trialSpace*(p - 1);
            
            
            % draw traces
            if ~isempty(dbROI{p,4}) % protect from empty
                tId     = dbROI{p,1};
                clr     = TraceColorMap(mod(tId,MaxColorNum)+1,:);
                if ~enableImageShow
                    if enableSpikeShow
                        plot(handStr.hAxTraces,timeTwoPhoton,dbROI{p,4}+pos,'color',clr);  hold on ;
                        handSpikePlot(p) = plot(handStr.hAxTraces,timeTwoPhoton,dbROI{p,5}+pos,'color',1-clr);
                    elseif enableBrightShow
                        plot(handStr.hAxTraces,timeTwoPhoton,dbROI{p,6}+pos,'color',clr);  hold on ;
                    else
                        plot(handStr.hAxTraces,timeTwoPhoton,dbROI{p,4}+pos,'color',clr);  hold on ;
                    end
                else
                    if enableSpikeShow
                        currTraces(:,p) = dbROI{p,5};
                    elseif enableBrightShow
                        currTraces(:,p) = dbROI{p,6};
                    else
                        currTraces(:,p) = dbROI{p,4};
                    end
                end
                meanTrace    = meanTrace    + dbROI{p,4};
                meanTraceCnt = meanTraceCnt + 1;
            end
            % draw ref lines
            if ~enableImageShow            
                 plot(handStr.hAxTraces,timeTwoPhoton,zeros(frameNum,1) + pos,':','color',[.7 .7 .7]); hold on;
            end
        end
        
        % show image
        if enableImageShow
            imagesc(timeTwoPhoton,(1:traceNum),currTraces',[-.1 trialSpace]);
            colormap(TraceColorMap)
            trialSpace       = 1;
            textOffset      = 0;
        else
            %trialSpace       = trialSkip;
            textOffset      = 1;
        end
        
        % show names
        if enableTextLabel
            for p = 1:traceNum
                roiName         = sprintf('T-%2d: %s',dbROI{p,1},dbROI{p,3});
                pos             = trialSpace*(p - textOffset);
                text(timeTwoPhoton(3),pos + 0.2,roiName,'color','w','FontSize',8,'interpreter','none');
            end
        end
        
        
        ylabel('Trace Num'),%xlabel('Frame Num')
        ylim([-0.5 trialSpace*traceNum+0.5]),%axis tight
        hold off
        
        % ------------------------------------------
        axes(handStr.hAxAver), cla, hold on; %
        % deal with average
        meanTrace = meanTrace/max(1,meanTraceCnt);
        plot(handStr.hAxAver,timeTwoPhoton,meanTrace,'color','r');  hold on;
        % draw ref lines
        plot(handStr.hAxAver,timeTwoPhoton,zeros(frameNum,1),':','color',[.7 .7 .7]); hold off 
        ylabel('Aver'),%xlabel('Frame Num')
        ylim([-0.5 trialSkip+0.5]), axis tight;
                
        %colorbar('peer',handStr.hAxAver,'east');

        
        % print for shahar
        [mv,mi] = max(meanTrace);
        if enableBrightShow 
            txt = 'Fluorescence'; 
        else
            txt = 'dF/F';
        end
        DTP_ManageText([], sprintf('Multi Trial : Average %s : Max Value %f Frame %d.',txt,mv,mi),  'I' ,0);

        
    end

% ----------------------------------------------------------------
% Update Event axis

    function fRenderEventTraceAxis(DataStr)
        % draw events 
        if nargin < 1, error('DataStr is required'); end;
        if ~isfield(DataStr,'Event'), 
            errordlg('Must have Event structure. Could be that no Events or ROIs are found'); 
            return
        end
        
        dbEvent               = DataStr.Event ;
        axes(handStr.hAxBehave), cla, hold on; %set(handStr.hAxTraces,'nextplot','add') % current view
        
        if isempty(dbEvent),
             set(handStr.hTtl,'string','No Bahavior data found for this selection','color','r')
             DTP_ManageText([], sprintf('Multi Trial : No Event data found for this selection.'),  'W' ,0);
             %return
        end
        eventSkip           = 1; %Par.Event.DataRange(2);         % the distance between lines - pixels
        eventMin            = Par.Event.DataRange(1);
        eventNorm           = diff(Par.Event.DataRange);
        
        % specify at least one event to reset axis
        eventNum            = size(dbEvent,1);
        
        % this time should be already aligned to TwoPhoton
        timeBehavior           = (1:imFrameNum)';
        currEvents             = zeros(imFrameNum,eventNum);

       
        enbShowImage = enableImageShow && enableElectroShow;
        
        % ------------------------------------------        
        for p = 1:eventNum
                        
            % show trial with shift
            pos         = eventSkip*(p - 1);

            eventData   = timeBehavior*0;
            
            % draw traces
            if ~isempty(dbEvent{p,4}) % protect from empty
                tId         = dbEvent{p,1};
                if enbShowImage
                clr         = TraceColorMap(mod(tId,MaxColorNum)+1,:);
                else
                clr         = 'y';    
                end
                sigLen      = length(dbEvent{p,4}); % vector
                if sigLen > imFrameNum
                    eventData   = dbEvent{p,4}(1:imFrameNum);%0.5;
                else
                    eventData(1:sigLen) = dbEvent{p,4}(1:sigLen);%0.5;
                    eventData(1+sigLen:imFrameNum) = eventData(sigLen);
                end
                eventData           = (eventData - eventMin)./eventNorm;
                
                if ~enbShowImage
                    plot(handStr.hAxBehave,timeBehavior,eventData+pos,'color',clr);  hold on ;
                else
                    currEvents(:,p) = eventData;
                end
            end
                            
            % draw ref lines
            if ~enbShowImage
            plot(handStr.hAxBehave,timeBehavior,zeros(imFrameNum,1) + pos,':','color',[.7 .7 .7]); hold on 
            end
          
        end
        
        % show image
        if enbShowImage
            
            % normalize event data for brightness
            if max(currEvents(:)) > 50
                %currEvents = bsxfun(@minus,currEvents,min(currEvents)); 
                %currEvents = bsxfun(@rdivide,currEvents,max(currEvents))*eventSkip; 
                currEvents = currEvents./128*eventSkip; % divide by 128 and not 255 since average is low
            end
            
            if ~enableEthogram
                imagesc(timeBehavior,1:eventNum,currEvents',[-.1 eventSkip]);
                colormap(TraceColorMap);
            else
                imagesc(timeBehavior,1:eventNum,currEvents',[ 1 6]);
                colormap(EthogramColorMap)
            end
            eventSkip       = 1;
            textOffset      = 0;

        else
            textOffset      = 1;
        end
        
        % show names
        if enableTextLabel
            for p = 1:eventNum
                eventName       = sprintf('T-%2d: %s',dbEvent{p,1},dbEvent{p,3});
                pos             = eventSkip*(p - textOffset);
                text(timeBehavior(3),pos + 0.2,eventName,'color','k','FontSize',8,'interpreter','none');
            end
        end
        
        ylabel('Event Num'),xlabel('Frame Num')
        ylim([-0.2 eventSkip*eventNum+0.5]),xlim([1 imFrameNum]);axis tight
        hold off
        %set(handStr.hTtl,'string',sprintf('%d Traces of dF/F',eventNum),'color','w')
                
        %colorbar('peer',handStr.hAxBehave,'EastOutside');

    end

% ----------------------------------------------------------------
% Change axis

    function fAxisExpand(hObject, eventdata, selInd)
        % arranges all the views

        %%%
        % change axis position according to Plot View method selected
        %%%
        switch selInd,
            case 1, % Traces
                set(handStr.hAxTraces,  'pos',axisViewPosUp(3,:));
                set(handStr.hAxAver,    'pos',axisViewPosUp(2,:));
                set(handStr.hAxBehave,  'pos',axisViewPosUp(1,:));
            case 2, % Equal
                set(handStr.hAxTraces,  'pos',axisViewPosMid(3,:));
                set(handStr.hAxAver,    'pos',axisViewPosMid(2,:));
                set(handStr.hAxBehave,  'pos',axisViewPosMid(1,:));
           case 3, % Behave
                set(handStr.hAxTraces,  'pos',axisViewPosDwn(3,:));
                set(handStr.hAxAver,    'pos',axisViewPosDwn(2,:));
                set(handStr.hAxBehave,  'pos',axisViewPosDwn(1,:));
            otherwise
                error('Bad plotIndexSelected')
        end
        
    end

% ----------------------------------------------------------------
% Render axis

    function fAxisManager(hObject, eventdata)
        % arranges all the views
        %         get(handles.figure1,'SelectionType');
        %         % If double click
        %         if strcmp(get(handles.figure1,'SelectionType'),'open')
        trialIndexSelected = get(handStr.hTrialListBox,'Value');
        roiIndexSelected   = get(handStr.hRoiListBox,'Value');
        eventIndexSelected = get(handStr.hEventListBox,'Value');
        plotIndexSelected  = get(handStr.hPlotPopup,'Value');
                
        if enableBrightShow 
            txt = 'Fluorescence'; 
        else
            txt = 'dF/F';
        end
        enableEthogram = false;
        
        
        %%%
        % change axis position according to Plot View method selected
        %%%
        switch PLOT_TYPES{plotIndexSelected},
            case PLOT_TYPES([1 4 5 6])
                set(handStr.hAxTraces,  'pos',axisViewPosUp(3,:));
                set(handStr.hAxAver,    'pos',axisViewPosUp(2,:));
                set(handStr.hAxBehave,  'pos',axisViewPosUp(1,:));
            case PLOT_TYPES([2 3])
                set(handStr.hAxTraces,  'pos',axisViewPosMid(3,:));
                set(handStr.hAxAver,    'pos',axisViewPosMid(2,:));
                set(handStr.hAxBehave,  'pos',axisViewPosMid(1,:));
            case PLOT_TYPES([7]) % traces per event + ethogram
                set(handStr.hAxTraces,  'pos',axisViewPosDwn(3,:));
                set(handStr.hAxAver,    'pos',axisViewPosDwn(2,:));
                set(handStr.hAxBehave,  'pos',axisViewPosDwn(1,:));
            otherwise
                error('Bad plotIndexSelected')
        end
        
        %%%
        % Do different computation to extract data for the current view
        %%%
        switch PLOT_TYPES{plotIndexSelected}
            case PLOT_TYPES{1}
                % roi and event per trace
                 % get traces
                dataStr             = mngrData.TracesPerTrial(trialIndexSelected(1));
                ttlTxt              = sprintf('All %s Traces for trial %d',txt,trialIndexSelected(1));
            case PLOT_TYPES{2}
                % traces per roi and event ethogram
                %dataStr             = mngrData.TracesPerRoiEvent(roiNames{roiIndexSelected(1)},eventNames{eventIndexSelected(1)});
                dataStr             = mngrData.TracesPerRoiEventEthogram(roiNames{roiIndexSelected(1)},eventNames(eventIndexSelected));
                ttlTxt              = sprintf('All %s Traces for Roi %s and Event %s ',txt,roiNames{roiIndexSelected(1)},eventNames{eventIndexSelected(1)});
            case PLOT_TYPES{3}
                dataStr             = mngrData.TracePerEventRoiTrial(eventNames{eventIndexSelected(1)},roiIndexSelected,trialIndexSelected);
                ttlTxt              = sprintf('All %s Traces per Event %s ',txt,eventNames{eventIndexSelected(1)});
            case PLOT_TYPES{4}
                dataStr             = mngrData.TraceAlignedPerEventRoiTrial(eventNames{eventIndexSelected(1)},roiIndexSelected,trialIndexSelected);                
                ttlTxt              = sprintf('All %s Traces Aligned per Event %s ',txt,eventNames{eventIndexSelected(1)});
            case PLOT_TYPES{5}
                % averaged traces per selected trials
                dataStr             = mngrData.TraceAveragedPerEventRoiTrial(eventNames{eventIndexSelected(1)},roiIndexSelected,trialIndexSelected);                
                ttlTxt              = sprintf('All %s Traces Averaged per Event %s ',txt,eventNames{eventIndexSelected(1)});
            case PLOT_TYPES{6}
                % traces per roi - for all events
                dataStr             = mngrData.TracesPerRoi(roiNames{roiIndexSelected(1)});
                ttlTxt              = sprintf('All %s Traces for Roi %s ',txt,roiNames{roiIndexSelected(1)});
            case PLOT_TYPES{7}
                % trials per event - for all rois
                %dataStr             = mngrData.TrialsPerEvent(eventNames{eventIndexSelected(1)});
                dataStr             = mngrData.EventEthogram(eventNames(eventIndexSelected));
                ttlTxt              = sprintf('All Trials for Event %s ',eventNames{eventIndexSelected(1)});
                enableEthogram      = true;
                
            otherwise
                disp('Bad plotIndexSelected')
        end
        
        % transform to spike detection
        enableSpikeShow     =  strcmp(get(handStr.hShowSpikes,'State'),'on');
        
        % check if to render text labels
        enableTextLabel     = strcmp(get(handStr.hShowText,'State'),'on');
        
        % check if to show image data or plot
        enableImageShow     = strcmp(get(handStr.hShowImage,'State'),'on');
        
        % show cursors
        enableCursorShow    = strcmp(get(handStr.hShowCursor,'State'),'on');
        
        % edit spikes
        enableSpikeEdit    = strcmp(get(handStr.hEditSpikes,'State'),'on');
        
        % edit spikes
        enableBrightShow    = strcmp(get(handStr.hShowBright,'State'),'on');
        
        
        % render
        fRenderRoiTraceAxis(dataStr);                
        fRenderEventTraceAxis(dataStr);
        set(handStr.hTtl,'string',ttlTxt,'color','w');
        
        % save data for export and cursor cross probing         
        dataStrForExport = dataStr;
        
%         % enable spike manual editor
%         if enableSpikeEdit
%             set(handStr.hFig,'WindowButtonDownFcn',@fSpikeMouseDown);
%         else
%             set(handStr.hFig,'WindowButtonDownFcn',@fUpdateCursors);
%         end

        
        
    end

%-----------------------------------------------------
% Update GUI with new Info :  list boxes

    function fUpdateGUI(o,e)
        
        % update axis
        fAxisManager(0,0);
        
        % update cursors since axis size could change
        fManageCursors(0,0);
        
        % update spikes if has been changed
        fUpdateSpikes(0,0);
        
        % update spatial position
        fShowCellSpatialLocation(0,0);
        
    end

%-----------------------------------------------------
% Update Colors from Color :  list boxes

    function fUpdateColor(o,e)
        %Refresh the image & plot
        
        val             = get(handStr.hColormapPopup,'val');
        nameColormap    = get(handStr.hColormapPopup,'string');
        colName         = strtrim(nameColormap(val,:));
        
        switch colName
            case 'yellow',  TraceColorMap = repmat([1  1 0],MaxColorNum,1);
            case 'red',     TraceColorMap = repmat([.7 0 0],MaxColorNum,1);
            case 'green',   TraceColorMap = repmat([0 0.7 0],MaxColorNum,1);
            case 'blue',    TraceColorMap = repmat([0 0 0.8],MaxColorNum,1);
            case 'cyan',    TraceColorMap = repmat([0 .8 0.8],MaxColorNum,1);
            otherwise % standard
                            TraceColorMap = colormap(colName);
        end
        %TraceColorMap   = TraceColorMap(randperm(MaxColorNum),:);

        % update all
        fUpdateGUI(0,0);
        
    end

%-----------------------------------------------------
% Update Color range :  User Input

    function fConfigTwoPhotonRange(o,e,t)
        %Refresh the image & plot
        
        fRange                = Par.Roi.DataRange;
        dRange                = Par.Roi.dFFRange;
        
        % config small GUI
        isOK                  = false; % support next level function
        options.Resize        ='on';
        options.WindowStyle   ='modal';
        options.Interpreter   ='none';
        prompt                = {'Fluorescence Data Range [Min Max] values',...
                                'dF/F Data Range [Min Max values]',...            
                                };
        name                = 'Config Color Range Parameters';
        numlines            = 1;
        defaultanswer       = {num2str(fRange),num2str(dRange)};
        answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
        if isempty(answer), return; end
        
        
        % try to configure
        fRange              = str2num(answer{1});
        dRange              = str2num(answer{2});
        
        % check
        if numel(fRange) ~= 2, errordlg('Fluorescence range must be a vector of 2 values'); end
        if numel(dRange) ~= 2, errordlg('dF/F Range must be a vector of 2 values'); end
        
        % save
        Par.Roi.DataRange   = max(-1,min(10000,fRange));
        Par.Roi.dFFRange    = max(-1,min(5,dRange));

        % update all
        fUpdateGUI(0,0);
        
    end

%-----------------------------------------------------
% Update Data range :  User Input

    function fConfigBehavioralRange(o,e,t)
        %Refresh the image & plot
        
        dRange                = Par.Event.DataRange;
        
        % config small GUI
        isOK                  = false; % support next level function
        options.Resize        ='on';
        options.WindowStyle   ='modal';
        options.Interpreter   ='none';
        prompt                = {'Behavioral Data Range [-1 1000] values',...
                                };
        name                = 'Config Behavioral Data Range Parameters';
        numlines            = 1;
        defaultanswer       = {num2str(dRange)};
        answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
        if isempty(answer), return; end
        
        
        % try to configure
        dRange              = str2num(answer{1});
        
        % check
        if numel(dRange) ~= 2, errordlg('Data Range must be a vector of 2 values'); end
        
        % save
        Par.Event.DataRange   = max(-1,min(10000,dRange));

        % update all
        fUpdateGUI(0,0);
        
    end


%-----------------------------------------------------
% Update Data range :  Switch between user show of the plot lines

    function fSwitchElectroPhysShow(o,e,t)
        %Refresh the image & plot
        
        enableElectroShow = ~enableElectroShow;
        
        % update all
        fUpdateGUI(0,0);
        
    end


%-----------------------------------------------------
% Export button pressed

    function fExportCallback(hObject, eventdata)
        
        % prepare data for export        
        Par = TPA_ExportDataToExcel(Par,'MultiTrial',dataStrForExport,enableBrightShow);
        
    end

%-----------------------------------------------------
% Update Group Info :  

    function fUpdateGroup(o,e)
        % Save relevant info and form a new group
        dmGroup      = TPA_DataManagerGroup();

        % different param collect
        dmGroup      = dmGroup.Init(Par);
        
        % save selection
        dmGroup      = dmGroup.SetGroupInfo(dataStrForExport);
              
        % save selection
        dmGroup      = dmGroup.SaveToFile();
        
        
    end

%-----------------------------------------------------
% Manage GUI cursors and response to button click

    function fManageCursors(o,e)
        
        % argument sel is passed from contextmenu
        enableCursorShow    = strcmp(get(handStr.hShowCursor,'State'),'on');
        
        % check the toggle state
        if ~enableCursorShow, %strcmp(get(handStr.hShowCursor,'State'),'off'),
            % delte/hide cursors
            if ishandle(handStr.hCursorUp), % could be cleared by cla
                set([handStr.hCursorUp handStr.hCursorMid handStr.hCursorDwn], 'Visible','off');
            end
            cursorSelection = 1;
        else
            % show cursors new pos
            if ~ishandle(handStr.hCursorUp), % could be cleared by cla    
                % create new
                handStr.hCursorUp = line([1 1;1 1],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',handStr.hAxTraces,'UIContextMenu', handStr.hClickMenu);
                handStr.hCursorMid = line([1 1;1 1],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',handStr.hAxAver);
                handStr.hCursorDwn = line([1 1;1 1],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',handStr.hAxBehave,'UIContextMenu', handStr.hClickMenu);
            end 
            for m = 1:2,
                xx = [cursorPosition(m) cursorPosition(m)];
                set(handStr.hCursorUp(m), 'xdata',xx,'ydata', get(handStr.hAxTraces,'ylim'));
                set(handStr.hCursorMid(m), 'xdata',xx,'ydata',get(handStr.hAxAver,'ylim'));
                set(handStr.hCursorDwn(m), 'xdata',xx,'ydata',get(handStr.hAxBehave,'ylim'));
            end
            set([handStr.hCursorUp handStr.hCursorMid handStr.hCursorDwn], 'Visible','on');
            set(handStr.hTtl,'string',sprintf('Cursors 1 : %3d, 2 : %d, Diff : %3d',cursorPosition(1),cursorPosition(2),abs(diff(cursorPosition))));
            
            
        end
    end

%-----------------------------------------------------
% Update Cursor position. Snap to the closest point

    function fUpdateCursors(src,evnt)
        
    % get which button is clicked
    clickType   = get(src,'Selectiontype');
    leftClick   = strcmp(clickType,'normal');
    rightClick  = strcmp(clickType,'alt');

    cp          = get(gca,'CurrentPoint');
    xinit       = cp(1,1);yinit = cp(1,2);
    XLim        = get(gca,'XLim');        
    YLim        = get(gca,'YLim');        
    % check the point location
    if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
    if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
    lastClickPosition = round([xinit yinit]);
        
      if leftClick,
            %set(src,'pointer','circle')
            % which cursor is selected
            mI              = max(1,min(2,cursorSelection)) ;
            cursorPosition(mI) = round(xinit);
            fManageCursors(0,0);
      end
      if rightClick,
          
      end
            
    end

%-----------------------------------------------------
% Get Trial Id from the screen

    function [trialInd,imageId,trialId] = fGetTrialImage(newClickPosition)
        % convert click to trial
        if nargin < 1, newClickPosition = lastClickPosition; end;
        
        % argument sel is passed from contextmenu
        trialInd = []; imageId = []; trialId = [];
        
        % check if enabled

        dbROI               = dataStrForExport.Roi;
        if isempty(dbROI),  dbROI = dataStrForExport.Event; end;
        if isempty(dbROI),  return; end;
                
        trialInd            = cell2mat(dbROI(:,1));
        
        % Do different computation according to the current view
        trialIndexSelected = get(handStr.hTrialListBox,'Value');
        trialNum            = numel(trialIndexSelected);
        if enableImageShow,
            clickTrial      = newClickPosition(2);
        else
            clickTrial      = ceil(newClickPosition(2)./trialSkip);
        end
        trialId             = max(1,min(trialNum,clickTrial));
        trialId             = trialIndexSelected(trialId);
        imageId             = newClickPosition(1);
        % convert search index to actual index
        trialInd             = trialInd(trialId);
        
    end

%-----------------------------------------------------
% Manage Right Click Menu on Cursors

    function fRightClick(o,e,sel)
        
        % argument sel is passed from contextmenu
        if nargin < 3, sel = cursorSelection; end;
        
        % check if enabled
        if strcmp(get(handStr.hShowCursor,'State'),'off'), return; end;
        
        % get all the menu items and implement toggle on cursors
        hItems          = get(get(o,'parent'),'children');
        hItems          = hItems(end:-1:1); % in opposite order
        
        switch sel,
            case {1,2},
                cursorSelection = max(1,min(2,sel));
                set(hItems(cursorSelection),'Checked','on');
                set(hItems(3-cursorSelection),'Checked','off');
            case {3,4} % select Behavior Video
                
                [trialId,imageId] = fGetTrialImage();

                % show data
                if sel == 3, % behavior
                    imageId             = round(imageId * mngrData.TimeConvertFact);
                    currTrial           = trialId;
                    imageIndx           = [imageId-18 imageId+17];
                    if trialId ~= trialIdPrev,
                    [Par.DMB, SData.imBehaive]  = LoadBehaviorData(Par.DMB,currTrial, 'side') ;
                    end
                    if isempty(SData.imBehaive),return; end;
                    imageIndx(2) = min(imageIndx(2), size(SData.imBehaive,4));
                    %figure(161),set(gcf,'Tag','AnalysisROI','Name','Behavior Data');clf; colordef(gcf,'none');
                    implay(SData.imBehaive(:,:,:,imageIndx(1):imageIndx(2)));
                    title(sprintf('Trial : %d, Video : %d - %d',currTrial,imageIndx(1),imageIndx(2)));
                    trialIdPrev         = trialId;
                elseif sel == 4,
                    imageIdSlice        = imageId * Par.DMT.SliceNum;
                    currTrial           = trialId;
                    imageIndx           = [imageIdSlice-1 imageIdSlice+1];
                    [Par.DMT, imgData]  = LoadTwoPhotonData(Par.DMT,currTrial, imageIndx) ;                
                    if isempty(imgData),return; end;
                    figure(162),set(gcf,'Tag','AnalysisROI','Name','TwoPhoton Data');clf; %colordef(gcf,'none');
                    if Par.DMT.SliceNum > 1,
                        imgData = cat(2,imgData(:,:,1,1),imgData(:,:,2,1),imgData(:,:,3,1));
                    else
                        imgData = squeeze(imgData(:,:,1,2));
                    end
                    imagesc(imgData);colormap(gray)
                    title(sprintf('Trial : %d, Image : %d, Slices : %d',currTrial,imageId,Par.DMT.SliceNum));
                end
                    
       
            otherwise
                error('bad sel')
        end
    end

%-----------------------------------------------------
% Manage Spike Filter Configuration

    function fConfigSpikes(o,e)
        
%         if mngrData.SpikeDataIsChanged,
%             buttonName = questdlg('New Spike Detector configuration : Selected Spike data will be changed', 'Warning');
%             if ~strcmp(buttonName,'Yes'), return; end; % 
%         end
        [mngrData.TPED,isOK] = SetDeconvolutionParams(mngrData.TPED,121);
        if ~isOK, return; end; % cancel
        mngrData.SpikeDataIsChanged = true; % can make any changes
        
        % compute spikes    
        [mngrData,~,dataStrForExport]    = ComputeSpikes(mngrData,dataStrForExport);
        
        % write back to DB
        mngrData = UpdateDatabaseFromSelection(mngrData,dataStrForExport);
        
        % render the results
        fUpdateGUI(0,0);
        
    end

%-----------------------------------------------------
% Update Spike Data in memory 

    function fUpdateSpikes(o,e)
        
        % check
        enableSpikeEdit    = strcmp(get(handStr.hEditSpikes,'State'),'on');
        % enable spike manual editor
        if enableSpikeEdit
            set(handStr.hFig,'WindowButtonDownFcn',@fSpikeMouseDown);
        else
            set(handStr.hFig,'WindowButtonDownFcn',@fUpdateCursors);
        end
       % previous state was off
        if ~enableSpikeEdit, return; end;
        
        
        % spike data is not changed
        if ~mngrData.SpikeDataIsChanged,return; end;
         
        % write back to DB
        mngrData = UpdateDatabaseFromSelection(mngrData,dataStrForExport);
        
        % render the results
        %fUpdateGUI(0,0);
        
    end

%-----------------------------------------------------
% Save Spike Data to ROI on the Disk

    function fSaveSpikes(o,e)
        
        if mngrData.SpikeDataIsChanged, % has been changed 
            buttonName = questdlg('Would you like to save spike data?', 'Warning');
            if strcmp(buttonName,'Yes'), 
               % fSaveSpikes(0,0); 
               mngrData = SaveDataFromTrials(mngrData);
               mngrData.SpikeDataIsChanged = false; % can make any changes
            end; % 
        else
            DTP_ManageText([], sprintf('Multi Trial : No spike data has been changed.'),  'I' ,0);
        end
    end

%--------------------------------------------------------%
% Spike Edit : start

    function fSpikeMouseDown(s,e)
        % start drawing of the rectangle
        % get which button is clicked
        clickType   = get(s,'Selectiontype');
        leftClick   = strcmp(clickType,'normal');
        rightClick  = strcmp(clickType,'alt');

        cp          = get(handStr.hAxTraces,'CurrentPoint');
        xinit       = cp(1,1);yinit = cp(1,2);
        XLim        = get(handStr.hAxTraces,'XLim');        
        YLim        = get(handStr.hAxTraces,'YLim');        
        % check the point location
        if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
        if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
        
        lastClickPosition = round([xinit yinit]);
                
        [trialInd,imageId,trialId]  = fGetTrialImage(lastClickPosition);
        
        % get trace info
        if ~isempty(imageId)
            dffValue = dataStrForExport.Roi{trialId,4}(imageId);
        else
            dffValue = 1;
        end
        cp_start    = [imageId trialId dffValue];

        
        %cp      = get(handStr.hAxTraces,'CurrentPoint');
        set(handStr.hFig,'WindowButtonMotionFcn',{@fSpikeMouseMotion,cp_start});
        
        % debug
        %fprintf('Start x = %d, y = %d\n',cp(1,1),cp(1,2));
        %mngrData.SpikeDataIsChanged = true;
        
    end
        
%--------------------------------------------------------%
% Sike Edit : do

    function fSpikeMouseMotion(s,e,cp_start)


        set(handStr.hFig,'WindowButtonUpFcn',{@fSpikeMouseUp});
        cp          = get(handStr.hAxTraces,'CurrentPoint');
        xinit       = cp(1,1);yinit = cp(1,2);
        XLim        = get(handStr.hAxTraces,'XLim');        
        YLim        = get(handStr.hAxTraces,'YLim');        
        % check the point location
        if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
        if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;

        newClickPosition    = round([xinit yinit]);
        % trials per event - for all rois
        [trialInd,imageId,trialId]  = fGetTrialImage(newClickPosition);
        %imageId     = newClickPosition(1);
        %trialInd    = cp_start(2);
                            
        set(handStr.hTtl,'string',sprintf('Trial : %d, Image : %d',trialInd,imageId));


        xdata   = get(handSpikePlot(trialId),'xdata');
        ydata   = get(handSpikePlot(trialId),'ydata');
        xLen    = length(xdata);

        xp      = max(1,min(xLen,round(cp(1,1))));
        yp      = cp(2,2);
        xp_s    = max(1,min(xLen,round(cp_start(1))));
        yp_s    = cp_start(2);
        yval    = double(yp > (trialId-1)*trialSkip + 0.5*trialSkip);

        % assign
        if xp > xp_s, ind = xp_s:xp; 
        else          ind = xp:xp_s; 
        end;
        % assign actual value at the start
        if yval > 0,
            yval = cp_start(3);
        end
        ydata(ind)  = yval + (trialId-1)*trialSkip;%- ydata(ind);

        % show
        set(handSpikePlot(trialId),'ydata',ydata);

        % save for update
        dataStrForExport.Roi{trialId,5}(ind) = yval;


    end

%--------------------------------------------------------%
% Spike Edit Finish    

    function fSpikeMouseUp(s,e)

%         h               = obj.Handles;
%         cp              = get(h.axesLabel,'CurrentPoint');
%         obj.cp_stop     = cp;

        mngrData.SpikeDataIsChanged = true;
        set(handStr.hFig,'WindowButtonMotionFcn','');

        % debug
        fUpdateSpikes(0,0);
        %fprintf('Stop x = %d, y = %d\n',cp(1,1),cp(1,2));


    end
 
%-----------------------------------------------------
% Show Spatial location 

    function fShowCellSpatialLocation(o,e)
        
        % check of active
        figNum                = 127;
        enableShowLocation    = strcmp(get(handStr.hShowLocation,'State'),'on');
        guiIsOpen             = ishandle(figNum);
        
        % check if GUI is open
        if enableShowLocation
            % get selected cell
            roiIndexSelected   = get(handStr.hRoiListBox,'Value');
            roiNamesSelected   = roiNames(roiIndexSelected);
            sliceId            = sliceIdPrev;
            if ~guiIsOpen
                if Par.DMT.SliceNum > 1 
                    [s,ok] = listdlg('PromptString','Select Slice Id to Show :','ListString',num2str((1:Par.DMT.SliceNum)'),'SelectionMode','single');
                    if ~ok, return; end
                    sliceId = s;
                end
                % load trial and then show cell
                currTrial                       = Par.DMT.Trial;
                [Par.DMT,  SData.strROI]        = Par.DMT.LoadAnalysisData(currTrial,'strROI');
                [Par.DMT, SData.imTwoPhoton]    = Par.DMT.LoadTwoPhotonData(currTrial) ;        
                % apply shift
                [Par.DMT, strShift]             = Par.DMT.LoadAnalysisData(currTrial,'strShift');
                [Par.DMT, SData.imTwoPhoton]    = Par.DMT.ShiftTwoPhotonData(SData.imTwoPhoton,strShift);
                
                if isempty(SData.imTwoPhoton),return; end
                imgData         = mean(squeeze(SData.imTwoPhoton(:,:,sliceId,:)),3);
                imgData         = imadjust(uint16(imgData));
                figure(figNum),set(gcf,'Tag','AnalysisROI','Name','Cell Spatial Location','menubar', 'none');clf; %colordef(gcf,'none');
                imagesc(imgData);colormap(gray); set(gca,'pos',[0 0 1 1]);
                hold on;
                hRoi    = zeros(length(SData.strROI),1);
                for k = 1:length(SData.strROI)
                    hRoi(k) = plot(SData.strROI{k}.xyInd(:,1),SData.strROI{k}.xyInd(:,2),'y','Visible','off');
                    if SData.strROI{k}.zInd ~= sliceId, continue; end
                    set(hRoi(k),'Visible','on');
                end
                hold off;
                set(gcf,'UserData',hRoi);
                % align
                iptwindowalign(handStr.hFig, 'right', gcf, 'left');
                iptwindowalign(handStr.hFig, 'top',   gcf, 'top');
            end
           % show selected cell
           hRoi = get(figure(figNum),'UserData');
           for k = 1:length(SData.strROI)
                set(hRoi(k),'Visible','off');
                if SData.strROI{k}.zInd ~= sliceId, continue; end
                set(hRoi(k), 'color','y','Visible','off');
                if ~any(strcmp(SData.strROI{k}.Name,roiNamesSelected)), continue; end
                set(hRoi(k), 'color','r','Visible','on');
            end
            sliceIdPrev = sliceId;
        else
            if guiIsOpen, delete(figNum); end
            % do nothing
        end
        % return focus back
        figure(handStr.hFig);

        
        % render the results
        %fUpdateGUI(0,0);
        
    end


%-----------------------------------------------------
% Finalization

    function fCloseRequestFcn(~, ~)
        % This is where we can return the ROI selected
        
%         if mngrData.SpikeDataIsChanged, % has been changed 
%             buttonName = questdlg('Would you like to save spike data?', 'Warning');
%             if strcmp(buttonName,'Yes'), 
%                 fSaveSpikes(0,0); 
%             end; % 
%         end
        fSaveSpikes(0,0); 

        
        %fExportROI();               % check that ROI structure is OK
        if ishandle(161),close(161); end; % if exist
        if ishandle(162),close(162); end % if exist
        
        %uiresume(handStr.roiFig);
        try
            %             % remove from the child list
            %             ii = find(SGui.hChildList == handStr.roiFig);
            %             SGui.hChildList(ii) = [];
            delete(handStr.hFig);
        catch ex
            errordlg(ex.getReport('basic'),'Close Window Error','modal');
        end
        % return attention
        figure(SGui.hMain)
    end

%-----------------------------------------------------
% Export to image

    function fFigureExport(~, ~)
        
        % return attention
        figure(handStr.hFig)
        set(handStr.hFig,'menubar', 'figure','ToolBar','figure');
        
        % remove boxes
        %set(handStr.hAxTraces,'visible','off')
        %set(handStr.hAxAver,'visible','off')
        %set(handStr.hAxBehave,'visible','off')
        
        %print( gcf, '-djpeg95', '-r600', 'MultiTrialExplorer.jpg');      
        %print( gcf, '-dtiff', '-r900', 'MultiTrialExplorer.tiff');      
        %savefig('MultiTrialExplorer.jpg', gcf, 'jpeg','-rgb','-r600');
        %savefig('MultiTrialExplorer', gcf, 'jpeg');
        %export_fig('MultiTrialExplorer.jpg', gcf, '-jpg','-rgb','-r800');
        %saveas(gcf,'MultiTrialExplorer','bmp')
        savefig('MultiTrialExplorer.fig');
        
        set(handStr.hAxTraces,'visible','on')
        set(handStr.hAxAver,'visible','on')
        set(handStr.hAxBehave,'visible','on')
        
        
    end

%-----------------------------------------------------
% Nain GUI create

    function fCreateGUI() %#ok<*INUSD> eventdata is trialedly unused
        
        ScreenSize  = get(0,'ScreenSize');
        figWidth    = 900;
        figHeight   = 600;
        figX = (ScreenSize(3)-figWidth)/2;
        figY = (ScreenSize(4)-figHeight)/2;
        
        hFig=figure( ...
            'Visible','on', ...
            'NumberTitle','off', ...
            'name', '4D : Multi Trial Explorer',...
            'position',[figX, figY, figWidth, figHeight],...
            'menubar', 'none',...
            'toolbar','none',...
            'Tag','AnalysisROI',...
            'WindowButtonDownFcn',@fUpdateCursors,...
            'Color','black');
        % prepare icons
        s                       = load('TPA_ToolbarIcons.mat');
        
        ht                       = uitoolbar(hFig);
        icon                     = im2double(imread(fullfile(matlabroot,'/toolbox/matlab/icons','tool_zoom_in.png')));
        icon(icon==0)            = NaN;
        uitoggletool(ht,...
            'CData',               icon,...
            'ClickedCallback',     'zoom',... @zoomIn,...
            'tooltipstring',       'ZOOM In/Out',...
            'separator',           'on');
        icon                     = im2double(imread(fullfile(matlabroot,'/toolbox/matlab/icons','tool_zoom_out.png')));
        icon(icon==0)            = NaN;
        uipushtool(ht,...
            'CData',               icon,...
            'ClickedCallback',     'zoom off',...@zoomOut,...
            'tooltipstring',       'ZOOM Out/Off');
        
        hShowCursor = uitoggletool(ht,...
            'CData',               s.ico.ml_tool_selpoint,...
            'ClickedCallback',     {@fManageCursors},...@,...
            'tooltipstring',       'Toggle and show cursors',...
            'separator',           'on');

        hShowSpikes = uitoggletool(ht,...
            'separator',            'on',...
            'CData',                s.ico.ml_tool_graph,...
            'ClickedCallback',     {@fUpdateGUI},...@,...
            'tooltipstring',       'Toggle to show spike data',...
            'State',                'off');
        
        hConfigSpikes              = uipushtool(ht, 'CData', s.ico.win_bookmark, ...
            'TooltipString',        'Configure automatic spike detection filter',...
            'clickedCallback',      {@fConfigSpikes},...
            'tag',                  'spikef');
      
        hEditSpikes              = uitoggletool(ht, 'CData', s.ico.ml_tool_hand, ...
            'TooltipString',        'Manualy edit spike data',...
            'clickedCallback',      {@fUpdateSpikes},...
            'State',                'off',...
            'tag',                  'manuals');
        
        
        hShowText = uitoggletool(ht,...
            'CData',               s.ico.win_new_text,...
            'ClickedCallback',     {@fUpdateGUI},...@,...
            'tooltipstring',       'Toggle text labels for Roi and Events',...
            'separator',           'on',...
            'State',               'on');
        
        hShowImage = uitoggletool(ht,...
            'CData',               repmat(rand(16,1,3),[1 16 1]),...
            'ClickedCallback',     {@fUpdateGUI},...@,...
            'tooltipstring',       'Toggle Trace View - Image or Plot Lines',...
            'State',                'off');
        
        
        hShowBright = uitoggletool(ht,...
            'CData',               s.ico.xp_gears,...
            'ClickedCallback',     {@fUpdateGUI},...@copyROIs,...
            'tooltipstring',       'Press to show Fluorescence traces',...
            'State',               'off',...
            'separator',           'off');
        
        hShowLocation = uitoggletool(ht,...
            'CData',               s.ico.ml_sl_associate,...
            'ClickedCallback',     {@fShowCellSpatialLocation},...@copyROIs,...
            'tooltipstring',       'Show cell spatial location',...
            'State',               'off',...
            'separator',           'off');
        
%         
%         uitoggletool(ht,...
%             'CData',               s.ico.win_paste,...
%             'oncallback',          'warndlg(''Is yet to come'')',...@pasteROIs,...
%             'tooltipstring',       'Paste ROI(s): CTRL-2');
%         
%         uitoggletool(ht,...
%             'CData',               s.ico.ml_del,...
%             'oncallback',          'warndlg(''Is yet to come'')',...@deleteROIs,...
%             'tooltipstring',       'Delete ALL ROI(s): CTRL-3');
%         
        uipushtool(ht,...
            'CData',               s.ico.xp_save,...
            'clickedCallback',     {@fSaveSpikes},... %@saveSession,..
            'enable',              'on',...
            'tooltipstring',       'Save/Export ROI Spike Data: CTRL-s',...
            'separator',           'on');
        
        helpSwitchTool              = uipushtool(ht, 'CData', s.ico.win_help, ...
            'separator',            'on',...
            'TooltipString',        'A little help about the buttons',...
            'clickedCallback',      'winopen(''TwoPhotonAnalysis UserGuide.docx'')',...
            'tag',                  'help');
        exitButton                  = uipushtool(ht, 'CData', s.ico.xp_exit, ...
            'separator',            'on',...
            'clickedCallback',      {@fCloseRequestFcn},...
            'TooltipString',        'Save, Close all and Exit',...
            'tag',                  'exit');
        
        
        % UIMENUS
        parentFigure = ancestor(hFig,'figure');
        
        % FILE Menu
        f = uimenu(parentFigure,'Label','File...');
        uimenu(f,...
            'Label','Load Image...',...
            'callback','warndlg(''Is yet to come'')'); %,...@loadImage
        uimenu(f,...
            'Label','Save/Export Figure to Image... ',...
            'callback',@fFigureExport);%,...@saveSession 
        uimenu(f,...
            'Label','Close GUI',...
            'callback',@fCloseRequestFcn);
        
        
        % Image Menu
        g = uimenu(parentFigure,...
            'Label','Two Photon ROIs ...');
        uimenu(g,...
            'Label','Config Color Range parameters',...
            'checked','off',...
            'callback',@fConfigTwoPhotonRange); %{@fUpdateImageShow,IMAGE_TYPES.RAW});
        uimenu(g,...
            'Label','Expand Axis',...
            'checked','off',...
            'callback',{@fAxisExpand,1}); %{@fUpdateImageShow,IMAGE_TYPES.RAW});
        uimenu(g,...
            'Label','Configure Spike Detector',...
            'checked','off',...
            'callback',@fConfigSpikes); %{@fUpdateImageShow,IMAGE_TYPES.MEAN});
        
        
        % Event Menu
        f = uimenu(parentFigure,...
            'Label','Bahavior Events...');
        uimenu(f,...
            'Label','Config Y Axis Range parameters',...
            'checked','off',...
            'callback',@fConfigBehavioralRange); %{@fUpdateImageShow,IMAGE_TYPES.RAW});
        uimenu(f,...
            'Label','Expand Axis',...
            'callback',{@fAxisExpand,3}); %,...@defineROI,...);
        uimenu(f,...
            'Label','Keep behavior axis to show lines',...
            'callback',@fSwitchElectroPhysShow,... %'enableElectroShow = ~enableElectroShow;',...@copyROIs,...
            'accelerator','1');%c is reserved
        uimenu(f,...
            'Label','Toggle Zoom',...
            'callback','zoom',...
            'accelerator','z');
        uimenu(f,...
            'Label','Save/Export ',...
            'callback','warndlg(''Is yet to come'')',...@saveSession,...
            'accelerator','s');
        
        
        
        colordef(hFig,'none')
        hAxTraces = axes( ...
            'Units','normalized', 'box','on','XTickLabel','',...
            'Parent',hFig,...
            'Position',axisViewPosUp(3,:));
        hTtl = title('Hello');
     %  hCursorUp = line([1 1;2 2],[0 0;0 0],'visible','off','color','w','linestyle',':','interpreter','none','parent',hAxTraces);
        hCursorUp = line([1 1;2 2],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',hAxTraces,'LineWidth',0.8);
        %hCursorUp(2).Color = 'g';
        hAxAver = axes( ...
            'Units','normalized', 'box','on','XTickLabel','',...
            'Parent',hFig,...
            'Position',axisViewPosUp(2,:));
        hCursorMid = line([1 1;2 2],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',hAxAver,'LineWidth',0.8);
        hAxBehave = axes( ...
            'Units','normalized', 'box','on',...
            'Parent',hFig,...
            'Position',axisViewPosUp(1,:));
        hCursorDwn = line([1 2;1 2],[1 2;1 2],'visible','off','color','w','linestyle',':','parent',hAxBehave,'LineWidth',0.8);
        
        % Mouse Right Click Context Menu
        hClickMenu = uicontextmenu;
        %hAxTraces.UIContextMenu = hClickMenu;
        if ~verLessThan('matlab', '8.4')
            hCursorUp(1).UIContextMenu = hClickMenu;
            hCursorUp(2).UIContextMenu = hClickMenu;
        else
            set(hCursorUp,'UIContextMenu',hClickMenu);
        end
        uimenu(hClickMenu,...
            'Label','Select Cursor 1','checked','off',...
            'callback',{@fRightClick,1}); 
        uimenu(hClickMenu,...
            'Label','Select Cursor 2','checked','off',...
            'callback',{@fRightClick,2}); 
        uimenu(hClickMenu,...
            'Label','Show Behavior Data',...
            'callback',{@fRightClick,3});
        uimenu(hClickMenu,...
            'Label','Show TwoPhoton Data',...
            'callback',{@fRightClick,4});
        
        
        handStr.hFig        = hFig;
        handStr.hAxTraces   = hAxTraces;
        handStr.hAxAver     = hAxAver;
        handStr.hAxBehave   = hAxBehave;
        handStr.hTtl        = hTtl;
        handStr.hShowCursor = hShowCursor;
        handStr.hShowSpikes = hShowSpikes;
        handStr.hConfigSpikes = hConfigSpikes;
        handStr.hEditSpikes = hEditSpikes;
        handStr.hShowText   = hShowText;
        handStr.hShowImage  = hShowImage;
        handStr.hShowBright = hShowBright;
        handStr.hShowLocation = hShowLocation;
        
        handStr.hCursorUp   = hCursorUp;
        handStr.hCursorMid  = hCursorMid;
        handStr.hCursorDwn  = hCursorDwn;

        handStr.hClickMenu  = hClickMenu;
        
        
        %====================================
        % Information for all buttons
        labelColor=[0.8 0.8 0.8];
        top=0.95;
        bottom=0.05;
        yInitLabelPos=0.90;
        labelWid=0.15;
        btnWid=labelWid;
        labelHt=0.02;
        left=1-0.05-labelWid;
        btnHt=0.03;
        listHt=0.1;
        % Spacing between the label and the button for the same command
        btnOffset=0.003;
        % Spacing between the button and the next command's label
        spacing=0.05;
        
        %====================================
        % The CONSOLE frame
        frmBorder=0.02;
        yPos=0.05-frmBorder;
        frmPos=[left-frmBorder yPos btnWid+2*frmBorder 0.9+2*frmBorder];
        hFrame=uicontrol( ...
            'Style','frame', ...
            'Units','normalized', ...
            'Position',frmPos, ...
            'BackgroundColor',[0.50 0.50 0.50]);
        
        %====================================
        % Trial Listbox
        btnNumber=1;
        yLabelPos=top-(btnNumber-1)*(listHt+labelHt+spacing);
        labelPos=[left yLabelPos-labelHt labelWid labelHt];
        listPos=[left yLabelPos-labelHt-listHt-btnOffset btnWid listHt];
        uicontrol(hFig,'Style','text','Units','normalized',...
            'Position',labelPos,...
            'String','Trial : ','HorizontalAlignment','left', ...
            'BackgroundColor',labelColor);
        hTrialListBox = uicontrol(hFig,'Style','listbox','Units','normalized',...
            'Position',listPos,...
            'BackgroundColor','white',...
            'Max',10,'Min',1,...
            'Callback',@fUpdateGUI);
        
        %====================================
        % ROI Listbox
        btnNumber=2;
        yLabelPos=top-(btnNumber-1)*(listHt+labelHt+spacing);
        labelPos=[left yLabelPos-labelHt labelWid labelHt];
        listPos=[left yLabelPos-labelHt-listHt-btnOffset btnWid listHt];
        uicontrol(hFig,'Style','text','Units','normalized',...
            'Position',labelPos,...
            'String','ROIs : ','HorizontalAlignment','left', ...
            'BackgroundColor',labelColor);
        hRoiListBox = uicontrol(hFig,'Style','listbox','Units','normalized',...
            'Position',listPos,...
            'BackgroundColor','white',...
            'Max',10,'Min',1,...
            'Callback',@fUpdateGUI);
        
        %====================================
        % Event Listbox
        btnNumber=3;
        yLabelPos=top-(btnNumber-1)*(listHt+labelHt+spacing);
        labelPos=[left yLabelPos-labelHt labelWid labelHt];
        listPos=[left yLabelPos-labelHt-listHt-btnOffset btnWid listHt];
        uicontrol(hFig,'Style','text','Units','normalized',...
            'Position',labelPos,...
            'String','Events : ','HorizontalAlignment','left', ...
            'BackgroundColor',labelColor);
        hEventListBox = uicontrol(hFig,'Style','listbox','Units','normalized',...
            'Position',listPos,...
            'BackgroundColor','white',...
            'Max',10,'Min',1,...
            'Callback',@fUpdateGUI);
        
        
        
        handStr.hTrialListBox   = hTrialListBox;
        handStr.hRoiListBox     = hRoiListBox;
        handStr.hEventListBox   = hEventListBox;
        
        
        %====================================
        % The COLORMAP command popup button
        btnNumber=6;
        yLabelPos=top-(btnNumber-1)*(btnHt+labelHt+spacing);
        labelStr='Colormap';
        labelList=' jet| hsv| cool| hot| gray| pink| copper| flag | yellow | red | green | blue | cyan ';
        cmdList=str2mat( ...
            ' colormap(hsv)',' colormap(jet)',' colormap(cool)',' colormap(hot)', ...
            ' colormap(gray)',' colormap(pink)',' colormap(copper)');
        
        % Generic label information
        labelPos=[left yLabelPos-labelHt labelWid labelHt];
        uicontrol( ...
            'Style','text', ...
            'Units','normalized', ...
            'Position',labelPos, ...
            'BackgroundColor',labelColor, ...
            'HorizontalAlignment','left', ...
            'String',labelStr);
        
        % Generic popup button information
        btnPos=[left yLabelPos-labelHt-btnHt-btnOffset btnWid btnHt];
        hColormapPopup=uicontrol( ...
            'Style','popup', ...
            'Units','normalized', ...
            'Position',btnPos, ...
            'String',labelList, ...
            'Callback',@fUpdateColor, ...
            'UserData',cmdList);
        
        handStr.hColormapPopup = hColormapPopup;
        
        %====================================
        % The AXIS command popup button
        btnNumber=7;
        yLabelPos=top-(btnNumber-1)*(btnHt+labelHt+spacing);
        
        % Generic label information
        labelPos=[left yLabelPos-labelHt labelWid labelHt];
        uicontrol( ...
            'Style','text', ...
            'Units','normalized', ...
            'Position',labelPos, ...
            'BackgroundColor',labelColor, ...
            'HorizontalAlignment','left', ...
            'String','Show Plot : ');
        
        % Generic popup button information
        btnPos=[left yLabelPos-labelHt-btnHt-btnOffset btnWid btnHt];
        hPlotPopup=uicontrol( ...
            'Style','popup', ...
            'Units','normalized', ...
            'Position',btnPos, ...
            'String',PLOT_TYPES, ...
            'Callback',@fUpdateGUI);
        
        handStr.hPlotPopup = hPlotPopup;
        
        %====================================
        % The Export button.
        btnHt=0.04;
        % Spacing between the button and the next command's label
        spacing=0.02;
        
        uicontrol( ...
            'Style','pushbutton', ...
            'Units','normalized', ...
            'Position',[left bottom+2*(btnHt+spacing)+btnHt btnWid btnHt], ...
            'String','Export', ...
            'Callback',@fExportCallback);
        
        % The apply button.
        uicontrol( ...
            'Style','pushbutton', ...
            'Units','normalized', ...
            'Position',[left bottom+1*(btnHt+spacing)+btnHt btnWid btnHt], ...
            'String','Group', ...
            'Callback',@fUpdateGroup);
        
        % The close button.
        uicontrol( ...
            'Style','pushbutton', ...
            'Units','normalized', ...
            'Position',[left bottom btnWid btnHt], ...
            'String','Close', ...
            'Callback',{@fCloseRequestFcn});
        
        % Uncover the figure
        %         hndlList=[mcwHndl hndl1 hndl2 hndl3 hndl4];
        %         watchoff(oldFigNumber);
        %         set(hFig,'Visible','on', ...
        %             'UserData',hndlList);
        %         graf3d('eval');
        
        
        trialNames  = num2str((1:mngrData.ValidTrialNum)');
        set(handStr.hTrialListBox,'String',trialNames,'Value',1)
        set(handStr.hRoiListBox,'String',roiNames,'Value',1)
        set(handStr.hEventListBox,'String',eventNames,'Value',1)
        
        % add callbacks
        % set(handStr.hFig,'WindowButtonDownFcn',{@SpikeMouseDown});
            
        
    end


end    % EOF..
