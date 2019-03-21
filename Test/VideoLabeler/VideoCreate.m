%% Train R-CNN Detector
% 
%------------------------------
% Ver   Date        Who     Descr.
%-----------------------------
% 0401  03.09.18    UD      Create trajectory video
% 0301  19.03.18    UD      adjusting trackers
% 0203  12.09.17    UD      adding trackers
% 0101  05.08.17    UD      Created
%------------------------------

% %% Train CLassifier
% vc              = VideoClassifier();
% vc              = vc.TestAndTrainLabelerNetwork(101,21);

%% Load Training network
load('\\192.114.21.64\g\Amir\Video\DT73\CNO\2018-07-23\ROI23f_LabelData_D101_N23.mat','net')

%% Create Trajectories
movieReadFile   = '\\192.114.21.64\g\Amir\Video\DT73\CNO\2018-07-23\EPC_side_DT73_2018-07-23_020.mp4'; 
%[p,f,e]         = fileparts(movieReadFile);
%movieWriteFile  = fullfile(p,[f,'-Trajectory.mp4']);
%tracker         = MultiBBoxTracking;
trajData        = {};
    
vidRead         = vision.VideoFileReader(movieReadFile);
%vidRead         = VideoReader(movieReadFile);
%vidWrite        = vision.VideoFileWriter(movieWriteFile,'FileFormat','MPEG4','FrameRate', vidRead.info.VideoFrameRate);
vidPlayer       = vision.VideoPlayer; k = 0;
while ~isDone(vidRead) % hasFrame(vidRead) %
    k = k + 1;
    frame                   = step(vidRead);
    %frame                   = readFrame(vidRead);
    frame                   = uint8(frame*255);
    [bbox, score, label]    = detect(net, frame, 'MiniBatchSize', 32);
    % Display strongest detection result.
    %[tracker,bboxFilt,indOut] = Step(tracker, bbox);    
    
    labelNum                = size(bbox,1);
    for idx = 1:labelNum
        box         = bbox(idx, :);
        annotation  = sprintf('%s: (%4.3f)', label(idx), score(idx));
        frame       = insertObjectAnnotation(frame, 'rectangle', box, annotation,'Color','r');
    end
%     labelNum                = size(bboxFilt,1);
%     for idx = 1:labelNum
%         box         = bboxFilt(idx, :);
%         annotation  = sprintf('Filtered');
%         frame       = insertObjectAnnotation(frame, 'rectangle', box, annotation,'Color','g');
%     end
    
%    if k > 1000, break; end

    % save
    trajData{k}.bbox  = bbox;
    trajData{k}.score = score;
    trajData{k}.label = label;
    
    %step(vidWrite,frame);
    vidPlayer(frame);
end

release(vidRead)
%release(vidWrite)
release(vidPlayer)


%% Filter Trajectories - 1
% status - working
% copy data
for k = 1:length(trajData)
    bbox            = trajData{k}.bbox;
    score           = trajData{k}.score;
    [mv,mi]         = max(score);
    trajData{k}.bbox_f = trajData{k}.bbox(mi,:);
end
% filter
overlapThr = 0.6;
for k = 2:length(trajData)-1 
    
    % prev
    bbox_p          = trajData{k-1}.bbox_f;
    bbox            = trajData{k}.bbox_f;
    bbox_n          = trajData{k+1}.bbox_f;
    
    % check valid
    overlapRatio_p = 0;
    if ~isempty(bbox) && ~isempty(bbox_p)
        overlapRatio_p = bboxOverlapRatio(bbox,bbox_p);
    end
    overlapRatio_n = 0;
    if ~isempty(bbox) && ~isempty(bbox_n)
    overlapRatio_n = bboxOverlapRatio(bbox,bbox_n);
    end
    
    % filter
    if overlapRatio_p > overlapThr && overlapRatio_n > overlapThr
        bbox = bbox*0.6 + 0.2*bbox_p + 0.2*bbox_n;
    elseif overlapRatio_p > overlapThr && overlapRatio_n <= overlapThr
        bbox = bbox*0.7 + 0.3*bbox_p;
    elseif overlapRatio_p <= overlapThr && overlapRatio_n > overlapThr
        bbox = bbox*0.7 + 0.3*bbox_n;
    else
        %bbox = bbox*0.8 + 0.1*bbox_p + 0.1*bbox_n;
    end
    
    % save
    trajData{k}.bbox_f  = bbox;
    
    %step(vidWrite,frame);
    %vidPlayer(frame);
end

%% Filter Trajectories - 2
% filter Frwrd
tracker         = MultiBBoxTracking;
for k = 1:length(trajData) 
    
    % check valid
    [tracker,bboxFilt] = Step(tracker, trajData{k}.bbox); 
    
    % save
    trajData{k}.bbox_f  = bboxFilt;
    
end
% % filter Backwrd
% tracker         = MultiBBoxTracking;
% for k = length(trajData):-1:1
%     
%     % check valid
%     [tracker,bboxFilt] = Step(tracker, trajData{k}.bbox_f); 
%     
%     % save
%     trajData{k}.bbox_f  = bboxFilt;
% end


%% Extrat Trajectory Line
trajLineXY = nan(length(trajData),2);
for k = 1:length(trajData)
    bbox            = trajData{k}.bbox_f;
    if isempty(bbox),continue; end
    trajLineXY(k,1) = bbox(1)+bbox(3)/2;
    trajLineXY(k,2) = bbox(2)+bbox(4)/2;
end
isValid     = ~any(isnan(trajLineXY),2);
trajLineXYT = reshape(trajLineXY(isValid,:)',1,[]); % for show

%% Create a movie
movieReadFile   = '\\192.114.21.64\g\Amir\Video\DT73\CNO\2018-07-23\EPC_side_DT73_2018-07-23_020.mp4'; 
[p,f,e]         = fileparts(movieReadFile);
%movieWriteFile  = fullfile(p,[f,'-Trajectory.mp4']);
movieWriteFile  = [f,'-Trajectory.mp4'];
    
vidRead         = vision.VideoFileReader(movieReadFile);
vidWrite        = vision.VideoFileWriter(movieWriteFile,'FileFormat','MPEG4','FrameRate', vidRead.info.VideoFrameRate);
vidPlayer       = vision.VideoPlayer; k = 0;
while ~isDone(vidRead) % hasFrame(vidRead) %
    k = k + 1;
    frame                   = step(vidRead);
    %frame                   = readFrame(vidRead);
    frame                   = uint8(frame*255);
    
    % insert trajectory
    frame                   = insertShape(frame,'line',trajLineXYT,'color','y');
    if ~any(isnan(trajLineXY(k,:)))
    frame                   = insertMarker(frame,trajLineXY(k,:),'o','color','r','size',20);
    end
        
    step(vidWrite,frame);
    vidPlayer(frame);
end

release(vidRead)
release(vidWrite)
release(vidPlayer)


%%
% Remove the image directory from the path.
%rmpath(imDir); 