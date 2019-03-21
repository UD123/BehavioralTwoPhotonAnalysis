classdef TPA_MultiTrialEventManager
    % TPA_MultiTrialEventManager - loads Event data from all trials.
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 28.03 07.01.18 UD     Removing TimeInd field - make event class manager .
    % 27.07 29.10.17 UD     Fixing height of the event.
    % 25.11 10.05.17 UD     Adding more functionality.
    % 21.04 25.08.15 UD     Complete delet event.
    % 19.32 12.05.15 UD     Add events per specific trial.
    % 19.28 21.04.15 UD     Complex event assignment cretaed.
    %-----------------------------
    
    
    properties
        
        
        %
        MngrData        % data manager of the events and ROIs
        
        RoiLast         % event to be added/initialized
        
        TrialInd        % which trial should be updated
        
        QueryData       % table that contains query data
        
        % GUI
        hFig            % figure for query gen
        hEventTable     % table handles
        
        
    end % properties
    properties (SetAccess = private)
    end
    
    methods
        
        % ==========================================
        function obj = TPA_MultiTrialEventManager()
            % TPA_MultiTrialEventManager - constructor
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            
            %obj = InitRoiLast(obj);
            
            
        end
        
        % ==========================================
        function obj = LoadDataFromTrials(obj,Par)
            % LoadDataFromTrials - loads all the availabl info
            % Input:
            %     Par - header properties
            % Output:
            %     obj - updated structure
            
            % Init Data manager
            mngrData        = TPA_MultiTrialDataManager();
            mngrData        = mngrData.Init(Par);
            
            % checks
            [mngrData,IsOK] = mngrData.CheckDataFromTrials();
            if ~IsOK, return; end
            mngrData        = mngrData.LoadDataFromTrials();
            
            obj.MngrData    = mngrData;
            
        end
        
        % ==========================================
        function [obj,isOK] = InitRoiLast(obj)
            % InitRoiLast - Init ROI info
            % Input:
            %     - none
            % Output:
            %     obj - updated structure
            %     isOK - if success
            
            isOK                  = false; % support next level function
            
            roiLast             = TPA_EventManager();
            
            % prepare ROI prototype
            roiLast.Type        = 1; % ROI_TYPES.RECT should be
            roiLast.Active      = false;       % designates if this structure is in use
            roiLast.NameShow    = false;       % manage show name
            roiLast.zInd        = 1;           % location in Z stack
            %roiLast.tInd        = 1;           % location in T stack
            pos                 = [1 50 10 100];
            xy                  = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
            roiLast.Position    = pos;
            roiLast.xyInd       = xy;          % shape in xy plane
            roiLast.Name        = 'New';
            roiLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
            roiLast.SeqNum      = 1;           % designates Event number
            roiLast.Color       = [0 1 0];           % designates Event color
            
            % Setup & Get important parameters for event
            options.Resize      = 'on';
            options.WindowStyle = 'modal';
            options.Interpreter = 'none';
            prompt                = {'Event Name',...
                'Event Start and Duration [Video Frame Numbers]',...
                };
            name                = 'Add New Event:';
            numlines            = 1;
            defaultanswer       = {'Tone',num2str([100 50])};
            answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
            if isempty(answer), return; end;
            
            
            % try to configure
            newEventName        = answer{1};
            newEventFrameNum    = str2num(answer{2});
            
            % check
            if numel(newEventFrameNum) ~= 2,
                errordlg('You must provide two frame numbers for event start and duration')
                return
            end
            
            % prepare ROI prototype
            pos                     = [newEventFrameNum(1) 50 newEventFrameNum(2) 100];
            xy                      = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
            roiLast.Active      = true;
            roiLast.Position    = pos;
            roiLast.xyInd       = xy;          % shape in xy plane
            roiLast.Name        = newEventName;
            roiLast.TimeInd     = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
            
            % save
            obj.RoiLast         = roiLast;
            isOK                = true; % support next level function
            
        end
        
        % ==========================================
        function obj = AssignRoiLast(obj)
            % AssignRoiLast - assigns ROI last to all events in the range
            % Input:
            %     - none
            % Output:
            %     obj - updated structure
            
            % check that ROI has been touched
            roiLast             = obj.RoiLast;
            if ~isa(roiLast,'TPA_EventManager'),
                DTP_ManageText([], sprintf('Multi Trial : ROI last  is not updated.'),  'E' ,0);
                return
            end
            
            if isempty(obj.TrialInd),
                DTP_ManageText([], sprintf('Multi Trial : trial index is not specified.'),  'E' ,0);
                return
            end
            
            % Run over all files/trials and load the Analysis data
            for trialInd = obj.TrialInd,
                
                [obj.MngrData.DMB, strEvent]         = obj.MngrData.DMB.LoadAnalysisData(trialInd,'strEvent');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                numEvent                            = length(strEvent);
                strEvent{numEvent + 1}              = roiLast;
                
                obj.MngrData.DMB                     = obj.MngrData.DMB.SaveAnalysisData(trialInd,'strEvent',strEvent);
                
                
            end
            DTP_ManageText([], sprintf('Multi Trial : New Event assignment completed.'),  'I' ,0);
            
            
            
        end
        
        % ==========================================
        function obj = CreateConstantEventForAllTrials(obj)
            % CreateConstantEventForTrials - sets the new event defined by user to all trials
            % Input:
            %     obj - current structure
            % Output:
            %     obj - updated structure
            
            % check if initialized
            if isempty(obj.MngrData), error('MngrData must be init first');  end;
            
            % Load Trials
            validTrialNum       = length(obj.MngrData.DMB.EventFileNames);
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder. ',obj.MngrData.DMB.EventDir),  'E' ,0);
                return;
            end
            
            % define ROI params
            [obj,isOK]          = InitRoiLast(obj);
            if ~isOK,
                DTP_ManageText([], sprintf('Multi Trial : User selected cancel. '),  'W' ,0);
                return;
            end
            
            % do assignment
            obj.TrialInd        = 1:validTrialNum;
            obj                 = AssignRoiLast(obj);
            
            
        end
        
        % ==========================================
        function obj = RemoveEventFromAllTrials(obj)
            % RemoveEventFromTrials - removes an  event selected by user from all trials
            % Input:
            %     obj - current structure
            %     Par - data
            % Output:
            %     obj - updated structure
            
            
            % check if initialized
            if isempty(obj.MngrData),
                error('MngrData must be init first')
            end
            
            eventNames      = obj.MngrData.GetEventNames();
            % select Event to remove
            [s,ok] = listdlg('PromptString','Select Event to Remove :','ListString',eventNames,'SelectionMode','single');
            if ~ok, return; end;
            
            % get all trials
            eventNameDel    = eventNames{s};
            dataStr         = TrialsPerEvent(obj.MngrData, eventNameDel);
            
            % detect all trials with the event
            trialInds        = [dataStr.Event(:,1)];
            
            % check Trials
            validTrialNum      = length(trialInds);
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data for event %s. Please check the data. ',eventNameDel),  'E' ,0);
            else
                DTP_ManageText([], sprintf('Multi Trial : Found %d trials with event %s. ',validTrialNum,eventNameDel),  'I' ,0);
            end
            
            
            % Run over all files/trials and load the Analysis data
            for m = 1:validTrialNum,
                
                trialInd                            = trialInds{m};
                
                [obj.MngrData.DMB, strEvent]         = obj.MngrData.DMB.LoadAnalysisData(trialInd,'strEvent');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                numEvent                            = length(strEvent);
                deleteInd                           = [];
                for k = 1:numEvent,
                    if strcmp(strEvent{k}.Name,eventNameDel),
                        deleteInd = [deleteInd k];
                    end;
                end
                strEvent(deleteInd)                 = [];
                obj.MngrData.DMB                     = obj.MngrData.DMB.SaveAnalysisData(trialInd,'strEvent',strEvent);
                
                
            end
            DTP_ManageText([], sprintf('Multi Trial : Event %s is removed from %d trials.',eventNameDel,validTrialNum),  'I' ,0);
            
            
        end
        
        % ==========================================
        function [obj,Par] = CreateComplexEventForAllTrials(obj,Par)
            % CreateCmplexEventForAllTrials - creates new complex event defined by user to all trials
            % Input:
            %     obj - current structure
            %     Par - contains event info
            % Output:
            %     obj - updated structure
            %     Par - updated structure
            
            
            if nargin < 2, error('Need Par'); end;
            
            % int Manager
            obj             = LoadDataFromTrials(obj,Par);
            eventNames      = mngrData.GetEventNames();
            % select Events to Show
            eventNames = {'Lift-Grab1-AtMouth','Lift-Grab1-Grab2'};
            [s,ok] = listdlg('PromptString','Select Event :','ListString',eventNames,'SelectionMode','single');
            if ~ok, return; end;
            
            dataStr = TrialsPerEvent(obj.MngrData, 'Lift1');
            ind1    = [dataStr.Event(:,1)];
            dataStr = TrialsPerEvent(obj.MngrData, 'Grab1');
            ind2    = [dataStr.Event(:,1)];
            switch s,
                case 1,
                    dataStr = TrialsPerEvent(obj, 'AtMouth1');
                    ind3    = [dataStr.Event(:,1)];
                case 2,
                    dataStr = TrialsPerEvent(obj, 'Grab2');
                    ind3    = [dataStr.Event(:,1)];
            end
            
            ind         = intersect(ind1,ind2);
            ind         = intersect(ind,ind3);
            
            % try to configure
            validTrialNum        = length(ind);
            
            % check
            if validTrialNum < 1,
                errordlg('Can not find any trial with specified option %s',eventNames{s})
                return
            end
            
            roiLast             = TPA_EventManager();
            
            
            % prepare ROI prototype
            roiLast.Type        = 1; % ROI_TYPES.RECT should be
            roiLast.Active      = true;   % designates if this pointer structure is in use
            roiLast.NameShow    = false;       % manage show name
            roiLast.zInd        = 1;           % location in Z stack
            %roiLast.tInd        = 1;           % location in T stack
            pos                 = [newEventFrameNum(1) 50 newEventFrameNum(2) 100];
            xy                  = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
            roiLast.Position    = pos;
            roiLast.xyInd       = xy;          % shape in xy plane
            roiLast.Name        = newEventName;
            roiLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
            roiLast.SeqNum      = 1;           % designates Event number
            roiLast.Color       = [0 1 0];           % designates Event color
            
            obj.RoiLast         = roiLast;
            
            
            % Run over all files/trials and load the Analysis data
            for trialInd = 1:validTrialNum,
                
                [Par.DMB, strEvent]         = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                numEvent                    = length(strEvent);
                strEvent{numEvent + 1}      = roiLast;
                
                Par.DMB                     = Par.DMB.SaveAnalysisData(trialInd,'strEvent',strEvent);
                
                
            end
            DTP_ManageText([], sprintf('Multi Trial : Complex Event assignment completed.'),  'I' ,0);
            
            
            
        end
        
        % ==========================================
        % Shift the trial index                        
        function [obj,Par] = MultiTrialEventIndexShift(obj,Par,FigNum)
            % MultiTrialEventIndexShift - loads Event data from the experiment.
            % Preprocess it to build the full list of all events in all trials.
            % Find unique Events and project them all over the database - allows to shift them by trial index.
            % Inputs:
            %   Par         - control structure
            %
            % Outputs:
            %   Par         - control structure updated
            % check if initialized

            % check if initialized
