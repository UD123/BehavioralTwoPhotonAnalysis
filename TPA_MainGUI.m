function TPA_MainGUI
% TPA_MainGUI
% Integrates Behaivior data and  Two Photon Experiments
% and allows ROI extraction and Analysis. It also supports Electro Physiology data and  Two Photon Experiments.

% Important:
% Expected Data Directory Structures for Behavioral experiments:
%    <your path>\Data - directory with all the data
%           Data -> Videos -   all the behavior data
%           Data -> Videos -> m1 -> 01-10-14 -  animal name m1 and experiment data/code
%                          -> m1 -> 03-10-14 -
%                          -> m20 -> 01-11-14 -
%           Data -> Images - all the Two Photon data (must match behavior structure)
%           Data -> Images -> m1 -> 01-10-14 -  animal name m1 and experiment data/code
%                          -> m1 -> 03-10-14 -
%                          -> m20 -> 01-11-14 -
%           Data -> Analysis - contains data analysis results (must match behavior structure)
%           Data -> Analysis -> m1 -> 01-10-14 -  animal name m1 and experiment data/code
%                            -> m1 -> 03-10-14 -
%                            -> m20 -> 01-11-14 -
% Expected Data Directory Structures for Electro Physiology experiments :
%    <your path>\Data - directory with all the data
%           Data -> Images - all the Two Photon data (must match behavior structure)
%           Data -> Images -> m1 -> 01-10-14 -  animal name m1 and experiment data/code
%                          -> m1 -> 03-10-14 - TSeries folders
%                          -> m20 -> 01-11-14 -
%           Data -> Analysis - contains data analysis results (must match behavior structure)
%           Data -> Analysis -> m1 -> 01-10-14 -  animal name m1 and experiment data/code
%                            -> m1 -> 03-10-14 -
%                            -> m20 -> 01-11-14 -


%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% See README.txt
%-----------------------------
% remove any global var if any
clear globals;
clear variables;

% version
currVers    = '29.04';

% connect
%rmpath(genpath('.')); % remove old connections
addpath(genpath('.'));

%%%
% GUI handles
%%%
S            = [];

%%%
% Control params
%%%
global Par;
Par           = TPA_ParInit(currVers);

%%%
% Data struct shared by all
%%%
global SData;
%SData        = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',{},'strManager',struct('roiCount',0,'eventCount',0)); % strManager will manage counters
SData        = TPA_DataManagerMemory();

%%%
% GUI handles visible to all
%%%
% main and all other gui windows required for sync. Contains current user position in 4D space
global SGui     % handle main     handle guis     user clck :x,y,z,t
SGui         = struct('hMain',[],'hChildList',[],'usrInfo',[]); 


% load default user settings
SSave        = struct('ExpDir',pwd,'DMT',[],'DMB',[],'strManager',[]); 
dmExperiment = TPA_ManageExperiment();

%  managers
dmSession   = TPA_ManageSession();
mcObj       = TPA_MotionCorrectionManager();
dmROIAD     = TPA_ManageRoiAutodetect();
dmEVAD      = TPA_ManageEventAutodetect(Par);
%dmFileDir   = TPA_DataManagerFileDir();
dmMTGD      = TPA_MultiTrialGroupDetect();
objTrack    = TPA_OpticalFlowTracking();
%dmED        = TPA_TwoPhotonEventDetect();
dmMultExp   = TPA_MultiExperimentLearning();
dmMTTP      = TPA_MultiTrialTwoPhotonManager();
dmRoiGal    = TPA_ManageRoiAutodetectGal();
dmCDNN      = TPA_MultiTrialBehaviorClassifier();


trajLabeler = [];

% helper for view selection
activeView  = 'side';

%%%
% Start
%%%

% build all the buttons
fSetupGUI();

% load last session
fManageSession(0,0,1);

% Update figure components
fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Start nested functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * save,load and clear current session data
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageSession(hObject, eventdata, selType)
        
        switch selType,
            
            case 1 % load last session
                dmSession           = LoadLastSession(dmSession);               
                
            case 2 % load session user mode
                dmSession           = LoadUserSession(dmSession);

            case 3 % save the session
                 dmSession          = SaveLastSession(dmSession);

            case 4 % save session as...
                dmSession           = SaveUserSession(dmSession);

            case 5 % clear/new session
                dmSession           = TPA_ManageSession();
                % close figures
                fCloseFigures(0,0)    ;
                
            otherwise
                error('Bad session selection %d',selType)
        end
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * sellects and check experiment menu
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageExperiment(hObject, eventdata, selType)
        
        % save session
        %dmSession          = SaveLastSession(dmSession);
        %dmExperiment       = SaveLastExperiment(dmExperiment);
        
        switch selType,
            
            case 1, % select experiment type
                
                dmExperiment = SelectExperimentType(dmExperiment);
                
            case 2, % select directory and load experiment using dir structure
                
                % recall last directory
                [dmSession,dirName]       = SelectDirectory(dmSession);
                if isnumeric(dirName), return; end;  % cancel button
                
                % clear all the data
                SData               = Init(SData);
                dmExperiment        = InitFromDirectory(dmExperiment, dirName);
                
                % check : reread dir structure
                Par.DMT             = Par.DMT.CheckData();
                Par.DMB             = Par.DMB.CheckData();
                
                
                
            case 3, % select directory and data management file to load experiment
                
                % recall last directory
                dmSession           = LoadLastSession(dmSession);
                
                % clear all the data
                SData               = Init(SData);
                dmExperiment        = InitFromManagementFile(dmExperiment, dmSession.ExpDir);
                
                
            case 4, % setup new directories
                
                % recall last directory
                dmSession           = LoadLastSession(dmSession);
                
                % new data, new dirs, create new CSV file
                SData               = Init(SData);
                dmExperiment        = SpecifyDirectories(dmExperiment);
                
            case 5, % Refresh Excel file by selecting directories
                
                % select dir
                [dmSession,dirName]       = SelectDirectory(dmSession);
                if isnumeric(dirName), return; end;  % cancel button
                
                % check
                Par.DMT             = Par.DMT.SelectAllData(dirName);
                Par.DMB             = Par.DMB.SelectAllData(dirName,'all');
                
                
                % check
                Par.DMT             = Par.DMT.CheckData();
                Par.DMB             = Par.DMB.CheckData();
                
                % save to excel
                Par.DMF            = Par.DMF.SaveTableFile(Par);
                
            case 6, % save experiment to excel
                
                Par.DMF           = Par.DMF.SaveTableFile(Par);
                
                
            case 7, % preview current Excel/Csv file
                
                Par.DMF             = Preview(Par.DMF, dmExperiment.ExpDir);
                
            case 8, % load experiment
                
                % new data, new dirs, create new CSV file
                dmExperiment        = LoadLastExperiment(dmExperiment,dmSession.ExpDir);

            case 9, % save experiment
                
                % new data, new dirs, create new CSV file
                dmExperiment        = SaveLastExperiment(dmExperiment, dmSession.ExpDir);
                
            case 15, % check data sync - open GUI
                
                
                % start GUI
                Par                 = TPA_DataAlignmentCheck(Par);
                
                
            otherwise
                error('Bad  selection %d',selType)
        end
        
        % save path
        %dmSession          = SaveLastSession(dmSession);
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * shows and explore behavior image data along with events
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageBehavior(hObject, eventdata, selType)
        
        % Intercept Stimulus
        if isa(Par.DMB,'TPA_DataManagerStimulus'),
            fManageStimulus(hObject, eventdata, selType);
            return
        end
        
        %%%%%%%%%%%%%%%%%%%%%%
        % What
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1, % select and load predefined trial
                
                % select GUI
                [Par.DMB,isOK] = GuiSelectTrial(Par.DMB);            %vis4d(uint8(SData.imTwoPhoton));
                if ~isOK,
                    DTP_ManageText([], 'Behavior : Trial Selection problems', 'E' ,0)   ;                  
                end
                if ~isequal(Par.DMT.Trial,Par.DMB.Trial), 
                    DTP_ManageText([], 'TwoPhoton and Behavior datasets have different trials numbers', 'W' ,0)   ;             
                end
                
                
            case 11,
                % determine data params
                [Par.DMB,isOK] = GuiSetDataParameters(Par.DMB);
                if ~isOK,
                    DTP_ManageText([], 'Behavior : configuration parameters are not updated', 'W' ,0)   ;                  
                end
                
            case 2,
                % Behavior
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                [Par.DMB, SData.imBehaive]      = Par.DMB.LoadBehaviorData(Par.DMB.Trial,'all');
                %DTP_ManageText([], 'Behavior : Two file load Completed.', 'I' ,0)   ;
                [Par.DMB, strEvent]             = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                % this code helps with sequential processing of the ROIs: use old one in the new image
%                 if length(strEvent) > 0 && length(SData.strEvent) > 0,
%                     buttonName                  = questdlg('Would you like to use Event data from previous trial?');  
%                     if ~strcmp(buttonName,'Yes'),  
%                         SData.strEvent          = strEvent;
%                     end;
                if length(strEvent) > 0, % && length(SData.strEvent) < 1,
                        SData.strEvent          = strEvent;
                elseif length(strEvent) < 1 && length(SData.strEvent) > 0,
                        SData.strEvent          = {}; % use none
                        %SData.strEvent = TPA_EventListManager;

                end

                
            case 3,
                % edit XY
                if (Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1) || isempty(SData.imBehaive) ,
                    warndlg('Need to load behavior data first.');
                    return
                end;
                [Par] = TPA_BehaviorEditorXY(Par);
                
            case 4,
                % edit YT
                if ( Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ) || isempty(SData.imBehaive),
                    warndlg('Need to load behavior data first.');
                    return
                end;
                [Par] = TPA_BehaviorEditorYT(Par);
 
                
%            case 5,
%                 % edit YT
%                 if ( Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ) || isempty(SData.imBehaive),
%                     warndlg('Need to load behavior data first.');
%                     return
%                 end;
%                 if length(SData.strEvent) < 1,
%                     warndlg('Need to mark behavior data first.');
%                     return
%                 end;
%                     
%                 % start save
%                 Par.DMB     = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'strEvent',SData.strEvent);

                
           case 6
                % Next Trial Full load
                
                % close previous
                hFigLU = findobj('Name','4D : Behavior Time Editor');    
                if ~isempty(hFigLU), close(hFigLU); end
                hFigRU = findobj('Name','4D : Behavior Image Editor');    
                if ~isempty(hFigRU), close(hFigRU); end
                
                % set new trial
                trialInd            = Par.DMB.Trial + 1;
                [Par.DMB,isOK]      = Par.DMB.SetTrial(trialInd);
                
                % load Image, Events
                fManageBehavior(0, 0, 2);

                % Preview
                fManageBehavior(0, 0, 3);
                fManageBehavior(0, 0, 4);
                
                % Arrange
                fArrangeFigures();
                
          case 21
                % Behavioral data compression
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end
                buttonName = questdlg('Current trial Behaivioral Video data will be changed.', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                Par.DMB           = Par.DMB.CompressBehaviorData(Par.DMB.Trial,'all');
                
          case 22
                % Behavioral data check
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end
                
                Par.DMB           = Par.DMB.CheckImageData(SData.imBehaive);
                
          case 31
              
                % Behavioral data check
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end
                
                % try to load the analysis data
                [Par.DMT, SData.strROI]                 = LoadAnalysisData(Par.DMT,Par.DMB.Trial,'strROI');
                if Par.DMB.Trial ~= Par.DMT.Trial,
                    warndlg('Behavior and Two Photon data must have the same trial numbers. Please select the same Trial and load the data after that.');
                    return
                end;
                
                mngrOverlay     = TPA_BehaviorTwoPhotonOverlay();
                mngrOverlay     = ShowInit(mngrOverlay, Par.DMB.Trial);
                %mngrOverlay     = Overlay(mngrOverlay);
                mngrOverlay     = OverlayColor(mngrOverlay);
                mngrOverlay     = ShowFinal(mngrOverlay);
                
          case 41,
              
                % Behavioral data check
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end
                if isempty(SData.imBehaive)
                    warndlg('Please load the Behavioral Data');
                    return
                end
                if isempty(SData.strEvent)
                    [Par.DMB, SData.strEvent]    = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                end
                if length(SData.strEvent)<1
                    warndlg('Please create ROI for Behavioral Data');
                    return
                end
                
                mngrAnalys              = TPA_BehaviorAnalysis();
                mngrAnalys              = ExternalAnalysis(mngrAnalys,SData.imBehaive,SData.strEvent);
                [mngrAnalys,strEvent]   = ExportEvents(mngrAnalys);
                                
                
                % save
                SData.strEvent          = strEvent;
                Par.DMB                 = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'strEvent',SData.strEvent);

                
            otherwise
                errordlg('Unsupported Type')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * shows and explore stimulus data from Prarie system
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageStimulus(hObject, eventdata, selType)
        
        % What
        switch selType,
            case 1, % select and load predefined trial
                
                % select GUI
                [Par.DMB,isOK] = GuiSelectTrial(Par.DMB);            %vis4d(uint8(SData.imTwoPhoton));
                if ~isOK,
                    DTP_ManageText([], 'Stimulus : Trial Selection problems', 'E' ,0)   ;                  
                end
                if ~isequal(Par.DMT.Trial,Par.DMB.Trial), 
                    DTP_ManageText([], 'TwoPhoton and Behavior datasets have different trials numbers', 'W' ,0)   ;             
                end
                
                
            case 11, % determine data params
                [Par.DMB,isOK] = GuiSetDataParameters(Par.DMB);
                if ~isOK,
                    DTP_ManageText([], 'Stimulus : configuration parameters are not updated', 'W' ,0)   ;                  
                end
                
            case 2,  % Behavior
                if Par.DMB.VideoFileNum < 1 ,
                    warndlg('Stimulus is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                Par.DMB                         = Par.DMB.LoadStimulusData(Par.DMB.Trial);
                %DTP_ManageText([], 'Behavior : Two file load Completed.', 'I' ,0)   ;
                [Par.DMB, strEvent]             = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                % this code helps with sequential processing of the ROIs: use old one in the new image
%                 if length(strEvent) > 0 && length(SData.strEvent) > 0,
%                     buttonName                  = questdlg('Would you like to use Event data from previous trial?');  
%                     if ~strcmp(buttonName,'Yes'),  
%                         SData.strEvent          = strEvent;
%                     end;
                if length(strEvent) > 0, % && length(SData.strEvent) < 1,
                        SData.strEvent          = strEvent;
                elseif length(strEvent) < 1 && length(SData.strEvent) > 0,
                        SData.strEvent          = {}; % use none
                        %SData.strEvent = TPA_EventListManager;

                end
                
                % show Record data
                Par.DMB           = Par.DMB.ShowRecordData(201);                

                
            case 3,
                return
                % edit XY
                
            case 4,
                return
                % edit YT
                
           case 6,
                % Next Trial Full load
                return
                 
          case 21,
                % Behavioral data compression
                
          case 22,
                % Behavioral data check
                if Par.DMB.VideoFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                
                Par.DMB           = Par.DMB.ShowRecordData(201);
                
          case 31,
                return                
                
                
            otherwise
                errordlg('Unsupported Type')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Manages event data for analysis
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageEvent(hObject, eventdata, selType)
        %
        %%%%%%%%%%%%%%%%%%%%%%
        % Init
        %%%%%%%%%%%%%%%%%%%%%%
        %Par       = TPA_ParInit;
        %FigNum    = Par.FigNum; % 0-no show 1-shows the image,2-line scans
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Check Event actions
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1,   % load previous
                [csFilenames, sPath] = uigetfile( ...
                    { ...
                    '*.xls', 'xls Files'; ...
                    '*.mat', 'mat Files'; ...
                    '*.*', 'All Files'}, ...
                    'OpenLocation'  , Par.DMB.EventDir, ...
                    'Multiselect'   , 'off');
                
                if isnumeric(sPath), return, end;   % Dialog aborted
                
                % if single file selected
                if iscell(csFilenames)
                    csFilenames = csFilenames{1};
                end;
                try
                userDataFileName    = fullfile(sPath,csFilenames);
                load(userDataFileName,'strEvent');
                SData.strEvent       = strEvent;
                catch ex
                        errordlg(ex.getReport('basic'),'File Type Error','modal');
                end
                
            case 2, % new
                
                buttonName = questdlg('All the previous Event data in the current trial will be lost', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                SData.strEvent        = {};
                %SData.strEvent          = TPA_EventListManager;

                
            case 3,       % save
%                 if Par.DMB.BehaviorNum < 1 ,
%                     warndlg('Please select Trial and load the Behavior image data first.');
%                     return
%                 end;
                
                % start save
                Par.DMB                     = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'strEvent',SData.strEvent);
                
            case 4,    % load
                [Par.DMB,SData.strEvent]   = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                

            case 5, % NA
                return
                
            case 11, % Init
                dmEVAD          = DeleteData(dmEVAD);
                dmEVAD          = InitClassifier(dmEVAD);
                
            case 12, % Load
                
                % load SSave structure
                fManageExperiment(0,0,2);
                dmEVAD.ClassPrm = SSave.StrEventClass;
                
             case 13, % Save
                
                % save to SSave structure
                SSave.StrEventClass = dmEVAD.ClassPrm;
                fManageExperiment(0,0,8);
                
            case 14, % Traing on current event data
                
                % test init behavior
                if Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                
                % close all figures - will prevent event data sync problem
                fCloseFigures();
                
                % determine if we have current event info
                if length(SData.strEvent) < 1,
                    [Par.DMB,SData.strEvent]   = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                    [Par.DMB, SData.imBehaive] = Par.DMB.LoadBehaviorData(Par.DMB.Trial,'side');
                else
                   % Par.DMB                    = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'StrEvent',SData.strEvent);
                end
                
                % convert Image and Event data to classifier format
                dmEVAD          = SetImageData(dmEVAD,SData.imBehaive);
                dmEVAD          = ConvertImageToFeatures(dmEVAD);                
                dmEVAD          = ConvertEventToClass(dmEVAD,SData.strEvent);
                dmEVAD          = TrainClassifier(dmEVAD);
                
            case 15, % Train on all previous data
                
                % set new trial
                for trialInd = 1:Par.DMB.Trial, %Par.DMB.EventFileNum,
                    
                    % prevent old data ask question
                    SData.strEvent      = {};
                    %SData.strEvent = TPA_EventListManager;

                
                    % set trial
                    [Par.DMB,isOK]      = Par.DMB.SetTrial(trialInd);
                
                    % load Image, Events
                    fManageBehavior(0, 0, 2);
                
                    % classify
                    fManageEvent(0,0,14);
                end
                
            case 16, % Classify current trial
                %dmEVAD          = DeleteData(dmEVAD);
                %dmEVAD          = InitClassifier(dmEVAD);
                dmEVAD                  = SetImageData(dmEVAD,SData.imBehaive);
                dmEVAD                  = ConvertImageToFeatures(dmEVAD);                
                dmEVAD                  = TestClassifier(dmEVAD);
                [dmEVAD,strEventEst]    = ConvertClassToEvent(dmEVAD);
                % Preview
                SData.strEvent          = strEventEst;
  
            case 20 % Update params for trajectories - KLT Optical Flow
                
                % assume object is initialized                
                objTrack    = SetParameters(objTrack);

                % which view
                viewNames = {'side','front'};
                [s,ok] = listdlg('PromptString','Select View for Trajectory Analysis :','ListString',viewNames,'SelectionMode','single','ListSize',[400 500]);
                if ~ok, return; end;
                activeView  = viewNames{s};
                
                % which ROI
                % load
                [Par.DMB,SData.strEvent]   = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                
                % MARIA IS WORKING ON DECIMATED DATA - INLCUDING ROIS
                decimFactor                 = 1; % Par.DMB.DecimationFactor(1);
                objTrack                    = SetTrajectoriesForROI(objTrack, SData.strEvent,decimFactor);
                
                
                DTP_ManageText([], 'Behavior : Track parameters are updated.', 'I' ,0)   ;   
                
                
            case 21, % Find trajectories - KLT Optical Flow
                
