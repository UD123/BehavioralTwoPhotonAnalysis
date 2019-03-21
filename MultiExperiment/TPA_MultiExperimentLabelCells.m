classdef TPA_MultiExperimentLabelCells
    % TPA_MultiExperimentLabelCells - Collects TwoPhoton dF/F info of all ROIs from multiple experiments
    % and performs averaging over the trials in the same day.
    % ROIs are mapped and max response is shown
    % Inputs:
    %       TIF Data, TPA_YYY.mat - data base
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 24.08 01.11.16 UD     Adopted for Test
    % 19.30 05.05.15 UD     Functional reconstruction
    % 19.29 01.05.15 UD     Created from Omri Barak TPA_corr2
    %-----------------------------
    properties (Constant)
        %IMAGE_SIZE           = [512 512];  % transform pixels to um
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
        function obj = TPA_MultiExperimentLabelCells()
            % TPA_MultiExperimentPrepareData - constructor
            % Input:
            %    -
            % Output:
            %     default values
            
            obj.AnalysisPath = '\\Jackie-backup\e\Projects\PT_IT\Analysis\D43';
        end
        
        % ==========================================
        function obj = LoadSingleExperiment(obj, expId) 
           % LoadSingleExperiment - loads single experiment data
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
            
            % Load Two Photon & ROI data
            Par                 = TPA_ParInit();
            Par.DMT             = Par.DMT.SelectAllData(analysisDir);
            
            % run on all trials
            for trialind = 1:Par.DMT.ValidTrialNum,
            
                % load data
                [Par.DMT, imTwoPhoton]          = Par.DMT.LoadTwoPhotonData(trialind);
                [Par.DMT, strROI]               = Par.DMT.LoadAnalysisData(trialind,'strROI');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                %SData.strROI                    = strROI;
                if length(strROI) < 1
                    ShowText(obj,  sprintf('Trial %s does no have ROI data',analysisDir), 'W');
                    continue
                end

                % average the data
                if trialind == 1,
                    imgAver                    = repmat(squeeze(mean(imTwoPhoton,4)),[1 1 Par.DMT.ValidTrialNum]);
                else
                    imgAver(:,:,trialind)      = squeeze(mean(imTwoPhoton,4));            
                end
            end
            
            % save
            obj.AnalysisStr{expId}.DMT      = Par.DMT;
            obj.AnalysisStr{expId}.Image    = imgAver;
            obj.AnalysisStr{expId}.StrROI   = strROI;
            obj.AnalysisStr{expId}.ExpName  = obj.AnalysisDir{expId};
            
            % info
            ShowText(obj,  sprintf('%s : Found %d ROIs and %d Video trials ',obj.AnalysisDir{expId},Par.DMT.RoiFileNum,Par.DMT.ValidTrialNum), 'I');


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
                    
                case 61,
                    
                    % Latest data ROI data
                    analysisPath           = 'C:\Uri\DataJ\Janelia\Imaging\M75\';
                    analysisDir             = {'2_21_14'};
                    
                    
                    
                otherwise
                    error('Bad testType')
            end
            
            % save
            obj.AnalysisDir             = analysisDir;
            obj.AnalysisPath            = analysisPath;
            
        end
        
        % ==========================================
        function obj = TestSingleLoad(obj,testType,expId)
            % TestSingleLoad - single experiment load - OK
            if nargin < 2,             testType  = 1; end;
            if nargin < 3,             expId    = 1; end;
           
            % params
            %testType                    = 1;
            figNum                      = 1;
            
            % select a database
            obj                         = TestSelect(obj, testType);
            
            % check load
            obj                         = LoadSingleExperiment(obj, expId) ;        
            
        end
        
        

    end % methods

end    % EOF..
