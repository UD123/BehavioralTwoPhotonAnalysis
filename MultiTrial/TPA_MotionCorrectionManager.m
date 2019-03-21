classdef TPA_MotionCorrectionManager
    % TPA_MotionCorrectionManager - corrects image motion in image stack using
    % different algorithm
    % Inputs:
    %       none
    % Outputs:
    %        motion path
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 24.11 15.11.16 UD     Working for Muhamad 
    % 19.07 13.10.14 UD     support multiple stack by mean projection 
    % 18.01 13.04.14 UD     GenData option 
    % 17.04 21.03.14 UD     Generating testing tif files 
    % 17.02 12.03.14 UD     Image Box with multiple rounds 
    % 17.01 08.03.14 UD     saving memory Uri Alg
	% 16.16 24.02.14 UD     switching from like to class
    % 16.08 22.02.14 UD     Improving Uri algo
    % 16.07 20.02.14 UD     Adding preview otions
    % 16.01 17.02.14 UD     New algo working good. TestAll is functional
    % 16.00 13.02.14 UD     Janelia Data alignement testing
    %-----------------------------
    
    
    properties
        
        ImgData                     = [];               % 3D array of image data
        ImgDataFix                  = [];               % 3D array fixed motion
        
        ImgDataIs4D                 = false;            % remember that image data was
        
    end % properties
    
    methods
        
        % ==========================================
        function obj = TPA_MotionCorrectionManager()
            % TPA_MotionCorrectionManager - constructor
            % Input:
            %   imgData - 3D dim data
            % Output:
            %     default values
            
            % connect to different algorithms
           % addpath('C:\UsersJ\Uri\SW\Imaging Box\')
            
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, imgData] = LoadImageData(obj,fileDirName)
            % LoadImageData - loads image for fileName into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     imgData   - 3D array image data
            
            if nargin < 2, fileDirName = 'C:\UsersJ\Uri\Data\Imaging\m8\02_10_14\2_9_14_m8__004.tif'; end;
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
            
            % output
            imageDataSize   = size(imgData);
            %obj.ImgData     = imgData;
            
            DTP_ManageText([], sprintf('Image : %d images (Z=1) are loaded from file %s successfully',imageDataSize(4),fileDirName), 'I' ,0)   ;
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = SetData(obj,imgData,zSel)
            % SetData - check the data before storage
            % Input:
            %   imgData - 3D or 4D dim data
            %   zSel    - selected slice to work with
            % Output:
            %   ImgData - 3D
            
            if nargin < 2, error('Reuires image data as input'); end;
            if nargin < 3, zSel = 1; end;
            
            [nR,nC,nZ,nT] = size(imgData);
            %obj.ImgData   = zeros(R,nC,nT,'like',imgData);
            
            if nT > 1 && nZ > 1,
                DTP_ManageText([], sprintf('Multiple Z stacks are detected. Working with slice %d.',zSel), 'I' ,0);
                imgData         = squeeze(imgData(:,:,zSel,:));
                obj.ImgDataIs4D = true;
            elseif nT == 1, % data is 3D - do nothing
            elseif nT > 1 && nZ < 2,
                DTP_ManageText([], sprintf('Single Z stack image data.'), 'I' ,0);
                %imgData         = squeeze(imgData(:,:,1,:)); % long time
                imgData         = reshape(imgData(:,:,1,:),[nR,nC,nT]);
                obj.ImgDataIs4D = true;
            end
            % data is 4D :  make it 3D
            if nT > 1 && nZ < 2,
            end
            % save
            obj.ImgData     = imgData;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,ImgData] = GetData(obj)
            % GetData - check the data before retreave
            % Input:
            %   internal -
            % Output:
            %   ImgData -  3D or 4D dim data fixed
            
            [nR,nC,nT] = size(obj.ImgDataFix);
            
            % data was 4D :  make it 4D
            if obj.ImgDataIs4D,
                ImgData = reshape(obj.ImgDataFix,[nR,nC,1,nT]);
            else
                ImgData = obj.ImgDataFix;
            end
            DTP_ManageText([], sprintf('Motion Corection : copy fixed to original dataset.'), 'W' ,0);
            
                        
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = DeleteData(obj)
            % DeleteData - will remove stored video
            % Input:
            %   internal -
            % Output:
            %   ImgData,ImgDataFix  -  removed
            
            % clean it up
            obj.ImgDataFix = [];
            obj.ImgData    = [];
            DTP_ManageText([], sprintf('Motion Corection : Clearing intermediate results of motion correction.'), 'W' ,0);
           
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function [obj,template] = GetTemplate(obj, targetType)
            % SetData - check the data before storage
            % Input:
            %     targetType - how to sellect target templat
            % Output:
            %   template -  2D corr template
            
            if nargin < 2, targetType = 1; end
            
            [nR,nC,nT] = size(obj.ImgData);
            
            % taken from UI_im_browser
            switch targetType,
                case 1, % projection
                    template            = im_proj_maxmean(squeeze(obj.ImgData), 1);
                    templateName        = 'Prject Max Min';
                case 2,            %for mannully selected templates
                    template_frames     = squeeze(obj.ImgData(:,:,1:5));
                    template            = mean(template_frames,3);
                    templateName        = 'Mean First 5';
                 case 3, % single frame
                    template            = obj.ImgData(:,:,1);
                    templateName        = 'First Frame';
                 case 4, % random frames mean
                     r                  = randi(nT,8,1);
                     templateName       = 'Random 8';
                    template            = mean(obj.ImgData(:,:,r),3);
                case 5, % full mean - avergae over entire Time stack
                     templateName       = 'Stack Average';
                    template            = mean(obj.ImgData,3);
                    
              otherwise
                    error('Unknown target')
            end;
             DTP_ManageText([], sprintf('Motion Corection : Template selected : %s',templateName), 'I' ,0)   ;
           
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,ShiftEst] = AlgImageBox(obj, targetType)
            % AlgImageBox - implements algorithm of Imaging Box
            % Input:
            %     targetType - how to sellect target templat
            %     ImgData - must be prloaded
            % Output:
            %     ShiftEst - Nx2 shift array in y and x
            
            if nargin < 2, targetType = 1; end
            
            [nR,nC,nT]          = size(obj.ImgData);
            DTP_ManageText([], 'AlgImageBox Registration ....', 'I' ,0)   ; tic;
            
            [obj,template]          = GetTemplate(obj, targetType);            
            
            [ShiftTmp,imgDataFix]   = im_reg_dft(template, obj.ImgData, 1); %images registered at 1/10 pixel level
            ShiftEst                = ShiftTmp([3 4],:)';
  
            DTP_ManageText([], sprintf('AlgImageBox finished successfully in %4.3f sec',toc), 'I' ,0)   ;
            
            %template                = mean(imgDataFix,3);
            obj.ImgDataFix          = cast(imgDataFix,class(obj.ImgData));
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,yxShift] = AlgImageBoxFast(obj, targetType)
            % AlgImageBoxFast - like original Imaging Box but with FFT tricks and fast max find
            % Input:
            %     targetType - how to sellect target templat
            %     ImgData - must be prloaded
            % Output:
            %     yxShift - Nx2 shift array in x and y
            
            if nargin < 2, targetType = 1; end
            
            [nR,nC,nT]          = size(obj.ImgData);
            %ShiftEst            = zeros(nT,2);
            
            DTP_ManageText([], 'AlgImageBoxFast Registration ....', 'I' ,0)   ; tic;    
            
            [obj,template]      = GetTemplate(obj, targetType)    ;
            
            % im_reg_dft - similar code
            % precompute 
            templateF            = conj(fft2(template));
             
            
            % transfomr entire data array
            imgDataF            = fft2(obj.ImgData );
