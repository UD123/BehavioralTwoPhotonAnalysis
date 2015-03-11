function ListROI = TPA_TestImageRoiEditor(imageData,ListROI)
%
% TPA_TestImageRoiEditor - Graphical interface to select rectangle or/and ellipse
%             regions of interest over a picture. It's also possible
%             to move, delete, change type and color or resize the
%             selections.
%
% Used for Debug ROI
% Credits to: Jean Bilheux - November 2012 - bilheuxjm@ornl.gov
%

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 16.11 22.02.14 UD     File management instead internal function
% 16.10 22.02.14 UD     Adding splitted ROI Last amd Array - WORKING
% 16.09 21.02.14 UD     Working version imported for debug of new ROI managements
% 15.03 06.02.14 UD     Adding movie player
% 15.02 26.01.14 UD     ROI selection according to image button. Help with overlayed ROIs
% 15.01 08.01.14 UD     Adding features
% 15.00 07.01.14 UD     Merging with UserEditRoi
% 14.03 27.12.13 UD     File menu and Control buttons
% 14.02 26.12.13 UD     Changing ROI
% 13.04 25.12.13 UD     Browsing added
% 13.03 19.12.13 UD     Created
%-----------------------------

% global variable
SData.strROI        = {};

% structure with GUI handles
handStr             = [];

% structure with constants
global Par
Par                 = TPA_ParInit();

% structure for GUI management 
% GUI_STATES          = struct('INIT',1,'BROWSE_START',2,'BROWSE_ABSPOS',3,'BROWSE_DIFFPOS',4,...
%                              'DRAW_RECT',11,'DRAW_ELLIPSE',12,'DRAW_FREEHAND',13);
% GUI_STATES          = struct('INIT',0,'ROI_INIT',1,'ROI_DRAW',2,'ROI_SELECTED',3,'ROI_EDIT',4,'ROI_MOVE',5,...
%                     'BROWSE_ABSPOS',11,'BROWSE_DIFFPOS',12,'PLAYING',21);
% guiState            = GUI_STATES.INIT;  % state of the gui
% BUTTON_TYPES        = struct('NONE',1,'RECT',2,'ELLIPSE',3,'FREEHAND',4,'BROWSE',5,'PLAYER',6);
% buttonState         = BUTTON_TYPES.NONE;
% ROI_TYPES           = struct('ELLIPSE',1,'RECT',2,'FREEHAND',3);
% IMAGE_TYPES         = struct('RAW',1,'MAX',2,'MEAN',3);  % which type of image representation to support
% imageShowState      = IMAGE_TYPES.RAW;   % controls how image is displayed

GUI_STATES          = Par.GUI_STATES;
guiState            = GUI_STATES.INIT;  % state of the gui
BUTTON_TYPES        = Par.BUTTON_TYPES;
buttonState         = BUTTON_TYPES.NONE;
ROI_TYPES           = Par.ROI_TYPES;
roiInitState        = ROI_TYPES.RECT;
IMAGE_TYPES         = Par.IMAGE_TYPES;
imageShowState      = IMAGE_TYPES.RAW;   % controls how image is displayed


% active ROI
roiLast                = [];

foiLast               = []; %TPA_ManageLastRoi([],'init',roiInitState);

% contains all the rois - populated by roiLast
%roiStr                  = {};

%status of the left click
leftClick           = false;
rightClick          = false;

%are we moving the mouse with left click on ?
%motionClickWithLeftClick = false;

%used in selection of boxes
point1              = [-1 -1];
point2              = [-1 -1];

%reference position of rectangle to used when moving selection
pointRef            = [-1 -1];
%used when moving the selection
rectangleInitialPosition  = [-1 -1 -1 -1]; %rectangle to move
% used for freehand drawing and rectanglemovements
shapeInitialDrawing      = [0 0]; % coordinates of the shape

%used when moving selection
activeRectangleIndex = -1;
%previousActiveRectangleIndex = -1;

