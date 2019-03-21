classdef TPA_DataManagerJaaba
    % TPA_DataManagerJaaba - Load Jaaba Behavior directory structures and appropriate events
    % Responsible for data integrity and naming convention between Behavior Imaging , Event Analysis   
    % Analysis SW Assumes that directory structure is:
    %       .....\Imaging\AnimalName\Date\
    %       .....\Videos\AnimalName\Date\
    %       .....\Analysis\AnimalName\Date\
    %
    % If the input is JAABA xls file the import is different.
    % XLS file structure:
    % 
    % File Name | ... | Event Name 1 | Event Name 2 | ....
    % XXXXX_01  | ....|  100         |    250       | ...  % frame start number in video file
    % XXXXX_02  | ....|  100         |    0         | ...  % zero means no event found
    % XXXXX_03  | ....|  0           |    750       | ...  % frame start number in video file
    % ........  | ....|  100         |    290       | ...  % frame start number in video file
    %
    % Inputs:
    %       none
    % Outputs:
    %        directories updated
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 28.12 08.03.18 UD     Using offset to move the data in time.
    % 28.03 07.01.18 UD     Removing TimeInd field - make event class manager .    
    % 23.08 22.03.16 UD     Adding class to event and increasing filter of duration   
    % 21.05 08.09.15 UD     Import Jaaba scores from Jab file - manual scores.   
    % 20.05 19.05.15 UD     Import Jaaba with EventManager Class.   
    % 19.08 07.10.14 UD     For ronen - do not number names.   
    % 19.06 21.09.14 UD     Import movie_comb.avi files.   
    % 18.12 09.04.14 UD     new Jaaba Excel with User support
    % 18.04 28.04.14 UD     Fixing non closed events. Adding Exscel support
    % 17.11 22.04.14 UD     TimeInd bug with Jaaba imoprt
    % 17.06 28.03.14 UD     Support of the new structure and interfaces
    % 16.03 16.02.14 UD     Split the Global manager on fractions
    % 16.01 15.02.14 UD     Updated to support single Behavior image. Adding JAABA support
    % 16.00 13.02.14 UD     Janelia Data integration
    %-----------------------------
    
    
    properties
        VideoDir                     = '';           % directory of the Front and Side view image Data
        EventDir                     = '';           % directory where the user Analysis data is stored
        JaabaDir                       = '';         % directory where the user Jaaba data is stored (usually = BehaviorDir)

        VideoFileNum                = 0;             % number of trials (avi movies) in Video/Image Dir
        VideoFileNames              = {};            % file names in the Image directory
        VideoDataSize              = [];             % data dimensions in a single trial
        VideoFilePattern            = 'movie_comb.avi';       % expected name for video pattern
        
        AnalysisFileNum             = 0;                % numer of Analysis mat files
        AnalysisFileNames           = {};               % file names of Analysis mat files
        AnalysisFilePattern         = 'TPA_Analysis_%03d.mat'; % expected name for analysis

        JaabaDirNum                 = 0;                % numer of Jaaba trial directories
        JaabaFileNames              = {};               % 2D cell array of file names of Jaaba mat files
        JaabaFileClassNum           = 0;                 % number of classifiers
        JaabaFilePattern            = 'scores_*.mat';   % expected name for analysis (regexp match )
        JaabaDirFilter              = '*_*';               % helps to separate front/side directories
        
        EventFileNum                = 0;                % numer of Analysis mat files
        EventFileNames              = {};               % file names of Analysis mat files
        EventFilePattern            = 'BDA_*.mat';      % expected name for analysis
        
        % Excel import support
        JaabaData                   = {};               % contains excel data
        
        % Jab file import export
        JabFileName                 = '';               % name of the jab file
        JabEventLabels              = [];               % contains jab file labels
        JabEventNames               = {};               % event names

        
         % how to offset data from the start
         Offset                     = [0 0 0 0];     % pix    pix     ???     frames
        
         %VideoFileNum               = 0;             % number of trials (avi movies) in Side or Front views
         Trial                      = 0;             % current trial
         ValidTrialNum              = 0;             % summarizes the number of valid trials
