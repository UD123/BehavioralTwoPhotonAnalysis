classdef TPA_OpticalFlowTracking
    %%% Motion-Based Optical Flow Tracker
    % This example shows how to perform automatic detection and motion-based
    % tracking using optical flow in video stream.
    %
    
    %-----------------------------------------------------
    % Ver       Date        Who     What
    %-----------------------------------------------------
    % 0101      23.02.15    UD      Created using Matlab 2014b.
    %-----------------------------------------------------
    properties (Constant)
        MaxFrameNum         = 10000;  % number of frames
    end
    
    properties
        
        % image management and point tracker
        FrameCnt            = 0;
        OldPoints           = [];           % previous points
        %Points              = [];           % detected image points
        PointTracker        = [];           % point tracker
        BBox                = [1 1 2 2];    % image ROI
        
        
        % Track management
        TrackCnt            = 0;
        TrackIds            = [];
        TrackAge            = 0;
        TrackHist                       % history for all frames
        % thresholds
        TrackProxNewThr     = 5^2*2;          % prune the new points that are too close
        TrackProxDensThr    = 5^2*2/4;   % prune the valid points that are too close
       
        % Track Linkage
        TrackIsValid        = [];      % bool array size of track number
        TrackPosFrame       = [];       % 3D array of frame x pos x track id
        TrackMaxLen         = 0;        % max length of the tracker
        
        % thresholds
        TrackPosStdThr      = 30;     % abs distance in pixels
        TrackMinLength      = 10;       % min length in frames
        
        
        % diplay for debug
        videoReader
        videoPlayer
        
        % for display only
        VisiblePoints           = [];
        NewPoints               = [];
        LostPoints              = [];
        PrunePoints             = [];
        VideoSize                       % nR,nC,nD,nT
        
        % debug
        FigNum                  = 1;   % 0-no debug is shown
        
        
    end
    
    methods
        
        
        % ======================================
        function obj = TPA_OpticalFlowTracking()
            % DFM_OpticalFlowTracking - constructor
            % Input:
            %   none
            % Output:
            %   default values
            
            %obj = InitializeTracks(obj);
            
        end
        
        
        % ======================================
        function obj = InitializeTracks(obj)
            % InitializeTracks - % create an empty array of tracks
            % Input:
            %   obj         - default
            % Output:
            %   obj         - updated object
            
            if isempty(obj.OldPoints), error('Initialize Detector first. Call InitializeTracker'); end
            
            points      = obj.OldPoints;
            
            trackStr = struct('Ids',[],'Pos',[]);
            %             tracks = struct(...
            %                 'id', {}, ...
            %                 'pf', {}, ...
            %                 'pd', {}, ...
            %                 'kalmanFilter', {}, ...
            %                 'age', {}, ...
            %                 'totalVisibleCount', {}, ...
            %                 'consecutiveInvisibleCount', {});
            
            [trackHist{1:obj.MaxFrameNum}] = deal(trackStr);
            
            
            %%% Track Init
            % Track the points from frame to frame, and use
            % initialize tracker structure to to hold the results
            trackCnt                = size(points,1);
            Ids                     = (1:trackCnt)';
            trackIds                = Ids;
            trackAge                = Ids*0 + 1;
            trackHist{1}.Ids        = (1:trackCnt)';
            trackHist{1}.Pos        = points;
            
            obj.TrackCnt            = trackCnt;
            obj.TrackIds            = trackIds;
            obj.TrackAge            = trackAge;
            obj.TrackHist           = trackHist;
            
            
            
        end
        
        
        % ======================================
        function [obj,points] = Detect(obj, videoFrame, bBox)
            % Detect - detector of features KLT
            % Input:
            %   obj         - default
            %   videoFrame  - image frame
            % Output:
            %   obj         - updated object
            %   points      - detected points
            
            if nargin < 2, videoFrame = ones(128,128,3); end
            if nargin < 3,  bBox = [1 1 size(videoFrame,2) size(videoFrame,1)]; end;
            
            
            % Initialize features for I(1)
            if size(videoFrame,3) > 1,
            videoFrameGray          = rgb2gray(videoFrame);
            else
            videoFrameGray          = (videoFrame);    
            end
            
            % Detect feature points in the face region.
            points                  = detectMinEigenFeatures(videoFrameGray, 'ROI', bBox);
            points                  = points.Location;
            
            obj.BBox                = bBox;
            obj.OldPoints           = points;

            
        end
        
        
        % ======================================
        function obj = InitializeDetector(obj, videoFrame, bBox)
            % InitializeDetector - optical flow pointdetector
            % Input:
            %   obj         - default
            %   videoFrame  - image frame
            % Output:
            %   obj         - updated object
            
            if nargin < 2, videoFrame = ones(128,128,3); end
            if nargin < 3,  bBox = [1 1 size(videoFrame,2) size(videoFrame,1)]; end;
            
            
            % Initialize features for I(1)
            [obj,points]            = Detect(obj, videoFrame, bBox);
            
            % Create a point tracker and enable the bidirectional error constraint to
            % make it more robust in the presence of noise and clutter.
            pointTracker            = vision.PointTracker('MaxBidirectionalError', 2);
            
            % Initialize the tracker with the initial point locations and the initial
            % video frame.
            initialize(pointTracker, points, videoFrame);
            
            obj.PointTracker        = pointTracker;
            
            obj.FrameCnt            = 0;

            
        end
        
        
        
        % ======================================
        function obj = Step(obj, videoFrame)
            % Step - process single frame
            % Input:
            %   videoFrame - image frame
            % Output:
            %   obj         - updated object
            
            if nargin < 2, videoFrame = ones(128,128,3); end
            
            % get previous track info
            trackCnt            = obj.TrackCnt;
            trackIds            = obj.TrackIds;
            trackAge            = obj.TrackAge;
            
            % image info and point detector
            frameCnt            = obj.FrameCnt + 1;
            oldPoints           = obj.OldPoints;
            pointTracker        = obj.PointTracker;
            
            
            % Track the points. Note that some points may be lost.
            [points, isFound, scores]   = step(pointTracker, videoFrame);
            visiblePoints       = points(isFound, :);
            scores              = scores(isFound, :);
            lostPoints          = oldPoints(~isFound, :);
            visiblePointsNum    = size(visiblePoints,1);
            visibleTrackIds     = trackIds(isFound);
            visibleTrackAge     = trackAge(isFound) + 1;
            
            % Init new points
            %     videoFrameGray      = rgb2gray(videoFrame);
            %     newPoints           = detectMinEigenFeatures(videoFrameGray, 'ROI', bbox);
            %     newPoints           = newPoints.Location;
            
            [obj,newPoints]     = Detect(obj, videoFrame, obj.BBox);
            
            % Prune the old visible
            distD               = bsxfun(@minus,visiblePoints(:,1),newPoints(:,1)').^2 + bsxfun(@minus,visiblePoints(:,2),newPoints(:,2)').^2;
            [minV,minI]         = min(distD);
            newPointsBool       = minV > obj.TrackProxNewThr;
            newPoints           = newPoints(newPointsBool,:);
            newPointNum         = size(newPoints,1);
            newTrackIds         = trackCnt  + (1:newPointNum)';
            newTrackAge         = ones(newPointNum,1);
            
            % Prune the closest visible
            distD               = bsxfun(@minus,visiblePoints(:,1),visiblePoints(:,1)').^2 + bsxfun(@minus,visiblePoints(:,2),visiblePoints(:,2)').^2;
            [minV,minI]         = min(distD + eye(visiblePointsNum)*1000);
            prunePointsBool     = minV < obj.TrackProxDensThr & ((1:visiblePointsNum) ~= minI); % not equal to them selves
            prunePoints         = visiblePoints(prunePointsBool,:);
            visiblePoints       = visiblePoints(~prunePointsBool,:);
            visibleTrackIds     = visibleTrackIds(~prunePointsBool);
            visibleTrackAge     = visibleTrackAge(~prunePointsBool);
            
            
            % manage trackers - save the info
            %frameCnt           = frameCnt + 1;
            trackCnt            = trackCnt + newPointNum;
            trackIds            = [visibleTrackIds;newTrackIds];
            trackAge            = [visibleTrackAge;newTrackAge];
            oldPoints           = [visiblePoints;newPoints];
            
            % Reset the points
            setPoints(pointTracker, oldPoints);
            
            
            % save
            obj.TrackHist{frameCnt}.Ids     = trackIds;
            obj.TrackHist{frameCnt}.Pos     = oldPoints;
            
            obj.TrackCnt        = trackCnt            ;
            obj.TrackIds        = trackIds            ;
            obj.TrackAge        = trackAge            ;
            
            % image info and point detector
            obj.FrameCnt        = frameCnt ;
            obj.OldPoints       = oldPoints           ;
            obj.PointTracker    = pointTracker        ;
            
            % for display only
            obj.VisiblePoints   = visiblePoints;
            obj.NewPoints       = newPoints;
            obj.LostPoints      = lostPoints;
            obj.PrunePoints     = prunePoints;
            
        end
        
        
        % ======================================
        function obj = TrackLinkage(obj)
            % TrackLinkage - Track Linkage
            % Input:
            %   obj         - updated object with track info
            % Output:
            %   obj         - updated object with frame x pos x trackId array
            
            frameCnt            = obj.FrameCnt;
            trackCnt            = obj.TrackCnt;
            
            % Track Linkage
            trackPosFrame       = zeros(frameCnt,2,trackCnt,'single');
            for m = 1:frameCnt,
                ids = obj.TrackHist{m}.Ids;
                pos = obj.TrackHist{m}.Pos;
                
                if isempty(pos),continue; end;
                
                % assign
                trackPosFrame(m,1,ids) = pos(:,1);
                trackPosFrame(m,2,ids) = pos(:,2);
            end
            
            % remove too short
            %isNotTooShort = sum(trackPosFrame(:,1,:) > 0) > 3;
            %trackPosFrame = trackPosFrame(:,:,isNotTooShort);
            
            % remove constant
            isMoving      = false(1,trackCnt);
            isLong        = false(1,trackCnt);
            trackMaxLen   = 0;
            for k = 1:trackCnt,
                ii          = find(trackPosFrame(:,1,k) > 0);
                trackLen    = numel(ii);
                %     posMax      = squeeze(max(trackPosFrame(ii,:,k),[],1));
                %     posMin      = squeeze(min(trackPosFrame(ii,:,k),[],1));
                %     isMoving(k) = sum(posMax - posMin) > posStdThr;
                
                posStd      = squeeze(std(trackPosFrame(ii,:,k),[],1));
                isMoving(k) = (posStd(1) + posStd(2)) > obj.TrackPosStdThr;
                isLong(k)   = trackLen > obj.TrackMinLength;
                trackMaxLen = max(trackMaxLen,trackLen);
            end
            % remove all
            %trackPosFrame = trackPosFrame(:,:,isMoving & isLong);
            obj.TrackIsValid   = isMoving' & isLong';
            obj.TrackPosFrame  = trackPosFrame;
            obj.TrackMaxLen    = trackMaxLen;
            
        end
        

        
        % ======================================
        function [obj,trackPos] = GetAverageTrack(obj)
            % GetAverageTrack - get 10% of the most long tracks and average them
            % Input:
            %   obj         - updated object with track info
            % Output:
            %   obj         - updated object with frame x pos x trackId array
            
            if obj.TrackMaxLen < 10, error('Run track linkage or something bad with video - shake is too big'); end;
            
            frameCnt            = obj.FrameCnt;
            
            if obj.TrackMaxLen < 0.3*frameCnt, error('Trackers are too short'); end;
            
            trackCnt            = obj.TrackCnt;
            
            % find the longest
            activeBool          = squeeze(obj.TrackPosFrame(:,1,:)) > 0 ;
            activeFrames        = sum(activeBool);
            validTrackBool      = activeFrames > 0.85*obj.TrackMaxLen;
            validTrackNum       = sum(validTrackBool);
            assert(validTrackNum > 0,'Something strange - can not find valid trackers');
            
            % average the found tracks
            xPos                = squeeze(obj.TrackPosFrame(:,1,validTrackBool));
            yPos                = squeeze(obj.TrackPosFrame(:,2,validTrackBool));
            tCount              = sum(xPos > 0,2)+eps;
            
            trackPos            = [(1:frameCnt)' sum(xPos,2)./tCount sum(yPos,2)./tCount];
            
            
            % debug
            if obj.FigNum < 1, return; end;
            
            figure,
            plot3(trackPos(:,2),trackPos(:,1),trackPos(:,3))
            title('Average Frame Trajectory')
            set(gca,'zdir','reverse'); % like in image
            xlabel('X [pix]'),ylabel('Time [frame]'),zlabel('Y [pix]')
            axis([1 320 1 frameCnt 1 240]), grid on;
            
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
        function obj = InputInit(obj)
            % Initialize Video Input
            % Create objects for reading a video from a file,
            
            % Create a video file reader.
            %objSys.reader = vision.VideoFileReader('atrium.avi'); % vippedtracking.avi visiontraffic.avi
            %objSys.reader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\ZoomIn\OnTable.MP4'); % vippedtracking.avi visiontraffic.avi
            %objSys.reader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\ZoomIn\OnCup.MP4'); % vippedtracking.avi visiontraffic.avi
            %obj.videoReader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\ZoomIn\OnUri.MP4'); % vippedtracking.avi visiontraffic.avi
            obj.videoReader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\CamShake\CamShake_Far.avi');
        end
        
        % ======================================
        function obj = ShowInit(obj, figNum)
            % Initialize Video I/O
            if nargin < 2, figNum = 0; end;
            
            % for display only
            obj.VisiblePoints = [];
            obj.NewPoints = [];
            obj.LostPoints = [];
            obj.PrunePoints = [];
            
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
            
            trackIds   =   obj.TrackIds  ;
            oldPoints  =   obj.OldPoints ;
            
            % make it RGB
            if size(videoFrame,3) < 2,
            videoFrame = repmat(videoFrame(:,:,1),[1 1 3]);
            end
            
            % Display tracked points
            videoFrame = insertMarker(videoFrame, obj.VisiblePoints, '+', ...
                'Color', 'white');
            % Display new points
            videoFrame = insertMarker(videoFrame, obj.NewPoints, 's', ...
                'Color', 'green');
            % Display lost points
            videoFrame = insertMarker(videoFrame, obj.LostPoints, 'o', ...
                'Color', 'c');
            % Display points that are too close - -to be pruned
            videoFrame = insertMarker(videoFrame, obj.PrunePoints, 'x', ...
                'Color', 'red');
            
            
            % show text Draw the objects on the frame.
            showTrackIds        = 1:15:trackIds(end);
            %pointsNum           = size(oldPoints,1);
            % find matching indexes
            [~,ids]             = intersect(trackIds,showTrackIds);
            %ids                 = (1:17:pointsNum);
            labels              = cellstr(int2str(trackIds(ids)));
            circPos             = [oldPoints(ids,:) ones(numel(ids),1,'single')*2];
            videoFrame          = insertObjectAnnotation(videoFrame, 'circle', circPos, labels,'color','y','TextBoxOpacity',0.2);
            
            if isempty(obj.videoPlayer), return; end;
            obj.videoPlayer.step(videoFrame);
        end
        
        
        
        % ======================================
        function obj = ShowLinkage(obj,DoFilter)
            % ShowLinkage - show linked structure
            % Input:
            %   DoFilter     - filter slightly
            % Output:
            %   obj         - updated object
            
            if nargin < 2, DoFilter = false; end;
            
            trackCnt        = obj.TrackCnt;
            trackPosFrame   = obj.TrackPosFrame;
            isValidTrack    = obj.TrackIsValid;
            
            % recover this info
            if isempty(obj.VideoSize),
            nT              = obj.FrameCnt;
            nR              = 240;
            nC              = 320;
            else
            nT              = obj.VideoSize(4);
            nR              = obj.VideoSize(1);
            nC              = obj.VideoSize(2);                
            end
 
            % show tracks in 3D
            figure;set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
            cmap  = jet(trackCnt);
            for k = 1:trackCnt,
                if ~isValidTrack(k), continue; end;
                frameInd    = find(trackPosFrame(:,1,k) > 0);
                posX        = double(trackPosFrame(frameInd,1,k));
                posY        = double(trackPosFrame(frameInd,2,k));
                if DoFilter,
                    alpha = 0.1;
                    posX  = filtfilt(alpha,[1 -(1-alpha)],posX);
                    posY  = filtfilt(alpha,[1 -(1-alpha)],posY);
                end
                plot3(posX,frameInd,posY,'color',cmap(k,:)); hold on;
                text(posX(1),frameInd(1),posY(1),num2str(k),'color',cmap(k,:),'FontSize',6);
            end
            hold off;
            set(gca,'zdir','reverse'); % like in image
            xlabel('X [pix]'),ylabel('Time [frame]'),zlabel('Y [pix]')
            axis([1 nC 1 nT 1 nR]), grid on;
            title(sprintf('Track Trajectories. Filtered %d',DoFilter))
           
        end
        
        
        
        
        % ======================================
        function obj = TrackBehavior(obj)
            % Tracks behavioral image data
            % Assumes it is global
            
            global SData
            
            % use only side info
            sId         = 1;
            
            % check
            [nR,nC,nD,nT] = size(SData.imBehaive);
            obj.VideoSize = size(SData.imBehaive); % for display
            if nT < 2, error('No Behavior data is found'); end;
            if nR > 240 || nC > 320,
                warndlg('The video is too big. Please use decimation factors in Config Params to reduce the size','Video Size','modal')
                return
            end
            
            % init IO
            obj         = InputInit(obj);
            obj         = ShowInit(obj,1);
            
            % init Tracker
            videoFrame  = SData.imBehaive(:,:,sId,1);
            obj         = InitializeDetector(obj, videoFrame);
            obj         = InitializeTracks(obj);
            
            % Detect moving objects, and track them across video frames.
            DTP_ManageText([], sprintf('Behavior : Start Tracking ...'), 'I' ,0) ;
            for  n = 1:nT,
                
                % get frame
                videoFrame       = SData.imBehaive(:,:,sId,n);
                % debug
                %                 frame                       = frame*0;
                %                 frame(100:200,200:300,:)    = 128;
                
                % step
                obj             = Step(obj, videoFrame);
                
                % path relaibility
                obj             = ShowUpdate(obj,videoFrame);
            end
            DTP_ManageText([], sprintf('Behavior : Done Tracking.'), 'I' ,0) ;
            
            % linkage
            obj = TrackLinkage(obj);
            
            % show linkage
            obj = ShowLinkage(obj, false);
            
            % get average and show it
            %[obj,trackPos] = GetAverageTrack(obj);
            
        end
        
        
        % ======================================
        function obj = TestTracking(obj)
            % Create System objects used for reading video, detecting tracking objects,
            % and displaying the results.
            
            % init IO
            obj         = InputInit(obj);
            obj         = ShowInit(obj,1);
            
            % init Tracker
            videoFrame  = obj.videoReader.step();
            obj         = InitializeDetector(obj, videoFrame);
            obj         = InitializeTracks(obj);
            
            % Detect moving objects, and track them across video frames.
            fprintf('Start Tracking ...\n')
            while ~isDone(obj.videoReader),
                
                % get frame
                frame           = obj.videoReader.step();
                % debug
                %                 frame                       = frame*0;
                %                 frame(100:200,200:300,:)    = 128;
                
                obj             = Step(obj, frame);
                
                % path relaibility
                obj             = ShowUpdate(obj,frame);
            end
            fprintf('Done\n')
            
            % linkage
            obj = TrackLinkage(obj);
            
            % show linkage
            obj = ShowLinkage(obj);
            
            % get average and show it
            [obj,trackPos] = GetAverageTrack(obj);
            
        end
        
        
        
    end % methods
end % class


