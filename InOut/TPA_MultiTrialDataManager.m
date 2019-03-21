classdef TPA_MultiTrialDataManager
    % TPA_MultiTrialDataManager - Collects Behavioral and TwoPhoton info from all the relevant trials
    % Inputs:
    %       BDA_XXX.mat, TPA_YYY.mat - data base
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 29.03 19.03.19 UD     Multiple channel support.
    % 28.15 04.07.18 UD     Patch for Shahar.
    % 28.13 11.04.18 UD     Resampling with padding after artifacts.
	% 28.12 19.03.18 UD     Fixing scaling of the behavioral events.
    % 28.04 15.01.18 UD     Fixing Ethogram show.
    % 28.03 07.01.18 UD     Lever press event support.
    % 27.10 08.11.17 UD     Averaged traces.
    % 26.05 11.07.17 UD     Adapting for Trajectories
    % 25.06 09.04.17 UD     Spike detection
    % 25.05 03.04.17 UD     Adding fluorescence
    % 25.04 19.03.17 UD     Adapting for Brightness
    % 24.08 01.11.16 UD  	Fixing Bug in Time rescaling    
    % 24.05 16.08.16 UD     Resolution is not an integer.    
    % 24.04 13.09.16 UD     protect from no df/f  
    % 23.09 29.03.16 UD     Extract all events per ROI per all trials  
    % 23.07 01.03.16 UD     DBEvent is empty protection  
    % 23.06 23.02.16 UD     Fixing bug in circshift alignment  
    % 23.03 14.02.16 UD     Spike Save support   
    % 23.02 06.02.16 UD     Adding ROI class support   
    % 22.02 12.01.16 UD     Circula shift behavior, Protect TimeConvert factors   
    % 21.22 29.12.15 UD     Changing Spike Detect interface    
    % 21.16 28.11.15 UD     Events are vectors  - need to find when active  for alignment
    % 21.14 24.11.15 UD     Remove detection of spikes
    % 21.10 17.11.15 UD     Event data taken from other channel is fixed
    % 21.08 03.11.15 UD     Support Events as class
    % 21.06 10.10.15 UD     Integrating Event Detector
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
        TPED                = [];   % two photon df/f event detector
        
        % Time rescaling 
        Behavior_Resolution  = [1 1 1 1];  % init from outside according to the 
        Behavior_Offset      = [0 0 0 0];
        TwoPhoton_Resolution = [1 1 1 1];
        TwoPhoton_Offset     = [0 0 0 0];
        TwoPhoton_FrameNum   = 0;
        TwoPhoton_SliceNum   = 0;
        
        % Spike detection management
        SpikeDataIsChanged   = false;
        
        
        
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
        
        % ==========================================
        function obj = Init(obj,Par)
            % Init - init Par structure related managers of the DB
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            
            if nargin < 2, error('Must have Par'); end;
            
            % manager copy
            obj.DMB                     = Par.DMB;
            obj.DMT                     = Par.DMT;
            obj.TPED                    = Par.TPED;%TPA_TwoPhotonEventDetect();
            obj.SpikeDataIsChanged      = false;
            
            % resolution updates
            obj.Behavior_Resolution     = Par.DMB.Resolution;
            obj.Behavior_Offset         = Par.DMB.Offset;
            obj.TwoPhoton_Resolution    = Par.DMT.Resolution;
            obj.TwoPhoton_Offset        = Par.DMT.Offset;
            obj.TwoPhoton_SliceNum      = Par.DMT.SliceNum;
            
            % Support for multiple channels
            chanNum                     = numel(Par.DMT.ChannelIndex);
            obj.TwoPhoton_SliceNum      = obj.TwoPhoton_SliceNum  * chanNum;
            
            % check
            if obj.Behavior_Resolution(4) < 1
                obj.Behavior_Resolution(4) = 1;
            end
            if obj.TwoPhoton_Resolution(4) < 1
                obj.TwoPhoton_Resolution(4) = 1;
            end
            if obj.TwoPhoton_SliceNum < 1
                obj.TwoPhoton_SliceNum = 1;
            end
            
            obj.TimeConvertFact         = (obj.Behavior_Resolution(4)/obj.TwoPhoton_Resolution(4)*obj.TwoPhoton_SliceNum);
            if obj.TimeConvertFact < 1
                errordlg('The numbers in Two Photon and Behavior Resolutions are not correct.')
                obj.TimeConvertFact = 1;
            end
            
        end
     
        % ==========================================
        function tcFact = GetTimeConvertFact(obj)
            % GetTimeConvertFact - conversion factor
            % Input:
            %    none
            % Output:
            %    tcFact     -ratio between Behavior and TwoPhoton frame rates
            
            tcFact = obj.TimeConvertFact;
        end
     
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
            if isempty(answer), return; end
            tcFact              = str2double(answer{1});
            
            if tcFact < 1 || tcFact > 16
                DTP_ManageText([], 'Frame conversion factor should be in range [1-16]', 'E' ,0)   ;
                return;
            end
            if ~isequal(tcFact, round(tcFact))
                DTP_ManageText([], 'Frame conversion factor should be an integer', 'E' ,0)   ;
                return;
            end
            
            
            obj.TimeConvertFact         = tcFact;
            obj.Behavior_Resolution(4)  = tcFact * obj.TwoPhoton_Resolution(4)*obj.TwoPhoton_SliceNum;
        end
        
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
            obj.DMT                 = obj.DMT.CheckData(true);     % important step to validate number of valid trials  
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
            if ~isprop(strROI{1},'Data')
                DTP_ManageText([], sprintf('Multi Trial : Found ROI which is old please review this trial.'),  'E' ,0);
                return    
            else
                if isempty(strROI{1}.Data),
                    DTP_ManageText([], sprintf('Multi Trial : Found ROI data but it seems like dF/F is not computed. Please run dF/F analysis.'),  'E' ,0);
                    return    
                end
            end

            IsOK = true;
            
        
        end
        
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
            if validTrialNum < 1
                DTP_ManageText([], sprintf('Multi Trial : No TwoPhoton Analysis data in directory %s. Please check the folder or run Data Check',obj.DMT.RoiDir),  'E' ,0);
                return
            end
            validTrialNumEv           = min(validTrialNum,length(obj.DMB.EventFileNames));
            if validTrialNumEv < 1
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder or run Data Check',obj.DMB.EventDir),  'E' ,0);
                %return
            else
                DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI and Events. Reading ...',validTrialNumEv),  'I' ,0);
            end
            
            
            filtH             = hamming(11);  filtH = filtH./sum(filtH);
            obj.ValidTrialNum = validTrialNum;
            obj.SpikeDataIsChanged = false;
            for trialInd = 1:validTrialNum


                    [obj.DMT, strROI]           = obj.DMT.LoadAnalysisData(trialInd,'strROI');
                    % this code helps with sequential processing of the ROIs: use old one in the new image
                    numROI                      = length(strROI);
                    if numROI < 1
                        DTP_ManageText([], sprintf('Multi Trial : There are no ROIs in trial %d. Trying to continue',trialInd),  'E' ,0);
                    end

                    % read the info
                    for rInd = 1:numROI
                        if size(strROI{rInd}.Data,2) < 2
                            DTP_ManageText([], sprintf('Multi Trial : Trial : %d, No dF/F data in ROI %s',trialInd,strROI{rInd}.Name),  'E' ,0);
                            continue;
                        end
                       obj.DbRoiRowCount                = obj.DbRoiRowCount + 1;
                       obj.DbROI{obj.DbRoiRowCount,1}   = trialInd;
                       obj.DbROI{obj.DbRoiRowCount,2}   = rInd;                   % roi num
                       obj.DbROI{obj.DbRoiRowCount,3}   = strROI{rInd}.Name;      % name 
                       obj.DbROI{obj.DbRoiRowCount,4}   = strROI{rInd}.Data(:,2); % df/f
                       % spike data is found
                       if size(strROI{rInd}.Data,2) > 2
                            obj.DbROI{obj.DbRoiRowCount,5}   = strROI{rInd}.Data(:,3);
                       else
                            obj.DbROI{obj.DbRoiRowCount,5}   = strROI{rInd}.Data(:,2)*0;
                       end
                       obj.DbROI{obj.DbRoiRowCount,6}   = strROI{rInd}.Data(:,1); % fluorescence   
                    end
                    
                    if numROI > 0
                        obj.TwoPhoton_FrameNum     = size(strROI{rInd}.Data,1);
                    end
                    if trialInd > validTrialNumEv, continue; end
                    
                    [obj.DMB, strEvent]         = obj.DMB.LoadAnalysisData(trialInd,'strEvent');
                    % this code helps with sequential processing of the ROIs: use old one in the new image
                    numEvent                    = length(strEvent);
                    if numEvent < 1
                        DTP_ManageText([], sprintf('Multi Trial : There are no events in trial %d. Trying to continue',trialInd),  'E' ,0);
                    end

                    % read the info
                    eventFrameNum                         = floor(obj.TwoPhoton_FrameNum * obj.TimeConvertFact);
                    for eInd = 1:numEvent
                       obj.DbEventRowCount                = obj.DbEventRowCount + 1;
                       obj.DbEvent{obj.DbEventRowCount,1} = trialInd;
                       obj.DbEvent{obj.DbEventRowCount,2} = eInd;                   % event num
                       obj.DbEvent{obj.DbEventRowCount,3} = strEvent{eInd}.Name;      % name 
                       if (isprop(strEvent{eInd},'Data') || isfield(strEvent{eInd},'Data')) && ~isempty(strEvent{eInd}.Data)
                            eventData                     = strEvent{eInd}.Data; % rescale time
                            eventData                     = eventData(:); % rescale time
                            % deal with data of different size
                            %dataLen                       = size(eventData,1);
                            %if dataLen > eventFrameNum, eventData = eventData(1:eventFrameNum); end
                            %if dataLen < eventFrameNum, eventData = [eventData; repmat(eventData(end),eventFrameNum-dataLen,1)]; end
                            
                            %eventData                     = strEvent{eInd}.Data(:,2); % rescale time
                       else
                            eventData                      = zeros(eventFrameNum,1); % NEED to know frameNum
                            % support Jaaba import - old style
                            if (isprop(strEvent{eInd},'TimeInd') || isfield(strEvent{eInd},'TimeInd')) && ~isempty(strEvent{eInd}.TimeInd)                           
                                eventData(strEvent{eInd}.TimeInd(1):strEvent{eInd}.TimeInd(2)) = 3;
                            % support Import of events from Lever press
                            elseif isprop(strEvent{eInd},'tInd') && ~isempty(strEvent{eInd}.tInd) && (strEvent{eInd}.tInd(end) <= eventFrameNum)                         
                                eventData(strEvent{eInd}.tInd(1):strEvent{eInd}.tInd(2)) = 3;
                            end
                       end
                       dataLen                            = size(eventData,1);
                       if dataLen > 10 
					       padLen 			 = ceil(dataLen./obj.TwoPhoton_FrameNum*5);
						   eventDataPad      = [repmat(eventData(1),padLen,1); double(eventData); repmat(eventData(end),padLen,1)];
                           eventData         = filtfilt(filtH,1,double(eventData)); % extend
                           eventData         = resample(eventData,obj.TwoPhoton_FrameNum,dataLen); 
						   eventData         = eventData(6:end-5);
                       end
                       obj.DbEvent{obj.DbEventRowCount,4} = eventData; % rescale time
                       % seq num support
                       seqNum = 1;
                       if (isprop(strEvent{eInd},'SeqNum') || isfield(strEvent{eInd},'SeqNum')), 
                           seqNum = strEvent{eInd}.SeqNum; 
                       end
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
        
        % ==========================================
        function obj = SaveDataFromTrials(obj)
        % Save Data back to Files
            if nargin < 1, error('Need one argument'); end;
            %if ~isfield(dataStr,'Roi'), error('Must be a structure'); end
        
            % computed spike data
            dbROI                   = obj.DbROI;

            % resolve interface
            validTrialNum           = length(obj.DMT.RoiFileNames);
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No TwoPhoton Analysis data in directory %s. Please check the folder or run Data Check',obj.DMT.RoiDir),  'E' ,0);
                return
            end
            trialIndLoad            = unique([dbROI{:,1}]);
            trialNum                = min(validTrialNum,numel(trialIndLoad));
            
            % Write data back
            for mm = 1:trialNum,
                
                    trialInd = trialIndLoad(mm);
                
                    [obj.DMT, strROI]    = obj.DMT.LoadAnalysisData(trialInd,'strROI');
                    roiNum  = length(strROI);
                    if roiNum < 1,
                        DTP_ManageText([], sprintf('Multi Trial : No ROIs in trial %d',trialInd),  'W' ,0);
                        continue;
                    end
                    selecteInd  = find([dbROI{:,1}] == trialInd);
                    for k = 1:numel(selecteInd),
                        roiInd         = dbROI{selecteInd(k),2}; 
                        if roiInd < 1 || roiInd > roiNum,
                            DTP_ManageText([], sprintf('Multi Trial : Something terrible wrong 911 : %d',roiInd),  'W' ,0);
                            continue;
                        end
                        spikeData      = dbROI{selecteInd(k),5};
                       if numel(spikeData) ~= size(strROI{roiInd}.Data(:,2)),
                            DTP_ManageText([], sprintf('Multi Trial : Spike and dFF length missmatch: %d',roiInd),  'W' ,0);
                            continue;
                        end
                        strROI{roiInd}.Data(:,3) = spikeData;
                    end
                    obj.DMT     = obj.DMT.SaveAnalysisData(trialInd,'strROI',strROI);

            end

            DTP_ManageText([], sprintf('Multi Trial : Spike data is saved to files'),  'I' ,0);

        end
 
        % ==========================================
        function obj = UpdateDatabaseFromSelection(obj, dataStr)
        % UpdateDatabaseFromSelection Save Spike Data back to database
            if nargin < 2, error('Need second argument'); end;
            if ~isfield(dataStr,'Roi'), error('Must be a structure'); end
        
            % computed spike data
            dbROI                   = dataStr.Roi;
            recordNum               = size(dbROI,1);
            if recordNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No dta in the current selection.'),  'W' ,0);
                return
            end

            % resolve interface
            trialIndDB              = [obj.DbROI{:,1}];
            roiIndDB                = [obj.DbROI{:,2}];
            
            % Write data back
            for m = 1:recordNum,

                trialInd    = dbROI{m,1};
                roiInd      = dbROI{m,2};
                spikeData   = dbROI{m,5};

                selecteInd  = find(trialIndDB == trialInd & roiIndDB == roiInd);
                if numel(selecteInd) ~= 1,
                    error('Some problem with data selection')
                end
                selecteInd = selecteInd(1);

                 if numel(spikeData) ~= size(obj.DbROI{selecteInd,4}),
                        DTP_ManageText([], sprintf('Multi Trial : Spike and dFF length missmatch: %d',roiInd),  'W' ,0);
                        continue;
                 end
                 obj.DbROI{selecteInd,5} = spikeData;

            end

            DTP_ManageText([], sprintf('Multi Trial : Spike data is saved to Data manager DB'),  'I' ,0);

        end
        
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
            DataStr.Roi = [];
            DataStr.Event = [];
            
            % find trial
            if isempty(obj.DbROI), return; end;
            trialBool       = [obj.DbROI{:,1}] == TrialInd;
            DataStr.Roi     = obj.DbROI(trialBool,:);      % name + dFF
            if isempty(obj.DbEvent), return; end;
            trialBool       = [obj.DbEvent{:,1}] == TrialInd;
            DataStr.Event   = obj.DbEvent(trialBool,:);      % name + dFF


            DTP_ManageText([], sprintf('Multi Trial : Extraction of trial %d Ready.',TrialInd),  'I' ,0);

        end
        
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
            
            eventNamesAll     = GetEventNames(obj);
            eventInd          = strcmp(eventNamesAll,EventName);
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
        
        % ==========================================
        function DataStr = EventEthogram(obj, EventNames)
            % EventEthogram - extract all the Events per each trial - build ethogram 
            % Input:
            %    EventNames - list of events to show
            %    TrialInds - from which trial
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, EventNames = {''}; end
            DataStr = [];
            %EventName         = deblank(EventName);
            
            eventNamesAll     = GetEventNames(obj);
            % for colors
            %mapObj            = containers.Map(eventNamesAll,1:obj.UniqueEventNum);
            
            eventNum          = length(EventNames);
            orderCodes        = {'Lift',2;'Grab',3;'AtMouth',4;'Chew',5;'Table',1;'Back',6};
            dbEvents          = {}; orderWeight = [];
            for m = 1:eventNum
                
                dataStr       = TrialsPerEvent(obj, EventNames{m});
                if isempty(dataStr),continue; end
                trialInd        = [dataStr.Event{:,1}];
                for k = 1:size(orderCodes,1)
                    if startsWith(EventNames{m},orderCodes{k,1},'IgnoreCase',true)
                         trialInd = trialInd*10 + orderCodes{k,2};
                    end
                end
                orderWeight   = cat(1,orderWeight,trialInd(:));
                dbEvents      = cat(1,dbEvents,dataStr.Event);
                
            end
            % group by trials
            %trialInds               = [dbEvents{:,1}];
            %[trialIndSort,ia,ic]    = unique(trialInds);
            [trialIndSort,ia]       = sort(orderWeight, 'ascend');
            % ia contains unique indeces
            dbE                     = dbEvents(ia,:);
            
            % clean up data and encode color
            colorCodes              = {'Lift',2;'Grab',3;'AtMouth',4;'Chew',5;'Table',5;'Back',7;'event',8};
            for m = 1:size(dbE,1)
                
                nameEvent           = dbE{m,3};
                dataEvent           = dbE{m,4};
                dataBool            = dataEvent > 0.2; 
                %dataEvent(~dataBool)= 1; % background
                for k = 1:size(colorCodes,1)
                    if startsWith(nameEvent,colorCodes{k,1},'IgnoreCase',true)
                        dataEvent(dataBool)= colorCodes{k,2};
                    end
                end
                dbE{m,4}            = dataEvent;
            end
            
            %cnts                    = ia*0;