%                 if verLessThan('matlab', '8.4.0'), 
%                     errordlg('This function requires Matlab R2014b'); 
%                     return; 
%                 end;

                
                % test init behavior
                if Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                
                % determine if we have current event info
                if isempty(SData.imBehaive),
                    [Par.DMB, SData.imBehaive] = Par.DMB.LoadBehaviorData(Par.DMB.Trial,'all');
                end
                
                % Init Tracking algorithm 
                objTrack            = TrackBehavior(objTrack, activeView);

                
            case 22 % Filtered
                
                objTrack            = ShowLinkage(objTrack, true);

            case 23 % Show Average
                
                objTrack            = ShowAverage(objTrack);
                
            case 24 % Show Volume
                
                objTrack            = ShowVolume(objTrack);
         
            case 25 % Save Event 
                
                % load
                [Par.DMB,SData.strEvent]   = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                %SData.strEvent              = {}; %TPA_EventListManager;
                
                % create event structure from tracking data
                [objTrack,trackPos]         = GetAverageTrack(objTrack);
                newEvent                    = TPA_EventManager;
                newEvent.Name               = sprintf('EV:%s:AverTrajX',activeView);
                newEvent.Data               = trackPos(:,2); 
                len                         = length(SData.strEvent)+1;
                SData.strEvent{len}         = newEvent;
                
                newEvent                    = TPA_EventManager;
                newEvent.Name               = sprintf('EV:%s:AverTrajY',activeView);
                newEvent.Data               = trackPos(:,3);  
                len                         = length(SData.strEvent)+1;
                SData.strEvent{len}         = newEvent;
                
                % start save
                Par.DMB                     = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'strEvent',SData.strEvent);
                
            case 26 % Set ROI for trajectories
                
                % load
                [Par.DMB,SData.strEvent]   = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                
                % MARIA IS WORKING ON DECIMATED DATA - INLCUDING ROIS
                decimFactor                 = 1; % Par.DMB.DecimationFactor(1);
                objTrack                    = SetTrajectoriesForROI(objTrack, SData.strEvent,decimFactor);
                
 
           case 31 % Manual trajectory labeler
                               
                trajLabeler                  = TPA_TrajectoryLabeler();
                
           case 32 % Save trajectory labeler data as event
               
                % load
                [Par.DMB,SData.strEvent]   = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                               
                if length(SData.strEvent) > 0
                buttonName = questdlg('Previous Behaivioral Event data is found. Would you like?', 'Warning','Cancel','Merge','Overwrite','Cancel');
                if strcmp(buttonName,'Cancel'), return; end
                if strcmp(buttonName,'Overwrite'), SData.strEvent = {}; end
                end
                
                roiNum                     = trajLabeler.GetRoiNum();
                for m = 1:roiNum
                    roiPos                 = trajLabeler.GetRoiPosition(m);
                    roiName                = trajLabeler.GetRoiName(m);
                
                    % create event structure from tracking data
                    newEvent{1}             = TPA_EventManager;
                    newEvent{1}.Name        = sprintf('TX:%s',roiName);
                    newEvent{1}.Data        = roiPos(:,1)./400; 
                    newEvent{2}             = TPA_EventManager;
                    newEvent{2}.Name        = sprintf('TY:%s',roiName);
                    newEvent{2}.Data        = roiPos(:,2)./400; 
                
                    % assign and save
                    SData.strEvent          = cat(1,SData.strEvent(:),newEvent(:));
                end
                
                % start save
                Par.DMB                     = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'strEvent',SData.strEvent);
        
        end
        
        
        %%%
        % Save Event do not ask
        %%%
       % Par.DMB            = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'StrEvent',SData.strEvent);
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * shows and explore two photon image data. fix some artifacts
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageTwoPhoton(hObject, eventdata, selType)
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1, % selection
                
                [Par.DMT,isOK]              = GuiSelectTrial(Par.DMT);            %vis4d(uint8(SData.imTwoPhoton));
                if ~isOK,
                    DTP_ManageText([], 'TwoPhoton : trial selection failed', 'E' ,0)   ;                  
                end
                if ~isequal(Par.DMT.Trial,Par.DMB.Trial), 
                    DTP_ManageText([], 'TwoPhoton and Behavior datasets have different trials numbers', 'W' ,0)   ;             
                end
                
                
            case 11,
                % determine data params
                [Par.DMT,isOK]              = GuiSetDataParameters(Par.DMT);
                if ~isOK,
                    DTP_ManageText([], 'TwoPhoton : configuration parameters are not updated', 'W' ,0)   ;                  
                end
                
            case 2,
                % TwoPhoton
                if Par.DMT.VideoFileNum < 1,
                    warndlg('Two Photon data is not selected or there are problems with load. Please select Trial and load the data after that.');
                    return
                end;
                % load
                [Par.DMT, SData.imTwoPhoton]      = Par.DMT.LoadTwoPhotonData(Par.DMT.Trial);
                [Par.DMT, strROI]                 = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strROI');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                %SData.strROI                    = strROI;
                if length(SData.strROI) > 0,
                    buttonName                  = questdlg('Would you like to use ROI data from previous trial?');  
                    if ~strcmp(buttonName,'Yes'),  
                        SData.strROI          = strROI;
                    end;
                elseif length(strROI) > 0 && length(SData.strROI) < 1,
                        SData.strROI          = strROI;
                elseif length(strROI) < 1 && length(SData.strROI) > 0,
                        %SData.strEvent          = strEvent; % use previous
                end
                
                % apply shift
                [Par.DMT, strShift]               = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strShift');
                [Par.DMT, SData.imTwoPhoton]      = Par.DMT.ShiftTwoPhotonData(SData.imTwoPhoton,strShift);
                
            case 3,
                % preview XY
                if Par.DMT.VideoFileNum < 1 || isempty(SData.imTwoPhoton),
                    warndlg('Need to load Two Photon data first.');
                    return
                end;
                %TPA_ImageViewer(SData.imTwoPhoton);
                %TPA_TwoPhotonEditorXY(SData.imTwoPhoton);
                %Par             = TPA_TwoPhotonEditorXY(Par);
                TPA_TwoPhotonEditorXY();  % Par is global
                
           case 4,
                % preview YT
                if Par.DMT.VideoFileNum < 1 || isempty(SData.imTwoPhoton),
                    warndlg('Need to load Two Photon data first.');
                    return
                end;
                Par             = TPA_TwoPhotonEditorYT(Par);
                
           case 5,
                % Next Trial Full load
                
                % close previous
                hFigLU = findobj('Name','4D : TwoPhoton Time Editor');    
                if ~isempty(hFigLU), close(hFigLU); end;
                hFigRU = findobj('Name','4D : TwoPhoton Image Editor');    
                if ~isempty(hFigRU), close(hFigRU); end;
                
                % set new trial
                trialInd            = Par.DMT.Trial + 1;
                [Par.DMT,isOK]      = Par.DMT.SetTrial(trialInd);
                
                % load Image, Shifts, ROI
                fManageTwoPhoton(0, 0, 2);

                % Preview
                fManageTwoPhoton(0, 0, 3);
                fManageTwoPhoton(0, 0, 4);
                
                % Arrange
                fArrangeFigures();
                
                
             otherwise
                errordlg('Unsupported Type')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Image registration :  fix some artifacts
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageRegistration(hObject, eventdata, selType)
        
        
        % preview XY
        if Par.DMT.VideoFileNum < 1 || isempty(SData.imTwoPhoton),
            warndlg('It is better to work on image data. Would you like to load Two Photon data first.');
            return
        end;
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
                
            case 1,
                % motion correction Janelia Style with template : parfor based
                % !!! need no copy that data
%                 mcObj                   = mcObj.SetData(SData.imTwoPhoton);
%                 % run algo :  
%                 templateType            = 5;
%                 [mcObj,estShift]        = mcObj.AlgImageBox(templateType); 
                [mcObj,estShift]        = AlgApply(mcObj, SData.imTwoPhoton ,1);              
                
                % save shift
                [Par.DMT, usrData]      = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strShift',estShift);
                
                figNum                  = Par.FigNum + selType;
                mcObj.CheckResult(figNum, estShift*0, estShift);   
                
                

           case 2,
                % motion correction Janelia Style with template but using FFT without parfor
                % !!! need no copy that data
%                 mcObj                   = mcObj.SetData(SData.imTwoPhoton);
%                 % run algo : 
%                 templateType            = 5;
%                 [mcObj,estShift]        = mcObj.AlgImageBoxFast(templateType);  
                [mcObj,estShift]        = AlgApply(mcObj, SData.imTwoPhoton ,2);              

                % save shift
                [Par.DMT, usrData]      = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strShift',estShift);
                
                figNum                  = Par.FigNum + selType;
                mcObj.CheckResult(figNum, estShift*0, estShift);   
                
           case 3,
                % motion correction Inverse Style No template No parfor
                % !!! need not to copy that data
%                 mcObj                   = mcObj.SetData(SData.imTwoPhoton);
%                 % run algo :  
%                 [mcObj,estShift]        = mcObj.AlgUriRegisterFast(1); 
                [mcObj,estShift]        = AlgApply(mcObj, SData.imTwoPhoton ,3);              

                % save shift
                [Par.DMT, usrData]      = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strShift',estShift);
                
                figNum                  = Par.FigNum + selType;
                mcObj.CheckResult(figNum, estShift*0, estShift);  
                
         case 4,
                % 3 Time run of the imagebox
