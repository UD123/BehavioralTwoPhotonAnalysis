classdef TPA_OpticalFlowTracking
    %%% Motion-Based Optical Flow Tracker
    % This example shows how to perform automatic detection and motion-based
    % tracking using optical flow in video stream.
    %
    
    %-----------------------------------------------------
    % Ver       Date        Who     What
    %-----------------------------------------------------
    % 2712      04.12.17    UD      filter trajectories by roi.    
    % 2705      22.10.17    UD      trying to filter trajectories.    
    % 2605      11.07.16    UD      add parameters.    
    % 2316      21.06.16    UD      input adapted.    
    % 2005      19.05.15    UD      View Type selection.    
    % 1932      12.05.15    UD      Small change for Ronen.    
    % 1931      10.05.15    UD      Updating for Nice trajectory generation.
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
        TrackProxDensThr    = 5^2*2/12;   % prune the valid points that are too close
       
        % Track Linkage
        TrackIsValid        = [];      % bool array size of track number
        TrackPosFrame       = [];       % 3D array of frame x pos x track id
        TrackMaxLen         = 0;        % max length of the tracker
        
        % thresholds
        TrackPosStdThr      = 5;     % abs distance in pixels
        TrackMinLength      = 10;       % min length in frames
        
        % spatial ROIs
        TrackBoundROI            = []; % ROI
        
        % Average Trajectory
       % TrajectoryData         = [];   % contains trajectory info - average N x 3 array
        
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
        function obj = SetParameters(obj)
            % SetParameters - % GUI for parameters
            % Input:
            %   obj         - default
            % Output:
            %   obj         - updated object
            
                % config small GUI 
                options              = struct('Resize','on','WindowStyle','modal','Interpreter','none');
                prompt                = {'Min Trajectory Length  [frames]',...
                                         'Min Move Deviation (std(X)+std(Y)) [pix]',...            
                                        };
                name                = 'Config Track Parameters';
                numlines            = 1;
                defaultanswer       ={num2str(obj.TrackMinLength),num2str(obj.TrackPosStdThr)};
                answer              = inputdlg(prompt,name,numlines,defaultanswer,options);
                if isempty(answer), return; end;


                % try to configure
                obj.TrackMinLength   = max(1,min(1000,str2num(answer{1})));
                obj.TrackPosStdThr   = max(1,min(1000,str2num(answer{2})));
                
                
                DTP_ManageText([], 'Behavior : Track parameters are updated.', 'I' ,0)   ;   
            
        end
        

        % ======================================
        function obj = SetTrajectoriesForROI(obj, strEvent, decimFactor)
            % SetTrajectoriesForROI - % set roi for sptial filtering
            % Input:
            %   obj         - default
            % Output:
            %   obj         - updated object
            if nargin < 2, strEvent = {}; end
            if nargin < 3, decimFactor = 1; end
            eventNum = length(strEvent);
            if eventNum < 1, error('Initialize ROI data first'); end
            eventNames{1} = strEvent{1}.Name;
            for m = 2:length(strEvent)
            eventNames{m} = strEvent{m}.Name;
            end
            [s,ok] = listdlg('PromptString','Select ROI for spatial filtering:','ListString',eventNames,'SelectionMode','single');
            if ~ok, return; end
            
            xyBound                 = strEvent{s}.xyInd;
            % check decimation 
            obj.TrackBoundROI       = xyBound ./ decimFactor;
            
            
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
        % For Maria : Please use it carefully
        function validTrackBool = GetValidTracksManually(obj)
            % ShowAverage - get valid tracks and average them
            % Input:
            %   obj         - updated object with track info
            % Output:
            %   obj         - updated object with frame x pos x trackId array
            
            if obj.TrackMaxLen < 10, error('Run track linkage or something bad with video - shake is too big'); end;
            
            frameCnt            = obj.FrameCnt;
            
            if obj.TrackMaxLen < 0.3*frameCnt, error('Trackers are too short'); end;
            
            %isValidTrack    = obj.TrackIsValid;
            
            % recover this info
            if isempty(obj.VideoSize)
            nT              = obj.FrameCnt;
            nR              = 240;
            nC              = 320;
            else
            nT              = frameCnt;
            nR              = obj.VideoSize(1);
            nC              = obj.VideoSize(2);                
            end
            
            % std and length
            trackCnt            = obj.TrackCnt;
            isMoving            = false(1,trackCnt);
            isLong              = false(1,trackCnt);
            trackMaxLen         = 0;
            for k = 1:trackCnt
                ii          = find(obj.TrackPosFrame(:,1,k) > 0);
                trackLen    = numel(ii);
                %     posMax      = squeeze(max(trackPosFrame(ii,:,k),[],1));
                %     posMin      = squeeze(min(trackPosFrame(ii,:,k),[],1));
                %     isMoving(k) = sum(posMax - posMin) > posStdThr;
                
                posStd      = squeeze(std(obj.TrackPosFrame(ii,:,k),[],1));
                isMoving(k) = (posStd(1) + posStd(2)) > obj.TrackPosStdThr;
                isLong(k)   = trackLen > obj.TrackMinLength;
                trackMaxLen = max(trackMaxLen,trackLen);
            end
            % remove all
            validTrackBool   = isMoving' & isLong';
            
            
            
            % find the longest
            %validTrackBool      = isValidTrack; %activeFrames > obj.TrackMinLength; %0.25*obj.TrackMaxLen;
            validTrackNum       = sum(validTrackBool);
            assert(validTrackNum > 0,'Something strange - can not find valid trackers');
            
