classdef TPA_DataManagerTwoChannel
    % TPA_DataManagerTwoChannel - Initializes different Video directory structures if Prarie system 
    % used in the analysis
    % Responsible for data integrity and naming convention between Imaging and ROI Analysis
    % Video Recordings (TBD) and Two Photon Analysis SW - Prarie System
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
    % 28.01 28.12.17 UD     Adopted from PrariManager for two channel load.
    % 27.10 08.11.17 UD     Prarie load when only analysis data is present.
    % 24.05 16.08.16 UD     Trying to support uneven image number in one trial - cut them off. Resolution is not an integer.
    % 23.19 16.08.16 UD     Ch2 fix
    % 22.03 12.01.16 UD     ROI conversion to class
    % 22.02 12.01.16 UD     Fixing management VideoDirNum
    % 22.00 05.01.16 UD     Adding Video Dir Names for management
    % 21.19 08.12.15 UD     Empty dir print
    % 21.17 01.12.15 UD     Fixing directory reading - CheckData
    % 21.12 18.11.15 UD     Trying to maintain roi files in sync with directories
    % 21.10 10.11.15 UD     fixing empty dirs and multiple selection delete.
    % 19.25 31.03.15 UD     load TSeries files.
    % 19.23 17.02.15 UD     Assign all files without video files.
    % 19.19 11.01.15 UD     Fixing bug with shifts
    % 19.16 30.12.14 UD     Support multi dimensional shift
    % 19.07 03.10.14 UD     Improve and bug fixes
    % 19.01 29.07.14 UD     Improve checking by dir structure re-read
    % 18.09 07.07.14 UD     Only analysis data support
    % 17.08 05.04.14 UD     adding clean
    % 17.01 08.03.14 UD     trying to improve export of tif. Adding shift info save and load
    % 16.18 25.02.14 UD     adding volume split capabilities
    % 16.11 22.02.14 UD     analysis file name load fix
    % 16.09 21.02.14 UD     Tiff close added
    % 16.07 20.02.14 UD     Adding resolution parameters
    % 16.04 17.02.14 UD     Adding decimation and splitting record remove
    % 16.03 16.02.14 UD     Split the Global manager on fractions
    % 16.01 15.02.14 UD     Updated to support single Behavior image. Adding JAABA support
    % 16.00 13.02.14 UD     Janelia Data integration
    %-----------------------------
    
    
    properties
        VideoDir                    = '';            % directory of the Cell image Data
        RoiDir                      = '';            % directory where the user Analysis data is stored
        
        VideoDirPattern             = 'TSeries*';    % Directories with tif files
        VideoDirNum                 = 0;
        VideoDirNames              = {};             % dir names in the TSeries Image directory
        
        VideoFileNum                = 0;             % number of trials (tiff movies) in Video/Image Dir
        VideoFileNames              = {};            % file names in the cell Image directory
        VideoDataSize              = [];             % data dimensions in a single trial
        VideoFilePattern            = '*Ch*.tif';   % expected name for video pattern
        VideoIndex                  = [];            % trial index extracted from file number
        
        
        RoiFileNum                  = 0;                % numer of Analysis mat files
        RoiFileNames                = {};               % file names of Analysis mat files
        RoiFilePattern              = 'TPA_*.mat'; % expected name for analysis
        
        
        % common info
        Trial                      = 1;             % current trial
        ValidTrialNum              = 0;             % summarizes the number of valid trials
        
        % set up resolution for sync                     X     Y     Z             T
        Resolution                 = [1 1 1 1];     % um/pix um/pix um/frame  frame/sec
        % how to offset data from the start
        Offset                     = [0 0 0 0];     % pix    pix     ???     frames
        % decimate
        DecimationFactor           = [1 1 1 1];     % decimate XYZT plane of the data
        
        % split tif file into Z slaices
        SliceNum                   = 2;             % if Z slice = 2 - two Z volumes are generated, 3 - 3 volumes
        
        
        
    end % properties
    properties (SetAccess = private)
        %hTifRead                =  [];          % object to read Tif files
        %hTifWrite                = [];          % object to write Tif files
    end
    %     properties (Dependent)
    %     end
    
    methods
        
        % ==========================================
        function obj = TPA_DataManagerTwoChannel()
            % TPA_DataManagerTwoChannel - constructor
            % Input:
            %
            % Output:
            %     default values
        end
        % ---------------------------------------------
        % ==========================================
        function obj = Clean(obj)
            % Clean - restores default
            % Input:
            %
            % Output:
            %     default values
            obj.VideoDir                    = {};            % directory of the Cell image Data
            obj.RoiDir                      = '';            % directory where the user Analysis data is stored
            obj.VideoDirPattern             = 'TSeries*';    % Directories with tif files
            obj.VideoDirNum                 = 0;
            obj.VideoDirNames              = {};             % dir names in the TSeries Image directory
            obj.VideoFileNum                = 0;             % number of trials (tiff movies) in Video/Image Dir
            obj.VideoFileNames              = {};            % file names in the cell Image directory
            obj.VideoDataSize              = [];             % data dimensions in a single trial
            obj.VideoFilePattern            = '*Ch*.tif';       % expected name for video pattern
            obj.VideoIndex                  = []; 
            obj.RoiFileNum                  = 0;                % numer of Analysis mat files
            obj.RoiFileNames                = {};               % file names of Analysis mat files
            obj.RoiFilePattern              = 'TPA_*.mat'; % expected name for analysis
            obj.Trial                      = 1;             % current trial
            obj.ValidTrialNum              = 0;             % summarizes the number of valid trials
            obj.Resolution                 = [1 1 1 1];     % um/pix um/pix um/frame  frame/sec
            obj.Offset                     = [0 0 0 0];     % pix    pix     ???     frames
            obj.DecimationFactor           = [1 1 1 1];     % decimate XYZT plane of the data
            obj.SliceNum                   = 2;             % if Z slice = 2 - two Z volumes are generated, 3 - 3 volumes
            
        end
        
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
            obj.Resolution   = resolValuesTmp;
            DTP_ManageText([], sprintf('Resolution is : %d [um/pix] %d [um/pix] %d [um/frame] %d [frame/sec]',resolValuesTmp), 'I' ,0);
            
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
            [obj,isOK2]             = SetResolution(obj,obj.Resolution .*obj.DecimationFactor);
            isOK                   = isOK && isOK2;
            DTP_ManageText([], sprintf('Decimation is : %d-[X] %d-[Y] %d-[Z] %d-[T]',decimFactor), 'I' ,0);
            
            
        end % set.Decimation
        
        % ==========================================
        function [obj,isOK] = SetSliceNum(obj,sliceNum)
            % how many slices to split
            isOK                   = true;
            obj.SliceNum           = sliceNum;
            DTP_ManageText([], sprintf('Channel Number is : %d',sliceNum), 'I' ,0);
            
        end
        
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
            
            
        end
        
        % ==========================================
        function [obj,isOK] = GuiSetDataParameters(obj)
            
            % obj - data managing object
            if nargin < 1, error('Must input Data Managing Object'); end
            
            % config small GUI
            isOK                    = false; % support next level function
            options.Resize          ='on';
            options.WindowStyle     ='modal';
            options.Interpreter     ='none';
            prompt                  = {
                'Data Resolution [X [um/pix] Y [um/pix] Z [um/frame] T [frame/sec]',...
                'Data Decimation Factor [X [(int>0)] Y [(int>0)] Z [(int>0)] T [(int>0)]',...
                'Number of Channels [nZ - number of Z] ',...
                };
            name                ='Config Data Parameters';
            numlines            = 1;
            defaultanswer       ={num2str(obj.Resolution),num2str(obj.DecimationFactor),num2str(obj.SliceNum)};
            answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
            if isempty(answer), return; end
            
            
            % try to configure
            res                 = str2num(answer{1});
            [obj,isOK1]         = obj.SetResolution(res) ;
            dec                 = str2num(answer{2});
            [obj,isOK2]         = obj.SetDecimation(dec) ;
            isOK                = isOK1 && isOK2;
            slc                 = str2num(answer{3});
            [obj,isOK2]         = obj.SetSliceNum(slc) ;
            isOK                = isOK1 && isOK2;
            
            
        end

        % ==========================================
        function obj = GetVideoFileIndex(obj)
           % GetVideoFileIndex - convert dir names to indeces
            % Input:
            %     VideoDir      - cell array of string path to the directory
            % Output:
            %     VideoIndex    - array of indeces
            
            % check
            dirNum                   = length(obj.VideoDirNames);
            if obj.VideoFileNum < 1,        DTP_ManageText([], 'Please read video data first', 'E');    return; end
            if dirNum ~= obj.VideoFileNum,  DTP_ManageText([], 'VideoFileNum missmatch', 'E');          return; end
            
            % extract      
            videoIndex              = zeros(1,dirNum);
            for m = 1:dirNum,
                
                dirName             = obj.VideoDirNames{m};
                [a,c]               = sscanf(dirName,'TSeries-%d-%d-%d');
                if c ~= 3,
                    DTP_ManageText([], sprintf('Problem with name decoding : %s',dirName), 'E');
                    continue;
                end
                videoIndex(m)       = a(3);   
                
            end
            obj.VideoIndex      = videoIndex;
            DTP_ManageText([], sprintf('Problem with name decoding : %s',dirName), 'E');
        end
        
        % ==========================================
        function obj = SelectTwoPhotonData(obj,dirPath)
            % SelectTwoPhotonData - selects image data files
            % Input:
            %     dirPath - string path to the directory
            % Output:
            %     VideoFileDir   - cell array of dir of the files
            %     VideoFileNames - cell array of names of the files
            
            if nargin < 2, dirPath = pwd; end
            
            % check
            if ~exist(dirPath,'dir')
                showTxt     = sprintf('Can not find directory %s',dirPath);
                DTP_ManageText([], showTxt, 'E' ,0)
                return
            end
            
            % detect all the directories
            %dirStr          = imageSet(dirPath,'recursive');
            dirStr          = dir(fullfile(dirPath,obj.VideoDirPattern));
            dirNum          = length(dirStr);
            if dirNum < 1
                DTP_ManageText([], sprintf('Can not find directories with pattern %s in directory %s',obj.VideoDirPattern,dirPath), 'E' ,0)
                return;
            end
            
            % check files in all directories
            videoFileDirs   = cell(1,dirNum);
            %videoFileNames  = cell(1,dirNum);            
            maxFileNum      = 0; emptyDirInd = [];
            for k = 1:dirNum
                
                % new path
                dirPathTrial    = fullfile(dirPath,dirStr(k).name);
                
                % tiff file load
                fileNames        = dir(fullfile(dirPathTrial,obj.VideoFilePattern));
                fileNum          = length(fileNames);
                if fileNum < 1
                    showTxt = sprintf('Can not find images *.tif* in the directory %s. Skipping it. Check the directory name or directory is empty.',dirPathTrial);
                    DTP_ManageText([], showTxt, 'W' ,0)   ;
                    emptyDirInd = [emptyDirInd k];
                    continue;
                end
                
                
                % init & check
                if maxFileNum < 1
                    videoFileNames  = cell(fileNum,dirNum);
                    maxFileNum      = fileNum;
                elseif fileNum < maxFileNum/3
                    showTxt = sprintf('Number of *.tif* images in the directory %s is much less than in the first trial %d. Ignoring.',dirPathTrial,maxFileNum);
                    DTP_ManageText([], showTxt, 'W' ,0)   ;
                    emptyDirInd     = [emptyDirInd k];
                    continue;
                elseif fileNum < maxFileNum
                    for p = fileNum+1:maxFileNum
                        fileNames(p) = fileNames(fileNum);
                    end
                    fileNum         = maxFileNum;
                    showTxt = sprintf('Number of *.tif* images in the directory %s less than expected %d. Replicating.',dirPathTrial,maxFileNum);
                    DTP_ManageText([], showTxt, 'W' ,0)   ;
                elseif maxFileNum < fileNum
                    fileNames       = fileNames(1:maxFileNum);
                    fileNum         = maxFileNum;
                    showTxt = sprintf('Number of *.tif* images in the directory %s greater than expected %d. Trimming.',dirPathTrial,maxFileNum);
                    DTP_ManageText([], showTxt, 'W' ,0)   ;
                end
                
                [fileNamesC{1:fileNum,1}]       = deal(fileNames.name);
                
                % save
                videoFileDirs{1,k}              = dirPathTrial;
                videoFileNames(1:fileNum,k)     = fileNamesC;
            end
            
            % check empty or bad file number directories
            if ~isempty(emptyDirInd)
                videoFileDirs(emptyDirInd)      = [];
                videoFileNames(:,emptyDirInd)   = [];
                dirNum                          = size(videoFileNames,2);
                DTP_ManageText([], sprintf('Empty Dirs found %s. Adjusting number of valid directories. Total %d found.',num2str(emptyDirInd),dirNum), 'W' ,0)   ;
            end
            
            % output
            obj.VideoDir              = dirPath;
            obj.VideoDirNames         = videoFileDirs;
            obj.VideoDirNum           = dirNum;
            obj.VideoFileNames        = videoFileNames;
            obj.VideoFileNum          = maxFileNum;
            
            DTP_ManageText([], sprintf('Prarie2C : %d trial data has been read successfully',dirNum), 'I' ,0)   ;
        end
        
        % ==========================================
        function [obj, imgData] = LoadTwoPhotonData(obj,currTrial, imageIndx)
            % LoadTwoPhotonData - loads Cell image for currTrial into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            %     imageIndx - certain images
            % Output:
            %     imgData   - 3D array image data
            
            if nargin < 2, currTrial = 1; end
            if nargin < 3, imageIndx = [1 Inf]; end

            imgData             = [];
            
            % check
            if obj.VideoDirNum < 1
                showTxt     = sprintf('Video : No data found. Could be a problem with directory or experiment file tree.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            if currTrial < 1 || currTrial > obj.VideoDirNum
                showTxt     = sprintf('Video : Trial is out of range %s. Loading trial 1.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0)
                currTrial = 1;
            end
            
            % check
            [frameNum,trialNum]  = size(obj.VideoFileNames);
            if obj.VideoDirNum ~= trialNum
                showTxt     = sprintf('Video : Something wrong with Data Init. 911.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            if frameNum < 1
                showTxt     = sprintf('Video : No image data found for trial %d. 911.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            
            % tiff file load
            fileDirName         = fullfile(obj.VideoDirNames{currTrial},obj.VideoFileNames{1,currTrial});
            if ~exist(fileDirName,'file') % has been moved in the middle
                showTxt     = sprintf('Video : Can  not locate file %s.',fileDirName);
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            %imgData             = imread(fileDirName,'tif'); % only one file
            %imgData             = Tiff(fileDirName,'r'); % structure from prarie
            imgInfo              = imfinfo(fileDirName);
            imgFrameNum          = min(length(imgInfo),diff(imageIndx)+1);
            imgData              = zeros(imgInfo(1).Height,imgInfo(1).Width,1,imgFrameNum,'uint16');
            
            % inform
            DTP_ManageText([], sprintf('Prarie2C : Loading data from directory %s. Please Wait ...',obj.VideoDirNames{currTrial}), 'I' ,0)   ;
            
            % Slow Option
            % another option :  TIff library
            cnt = 0;
            for fi = max(1,imageIndx(1)):min(frameNum,imageIndx(end))
                fileDirName         = fullfile(obj.VideoDirNames{currTrial},obj.VideoFileNames{fi,currTrial});
                img                 = imread(fileDirName,'info',imgInfo);
                cnt                 = cnt + 1;
                imgData(:,:,1,cnt)  = img;
            end
            % need to get this info for write pocess
            
            % check decimation
            if any(obj.DecimationFactor > 1)
                DTP_ManageText([], sprintf('Prarie2C : data from file %s is decimated. Check decimation factors ',fileDirName), 'W' ,0)   ;
                % indexing
                sz              = size(imgData);
                [y,x,z,t]       = ndgrid((1:obj.DecimationFactor(2):sz(1)),(1:obj.DecimationFactor(1):sz(2)),(1:obj.DecimationFactor(3):sz(3)),(1:obj.DecimationFactor(4):sz(4)));
                ii              = sub2ind(sz,y(:),x(:),z(:),t(:));
                imgData         = reshape(imgData(ii),ceil(sz./obj.DecimationFactor));
            end
            [nR,nC,nZ,nT]       = size(imgData);
            
            % reshape to be 4 D when multiple slices are used
            if (obj.SliceNum == 2)
                
                nTs             = floor(nT/obj.SliceNum);
                if nT ~= nTs*obj.SliceNum
                    DTP_ManageText([], sprintf('Slice number %d should divide the number of images %d in file %s. Please Fix it.',sliceNum,nT,fileDirName), 'E' ,0);
                    return;
                end
                %imgData         = reshape(imgData,[nR,nC,nTs,obj.SliceNum]);
                % ONLY 2 channels
                imgData         = cat(3,imgData(:,:,:,1:nTs),imgData(:,:,:,nTs+1:2*nTs));
            elseif obj.SliceNum > 2
                errordlg('Only one or two channels are supported'); return
            else % chanel 1
            end
            imgSize             = size(imgData);
            
            
            % output
            obj.Trial           = currTrial;
            obj.VideoDataSize   = imgSize;
            DTP_ManageText([], sprintf('Prarie2C : %d images are loaded from file %s successfully',obj.VideoDataSize(4),obj.VideoFileNames{currTrial}), 'I' ,0)   ;
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SaveTwoPhotonData(obj,currTrial,imgData)
            % SaveTwoPhotonData - saves image data to tif file
            % Input:
            %     currTrial  - which trial it was
            %     imgData  - 4D array image data
            % Output:
            %     result   - file saved
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, imgData = 1; end;
            [nR,nC,nZ,nT] = size(imgData);
            
            % check
            if obj.VideoDirNum < 1
                showTxt     = sprintf('Video : No data found. Could be a problem with directory or experiment file tree.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            if currTrial < 1 || currTrial > obj.VideoDirNum,
                showTxt     = sprintf('Video : Trial is out of range %s. Saving trial 1.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0)
                currTrial = 1;
            end
            if nZ > 1
                showTxt     = sprintf('Video : Found %d Z stacks. Saving only first.',nZ);
                DTP_ManageText([], showTxt, 'W' ,0)
                nZ = 1;
            end
            
            % tiff file write
            fileDirName         = fullfile(obj.VideoDirNames{currTrial},['TPA_',obj.VideoFileNames{currTrial}]);
            
            % squueze one dimension
            imgData             = squeeze(imgData(:,:,nZ,:));
            
            % inform
            DTP_ManageText([], sprintf('Prarie2C : Writing data to file %s. Please Wait ...',fileDirName), 'I' ,0)   ;
            
            %  working for 8 bit samples, 16 TBD
            saveastiff(uint16(imgData), fileDirName);
            
            % output
            %obj.hTifWrite  = hTif; % remember in case ?
            DTP_ManageText([], sprintf('Prarie2C : Done'), 'I' ,0)   ;
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, imgData] = ShiftTwoPhotonData(obj,imgData,currShift)
            % ShiftTwoPhotonData - load image data and shift it according to the current shift
            % Input:
            %     currShift - N x 2  - N samples of YX shifts in pixels
            %     imgData   - 3D array image data
            % Output:
            %     imgData   - 3D array image data shifted
            
            if nargin < 2, imgData = 1; end;
            if nargin < 3, currShift = 1; end;
            
            % check
            if obj.VideoFileNum < 1
                showTxt     = sprintf('Prarie2C : No data found. Could be a problem with directory or experiment file tree.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            [shiftNum,nPar,shiftDim]        = size(currShift);
            if shiftNum < 1 
                showTxt     = sprintf('Prarie2C : No registration data is provided. Video is untouched.');
                DTP_ManageText([], showTxt, 'W' ,0)
                return;
            end
            [nR,nC,nZ,nT]          = size(imgData);
            if shiftNum > nT
                showTxt     = sprintf('Prarie2C : Registration data differes from actual %d. Trying to fix.',nT);
                DTP_ManageText([], showTxt, 'W' ,0);
                shiftNum  = nT;
                currShift = currShift(1:shiftNum,:);
            end
            
            % check number of z stacks
            if shiftNum ~= nT
                errordlg(sprintf('Prarie2C : Registration data does not match number of images. Should you specify slice number in ConfigData?'))   ;
                return;
            end
            
            % check multi dimensional shift
            if shiftDim > 1
                if nZ < 2
                    errordlg(sprintf('Prarie2C : Registration data expects multiple slice image data. Should you specify slice number in ConfigData?'))   ;
                    return;
                end
                % check if the number of dimensions is less than number of slices
                nZmax       = min(nZ,shiftDim);
                showTxt     = sprintf('Prarie2C : Registration data has %d dimensions. Image data has %d slices.',shiftDim,nZ);
                DTP_ManageText([], showTxt, 'I' ,0);
            end
            
            % create shifted image
            if shiftDim < 2
                for m = 1:nT
                    for z = 1:nZ
                        imgData(:,:,z,m)   = circshift(imgData(:,:,z,m),currShift(m,:));
                    end
                end
            else
                for m = 1:nT
                    for z = 1:nZmax
                        imgData(:,:,z,m)   = circshift(imgData(:,:,z,m),squeeze(currShift(m,:,z)));
                    end
                end
            end
            
            DTP_ManageText([], sprintf('Prarie2C : Registration data is applied'), 'I' ,0)   ;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SelectAnalysisData(obj,dirPath)
            % SelectAnalysisData - loads user information (ROI) related to
            % image data
            % Input:
            %     dirPath - string path to the directory
            % Output:
            %     RoiFileNames - cell array of names of the files
            
            if nargin < 2, dirPath = pwd; end
            
            if isempty(dirPath)
                DTP_ManageText([], 'Prarie2C :  Path is not specified', 'E' ,0)
                return;
            end
            
            % check
            if ~exist(dirPath,'dir')
                
                isOK = mkdir(dirPath);
                if isOK,
                    showTxt     = sprintf('Prarie2C : Can not find directory %s. Creating one...',dirPath);
                    DTP_ManageText([], showTxt, 'W' ,0)
                else
                    showTxt     = sprintf('Can not create directory %s. Problem with access or files are open, please resolve ...',dirPath);
                    DTP_ManageText([], showTxt, 'E' ,0)
                    return
                end
                
            end
            % save dir already
            obj.RoiDir              = dirPath;
            
            
            % tiff file load
            fileNames        = dir(fullfile(dirPath,obj.RoiFilePattern));
            fileNum          = length(fileNames);
            if fileNum < 1
                showTxt = sprintf('Prarie2C : Can not find data files %s in the directory %s. Check file or directory names.',obj.RoiFilePattern,dirPath);
                DTP_ManageText([], showTxt, 'W' ,0)   ;
                return
            end;
            [fileNamesC{1:fileNum,1}]   = deal(fileNames.name);
            
            % output
            obj.RoiFileNum          = fileNum;
            obj.RoiFileNames        = fileNamesC;
            
            DTP_ManageText([], sprintf('Prarie2C : %d analysis data files has been read successfully',fileNum), 'I' ,0)   ;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, fileName] = GetAnalysisFileName(obj,currTrial)
            % GetAnalysisFileName - converts tif file name to relevant mat file
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     fileName   - analysis file name no path
            
            % take any active channel and strip off the name
            fileName = 'error';
            
            % check if the analysis has been done before
            if obj.RoiFileNum > 0 && currTrial <= obj.RoiFileNum ,
                if ~isempty(obj.RoiFileNames{currTrial})
                    fileName        = obj.RoiFileNames{currTrial} ;
                    return;
                end
            end

            if obj.VideoDirNum < currTrial,
                DTP_ManageText([], sprintf('Prarie2C : Trial is out of video file range. Call 911.'), 'E' ,0) ;
                return;
            end
            
            if obj.VideoFileNum > 0,
                fileName        = obj.VideoFileNames{1,currTrial} ;
                DTP_ManageText([], sprintf('Prarie2C : No ROI file name is found. Trying to determine it from Video data.'), 'W' ,0) ;
            else
                DTP_ManageText([], sprintf('Prarie2C : No video files. Need to load video first.'), 'E' ,0) ;
                return
            end
            
            
            % get prefix and suffix position : there is a directory name before
            pPos       = 1;
            sPos       = strfind(fileName,'.tif');
            experName  = fileName(pPos:sPos-1);
            
            % deal with crasy names like . inside
            experName   = regexprep(experName,'[\W+]','_');
            
            % switch in pattern * on new string
            fileName   = regexprep(obj.RoiFilePattern,'*',experName);
            
        end
        % ---------------------------------------------
        
               
        % ==========================================
        function [obj, strROI] = CheckRoiData(obj, strROI)
            % CheckRoiData - checks ROI data
            % Input:
            %     strROI - integer that specifies trial to load
            % Output:
            %     strROI   - StrROI, StrEvent, strShift - are subfields  
            
            if nargin < 2, strROI = {}; end
            
            numROI              = length(strROI);
            if numROI < 1
                DTP_ManageText([], sprintf('ROI : No ROI data is found. Please select/load ROIs'),  'E' ,0);
                return
            end
            
            validROI            = true(numROI,1);
            for m = 1:numROI
                
            
                if isa(strROI{m},'TPA_RoiManager'), 
                    continue; 
                elseif isstruct(strROI{m}),
                    roiLast             = TPA_RoiManager();  % ROI under selection/editing
                    roiLast             = ConvertToClass(roiLast,strROI{m});
                    strROI{m}           = roiLast;
                    DTP_ManageText([], sprintf('TwoPhoton : ROI %d is converted',m), 'I' ,0)   ;
                else
                    error('Bad ROI %d',m)
                end
%                 
%                 
%                  % check for multiple Z ROIs
%                 if ~isfield(strROI{m},'Ind') ,
%                     DTP_ManageText([], sprintf('ROI : Something wrong with ROI %s. Export is not done properly',strROI{m}.Name),  'E' ,0);
%                     validROI(m) = false;
%                     continue
%                 end
                zInd             = strROI{m}.zInd; % whic Z it belongs
                if zInd < 1 || zInd > obj.SliceNum
                    DTP_ManageText([], sprintf('ROI : %s does not belong to the specified z-stack number. Did you forget to configure Stack number?',strROI{m}.Name),  'E' ,0);
                    validROI(m) = false;
                    continue;
                end
               
            end
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function [obj, usrData] = LoadAnalysisData(obj,currTrial, strName)
            % LoadAnalysisData - loads currTrial user info data into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     usrData   - user structure information for specific trial
            %     strName   - StrROI, StrEvent, strShift - are subfields
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, strName   = 'strROI'; end;
            
            usrData = [];
            
            % check consistency
            if currTrial < 1, return; end
            
            % get file name to load
            [obj, fileName] = GetAnalysisFileName(obj,currTrial)  ;          % check format
            
            
            %             % check format
            %             fileName        = obj.RoiFileNames{currTrial};
            fileToLoad      = fullfile(obj.RoiDir,fileName);
            
            % check
            if ~exist(fileToLoad,'file'),
                showTxt     = sprintf('Prarie2C :  Analysis : Can not locate file %s. Nothing is loaded.',fileToLoad);
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            
            % mat file load
            usrData          = load(fileToLoad);
            
            % check if the variable is there
            
            if strcmp(strName,'usrData'),
                % the entire data is loaded
            elseif strcmp(strName,'strROI'),
                if isfield(usrData,'strROI'),
                    usrData          = usrData.strROI;
                    [obj, usrData]   = CheckRoiData(obj, usrData);
                else
                    usrData          = [];
                end
            elseif strcmp(strName,'strShift'),
                if isfield(usrData,'strShift'),
                    usrData          = usrData.strShift;
                else
                    usrData          = [];
                end
            else
                error('Unknown parameter name %d',strName)
            end
            
            
            % output
            obj.Trial                       = currTrial;
            obj.RoiFileNames{currTrial}     = fileName;
            obj.ValidTrialNum               = max(obj.ValidTrialNum,currTrial);
            
            DTP_ManageText([], sprintf('Prarie2C : %s data from file %s has been loaded successfully',strName,obj.RoiFileNames{currTrial}), 'I' ,0)   ;
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, usrData] = SaveAnalysisData(obj,currTrial,strName,strVal)
            % SaveAnalysisData - save currTrial user info data to the
            % Analysis folder
            % Input:
            %     currTrial - integer that specifies trial to load
            %     strName    - name of the structure to save
            %     strVal     - actual structure data to save
            % Output:
            %     usrData   - user information for specific trial
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, strName = 'strROI'; end;
            usrData = [];
            
            % check consistency
            if currTrial < 1, return; end
            if currTrial > obj.VideoFileNum,
                DTP_ManageText([], sprintf('Prarie2C : Requested trial exceeds video files. '), 'W' ,0) ;
                %return
            end;
            if ~any(strcmp(strName,{'strROI','strShift'})),
                DTP_ManageText([], sprintf('Prarie2C : Input structure name must be strROI.'), 'E' ,0) ;
                error(('TwoPhoton \t: Input structure name must be strROI or strShift.'))
                return
            end
            
            % get file name to save
            [obj, fileName] = GetAnalysisFileName(obj,currTrial)  ;          % check format
            
            fileToSave      = fullfile(obj.RoiDir,fileName);
            
            % check
            if ~exist(fileToSave,'file')
                showTxt     = sprintf('Prarie2C : Analysis : No previous data file found. Creating a new file.');
                DTP_ManageText([], showTxt, 'W' ,0) ;
            else
                % load old data
                [obj, usrData] = LoadAnalysisData(obj,currTrial,'usrData');
            end
            
            % save
            obj.RoiFileNames{currTrial}        = fileName;
            
            % ovveride the structure
            if strcmp(strName,'strROI'),
                usrData.strROI         = strVal;
            elseif strcmp(strName,'strShift'),
                usrData.strShift       = strVal;
            else
                error('Unknown parameter name %d',strName)
            end
            %usrData.(strName)                  = strVal;
            %strROI             = strVal;
            
            % file to save
            %save(fileToSave,'usrData');
            save(fileToSave,'-struct','usrData');
            
            DTP_ManageText([], sprintf('Prarie2C : Analysis data has been saved to file %s',obj.RoiFileNames{currTrial}), 'I' ,0)   ;
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
            
            if isempty(dirPath),
                DTP_ManageText([], 'Prarie2C :  Path is not specified', 'E' ,0)
                return;
            end;
            
            
            % check
            if ~exist(dirPath,'dir'),
                showTxt     = sprintf('Prarie2C : Can not find directory %s',dirPath);
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
            obj           = obj.SelectTwoPhotonData(tempDir);
            
            tempDir       = regexprep(dirPathKey,repKey,'Analysis');
            obj           = obj.SelectAnalysisData(tempDir);
            
            
            %DTP_ManageText([], 'All the data has been selected successfully', 'I' ,0)   ;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, imgData, usrData] = LoadAllData(obj,currTrial)
            % LoadAnalysisData - loads currTrial user info data into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     imgData - cell image data
            %     usrData - user information for specific trial
            
            if nargin < 2, currTrial = 1; end;
            
            [obj , imgData]          = obj.LoadTwoPhotonData(currTrial);
            [obj , usrData]          = obj.LoadAnalysisData(currTrial);
            
            
            %DTP_ManageText([], 'All the data has been read successfully', 'I' ,0)   ;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = RemoveRecord(obj,currTrial, removeWhat)
            % RemoveRecord - removes file reccord of currTrial from the list
            % Input:
            %     currTrial - integer list that specifies trial to remove
            %     removeWhat - integer that specifies which record to be removed : 1-Video,4-Analysis,7 all
            % Output:
            %     obj        - with updated file list
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, removeWhat = 4; end
            
            if any(currTrial < 1), 
                DTP_ManageText([], sprintf('TwoPhoton \t: Bad index for data removal.'), 'E' ,0)   ;
                return; 
            end;
            %             if currTrial > obj.VideoFileNum,
            %                 DTP_ManageText([], sprintf('Prarie2C : Roi requested trial exceeds video files. Nothing is deleted.'), 'E' ,0) ;
            %                 return
            %             end;
            
            isRemoved       = false;
            fileNumRemove   = numel(currTrial);
            
            % video
            if obj.VideoFileNum > 0 && all(currTrial <= obj.VideoFileNum) && bitand(removeWhat,1)>0,
                obj.VideoDir(currTrial)            = [];
                obj.VideoFileNames(:,currTrial)     = [];
                obj.VideoFileNum                    = obj.VideoFileNum - fileNumRemove;
                isRemoved = true;
            end
            
            % analysis
            if obj.RoiFileNum > 0 && all(currTrial <= obj.RoiFileNum) && bitand(removeWhat,4)>0,
                obj.RoiFileNames(currTrial)         = [];
                obj.RoiFileNum                       = obj.RoiFileNum - fileNumRemove;
                isRemoved = true;
            end
            
            if isRemoved,
                DTP_ManageText([], sprintf('TwoPhoton \t: %d Records are removed.',fileNumRemove), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TwoPhoton \t: Failed to remove record.'), 'I' ,0)   ;
            end;
            
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, CheckOK] = CheckData(obj, ReadDir)
            % CheckData - checks image and user analysis data compatability
            % Input:
            %     ReadDir  -  true - read directory content
            % Output:
            %     CheckOK - indicator of critical errors
            if nargin < 2, ReadDir = true; end;
            
            % cell data
            CheckOK         = true;
            
            if obj.Trial < 1,
                obj.Trial       = 1;
                DTP_ManageText([], 'Prarie2C : No trial is selected. Please select a trial or do new data load.', 'E' ,0)   ;
            end
            
            
            
            % reread dir structure
            if ReadDir,
                if isempty(obj.VideoDirNames),
                    DTP_ManageText([], 'Prarie2C : It is possible that you need to select directory above the current.', 'E' ,0)
                    %return
                else
%                     upDir           = obj.VideoDirNames{obj.Trial};
%                     ind             = strfind(upDir,filesep); 
%                     if isempty(ind), error('Something wrong with Video Dir'); end
%                     upDir           = upDir(1:ind(end));
                    obj             = SelectTwoPhotonData(obj,obj.VideoDir);
                end
            end
            imageNum        = obj.VideoDirNum;  % valid images for all the data
            if obj.VideoFileNum < 1,
                DTP_ManageText([], 'Prarie2C : Video data is not found. Trying to continue - must be specified for analysis.', 'E' ,0)   ;
                CheckOK         = false;
            else
                if obj.Trial <= size(obj.VideoFileNames,2)
                    DTP_ManageText([], sprintf('Prarie2C : Using image data from dir %s.',obj.VideoDirNames{obj.Trial}), 'I' ,0)   ;
                end
            end
            
            % user analysis data
            % reread dir structure
            if ReadDir,
                obj             = SelectAnalysisData(obj,obj.RoiDir);
            end
            obj.RoiFileNum      = length(obj.RoiFileNames);
            if obj.RoiFileNum < 1,
                DTP_ManageText([], 'Prarie2C : User ROI analysis data is not found. Trying to continue.', 'W' ,0)   ;
            else
                if obj.Trial <= length(obj.RoiFileNames)
                    DTP_ManageText([], sprintf('Prarie2C : Using analysis ROI data from file %s.',obj.RoiFileNames{obj.Trial} ), 'I' ,0)   ;
                end
            end
            
            if obj.VideoDirNum ~= obj.RoiFileNum && obj.RoiFileNum > 0,
                DTP_ManageText([], 'Prarie2C : Video and Analysis file number missmatch.', 'W' ,0)   ;
                %imageNum         = obj.RoiFileNum;
            end
            
            % summary
            DTP_ManageText([], sprintf('Prarie2C : Check status %d : Found %d valid trials.',CheckOK,imageNum), 'I' ,0)   ;
            
            % output
            obj.ValidTrialNum           = imageNum;
            
            
        end
        % ---------------------------------------------
        
        
    end
    
    % Test
    methods
        
        % ==========================================
        function obj = TestSelect(obj)
            % TestSelect - performs testing of the directory structure
            % selection and check process
            
            testVideoDir  = 'C:\LabUsers\Liora\Data\Imaging\B13\11_10_15';
            obj           = obj.SelectTwoPhotonData(testVideoDir);
            
            
            testRoiDir    = 'C:\LabUsers\Liora\Data\Analysis\B13\11_10_15';
            obj           = obj.SelectAnalysisData(testRoiDir);
            
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
        function obj = TestVideoLoad(obj)
            % TestVideoLoad - given a directory loads video data
            testVideoDir    = 'D:\Uri\Data\Technion\Imaging\FadiTwoChannels';
            tempTrial       = 1;
            frameNum        = 31;
            
            
            % select again using Full Load function
            obj                        = SelectTwoPhotonData(obj,testVideoDir);
            
            % load again using Full Load function
            [obj, imgData]             =  LoadTwoPhotonData(obj,tempTrial);
            
            % final
            [obj,isOK]                 = CheckData(obj);
            if isOK,
                DTP_ManageText([], sprintf('TestLoad OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestLoad Fail.'), 'E' ,0)   ;
            end
            
            % show
            if obj.VideoFileNum > 0      
                figure(1),imshowpair(squeeze(imgData(:,:,1,frameNum)),squeeze(imgData(:,:,2,frameNum))); 
            end
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestLoad(obj)
            % TestLoad - given a directory loads full data
            testVideoDir    = 'C:\LabUsers\Uri\Data\Liora\Imaging\B13\11_10_15\';
            tempTrial       = 2;
            frameNum        = 100;
            
            
            % select again using Full Load function
            obj                                 = obj.SelectAllData(testVideoDir);
            
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
        % -------------------------------------------
        
        % ==========================================
        function obj = TestExport(obj)
            
            % TestExport - analysis data save and load
            
            testRoiDir  = 'C:\UsersJ\Uri\Data\Imaging\m2\2_20_14';
            tempTrial     = 3;
            
            % select again using Full Load function
            obj            = obj.SelectAllData(testRoiDir);
            %obj            = obj.SelectAnalysisData(testRoiDir);
            
            % load data
            [obj, usrData] = obj.LoadTwoPhotonData(tempTrial);
            
            % load data
            obj             = obj.SaveTwoPhotonData(tempTrial, usrData);
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestLoadDecimation(obj)
            % TestLoadDecimation - given a directory loads full data
            % applies decimation to it
            testVideoDir  = 'C:\UsersJ\Uri\Data\Imaging\m76\1-10-14\';
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
            
            % TestAnalysis - analysis data save and load
            
            testRoiDir  = 'C:\UsersJ\Uri\Data\Analysis\m8\02_10_14';
            tempTrial     = 3;
            
            % select again using Full Load function
            obj            = obj.SelectAllData(testRoiDir);
            %obj            = obj.SelectAnalysisData(testRoiDir);
            
            % load dta should fail
            [obj, usrData] = obj.LoadAnalysisData(tempTrial,'strROI');
            if isempty(usrData),
                DTP_ManageText([], sprintf('1 OK.'), 'I' ,0)   ;
            end;
            
            % write data to directory
            for m = 1:obj.VideoFileNum,
                StrROI         = m;
                tempTrial      = m;
                obj            = obj.SaveAnalysisData(tempTrial,'strROI',StrROI);
            end
            
            [obj, usrData] = obj.LoadAnalysisData(tempTrial);
            if ~isempty(usrData),
                DTP_ManageText([], sprintf('2 OK.'), 'I' ,0)   ;
            end;
            
            
        end
        % ---------------------------------------------
        
        
    end% methods
end% classdef
