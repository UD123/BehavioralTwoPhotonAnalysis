classdef TPA_MultiPatchTracking
    %TPA_MultiPatchTracking - implements image tracking techniques 
    % using multiple patches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 06.01 28.11.17 UD 	Adopted to TPA
    % 05.08 20.11.17 UD 	Connection between patches
    % 05.07 23.10.17 UD 	Support of cData match from Labeler.... 
    % 05.06 13.09.17 UD 	Cont.... 
    % 05.04 12.09.17 UD 	Adapted for Kuka project. 
    % 05.03 31.07.17 UD 	Improved multiple ROI + configuration. 
    % 05.01 13.02.17 UD 	Improved - multiple ROI. 
    % 03.01 07.05.16 UD 	Created. 
    %-----------------------------
    
    properties (Constant)
        %ROI_TYPES           = struct('BRIGHTNESS',1,'MOTION',2);
        %RoiData             = struct('Position',[],'ImgData',[],'Name','','Type',1,'PixInd',[]);
        PatchSize           = [31 31]; % patch size x and y
    end
    
    properties
        
        
        % Which camera in use
        CamId               = 0;
        %TrigMode            = 0;  % identifier of the trigger mode
        %MaxFrameNum         = 0;  % how many frames to acquire
        
        
        % setup storage
        SetupDir            = ['..\Data\',date];
        SetupData           = [];   % structure with video analysis info
        SetupFilePattern    = 'PatchParams_%s.mat';  % setup, animal name, date
        SetupInputName      = ''; % name of the input file
        
        % Image data
        ImgCount            = 0; % count images
        ImgData             = []; % last image data
        CorrData            = [];
        VideoData           = []; % entire movie
        %ImgMask             = []; % contains image mask for ROI
        
        
        % enable show
        FigNum              = 1;
        hImg                = [];  % image handle
        hTtl                = [];
        IsDone              = true;
        
        
        
        
    end
    
    
    methods
        % =======================================
        function obj = TPA_MultiPatchTracking()
            % TPA_MultiPatchTracking - class constructor.
            %if nargin < 1, camId = 1; end;
            
            % check
            %if camId < 1 || camId > 2, error('Only Camera 1 or 2 is supported'); end;
            
            %obj = Clean(obj);
            tic;
            obj                 = Init(obj, 1);
            
        end
        
        % =======================================
        function obj = Init(obj, camId)
            % Init - init driver
            %%%
            
            if nargin < 2, camId = 1; end
            if camId < 1 || camId > 2, error('Only Camera 1 or 2 is supported'); end;
            
            % init all params
            obj.SetupData           = [];
            obj.SetupInputName      = '';
            
            obj.ImgCount            = 0;  % image data counter
            obj.ImgData             = []; % last image data
            obj.CorrData             = []; % contains patch table
            obj.VideoData           = [];
                        
            obj.IsDone              = false;     % no more movie
            obj.hImg                = [];
            
            % create setup dir
            if ~exist(obj.SetupDir,'dir'),mkdir(obj.SetupDir); end
            
        end
        
        % ==========================================
        % Find
        function obj = Find(obj,Record,ImgL,ImgR)
            % Find - find images in the record
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
            if nargin < 2, error('Record must be provided'); end;
            if nargin < 3, error('ImgL must be provided'); end;
            if nargin < 4, ImgR = []; end;
            
            % check parameters
            nT         = length(Record);
            if nT < 1 
                Print(obj,  sprintf('Vision Finder Record is empty'), 'E'); return; 
            end;
            % what is there
            [nR,nC,nD]  = size(Record{1}.ImgL);
            assert(size(ImgL,1)==nR)
            assert(size(ImgL,2)==nC)
            assert(size(ImgL,3)==nD)
            
            % params
            isMono      = isempty(Record{1}.ImgR) || isempty(ImgR);
            nR2         = ceil(nR/2);
            nR4         = ceil(nR2/2);
            nC2         = ceil(nC/2);
            q           = -15:15;
            imgRefL     = ImgL(nR4+q,nC2+q,:);
            imgRefR     = [];
            
            % right image
            if ~isMono
                imgRefR      = ImgR(nR4+q,nC2+q,:);
            end
            % debug
            figure(151),
            posLXY    = [nC2+q(1) nR4+q(1)];
            if ~isMono
                imshowpair(ImgL,ImgR,'montage');title('Ref')
                imrect(gca, [posLXY(1)+1, posLXY(2)+1, size(imgRefL,2), size(imgRefL,1)]);
                posRXY    = [nC2+q(1)+nC nR4+q(1)];
                imrect(gca, [posRXY(1)+1, posRXY(2)+1, size(imgRefR,2), size(imgRefR,1)]);
            else
                imshow(ImgL);title('Ref')
                imrect(gca, [posLXY(1)+1, posLXY(2)+1, size(imgRefL,2), size(imgRefL,1)]);
            end
            
            
            % check record dir
            maxLtot     = 0; tLtot = 1; timeStart = tic;
            maxRtot     = 0; tRtot = 1; 
            for t = 1:nT
                
                imgRegL  = Record{t}.ImgL(1:nR2,:,:);
                [obj,posLXY,maxLV,maxLU] = MatchImages(obj,imgRefL,imgRegL);  
                
                imgRegR  = Record{t}.ImgR(1:nR2,:,:);
                [obj,posRXY,maxRV,maxRU] = MatchImages(obj,imgRefR,imgRegR);
                    
                % track
                if maxLtot < maxLV
                    maxLtot = maxLV;
                    tLtot   = t;
                end
                if maxRtot < maxRV
                    maxRtot = maxRV;
                    tRtot   = t;
                end

                % debug
                figure(152), 
                if ~isMono
                imshowpair(imgRegL,imgRegR,'montage');title(sprintf('%d:CL %4.3f,CR%4.3f',t,maxLV,maxRV))
                imrect(gca, [posLXY(1)+1, posLXY(2)+1, size(imgRefL,2), size(imgRefL,1)]);
                imrect(gca, [posRXY(1)+1+nC, posRXY(2)+1, size(imgRefR,2), size(imgRefR,1)]);
                else
                imshow(imgRegL);title(t)
                imrect(gca, [posLXY(1)+1, posLXY(2)+1, size(imgRefL,2), size(imgRefL,1)]);
                end

            end
            
            %obj                 = Close(obj);
            % emergency button
            Print(obj,  sprintf('Vision Finder is Done %4.3f sec',toc(timeStart)), 'I');
            
        end
        
        % ==========================================
        % Jitter the reference pattern
        function [obj, ImgArray] = PatchJitter(obj,ImgIn)
            % PatchJitter - creates affine transform of the input
            % Input:
            %    obj        - structure with defines
            %    ImgIn      - image input
            % Output:
            %    obj        - updated values
            %   ImgArray    - ImgIn - transformed on dim 4
            
            
            % jitter
            [nR,nC,nD]  = size(ImgIn);
            rOut        = imref2d([nR,nC,nD],[1 nC],[1 nR]);
            ang         = linspace(-10,10,3); % angle in degree
            scale       = linspace(0.8,1.2,3);
            tx          = 0;
            ty          = 0;
            skew        = linspace(0.5,1.5,3);
            
            % init
            [ang,scale,skew] = meshgrid(ang,scale,skew);
            jitNum      = numel(ang);
            ImgArray    = zeros(nR,nC,nD,jitNum,'like',ImgIn);
            
            for m = 1:jitNum
                    
                    c       = scale(m)*cosd(ang(m)); % angle in degree
                    s       = scale(m)*sind(ang(m));
                    M       = [c -s 0;s*skew(m) c 0;tx ty 1];
                    tform   = projective2d(M);
                    imgOut  = imwarp(ImgIn,tform,'FillValues',0,'OutputView',rOut);
                    ImgArray(:,:,:,m) = imgOut;
            end
                
            % debug
            %figure,montage(ImgArray)
            
        end
        
        % =======================================
        % Build connection structure between patches
        function [obj,isOK] = PatchConnectInit(obj,imgFrame)
            % connects ROIs
            % Input:
            %   obj.SetupData - contains ROI data
            % Output:
            %   obj.SetupData - modified with neighborhood
            if nargin < 2, imgFrame = []; end
            isOK    = false;
            bNum    = length(obj.SetupData);
            if bNum < 1, return; end
            
            % find distances and angles
            bBoxCenter = zeros(bNum,2); % x,y pos
            for b = 1:bNum
                bBbox           = obj.SetupData(b).Bbox;
                bBoxCenter(b,:) = bBbox(1:2)+bBbox(3:4)/2;
            end
            % compute distances
            dx           = bBoxCenter(:,1) - bBoxCenter(:,1)';
            dy           = bBoxCenter(:,2) - bBoxCenter(:,2)';
            distBox      = sqrt(dx.^2 + dy.^2);
            anglBox      = atan2(dy,dx);
            
            % assign it to the structure back
            for b = 1:bNum
                obj.SetupData(b).NeighbDist = distBox(b,:);
                obj.SetupData(b).NeighbAngl = anglBox(b,:);
            end
           
            isOK    = true;
            % save
            doSaveData = true;
            if doSaveData
                [obj,isOK]  = SaveSetup(obj);
                Print(obj,'ROI structure is saved'); 
            end
            
            % debug
            if obj.FigNum < 1, return; end
            if isempty(imgFrame), return; end
            [nR,nC,nD] = size(imgFrame);
            imgS = imgFrame;
                % debug
            for b = 1:bNum                
                imgS         = insertObjectAnnotation(imgS,'rectangle',obj.SetupData(b).Bbox,obj.SetupData(b).Name,'LineWidth',2);
                for n = 1:bNum 
                imgS         = insertShape(imgS,'line',[bBoxCenter(b,:) bBoxCenter(n,:)],'color','r','LineWidth',2);
                end
            end
            %if isdeployed, return; end
            h = findobj('tag','debug_fig_135');
            if ishandle(h)
                set(h,'cdata',imgS); drawnow;
            else
                figure(obj.FigNum + 10),set(gcf,'toolbar','none','units','normalized','Name','Patch Connections');
                h = imshow(imgS);set(h,'tag','debug_fig_135');set(gca,'pos',[0 0 1 0.95]);

                %set(gca,'pos',[0 1 0 1]);
            end
            
             
        end        
        
        % ==========================================
        % Match two images
        function [obj,posXY,maxV,maxU] = MatchImages(obj,ImgRef,ImgReg)
            % MatchImages - two image match only
            % Input:
            %    obj        - structure with defines
            % Output:
            %     default values
            if nargin < 2, error('Reference must be provided'); end;
            if nargin < 3, error('Registration must be provided'); end;
            [posXY,maxV,maxU] = deal(-1);
            [nR,nC,nD]  = size(ImgRef);
            if nR < 1, return; end
            
            % correlate
            %imgReg  = rgb2gray(imgReg);
            c       = normxcorr2(ImgRef(:,:,1),ImgReg(:,:,1));
            for k = 2:nD
            c       = c + normxcorr2(ImgRef(:,:,k),ImgReg(:,:,k));
            end
            c       = c./nD;
            % protect border for second maxima
            c(1:2,:) = 0; c(:,1:2) = 0; c(end-1:end,:) = 0; c(:,end-1:end) = 0;
            % max
            maxc    = max(c(:));
            [ypeak, xpeak] = find(c==maxc);  
            yoffSet = ypeak-nR;
            xoffSet = xpeak-nC;
            
            % second maxima
            c(ypeak+(-2:2),xpeak+(-2:2)) = 0;
            maxc2   = max(c(:));
            
            % output
            posXY  = [xoffSet yoffSet];
            maxV   = maxc;
            maxU   = maxc2./maxc;
            
        end
        
        % =======================================
        % Track number of patches - no relative info
        function [obj,score] = TrackPatchROI(obj,imgFrame)
            % tracks ROIs
            score    = 0;
            bNum    = length(obj.SetupData);
            if bNum < 1, return; end
            
            [nR,nC,nD] = size(imgFrame);
            imgS       = imgFrame; % debug
            for b = 1:bNum
                
                bBbox           = obj.SetupData(b).Bbox;
                searchBbox      = obj.SetupData(b).BboxSearch;
                searchImgData   = imcrop(imgFrame,searchBbox);
                imgPatch        = obj.SetupData(b).ImgData;
            
                % compute correlation for each subregion
                [obj,posXY,maxV,maxU] = MatchImages(obj,imgPatch,searchImgData);
                score           = score + maxV;
                           
                % transform back to bbox : ul,ur,lr,ll
                newBboxRect         = bBbox;
                newBboxRect(1:2)    = searchBbox(1:2) + posXY;
                
                % debug
                %img         = imfuse(oldVideoFrame,newVideoFrame);
                imgS         = insertObjectAnnotation(imgS,'rectangle',bBbox,'ref','LineWidth',4);
                imgS         = insertObjectAnnotation(imgS,'rectangle',newBboxRect,num2str(maxV),...
                               'color','r','FontSize',16,'LineWidth',4);

            end
            score = score./bNum;
            
            % debug
            %if isdeployed, return; end
            h = findobj('tag','debug_fig_131');
            if ishandle(h)
                set(h,'cdata',imgS); drawnow;
            else
                figure(131),set(gcf,'menubar','none','toolbar','none','units','normalized');
                h = imshow(imgS);set(h,'tag','debug_fig_131');
                %set(gca,'pos',[0 1 0 1]);
            end
            
             
        end        
  
        % =======================================
        % Track number of patches - interate relative info
        function [obj,score] = TrackPatchConnectedROIs(obj,imgFrame)
            % tracks ROIs
            score    = 0;
            bNum    = length(obj.SetupData);
            if bNum < 2, Print(obj,'No Setup data is found.','W'); return; end
            % check Neigb field 
            if ~isfield(obj.SetupData(1),'NeighbDist'), Print(obj,'Setup data is not connected. Init connection structure.','W'); return; end
            
            % keep the data for update
            setupDataNew        = obj.SetupData;
            
            % evaluate scores for each box
            scoreBox            = zeros(bNum,1);
            bBoxCenter          = zeros(bNum,2); % x,y pos
            for b = 1:bNum
                
                bBbox           = obj.SetupData(b).Bbox;
                searchBbox      = obj.SetupData(b).BboxSearch;
                searchImgData   = imcrop(imgFrame,searchBbox);
                imgPatch        = obj.SetupData(b).ImgData;
            
                % compute correlation for each subregion
                [obj,posXY,maxV,maxU] = MatchImages(obj,imgPatch,searchImgData);
                scoreBox(b)     = maxV;
                           
                % transform back to bbox : ul,ur,lr,ll
                bBboxNew         = bBbox;
                bBboxNew(1:2)    = searchBbox(1:2) + posXY;
                
                % save
                setupDataNew(b).Bbox = bBboxNew;
                bBoxCenter(b,:)  = bBboxNew(1:2)+ bBboxNew(3:4)/2;
                
                % debug
                %img         = imfuse(oldVideoFrame,newVideoFrame);

            end
            score = mean(scoreBox);
            
            % compute distances
            dx           = bBoxCenter(:,1) - bBoxCenter(:,1)';
            dy           = bBoxCenter(:,2) - bBoxCenter(:,2)';
            distBox      = sqrt(dx.^2 + dy.^2);
            anglBox      = atan2(dy,dx);
            
            % build adjancency matrtix
            scoreMrtx   = zeros(bNum,bNum);
            for b = 1:bNum
                cv              = distBox(b,:); cv(b) = 1;
                rv              = obj.SetupData(b).NeighbDist; rv(b) = 1;
                distRelative    = cv./rv;
                distMetric      = 1 - abs(distRelative - median(distRelative));
                %distMetric      = 1-abs(distBox(b,:) - obj.SetupData(b).NeighbDist)/100;
                % distMetric(distMetric<0) = 0;
               
                anglMetric      = 1-sin(anglBox(b,:) - obj.SetupData(b).NeighbAngl).^2;
                scoreMrtx(b,:)  = anglMetric.*distMetric;
            end
            %scoreMrtx = scoreMrtx ./(bNum - 1);
            % one isimportant - allows to ignore 1 that moves away
            %scoreMrtx = scoreMrtx./(bNum - 1);
            scoreMrtx = scoreMrtx./(bNum - 0.3);
            
            % iterations
            for iter = 1:3
                scoreBox        = scoreMrtx * scoreBox;
                % nonlin
                v               = scoreBox < 0.75;
                scoreBox(v)     = scoreBox(v)*0.8;
                scoreBox(~v)    = scoreBox(~v)*1.1;
                v               = scoreBox > 1;
                %scoreBox(v)     = 1;
            end
            score = mean(scoreBox);
            
            
            % debug
            if obj.FigNum < 1, return; end
            [nR,nC,nD] = size(imgFrame);
            imgS = imgFrame;
                % debug
            for b = 1:bNum                
                imgS         = insertObjectAnnotation(imgS,'rectangle',obj.SetupData(b).Bbox,obj.SetupData(b).Name,'LineWidth',2);
                imgS         = insertObjectAnnotation(imgS,'rectangle',setupDataNew(b).Bbox,num2str(scoreBox(b)),'color','g','FontSize',10,'LineWidth',2);
                for n = 1:bNum 
                    imgS         = insertShape(imgS,'line',[bBoxCenter(b,:) bBoxCenter(n,:)],'color','r','LineWidth',2);
                end
            end
            
            % debug
            %if isdeployed, return; end
            h = findobj('tag','debug_fig_141');
            if ishandle(h)
                set(h,'cdata',imgS); title(score); drawnow;
            else
                figure(obj.FigNum + 30),set(gcf,'menubar','none','toolbar','none','units','normalized');
                h = imshow(imgS);set(h,'tag','debug_fig_141');
                set(gca,'pos',[0 0 1 .95]);
            end
            
             
        end        
        
        
    end
    
    % GUI
    methods
        
        % ==========================================
        % Print info and time
        function Print(obj,  txt, severity)
            % This manages info display and error
            if nargin < 2, txt = 'init';                 end
            if nargin < 3, severity = 'I';               end
            
            matchStr    = 'IWE'; cols = 'kbr';
            k = strfind(matchStr,severity);
            assert(k > 0,'severity must be IWE')
            
            % always print
            fprintf('%s : %5.3f : MPT : %s\n',severity,toc,txt);
            tic;
            
            if ~isprop(obj,'hText'), return; end
            if ~ishandle(obj.hText), return; end
            set(obj.hText,'string',txt,'ForegroundColor',cols(k));
            
        end
        
        % =======================================
        % SaveSetup - save experiment setup data
        function [obj,IsOK] = SaveSetup(obj)
            % SaveSetup - save experiment setup data
            % Input:
            %       saveDir     - string:directory to save - overrides the default
            %       animalName  - string:animal name - overrides the default
            %       trialNum    - trial start number
            %       SetupData   - structure that contains required data for analysis
            % Output:
            %       - files on the disk
            
            IsOK = false;
            
            % create save files
            setupFile       = sprintf(obj.SetupFilePattern,obj.SetupInputName); %,obj.TrialDate);
            
            % with dir
            setupFileDir     = fullfile(obj.SetupDir,setupFile);
            
            % get the data
            %[obj,setupData]   = GetSetupData(obj) ;
            setupData        = obj.SetupData;
            
            % save the data
            Print(obj,sprintf('Saving %s ... ',setupFileDir)); tic;
            try
                save(setupFileDir,'setupData');
            catch ME
                error('%s : can not save setup data', ME.message);
            end
            Print(obj,sprintf('Done in %4.3f sec.',toc)); 
            
            IsOK = true;
        end

        % =======================================
        function [obj,DoSaveData] = LoadSetup(obj)
            % LoadSetup - load experiment setup data
            % Input:
            %       saveDir     - string:directory to save - overrides the default
            %       animalName  - string:animal name - overrides the default
            % Output:
            %       DoSaveData   - save data after that
            
            DoSaveData       = true;
            obj.SetupData    = [];
            
            % create save files
            setupFile       = sprintf(obj.SetupFilePattern,obj.SetupInputName); %,obj.TrialDate);
            
            % with dir
            setupFileDir     = fullfile(obj.SetupDir,setupFile);
            
            % check
            if ~exist(setupFileDir,'file')
                Print(obj,'No Setup data is found.','W');
                return
            end
            
            bSkipFileLoad	= 1;
            if exist(setupFileDir,'file')

                Answer=questdlg('The setup for the specified animal already exists?',  'Database',  'Create New','Use it','Create New');
                if strcmp(Answer,'Use it'), bSkipFileLoad = 0;end

            end      
            if bSkipFileLoad > 0.5, return; end
            
            %[obj,setupData]   = GetSetupData(obj) ;
            
            % save the data
            Print(obj,sprintf('Loading %s ... ',setupFileDir)); tic;
            try
                s = load(setupFileDir,'setupData');
            catch ME
                error('%s : can not load setup data', ME.message);
            end
            Print(obj,sprintf('Done in %4.3f sec.',toc)); 
            
            obj.SetupData = s.setupData;
            DoSaveData = false;
        end
        
        % =======================================
        % Edit patch structure - user input
        function [obj,isOk] = EditPatch(obj,imgFrame)
            % EditPatch - gets Patch data from disk or define new, or delete and saves 
            %  imgFrame - image to be tested
            % Output:
            %  isOk - ok
            
            % check and load the previos data
            isOk                = false;
            [obj,doSaveData]    = LoadSetup(obj);
            %typeNames           = fieldnames(obj.ROI_TYPES);
            halfPatchSize       = round((obj.PatchSize-1)./2);
            [nR,nC,nD]          = size(imgFrame);
            
            % setup user input
            userIsFinished      = false;
            refreshRoi          = true;
            hRois               = [];
            hSearch             = [];
            hTxts               = [];
            figNum              = 101;
            figure(figNum),hIm = imshow(imgFrame);
            set(gcf,'Name','Patch Editor','Tag','EPC','KeyPressFcn',@(obj,evt)setappdata(obj,'flag',evt.Character));
            setappdata(figNum,'flag','');
            set(gca,'pos',[0 0 1 0.95]);
            title('Select : a-add (Finalize = double Click),r-rename,d-delete,q-quit')
            while ~userIsFinished

               % image show
                set(hIm,'cdata',imgFrame) ;  drawnow;
            
                % refersh ROI show
                roiNum              = length(obj.SetupData);
                if refreshRoi
                    delete(hRois); hRois = [];
                    delete(hSearch); hSearch = [];
                    delete(hTxts); hTxts = [];
                    for k = 1:roiNum
                        posBox = obj.SetupData(k).Bbox;
                        posRoi = [posBox(1:2);posBox(1:2)+posBox(3:4).*[0 1];...
                                  posBox(1:2)+posBox(3:4).*[1 1]; posBox(1:2)+posBox(3:4).*[1 0]; posBox(1:2)];
                        posBox = obj.SetupData(k).BboxSearch;
                        posSearch = [posBox(1:2);posBox(1:2)+posBox(3:4).*[0 1];...
                                  posBox(1:2)+posBox(3:4).*[1 1]; posBox(1:2)+posBox(3:4).*[1 0]; posBox(1:2)];
                        txt     = obj.SetupData(k).Name;
                        hold on; 
                        hRois(k)    = plot(posRoi(:,1),posRoi(:,2),'g'); 
                        hSearch(k)  = plot(posSearch(:,1),posSearch(:,2),'y'); 
                        hTxts(k)    = text(posRoi(1,1),posRoi(1,2),txt,'Color','r'); 
                        hold off;
                    end
                    refreshRoi = false;
                end
            
                % Terminate if any user input
                if ~ishandle(figNum), return; end
                flag = getappdata(figNum,'flag');
                switch flag
                    case 'q', userIsFinished = true;
                    case 'a_old' % add
                        h           = imfreehand(gca,'Closed',true);
                        position    = wait(h); 
                        posc        = round(mean(position));
                        bbox        = [posc-halfPatchSize obj.PatchSize];
                        obj.SetupData(roiNum+1).Bbox      = bbox;
                        obj.SetupData(roiNum+1).ImgData   = imcrop(imgFrame,bbox);
                        obj.SetupData(roiNum+1).Name      = sprintf('P: %d',roiNum+1);
                        bboxSearch       = bbox;
                        bboxSearch(1:2)  = max(1, bbox(1:2) - halfPatchSize*5);
                        bboxSearch(3:4)  = halfPatchSize*12;
                        bboxSearch(3)    = bboxSearch(3) - max(0,bboxSearch(1) + bboxSearch(3) - nC);
                        bboxSearch(4)    = bboxSearch(4) - max(0,bboxSearch(2) + bboxSearch(4) - nR);
                        obj.SetupData(roiNum+1).BboxSearch = bboxSearch;
                        
                        refreshRoi  = true;
                        doSaveData  = true;
                        delete(h);
                    case 'a' % add
                        h           = impoint(gca);
                        posc        = wait(h); 
                        bbox        = [posc-halfPatchSize obj.PatchSize];
                        obj.SetupData(roiNum+1).Bbox      = bbox;
                        obj.SetupData(roiNum+1).ImgData   = imcrop(imgFrame,bbox);
                        obj.SetupData(roiNum+1).Name      = sprintf('P: %d',roiNum+1);
                        bboxSearch       = bbox;
                        bboxSearch(1:2)  = max(1, bbox(1:2) - halfPatchSize*5);
                        bboxSearch(3:4)  = halfPatchSize*12;
                        bboxSearch(3)    = bboxSearch(3) - max(0,bboxSearch(1) + bboxSearch(3) - nC);
                        bboxSearch(4)    = bboxSearch(4) - max(0,bboxSearch(2) + bboxSearch(4) - nR);
                        obj.SetupData(roiNum+1).BboxSearch = bboxSearch;
                        
                        refreshRoi  = true;
                        doSaveData  = true;
                        delete(h);                 case 'r' % change name
                        roiNames = {obj.SetupData(:).Name};
