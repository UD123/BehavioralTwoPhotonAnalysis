classdef TPA_ImageRegistration
    % TPA_ImageRegistration - test different algorithms for image matching
    % Inputs:
    %       none
    % Outputs:
    %        
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 01.02 12.04.16 UD     Adopted for Sensor Tests
    %-----------------------------
       
    properties (Constant)
        Version         = '0102';       % SW version
        MsgCodes        = struct('OK',0,'FAIL',1,'NO_MATCHES',2);  % code for error messages
    end

    
    properties
        
        ImgData                     = [];               % 4D array of intensity image data 
        ImgMean                     = [];               % image difference
        
        MsgId                       = 0;              % success or fail or othe message
        
        
    end % properties
    
    % Analysis
    methods
        
        % ==========================================
        function obj = TPA_ImageRegistration()
            % TPA_ImageRegistration - constructor
            % Input:
            %   
            % Output:
            %     default values
            
            %if nargin < 1, dirName   = 'C:\Uri\Data\Images\Target'; end;
            

        end
        
        % ==========================================
        function obj = LoadData(obj, dirName, imgId)
            % LoadData - loads image data.
            % First image is the reference
            % Input:
            %    shotName - name of the shot to get
            %     obj - initialized with the test data
            % Output:
            %     ImgData - [nR,nC,3,nT] array nT - number of images
            
            obj.MsgId               = obj.MsgCodes.FAIL;
            if nargin < 2, dirName = 'C:\LabUsers\Uri\Data\Janelia\Imaging\D8\7_12_14'; end
            if nargin < 3, imgId = 1; end
            
            imSet                   = imageSet(dirName);
            if 1 > imSet.Count, DTP_ManageText([], sprintf('no image data is found'), 'E' ,0) ; end;
            if imgId < 0, error('imgId mus be > 0'); end;
            if imgId > imSet.Count, DTP_ManageText([], sprintf('ImgId is less than number of images'), 'E' ,0) ; end;
            
            
            % load all the data
            imgData                 = [];
            for m = 1:length(imSet.ImageLocation),
                img                 = imread(imSet.ImageLocation{m});
                imgData             = cat(4,imgData,img);
            end
            
            obj.ImgData             = imgData;
            obj.MsgId               = obj.MsgCodes.OK;
            
        end
        
        % ==========================================
        function obj = PreprocessData(obj)
            % SmoothData - smooth image data - may be can help. Substract Min or Mean
            % Input:
            %     obj - initialized with the test data
            % Output:
            %     obj - initialized with the test data
            
            % get the dim
            [rNum,cNum,~,imNum]     = size(obj.ImgData);
            if imNum < 1, error('Load test data first by calling LoadTestData method'); end;
                        
%             % smooth
%             F                   = fspecial('disk',5);
%             imgData             = imfilter(obj.ImgData,F);
%             
%             % substract mean
%             imgData             = double(imgData);
%             %imMean              = mean(imD,4);
%             imgMin              = min(imgData,[],4);
%             imgData             = bsxfun(@minus,imgData,imgMin);
            
            
%             for m = 1:imNum,
%                 imD      = cat(4,imD,rgb2gray(testStr.ImData(:,:,:,m)));
%             end
%             
            % save
            %obj.ImgData         = imgData;
            obj.ImgMean         = mean(obj.ImgData,4);
            
        end
        
        % ==========================================
        function obj = AlgoMultimodal(obj, imgD, figNum)
            % AlgoMultimodal - estimates transformation between images in array imgD
            % Runs matlab example : Registering Multimodal MRI Images
            % Input:
            %     imgD - [rNum,cNum,~,imNum] image array
            % Output:
            %     obj - with distances
             if nargin < 2, imgD         = load('mri.mat','D'); end;
             if nargin < 3, figNum       = 1; end;
             
           
            % get the dim
            [rNum,cNum,nD,imNum]     = size(imgD);
            if imNum < 1, error('Load test data first'); end;
            %obj.ImgData  = imgD;

            
            % Run algorithm on pairs
            [optimizer,metric] = imregconfig('multimodal');
            tic;
            for m = 2:imNum,
                
               if nD == 3,
                fixed  = rgb2gray(imgD(:,:,:,m-1));
                moving = rgb2gray(imgD(:,:,:,m));
                else % some cases
                fixed  = imgD(:,:,:,m-1);
                moving = imgD(:,:,:,m);
                end
                
                % preprocess
               % moving = imhistmatch(moving,fixed);
                
                figure, imshowpair(moving, fixed, 'montage')
                title('Unregistered');
                