%             for p = 1:2,
%                 imgDataF        = fft(imgDataF,[],p);
%             end

            % multiply by template
            imgDataF            = bsxfun(@times, imgDataF, templateF);
            
            % transform back
%             for p = 1:2, %:-1:1,
%                 imgDataF        = ifft(imgDataF,[],p);
%             end
            imgDataF            = ifft2(imgDataF,'symmetric');
           
            % find maxima (3d dim is time)
            [max1,loc1]        = max(imgDataF,[],1);
            max1               = squeeze(max1);
            loc1               = squeeze(loc1);
            
            [max2,loc2]        = max(max1,[],1);    
            rloc               = loc1(sub2ind([nC nT],loc2,1:nT));
            cloc               = loc2;
            rloc               = rloc - 1;
            cloc               = cloc - 1;
            iBool              = rloc > fix(nR/2);
            rloc(iBool)        = rloc(iBool) - nR; %   row_shift = rloc - nR - 1;
            iBool              = cloc > fix(nC/2);
            cloc(iBool)        = cloc(iBool) - nC; %   col_shift = cloc - nC - 1;

            yxShift            = -round([rloc(:) cloc(:)]);
            
            % instaed of
           % [ShiftTmp,imgDataFix]   = im_reg_dft(template, obj.ImgData, 1); %images registered at 1/10 pixel level
           % ShiftEst                = ShiftTmp([3 4],:)';
             % create shifted image
            for m = 1:nT,
                obj.ImgDataFix(:,:,m)   = circshift(obj.ImgData(:,:,m),yxShift(m,:));
            end
            obj.ImgDataFix      = cast(obj.ImgDataFix,class(obj.ImgData));
            DTP_ManageText([], sprintf('AlgImageBoxFast finished successfully in %4.3f sec',toc), 'I' ,0)   ;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,ShiftEst] = AlgMultipleImageBox(obj, iterNum)
            % AlgMultipleImageBox - implements algorithm of Imaging Box - multiple times
            % Input:
            %     iterNum - how many rounds
            %     ImgData - must be prloaded
            % Output:
            %     ShiftEst - Nx2 shift array in y and x
            
            if nargin < 2, iterNum = 3; end
            
            [nR,nC,nT]              = size(obj.ImgData);
            DTP_ManageText([], sprintf('AlgMultipleImageBox : %d Registration ....',iterNum), 'I' ,0)   ; tic;
            

            % run algo : 
            templateType            = 5;
            ShiftEst                = zeros(nT,2);
            for m = 1:iterNum,
                [obj,estShift]      = obj.AlgImageBox(templateType); 
                %[obj,estShift]      = obj.AlgImageBoxFast(templateType); 
                obj                 = obj.SetData(obj.ImgDataFix);  % load back
                ShiftEst            = ShiftEst + estShift;
            end
            %template                = mean(imgDataFix,3);
            obj.ImgDataFix          = cast(obj.ImgDataFix,class(obj.ImgData));
            %ShiftEst                = estShift;
            DTP_ManageText([], sprintf('AlgMultipleImageBox finished successfully in %4.3f sec',toc), 'I' ,0)   ;
           
        end
        % ---------------------------------------------
        
        
          % ==========================================
      
        function [obj, yxShift, ImgDataFix] =  AlgUriCorrelate(obj, OffsetInd)
            % AlgUriCorrelate - implements algorithm of image alignment
            % using correlation between images at certain offset
            % Input:
            %     OffsetInd - nT x 2 indexes of the images to correlate
            %     ImgData - must be prloaded
            % Output:
            %     yxShift - Nx2 shift array in y and x
            
            
            if nargin < 2, OffsetInd = [1 2]; end
            
            [nR,nC,nT]          = size(obj.ImgData);
            if size(OffsetInd,1) ~= nT, error('Bad indexes'); end;
            yxShift            = zeros(nT,2);
            usfac                  = 1;
            output              = zeros(4, nT);
            
            % for j=1:nsize(3);
            % use paralell computering 12/13/2012
            
            %to use maxium workers at local
            % myCluster = parcluster('local');
            % nworkers = myCluster.NumWorkers;
            
            % isOpen = matlabpool('size') > 0;
            % if isOpen
            %     disp('The resource requested is being used ...');
            %     return;
            % end
            % matlabpool open local;
            %parfor k=1:nT;
            for k=1:nT,
                
                % images
                imIn1       = fft2(obj.ImgData(:,:,OffsetInd(k,1)));
                imIn2       = fft2(obj.ImgData(:,:,OffsetInd(k,2)));
                
                [output(:,k), fft_frame_reg]  = dftregistration(imIn1,imIn2,usfac);
                frames_reg(:,:,k)             = abs(ifft2(fft_frame_reg));
            end
            yxShift         = output(3:4,:)';
            ImgDataFix      = cast(frames_reg,class(obj.ImgData));
            
            % matlabpool close;
        end
        
        % ==========================================
        function [obj,yxShift] = AlgUriRegister(obj, targetType)
            % AlgUriRegister - implements algorithm of image alignment
            % without target image
            % Input:
            %     targetType - how to sellect target templat
            %     ImgData - must be prloaded
            % Output:
            %     yxShiftEst - Nx2 shift array in x and y
            
            if nargin < 2, targetType = 1; end
            
            [nR,nC,nT]          = size(obj.ImgData);
            %yxShift            = zeros(nT,2);
            refInd              = (1:nT)';
            % differntial check
            offsetInd           = [refInd circshift(refInd,-1)];  % image pairs to run
            
            % taken
            DTP_ManageText([], 'AlgUriRegister Registration ....', 'I' ,0)   ; tic;
            
            
            
            % for target test
            %offsetInd           = [refInd ones(nT,1)];  % image pairs to run
            A                   = speye(nT,nT) + sparse(offsetInd(:,1),offsetInd(:,2),-1,nT,nT); %A(1,1) = 0;
            
            
            %             % precompute matrix inverse (pinv on sparse)
            %             [U,S,V]             = svds(A);
            %             s                   = diag(S);
            %             tol                 = nT * eps(max(s));
            %             r                   = sum(s > tol);
            %             s                   = diag(ones(r,1)./s(1:r));
            %             Ainv                = V(:,1:r)*s*U(:,1:r)';
            
            % sparse does not help since inv matrix is full
            A                   = pinv(full(A));
            
            
            
            % for testing
            %template                = squeeze(obj.ImgData(:,:,1));
            %template                = im_proj_maxmean(squeeze(obj.ImgData), 1);
            %[shiftTmp,imgDataFix]   = im_reg_dft(template, obj.ImgData, 1); 
            %shiftTmp                = shiftTmp([3 4],:)';
            
            [obj, shiftTmp ,imgDataFix]   = obj.AlgUriCorrelate(offsetInd); %images registered at 1 pixel level
            
            % solve for y and x
            yxShift                 =  A*shiftTmp;
            yxShift                 = -round(yxShift); % opposite move direction
            %end
            
            % create shifted image
            for m = 1:nT,
                obj.ImgDataFix(:,:,m)   = circshift(obj.ImgData(:,:,m),yxShift(m,:));
            end
            obj.ImgDataFix      = cast(obj.ImgDataFix,class(obj.ImgData));
            
            DTP_ManageText([], sprintf('AlgUriRegister finished successfully in %4.3f sec',toc), 'I' ,0)   ;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,yxShift] = AlgUriRegisterFast(obj, mtrxOption)
            % AlgUriRegisterFast - implements algorithm of image alignment
            % without target image. Matrix inversion and Fourier
            % Input:
            %   mtrxOption - selects different matrix
            %     ImgData - must be prloaded
            % Output:
            %     yxShiftEst - Nx2 shift array in x and y
            
            if nargin < 1, mtrxOption = 1; end
            
            [nR,nC,nT]          = size(obj.ImgData);
            %yxShift            = zeros(nT,2);
            refInd              = (1:nT)';
            
            % taken
            DTP_ManageText([], sprintf('AlgUriRegisterFast Registration %d. ....',mtrxOption), 'I' ,0)   ;   tic;                         
            
            switch mtrxOption,
                case 1, % one by one
                    insertIndP           = [refInd refInd ];  % image pairs to run
                    insertIndN           = [refInd, circshift(refInd,-1) ];  % image pairs to run
                    offsetInd            = insertIndN;
