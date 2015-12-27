classdef TPA_ManageRoiAutodetect
    % TPA_ManageRoiAutodetect - finds cell data in tif TwoPhoton imags
    % Uses algorithm with local SVD decomposition in time to detect similar pixels
    % Inputs:
    %       none
    % Outputs:
    %       strROI
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
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
                                                        % contains overlapping regions
        %NeighbSize                  = 32;               % size of neighb region NeighbSize x NeighbSize for analysis                                       
        
        %ImgProbS                    = [];               % spatial segm results
        %ImgProbT                    = [];               % time segm results
        
        EventCC                     = [];               % event connectivity structure
        
        ImgDataIs4D                 = false;            % remember that image data was
        
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
        % ---------------------------------------------
        % ==========================================
        function obj = DeleteData(obj)
            % DeleteData - will remove stored video data
            % Input:
            %   internal -
            % Output:
            %   ImgData,ImgDFF  -  removed
            
            % clean it up
            obj.ImgData     = [];
            obj.ImgDFF      = [];
            obj.EventCC     = [];
            DTP_ManageText([], sprintf('AutoDetect : Clearing intermediate results.'), 'W' ,0);
           
        end
        % ---------------------------------------------
        
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
            obj             = SetData(obj,imgData);
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SetData(obj,imgData)
            % SetData - check the data before convert it to 3D 
            % Input:
            %   imgData - 3D-4D data stored after Image Load
            % Output:
            %   obj.ImgData - (nRxnCxnT)  3D array
            
            if nargin < 2, error('Reuires image data as input'); end;
            % remove dim
            [nR,nC,nZ,nT] = size(imgData);
            DTP_ManageText([], sprintf('AutoDetect : Inout image dimensions R-%d,C-%d,Z-%d,T-%d.',nR,nC,nZ,nT), 'I' ,0)   ;

            
            if nT > 1 && nZ > 1,
                DTP_ManageText([], sprintf('AutoDetect : Multiple Z stacks are detetcted. Working with first one.'), 'W' ,0);
                nZ = 1;
            end
            % data is 4D :  make it 3D
            if nT > 1 && nZ < 2,
                imgData         = squeeze(imgData(:,:,nZ,:));
                obj.ImgDataIs4D = true;
            end
            % output
            imageDataSize   = size(imgData);
            obj.ImgData     = single(imgData);
            obj.ImgSize     = imageDataSize;
            
            DTP_ManageText([], sprintf('AutoDetect : %d images are in use.',imageDataSize(3)), 'I' ,0)   ;
            
            
        end
        % ---------------------------------------------
        
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
        % ---------------------------------------------
        
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
        % ---------------------------------------------
        
        % ==========================================
        function obj = SegmentSpatialOtsu(obj, figNum)
            % SegmentSpatialOtsu - perform XY segmentation using Otsu method
            % on overlapping regions
            % Input:
            %   ImgData    - 3D  image (obj preloaded)
            %   figNum     - figure to show (0 - none)
            % Output:
            %   imgProbS - (nRxnC)  2D array of probailities
            
            if nargin < 2, figNum = 1; end;
            if isempty(obj.ImgSize),
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first.'), 'E' ,0);
                return;
            end
            
            % get neighborhoods
            obj             = GetNeighborhoodIndexes(obj, obj.NeighbSize);            
            
            % average over time
            imgMean         = mean(obj.ImgData,3);
            % to use graythresh we need to rescale the data to uint8
            imgMean         = imgMean./max(imgMean(:));
            
            % init prob 
            imgProbS        = imgMean*0;  % conf params
            imgMeanThr      = imgMean*0;  % thr level
            imgCount        = imgMean*0;  % how many hits per pixels
            
            % segment over the regions
            for m = 1:length(obj.NeighbIndex),
                nCol = size(obj.NeighbIndex{m},2);
                for k = 1:nCol,
                    ind             = obj.NeighbIndex{m}(:,k);
                    [lev, em]       = graythresh(imgMean(ind));
                    
                    % save the results
                    imgMeanThr(ind) = imgMeanThr(ind) + lev;
                    imgProbS(ind)   = imgProbS(ind) + em;
                    imgCount(ind)   = imgCount(ind) + 1;
                end
            end
            % normalize
            imgCount(imgCount < .1) = 1;
            imgMeanThr              = imgMeanThr./imgCount;
            imgProbS                = imgProbS./imgCount;
            
            % output
            obj.ImgProbS            = imgProbS;
            
            % show
            if figNum < 1, return; end;
            
            figure(figNum + 1)
            imagesc(imgMean),colorbar,title('imgMean')
            figure(figNum + 2)
            imagesc(imgMeanThr),colorbar,title('imgMeanThr')
            figure(figNum + 3)
            imagesc(imgProbS),colorbar,title('imgProbS')
            figure(figNum + 4)
            imagesc(imgCount),colorbar,title('imgCount')
            
            
        end
        % ---------------------------------------------
        
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
                    
                    filtMean         = ones(3,3,20); filtMean = filtMean./sum(filtMean(:));
                    obj.ImgDFF       = imfilter(obj.ImgData,filtMean,'replicate');
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
                    
                    filtMean         = ones(5,5,7); filtMean = filtMean./sum(filtMean(:));
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
        % ---------------------------------------------
        
