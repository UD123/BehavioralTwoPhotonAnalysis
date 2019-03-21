classdef TPA_ManageRoiAutodetect
    % TPA_ManageRoiAutodetect - finds cell data in tif TwoPhoton imags
    % Uses algorithm space - time info to detect similar pixels
    % If user provides outlines for ROIs - they could be adjusted.
    % Inputs:
    %       none
    % Outputs:
    %       strROI
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 27.14 26.12.17 UD     Segmentation using adaptive threshold
    % 27.06 23.10.17 UD     Segment using Voting
    % 26.02 13.06.17 UD     Auto Segment
    % 25.09 27.04.17 UD     Trying to improve
    % 23.15 07.06.16 UD     Minimal Functions
    % 23.14 21.05.16 UD     New IF and Functions
    % 23.08 15.03.16 UD     ROIs are provided dF/F
    % 18.13 10.07.14 UD     Smooth Fo before dF/F
    % 17.08 05.04.14 UD     Adding local mean dF/F
    % 17.07 02.04.14 UD     Adding debug prints for jackie
    % 17.06 23.03.14 UD     Time Space Segm is OK -  generates events
    % 17.05 23.03.14 UD     Spat Segm OK 
    % 17.03 13.03.14 UD     Created 
    %-----------------------------
    
    
    properties
        
        
        ImgData                     = [];               % 3D array (nR x nC x nT) of image data
        ImgDFF                      = [];               % 3D array (nR x nC x nT) where time is 3'd dim
        ImgSize                     = [];               % input array size
        %NeighbIndex                 = {};               % neighborhood info for image data M^2 x nR*nC/(M/2)^2. M neighb. size
        
        RoiData                     = {};               % cell array of ROIs
        SliceId                     = 1;                % Slice to work on
        ProcessType                 = 1;                % 1-mean, 2-std
        
        ImgProbS                    = [];               % spatial segm results
        AreaMinMax                  = [20 1000];        % ROI min max size
        %ImgProbT                    = [];               % time segm results
        
        EventCC                     = [];               % event connectivity structure
        
        SegmThr                     = 0.7;              % segmentation threshold
        ImgDataIs4D                 = false;            % remember that image data was
        %UseEffectiveROI             = true;             % should we use the ROI in processing
        FigNum                      = 67;
        
    end % properties
    
    methods
        
        % ==========================================
        function obj = TPA_ManageRoiAutodetect()
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
            obj.ImgData     = [];
            obj.ImgDFF      = [];
            obj.EventCC     = [];
            obj.RoiData     = {};
            obj.ImgProbS    = [];
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
                'Cell [Min, Max] Area Size : [10,20000] pix',...
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
            obj.AreaMinMax       = max(10,min(20000,round(aMinMax)));
            
            isOk                    = true; % support next level function
        
            DTP_ManageText([], sprintf('AutoDetect : configuration is changed.'), 'I' ,0);
           
        end
        
        % ==========================================
        function [obj, imgData] = LoadImageData(obj,fileDirName)
            % LoadImageData - loads image for fileName into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     imgData   - 3D array image data
            
            if nargin < 2, fileDirName = 'C:\Uri\Data\Movies\Janelia\Imaging\M2\2_20_14\2_20_14_m2__002.tif'; end;
            imgData             = [];
            
            % check
            if ~exist(fileDirName,'file')
                showTxt     = sprintf('Image : No data found. Aborting');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            % tiff file load
            imgInfo              = imfinfo(fileDirName);
            imgData              = zeros(imgInfo(1).Height,imgInfo(1).Width,1,length(imgInfo),'uint16');
                        
            % another option :  TIff library
            hTif                = Tiff(fileDirName,'r');
            for fi = 1:length(imgInfo),
                hTif.setDirectory(fi);
                imgData(:,:,1,fi) = hTif.read;
            end
            % remove dim
            [nR,nC,nZ,nT] = size(imgData);
            
            DTP_ManageText([], sprintf('AutoDetect : %d images (Z=1) are loaded from file %s successfully',nT,fileDirName), 'I' ,0)   ;
            
            % set data to internal structure and convert to single
            obj             = SetImgData(obj,imgData);
        end
        
        % ==========================================
        function obj = SetImgData(obj,imgData)
            % SetImgData - check the data before convert it to 3D 
            % Input:
            %   imgData - 3D-4D data stored after Image Load
            % Output:
            %   obj.ImgData - (nRxnCxnT)  3D array
            
            if nargin < 2, error('Reuires image data as input'); end;
            % remove dim
            [nR,nC,nZ,nT] = size(imgData);
            DTP_ManageText([], sprintf('AutoDetect : Inout image dimensions R-%d,C-%d,Z-%d,T-%d.',nR,nC,nZ,nT), 'I' ,0)   ;

            sliceId = 1;
            if nT > 1 && nZ > 1
