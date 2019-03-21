classdef VideoClassifier
    % VideoClassifier - detects ROIs automatically using CDNN
    % 1. Loads data from experiments
    % 2. Computes number of classes.
    % 3. Increase dataset size by jittering
    % 4. Trains CNN network
    % 4. Test CNN network
    % 6. Shows the result
    % 
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 0805  10.10.18 UD     Adding numbers
    % 0804  04.07.18 UD     Adding heavier 3D net
    % 0803  21.06.18 UD     Valid net type
    % 0802  18.04.18 UD     Bug fixes
    % 0801  19.03.18 UD     code for Arugga
    % 0705  08.03.18 UD     using labeling data
    % 0704  07.03.18 UD     improving performance
    % 0703  27.02.18 UD     Integrating into the GUI
    % 0702  25.02.18 UD     Reading session file
    % 0701  09.02.18 UD     merging AUDIO_DatabaseClassifier & TPA_MultiTrialCellDetectUsingRCNN & TPA_ManageEventAutodetect
    % 0607  17.11.17 UD     multiple networks for speed and parameter for jitter
    % 0606  13.11.17 UD     adding training support
    % 0604  12.11.17 UD     GUI integration. Adding some dataset and jitter
    % 0603  11.11.17 UD     Adopted from TPA...RCNNN
    %-----------------------------
    
    properties (Constant)
        Version             = '0804';   % SW version
    end
    
    properties
        
        % Control
        SaveDir             % where the database will be created
        SaveFile            % name to save
        
        % Data
        DataType                = 0; % control of database
        DataTrain               = []; % input data
        LabelTrain              = []; % labels
        DataValid               = []; % input data
        LabelValid              = []; % labels
        DataTest                = []; % input data
        LabelTest               = []; % labels
        DataPerFileNum          = 100; % expansion of the data - jitter factor
        %DataTable               = {};  % cell array
        
        % Network
        NetType                 = 0; % control of network
        Net                     = []; % trained network
        NetLayers               = []; % Layers 
        NetOptions              = []; % options
        NetDatasrc              = []; % data source for augementer

        
        % GUI
        hFig                    % figure for query gen
        
        
    end % properties
    properties (SetAccess = private)
    end
    
    % Main
    methods
        
        % ==========================================
        % Constructor
        function obj = VideoClassifier()
            % VideoClassifier - constructor
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            %if nargin < 1, error('Requires Par structure'); end;
            tic;
            
            % init
            obj.SaveDir             = '..\Data';
            obj.SaveFile            = 'DataCDNN.mat';
            
        end
        
        
        % ==========================================
        % Define params
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
                'Jitter Factor per File [100-Small : 2000-Huge] :',...
                'Name of the file to save:',...
                'Network Type [11-Fast : 15-Accurate and slow]:',...
                };
            defaultanswer   =  {...
                num2str(obj.DataPerFileNum),...
                obj.SaveFile,...
                num2str(obj.NetType),...
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
            obj.DataPerFileNum      = str2num(answer{1});
            obj.SaveFile            = answer{2};
            obj.NetType             = str2num(answer{3});
            
            % validate
            obj.ProcessType         = max(100,min(2000,obj.DataPerFileNum));
            %obj.ActiveZstackIndex   = max(1,min(3,obj.SaveFile));
            obj.NetType             = max(11,min(15,obj.NetType));
            
            
            isOK        = true;
            Print(obj, sprintf('Parameters are updated'),  'I');
            
        end
        
        % ==========================================
        % get valid network type
        function netType = GetValidNetType(obj)
            % GetValidNetType - set obj params 
            % Inputs:
            %   obj         - control structure
            %
            % Outputs:
            %   obj         - control structure updated
            
            netType         = 22;
            
            netOptionts     = {'Default - 22',22;'Simple - 21',21;'Big - 23',23;'Flower - 24',24;'Heavy 1D - 25',25;'Transfer Vehicle - 26',26};
                        
            [s,ok] = listdlg('PromptString','Select Network type to train :','ListString',netOptionts(:,1),'SelectionMode','single');
            if ~ok, return; end
            netType         = netOptionts{s,2};
            obj.NetType             = netType;
            Print(obj, sprintf('Network %d is selected',netType),  'I');
            
        end
        
 
        % ==========================================
        % Clean all the data
        function obj = Init(obj)
            % DeleteData - will remove stored video data
            % Input:
            %   internal -
            % Output:
            %   default
            
            % clean it up
            Print(obj, sprintf('Clearing intermediate results.'), 'W');
            
        end
        
        % ==========================================
        % Prepare data for the experiment
        function [dbTrain,dbTest] = PrepareLabelerData(obj, dataType)
            % PrepareLabelerData - test data load from session file and prepare small dataset
            % Input:
            %     session file
            % Output:
            %     obj - updated structure
            if nargin < 2, dataType = 1; end
            dbTrain = []; dbTest = [];
            % init all
            switch dataType
                case 1 % home
                    k = 1;
                    dbStr(k).Path        = 'D:\Uri\Data\Videos\Flowers\SessionFlowers_LabelData.mat';
            
                    
                case 101
                    [sessionFileName,sessionFilePath,~] = uigetfile('.mat','LabelerData',obj.SaveDir);
                    if sessionFileName==0, return; end
                    fName = fullfile(sessionFilePath,sessionFileName);
                    dbStr(1).Path = fName; 
                otherwise
                    error('Bad dataType')
            end
            
            % assign
            dbTrain               = dbStr;
            dbTest                = dbStr;
                    
            Print(obj, sprintf('Data type selected %d.',dataType), 'I');
            
            
        end
        
        
      
    end
    
    % DB
    methods
        
        % ==========================================
        % Convert to 3D the video data
        function obj = xSetImageData(obj,imgData)
            % SetImageData - check the data before convert it to 3D
            % Input:
            %   imgData - 3D-4D data stored after Image Load
            % Output:
            %   obj.ImgData - (nRxnCxnT)  3D array
            
            if nargin < 2, error('Reuires image data as input'); end;
            % remove dim
            [nR,nC,nZ,nT] = size(imgData);
            Print(obj, sprintf('AutoDetect : Inout image dimensions R-%d,C-%d,Z-%d,T-%d.',nR,nC,nZ,nT), 'I' ,0)   ;
            
            % data is 4D :  make it 3D by stacking each channel
            if nT > 1 && nZ > 1
                Print(obj, sprintf('AutoDetect : Multiple Z stacks are detected. Creating single image from multiple channels.'), 'W' ,0);
                imgData         = squeeze(imgData(:,:,1,:));
                obj.ImgDataIs4D = true;
            elseif nT == 1 % 3D - do nothing
            end
            % make it 3D
           
            % check decimation
            if nR > 400 && nC > 600, %any(obj.DecimationFactor > 1),
                Print(obj, sprintf('AutoDetect : Image data is decimated. Check decimation factors '), 'W' ,0)   ;
                % indexing
                sz              = size(imgData);
                imgData         = imgData(1:obj.DecimationFactor(2):sz(1),1:obj.DecimationFactor(1):sz(2),1:obj.DecimationFactor(3):sz(3));
            end
            imgSize             = size(imgData);
            
            
            % output
            obj.ImgData     = single(imgData);
            obj.ImgClass    = class(obj.ImgData);
            obj.ImgSize     = imgSize;
            
            Print(obj, sprintf('AutoDetect : %d images are in use.',imgSize(3)), 'I' )   ;
            
        end
        
        % ==========================================
        % Load vidoe data
        function [obj, imgData] = xLoadImageData(obj,fileDirName)
            % LoadImageData - loads image for fileName into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     imgData   - 3D array image data
            
            if nargin < 2, fileDirName = 'C:\Uri\DataJ\Janelia\Videos\M2\2_20_14\Basler_side_20_02_2014_m2_6.avi'; end;
            imgData             = [];
            
            % check
            if ~exist(fileDirName,'file')
                showTxt     = sprintf('No data file found. Aborting');
                Print(obj, showTxt, 'E' ,0) ;
                return;
            end
            
            if verLessThan('matlab', '8.1.0')
                readObj             = mmreader(fileDirName);
            else
                readObj             = VideoReader(fileDirName);
            end
            imgData             = read(readObj);
            imgSize             = size(imgData);
            
            % save
            obj.ImgSize         = imgSize;
            Print(obj, sprintf('AutoDetect : %d images (Z=1) are loaded from file %s successfully',imgSize(3),fileDirName), 'I' ,0)   ;
            
            % set data to internal structure and convert to single
            obj                 = SetImageData(obj,imgData);
        end
        
        % ==========================================
        % JitterTransform - Implements a random tranform on a signal
        function dataOut    = xJitterTransform(obj,sigLoad,maxLen,sigLabel,repeatNum)
            % Input:
            %     sigLoad - signal for expansion and jittering
            %     maxLen  - signal length required at the end
            %     sigLabel  - N.A. transform according to the label
            %     repeatNum  - how many times to do this
            % Output:
            %     dataOut - final pattern
                        
            dataOut         = repmat(single(0),[1,maxLen,1,repeatNum]);
            supportLen      = length(sigLoad);
            jitterLen       = supportLen/5;
            sigLoad         = single(sigLoad);
            
            for m = 1:repeatNum
                
                % x - the pattern to be creates
                xdata               = zeros(1,maxLen,'single');
                
                % new support length
                supportLenJittered  = ceil(supportLen + (rand(1)-0.5)*jitterLen);
                supportLenInterp    = min(maxLen-1,supportLenJittered);

                
                % Interpolate
                xdata_ind           = 1:supportLen;
                xdata_interp_ind    = linspace(1,supportLen,supportLenJittered);
                ydata_interp        = interp1(xdata_ind,sigLoad,xdata_interp_ind,'pchip');
                sig_interp          = ydata_interp(1:supportLenInterp);
  
                % offset + amp
                offs                = randi(maxLen-supportLenInterp,1);
                amp                 = sign(randn(1))*(rand(1)*0.5+0.5);
                xdata(offs:offs+supportLenInterp-1)   = sig_interp.*hamming(supportLenInterp)'*amp;
                
                % save
                dataOut(1,:,1,m)   = xdata;
                
            end
        end
        
        % ==========================================
        % LoadSimlpeDataset - creates/loads standard datasets for testing
        function obj = LoadSimlpeDataset(obj,dataType)
            % Input:
            %     dataType - test type to load
            % Output:
            %     obj - updated structure
            
            % check the data is already loaded
            if obj.DataType == dataType && ~isempty(obj.DataTrain)
                Print(obj, sprintf('Dataset %d is already in the memory.',dataType), 'I');
                return
            end
            
            dataName = 'None';
            switch dataType
                
                case 1 % digit dataset for train, validation and test
                    dataName                  = 'Digit 28x28 trains and test from example';
                    
                    % select small training set and large test set
                    [xTrain,yTrain]          = digitTrain4DArrayData;
                    
                    idx                 = randperm(size(xTrain,4),1000);
                    xValid              = xTrain(:,:,:,idx);
                    xTrain(:,:,:,idx)  = [];
                    yValid              = yTrain(idx);
                    yTrain(idx)         = [];
                    % check
                    figure,montage(xTrain(:,:,:,randi(numel(yTrain),[1 16])))
                    
                    
                    [xTest,yTest]       = digitTest4DArrayData;
                    
                case 2 % digit dataset for train, validation and test
                    dataName        = 'Digit 28x28 trains and test with augimination';
                    
                    [XTrain,yTrain] = digitTrain4DArrayData;
                    % select small training set and large test set
                    [uv,ia,ic]      = unique(yTrain);
                    sampNum         = 4;
                    repNum          = 16;
                    batchNum        = sampNum * repNum;
                    b               = false(size(ic));
                    for k = 1:length(uv)
                        b(find(yTrain == uv(k),sampNum,'first')) = true;
                    end
                    xValid          = XTrain(:,:,:,~b);
                    yValid          = yTrain(~b);
                    xTrain         = XTrain(:,:,:,b);
                    yTtrain         = yTrain(b);
                    xTrain         = repmat(xTrain,[1,1,1,repNum]);
                    yTtrain         = repmat(yTtrain,[repNum,1]);
                    % check
                    figure,montage(xTrain(:,:,:,randi(numel(yTtrain),[1 16])))
                    
                    
                    [xTest,yTest]   = digitTest4DArrayData;
                    
                case 11 % 1D signal dataset for test
                    dataName            = '1D signal dataset for test';
                    
                    % create
                    sigdb               = CreateSyntheticSigDb(obj);
                    
                    % labels must be categorical
                    sigdb.label         = categorical(sigdb.label);
                    
                    % split
                    ii                  = sigdb.set==1; % train
                    [xTrain,yTrain]     = deal(sigdb.data(:,:,:,ii),sigdb.label(ii));
                    ii                  = sigdb.set==2; % valid
                    [xValid,yValid]     = deal(sigdb.data(:,:,:,ii),sigdb.label(ii));
                    ii                  = sigdb.set==3; % valid
                    [xTest,yTest]       = deal(sigdb.data(:,:,:,ii),sigdb.label(ii));
                    
                    % Visualize some of the data
                    M   = 8;
                    N   = size(sigdb.data,4);
                    ri  = randi(N/2,1,M);
                    figure(11),set(gcf,'Tag','AUDIO');
                    for i = 1:M
                      subplot(M,2,2*i-1); plot(squeeze(sigdb.data(:,:,:,2*ri(i)-1))) ; axis tight;
                      subplot(M,2,2*i) ;  plot(squeeze(sigdb.data(:,:,:,2*ri(i)))) ;    axis tight;
                    end
                    subplot(M,2,1), title(char(sigdb.label(2*ri(1)-1)))
                    subplot(M,2,2), title(char(sigdb.label(2*ri(1))))                    
                    
                otherwise error('Unsupported dataType')
            end
            
            obj.DataType                = dataType;
            obj.DataTrain               = xTrain; % input data
            obj.LabelTrain              = yTrain; % labels
            obj.DataValid               = xValid; % input data
            obj.LabelValid              = yValid; % labels
            obj.DataTest                = xTest; % input data
            obj.LabelTest               = yTest; % labels
            
            Print(obj, sprintf('Dataset %s is loaded.',dataName), 'I');
            
        end
        
        % ==========================================
        % LoadDataFromLabeler - loads available info from labeler export database file
        function obj = LoadDataFromLabeler(obj,dbStr,isTrain)
            % Input:
            %     dbStr             - path to the export file
            %    isTrain            - is train or test
            % Output:
            %     obj - updated structure
            if nargin < 2, dbStr = []; end
            if nargin < 3, isTrain = true; end
            
            fileNum                     = length(dbStr);
            if fileNum < 1
                Print(obj, sprintf('Found no records in the dataset.'), 'W');
                return
            end
            Print(obj, sprintf('Found %d records in the dataset.',fileNum), 'I');
            
            % append several
            dataSet             = {};
            for k = 1:fileNum
                
                s               = load(dbStr(k).Path,'labelData');
                dataSet         = cat(1,dataSet,s.labelData);
                
            end
            
            % disp patch
            %disp('PATCH removing g column - contains empty')
            %dataSet(:,3) = [];
            %obj.DataType                = 1;
            if isTrain
            obj.DataTrain               = dataSet; % input data
            else
            obj.DataTest                = dataSet; % input data
            end
            
            Print(obj, sprintf('LoadDataFromLabeler done.'), 'I');
            
            % debug show data
            ShowDataSet(obj);

            
        end
    
        % ==========================================
        % Load database for testing and training
        function cellData = xLoadDatabase(obj, dbType)
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
        % Create ground truth object
        function [obj,cData] = CreateGroundTruth(obj, mediaInfo, uniqueLabels, sessionPath)
            % CreateGroundTruth - lground truth object for matlab
            % Input:
            %   mediaInfo   - structure with relevant data
            %  uniqueLabels - which labels to use
            % Output:
            %   cData     - table with image path and roi boxes
            
            validateattributes(uniqueLabels, {'cell'}, {'nonempty'});
            validateattributes(sessionPath, {'char'}, {'nonempty'});

            cData = {};
            % check
            if ~exist(mediaInfo.FileName,'file')
                Print(obj,sprintf('%s is not found.',mediaInfo.FileName),'E'); 
                return
            end
            nFrames         = length(mediaInfo.FrameInfo);
            if nFrames < 10
                Print(obj,sprintf('%s does not contain label data.',mediaInfo.FileName),'E'); 
                return
            end
            labelNum = length(uniqueLabels);
            if labelNum < 1
                Print(obj,sprintf('Label data is not cpecified.'),'E'); 
                return
            end
            [savePath,saveFile,~] = fileparts(sessionPath);
            
            % extract all valid frames
%             labelFrameNum   = zeros(nFrames,1);
%             for fi = 1:nFrames
%                 labelFrameNum(fi) = length(mediaInfo.FrameInfo(fi).labels);
%                 if labelFrameNum(fi)<1, continue; end
%             end
            % extract frames with labels
            labelFrameNum = arrayfun(@(x)(length(x.labels)),mediaInfo.FrameInfo,'UniformOutput', true);
%             names       = uniqueLabels(:);
%             types       = repmat(labelType('Rectangle'),labelNum,1);
%             labelDefs   = table(names,types,'VariableNames',{'Name','Type'});
% 
%             % define datasource
%             dataSource                  = groundTruthDataSource(mediaInfo.FileName);
%             numRows                     = numel(dataSource.TimeStamps);
%             carsTruth = cell(numRows,1);
%             laneMarkerTruth = cell(numRows,1);            
%             
%             labelData = table(carsTruth,laneMarkerTruth,'VariableNames',names);
%            [filePath,fileName,fileExt] = fileparts(mediaInfo.FileName);

            % prepare session file
            [p,fname,ext] = fileparts(mediaInfo.FileName);
            if strcmp(fname,'movie_comb'),[p,fname,ext] = fileparts(p); end
            [~,sname,ext] = fileparts(saveFile);
            dirPathLabel  = fullfile(savePath,sname,fname);
            updateDir = true;
            if exist(dirPathLabel,'dir')
                button = questdlg(sprintf('Image directory %s already exists. Overwrite?',fname));
                if strcmp('Cancel',button)
                    return
                elseif strcmp('No',button)
                    % contiune
                    updateDir = false;
                else % Yes
                    rmdir(dirPathLabel);
                    mkdir(dirPathLabel);
                end
            else
                mkdir(dirPathLabel)
            end
            
            
            % export data
            %[~,fname,ext] = fileparts(mediaInfo.FileName);
            localFR     = VideoReader(mediaInfo.FileName);
            cData       = cell(1,labelNum+1); m = 0;
            %cData       = cell2table(cData,'VariableNames',{'imageFileName',uniqueLabels});
            %fi = 0;
            for fi      = 1:nFrames
                if labelFrameNum(fi)<1,continue; end
                m                       = m + 1;
                framePath               = fullfile(dirPathLabel,sprintf('frame_%04d.jpg',fi));
                cData{m,1}              = framePath;
                for k = 1:labelNum
                    lbl                 = uniqueLabels{k};
                    ind                 = find(strcmp(mediaInfo.FrameInfo(fi).labels,lbl));
                    if isempty(ind),continue; end
                    cData{m,k+1}        = {mediaInfo.FrameInfo(fi).bboxes{ind}};
                end
                if ~updateDir, continue; end
                localFR.CurrentTime     = fi/localFR.FrameRate;
                frameW                  = readFrame(localFR);                
                imwrite(frameW,framePath,'jpg');
            end

        end
        
        % ==========================================
        % Load database for testing and training from a session
        function obj = LoadDataFromSession(obj,dbStr,isTrain)
            % LoadDataFromSession - load images and rois boxes
            % Input:
            %   SaveDir   - where the data resides
            % Output:
            %   DataTable     - table with image path and roi boxes
            if nargin < 2, dbStr = []; end
            if nargin < 3, isTrain = true; end
            fileNum                     = length(dbStr);
            if fileNum < 1
                Print(obj, sprintf('Found no records in the dataset.'), 'W');
                return
            end
            fName           = dbStr(1).Path;
            if ~exist(fName,'file')
                Print(obj,sprintf('%s does not exists. Trying to load manually',fName),'W'); 
                [sessionFileName,sessionFilePath,~] = uigetfile('.mat','Session',obj.SaveDir);
                if sessionFileName==0, return; end
                fName = fullfile(sessionFilePath,sessionFileName);
            end
            
            
            % If session was selected
            GroundTruthSession = load(fName);
            % Check if selected .MAT file session is valid
            if ~isfield(GroundTruthSession,'GTS')
                Print(obj,sprintf('%s is not a session file.',fName),'E'); 
                return
            end
            GTS = GroundTruthSession.GTS;
            % check
            mediaNum        = length(GTS.MediaInfo);
            if mediaNum < 1, Print(obj,sprintf('%s no media data.',fName),'E'); return; end
            
            % prepare labels
            uniqueLabels    = {}; mediaWithLabels = false(mediaNum,1);
            for mediaIndex = 1:mediaNum
                %nFrames = length(GTS.MediaInfo(mediaIndex).FrameInfo);
                % find non empty labels
                w       = arrayfun(@(x)(~isempty(x.labels)),GTS.MediaInfo(mediaIndex).FrameInfo,'UniformOutput', true);
                wInd    = find(w);
                mediaWithLabels(mediaIndex) = ~isempty(wInd);
                for k = 1:numel(wInd)
                    fi = wInd(k);
                    uniqueLabels  = union(uniqueLabels,GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels);
                end
            end
            labelNum        = length(uniqueLabels);
            if labelNum < 1, Print(obj,sprintf('%s : no label data.',fName),'E'); return; end
            
            % run over all medias and prepare directories
            gtData           = cell(0,labelNum+1);
            for mediaIndex = 1:mediaNum
                % skip not used labels
                if ~mediaWithLabels(mediaIndex), continue; end
                % prepare location
                [obj,cData]     = CreateGroundTruth(obj, GTS.MediaInfo(mediaIndex),uniqueLabels,fName);
                gtData          = cat(1,gtData,cData);        
            end
            % check if there are empty
            anEmptyCell         = cellfun(@(x)(isempty(x)),gtData,'UniformOutput', true);
            [ii,jj]             = find(anEmptyCell);
            gtData(ii,:)        = [];
            
            % save
            tData           = cell2table(gtData,'VariableNames',cat(1,{'imageFileName'}, uniqueLabels(:)));
            %obj.DataTable   = tData;
            
            if isTrain
            obj.DataTrain               = tData; % input data
            else
            obj.DataTest                = tData; % input data
            end
            
            Print(obj, sprintf('LoadDataFromSession done.'), 'I');

            
        end
        

        
    end
    
    % DNN training and testing
    methods
        
        % ==========================================
        % Load pre trained networks
        function obj = LoadNetwork(obj,netType)
            % LoadNetwork - defines netowrk with options
            % Input:
            %   netType   - what net to load
            % Output:
            %   Layers     - network layers
            %   Opts       - network trainig options
            if nargin < 2, netType = 1; end
            
            % check if you want to retrain
            if ~isempty(obj.NetLayers)
                buttonChosen = questdlg('Would you like to continue to train the current network. Press No to init network again?','Unsaved Changes','Yes','No','No');
                if strcmp(buttonChosen,'Yes'), return; end
            end
            if isempty(obj.DataTrain), obj.Print('Load data first','W'); return; end
            
            
            dataSource = {};
            netName = 'None';
            switch netType
                
                case 1 % From matlab Digit example
                    netName         = 'From matlab Digit example';
                    
                    % check the data exists
                    if isempty(obj.DataTrain)
                        Print(obj, sprintf('Load training dataset first.'), 'W');  return
                    end
                    if isempty(obj.DataValid)
                        Print(obj, sprintf('This network requires validation dataset.'), 'W');  return
                    end
                    
                    % define net
                    layers = [
                        imageInputLayer([28 28 1])
                        
                        convolution2dLayer(3,16,'Padding',1)
                        batchNormalizationLayer
                        reluLayer
                        
                        maxPooling2dLayer(2,'Stride',2)
                        
                        convolution2dLayer(3,32,'Padding',1)
                        batchNormalizationLayer
                        reluLayer
                        
                        maxPooling2dLayer(2,'Stride',2)
                        
                        convolution2dLayer(3,64,'Padding',1)
                        batchNormalizationLayer
                        reluLayer
                        
                        fullyConnectedLayer(10)
                        softmaxLayer
                        classificationLayer];
                    
                    % train
                    opts = trainingOptions('sgdm',...
                        'MaxEpochs',6, ...
                        'ValidationData',{obj.DataValid,obj.LabelValid},...
                        'ValidationFrequency',30,...
                        'Verbose',false,...
                        'Plots','training-progress');
                    
                    dataSource = {};
                    
                case 2 % From matlab Digit example with augement
                    netName         = 'From matlab Digit example with augement';
                    
                    % check the data exists
                    if isempty(obj.DataTrain)
                        Print(obj, sprintf('Load training dataset first.'), 'W');  return
                    end
                    if isempty(obj.DataValid)
                        Print(obj, sprintf('This network requires validation dataset.'), 'W');  return
                    end
                    
                    % define aug
                    %imageAugmenter = imageDataAugmenter('RandRotation',[-20 20]); % Working
                    imageAugmenter = imageDataAugmenter('RandXScale',[0.7 1.2],'RandYScale',[0.7 1.2],'RandRotation',[-20 20]);
                    %imageAugmenter = imageDataAugmenter('RandXScale',[1 1],'RandYScale',[1 1]);
                    
                    batchNum        = 64;
                    imageSize       = [28 28 1];
                    dataSource      = augmentedImageSource(imageSize,obj.DataTrain,obj.LabelTrain,'DataAugmentation',imageAugmenter);
                    
                    % build net
                    layers = [
                        imageInputLayer([28 28 1])
                        
                        convolution2dLayer(3,16,'Padding',1)
                        batchNormalizationLayer
                        reluLayer
                        
                        maxPooling2dLayer(2,'Stride',2)
                        
                        convolution2dLayer(3,32,'Padding',1)
                        batchNormalizationLayer
                        reluLayer
                        
                        maxPooling2dLayer(2,'Stride',2)
                        
                        convolution2dLayer(3,64,'Padding',1)
                        batchNormalizationLayer
                        reluLayer
                        
                        fullyConnectedLayer(10)
                        softmaxLayer
                        classificationLayer];
                    
                    % train
                    opts = trainingOptions('sgdm', ...
                        'MaxEpochs',10, ...
                        'Shuffle','every-epoch', ...
                        'ValidationData',{obj.DataValid,obj.LabelValid},...
                        'MiniBatchSize',batchNum,...
                        'InitialLearnRate',1e-3);
                    
                case 11 % Transfer learning with augement
                    netName         = 'Transfer learning with augement';
                    
                    imageAugmenter = imageDataAugmenter('RandRotation',[-20 20]);
                    
                    imageSize = [28 28 1];
                    datasource = augmentedImageSource(imageSize,XTrain,YTrain,'DataAugmentation',imageAugmenter);
                    
                    load('rcnnStopSigns.mat','cifar10Net');
                    layers     = cifar10Net.Layers;
                    layers(13) = fullyConnectedLayer(2,'Name','fc_out','WeightLearnRateFactor',20,'BiasLearnRateFactor',20);
                    layers(14) = softmaxLayer;
                    layers(15) = classificationLayer;
                    
                    % Set training options
                    opts = trainingOptions('sgdm', ...
                        'MiniBatchSize', 128, ...
                        'Shuffle','every-epoch', ...
                        'InitialLearnRate', 1e-3, ...
                        'LearnRateSchedule', 'piecewise', ...
                        'LearnRateDropFactor', 0.1, ...
                        'LearnRateDropPeriod', 100, ...
                        'MaxEpochs', 30, ...
                        'Verbose', true); 
                    
                case 21 % R-cnn with transfer learning
                     netName         = 'rcnn simple';
                   % Finally, train the R-CNN object detector using |trainRCNNObjectDetector|.
                    % The input to this function is the ground truth table which contains
                    % labeled stop sign images, the pre-trained CIFAR-10 network, and the
                    % training options. The training function automatically modifies the
                    % original CIFAR-10 network, which classified images into 10 categories,
                    % into a network that can classify images into 2 classes: stop signs and
                    % a generic background class.
                    
                    % must be + 1 label num - this is OK the first column is image path
                    labelNum    = size(obj.DataTrain,2); 
                    
                    load('rcnnStopSigns.mat','cifar10Net');
                    layers     = cifar10Net.Layers;
                    
                    layers(13) = fullyConnectedLayer(labelNum,'Name','fc_out','WeightLearnRateFactor',20,'BiasLearnRateFactor',20);
                    layers(14) = softmaxLayer;
                    layers(15) = classificationLayer;
                    
                    % Set training options
                    opts = trainingOptions('sgdm', ...
                        'MiniBatchSize', 32, ...
                        'InitialLearnRate', 1e-3, ...
                        'LearnRateSchedule', 'piecewise', ...
                        'LearnRateDropFactor', 0.1, ...
                        'LearnRateDropPeriod', 100, ...
                        'MaxEpochs', 20, ...
                        'Verbose', true);
                    
                case 22  % R-cnn
                    netName         = 'for r-cnn ';
                % Finally, train the R-CNN object detector using |trainRCNNObjectDetector|.
                % The input to this function is the ground truth table which contains
                % labeled stop sign images, the pre-trained CIFAR-10 network, and the
                % training options. The training function automatically modifies the
                % original CIFAR-10 network, which classified images into 10 categories,
                % into a network that can classify images into 2 classes: stop signs and
                % a generic background class.
                    
                    % must be + 1 label num - this is OK the first column is image path
                    labelNum    = size(obj.DataTrain,2); 
                    
                    load('rcnnStopSigns.mat','cifar10Net');
                    layers     = cifar10Net.Layers;
                    
                    layers(13) = fullyConnectedLayer(labelNum,'Name','fc_out','WeightLearnRateFactor',20,'BiasLearnRateFactor',20);
                    layers(14) = softmaxLayer;
                    layers(15) = classificationLayer;
                    
                    % Set training options
                    opts = trainingOptions('sgdm', ...
                        'MiniBatchSize', 128, ...
                        'InitialLearnRate', 1e-3, ...
                        'LearnRateSchedule', 'piecewise', ...
                        'LearnRateDropFactor', 0.1, ...
                        'LearnRateDropPeriod', 100, ...
                        'MaxEpochs', 50, ...
                        'Verbose', true);
                    
                case 23  % DEMOS Vehicle detection
                    
                    netName         = 'Vehicle Detect RCNN';
                    % must be + 1 label num - this is OK the first column is image path
                    labelNum    = size(obj.DataTrain,2); 
                    
                    % Create image input layer.
                    inputLayer = imageInputLayer([64 64 1]);
                    
                    %
                    % Next, define the middle layers of the network. The middle layers are made
                    % up of repeated blocks of convolutional, ReLU (rectified linear units),
                    % and pooling layers. These layers form the core building blocks of
                    % convolutional neural networks.
                    
                    % Define the convolutional layer parameters.
                    filterSize = [3 3];
                    numFilters = 32;
                    
                    % Create the middle layers.
                    middleLayers = [
                        
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    %maxPooling2dLayer(3, 'Stride',2)
                    
                    ];
                    %
                    % You can create a deeper network by repeating these basic layers. However,
                    % to avoid downsampling the data prematurely, keep the number of pooling
                    % layers low. Downsampling early in the network discards image information
                    % that is useful for learning.
                    %
                    % The final layers of a CNN are typically composed of fully connected
                    % layers and a softmax loss layer.

                    finalLayers = [

                    % Add a fully connected layer with 64 output neurons. The output size
                    % of this layer will be an array with a length of 64.
                    fullyConnectedLayer(numFilters)

                    % Add a ReLU non-linearity.
                    reluLayer()
                    
                    % Add a fully connected layer with 64 output neurons. The output size
                    % of this layer will be an array with a length of 64.
                    fullyConnectedLayer(64)

                    % Add a ReLU non-linearity.
                    reluLayer()
                    

                    % Add the last fully connected layer. At this point, the network must
                    % produce outputs that can be used to measure whether the input image
                    % belongs to one of the object classes or background.
                    fullyConnectedLayer(labelNum)

                    % Add the softmax loss layer and classification layer.
                    softmaxLayer()
                    classificationLayer()
                    ];
            
                    %
                    % Combine the input, middle, and final layers.
                    layers = [
                        inputLayer
                        middleLayers
                        middleLayers
                        finalLayers
                        ]


                    % Configure Training Options
                    % |trainFasterRCNNObjectDetector| trains the detector in four steps. The first
                    % two steps train the region proposal and detection networks used in Faster
                    % R-CNN. The final two steps combine the networks from the first two steps
                    % such that a single network is created for detection [1]. Each training
                    % step can have different convergence rates, so it is beneficial to specify
                    % independent training options for each step. To specify the network
                    % training options use |trainingOptions| from Neural Network Toolbox(TM).

                    %
                    % Here, the learning rate for the first two steps is set higher than the
                    % last two steps. Because the last two steps are fine-tuning steps, the
                    % network weights can be modified more slowly than in the first two steps.
                    %
                    % In addition, |'CheckpointPath'| is set to a temporary location for all
                    % the training options. This name-value pair enables the saving of
                    % partially trained detectors during the training process. If training is
                    % interrupted, such as from a power outage or system failure, you can
                    % resume training from the saved checkpoint.
                    
                    % Set training options
                    opts = trainingOptions('sgdm', ...
                        'MiniBatchSize', 64, ...
                        'InitialLearnRate', 1e-3, ...
                        'LearnRateSchedule', 'piecewise', ...
                        'LearnRateDropFactor', 0.1, ...
                        'LearnRateDropPeriod', 100, ...
                        'MaxEpochs', 20, ...
                        'Verbose', true);
                    
                case 24 % from Flowers
                    
                    netName         = 'Manual Flowers';
                    % must be + 1 label num - this is OK the first column is image path
                    labelNum        = size(obj.DataTrain,2); 
                    
                    
                    % Create image input layer.
                    inputLayer = imageInputLayer([32 32 1]);

                    %
                    % Next, define the middle layers of the network. The middle layers are made
                    % up of repeated blocks of convolutional, ReLU (rectified linear units),
                    % and pooling layers. These layers form the core building blocks of
                    % convolutional neural networks.

                    % Define the convolutional layer parameters.
                    filterSize = [3 3];
                    numFilters = 32;

                    % Create the middle layers.
                    middleLayers = [
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    maxPooling2dLayer(3, 'Stride',2)

                    ];
                    %
                    % You can create a deeper network by repeating these basic layers. However,
                    % to avoid downsampling the data prematurely, keep the number of pooling
                    % layers low. Downsampling early in the network discards image information
                    % that is useful for learning.
                    %
                    % The final layers of a CNN are typically composed of fully connected
                    % layers and a softmax loss layer.

                    finalLayers = [

                    % Add a fully connected layer with 64 output neurons. The output size
                    % of this layer will be an array with a length of 64.
                    fullyConnectedLayer(64)

                    % Add a ReLU non-linearity.
                    reluLayer()

                    % Add the last fully connected layer. At this point, the network must
                    % produce outputs that can be used to measure whether the input image
                    % belongs to one of the object classes or background.
                    fullyConnectedLayer(labelNum)

                    % Add the softmax loss layer and classification layer.
                    softmaxLayer()
                    classificationLayer()
                    ];

                    %
                    % Combine the input, middle, and final layers.
                    layers = [
                        inputLayer
                        middleLayers
                        finalLayers
                        ]


                    % options
                    opts = trainingOptions('sgdm', ...
                      'MiniBatchSize', 32, ...
                      'InitialLearnRate', 1e-6, ...
                      'MaxEpochs', 30,...
                      'Verbose', true);
                    
                case 25 % from Flowers Heavy
                    
                    netName         = 'Manual Flowers';
                    % must be + 1 label num - this is OK the first column is image path
                    labelNum        = size(obj.DataTrain,2); 
                    

                    % Create image input layer.
                    inputLayer = imageInputLayer([64 64 1]);

                    % Define the convolutional layer parameters.
                    filterSize = [3 3];
                    numFilters = 32;

                    % Create the middle layers.
                    middleLayers = [
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    %maxPooling2dLayer(3, 'Stride',2)
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    %maxPooling2dLayer(3, 'Stride',2)
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    convolution2dLayer(filterSize, numFilters, 'Padding', 1)
                    reluLayer()
                    ];
                    %
                    % You can create a deeper network by repeating these basic layers. However,
                    finalLayers = [
%                     fullyConnectedLayer(64)
%                     reluLayer()
                    fullyConnectedLayer(32)
                    reluLayer()
                    fullyConnectedLayer(16)
                    reluLayer()
                    fullyConnectedLayer(labelNum)
                    % Add the softmax loss layer and classification layer.
                    softmaxLayer()
                    classificationLayer()
                    ];

                    %
                    % Combine the input, middle, and final layers.
                    layers = [
                        inputLayer
                        middleLayers
                        finalLayers
                        ]

                    
                    % Set training options
                    opts = trainingOptions('sgdm', ...
                        'MiniBatchSize', 32, ...
                        'InitialLearnRate', 1e-3, ...
                        'LearnRateSchedule', 'piecewise', ...
                        'LearnRateDropFactor', 0.1, ...
                        'LearnRateDropPeriod', 100, ...
                        'MaxEpochs', 40, ...
                        'Verbose', true);

                  
                case 26  % DEMOS Vehicle detection
                    
                    netName         = 'Vehicle Detect Faster RCNN';
                    % must be + 1 label num - this is OK the first column is image path
                    labelNum        = size(obj.DataTrain,2); 
                    
                    % load pretrained model
                    data            = load('fasterRCNNVehicleTrainingData.mat');
                    
                    % Create image input layer.
                    layers                   = data.layers;
                    %layers(1).InputSize      = [32 32 1];
                    %layers(end).ClassNames   = {'hand'  'Background'};
            
                    % Options for step 1.
                    opts = trainingOptions('sgdm', ...
                        'MiniBatchSize', 32, ...
                        'Verbose', true,...
                        'InitialLearnRate', 1e-4, ...
                        'MaxEpochs', 30);   
                    
                    %
                    
                    
                    
                case 31  % AlexNet : transfer learning
                    netName         = 'AlexNet from Demo ';
                    
                    % must be + 1 label num - this is OK the first column is image path
                    labelNum    = size(obj.DataTrain,2);
                    
                    % Look at structure of pre-trained network
                    net = alexnet;
                    % Notice the last layer performs 1000 object classification
                    layers = net.Layers %#ok
                    
                    % Or even inspect the types of object this network was trained on
                    layers(25).ClassNames' %#ok we want to display this in command window
                    
                    % Alter network to fit our desired output
                    % The pre-trained layers at the end of the network are designed to classify
                    % 1000 objects. But we need to classify different objects now. So the
                    % first step in transfer learning is to replace alter just two of the layers of the
                    % pre-trained network with a set of layers that can classify 5 classes.
                    
                    % Get the layers from the network. The layers define the network
                    % architecture and contain the learned weights. Here we only alter two of
                    % the layers. Everything else stays the same.
                    
                    
                    layers(23) = fullyConnectedLayer(labelNum, 'Name','fc8');
                    layers(25) = classificationLayer('Name','myNewClassifier');
                    
                    
                    % Setup learning rates for fine-tuning
                    % For fine-tuning, we want to changed the network ever so slightly. How
                    % much a network is changed during training is controlled by the learning
                    % rates. Here we do not modify the learning rates of the original layers,
                    % i.e. the ones before the last 3. The rates for these layers are already
                    % pretty small so they don't need to be lowered further. You could even
                    % freeze the weights of these early layers by setting the rates to zero.
                    %
                    % Instead we boost the learning rates of the new layers we added, so that
                    % they change faster than the rest of the network. This way earlier layers
                    % don't change that much and we quickly learn the weights of the newer
                    % layer.
                    
                    % fc 8 - bump up learning rate for last layers
                    layers(end-2).WeightLearnRateFactor = 10;
                    layers(end-2).BiasLearnRateFactor = 20;
                    
                    
                    % We want the last layer to train faster than the other layers because
                    % bias the training proces to quickly improve the last layer and keep the
                    % other layers relatively unchanged
                    % When the network is training, how can we see inside?
                    % CNNs are historically fairly black box solutions, but we want insight into
                    % the training
                    
                    % Let's look at some options:
                    
                    % Plot the accuracy as we are training
                    
                    % Stop training based on certain criteria
                    
                    
                    
                    % Fine-tune the Network
                    
                    miniBatchSize = 16; % number of images it processes at once
                    maxEpochs = 20; % one epoch is one complete pass through the training data
                    % lower the batch size if your GPU runs out of memory
                    
                    %                     layers(13) = fullyConnectedLayer(labelNum,'Name','fc_out','WeightLearnRateFactor',20,'BiasLearnRateFactor',20);
                    %                     layers(14) = softmaxLayer;
                    %                     layers(15) = classificationLayer;
                    
                    opts = trainingOptions('sgdm', ...
                        'Verbose', true, ...
                        'LearnRateSchedule', 'none',...
                        'InitialLearnRate', 0.0001,...
                        'MaxEpochs', maxEpochs, ...
                        'MiniBatchSize', miniBatchSize,...
                        'OutputFcn','');
                    
                case 32 % https://www.mathworks.com/matlabcentral/answers/354274-error-using-trainfastrcnnobjectdetector
                    netName         = 'AlexNet from FileExchange ';
                    
                    % must be + 1 label num - this is OK the first column is image path
                    labelNum        = size(obj.DataTrain,2);
                    net             = alexnet;
                    layers          = net.Layers;
                    % Reduce output size of final max pooling layer by increasing pool size to 5.
                    % This changes the minimum size to 88-by-88.
                    layers(16) = maxPooling2dLayer(5,'stride',2);  
                    % reset fully connected layers because of the size change. 
                    % Note: This may not be the ideal set of layers and might require some experimentation
                    % to figure out the best number of layers after making this change to the max pooling
                    % layer. 
                    layers(17) = fullyConnectedLayer(4096);
                    layers(20) = fullyConnectedLayer(4096);
                    layers(23) = fullyConnectedLayer(labelNum);
                    layers(end) = classificationLayer();    
                    
                    miniBatchSize = 16; % number of images it processes at once
                    maxEpochs = 20; % one epoch is one complete pass through the training data
                    opts = trainingOptions('sgdm', ...
                        'Verbose', true, ...
                        'LearnRateSchedule', 'none',...
                        'InitialLearnRate', 0.0001,...
                        'MaxEpochs', maxEpochs, ...
                        'MiniBatchSize', miniBatchSize,...
                        'OutputFcn','');
                    
                    
                    
                otherwise
                    error('bad netType')
            end
            % save
            obj.NetLayers  = layers;
            obj.NetOptions = opts;
            obj.NetDatasrc = dataSource;
            obj.NetType    = netType;
            
            
            Print(obj, sprintf('Network %s is loaded.',netName), 'I');
            
            %Layers
        end
        
        % ==========================================
        % Train the networks
        function obj = TrainNetwork(obj)
            % TrainNetwork - trains RCNN net
            % Input:
            %   datarc   - what net to load
            %   layers     - network layers
            %   opts       -  traing options
            % Output:
            %   rcnn        - trained network
            
            if isempty(obj.NetLayers)
                Print(obj, sprintf('Network is not initialized.'), 'W'); return
            end
            
            % according to the net
            switch obj.NetType
                case 26 % Faster RCNN
                    
                    net = trainFasterRCNNObjectDetector(obj.DataTrain, obj.NetLayers, obj.NetOptions);
                    
                otherwise

            
                    % support augement datastore
                    if ~isempty(obj.NetDatasrc)
                        % Train DNN object detector. This will take several minutes.
                        net             = trainNetwork(obj.NetDatasrc,obj.NetLayers,obj.NetOptions);
                    elseif ~isempty(obj.LabelTrain)
                        % Train DNN object detector. This will take several minutes.
                        net             = trainNetwork(obj.DataTrain,obj.LabelTrain,obj.NetLayers,obj.NetOptions);
                    else
                        %net             = trainNetwork(obj.DataSet,obj.NetLayers,obj.NetOptions);
                        net             = trainRCNNObjectDetector(obj.DataTrain, obj.NetLayers,obj.NetOptions, ...
                        'NegativeOverlapRange', [0 0.3], 'PositiveOverlapRange',[0.6 1],'NumStrongestRegions' ,200);
                    end

                    %             % Train Faster R-CNN detector. Select a BoxPyramidScale of 1.2 to allow
                    %     % for finer resolution for multiscale object detection.
                    %     %detector = trainFasterRCNNObjectDetector(trainingData, layers, options, ...
                    %     detector = trainFasterRCNNObjectDetector(trainingData, layers, trainingOpts, ...
                    %         'NegativeOverlapRange', [0 0.3], ...
                    %         'PositiveOverlapRange', [0.6 1], ...
                    %         'BoxPyramidScale', 1.2);
                    %                 
                    %end
            end
            
            obj.Net         = net;
            
            % save for the future
            if ~exist(obj.SaveDir,'dir'),mkdir(obj.SaveDir); end
            fname   = fullfile(obj.SaveDir,obj.SaveFile);
            save(fname,'net');
            
            Print(obj, sprintf('Network is trained and saved to %s.',fname), 'I');            
            
        end
        
        % ==========================================
        % Test the networks
        function obj = TestNetwork(obj, imgInd)
            % TestNetwork - test rcnn classifier
            % Input:
            %   imgInd     -  image for test
            % Output:
            %   figures        - from test image 
            if nargin < 2, imgInd = 50; end
            
            % check
            if isempty(obj.Net)
                load(fullfile(obj.SaveDir,obj.SaveFile),'net');
            else
                net     = obj.Net;
            end
            if isempty(obj.DataTest)
                Print(obj, sprintf('Load test data for test first.'), 'W');  return
            end
            
            %
            % Test the R-CNN detector on a test image.
            t                       = imgInd;
            testImage               = imread(obj.DataTest.imageFileName{t}); 
            %testImage               = testImage(:,:,1);
            [bbox, score, label]    = detect(net, testImage, 'MiniBatchSize', 64, 'SelectStrongest', true);

            % Display strongest detection result.
            %[score, idx] = max(score);
            labelNum     = size(bbox,1);
            img          = testImage; %imadjust(testImage);
            %clrs         = jet(labelNum)*250;
            for idx = 1:labelNum
                box         = bbox(idx, :);
                annotation  = sprintf('%s: (C=%4.3f)', label(idx), score(idx));
                img         = insertObjectAnnotation(img, 'rectangle', box, annotation,'Color','r');
            end
            % Add true boxes
            labelNames      = obj.DataTest.Properties.VariableNames;
            trueLabelNum    = size(obj.DataTest,2)-1;
            for m = 1:trueLabelNum
                box         = obj.DataTest{imgInd,m+1};
                txt         = labelNames{m+1};
                img         = insertObjectAnnotation(img, 'rectangle', box{1}, txt,'Color','y');
            end
            %detectedImg = insertObjectAnnotation(detectedImg, 'rectangle', rcnnData.f(t,:), 'True');
            figure(95)
            imshow(img)
            title(t)
            
            % another test
            featureMap = activations(net.Network, testImage, 'softmax', 'OutputAs', 'channels');
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
        % Test the networks
        function obj = xCreateTrajectories(obj, dataPath)
            % TestNetwork - test rcnn classifier
            % Input:
            %   dataPath     -  path to video file
            % Output:
            %   figures        - from test image 
            if nargin < 2, dataPath = ''; end
            
            % check
            if isempty(obj.Net)
                load(fullfile(obj.SaveDir,obj.SaveFile),'net');
            else
                net     = obj.Net;
            end
            if ~exist(dataPath,'file')
                Print(obj, sprintf('%s is not found.',dataPath), 'W');  return
            end
            
            %
            % Test the R-CNN detector on a test image.
            %videoFReader            = vision.VideoFileReader(dataPath);
            videoFReader            = VideoReader(dataPath);
            videoPlayer             = vision.VideoPlayer;
            %isDone                  = false;
            %while ~isDone(videoFReader)
            while hasFrame(videoFReader)
                img               = readFrame(videoFReader);
                %img               = step(videoFReader);
                [bbox, score, label]    = detect(net, uint8(img(:,:,1)), 'MiniBatchSize', 64, 'SelectStrongest', true);

                % Display strongest detection result.
                %[score, idx] = max(score);
                labelNum     = size(bbox,1);
                %clrs         = jet(labelNum)*250;
                annotation   = cell(labelNum,1);
                for idx = 1:labelNum
                    %box         = bbox(idx, :);
                    annotation{idx}  = sprintf('%s: (C=%4.3f)', label(idx), score(idx));
                    %img         = insertObjectAnnotation(img, 'rectangle', box, annotation,'Color','r');
               end
                
                 img         = insertObjectAnnotation(img, 'rectangle', bbox, annotation,'Color','r');
               
                step(videoPlayer,img);
                if ~isOpen(videoPlayer), break; end
            end
            %release(videoFReader);
            release(videoPlayer);
            
        end
        
        
        
    end
    
    % GUI 
    methods
        
        % ==========================================
        % Show original data sub sample
        function ShowDataSet(obj, setType, figNum, showNum)
            % show input data for Cell arrays
            
            if nargin < 2, setType = 1; end
            if nargin < 3, figNum  = 12; end
            if nargin < 4, showNum = 9; end
            
            if figNum < 1, return; end
            
            if setType == 1
                dataSet = obj.DataTrain;
            else
                dataSet = obj.DataTest; figNum = figNum + 1;
            end
            dataNum = size(dataSet,1);
            if dataNum < 1, obj.Print('Load DataSet first'); return; end 
            
            % random indices
            showNum     = min(showNum,dataNum);
            showInd     = randi(dataNum,showNum,1);
            
            % make montage
            lbl         = dataSet.Properties.VariableNames(2:end);
            showData    = [];
            for k = 1:showNum
                    t   = showInd(k);
                    img = imread(dataSet.imageFileName{t});
                    box = dataSet{t,2:end};
                    %box = box{1};
                    %if all(cellfun(@numel,box)==4)
                    %box = cell2mat(box(:));
                    %lbl = obj.DataSet.labels{t};
                    for m = 1:length(lbl)
                    img = insertObjectAnnotation(img, 'Rectangle', box{m}, lbl{m}, 'LineWidth', 8);
                    end
                    %end
                    
                    showData = cat(4,showData,img);
            end
            figure(figNum),montage(showData), title('Subsample of the input data')
            
        end
        
        % ==========================================
        % Test the networks
        function xShowTrajectories(obj, imgInd)
            % TestNetwork - test rcnn classifier
            % Input:
            %   imgInd     -  image for test
            % Output:
            %   figures        - from test image 
            if nargin < 2, imgInd = 50; end
            
            % check
            if isempty(obj.Net)
                load(fullfile(obj.SaveDir,obj.SaveFile),'net');
            else
                net     = obj.Net;
            end
            if isempty(obj.DataTest)
                Print(obj, sprintf('Load test data for test first.'), 'W');  return
            end
            
            %
            % Test the R-CNN detector on a test image.
            t                       = imgInd;
            testImage               = imread(obj.DataTest.imageFileName{t}); 
            [bbox, score, label]    = detect(net, testImage, 'MiniBatchSize', 64, 'SelectStrongest', true);

            % Display strongest detection result.
            %[score, idx] = max(score);
            labelNum     = size(bbox,1);
            img          = imadjust(testImage);
            %clrs         = jet(labelNum)*250;
            for idx = 1:labelNum
                box         = bbox(idx, :);
                annotation  = sprintf('%s: (C=%4.3f)', label(idx), score(idx));
                img         = insertObjectAnnotation(img, 'rectangle', box, annotation,'Color','r');
            end
            % Add true boxes
            labelNames      = obj.DataTest.Properties.VariableNames;
            trueLabelNum    = size(obj.DataTest,2)-1;
            for m = 1:trueLabelNum
                box         = obj.DataTest{imgInd,m+1};
                txt         = labelNames{m+1};
                img         = insertObjectAnnotation(img, 'rectangle', box{1}, txt,'Color','y');
            end
            %detectedImg = insertObjectAnnotation(detectedImg, 'rectangle', rcnnData.f(t,:), 'True');
            figure(95)
            imshow(img)
            title(t)
            
            % another test
            featureMap = activations(net.Network, repmat(testImage,[1,1,3]), 'softmax', 'OutputAs', 'channels');
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
        % Testing data load
        function obj = xTestLoadImageData(obj, selType)
            % TestLoadImageData - test image data load
            % from different sources
            
            if nargin < 2, selType = 1; end
            
            % init
            switch selType
                case 1 % true image data
                    %dataPath        = 'C:\UsersJ\Uri\Data\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_016.avi';
                    dataPath        = 'C:\Uri\DataJ\Janelia\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_016.avi';
                    obj             = LoadImageData(obj, dataPath);
                case 2
                    %dataPath        = 'C:\UsersJ\Uri\Data\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_016.avi';
                    dataPath        = 'C:\Uri\DataJ\Janelia\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_016.avi';
                    obj             = LoadImageData(obj, dataPath);
                case 11 % using DMB
                    testVideoDir   = 'C:\Uri\DataJ\Janelia\Analysis\m8\02_10_14';
                    testTrial      = 3;
                    
                    dm             = TPA_DataManagerBehavior();
                    dm             = dm.SelectAllData(testVideoDir);
                    [dm, vidData]  = dm.LoadAllData(testTrial);
                    obj            = SetImageData(obj,vidData);
                    obj.DMB        = dm;
                    
                case 21 % synthetic
                    load('mri.mat','D');
                    obj            = SetImageData(obj,D);
                    
                case 22 % synthetic
                    dm             = TPA_MotionCorrectionManager();
                    dm             = dm.GenData(5,5);
                    obj            = SetImageData(obj,dm.ImgData);
                    
                case 31 % true data loaded straighforward
                    dm             = TPA_MotionCorrectionManager();
                    dm             = dm.GenData(13,6);
                    obj            = SetImageData(obj,dm.ImgData);
                    
                case 51, % small region confined to x,y,t
                    imgData        = zeros(80,96,128,'uint16');
                    imgData(30:50,40:56,60:68) = 128;
                    obj.DecimationFactor = [1 1 1];
                    obj            = SetImageData(obj,imgData);
                    
                case 52, % small region confined to x,y,t
                    imgData        = zeros(128,220,128,'uint16');
                    imgData(50:70,100:156,50:78) = 128;
                    imgData(50:70,100:156,60:61) = 0;
                    obj.DecimationFactor = [1 1 1];
                    obj            = SetImageData(obj,imgData);
                    
                    
                otherwise
                    error('Bad selType %d',selType)
            end
            % show
            %obj                     = PlayImgData(obj);
        end
        
        % ==========================================
        function obj = TestLoadDataFromLabeler(obj, dataType)
            % TestLoadDataFromLabeler - test data load from labeler export file and prepare small dataset
            % Input:
            %     labeler export file
            % Output:
            %     obj - updated structure
            if nargin < 2, dataType = 1; end
            
            % init all
            k = 1;
            dbStr(k).Path        = 'D:\Uri\Data\Technion\Videos\m8\02_10_14\Basler_side_10_02_2014_m8_1_LabelData.mat';
            k = 2;
            dbStr(k).Path        = 'D:\Uri\Data\Technion\Videos\m8\02_10_14\Basler_side_10_02_2014_m8_4_LabelData.mat';
            
            % Run over selected session file and load the dataset
            obj                 = LoadDataFromLabeler(obj,dbStr, true);
            
        end
        
        % ==========================================
        function obj = TestLoadDataFromSession(obj, dataType)
            % TestLoadDataFromSession - test data load from session file and prepare small dataset
            % Input:
            %     session file
            % Output:
            %     obj - updated structure
            if nargin < 2, dataType = 1; end
            
            % init all
            switch dataType
                case 1
                    k = 1;
                    dbStr(k).Path        = 'D:\Uri\Data\Technion\Videos\m8\GroundTruthSession.mat';
                otherwise
                    error('Bad dataType')
            end
            
            % Run over selected session file and load the dataset
            obj                 = LoadDataFromSession(obj,dbStr,true);
            
        end
        
        % ==========================================
        % Test database for testing and training on1D signals
        function obj = xTestSimpleDataset(obj)
            
            % params
            dbType              = 11;
            
            % predefined set
            obj                 = LoadSimlpeDataset(obj, dbType);
            
        end
                
        % ==========================================
        % Test & Train digit 28x28 image classifier
        function obj = TestAndTrainDigitNetwork(obj)
            
            % params
            dbType              = 1;
            netType             = 1;
            
            % predefined set
            obj                 = LoadSimlpeDataset(obj, dbType);
            
            % network and options
            obj                 = LoadNetwork(obj, netType);
            
            % run
            obj                 = TrainNetwork(obj);
            
            % test
            obj                 = TestNetworkForImages(obj);
            
        end
        
        % ==========================================
        % Test & Train digit 28x28 image classifier with augimation
        function obj = xTestAndTrainDigitNetworkAugemented(obj)
            
            % params
            dbType              = 1;
            netType             = 21;
            
            % predefined set
            obj                 = LoadSimlpeDataset(obj, dbType);   
            
            % network and options
            obj                 = LoadNetwork(obj, netType);
            
            % run
            obj                 = TrainNetwork(obj);
            
            % test
            obj                 = TestNetworkForImages(obj);

        end
        
        % ==========================================
        % Test & Train Labeler database classifier
        function obj = TestAndTrainLabelerNetwork(obj, dataType, netType)
            % Inputs:
            %   dataType - which dataset
            %   netType  - which net to train
            % Outputs
            %   net  - trained network
            if nargin < 2 , dataType = 1; end
            if nargin < 3 , netType = 21; end
            
            % prepare data
            [dbTrain,dbTest]    = PrepareLabelerData(obj, dataType);
            
            % params
            [p,f,~]             = fileparts(dbTrain(1).Path);
            obj.SaveDir         = p;
            obj.SaveFile        = [f,sprintf('_D%d_N%d.mat',dataType,netType)];
            
            % Run over selected session file and load the dataset
            obj                 = LoadDataFromLabeler(obj,dbTrain, true);
            
            % keep only hand motion
            %obj.DataTrain       = obj.DataTrain(:,1:2);
                        
            % network and options
            obj                 = LoadNetwork(obj, netType);
            
            % run
            obj                 = TrainNetwork(obj);
            
            % Run over selected session file and load the dataset
            obj                 = LoadDataFromLabeler(obj,dbTest, false);

            % keep only hand motion
            obj.DataTest        = obj.DataTest(:,1:2);
            
            
            % test
            obj                 = TestNetwork(obj);
            
        end
        
        % ==========================================
        % Test & Train Session Based classifier
        function obj = TestAndTrainSessionNetwork(obj, dataType, netType)
            % Inputs:
            %   dataType - which dataset
            %   netType  - which net to train
            % Outputs
            %   net  - trained network
            if nargin < 2 , dataType = 101; end
            if nargin < 3 , netType = 21; end
            
            % params
            obj.SaveFile        = sprintf('DataSessionCNN_D%d_N%d.mat',dataType,netType);
            
            % prepare data
            switch dataType
                case 1
                    dbTrain(1).Path        = '..\Data\SessionPeople.mat';
                case 101
                    dbTrain(1).Path        = 'Not Exist Will Ask';
                otherwise
                    error('Bad dataType')
            end
            
            % Run over selected session file and load the dataset
            obj                 = LoadDataFromSession(obj,dbTrain, true);
                        
            % network and options
            obj                 = LoadNetwork(obj, netType);
            
            % run
            obj                 = TrainNetwork(obj);
            
            % Run over selected session file and load the dataset
            %obj                 = LoadDataFromSession(obj,dbTest, false);
            obj.DataTest        = obj.DataTrain;
            
            % test
            obj                 = TestNetwork(obj);
            
        end
        
        % ==========================================
        % Test & Train Session Based classifier
        function obj = TestAndTrainVehicleDemo(obj, dataType, netType)
            % Inputs:
            %   dataType - which dataset
            %   netType  - which net to train
            % Outputs
            %   net  - trained network
            if nargin < 2 , dataType = 1; end
            if nargin < 3 , netType = 26; end
            
            % params
            obj.SaveFile        = sprintf('DataSessionCNN_D%d_N%d.mat',dataType,netType);
            
            % prepare data
            switch dataType
                case 1
                    dbTrain(1).Path        = '..\TwoPhotonData\GroundTruthSession_D8_0802.mat';
                case 101
                    dbTrain(1).Path        = 'Not Exist Will Load Ask';
                otherwise
                    error('Bad dataType')
            end
            
            % Run over selected session file and load the dataset
            obj                 = LoadDataFromSession(obj,dbTrain, true);
            obj.DataTrain       = obj.DataTrain(:,1:2);
                        
            % network and options
            obj                 = LoadNetwork(obj, netType);
            
            % run
            obj                 = TrainNetwork(obj);
            
            % Run over selected session file and load the dataset
            %obj                 = LoadDataFromSession(obj,dbTest, false);
            obj.DataTest        = obj.DataTrain;
            
            % test
            obj                 = TestNetwork(obj);
            
        end
        
        % ==========================================
        % How trajectories from ROIs are created
        function obj = TestCreateTrajectories(obj, dataType)
            % TestCreateTrajectories - trajectories test
            % Input:
            %     which path
            % Output:
            %     obj - updated structure
            if nargin < 2, dataType = 1; end
            
            % init all
            switch dataType
                case 1 % Home
                    dPath        = 'D:\Uri\Data\Technion\Videos\m8\02_10_14\Basler_side_10_02_2014_m8_4.avi';
                case 2
                    dPath        = 'D:\Uri\Data\Technion\Videos\m8\02_10_14\Basler_side_10_02_2014_m8_3.avi';
               case 11 % Technion
                    dPath        = 'C:\LabUsers\Uri\Data\Janelia\Videos\D10\8_6_14\Basler_06_08_2014_d10_003\movie_comb.avi';
             end
            
            % Run over selected session file and load the dataset
            obj                 = CreateTrajectories(obj,dPath);
            
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
            
            % Run over selected session file and load the dataset
            dbTrain(1).Path     = 'Not Exist Will Load Ask';
            obj                 = LoadDataFromSession(obj,dbTrain, true);
            cellData            = obj.DataTrain;            
            
            % run
            acfd                = trainACFObjectDetector(cellData,'NumStages',numStages,'Verbose',true);
            obj.SaveFile        = 'CellDataAcf.mat';
            save(fullfile(obj.SaveDir,obj.SaveFile),'cellData','acfd');

            
            % test
            obj                 = TestACF(obj, cellData, acfd);
            

        end
        
        % ==========================================
        % Test the ACF detector
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
        
        
    end
    
end % class