%             for k = 1:numel(trialIndSort),
%                dbE{k,3} = '';          % name
%                dbE{k,4} = dbE{k,4}*0;  % data
%                ii       = find(trialIndSort(k) == trialInds);
% %                if trialIndSort(k)==32,
% %                    disp('dbg')
% %                end
%                
%                for m = 1:numel(ii),
%                    dbE{k,3}    = strcat(dbE{k,3},dbEvents{ii(m),3},':');
%                    b           = dbEvents{ii(m),4}>0.4;
%                    eId         = mapObj(dbEvents{ii(m),3});
%                    dbE{k,4}(b) = eId;
%                end
%             end
                
                
            
            % find trials for selected Event
            %eventPos        = strmatch(EventName,obj.DbEvent(:,3),'exact') ; %strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %eventPos        = strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %trialInd        = [obj.DbEvent{eventPos,1}]; % all trials for specific event
            
            %roiInd          = ismember([obj.DbROI{:,1}],trialInd);    
            DataStr.Roi     = []; %obj.DbROI(roiInd,:);      % trial num + dFF
            DataStr.Event   = dbE; %obj.DbEvent(eventPos(:),:);      % name + time
            DTP_ManageText([], sprintf('Multi Trial : Extraction of trials per event %s is ready.',EventNames{1}),  'I' ,0);

        end
        
        % ==========================================
        function DataStr = TracesPerRoiEventEthogram(obj, RoiName, EventNames)
            % TracesPerRoiEventEthogram - extract all the Events per each trial - build ethogram 
            % Extract all traces per ROI
            % Input:
            %    RoiName    - single ROI
            %    EventNames - list of events to show
            %    TrialInds - from which trial
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, EventNames = {''}; end
            DataStr = [];
            %EventName         = deblank(EventName);
            roiNames        = GetRoiNames(obj);
            roiInd         = strmatch(RoiName,roiNames);
            if length(roiInd) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Roi name %s.',RoiName),  'E' ,0);
                return
            end
            
            % find trials for selected ROI
            roiPos          = strmatch(RoiName,obj.DbROI(:,3),'exact') ;          
            %roiPos          = strmatch(RoiName,strvcat(obj.DbROI{:,3})) ;          
            
            
            eventNamesAll     = GetEventNames(obj);
            % for colors
            mapObj            = containers.Map(eventNamesAll,1:obj.UniqueEventNum);
            
            eventNum          = length(EventNames);
            dbEvents          = {};
            for k = 1:eventNum,

                dataStr       = TrialsPerEvent(obj, EventNames{k});
                if isempty(dataStr),continue; end;
                dbEvents      = cat(1,dbEvents,dataStr.Event);
                
            end
            % group by trials
            trialInds               = [dbEvents{:,1}];
            [trialIndSort,ia,ic]    = unique(trialInds);
            % ia contains unique indeces
            dbE                     = dbEvents(ia,:);
            %cnts                    = ia*0;