%                 movingRegisteredDefault = imregister(moving, fixed, 'affine', optimizer, metric);
%                 figure, imshowpair(movingRegisteredDefault, fixed)
%                 title('A: Default registration')
%                 
                 optimizer.InitialRadius = optimizer.InitialRadius/3.5;
%                 movingRegisteredAdjustedInitialRadius = imregister(moving, fixed, 'affine', optimizer, metric);
%                 figure, imshowpair(movingRegisteredAdjustedInitialRadius, fixed)
%                 title('Adjusted InitialRadius')                
                
                optimizer.MaximumIterations = 300;
                optimizer.Epsilon = 1.5e-4;
                optimizer.GrowthFactor = 1.01;
                
                movingRegisteredAdjustedInitialRadius300 = imregister(moving, fixed, 'affine', optimizer, metric);
                figure, imshowpair(movingRegisteredAdjustedInitialRadius300, fixed)
                title('B: Adjusted InitialRadius, MaximumIterations = 300, Adjusted InitialRadius.')                
                
                obj.ImgDiff = imabsdiff(movingRegisteredAdjustedInitialRadius300, fixed);
                figure,imagesc((obj.ImgDiff)),colorbar;
                title('Final Difference')
                
            end
            ShowText(obj,sprintf('Multimodal Image Registration is done in %4.3f sec.',imNum,toc));
        end
        
        % ==========================================
        function obj = AlgoMonomodal(obj, imgD, figNum)
            % AlgoMonomodal - estimates transformation between images in array imgD
            % Runs matlab example : Registering Multimodal MRI Images
            % Input:
            %     imgD - [rNum,cNum,~,imNum] image array
            % Output:
            %     obj - with distances
             if nargin < 2, imgD         = load('mri.mat','D'); end;
             if nargin < 3, figNum       = 1; end;
             
           
            % get the dim
            [rNum,cNum,nD,imNum]     = size(imgD);
            if imNum < 1, error('Load test data first'); end;
            %obj.ImgData  = imgD;

            
            % Run algorithm on pairs
            [optimizer,metric] = imregconfig('monomodal');
            %optimizer = registration.optimizer.OnePlusOneEvolutionary;
            tic;
            for m = 2:imNum,
                
               if nD == 3,
                fixed  = rgb2gray(imgD(:,:,:,m-1));
                moving = rgb2gray(imgD(:,:,:,m));
                else % some cases
                fixed  = imgD(:,:,:,m-1);
                moving = imgD(:,:,:,m);
                end
                
                % preprocess
                %moving = imhistmatch(moving,fixed);
                
                figure, imshowpair(moving, fixed)
                title('Unregistered');
                
%                 movingRegisteredDefault = imregister(moving, fixed, 'affine', optimizer, metric);
%                 figure, imshowpair(movingRegisteredDefault, fixed)
%                 title('A: Default registration')
%                 
%                 optimizer.InitialRadius = optimizer.InitialRadius/3.5;
%                 movingRegisteredAdjustedInitialRadius = imregister(moving, fixed, 'affine', optimizer, metric);
%                 figure, imshowpair(movingRegisteredAdjustedInitialRadius, fixed)
%                 title('Adjusted InitialRadius')                
                