%['top','bottom','right','left','topl','topr','botl','botr','hand'
pointer             = 'crosshair'; %cursor shape

% parameter that controls sensitivity of the pointer to ROI borders        
szEdge              = 2; %pixels units

% create context menu
cntxMenu            = [];

% contain all the data
D                   = [];
activeTimeIndex     = 1;
activeZstackIndex   = 1;

% conatin motion callback
%callId              = [];

%-----------------------------------------------------
if nargin < 1
    %demoFile = 'cameraman.tif';
    load('mri.mat','D');
    imageData = D;
end
if nargin < 2,
    ListROI = {};
end

% what kind of data is there
[nR,nC,nZ,nT]       = size(imageData);
imageIn             = imageData(:,:,activeZstackIndex,activeTimeIndex); %imread(demoFile);


fCreateGUI();
fCreateRoiContextMenu();
fRefreshImage();            % show the image
fLoadROI(ListROI);          % load ROI list if any

% make it blocking
%uiwait(handStr.roiFig);
% init axes
foiLast       = [];%TPA_ManageLastRoi(foiLast,'init',ROI_TYPES.RECT);
%foiLast       = TPA_ManageLastRoi(foiLast,'initViewXY',handStr.roiAxes);


% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    function fCreateGUI()
        
        ScreenSize  = get(0,'ScreenSize');
        figWidth    = 800;
        figHeight   = 800;
        figX = (ScreenSize(3)-figWidth)/2;
        figY = (ScreenSize(4)-figHeight)/2;
        
%         roiFig  = figure('position',[figX, figY, figWidth, figHeight],...
%                         'Interruptible','off','Tag','AnalysisROI');
                    
        roiFig = figure(...
            'numbertitle', 'off',...
            'WindowStyle','normal',...
            'name','4D Image ROI Editor', ...
            'units', 'pixels',...
            'position',[figX, figY, figWidth, figHeight],... ceil(get(0,'screensize') .*[1 1 0.75 0.855] ),...
            'visible','off',...
            'menubar', 'none',...
            'toolbar','none',...
            'pointer','crosshair', ...            
            'Tag','AnalysisROI',...
            'WindowKeyPressFcn',        {@hFigure_KeyPressFcn}, ...
            'WindowButtonDownFcn',      {@hFigure_DownFcn}, ...
            'WindowButtonUpFcn',        {@hFigure_UpFcn}, ...
            'WindowButtonMotionFcn',    {@hFigure_MotionFcn}, ...
            'CloseRequestFcn',          {@fCloseRequestFcn});
        
        
        
        % UITOOLBAR
        % prepare icons
        s                       = load('TPA_ToolbarIcons.mat');
        
        
        ht                       = uitoolbar(roiFig);
        icon                     = im2double(imread(fullfile(matlabroot,'/toolbox/matlab/icons','tool_zoom_in.png')));
        icon(icon==0)            = NaN;
        uitoggletool(ht,...
            'CData',               icon,...
            'ClickedCallback',     'zoom',... @zoomIn,...
            'tooltipstring',       'ZOOM In/Out',...
            'separator',           'on');
        icon                     = im2double(imread(fullfile(matlabroot,'/toolbox/matlab/icons','tool_zoom_out.png')));
        icon(icon==0)            = NaN;
        uipushtool(ht,...
            'CData',               icon,...
            'ClickedCallback',     'zoom off',...@zoomOut,...
            'tooltipstring',       'ZOOM Out/Off');
        
       uipushtool(ht,...
            'CData',               s.ico.ml_arrow_d,...
            'separator',           'on',...            
            'ClickedCallback',     {@clickedNavToolZ,-1},...@prev,...
            'tooltipstring',       'Move down in Z stack');
       uipushtool(ht,...
            'CData',               s.ico.ml_arrow_u,...
            'ClickedCallback',     {@clickedNavToolZ,1},...@next,...
            'tooltipstring',       'Move up in Z stack ');
       uipushtool(ht,...
            'CData',               s.ico.ml_arrow_l,...
            'ClickedCallback',     {@clickedNavToolT,-1},...@prev,...
            'tooltipstring',       'Prev image in time');
       uipushtool(ht,...
            'CData',               s.ico.ml_arrow_r,...
            'ClickedCallback',     {@clickedNavToolT,1},...@next,...
            'tooltipstring',       'Next image in time');
        
        browseTool = uitoggletool(ht, 'CData', s.ico.ml_tool_hand, ...
            'State',                'on', ...
            'TooltipString',        'Browse image data in T and Z using mouse',...
            'clickedCallback',      {@clickedToolButton,BUTTON_TYPES.BROWSE},...
            'tag',                  'browse_data');
        
        playerTool = uitoggletool(ht, 'CData',s.ico.player_play, ...
            'TooltipString',        'Play a movie at constant speed', ...
            'State',                'off', ...
            'clickedCallback',      {@clickedToolButton,BUTTON_TYPES.PLAYER},...            
            'tag',                  'player');
        
        
        icon                     = im2double(imread(fullfile(matlabroot,'/toolbox/images/icons','tool_contrast.png')));
        icon(icon==0)            = NaN;
        uipushtool(ht,...
            'CData',               icon,...
            'separator',           'on',...
            'ClickedCallback',     'imcontrast(gcf)',...
            'tooltipstring',       'Image contrast adjustment');
        

        %icon                    = im2double(imread('tool_rectangle.gif'));   icon(icon==0)            = NaN;
        rectangleTool           = uitoggletool(ht, 'CData',s.ico.rectangle, ...
            'TooltipString',    'Select a rectangular ROI', ...
            'separator',        'on',...
            'State',            'off', ...
            'clickedCallback', {@clickedToolButton,BUTTON_TYPES.RECT},...            
            'tag',              'rectangle_roi');
        
        %icon                     = im2double(imread('tool_shape_ellipse.png'));   icon(icon==0)            = NaN;
        ellipseTool             = uitoggletool(ht, 'CData',s.ico.ellipse, ...
            'TooltipString',    'Select an elliptical ROI', ...
            'clickedCallback', {@clickedToolButton,BUTTON_TYPES.ELLIPSE},...            
            'tag',              'ellipse_roi');
        
        freehandTool            = uitoggletool(ht, 'CData', s.ico.freehand, ...
            'State',            'off', ...
            'Enable',           'on',...
            'TooltipString',    'Select a freehand ROI',...
            'clickedCallback', {@clickedToolButton,BUTTON_TYPES.FREEHAND},...            
            'tag',              'freehand_roi');
        
%        uipushtool(ht,...
%             'CData',               s.ico.ml_report,...
%             'ClickedCallback',     {@clickedNavToolZ,1},...@show props,...
%             'tooltipstring',       'Setup Selected ROI Properties and Parameters ');
        
        uitoggletool(ht,...
            'CData',               s.ico.win_copy,...
            'oncallback',          'warndlg(''Is yet to come'')',...@copyROIs,...
            'tooltipstring',       'Copy ROI(s): CTRL-1');
       
        uitoggletool(ht,...
            'CData',               s.ico.win_paste,...
            'oncallback',          'warndlg(''Is yet to come'')',...@pasteROIs,...
            'tooltipstring',       'Paste ROI(s): CTRL-2');
  
        uitoggletool(ht,...
            'CData',               s.ico.ml_del,...
            'oncallback',          'warndlg(''Is yet to come'')',...@deleteROIs,...
            'tooltipstring',       'Delete ALL ROI(s): CTRL-3');
        
        uitoggletool(ht,...
            'CData',               s.ico.xp_save,...
            'oncallback',          'warndlg(''Is yet to come'')',... %@saveSession,...
            'tooltipstring',       'Save/Export Session: CTRL-s',...
            'separator',           'on');
        
        helpSwitchTool              = uipushtool(ht, 'CData', s.ico.win_help, ...
            'separator',            'on',...
            'TooltipString',        'A little help about the buttons',...
            'clickedCallback',      {@clickedHelpTool},...            
            'tag',                  'help');
        exitButton                  = uipushtool(ht, 'CData', s.ico.xp_exit, ...
            'separator',            'on',...
            'clickedCallback',      {@fCloseRequestFcn},...
            'TooltipString',        'Save, Close all and Exit',...
            'tag',                  'exit');
        

        % UIMENUS
        parentFigure = ancestor(roiFig,'figure');

        % FILE Menu
        f = uimenu(parentFigure,'Label','File...');
        uimenu(f,...
            'Label','Load Image...',...
            'callback','warndlg(''Is yet to come'')'); %,...@loadImage
        uimenu(f,...
            'Label','Save/Export Image',...
            'callback','warndlg(''Is yet to come'')');%,...@saveSession
        uimenu(f,...
            'Label','Close GUI',...
            'callback',@fCloseRequestFcn);

        % Image Menu
        menuImage(1) = uimenu(parentFigure,...
            'Label','Image ...');
        menuImage(2) = uimenu(menuImage(1),...
            'Label','Raw Data',...
            'checked','on',...
            'callback',{@fUpdateImageShow,IMAGE_TYPES.RAW});
        menuImage(3) = uimenu(menuImage(1),...
            'Label','Max Projection',...
            'checked','off',...
            'callback',{@fUpdateImageShow,IMAGE_TYPES.MAX});
        menuImage(4) = uimenu(menuImage(1),...
            'Label','Mean Projection',...
            'checked','off',...
            'callback',{@fUpdateImageShow,IMAGE_TYPES.MEAN});

        % ROIs Menu
        f = uimenu(parentFigure,...
            'Label','ROI...');
        uimenu(f,...
            'Label','Add ROI',...
            'callback','warndlg(''Is yet to come'')',...@defineROI,...
            'accelerator','r');
        uimenu(f,...
            'Label','Copy ROI(s)',...
            'callback','warndlg(''Is yet to come'')',...@copyROIs,...
            'accelerator','1');%c is reserved
        uimenu(f,...
            'Label','Paste ROI(s)',...
            'callback','warndlg(''Is yet to come'')',...@pasteROIs,...
            'accelerator','2');%v is reserved
        uimenu(f,...
            'Label','Delete ROI',...
            'callback',@fRemoveMarkedRoi,...@deleteROIs,...
            'accelerator','3');
        uimenu(f,...
            'Label','Set Color',...
            'callback',@fSelectColorForRoi,...{@advanceImage,+1},...
            'accelerator','n');
        uimenu(f,...
            'Label','Rename',...
            'callback',@fRenameRoi,...{@advanceImage,-1},...
            'accelerator','p');
        uimenu(f,...
            'Label','Average Type Select',...
            'callback',@fAverageTypeRoi,...
            'accelerator','a');
        uimenu(f,...
            'Label','Toggle Zoom',...
            'callback','zoom',...
            'accelerator','z');
        uimenu(f,...
            'Label','Save/Export Session',...
            'callback','warndlg(''Is yet to come'')',...@saveSession,...
            'accelerator','s');
        
        
       
        % add callback
        %callId = iptaddcallback(roiFig, 'WindowButtonMotionFcn', {@hFigure_MotionFcn});
         %create an axes object
        roiAxes = axes();
        set(roiAxes, ...
            'tickdir','out', ...
            'drawmode','fast',...
            'position',[0 0 1 1]);
    
        roiImg          = imagesc(imageIn,'parent',roiAxes);  colormap('gray')
        roiText         = text(3,7,'User Info','BackgroundColor','w');
        
        handStr.roiFig          = roiFig;
        handStr.roiAxes         = roiAxes;
        handStr.roiImg          = roiImg;
        handStr.roiText         = roiText;
        handStr.rectangleTool   = rectangleTool;
        handStr.ellipseTool     = ellipseTool;
        handStr.freehandTool    = freehandTool;
        handStr.browseTool      = browseTool;
        handStr.playerTool      = playerTool;
        handStr.helpSwitchTool  = helpSwitchTool;
        handStr.menuImage       = menuImage;
        handStr.ico             = s.ico;
        
        
        drawnow
        
        %uiwait(roiFig);
        
    end

%-----------------------------------------------------
% Last ROI Management

   function fManageLastRoi(Cmnd,Data)
        if nargin < 2, Data = 0; end;
        
        switch Cmnd,
            
            case 'init',
                
                if strcmp(get(handStr.rectangleTool, 'State'),'on')
                        fManageLastRoi('initRect',0)
                else
                    if strcmp(get(handStr.ellipseTool, 'State'),'on')
                        fManageLastRoi('initEllipse',0)
                    else % freehand
                        fManageLastRoi('initFreehand',0)
                    end
                end;
                
                %fManageRoiArray('add',0); % add to the list               
                
            case 'initRect',
                % init new roi handle
                
                clr = 'red';
                pos = [0 0 0.1 0.1];
                % support xy shape input
                xy               = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                if numel(Data) > 4, xy = Data; end;
                pos              = [min(xy) max(xy) - min(xy)];
               
                roiLast.Type    = ROI_TYPES.RECT;
                roiLast.Active   = true;   % designates if this pointer structure is in use
                roiLast.Color    = rand(1,3);   % generate colors
                roiLast.Name     = 'Rect';
                roiLast.Position = pos;   
                roiLast.NameShow = false;       % manage show name
                roiLast.AverType = 'PointAver'; % props
                roiLast.zInd     = 1;           % location in Z stack
                roiLast.tInd     = 1;           % location in T stack
                roiLast.YT       = [];          % init view
                
                roiLast.XY.hShape  =  line('xdata',xy(:,1),'ydata',xy(:,2),...
                        'lineStyle','--',...
                        'lineWidth',1, ...
                        'Color',clr);
                roiLast.XY.hBoundBox = rectangle('position',pos,...
                        'lineStyle',':',...
                        'lineWidth',0.5, ...
                        'edgeColor',clr);
                cornerRectangles = getCornerRectangles(pos);
                for j=1:8,
                 roiLast.XY.hCornRect(j) = rectangle('position',cornerRectangles{j},...
                        'lineWidth',1, ...
                        'edgeColor',clr);
                end
                roiLast.XY.hText =  text(pos(1),pos(2),roiLast.Name,'color',roiLast.Color,'interpreter','none');  
                
                %  hide it
                set(roiLast.XY.hShape,   'visible','off')
                set(roiLast.XY.hBoundBox,'visible','off')
                set(roiLast.XY.hCornRect,'visible','off')
                set(roiLast.XY.hText,    'visible','off')
                
                % add context menu
                 set(roiLast.XY.hBoundBox,'uicontextmenu',cntxMenu)

            case 'initEllipse',
                % init new roi handle
                
                clr = 'red';
                pos = [0 0 0.1 0.1];
                % rect to xy
                xy               = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                if numel(Data) > 4, xy = Data; end;
                pos              = [min(xy) max(xy) - min(xy)];
               
                roiLast.Type    = ROI_TYPES.ELLIPSE;
                roiLast.Active   = true;   % designates if this pointer structure is in use
                roiLast.Color    = rand(1,3);   % generate colors
                roiLast.Name     = 'new ellipse';
                roiLast.Position = pos;   
                roiLast.NameShow = false;
                roiLast.AverType = 'PointAver'; % props
                roiLast.zInd     = 1;           % location in Z stack
                roiLast.tInd     = 1;           % location in T stack
                roiLast.YT       = [];          % init view
                
                
                roiLast.XY.hShape  =  line('xdata',xy(:,1),'ydata',xy(:,2),...
                        'lineStyle','--',...
                        'lineWidth',1, ...
                        'Color',clr);
                 roiLast.XY.hBoundBox = rectangle('position',pos,...
                        'lineStyle',':',...
                        'lineWidth',0.5, ...
                        'edgeColor',clr);
                        %'curvature',[1,1],...
                cornerRectangles = getCornerRectangles(pos);
                for j=1:8,
                 roiLast.XY.hCornRect(j) = rectangle('position',cornerRectangles{j},...
                        'lineWidth',1, ...
                        'edgeColor',clr);
                end
                roiLast.XY.hText =  text(pos(1),pos(2),roiLast.Name,'color',roiLast.Color,'interpreter','none');  
                
                %  hide it
                set(roiLast.XY.hShape,   'visible','off')
                set(roiLast.XY.hBoundBox,'visible','off')
                set(roiLast.XY.hCornRect,'visible','off')
                set(roiLast.XY.hText,    'visible','off')
                
                % add context menu
                 set(roiLast.XY.hBoundBox,'uicontextmenu',cntxMenu)                 
 
            case 'initFreehand',
                
                clr = 'red';
                pos = [0 0 5 5];
                % support init from load
                if numel(Data) > 4, 
                    xy           = Data; 
                    pos          = [min(xy) max(xy) - min(xy)];
                else
                    xy           = point1(1,1:2);%hFree.getPosition;
                    pos          = pos + [xy 0 0];
                end;
                
                % init new roi handle
                roiLast.Type     = ROI_TYPES.FREEHAND;
                roiLast.Active   = true;   % designates if this pointer structure is in use
                roiLast.Color    = rand(1,3);   % generate colors
                roiLast.Name     = 'FreeHand';
                roiLast.Position = pos;              
                roiLast.NameShow = false;
                roiLast.AverType = 'LineOrthog'; % props
                roiLast.zInd     = 1;           % location in Z stack
                roiLast.tInd     = 1;           % location in T stack
                roiLast.YT       = [];          % init view
                
               
                % try to init
                %freeHandPerim   = [0 0; 1 1];%hFree.getPosition;
               % pos             = pos + [xy 0 0]; % [min(freeHandPerim) max(freeHandPerim)-min(freeHandPerim)];
                roiLast.XY.hShape  = line('xdata',xy(:,1),'ydata',xy(:,2),...
                        'lineStyle','--',...
                        'lineWidth',1, ...
                        'Color',clr);
                 roiLast.XY.hBoundBox =   rectangle('position',pos,...
                        'lineStyle',':',...
                        'lineWidth',0.5, ...
                        'edgeColor',clr);
                cornerRectangles = getCornerRectangles(pos);
                for j=1:8,
                 roiLast.XY.hCornRect(j) = rectangle('position',cornerRectangles{j},...
                        'lineWidth',1, ...
                        'edgeColor',clr);
                end
                roiLast.XY.hText =  text(pos(1),pos(2),roiLast.Name,'color',roiLast.Color,'interpreter','none');  
                    
                
                %  hide it
                set(roiLast.XY.hShape,   'visible','off')
                set(roiLast.XY.hBoundBox,'visible','off')
                set(roiLast.XY.hCornRect,'visible','off')
                set(roiLast.XY.hText,    'visible','off')
                
                % add context menu
                 set(roiLast.XY.hBoundBox,'uicontextmenu',cntxMenu)

            case 'addPoint',
                % add point to a freehand line
                newPoint                = Data;
                if isempty(newPoint), return; end;
                
                xData                   = [get(roiLast.XY.hShape,'xdata') newPoint(1)];
                yData                   = [get(roiLast.XY.hShape,'ydata') newPoint(2)];
                set(roiLast.XY.hShape,'xdata',xData,'ydata',yData ,'color','b');
                
                % no scaling after position set
                roiLast.Position        = [min(xData) min(yData) max(xData)-min(xData) max(yData)-min(yData)];
                
                %  show it
                set(roiLast.XY.hShape,   'visible','on')                                
                 
            case 'setPos',
                % redraw the last ROI object pos
                pos                     = Data;
                
                 switch roiLast.Type,
                     case ROI_TYPES.RECT,
                        xy          = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                     case ROI_TYPES.ELLIPSE,
                        xyr         = pos(3:4)/2;        % radius
                        xyc         = pos(1:2)+ xyr;     % center
                        tt          = linspace(0,2*pi,30)';
                        xy          = [cos(tt)*xyr(1) + xyc(1), sin(tt)*xyr(2) + xyc(2)];
                     case ROI_TYPES.FREEHAND,
                        pos_old     = rectangleInitialPosition;
                        xy_old      = shapeInitialDrawing;
                        % rescale
                        xyc         = pos(1:2)      + pos(3:4)/2;     % center
                        xyc_old     = pos_old(1:2)  + pos_old(3:4)/2;     % center
                        x           = (xy_old(:,1) - xyc_old(1))*pos(3)/(eps+pos_old(3)) + xyc(1);
                        y           = (xy_old(:,2) - xyc_old(2))*pos(4)/(eps+pos_old(4)) + xyc(2); 
                        xy          = [x(:) y(:)];
                 end;
                roiLast.Position        = pos; %[x,y,w,h]
                %[pos;pos_old]
                
                % rect to xy
                set(roiLast.XY.hShape,     'xdata',xy(:,1),'ydata',xy(:,2),'visible','on');
                set(roiLast.XY.hBoundBox,  'position',roiLast.Position,'visible','on');
                cornerRectangles        = getCornerRectangles(roiLast.Position);
                for j=1:8,
                    set(roiLast.XY.hCornRect(j), 'position',cornerRectangles{j},'visible','on');
                end
                set(roiLast.XY.hText,'pos',roiLast.Position(1:2)+[5,5], 'visible','on')
                
            case 'setClr',
                % redraw the last ROI object pos
                clr                 = Data;
                roiLast.Color       = clr;   % remember
                set(roiLast.XY.hShape,     'Color',    clr);
                set(roiLast.XY.hBoundBox,  'edgeColor',clr);
                set(roiLast.XY.hCornRect,  'edgeColor',clr);
                set(roiLast.XY.hText,      'color',    clr)
               
            case 'setName',
                % redraw the last ROI object pos
                roiLast.Name        = Data;   % remember
                set(roiLast.XY.hText,  'string', roiLast.Name,   'visible','on')
                              
             case 'setAverType',
                % properties for the subsequent processing
                roiLast.AverType        = Data;   % remember               
                
            case 'setZInd',
                % stack position
                roiLast.zInd            = Data;
                
            case 'setTInd',
               roiLast.tInd             = Data;           % location in T stack
                                
            case 'clean',
                % delete graphics of the lastROI
                if activeRectangleIndex < 1, return; end;
                
                %remove the rectangle at the index given
                delete(roiLast.XY.hShape);
                delete(roiLast.XY.hBoundBox);
                delete(roiLast.XY.hCornRect);
                delete(roiLast.XY.hText);
               
                activeRectangleIndex = -1;
                
            case 'updateView',

                % redraw XY view according to info from YT view
                
                % check if YT is initialized
                if ~isfield(roiLast.YT,'hBoundBox'), return; end;
                
                % extract Y length from YT space
                posXY                = get(roiLast.XY.hBoundBox,'pos');
                posYT                = get(roiLast.YT.hBoundBox,'pos');
                
                % position is defined by 
                posXY([2 4])         = posYT([2 4]);
                
                % redefine the shape
                fManageLastRoi('setPos',posXY);                
                % update color
                fManageLastRoi('setClr',roiLast.Color);                
 
            case 'createView',

                % redraw XY view according to info from YT view
                
                % check if YT is initialized
                %if ~isfield(roiLast.YT,'hBoundBox'), return; end;
                if ~isfield(roiLast.YT,'hBoundBox'), return; end;
                
                % extract Y length from YT space
                posYT                = get(roiLast.YT.hBoundBox,'pos');
                
                % position is defined by 
                posXY([2 4])         = posYT([2 4]);
                posXY([1 3])         = [10 nC-20];    
                
               switch roiLast.Type,
                     case ROI_TYPES.ELLIPSE,
                        curv           = [1,1]; % curvature
                    otherwise
                        curv           = [0,0]; % curvature
                end;
                
                
                % init shapes
                pos                  = posXY;
                xy                   = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];                
                clr                 = 'y';
                roiLast.XY.hShape  =  line('xdata',xy(:,1),'ydata',xy(:,2),...
                        'lineStyle','--',...
                        'lineWidth',1, ...
                        'Color',clr);
                roiLast.XY.hBoundBox = rectangle('position',pos,...
                        'lineStyle',':',...
                        'lineWidth',0.5, ...
                        'curvature',curv,...                       
                        'edgeColor',clr);
                cornerRectangles = getCornerRectangles(pos);
                for j=1:8,
                 roiLast.XY.hCornRect(j) = rectangle('position',cornerRectangles{j},...
                        'lineWidth',1, ...
                        'edgeColor',clr);
                end
                roiLast.XY.hText =  text(pos(1),pos(2),roiLast.Name,'color',roiLast.Color,'interpreter','none');  
                
                %  hide it
                set(roiLast.XY.hShape,   'visible','off')
                set(roiLast.XY.hBoundBox,'visible','off')
                set(roiLast.XY.hCornRect,'visible','off')
                set(roiLast.XY.hText,    'visible','off')
                
                % add context menu
                 set(roiLast.XY.hBoundBox,'uicontextmenu',cntxMenu)
                
                
                % redefine the shape
                fManageLastRoi('setPos',posXY);                
                % update color
                fManageLastRoi('setClr',roiLast.Color);                
                
                
                                               
            otherwise
                error('Unknown Cmnd : %s',Cmnd)

        end
   end

