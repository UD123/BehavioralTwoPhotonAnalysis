classdef TPA_BehaviorAnalysis
    %TPA_BehaviorAnalysis - Analysis tools per ROI
    % Extract data for all ROIs and do some feature analysis
    %
    
    %-----------------------------------------------------
    % Ver       Date        Who     What
    %-----------------------------------------------------
    % 2600      01.06.17    UD      video player small bug when figNum = 0.    
    % 2508      19.04.17    UD      making it better with memory management.    
    % 2501      27.02.17    UD      adapted from Tracker.    
    % 2316      21.06.16    UD      input adapted.    
    % 2005      19.05.15    UD      View Type selection.    
    % 1932      12.05.15    UD      Small change for Ronen.    
    % 1931      10.05.15    UD      Updating for Nice trajectory generation.
    % 0101      23.02.15    UD      Created using Matlab 2014b.
    %-----------------------------------------------------
    properties (Constant)
        MaxFrameNum         = 10000;  % number of frames
        FeatureNames        = {'Mean','Std','Flow'};
        %SetupDir            = '.\Setup\';
        %SetupFile           = 'ROIC_Setup.mat';  % setup, animal name, date
    end
    
    properties
        
        % image management and point tracker
        FrameCnt            = 0;
        ImgFrameRef         = []; % reference image frame
        ImgFramePrev        = []; % previous image frame
        FileNameROI         = '.\Setup\ROIC_Setup.mat';             
        FileNameVideo       = '';             
        
        % ROI structure
        StrROI              = {};
        ImgData             = [];
        
        % Analysis results 
        OpticalFlow         = [];
        
        
        % thresholds
        %TrackPosStdThr      = 30;     % abs distance in pixels
        %TrackMinLength      = 10;       % min length in frames
        
        % Average Trajectory
       % TrajectoryData         = [];   % contains trajectory info - average N x 3 array
        
        % diplay for debug
        videoReader
        videoPlayer
        
        % for display only