%                 case 2, % one by one
%                     insertIndP           = [refInd refInd ];  % image pairs to run
%                     insertIndN           = [refInd circshift(refInd,-10) ];  % image pairs to run
%                     offsetInd            = insertIndN;
                case 2, % double run equivalent in two directions - not working good
                    insertIndP           = [refInd refInd ];  % image pairs to run
                    insertIndP           = [insertIndP; [refInd+nT refInd]];  % image pairs to run
                    insertIndN           = [refInd circshift(refInd,-1)  ];  % image pairs to run
                    offsetInd            = [insertIndN; [refInd circshift(refInd,-ceil(nT/2)) ]];
                    insertIndN           = [insertIndN; [refInd+ nT circshift(refInd,-ceil(nT/2)) ]];  % image pairs to run
                case 3, % with long connections - not working good
                    offsetInd           = [refInd circshift(refInd,-1)];  % image pairs to run
                    offsetInd           = [[refInd circshift(refInd,-ceil(nT/3))];offsetInd];  % image pairs to run
                    insertInd           = [[refInd circshift(refInd,+ceil(nT/3))];offsetInd];  % image pairs to run
               otherwise
                    error('bad mtrxOption')
            end
            numFFT              = size(offsetInd,1);
            
            % for target test
            %offsetInd           = [refInd ones(nT,1)];  % image pairs to run
            A                   = sparse(insertIndP(:,1),insertIndP(:,2),1,numFFT+1,nT);
            A                   = A + sparse(insertIndN(:,1),insertIndN(:,2),-1,numFFT+1,nT); %A(1,1) = 0
            A(numFFT+1,:)       = 1; % average of all of them
                        
            % sparse does not help since inv matrix is full
            A                   = pinv(full(A));
            
            % transfomr entire data array
            imgDataF            = fft2(obj.ImgData);

            % multiply by template
			imgDataF            = imgDataF(:,:,offsetInd(:,2)) .* conj(imgDataF(:,:,offsetInd(:,1)));
