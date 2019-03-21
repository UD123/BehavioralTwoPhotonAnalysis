classdef TPA_MultiTrialTwoPhotonManager
    % TPA_MultiTrialTwoPhotonManager - loads raw data from all trials.
    % Computes transformations and extracts relevant info without ROIs
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 28.04 15.01.18 UD     Pixel correlation in time.
    % 26.06 16.07.17 UD     Dealing with boundaries.
    % 26.05 11.07.17 UD     Adding ROI extraction.
    % 25.13 23.05.17 UD     Created.
    %-----------------------------
    
    properties (Constant)
        PROCESS_TYPES       = {'dFF','Mean','STD','Time'};
    end
    
    properties
        
        % Control
        ProcessType 
        
        % Data
        ImgTrialArray        % image trial data
        ActiveZstackIndex    % which z stack
        SliceNum             % how many z stacks
        ClusterNum           % how many clusters to use
        TrialInd            % which trial should be updated
        StrROI              % strROI for show only
        ImgROI              % image with marked ROI
        ImgSvdArray         % svd decomposition
        ImgCluster          % cell clustering
        StrNewROI           % auto generated ROIS
        MaxShift            % max shift in registration - to prevent artifacts [X Y]
        
        % GUI
        hFig            % figure for query gen
        
        
    end % properties
    properties (SetAccess = private)
    end
    
    methods
        
        % ==========================================
        function obj = TPA_MultiTrialTwoPhotonManager()
            % TPA_MultiTrialTwoPhotonManager - constructor
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            %if nargin < 1, error('Requires Par structure'); end;
            
            % init
            obj.ProcessType         = 1;
            obj.SliceNum            = 1;
            obj.ActiveZstackIndex   = 1;
            obj.ClusterNum          = 3;
            
            % Load data
            %obj             = LoadDataFromTrials(obj,Par);
            
            
        end
        
        % ==========================================
        function [obj,isOK] = SetParams(obj,FigNum)
            % SetParams - set obj params 
            % Inputs:
            %   obj         - control structure
            %
            % Outputs:
            %   obj         - control structure updated
            
            if nargin < 2, FigNum = 145; end
            isOK = false;
            prompt          = { 
                'Processing Type [1-dFF, 2-Mean, 3-STD, 4-Time] :',...
                'Z Stack [1-2-3]:',...
                'Cluster Number [3:20]:',...
                };
            defaultanswer   =  {...
                num2str(obj.ProcessType),...
                num2str(obj.ActiveZstackIndex),...
                num2str(obj.ClusterNum),...
                };
            name            = 'Set Parameters';
            numlines        = 1;
            
            options.Resize      = 'on';
            options.WindowStyle = 'modal';
            options.Interpreter = 'none';
            
            % user input required
            answer          = inputdlg(prompt,name,numlines,defaultanswer,options);
            
            % check
            if isempty(answer), return; end % cancel
            
            % else
            obj.ProcessType         = str2num(answer{1});
            obj.ActiveZstackIndex   = str2num(answer{2});
            obj.ClusterNum          = str2num(answer{3});
            
            % validate
            obj.ProcessType         = max(1,min(4,obj.ProcessType));
            obj.ActiveZstackIndex   = max(1,min(3,obj.ActiveZstackIndex));
            obj.ClusterNum          = max(3,min(20,obj.ClusterNum));
            
            
            isOK        = true;
            DTP_ManageText([], sprintf('AutoDetect: parameters are updated'),  'I' ,0);
            
        end
        
        % ==========================================
        function obj = LoadDataFromTrials(obj,Par)
            % LoadDataFromTrials - loads all the availabl info
            % Input:
            %     Par - header properties
            % Output:
            %     obj - updated structure
            
            % attach
            global SData 

            %%%%%%%%%%%%%%%%%%%%%%
            % Run over selected files/trials and load the raw data
            %%%%%%%%%%%%%%%%%%%%%%
            Par.DMT                 = Par.DMT.CheckData(false);    % important step to validate number of valid trials    
            validTrialNum           = Par.DMT.ValidTrialNum;
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('AutoDetect: Missing data in directory %s. Please check the folder or run Data Check',Par.DMT.RoiDir),  'E' ,0);
                return
            else
                DTP_ManageText([], sprintf('AutoDetect: Found %d files. Processing ...',validTrialNum),  'I' ,0);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Select which trial to write
            %%%%%%%%%%%%%%%%%%%%%%
            if isa(Par.DMT,'TPA_DataManagerPrarie') || isa(Par.DMT,'TPA_DataManagerTwoChannel')
            trialFileNames        = Par.DMT.VideoDirNames(:);
            else
            trialFileNames        = Par.DMT.VideoFileNames;
            end

            [s,ok] = listdlg('PromptString','Select Trials to Process :','ListString',trialFileNames,'SelectionMode','multiple', 'ListSize',[300 500]);
            if ~ok, return; end;

            selectedInd         = s;
            selectedTrialNum    = length(s);     

            obj.ImgTrialArray   = [];
            obj.ImgSvdArray     = [];
            obj.ImgCluster      = [];
            obj.StrROI          = [];
            obj.ImgROI          = [];
            obj.MaxShift        = [0 0];
            


            for m = 1:selectedTrialNum

                    %%%%%%%%%%%%%%%%%%%%%%
                    % Load Trial
                    %%%%%%%%%%%%%%%%%%%%%%
                    trialInd                          = selectedInd(m);
                    [Par.DMT,isOK]                    = Par.DMT.SetTrial(trialInd);
                    [Par.DMT, SData.imTwoPhoton]      = Par.DMT.LoadTwoPhotonData(trialInd);
                    % apply shift
                    [Par.DMT, strShift]               = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strShift');
                    [Par.DMT, SData.imTwoPhoton]      = Par.DMT.ShiftTwoPhotonData(SData.imTwoPhoton,strShift);
                    % remeber max shoft
                    obj.MaxShift                      = max(obj.MaxShift,max(max(abs(strShift),[],1),[],3));
                    
                    % load ROIs for show only
                    if isempty(obj.StrROI)
                    [Par.DMT, obj.StrROI]             = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strROI');
                    end

                    %%%%%%%%%%%%%%%%%%%%%%
                    % Process dF/F for each trial
                    %%%%%%%%%%%%%%%%%%%%%%
                    [obj,imgOut]                      = ProcessTrialData(obj,SData.imTwoPhoton);
                    if isempty(obj.ImgTrialArray), obj.ImgTrialArray = repmat(imgOut,[1 1 1 selectedTrialNum]); end;
                    obj.ImgTrialArray(:,:,:,m)        = imgOut;

                    %%%%%%%%%%%%%%%%%%%%%%
                    % Save back
                    %%%%%%%%%%%%%%%%%%%%%%
                    % start save
                    %Par.DMT                         = Par.DMT.SaveAnalysisData(Par.DMT.Trial,'strROI',SData.strROI);                

            end
            DTP_ManageText([], sprintf('AutoDetect: processed for %d trials.',selectedTrialNum),  'I' ,0);
            
            obj.TrialInd    = selectedInd;
            figNum          = sum(selectedInd) + obj.ProcessType + 1*obj.ActiveZstackIndex;
            obj             = ShowArray(obj,figNum);            
            
        end
         
        % ==========================================
        function [obj,imgOut] = ProcessTrialData(obj,imgArray)
            % ProcessData - computes the transformation on time data
            % Input:
            %     obj - current structure
            %     imgArray - NxMxZxT - image array
            % Output:
            %     obj - updated structure
            %     imgOut - NxM image
            
            
            if nargin < 2, error('Need imgArray'); end;
            
            % init
            [nR,nC,nZ,nT]           = size(imgArray);
            if nZ > 1, nZ = nZ - 1; end % do not process the last plane
            
            % check
            if nT < 2,
                errordlg('The data array is not correct structure')
                return
            end
            if obj.ActiveZstackIndex > nZ
                DTP_ManageText([], sprintf('Specified Z-Stack does not exists....'), 'W' ,0);
                obj.ActiveZstackIndex = nZ;
            end
            imgOut              = single(imgArray(:,:,:,1));

            % process
            for z = 1:nZ,
            switch obj.ProcessType
                case 1 % DFF
                    DTP_ManageText([], sprintf('Computing Image transformation. Please wait....'), 'I' ,0);
                    %imageInTmp        = single(squeeze(imgArray(:,:,obj.ActiveZstackIndex,:)));
                    imageInTmp        = single(squeeze(imgArray(:,:,z,:)));
                    filtH             = ones(3,3,5)/45;
                    imageInTmp        = imfilter(imageInTmp,filtH);
                    imageInTmp       = sort(imageInTmp,3,'descend');
                    imNum             = ceil(size(imageInTmp,3)*0.05);
                    %imageIn           = mean(imageInMean(:,:,1:imNum),3) - mean(imageInMean(:,:,end-imNum:end),3);
                    imageInMean      = mean(imageInTmp(:,:,end-imNum:end),3);
                    imageInMean      = mean(imageInMean(:)) + imageInMean;
                    imgOut(:,:,z)    = mean(imageInTmp(:,:,1:imNum),3) ./imageInMean - 1;
                    %imgOut           = imgOut .* 100; % scale for show
                    
                case 2 % Mean
                    imgOut(:,:,z)   = squeeze(mean(imgArray(:,:,z,:),4));

               case 3 % STD
                    imageInTmp        = single(squeeze(imgArray(:,:,z,:)));
                    imgOut(:,:,z)   = std(imageInTmp,[],3);

               case 4 % Time
                    imageInTmp       = single(squeeze(imgArray(:,:,z,:)));
                    imgOut(:,:,z)    = std(imageInTmp,[],3);
                    
                otherwise
                    error('Usupported process type')
            end
            end
            
            % remove boundaties
            imgOut(1:obj.MaxShift(2),:,:,1)     = single(0);
            imgOut(nR-obj.MaxShift(2):nR,:,:,1) = single(0);
            imgOut(:,1:obj.MaxShift(1),:,1)     = single(0);
            imgOut(:,nC-obj.MaxShift(2):nC,:,1) = single(0);
            
            
            DTP_ManageText([], sprintf('AutoDetect: Trial processing is done.'),  'I' ,0);
            
            
            
        end
        
         % ==========================================
        function [obj,imgOut] = DecomposeKmeans(obj)
            % DecomposeKmeans - perform Kmeans on the dF/F data
            % Input:
            %     obj - current structure
            %     imgArray - NxMxZxT - image array
            % Output:
            %     obj - updated structure
            %     imgOut - NxMxK image
            
            
            % init
            [nR,nC,nZ,nT]           = size(obj.ImgTrialArray);
            imgOut = [];
            % check
            if nT < 2,
                errordlg('The data array is not correct structure')
                return
            end
            if obj.ActiveZstackIndex > nZ
                DTP_ManageText([], sprintf('Specified Z-Stack does not exists....'), 'W' ,0);
                obj.ActiveZstackIndex = nZ;
            end
            zIndex              = obj.ActiveZstackIndex; % already seleceted
            
            % process K-Means
            DTP_ManageText([], sprintf('AutoDetect: K-Means processing ... wait please.'),  'I' ,0);
            imgArray            = reshape(obj.ImgTrialArray(:,:,zIndex,:),nR*nC,nT);
            
            % remove low value or low variation points
            Xmean               = mean(imgArray,2);
            X                   = bsxfun(@minus, imgArray, Xmean);
            Xnorm               = sqrt(sum(X.^2, 2));
            ii                  = Xmean < 10 & Xnorm < 1;
            %imgArray(ii,:)      = 0;
            imgActive           = imgArray(~ii,:);
            idx1                = ii*0;

            % Classify
            clusterNum          = obj.ClusterNum;
            %idx3                = kmeans(imgActive,clusterNum,'MaxIter',500,'Replicates',3,'Distance','correlation');
            %idx3                = kmeans(imgActive,clusterNum,'MaxIter',1000,'Distance','correlation','Replicates',10,'Options',statset('UseParallel',1),'Display','final');
            idx3                = kmeans(imgActive,clusterNum,'MaxIter',1000,'Distance','correlation','Replicates',10,'Display','final');
            idx1(~ii)           = idx3;
            obj.ImgCluster      = reshape(idx1,nR,nC);
            
            DTP_ManageText([], sprintf('AutoDetect: K-Means processing is done.'),  'I' ,0);
            
            % show
            figNum              = sum(obj.TrialInd) + obj.ProcessType + 20*obj.ActiveZstackIndex;
            obj                 = ShowCluster(obj,figNum);
            
        end

        
        
         % ==========================================
        function [obj,imgOut] = DecomposeSVD(obj)
            % DecomposeSVD - perform SVD decomposition
            % Input:
            %     obj - current structure
            %     imgArray - NxMxZxT - image array
            % Output:
            %     obj - updated structure
            %     imgOut - NxMxK image
            
            
            % init
            [nR,nC,nZ,nT]           = size(obj.ImgTrialArray);
            imgOut = [];
            % check
            if nT < 2,
                errordlg('The data array is not correct structure')
                return
            end
            if obj.ActiveZstackIndex > nZ
                DTP_ManageText([], sprintf('Specified Z-Stack does not exists....'), 'W' ,0);
                obj.ActiveZstackIndex = nZ;
            end
            zIndex              = obj.ActiveZstackIndex; % already seleceted
            
            % process SVD
            DTP_ManageText([], sprintf('AutoDetect: SVD processing ... wait please.'),  'I' ,0);
            imgArray            = reshape(obj.ImgTrialArray(:,:,zIndex,:),nR*nC,nT);
            [u,s,v]             = svd(imgArray,0);
            
            % use 90%
            sd                  = cumsum(diag(s));
            sd                  = sd./sd(end);
            fInd                = find(sd > 0.9,1,'first');
            fInd                = 3;
            %u                   = u(:,1:fInd);
            
            % Classify
            clusterNum          = obj.ClusterNum;
            idx3                = kmeans(u(:,1:fInd),clusterNum,'MaxIter',500,'Replicates',3);
            obj.ImgCluster      = reshape(idx3,nR,nC);
            
            obj.ImgSvdArray     = obj.ImgTrialArray;
            for k = 1:nT
                imgTmp          = reshape(u(:,k),nR,nC);
                maxv            = max(imgTmp(:));
                minv            = min(imgTmp(:));
                obj.ImgSvdArray(:,:,zIndex,k) = (imgTmp - minv).* 255./(maxv - minv);
            end
            disp(diag(s));
            
            DTP_ManageText([], sprintf('AutoDetect: SVD processing is done.'),  'I' ,0);
            
            % show
            figNum      = sum(obj.TrialInd) + obj.ProcessType + 10*obj.ActiveZstackIndex;
            obj         = ShowSVD(obj,figNum);
            
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
            if isempty(obj.ImgCluster)
                DTP_ManageText([], sprintf('AutoDetect : Please load image data first and run detection.'), 'E' ,0);
                return;
            end
            % params
            clustNum         = max(obj.ImgCluster(:));
            if clustNum < 2,
                DTP_ManageText([], sprintf('AutoDetect : No clsuters detected. Could be problems in Clustering of the Data.'), 'E' ,0);
                return;
            end
            
            [nR,nC]                 = size(obj.ImgCluster);
            cellPerimeterLenMax     = (nR+nC)*0.1;
            cellPerimeterLenMin     = 5*4;
            cellInd                 = 0;
            cellColors              = jet(clustNum);
            for k = 1:clustNum
               
               % extract ROI data
               imgClust               = obj.ImgCluster == k;
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
                   roiLast          = SetName(roiLast,sprintf('AROI:Z%d:C%d:%04d',obj.ActiveZstackIndex,k,cellInd));
                   %roiLast.xyInd    = newXY(:,[2 1]);
                   roiLast          = InitView(roiLast,newXY(:,[2 1]));
                   roiLast.PixInd   = find(imgL == c);
                   roiLast.zInd     = obj.ActiveZstackIndex;  % z -stack
                   
                   strROI{cellInd,1}  = roiLast;
               end

            end
            
            % output
            obj.StrNewROI     = strROI;
            DTP_ManageText([], sprintf('AutoDetect : Extracted %d ROIs.',cellInd), 'I' ,0);
            
            if FigNum < 1, return; end
            [obj,imgCell]   = ConvertRoiToImage(obj,obj.StrNewROI, obj.ActiveZstackIndex);
            obj.ImgROI      = imgCell;
            % run show svd after that
            % show
            figNum      = sum(obj.TrialInd) + obj.ProcessType + 10*obj.ActiveZstackIndex;
            obj         = ShowSVD(obj,figNum);
            
            
        end
        
         % ==========================================
        function obj = SaveDataFromTrials(obj,Par)
            % SaveDataFromTrials - saves available info to one trial
            % Input:
            %     Par - header properties
            % Output:
            %     obj - updated structure
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Run over selected files/trials and load the raw data
            %%%%%%%%%%%%%%%%%%%%%%
            Par.DMT                 = Par.DMT.CheckData(false);    % important step to validate number of valid trials    
            validTrialNum           = Par.DMT.ValidTrialNum;
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('AutoDetect: Missing data in directory %s. Please check the folder or run Data Check',Par.DMT.RoiDir),  'E' ,0);
                return
            else
                DTP_ManageText([], sprintf('AutoDetect: Found %d files. Processing ...',validTrialNum),  'I' ,0);
            end
            
            %%%
            % Check if data is created
            %%%
            if length(obj.StrNewROI) < 1
                DTP_ManageText([], sprintf('AutoDetect: No ROI data is created. Please check the folder or run Data Check'),  'E' ,0);
                return
            end
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Select which trial to write
            %%%%%%%%%%%%%%%%%%%%%%
            trialInd    = 1;
            buttonName = questdlg('Would you like to add or overwrite new ROI data?', 'Warning','Add','Overwrite','Cancel','Cancel');
            if strcmp(buttonName,'Cancel'), return; end


            %%%%%%%%%%%%%%%%%%%%%%
            % Save back
            %%%%%%%%%%%%%%%%%%%%%%
            % start save
            [Par.DMT,isOK]                  = Par.DMT.SetTrial(trialInd);
            if ~isOK, DTP_ManageText([], sprintf('AutoDetect: Save problem. 911'),  'E' ,0); end
            
            if strcmp(buttonName,'Add')
            [Par.DMT, newROI]               = Par.DMT.LoadAnalysisData(trialInd,'strROI');
                newROI                      = cat(1,newROI(:),obj.StrNewROI(:));
            else
                newROI                      = obj.StrNewROI;
            end
            Par.DMT                         = Par.DMT.SaveAnalysisData(trialInd,'strROI',newROI);                
            
            DTP_ManageText([], sprintf('AutoDetect: ROIs saved in %d trial.',trialInd),  'I' ,0);
            
        end
      
    end
    
    
    % GUI based
    methods
        
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
        function obj = ShowArray(obj,FigNum)
            % ShowArray - show array selected
            % Inputs:
            %   obj         - control structure
            %
            % Outputs:
            %   obj         - control structure updated
            
            if nargin < 2, FigNum = 145; end
            if FigNum < 1, return; end
            if isempty(obj.ImgTrialArray), return; end;
            [nR,nC,nZ,nT] = size(obj.ImgTrialArray);
            if nZ > 1, nZ = nZ - 1; end % do not show the last plane
            
            % show filter
            %maxv    = max(obj.ImgTrialArray(:))*0.1; % 0.1 for high values
            for z = 1:nZ
            figure(FigNum + z), set(gcf,'Tag','AnalysisROI','Name',sprintf('%s Data : Z-Stack :%d',obj.PROCESS_TYPES{obj.ProcessType},z)),%clf; colordef(gcf,'none')
            imgData  = obj.ImgTrialArray(:,:,z,:);
            maxv     = prctile(imgData,99);
            imgData  = uint8(imgData .*(255/maxv));
            % add ROIs
            [obj,imgCell]   = ConvertRoiToImage(obj,obj.StrROI, z);
            roiNum          = length(obj.StrROI);
            if roiNum > 0
                imgData = cat(4,imgData,uint8(imgCell));
                % save
                obj.ImgROI = imgCell;
            end
            DFS_MontageProbe(imgData);
           end
        end

        % ==========================================
        function obj = ShowSVD(obj,FigNum)
            % ShowSVD - show svd decomposition selected
            % Inputs:
            %   obj         - control structure
            %
            % Outputs:
            %   obj         - control structure updated
            
            if nargin < 2, FigNum = 145; end
            if FigNum < 1, return; end
            if isempty(obj.ImgSvdArray), return; end;
            
            % show filter
            figure(FigNum), set(gcf,'Tag','AnalysisROI','Name',sprintf('%s Eigenvectors : Z-Stack :%d',obj.PROCESS_TYPES{obj.ProcessType},obj.ActiveZstackIndex)),%clf; colordef(gcf,'none')
            %maxv = max(obj.ImgTrialArray(:))*0.1; % 0.1 for high values
            DFS_MontageProbe(uint8(obj.ImgSvdArray(:,:,obj.ActiveZstackIndex,:)))
            
            figure(FigNum+1),set(gcf,'Tag','AnalysisROI','Name',sprintf('%s Data & Clsutering : Z-Stack :%d',obj.PROCESS_TYPES{obj.ProcessType},obj.ActiveZstackIndex))
