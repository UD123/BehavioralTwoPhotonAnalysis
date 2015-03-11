function [Par] = TPA_MultiTrialExcelExplorer(Par)
%
% TPA_MultiTrialExcelExplorer - Graphical interface to see the results of behavioral and two photon experiments
% behavioral experiment is loaded from Excel file.
%
% Depend:     Analysis data set from behavioral and two photon trials.
%
% Input:      Par               - structure of differnt constants
%             TPA_XXX.mat       - results of multiple trials -
%             YYY.xls           - Excel file from JAABA
%

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 19.04 12.08.14 UD     Working on integration 
% 19.02 05.08.14 UD     Created from MultiTrialExplorer
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



% check two photon data 
[Par,isOK]            = fCheckTwoPhotonData(Par);
if ~isOK,
    errordlg('Could not find Two Photon data - the exepriment must be defined using usual flow')
    return
end;

% define Event Table from Excel (structure with different params)
EventTable          = struct('ColumnNames',[],'RowNames',[],'Data',[]);
% result query
QueryTable          = struct('ColumnNames','None','RowNames',[],'Data',[]);


% check excel Jaaba data 
[Par,isOK]            = fCheckJaabaData(Par);
if ~isOK,
    errordlg('Could not find JAABA excel data or file is not in standard format.')
    return
end;


% Init Data manager
mngrData        = TPA_MultiTrialDataManager();


% prepare for Test
if nargin < 1,
    Par         = [];
    mngrData    = mngrData.TestLoad(); % get the test data
else
    mngrData    = mngrData.Init(Par);
    mngrData    = mngrData.LoadDataFromTrials(Par);
end

roiNames        = mngrData.GetRoiNames();
eventNames      = mngrData.GetEventNames();
% protect
if isempty(eventNames), eventNames = 'None'; end;
%eventNames = char(eventNames,'Query');

% list of all objects
queryTableList       = {};  % query/event listing


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
            errordlg('Must have Roi structure. Could be that no Events or ROIs are found','modal'); 
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
            text(timeBehavior(3),pos + 0.2,eventName,'color','g','interpreter','none');
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
        
        % blanks are created when stacking different names
        % query names are without blanks
        deblankEventName = deblank(eventNames(eventIndexSelected(1),:)); % need to match query name
 
        
        
        %%%
        % Do different computation to extract data for the current view
        %%%
        switch PLOT_TYPES{plotIndexSelected},
            case PLOT_TYPES{1}
                % roi and event per trace
                 % get traces
                dataStr             = mngrData.TracesPerTrial(trialIndexSelected(1));
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                        
                set(handStr.hTtl,'string',sprintf('All dF/F Traces for trial %d',trialIndexSelected(1)),'color','w')

            
            case PLOT_TYPES{2}
                % traces per roi 
                 % get roi                 
                dataStr             = mngrData.TracesPerRoiEvent(roiNames(roiIndexSelected(1),:),deblankEventName);
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All dF/F Traces for Roi %s and Event %s ',roiNames(roiIndexSelected(1),:),deblankEventName),'color','w')
                
            
            case PLOT_TYPES{3}

                %dataStr             = mngrData.TracePerEventTrial(eventNames(eventIndexSelected(1),:),trialIndexSelected);
                dataStr             = mngrData.TracePerEventRoiTrial(deblankEventName,roiIndexSelected,trialIndexSelected);
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All dF/F Traces per Event %s ',deblankEventName),'color','w')

            case PLOT_TYPES{4}

                dataStr             = mngrData.TraceAlignedPerEventRoiTrial(deblankEventName,roiIndexSelected,trialIndexSelected);
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All dF/F Traces Aligned per Event %s ',deblankEventName),'color','w')
                
           case PLOT_TYPES{5}
                % traces per roi - for all events
                dataStr             = mngrData.TracesPerRoi(roiNames(roiIndexSelected(1),:));
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All dF/F Traces for Roi %s ',roiNames(roiIndexSelected(1),:)),'color','w')
     
           case PLOT_TYPES{6}
                % trials per event - for all rois
                dataStr             = mngrData.TrialsPerEvent(deblankEventName);
                fRenderRoiTraceAxis(dataStr);                
                fRenderEventTraceAxis(dataStr);
                
                set(handStr.hTtl,'string',sprintf('All Trials for Event %s ',deblankEventName),'color','w')
                
                
            otherwise
                disp('Bad plotIndexSelected')
        end
        
        % save data for export          
        dataStrForExport = dataStr;
        
        
    end


