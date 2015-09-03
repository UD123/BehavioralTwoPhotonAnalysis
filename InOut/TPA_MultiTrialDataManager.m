classdef TPA_MultiTrialDataManager
    % TPA_MultiTrialDataManager - Collects Behavioral and TwoPhoton info from all the relevant trials
    % Inputs:
    %       BDA_XXX.mat, TPA_YYY.mat - data base
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 20.07 27.05.15 UD     Fixing event multi index bug - check that events are not present
    % 20.04 17.05.15 UD     Event data is continuos
    % 19.28 28.04.15 UD     Fixing time when multiple Z-stacks are used
    % 19.22 12.02.15 UD     Adding more test cases for load
    % 19.11 16.10.14 UD     Supporting seq num and group analysis. strcmp review
    % 19.04 12.08.14 UD     Working on integration with Event Editor for JAABA files
    % 19.00 12.07.14 UD     Query support by adding dummy event
    % 18.10 09.07.14 UD     All trials per event. Fixing bug with alignment
    % 18.04 28.04.14 UD     Align per ROI
    % 17.08 05.04.14 UD     Support no behavioral data
    % 16.16 24.02.14 UD     Created
    %-----------------------------
    
    
    properties
        
        
        % containers of events and rois
        DbROI               = {};
        DbRoiRowCount       = 0;
        DbEvent             = {};
        DbEventRowCount     = 0;
        
        % Trials
        ValidTrialNum       = 0;   % how many trials do we have
        UniqueEventNames    = {};  % contains event names - unique
        UniqueEventNum      = 0;   % how many different event we have
        UniqueRoiNames      = {};  % contains roi names - unique
        UniqueRoiNum        = 0;   % how many different ROI we have

        % copy of the containers with file info
        DMB                 = [];   % behaivior
        DMT                 = [];   % two photon
        
        % Time rescaling 
        Behavior_Resolution  = [1 1 1 1];  % init from outside according to the 
        Behavior_Offset      = [0 0 0 0];
        TwoPhoton_Resolution = [1 1 1 1];
        TwoPhoton_Offset     = [0 0 0 0];
        TwoPhoton_FrameNum   = 0;
        TwoPhoton_SliceNum   = 0;
        
        % TYPES (shouild be defined globaly)
        % message
        %EVENT_TYPES         = []; %struct('NONE',1,'UPDATE_IMAGE',2,'UPDATE_ROI',3);
        % sources
        %GUI_TYPES           = []; %struct('MAIN_GUI',1,'TWO_PHOTON_XY',2,'TWO_PHOTON_YT',3,'BEHAVIOR_XY',4,'BEHAVIOR_YT',5);
        
        
    end % properties
    properties (SetAccess = private)
        TimeConvertFact     = 1;           % time conversion >= 1 between behav - fast and twophoton - slow
    end

    methods
        
        % ==========================================
        function obj = TPA_MultiTrialDataManager()
            % TPA_MultiTrialDataManager - constructor
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values

            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = Init(obj,Par)
            % Init - init Par structure related managers of the DB
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            
            if nargin < 1, error('Must have Par'); end;
            
            % manager copy
            obj.DMB                     = Par.DMB;
            obj.DMT                     = Par.DMT;
            
            % resolution updates
            obj.Behavior_Resolution     = Par.DMB.Resolution;
            obj.Behavior_Offset         = Par.DMB.Offset;
            obj.TwoPhoton_Resolution    = Par.DMT.Resolution;
            obj.TwoPhoton_Offset        = Par.DMT.Offset;
            obj.TwoPhoton_SliceNum      = Par.DMT.SliceNum;
            
            % check
            if obj.Behavior_Resolution(4) < 1,
                obj.Behavior_Resolution(4) = 1;
            end
            if obj.TwoPhoton_Resolution(4) < 1,
                obj.TwoPhoton_Resolution(4) = 1;
            end
            if obj.TwoPhoton_SliceNum < 1,
                obj.TwoPhoton_SliceNum = 1;
            end
            
            obj.TimeConvertFact         = round(obj.Behavior_Resolution(4)/obj.TwoPhoton_Resolution(4)*obj.TwoPhoton_SliceNum);   
            
        end
        % ---------------------------------------------
        
     
        % ==========================================
        function tcFact = GetTimeConvertFact(obj)
            % GetTimeConvertFact - conversion factor
            % Input:
            %    none
            % Output:
            %    tcFact     -ratio between Behavior and TwoPhoton frame rates
            
            tcFact = obj.TimeConvertFact;
        end
        % ---------------------------------------------
        
     
        % ==========================================
        function obj = SetTimeConvertFact(obj)
            % SetTimeConvertFact - manually define conversion factor between behavior and two photon time frames
            % Input:
            %    none
            % Output:
            %    obj     - updated ratio between Behavior and TwoPhoton frame rates
            
            options.Resize      ='on';
            options.WindowStyle ='modal';
            options.Interpreter ='none';
            prompt              = {sprintf('Change Frame Rate ratio factor Behavior/TwoPhoton : ')};
            name                = 'Set Frame Rate Ratio';
            numlines            = 1;
            defaultanswer       = {num2str(obj.TimeConvertFact)};

            answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
            if isempty(answer), return; end;
            tcFact              = str2double(answer{1});
            
            if tcFact < 1 || tcFact > 16,
                DTP_ManageText([], 'Frame conversion factor should be in range [1-16]', 'E' ,0)   ;
                return;
            end
            if ~isequal(tcFact, round(tcFact)),
                DTP_ManageText([], 'Frame conversion factor should be an integer', 'E' ,0)   ;
                return;
            end
            
            
            obj.TimeConvertFact         = tcFact;
            obj.Behavior_Resolution(4)  = tcFact * obj.TwoPhoton_Resolution(4)*obj.TwoPhoton_SliceNum;
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function [obj,IsOK] = CheckDataFromTrials(obj)
            % CheckDataFromTrials - check ROI data
            % Input:
            %     obj  - after Par init
            % Output:
            %     IsOK - true if OK
            
            IsOK = false;
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Do some data ready test
            %%%%%%%%%%%%%%%%%%%%%%
            obj.DMT                 = obj.DMT.CheckData(false);     % important step to validate number of valid trials  
                                                                    % false means do not read dir again
            validTrialNum           = obj.DMT.RoiFileNum;           % only analysis data
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : Missing Two Photon ROI data in directory %s. Please check the folder or run Data Check',obj.DMT.RoiDir),  'E' ,0);
                return
            else
                DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI. ',validTrialNum),  'I' ,0);
            end

            % bring one file and check that it has valid data : mean and proc ROI
            trialInd                          = 1;
            [obj.DMT,isOK]                    = obj.DMT.SetTrial(trialInd);
            [obj.DMT,strROI]                  = obj.DMT.LoadAnalysisData(trialInd,'strROI');

            % Need to do it more nicely but
            if length(strROI) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find ROI data %s. Please check the folder or run define ROI',obj.DMT.RoiDir),  'E' ,0);
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

            IsOK = true;
            
        
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = LoadDataFromTrials(obj,Par)
            % LoadDataFromTrials - loads all the availabl info
            % Input:
            %     Par - header properties
            % Output:
            %     msgObj - meassge structure
            
            if nargin == 2, obj   = obj.Init(Par); end;
            
   
            %%%%%%%%%%%%%%%%%%%%%%
            % Run over all files/trials and load the Analysis data
            %%%%%%%%%%%%%%%%%%%%%%
            validTrialNum           = length(obj.DMT.RoiFileNames);
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No TwoPhoton Analysis data in directory %s. Please check the folder or run Data Check',obj.DMT.RoiDir),  'E' ,0);
                return
            end
            validTrialNumEv           = min(validTrialNum,length(obj.DMB.EventFileNames));
            if validTrialNumEv < 1,
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder or run Data Check',obj.DMB.EventDir),  'E' ,0);
                %return
            else
                DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI and Events. Reading ...',validTrialNumEv),  'I' ,0);
            end

            obj.ValidTrialNum = validTrialNum;

            for trialInd = 1:validTrialNum,


                    [obj.DMT, strROI]           = obj.DMT.LoadAnalysisData(trialInd,'strROI');
                    % this code helps with sequential processing of the ROIs: use old one in the new image
                    numROI                      = length(strROI);
                    if numROI < 1,
                        DTP_ManageText([], sprintf('Multi Trial : There are no ROIs in trial %d. Trying to continue',trialInd),  'E' ,0);
                    end

                    % read the info
                    for rInd = 1:numROI,
                       obj.DbRoiRowCount                = obj.DbRoiRowCount + 1;
                       obj.DbROI{obj.DbRoiRowCount,1}   = trialInd;
                       obj.DbROI{obj.DbRoiRowCount,2}   = rInd;                   % roi num
                       obj.DbROI{obj.DbRoiRowCount,3}   = strROI{rInd}.Name;      % name 
                       obj.DbROI{obj.DbRoiRowCount,4}   = strROI{rInd}.procROI;
                    end
                    
                    if numROI > 0,
                    obj.TwoPhoton_FrameNum     = size(strROI{rInd}.procROI,1);
                    end
                    if trialInd > validTrialNumEv, continue; end
                    
                    [obj.DMB, strEvent]         = obj.DMB.LoadAnalysisData(trialInd,'strEvent');
                    % this code helps with sequential processing of the ROIs: use old one in the new image
                    numEvent                    = length(strEvent);
                    if numEvent < 1,
                        DTP_ManageText([], sprintf('Multi Trial : There are no events in trial %d. Trying to continue',trialInd),  'E' ,0);
                    end

                    % read the info
                    for eInd = 1:numEvent,
                       obj.DbEventRowCount                = obj.DbEventRowCount + 1;
                       obj.DbEvent{obj.DbEventRowCount,1} = trialInd;
                       obj.DbEvent{obj.DbEventRowCount,2} = eInd;                   % event num
                       obj.DbEvent{obj.DbEventRowCount,3} = strEvent{eInd}.Name;      % name 
                       if isfield(strEvent{eInd},'Data') && ~isempty(strEvent{eInd}.Data),
                            eventData                     = strEvent{eInd}.Data(:,2); % rescale time
                       else
                           eventData                      = zeros(2400,1); % NEED to know frameNum
                       end
                       dataLen                            = size(eventData,1);
                       if dataLen > 10, eventData         = resample(double(eventData),1,obj.TimeConvertFact); end;
                       obj.DbEvent{obj.DbEventRowCount,4} = eventData; % rescale time
                       % seq num support
                       seqNum = 1;
                       if isfield(strEvent{eInd},'SeqNum'), seqNum = strEvent{eInd}.SeqNum; end
                       obj.DbEvent{obj.DbEventRowCount,5} = seqNum;
                    end
