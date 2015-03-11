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
% 19.20 13.01.15 UD 	Trajectory in behavioral space cont
% 19.17 30.12.14 UD 	Trajectory in behavioral space 
% 19.16 22.12.14 UD 	Fixing bugs in Group and Adding cursors to MultiTrial Explorer.
% 19.12 21.10.14 UD 	Merging with 1909. Fixes and bugs.
% 19.06 21.09.14 UD 	Adding import to movie_comb.avi file from new JAABA_multi SW
% 18.13 10.07.14 UD     Adding Group Analysis and improve auto detect .
% 18.10 08.07.14 UD     Adding tool of multi experiment explorer.
% 18.09 06.07.14 UD     Back to Janelia.
% 18.03 25.04.14 UD     Rename and fixing bugs in Jaaba import.
% 18.01 13.04.14 UD     One GUI for ElectroPhys
% 17.08 05.04.14 UD     Recheck ROI problems by synthetic data gen
% 17.06 28.03.14 UD     Jaaba import and auto detect two photon events
% 17.05 22.03.14 UD     Working on auto detect of the cells. Fixing small bugs
% 17.04 21.03.14 UD     Recheck registration
% 17.03 12.03.14 UD     Batch registration fix
% 17.02 10.03.14 UD     All cells are extracted in batch and processed even they do not appear.
% 17.01 06.03.14 UD     Explorer improve. Export to Tiff registration.
% 17.00 04.03.14 UD     ROI names management.
% 16.26 04.03.14 UD     Adding features : x - line and selection of ROI names.
% 16.23 26.02.14 UD     Counters....
% 16.22 26.02.14 UD     Version backup - previous in tests.
% 16.21 26.02.14 UD     Counter in the session file and session is moved to experiment.
% 16.20 26.02.14 UD     Multi Trial improving. Bug in save.
% 16.19 24.02.14 UD     Multi Trial.
% 16.13 23.02.14 UD     Adding ROI analysis.
% 16.11 22.02.14 UD     testing.
% 16.10 21.02.14 UD     communication is only on position.
% 16.07 20.02.14 UD     renaming.
% 16.06 19.02.14 UD     ROI management.
% 16.05 18.02.14 UD     Sync .Jackies bugs.
% 16.03 16.02.14 UD     Adding Data Sync options. Changing Data to global.
% 16.02 15.02.14 UD     Restructuring. Front and Side are the same. Make
%                       global image data
% 16.00 13.02.14 UD     Janelia Data integration
% 15.01 06.02.14 UD     Email comments
% 15.00 10.01.14 UD     Janelia support
% 13.01 10.11.13 UD     working on ROI. Adding Janelia support
% 13.00 03.11.13 UD     ROI edit
% 12.01 14.09.13 UD     working on Z stack
% 12.00 03.09.13 UD     working on Z stack
% 11.09 20.08.13 UD     improvement and bug fixes. Adding cursor management
% 11.06 06.08.13 UD     two image channel support
% 11.05 30.07.13 UD     update for save
% 11.02 15.07.13 UD     Improving.
% 11.00 08.07.13 UD     Working to implement differnt options.
% 10.07 25.06.13 UD     Extracting data to Igor.
%-----------------------------
% remove any global var if any
%clear all;

% version
currVers    = '19.24';

% connect
addpath(genpath('.'));

%%%
% GUI handles
%%%
S            = [];

%%%
% Control params
%%%
Par           = TPA_ParInit;

%%%
% Data struct shared by all
%%%
global SData;
SData        = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[],'strManager',struct('roiCount',0,'eventCount',0)); % strManager will manage counters

%%%
% GUI handles visible to all
%%%
% main and all other gui windows required for sync. Contains current user position in 4D space
global SGui     % handle main     handle guis     user clck :x,y,z,t
SGui         = struct('hMain',[],'hChildList',[],'usrInfo',[]); 


% load default user settings
SSave       = [];  % can not load without init definition

%  managers
mcObj       = TPA_MotionCorrectionManager();
dmROIAD     = TPA_ManageRoiAutodetect();
dmEVAD      = TPA_ManageEventAutodetect(Par);
dmFileDir   = TPA_DataManagerFileDir();
gdm         = TPA_MultiTrialGroupDetect();
objTrack    = TPA_OpticalFlowTracking();




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
% * *
% * * NESTED FUNCTION fManageSession (nested in main)
% * *
% * * save,load and clear current session data
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageSession(hObject, eventdata, selType)
                
        userSessionFileName    = fullfile(Par.SetupDir,Par.SetupFileName);
        
        switch selType,
            
            case 1, % load last session
                if exist(userSessionFileName, 'file'),
                    try
                        SSave = load(userSessionFileName);
                        %Par   = SSave.ExpDir;
                    catch ex
                        errordlg(ex.getReport('basic'),'File Type Error','modal');
                    end
                end
                % clear all
                %SData            = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[]);
                %DTP_ManageText([], sprintf('Session : Setting path to data %. Clearing the internal memory.',SSave.ExpDir), 'I' ,0)   ;
                
                
            case 2, % load session user mode
                
                [csFilenames, sPath] = uigetfile(...
                    {   '*.mat', 'mat Files'; '*.*', 'All Files'}, ...
                    'OpenLocation'  , Par.SetupDir, ...
                    'Multiselect'   , 'off');
                
                if isnumeric(sPath), return, end;   % Dialog aborted
                
                % if single file selected
                if iscell(csFilenames), csFilenames = csFilenames{1}; end;
                userSessionFileName    = fullfile(sPath,csFilenames);
                try
                    SSave = load(userSessionFileName); % load all info
                    catch ex
                        errordlg(ex.getReport('basic'),'File Type Error','modal');
                end
                % remember the name of the session
                Par.SetupFileName       = csFilenames;
                Par.ExpDir              = sPath;
                
            case 3, % save the session
                 %DTP_ManageText([], sprintf('Session : Saving data setup. Analysis data is not saved. '), 'I' ,0)   ;
               
                % Save the settings
                SSave.ExpDir        = Par.DMT.RoiDir;
                try %#ok<TRYNC>
                    save(userSessionFileName,'-struct', 'SSave');
                end
                
            case 4, % save session as...
                
               [filename, pathname] = uiputfile('*.mat', 'Save Session file',Par.SetupFileName);
                if isequal(filename,0) || isequal(pathname,0),  return;    end
                
                userSessionFileName = fullfile(pathname, filename);
                % Save the settings
                SSave.ExpDir        = Par.DMT.VideoDir;
                try %#ok<TRYNC>
                    save(userSessionFileName,'-struct', 'SSave');
                end
                
            case 5, % clear/new session
                
%                 buttonName = questdlg('All the numbering of ROis and Events will be lost', 'Warning');
%                 if ~strcmp(buttonName,'Yes'), return; end;
%                   
%                 SSave.ExpDir        = Par.DMT.VideoDir;
%               
%                 DTP_ManageText([], sprintf('Session : Clearing all the video and analysis data.'), 'W' ,0)   ;
%                % Clear all the previous data
%                 SData           = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[]);
%                 Par             = TPA_ParInit;
%                 
%                 try %#ok<TRYNC>
%                     save(userSessionFileName,'-struct', 'SSave');
%                 end
                
                % close figures
                fCloseFigures(0,0)    ;
                
            otherwise
                error('Bad session selection %d',selType)
        end
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fManageSession
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fManageJaneliaExperiment (nested in main)
% * *
% * * sellects and check experiment data from Janelia
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageJaneliaExperiment(hObject, eventdata, selType)
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Which data
        %%%%%%%%%%%%%%%%%%%%%%
        
        %FigNum              = Par.FigNum; % 0-no show 1-shows the image,2-line scans
        switch selType,
            
          case 1, % new experiment - file style
                fManageJaneliaExperiment(0,0,3);        
              
                % set up fiile
                buttonName = questdlg('If you select previous experiment folder : all the numbering of ROis and Events will be lost', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                 % determine the path - do not certain directory structure
                Par                 = TPA_ParInit;         
                SData               = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[],'strManager',struct('roiCount',0,'eventCount',0)); % strManager will manage counters
                
                % recall last directory
                fManageSession(0, 0, 1);
                dirName             = SSave.ExpDir;
                 
             
                % analysis directory
                dirName             = uigetdir(dirName,'Select Analysis directory that belongs to Experiment (i.e. ..Analysis\m76\1-10-14)');
                if isnumeric(dirName), return; end;  % cancel button

                Par.DMT             = Par.DMT.SelectAnalysisData(dirName);
                Par.DMB             = Par.DMB.SelectAnalysisData(dirName);

                % two photon imaging directory
                dirName             = uigetdir(dirName,'Select Two Photon image data directory that belongs to Experiment (i.e. ..Imaging\m76\1-10-14)');
                if isnumeric(dirName), return; end;  % cancel button
                Par.DMT             = Par.DMT.SelectTwoPhotonData(dirName);
          
                % behavior directory
                dirName             = uigetdir(dirName,'Select Beahavior image data directory that belongs to Experiment (i.e. ..Videos\m76\1-10-14)');
                if isnumeric(dirName), return; end;  % cancel button
                Par.DMB             = Par.DMB.SelectBehaviorData(dirName,'all');
                
                % check
                Par.DMT             = Par.DMT.CheckData();
                Par.DMB             = Par.DMB.CheckData();
                
                % create new Excel file
                dmFileDir           = dmFileDir.Init(Par);
                dmFileDir           = dmFileDir.SaveExcelFile(Par);
                   
                % remember session
                fManageJaneliaExperiment(0,0,3);   
                
                % save session
                %fManageSession(0, 0, 3);
                 
            case 2, % load experiment - select directory
                % save data before
                fManageJaneliaExperiment(0,0,3);                        
                
                dirName             = uigetdir(SSave.ExpDir,'Select Analysis directory that belongs to Experiment');
                if isnumeric(dirName), return; end;  % cancel button
                
                SData               = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[],'strManager',struct('roiCount',0,'eventCount',0));                
                expFileName         = fullfile(dirName,Par.ExpFileName);
                try 
                    SSave           = load(expFileName);
                    SData.strManager= SSave.strManager; % counters
                 catch
                    DTP_ManageText([], sprintf('Experiment : Can not load file %s',expFileName), 'E' ,0)   ;  
                    return
                end
                SSave.ExpDir        = dirName;
                
