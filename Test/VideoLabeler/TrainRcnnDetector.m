%% Train R-CNN Detector
% 
%------------------------------
% Ver   Date        Who     Descr.
%-----------------------------
% 0205  11.04.18    UD  	Increasing learning size. rename rcnn to net
% 0204  05.04.18    UD      testing the old code
% 0203  12.09.17    UD      adding trackers
% 0101  05.08.17    UD      Created
%------------------------------

%%
% Load training data and network layers.
load('rcnnStopSigns.mat','cifar10Net')  
%saveFile = 'C:\ABH\data\Detection\SessionFlowers_LabelData.mat';
% dora data
saveFile = '\\192.114.20.50\g\Amir\Video\DT73\Saline\2018-07-25\ROI30_F_LabelData.mat';
load(saveFile,'labelData')  

%%   
% 
% Display one training image and the ground truth bounding boxes
t = randi(height(labelData));
I = imread(labelData.imageFileName{t});
%I = insertObjectAnnotation(I, 'Rectangle', labelData.hf{t,:}, 'Hand', 'LineWidth', 4);
I = insertObjectAnnotation(I, 'Rectangle', labelData.handS{t,:}, 'Hand', 'LineWidth', 4);

figure
imshow(I)
title(labelData.imageFileName{t},'interpreter','none')

%% Option1
% % Set network training options to use mini-batch size of 32 to reduce GPU
% % memory usage. Lower the InitialLearningRate to reduce the rate at which
% % network parameters are changed. This is beneficial when fine-tuning a
% % pre-trained network and prevents the network from changing too rapidly. 
% options = trainingOptions('sgdm', ...
%   'MiniBatchSize', 32, ...
%   'InitialLearnRate', 1e-6, ...
%   'MaxEpochs', 10);
% 
% % Train the R-CNN detector. Training can take a few minutes to complete.
% rcnn = trainRCNNObjectDetector(stopSigns, layers, options, 'NegativeOverlapRange', [0 0.3]);

% 
%% split the data size
trainSetInd          = rand(height(labelData),1) > 0.4;
trainSet             = labelData(trainSetInd,:);
testSet              = labelData(~trainSetInd,:);



%% Option 2 : Train R-CNN  Detector

% increase input
%cifar10Net.Layers(1).InputSize = [48 48 1];

% Set training options
options = trainingOptions('sgdm', ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-3, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.1, ...
    'LearnRateDropPeriod', 100, ...
    'MaxEpochs', 50, ...
    'Verbose', true);

% Train an R-CNN object detector. This will take several minutes.    
net = trainRCNNObjectDetector(trainSet, cifar10Net, options); %, ...
%net = trainFasterRCNNObjectDetector(trainSet, cifar10Net, options); %, ...
%'NegativeOverlapRange', [0 0.3], 'PositiveOverlapRange',[0.5 1])

[p,f,e] = fileparts(saveFile);
netFile = fullfile(p,[f,'_Detector2',e]);
save(netFile,'labelData','net')  
%save(saveFile,'labelData','net')  


%%
% Test the R-CNN detector on a test image.
saveFile = '\\192.114.20.50\g\Amir\Video\DT73\CNO\2018-07-23\ROI23f_LabelData_D101_N23.mat';
load(saveFile,'net');

t           = randi(height(testSet));
img         = imread(testSet.imageFileName{t}); 
tic
[bbox, score, label] = detect(net, img, 'MiniBatchSize', 32);
toc
% Display strongest detection result.
%[score, idx] = max(score);
%bbox        = bbox(idx, :);
detectedImg = img;
for idx = 1:length(score)
    annotation  = sprintf('%s: (C = %4.3f)', label(idx), score(idx));  
    detectedImg = insertObjectAnnotation(detectedImg, 'rectangle', bbox(idx,:), annotation,'Color','r');
end
detectedImg = insertObjectAnnotation(detectedImg, 'rectangle', testSet.handS{t,:}, 'True');

figure
imshow(detectedImg),title(testSet.imageFileName{t},'interpreter','none')

%% Load network
%saveFile = 'C:\ABH\data\Detection\SessionFlowers_LabelData.mat';
%saveFile = 'C:\ABH\data\Detection\SessionFlowersMoreLabels_LabelData.mat';
%saveFile = 'C:\LabUsers\Uri\Data\Prarie\Videos\HR5-7\09_18_17_S\Session_08072018_LabelData_D101_N22.mat';
%load(saveFile)  
load('\\192.114.20.50\g\Amir\Video\DT73\CNO\2018-07-23\ROI23f_LabelData_D101_N23.mat')


%% Analysis of a movie - reading from Network
movieReadFile   = '\\192.114.20.50\g\Amir\Video\DT73\Saline\2018-07-25\EPC_side_Saline_2018-07-25_045.mp4'; %
[p,f,e]         = fileparts(movieReadFile); [p,fp,~] = fileparts(p); 
movieWriteFile  = fullfile(p,[fp,'-detected.mp4']);
tracker         = MultiBBoxTracking;
DetectSensetivity = 0.98;
timeStartStop    = [650 1200]./30; % sec / frame number divided by frame rate
    
%vidRead         = vision.VideoFileReader(movieReadFile);
%vidWrite        = vision.VideoFileWriter(movieWriteFile,'FileFormat','MPEG4','FrameRate', vidRead.info.VideoFrameRate);
vidRead         = VideoReader(movieReadFile);
vidRead.CurrentTime = timeStartStop(1);