%                     
%                     % adding dummy Query event
%                     obj.DbEventRowCount = obj.DbEventRowCount + 1;
%                     obj.DbEvent{obj.DbEventRowCount,1} = trialInd;
%                     obj.DbEvent{obj.DbEventRowCount,2} = numEvent+1;                   % event num
%                     obj.DbEvent{obj.DbEventRowCount,3} = 'Query';       % name 
%                     obj.DbEvent{obj.DbEventRowCount,4} = [0 0];             % rescale time - will be assigned later
%                     obj.DbEvent{obj.DbEventRowCount,5} = 1;
            end
            
            obj = CheckUniqueNames(obj);            
            DTP_ManageText([], sprintf('Multi Trial : Database Ready.'),  'I' ,0);

        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = LoadEventsFromQuery(obj,QueryTable)
            % LoadEventsFromQuery - converts query table data to dbEvent structure
            % Input:
            %     QueryTable - query table structure with ColumnNames,RowNames and data (1 - coumn is assumed)
            % Output:
            %     msgObj - meassge structure
            
            if nargin < 2, error('Must have Query Table'); end;
            
            obj.DbEvent             = {};
            obj.DbEventRowCount     = 0;
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Run over all files/trials and load the Analysis data
            %%%%%%%%%%%%%%%%%%%%%%
            if obj.ValidTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No TwoPhoton Analysis data in directory %s. Please check the folder or run Data Check',obj.DMT.RoiDir),  'E' ,0);
                return
            end
            validTrialNumEv       = size(QueryTable.Data,1);
            if validTrialNumEv < 1,
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data in excel query. Please recheck your selection Query Editor'),  'E' ,0);
                return
            else
                validEventInd       = find(QueryTable.Data(:,1) > 0);
                validTrialNumEv     = length(validEventInd);
                if validTrialNumEv < 1,
                    DTP_ManageText([], sprintf('Multi Trial : No valid events in the current query (all zeros). Please recheck your selection Query Editor'),  'E' ,0);
                    return
                else
                    DTP_ManageText([], sprintf('Multi Trial : Found %d valid Events in the current query. Converting ...',validTrialNumEv),  'I' ,0);
                end
            end
            
            % max frame number
            behaviorFrameNum    = max(QueryTable.Data);
            if behaviorFrameNum < 5,
                DTP_ManageText([], sprintf('Multi Trial : Current query data does not contain valid frame numbers. Please recheck your selection Query Editor'),  'E' ,0);
                return
            end
            % give opportunity to user to set the frame rates correctly
            if behaviorFrameNum/obj.TimeConvertFact > obj.TwoPhoton_FrameNum ,
                obj = SetTimeConvertFact(obj);
            end
            % recheck
            if behaviorFrameNum/obj.TimeConvertFact > obj.TwoPhoton_FrameNum ,
                DTP_ManageText([], sprintf('Multi Trial : Behavior data frame numbmers exceed two photon numbers. Please recheck your selection Query/Frame Rate factor/Two Photon data'),  'E' ,0);
                return
            end

            % convert
            for m = 1:validTrialNumEv,
                
                    trialInd                    = validEventInd(m);
                    eventStartTime              = QueryTable.Data(trialInd,1);
                    frameTime                   = ceil(eventStartTime/obj.TimeConvertFact); % rescale time


                    % save the info
                   obj.DbEventRowCount = obj.DbEventRowCount + 1;
                   obj.DbEvent{obj.DbEventRowCount,1} = trialInd;
                   obj.DbEvent{obj.DbEventRowCount,2} = 1;                             % event num
                   obj.DbEvent{obj.DbEventRowCount,3} = QueryTable.ColumnNames{1};      % name 
                   obj.DbEvent{obj.DbEventRowCount,4} = [frameTime frameTime+1]; 
                   obj.DbEvent{obj.DbEventRowCount,5} = 1;                             % event seq num

                    
            end
            obj = CheckUniqueNames(obj);                        
            DTP_ManageText([], sprintf('Multi Trial : Query to Event Conversion Ready.'),  'I' ,0);

        end
        % ---------------------------------------------
        
        
        % ==========================================
        function RoiNames = GetRoiNames(obj)
            % GetRoiNames - extract unique names from ROI data
            % Input:
            %    none
            % Output:
            %    RoiNames     - list of names
            if obj.UniqueRoiNum < 1 && ~isempty(obj.DbROI),
                %RoiNames            = unique(strvcat(obj.DbROI{:,3}),'rows');
                RoiNames            = unique(obj.DbROI(:,3));
            else % save computation
                RoiNames            = obj.UniqueRoiNames;
            end
                
        end
        % ---------------------------------------------
        % ==========================================
        function EventNames = GetEventNames(obj)
            % GetEventNames - extract unique names from ROI data
            % Input:
            %    none
            % Output:
            %    EventNames     - list of names
            if obj.UniqueEventNum < 1 && ~isempty(obj.DbEvent),
                %EventNames            = unique(strvcat(obj.DbEvent{:,3}),'rows');
                EventNames            = unique(obj.DbEvent(:,3));
            else % save computation
                EventNames            = obj.UniqueEventNames;
            end
       end
        % ---------------------------------------------
        
        % ==========================================
        function obj = CheckUniqueNames(obj)
            % CheckUniqueNames - check ROI and Event names
            % Input:
            %     obj  - after init
            % Output:
            %     number of unique oi names
            
            roiNames                = GetRoiNames(obj);            
            eventNames              = GetEventNames(obj);            
                        
            obj.UniqueEventNames    = eventNames;  % contains event names - unique
            obj.UniqueEventNum      = length(eventNames);   % how many different event we have
            obj.UniqueRoiNames      = roiNames;  % contains roi names - unique
            obj.UniqueRoiNum        = length(roiNames);   % how many different ROI we have
        end        
        % ---------------------------------------------
        
        
         
        % ==========================================
        function DataStr = TracesPerTrial(obj, TrialInd)
            % TracesPerTrial - extract all the traces per trial
            % Input:
            %    TrialInd - which trial to show
            % Output:
            %    DataStr.Roi            - list of names and data
            %    DataStr.Event          - list of names and data
            
            if nargin < 2, TrialInd = 1; end
            TrialInd        = TrialInd(1);
            if TrialInd < 1 || TrialInd > obj.ValidTrialNum,
                error('Trial Index %d should be in the range 1 : %d',TrialInd,obj.ValidTrialNum)
            end
            DataStr = [];
            
            % find trial
            trialBool       = [obj.DbROI{:,1}] == TrialInd;
            DataStr.Roi     = obj.DbROI(trialBool,:);      % name + dFF
            trialBool       = [obj.DbEvent{:,1}] == TrialInd;
            DataStr.Event   = obj.DbEvent(trialBool,:);      % name + dFF


            DTP_ManageText([], sprintf('Multi Trial : Extraction of trial %d Ready.',TrialInd),  'I' ,0);

        end
        % ---------------------------------------------
        % ==========================================
        function DataStr = TracesPerRoi(obj, RoiName)
            % TracesPerRoi - extract all the traces per Roi
            % Input:
            %    RoiName - which roi to show
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, RoiName = ''; end
            DataStr = [];
            
            roiNames        = GetRoiNames(obj);
            roiInd         = strmatch(RoiName,roiNames);
            if length(roiInd) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Roi name %s.',RoiName),  'E' ,0);
                return
            end
            
            % find trials for selected ROI
            roiPos          = strmatch(RoiName,obj.DbROI(:,3),'exact') ;          
            %roiPos          = strmatch(RoiName,strvcat(obj.DbROI{:,3})) ;          
            DataStr.Roi     = obj.DbROI(roiPos,:);      % trial num + dFF
            %trialInd        = [obj.DbROI{roiPos,1}];
            
            % find events for all trials
            %[c,ia,evntInd]  = intersect(roiInd,[obj.DbEvent{:,1}]);
            %evntInd         = ismember([obj.DbEvent{:,1}],trialInd);     
            DataStr.Event   = []; %obj.DbEvent(evntInd,:);      % name + time
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces for %s is ready.',RoiName),  'I' ,0);

        end
        % ---------------------------------------------
        
        % ==========================================
        function DataStr = TrialsPerEvent(obj, EventName)
            % TrialsPerEvent - extract all the trials per Event 
            % Input:
            %    EventName - which event to show
            %    TrialInds - from which trial
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, EventName = ''; end
            DataStr = [];
            %EventName         = deblank(EventName);
            
            eventNames        = GetEventNames(obj);
            eventInd          = strcmp(eventNames,EventName);
            if length(eventInd) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Event name %s.',EventName),  'E' ,0);
                return
            end
            
            % find trials for selected Event
            eventPos        = strmatch(EventName,obj.DbEvent(:,3),'exact') ; %strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %eventPos        = strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %trialInd        = [obj.DbEvent{eventPos,1}]; % all trials for specific event
            
            %roiInd          = ismember([obj.DbROI{:,1}],trialInd);    
            DataStr.Roi     = []; %obj.DbROI(roiInd,:);      % trial num + dFF
            DataStr.Event   = obj.DbEvent(eventPos(:),:);      % name + time
            DTP_ManageText([], sprintf('Multi Trial : Extraction of trials per event %s is ready.',EventName),  'I' ,0);

        end
        % ---------------------------------------------
        
        
        % ==========================================
        function DataStr = TracesPerRoiEvent(obj, RoiName, EventName)
            % TracesPerRoiEvent - extract all the traces per Roi and Event
            % Input:
            %    RoiName - which roi to show
            %    EventName - which event to show
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, RoiName = ''; end
            DataStr = [];
            
            roiNames        = GetRoiNames(obj);
            roiInd         = strmatch(RoiName,roiNames);
            if length(roiInd) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Roi name %s.',RoiName),  'E' ,0);
                return
            end
            eventNames        = GetEventNames(obj);
            eventInd          = strmatch(EventName,eventNames);
            if length(eventInd) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Event name %s.',EventName),  'E' ,0);
                return
            end
            
            
            % find trials for selected ROI
            %roiPos          = strmatch(RoiName,strvcat(obj.DbROI{:,3})) ;          
            roiPos          = strmatch(RoiName,obj.DbROI(:,3),'exact') ;          
            trialIndRoi     = [obj.DbROI{roiPos,1}];
            
            % find trials for selected Event
            eventPos        = strmatch(EventName,obj.DbEvent(:,3),'exact') ; %strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %eventPos        = strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            trialIndEvent   = [obj.DbEvent{eventPos,1}]; % all trials for specific event
            
            
            % if there are no events related - do not show those ROI
            roiInd          = ismember(trialIndRoi,trialIndEvent);     
            eventInd        = ismember(trialIndEvent,trialIndRoi);     
            

            % find events for all trials
            %[c,ia,evntInd]  = intersect(roiInd,[obj.DbEvent{:,1}]);
            %evntInd         = ismember([obj.DbEvent{:,1}],trialInd);     
            DataStr.Roi     = obj.DbROI(roiPos(roiInd),:);      % trial num + dFF
            DataStr.Event   = obj.DbEvent(eventPos(eventInd),:);      % name + time
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces for ROI %s and Event %s is ready.',RoiName,EventName),  'I' ,0);

        end
        % ---------------------------------------------
 
        % ==========================================
        function DataStr = TracePerEventTrial(obj, EventName, TrialInds)
            % TracePerEventTrial - extract all the traces per Event and Trial
            % Trial could be multiple index
            % Input:
            %    EventName - which event to show
            %    TrialInds - from which trial
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, EventName = ''; end
            if nargin < 3, TrialInds = 1;  end
            DataStr = [];
            
            eventNames        = GetEventNames(obj);
            eventInd          = strmatch(EventName,eventNames);
            if length(eventInd) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Event name %s.',EventName),  'E' ,0);
                return
            end
            
            % find trials for selected Event
            eventPos        = strmatch(EventName,obj.DbEvent(:,3),'exact') ; %strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %eventPos        = strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            trialInd        = [obj.DbEvent{eventPos,1}]; % all trials for specific event
            
            % filter by current input
            trialInd        = intersect(trialInd,TrialInds);
            
            % find events for all trials
            %[c,ia,evntInd]  = intersect(roiInd,[obj.DbEvent{:,1}]);
            roiInd         = ismember([obj.DbROI{:,1}],trialInd);    
            DataStr.Roi     = obj.DbROI(roiInd,:);      % trial num + dFF
            
            eventInd         = ismember([obj.DbEvent{:,1}],trialInd);    
            DataStr.Event    = obj.DbEvent(eventPos(trialInd),:);      % name + time
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces per event %s is ready.',EventName),  'I' ,0);

        end
        % ---------------------------------------------
          
        % ==========================================
        function DataStr = TracePerEventRoiTrial(obj, EventName, RoiInds, TrialInds)
            % TracePerEventRoiTrial - extract all the traces per Event, Rois and Trials
            % ROIs,Trial could be multiple index
            % Input:
            %    EventName - which event to show
            %    RoiInds   - from which ROI (multiple)
            %    TrialInds - from which trial (multiple)
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, EventName = ''; end
            if nargin < 3, TrialInds = 1;  end
            DataStr = [];
            
            eventNames        = GetEventNames(obj);
            eventInd          = strmatch(EventName,eventNames,'exact');
            if length(eventInd) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Event name %s.',EventName),  'E' ,0);
                return
            end
            
            roiNames        = GetRoiNames(obj);
            roiNum          = size(roiNames,1);
            if any(RoiInds < 1) || any(RoiInds > roiNum),
                DTP_ManageText([], sprintf('Multi Trial : Bad Roi index specified.'),  'E' ,0);
                return
            end
            
            if any(TrialInds < 1) || any(TrialInds > obj.ValidTrialNum),
                error('Trial Index %d should be in the range 1 : %d',TrialInd,obj.ValidTrialNum)
            end
            
            % find trials for selected Event
            %eventPos        =  strmatch(EventName,obj.DbEvent(:,3),'exact') ; %strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            eventPos        =  find(strcmp(EventName,obj.DbEvent(:,3))) ; % faile when the same string in different name          
            trialIndEvent   = [obj.DbEvent{eventPos,1}]; % all trials for specific event

            % filter by current input
            trialBoolEvent  = ismember(trialIndEvent,TrialInds);
            %trialIndEvent   = trialInd(trialBoolEvent);
            
            % find trials for selected ROIs
            roiPos          = [];
            for m = 1:length(RoiInds),
                %roiPos      = [roiPos; strmatch(roiNames(RoiInds(m),:),strvcat(obj.DbROI{:,3}))];  
                roiPos      = [roiPos; strmatch(roiNames(RoiInds(m),:),obj.DbROI(:,3),'exact')];  
            end
            trialIndRoi     = [obj.DbROI{roiPos,1}];
            
            % filter by current input
            trialBoolRoi     = ismember(trialIndRoi,TrialInds);
            %trialIndRoi      = trialInd(trialBoolRoi);
            
            % if there are no events related - do not show those ROI
            trialBoolRoi     = ismember(trialIndRoi.*trialBoolRoi,trialIndEvent);
            %trialIndRoi      = trialInd(trialBoolRoi);
            
            
            % find events for all trials
            %[c,ia,evntInd]  = intersect(roiInd,[obj.DbEvent{:,1}]);
            DataStr.Roi      = obj.DbROI(roiPos(trialBoolRoi),:);      % trial num + dFF
            DataStr.Event    = obj.DbEvent(eventPos(trialBoolEvent),:);      % name + time
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces per event %s is ready.',EventName),  'I' ,0);

        end
        % ---------------------------------------------

        % ==========================================
        function DataStr = TraceAlignedPerEventRoiTrial(obj, EventName, RoiInds, TrialInds)
            % TraceAlignedPerEventRoiTrial - extract all the traces per Event, Rois and Trials
            % ROIs,Trial could be multiple index
            % Align traces according to the event time start
            % Input:
            %    EventName - which event to show
            %    RoiInds   - from which ROI (multiple)
            %    TrialInds - from which trial (multiple)
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, EventName = ''; end
            if nargin < 3, RoiInds   = 1;  end
            if nargin < 4, TrialInds = 1;  end
            DataStr = [];
            
            eventNames        = GetEventNames(obj);
            eventInd          = strmatch(EventName,eventNames);
            if length(eventInd) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Event name %s.',EventName),  'E' ,0);
                return
            end
            
            roiNames        = GetRoiNames(obj);
            roiNum          = size(roiNames,1);
            if any(RoiInds < 1) || any(RoiInds > roiNum),
                DTP_ManageText([], sprintf('Multi Trial : Bad Roi index specified.'),  'E' ,0);
                return
            end
            
            if any(TrialInds < 1) || any(TrialInds > obj.ValidTrialNum),
                error('Trial Index %d should be in the range 1 : %d',TrialInd,obj.ValidTrialNum)
            end
            
            % find trials for selected Event
            eventPos        =  strmatch(EventName,obj.DbEvent(:,3),'exact') ; %strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %eventPos        = strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            trialIndEvent   = [obj.DbEvent{eventPos,1}]; % all trials for specific event

            % filter by current input
            trialBoolEvent   = ismember(trialIndEvent,TrialInds);
            trialIndEvent    = trialIndEvent(trialBoolEvent);
            
            % find trials for selected ROIs
            roiPos          = [];
            for m = 1:length(RoiInds),
                roiPos      = [roiPos; strmatch(roiNames(RoiInds(m),:),obj.DbROI(:,3),'exact')];  
               % roiPos      = [roiPos; strmatch(roiNames(RoiInds(m),:),strvcat(obj.DbROI{:,3}))];  
            end
            trialIndRoi        = [obj.DbROI{roiPos,1}];
            
            % filter by current input
            trialBoolRoi     = ismember(trialIndRoi,TrialInds);
            %trialIndRoi      = trialIndRoi(trialBoolRoi);
            
            % if there are no events related - do not show those ROI
            trialBoolRoi     = ismember(trialIndRoi.*trialBoolRoi,trialIndEvent);
            trialIndRoi      = trialIndRoi(trialBoolRoi);

            
            % extract data
            DataStr.Roi      = obj.DbROI(roiPos(trialBoolRoi),:);           % trial num + dFF
            DataStr.Event    = obj.DbEvent(eventPos(trialBoolEvent),:);      % name + time
            
            % start alignment
            for m = 1:length(TrialInds),
                
                % all rois related to the current trial - could be several 
                iR      = find(trialIndRoi == TrialInds(m));
                if isempty(iR), continue; end
                procROI  = DataStr.Roi{iR(1),4}; % The first one only
                frameNum = size(procROI,1);
                
                % all events related to the current trial - could be several - choose the first one
                iE      = find(trialIndEvent == TrialInds(m));
                if isempty(iE), continue; end
                iE      = iE(1); % The first one only
                tEvent  = DataStr.Event{iE,4};
                tDelta  = round(frameNum/2) - tEvent(1); % delata move to the middle
                tEvent  = tEvent + tDelta; % move to the middle
                DataStr.Event{iE,4} = tEvent;
                
                % for all ROIs
                for r = 1:length(iR),
                    procROI             = DataStr.Roi{iR(r),4};                        
                    procROI             = circshift(procROI,tDelta);
                    if tDelta > 0, 
                        procROI(1:tDelta,:) = 0;
                    else
                        procROI(frameNum - tDelta+1:frameNum,:) = 0;
                    end
                    DataStr.Roi{iR(r),4}    = procROI;                   
                end
                
            end
            
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces aligned per event %s is ready.',EventName),  'I' ,0);

        end
        % ---------------------------------------------
        

        % ==========================================
        function DataStr = TraceAlignedPerRoiEventTrial(obj, RoiName, EventInds, TrialInds)
            % TraceAlignedPerRoiEventTrial - extract all the traces per Event, Rois and Trials
            % EventInds,TrialInds could be multiple index
            % Align traces according to the RoiName trace first threshold crossing
            % Input:
            %    RoiName - which ROI to show
            %    EventInds - from which Events (multiple)
            %    TrialInds - from which trial (multiple)
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, RoiName   = ''; end
            if nargin < 3, EventInds = 1;  end
            if nargin < 4, TrialInds = 1;  end
            DataStr = [];
            
                        
            roiNames        = GetRoiNames(obj);
            roiInd          = strmatch(RoiName,roiNames);
            if length(roiInd) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Roi name %s.',RoiName),  'E' ,0);
                return
            end
            
            eventNames         = GetEventNames(obj);
            eventNum            = size(eventNames,1);
            if any(EventInds < 1) || any(EventInds > eventNum),
                DTP_ManageText([], sprintf('Multi Trial : Bad Event index specified.'),  'E' ,0);
                return
            end
            
            if any(TrialInds < 1) || any(TrialInds > obj.ValidTrialNum),
                error('Trial Index %d should be in the range 1 : %d',TrialInd,obj.ValidTrialNum)
            end
            
            % find trials for selected Roi
            roiPos          = strmatch(RoiName,obj.DbROI(:,3),'exact') ;          
            %roiPos          = strmatch(RoiName,strvcat(obj.DbROI{:,3})) ;          
            trialIndRoi     = [obj.DbROI{roiPos,1}]; % all trials for specific event

            % filter by current input
            trialBoolRoi   = ismember(trialIndRoi,TrialInds);
            trialIndRoi    = trialIndRoi(trialBoolRoi);
            
            % find trials for selected ROIs
            roiPos          = [];
            for m = 1:length(EventInds),
                roiPos      = [roiPos; strmatch(roiNames(EventInds(m),:),obj.DbROI(:,3),'exact')];  
                %roiPos      = [roiPos; strmatch(roiNames(EventInds(m),:),strvcat(obj.DbROI{:,3}))];  
            end
            trialIndRoi        = [obj.DbROI{roiPos,1}];
            
            % filter by current input
            trialBoolRoi     = ismember(trialIndRoi,TrialInds);
            trialIndRoi      = trialIndRoi(trialBoolRoi);
            
            % extract data
            DataStr.Roi      = obj.DbROI(roiPos(trialBoolRoi),:);           % trial num + dFF
            DataStr.Event    = obj.DbEvent(roiPos(trialBoolRoi),:);      % name + time
            
            % start alignment
            for m = 1:length(TrialInds),
                
                % all rois related to the current trial - could be several 
                iR      = find(trialIndRoi == TrialInds(m));
                if isempty(iR), continue; end
                procROI  = DataStr.Roi{iR(1),4}; % The first one only
                frameNum = size(procROI,1);
                
                % all events related to the current trial - could be several - choose the first one
                iE      = find(trialIndRoi == TrialInds(m));
                if isempty(iE), continue; end
                iE      = iE(1); % The first one only
                tEvent  = DataStr.Event{iE,4};
                tDelta  = round(frameNum/2) - tEvent(1); % delata move to the middle
                tEvent  = tEvent + tDelta; % move to the middle
                DataStr.Event{iE,4} = tEvent;
                
                % for all ROIs
                for r = 1:length(iR),
                    procROI             = DataStr.Roi{iR(r),4};                        
                    procROI             = circshift(procROI,tDelta);
                    if tDelta > 0, 
                        procROI(1:tDelta,:) = 0;
                    else
                        procROI(frameNum - tDelta+1:frameNum,:) = 0;
                    end
                    DataStr.Roi{iR(r),4}    = procROI;                   
                end
                
            end
            
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces aligned per event %s is ready.',EventName),  'I' ,0);

        end
        % ---------------------------------------------
        
       
        % ==========================================
        function [obj, DataStr] = ComputeSpikes(obj, DataStr)
           % ComputeSpikes - detects ROI activity spikes and stores the data back 
            % Input:
            %    EventNames - which event to show cell array of strings
            % Output:
            %    obj        - image map 
            
            if nargin < 2,   error('DataStr'); end
            
            traceNum    = size(DataStr.Roi,1);
            if traceNum < 1, return; end;
            procROI     = DataStr.Roi{1,4}; % The first one only
            frameNum    = size(procROI,1);
            if frameNum < 11, return; end;
            
            % estimate mean and threshold
            frameNum10          = ceil(frameNum/10); % 10 percent
            Par                 = [];
            for k = 1:traceNum,
                
                dffData             = DataStr.Roi{k,4};  
                
                % remove trend
                alpha               = 0.9;
                startData           = repmat(mean(dffData(1:5)),100,1);
                dffDataAv           = filtfilt((1-alpha),[1 -alpha],[startData;dffData]);
                dffDataAv           = dffDataAv(101:end,:);                
                dffData             = dffData - dffDataAv;
                
                % filter and find spikes
                [Par,dffSpike]       = TPA_FastEventDetect(Par,dffData,0);                
                
                