%                 optimizer.MaximumIterations = 300;
%                 optimizer.Epsilon = 1.5e-4;
%                 optimizer.GrowthFactor = 1.01;
                
                movingRegistered = imregister(moving, fixed, 'affine', optimizer, metric);
                figure, imshowpair(movingRegistered, fixed)
                title('B: Registred.')                
                
                obj.ImgDiff = imabsdiff(movingRegistered, fixed);
                figure,imagesc((obj.ImgDiff)),colorbar;
                title('Final Difference')
                
            end
            ShowText(obj,sprintf('Multimodal Image Registration is done in %4.3f sec.',imNum,toc));
        end
        
         % ==========================================
        function obj = AlgoImRegDemons(obj, imgD, figNum)
            % AlgoImRegDemons - estimates transformation between images in array imgD
            % Runs matlab example : imregdemons
            % Input:
            %     imgD - [rNum,cNum,~,imNum] image array
            % Output:
            %     obj - with distances
             if nargin < 2, imgD         = load('mri.mat','D'); end;
             if nargin < 3, figNum       = 1; end;
             
           
            % get the dim
            [rNum,cNum,nD,imNum]     = size(imgD);
            if imNum < 1, error('Load test data first'); end;
            if figNum < 1, return; end;
            %obj.ImgData  = imgD;

            
            % Run algorithm on pairs
            tic;
            for m = 2:imNum,
                
               if nD == 3,
                fixed  = rgb2gray(imgD(:,:,:,m-1));
                moving = rgb2gray(imgD(:,:,:,m));
                else % some cases
                fixed  = imgD(:,:,:,m-1);
                moving = imgD(:,:,:,m);
                end
                
                % preprocess
                moving = imhistmatch(moving,fixed);
                
                figure(figNum + 1), imshowpair(moving, fixed, 'montage')
                title('Unregistered');
                
                [~,movingReg] = imregdemons(moving,fixed,[500 400 200],'AccumulatedFieldSmoothing',1.3);
                
                figure(figNum + 2), imshowpair(movingReg, fixed)
                title('A: Default registration')
                
                obj.ImgDiff = imabsdiff(movingReg, fixed);
                figure(figNum + 3),imagesc((obj.ImgDiff)),colorbar;
                title('Final Difference')
                
            end
            ShowText(obj,sprintf('AlgoImRegDemons Registration is done on %d images in %4.3f sec.',imNum,toc));
        end

         % ==========================================
        function obj = AlgoFeatures(obj, imgD, figNum)
            % AlgoFeatures - estimates transformation between images in array imgD
            % Runs matlab example : Video Stabilization Using Point Feature Matching
            % Input:
            %     imgD - [rNum,cNum,~,imNum] image array
            % Output:
            %     obj - with distances
             if nargin < 2, imgD         = load('mri.mat','D'); end;
             if nargin < 3, figNum       = 1; end;
             
           
            % get the dim
            [rNum,cNum,nD,imNum]     = size(imgD);
            if imNum < 1, error('Load test data first'); end;
            if figNum < 1, return; end;
            %obj.ImgData  = imgD;

            
            % Run algorithm on pairs
            tic;
            for m = 2:imNum,
                
                if nD == 3,
                fixed  = rgb2gray(imgD(:,:,:,m-1));
                moving = rgb2gray(imgD(:,:,:,m));
                else % some cases
                fixed  = imgD(:,:,:,m-1);
                moving = imgD(:,:,:,m);
                end
                
                % preprocess
                %moving = imhistmatch(moving,fixed);
                figure(figNum + 1), imshowpair(moving, fixed)
                title('Unregistered');
                
%                 ptThresh = 0.1;
%                 pointsA = detectFASTFeatures(fixed, 'MinContrast', ptThresh);
%                 pointsB = detectFASTFeatures(moving, 'MinContrast', ptThresh);
                
                pointsA  = detectSURFFeatures(fixed);
                pointsB  = detectSURFFeatures(moving);

