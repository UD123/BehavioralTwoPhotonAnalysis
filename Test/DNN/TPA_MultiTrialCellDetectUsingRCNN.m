classdef TPA_MultiTrialCellDetectUsingRCNN
    % TPA_MultiTrialCellDetectUsingRCNN - detects ROIs automatically using RCNN
    % 1. loads raw data from all trials.
    % 2. Applies registration shift and transformation to image data.
    % 3. Computes mean image 
    % 4. Creates training database using mean image and ROI boxes
    % 5. Computes RCNN classifier
    % 6. Shows the result
    % 
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 27.03 16.10.17 UD     Increasing ROI size.
    % 27.02 15.10.17 UD     From Technion Matlab 2017a.
    % 27.01 08.10.17 UD     Ceates from TPA_MultiTrialTwoPhotonManager.
    % 26.05 11.07.17 UD     Adding ROI extraction.
    % 25.13 23.05.17 UD     Created.
    %-----------------------------
    
    properties (Constant)
        %PROCESS_TYPES       = {'dFF','Mean','STD'};
    end
    
    properties
        
        % Control
        %ProcessType 
        SaveDir             % where the atabase will be created
        SaveFile            % name to save
        
        % Data
        %ImgTrialArray        % image trial data
        ActiveZstackIndex    % which z stack
        SliceNum             % how many z stacks
        %ClusterNum           % how many clusters to use
        %TrialInd            % which trial should be updated
        %StrROI              % strROI for show only
        %ImgROI              % image with marked ROI
        %ImgSvdArray         % svd decomposition
        %ImgCluster          % cell clustering
        %StrNewROI           % auto generated ROIS
        MaxShift            % max shift in registration - to prevent artifacts [X Y]
        
        DataSet             % cell array holds images names and ROIs

        
        % GUI
        hFig            % figure for query gen
        
        
    end % properties
    properties (SetAccess = private)
    end
    
    % DataSet create
    methods
        
        % ==========================================
        function obj = TPA_MultiTrialCellDetectUsingRCNN()
            % TPA_MultiTrialCellDetectUsingRCNN - constructor
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            %if nargin < 1, error('Requires Par structure'); end;
            tic;
            
            % init
            %obj.ProcessType         = 1;
            obj.SliceNum            = 1;
            obj.ActiveZstackIndex   = 1;
            %obj.ClusterNum          = 3;
            obj.DataSet             = cell(0,2);

            
            obj.SaveDir             = '..\DataForDnn2';
            obj.SaveFile            = 'CellDataRcnnFadi.mat';
            
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
                'Processing Type [1-dFF, 2-Mean, 3-STD] :',...
                'Z Stack [1-2-3]:',...
                'Cluster Number [3-4-5]:',...
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
            obj.ProcessType         = max(1,min(3,obj.ProcessType));
            obj.ActiveZstackIndex   = max(1,min(3,obj.ActiveZstackIndex));
            obj.ClusterNum          = max(3,min(5,obj.ClusterNum));
            
            
            isOK        = true;
            DTP_ManageText([], sprintf('AutoDetect: parameters are updated'),  'I' ,0);
            
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
            for z = 1:nZ
                  imgOut(:,:,z)   = squeeze(mean(imgArray(:,:,z,:),4));
            end
            
            % remove boundaties
            imgOut(1:obj.MaxShift(2),:,:,1)     = single(0);
            imgOut(nR-obj.MaxShift(2):nR,:,:,1) = single(0);
            imgOut(:,1:obj.MaxShift(1),:,1)     = single(0);
            imgOut(:,nC-obj.MaxShift(2):nC,:,1) = single(0);
            
            
            DTP_ManageText([], sprintf('AutoDetect: Trial processing is done.'),  'I' ,0);
            
            
            
        end
        
        % ==========================================
        function obj = AddToDataSetSingleBox(obj,imgMean,strROI,imgName)
            % AddToDataSet - adds another entry to the data set
            % Input:
            %     obj - current structure
            %     imgMean - mean image
            %     strROI  - cell array of ROIs 
            %     imgName - image name to save
            % Output:
            %     obj - updated structure
            if nargin < 4, error('Need imgMean,strROI,imgName'); end
            
            % init
            [nR,nC,nZ]           = size(imgMean);
            if nZ > 1, nZ = nZ - 1; end % do not process the last plane
            nROI                 = length(strROI);
            if nROI < 1, Print(obj,'No ROIs','W'); return; end
            if ~ischar(imgName), Print(obj,'Image name must be a char','W'); return; end
            if ~exist(obj.SaveDir,'dir'),mkdir(obj.SaveDir); end
            
            % check
            %mv                   = maxk(imgMean(:),10);
            %imgMean              = imgMean./mv(10)*255;
            mv                   = max(imgMean(:));
            imgMean              = imgMean./mv*255;
            imgMean              = uint8(imgMean);
            %imgMean              = uint16(imgMean);
            %lh                   = stretchlim(imgMean);

            % process
            for z = 1:nZ
                %ind             = [strROI(:).zInd] == z;
                frame           = imgMean(:,:,z);
