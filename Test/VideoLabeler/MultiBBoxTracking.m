%%% Motion-Based Multiple Object BBox Tracking
% This example shows how to perform automatic detection and motion-based
% tracking of moving objects in a video from a stationary camera.
%
%   Copyright 2014 The MathWorks, Inc.

%------------------------------
% Ver   Date        Who     Descr.
%-----------------------------
% 0201  25.07.18    UD      Track Overlap resolve
% 0101  07.09.17    UD      Adopted
%------------------------------

classdef MultiBBoxTracking
    
%%%
% Detection of moving objects and motion-based tracking are important
% components of many computer vision applications, including activity
% recognition, traffic monitoring, and automotive safety.  The problem of
% motion-based object tracking can be divided into two parts:
%
% # detecting moving objects in each frame
% # associating the detections corresponding to the same object over time
%
% The detection of moving objects uses a background subtraction algorithm
% based on Gaussian mixture models. Morphological operations are applied to
% the resulting foreground mask to eliminate noise. Finally, blob analysis
% detects groups of connected pixels, which are likely to correspond to
% moving objects.
%
% The association of detections to the same object is based solely on
% motion. The motion of each track is estimated by a Kalman filter. The
% filter is used to predict the track's location in each frame, and
% determine the likelihood of each detection being assigned to each
% track.
%
% Track maintenance becomes an important aspect of this example. In any
% given frame, some detections may be assigned to tracks, while other
% detections and tracks may remain unassigned.The assigned tracks are
% updated using the corresponding detections. The unassigned tracks are
% marked invisible. An unassigned detection begins a new track.
%
% Each track keeps count of the number of consecutive frames, where it
% remained unassigned. If the count exceeds a specified threshold, the
% example assumes that the object left the field of view and it deletes the
% track.
%
% This example is a function with the main body at the top and helper
% routines in the form of
% <matlab:helpview(fullfile(docroot,'toolbox','matlab','matlab_prog','matlab_prog.map'),'nested_functions') nested functions>
% below.
    
    properties
        
        % Track management
        tracks              % array of kalman trackers
        Assignments         % data to track assignments
        UnassignedTracks
        UnassignedDetections
        OverlappingTracks   % track indices that overlap by others
        ReliableTrackInds   = [];  % reliable indices
        PredictedTrackInds  = [];
        
        % kalman params
        InitialEstimateError  = [10 1];   % pix
        MotionNoise           = [.1 .01];   % pix^2/T
        MeasurementNoise      = 20;         % pix^2

        
        % data Management
        %Centroids           % data point coordinates
        BBoxes              % bounding box for data
        NextId              = 1; % ID of the next track
        
        % Controls
        VisibilityThr       = 0.6;  % percent of time track is visible relative to its age
        MinVisibleCount     = 4;    % reliable trackers
        InvisibleForTooLong = 10;   % number of last frames that tracker disappeared
        AgeThreshold        = 8;    % must be old enough
        CostOfNonAssignment = 50;   % must be compatible with noise model
        
    end
    
    % Main Functions
    methods
        
        % ======================================
        function obj = MultiBBoxTracking()
            % Constructor
            obj = InitializeTracks(obj);
        end
        
        % ======================================
        %%% Initialize Tracks
        function obj = InitializeTracks(obj)        
        % The |initializeTracks| function creates an array of tracks, where each
        % track is a structure representing a moving object in the video. The
        % purpose of the structure is to maintain the state of a tracked object.
        % The state consists of information used for detection to track assignment,
        % track termination, and display.
        %
        % The structure contains the following fields:
        %
        % * |id| :                  the integer ID of the track
        % * |bbox| :                the current bounding box of the object; used
        %                           for display
        % * |kalmanFilter| :        a Kalman filter object used for motion-based
        %                           tracking
        % * |age| :                 the number of frames since the track was first
        %                           detected
        % * |totalVisibleCount| :   the total number of frames in which the track
        %                           was detected (visible)
        % * |consecutiveInvisibleCount| : the number of consecutive frames for
        %                                  which the track was not detected (invisible).
        %
        % Noisy detections tend to result in short-lived tracks. For this reason,
        % the example only displays an object after it was tracked for some number
        % of frames. This happens when |totalVisibleCount| exceeds a specified
        % threshold.
        %
        % When no detections are associated with a track for several consecutive
        % frames, the example assumes that the object has left the field of view
        % and deletes the track. This happens when |consecutiveInvisibleCount|
        % exceeds a specified threshold. A track may also get deleted as noise if
        % it was tracked for a short time, and marked invisible for most of the of
        % the frames.
        

            % create an empty array of tracks
            obj.tracks = struct(...
                'id', {}, ...
                'bbox', {}, ...
                'kalmanFilter', {}, ...
                'age', {}, ...
                'totalVisibleCount', {}, ...
                'consecutiveInvisibleCount', {});
        end
        
        % ======================================
        %%% Predict New Locations of Existing Tracks
        function obj = PredictNewLocationsOfTracks(obj)
        % Use the Kalman filter to predict the centroid of each track in the
        % current frame, and update its bounding box accordingly.
            
            for i = 1:length(obj.tracks)
                %bbox                = obj.tracks(i).bbox;
                
                % Predict the current location of the track.
                predictedBbox       = predict(obj.tracks(i).kalmanFilter);
                
                % Shift the bounding box so that its center is at
                % the predicted location.
                %predictedBbox       = predictedBbox - bbox;
                predictedBbox(3:4)  = max(1,predictedBbox(3:4)); % size must be positive
                obj.tracks(i).bbox  = predictedBbox;
            end
        end
                
        % ======================================
        %%% Assign Detections to Tracks
        function obj = DetectionToTrackAssignment(obj,bboxes)        
        % Assigning object detections in the current frame to existing tracks is
        % done by minimizing cost. The cost is defined as the negative
        % log-likelihood of a detection corresponding to a track.
        %
        % The algorithm involves two steps:
        %
        % Step 1: Compute the cost of assigning every detection to each track using
        % the |distance| method of the |vision.KalmanFilter| System object(TM). The
        % cost takes into account the Euclidean distance between the predicted
        % centroid of the track and the centroid of the detection. It also includes
        % the confidence of the prediction, which is maintained by the Kalman
        % filter. The results are stored in an MxN matrix, where M is the number of
        % tracks, and N is the number of detections.
        %
        % Step 2: Solve the assignment problem represented by the cost matrix using
        % the |assignDetectionsToTracks| function. The function takes the cost
        % matrix and the cost of not assigning any detections to a track.
        %
        % The value for the cost of not assigning a detection to a track depends on
        % the range of values returned by the |distance| method of the
        % |vision.KalmanFilter|. This value must be tuned experimentally. Setting
        % it too low increases the likelihood of creating a new track, and may
        % result in track fragmentation. Setting it too high may result in a single
        % track corresponding to a series of separate moving objects.
        %
        % The |assignDetectionsToTracks| function uses the Munkres' version of the
        % Hungarian algorithm to compute an assignment which minimizes the total
        % cost. It returns an M x 2 matrix containing the corresponding indices of
        % assigned tracks and detections in its two columns. It also returns the
        % indices of tracks and detections that remained unassigned.
        
   
            
            if nargin < 2, bboxes    = [1 1 2 2] ; end
            
            nTracks                 = length(obj.tracks);
            nDetections             = size(bboxes, 1);
            costOfNonAssignment     = obj.CostOfNonAssignment;
            
            
            % Compute the cost of assigning each detection to each track.
            cost = zeros(nTracks, nDetections);
            for i = 1:nTracks
                cost(i, :) = distance(obj.tracks(i).kalmanFilter, bboxes);
            end
            
            % Solve the assignment problem.
            [assignments, unassignedTracks, unassignedDetections] = ...
                assignDetectionsToTracks(cost, costOfNonAssignment);
            
            % save
            obj.Assignments             = assignments;
            obj.UnassignedTracks        = unassignedTracks;
            obj.UnassignedDetections    = unassignedDetections;
            
            % CHECK
            %obj.Centroids               = centroids;
            obj.BBoxes                  = bboxes;
        end
        
        % ======================================
        %%% Detect Overlapping Tracks
        function obj = DetectOverlappingTracks(obj)
        % The |DetectOverlappingTracks| function detects tracks that have been overlapping each other 
        % for a long time.
        
            nTracks                 = length(obj.tracks);
            if nTracks < 2,  return;  end
            
            costOfNonAssignment     = obj.CostOfNonAssignment/2;
            bboxes                  = vertcat(obj.tracks(:).bbox);
            ages                    = horzcat(obj.tracks(:).age);
           
            
            % Compute the cost of assigning each detection to each track.
           costBox = zeros(nTracks, nTracks);
           costAge = zeros(nTracks, nTracks);
            for i = 1:nTracks
                costBox(i, :) = distance(obj.tracks(i).kalmanFilter, bboxes);
                costAge(i, :) = obj.tracks(i).age - ages;
            end
            % resolve self assignment + small bias
            costSelf    = diag(costBox) + costOfNonAssignment/100;
            costBox     = costBox + eye(nTracks)*costOfNonAssignment;
            
            % Which tracks overlaps with which
            overlappingTracks    = costBox < costSelf*1.1;    
            
            % Use tracks that are older - resolve ties arbitrary
            zeroDiff             = triu(abs(costAge) < 1e-6);
            yangTracks           = costAge < -0.1 | zeroDiff; % 
            
            % tracks
            [surviveInd,deadInd] = find(overlappingTracks & yangTracks);
            
            % save
            obj.OverlappingTracks  = deadInd;
            
        end
        
        
        
        % ======================================
        %%% Update Assigned Tracks
        function obj = UpdateAssignedTracks(obj)        
        % The |updateAssignedTracks| function updates each assigned track with the
        % corresponding detection. It calls the |correct| method of
        % |vision.KalmanFilter| to correct the location estimate. Next, it stores
        % the new bounding box, and increases the age of the track and the total
        % visible count by 1. Finally, the function sets the invisible count to 0.
        
            
            assignments         = obj.Assignments;
            %centroids           = obj.Centroids;
            bboxes              = obj.BBoxes;
            
            numAssignedTracks = size(assignments, 1);
            for i = 1:numAssignedTracks
                trackIdx        = assignments(i, 1);
                detectionIdx    = assignments(i, 2);
                %centroid        = centroids(detectionIdx, :);
                bbox            = bboxes(detectionIdx, :);
                
                % Correct the estimate of the object's location
                % using the new detection.
                trackBox        = correct(obj.tracks(trackIdx).kalmanFilter, bbox);
                
                % Replace predicted bounding box with detected
                % bounding box.
                obj.tracks(trackIdx).bbox = trackBox;
                
                % Update track's age.
                obj.tracks(trackIdx).age = obj.tracks(trackIdx).age + 1;
                
                % Update visibility.
                obj.tracks(trackIdx).totalVisibleCount = obj.tracks(trackIdx).totalVisibleCount + 1;
                obj.tracks(trackIdx).consecutiveInvisibleCount = 0;
            end
        end
        
        % ======================================
        %%% Update Overlapping Tracks
        function obj = UpdateOverlappingTracks(obj)
        % Mark each Overlapping track has no assignment - just add them to this list.
            
            obj.UnassignedTracks      = cat(1,obj.UnassignedTracks,obj.OverlappingTracks);
            
        end
        
        
        
        % ======================================
        %%% Update Unassigned Tracks
        function obj = UpdateUnassignedTracks(obj)
        % Mark each unassigned track as invisible, and increase its age by 1.
            
            unassignedTracks         = obj.UnassignedTracks;
            for i = 1:length(unassignedTracks)
                ind                 = unassignedTracks(i);
                obj.tracks(ind).age = obj.tracks(ind).age + 1;
                obj.tracks(ind).consecutiveInvisibleCount = obj.tracks(ind).consecutiveInvisibleCount + 1;
            end
        end
        
        
        % ======================================
        %%% Create New Tracks
        function obj = CreateNewTracks(obj)
        % Create new tracks from unassigned detections. Assume that any unassigned
        % detection is a start of a new track. In practice, you can use other cues
        % to eliminate noisy detections, such as size, location, or appearance.
        

            
            unassignedDetections    = obj.UnassignedDetections;
            %centroids               = obj.Centroids(unassignedDetections, :);
            bboxes                  = obj.BBoxes(unassignedDetections, :);
            nextId                  = obj.NextId;
            
            for i = 1:size(bboxes, 1)
                
                %centroid = centroids(i,:);
                bbox     = bboxes(i, :);
                
                % Create a Kalman filter object.
                kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
                    bbox, obj.InitialEstimateError, obj.MotionNoise, obj.MeasurementNoise);
                
                % Create a new track.
                newTrack = struct(...
                    'id', nextId, ...
                    'bbox', bbox, ...
                    'kalmanFilter', kalmanFilter, ...
                    'age', 1, ...
                    'totalVisibleCount', 1, ...
                    'consecutiveInvisibleCount', 0);
                
                % Add it to the array of tracks.
                obj.tracks(end + 1) = newTrack;
                
                % Increment the next id.
                nextId = nextId + 1;
            end
            
            obj.NextId = nextId;
                        
        end
        
        % ======================================
        %%% Delete Lost Tracks
        function obj = DeleteLostTracks(obj)
        % The |deleteLostTracks| function deletes tracks that have been invisible
        % for too many consecutive frames. It also deletes recently created tracks
        % that have been invisible for too many frames overall.
        
 
            if isempty(obj.tracks)
                return;
            end
            
    %         VisibilityThr       = 0.6;  % percent of time track is visible relative to its age
    %         MinVisibleCount     = 8;    % reliable trackers
    %         InvisibleForTooLong = 20;   % number of last frames that tracker disappeared
    %         AgeThreshold        = 8;    % must be old enough
            
            
            invisibleForTooLong = obj.InvisibleForTooLong;
            ageThreshold        = obj.AgeThreshold;
            visibilityThr       = obj.VisibilityThr;
            minVisibleCount     = obj.MinVisibleCount;
            
            % Compute the fraction of the track's age for which it was visible.
            ages                = [obj.tracks(:).age];
            totalVisibleCounts  = [obj.tracks(:).totalVisibleCount];
            visibility          = totalVisibleCounts ./ ages;
            totalInvisibleCount = [obj.tracks(:).consecutiveInvisibleCount];
            
            %reliableTrackInds   = totalVisibleCounts > obj.MinVisibleCount;
            
            % Find the indices of 'lost' tracks.
            lostInds            = (ages < ageThreshold & visibility < visibilityThr);
            lostInds            = lostInds | (totalInvisibleCount >= invisibleForTooLong);
            
            % check reliability            
            %reliableTrackInds   = totalVisibleCounts > minVisibleCount;
            reliableTrackInds   = visibility > visibilityThr;
            %reliableTrackInds   = reliableTrackInds & (ages > ageThreshold);
            predictedTrackInds = totalInvisibleCount > 0;

            % Delete lost tracks.
            obj.tracks          = obj.tracks(~lostInds);
            
            % save reliability
            obj.ReliableTrackInds  = reliableTrackInds(~lostInds);
            obj.PredictedTrackInds = predictedTrackInds(~lostInds);
            
        end
        
        % ======================================
        %%% Export Tracks
        function [obj,bboxs,ids] = ExportTracks(obj)        
        % The |deleteLostTracks| function deletes tracks that have been invisible
        % for too many consecutive frames. It also deletes recently created tracks
        % that have been invisible for too many frames overall.

            % Export tracks
            bboxs = []; ids = [];
            if isempty(obj.tracks)
                return;
            end

            % Noisy detections tend to result in short-lived tracks.
            % Only display tracks that have been visible for more than
            % a minimum number of frames.
            reliableTrackInds   = [obj.tracks(:).totalVisibleCount] > obj.MinVisibleCount;
            reliableTracks      = obj.tracks(reliableTrackInds);

            % Display the objects. If an object has not been detected
            % in this frame, display its predicted bounding box.
            if ~isempty(reliableTracks)
                % Get bounding boxes.
                bboxs = cat(1, reliableTracks.bbox);
                ids   = find(reliableTrackInds);
            end
        end

        % ======================================
        %%% Track Tracks
        function [obj,BboxOut,IndOut] = Step(obj, Bbox)
        % Single step of tracking.
            % 
            if nargin < 2, Bbox  = [0 0 2 2] ;       end
            if nargout > 1, BboxOut  = [0 0 2 2] ;  IndOut = 1; end;
            
            obj = PredictNewLocationsOfTracks(obj);
            obj = DetectOverlappingTracks(obj);            
            obj = DetectionToTrackAssignment(obj,Bbox);
            obj = UpdateAssignedTracks(obj);
            obj = UpdateOverlappingTracks(obj);            
            obj = UpdateUnassignedTracks(obj);
            obj = CreateNewTracks(obj);
            obj = DeleteLostTracks(obj);
            [obj,BboxOut,IndOut] = ExportTracks(obj);
        end
        
    end % methods
    
    % Debug & Test
    methods
        
        % ======================================
        %%% Sim Object Tracking - simple bbox
        function obj = TestSyntheticTracking(obj, testType)        
        % This example shows how the system tracks simulated bboxes.
        if nargin < 2, testType        = 1; end
        
        % init bbox motion
        [bboxArray,nR,nC]       = CreateMotionExample(obj,testType);
        tNum                    = size(bboxArray,3);

        videoPlayer     = vision.VideoPlayer('Position', [20, 400, nC, nR]);
            
         % Detect moving objects, and track them across video frames.
         for  t = 1:tNum
                bboxes               = bboxArray(:,:,t);
                obj                  = Step(obj, bboxes);
                [obj,bboxes_f,ids_f]   = ExportTracks(obj) ;
                
                % show
                %labels_f              = cellstr(int2str(ids'));
                ids                   = find(sum(bboxes,2)> 1); % valid boxes
        
                % Draw the objects on the frame.
                frame                 = zeros(nR,nC,3,'uint8');
                if ~isempty(bboxes(ids,:))
                frame                 = insertObjectAnnotation(frame, 'rectangle', bboxes(ids,:), ids,'color','y');
                end
                if ~isempty(bboxes_f)
                frame                 = insertObjectAnnotation(frame, 'rectangle', bboxes_f, ids_f(:),'color','r');
                end
                videoPlayer.step(frame);
                
         end       
         %release(videoPlayer) ;      
        end
        
        
        % ======================================
        %%% Real Video Tracing
        function obj = TestVideoTracking(obj)        
        % This example created a motion-based system for detecting and
        % tracking multiple moving objects. Try using a different video to see if
        % you are able to detect and track objects. Try modifying the parameters
        % for the detection, assignment, and deletion steps.
        %
        % The tracking in this example was solely based on motion with the
        % assumption that all objects move in a straight line with constant speed.
        % When the motion of an object significantly deviates from this model, the
        % example may produce tracking errors. Notice the mistake in tracking the
        % person labeled #12, when he is occluded by the tree.
        %
        % The likelihood of tracking errors can be reduced by using a more complex
        % motion model, such as constant acceleration, or by using multiple Kalman
        % filters for every object. Also, you can incorporate other cues for
        % associating detections over time, such as size, shape, and color.
        
        
        % Create System objects used for reading video, detecting moving objects,
        % and displaying the results.

            objSys     = setupSystemObjects();
            
            % Detect moving objects, and track them across video frames.
            while ~isDone(objSys.reader)
                frame = objSys.reader.step();
                [centroids, bboxes, mask]   = detectObjects(objSys,frame);
                obj                        = Step(obj, bboxes);
                displayTrackingResults(objSys,obj.tracks,frame,mask);
            end
        end
        
    end % methods
    
    
end % class

% ======================================
%%% Create test boxes along with the motion
function [bboxArray,nR,nC] = CreateMotionExample(obj,testType)
% 
nR = 400; nC = 700; nT = 100;
switch testType
    case 1  % non moving box
        boxSize         = [30,40];
        bbox            = [[nC/2 - boxSize(1)/2, nR/2 - boxSize(2)/2] boxSize];
        bboxArray       = repmat(bbox,1,1,nT);

    case 2 % moving box
        boxSize         = [30,40];
        bbox            = [[nC/2 - boxSize(1)/2, nR/2 - boxSize(2)/2] boxSize];
        bboxArray       = repmat(bbox,1,1,nT);
        bboxArray(1,1,:) = linspace(1/4*nC,3/4*nC,nT);
        
    case 3 % moving box with missing frames
        boxSize         = [30,40];
        bbox            = [[nC/2 - boxSize(1)/2, nR/2 - boxSize(2)/2] boxSize];
        bboxArray       = repmat(bbox,1,1,nT);
        bboxArray(1,1,:) = linspace(1/4*nC,3/4*nC,nT);
        bboxArray(:,:,50:55) = 0;

    case 4 % moving box with many missing frames - new track formation
        boxSize         = [30,40];
        bbox            = [[nC/2 - boxSize(1)/2, nR/2 - boxSize(2)/2] boxSize];
        bboxArray       = repmat(bbox,1,1,nT);
        bboxArray(1,1,:) = linspace(1/4*nC,3/4*nC,nT);
        bboxArray(:,:,30:45) = 0;

    case 5 % moving box with size increase
        boxSize         = [30,40];
        bbox            = [[nC/2 - boxSize(1)/2, nR/2 - boxSize(2)/2] boxSize];
        bboxArray       = repmat(bbox,1,1,nT);
        bboxArray(1,1,:) = linspace(1/4*nC,3/4*nC,nT);
        bboxArray(1,4,:) = linspace(1/2*boxSize(2),3/2*boxSize(2),nT);
        
        
    case 11 % 2 moving box 
        boxSize         = [30,40];
        bbox            = [[nC/2 - boxSize(1)/2, nR/2 - boxSize(2)/2] boxSize];
        bboxArray       = repmat(bbox,2,1,nT);
        bboxArray(1,1,:) = linspace(1/4*nC,3/4*nC,nT);
        bboxArray(2,2,:) = linspace(1/4*nR,3/4*nR,nT);
        
        
    case 12 % 2 overlapping boxes equal size
        boxSize         = [30,40];
        bbox            = [[nC/2 - boxSize(1)/2, nR/2 - boxSize(2)/2] boxSize];
        bboxArray       = repmat(bbox,2,1,nT);
        bboxArray(1,1,1:nT/2) = linspace(1/4*nC,1/2*nC,nT/2);
        bboxArray(2,1,1:nT/2) = linspace(3/4*nC,1/2*nC,nT/2);
      
   case 13 % 2 overlapping boxes non equal size
        boxSize         = [30,40];
        bbox1           = [[nC/2 - boxSize(1)/2, nR/2 - boxSize(2)/2] boxSize];
        boxSize         = [50,60];
        bbox2           = [[nC/2 - boxSize(1)/2, nR/2 - boxSize(2)/2] boxSize];
        bboxArray       = repmat([bbox1;bbox2],1,1,nT);
        bboxArray(1,1,1:nT/2) = linspace(1/4*nC,1/2*nC,nT/2);
        bboxArray(2,1,1:nT/2) = linspace(3/4*nC,1/2*nC,nT/2);
        
        
    otherwise
        error('Bad testType')
end
bboxArray = round(bboxArray);

end


% ======================================
%%% Create System Objects
function objSys = setupSystemObjects()
% Create System objects used for reading the video frames, detecting
% foreground objects, and displaying results.

% Initialize Video I/O
% Create objects for reading a video from a file, drawing the tracked
% objects in each frame, and playing the video.

% Create a video file reader.
objSys.reader = vision.VideoFileReader('visiontraffic.avi');

% Create two video players, one to display the video,
% and one to display the foreground mask.
objSys.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
objSys.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]);