%                         for m = 1:roiNum
%                             roiNames{m} = obj.SetupData(m).Name;
%                         end
                        [s,ok] = listdlg('PromptString','Select ROI :','ListString',roiNames,'SelectionMode','single');
                        if ~ok, continue; end
                        answer   = inputdlg('Rename','Rename',1,roiNames(s));
                        obj.SetupData(s).Name       = answer{1};
                        refreshRoi  = true;
                        doSaveData  = true;
                    case 'd' 
                        roiNames = {obj.SetupData(:).Name};
                        [s,ok] = listdlg('PromptString','Select ROI to delete :','ListString',roiNames,'SelectionMode','single');
                        if ~ok, continue; end
                        obj.SetupData(s) = [];
                        refreshRoi  = true;
                        doSaveData  = true;
                    case 'p' % test uitable
                        roiNames = {obj.SetupData(:).Name};
                        [s,ok]   = listdlg('PromptString','Select ROI :','ListString',roiNames,'SelectionMode','single');
                        if ~ok, continue; end
                        setupD  = obj.SetupData(s);
                        setupD  = rmfield(setupD,{'Position','Hist','Ind'});
                        cData   = struct2cell(setupD);
                        
                        uf      = uifigure;
                        t       = uitable('Parent',uf,'Position',[20 20 300 400],'CellEditCallback',@(x)disp(x));
                        t.Data  = cData;
                        t.ColumnEditable = [true false];
                        t.RowName = fieldnames(setupD);
                        t.ColumnName = {'Value'};
                end
                setappdata(figNum,'flag','')            
            end
            
