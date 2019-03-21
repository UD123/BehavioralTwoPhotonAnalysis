classdef TPA_DataManagerBehavior
    % TPA_DataManagerBehavior - Initializes/load Behavior directory structures and appropriate events
    % Responsible for data integrity and naming convention between Behavior Imaging , Event Analysis   
    % Analysis SW
    % Assumes that directory structure is:
    %       .....\Imaging\AnimalName\Date\
    %       .....\Videos\AnimalName\Date\
    %       .....\Analysis\AnimalName\Date\
    
    % Inputs:
    %       none
    % Outputs:
    %        directories updated
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 28.19 24.05.18 UD     Support mp4 and AvI
    % 28.18 16.05.18 UD     Adding actual frame rate
    % 28.17 29.04.18 UD     Import Video Labeler data.
    % 28.13 19.03.18 UD     Fixing offset.
    % 28.12 08.03.18 UD     Using offset to move the data in time.
    % 28.02 03.01.18 UD     Import events from Shahar .
    % 25.05 03.04.17 UD     Faster load
    % 24.05 16.08.16 UD     Resolution is not an integer.
    % 21.12 24.11.15 UD     Fix - Do not generate 2D matrix of Eventnames
    % 21.11 17.11.15 UD     Fixing names when no behave data
    % 21.10 10.11.15 UD     Remove with multi index
    % 21.03 25.08.15 UD     Bring GUI inside
    % 20.12 27.07.15 UD     Support video subset read
    % 20.05 19.05.15 UD     Video files only could be imported
    % 19.32 12.05.15 UD     Can import events without video files
    % 19.09 14.10.14 UD     Import Jaaba from external storage support
    % 19.06 21.09.14 UD     Import movie_comb.avi files.   Deal with names and Dir structures
    % 19.05 11.09.14 UD     Dump color info. File size equalization.   
    % 19.01 29.07.14 UD     Improve checking by dir structure re-read  
    % 18.10 08.07.14 UD     Only analysis data load support.  
    % 17.08 05.04.14 UD     adding clean  
    % 16.11 22.02.14 UD     analysis file name load fix
    % 16.07 20.02.14 UD     Adding resolution parameters
    % 16.04 17.02.14 UD     Adding decimation and splitting record remove
    % 16.03 16.02.14 UD     Split the Global manager on fractions
    % 16.01 15.02.14 UD     Updated to support single Behavior image. Adding JAABA support
    % 16.00 13.02.14 UD     Janelia Data integration
    %-----------------------------
    
    
    properties
        VideoDir                     = '';           % directory of the Front and Side view image Data
        EventDir                     = '';           % directory where the user Analysis data is stored
        VideoFrameRate               = 200;          % Behavioral Frame Rate Hz
       
        VideoFrontFileNum           = 0;             % number of trials (tiff movies) in Behavior/Front Dir
        VideoFrontFileNames         = {};            % front video file names in the Behavior directory
        VideoFrontSize              = [];            % data dimensions in a single trial
        VideoFrontFilePattern       = '*_front_*.avi';   % expected name for video pattern
        
        VideoSideFileNum            = 0;             % number of trials (tiff movies) in Behavior/Side Dir
        VideoSideFileNames          = {};            % side video file names in the Behavior directory
        VideoSideSize               = [];            % data dimensions in a single trial
        VideoSideFilePattern        = '*_side_*.avi';   % expected name for video pattern
        
        JaabaDirNum                 = 0;                % numer of Jaaba directories        
        JaabaDirFilter              = '*_*';               % helps to separate front/side directories
        JaabaVideoFilePattern       = 'movie_comb.avi';       % expected name for video pattern
        
        EventFileNum                = 0;                % numer of Analysis mat files
        EventFileNames              = {};               % file names of Analysis mat files
        EventFilePattern            = 'BDA_*.mat';      % expected name for analysis
        
%         % common info
         VideoFileNum               = 0;             % number of trials (avi movies) in Side or Front views
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
        function obj = TPA_DataManagerBehavior(varargin)
            % TPA_DataManagerBehavior - constructor
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
            obj.VideoFrontFileNum           = 0;             % number of trials (tiff movies) in Behavior/Front Dir
            obj.VideoFrontFileNames         = {};            % front video file names in the Behavior directory
            obj.VideoFrontSize              = [];            % data dimensions in a single trial
            obj.VideoFrontFilePattern       = '*_front_*.avi';   % expected name for video pattern
            obj.VideoSideFileNum            = 0;             % number of trials (tiff movies) in Behavior/Side Dir
            obj.VideoSideFileNames          = {};            % side video file names in the Behavior directory
            obj.VideoSideSize               = [];            % data dimensions in a single trial
            obj.VideoSideFilePattern        = '*_side_*.avi';   % expected name for video pattern
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
        function obj = RemoveEventData(obj)
            % RemoveEventData - deletes files on the disk and also cleans the relevant structures
            % Input:
            %
            % Output:
            %     -
            if isempty(obj.EventDir) || ~exist(obj.EventDir,'dir'),
                 DTP_ManageText([], sprintf('Behavior : Event directory is empty or does not exists.'), 'E' ,0);
                 return;
            end
            
            if obj.EventFileNum < 1,
                 DTP_ManageText([], sprintf('Behavior : No event data in directory %s.',obj.EventDir), 'W' ,0);
                 return;
            end
            
            for m = 1:obj.EventFileNum,
                
                fDirName                    = fullfile(obj.EventDir,obj.EventFileNames{m});
                delete(fDirName);
                
            end
            
            % clean up
            obj.EventFileNum                = 0;
            obj.EventFileNames              = {};
            
        end
        % ---------------------------------------------
        
         % ==========================================
         function [obj,isOK] = SetTrial(obj,trial)
             % sets trial and tests if it is OK
             
             isOK = false;
             
             if trial < 1 || trial > obj.ValidTrialNum,
                 DTP_ManageText([], sprintf('Behavior : Trial value %d is out of range. No action taken.',trial), 'E' ,0);
                 return;
             end
             isOK       = true;
             obj.Trial = trial;
         end % set.Trial
        % ---------------------------------------------
       
        % ==========================================
         function [obj,isOK] = SetSliceNum(obj,sliceNum)
             % how many slices to split