%                 framePath       = fullfile(obj.SaveDir,sprintf('%s_%d.tif',imgName,z));
%                 imwrite(frame,framePath,'tif'); %,'BitDepth',16);
                framePath       = fullfile(obj.SaveDir,sprintf('%s_%d.jpg',imgName,z));
                imwrite(frame,framePath,'jpg'); %,'BitDepth',16);
                % extract boxes for all ROIs in this z stack
                %bboxes          = [];
                for m = 1:nROI
                    if strROI{m}.zInd ~= z, continue; end
                    xy          = strROI{m}.xyInd;
                    xy_min      = min(xy);
                    xy_max      = max(xy);
                    bbox        = [xy_min xy_max - xy_min];
                    %bboxes      = cat(1,bboxes,bbox);
                    % for each ROI create an entry
                    ind                   = size(obj.DataSet ,1)+1;
                    obj.DataSet{ind,1}    = framePath;
                    obj.DataSet{ind,2}    = {bbox};
                end
            end
            
            DTP_ManageText([], sprintf('AutoDetect: DataSet processing is done.'),  'I' ,0);
            
        end
        
        % ==========================================
        function obj = AddToDataSet(obj,imgMean,strROI,imgName)
            % AddToDataSet - adds another entry to the data set
            % Input:
            %     obj - current structure
            %     imgMean - mean image
            %     strROI  - cell array of ROIs 
            %     imgName - image name to save
            % Output:
            %     obj - updated structure
            if nargin < 4, error('Need imgMean,strROI,imgName'); end
            
            % init
            [nR,nC,nZ]           = size(imgMean);
            if nZ > 1, nZ = nZ - 1; end % do not process the last plane
            nROI                 = length(strROI);
            if nROI < 1, Print(obj,'No ROIs','W'); return; end
            if ~ischar(imgName), Print(obj,'Image name must be a char','W'); return; end
            if ~exist(obj.SaveDir,'dir'),mkdir(obj.SaveDir); end
            
            % check
            %mv                   = maxk(imgMean(:),10);
            %imgMean              = imgMean./mv(10)*255;
            mv                   = max(imgMean(:));
            imgMean              = imgMean./mv*255;
            imgMean              = uint8(imgMean);
            %imgMean              = uint16(imgMean);
            %lh                   = stretchlim(imgMean);

            % process
            for z = 1:nZ
                %ind             = [strROI(:).zInd] == z;
                frame           = imgMean(:,:,z);
