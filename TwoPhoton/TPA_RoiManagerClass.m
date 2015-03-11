
classdef TPA_RoiManagerClass %< handle
    % TPA_RoiManager - defines Last ROI management class
    % Inputs:
    %       global variables and more
    % Outputs:
    %        different functions
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 16.10 21.02.14 UD     Improving
    % 16.06 17.02.14 UD     Created
    %-----------------------------
    
    properties
        % Selected ROI properties
        % init common ROI structure
        Type     = 0;               % define ROI type
        State    = 0;               % designates in which init state ROI is in
        Color    = rand(1,3);       % generate colors
        Name     = 'X';             % which name
        AverType = 0;               % which operation to perform
        
        % bounding box
        xInd     = [1 1];           % range location in X
        yInd     = [1 1];           % range location in Y
        zInd     = [1 1];           % range location in Z stack
        tInd     = [1 1];           % rangelocation in T stack
        
        % init graphics
        %ViewType = 0;               % which type default
        NameShow = false;           % manage show name
        ViewXY   = [];             % structure contains XY shape params
        ViewYT   = [];             % structure contains YT shape params
        
        % clicks position
        pointRef                    = [10 10];  % point1        
        rectangleInitialPosition    = [-1 -1 -1 -1]; %rectangle to move
        shapeInitialDrawing         = [0 0]; % coordinates of the shape


        
        % internal stuff
        cntxMenu        = [];  % handle that will contain context menu
        
        
        %Testing
        hFigure             = [];
        hAxes               = [];
        hImage              = [];
                    
        
        
    end
    
    properties (SetAccess = private)
        % global constants see Par file
        GUI_STATES          = [];
        BUTTON_TYPES        = [];
        ROI_TYPES           = [];
        IMAGE_TYPES         = [];
        ROI_AVERAGE_TYPES        = [];
        VIEW_TYPES          = [];
        
        % constants : just do not want to define another file
        ROI_STATE_NONE       = 1; % designates states of lastROI first time init
        ROI_STATE_INIT       = 2;% designates states of lastROI first time init
        ROI_STATE_VIEWXY     = 3;% lastROI assigned to view xy
        ROI_STATE_VIEWYT     = 4;% lastROI assigned to view yt
        ROI_STATE_VIEWALL    = 5;% lastROI all views are init
    end
    
    methods
        
        % =============================================
        function obj = TPA_RoiManagerClass()
            % Constructor

            % state of the ROI
            obj.State               = obj.ROI_STATE_NONE;
                        
        end
        
        % =============================================
        function obj = TPA_ParInit(obj,Par)
            % Constructor
            
            if nargin < 2, error('Requires Par structure'); end
            %global Par
            
            % init types internally
            obj.GUI_STATES          = Par.GUI_STATES;
            obj.BUTTON_TYPES        = Par.BUTTON_TYPES;
            obj.ROI_TYPES           = Par.ROI_TYPES;
            obj.IMAGE_TYPES         = Par.IMAGE_TYPES;
            obj.ROI_AVERAGE_TYPES        = Par.ROI_AVERAGE_TYPES;
            obj.VIEW_TYPES          = Par.VIEW_TYPES;

            % state of the ROI
            obj.State               = obj.ROI_STATE_NONE;
            
            % ROI processing type
            obj.AverType            = Par.ROI_AVERAGE_TYPES.MEAN;     % which operation to perform
            obj.Color               = rand(1,3);       % generate colors
            obj.Name                = 'X';             % which name
            
        end
        
        
        % =============================================
        function obj = Init(obj,roiType,viewType,hAxes)
            % RoiInit - Init current/selected ROI main parameters. Not view/graphics related
            % Input
            %   roiType  - which ROI to create
            %   viewType  - which view ROI to create
            %   hAxes     - handle of the axes
            % Output
            %   obj     - updated
            
            if nargin < 2, roiType      = obj.ROI_TYPES.RECT; end;
            if nargin < 3, viewType     = obj.VIEW_TYPES.XY;   end;
            if nargin < 4, hAxes        = [];   end;
            
            % check
            if isempty(hAxes) || ~ishandle(hAxes)
                error('hAxes must be a valid handle')
            else
                axes(hAxes); % attention
            end
            
            % in the fisrt time init
            if obj.State == obj.ROI_STATE_NONE,
                % init common ROI structure
                obj.Type     = roiType;            % define ROI type
                obj.State    = obj.ROI_STATE_INIT;          % designates if this pointer structure is in use
            else
                if obj.Type  ~= roiType,
                    error('roiType on second init must match the first time')
                end
            end
            
            % could be variations in XY
            switch viewType,
                case Par.VIEW_TYPES.XY,
                    % XY view allows different ROI forms
                    switch obj.Type,
                        case Par.ROI_TYPES.RECT,
                            obj.ViewXY = InitShape(obj,0);
                        case Par.ROI_TYPES.ELLIPSE,
                            obj.ViewXY = InitShape(obj,0);
                        case Par.ROI_TYPES.FREEHAND,
                            obj.ViewXY = InitShape(obj,0);
                            obj.AverType = 'LineOrthog'; % props
                            
                        otherwise
                            error('Type must be ROI_TYPE variable')
                    end
                    % state
                    if obj.State == obj.ROI_STATE_VIEWYT,
                        obj.State    = obj.ROI_STATE_VIEWALL;
                    else
                        obj.State    = obj.ROI_STATE_VIEWXY;
                    end
                case Par.VIEW_TYPES.YT,
                    obj.Type   = Par.ROI_TYPES.RECT;            % define ROI type
                    obj.ViewYT = InitShape(obj,0);
                    % state
                    if obj.State == obj.ROI_STATE_VIEWXY,
                        obj.State    = obj.ROI_STATE_VIEWALL;
                    else
                        obj.State    = obj.ROI_STATE_VIEWYT;
                    end
                    
                otherwise
                    error('viewType must be VIEW_TYPES variable')
            end
        end
        
        % =============================================
        function xy = PosToRect(obj,pos)
            % Helper function that transforms position to rectangles
            xy =  [ pos(1:2);...
                pos(1:2)+[0 pos(4)/2];...
                pos(1:2)+[0 pos(4)];...
                pos(1:2)+[pos(3)/2 pos(4)];...
                pos(1:2)+[pos(3) pos(4)];...
                pos(1:2)+[pos(3) pos(4)/2];...
                pos(1:2)+[pos(3) 0];...
                pos(1:2)+[pos(3)/2 0];...
                pos(1:2)];
            
        end
        % =============================================
        function View = InitShape(obj,Data)
            % Initalizes
            global Par
            clr             = 'red';
            pos             = [0 0 35 35]+10;
            curv            = [0,0]; % curvature
            switch obj.Type,
                case Par.ROI_TYPES.RECT,
                    % support xy shape input
                    xy               = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                    if numel(Data) > 4, xy = Data; end;
                    pos              = [min(xy) max(xy) - min(xy)];
                case Par.ROI_TYPES.ELLIPSE,  % the same except curvature
                    % support xy shape input
                    xy               = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                    if numel(Data) > 4, xy = Data; end;
                    pos              = [min(xy) max(xy) - min(xy)];
                    curv             = [1,1]; % curvature
                case Par.ROI_TYPES.FREEHAND,
                    if numel(Data) > 4,
                        xy           = Data;
                        pos          = [min(xy) max(xy) - min(xy)];
                    else
                        xy           = obj.pointRef(1,1:2);%hFree.getPosition;
                        pos          = pos + [xy 0 0];
                    end;
                otherwise
                    error('Type must be ROI_TYPE variable')
            end
            
            View.hShape  =  line('xdata',xy(:,1),'ydata',xy(:,2),...
                'lineStyle','--',...
                'lineWidth',1, ...
                'Color',clr);
            View.hBoundBox = rectangle('position',pos,...
                'lineStyle',':',...
                'lineWidth',0.5, ...
                'curvature', curv,... % added                
                'edgeColor',clr);
            
            xy               = obj.PosToRect(pos);
            View.hCornRect  =  line('xdata',xy(:,1),'ydata',xy(:,2),'lineStyle','--','Marker','s','Color',clr);
            View.hText      =  text(pos(1),pos(2),obj.Name,'color',obj.Color,'interpreter','none');
            
            %  hide it
            set(View.hShape,   'visible','off')
            set(View.hBoundBox,'visible','off')
            set(View.hCornRect,'visible','off')
            set(View.hText,    'visible','off')
            
            View.Position = pos;
            
            % add context menu
            % set(View.hBoundBox,'uicontextmenu',cntxMenu)
            
        end
         
        % =============================================
        function obj = AddPoint(obj,Data)
            % Adds data point to ROI shape.
            % Applicable only to XY view - freehand
            global Par;
            % add point to a freehand line
            newPoint                = Data;
            if isempty(newPoint), return; end;
            if obj.Type ~= Par.ROI_TYPES.FREEHAND,
                error('Should only be called in freehand object')
            end
            
            xData                   = [get(obj.ViewXY.hShape,'xdata') newPoint(1)];
            yData                   = [get(obj.ViewXY.hShape,'ydata') newPoint(2)];
            set(obj.ViewXY.hShape,'xdata',xData,'ydata',yData ,'color','b');
            
            % no scaling after position set
            obj.ViewXY.Position        = [min(xData) min(yData) max(xData)-min(xData) max(yData)-min(yData)];
            
            %  show it
            set(obj.ViewXY.hShape,   'visible','on')
        end
        
        % =============================================
        function obj = SetPosition(obj, Data, viewType)
            % define new ROI position
            % redraw the last ROI object pos
            global Par;
            if nargin < 2, Data = [0 0]; end;
            if nargin < 3, viewType = Par.VIEW_TYPES.XY; end;
            
            pos                     = Data;
            switch viewType,
                case Par.VIEW_TYPES.XY,
                    View          = obj.ViewXY;
                    if obj.State ~= obj.ROI_STATE_VIEWXY && obj.State ~= obj.ROI_STATE_VIEWALL,
                        error('XY not initiazed')
                    end
                    switch obj.Type,
                        case Par.ROI_TYPES.RECT,
                            xy          = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                        case Par.ROI_TYPES.ELLIPSE,
                            xyr         = pos(3:4)/2;        % radius
                            xyc         = pos(1:2)+ xyr;     % center
                            tt          = linspace(0,2*pi,30)';
                            xy          = [cos(tt)*xyr(1) + xyc(1), sin(tt)*xyr(2) + xyc(2)];
                        case Par.ROI_TYPES.FREEHAND,
                            pos_old     = obj.rectangleInitialPosition;
                            xy_old      = obj.shapeInitialDrawing;
                            % rescale
                            xyc         = pos(1:2)      + pos(3:4)/2;     % center
                            xyc_old     = pos_old(1:2)  + pos_old(3:4)/2;     % center
                            x           = (xy_old(:,1) - xyc_old(1))*pos(3)/(eps+pos_old(3)) + xyc(1);
                            y           = (xy_old(:,2) - xyc_old(2))*pos(4)/(eps+pos_old(4)) + xyc(2);
                            xy          = [x(:) y(:)];
                    end;
                case Par.VIEW_TYPES.YT,
                    if obj.State ~= obj.ROI_STATE_VIEWYT || obj.State ~= obj.ROI_STATE_VIEWALL,
                        error('YT not initiazed')
                    end
                    xy          = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                    View          = obj.ViewYT;
                otherwise
                    error('Bad viewType')
            end
            
            View.Position        = pos; %[x,y,w,h]
            
            % rect to xy
            set(View.hShape,     'xdata',xy(:,1),'ydata',xy(:,2),'visible','on');
            set(View.hBoundBox,  'position',View.Position,'visible','on');
            %             cornerRectangles        = getCornerRectangles(View.Position);
            %             for j=1:8,
            %                 set(View.hCornRect(j), 'position',cornerRectangles{j},'visible','on');
            %             end
            xy              = obj.PosToRect(pos);
            set(View.hCornRect,'xdata',xy(:,1),'ydata',xy(:,2),'visible','on' );
            set(View.hShape,     'xdata',xy(:,1),'ydata',xy(:,2),'visible','on');
            set(View.hText,'pos',View.Position(1:2)+[5,5], 'visible','on');
            
            % save back
            switch viewType,
                case Par.VIEW_TYPES.XY,
                    obj.ViewXY = View;
                case Par.VIEW_TYPES.YT,
                    obj.ViewYT = View;
            end
            
        end
        
        % =============================================
        function obj = SetColor(obj, Data)
            % set color for all views
            %global Par;
            if nargin < 2, Data = [0 0]; end;
            
            clr                 = Data;
            % check init
            if obj.State == obj.ROI_STATE_VIEWXY || obj.State == obj.ROI_STATE_VIEWALL,
                obj.Color           = clr;   % remember
                set(obj.ViewXY.hShape,     'Color',    clr);
                set(obj.ViewXY.hBoundBox,  'edgeColor',clr);
                set(obj.ViewXY.hCornRect,  'Color',clr);
                set(obj.ViewXY.hText,      'color',    clr);
            end;
            
            % check init
            if obj.State == obj.ROI_STATE_VIEWYT || obj.State == obj.ROI_STATE_VIEWALL,
                obj.Color           = clr;   % remember
                set(obj.ViewYT.hShape,     'Color',    clr);
                set(obj.ViewYT.hBoundBox,  'edgeColor',clr);
                set(obj.ViewYT.hCornRect,  'Color',clr);
                set(obj.ViewYT.hText,      'color',    clr);
            end;
        end
        
        % =============================================
        function obj = SetName(obj, Data)
            % set name of the ROI
            % redraw the last ROI object pos
            obj.Name        = Data;   % remember
            set(obj.hText,  'string', obj.Name,   'visible','on')
        end
        
        
        %              case 'setAverType',
        %                 % properties for the subsequent processing
        %                 roiLast.AverType        = Data;   % remember
        %
        %             case 'setZInd',
        %                 % stack position
        %                 roiLast.zInd            = Data;
        %
        %             case 'setTInd',
        %                roiLast.tInd             = Data;           % location in T stack
        
        % =============================================
        function obj = Delete(obj)
            % redraw the last ROI object pos
            % delete graphics of the lastROI
            %if activeRectangleIndex < 1, return; end;
            
            
            if obj.State == obj.ROI_STATE_VIEWXY || obj.State == obj.ROI_STATE_VIEWALL,
                delete(obj.ViewXY.hShape);
                delete(obj.ViewXY.hBoundBox);
                delete(obj.ViewXY.hCornRect);
                delete(obj.ViewXY.hText);
            end;
            
            % check init
            if obj.State == obj.ROI_STATE_VIEWYT || obj.State == obj.ROI_STATE_VIEWALL,
                delete(obj.ViewYT.hShape);
                delete(obj.ViewYT.hBoundBox);
                delete(obj.ViewYT.hCornRect);
                delete(obj.ViewYT.hText);
            end;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = TestUserInput(obj,a,b)
            
            %motionClickWithLeftClick = true;
            units = get(obj.hAxes,'units');
            set(obj.hAxes,'units','normalized');
            point2 = get(obj.hAxes, 'CurrentPoint');
            set(obj.hAxes,'units',units);
            
            %fRefreshImage (); %plot the image
            %obj.AddPoint(point2(1,1:2));
            obj = obj.SetPosition( [point2(1,1:2) 20 20]);            
            
            obj.SetColor('blue');
            
        end
        
        function obj = TestSimple(obj)
            % TestSimple - create image connect callback and init an object
            
            % GUI
            obj.hFigure = figure(10); clf; set(obj.hFigure,'Position',[100 100 560 580]);
            obj.hAxes = axes('DataAspectRatio',[1 1 1],'Parent',obj.hFigure);
            obj.hImage = image(imread('cell.tif'),'CDataMapping','scaled','Parent',obj.hAxes);
            
            % init ROI
            
            global Par;
            %Par = TPA_ParInit();
            %obj = obj.Init(Par.ROI_TYPES.RECT,Par.VIEW_TYPES.XY,obj.hAxes);
            obj = obj.Init(Par.ROI_TYPES.FREEHAND,Par.VIEW_TYPES.XY,obj.hAxes);
            obj = obj.SetPosition( [10 10 20 20], Par.VIEW_TYPES.XY);
            obj = obj.SetColor( [0 0 0.5]);
            %obj = obj.Delete();
            
            %set(seal.Figure,'WindowButtonMotion',@(src,event)TestUserInput(obj, src, eventdata, seal));
            set(obj.hFigure,'WindowButtonDown',@(src,event)TestUserInput(obj, src, event));
            
            
        end % TestSimple
        
        
    end% methods
end% classdef