%                 % check - see if directory structure is updated
%                 Par.DMT             = Par.DMT.SelectAllData(dirName);
%                 Par.DMB             = Par.DMB.SelectAllData(dirName,'all');
%                 
%                 
%                 % check
%                 [Par.DMT,isOK]      = Par.DMT.CheckData();
%                 [Par.DMB,isOK]      = Par.DMB.CheckData();
%                 
                
                % load from Excel
                dmFileDir           = dmFileDir.Init(Par) ;
                dmFileDir           = dmFileDir.LoadExcelFile(dirName) ;
                
                % init data base
                Par                 = dmFileDir.ParInit(Par);     
                
%                 % check
%                 [Par.DMT,isOK]      = Par.DMT.CheckData();
%                 if ~isOK,                     
%                     DTP_ManageText([], sprintf('Experiment : Excel file %s could contain non valid info for two photon data location',expFileName), 'E' ,0)   ;
%                 end
% 
%                 [Par.DMB,isOK]      = Par.DMB.CheckData();
%                 if ~isOK,                     
%                     DTP_ManageText([], sprintf('Experiment : Excel file %s could contain non valid info for behavioral data location',expFileName), 'E' ,0)   ;
%                 end
                
                % save session
                fManageSession(0, 0, 3);
                
                
         case 3, % save experiment settings
             
                % if at least one load has been done
                if Par.DMT.RoiFileNum < 1 , return; end; % No load - nothing to save
                
                % Save the settings
                SSave.ExpDir        = Par.DMT.RoiDir;
                SSave.strManager    = SData.strManager;
                % SSave.StrEventClass = []; % use old classifier if assigned

                expFileName         = fullfile(SSave.ExpDir,Par.ExpFileName);                
                try 
                    save(expFileName,'-struct', 'SSave');
                    DTP_ManageText([], sprintf('Experiment : Saving current configuration. '), 'I' ,0)   ;
                catch
                    DTP_ManageText([], sprintf('Experiment : Can not save file %s',expFileName), 'E' ,0)   ;             
                end
   
                
                % save session
                fManageSession(0, 0, 3);
                
          
            case 4, % Refresh Excel file
                
                %fManageJaneliaExperiment(0,0,2);   
                
                dirName             = uigetdir(SSave.ExpDir,'Select Analysis directory that belongs to Experiment');
                if isnumeric(dirName), return; end;  % cancel button
                
                
                % check directory
                %dirName             = SSave.ExpDir;
                
                % check
                Par.DMT             = Par.DMT.SelectAllData(dirName);
                Par.DMB             = Par.DMB.SelectAllData(dirName,'all');

                
                % check
                Par.DMT             = Par.DMT.CheckData();
                Par.DMB             = Par.DMB.CheckData();
                
                
                % save to excel
                fManageJaneliaExperiment(0,0,7);                   
                
                
          
          case 5, % check data sync - open GUI
                
                % start GUI
                Par                 = TPA_DataAlignmentCheck(Par);
                
                % check
                %Par.DMT             = Par.DMT.CheckData();
                %Par.DMB             = Par.DMB.CheckData();
                
         
            case 6, % preview current Excel file
                
                % start GUI
                fileExcelName      = fullfile(dmFileDir.ExpDir,dmFileDir.FileName);
                try 
                    winopen(fileExcelName);
                    DTP_ManageText([], sprintf('Experiment : New configuration is done. '), 'I' ,0)   ;                    
                 catch
                    DTP_ManageText([], sprintf('Experiment : Can not open file %s',fileExcelName), 'E' ,0)   ;             
                end
                
         case 7, % save experiment to excel
             
                % if at least one load has been done
%                 if Par.DMT.VideoFileNum < 1,
%                     DTP_ManageText([], sprintf('Experiment : First select or load some experiment. '), 'E' ,0)   ;
%                     return; 
%                 end; % No load - nothing to save
                %dirName             = Par.DMT.RoiDir;
                
                % create new Excel file
                dmFileDir           = dmFileDir.SaveExcelFile(Par);
                
                % Save the settings
                fManageJaneliaExperiment(0,0,3);   
                
                
            case 8, %  experiment - old style
                fManageJaneliaExperiment(0,0,3);        
              
%                 % set up fiile
%                 buttonName = questdlg('If you select previous experiment folder : all the numbering of ROis and Events will be lost', 'Warning');
%                 if ~strcmp(buttonName,'Yes'), return; end;
              
                dirName             = uigetdir(SSave.ExpDir,'Select any directory that belongs to Experiment (i.e. ..Analysis\m76\1-10-14)');
                if isnumeric(dirName), return; end;  % cancel button
                
                % determine the path - assume certain directory structure
                Par                = TPA_ParInit;         
                
                SData               = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[],'strManager',struct('roiCount',0,'eventCount',0)); % strManager will manage counters
                Par.DMT             = Par.DMT.SelectAllData(dirName);
                Par.DMB             = Par.DMB.SelectAllData(dirName);
                % check
                Par.DMT             = Par.DMT.CheckData();
                Par.DMB             = Par.DMB.CheckData();
                
                % save settings
                fManageJaneliaExperiment(0,0,3);   
            
                
          