%                 framePath       = fullfile(obj.SaveDir,sprintf('%s_%d.tif',imgName,z));
%                 imwrite(frame,framePath,'tif'); %,'BitDepth',16);
                framePath       = fullfile(obj.SaveDir,sprintf('%s_%d.jpg',imgName,z));
                imwrite(frame,framePath,'jpg'); %,'BitDepth',16);
                % extract boxes for all ROIs in this z stack
                bboxes          = [];
                for m = 1:nROI
                    if strROI{m}.zInd ~= z, continue; end
                    xy          = strROI{m}.xyInd;
                    xy_min      = min(xy);
                    xy_max      = max(xy);
                    bbox        = [xy_min-5 xy_max - xy_min + 10];
                    bbox(1)     = max(1,bbox(1));
                    bbox(2)     = max(1,bbox(2));
                    bbox(3)     = bbox(3) + min(0,nC - (bbox(1)+bbox(3)));
                    bbox(4)     = bbox(4) + min(0,nR - (bbox(2)+bbox(4)));
                    bboxes      = cat(1,bboxes,bbox);
                end
                % for each ROI create an entry
                ind                   = size(obj.DataSet ,1)+1;
                obj.DataSet{ind,1}    = framePath;
                obj.DataSet{ind,2}    = {bboxes};
            end
            
            DTP_ManageText([], sprintf('AutoDetect: DataSet processing is done.'),  'I' ,0);
            
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
            SData                   = TPA_DataManagerMemory();

            % Run over selected files/trials and load the raw data
            Par.DMT                 = Par.DMT.CheckData(false);    % important step to validate number of valid trials    
            validTrialNum           = Par.DMT.ValidTrialNum;
            if validTrialNum < 1,
                DTP_ManageText([], sprintf('AutoDetect: Missing data in directory %s. Please check the folder or run Data Check',Par.DMT.RoiDir),  'E' ,0);
                return
            else
                DTP_ManageText([], sprintf('AutoDetect: Found %d files. Processing ...',validTrialNum),  'I' ,0);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Select which trial to process
            %%%%%%%%%%%%%%%%%%%%%%
            if isa(Par.DMT,'TPA_DataManagerPrarie') || isa(Par.DMT,'TPA_DataManagerTwoChannel')
            trialFileNames        = Par.DMT.VideoDirNames(:);
            else
            trialFileNames        = Par.DMT.VideoFileNames;
            end

%             [s,ok] = listdlg('PromptString','Select Trials to Process :','ListString',trialFileNames,'SelectionMode','multiple', 'ListSize',[300 500]);
%             if ~ok, return; end
            s                   = 1:min(1000,length(trialFileNames));

            selectedInd         = s;
            selectedTrialNum    = length(s);     

            %obj.StrROI          = [];
            %obj.ImgROI          = [];
            obj.MaxShift        = [0 0];

            for m = 1:selectedTrialNum,

                    %%%%%%%%%%%%%%%%%%%%%%
                    % Load Trial
                    %%%%%%%%%%%%%%%%%%%%%%
                    trialInd                          = selectedInd(m);
                    [Par.DMT,isOK]                    = Par.DMT.SetTrial(trialInd);
                    [Par.DMT, SData.imTwoPhoton]      = Par.DMT.LoadTwoPhotonData(trialInd);
                    % apply shift
                    [Par.DMT, strShift]               = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strShift');
                    [Par.DMT, SData.imTwoPhoton]      = Par.DMT.ShiftTwoPhotonData(SData.imTwoPhoton,strShift);
%                     % remeber max shoft
                    if ~isempty(strShift)
                    obj.MaxShift                      = max(obj.MaxShift,max(max(abs(strShift),[],1),[],3));
                    end
                    
                    % load ROIs for show only
                    [Par.DMT, SData.strROI]           = Par.DMT.LoadAnalysisData(Par.DMT.Trial,'strROI');

                    %%%%%%%%%%%%%%%%%%%%%%
                    % Process dF/F for each trial
                    %%%%%%%%%%%%%%%%%%%%%%
                    [obj,imgMean]                      = ProcessTrialData(obj,SData.imTwoPhoton);

                    %%%%%%%%%%%%%%%%%%%%%%
                    % Save image back along with ROI
                    %%%%%%%%%%%%%%%%%%%%%%
                    % start save
                    [~,imgName,~]                       = fileparts(trialFileNames{trialInd});
                    obj                                 = AddToDataSet(obj,imgMean,SData.strROI,imgName) ;               

            end
            DTP_ManageText([], sprintf('AutoDetect: processed for %d trials.',selectedTrialNum),  'I' ,0);