%                 pointsA = detectHarrisFeatures(fixed);
%                 pointsB = detectHarrisFeatures(moving);       
                
                
                % Extract FREAK descriptors for the corners
                [featuresA, pointsA] = extractFeatures(fixed, pointsA);
                [featuresB, pointsB] = extractFeatures(moving, pointsB);  
                indexPairs = matchFeatures(featuresA, featuresB,'unique','true');
                pointsA = pointsA(indexPairs(:, 1), :);
                pointsB = pointsB(indexPairs(:, 2), :);  
                
                % prjective
                if size(pointsA,1)< 4,
                    obj.MsgId  = obj.MsgCodes.NO_MATCHES;
                    ShowText(obj,sprintf('AlgoPointTracker Registration failed. No matches for image %d.',m),'E');
                    return
                end
                
                
                [tform, pointsBm, pointsAm] = estimateGeometricTransform(pointsB, pointsA, 'projective');
                movingReg = imwarp(moving, tform, 'OutputView', imref2d(size(moving)));
                
                figure(figNum + 2), imshowpair(movingReg, fixed)
                title('A: Default registration')
                
                obj.ImgDiff = imabsdiff(movingReg, fixed);
                figure(figNum + 3),imagesc((obj.ImgDiff)),colorbar;
                title('Final Difference')
                
                figure(figNum + 4); ax = axes;
                showMatchedFeatures(fixed,moving,pointsA,pointsB,'montage','Parent',ax);  
                title('Matched points');
                
            end
            ShowText(obj,sprintf('AlgoImRegDemons Registration is done on %d images in %4.3f sec.',imNum,toc));
        end

         % ==========================================
        function obj = AlgoPointTracker(obj, imgD, figNum)
            % AlgoPointTracker - estimates transformation between images in array imgD
            % using points
            % Runs matlab example : Structure From Motion From Two Views
            % Input:
            %     imgD - [rNum,cNum,~,imNum] image array
            % Output:
            %     ImgData -registred image data
            
             if nargin < 2, imgD         = load('mri.mat','D'); end;
             if nargin < 3, figNum       = 1; end;
             % designate any problem
             obj.MsgId                  = obj.MsgCodes.OK;
             
           
            % get the dim
            [rNum,cNum,nD,imNum]     = size(imgD);
            if imNum < 1, error('Load test data first'); end;
            if figNum < 1, return; end;
            % init
            %obj.ImgData             = [];
            
            % init images
            fixed  = imgD(:,:,:,1);
            if nD == 3, fixed  = rgb2gray(fixed); end
            obj.ImgData = fixed;
            

            
            % Run algorithm on pairs
            tic;
            for m = 2:imNum,
                
                 moving = imgD(:,:,:,m);
                if nD == 3, moving = rgb2gray(moving); end;
                
                % init
                %if m == 2, obj.ImgData = fixed; end
                
                % preprocess
                %moving = imhistmatch(moving,fixed);
                figure(figNum + 1), imshowpair(moving, fixed)
                title('PT : Unregistered');
                
                % estimate
                imagePoints1  = detectMinEigenFeatures(fixed, 'MinQuality', 0.1);                
                %pointsB = detectMinEigenFeatures(moving, 'MinQuality', 0.1);    
                
%                 % Visualize detected points
%                 figure(figNum + 5)
%                 imshow(fixed, 'InitialMagnification', 50);
%                 title('150 Strongest Corners from the First Image');
%                 hold on
%                 plot(selectStrongest(imagePoints1, 150));  
%                 hold off;
                
                % Create the point tracker
                tracker = vision.PointTracker('MaxBidirectionalError', 3, 'NumPyramidLevels', 5);                
                
                % Initialize the point tracker
                imagePoints1 = imagePoints1.Location;
                initialize(tracker, imagePoints1, fixed);

                % Track the points
                [imagePoints2, validIdx] = step(tracker, moving);
                pointsA = imagePoints1(validIdx, :);
                pointsB = imagePoints2(validIdx, :);
                
                % prjective
                if numel(validIdx)< 4,
                    obj.MsgId  = obj.MsgCodes.NO_MATCHES;
                    ShowText(obj,sprintf('AlgoPointTracker Registration failed. No matches for image %d.',m),'E');
                    return
                end
                

                
                % transform
                %[tform, pointsBm, pointsAm] = estimateGeometricTransform(pointsB, pointsA, 'affine');
                [tform, pointsBm, pointsAm] = estimateGeometricTransform(pointsB, pointsA, 'projective');
                movingReg = imwarp(moving, tform, 'OutputView', imref2d(size(moving)));
                
                figure(figNum + 2), imshowpair(movingReg, fixed)
                title('PT : Coarse registration')
                
                obj.ImgDiff = imabsdiff(movingReg, fixed);
                figure(figNum + 3),imagesc((obj.ImgDiff)),colorbar;
                title('PT : Coarse Difference')
                
                % Visualize correspondences
                figure(figNum + 6)
                showMatchedFeatures(fixed, moving, pointsA, pointsB);
                title('PT : Tracked Features');                
                
                
