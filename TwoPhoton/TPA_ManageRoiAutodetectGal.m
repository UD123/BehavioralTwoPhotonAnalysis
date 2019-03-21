classdef TPA_ManageRoiAutodetectGal
    % TPA_ManageRoiAutodetectGal - Gals Code for ROI detection.
    % Inputs:
    %       none
    % Outputs:
    %       strROI
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 28.19 28.05.18 UD     Interface is updated
    % 28.06 24.01.18 UD     Interface to Gal code
    %-----------------------------
    
    
    properties
        
        SaveDir                      = ''; % Gals data place
        
%         ImgData                     = [];               % 3D array (nR x nC x nT) of image data
%         ImgDFF                      = [];               % 3D array (nR x nC x nT) where time is 3'd dim
%         ImgSize                     = [];               % input array size
%         %NeighbIndex                 = {};               % neighborhood info for image data M^2 x nR*nC/(M/2)^2. M neighb. size
%         
         RoiData                     = {};               % cell array of ROIs
         SliceId                     = 1;                % Slice to work on
%         ProcessType                 = 1;                % 1-mean, 2-std
%         
%         ImgProbS                    = [];               % spatial segm results
%         AreaMinMax                  = [20 1000];        % ROI min max size
%         %ImgProbT                    = [];               % time segm results
%         
%         EventCC                     = [];               % event connectivity structure
%         
%         SegmThr                     = 0.7;              % segmentation threshold
%         ImgDataIs4D                 = false;            % remember that image data was
        %UseEffectiveROI             = true;             % should we use the ROI in processing
        FigNum                      = 67;
        
    end % properties
    
    % Original
    methods
        
        % ==========================================
        function obj = TPA_ManageRoiAutodetectGal()
            % TPA_ManageRoiAutodetect - constructor
            % Input:
            %   none
            % Output:
            %     default values
            
            % connect to different algorithms
           % addpath('C:\UsersJ\Uri\SW\Imaging Box\')
            
            
        end
        
        % ==========================================
        function obj = Init(obj)
            % Init - will remove stored video data
            % Input:
            %   internal -
            % Output:
            %   ImgData,ImgDFF  -  removed
            
            % clean it up
            obj.SaveDir     = '';
%             obj.ImgDFF      = [];
%             obj.EventCC     = [];
%             obj.RoiData     = {};
%             obj.ImgProbS    = [];
            DTP_ManageText([], sprintf('AutoDetect : Clearing intermediate results.'), 'W' ,0);
           
        end
        
        % ==========================================
        function [obj,isOk] = Configure(obj)
            % Configure - user params definition
            % Input:
            %   params to configure -
            % Output:
            %   params to configure -
             isOk = false;
             
             return
            
            
            mThr                    = obj.SegmThr ;
            slieId                  = obj.SliceId ;
            pType                  = obj.ProcessType ;
            aMinMax                 = obj.AreaMinMax;
            
            
            % config small GUI
            options.Resize          = 'on';
            options.WindowStyle     ='modal';
            options.Interpreter     ='none';
            prompt                  = {...
                'Detect Thr : [0:1]',...
                'Slice Number to process: [1:3] ',...
                'Processing Type: [1-mean,2-dff]',...
                'Cell [Min, Max] Area Size : [10,2000] pix',...
                };
            name                    = 'Config Registration Parameters';
            numlines                = 1;
            defaultanswer           = {
                num2str(mThr),...
                num2str(slieId),...
                num2str(pType),...
                num2str(aMinMax),...
                };
            answer                  = inputdlg(prompt,name,numlines,defaultanswer,options);
            if isempty(answer),     return; end;
            
            
            % try to configure
            mThr                 = str2num(answer{1});
            slieId               = str2num(answer{2});
            pType                = str2num(answer{3});
            aMinMax              = str2num(answer{4});
            
            
            % check
            obj.SegmThr          = max(0.1,min(1,mThr));
            obj.SliceId          = max(0,min(999,slieId));
            obj.ProcessType      = max(1,min(2,round(pType)));
            obj.AreaMinMax       = max(10,min(2000,round(aMinMax)));
            
            isOk                    = true; % support next level function
        
            DTP_ManageText([], sprintf('AutoDetect : configuration is changed.'), 'I' ,0);
           
        end
        
        % ==========================================
        function [obj, imgData] = LoadImageData(obj,DMT)
            % LoadImageData - loads image for fileName into memory
            % Input:
            %     DMT - data manager two photon
            % Output:
            %     imgData   - 3D array image data
            
            if nargin < 2, fileDirName = 'C:\Uri\Data\Movies\Janelia\Imaging\M2\2_20_14\2_20_14_m2__002.tif'; end;
            imgData             = [];
            
            DMT                 = DMT.CheckData(false);    % do not check dirs - use user selection   
            validTrialNum       = DMT.ValidTrialNum;
            if validTrialNum < 1
                DTP_ManageText([], sprintf('Autodetect : Missing data in directory %s. Please check the folder or run Data Check',DMT.RoiDir),  'E' ,0);
                return
            else
                DTP_ManageText([], sprintf('Autodetect : Found %d Analysis files of ROI. Processing ...',validTrialNum),  'I' ,0);
            end

   
            control    = false;
            saveOutput = false;

            %%
            % setup paths to imaging and TPA files
            %if control
            basedir_imaging = DMT.VideoDir;
            basedir_TPA     = DMT.RoiDir;
           % else
           %     basedir_imaging = 'D:\Uri\Data\Technion\Imaging\D10\8_6_14\';
           %     basedir_TPA     = 'D:\Uri\Data\Technion\Analysis\D10\8_6_14\';
           % end

            %% for D10 (2 depths are acquired in 10Hz each)
            start_frame = 1;
            skip = 3;
            %% load tiff files from all trials 
            [A, N_TRIALS]   = gather_seq_video_region(basedir_imaging, basedir_TPA, saveOutput, start_frame, skip);
            
            pFile   = fullfile(DMT.VideoDir,'GalData.mat');
            try
                save(pFile,'A','N_TRIALS');
            catch
                DTP_ManageText([], sprintf('AutoDetect : problem to save file %s',pFile), 'E' ,0)   ; return
            end
            obj.SaveDir         = DMT.VideoDir;
            
            DTP_ManageText([], sprintf('AutoDetect : data is saved to %s',pFile), 'I' ,0)   ;
            
            % set data to internal structure and convert to single
            %obj             = SetImgData(obj,imgData);
        end
        
        % ==========================================
        function obj = SegmentSpaceTime(obj, segmType)
            % SegmentSpaceTime - perform space and time based segmentation using dFF info of the entire movie
            % Input:
            %   ImgData    - 3D  image (obj preloaded)
            %   segmType   - selects between different param settings
            % Output:
            %   EventCC   - list of Connected Components
            
            if nargin < 2, segmType = 3; end;
            if isempty(obj.SaveDir)
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
            
            pFile   = fullfile(obj.SaveDir,'GalData.mat');
            load(pFile,'A','N_TRIALS');
            
            region = A(151:350,301:500,:);
            [NROWS,NCOLS,~] = size(A);
            N_TIME = size(A,3) / N_TRIALS;

            
%             nR              = obj.ImgSize(1);
%             nC              = obj.ImgSize(2);
%             nT              = obj.ImgSize(3);
%             
%             
%             % params
%             switch segmType
%                 case 1
%                     % params
%                     dffType         = 1;
%                     emphType        = 4;   % signal emphsize type
%                     dffThr          = 1;   % to be sure
%                     filtThr         = ones(5,5,5); filtThr = filtThr./sum(filtThr(:));
%                     minAreaThr      = nR/40*nC/40;
%                     
%                 otherwise
%                     error('Bad segmType')
%             end
            
            
            %%
            dParams                 = default_parameters;
            %% calculate embedding
            configParams.fig_str     = 'D10_cno';
            configParams.doNormalize = true;  % !
            configParams.doImadjust  = false; % !
            configParams.doPCA       = true; % !
            calc_embedding;
            t1                      = toc(tstart);
            %% selective_clustering
            tmp                     = reshape(region,[],N_TIME*N_TRIALS);
            remove_inds             = median(tmp,2)==0;
            configParams.n_clust    = 200;
            configParams.thresh_eig = 30;
            selective_clustering2;
            t2                      = toc(tstart);
            %% merge clusters, remove clusters with small /large size
            configParams.doSizeThresh = true;
            merge_clusters;
            t3                      = toc(tstart);
            %% denoise
            demix_denoise2;
            t4                      = toc(tstart);

            % output
%             obj.EventCC     = CC;
%             obj.ImgDFF      = single(labelmatrix(CC));
            DTP_ManageText([], sprintf('AutoDetect : Found %d active regions.',CC.NumObjects), 'I' ,0);
            
        end

        % ==========================================
        function [obj,strROI] = ExtractROI(obj,FigNum)
            % ExtractROI - uses clustered data to extact ROIs
            % Input:
            %   EventCC   - list of Connected Components
            %   ImgDFF    - 3D  image (obj preloaded)
            % Output:
            %   strROI     - cell list of ROIs with xyInd - field
            
            if nargin < 2, FigNum = 137; end
            strROI          = {};
            fileDir         = '..';
            [fileName,filePath,~] = uigetfile('.mat','Labeler Output',fileDir,'multiselect','off');
            if isequal(fileName,0), return; end
            
            %s = load('C:\Users\Jackie\Downloads\D10output.mat');
            s = load(fullfile(filePath,fileName));
            
            if ~isfield(s,'mergedROI') || isempty(s.mergedROI)
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first and run detection.'), 'E' ,0);
                return;
            end
            % params
            clustNum         = size(s.mergedROI,2);
            if clustNum < 2
                DTP_ManageText([], sprintf('AutoDetect : No clsuters detected. Could be problems in Clustering of the Data.'), 'E' ,0);
                return;
            end
            
            [nR,nC]                 = size(s.max_Psi);
            cellInd                 = 0;
            cellColors              = jet(clustNum);
            for k = 1:clustNum
               
               % extract ROI data
               imgClust         = reshape(s.mergedROI(:,k),nR,nC);
               % get cells
               [cellB,imgL,cellNum]    = bwboundaries(imgClust,'noholes');
               assert(length(cellB)==1,'Call Gal : ');
                   
               cellInd          = k;
               newXY            = cellB{1};

               roiLast          = TPA_RoiManager();
               roiLast          = Init(roiLast,roiLast.ROI_TYPES.FREEHAND);
               roiLast.CountId  = cellInd;
               roiLast.CellPart = k;  % helps with colors
               roiLast          = SetColor(roiLast,cellColors(k,:));
               roiLast          = SetName(roiLast,sprintf('AROI:Z%d:%04d',obj.SliceId,cellInd));
               %roiLast.xyInd    = newXY(:,[2 1]);
               roiLast          = InitView(roiLast,newXY(:,[2 1]));
               roiLast.PixInd   = find(imgClust);
               roiLast.zInd     = obj.SliceId;  % z -stack

               strROI{cellInd,1}  = roiLast;

            end
            
            % output
            obj.RoiData     = strROI;
            DTP_ManageText([], sprintf('AutoDetect : Extracted %d ROIs.',cellInd), 'I' ,0);
            
            
        end
        
        
        % ==========================================
        function roiData = GetRoiData(obj)
            % GetRoiData - get data 
            % Input:
            %   obj
            % Output:
            %   roiData - xy coordinates of the ROI
            
            roiData = obj.RoiData;
            % check
            roiNum = length(roiData);
            if roiNum < 1,
                DTP_ManageText([], sprintf('AutoDetect : No ROI data is found.'), 'W' ,0)   ; return;
            end
                
            % output
            DTP_ManageText([], sprintf('AutoDetect : %d ROIs are in use.',roiNum), 'I' ,0)   ;
            
        end
        
        
        
        
    end
        
    % GUI
    methods
        
        % ==========================================
        function obj = ShowRois(obj,figNum)
            % ShowRois - show ROI - user and Effective
            % Input:
            %   ROI str -
            % Output:
            %   image
            if nargin  < 2, figNum = obj.FigNum; end;
            % show
            if figNum < 1, return; end;
            
           if isempty(obj.ImgSize),
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
            nR              = obj.ImgSize(1);
            nC              = obj.ImgSize(2);
            nT              = obj.ImgSize(3);
            roiNum          = length(obj.RoiData);
            if roiNum < 1,
                DTP_ManageText([], sprintf('AutoDetect : Please load roi data first.'), 'E' ,0);
                return;
            end
            % to use graythresh we need to rescale the data to uint8
            imgMean         = mean(obj.ImgData,3);
            valMax          = max(imgMean(:));
            imgNorm         = uint8(imgMean./valMax*255);
            imgNorm         = imadjust(imgNorm);
            
            % ROI
            [X,Y]           = meshgrid(1:nC,1:nR);  % export
            
            
            % init prob 
            imgROIs         = repmat(imgNorm,[1 1 3]);  % conf params
            
            % segment over the regions
            for m = 1:roiNum,
                
                % get ROI
                currentXY               = obj.RoiData{m}.xyInd;
                %effectXY                = obj.RoiData{m}.xyEffInd;
                %imgROIs(pixInd)         = m;
                pos                     = currentXY'; 
                imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','y');
                %pos                     = mean(currentXY); 
                %imgROIs                 = insertText(imgROIs,pos,obj.RoiData{m}.Name,'TextColor','yellow','BoxOpacity',0);
                %pos                     = effectXY'; 
                %imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','r');
                
            end
            
            figure(figNum + 4 + obj.ProcessType)
            imagesc(imgROIs),colorbar,title('Image with Overlayed ROIs'),
            
        end
        
        % ==========================================
        function [obj,ImgROI] = ConvertRoiToImage(obj,StrROI,zInd)
            % ConvertRoiToImage - convert ROI data to image data
            % Inputs:
            %   obj         - control structure
            %
            % Outputs:
            %   obj         - control structure updated
            
            ImgROI      = [];
            if nargin < 2, StrROI = {}; end
            if nargin < 3, zInd = obj.ActiveZstackIndex; end
            [nR,nC,nD,nT] = size(obj.ImgTrialArray);
            % check
            if nR < 1, return; end
            roiNum   = length(StrROI);
            if roiNum < 1, return; end
            ImgROI        = zeros(nR,nC,'uint8');
            for m = 1:roiNum
                if zInd ~= StrROI{m}.zInd, continue; end 
                ImgROI(StrROI{m}.PixInd) = m;
            end
            % save
            
        end
        
        % ==========================================
        function obj = PlayImgOverlay(obj,FigNum)
            % PlayImgOverlay - show dFF data with Event overlay
            % Input:
            %   internal -
            % Output:
            %   obj.ImgDFF  -  array
             if nargin  < 2, FigNum = 1; end;
           
             if isempty(obj.ImgDFF),
                DTP_ManageText([], sprintf('AutoDetect : Please run SetData first.'), 'E' ,0);
                return
             end
            
            % find perimeter
            ii  = (bwperim(obj.ImgDFF > 0,26));
            obj.ImgData(ii) = 32;
            
            implay(obj.ImgData);
            
        end
        
        % ==========================================
        function obj = PlayImgDFF(obj,FigNum)
            % PlayImgDFF - show dFF data with Event data
            % Input:
            %   internal -
            % Output:
            %   obj.ImgDFF  -  array
             if nargin  < 2, FigNum = 1; end;
           
             if isempty(obj.ImgDFF),
                DTP_ManageText([], sprintf('AutoDetect : Please run SetData first.'), 'E' ,0);
                return
             end
             objNum     = obj.EventCC.NumObjects;
             if objNum < 1,
                DTP_ManageText([], sprintf('AutoDetect : Could not detect active regions. Call 911 .'), 'E' ,0);
                return
             end
            
            %figure(FigNum),
            maxV        = max(obj.ImgData(:));
            grayImg     = reshape(obj.ImgData./maxV,[obj.ImgSize(1) obj.ImgSize(2) 1 obj.ImgSize(3)]);
            clrImage    = reshape(single(obj.ImgDFF > 0),[obj.ImgSize(1) obj.ImgSize(2) 1 obj.ImgSize(3)]);
            implay(cat(3,clrImage,grayImg,grayImg*0))
            
            
        end
        
        % ==========================================
        function obj = PlayImgData(obj,FigNum)
            % PlayImgData - plays stored video.
            % Input:
            %   internal -
            % Output:
            %   ImgData  -  is played
             if nargin  < 2, FigNum = 1; end;
           
            if isempty(obj.ImgData),
                DTP_ManageText([], sprintf('AutoDetect : requires input data load first.'), 'E' ,0);
                return
            end
            % player plays 3 dim movies
            D                      = obj.ImgData;
            %figure(FigNum),
            implay(D)
            title(sprintf('Original Data '))
            
        end
        
    end
    
    % Test
    methods
        % ==========================================
        function obj = TestLoadData(obj)
            
            % TestLoadData - test data reshape and neighborrhod construction
            
            %dataPath                = 'C:\Uri\Data\Movies\Janelia\Imaging\M2\2_20_14\2_20_14_m2__004.tif';
            dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\m8\02_10_14\2_9_14_m8__003.tif';
            [obj, imgData]          = LoadImageData(obj, dataPath);
            %obj                     = SetData(obj, imgData);
            obj                     = GetNeighborhoodIndexes(obj, 8);
            
            
        end
        
        % ==========================================
        function obj = TestDFF(obj)
            
            % TestDFF - performs testing of the mstrix inversion method on random data
            
            figNum          = 11;
            %dataPath        = 'C:\Uri\DataJ\Janelia\Imaging\M2\2_20_14\2_20_14_m2__002.tif';
            dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\m8\02_10_14\2_9_14_m8__003.tif';
            dffType         = 1;   % dff type
            emphType        = 5;   % signal emphsize type
            
            
            [obj, imgData]  = LoadImageData(obj, dataPath);
            %obj                     = SetData(obj, imgData);
            %obj             = GetNeighborhoodIndexes(obj, 8);
            obj             = ComputeDFF(obj,dffType);
            % Signal Emphasize
            obj             = SignalEmphasizeDFF(obj, emphType);
            
            obj             = PlayImgData(obj, figNum);
            obj             = PlayImgDFF(obj, figNum+1);
            obj             = DeleteData(obj);
            
        end
        
        % ==========================================
        function obj = TestSegmentSpaceTime(obj)
            
            % TestSegmentSpaceTime - performs testing of the space and time based segmentation
            % of pixels according to the activity
            
            figNum                  = 31;
            segmType                = 1;
            %dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\M2\2_20_14\2_20_14_m2__002.tif';
            %dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\m8\02_10_14\2_9_14_m8__003.tif'; % 256 x 256 x 900 - stable
            dataPath                = 'C:\UsersJ\Uri\Data\Imaging\m2\4_4_14\4_4_14_m2__016.tif'; % 
            
            obj                     = LoadImageData(obj, dataPath);
            obj                     = SegmentSpaceTime(obj, figNum);
            
            obj                     = PlayImgDFF(obj, figNum+1);
            obj                     = DeleteData(obj);
            
        end

        
        
    end% methods
    
end% classdef