%                 [dffS,dffI]         = sort(dffData,'ascend');
% 
%                 
%                 dffMean          = mean(dffData(dffI(1:frameNum10)));
%                 dffStd           = std(dffData(dffI(1:frameNum10)));
% 
%                 % estimate threshold and above
%                 spikeThr            = dffMean + dffStd*6 + 0.3;
%                 dffSpikeBool        = dffData > spikeThr;
% 
%                 % check if it does not starts from high - remove it
%                 if dffSpikeBool(1),
%                     for m = 1:frameNum,
%                         if ~dffSpikeBool(m), break; end;
%                         dffSpikeBool(m) = false;
%                     end
%                 end

                DataStr.Roi{k,4} = double(dffSpike);
            end

         
        end
        % ---------------------------------------------

        
        
        % ==========================================
        function obj = TestLoad(obj, testType)
            
            if nargin < 2,  testType     = 2; end;
            % TestLoad - check if the data could be loaded - working
            
            switch testType,
                case 1, % Tech
                    testImDir         = 'C:\UsersJ\Uri\Data\Imaging\m8\02_10_14\';
                    testViDir         = 'C:\UsersJ\Uri\Data\Videos\m8\02_10_14\';
                    testAnDir         = 'C:\UsersJ\Uri\Data\Analysis\m8\02_10_14\';
                case 2, % Home
                    testImDir         = 'C:\Uri\DataJ\Janelia\Imaging\M2\4_4_14\';
                    testViDir         = 'C:\Uri\DataJ\Janelia\Video\M2\4_4_14\';
                    testAnDir         = 'C:\Uri\DataJ\Janelia\Analysis\M2\4_4_14\';
                case 3, % Tech - computer new
                    testImDir         = 'C:\LabUsers\Uri\Data\Janelia\Imaging\D8\6_21_14\';
                    testViDir         = 'C:\LabUsers\Uri\Data\Janelia\Videos\D8\6_21_14\';
                    testAnDir         = 'C:\LabUsers\Uri\Data\Janelia\Analysis\D8\6_21_14\';
                otherwise 
                    error('Bad testType')
            end


            % init managers
            Par.DMT         = TPA_DataManagerTwoPhoton();
            Par.DMB         = TPA_DataManagerBehavior(); Par.DMB.DecimationFactor = [2 2 1 3];
                           
            % need to init video data since analysis name is decoded from it
            Par.DMT         = Par.DMT.SelectTwoPhotonData(testImDir);
            Par.DMT         = Par.DMT.SelectAnalysisData(testAnDir);
            Par.DMB         = Par.DMB.SelectBehaviorData(testViDir);
            Par.DMB         = Par.DMB.SelectAnalysisData(testAnDir);
            
            % init
            obj             = obj.Init(Par);

            % load
            obj              = obj.CheckDataFromTrials();
            obj              = obj.LoadDataFromTrials();
            
            
%             if ~isempty(usrData), 
%                 DTP_ManageText([], sprintf('2 OK.'), 'I' ,0)   ;
%             end;
            
         
        end
        % ---------------------------------------------
    
        % ==========================================
        function obj = TestDataExtract(obj)
            
            % TestDataExtract - try to find a search
            trialInd    = 2;
            roiName     = 'ROI: 4 Z:1 ';
            
            % init DB
            obj     = obj.TestLoad() ; 
            
            % get traces
            dataStr = obj.TracesPerTrial(trialInd);
            
            if ~isempty(dataStr), 
                DTP_ManageText([], sprintf('TracesPerTrial -  OK.'), 'I' ,0)   ;
            end;
            
            % get traces
            dataStr = obj.TracesPerRoi(roiName);
            
            if ~isempty(dataStr), 
                DTP_ManageText([], sprintf('TracesPerRoi -  OK.'), 'I' ,0)   ;
            end;
            
         
        end
        % ---------------------------------------------
        
        
    end% methods
end% classdef