%-----------------------------------------------------
% Array ROI Management

   function fManageRoiArray(Cmnd,Data)
       % manage list of ROIs
        if nargin < 2, Data = 0; end;
        
        switch Cmnd,
                                           
            case 'copyFromList',
                % redraw the last ROI object pos
                activeIndx              = Data;
                roiNum                  = length(SData.strROI);
                if activeIndx < 1 || activeIndx > roiNum, error('Bad value for activeIndx'); end;
                
                roiLast                 = SData.strROI{activeIndx};
                SData.strROI{activeIndx}.Active = false;
                
                switch roiLast.Type,
                     case ROI_TYPES.ELLIPSE,
                        curv           = [1,1]; % curvature
                    otherwise
                        curv           = [0,0]; % curvature
                end;
                

                clr                     = SData.strROI{activeIndx}.Color; showOnOff = 'on';
                set(roiLast.XY.hShape,     'color',    clr,'visible',showOnOff);
                set(roiLast.XY.hBoundBox,  'edgeColor',clr,'visible',showOnOff, 'curvature', curv);
                set(roiLast.XY.hCornRect,  'edgeColor',clr,'visible',showOnOff);
                set(roiLast.XY.hText,      'color',    clr,'visible',showOnOff)
                
                foiLast   = TPA_ManageLastRoi(foiLast,'setColor',clr);
                foiLast   = TPA_ManageLastRoi(foiLast,'OnOffBoundBox',1);
                
                % gui support
                rectangleInitialPosition    = SData.strROI{activeIndx}.Position;
                shapeInitialDrawing         = [get(roiLast.XY.hShape,'xdata')' get(roiLast.XY.hShape,'ydata')']; 

                foiLast   = TPA_ManageLastRoi(foiLast,'saveInitRef',rectangleInitialPosition);
                
                % sync -  change color
                %%fSyncSend(Par.EVENT_TYPES.UPDATE_ROI);                
                

            case 'copyToList',
                % redraw the last ROI object pos
                activeIndx              = Data;
                roiNum                  = length(SData.strROI);
                if activeIndx < 1 || activeIndx > roiNum, error('Bad value for activeIndx'); end;
                
                % update shape - important for circles and freehand
                fManageLastRoi('setPos',roiLast.Position);
                foiLast   = TPA_ManageLastRoi(foiLast,'setPosXY',foiLast.Position);
                
                % update name
                fManageLastRoi('setName',sprintf('ROI:%2d Z:%d %s',activeIndx,roiLast.zInd,roiLast.AverType));                
                foiLast   = TPA_ManageLastRoi(foiLast,'setName',sprintf('FOI:%2d ',activeIndx));
               
                
                SData.strROI{activeIndx}      = roiLast;
                clr                     = 'y';
                set(SData.strROI{activeIndx}.XY.hShape,     'Color',     clr,'visible','on');
                set(SData.strROI{activeIndx}.XY.hBoundBox,  'edgeColor', clr,'visible','off', 'curvature', [0,0]);
                set(SData.strROI{activeIndx}.XY.hCornRect,  'edgeColor', clr,'visible','off');
                set(SData.strROI{activeIndx}.XY.hText,      'color',     clr,'visible','on')
                SData.strROI{activeIndx}.Active = true;
                
                foiLast   = TPA_ManageLastRoi(foiLast,'OnOffBoundBox',0);

                
                % not in use any more
                %activeRectangleIndex   = 0;      
                % sync
                %%fSyncSend(Par.EVENT_TYPES.UPDATE_ROI);                
                
 
            case 'delete',
                % delete from list
                activeIndx              = Data;
                roiNum                  = length(SData.strROI);
                if activeIndx < 1 || activeIndx > roiNum, error('Bad value for activeIndx'); end;
                
                %remove the rectangle at the index given
                delete(SData.strROI{activeIndx}.XY.hShape);
                delete(SData.strROI{activeIndx}.XY.hBoundBox);
                delete(SData.strROI{activeIndx}.XY.hCornRect);
                delete(SData.strROI{activeIndx}.XY.hText);
                if ~isempty(SData.strROI{activeIndx}.YT),
                delete(SData.strROI{activeIndx}.YT.hShape);
                delete(SData.strROI{activeIndx}.YT.hBoundBox);
                delete(SData.strROI{activeIndx}.YT.hCornRect);
                delete(SData.strROI{activeIndx}.YT.hText);
                end
                SData.strROI(activeIndx)      = [];
                
                foiLast   = TPA_ManageLastRoi(foiLast,'removeHandles',0);
                
                
                % sync
                %%fSyncSend(Par.EVENT_TYPES.UPDATE_ROI);                
                
                               
            case 'add',

               %add the last rectangle ROI to the list of Rectangle ROIs
                
                activeIndx              = length(SData.strROI) + 1;
                
                % update name
                fManageLastRoi('setName',sprintf('ROI:%2d Z:%d %s',activeIndx,roiLast.zInd,roiLast.AverType));
                 foiLast   = TPA_ManageLastRoi(foiLast,'setName',sprintf('FOI:%2d ',activeIndx));
               
                
                SData.strROI{activeIndx}      = roiLast;
                clr                     = 'r';
                set(SData.strROI{activeIndx}.XY.hShape,     'Color',     clr,'visible','on');
                set(SData.strROI{activeIndx}.XY.hBoundBox,  'edgeColor', clr,'visible','on');
                set(SData.strROI{activeIndx}.XY.hCornRect,  'edgeColor', clr,'visible','on');
                set(SData.strROI{activeIndx}.XY.hText,      'color',     clr,'visible','on');
                
                foiLast   = TPA_ManageLastRoi(foiLast,'OnOffShape',1);
                foiLast   = TPA_ManageLastRoi(foiLast,'setColor',clr);
                        
                
                % when added - still selected
                activeRectangleIndex     = activeIndx;
                rectangleInitialPosition = roiLast.Position; % no scaling
                shapeInitialDrawing      = [get(roiLast.XY.hShape,'xdata')' get(roiLast.XY.hShape,'ydata')']; 
 
                foiLast   = TPA_ManageLastRoi(foiLast,'saveInitRef',1);
                
                
                % update shape - important for circles and freehand
                fManageLastRoi('setPos',roiLast.Position);
                
                 foiLast   = TPA_ManageLastRoi(foiLast,'setPosXY',foiLast.XY.pos);
               
                
                % sync
                %%fSyncSend(Par.EVENT_TYPES.UPDATE_ROI);                
            
           case 'updateView',
               
               % check if any rectangle is under editing : return it back
               if activeRectangleIndex > 0,
                   fManageRoiArray('copyToList',activeRectangleIndex);
                   activeRectangleIndex   = 0; 
               end

                % update view if it has been updated by other window
                roiNum                  = length(SData.strROI);
                for activeIndx = 1:roiNum,
                    
                    % unknown effect -  it will flicker
                    fManageRoiArray('copyFromList',activeIndx);                    
                    
                    % update shape - important for circles and freehand
                    fManageLastRoi('updateView',activeIndx);
                    
                    % unknown effect -  it will flicker
                    fManageRoiArray('copyToList',activeIndx);                    
                    
                end
                %%fSyncSend(Par.EVENT_TYPES.UPDATE_ROI);
                
          case 'createView',
               % designed to init the structure when opened second
               % check if any rectangle is under editing : return it back
               if activeRectangleIndex > 0,
                   fManageRoiArray('copyToList',activeRectangleIndex);
               end

                % update view if it has been updated by other window
                roiNum                  = length(SData.strROI);
                for activeIndx = 1:roiNum,
                    
                    % do it simple since shapes are not initialized
                   % fManageRoiArray('copyFromList',activeIndx);    
                    roiLast            = SData.strROI{activeIndx};                   
                    
                    % update shape - important for circles and freehand
                    fManageLastRoi('createView',activeIndx);
                    
                    % unknown effect -  it will flicker
                    fManageRoiArray('copyToList',activeIndx);                    
                    
                end
                %%fSyncSend(Par.EVENT_TYPES.UPDATE_ROI); 
                
            otherwise
                error('Unknown Cmnd : %s',Cmnd)

        end
   end