%             % create search box
%             roiNum              = length(obj.SetupData);
%             [nR,nC,nD]          = size(imgFrame);
%             for k = 1:roiNum
%                 bbox             = obj.SetupData(k).Bbox;
%                 bboxSearch       = bbox;
%                 bboxSearch(1:2)  = max(1, bbox(1:2) - halfPatchSize*5);
%                 bboxSearch(3:4)  = bbox(1:2) + halfPatchSize*7;
%                 bboxSearch(3)    = bboxSearch(3) - max(0,bbox(1) + bboxSearch(3) - nC);
%                 bboxSearch(4)    = bboxSearch(4) - max(0,bbox(2) + bboxSearch(4) - nR);
%                 obj.SetupData(k).BboxSearch = bboxSearch;
                % additional var for graphics and events
%                 obj.SetupData(k).Ind                = ind;
%                 obj.SetupData(k).IsActive           = false;
%                 obj.SetupData(k).IsActiveBefore     = false; % one time trigger
%                 obj.SetupData(k).Hist   = []; % history info
%                 obj.SetupData(k).hLine  = [];
%                 obj.SetupData(k).hText  = [];

%            end
            
            % save
            if doSaveData,
                [obj,IsOK]              = SaveSetup(obj);
                fprintf('I : ROI is updated\n'); 
            end
            
            % clean up
            close(figNum);
        end
        
        % =======================================
        function obj = ShowVideoRealTime(obj, Img, FrameId)
            % ShowVideoRealTime - show video in real time.
            % Init and show 
            if nargin < 3, FrameId = obj.ImgCount; end;
            
            if obj.FigNum < 1, return; end;
            if nargin < 2, error('Must have image data'); end
            roiNum      = length(obj.SetupData);
            %FrameNum
            %obj.IsDone = true;
            if isempty(obj.hImg)
                % setup
                figure(obj.FigNum),set(gcf,'Name','Camera View','Tag','EPC'); 
                obj.hImg    = imshow(Img); 
                hold on;
                for m = 1:roiNum
                        posBox = obj.SetupData(m).Bbox;
                        position = [posBox(1:2);posBox(1:2)+posBox(3:4).*[0 1];...
                                  posBox(1:2)+posBox(3:4).*[1 1]; posBox(1:2)+posBox(3:4).*[1 0]; posBox(1:2)];

                     obj.SetupData(m).hLine = plot(position(:,1),position(:,2),'g'); 
                     obj.SetupData(m).hText = text(mean(position(:,1)),mean(position(:,2)),obj.SetupData(m).Name,'color','g'); 
                end
                set(gca,'pos',[0 0 1 .95]);%set(gcf,'menubar','none'); 
                obj.hTtl   = title('Result'); 
                hold off;
                obj.IsDone = false;
           else