% Create System objects for foreground detection and blob analysis

% The foreground detector is used to segment moving objects from
% the background. It outputs a binary mask, where the pixel value
% of 1 corresponds to the foreground and the value of 0 corresponds
% to the background.

objSys.detector = vision.ForegroundDetector('NumGaussians', 3, ...
    'NumTrainingFrames', 40, 'MinimumBackgroundRatio', 0.7);

% Connected groups of foreground pixels are likely to correspond to moving
% objects.  The blob analysis System object is used to find such groups
% (called 'blobs' or 'connected components'), and compute their
% characteristics, such as area, centroid, and the bounding box.

objSys.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', true, 'CentroidOutputPort', true, ...
    'MinimumBlobArea', 400);
end

% ======================================
%%% Detect Objects
function [centroids, bboxes, mask] = detectObjects(objSys,frame)
% The |detectObjects| function returns the centroids and the bounding boxes
% of the detected objects. It also returns the binary mask, which has the
% same size as the input frame. Pixels with a value of 1 correspond to the
% foreground, and pixels with a value of 0 correspond to the background.
%
% The function performs motion segmentation using the foreground detector.
% It then performs morphological operations on the resulting binary mask to
% remove noisy pixels and to fill the holes in the remaining blobs.

% Detect foreground.
mask = objSys.detector.step(frame);

