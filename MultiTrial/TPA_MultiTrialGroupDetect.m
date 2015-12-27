classdef TPA_MultiTrialGroupDetect
    % TPA_MultiTrialGroupDetect - Collects Behavioral and TwoPhoton info and finds ROI groups
    % using different techniques.
    % Inputs:
    %       BDA_XXX.mat, TPA_YYY.mat - data base
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 21.18 01.12.15 UD     Adding order matrix and more PSTH
    % 21.14 24.11.15 UD     More order graphs
    % 21.10 17.11.15 UD     Support new event structure
    % 19.30 07.05.15 UD     Delay map with time filtering
    % 19.22 12.02.15 UD     Delay map is created
    % 19.11 16.10.14 UD     Created
    %-----------------------------
    
    properties
        

        % copy of the containers with file info
        MngrData            = [];   % db manager
        FrameRange          = [0 100]; % for user to remember
               
        IsAligned           = false;   % align events or not
        
        % dff related
        DffThr              = 0.5;          % threshold of dff
        
        
    end % properties
    properties (SetAccess = private)
        %TimeConvertFact     = 1;           % time conversion >= 1 between behav - fast and twophoton - slow
        %TimeEventAligned    = false;        % if the events has been time aligned
    end

    methods
        
        % ==========================================
        function obj = TPA_MultiTrialGroupDetect()
            % TPA_MultiTrialGroupDetect - constructor
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
            
            if nargin < 1, error('Must have Par'); end;
            
            % manager copy