%                 mcObj                   = mcObj.SetData(SData.imTwoPhoton);
%                 % run algo : 
%                 [mcObj,estShift]        = mcObj.AlgMultipleImageBox(3);
                [mcObj,estShift]        = AlgApply(mcObj, SData.imTwoPhoton ,4);              
                
                
                figNum                  = Par.FigNum + selType;
                mcObj.CheckResult(figNum, estShift*0, estShift);   
                
                % save shift
                [Par.DMT, usrData]      = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strShift',estShift);
                
                DTP_ManageText([], 'TwoPhoton : image has been ImageBox motion corrected 3 times', 'W' ,0)   ;                  
                   

          case 5,
                % motion correction Video Show
                %mcObj                 = mcObj.SetData(SData.imTwoPhoton);
                % check is done in video player
                
                % run player :  
                mcObj.ViewVideo();                
                
                % get fixed video
                %[mcObj,SData.imTwoPhoton]    = mcObj.GetData();                
                 
           case 6,
                % substitute data and clean the rest
                buttonName = questdlg('Switching to the corrected image data. To undo you nead to reload your dataset.');  
                if ~strcmp(buttonName,'Yes'), return; end;
                
                % apply shift
                [Par.DMT, strShift]             = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strShift');
                [Par.DMT, SData.imTwoPhoton]    = Par.DMT.ShiftTwoPhotonData(SData.imTwoPhoton,strShift);
                
                mcObj                           = mcObj.DeleteData();
                
           case 7,
                % clean previous reg results
                % save shift
                [Par.DMT, usrData]              = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strShift',[]);
                DTP_ManageText([], 'TwoPhoton : registration data has been cleared. Please reload the raw data.', 'W' ,0)   ;                  
                
           case 8,
                % drop frames from Registration process - overcome some equipment artifacts
                isOK                = false; % support next level function
                options             = struct('Resize','on','WindowStyle','modal','Interpreter','none');
                prompt              = {sprintf('Enter frame numbers to skip between %d:%d',1,Par.DMT.VideoFileNum)};
                name                = 'Artifact Correction : Ignore frame numbers from registration';
                numlines            = 1;
                defaultanswer       = {num2str(1)};
                answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
                if isempty(answer), return; end;
                ignoreInd           = str2num(answer{1});
                
                % check if valid
                if any(ignoreInd<1) || any(ignoreInd > Par.DMT.VideoFileNum),
                    DTP_ManageText([], 'TwoPhoton : Please provide frame indexes in the valid range.', 'E' ,0)   ; 
                    return
                end
                % take first frame that could be replicated to all
                cI                  = setdiff(1:Par.DMT.VideoFileNum,ignoreInd);
                if isempty(cI),
                    DTP_ManageText([], 'TwoPhoton : Bad frame indexes -  something terrible worng.', 'E' ,0)   ; 
                    return
                end
                % replicate
                for m = 1:numel(ignoreInd)
                    SData.imTwoPhoton(:,:,:,ignoreInd(m)) = SData.imTwoPhoton(:,:,:,cI(1));
                    DTP_ManageText([], sprintf('TwoPhoton : Frame %d is filled by Frame %d.',ignoreInd(m),cI(1)), 'I' ,0)   ; 
                end
               
            otherwise
                errordlg('Unsupported Type')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * load/draw/manage ROIs for analysis
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageROI(hObject, eventdata, selType)
        %
        %%%%%%%%%%%%%%%%%%%%%%
        % Init
        %%%%%%%%%%%%%%%%%%%%%%
        %Par       = TPA_ParInit;
        FigNum    = Par.FigNum; % 0-no show 1-shows the image,2-line scans
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Load Roi
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1
                
                [csFilenames, sPath] = uigetfile( ...
                    { ...
                    '*.mat', 'Mat Files'; ...
                    '*.*', 'All Files'}, ...
                    'OpenLocation'  , Par.DMT.RoiDir, ...
                    'Multiselect'   , 'off');
                
                if isnumeric(sPath), return, end;   % Dialog aborted
                
                % if single file selected
                if iscell(csFilenames)
                    csFilenames = csFilenames{1};
                end;
                
                try
                userDataFileName    = fullfile(sPath,csFilenames);
                load(userDataFileName,'strROI');
                SData.strROI        = strROI;
                catch ex
                        errordlg(ex.getReport('basic'),'File Type Error','modal');
                end
                DTP_ManageText([], sprintf('TwoPhoton : Loaded ROIs from file %s.',csFilenames), 'I'); 
                
            case 2 % new
                
                buttonName = questdlg('All the previous ROI data will be lost', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                SData.strROI        = {};
                % start save
                Par.DMT                 = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strROI',SData.strROI);                
                
            case 3
                % save
%                 if Par.DMT.TwoPhotonNum < 1 ,
%                     warndlg('Please select Trial and load the Behavior image data first.');
%                     return
%                 end;
                
                % start save
                Par.DMT                 = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strROI',SData.strROI);                
                
            case 4
                % Load
                [Par.DMT,SData.strROI]     = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strROI');
                
                
            case 5 % Load from specific File and Z stack
                
                [csFilenames, sPath] = uigetfile( ...
                    { ...
                    '*.mat', 'Mat Files'; ...
                    '*.*', 'All Files'}, ...
                    'OpenLocation'  , Par.DMT.RoiDir, ...
                    'Multiselect'   , 'off');
                
                if isnumeric(sPath), return, end;   % Dialog aborted
                
                % if single file selected
                if iscell(csFilenames),   csFilenames = csFilenames{1};   end;
                
                try
                    userDataFileName    = fullfile(sPath,csFilenames);
                    load(userDataFileName,'strROI');
                catch ex
                        errordlg(ex.getReport('basic'),'File Type Error','modal');
                end
   
                % filter by Z - stack
                [Par.DMT, strROI]      = LoadRoiData(Par.DMT, strROI );
                SData.strROI           = cat(2,SData.strROI,strROI);
           
                            
%             case 6, % N.A.
%                 % Auto Detect of ROIs
%                 buttonName = questdlg('All the previous ROI data will be lost', 'Warning');
%                 if ~strcmp(buttonName,'Yes'), return; end;
%                 
%                 
%                 dmROIAD                 = SetImgData(dmROIAD,SData.imTwoPhoton);
%                 dmROIAD                 = SegmentSpaceTime(dmROIAD, 11);
%                 dmROIAD                 = PlayImgDFF(dmROIAD);
%                 [dmROIAD,SData.strROI]  = ExtractROI(dmROIAD);
%                 dmROIAD                 = DeleteData(dmROIAD);
%                 
%                 % update counters and save
%                 SData.strManager.roiCount = length(SData.strROI);
%                 fManageJaneliaExperiment(0,0,3); 
%                 
%                 % open viewer
%                 Par                     = TPA_TwoPhotonEditorXY(Par);
%                 
%            case 6,
                % preview mode only
%                 tmpFigNum               = FigNum + 5;
%                 Par                     = TPA_PreviewROI(Par,SData.imTwoPhoton,SData.strROI,tmpFigNum);
%                 return
                
                
%             case 11,
%                 % Auto Detect of ROI - Soft Options
%                 
%                 dmROIAD                 = SetData(dmROIAD,SData.imTwoPhoton);
%                 dmROIAD                 = SegmentSpaceTime(dmROIAD,1);
%                 dmROIAD                 = PlayImgDFF(dmROIAD);
% 
%             case 12,
%                 % Auto Detect of ROI - Soft Options
%                 
%                 dmROIAD                 = SetData(dmROIAD,SData.imTwoPhoton);
%                 dmROIAD                 = SegmentSpaceTime(dmROIAD,2);
%                 dmROIAD                 = PlayImgDFF(dmROIAD);
%                 
%             case 13,
%                 % Auto Detect of ROI - Soft Options
%                 
%                 dmROIAD                 = SetData(dmROIAD,SData.imTwoPhoton);
%                 dmROIAD                 = SegmentSpaceTime(dmROIAD,3);
%                 dmROIAD                 = PlayImgDFF(dmROIAD);
                
           case 10
                % Init & Set Parameters 
                dmROIAD                 = Configure(dmROIAD);
                %Par.Roi.UseEffectiveROI = dmROIAD.UseEffectiveROI;

           case 11
                % Use Functional dF/F for segmentation
                %dmROIAD                 = TPA_ManageRoiAutodetect();
                dmROIAD                 = SetImgData(dmROIAD,SData.imTwoPhoton);
                %dmROIAD                 = SetRoiData(dmROIAD,SData.strROI);
                %dmROIAD                 = SegmentSortingFunctional(dmROIAD,81);
                dmROIAD                 = SegmentSpatialAdaptiveThreshold(dmROIAD);
                dmROIAD                 = ExtractROI(dmROIAD,77);

           case 12
                % Use Only spatial fluorescence for segmentation
                %dmROIAD                 = TPA_ManageRoiAutodetect();
                dmROIAD                 = SetImgData(dmROIAD,SData.imTwoPhoton);
                %dmROIAD                 = SetRoiData(dmROIAD,SData.strROI);
                %dmROIAD                 = SegmentSortingSpatial(dmROIAD,91);
                %dmROIAD                 = SegmentSortingSpatialXY(dmROIAD,91);
                %dmROIAD                 = SegmentByVoting(dmROIAD,91);
                dmROIAD                 = SegmentSpatialAdaptiveThreshold(dmROIAD);
                %dmROIAD                 = SegmentSortingMinmal(dmROIAD,91);
                dmROIAD                 = ExtractROI(dmROIAD,78);
                
%             case {13,14}, % Not in use
%                 % Auto Detect of ROI - Soft Options
%                 
%                 dmROIAD                 = SetImgData(dmROIAD,SData.imTwoPhoton);
%                 dmROIAD                 = SegmentSpaceTime(dmROIAD,4);
%                 dmROIAD                 = PlayImgDFF(dmROIAD);
%                 
%             case 15,
%                 % Replay with Original
%                 dmROIAD                 = PlayImgOverlay(dmROIAD);
                
            case 16
                % Display ROIs and Effective One
                %dmROIAD                 = SetImgData(dmROIAD,SData.imTwoPhoton);
                %dmROIAD                 = SetRoiData(dmROIAD,SData.strROI);
                dmROIAD                 = ShowRois(dmROIAD);
                
                            
            case 17
                
                strROI                 = GetRoiData(dmROIAD);
                if isempty(strROI)
                    warndlg(sprintf('AutoDetect : ROI is not created. Please run the process again.')); return;
                end
                
                % Ask about event data
                doMerge = false;
                if length(SData.strROI) > 0
                buttonName = questdlg('Previous Two Photon ROI data is found. Would you like?', 'Warning','Cancel','Merge','Overwrite','Cancel');
                if strcmp(buttonName,'Cancel'), return; end
                % check if merge is required
                doMerge = strcmp(buttonName,'Merge');
                end
                
                if doMerge
                    SData.strROI           = cat(1,SData.strROI(:),strROI(:));
                else
                    SData.strROI           = strROI;
                end


                %Par.Roi.UseEffectiveROI = true;        % override user ROI contour by effective one
                
                DTP_ManageText([], sprintf('AutoDetect : Use Two Photon -> ROI -> to remember the effective ROI computations.'), 'I');
                %dmROIAD                 = Init(dmROIAD);
                            


           case 21
                % Init & Set Parameters 
                dmRoiGal                 = Configure(dmRoiGal);

           case 22
                % load data
                dmRoiGal                 = LoadImageData(dmRoiGal,Par.DMT);

           case 23
                % Time Ferq Analysis
                dmRoiGal                 = SegmentSpaceTime(dmRoiGal);

            case 24
                % export ROIs
                [dmRoiGal,strROI]            = ExtractROI(dmRoiGal,121);
                %strROI                 = GetRoiData(dmRoiGal);
                if isempty(strROI)
                    warndlg(sprintf('AutoDetect : ROI is not created. Please run the process again.')); return;
                end
                
                % Ask about event data
                doMerge = false;
                if length(SData.strROI) > 0
                buttonName = questdlg('Previous Two Photon ROI data is found. Would you like?', 'Warning','Cancel','Merge','Overwrite','Cancel');
                if strcmp(buttonName,'Cancel'), return; end
                % check if merge is required
                doMerge = strcmp(buttonName,'Merge');
                end
                
                if doMerge
                    SData.strROI           = cat(1,SData.strROI(:),strROI(:));
                else
                    SData.strROI           = strROI;
                end


                %Par.Roi.UseEffectiveROI = true;        % override user ROI contour by effective one
                
                DTP_ManageText([], sprintf('AutoDetect : Use Two Photon -> ROI -> to remember the effective ROI computations.'), 'I');

            otherwise
                error('Bad Selection')
        end
        
        %%%
        % Save ROI do not ask
        %%%
        %Par.DMT            = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'StrROI',SData.strROI);
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * ROI averaging
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fAnalysisROI(hObject, eventdata, selType)
        %
        %%%%%%%%%%%%%%%%%%%%%%
        % Init
        %%%%%%%%%%%%%%%%%%%%%%
        %Par       = TPA_ParInit;
        %Par.RoiAverageType = 'LineOrthog'; % see DTP_ComputeROI
        
        switch selType,
            case {1,2,3,4},
                % Averaging
                tmpFigNum               = Par.Debug.AverFluorFigNum; %Par.FigNum + 50;
                [Par,SData.strROI]      = TPA_AverageMultiROI(Par,SData.strROI,tmpFigNum);
            case 5, 
            otherwise
                errordlg('Unsupported Case for Par.Roi.AverageType')
        end;
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Do Averaging
        %%%%%%%%%%%%%%%%%%%%%%
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Removes Artifacts from Average values of the channels
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fArtifactsROI(hObject, eventdata, selType)
        %
        switch selType,
            case 1,
                Par.Roi.ArtifactType = Par.ROI_ARTIFACT_TYPES.BLEACHING;        % see TPA_FixArtifactROI
            case 2,
                Par.Roi.ArtifactType = Par.ROI_ARTIFACT_TYPES.SLOW_TIME_WAVE;      % see TPA_FixArtifactROI
            case 3,
                Par.Roi.ArtifactType = Par.ROI_ARTIFACT_TYPES.FAST_TIME_WAVE;    % see TPA_FixArtifactROI
            case 4,
                Par.Roi.ArtifactType = Par.ROI_ARTIFACT_TYPES.POLYFIT2;    % see TPA_FixArtifactROI
            otherwise
                errordlg('Unsupported Case for Artifact removal')
        end;
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Fix channels mutual correlation or smoothing
        %%%%%%%%%%%%%%%%%%%%%%
        tmpFigNum                 = Par.Debug.ArtifactFigNum;
        [Par,strROI]              = TPA_FixArtifactsROI(Par, SData.strROI,tmpFigNum);
        
        % save
        SData.strROI            = strROI;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * dF/F processing of the ROI data after averaging
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fProcessROI(hObject, eventdata, selType)
        %
        %%%%%%%%%%%%%%%%%%%%%%
        % Init
        %%%%%%%%%%%%%%%%%%%%%%
        
        switch selType,
            case 1
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.MEAN;        % see TPA_ProcessROI
            case 2
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.MIN10;      % see TPA_ProcessROI
            case 3
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.STD;    % see TPA_ProcessROI
            case 4
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.MIN10CONT;    % see TPA_ProcessROI
            case 5
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.MIN10BIAS;    % see TPA_ProcessROI
            case 6
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.MAX10;    % see TPA_ProcessROI
            otherwise
                errordlg('Unsupported Case for Par.Roi.ProcessType')
        end
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Do Analysis
        %%%%%%%%%%%%%%%%%%%%%%
        tmpFigNum               = Par.Debug.DeltaFOverFigNum; %Par.FigNum + 151;
        [Par,SData.strROI]      = TPA_ProcessROI(Par,SData.strROI,tmpFigNum);
        % save
        
        %%%
        % Save ROI do not ask
        %%%
        Par.DMT                 = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strROI',SData.strROI);
        
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Two Photon based Detection & Classification of events on dF/F data
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fTwoPhotonDetection(hObject, eventdata, selType)
        %
        %%%%%%%%%%%%%%%%%%%%%%
        % Init
        %%%%%%%%%%%%%%%%%%%%%%    
        fMultipleGroups(0, 0, 10); % init if required : TPED - internal object
        
        switch selType,
            case {1,3},
                % Init
                
                dmMTGD.MngrData.TPED = SetDeconvolutionParams(dmMTGD.MngrData.TPED,121);
                
            case 2,
                % process df/f - single trial
                roiNum  = length(SData.strROI);
                if roiNum < 1,
                    warndlg('No ROI data is loaded');
                    return
                end
                dataLen = size(SData.strROI{1}.Data,1);
                if dataLen < 1,
                    warndlg('ROI data need to be processed to compute dF/F');
                    return
                end
                dffData = zeros(dataLen,roiNum);
                for m = 1:roiNum,
                    dffData(:,m) = SData.strROI{m}.Data(:,2);
                end
                %[dmMTGD.MngrData.TPED,dffData] = FastEventDetect(dmMTGD.MngrData.TPED,dffData,122);
                [dmMTGD.MngrData,dffData] = ComputeSpikes(dmMTGD.MngrData,dffData,95);
                for m = 1:roiNum,
                    SData.strROI{m}.Data(:,3) = double(dffData(:,m));
                end
                 DTP_ManageText([], 'TwoPhoton : Detection results are not saved to the file.', 'W' ,0)   ;   
               
           case 4,
                % Multi Trial Event detection 
                %warndlg('Multi Trial Event Detection is not ready yet')
                dmMTGD.MngrData = LoadDataFromTrials(dmMTGD.MngrData,Par);
                roiNum  = size(dmMTGD.MngrData.DbROI,1);
                if roiNum < 1,
                    warndlg('No ROI data is loaded');
                    return
                end
                for m = 1:roiNum,
                    dffData                     = dmMTGD.MngrData.DbROI{m,4};
                    %[dmMTGD.MngrData,spikeData] = ComputeSpikes(dmMTGD.MngrData,dffData,97);
                    % more lower level
                    [dmMTGD.MngrData.TPED,spikeData] = ManualEventDetect(dmMTGD.MngrData.TPED,dffData,99);
                    dmMTGD.MngrData.DbROI{m,5}  = spikeData;
                end

                
                dmMTGD.MngrData = SaveDataFromTrials(dmMTGD.MngrData);

           case 5,
                % Save ROI data 

          case 6, % Configure
                %dmMTTP = TPA_MultiTrialTwoPhotonManager();
                dmMTTP = dmMTTP.SetParams();
                
          case 7, % Analysis
                % Process raw image data 
                dmMTTP = dmMTTP.LoadDataFromTrials(Par);

          case 8, % Compute
                % 
                %dmMTTP = dmMTTP.DecomposeSVD();
                dmMTTP = dmMTTP.DecomposeKmeans();
                
          case 9, % Export to ROIs
                % 
                dmMTTP = dmMTTP.ExtractROI();
                dmMTTP = dmMTTP.SaveDataFromTrials(Par);
                
                
            otherwise
                errordlg('Detection of Time events on dF/F data is coming soon  ')
        end;
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Shows Behavior and TwoPhoton results 
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fMultipleTrials(hObject, eventdata, selType)
        
         
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType
            
           case 1 % Full experiment image registration
                Par                     = TPA_MultiTrialRegistration(Par);
                 
           case 2
                % Align all the ROIs to first one that has been marked

                buttonName = questdlg('All the ROI data will be chnaged. Each ROI will have one exact position for all trials. Results are irreversible', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                                
                Par                     = TPA_MultiTrialRoiAssignment(Par);
                
            case 4
                % preliminary show
                tmpFigNum               = Par.FigNum + 201;
                [Par,dbROI,dbEvent]     = TPA_MultiTrialRoiShow(Par,tmpFigNum);
                
               
            case 5
                % open editor
                %tmpFigNum               = Par.FigNum + 251;
                Par                     = TPA_MultiTrialExplorer(Par);
                
            case 6
                % open editor from Jaaba excel
                Par                     = TPA_MultiTrialExcelExplorer(Par);
                
                
            case 13
                % dF/F for all trials :  Fo = Aver
                Par.Roi.ArtifactType    = Par.ROI_ARTIFACT_TYPES.NONE;
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MEAN;        % see TPA_ProcessROI
                Par                     = TPA_MultiTrialRoiProcess(Par);
                
            case 14
                % dF/F for all trials :  Fo = min 10%
                Par.Roi.ArtifactType    = Par.ROI_ARTIFACT_TYPES.NONE;
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MIN10;      % see TPA_ProcessROI                
                Par                     = TPA_MultiTrialRoiProcess(Par);

            case 15
                % dF/F for all trials :  Fo = min 10% - continuous sections
                Par.Roi.ArtifactType    = Par.ROI_ARTIFACT_TYPES.NONE;
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MIN10CONT;        % see TPA_ProcessROI
                Par                     = TPA_MultiTrialRoiProcess(Par);
                
            case 16 % For Itshik - with artifact removal
                % dF/F for all trials :  Fo = min 10% 
                Par.Roi.ArtifactType    = Par.ROI_ARTIFACT_TYPES.FAST_TIME_WAVE;
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MIN10;        % see TPA_ProcessROI
                Par                     = TPA_MultiTrialRoiProcess(Par);
            
            case 17 
                % dF/F for all trials :  Fo = min 10% + small bias 
                Par.Roi.ArtifactType    = Par.ROI_ARTIFACT_TYPES.NONE;
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MIN10BIAS;        % see TPA_ProcessROI
                Par                     = TPA_MultiTrialRoiProcess(Par);
 
           case 18 
                % dF/F for all trials :  Fo = max 10% 
                Par.Roi.ArtifactType    = Par.ROI_ARTIFACT_TYPES.NONE;
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MAX10;        % see TPA_ProcessROI
                Par                     = TPA_MultiTrialRoiProcess(Par);

           case 19 
                % dF/F for all trials :  Fo = min 10% and 75% on all trials 
                Par.Roi.ArtifactType    = Par.ROI_ARTIFACT_TYPES.NONE;
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MANY_TRIAL;        % see TPA_ProcessROI
                Par                     = TPA_MultiTrialRoiProcess(Par);
                
                
           case 21
                % Behavioral data compression
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                buttonName = questdlg('All the Behaivioral Video data will be changed. It is not possible to recover it back.', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                trialInd                 = 1:Par.DMB.VideoSideFileNum;
                Par.DMB                  = Par.DMB.CompressBehaviorData(trialInd,'all');
                
            case 22 % Adding new event to all trials
                
                % check if dir structure is changed
                %Par                     = TPA_MultiTrialEventAssignment(Par);
                mtMngr                  = TPA_MultiTrialEventManager();
                Par                     = mtMngr.MultiTrialEventAssignment(Par);
                
            case 23, % Removing events from all trials
                
                mtMngr                  = TPA_MultiTrialEventManager();
                mtMngr                  = LoadDataFromTrials(mtMngr,Par);
                mtMngr                  = RemoveEventFromAllTrials(mtMngr);
                
            case 24, % Compute Average ROI value event to all trials 
                
                %Par                     = TPA_MultiTrialEventProcess(Par,0);
                mtMngr                  = TPA_MultiTrialEventManager();
                Par                     = mtMngr.MultiTrialEventProcess(Par,0);
                
            case 25,  % Manger of new/old/complex event to all trials
                
                %Par                     = TPA_MultiTrialEventCreate(Par);
                mtMngr                  = TPA_MultiTrialEventManager();
                Par                     = mtMngr.MultiTrialEventCreate(Par,0);
                
            case 26,
                % preliminary show
                tmpFigNum               = Par.FigNum + 231;
                %[Par,dbROI,dbEvent]     = TPA_MultiTrialEventShow(Par,tmpFigNum);
                mtMngr                  = TPA_MultiTrialEventManager();                
                [Par,dbROI,dbEvent]     = mtMngr.MultiTrialEventShow(Par,tmpFigNum);   
                
            case 27,  % Copy event with trial index shift
                
                mtMngr                  = TPA_MultiTrialEventManager();
                mtMngr                  = LoadDataFromTrials(mtMngr,Par);
                [mtMngr,Par]            = mtMngr.MultiTrialEventIndexShift(Par,0);
                
                
                
           case 31, % Behavioral trajectory extraction and event generation
                
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end
                buttonName = questdlg('X and Y Behaivioral trajectory Events will be added.', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end
                
                % assume that active view is side
                
                % assume that data is scaled by 2 in X and Y
                [Par.DMB,isOK]       = Par.DMB.SetDecimation([2 2 1 1]); 
                if ~isOK
                    DTP_ManageText([], 'MultiTrial : Something wrong with decimation settings.', 'E' ,0)   ; 
                    return
                end
                
                % ROI
                h = warndlg('User ROI to limit trajectories. Use decimation factor 2 to define the limit ROI');
                uiwait(h);
                fManageEvent(0,0,26);
                                
                % set new trial
                for trialInd            = 1:Par.DMB.VideoSideFileNum,
                
                    % select
                    [Par.DMB,isOK]          = Par.DMB.SetTrial(trialInd);
                    assert(isOK,sprintf('Something wrong with data load in trial %d',trialInd))
                
                    % load Image, Events
                    %fManageBehavior(0, 0, 2);
                    [Par.DMB, SData.imBehaive] = Par.DMB.LoadBehaviorData(Par.DMB.Trial,'all');

                    % tracking
                    fManageEvent(0,0,21);
                    
                    % save trajectory events - average
                    fManageEvent(0,0,25);
                    % save trajectory events - diff
                    %fManageEvent(0,0,26);
                
                    
                end
                
           case 32, % BUG FIX IN TRAJ GENERATOR - MAKE OBJECT : CAN NOT BE REACHED FROM MENU
                % Behavioral trajectory extraction and event generation
                if Par.DMB.EventFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with event data. Please select Trial and load the data after that.');
                    return
                end;
                
                                
                % set new trial
                for trialInd            = 1:Par.DMB.VideoSideFileNum,
                
                    % select and load
                    [Par.DMB,isOK]          = Par.DMB.SetTrial(trialInd);
                    assert(isOK,sprintf('Something wrong with data load in trial %d',trialInd))
                    [Par.DMB,SData.strEvent]   = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                    
                
                    % load Image, Events                                    
                    eventNum                = length(SData.strEvent);
                    badEvent                = false(eventNum,1);
                    for k = 1:eventNum,
                       
                        if isa(SData.strEvent{k},'TPA_EventManager'),continue; end;
                        if ~isfield(SData.strEvent{k},'Data'),badEvent(k) = true; continue; end;                        
                        newEvent            = TPA_EventManager;
                        newEvent.Name       = SData.strEvent{k}.Name;
                        newEvent.Data       = SData.strEvent{k}.Data;
                        SData.strEvent{k}   = newEvent;
                        
                    end
                    % remove bad events
                    SData.strEvent(badEvent) = [];

                    
                    % save trajectory events
                    Par.DMB                 = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'strEvent',SData.strEvent);
                
                    
                end
                
           case 33 % Show all behavioral events
                
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end
                
                % names to look
                xEventName               = sprintf('EV:%s:AverTrajX',activeView);
                yEventName               = sprintf('EV:%s:AverTrajY',activeView);
                xEventData               = [];
                yEventData               = [];
                                
                % set new trial
                for trialInd            = 1:Par.DMB.VideoSideFileNum,
                
                    % select
                    [Par.DMB,isOK]          = Par.DMB.SetTrial(trialInd);
                    assert(isOK,sprintf('Something wrong with data load in trial %d',trialInd))
                
                    % load Image, Events
                    [Par.DMB, SData.strEvent]  = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                    
                    % assign to db
                    for m = 1:length(SData.strEvent)
                       if strcmp(SData.strEvent{m}.Name,xEventName)
                           xEventData = cat(2,xEventData,SData.strEvent{m}.Data(:,1));
                       end
                       if strcmp(SData.strEvent{m}.Name,yEventName)
                           yEventData = cat(2,yEventData,SData.strEvent{m}.Data(:,1));
                       end
                    end
                    
                end   
                
                
                figure(181),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
                plot(xEventData),title('X Trajectories'),ylabel('Pixels'),xlabel('Behavioral Frame #')
                legend(num2str((1:Par.DMB.VideoSideFileNum)'));
                figure(182),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
                plot(yEventData),title('Y Trajectories'),ylabel('Pixels'),xlabel('Behavioral Frame #')
                legend(num2str((1:Par.DMB.VideoSideFileNum)'));
                
                % 
                saveFileName    = 'TrajectoryData.xlsx';
                stat            = xlswrite(saveFileName,xEventData,        'X-Traj','A1');
                stat            = xlswrite(saveFileName,yEventData,        'Y-Traj','A1');
                
                
           case 41 % DNN Trajectory generation - Setup
                % Labeler
                lbl = VideoLabeler();
%                 if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 
%                     groundTruthLabeler();
%                     %warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
%                     return
%                 end
%              
%                 [Par.DMB,isOK] = GuiSelectTrial(Par.DMB);
%                 if ~isOK, return; end
% 
%                 % load side movie
%                 fileDirName         = fullfile(Par.DMB.VideoDir,Par.DMB.VideoSideFileNames{Par.DMB.Trial});
%                 groundTruthLabeler(fileDirName);
                
           case 42 % DNN Trajectory generation - Train and Test 
                % Classifier
                %dmCDNN = dmCDNN.SelectTrainData();
                %dmCDNN = dmCDNN.TestAndTrainLabelerNetwork();
                dataType = 101; % ask
                netType  = 21;
                dmCDNN = TestAndTrainSessionNetwork(dmCDNN, dataType, netType);
                
           case 43 % DNN Trajectory generation - Classify
                % 
                dmCDNN = dmCDNN.SelectTestData();
                dmCDNN = dmCDNN.CreateTrajectories();
                
           case 44 % DNN Trajectory generation - Import events
                % 
                dmCDNN = dmCDNN.CreateEvents();

            otherwise
                errordlg('Unsupported Option')
                
                
        end
        
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Analysis of the combined Behavior and TwoPhoton results over many experiments
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fMultipleGroups(hObject, eventdata, selType)
        
         
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            
           case 1, % Use groups for analysis
                % Init
                dmMultExp               = Init(dmMultExp);
                 
           case 2,
                % Select TPA directories to compare
                testType                = 11;
                figNum                  = 81;
            
                % select a database
                dmMultExp               = TestShowAveragedTraces(dmMultExp, testType, figNum);
                
                
           case 3,
                % Select TPA directories to compare
                dmCorr                  = TPA_MultiExperimentFunctionalReconstruction();
                testType                = 11;
                expId                   = 1;
            
                % select a database
                dmCorr                   = TestSelect(dmCorr, testType);

                % check load
                dmCorr                  = LoadSingleExperiment(dmCorr, expId) ;        
                dmCorr                  = LoadSingleExperiment(dmCorr, expId+1) ; 
 
                % correlate
                dmCorr                  = FunctionalExperimentCorrelation(dmCorr, expId); 
                
           case 4,
                % Select BDA directories to compare
                testType                = 11;
                figNum                  = 181;
            
                % select a database
                dmMultExp               = TestShowAveragedEvents(dmMultExp, testType, figNum);
                
           case 5,
                % Select TPA directories to compare
                testType                = 11;
                figNum                  = 281;
            
                % select a database
                dmMultExp               = TestShowAveragedTracesOrderedByCM(dmMultExp, testType, figNum);
                

           case 9 %  Init Group Manager in Any Way
                
                dmMTGD = Init(dmMTGD,Par);
                dmMTGD = LoadData(dmMTGD);
                

            case 10 %  Init Group Manager
                
                % if nitialized before : save data load
               buttonName                  = questdlg('Would you like to reload the data');  
               if strcmp(buttonName,'Yes')  
                    dmMTGD = Init(dmMTGD,Par);
                    dmMTGD = LoadData(dmMTGD);
               end
                


            case 11 %  Active Rois per Event
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ListMostActiveRoiPerEvent(dmMTGD);
                

            case 12 %  Early/Late/OnTime Rois per Event
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ListEarlyLateOntimeRoiPerEvent(dmMTGD);
            
            case 13 %  Show delay map for all trials per specific event
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ShowDelayMapPerEvent(dmMTGD);
                
            case 14 %  Show delay map histograms for all trials per specific event
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ShowHistMapPerEvent(dmMTGD,false);
                
            case 15 %  Show ordered delay map histograms for all trials per specific event
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ShowHistMapPerEvent(dmMTGD,true);
                
            case 16 %  order matrix
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ShowSpikeOrderMatrx(dmMTGD);
               
            case 17 %  order by trace - features - center of mass
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ShowNeuronOrderByFeature(dmMTGD);
               
            case 18, %  order trace by delay of spikes
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ShowNeuronOrderByDelay(dmMTGD);
                
            case 19, %  order by averaged trace - features - center of mass
                
                fMultipleGroups(0, 0, 10); % init if required
                %dmMTGD = ShowAveragedTracesOrderByFeature(dmMTGD);
                dmMTGD = ShowAveragedTracesAndEvents(dmMTGD);

            case 20, %  averaged traces and events
                
                fMultipleGroups(0, 0, 10); % init if required
                %dmMTGD = ShowAveragedTracesAndEvents(dmMTGD);
                %dmMTGD = ShowAveragedTracesAndEventsHadas(dmMTGD);
                dmMTGD = ShowAveragedTracesAndEventsShahar(dmMTGD);
                
 
            case 21, %  Pearson Correlation
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ShowPearsonCorrelationdFF(dmMTGD);
                
            case 22, %  Perform and Show clustering
                
                fMultipleGroups(0, 0, 10); % init if required
                dmMTGD = ShowClusters(dmMTGD);
 
                
             otherwise
                errordlg('Unsupported Option')
        end;
        
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * shows and explore electro phys data along with events
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManagElectroPhys(hObject, eventdata, selType)
        
        %%%%%%%%%%%%%%%%%%%%%%
        % What
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1, % select and load predefined trial
                
                % select GUI
                [Par.DMB,isOK] = GuiSelectTrial(Par.DMB);            %vis4d(uint8(SData.imTwoPhoton));
                if ~isOK,
                    DTP_ManageText([], 'Behavior : Trial Selection problems', 'E' ,0)   ;                  
                end
                
            case 11,
                % determine data params
                [Par.DMB,isOK] = GuiSetDataParameters(Par.DMB);
                if ~isOK,
                    DTP_ManageText([], 'ElectroPhys : configuration parameters are not updated', 'W' ,0)   ;                  
                end
                
            case 2,
                % Behavior
                if Par.DMB.VideoFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                Par.DMB                         = Par.DMB.LoadElectroPhysData(Par.DMB.Trial);
                Par.DMB                         = ShowRecordData(Par.DMB, 151);
                [Par.DMB, strEvent]             = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                if length(strEvent) > 0 && length(SData.strEvent) > 0,
                    buttonName                  = questdlg('Would you like to use Event data from previous trial?');  
                    if ~strcmp(buttonName,'Yes'),  
                        SData.strEvent          = strEvent;
                    end;
                elseif length(strEvent) > 0 && length(SData.strEvent) < 1,
                        SData.strEvent          = strEvent;
                elseif length(strEvent) < 1 && length(SData.strEvent) > 0,
                        %SData.strEvent          = strEvent; % use previous
                end

                
%             case 3,
%                 % edit XY
%                 if (Par.DME.VideoFrontFileNum < 1 && Par.DME.VideoSideFileNum < 1) || isempty(SData.imBehaive) ,
%                     warndlg('Need to load behavior data first.');
%                     return
%                 end;
%                 [Par] = TPA_BehaviorEditorXY(Par);
                
            case 4,
                % edit YT
%                 if ( Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ) || isempty(SData.imBehaive),
%                     warndlg('Need to load behavior data first.');
%                     return
%                 end;
                %[Par] = TPA_ElectroPhysEditorYT(Par);
                Par.DMB                         = ShowRecordData(Par.DMB, 151);
                
           case 5,
                % edit YT
                if ( Par.DMB.VideoFileNum < 1 ) ,
                    warndlg('Need to load behavior data first.');
                    return
                end;
                if length(SData.strEvent) < 1,
                    warndlg('Need to mark behavior data first.');
                    return
                end;
                    
                % start save
                Par.DMB     = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'strEvent',SData.strEvent);

                
           case 6,
                % Next Trial Full load
                
%                 % close previous
%                 hFigLU = findobj('Name','4D : Behavior Time Editor');    
%                 if ~isempty(hFigLU), close(hFigLU); end;
%                 hFigRU = findobj('Name','4D : Behavior Image Editor');    
%                 if ~isempty(hFigRU), close(hFigRU); end;
                
                % set new trial
                trialInd            = Par.DMB.Trial + 1;
                [Par.DMB,isOK]      = Par.DMB.SetTrial(trialInd);
                
                % load Image, Events
                fManagElectroPhys(0, 0, 2);

                % Preview
                %fManagElectroPhys(0, 0, 3);
                fManagElectroPhys(0, 0, 4);
                
                % Arrange
                %fArrangeFigures();
                
            otherwise
                errordlg('Unsupported Type')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Configures and loads Calcium image and data
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageCalcium(hObject, eventdata, selType)
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1, % init analysis
                
                                
                dirName            = Par.DMT.VideoDir;
                % init DMC
                Par.Roi.DataRange  = [0 60000];         % data range for display images
                Par.DMC            = Par.DMC.SelectAllData(dirName);
                Par.DMC            = Par.DMC.CheckData();

%                 end
            case 2, % selection
                
                [Par.DMC,isOK]  = fSelectTrial(Par.DMC);            %vis4d(uint8(SData.imTwoPhoton));
%                 if ~isOK,
%                     errordlg('Trial selection failed. Check out logs - matlab window');
%                     return
%                 end
                
            case 3,
                % determine data params
                [Par.DMC,isOK] = fSetDataParameters(Par.DMC);
                if ~isOK,
                    DTP_ManageText([], 'Calcium : configuration parameters are not updated', 'W' ,0)   ;                  
                end
                
            case 4,
                % TwoPhoton
                if Par.DMC.VideoFileNum < 1,
                    warndlg('Calcium data is not selected or there are problems with load. Please select Trial and load the data after that.');
                    return
                end;
                % load
                [Par.DMC, SData.imTwoPhoton]      = Par.DMC.LoadCalciumData(Par.DMC.Trial);
                [Par.DMC, strROI]                 = Par.DMC.LoadAnalysisData(Par.DMC.Trial,'strROI');
                % this code helps with sequential processing of the ROIs: use old one in the new image
                if length(strROI) > 0,
                    SData.strROI = strROI;
                end
                
            case 5,
                % preview XY
                if Par.DMC.VideoFileNum < 1 || isempty(SData.imTwoPhoton),
                    warndlg('Need to load Calcium data first.');
                    return
                end;
                %TPA_ImageViewer(SData.imTwoPhoton);
                %TPA_TwoPhotonEditorXY(SData.imTwoPhoton);
                Par             = TPA_TwoPhotonEditorXY(Par);
                
           case 6,
                % preview YT
                if Par.DMC.VideoFileNum < 1 || isempty(SData.imTwoPhoton),
                    warndlg('Need to load Calcium data first.');
                    return
                end;
                Par             = TPA_TwoPhotonEditorYT(Par);
                %TPA_TwoPhotonEditorYT(SData.imTwoPhoton);
                
             otherwise
                errordlg('Unsupported Type')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * shows ROI analysis results
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fViewResults(hObject, eventdata, selType)
        % help with different functions
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1,
                winopen('TwoPhotonAnalysis UserGuide.docx');
                
%                 tmpFigNum               = Par.FigNum + 201;
%                 Par                     = DTP_ShowResults(Par,SData.imTwoPhoton,SData.strRecord,SData.strROI2,tmpFigNum);
%             case 2,
%                 tmpFigNum               = Par.FigNum + 251;
%                 Par                     = DTP_ShowROIs(Par,SData.imTwoPhoton,SData.strRecord,SData.strROI2,tmpFigNum);
%             case 3,
%                 tmpFigNum               = Par.FigNum + 301;
%                 [Par,strROI2]           = DTP_MeasurementsROI(Par,SData.imTwoPhoton,SData.strRecord,SData.strROI2,tmpFigNum);
%                 SData.strROI2           = strROI2;
            otherwise
                errordlg('Unsupported View')
        end;
        
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Import analysis results
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fImportResults(hObject, eventdata, selType)
        % Import data primarly from JAABA
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Do it
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            
            case 1, % import Jabba predicted scores - select one directory
                
                % check if experiment is specified
                if isempty(Par.DMB.EventDir),
                    warndlg('Please specify experiment directory first. File > Experiment > New or Load '); 
                    return
                end
                
                
                dirName             = uigetdir(Par.DMJ.JaabaDir,'Jaaba Generated Data Directory');
                if isnumeric(dirName), return; end;  % cancel button  
                
                Par.DMJ.JaabaDir     = dirName; % info Jaaba
                
                fImportResults(0, 0, 12);
                
            case {2,3}, % import Jabba Excel - select one directory - auto or manualy
                
                % Behavior dir is known
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Please Select Analysis directory for the results. Use File->Experiment Behavior->Select Directory ');
                    return
                end;
                
                % Ask about event data
                if Par.DMB.EventFileNum > 0,
                    buttonName = questdlg('All the previous Behaivioral Event data will be lost.', 'Warning');
                    if ~strcmp(buttonName,'Yes'), return; end;
                end
                
                % load excel
                [fileName,dirName]              = uigetfile(dmSession.ExpDir,'Jaaba Excel File');
                if isnumeric(dirName), return; end;  % cancel button
                
                
                % read the excel
                xlsFile                                 = fullfile(dirName,fileName);
                if selType == 2,
                    Par.DMJ                             = Par.DMJ.LoadJaabaExcelData(xlsFile);
                else
                    Par.DMJ                             = Par.DMJ.LoadJaabaExcelDataManual(xlsFile);
                end
                    
                
                if Par.DMJ.JaabaDirNum < 1,
                    warndlg('Jaaba Excel file problems. Check the messages and determine the source.');
                    return
                end

                for trialInd = 1:Par.DMJ.JaabaDirNum,
                    [Par.DMJ, jabEvent]             = Par.DMJ.ConvertExcelToAnalysis(trialInd);
                    
                    % assign and save
                    SData.strEvent                  = jabEvent;
                    [Par.DMB,isOK]                  = Par.DMB.SetTrial(trialInd);
                    if isOK,
                    Par.DMB                         = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'strEvent',SData.strEvent);
                    end
                end
                
            case 4, % import Jabba manual scores - select one directory with jab files
                
                % check if experiment is specified
                if isempty(Par.DMB.EventDir),
                    warndlg('Please specify experiment directory first. File > Experiment > New or Load '); 
                    return
                end
                
                % Ask about event data
                if Par.DMB.EventFileNum > 0,
                buttonName = questdlg('All the previous Behaivioral Event data will be lost.', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                end
                
                
                [csFilenames, sPath] = uigetfile({   '*.jab', 'jab Files'; '*.*', 'All Files'}, 'Select jab File ',...
                    'OpenLocation'  , Par.DMJ.EventDir, ...
                    'Multiselect'   , 'off');
                
                if isnumeric(sPath), return, end;   % Dialog aborted
                
                % if single file selected
                if iscell(csFilenames), csFilenames = csFilenames{1}; end;
                
                Par.DMJ.EventDir     = sPath; % info Jaaba
                Par.DMJ.JabFileName  = csFilenames;
                
                
                fImportResults(0, 0, 13);
                
            case 12, % import Jabba - select one directory from scores files
                
                % Ask about event data
                doMerge = false;
                if Par.DMB.EventFileNum > 0,
                buttonName = questdlg('Previous Behaivioral Event data is found. Would you like?', 'Warning','Cancel','Merge','Overwrite','Cancel');
                if strcmp(buttonName,'Cancel'), return; end;
                % check if merge is required
                doMerge = strcmp(buttonName,'Merge');
                end
                
                
                % determine the path - assume certain directory structure
                dirName                             = Par.DMJ.JaabaDir ;
                Par.DMJ                             = Par.DMJ.SelectJaabaData(dirName);

                % Jaaba
                if Par.DMJ.JaabaDirNum < 1 ,
                    warndlg('Jaaba info is not found. You will need to mark behavioral event differently.');
                    return
                end
                % where to put data back
                eventDirName                        = Par.DMB.EventDir;
                
                
                 % init Behavior directories
                 %Par.DMB                             = Par.DMB.Clean();
                 %Par.DMB                            = Par.DMB.SelectAllData(dirName,'comb');
                 Par.DMB                            = Par.DMB.SelectBehaviorData(dirName,'comb');
                 %Par.DMB                            = Par.DMB.RemoveEventData();
                 Par.DMB                            = Par.DMB.SelectAnalysisData(eventDirName) ; % event directory is different              
                 Par.DMB                            = Par.DMB.CheckData();
                 
                 % assign offsets for the data import : using behavioral inputs
                 Par.DMJ.Offset                     = Par.DMB.Offset;

                for trialInd = 1:Par.DMJ.JaabaDirNum
                    [Par.DMJ, jabData]              = Par.DMJ.LoadJaabaData(trialInd);
                    [Par.DMJ, jabEvent]             = Par.DMJ.ConvertToAnalysis(jabData);
                    
                    % assign and save
                    if doMerge
                        % select and load
                        [Par.DMB,isOK]                  = Par.DMB.SetTrial(trialInd);
                        assert(isOK,sprintf('Something wrong with data load in trial %d',trialInd))
                        [Par.DMB,SData.strEvent]        = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                        SData.strEvent                  = cat(1,SData.strEvent(:),jabEvent(:));
                    else
                        SData.strEvent                  = jabEvent;
                    end
                    Par.DMB                         = Par.DMB.SetTrial(trialInd);
                    Par.DMB                         = Par.DMB.SaveAnalysisData(trialInd,'strEvent',SData.strEvent);
                end

            case 13, % import Jabba events from jab file - manual data

                pathFileName                        = fullfile(Par.DMJ.EventDir,Par.DMJ.JabFileName) ;
                
                % determine the path - assume certain directory structure
                Par.DMJ                             = Par.DMJ.LoadJabFile(pathFileName);

                % Jaaba
                if Par.DMJ.JaabaDirNum < 1 ,
                    warndlg('Jaaba info is not found. You will need to mark behavioral event differently.');
                    return
                end;
                % where to put data back
                eventDirName                        = Par.DMB.EventDir;
                
                
%                 % init Behavior directories
                 %Par.DMB                            = Par.DMB.RemoveEventData();
                 Par.DMB                            = Par.DMB.SelectAnalysisData(eventDirName) ; % event directory is different              
                 Par.DMB                            = Par.DMB.CheckData();


                for trialInd = 1:Par.DMJ.JaabaDirNum,
                    [Par.DMJ, jabData]              = Par.DMJ.GetJabFileData(trialInd);
                    [Par.DMJ, jabEvent]             = Par.DMJ.ConvertToAnalysis(jabData);
                    
                    % assign and save
                    SData.strEvent                  = jabEvent;
                    %Par.DMB                         = Par.DMB.SetTrial(trialInd);
                    Par.DMB                         = Par.DMB.SaveAnalysisData(trialInd,'strEvent',SData.strEvent);
                end
                
            case 21 % Import Prarie Piezo Events
                
                % check if experiment is specified
                if isempty(Par.DMB.EventDir)
                    warndlg('Please specify experiment directory first. File > Experiment > New or Load '); 
                    return
                end
                
                % Ask about event data
                if Par.DMB.EventFileNum > 0
                buttonName = questdlg('All the previous Behaivioral Event data will be lost.', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                end
                
                % TwoPhoton
                if Par.DMT.VideoFileNum < 1
                    warndlg('Two Photon data is not selected or there are problems with load. Please select Trial and load the data after that.');
                    return
                end
                dirName         = Par.DMT.VideoDir;
                
                Par.DMB         = ImportEventsLiora(Par.DMB,dirName);
                
            case 22 % Import Prarie Electro Phys Events
                
                % check if experiment is specified
                if isempty(Par.DMB.EventDir)
                    warndlg('Please specify experiment directory first. File > Experiment > New or Load '); 
                    return
                end
                
                % Ask about event data
                if Par.DMB.EventFileNum > 0
                buttonName = questdlg('All the previous Behaivioral Event data will be lost.', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                end
                
                % TwoPhoton
                if Par.DMT.VideoFileNum < 1,
                    warndlg('Two Photon data is not selected or there are problems with load. Please select Trial and load the data after that.');
                    return
                end
                dirName         = Par.DMT.VideoDir;
                Par.DMB         = ImportEventsElectroPhys(Par.DMB,dirName);
                
          case 23 % Import Behavioral Lever press events
                
                % check if experiment is specified
                if isempty(Par.DMB.EventDir)
                    warndlg('Please specify experiment directory first. File > Experiment > New or Load '); 
                    return
                end
                
%                 % Ask about event data
%                 if Par.DMB.EventFileNum > 0
%                 buttonName = questdlg('All the previous Behaivioral Event data will be lost.', 'Warning');
%                 if ~strcmp(buttonName,'Yes'), return; end
%                 end
                
                % Behavioral data
                if Par.DMB.VideoFrontFileNum < 1
                    warndlg('Behavioral video data is not selected or there are problems with load. Please select Trial and load the data after that.');
                    return
                end
                dirName         = Par.DMB.VideoDir;
                Par.DMB         = ImportLeverPressData(Par.DMB,dirName);
               
                
          case 24 % Import Behavioral events from Vdieo Labeler
                
                % check if experiment is specified
                if isempty(Par.DMB.EventDir)
                    warndlg('Please specify experiment directory first. File > Experiment > New or Load '); 
                    return
                end
                
%                 % Ask about event data
%                 if Par.DMB.EventFileNum > 0
%                 buttonName = questdlg('All the previous Behaivioral Event data will be lost.', 'Warning');
%                 if ~strcmp(buttonName,'Yes'), return; end
%                 end
                
                % Behavioral data
                if Par.DMB.VideoFrontFileNum < 1
                    warndlg('Behavioral video data is not selected or there are problems with load. Please select Trial and load the data after that.');
                    return
                end
                dirName         = Par.DMB.VideoDir;
                Par.DMB         = ImportVideoLabelerROI(Par.DMB); %,dirName);
                 
             otherwise
                errordlg('Unsupported Import Case')
        end
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * exports analysis results
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fExportResults(hObject, eventdata, selType)
        %
        %%%%%%%%%%%%%%%%%%%%%%
        % Do Export
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
%             case 3,
%                 Par = TPA_ExportDataToExcel(Par,SData.strRecord,SData.strROI2);
%             case 4,
%                 Par = DTP_ExportDataToIgor(Par,SData.strRecord,SData.strROI2);

            case 5, % TwoPhoton data export
                
                % preview XY
                if Par.DMT.VideoFileNum < 1 || isempty(SData.imTwoPhoton),
                    warndlg('Need to load Two Photon data first.');
                    return
                end;
                Par.DMT         = Par.DMT.SaveTwoPhotonData(Par.DMT.Trial, SData.imTwoPhoton);                
                
            otherwise
                errordlg('Unsupported Export Case')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Init all the buttons
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fSetupGUI() %#ok<*INUSD> eventdata is trialedly unused
        
        % all the figures are black
        %colordef('none');
        
        S.hFig = figure('units','pixels',...
            'position',[200 250 750 30],...
            'menubar','none',...
            'name', sprintf('Two Photon Analysis : %s',currVers),...
            'numbertitle','off',...
            'resize','off',...
            'closerequestfcn',{@fCloseGUI}); %{@fh_crfcn});
        
        % -------------------------------------------------------------------------------------------------------        
        S.hMenuFile(1)          = uimenu(S.hFig,                'Label','File...');
        S.hMenuSession(1)       = uimenu(S.hMenuFile(1),        'Label','Session ...'                                                        );
        S.hMenuSession(2)       = uimenu(S.hMenuSession(1),     'Label','Load Session',                             'Callback',{@fManageSession,1});
        S.hMenuSession(3)       = uimenu(S.hMenuSession(1),     'Label','Load Session From ...',                    'Callback',{@fManageSession,2});
        S.hMenuSession(4)       = uimenu(S.hMenuSession(1),     'Label','Save Session',                             'Callback',{@fManageSession,3});
        S.hMenuSession(5)       = uimenu(S.hMenuSession(1),     'Label','Save Session As...',                       'Callback',{@fManageSession,4});
        S.hMenuSession(6)       = uimenu(S.hMenuSession(1),     'Label','Clear Session',                            'Callback',{@fManageSession,5});
        
        S.hMenuExperiment(1)    = uimenu(S.hMenuFile(1) ,       'Label','Experiment ...', 'separator','on'                                           );
        S.hMenuExperiment(2)    = uimenu(S.hMenuExperiment(1),  'Label','Select System ...',                        'Callback',{@fManageExperiment,1});
        S.hMenuExperiment(3)    = uimenu(S.hMenuExperiment(1),  'Label','Load Organized Directory ...',             'Callback',{@fManageExperiment,2}, 'enable','on');
        S.hMenuExperiment(4)    = uimenu(S.hMenuExperiment(1),  'Label','Load from Management File ...',            'Callback',{@fManageExperiment,3}, 'enable','on');
        S.hMenuExperiment(5)    = uimenu(S.hMenuExperiment(1),  'Label','Setup New Experiment...',                  'Callback',{@fManageExperiment,4}, 'separator','on');
        S.hMenuExperiment(6)    = uimenu(S.hMenuExperiment(1),  'Label','Refresh Data Management File...',          'Callback',{@fManageExperiment,5});
        S.hMenuExperiment(7)    = uimenu(S.hMenuExperiment(1),  'Label','Save Data Management File ...',            'Callback',{@fManageExperiment,6});
        S.hMenuExperiment(8)    = uimenu(S.hMenuExperiment(1),  'Label','Preview Data Management File...',          'Callback',{@fManageExperiment,7});
        S.hMenuExperiment(9)    = uimenu(S.hMenuExperiment(1),  'Label','Load Last Experiment ...',                 'Callback',{@fManageExperiment,8},'separator','on');
        S.hMenuExperiment(10)   = uimenu(S.hMenuExperiment(1),  'Label','Save Last Experiment ...',                 'Callback',{@fManageExperiment,9},'separator','off');
        S.hMenuExperiment(11)   = uimenu(S.hMenuExperiment(1),  'Label','Check Data Structure ...',                 'Callback',{@fManageExperiment,15},'separator','off');
                
        
        S.hMenuImport(1)        = uimenu(S.hMenuFile(1),        'Label','Import ...', 'separator','on'                                              );
        S.hMenuImport(2)        = uimenu(S.hMenuImport(1),      'Label','Jaaba Predicted Score Data ...',           'Callback',{@fImportResults,1});
        S.hMenuImport(3)        = uimenu(S.hMenuImport(1),      'Label','Jaaba Manual Score  Data ...',             'Callback',{@fImportResults,4});
        S.hMenuImport(4)        = uimenu(S.hMenuImport(1),      'Label','Jaaba Excel Data Semi Auto ...',           'Callback',{@fImportResults,3},  'Enable','off');
        S.hMenuImport(5)        = uimenu(S.hMenuImport(1),      'Label','Prarie Piezo Stimulus Events...',          'Callback',{@fImportResults,21}, 'Enable','off');
        S.hMenuImport(6)        = uimenu(S.hMenuImport(1),      'Label','Prarie Electro Phys as Events...',         'Callback',{@fImportResults,22}, 'Enable','on');
        S.hMenuImport(7)        = uimenu(S.hMenuImport(1),      'Label','Lever Press Events...',                    'Callback',{@fImportResults,23});
        S.hMenuImport(8)        = uimenu(S.hMenuImport(1),      'Label','Video Labeler ROIs...',                    'Callback',{@fImportResults,24});
        S.hMenuExport(1)        = uimenu(S.hMenuFile(1),        'Label','Export...');
        S.hMenuExport(2)        = uimenu(S.hMenuExport(1),      'Label','ImageJ ...',                               'Callback','warndlg(''Countdown is initiated'')');
        S.hMenuExport(3)        = uimenu(S.hMenuExport(1),      'Label','Matlab ...',                               'Callback','warndlg(''Is yet to come'')');
        S.hMenuExport(4)        = uimenu(S.hMenuExport(1),      'Label','Excel ...',                                'Callback',{@fExportResults,3});
        S.hMenuExport(5)        = uimenu(S.hMenuExport(1),      'Label','Igor ...',                                 'Callback',{@fExportResults,4});
        S.hMenuExport(6)        = uimenu(S.hMenuExport(1),      'Label','Jabba ...',                                'Callback','warndlg(''Is yet to come'')');
        S.hMenuExport(7)        = uimenu(S.hMenuExport(1),      'Label','TwoPhoton Image Data to TIF file ...',     'Callback',{@fExportResults,5});
       
        
        S.hMenuFile(3)          = uimenu(S.hMenuFile(1),        'Label','Close Windows',        'separator','on',   'Callback',@fCloseFigures);
        S.hMenuFile(4)          = uimenu(S.hMenuFile(1),        'Label','Arrange Windows',                          'Callback',@fArrangeFigures);        
        S.hMenuFile(5)          = uimenu(S.hMenuFile(1),        'Label','Save All & Exit',   'separator','on',      'Callback',@fCloseGUI);
        
        % -------------------------------------------------------------------------------------------------------        
        S.hMenuBehaive(1)       = uimenu(S.hFig,                'Label','Behavior...');
        S.hMenuBehaive(2)       = uimenu(S.hMenuBehaive(1),     'Label','Set Trial Num...',                         'Callback',{@fManageBehavior,1});
        S.hMenuBehaive(3)       = uimenu(S.hMenuBehaive(1),     'Label','Config Data...',                           'Callback',{@fManageBehavior,11});
        S.hMenuBehaive(4)       = uimenu(S.hMenuBehaive(1),     'Label','Load Trial Data...',                       'Callback',{@fManageBehavior,2});
        S.hMenuBehaive(5)       = uimenu(S.hMenuBehaive(1),     'Label','View XY...',                               'Callback',{@fManageBehavior,3});
        S.hMenuBehaive(6)       = uimenu(S.hMenuBehaive(1),     'Label','View YT...',                               'Callback',{@fManageBehavior,4});
        S.hMenuBehaive(7)       = uimenu(S.hMenuBehaive(1),     'Label','Next Trial Load and Show...',              'Callback',{@fManageBehavior,6});
        S.hMenuBehaive(8)       = uimenu(S.hMenuBehaive(1),     'Label','Compress Video Data...',                   'Callback',{@fManageBehavior,21});
        S.hMenuBehaive(9)       = uimenu(S.hMenuBehaive(1),     'Label','Check Drop Frames in Video Data...',       'Callback',{@fManageBehavior,22});
        S.hMenuBehaive(10)      = uimenu(S.hMenuBehaive(1),     'Label','Overlay Two Photon ROIs...',               'Callback',{@fManageBehavior,31});
        %S.hMenuBehaive(10)       = uimenu(S.hMenuBehaive(1),     'Label','Event Analysis...',                       'Callback',{@fManageBehavior,41});
       
        S.hMenuEventsBD(1)      = uimenu(S.hMenuBehaive(1),     'Label','Events...', 'separator','on');
        S.hMenuEventsBD(2)      = uimenu(S.hMenuEventsBD(1),    'Label','Load from File...',                        'Callback',{@fManageEvent,1});
        S.hMenuEventsBD(3)      = uimenu(S.hMenuEventsBD(1),    'Label','New/Clean  ...',                           'Callback',{@fManageEvent,2});
        S.hMenuEventsBD(4)      = uimenu(S.hMenuEventsBD(1),    'Label','Save ...',                                 'Callback',{@fManageEvent,3});
        S.hMenuEventsBD(5)      = uimenu(S.hMenuEventsBD(1),    'Label','Load...',                                  'Callback',{@fManageEvent,4});
        S.hMenuEventsBD(6)       = uimenu(S.hMenuEventsBD(1),   'Label','Analysis...',                              'Callback',{@fManageBehavior,41});
        %S.hMenuEvents(6)        = uimenu(S.hMenuEvents(1),      'Label','View All...',                              'Callback',{@fManageEvent,5});
        %S.hMenuEvents(7)        = uimenu(S.hMenuEvents(1),      'Label','Auto Detect...',                           'Callback','warndlg(''Is yet to come'')');
        %S.hMenuBehaive(8)       = uimenu(S.hMenuBehaive(1),     'Label','Save Event Results',  'separator','on',    'Callback',{@fManageBehavior,5});
        S.hMenuClass(1)         = uimenu(S.hMenuBehaive(1),     'Label','Event Classifier...',  'separator','on'   );
        S.hMenuClass(2)         = uimenu(S.hMenuClass(1),       'Label','Init ...',                                 'Callback',{@fManageEvent,11});
        S.hMenuClass(3)         = uimenu(S.hMenuClass(1),       'Label','Load  ...',                                'Callback',{@fManageEvent,12});
        S.hMenuClass(4)         = uimenu(S.hMenuClass(1),       'Label','Save  ...',                                'Callback',{@fManageEvent,13});
        S.hMenuClass(5)         = uimenu(S.hMenuClass(1),       'Label','Train on Current Trial...',                'Callback',{@fManageEvent,14});
        S.hMenuClass(6)         = uimenu(S.hMenuClass(1),       'Label','Train on all Previous Trials...',          'Callback',{@fManageEvent,15});
        S.hMenuClass(7)         = uimenu(S.hMenuClass(1),       'Label','Classify Current Trial...',                'Callback',{@fManageEvent,16});

        S.hMenuTrajec(1)        = uimenu(S.hMenuBehaive(1),      'Label','Trajectory Analysis...',  'separator','off'   );
        S.hMenuTrajec(2)        = uimenu(S.hMenuTrajec(1),       'Label','Params ...',                               'Callback',{@fManageEvent,20});
        S.hMenuTrajec(3)        = uimenu(S.hMenuTrajec(1),       'Label','Define Bounds using ROIs ...',             'Callback',{@fManageEvent,26});
        S.hMenuTrajec(4)        = uimenu(S.hMenuTrajec(1),       'Label','Create ...',                               'Callback',{@fManageEvent,21});
        S.hMenuTrajec(5)        = uimenu(S.hMenuTrajec(1),       'Label','Show Filtered ...',                        'Callback',{@fManageEvent,22});
        S.hMenuTrajec(6)        = uimenu(S.hMenuTrajec(1),       'Label','Show Average  ...',                        'Callback',{@fManageEvent,23});
        S.hMenuTrajec(7)        = uimenu(S.hMenuTrajec(1),       'Label','Show Volume  ...',                         'Callback',{@fManageEvent,24});
        S.hMenuTrajec(8)        = uimenu(S.hMenuTrajec(1),       'Label','Save Aver. Trajectory as Event  ...',      'Callback',{@fManageEvent,25});
        S.hMenuTrajec(9)        = uimenu(S.hMenuTrajec(1),       'Label','Manual Trajectory Labeler  ...',           'Callback',{@fManageEvent,31},  'separator','on'   );
        S.hMenuTrajec(10)       = uimenu(S.hMenuTrajec(1),       'Label','Save Labeler data as Events  ...',         'Callback',{@fManageEvent,32});
        
        % -------------------------------------------------------------------------------------------------------
        S.hMenuElectroPhys(1)   = uimenu(S.hFig,                'Label','ElectroPhys...');
        S.hMenuElectroPhys(2)   = uimenu(S.hMenuElectroPhys(1), 'Label','Set Trial Num...',                         'Callback',{@fManagElectroPhys,1});
        S.hMenuElectroPhys(3)   = uimenu(S.hMenuElectroPhys(1), 'Label','Config Data...',                           'Callback',{@fManagElectroPhys,11});
        S.hMenuElectroPhys(4)   = uimenu(S.hMenuElectroPhys(1), 'Label','Load Trial Data...',                       'Callback',{@fManagElectroPhys,2});
        S.hMenuElectroPhys(5)   = uimenu(S.hMenuElectroPhys(1), 'Label','View XY...',                               'Callback',{@fManagElectroPhys,3},'Enable','off');
        S.hMenuElectroPhys(6)   = uimenu(S.hMenuElectroPhys(1), 'Label','View YT...',                               'Callback',{@fManagElectroPhys,4});
        S.hMenuElectroPhys(7)   = uimenu(S.hMenuElectroPhys(1), 'Label','Next Trial Load and Show...',              'Callback',{@fManagElectroPhys,6});
        
        % -------------------------------------------------------------------------------------------------------
        S.hMenuImage(1)         = uimenu(S.hFig,                'Label','Two Photon...');
        S.hMenuImage(2)         = uimenu(S.hMenuImage(1),       'Label','Set Trial Num...',                         'Callback',{@fManageTwoPhoton,1});
        S.hMenuImage(3)         = uimenu(S.hMenuImage(1),       'Label','Config Data...',                           'Callback',{@fManageTwoPhoton,11});
        S.hMenuImage(4)         = uimenu(S.hMenuImage(1),       'Label','Load Trial Data...',                       'Callback',{@fManageTwoPhoton,2});
        S.hMenuImage(5)         = uimenu(S.hMenuImage(1),       'Label','View XY...',                               'Callback',{@fManageTwoPhoton,3});
        S.hMenuImage(6)         = uimenu(S.hMenuImage(1),       'Label','View YT...',                               'Callback',{@fManageTwoPhoton,4});
        S.hMenuImage(7)         = uimenu(S.hMenuImage(1),       'Label','Next Trial Load and Show...',              'Callback',{@fManageTwoPhoton,5});
        
        S.hMenuArtif(1)         = uimenu(S.hMenuImage(1),       'Label','Registration...');
        S.hMenuArtif(2)         = uimenu(S.hMenuArtif(1),       'Label','Janelia : Template + Parfor ...',          'Callback',{@fManageRegistration,1});
        S.hMenuArtif(3)         = uimenu(S.hMenuArtif(1),       'Label','Janelia : Template + FFT ...',             'Callback',{@fManageRegistration,2});
        S.hMenuArtif(4)         = uimenu(S.hMenuArtif(1),       'Label','Mtrx Inverse: No Template + FFT ...',      'Callback',{@fManageRegistration,3});
        S.hMenuArtif(5)         = uimenu(S.hMenuArtif(1),       'Label','Janelia : Template x 3 ...',               'Callback',{@fManageRegistration,4});        
        S.hMenuArtif(6)         = uimenu(S.hMenuArtif(1),       'Label','Preview Registration Results ...',         'Callback',{@fManageRegistration,5});
        S.hMenuArtif(7)         = uimenu(S.hMenuArtif(1),       'Label','Verify Substitution ...',                  'Callback',{@fManageRegistration,6});
        S.hMenuArtif(8)         = uimenu(S.hMenuArtif(1),       'Label','TwoPhoton Image Data to TIF file ...',     'Callback',{@fExportResults,5});
        S.hMenuArtif(9)         = uimenu(S.hMenuArtif(1),       'Label','Clear Registration Results ...',           'Callback',{@fManageRegistration,7});
        S.hMenuArtif(10)        = uimenu(S.hMenuArtif(1),       'Label','Drop frames from Registration ...',        'Callback',{@fManageRegistration,8});
        %S.hMenuArtif(10)        = uimenu(S.hMenuArtif(1),       'Label','Correct Motion in Sub Regions in T ...',   'Callback','warndlg(''Is yet to come'')');
        
        S.hMenuRoi(1)           = uimenu(S.hMenuImage(1),       'Label','ROIs...');
        S.hMenuRoi(2)           = uimenu(S.hMenuRoi(1),         'Label','Load from File ...',                       'Callback',{@fManageROI,1});
        S.hMenuRoi(3)           = uimenu(S.hMenuRoi(1),         'Label','Clean/New  ...',                           'Callback',{@fManageROI,2});
        S.hMenuRoi(4)           = uimenu(S.hMenuRoi(1),         'Label','Save ...',                                 'Callback',{@fManageROI,3});
        S.hMenuRoi(5)           = uimenu(S.hMenuRoi(1),         'Label','Load Current...',                          'Callback',{@fManageROI,4});
        S.hMenuRoi(6)           = uimenu(S.hMenuRoi(1),         'Label','Load From File and Specific Z-Stack...',   'Callback',{@fManageROI,5});
        %S.hMenuRoi(7)           = uimenu(S.hMenuRoi(1),         'Label','Manual Registration...',                   'Callback',{@fManageROI,21});
        
        S.hMenuAverage(1)       = uimenu(S.hMenuImage(1),       'Label','Analysis...');
        S.hMenuAverage(2)       = uimenu(S.hMenuAverage(1),     'Label','Aver Fluorescence Point ROIs ...',         'Callback',{@fAnalysisROI,1});
        S.hMenuAverage(3)       = uimenu(S.hMenuAverage(1),     'Label','Aver Fluorescence Line(Max) ROIs ...',     'Callback',{@fAnalysisROI,2});
        S.hMenuAverage(4)       = uimenu(S.hMenuAverage(1),     'Label','Aver Fluorescence Line(Orth) ROIs ...',    'Callback',{@fAnalysisROI,3});
        S.hMenuAverage(5)       = uimenu(S.hMenuAverage(1),     'Label','Aver Separately by ROI Type ...',          'Callback',{@fAnalysisROI,4});        
        S.hMenuProcess(2)       = uimenu(S.hMenuAverage(1),     'Label','Remove Artifacts : Slow Time ...',         'Callback',{@fArtifactsROI,2}, 'separator','on');
        S.hMenuProcess(3)       = uimenu(S.hMenuAverage(1),     'Label','Remove Artifacts : Fast Time ...',         'Callback',{@fArtifactsROI,3});
        S.hMenuProcess(4)       = uimenu(S.hMenuAverage(1),     'Label','Remove Artifacts : Polyfit 2 ...',         'Callback',{@fArtifactsROI,4});        
        S.hMenuProcess(5)       = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = Aver Fluorescence ...',       'Callback',{@fProcessROI,1},    'separator','on');
        S.hMenuProcess(6)       = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = 10% Min ...',                 'Callback',{@fProcessROI,2});
        S.hMenuProcess(7)       = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = STD ...',                     'Callback',{@fProcessROI,3});
        S.hMenuProcess(8)       = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = 10% Min Cont ...',            'Callback',{@fProcessROI,4});
        S.hMenuProcess(9)       = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = 10% Min + Bias ...',          'Callback',{@fProcessROI,5});
        S.hMenuProcess(10)      = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = 10% Max ...',                 'Callback',{@fProcessROI,6});
        
        S.hMenuDetectEvent(1)   = uimenu(S.hMenuImage(1),       'Label','dF/F Spike Detection...', 'separator','on' );
        S.hMenuDetectEvent(2)   = uimenu(S.hMenuDetectEvent(1), 'Label','Configure ...',                             'Callback',{@fTwoPhotonDetection,1});
        S.hMenuDetectEvent(2)   = uimenu(S.hMenuDetectEvent(1), 'Label','Detect Events on ROI data ...',             'Callback',{@fTwoPhotonDetection,2});
        
        
        S.hMenuEventTP(1)       = uimenu(S.hMenuImage(1),       'Label','ROI Auto Detector ...');
        S.hMenuEventTP(2)       = uimenu(S.hMenuEventTP(1),     'Label','Configure ... ',                           'Callback',{@fManageROI,10});
        S.hMenuEventTP(3)       = uimenu(S.hMenuEventTP(1),     'Label','Functional Fluorescence ',                 'Callback',{@fManageROI,11}, 'Enable','on');
        S.hMenuEventTP(4)       = uimenu(S.hMenuEventTP(1),     'Label','Spatial Fluorescence ',                    'Callback',{@fManageROI,12});
        S.hMenuEventTP(5)       = uimenu(S.hMenuEventTP(1),     'Label','Play Orig + Results ... ',                 'Callback',{@fManageROI,15},'Enable','off');
        S.hMenuEventTP(6)       = uimenu(S.hMenuEventTP(1),     'Label','Show Results ... ',                        'Callback',{@fManageROI,16});
        S.hMenuEventTP(7)       = uimenu(S.hMenuEventTP(1),     'Label','Import ROIs ... ',                         'Callback',{@fManageROI,17});
        
        
        % -------------------------------------------------------------------------------------------------------
        S.hMenuMulti(1)          = uimenu(S.hFig,               'Label','Multi Trial...');
        S.hMenuMulti(2)          = uimenu(S.hMenuMulti(1),      'Label','TwoPhoton Registration for all Trials ... ',       'Callback',{@fMultipleTrials,1});
        S.hMenuMulti(3)          = uimenu(S.hMenuMulti(1),      'Label','ROI Assignment ... ',                              'Callback',{@fMultipleTrials,2});
        S.hMenuMultiDFF(1)       = uimenu(S.hMenuMulti(1),      'Label','dF/F Computation... '                        );
        S.hMenuMultiDFF(2)       = uimenu(S.hMenuMultiDFF(1),   'Label','dF/F  : Fbl = Aver ... ',                          'Callback',{@fMultipleTrials,13});
        S.hMenuMultiDFF(3)       = uimenu(S.hMenuMultiDFF(1),   'Label','dF/F  : Fbl = 10% Min... ',                        'Callback',{@fMultipleTrials,14});
        S.hMenuMultiDFF(4)       = uimenu(S.hMenuMultiDFF(1),   'Label','dF/F  : Fbl = 10% Min Cont ... ',                  'Callback',{@fMultipleTrials,15});
        S.hMenuMultiDFF(5)       = uimenu(S.hMenuMultiDFF(1),   'Label','dF/F  : Fbl = 10% Min with Artifact = Slow ... ',  'Callback',{@fMultipleTrials,16}, 'separator','off');
        S.hMenuMultiDFF(6)       = uimenu(S.hMenuMultiDFF(1),   'Label','dF/F  : Fbl = 10% Min + Bias ... ',                'Callback',{@fMultipleTrials,17}, 'separator','off');
        S.hMenuMultiDFF(7)       = uimenu(S.hMenuMultiDFF(1),   'Label','dF/F  : Fbl = 10% Max ... ',                       'Callback',{@fMultipleTrials,18}, 'separator','off');
        S.hMenuMultiDFF(8)       = uimenu(S.hMenuMultiDFF(1),   'Label','dF/F  : Fbl = 10% Min on All trials ... ',         'Callback',{@fMultipleTrials,19}, 'separator','off');
        S.hMenuMulti(4)          = uimenu(S.hMenuMulti(1),      'Label','dF/F Preview for all Trials .... ',                'Callback',{@fMultipleTrials,4});
        S.hMenuDetect(1)         = uimenu(S.hMenuMulti(1),      'Label','dF/F Spike Detection...');
        S.hMenuDetect(2)         = uimenu(S.hMenuDetect(1),      'Label','Configure Filter ...',                            'Callback',{@fTwoPhotonDetection,3});
        S.hMenuDetect(3)         = uimenu(S.hMenuDetect(1),      'Label','Detect and Show ...',                             'Callback',{@fTwoPhotonDetection,4});
        S.hMenuDetect(4)         = uimenu(S.hMenuDetect(1),      'Label','Save Detect Results ...',                         'Callback',{@fTwoPhotonDetection,5});
        S.hMenuDetect(5)         = uimenu(S.hMenuDetect(1),      'Label','Refresh Data ...',                                'Callback',{@fMultipleGroups,9});

        S.hMenuRaw(1)            = uimenu(S.hMenuMulti(1),       'Label','Raw Data Analysis without ROI...'                );
        S.hMenuRaw(2)            = uimenu(S.hMenuRaw(1),         'Label','Configuration ...',                               'Callback',{@fTwoPhotonDetection,6});
        S.hMenuRaw(3)            = uimenu(S.hMenuRaw(1),         'Label','Analysis ...',                                    'Callback',{@fTwoPhotonDetection,7});
        S.hMenuRaw(4)            = uimenu(S.hMenuRaw(1),         'Label','SVD ...',                                         'Callback',{@fTwoPhotonDetection,8});
        S.hMenuRaw(5)            = uimenu(S.hMenuRaw(1),         'Label','Save new ROIs ...',                               'Callback',{@fTwoPhotonDetection,9});
        
        S.hMenuEventGal(1)      = uimenu(S.hMenuMulti(1),       'Label','Gals ROI Detector ...', 'separator','off');
        S.hMenuEventGal(2)      = uimenu(S.hMenuEventGal(1),    'Label','Configure ... ',                                   'Callback',{@fManageROI,21});
        S.hMenuEventGal(3)      = uimenu(S.hMenuEventGal(1),    'Label','Analysis ',                                        'Callback',{@fManageROI,22}, 'Enable','on');
        S.hMenuEventGal(6)      = uimenu(S.hMenuEventGal(1),    'Label','Show Results ... ',                                'Callback',{@fManageROI,23}, 'Enable','off');
        S.hMenuEventGal(7)      = uimenu(S.hMenuEventGal(1),    'Label','Import ROIs ... ',                                 'Callback',{@fManageROI,24});
        
        

        S.hMenuMulti(5)          = uimenu(S.hMenuMulti(1),       'Label','Behavior Compress. ...', 'separator','on',        'Callback',{@fMultipleTrials,21});
        S.hMenuMulti(6)          = uimenu(S.hMenuMulti(1),       'Label','Event Assignment. ...', 'separator','off',        'Callback',{@fMultipleTrials,22});
        S.hMenuMultiEvent(1)     = uimenu(S.hMenuMulti(1),       'Label','Events ... '                        );
        S.hMenuMultiEvent(2)     = uimenu(S.hMenuMultiEvent(1),  'Label','Event Removal ...',                               'Callback',{@fMultipleTrials,23});
        S.hMenuMultiEvent(3)     = uimenu(S.hMenuMultiEvent(1),  'Label','Constant Event Create ...',                       'Callback',{@fMultipleTrials,25});
        S.hMenuMultiEvent(4)     = uimenu(S.hMenuMultiEvent(1),  'Label','Average Processing ...',                          'Callback',{@fMultipleTrials,24});
        S.hMenuMultiEvent(5)     = uimenu(S.hMenuMultiEvent(1),  'Label','Copy Event and Shift Trial Index ...',            'Callback',{@fMultipleTrials,27});
        S.hMenuMultiEvent(7)     = uimenu(S.hMenuMultiEvent(1),  'Label','Event Preview for all Trials ...',                'Callback',{@fMultipleTrials,26});
        
%         S.hMenuMultiTraj(1)      = uimenu(S.hMenuMulti(1),       'Label','Trajectories ...'                       );
%         S.hMenuMultiTraj(2)      = uimenu(S.hMenuMultiTraj(1),   'Label','Parameter setup ...',                             'Callback',{@fManageEvent,20});
%         S.hMenuMultiTraj(3)      = uimenu(S.hMenuMultiTraj(1),   'Label','Generation ...',                                  'Callback',{@fMultipleTrials,31});
%         S.hMenuMultiTraj(4)      = uimenu(S.hMenuMultiTraj(1),   'Label','Show all ...',                                    'Callback',{@fMultipleTrials,33});

        S.hMenuMultiTraj(1)      = uimenu(S.hMenuMulti(1),       'Label','Trajectories ...'                       );
        S.hMenuMultiTraj(2)      = uimenu(S.hMenuMultiTraj(1),   'Label','Labeler App ...',                                 'Callback',{@fMultipleTrials,41});
        S.hMenuMultiTraj(3)      = uimenu(S.hMenuMultiTraj(1),   'Label','Training ...',                                    'Callback',{@fMultipleTrials,42});
        S.hMenuMultiTraj(4)      = uimenu(S.hMenuMultiTraj(1),   'Label','Test and Show ...',                               'Callback',{@fMultipleTrials,43});
        S.hMenuMultiTraj(5)      = uimenu(S.hMenuMultiTraj(1),   'Label','Import Trajectories ...',                         'Callback',{@fMultipleTrials,44});
        
        
        S.hMenuMulti(9)          = uimenu(S.hMenuMulti(1),       'Label','Multi Trial Event Editor. ...', 'separator','on',  'Callback',{@fMultipleTrials,24},'Enable','off');
        S.hMenuMulti(10)          = uimenu(S.hMenuMulti(1),      'Label','Multi Trial Explorer ...',                         'Callback',{@fMultipleTrials,5});
        S.hMenuMulti(11)         = uimenu(S.hMenuMulti(1),       'Label','Multi Trial Explorer from JAABA Excel ...',        'Callback',{@fMultipleTrials,6},'Enable','off');
        S.hMenuMulti(12)         = uimenu(S.hMenuMulti(1),       'Label','Active Roi per Event Analysis...',                 'Callback',{@fMultipleGroups,11});
        S.hMenuMulti(13)         = uimenu(S.hMenuMulti(1),       'Label','Early/Late Roi per Event Analysis...',             'Callback',{@fMultipleGroups,12});
        S.hMenuMulti(14)          = uimenu(S.hMenuMulti(1),      'Label','dF/F Spike Delay Map for all ROIs     ...',        'Callback',{@fMultipleGroups,13});
        S.hMenuMulti(15)          = uimenu(S.hMenuMulti(1),      'Label','dF/F Spike Delay Histograms for all ROIs ...',     'Callback',{@fMultipleGroups,14});
        S.hMenuMulti(16)          = uimenu(S.hMenuMulti(1),      'Label','dF/F Spike Delay Histograms for Ordered ROIs ...', 'Callback',{@fMultipleGroups,15});
        S.hMenuMulti(17)          = uimenu(S.hMenuMulti(1),      'Label','dF/F Spike Delay Mutual Order matrix ...',         'Callback',{@fMultipleGroups,16});
        S.hMenuMulti(18)          = uimenu(S.hMenuMulti(1),      'Label','Show Neuron Trace Order by dF/F Spike Delay ...',  'Callback',{@fMultipleGroups,18});
        S.hMenuMulti(19)          = uimenu(S.hMenuMulti(1),      'Label','Show Neuron Trace Order by Center of Activity ...','Callback',{@fMultipleGroups,17},'separator','on','Enable','off');
        S.hMenuMulti(20)          = uimenu(S.hMenuMulti(1),      'Label','Show Averaged Traces and Behavior Events ...',     'Callback',{@fMultipleGroups,20});
        S.hMenuMulti(21)          = uimenu(S.hMenuMulti(1),      'Label','Pearson Correlation Mtrx of dF/F ...',             'Callback',{@fMultipleGroups,21});
        S.hMenuMulti(22)          = uimenu(S.hMenuMulti(1),      'Label','Cluster ROI dF/F data ...',                        'Callback',{@fMultipleGroups,22},'separator','off');
         
        S.hMenuGroups(1)        = uimenu(S.hFig,                 'Label','Muti Experiment...');
        S.hMenuGroups(2)        = uimenu(S.hMenuGroups(1),       'Label','Multi Group Explorer Init.....', 'enable','on' ,    'Callback',{@fMultipleGroups,1});
        S.hMenuGroups(3)        = uimenu(S.hMenuGroups(1),       'Label','Averaged dF/F per ROI ...',                         'Callback',{@fMultipleGroups,2});
        S.hMenuGroups(4)        = uimenu(S.hMenuGroups(1),       'Label','Averaged dF/F per ROI and Ordered ...',             'Callback',{@fMultipleGroups,5});
        S.hMenuGroups(5)        = uimenu(S.hMenuGroups(1),       'Label','Correlation Analysis ...',                         'Callback',{@fMultipleGroups,3});
        S.hMenuGroups(6)        = uimenu(S.hMenuGroups(1),       'Label','Behavioral Events ...',                            'Callback',{@fMultipleGroups,4},'separator','on');
       
        S.hMenuEventsEP(1)      = uimenu(S.hMenuElectroPhys(1), 'Label','Events...');
        S.hMenuEventsEP(2)      = uimenu(S.hMenuEventsEP(1),      'Label','Load from File...',                      'Callback',{@fManageEventEP,1});
        S.hMenuEventsEP(3)      = uimenu(S.hMenuEventsEP(1),      'Label','New/Clean  ...',                         'Callback',{@fManageEventEP,2});
        S.hMenuEventsEP(4)      = uimenu(S.hMenuEventsEP(1),      'Label','Save ...',                               'Callback',{@fManageEventEP,3});
        S.hMenuEventsEP(5)      = uimenu(S.hMenuEventsEP(1),      'Label','Load...',                                'Callback',{@fManageEventEP,4});
        S.hMenuEventsEP(6)      = uimenu(S.hMenuEventsEP(1),      'Label','View All...',                            'Callback',{@fManageEventEP,5});
        S.hMenuEventsEP(7)      = uimenu(S.hMenuEventsEP(1),      'Label','Auto Detect...',                         'Callback','warndlg(''Is yet to come'')');
        S.hMenuElectroPhys(8)   = uimenu(S.hMenuElectroPhys(1),   'Label','Save Event Results',  'separator','on',  'Callback',{@fManagElectroPhys,5});
        
        
        
%         S.hMenuCalcium(1)       = uimenu(S.hFig,                  'Label','Calcium...');
%         S.hMenuCalcium(2)       = uimenu(S.hMenuCalcium(1),       'Label','One time init after Selection...',         'Callback',{@fManageCalcium,1});
%         S.hMenuCalcium(3)       = uimenu(S.hMenuCalcium(1),       'Label','Set Trial Num...',                         'Callback',{@fManageCalcium,2});
%         S.hMenuCalcium(4)       = uimenu(S.hMenuCalcium(1),       'Label','Config Data...',                           'Callback',{@fManageCalcium,3});
%         S.hMenuCalcium(5)       = uimenu(S.hMenuCalcium(1),       'Label','Load Trial Data...',                       'Callback',{@fManageCalcium,4});
%         S.hMenuCalcium(6)       = uimenu(S.hMenuCalcium(1),       'Label','View XY...',                               'Callback',{@fManageCalcium,5});
%         S.hMenuCalcium(7)       = uimenu(S.hMenuCalcium(1),       'Label','View YT...',                               'Callback',{@fManageCalcium,6});
       
        
        
%         S.hMenuView(1)          = uimenu(S.hFig,                'Label','View...');
%         S.hMenuView(2)          = uimenu(S.hMenuView(1),        'Label','Raw data in T ',                           'Callback','warndlg(''Is yet to come'')',  'Checked', 'on');
%         S.hMenuView(3)          = uimenu(S.hMenuView(1),        'Label','Raw data in Z ',                           'Callback','warndlg(''Is yet to come'')',  'Checked', 'off');
%         S.hMenuView(4)          = uimenu(S.hMenuView(1),        'Label','dF/F + Behavior. ...',                     'Callback',{@fViewResults,1});
%         S.hMenuView(5)          = uimenu(S.hMenuView(1),        'Label','dF/F all ROIs     ...',                    'Callback',{@fViewResults,2});
%         S.hMenuView(6)          = uimenu(S.hMenuView(1),        'Label','ROI Cursor Measure ...',                   'Callback',{@fViewResults,3});
        
        S.hMenuExport(1)        = uimenu(S.hFig,                'Label','Help...');
        S.hMenuExport(2)        = uimenu(S.hMenuExport(1),      'Label','Manual ...',                               'Callback',{@fViewResults,1});
        S.hMenuExport(3)        = uimenu(S.hMenuExport(1),      'Label','How To ...',                               'Callback',{@fViewResults,1});
        S.hMenuExport(4)        = uimenu(S.hMenuExport(1),      'Label','About ...',                                'Callback','warndlg(''Created by : Uri Dubin - uri.dubin@gmail.com'')');
        
        
        %         S.hMenuStam(1)      = uimenu(S.hFig(1),'Label','Variable');
        %         uimenu(S.hMenuStam(1) ,'Label','Name...', 'Callback','variable');
        %         uimenu(S.hMenuStam(1) ,'Label','Value...', 'Callback','value');
        
        % close this menu
        %set(S.hMenuExpElectro,'Enable','off');
        
        % sync all components
        SGui.hMain = S.hFig;
        setappdata(SGui.hMain, 'fSyncAll', @fSyncAll);

        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * Defines state of all buttons
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fUpdateGUI() %#ok<*INUSD> eventdata is trialedly unused
        
        % TBD
        return
        
        if isempty(SData.strRecord)
        end;
        if isempty(SData.imTwoPhoton)
            set(S.hMenuImage,   'Enable','off')
            set(S.hMenuRoi,     'Enable','off')
            set(S.hMenuAverage, 'Enable','off')
            set(S.hMenuExport,  'Enable','off')
        else
            set(S.hMenuImage,   'Enable','on')
            set(S.hMenuRoi,     'Enable','on')
        end;
        if isempty(SData.strROI2)
            %set(S.hMenuRoi(2:3),'Enable','off')
            set(S.hMenuAverage, 'Enable','off')
            set(S.hMenuProcess, 'Enable','off')
            set(S.hMenuView,    'Enable','off')
            set(S.hMenuExport,  'Enable','off')
        else
            set(S.hMenuRoi,     'Enable','on')
            set(S.hMenuAverage, 'Enable','on')
            if isfield(SData.strROI2{1},'procROI')
                if ~isempty(SData.strROI2{1}.procROI)
                    set(S.hMenuView,    'Enable','on')
                    set(S.hMenuExport,  'Enable','on')
                else
                    set(S.hMenuProcess, 'Enable','on')
                    set(S.hMenuView,    'Enable','off')
                    set(S.hMenuExport,  'Enable','off')
                end;
            end;
        end;
        
        set(S.hMenuFile(2), 'Enable','off')      % not in use
        set(S.hMenuProcess(end), 'Enable','off') % not supported Konnerth
        set(S.hMenuView(2:3),'Enable','off');    % not in use
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * Is called by children GUI Windows - to inform/sync other childrens
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function  fSyncAll(srcId,eventData) %
        % receives srcId and eventId
        if eventData.msgId ~= Par.EVENT_TYPES.UPDATE_POS,
            return
        end
        % get event and spread it
        for m = 1:length(SGui.hChildList),
            fSyncRecv = getappdata(SGui.hChildList(m), 'fSyncRecv');
            feval(fSyncRecv,srcId,eventData);
        end
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * Arrange figures sets up figures in the screen
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fArrangeFigures(hObject, eventdata) %#ok<*INUSD> eventdata is trialedly unused
        
        screenSize  = get(0,'ScreenSize');
        if screenSize(3) < 850 || screenSize(4) < 620,
            warndlg('Can not arrange figures. Please do it manually')
        end
        xScale  = screenSize(3)/1920; yScale = screenSize(4)/ 1200;
        scVect  = [xScale yScale xScale yScale];
        
        hFigLB = findobj('Name','4D : Behavior Time Editor');    
        if ~isempty(hFigLB), set(hFigLB,'pos',[110          65        1098         419].*scVect); end;
        hFigRB = findobj('Name','4D : Behavior Image Editor');    
        if ~isempty(hFigRB), set(hFigRB,'pos',[1228          67         518         419].*scVect); end;
        hFigLU = findobj('Name','4D : TwoPhoton Time Editor');    
        if ~isempty(hFigLU), set(hFigLU,'pos',[109         577        1100         458].*scVect); end;
        hFigRU = findobj('Name','4D : TwoPhoton Image Editor');    
        if ~isempty(hFigRU), set(hFigRU,'pos',[1228         581         513         456].*scVect); end;
        
%         iptwindowalign(hFigLU,'right',hFigRU,'left');
%         iptwindowalign(hFigLU, 'hcenter', hFigLB, 'hcenter');
%         iptwindowalign(hFigLB,'right',hFigRB,'left');
        
    end


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * Closes figures with special tag names
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCloseFigures(hObject, eventdata) %#ok<*INUSD> eventdata is trialedly unused
        
        fUpdateGUI();
        
        try
            % close all childs
            if exist('SGui','var')
            if ~isempty(SGui.hChildList),
                if all(ishandle(SGui.hChildList)),
                    close(SGui.hChildList);
                end
            end
            end
        catch ex
           % errordlg(ex.getReport('basic'),'Close GUI Window Error','modal');
        end
        
       
        hFigs = findobj('Tag','AnalysisROI'); 
        try
            delete(hFigs);
        catch ex
            errordlg(ex.getReport('basic'),'Close Other Window Error','modal');
        end
        
        %delete(S.hFig);
        
    end

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * Figure callback
% * *
% * * Closes the figure and saves the settings
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCloseGUI(hObject, eventdata) %#ok<*INUSD> eventdata is trialedly unused
        % save user params
        fManageSession(0,0,3);        
        fManageExperiment(0,0,9);
        
        try
            fCloseFigures(0,0);            
            delete(SGui.hMain)
        catch ex
            errordlg(ex.getReport('basic'),'Close Other Window Error','modal');
        end
        delete(hObject); % Bye-bye figure
    end

end
% =========================================================================
% *** END FUNCTION  (and its nested functions)
% =========================================================================