%         
        
    end % properties
%     properties (SetAccess = private)
%         %dbgShowErrorMsgGui      = true;          % show error messages
%     end
%     properties (Dependent)
%     end

    methods
        
        % ==========================================
        function obj = TPA_DataManagerJaaba()
            % TPA_DataManagerBehavior - constructor
            % Input:
            %
            % Output:
            %     default values
            
            
        end
        % ---------------------------------------------
 
         % ==========================================
         function [obj,isOK] = SetTrial(obj,trial)
             % sets trial and tests if it is OK
             
             isOK = false;
             
             if trial < 1 || trial > obj.ValidTrialNum,
                 DTP_ManageText([], sprintf('Trial value %d is out of range. No action taken.',trial), 'E' ,0);
                 return;
             end
             isOK       = true;
             obj.Trial = trial;
         end % set.Trial
        % ---------------------------------------------
     
        % ==========================================
        function obj = SelectJaabaData(obj,dirPath)
            % SelectJaabaData - loads Jaaba event score data
            % Input:
            %     dirPath - string path to the directory
            % Output:
            %     JaabaFileNames - cell array of names of the files
            
            if nargin < 2, dirPath = pwd; end;
            
            % check
            if ~exist(dirPath,'dir'),
                showTxt     = sprintf('Can not find directory %s',dirPath);
                DTP_ManageText([], showTxt, 'E' ,0)
                return
            end
            
            % add filter
            dirPathFilt     = fullfile(dirPath,obj.JaabaDirFilter );
            
            
            % Jaaba data is sitting in directories
            jdir            = dir(dirPathFilt);
            % filter ./.. directoris 
            dirNum          = length(jdir);
            boolValid       = [jdir.isdir] == 1;
            for m = 1:dirNum,
                if strcmp('.',jdir(m).name(1)), boolValid(m) = false;  end;
            end
            validDirInd     = find(boolValid); % ignores files
            trialNum        = numel(validDirInd);
            if trialNum < 1,
                showTxt = sprintf('Can not find Jaaba directories in %s. Check the directory name.',dirPath);
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;
            % prob file number in each directory
            newDir           = fullfile(dirPath,jdir(validDirInd(1)).name);
            fileNames        = dir(fullfile(newDir,obj.JaabaFilePattern));
            fileNum          = length(fileNames);
            if fileNum < 1,
                showTxt = sprintf('Can not find Jaaba files matching %s in the specified directory %s. Check the directory name or files.',obj.JaabaFilePattern,newDir);
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;
            % allocate file names
            fileNamesC      = {}; %cell(trialNum,fileNum);
            fileNamesV      = {}; % video files
            classNum        = zeros(trialNum,1);
            
            % collect all - ignore bak files
            for m = 1:trialNum,  
                newDir           = fullfile(dirPath,jdir(validDirInd(m)).name);
                fileNames        = dir(fullfile(newDir,obj.JaabaFilePattern));
                fileNumNew       = length(fileNames);
                if fileNumNew < 1,
                    showTxt = sprintf('Can not find Jaaba files matching %s in the directory %s. Check the directory name or files.',obj.JaabaFilePattern,newDir);
                    DTP_ManageText([], showTxt, 'E' ,0)   ;             
                    continue
                end;
                
                validFileBool    = false(fileNumNew,1);               
                for k = 1:fileNumNew,
                    % Jaaba SW have bak files in the same directory - ignore them
                    if ~isempty(strfind(fileNames(k).name,'bak')),continue; end;
                    validFileBool(k) = true;
                end
                validFileInd     = find(validFileBool);
                validFileNum     = length(validFileInd);
                if validFileNum < 1,
                    showTxt = sprintf('Can not find Jaaba files matching without bak in directory %s. Check the directory name or files.',newDir);
                    DTP_ManageText([], showTxt, 'E' ,0)   ;             
                    continue
                end;
                
                % check that it is compatible over all directories