%-----------------------------------------------------
% ROI Input & Output

    function fLoadROI(preLoadedRoi)
        %This function will parse the ROI from the main gui roi list
        %and populates the roiSelection and roiSelectionType
        
        nbrRow = length(preLoadedRoi);
        for i=1:nbrRow,
            
            % set selec tool - rectangular
            %clickedRectangleTool();
            
            % load it to temp ROI and then copy to the pool
            %fManageLastRoi('init',0);
            
            
            % support roi types
            currentRoiType              = ROI_TYPES.RECT;
            if isfield(preLoadedRoi{i},'type'),
                currentRoiType          = preLoadedRoi{i}.type;
            end;
%             if ~any(strcmp(currentRoiType,ROI_TYPES)),
%                 warndlg(sprintf('ROI %d does not contain valid ROI field',i));
%                 currentRoiType              = ROI_TYPES.ELLIPSE;
%             end;
            roiLast.Type                = currentRoiType;
            
            currentXY                   = [1 1; 1 10;10 10;10 1; 1 1];
            if isfield(preLoadedRoi{i},'xy')
            currentXY                   = preLoadedRoi{i}.xy;
            end
            
            switch currentRoiType,
                case ROI_TYPES.RECT,
                    fManageLastRoi('initRect',currentXY);
                case ROI_TYPES.ELLIPSE,
                    fManageLastRoi('initEllipse',currentXY);
                case ROI_TYPES.FREEHAND,
                    fManageLastRoi('initFreehand',currentXY);
            end
            %Position                    = [currentXY(1,1:2) diff(currentXY(2:3,1)) diff(currentXY(1:2,2))];
            %fManageLastRoi('setPos',Position);

            
            % support colors
             currentRoiColor              = rand(1,3);
            if isfield(preLoadedRoi{i},'color'),
                currentRoiColor          = preLoadedRoi{i}.color;
            end;
            fManageLastRoi('setClr',currentRoiColor);
           
                        
             % support name
             currentRoiName              = sprintf('C_%02d',i);
            if isfield(preLoadedRoi{i},'name'),
                currentRoiName          = preLoadedRoi{i}.name;
            end;
            fManageLastRoi('setName',currentRoiName);
            
             % support average type
            currentRoiAverType              = 'PointAver';
            if isfield(preLoadedRoi{i},'averType'),
                currentRoiAverType          = preLoadedRoi{i}.averType;
            end;
            fManageLastRoi('setAverType',currentRoiAverType);

             % support Z Index 
            currentRoiZInd              = 1;
            if isfield(preLoadedRoi{i},'zInd'),
                currentRoiZInd          = preLoadedRoi{i}.zInd;
            end;
            fManageLastRoi('setZInd',currentRoiZInd);
            
            
            % add to the pool
            fManageLastRoi('add',0)

        end

        activeRectangleIndex = -1; % none is selected
    end

    function roiList = fExportROI(roiList)
       
        return
        %this will format the roi for the main gui ROI list
        %[10,20,30,40] -> "r:10,20,30,40" for a rectangle
        %[20,30,40,50] -> "c:20,30,40,50" for an ellipse
        sz      = length(roiStr);
        [Y,X]   = meshgrid(1:nR,1:nC);
        %roiList = {};        
        for i=1:sz,
            
            % check for problems
            if ~ishandle(roiStr{i}.hShape),
                continue;
            end
            
            %pos                 = SData.strROI{i}.Position;
            xy                  = [get(SData.strROI{i}.XY.hShape,'xdata')' get(SData.strROI{i}.XY.hShape,'ydata')'];
            roiList{i}.xy       = xy; %[pos(1:2); pos(1:2)+[0 pos(4)];pos(1:2)+pos(3:4);pos(1:2)+[pos(3) 0]];
            roiList{i}.type     = SData.strROI{i}.Type;
            roiList{i}.color    = SData.strROI{i}.Color;
            %roiList{i}.name     = SData.strROI{i}.Name;
            roiList{i}.name     = sprintf('ROI:%2d Z:%d %s',i,SData.strROI{i}.zInd,SData.strROI{i}.AverType);
            roiList{i}.averType = SData.strROI{i}.AverType;
            roiList{i}.zInd     = SData.strROI{i}.zInd;
            % actual indexes
            maskIN              = inpolygon(X,Y,xy(:,1),xy(:,2));
            roiList{i}.BW       = maskIN;
            
        end
    end

