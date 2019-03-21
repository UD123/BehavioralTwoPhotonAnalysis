function [Par,QueryTable] = TPA_MultiEventEditor(Par,EventTable)
%
% TPA_MultiEventEditor - Graphical interface to generate new events from existant one
%
% Depend:     Analysis data set from behavioral and two photon trials.
%
% Input:      Par               - structure of different constants
%             EventTable        - table object that summarizes the events from Excel file (M x N)
%
% Output:     Par               - structure of differnt constants
%             QueryTable        - M x 1 table object for selected table

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 19.04 12.08.14 UD     Working on integration 
% 19.01 29.07.14 UD     Remove Table object - is not supported in Matlab R2013a  
% 18.12 09.07.14 UD     Created
%-----------------------------

% debug and testing
if nargin < 1, Par          = TPA_ParInit; end;
if nargin < 2, EventTable   = fGetDebugData(3); end;

% check that this is a table
%if ~strcmp(class(EventTable),'table'), error('Second input must be a table object'); end;
[rNum,cNum]                 = size(EventTable.Data);

% clean the data - must be numeric
%cellData                    = table2cell(EventTable);
cellData                    = (EventTable.Data);
cellData(isnan(cellData))   = 0;
% keep 0/1
%cellBool                    = cellfun(@(x) (islogical(x)),cellData);
%cellData(cellBool)  = double(cellData(cellBool));
%cellData(cellfun(@(x) (isempty(x) || ~isnumeric(x) || isnan(x)),cellData)) = {0};
%cellData(cellfun(@(x) strcmp(x,'NaN'),cellData)) = {0};

% prepare for later
EventTableDataFix           = cellData; %cell2mat(cellData);
ControlTableData            = [min(EventTableDataFix);max(EventTableDataFix);zeros(1,cNum)]; % keep this data for checks
QueryTableData              = zeros(rNum,1);
EventTableData              = [EventTableDataFix;ControlTableData];

% GUI prepared
%QueryTable                  = table(QueryTableData); %table; % empty table object
QueryTable.Data                = QueryTableData; %table; % empty table object
%ControlTable                = array2table(ControlTableData);



% add columns
QueryTable.ColumnNames          = {'Query'};
QueryTable.RowNames             = EventTable.RowNames;
eventRowNames                       = cat(1,EventTable.RowNames, {'Min <= ';' <= Max';'And'});
eventVariableNames                  = EventTable.ColumnNames;
EventTable.Data                     = (EventTableData);
EventTable.RowNames                 = eventRowNames;
EventTable.ColumnNames              = eventVariableNames;


% % build extended table with control fields
% EventTableData                       = [EventTableData zeros(rNum,1);zeros(3,cNum+1)];
% newTable                    = array2table(EventTableData);
% newTable.Properties.VariableNames = cat(2,EventTable.Properties.VariableNames, {'Query'});
% newTable.Properties.RowNames      = cat(1,EventTable.Properties.RowNames, {'Min <= ';' < Max';'And'});
% 
%EventTable                  = newTable;

% structure with GUI handles
handStr                             = [];
fCreateGUI();

% handle for blocking -  do not go out until QueryTable is updated
%HandleFig                       = handStr.hFig;

uiwait(handStr.hFig);



return


               
%-----------------------------------------------------
% Callback for editing of the tables 
    
    function fUpdateQuery()
        
        % checks the data in the control panel and applies
        % it to for a query event generation
        
        % new input
        EventTableData   = get(handStr.hEventTable,'Data');
        ControlTableData = EventTableData(rNum+1:rNum+3,:);
        
        % get columns that they 1
        validColInd     = find(ControlTableData(3,:) > 0);
        if isempty(validColInd), 
            QueryTableData(:)           = 0;
            QueryTable.ColumnNames{1}   = 'None';
            set(handStr.hQueryTable,    'Data',QueryTableData, 'ColumnName', QueryTable.ColumnNames);
            return; 
        end;
        
        % valid rows
        minCond     = bsxfun(@le,ControlTableData(1,validColInd),EventTableData(1:rNum,validColInd)); 
        maxCond     = bsxfun(@le,EventTableData(1:rNum,validColInd),ControlTableData(2,validColInd));
        goodCond    = minCond & maxCond;
        selectCond  = all(goodCond,2);
        
        % check
        if any(sum(goodCond,2)>1),
            set(handStr.hQueryTable,'ForegroundColor','r')
            DTP_ManageText([], sprintf('EventEdit : Selection contains overlapping events.'), 'W' ,0);
        else
            set(handStr.hQueryTable,'ForegroundColor','k')
        end
        
        % update :  select rows with max numbers that all conditions are OK
        selectData     = bsxfun(@times,double(selectCond),EventTableData(1:rNum,validColInd)); 
        QueryTableData = max(selectData,[],2);
        set(handStr.hQueryTable,'Data',QueryTableData);
        QueryTable.Data   = QueryTableData; % save for exit
        
        % chenge query name 
        QueryTable.ColumnNames{1}   = EventTable.ColumnNames{validColInd(1)};
        set(handStr.hQueryTable ,  'ColumnName', QueryTable.ColumnNames);
        
        
        
    end
        



    function fCellEditCallback(hObject, eventdata)
    % hObject    Handle to uitable1 (see GCBO)
    % eventdata  Currently selected table indices
    % Callback check data entry and aplyer query over selected columns
    % 
        
        % Get the list of currently selected table cells
        sel         = eventdata.Indices;     % Get selection indices (row, col)
        if isempty(sel), return; end;        % I do not understand why
        
        % put back original value
        if sel(1) <= rNum, % not editable
            val    = EventTableDataFix(sel(1),sel(2));
        else
            EventTableData   = get(handStr.hEventTable,'Data');
            val    = EventTableData(sel(1),sel(2));
        end; 
        
        % checks
        if sel(1) == rNum+3,
            EventTableData(sel(1),sel(2)) = double(val > 0);
        else
            EventTableData(sel(1),sel(2)) = val;
        end
        % display
        set(handStr.hEventTable,'Data',EventTableData);
        
        % calc
        fUpdateQuery();
        
    end

