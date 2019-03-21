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
    % 24.07 25.10.16 UD     Fadi frame sync is inverted + fixing number of frames
    % 23.16 28.06.16 UD     bug fix with Max Frame Num
    % 23.07 12.03.16 UD     maxFileNum is tested again
    % 22.02 12.01.16 UD     Suppress warning
    % 22.02 12.01.16 UD     Suppress warning
    % 22.01 05.01.16 UD     Created
    % 22.00 05.01.16 UD     Created from TPA_DataManagerBehavior and TwoPhotonTSeries_1604
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
       
        VideoDirPattern             = 'TSeries*';    % helps to separate folders
        VideoDirNum                 = 0;
        VideoDirNames              = {};             % dir names in the TSeries Image directory
        VideoFileNum                = 0;             % number of trials (tiff movies) in Video/Image Dir
        VideoFileNames              = {};            % file names in the cell Image directory
        VideoFilePattern            = '*_Ch2_*.tif';       % expected name for video pattern
        VideoDataSize               = [];             % data dimensions in a single trial
        VideoIndex                  = [];            % trial index extracted from file number
        VideoFrameNum               = 0;             % number of frames 
        
        % ElectroPhys
        SampleTime                  = 1e3;          % stimulus sampling time
        RecordValues                = [];            % contains records for different channels
        FrameStart                  = [];
        ChanNames                   = {};           % names of the channels
        
        % Analysis
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
        
        % ==========================================
        function obj = Clean(obj)
            % Clean - restores default
            % Input:
            %
            % Output:
            %     default values
            obj.VideoDir                     = '';           % directory of the Front and Side view image Data
            obj.EventDir                     = '';           % directory where the user Analysis data is stored
            obj.VideoDirPattern             = 'TSeries*';    % helps to separate folders
            obj.VideoDirNum                 = 0;
            obj.VideoDirNames              = {};             % dir names in the TSeries Image directory
            obj.VideoFileNum                = 0;             % number of trials (tiff movies) in Video/Image Dir
            obj.VideoFileNames              = {};            % file names in the cell Image directory
            obj.VideoFilePattern            = '*_Ch2_*.tif';       % expected name for video pattern
            obj.VideoDataSize               = [];             % data dimensions in a single trial
            
            obj.SampleTime                  = 1e3;              % sample time init value
            obj.RecordValues                = [];            % contains records for different channels
            obj.FrameStart                  = [];
            obj.ChanNames                   = {};           % names of the channels
            
            
            obj.EventFileNum                = 0;                % numer of Analysis mat files
            obj.EventFileNames              = {};               % file names of Analysis mat files
            obj.EventFilePattern            = 'BDA_*.mat';      % expected name for analysis
            
            obj.Trial                      = 0;             % current trial
            obj.ValidTrialNum              = 0;             % summarizes the number of valid trials
            obj.Resolution                 = [1 1 1 1];     % um/pix um/pix um/pix-else  frame/sec
            obj.Offset                     = [0 0 0 0];     % pix    pix     ???     frames
            obj.DecimationFactor           = [1 1 1 1];     % decimate XYZT plane of the data
            obj.SliceNum                   = 1;             % if Z slice = 2 - two Z volumes are generated, 3 - 3 volumes
            
        end
        
        
         % ==========================================
         function [obj,isOK] = SetTrial(obj,trial)
             % sets trial and tests if it is OK
             
             isOK = false;
             
             if trial < 1 || trial > obj.ValidTrialNum,
                 DTP_ManageText([], sprintf('Electro : Trial value %d is out of range. No action taken.',trial), 'E' ,0);
                 return;
             end
             isOK       = true;
             obj.Trial = trial;
         end % set.Trial
       
        % ==========================================
         function [obj,isOK] = SetSampleRate(obj,sampRate)
             % how many slices to split
             isOK                   = true;
             obj.SampleTime         = 1/sampRate;
             DTP_ManageText([], sprintf('Sample Rate is : %d Hz',sampRate), 'I' ,0);
             
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
         
         % ==========================================
         function [obj,isOK] = GuiSetDataParameters(obj)
            
            % obj - data managing object
            if nargin < 1, error('Must input Data Managing Object'); end
            
            % config small GUI
            isOK                  = false; % support next level function
            sampleRate           = 1./obj.SampleTime;
            
            options.Resize          = 'on';
            options.WindowStyle     ='modal';
            options.Interpreter     ='none';
            prompt                  = {'Data Resolution [X [um/pix] Y [um/pix] Z [um/frame] T [frame/sec]',...
                'Data Decimation Factor [X [(int>0)] Y [(int>0)] Z [(int>0)] T [(int>0)]',...
                'Data Offset (N.A.)    [X [um] Y [um] Z [um] T [frame] ',...
                'Sampling Rate [10:100000] Hz',...
                };
            name                ='Config Data Parameters';
            numlines            = 1;
            defaultanswer       ={num2str(obj.Resolution),num2str(obj.DecimationFactor),num2str(obj.Offset),num2str(sampleRate)};
            answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
            if isempty(answer), return; end
            
            
            % try to configure
            res                 = str2num(answer{1});
            [obj,isOK1]         = obj.SetResolution(res) ;
            dec                 = str2num(answer{2});
            [obj,isOK2]         = obj.SetDecimation(dec) ;
            isOK                = isOK1 && isOK2;
            slc                 = str2num(answer{4});
            [obj,isOK2]         = obj.SetSampleRate(slc) ;
            isOK                = isOK1 && isOK2;
            
            
        end
         
        % ==========================================
        function obj = SelectElectroPhysDataOld(obj,dirPath)
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
        
        % ==========================================
        function [obj, recordData] = LoadElectroPhysDataOld(obj,currTrial, figNum)
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
        
        % ==========================================
        function obj = SelectElectroPhysData(obj,dirPath)
            % SelectStimulusData - selects stimulus data files from TwoPhoton dir
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
            dirStr          = dir(fullfile(dirPath,obj.VideoDirPattern));
            dirNum          = length(dirStr);
            if dirNum < 1
                DTP_ManageText([], sprintf('Can not find directories with pattern %s in directory %s',obj.VideoDirPattern,dirPath), 'E' ,0)
                return;
            end
            
            % check files in all directories
            videoFileDirs   = cell(1,dirNum);
            videoFileNames  = cell(1,dirNum);
            emptyDirInd = []; maxFileNum = 0;
            for k = 1:dirNum
                
                % new path
                dirPathTrial    = fullfile(dirPath,dirStr(k).name);
                
                % tiff file load
                fileNames        = dir(fullfile(dirPathTrial,obj.VideoFilePattern));
                fileNum          = length(fileNames);
                if fileNum < 1
                    showTxt = sprintf('Can not find image *.tif in the directory %s. Skipping it. Check the directory name or directory is empty.',dirPathTrial);
                    DTP_ManageText([], showTxt, 'W' ,0)   ;
                    emptyDirInd = [emptyDirInd k];
                    continue;
                end
                
                % init & check
                maxFileNum          = max(maxFileNum , fileNum);
                    
                % tiff file load
                fileNames        = dir(fullfile(dirPathTrial,'*.csv'));
                fileNum          = length(fileNames);
                if fileNum < 1,
                    showTxt = sprintf('Can not find stimulus *.csv in the directory %s. Skipping it. Check the directory name or directory is empty.',dirPathTrial);
                    DTP_ManageText([], showTxt, 'W' ,0)   ;
                    emptyDirInd = [emptyDirInd k];
                    continue;
                end;
                
 
                % Load Channel - Electro Phys
                chanNum                 = 1;
                
                % save
                videoFileDirs{1,k}      = dirPathTrial;
                videoFileNames{1,k}     = fileNames(chanNum).name;
            end
            
            % check empty or bad file number directories
            if ~isempty(emptyDirInd)
                videoFileDirs(emptyDirInd)      = [];
                videoFileNames(emptyDirInd)     = [];
                dirNum                          = size(videoFileNames,2);
                DTP_ManageText([], sprintf('ElectroPhys : Empty Dirs found %s. Adjusting number of valid directories. Total %d found.',num2str(emptyDirInd),dirNum), 'W' ,0)   ;
            end
            % Fix
            frameNum                 = maxFileNum;
            maxFileNum               = length(videoFileNames);
            
            % output
            obj.VideoDir              = dirPath;
            obj.VideoDirNames         = videoFileDirs;
            obj.VideoDirNum           = dirNum;
            obj.VideoFileNames        = videoFileNames;
            obj.VideoFileNum          = maxFileNum;
            obj.VideoFrameNum         = frameNum;
            
            DTP_ManageText([], sprintf('ElectroPhys : %d trial data has been read successfully',dirNum), 'I' ,0)   ;
        end
         
        % ==========================================
        function obj = LoadElectroPhysData(obj,currTrial)
            % LoadStimulusData - loads currTrial stimulus data into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            %     fileDescriptor - string that could be 'side' / 'front' or 'all' or 'comb'
            % Output:
            %     imgData   - 3D array image data when 3'd dim is a channel front or side
            
            if nargin < 2, currTrial = 1; end;
            
            fileNamesC = obj.VideoFileNames ;
            fileNum    = obj.VideoFileNum;
            dirNum     = obj.VideoDirNum;
            dirNames   = obj.VideoDirNames;
            dirPath    = obj.VideoDir;
            
            
            % check
             if fileNum < 1
                showTxt     = sprintf('ElectroPhys : No data found. Aborting');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
             end
            if currTrial < 1 || currTrial > dirNum,
                showTxt     = sprintf('ElectroPhys : Trial is out of range %s. Loading trial 1.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0)
                currTrial = 1;
            end
            
            % csv file load
            dirTrial            = dirNames{currTrial};
            fileDirName         = fullfile(dirTrial,fileNamesC{currTrial});
            if ~exist(fileDirName,'file')
                DTP_ManageText([], sprintf('ElectroPhys : Can not locate file %s. Please check.',fileDirName), 'E' ,0)   ;  
                return
            else
                % inform
                DTP_ManageText([], sprintf('ElectroPhys : Loading data from file %s. Please Wait ...',fileNamesC{currTrial}), 'I' ,0)   ;             
            end
            
            % read csv data
            warning('off','MATLAB:iofun:UnsupportedEncoding'); % do not show warning
            recordedValues          = csvread(fileDirName,1,0);
            [recordNum,chanNum]      = size(recordedValues);
            if chanNum < 2
               error('Bad records in csv file. Do not have data') 
            end

            % do not need time 
            recordTime              = recordedValues(end,1);
            sampTime                = median(diff(recordedValues(:,1)))./1000; % in msec
            recordedValues          = recordedValues(:,2:end);
            chanNum                 = chanNum - 1;

            % load additional params
            xmlFileLoc              = strrep(fileDirName,'.csv','.xml');
            s                       = xml_read(xmlFileLoc);

            % Freq os the sampling
            stimSampleRate          = s.Experiment.Rate; % Rate is like time Yoav's code
            stimSampleTime          = 1/stimSampleRate;

            % time required by DTP_FindFrameSync
            if abs(sampTime - stimSampleTime) > 1e-3
               DTP_ManageText([],'Sampling times do not match. Problems with data files. Trying to continue.','W');
            end
            
            % find frame sync
            %parTmp.syncType            = 'System 2014'; %'Resonant 2014';
            %parTmp.syncType            = 'Prarie 2018'; %'Resonant 2014';
            parTmp.syncType            = 'Prarie 1 channel'; %
            parTmp.stimSampleTime      = stimSampleTime;
            parTmp.frameNum            = obj.VideoFrameNum;
            parTmp.recordTime          = recordTime;
            [parTmp,frameStart, recordedValues]        = TPA_FindFrameSync(parTmp,recordedValues,0)  ;
            
            % adjust to image row number
            % blank_num                   = min(blank_num,height);
            %blankValuesNum  = numel(blankValues );
            blankImNum                      = length(frameStart);
            imNum                           = obj.VideoFrameNum;
            if imNum < blankImNum
                txt = sprintf('Image number is less than blank number. Cutting blanks.');
                DTP_ManageText([], txt,   'W' ,0);
                blankImNum                  = imNum;
                frameStart                  = frameStart(1:blankImNum);
            end
            if imNum > blankImNum
                txt = sprintf('There are more images than blanks. Cutting images.');
                DTP_ManageText([], txt,   'E' ,0);
            end


            DTP_ManageText([], sprintf('ElectroPhys : Image number found    : %d',imNum),     'I' ,0)
            DTP_ManageText([], sprintf('ElectroPhys : Image blank number    : %d',blankImNum),'I' ,0)
            DTP_ManageText([], sprintf('ElectroPhys : Physiology total time : %5.2f [sec]',recordNum*stimSampleTime),  'I' ,0)

                        
            % output
            obj.Trial                       = currTrial;
            obj.SampleTime                  = stimSampleTime;
            obj.RecordValues                = recordedValues;            % contains records for different channels
            obj.FrameStart                  = frameStart;
            obj.ChanNames                   = parTmp.chanName;           % names of the channels
            
             
            DTP_ManageText([], sprintf('ElectroPhys : stimulus from file %s are loaded successfully',fileNamesC{currTrial}), 'I' ,0)   ;             
        end
        
        % ==========================================
        function obj = ShowRecordData(obj, figNum)
            % ShowRecordData - checks and shows record data for all channels
            % Input:
            %     RecordValues - NxD array 
            % Output:
            %     show 
            if nargin < 2, figNum = 101; end
        

            % show all data
            if figNum < 1, return; end;
            [recordNum,chanNum]      = size(obj.RecordValues);
            if chanNum < 1
                txt = sprintf('Please load data first.');
                DTP_ManageText([], txt,   'E' ,0);
                return
            end

            % params
            recordedValues = obj.RecordValues;
            stimSampleTime = obj.SampleTime;
            chanName    = obj.ChanNames;
            chanNum     = length(chanName);
            frameStart  = obj.FrameStart;
            tt          = (1:recordNum)'*stimSampleTime;
            
            
            %frameStart  = FrameStart; %ft_ind(1:height:blank_num);
            %frameMarks  = zeros(size(tt));

            figure(figNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
            plot(tt, recordedValues),
            hold on;
            stem(tt(frameStart),frameStart*0+.6,'w')
            hold off;
            title('Electro Data')
            %xlabel('Sample number'),
            xlabel('Time [sec]'),
            ylabel('Channel [Volt]')
            chanName{chanNum+1} = 'Frame Start';
            legend(chanName)

            
           
        end
               
        % ==========================================
        function [obj,PiezoData] = ClusterPiezoData(obj, figNum)
            % ClusterPiezoData - extracts events from piezo data
            % Input:
            %     RecordValues - NxD array 
            % Output:
            %     Piezo Events clustered 
            if nargin < 2, figNum = 101; end
            PiezoData = [];

            % show all data
            [recordNum,chanNum]      = size(obj.RecordValues);
            if chanNum < 1,
                txt = sprintf('Please load data first.');
                DTP_ManageText([], txt,   'E' ,0);
                return
            end
            
            

            % params
            recordedValues  = obj.RecordValues;
            stimSampleTime  = obj.SampleTime;
            chanName        = obj.ChanNames;
            frameStart      = obj.FrameStart;
            tt              = (1:recordNum)'*stimSampleTime;
            voltThr         = 1; % low values for Piezo
            
            i1              = strcmpi(chanName,'Piezo 1');
            i2              = strcmpi(chanName,'Piezo 2');
            
            % find continuous segments where the piezo is active
            piezoValues     = recordedValues(:,i1 | i2);
            piezoValuesAbs  = abs(piezoValues);
            enrgyPiezo      = sum(piezoValuesAbs,2);
            
            
            % filter and find peaks
            alpha           = 0.001;
            enrgyPiezoFilt  = filtfilt(alpha,[1 -(1-alpha)],enrgyPiezo);
            [pks,loc]       = findpeaks(enrgyPiezoFilt,'MinPeakHeight',voltThr);
            
            % cluster - they are all in differnet directions and also zero
            nonZeroBool     = piezoValuesAbs(loc,:) > voltThr;
            piezoSign       = sign(piezoValues(loc,:)) .* double(nonZeroBool); 
            piezoSign       = piezoSign + 1; % make it positive or zero
            piezoEncode     = piezoSign(:,1)*3 + piezoSign(:,2);
            
            % check
            piezoNum        = numel(piezoEncode);
            %if numel(piezoEncode) ~= 8,
            DTP_ManageText([], sprintf('ElectroPhys : Found %d Piezo Angles.',piezoNum),   'I' ,0);
            if piezoNum < 1,
                return
            end
            
             % estimate half width of piezo values
            sampNumHalf     = round(sum(enrgyPiezo > voltThr)/piezoNum/2);
           
            
            % output
            PiezoData       = [loc-sampNumHalf loc+sampNumHalf piezoEncode];
            
            %frameStart  = FrameStart; %ft_ind(1:height:blank_num);
            %frameMarks  = zeros(size(tt));

            
                        
            if figNum < 1, return; end;

            figure(figNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
            plot(tt, recordedValues),
            hold on;
            plot(tt,enrgyPiezo,'m');
            plot(tt(loc),pks,'wo');
            text(tt(loc),pks+0.5,num2str(piezoEncode(:)),'color','y');
            hold off;
            title('ElectroPhys Data and Extracted Events')
            %xlabel('Sample number'),
            xlabel('Time [sec]'),
            ylabel('Channel [Volt]')
            chanName{chanNum+1} = 'Energy';
            chanName{chanNum+2} = 'Peaks';
            legend(chanName)

            
           
        end
        
        % ==========================================
        function [obj, eventData] = ConvertToAnalysis(obj,piezoData)
            % ConvertToAnalysis - converts Stimulus data to Behavioral event format.
            % Get it ready for analysis directory for specific trial 
            % Input:
            %     piezoData   - 8 x 3 array of start,stop and Id for specific trial
            % Output:
             %     eventData   - event structure information for specific trial
            %                   classiiers are subfields  
           
            if nargin < 2, error('Requires 2nd argument'); end;
            
            
            eventData       = {};
            if size(piezoData,2) ~= 3, 
                DTP_ManageText([], sprintf('ElectroPhys : Bad event %d durations.',obj.Trial), 'E' ,0)   ;   
                return;
            end
            classNum        = size(piezoData,1);
            %eventData       = {};
            roiLast          = TPA_EventManager();
            dataLen          = size(obj.RecordValues,1);
           
            % get data from Jabba scores
            for m = 1:classNum,
                
                % start and end of the events - could be multiple
                startInd        = piezoData(m,1);
                stopInd         = piezoData(m,2);
                eventName       = sprintf('angle_%d',piezoData(m,3));
                
                % detrmine if the length has minimal distance
                eventDuration       = stopInd - startInd;
                if any(eventDuration < 0),
                    DTP_ManageText([], sprintf('ElectroPhys : Bad event %d durations.',m), 'E' ,0)   ;                     
                    continue;
                end
                
                    
                pos                 = [startInd 50 eventDuration 150];
                xy                  = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                roiLast.Color       = rand(1,3);   % generate colors
                %roiLast.Position    = pos;   
                %roiLast.xyInd       = xy;          % shape in xy plane
                roiLast.Name        = eventName; %jabData{m}.Name;
                roiLast.SeqNum      = m;
                roiLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
                roiLast.yInd        = round([min(xy(:,2)) max(xy(:,2))]);  % time/frame indices
                roiLast.Data        = zeros(dataLen,1);
                roiLast.Data(startInd:stopInd,1)  = 1;

                % save
                eventData{m}        = roiLast;
            end

            DTP_ManageText([], sprintf('ElectroPhys : Converting Piezo to %d Events : Done',classNum), 'I' ,0)   ;             
        end
        
        % ==========================================
        function obj = ImportEventsLiora(obj,dirPath)
            % ImportEvents - creates Events from Piezo data
            % Input:
            %     dirPath       - string path to the directory
            % Output:
            %     BDA files   - cell array of dir of the files
            
            if nargin < 2, dirPath = pwd; end;
            
            % do load and convert
            obj             = SelectAllData(obj,dirPath);
            for trialInd = 1:obj.VideoDirNum,

                obj             = LoadElectroPhysData(obj,trialInd);
                obj             = ShowRecordData(obj, 0);
                [obj,pData]     = ClusterPiezoData(obj, 10);
                [obj,strEvent]  = ConvertToAnalysis(obj, pData);
                obj             = SaveAnalysisData(obj,trialInd,'strEvent',strEvent);

            end
            
            
        end        
        
        % ==========================================
        function [obj, eventData] = ConvertElectroPhysToEvents(obj)
            % ConvertElectroPhysToEvents - converts Electr Phys data to Behavioral event format.
            % Get it ready for analysis directory for specific trial 
            % Input:
            %     RecordValues   - N x 6 record
            % Output:
             %     eventData   - event structure information for specific trial
            %                   classiiers are subfields  
           
            %if nargin < 2, error('Requires 2nd argument'); end;
            

            % params
            recordedValues  = obj.RecordValues;
            stimSampleTime  = obj.SampleTime;
            chanName        = obj.ChanNames;
            %frameStart      = obj.FrameStart;
            %tt              = (1:recordNum)'*stimSampleTime;
            
            i1              = strcmpi(chanName,'Electrophysiology');
            
            % find continuous segments where the piezo is active
            electroValues   = recordedValues(:,i1);            
            
%             % filter and find peaks
%             alpha           = 0.001;
%             enrgyPiezoFilt  = filtfilt(alpha,[1 -(1-alpha)],enrgyPiezo);
%             [pks,loc]       = findpeaks(enrgyPiezoFilt,'MinPeakHeight',voltThr);
            
            
            
            eventData       = {};
            if size(electroValues,1) < 3, 
                DTP_ManageText([], sprintf('ElectroPhys : Bad event %d durations.',obj.Trial), 'E' ,0)   ;   
                return;
            end
            classNum        = size(electroValues,2);
            %eventData       = {};
            roiLast          = TPA_EventManager();
            dataLen          = size(obj.RecordValues,1);
           
            % get data from Jabba scores
            for m = 1:classNum,
                
                % start and end of the events - could be multiple
                startInd        = 100; %piezoData(m,1);
                stopInd         = 1./stimSampleTime; %piezoData(m,2);
                eventName       = sprintf('ElectroPhys_%d',m);
                
                % detrmine if the length has minimal distance
                eventDuration       = stopInd - startInd;
                if any(eventDuration < 0),
                    DTP_ManageText([], sprintf('ElectroPhys : Bad event %d durations.',m), 'E' ,0)   ;                     
                    continue;
                end
                
                    
                pos                 = [startInd 50 eventDuration 150];
                xy                  = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                roiLast.Color       = rand(1,3);   % generate colors
                %roiLast.Position    = pos;   
                %roiLast.xyInd       = xy;          % shape in xy plane
                roiLast.Name        = eventName; %jabData{m}.Name;
                roiLast.SeqNum      = m;
                roiLast.tInd        = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
                roiLast.yInd        = round([min(xy(:,2)) max(xy(:,2))]);  % time/frame indices
                roiLast.Data        = electroValues;
                %roiLast.Data(startInd:stopInd,1)  = 1;

                % save
                eventData{m}        = roiLast;
            end

            DTP_ManageText([], sprintf('ElectroPhys : Converting Piezo to %d Events : Done',classNum), 'I' ,0)   ;             
        end
        
        
        % ==========================================
        function obj = ImportEventsElectroPhys(obj,dirPath)
            % ImportEventsElectroPhys - creates Events from Electro Phys data - one event
            % Input:
            %     dirPath       - string path to the directory
            % Output:
            %     BDA files   - cell array of dir of the files
            
            if nargin < 2, dirPath = pwd; end
            
            % do load and convert
            obj             = SelectAllData(obj,dirPath);
            for trialInd = 1:obj.VideoDirNum

                obj             = LoadElectroPhysData(obj,trialInd);
                obj             = ShowRecordData(obj, 0);
                [obj,strEvent]  = ConvertElectroPhysToEvents(obj);
                
                % clean 50 Hz and more
                peakNum         = 4;
                s               = strEvent{1,1}.Data;
                Fs              = 10e3;
                pf              = fft(s);
                f               = ((0:numel(pf)-1)./numel(pf))*Fs;
                apf             = abs(pf); apf(f<40) = 0; apf(f > Fs-40) = 0;
                [ppeak,ploc,pw] = findpeaks(apf,'SortStr','descend','NPeaks',peakNum*2,'MinPeakDistance',100);
                figure(64),semilogy(f,apf,'b',f(ploc),ppeak,'og',f(ploc-3),ppeak,'<r',f(ploc+3),ppeak,'>r');
                title('Signal with rejection bands');
                % reject
                for dt = -3:3 
                    pf(ploc+dt) = 0; 
                end
                sr               = real(ifft(pf));
                strEvent{1,1}.Data = sr; 
                figure(65),plot(s,'b'); hold on; plot(sr,'r'); hold off;
                title('Signal Before and After filtering');
                
                % save
                obj             = SaveAnalysisData(obj,trialInd,'strEvent',strEvent);

            end
            
            
        end        
        
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
                DTP_ManageText([], 'ElectroPhys :  Path is not specified', 'E' ,0)
                return; 
            end;
            
            
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
        
       % ==========================================
        function [obj, fileName] = GetAnalysisFileName(obj,currTrial)
            % GetAnalysisFileName - converts tif file name to relevant mat file name
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     fileName   - analysis file name no path
            
            % take any active channel and strip off the name
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
            if obj.VideoFileNum > 0,
                fileName        = obj.VideoFileNames{currTrial} ;
            else
                DTP_ManageText([], sprintf('ElectroPhys : Event : No video files. Need to load video first.'), 'E' ,0) ;
                return
            end
            
             % get prefix and siffix position : there is a directory name before
             sPos       = strfind(fileName,'.csv');
             experName  = fileName(1:sPos-1);

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
                
            DTP_ManageText([], sprintf('ElectroPhys : Analysis data from file %s has been loaded successfully',obj.EventFileNames{currTrial}), 'I' ,0)   ;             
        end
        
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
%             if currTrial > obj.EventFileNum,
%                 DTP_ManageText([], sprintf('ElectroPhys : Event : Requested trial exceeds video files. Nothing is saved.'), 'E' ,0) ;
%                 return
%             end;
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
            if obj.VideoFileNum > 0 && currTrial <= obj.VideoFileNum && bitand(removeWhat,1)>0,
                obj.VideoFileNames(currTrial)  = [];
                obj.VideoFileNum               = obj.VideoFileNum - 1;
                isRemoved = true;
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
        
        % ==========================================
        function [obj, CheckOK] = CheckData(obj,ReadDir)
            % CheckData - checks image and user analysis data compatability
            % Input:
            %     ReadDir  -  true - read directory content
            % Output:
            %     CheckOK - indicator of critical errors
              if nargin < 2, ReadDir = true; end;
           
            CheckOK     = true;
            
            if obj.Trial < 1,
                obj.Trial       = 1;
                DTP_ManageText([], 'ElectroPhys : No trial is selected. Please select a trial or do new data load.', 'E' ,0)   ;
            end
            
            % reread
            if ReadDir,
            obj             = SelectElectroPhysData(obj,obj.VideoDir);
            end
            trialNum        = obj.VideoDirNum;  % valid dir for all the data            
            
            
            % video data with 1 camera compatability
            if obj.VideoFileNum < 1,
                DTP_ManageText([], 'ElectroPhys : Image ElectroPhys data is not found. Trying to continue.', 'W' ,0)   ;
            else
                trialNum = min(trialNum,obj.VideoDirNum);
                DTP_ManageText([], sprintf('ElectroPhys : Using video data from directory %s.',obj.VideoDirNames{obj.Trial}), 'I' ,0)   ;                
            end
            
            % reread dir structure
            if ReadDir,
            obj             = SelectAnalysisData(obj,obj.EventDir);            
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
            
            if obj.VideoDirNum ~= obj.EventFileNum
                DTP_ManageText([], 'ElectroPhys : Video and Analysis file number missmatch.', 'W' ,0)   ;
            end
            
            
            % summary
            DTP_ManageText([], sprintf('ElectroPhys : Status %d : Found %d valid trials.',CheckOK,trialNum), 'I' ,0)   ;
            
            
            % output
            obj.ValidTrialNum           = trialNum;
            obj.Trial                   = 1;
            
        end
        
        % ==========================================
        function obj = RemoveEventData(obj)
            % RemoveEventData - deletes files on the disk and also cleans the relevant structures
            % Input:
            %
            % Output:
            %     -
            if isempty(obj.EventDir) || ~exist(obj.EventDir,'dir'),
                 DTP_ManageText([], sprintf('ElectroPhys : Event directory is empty or does not exists.'), 'E' ,0);
                 return;
            end
            
            if obj.EventFileNum < 1,
                 DTP_ManageText([], sprintf('ElectroPhys : No event data in directory %s.',obj.EventDir), 'W' ,0);
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
        
    end
    
    % Tests
    methods
        
        
        % ==========================================
        function obj = TestSelect(obj)
            % TestSelect - performs testing of the directory structure 
            % selection and check process
            
            testVideoDir  = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Imaging\B18\20_12_15\20_12_15A';
            obj           = obj.SelectElectroPhysData(testVideoDir);
            
            %return
            
            testEventDir  = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Analysis\B18\20_12_15\20_12_15A';
            obj           = obj.SelectAnalysisData(testEventDir);
            
            % check
            [obj,isOK]    = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TestSelect 1 OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TestSelect 1 Fail.'), 'E' ,0)   ;
            end;
            
            return
            
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
        
        % ==========================================
        function obj = TestElectroPhysLoad(obj)
            % TestLoad - given a directory loads full data
            % 8 angles
            testVideoDir   = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Imaging\B18\20_12_15\20_12_15A';
            % 1 angle
            testVideoDir   = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Imaging\B18\7_12_15\7_12_15A';
            testTrial      = 3;
            figNum         = 100;
            
            % select again using Full Load function
            obj             = SelectElectroPhysData(obj,testVideoDir);
            obj             = LoadElectroPhysData(obj,testTrial);
            obj             = ShowRecordData(obj, figNum);

            
            % final
            [obj,isOK]                         = CheckData(obj);
            if isOK, 
                DTP_ManageText([], sprintf('TesttElectroPhysLoad OK.'), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TesttElectroPhysLoad Fail.'), 'E' ,0)   ;
            end;
         
        end
        
         % ==========================================
        function obj = TestCluster(obj)
            % TestCluster - given a directory loads full data
            % and clusters it according to piezo
            % 8 angles
            testVideoDir   = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Imaging\B18\20_12_15\20_12_15A';
            % 1 angle
            testVideoDir   = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Imaging\B18\7_12_15\7_12_15A';
            testTrial       = 1;
            figNum          = 100;
            
            
            % select again using Full Load function
            obj             = SelectElectroPhysData(obj,testVideoDir);
            obj             = LoadElectroPhysData(obj,testTrial);
            %obj             = ShowRecordData(obj, figNum);
            obj             = ClusterPiezoData(obj, figNum);
         
        end
       
         % ==========================================
        function obj = TestConvert(obj)
            % TestConvert - given a directory loads full data
            % and clusters it according to piezo. Converts to events
            % 8 angles
            testVideoDir   = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Imaging\B18\20_12_15\20_12_15A';
            % 1 angle
            testVideoDir   = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Imaging\B18\7_12_15\7_12_15A';
            testTrial       = 11;
            figNum          = 100;
            
            
            % select again using Full Load function
            obj             = SelectElectroPhysData(obj,testVideoDir);
            obj             = LoadElectroPhysData(obj,testTrial);
            %obj             = ShowRecordData(obj, figNum);
            [obj,pData]     = ClusterPiezoData(obj, figNum);
            [obj,eData]     = ConvertToAnalysis(obj, pData);
         
        end
        
         % ==========================================
        function obj = TestImport(obj)
            % TestImport - given a directory loads full data
            % and clusters it according to piezo. Converts to events and saves them
            % 8 angles
            testVideoDir   = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Imaging\B18\20_12_15\20_12_15A';
            % 1 angle
            %testVideoDir   = 'C:\Users\Jackie.MEDICINE\Documents\liora\Data\Imaging\B18\7_12_15\7_12_15A';
            figNum          = 100;
            
            
            % select again using Full Load function
            obj             = ImportEvents(obj,testVideoDir);
         
        end
        
        
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
        
        
    end% methods
end% classdef