%             for k = 1:numel(trialIndSort),
%                dbE{k,3} = '';          % name
%                dbE{k,4} = dbE{k,4}*0;  % data
%                ii       = find(trialIndSort(k) == trialInds);
% %                if trialIndSort(k)==32,
% %                    disp('dbg')
% %                end
%                
%                for m = 1:numel(ii),
%                    dbE{k,3}    = strcat(dbE{k,3},dbEvents{ii(m),3},':');
%                    b           = dbEvents{ii(m),4}>0.4;
%                    eId         = mapObj(dbEvents{ii(m),3});
%                    dbE{k,4}(b) = eId;
%                end
%            end
                
                
            
            % find trials for selected Event
            %eventPos        = strmatch(EventName,obj.DbEvent(:,3),'exact') ; %strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %eventPos        = strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %trialInd        = [obj.DbEvent{eventPos,1}]; % all trials for specific event
            
            %roiInd          = ismember([obj.DbROI{:,1}],trialInd);    
            DataStr.Roi     = obj.DbROI(roiPos,:);      % trial num + dFF
            DataStr.Event   = dbE; %obj.DbEvent(eventPos(:),:);      % name + time
            DTP_ManageText([], sprintf('Multi Trial : Extraction of trials per roi %s and event %s is ready.',RoiName,EventNames{1}),  'I' ,0);

        end
        
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
            %DTP_ManageText([], sprintf('Multi Trial : Extraction of traces per event %s is ready.',EventName),  'I' ,0);

        end
          
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
            %DTP_ManageText([], sprintf('Multi Trial : Extraction of traces per event %s is ready.',EventName),  'I' ,0);

        end

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
                % check if a vector : new event format
                if numel(tEvent) > 2,  activeEventInd = find(tEvent>0.1); end;
                if numel(tEvent) == 2, % old format
                    activeEventInd = tEvent(1);  tEvent = zeros(frameNum,1) ; tEvent(activeEventInd) = 1;
                end;
                if isempty(activeEventInd),
                    DTP_ManageText([], sprintf('Multi Trial : Event %s Problem.',EventName),  'E' ,0);
                    continue;
                end
                tDelta  = round(frameNum/2) - activeEventInd(1); % delata move to the middle
                tEvent  = circshift(tEvent, tDelta); % move to the middle
                DataStr.Event{iE,4} = tEvent;
                
                % for all ROIs
                for r = 1:length(iR),
                    procROI             = DataStr.Roi{iR(r),4};                        
                    procROI             = circshift(procROI,tDelta);
                    if tDelta > 0, 
                        procROI(1:tDelta,:) = 0;
                    else
                        procROI(frameNum + tDelta+1:frameNum,:) = 0;
                    end
                    DataStr.Roi{iR(r),4}    = procROI;                   
                end
                
            end
            
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces aligned per event %s is ready.',EventName),  'I' ,0);

        end

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
                        procROI(frameNum + tDelta+1:frameNum,:) = 0;
                    end
                    DataStr.Roi{iR(r),4}    = procROI;                   
                end
                
            end
            
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces aligned per event %s is ready.',EventName),  'I' ,0);

        end
       
        % ==========================================
        function DataStr = TraceAveragedPerEventRoiTrial(obj, EventName, RoiInds, TrialInds)
            % TraceAveragedPerEventRoiTrial - extract all the traces per Event, Rois and Trials
            % ROIs,Trial could be multiple index
            % Average over traces 
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
            DataStr           = [];
            
            % checks
            eventNames        = GetEventNames(obj);
            eventNum          = size(eventNames,1);
            eventInd          = strmatch(EventName,eventNames);
            if length(eventInd) < 1
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
            
            % prepare matrix of traces
            %traceRoiTrialData = nan(obj.TwoPhoton_FrameNum,roiNum,obj.ValidTrialNum);
            
            % find trials for selected Event
            eventPos        =  strmatch(EventName,obj.DbEvent(:,3),'exact') ; %strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %eventPos        = strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            trialIndEvent   = [obj.DbEvent{eventPos,1}]; % all trials for specific event

            % filter by current trial input
            trialBoolEvent   = ismember(trialIndEvent,TrialInds);
            trialIndEvent    = trialIndEvent(trialBoolEvent);
            
            % find trials for selected ROIs and average them
            roiStr          = cell(0,4);
            for m = 1:length(RoiInds)
                % get roi positions
                roiPos          = strmatch(roiNames(RoiInds(m),:),obj.DbROI(:,3),'exact');  
               % trials for this ROI 
               trialIndRoi        = [obj.DbROI{roiPos,1}];
            
               % filter by current input
               trialBoolRoi      = ismember(trialIndRoi,trialIndEvent);
               trialInd          = find(trialBoolRoi);
               trialIndNum       = length(trialInd);
               if trialIndNum < 1, continue; end
               
               % save the data
               pointerInd        = size(roiStr,1)+1;
               oneTimeInit       = true;
               for p = 1:trialIndNum
                   roiInd        = roiPos(trialInd(p));
                   if oneTimeInit 
                       roiStr{pointerInd,1}  = obj.DbROI{roiInd,1};
                       roiStr{pointerInd,2}  = obj.DbROI{roiInd,2};
                       roiStr{pointerInd,3}  = sprintf('%s - A',obj.DbROI{roiInd,3});
                       roiStr{pointerInd,4}  = obj.DbROI{roiInd,4}*0;
                       oneTimeInit           = false;
                   end
                   roiStr{pointerInd,4} = roiStr{pointerInd,4} + obj.DbROI{roiInd,4};
                   
               end
               roiStr{pointerInd,4} = roiStr{pointerInd,4}./trialIndNum;
             end
           
            % find events for selected Events and ROIs and average them
            eventStr          = cell(0,4);
            eventNum          = 1; % only one event
            for m = 1:eventNum
                % get roi positions
               eventPos          = strmatch(EventName,obj.DbEvent(:,3),'exact');  
               % trials for this ROI 
               trialInd          = [obj.DbEvent{eventPos,1}];
            
               % filter by current input
               trialBool         = ismember(trialInd,trialIndEvent);
               trialInd          = find(trialBool);
               trialIndNum       = length(trialInd);
               if trialIndNum < 1, continue; end
               
               % save the data
               pointerInd        = size(eventStr,1)+1;
               oneTimeInit       = true;
               for p = 1:trialIndNum
                   roiInd        = eventPos(trialInd(p));
                   if oneTimeInit 
                       eventStr{pointerInd,1}  = obj.DbEvent{roiInd,1};
                       eventStr{pointerInd,2}  = obj.DbEvent{roiInd,2};
                       eventStr{pointerInd,3}  = sprintf('%s - A',obj.DbEvent{roiInd,3});
                       eventStr{pointerInd,4}  = obj.DbEvent{roiInd,4}*0;
                       oneTimeInit           = false;
                   end
                   eventStr{pointerInd,4} = eventStr{pointerInd,4} + obj.DbEvent{roiInd,4};
                   
               end
               eventStr{pointerInd,4} = eventStr{pointerInd,4}./trialIndNum;
             end
           

            
            % extract data
            DataStr.Roi      = roiStr;           % trial num + dFF
            DataStr.Event    = eventStr;      % name + time
            
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces averaged per event %s is ready.',EventName),  'I' ,0);

        end
        
       % ==========================================
       % PATCH for Shahar
        function DataStr = TraceAveragedPerEventRoiTrialShahar(obj, EventName, RoiInds, TrialInds, EventInds)
            % TraceAveragedPerEventRoiTrialShahar - extract all the traces per Event, Rois and Trials - PATCH
            % ROIs,Trial could be multiple index
            % Average over traces 
            % Input:
            %    EventName - which event to show
            %    RoiInds   - from which ROI (multiple)
            %    TrialInds - from which trial (multiple)
            %    EventInds - event indexes
            % Output:
            %    DataStr.RoiNames       - list of names
            %    DataStr.RoiTraces      - list of names
            %    DataStr.EventNames     - list of names
            %    DataStr.EventTraces    - list of names
            
            if nargin < 2, EventName = ''; end
            if nargin < 3, RoiInds   = 1;  end
            if nargin < 4, TrialInds = 1;  end
            if nargin < 5, EventInds = [];  end
            DataStr           = [];
            
            % checks
            eventNames        = GetEventNames(obj);
            eventNum          = size(eventNames,1);
            eventInd          = strmatch(EventName,eventNames);
            if length(eventInd) < 1
                DTP_ManageText([], sprintf('Multi Trial : Can not find Event name %s.',EventName),  'E' ,0);
                return
            end
            if isempty(EventInds), EventInds = 1:eventNum; end
            if any(EventInds < 1) || any(EventInds > eventNum)
                error('Event Index %d should be in the range 1 : %d',EventInds,eventNum)
            end
            eventNames        = eventNames(EventInds);
            eventNum          = size(eventNames,1);
            
            
            roiNames        = GetRoiNames(obj);
            roiNum          = size(roiNames,1);
            if any(RoiInds < 1) || any(RoiInds > roiNum),
                DTP_ManageText([], sprintf('Multi Trial : Bad Roi index specified.'),  'E' ,0);
                return
            end
            
            if any(TrialInds < 1) || any(TrialInds > obj.ValidTrialNum)
                error('Trial Index %d should be in the range 1 : %d',TrialInds,obj.ValidTrialNum)
            end
            
            
            % find trials for selected Event
            eventPos        =  strmatch(EventName,obj.DbEvent(:,3),'exact') ; %strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            %eventPos        = strmatch(EventName,strvcat(obj.DbEvent{:,3})) ;          
            trialIndEvent   = [obj.DbEvent{eventPos,1}]; % all trials for specific event

            % filter by current trial input
            trialBoolEvent   = ismember(trialIndEvent,TrialInds);
            trialIndEvent    = trialIndEvent(trialBoolEvent);
            trialIndNumAll   = length(trialIndEvent);
            
            % find trials for selected ROIs and average them
            roiStr          = cell(0,4);
            for m = 1:length(RoiInds)
                % get roi positions
                roiPos          = strmatch(roiNames(RoiInds(m),:),obj.DbROI(:,3),'exact');  
               % trials for this ROI 
               trialIndRoi        = [obj.DbROI{roiPos,1}];
            
               % filter by current input
               trialBoolRoi      = ismember(trialIndRoi,trialIndEvent);
               trialInd          = find(trialBoolRoi);
               trialIndNum       = length(trialInd);
               if trialIndNum < 1, continue; end
               
               % save the data
               pointerInd        = size(roiStr,1)+1;
               oneTimeInit       = true;
               for p = 1:trialIndNum
                   roiInd        = roiPos(trialInd(p));
                   if oneTimeInit 
                       roiStr{pointerInd,1}  = obj.DbROI{roiInd,1};
                       roiStr{pointerInd,2}  = obj.DbROI{roiInd,2};
                       roiStr{pointerInd,3}  = sprintf('%s - A',obj.DbROI{roiInd,3});
                       roiStr{pointerInd,4}  = obj.DbROI{roiInd,4}*0;
                       oneTimeInit           = false;
                   end
                   roiStr{pointerInd,4} = roiStr{pointerInd,4} + obj.DbROI{roiInd,4};
                   
               end
               roiStr{pointerInd,4} = roiStr{pointerInd,4}./trialIndNum;
             end
           
            % find events for selected Events and ROIs and average them
            eventStr          = cell(0,4);
            for m = 1:eventNum
                % get roi positions
                eventPos          = strmatch(eventNames(m,:),obj.DbEvent(:,3),'exact');  
               % trials for this ROI 
               trialInd          = [obj.DbEvent{eventPos,1}];
            
               % filter by current input
               trialBool         = ismember(trialInd,trialIndEvent);
               trialInd          = find(trialBool);
               trialIndNum       = length(trialInd);
               if trialIndNum < 1, continue; end
               
               % save the data
               pointerInd        = size(eventStr,1)+1;
               oneTimeInit       = true;
               for p = 1:trialIndNum
                   roiInd        = eventPos(trialInd(p));
                   if oneTimeInit 
                       eventStr{pointerInd,1}  = obj.DbEvent{roiInd,1};
                       eventStr{pointerInd,2}  = obj.DbEvent{roiInd,2};
                       eventStr{pointerInd,3}  = sprintf('%s - A',obj.DbEvent{roiInd,3});
                       eventStr{pointerInd,4}  = obj.DbEvent{roiInd,4}*0;
                       oneTimeInit           = false;
                   end
                   eventStr{pointerInd,4} = eventStr{pointerInd,4} + obj.DbEvent{roiInd,4};
                   
               end
               eventStr{pointerInd,4} = eventStr{pointerInd,4}./trialIndNumAll; %trialIndNum;
            end
           
             