%                 if ~ishandle(obj.hImg), 
%                     obj.IsDone = true; return; 
%                 end
                try
                    set(obj.hImg,'cdata',Img);  drawnow; %('EXPOSE'); %set(obj.hTtl ,'string',num2str(FrameNum));
                    for m = 1:roiNum
                         txt = 'No Detect'; clr = 'y';
                         %if obj.SetupData(m).IsActive, txt = 'Trigger';     clr = 'r'; end
                         set(obj.SetupData(m).hLine,'color',clr); 
                         set(obj.SetupData(m).hText,'string',txt,'color',clr); 
                    end
                    set(obj.hTtl,'string',sprintf('Frame %4d: %s',FrameId));
                catch
                    obj.IsDone = true;   
                end
            end
            
        end
        
        % =======================================
        function obj = LoadLabelerData(obj,dataPath)
            % LoadLabelerData - load data from the labeler
            % Input:
            %       dataPath    - string:to file with data
            % Output:
            %       SetupData   - becomes a table
            
            obj.CorrData    = [];
            
            % check
            if ~exist(dataPath,'file')
                Print(obj,sprintf('No Labeler data is found.'));
                return
            end
            %[obj,setupData]   = GetSetupData(obj) ;
            
            % save the data
            Print(obj,sprintf('Loading %s ... ',dataPath)); tic;
            try
                s = load(dataPath,'corrData');
            catch ME
                error('%s : can not load setup data', ME.message);
            end
            Print(obj,sprintf('Done in %4.3f sec.',toc)); 
            
            obj.CorrData = s.corrData;
        end
        
        % =======================================
        % load entire movie file
        function obj = LoadVideoData(obj,dataPath)
            % LoadVideoData - load data from the movie
            % Input:
            %       dataPath    - string:to file with data
            % Output:
            %       SetupData   - becomes a table
            
            if ~isempty(obj.VideoData)
                butPress = questdlg('Would you like to reload the video data?');
                if strcmp(butPress,'No'), return; end
            end
            %obj.VideoData    = [];
            
            % check
            if ~exist(dataPath,'file')
                Print(obj,sprintf('No Video data is found.'),'E');
                return
            end
            
            % save the data
            Print(obj,sprintf('Loading %s ... ',dataPath)); tic;
            try
                vid             = VideoReader(dataPath);
                obj.VideoData   = read(vid,[1 Inf]);
           catch ME
                error('%s : can not load video data', ME.message);
            end
            Print(obj,sprintf('Done in %4.3f sec.',toc)); 
            
        end
        
        % =======================================
        % Prepare setup from Labeler data
        function obj = PrepareSetupData(obj,imagePath,frameId)
            % PrepareSetupData - gets Patch data from corrData set 
            %  imagePath - path to image to be tested
            %  frameId   - which frame to read
            % Output:
            %  SetupData
            if nargin < 2, error('Bad input'); end
            if nargin < 3, frameId = 1; end
            
            % check that CorrData is loaded
            if isempty(obj.CorrData)
                Print(obj, 'Please load CorrData first','E');
                return
            end
            % check that Video Data is loaded
            if isempty(obj.VideoData)
                Print(obj, 'Please load Video first','E');
                return
            end
            
            % find the reference frame
            frameIds       = cell2mat(obj.CorrData.frameNumber);
            rowInd = find(frameIds >= frameId,1);
            if isempty(rowInd)
                Print(obj, 'Please set correct frame id','E');
                return
            end
            frameId             = obj.CorrData.frameNumber{rowInd};
            Print(obj, sprintf('Closest reference frame %4d',frameId));
            