%             imagesc(obj.ImgCluster)
%             title('Clustered networks')
            
            % make data more user friendly
            imgData     = obj.ImgTrialArray(:,:,obj.ActiveZstackIndex,:);
            maxv        = prctile(imgData(:),99);
            imgData     = uint8(imgData .*(255/maxv));
            imgData     = imgData(:,:,[1 1 1],:); % replicate
            %imgCluster  = obj.ImgCluster(:,:,[1 1 1])*(255./obj.ClusterNum); % replicate
            imgCluster  = label2rgb(obj.ImgCluster,'jet','k'); % replicate
            imgData     = cat(4,imgData,uint8(imgCluster));
            % add cells
            if ~isempty(obj.ImgROI)
                imgCluster  = label2rgb(obj.ImgROI,'jet','k');
                imgData     = cat(4,imgData,uint8(imgCluster));
            end
            DFS_MontageProbe(imgData);

            
        end
        
        % ==========================================
        function obj = ShowCluster(obj,FigNum)
            % ShowCluster - show kmeans decomposition selected
            % Inputs:
            %   obj         - control structure
            %
            % Outputs:
            %   obj         - control structure updated
            
            if nargin < 2, FigNum = 145; end
            if FigNum < 1, return; end
%            if isempty(obj.ImgSvdArray), return; end;
            
            figure(FigNum+1),set(gcf,'Tag','AnalysisROI','Name',sprintf('%s Data & Clsutering : Z-Stack :%d',obj.PROCESS_TYPES{obj.ProcessType},obj.ActiveZstackIndex))
