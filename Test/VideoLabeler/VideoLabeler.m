classdef VideoLabeler < handle
    % VideoLabeler class used for the Ground Truth Labeler App
    %
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 11.12 19.08.18 UD     Fixes for ROIs 
    % 11.11 14.08.18 UD     One time save and variable valid change. 
    % 11.10 04.07.18 UD     3D image output. 
    % 11.09 27.06.18 UD     Improving performance. 
    % 11.08 26.06.18 UD     Work on All Data, Export Trajectories. 
    % 11.07 21.06.18 UD     Work on All Data, Export Trajectories. 
    % 11.06 06.06.18 UD     Fixing some minor bugs. 
    % 11.05 09.05.18 UD     Sorting video add
    % 11.04 29.04.18 UD     Adding function that can Run over all Files and Detect
    % 11.03 23.04.18 UD     Session file fix
    % 11.01 11.04.18 UD     Adopting to TPA
    % 10.03 02.04.18 UD     Image size is 640 columns
    % 10.02 25.03.18 UD     Adjusting for old labels
    % 10.01 19.03.18 UD     Code for Aruga
    % 08.03 08.03.18 UD     Adding button for all and putting Detector inside
    % 08.02 04.03.18 UD     Fixes
    % 08.01 01.03.18 UD     Detector Dir and also table for ROIs. Function remix
    % 07.07 27.02.18 UD     Adding buttons for Detector
    % 07.06 25.02.18 UD     ROI structures - type added
    % 07.05 21.02.18 UD     Merging and Improving
    % 07.04 19.02.18 UD     Loading entire video sequence
    % 07.03 10.02.18 UD     Dealing with MovieComb
    % 07.02 09.02.18 UD     Export for heatmap
    % 07.01 05.01.18 UD     Imported after room labeler
    % 06.03 28.11.17 UD     Selecting multiple frames
    % 06.02 25.11.17 UD     Adding media manager
    % 06.01 24.11.17 UD     adopted to TPA. No room axis
    % 05.01 18.10.17 UD     room added
    % 04.03 17.10.17 UD     using two image axis
    % 04.02 14.10.17 UD     Adding ROI info and map
    % 04.01 11.10.17 UD     Adding ROI list
    % 03.01 19.07.17 UD     Garbage labeller
    %-----------------------------
    % Constant values
    properties (Constant)
        VERSION = '11.11';
    end
    
    properties (Access = private)
        %% Figure Properties
        hf % handle for figure
        ha % handle for axes
        %hp % handle axis with plot
        %% Toolbar Properties
        hNewSession
        hOpenSession
        hSaveSession
        hAddImages
        hAddVideo
        hRoiAdd
        hLoadDetectROI
        hAddAutoROI
        hAddAllROI
        hZoomIn
        hZoomOut
        hzoom
        hPanButton
        hpan
        hTrain
        hHelp
        %% Video Utility Panel Properties
        hVideoUtilityPanel
        hFrameNumberText
        hFrameNumber
        %hPreviousFrame
        %hNextFrame
        hAddLabelsNextFrame
        hAddLabelsPrevFrame
        %% Media Utility Panel Properties
        hMediaUtilityPanel
        hPreviousMedia
        hNextMedia
        %% Telemetry Bar Properties
        hTelemetryBar
        %% Data Browser Properties
        hDataBrowser
        hMediaBrowser
        hFrameBrowser
        hRoiBrowser
        hMediaBrowserList
        hFrameBrowserList
        hRoiBrowserList
        %% Slider
        hSlider
        %% Structures to hold the info
        FrameInfo
        %% ROI Label Properties
        xDeleteOffset  = 0;
        yDeleteOffset  = 15;
        xLabelOffset = 0;
        yLabelOffset = 0;
        
    end
    
    properties
        %% Data Properties
        GTS
        FrameIndex = 0;
        MediaIndex = 0;
        RoiIndex = 0;
        nFrames  = 0;   
        FR                  % video object
        VideoData           % entire video
        %RoiIndex
        Frame
        
        %InitialState
        DataDir             % connection to the latest data dir
        SessionDir          % session file location
        SessionName         % session file name
        RoiList             % container of roi labels
        RoiDetect           % auto ROI detector
        RoiDetectManager    % object that manages all the training and detection
        
        % control params
        DetectSensetivity = 0.98;
    end
    
    %% Init
    methods
        
        function app = VideoLabeler
            tic;
            app.ConstructComponents();
            app.InitializeData();
            %app.SetupExamples();
        end
        %  Callbacks for simple_gui. These callbacks automatically
        %  have access to component handles and initialized GTS
        %  because they are nested at a lower level.
        function ConstructComponents(obj)
            %% Initialize common parameters
            %close all
            widthFigure         = 1000;
            heightFigure        = 550;
            xFigure             = 200;
            yFigure             = 200;
            widthDataBrowser    = 200;
            widthImage          = 640;
            heightTelemetryBar  = 30;
            heightSlider        = 25;
            %% Create Figure
            obj.hf              = figure('Position',[xFigure,yFigure,widthFigure,heightFigure],'Visible','off','NumberTitle','off');
            set(obj.hf,'menubar','none');
            % Assign the GUI a name to appear in the window title.
            obj.hf.Name         = ['Video Labeler : ',obj.VERSION];
            % Move the GUI to the center of the screen.
            movegui(obj.hf,'center')
            %% Construct Toolbar Components
            % define general location parameters
            heightToolbar       = 75; % height of all buttons for top bar
            yToolbar            = heightFigure-heightToolbar; % y coordinate for bottom of top bar
            % construct new session button
            xNewSession         = 5;
            widthNewSession     = 50;
            textUI              = '<html>New<br>Session</html>';
            obj.hNewSession = uicontrol('Tag','NewSession',...
                'Style','pushbutton',...
                'Max',2,...
                'String',textUI,...
                'TooltipString','Open a new session for labeling',...
                'Position',[xNewSession,yToolbar,widthNewSession,heightToolbar],...
                'Callback',@obj.SessionNew_Callback);
            % construct open session button
            xOpenSession = xNewSession+widthNewSession;
            widthOpenSession = 60;
            textUI = '<html>Open<br>Session</html>';
            obj.hOpenSession = uicontrol('Tag','OpenSession',...
                'Style','pushbutton',...
                'String',textUI,...
                'Position',[xOpenSession,yToolbar,widthOpenSession,heightToolbar],...
                'Callback',@obj.SessionOpen_Callback,...
                'Max',2);
            % construct save session button
            xSaveSession = xOpenSession+widthOpenSession;
            widthSaveSession = 60;
            textUI = '<html>Save<br>Session</html>';
            obj.hSaveSession = uicontrol('Tag','SaveSession',...
                'Style','pushbutton',...
                'String',textUI,...
                'Position',[xSaveSession,yToolbar,widthSaveSession,heightToolbar],...
                'Callback',@obj.SessionSave_Callback,...
                'Max',2);
            % construct add images button
            xAddImages = xSaveSession+widthSaveSession+5;
            widthAddImages = 60;
            textUI = '<html>Add<br>Directory</html>';
            obj.hAddImages = uicontrol('Tag','AddImages',...
                'Style','pushbutton',...
                'String',textUI,...
                'Position',[xAddImages,yToolbar,widthAddImages,heightToolbar],...
                'Callback',@obj.MediaAddDirectory_Callback,...
                'Max',2);
            % construct add video button
            xAddVideo = xAddImages+widthAddImages;
            widthAddVideo = 60;
            textUI = '<html>Add<br>Video</html>';
            obj.hAddVideo = uicontrol('Tag','AddVideo',...
                'Style','pushbutton',...
                'String',textUI,...
                'Position',[xAddVideo,yToolbar,widthAddVideo,heightToolbar],...
                'Callback',@obj.MediaAddVideo_Callback,...
                'Max',2);
            
%             % add media button
%             xMediaButtons = xAddVideo+widthAddVideo;
%             widthMediaButtons = 60;
%             % construct Previous Media button
%             obj.hPreviousMedia = uicontrol(...
%                 'Tag','PreviousMedia',...
%                 'Style','pushbutton',...
%                 'String','<html>Previous<br>Media</html>',...
%                 'Position',[xMediaButtons,yToolbar,widthMediaButtons,heightToolbar],...
%                 'Callback',@obj.MediaPrevious_Callback,...
%                 'Max',2);
%             xMediaButtons = xMediaButtons+widthMediaButtons;
%             obj.hNextMedia = uicontrol(...
%                 'Tag','NextMedia',...
%                 'Style','pushbutton',...
%                 'String','<html>Next<br>Media</html>',...
%                 'Position',[xMediaButtons,yToolbar,widthMediaButtons,heightToolbar],...
%                 'Callback',@obj.MediaNext_Callback,...
%                 'Max',2);
            
            % construct Frame Number text
            heightFrameNumberText = heightToolbar/2;
            widthFrameNumberText = 60;
            xFrameNumberText = xAddVideo+widthAddVideo+5; %xMediaButtons+widthMediaButtons+5; %xROI+widthROI;
            yFrameNumberText = yToolbar+1/2*heightToolbar;
            obj.hFrameNumberText = uicontrol(...
                'Tag','FrameNumberText',...
                'Style','text',...
                'String','Frame Number:',...
                'Position',[xFrameNumberText yFrameNumberText widthFrameNumberText heightFrameNumberText],...
                'Max',2);
            % convert generalized variables to normalized
            widthVideoButtons = 60;
            heightVideoButtons = heightToolbar;
            % construct Frame Number edit
            widthFrameNumber = 60;
            heightFrameNumber = heightToolbar/2;
            xFrameNumber = xFrameNumberText;
            yFrameNumber = yToolbar;
            obj.hFrameNumber = uicontrol(...
                'Tag','FrameNumber',...
                'Style','edit',...
                'Tag','FrameEdit',...
                'String','',...
                'Position',[xFrameNumber,yFrameNumber,widthFrameNumber,heightFrameNumber],...
                'CallBack',@obj.FrameNumber_Callback);
            % construct Add Labels to Prev Frame button
            xAddLabelsPrevFrame = xFrameNumber + widthVideoButtons;
            obj.hAddLabelsPrevFrame = uicontrol(...
                'Tag','AddLabelsPrevFrame',...
                'Style','pushbutton',...
                'String','<html>Prev<br>Frame<br>+ROIs</html>',...
                'TooltipString','Track the current ROIs to the previous frame. ',...
                'Position',[xAddLabelsPrevFrame,yToolbar,widthVideoButtons,heightToolbar],...
                'Callback',{@obj.FrameNextAddLabels_Callback,false},...
                'Max',2);
            
