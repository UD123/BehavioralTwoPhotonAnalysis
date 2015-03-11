%%% Optical Flow Point Tracker
%-----------------------------------------------------
% Ver       Date        Who     What
%-----------------------------------------------------
% 0403      10.02.15    UD      Updating
% 0402      05.02.15    UD      Video management + Backgr Segment
% 0401      05.02.15    UD      KLT point tracker.
%-----------------------------------------------------

%%%
% Params
%%%
testType            = 32;
proxNewThr          = 5^2*2;          % prune the new points that are too close
proxDensThr         = proxNewThr/4;   % prune the valid points that are too close
posStdThr           = 10;              % trajectory movement std 
trackMinLength      = 5;               % trajectory min length in frames
figNum              = 1;


%%%
% Data setup
%%%
doLoad  = true;
if exist('testTypePrev','var'), doLoad = testTypePrev ~= testType; end
if doLoad,

clear bbox;
switch testType,
    case 1, % 
    % Read a video frame and run the face detector.
    fileDirName     = 'tilted_face.avi';
    %videoFileReader = vision.VideoFileReader(fileDirName);
    readerobj       = VideoReader(fileDirName);
    imgD            = read(readerobj);

    bbox            = [200 100 200 100];
    
    case 11, % side video
    fileDirName     = 'C:\Uri\DataJ\Janelia\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_014.avi';
    %videoFileReader = vision.VideoFileReader('');
    readerobj       = VideoReader(fileDirName);
    imgD            = read(readerobj);
    
    bbox            = [1 1 200 200];
    
    case 15, % side video -- too long
    fileDirName     = 'C:\Uri\DataJ\Janelia\Videos\m76\10_01_14\Basler_side_10_01_2014_m76_2.avi';
    %videoFileReader = vision.VideoFileReader('');
    readerobj       = VideoReader(fileDirName);
    imgD            = read(readerobj);
    imgD            = imresize(imgD,0.5);
    
    %bbox            = [1 1 200 200];
    case 16, % side video 
    fileDirName     = 'C:\Uri\DataJ\Janelia\Videos\M75\2_21_14\Basler_side_21_02_2014_m75_8.avi';
    %videoFileReader = vision.VideoFileReader('');
    readerobj       = VideoReader(fileDirName);
    imgD            = read(readerobj);
    imgD            = imresize(imgD,0.5);
    
    

    
    case 21, % combine version
    fileDirName     = 'C:\Uri\DataJ\Janelia\Videos\d13\15_08_14\Basler_15_08_2014_arch5_003\movie_comb.avi';
    %videoFileReader = vision.VideoFileReader('');
    readerobj       = VideoReader(fileDirName);
    imgD            = read(readerobj);
    %imgD            = imgD(:,1:500,:,:);
    imgD            = imresize(imgD,0.5);
    
    case 31, % Lab
        
    fileDirName     = 'C:\LabUsers\Uri\Data\Janelia\Videos\M75\2_21_14\Basler_side_21_02_2014_m75_011.avi';
    %videoFileReader = vision.VideoFileReader('');
    readerobj       = VideoReader(fileDirName);
    imgD            = read(readerobj);
    %imgD            = imgD(:,1:500,:,:);
    imgD            = imresize(imgD,0.5);

    case 32, % Lab - whisker front
        
    fileDirName     = 'C:\LabUsers\Uri\Data\Janelia\Videos\M75\2_21_14\Basler_front_21_02_2014_m75_035.avi';
    %videoFileReader = vision.VideoFileReader('');
    readerobj       = VideoReader(fileDirName);
    imgD            = read(readerobj);
    %imgD            = imgD(:,1:500,:,:);
    %imgD            = imresize(imgD,0.5);

    
end
testTypePrev = testType;
end
[nR,nC,nD,nT]      = size(imgD);
videoFrame         = imgD(:,:,:,1);

%bbox            = step(faceDetector, videoFrame);

% % Draw the returned bounding box around the detected face.
% videoFrame      = insertShape(videoFrame, 'Rectangle', bbox);
% figure; imshow(videoFrame); title('Detected face');

% Convert the first box into a list of 4 points
% This is needed to be able to visualize the rotation of the object.
%bboxPoints = bbox2points(bbox(1, :));

%%%
% To track the points over time, this example uses the Kanade-Lucas-Tomasi
% (KLT) algorithm. While it is possible to use the cascade object detector
% on every frame, it is computationally expensive. It may also fail to
% detect the face, when the subject turns or tilts his head. This
% limitation comes from the type of trained classification model used for
% detection. The example detects the face only once, and then the KLT
% algorithm tracks the face across the video frames. 

%%% Identify  Features To Track
% The KLT algorithm tracks a set of feature points across the video frames.
% Once the detection locates the face, the next step in the example
% identifies feature points that can be reliably tracked.  This example
% uses the standard, "good features to track" proposed by Shi and Tomasi. 