%                 figure(figNum + 7); ax = axes;
%                 showMatchedFeatures(fixed,moving,pointsA,pointsB,'montage','Parent',ax);  
%                 title('Matched points');
                
                % save
                fixed       = movingReg;
                obj.ImgData = cat(4,obj.ImgData,movingReg); 
                
            end
            % designate no problem
            %obj.MsgId                  = obj.MsgCodes.OK;
            ShowText(obj,sprintf('AlgoPointTracker Registration is done on %d images in %4.3f sec.',imNum,toc));
        end
        
         % ==========================================
        function obj = AlgoSIFT_old(obj, imgD, figNum)
            % AlgoSIFT - estimates transformation between images in array imgD
            % Runs matlab example : uses SIFT from vedaldi
            % Input:
            %     imgD - [rNum,cNum,~,imNum] image array
            % Output:
            %     ImgData -registred image data
             if nargin < 2, imgD         = load('mri.mat','D'); end;
             if nargin < 3, figNum       = 1; end;
             
           
            % get the dim
            [rNum,cNum,nD,imNum]     = size(imgD);
            if imNum < 1, error('Load test data first'); end;
            if figNum < 1, return; end;
             % designate any problem
             obj.MsgId              = obj.MsgCodes.OK;
             scoreThr               = (rNum^2+cNum^2)/50;
            
            % init
            obj.ImgData             = [];
            

            % one time init
            if ~exist('vl_setup.m','file')
            addpath('C:\Uri\Code\Matlab\ImageProcessing\People\Vedaldi\vlfeat-0.9.19\toolbox');
            vl_setup;
            end

            octaveStart         = 1;
            octaveNum           = 5;            
            
            % Run algorithm on pairs
            tic;
            for m = 2:imNum,
                
                if nD == 3,
                fixed  = rgb2gray(imgD(:,:,:,m-1));
                moving = rgb2gray(imgD(:,:,:,m));
                else % some cases
                fixed  = imgD(:,:,:,m-1);
                moving = imgD(:,:,:,m);
                end
                
                % init
                if m == 2, obj.ImgData = fixed; end
                
                
                % preprocess
                %moving = imhistmatch(moving,fixed);
                figure(figNum + 1), imshowpair(moving, fixed)
                title('SIFT : Unregistered');
                
                imga             = im2single(fixed);
                [fa,da]          = vl_sift(imga,'FirstOctave',octaveStart,'Octaves',octaveNum) ;
                
                imga             = im2single(moving);
                [fb,db]          = vl_sift(imga,'FirstOctave',octaveStart,'Octaves',octaveNum) ;

                % match
                [matches, scores] = vl_ubcmatch(da,db) ;
                [drop, perm]    = sort(scores, 'descend') ;
                matches         = matches(:, perm) ;
                scores          = scores(perm) ;
                
%                 % reject long distance matches
%                 validBool       = scores < scoreThr;
%                 matches         = matches(:,validBool);

                pointsA         = fa(1:2,matches(1,:))' ;
                pointsB         = fb(1:2,matches(2,:))' ;
                %ya = fa(2,matches(1,:)) ;
                %yb = fb(2,matches(2,:)) ;
                
                    
%                 [camParams, ~, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints);
%                 figure(10),showExtrinsics(camParams, 'PatternCentric');    
% 

                % prjective
                if size(pointsA,1)< 4,
                    obj.MsgId  = obj.MsgCodes.NO_MATCHES;
                    ShowText(obj,sprintf('AlgoPointTracker Registration failed. No matches for image %d.',m),'E');
                    return
                end

                
                [tform, pointsBm, pointsAm, status] = estimateGeometricTransform(pointsB, pointsA, 'projective');
                obj.MsgId  = status;
                
                movingReg = imwarp(moving, tform, 'OutputView', imref2d(size(moving)));
                
                figure(figNum + 2), imshowpair(movingReg, fixed)
                title(['SIFT: Registration : ',num2str(status)])
                
                obj.ImgDiff = imabsdiff(movingReg, fixed);
                figure(figNum + 3),imagesc((obj.ImgDiff)),colorbar;
                title('SIFT: Difference')
                
                % Visualize correspondences
                figure(figNum + 6)
                showMatchedFeatures(fixed, moving, pointsA, pointsB);
                title('SIFT : Tracked Features');                
                
                % save
                obj.ImgData = cat(4,obj.ImgData,movingReg); 
                
                
                
            end
            ShowText(obj,sprintf('AlgoSIFT Registration is done on %d images in %4.3f sec.',imNum,toc));
        end
 
         % ==========================================
        function obj = AlgoSIFT(obj, imgD, figNum)
            % AlgoSIFT - estimates transformation between images in array imgD
            % Runs matlab example : uses SIFT from vedaldi
            % Input:
            %     imgD - [rNum,cNum,~,imNum] image array
            % Output:
            %     ImgData -registred image data
             if nargin < 2, imgD         = load('mri.mat','D'); end;
             if nargin < 3, figNum       = 1; end;
             
           
            % get the dim
            [rNum,cNum,nD,imNum]     = size(imgD);
            if imNum < 1, error('Load test data first'); end;
            %if figNum < 1, return; end;
             % designate any problem
             obj.MsgId              = obj.MsgCodes.OK;
             scoreThr               = (rNum^2+cNum^2)/120;
            
            % init
            obj.ImgData             = [];
            

            % one time init
            if ~exist('vl_setup.m','file')
            addpath('C:\Uri\Code\Matlab\ImageProcessing\People\Vedaldi\vlfeat-0.9.19\toolbox');
            vl_setup;
            end

            octaveStart         = 1;
            octaveNum           = 5;      
            
            % init images
            fixed  = imgD(:,:,:,1);
            if nD == 3, fixed  = rgb2gray(fixed); end
            obj.ImgData = fixed;
            
            
            % Run algorithm on pairs
            tic;
            for m = 2:imNum,
                
                moving = imgD(:,:,:,m);
                if nD == 3, moving = rgb2gray(moving); end;
                
                % init
                %if m == 2, obj.ImgData = fixed; end
                
                
                % preprocess
                %moving = imhistmatch(moving,fixed);
                if figNum > 0,
                figure(figNum + 1), imshowpair(moving, fixed)
                title('SIFT : Unregistered');
                end
                
                imga             = im2single(fixed);
                [fa,da]          = vl_sift(imga,'FirstOctave',octaveStart,'Octaves',octaveNum) ;
                
                imga             = im2single(moving);
                [fb,db]          = vl_sift(imga,'FirstOctave',octaveStart,'Octaves',octaveNum) ;

                % match
                [matches, scores] = vl_ubcmatch(da,db) ;
                [drop, perm]    = sort(scores, 'descend') ;
                matches         = matches(:, perm) ;
                scores          = scores(perm) ;
                
                % reject long distance matches
                validBool       = scores < scoreThr;
                matches         = matches(:,validBool);

                pointsA         = fa(1:2,matches(1,:))' ;
                pointsB         = fb(1:2,matches(2,:))' ;
                %ya = fa(2,matches(1,:)) ;
                %yb = fb(2,matches(2,:)) ;
                
                    