%                 if m == 1, validFilePrevNum = validFileNum; end
%                 if validFilePrevNum ~= validFileNum,
%                     showTxt = sprintf('Something wrong with number of Jaaba files in directory %s. Try to remove .bak.mat files.',newDir);
%                     DTP_ManageText([], showTxt, 'E' ,0)   ;             
%                     continue
%                 end;
%                 validFilePrevNum = validFileNum;
                classNum(m) = validFileNum;
                for k = 1:validFileNum,
                    fileNamesC{m,k} = fullfile(jdir(validDirInd(m)).name,fileNames(validFileInd(k)).name);
                end
                
                
                % bring movies
                fileNames          = dir(fullfile(newDir,obj.VideoFilePattern));
                fileNumVideo       = length(fileNames);
                if fileNumVideo < 1,
                    showTxt = sprintf('Can not find movie files matching %s in the directory %s. Check the directory name or files.',obj.VideoFilePattern,newDir);
                    DTP_ManageText([], showTxt, 'E' ,0)   ;             
                    continue
                end;   
                fileNamesV{m}   = fullfile(newDir,fileNames(1).name);
                
                
            end
            
            % valid number
            emptyDir                  = cellfun(@isempty, fileNamesV);
            trialNum                  = sum(~emptyDir);
            fileNamesC                = fileNamesC(~emptyDir,:);
            fileNamesV                = fileNamesV(~emptyDir);
            
            
            % output
            obj.JaabaDir              = dirPath;
            obj.JaabaDirNum           = trialNum;   % 
            obj.JaabaFileClassNum     = classNum;   % classifier number
            obj.JaabaFileNames        = fileNamesC; % 2D
            
            obj.VideoFileNum          = trialNum;             % number of trials (avi movies) in Video/Image Dir
            obj.VideoFileNames        = fileNamesV;            % file names in the Image directory
            
            
            DTP_ManageText([], 'Jaaba : data has been read successfully', 'I' ,0)   ;             
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, jabData] = LoadJaabaData(obj,currTrial)
            % LoadAnalysisData - loads currTrial user info data into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     jabData   - jaaba structure information for specific trial
            %         classiiers are subfields  
            
            if nargin < 2, currTrial = 1; end
            jabData = {};
            
            % there was an error during load
            if obj.JaabaDirNum < 1
                showTxt     = sprintf('Jaaba : Can not find directories.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            if obj.JaabaDirNum < currTrial
                showTxt     = sprintf('Jaaba : Requested trial %d exceeds Jaaba directory content.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            
            % check format
            classNum    = obj.JaabaFileClassNum(currTrial);
            jabData     = cell(classNum,1); 
            fileToLoad  = '';
            for m = 1:obj.JaabaFileClassNum(currTrial)
                %
                fileName        = obj.JaabaFileNames{currTrial,m};
                fileToLoad      = fullfile(obj.JaabaDir,fileName);
                
                % check
                 if ~exist(fileToLoad,'file')
                    showTxt     = sprintf('Jaaba : Can not find file %s. Nothing is loaded.',fileToLoad);
                    DTP_ManageText([], showTxt, 'E' ,0) ;
                    return;
                 end
                
                 % get classifier names by filtering files
                 pLoc       = strfind(obj.JaabaFilePattern,'*');
                 prefixName = obj.JaabaFilePattern(1:pLoc-1); % should be scores_
                 sufixName  = obj.JaabaFilePattern(pLoc+1:end); % should be .mat
                 
                 % get prefix and siffix position : there is a directory name befor
                 pPos       = strfind(fileName,prefixName) + length(prefixName);
                 sPos       = strfind(fileName,sufixName);
                 className  = fileName(pPos:sPos-1);
                 
                 % deal with crasy names like . inside
                 className  = regexprep(className,'[\W+]','_');
                
                % mat file load
                jabDataTmp          = load(fileToLoad,'allScores');
                jabData{m}          = jabDataTmp.allScores;
                jabData{m}.Name     = className;
            end

            pathFile = fileparts(fileToLoad);   
            DTP_ManageText([], sprintf('Jaaba : %d classifier data files have been loaded from %s',obj.JaabaFileClassNum(currTrial),pathFile), 'I' ,0)   ;             
        end
        % ---------------------------------------------

        % ==========================================
        function obj = SelectJabFile(obj,fileName)
            % SelectJabFile - loads Jab File manual score data
            % Input:
            %     fileName - string path to the directory and file
            % Output:
            %     JaabaFileNames - cell array of names of the files
            
            if nargin < 2, fileName = fullfile(obj.EventDir,obj.JabFileName); end;
            
            % there was an error during load
            if ~exist(fileName,'file'),
                showTxt     = sprintf('Jaaba : Can not find jab file %s.',fileName);
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end;
            try 
                jb  = load(fileName,'-mat');            
            catch merr
                DTP_ManageText([], merr.message, 'E' ,0) ;
                return
            end
            
            if ~isa(jb.x,'Macguffin')
                DTP_ManageText([], 'Not a Macguffin class', 'E' ,0) ;
            end
            
            trialNum        = length(jb.x.labels);
            if trialNum < 1,
                showTxt = sprintf('Can not find Jab labels in %s. Check the Jaaba manual results.',fileName);
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;
            classNum        = length(jb.x.behaviors.names);
                        
            
            % output
            obj.JaabaDir              = dirPath;
            obj.JaabaDirNum           = trialNum;   % 
            obj.JaabaFileClassNum     = classNum;   % classifier number
            %obj.JaabaFileNames        = fileNamesC; % 2D
            
            obj.JabEventNames         = jb.x.behaviors.names;
            obj.JabEventLabels        = jb.x.labels;
            
            obj.VideoFileNum          = trialNum;             % number of trials (avi movies) in Video/Image Dir
            obj.VideoFileNames        = '';                  % file names in the Image directory
            
            
            DTP_ManageText([], 'Jaaba : jab data file has been read successfully', 'I' ,0)   ;             
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function [obj, eventData] = LoadJabData(obj,currTrial)
            % LoadJabData - loads manual score data from jab file
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     eventData   - roiLast cell array  
            
            if nargin < 2, currTrial = 1; end;
            eventData       = {};
            roiLast         = TPA_EventManager();
            
            
            % there was an error during load
            if obj.JaabaDirNum < 1,
                showTxt     = sprintf('Jaaba : Can not find valid trials.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end;
            
            if obj.JaabaDirNum < currTrial,
                showTxt     = sprintf('Jaaba : Requested trial %d exceeds Jaaba trial content.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            % current labels
            currLabels      = obj.JabEventLabels(currTrial);
            eventNum        = length(currLabels.names);
            dataLen         = currLabels.imp_t1s{1}(1);
            if eventNum < 1,
                DTP_ManageText([], sprintf('Jaaba : Trial %d - no maual class data.',currTrial), 'W' ,0)   ;                     
            end
            
            
            % get data from Jabba scores
            eventCount       = 0;
            for m = 1:eventNum,
                
                
                
                % start and end of the events - could be multiple
                startInd        = currLabels.t0s{1}(m);
                stopInd         = currLabels.t1s{1}(m);
                
                % detrmine if the length has minimal distance
                eventDuration       = stopInd - startInd;
                if any(eventDuration < 0),
                    DTP_ManageText([], sprintf('Jaaba : Trial %d (%d)- can not determine event durations.',currTrial,m), 'E' ,0)   ;                     
                    continue;
                end

                ii                  = 1;
                pos                 = [startInd 50 eventDuration 150];
                xy                  = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                roiLast.Color       = rand(1,3);   % generate colors
                roiLast.Name        = sprintf('%s:%02d',currLabels.names{m},m); %jabData{m}.Name;
                roiLast.SeqNum      = m;
                roiLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
                roiLast.yInd        = round([min(xy(:,2)) max(xy(:,2))]);  % time/frame indices
                roiLast.Data        = zeros(dataLen,1);
                roiLast.Data(startInd(ii):stopInd(ii))  = 1;

                % save
                eventCount           = eventCount + 1;
                eventData{eventCount} = roiLast;
            end

            DTP_ManageText([], sprintf('Jaaba : Converting Jaaba to %d Events : Done',classNum), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function [obj, eventData] = ConvertToAnalysis(obj,jabData)
            % ConvertToAnalysis - converts Jaaba data to Behavioral event format.
            % Get it ready for analysis directory for specific trial 
            % Input:
            %     jabData   - jaaba structure information for specific trial
            %         classiiers are subfields  
            % Output:
             %     eventData   - event structure information for specific trial
            %         classiiers are subfields  
           
            if nargin < 2, error('Requires 2nd argument'); end;
            
            classNum        = length(jabData);
            eventData       = {};
            roiLast          = TPA_EventManager();
            
            
            % get data from Jabba scores
            eventCount       = 0;
            clrMap           = jet(classNum);
            for m = 1:classNum
                
                % actual time events
                eventBool       = jabData{m}.postprocessed{1} > 0.5;
                eventBool       = eventBool(:);
                if ~any(eventBool) 
                    DTP_ManageText([], sprintf('Jaaba : No Events of type %s - nothing to convert.',jabData{m}.Name), 'W' ,0)   ;                     
                    continue
                end
                
                % make sure to close all events
                eventBool(1)    = false;
                eventBool(end)  = false;
                dataLen         = length(eventBool);
                
                % shift by offset
                shiftFrames     = round(obj.Offset(4));
                if shiftFrames > 0
                    eventBool       = [eventBool(shiftFrames+1:dataLen); false(shiftFrames,1)];
                elseif shiftFrames < 0
                    eventBool       = [false(-shiftFrames,1); eventBool(1:dataLen+shiftFrames)];
                end
                
                
                % start and end of the events - could be multiple
                startInd        = find(~eventBool(1:end-1) & eventBool(2:end));
                stopInd         = find(eventBool(1:end-1) & ~eventBool(2:end));
                eventNum        = length(startInd);
                if length(stopInd) ~= eventNum,
                    DTP_ManageText([], sprintf('Jaaba : Classifier %s - something wrong with classification data.',jabData{m}.Name), 'W' ,0)   ;                     
                    eventNum    = min(length(stopInd),eventNum);
                end
                
                % detrmine if the length has minimal distance
                eventDuration       = stopInd(1:eventNum) - startInd(1:eventNum);
                if any(eventDuration < 0)
                    DTP_ManageText([], sprintf('Jaaba : Classifier %s (%d)- can not determine event durations.',jabData{m}.Name,m), 'E' ,0)   ;                     
                    continue;
                end
                
                MinEventDuration        = 3; % frames
                validInd                = find(eventDuration > MinEventDuration);
                
                % asssign
                for k = 1:length(validInd)
                    
                    ii                  = validInd(k);
                    pos                 = [startInd(ii) 50 eventDuration(ii) 150];
                    xy                  = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
%                     roiLast.Color       = rand(1,3);   % generate colors
%                     roiLast.Position    = pos;   
%                     roiLast.xyInd       = xy;          % shape in xy plane
%                     roiLast.Name        = sprintf('%s:%02d',jabData{m}.Name,k); %jabData{m}.Name;
%                     roiLast.SeqNum      = k;
%                     roiLast.TimeInd     = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
                    roiLast.Color       = clrMap(m,:);   % generate colors
                    roiLast.Class       = m;           % designates which class
                    %roiLast.xyInd       = xy;          % shape in xy plane
                    roiLast.Name        = sprintf('%s:%02d',jabData{m}.Name,k); %jabData{m}.Name;
                    roiLast.SeqNum      = k;
                    roiLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
                    roiLast.yInd        = round([min(xy(:,2)) max(xy(:,2))]);  % time/frame indices
                    roiLast.Data        = zeros(dataLen,1);
                    roiLast.Data(startInd(ii):stopInd(ii))  = 1;
                
                    % save
                    eventCount           = eventCount + 1;
                    eventData{eventCount} = roiLast;
                end
            end

            DTP_ManageText([], sprintf('Jaaba : Converting Jaaba to %d Events : Done',classNum), 'I' ,0)   ;             
        end
        % ---------------------------------------------
     
        % ==========================================
        function obj = LoadJaabaExcelData(obj,filePath)
            % LoadJaabaExcelData - loads Jaaba event data from Excel
            % Input:
            %     filePath - string path to the directory and file
            % Output:
            %     jabData - cell array of names of the files along with frame numbers
            
            if nargin < 2, filePath = ''; end;
            jabData = {};

            
            % check
            if ~exist(filePath,'file'),
                showTxt     = sprintf('Jaaba : Can not find file %s',filePath);
                DTP_ManageText([], showTxt, 'E' ,0)
                return
            end
            
            % read excel
            [xlsNUM,xlsTXT,xlsRAW]      = xlsread(filePath);
            
            % do the basic tests
            trialNum       = size(xlsRAW,1) - 1; % 1 for column names
            if trialNum < 1,
                showTxt = sprintf('Jaaba : Excel file %s does not have data rows.',filePath);
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;
            
            % find column with names
            hasColumnExp            = strfind(xlsTXT(1,:),'exp');
            columnInd               = 0;
            for k = 1:length(hasColumnExp),
                if isempty(hasColumnExp{k}), continue; end;
                columnInd = k; 
                break
            end
             if columnInd < 1,
                showTxt = sprintf('Jaaba : Excel file %s do not contain column ''exp'' with name of the video files.',filePath);
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;
            
            % detrmine number of classifiers
            classNum       = size(xlsRAW,2) - columnInd;
             if classNum < 1,
                showTxt = sprintf('Jaaba : Excel file %s do not contain classifier data results.',filePath);
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;

            % read all the data
            for m = 1:trialNum,  
                for k = 1:classNum,
                    jabData{m,k}.FileName  = xlsRAW{m+1,columnInd};
                    jabData{m,k}.ClassName = xlsRAW{1,columnInd+k};
                    frameNum               = (xlsRAW{m+1,columnInd+k});
                    if ~isnumeric(frameNum),frameNum = 0;end
                    if isnan(frameNum),frameNum = 0;end
                    jabData{m,k}.FrameNum = frameNum;
                end
            end
            
            
            % output
            %obj.JaabaDir              = filePath;
            obj.JaabaDirNum           = trialNum;   % 
            obj.JaabaFileClassNum     = classNum;   % classifier number
            obj.JaabaData             = jabData; % 2D
            obj.ValidTrialNum         = trialNum;
            
            DTP_ManageText([], sprintf('Jaaba : Excel data has been read successfully. %d trials, %d classes',trialNum,classNum), 'I' ,0)   ;             
            
        end
        % ---------------------------------------------

        % ==========================================
        function obj = LoadJaabaExcelDataManual(obj,filePath)
            % LoadJaabaExcelDataManual - loads Jaaba event data from Excel and ask Users for column selection
            % Input:
            %     filePath - string path to the directory and file
            % Output:
            %     jabData - cell array of names of the files along with frame numbers
            
            if nargin < 2, filePath = ''; end;
            jabData = {};

            
            % check
            if ~exist(filePath,'file'),
                showTxt     = sprintf('Jaaba : Can not find file %s',filePath);
                DTP_ManageText([], showTxt, 'E' ,0)
                return
            end
            
%             % read excel
%             [xlsNUM,xlsTXT,xlsRAW]      = xlsread(filePath);
%             
%             % do the basic tests
%             trialNum       = size(xlsRAW,1) - 1; % 1 for column names
            
            % Import the data
            [ndata, txt, allData]  = xlsread(filePath);
            % clean
            allData(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),allData)) = {''};

            % Process to find valid columns
            % find columns with numbers
            allData(cellfun(@(x) strcmp(x,'NaN'),allData)) = {0};
            allDataBool         = cellfun(@(x) isnumeric(x),allData);
            validNumColBool     = all(allDataBool(2:end,:)); % skip col names

            % find column with names
            allDataBool         = cellfun(@(x) strncmp(x,'Basler',6),allData);
            validNameColBool    = all(allDataBool(2:end,:)); % skip col names

            % extract 
            validColInd         = find(validNumColBool);
            if isempty(validColInd),
                DTP_ManageText([], sprintf('Jaaba : Excel import is failed. Data in columns is not numeric.'),  'E' ,0);
                return
            end
            columnNames         = allData(1,validColInd);
            trialNames          = allData(2:end,validNameColBool);
            trialNum            = length(trialNames);
            if trialNum < 1,
                showTxt = sprintf('Jaaba : Excel file %s does not have data rows.',filePath);
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;


            % Ask User
            [sel,OK]            = listdlg('ListString',columnNames, 'PromptString','Select columns to use:','Name','JAABA Event Import','ListSize',[300 500]);
            if ~OK, return; end;
            classNum            = length(sel);   
            columnNames         = columnNames(sel);
            eventData           = cell2mat(allData(2:end,validColInd(sel)));

            % read all and assign data
            for m = 1:trialNum,  
                for k = 1:classNum,
                    jabData{m,k}.FileName  = trialNames{m};
                    jabData{m,k}.ClassName = columnNames{k};
                    frameNum               = eventData(m,k);
                    if ~isnumeric(frameNum),frameNum = 0;end
                    if isnan(frameNum),frameNum = 0;end
                    jabData{m,k}.FrameNum = frameNum;
                end
            end
            
            
            % output
            %obj.JaabaDir              = filePath;
            obj.JaabaDirNum           = trialNum;   % 
            obj.JaabaFileClassNum     = classNum;   % classifier number
            obj.JaabaData             = jabData; % 2D
            obj.ValidTrialNum         = trialNum;
            
            DTP_ManageText([], sprintf('Jaaba : Excel data has been read successfully. %d trials, %d classes',trialNum,classNum), 'I' ,0)   ;             
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, eventData] = ConvertExcelToAnalysis(obj,currTrial)
            % ConvertExcelToAnalysis - converts Jaaba Excel data to Behavioral event format.
            % Get it ready for analysis directory for specific trial 
            % Input:
            %     jabData   - jaaba cell structure information for all trials
            %     currTrial - which trial to convert     
            % Output:
             %     eventData   - event structure information for specific trial
            %         classiiers are subfields  
           
             if nargin < 2, currTrial = 1; end;

            [trialNum,classNum]        = size(obj.JaabaData);
            eventData                  = {};
             if classNum < 2 || trialNum < 1,
                showTxt = sprintf('Jaaba : Need to load valid Excel file first.');
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;
            
            if currTrial < 1 || currTrial > trialNum,
                DTP_ManageText([], sprintf('Jaaba : Need to specify valid trial from range 1-%d.',trialNum), 'E' ,0)   ;             
                return
            end;
            jabData          = obj.JaabaData;
            
            
            % prepare ROI prototype 
            roiLast          = TPA_EventManager();
            roiLast.Type     = 1; % ROI_TYPES.RECT should be
            roiLast.Active   = true;   % designates if this pointer structure is in use
            roiLast.NameShow = false;       % manage show name
            roiLast.zInd     = 1;           % location in Z stack
            %roiLast.tInd     = 1;           % location in T stack
            pos              = [0 0 0.1 0.1];
            xy               = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
            roiLast.Position = pos;   
            roiLast.xyInd    = xy;          % shape in xy plane
            roiLast.Name     = 'Rect';
            roiLast.tInd     = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
            
            
            
            % get data from Jabba scores
            eventCount       = 0;
            m                = currTrial;
            DTP_ManageText([], sprintf('Jaaba : Converting trial %d ...',currTrial), 'I' ,0)   ;
            for k = 1:classNum,
                
                % actual time events
                if jabData{m,k}.FrameNum < 1, 
                    DTP_ManageText([], sprintf('Jaaba : No Events of type %s - nothing to convert.',jabData{m,k}.ClassName), 'W' ,0)   ;                     
                    continue
                end
                
                
                % start and end of the events 
                startInd        = jabData{m,k}.FrameNum;
                
                % asssign
                ii                  = 1;
                pos                 = [startInd(ii) 50 32 150];
                xy                  = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                roiLast.Color       = rand(1,3);   % generate colors
                roiLast.Position    = pos;   
                roiLast.xyInd       = xy;          % shape in xy plane
                roiLast.Name        = sprintf('%s',jabData{m,k}.ClassName);
                roiLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices

                % save
                eventCount           = eventCount + 1;
                eventData{eventCount} = roiLast;
            end

            DTP_ManageText([], sprintf('Jaaba : Converting Jaaba Trial %d with %d Events : Done',currTrial,eventCount), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, CheckOK] = CheckData(obj)
            % CheckData - checks Jaaba analysis data compatability
            % Input:
            %     none
            % Output:
            %     CheckOK - indicator of critical errors
            
            CheckOK     = true;
            imageNum    = obj.VideoFileNum;
            
            % user analysis data
            if obj.EventFileNum < 1,
                DTP_ManageText([], 'User analysis data is not found. Trying to continue.', 'W' ,0)   ;
                CheckOK = false;                
            else
                %imageNum = min(imageNum,obj.EventFileNum);
            end        
            
            if obj.VideoFileNum ~= obj.EventFileNum
                DTP_ManageText([], 'Jaaba : Video and Analysis file number missmatch.', 'W' ,0)   ;
            end
            
            % Jaaba analysis data
            if obj.JaabaFileClassNum < 1,
                DTP_ManageText([], 'Jaaba : analysis data is not found. Trying to continue.', 'W' ,0)   ;
            else
                %imageNum = min(imageNum,obj.AnalysisFileNum);
            end
            
            
            % summary
            DTP_ManageText([], sprintf('Check : Status %d : Found %d valid trials.',CheckOK,imageNum), 'I' ,0)   ;
            
            
            % output
            obj.ValidTrialNum           = imageNum;
            obj.Trial                   = 1;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestSelect(obj)
            % TestSelect - performs testing of the directory structure 
            % selection and check process
            
            testVideoDir  = 'C:\Uri\DataJ\Janelia\Videos\m76\10_01_14\';
            obj           = obj.SelectJaabaData(testVideoDir);
            
            % check
            [obj,isOK]    = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TestSelect 1 OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestSelect 1 Fail.'), 'E' ,0)   ;
            end;
            
         
        end
        % ---------------------------------------------
     
        % ==========================================
        function obj = TestLoad(obj)
            % TestLoad - given a directory loads full data
            testVideoDir    = 'C:\Uri\DataJ\Janelia\Videos\d13\14_08_14'; %'C:\Uri\DataJ\Janelia\Videos\m76\10_01_14\';
            tempTrial      = 3;
            
            
            % select again using Full Load function
            obj                         = obj.SelectJaabaData(testVideoDir);

            % load again using Full Load function
            [obj, vidData ]            = obj.LoadJaabaData(tempTrial);
            
            % final
            [obj,isOK]                         = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TestLoad OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestLoad Fail.'), 'E' ,0)   ;
            end;
         
        end
        % ---------------------------------------------
       
        % ==========================================
        function obj = TestConvertToAnalysis(obj)
            
            % TestConvertToAnalysis - reads Jaaba file. Filters scores and
            % saves it into event structure
            
            testVideoDir        = 'C:\Uri\DataJ\Janelia\Videos\m76\10_01_14\';
            
            % select again using Full Load function
            obj                 = obj.SelectJaabaData(testVideoDir);

            
           %jabEvent = cell(Par.DMJ.JaabaDirNum,1);
            for trialInd = 1:obj.JaabaDirNum,
                [obj, jabData]              = obj.LoadJaabaData(trialInd);
                [obj, jabEvent]             = obj.ConvertToAnalysis(jabData);
            end
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestExcelLoad(obj)
            % TestLoad - given a directory loads full data
            testFile        = 'C:\Uri\Projects\Technion\Maria\TwoPhotonAnalysis\Test\D3_ForTPA.xlsx';
            
            
            % select again using Full Load function
            obj                        = obj.LoadJaabaExcelData(testFile);

            % load again using Full Load function
            for trialInd = 1:obj.JaabaDirNum,
                [obj, vidData ]        = obj.ConvertExcelToAnalysis(trialInd);
            end
            
            % final
            [obj,isOK]                 = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TestExcelLoad OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestExcelLoad Fail.'), 'E' ,0)   ;
            end;
         
        end
        % ---------------------------------------------
        
        
        
    end% methods
end% classdef 