%             % construct Previous Frame button
%             xPreviousFrame = xAddLabelsPrevFrame + widthFrameNumber;
%             obj.hPreviousFrame = uicontrol(...
%                 'Tag','PreviousFrame',...
%                 'Style','pushbutton',...
%                 'String','<html>Previous<br>Frame</html>',...
%                 'Position',[xPreviousFrame,yToolbar,widthVideoButtons,heightToolbar],...
%                 'Callback',@obj.FramePrevious_Callback,...
%                 'Max',2);
%             
%             % construct Next Frame button
%             xNextFrame = xPreviousFrame + widthVideoButtons;
%             obj.hNextFrame = uicontrol(...
%                 'Tag','NextFrame',...
%                 'Style','pushbutton',...
%                 'String','<html>Next<br>Frame</html>',...
%                 'TooltipString','Go to the next frame without ROIs. ',...
%                 'Position',[xNextFrame,yToolbar,widthVideoButtons,heightToolbar],...
%                 'Callback',@obj.FrameNext_Callback,...
%                 'Max',2);
            % construct Add Labels to Next Frame button
            xAddLabelsNextFrame = xAddLabelsPrevFrame + widthVideoButtons;
            obj.hAddLabelsNextFrame = uicontrol(...
                'Tag','AddLabelsNextFrame',...
                'Style','pushbutton',...
                'String','<html>Next<br>Frame<br>+ROIs</html>',...
                'TooltipString','Track the current ROIs to the next frame. ',...
                'Position',[xAddLabelsNextFrame,yToolbar,widthVideoButtons,heightToolbar],...
                'Callback',@obj.FrameNextAddLabels_Callback,...
                'Max',2);
            
            % construct add roi button
            xROI = xAddLabelsNextFrame+widthVideoButtons + 5;
            widthROI = 60;
            action = 'new';
            obj.hRoiAdd = uicontrol('Tag','RoiAdd',...
                'Style','pushbutton',...
                'TooltipString','Draw ROI manually.',...
                'String','Add ROI',...
                'Position',[xROI,yToolbar,widthROI,heightToolbar],...
                'Callback',{@obj.RoiAdd_Callback,action},...
                'Max',2);
            
            % construct add roi button
            xDetect = xROI+widthROI;
            obj.hLoadDetectROI = uicontrol('Tag','LoadDetectROI',...
                'Style','pushbutton',...
                'TooltipString','Load ROI detector (CNN).',...
                'String','<html>Load<br>ROI<br>Detector</html>',...
                'Position',[xDetect,yToolbar,widthROI,heightToolbar],...
                'Callback',@obj.RoiDetectorLoad_Callback);
            
            % construct add roi button for single frame
            xAutoROI = xDetect+widthROI;
            textUI = '<html>Detect<br>ROIs per<br>Frame</html>';
            action = 'new';
            obj.hAddAutoROI = uicontrol('Tag','AddSingleROI',...
                'Style','pushbutton',...
                'String',textUI,...
                'Position',[xAutoROI,yToolbar,widthROI,heightToolbar],...
                'Callback',{@obj.RoiAddFrame_Callback,action},...
                'Max',2);

            % construct add roi button for multiple files and frames
            xAllROI = xAutoROI+widthROI;
            textUI = '<html>Detect<br>ROIs<br>For All</html>';
            action = 'new';
            obj.hAddAllROI = uicontrol('Tag','AddAutoROI',...
                'Style','pushbutton',...
                'String',textUI,...
                'Position',[xAllROI,yToolbar,widthROI,heightToolbar],...
                'Callback',{@obj.RoiAddMedia_Callback,action},...
                'Max',2);
            
            
            
            % construct zoom buttons
            xZoom = xAllROI+widthROI+5;
            widthZoom = 60;
            heightZoom = heightToolbar/3;
            % construct zoom in
            yZoomIn = yToolbar+2/3*heightToolbar;
            textUI = sprintf('%s','Zoom In');
            obj.hZoomIn = uicontrol('Tag','ZoomIn',...
                'Style','togglebutton','String',textUI,...
                'Position',[xZoom,yZoomIn,widthZoom,heightZoom],...
                'Callback',@obj.ZoomIn_Callback,...
                'Max',2);
            % construct zoom out
            yZoomOut = yToolbar+1/3*heightToolbar;
            textUI = sprintf('%s','Zoom Out');
            obj.hZoomOut = uicontrol('Tag','ZoomOut',...
                'Style','togglebutton','String',textUI,...
                'Position',[xZoom,yZoomOut,widthZoom,heightZoom],...
                'Callback',@obj.ZoomOut_Callback,...
                'Max',2);
            obj.hzoom = zoom(obj.hf);
            % construct pan
            yPan = yToolbar;
            textUI = sprintf('%s','Pan');
            obj.hPanButton = uicontrol('Tag','Pan',...
                'Style','togglebutton','String',textUI,...
                'Position',[xZoom,yPan,widthZoom,heightZoom],...
                'Callback',@obj.Pan_Callback,...
                'Max',2);
            obj.hpan = pan(obj.hf);
            
            % construct Export button
            widthHelp = 60;
            xHelp= xZoom+widthHelp;
            widthHelp = 60;
            textUI = '<html>Export<br>Data</html>'; %sprintf('%s','Help');
            obj.hHelp = uicontrol('Tag','Help',...
                'Style','pushbutton','String',textUI,...
                'Position',[xHelp,yToolbar,widthHelp,heightToolbar],...
                'Callback',@obj.Export_Callback,...
                'Max',2);
            
            % construct train button
            xTrain= xHelp+widthZoom+5;
            textUI = '<html>Train<br>ROI <br>Detector</html>'; %sprintf('%s','Help');
            obj.hTrain = uicontrol('Tag','Train',...
                'Style','pushbutton','String',textUI,...
                'TooltipString','Train ROI detector (CNN).',...
                'Position',[xTrain,yToolbar,widthHelp,heightToolbar],...
                'Callback',@obj.NetTrain_Callback,...
                'Max',2);
            
            
            % Construct Video Utility Panel
            xVideoPanel = widthDataBrowser+20;
            widthVideoPanel = 0;
            % Construct Telemetry Bar
            obj.hTelemetryBar = uicontrol(obj.hf,...
                'Tag','TelemetryBar',...
                'Style','text',...
                'HorizontalAlignment','left',...
                'String','Add Images or Video to begin',...
                'Units','pixels',...
                'Position',[5 -10 widthDataBrowser heightTelemetryBar]);
            % Construct Data Browser
            obj.hDataBrowser = uitabgroup(obj.hf,'Units','Pixels','Position',[10 heightTelemetryBar widthDataBrowser 440]);
            obj.hMediaBrowser = uitab(obj.hDataBrowser,'Title','Media');
            obj.hFrameBrowser = uitab(obj.hDataBrowser,'Title','Frames');
            obj.hRoiBrowser   = uitab(obj.hDataBrowser,'Title','ROIs');
            mediaBrowserContextMenu = uicontextmenu;
            uimenu(mediaBrowserContextMenu,'Label','Add Video','Enable','on','Callback',@obj.MediaAddVideo_Callback);
            uimenu(mediaBrowserContextMenu,'Label','Delete Media','Enable','on','Callback',@obj.MediaDelete_Callback);
            uimenu(mediaBrowserContextMenu,'Label','Import Old Labels','Enable','on','Callback',@obj.MediaOldLabelImport_Callback);
            
            roiBrowserContextMenu = uicontextmenu;
            uimenu(roiBrowserContextMenu,'Label','Add ROI Label','Enable','on','Callback',{@obj.RoiListManage_Callback,'add'});
            uimenu(roiBrowserContextMenu,'Label','Delete ROI Label','Enable','on','Callback',{@obj.RoiListManage_Callback,'delete'});
            uimenu(roiBrowserContextMenu,'Label','ROI List Update','Enable','on','Callback',{@obj.RoiListManage_Callback,'update'});
            uimenu(roiBrowserContextMenu,'Label','Statistics of ROI','Enable','on','Callback',{@obj.RoiListManage_Callback,'statistics'});
            uimenu(roiBrowserContextMenu,'Label','Export Trajectories','Enable','on','Callback',{@obj.RoiListManage_Callback,'export'});
            
            obj.hMediaBrowserList = uicontrol('Style','listbox',...
                'Parent',obj.hMediaBrowser,...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'UIContextMenu',mediaBrowserContextMenu,...
                'Callback',@obj.MediaBrowserList_Callback);
            obj.hFrameBrowserList = uicontrol('Style','listbox',...
                'Parent',obj.hFrameBrowser,...
                'Units','normalized',...
                'Max',100,...  % multiselection
                'Min',0,...
                'Position',[0 0 1 1],...
                'Callback',@obj.FrameBrowserList_Callback);
            obj.hRoiBrowserList = uicontrol('Style','listbox',...
                'Parent',obj.hRoiBrowser,...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'UIContextMenu',roiBrowserContextMenu,...
                'Callback',@obj.RoiBrowserList_Callback);
            