%                 [camParams, ~, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints);
%                 figure(10),showExtrinsics(camParams, 'PatternCentric');    
% 

                % prjective
                if size(pointsA,1)< 4,
                    obj.MsgId  = obj.MsgCodes.NO_MATCHES;
                    ShowText(obj,sprintf('AlgoPointTracker Registration failed. No matches for image %d.',m),'E');
                    return
                end

                
                [tform, pointsBm, pointsAm, status] = estimateGeometricTransform(pointsB, pointsA, 'projective');
                obj.MsgId  = status;
                
                movingReg = imwarp(moving, tform, 'OutputView', imref2d(size(moving)));
                obj.ImgDiff = imabsdiff(movingReg, fixed);
                
                             
                if figNum > 0,
                figure(figNum + 2), imshowpair(movingReg, fixed)
                title(['SIFT: Registration : ',num2str(status)])
                
                figure(figNum + 3),imshow((obj.ImgDiff)),colorbar;
                title('SIFT: Difference')
                end
                
%                 % Visualize correspondences
%                 figure(figNum + 6)
%                 showMatchedFeatures(fixed, moving, pointsA, pointsB);
%                 title('SIFT : Tracked Features');                
                
                % save
                fixed       = movingReg;
                obj.ImgData = cat(4,obj.ImgData,movingReg); 
                
                
                
            end
            ShowText(obj,sprintf('AlgoSIFT Registration is done on %d images in %4.3f sec.',imNum,toc));
        end
        
         % ==========================================
        function obj = AlgoOpticalFlow_old(obj, imgD, figNum)
            % AlgoOpticalFlow - estimates transformation between images in array imgD
            % Uses fine approximation by optical flow
            % Input:
            %     imgD - [rNum,cNum,~,imNum] image array
            % Output:
            %     obj - with distances
             if nargin < 2, imgD         = load('mri.mat','D'); end;
             if nargin < 3, figNum       = 1; end;
             
           
            % get the dim
            [rNum,cNum,nD,imNum]     = size(imgD);
            if imNum < 1, error('Load test data first'); end;
            if figNum < 1, return; end;
                       
            % init
            %obj.ImgData             = [];


            % one time init
            %if ~exist('getOpticalFlow_CeLiu.m','file')
            %addpath('C:\Uri\Code\Matlab\ImageProcessing\OpticalFlow\Optical Flow');
            %end

            [x,y]       = meshgrid(1:cNum,1:rNum);
            x           = x - cNum/2;
            y           = y - rNum/2;
            intA        = [x(:).^2 y(:).^2 x(:).*y(:) x(:) y(:) x(:)*0+1];
            pinvA       = pinv(intA);
            
