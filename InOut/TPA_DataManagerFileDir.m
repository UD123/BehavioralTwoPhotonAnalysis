classdef TPA_DataManagerFileDir
    % TPA_DataManagerFileDir - manages data directory
    % Inputs:
    %       BDA_XXX.mat, TPA_YYY.mat - data base
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 19.09 14.07.14 UD     Fixing
    % 19.06 21.09.14 UD     Compare with disk data
    % 18.10 09.07.14 UD     Created
    %-----------------------------
    
    
    properties
        
        % directory file manager
        FileName            = '';       % xlsx data file name
        ExpDir              = '';       % xlsx directory  (Analysis)
        
        
        % copy of the containers with file info
        DMB                 = [];   % behaivior   data managers
        DMT                 = [];   % two photon  data managers
        
        
    end % properties
    properties (SetAccess = private)
        %TimeConvertFact     = 1;           % time conversion >= 1 between behav - fast and twophoton - slow
        %TimeEventAligned    = false;        % if the events has been time aligned
    end
    
    methods
        
        % ==========================================
        function obj = TPA_DataManagerFileDir()
            % TPA_DataManagerFileDir - constructor
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
            %obj.DMB                     = Par.DMB;
            %obj.DMT                     = Par.DMT;
            obj.FileName                = Par.ExpDataDirFileName;
            obj.ExpDir                  = Par.DMT.RoiDir;
            
            obj.DMT                     = TPA_DataManagerTwoPhoton();
            obj.DMB                     = TPA_DataManagerBehavior(); Par.DMB.DecimationFactor = [2 2 1 1];
            
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = SaveExcelFile(obj,Par)
            % SaveExcelFile - writes directory structures to Excel
            % Input:
            %    Par  - DMT, DMB initialized
            % Output:
            %    obj  - File in Analysis directory
            
            obj.DMB                     = Par.DMB;
            obj.DMT                     = Par.DMT;
            obj.FileName                = Par.ExpDataDirFileName;
            obj.ExpDir                  = Par.DMT.RoiDir;
            
            if isempty(obj.ExpDir),
                DTP_ManageText([], sprintf('DataExcel : Analysis directory is not specified.'),  'E' ,0);
                return
            end
                        
            % create save file name
            saveFileName    = fullfile(obj.ExpDir,obj.FileName);
            if exist(saveFileName,'file'),
                showTxt     = sprintf('DataExcel : File %s exists and will be overwritten',saveFileName);
                DTP_ManageText([], showTxt, 'W' ,0)
            end
            warning('off', 'MATLAB:xlswrite:AddSheet');
            
            % two photon video
            fileNum         = length(obj.DMT.VideoFileNames);
            if fileNum > 0,
                
                columnNames     = {'TwoPhoton Video Dir','TwoPhoton Video File Name'};
                columnData{:,1} = repmat({obj.DMT.VideoDir},fileNum,1);
                columnData{:,2} = obj.DMT.VideoFileNames;
                
                stat            = xlswrite(saveFileName,columnNames,       'DataDir','A1');
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','A2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','B2');
                
            else
                DTP_ManageText([], 'DataExcel : No Two Photon video data is saved to Excel', 'W' ,0);
            end
            
            % two photon analysis
            fileNum         = length(obj.DMT.RoiFileNames);
            if fileNum > 0,
                
                columnNames     = {'TwoPhoton Analysis Dir','TwoPhoton Analysis File Name'};
                columnData{:,1} = repmat({obj.DMT.RoiDir},fileNum,1);
                columnData{:,2} = obj.DMT.RoiFileNames;
                
                stat            = xlswrite(saveFileName,columnNames,       'DataDir','C1');
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','C2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','D2');
                
            else
                DTP_ManageText([], 'DataExcel : No Two Photon analysis data is saved to Excel', 'W' ,0);
            end
            
            % behavior side video
            fileNum         = length(obj.DMB.VideoSideFileNames);
            if fileNum > 0,
                
                columnNames     = {'Behavior Side Video Dir','Behavior Side Video File Name'};
                columnData{:,1} = repmat({obj.DMB.VideoDir},fileNum,1);
                columnData{:,2} = obj.DMB.VideoSideFileNames;
                
                stat            = xlswrite(saveFileName,columnNames,       'DataDir','E1');
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','E2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','F2');
                
            else
                DTP_ManageText([], 'DataExcel : No Behavior side video data is saved to Excel', 'W' ,0);
            end
            
            % behavior front video
            fileNum         = length(obj.DMB.VideoFrontFileNames);
            if fileNum > 0,
                
                columnNames     = {'Behavior Front Video Dir','Behavior Front Video File Name'};
                columnData{:,1} = repmat({obj.DMB.VideoDir},fileNum,1);
                columnData{:,2} = obj.DMB.VideoFrontFileNames;
                
                stat            = xlswrite(saveFileName,columnNames,       'DataDir','G1');
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','G2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','H2');
                
            else
                DTP_ManageText([], 'DataExcel : No Behavior front video data is saved to Excel', 'W' ,0);
            end
            
            % behavior analysis
            fileNum         = length(obj.DMB.EventFileNames);
            if fileNum > 0,
                
                columnNames     = {'Behavior Analysis Dir','Behavior Analysis File Name'};
                columnData{:,1} = repmat({obj.DMB.EventDir},fileNum,1);
                columnData{:,2} = reshape(obj.DMB.EventFileNames,[],1);
                
                stat            = xlswrite(saveFileName,columnNames,       'DataDir','I1');
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','I2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','J2');
                
            else
                DTP_ManageText([], 'DataExcel : No Behavior analysis data is saved to Excel', 'W' ,0);
            end
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = LoadExcelFile(obj,filePath)
            % LoadExcelFile - reads directory structures from Excel
            % Input:
            %    obj  - File in Analysis directory
            % Output:
            %    obj  - DMT, DMB initialized
            
            if nargin < 2, filePath = ''; end;
            
            if isempty(filePath),
                DTP_ManageText([], sprintf('DataExcel : Data path to Analysis directory is not specified.'),  'E' ,0);
                return
            end
            obj.ExpDir = filePath;
            
            % check file name
            loadFileName    = fullfile(obj.ExpDir,obj.FileName);
            if ~exist(loadFileName,'file'),
                showTxt     = sprintf('DataExcel : File %s does not exists. Create it or specify correct directory.',loadFileName);
                DTP_ManageText([], showTxt, 'E' ,0)
                return
            end
            
            % Import the data
            [ndata, txt, allData]  = xlsread(loadFileName, 'DataDir');
            % clean
            %allData(cellfun(@(x) isempty(x) || isnumeric(x) || isnan(x),allData)) = {''};
            a = cellfun(@(x) isnan(x),allData, 'UniformOutput', false);
            b = cellfun(@(x) any(x),a);
            allData(b)              = {''};
            
            
            % two photon video
            dInd                    = [1 2];            % A,B
            obj.DMT.VideoDir        = allData{2,dInd(1)};
            validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd(2))));
            fileNum                 = length(validInd);
            if fileNum > 0,
                obj.DMT.VideoFileNames = allData(validInd + 1,dInd(2)); % skip header
            else
                obj.DMT.VideoFileNames = '';
            end
            obj.DMT.VideoFileNum    = fileNum;
            DTP_ManageText([], sprintf('DataExcel : Two Photon video data files found : %d',fileNum), 'W' ,0);
            
            
            % two photon analysis
            dInd                    = [3 4];            % C,D
            obj.DMT.RoiDir          = allData{2,dInd(1)};
            validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd(2))));
            fileNum                 = length(validInd);
            if fileNum > 0,
                obj.DMT.RoiFileNames = allData(validInd + 1,dInd(2)); % skip header
            else
                obj.DMT.RoiFileNames = '';
            end
            obj.DMT.RoiFileNum     = fileNum;
            DTP_ManageText([], sprintf('DataExcel : Two Photon analysis data files found : %d',fileNum), 'W' ,0);
            
            
            % behavior side video
            dInd                    = [5 6];            % E,F
            obj.DMB.VideoDir        = allData{2,dInd(1)};
            validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd(2))));
            fileNum                 = length(validInd);
            if fileNum > 0,
                obj.DMB.VideoSideFileNames = allData(validInd + 1,dInd(2)); % skip header
            else
                obj.DMB.VideoSideFileNames = '';
            end
            obj.DMB.VideoSideFileNum    = fileNum;
            DTP_ManageText([], sprintf('DataExcel : Behavior side video data files found : %d',fileNum), 'W' ,0);
            
            
            % behavior front video
            dInd                    = [7 8];            % G,H
            obj.DMB.VideoDir        = allData{2,dInd(1)};
            validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd(2))));
            fileNum                 = length(validInd);
            if fileNum > 0,
                obj.DMB.VideoFrontFileNames = allData(validInd + 1,dInd(2)); % skip header
            else
                obj.DMB.VideoFrontFileNames = '';
            end
            obj.DMB.VideoFrontFileNum    = fileNum;
            DTP_ManageText([], sprintf('DataExcel : Behavior front video data files found : %d',fileNum), 'W' ,0);
            
            
            % behavior analysis
            dInd                    = [9 10];            % I,J
            obj.DMB.EventDir        = allData{2,dInd(1)};
            validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd(2))));
            fileNum                 = length(validInd);
            if fileNum > 0,
                obj.DMB.EventFileNames = allData(validInd + 1,dInd(2)); % skip header
            else
                obj.DMB.EventFileNames = '';
            end
            obj.DMB.EventFileNum    = fileNum;
            DTP_ManageText([], sprintf('DataExcel : Behavior analysis data files found : %d',fileNum), 'W' ,0);
            
            
        end
        % ---------------------------------------------
        % ==========================================
        function Par = ParInit(obj,Par)
            % ParInit - init Par structure using internal data managers
            % Input:
            %    Par        - structure with defines
            % Output:
            %    Par        - updated
            
            if nargin < 1, error('Must have Par'); end;
            
            % Two Photon
            Par.DMT.VideoDir                    = obj.DMT.VideoDir;            % directory of the Cell image Data
            Par.DMT.RoiDir                      = obj.DMT.RoiDir;            % directory where the user Analysis data is stored
            Par.DMT.VideoFileNum                = obj.DMT.VideoFileNum;             % number of trials (tiff movies) in Video/Image Dir
            Par.DMT.VideoFileNames              = obj.DMT.VideoFileNames;            % file names in the cell Image directory
            Par.DMT.RoiFileNum                  = obj.DMT.RoiFileNum;                % numer of Analysis mat files
            Par.DMT.RoiFileNames                = obj.DMT.RoiFileNames;               % file names of Analysis mat files
            Par.DMT.ValidTrialNum               = min(obj.DMT.VideoFileNum,obj.DMT.RoiFileNum);             % summarizes the number of valid trials
            
            % Behave
            Par.DMB.VideoDir                    = obj.DMB.VideoDir;           % directory of the Front and Side view image Data
            Par.DMB.EventDir                    = obj.DMB.EventDir;           % directory where the user Analysis data is stored
            Par.DMB.VideoFrontFileNum           = obj.DMB.VideoFrontFileNum;             % number of trials (tiff movies) in Behavior/Front Dir
            Par.DMB.VideoFrontFileNames         = obj.DMB.VideoFrontFileNames;            % front video file names in the Behavior directory
            Par.DMB.VideoSideFileNum            = obj.DMB.VideoSideFileNum;             % number of trials (tiff movies) in Behavior/Side Dir
            Par.DMB.VideoSideFileNames          = obj.DMB.VideoSideFileNames;            % side video file names in the Behavior directory
            Par.DMB.EventFileNum                = obj.DMB.EventFileNum;                % numer of Analysis mat files
            Par.DMB.EventFileNames              = obj.DMB.EventFileNames;               % file names of Analysis mat files
            Par.DMB.ValidTrialNum               = min(obj.DMB.EventFileNum,min(obj.DMB.VideoFrontFileNum,obj.DMB.VideoSideFileNum));             % summarizes the number of valid trials
            Par.DMB.VideoFileNum                = min(obj.DMB.VideoFrontFileNum,obj.DMB.VideoSideFileNum);
            if Par.DMB.VideoFileNum > 0, % designate that Jaaba direcotries and movie should be split
                if strcmp(Par.DMB.VideoFrontFileNames{1},Par.DMB.VideoSideFileNames{1}),
                    Par.DMB.JaabaDirNum         = Par.DMB.VideoFileNum;
                end
            end
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = TestDataExtract(obj)
            
            
            
        end
        % ---------------------------------------------
        
        
    end% methods
end% classdef