%         VisiblePoints           = [];
%         NewPoints               = [];
%         LostPoints              = [];
%         PrunePoints             = [];
        VideoSize                       % nR,nC,nD,nT
        
        % debug
        FigNum                  = 123;   % 0-no debug is shown
        
        
    end
    
    methods
        
        
        % ======================================
        function obj = TPA_BehaviorAnalysis()
            % TPA_BehaviorAnalysis - constructor
            % Input:
            %   none
            % Output:
            %   default values
            
            obj = InitAnalysis(obj);
            
        end
        
        % ======================================
        function obj = InitAnalysis(obj)
            % InitAnalysis - init analtysis structures            % Input:
            %   obj         - default
            %   videoFrame  - image frame
            % Output:
            %   obj         - updated object
            
            %if nargin < 2, videoFrame = ones(128,128,3); end
            
            
            obj.FrameCnt            = 0;
            obj.StrROI              = {};
            obj.ImgFramePrev        = [];
            obj.ImgFrameRef         = [];
            obj.ImgData             = [];
            % Create a System object to estimate direction and speed of object motion
            % from one video frame to another using optical flow.
            obj.OpticalFlow         = vision.OpticalFlow( ...
                'OutputValue', 'Horizontal and vertical components in complex form');


            
        end
        
        % ======================================
        function obj = ImportData(obj,imgData,strROI)
            % ImportData -  Initialize Video Data and ROI
            if nargin < 3, strROI = {}; end;
            % connect to global
            global SData 
            
            % check
            [nR,nC,nD,nT]           = size(imgData);
            if nR < 1,
                imgData             = SData.imBehaive;
            end
            
            
            % video init
            obj.videoReader         = [];
            obj.ImgData             = imgData;
            obj.FrameCnt            = 0;
            [obj,imgFrame]          = GetFrame(obj);
            
            % roi init
            obj.StrROI              = strROI;
            % show
            roiNum                  = length(obj.StrROI);  
            %figure(obj.FigNum + 1),imshow(uint8(imgFrame)); title('Analysis ROI');
            for m = 1:roiNum,
                position    = obj.StrROI{m}.xyInd;
                addOffset   = 0;
                if nD == 2 && obj.StrROI{m}.zInd > 1,
                    addOffset = nC;
                end            
                position(:,1) = position(:,1) + addOffset;
                
                %hp          = impoly(gca, position);
                %ind         = find(hp.createMask());
                imBW        = poly2mask(position(:,1), position(:,2), nR, nC + addOffset);
                ind         = find(imBW);
            
                % save
                %if doSaveData,
                obj.StrROI{m}.xyInd     = position;
                obj.StrROI{m}.PixInd    = ind;
            end
            
            
            % save
            obj.FileNameROI         = 'External';
            obj.FileNameVideo       = 'External';
                    
            DTP_ManageText([], sprintf('Behavior : Video Load from External Source.'), 'I' ) ;                  
            DTP_ManageText([], sprintf('Behavior : ROI Load from External Source.'), 'I' ) ;                  
            
            
        end
        
        % ======================================
        function [obj,strEvent] = ExportEvents(obj)
            % CreateEvents - creates events from the processed data
            % Input:
            %   obj         - StrROI is processed
            % Output:
            %   obj         - updated object
            
            roiNum              = length(obj.StrROI);
            if roiNum < 1, fprintf('Must have ROI defined\n'); end;
            
            frameCnt            = obj.FrameCnt;
            if frameCnt < 2, error('Must run video analysis furst'); end;
        
            featNum             = size(obj.StrROI{1}.Data,2);
            if featNum < 1, error('Must have features'); end;
            

            % prepare output according to image
            [nR,nC,nD,nT]       = size(obj.ImgData);


            % convert
            strEvent    = cell(roiNum*featNum,1);
            cnt         = 0;
            for r = 1:roiNum,
                for k = 1:featNum,
                    cnt = cnt + 1;
                    strEvent{cnt}       = obj.StrROI{r};
                    strEvent{cnt}.Data  = obj.StrROI{r}.Data(:,k);
                    %strEvent{cnt}.Name  = sprintf('%s-%s',obj.StrROI{r}.Name,obj.FeatureNames{k});
                    strEvent{cnt}.Name  = obj.StrROI{r}.Name; %sprintf('%s-%s',obj.StrROI{r}.Name,obj.FeatureNames{k});
                    if nD == 2 && strEvent{cnt}.zInd > 1,
                        strEvent{cnt}.xyInd(:,1) = strEvent{cnt}.xyInd(:,1) - nC;
                    end
                        
                end
            end
            
                
            
        end
        
        
        % ======================================
        function obj = Step(obj, videoFrame)
            % Step - process single frame
            % Input:
            %   videoFrame - image frame
            % Output:
            %   obj         - updated object
            
            if nargin < 2, videoFrame = ones(128,128,3); end
            
            % compute useful info
            %obj.FrameCnt        = obj.FrameCnt + 1;
%             [nR,nC,nD]          = size(videoFrame);
%             if nD > 1, videoFrame = rgb2gray(videoFrame); end;
%             if ~isa(videoFrame,'single'), videoFrame = single(videoFrame); end;
            
            % init detector of the reference frame
            if isempty(obj.ImgFrameRef),  obj.ImgFrameRef = videoFrame; end
            %if isempty(obj.ImgFramePrev), obj.ImgFramePrev = videoFrame; end
            
            
            roiNum              = length(obj.StrROI);
            assert(roiNum > 0,'Must have ROI defined');
            
            % for all ROIs
            for m = 1:roiNum,
                
                % get index
                ind             = obj.StrROI{m}.PixInd;
                
                % analysis of the different structures
                vMean           = mean(videoFrame(ind));
                obj.StrROI{m}.Data(obj.FrameCnt,1) = vMean;
                