% Detect feature points in the face region.
if ~exist('bbox','var')
bbox   = [1 1 size(videoFrame,2) size(videoFrame,1)];
end
%bbox   = [200 100 200 100];
videoFrameG = videoFrame;
if nD > 1, videoFrameG = rgb2gray(videoFrame); end;
points = detectMinEigenFeatures(videoFrameG, 'ROI', bbox);

% Display the detected points.
figure, imshow(videoFrame), hold on, title('Detected features');
plot(points); hold off;

%%% Initialize a Tracker to Track the Points
% With the feature points identified, you can now use the
% |vision.PointTracker| System object to track them. For each point in the
% previous frame, the point tracker attempts to find the corresponding
% point in the current frame. Then the |estimateGeometricTransform|
% function is used to estimate the translation, rotation, and scale between
% the old points and the new points. This transformation is applied to the
% bounding box around the face.

% Create a point tracker and enable the bidirectional error constraint to
% make it more robust in the presence of noise and clutter.
pointTracker = vision.PointTracker('MaxBidirectionalError', 2);

% Initialize the tracker with the initial point locations and the initial
% video frame.
points = points.Location;
initialize(pointTracker, points, videoFrame);

%%% Initialize a Video Player to Display the Results
% Create a video player object for displaying video frames.
% videoPlayer  = vision.VideoPlayer('Position',...
%     [100 100 [size(videoFrame, 2), size(videoFrame, 1)]+30]);

%%% Track Init
% Track the points from frame to frame, and use
% initialize tracker structure to to hold the results
trackCnt            = size(points,1);
trackStr{1}.Ids     = (1:trackCnt)';
trackStr{1}.Pos     = points;
trackIds            = trackStr{1}.Ids;
trackAge            = trackStr{1}.Ids*0 + 1;


% Make a copy of the points to be used for computing the geometric
% transformation between the points in the previous and the current frames
oldPoints = points;
frameCnt  = 1;
imgRGB    = repmat(imgD(:,:,1,1),[1 1 3 nT]);
fprintf('I : Tracking ...')
while frameCnt <= nT, %~isDone(videoFileReader)
    % get the next frame
    %videoFrame          = step(videoFileReader);
    videoFrame          = imgD(:,:,:,frameCnt);

    % Track the points. Note that some points may be lost.
    [points, isFound, scores]   = step(pointTracker, videoFrame);
    visiblePoints       = points(isFound, :);
    scores              = scores(isFound, :);
    oldInliers          = oldPoints(isFound, :);
    lostPoints          = oldPoints(~isFound, :);
    visiblePointsNum    = size(visiblePoints,1);
    visibleTrackIds     = trackIds(isFound);
    visibleTrackAge     = trackAge(isFound) + 1;
    
    % Init new points
    videoFrameG         = videoFrame;
    if nD > 1, videoFrameG = rgb2gray(videoFrame); end;
    newPoints           = detectMinEigenFeatures(videoFrameG, 'ROI', bbox);
    newPoints           = newPoints.Location;
    
    % Prune the old visible
    distD               = bsxfun(@minus,visiblePoints(:,1),newPoints(:,1)').^2 + bsxfun(@minus,visiblePoints(:,2),newPoints(:,2)').^2;
    [minV,minI]         = min(distD);
    newPointsBool       = minV > proxNewThr;
    newPoints           = newPoints(newPointsBool,:);
    newPointNum         = size(newPoints,1);
    newTrackIds         = trackCnt  + (1:newPointNum)';
    newTrackAge         = ones(newPointNum,1);
    
    
    % Prune the closest visible
    distD               = bsxfun(@minus,visiblePoints(:,1),visiblePoints(:,1)').^2 + bsxfun(@minus,visiblePoints(:,2),visiblePoints(:,2)').^2;
    [minV,minI]         = min(distD + eye(visiblePointsNum)*1000);
    prunePointsBool     = minV < proxDensThr & ((1:visiblePointsNum) ~= minI); % not equal to them selves
    prunePoints         = visiblePoints(prunePointsBool,:);
    visiblePoints       = visiblePoints(~prunePointsBool,:);
    visibleTrackIds     = visibleTrackIds(~prunePointsBool);
    visibleTrackAge     = visibleTrackAge(~prunePointsBool);
    
   
    % manage trackers - save the info
    frameCnt            = frameCnt + 1;
    trackCnt            = trackCnt + newPointNum;
    trackIds            = [visibleTrackIds;newTrackIds];
    trackAge            = [visibleTrackAge;newTrackAge];
    oldPoints           = [visiblePoints;newPoints];
    
    trackStr{frameCnt}.Ids     = trackIds;     
    trackStr{frameCnt}.Pos     = oldPoints;

    
    % Display tracked points
    videoFrame = insertMarker(videoFrame, visiblePoints, '+', ...
        'Color', 'white');       
    % Display new points
    videoFrame = insertMarker(videoFrame, newPoints, 's', ...
        'Color', 'green');       
    % Display lost points
    videoFrame = insertMarker(videoFrame, lostPoints, 'o', ...
        'Color', 'c');       
    % Display points that are too close - -to be pruned
    videoFrame = insertMarker(videoFrame, prunePoints, 'x', ...
        'Color', 'red');       

    % show text Draw the objects on the frame.
    pointsNum           = size(oldPoints,1);
    ids                 = (1:17:pointsNum);
    labels              = cellstr(int2str(trackIds(ids)));
    circPos             = [oldPoints(ids,:) ones(numel(ids),1,'single')*2];
    videoFrame          = insertObjectAnnotation(videoFrame, 'circle', circPos, labels,'color','y','TextBoxOpacity',0.2);


    % Reset the points
    setPoints(pointTracker, oldPoints);        
    
    % Display the annotated video frame using the video player object
    %step(videoPlayer, videoFrame);
    imgRGB(:,:,:,frameCnt) = videoFrame;
    
    % show progress
    if rem(frameCnt,100) < 1, fprintf('.'); end;