%             % 
%             stat            = xlswrite(saveFileName,columnNames,       'TwoPhoton','A1');
%             stat            = xlswrite(saveFileName,columnData,        'TwoPhoton','A2');
%             stat            = xlswrite(saveFileName,{'Average'},       'TwoPhotonAverage','A1');
%             stat            = xlswrite(saveFileName,meanTrace,         'TwoPhotonAverage','A2');


            
            % extract data
            DataStr.Roi      = roiStr;           % trial num + dFF
            DataStr.Event    = eventStr;      % name + time
            
            DTP_ManageText([], sprintf('Multi Trial : Extraction of traces averaged per event %s is ready.',EventName),  'I' ,0);

        end
         
        
        % ==========================================
        function [obj, DataSpike, DataStr] = ComputeSpikes(obj, DataStr, FigNum)
           % ComputeSpikes - detects ROI activity spikes and stores the data back 
            % Input:
            %    DataStr    - structure of ROIs or Roi cell array 
            % Output:
            %    DataSpike  - array of detected spike data 
            
            if nargin < 2,   error('DataStr'); end
            if nargin < 3,   FigNum = 0; end
            DataSpike   = [];
            
            % resolve interface
            if isa(DataStr,'struct')
                traceNum    = size(DataStr.Roi,1);
                if traceNum < 1, return; end;
                procROI     = DataStr.Roi{1,4}; % The first one only
                frameNum    = size(procROI,1);
                if frameNum < 11, return; end;
                
                dffDataAll   = zeros(frameNum,traceNum);
                for k = 1:traceNum,
                    dffDataAll(:,k) = DataStr.Roi{k,4};
                end
            elseif isa(DataStr,'numeric'),
                dffDataAll      = DataStr;
                traceNum        = size(dffDataAll,2);
                frameNum        = size(dffDataAll,1);
            else
                error('Unresolved dataStr')
            end
            % estimate of spikes
            DataSpike           = zeros(frameNum,traceNum);
            
            if ~obj.SpikeDataIsChanged, % take the old data
                
                for k = 1:traceNum, 
                    DataSpike(:,k) = DataStr.Roi{k,5};
                end
                
            else

                %Par                 = [];
                for k = 1:traceNum,

                    dffData             = dffDataAll(:,k);  