%             imagesc(obj.ImgCluster)
%             title('Clustered networks')
            
            % make data more user friendly
            imgData     = obj.ImgTrialArray(:,:,obj.ActiveZstackIndex,:);
            maxv        = prctile(imgData(:),99);
            imgData     = uint8(imgData .*(255/maxv));
            imgData     = imgData(:,:,[1 1 1],:); % replicate
            %imgCluster  = obj.ImgCluster(:,:,[1 1 1])*(255./obj.ClusterNum); % replicate
            imgCluster  = label2rgb(obj.ImgCluster,'jet','k'); % replicate
            imgData     = cat(4,imgData,uint8(imgCluster));
            % add cells
            if ~isempty(obj.ImgROI)
                imgCluster  = label2rgb(obj.ImgROI,'jet','k');
                imgData     = cat(4,imgData,uint8(imgCluster));
            end
            DFS_MontageProbe(imgData);

            
        end
        
        
    end % GUI
    
    % Tests 
    methods
        
        % ==========================================
        function obj = TestLoadDataFromTrials(obj)
            % TestLoadDataFromTrials - test data load
            % Input:
            %     Par - header properties
            % Output:
            %     obj - updated structure
            
        
            % init all
            dirName             = 'C:\LabUsers\Uri\Data\Janelia\Imaging\D10\7_23_14_40-80';
            obj.SliceNum        = 3;

            Par                 = TPA_ParInit('');
            Par.DMT             = Par.DMT.SelectAllData(dirName);
            Par.DMT             = Par.DMT.CheckData();
            Par.DMT.SliceNum    = 3;

            %%%%%%%%%%%%%%%%%%%%%%
            % Run over selected files/trials and load the raw data
            %%%%%%%%%%%%%%%%%%%%%%
            obj                 = LoadDataFromTrials(obj,Par);            
        end

    end
    
end % class