%             if isempty(obj.MngrData),
%                 obj.MngrData                  = LoadDataFromTrials(obj.MngrData,Par);
%             end
            if isempty(obj.MngrData), error('MngrData must be init first');  end;
            
            eventNames      = obj.MngrData.GetEventNames();
            % select Event to remove
            [s,ok] = listdlg('PromptString','Select Event to Remove :','ListString',eventNames,'SelectionMode','single');
            if ~ok, return; end;
            maxBehaveFrameNum   = obj.MngrData.TwoPhoton_FrameNum;
            maxTrialNum         = obj.MngrData.DMT.ValidTrialNum;
            
            % get all trials
            eventNameSel    = eventNames{s};
            dataStr         = TrialsPerEvent(obj.MngrData, eventNameSel);
            
            % detect all trials with the event
            trialInds        = cell2mat([dataStr.Event(:,1)])';
            
            % check Trials
            validTrialNum      = length(trialInds);
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data for event %s. Please check the data. ',eventNameSel),  'E' ,0);
            else
                DTP_ManageText([], sprintf('Multi Trial : Found %d trials with event %s. ',validTrialNum,eventNameSel),  'I' ,0);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Setup & Get important parameters for event
            %%%%%%%%%%%%%%%%%%%%%%
            isOK                  = false; % support next level function
            options.Resize        ='on';
            options.WindowStyle   ='modal';
            options.Interpreter   ='none';
            prompt                = {'Event Name',...
                                    'Trial Offset [-10:10]',...
                                    'Trial Numbers [any subset]',...
                };
            name                = 'Add New Event to specific trials:';
            numlines            = 1;
            defaultanswer       ={eventNameSel,num2str(0),num2str(trialInds)};
            answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
            if isempty(answer), return; end;
            
            
            % try to configure
            newEventName        = answer{1};
            newEventTrialOff    = max(-10,min(10,str2num(answer{2})));
            newEventTrialInd    = str2num(answer{3});
            
            % checks
            if abs(newEventTrialOff)<1,
                DTP_ManageText([], sprintf('Multi Trial : Offset can not be zero. '),  'W' ,0);
                return;
            end
            newEventName        = [newEventName,'_',num2str(newEventTrialOff)];
            newEventTrialInd    = newEventTrialInd + newEventTrialOff;
            newEventTrialInd(newEventTrialInd < 1) = [];
            newEventTrialInd(newEventTrialInd > maxTrialNum) = [];
            
            % Create new ROI
            eventLast            = TPA_EventManager();
            
            % prepare ROI prototype
            eventLast.Type        = eventLast.ROI_TYPES.RECT; % ROI_TYPES.RECT should be
            pos                   = [20 10 10 10];
            xy                    = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
            %eventLast.Position    = pos;
            %eventLast.xyInd       = xy;          % shape in xy plane
            eventLast.Name        = newEventName;
            eventLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
            eventLast.SeqNum      = 1;           % designates Event number
            eventLast.Color       = [0 1 0];           % designates Event color
            eventLast.Data        = zeros(maxBehaveFrameNum,2);
            eventLast.Data(eventLast.tInd(1):eventLast.tInd(2),:) = 1; % no reason
            
            
            % do assignment
            obj.RoiLast         = eventLast;
            obj.TrialInd        = newEventTrialInd;
            obj                 = AssignRoiLast(obj);
            
            
            DTP_ManageText([], sprintf('Multi Trial : Events %s is assigned to %d trial files',newEventName,numel(newEventTrialInd)),  'I' ,0);
            
        end
        
        
        
    end
    
    % Entire Files based
    methods
        
        % ==========================================
        % Requires optimization
        function Par = MultiTrialEventProcess(obj,Par,FigNum)
            % TPA_MultiTrialEventProcess - computes Event data for all trials
            % Inputs:
            %   Par         - control structure
            %   BDA_XXX.mat -           files on the disk
            %
            % Outputs:
            %   Par         - control structure updated
            %   BDA_XXX.mat -           files on the disk
            
            %-----------------------------
            % Ver	Date	 Who	Descr
            %-----------------------------
            % 25.02 15.03.17 UD     Created for Event processing
            %-----------------------------
            
            if nargin < 1,  error('Need Par structure');        end;
            if nargin < 2,  FigNum      = 11;                  end;
            
            %if FigNum < 1, return; end;
            
            % attach
            global SData
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Run over all files/trials and load the Analysis data
            %%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%
            % Load Trial
            %%%%%%%%%%%%%%%%%%%%%%
            Par.DMT                     = Par.DMT.CheckData(true);
            if isa(Par.DMT,'TPA_DataManagerPrarie') || isa(Par.DMT,'TPA_DataManagerTwoChannel')
                validTrialNum           = Par.DMT.ValidTrialNum;
                %Par                     = ExpandEvents(Par);
            else
                validTrialNum      = length(Par.DMB.EventFileNames);
            end
            %validTrialNum      = Par.DMB.VideoFileNum;
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder. ',Par.DMB.EventDir),  'E' ,0);
                validTrialNum           = Par.DMT.ValidTrialNum;
                if validTrialNum < 1,
                    DTP_ManageText([], sprintf('Multi Trial : No ROI data in folder %s. New event data will be created.',Par.DMT.RoiDir),  'E' ,0);
                    %return
                end
                Par             = ExpandEvents(Par);
                DTP_ManageText([], sprintf('Multi Trial : Manual Events will be created in folder %s. ',Par.DMB.EventDir),  'W' ,0);
                validTrialNum   = Par.DMB.EventFileNum;
                
            else
                DTP_ManageText([], sprintf('Multi Trial : Found %d valid trials. ',validTrialNum),  'I' ,0);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Select which trial to process
            %%%%%%%%%%%%%%%%%%%%%%
            trialFileNames        = Par.DMB.VideoSideFileNames;
            [s,ok] = listdlg('PromptString','Select Trial to Process :','ListString',trialFileNames,'SelectionMode','multiple', 'ListSize',[300 500]);
            if ~ok, return; end;
            
            selecteInd          = s;
            selectedTrialNum    = length(s);
            
            
            % prepare
            mngrAnalys              = TPA_BehaviorAnalysis();
            mngrAnalys.FigNum       = FigNum;
            
            for m = 1:selectedTrialNum,
                
                trialInd                        = selecteInd(m);
                
                %%%%%%%%%%%%%%%%%%%%%%
                % Load Trial
                %%%%%%%%%%%%%%%%%%%%%%
                [Par.DMB, isOK]                    = Par.DMB.SetTrial(trialInd);
                [Par.DMB, strEvent]                = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
                
                % this code helps with sequential processing of the ROIs: use old one in the new image
                numEvent                            = length(strEvent);
                if numEvent < 1,
                    DTP_ManageText([], sprintf('Multi Trial : There are no ROIs in trial %d. Trying to continue',trialInd),  'E' ,0);
                    continue
                end
                
                [Par.DMB, SData.imBehaive]                = Par.DMB.LoadBehaviorData(trialInd,'all');
                if isempty(SData.imBehaive),
                    DTP_ManageText([], sprintf('Multi Trial : There is no Behavioral data in trial %d. Trying to continue',trialInd),  'E' ,0);
                    continue
                end
                
                
                %%%%%%%%%%%%%%%%%%%%%%
                % Average
                %%%%%%%%%%%%%%%%%%%%%%
                %mngrAnalys                          = ExternalAnalysis(mngrAnalys,SData.imBehaive,strEvent);
                mngrAnalys                          = ExternalAnalysis(mngrAnalys,[],strEvent);
                [mngrAnalys,strEvent]               = ExportEvents(mngrAnalys);
                
                
                %%%%%%%%%%%%%%%%%%%%%%
                % Save back
                %%%%%%%%%%%%%%%%%%%%%%
                % start save
                Par.DMB                             = Par.DMB.SaveAnalysisData(trialInd,'strEvent',strEvent);
                
            end
            DTP_ManageText([], sprintf('Multi Trial : Event Data is computed for %d trials.',validTrialNum),  'I' ,0);
            
        end
        
        % ==========================================
        % Requires optimization        
        function [Par,dbROI,dbEvent] = MultiTrialEventShow(obj,Par,FigNum)
            % TPA_MultiTrialEventShow - loads data from the experiment.
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
            % 25.04 19.03.17 UD     Created from TPA_MultiTrialShow
            % 23.02 06.02.16 UD     Adding ROI Class suppport
            % 22.02 12.01.16 UD     Adapted for new events
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
            if FigNum < 1, return; end;
            
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
            newEventExist = false; % estimate
            for trialInd = 1:validTrialNum,
                
                
                [Par.DMT, strROI]           = Par.DMT.LoadAnalysisData(trialInd,'strROI');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                numROI                      = length(strROI);
                if numROI < 1,
                    DTP_ManageText([], sprintf('Multi Trial : There are no ROIs in trial %d. Trying to continue',trialInd),  'E' ,0);
                end
                
                
                % read the info
                for rInd = 1:numROI,
                    
                    if size(strROI{rInd}.Data,2)< 2,
                        DTP_ManageText([], sprintf('Multi Trial : Trial %d, dF/F is not computed for ROI %s. Trying to continue',trialInd,strROI{rInd}.Name),  'E' ,0);
                        continue;
                    end
                    
                    
                    dbRoiRowCount          = dbRoiRowCount + 1;
                    dbROI{dbRoiRowCount,1} = trialInd;
                    dbROI{dbRoiRowCount,2} = rInd;                   % roi num
                    dbROI{dbRoiRowCount,3} = strROI{rInd}.Name;      % name
                    dbROI{dbRoiRowCount,4} = strROI{rInd}.Data(:,2);
                    newRoiExist = newRoiExist | isempty(strROI{rInd}.Data);
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
                    dbEventRowCount            = dbEventRowCount + 1;
                    dbEvent{dbEventRowCount,1} = trialInd;
                    dbEvent{dbEventRowCount,2} = eInd;                   % roi num
                    dbEvent{dbEventRowCount,3} = strEvent{eInd}.Name;      % name
                    dbEvent{dbEventRowCount,4} = strEvent{eInd}.tInd;
                    dbEvent{dbEventRowCount,5} = strEvent{eInd}.Data;
                    newEventExist = newEventExist | isempty(strEvent{eInd}.Data);
                end
                
                
            end
            DTP_ManageText([], sprintf('Multi Trial : Database Ready.'),  'I' ,0);
            
            if FigNum < 1, return; end;
            
            % check new names
            if newRoiExist,
                DTP_ManageText([], sprintf('Preview : You need to rerun dF/F analysis. Empty ROI is found. '), 'E' ,0)   ;
                return
            end
            % check new names
            if newEventExist,
                DTP_ManageText([], sprintf('Preview : You need to rerun Event analysis. Empty Event is found. '), 'E' ,0)   ;
                return
            end
            % check their number
            if dbEventRowCount < 1,
                DTP_ManageText([], sprintf('Preview : You need to rerun Event analysis. No Event is found. '), 'E' ,0)   ;
                return
            end
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Find Unique names
            %%%%%%%%%%%%%%%%%%%%%%
            namesEvents         = unique(dbEvent(:,3)); %unique(strvcat(dbEvent{:,3}),'rows');
            %namesEvent          = unique(strvcat(dbEvent{:,3}),'rows');
            
            frameNum            = size(dbEvent{1,5},1);
            timeBehavior       = (1:frameNum)';
            
            
            [s,ok] = listdlg('PromptString','Select Event name :','ListString',namesEvents,'SelectionMode','single');
            if ~ok, return; end;
            
            nameRefEvent        = namesEvents{s}; %namesROI(s,:);
            
            figure(FigNum + s),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            procROI             = []; trialCount = 0;
            trialSkip           = 20; % the change in brightness levels
            
            for p = 1:size(dbEvent,1),
                
                if ~strcmp(nameRefEvent,dbEvent{p,3}), continue; end;
                
                procROI = dbEvent{p,5};
                if isempty(procROI), text(10,p*10,'No dF/F data found'); continue; end;
                
                % get the data
                %procROI = [procROI dbROI{p,4}];
                
                % get trial and get events
                trialInd    = dbEvent{p,1};
                trialCount  = trialCount + 1;
                
                %     % find all the events taht are in trial p
                %     if validBahaveTrialNum > 0,
                %         eventInd = find(trialInd == [dbEvent{:,1}]);
                %     else
                %         eventInd = [];
                %     end
                
                % show trial with shift
                pos  = trialSkip*(trialCount - 1);
                clr  = rand(1,3);
                plot(timeBehavior,procROI+pos,'color',clr); hold on;
                %plot(timeBehavior,zeros(frameNum,1) + pos,':','color',[.7 .7 .7]);
                
            end
            ylabel('Trial Num'),xlabel('Frame Num')
            hold off
            %ylim([-1.5 2])
            title(sprintf('Brightness for Event %s',nameRefEvent))
            
            return
            
            
        end        
        
        % ==========================================
        % Requires optimization                
        function Par = MultiTrialEventCreate(obj,Par,FigNum)
            % TPA_MultiTrialEventCreate - loads Event data from all trials.
            % Ask user about new event info.
            % Adds it to the event list for each trial.
            % Inputs:
            %   Par         - control structure
            %  Event        - data bases
            % Outputs:
            %   Par         - control structure updated
            %  Event        - data bases
            
            %-----------------------------
            % Ver	Date	 Who	Descr
            %-----------------------------
            % 24.16 08.02.17 UD     Video to TwoPhoton.
            % 24.05 16.08.16 UD     Resolution is not an integer.
            % 23.20 23.08.16 UD     Fix string bug
            % 21.08 03.11.15 UD     Number of files
            % 21.07 13.10.15 UD     Adjusting to EventManager  and ValidTrials according to number of BDA files
            % 20.05 19.05.15 UD     Use VideoFile numbers to create new events
            % 20.04 17.05.15 UD     Adjusted to support new event structure
            % 19.32 12.05.15 UD     Specific trials
            % 17.08 05.03.14 UD     Extend to all video files. Fixing bug in old index file generation - inpolygon must be run again
            % 17.02 10.03.14 UD     Created
            %-----------------------------
            
            if nargin < 1,  error('Need Par structure');        end;
            if nargin < 2,  FigNum      = 11;                  end;
            
            
            % attach
            %global SData SGui
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Load Trial
            %%%%%%%%%%%%%%%%%%%%%%
            Par.DMT                     = Par.DMT.CheckData(true);
            if isa(Par.DMT,'TPA_DataManagerPrarie') || isa(Par.DMT,'TPA_DataManagerTwoChannel')
                validTrialNum           = Par.DMT.ValidTrialNum;
                Par                     = ExpandEvents(Par);
            else
                validTrialNum      = length(Par.DMB.EventFileNames);
            end
            %validTrialNum      = Par.DMB.VideoFileNum;
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder. ',Par.DMB.EventDir),  'E' ,0);
                validTrialNum           = Par.DMT.ValidTrialNum;
                if validTrialNum < 1,
                    DTP_ManageText([], sprintf('Multi Trial : No ROI data in folder %s. New event data will be created.',Par.DMT.RoiDir),  'E' ,0);
                    %return
                end
                Par             = ExpandEvents(Par);
                DTP_ManageText([], sprintf('Multi Trial : Manual Events will be created in folder %s. ',Par.DMB.EventDir),  'W' ,0);
                validTrialNum   = Par.DMB.EventFileNum;
                
            else
                DTP_ManageText([], sprintf('Multi Trial : Found %d Events Analysis files. ',validTrialNum),  'I' ,0);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Guess numbmer of frames in Behavioral data
            %%%%%%%%%%%%%%%%%%%%%%
            maxBehaveFrameNum       = 2400;
            % detect Prarie experiment
            if isa(Par.DMT,'TPA_DataManagerPrarie') || isa(Par.DMT,'TPA_DataManagerTwoChannel')
                tpFrameNum = size(Par.DMT.VideoFileNames,1);
                maxBehaveFrameNum = floor(tpFrameNum*Par.DMB.Resolution(4));
            end
            DTP_ManageText([], sprintf('Multi Trial : Found %d behavioral frames. ',maxBehaveFrameNum),  'I' ,0);
            
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Setup & Get important parameters for event
            %%%%%%%%%%%%%%%%%%%%%%
            isOK                  = false; % support next level function
            options.Resize        ='on';
            options.WindowStyle   ='modal';
            options.Interpreter   ='none';
            prompt                = {'Event Name',...
                'Event Start and Duration [Behavioral Frame Numbers]',...
                'Trial Numbers [any subset]',...
                };
            name                = 'Add New Event to specific trials:';
            numlines            = 1;
            defaultanswer       ={'Tone',num2str([100 50]),num2str((1:validTrialNum))};
            answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
            if isempty(answer), return; end;
            
            
            % try to configure
            newEventName        = answer{1};
            newEventFrameNum    = str2num(answer{2});
            newEventTrialInd    = str2num(answer{3});
            
            % check
            if numel(newEventFrameNum) ~= 2,
                errordlg('You must provide two frame numbers for event start and duration')
                return
            end
            if sum(newEventFrameNum) > maxBehaveFrameNum,
                errordlg(sprintf('Event frame numbers exceed max number of valid frames %d',maxBehaveFrameNum))
                return
            end
            if numel(newEventTrialInd) < 1,
                errordlg('You must provide number of trial indexes')
                return
            end
            if min(newEventTrialInd) < 1,
                errordlg('Minimal trial number should be 1')
                return
            end
            if max(newEventTrialInd) > validTrialNum,
                errordlg(sprintf('Maximal trial number should be %d',validTrialNum))
                return
            end
            
            eventLast            = TPA_EventManager();
            
            % prepare ROI prototype
            eventLast.Type        = eventLast.ROI_TYPES.RECT; % ROI_TYPES.RECT should be
            %eventLast.Active      = true;   % designates if this pointer structure is in use
            %eventLast.NameShow    = false;       % manage show name
            %eventLast.zInd        = 1;           % location in Z stack
            %eventLast.tInd        = 1;           % location in T stack
            pos                     = [newEventFrameNum(1) 50 newEventFrameNum(2) 100];
            xy                      = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
            %eventLast.Position    = pos;
            %eventLast.xyInd       = xy;          % shape in xy plane
            eventLast.Name        = newEventName;
            eventLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
            eventLast.SeqNum      = 1;           % designates Event number
            eventLast.Color       = [0 1 0];           % designates Event color
            eventLast.Data        = zeros(maxBehaveFrameNum,2);
            eventLast.Data(eventLast.tInd(1):eventLast.tInd(2),:) = 1; % no reason
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Run over all files/trials and load the Analysis data
            %%%%%%%%%%%%%%%%%%%%%%
            for trialInd = 1:validTrialNum,
                
                % check if included
                if ~any(trialInd == newEventTrialInd), continue; end;
                
                [Par.DMB, strEvent]         = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                % add new event
                %strEvent{end+1}                    = Add(strEvent);
                strEvent{end+1}             = eventLast;
                Par.DMB                     = Par.DMB.SaveAnalysisData(trialInd,'strEvent',strEvent);
                
                
            end
            DTP_ManageText([], sprintf('Multi Trial : New Event assignment completed.'),  'I' ,0);
            
        end
        
        % ==========================================
        % Requires optimization                        
        function Par = MultiTrialEventAssignment(obj,Par,FigNum)
            % TPA_MultiTrialEventAssignment - loads Event data from the experiment.
            % Preprocess it to build the full list of all events in all trials.
            % Find unique Events and project them all over the database.
            % If Event in different trials has been moved/renamed - this info will be lost.
            % Inputs:
            %   Par         - control structure
            %
            % Outputs:
            %   Par         - control structure updated
            
            %-----------------------------
            % Ver	Date	 Who	Descr
            %-----------------------------
            % 25.09 30.04.17 UD     merging with events
            % 25.04 19.03.17 UD     Created from TPA_MultiTrialRoiAssignment
            % 23.07 01.03.16 UD     Protect from empty ROIs
            % 21.22 29.12.15 UD     Rename
            % 21.11 17.11.15 UD     Selecting a subset of ROIs
            % 21.08 20.10.15 UD     Selecting which video file to write for Prarie experiment (Janelia is not tested).
            % 19.23 17.02.15 UD     Assign all files without bug fix.
            % 17.08 05.03.14 UD     Extend to all video files. Fixing bug in old index file generation - inpolygon must be run again
            % 17.02 10.03.14 UD     Created
            %-----------------------------
            
            if nargin < 1,  error('Need Par structure');        end;
            if nargin < 2,  FigNum      = 11;                  end;
            
            
            % attach
            %global SData SGui
            
            % containers of events and rois
            dbEvent               = {};
            dbEventRowCount       = 0;
            
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Setup & Get important parameters
            %%%%%%%%%%%%%%%%%%%%%%
            %tpSize          = Par.DMT.VideoSize;
            %bhSize          = Par.DMB.VideoSideSize;
            %timeConvertFact      = Par.DMB.Resolution(4)/Par.DMT.Resolution(4);
            
            % check for updates
            Par.DMB             = Par.DMB.CheckData();
            
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Run over all files/trials and load the Analysis data
            %%%%%%%%%%%%%%%%%%%%%%
            vBool                   = cellfun(@numel,Par.DMB.EventFileNames) > 0;
            validTrialNum           = sum(vBool);
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder. Create this data or run Data Check',Par.DMB.EventDir),  'E' ,0);
                return
            else
                DTP_ManageText([], sprintf('Multi Trial : Found %d Analysis files of ROI and Events. Reading ...',validTrialNum),  'I' ,0);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Select which trial
            %%%%%%%%%%%%%%%%%%%%%%
            validInd                = find(vBool);
            eventNameList           = Par.DMB.EventFileNames(validInd);
            [s,ok] = listdlg('PromptString','Select Trial with Events :','ListString',eventNameList,'SelectionMode','multiple','ListSize',[300 500]);
            if ~ok, return; end;
            
            selecteInd          = validInd(s);
            selectedTrialNum    = length(s);
            
            % for ind fix
            % nR          = Par.DMT.VideoDataSize(1);
            % nC          = Par.DMT.VideoDataSize(2);
            % [X,Y]       = meshgrid(1:nR,1:nC);  %
            
            for sInd = 1:selectedTrialNum,
                
                % show
                trialInd                    = selecteInd(sInd);
                
                
                [Par.DMB, strEvent]           = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                numEvents                      = length(strEvent);
                if numEvents < 1,
                    DTP_ManageText([], sprintf('Multi Trial : There are no Events in trial %d. Trying to continue',trialInd),  'E' ,0);
                end
                
                
                
                % read the info
                for rInd = 1:numEvents,
                    
                    dbEventRowCount = dbEventRowCount + 1;
                    dbEvent{dbEventRowCount,1} = trialInd;
                    dbEvent{dbEventRowCount,2} = rInd;                   % roi num
                    dbEvent{dbEventRowCount,3} = strEvent{rInd}.Name;      % name
                    dbEvent{dbEventRowCount,4} = strEvent{rInd};           % save entire structure
                end
                
            end
            DTP_ManageText([], sprintf('Multi Trial : Database Ready.'),  'I' ,0);
            
            % user selected bad files
            if isempty(dbEvent),
                DTP_ManageText([], sprintf('Multi Trial : Trials selected do not contain ROIs.'),  'W' ,0);
                return
            end
            
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Find Unique names
            %%%%%%%%%%%%%%%%%%%%%%
            % find unique patterns and their first occurance
            [namesEvent,ia]       = unique(strvcat(dbEvent{:,3}),'rows','first');
            
            % recover back the entire struture of ROIs
            strEvent              = {};
            for m = 1:length(ia),
                strEvent{m}       = dbEvent{ia(m),4};
            end
            numEvents           = length(strEvent);
            
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Select which trial to write
            %%%%%%%%%%%%%%%%%%%%%%
            trialFileNames        = Par.DMB.VideoSideFileNames;
            [s,ok] = listdlg('PromptString','Select Trial to Assign :','ListString',trialFileNames,'SelectionMode','multiple', 'ListSize',[300 500]);
            if ~ok, return; end;
            
            selecteInd          = s;
            selectedTrialNum    = length(s);
            
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Ask about merge
            %%%%%%%%%%%%%%%%%%%%%%
            % Ask about event data
            doMerge = false;
            if numEvents > 0,
                buttonName = questdlg('Previous Behaivioral Event data is found. Would you like?', 'Warning','Cancel','Merge','Overwrite','Cancel');
                if strcmp(buttonName,'Cancel'), return; end;
                % check if merge is required
                doMerge = strcmp(buttonName,'Merge');
            end
            
            
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Write data back
            %%%%%%%%%%%%%%%%%%%%%%
            
            for m = 1:selectedTrialNum,
                
                trialInd        = selecteInd(m);
                strEventSave    = strEvent;
                if doMerge,
                    [Par.DMB, strEventOld]           = Par.DMB.LoadAnalysisData(trialInd,'strEvent');
                    strEventSave                     = cat(2,strEventSave,strEventOld);
                end
                Par.DMB     = Par.DMB.SaveAnalysisData(trialInd,'strEvent',strEventSave);
                
            end
            
            DTP_ManageText([], sprintf('Multi Trial : %d Events  are aligned to %d trial files',numEvents,selectedTrialNum),  'I' ,0);
            
        end
        
        
    end % methods
    
    % GUI based
    methods
        % ==========================================
        function obj = CreateConstantEventForSpecificTrials(obj)
            % CreateConstantEventForSpecificTrials - GUI for new event creation
            % defined for specific trials
            % Input:
            %     obj - current structure
            % Output:
            %     obj - updated structure
            
            
            
            % check if initialized
            if isempty(obj.MngrData), error('MngrData must be init first');  end;
            
            % check Trials
            validTrialNum       = length(obj.MngrData.DMB.EventFileNames);
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('Multi Trial : No Behavior data in directory %s. Please check the folder. ',obj.MngrData.DMB.EventDir),  'E' ,0);
                return;
            end
            trialInd            = (1:validTrialNum)';
            
            
            % define ROI params
            [obj,isOK]          = InitRoiLast(obj);
            if ~isOK,
                DTP_ManageText([], sprintf('Multi Trial : User selected cancel. '),  'W' ,0);
                return;
            end
            
            
            eventNames                    = obj.MngrData.DMB.EventFileNames;
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Event planner
            %%%%%%%%%%%%%%%%%%%%%%
            hhFig = figure(...
                'Position',[100 100 300 650],...
                'Name','Trial Selection Table',...
                'menubar','none',...
                'Tag','AnalysisROI',...
                'Color','white',...
                'CloseRequestFcn',{@(src,event)fCloseRequestFcn(obj,src,event)});
            
            %'WindowStyle','modal',...
            
            %colordef(hhFig,'none');
            
            obj.QueryData   = cat(2,num2cell(true(validTrialNum,1)), eventNames);
            columnname      = {'Select To Apply', '       Event Name   '};
            columnformat    = {'logical','char'};
            columneditable  =  [true false];
            rowname         = num2cell(trialInd);
            hhEventTable    = uitable('Units','normalized',...
                'Position',     [0.0 0.0 0.999 0.999],...
                'Data',         obj.QueryData,...
                'ColumnName',   columnname,...
                'ColumnWidth',  {'auto','auto'},...
                'ColumnFormat', columnformat,...
                'ColumnEditable', columneditable,...
                'CellEditCallback', {@(src,event)fCellEditCallback(obj,src,event)},...
                'RowName',rowname);
            
            % The close button.
            hCntrl = uicontrol( ...
                'Style','pushbutton', ...
                'Units','normalized', ...
                'Position',[0.03 0.03 0.4 0.1], ...
                'String','Save & Close', ...
                'Callback','');
            
            
            obj.hFig            = hhFig;
            obj.hEventTable     = hhEventTable;
            
            % populate callbacks
            set(hhFig ,         'CloseRequestFcn',  {@(src,event)fCloseRequestFcn(obj,src,event)});
            set(hhEventTable ,  'CellEditCallback', {@(src,event)fCellEditCallback(obj,src,event)});
            set(hCntrl ,        'Callback',         {@(src,event)fCloseRequestFcn(obj,src,event)});
            
            uiwait(hhFig);
            %uiresume(hhFig);
            
            trialInd            = cell2mat(obj.QueryData(:,1));
            
        end
        
        % ==========================================
        function obj = ComplexEventPlanner(obj)
            % CmplexEventPlanner - GUI for new complex event creation
            % Input:
            %     obj - current structure
            %     Par - contains event info
            % Output:
            %     obj - updated structure
            %     Par - updated structure
            
            
            % check if initialized
            if isempty(obj.MngrData),
                error('MngrData must be init first')
            end
            
            eventNames                    = obj.MngrData.GetEventNames();
            maxEventNum                   = 3;
            [datEvent{1:maxEventNum,1}]   = deal(eventNames{1});
            [datLogic{1:maxEventNum,1}]   = deal('And');
            
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Event planner
            %%%%%%%%%%%%%%%%%%%%%%
            hhFig               = figure(...
                'Position',[100 100 300 150],...
                'Name','Query Table',...
                'menubar','none',...
                'WindowStyle','modal',...
                'Tag','AnalysisROI',...
                'Color','white',...
                'CloseRequestFcn',{@(src,event)fCloseRequestFcn(obj,src,event)});
            
            %colordef(hhFig,'none');
            
            ndata           = cat(2,num2cell(false(maxEventNum,1)), datLogic, datEvent);
            columnname      = {'Select', 'Logic','Event Name'};
            columnformat    = {'logical', {'And','And Not'},eventNames'};
            columneditable  =  [true true true];
            rowname         = num2cell((1:maxEventNum)');
            hhEventTable     = uitable('Units','normalized',...
                'Position', [0.0 0.0 0.999 0.999],...
                'Data', ndata,...
                'ColumnName', columnname,...
                'ColumnWidth', {'auto','auto',100},...
                'ColumnFormat', columnformat,...
                'ColumnEditable', columneditable,...
                'CellEditCallback', {@(src,event)fCellEditCallback(obj,src,event)},...
                'RowName',rowname);
            
            % The close button.
            hCntrl = uicontrol( ...
                'Style','pushbutton', ...
                'Units','normalized', ...
                'Position',[0.03 0.03 0.4 0.15], ...
                'String','Save & Close', ...
                'Callback','');
            
            
            
            %uiwait(hhFig);
            %uiresume(hhFig);
            
            obj.hFig            = hhFig;
            obj.hEventTable     = hhEventTable;
            
            % populate callbacks
            set(hhFig , 'CloseRequestFcn',{@(src,event)fCloseRequestFcn(obj,src,event)});
            set(hhEventTable , 'CellEditCallback', {@(src,event)fCellEditCallback(obj,src,event)});
            set(hCntrl , 'Callback',{@(src,event)fCloseRequestFcn(obj,src,event)});
            
            
        end
        
        % ==========================================
        % Callback on edit
        function obj = fCellEditCallback(obj,hObject, eventdata)
            % hObject    Handle to uitable1 (see GCBO)
            % eventdata  Currently selected table indices
            % Callback check data entry and aplyer query over selected columns
            %
            
            % Get the list of currently selected table cells
            sel         = eventdata.Indices;     % Get selection indices (row, col)
            if isempty(sel), return; end;        % I do not understand why
            
            obj.QueryData   = get(obj.hEventTable,'Data');
            %QueryTable.Data   = QueryTableData; % save for exit
            
            %         % put back original value
            %         if sel(1) <= rNum, % not editable
            %             val    = EventTableDataFix(sel(1),sel(2));
            %         else
            %             EventTableData   = get(handStr.hEventTable,'Data');
            %             val    = EventTableData(sel(1),sel(2));
            %         end;
            %
            %         % checks
            %         if sel(1) == rNum+3,
            %             EventTableData(sel(1),sel(2)) = double(val > 0);
            %         else
            %             EventTableData(sel(1),sel(2)) = val;
            %         end
            %         % display
            %         set(handStr.hEventTable,'Data',EventTableData);
            %
            %         % calc
            %         %fUpdateQuery();
            %         QueryTable.Data   = QueryTableData; % save for exit
            
            
        end
        
        % ==========================================
        % Close
        function obj = fCloseRequestFcn(obj, s, e)
            % This is where we can return the ROI selected
            
            %fExportROI();               % check that ROI structure is OK
            obj.QueryData   = get(obj.hEventTable,'Data');
            %uiresume(handStr.roiFig);
            try
                uiresume(obj.hFig);
                %delete(findobj('Tag','AnalysisROI'))
                delete(obj.hFig);
                %delete(s)
            catch ex
                errordlg(ex.getReport('basic'),'Close Window Error','modal');
            end
            % return attention
            %figure(SGui.hMain)
        end
        
        
    end % methods
end % class

%%%%%%%%%%%%%%%%%%%%%%%%%
% Expand for empty events
%%%%

function Par = ExpandEvents(Par)

validTrialNum           = Par.DMT.RoiFileNum;
Par.DMB.EventDir        = Par.DMT.RoiDir;
Par.DMB.EventFileNum    = validTrialNum;
for m = 1:validTrialNum,
    if isempty(Par.DMT.RoiFileNames{m}), continue; end;
    Par.DMB.EventFileNames{m}  = sprintf('BDA_%s',Par.DMT.RoiFileNames{m}(5:end));
end
end


