function [Par] = TPA_MultiGroupExplorer(Par)
%
% TPA_MultiGroupExplorer - Graphical interface to see the results of behavioral and two photon experiments arranged in Groupd
% after MultiTrialExplorer
%
% Depend:     Analysis data set from behavioral and two photon trials.
%
% Input:      Par               - structure of differnt constants
%             GBT_XXX.mat       - results of multiple trials, events, ROI -
%

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 18.10 09.07.14 UD     Created
%-----------------------------


%
global SGui;


% Init Data manager
mngrData        = TPA_MultiTrialDataManager();
mngrData        = mngrData.Init(Par);
% [mngrData,IsOK] = mngrData.CheckDataFromTrials();
% if ~IsOK, return; end
%  mngrData       = mngrData.LoadDataFromTrials();


% %%%%%%%%%%%%%%%%%%%%%%
% % Do some data ready test
% %%%%%%%%%%%%%%%%%%%%%%
% Par.DMT                 = Par.DMT.CheckData();    % important step to validate number of valid trials    
% validTrialNum           = Par.DMT.RoiFileNum;    % only analysis data
% if validTrialNum < 1,
%     DTP_ManageText([], sprintf('Multi Trial : Missing data in directory %s. Please check the folder or run Data Check',Par.DMT.RoiDir),  'E' ,0);
%     return
% else
%     DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI. ',validTrialNum),  'I' ,0);
% end
%  
% % bring one file and check that it has valid data : mean and proc ROI
% trialInd                          = 1;
% [Par.DMT,isOK]                    = Par.DMT.SetTrial(trialInd);
% [Par.DMT,strROI]                  = Par.DMT.LoadAnalysisData(trialInd,'strROI');
% 
% % Need to do it more nicely but
% if length(strROI) < 1,
%     DTP_ManageText([], sprintf('Multi Trial : Can not find ROI data %s. Please check the folder or run define ROI',Par.DMT.RoiDir),  'E' ,0);
%     return
% end
% 
% % Need to do it more nicely but
% if ~isfield(strROI{1},'procROI')
%     DTP_ManageText([], sprintf('Multi Trial : Found ROI data but it seems like dF/F is not computed. Please run dF/F analysis.'),  'E' ,0);
%     return    
% else
%     if isempty(strROI{1}.procROI),
%         DTP_ManageText([], sprintf('Multi Trial : Found ROI data but it seems like dF/F is not computed. Please run dF/F analysis.'),  'E' ,0);
%         return    
%     end
% end

% list of all objects
groupObjList   = {};  % group listing

groupNames      = {''};
trialNames      = '';
roiNames        = '';
eventNames      = '';


% roiNames    = mngrData.GetRoiNames();
% eventNames  = mngrData.GetEventNames();

% dir management
prevDir         =  mngrData.DMT.RoiDir;


% protect
if isempty(eventNames), eventNames = 'None'; end;

% number of frames in the image - updated by axis rendering
imFrameNum          = 1; % communication between axis

% structure with GUI handles
handStr             = [];

% GUI Constants
%VIEW_TYPES          = {'UP_BIG','UP_LOW_EQUAL'};
PLOT_TYPES          = {'ROIs & Events per Trial','Traces per ROI & Event','Traces per Event, ROIs & Trials','Traces Aligned per Event, ROIs & Trials','Traces per ROI','Traces per Event'};
aW                  = 0.7;
axisViewPosUp       = [[0.05 0.05 aW 0.1];[0.05 0.16 aW 0.05];[0.05 0.22 aW 0.73]]; % spatial loc
axisViewPosDwn      = [[0.05 0.05 aW 0.7];[0.05 0.76 aW 0.05];[0.05 0.82 aW 0.15]];
axisViewPosMid      = [[0.05 0.05 aW 0.35];[0.05 0.45 aW 0.05];[0.05 0.55 aW 0.4]];

% color management
TraceColorMap       = Par.Roi.TraceColorMap ;
MaxColorNum         = Par.Roi.MaxColorNum;