%         % ==========================================
%         function [obj, imgDataCol] = SignalEmphasize(obj, imgDataCol,emphType)
%             % SignalEmphasize - compute dF/F signal emphasasis that utilizes properties of dF/F
%             % signals.
%             % Input:
%             %   imgDataCol    - 2D nT x nPix image (obj preloaded)
%             %     emphType  - emphasasis type
%             % Output:
%             %   imgDataCol    -  2D nT x nPix emphasized
%             
%             if nargin < 3, emphType = 1; end
%             if isempty(obj.ImgDFF),
%                 DTP_ManageText([], sprintf('AutoDetect : Please load image data first and compute dFF.'), 'E' ,0);
%                 return;
%             end
%             
%             X                   = imgDataCol;
%             
%             % taken from UI_im_browser
%             switch emphType,
%                 case 1, % none
%                     Z                   = X;
%                     emphName               = 'None';
%                 case 2, % dFF - mean
%                     % Compute matrices for GSVD
%                     % gradient
%                     [N,numV]            = size(X);
%                     Z                   = X*0;
%                     dt                  = 1:N-2;
%                     Z(dt,:)             = X(dt+2,:)- X(dt,:);
% 
%                     % signal by remove noise
%                     Z                   = X;
%                     noiseStd            = mean(std(Z));
%                     Z(abs(Z) < noiseStd*3) = 0;
%                     
%                     emphName               = 'Sig+Noise*3';
%                 case 3, % dFF  - std
%                     % Compute matrices for GSVD
%                     % signal by remove noise
%                     noiseStd            = mean(std(X));
%                     X(abs(X) < noiseStd*3) = 0;
%                     
%                     
%                     % gradient
%                     [N,numV]            = size(X);
%                     Z                   = X*0;
%                     dt                  = 1:N-2;
%                     Z(dt,:)             = X(dt+2,:)- X(dt,:);
%                     emphName            = 'Noise*3+Sig';
%                     
%               otherwise
%                     error('Unknown dFF')
%             end;
%             
%             imgDataCol = Z;
%             DTP_ManageText([], sprintf('AutoDetect : Emphasaze selected : %s',emphName), 'I' ,0)   ;
%            
%         end
%         % ---------------------------------------------
        
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
        % ---------------------------------------------
        
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
        % ---------------------------------------------
 
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
                    
                    
                otherwise
                    error('Bad segmType')
            end
            
            
            % dFF
            obj             = ComputeDFF(obj, dffType);
            
            % Signal Emphasize
            obj             = SignalEmphasizeDFF(obj, emphType);
            
            % threshold and filter
            imgMeanThr      = obj.ImgDFF > dffThr;
            imgMeanThr      = imfilter(imgMeanThr,filtThr);
            
            % threshold again
            imgMeanThr      = imgMeanThr > 0.75;
            
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
        % ---------------------------------------------

        % ==========================================
        function [obj,strROI] = ExtractROI(obj)
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
        % ---------------------------------------------
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
        % ---------------------------------------------
        
        
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
        % ---------------------------------------------
        
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
        % ---------------------------------------------
                
%         % ==========================================
%         function isOK = CheckResult(obj,figNum, refShift, estShift)
%             % CheckResult - computes error and shows mostion estimation results 
%             
%             if nargin  < 2, figNum = 1; end;
%             if nargin  < 3, refShift = [0 0]; end;
%             if nargin  < 4, estShift = [0 0]; end;
%             
%             errShift            = refShift + estShift; % opposite directions
%             algErr              = (std(errShift));
%             t                   = 1:size(refShift,1);
%             
%             figure(figNum),set(figNum,'Tag','AnalysisROI');
%             ii = 1; subplot(2,1,ii),plot(t,[refShift(:,ii) estShift(:,ii) errShift(:,ii)]),legend('ref','est','err')
%             ylabel('y [pix]'),
%             title(sprintf('Shift Estimation and Error y: %5.3f [pix], x: %5.3f [pix]',algErr(1),algErr(2)))            
%             ii = 2; subplot(2,1,ii),plot(t,[refShift(:,ii) estShift(:,ii) errShift(:,ii)]),legend('ref','est','err')
%             ylabel('x [pix]'),
%             xlabel('Frame [#]'),
%             
%             isOK    = true;
%             
%         end
%         % ---------------------------------------------
        
        
        % ==========================================
        function obj = TestLoadData(obj)
            
            % TestLoadData - test data reshape and neighborrhod construction
            
            %dataPath                = 'C:\Uri\Data\Movies\Janelia\Imaging\M2\2_20_14\2_20_14_m2__004.tif';
            dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\m8\02_10_14\2_9_14_m8__003.tif';
            [obj, imgData]          = LoadImageData(obj, dataPath);
            %obj                     = SetData(obj, imgData);
            obj                     = GetNeighborhoodIndexes(obj, 8);
            
            
        end
        % ---------------------------------------------
        
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
        % ---------------------------------------------
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
        % ---------------------------------------------
        
        
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
        % ---------------------------------------------


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
        % ---------------------------------------------

        
        
    end% methods
end% classdef