%-----------------------------------------------------
% ROI Position

   function [yesItIs, index, isEdge, whichEdge_trbl] = isMouseOverRectangle()
        %this function will determine if the mouse is
        %currently over a previously selected Rectangle
        %
        %yesItIs: true or false
        %index; if yesItIs, returns the index of the rectangle selected
        %isEdge: true or false (are we over the rectangle, or just the
        % edge). Just the edge means that the rectangle will be resized
        % when over the center will mean replace it !
        %whichEdge: 'top', 'left', 'bottom' or 'right' or combination of
        % 'top-left'...etc
        
        yesItIs = false;
        index = -1;
        isEdge = false;
        whichEdge_trbl = [false false false false];
        
        point = get(handStr.roiAxes, 'CurrentPoint');
        
        sz = length(SData.strROI);
        for i=1:sz
            [isOverRectangle, isEdge, whichEdge_trbl] = isMouseOverEdge(point, SData.strROI{i}.Position);
            if isOverRectangle, % && SData.strROI{i}.Active, % Active helps when one of the rectangles is under editing
                % check if the selection tool fits SData.strROI{i}.Type
                switch buttonState,
                    case BUTTON_TYPES.RECT,
                            if SData.strROI{i}.Type ~= ROI_TYPES.RECT,
                                continue;
                            end
                    case BUTTON_TYPES.ELLIPSE
                            if SData.strROI{i}.Type ~= ROI_TYPES.ELLIPSE,
                                continue;
                            end
                   case BUTTON_TYPES.FREEHAND
                            if SData.strROI{i}.Type ~= ROI_TYPES.FREEHAND,
                                continue;
                            end
                   otherwise
                        % nothing is sellected
                        continue
                end                
                yesItIs = true;
                index = i;
                break
            end
        end
        
    end

   function [result, isEdge, whichEdge_trbl] = isMouseOverEdge(point, rectangle)
        %check if the point(x,y) is over the edge of the
        %rectangle(x,y,w,h)
        
        
        result = false;
        isEdge = false;
        whichEdge_trbl = [false false false false]; %top right bottom left
        
        xMouse = point(1,1);
        yMouse = point(1,2);
        
        xminRect = rectangle(1);
        yminRect = rectangle(2);
        xmaxRect = rectangle(3)+xminRect;
        ymaxRect = rectangle(4)+yminRect;
        
        %is inside rectangle
        if (yMouse > yminRect-szEdge && ...
                yMouse < ymaxRect+szEdge && ...
                xMouse > xminRect-szEdge && ...
                xMouse < xmaxRect+szEdge)
            
            %is over left edge
            if (yMouse > yminRect-szEdge && ...
                    yMouse < ymaxRect+szEdge && ...
                    xMouse > xminRect-szEdge && ...
                    xMouse < xminRect+szEdge)
                
                isEdge = true;
                whichEdge_trbl(4) = true;
            end
            
            %is over bottom edge
            if (xMouse > xminRect-szEdge && ...
                    xMouse < xmaxRect+szEdge && ...
                    yMouse > ymaxRect-szEdge && ...
                    yMouse < ymaxRect+szEdge)
                
                isEdge = true;
                whichEdge_trbl(3) = true;
            end
            
            %is over right edge
            if (yMouse > yminRect-szEdge && ...
                    yMouse < ymaxRect+szEdge && ...
                    xMouse > xmaxRect-szEdge && ...
                    xMouse < xmaxRect+szEdge)
                
                isEdge = true;
                whichEdge_trbl(2) = true;
            end
            
            %is over top edge
            if (xMouse > xminRect-szEdge && ...
                    xMouse < xmaxRect+szEdge && ...
                    yMouse > yminRect-szEdge && ...
                    yMouse < yminRect+szEdge)
                
                isEdge = true;
                whichEdge_trbl(1) = true;
            end
            
            result = true;
            
        end
        
    end

   function cornerRectangles = getCornerRectangles(currentRectangle)
        %this function will create a [8x4] array of the corner
        %rectangles used to show the user that it can resize the ROI
        
        cornerRectangles = {};
        
        x = currentRectangle(1);
        y = currentRectangle(2);
        w = currentRectangle(3);
        h = currentRectangle(4);
        
        units=get(handStr.roiFig,'units');
        set(handStr.roiFig,'units','pixels');
        roiFigPosition      = get(handStr.roiFig,'position');
        roiFigWidth         = roiFigPosition(3);
        roiFigHeight        = roiFigPosition(4);
        set(handStr.roiFig,'units',units);
        
        wBox = roiFigWidth/200;
        hBox = roiFigHeight/200;
        
        %tl corner
        x1 = x - wBox/2;
        y1 = y - hBox/2;
        cornerRectangles{1} = [x1,y1,wBox,hBox];
        
        %t (middle of top edge) corner
        x2 = x + w/2 - wBox/2;
        y2 = y - wBox/2;
        cornerRectangles{2} = [x2,y2,wBox,hBox];
        
        %tr corner
        x3 = x + w - wBox/2;
        y3 = y - hBox/2;
        cornerRectangles{3} = [x3,y3,wBox,hBox];
        
        %r (middle of right edge) corner
        x4 = x + w - wBox/2;
        y4 = y + h/2 - hBox/2;
        cornerRectangles{4} = [x4,y4,wBox,hBox];
        
        %br corner
        x5 = x + w - wBox/2;
        y5 = y + h - hBox/2;
        cornerRectangles{5} = [x5,y5,wBox,hBox];
        
        %b (middle of bottom edge) corner
        x6 = x + w/2 - wBox/2;
        y6 = y + h - hBox/2;
        cornerRectangles{6} = [x6,y6,wBox,hBox];
        
        %bl corner
        x7 = x - wBox/2;
        y7 = y + h - hBox/2;
        cornerRectangles{7} = [x7,y7,wBox,hBox];
        
        %l (middle of left edge) corner
        x8 = x - wBox/2;
        y8 = y + h/2 - hBox/2;
        cornerRectangles{8} = [x8,y8,wBox,hBox];
        
    end

   function drawLiveRectangle()
        %draw a rectangle live with mouse moving
        
        %motionClickWithLeftClick = true;
        units = get(handStr.roiAxes,'units');
        set(handStr.roiAxes,'units','normalized');
        point2 = get(handStr.roiAxes, 'CurrentPoint');
        
        x = min(point1(1,1),point2(1,1));
        y = min(point1(1,2),point2(1,2));
        w = abs(point1(1,1)-point2(1,1));
        h = abs(point1(1,2)-point2(1,2));
        if w == 0
            w=1;
        end
        if h == 0
            h=1;
        end
        
        %save rectangle
        roiLast.Position = [x y w h];
        %fRefreshImage (); %plot the image
        fManageLastRoi('setPos',[x,y,w,h]);
        fManageLastRoi('setClr','blue');
        
                          
        foiLast   = TPA_ManageLastRoi(foiLast,'setPosXY',[x,y,w,h]);
        foiLast   = TPA_ManageLastRoi(foiLast,'setColor','g');
      
        
        set(handStr.roiAxes,'units',units);
        
    end

   function drawLiveEllipse()
       % ellipse is generated by rectangle with curvature
       drawLiveRectangle();

    end

   function drawLiveFreehand()
        %draw a freehand shape with mouse moving
        
        %motionClickWithLeftClick = true;
        units = get(handStr.roiAxes,'units');
        set(handStr.roiAxes,'units','normalized');
        point2 = get(handStr.roiAxes, 'CurrentPoint');
        
        %fRefreshImage (); %plot the image
        fManageLastRoi('addPoint',point2(1,1:2));
        fManageLastRoi('setClr','blue');
        
        foiLast   = TPA_ManageLastRoi(foiLast,'addPoint',point2(1,1:2));
        foiLast   = TPA_ManageLastRoi(foiLast,'setColor','g');
        
        
        set(handStr.roiAxes,'units',units);
        
    end

    function moveLiveRectangle()
        %will move the rectangle selection
        
        %motionClickWithLeftClick = true;
        units = get(handStr.roiAxes,'units');
        set(handStr.roiAxes,'units','normalized');
        %point2 = get(handStr.roiAxes, 'CurrentPoint');
        
        
        %current mouse position
        curMousePosition = get(handStr.roiAxes,'CurrentPoint');
        
        %offset to apply
        deltaX = curMousePosition(1,1) - pointRef(1,1);
        deltaY = curMousePosition(1,2) - pointRef(1,2);
        
        roiLast.Position(1) = rectangleInitialPosition(1) + deltaX;
        roiLast.Position(2) = rectangleInitialPosition(2) + deltaY;
        
        
        %fRefreshImage();
        fManageLastRoi('setPos',roiLast.Position);
        fManageLastRoi('setClr','red');
        
        foiLast   = TPA_ManageLastRoi(foiLast,'setPosXY',roiLast.Position);
        foiLast   = TPA_ManageLastRoi(foiLast,'setColor','g');
        
        set(handStr.roiAxes,'units',units);

        
    end

    function moveEdgeRectangle()
        %will resize the rectangle by moving the left, right, top
        %or bottom edge
        
        %motionClickWithLeftClick = true;
        units = get(handStr.roiAxes,'units');
        set(handStr.roiAxes,'units','normalized');
        %point2 = get(handStr.roiAxes, 'CurrentPoint');
        
        %current mouse position
        curMousePosition = get(handStr.roiAxes,'CurrentPoint');
        
        %FIXME
        %make sure the program does not complain when width or height
        %becomes 0 or negative
        
        minWH = 1;  %rectangle is at least minWH pixels width and height
        
        switch pointer
            case 'left'
                
                %offset to apply
                deltaX = curMousePosition(1,1) - pointRef(1,1);
                
                roiLast.Position(1) = rectangleInitialPosition(1) + deltaX;
                roiLast.Position(3) = rectangleInitialPosition(3) - deltaX;
                if roiLast.Position(3) <= minWH
                    roiLast.Position(3) = minWH;
                end
                
            case 'right'
                
                %offset to apply
                deltaX = curMousePosition(1,1) - pointRef(1,1);
                
                roiLast.Position(3) = rectangleInitialPosition(3) + deltaX;
                
            case 'top'
                
                %offset to apply
                deltaY = curMousePosition(1,2) - pointRef(1,2);
                
                roiLast.Position(2) = rectangleInitialPosition(2) + deltaY;
                roiLast.Position(4) = rectangleInitialPosition(4) - deltaY;
                
            case 'bottom'
                
                %offset to apply
                deltaY = curMousePosition(1,2) - pointRef(1,2);
                
                roiLast.Position(4) = rectangleInitialPosition(4) + deltaY;
                
            case 'topl'
                
                %offset to apply
                deltaY = curMousePosition(1,2) - pointRef(1,2);
                deltaX = curMousePosition(1,1) - pointRef(1,1);
                
                roiLast.Position(1) = rectangleInitialPosition(1) + deltaX;
                roiLast.Position(3) = rectangleInitialPosition(3) - deltaX;
                roiLast.Position(2) = rectangleInitialPosition(2) + deltaY;
                roiLast.Position(4) = rectangleInitialPosition(4) - deltaY;
                
            case 'topr'
                
                %offset to apply
                deltaX = curMousePosition(1,1) - pointRef(1,1);
                deltaY = curMousePosition(1,2) - pointRef(1,2);
                
                roiLast.Position(3) = rectangleInitialPosition(3) + deltaX;
                roiLast.Position(2) = rectangleInitialPosition(2) + deltaY;
                roiLast.Position(4) = rectangleInitialPosition(4) - deltaY;
                
            case 'botl'
                
                %offset to apply
                deltaY = curMousePosition(1,2) - pointRef(1,2);
                deltaX = curMousePosition(1,1) - pointRef(1,1);
                
                roiLast.Position(1) = rectangleInitialPosition(1) + deltaX;
                roiLast.Position(3) = rectangleInitialPosition(3) - deltaX;
                roiLast.Position(4) = rectangleInitialPosition(4) + deltaY;
                
            case 'botr'
                
                %offset to apply
                deltaY = curMousePosition(1,2) - pointRef(1,2);
                deltaX = curMousePosition(1,1) - pointRef(1,1);
                
                roiLast.Position(3) = rectangleInitialPosition(3) + deltaX;
                roiLast.Position(4) = rectangleInitialPosition(4) + deltaY;
                
        end
        
        %make sure we have the minimum width and height requirements
        if roiLast.Position(3) <= minWH
            roiLast.Position(3) = minWH;
        end
        if roiLast.Position(4) <= minWH
            roiLast.Position(4) = minWH;
        end
        % dbg
        %roiLast.Position
        
        %fRefreshImage();
        fManageLastRoi('setPos',roiLast.Position);
        fManageLastRoi('setClr','red');
        
        foiLast   = TPA_ManageLastRoi(foiLast,'setPosXY',roiLast.Position);
        foiLast   = TPA_ManageLastRoi(foiLast,'setColor','g');
        
        set(handStr.roiAxes,'units',units);
        
        
    end

    function showEdgeRectangle()
        % will change pointer to different shapes over selected rectangle
        