vidWrite        = vision.VideoFileWriter(movieWriteFile,'FileFormat','MPEG4','FrameRate', vidRead.FrameRate);
vidPlayer       = vision.VideoPlayer;
%while ~isDone(vidRead)
while hasFrame(vidRead) && vidRead.CurrentTime < timeStartStop(2)
    frame                   = readFrame(vidRead);
    %frame                   = uint8(frame*255);
    [bbox, score, label]    = detect(net, frame, 'MiniBatchSize', 32);
    
    % filter
    if ~isempty(score)
    validInd                 = score > DetectSensetivity;
    if ~any(validInd)
        fprintf('Score is low. No ROI is shown\n'); 
    end
    [bbox,score,label]       = deal(bbox(validInd,:),score(validInd),label(validInd));
    end
    
    % Display strongest detection result.
%    [score, idx]            = max(score);
%    bbox                    = bbox(idx, :);
%    [tracker,bboxFilt,indOut] = Step(tracker, bbox);    
%     annotation              = sprintf('%s: (Conf = %4.3f)', label(idx), score);
%     frame                   = insertObjectAnnotation(frame, 'rectangle', bbox, annotation,'Color','r');
%     frame                   = insertObjectAnnotation(frame, 'rectangle', bboxFilt, annotation,'Color','b');
    
    labelNum                = size(bbox,1);
    for idx = 1:labelNum
        box         = bbox(idx, :);
        annotation  = sprintf('%s: (C=%4.3f)', label(idx), score(idx));
        frame       = insertObjectAnnotation(frame, 'rectangle', box, annotation,'Color','r');
    end
%    labelNum                = size(bboxFilt,1);
%     for idx = 1:labelNum
%         box         = bboxFilt(idx, :);
%         annotation  = sprintf('Filtered');
%         frame       = insertObjectAnnotation(frame, 'rectangle', box, annotation,'Color','g');
%     end
    
    step(vidWrite,frame);
    vidPlayer(frame);
end

%release(vidRead)
release(vidWrite)
release(vidPlayer)


%% Analysis of a movie - reading from Memory
% saline
%movieReadFile   = '\\192.114.20.50\g\Amir\Video\DT73\Saline\2018-07-25\EPC_side_Saline_2018-07-25_045.mp4'; %
% CNO
movieReadFile   = '\\192.114.20.50\g\Amir\Video\DT73\CNO\2018-07-23\EPC_side_DT73_2018-07-23_029.mp4'; %

[p,f,e]         = fileparts(movieReadFile); [p,fp,~] = fileparts(p); 
movieWriteFile  = fullfile(p,[fp,'-detected.mp4']);
%tracker         = MultiBBoxTracking;
DetectSensetivity = 0.98;
frameStartStop    = [650 1200]; %  frame number 
    
%vidRead         = vision.VideoFileReader(movieReadFile);
%vidWrite        = vision.VideoFileWriter(movieWriteFile,'FileFormat','MPEG4','FrameRate', vidRead.info.VideoFrameRate);
vidRead         = VideoReader(movieReadFile);
vidData         = read(vidRead,frameStartStop);

vidWrite        = vision.VideoFileWriter(movieWriteFile,'FileFormat','MPEG4','FrameRate', vidRead.FrameRate);
vidPlayer       = vision.VideoPlayer;
%while ~isDone(vidRead)
for k = 1:size(vidData,4)
    frame                   = vidData(:,:,:,k);
    %frame                   = uint8(frame*255);
    %[bbox, score, label]    = detect(net, frame, 'MiniBatchSize', 32);
    tic;
    [bbox, score, label]    = detect(net, frame);
    fprintf('Detect %4.3f\n',toc);
    
    % filter
    if ~isempty(score)
    validInd                 = score > DetectSensetivity;
    if ~any(validInd)
        fprintf('Score is low. No ROI is shown\n'); 
    end
    [bbox,score,label]       = deal(bbox(validInd,:),score(validInd),label(validInd));
    end
    
    % Display strongest detection result.
%    [score, idx]            = max(score);
%    bbox                    = bbox(idx, :);
%    [tracker,bboxFilt,indOut] = Step(tracker, bbox);    
%     annotation              = sprintf('%s: (Conf = %4.3f)', label(idx), score);
%     frame                   = insertObjectAnnotation(frame, 'rectangle', bbox, annotation,'Color','r');
%     frame                   = insertObjectAnnotation(frame, 'rectangle', bboxFilt, annotation,'Color','b');
    
    labelNum                = size(bbox,1);
    for idx = 1:labelNum
        box         = bbox(idx, :);
        annotation  = sprintf('%s: (C=%4.3f)', label(idx), score(idx));
        frame       = insertObjectAnnotation(frame, 'rectangle', box, annotation,'Color','r');
    end
%    labelNum                = size(bboxFilt,1);
%     for idx = 1:labelNum
%         box         = bboxFilt(idx, :);
%         annotation  = sprintf('Filtered');
%         frame       = insertObjectAnnotation(frame, 'rectangle', box, annotation,'Color','g');
%     end
    
    step(vidWrite,frame);
    vidPlayer(frame);
end

%release(vidRead)
release(vidWrite)
release(vidPlayer)

%%
% Remove the image directory from the path.
rmpath(imDir); 