%             % init images
%             fixed       = imgD(:,:,:,1);
%             if nD == 3, fixed  = rgb2gray(fixed); end
%             obj.ImgData = fixed;
            
            
            
            % Run algorithm on pairs
            tic;
            for m = 2:imNum,
                
                if nD == 3,
                fixed  = rgb2gray(imgD(:,:,:,m-1));
                moving = rgb2gray(imgD(:,:,:,m));
                else % some cases
                fixed  = imgD(:,:,:,m-1);
                moving = imgD(:,:,:,m);
                end
                
                % init
                if m == 2, obj.ImgData = fixed; end
                
                
                % preprocess
                %moving = imhistmatch(moving,fixed);
                figure(figNum + 1), imshowpair(moving, fixed)
                title('OF : Unregistered');
                
                [vx,vy] = getOpticalFlow_CeLiu(fixed,moving);
                
                % smooth optical filed - otherwise holes are affected
                vxb = imfilter(vx,fspecial('disk',25));
                vyb = imfilter(vy,fspecial('disk',25));

%                 intCoeff    = pinvA*[vx(:),vy(:)];
%                 intv        = intA*intCoeff;
%                 vxb         = reshape(intv(:,1),rNum,cNum);
%                 vyb         = reshape(intv(:,2),rNum,cNum);

%                 vxb         = vx;
%                 vyb         = vy;
                
                
                movingReg  = warpByOpticalFlow_dong(moving,vxb,vyb,'linear');
                movingReg  = im2uint8(movingReg);
                
                figure(figNum + 2), imshowpair(movingReg, fixed)
                title('OF: Fine registration')
                
                obj.ImgDiff = imabsdiff(movingReg, fixed);
                figure(figNum + 3),imagesc((obj.ImgDiff)),colorbar;
                title('OF : Fine Difference')
                
                % save
                obj.ImgData = cat(4,obj.ImgData,movingReg); 
                
            end
            ShowText(obj,sprintf('AlgoOF Registration is done on %d images in %4.3f sec.',imNum,toc));
        end
        
         % ==========================================
        function obj = AlgoOpticalFlow(obj, imgD, figNum)
            % AlgoOpticalFlow - estimates transformation between images in array imgD
            % Uses fine approximation by optical flow
            % Input:
            %     imgD - [rNum,cNum,~,imNum] image array
            % Output:
            %     obj - with distances
             if nargin < 2, imgD         = load('mri.mat','D'); end;
             if nargin < 3, figNum       = 1; end;
             
           
            % get the dim
            [rNum,cNum,nD,imNum]     = size(imgD);
            if imNum < 1, error('Load test data first'); end;
                       
            % init
            %obj.ImgData             = [];


            % one time init
            %if ~exist('getOpticalFlow_CeLiu.m','file')
            %addpath('C:\Uri\Code\Matlab\ImageProcessing\OpticalFlow\Optical Flow');
            %end

            [x,y]       = meshgrid(1:cNum,1:rNum);
            x           = x - cNum/2;
            y           = y - rNum/2;
            intA        = [x(:).^2 y(:).^2 x(:).*y(:) x(:) y(:) x(:)*0+1];
            pinvA       = pinv(intA);
            
            % init images
            fixed       = imgD(:,:,:,1);
            if nD == 3, fixed  = rgb2gray(fixed); end
            obj.ImgData = fixed;
            
            
            
            % Run algorithm on pairs
            tic;
            for m = 2:imNum,
                
                 moving = imgD(:,:,:,m);
                if nD == 3, moving = rgb2gray(moving); end;
                
                % init
                %if m == 2, obj.ImgData = fixed; end
                
                
                % preprocess
                %moving = imhistmatch(moving,fixed);
                if figNum > 0,
                figure(figNum + 1), imshowpair(moving, fixed)
                title('OF : Unregistered');
                end
                
                [vx,vy] = getOpticalFlow_CeLiu(fixed,moving);
                
                % smooth optical filed - otherwise holes are affected
                vxb = imfilter(vx,fspecial('disk',25));
                vyb = imfilter(vy,fspecial('disk',25));

%                 intCoeff    = pinvA*[vx(:),vy(:)];
%                 intv        = intA*intCoeff;
%                 vxb         = reshape(intv(:,1),rNum,cNum);
%                 vyb         = reshape(intv(:,2),rNum,cNum);

