classdef TPA_MultiExperimentLearning
    % TPA_MultiExperimentLearning - Collects TwoPhoton dF/F info of all ROIs from multiple experiments
    % and performs averaging over the trials in the same day.
    % ROIs are mapped and max response is shown
    % Inputs:
    %       BDA_XXX.mat, TPA_YYY.mat - data base
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 24.15 22.01.17 UD     Compute Ordered by CM
    % 24.10 12.11.16 UD     Adding Init
    % 24.08 01.11.16 UD     Adopted for Test
    % 19.30 05.05.15 UD     Functional reconstruction
    % 19.29 01.05.15 UD     Created from Omri Barak TPA_corr2
    %-----------------------------
    properties (Constant)
        IMAGE_SIZE           = [512 512];  % transform pixels to um
        COLOR_LIM            = [-0.1 2]; % like in MultiTrial Explorer
        %NEURON2UM           = 10;  % cell radius in um
    end
    properties
        
        % Experiment Setup
        AnalysisPath        % animal directory
        AnalysisDir         % cell array of all experiments
        
        % All data container
        AnalysisStr         % Contains, dFF Data, Trials and ROI info 
        
        
        
        
    end % properties
    properties (SetAccess = private)
    end

    methods % Analysis
        
        % ==========================================
        function obj = TPA_MultiExperimentLearning()
            % TPA_MultiExperimentLearning - constructor
            % Input:
            %    -
            % Output:
            %     default values
            
            obj.AnalysisPath = '\\Jackie-backup\e\Projects\PT_IT\Analysis\D43';
            obj         = Init(obj);
        end
        
        % ==========================================
        function obj = Init(obj)
            % Init - clean up
            % Input:
            %    -
            % Output:
            %     default values
            
            obj.AnalysisPath = '\\Jackie-backup\e\Projects\PT_IT\Analysis\D43';
            obj.AnalysisStr  = {};
            obj.AnalysisDir  = {};
            
        end
        
        % ==========================================
        function [obj, frameRange] = SelectFrameRange(obj, frameRange)
            % SelectFrameRange - selects frame range for filtering
            if nargin < 2, frameRange = [1 360]; end;
            
            % of the ROI spike events
            isOK                  = false; % support next level function
            options.Resize        ='on';
            options.WindowStyle   ='modal';
            options.Interpreter   ='none';
            prompt                = {'Analysis Range [Two Photon Frame Numbers]',...            
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
            frameRange(1)       = max(-500,min(10000,frameRange(1)));          
            frameRange(2)       = max(-500,min(10000,frameRange(2)));          
            %obj.FrameRange      = frameRange;
        
        end
        
        % ==========================================
        function obj = LoadSingleExperimentTwoPhoton(obj, expId) 
           % LoadSingleExperimentTwoPhoton - loads single experiment with TP data
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to load
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;

            % checks
            expNum              = length(obj.AnalysisDir);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum >= expId ,'expId must be less than expNum');
            
            % check if is already loaded
            if ~isempty(obj.AnalysisStr),
                if length(obj.AnalysisStr) >= expId,
                    if strcmp(obj.AnalysisStr{expId}.ExpName,obj.AnalysisDir{expId}),
                      ShowText(obj,  sprintf('Experiment %s is already loaded',obj.AnalysisDir{expId}), 'I');
                      return;
                    end
                end
            end
            
            
            % construct path
            analysisDir         = fullfile(obj.AnalysisPath,obj.AnalysisDir{expId});
            
            % Load Two Photon ROI data
            fileNames           = dir(fullfile(analysisDir,'TPA_*.mat'));
            fileNum             = length(fileNames);
            if fileNum < 1,
                error('TwoPhoton : Can not find data files in the directory %s. Check file or directory names.',analysisDir);
            end;
            [fileNamesRoi{1:fileNum,1}]     = deal(fileNames.name);
            fileNumRoi                      = fileNum;

            allTrialRois                    = cell(fileNumRoi,1); count = 0; %;
            roiNumPerTrial                  = zeros(fileNumRoi,1);
            for trialInd = 1:fileNumRoi,
                fileToLoad                 = fullfile(analysisDir,fileNamesRoi{trialInd});
                usrData                    = load(fileToLoad);
                % bad trial
                if ~isfield(usrData,'strROI'), 
                    txt             = sprintf('No ROI field in file %s. Please Check.',fileToLoad);
                    ShowText(obj,  txt, 'E');
                    continue; 
                end;
                
                % check dff data
                roiNum                      = length(usrData.strROI);
                if roiNum < 1,
                    txt             = sprintf('No ROI data in %s ',fileToLoad);
                    ShowText(obj,  txt, 'E');
                    continue; 
                end;
                timeLen                    = zeros(roiNum,1);
                for r = 1:roiNum,
                    timeLen(r)              = size(usrData.strROI{r}.Data,1);
                    % bad roi
                    if timeLen(r) < 1, 
                        txt             = sprintf('%s no dF/F data in file %s. Please Check.',usrData.strROI{r}.Name,fileToLoad);
                        ShowText(obj,  txt, 'W');
                    end;
                end
                validInd                = timeLen == median(timeLen);
                validNum                = sum(validInd);
                    
                % bad trial
                if roiNum - validNum > 5, 
                    txt             = sprintf('Too many bad dF/F data in file %s. Please Check.',fileToLoad);
                    ShowText(obj,  txt, 'E');
                    continue; 
                end;
                    
                count                      = count + 1;
                allTrialRois{count}        = usrData.strROI(validInd);
                roiNumPerTrial(count)      = validNum;

            end
            if count < 1,
                txt             = sprintf('No Valid trials in %s. Please Check.',obj.AnalysisDir{expId});
                ShowText(obj,  txt, 'E');
                return; 
            end
            
            
            % cut of there is a problem
            allTrialRois                   = allTrialRois(1:count);
            roiNumPerTrial                 = roiNumPerTrial(1:count);
            
            % check roi number consistency
            if ~all(roiNumPerTrial == median(roiNumPerTrial)),
                txt             = sprintf('There are different ROI numbers in trials of %s. Please Check.',obj.AnalysisDir{expId});
                ShowText(obj,  txt, 'W');
                %return; 
            end
            nTrials     = length(allTrialRois);
            nROI        = min(roiNumPerTrial);
            nTime       = max(timeLen);
            

            % Flatten
            dataRoi     = nan(nTime, nTrials, nROI);
            namesRoi    = cell(nROI,1);
            xyzPos      = zeros(nROI,3);
            % extract all the data
            for i = 1:nROI
                for j  = 1:nTrials
                    if ~isempty(allTrialRois{j}{i}.Data)
                        dataRoi(:,j,i) = allTrialRois{j}{i}.Data(:,2);
                    end
                end
                % last trial
                namesRoi{i}     = allTrialRois{1}{i}.Name;
                xyzPos(i,1:2)   = mean(allTrialRois{1}{i}.xyInd);   
                xyzPos(i,3)     = allTrialRois{1}{i}.zInd;
            end
            assert(~any(isnan(dataRoi(:))),'Should not have a bad data');
            
            % check names are consistent order
            [namesRoi,ia]                   = unique(namesRoi);
            dataRoi                         = dataRoi(:,:,ia);
            xyzPos                          = xyzPos(ia,:);
            
            % save
            obj.AnalysisStr{expId}.DffData  = dataRoi;
            obj.AnalysisStr{expId}.PosXYZ   = xyzPos;
            obj.AnalysisStr{expId}.RoiNames = namesRoi;
            obj.AnalysisStr{expId}.ExpName  = obj.AnalysisDir{expId};
            
            % info
            ShowText(obj,  sprintf('%s : Found %d valid trials ',obj.AnalysisDir{expId},count), 'I');


        end
        
        % ==========================================
        function obj = LoadSingleExperimentBehavioral(obj, expId) 
           % LoadSingleExperimentBehavioral - loads single experiment with Behave data
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to load
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;

            % checks
            expNum              = length(obj.AnalysisDir);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum >= expId ,'expId must be less than expNum');
            
            % check if is already loaded
            if ~isempty(obj.AnalysisStr),
                if length(obj.AnalysisStr) >= expId,
                    if strcmp(obj.AnalysisStr{expId}.ExpName,obj.AnalysisDir{expId}),
                      ShowText(obj,  sprintf('Experiment %s is already loaded',obj.AnalysisDir{expId}), 'I');
                      return;
                    end
                end
            end
            
            % construct path
            analysisDir         = fullfile(obj.AnalysisPath,obj.AnalysisDir{expId});
            
            % Load Two Photon ROI data
            fileNames           = dir(fullfile(analysisDir,'BDA_*.mat'));
            fileNum             = length(fileNames);
            if fileNum < 1,
                ShowText(obj, sprintf('Behavior : Can not find data files in the directory %s. Check file or directory names.',analysisDir),'E');
                return;
            end;
            [fileNamesEvent{1:fileNum,1}]   = deal(fileNames.name);
            fileNumEvent                    = fileNum;

            allTrialEvents                  = cell(fileNumEvent,1); count = 0; %;
            eventNumPerTrial                = zeros(fileNumEvent,1);
            eventTimeLenPerTrial            = zeros(fileNumEvent,1);
            for trialInd = 1:fileNumEvent,
                fileToLoad                 = fullfile(analysisDir,fileNamesEvent{trialInd});
                usrData                    = load(fileToLoad);
                % bad trial
                if ~isfield(usrData,'strEvent'), 
                    txt             = sprintf('No Event field in file %s. Please Check.',fileToLoad);
                    ShowText(obj,  txt, 'E');
                    continue; 
                end;
                
                % check dff data
                eventNum                      = length(usrData.strEvent);
                if eventNum < 1,
                    txt             = sprintf('No Event data in %s ',fileToLoad);
                    ShowText(obj,  txt, 'E');
                    continue; 
                end;
                timeLen                    = zeros(eventNum,1);
                for r = 1:eventNum,
                    
                    if ~isprop(usrData.strEvent{r},'Data'),
                        txt             = sprintf('%s -  No property data in %s ',usrData.strEvent{r}.Name,fileToLoad);
                        ShowText(obj,  txt, 'E');
                        continue; 
                    end;
                    
                    timeLen(r)              = size(usrData.strEvent{r}.Data,1);
                    % bad roi
                    if timeLen(r) < 1, 
                        txt             = sprintf('%s no Event data in file %s. Please Check.',usrData.strEvent{r}.Name,fileToLoad);
                        ShowText(obj,  txt, 'W');
                    end;
                end
                validInd                = abs(timeLen - mean(timeLen)) < 0.1*mean(timeLen);
                validNum                = sum(validInd);
                    
                % bad trial
                if eventNum - validNum > 5, 
                    txt             = sprintf('There are many Events with different data length in file %s. Please Check.',fileToLoad);
                    ShowText(obj,  txt, 'W');
                    %continue; 
                end;
                    
                count                        = count + 1;
                allTrialEvents{count}        = usrData.strEvent(validInd);
                eventNumPerTrial(count)      = validNum;
                eventTimeLenPerTrial(count)  = max(timeLen);

            end
            if count < 1,
                txt             = sprintf('No Valid trials in %s. Please Check.',obj.AnalysisDir{expId});
                ShowText(obj,  txt, 'E');
                return; 
            end
            
            
            % cut of there is a problem
            allTrialEvents                 = allTrialEvents(1:count);
            eventNumPerTrial               = eventNumPerTrial(1:count);
            eventTimeLenPerTrial           = eventTimeLenPerTrial(1:count);
            
            % check event number consistency
            if ~all(eventTimeLenPerTrial == median(eventTimeLenPerTrial)),
                txt             = sprintf('There are different time length in Events in trials of %s. Please Check.',obj.AnalysisDir{expId});
                ShowText(obj,  txt, 'W');
            end
            nTrials     = length(allTrialEvents);
            nEvent      = sum(eventNumPerTrial);
            nTime       = max(eventTimeLenPerTrial);
            

            % Flatten
            dataEvent     = zeros(nTime,nEvent);
            namesEvent    = cell(nEvent,1);
            tPos          = zeros(nEvent,2);
            ce            = 0; % event counter
            % extract all the data
            for i = 1:nTrials
                % check for jackie
                txtName = cell(eventNumPerTrial(i),1);
                for j  = 1:eventNumPerTrial(i),
                    txtName{j} = allTrialEvents{i}{j}.Name;
                end
                % 
                [showBool,locb] = ismember(txtName,{'Success','Failure'});
                if ~any(showBool), 
                    ShowText(obj,  sprintf('%s : Success  and Failure are not found in trial %d ',obj.AnalysisDir{expId},i), 'I');
                end
                if sum(showBool)>1, 
                    ShowText(obj,  sprintf('%s : Success  and Failure are found together in trial %d ',obj.AnalysisDir{expId},i), 'W');
                end
                
                
                for j  = 1:eventNumPerTrial(i),
                    dLen        = size(allTrialEvents{i}{j}.Data,1);
                    if dLen < 1,
                        continue; 
                    end
                    
                    ce               = ce + 1;
                    dataEvent(1:dLen,ce)  = allTrialEvents{i}{j}.Data(:,1);
                    namesEvent{ce}   = allTrialEvents{i}{j}.Name;
                    tPos(ce,1:2)     = allTrialEvents{i}{j}.tInd;   
                end
                
            end
            %assert(~any(isnan(dataEvent(:))),'Should not have a bad data');
            
            % save
            obj.AnalysisStr{expId}.EventData    = dataEvent;
            obj.AnalysisStr{expId}.PosT         = tPos;
            obj.AnalysisStr{expId}.EventNames   = namesEvent;
            obj.AnalysisStr{expId}.ExpName      = obj.AnalysisDir{expId};
            
            % info
            ShowText(obj,  sprintf('%s : Found %d valid trials ',obj.AnalysisDir{expId},count), 'I');


        end
        
        % ==========================================
        function obj = ArrangeExperimentsByName(obj) 
           % ArrangeExperimentsByName - arranges data in each experiment by
           % namevorder of the ROIs
            % Input:
            %    obj    - this structure
            % Output:
            %    obj   - updated 

            % checks
            expNum              = length(obj.AnalysisDir);
            assert(expNum > 0,'First load the experiment data');
            assert(~any(isempty(obj.AnalysisStr)),'Please load all the specified experiments');
            
            % extract names for each experiment
            roiNames        = obj.AnalysisStr{1}.RoiNames;
            for expInd = 2:expNum,
                roiNames        = union(roiNames,obj.AnalysisStr{expInd}.RoiNames);
            end
            % info
            %ShowText(obj,  sprintf('%s : Found %d valid trials ',obj.AnalysisDir{expId},count), 'I');


        end
        
        
    end         % Analysis
    
    methods     % Show
        
        % ==========================================
        function obj = ShowTracesPerROI(obj, roiName, figNum) 
           % ShowROI - draws ROI traces for all experiments and trials 
            % Input:
            %    obj    - this structure
            %    roiName  - which roi to show
            % Output:
            %    obj   - updated 
            
            if nargin < 2, roiName = ''; end;
            if nargin < 3, figNum = 103; end;

            % checks
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            
            % random
            if length(roiName) < 3, roiName = obj.AnalysisStr{1}.RoiNames{randi(10,1)}; end
            
            % valid roi name - concatenate all
            roiExpInd      = zeros(expNum,1);
            for expId = 1:expNum,
                
                roiInd              = strmatch(roiName,obj.AnalysisStr{expId}.RoiNames);
                if length(roiInd) < 1,
                    Showtext(obj, sprintf(' Can not find data for %s.',roiName),  'W' ,0);
                    continue;
                end
                if length(roiInd) > 1,
                    Showtext(obj, sprintf(' Too many %s.',roiName),  'W' ,0);
                    continue;
                end
                
                roiExpInd(expId)   = roiInd;
            end
            
            if sum(roiExpInd) < 1,
                Showtext(obj, sprintf(' No valid data for %s.',roiName),  'E' ,0);
                return
            end
            
            for expId = 1:expNum,
                roiInd          = roiExpInd(expId);
                if roiInd < 1, continue; end;
            
                % select data
                roiData            = obj.AnalysisStr{expId}.DffData(:,:,roiInd);
                if figNum < 1, return; end

                figure(figNum + expId),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
                imagesc(roiData',obj.COLOR_LIM);
                title(sprintf('Experiment %s, dF/F Map of %s.',obj.AnalysisStr{expId}.ExpName, roiName),'interpreter','none');
                ylabel('Traces'),xlabel('Time [Frame]')
                colormap(jet)
%                hFig1 = gcf;
%                 % install user click
%                 UD.expId    = expId;
%                 UD.dataCurr = dataCurr;
%                 UD.dataNext = dataNext;
%                 set(hFig1,'UserData',UD,'WindowButtonDownFcn',@(s,e)ShowTraces(obj,s,e));% store new update
                
                
            end
            
            

        end
 
        % ==========================================
        function obj = ShowAveragedTraces(obj, figNum) 
           % ShowAveragedTraces - draws ROI traces for all experiments and avergaes them for all trials 
            % Input:
            %    obj    - this structure
            % Output:
            %    obj   - updated 
            
            if nargin < 2, figNum = 203; end;

            % checks
            if figNum < 1, return; end
            expNonValid = cellfun(@isempty,obj.AnalysisStr);
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            
            % get data averaged
            for expId = 1:expNum,
                if expNonValid(expId),continue; end;
                
                dataRoi  = squeeze(mean(obj.AnalysisStr{expId}.DffData,2));
                namesRoi = obj.AnalysisStr{expId}.RoiNames ;
                nameExp  = obj.AnalysisStr{expId}.ExpName ;
                
            
                % show data
                figure(figNum + expId),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
                imagesc(dataRoi',obj.COLOR_LIM);colormap(jet);
                title(sprintf('Experiment %s, Averaged dF/F Map.',nameExp),'interpreter','none');
                ylabel('ROIs'),xlabel('Time [Frame]')
                % mark ROIs
                showInd         = 1:size(dataRoi,2); %1:decimFactor:roiNum;
                set(gca,'yticklabel',namesRoi,'ytick',showInd(:))
                
            end
            
            

        end

        % ==========================================
        function obj = ShowAveragedTracesFilteredByROI(obj, figNum) 
           % ShowAveragedTracesFilteredByROI - draws ROI traces for all experiments and avergaes them for all trials 
           % asks about ROIs
            % Input:
            %    obj    - this structure
            % Output:
            %    obj   - updated 
            
            if nargin < 2, figNum = 203; end;

            % checks
            if figNum < 1, return; end
            expNonValid = cellfun(@isempty,obj.AnalysisStr);
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data or data is not valid.');
            
            % get all ROIs
            namesRoi     = {};
            for expId = 1:expNum,
                if expNonValid(expId),continue; end;
                namesRoi = union(namesRoi,obj.AnalysisStr{expId}.RoiNames) ;
            end
            
            % ask about selection
            [s,ok] = listdlg('PromptString','Select ROIs :','ListString',namesRoi,'SelectionMode','multiple', 'ListSize',[300 600]);
            if ~ok, return; end;
            namesRoiShow          = namesRoi(s);

            
            
            % get data averaged
            for expId = 1:expNum,
                if expNonValid(expId),continue; end;
                
                namesRoi    = obj.AnalysisStr{expId}.RoiNames ;
                showBool    = ismember(namesRoi,namesRoiShow);
                
                % select
                dataRoi  = squeeze(mean(obj.AnalysisStr{expId}.DffData,2));
                dataRoi  = dataRoi(:,showBool);
                namesRoi = namesRoi(showBool);
                nameExp  = obj.AnalysisStr{expId}.ExpName ;
                
            
                % show data
                figure(figNum + expId),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
                imagesc(dataRoi',obj.COLOR_LIM);colormap(jet);
                title(sprintf('Experiment %s, Averaged dF/F Map.',nameExp),'interpreter','none');
                ylabel('ROIs'),xlabel('Frame [#]')
                % mark ROIs
                showInd         = 1:size(dataRoi,2); %1:decimFactor:roiNum;
                set(gca,'yticklabel',namesRoi,'ytick',showInd(:))
                
            end
            
            

        end
        
        % ==========================================
        function obj = ShowAveragedTracesFilteredByRoiOrderedByCM(obj, figNum) 
           % ShowAveragedTracesFilteredByRoiOrderedByCM - draws ROI traces for all experiments and avergaes them for all trials 
           % compute CM and order by the computed parameter.
            % Input:
            %    obj    - this structure
            % Output:
            %    obj   - updated 
            
            if nargin < 2, figNum = 303; end;

            % checks
            if figNum < 1, return; end
            expNonValid = cellfun(@isempty,obj.AnalysisStr);
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data or data is not valid.');
            
            % get all ROIs
            frameNum     = 0;
            namesRoi     = {};
            for expId = 1:expNum,
                if expNonValid(expId),continue; end;
                namesRoi = union(namesRoi,obj.AnalysisStr{expId}.RoiNames) ;
                frameNum = max(frameNum,size(obj.AnalysisStr{expId}.DffData,1));
            end
            
            % ask about selection
            [s,ok] = listdlg('PromptString','Select ROIs :','ListString',namesRoi,'SelectionMode','multiple', 'ListSize',[300 600]);
            if ~ok, return; end;
            namesRoiShow          = namesRoi(s);

            % ask for frame range  
            frameRange              = [1 frameNum];
            [obj, frameRange]       = SelectFrameRange(obj, frameRange);
            frameInd                = frameRange(1):frameRange(end);
            
            
            % get data averaged
            centerOfMassResults    = {};
            for expId = 1:expNum,
                if expNonValid(expId),continue; end;
                
                namesRoi    = obj.AnalysisStr{expId}.RoiNames ;
                showBool    = ismember(namesRoi,namesRoiShow);
                
                % select
                dataRoi  = squeeze(mean(obj.AnalysisStr{expId}.DffData,2));
                dataRoi  = dataRoi(:,showBool);
                namesRoi = namesRoi(showBool);
                nameExp  = obj.AnalysisStr{expId}.ExpName ;
                dffCenterOfMass     = frameInd * dataRoi(frameInd,:)./(sum(dataRoi(frameInd,:))+eps);
                
                % save
                indNum              = length(centerOfMassResults) + 1;
                centerOfMassResults{indNum}.NamesRoi = namesRoi;
                centerOfMassResults{indNum}.TimesRoi = dffCenterOfMass;
                centerOfMassResults{indNum}.ExpId    = expId;
                centerOfMassResults{indNum}.NameExp  = nameExp;
                
                
                % sort
                [~,sortInd]         = sort(dffCenterOfMass,'ascend');
                dataRoi             = dataRoi(:,sortInd);
                namesRoi            = namesRoi(sortInd);
                
                
            
                % show data
                figure(figNum + expId),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
                imagesc(dataRoi',obj.COLOR_LIM);colormap(jet);
                title(sprintf('Experiment %s, Sorted dF/F Map.',nameExp),'interpreter','none');
                ylabel('ROIs'),xlabel('Time [Frame]')
                % mark ROIs
                showInd         = 1:size(dataRoi,2); %1:decimFactor:roiNum;
                set(gca,'yticklabel',namesRoi,'ytick',showInd(:))
                
            end
            
            save('CenterOfMassResults.mat','centerOfMassResults');
            
            % find intersection of all names
            expNum   = length(centerOfMassResults);
            namesRoi = {};
            for m = 1:expNum,
                % first time init
                if length(namesRoi) < 1, namesRoi    = centerOfMassResults{m}.NamesRoi; end;
                namesRoi        = intersect(namesRoi,centerOfMassResults{m}.NamesRoi) ;
            end
            roiNumTotal         = length(namesRoi);
            
            % collect time into the matrix : arrange by ROI names
            delayFrames         = zeros(expNum,roiNumTotal);
            %roiPosY             = delayFrames;
            lb                  = cell(expNum,1);
            for m = 1:expNum,
                roiNum          = length(centerOfMassResults{m}.NamesRoi);
                roiInd          = zeros(1,roiNum);
                for k = 1:roiNum,
                    [~,roiInd(k)] = ismember(centerOfMassResults{m}.NamesRoi{k},namesRoi);
                end
                %assert(~any(roiInd < 1),'Must all be positive numbers');
                roiInd(roiInd < 1) = [];
                delayFrames(m,:) = centerOfMassResults{m}.TimesRoi(roiInd);
                lb{m}            = centerOfMassResults{m}.NameExp;
                %roiPosY(m,:)     = m;
            end
            roiPosY             = repmat(1:roiNumTotal,expNum,1);

            
            % show all results on the same graph
            figure(figNum + 500),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            plot(delayFrames',roiPosY','-o','MarkerFaceColor','auto');
            legend(lb,'interpreter','none');
            title('ROI Delays')
            set(gca,'yticklabel',namesRoi,'ytick',(1:roiNumTotal)')
            xlabel('Frame [#]')            
            xlim(frameRange),ylim([0 roiNumTotal+1]);
            grid on; axis ij
            

        end
        
        % ==========================================
        function obj = ShowAveragedEventsFilteredByName(obj, figNum) 
           % ShowAveragedEventsFilteredByName - draws Event traces for all experiments and avergaes them for all trials 
           % asks about ROIs
            % Input:
            %    obj    - this structure
            % Output:
            %    obj   - updated 
            
            if nargin < 2, figNum = 203; end;

            % checks
            if figNum < 1, return; end
            expNonValid = cellfun(@isempty,obj.AnalysisStr);
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            
            % get all ROIs
            namesEvents     = {};
            for expId = 1:expNum,
                if expNonValid(expId),continue; end;
                namesEvents = union(namesEvents,obj.AnalysisStr{expId}.EventNames) ;
            end
            
            % ask about selection
            [s,ok] = listdlg('PromptString','Select ROIs :','ListString',namesEvents,'SelectionMode','multiple', 'ListSize',[300 600]);
            if ~ok, return; end;
            namesEventShow          = namesEvents(s);

            
            
            % get data averaged
            for expId = 1:expNum,
                if expNonValid(expId),continue; end;
                
                namesEvents    = obj.AnalysisStr{expId}.EventNames ;
                [showBool,locb] = ismember(namesEvents,namesEventShow);
                
                if ~any(showBool),
                    ShowText(obj,  sprintf('%s : no selected events are found ',obj.AnalysisStr{expId}.ExpName), 'W');
                    continue;
                end
                [s,lb]          = setdiff(namesEventShow,namesEvents);
                for m = 1:length(s),
                    ShowText(obj,  sprintf('%s : Event %s is not found ',obj.AnalysisStr{expId}.ExpName,s{m}),'W');
                end
                
                % select
                dataEvent       = obj.AnalysisStr{expId}.EventData; %squeeze(mean(obj.AnalysisStr{expId}.EventData,2));
                dataEvent       = dataEvent(:,showBool);
                namesEvents     = namesEvents(showBool);
                nameExp         = obj.AnalysisStr{expId}.ExpName ;
                
            
                % show data
                figure(figNum + expId),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
                imagesc(dataEvent',obj.COLOR_LIM);colormap(jet);
                title(sprintf('Experiment %s, All Events.',nameExp),'interpreter','none');
                ylabel('Events'),xlabel('Time [Frame]')
                % mark ROIs
                showInd         = 1:size(dataEvent,2); %1:decimFactor:roiNum;
                set(gca,'yticklabel',namesEvents,'ytick',showInd(:))
                
            end
            
            

        end
        
        % ==========================================
        function obj = ShowTraces(obj,  src, e)
            % ShowTraces - a callback
            % Shows traces on the figure
            hFig = src;
            if ~strcmp(get(src,'SelectionType'),'normal'), return; end;
            %set(src,'pointer','circle')
            cp = get(gca,'CurrentPoint');
            xinit = round(cp(1,1));
            yinit = round(cp(1,2));
            XLim = get(gca,'XLim'); YLim = get(gca,'YLim');        
            % check the point location
            if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
            if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
            
            % estimate where
                        
            UD             = get(hFig,'UserData');
            [nR,nCurrRois] = size(UD.dataCurr);
            [nR,nNextRois] = size(UD.dataNext);
            expId          = UD.expId;
            
%             % check
%             xinit           = max(1,min(nNextRois,xinit));
%             yinit           = max(1,min(nCurrRois,yinit));
            
            
            % extract traces
            if xinit > nCurrRois,
                xinit  = xinit - nCurrRois;
                trace1 = UD.dataNext(:,xinit);
                name1  = sprintf('%s',obj.AnalysisStr{expId}.RoiNames{xinit});
            else
                trace1 = UD.dataCurr(:,xinit);  
                name1  = sprintf('%s',obj.AnalysisStr{expId}.RoiNames{xinit});
            end
            name1 = sprintf('X-%d:%s:',xinit,name1);
            if yinit > nCurrRois,
                yinit  = yinit - nCurrRois;
                trace2 = UD.dataNext(:,yinit);
                name2  = sprintf('%s',obj.AnalysisStr{expId}.RoiNames{yinit});
            else
                trace2 = UD.dataCurr(:,yinit);  
                name2  = sprintf('%s',obj.AnalysisStr{expId}.RoiNames{yinit});
            end
            name2 = sprintf('Y-%d:%s:',yinit,name2);
            
            
            % extract traces
            
            figure(105),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            plot([trace1 trace2]),s = legend(name1,name2); set(s,'interpreter','none');
            title('Selected Traces')
            

            
        end
        
        % ==========================================
        function obj = ShowPositions(obj,  src, e)
            % ShowTraces - a callback
            % Shows traces on the figure
            hFig = src;
            if ~strcmp(get(src,'SelectionType'),'normal'), return; end;
            %set(src,'pointer','circle')
            cp = get(gca,'CurrentPoint');
            xinit = round(cp(1,1));
            yinit = round(cp(1,2));
            XLim = get(gca,'XLim'); YLim = get(gca,'YLim');        
            % check the point location
            if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
            if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
            
            % estimate where
            UD          = get(hFig,'UserData');
            [nCurrRois] = size(UD.dataCurr,1);
            [nNextRois] = size(UD.dataNext,1);
            expId       = UD.expId;
            distData    = obj.AnalysisStr{expId}.DistData;
            
            % check
            yinit       = max(1,min(nCurrRois,yinit));
            xinit       = max(1,min(nNextRois,xinit));
            
            % corr value
            corrValue   = distData(yinit,xinit);
            fprintf('Spatial Selection Value %4.3f : %s - %s\n',corrValue,obj.AnalysisStr{expId}.RoiNames{yinit},obj.AnalysisStr{expId+1}.RoiNames{xinit});
            
            % show on the map
            %if ~isempty(UD.hSelect), delete(UD.hSelect); end;
            %figure(src+1)
            set(UD.hSelect,'xdata',[UD.dataCurr(yinit,1);UD.dataNext(xinit,1)],'ydata',[UD.dataCurr(yinit,2);UD.dataNext(xinit,2)],'Visible','on')
            
            
            
        end
        
        % ==========================================
        function obj = ShowLayer(obj, expId, figNum, zId )
           % ShowLayer - loads single experiment data and shows units in 3D space
            % Input:
            %    obj    - this structure
            %    expId  - which eperiment to show
            %    figNum - on what figure
            %    zId    - which z stack to show
            % Output:
            %    obj   - updated 
            
            if nargin < 2, expId = 1; end;
            if nargin < 3, figNum = 105; end;
            if nargin < 4, zId = [1 2]; end;
            

            % checks
            expNum      = length(obj.AnalysisStr);
            assert(expNum > 0,'First load the experiment data');
            assert(expNum >= expId ,'expId must be less or equal expNum');
            
            % check if load is required
            assert(~isempty(obj.AnalysisStr{expId}),  'Current Experiment data is not loaded');
 
            zNum                = size(obj.AnalysisDepth,2);
            assert(any(0 < zId & zId <= zNum), sprintf('zId must be in range [1:%d]',zNum));
            
            % color coding
            cmap                = jet(expNum*zNum);

            
            % create XYZ data in um
            posXYZ              = obj.AnalysisStr{expId}.PosXYZ;
            
            
            % select appropriate Z indexes and assign depth
            posZ                = zeros(size(posXYZ,1),1);
            for z = 1:zNum,
                if ~any(z == zId), continue; end;
                zBool           = obj.AnalysisStr{expId}.PosXYZ(:,3) == z;
                posXYZ(zBool,3) = obj.AnalysisDepth(expId,z);
                posZ(zBool)     = z;
            end
            % cut the non relevant
            posXYZ              = posXYZ(posZ>0,:);
            posZ                = posZ(posZ>0,:);
            
            % select XY and scale to um
            posXYZ(:,1:2)       = posXYZ(:,1:2)*obj.PIX2UM;
            
            % plot spheres
            %[xS,yS,zS]          = sphere;       
            % plot cylinder
            [xS,yS,zS]          = cylinder(linspace(0,.5,32).^2);       
            [xS,yS,zS]          = deal(xS*3,yS*3,zS*3);

            [xS,yS,zS]          = deal(xS*obj.NEURON2UM,yS*obj.NEURON2UM,zS*obj.NEURON2UM);
            
            figure(figNum),
            if isempty(findobj('Tag','AnalysisROI'))
            set(gcf,'Tag','AnalysisROI','Color','b','Name','Functional Reconstruction'),clf; colordef(gcf,'none');
            end
            hold on;
            for m = 1:size(posXYZ,1),
                s = surfl(xS + posXYZ(m,1),yS+posXYZ(m,2),zS + posXYZ(m,3));
                %set(s,'EdgeColor','none','FaceColor','interp','FaceLighting','phong')
                if posZ(m) == 1,
                    %set(s,'EdgeColor','none','FaceColor',cmap(zNum*(expId-1)+1,:),'FaceLighting','phong')
                    set(s,'EdgeColor','none','FaceColor',[0.7 0.7 0],'FaceLighting','phong')
                else
                    %set(s,'EdgeColor','none','FaceColor',cmap(zNum*(expId-1)+2,:),'FaceLighting','phong')
                    set(s,'EdgeColor','none','FaceColor',[0.7 0.7 0],'FaceLighting','phong')
                end
                %text( posXYZ(m,1)+15, posXYZ(m,2), posXYZ(m,3),obj.AnalysisStr{expId}.RoiNames{m},'FontSize',6)
            end
            hold off;
            axis equal; colormap(cool)
            xlabel('X [um]'),ylabel('Y [um]'),zlabel('Z [um]'),set(gca,'zdir','reverse');
            grid on;
            view(3)
            title('Functional Reconstruction Stack')
            %shading interp
         
        end
        
        % ==========================================
        function obj = ShowText(obj,  txt, severity ,quiet)
            % This manages info display
            
            % Ver    Date     Who  Description
            % ------ -------- ---- -------
            % 01.01  12/09/12 UD   adopted from SMT
            
            if nargin < 2, txt = 'connect';                 end;
            if nargin < 3, severity = 'I';                  end;
            if nargin < 4, quiet = 0;                       end;
            
            if quiet > 0, return; end;
            
            % print to screen
            %NoGUI = 1; %isempty(obj.Handles);
            
            
            if strcmp(severity,'I')
                col = 'k';
            elseif strcmp(severity,'W')
                col = 'b';
            elseif strcmp(severity,'E')
                col = 'r';
            else
                col = 'k';
            end;
            
            if true, %NoGUI,
                fprintf('%s : MEL : %s\n',severity,txt);
                %fprintf('%s',txt);
            else
                set(obj.Handles.textLabel,'string',txt,'ForegroundColor',col);
            end;
            
        end
        
        
    end % show
        
    methods % Test
        
        % ==========================================
        function obj = TestSelect(obj, testType)
            % TestSelect - which test data to use 
            % Input:
            %   testType - which test to run
            % Output:
            %   ExperimentDir - creates directories to align
            
            if nargin < 2, testType    = 1; end;
            
            analysisDir     = {};
            analysisPath    = '';
            
            % params
            switch testType,
                
                case 1, % lab
                    
                    % Latest data ROI data
                    analysisPath           = '\\Jackie-backup\e\Projects\PT_IT\Analysis\D43';
                    analysisDir             = {'9_28_16_1-30','10_16_16_1-33','10_18_16_1-35'};
                    
          
                case 2, % Lab
                    
                    % Latest data ROI data
                    analysisPath           = '\\Jackie-backup\e\Projects\PT_IT\Analysis\D43';
                    analysisDir             = {'10_13_16_1-71','10_16_16_1-33','10_18_16_1-35'};
                    

               case 3, % Lab
                    
                    % Latest data ROI data
                    analysisPath           = 'C:\LabUsers\Uri\Data\Janelia\Analysis\D16';
                    analysisDir             = {'6_24_14_1-15','7_5_14_1-25','7_9_14_1-18','7_15_14_1-46'};
                    
                    
                case 11, % user specified selection
                    
                    dirName             = uigetdir(obj.AnalysisPath,'Select Animal Directory with Many Experiments');
                    if isnumeric(dirName), return; end;  % cancel button  
                    analysisPath        = dirName;
                    
                    dirStr              = dir([analysisPath,'\*_*']);
                    analysisDir         = struct2cell(dirStr);
                    analysisDir         = reshape(analysisDir(1,:),[],1);
                    
                    [s,ok] = listdlg('PromptString','Select Days :','ListString',analysisDir,'SelectionMode','multiple', 'ListSize',[300 500]);
                    if ~ok, return; end;
                    analysisDir          = analysisDir(s);
                    
                case 51, % Uri
                    
                    % Latest data ROI data
                    analysisPath           = 'C:\Uri\DataJ\Janelia\Analysis\D43';
                    analysisDir             = {'9_28_16_1-30','10_16_16_1-33','10_18_16_1-35'};

                case 52, % Uri
                    
                    % Latest data ROI data
                    analysisPath            = 'C:\Uri\DataJ\Janelia\Analysis\D43';
                    dirStr                  = dir([analysisPath,'\*_*']);
                    analysisDir             = struct2cell(dirStr);
                    analysisDir             = reshape(analysisDir(1,:),[],1);
                    analysisDir             = unique(analysisDir); % sort
                    
                    
                otherwise
                    error('Bad testType')
            end
            
            % save
            obj.AnalysisDir             = analysisDir;
            obj.AnalysisPath            = analysisPath;
            
        end
        
        % ==========================================
        function obj = TestSingleLoadTwoPhoton(obj,testType,expId)
            % TestSingleLoadTwoPhoton - single experiment load with TP - OK
            if nargin < 2,             testType  = 1; end;
            if nargin < 3,             expId    = 1; end;
           
            % params
            %testType                    = 1;
            figNum                      = 1;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % check load
            obj                         = LoadSingleExperimentTwoPhoton(obj, expId) ;        
            
        end
        
        % ==========================================
        function obj = TestShowTracesPerROI(obj,testType, figNum)
            % TestShowTracesPerROI - single ROI multiple experiment load - OK
            if nargin < 2,             testType  = 1; end;
            if nargin < 3,             figNum  = 1; end;
           
            % params
            %testType                    = 1;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % load all expertiments
            for expId = 1:length(obj.AnalysisDir), 
                obj                         = LoadSingleExperimentTwoPhoton(obj, expId) ;   
            end
            
            % select ROI
            roiName                     = obj.AnalysisStr{1}.RoiNames{randi(20,1)};
            obj                         = ShowTracesPerROI(obj, roiName, figNum) ;
            
            
        end
        
        % ==========================================
        function obj = TestShowAveragedTraces(obj,testType, figNum)
            % TestShowAveragedTraces - multiple experiment with averaged
            % traces
            if nargin < 2,             testType  = 1; end;
            if nargin < 3,             figNum  = 1; end;
            
            obj                         = Init(obj);
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % load all expertiments
            for expId = 1:length(obj.AnalysisDir), 
                obj                     = LoadSingleExperimentTwoPhoton(obj, expId) ;   
            end
            
            % show
            %obj                         = ShowAveragedTraces(obj,  figNum) ;
            obj                         = ShowAveragedTracesFilteredByROI(obj,  figNum) ;
            
            
        end
        
        % ==========================================
        function obj = TestShowAveragedTracesOrderedByCM(obj,testType, figNum)
            % TestShowAveragedTraces - multiple experiment with averaged
            % traces
            if nargin < 2,             testType  = 1; end;
            if nargin < 3,             figNum  = 1; end;
            
            obj                         = Init(obj);
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % load all expertiments
            for expId = 1:length(obj.AnalysisDir), 
                obj                     = LoadSingleExperimentTwoPhoton(obj, expId) ;   
            end
            
            % show
            obj                         = ShowAveragedTracesFilteredByRoiOrderedByCM(obj,  figNum) ;
            
            
        end
        
        % ==========================================
        function obj = TestSingleLoadBehavioral(obj,testType,expId)
            % TestSingleLoadBehavioral - single experiment load with Behave - OK
            if nargin < 2,             testType  = 1; end;
            if nargin < 3,             expId    = 1; end;
           
            % params
            %testType                    = 1;
            figNum                      = 1;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % check load
            obj                         = LoadSingleExperimentBehavioral(obj, expId) ;        
            
        end
        
        % ==========================================
        function obj = TestShowAveragedEvents(obj,testType, figNum)
            % TestShowAveragedEvents - multiple experiment with averaged
            % events
            if nargin < 2,             testType  = 1; end;
            if nargin < 3,             figNum  = 1; end;
            
            obj                         = Init(obj);
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % load all expertiments
            for expId = 1:length(obj.AnalysisDir), 
                obj                     = LoadSingleExperimentBehavioral(obj, expId) ;   
            end
            
            % show
            %obj                         = ShowAveragedTraces(obj,  figNum) ;
            obj                         = ShowAveragedEventsFilteredByName(obj,  figNum) ;
            
            
        end
        
        

        

    end % methods

end    % EOF..