%-----------------------------------------------------
% Update GUI with new Info :  list boxes

    function fUpdateGUI(o,e)
        %Refresh the image & plot
        
        fEventListUpdate(0,0)
        
        fAxisManager(0,0)
        
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
% Update Event Info :  

    function fEventListUpdate(o,e)
        % event list management
        
                
        listLen             = length(queryTableList);
        if listLen < 1,
            % set
            eventNames = 'None';
            set(handStr.hEventListBox,'String',eventNames);
            return;
        end

        
        
        % get group info
        groupIndexSelected  = get(handStr.hEventListBox,'Value');
%         % inly one is allowed
%         groupIndexSelected  = groupIndexSelected(1);
%         listLen             = size(eventNames,1);
%         if groupIndexSelected < 1 || groupIndexSelected > listLen, return; end;
        
        % only one is allowed
        groupIndexSelected  = groupIndexSelected(1);
        if groupIndexSelected < 1 || groupIndexSelected > listLen, return; end;
        
        % get group info
        eventNames          = queryTableList{1}.ColumnNames{1};
        for k = 2:listLen,
            eventNames      = char(eventNames,queryTableList{k}.ColumnNames{1}); 
        end
        
        % set
        set(handStr.hEventListBox,'String',eventNames);
        
        
        % prepare DB of events
        QueryTable          = queryTableList{groupIndexSelected};
        mngrData            = mngrData.LoadEventsFromQuery(QueryTable);
        
        
        
    end

%-----------------------------------------------------
% Event Management :  Add

    function fEventAddCallback(o,e)
        
        % get files - debug
         %eventNames         = strvcat(eventNames,num2str(rand*1000));
         
         [Par,QueryTable]    = TPA_MultiEventEditor(Par,EventTable);
         % wait to finish
         %waitfor(handleFIg);
         
         % add to grouop
         listLen                        = length(queryTableList);
         queryTableList{listLen + 1}    = QueryTable;
         
         % set focus
         set(handStr.hEventListBox,'Value', listLen + 1);
         
         % put it into the list
         %eventNames         = char(eventNames,QueryTable.ColumnNames);
         
         fUpdateGUI(0,0);
        
    end

%-----------------------------------------------------
% Event Management :  Delete

   function fEventDeleteCallback(o,e)
        
        % get file index
        groupIndexSelected  = get(handStr.hEventListBox,'Value');
%         listLen             = size(eventNames,1);
%         if groupIndexSelected < 1 || groupIndexSelected > listLen, return; end;
%         
%         eventNames(groupIndexSelected,:) = [];

        listLen             = length(queryTableList);
        if groupIndexSelected < 1 || groupIndexSelected > listLen, return; end;
        queryTableList(groupIndexSelected) = [];

        % set
        fUpdateGUI(0,0);
        
   end

%-----------------------------------------------------
% Event Management :  Rename

   function fEventRenameCallback(o,e)
        
        % get file index
        groupIndexSelected  = get(handStr.hEventListBox,'Value');
%         listLen             = size(eventNames,1);
%         if groupIndexSelected < 1 || groupIndexSelected > listLen, return; end;
%         currName            = eventNames(groupIndexSelected,:);
        
        listLen             = length(queryTableList);
        if groupIndexSelected < 1 || groupIndexSelected > listLen, return; end;
        currName            = queryTableList{groupIndexSelected}.ColumnNames{1};
        
                
        options.Resize      ='on';
        options.WindowStyle ='modal';
        options.Interpreter ='none';
        prompt              = {sprintf('Change Event Name : ')};
        name                = 'Event Rename';
        numlines            = 1;
        defaultanswer       = {currName};
        
        answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
        if isempty(answer), return; end;
        currName           = answer{1};
        
        % extend group names if the new name is long
        %eventNames          = char(eventNames,currName);
        queryTableList{groupIndexSelected}.ColumnNames{1} = currName;
        %eventNames(end,:)   = [];  % remove it
       
        % set
        fUpdateGUI(0,0);
        
   end