%             obj.DMB                     = Par.DMB;
%             obj.DMT                     = Par.DMT;
            % Init Data manager
            obj.MngrData                = TPA_MultiTrialDataManager();
            obj.MngrData                = obj.MngrData.Init(Par);
            
        end
        
        % ==========================================
        function EventName = SelectEvent(obj,EventName)
            % SelectEvent - selects event from DB or performs manual selection
            % Input:
            %    EventName        - name to select
            % Output:
            %    EventName   - manual selection
            
            if nargin < 2, EventName = ''; end; % manual selection
            
            if ~isempty(EventName), return; end;
        
            % select Events to Show
            eventNames = obj.MngrData.UniqueEventNames;
            [s,ok] = listdlg('PromptString','Select Event :','ListString',eventNames,'SelectionMode','single');
            if ~ok, return; end;

            % do analysis
            EventName = eventNames{s};
            
        end

        % ==========================================
        function [obj, frameRange] = SelectFrameRange(obj, frameRange)
            % SelectFrameRange - selects frame range for filtering
            if nargin < 2, frameRange = obj.FrameRange; end;
            
            % of the ROI spike events
            isOK                  = false; % support next level function
            options.Resize        ='on';
            options.WindowStyle   ='modal';
            options.Interpreter   ='none';
            prompt                = {'ROI Spike Event Start and Stop [Two Photon Frame Numbers]',...            
                                    };
            name                ='Add New Event to all trials:';
            numlines            = 1;
            defaultanswer       ={num2str(frameRange)};
            answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
            if isempty(answer), return; end;


            % try to configure
            frameRange          = str2num(answer{1});

            % check
            if numel(frameRange) ~= 2,
                errordlg('You must provide two frame numbers for event start and stop')
                return
            end
            frameRange(1)       = max(-500,min(1000,frameRange(1)));          
            frameRange(2)       = max(-500,min(1000,frameRange(2)));          
            obj.FrameRange      = frameRange;
        
        end
        
        % ==========================================
        function obj = LoadData(obj) 
           % LoadData - check and load data about ROIs and Events
            % Input:
            %    MngrData - created by MultiTrialDataManager
            % Output:
            %    obj   - updated 
            

            % checks
            [obj.MngrData,IsOK] = obj.MngrData.CheckDataFromTrials();
            if ~IsOK, return; end
            obj.MngrData        = obj.MngrData.LoadDataFromTrials();

            % init frame range
            obj.FrameRange      = [-10 obj.MngrData.TwoPhoton_FrameNum];
            
            

        end
        
        % ==========================================
        function [obj, DataStr] = TraceTablePerRoiEvent(obj,RoiName,EventName,IsAligned) 
           % TraceRoiTablePerEvent - creates big table of all ROI and traces per specified event
            % Input:
            %    MngrData - created by MultiTrialDataManager
            %    RoiName  - name of the ROI
            %    EventName - which event to find
            %    IsAligned - true if you want to align time
            % Output:
            %    obj   - updated 
            %    DataStr   - object with fields for analysis of traces
            
             if nargin < 2, RoiName = ''; end;
             if nargin < 3, EventName = ''; end;
             if nargin < 4, IsAligned = obj.IsAligned; end;
             
             DataStr = [];
             obj.IsAligned         = IsAligned;
             
             %obj                    = LoadData(obj) ;
             
            roiNames                = GetRoiNames(obj.MngrData);
            roiIndex                = strmatch(RoiName,roiNames);
            if length(roiIndex) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Roi name %s.',RoiName),  'E' ,0);
                return
            end             
           
             % all trials
             trialIndex             = 1:obj.MngrData.ValidTrialNum;
             %roiIndex               = 1:obj.MngrData.UniqueRoiNum;
                        
             if obj.IsAligned,
                dataStrTmp          = obj.MngrData.TraceAlignedPerEventRoiTrial(EventName,roiIndex,trialIndex);
             else
                dataStrTmp          = obj.MngrData.TracePerEventRoiTrial(EventName,roiIndex,trialIndex);
             end
             
             % assemble into matrix
            dbROI               = dataStrTmp.Roi ;
            dbEvent             = dataStrTmp.Event ;
            if isempty(dbROI),
                DTP_ManageText([], sprintf('Multi Trial : No ROI data found for this selection.'),  'W' ,0);
                return
            end
            DataStr             = dataStrTmp ;
            

        end
 
        % ==========================================
        function [obj, DataStr] = OldTraceTablePerRoiEvent(obj,RoiName,EventName,IsAligned) 
           % TraceRoiTablePerEvent - creates big table of all ROI and traces per specified event
            % Input:
            %    MngrData - created by MultiTrialDataManager
            %    RoiName  - name of the ROI
            %    EventName - which event to find
            %    IsAligned - true if you want to align time
            % Output:
            %    obj   - updated 
            %    DataStr   - object with fields for analysis of traces
            
             if nargin < 2, RoiName = ''; end;
             if nargin < 3, EventName = ''; end;
             if nargin < 4, obj.IsAligned = false; end;
             
             DataStr = [];
             
             %obj                    = LoadData(obj) ;
             
            roiNames                = GetRoiNames(obj.MngrData);
            roiIndex                = strmatch(RoiName,roiNames);
            if length(roiIndex) < 1,
                DTP_ManageText([], sprintf('Multi Trial : Can not find Roi name %s.',RoiName),  'E' ,0);
                return
            end             
           
             % all trials
             trialIndex             = 1:obj.MngrData.ValidTrialNum;
             %roiIndex               = 1:obj.MngrData.UniqueRoiNum;
                        
             if obj.IsAligned,
                dataStrTmp          = obj.MngrData.TraceAlignedPerEventRoiTrial(EventName,roiIndex,trialIndex);
             else
                dataStrTmp          = obj.MngrData.TracePerEventRoiTrial(EventName,roiIndex,trialIndex);
             end
             
             % assemble into matrix
            dbROI               = dataStrTmp.Roi ;
            dbEvent             = dataStrTmp.Event ;
            if isempty(dbROI),
                DTP_ManageText([], sprintf('Multi Trial : No ROI data found for this selection.'),  'W' ,0);
                return
            end
            frameNum            = size(dbROI{1,4},1);
            traceNum            = size(dbROI,1);
        
            % Set dF/F data container
            dffDataArray        = zeros(frameNum,traceNum);
            % Set container for time events
            eventTimeArray      = zeros(2,traceNum);
            for m = 1:traceNum,
                dffDataArray(:,m)   = dbROI{m,4};
                ii = find(dbEvent{m,4}>0,1,'first');
                if isempty(ii), continue; end;
                eventTimeArray(1,m) = ii;    
                eventTimeArray(2,m) = find(dbEvent{m,4}>0,1,'last');    
            end      
            
            % save
            DataStr.EventName   = EventName;
            DataStr.RoiName     = RoiName;
            DataStr.DffData     = dffDataArray;
            DataStr.EventTime   = eventTimeArray;
            DataStr.TraceInd    = [dbROI{:,1}];

        end
         
       % ==========================================
        function obj = ListMostActiveRoiPerEvent(obj, EventNames)
           % ListMostActiveRoiPerEvent - prints the list of ROIs that most active per given event 
           % measured by number of time Trace is above the threshold
            % Input:
            %    EventNames - which event to show cell array of strings
            % Output:
            %    obj        - list of events 
            
            if nargin < 2,   EventNames    = ''; end
            eventNames    = SelectEvent(obj,EventNames);
            
            % params
            figNum       = 11;
            
            % check against all ROIs
            %eventNames    = EventNames;
            eventNum      = length(eventNames);
            if eventNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to supply event as cell array of strings.'), 'E' ,0)   ;
                 return
            end
            roiNames      = obj.MngrData.UniqueRoiNames;
            roiNum        = length(roiNames);
            if roiNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to initialize the database. Call obj.Init'), 'E' ,0)   ;
                 return
            end
            % assume init has been done
            
            % start analysis
            scoreEventRoi           = zeros(eventNum,roiNum); % keep the scores
            dataStrAll              = cell(eventNum,roiNum);
            
            % select traces per roi and event and compute score
            %obj                         = LoadData(obj);
            for eId = 1:eventNum,
                for rId = 1:roiNum,
                    [obj,dataStr]   = OldTraceTablePerRoiEvent(obj,roiNames{rId},eventNames{eId});  
                    if isempty(dataStr),continue; end;
                    
                    scoreTmp                = sum(mean(dataStr.DffData > obj.DffThr,1));
                    scoreEventRoi(eId,rId)  = scoreEventRoi(eId,rId) + scoreTmp;
                    
                    % store for the results
                    dataStrAll{eId,rId}    = dataStr;
                    
                end
            end
            
            % sort
            [sV,sI] = sort(scoreEventRoi,2,'descend');
            maxShow = min(7,roiNum); % show the best number
            
            % show the best winners
            %obj                         = LoadData(obj);
            for eId = 1:eventNum,
                for rBestId = 1:maxShow,
                    rId                  = sI(eId,rBestId);
                    dataStr              = dataStrAll{eId,rId};  
                    DTP_ManageText([],sprintf('Best %d : Event : %s, Roi : %s',rBestId,dataStr.EventName,dataStr.RoiName),'I' ,0) ;
                    
                    figNumTmp            = 0; %roiNum*eId + rId + figNum;
                    obj                  = ShowOneGroup(obj, dataStr, figNumTmp);                      
                end
            end
            
            % show all scores
            figure(figNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
            imagesc(scoreEventRoi),colormap(hot),colorbar;
            %xlabel('Roi [#]'),
            ylabel('Event [#]'),title(sprintf('Activity Scores above dff thr : %4.3f',obj.DffThr))
            oldticksX       = get(gca,'xtick');
            oldticklabels   = roiNames(oldticksX); % cellstr(get(gca,'xtickLabel'));
            set(gca,'xticklabel',[])
            text(oldticksX, zeros(size(oldticksX))+eventNum+.5, oldticklabels, 'rotation',-45,'horizontalalignment','left','fontsize',8,'interpreter','none')            
            set(gca,'ytick',1:eventNum,'yticklabel',eventNames)
         
        end

        % ==========================================
        function obj = ListEarlyLateOntimeRoiPerEvent(obj, EventNames)
           % ListEarlyLateOntimeRoiPerEvent - prints the list of ROIs that active before/late or on time per given event 
           % Measured by number of time Trace is above the threshold before/after event time
            % Input:
            %    EventNames - which event to show cell array of strings
            % Output:
            %    obj        - list of events 
            
            if nargin < 2,   EventNames    = ''; end
            eventNames    = SelectEvent(obj,EventNames);
            
            % params
            figNum       = 11;
            
            % check against all ROIs
            %eventNames    = EventNames;
            eventNum      = length(eventNames);
            if eventNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to supply event as cell array of strings.'), 'E' ,0)   ;
                 return
            end
            eventNum       = 1; % use only one
            
            roiNames      = obj.MngrData.UniqueRoiNames;
            roiNum        = length(roiNames);
            if roiNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to initialize the database. Call obj.Init'), 'E' ,0)   ;
                 return
            end
            % assume init has been done
            
            % start analysis
            scoreEventRoi           = zeros(eventNum*3,roiNum); % keep the scores for 3 positions
            dataStrAll              = cell(eventNum,roiNum);
            
            % select traces per roi and event and compute score
            frameLen                = 40; % Two Photon 1 sec frame number
            %obj                         = LoadData(obj);
            for eId = 1:eventNum,
                for rId = 1:roiNum,
                    [obj,dataStr]           = OldTraceTablePerRoiEvent(obj,roiNames{rId},eventNames{eId});  
                    if isempty(dataStr),continue; end;
                    
                    % get event time
                    startFrame              = dataStr.EventTime(1,:);  
                    [frameNum,trialNum]     = size(dataStr.DffData);
                    OnTimeStartFrame        = max(1,startFrame - frameLen);
                    OnTimeStopFrame         = min(frameNum,startFrame + frameLen);
                    
                    % check
                    if any(OnTimeStartFrame > frameNum),
                        DTP_ManageText([],sprintf('Group : Event frame number exceeds TwoPhoton : Did you forget to specify Frame rate for Video? '),'E' ,0) ;
                        return;
                    end
                        
                        
                    
                    % define 3 regions
                    activeBool              = dataStr.DffData > obj.DffThr;
                    for m = 1:trialNum,
                        scoreEventRoi(eId+0,rId) = scoreEventRoi(eId+0,rId) + mean(activeBool(1:OnTimeStartFrame(m),m),1);
                        scoreEventRoi(eId+1,rId) = scoreEventRoi(eId+1,rId) + mean(activeBool(OnTimeStartFrame(m):OnTimeStopFrame(m),m),1);
                        scoreEventRoi(eId+2,rId) = scoreEventRoi(eId+2,rId) + mean(activeBool(OnTimeStopFrame(m):end,m),1);
                    end
                    
                    % store for the results
                    dataStrAll{eId,rId}    = dataStr;
                    
                end
            end
            
            % sort
            [sV,sI] = sort(scoreEventRoi,2,'descend');
            maxShow = min(7,roiNum); % show the best number
            
            % show the best winners
            %obj                         = LoadData(obj);
            for eId = 1:eventNum,
                for rBestId = 1:maxShow,
                     
                    rId                  = sI(eId,rBestId);
                    figNumTmp            = 0; %1 + rId * 3 + figNum;
                    dataStr              = dataStrAll{eId,rId}; 
                    DTP_ManageText([],sprintf('Best %d : Early : Event : %s, Roi : %s',rBestId,dataStr.EventName,dataStr.RoiName),'I' ,0) ;
                    
                    dataStr.EventName    = sprintf('%s - Early',dataStr.EventName);
                    obj                  = ShowOneGroup(obj, dataStr, figNumTmp);                      
                    rId                  = sI(eId+1,rBestId);
                    figNumTmp            = 0; %2 + rId * 3 + figNum;
                    dataStr              = dataStrAll{eId,rId}; 
                    DTP_ManageText([],sprintf('Best %d : OnTime: Event : %s, Roi : %s',rBestId,dataStr.EventName,dataStr.RoiName),'I' ,0) ;
                    
                    dataStr.EventName    = sprintf('%s - On Time',dataStr.EventName);
                    obj                  = ShowOneGroup(obj, dataStr, figNumTmp);  
                    rId                  = sI(eId+2,rBestId);
                    figNumTmp            = 0; %3 + rId * 3 + figNum;
                    dataStr              = dataStrAll{eId,rId}; 
                    DTP_ManageText([],sprintf('Best %d : Late  : Event : %s, Roi : %s',rBestId,dataStr.EventName,dataStr.RoiName),'I' ,0) ;
                    
                    dataStr.EventName    = sprintf('%s - Late',dataStr.EventName);
                    obj                  = ShowOneGroup(obj, dataStr, figNumTmp);      
                    
                end
            end
            
            % show all scores
            figure(figNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
            imagesc(scoreEventRoi),colormap(hot),colorbar; 
            %xlabel('Roi [#]'),
            ylabel('ROI Activity Scores'),title(sprintf('Activity Scores above dff thr %4.3f for Event %s ',obj.DffThr,eventNames{1}))

            % mark ROIs
            oldticksX       = get(gca,'xtick');
            oldticklabels   = roiNames(oldticksX); % cellstr(get(gca,'xtickLabel'));
            set(gca,'xticklabel',[])
            text(oldticksX, zeros(size(oldticksX))+3.5, oldticklabels, 'rotation',-45,'horizontalalignment','left','fontsize',8,'interpreter','none')            
            set(gca,'ytick',1:3,'yticklabel',{'Early','OnTime','Late'})
            
         
        end
        
        % ==========================================
        function [obj, SpikeData] = OldDetectSpikes(obj, DffData)
           % DetectSpikes - detects ROI activity spikes and stores the data 
            % Input:
            %    EventNames - which event to show cell array of strings
            % Output:
            %    obj        - image map 
            
            if nargin < 2,   error('DffData'); end
            SpikeData    = [];
            [frameNum,trialNum]     = size(DffData);
            if trialNum < 1 || frameNum < 11, return; end;
            
            SpikeData           = zeros(1,trialNum);
            
            % estimate mean and threshold
            [dffS,dffI]         = sort(DffData,'ascend');
            frameNum10          = ceil(frameNum/10); % 10 percent
            dffMean             = zeros(1,trialNum);
            dffStd              = zeros(1,trialNum);
            for k = 1:trialNum,
                dffMean(k)          = mean(DffData(dffI(1:frameNum10,k),k));
                dffStd(k)           = std(DffData(dffI(1:frameNum10,k),k));

                % estimate threshold and above
                spikeThr            = obj.DffThr; %dffMean(k) + dffStd(k)*4 + 0.1;
                dffSpikeBool        = DffData(:,k) > spikeThr;

                % check if it does not starts from high - remove it
                if dffSpikeBool(1),
                    for m = 1:frameNum,
                        if ~dffSpikeBool(m), break; end;
                        dffSpikeBool(m) = false;
                    end
                end

                % first time start
                ii                  = find(dffSpikeBool,1,'first');
                if isempty(ii), continue; end;
                SpikeData(k) = ii;
            end

         
        end

        % ==========================================
        function [obj, DelayMap] = ComputeDelayMapPerEvent(obj, EventNames, FrameRange)
           % ComputeDelayMapPerEvent - detects ROI activity and shows all active ROIs for all trials
           % delay betwen first activation time and fiven given event 
            % Input:
            %    EventNames - which event to show cell array of strings
            % Output:
            %    DelayMap   - image map 
            
            if nargin < 2,   EventNames    = 'Grabm2 - 1'; end
            if nargin < 3,   FrameRange    = [1 obj.MngrData.TwoPhoton_FrameNum]; end;

            
            % params
            figNum        = 21;
            DelayMap      = [];
            frameRange    = FrameRange;
            
            % check against all ROIs
            eventNames    = EventNames;
            eventNum      = length(eventNames);
            if eventNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to supply event as cell array of strings.'), 'E' ,0)   ;
                 return
            end
            eventNum       = 1; % use only one
            %eId            = 1; % event id
            
            roiNames      = obj.MngrData.UniqueRoiNames;
            roiNum        = length(roiNames);
            if roiNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to initialize the database. Call obj.Init'), 'E' ,0)   ;
                 return
            end
            % assume init has been done
            trialNum                = obj.MngrData.ValidTrialNum;
            frameNum                = 1;
            
            % ask fort frame range  
            %[obj, frameRange]       = SelectFrameRange(obj, frameRange);
            
            
            % start analysis
            delayMapTrialRoi        = nan(trialNum,roiNum);
            
            % detect first time events
            %for eId = 1:eventNum,
            for rId = 1:roiNum,
                [obj,dataStr]           = TraceTablePerRoiEvent(obj,roiNames{rId},eventNames);  
                if isempty(dataStr),continue; end;
                
                
                % detect spikes
                %[obj, spikeData]        = DetectSpikes(obj, dataStr.DffData);                

                % get event time
                traceInd                = [dataStr.Roi{:,1}];
                frameNum                = size(dataStr.Roi{1,4},1);
                traceNum                = size(dataStr.Roi,1);
                
                % event start time
                if size(dataStr.Event,1) ~= traceNum,
                    DTP_ManageText([], sprintf('Group : ROI and Event number mnissmatch. Requires debug.'), 'E' ,0)   ;                    
                    continue;
                end
                
                
        
                % Set dF/F data container
                %dffDataArray        = zeros(frameNum,traceNum);
                % Set container for time events
                eventTimeArray      = zeros(2,traceNum);
                for m = 1:traceNum,
                    %dffDataArray(:,m)   = dbROI{m,4};
                    % support continuous functions
                    eventData           = dataStr.Event{m,4};
                    iid                 = find(eventData > 0); 
                    if isempty(iid),    iid = [10 frameNum]; end; % 10 - strt at some point
                    eventTimeArray(1,m) = iid(1);    
                    eventTimeArray(2,m) = iid(end);    
                end   
                startFrame              = eventTimeArray(1,:);
                %startFrame              = zeros(1,traceNum);
                
                
                % new way
                [obj.MngrData, dataStr] = ComputeSpikes(obj.MngrData, dataStr);     
                
                % find first events
                spikeData               = nan(1,traceNum);
                for m = 1:traceNum,
                    % transitions from 0 to 1
                    spikeTrace          = dataStr.Roi{m,4} > 0;
                    indOnset            = find(spikeTrace(1:end-1) == 0 & spikeTrace(2:end) == 1);
                    ii                  = find(indOnset >= frameRange(1) & indOnset <= frameRange(2),1,'first');
                    if isempty(ii), continue; end;
                    spikeData(m)        = indOnset(ii);    
                end                  
                % assign
                delayData               = spikeData -  startFrame; 
                delayMapTrialRoi(traceInd,rId) = delayData(:);
                

            end
            %end
            
            DelayMap        = delayMapTrialRoi;
            
         
        end
        
        % ==========================================
        function [obj, DelayMap] = ShowDelayMapPerEvent(obj, EventNames)
           % ShowDelayMapPerEvent - detects ROI activity and shows all active ROIs for all trials
           % delay betwen first activation time and fiven given event 
            % Input:
            %    EventNames - which event to show cell array of strings
            % Output:
            %    obj        - image map 
            
            if nargin < 2,   EventNames    = ''; end
            eventName    = SelectEvent(obj,EventNames);
            
            % params
            figNum        = 21;
            DelayMap      = [];
            
            % check against all ROIs
            %eventNames    = EventNames;
            eventNum      = length(eventName);
            if eventNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to supply event as cell array of strings.'), 'E' ,0)   ;
                 return
            end
            eventNum       = 1; % use only one
            eId            = 1; % event id
            
            roiNames      = obj.MngrData.UniqueRoiNames;
            roiNum        = length(roiNames);
            if roiNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to initialize the database. Call obj.Init'), 'E' ,0)   ;
                 return
            end
            % assume init has been done
            trialNum                = obj.MngrData.ValidTrialNum;
            frameNum                = 1;
            
            % ask fort frame range  
            [obj, frameRange]       = SelectFrameRange(obj);
            
            % compute           
            [obj, delayMapTrialRoi] = ComputeDelayMapPerEvent(obj, eventName, frameRange);
            
            %end
            % design colormap
%             if frameNum < 5, 
%                 cmap    = hot(8); 
%             else
            coolLen = -min(-1,min(delayMapTrialRoi(:)));
            hotLen  = max(1,max(delayMapTrialRoi(:))); %frameNum - coolLen;
            lenSum  = (coolLen + hotLen);
            % map Nan to red
            delayMapTrialRoi(isnan(delayMapTrialRoi)) = -(coolLen + 1);
            coolLen = ceil(coolLen./lenSum*128);
            hotLen  = ceil(hotLen./lenSum*128);
            cmapH   = hot(hotLen);cmapC = bone(coolLen);
            %cmapH   = summer(hotLen);cmapC = winter(coolLen);
            %cmapH   = jet(hotLen);cmapC = jet(coolLen);
            %cmap    = [cmapC(end:-1:1,:);[0 0 0];cmapH];
            %cmap    = [cmapC;[0 0 0];cmapH(end:-1:1,:)];
            cmap    = [[0.5 0.5 0.5];cmapC(end:-1:1,:);[0 0 0];cmapH];
            %cmap    = [[1 0 0];cmapC;[1 1 1];cmapH(end:-1:1,:)];
            %cmap    = [cmapH;[0 0 0];cmapC(end:-1:1,:)];
            %cmap    = jet(64);
            clims    = [-(coolLen + 1) hotLen];
 %           end
            
            % show all scores
            %imageRGB    = ind2rgb(delayMapTrialRoi + coolLen,cmap);
            figure(figNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
            %imagesc(delayMapTrialRoi,'CDataMapping','direct'),colormap(cmap);colorbar;
            %imagesc(delayMapTrialRoi,[-coolLen hotLen]),colormap('default');colorbar;
            imagesc(delayMapTrialRoi',clims),colormap(cmap);colorbar;
            axis xy; % to match view in multri-trial
            %imagesc(imageRGB),colorbar;
            %xlabel('Roi [#]'),
            xlabel('Trials'),
            title(sprintf('Frame Delay for First ROI Spike in range [%d:%d] from Event %s ',frameRange(1),frameRange(2),eventName))
            
%             % mark ROIs
%             oldticksX       = get(gca,'xtick');
%             oldticklabels   = roiNames(oldticksX); % cellstr(get(gca,'xtickLabel'));
%             set(gca,'xticklabel',[])
%             text(oldticksX, zeros(size(oldticksX)), oldticklabels, 'rotation',-45,'horizontalalignment','left','fontsize',8,'interpreter','none')            

            % mark ROIs
            decimFactor     = ceil(length(roiNames)./10);
            showInd         = 1:decimFactor:length(roiNames);
            oldticklabels   = roiNames(showInd); % cellstr(get(gca,'xtickLabel'));
            set(gca,'yticklabel',oldticklabels,'ytick',showInd)
            %text(oldticksX, zeros(size(oldticksX)), oldticklabels, 'rotation',-45,'horizontalalignment','left','fontsize',8,'interpreter','none')            
            
         
        end
        
        % ==========================================
        function obj = ShowHistMapPerEvent(obj, DoOrder, EventNames)
           % ShowHistMapPerEvent - detects ROI activity and shows all active ROIs for all trials on one axis
           % delay betwen first activation time and fiven given event 
            % Input:
            %    DoOrder    - present this map in certain order
            %    EventNames - which event to show cell array of strings
            % Output:
            %    obj        - image map 
            
            if nargin < 2,   DoOrder       = false; end
            if nargin < 3,   EventNames    = ''; end
            
            % params
            figNum       = 21;
            
            eventName    = SelectEvent(obj,EventNames);
            
            
            % check against all ROIs
            %eventNames    = EventNames;
            eventNum      = length(eventName);
            if eventNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to supply event as cell array of strings.'), 'E' ,0)   ;
                 return
            end
            eventNum       = 1; % use only one
            eId            = 1; % event id
            
            roiNames      = obj.MngrData.UniqueRoiNames;
            roiNum        = length(roiNames);
            if roiNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to initialize the database. Call obj.Init'), 'E' ,0)   ;
                 return
            end
            % assume init has been done
%             trialNum                = obj.MngrData.ValidTrialNum;
%             frameNum                = 1;
            
            % ask fort frame range  
            %frameRange              = [-100 obj.MngrData.TwoPhoton_FrameNum];
            %[obj, frameRange]       = SelectFrameRange(obj, frameRange);
            [obj, frameRange]       = SelectFrameRange(obj);
            
            % compute           
            [obj, delayMapTrialRoi] = ComputeDelayMapPerEvent(obj, eventName, frameRange);
            %delayMapTrialRoi        = delayMapTrialRoi; %+ frameRange(1);
            
            %  compute hist
            %histBins                = frameRange(1):frameRange(end);
            minV                    = min(delayMapTrialRoi(~isnan(delayMapTrialRoi)));
            maxV                    = max(delayMapTrialRoi(~isnan(delayMapTrialRoi)));
            histBins                = linspace(minV-5,maxV+5,64);
            binsRoiMap              = zeros(numel(histBins),roiNum);
            for m = 1:roiNum,
                cnts                = hist(delayMapTrialRoi(:,m),histBins);
                binsRoiMap(:,m)     = cnts(:);
            end
            
            % order the display
            if DoOrder,
                centerOfMassDelay   = histBins*binsRoiMap ./ (sum(binsRoiMap)+eps);
                [sortV,sortInd]     = sort(centerOfMassDelay,'ascend');
                sortName            = 'Ordered';
            else
                sortInd             = 1:roiNum;
                sortName            = '';
            end
            

            
            % show all scores
            %imageRGB    = ind2rgb(delayMapTrialRoi + coolLen,cmap);
            figure,set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
            %imagesc(delayMapTrialRoi,'CDataMapping','direct'),colormap(cmap);colorbar;
            %imagesc(delayMapTrialRoi,[-coolLen hotLen]),colormap('default');colorbar;
            %imagesc(binsRoiMap,clim),colormap(cmap);colorbar;
            imagesc(histBins,1:roiNum,binsRoiMap(:,sortInd)');colormap(jet);colorbar;
            if DoOrder,
            hold on;
            plot(sortV,1:roiNum,'color',[1 1 1]*.5,'LineWidth',4);
            hold off;
            end
            %axis xy; % to match view in multri-trial
            %imagesc(imageRGB),colorbar;
            %xlabel('Roi [#]'),
            xlabel('Difference Between Event and First Spike [Frame Numbers]'),
            title(sprintf('%s Delay Histogram for First ROI Spike in range [%d:%d] from Event %s ',sortName,frameRange(1),frameRange(2),eventName))
%             
%             % mark ROIs
%             oldticksY       = get(gca,'ytick');
%             oldticklabels   = roiNames(oldticksY); % cellstr(get(gca,'xtickLabel'));
%             set(gca,'yticklabel',[])
%             text(zeros(size(oldticksY))+frameRange(1)-10, oldticksY , oldticklabels, 'rotation',0,'horizontalalignment','left','fontsize',8,'interpreter','none')            

            % mark ROIs
            decimFactor     = ceil(length(roiNames)./10);
            showInd         = 1:roiNum; %1:decimFactor:roiNum;
            oldticklabels   = roiNames(sortInd); % cellstr(get(gca,'xtickLabel'));
            set(gca,'yticklabel',oldticklabels,'ytick',showInd)

            DTP_ManageText([], sprintf('Group : Spike Order Graph is computed'), 'I' ,0)   ;

        end
        
        % ==========================================
        function obj = ShowSpikeOrderMatrx(obj, EventNames)
           % ShowSpikeOrderMatrx - shows cross ROI dF/F order matrix for all trials 
            % Input:
            %    EventNames - which event to show cell array of strings
            % Output:
            %    obj        - image map 
            
            if nargin < 2,   EventNames    = ''; end
            
            % params
            figNum       = 41;
            eventName    = SelectEvent(obj,EventNames);
            
            
            % check against all ROIs
            %eventNames    = EventNames;
            eventNum      = length(eventName);
            if eventNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to supply event as cell array of strings.'), 'E' ,0)   ;
                 return
            end
            
            roiNames      = obj.MngrData.UniqueRoiNames;
            roiNum        = length(roiNames);
            if roiNum < 1,
                 DTP_ManageText([], sprintf('Group : You need to initialize the database. Call obj.Init'), 'E' ,0)   ;
                 return
            end
            % ask fort frame range  
            [obj, frameRange]       = SelectFrameRange(obj);
            
            % compute           
            [obj, delayMapTrialRoi] = ComputeDelayMapPerEvent(obj, eventName, frameRange);
            
            %  compute order map
            countBins               = nan(roiNum,roiNum);
            %trialNum                = size(delayMapTrialRoi,1);
            for m = 1:roiNum, % from
                fromDelay = delayMapTrialRoi(:,m);
                for n = 1:roiNum,
                    toDelay     = delayMapTrialRoi(:,n);
                    isValid     = ~isnan(fromDelay) & ~isnan(toDelay);
                    if ~any(isValid), continue; end;
                    countBins(m,n) = sum(fromDelay(isValid) >= toDelay(isValid));
                end
            end
            
            

            
            % show all scores
            %imageRGB    = ind2rgb(delayMapTrialRoi + coolLen,cmap);
            figure,set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
            imagesc(1:roiNum,1:roiNum,countBins);colormap(jet);colorbar;
            title(sprintf('Relative Order Histogram (Row after Columns) in range [%d:%d] from Event %s ',frameRange(1),frameRange(2),eventName))
            % mark ROIs
            decimFactor     = ceil(length(roiNames)./10);
            showInd         = 1:decimFactor:roiNum;
            oldticklabels   = roiNames(showInd); % cellstr(get(gca,'xtickLabel'));
            set(gca,'yticklabel',oldticklabels,'ytick',showInd)
            set(gca,'xticklabel',oldticklabels,'xtick',showInd)

            DTP_ManageText([], sprintf('Group : Relative Spike Order Count Matrix is computed'), 'I' ,0)   ;

        end
        
        
        % ==========================================
        function obj = ShowOneGroup(obj, DataStr, figNum)
            % ShowOneGroup - shows single group data
             if nargin < 2, DataStr = []; end;
             if figNum < 3, figNum = 10; end;
             
             % check
             if figNum < 1, return; end;
             if ~isfield(DataStr,'DffData'), 
                DTP_ManageText([], sprintf('Multi Trial : Show Fails - no DffData.'),  'E' ,0);
                return
             end
             [frameNum,traceNum]   = size(DataStr.DffData);
             dffData               = bsxfun(@plus,DataStr.DffData,(0:traceNum-1));
             
             figure(figNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
             plot(dffData),axis tight;
             title(sprintf('Trace Dff for group Event : %s, Roi : %s',DataStr.EventName,DataStr.RoiName))
             xlabel('Frame [#]'),ylabel('dF/F')
         
        end
        
        % ==========================================
        function obj = TestOneGroup(obj,testType )
            % TestOneGroup - load data and extracts one group per event and roi
            if nargin <2, testType = 1; end;
            
            switch  testType
                case {1,2}
                    eventName    = 'Grabm2 - 1';
                    roiName      = 'ROI: 4 Z:1';
                case 3,
                    eventName    = 'Atmouthd8:01';
                    roiName      = 'ROI: 1 Z:1';
                otherwise
                    error('Bad testType')
            end
            
            isAligned    = false;
            
            % bypass init : load a database
            obj.MngrData                = TPA_MultiTrialDataManager();
            obj.MngrData                = obj.MngrData.TestLoad(3);
            
            % select traces per roi and event
            %obj                         = LoadData(obj);
            [obj, dataStr]              = TraceTablePerRoiEvent(obj,roiName,eventName,isAligned);    
            
            obj                         = ShowOneGroup(obj, dataStr, 11);            
            
            if ~isempty(dataStr), 
                DTP_ManageText([], sprintf('TracesPerEventRoi -  OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TracesPerEventRoi -  Fail.'), 'E' ,0)   ;
            end;
         
        end
        
        % ==========================================
        function obj = TestManyGroups(obj)
            % TestManyGroups - load data and extracts one group per event and roi in the list
            
            eventNames    = {'Grabm2 - 1','Liftm2 - 1','Atmouthm2 - 1'};
            roiNames      = {'ROI: 4 Z:1','ROI:14 Z:1','ROI:24 Z:1'};
            isAligned    = false;
            
            % bypass init : load a database
            obj.MngrData                = TPA_MultiTrialDataManager();
            obj.MngrData                = obj.MngrData.TestLoad();
            
            % select traces per roi and event
            %obj                         = LoadData(obj);
            for eId = 1:length(eventNames),
                for rId = 1:length(roiNames)
                    [obj, dataStr]              = TraceTablePerRoiEvent(obj,roiNames{rId},eventNames{eId},isAligned);  
                    figNum                      = length(roiNames)*eId + rId;
                    obj                         = ShowOneGroup(obj, dataStr, figNum);  
                    
                    if ~isempty(dataStr), 
                        DTP_ManageText([], sprintf('TracesPerEventRoi : %s, %s -  OK.',eventNames{eId},roiNames{rId}), 'I' ,0)   ;
                    else
                        DTP_ManageText([], sprintf('TracesPerEventRoi : %s, %s -  Fail.',eventNames{eId},roiNames{rId}), 'E' ,0)   ;
                    end;
                    
                end
            end
            
         
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestMostActivePerEvent(obj)
            % TestMostActivePerEvent - ltest most active rois per event
            
            eventNames    = {'Grabm2 - 1','Liftm2 - 1','Liftm2 - 2','Atmouthm2 - 1', 'Handopenm2 - 1','Supm2 - 1'};
            
            % bypass init : load a database
            obj.MngrData                = TPA_MultiTrialDataManager();
            obj.MngrData                = obj.MngrData.TestLoad();
            
            % select traces per roi and event
            obj                         = ListMostActiveRoiPerEvent(obj, eventNames);         
         
        end
        % ---------------------------------------------
        
       


    end % methods

end    % EOF..