% pass info from render to Export
dataStrForExport    = [];

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

        trialSkip           = max(Par.Roi.dFFRange)/2;  % the distance between lines
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
        %currTraces          = zeros(frameNum,traceNum);
        meanTraceCnt        = 0;

        for p = 1:traceNum,
                        
            % show trial with shift
            pos     = trialSkip*(p - 1);
            %clr     = rand(1,3);
            
            % draw traces
            if ~isempty(dbROI{p,4}), % protect from empty
                tId     = dbROI{p,1};
                clr     = TraceColorMap(mod(tId,MaxColorNum)+1,:);
                plot(handStr.hAxTraces,timeTwoPhoton,dbROI{p,4}+pos,'color',clr);  hold on ;
                meanTrace    = meanTrace + dbROI{p,4};
                meanTraceCnt = meanTraceCnt + 1;
            end
            % draw ref lines
            plot(handStr.hAxTraces,timeTwoPhoton,zeros(frameNum,1) + pos,':','color',[.7 .7 .7]); hold on 
            % draw names
            roiName       = sprintf('T-%2d: %s',dbROI{p,1},dbROI{p,3});
            text(timeTwoPhoton(3),pos + 0.2,roiName,'color','w');
            %currTraces(:,p)     = dbROI{p,4};
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
        eventSkip           = 1;         % the distance between lines
        
        % specify at least one event to reset axis
        eventNum            = size(dbEvent,1);
        
        % this time should be already aligned to TwoPhoton
        timeBehavior           = (1:imFrameNum)';
        %currEvents             = zeros(imFrameNum,eventNum);
       
        % ------------------------------------------        
        for p = 1:eventNum,
                        
            % show trial with shift
            pos         = eventSkip*(p - 1);
            %clr         = rand(1,3);

            eventData   = timeBehavior*0;
            
            % draw traces
            if ~isempty(dbEvent{p,4}), % protect from empty
                tId         = dbEvent{p,1};
                clr         = TraceColorMap(mod(tId,MaxColorNum)+1,:);
                tt          = max(1,min(imFrameNum,round(dbEvent{p,4}))); % vector
                eventData(tt(1):tt(2)) = 0.5;
                plot(handStr.hAxBehave,timeBehavior,eventData+pos,'color',clr);  hold on ;
            end
            % draw ref lines
            plot(handStr.hAxBehave,timeBehavior,zeros(imFrameNum,1) + pos,':','color',[.7 .7 .7]); hold on 
            % draw names
            eventName       = sprintf('T-%2d: %s',dbEvent{p,1},dbEvent{p,3});
            text(timeBehavior(3),pos + 0.2,eventName,'color','g');
            %currEvents(:,p)     = eventData;
          
        end
        ylabel('Event Num'),xlabel('Frame Num')
        ylim([-0.2 eventSkip*eventNum+0.5]),xlim([1 imFrameNum]);axis tight
        hold off
        %set(handStr.hTtl,'string',sprintf('%d Traces of dF/F',eventNum),'color','w')
        
    end



% ----------------------------------------------------------------
    function fAxisManager(hObject, eventdata)
        % arranges all the views
        groupIndexSelected = get(handStr.hGroupListBox,'Value');
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
        
        
        %if mngrData.ValidTrialNum < 1, return; end
        dataStr.Roi      = groupObjList{groupIndexSelected}.DbROI;
        dataStr.Event    = groupObjList{groupIndexSelected}.DbEvent;
       
        %%%
        % Do different computation to extract data for the current view
        %%%
        switch PLOT_TYPES{plotIndexSelected},
            case PLOT_TYPES{1}
                % roi and event per trace
                 % get traces
                %dataStr             = mngrData.TracesPerTrial(trialIndexSelected(1));
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                        
                set(handStr.hTtl,'string',sprintf('All dF/F Traces for trial %d',trialIndexSelected(1)),'color','w')

            
            case PLOT_TYPES{2}
                % traces per roi 
                 % get roi                 
                %dataStr             = mngrData.TracesPerRoiEvent(roiNames(roiIndexSelected(1),:),eventNames(eventIndexSelected(1),:));
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All dF/F Traces for Roi %s and Event %s ',roiNames(roiIndexSelected(1),:),eventNames(eventIndexSelected(1),:)),'color','w')
                
            
            case PLOT_TYPES{3}

                %dataStr             = mngrData.TracePerEventTrial(eventNames(eventIndexSelected(1),:),trialIndexSelected);
                %dataStr             = mngrData.TracePerEventRoiTrial(eventNames(eventIndexSelected(1),:),roiIndexSelected,trialIndexSelected);
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All dF/F Traces per Event %s ',eventNames(eventIndexSelected(1),:)),'color','w')

            case PLOT_TYPES{4}

                %dataStr             = mngrData.TraceAlignedPerEventRoiTrial(eventNames(eventIndexSelected(1),:),roiIndexSelected,trialIndexSelected);
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All dF/F Traces Aligned per Event %s ',eventNames(eventIndexSelected(1),:)),'color','w')
                
           case PLOT_TYPES{5}
                % traces per roi - for all events
                %dataStr             = mngrData.TracesPerRoi(roiNames(roiIndexSelected(1),:));
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All dF/F Traces for Roi %s ',roiNames(roiIndexSelected(1),:)),'color','w')
     
           case PLOT_TYPES{6}
                % trials per event - for all rois
                %dataStr             = mngrData.TrialsPerEvent(eventNames(eventIndexSelected(1),:));
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All Trials for Event %s ',eventNames(eventIndexSelected(1),:)),'color','w')
                
                
            otherwise
                disp('Bad plotIndexSelected')
        end
        
        % save data for export          
        dataStrForExport = dataStr;
        
        
    end