%         if activeRectangleIndex < 1, 
%             error('Sometyhing wrong with state management. Must be in state with rect selected')
%         end;
        
        
        [yesItIs, index, isEdge, whichEdge_trbl] = isMouseOverRectangle();
        if yesItIs && activeRectangleIndex == index %change color of this rectangle

            pointer = 'hand';
            if isEdge

                if isequal(whichEdge_trbl,[true false false false])
                    pointer = 'top';
                end
                if isequal(whichEdge_trbl,[false true false false])
                    pointer = 'right';
                end
                if isequal(whichEdge_trbl,[false false true false])
                    pointer = 'bottom';
                end
                if isequal(whichEdge_trbl,[false false false true])
                    pointer = 'left';
                end
                if isequal(whichEdge_trbl,[true true false false])
                    pointer = 'topr';
                end
                if isequal(whichEdge_trbl,[true false false true])
                    pointer = 'topl';
                end
                if isequal(whichEdge_trbl,[false true true false])
                    pointer = 'botr';
                end
                if isequal(whichEdge_trbl,[false false true true])
                    pointer = 'botl';
                end
            end
        else
            %activeRectangleIndex = -1;
            pointer = 'crosshair';
        end
        set(handStr.roiFig, 'pointer',pointer);
        
    end


%-----------------------------------------------------
% Mouse Motion

    function hFigure_MotionFcn(~, ~)
        %This function is reached any time the mouse is moving over the figure
        
       switch guiState,
           case GUI_STATES.INIT, 
                % do nothing
           case GUI_STATES.BROWSE_ABSPOS,
               % go to the next state
                if leftClick %we need to draw something                  
                    guiState = GUI_STATES.BROWSE_DIFFPOS;
                end
           case GUI_STATES.BROWSE_DIFFPOS,               
               % draw now roi
                if leftClick %we need to draw something               
                  fUpdateBrowseData();
                end
           
           case GUI_STATES.ROI_INIT, 
                % do nothing
           case GUI_STATES.ROI_DRAW,
               % draw now roi
                if leftClick %we need to draw something 
                 switch roiLast.Type,
                     case ROI_TYPES.RECT,
                        drawLiveRectangle();
                     case ROI_TYPES.ELLIPSE,
                        drawLiveEllipse();
                     case ROI_TYPES.FREEHAND,
                        drawLiveFreehand();
                 end;
                end
                
                
           case GUI_STATES.ROI_MOVE,
                if leftClick %we need to draw something               
                   moveLiveRectangle();
                end
               
              
           case GUI_STATES.ROI_SELECTED,
               % change pointer over selected ROI
               showEdgeRectangle();
               
           case GUI_STATES.ROI_EDIT,
               % move ROI edges
                if leftClick %we need to draw something
                    moveEdgeRectangle();
                end
               
       end
    end

    function hFigure_DownFcn(~, ~)
        
        
        % get which button is clicked
        clickType   = get(handStr.roiFig,'Selectiontype');
        leftClick   = strcmp(clickType,'normal');
        rightClick  = strcmp(clickType,'alt');
        
        units       = get(handStr.roiAxes,'units');
        set(handStr.roiAxes,'units','normalized');
        point1      = get(handStr.roiAxes,'CurrentPoint');
        set(handStr.roiAxes,'units',units);
        pointRef    = point1;                        

        [yesItIs, index, isEdge, whichEdge_trbl] = isMouseOverRectangle();
        
        % debug
        %fprintf('Dwn state : %d, indx : %d\n',guiState,activeRectangleIndex)
        
        switch guiState,
            case GUI_STATES.INIT, 
                if leftClick,
                    guiState  = GUI_STATES.BROWSE_ABSPOS;
                elseif rightClick,
                end;
            case GUI_STATES.BROWSE_ABSPOS,
                error('Dwn 11 : Should not be here')
            case GUI_STATES.BROWSE_DIFFPOS,
                error('Dwn 12 : Should not be here')
            case GUI_STATES.ROI_INIT, 
                if leftClick,
                    if yesItIs,
                        activeRectangleIndex        = index;
                        % start editing : take ref point and rectagle
                        fManageRoiArray('copyFromList',activeRectangleIndex);
                        guiState  = GUI_STATES.ROI_SELECTED;
                    else 
                        % start drawing
                        fManageLastRoi('init',0);
                        guiState  = GUI_STATES.ROI_DRAW;
                        foiLast   = TPA_ManageLastRoi(foiLast,'init',roiInitState,pointRef(1,1:2));
                        
                    end
                elseif rightClick,
                end;
                
                
            case {GUI_STATES.ROI_DRAW}
                error('Dwn 2 : Should not be here')
            case GUI_STATES.ROI_SELECTED,
                % return roi back if any and selecte new if it is on
                if activeRectangleIndex < 1,
                    error('Dwn 3 : DBG : activeRectangleIndex must be positive')
                end
                
                if leftClick,
                    if yesItIs,
                        % new roi selected
                        if activeRectangleIndex  ~= index,
                            % return back and extract new current roi
                            fManageRoiArray('copyToList',activeRectangleIndex);
                            activeRectangleIndex  = index;
                            fManageRoiArray('copyFromList',activeRectangleIndex);
                        end
                        % clicked on the same ROI :  inside or edge
                        if isEdge,
                            guiState  = GUI_STATES.ROI_EDIT;
                        else
                            guiState  = GUI_STATES.ROI_MOVE;
                        end;
                        % take new RefPoint and RefRectangle
                        %activeRectangleIndex  = index;
                        %fManageLastRoi('copyFromList',activeRectangleIndex);
                        
                    else 
                        % clicked on the empty space
                        fManageRoiArray('copyToList',activeRectangleIndex);
                        guiState  = GUI_STATES.ROI_INIT;

                    end    
                elseif rightClick,
                    % Do nothing - may access the context menu
                    guiState = GUI_STATES.ROI_SELECTED;
                end;
                        
           case  GUI_STATES.PLAYING,
                % stay there
                
            otherwise
               % error('bad roi state')
        end
        
        %fRefreshImage();
        
        
    end

    function hFigure_UpFcn(~, ~)
        
        % debug
        %fprintf('Up  state : %d, indx : %d\n',guiState,activeRectangleIndex)
        
        
        switch guiState,
          case GUI_STATES.INIT, 
                % no ROi selected
                %error('Up 1 should not be here')
             
          case GUI_STATES.BROWSE_ABSPOS,
                if leftClick, % add roi to list
                    % if size of the roi is small  - it is not added - just like click outside
                    fUpdateBrowseData();
                    guiState  = GUI_STATES.INIT;
                elseif rightClick, % show context menu
                 end;
          case GUI_STATES.BROWSE_DIFFPOS,
                    guiState  = GUI_STATES.INIT;
            case GUI_STATES.ROI_INIT, 
                % no ROi selected
                %error('Up 1 should not be here')
                activeRectangleIndex = -1;
                
            case GUI_STATES.ROI_DRAW,
                if leftClick, % add roi to list
                    % if size of the roi is small  - it is not added - just like click outside
                     switch roiLast.Type,
                         case ROI_TYPES.RECT,
                         case ROI_TYPES.ELLIPSE,
                         case ROI_TYPES.FREEHAND,
                             % make it closed
                            xData                   = get(roiLast.XY.hShape,'xdata');
                            yData                   = get(roiLast.XY.hShape,'ydata');
                            %rectangleInitialPosition = roiLast.Position; % no scaling
                            fManageLastRoi('addPoint',[xData(1) yData(1)]);
                     end;
                     
                     % protect from small touch
                     if prod(roiLast.Position(3:4)) < 50,
                        fManageLastRoi('clean',0); 
                        guiState  = GUI_STATES.ROI_INIT;
                        foiLast   = TPA_ManageLastRoi(foiLast,'removeHandles',1);
                     else
                        fManageRoiArray('add',0);                
                        guiState  = GUI_STATES.ROI_SELECTED;
                     end
                    
                elseif rightClick, % show context menu
                    %guiState  = GUI_STATES.INIT;
                    
                end;
               
            case GUI_STATES.ROI_SELECTED,
                if leftClick, % add roi to list
                 elseif rightClick, % show context menu
                    %guiState  = GUI_STATES.ROI_INIT;
                end;

            case GUI_STATES.ROI_EDIT,
                if leftClick, % add roi to list
                 elseif rightClick, % show context menu
                end;
                %fManageLastRoi('copyToList',activeRectangleIndex);                
                guiState  = GUI_STATES.ROI_SELECTED;
             
            case GUI_STATES.ROI_MOVE,
                if leftClick, % add roi to list
                 elseif rightClick, % show context menu
                end;
                %fManageLastRoi('copyToList',activeRectangleIndex);                
                guiState  = GUI_STATES.ROI_SELECTED;
               
            case  GUI_STATES.PLAYING,
                % stay there
                
            otherwise
                %error('bad roi state')
        end

        
        fRefreshImage();
        leftClick  = false;
        rightClick = false;
    end