%                         % Create the uitable
%              obj.hRoiBrowserList    = uitable(obj.hRoiBrowser,...
%                         'Data', zeros(0,2),...
%                         'Units','normalized',...
%                         'ColumnName', {'Frame','ROI'},...
%                         'ColumnFormat', {'char'},...
%                         'Position',[0.02 0.02 0.96 0.96]);
%                         %'ColumnEditable', false(1,length(obj.DBM.ExpertNames)),...
%                         %'RowName',rownames);            

            
            % Construct Image Viewer
            xImageViewer        = widthDataBrowser+widthVideoPanel+5;
            yImageViewer        = heightTelemetryBar;
            xImageWidth         = (widthFigure - widthDataBrowser)-10;
            obj.ha              = axes('Units','Pixels','Position',[xImageViewer,yImageViewer,xImageWidth,heightFigure-heightToolbar-heightTelemetryBar-10]);
            obj.ha.ALimMode     = 'manual';
            obj.Frame           = rand(480,640,3);
            hImg                = imshow(obj.Frame,'Parent', obj.ha);
            
            % Construct slider
            xSlider             = xImageViewer;
            ySlider             = yImageViewer - heightSlider;
            obj.hSlider         = uicontrol('style','slider','units','Pixels',...
                'Position',[xSlider,ySlider,xImageWidth,heightSlider-5],...
            'min',1,'max',100,'val',1, ...
            'sliderstep',[1/100,0.03],'callback',@obj.FrameSlider_Callback,...
            'TooltipString','Always browsing in Time');
        
            % callback for left mouse down to add ROI
            %set(obj.hf, 'WindowButtonDownFcn',@(s,e)obj.RoiAdd_Callback(s,e,'new'));


            % Normalize Units to Enable Auto-Resize
            % Initialize the GUI.
            % Change units to normalized so components resize
            % automatically.
            obj.hf.Units        = 'normalized';
            obj.ha.Units        = 'normalized';
            obj.hSlider.Units   = 'normalized';
            obj.hNewSession.Units = 'normalized';
            obj.hOpenSession.Units = 'normalized';
            obj.hSaveSession.Units = 'normalized';
            obj.hAddImages.Units = 'normalized';
            obj.hAddVideo.Units = 'normalized';
            obj.hRoiAdd.Units = 'normalized';
            obj.hLoadDetectROI.Units = 'normalized';
            obj.hAddAutoROI.Units = 'normalized';  
            obj.hAddAllROI.Units = 'normalized';
            obj.hZoomIn.Units = 'normalized';
            obj.hZoomOut.Units = 'normalized';
            obj.hPanButton.Units = 'normalized';
            obj.hTrain.Units = 'normalized';
            obj.hHelp.Units = 'normalized';
            obj.hDataBrowser.Units = 'normalized';
            obj.hPreviousMedia.Units = 'normalized';
            obj.hNextMedia.Units = 'normalized';
            obj.hFrameNumberText.Units = 'normalized';
            obj.hFrameNumber.Units = 'normalized';
            %obj.hNextFrame.Units = 'normalized';
            obj.hAddLabelsNextFrame.Units = 'normalized';
            obj.hAddLabelsPrevFrame.Units = 'normalized';
            %obj.hPreviousFrame.Units = 'normalized';
            obj.hVideoUtilityPanel.Units = 'normalized';
            obj.hMediaUtilityPanel.Units = 'normalized';
            %% Make the GUI visible.
            obj.hf.Visible = 'on';
            obj.hf.HandleVisibility = 'callback';
        end
        function InitializeData(obj)
            %% Initialize the Ground Truth Session
            frameInfo       = struct('bboxes',{},'labels',{},'types',{}); % 1-Human,2-machine
            media           = struct('FileName',' ','FrameInfo',frameInfo,'FrameString',{});
            gtsInfo         = struct('DateModified',datestr(now),'Version',obj.VERSION,'MediaInfo', media,'RoiInfo',{[]});
            obj.GTS         = gtsInfo;
            %obj.GTS.MediaInfo(1) = []; % make the GTS empty
            %obj.GTS.MediaInfo   = obj.GTS.MediaInfo'; % transpose MediaInfo to be Mx1
            obj.RoiList     = {}; %containers.Map('KeyType','char','ValueType','any');
            % Determine list of supported image and video data types
            obj.DataDir     = '..\TwoPhotonData';
            obj.SessionDir  = '..\TwoPhotonData';
            obj.SessionName = 'VideoLabelerSession.mat';
            obj.FrameInfo   = frameInfo;
            obj.RoiDetectManager = VideoClassifier();
        end
    end
    
    %% Session
    methods
        
        function SessionNew_Callback(obj,source,eventData)
            ButtonChosen = questdlg('Creating a new session will erase any unsaved changes. Are you sure you would like to proceed?','Unsaved Changes','Yes','No','No');
            if strcmp(ButtonChosen,'Yes')
                app = VideoLabeler;
            end
        end
        function SessionOpen_Callback(obj,source,eventData)
            [SessionFileName,SessionFilePath,~] = uigetfile('.mat','Session',obj.SessionDir);
            % If session was selected
            if isequal(SessionFileName,0), return; end
            
            obj.SessionDir        = SessionFilePath;
            obj.SessionName       = SessionFileName;
            GroundTruthSession    = load(fullfile(SessionFilePath,SessionFileName));
            PreviousGTS           = obj.GTS;
            % Check if selected .MAT file session is valid
            if ~isfield(GroundTruthSession,'GTS')
                errordlg('Specified .MAT file is not a Ground Truth Session. Please specify a valid Ground Truth Session.','Invalid Ground Truth Session');
            end
            
            obj.GTS               = GroundTruthSession.GTS;
            % if the session is not empty
            if isempty(obj.GTS.MediaInfo)
                obj.GTS = PreviousGTS;
                warndlg('The session chosen is empty and therefore will not be loaded.','Empty Ground Truth Session');
                return
            end
            
            % Update media browser
            obj.hMediaBrowserList.String = {};
            for idx = 1:length(obj.GTS.MediaInfo)
                [~,FileName,FileExt] = fileparts(obj.GTS.MediaInfo(idx).FileName);
                obj.hMediaBrowserList.String{idx} = [FileName,FileExt];
            end
            % Update media index
            persistent netName
            obj.MediaIndex = 1;
            % Check that all files exist
            for idx = 1:length(obj.GTS.MediaInfo)
                mediaFileName = obj.GTS.MediaInfo(idx).FileName;
                if ~exist(mediaFileName,'file')
                    if isempty(netName)
                        prompt={'Please add computer network name: (\\192.114.20.42) '};
                        name='Session is Moved';
                        numlines=1;
                        defaultanswer={'\\192.114.20.42'};
                        answer=inputdlg(prompt,name,numlines,defaultanswer);
                        if isempty(answer),return; end
                        netName = answer{1};
                    end
                    ii            = strfind(mediaFileName,'\');
                    if numel(ii)<3, error('Bad file string. Call 911'); end
                    % check if begins with \\ 
                    if diff(ii(1:2))<2
                        mediaFileName = mediaFileName(ii(3):end);
                    end
                    mediaFileName = fullfile(netName,mediaFileName);
                    mediaFileName = erase(mediaFileName,':');
                    if ~exist(mediaFileName,'file')
                        errordlg('No media found. Did you move the file ?'); return;
                    end
                    obj.GTS.MediaInfo(idx).FileName =  mediaFileName;
                end
            end
            obj.SessionUpdate;
        end
        function SessionUpdate(obj)
            % Update frame index
            %obj.FrameIndex  = 1;
            % Set focus of data browser back to media browser
            obj.hDataBrowser.SelectedTab = obj.hMediaBrowser;
            % Check that the chosen file exists
            if ~exist(obj.GTS.MediaInfo(obj.MediaIndex).FileName,'file')
                errordlg('No media found. Did you move the file?'); return;
            end
            % update media browser
            obj.hMediaBrowserList.Value = obj.MediaIndex;
            obj.hMediaBrowserList.String = {};
            for idx = 1:length(obj.GTS.MediaInfo)
                [p,FileName,FileExt]=fileparts(obj.GTS.MediaInfo(idx).FileName);
                if startsWith(FileName,'movie_comb')
                    [p,pf,~] = fileparts(p);
                    FileName = [pf,'_',FileName];
                end
                obj.hMediaBrowserList.String{idx} = [FileName,FileExt];
            end
            % If file exists, update session
            FilePath = obj.GTS.MediaInfo(obj.MediaIndex).FileName;
            % check media type of selected media file
            mediatype = obj.MediaTypeGet(FilePath);
            % if image
            if strcmp(mediatype,'image')
                error('Not supported')
                %obj.Frame = imresize(imread(obj.GTS.MediaInfo(obj.MediaIndex).FileName),[NaN,640]);
                obj.Frame = imread(obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                % hide video utility panel
                obj.hVideoUtilityPanel.Visible = 'off';
                % if video
            elseif strcmp(mediatype,'video')
                obj.hVideoUtilityPanel.Visible = 'on';
                % Extract frame rate, number of frames and frame from file
                %                     obj.FR          = VideoReader(obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                %                     obj.nFrames     = ceil(obj.FR.FrameRate*obj.FR.Duration);
                %                     obj.Frame       = readFrame(obj.FR);
                %                     obj.FrameIndex  = 1;
                MediaManage(obj,'init_old',obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                
                % start at first frame
                %obj.FR.CurrentTime=0;
                %obj.Frame       = readFrame(obj.FR);
                obj.hVideoUtilityPanel.Visible = 'on';
                %obj.hFrameNumber.String = num2str(obj.FrameIndex);
                % Update Frame Browser
                for idx = 1:length(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo)
                    roiNum = length(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(idx).bboxes);
                    if roiNum > 0
                        obj.GTS.MediaInfo(obj.MediaIndex).FrameString{idx} = sprintf('frame %04d - %02d',idx,roiNum);
                    else
                        obj.GTS.MediaInfo(obj.MediaIndex).FrameString{idx} = sprintf('frame %04d',idx);
                    end
                end
                obj.hFrameBrowserList.String = obj.GTS.MediaInfo(obj.MediaIndex).FrameString;
                obj.RoiList                  = obj.GTS.RoiInfo;
                %obj.hFrameBrowserList.Value = 1;
            end
            % show frame
            %imshow(obj.Frame,'Parent', obj.ha);
            % add rois to axes
            obj.RoiAdd_Callback([],[],'update');
            RoiListUpdate(obj);
        end
        function SessionSave_Callback(obj,source,eventData)
            if isempty(obj.GTS.MediaInfo)
                errordlg('Session is empty. Please add media to session before saving.');
            end
            [filename, pathname] = uiputfile('*.mat',...
                       'Save Session file', obj.SessionDir);
            if isequal(filename,0) || isequal(pathname,0)
               return
            end
            
            obj.SessionDir        = pathname;
            obj.SessionName       = filename;
            fname                 = fullfile(pathname,filename);
            obj.GTS.RoiInfo       = obj.RoiList;
            GTS = obj.GTS; %#ok<PROPLC>
            try
                save(fname, 'GTS');
                obj.DataDir = pathname;
            catch me
                error(me.message);
            end
            obj.Print(sprintf('Session is saved to %s',fname),'I');
        end
        function SessionExport(obj)
            % check
            mediaNum        = length(obj.GTS.MediaInfo);
            if mediaNum < 1, Print(obj,sprintf('no media data.'),'E'); return; end
            
            % check mdia
            mediatype = obj.MediaTypeGet(obj.GTS.MediaInfo(obj.MediaIndex).FileName);
            if ~strcmp(mediatype,'video'), warndlg('Works only for video'); return; end
            
            % session name
            fName                 = fullfile(obj.SessionDir,obj.SessionName);
            if ~exist(fName,'file')
                Print(obj,sprintf('%s does not exists. Trying to load manually',fName),'W'); 
                [sessionFileName,sessionFilePath,~] = uigetfile('.mat','Session',obj.SessionDir);
                if sessionFileName==0, return; end
                fName = fullfile(sessionFilePath,sessionFileName);
            end
            
            
            % prepare labels
            uniqueLabels    = obj.GTS.RoiInfo; 
            mediaWithLabels = false(mediaNum,1);
            for mediaIndex = 1:mediaNum
                %nFrames = length(GTS.MediaInfo(mediaIndex).FrameInfo);
                % find non empty labels
                w       = arrayfun(@(x)(~isempty(x.labels)),obj.GTS.MediaInfo(mediaIndex).FrameInfo,'UniformOutput', true);
                wInd    = find(w);
                mediaWithLabels(mediaIndex) = ~isempty(wInd);
                for k = 1:numel(wInd)
                    fi = wInd(k);
                    uniqueLabels  = union(uniqueLabels,obj.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels);
                end
                
            end
            labelNum        = length(uniqueLabels);
            if labelNum < 1, Print(obj,sprintf('no label data.'),'E'); return; end
            obj.RoiList     = uniqueLabels;
            RoiListUpdate(obj);
            
            % which labels to train
            [s,ok] = listdlg('PromptString','Select ROI type to train :','ListString',uniqueLabels,'SelectionMode','multi');
            if ~ok, return; end
            uniqueLabels    = uniqueLabels(s);
            labelNum        = length(uniqueLabels);
            
            
            % run over all medias and prepare directories
            gtData           = cell(0,labelNum+1);
            for mediaIndex = 1:mediaNum
                % skip not used labels
                if ~mediaWithLabels(mediaIndex) 
                    obj.Print(sprintf('%s - no labels found',obj.GTS.MediaInfo(mediaIndex).FileName),'W');
                    continue; 
                end
                % prepare location
                [obj,cData]     = MediaExport(obj, obj.GTS.MediaInfo(mediaIndex),uniqueLabels, fName);
                gtData          = cat(1,gtData,cData); 
                obj.Print(sprintf('%s - %d labels found',obj.GTS.MediaInfo(mediaIndex).FileName,size(cData,1)),'I');
            end
            % check if there are empty
            anEmptyCell         = cellfun(@(x)(isempty(x)),gtData,'UniformOutput', true);
            [ii,jj]             = find(anEmptyCell);
            gtData(ii,:)        = [];
            
            % save
            varNames            = matlab.lang.makeValidName(uniqueLabels(:));
            labelData           = cell2table(gtData,'VariableNames',cat(1,{'imageFileName'}, varNames));
            
            %corrData    = cData;
            [filePath,fileName,~] = fileparts(fName);
            saveFile    = fullfile(filePath,sprintf('%s_LabelData.mat',fileName));
            if exist(saveFile,'file')
                button = questdlg('Previous results file exists. Overwrite?');
                if strcmp(button,'Yes')
                    save(saveFile,'labelData');
                end
            else
                save(saveFile,'labelData');
            end
            obj.Print(sprintf('Label Data is saved to %s',saveFile))
            
        end
        
    end
    
    %% Media
    methods
        
        function MediaAddVideo_Callback(obj,source,eventData)
            %[FileNames,PathNames,~] = uigetfile({'*.avi','';'*.tif','';'*.tiff','';'*.mp4','';'*.mov','';'*.mpg','';'*.*','All Video Files'},'Select Video' ,'MultiSelect','on','Video',obj.DataDir);
            [FileNames,PathNames,~] = uigetfile({'*.avi';'*.tif';'*.tiff';'*.mp4';'*.mov';'*.mpg';'*.*'},'Select Video',obj.DataDir,'MultiSelect','on');
            if FileNames == 0, return; end
            obj.MediaAdd(FileNames,PathNames);
            obj.DataDir = PathNames;
        end
        function MediaAddDirectory_Callback(obj,s,e)
            
            start_path = obj.DataDir;
            folder_name = uigetdir(start_path,'Select Folder with video data');
            if isequal(folder_name,0), return ;end
            obj.DataDir = folder_name;
            obj.SessionDir = folder_name;
            imds = imageDatastore(folder_name,...
            'IncludeSubfolders',true,'FileExtensions',{'.tif','.mp4','.avi','.mov'},'LabelSource','foldernames');
            MediaAdd(obj,imds.Files,'');
        end
        function MediaAdd(obj,FileNames,PathNames)
            FullFilePaths = fullfile(PathNames,FileNames);
            % If button was not cancelled
            if isequal(FileNames,0), return; end
            % create list of FileNames from media browser
            FileNamesMB = cell(length(obj.GTS.MediaInfo),1);
            for idx = 1:length(obj.GTS.MediaInfo)
                [p,FileNameMB,FileExtMB] = fileparts(obj.GTS.MediaInfo(idx).FileName);
                FileNamesMB{idx} = FileNameMB; %[FileNameMB FileExtMB];
            end
            FileNames = cellstr(FileNames);
            FullFilePaths = cellstr(FullFilePaths);
            for idx = 1:length(FileNames)
                FileNewBool(idx) = ~any(strcmp(FileNames(idx),FileNamesMB)); %#ok<AGROW>
            end
            NewFileNames = FileNames(FileNewBool);
            NewFullFilePaths = FullFilePaths(FileNewBool);
            % Create an empty structure array
            FrameInfoEmpty = obj.FrameInfo;
            % if there are any new files
            if isempty(NewFileNames),return; end
            % Set focus of data browser back to media browser
            obj.hDataBrowser.SelectedTab = obj.hMediaBrowser;
            for idx = 1:length(NewFileNames)
                % Update Media Index
                obj.MediaIndex = length(obj.hMediaBrowserList.String)+1;
                % Update GTS filename for each file
                obj.GTS.MediaInfo(obj.MediaIndex,1).FileName = NewFullFilePaths{idx};
                % Update Media Browser for each file
                % add dir name to file
                fileName   = NewFileNames{idx};
                if startsWith(fileName,'movie_comb')
                    [p,pf,~] = fileparts(NewFullFilePaths{idx});
                    [p,pf,~] = fileparts(p);
                    fileName = [pf,'_',fileName];
                end
                obj.hMediaBrowserList.String{obj.MediaIndex} = fileName;
                % check media type of selected media file
                mediatype = obj.MediaTypeGet(obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                if strcmp(mediatype,'video')
                    % Extract frame rate, number of frames and frame from each file
                    %obj.FR      = VideoReader(obj.GTS.MediaInfo(obj.MediaIndex).FileName); %#ok<TNMLP>
                    %MediaManage(obj,'init_old',obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                    MediaManage(obj,'init_old',obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                    %obj.nFrames = ceil(obj.FR.FrameRate*obj.FR.Duration);
                    %UD FrameInfo = repmat(FrameInfoEmpty,obj.nFrames,1);
                    frameString = cell(obj.nFrames,1);
                    for didx = 1:obj.nFrames
                        %frameInfo(didx,1) = FrameInfoEmpty;
                        frameString{didx} = sprintf('frame %04d',didx);
                    end
                    frameInfo                     = FrameInfoEmpty;
                    frameInfo(obj.nFrames).bboxes = {};
                    
                else
                    frameInfo = FrameInfoEmpty;
                    frameString = {};
                end
                obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo = frameInfo;
                obj.GTS.MediaInfo(obj.MediaIndex).FrameString = frameString;
            end
            % Update Media Browser value to final media index value
            obj.hMediaBrowserList.Value = obj.MediaIndex;
            % Add delete menu item
            %obj.hMediaBrowserList.UIContextMenu.Children.Enable = 'on';
            %[obj.hMediaBrowserList.UIContextMenu.Children(:).Enable] = deal('on')
            % Set frame index to 1
            %obj.FrameIndex = 1;
            % if image
            if strcmp(mediatype,'image')
                % read image
                obj.Frame = imread(obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                % if video
            elseif strcmp(mediatype,'video')
                %MediaManage(obj,'init_old',obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                obj.hVideoUtilityPanel.Visible = 'on';
                obj.hFrameBrowserList.String = obj.GTS.MediaInfo(obj.MediaIndex).FrameString;
            end
            obj.DataDir = NewFullFilePaths{1};
        end        
        function MediaManage(obj,action,varargin)
            % perform operations on video files
            if nargin < 2,error('action is not specified'); end
            switch action
                case 'init_old' % init frame by frame
                    % check inputs
                    filename = varargin{1};
                    if ~exist(filename,'file'), errordlg(sprintf('File %s is not found',filename)); end
                    
                    % Extract frame rate, number of frames and frame from each file
                    obj.FR                  = VideoReader(filename); 
                    obj.FR.CurrentTime      = eps;
                    obj.nFrames             = ceil(obj.FR.FrameRate*obj.FR.Duration);
                    obj.Frame               = readFrame(obj.FR);
                    % keep the index for media browsing
                    obj.FrameIndex          = max(1,min(obj.nFrames,obj.FrameIndex));
                    % slider
                    obj.hSlider.Max         = obj.nFrames;
                    obj.hSlider.SliderStep  = [1/obj.nFrames,0.03];
                    obj.hFrameBrowserList.ListboxTop = obj.nFrames;
                    
                case 'init' % load entire movie
                    % check inputs
                    filename = varargin{1};
                    if ~exist(filename,'file'), errordlg(sprintf('File %s is not found',filename)); end
                    
                    % Extract frame rate, number of frames and frame from each file
                    obj.Print('Loading video file. Please wait....')
                    obj.FR          = VideoReader(filename); 
                    obj.VideoData   = read(obj.FR);
                    obj.nFrames     = ceil(obj.FR.FrameRate*obj.FR.Duration);
                    obj.FrameIndex  = 1;
                    obj.Frame       = obj.VideoData(:,:,:,1); %imresize(readFrame(obj.FR),[NaN,640]);
                    obj.Print('Done')
    
                    
                case 'next_old' % old style
                    
                    if obj.FrameIndex >= obj.nFrames, return; end
                    obj.FrameIndex  = obj.FrameIndex + 1;
                    obj.Frame       = readFrame(obj.FR); 
                    
                    
                case 'next'
                    
                    obj.FrameIndex = min(obj.FrameIndex + 1,obj.nFrames);
                    obj.Frame      = obj.VideoData(:,:,:,obj.FrameIndex);
                    
               case 'prev_old' % old style
                    
                     if obj.FrameIndex <= 1, return; end
                    obj.FrameIndex      = obj.FrameIndex - 1;
                    obj.FR.CurrentTime  = (obj.FrameIndex-1)/obj.FR.FrameRate;
                    obj.Frame           = readFrame(obj.FR);
                    
                case 'prev'
                    
                    obj.FrameIndex = max(obj.FrameIndex - 1,1);
                    obj.Frame      = obj.VideoData(:,:,:,obj.FrameIndex);
                    
                case 'frame' % read specific frame
                    % check inputs
                    frameInd = varargin{1};
                    if ~isnumeric(frameInd), errordlg(sprintf('Frame number must be a number')); end
                    frameInd        = max(1,min(obj.nFrames,frameInd));
                    %if frameNum<0||frameNum>obj.nFrames, errordlg(sprintf('No a valid number')); end
                    
                    obj.FrameIndex = frameInd;
                    obj.Frame      = obj.VideoData(:,:,:,obj.FrameIndex);
                    
                    % do not update the GUI
                    return
                    
               case 'frame_3d' % read specific frame
                    % check inputs
                    frameInd        = varargin{1};
                    if ~isnumeric(frameInd), errordlg(sprintf('Frame number must be a number')); end
                    frameInd        = max(2,min(obj.nFrames-1,frameInd));
                    %if frameNum<0||frameNum>obj.nFrames, errordlg(sprintf('No a valid number')); end
                    
                    obj.FrameIndex = frameInd;
                    fInd           = frameInd-1:frameInd+1;
                    obj.Frame      = squeeze(obj.VideoData(:,:,1,fInd));
                    
                    % do not update the GUI
                    return
                    
 
               case 'frame_old' % read specific frame - old style
                    % check inputs
                    frameInd = varargin{1};
                    if ~isnumeric(frameInd), errordlg(sprintf('Frame number must be a number')); end
                    frameInd = max(1,min(obj.nFrames,frameInd));
                    
                    % assume that the multiple frame selection
                    %[c,ia] = setdiff(frameNum,obj.FrameIndex);
                    
                    % show accumulated video
                    frameTmp        = zeros(size(obj.Frame),'single');
                    frameLen        = numel(frameInd);
                    for k = 1:frameLen
                        obj.FR.CurrentTime  = (frameInd(k)-1)/obj.FR.FrameRate;
                        obj.Frame           = readFrame(obj.FR);
                        frameTmp            = frameTmp + single(obj.Frame);
                    end
                    obj.Frame               = uint8(frameTmp./frameLen);
                    obj.FrameIndex          = frameInd;
                    
                otherwise
                    error('Bad action type')
            end
            
            % update GUI
            imshow(obj.Frame,'Parent',obj.ha);
            % Update the Frame Browser
            obj.hFrameBrowserList.Value = obj.FrameIndex;
            obj.hSlider.Value           = obj.FrameIndex(1);
            % update the frame number edit box
            obj.FrameIndex          = obj.FrameIndex(1);
            obj.hFrameNumber.String = num2str(obj.FrameIndex);
                    
        end   
        function uniqueLabels = MediaGetValidLabels(obj) 
            % prepare labels
            uniqueLabels    = {}; 
            mediaNum        = length(obj.GTS.MediaInfo);
            if mediaNum < 1, Print(obj,sprintf('no media data.'),'E'); return; end
            
            %allLabels        = {[]}; 
            mediaWithLabels = false(mediaNum,1);
            for mediaIndex = 1:mediaNum
                %nFrames = length(GTS.MediaInfo(mediaIndex).FrameInfo);
                % find non empty labels
                w       = arrayfun(@(x)(~isempty(x.labels)),obj.GTS.MediaInfo(mediaIndex).FrameInfo,'UniformOutput', true);
                wInd    = find(w);
                mediaWithLabels(mediaIndex) = ~isempty(wInd);
                for k = 1:numel(wInd)
                    fi      = wInd(k);
                    % FIX :  remove empty labels or non chracters
                    ii      = cellfun(@(x)ischar(x),obj.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels,'UniformOutput', true);
                    obj.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels = obj.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels(ii);
                    %allLabels     = cat(2,allLabels,obj.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels);
                    if isempty(uniqueLabels), uniqueLabels = obj.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels; end
                    uniqueLabels  = union(uniqueLabels,obj.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels);
                end
                
            end
       end        
        function MediaBrowserList_Callback(obj,eventData,handles)
            % MediaBrowserList_Callback activated whenever item is selected
            % in the media browser
            % if session has at least one media
            if isempty(obj.GTS.MediaInfo), return; end
            obj.MediaIndex = eventData.Value;
            obj.hMediaBrowserList.Value = obj.MediaIndex;
            % Update frame index
            %obj.FrameIndex  = 1;
            obj.SessionUpdate;
        end 
        function MediaPrevious_Callback(obj,source,eventData)
            % if not 1st frame
            if obj.MediaIndex >= 2
                % Update Media Index
                obj.MediaIndex = obj.MediaIndex - 1;
                obj.SessionUpdate;
            end
        end
        function MediaNext_Callback(obj,source,eventData)
            % if not last frame
            if obj.MediaIndex<=length(obj.hMediaBrowserList.String)-1
                % Update Media Index
                obj.MediaIndex = obj.MediaIndex + 1;
                obj.SessionUpdate;
            end
        end
        function mediatype = MediaTypeGet(obj,filename)
            %[~,~,ext] = fileparts(filename);
            %if any(strcmpi(ext,obj.VideoExtensionsCell))
                mediatype = 'video';
            %elseif any(strcmpi(ext,obj.ImageExtensionsCell))
            %    mediatype = 'image';
            %end
        end
        function MediaDelete_Callback(obj,source,eventData)
            % if there are any media objects available
            if ~isempty(obj.GTS.MediaInfo)
                DeleteIndex = obj.hMediaBrowserList.Value;
                % if no more media remains
                if length(obj.hMediaBrowserList.String)==1
                    obj.MediaIndex = 0;
                    % update media browser
                    obj.hMediaBrowserList.String(DeleteIndex) = [];
                    obj.hMediaBrowserList.Value;
                    obj.hMediaBrowserList.ListboxTop = 1;
                    % update delete menu item
                    obj.hMediaBrowserList.UIContextMenu.Children.Enable = 'off';
                    % update frame browser
                    obj.hFrameBrowserList.String = {};
                    % Update GTS
                    obj.GTS.MediaInfo(DeleteIndex) = [];
                    % Update Video Utility Panel
                    obj.hVideoUtilityPanel.Visible = 'off';
                    % update image viewer
                    obj.Frame = ones(480,640,3);
                    imshow(obj.Frame,'Parent',obj.ha);
                else  % if there are is any remaining media
                    % update Media Browser
                    obj.MediaIndex = max(1,DeleteIndex-1);
                    obj.hMediaBrowserList.String(DeleteIndex) = [];
                    obj.hMediaBrowserList.Value = obj.MediaIndex;
                    obj.hMediaBrowserList.ListboxTop = 1;
                    % Update GTS
                    obj.GTS.MediaInfo(DeleteIndex) = [];
                    obj.SessionUpdate;
                end
            end
        end
        function [obj,cData] = MediaExport(obj, mediaInfo, uniqueLabels, sessionPath)
            % MediaExport - export single media file
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
            frameNum         = length(mediaInfo.FrameInfo);
            if frameNum < 10
                Print(obj,sprintf('%s does not contain label data.',mediaInfo.FileName),'E'); 
                return
            end
            labelNum = length(uniqueLabels);
            if labelNum < 1
                Print(obj,sprintf('Label data is not cpecified.'),'E'); 
                return
            end
            [savePath,saveFile,~] = fileparts(sessionPath);
            
            % extract frames with labels
            labelFrameNum = arrayfun(@(x)(length(x.labels)),mediaInfo.FrameInfo,'UniformOutput', true);

            % prepare session file
            [p,fname,ext] = fileparts(mediaInfo.FileName);
            if strcmp(fname,'movie_comb'),[p,fname,ext] = fileparts(p); end
            [~,sname,ext] = fileparts(saveFile);
            dirPathLabel  = fullfile(savePath,sname,fname);
            
            persistent updateDir;
            if isempty(updateDir), updateDir = true; end
            if exist(dirPathLabel,'dir')
                button = questdlg(sprintf('Image directory %s already exists. Overwrite?',fname));
                if strcmp('Cancel',button)
                    return
                elseif strcmp('No',button)
                    % contiune
                    updateDir = false;
                else % Yes
                    rmdir(dirPathLabel,'s');
                    mkdir(dirPathLabel);
                end
            else
                mkdir(dirPathLabel)
            end
            
            % check if there are any label
            if all(labelFrameNum<1)
                Print(obj,sprintf('%s does not contain label data. Next media file.',mediaInfo.FileName),'W');
                return
            end
            
            
            % export data
            %[~,fname,ext] = fileparts(mediaInfo.FileName);
            %localFR     = VideoReader(mediaInfo.FileName);
            % load entire data file
            MediaManage(obj,'init',mediaInfo.FileName);

            cData       = cell(1,labelNum+1); m = 0;
            %cData       = cell2table(cData,'VariableNames',{'imageFileName',uniqueLabels});
            %fi = 0;
            for fi      = 2:frameNum-1
                if labelFrameNum(fi)<1,continue; end
                framePath       = fullfile(dirPathLabel,sprintf('frame_%04d.jpg',fi));
               % check if label belongs to this frame
                noLabel = true;
                for k = 1:labelNum
                    lbl                 = uniqueLabels{k};
                    ind                 = find(strcmp(mediaInfo.FrameInfo(fi).labels,lbl));
                    if isempty(ind),continue; end
                    % create a new row once
                    if noLabel
                        m               = m + 1;
                        cData{m,1}      = {framePath};
                        noLabel         = false;
                    end
                    %%cData{m,k+1}        = {cell2mat(mediaInfo.FrameInfo(fi).bboxes(ind)')};
                    bboxs               = cell2mat(mediaInfo.FrameInfo(fi).bboxes(ind)');
%                     bboxs(:,1:2)        = bboxs(:,1:2)-bboxs(:,3:4)/4;
%                     bboxs(:,3:4)        = bboxs(:,3:4)+bboxs(:,3:4)/4*2;
                    cData{m,k+1}        = {bboxs};
                end
                if ~updateDir, continue; end
                if noLabel, continue; end
                % frame by frame
                %localFR.CurrentTime     = fi/localFR.FrameRate;
                %frameW                  = readFrame(localFR);    
                %
                indW                     = fi; %fi-1:fi+1;
                frameW                  = squeeze(obj.VideoData(:,:,1,indW));
                imwrite(frameW,framePath,'jpg');
            end

        end
        function mediaInfo = MediaDeleteLabel(obj, mediaInfo, labelNames)
            % MediaDeleteLabel - delete specific label from media data
            % Input:
            %   mediaInfo   - structure with relevant data
            %  labelNames - which labels to delete
            % Output:
            %   mediaInfo     - updated
            validateattributes(labelNames, {'cell'}, {'nonempty'});
            frameNum         = length(mediaInfo.FrameInfo);
            if frameNum < 10
                Print(obj,sprintf('%s does not contain label data.',mediaInfo.FileName),'E'); 
                return
            end
            labelNum = length(labelNames);
            if labelNum < 1
                Print(obj,sprintf('Label data is not cpecified.'),'E'); 
                return
            end
            
            % extract frames with labels
            labelFrameNum = arrayfun(@(x)(length(x.labels)),mediaInfo.FrameInfo,'UniformOutput', true);
            %fi = 0;
            for fi      = 1:frameNum
                if labelFrameNum(fi)<1,continue; end
               % check if label belongs to this frame
                for k = 1:labelNum
                    lbl                 = labelNames{k};
                    ind                 = find(strcmp(mediaInfo.FrameInfo(fi).labels,lbl));
                    if isempty(ind),continue; end
                    % delete
                    mediaInfo.FrameInfo(fi).labels(ind) = [];
                    mediaInfo.FrameInfo(fi).bboxes(ind) = [];
                    mediaInfo.FrameInfo(fi).types(ind) = [];
                end
            end

        end        
        function MediaOldLabelImport_Callback(obj,source,eventData)
            % imprts previously labeled data by Iddo
            if isempty(obj.GTS.MediaInfo), return; end
%             importIndex = obj.hMediaBrowserList.Value;
%             obj.MediaIndex
            [fileDir,fileName] = fileparts(obj.GTS.MediaInfo(obj.MediaIndex).FileName);
            
            [fileName,filePath,~] = uigetfile('.mat','Labeler Output',fileDir,'multiselect','off');
            % If session was selected
            if isequal(fileName,0), return; end
            
            % load old labeler file
            sOld       = load(fullfile(filePath,fileName));
            nFramesOld  = length(sOld.GTS.MediaInfo.FrameInfo);
            
            % checks
            nFramesNew  = length(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo);
            if nFramesOld ~= nFramesNew-1 && nFramesOld ~= nFramesNew % some reading problem
                obj.Print('Number of frames missmatch in the video files. Could be a potential problem.','E');
                return
            end
            
            % prepare labels
            uniqueLabels    = {}; 
            % find non empty labels
            w       = arrayfun(@(x)(~isempty(x.labels)),sOld.GTS.MediaInfo(1).FrameInfo,'UniformOutput', true);
            wInd    = find(w);
            frameId = wInd;
            for k = 1:numel(wInd)
                fi            = wInd(k);
                %vind          = cellfun(@(x)(~isempty(x)),sOld.GTS.MediaInfo(1).FrameInfo(fi).labels,'UniformOutput', true);
                for m = 1:length(sOld.GTS.MediaInfo(1).FrameInfo(fi).labels)
                    % fix some nested cell problem
                    if isempty(sOld.GTS.MediaInfo(1).FrameInfo(fi).labels{m}),continue; end
                    if iscell(sOld.GTS.MediaInfo(1).FrameInfo(fi).labels{m})
                        roiLabel = sOld.GTS.MediaInfo(1).FrameInfo(fi).labels{m};
                    else
                        roiLabel = sOld.GTS.MediaInfo(1).FrameInfo(fi).labels{m};
                    end
                    uniqueLabels  = union(uniqueLabels,roiLabel);
                end
            end
            labelNum        = length(uniqueLabels);
            if labelNum < 1, Print(obj,sprintf('%s : no label data.',fileName),'E'); return; end
            
            % compare with current ROI list
            if isempty(obj.RoiList), obj.RoiList = uniqueLabels; end
            % adding missed labels
            missedLabels = setdiff(obj.RoiList,uniqueLabels);
            if ~isempty(missedLabels)
                obj.Print(sprintf('There are new labels will be added to the ROI list : %',cell2mat(missedLabels{:})),'W');
            end
            obj.RoiList = uniqueLabels;
            RoiListUpdate(obj);
            
            % roi resize
            [nR,nC,nD]          = size(obj.Frame);
            rescaleFactor       = 1;%nC/640;
            
            % assign ROIs to the particular frames
            for k = 1:numel(frameId)
                fiOld      = wInd(k);
                fiNew      = frameId(k);
                for m = 1:numel(sOld.GTS.MediaInfo(1).FrameInfo(fiOld).labels)
                    if isempty(sOld.GTS.MediaInfo(1).FrameInfo(fiOld).labels{m}),continue; end
                    if iscell(sOld.GTS.MediaInfo(1).FrameInfo(fiOld).labels{m})
                        roiLabel = sOld.GTS.MediaInfo(1).FrameInfo(fiOld).labels{m};
                    else
                        roiLabel = sOld.GTS.MediaInfo(1).FrameInfo(fiOld).labels{m};
                    end
                    colInd     = strcmp(obj.RoiList, roiLabel);
                    if ~any(colInd), continue; end
                    bbox        = sOld.GTS.MediaInfo(1).FrameInfo(fiOld).bboxes{m};
                    obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(fiNew).bboxes{m} = bbox*rescaleFactor;
                    obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(fiNew).labels{m} = roiLabel;
                    obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(fiNew).types{m} = 1;
                end
            end
            
            obj.SessionUpdate;
            obj.Print('Import Succesfull');
        end        
        
    end
        
    %% ROI
    methods
        
        function RoiBrowserList_Callback(obj,eventData,handles)
            % if session has at least one media
            %if isempty(obj.GTS.MediaInfo),return; end
            % if file browser is empty, don't do anything when user
            %obj.RoiListUpdate();
            % clicks on empty list
            if ~isempty(obj.hRoiBrowserList.String)
                obj.RoiIndex = obj.hRoiBrowserList.Value;
%                 keyL         = obj.hRoiBrowserList.String(obj.RoiIndex,:);
%                 % add 
%                 frameIndex   = obj.RoiList(keyL);
%                 FrameNumber_Callback(obj,[],[], frameIndex(1));
            end
        end
        function RoiListUpdate(obj) 
            % updates labels 
            %uniqueLabels            = MediaGetValidLabels(obj);
            %uniqueLabels            = unique(allLabels);
            %labelNum                = length(uniqueLabels);
            %if labelNum < 1, Print(obj,sprintf('no label data.'),'E'); return; end
            %obj.RoiList                 = union(uniqueLabels,obj.RoiList);
            %if isempty(obj.RoiList), return; end
            obj.hRoiBrowserList.String = obj.RoiList(:); %uniqueLabels{:}; %keys(obj.RoiList);       
            obj.hRoiBrowserList.Value = 1;
            Print(obj,sprintf('ROI List updated.'),'I');
        end
        function RoiListManage_Callback(obj,source,eventData,action)
            
            % which action to do with the list
            roiLabelNum = length(obj.RoiList);
            roiIndex    = obj.hRoiBrowserList.Value;
            
            switch action
                case 'add'
                    % user input to specify label
                    label = inputdlg('ROI Label Name');
                    obj.RoiList{roiLabelNum+1} = matlab.lang.makeValidName(label{1});
                case 'delete'
                    if roiLabelNum < 1, obj.Print('No ROIs in the list','W'); return; end
                    deleteIndex = roiIndex;
                    deleteLabel = obj.RoiList{deleteIndex};
                    % ask to remove all ROIs
                    button = questdlg(sprintf('Delete all ROIs with label %s from the current session?',deleteLabel{:}));
                    if ~strcmp('Yes',button)
                        return
                    else
                        % do it
                        mediaNum = length(obj.GTS.MediaInfo);
                        if mediaNum < 1, Print(obj,sprintf('No media data.'),'E'); return; end
                        for mediaIndex = 1:mediaNum
                            mediaInfo = obj.GTS.MediaInfo(mediaIndex);
                            mediaInfo = MediaDeleteLabel(obj, mediaInfo, deleteLabel);
                            obj.GTS.MediaInfo(mediaIndex) = mediaInfo;
                        end
                        Print(obj,sprintf('%s deleted.',deleteLabel{1}),'I');
                    end
                    obj.RoiList(deleteIndex) = [];
                case 'statistics'
                    if roiLabelNum < 1, obj.Print('No ROIs in the list','W'); return; end
                    roiLabel = obj.RoiList(roiIndex);
                    RoiStatistics(obj, {roiLabel});
                case 'export'
                    if roiLabelNum < 1, obj.Print('No ROIs in the list','W'); return; end
                    roiLabel = obj.RoiList{roiIndex(1)};
                    RoiExportTrajectory(obj, roiLabel);
                case 'update'
                    uniqueLabels            = MediaGetValidLabels(obj);
                    obj.RoiList             = union(uniqueLabels,obj.RoiList);
                    obj.hRoiBrowserList.String = obj.RoiList(:);                    
                otherwise
                   errordlg('Unknown action type');
            end 
            
            RoiListUpdate(obj);            
        end        
        function RoiAdd_Callback(obj,source,eventData,action)
            if isempty(obj.GTS.MediaInfo)
                errordlg('Session is empty. Please add media before adding a ROI');
            end
                
            if strcmp(action,'new')
                obj.RoiAdd(action);
            elseif strcmp(action,'update') % next frame, previous frame, edit box frame, open session
                % check media type of selected media file
                mediatype = obj.MediaTypeGet(obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                if strcmp(mediatype,'image')
                    for idx = 1:length(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(1).bboxes)
                        obj.RoiIndex = idx;
                        obj.RoiAdd(action)
                    end
                elseif strcmp(mediatype,'video')
                    % remove points
%                         childrenP = get(obj.hp,'children');
%                         for k = 1:length(childrenP)
%                             if ~strcmp(childrenP(k).Type,'image'), delete(childrenP(k)); end
%                         end
                    % add rois
                    for idx = 1:length(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes)
                        obj.RoiIndex = idx;
                        obj.RoiAdd(action)
                    end
                end
            end
            % mark it on frame
            roiNum          = length(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes);
            lbt = get(obj.hFrameBrowserList,'ListboxTop'); % box position changes - keep the previous after accessing string
            if roiNum > 0
                obj.GTS.MediaInfo(obj.MediaIndex).FrameString{obj.FrameIndex} = sprintf('frame %04d - %02d',obj.FrameIndex,roiNum);
            else
                obj.GTS.MediaInfo(obj.MediaIndex).FrameString{obj.FrameIndex} = sprintf('frame %04d',obj.FrameIndex);
            end
            obj.hFrameBrowserList.String{obj.FrameIndex} = obj.GTS.MediaInfo(obj.MediaIndex).FrameString{obj.FrameIndex};
            set(obj.hFrameBrowserList,'ListboxTop',lbt);
            %obj.RoiListUpdate();
            %obj.Print('Select frame');
            
        end
        function RoiDetectorLoad_Callback(obj,source,eventData)
            % load detector
            [detectFileName,detectFilePath,~] = uigetfile('.mat','Detector',obj.DataDir);
            if detectFileName == 0, return; end
            loadFile = fullfile(detectFilePath,detectFileName);
            try
                s = load(loadFile,'net');
            catch
                errordlg(sprintf('Bad or incorrect Detector file %s ',loadFile)); 
                return;
            end
            obj.RoiDetect = s.net;
            if ~isa(obj.RoiDetect,'rcnnObjectDetector'),obj.Print('Detector of not supported type ','E'); return; end
            %if ~isa(obj.RoiDetect,'fasterRCNNObjectDetector'),obj.Print('Detector of not supported type ','E'); return; end
            % check labels
            detectLabels = obj.RoiDetect.ClassNames(1:end-1); % the last is background
            if isempty(obj.RoiList), obj.RoiList = detectLabels; end
            missedLabels = setdiff(obj.RoiList,detectLabels);
            if ~isempty(missedLabels)
                warndlg(sprintf('The following labels will not be detected :%s',missedLabels{:}));
            end
            RoiListUpdate(obj);
            obj.DataDir = detectFilePath;
            obj.Print('Detector is loaded ','I');
        end      
        function RoiAddFrame_Callback(obj,source,eventData,action)
            % if current media is valid
            if nargin < 4, action = 'new'; end 
            if obj.MediaIndex < 1,                              obj.Print('No Media found','E'); return; end
            if obj.FrameIndex<1 || obj.FrameIndex>obj.nFrames,  obj.Print('Out of range','E');  return; end
 
            % if net is loaded
            if isempty(obj.RoiDetect),errordlg('Load Detector first'); return; end
                                
            %obj.hFrameBrowserList.Value
            
            oldBbox             = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes;
            oldLabel            = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels;
            oldType             = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).types;
            
            % load frame 3D
            %MediaManage(obj,'frame_3d',obj.FrameIndex);
            %testImage               = obj.Frame;%(:,:,1);
            testImage               = obj.Frame(:,:,1);
            [bbox, score, label]    = detect(obj.RoiDetect, testImage, 'MiniBatchSize', 32, 'SelectStrongest', true);
            if isempty(score)
                Print(obj,sprintf('No ROI is detected.'),'W'); return;
            end
            % For faster RCNN
            %[bbox, score, label]    = detect(obj.RoiDetect, testImage);
            validInd                 = score > obj.DetectSensetivity;
            if ~any(validInd)
                Print(obj,sprintf('Score is low. No ROI is shown'),'W'); return;
            end
            [bbox,score,label]       = deal(bbox(validInd,:),score(validInd),label(validInd));
            
            % create ROIs
            [newBbox,newLabel,newType] = deal(oldBbox,oldLabel,oldType);
            k  = length(oldLabel);
            for m = 1:length(label)
                newBbox{k+m}      = bbox(m,:);
                %newLabel{k+m}     = sprintf('%s:%4.3f', label(m), score(m));
                newLabel{k+m}     = sprintf('%s-d', label(m));
                newType{k+m}      = 2;
            end
            % copy and replace ROIs from previous frame
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes = newBbox;
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels = newLabel;
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).types = newType;
            % add ROIs to frame
            if strcmp(action,'new')
            obj.RoiAdd_Callback(source,eventData,'update');
            end
        end   
        function RoiAddMedia_Callback(obj,source,eventData,action)
            % for entire media
            mediaNum        = length(obj.GTS.MediaInfo);
            if mediaNum < 1, Print(obj,sprintf('no media data.'),'E'); return; end
            % if net is loaded
            if isempty(obj.RoiDetect),errordlg('Load Detector first'); return; end
            
            % which labels to train
            mediaFiles = obj.hMediaBrowserList.String;
            [s,ok] = listdlg('PromptString','Select Media to Apply ROI Detector :','ListString',mediaFiles,'SelectionMode','multi');
            if ~ok, return; end
            mediaInd    = s;
            
            % start iterate over media files
            for mi = mediaInd
                obj.MediaIndex   = mi;
                obj.FrameIndex   = 1;
                %MediaManage(obj,'init_old',obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                MediaManage(obj,'init',obj.GTS.MediaInfo(obj.MediaIndex).FileName);
                Print(obj,sprintf('Computing for file %s,',obj.GTS.MediaInfo(obj.MediaIndex).FileName),'I');
                for fi =1:obj.nFrames
                    obj.FrameIndex      = fi;
                    MediaManage(obj,'frame',fi);
                    %MediaManage(obj,'frame_3d',fi);
                    RoiAddFrame_Callback(obj,0,0,'no'); % do not add to image
                    obj.Print(sprintf('Frame : %04d - Done.',fi));
                end
                Print(obj,sprintf('Done.'),'I');
            end
        end           
        function RoiAdd(obj,action)
            fcn = makeConstrainToRectFcn('imrect',get(obj.ha,'XLim'),get(obj.ha,'YLim'));
            LabelValid = true;
            if strcmp(action,'new')
                % check if labels are defined
                labelNum    = length(obj.RoiList); %obj.hRoiBrowserList.String);
                if labelNum < 1, errordlg('Please specify ROI labels first'); return; end
                label       = obj.RoiList(obj.hRoiBrowserList.Value);
                if isempty(label),obj.Print('Bad label 911', 'E'); return; end
                
                % user input to specify bounding box
                hroi = imrect(obj.ha,'PositionConstraintFcn',fcn);

                % find out how many rois there are
                nlabels     = length(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes);
                obj.RoiIndex  = nlabels + 1;
                % Update GTS with bounding box
                obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes{obj.RoiIndex} = round(getPosition(hroi));
                % update GTS with label
                obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels{obj.RoiIndex} = label{1};
                obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).types{obj.RoiIndex} = 1;

            elseif strcmp(action,'update')
                % find out how many rois there are
                nlabels = length(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes);
                if nlabels ~= length(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels)
                    LabelValid = false;
                end
                if ~isempty(nlabels) && LabelValid
                    hroi = imrect(obj.ha,obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes{obj.RoiIndex},'PositionConstraintFcn',fcn);
                end
            end
            if LabelValid && ~isempty(obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes{obj.RoiIndex})
                rx = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes{obj.RoiIndex}(1);
                ry = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes{obj.RoiIndex}(2);
                rw = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes{obj.RoiIndex}(3);
                rh = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes{obj.RoiIndex}(4);
                % remove context menu items from imrect object
                p = findall(hroi,'type','Patch');
                set(p,'UIContextMenu',[]);
                % prevent imrect from being deleted
                hroi.Deletable = false;
                % add label
                obj.xLabelOffset = 0;
                obj.yLabelOffset = 15;
                hLabelEdit = text('Parent',obj.ha,...
                    'pos',[rx+rw/2+obj.xLabelOffset ry+rh+obj.yLabelOffset],...
                    'string',obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels{obj.RoiIndex},...
                    'tag','label',...
                    'edgecolor','w',...
                    'color','b',...
                    'backgroundcolor',[1 1 0],...'r',...
                    'horizontalalignment','center');
                % add delete button
                obj.xDeleteOffset = 0;
                obj.yDeleteOffset = 0;
                hDelButton = text('Parent',obj.ha,...
                    'pos',[rx+rw+obj.xDeleteOffset ry+obj.yDeleteOffset],...
                    'string','\fontsize{4} \bf\fontsize{6}X\rm\fontsize{4} ',...
                    'tag','delButton',...
                    'edgecolor','w',...
                    'color','w',...
                    'backgroundcolor',[0.7 0 0],...'r',...
                    'horizontalalignment','center');
                uistack(hDelButton,'top');
                %setString(hpnt,obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels{obj.RoiIndex});
                
                % add callback to move set of objects corresponding to label when dragged
                idx = obj.RoiIndex;
                RoiChange_Callback   = @(pos) obj.RoiChange_Callback(hroi,hLabelEdit,hDelButton,pos,idx);
                addNewPositionCallback(hroi,RoiChange_Callback);
                % add callback to delete object set when delete box is pressed
                RoiDelete_Callback = @(source,eventData) obj.RoiDelete_Callback(source,eventData,hroi,hLabelEdit,hDelButton,idx);
                hDelButton.ButtonDownFcn = RoiDelete_Callback;
                % add callback to rename label when edit label is clicked on
                RoiEditLabel_Callback = @(source,eventData) obj.RoiEditLabel_Callback(source,eventData,hLabelEdit,idx);
                hLabelEdit.ButtonDownFcn = RoiEditLabel_Callback;
            end
            %
        end
        function [obj,newBbox,newLabel,newTypes] = RoiTrack(obj,oldVideoFrame,oldBbox,oldLabel,oldTypes, newVdeoFrame)
            % tracks ROIs
            newBbox = oldBbox;
            newLabel = oldLabel;
            newTypes = oldTypes;
            bNum    = length(newBbox);
            if bNum < 1, return; end
            boxValid  = false(bNum,1);
            if size(oldVideoFrame,3) > 1, oldVideoFrame = rgb2gray(oldVideoFrame); end
            if size(newVdeoFrame,3) > 1, newVdeoFrame = rgb2gray(newVdeoFrame); end
            for b = 1:bNum
                oldBboxRect = oldBbox{b};
                % Create a point tracker and enable the bidirectional error constraint to
                % make it more robust in the presence of noise and clutter.
                pointTracker = vision.PointTracker('MaxBidirectionalError', 1);
                
                % Detect feature points in the region.
                points      = detectMinEigenFeatures(oldVideoFrame, 'ROI', oldBboxRect);
                
                % Initialize the tracker with the initial point locations and the initial
                % video frame.
                oldPoints = points.Location;
                initialize(pointTracker, oldPoints, oldVideoFrame);
                
                % Track the points. Note that some points may be lost.
                [points, isFound] = step(pointTracker, newVdeoFrame);
                visiblePoints = points(isFound, :);
                oldInliers = oldPoints(isFound, :);
                
                if size(visiblePoints, 1) >= 2 % need at least 2 points
                    
                    % Estimate the geometric transformation between the old points
                    % and the new points and eliminate outliers
                    [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                        oldInliers, visiblePoints, 'similarity', 'MaxDistance', 1);
                    
                    %                 % transform back to bbox : ul,ur,lr,ll
                    xform.T(3,1:2)      = mean(visiblePoints  - oldInliers); % STRANGE FIX - estimateGeometricTransform is not good 
                    newBbox{b}(1:2)     = newBbox{b}(1:2) + xform.T(3,1:2);
                    scaleFactor         = sqrt(sum(xform.T(1:2,1).^2));
                    newBbox{b}(3:4)     = newBbox{b}(3:4)*scaleFactor;
                    
                    % check boundaries
                    if 1<=newBbox{b}(1) && sum(newBbox{b}([1 3]))<=size(oldVideoFrame,2) &&...
                            1<=newBbox{b}(2) && sum(newBbox{b}([2 4]))<=size(oldVideoFrame,1)
                        boxValid(b)         = true;
                    end
                    
                end
                
                release(pointTracker);
            end
            newBbox = newBbox(boxValid);
            newLabel = newLabel(boxValid);
            newTypes = newTypes(boxValid);
            
            
        end
        function [obj,newBbox] = RoiTrackPatch(obj,oldVideoFrame,oldBbox,newVideoFrame)
            % tracks ROIs
            newBbox = oldBbox;
            bNum    = length(newBbox);
            if bNum < 1, return; end
            
            [nR,nC,nD] = size(newVideoFrame);
            % debug
            imgS        = imfuse(oldVideoFrame,newVideoFrame);
            
            for b = 1:bNum
                oldBboxRect = oldBbox{b};
                newBboxRect = oldBboxRect;
                % check if possible for correlation
                xyHalfLen   = ceil(oldBboxRect(3:4)*1/5);
                xr          = oldBboxRect(1)-xyHalfLen(1):oldBboxRect(1)+oldBboxRect(3)+xyHalfLen(1);
                yr          = oldBboxRect(2)-xyHalfLen(2):oldBboxRect(2)+oldBboxRect(4)+xyHalfLen(2);
                if xr(1) < 1 || yr(1) < 1 || xr(end) > nC || yr(end) > nR, continue; end
                
                % create 5 patches from ROI
                xyCenters   = round([oldBboxRect(1:2) + oldBboxRect(3:4)./2;... % center
                    oldBboxRect(1:2) + xyHalfLen;...           % UL
                    oldBboxRect(1:2) + [oldBboxRect(3)-xyHalfLen(1) xyHalfLen(2)];... % UR
                    oldBboxRect(1:2) + oldBboxRect(3:4) - xyHalfLen;...    % LR
                    oldBboxRect(1:2) + [xyHalfLen(1) oldBboxRect(4)-xyHalfLen(2)];... % LL
                    ]);
                xt          = -xyHalfLen(1):xyHalfLen(1);
                yt          = -xyHalfLen(2):xyHalfLen(2);
                
                % compute correlation for each subregion
                img         = newVideoFrame(yr,xr,:);
                if nD > 1, img = rgb2gray(img); end
                xyOffset    = xyCenters*0;
                for m = 1:size(xyCenters,1)
                    
                    % extract small region
                    imgPatch        = oldVideoFrame(xyCenters(m,2)+yt,xyCenters(m,1)+xt,:);
                    if nD > 1, imgPatch = rgb2gray(imgPatch); end
                    
                    % corr
                    c               = normxcorr2(imgPatch,img);
                    [ypeak, xpeak]  = find(c==max(c(:)));
                    xyOffset(m,2)   = ypeak-xyHalfLen(2)-xyCenters(m,2)+yr(1)-1;
                    xyOffset(m,1)   = xpeak-xyHalfLen(1)-xyCenters(m,1)+xr(1)-1;
                    
                end
                
                % transform back to bbox : ul,ur,lr,ll
                xyCenterNew         = oldBboxRect(1:2) + oldBboxRect(3:4)/2 + mean(xyOffset);
                newBboxRect(3)      = oldBboxRect(3) + mean(xyOffset(3:4,1)) - mean(xyOffset([2 5],1));
                newBboxRect(4)      = oldBboxRect(4) + mean(xyOffset(4:5,2)) - mean(xyOffset(2:3,2));
                newBboxRect(1:2)    = xyCenterNew(1:2) - newBboxRect(3:4)/2;
                newBbox{b}          = round(newBboxRect);
                
                % debug
                %img         = imfuse(oldVideoFrame,newVideoFrame);
                imgS         = insertObjectAnnotation(imgS,'rectangle',oldBboxRect,'old');
                imgS         = insertObjectAnnotation(imgS,'rectangle',newBboxRect,'new','color','r');
                
            end
            
            % debug
            %if isdeployed, return; end
            h = findobj('tag','debug_fig_131');
            if ishandle(h)
                set(h,'cdata',imgS)
            else
                figure(131),set(gcf,'menubar','none','toolbar','none','units','normalized');
                h = imshow(imgS);set(h,'tag','debug_fig_131');
                %set(gca,'pos',[0 1 0 1]);
            end
            
            
        end
        function RoiChange_Callback(obj,hroi,hLabelEdit,hDelButton,newPos,roiIdx)
            % update obj.GTS
            newPos = round(newPos);
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes{roiIdx} = newPos;
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).types{roiIdx} = 1;
            % update delete button and label object positions
            setPosition(hroi,newPos);
            set(hDelButton,'pos',[newPos(1)+newPos(3)+obj.xDeleteOffset newPos(2)+obj.yDeleteOffset])
            set(hLabelEdit,'Position',[newPos(1)+newPos(3)/2+obj.xLabelOffset newPos(2)+newPos(4)+obj.yLabelOffset]);
            % return focus to the next figure button
            uicontrol(obj.hAddLabelsNextFrame);
        end
        function RoiEditLabel_Callback(obj,source,eventData,hLabelEdit,roiIdx)
            label = inputdlg('Rename Label');
            label = strtrim(label);
            label = matlab.lang.makeValidName(lower(label));
            if ~isempty(label)
                % Update GTS
                obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels{roiIdx} = label;
                % Update label object
                set(source,'String',label)
            end
        end
        function RoiDelete_Callback(obj,source,eventData,hroi,hLabelEdit,hDelButton,roiIdx)
            % update GTS
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes{roiIdx} = [];
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels{roiIdx} = [];
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).types{roiIdx}  = [];
            
            a =  obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes;
            a(cellfun(@(a) isempty(a),a))=[];
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes = a;
            a =  obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels;
            a(cellfun(@(a) isempty(a),a))=[];
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels = a;
            a =  obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).types;
            a(cellfun(@(a) isempty(a),a))=[];
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).types = a;
            % delete handles for visual delete
            delete(hroi);
            delete(hDelButton);
            delete(hLabelEdit);
        end
        function RoiStatistics(obj, labelName)
            % RoiStatistics - show particular ROI in the selected range of the medi files
            % Input:
            %   labelName   - which label to find
            % Output:
            %   cData     - table with image path and roi boxes
            if nargin < 1, labelName = ''; end            
            validateattributes(labelName, {'cell'}, {'nonempty'});
            % check
            mediaNum        = length(obj.GTS.MediaInfo);
            if mediaNum < 1, Print(obj,sprintf('No media data.'),'E'); return; end
            
            % max number of frames
            maxFrameNum = 0;
            for mediaIndex = 1:mediaNum
                frameNum = length(obj.GTS.MediaInfo(mediaIndex).FrameInfo);
                maxFrameNum = max(maxFrameNum,frameNum);
            end
            
            % label Number map
            labelMap        = zeros(mediaNum,maxFrameNum);
            for mediaIndex = 1:mediaNum
                frameNum        = length(obj.GTS.MediaInfo(mediaIndex).FrameInfo);
                % find non empty labels
                labelNum       = arrayfun(@(x)(length(x.labels)),obj.GTS.MediaInfo(mediaIndex).FrameInfo,'UniformOutput', true);
                labelMap(mediaIndex,1:frameNum) = labelNum;
            end
            
            % show
            figure(154)
            imagesc(labelMap),colorbar
            xlabel('Time [Frame #]'), ylabel('Media Number'),title('Labels for different medias')
            impixelinfo;
        end
        function RoiExportTrajectory(obj, labelName)
            % RoiExportTrajectory - export particular ROI in the selected range of the medi files
            % Input:
            %   labelName   - which label to find
            % Output:
            %   csvFile     - file with trajectories
            if nargin < 1, labelName = ''; end            
            validateattributes(labelName, {'char'}, {'nonempty'});
            % check
            mediaNum        = length(obj.GTS.MediaInfo);
            if mediaNum < 1, Print(obj,sprintf('No media data.'),'E'); return; end
            
            % max number of frames
            maxFrameNum = 0; columnNames = {}; validMedia = false(mediaNum,1);
            for mediaIndex = 1:mediaNum
                frameNum = length(obj.GTS.MediaInfo(mediaIndex).FrameInfo);
                maxFrameNum = max(maxFrameNum,frameNum);
                labelFrameNum       = arrayfun(@(x)(length(x.labels)),obj.GTS.MediaInfo(mediaIndex).FrameInfo,'UniformOutput', true);
                validMedia(mediaIndex) = any(labelFrameNum>0);
                [p,f,e]     = fileparts(obj.GTS.MediaInfo(mediaIndex).FileName);
                if strcmp(f,'movie_comb'),[p,f,~] = fileparts(p); end
                columnNames{mediaIndex} = f;
            end
            
            % use only valid media - that contains ROIs
            validInd        = find(validMedia);
            validNum        = length(validInd);
            if validNum < 1, obj.Print('No ROI data is found','E'); return; end
            columnNames     = columnNames(validInd);
            
            % label Number map
            labelCoord        = zeros(maxFrameNum,validNum,2); % 2-xy
            for kk = 1:validNum
                mediaIndex      = validInd(kk);
                frameNum        = length(obj.GTS.MediaInfo(mediaIndex).FrameInfo);
                % find non empty labels
                %labelFrameNum       = arrayfun(@(x)(length(x.labels)),obj.GTS.MediaInfo(mediaIndex).FrameInfo,'UniformOutput', true);
                %labelMap(1:frameNum,mediaIndex) = labelFrameNum;
                %if ~any(labelFrameNum>0), continue; end
                for fi      = 1:frameNum
                    if labelFrameNum(fi)<1,continue; end
                   % check if label belongs to this frame
                    lbl                 = labelName;
                    ind                 = find(strcmp(obj.GTS.MediaInfo(mediaIndex).FrameInfo(fi).labels,lbl));
                    if isempty(ind),continue; end
                    % create a new row once
                    bbox                = obj.GTS.MediaInfo(mediaIndex).FrameInfo(fi).bboxes{ind};
                    labelCoord(fi,kk,1) = bbox(1)+bbox(3)/2;
                    labelCoord(fi,kk,2) = bbox(2)+bbox(4)/2;
                end
            end
            
            
            % export
            saveFileName    = fullfile(obj.SessionDir,sprintf('RoiTrajectory_%s.xlsx',labelName));
            stat            = xlswrite(saveFileName,columnNames,       'X','A1');
            stat            = xlswrite(saveFileName,labelCoord(:,:,1), 'X','A2');
            stat            = xlswrite(saveFileName,columnNames,       'Y','A1');
            stat            = xlswrite(saveFileName,labelCoord(:,:,2), 'Y','A2');
            obj.Print(saveFileName);
            
            % show
            labelCoord(labelCoord < 1) = NaN;
            figure,
            plot(labelCoord(:,:,1),labelCoord(:,:,2)),set(gca,'ydir','reverse');
            xlabel('X [pix]'), ylabel('Y [pix]'),title(sprintf('Trajectories %s',labelName))
            legend(columnNames,'interpreter','none')
        end
        
        
    end
        
    %% Frame
    methods
        
        function FrameBrowserList_Callback(obj,eventData,handles)
            % if session has at least one media
            if isempty(obj.GTS.MediaInfo), return; end
            % if file browser is empty, don't do anything when user
            % clicks on empty list
            if isempty(obj.hFrameBrowserList.String), return; end

            MediaManage(obj,'frame_old',obj.hFrameBrowserList.Value);
            % add rois to axes
            source = '';
            obj.RoiAdd_Callback(source,eventData,'update')
        end
        function FrameNumber_Callback(obj,source,eventData, fIndex)
            if nargin < 4, fIndex = []; end
            % Read input frame index
            if isempty(fIndex)
                FrameIndexIn = str2double(source.String);
            else
                FrameIndexIn = fIndex;
            end
            % Bound frame index between [0 MaxFrames]
            MediaManage(obj,'frame_old',FrameIndexIn);
            source.String   = num2str(obj.FrameIndex);
            
            % add rois to axes
            obj.RoiAdd_Callback(source,eventData,'update')
        end
        function FramePrevious_Callback(obj,source,eventData)
            % if current media is valid
            if obj.MediaIndex~=0
                %  if not the first frame, navigate to the previous frame
                if obj.FrameIndex>=2
                    MediaManage(obj,'prev_old');
                    % add rois to axes
                    obj.RoiAdd_Callback(source,eventData,'update')
                end
            end
        end
        function FrameNext_Callback(obj,source,eventData)
            % if current media is valid
            if obj.MediaIndex~=0
                if obj.FrameIndex<=obj.nFrames-1
                    MediaManage(obj,'next_old');
                    % add rois to axes
                    obj.RoiAdd_Callback(source,eventData,'update')
                end
            end
        end
        function FrameNextAddLabels_Callback(obj,source,eventData,nextOrPrev)
            if nargin < 4, nextOrPrev = true; end
            assert(islogical(nextOrPrev),'nextOrPrev must be troe or false');
            % if current media is valid
            if obj.MediaIndex==0, return; end
            % the last frame
            if nextOrPrev && obj.FrameIndex==obj.nFrames, return; end
            % first frame
            if ~nextOrPrev && obj.FrameIndex==1, return; end
            
            % save previous for tracking
            oldVideoFrame       = obj.Frame;
            oldBbox             = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes;
            oldLabel            = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels;
            oldType             = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).types;
            %oldRobotPose        = obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).robotpose;
            % Update the Image Viewer
            %obj.Frame           = readFrame(obj.FR);
            %obj.Frame           = imresize(obj.Frame,[NaN,640]);
            if nextOrPrev
            MediaManage(obj,'next_old');
            else
            MediaManage(obj,'prev_old');
            end
            % Insert intersting points
%                     points              = detectMinEigenFeatures(rgb2gray(obj.Frame),'MinQuality',0.01,'FilterSize',11);
%                     frameShow           = insertMarker(obj.Frame,points.Location,'*','color','y');
%                    imshow(obj.Frame,'Parent',obj.ha);
            % try to track ROI
            newVideoFrame                       = obj.Frame;
            [obj,newBbox,newLabel,newType]      = RoiTrack(obj,oldVideoFrame,oldBbox,oldLabel,oldType,newVideoFrame);
            %[obj,newBbox]   = RoiTrackPatch(obj,oldVideoFrame,oldBbox,newVideoFrame);

            % copy and replace ROIs from previous frame
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).bboxes = newBbox;
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).labels = newLabel;
            obj.GTS.MediaInfo(obj.MediaIndex).FrameInfo(obj.FrameIndex).types = newType;
            % add ROIs to frame
            obj.RoiAdd_Callback(source,eventData,'update')
        end
        function FrameSlider_Callback(obj,source,eventData)
            FrameIndexIn   = round(get(obj.hSlider,'value'));
            % Bound frame index between [0 MaxFrames]
            MediaManage(obj,'frame_old',FrameIndexIn);
            % add rois to axes
            obj.RoiAdd_Callback(source,eventData,'update')
        end        
        function Export_Callback(obj,source,eventData)
            %openGroundTruthDoc
            SessionExport(obj)
        end
        function ZoomIn_Callback(obj,source,eventData)
            if ~isempty(obj.GTS.MediaInfo)
                if isequal(source.Value,0)
                    obj.hzoom.Enable = 'off';
                elseif isequal(source.Value,2)
                    obj.hzoom.Enable = 'on';
                end
                obj.hzoom.Direction = 'in';
                % turn off all other zoom/pan buttons
                obj.hZoomOut.Value = 0;
                obj.hPanButton.Value = 0;
            else
                errordlg('Session is empty. Please add media before using zoom functionality.');
                source.Value = 0;
            end
        end
        function ZoomOut_Callback(obj,source,eventData)
            if ~isempty(obj.GTS.MediaInfo)
                if isequal(source.Value,0)
                    obj.hzoom.Enable = 'off';
                elseif isequal(source.Value,2)
                    obj.hzoom.Enable = 'on';
                end
                obj.hzoom.Direction = 'out';
                % Turn off all other zoom/pan buttons
                obj.hZoomIn.Value = 0;
                obj.hPanButton.Value = 0;
            else
                errordlg('Session is empty. Please add media before using zoom functionality.');
                source.Value = 0;
            end
        end
        function Pan_Callback(obj,source,eventData)
            if ~isempty(obj.GTS.MediaInfo)
                if isequal(source.Value,0)
                    obj.hpan.Enable = 'off';
                elseif isequal(source.Value,2)
                    obj.hpan.Enable = 'on';
                end
                % Turn off all other zoom/pan buttons
                obj.hZoomIn.Value = 0;
                obj.hZoomOut.Value = 0;
            else
                errordlg('Session is empty. Please add media before using pan functionality.');
                source.Value = 0;
            end
        end
        
    end
    
   %% Supplementary functions
    methods
        function Print(obj,  txt, severity)
            % This manages info display and error
            if nargin < 2, txt = 'init';                 end
            if nargin < 3, severity = 'I';               end
            
            matchStr    = 'IWE'; cols = 'kbr';
            k = strfind(matchStr,severity);
            assert(k > 0,'severity must be IWE')
            
            % always print
            fprintf('%s : %6.3f : VRL : %s\n',severity,toc,txt);
            tic;
            if ~ishandle(obj.hTelemetryBar), return; end
            set(obj.hTelemetryBar,'string',txt,'ForegroundColor',cols(k));
            
        end
        function obj = NetTrain_Callback(obj, s, e)
            % check mdia
            %obj.Print(sprintf('Record is saved to %s',saveFile))

            dataType                = 101; % ask
            %netType                 = 22;
            dmCDNN                  = obj.RoiDetectManager;
            netType                 = GetValidNetType(dmCDNN);
            %dmCDNN                  = TestAndTrainSessionNetwork(dmCDNN, dataType, netType);
            dmCDNN                  = TestAndTrainLabelerNetwork(dmCDNN, dataType, netType);
            obj.RoiDetectManager    = dmCDNN;
            
        end        
    end
    
    %% Test
    methods
        
       function SetupExamples(obj)
            % Setup app examples
            load(fullfile(returnGroundTruthPath,'documentation','examples','GroundTruthSessionFull'))
            load(fullfile(returnGroundTruthPath,'documentation','examples','SensitivityAndSpecificityFull'));
            for mi = 1:length(GTS.MediaInfo)  %#ok<NODEF,PROP>
                if mi==1
                    FileName = 'buoys.jpg';
                elseif mi==2
                    FileName = 'stop.jpg';
                elseif mi==3
                    FileName = 'BuoyRun.avi';
                elseif mi==4
                    FileName = 'vipwarnsigns.avi';
                end
                FilePath = which(FileName);
                GTS.MediaInfo(mi).FileName = FilePath; %#ok<PROP>
                SAS.media(mi).FileName = FilePath; %#ok<STRNU>
            end
            save(fullfile(returnGroundTruthPath,'documentation','examples','GroundTruthSessionFull'),'GTS');
            save(fullfile(returnGroundTruthPath,'documentation','examples','SensitivityAndSpecificityFull'),'SAS');
            % Setup Automatic Ground Truth Generation Example
            load GroundTruthSessionBuoyRun
            GTS.MediaInfo(1).FileName = which('BuoyRun.avi'); %#ok<PROP>
            save(fullfile(returnGroundTruthPath,'documentation','examples','AutomaticGroundTruthGeneration','GroundTruthSessionBuoyRun'),'GTS');
            % Setup Ground Truth Session Manipulation Example
            load GroundTruthSessionBuoys
            GTS.MediaInfo(1).FileName = which('buoys.jpg'); %#ok<PROP>
            save(fullfile(returnGroundTruthPath,'documentation','examples','GroundTruthSessionManipulation','GroundTruthSessionBuoys'),'GTS');
            load GroundTruthSessionStop
            GTS.MediaInfo(1).FileName = which('stop.jpg'); %#ok<PROP>
            save(fullfile(returnGroundTruthPath,'documentation','examples','GroundTruthSessionManipulation','GroundTruthSessionStop'),'GTS');
        end        
    end
end
