classdef TPA_ManageExperiment
    % TPA_ManageExperiment - deal with save and load of the user data and config
    
    % Ver    Date     Who  Description
    % ------ -------- ---- -------
    % 28.01  28/12/17 UD   Prarie 2 channel
    % 12.00  27/03/16 UD   Save System and Algorithm
    % 11.00  25/10/15 UD   Created
    

    %%%%%%%%%%%%%%%%%%%%%%
    % Main Constants and Defines
    %%%%%%%%%%%%%%%%%%%%%%

    properties (Constant)


    end % constant    
    properties
        
        ExpType                 = 1;
        ExpDir                   % analysis directory
        ExpFileName             = 'TPC_Experiment.mat'; 
        %DMB                     % behavioral
        %DMT                     % two photn
        %UserSessionFileName     = '.\Setup\TPA_Session.mat';
        
    end
    methods
        
        % ==========================================
        function obj = TPA_ManageExperiment()
            % TPA_ManageExperiment - constructor
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
            %if nargin < 1, Par = TPA_ParInit; end;
            
            % connect
            global Par;
            %obj.UserSessionFileName = fullfile(Par.SetupDir,Par.SetupFileName);
            obj.ExpDir              = pwd;
            obj.ExpFileName         = Par.ExpFileName;
            obj.ExpType             = Par.ExpType;
            
        end
        
        % ==========================================
        function obj = SelectExperimentType(obj)
            % SelectExperimentType - which experiment to use - user selection
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
        
            % connect
            global Par;
            
            expNames    = fieldnames(Par.EXPERIMENT_TYPES);
            [s,ok]      = listdlg('PromptString','Select System Type:','ListString',expNames,'SelectionMode','single','ListSize',[160 200]);
            if ~ok, return; end
            expValue    = getfield(Par.EXPERIMENT_TYPES,expNames{s});
            Par.ExpType = expValue;
                
            DTP_ManageText([], sprintf('Experiment : Selected %s ',expNames{s}), 'I' ,0) ;
            
            obj         = ConfigureExperiment(obj);
        end
        
        % ==========================================
        function obj = ConfigureExperiment(obj)
            % ConfigureExperiment - which structures will be used
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
        
            % connect
            global Par;
            
           % Init params
            switch Par.ExpType,
                case Par.EXPERIMENT_TYPES.TWOPHOTON_JANELIA
                    Par.DMT = TPA_DataManagerTwoPhoton();
                    Par.DMB = TPA_DataManagerBehavior();
                 case Par.EXPERIMENT_TYPES.TWOPHOTON_PRARIE
                    Par.DMT = TPA_DataManagerPrarie();
                    Par.DMB = TPA_DataManagerBehavior();
                 case Par.EXPERIMENT_TYPES.TWOCHANNEL_PRARIE
                    Par.DMT = TPA_DataManagerTwoChannel();
                    Par.DMB = TPA_DataManagerBehavior();
                case Par.EXPERIMENT_TYPES.TWOPHOTON_ELECTROPHYS,
                    Par.DMT = TPA_DataManagerPrarie();
                    Par.DMB = TPA_DataManagerElectroPhys();
                case Par.EXPERIMENT_TYPES.TWOPHOTON_SHEET
                    Par.DMT = TPA_DataManagerTwoPhotonSheet();
                    Par.DMB = TPA_DataManagerBehavior();
                otherwise
                    error('Bad system type %d',Par.Config.SysType)
            end
            
                
            DTP_ManageText([], sprintf('Experiment : Configured %d ',Par.ExpType), 'I' ,0)   ;
        end
        
        % ==========================================
        function obj = InitFromDirectory(obj, dirName)
            % InitFromDirectory - select directory to init the experiment.
            % Check if csv file is there - else load all
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
            if nargin < 2, dirName = obj.ExpDir; end;
        
            % connect
            global Par;
            
            % check if the data file exists
            csvFile             = fullfile(dirName,Par.CsvDataDirFileName);
            buttonName          = 'No';
            if exist(csvFile,'file'),
                % set up fiile
                buttonName = questdlg('Experiment management file is found : would you like to load the experiment file from this file?', 'Warning');
            end
            
            if strcmp(buttonName,'Yes'), 
                Par.DMF             = Clear(Par.DMF);
                Par.DMF             = LoadTableFile(Par.DMF,csvFile);
                % copy DMT and DMB from Loaded to actual structures 
                Par                 = ParInit(Par.DMF,Par);     
            elseif  strcmp(buttonName,'No'), 
                % select data 
                Par.DMT             = Par.DMT.SelectAllData(dirName);
                Par.DMB             = Par.DMB.SelectAllData(dirName);
            else % cancel
                return
            end;
                
            % check
                
            obj.ExpDir          = dirName;
            DTP_ManageText([], sprintf('Experiment : Directory Selected : %s ',obj.ExpDir), 'I' ,0)   ;
        end
        
        % ==========================================
        function obj = InitFromManagementFile(obj, dirName)
            % InitFromManagementFile - select directory and data management file.
            % Check if csv file is there - else load all
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
            if nargin < 2, dirName = obj.ExpDir; end;
        
            % connect
            global Par;
            
            % check if the data file exists
            
            [fileName,dirName] = uigetfile({'*.csv','Data Management File'},'MultiSelect','off','Select Data Management File',dirName);
            if isnumeric(fileName), return; end;
            csvFile             = fullfile(dirName,Par.CsvDataDirFileName);
            
            
            Par.DMF             = Clear(Par.DMF);
            Par.DMF             = LoadTableFile(Par.DMF,csvFile);
            % copy DMT and DMB from Loaded to actual structures 
            Par                 = ParInit(Par.DMF,Par);     
                
            % check
                
            obj.ExpDir          = dirName;
            DTP_ManageText([], sprintf('Experiment : Directory Selected : %s ',obj.ExpDir), 'I' ,0)   ;
        end
        
        
        % ==========================================
        function obj = SpecifyDirectories(obj, dirName)
            % SpecifyDirectories - select directory to init the experiment.
            % Asks and loads one by one
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
            if nargin < 2, dirName = obj.ExpDir; end;
        
            % connect
            global Par;
            
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
                
            % create new CSV file
            %Par.DMF           = Par.DMF.Init(Par);
            Par.DMF           = Par.DMF.SaveTableFile(Par);
            
                
            obj.ExpDir          = dirName;
            DTP_ManageText([], sprintf('Experiment : Directory Selected : %s ',obj.ExpDir), 'I' ,0)   ;
        end
        
        % ==========================================
        function obj = LoadLastExperiment(obj,expDir)
            % LoadLastExperiment - load the latest experiment file
            % Input:
            %    userFile - file to load
            %    Par - control structure (global)
            % Output:
            %    obj -  default values
            if nargin < 2, expDir = obj.ExpDir; end;
            
            global Par;
            
            expFile = fullfile(obj.ExpDir,obj.ExpFileName);
            
            if exist(expFile, 'file'),
                try
                    SSave                        = load(expFile);
                    % check version
                    if isfield(SSave,'Version'),
                    if ~strcmp(SSave.Version,Par.Version),
                        DTP_ManageText([], sprintf('Session : Session Version File may be incompatible with current SW version. '), 'W');
                    end
                    end

                    % Save the settings
                   
                    obj.ExpDir                  = SSave.ExpDir;
                    obj.ExpType                 = SSave.ExpType;
                    Par.ExpType                 = SSave.ExpType;
                    
                    %obj.UserSessionFileName         = expFile;
                    
                catch ex
                    errordlg(ex.getReport('basic'),'File Type Error','modal'); return;
                end
                DTP_ManageText([], sprintf('Experiment : Latest experiment configuration is loaded. '), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('Experiment : Can nos find %s file. ',expFile), 'E')   ;
            end
            
            
        end
        
        % ==========================================
        function obj = SaveLastExperiment(obj,expFile)
            % SaveLastSession - save the latest session
            % Input:
            %    obj - structure with defines
            %    Par - control structure (global)
            % Output:
            %    obj -  default values
            if nargin < 2, expFile = fullfile(obj.ExpDir,obj.ExpFileName); end;
            
            global Par;
                        
            expDir = pwd;
            if isempty(Par.DMT), 
                DTP_ManageText([], sprintf('Session : Nothing to save - analysis dir is not specified. '), 'W' ,0)   ;
            end
            if ~exist(Par.DMT.RoiDir,'dir'), 
                DTP_ManageText([], sprintf('Session : bad analysis directory. '), 'W' ,0)   ;
            else
                expDir = Par.DMT.RoiDir;
            end;

            % save to object
            obj.ExpDir              = expDir;
            obj.ExpType             = Par.ExpType;

            % Save the settings
            SSave.ExpDir             = expDir;
            SSave.ExpType            = Par.ExpType;
            SSave.Version            = Par.Version;
            
            try %#ok<TRYNC>
                save(expFile,'-struct', 'SSave');
            catch ex
                errordlg(ex.getReport('basic'),'File Type Error','modal');
            end
            DTP_ManageText([], sprintf('Experiment : Latest experiment configuration is saved. '), 'I' ,0)   ;
            
            
        end
        
        % ==========================================
        function obj = ConfigureJaneliaExperiment(obj)
            % ConfigureJaneliaExperiment - which structures belong to Janelia
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
        
            % connect
            global Par;
            
            % check
            assert(Par.ExpType == Par.EXPERIMENT_TYPES.TWOPHOTON_JANELIA);
            
            
                
            DTP_ManageText([], sprintf('Experiment : Janelia is Configured'), 'I' ,0)   ;
        end
        
        
        
    end % methods
end % classdef