%             % save the data set 
%             cellData      = cell2table(obj.DataSet,'VariableNames',{'imageFileName' 'Cells'});
%             save(fullfile(obj.SaveDir,'CellDataRcnn.mat'),'cellData');
            
%             % show
%             obj.TrialInd    = selectedInd;
%             figNum          = sum(selectedInd) + 1*obj.ActiveZstackIndex;
%             obj             = ShowArray(obj,figNum);            
            
        end

        % ==========================================
        % Load database for testing and training
        function obj = CreateDatabase(obj,dbStr)
            % CreateDatabase - save the data from several experiments
            % Input:
            %   dbStr    - contains path and parameters of the database
            % Output:
            %   saved cell array 
            if nargin < 2, dbStr = struct('Path','','SliceNum',1,'ExpType',1); end
            dbNum = length(dbStr);
            if dbNum < 1
                DTP_ManageText([], sprintf('AutoDetect : Please specify data base.'), 'E' ,0);
                return;
            end
            % create save dir
            %obj.SaveDir             = '..\DataForDnn';
            % clean results
            obj.DataSet             = cell(0,2);            
            % params
            for k = 1:dbNum
               
               % extract ROI data
                dirName             = dbStr(k).Path;
                sliceNum            = dbStr(k).SliceNum;
                expType             = dbStr(k).ExpType;

                % config
                Par                 = TPA_ParInit('');
                if expType == 2
                    Par.DMT         = TPA_DataManagerPrarie();
                end
                Par.DMT             = Par.DMT.SelectAllData(dirName);
                Par.DMT             = Par.DMT.CheckData();
                Par.DMT.SliceNum    = sliceNum;
                obj.SliceNum        = sliceNum;
                
                % Run over selected files/trials and load the raw data
                obj                 = LoadDataFromTrials(obj,Par);            
            end 
            % save the data set 
            cellData      = cell2table(obj.DataSet,'VariableNames',{'imageFileName' 'Cells'});
            save(fullfile(obj.SaveDir,obj.SaveFile),'cellData');
            
            
        end
        
        
        
        % ==========================================
        function obj = NA_SaveDataFromTrials(obj,Par)
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
    
    % DNN training and testing
    methods
        
        % ==========================================
        % increase ROI size
        function cellData = IncreaseRoiSize(obj, cellData, imgSize)
            % IncreaseRoiSize - rois boxes are get increased
            % Input:
            %   SaveDir   - where the data resides
            % Output:
            %   cellData     - table with image path and roi boxes
            if nargin < 3, imgSize = [512 512]; end
            nR      = imgSize(1);
            nC      = imgSize(2);
            
            % Display one training image and the ground truth bounding boxes before
            t = 23;
            I = imread(cellData.imageFileName{t});
            I = insertObjectAnnotation(I, 'Rectangle', cellData.Cells{t,:}, 'Cell', 'LineWidth', 1);
            
            % increase
            nRows = height(cellData);
            for t = 1:nRows
                bboxes   = cellData.Cells{t,:};
                nROI     = size(bboxes,1);
                for m = 1:nROI
                    bbox        = bboxes(m,:);
                    bbox(1)     = max(1,bbox(1)-5);
                    bbox(2)     = max(1,bbox(2)-5);
                    bbox(3)     = bbox(3) + min(10,nC - (bbox(1)+bbox(3)+10));
                    bbox(4)     = bbox(4) + min(10,nR - (bbox(2)+bbox(4)+10));
                    bboxes(m,:) = bbox;
                end
                cellData.Cells{t,:} = bboxes;
            end
            
            I = insertObjectAnnotation(I, 'Rectangle', cellData.Cells{t,:}, 'Cell Large', 'LineWidth', 1,'color','r');

            figure(91)
            imagesc(I)
            title(cellData.imageFileName{t},'interpreter','none');
            
            
        end
        
        % ==========================================
        % Load database for testing and training
        function cellData = LoadDatabase(obj, dbType)
            % LoadDatabase - load images and rois boxes
            % Input:
            %   SaveDir   - where the data resides
            % Output:
            %   cellData     - table with image path and roi boxes
            if nargin < 2, dbType = 1; end
            cellData = {};
            fName = fullfile(obj.SaveDir,obj.SaveFile);
            if ~exist(fName,'file'),Print(obj,sprintf('%s does not exists',fName),'E'); return; end
            load(fName,'cellData')  
            addpath(obj.SaveDir);
            
            % show an image
            % Display one training image and the ground truth bounding boxes
            t = 2;
            I = imread(cellData.imageFileName{t});
            I = insertObjectAnnotation(I, 'Rectangle', cellData.Cells{t,:}, '', 'LineWidth', 1);

            figure(91)
            imshow(I)
            title(cellData.imageFileName{t},'interpreter','none')
            
            
        end
        
        % ==========================================
        % Load pre trained networks
        function [Layers,Opts] = LoadNetwork(obj,netType)
            % LoadDatabase - load images and rois boxes
            % Input:
            %   netType   - what net to load
            % Output:
            %   Layers     - network layers
            %   Opts       - network trainig options
            if nargin < 2, netType = 1; end
            switch netType
                case 1
                % Finally, train the R-CNN object detector using |trainRCNNObjectDetector|.
                % The input to this function is the ground truth table which contains
                % labeled stop sign images, the pre-trained CIFAR-10 network, and the
                % training options. The training function automatically modifies the
                % original CIFAR-10 network, which classified images into 10 categories,
                % into a network that can classify images into 2 classes: stop signs and
                % a generic background class.
                    
                    load('rcnnStopSigns.mat','cifar10Net');
                    Layers     = cifar10Net.Layers;
                    
                    Layers(13) = fullyConnectedLayer(2,'Name','fc_out','WeightLearnRateFactor',20,'BiasLearnRateFactor',20);
                    Layers(14) = softmaxLayer;
                    Layers(15) = classificationLayer;
                    
                    % Set training options
                    Opts = trainingOptions('sgdm', ...
                        'MiniBatchSize', 128, ...
                        'InitialLearnRate', 1e-3, ...
                        'LearnRateSchedule', 'piecewise', ...
                        'LearnRateDropFactor', 0.1, ...
                        'LearnRateDropPeriod', 100, ...
                        'MaxEpochs', 30, ...
                        'Verbose', true);
                    
                case 2 % with augement
                    
                    imageAugmenter = imageDataAugmenter('RandRotation',[-20 20]);

                    imageSize = [28 28 1];
                    datasource = augmentedImageSource(imageSize,XTrain,YTrain,'DataAugmentation',imageAugmenter)

                    load('rcnnStopSigns.mat','cifar10Net');
                    Layers     = cifar10Net.Layers;
                    Layers(13) = fullyConnectedLayer(2,'Name','fc_out','WeightLearnRateFactor',20,'BiasLearnRateFactor',20);
                    Layers(14) = softmaxLayer;
                    Layers(15) = classificationLayer;
                    
                    % Set training options
                    Opts = trainingOptions('sgdm', ...
                        'MiniBatchSize', 128, ...
                        'Shuffle','every-epoch', ...
                        'InitialLearnRate', 1e-3, ...
                        'LearnRateSchedule', 'piecewise', ...
                        'LearnRateDropFactor', 0.1, ...
                        'LearnRateDropPeriod', 100, ...
                        'MaxEpochs', 30, ...
                        'Verbose', true);
                    

                    
                otherwise
                    error('bad netType')
            end
            
            %Layers
        end
        
        % ==========================================
        % Train the networks
        function rcnn = TrainNetwork(obj, cellData, layers, opts)
            % TrainNetwork - trains RCNN net
            % Input:
            %   cellData   - what net to load
            %   layers     - network layers
            %   opts       -  traing options
            % Output:
            %   rcnn        - trained network 
            if nargin < 3, error(' Need cellData, layers'); end
            

            % Train an R-CNN object detector. This will take several minutes.    
            rcnn = trainRCNNObjectDetector(cellData, layers, opts, ...
            'NegativeOverlapRange', [0 0.2], 'PositiveOverlapRange',[0.8 1]);

            save(fullfile(obj.SaveDir,obj.SaveFile),'cellData','rcnn');
            
            
        end

        % ==========================================
        % Train the networks
        function obj = TestNetwork(obj, cellData, rcnn, imgInd)
            % TestNetwork - test rcnn classifier
            % Input:
            %   cellData   - what net to load
            %   rcnn       - network trained
            %   imgInd     -  image for test
            % Output:
            %   figures        - from test image 
            if nargin < 3, cellData = [] ; rcnn = []; end
            if nargin < 4, imgInd = 50; end
            
            % check
            if isempty(cellData)
                load(fullfile(obj.SaveDir,obj.SaveFile),'cellData','rcnn');
            end
            
            %
            % Test the R-CNN detector on a test image.
            t                       = imgInd;
            testImage               = imread(cellData.imageFileName{t}); 
            [bbox, score, label]    = detect(rcnn, testImage, 'MiniBatchSize', 64, 'SelectStrongest', true);

            % Display strongest detection result.
            %[score, idx] = max(score);
            labelNum     = size(bbox,1);
            img          = imadjust(testImage);
            %clrs         = jet(labelNum)*250;
            for idx = 1:labelNum
                box         = bbox(idx, :);
                annotation  = sprintf('%s: (C=%4.3f)', label(idx), score(idx));
                img         = insertObjectAnnotation(img, 'rectangle', box, '','Color','y');
            end
            % Add true boxes
            tf              = contains(cellData.imageFileName(:),cellData.imageFileName{t});
            tfInd           = find(tf);
            for m = 1:numel(tfInd)
                box         = cellData.Cells{tfInd(m)};
                img         = insertObjectAnnotation(img, 'rectangle', box, '','Color','r');
            end
            %detectedImg = insertObjectAnnotation(detectedImg, 'rectangle', rcnnData.f(t,:), 'True');
            figure(95)
            imshow(img)
            title(t)
            
            % another test
            featureMap = activations(rcnn.Network, repmat(testImage,[1,1,3]), 'softmax', 'OutputAs', 'channels');
            cellMap = featureMap(:, :, 2);
            % Resize  for visualization
            [height, width, ~]  = size(testImage);
            cellMap             = imresize(cellMap, [height, width]);

            % Visualize the feature map superimposed on the test image.
            featureMapOnImage = imfuse(testImage, cellMap);

            figure(96)
            imshow(featureMapOnImage)
            title(t)
            
            
        end
        
        % ==========================================
        % Train & Test dnn classifier
        function obj = TrainAndTestNetwork(obj)
            
            % params
            dbType              = 1;
            netType             = 1;
            %obj.SaveDir         = '..\DataForDnn\';            
            
            % predefined
            cellData            = LoadDatabase(obj, dbType);            
            [layers,opts]       = LoadNetwork(obj, netType);
            
            % increase ROI size
            cellData            = IncreaseRoiSize(obj, cellData);
            
            % run
            rcnn                = TrainNetwork(obj, cellData, layers, opts);
            
            % test
            obj                 = TestNetwork(obj, cellData, rcnn);
            

        end
        
        % ==========================================
        % Train the ACF detector
        function obj = TestACF(obj, cellData, acfd, imgInd)
            % TestACF - test ACF classifier
            % Input:
            %   cellData   - what net to load
            %   acfd       - network trained
            %   imgInd     -  image for test
            % Output:
            %   figures        - from test image 
            if nargin < 3, cellData = [] ; acfd = []; end
            if nargin < 4, imgInd = 34; end
            
            % check
            if isempty(cellData)
                load(fullfile(obj.SaveDir,obj.SaveFile),'cellData','acfd');
            end
            
            %
            % Test the R-CNN detector on a test image.
            n                       = 80;
            t                       = imgInd;
            testImage               = imread(cellData.imageFileName{t}); 
            %[bbox, score, label]    = detect(acfd, testImage, 'MiniBatchSize', 64, 'SelectStrongest', true);
            [bbox, score]           = detect(acfd,testImage);
            [sv,si]                 = sort(score,'descend');
            score                   = score(si(1:n));
            bbox                    = bbox(si(1:n),:);
            
            % Display strongest detection result.
            boxNum                  = length(score);
            img                     = imadjust(testImage);
            %clrs         = jet(labelNum)*250;
            for idx = 1:boxNum
                box         = bbox(idx, :);
                %annotation  = sprintf('%s: (C=%4.3f)', score(idx));
                img         = insertObjectAnnotation(img, 'rectangle', box, '','Color','y');
            end
            % Add true boxes
            tf              = contains(cellData.imageFileName(:),cellData.imageFileName{t});
            tfInd           = find(tf);
            for m = 1:numel(tfInd)
                box         = cellData.Cells{tfInd(m)};
                img         = insertObjectAnnotation(img, 'rectangle', box, '','Color','r');
            end
            %detectedImg = insertObjectAnnotation(detectedImg, 'rectangle', rcnnData.f(t,:), 'True');
            figure(95)
            imshow(img)
            title(t)
            