end
fprintf('Done\n')
% Clean up
%release(videoFileReader);
%release(videoPlayer);
release(pointTracker);
implay(imgRGB);


%%%
% Track Linkage
%%%
trackPosFrame = zeros(frameCnt,2,trackCnt,'single');
for m = 1:frameCnt,
    ids = trackStr{m}.Ids;
    pos = trackStr{m}.Pos;
    
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
for k = 1:trackCnt,
    ii          = trackPosFrame(:,1,k) > 0;
%     posMax      = squeeze(max(trackPosFrame(ii,:,k),[],1));
%     posMin      = squeeze(min(trackPosFrame(ii,:,k),[],1));
%     isMoving(k) = sum(posMax - posMin) > posStdThr;
    
    posStd      = squeeze(std(trackPosFrame(ii,:,k),[],1));
    isMoving(k) = (posStd(1) + posStd(2)) > posStdThr;
    isLong(k)   = numel(ii) > trackMinLength;
end
% remove all
%trackPosFrame = trackPosFrame(:,:,isMoving & isLong);
isValidTrack   = isMoving' & isLong';


%%%
% Create movie with trackers
%%%
%fileDirName     = videoFileReader.Filename;
%readerobj       = VideoReader(fileDirName);
imgRGB          = repmat(imgD(:,:,1,1),[1 1 3 nT]);
%imgRGB          = imgD;
idsForShow        = (1:5:trackCnt);  % prune for show

for n = 1:nT,
    
    % get
    videoFrame          = imgD(:,:,:,n);
    
    % get the trackers
    validBool           = squeeze(trackPosFrame(n,1,:)) > 0 & isValidTrack;
    validIds            = find(validBool);
    %validIds            = intersect(validIds,idsForShow);
    
    % show text Draw the objects on the frame.
    trackNum           = length(validIds);
    labels              = cellstr(int2str(validIds));
    xpos                = trackPosFrame(n,1,validIds);
    ypos                = trackPosFrame(n,2,validIds);
    circPos             = [xpos(:) ypos(:) ones(trackNum,1,'single')*2];
    videoFrame          = insertMarker(videoFrame, circPos(:,1:2), '+', 'Color', 'g');       
    [~,vIds ]           = intersect(validIds,idsForShow);
    videoFrame          = insertObjectAnnotation(videoFrame, 'circle', circPos(vIds,:), labels(vIds),'color','y','TextBoxOpacity',0.2);

    % save
    imgRGB(:,:,:,n) = videoFrame;
    
end
% show
implay(imgRGB)

% show tracks in 3D
figure(figNum)
cmap  = jet(trackCnt);
for k = 1:trackCnt,
    if ~isValidTrack(k), continue; end;
    frameInd     = find(trackPosFrame(:,1,k) > 0);
    posX        = trackPosFrame(frameInd,1,k);
    posY        = trackPosFrame(frameInd,2,k);
    plot3(posX,frameInd,posY,'color',cmap(k,:)); hold on;
    text(posX(1),frameInd(1),posY(1),num2str(k),'color',cmap(k,:),'FontSize',6);
end
hold off;
set(gca,'zdir','reverse'); % like in image
xlabel('X [pix]'),ylabel('Time [frame]'),zlabel('Y [pix]')
axis([1 nC 1 nT 1 nR]), grid on;
title('Track Trajectories')



return


%%% References
%
% Viola, Paul A. and Jones, Michael J. "Rapid Object Detection using a
% Boosted Cascade of Simple Features", IEEE CVPR, 2001.
%
% Bruce D. Lucas and Takeo Kanade. An Iterative Image Registration 
% Technique with an Application to Stereo Vision. 
% International Joint Conference on Artificial Intelligence, 1981.
%
% Carlo Tomasi and Takeo Kanade. Detection and Tracking of Point Features. 
% Carnegie Mellon University Technical Report CMU-CS-91-132, 1991.
%
% Jianbo Shi and Carlo Tomasi. Good Features to Track. 
% IEEE Conference on Computer Vision and Pattern Recognition, 1994.
%
% Zdenek Kalal, Krystian Mikolajczyk and Jiri Matas. Forward-Backward
% Error: Automatic Detection of Tracking Failures.
% International Conference on Pattern Recognition, 2010