%-----------------------------------------------------
% Update Group Info :  

    function fUpdateGroup(o,e)
        
        % get group info
        groupIndexSelected  = get(handStr.hGroupListBox,'Value');
        % inly one is allowed
        groupIndexSelected  = groupIndexSelected(1);
        listLen             = length(groupObjList);
        if groupIndexSelected < 1 || groupIndexSelected > listLen, return; end;
        
        % get group info
        groupNames          = {};
        for k = 1:listLen,
            groupNames{k}   = groupObjList{k}.GroupName; 
        end

        % set
        set(handStr.hGroupListBox,'String',groupNames);
        
        % populate ROIs and Events
        k                   = groupIndexSelected;
        roiNames            = unique(groupObjList{k}.DbROI(:,3)); %strvcat(groupObjList{k}.DbROI{:,3});
        eventNames          = unique(groupObjList{k}.DbEvent(:,3)); %strvcat(groupObjList{k}.DbEvent{:,3});
        trialInd            = [groupObjList{k}.DbROI{:,1}];
        trialNames          = num2str(trialInd(:));
        
        set(handStr.hTrialListBox,'String',trialNames,'Value',1)
        set(handStr.hRoiListBox,'String',roiNames,'Value',1)
        set(handStr.hEventListBox,'String',eventNames,'Value',1)
        
                
        fUpdateGUI(0,0);

        
    end




%-----------------------------------------------------
% Group Management :  

    function fGroupAddCallback(o,e)
        
        % get files
        currDir = pwd;
        cd(prevDir);
        [fileName, pathname, filterindex] = uigetfile( ...
        {  'GBT_*.mat','MAT-files (*.mat)'; ...
           '*.*',  'All Files (*.*)'}, ...
           'Pick a file or files', ...
           'MultiSelect', 'on');
       cd(currDir)
                        
       if isnumeric(pathname), return, end;   % Dialog aborted
       prevDir = pathname;
       %Par.Group.Dir = pathname;
       
       if ~iscell(fileName),fileName = {fileName}; end; % single selectoin
       
       % load group 
       
        fileNum      = length(fileName);
        listLen      = length(groupObjList);
        for k = 1:fileNum,
            %groupList{listLen + k} = fullfile(pathname,fileName{k});
            sTmp                        = load(fullfile(pathname,fileName{k}));
            groupObjList{listLen + k}   = sTmp.GroupObj;
        end
     
       % check if there is a change in the group
        fUpdateGroup(0,0);

                
    end

   function fGroupDeleteCallback(o,e)
        
        % get file index
        groupIndexSelected  = get(handStr.hGroupListBox,'Value');
        listLen             = length(groupObjList);
        if groupIndexSelected < 1 || groupIndexSelected > listLen, return; end;
        
        groupObjList(groupIndexSelected) = [];
       
       % check if there is a change in the group
        fUpdateGroup(0,0);
        
    end

%-----------------------------------------------------
% Update GUI with new Info :  list boxes

    function fUpdateGUI(o,e)
        
        
        % apply it to Axis
        fAxisManager(0,0);
       
    end

%-----------------------------------------------------
% Update Colors from Color :  list boxes

    function fUpdateColor(o,e)
        %Refresh the image & plot
        
        val             = get(handStr.hColormapPopup,'val');
        nameColormap    = get(handStr.hColormapPopup,'string');
        TraceColorMap   = colormap(strtrim(nameColormap(val,:)));
        TraceColorMap   = TraceColorMap(randperm(MaxColorNum),:);

        % update all
        fUpdateGUI(0,0);
        
    end


%-----------------------------------------------------
% Export button pressed

    function fExportCallback(hObject, eventdata)
        
        % prepare data for export        
        Par = TPA_ExportDataToExcel(Par,'MultiTrial',dataStrForExport);
        
    end