%-----------------------------------------------------
% Keyboard

    function hFigure_KeyPressFcn(~,eventdata)
        
        switch eventdata.Key
            case 'delete'
                fRefreshImage();
            case 'backspace'
                fRefreshImage();
            otherwise
        end
    end

%-----------------------------------------------------
% Menu Selections

   function fUpdateImageShow(~, ~, menuImageType)
       % function handles image preprocessing type and gui indications
       % 
       set(handStr.menuImage(2:end),'checked','off')
       
        %set([handStr.rectangleTool , handStr.ellipseTool , handStr.freehandTool ,  handStr.browseTool],'State', 'off')
        switch menuImageType,
            case IMAGE_TYPES.RAW,
               set(handStr.menuImage(2),'checked','on')
               imageShowState    = IMAGE_TYPES.RAW;
            case IMAGE_TYPES.MAX,
               set(handStr.menuImage(3),'checked','on')
               imageIn         = max(imageData(:,:,activeZstackIndex,:),[],4);
               imageShowState    = IMAGE_TYPES.MAX;
            case IMAGE_TYPES.MEAN,
               set(handStr.menuImage(4),'checked','on')
               imageIn         = mean(imageData(:,:,activeZstackIndex,:),4);
               imageShowState    = IMAGE_TYPES.MEAN;
            otherwise error('bad menuImageType')
        end
        
        fRefreshImage()
        
   end

