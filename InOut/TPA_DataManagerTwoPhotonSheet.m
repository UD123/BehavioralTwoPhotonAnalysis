classdef TPA_DataManagerTwoPhotonSheet
    % TPA_DataManagerTwoPhotonSheet - Initializes different Video directory structures used in the analysis
    % Responsible for data integrity and naming convention between Video Imaging , ROI Analysis
    % Video Recordings (TBD) and Two Photon Analysis SW. 
    % ROIs are arranged in 4 slide sheets - latest data from Janelia
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
    % 26.00 01.06.17 UD     Created from ThoPhoton 
    % 24.08 07.11.16 UD     Set valid dir number
    % 24.04 06.09.16 UD     Fixing ROI conversion to class
    % 22.03 12.01.16 UD     ROI conversion to class
    % 21.16 25.11.15 UD     remove return for Z stack
    % 21.03 25.08.15 UD     Bring GUI inside
    % 20.12 27.07.15 UD     Support video subset read
    % 19.26 17.04.15 UD     Load ROIs by Z stack.
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
       
        VideoFileNum                = 0;             % number of trials (tiff movies) in Video/Image Dir
        VideoFileNames              = {};            % file names in the cell Image directory
        VideoDataSize              = [];             % data dimensions in a single trial
        VideoFilePattern            = '*.tif';       % expected name for video pattern
        
        
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
        SliceNum                   = 1;             % if Z slice = 2 - two Z volumes are generated, 3 - 3 volumes
        
        
        
    end % properties
    properties (SetAccess = private)
        hTifRead                =  [];          % object to read Tif files
        hTifWrite                = [];          % object to write Tif files
    end