%                 [s,ok] = listdlg('PromptString','Select Slice Id to Work On :','ListString',num2str((1:nZ)'),'SelectionMode','single');
%                 if ~ok, return; end
                sliceId = obj.SliceId;
            end
            DTP_ManageText([], sprintf('AutoDetect : Working with Slice %d',sliceId), 'I' ,0)   ;
            
            % data is 4D :  make it 3D
            sliceId         = min(sliceId,nZ);
            if nT > 1,
                imgData         = squeeze(imgData(:,:,sliceId,:));
                obj.ImgDataIs4D = true;
                
            end
            % output
            imageDataSize   = size(imgData);
            obj.ImgData     = single(imgData); % gpuArray is not wroking
            obj.ImgSize     = imageDataSize;
            obj.SliceId     = sliceId;
            
            DTP_ManageText([], sprintf('AutoDetect : %d images are in use.',imageDataSize(3)), 'I' ,0)   ;
            
            
        end
        
        % ==========================================
        function obj = SetRoiData(obj,roiData)
            % SetRoiData - check the ROI data before import 
            % Input:
            %   roiData - xy coordinates of the ROI
            % Output:
            %   obj.RoiData - 1xnRoi  cell array
            
            if nargin < 2, error('Reuires ROI data as input'); end;
            % check
            roiNum = length(roiData);
            if roiNum < 1,
                DTP_ManageText([], sprintf('AutoDetect : No ROI data is found.'), 'W' ,0)   ; return;
            else
                DTP_ManageText([], sprintf('AutoDetect : %d ROIs are provided by user.',roiNum), 'I' ,0)   ;
            end
            if isempty(obj.ImgSize),
                DTP_ManageText([], sprintf('AutoDetect : load image data first.'), 'E' ,0)   ; return;
            end

            
            % validate ROIs
            badRoiId    = true(1,roiNum);
            
            for i=1:roiNum,

                % check for problems
                if isempty(roiData{i}),
                    continue; 
                end
                % try class
                if ~isa(roiData{i},'TPA_RoiManager'),
                    continue;
                end
                if ~isprop(roiData{i},'xyInd'),       
                    continue;  
                end
                % check area
                currentXY = roiData{i}.xyInd;
                rectArea                    = prod(max(currentXY) - min(currentXY));
                if rectArea < 10,
                    continue;
                end
                badRoiId(i)             = false;
                
            end
            roiData(badRoiId) = [];
            roiNum          = length(roiData);
                
            % output
            obj.RoiData     = roiData;
            DTP_ManageText([], sprintf('AutoDetect : %d ROIs are in use.',roiNum), 'I' ,0)   ;
            
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
        
        % ==========================================
        function [obj] = GetNeighborhoodIndexes(obj, NeighbSize)
            % GetNeighborhoodIndexes - extract neighborhood info
            % Input:
            %   NeighbSize - number of pixels in the neighborhhod (must be even)
            % Output:
            %   NeighbIndex -  which pixel is close to which in the 2D : M^2 x nR*nC/(M/2)^2 matrix
            
            if nargin < 1, NeighbSize = 8; end
            
            if isempty(obj.ImgSize),
                DTP_ManageText([], sprintf('AutoDetect : Please use SetData command define image data.'), 'E' ,0);
                return;
            end
            if NeighbSize ~= round(NeighbSize/2)*2,
                 DTP_ManageText([], sprintf('AutoDetect : NeighbSize must be even.'), 'E' ,0);
                return;
            end
            N                   = NeighbSize;
            N2                  = NeighbSize/2;
            nR                   = obj.ImgSize(1);
            nC                   = obj.ImgSize(2);
            
            % define neighb
            A                   = reshape(1:nR*nC,nR,[]);
            
            % construct overlapping regions
            B{1}                = im2col(A(1:nR-N,1:nC-N),[N N],'distinct');
            B{2}                = im2col(A(N2+1:nR-N2,1:nC-N),[N N],'distinct');
            B{3}                = im2col(A(1:nR-N,N2+1:nC-N2),[N N],'distinct');
            B{4}                = im2col(A(N2+1:nR-N2,N2+1:nC-N2),[N N],'distinct');
            
            obj.NeighbIndex       = B; %im2col(A,[NeighbSize NeighbSize],'sliding');
            
            DTP_ManageText([], sprintf('AutoDetect : neighborhood is computed.'), 'I' ,0);
            
                        
        end
        
        % ==========================================
        function obj = SegmentSpatial(obj, segmType)
            % SegmentSpatial - perform XY segmentation
            % Input:
            %   ImgData    - 3D  image
            % Output:
            %   ImgProbXY - (nRxnC)  2D array of probailities
            
            if nargin < 2, segmType = 1; end;
            if isempty(obj.ImgSize),
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
            
            % average over time
            imgMean         = mean(obj.ImgData,3);
            
            % find mean fluorescence and then estmate noise levels
            imgMeanThr      = mean(mean(imgMean))/2;
            imgStd          = std(obj.ImgData,[],3);
            
            % regions of no activity
            imgBckgBool     = imgMean < imgMeanThr;
            % dbg
            figure,imagesc(imgBckgBool)
            
            imgMeanThr      = mean(imgMean(imgBckgBool));
            imgStdThr       = mean(imgStd(imgBckgBool));
            
            imgBckgBool     = imgMean < (imgMeanThr + imgStdThr);
            figure,imagesc(imgBckgBool)
            
            % save
            %obj.ImgDFF     = im2single(imgData);
            
        end
 
        % ==========================================
        function obj = SegmentSpatialAdaptiveThreshold(obj)
            % SegmentSpatialAdaptiveThreshold - perform XY segmentation using adaptive threshold
            % Input:
            %   ImgData    - 3D  image
            % Output:
            %   ImgBW       -(nRxnC)  2D array of probailities
            
            %if nargin < 2, segmType = 1; end;
            if isempty(obj.ImgSize)
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
%             switch segmType 
%                 case 1, sensThr = 0.8; areaMax = 800;
%                 case 2, sensThr = 0.7; areaMax = 1000;
%                 case 3, sensThr = 0.6; areaMax = 1200;
%                 case 4, sensThr = obj.SegmThr; areaMax = 1200;
%                 otherwise error('Bad segmType')
%             end
            sensThr     = obj.SegmThr;
            areaMax     = obj.AreaMinMax(2);
            areaMin     = obj.AreaMinMax(1);
            
            % average over time
            switch obj.ProcessType
                case 1 % Mean
                    imgMean         = uint16(mean(obj.ImgData,3));
                    figure(141),imagesc(imgMean),title('Mean Image'), ax(1) = gca;
               case 2 % DFF
                    % average over time
                    nT              = obj.ImgSize(3);
                    len10           = ceil(nT*0.1);
                    [imgS,~]        = sort(obj.ImgData,3,'ascend');
                    % to use graythresh we need to rescale the data to uint8
                    imgMax          = mean(imgS(:,:,nT-len10:nT),3);
                    imgMin          = mean(imgS(:,:,1:len10),3);
                    imgDFF          = (imgMax-imgMin)./(imgMin + 100);
                    imgMean         = uint8(imgDFF * 8);
                     figure(142),imagesc(imgMean),title('DFF Image'), ax(1) = gca;
               otherwise
                    error('Bad ProcessType')
            end
                    
            
            % find mean fluorescence and then estmate noise levels
            T               = adaptthresh(imgMean,sensThr,'ForegroundPolarity','dark','NeighborhoodSize',[31 31]);
            imgBW           = imbinarize(imgMean,T);    
            % dbg
            %figure,imagesc(imgBW),title('Adaptive threshold')
            se              = strel('disk',2);
            imgBW           = imopen(imgBW,se);
            
            % borders
            imgBW(1:3,:)    = false;
            imgBW(:,1:3)    = false;
            imgBW(:,end-2:end)    = false;
            imgBW(end-2:end,:)    = false;
            
            % clearing
            cc              = bwconncomp(imgBW); 
            stats           = regionprops(cc,{'area'});
            allArea         = [stats.Area];
            idx             = find(allArea > areaMin & allArea < areaMax); 
            imgBW           = ismember(labelmatrix(cc), idx);            
            
            figure(145 + obj.ProcessType),imagesc(imgBW),title('Opened, Cleared by Area'),ax(2) = gca;
            %figure,imshowpair(imgMean,imgBW,'blend'),title('Cleared by Area')
            linkaxes(ax)
            
            % save
            obj.ImgProbS     = bwlabel(imgBW);
            
        end
                
        % ==========================================
        function obj = SegmentSortingSpatial(obj, figNum)
            % SegmentSorting - perform XY segmentation using sorting between mean and max values 
            % on ROI regions
            % Input:
            %   ImgData    - 3D  image (obj preloaded)
            %   RoiData    - ROIs (obj preloaded)
            %   figNum     - figure to show (0 - none)
            % Output:
            %   imgProbS - (nRxnC)  2D array of probailities
            
            if nargin < 2, figNum = obj.FigNum; end;
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
            % do some spatial filter
            imgData         = imfilter(obj.ImgData,ones(3,3,3)/27);
                        
            % average over time
            len10           = ceil(nT*0.1);
            [imgS,imgI]     = sort(imgData,3,'ascend');
            % to use graythresh we need to rescale the data to uint8
            imgMax          = mean(imgS(:,:,nT-len10:nT),3);
            imgMin          = mean(imgS(:,:,1:len10),3);
            valMax          = max(imgMax(:));
            
            % ROI
            [X,Y]           = meshgrid(1:nC,1:nR);  % export
            
            
            % init prob 
            imgROIs         = repmat(uint8(imgMax./valMax*255),[1 1 3]);  % conf params
            imgThr          = imgMin*0;  % thr level
            %imgEM           = imgMin*0;  % how valid the decision
            
            % segment over the regions
            for m = 1:roiNum,
                
                % get ROI
                currentXY               = obj.RoiData{m}.xyInd;
                maskROI                 = inpolygon(X,Y,currentXY(:,1),currentXY(:,2));
                maskBG                  = imdilate(maskROI,strel('disk',5));
%                 bbox                    = [min(currentXY)-5 max(currentXY)+5];
%                 bbox([1 3])             = max(1,min(nC,round(bbox([1 3]))));
%                 bbox([2 4])             = max(1,min(nR,round(bbox([2 4]))));
%                maskBG                  = false(nR,nC); 
%                maskBG(bbox(2):bbox(4),bbox(1):bbox(3)) = true;
                % only pixels outside ROI
                maskNP                  = maskBG & ~maskROI; % neurophil
                
                % estimate Thr
                %valROI                  = mean(imgMax(maskROI));
                valBG                   = mean(imgMax(maskNP));
                %thr                     = valBG*.5 + valROI*0.5;
                maskNewROI              = false(nR,nC); 
                maskROI                 = maskBG;
                %maskNewROI(maskROI)     = imgMax(maskROI) > thr;
                %maskNewROI(maskROI)     = imgMax(maskROI) > imgMin(maskROI)*1.5 & imgMin(maskROI) > 5;
                maskNewROI(maskROI)     = imgMax(maskROI) > valBG*obj.SegmThr & imgMax(maskROI) > 10;
                if sum(maskNewROI(maskROI)) < 5,
                    DTP_ManageText([], sprintf('AutoDetect : ROI %d is small.',m), 'W' );
                    continue;
                end
                imgThr(maskROI)         = maskNewROI(maskROI) | imgThr(maskROI);
                
                % save for the debug
                [B,~]                   = bwboundaries(maskNewROI,'noholes');
                % extract max region
                [Cnrows,Cncols]         = cellfun(@size, B); 
                [mv,mi]                 = max(Cnrows);
                newXY                   = B{mi};
                if size(newXY,1) < 7,
                    DTP_ManageText([], sprintf('AutoDetect : ROI %d is not extracted well.',m), 'W' );
                    continue;
                end
                effectXY                = newXY(:,[2 1]);
                %imgROIs(pixInd)         = m;
                pos                     = currentXY'; 
                imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','y');
                pos                     = effectXY'; 
                imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','r');
 
                % save
                obj.RoiData{m}.xyEffInd = effectXY;
                
            end
            
            % output
            obj.ImgProbS            = imgROIs;
            
            % show
            if figNum < 1, return; end;
            
            figure(figNum + 1)
            imagesc(imgMin),colorbar,title('imgMin'),ax(1) = gca;impixelinfo;
            figure(figNum + 2)
            imagesc(imgMax),colorbar,title('imgMax'),ax(2) = gca;impixelinfo;
            figure(figNum + 3)
            imagesc(imgThr),colorbar,title('imgThr'),ax(3) = gca;
            figure(figNum + 4)
            imagesc(imgROIs),colorbar,title('imgROIs'),ax(4) = gca;
            linkaxes(ax)
            
        end
        
        % ==========================================
        function obj = SegmentSortingFunctional (obj, figNum)
            % SegmentSortingFunctional - perform XY segmentation using sorting between mean and max values 
            % on ROI regions
            % Input:
            %   ImgData    - 3D  image (obj preloaded)
            %   RoiData    - ROIs (obj preloaded)
            %   figNum     - figure to show (0 - none)
            % Output:
            %   imgProbS - (nRxnC)  2D array of probailities
            
            if nargin < 2, figNum = obj.FigNum+10; end;
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
            % do some spatial filter
            imgData         = imfilter(obj.ImgData,ones(3,3,3)/27);
                        
            % average over time
            len10           = ceil(nT*0.1);
            [imgS,imgI]     = sort(imgData,3,'ascend');
            % to use graythresh we need to rescale the data to uint8
            imgMax          = mean(imgS(:,:,nT-len10:nT),3);
            imgMin          = mean(imgS(:,:,1:len10),3);
            valMax          = max(imgMax(:));
            imgDFF          = (imgMax-imgMin)./(imgMin + 10);
            dffThr          = obj.SegmThr;
            
            % ROI
            [X,Y]           = meshgrid(1:nC,1:nR);  % export
            
            
            % init prob 
            imgROIs         = repmat(uint8(imgMax./valMax*255),[1 1 3]);  % conf params
            imgThr          = imgMin*0;  % thr level
            %imgEM           = imgMin*0;  % how valid the decision
            
            % segment over the regions
            for m = 1:roiNum,
                
                % get ROI
                currentXY               = obj.RoiData{m}.xyInd;
                maskROI                 = inpolygon(X,Y,currentXY(:,1),currentXY(:,2));
                
                
                % estimate Thr
                maskNewROI              = false(nR,nC); 
                maskNewROI(maskROI)     = imgDFF(maskROI) > dffThr & imgMax(maskROI) > 10;
                %maskNewROI(maskROI)     = imgMax(maskROI) > imgMin(maskROI)*2.5;
                if sum(maskNewROI(maskROI)) < 5,
                    DTP_ManageText([], sprintf('AutoDetect : ROI %d is small.',m), 'W' );
                    continue;
                end
                imgThr(maskROI)         = maskNewROI(maskROI) | imgThr(maskROI);
                
                % save for the debug
                [B,~]                   = bwboundaries(maskNewROI,'noholes');
                % extract max region
                [Cnrows,Cncols]         = cellfun(@size, B); 
                [mv,mi]                 = max(Cnrows);
                newXY                   = B{mi};
                if size(newXY,1) < 7,
                    DTP_ManageText([], sprintf('AutoDetect : ROI %d is not extracted well.',m), 'W' );
                    continue;
                end
                effectXY                = newXY(:,[2 1]);
                %imgROIs(pixInd)         = m;
                pos                     = currentXY'; 
                imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','y');
                pos                     = effectXY'; 
                imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','r');
                
                % save
                obj.RoiData{m}.xyEffInd = effectXY;
                
            end
            
            % output
            obj.ImgProbS            = imgROIs;
            
            % show
            if figNum < 1, return; end;
            
            figure(figNum + 1)
            imagesc(imgMin),colorbar,title('imgMin'),ax(1) = gca;impixelinfo;
            figure(figNum + 2)
            imagesc(imgMax),colorbar,title('imgMax'),ax(2) = gca;impixelinfo;
            figure(figNum + 3)
            imagesc(imgDFF),colorbar,title('imgDFF'),ax(3) = gca;
            figure(figNum + 4)
            imagesc(imgROIs),colorbar,title('imgROIs'),ax(4) = gca;
            linkaxes(ax)
            
        end
        
        % ==========================================
        function obj = SegmentSortingMinmal (obj, figNum)
            % SegmentSortingFunctional - perform XY segmentation using sorting between mean and max values 
            % on ROI regions
            % Input:
            %   ImgData    - 3D  image (obj preloaded)
            %   RoiData    - ROIs (obj preloaded)
            %   figNum     - figure to show (0 - none)
            % Output:
            %   imgProbS - (nRxnC)  2D array of probailities
            
            if nargin < 2, figNum = obj.FigNum+30; end;
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
            % do some spatial filter
            imgData         = imfilter(obj.ImgData,ones(3,3,3)/27);
%             imgDataFilt     = imfilter(imgData,ones(5,5,5)/125);
%             imgDataFilt     = imfilter(imgDataFilt,ones(5,5,5)/125);
                        
            % average over time
            len10           = ceil(nT*0.1);
%             len20           = ceil(nT*0.2);
%             len50           = ceil(nT*0.5);
            [imgS,imgI]     = sort(imgData,3,'ascend');
            % to use graythresh we need to rescale the data to uint8
            imgMax          = mean(imgS(:,:,nT-len10:nT),3);
            imgMin          = mean(imgS(:,:,1:len10),3);
%             imgMin20        = mean(imgS(:,:,1:len20),3);
%             imgMin50        = mean(imgS(:,:,1:len50),3);
            valMax          = max(imgMax(:));
            imgDFF          = imgMin;
            dffThr          = mean(imgMin(:)) + obj.SegmThr; % for quiet data
            
            % ROI
            [X,Y]           = meshgrid(1:nC,1:nR);  % export
            
            
            % init prob 
            imgROIs         = repmat(uint8(imgMax./valMax*255),[1 1 3]);  % conf params
            imgThr          = imgMin*0;  % thr level
            %imgEM           = imgMin*0;  % how valid the decision
            
            % segment over the regions
            for m = 1:roiNum,
                
                % get ROI
                currentXY               = obj.RoiData{m}.xyInd;
                maskROI                 = inpolygon(X,Y,currentXY(:,1),currentXY(:,2));
                
                % expand ROI
                maskROI                 = imdilate(maskROI,strel('disk',15));
                
                % estimate Thr
                maskNewROI              = false(nR,nC); 
                maskNewROI(maskROI)     = imgMin(maskROI) > dffThr; % & imgMax(maskROI) > 10;
                %maskNewROI(maskROI)     = imgMax(maskROI) > imgMin(maskROI)*2.5;
                if sum(maskNewROI(maskROI)) < 5,
                    DTP_ManageText([], sprintf('AutoDetect : ROI %d is small.',m), 'W' );
                    continue;
                end
                imgThr(maskROI)         = maskNewROI(maskROI) | imgThr(maskROI);
                
                % save for the debug
                [B,~]                   = bwboundaries(maskNewROI,'noholes');
                % extract max region
                [Cnrows,Cncols]         = cellfun(@size, B); 
                [mv,mi]                 = max(Cnrows);
                newXY                   = B{mi};
                if size(newXY,1) < 7,
                    DTP_ManageText([], sprintf('AutoDetect : ROI %d is not extracted well.',m), 'W' );
                    continue;
                end
                effectXY                = newXY(:,[2 1]);
                %imgROIs(pixInd)         = m;
                pos                     = currentXY'; 
                imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','y');
                pos                     = effectXY'; 
                imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','r');
                
                % save
                obj.RoiData{m}.xyEffInd = effectXY;
                
            end
            
            % output
            obj.ImgProbS            = imgROIs;
            
            % show
            if figNum < 1, return; end;
            
            figure(figNum + 1)
            imagesc(imgMin),colorbar,title('imgMin'),ax(1) = gca;impixelinfo;
            figure(figNum + 2)
            imagesc(imgMax),colorbar,title('imgMax'),ax(2) = gca;impixelinfo;
            figure(figNum + 3)
            imagesc(imgDFF),colorbar,title('imgDFF'),ax(3) = gca;
            figure(figNum + 4)
            imagesc(imgROIs),colorbar,title('imgROIs'),ax(4) = gca;
            linkaxes(ax)
            
        end
        
        % ==========================================
        function obj = SegmentSortingSpatialXY(obj, figNum)
            % SegmentSorting - perform XY segmentation using sorting between mean and max values 
            % on ROI regions
            % Input:
            %   ImgData    - 3D  image (obj preloaded)
            %   RoiData    - ROIs (obj preloaded)
            %   figNum     - figure to show (0 - none)
            % Output:
            %   imgProbS - (nRxnC)  2D array of probailities
            
            if nargin < 2, figNum = 1; end;
            if isempty(obj.ImgSize),
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
            nR              = obj.ImgSize(1);
            nC              = obj.ImgSize(2);
            nT              = obj.ImgSize(3);
%             roiNum          = length(obj.RoiData);
%             if roiNum < 1,
%                 DTP_ManageText([], sprintf('AutoDetect : Please load roi data first.'), 'E' ,0);
%                 return;
%             end
            % do some spatial filter
            imgData         = imfilter(obj.ImgData,ones(3,3,7)/63);
                        
            % average over time
            len10           = ceil(nT*0.05);
            [imgS,imgI]     = sort(imgData,3,'descend');
            % to use graythresh we need to rescale the data to uint8
            imgMin          = mean(imgS(:,:,nT-len10:nT),3)+10;
            imgMax          = mean(imgS(:,:,1:len10),3);
            valMax          = max(imgMax(:));
            
            % ROI
            [X,Y]           = meshgrid(1:nC,1:nR);  % export
            imageIn         = imgMax ./imgMin - 1;
            
            
            % init prob 
            %imgThr          = imageIn > obj.SegmThr;  % thr level
            %imgROIs         = repmat(uint8(imgThr*255),[1 1 3]);  % conf params
            %imgEM           = imgMin*0;  % how valid the decision
            
            % try few thershold levels
            initThr         = obj.SegmThr;
            isGood          = false; cnt = 0;
            while ~isGood && cnt < 10
                imgThr          = imageIn > obj.SegmThr;  % thr level
                stats           = regionprops(imgThr,{'centroid','area'});
                allArea         = [stats.Area];
                maxa            = max(allArea);
                if maxa < 30 % threshold is too high
                    initThr     = 0.9*initThr;
                elseif maxa > (nC*nR)*.05 % too big
                    initThr     = 1.1*initThr;
                else
                    isGood      = true;
                end
                cnt             = cnt + 1;
            end
            if ~isGood || numel(allArea)< 2 || numel(allArea) > 200 ,
                DTP_ManageText([], sprintf('AutoDetect : Please check threshold value.'), 'E' ,0);
            end

            % postprocessing
            %imgThr                  = imdilate(imgThr,strel('disk',1));
            imgThr                  = imfill(imgThr,'holes');
            
            % output
            imgROIs                 = label2rgb(bwlabel(imgThr),'jet','k','shuffle');
            obj.ImgProbS            = imgROIs;
            
            % show
            if figNum < 1, return; end;
            figNum = figNum + 10;
            
            figure(figNum + 1)
            imagesc(imgMin,[0 1000]),colorbar,title('imgMin'),ax(1) = gca;impixelinfo;
            figure(figNum + 2)
            imagesc(imgMax,[0 1000]),colorbar,title('imgMax'),ax(2) = gca;impixelinfo;
            figure(figNum + 3)
            imagesc(imgThr),colorbar,title('imgThr'),ax(3) = gca;
            figure(figNum + 4)
            imagesc(imgROIs),colorbar,title('imgROIs'),ax(4) = gca;
            linkaxes(ax)
            
        end
        
        % ==========================================
        function obj = ComputeDFF(obj, dffType)
            % ComputeDFF - compute dF/F for the column data
            % Input:
            %   ImgData    - 3D  image (obj preloaded)
            %     dffType  - dff type
            % Output:
            %   ImgDFF    -  2D corr template
            
            if nargin < 2, dffType = 1; end
            if isempty(obj.ImgData),
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
            
            % taken from UI_im_browser
            switch dffType,
                case 1, % dFF - mean
                    imgMean           = mean(obj.ImgData,3);
                    imgMean           = imfilter(imgMean,ones(3,3)./9);
                    obj.ImgDFF        = bsxfun(@minus, obj.ImgData,imgMean);
                    obj.ImgDFF        = bsxfun(@times, obj.ImgDFF,1./(100+imgMean));
                    
                    dffName               = 'dFF - Mean';
                    
                case 2, % dFF  - std
                    imgMean           = mean(obj.ImgData,3);
                    imgStd            = std(obj.ImgData,[],3)+eps;
                    obj.ImgDFF        = bsxfun(@minus, obj.ImgDFF,imgMean);
                    obj.ImgDFF        = bsxfun(@times, obj.ImgDFF,1./imgStd);
                    
                    dffName               = 'dFF - STD';
                 
                case 3, % dFF  - Median
                    imgMean           = median(obj.ImgData,3);
                    imgStd            = imgMean + 1; %std(obj.ImgDFF,[],3)+eps;
                    obj.ImgDFF        = bsxfun(@minus, obj.ImgDFF,imgMean);
                    obj.ImgDFF        = bsxfun(@times, obj.ImgDFF,1./imgStd);
                    
                    dffName               = 'dFF - Median';
                    
                    
                case 11, % dFF - mean local
                    
                    filtMean         = ones(3,3,10); filtMean = filtMean./sum(filtMean(:));
                    obj.ImgDFF       = imfilter(obj.ImgData,filtMean,'symmetric');
                    imgMin           = min(obj.ImgData,[],3);
                    imgMax           = max(obj.ImgData,[],3);
                    imgDiff          = imgMax - imgMin + 1;
                    obj.ImgDFF       = bsxfun(@minus, obj.ImgDFF,imgMin);
                    obj.ImgDFF       = bsxfun(@times, obj.ImgDFF,1./imgDiff);
                    
                    dffName               = 'dFF - Mean Local';
                    
                case 12, % dFF  - Mean Filtered
                    
                    filtMean         = ones(7,7,7); filtMean = filtMean./sum(filtMean(:));
                    obj.ImgDFF       = imfilter(obj.ImgData,filtMean,'replicate');
                    imgMin           = min(obj.ImgDFF,[],3);
                    imgMax           = max(obj.ImgDFF,[],3);
                    
                    imgMean           = imgMax .*0.1 + imgMin .* 0.9;
                    obj.ImgDFF        = bsxfun(@minus, obj.ImgDFF,imgMean);
                    obj.ImgDFF        = bsxfun(@times, obj.ImgDFF,1./imgMean);
                    
                    dffName               = 'dFF - Median';
            
                case 13, % dFF  - Mean Filtered + Rize detect
                    
                    filtMean         = ones(5,5,7); filtMean = filtMean./sum(filtMean(:));
                    imgDataFilt      = imfilter(obj.ImgData,filtMean,'replicate','full');
                    obj.ImgDFF       = imgDataFilt(:,:,6+(1:obj.ImgSize(3))) - imgDataFilt(:,:,1+(1:obj.ImgSize(3)));
                    imgThr           = mean(mean(std(obj.ImgDFF,[],3),1),2)*3 + 10;
                    %imgMax           = max(obj.ImgDFF,[],3);
                    
                    %imgMean           = imgMax .*0.1 + imgMin .* 0.9;
                    %obj.ImgDFF        = bsxfun(@minus, obj.ImgDFF,imgMean);
                    obj.ImgDFF        = bsxfun(@times, obj.ImgDFF,1./imgThr);
                    
                    dffName               = 'dFF - Rize Time';
                    
                case 14, % dFF  - 10% Min
                    
                    filtMean         = ones(3,3,3); filtMean = filtMean./sum(filtMean(:));
                    imgDataFilt      = imfilter(obj.ImgData,filtMean,'replicate');
                    obj.ImgDFF       = sort(imgDataFilt,3,'ascend');
                    imgMin          = mean(obj.ImgDFF(:,:,1:ceil(obj.ImgSize(3)/10)),3);
                    imgMean           = imgMin + 100;
                    
                    %imgMean           = imgMax .*0.1 + imgMin .* 0.9;
                    obj.ImgDFF        = bsxfun(@minus, imgDataFilt,imgMin);
                    obj.ImgDFF        = bsxfun(@times, obj.ImgDFF,1./imgMean);
                    
                    dffName               = 'dFF - 10%';
                    
                case 15, % dFF  - Max Filtered 
                    
                    filtMean         = ones(5,5,9); filtMean = filtMean./sum(filtMean(:));
                    obj.ImgDFF       = imfilter(obj.ImgData,filtMean,'replicate');
                    imgMin           = min(obj.ImgDFF,[],3);
                    imgMax           = max(obj.ImgDFF,[],3);
                    imgThr           = mean(mean(std(obj.ImgDFF,[],3),1),2)*3 + 10;
                    %imgMax           = max(obj.ImgDFF,[],3);
                    
                    %imgMean           = imgMax .*0.1 + imgMin .* 0.9;
                    %obj.ImgDFF        = bsxfun(@minus, obj.ImgDFF,imgMean);
                    obj.ImgDFF        = bsxfun(@times, obj.ImgDFF,1./imgThr);
                    
                    dffName               = 'dFF - Max Filter';
                    
                    
              otherwise
                    error('Unknown dFF')
            end;
            
            % save for show - destroy original
            %obj.ImgData  = obj.ImgDFF;
            DTP_ManageText([], sprintf('AutoDetect : dFF selected : %s',dffName), 'I' ,0)   ;
           
        end
        
        % ==========================================
        function obj = SignalEmphasizeDFF(obj, emphType)
            % SignalEmphasizeDFF - compute dF/F signal emphasasis that utilizes properties of dF/F
            % signals.
            % Input:
            %   ImgDFF    - 3D image (obj preloaded)
            %     emphType  - emphasasis type
            % Output:
            %   ImgDFF    -  3D image emphasized
            
            if nargin < 2, emphType = 1; end
            if isempty(obj.ImgDFF),
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first and compute dFF.'), 'E' ,0);
                return;
            end
            
            [nR,nC,nT]         = size(obj.ImgDFF);
            
            % taken from UI_im_browser
            switch emphType,
                case 1, % none
                    
                    emphName               = 'None';
                case 2, % dFF - first Grad then Denoise
                    % gradient
                    dt                  = 1:nT-1;
                    obj.ImgDFF(:,:,dt)  = obj.ImgDFF(:,:,dt+1)- obj.ImgDFF(:,:,dt);

                    % signal by remove noise
                    noiseStd            = mean(mean(std(obj.ImgDFF,[],3)));
                    obj.ImgDFF(abs(obj.ImgDFF) < noiseStd*3) = 0;
                    
                    emphName               = 'Sig+Noise*3';
                case 3, % dFF  - std
                    % signal by remove noise
                    noiseStd            = mean(mean(std(obj.ImgDFF,[],3)));
                    obj.ImgDFF(abs(obj.ImgDFF) < noiseStd*3) = 0;
                    
                    % gradient
                    dt                  = 1:nT-1;
                    obj.ImgDFF(:,:,dt)  = obj.ImgDFF(:,:,dt+1)- obj.ImgDFF(:,:,dt);
                    
                    emphName            = 'Noise*3+Sig';
                    
                case 4, % dFF  - std soft
                    % signal by suppress noise
                    noiseStd            = mean(mean(std(obj.ImgDFF,[],3)));
                    obj.ImgDFF          = (obj.ImgDFF ./ noiseStd*3).^1;
                    
                    % gradient
                    %dt                  = 1:nT-1;
                    %obj.ImgDFF(:,:,dt)  = obj.ImgDFF(:,:,dt+1)- obj.ImgDFF(:,:,dt);
                    
                    emphName            = 'Noise*1+Soft';

                case 5, % dFF  - std soft
                    % signal by suppress noise
                    noiseStd            = mean(mean(std(obj.ImgDFF,[],3)));
                    obj.ImgDFF          = (obj.ImgDFF ./ noiseStd*3).^3;
                    
                    % gradient
                    %dt                  = 1:nT-1;
                    %obj.ImgDFF(:,:,dt)  = obj.ImgDFF(:,:,dt+1)- obj.ImgDFF(:,:,dt);
                    
                    emphName            = 'Noise*3+Soft';
                    
                    
                case 6, % dFF  - std soft + median
                    % signal by suppress noise
                    noiseStd            = mean(mean(std(obj.ImgDFF,[],3)));
                    obj.ImgDFF          = (obj.ImgDFF ./ noiseStd*3).^3;
                    
                    % med filter
                    for t = 1:nT,
                        obj.ImgDFF(:,:,t)  = medfilt2(obj.ImgDFF(:,:,t),[3 3]);
                    end
                    
                    emphName            = 'Noise*3+Soft+Med';
                    
                    
              otherwise
                    error('Unknown dFF')
            end;
            
            DTP_ManageText([], sprintf('AutoDetect : Emphasize selected : %s',emphName), 'I' ,0)   ;
           
        end
        
        % ==========================================
        function obj = SegmentTimeSVD(obj, figNum)
            % SegmentTimeSVD - perform time based segmentation using time information from each pixel
            % Input:
            %   ImgData    - 3D  image (obj preloaded)
            %   figNum     - figure to show (0 - none)
            % Output:
            %   imgProbT   - (nRxnC)  2D array of probailities
            
            if nargin < 2, figNum = 1; end;
            if isempty(obj.ImgSize),
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
            % params
            dffType         = 1;
            emphType        = 5;   % signal emphsize type
            
            nR              = obj.ImgSize(1);
            nC              = obj.ImgSize(2);
            nT              = obj.ImgSize(3);
            
            % get neighborhoods
            obj             = GetNeighborhoodIndexes(obj, obj.NeighbSize);            
            
            % dFF
            obj             = ComputeDFF(obj, dffType);
            
            % Signal Emphasize
            obj             = SignalEmphasizeDFF(obj, emphType);
            
            % init prob 
            imgProbT        = zeros(nR,nC);  % conf params
            imgMeanThr      = imgProbT;  % thr level
            imgCount        = imgProbT;  % how many hits per pixels
            
            % segment over the regions
            for m = 1:length(obj.NeighbIndex),
                [nRow,nCol] = size(obj.NeighbIndex{m});
                imgMeanCol  = zeros(nRow,nT);
                for k = 1:nCol,
                    % convert to column
                    ind             = obj.NeighbIndex{m}(:,k);
                    for t = 1:nT,
                        imgMeanTmp       = obj.ImgDFF(:,:,t);
                        imgMeanCol(:,t)  = imgMeanTmp(ind);
                    end
                    
                    % prepare
                    X          = imgMeanCol';
                    X          = X - repmat(mean(X,2),1,nRow);
                    %Y          = Y*diag(1./std(Y));

                    %
                    % svd
                    [U,S,V]     = svd(X);
                    S           = diag(S);
                    em          = 1  - S(2)/S(1); % how large is the gap
                    
                    % segment
                    [maxV,maxI] = max(abs(V(:,1)));
                    maxS        = sign(V(maxI,1));
                    groupBool   = maxV/2 <= V(:,1).*maxS; % make it positive
                    lev         = maxV;
                    
                    % save the results
                    groupInd             = ind(groupBool);
                    imgMeanThr(groupInd) = imgMeanThr(groupInd) + lev;
                    imgProbT(groupInd)   = imgProbT(groupInd) + em;
                    imgCount(ind)        = imgCount(ind) + 1;
                    
                    if figNum < 11, continue; end
                    ind2             = [1 2 3];
                    [y,x]            = ind2sub([nR nC],ind([1 end]));
                    figure(figNum+1)
                    plot(V(:,ind2)),legend(num2str(S(ind2)))
                    title(sprintf('Time Segmentation : from  (%d ,%d) to (%d ,%d)',y(1),x(1),y(2),x(2)))
                    
                end
            end
            % normalize
            imgCount(imgCount < .1) = 1;
            imgMeanThr              = imgMeanThr./imgCount;
            imgProbT                = imgProbT./imgCount;
            
            % output
            obj.ImgProbT            = imgProbT;
            
            % show
            if figNum < 1, return; end;
            
            figure(figNum + 2)
            imagesc(imgMeanThr),colorbar,title('imgMeanThr')
            figure(figNum + 3)
            imagesc(imgProbT),colorbar,title('imgProbT')
            figure(figNum + 4)
            imagesc(imgCount),colorbar,title('imgCount')
            
            
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
            if isempty(obj.ImgSize),
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
            
            nR              = obj.ImgSize(1);
            nC              = obj.ImgSize(2);
            nT              = obj.ImgSize(3);
            
            
            % params
            switch segmType,
                case 1,
                    % params
                    dffType         = 1;
                    emphType        = 4;   % signal emphsize type
                    dffThr          = 1;   % to be sure
                    filtThr         = ones(5,5,5); filtThr = filtThr./sum(filtThr(:));
                    minAreaThr      = nR/40*nC/40;
                   
                case 2,
 
                    % params
                    dffType         = 12;
                    emphType        = 5;   % signal emphasize type
                    dffThr          = 3;   % to be sure
                    filtThr         = ones(5,5,5); filtThr = filtThr./sum(filtThr(:));
                    minAreaThr      = nR/40*nC/40;
                    
                case 3,
 
                    % params
                    dffType         = 3;
                    emphType        = 6;   % signal emphasize type
                    dffThr          = 5;   % to be sure
                    filtThr         = ones(5,5,5); filtThr = filtThr./sum(filtThr(:));
                    minAreaThr      = nR/50*nC/50;
 
                case 4,
 
                    % params
                    dffType         = 14;  % local mean
                    emphType        = 4;   % signal emphasize type
                    dffThr          = 10;   % to be sure
                    filtThr         = ones(5,5,5); filtThr = filtThr./sum(filtThr(:));
                    minAreaThr      = nR/50*nC/50;
 
                case 11,
 
                    % params
                    dffType         = 11;  % local mean
                    emphType        = 1;   % signal emphasize type
                    dffThr          = 0.4;   % to be sure
                    filtThr         = ones(5,5,5); filtThr = filtThr./sum(filtThr(:));
                    minAreaThr      = nR/50*nC/50;
                    
                    
                otherwise
                    error('Bad segmType')
            end
            
            
            % dFF
            obj             = ComputeDFF(obj, dffType);
            
            % Signal Emphasize
            obj             = SignalEmphasizeDFF(obj, emphType);
            
            % threshold and filter - the most probable locations
            imgMeanThr      = single(obj.ImgDFF > dffThr);
            
            % expand these locations and lower threshold around them
            imgMeanThr      = imfilter(imgMeanThr,filtThr);
            imgMeanThr      = obj.ImgDFF > (dffThr - imgMeanThr*0.2);
            
            % fill small holes
            imgMeanThr      = imfill(imgMeanThr,'holes');
            
            % label
            %[imgL, cellNum] = bwlabeln(imgMeanThr);
            CC              = bwconncomp(imgMeanThr,26);
            cellNum         = CC.NumObjects;
            
            % filter objects by their duration and size
            isValid         = false(cellNum,1);
            for k = 1:cellNum,
                [y,x,t] = ind2sub(size(imgMeanThr),CC.PixelIdxList{k});
                dy      = max(y) - min(y);
                dx      = max(x) - min(x);
                dt      = max(t) - min(t);
                pNum    = length(y);
                
                % conditions
                isValid(k) = dt > 5;
                isValid(k) = isValid(k) && (dx*dy > minAreaThr);
            end
            CC.PixelIdxList = CC.PixelIdxList(isValid);
            CC.NumObjects   = sum(isValid);
            
            % output
            obj.EventCC     = CC;
            obj.ImgDFF      = single(labelmatrix(CC));
            DTP_ManageText([], sprintf('AutoDetect : Found %d active regions.',CC.NumObjects), 'I' ,0);
            
        end

        % ==========================================
        function obj = SegmentByVoting(obj, figNum)
            % SegmentByVoting - perform segmentation by edge voting
            % Input:
            %   ImgData    - 3D  image (obj preloaded)
            %   RoiData    - ROIs (obj preloaded)
            %   figNum     - figure to show (0 - none)
            % Output:
            %   imgProbS - (nRxnC)  2D array of probailities
            
            if nargin < 2, figNum = obj.FigNum; end;
            if isempty(obj.ImgSize)
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
            nR              = obj.ImgSize(1);
            nC              = obj.ImgSize(2);
            nT              = obj.ImgSize(3);
%             roiNum          = length(obj.RoiData);
%             if roiNum < 1
%                 DTP_ManageText([], sprintf('AutoDetect : Please load roi data first.'), 'E' ,0);
%                 return;
%             end
            % do some spatial filter
            imgData         = mean(obj.ImgData,3); %imfilter(obj.ImgData,ones(3,3,3)/27);
            
            % compute gradients
            [Gx, Gy]        = imgradientxy(imgData);
            [Gx, Gy]        = deal(Gx./4,Gy./4); % rescale for Sobel
            [Gmag, Gdir]    = imgradient(Gx, Gy);
            
            % filter edges
            imgMagMask      = double(Gmag > 30);
            Gmag            = Gmag.*imgMagMask;
            Gx              = Gx.*imgMagMask;
            Gy              = Gy.*imgMagMask;
            
            
            % do voting
            cellSize        = 10;  % search region
            imgMagPad       = padarray(Gmag*0,[cellSize cellSize],'replicate','both');
            imgGxPad        = imgMagPad;
            imgGyPad        = imgMagPad;
            
            % ROI
            [xi,yi]         = deal(1:nC,1:nR);  % export
            xiv             = xi +  cellSize;             
            yiv             = yi +  cellSize;             
            
            % start voting
            for dx = -cellSize:cellSize
                for dy = -cellSize:cellSize
                    xin         = xiv + dx;
                    yin         = yiv + dy;
                    imgMagPad(yin,xin) = imgMagPad(yin,xin) + Gmag;
                    imgGxPad(yin,xin)  = imgGxPad(yin,xin)  + Gx;
                    imgGyPad(yin,xin)  = imgGyPad(yin,xin)  + Gy;
                end
            end
            imgMagPad       = imgMagPad ./ cellSize^2;
            imgGxPad        = imgGxPad ./ cellSize^2;
            imgGyPad        = imgGyPad ./ cellSize^2;
            
            % cut 
            [imgMag,imgGx,imgGy] = deal(imgMagPad(yiv,xiv), imgGxPad(yiv,xiv), imgGyPad(yiv,xiv));
            
            % most probable 
            pixThr          = pi*cellSize*2;
            imgMagMaxBW     = imregionalmax(imgMag);
            imgGrad         = abs(imgGx) + abs(imgGy); 
            imgGradMinBW    = imregionalmin(imgGrad);
            imgGradMinBW    = imdilate(imgGradMinBW,ones(5)); % increase prob of hit
            imgCenters      = imgMag > pixThr & imgGrad < 20 & imgMagMaxBW & imgGradMinBW;
            
%             % compute centers of the detected regions
%             s               = regionprops(imgCenters,'centroid');
%             centroids       = cat(1, s.Centroid);
%             
%             % vote back on edges
%             [dxArray,dyArray]         = meshgrid(-cellSize:cellSize);
%             
%             % start voting
%             for dx = -cellSize:cellSize
%                 for dy = -cellSize:cellSize
%                     xin         = xiv + dx;
%                     yin         = yiv + dy;
%                     imgMagPad(yin,xin) = imgMagPad(yin,xin) + Gmag;
%                     imgGxPad(yin,xin)  = imgGxPad(yin,xin)  + Gx;
%                     imgGyPad(yin,xin)  = imgGyPad(yin,xin)  + Gy;
%                 end
%             end

            
            
            
%             
%             % init prob 
%             imgROIs         = repmat(uint8(imgMax./valMax*255),[1 1 3]);  % conf params
%             imgThr          = imgMin*0;  % thr level
%             %imgEM           = imgMin*0;  % how valid the decision
            
%             % segment over the regions
%             for m = 1:roiNum,
%                 
%                 % get ROI
%                 currentXY               = obj.RoiData{m}.xyInd;
%                 maskROI                 = inpolygon(X,Y,currentXY(:,1),currentXY(:,2));
%                 maskBG                  = imdilate(maskROI,strel('disk',5));
% %                 bbox                    = [min(currentXY)-5 max(currentXY)+5];
% %                 bbox([1 3])             = max(1,min(nC,round(bbox([1 3]))));
% %                 bbox([2 4])             = max(1,min(nR,round(bbox([2 4]))));
% %                maskBG                  = false(nR,nC); 
% %                maskBG(bbox(2):bbox(4),bbox(1):bbox(3)) = true;
%                 % only pixels outside ROI
%                 maskNP                  = maskBG & ~maskROI; % neurophil
%                 
%                 % estimate Thr
%                 %valROI                  = mean(imgMax(maskROI));
%                 valBG                   = mean(imgMax(maskNP));
%                 %thr                     = valBG*.5 + valROI*0.5;
%                 maskNewROI              = false(nR,nC); 
%                 maskROI                 = maskBG;
%                 %maskNewROI(maskROI)     = imgMax(maskROI) > thr;
%                 %maskNewROI(maskROI)     = imgMax(maskROI) > imgMin(maskROI)*1.5 & imgMin(maskROI) > 5;
%                 maskNewROI(maskROI)     = imgMax(maskROI) > valBG*obj.SegmThr & imgMax(maskROI) > 10;
%                 if sum(maskNewROI(maskROI)) < 5,
%                     DTP_ManageText([], sprintf('AutoDetect : ROI %d is small.',m), 'W' );
%                     continue;
%                 end
%                 imgThr(maskROI)         = maskNewROI(maskROI) | imgThr(maskROI);
%                 
%                 % save for the debug
%                 [B,~]                   = bwboundaries(maskNewROI,'noholes');
%                 % extract max region
%                 [Cnrows,Cncols]         = cellfun(@size, B); 
%                 [mv,mi]                 = max(Cnrows);
%                 newXY                   = B{mi};
%                 if size(newXY,1) < 7,
%                     DTP_ManageText([], sprintf('AutoDetect : ROI %d is not extracted well.',m), 'W' );
%                     continue;
%                 end
%                 effectXY                = newXY(:,[2 1]);
%                 %imgROIs(pixInd)         = m;
%                 pos                     = currentXY'; 
%                 imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','y');
%                 pos                     = effectXY'; 
%                 imgROIs                 = insertShape(imgROIs,'polygon',pos(:)','color','r');
%  
%                 % save
%                 obj.RoiData{m}.xyEffInd = effectXY;
%                 
%             end
%             
            % output
            %obj.ImgProbS            = imgROIs;
            
            % show
            if figNum < 1, return; end
            figure(figNum + 1)
            imagesc(imgData),colorbar,title('Data'),ax(1) = gca;
            figure(figNum + 2)
            imagesc(imgMag),colorbar,title('Mag'),ax(2) = gca;
            figure(figNum + 3)
            imagesc(imgGrad),colorbar,title('Grad'),ax(3) = gca;
            figure(figNum + 4)
            imagesc(imgGy),colorbar,title('Gy'),ax(4) = gca;
            figure(figNum + 5)
            imagesc(imgCenters),colorbar,title('Centers'),ax(5) = gca;
            figure(figNum + 6)
            imagesc(imgMagMaxBW),colorbar,title('Reg Max'),ax(6) = gca;
            figure(figNum + 7)
            imagesc(imgGradMinBW),colorbar,title('Reg Min'),ax(7) = gca;
            linkaxes(ax)
            
        end
        
        % ==========================================
        function [obj,strROI] = ExtractROI_old(obj)
            % SegmentSpaceTime - perform space and time based segmentation using dFF info of the entire movie
            % Input:
            %   EventCC   - list of Connected Components
            %   ImgDFF    - 3D  image (obj preloaded)
            % Output:
            %   strROI     - cell list of ROIs with xyInd - field
            
            strROI          = {};
            if isempty(obj.EventCC),
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first and run detection.'), 'E' ,0);
                return;
            end
            % params
            cellNum         = obj.EventCC.NumObjects;
            if cellNum < 1,
                DTP_ManageText([], sprintf('AutoDetect : No ROIs detected. Culd be problems in SpaceTime Segmentation or Data.'), 'E' ,0);
                return;
            end
            
            % filter events by their duration and size
            for k = 1:cellNum,
                [y,x,t]     = ind2sub(size(obj.ImgDFF),obj.EventCC.PixelIdxList{k});
                
                % find the widest area
                ti          = min(t):max(t);
                imgTmp      = sum(obj.ImgDFF(:,:,ti) == k,3);
                boundTmp    = bwboundaries(imgTmp > 0,'noholes');
                %[yp,xp]     = find(imgPerim);
                
                % assign
                yx          = boundTmp{1};
                strROI{k}.xyInd = yx(:,[2 1]);
                
                % conditions
            end
            
            % remove overlaps
            
            % output
            DTP_ManageText([], sprintf('AutoDetect : Converted to %d ROIs.',cellNum), 'I' ,0);
            
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
            if isempty(obj.ImgProbS)
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first and run detection.'), 'E' ,0);
                return;
            end
            % params
            clustNum         = max(obj.ImgProbS(:));
            if clustNum < 2
                DTP_ManageText([], sprintf('AutoDetect : No clsuters detected. Could be problems in Clustering of the Data.'), 'E' ,0);
                return;
            end
            
            [nR,nC]                 = size(obj.ImgProbS);
            cellPerimeterLenMax     = (nR+nC)*0.1;
            cellPerimeterLenMin     = 5*4;
            cellInd                 = 0;
            cellColors              = jet(clustNum);
            for k = 1:clustNum
               
               % extract ROI data
               imgClust               = obj.ImgProbS == k;
               imgClust               = imdilate(imgClust,ones(2));
               % get cells
               [cellB,imgL,cellNum]    = bwboundaries(imgClust,'noholes');
               % extract max region
               [Cnrows,Cncols]        = cellfun(@size, cellB); 
               
               % start creating ROIs
               for c = 1:cellNum
                   
                   % check size and validity
                   if Cnrows(c) < cellPerimeterLenMin, continue; end
                   if Cnrows(c) > cellPerimeterLenMax, continue; end
                   cellInd          = cellInd + 1;
                   newXY            = cellB{c};

                   roiLast          = TPA_RoiManager();
                   roiLast          = Init(roiLast,roiLast.ROI_TYPES.FREEHAND);
                   roiLast.CountId  = cellInd;
                   roiLast.CellPart = k;  % helps with colors
                   roiLast          = SetColor(roiLast,cellColors(k,:));
                   roiLast          = SetName(roiLast,sprintf('AROI:Z%d:%04d',obj.SliceId,cellInd));
                   %roiLast.xyInd    = newXY(:,[2 1]);
                   roiLast          = InitView(roiLast,newXY(:,[2 1]));
                   roiLast.PixInd   = find(imgL == c);
                   roiLast.zInd     = obj.SliceId;  % z -stack
                   
                   strROI{cellInd,1}  = roiLast;
               end

            end
            
            % output
            obj.RoiData     = strROI;
            DTP_ManageText([], sprintf('AutoDetect : Extracted %d ROIs.',cellInd), 'I' ,0);
            
%             if FigNum < 1, return; end
%             [obj,imgCell]   = ConvertRoiToImage(obj,obj.RoiData, obj.SliceId);
%             obj.ImgROI      = imgCell;
            % run show svd after that
            
            
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
        function obj = TestSegmentSpatial(obj)
            
            % TestSegmentSpatial - performs testing of the image data using fluorescence of the
            % time average. 
            
            figNum                  = 31;
            segmType                = 1;
            dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\M2\2_20_14\2_20_14_m2__002.tif';
            
            obj                     = LoadImageData(obj, dataPath);
            %obj                     = SegmentSpatial(obj, segmType);
            obj                     = SegmentSpatialOtsu(obj, figNum);
            %obj                     = ShowSpatialSegm(obj, figNum);
            
            obj                     = DeleteData(obj);
            
        end
        
        % ==========================================
        function obj = TestSegmentTime(obj)
            
            % TestSegmentTime - performs testing of the time based segmentation
            % of pixels according to the activity
            
            figNum                  = 31;
            segmType                = 1;
            dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\M2\2_20_14\2_20_14_m2__002.tif';
            
            obj                     = LoadImageData(obj, dataPath);
            obj                     = SegmentTimeSVD(obj, figNum);
            obj                     = DeleteData(obj);
            
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

        % ==========================================
        function obj = TestSegmentByVoting(obj)
            
            % TestSegmentByVoting - performs testing of the space and time based segmentation
            % of pixels according to the activity
            
            figNum                  = 31;
            segmType                = 1;
            %dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\M2\2_20_14\2_20_14_m2__002.tif';
            %dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\m8\02_10_14\2_9_14_m8__003.tif'; % 256 x 256 x 900 - stable
            dataPath                = 'C:\LabUsers\Uri\Data\Janelia\Imaging\D10\8_6_14_cno\8_6_14_d10_008.tif'; % 
            
            obj                     = LoadImageData(obj, dataPath);
            obj                     = SegmentByVoting(obj, figNum);
            
            %obj                     = DeleteData(obj);
            
        end
        
        
    end% methods
end% classdef