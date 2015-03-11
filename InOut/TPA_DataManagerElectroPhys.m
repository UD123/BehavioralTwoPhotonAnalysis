classdef TPA_DataManagerElectroPhys
    % TPA_DataManagerElectroPhys - Initializes/load Electro Physiology directory structures and appropriate events
    % Responsible for data integrity and naming convention between ElectroPhys data, Imaging, Event Analysis   
    % Analysis SW
    % Assumes that directory structure is:
    %       .....\Imaging\AnimalName\Date\TSeries_XXX
    %       .....\Analysis\AnimalName\Date\
    
    % Inputs:
    %       none
    % Outputs:
    %        directories updated
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 18.00 08.04.14 UD     Created  
    % 17.08 05.04.14 UD     adding clean  
    % 16.11 22.02.14 UD     analysis file name load fix
    % 16.07 20.02.14 UD     Adding resolution parameters
    % 16.04 17.02.14 UD     Adding decimation and splitting record remove
    % 16.03 16.02.14 UD     Split the Global manager on fractions
    % 16.01 15.02.14 UD     Updated to support single ElectroPhys image. Adding JAABA support
    % 16.00 13.02.14 UD     Janelia Data integration
    %-----------------------------
    
    
    properties
        VideoDir                     = '';           % directory of the Front and Side view image Data
        EventDir                     = '';           % directory where the user Analysis data is stored
       
        VideoFileNum                = 0;             % number of trials (tiff movies) in Video/Image Dir
        VideoFileNames              = {};            % file names in the cell Image directory
        VideoDataSize               = [];             % data dimensions in a single trial
        VideoFilePattern            = '*.tif';       % expected name for video pattern
        VideoDirFilter              = 'TSeries*';    % helps to separate folders
        VideoDirNum                 = 0;
        VideoDirNames              = {};             % dir names in the TSeries Image directory
        
        %RecordData                  = [];
        
        EventFileNum                = 0;                % numer of Analysis mat files
        EventFileNames              = {};               % file names of Analysis mat files
        EventFilePattern            = 'BDA_*.mat';      % expected name for analysis

        
%         % common info
         Trial                      = 0;             % current trial
         ValidTrialNum              = 0;             % summarizes the number of valid trials
         
        % set up resolution for sync                     X     Y     Z             T
        Resolution                 = [1 1 1 1];     % um/pix um/pix um/pix-else  frame/sec
        % how to offset data from start 
        Offset                     = [0 0 0 0];     % pix    pix     ???     frames
        % decimate
        DecimationFactor           = [1 1 1 1];     % decimate XYZT plane of the data
%         
        % split tif file into Z slaices
        SliceNum                   = 1;             % if Z slice = 2 - two Z volumes are generated, 3 - 3 volumes
        
    end % properties
%     properties (SetAccess = private)
%         %dbgShowErrorMsgGui      = true;          % show error messages
%     end
%     properties (Dependent)
%     end

    methods
        
        % ==========================================
        function obj = TPA_DataManagerElectroPhys(varargin)
            % TPA_DataManagerElectroPhys - constructor
            % Input:
            %
            % Output:
            %     default values