%                     % remove trend
%                     alpha               = 0.9;
%                     startData           = repmat(mean(dffData(1:15)),100,1);
%                     dffDataAv           = filtfilt((1-alpha),[1 -alpha],[startData;dffData]);
%                     dffDataAv           = dffDataAv(101:end,:);                
%                     dffData             = dffData - dffDataAv*0;

                    % filter and find spikes
                    %[Par,dffSpike]       = TPA_FastEventDetect(Par,dffData,0);                
                    %[obj.TPED,dffSpike]       = FastEventDetect(obj.TPED,dffData,0);                
                    %[obj.TPED,dffSpike]       = SlowEventDetect(obj.TPED,dffData,0);                
                    [obj.TPED,dffSpike]       = ManualEventDetect(obj.TPED,dffData,0);                

                    % save
                    DataSpike(:,k)      = double(dffSpike);

                end

            end

            % output
            for k = 1:traceNum,
                if isa(DataStr,'struct'),
                        DataStr.Roi{k,5}    = DataSpike(:,k);
                else
                        DataStr(:,k)        = DataSpike(:,k);
                end
            end
            
            if FigNum < 1, return; end;
            
            % show spikes and data
            tt          = (1:frameNum)';
            maxRange    = 4;
            figure(FigNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
            for k = 1:traceNum,
                plot(tt,dffDataAll(:,k)     + (k)*maxRange,'color','y'); hold on
                plot(tt,DataSpike(:,k)      + (k)*maxRange,'color','r',  'linestyle','-.');
                plot(tt([1 end]),[0 0]      + (k)*maxRange,'color','w',  'linestyle','--');
                if k == 1, legend('Trace','Spikes'); end
                %plot(tt,ones(nT,1)                          + namePos(k)*maxRange,'color',[1 1 1]*0.6,'linestyle',':');
                text(10,(k)*maxRange,num2str(k),'color','y')
            end
            hold off
            ylabel('dF/F (Increamental)'),xlabel('Frame Num')
            title(sprintf('dF/F and Detected Spikes'), 'interpreter','none'),
            

         
        end
        
    end
    
    % Test
    methods
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
        
        
    end% methods
end% classdef