%-----------------------------------------------------
% Check Two Photon Data

    function [Par,isOK] = fCheckTwoPhotonData(Par)
        % This is where we can return the ROI selected
        
        isOK = false;

        % Do some data ready test
        Par.DMT                 = Par.DMT.CheckData();    % important step to validate number of valid trials    
        validTrialNum           = Par.DMT.RoiFileNum;    % only analysis data
        if validTrialNum < 1,
            DTP_ManageText([], sprintf('Multi Trial : Missing data in directory %s. Please check the folder or run Data Check',Par.DMT.RoiDir),  'E' ,0);
            return
        else
            DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI. ',validTrialNum),  'I' ,0);
        end

        % bring one file and check that it has valid data : mean and proc ROI
        trialInd                          = 1;
        [Par.DMT,isOK]                    = Par.DMT.SetTrial(trialInd);
        [Par.DMT,strROI]                  = Par.DMT.LoadAnalysisData(trialInd,'strROI');

        % Need to do it more nicely but
        if length(strROI) < 1,
            DTP_ManageText([], sprintf('Multi Trial : Can not find ROI data %s. Please check the folder or run define ROI',Par.DMT.RoiDir),  'E' ,0);
            return
        end

        % Need to do it more nicely but
        if ~isfield(strROI{1},'procROI')
            DTP_ManageText([], sprintf('Multi Trial : Found ROI data but it seems like dF/F is not computed. Please run dF/F analysis.'),  'E' ,0);
            return    
        else
            if isempty(strROI{1}.procROI),
                DTP_ManageText([], sprintf('Multi Trial : Found ROI data but it seems like dF/F is not computed. Please run dF/F analysis.'),  'E' ,0);
                return    
            end
        end
        
        isOK = true;

    end % fCheckTwoPhotonData


%-----------------------------------------------------
% Check Jaaba Excel Data

    function [Par,isOK] = fCheckJaabaData(Par)
        % Check JAABA data location
        
        isOK = false;
        
        % check if JAABA file is already defined
