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
global SGui;

% Init Data manager
mngrData        = TPA_MultiTrialDataManager();
mngrData        = mngrData.Init(Par);

% checks
[mngrData,IsOK] = mngrData.CheckDataFromTrials();
if ~IsOK, return; end
 mngrData       = mngrData.LoadDataFromTrials();


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
imFrameNum          = 1; % communication between axis

% structure with GUI handles
handStr             = [];

% GUI Constants
%VIEW_TYPES          = {'UP_BIG','UP_LOW_EQUAL'};
PLOT_TYPES          = {'ROIs & Events per Trial','Traces per ROI & Event','Traces per Event, ROIs & Trials','Traces Aligned per Event, ROIs & Trials','Traces per ROI','Traces per Event'};
aW                  = 0.72;
axisViewPosUp       = [[0.05 0.05 aW 0.1];[0.05 0.16 aW 0.05];[0.05 0.22 aW 0.73]]; % spatial loc
axisViewPosDwn      = [[0.05 0.05 aW 0.7];[0.05 0.76 aW 0.05];[0.05 0.82 aW 0.15]];
axisViewPosMid      = [[0.05 0.05 aW 0.35];[0.05 0.45 aW 0.05];[0.05 0.55 aW 0.4]];

% color management
TraceColorMap       = Par.Roi.TraceColorMap ;
MaxColorNum         = Par.Roi.MaxColorNum;

% pass info from render to Export
dataStrForExport    = [];
cursorPosition      = [1 1]; % two cursor data 
enableTextLabel     = true;
enableImageShow     = false;  % show image data instead of plots

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
        end;
        
        dbROI               = DataStr.Roi ;
        axes(handStr.hAxTraces), cla, hold on; %set(handStr.hAxTraces,'nextplot','add') % current view
         %set(handStr.hAxTraces,'nextplot','add') % current view
        
        if isempty(dbROI),
             set(handStr.hTtl,'string','No Trace data found for this selection','color','r')
             DTP_ManageText([], sprintf('Multi Trial : No ROI data found for this selection.'),  'W' ,0);
             %plot(handStr.hAxAver,1:imFrameNum,zeros(1,imFrameNum),'color','r');    % remove old trace
             axes(handStr.hAxAver), cla;
             return
        end

        trialSkip           = max(Par.dFFRange)/2;  % the distance between lines
        frameNum            = size(dbROI{1,4},1);
        traceNum            = size(dbROI,1);
        
        % stupid protect when no dF/F data
        if frameNum < 1,
            mtrxTraces          = [dbROI(:,4)];
            frameNum            = max(100,size(mtrxTraces,1));
        end
         timeTwoPhoton       = (1:frameNum)';
         imFrameNum             = max(1,frameNum);  % communicates info to the second axis manager
       
        % ------------------------------------------        
        meanTrace           = zeros(frameNum,1);
        currTraces          = zeros(frameNum,traceNum);
        meanTraceCnt        = 0;

        for p = 1:traceNum,
                        
            % show trial with shift
            pos     = trialSkip*(p - 1);
            %clr     = rand(1,3);
            
            % draw traces
            if ~isempty(dbROI{p,4}), % protect from empty
                tId     = dbROI{p,1};
                clr     = TraceColorMap(mod(tId,MaxColorNum)+1,:);
                if ~enableImageShow
                    plot(handStr.hAxTraces,timeTwoPhoton,dbROI{p,4}+pos,'color',clr);  hold on ;
                else
                    currTraces(:,p) = dbROI{p,4};
                end
                meanTrace    = meanTrace + dbROI{p,4};
                meanTraceCnt = meanTraceCnt + 1;
            end
            % draw ref lines
            if ~enableImageShow            
                plot(handStr.hAxTraces,timeTwoPhoton,zeros(frameNum,1) + pos,':','color',[.7 .7 .7]); hold on;
            end