%-----------------------------------------------------
% Create debug info  

    function EventTable = fGetDebugData(selType)
        
        if nargin < 1, selType = 1; end;
        
        % Save relevant info and form a new group
        switch selType,
            case 1,
                EventTable      =  table(['M';'M';'F';'F';'F'],[38;43;38;40;49],[71;69;64;67;64],[176;163;131;133;119]);
            case 2,
                S               = load('patients.mat');
                EventTable      = table(S.Age,S.Gender,S.Height,S.Weight,S.Smoker,'RowNames',S.LastName);
            case 3,
                %EventTable      = readtable('rawtest.csv','ReadRowNames',true);
                [ndata, text, allData]  = xlsread('rawtest.csv');
                EventTable.ColumnNames  = text(1,:);
                EventTable.RowNames     = mat2cell((1:size(ndata,1))',ones(1,size(ndata,1)),1); %   num2str((1:size(ndata,1)'));
                EventTable.Data         = ndata;
                
%                 fileID          = fopen('rawtest.csv','r');
%                 EventTable      = textscan(fileID, '%s', 'Delimiter', ',', 'HeaderLines' ,2-1, 'ReturnOnError', false);
%                 fclose(fileID);
           case 4,
                EventTable      = readtable('processtest.csv','ReadRowNames',true);
            otherwise
                error('Bad selType')
        end
    end

%-----------------------------------------------------
% Create 

    function fCreateGUI() %#ok<*INUSD> eventdata is trialedly unused
        
        ScreenSize  = get(0,'ScreenSize');
        figWidth    = 900;
        figHeight   = 600;
        figX = (ScreenSize(3)-figWidth)/2;
        figY = (ScreenSize(4)-figHeight)/2;
        
        hFig=figure( ...
            'Visible','on', ...
            'NumberTitle','off', ...
            'name', '4D : Multi Event Query Editor',...
            'position',[figX, figY, figWidth, figHeight],...
            'menubar', 'none',...
            'toolbar','none',...
            'WindowStyle','modal',...
            'Tag','AnalysisROI',...
            'Color','black');

        colordef(hFig,'none')
        
        
        
        % tables
        colwdt = 30; % column width in pixels
        % Create a uitable on the left side of the figure
        hEventTable = uitable('Units', 'normalized',...
                         'Position',        [0.03 0.03 0.76 0.94],...
                         'Data',            EventTableData,... 
                         'ColumnName',      EventTable.ColumnNames,...
                         'ColumnFormat',    repmat({'numeric'},1,cNum),...
                         'ColumnEditable',  true,...
                         'ColumnWidth',     'auto',...
                         'RowName',         EventTable.RowNames,...
                         'ToolTipString',   'Cells is not possible to edit',...
                         'CellEditCallback', {@fCellEditCallback});
        
      %                      'ColumnWidth',     colwdt,...
     
         hQueryTable = uitable('Units', 'normalized',...
                         'Position',        [0.8 0.2 0.18 0.77],...
                         'Data',            QueryTableData,... 
                         'ColumnName',      QueryTable.ColumnNames,...
                         'ColumnFormat',    {'numeric'},...
                         'ColumnEditable',  false,...
                         'RearrangeableColumns','on',...
                         'ColumnWidth',     'auto',...
                         'RowName',         QueryTable.RowNames,...
                         'ToolTipString',   'Select cells to highlight them on the plot',...
                         'CellSelectionCallback', '');
       
%          hControlTable = uitable('Units', 'normalized',...
%                          'Position',        [0.03 0.03 0.82 0.165],...
%                          'Data',            ControlTableData,...  %table2cell(ControlTable),... 
%                          'ColumnName',      ControlTable.Properties.VariableNames,...
%                          'ColumnFormat',    repmat({'numeric'},1,cNum),...
%                          'ColumnEditable',  true,...
%                          'ColumnWidth',     get(hEventTable,'ColumnWidth') ,...
%                          'RowName',         ControlTable.Properties.RowNames,...
%                          'ToolTipString',   'Double click and add number to this cell',...
%                          'CellEditCallback', {@fCellEditCallback});
                     
                 
%         jScroll = findjobj(hEventTable);
%         jTable = jScroll.getViewport.getView;
%         jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS)                     
%         jScroll = findjobj(hControlTable);
%         jTable = jScroll.getViewport.getView;
%         jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS)   

        
        % The close button.
        uicontrol( ...
            'Style','pushbutton', ...
            'Units','normalized', ...
            'Position',[0.8 0.03 0.18 0.05], ...
            'String','Close', ...
            'Callback',{@fCloseRequestFcn});

                     

        handStr.hFig            = hFig;
        handStr.hEventTable     = hEventTable;
        handStr.hQueryTable     = hQueryTable;
       % handStr.hControlTable   = hControlTable;
        
        
    end

%-----------------------------------------------------
% Close

    function fCloseRequestFcn(~, ~)
        % This is where we can return the ROI selected
        
        %fExportROI();               % check that ROI structure is OK
        
        %uiresume(handStr.roiFig);
        try
            %             % remove from the child list
            %             ii = find(SGui.hChildList == handStr.roiFig);
            %             SGui.hChildList(ii) = [];
            uiresume(handStr.hFig);
            delete(handStr.hFig);
        catch ex
            errordlg(ex.getReport('basic'),'Close Window Error','modal');
        end
        % return attention
        %figure(SGui.hMain)
    end




 end