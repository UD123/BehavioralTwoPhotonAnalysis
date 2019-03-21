classdef TPA_ManageSession
    % TPA_ManageSession - deal with save and load the latest session
    
    % Ver    Date     Who  Description
    % ------ -------- ---- -------
    % 02.00  06/09/16 UD   Fixing bug
    % 01.00  23/08/16 UD   Created
    

    %%%%%%%%%%%%%%%%%%%%%%
    % Main Constants and Defines
    %%%%%%%%%%%%%%%%%%%%%%

    properties (Constant)


    end % constant    

    %%%%%%%%%%%%%%%%%%%%%%
    % Data save/load to dsik
    %%%%%%%%%%%%%%%%%%%%%%
    
    properties
        
        ExpDir                   % analysis directory
        ExpType                  % type of the experiment
        %ExpFileName              % TPC_Experiment
        %DMB                     % behavioral
        %DMT                     % two photn
        UserSessionFileName     = '.\Setup\TPA_Session.mat';
        
    end
    methods
        
        % ==========================================
        function obj = TPA_ManageSession()
            % TPA_ManageSession - constructor
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
            %if nargin < 1, Par = TPA_ParInit; end;
            
            % connect
            global Par;
            obj.UserSessionFileName = fullfile(Par.SetupDir,Par.SetupFileName);
            obj.ExpDir              = pwd;
            %obj.ExpFileName         = Par.ExpFileName;
            obj.ExpType             = Par.ExpType;
            
        end
        
        % ==========================================
        function [obj,dirName] = SelectDirectory(obj)
            % SelectDirectory - load the latest session from specified directory
            % Input:
            %    obj - default values
            % Output:
            %    dirName -  select
            
            obj                 = LoadLastSession(obj);
            dirName             = uigetdir(obj.ExpDir,'Select a directory that belongs to Experiment');
            if isnumeric(dirName), return; end;  % cancel button
            obj.ExpDir          = dirName;
            obj                 = SaveLastSession(obj);
            DTP_ManageText([], sprintf('Session : Directory selected : %s',dirName), 'I' ,0)   ;
            
            
        end
        
        
        % ==========================================
        function obj = LoadLastSession(obj,userFile)
            % LoadLastSession - load the latest session
            % Input:
            %    userFile - file to load
            %    Par - control structure (global)
            % Output:
            %    obj -  default values
            if nargin < 2, userFile = obj.UserSessionFileName; end;
            
            global Par
            
            if exist(userFile, 'file'),
                try
                    SSave                        = load(userFile);
                    % check version
                    if ~strcmp(SSave.Version,Par.Version),
                        DTP_ManageText([], sprintf('Session : Session Version File may be incompatible with current SW version. '), 'W');
                    end

                    % Save the settings
                   
                    obj.ExpDir                  = SSave.ExpDir;
                    obj.ExpType                 = SSave.ExpType;
                    Par.ExpType                 = SSave.ExpType;
                    
                    obj.UserSessionFileName         = userFile;
                    
                catch ex
                    errordlg(ex.getReport('basic'),'File Type Error','modal'); return;
                end
                DTP_ManageText([], sprintf('Session : Latest session configuration is loaded. '), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('Session : Can not find %s file. ',userFile), 'E')   ;
            end
            
            
        end
        
        % ==========================================
        function obj = SaveLastSession(obj,userFile)
            % SaveLastSession - save the latest session
            % Input:
            %    obj - structure with defines
            %    Par - control structure (global)
            % Output:
            %    obj -  default values
            if nargin < 2, userFile = obj.UserSessionFileName; end;
            
            global Par;
                        
            expDir = obj.ExpDir;
            if isempty(Par.DMT), 
                DTP_ManageText([], sprintf('Session : Nothing to save - analysis dir is not specified. '), 'W' ,0)   ;
            end
            if ~exist(Par.DMT.RoiDir,'dir'), 
                DTP_ManageText([], sprintf('Session : analysis directory is not defined. '), 'W' ,0)   ;
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
                save(userFile,'-struct', 'SSave');
            catch ex
                errordlg(ex.getReport('basic'),'File Type Error','modal');
            end
            DTP_ManageText([], sprintf('Session : Latest session configuration is saved. '), 'I' ,0)   ;
            
            
        end
        
        % ==========================================
        function obj = LoadUserSession(obj)
            % LoadUserSession - load by user input
            % Input:
            %    obj - structure with defines
            % Output:
            %    obj -  default values
            
            global Par;
            
            [csFilenames, sPath] = uigetfile(...
                {   '*.mat', 'mat Files'; '*.*', 'All Files'}, ...
                'OpenLocation'  , Par.SetupDir, ...
                'Multiselect'   , 'off');
            
            if isnumeric(sPath), return, end;   % Dialog aborted

            % if single file selected
            if iscell(csFilenames), csFilenames = csFilenames{1}; end;
            userSessionFileName     = fullfile(sPath,csFilenames);
            obj                     = LoadLastSession(obj,userSessionFileName);
            
        end
        
        % ==========================================
        function obj = SaveUserSession(obj)
            % SaveUserSession - save by user input
            % Input:
            %    obj - structure with defines
            % Output:
            %    obj -  default values
            
            global Par;
            
            [filename, pathname] = uiputfile('*.mat', 'Save Session file',Par.SetupFileName);
            if isequal(filename,0) || isequal(pathname,0),  return;    end

            userSessionFileName = fullfile(pathname, filename);
            
            obj                 = SaveLastSession(obj,userSessionFileName);
            
        end
        
        
    end % methods
end % classdef
