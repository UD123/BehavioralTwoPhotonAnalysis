classdef TPA_DataManagerFileDir
    % TPA_DataManagerFileDir - manages data directory
    % Inputs:
    %       BDA_XXX.mat, TPA_YYY.mat - data base
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 24.03 04.09.16 UD     Adjusting to new flow
    % 23.15 14.06.16 UD     Save prarie experiment
    % 20.10 24.07.15 UD     CSV file support for MAC
    % 19.32 12.05.15 UD     Writing column names even no data is found
    % 19.30 05.05.15 UD     Fixing bugs
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
        function obj = TPA_DataManagerFileDir(fileName)
            % TPA_DataManagerFileDir - constructor
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            if nargin < 1, fileName = 'TPC_ExperimentDataDir.csv'; end;
            
            obj.FileName = fileName;
            obj.ExpDir   = pwd;
            
            obj          = Clear(obj);            
        end
        
%         % ==========================================
%         function obj = Init(obj,Par)
%             % Init - init Par structure related managers of the DB
%             % Input:
%             %    Par        - structure with defines
%             % Output:
%             %     default values
%             
%             if nargin < 1, error('Must have Par'); end;
%             
%             % manager copy
%             %obj.DMB                     = Par.DMB;
%             %obj.DMT                     = Par.DMT;
%             obj.FileName                = Par.CsvDataDirFileName;
%             obj.ExpDir                  = Par.DMT.RoiDir;
%             
%             obj                         = Clear(obj);            
%             
%         end
%         
        
        % ==========================================
        function obj = Clear(obj)
            % Clear - clears temp structures
            % Input:
            %    none
            % Output:
            %     default values
            
            if nargin < 1, error('Must have Par'); end;
            
            
            obj.DMT                     = TPA_DataManagerTwoPhoton();
            obj.DMB                     = TPA_DataManagerBehavior(); 
            
            
        end
        
        
        % ==========================================
        function obj = SaveExcelFile(obj,Par)
            % SaveExcelFile - writes directory structures to Excel
            % Input:
            %    Par  - DMT, DMB initialized
            % Output:
            %    obj  - File in Analysis directory
            
            obj.DMB                     = Par.DMB;
            obj.DMT                     = Par.DMT;
            %obj.FileName                = Par.ExpDataDirFileName;
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
            columnNames     = {'TwoPhoton Video Dir','TwoPhoton Video File Name'};
            stat            = xlswrite(saveFileName,columnNames,       'DataDir','A1');
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMT.VideoDir},fileNum,1);
                columnData{:,2} = obj.DMT.VideoFileNames;
                
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','A2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','B2');
                
            else
                DTP_ManageText([], 'DataExcel : No Two Photon video data is saved to Excel', 'W' ,0);
            end
            
            % two photon analysis
            fileNum         = length(obj.DMT.RoiFileNames);
            columnNames     = {'TwoPhoton Analysis Dir','TwoPhoton Analysis File Name'};
            stat            = xlswrite(saveFileName,columnNames,       'DataDir','C1');
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMT.RoiDir},fileNum,1);
                columnData{:,2} = obj.DMT.RoiFileNames;
                
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','C2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','D2');
                
            else
                DTP_ManageText([], 'DataExcel : No Two Photon analysis data is saved to Excel', 'W' ,0);
            end
            
            % behavior side video
            fileNum         = length(obj.DMB.VideoSideFileNames);
            columnNames     = {'Behavior Side Video Dir','Behavior Side Video File Name'};
            stat            = xlswrite(saveFileName,columnNames,       'DataDir','E1');
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMB.VideoDir},fileNum,1);
                columnData{:,2} = obj.DMB.VideoSideFileNames;
                
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','E2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','F2');
                
            else
                DTP_ManageText([], 'DataExcel : No Behavior side video data is saved to Excel', 'W' ,0);
            end
            
            % behavior front video
            fileNum         = length(obj.DMB.VideoFrontFileNames);
            columnNames     = {'Behavior Front Video Dir','Behavior Front Video File Name'};
            stat            = xlswrite(saveFileName,columnNames,       'DataDir','G1');
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMB.VideoDir},fileNum,1);
                columnData{:,2} = obj.DMB.VideoFrontFileNames;
                
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','G2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','H2');
                
            else
                DTP_ManageText([], 'DataExcel : No Behavior front video data is saved to Excel', 'W' ,0);
            end
            
            % behavior analysis
            fileNum         = length(obj.DMB.EventFileNames);
            columnNames     = {'Behavior Analysis Dir','Behavior Analysis File Name'};
            stat            = xlswrite(saveFileName,columnNames,       'DataDir','I1');
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMB.EventDir},fileNum,1);
                columnData{:,2} = reshape(obj.DMB.EventFileNames,[],1);
                
                stat            = xlswrite(saveFileName,columnData{:,1},   'DataDir','I2');
                stat            = xlswrite(saveFileName,columnData{:,2},   'DataDir','J2');
                
            else
                DTP_ManageText([], 'DataExcel : No Behavior analysis data is saved to Excel', 'W' ,0);
            end
            
        end
        
        % ==========================================
        function obj = SaveTableFile(obj,Par)
            % SaveTableFile - writes directory structures to CSV file
            % Uses table
            % Input:
            %    Par  - DMT, DMB initialized
            % Output:
            %    obj  - File in Analysis directory
            
            obj.DMB                     = Par.DMB;
            obj.DMT                     = Par.DMT;
            %obj.FileName                = Par.CsvDataDirFileName;
            obj.ExpDir                  = Par.DMT.RoiDir;
            
            if isempty(obj.ExpDir),
                DTP_ManageText([], sprintf('DataCSV : Analysis directory is not specified.'),  'E' ,0);
                return
            end
            
            % create save file name
            saveFileName    = fullfile(obj.ExpDir,obj.FileName);
            if exist(saveFileName,'file'),
                showTxt     = sprintf('DataCSV : File %s exists and will be overwritten',saveFileName);
                DTP_ManageText([], showTxt, 'W' ,0)
            end
            %warning('off', 'MATLAB:xlswrite:AddSheet');
            
            % two photon video - support of Prarie -TBD
            if isa(obj.DMT,'TPA_DataManagerPrarie'),errordlg('Prarie is not supported yet'); return; end;
            if isa(obj.DMT,'TPA_DataManagerTwoChannel'),errordlg('Prarie is not supported yet'); return; end;
            
            %fileNum         = length(obj.DMT.VideoFileNames);
            fileNum         = size(obj.DMT.VideoFileNames,1);
            columnNames     = {'TwoPhoton Video Dir','TwoPhoton Video File Name','TwoPhoton Analysis Dir','TwoPhoton Analysis File Name',...
                               'Behavior Side Video Dir','Behavior Side Video File Name','Behavior Front Video Dir','Behavior Front Video File Name',...
                               'Behavior Analysis Dir','Behavior Analysis File Name'};
                           
            columnData      = cell(200,length(columnNames));
            maxLineNum      = 0;
            %dlmwrite(saveFileName,columnNames, ',',1,1);
            if fileNum > 0,
                
                columnData(1:fileNum,1) = repmat({obj.DMT.VideoDir},fileNum,1);
                columnData(1:fileNum,2) = reshape(obj.DMT.VideoFileNames(:,1),fileNum,1);
                
            else
                DTP_ManageText([], 'DataCSV : No Two Photon video data is saved to CSV', 'W' ,0);
            end
            maxLineNum = max(maxLineNum,fileNum);
            
            % two photon analysis
            fileNum         = length(obj.DMT.RoiFileNames);
            %columnNames     = {'TwoPhoton Analysis Dir','TwoPhoton Analysis File Name'};
            if fileNum > 0,
                
                columnData(1:fileNum,3) = repmat({obj.DMT.RoiDir},fileNum,1);
                columnData(1:fileNum,4) = obj.DMT.RoiFileNames;
                
            else
                columnData(1,3) = {obj.DMT.RoiDir};
                DTP_ManageText([], 'DataCSV : No Two Photon analysis data is saved to CSV', 'W' ,0);
            end
            maxLineNum = max(maxLineNum,fileNum);
            
            % behavior side video
            if isprop(obj.DMB,'VideoSideFileNames'), %errordlg('Call 991 : Can not save. Must resolve Prarie and Janelia'); end;
                fileNamesBehaive = obj.DMB.VideoSideFileNames;
            else
                fileNamesBehaive = obj.DMB.VideoFileNames;
            end
            fileNum         = length(fileNamesBehaive);
            %columnNames     = {'Behavior Side Video Dir','Behavior Side Video File Name'};
            %dlmwrite(saveFileName,columnNames,       ',',1,5);
            if fileNum > 0,
                
                columnData(1:fileNum,5) = repmat({obj.DMB.VideoDir},fileNum,1);
                columnData(1:fileNum,6) = fileNamesBehaive;
                
            else
                DTP_ManageText([], 'DataCSV : No Behavior side video data is saved to CSV', 'W' ,0);
            end
            maxLineNum = max(maxLineNum,fileNum);
            
            % behavior front video
            if isprop(obj.DMB,'VideoFrontFileNames'), %errordlg('Call 991 : Can not save. Must resolve Prarie and Janelia'); end;
                fileNamesBehaive = obj.DMB.VideoFrontFileNames;
            else
                fileNamesBehaive = obj.DMB.VideoFileNames;
            end
            fileNum         = length(fileNamesBehaive);
            %columnNames     = {'Behavior Front Video Dir','Behavior Front Video File Name'};
            if fileNum > 0,
                
                columnData(1:fileNum,7) = repmat({obj.DMB.VideoDir},fileNum,1);
                columnData(1:fileNum,8) = fileNamesBehaive;
                
            else
                DTP_ManageText([], 'DataCSV : No Behavior front video data is saved to CSV', 'W' ,0);
            end
            maxLineNum = max(maxLineNum,fileNum);
            
            % behavior analysis
            fileNum         = length(obj.DMB.EventFileNames);
            %columnNames     = {'Behavior Analysis Dir','Behavior Analysis File Name'};
            if fileNum > 0,
                
                columnData(1:fileNum,9) = repmat({obj.DMB.EventDir},fileNum,1);
                columnData(1:fileNum,10) = reshape(obj.DMB.EventFileNames,[],1);
            else
                columnData(1,9) = {obj.DMB.EventDir}; % write at least one
                DTP_ManageText([], 'DataCSV : No Behavior analysis data is saved to CSV', 'W' ,0);
            end
            maxLineNum = max(maxLineNum,fileNum);
            
            % final table
            columnDataFinal  = cat(1,columnNames,columnData(1:maxLineNum,:));
            
            % Create table to write
            T = table(columnDataFinal);
            writetable(T,saveFileName,'WriteVariableNames',false);
                
            DTP_ManageText([], sprintf('DataCSV : Directory structure is saved to %s',saveFileName), 'I' ,0);
            
        end
        
        % ==========================================
        function obj = SaveCsvFile(obj,Par)
            % SaveCsvFile - writes directory structures to CSV
            % Input:
            %    Par  - DMT, DMB initialized
            % Output:
            %    obj  - File in Analysis directory
            
            obj.DMB                     = Par.DMB;
            obj.DMT                     = Par.DMT;
            %obj.FileName                = Par.CsvDataDirFileName;
            obj.ExpDir                  = Par.DMT.RoiDir;
            
            if isempty(obj.ExpDir),
                DTP_ManageText([], sprintf('DataCSV : Analysis directory is not specified.'),  'E' ,0);
                return
            end
            
            % create save file name
            saveFileName    = fullfile(obj.ExpDir,obj.FileName);
            if exist(saveFileName,'file'),
                showTxt     = sprintf('DataCSV : File %s exists and will be overwritten',saveFileName);
                DTP_ManageText([], showTxt, 'W' ,0)
            end
            %warning('off', 'MATLAB:xlswrite:AddSheet');
            
            % two photon video
            fileNum         = length(obj.DMT.VideoFileNames);
            columnNames     = {'TwoPhoton Video Dir','TwoPhoton Video File Name'};
            dlmwrite(saveFileName,columnNames, ',',1,1);
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMT.VideoDir},fileNum,1);
                columnData{:,2} = obj.DMT.VideoFileNames;
                
                dlmwrite(saveFileName,columnData{:,1},  ',', 2,1);
                dlmwrite(saveFileName,columnData{:,2},  ',', 2,2);
                
            else
                DTP_ManageText([], 'DataCSV : No Two Photon video data is saved to CSV', 'W' ,0);
            end
            
            % two photon analysis
            fileNum         = length(obj.DMT.RoiFileNames);
            columnNames     = {'TwoPhoton Analysis Dir','TwoPhoton Analysis File Name'};
            dlmwrite(saveFileName,columnNames,   ',',    1,3);
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMT.RoiDir},fileNum,1);
                columnData{:,2} = obj.DMT.RoiFileNames;
                
                dlmwrite(saveFileName,columnData{:,1}, ',',  2,3);
                dlmwrite(saveFileName,columnData{:,2}, ',',  2,4);
                
            else
                DTP_ManageText([], 'DataCSV : No Two Photon analysis data is saved to CSV', 'W' ,0);
            end
            
            % behavior side video
            fileNum         = length(obj.DMB.VideoSideFileNames);
            columnNames     = {'Behavior Side Video Dir','Behavior Side Video File Name'};
            dlmwrite(saveFileName,columnNames,       ',',1,5);
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMB.VideoDir},fileNum,1);
                columnData{:,2} = obj.DMB.VideoSideFileNames;
                
                dlmwrite(saveFileName,columnData{:,1}, ',',  2,5);
                dlmwrite(saveFileName,columnData{:,2}, ',',  2,6);
                
            else
                DTP_ManageText([], 'DataCSV : No Behavior side video data is saved to CSV', 'W' ,0);
            end
            
            % behavior front video
            fileNum         = length(obj.DMB.VideoFrontFileNames);
            columnNames     = {'Behavior Front Video Dir','Behavior Front Video File Name'};
            dlmwrite(saveFileName,columnNames,   ',',    1,7);
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMB.VideoDir},fileNum,1);
                columnData{:,2} = obj.DMB.VideoFrontFileNames;
                
                dlmwrite(saveFileName,columnData{:,1}, ',',  2,7);
                dlmwrite(saveFileName,columnData{:,2}, ',',  2,8);
                
            else
                DTP_ManageText([], 'DataCSV : No Behavior front video data is saved to CSV', 'W' ,0);
            end
            
            % behavior analysis
            fileNum         = length(obj.DMB.EventFileNames);
            columnNames     = {'Behavior Analysis Dir','Behavior Analysis File Name'};
            dlmwrite(saveFileName,columnNames,   ',',    1,9);
            if fileNum > 0,
                
                columnData{:,1} = repmat({obj.DMB.EventDir},fileNum,1);
                columnData{:,2} = reshape(obj.DMB.EventFileNames,[],1);
                
                dlmwrite(saveFileName,columnData{:,1}, ',',  2,9);
                dlmwrite(saveFileName,columnData{:,2}, ',',  2,10);
                
            else
                DTP_ManageText([], 'DataCSV : No Behavior analysis data is saved to CSV', 'W' ,0);
            end
            
        end
        
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
            
            colNum                  = size(allData,2);
            for dInd = 1:2:colNum,
                
                switch allData{1,dInd},
                    case {'TwoPhoton Video Dir'},
                        
                        
                        % two photon video
                        %dInd                    = [1 2];            % A,B
                        %columnNames             = {'TwoPhoton Video Dir','TwoPhoton Video File Name'};
                        
                        obj.DMT.VideoDir        = allData{2,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMT.VideoFileNames = allData(validInd + 1,dInd+1); % skip header
                        else
                            obj.DMT.VideoFileNames = '';
                        end
                        obj.DMT.VideoFileNum    = fileNum;
                        DTP_ManageText([], sprintf('DataExcel : Two Photon video data files found : %d',fileNum), 'W' ,0);
                        
                        
                    case {'TwoPhoton Analysis Dir'},
                        
                        
                        % two photon analysis
                        %dInd                    = [3 4];            % C,D
                        %columnNames             = {'TwoPhoton Analysis Dir','TwoPhoton Analysis File Name'};
                        
                        obj.DMT.RoiDir          = allData{2,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMT.RoiFileNames = allData(validInd + 1,dInd+1); % skip header
                        else
                            obj.DMT.RoiFileNames = '';
                        end
                        obj.DMT.RoiFileNum     = fileNum;
                        DTP_ManageText([], sprintf('DataExcel : Two Photon analysis data files found : %d',fileNum), 'W' ,0);
                        
                        
                    case {'Behavior Side Video Dir'},
                        
                        % behavior side video
                        %dInd                    = [5 6];            % E,F
                        %columnNames             = {'Behavior Side Video Dir','Behavior Side Video File Name'};
                        
                        obj.DMB.VideoDir        = allData{2,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMB.VideoSideFileNames = allData(validInd + 1,dInd+1); % skip header
                        else
                            obj.DMB.VideoSideFileNames = '';
                        end
                        obj.DMB.VideoSideFileNum    = fileNum;
                        DTP_ManageText([], sprintf('DataExcel : Behavior side video data files found : %d',fileNum), 'W' ,0);
                        
                        
                    case {'Behavior Front Video Dir'},
                        
                        
                        % behavior front video
                        %dInd                    = [7 8];            % G,H
                        %columnNames             = {'Behavior Front Video Dir','Behavior Front Video File Name'};
                        
                        obj.DMB.VideoDir        = allData{2,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMB.VideoFrontFileNames = allData(validInd + 1,dInd+1); % skip header
                        else
                            obj.DMB.VideoFrontFileNames = '';
                        end
                        obj.DMB.VideoFrontFileNum    = fileNum;
                        DTP_ManageText([], sprintf('DataExcel : Behavior front video data files found : %d',fileNum), 'W' ,0);
                        
                        
                    case {'Behavior Analysis Dir'},
                        
                        % behavior analysis
                        %dInd                    = [9 10];            % I,J
                        %columnNames             = {'Behavior Analysis Dir','Behavior Analysis File Name'};
                        
                        obj.DMB.EventDir        = allData{2,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(2:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMB.EventFileNames = allData(validInd + 1,dInd+1); % skip header
                        else
                            obj.DMB.EventFileNames = '';
                        end
                        obj.DMB.EventFileNum    = fileNum;
                        DTP_ManageText([], sprintf('DataExcel : Behavior analysis data files found : %d',fileNum), 'W' ,0);
                        
                    case {''},      % continue
                        %continue
                        
                    otherwise
                        error('Unknown column %s',allData{1,dInd})
                end
            end
            
            
        end
        
        % ==========================================
        function obj = LoadTableFile(obj,filePath)
            % LoadTableFile - reads directory structures from CSV
            % Input:
            %    obj  - File in Analysis directory
            % Output:
            %    obj  - DMT, DMB initialized
            
            if nargin < 2, filePath = ''; end;
            
            if isempty(filePath),
                DTP_ManageText([], sprintf('DataCSV : Data path to Analysis directory is not specified.'),  'E' ,0);
                return
            end
            obj.ExpDir      = fileparts(filePath);
            
            % check file name
            loadFileName    = fullfile(obj.ExpDir,obj.FileName);
            if ~exist(loadFileName,'file'),
                showTxt     = sprintf('DataCSV : File %s does not exists. Create it or specify correct directory.',loadFileName);
                DTP_ManageText([], showTxt, 'E' ,0)
                return
            end
            % read table
            T                       = readtable(loadFileName);
            
            % Import the data
            allData                = table2cell(T);
            columnNames            = T.Properties.VariableNames;
            %[ndata, txt, allData]  = xlsread(loadFileName, 'DataDir');
            % clean
            %allData(cellfun(@(x) isempty(x) | isnumeric(x) | isnan(x),allData),'UniformOutput',false) = {''};
            a = cellfun(@(x) isempty(x) | isnumeric(x) | isnan(x),allData, 'UniformOutput', false);
            b = cellfun(@(x) any(x),a);
            allData(b)              = {''};
            
            colNum                  = size(allData,2);
            for dInd = 1:2:colNum,
                
                switch columnNames{1,dInd},
                    case {'TwoPhotonVideoDir'}, % NO SPACES -TREATED AS VARIABLES
                        
                        
                        % two photon video
                        %dInd                    = [1 2];            % A,B
                        %columnNames             = {'TwoPhoton Video Dir','TwoPhoton Video File Name'};
                        
                        obj.DMT.VideoDir        = allData{1,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(1:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMT.VideoFileNames = allData(validInd ,dInd+1); % skip header
                        else
                            obj.DMT.VideoFileNames = '';
                        end
                        obj.DMT.VideoFileNum    = fileNum;
                        DTP_ManageText([], sprintf('DataCSV : Two Photon video data files found : %d',fileNum), 'W' ,0);
                        
                        
                    case {'TwoPhotonAnalysisDir'},
                        
                        
                        % two photon analysis
                        %dInd                    = [3 4];            % C,D
                        %columnNames             = {'TwoPhoton Analysis Dir','TwoPhoton Analysis File Name'};
                        
                        obj.DMT.RoiDir          = allData{1,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(1:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMT.RoiFileNames = allData(validInd ,dInd+1); % skip header
                        else
                            obj.DMT.RoiFileNames = '';
                        end
                        obj.DMT.RoiFileNum     = fileNum;
                        DTP_ManageText([], sprintf('DataCSV : Two Photon analysis data files found : %d',fileNum), 'W' ,0);
                        
                        
                    case {'BehaviorSideVideoDir'},
                        
                        % behavior side video
                        %dInd                    = [5 6];            % E,F
                        %columnNames             = {'Behavior Side Video Dir','Behavior Side Video File Name'};
                        
                        obj.DMB.VideoDir        = allData{1,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(1:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMB.VideoSideFileNames = allData(validInd ,dInd+1); % skip header
                        else
                            obj.DMB.VideoSideFileNames = '';
                        end
                        obj.DMB.VideoSideFileNum    = fileNum;
                        DTP_ManageText([], sprintf('DataCSV : Behavior side video data files found : %d',fileNum), 'W' ,0);
                        
                        
                    case {'BehaviorFrontVideoDir'},
                        
                        
                        % behavior front video
                        %dInd                    = [7 8];            % G,H
                        %columnNames             = {'Behavior Front Video Dir','Behavior Front Video File Name'};
                        
                        obj.DMB.VideoDir        = allData{1,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(1:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMB.VideoFrontFileNames = allData(validInd ,dInd+1); % skip header
                        else
                            obj.DMB.VideoFrontFileNames = '';
                        end
                        obj.DMB.VideoFrontFileNum    = fileNum;
                        DTP_ManageText([], sprintf('DataCSV : Behavior front video data files found : %d',fileNum), 'W' ,0);
                        
                        
                    case {'BehaviorAnalysisDir'},
                        
                        % behavior analysis
                        %dInd                    = [9 10];            % I,J
                        %columnNames             = {'Behavior Analysis Dir','Behavior Analysis File Name'};
                        
                        obj.DMB.EventDir        = allData{1,dInd};
                        validInd                = find(cellfun(@(x) ~isempty(x),allData(1:end,dInd+1)));
                        fileNum                 = length(validInd);
                        if fileNum > 0,
                            obj.DMB.EventFileNames = allData(validInd ,dInd+1); % skip header
                        else
                            obj.DMB.EventFileNames = '';
                        end
                        obj.DMB.EventFileNum    = fileNum;
                        DTP_ManageText([], sprintf('DataCSV : Behavior analysis data files found : %d',fileNum), 'W' ,0);
                        
                    case {''},      % continue
                        %continue
                        
                    otherwise
                        error('Unknown column %s',allData{1,dInd})
                end
            end
            
            
        end
        
        % ==========================================
        function obj = Preview(obj,dirName)
            % Show current Data management file
            if nargin < 2, dirName = obj.ExpDir; end;
            
            obj.ExpDir         = dirName;
            fileExcelName      = fullfile(obj.ExpDir,obj.FileName);
            try
                winopen(fileExcelName);
                DTP_ManageText([], sprintf('Experiment : New configuration is done. '), 'I' ,0)   ;
            catch
                DTP_ManageText([], sprintf('Experiment : Can not open file %s',fileExcelName), 'E' ,0)   ;
            end
            
            
        end
        
        
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
            if ~isempty(obj.DMT.RoiDir),
            Par.DMT.RoiDir                      = obj.DMT.RoiDir;            % directory where the user Analysis data is stored
            end
            Par.DMT.VideoFileNum                = obj.DMT.VideoFileNum;             % number of trials (tiff movies) in Video/Image Dir
            Par.DMT.VideoFileNames              = obj.DMT.VideoFileNames;            % file names in the cell Image directory
            Par.DMT.RoiFileNum                  = obj.DMT.RoiFileNum;                % numer of Analysis mat files
            Par.DMT.RoiFileNames                = obj.DMT.RoiFileNames;               % file names of Analysis mat files
            Par.DMT.ValidTrialNum               = max(obj.DMT.VideoFileNum,obj.DMT.RoiFileNum);             % summarizes the number of valid trials
            
            % Behave
            Par.DMB.VideoDir                    = obj.DMB.VideoDir;           % directory of the Front and Side view image Data
            if ~isempty(obj.DMB.EventDir),
            Par.DMB.EventDir                    = obj.DMB.EventDir;           % directory where the user Analysis data is stored
            end
            Par.DMB.VideoFrontFileNum           = obj.DMB.VideoFrontFileNum;             % number of trials (tiff movies) in Behavior/Front Dir
            Par.DMB.VideoFrontFileNames         = obj.DMB.VideoFrontFileNames;            % front video file names in the Behavior directory
            Par.DMB.VideoSideFileNum            = obj.DMB.VideoSideFileNum;             % number of trials (tiff movies) in Behavior/Side Dir
            Par.DMB.VideoSideFileNames          = obj.DMB.VideoSideFileNames;            % side video file names in the Behavior directory
            Par.DMB.EventFileNum                = obj.DMB.EventFileNum;                % numer of Analysis mat files
            Par.DMB.EventFileNames              = obj.DMB.EventFileNames;               % file names of Analysis mat files
            Par.DMB.ValidTrialNum               = max(obj.DMB.EventFileNum,max(obj.DMB.VideoFrontFileNum,obj.DMB.VideoSideFileNum));             % summarizes the number of valid trials
            Par.DMB.VideoFileNum                = min(obj.DMB.VideoFrontFileNum,obj.DMB.VideoSideFileNum);
            if Par.DMB.VideoFileNum > 0, % designate that Jaaba direcotries and movie should be split
                if strcmp(Par.DMB.VideoFrontFileNames{1},Par.DMB.VideoSideFileNames{1}),
                    Par.DMB.JaabaDirNum         = Par.DMB.VideoFileNum;
                end
            end
            
        end
        
        
        
        % ==========================================
        function obj = TestDataExtract(obj)
            
            
            
        end
        
        
    end% methods
end% classdef