%             % draw names
%             roiName       = sprintf('T-%2d: %s',dbROI{p,1},dbROI{p,3});
%             if enableTextLabel,
%             text(timeTwoPhoton(3),pos + 0.2,roiName,'color','w','FontSize',8);
%             end
            %currTraces(:,p)     = dbROI{p,4};
        end
        
        % show image
        if enableImageShow,
            imagesc(timeTwoPhoton,1:traceNum,currTraces',[-.1 trialSkip]);
            colormap(TraceColorMap)
            trialSkip = 1;
        end
        
        % show names
        if enableTextLabel,
            for p = 1:traceNum,
                roiName         = sprintf('T-%2d: %s',dbROI{p,1},dbROI{p,3});
                pos             = trialSkip*(p - 1);
                text(timeTwoPhoton(3),pos + 0.2,roiName,'color','w','FontSize',8);
            end
        end
        
        
        ylabel('Trace Num'),%xlabel('Frame Num')
        ylim([-0.5 trialSkip*traceNum+0.5]),axis tight
        hold off
        
        % ------------------------------------------
        axes(handStr.hAxAver), cla, hold on; %
        % deal with average
        meanTrace = meanTrace/max(1,meanTraceCnt);
        plot(handStr.hAxAver,timeTwoPhoton,meanTrace,'color','r');  hold on;
        % draw ref lines
        plot(handStr.hAxAver,timeTwoPhoton,zeros(frameNum,1),':','color',[.7 .7 .7]); hold off 
        ylabel('Aver'),%xlabel('Frame Num')
        ylim([-0.8 trialSkip+0.5]), axis tight

        
    end

% ----------------------------------------------------------------
% Update Event axis

    function fRenderEventTraceAxis(DataStr)
        % draw events 
        if nargin < 1, error('DataStr is required'); end;
        if ~isfield(DataStr,'Event'), 
            errordlg('Must have Event structure. Could be that no Events or ROIs are found'); 
            return
        end;
        
        dbEvent               = DataStr.Event ;
        axes(handStr.hAxBehave), cla, hold on; %set(handStr.hAxTraces,'nextplot','add') % current view
        
        if isempty(dbEvent),
             set(handStr.hTtl,'string','No Bahavior data found for this selection','color','r')
             DTP_ManageText([], sprintf('Multi Trial : No Event data found for this selection.'),  'W' ,0);
             %return
        end
        eventSkip           = 5;         % the distance between lines - pixels
        
        % specify at least one event to reset axis
        eventNum            = size(dbEvent,1);
        
        % this time should be already aligned to TwoPhoton
        timeBehavior           = (1:imFrameNum)';
        %currEvents             = zeros(imFrameNum,eventNum);
       
        % ------------------------------------------        
        for p = 1:eventNum,
                        
            % show trial with shift
            pos         = eventSkip*(p - 1);

            eventData   = timeBehavior*0;
            
            % draw traces
            if ~isempty(dbEvent{p,4}), % protect from empty
                tId         = dbEvent{p,1};
                clr         = TraceColorMap(mod(tId,MaxColorNum)+1,:);
                maxLen      = min(imFrameNum,length(dbEvent{p,4})); % vector
                eventData(1:maxLen) = dbEvent{p,4}(1:maxLen);%0.5;
                plot(handStr.hAxBehave,timeBehavior,eventData+pos,'color',clr);  hold on ;
            end
            % draw ref lines
            plot(handStr.hAxBehave,timeBehavior,zeros(imFrameNum,1) + pos,':','color',[.7 .7 .7]); hold on 
            % draw names
            eventName       = sprintf('T-%2d: %s',dbEvent{p,1},dbEvent{p,3});
            if enableTextLabel,
            text(timeBehavior(3),pos + 0.2,eventName,'color','g');
            end
            %currEvents(:,p)     = eventData;
          
        end
        ylabel('Event Num'),xlabel('Frame Num')
        ylim([-0.2 eventSkip*eventNum+0.5]),xlim([1 imFrameNum]);axis tight
        hold off
        %set(handStr.hTtl,'string',sprintf('%d Traces of dF/F',eventNum),'color','w')
        
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
        
        
        %%%
        % change axis position according to Plot View method selected
        %%%
        switch PLOT_TYPES{plotIndexSelected},
            case PLOT_TYPES([1 3 4 5])
                set(handStr.hAxTraces,  'pos',axisViewPosUp(3,:));
                set(handStr.hAxAver,    'pos',axisViewPosUp(2,:));
                set(handStr.hAxBehave,  'pos',axisViewPosUp(1,:));
            case PLOT_TYPES([2])
                set(handStr.hAxTraces,  'pos',axisViewPosMid(3,:));
                set(handStr.hAxAver,    'pos',axisViewPosMid(2,:));
                set(handStr.hAxBehave,  'pos',axisViewPosMid(1,:));
           case PLOT_TYPES([6]), % traces per event
                set(handStr.hAxTraces,  'pos',axisViewPosDwn(3,:));
                set(handStr.hAxAver,    'pos',axisViewPosDwn(2,:));
                set(handStr.hAxBehave,  'pos',axisViewPosDwn(1,:));
            otherwise
                error('Bad plotIndexSelected')
        end
        
        
        %%%
        % Do different computation to extract data for the current view
        %%%
        switch PLOT_TYPES{plotIndexSelected},
            case PLOT_TYPES{1}
                % roi and event per trace
                 % get traces
                dataStr             = mngrData.TracesPerTrial(trialIndexSelected(1));
                ttlTxt              = sprintf('All dF/F Traces for trial %d',trialIndexSelected(1));
            
            case PLOT_TYPES{2}
                % traces per roi 
                 % get roi                 
                dataStr             = mngrData.TracesPerRoiEvent(roiNames{roiIndexSelected(1)},eventNames{eventIndexSelected(1)});
                ttlTxt              = sprintf('All dF/F Traces for Roi %s and Event %s ',roiNames{roiIndexSelected(1)},eventNames{eventIndexSelected(1)});
            
            case PLOT_TYPES{3}
                %dataStr             = mngrData.TracePerEventTrial(eventNames(eventIndexSelected(1),:),trialIndexSelected);
                dataStr             = mngrData.TracePerEventRoiTrial(eventNames{eventIndexSelected(1)},roiIndexSelected,trialIndexSelected);
                ttlTxt              = sprintf('All dF/F Traces per Event %s ',eventNames{eventIndexSelected(1)});

            case PLOT_TYPES{4}

                dataStr             = mngrData.TraceAlignedPerEventRoiTrial(eventNames{eventIndexSelected(1)},roiIndexSelected,trialIndexSelected);                
                ttlTxt              = sprintf('All dF/F Traces Aligned per Event %s ',eventNames{eventIndexSelected(1)});
                
           case PLOT_TYPES{5}
                % traces per roi - for all events
                dataStr             = mngrData.TracesPerRoi(roiNames{roiIndexSelected(1)});
                ttlTxt              = sprintf('All dF/F Traces for Roi %s ',roiNames{roiIndexSelected(1)});
     
           case PLOT_TYPES{6}
                % trials per event - for all rois
                dataStr             = mngrData.TrialsPerEvent(eventNames{eventIndexSelected(1)});
                ttlTxt              = sprintf('All Trials for Event %s ',eventNames{eventIndexSelected(1)});
                
                
            otherwise
                disp('Bad plotIndexSelected')
        end
        
        % transform to spike detection
        if strcmp(get(handStr.hShowSpikes,'State'),'on'),
            [mngrData,dataStr]             = ComputeSpikes(mngrData,dataStr);
        end
        
        % check if to render text labels
        enableTextLabel     = strcmp(get(handStr.hShowText,'State'),'on');
        
        % check if to show image data or plot
        enableImageShow     = strcmp(get(handStr.hShowImage,'State'),'on');
        
        
        fRenderRoiTraceAxis(dataStr);                
        fRenderEventTraceAxis(dataStr);
        set(handStr.hTtl,'string',ttlTxt,'color','w');
        
        
        % save data for export          
        dataStrForExport = dataStr;
        
        
    end

%-----------------------------------------------------
% Update GUI with new Info :  list boxes

    function fUpdateGUI(o,e)
        
        % update axis
        fAxisManager(0,0);
        % update cursors since axis size could change
        fManageCursors(0,0);
        
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
% Export button pressed

    function fExportCallback(hObject, eventdata)
        
        % prepare data for export        
        Par = TPA_ExportDataToExcel(Par,'MultiTrial',dataStrForExport);
        
    end

%-----------------------------------------------------
% Update Group Info :  

    function fUpdateGroup(e,o)
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

    function fManageCursors(~, ~)
        
        % check the toggle state
        if strcmp(get(handStr.hShowCursor,'State'),'off'),
            % delte/hide cursors
            if ishandle(handStr.hCursorUp), % could be cleared by cla
                set([handStr.hCursorUp handStr.hCursorMid handStr.hCursorDwn], 'Visible','off');
            end
        else
            % show cursors new pos
            if ~ishandle(handStr.hCursorUp), % could be cleared by cla    
                % create new
                handStr.hCursorUp = line([1 1;1 1],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',handStr.hAxTraces);
                handStr.hCursorMid = line([1 1;1 1],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',handStr.hAxAver);
                handStr.hCursorDwn = line([1 1;1 1],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',handStr.hAxBehave);
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
        
      if strcmp(get(src,'SelectionType'),'normal')
            %set(src,'pointer','circle')
            cp = get(gca,'CurrentPoint');
            xinit = cp(1,1);yinit = cp(1,2);
            XLim = get(gca,'XLim');        
            YLim = get(gca,'YLim');        
            % check the point location
            if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
            if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
            
            cPos           = round(xinit);
            % which cursor is selected
            [mV,mI]        = min(abs(cursorPosition - cPos));
            
            cursorPosition(mI) = round(cPos);
      end
      fManageCursors(0,0);
            
    end



%-----------------------------------------------------
% Finalization

    function fCloseRequestFcn(~, ~)
        % This is where we can return the ROI selected
        
        %fExportROI();               % check that ROI structure is OK
        
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
        
        %print( gcf, '-djpeg95', '-r600', 'MultiTrialExplorer.jpg');      
        print( gcf, '-dtiff', '-r900', 'MultiTrialExplorer.tiff');      
        %savefig('MultiTrialExplorer.jpg', gcf, 'jpeg','-rgb','-r600');
        %savefig('MultiTrialExplorer', gcf, 'jpeg');
        %export_fig('MultiTrialExplorer.jpg', gcf, '-jpg','-rgb','-r800');
        %saveas(gcf,'MultiTrialExplorer','bmp')
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
            'CData',               s.ico.ml_tool_graph,...
            'ClickedCallback',     {@fUpdateGUI},...@,...
            'tooltipstring',       'Toggle to show spike data',...
            'State',                'off');
        
        hShowText = uitoggletool(ht,...
            'CData',               s.ico.win_new_text,...
            'ClickedCallback',     {@fUpdateGUI},...@,...
            'tooltipstring',       'Toggle text labels for Roi and Events',...
            'State',                'on');
        
        hShowImage = uitoggletool(ht,...
            'CData',               repmat(rand(16,1,3),[1 16 1]),...
            'ClickedCallback',     {@fUpdateGUI},...@,...
            'tooltipstring',       'Toggle Trace View - Image or Plot Lines',...
            'State',                'off');
        
        
%         uitoggletool(ht,...
%             'CData',               s.ico.win_copy,...
%             'oncallback',          {@fImportROI},...@copyROIs,...
%             'tooltipstring',       'Copy ROI(s): CTRL-1',...
%             'separator',           'on');
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
%         uitoggletool(ht,...
%             'CData',               s.ico.xp_save,...
%             'oncallback',          {@fExportROI},... %@saveSession,..
%             'enable',              'off',...
%             'tooltipstring',       'Save/Export Session: CTRL-s',...
%             'separator',           'on');
        
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
        menuImage(1) = uimenu(parentFigure,...
            'Label','ROI Traces ...');
        menuImage(2) = uimenu(menuImage(1),...
            'Label','Expand Axis',...
            'checked','off',...
            'callback',{@fAxisExpand,1}); %{@fUpdateImageShow,IMAGE_TYPES.RAW});
        menuImage(3) = uimenu(menuImage(1),...
            'Label','Mean Projection',...
            'checked','off',...
            'callback','warndlg(''Is yet to come'')'); %{@fUpdateImageShow,IMAGE_TYPES.MEAN});
        menuImage(4) = uimenu(menuImage(1),...
            'Label','Max Projection',...
            'checked','off',...
            'callback','warndlg(''Is yet to come'')'); %{@fUpdateImageShow,IMAGE_TYPES.MAX});
        menuImage(5) = uimenu(menuImage(1),...
            'Label','Mean Time Difference',...
            'checked','off',...
            'callback','warndlg(''Is yet to come'')'); %{@fUpdateImageShow,IMAGE_TYPES.GRADT});
        menuImage(6) = uimenu(menuImage(1),...
            'Label','Mean Spatial Difference',...
            'checked','off',...
            'callback','warndlg(''Is yet to come'')'); %{@fUpdateImageShow,IMAGE_TYPES.GRADXY});
        
        
        % Event Menu
        f = uimenu(parentFigure,...
            'Label','Bahavior Events...');
        uimenu(f,...
            'Label','Expand Axis',...
            'callback',{@fAxisExpand,3}); %,...@defineROI,...);
        uimenu(f,...
            'Label','Copy Events',...
            'callback','warndlg(''Is yet to come'')',...@copyROIs,...
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
        hCursorUp = line([1 1;2 2],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',hAxTraces);
        hAxAver = axes( ...
            'Units','normalized', 'box','on','XTickLabel','',...
            'Parent',hFig,...
            'Position',axisViewPosUp(2,:));
        hCursorMid = line([1 1;2 2],[0 0;0 0],'visible','off','color','w','linestyle',':','parent',hAxAver);
        hAxBehave = axes( ...
            'Units','normalized', 'box','on',...
            'Parent',hFig,...
            'Position',axisViewPosUp(1,:));
        hCursorDwn = line([1 2;1 2],[1 2;1 2],'visible','off','color','w','linestyle',':','parent',hAxBehave);
        
        handStr.hFig        = hFig;
        handStr.hAxTraces   = hAxTraces;
        handStr.hAxAver     = hAxAver;
        handStr.hAxBehave   = hAxBehave;
        handStr.hTtl        = hTtl;
        handStr.hShowCursor = hShowCursor;
        handStr.hShowSpikes = hShowSpikes;
        handStr.hShowText   = hShowText;
        handStr.hShowImage  = hShowImage;
        
        handStr.hCursorUp   = hCursorUp;
        handStr.hCursorMid  = hCursorMid;
        handStr.hCursorDwn  = hCursorDwn;

        
        
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
            'Callback','close(gcf)');
        
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
        
        
        
    end


end    % EOF..