%             % patch - exclude food trajectories : frame 600 xpos > 150
%             nonValidTrackBool   = squeeze(obj.TrackPosFrame(600,1,:)) > nC/2;
%             validTrackBool      = validTrackBool & (~nonValidTrackBool);
%             % patch - exclude food trajectories : frame 1400 xpos > 150
%             nonValidTrackBool   = squeeze(obj.TrackPosFrame(1400,1,:)) > nC/2;
%             validTrackBool      = validTrackBool & (~nonValidTrackBool);
            
            % XY boundaries
            if isempty(obj.TrackBoundROI), return; end
            
            % find max nad min for each trajectory and each point that inside the polygon
            xBound                = obj.TrackBoundROI(:,1);
            yBound                = obj.TrackBoundROI(:,2);
            validTrackPolygonBool = false(size(validTrackBool));
            for m = 1:validTrackNum
                if ~validTrackBool(m), continue; end
                % some tracks are not started at 1 and finished at the end - they have zeros
                validFrames         = obj.TrackPosFrame(:,1,m) > 0;
                xTraj               = squeeze(obj.TrackPosFrame(validFrames,1,m));
                yTraj               = squeeze(obj.TrackPosFrame(validFrames,2,m));
                
                in                  = inpolygon(xTraj,yTraj,xBound,yBound);
                validTrackPolygonBool(m) = all(in);
            end
            validTrackBool      = validTrackBool & validTrackPolygonBool;
            
            %obj.TrackIsValid   = validTrackBool;
                        
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
            
            isValidTrack    = obj.TrackIsValid;
            
            % recover this info
            if isempty(obj.VideoSize)
            nT              = obj.FrameCnt;
            nR              = 240;
            nC              = 320;
            else
            nT              = frameCnt;
            nR              = obj.VideoSize(1);
            nC              = obj.VideoSize(2);                
            end
            
            dF = 1;
            if nR > 240 || nC > 320,
                %warndlg('The video is too big. Software will use decimation factors to reduce the size to 240x320','Video Size','modal')
                dF  = 2;
            end
            
            % find the longest
%             activeBool          = squeeze(obj.TrackPosFrame(:,1,:)) > 0 ;
%             activeFrames        = sum(activeBool);
            validTrackBool      = isValidTrack; %activeFrames > obj.TrackMinLength; %0.25*obj.TrackMaxLen;
            validTrackNum       = sum(validTrackBool);
            assert(validTrackNum > 0,'Something strange - can not find valid trackers');
            