%             % find the reference image 
%             fileName            = fullfile(imagePath,obj.CorrData.imageFileName{rowInd});
%             try
%                imgFrame         = imread(fileName); 
%             catch
%                 Print(obj, sprintf('Can load image file name %s',fileName),'E');
%                 return
%             end

            imgFrame            = obj.VideoData(:,:,:,frameId);
            [nR,nC,nD]          = size(imgFrame);
            
            % assign rois
            roiNum              = size(obj.CorrData.boxes{rowInd},1);
            for k = 1:roiNum
                bbox            = obj.CorrData.boxes{rowInd}(k,:);
                lbl             = obj.CorrData.labels{rowInd}{k};
                %pos             = obj.CorrData.positions{rowInd}(k,:);
                
                % assign
                obj.SetupData(k).Bbox      = bbox;
                obj.SetupData(k).ImgData   = imcrop(imgFrame,bbox);
                obj.SetupData(k).Name      = sprintf('%d-%s',frameId,lbl);
                %obj.SetupData(k).Pose      = pos;
                
                % search region
                bboxSearch       = bbox;
                patchSize        = bbox(3:4);
                bboxSearch(1:2)  = max(1, bbox(1:2) - patchSize);
                bboxSearch(3:4)  = patchSize*3;
                bboxSearch(3)    = bboxSearch(3) - max(0,bboxSearch(1) + bboxSearch(3) - nC);
                bboxSearch(4)    = bboxSearch(4) - max(0,bboxSearch(2) + bboxSearch(4) - nR);
                obj.SetupData(k).BboxSearch = bboxSearch;
            end
            
            % connect patches
            obj                = PatchConnectInit(obj,imgFrame);

            
            % show
            if obj.FigNum < 1, return; end
            figNum  = obj.FigNum + 20;
            figure(figNum),imshow(imgFrame);
            set(gca,'pos',[0 0 1 0.95]);
            hold on; 
            %  ROI show
            roiNum              = length(obj.SetupData);
            for k = 1:roiNum
                posBox = obj.SetupData(k).Bbox;
                posRoi = [posBox(1:2);posBox(1:2)+posBox(3:4).*[0 1];...
                          posBox(1:2)+posBox(3:4).*[1 1]; posBox(1:2)+posBox(3:4).*[1 0]; posBox(1:2)];
                posBox = obj.SetupData(k).BboxSearch;
                posSearch = [posBox(1:2);posBox(1:2)+posBox(3:4).*[0 1];...
                          posBox(1:2)+posBox(3:4).*[1 1]; posBox(1:2)+posBox(3:4).*[1 0]; posBox(1:2)];
                txt     = obj.SetupData(k).Name;
                plot(posRoi(:,1),posRoi(:,2),'g'); 
                plot(posSearch(:,1),posSearch(:,2),'y'); 
                text(posRoi(1,1),posRoi(1,2),txt,'Color','r'); 
            end
            hold off;
        end
        
    end
    
    
    % Test 
    methods

        
        % =======================================
        function obj = TestEditPatch(obj)
            % TestEditPatch - test how video analysis is working
            
            obj             = Init(obj);
            
            % define video input
            videoDir         = 'D:\Uri\Data\Videos\Robi\';
            videoFile        = 'astech1.mp4';
            videoDirFile     = fullfile(videoDir,videoFile);
            
            videoSrc         = VideoReader(videoDirFile);
            imgFrame         = readFrame(videoSrc);
            imgFrame         = imresize(imgFrame,0.5);
            
            % get ROI
            obj             = EditPatch(obj,imgFrame);
            obj             = PatchConnectInit(obj,imgFrame);
            
        end
        
        % =======================================
        function obj = TestPatchJitter(obj)
            % TestPatchJitter - test jitter of the patch
            
            obj             = Init(obj);
            
            % define input
            imgFrame        = zeros(31);
            imgFrame(13:19,13:19) = 64;
            %imgFrame(1:15,1:15) = 64;imgFrame(16:31,16:31) = 64;
            
            % get ROI
            [obj, ImgArray] = PatchJitter(obj,imgFrame);
            
            % debug
            figure,montage(ImgArray)
            
        end
        
        % =======================================
        function obj = TestVideoAnalysis(obj)
            % TestVideoAnalysis - test how video analysis is working
            
            obj             = Init(obj);
                       
            % define video input
            videoDir         = 'D:\Uri\Data\Videos\Robi\';
            videoFile        = 'astech1.mp4';
            [~,obj.SetupInputName] = fileparts(videoFile);
            
            videoSrc         = VideoReader(fullfile(videoDir,videoFile));
            imgData          = readFrame(videoSrc);
            
            % get ROI
            imgFrame         = imresize(imgData(:,:,:,1),.5);
            obj              = EditPatch(obj,imgFrame);
            
            % do analysis
            fprintf('I : Analysis ... '); tic; m = 0;
            while hasFrame(videoSrc) 
                m                   = m+1;
                imgFrame            = readFrame(videoSrc);
                imgFrame            = imresize(imgFrame,.5);
                [obj,isOk]          = TrackPatchROI(obj,imgFrame);
                obj                 = ShowVideoRealTime(obj, imgFrame, m);
            end
            fprintf('Done in %4.3f sec.\n',toc); 
            
        end
   
        % =======================================
        function obj = TestConnectedPatchTracking(obj)
            % TestConnectedPatchTracking - uses connecttion to track ROIs
            
            obj             = Init(obj);
                       
            % define video input
            videoDir         = 'D:\Uri\Data\Videos\Robi\';
            videoFile        = 'astech1.mp4';
            [~,obj.SetupInputName] = fileparts(videoFile);
            
            videoSrc         = VideoReader(fullfile(videoDir,videoFile));
            imgData          = readFrame(videoSrc);
            
            % get ROI
            imgFrame         = imresize(imgData(:,:,:,1),.5);
            obj              = EditPatch(obj,imgFrame);
            obj              = PatchConnectInit(obj,imgFrame);
            
            % do analysis
            fprintf('I : Analysis ... '); tic; m = 0;
            while hasFrame(videoSrc) 
                m                   = m+1;
                imgFrame            = readFrame(videoSrc);
                imgFrame            = imresize(imgFrame,.5);
                [obj,isOk]          = TrackPatchConnectedROIs(obj,imgFrame);
                %obj                 = ShowVideoRealTime(obj, imgFrame, m);
            end
            fprintf('Done in %4.3f sec.\n',toc); 
            
        end
   
        
        
        % =======================================
        % Real time web cam tracking
        function obj = TestWebcamAnalysis(obj)
            % TestVideoAnalysis - test how video analysis is working
            
            obj             = Init(obj);
                       
            % define video input
            wlist               = webcamlist;
            assert(~isempty(strfind(wlist,'270')), 'Camera 1 is not connected');

            resolutionId       = 1;        % 3-'320x240' ; % 1-'640x480'; % 
            webCamId           = length(wlist);
            vidObj             = webcam(webCamId);%TH_WebCamInit(2);            % init
            vidObj.Resolution  = vidObj.AvailableResolutions{resolutionId};
            obj.SetupInputName = sprintf('webcam_N%dR%d',webCamId,resolutionId);
            
            imgFrame            = snapshot(vidObj); %
            imgFrame            = snapshot(vidObj); %
            
            % get ROI
            %imgFrame            = imresize(imgData(:,:,:,1),.5);
            obj                 = EditPatch(obj,imgFrame);
            
            % do analysis
            fprintf('I : Analysis ... '); tic; m = 0; obj.IsDone = false;
            while ~obj.IsDone 
                m                   = m+1;
                imgFrame            = snapshot(vidObj);
                %imgFrame            = imresize(imgFrame,.5);
                [obj,isOk]          = TrackPatchROI(obj,imgFrame);
                obj                 = ShowVideoRealTime(obj, imgFrame, m);
            end
            fprintf('Done in %4.3f sec.\n',toc); 
            clear vidObj
        end
        
        % =======================================
        % Load database from Labeler and find an image frame
        function obj = TestLabelerData(obj,refFrameId)
            % TestLabelerData - test how analysis is working on labeler data
            if nargin < 2, refFrameId = 601; end
            
            %obj                 = Init(obj);
            
            % params
            videoName           = 'movie_comb.avi';
            dataPath            = 'C:\LabUsers\Uri\Data\Janelia\Videos\D16a\8_15_14\Basler_15_08_2014_d16_001';
            obj.FigNum          = 1;
            
            % load video data
            videoPath           = fullfile(dataPath,videoName);
            obj                 = LoadVideoData(obj,videoPath);
                       
            % label load
            corrPath           = strrep(videoPath,'.avi','_LabelData.mat');
            obj                = LoadLabelerData(obj,corrPath);
            
            % define reference dataset
            dataPath            = 'C:\LabUsers\Uri\Data\Janelia\Videos\D16a\8_15_14\Basler_15_08_2014_d16_005';
            videoPath           = fullfile(dataPath,videoName);
            obj                 = PrepareSetupData(obj,videoPath,refFrameId);
            
            % load another or the same file
            %videoName               = 'Basler_side_10_02_2014_m8_1.avi';
            %videoPath               = fullfile(dataPath,videoName);
            %obj                     = LoadVideoData(obj,videoPath);
            
            % do search
            %frameIds                = cell2mat(obj.CorrData.frameNumber);
            %frameIds                = 750:850;
            frameIds                = 1:size(obj.VideoData,4);
            rowNum                  = numel(frameIds);
                    
            % init score
            scoreTotal              = zeros(rowNum,1);

            
            % do analysis
            fprintf('I : Analysis ... '); tic; m = 0;
            while m < rowNum %hasFrame(videoSrc) 
                m                   = m+1;
                %imgFrame            = readFrame(videoSrc);
                imgFrame            = obj.VideoData(:,:,:,frameIds(m));
                %imgFrame            = imresize(imgFrame,.5);
                [obj,score]         = TrackPatchConnectedROIs(obj,imgFrame);
                scoreTotal(m,1)     = score;
               %obj                 = ShowVideoRealTime(obj, imgFrame, m);
            end
            fprintf('Done in %4.3f sec.\n',toc); 

            
            % find best 5 frames
            [mv,mi] = maxk(scoreTotal,3);
            fprintf('Best matching frames %4d\n',frameIds(mi(:)));
            
            % show 
            figure(121),plot(scoreTotal),xlabel('Frmae #'),title('Score')
            
            
        end
        
        
    end
    
end