%                 
%             case 11, % new SW version  - load movie_comb.avi from directories 
%                 % save
%                 fManageJaneliaExperiment(0,0,3);  
%                 
%                 %dirName             = uigetdir(SSave.ExpDir,'Jaaba Data Directory');
%                 dirName             = uigetdir(SSave.ExpDir,'Select any directory that belongs to Experiment (i.e. ..Analysis\m76\1-10-14)');
%                 if isnumeric(dirName), return; end;  % cancel button  
%                 
%                 % determine the path - assume certain directory structure
%                 Par                = TPA_ParInit;         
%   
%                 % init Behave and Two Photon
%                 SData               = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[],'strManager',struct('roiCount',0,'eventCount',0)); % strManager will manage counters
%                 
%                 % import JAABA - event from scores and movies from movie_comb.avi
%                 SSave.ExpDir        = dirName;  % path this info for Jaaba
%                 fImportResults(0, 0, 1);
%                 
%                 
%                 Par.DMT             = Par.DMT.SelectAllData(dirName);
%                 Par.DMB             = Par.DMB.SelectAllData(dirName,'comb');
%                 % check
%                 Par.DMT             = Par.DMT.CheckData();
%                 Par.DMB             = Par.DMB.CheckData();
%                 
%                  
%                 expFileName         = fullfile(Par.DMB.EventDir,Par.ExpFileName);                
%                 SSave.ExpDir        = dirName;
%                 SSave.StrEventClass = []; % new classifier
%                 try 
%                     save(expFileName,'-struct', 'SSave');
%                     DTP_ManageText([], sprintf('Experiment : New configuration is done. '), 'I' ,0)   ;                    
%                  catch
%                     DTP_ManageText([], sprintf('Experiment : Can not save file %s',expFileName), 'E' ,0)   ;             
%                 end
%                 
                
            otherwise
                error('Bad  selection %d',selType)
        end
        
        % save path
        %fManageSession(0,0,3);
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fManageJaneliaExperiment
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fManageElectroPhysExperiment (nested in main)
% * *
% * * sellects and check experiment data from Electro Physiology
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageElectroPhysExperiment(hObject, eventdata, selType)
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Which data
        %%%%%%%%%%%%%%%%%%%%%%
        
        %FigNum              = Par.FigNum; % 0-no show 1-shows the image,2-line scans
        switch selType,
            
          case 1, % new experiment
                fManageElectroPhysExperiment(0,0,3);        
              
                % set up fiile
                buttonName = questdlg('If you select previous experiment folder : all the numbering of ROis and Events will be lost', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
              
                dirName             = uigetdir(SSave.ExpDir,'Select any directory that belongs to Experiment (i.e. ..Analysis\m76\1-10-14)');
                if isnumeric(dirName), return; end;  % cancel button
                
                % determine the path - assume certain directory structure
                Par                = TPA_ParInit;         
                
                SData               = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[],'strManager',struct('roiCount',0,'eventCount',0)); % strManager will manage counters
                Par.DMT             = Par.DMT.SelectAllData(dirName);
                Par.DME             = Par.DME.SelectAllData(dirName);
                % check
                Par.DMT             = Par.DMT.CheckData();
                Par.DME             = Par.DME.CheckData();
                
                   
                expFileName         = fullfile(Par.DMT.RoiDir,Par.ExpFileName);
                SSave.strManager    = SData.strManager;
                SSave.ExpDir        = dirName;
                try 
                    save(expFileName,'-struct', 'SSave');
                 catch
                    DTP_ManageText([], sprintf('Experiment : Can not save file %s',expFileName), 'E' ,0)   ;             
                end
                 
             
            
            case 2, % load experiment - select directory
                % save data before
                fManageElectroPhysExperiment(0,0,3);                        
                
                dirName             = uigetdir(SSave.ExpDir,'Select any directory that belongs to Experiment');
                if isnumeric(dirName), return; end;  % cancel button
                
                SData               = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[],'strManager',struct('roiCount',0,'eventCount',0));                
                expFileName         = fullfile(dirName,Par.ExpFileName);
                try 
                    SSave           = load(expFileName);
                    SData.strManager= SSave.strManager; % counters
                 catch
                    DTP_ManageText([], sprintf('Experiment : Can not load file %s',expFileName), 'E' ,0)   ;             
                end
                
                SSave.ExpDir        = dirName;
              
                % determine the path - assume certain directory structure - find new files
                Par.DMT            = Par.DMT.SelectAllData(dirName);
                Par.DME            = Par.DME.SelectAllData(dirName);
                
                % check
                Par.DMT             = Par.DMT.CheckData();
                Par.DME             = Par.DME.CheckData();
                
         case 3, % save experiment
             
                % if at least one load has been done
                if Par.DMT.VideoFileNum < 1, return; end; % No load - nothing to save
                
                % Save the settings
                SSave.ExpDir        = Par.DMT.RoiDir;
                SSave.strManager    = SData.strManager;
                expFileName         = fullfile(SSave.ExpDir,Par.ExpFileName);                
                try 
                    save(expFileName,'-struct', 'SSave');
                    DTP_ManageText([], sprintf('Experiment : Saving current configuration. '), 'I' ,0)   ;
                 catch
                    DTP_ManageText([], sprintf('Experiment : Can not save file %s',expFileName), 'E' ,0)   ;             
                end
                
               
          
          case 4, % check data sync - open GUI
                
                % start GUI
                Par                 = TPA_DataAlignmentCheck(Par);
                
                % check
                Par.DMT             = Par.DMT.CheckData();
                Par.DME             = Par.DME.CheckData();
                
                %uiwait(hFig)
                
            otherwise
                error('Bad  selection %d',selType)
        end
        
        % save path
        %fManageSession(0,0,3);
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fManageElectroPhysExperiment
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fSelectTrial (nested in main)
% * *
% * * selects which trial to load
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function [dmObj,isOK] = fSelectTrial(dmObj)
        
        % dmObj - data managing object
        if nargin < 1, error('Must input Data Managing Object'); end
        
        isOK                = false; % support next level function
        options.Resize      ='on';
        options.WindowStyle ='modal';
        options.Interpreter ='none';
        prompt              = {sprintf('Enter trial number between %d:%d',1,dmObj.ValidTrialNum)};
        name                ='Choose trial to load';
        numlines            = 1;
        defaultanswer       ={num2str(dmObj.Trial)};
        
        answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
        if isempty(answer), return; end;
        trialInd           = str2double(answer{1});
        
        % check validity
        [dmObj,isOK]        = dmObj.SetTrial(trialInd);
        
        if~isequal(Par.DMT.Trial,Par.DMB.Trial), 
            DTP_ManageText([], 'TwoPhoton and Behavior datasets have different trials numbers', 'W' ,0)   ;             
        end
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fSelectTrial
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fSetDataParameters (nested in main)
% * *
% * * determines X,Y,Z and T resolution and decimation parameters
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function [dmObj,isOK] = fSetDataParameters(dmObj)
        
        % dmObj - data managing object
        if nargin < 1, error('Must input Data Managing Object'); end
        
        % config small GUI
        isOK                  = false; % support next level function
        options.Resize        ='on';
        options.WindowStyle     ='modal';
        options.Interpreter     ='none';
        prompt                  = {'Data Resolution [X [um/pix] Y [um/pix] Z [um/frame] T [frame/sec]',...
                                'Data Decimation Factor [X [(int>0)] Y [(int>0)] Z [(int>0)] T [(int>0)]',...            
                                'Data Offset (N.A.)    [X [um] Y [um] Z [um] T [frame] ',...            
                                'Slice Tiff File on Multiple Z Stacks [nZ - number of Z] ',...            
                                };
        name                ='Config Data Parameters';
        numlines            = 1;
        defaultanswer       ={num2str(dmObj.Resolution),num2str(dmObj.DecimationFactor),num2str(dmObj.Offset),num2str(dmObj.SliceNum)};
        answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
        if isempty(answer), return; end;
        
        
        % try to configure
        res                 = str2num(answer{1});
        [dmObj,isOK1]       = dmObj.SetResolution(res) ;       
        dec                 = str2num(answer{2});
        [dmObj,isOK2]       = dmObj.SetDecimation(dec) ;       
        isOK                = isOK1 && isOK2;
        slc                 = str2num(answer{4});
        [dmObj,isOK2]       = dmObj.SetSliceNum(slc) ;       
        isOK                = isOK1 && isOK2;
        
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fSetDataParameters
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fManageBehavior (nested in main)
% * *
% * * shows and explore behavior image data along with events
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageBehavior(hObject, eventdata, selType)
        
        %%%%%%%%%%%%%%%%%%%%%%
        % What
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1, % select and load predefined trial
                
                % select GUI
                [Par.DMB,isOK] = fSelectTrial(Par.DMB);            %vis4d(uint8(SData.imTwoPhoton));
                if ~isOK,
                    DTP_ManageText([], 'Behavior : Trial Selection problems', 'E' ,0)   ;                  
                end
                
            case 11,
                % determine data params
                [Par.DMB,isOK] = fSetDataParameters(Par.DMB);
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
 
                
           case 5,
                % edit YT
                if ( Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ) || isempty(SData.imBehaive),
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
                
                % close previous
                hFigLU = findobj('Name','4D : Behavior Time Editor');    
                if ~isempty(hFigLU), close(hFigLU); end;
                hFigRU = findobj('Name','4D : Behavior Image Editor');    
                if ~isempty(hFigRU), close(hFigRU); end;
                
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
                
          case 21,
                % Behavioral data compression
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                buttonName = questdlg('Current trial Behaivioral Video data will be changed.', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                Par.DMB           = Par.DMB.CompressBehaviorData(Par.DMB.Trial,'all');
                
          case 22,
                % Behavioral data check
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                
                Par.DMB           = Par.DMB.CheckImageData(SData.imBehaive);
                
                
            otherwise
                errordlg('Unsupported Type')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fManageTwoPhoton
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fManageEvent (nested in main)
% * *
% * * Manages event data for analysis
% * *
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
            case 1,
                % load previous
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
                load(userDataFileName,'StrEvent');
                SData.strEvent       = StrEvent;
                catch ex
                        errordlg(ex.getReport('basic'),'File Type Error','modal');
                end
                
            case 2, % new
                
                buttonName = questdlg('All the previous Event data in the current trial will be lost', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                SData.strEvent        = {};
                
            case 3,
%                 % save
%                 if Par.DMB.BehaviorNum < 1 ,
%                     warndlg('Please select Trial and load the Behavior image data first.');
%                     return
%                 end;
                
                % start save
                Par.DMB                     = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'StrEvent',SData.strEvent);
                
            case 4,
                % load
                [Par.DMB,SData.strEvent]   = Par.DMB.LoadAnalysisData(Par.DMB.Trial,'strEvent');
                

            case 5,
                return
                
            case 11, % Init
                dmEVAD          = DeleteData(dmEVAD);
                dmEVAD          = InitClassifier(dmEVAD);
                
            case 12, % Load
                
                % load SSave structure
                fManageJaneliaExperiment(0,0,2);
                dmEVAD.ClassPrm = SSave.StrEventClass;
                
             case 13, % Save
                
                % save to SSave structure
                SSave.StrEventClass = dmEVAD.ClassPrm;
                fManageJaneliaExperiment(0,0,3);
                
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
  
            case 20, % Update params for trajectories - KLT Optical Flow
                
                % assume object is initialized
                
                % config small GUI 
                options              = struct('Resize','on','WindowStyle','modal','Interpreter','none');
                prompt                = {'Min Trajectory Length  [frames]',...
                                         'Min Move Length (std(X)+std(Y)) [pix]',...            
                                        };
                name                = 'Config Track Parameters';
                numlines            = 1;
                defaultanswer       ={num2str(objTrack.TrackMinLength),num2str(objTrack.TrackPosStdThr)};
                answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
                if isempty(answer), return; end;


                % try to configure
                objTrack.TrackMinLength   = max(1,min(1000,str2num(answer{1})));
                objTrack.TrackPosStdThr   = max(1,min(1000,str2num(answer{2})));
                
                DTP_ManageText([], 'Behavior : Track parameters are updated.', 'I' ,0)   ;   
                
                
            case 21, % Find trajectories - KLT Optical Flow
                
                if verLessThan('matlab', '8.4.0'), 
                    errordlg('This function requires Matlab R2014b'); 
                    return; 
                end;

                
                % test init behavior
                if Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                
                % close all figures - will prevent event data sync problem
                %fCloseFigures();
                
                % determine if we have current event info
                if isempty(SData.imBehaive),
                    [Par.DMB, SData.imBehaive] = Par.DMB.LoadBehaviorData(Par.DMB.Trial,'side');
                else
                   % Par.DMB                    = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'StrEvent',SData.strEvent);
                end
                
                
                % Init Tracking algorithm 
                objTrack            = TrackBehavior(objTrack);

                
            case 22, % Filtered
                
                objTrack            = ShowLinkage(objTrack, true);

            case 23, % Filtered
                
                objTrack            = ShowLinkage(objTrack, false);
                
            case 24,
        end;
        
        
        %%%
        % Save Event do not ask
        %%%
       % Par.DMB            = Par.DMB.SaveAnalysisData(Par.DMB.Trial,'StrEvent',SData.strEvent);
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fManageEvent
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fManageTwoPhoton (nested in main)
% * *
% * * shows and explore image data. fix some artifacts
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageTwoPhoton(hObject, eventdata, selType)
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1, % selection
                
                [Par.DMT,isOK]              = fSelectTrial(Par.DMT);            %vis4d(uint8(SData.imTwoPhoton));
                if ~isOK,
                    DTP_ManageText([], 'TwoPhoton : trial selection failed', 'E' ,0)   ;                  
                end
                
            case 11,
                % determine data params
                [Par.DMT,isOK]              = fSetDataParameters(Par.DMT);
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
                if length(strROI) > 0 && length(SData.strROI) > 0,
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
                Par             = TPA_TwoPhotonEditorXY(Par);
                
           case 4,
                % preview YT
                if Par.DMT.VideoFileNum < 1 || isempty(SData.imTwoPhoton),
                    warndlg('Need to load Two Photon data first.');
                    return
                end;
                Par             = TPA_TwoPhotonEditorYT(Par);
                %TPA_TwoPhotonEditorYT(SData.imTwoPhoton);
                
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
% * * END NESTED FUNCTION fManageTwoPhoton
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fManageRegistration (nested in main)
% * *
% * * Image registration :  fix some artifacts
% * *
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
% * * END NESTED FUNCTION fManageRegistration
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fManageROI (nested in main)
% * *
% * * load/draw ROIs for analysis
% * *
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
            case 1,
                
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
                
            case 2, % new
                
                buttonName = questdlg('All the previous ROI data will be lost', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                SData.strROI        = {};
                % start save
                Par.DMT                 = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strROI',SData.strROI);                
                
            case 3,
                % save
%                 if Par.DMT.TwoPhotonNum < 1 ,
%                     warndlg('Please select Trial and load the Behavior image data first.');
%                     return
%                 end;
                
                % start save
                Par.DMT                 = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strROI',SData.strROI);                
                
            case 4,
                % Load
                [Par.DMT,SData.strROI]     = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strROI');

                            
            case 5,
                % Auto Detect of ROIs
                buttonName = questdlg('All the previous ROI data will be lost', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                
                dmROIAD                 = SetData(dmROIAD,SData.imTwoPhoton);
                dmROIAD                 = SegmentSpaceTime(dmROIAD);
                dmROIAD                 = PlayImgDFF(dmROIAD);
                [dmROIAD,SData.strROI]  = ExtractROI(dmROIAD);
                dmROIAD                 = DeleteData(dmROIAD);
                
                % update counters and save
                SData.strManager.roiCount = length(SData.strROI);
                fManageJaneliaExperiment(0,0,3); 
                
                % open viewer
                Par                     = TPA_TwoPhotonEditorXY(Par);
                
            case 6,
                % preview mode only
%                 tmpFigNum               = FigNum + 5;
%                 Par                     = TPA_PreviewROI(Par,SData.imTwoPhoton,SData.strROI,tmpFigNum);
%                 return
                
                
            case 11,
                % Auto Detect of ROI - Soft Options
                
                dmROIAD                 = SetData(dmROIAD,SData.imTwoPhoton);
                dmROIAD                 = SegmentSpaceTime(dmROIAD,1);
                dmROIAD                 = PlayImgDFF(dmROIAD);

            case 12,
                % Auto Detect of ROI - Soft Options
                
                dmROIAD                 = SetData(dmROIAD,SData.imTwoPhoton);
                dmROIAD                 = SegmentSpaceTime(dmROIAD,2);
                dmROIAD                 = PlayImgDFF(dmROIAD);
                
            case 13,
                % Auto Detect of ROI - Soft Options
                
                dmROIAD                 = SetData(dmROIAD,SData.imTwoPhoton);
                dmROIAD                 = SegmentSpaceTime(dmROIAD,3);
                dmROIAD                 = PlayImgDFF(dmROIAD);
                
            case 14,
                % Auto Detect of ROI - Soft Options
                
                dmROIAD                 = SetData(dmROIAD,SData.imTwoPhoton);
                dmROIAD                 = SegmentSpaceTime(dmROIAD,4);
                dmROIAD                 = PlayImgDFF(dmROIAD);
                
            case 15,
                % Replay with Original
                dmROIAD                 = PlayImgDFF(dmROIAD);
                
            case 16,
                % Replay with dF/F
                dmROIAD                 = PlayImgOverlay(dmROIAD);
                
                            
            case 17,
                % Auto Detect of ROI - Extract ROI info
                buttonName = questdlg('All the previous ROI data will be lost', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                
                [dmROIAD,SData.strROI]  = ExtractROI(dmROIAD);
                dmROIAD                 = DeleteData(dmROIAD);
                
                % update counters and save
                SData.strManager.roiCount = length(SData.strROI);
                fManageJaneliaExperiment(0,0,3); 
                
                % open viewer
                Par                     = TPA_TwoPhotonEditorXY(Par);

                
        end;
        
        %%%
        % Save ROI do not ask
        %%%
        %Par.DMT            = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'StrROI',SData.strROI);
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fManageROI
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =



% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fAnalysisBigROI (nested in main)
% * *
% * * big ROI analysis
% * *
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
% * * END NESTED FUNCTION fAnalysisROI
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fArtifacts (nested in main)
% * *
% * * Removes Artifacts from Average values of the channels
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fArtifactsROI(hObject, eventdata, selType)
        %
                    
        warndlg('Requires Red and Green channel. We Apologize. Please come later .');
        return
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Init
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1,
                Cmnd = 'SmoothSpatial';     % see DTP_ProcessingROI
            case 2,
                Cmnd = 'DeCorrelation';     % see DTP_ProcessingROI
            case 3,
                Cmnd = 'BleachingMotion';     % see DTP_ProcessingROI
            otherwise
                errordlg('Unsupported Case for fArtifacts Cmnd')
        end;
        %%%%%%%%%%%%%%%%%%%%%%
        % Fix channels mutual correlation or smoothing
        %%%%%%%%%%%%%%%%%%%%%%
        tmpFigNum               = Par.FigNum + 101;
        [Par,SData.strROI1,SData.strROI2]       = DTP_FixArtifactsROI(Par, Cmnd, SData.strROI1,SData.strROI2,tmpFigNum);
        
        % save
        %SData.strROI            = strROI;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fArtifacts
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fProcessROI (nested in main)
% * *
% * * Post processing of the ROI data after averaging
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fProcessROI(hObject, eventdata, selType)
        %
        %%%%%%%%%%%%%%%%%%%%%%
        % Init
        %%%%%%%%%%%%%%%%%%%%%%
        
        switch selType,
            case 1,
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.MEAN;        % see TPA_ProcessROI
            case 2,
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.MIN10;      % see TPA_ProcessROI
            case 3,
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.STD;    % see TPA_ProcessROI
            case 4,
                Par.Roi.ProcessType = Par.ROI_DELTAFOVERF_TYPES.MIN10CONT;    % see TPA_ProcessROI
            otherwise
                errordlg('Unsupported Case for Par.Roi.ProcessType')
        end;
        
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
% * * END NESTED FUNCTION fProcessROI
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =



% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fMultipleTrials (nested in main)
% * *
% * * Shows Behavior and TwoPhoton results 
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fMultipleTrials(hObject, eventdata, selType)
        
         
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            
           case 1, % Full experiment image registration
                Par                     = TPA_MultiTrialRegistration(Par);
                 
           case 2,
                % Align all the ROIs to first one that has been marked

                buttonName = questdlg('All the ROI data will be chnaged. Each ROI will have one exact position for all trials. Results are irreversible', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                Par                     = TPA_MultiTrialRoiAlignment(Par);
                
            case 13,
                % dF/F for all trials :  Fo = Aver
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MEAN;        % see TPA_ProcessROI
                Par                     = TPA_MultiTrialProcess(Par);
                
            case 14,
                % dF/F for all trials :  Fo = min 10%
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MIN10;      % see TPA_ProcessROI                
                Par                     = TPA_MultiTrialProcess(Par);

            case 15,
                % dF/F for all trials :  Fo = min 10% - continuous sections
                Par.Roi.ProcessType     = Par.ROI_DELTAFOVERF_TYPES.MIN10CONT;        % see TPA_ProcessROI
                Par                     = TPA_MultiTrialProcess(Par);
                
            
            case 4,
                % preliminary show
                tmpFigNum               = Par.FigNum + 201;
                [Par,dbROI,dbEvent]     = TPA_MultiTrialShow(Par,tmpFigNum);
                
               
            case 5,
                % open editor
                %tmpFigNum               = Par.FigNum + 251;
                Par                     = TPA_MultiTrialExplorer(Par);
                
            case 6,
                % open editor from Jaaba excel
                Par                     = TPA_MultiTrialExcelExplorer(Par);
                

           case 21,
                % Behavioral data compression
                if Par.DMB.VideoFrontFileNum < 1 && Par.DMB.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                buttonName = questdlg('All the Behaivioral Video data will be changed. It is not possible to recover it back.', 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
                
                trialInd                 = 1:Par.DMB.VideoSideFileNum;
                Par.DMB                  = Par.DMB.CompressBehaviorData(trialInd,'all');
                
                
            case 22, % Adding new event to all trials
                
                Par                     = TPA_MultiTrialEventAssignment(Par);
                    
                
             otherwise
                errordlg('Unsupported Option')
        end;
        
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fMultipleTrials
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fMultipleGroups (nested in main)
% * *
% * * Analysis of the combined Behavior and TwoPhoton results over many experriments
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fMultipleGroups(hObject, eventdata, selType)
        
         
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            
           case 1, % Use groups for analysis
                % open editor
                Par                     = TPA_MultiGroupExplorer(Par);
                 
%            case 2,
%                 % Align all the ROIs to first one that has been marked
%                 warndlg('')
%                 
%                 buttonName = questdlg('All the ROI data will be chnaged. Each ROI will have one exact position for all trials. Results are irreversible', 'Warning');
%                 if ~strcmp(buttonName,'Yes'), return; end;
%                 
%                 Par                     = TPA_MultiTrialRoiAlignment(Par);

            case 10, %  Init Group Manager
                
                % if nitialized before
                %if (gdm.MngrData.DbRoiRowCount > 0), return; end;
                if ~isempty(gdm.MngrData), return; end;
                
                gdm = Init(gdm,Par);
                gdm = LoadData(gdm);
                


            case 11, %  Active Rois per Event
                
                fMultipleGroups(0, 0, 10); % init if required
                
                % select Events to Show
                eventNames = gdm.MngrData.UniqueEventNames;
                [s,ok] = listdlg('PromptString','Select Event :','ListString',eventNames,'SelectionMode','multi');
                if ~ok, return; end;
                
                % do analysis
                eventNamesSelected = eventNames(s);
                gdm = ListMostActiveRoiPerEvent(gdm, eventNamesSelected);
                

            case 12, %  Early/Late/OnTime Rois per Event
                
                fMultipleGroups(0, 0, 10); % init if required
                                
                % select Events to Show
                eventNames = gdm.MngrData.UniqueEventNames;
                [s,ok] = listdlg('PromptString','Select Event :','ListString',eventNames,'SelectionMode','single');
                if ~ok, return; end;
                
                % do analysis
                eventNamesSelected = eventNames(s);
                gdm = ListEarlyLateOntimeRoiPerEvent(gdm, eventNamesSelected);
            
            case 13, %  Show delay map for all trials per specific event
                
                fMultipleGroups(0, 0, 10); % init if required
                                
                % select Events to Show
                eventNames = gdm.MngrData.UniqueEventNames;
                [s,ok] = listdlg('PromptString','Select Event :','ListString',eventNames,'SelectionMode','single');
                if ~ok, return; end;
                
                % do analysis
                eventNamesSelected = eventNames(s);
                gdm = ShowDelayMapPerEvent(gdm, eventNamesSelected);
                
                
             otherwise
                errordlg('Unsupported Option')
        end;
        
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fMultipleGroups
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fTwoPhotonDetection (nested in main)
% * *
% * * Two Photon based Detection & Classification of events on dF/F data
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fTwoPhotonDetection(hObject, eventdata, selType)
        %
        %%%%%%%%%%%%%%%%%%%%%%
        % Init
        %%%%%%%%%%%%%%%%%%%%%%        
        switch selType,
            case 1,
                % Init
                warndlg('TBD : future option .');
                
            case 2,
                % Do it
                Par = TPA_MultiTrialScattering(Par);
                

            case 5, 
            otherwise
                errordlg('Detection of Time events on dF/F data is coming soon  ')
        end;
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Do Averaging
        %%%%%%%%%%%%%%%%%%%%%%
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fTwoPhotonDetection
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fManagElectroPhys (nested in main)
% * *
% * * shows and explore behavior image data along with events
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManagElectroPhys(hObject, eventdata, selType)
        
        %%%%%%%%%%%%%%%%%%%%%%
        % What
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1, % select and load predefined trial
                
                % select GUI
                [Par.DME,isOK] = fSelectTrial(Par.DME);            %vis4d(uint8(SData.imTwoPhoton));
                if ~isOK,
                    DTP_ManageText([], 'Behavior : Trial Selection problems', 'E' ,0)   ;                  
                end
                
            case 11,
                % determine data params
                [Par.DME,isOK] = fSetDataParameters(Par.DME);
                if ~isOK,
                    DTP_ManageText([], 'Behavior : configuration parameters are not updated', 'W' ,0)   ;                  
                end
                
            case 2,
                % Behavior
                if Par.DME.VideoFrontFileNum < 1 && Par.DME.VideoSideFileNum < 1 ,
                    warndlg('Behavior is not selected or there are problems with directory. Please select Trial and load the data after that.');
                    return
                end;
                [Par.DME, SData.imBehaive]      = Par.DMB.LoadBehaviorData(Par.DME.Trial,'all');
                DTP_ManageText([], 'Behavior : Two file load Completed.', 'I' ,0)   ;
                [Par.DME, strEvent]             = Par.DMB.LoadAnalysisData(Par.DME.Trial,'strEvent');
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
                [Par] = TPA_ElectroPhysEditorYT(Par);
 
                
           case 5,
                % edit YT
                if ( Par.DME.VideoFrontFileNum < 1 && Par.DME.VideoSideFileNum < 1 ) || isempty(SData.imBehaive),
                    warndlg('Need to load behavior data first.');
                    return
                end;
                if length(SData.strEvent) < 1,
                    warndlg('Need to mark behavior data first.');
                    return
                end;
                    
                % start save
                Par.DME     = Par.DME.SaveAnalysisData(Par.DME.Trial,'strEvent',SData.strEvent);

                
           case 6,
                % Next Trial Full load
                
                % close previous
                hFigLU = findobj('Name','4D : Behavior Time Editor');    
                if ~isempty(hFigLU), close(hFigLU); end;
                hFigRU = findobj('Name','4D : Behavior Image Editor');    
                if ~isempty(hFigRU), close(hFigRU); end;
                
                % set new trial
                trialInd            = Par.DMB.Trial + 1;
                [Par.DME,isOK]      = Par.DMB.SetTrial(trialInd);
                
                % load Image, Events
                fManagElectroPhys(0, 0, 2);

                % Preview
                fManagElectroPhys(0, 0, 3);
                fManagElectroPhys(0, 0, 4);
                
                % Arrange
                fArrangeFigures();
  
                
                
            otherwise
                errordlg('Unsupported Type')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fManagElectroPhys
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fManageCalcium (nested in main)
% * *
% * * Configures and loads Calcium image and data
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fManageCalcium(hObject, eventdata, selType)
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Show
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            case 1, % init analysis
                
                                
                dirName            = Par.DMT.VideoDir;
                % init DMC
                Par.DataRange      = [0 60000];         % data range for display images
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
% * * END NESTED FUNCTION fManageCalcium
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fViewResults (nested in main)
% * *
% * * shows ROI analysis results
% * *
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
% * * END NESTED FUNCTION fViewResults
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fImportResults (nested in main)
% * *
% * * Import ROI analysis results
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fImportResults(hObject, eventdata, selType)
        % Import data primarly from JAABA
        
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Do it
        %%%%%%%%%%%%%%%%%%%%%%
        switch selType,
            
               
            
            case 1, % import Jabba - select one directory
                
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
                [fileName,dirName]              = uigetfile(SSave.ExpDir,'Jaaba Excel File');
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
                
%             case 11, % new SW version  - load movie_comb.avi from directories 
%                 % save
%                 fManageJaneliaExperiment(0,0,3);  
%                 
%                 %dirName             = uigetdir(SSave.ExpDir,'Jaaba Data Directory');
%                 dirName             = uigetdir(SSave.ExpDir,'Select any directory that belongs to Experiment (i.e. ..Analysis\m76\1-10-14)');
%                 if isnumeric(dirName), return; end;  % cancel button  
%                 
%                 % determine the path - assume certain directory structure
%                 Par                = TPA_ParInit;         
%   
%                 % init Behave and Two Photon
%                 SData               = struct('imBehaive',[],'imTwoPhoton',[],'strROI',[],'strEvent',[],'strManager',struct('roiCount',0,'eventCount',0)); % strManager will manage counters
%                 
%                 % import JAABA - event from scores and movies from movie_comb.avi
%                 SSave.ExpDir        = dirName;  % path this info for Jaaba
%                 fImportResults(0, 0, 11);
%                 
%                 
%                 Par.DMT             = Par.DMT.SelectAllData(dirName);
%                 Par.DMB             = Par.DMB.SelectAllData(dirName,'comb');
%                 % check
%                 Par.DMT             = Par.DMT.CheckData();
%                 Par.DMB             = Par.DMB.CheckData();
%                 
%                  
%                 expFileName         = fullfile(Par.DMB.EventDir,Par.ExpFileName);                
%                 SSave.ExpDir        = dirName;
%                 SSave.StrEventClass = []; % new classifier
%                 try 
%                     save(expFileName,'-struct', 'SSave');
%                     DTP_ManageText([], sprintf('Experiment : New configuration is done. '), 'I' ,0)   ;                    
%                  catch
%                     DTP_ManageText([], sprintf('Experiment : Can not save file %s',expFileName), 'E' ,0)   ;             
%                 end
%                 
                
                
            case 12, % import Jabba - select one directory
                
                
                dirName                             = Par.DMJ.JaabaDir ;
                
                % determine the path - assume certain directory structure
                Par.DMJ                             = Par.DMJ.SelectJaabaData(dirName);

                % Jaaba
                if Par.DMJ.JaabaDirNum < 1 ,
                    warndlg('Jaaba info is not found. You will need to mark behavioral event differently.');
                    return
                end;
                % where to put data back
                eventDirName                        = Par.DMB.EventDir;
                
                
%                 % init Behavior directories
                 %Par.DMB                             = Par.DMB.Clean();
                 %Par.DMB                            = Par.DMB.SelectAllData(dirName,'comb');
                 Par.DMB                            = Par.DMB.SelectBehaviorData(dirName,'comb');
                 Par.DMB                            = Par.DMB.RemoveEventData();
                 Par.DMB                            = Par.DMB.SelectAnalysisData(eventDirName) ; % event directory is different              
                 Par.DMB                            = Par.DMB.CheckData();


                for trialInd = 1:Par.DMJ.JaabaDirNum,
                    [Par.DMJ, jabData]              = Par.DMJ.LoadJaabaData(trialInd);
                    [Par.DMJ, jabEvent]             = Par.DMJ.ConvertToAnalysis(jabData);
                    
                    % assign and save
                    SData.strEvent                  = jabEvent;
                    %Par.DMB                         = Par.DMB.SetTrial(trialInd);
                    Par.DMB                         = Par.DMB.SaveAnalysisData(trialInd,'strEvent',SData.strEvent);
                end
                

                 
             otherwise
                errordlg('Unsupported Import Case')
        end;
        
        % Update figure components
        fUpdateGUI(); % Acitvate/deactivate some buttons according to the gui state
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fImportResults
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * *
% * * NESTED FUNCTION fExportResults (nested in main)
% * *
% * * exports ROI analysis results
% * *
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
% * * END NESTED FUNCTION fExportResults
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * NESTED FUNCTION fSetupGUI (nested in Main)
% * *
% * * Init all the buttons
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fSetupGUI() %#ok<*INUSD> eventdata is trialedly unused
        
        S.hFig = figure('units','pixels',...
            'position',[200 250 650 30],...
            'menubar','none',...
            'name', sprintf('Two Photon Analysis : %s',currVers),...
            'numbertitle','off',...
            'resize','off',...
            'closerequestfcn',{@fCloseGUI}); %{@fh_crfcn});
        
        S.hMenuFile(1)          = uimenu(S.hFig,                'Label','File...');
        S.hMenuSession(1)       = uimenu(S.hMenuFile(1),        'Label','Session ...'                                                        );
        S.hMenuSession(2)       = uimenu(S.hMenuSession(1),     'Label','Load Session',                             'Callback',{@fManageSession,1});
        S.hMenuSession(3)       = uimenu(S.hMenuSession(1),     'Label','Load Session From ...',                    'Callback',{@fManageSession,2});
        S.hMenuSession(4)       = uimenu(S.hMenuSession(1),     'Label','Save Session',                             'Callback',{@fManageSession,3});
        S.hMenuSession(5)       = uimenu(S.hMenuSession(1),     'Label','Save Session As...',                       'Callback',{@fManageSession,4});
        S.hMenuSession(6)       = uimenu(S.hMenuSession(1),     'Label','Clear Session',                            'Callback',{@fManageSession,5});
        
        S.hMenuExpBehaive(1)    = uimenu(S.hMenuFile(1),        'Label','Experiment Behavior...', 'separator','on'                                              );
        S.hMenuExpBehaive(2)    = uimenu(S.hMenuExpBehaive(1),  'Label','Setup New ...',                            'Callback',{@fManageJaneliaExperiment,1});
        S.hMenuExpBehaive(3)    = uimenu(S.hMenuExpBehaive(1),  'Label','Load from Data Management File...',        'Callback',{@fManageJaneliaExperiment,2});
        S.hMenuExpBehaive(4)    = uimenu(S.hMenuExpBehaive(1),  'Label','Refresh Data Management File...',          'Callback',{@fManageJaneliaExperiment,4});
        S.hMenuExpBehaive(5)    = uimenu(S.hMenuExpBehaive(1),  'Label','Save Data Management File ...',            'Callback',{@fManageJaneliaExperiment,7});
        S.hMenuExpBehaive(6)    = uimenu(S.hMenuExpBehaive(1),  'Label','Preview Data Management File...',          'Callback',{@fManageJaneliaExperiment,6});
        S.hMenuExpBehaive(7)    = uimenu(S.hMenuExpBehaive(1),  'Label','Select Directory (Old Style)...',          'Callback',{@fManageJaneliaExperiment,8}, 'separator','on');
        S.hMenuExpBehaive(8)    = uimenu(S.hMenuExpBehaive(1),  'Label','Check Data Structure ...',                 'Callback',{@fManageJaneliaExperiment,5});
        
        S.hMenuExpElectro(1)    = uimenu(S.hMenuFile(1),        'Label','Experiment Electro Phys...','separator','on'                                            );
        S.hMenuExpElectro(2)    = uimenu(S.hMenuExpElectro(1),  'Label','Select Directory...',                      'Callback',{@fManageElectroPhysExperiment,2});
        S.hMenuExpElectro(3)    = uimenu(S.hMenuExpElectro(1),  'Label','New/Clear ...',                            'Callback',{@fManageElectroPhysExperiment,1});
        S.hMenuExpElectro(4)    = uimenu(S.hMenuExpElectro(1),  'Label','Save ...',                                 'Callback',{@fManageElectroPhysExperiment,3});
        S.hMenuExpElectro(5)    = uimenu(S.hMenuExpElectro(1),  'Label','Check Data Sync ...', 'separator','on',    'Callback',{@fManageElectroPhysExperiment,4});
        
        S.hMenuFile(3)          = uimenu(S.hMenuFile(1),        'Label','Close Windows',        'separator','on',   'Callback',@fCloseFigures);
        S.hMenuFile(4)          = uimenu(S.hMenuFile(1),        'Label','Arrange Windows',                          'Callback',@fArrangeFigures);
        
        S.hMenuImport(1)        = uimenu(S.hMenuFile(1),        'Label','Import ...', 'separator','on'                                              );
        S.hMenuImport(2)        = uimenu(S.hMenuImport(1),      'Label','Jaaba Score Data ...',                     'Callback',{@fImportResults,1});
        S.hMenuImport(3)        = uimenu(S.hMenuImport(1),      'Label','Jaaba Excel Data Old...',                  'Callback',{@fImportResults,2});
        S.hMenuImport(4)        = uimenu(S.hMenuImport(1),      'Label','Jaaba Excel Data Semi Auto ...',           'Callback',{@fImportResults,3});
        S.hMenuExport(1)        = uimenu(S.hMenuFile(1),        'Label','Export...');
        S.hMenuExport(2)        = uimenu(S.hMenuExport(1),      'Label','ImageJ ...',                               'Callback','warndlg(''Countdown is initiated'')');
        S.hMenuExport(3)        = uimenu(S.hMenuExport(1),      'Label','Matlab ...',                               'Callback','warndlg(''Is yet to come'')');
        S.hMenuExport(4)        = uimenu(S.hMenuExport(1),      'Label','Excel ...',                                'Callback',{@fExportResults,3});
        S.hMenuExport(5)        = uimenu(S.hMenuExport(1),      'Label','Igor ...',                                 'Callback',{@fExportResults,4});
        S.hMenuExport(6)        = uimenu(S.hMenuExport(1),      'Label','Jabba ...',                                'Callback','warndlg(''Is yet to come'')');
        S.hMenuExport(7)        = uimenu(S.hMenuExport(1),      'Label','TwoPhoton Image Data to TIF file ...',     'Callback',{@fExportResults,5});
        S.hMenuFile(5)          = uimenu(S.hMenuFile(1),        'Label','Save All & Exit',   'separator','on',      'Callback',@fCloseGUI);
        
        S.hMenuBehaive(1)       = uimenu(S.hFig,                'Label','Behavior...');
        S.hMenuBehaive(2)       = uimenu(S.hMenuBehaive(1),     'Label','Set Trial Num...',                         'Callback',{@fManageBehavior,1});
        S.hMenuBehaive(3)       = uimenu(S.hMenuBehaive(1),     'Label','Config Data...',                           'Callback',{@fManageBehavior,11});
        S.hMenuBehaive(4)       = uimenu(S.hMenuBehaive(1),     'Label','Load Trial Data...',                       'Callback',{@fManageBehavior,2});
        S.hMenuBehaive(5)       = uimenu(S.hMenuBehaive(1),     'Label','View XY...',                               'Callback',{@fManageBehavior,3});
        S.hMenuBehaive(6)       = uimenu(S.hMenuBehaive(1),     'Label','View YT...',                               'Callback',{@fManageBehavior,4});
        S.hMenuBehaive(7)       = uimenu(S.hMenuBehaive(1),     'Label','Next Trial Load and Show...',              'Callback',{@fManageBehavior,6});
        S.hMenuBehaive(8)       = uimenu(S.hMenuBehaive(1),     'Label','Compress Video Data...',                   'Callback',{@fManageBehavior,21});
        S.hMenuBehaive(9)       = uimenu(S.hMenuBehaive(1),     'Label','Check Drop Frames in Video Data...',       'Callback',{@fManageBehavior,22});
       
        S.hMenuEventsBD(1)      = uimenu(S.hMenuBehaive(1),     'Label','Events...');
        S.hMenuEventsBD(2)      = uimenu(S.hMenuEventsBD(1),    'Label','Load from File...',                        'Callback',{@fManageEvent,1});
        S.hMenuEventsBD(3)      = uimenu(S.hMenuEventsBD(1),    'Label','New/Clean  ...',                           'Callback',{@fManageEvent,2});
        S.hMenuEventsBD(4)      = uimenu(S.hMenuEventsBD(1),    'Label','Save ...',                                 'Callback',{@fManageEvent,3});
        S.hMenuEventsBD(5)      = uimenu(S.hMenuEventsBD(1),    'Label','Load...',                                  'Callback',{@fManageEvent,4});
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

        S.hMenuTrajec(1)        = uimenu(S.hMenuBehaive(1),      'Label','Trajectory Analysis...',  'separator','on'   );
        S.hMenuTrajec(2)        = uimenu(S.hMenuTrajec(1),       'Label','Params ...',                               'Callback',{@fManageEvent,20});
        S.hMenuTrajec(3)        = uimenu(S.hMenuTrajec(1),       'Label','Create ...',                               'Callback',{@fManageEvent,21});
        S.hMenuTrajec(4)        = uimenu(S.hMenuTrajec(1),       'Label','Show Filtered ...',                        'Callback',{@fManageEvent,22});
        S.hMenuTrajec(5)        = uimenu(S.hMenuTrajec(1),       'Label','Group  ...',                               'Callback',{@fManageEvent,23});
        S.hMenuTrajec(6)        = uimenu(S.hMenuTrajec(1),       'Label','Save  ...',                                'Callback',{@fManageEvent,24});
        
        
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
        %S.hMenuRoi(6)           = uimenu(S.hMenuRoi(1),         'Label','Auto Detect...',                           'Callback',{@fManageROI,5});
        
        S.hMenuAverage(1)       = uimenu(S.hMenuImage(1),       'Label','Analysis...');
        S.hMenuAverage(2)       = uimenu(S.hMenuAverage(1),     'Label','Aver Fluorescence Point ROIs ...',         'Callback',{@fAnalysisROI,1});
        S.hMenuAverage(3)       = uimenu(S.hMenuAverage(1),     'Label','Aver Fluorescence Line(Max) ROIs ...',     'Callback',{@fAnalysisROI,2});
        S.hMenuAverage(4)       = uimenu(S.hMenuAverage(1),     'Label','Aver Fluorescence Line(Orth) ROIs ...',    'Callback',{@fAnalysisROI,3});
        S.hMenuAverage(5)       = uimenu(S.hMenuAverage(1),     'Label','Aver Separately by ROI Type ...',          'Callback',{@fAnalysisROI,4});        
        S.hMenuProcess(2)       = uimenu(S.hMenuAverage(1),     'Label','Remove Artifacts : Smooth Ch 1 ...',       'Callback',{@fArtifactsROI,1}, 'separator','on');
        S.hMenuProcess(3)       = uimenu(S.hMenuAverage(1),     'Label','Remove Artifacts : Decorrelate ...',       'Callback',{@fArtifactsROI,2});
        S.hMenuProcess(4)       = uimenu(S.hMenuAverage(1),     'Label','Remove Artifacts : Bleach & Motion ...',   'Callback',{@fArtifactsROI,3});        
        S.hMenuProcess(5)       = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = Aver Fluorescence ...',       'Callback',{@fProcessROI,1},    'separator','on');
        S.hMenuProcess(6)       = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = 10% Min ...',                 'Callback',{@fProcessROI,2});
        S.hMenuProcess(7)       = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = STD ...',                     'Callback',{@fProcessROI,3});
        S.hMenuProcess(8)       = uimenu(S.hMenuAverage(1),     'Label','dF/F : Fbl = 10% Min Cont ...',            'Callback',{@fProcessROI,4});
        
        S.hMenuEventTP(1)       = uimenu(S.hMenuImage(1),       'Label','ROI Event Detector ...', 'separator','on' );
        S.hMenuEventTP(2)       = uimenu(S.hMenuEventTP(1),     'Label','Event Auto Detect (dff-1,emph-4) ',        'Callback',{@fManageROI,11},    'separator','on');
        S.hMenuEventTP(3)       = uimenu(S.hMenuEventTP(1),     'Label','Event Auto Detect (dff-1,emph-5) ',        'Callback',{@fManageROI,12});
        S.hMenuEventTP(4)       = uimenu(S.hMenuEventTP(1),     'Label','Event Auto Detect (dff-1,emph-6) ',        'Callback',{@fManageROI,13});
        S.hMenuEventTP(5)       = uimenu(S.hMenuEventTP(1),     'Label','Event Auto Detect (dff-4,emph-6) ',        'Callback',{@fManageROI,14});
        S.hMenuEventTP(6)       = uimenu(S.hMenuEventTP(1),     'Label','Play Orig + Results ... ',                 'Callback',{@fManageROI,15});
        S.hMenuEventTP(7)       = uimenu(S.hMenuEventTP(1),     'Label','Play dFF + Results ... ',                  'Callback',{@fManageROI,16});
        S.hMenuEventTP(8)       = uimenu(S.hMenuEventTP(1),     'Label','Export to ROI ... ',                       'Callback',{@fManageROI,17});
        
        S.hMenuMulti(1)          = uimenu(S.hFig,               'Label','Multi Trial...');
        S.hMenuMulti(2)          = uimenu(S.hMenuMulti(1),      'Label','Batch TwoPhoton Registration for all Trials ... ', 'Callback',{@fMultipleTrials,1});
        S.hMenuMulti(3)          = uimenu(S.hMenuMulti(1),      'Label','Batch ROI Assignment ... ',                        'Callback',{@fMultipleTrials,2});
        S.hMenuMultiDFF(1)       = uimenu(S.hMenuMulti(1),      'Label','Batch dF/ ... '                        );
        S.hMenuMultiDFF(2)       = uimenu(S.hMenuMultiDFF(1),   'Label','Batch dF/F all Trials : Fbl = Aver ... ',          'Callback',{@fMultipleTrials,13});
        S.hMenuMultiDFF(3)       = uimenu(S.hMenuMultiDFF(1),   'Label','Batch dF/F all Trials : Fbl = 10% Min... ',        'Callback',{@fMultipleTrials,14});
        S.hMenuMultiDFF(4)       = uimenu(S.hMenuMultiDFF(1),   'Label','Batch dF/F all Trials : Fbl = 10% Min Cont ... ',  'Callback',{@fMultipleTrials,15});
        S.hMenuMulti(4)          = uimenu(S.hMenuMulti(1),      'Label','Preview all Trials .... ',                         'Callback',{@fMultipleTrials,4});
        S.hMenuMulti(5)          = uimenu(S.hMenuMulti(1),      'Label','Multi Trial Explorer ...',                         'Callback',{@fMultipleTrials,5});
        S.hMenuMulti(6)          = uimenu(S.hMenuMulti(1),      'Label','Multi Trial Explorer from JAABA Excel ...',        'Callback',{@fMultipleTrials,6});
        S.hMenuMulti(7)         = uimenu(S.hMenuMulti(1),       'Label','Active Roi per Event Analysis...',                 'Callback',{@fMultipleGroups,11});
        S.hMenuMulti(8)         = uimenu(S.hMenuMulti(1),       'Label','Early/Late Roi per Event Analysis...',             'Callback',{@fMultipleGroups,12});
        S.hMenuMulti(9)          = uimenu(S.hMenuMulti(1),      'Label','dF/F Spike Delay Map for all ROIs     ...',        'Callback',{@fMultipleGroups,13});
%         S.hMenuMulti(10)         = uimenu(S.hMenuMulti(1),      'Label','Export Data...',                           'Callback',{@fMultipleTrials,7});
        S.hMenuDetect(1)         = uimenu(S.hMenuMulti(1),      'Label','Batch dF/F Event Detection...');
        S.hMenuDetect(2)         = uimenu(S.hMenuDetect(1),     'Label','Configure ...',                                    'Callback',{@fTwoPhotonDetection,1});
        S.hMenuDetect(2)         = uimenu(S.hMenuDetect(1),     'Label','Detect Events on ROI data ...',                    'Callback',{@fTwoPhotonDetection,2});
        S.hMenuMulti(11)         = uimenu(S.hMenuMulti(1),      'Label','Batch Behavior Compress. ...', 'separator','on',   'Callback',{@fMultipleTrials,21});
        S.hMenuMulti(12)         = uimenu(S.hMenuMulti(1),      'Label','Batch Event Assignment. ...',                      'Callback',{@fMultipleTrials,22});
         
        S.hMenuGroups(1)        = uimenu(S.hFig,                  'Label','Muti Experiment...');
        S.hMenuGroups(2)        = uimenu(S.hMenuGroups(1),       'Label','Multi Group Explorer. .....',          'Callback',{@fMultipleGroups,1});
        %S.hMenuGroups(3)        = uimenu(S.hMenuGroups(1),       'Label','Correlation Analysis...',                   'Callback',{@fMultipleGroups,2});
       
      
        
        S.hMenuElectroPhys(1)   = uimenu(S.hFig,                'Label','ElectroPhys...');
        S.hMenuElectroPhys(2)   = uimenu(S.hMenuElectroPhys(1), 'Label','Set Trial Num...',                         'Callback',{@fManagElectroPhys,1});
        S.hMenuElectroPhys(3)   = uimenu(S.hMenuElectroPhys(1), 'Label','Config Data...',                           'Callback',{@fManagElectroPhys,11});
        S.hMenuElectroPhys(4)   = uimenu(S.hMenuElectroPhys(1), 'Label','Load Trial Data...',                       'Callback',{@fManagElectroPhys,2});
        S.hMenuElectroPhys(5)   = uimenu(S.hMenuElectroPhys(1), 'Label','View XY...',                               'Callback',{@fManagElectroPhys,3},'Enable','off');
        S.hMenuElectroPhys(6)   = uimenu(S.hMenuElectroPhys(1), 'Label','View YT...',                               'Callback',{@fManagElectroPhys,4});
        S.hMenuElectroPhys(7)   = uimenu(S.hMenuElectroPhys(1), 'Label','Next Trial Load and Show...',              'Callback',{@fManagElectroPhys,6});
       
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
        set(S.hMenuExpElectro,'Enable','off');
        
        % sync all components
        SGui.hMain = S.hFig;
        setappdata(SGui.hMain, 'fSyncAll', @fSyncAll);

        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fSetupGUI
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * NESTED FUNCTION fUpdateGUI (nested in Main)
% * *
% * * Defines state of all buttons
% * *
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
% * * END NESTED FUNCTION fUpdateGUI
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * NESTED FUNCTION fSyncAll (nested in Main)
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
% * * END NESTED FUNCTION fSyncAll
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * NESTED FUNCTION fArrangeFigures (nested in imagine)
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
% * * END NESTED FUNCTION fArrangeFigures
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * NESTED FUNCTION fCloseFigures (nested in imagine)
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
        
        
        
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fCloseFigures
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * NESTED FUNCTION fCloseGUI (nested in imagine)
% * *
% * * Figure callback
% * *
% * * Closes the figure and saves the settings
% * *
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCloseGUI(hObject, eventdata) %#ok<*INUSD> eventdata is trialedly unused
        % save user params
        fManageSession(0,0,3);        
        fManageJaneliaExperiment(0,0,3);
        
        try
            fCloseFigures(0,0);            
            delete(gcf)
        catch ex
            errordlg(ex.getReport('basic'),'Close Other Window Error','modal');
        end
        %delete(hObject); % Bye-bye figure
    end
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
% * * END NESTED FUNCTION fCloseGUI
% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

end
% =========================================================================
% *** END FUNCTION fSettings (and its nested functions)
% =========================================================================