%             % patch - exclude food trajectories : frame 700 xpos > 150
%             nonValidTrackBool   = squeeze(obj.TrackPosFrame(700,1,:)) > nC/2;
%             validTrackBool      = validTrackBool & (~nonValidTrackBool);

            validTrackBool      = GetValidTracksManually(obj);
            
            % average the found tracks
            xPos                = squeeze(obj.TrackPosFrame(:,1,validTrackBool))*dF;
            yPos                = squeeze(obj.TrackPosFrame(:,2,validTrackBool))*dF;
            tCount              = sum(xPos > 0,2)+eps;
            
            trackPos            = [(1:frameCnt)' sum(xPos,2)./tCount sum(yPos,2)./tCount];
            
            
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
        function obj = InputInit(obj,fname)
            % Initialize Video Input
            % Create objects for reading a video from a file,
            
            % Create a video file reader.
            %obj.videoReader = vision.VideoFileReader('atrium.avi'); % vippedtracking.avi visiontraffic.avi
            %obj.videoReader     = vision.VideoFileReader('visiontraffic.avi'); % vippedtracking.avi visiontraffic.avi
            %objSys.reader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\ZoomIn\OnTable.MP4'); % vippedtracking.avi visiontraffic.avi
            %objSys.reader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\ZoomIn\OnCup.MP4'); % vippedtracking.avi visiontraffic.avi
            %obj.videoReader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\ZoomIn\OnUri.MP4'); % vippedtracking.avi visiontraffic.avi
            %obj.videoReader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\CamShake\CamShake_Far.avi');
            if nargin < 1,
            fname               = 'C:\Uri\DataJ\Janelia\Videos\d10\Basler_side_06_08_2014_d10_015.avi';
            end
            obj.videoReader     = vision.VideoFileReader(fname);
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
            nT              = obj.FrameCnt;
            nR              = obj.VideoSize(1);
            nC              = obj.VideoSize(2);                
            end
            
            % filter tracks manually
            validTrackNum       = sum(isValidTrack);
            assert(validTrackNum > 0,'Something strange - can not find valid trackers');
            
%             % patch - exclude food trajectories : frame 700 xpos > 150
%             nonValidTrackBool   = squeeze(obj.TrackPosFrame(600,1,:)) > nC/2;
%             isValidTrack        = isValidTrack & (~nonValidTrackBool);
%             nonValidTrackBool   = squeeze(obj.TrackPosFrame(1400,1,:)) > nC/2;
%             isValidTrack        = isValidTrack & (~nonValidTrackBool);

            isValidTrack = GetValidTracksManually(obj);
 
            % show tracks in 3D
            figure;set(gcf,'Tag','AnalysisROI','Color','w','Name','Traj'),clf; colordef(gcf,'none');
            cmap  = jet(trackCnt);
            for k = 1:trackCnt,
                if ~isValidTrack(k), continue; end;
                frameInd    = find(trackPosFrame(:,1,k) > 0);
                posX        = double(trackPosFrame(frameInd,1,k));
                posY        = double(trackPosFrame(frameInd,2,k));
                if DoFilter
                    alpha = 0.1;
                    posX  = filtfilt(alpha,[1 -(1-alpha)],posX);
                    posY  = filtfilt(alpha,[1 -(1-alpha)],posY);
                end
%                 plot3(posX,frameInd,posY,'color',cmap(k,:)); hold on;
%                 text(posX(1),frameInd(1),posY(1),num2str(k),'color',cmap(k,:),'FontSize',6);
                plot3(posX,frameInd,posY,'color','r'); hold on;
                %text(posX(1),frameInd(1),posY(1),num2str(k),'color',cmap(k,:),'FontSize',6);
            end
            hold off;
            set(gca,'zdir','reverse'); % like in image
            xlabel('X [pix]'),ylabel('Time [frame]'),zlabel('Y [pix]')
            axis([1 nC 1 nT 1 nR]), grid on;
            title(sprintf('Track Trajectories. Filtered %d',DoFilter))
           
        end
        
        % ======================================
        function obj = ShowAverage(obj)
            % ShowAverage - get valid tracks and average them
            % Input:
            %   obj         - updated object with track info
            % Output:
            %   obj         - updated object with frame x pos x trackId array
            
            if obj.TrackMaxLen < 10, error('Run track linkage or something bad with video - shake is too big'); end;
            
            frameCnt            = obj.FrameCnt;
            
            if obj.TrackMaxLen < 0.3*frameCnt, error('Trackers are too short'); end;
            
            trackCnt        = obj.TrackCnt;
            trackPosFrame   = obj.TrackPosFrame;
            isValidTrack    = obj.TrackIsValid;
            
            % recover this info
            if isempty(obj.VideoSize)
            nT              = obj.FrameCnt;
            nR              = 240;
            nC              = 320;
            else
            nT              = frameCnt;
            nR              = obj.VideoSize(1);
            nC              = obj.VideoSize(2);                
            end
            
            
            % find the longest
%             activeBool          = squeeze(obj.TrackPosFrame(:,1,:)) > 0 ;
%             activeFrames        = sum(activeBool);
            validTrackBool      = isValidTrack; %activeFrames > obj.TrackMinLength; %0.25*obj.TrackMaxLen;
            validTrackNum       = sum(validTrackBool);
            assert(validTrackNum > 0,'Something strange - can not find valid trackers');
            
%             % patch - exclude food trajectories : frame 700 xpos > 150
%             nonValidTrackBool   = squeeze(obj.TrackPosFrame(600,1,:)) > nC/2;
%             validTrackBool      = validTrackBool & (~nonValidTrackBool);
%             nonValidTrackBool   = squeeze(obj.TrackPosFrame(1400,1,:)) > nC/2;
%             validTrackBool      = validTrackBool & (~nonValidTrackBool);

            validTrackBool      = GetValidTracksManually(obj);
            
            % average the found tracks
            xPos                = squeeze(obj.TrackPosFrame(:,1,validTrackBool));
            yPos                = squeeze(obj.TrackPosFrame(:,2,validTrackBool));
            tCount              = sum(xPos > 0,2)+eps;
            
            trackPos            = [(1:frameCnt)' sum(xPos,2)./tCount sum(yPos,2)./tCount];
            vind                = trackPos(:,2)>1;
            
            % debug
            if obj.FigNum < 1, return; end;
            hFig = findobj('Name','Traj');
            if ~isempty(hFig), % add to the current
                figure(hFig(1))
                hold on;
                plot3(trackPos(vind,2),trackPos(vind,1),trackPos(vind,3),'c','LineWidth',2);
                hold off;
            else
                figure,set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
                plot3(trackPos(:,2),trackPos(:,1),trackPos(:,3),'g','LineWidth',2)
                title('Average Frame Trajectory')
                set(gca,'zdir','reverse'); % like in image
                xlabel('X [pix]'),ylabel('Time [frame]'),zlabel('Y [pix]')
                axis([1 nC 1 frameCnt 1 nR]), grid on;
            end
            
        end
        
        % ======================================
        function obj = TrackBehavior(obj,viewType)
            % Tracks behavioral image data
            % Assumes it is global
            if nargin < 2, viewType = 'side'; end;
            
            global SData
            
            % use only side info
            sId         = find(strcmp({'side','front'},viewType));
            if isempty(sId),error('viewType must be side or front'); end;
            
            % check
            [nR,nC,nD,nT] = size(SData.imBehaive);
            obj.VideoSize = size(SData.imBehaive); % for display
            if nT < 2, error('No Behavior data is found'); end;
            dF = 1;
            if nR > 240 || nC > 320,
                warndlg('The video is too big. Software will use decimation factors to reduce the size to 240x320','Video Size','modal')
                dF  = 2;
                %return
            end
            
            % init IO
            %obj         = InputInit(obj);
            obj         = ShowInit(obj,1);
            
            % init Tracker
            videoFrame  = SData.imBehaive(1:dF:nR,1:dF:nC,sId,1);
            obj         = InitializeDetector(obj, videoFrame);
            obj         = InitializeTracks(obj);
            
            % Detect moving objects, and track them across video frames.
            DTP_ManageText([], sprintf('Behavior : Start Tracking ...'), 'I' ,0) ;
            %nT = 400;
            %F(nT) = struct('cdata',[],'colormap',[]);
            for  n = 1:nT
                
                % get frame
                videoFrame       = SData.imBehaive(1:dF:nR,1:dF:nC,sId,n);
                % debug
                %                 frame                       = frame*0;
                %                 frame(100:200,200:300,:)    = 128;
                
                % step
                obj             = Step(obj, videoFrame);
                
                % path relaibility
                [obj,vF]        = ShowUpdate(obj,videoFrame);
                %F(n)            = im2frame(vF);
            end
            DTP_ManageText([], sprintf('Behavior : Done Tracking.'), 'I' ,0) ;
            
%             % write
%             myVideo = VideoWriter('mytrack.avi');
%             myVideo.Quality = 90;    % Default 75
%             open(myVideo);
%             writeVideo(myVideo, F);
%             close(myVideo);
            
            
            % linkage
            obj = TrackLinkage(obj);
            
            % show linkage
            obj = ShowLinkage(obj, false);
            
            % get average and show it
            %[obj,trackPos] = GetAverageTrack(obj);
            obj = ShowAverage(obj);
            
        end
        
        % ======================================
        function obj = ShowVolume(obj)
            % Tracks behavioral image data
            % Assumes it is global
            
            global SData
            
            % use only side info
            sId         = 1;
            %indT        = 400:1400; % interesting part
            xmin        = 700;
            xmax        = 942;
            xmean       = 831;
            indT        = xmin:xmax; % interesting part
            
            % check
            [nR,nC,nD,nT] = size(SData.imBehaive);
            if nT < 2, error('No Behavior data is found'); end;
            if nR > 240 || nC > 320,
                warndlg('The video is too big. Please use decimation factors in Config Params to reduce the size','Video Size','modal')
                return
            end
            
            V3D                 = double(squeeze(SData.imBehaive(:,:,sId,indT)));
            V3D                 = shiftdim(V3D,1);% z is Y and Y is Z
            %[nC,nT,nR]          = size(V3D);
            [X3D,Y3D,Z3D]       = meshgrid(indT,1:nC,1:nR);
            
            
            % show slices
            figure;set(gcf,'Tag','AnalysisROI','Color','w'),clf; %colordef(gcf,'none');
            hsurfaces = slice(X3D,Y3D,Z3D,V3D,[xmin xmean xmax],[],[]);
            set(hsurfaces,'FaceColor','interp','EdgeColor','none')
            
               
            colormap gray;
            set(gca,'zdir','reverse'); % like in image            
            set(gca,'ydir','reverse'); 

            
            %hcont = contourslice(X3D,Y3D,Z3D,V3D,[ymean],[],[]);
            %set(hcont,'EdgeColor',[0.7 0.7 0.7],'LineWidth',0.5)  
            
            trackCnt        = obj.TrackCnt;
            trackPosFrame   = obj.TrackPosFrame;
            isValidTrack    = obj.TrackIsValid;
            
            % show tracks in 3D
            %cmap  = jet(trackCnt);
            hold on;
            for k = 1:trackCnt,
                if ~isValidTrack(k), continue; end;
                frameInd    = find(trackPosFrame(:,1,k) > 0);
                frameInd    = frameInd(frameInd > xmin-20 & frameInd < xmax);
                if isempty(frameInd),continue; end;
                posX        = double(trackPosFrame(frameInd,1,k));
                posY        = double(trackPosFrame(frameInd,2,k));
%                 if DoFilter,
%                     alpha = 0.1;
%                     posX  = filtfilt(alpha,[1 -(1-alpha)],posX);
%                     posY  = filtfilt(alpha,[1 -(1-alpha)],posY);
%                 end
                plot3(frameInd,posX,posY,'color','r'); 
                %text(posX(1),frameInd(1),posY(1),num2str(k),'color',cmap(k,:),'FontSize',6);
            end
            hold off;
            
            ylabel('X [pix]'),xlabel('Time [frame]'),zlabel('Y [pix]')
            %axis([1 nC zmin zmax 1 nR]), grid on;
            axis tight
            grid off
            daspect([2 1 1])

        end
        
        % ======================================
        function obj = TestTracking(obj, fname)
            % Create System objects used for reading video, detecting tracking objects,
            % and displaying the results.
            
            % init IO
            obj         = InputInit(obj, fname);
            obj         = ShowInit(obj,1);
            
            % fast forward
            cnt = 0;
            while cnt < 700, 
                videoFrame  = obj.videoReader.step();
                cnt         = cnt + 1;
            end
            
            % init Tracker
            videoFrame  = obj.videoReader.step();
            obj.VideoSize = size(videoFrame);
            obj         = InitializeDetector(obj, videoFrame);
            obj         = InitializeTracks(obj);
            
            % Detect moving objects, and track them across video frames.
            fprintf('Start Tracking ...\n')
            while ~isDone(obj.videoReader) && cnt < 800,
                
                % get frame
                frame           = obj.videoReader.step();
                cnt             = cnt + 1;
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
            obj    = ShowAverage(obj);
            %[obj,trackPos] = GetAverageTrack(obj);
            
        end
        
        
        
    end % methods
end % class