%         if isempty(Par.Event.JaabaExcelFileDir),
%             loadDir = pwd;
%         else
%             loadDir = Par.Event.JaabaExcelFileDir;
%         end
                
        [sFilenames, sPath] = uigetfile({ '*.csv', 'csv Files'; '*.xls*', 'xls Files';  '*.*', 'All Files'},  'OpenLocation'  , Par.Event.JaabaExcelFileDir, 'Multiselect'   , 'off');
        if isnumeric(sPath), return, end;   % Dialog aborted

        % if single file selected
        if iscell(sFilenames), sFilenames = sFilenames{1}; end;
        
        % create full name
        userJaabaExcelFileName         = fullfile(sPath,sFilenames);
        
        % try to load
       try
                [ndata, text, allData]  = xlsread(userJaabaExcelFileName);
        catch ex
                errordlg(ex.getReport('basic'),'File Type Error','modal');
                return
       end
        
       
        
        % do some data checks
        [nTrials,nEvents]               = size(ndata);
        if nTrials < 2,
            DTP_ManageText([], sprintf('JAABA Excel : There is less than 2 trials in the Excel %s',userJaabaExcelFileName),  'E' ,0);
            return
        end
        if nEvents < 1,
            DTP_ManageText([], sprintf('JAABA Excel : There are events found in the Excel %s',userJaabaExcelFileName),  'E' ,0);
            return
        end
        
        % remember the table on the way
        EventTable.ColumnNames  = text(1,:);
        EventTable.RowNames     = mat2cell((1:size(ndata,1))',ones(1,size(ndata,1)),1); %   num2str((1:size(ndata,1)'));
        EventTable.Data         = ndata;
        
        
        % remember the name of the session
        Par.Event.JaabaExcelFileName    = sFilenames;
        Par.Event.JaabaExcelFileDir     = sPath;
        isOK = true;

    end % fCheckJaabaData



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
            'name', '4D : Multi Trial for JAABA Excel Explorer',...
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
            'Label','Load JAABA Excel...',...
            'callback','warndlg(''Is yet to come'')'); %,...@loadImage
        uimenu(f,...
            'Label','Save/Export ',...
            'callback','warndlg(''Is not implemented'')');%,...@saveSession
        uimenu(f,...
            'Label','Close GUI',...
            'callback',@fCloseRequestFcn);
        
        % ROI Menu
        menuImage(1) = uimenu(parentFigure,...
            'Label','ROI Traces ...');
        menuImage(2) = uimenu(menuImage(1),...
            'Label','Raw Data',...
            'checked','on',...
            'callback','warndlg(''Is yet to come'')'); %{@fUpdateImageShow,IMAGE_TYPES.RAW});
        
        
        % Event Menu
        f = uimenu(parentFigure,...
            'Label','Bahavior Events...');
        uimenu(f,...
            'Label','Add Event',...
            'callback','warndlg(''Is yet to come'')',...@defineROI,...
            'accelerator','r');
        
        
        colordef(hFig,'none')
        hAxTraces = axes( ...
            'Units','normalized', 'box','on','XTickLabel','',...
            'Parent',hFig,...
            'Position',axisViewPosUp(3,:));
        hTtl = title('Hello','interpreter','none');
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
            'String','Events (use Right Click): ','HorizontalAlignment','left', ...
            'BackgroundColor',labelColor);
        hEventListBox = uicontrol(hFig,'Style','listbox','Units','normalized',...
            'Position',listPos,...
            'BackgroundColor','white',...
            'Max',10,'Min',1,...
            'Callback',@fUpdateGUI);
        
        
        
        handStr.hTrialListBox   = hTrialListBox;
        handStr.hRoiListBox     = hRoiListBox;
        handStr.hEventListBox   = hEventListBox;
        
        
        %         %====================================
        %         % The SHADING command popup button
        %         btnNumber=2;
        %         yLabelPos=top-(btnNumber-1)*(btnHt+labelHt+spacing);
        %         labelStr=getString(message('MATLAB:demos:graf3d:LabelShading'));
        %         labelList=' faceted| flat| interp';
        %         cmdList=str2mat( ...
        %             ' ',' shading flat',' shading interp');
        %         callbackStr='graf3d eval';
        %
        %         % Generic label information
        %         labelPos=[left yLabelPos-labelHt labelWid labelHt];
        %         uicontrol( ...
        %             'Style','text', ...
        %             'Units','normalized', ...
        %             'Position',labelPos, ...
        %             'BackgroundColor',labelColor, ...
        %             'HorizontalAlignment','left', ...
        %             'String',labelStr);
        %
        %         % Generic popup button information
        %         btnPos=[left yLabelPos-labelHt-btnHt-btnOffset btnWid btnHt];
        %         hndl2=uicontrol( ...
        %             'Style','popup', ...
        %             'Units','normalized', ...
        %             'Position',btnPos, ...
        %             'String',labelList, ...
        %             'Callback',callbackStr, ...
        %             'UserData',cmdList);
        %
        %====================================
        % The COLORMAP command popup button
        btnNumber=6;
        yLabelPos=top-(btnNumber-1)*(btnHt+labelHt+spacing);
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
        
       
        % add menu to listbox
        
        eventContextMenu =   uicontextmenu;
        Menu1 = uimenu('Parent',eventContextMenu,...
            'Label','Add New ','Callback',{@fEventAddCallback});
        Menu2 = uimenu('Parent',eventContextMenu,...
            'Label','Delete Selected','Callback',{@fEventDeleteCallback});
        Menu3 = uimenu('Parent',eventContextMenu,...
            'Label','Rename Selected','Callback',{@fEventRenameCallback});
        set(handStr.hEventListBox,'UIContextMenu',eventContextMenu);
        
        
    end



end    % EOF..