%             
%             for k = 1:2:nargin,
%                if strcmp(varargin{2*k-1},'DecimationFactor'), obj.DecimationFactor =  varargin{2*k}; end;
%             end
%             % check
%             obj.DecimationFactor = max(1,min(16,round(obj.DecimationFactor)));
%             
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = Clean(obj)
            % Clean - restores default
            % Input:
            %
            % Output:
            %     default values
            obj.VideoDir                     = '';           % directory of the Front and Side view image Data
            obj.EventDir                     = '';           % directory where the user Analysis data is stored
            obj.VideoFileNum                = 0;             % number of trials (tiff movies) in Video/Image Dir
            obj.VideoFileNames              = {};            % file names in the cell Image directory
            obj.VideoDataSize               = [];             % data dimensions in a single trial
            obj.VideoFilePattern            = '*.tif';       % expected name for video pattern
            obj.VideoDirFilter              = 'TSeries*';    % helps to separate folders
            obj.VideoDirNum                 = 0;
            obj.VideoDirNames              = {};             % dir names in the TSeries Image directory
            obj.EventFileNum                = 0;                % numer of Analysis mat files
            obj.EventFileNames              = {};               % file names of Analysis mat files
            obj.EventFilePattern            = 'BDA_*.mat';      % expected name for analysis
            obj.VideoFileNum               = 0;             % number of trials (avi movies) in Side or Front views
            obj.Trial                      = 0;             % current trial
            obj.ValidTrialNum              = 0;             % summarizes the number of valid trials
            obj.Resolution                 = [1 1 1 1];     % um/pix um/pix um/pix-else  frame/sec
            obj.Offset                     = [0 0 0 0];     % pix    pix     ???     frames
            obj.DecimationFactor           = [1 1 1 1];     % decimate XYZT plane of the data
            obj.SliceNum                   = 1;             % if Z slice = 2 - two Z volumes are generated, 3 - 3 volumes
            
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
       
        % ==========================================
         function [obj,isOK] = SetSliceNum(obj,sliceNum)
             % how many slices to split