%     properties (Dependent)
%     end

    methods
        
        % ==========================================
        function obj = TPA_DataManagerTwoPhotonSheet()
            % TPA_DataManagerTwoPhotonSheet - constructor
            % Input:
            %
            % Output:
            %     default values
        end
        
        % ==========================================
        function obj = Clean(obj)
            % Clean - restores default
            % Input:
            %
            % Output:
            %     default values
            obj.VideoDir                    = '';            % directory of the Cell image Data
            obj.RoiDir                      = '';            % directory where the user Analysis data is stored
            obj.VideoFileNum                = 0;             % number of trials (tiff movies) in Video/Image Dir
            obj.VideoFileNames              = {};            % file names in the cell Image directory
            obj.VideoDataSize              = [];             % data dimensions in a single trial
            obj.VideoFilePattern            = '*.tif';       % expected name for video pattern
            obj.RoiFileNum                  = 0;                % numer of Analysis mat files
            obj.RoiFileNames                = {};               % file names of Analysis mat files
            obj.RoiFilePattern              = 'TPA_*.mat'; % expected name for analysis
            obj.Trial                      = 1;             % current trial
            obj.ValidTrialNum              = 0;             % summarizes the number of valid trials
            obj.Resolution                 = [1 1 1 1];     % um/pix um/pix um/frame  frame/sec
            obj.Offset                     = [0 0 0 0];     % pix    pix     ???     frames
            obj.DecimationFactor           = [1 1 1 1];     % decimate XYZT plane of the data
            obj.SliceNum                   = 1;             % if Z slice = 2 - two Z volumes are generated, 3 - 3 volumes
            
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
             [obj,isOK2]             = SetResolution(obj,obj.Resolution .*obj.DecimationFactor);
             isOK                   = isOK && isOK2;
             DTP_ManageText([], sprintf('Decimation is : %d-[X] %d-[Y] %d-[Z] %d-[T]',decimFactor), 'I' ,0);
             
             
         end % set.Decimation
                 
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
         
        % ==========================================
        function obj = SelectTwoPhotonData(obj,dirPath)
            % SelectTwoPhotonData - selects image data files
            % Input:
            %     dirPath - string path to the directory
            % Output:
            %     VideoFileNames - cell array of names of the files
            
            if nargin < 2, dirPath = pwd; end;
            
            % check
            if ~exist(dirPath,'dir'),
                showTxt     = sprintf('Can not find directory %s',dirPath);
                DTP_ManageText([], showTxt, 'E' ,0)
                return
            end
            % tiff file load
            fileNames        = dir(fullfile(dirPath,obj.VideoFilePattern));
            fileNum          = length(fileNames);
            if fileNum < 1,
                showTxt = sprintf('Can not find images *.tif* in the specified directory %s. Check the directory name.',dirPath);
                DTP_ManageText([], showTxt, 'W' ,0)   ;             
                return
            end;
            [fileNamesC{1:fileNum,1}] = deal(fileNames.name);
            
            % output
            obj.VideoDir              = dirPath;
            obj.VideoFileNum          = fileNum;
            obj.VideoFileNames        = fileNamesC;
                
            DTP_ManageText([], 'TwoPhoton : data has been read successfully', 'I' ,0)   ;             
        end
        
        % ==========================================
        function [obj, imgData] = LoadTwoPhotonData(obj,currTrial, imageIndx)
            % LoadTwoPhotonData - loads Cell image for currTrial into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            %     imageIndx - certain images
            % Output:
            %     imgData   - 3D array image data
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, imageIndx = [1 Inf]; end;
            imgData             = [];
            
            % check
            if obj.VideoFileNum < 1
                showTxt     = sprintf('Video : No data found. Could be a problem with directory or experiment file tree.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            if currTrial < 1 || currTrial > obj.VideoFileNum,
                showTxt     = sprintf('Video : Trial is out of range %s. Loading trial 1.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0)
                currTrial = 1;
            end
%             % tiff file load
%             fileDirName         = fullfile(obj.VideoDir,obj.VideoFileNames{currTrial});
%             readObj             = VideoReader(fileDirName);
%             imgData             = read(readObj);
            
            % tiff file load
            fileDirName         = fullfile(obj.VideoDir,obj.VideoFileNames{currTrial});
            if ~exist(fileDirName,'file'), % has been moved in the middle
                showTxt     = sprintf('TwoPhoton : Can  not locate file %s.',fileDirName);
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            %imgData             = imread(fileDirName,'tif'); % only one file
            %imgData             = Tiff(fileDirName,'r'); % structure from prarie
            imgInfo              = imfinfo(fileDirName);
            
            % inform
            DTP_ManageText([], sprintf('TwoPhoton : Loading data from file %s. Please Wait ...',fileDirName), 'I' ,0)   ;             
            
            % this option is slow
            if imageIndx(end) < Inf,
                
                imageIndx            = max(1,min(imageIndx,length(imgInfo)));
                imageIndx            = imageIndx(1):imageIndx(end);
                fileNumToRead        = numel(imageIndx);
                imgData              = zeros(imgInfo(1).Height,imgInfo(1).Width,1,fileNumToRead,'uint16');      
                

                for fi = 1:fileNumToRead,
                    imgData(:,:,1,fi) = imread(fileDirName,'tif',imageIndx(fi));
                end     
            
            else
                
                % the entire file
                imgData              = zeros(imgInfo(1).Height,imgInfo(1).Width,1,length(imgInfo),'uint16');      

                % another option :  TIff library
                hTif                = Tiff(fileDirName,'r');
                for fi = 1:length(imgInfo),
                    hTif.setDirectory(fi);
                    imgData(:,:,1,fi) = hTif.read;
                end     
                % need to get this info for write pocess

                hTifInfo.Photometric        = hTif.getTag('Photometric');            
                hTifInfo.BitsPerSample      = hTif.getTag('BitsPerSample');
                hTifInfo.SamplesPerPixel    = size(imgData,3);
                hTifInfo.Compression        =  hTif.getTag('Compression');
                hTifInfo.PlanarConfiguration=  hTif.getTag('PlanarConfiguration');
                hTif.close();
                obj.hTifRead                = hTifInfo; % remember in case ?
            end
 
            % check decimation
            if any(obj.DecimationFactor > 1),
                DTP_ManageText([], sprintf('TwoPhoton : data from file %s is decimated. Check decimation factors ',fileDirName), 'W' ,0)   ;  
                % indexing
                sz              = size(imgData);
                [y,x,z,t]       = ndgrid((1:obj.DecimationFactor(2):sz(1)),(1:obj.DecimationFactor(1):sz(2)),(1:obj.DecimationFactor(3):sz(3)),(1:obj.DecimationFactor(4):sz(4)));
                ii              = sub2ind(sz,y(:),x(:),z(:),t(:));  
                imgData         = reshape(imgData(ii),ceil(sz./obj.DecimationFactor));                
            end
            [nR,nC,nZ,nT]       = size(imgData);


            
            % reshape to be 4 D when multiple slices are used
            if (obj.SliceNum > 1),

                % parameters that specify this particular image type
                nR_true             = 512;
                nBlanks             = obj.SliceNum - 1;
                nR_blank            = floor((nR - nR_true*obj.SliceNum)./nBlanks);
%                 nTs         = round(nT/obj.SliceNum);
%                 if nT ~= nTs*obj.SliceNum,
%                     DTP_ManageText([], sprintf('Slice number %d should divide the number of images %d in file %s. Please Fix it.',obj.SliceNum,nT,fileDirName), 'E' ,0);
%                     return;
%                 end

                imgDataNew      = zeros(nR_true,nC,obj.SliceNum,nT,'like',imgData);
                for z = 1:obj.SliceNum,
                    imgDataNew(:,:,z,:) = imgData((z-1)*(nR_true+nR_blank)+(1:nR_true),:,:,:);
                end
                imgData         = imgDataNew;
            else
                if nR > 1024,
                    DTP_ManageText([], sprintf('TwoPhoton : did you forget to specify number of slices. Should be around %2d ',round(nR/512)), 'W' ,0);
                    return
                end;  
                % indexing
           end
            
            imgSize             = size(imgData);
            
            
            % output
            obj.Trial           = currTrial;
            obj.VideoDataSize   = imgSize;
            DTP_ManageText([], sprintf('TwoPhoton : %d images are loaded from file %s successfully',obj.VideoDataSize(4),obj.VideoFileNames{currTrial}), 'I' ,0)   ;             
        end
        
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
            if obj.VideoFileNum < 1
                showTxt     = sprintf('Video : No data found. Could be a problem with directory or experiment file tree.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            if currTrial < 1 || currTrial > obj.VideoFileNum,
                showTxt     = sprintf('Video : Trial is out of range %s. Saving trial 1.',currTrial);
                DTP_ManageText([], showTxt, 'E' ,0)
                currTrial = 1;
            end
            if nZ > 1,
                showTxt     = sprintf('Video : Found %d Z stacks. Saving only first.',nZ);
                DTP_ManageText([], showTxt, 'W' ,0)
                nZ = 1;
            end
            
            % tiff file write
            fileDirName         = fullfile(obj.VideoDir,['TPA_',obj.VideoFileNames{currTrial}]);
            
            % squueze one dimension
            imgData             = squeeze(imgData(:,:,nZ,:));
            
            % inform
            DTP_ManageText([], sprintf('TwoPhoton : Writing data to file %s. Please Wait ...',fileDirName), 'I' ,0)   ;             


            %  working for 8 bit samples, 16 TBD
            saveastiff(uint16(imgData), fileDirName);
            
            
%             % another option :  TIff library
%             hTif                                = Tiff(fileDirName,'w');
%             hTif.setTag('ImageLength',           size(imgData,1));
%             hTif.setTag('ImageWidth',           size(imgData,2));
%             hTif.setTag('Photometric',          obj.hTifRead.Photometric);            
%             hTif.setTag('BitsPerSample',        obj.hTifRead.BitsPerSample);
%             hTif.setTag('SamplesPerPixel',      size(imgData,3));
%             %hTif.setTag('TileWidth',            obj.hTifRead.getTag('TileWidth'));
%             %hTif.setTag('TileLength',           obj.hTifRead.getTag('TileLength'));
%             hTif.setTag('Compression',          obj.hTifRead.Compression );
%             hTif.setTag('PlanarConfiguration',  obj.hTifRead.PlanarConfiguration);
%             hTif.setTag('Software','MATLAB');            
%             
%           not working
%             for fi = 1:size(imgData,3),
%                hTif.write(imgData(:,:,fi));
%                hTif.writeDirectory();
%             end    

%           working but can not read by ImageJ
%           hTif.write(imgData);
            
% also not working well          
%             nimgs = size(imgData,3); 
%             for n=1:nimgs 
%                 hTif.write(squeeze(imgData(:,:,n)), 'a'); 
%             end 
%             hTif.close();
           
            
            
            % output
            %obj.hTifWrite  = hTif; % remember in case ?
            DTP_ManageText([], sprintf('TwoPhoton : Done'), 'I' ,0)   ;             
        end
        
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
                showTxt     = sprintf('TwoPhoton : No data found. Could be a problem with directory or experiment file tree.');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            [shiftNum,nPar,shiftDim]        = size(currShift);
            if shiftNum < 1 ,
                showTxt     = sprintf('TwoPhoton : No registration data is provided. Video is untouched.');
                DTP_ManageText([], showTxt, 'W' ,0)
                return;
            end
           [nR,nC,nZ,nT]          = size(imgData);
           if shiftNum > nT,
                showTxt     = sprintf('TwoPhoton : Registration data differes from actual %d. Trying to fix.',nT);
                DTP_ManageText([], showTxt, 'W' ,0);
                shiftNum  = nT;
                currShift = currShift(1:shiftNum,:);
           end
            
           % check number of z stacks
           if shiftNum ~= nT,
               errordlg(sprintf('TwoPhoton : Registration data does not match number of images. Should you specify slice number in ConfigData?'))   ; 
               return;
           end
           
           % check multi dimensional shift
           if shiftDim > 1,
               if nZ < 2,
                    errordlg(sprintf('TwoPhoton : Registration data expects multiple slice image data. Should you specify slice number in ConfigData?'))   ; 
                    return;
               end
               % check if the number of dimensions is less than number of slices
               nZmax  = min(nZ,shiftDim);
               showTxt     = sprintf('TwoPhoton : Registration data has %d dimensions. Image data has %d slices.',shiftDim,nZ);
               DTP_ManageText([], showTxt, 'I' ,0);               
           end
 
           % create shifted image
           if shiftDim < 2,
                for m = 1:nT,
                    for z = 1:nZ,
                        imgData(:,:,z,m)   = circshift(imgData(:,:,z,m),currShift(m,:));
                    end
                end
           else
                for m = 1:nT,
                    for z = 1:nZmax,
                        imgData(:,:,z,m)   = circshift(imgData(:,:,z,m),squeeze(currShift(m,:,z)));
                    end
                end
           end
            
            
            DTP_ManageText([], sprintf('TwoPhoton : Registration data is applied'), 'I' ,0)   ;             

        end
        
        % ==========================================
        function obj = SelectAnalysisData(obj,dirPath)
            % SelectAnalysisData - loads user information (ROI) related to
            % image data 
            % Input:
            %     dirPath - string path to the directory
            % Output:
            %     RoiFileNames - cell array of names of the files
            
            if nargin < 2, dirPath = pwd; end;
            
            if isempty(dirPath), 
                DTP_ManageText([], 'TwoPhoton :  Path is not specified', 'E' ,0)
                return; 
            end;
            
            % check
            if ~exist(dirPath,'dir'),
                
                isOK = mkdir(dirPath);
                if isOK,
                    showTxt     = sprintf('TwoPhoton : Can not find directory %s. Creating one...',dirPath);
                    DTP_ManageText([], showTxt, 'W' ,0)
                else
                    showTxt     = sprintf('Can not create directory %s. Problem with access or files are open, please resolve ...',dirPath);
                    DTP_ManageText([], showTxt, 'E' ,0)
                    return
                end

            end
            % save dir already
            obj.RoiDir              = dirPath;
            
            
            % file load
            fileNames        = dir(fullfile(dirPath,obj.RoiFilePattern));
            fileNum          = length(fileNames);
            if fileNum < 1,
                showTxt = sprintf('TwoPhoton : Can not find data files %s in the directory %s. Check file or directory names.',obj.RoiFilePattern,dirPath);
                DTP_ManageText([], showTxt, 'W' ,0)   ;             
                return
            end;
            [fileNamesC{1:fileNum,1}]   = deal(fileNames.name);
            
            % output
            obj.RoiFileNum          = fileNum;
            obj.RoiFileNames        = fileNamesC;
            
            DTP_ManageText([], sprintf('TwoPhoton : %d analysis data files has been read successfully',fileNum), 'I' ,0)   ;             
            
        end
        % ------------------------------------------
        
       % ==========================================
        function [obj, fileName] = GetAnalysisFileName(obj,currTrial)
            % GetAnalysisFileName - converts tif file name to relevant mat file
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     fileName   - analysis file name no path
            
            % take any active channel and strip off the name
            fileName = '';
            
            % check if the analysis has been done before
            if obj.RoiFileNum > 0 && obj.RoiFileNum >= currTrial,
                fileName        = obj.RoiFileNames{currTrial} ;
                return
            else
                DTP_ManageText([], sprintf('TwoPhoton : No ROI file name are found. Trying to determine them from Video data.'), 'W' ,0) ;
            end

            
            if obj.VideoFileNum > 0,
                fileName        = obj.VideoFileNames{currTrial} ;
            else
                DTP_ManageText([], sprintf('TwoPhoton : No video files. Need to load video first.'), 'E' ,0) ;
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
        % ------------------------------------------        
        
               
        % ==========================================
        function [obj, strROI] = CheckRoiData(obj, strROI)
            % CheckRoiData - checks ROI data
            % Input:
            %     strROI - integer that specifies trial to load
            % Output:
            %     strROI   - StrROI, StrEvent, strShift - are subfields  
            
            if nargin < 2, strROI = {}; end;
            
            numROI              = length(strROI);
            if numROI < 1,
                DTP_ManageText([], sprintf('ROI : No ROI data is found. Please select/load ROIs'),  'E' ,0);
                return
            end
            
            validROI            = true(numROI,1);
            for m = 1:numROI,
                
            
                if isa(strROI{m},'TPA_RoiManager'), 
                    continue; 
                elseif isstruct(strROI{m}),
                    roiLast             = TPA_RoiManager();  % ROI under selection/editing
                    roiLast             = ConvertToClass(roiLast,strROI{m});
                    strROI{m}           = roiLast;
                    DTP_ManageText([], sprintf('TwoPhoton : ROI %d is converted',m), 'I' ,0)   ;
                else
                    error('Bad ROI %d',m)
                end;
                
%                 
%                  % check for multiple Z ROIs
%                 if ~isfield(strROI{m},'Ind') ,
%                     DTP_ManageText([], sprintf('ROI : Something wrong with ROI %s. Export is not done properly',strROI{m}.Name),  'E' ,0);
%                     validROI(m) = false;
%                     continue
%                 end
                
                zInd             = strROI{m}.zInd; % whic Z it belongs
                if zInd < 1 || zInd > obj.SliceNum,
                    DTP_ManageText([], sprintf('ROI : %s does not belong to the specified z-stack number. Did you forget to configure Stack number?',strROI{m}.Name),  'E' ,0);
                    validROI(m) = false;
                    continue;
                end
               
            end
            
            strROI = strROI(validROI);
            
        end
        
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
                showTxt     = sprintf('TwoPhoton : Analysis : Can not locate file %s. Nothing is loaded.',fileToLoad);
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
                
            DTP_ManageText([], sprintf('TwoPhoton : %s data from file %s has been loaded successfully',strName,obj.RoiFileNames{currTrial}), 'I' ,0)   ;             
        end
        % ------------------------------------------
        
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
                DTP_ManageText([], sprintf('TwoPhoton : Requested trial exceeds video files. '), 'W' ,0) ;
                %return
            end;
             if ~any(strcmp(strName,{'strROI','strShift'})),
                 DTP_ManageText([], sprintf('TwoPhoton : Input structure name must be strROI.'), 'E' ,0) ;
                 error(('TwoPhoton \t: Input structure name must be strROI or strShift.'))
                return
            end
           
            % get file name to save
            [obj, fileName]  = GetAnalysisFileName(obj,currTrial)  ;          % check format
            
             fileToSave      = fullfile(obj.RoiDir,fileName);
            
            % check
             if ~exist(fileToSave,'file')
                showTxt     = sprintf('TwoPhoton : Analysis : No previous data file found. Creating a new file.');
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
                            
            DTP_ManageText([], sprintf('TwoPhoton : Analysis data has been saved to file %s',obj.RoiFileNames{currTrial}), 'I' ,0)   ;             
        end
        % ------------------------------------------
        
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
                DTP_ManageText([], 'TwoPhoton :  Path is not specified', 'E' ,0)
                return; 
            end;
            
            
            % check
            if ~exist(dirPath,'dir'),
                showTxt     = sprintf('TwoPhoton : Can not find directory %s',dirPath);
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
                        
            % number of valid trials
            obj.ValidTrialNum = min(obj.RoiFileNum,obj.VideoFileNum);
            %DTP_ManageText([], 'All the data has been selected successfully', 'I' ,0)   ;             
            
        end
        % ------------------------------------------
        
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
        % ------------------------------------------
        
        % ==========================================
        function [obj, usrData] = LoadRoiData(obj, strROI )
            % LoadRoiData - loads newStr to roi according to z stack
            % Input:
            %     strROI     - structure of ROIs
            % Output:
            %     usrData   - user structure information for specific trial
            
            if nargin < 2, error('Must have 2 aruments') = 1; end;
            %if nargin < 3, currZstack = 1; end;
            
            usrData = [];
            roiNum  = length(strROI);
            
            % check consistency
            %if currZstack < 1, error('currZstack must be integer > 0'); end
            if roiNum < 1, warndlg('Input data does not have ROIs'); return; end;
            if ~isprop(strROI{1},'zInd'), error('Input structure is not valid ROI'); end;
            if obj.SliceNum < 2, 
                warndlg('Did you forget to specify number of Z stacks? You have only 1');  
            end;
            %if currZstack > obj.SliceNum, error('currZstack must be integer > 0'); end
            
            % get all z stacks
            zInd        = zeros(roiNum,1);
            for m = 1:roiNum,
                zInd(m)       = strROI{m}.zInd;
            end
            
            % select Z stack to import from
            zIndList    = min(zInd):max(zInd);
            [s,ok] = listdlg('PromptString','Select Z Stack to Import from :','ListString',num2str(zIndList(:)),'SelectionMode','single','Name','Select From');
            if ~ok, return; end;
            zIndFrom    = zIndList(s);
            
            % select Z index to assign
            zIndList    = 1:obj.SliceNum;
            [s,ok] = listdlg('PromptString','Select Z Stack to Assign new ROIs :','ListString',num2str(zIndList(:)),'SelectionMode','single','Name','Assign To');
            if ~ok, return; end;
            zIndTo    = zIndList(s);
            
            % select
            ii      = zInd == zIndFrom;
            usrData  = strROI(ii);
            roiNum  = length(usrData);  
            for m = 1:roiNum,
                usrData{m}.zInd       = (zIndTo); 
                usrData{m}.Name       = sprintf('%s:NZ-%d',usrData{m}.Name,zIndTo); 
            end
            
            % output
            DTP_ManageText([], sprintf('TwoPhoton : %d ROIs are assigned to Z-Stack %d successfully',roiNum,zIndTo), 'I' ,0)   ;             
        end
        % ------------------------------------------
  
        % ==========================================
        function obj = RemoveRecord(obj,currTrial, removeWhat)
            % RemoveRecord - removes file reccord of currTrial from the list
            % Input:
            %     currTrial - integer that specifies trial to load
            %     removeWhat - integer that specifies which record to be removed : 1-Video,4-Analysis,7 all
            % Output:
            %     obj        - with updated file list
            
            if nargin < 2, currTrial = 1; end;
            if nargin < 3, removeWhat = 4; end
          
            if currTrial < 1, return; end;
%             if currTrial > obj.VideoFileNum,
%                 DTP_ManageText([], sprintf('TwoPhoton : Roi requested trial exceeds video files. Nothing is deleted.'), 'E' ,0) ;
%                 return
%             end;
                        
            isRemoved = false;

            % video
            if obj.VideoFileNum > 0 && currTrial <= obj.VideoFileNum && bitand(removeWhat,1)>0,
                obj.VideoFileNames(currTrial) = [];
                obj.VideoFileNum               = obj.VideoFileNum - 1;
                isRemoved = true;
            end
             
            % analysis
            if obj.RoiFileNum > 0 && currTrial <= obj.RoiFileNum && bitand(removeWhat,4)>0,
                obj.RoiFileNames(currTrial)         = [];
                obj.RoiFileNum                       = obj.RoiFileNum - 1;
                isRemoved = true;
            end
             
            if isRemoved,
                DTP_ManageText([], sprintf('TwoPhoton \t: Record %d is removed.',currTrial), 'I' ,0)   ;
            else
                DTP_ManageText([], sprintf('TwoPhoton \t: Failed to remove record.'), 'I' ,0)   ;
            end;

            
        end
        % ------------------------------------------
        
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
                DTP_ManageText([], 'TwoPhoton : No trial is selected. Please select a trial or do new data load.', 'E' ,0)   ;
            end
            
            % reread dir structure
            if ReadDir,
            obj             = SelectTwoPhotonData(obj,obj.VideoDir);
            end
            imageNum        = obj.VideoFileNum;  % valid images for all the data
            if obj.VideoFileNum < 1,
                DTP_ManageText([], 'TwoPhoton : Video data is not found. Trying to continue - must be specified for analysis.', 'E' ,0)   ;
                CheckOK         = false;
            else
                if obj.Trial <= length(obj.VideoFileNames)
                    DTP_ManageText([], sprintf('TwoPhoton : Using image data from file %s.',obj.VideoFileNames{obj.Trial}), 'I' ,0)   ;
                end
            end
            
            % user analysis data
            % reread dir structure
            if ReadDir,
            obj             = SelectAnalysisData(obj,obj.RoiDir);            
            end
            if obj.RoiFileNum < 1,
                DTP_ManageText([], 'TwoPhoton : User ROI analysis data is not found. Trying to continue.', 'W' ,0)   ;
            else
                if obj.Trial <= length(obj.RoiFileNames)                
                    DTP_ManageText([], sprintf('TwoPhoton : Using analysis ROI data from file %s.',obj.RoiFileNames{obj.Trial} ), 'I' ,0)   ;
                end
            end
            
            if obj.VideoFileNum ~= obj.RoiFileNum
                DTP_ManageText([], 'TwoPhoton : Video and Analysis file number missmatch.', 'W' ,0)   ;
                %imageNum         = obj.RoiFileNum;
            end
            
            % summary
            DTP_ManageText([], sprintf('TwoPhoton : Check status %d : Found %d valid trials.',CheckOK,imageNum), 'I' ,0)   ;
            
            % output
            obj.ValidTrialNum           = imageNum;
            
            
        end
        % ------------------------------------------
         
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
        % ------------------------------------------

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
                                'Data Offset (N.A.)    [X [um] Y [um] Z [um] T [frame] ',...            
                                'Slice Tiff File on Multiple Z Stacks [nZ - number of Z] ',...            
                                };
        name                ='Config Data Parameters';
        numlines            = 1;
        defaultanswer       ={num2str(obj.Resolution),num2str(obj.DecimationFactor),num2str(obj.Offset),num2str(obj.SliceNum)};
        answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
        if isempty(answer), return; end;
        
        
        % try to configure
        res                 = str2num(answer{1});
        [obj,isOK1]       = obj.SetResolution(res) ;       
        dec                 = str2num(answer{2});
        [obj,isOK2]       = obj.SetDecimation(dec) ;       
        isOK                = isOK1 && isOK2;
        slc                 = str2num(answer{4});
        [obj,isOK2]       = obj.SetSliceNum(slc) ;       
        isOK                = isOK1 && isOK2;
        
        
    end
        % ------------------------------------------
        
        
        % ==========================================
        function obj = TestSelect(obj)
            % TestSelect - performs testing of the directory structure 
            % selection and check process
            
            testVideoDir  = 'C:\UsersJ\Uri\Data\Imaging\m8\02_10_14';
            obj           = obj.SelectTwoPhotonData(testVideoDir);
            
            
            testRoiDir  = 'C:\UsersJ\Uri\Data\Analysis\m8\02_10_14';
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
        % ------------------------------------------
     
        % ==========================================
        function obj = TestLoad(obj)
            % TestLoad - given a directory loads full data
            testVideoDir  = 'C:\UsersJ\Uri\Data\Imaging\m76\1-10-14\';
            tempTrial      = 3;
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
        % ------------------------------------------
        
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
        % ------------------------------------------    
        
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
        % ------------------------------------------
      
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
        % ------------------------------------------
    
        
    end% methods
end% classdef