%                 % diff
%                 vDiff           = std(videoFrame(ind) - obj.ImgFramePrev(ind));
%                 obj.StrROI{m}.Data(obj.FrameCnt,2) = vDiff;
%     
%                 % Compute the optical flow for that particular frame.
%                 optFlow         = step(obj.OpticalFlow,videoFrame);
%                 vFlow           = mean(abs(optFlow(ind)));    
%                 obj.StrROI{m}.Data(obj.FrameCnt,3) = vFlow;
                
            end
            
            % save
            obj.ImgFramePrev    = videoFrame;
                
            
        end
        
        % ======================================
        function obj = ExternalAnalysis(obj, imgData,strROI)
            % Loads data from repositories.
            if nargin < 3, error('Reuires 3 inputs') ; end;
            
            %obj         = InitAnalysis(obj);            
            obj         = ImportData(obj,imgData,strROI);
            obj         = ShowInit(obj,obj.FigNum);
           
            
            
%             % fast forward
%             while cnt < 600, 
%                 [obj,videoFrame] = GetFrame(obj);
%                 cnt              = cnt + 1;
%             end
            
            % init Tracker
            [obj,videoFrame]    = GetFrame(obj);
            obj.VideoSize       = size(videoFrame);
            obj.ImgFramePrev    = videoFrame;
            if ~isempty(obj.videoPlayer)
            obj.videoPlayer.Position = [100 100 100+obj.VideoSize([2 1])];
            end
            
            %obj                 = ManualRoiInit(obj,videoFrame);

            % Detect moving objects, and track them across video frames.
            cnt = 0;
            DTP_ManageText([], sprintf('Behavior : Starting Computation .....'), 'I' ) ;                  
            while ~IsFinished(obj) && cnt < obj.MaxFrameNum, % just to have a limit
                
                % get frame
                [obj,videoFrame]    = GetFrame(obj);
                cnt                 = cnt + 1;
                % debug
                %                 frame                       = frame*0;
                %                 frame(100:200,200:300,:)    = 128;