% 			% save memory : must be offsetInd(:,2) > offsetInd(:,1)
%             imgDataFC          = imgDataF;
% 			for k = 1:numFFT,
% 				imgDataFC(:,:,offsetInd(k,1))  = imgDataF(:,:,offsetInd(k,1)) .* conj(imgDataF(:,:,offsetInd(k,2)));
% 			end
            
            % transform back
            imgDataF           = ifft2(imgDataF,'symmetric');
           
            % find maxima (3d dim is time)
            [max1,loc1]        = max(imgDataF,[],1);
            max1               = squeeze(max1);
            loc1               = squeeze(loc1);
            
            [max2,loc2]        = max(max1,[],1);    
            rloc               = loc1(sub2ind([nC numFFT],loc2,1:numFFT));
            cloc               = loc2;
            rloc               = rloc - 1;
            cloc               = cloc - 1;
            iBool              = rloc > fix(nR/2);
            rloc(iBool)        = rloc(iBool) - nR; %   row_shift = rloc - nR - 1;
            iBool              = cloc > fix(nC/2);
            cloc(iBool)        = cloc(iBool) - nC; %   col_shift = cloc - nC - 1;

            yxShift            = [rloc(:) cloc(:)];
            yxShift(numFFT+1,:)= 0; % avergae is all zero
            
            % solve for y and x
            yxShift                 = A*yxShift;
            yxShift                 = round(yxShift(1:nT,:)); % opposite move direction
            %end
            
            % create shifted image
            obj.ImgDataFix          = obj.ImgData;
            for m = 1:nT,
                obj.ImgDataFix(:,:,m)   = circshift(obj.ImgData(:,:,m),yxShift(m,:));
            end
            obj.ImgDataFix      = cast(obj.ImgDataFix,'like',obj.ImgData);
            DTP_ManageText([], sprintf('AlgUriRegisterFast finished successfully in %4.3f sec',toc), 'I' ,0)   ;
            
        end
        % ---------------------------------------------
    
        % ==========================================
        function [obj,yxShift] = AlgUriRegisterFastStable(obj, mtrxOption)
            % AlgUriRegisterFast - implements algorithm of image alignment
            % without target image. Matrix inversion and Fourier.
            % The same as Fast but uses k*nT x nT matrices
            % Input:
            %   mtrxOption - selects different matrix
            %     ImgData - must be prloaded
            % Output:
            %     yxShiftEst - Nx2 shift array in x and y
            
            if nargin < 1, mtrxOption = 1; end
            
            [nR,nC,nT]          = size(obj.ImgData);
            %yxShift            = zeros(nT,2);
            refInd              = (1:nT)';
            
            % taken
            DTP_ManageText([], sprintf('AlgUriRegisterFast Stable Registration %d. ....',mtrxOption), 'I' ,0)   ;   tic;                         
            
            switch mtrxOption,
               case 1, % douuble run equivalent in two directions
                    shiftVal            = 1;
                    posInd              = [refInd     refInd];
                    offsetInd           = [refInd     circshift(refInd,-1)];  % image pairs to run
                    negInd              = offsetInd;
                    posInd              = [[refInd+nT refInd]; posInd];
                    offsetInd           = [[refInd    circshift(refInd,shiftVal) ]  ;offsetInd];
                    negInd              = [[refInd+nT circshift(refInd,shiftVal) ]  ;negInd];  % image pairs to run
               case 2, % douuble run equivalent in two directions
                    shiftVal            = ceil(nT/3);
                    posInd              = [refInd     refInd];
                    offsetInd           = [refInd     circshift(refInd,-1)];  % image pairs to run
                    negInd              = offsetInd;
                    posInd              = [[refInd+nT  refInd]; posInd];
                    offsetInd           = [[refInd     circshift(refInd,-shiftVal) ]  ;offsetInd];
                    negInd              = [[refInd+nT  circshift(refInd,-shiftVal) ]  ;negInd];  % image pairs to run
                case 3, % with long connections
                    shiftVal            = ceil(nT/3);
                    offsetInd           = [refInd circshift(refInd,-1)];  % image pairs to run
                    offsetInd           = [[refInd circshift(refInd,-shiftVal)];offsetInd];  % image pairs to run
                    insertInd           = offsetInd;  % image pairs to run
              otherwise
                    error('bad mtrxOption')
            end
            numFFT              = size(offsetInd,1);
            
            % for target test
            %offsetInd           = [refInd ones(nT,1)];  % image pairs to run
            A                   = sparse(posInd(:,1),posInd(:,2),1,numFFT,nT);
            A                   = A + sparse(negInd(:,1),negInd(:,2),-1,numFFT,nT); %A(1,1) = 0;
                        
            % sparse does not help since inv matrix is full
            A                   = full(A);
            A                   = pinv(A);
            
            % transfomr entire data array
            imgDataF            = fft2(obj.ImgData );

            % multiply by template
            imgDataF            = imgDataF(:,:,offsetInd(:,1)) .* conj(imgDataF(:,:,offsetInd(:,2)));
            
            % transform back
            imgDataF            = ifft2(imgDataF,'symmetric');
           
            % find maxima (3d dim is time)
            [max1,loc1]        = max(imgDataF,[],1);
            max1               = squeeze(max1);
            loc1               = squeeze(loc1);
            
            [max2,loc2]        = max(max1,[],1);    
            rloc               = loc1(sub2ind([nC numFFT],loc2,1:numFFT));
            cloc               = loc2;
            rloc               = rloc - 1;
            cloc               = cloc - 1;
            iBool              = rloc > fix(nR/2);
            rloc(iBool)        = rloc(iBool) - nR; %   row_shift = rloc - nR - 1;
            iBool              = cloc > fix(nC/2);
            cloc(iBool)        = cloc(iBool) - nC; %   col_shift = cloc - nC - 1;

            yxShift            = [rloc(:) cloc(:)];
            
            % solve for y and x
            yxShift                 = A*yxShift;
            yxShift                 = -round(yxShift(1:nT,:)); % opposite move direction
            %end
            
            % create shifted image
            for m = 1:nT,
                obj.ImgDataFix(:,:,m)   = circshift(obj.ImgData(:,:,m),yxShift(m,:));
            end
            obj.ImgDataFix      = cast(obj.ImgDataFix,class(obj.ImgData));
            DTP_ManageText([], sprintf('AlgUriRegisterFast finished successfully in %4.3f sec',toc), 'I' ,0)   ;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,yxShift, imgData] = AlgApply(obj, imgData ,algType)
            % AlgApply - wrapper for algorithm and multi dimensional image data
            % Input:
            %   algType   - selects different algorithms
            %     imgData - nRxnCxnZxnT
            % Output:
            %     yxShift - nTx2xnZ shift array in x and y
            %     imgData - nRxnCxnZxnT corrected position per slice nZ
            
            if nargin < 2, imgData    = zeros(64,64,3,128,'uint8'); end;
            if nargin < 3, algType   = 1; end;
            
            [nR,nC,nZ,nT]       = size(imgData);
            yxShift             = zeros(nT,2,nZ);
            
            % work per slice
            for z = 1:nZ,
            
                % prepare data
                obj  = SetData(obj,imgData,z);
            
                switch algType,
                    case 1, % original as reference
                        templateType        = 5;
                        [obj,estShift]      = obj.AlgImageBox(templateType);
                    case 2, % original but fast
                        templateType        = 5;
                        [obj,estShift]      = obj.AlgImageBoxFast(templateType);
                    case 3, % % Uri + Fast
                        [obj,estShift]      = obj.AlgUriRegisterFast(2);
                    case 4, % multiple iterations
                        [obj,estShift]      = obj.AlgMultipleImageBox(3);
                     
                    case 11, % good quality - first image is a template
                        [obj,estShift]      = obj.AlgImageBoxFast(3);
                       
                    otherwise
                        error('Bad Alg Type %d',algType)
                end
                
                % loose the dimension if nZ = 1
                %yxShift = squeeze(yxShift);
                yxShift(:,:,z)      = estShift;
                [obj,imgDataTmp]    = GetData(obj);
                imgData(:,:,z,:)    = imgDataTmp;
            end
            
        end
        % ---------------------------------------------
        
    
        
        
        % ==========================================
        function [obj,yxShift, imgData] = GenData(obj, imgType, shiftType)
            % GenData - try to gen data for testing
            % Input:
            %   imgType  - which image to use as input
            %   shiftType - which motion to gen
            % Output:
            %   yxShift - nT x 2 - y,x true pixel shifts
            %   ImgData - image data with shifts
            
            if nargin < 2, imgType = 1; end;
            if nargin < 3, shiftType = 1; end;
            
            switch imgType,
                case 1, % random small
                    nT          = 16;
                    imgData     = repmat(uint16(rand(256)*256),[1,1,nT]);
               case 2, % rand
                    nT          = 128;
                    imgData     = repmat(uint16(rand(256)*256),[1,1,nT]);
               case 3, % ceil
                    nT          = 128;
                    imgData     = repmat(uint16(imread('cell.tif')),[1,1,nT]);
               case 4, % cameraman
                    nT          = 128;
                    imgData     = repmat(uint16(imread('cameraman.tif')),[1,1,nT]);
               case 5, % square
                    nT          = 128;
                    im          = zeros(128);
                    im(60:74,32:64) = 100;
                    imgData     = repmat(uint16(im),[1,1,nT]);
               case 6, % circle
                    nT          = 128;
                    [x,y]       = meshgrid(1:128);
                    im          = 100 * ((x-64).^2 + (y-64).^2 < 64);
                    imgData     = repmat(uint16(im),[1,1,nT]);
               case 7, % square positioned differently
                    nT          = 128;
                    im          = zeros(128);
                    im(70:84,42:74) = 100;
                    imgData     = repmat(uint16(im),[1,1,nT]);
                    
                case 11, % true image
                    [obj, imgData] = LoadImageData(obj);
                case 12, % true image
                    fileDirName = 'C:\LabUsers\Uri\Data\Janelia\Imaging\m76\1-10-14\1_10_14_m76__005.tif';
                    [obj, imgData] = LoadImageData(obj,fileDirName);
               case 13, % true image
                    fileDirName = 'C:\UsersJ\Uri\Data\Videos\m2\4_4_14\Basler_front_04_04_2014_m2_014.avi';
                    [obj, imgData] = LoadImageData(obj,fileDirName);
               case 14, % true image
                    fileDirName = 'C:\UsersJ\Uri\Data\Videos\m2\4_4_14\Basler_side_04_04_2014_m2_016.avi';
                    [obj, imgData] = LoadImageData(obj,fileDirName);
               case 15, % synthetic 3 stack image
                    fileDirName = 'C:\LabUsers\Uri\Data\Janelia\Imaging\T2\03\03_T2_001.tif';
                    [obj, imgData] = LoadImageData(obj,fileDirName);
                    imgData        = reshape(imgData,size(imgData,1),size(imgData,2),3,[]);
                otherwise
                    error('Bad imgType')
            end
            % put it in
            %obj = SetData(obj,imgData) ;
            nT  = size(imgData,4);
            nZ  = size(imgData,3);
            if nT == 1, nT = nZ; nZ = 1; end;
            
            % define shifts
            yxShift      = zeros(nT,2);
            switch shiftType,
                case 1, % no shift
                    
                case 2, % single frame jump
                    yxShift(2,1) = 10;
                    yxShift(4,2) = 10;
                    yxShift(6,1) = -10;
                    yxShift(8,2) = -10;
                case 3, % cos in y
                    for m = 1:nT,
                        yxShift(m,1)        = round(7*cos(2*pi/nT*m*3));
                    end
                case 4, % sin/cos in y,x
                    for m = 1:nT,
                        yxShift(m,1)        = round(7*cos(2*pi/nT*m*3));
                        yxShift(m,2)        = round(9*sin(2*pi/nT*m*5));
                    end
                case 5, % long jump
                    yxShift(20:60,1) = 10;
                    yxShift(40:80,2) = 10;
                    
                case 6, % constant motion
                    yxShift(10+1:nT-10,1) = round(linspace(-32,32,nT-20));
                    %yxShift(40:60,2) = 10;
                    
                case 7, % constant motion
                    yxShift(10+1:nT-10,2) = round(linspace(32,-32,nT-20));
                    %yxShift(40:60,2) = 10;
                    
                case 11, % random noise
                    yxShift = ceil(randn(nT,2)*10);
                    
                case 12, % random noise with offset
                    yxShift = ceil(randn(nT,2)*10);
                    yxShift = bsxfun(@plus, yxShift, ceil(randn(1,2)*10));
                    
                otherwise
                    error('Bad shiftType')
            end
            
            % create shift
            for m = 1:nT,
                if nZ == 1,
                    imgData(:,:,m)   = circshift(imgData(:,:,m),yxShift(m,:));
                else
                    imgData(:,:,nZ,m)   = circshift(imgData(:,:,nZ,m),yxShift(m,:));
                end
            end
            
            % fix
            if nZ > 1,
                yxShiftTmp = repmat(yxShift*0,[1 1 nZ]);
                yxShiftTmp(:,:,nZ) = yxShift;
                yxShift            = yxShiftTmp;
            end
            
            % assign
            obj                 = obj.SetData(imgData);
            
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = ViewVideo(obj,FigNum)
            % ViewData - plays stored video.
            % Supports two and separate channels
            % Input:
            %   internal -
            % Output:
            %   ImgData,ImgDataFix  -  are played together
             if nargin  < 2, FigNum = 1; end;
           
            if isempty(obj.ImgData),
                DTP_ManageText([], sprintf('Motion Corection : requires input file load first.'), 'E' ,0);
                return
            end
            [nR1,nC1,nT1]          = size(obj.ImgData);
            if isempty(obj.ImgDataFix),
                DTP_ManageText([], sprintf('Motion Corection : Please run registration first.'), 'E' ,0);
                return
            end
            [nR2,nC2,nT1]          = size(obj.ImgDataFix);

            % player plays 3 dim movies
            D                      = zeros(nR1,nC1,3,nT1,class(obj.ImgData));
            D(:,:,1,:)             = reshape(obj.ImgData,nR1,nC1,1,nT1); %reshape(D,nR1,nC1+nC2,1,nT1);
            D(:,:,2,:)             = reshape(obj.ImgDataFix,nR1,nC1,1,nT1);
            D                      = single(D); % RGB can not be adjusted in the player
            D                      = uint8(D./max(D(:))*255);
            
            %figure(FigNum),
            implay(D)
            title(sprintf('Original and Corrected with Color Change '))
            
        end
        % ---------------------------------------------
                
        % ==========================================
        function isOK = CheckResult(obj,figNum, refShift, estShift)
            % CheckResult - computes error and shows mostion estimation results 
            
            if nargin  < 2, figNum = 1; end;
            if nargin  < 3, refShift = [0 0]; end;
            if nargin  < 4, estShift = [0 0]; end;
            
            errShift            = refShift + estShift; % opposite directions
            algErr              = (std(errShift));
            t                   = 1:size(refShift,1);
            zNum                = size(estShift,3);
            
            for z = 1:zNum,
            figure(figNum + z),set(figNum + z,'Tag','AnalysisROI');
            ii = 1; subplot(2,1,ii),plot(t,[refShift(:,ii,z) estShift(:,ii,z) errShift(:,ii,z)]),legend('ref','est','err')
            ylabel('y [pix]'),
            title(sprintf('Shift Estimation and Error z: %d y: %5.3f [pix], x: %5.3f [pix]',z,algErr(1),algErr(2)))            
            ii = 2; subplot(2,1,ii),plot(t,[refShift(:,ii,z) estShift(:,ii,z) errShift(:,ii,z)]),legend('ref','est','err')
            ylabel('x [pix]'),
            xlabel('Frame [#]'),
            end
            isOK    = true;
            
        end
        % ---------------------------------------------
        
            
        % ==========================================
        function obj = TestMultiTrialRegistration(obj)
            
            % TestMultiTrialRegistration - generates files for multi trial tests
            
            figNum              = 11;
            imgType             = 4; % camera man
            shiftType           = 12;
            fPath               = 'C:\Uri\DataJ\Janelia\Imaging\T1\01';
            
            % file gen
            for m = 1:11,
                [obj,refShift]      = GenData(obj, imgType, shiftType);
                fileDirName         = fullfile(fPath,sprintf('T1_Camera_%03d.tif',m));
                saveastiff(uint16(obj.ImgData), fileDirName);
                fileDirName         = fullfile(fPath,sprintf('T1_Camera_%03d.mat',m));
                save(fileDirName,'refShift');
            end
            
        end
        % ---------------------------------------------
              

        % ==========================================
        function obj = TestImageBox(obj, imgType, shiftType)
            
            % TestImageBox - performs testing of the methods on random shifts and differnt data
            if nargin < 2, imgType    = 1; end;
            if nargin < 3, shiftType   = 1; end;
            
            figNum              = 11;
            
            [obj,refShift]      = GenData(obj, imgType, shiftType);
            %[obj,estShift]      = obj.AlgImageBox(1);
            [obj,estShift]      = obj.AlgImageBoxFast(1);
            
            isOK = obj.CheckResult(figNum, refShift, estShift);         
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestAlgUri(obj, imgType ,shiftType)
            
            % TestAlgUri - performs testing of the mstrix inversion method on random data
            
            if nargin < 2, imgType    = 1; end;
            if nargin < 3, shiftType   = 1; end;
            
            figNum              = 2;
            
            [obj,refShift]   = GenData(obj, imgType, shiftType);
            [obj,estShift]   = obj.AlgUriRegister(1);
            
            
            isOK = obj.CheckResult(figNum, refShift, estShift);         
            
            
        end
        % ---------------------------------------------

        % ==========================================
        function obj = TestAllAlg(obj, imgType ,shiftType, algType)
            
            % TestAllAlg - runs all the algorithm
            
            if nargin < 2, imgType    = 1; end;
            if nargin < 3, shiftType   = 1; end;
            
            algNum              = length(algType);
            
            % prepare data
            [obj,refShift]      = GenData(obj, imgType, shiftType);
            
            % run algorithms
            for k = 1:algNum,
                switch algType(k),
                    case 1, % original as reference
                        [obj,estShift]      = obj.AlgImageBox(4);
                    case 2, % original but fast
                        [obj,estShift]      = obj.AlgImageBoxFast(4);
                    case 3, % My version
                        [obj,estShift]      = obj.AlgUriRegister();
                    case 4, % Uri + Fast
                        [obj,estShift]      = obj.AlgUriRegisterFast(1);
                    case 5, % Uri + Matrix Frw and Back
                        [obj,estShift]      = obj.AlgUriRegisterFast(2);
                    case 6, % Uri + Fast
                        [obj,estShift]      = obj.AlgUriRegisterFast(3);
                    case 7, % Uri + Fast + Stable
                        [obj,estShift]      = obj.AlgUriRegisterFastStable(1);
                    case 8, % Uri + Fast + Stable
                        [obj,estShift]      = obj.AlgUriRegisterFastStable(2);
                    case 11, % original with mean target
                        [obj,estShift]      = obj.AlgImageBox(5);
                    case 12, % original fast with mean target
                        [obj,estShift]      = obj.AlgImageBoxFast(5);
                    case 13, % multiple iterations
                        [obj,estShift]      = obj.AlgMultipleImageBox(3);
                        
                    otherwise
                        error('Bad Alg Type %d',algType(k))
                end
                
                % show results
                figNum          = algType(k);
                isOK = obj.CheckResult(figNum, refShift, estShift);         
            end
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestAlgFinal(obj, imgType ,shiftType)
            
            % TestAlgUri - performs testing of the mstrix inversion method on random data
            
            if nargin < 2, imgType    = 1; end;
            if nargin < 3, shiftType   = 1; end;
            
            figNum                      = 2;
            imgType                     = 15;
            shiftType                   = 4;
            
            [obj,refShift, imgData]   = GenData(obj, imgType, shiftType);
            [obj,estShift]            = AlgApply(obj, imgData ,4);
            
            
            isOK = obj.CheckResult(figNum, refShift, estShift);         
            
            
        end
        % ---------------------------------------------
        
        
    end% methods
end% classdef