%-----------------------------------------------------
% Button Clicks

    function clickedHelpTool(~, ~)
        %reached when user click HELP button
        message = {'Navigate in Time and Z stack by using buttons and mouse wheele.', '', ...
            'Scroll in any direction to see images in data set .'};
        msgbox(message,'Help','help','modal');
    end

    function clickedNavToolT (~, ~, incr)
        
        % save update
        if abs(incr) < 1, return; end;
        activeTimeIndex = max(1,min(activeTimeIndex + incr,nT));
        % do not change image for max and mean projections
        switch imageShowState,
            case IMAGE_TYPES.RAW,
                imageIn         = imageData(:,:,activeZstackIndex,activeTimeIndex);
        end
        fRefreshImage()
    end

    function clickedNavToolZ (~, ~, incr)
        
        if abs(incr) < 1, return; end;        
        activeZstackIndex = max(1,min(activeZstackIndex + incr,nZ));
        switch imageShowState,
            case IMAGE_TYPES.RAW,
                imageIn         = imageData(:,:,activeZstackIndex,activeTimeIndex);
            case IMAGE_TYPES.MAX,
                imageIn         = max(imageData(:,:,activeZstackIndex,:),[],4);
            case IMAGE_TYPES.MEAN,
                imageIn         = mean(imageData(:,:,activeZstackIndex,:),4);
        end
                
        fRefreshImage()
    end

    function clickedPlayTool()
        
        
        fdelay  = Par.PlayerMovieTime/nT; % delay between frames
        incr    = ceil(0.1/fdelay);       % skip frames if frame delay is below 100 msec
        %incr    = Par.Player.FrameInrement;
        %fdelay  = Par.Player.FrameDelay;
        while guiState  == GUI_STATES.PLAYING,
            clickedNavToolT (0, 0, incr);
            pause(fdelay);
            if activeTimeIndex == nT, break; end;
        end
 
    end

    function clickedToolButton (~, ~, buttonType)
        % state management
        
        %set([handStr.rectangleTool , handStr.ellipseTool , handStr.freehandTool ,  handStr.browseTool],'State', 'off')
        set(handStr.ellipseTool,    'State', 'off');
        set(handStr.rectangleTool,  'State', 'off');
        set(handStr.freehandTool,   'State', 'off');
        set(handStr.browseTool,     'State', 'off');
        set(handStr.playerTool,     'State', 'off');
        roiInitState = ROI_TYPES.RECT;        
        switch buttonType,
            case BUTTON_TYPES.RECT,
                    set(handStr.rectangleTool,  'State', 'on');
                    guiState  = GUI_STATES.ROI_INIT;
                    roiInitState = ROI_TYPES.RECT;
            case BUTTON_TYPES.ELLIPSE
                    set(handStr.ellipseTool,    'State', 'on');
                     guiState  = GUI_STATES.ROI_INIT;
                      roiInitState = ROI_TYPES.ELLIPSE;
         case BUTTON_TYPES.FREEHAND
                    set(handStr.freehandTool,   'State', 'on');
                     guiState  = GUI_STATES.ROI_INIT;
                     roiInitState = ROI_TYPES.FREEHAND;
          case BUTTON_TYPES.BROWSE
                    set(handStr.browseTool,   'State', 'on');
                     guiState  = GUI_STATES.INIT;
            case BUTTON_TYPES.PLAYER,
                    % ugly loading icons one more time  -just dont want to global
                    %s                       = load('icons.mat');
                    if guiState  == GUI_STATES.PLAYING,
                        guiState  = GUI_STATES.INIT;
                        set(handStr.playerTool,   'State', 'off', 'CData',handStr.ico.player_play);
                    else
                        guiState  = GUI_STATES.PLAYING;
                        set(handStr.playerTool,   'State', 'on', 'CData',handStr.ico.player_stop);
                        clickedPlayTool();
                        guiState  = GUI_STATES.INIT;
                        set(handStr.playerTool,   'State', 'off', 'CData',handStr.ico.player_play);
                   end
                     
                     
                
           otherwise
                % nothing is sellected
                error('Unknown  buttonType %d',buttonType)
        end
        % last clicked position
        buttonState = buttonType;

        
        %fprintf('Tool  state : %d, pointer : %s\n',guiState,pointer)

        %fRefreshImage()
    end

%-----------------------------------------------------
% GUI management

    function fUpdateBrowseData()
        % manage increment of image browse  T and Z
        
        point2       = get(handStr.roiAxes, 'CurrentPoint');
        
        nR2         = nR/nZ;
        nC2         = nC/nT;

      switch guiState,
           case GUI_STATES.BROWSE_ABSPOS, % each new point will be absolute position
                xMouse      = (point2(1,1)/nC2) - activeTimeIndex;
                yMouse      = (point2(1,2)/nR2) - activeZstackIndex;
                mouseSens   = 1;
            case GUI_STATES.BROWSE_DIFFPOS, % each new point will be differential position              
                xMouse      = (point2(1,1) - point1(1,1))./nC2;
                yMouse      = (point2(1,2) - point1(1,2))./nR2;
                mouseSens   = 0.1;
      end
         
        
        % browse speed
        velT        = ceil(mouseSens*xMouse);
        clickedNavToolT(0,0,velT)
        velZ        = ceil(mouseSens*yMouse);
        clickedNavToolZ(0,0,velZ)
        
        %fprintf('updateBrowseData : %5.2f\n',velT)
        
    end

    function fRefreshImage (~)
        %Refresh the image plot
        %disp('fRefreshImage');
        %get current saved image to preview
        axes(handStr.roiAxes);
        set(handStr.roiImg,'cdata',imageIn);
        set(handStr.roiText,'string',sprintf('Z:%d/%d, T:%d/%d',activeZstackIndex,nZ,activeTimeIndex,nT))
         
        
        %sz = size(roiSelection,2);
        sz = length(SData.strROI);
        for i=1:sz
            
            if i==activeRectangleIndex
                color = 'r';
            else
                color = 'y';
            end
                
            %pos                     = SData.strROI{i}.Position;
            %xy                      = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
            %set(SData.strROI{i}.XY.hShape,     'xdata',xy(:,1),'ydata',xy(:,2),'Color',color);
            %set(SData.strROI{i}.XY.hShape,     'position',SData.strROI{i}.Position, 'edgeColor',color);
            set(SData.strROI{i}.XY.hShape,    'visible','on','Color',color);
            set(SData.strROI{i}.XY.hText,     'visible','off','Color',color);
            set(SData.strROI{i}.XY.hBoundBox,  'visible','off');
            % all the active rectangles - hide
            set(SData.strROI{i}.XY.hCornRect, 'visible','off');

            
            
            foiLast       = TPA_ManageLastRoi(foiLast,'setPosXY',foiLast.Position+1);   % just to see the box      
            foiLast       = TPA_ManageLastRoi(foiLast,'OnOffShapeOnly',1);        

            if strcmp(color,'r')
                %draw small squares in the corner and middle of length
                set(SData.strROI{i}.XY.hBoundBox,  'visible','on','edgeColor',color);
                set(SData.strROI{i}.XY.hText,      'visible','on','Color',color);
                set(SData.strROI{i}.XY.hCornRect,  'visible','on','edgeColor',color);                
               
                foiLast       = TPA_ManageLastRoi(foiLast,'OnOffBoundBox',1);        
             
            end
            
        end
        
    end

    function fCloseRequestFcn(~, ~)
        % This is where we can return the ROI selected
        
        hFigure = handStr.roiFig;
        
        ListROI = fExportROI({});
        
%         try
%         catch
%         end
        
        uiresume(hFigure);
        delete(hFigure);
       
    end

%-----------------------------------------------------
% Context Menu

    function fCreateRoiContextMenu()
    cntxMenu = uicontextmenu;
    uimenu(cntxMenu,'Label','Remove ROI',    'Callback',         @fRemoveMarkedRoi);
    uimenu(cntxMenu,'Label','Select Color',  'Callback',         @fSelectColorForRoi);
    uimenu(cntxMenu,'Label','Rename',        'Callback',         @fRenameRoi);
    uimenu(cntxMenu,'Label','Aver Type',     'Callback',         @fAverageTypeRoi);
    uimenu(cntxMenu,'Label','Show name',     'Callback',         @fShowNameRoi, 'checked', 'off');
    uimenu(cntxMenu,'Label','Snap to Data',  'Callback',         'warndlg(''TBD'')');
    end

    function fRemoveMarkedRoi(src,eventdata)

        % activate menu only when active index is OK
        if activeRectangleIndex < 1, return; end;

        fManageRoiArray('delete',activeRectangleIndex);
        activeRectangleIndex    = -1;

        fRefreshImage();

    end

    function fSelectColorForRoi(src,eventdata)

        % activate menu only when active index is OK
        if activeRectangleIndex < 1, return; end;

        selectedColor = uisetcolor('Select a Color for the cell');
        if(selectedColor == 0),         return;     end
        fManageLastRoi('setClr',selectedColor);
        foiLast       = TPA_ManageLastRoi(foiLast,'setColor',selectedColor);        

    end

    function fRenameRoi(src,eventdata)

        % activate menu only when active index is OK
        if activeRectangleIndex < 1, return; end;

        prompt      = {'Enter ROI Name:'};
        dlg_title   = 'ROI parameters';
        num_lines   = 1;
        def         = {roiLast.Name};
        answer      = inputdlg(prompt,dlg_title,num_lines,def);
        if isempty(answer), return; end;
        fManageLastRoi('setName',answer{1});
        foiLast       = TPA_ManageLastRoi(foiLast,'setName',answer{1});        

    end

    function fAverageTypeRoi(src,eventdata)

        % activate menu only when active index is OK
        if activeRectangleIndex < 1, return; end;
                
        RoiAverageOptions = {'PointAver','LineMaxima','LineOrthog'};
        [s,ok] = listdlg('PromptString','Select ROI Averaging Type:','ListString',RoiAverageOptions,'SelectionMode','single');
        if ~ok, return; end;
        fManageLastRoi('setAverType',RoiAverageOptions{s});
        foiLast       = TPA_ManageLastRoi(foiLast,'setAverType',RoiAverageOptions{s});     
    end


    function fShowNameRoi(src,eventdata)

        % activate menu only when active index is OK
        if activeRectangleIndex < 1, return; end;

        roiLast.NameShow  = strcmp(get(src,'Checked'),'on');

    end



end