%                 if cnt == 2100,
%                     disp('dbg')
%                 end
                
                obj             = Step(obj, videoFrame);
                
                % show
                obj             = ShowUpdate(obj,videoFrame);
            end
            DTP_ManageText([], sprintf('Behavior : Finished'), 'I' ) ;                  
            
            % Show
            obj         = ShowRoiData(obj);
            
            
            
            
        end
        
        
    end
    
    methods % GUI & Test
                
        
        % ======================================
        function obj = InputInit(obj,testType)
            % Initialize Video Input
            % Create objects for reading a video from a file,
            
            % Create a video file reader.
            assert(isnumeric(testType), 'Must be a number between 0 - 200');
            switch testType,
                case 1
                    fname               = 'C:\LabUsers\Uri\Data\Janelia\Videos\D30a\8_15_14\Basler_15_08_2014_d30_002\movie_comb.avi';
                    rname               = 'C:\LabUsers\Uri\Data\Janelia\Videos\D30a\8_15_14\Basler_15_08_2014_d30_002\movie_comb.avi';
                case 2,
                    fname               = 'C:\LabUsers\Uri\Data\Janelia\Videos\D30a\8_15_14\Basler_15_08_2014_d30_002\movie_comb.avi';
                    rname               = 'C:\LabUsers\Uri\Data\Janelia\Videos\D30a\8_15_14\Basler_15_08_2014_d30_002\movie_comb.avi';
                 case 101,
                    fname               = 'C:\LabUsers\Uri\Data\Janelia\Videos\D30a\8_17_14_01-45\Basler_17_08_2014_d30_001\movie_comb.avi';
                    rname               = 'C:\LabUsers\Uri\Data\Janelia\Analysis\D30a\8_17_14_01-45\BDA_Basler_17_08_2014_d30_001.mat';
               otherwise
                    error('testType')
            end
            
            % video init
            obj.FrameCnt        = 0;
            if testType > 100,
                obj.videoReader     = VideoReader(fname);
                obj.ImgData         = read(obj.videoReader,[1 120]);
            else
                obj.videoReader     = vision.VideoFileReader(fname);
                obj.ImgData         = [];
            end
            
            % roi init
            [p,f,ex] = fileparts(rname);
            if ~exist(rname,'file') || ~strcmp(ex,'.mat'),
                DTP_ManageText([], sprintf('Behavior : No ROI file %s',rname), 'W' ) ;
                obj.StrROI          = {};
            else
                usrData             = load(rname,'strEvent');
                obj.StrROI          = usrData.strEvent;
            end
            
            
            % save
            obj.FileNameROI         = rname;
            obj.FileNameVideo       = fname;
                    
            DTP_ManageText([], sprintf('Behavior : Video Load from %s',obj.FileNameVideo), 'I' ) ;                  
            DTP_ManageText([], sprintf('Behavior : ROI Load from %s',obj.FileNameROI), 'I' ) ;                  
            
            
        end
        
        % ======================================
        function [obj,videoFrame] = GetFrame(obj)
            % GetFrame - get frame from the data
            
            % Create a video file reader.
            %assert(isa(obj.videoReader,'vision.VideoFileReader'), 'Must init video reader');
            obj.FrameCnt = obj.FrameCnt + 1;
            if isempty(obj.ImgData),
                videoFrame  = obj.videoReader.step();
            else
                obj.FrameCnt = min(obj.FrameCnt,size(obj.ImgData,4));
                videoFrame   = obj.ImgData(:,:,:,obj.FrameCnt);
            end
            [nR,nC,nD]          = size(videoFrame);
            if nD == 2, videoFrame = cat(2,videoFrame(:,:,1),videoFrame(:,:,2)); end;
            if nD == 3, videoFrame = rgb2gray(videoFrame); end;
            if ~isa(videoFrame,'single'), videoFrame = single(videoFrame); end;
            
            
        end
               
        % ======================================
        function isFinished = IsFinished(obj)
            % IsFinished - check the data end
            % Create a video file reader.
            %assert(isa(obj.videoReader,'vision.VideoFileReader'), 'Must init video reader');
            %obj.FrameCnt = obj.FrameCnt + 1;
            if isempty(obj.ImgData),
                isFinished  = isDone(obj.videoReader);
            else
                isFinished   = obj.FrameCnt >= size(obj.ImgData,4);
            end
        end
        
        
       % =======================================
        function [obj,IsOK] = SaveROI(obj)
            % SaveROI - save experiment setup data
            % Input:
            %       saveDir     - string:directory to save - overrides the default
            %       animalName  - string:animal name - overrides the default
            %       trialNum    - trial start number
            %       SetupData   - structure that contains required data for analysis
            % Output:
            %       - files on the disk
            
            IsOK = false;
            
            % create save files
            % with dir
            setupFileDir     = obj.FileNameROI; %fullfile(obj.SetupDir,obj.SetupFile);
            
            % get the data
            %[obj,setupData]   = GetSetupData(obj) ;
            strEvent           = obj.StrROI;
            
            % save the data
            fprintf('I : Saving %s ... ',setupFileDir); tic;
            try
                save(setupFileDir,'strEvent');
            catch ME
                error('%s : can not save setup data', ME.message);
            end
            fprintf('Done in %4.3f sec.\n',toc); 
            
            IsOK = true;
        end

        % =======================================
        function [obj,DoSaveData] = LoadROI(obj)
            % LoadROI - load experiment ROI data
            % Input:
            %       saveDir     - string:directory to save - overrides the default
            % Output:
            %       DoSaveData   - save data after that
            
            DoSaveData       = true;
            obj.StrROI       = {};
            
            % create save files
            setupFileDir     = obj.FileNameROI; %fullfile(obj.SetupDir,obj.SetupFile);
            
            % check
            if ~exist(setupFileDir,'file'),
                fprintf('W: No Setup data is found.\n');
                return
            end
            
            bSkipFileLoad	= 1;
            if exist(setupFileDir,'file'),

                Answer=questdlg('The setup for the specified image already exists?',  'Database',  'Create New','Use it','Create New');
                if strcmp(Answer,'Use it'), bSkipFileLoad = 0;end;

            end;      
            if bSkipFileLoad > 0.5, return; end;
            
            %[obj,setupData]   = GetSetupData(obj) ;
            
            % save the data
            fprintf('I : Loading %s ... ',setupFileDir); tic;
            try
                s = load(setupFileDir,'strEvent');
            catch ME
                error('%s : can not load setup data', ME.message);
            end
            fprintf('Done in %4.3f sec.\n',toc); 
            
            obj.StrROI = s.strROI;
            DoSaveData = false;
        end
        
        % =======================================
        function [obj,isOk] = GetROI(obj,imgFrame)
            % GetROI - gets ROI data from disk or define new and save 
            %  imgFrame - image to be tested
            % Output:
            %  isOk - ok
            
            % check 
            isOk                = false;
            
            [obj,doSaveData]    = LoadROI(obj);
            %if isempty(obj.SetupData),
            %end
            
            % if no setup to load - create new
            if isempty(obj.SetupData),
                figure(101),imshow(imgFrame);
                title('Draw ROI on the Image (Double Click to Finish)')
                h           = imfreehand(gca);
                position    = wait(h); 
                position    = [position;position(1,:)];
            else
                imgFrame    = obj.SetupData.ImgData;
                position    = obj.SetupData.Position;
            end
            
            % show
            figure(1),imshow(imgFrame);
            hold on; plot(position(:,1),position(:,2),'r'); hold off;
            title('Analysis ROI')
            
            % save
            if doSaveData,
                obj.SetupData.Position  = position;
                obj.SetupData.ImgData   = imgFrame;
                [obj,IsOK]              = SaveROI(obj);
            end
            fprintf('I : ROI is defined\n'); 
            
        end
        
       % =======================================
        function obj = ManualRoiInit(obj,imgFrame)
            % GetROI - gets ROI data from disk or define new and save 
            %  imgFrame - image to be tested
            % Output:
            %  isOk - ok
            
            % check 
            isOk                = false;
            roiNum              = length(obj.StrROI);
            imgFrame            = uint8(imgFrame);
            
            %[obj,doSaveData]    = LoadROI(obj);
            %if isempty(obj.SetupData),
            %end
            
            % if no setup to load - create new
            if roiNum < 1,
                figure(obj.FigNum + 1),imshow(imgFrame);
                title('Draw ROI on the Image (Double Click to Finish)');
                isDone = false; cnt = 0;
                while ~isDone,
                    h           = imfreehand(gca,'closed',true);
                    position    = wait(h); 
                    cnt         = cnt + 1;
                    obj.StrROI{cnt}.xyInd = position;
                    isDone      = ~strcmp('Yes',questdlg('Would you like to add another ROI'));
                end
            end
            
            % show
            roiNum          = length(obj.StrROI);            
            figure(obj.FigNum + 1),imshow(imgFrame); title('Analysis ROI');
            for m = 1:roiNum,
                position = obj.StrROI{m}.xyInd;
                hp        = impoly(gca, position);
                ind       = find(hp.createMask());
            
                % save
                %if doSaveData,
                obj.StrROI{m}.xyInd     = position;
                obj.StrROI{m}.PixInd    = ind;
            end
                %obj.SetupData.ImgData   = imgFrame;
                %[obj,IsOK]              = SaveROI(obj);
            %end
            fprintf('I : %d ROI are defined\n',roiNum); 
            
        end
        
        % ======================================
        function obj = ShowInit(obj, figNum)
            % Initialize Video I/O
            if nargin < 2, figNum = 0; end;
                        
            if figNum < 1, return; end;
            obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
            
            
        end
        
        
        % ======================================
        function [obj,videoFrame] = ShowUpdate(obj,videoFrame)
            % ShowUpdate - updates video player
            % Input:
            %   videoFrame - image frame RGB
            % Output:
            %   obj         - updated object
            %   videoFrame - image frame with symbols
            
            % not initialized - no show
            
            % make it RGB
            if size(videoFrame,3) < 2,
            videoFrame = repmat(videoFrame(:,:,1),[1 1 3]);
            end
            videoFrame      = uint8(videoFrame);
            
            % Show ROIS
            for m = 1:length(obj.StrROI),
                polyLine   = reshape(obj.StrROI{m}.xyInd',1,[]);
                videoFrame = insertShape(videoFrame,'polygon',polyLine);
                videoFrame = insertText(videoFrame,mean(obj.StrROI{m}.xyInd),num2str(obj.StrROI{m}.Data(obj.FrameCnt,:)));
            end
            
            
            if isempty(obj.videoPlayer), return; end;
            obj.videoPlayer.step(videoFrame);
        end
        
        
        % ======================================
        function obj = ShowRoiData(obj)
            % ShowRoiData - show data from ROIs 
            % Input:
            %   obj         - updated object with track info
            % Output:
            %   obj         - updated object with frame x pos x trackId array
            
            % checks
            if obj.FigNum < 1, return; end;
            
            roiNum              = length(obj.StrROI);
            if roiNum < 1, errordlg('No ROI is intialized'); return; end;
            
            frameCnt            = obj.FrameCnt;
            if frameCnt < 2, error('Must run video analysis furst'); end;
        
            featNum             = size(obj.StrROI{1}.Data,2);
            if featNum < 1, error('Must have features'); end;
            

            rNames = cell(roiNum,1);
            for m = 1:roiNum, rNames{m} = obj.StrROI{m}.Name ; end

            
            % show
            figure(obj.FigNum + 2),clf; set(gcf,'Tag','AnalysisROI'),colordef(gcf,'none');
            clrs  = jet(roiNum);
            tt    = (1:frameCnt)';
            for k = 1:featNum,
                for r = 1:roiNum,
                    subplot(featNum,1,k),
                    hold on
                    plot(tt,obj.StrROI{r}.Data(:,k),'color',clrs(r,:));
                    hold off;
                end
                if k == featNum, xlabel('Frame [#]');  legend(rNames);
                end;
                ylabel(obj.FeatureNames{k})
            end
            
            
        end
        
        % ======================================
        function obj = Close(obj)
            %%% Close
            % Stop tracking - release resources
            if ~isempty(obj.videoReader),
                release(obj.videoReader);
            end
            if ~isempty(obj.videoPlayer),
                release(obj.videoPlayer);
            end
        end
        
        % ======================================
        function obj = TestAnalysis(obj, testType)
            % Create System objects used for reading video, detecting tracking objects,
            % and displaying the results.
            if nargin < 2, testType = 1; end;
            
            % init IO
            if testType > 0,
                obj         = InputInit(obj, testType);
                obj         = ShowInit(obj,obj.FigNum);
                obj         = InitAnalysis(obj);
            else
                obj.FrameCnt = 0; 
            end
            
%             % fast forward
             cnt = 0;
            while cnt < 600, 
                [obj,videoFrame] = GetFrame(obj);
                cnt              = cnt + 1;
            end
            
            % init Tracker
            [obj,videoFrame]    = GetFrame(obj);
            obj.VideoSize       = size(videoFrame);
            obj.ImgFramePrev    = videoFrame;
            obj.videoPlayer.Position = [100 100 100+obj.VideoSize([2 1])];
            
            obj                 = ManualRoiInit(obj,videoFrame);

            % Detect moving objects, and track them across video frames.
            fprintf('Start Tracking ...\n')
            while ~IsFinished(obj) && cnt < 1200,
                
                % get frame
                [obj,videoFrame]    = GetFrame(obj);
                cnt                 = cnt + 1;
                % debug
                %                 frame                       = frame*0;
                %                 frame(100:200,200:300,:)    = 128;
                
                obj             = Step(obj, videoFrame);
                
                % show
                obj             = ShowUpdate(obj,videoFrame);
            end
            fprintf('Done\n')
            
            % Show
            obj         = ShowRoiData(obj);
            
            
        end
        
        % ======================================
        function obj = TestExternalAnalysis(obj, testType)
            % Loads data from repositories.
            if nargin < 2, testType = 1; end;
            
            % init IO
            assert(testType > 100,'Support full data load');
             
            obj         = InitAnalysis(obj);
            obj         = InputInit(obj, testType);
            
            % get the info
            imgData     = obj.ImgData;
            strROI      = obj.StrROI;
            
            obj         = ExternalAnalysis(obj, imgData,strROI);            
            
        end
        
        
    end % methods
end % class