%              if obj.VideoFileNum < 1,
%                  DTP_ManageText([], sprintf('No video data found. May be you need to load your video files.'), 'E' ,0);
%                  return;
%              end
             isOK                   = true;
             obj.SliceNum = sliceNum;
             DTP_ManageText([], sprintf('Slice Number is : %d',sliceNum), 'I' ,0);
             
         end
        % ---------------------------------------------
         
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
             resolValuesTmp(4) = max(1,min(1000,resolValues(4)));             
             if ~all(resolValuesTmp(4) == resolValues(4)),
                 DTP_ManageText([], sprintf('T Frame Rate is out of range [1:1000]. Not set - Fix it'), 'E' ,0);
                 return;
             end
             
             isOK             = true;
             obj.Resolution   = resolValues;
             DTP_ManageText([], sprintf('Resolution is : %d [um/pix] %d [um/pix] %d [um/frame] %d [frame/sec]',resolValues), 'I' ,0);
         end % set.Resolution
        % ---------------------------------------------
         
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
        % ---------------------------------------------
         
         % ==========================================
         function [obj,isOK] = SetOffset(obj,offsetParams)
             % sets offset parameter
             
             isOK = false;
             
             % check
             if numel(offsetParams) ~= 4
                 errordlg('Offset must be a 4 value vector'); return
             end
             
             %  minus sign for direction of motion
             offsetParams(4)    = -offsetParams(4);
             offsetTmp          = offsetParams;
             
             % check offset.
             offsetTmp(4) = max(-400,min(400,round(offsetParams(4))));             
             if ~all(offsetTmp(4) == offsetParams(4))
                 DTP_ManageText([], sprintf('The Offset factor is out of range [-400:400] or non integer. Not set - Fix it'), 'E' ,0);
                 return;
             end
             
             isOK                   = true;
             obj.Offset             = offsetParams;
             
             DTP_ManageText([], sprintf('Offset is : %d-[X] %d-[Y] %d-[Z] %d-[T]',offsetParams), 'I' ,0);
         end % SetOffset
        % ---------------------------------------------
        
        % ==========================================
        function obj = SelectJaabaDir(obj,dirPath)
            % SelectJaabaDir - loads Jaaba video file names
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
            % allocate file names
            fileNamesV      = cell(trialNum,1); % video files
            
            % collect all -
            for m = 1:trialNum,  
                newDir              = fullfile(dirPath,jdir(validDirInd(m)).name);
                
                % bring movies
                fileNames           = dir(fullfile(newDir,obj.JaabaVideoFilePattern));
                fileNumVideo        = length(fileNames);
                if fileNumVideo < 1,
                    showTxt = sprintf('Can not find movie files matching %s in the directory %s. Check the directory name or files.',obj.JaabaVideoFilePattern,newDir);
                    DTP_ManageText([], showTxt, 'E' ,0)   ;             
                    continue
                end;   
                fileNamesV{m}       = fullfile(jdir(validDirInd(m)).name,fileNames(1).name);
                
            end
            
            % valid number
            emptyDir                  = cellfun(@isempty, fileNamesV);
            trialNum                  = sum(~emptyDir);
            fileNamesV                = fileNamesV(~emptyDir);
            
            
            % output
            obj.VideoFrontFileNum   = trialNum;
            obj.VideoFrontFileNames = fileNamesV;
            obj.VideoSideFileNum    = trialNum;
            obj.VideoSideFileNames  = fileNamesV;
            obj.VideoFileNum        = trialNum;
            obj.ValidTrialNum       = trialNum;
            obj.VideoDir            = dirPath;
            obj.JaabaDirNum         = trialNum;  % designates that data is comb
            
            % estimate total video frames
            DTP_ManageText([], sprintf('Behavior : movie_comb.avi data in %d directories is found',trialNum), 'I' ,0);             
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SelectBehaviorData(obj,dirPath,fileDescriptor)
            % SelectBehaviorData - video image data files from Left and Forward cameras
            % Input:
            %     dirPath - string path to the directory
            %     fileDescriptor - string that could be 'side' or 'front' or 'all' 
            % Output:
            %     BehaviorFileNames - cell array of names of the files
            
            if nargin < 2, dirPath        = pwd; end;
            if nargin < 3, fileDescriptor = 'comb'; end;
            
            % check
            if ~exist(dirPath,'dir'),
                showTxt = sprintf('Can not find directory %s',dirPath);
                DTP_ManageText([], showTxt, 'E' ,0)  ;              
                return
            end
            fileDescriptor = lower(fileDescriptor);
            if ~any(strcmp(fileDescriptor,{'side','front','all','comb'})),
                showTxt = sprintf('File Descriptor should be ''side'' or ''front'' or ''comb'' %s',fileDescriptor);
                DTP_ManageText([], showTxt, 'E' ,0);                
                return
            end
            
            % load all by double call
            if strcmp(fileDescriptor,'all')
                % try Jaaba dir strcture
                obj = SelectJaabaDir(obj,dirPath);
                if obj.JaabaDirNum > 0, return; end;
                % try each file separately
                obj = SelectBehaviorData(obj,dirPath,'side');
                obj = SelectBehaviorData(obj,dirPath,'front');
                return
            elseif strcmp(fileDescriptor,'comb')
                obj = SelectJaabaDir(obj,dirPath);
                return
            end
            
            % forward avi file load
            filePattern      = ['*',fileDescriptor,'*.mp4'];
            fileNames        = dir(fullfile(dirPath,filePattern));
            fileNum          = length(fileNames);
            if fileNum < 1
                showTxt = sprintf('Can not find file pattern %s in the directory %s. Check the directory name.',filePattern,dirPath);
                DTP_ManageText([], showTxt, 'W' ,0) ;     
                % avi
                filePattern      = ['*',fileDescriptor,'*.avi'];
                fileNames        = dir(fullfile(dirPath,filePattern));
                fileNum          = length(fileNames);
                if fileNum < 1
                    showTxt = sprintf('Can not find file pattern %s in the directory %s. Check the directory name.',filePattern,dirPath);
                    DTP_ManageText([], showTxt, 'W' ,0) ;               
                    return
                end
            end
            
            [fileNamesC{1:fileNum,1}] = deal(fileNames.name);
            
            % output
            obj.VideoDir              = dirPath;
            
            if strcmp(fileDescriptor,'front')
                obj.VideoFrontFileNum   = fileNum;
                obj.VideoFrontFileNames = fileNamesC;
            else
                obj.VideoSideFileNum   = fileNum;
                obj.VideoSideFileNames = fileNamesC;
            end
            
            % estimate total video frames
            if obj.VideoFrontFileNum >= 1 && obj.VideoSideFileNum < 1
                obj.VideoFileNum = obj.VideoFrontFileNum;
            elseif obj.VideoFrontFileNum < 1 && obj.VideoSideFileNum >= 1
                obj.VideoFileNum = obj.VideoSideFileNum;
            else
                obj.VideoFileNum = min(obj.VideoFrontFileNum,obj.VideoSideFileNum);
            end

            
            DTP_ManageText([], sprintf('Behavior : %s data structure with %d files has been detected',fileDescriptor,obj.VideoFileNum), 'I' ,0);             
            
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, imgData] = LoadBehaviorData(obj,currTrial, fileDescriptor, imageIndx)
            % LoadTwoPhotonData - loads currTrial image data into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            %     fileDescriptor - string that could be 'side' / 'front' or 'all' or 'comb'
            % Output:
            %     imgData   - 3D array image data when 3'd dim is a channel front or side
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, fileDescriptor = 'side'; end;
            if nargin < 4, imageIndx = [0 Inf]; end;
            
            imgData = [];
            
            % load all by double call
            if strcmp(fileDescriptor,'all')
                
                % check Jaaba
                if obj.JaabaDirNum > 0
                    % the same movie contains both front and side - bring it like a side
                    [obj, imgDataS]         = LoadBehaviorData(obj,currTrial,'side');
                    % second dimension has two frames stacked - combine them differently
                    colNum                  = ceil(obj.VideoSideSize(2)/2);
                    imgData                 = cat(3,imgDataS(:,1:colNum,:,:), imgDataS(:,1+colNum:2*colNum,:,:));
                    obj.VideoFrontSize      = obj.VideoSideSize;
                    obj.VideoFrontFileNames = obj.VideoSideFileNames;
                    return
                end
                
                [obj, imgDataS] = LoadBehaviorData(obj,currTrial,'side');
                [obj, imgDataF] = LoadBehaviorData(obj,currTrial,'front');
                if obj.VideoSideFileNum > 0 && obj.VideoFrontFileNum > 0,
                    % check the equal size
                    minFrameNum    = min(size(imgDataS,4),size(imgDataF,4));
                    imgData        = cat(3,imgDataS(:,:,:,1:minFrameNum), imgDataF(:,:,:,1:minFrameNum));
                elseif obj.VideoSideFileNum > 0,
                    imgData        = imgDataS;
                elseif obj.VideoFrontFileNum > 0,
                    imgData        = imgDataF;
                end   
                return
            %elseif strcmp(fileDescriptor,'comb')
            end
            
            
            % select
            if strcmp(fileDescriptor,'front')
                fileNamesC = obj.VideoFrontFileNames ;
                fileNum    = obj.VideoFrontFileNum;
            else
                fileNamesC = obj.VideoSideFileNames  ;
                fileNum    = obj.VideoSideFileNum;
            end
            
            
            % check
             if fileNum < 1
                showTxt     = sprintf('Behavior : No data found. Aborting');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
             end
            if currTrial < 1 || currTrial > fileNum,
                showTxt     = sprintf('Behavior : Trial is out of range %s. Loading trial 1.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0)
                currTrial = 1;
            end
            fileDescriptor = lower(fileDescriptor);
            if ~any(strcmp(fileDescriptor,{'side','front'})),
                showTxt = sprintf('File Descriptor should be ''side'' or ''front'' %s',fileDescriptor);
                DTP_ManageText([], showTxt, 'E' ,0);                
                return
            end
            
            % avi file load
            fileDirName         = fullfile(obj.VideoDir,fileNamesC{currTrial});
            if ~exist(fileDirName,'file')
                DTP_ManageText([], sprintf('Behavior : Can not locate file %s. Please check.',fileDirName), 'E' ,0)   ;  
                return
            else
                % inform
                DTP_ManageText([], sprintf('Behavior : Loading data from file %s. Please Wait ...',fileNamesC{currTrial}), 'I' ,0)   ;             
            end
            
            
            %readObj             = VideoReader(fileDirName);
            if verLessThan('matlab', '8.1.0')
                readObj             = mmreader(fileDirName);
                numFrames           = readObj.NumberOfFrames;
            else
%                readObj             = vision.VideoFileReader(fileDirName);
%                 readObj             = VideoReader(fileDirName);
%                 lastFrame           = read(readObj, inf); % variable frame rate
%                 numFrames           = readObj.NumberOfFrames; 
            end       
            
%             % check image index
%             imageIndx           = max(1,min(numFrames,imageIndx));
%             % read only the relevant indexes - VERY SLOW
%             imgData             = read(readObj,imageIndx);
            
%             % read only the relevant indexes
%             numFrames           = floor(readObj.Duration*readObj.FrameRate);
%             imgData             = repmat(uint8(0),[readObj.Height readObj.Width numFrames]); 
%             k = 1;
%             while hasFrame(readObj)
%                 imgData(:,:,k) = readFrame(readObj);
%                 k = k + 1;
%             end            
            
            readObj             = vision.VideoFileReader(fileDirName,'ImageColorSpace','Intensity');
            % advance to the start
            startFrameIndx      = max(1,imageIndx(1));
            stopFrameIndx       = min(2500,imageIndx(2));
            k                   = 0;
            while ~isDone(readObj) && k < startFrameIndx,
              videoFrame = step(readObj); k = k + 1;
            end
            frameNum            = stopFrameIndx - startFrameIndx;
            imgData             = repmat(videoFrame,[1 1 1 frameNum]);
            k                   = 1;
            while ~isDone(readObj) && k < frameNum,
              videoFrame = step(readObj); k = k + 1;
              if size(imgData,4) < k, 
                  imgData    = cat(4,imgData,repmat(videoFrame,[1 1 1 100])); % extend
              end
              imgData(:,:,:,k)    = videoFrame;
            end
            imageIndx       = max(1,min(k,imageIndx));
            imgData         = imgData(:,:,:,imageIndx(1):imageIndx(2));
            release(readObj);

            % check decimation
            if any(obj.DecimationFactor > 1),
                DTP_ManageText([], sprintf('Behavior : data from file %s is decimated. Check decimation factors ',fileNamesC{currTrial}), 'W' ,0)   ;  
                % indexing
                sz              = size(imgData);
                imgData         = imgData(1:obj.DecimationFactor(2):sz(1),1:obj.DecimationFactor(1):sz(2),1:1:sz(3),1:obj.DecimationFactor(4):sz(4));                

%                 
%                 [y,x,z,t]       = ndgrid((1:obj.DecimationFactor(2):sz(1)),(1:obj.DecimationFactor(1):sz(2)),(1:1:sz(3)),(1:obj.DecimationFactor(4):sz(4)));
%                 ii              = sub2ind(sz,y(:),x(:),z(:),t(:));  
%                 %imgData         = reshape(imgData(ii),ceil(sz./[obj.DecimationFactor obj.DecimationFactor 1 1]));                
%                 imgData         = reshape(imgData(ii),ceil(sz./obj.DecimationFactor));                
            end
            imgSize             = size(imgData);
            
            % check if there is a color
            if imgSize(3) > 1,
                imgData             = imgData(:,:,1,:);
                DTP_ManageText([], sprintf('Behavior : Assuming that the input data has no colors. Using the first color channel '), 'W' ,0)   ;  
            end
            
                        
            % output
            obj.Trial          = currTrial;
            if strcmp(fileDescriptor,'front'),
            obj.VideoFrontSize  = imgSize;
            else
            obj.VideoSideSize   = imgSize;
            end
            
            DTP_ManageText([], sprintf('Behavior : %d images from file %s are loaded successfully',imgSize(4),fileNamesC{currTrial}), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SaveBehaviorData(obj,currTrial,fileDescriptor,imgData)
            % SaveBehaviorData - saves image data to avi file using compression
            % Input:
            %     currTrial  - which trial it was
            % fileDescriptor - side or front
            %     imgData  - 4D array image data
            % Output:
            %     result   - file saved
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, fileDescriptor = 'front'; end;
            if nargin < 4, imgData = 1; end;
            [nR,nC,nZ,nT] = size(imgData);
            
            % select
            if strcmp(fileDescriptor,'front')
                fileNamesC = obj.VideoFrontFileNames ;
            else
                fileNamesC = obj.VideoSideFileNames  ;
            end
            
            
            % check
            if obj.VideoFileNum < 1
                showTxt     = sprintf('Behavior : No data found. Could be a problem with directory or experiment file tree.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            if currTrial < 1 || currTrial > obj.VideoFileNum,
                showTxt     = sprintf('Behavior : Trial is out of range %d. Aborting.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0)
                return;
            end
            if nZ > 1,
                showTxt     = sprintf('Behavior : Found %d Z stacks. Saving only first.',nZ);
                DTP_ManageText([], showTxt, 'W' ,0)
                nZ = 1;
            end
            
            % squueze one dimension - 4D array required
            %imgData             = squeeze(imgData(:,:,nZ,:));
            % inform
            DTP_ManageText([], sprintf('Behavior : Writing data to file %s. Please Wait ...',fileNamesC{currTrial}), 'I' ,0)   ;             
            
            % inform
            % avi file load
            fileDirName         = fullfile(obj.VideoDir,fileNamesC{currTrial});
            %if exist(fileDirName,'file'),delete(fileDirName); end;
            if verLessThan('matlab', '8.1.0')
                errordlg('Write AVI files on this Matlab version is not supported. At least 2013a.');
                return
            else
                writeObj             = VideoWriter(fileDirName); % motion JPEG
                %writeObj.CompressionRatio = 100;
                open(writeObj);
                writeVideo(writeObj, imgData);
                close(writeObj)
           end            
            
            
            % output
            DTP_ManageText([], sprintf('Behavior : Data compression is Done'), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = CheckImageData(obj,imgData)
            % CheckImageData - checks if there are drop frames and sync between channels
            % Input:
            %     imgData - 4-D image files
            % Output:
            %     print 
        
            [nR,nC,nZ,nT]   = size(imgData);
            
            if nT < 2,
                showTxt     = sprintf('Behavior : Image data is not valid. Do you need to load it first?');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            % detect motion in time
            motionLine      = zeros(nZ,nT);
            for z = 1:nZ,
                motionLine(z,3:nT)  = squeeze(mean(mean(abs(imgData(:,:,z,1:nT-2) - imgData(:,:,z,3:nT)),1),2));
            end
            
            % detrmine if there are trailing zeros (difference 10 in 30 pixels at least)
            motionThr       = 10*30/(nR*nC);
            motionDetect    = zeros(nZ,nT);
            dropFrameThr    = 3;
            for z = 1:nZ,
                motionDetect(z,:)  = motionLine(z,:) < motionThr; 
                motionDetect(z,:)  = filter(ones(1,dropFrameThr),1,motionDetect(z,:));
                indDrops           = find(motionDetect(z,:) == dropFrameThr);
                numDrops           = numel(indDrops);
                if numDrops < 1,
                    DTP_ManageText([], sprintf('Behavior : Channel %d : Drop frames analysis - no droped frames found',z), 'I' ,0) ;
                elseif 1 <= numDrops && numDrops < 10,
                    DTP_ManageText([], sprintf('Behavior : Channel %d : Drop frames found. Show frame Indixes',z), 'W' ,0) ;
                    disp(indDrops)
                else
                    DTP_ManageText([], sprintf('Behavior : Channel %d : Many frames found. Check you data.',z), 'E' ,0) ;
                end
                
            end
            
           
            figure(102),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
            plot(1:nT, motionLine'); hold on;
            plot(1:nT, motionDetect',':'); hold off;
            title('Behavior Motion Analysis'), axis tight;
            xlabel('Frame [#]'), ylabel('Average motion between frames')
            lbl = {'side','front'};
            legend(lbl{1:nZ});
            
            
           
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = CompressBehaviorData(obj,trialInd, fileDescriptor)
            % CompressBehaviorData - loads behavior image data and applyes compression
            % Input:
            %     trialInd - file numbers in directory
            % Output:
            %     files changed in the directory 
        
            validInd    = 1 <= trialInd  & trialInd <= obj.VideoFileNum;
            trialInd    = trialInd(validInd);
            fileNum     = length(trialInd);
            
            if fileNum < 1,
                showTxt     = sprintf('Behavior : trial index is not correct. Aborting');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            for k = 1:fileNum,
                currTrial       = trialInd(k);
                fileDescriptor  = 'front';
                [obj, imgData]  = LoadBehaviorData(obj,currTrial, fileDescriptor) ;
                obj             = SaveBehaviorData(obj,currTrial, fileDescriptor, imgData);                
                fileDescriptor  = 'side';
                [obj, imgData]  = LoadBehaviorData(obj,currTrial, fileDescriptor) ;
                obj             = SaveBehaviorData(obj,currTrial, fileDescriptor, imgData);                
            end
           
        
            DTP_ManageText([], sprintf('Behavior : Compression finished successfully'), 'I' ,0)   ;             
        end
        % ---------------------------------------------
       
        
    end
    % Analysis
    methods
        
        % ==========================================
        function obj = SelectAnalysisData(obj,dirPath)
            % SelectAnalysisData - loads user information (ROI) related to
            % image data 
            % Input:
            %     dirPath - string path to the directory
            % Output:
            %     EventFileNames - cell array of names of the files
            
            if nargin < 2, dirPath = pwd; end;
            
            if isempty(dirPath), 
                DTP_ManageText([], 'Behavior :  Path is not specified', 'E' ,0)
                return; 
            end;
            
            % check
            if ~exist(dirPath,'dir'),
                
                isOK = mkdir(dirPath);
                if isOK,
                    showTxt     = sprintf('Behavior : Can not find directory %s. Creating one...',dirPath);
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
            
            DTP_ManageText([], 'Behavior : Analysis data has been read successfully', 'I' ,0)   ;             
            
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
            
                        
            % check if the analysis has been done before
            if obj.EventFileNum > 0 && obj.EventFileNum >= currTrial,
                if ~isempty(obj.EventFileNames{currTrial}),
                    fileName        = obj.EventFileNames{currTrial} ;
                    return
                end
            else
                %DTP_ManageText([], sprintf('Behavior \t: No Event file name are found. Trying to determine them from Video data.'), 'W' ,0) ;
            end
            
            
            % take any active channel and strip off the name
            if obj.VideoFrontFileNum > 0,
                fileName        = obj.VideoFrontFileNames{currTrial} ;
                fileDescriptor  = 'front';
            elseif obj.VideoSideFileNum > 0,
                fileName        = obj.VideoSideFileNames{currTrial}  ;
                fileDescriptor  = 'side';
            else
                DTP_ManageText([], sprintf('Behavior : Event : No video files. Need to load video first.'), 'E' ,0) ;
                fileName        = sprintf('front_%03d',currTrial) ;
                fileDescriptor  = 'front';
            end
            
             % get prefix and siffix position : there is a directory name before
            if obj.JaabaDirNum > 0
               experName    = fileparts(obj.VideoFrontFileNames{currTrial});
            else
                 pPos       = strfind(fileName,fileDescriptor) ;
                 pPos       = pPos + length(fileDescriptor) + 1;
                 sPos       = strfind(fileName,'.avi');
                 experName  = fileName(pPos:sPos-1);
            end

             % deal with crasy names like . inside
             experName   = regexprep(experName,'[\W+]','_');
             
             % switch in pattern * on new string
             fileName   = regexprep(obj.EventFilePattern,'*',experName);
                        
        end
        % ---------------------------------------------
        
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
                showTxt     = sprintf('Behavior : Analysis : No data found. Nothing is loaded.');
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
                 DTP_ManageText([],sprintf('Behavior : No data in File %s',fileName),'W');
                 return
             end
            
            % output
            obj.Trial                      = currTrial;
            obj.EventFileNames{currTrial}  = fileName;
            obj.ValidTrialNum              = max(obj.ValidTrialNum,currTrial);
                
            DTP_ManageText([], sprintf('Behavior : Analysis data from file %s has been loaded successfully',obj.EventFileNames{currTrial}), 'I' ,0)   ;             
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
                DTP_ManageText([], sprintf('Behavior : Event : Requested trial exceeds video files. '), 'E' ,0) ;
                %return
            end;
            if ~any(strcmp(strName,{'strEvent'})),
                DTP_ManageText([], sprintf('Behavior : Event : Input structure name must be strEvent.'), 'E' ,0) ;
                  error(('Behavior : Event : Input structure name must be strEvent.'))                
                return
            end
            
            % check file name 
            [obj, fileName] = GetAnalysisFileName(obj,currTrial); 
            
            fileToSave      = fullfile(obj.EventDir,fileName);
            
            % check
             if ~exist(fileToSave,'file')
                showTxt     = sprintf('Behavior : Event - No data found. Creating a new file.');
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
                            
            DTP_ManageText([], sprintf('Behavior : Event data saved to file %s ',fileToSave), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SelectAllData(obj,dirPath,fileDescriptor)
            % SelectAllData - loads user all data according to the path
            % Assumes that directory structure is:
            %       .....\Imaging\AnimalName\Date\
            %       .....\Videos\AnimalName\Date\
            %       .....\Analysis\AnimalName\Date\
            % Input:
            %     dirPath - string path to the Imaging directory
             %     fileDescriptor - string that could be 'comb' or 'all' 
            % Output:
            %     updated object 
            
            if nargin < 2, dirPath        = pwd; end;
            if nargin < 3, fileDescriptor = 'all'; end;
            
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
            tempDir       = regexprep(dirPathKey,repKey,'Videos');
            obj           = obj.SelectBehaviorData(tempDir,fileDescriptor);          
            
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
          
            [obj , vidData]          = obj.LoadBehaviorData(currTrial,'all');
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
          
            if any(currTrial < 1), 
                DTP_ManageText([], sprintf('Event \t: index error.'), 'E' ,0)
                return; 
            end;
%             if currTrial > obj.VideoFileNum,
%                 DTP_ManageText([], sprintf('Event \t: Requested trial exceeds video files. Nothing is deleted.'), 'E' ,0) ;
%                 return
%             end;
            isRemoved = false;
            fileNumRemove   = numel(currTrial);

            % video
            if obj.VideoFrontFileNum > 0 && all(currTrial <= obj.VideoFrontFileNum) && bitand(removeWhat,1)>0,
                obj.VideoFrontFileNames(currTrial) = [];
                obj.VideoFrontFileNum               = obj.VideoFrontFileNum - fileNumRemove;
                isRemoved = true;
            end
            if obj.VideoSideFileNum > 0 && all(currTrial <= obj.VideoSideFileNum) && bitand(removeWhat,2)>0,
                obj.VideoSideFileNames(currTrial)  = [];
                obj.VideoSideFileNum                = obj.VideoSideFileNum - fileNumRemove;
                isRemoved = true;
            end
            if obj.VideoFrontFileNum > 0 || obj.VideoSideFileNum > 0,
                obj.VideoFileNum                    = obj.VideoFileNum - fileNumRemove;
            end
            
            % analysis
            if obj.EventFileNum > 0 && all(currTrial <= obj.EventFileNum) && bitand(removeWhat,4)>0,
                obj.EventFileNames(currTrial)         = [];
                obj.EventFileNum                       = obj.EventFileNum - fileNumRemove;
                isRemoved = true;
            end
             
            if isRemoved,
                DTP_ManageText([], sprintf('Behavior \t: Remove : Record %d is removed.',currTrial), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('Behavior \t: Failed to remove record.'), 'I' ,0)   ;
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
                DTP_ManageText([], 'Behavior : No trial is selected. Please select a trial or do new data load.', 'W' ,0)   ;
            end
            
            % reread
            obj             = SelectBehaviorData(obj,obj.VideoDir,'all');
            
            % video data with 1 camera compatability
            if obj.VideoFrontFileNum < 1,
                DTP_ManageText([], 'Behavior : Front Behavior data is not found. Trying to continue.', 'W' ,0)   ;
            else
                imageNum = min(imageNum,obj.VideoFrontFileNum);
                DTP_ManageText([], sprintf('Behavior : Using Front video data from file %s.',obj.VideoFrontFileNames{obj.Trial}), 'I' ,0)   ;                
            end
            
            if obj.VideoSideFileNum < 1,
                if obj.VideoFrontFileNum < 1,
                    DTP_ManageText([], 'Behavior : Side & Front Behavior data are not found. Trying to continue - must be loaded.', 'E' ,0)   ;
                    CheckOK = false;
                end
                DTP_ManageText([], 'Behavior : Side Behavior data is not found. Trying to continue.', 'W' ,0)   ;
            else
                if obj.VideoSideFileNum ~= obj.VideoFrontFileNum,
                    DTP_ManageText([], 'Behavior : Front and Side Behavior data differ in size. Trying to continue.', 'W' ,0)   ;
                end
                imageNum = min(imageNum,obj.VideoSideFileNum);
                DTP_ManageText([], sprintf('Behavior : Using Side video data from file %s.',obj.VideoSideFileNames{obj.Trial}), 'I' ,0)   ;                
                
            end
            
            % user analysis data
            % reread dir structure
            obj             = SelectAnalysisData(obj,obj.EventDir);            
            
            if obj.EventFileNum < 1,
                DTP_ManageText([], 'Behavior : User analysis data is not found. Trying to continue.', 'W' ,0)   ;
                CheckOK = false;                
            else
                if obj.Trial <= length(obj.EventFileNames)
                    DTP_ManageText([], sprintf('Behavior : Using analysis Event data from file %s.',obj.EventFileNames{obj.Trial} ), 'I' ,0)   ;
                end
                %imageNum = min(imageNum,obj.EventFileNum);
            end        
            
            if obj.VideoFileNum ~= obj.EventFileNum
                DTP_ManageText([], 'Bahavior : Video and Analysis file number missmatch.', 'W' ,0)   ;
                % use only event data
                %imageNum = obj.EventFileNum;
            end
            
            
            % summary
            DTP_ManageText([], sprintf('Bahavior : Check status %d : Found %d valid trials.',CheckOK,imageNum), 'I' ,0)   ;
            
            
            % output
            obj.ValidTrialNum           = imageNum;
            obj.Trial                   = 1;
            
        end
                
        % ==========================================
        function obj = ImportLeverPressData(obj,dirPath)
            % ImportLeverPressData - imports lever press events into the 
            % Input:
            %     dirPath       - string path to the directory
            % Output:
            %     BDA files   - cell array of dir of the files
            
            if nargin < 2, dirPath = pwd; end
 
            % do load and convert
           % obj             = SelectAllData(obj,dirPath);
            
            
            % Ask about event data
            doMerge = false;
            if obj.EventFileNum > 0
            buttonName = questdlg('Previous Behavioral Event data is found. Would you like?', 'Warning','Cancel','Merge','Overwrite','Cancel');
            if strcmp(buttonName,'Cancel'), return; end
            % check if merge is required
            doMerge = strcmp(buttonName,'Merge');
            end
            
            
            for trialInd = 1:obj.VideoFrontFileNum

                fileName        = obj.VideoFrontFileNames{trialInd,1};
                fileName        = strrep(fileName,'_front_','_time_');
                [p,fileName,~]    = fileparts(fileName);         
                fileDirName     = fullfile(obj.VideoDir,[fileName,'.mat']);
                if ~exist(fileDirName,'file')
                    DTP_ManageText([], sprintf('Bahavior : Can not find file %s.',fileDirName), 'W' ,0); continue;
                end
                try
                    s           = load(fileDirName);
                    timeBuffer  = s.timeBuffer;
                catch me
                    errordlg(me.message);
                    return
                end
                strEventNew             = TPA_EventManager();
                % start and duration
                strEventNew.tInd        = [timeBuffer(:) timeBuffer(:)+30];
                strEventNew.Name        = 'LeverPress';
                
                [obj,strEvent]          = LoadAnalysisData(obj,trialInd,'strEvent');
                
                if doMerge
                    strEvent{end+1}    = strEventNew; %cat(1,strEventOld{:},strEventNew);
                else
                    strEvent           = {strEventNew};
                end
                obj                    = SaveAnalysisData(obj,trialInd,'strEvent',strEvent);

            end
            
            
        end        
                
        % ==========================================
        function obj = ImportVideoLabelerROI(obj,sessionDir)
            % ImportVideoLabelerROI - imports video labeler ROIs 
            % Input:
            %     sessionDir       - session dir name
            % Output:
            %     BDA files   - cell array of dir of the files
            
            if nargin < 2, sessionDir = []; end
 
            % -------------------------------------------------
            % select session file
            if isempty(sessionDir), sessionDir = '..\TwoPhotonData'; end
            [sessionFileName,sessionFilePath,~] = uigetfile('.mat','Session',sessionDir);
            % If session was selected
            if isequal(sessionFileName,0), return; end
            groundTruthSession    = load(fullfile(sessionFilePath,sessionFileName));
            % Check if selected .MAT file session is valid
            if ~isfield(groundTruthSession,'GTS')
                errordlg('Specified .MAT file is not a Ground Truth Session. Please specify a valid Ground Truth Session.','Invalid Ground Truth Session');
            end
            % if the session is not empty
            mediaNum     = length(groundTruthSession.GTS.MediaInfo);
            if mediaNum < 1
                errordlg('The session file has no Media Info.','Empty Ground Truth Session');
            end
            if mediaNum ~= obj.VideoFrontFileNum
                errordlg('The session file has media file number different from loaded files .','File Missmatch Session');
            end
            roiNum     = length(groundTruthSession.GTS.RoiInfo);
            if roiNum < 1
                errordlg('The session has no ROI labels.','Non Valid Ground Truth Session');
            end
           
           % ----------------------------------------------------
           % extract media files and compare to the current set of filees
           fileString   = cell(mediaNum,1);
           for idx = 1:mediaNum
                [p,FileName,FileExt] = fileparts(groundTruthSession.GTS.MediaInfo(idx).FileName);
                if startsWith(FileName,'movie_comb')
                    [p,pf,~] = fileparts(p);
                    FileName = [pf,'\',FileName];
                end
               fileString{idx} = [FileName,FileExt];
           end
           % check with respect to the order. Assume obj.VideoFrontFileNames are sorted.
           [fileStringS,iiS] = sort(fileString);
           fileMatch = strcmp(fileStringS,obj.VideoFrontFileNames);
           if ~all(fileMatch)
                fileStringS(~fileMatch)
                errordlg('Names of the selected Files in the Experiment and the Labeler do not match. Seee Matlab print');
           end
           
            
           % --------------------------------------------------
           % select files with labels
           uniqueLabels    = groundTruthSession.GTS.RoiInfo; 
           mediaWithLabels = zeros(mediaNum,1);
           mediaFrameLength = zeros(mediaNum,1);
           for mediaIndex = 1:mediaNum
                mediaFrameLength(mediaIndex) = length(groundTruthSession.GTS.MediaInfo(mediaIndex).FrameInfo);
                % find non empty labels
                w       = arrayfun(@(x)(~isempty(x.labels)),groundTruthSession.GTS.MediaInfo(mediaIndex).FrameInfo,'UniformOutput', true);
                mediaWithLabels(mediaIndex) = sum(w);
           end
           maxFrameNum      = max(mediaFrameLength);
           
           % ------------------------------------------------
           % extract ROI data for all frames
           bboxData = nan(maxFrameNum,2,roiNum,mediaNum);
           for mediaIndex = 1:mediaNum
                if mediaWithLabels(mediaIndex) < 1, continue; end
                for ri = 1:roiNum
                   labelName = groundTruthSession.GTS.RoiInfo{ri};
                   for fi = 1:length(groundTruthSession.GTS.MediaInfo(mediaIndex).FrameInfo)
                       if length(groundTruthSession.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels) < 1, continue; end
                       li = find(strcmp(groundTruthSession.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels,labelName));
                       if isempty(li), continue; end
                       bbox = groundTruthSession.GTS.MediaInfo(mediaIndex).FrameInfo(fi).bboxes{li};
                       xc = bbox(1);
                       xd = bbox(3);
                       yc = bbox(2);
                       yd = bbox(4);
                       bboxData(fi,1,ri,mediaIndex) = xc + xd/2;
                       bboxData(fi,2,ri,mediaIndex) = yc + yd/2;
                   end
               end
           end
           

            
            
            % --------------------------------------------------
            % Ask about event data
            doMerge = false;
            if obj.EventFileNum > 0
                buttonName = questdlg('Previous Behavioral Event data is found. Would you like?', 'Warning','Cancel','Merge','Overwrite','Cancel');
            if strcmp(buttonName,'Cancel'), return; end
                % check if merge is required
                doMerge = strcmp(buttonName,'Merge');
            end
            
            % --------------------------------------------------
            % Create Events
            for trialInd = 1:obj.VideoFrontFileNum
                if mediaWithLabels(trialInd) < 1, continue; end
                
                [obj,strEvent]          = LoadAnalysisData(obj,trialInd,'strEvent');
                
                for ri = 1:roiNum
                    if all(isnan(bboxData(:,1,ri,trialInd))), continue; end

                    strEventNew             = TPA_EventManager();
                    % Fix is required
                    strEventNew.Data        = bboxData(:,:,ri,trialInd);
                    strEventNew.Name        = uniqueLabels{ri};
                
                    %[obj,strEvent]          = LoadAnalysisData(obj,trialInd,'strEvent');
                
                    if doMerge
                        strEvent{end+1}    = strEventNew; %cat(1,strEventOld{:},strEventNew);
                    else
                        strEvent           = {strEventNew};
                    end
                    %obj                    = SaveAnalysisData(obj,trialInd,'strEvent',strEvent);
                    
                    % info
                    DTP_ManageText([], sprintf('Behavior : Event %s added to %s ',strEventNew.Name,obj.EventFileNames{trialInd}), 'I')   ;  

                end

            end
            
            
        end        
        
        
    end
    
    % GUI & Test
    methods
        
        % ==========================================
        function [obj,isOK] = GuiSelectTrial(obj)
        
        % obj - data managing object
        if nargin < 1, error('Must input Data Managing Object'); end
        
        isOK                = false; % support next level function
        options.Resize      ='on';
        options.WindowStyle ='modal';
        options.Interpreter ='none';
        prompt              = {sprintf('Enter trial number between %d:%d',1,obj.ValidTrialNum)};
        name                ='Choose trial to load';
        numlines            = 1;
        defaultanswer       ={num2str(obj.Trial)};
        
        answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
        if isempty(answer), return; end;
        trialInd           = str2double(answer{1});
        
        % check validity
        [obj,isOK]        = obj.SetTrial(trialInd);
        
%         if~isequal(Par.DMT.Trial,Par.DMB.Trial), 
%             DTP_ManageText([], 'TwoPhoton and Behavior datasets have different trials numbers', 'W' ,0)   ;             
%         end
        
    end        
        % ---------------------------------------------
        
        % ==========================================
        function [obj,isOK] = GuiSetDataParameters(obj)
        
        % obj - data managing object
        if nargin < 1, error('Must input Data Managing Object'); end
        
        % config small GUI
        isOK                  = false; % support next level function
        options.Resize        ='on';
        options.WindowStyle     ='modal';
        options.Interpreter     ='none';
        prompt                  = {'Data Resolution [X [um/pix] Y [um/pix] Z [um/frame] T [frame/sec]',...
                                'Data Decimation Factor [X [(int>0)] Y [(int>0)] Z [(int>0)] T [(int>0)]',...            
                                'Data Offset [X [um] Y [um] Z [um] T [ Left <= -400 < frame# < 400 => Right] ',...            
                                };
        name                ='Config Data Parameters';
        numlines            = 1;
        defaultanswer       ={num2str(obj.Resolution),num2str(obj.DecimationFactor),num2str(obj.Offset)};
        answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
        if isempty(answer), return; end
        
        
        % try to configure
        res                 = str2num(answer{1});
        [obj,isOK1]         = obj.SetResolution(res) ;       
        dec                 = str2num(answer{2});
        [obj,isOK2]         = obj.SetDecimation(dec) ;       
        off                 = str2num(answer{3});
        [obj,isOK3]         = obj.SetOffset(off) ;       
        isOK                = isOK1 && isOK2 && isOK3;
        
        
    end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestSelect(obj)
            % TestSelect - performs testing of the directory structure 
            % selection and check process
            
            testVideoDir  = 'C:\UsersJ\Uri\Data\Videos\m8\02_10_14';
            obj           = obj.SelectBehaviorData(testVideoDir,'side');
            obj           = obj.SelectBehaviorData(testVideoDir,'front');
            obj           = obj.SelectBehaviorData(testVideoDir,'all');
            
            testEventDir  = 'C:\UsersJ\Uri\Data\Analysis\m8\02_10_14';
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
     
        % ==========================================
        function obj = TestCombLoad(obj)
            % TestCombLoad - given a directory loads movie_comb.avi file
            testVideoDir    = 'C:\Uri\DataJ\Janelia\Videos\d13\14_08_14\Basler_14_08_2014_d13_005';
            tempTrial       = 3;
            frameNum        = 100;
            
            
            % select again using Full Load function
            obj                         = obj.SelectAllData(testVideoDir);

            % load again using Full Load function
            [obj, vidData, usrData]     = obj.LoadAllData(tempTrial,'comb');
            
            % final
            [obj,isOK]                  = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TestLoad OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestLoad Fail.'), 'E' ,0)   ;
            end;
            
            % show
            if obj.VideoFrontFileNum > 0,   figure(2),imshow(squeeze(vidData(:,:,frameNum))); end;
         
        end
        % ---------------------------------------------
        
        
    end% methods
end% classdef