% 
% %-----------------------------------------------------
% % Selection or Double click :  list boxes
% 
%     function fGroupListCallback(hObject, eventdata, handles)
%         get(handStr.hFig,'SelectionType');
%         % If double click
%         if strcmp(get(handStr.hFig,'SelectionType'),'open')
%             index_selected = get(handStr.hGroupListBox,'Value');
%             file_list = get(handStr.hGroupListBox,'String');
%             % Item selected in list box
%             filename = file_list{index_selected};
%             % If folder
%             if  handles.is_dir(handles.sorted_index(index_selected))
%                 cd (filename)
%                 % Load list box with new folder.
%                 load_listbox(pwd,handles)
%             else
%                 [path,name,ext] = fileparts(filename);
%                 switch ext
%                     case '.fig'
%                         % Open FIG-file with guide command.
%                         guide (filename)
%                     otherwise
%                         try
%                             % Use open for other file types.
%                             open(filename)
%                         catch ex
%                             errordlg(...
%                                 ex.getReport('basic'),'File Type Error','modal')
%                         end
%                 end
%             end
%         end
%     end



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


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCreateGUI() %#ok<*INUSD> eventdata is trialedly unused
        
        ScreenSize  = get(0,'ScreenSize');
        figWidth    = 900;
        figHeight   = 600;
        figX = (ScreenSize(3)-figWidth)/2;
        figY = (ScreenSize(4)-figHeight)/2;
        
        hFig=figure( ...
            'Visible','on', ...
            'NumberTitle','off', ...
            'name', 'TPA : Multi Group Explorer',...
            'position',[figX, figY, figWidth, figHeight],...
            'menubar', 'none',...
            'toolbar','none',...
            'Tag','AnalysisROI',...
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
        
        uitoggletool(ht,...
            'CData',               s.ico.win_copy,...
            'oncallback',          {@fImportROI},...@copyROIs,...
            'tooltipstring',       'Copy ROI(s): CTRL-1');
        
        uitoggletool(ht,...
            'CData',               s.ico.win_paste,...
            'oncallback',          'warndlg(''Is yet to come'')',...@pasteROIs,...
            'tooltipstring',       'Paste ROI(s): CTRL-2');
        
        uitoggletool(ht,...
            'CData',               s.ico.ml_del,...
            'oncallback',          'warndlg(''Is yet to come'')',...@deleteROIs,...
            'tooltipstring',       'Delete ALL ROI(s): CTRL-3');
        
        uitoggletool(ht,...
            'CData',               s.ico.xp_save,...
            'oncallback',          {@fExportROI},... %@saveSession,..
            'enable',              'off',...
            'tooltipstring',       'Save/Export Session: CTRL-s',...
            'separator',           'on');
        
        helpSwitchTool              = uipushtool(ht, 'CData', s.ico.win_help, ...
            'separator',            'on',...
            'TooltipString',        'A little help about the buttons',...
            'clickedCallback',      {@clickedHelpTool},...
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
            'Label','Save/Export ',...
            'callback','warndlg(''Is yet to come'')');%,...@saveSession
        uimenu(f,...
            'Label','Close GUI',...
            'callback',@fCloseRequestFcn);
        
        
        % Image Menu
        menuImage(1) = uimenu(parentFigure,...
            'Label','ROI Traces ...');
        menuImage(2) = uimenu(menuImage(1),...
            'Label','Raw Data',...
            'checked','on',...
            'callback','warndlg(''Is yet to come'')'); %{@fUpdateImageShow,IMAGE_TYPES.RAW});
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
            'Label','Add ROI',...
            'callback','warndlg(''Is yet to come'')',...@defineROI,...
            'accelerator','r');
        uimenu(f,...
            'Label','Copy ROI(s)',...
            'callback','warndlg(''Is yet to come'')',...@copyROIs,...
            'accelerator','1');%c is reserved
        uimenu(f,...
            'Label','Paste ROI(s)',...
            'callback','warndlg(''Is yet to come'')',...@pasteROIs,...
            'accelerator','2');%v is reserved
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
        hAxAver = axes( ...
            'Units','normalized', 'box','on','XTickLabel','',...
            'Parent',hFig,...
            'Position',axisViewPosUp(2,:));
        hAxBehave = axes( ...
            'Units','normalized', 'box','on',...
            'Parent',hFig,...
            'Position',axisViewPosUp(1,:));
        
        handStr.hFig        = hFig;
        handStr.hAxTraces   = hAxTraces;
        handStr.hAxAver     = hAxAver;
        handStr.hAxBehave   = hAxBehave;
        handStr.hTtl        = hTtl;
        
        
        %====================================
        % Information for all buttons
        labelColor = [0.8 0.8 0.8];
        top        = 0.95;
        bottom     = 0.05;
        %yInitLabelPos=0.90;
        labelWid   = 0.15;
        btnWid     = labelWid;
        labelHt    = 0.02;
        left       = 1-0.05-labelWid;
        btnHt      = 0.03;
        listHt     = 0.09;
        listHtG    = 0.18;
        % Spacing between the label and the button for the same command
        btnOffset  =0.001;
        % Spacing between the button and the next command's label
        spacing    =0.005;
        
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
        % Group Listbox
        btnNumber=1;
        yLabelPos=top-(btnNumber-1)*(listHtG+labelHt+spacing);
        labelPos=[left yLabelPos-labelHt labelWid labelHt];
        listPos=[left yLabelPos-labelHt-listHtG-btnOffset btnWid listHtG];
        uicontrol(hFig,'Style','text','Units','normalized',...
            'Position',labelPos,...
            'String','Groups : ','HorizontalAlignment','left', ...
            'BackgroundColor',labelColor);
        hGroupListBox = uicontrol(hFig,'Style','listbox','Units','normalized',...
            'Position',listPos,...
            'BackgroundColor','white',...
            'Max',10,'Min',1,...
            'Callback',@fUpdateGUI);
        
        %====================================
        % The Add & Delete buttons.
        btnHtSmall  = 0.02;
        btnWidSmall = btnWid/2.3;
        spacingSmall= 0;
        % Spacing between the button and the next command's label
        yStartPos   = listPos(2);
        addPos      =[left yStartPos-1*(btnHtSmall+spacingSmall) btnWidSmall btnHtSmall];
        delPos      =[left+btnWid-btnWidSmall yStartPos-1*(btnHtSmall+spacingSmall) btnWidSmall btnHtSmall];
        % The Add button.
        uicontrol( ...
            'Style','pushbutton', ...
            'Units','normalized', ...
            'Position',addPos, ...
            'String','Add', ...
            'Callback',@fGroupAddCallback);
        
        % The Delete button.
        uicontrol( ...
            'Style','pushbutton', ...
            'Units','normalized', ...
            'Position',delPos, ...
            'String','Delete', ...
            'Callback',@fGroupDeleteCallback);
        
        
        
        %====================================
        % Trial Listbox
        btnNumber=1;
        top      = addPos(2)-spacing;
        yLabelPos=top-(btnNumber-1)*(listHt+labelHt+spacing);
        labelPos=[left yLabelPos-labelHt labelWid labelHt];
        listPos=[left yLabelPos-labelHt-listHt-btnOffset btnWid listHt];
        uicontrol(hFig,'Style','text','Units','normalized',...
            'Position',labelPos,...
            'String','Trials : ','HorizontalAlignment','left', ...
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
        
        
        
        handStr.hGroupListBox   = hGroupListBox;
        handStr.hTrialListBox   = hTrialListBox;
        handStr.hRoiListBox     = hRoiListBox;
        handStr.hEventListBox   = hEventListBox;
        
        
        %
        %====================================
        % The COLORMAP command popup button
        btnNumber=1;
        yStartPos = listPos(2);
        yLabelPos = yStartPos-(btnNumber-1)*(btnHt+labelHt+spacing);
        labelStr='Colormap';
        labelList=' hsv| jet| cool| hot| gray| pink| copper';
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
        btnNumber=2;
        yLabelPos=yStartPos-(btnNumber-1)*(btnHt+labelHt+spacing);
        
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
        spacing=0.002;
        
        uicontrol( ...
            'Style','pushbutton', ...
            'Units','normalized', ...
            'Position',[left bottom+2*(btnHt+spacing)+btnHt btnWid btnHt], ...
            'String','Export Excel', ...
            'Callback',@fExportCallback);
        
        % The Show button.
        uicontrol( ...
            'Style','pushbutton', ...
            'Units','normalized', ...
            'Position',[left bottom+1*(btnHt+spacing)+btnHt btnWid btnHt], ...
            'String','Show', ...
            'Callback',@fUpdateGUI);
        
        % The close button.
        uicontrol( ...
            'Style','pushbutton', ...
            'Units','normalized', ...
            'Position',[left bottom btnWid btnHt], ...
            'String','Close', ...
            'Callback','close(gcf)');
        
        
        
        set(handStr.hGroupListBox,'String',groupNames,'Value',1)
        set(handStr.hTrialListBox,'String',trialNames,'Value',1)
        set(handStr.hRoiListBox,'String',roiNames,'Value',1)
        set(handStr.hEventListBox,'String',eventNames,'Value',1)
        
        
        
    end



end    % EOF..