%              if obj.VideoFileNum < 1,
%                  DTP_ManageText([], sprintf('No video data found. May be you need to load your video files.'), 'E' ,0);
%                  return;
%              end
             isOK                   = true;
             obj.SliceNum           = sliceNum;
             DTP_ManageText([], sprintf('Slice Number is : %d',sliceNum), 'I' ,0);
             
         end
         
         
         % ==========================================
         function [obj,isOK] = SetResolution(obj,resolValues)
             % sets resolution for Video source
             
             isOK = false;
             resolValuesTmp = resolValues;
             
             % check XY
             resolValuesTmp(1:2) = max(.1,min(1000,(resolValues(1:2))));             
             if ~all(resolValuesTmp(1:2) == resolValues(1:2)),
                 DTP_ManageText([], sprintf('XY Resolution of um /pixel is out of range [0.1:1000] or non equal for X and Y. Not set - Fix it.'), 'E' ,0);
                 return;
             end
             % check Z
             resolValuesTmp(3) = max(1,min(1,round(resolValues(3))));             
             if ~all(resolValuesTmp(3) == resolValues(3)),
                 DTP_ManageText([], sprintf('Z Resolution must be 1. Not set - Fix it.'), 'E' ,0);
                 return;
             end
             % check T
             resolValuesTmp(4) = max(1,min(1000,round(resolValues(4))));             
             if ~all(resolValuesTmp(4) == resolValues(4)),
                 DTP_ManageText([], sprintf('T Frame Rate is out of range [1:1000] or non integer. Not set - Fix it'), 'E' ,0);
                 return;
             end
             
             isOK             = true;
             obj.Resolution   = resolValues;
             DTP_ManageText([], sprintf('Resolution is : %d [um/pix] %d [um/pix] %d [um/frame] %d [frame/sec]',resolValues), 'I' ,0);
         end % set.Resolution
         
         
         
         % ==========================================
         function [obj,isOK] = SetDecimation(obj,decimFactor)
             % sets decimation factor for each dimension
             % updates resolution parameter
             
             isOK = false;
             decimFactorTmp = decimFactor;
             
             % check XY
             decimFactorTmp(1:2) = max(1,min(16,round(decimFactor(1:2))));             
             if ~all(decimFactorTmp(1:2) == decimFactor(1:2)),
                 DTP_ManageText([], sprintf('XY Decimation factor is out of range [1:16] or non integer. Not set - Fix it.'), 'E' ,0);
                 return;
             end
             % check Z
             decimFactorTmp(3) = max(1,min(1,round(decimFactor(3))));             
             if ~all(decimFactorTmp(3) == decimFactor(3)),
                 DTP_ManageText([], sprintf('Z Decimation factor must be 1. Not set - Fix it.'), 'E' ,0);
                 return;
             end
             % check T
             decimFactorTmp(4) = max(1,min(16,round(decimFactor(4))));             
             if ~all(decimFactorTmp(4) == decimFactor(4)),
                 DTP_ManageText([], sprintf('T Decimation factor is out of range [1:16] or non integer. Not set - Fix it'), 'E' ,0);
                 return;
             end
             
             isOK                   = true;
             obj.DecimationFactor   = decimFactor;
             
             % update resolution
             [obj,isOK2]             = SetResolution(obj,obj.Resolution.*obj.DecimationFactor);
             isOK                   = isOK && isOK2;
             DTP_ManageText([], sprintf('Decimation is : %d-[X] %d-[Y] %d-[Z] %d-[T]',decimFactor), 'I' ,0);
         end % set.Decimation
         
         
        
        % ==========================================
        function obj = SelectElectroPhysData(obj,dirPath)
            % SelectElectroPhysData - determine data folders in the current
            % experiment
            % Input:
            %     dirPath - string path to the directory
            % Output:
            %     VideoFileNames - cell array of names of the files
        
        
            % check
            if ~exist(dirPath,'dir'),
                showTxt     = sprintf('Can not find directory %s',dirPath);
                DTP_ManageText([], showTxt, 'E' ,0)
                return
            end
            
            % add filter
            dirPathFilt     = fullfile(dirPath,obj.VideoDirFilter );
            
            
            % TSeries data is sitting in directories
            jdir            = dir(dirPathFilt);
            % filter ./.. directoris
            firstChar       = ''; for m = 1:length(jdir),firstChar(m) = jdir(m).name(1); end;
            validDirInd     = find([jdir.isdir] == 1 & (firstChar ~= '.')); % ignores files
            trialNum       = numel(validDirInd);
            if trialNum < 1,
                showTxt = sprintf('Can not find ElectroPhys directories in %s. Check the directory name.',dirPath);
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;
            
            
            % prob file number in each directory
            newDir           = fullfile(dirPath,jdir(validDirInd(1)).name);
            fileNames        = dir(fullfile(newDir,obj.VideoFilePattern));
            fileNum          = length(fileNames);
            if fileNum < 1,
                showTxt = sprintf('Can not find ElectroPhys TSeries files matching %s in the specified directory %s. Check the directory name or files.',obj.JaabaFilePattern,newDir);
                DTP_ManageText([], showTxt, 'E' ,0)   ;             
                return
            end;
            % allocate file names
            fileNamesC      = {}; %cell(trialNum,fileNum);
            
            % collect all 
            videoDirNames   = cell(trialNum,1);
            for m = 1:trialNum,  
                videoDirNames{m} = jdir(validDirInd(m)).name;
                newDir           = fullfile(dirPath,jdir(validDirInd(m)).name);
                fileNames        = dir(fullfile(newDir,obj.VideoFilePattern));
                fileNumNew       = length(fileNames);
                if fileNumNew < 1,
                    showTxt = sprintf('Can not find ElectroPhys TSeries files matching %s in the directory %s. Check the directory name or files.',obj.JaabaFilePattern,newDir);
                    DTP_ManageText([], showTxt, 'E' ,0)   ;             
                    continue
                end;
                
                validFileBool    = false(fileNumNew,1);               
                for k = 1:fileNumNew,
                    % TSeries may have ch1 files in the same directory - ignore them
                    if ~isempty(strfind(lower(fileNames(k).name),'ch1')),continue; end;
                    validFileBool(k) = true;
                end
                validFileInd     = find(validFileBool);
                validFileNum     = length(validFileInd);
                if validFileNum < 1,
                    showTxt = sprintf('Can not find ElectroPhys files ch2 in directory %s. Check the directory name or files.',newDir);
                    DTP_ManageText([], showTxt, 'E' ,0)   ;             
                    continue
                end;
                
                % check that it is compatible over all directories
                for k = 1:validFileNum,
                    fileNamesC{m,k} = fullfile(jdir(validDirInd(m)).name,fileNames(validFileInd(k)).name);
                end
            end
            trialNum                  = length(validDirInd);
            
            % output
            obj.VideoDir              = dirPath;
            obj.VideoDirNum           = trialNum;
            obj.VideoDirNames         = videoDirNames;
            obj.VideoFileNum          = trialNum;
            obj.VideoFileNames        = fileNamesC;
            
            
            DTP_ManageText([], sprintf('ElectroPhys : %d trial data has been read successfully.',trialNum), 'I' ,0)   ;             
        
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function [obj, recordData] = LoadElectroPhysData(obj,currTrial, figNum)
            % LoadTwoPhotonData - loads currTrial image data into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     recordData   - nT x chanNum - records loaded
            
            if nargin < 2, currTrial    = 1;    end;
            if nargin < 3, figNum       = 11;   end;
            
            recordData     = [];
            
            % there was an error during load
            if obj.VideoDirNum < 1,
                showTxt     = sprintf('ElectroPhys : Can not find directories.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end;
            if obj.VideoDirNum < currTrial,
                showTxt     = sprintf('ElectroPhys : Requested trial %d exceeds ElectroPhys directory content.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            dirPathTrial    = fullfile(obj.VideoDir,obj.VideoDirNames{currTrial});
            
            
            % load all by double call
            recordData       = DTP_LoadRecords(recordData, dirPathTrial, figNum);
            

                        
            % output
            recordTime      = recordData.recordNum*recordData.stimSampleTime;
            chanNum         = recordData.chanNum;
            DTP_ManageText([], sprintf('ElectroPhys : %5.3f sec data from trial %s is loaded successfully',recordTime, dirPathTrial), 'I' ,0)   ;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SelectAnalysisData(obj,dirPath)
            % SelectAnalysisData - loads user information (ROI) related to
            % image data 
            % Input:
            %     dirPath - string path to the directory
            % Output:
            %     EventFileNames - cell array of names of the files
            
            if nargin < 2, dirPath = pwd; end;
            
            % check
            if ~exist(dirPath,'dir'),
                
                isOK = mkdir(dirPath);
                if isOK,
                    showTxt     = sprintf('Can not find directory %s. Creating one...',dirPath);
                    DTP_ManageText([], showTxt, 'W' ,0)
                else
                    showTxt     = sprintf('Can not create directory %s. Problem with access or files are open, please resolve ...',dirPath);
                    DTP_ManageText([], showTxt, 'E' ,0)
                    return
                end

            end
            % save dir already
            obj.EventDir              = dirPath;
            
            
            % event file load
            fileNames        = dir(fullfile(dirPath,obj.EventFilePattern));
            fileNum          = length(fileNames);
            if fileNum < 1,
                showTxt = sprintf('Can not find data files *.mat in the directory %s : Check the directory name.',dirPath);
                DTP_ManageText([], showTxt, 'W' ,0)   ;             
                return
            end;
            [fileNamesC{1:fileNum,1}]   = deal(fileNames.name);
            
            % output
            obj.EventFileNum          = fileNum;
            obj.EventFileNames        = fileNamesC;
            
            DTP_ManageText([], 'ElectroPhys : Analysis data has been read successfully', 'I' ,0)   ;             
            
        end
        % ---------------------------------------------
        
       % ==========================================
        function [obj, fileName] = GetAnalysisFileName(obj,currTrial)
            % GetAnalysisFileName - converts tif file name to relevant mat file name
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     fileName   - analysis file name no path
            
            % take any active channel and strip off the name
            fileName = '';
            
            % take any active channel and strip off the name
            if obj.VideoFrontFileNum > 0,
                fileName        = obj.VideoFrontFileNames{currTrial} ;
                fileDescriptor  = 'front';
            elseif obj.VideoSideFileNum > 0,
                fileName        = obj.VideoSideFileNames{currTrial}  ;
                fileDescriptor  = 'side';
            else
                DTP_ManageText([], sprintf('ElectroPhys : Event : No video files. Need to load video first.'), 'E' ,0) ;
                return
            end
            
             % get prefix and siffix position : there is a directory name before
             pPos       = strfind(fileName,fileDescriptor) ;
             pPos       = pPos + length(fileDescriptor) + 1;
             sPos       = strfind(fileName,'.avi');
             experName  = fileName(pPos:sPos-1);

             % deal with crasy names like . inside
             experName   = regexprep(experName,'[\W+]','_');
             
             % switch in pattern * on new string
             fileName   = regexprep(obj.EventFilePattern,'*',experName);
                        
        end
        
        
        % ==========================================
        function [obj, usrData] = LoadAnalysisData(obj,currTrial, strName)
            % LoadAnalysisData - loads curr Trial user info data into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     usrData   - user structure information for specific trial
            %     strName   - StrROI, StrEvent - are subfields  
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, strName   = 'strEvent'; end;
            usrData = [];
            
            % check consistency
            if currTrial < 1, return; end
           
            % check file name 
            [obj, fileName] = GetAnalysisFileName(obj,currTrial); 
            
            %fileName        = obj.EventFileNames{currTrial};
            fileToLoad      = fullfile(obj.EventDir,fileName);
            
            % check
             if ~exist(fileToLoad,'file') || isempty(fileName), % strange bug exist with empty file returns 7 - directory
                showTxt     = sprintf('ElectroPhys : Analysis : No data found. Nothing is loaded.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
             end
             
             
            % mat file load
            usrData                         = load(fileToLoad);
%             usrData.StrROI      = tmpObj.StrROI;
             if strcmp(strName,'usrData'),
                 % the entire data is loaded
             elseif isfield(usrData,'strEvent') && strcmp(strName,'strEvent'),
                 usrData          = usrData.strEvent;
             else
                 error('Unknown parameter name %d',strName)
             end
            
            % output
            obj.Trial                      = currTrial;
            obj.EventFileNames{currTrial}  = fileName;
            obj.ValidTrialNum              = max(obj.ValidTrialNum,currTrial);
                
            DTP_ManageText([], sprintf('Analysis data from file %s has been loaded successfully',obj.EventFileNames{currTrial}), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, usrData] = SaveAnalysisData(obj,currTrial,strName,strVal)
            % SaveAnalysisData - save currTrial user info data to the
            % Analysis folder. Takes name from the corresponding Video files
            % Input:
            %     currTrial - integer that specifies trial to load
            %     strName    - name of the structure to save
            %     strVal     - actual structure data to save
            % Output:
            %     usrData   - user information for specific trial
            
            if nargin < 2, currTrial = 1; end;
            usrData = [];
            
            % check consistency
            if currTrial < 1, return; end
            if currTrial > obj.VideoFileNum,
                DTP_ManageText([], sprintf('ElectroPhys : Event : Requested trial exceeds video files. Nothing is saved.'), 'E' ,0) ;
                return
            end;
            if ~any(strcmp(strName,{'strEvent'})),
                DTP_ManageText([], sprintf('ElectroPhys : Event : Input structure name must be strEvent.'), 'E' ,0) ;
                  error(('ElectroPhys : Event : Input structure name must be strEvent.'))                
                return
            end
            
            % check file name 
            [obj, fileName] = GetAnalysisFileName(obj,currTrial); 
            
            fileToSave      = fullfile(obj.EventDir,fileName);
            
            % check
             if ~exist(fileToSave,'file')
                showTxt     = sprintf('ElectroPhys : Event - No data found. Creating a new file.');
                DTP_ManageText([], showTxt, 'W' ,0) ;
             else
                 % load old data
                 [obj, usrData] = LoadAnalysisData(obj,currTrial,'usrData');
             end
             
             % save
             obj.EventFileNames{currTrial}     = fileName;
             
             % ovveride the structure
             %usrData.(strName)                  = strVal;
             if strcmp(strName,'strEvent'),
                 usrData.strEvent         = strVal;
             else
                 error('Unknown parameter name %d',strName)
             end
             
            % file to save
            %save(fileToSave,'-struct','strEvent');
            save(fileToSave,'-struct','usrData');
                            
            DTP_ManageText([], sprintf('ElectroPhys : Event data from file %s has been saved',obj.EventFileNames{currTrial}), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
  
        
        % ==========================================
        function obj = SelectAllData(obj,dirPath)
            % SelectAllData - loads user all data according to the path
            % Assumes that directory structure is:
            %       .....\Imaging\AnimalName\Date\
            %       .....\Videos\AnimalName\Date\
            %       .....\Analysis\AnimalName\Date\
            % Input:
            %     dirPath - string path to the Imaging directory
            % Output:
            %     updated object 
            
            if nargin < 2, dirPath = pwd; end;
            
            % check
            if ~exist(dirPath,'dir'),
                showTxt     = sprintf('Can not find directory %s',dirPath);
                DTP_ManageText([], showTxt, 'E' ,0)
                return
            end
            % try to extract directory
            repKey     = 'kukuriku';
            dirPathKey = regexprep(dirPath,{'Videos','Imaging','Analysis'},repKey);  % replace it with key
            
            % check if replacement is done
            if strcmp(dirPathKey,dirPath),
                 DTP_ManageText([], 'Input path does not have Analysis/Videos or Imaging names. Can not extract path. Aborting', 'E' ,0)   ;   
                 return
            end;
            
            % do previous data clean
            obj           = obj.Clean();                        

            % replace and load
            tempDir       = regexprep(dirPathKey,repKey,'Imaging');
            obj           = obj.SelectElectroPhysData(tempDir);          
            
            tempDir       = regexprep(dirPathKey,repKey,'Analysis');
            obj           = obj.SelectAnalysisData(tempDir);
                        
            
            %DTP_ManageText([], 'All the data has been selected successfully', 'I' ,0)   ;             
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, vidData, usrData] = LoadAllData(obj,currTrial)
            % LoadAnalysisData - loads currTrial user info data into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            %     decimFact - integer that specifies decimation factor
            % Output:
            %     vidData - video data from 2 cameras
            %     usrData - user information for specific trial
            
            if nargin < 2,          currTrial = 1; end;
          
            [obj , vidData]          = obj.LoadElectroPhysData(currTrial,'all');
            [obj , usrData]          = obj.LoadAnalysisData(currTrial);
            
            
            %DTP_ManageText([], 'All the data has been read successfully', 'I' ,0)   ;             
            
        end
        % ---------------------------------------------
        

        % ==========================================
        function obj = RemoveRecord(obj,currTrial, removeWhat)
            % RemoveRecord - removes file reccord of currTrial from the list
            % Input:
            %     currTrial - integer that specifies trial to load
            %     removeWhat - integer that specifies which record to be removed : 1-Front,2-Side,4-Analysis,7 all
            % Output:
            %     obj        - with updated file list
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, removeWhat = 4; end
          
            if currTrial < 1, return; end;
%             if currTrial > obj.VideoFileNum,
%                 DTP_ManageText([], sprintf('Event \t: Requested trial exceeds video files. Nothing is deleted.'), 'E' ,0) ;
%                 return
%             end;
            isRemoved = false;

            % video
            if obj.VideoFrontFileNum > 0 && currTrial <= obj.VideoFrontFileNum && bitand(removeWhat,1)>0,
                obj.VideoFrontFileNames(currTrial) = [];
                obj.VideoFrontFileNum               = obj.VideoFrontFileNum - 1;
                isRemoved = true;
            end
            if obj.VideoSideFileNum > 0 && currTrial <= obj.VideoSideFileNum && bitand(removeWhat,2)>0,
                obj.VideoSideFileNames(currTrial)  = [];
                obj.VideoSideFileNum                = obj.VideoSideFileNum - 1;
                isRemoved = true;
            end
            if obj.VideoFrontFileNum > 0 || obj.VideoSideFileNum > 0,
                obj.VideoFileNum                    = obj.VideoFileNum - 1;
            end
            
            % analysis
            if obj.EventFileNum > 0 && currTrial <= obj.EventFileNum && bitand(removeWhat,4)>0,
                obj.EventFileNames(currTrial)         = [];
                obj.EventFileNum                       = obj.EventFileNum - 1;
                isRemoved = true;
            end
             
            if isRemoved,
                DTP_ManageText([], sprintf('ElectroPhys \t: Remove : Record %d is removed.',currTrial), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('ElectroPhys \t: Failed to remove record.'), 'I' ,0)   ;
            end;

            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function [obj, CheckOK] = CheckData(obj)
            % CheckData - checks image and user analysis data compatability
            % Input:
            %     none
            % Output:
            %     CheckOK - indicator of critical errors
            
            CheckOK     = true;
            imageNum    = obj.VideoFileNum;
            
            if obj.Trial < 1,
                obj.Trial       = 1;
                DTP_ManageText([], 'ElectroPhys : No trial is selected. Please select a trial or do new data load.', 'E' ,0)   ;
                
            end
            
            % video data with 1 camera compatability
            if obj.VideoFileNum < 1,
                DTP_ManageText([], 'ElectroPhys : Image ElectroPhys data is not found. Trying to continue.', 'W' ,0)   ;
            else
                imageNum = min(imageNum,obj.VideoDirNum);
                DTP_ManageText([], sprintf('ElectroPhys : Using video data from directory %s.',obj.VideoDirNames{obj.Trial}), 'I' ,0)   ;                
            end
            
            
            % user analysis data
            if obj.EventFileNum < 1,
                DTP_ManageText([], 'ElectroPhys : User analysis data is not found. Trying to continue.', 'W' ,0)   ;
                CheckOK = false;                
            else
                if obj.Trial <= length(obj.EventFileNames)
                    DTP_ManageText([], sprintf('ElectroPhys : Using analysis Event data from file %s.',obj.EventFileNames{obj.Trial} ), 'I' ,0)   ;
                end
                %imageNum = min(imageNum,obj.EventFileNum);
            end        
            
            if obj.VideoFileNum ~= obj.EventFileNum
                DTP_ManageText([], 'Bahavior : Video and Analysis file number missmatch.', 'W' ,0)   ;
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
            
            testVideoDir  = 'C:\LabUsers\Maria\5_6_13';
            obj           = obj.SelectElectroPhysData(testVideoDir,'ch1');
            
            testEventDir  = 'C:\UsersJ\Uri\Data\Analysis\Maria\5_6_13';
            obj           = obj.SelectAnalysisData(testEventDir);
            
            % check
            [obj,isOK]    = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TestSelect 1 OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestSelect 1 Fail.'), 'E' ,0)   ;
            end;
            
            % remove entry
            currTrial    = 1;
            obj           = obj.RemoveRecord(currTrial);
            
            % check
            [obj,isOK]    = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TestSelect 2 OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestSelect 2 Fail.'), 'E' ,0)   ;
            end;
            
            
         
        end
        % ---------------------------------------------
        % ==========================================
        function obj = TestElectroPhysLoad(obj)
            % TestLoad - given a directory loads full data
            testVideoDir   = 'C:\LabUsers\Uri\Data\Janelia\Imaging\Maria\5_6_13';
            tempTrial      = 3;
            figNum         = 100;
            
            
            % select data Load function
            obj           = obj.SelectElectroPhysData(testVideoDir);
            
            
            % load
            [obj, recStr] = obj.LoadElectroPhysData(tempTrial);

            
            % final
            [obj,isOK]                         = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TesttElectroPhysLoad OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TesttElectroPhysLoad Fail.'), 'E' ,0)   ;
            end;
            
            
                
            tt          = (1:recStr.recordNum)'*recStr.stimSampleTime;
            figure(figNum),set(gcf,'Tag','AnalysisROI')
            plot(tt, recStr.recordValue),
            hold on;
            stem(tt(recStr.frameStart),recStr.frameStart*0+3,'k')
            hold off;
            title('Electro Data')
            %xlabel('Sample number'),
            xlabel('Time [sec]'),
            ylabel('Channel [Volt]')
            chanName = recStr.chanName;
            chanName{recStr.chanNum+1} = 'Frame Start';
            legend(chanName)
            
         
        end
        % ---------------------------------------------
        
     
        % ==========================================
        function obj = TestLoad(obj)
            % TestLoad - given a directory loads full data
            testVideoDir    = 'C:\UsersJ\Uri\Data\Videos\m8\02_10_14';
            tempTrial      = 3;
            frameNum        = 100;
            
            
            % select again using Full Load function
            obj                         = obj.SelectAllData(testVideoDir);

            % load again using Full Load function
            [obj, vidData, usrData]     = obj.LoadAllData(tempTrial);
            
            % final
            [obj,isOK]                         = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TestLoad OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestLoad Fail.'), 'E' ,0)   ;
            end;
            
            % show
            if obj.VideoFrontFileNum > 0,   figure(2),imshow(squeeze(vidData(:,:,frameNum))); end;
         
        end
        % ---------------------------------------------
       
       
        % ==========================================
        function obj = TestLoadDecimation(obj)
            % TestLoadDecimation - given a directory loads full data
            % applies decimation to it
            testVideoDir  = 'C:\UsersJ\Uri\Data\Videos\m8\02_10_14\';
            tempTrial      = 3;
            frameNum        = 100;
            
            
            % select again using Full Load function
            obj                                 = obj.SelectAllData(testVideoDir);
            
            % set decimation factors
            decimFactor                         = obj.DecimationFactor;
            resolution                          = obj.Resolution;
            
            [obj,isOK]                          = obj.SetResolution(resolution*10); % just a check
            if ~isOK, 
                DTP_ManageText([], sprintf('Set Resolution fails but it is OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('Set Resolution pass but it should  Fail.'), 'E' ,0)   ;
            end;
            [obj,isOK]                          = obj.SetDecimation(decimFactor*2); % just a check
            if ~isOK, 
                DTP_ManageText([], sprintf('Set Decimation fails but it is OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('Set Decimation pass but it should  Fail.'), 'E' ,0)   ;
            end;
            [obj,isOK]                          = obj.SetDecimation([1 2 1 3]); % just a check
            if isOK, 
                DTP_ManageText([], sprintf('Set Decimation now is working OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('Set Decimation Fails.'), 'E' ,0)   ;
            end;
            

            % load again using Full Load function
            [obj, imgData, usrData]             = obj.LoadAllData(tempTrial);
            
            % final
            [obj,isOK]                         = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TestLoad OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestLoad Fail.'), 'E' ,0)   ;
            end;
            
            % show
            if obj.VideoFileNum > 0,       figure(1),imshow(squeeze(imgData(:,:,1,frameNum))); end;
         
        end
        % ---------------------------------------------
        
        
         
        % ==========================================
        function obj = TestAnalysis(obj)
            
            % Test4 - analysis data save and load
            
            testEventDir  = 'C:\UsersJ\Uri\Data\Analysis\m8\02_10_14';
            tempTrial     = 3;
           
            % select again using Full Load function
            %obj            = obj.SelectAnalysisData(testEventDir);
            obj            = obj.SelectAllData(testEventDir);
            

            % load data should fail
            [obj, usrData] = obj.LoadAnalysisData(tempTrial);
            if isempty(usrData), 
                DTP_ManageText([], sprintf('1 OK.'), 'I' ,0)   ;
            end;
            
            % write data to directory
            for m = 1:obj.VideoFileNum,
                StrEvent        = 10;
                tempTrial      = m;
            
                obj            = obj.SaveAnalysisData(tempTrial,'StrEvent',StrEvent);
                
            end
            
            [obj, usrData] = obj.LoadAnalysisData(tempTrial - 2);
            if ~isempty(usrData), 
                DTP_ManageText([], sprintf('2 OK.'), 'I' ,0)   ;
            end;
            
         
        end
        % ---------------------------------------------
        
        
    end% methods
end% classdef