%                 vxb         = vx;
%                 vyb         = vy;
                
                
                movingReg  = warpByOpticalFlow_dong(moving,vxb,vyb,'linear');
                movingReg  = im2uint8(movingReg);
                obj.ImgDiff = imabsdiff(movingReg, fixed);
                
                if figNum > 0,
                figure(figNum + 2), imshowpair(movingReg, fixed)
                title('OF: Fine registration')
                
                figure(figNum + 3),imshow((obj.ImgDiff)),colorbar;
                title('OF : Fine Difference')
                end
                
                % save
                fixed       = movingReg;                
                obj.ImgData = cat(4,obj.ImgData,movingReg); 
                
            end
            ShowText(obj,sprintf('AlgoOF Registration is done on %d images in %4.3f sec.',imNum,toc));
        end
        
        % ==========================================
        function obj = ShowText(obj,  txt, severity ,quiet)
            % This manages info display
            
            if nargin < 2, txt = 'connect';                 end;
            if nargin < 3, severity = 'I';                  end;
            if nargin < 4, quiet = 0;                       end;
            
            if quiet > 0, return; end;
            
            if strcmp(severity,'I')
                col = 'k';
            elseif strcmp(severity,'W')
                col = 'b';
            elseif strcmp(severity,'E')
                col = 'r';
            else
                col = 'k';
            end;
            
            % always print
            fprintf('%s : IR : %s\n',severity,txt);
            %set(obj.Handles.textLabel,'string',txt,'ForegroundColor',col);
            
        end
        
        
    end
    
    % Test
    methods
        
        % ==========================================
        function obj = TestLoad(obj, testType, figNum)
            % TestLoad - test image data load
            
            if nargin < 2, testType     = 1; end;
            if nargin < 3, figNum       = 1; end;
            
                
            switch testType,
                case 1,   dirName  = pwd; 
                otherwise error('Bad testType');
            end;
            
            % load test data
            obj                     = LoadData(obj);
            
            % show
            figure(figNum)
            montage(obj.ImgData);
            
        end
        
        % ==========================================
        function obj = TestImRegDemons(obj, testType, figNum)
            
            % TestLedGeometry - loads test and show led geometry
            
            if nargin < 2, testType     = 11; end;
            if nargin < 3, figNum       = 1; end;
            
                
            switch testType,
                case 1,   shotName  = 'session_2601'; 
                case 2,   shotName  = 'session_2493'; % gray large disparity
                case 3,   shotName  = 'session_2696';
                case 11,  shotName  = randi(20);
                otherwise error('Bad testType');
            end;
            
            % load test data
            imgD                    = LoadData(obj.MngrData);
            
            % Matlab example
            obj                     = AlgoImRegDemons(obj, imgD, figNum);
            
        end

        % ==========================================
        function obj = TestAllAlg(obj, testType ,algType, figNum)
            % TestAllAlg - runs all the algorithms
            
            if nargin < 2, testType  = 1;   end;
            if nargin < 3, algType   = 1;   end;
            if nargin < 4, figNum    = 1;   end;

            
            switch testType,
                case 1,   dirName  = ''; % 
                otherwise error('Bad testType');
            end;
            algNum                  = length(algType);
            
            
            % load test data
            if isempty(obj.ImgData),
            obj                     = LoadData(obj);
            end
            imgD                    = obj.ImgData;
            
            
            % run algorithms
            for k = 1:algNum,
                switch algType(k),
                    case 1, % heavy
                         obj   = AlgoMultimodal(obj, imgD, figNum);
                    case 2, % heavy
                         obj   = AlgoMonomodal(obj, imgD, figNum);
                    case 3, % Not so good
                         obj   = AlgoImRegDemons(obj, imgD, figNum);
                    case 4, % Bad
                         obj   = AlgoFeatures(obj, imgD, figNum);
                   case 5, % Good
                         obj   = AlgoPointTracker(obj, imgD, figNum);
                   case 6, % Good
                         obj   = AlgoSIFT(obj, imgD, figNum);
                    
                         
                  case 11, % optical flow fine registration - good
                         obj   = AlgoOpticalFlow(obj, imgD, figNum);
                         
                    otherwise
                        error('Bad Alg Type %d',algType(k))
                end
                
                % show results
                %figNum          = algType(k);
            end
            
        end
        
        
    end% methods
end% classdef