%             % another test
%             featureMap = activations(acfd.Network, repmat(testImage,[1,1,3]), 'softmax', 'OutputAs', 'channels');
%             cellMap = featureMap(:, :, 2);
%             % Resize  for visualization
%             [height, width, ~]  = size(testImage);
%             cellMap             = imresize(cellMap, [height, width]);
% 
%             % Visualize the feature map superimposed on the test image.
%             featureMapOnImage = imfuse(testImage, cellMap);
% 
%             figure(96)
%             imshow(featureMapOnImage)
%             title(t)
            
            
        end
        
        
        % ==========================================
        % Train & Test ACF classifier
        function obj = TrainAndTestACF(obj)
            
            % params
            dbType              = 1;
            numStages           = 3;
            obj.SaveDir         = '..\DataForDnn2\'; 
            
            % predefined
            obj.SaveFile        = 'CellDataRcnnFadi.mat';
            cellData            = LoadDatabase(obj, dbType);            
            
            % increase ROI size
            cellData            = IncreaseRoiSize(obj, cellData);
            
            % run
            obj.SaveFile        = 'CellDataAcf.mat';
            acfd                = trainACFObjectDetector(cellData,'NumStages',numStages,'Verbose',true);
            save(fullfile(obj.SaveDir,obj.SaveFile),'cellData','acfd');

            
            % test
            obj                 = TestACF(obj, cellData, acfd);
            

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
        % Print info and time
        function Print(obj,  txt, severity)
            % This manages info display and error
            if nargin < 2, txt = 'init';                 end;
            if nargin < 3, severity = 'I';               end;
            
            matchStr    = 'IWE'; cols = 'kbr';
            k = strfind(matchStr,severity);
            assert(k > 0,'severity must be IWE')
            %if k < obj.ReportLevel, return; end;
            
            % always print
            fprintf('%s : %5.3f : DNN : %s\n',severity,toc,txt);
            tic;
            
            if ~isprop(obj,'hText'), return; end;
            if ~ishandle(obj.hText), return; end;
            set(obj.hText,'string',txt,'ForegroundColor',cols(k));
            
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
            dirName             = 'D:\Uri\Data\Technion\Imaging\m8\02_10_14';
            sliceNum            = 1;
            saveDir             = [dirName,'_dnn'];

            % config
            Par                 = TPA_ParInit('');
            Par.DMT             = Par.DMT.SelectAllData(dirName);
            Par.DMT             = Par.DMT.CheckData();
            Par.DMT.SliceNum    = sliceNum;
            obj.SliceNum        = sliceNum;
            obj.SaveDir         = saveDir;

            % Run over selected files/trials and load the raw data
            obj                 = LoadDataFromTrials(obj,Par);            
        end
        
        % ==========================================
        % Test database for testing and training
        function obj = TestCreateDatabase(obj)
            
            k = 1;
            dbStr(k).Path        = 'D:\Uri\Data\Technion\Imaging\m8\02_10_14';
            dbStr(k).SliceNum    = 1;
            k = 2;
            dbStr(k).Path        = 'D:\Uri\Data\Technion\Imaging\m2\2_20_14';
            dbStr(k).SliceNum    = 1;
            
            % run
            obj                 = CreateDatabase(obj,dbStr);          

        end

        % ==========================================
        % Test database for testing and training
        function obj = TestCreateDatabaseTechnionSimple(obj)
            
            k = 1;
            dbStr(k).Path        = 'C:\LabUsers\Uri\Data\Janelia\Imaging\m8\02_10_14';
            dbStr(k).SliceNum    = 3;
            k = 2;
            dbStr(k).Path        = 'C:\LabUsers\Uri\Data\Janelia\Imaging\m2\2_20_14';
            dbStr(k).SliceNum    = 1;
            
            % run
            obj                 = CreateDatabase(obj,dbStr);          

        end
  
        % ==========================================
        % Test database for testing and training
        function obj = TestCreateDatabaseJackieBackup(obj)
            
            k = 1;
            dbStr(k).Path        = '\\Jackie-backup\E\Projects\PT_IT\Analysis\D8\6_28_14-1_16';
            dbStr(k).SliceNum    = 3;
            k = 2;
            dbStr(k).Path        = '\\Jackie-backup\E\Projects\PT_IT\Analysis\D8\7_16_14-1_16';
            dbStr(k).SliceNum    = 3;
            k = 3;
            dbStr(k).Path        = '\\Jackie-backup\E\Projects\PT_IT\Analysis\D8\8_7_14_1-20';
            dbStr(k).SliceNum    = 3;
            
            % name
           obj.SaveFile          = 'CellDataRcnnJB.mat';

            
            % run
            obj                 = CreateDatabase(obj,dbStr);          

        end
        
        % ==========================================
        % Test database for testing and training
        function obj = TestCreateDatabaseFadi(obj)
            
            k = 1;
            dbStr(k).Path        = 'C:\LabUsers\Uri\Data\Prarie\Analysis\Pyramidal5\10_11_17';
            dbStr(k).SliceNum    = 1;
            dbStr(k).ExpType     = 2; % 1-janelia, 2-Prarie
            k = 2;
            dbStr(k).Path        = 'C:\LabUsers\Uri\Data\Prarie\Analysis\SlcL23\10_04_17';
            dbStr(k).SliceNum    = 1;
            dbStr(k).ExpType     = 2; % 1-janelia, 2-Prarie

%             k = 1;
%             dbStr(k).Path        = '\\Jackie-lab20\E\FadiAeed\Epilepsy\Data\Analysis\Pyramidal5\10_11_17';
%             dbStr(k).SliceNum    = 1;
%             dbStr(k).ExpType     = 2; % 1-janelia, 2-Prarie
%             k = 2;
%             dbStr(k).Path        = '\\Jackie-lab20\F\FadiAeed\ParkinsonL23\Analysis\SlcL23\SL3\10_04_17';
%             dbStr(k).SliceNum    = 1;
%             dbStr(k).ExpType     = 2; % 1-janelia, 2-Prarie
            
            % name
            obj.SaveDir          = '..\DataForDnn2\';
            obj.SaveFile          = 'CellDataRcnnFadi.mat';

            
            % run
            obj                 = CreateDatabase(obj,dbStr);          

        end
        
        
    end
    
end % class