% Apply morphological operations to remove noise and fill in holes.
mask = imopen(mask, strel('rectangle', [3,3]));
mask = imclose(mask, strel('rectangle', [15, 15]));
mask = imfill(mask, 'holes');

% Perform blob analysis to find connected components.
[~, centroids, bboxes] = objSys.blobAnalyser.step(mask);
end

% ======================================
%%% Display Tracking Results
function displayTrackingResults(objSys,tracks,frame,mask)
% The |displayTrackingResults| function draws a bounding box and label ID
% for each track on the video frame and the foreground mask. It then
% displays the frame and the mask in their respective video players.

% Convert the frame and the mask to uint8 RGB.
frame = im2uint8(frame);
mask = uint8(repmat(mask, [1, 1, 3])) .* 255;

minVisibleCount = 8;
if ~isempty(tracks)
    
    % Noisy detections tend to result in short-lived tracks.
    % Only display tracks that have been visible for more than
    % a minimum number of frames.
    reliableTrackInds = ...
        [tracks(:).totalVisibleCount] > minVisibleCount;
    reliableTracks = tracks(reliableTrackInds);
    
    % Display the objects. If an object has not been detected
    % in this frame, display its predicted bounding box.
    if ~isempty(reliableTracks)
        % Get bounding boxes.
        bboxes = cat(1, reliableTracks.bbox);
        
        % Get ids.
        ids = int32([reliableTracks(:).id]);
        
        % Create labels for objects indicating the ones for
        % which we display the predicted rather than the actual
        % location.
        labels = cellstr(int2str(ids'));
        predictedTrackInds = ...
            [reliableTracks(:).consecutiveInvisibleCount] > 0;
        isPredicted = cell(size(labels));
        isPredicted(predictedTrackInds) = {' predicted'};
        labels = strcat(labels, isPredicted);
        
        % Draw the objects on the frame.
        frame = insertObjectAnnotation(frame, 'rectangle', ...
            bboxes, labels);
        
        % Draw the objects on the mask.
        mask = insertObjectAnnotation(mask, 'rectangle', ...
            bboxes, labels);
    end
end

% Display the mask and the frame.
objSys.maskPlayer.step(mask);
objSys.videoPlayer.step(frame);
end

