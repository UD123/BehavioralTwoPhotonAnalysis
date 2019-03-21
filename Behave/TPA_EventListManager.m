
classdef TPA_EventListManager %< handle
    % TPA_EventListManager - defines list of Event objects and
    % performes management of them
    % Inputs:
    %       global variables and more
    % Outputs:
    %        different functions
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 20.04 17.05.15 UD     Created
    %-----------------------------
      
    properties (Constant)
        %         
        Version             = '2004';
    end
    properties
        % Init roi list
        EventLast             = [];  % init working instance
        
        % contains all the rois - populated by EventLast
        EventList              = {};
        
%         % tracking og the list
%         activeRectangleIndex = -1; %used when moving selection
%         
        
        
        % GUI Support
        %UseGUI              = false;
        hFigure             = [];
        hAxes               = []; % actual handle axis are created
        hImage              = [];
        
        
        
    end
    methods
        
        % =============================================
        function obj = TPA_EventListManager(haxes)
            % Constructor
            
            % check 
            if nargin < 1, 
                %obj.UseGUI = false;
                haxes      = [];
            end
            
            obj.hAxes                = haxes;
            obj.EventLast            = TPA_EventManager();  % init working instance
            
        end
        
        % =============================================
        function obj = CopyFromList(obj,activeIndx)
            % CopyFromList -  % redraw the last ROI object pos
            % Input
            %   activeIndx  - which ROI to create
            % Output
            %   obj     - updated
            %global Par
            roiNum                  = length(obj.EventList);
            if activeIndx < 1 || activeIndx > roiNum, error('Bad value for activeIndx'); end;
            
            obj.EventLast                   = obj.EventList{activeIndx};
            obj.EventList{activeIndx}.Active = false;
            
            % gui support
            if isempty(obj.hAxes), return; end;
            
            % non active ROI do not need curvature? : check it out
            switch obj.EventLast.Type,
                case Par.ROI_TYPES.ELLIPSE,
                    curv           = [1,1]; % curvature
                otherwise
                    curv           = [0,0]; % curvature
            end;
            
            clr                     = obj.EventList{activeIndx}.Color;
            set(obj.EventLast.hShape,     'color',    clr,'visible','on');
            set(obj.EventLast.hBoundBox,  'edgeColor',clr,'visible','on', 'curvature', curv);
            set(obj.EventLast.hCornRect,  'edgeColor',clr,'visible','on');
            set(obj.EventLast.hText,      'color',    clr,'visible','on')
            
            % gui support
            obj.EventLast.rectangleInitialPosition    = obj.EventList{activeIndx}.Position;
            obj.EventLast.shapeInitialDrawing         = [get(obj.EventLast.hShape,'xdata')' get(obj.EventLast.hShape,'ydata')'];
        end
        
        % =============================================
        function obj = CopyToList(obj,activeIndx)
            % copyToList -  % returns the last ROI object pos
            % Input
            %   activeIndx  - which ROI to create
            % Output
            %   obj     - updated
            eventNum                  = length(obj.EventList);
            if activeIndx < 1 || activeIndx > eventNum, error('Bad value for activeIndx'); end;
            
            obj.EventList{activeIndx}      = obj.EventLast;
            
            % gui support
            if isempty(obj.hAxes), return; end;

            
            % update shape - important for circles and freehand
            %fManageLastRoi('setPos',EventLast.Position);
            obj.EventLast = obj.EventLast.SetPosition(obj.EventLast.Position); % MUST have view as input
            
            % update name
            %obj.EventLast = obj.EventLast.SetName(sprintf('ROI_%2d',activeIndx));
            
            
            clr                     = 'y';
            set(obj.EventList{activeIndx}.hShape,     'Color',     clr,'visible','on');
            set(obj.EventList{activeIndx}.hBoundBox,  'edgeColor', clr,'visible','off', 'curvature', [0,0]);
            set(obj.EventList{activeIndx}.hCornRect,  'edgeColor', clr,'visible','off');
            set(obj.EventList{activeIndx}.hText,      'color',     clr,'visible','on')
            %obj.EventList{activeIndx}.Active = true;
            
            % not in use any more
            %activeRectangleIndex   = 0;
        end
        
        % =============================================
        function obj = Delete(obj,activeIndx)
            % Delete -  % delete ROI from list
            % Input
            %   activeIndx  - which ROI to create
            % Output
            %   obj     - updated
            % delete from list
            roiNum                  = length(obj.EventList);
            if activeIndx < 1 || activeIndx > roiNum, error('Bad value for activeIndx'); end;
            
            % gui support
            if ~isempty(obj.hAxes),          
            
            %remove the rectangle at the index given
            delete(obj.EventList{activeIndx}.hShape);
            delete(obj.EventList{activeIndx}.hBoundBox);
            delete(obj.EventList{activeIndx}.hCornRect);
            delete(obj.EventList{activeIndx}.hText);
            
            end
            
            obj.EventList(activeIndx)      = [];
            
        end
        
        % =============================================
        function obj = Add(obj)
            % Add -  add the last rectangle ROI to the list of Rectangle ROIs
            % Input
            %   activeIndx  - which ROI to create
            % Output
            %   obj     - updated
            
            activeIndx              = length(obj.EventList) + 1;
            
            % update name
            obj.EventLast           = obj.EventLast.SetName(sprintf('ROI_%2d',activeIndx));
            %fManageLastRoi('setName',sprintf('ROI:%2d Z:%d %s',activeIndx,EventLast.zInd,EventLast.AverType));
            
            
            obj.EventList{activeIndx}      = obj.EventLast;
            
            % gui support
            if isempty(obj.hAxes), return; end;
            
            
            clr                     = 'r';
            set(obj.EventList{activeIndx}.hShape,     'Color',     clr,'visible','on');
            set(obj.EventList{activeIndx}.hBoundBox,  'edgeColor', clr,'visible','on');
            set(obj.EventList{activeIndx}.hCornRect,  'edgeColor', clr,'visible','on');
            set(obj.EventList{activeIndx}.hText,      'color',     clr,'visible','on');
            
            
            
            % when added - still selected
            %obj.activeRectangleIndex     = activeIndx;
            obj.EventLast.rectangleInitialPosition = obj.EventLast.Position; % no scaling
            obj.EventLast.shapeInitialDrawing      = [get(obj.EventLast.hShape,'xdata')' get(obj.EventLast.hShape,'ydata')'];
            
            % update shape - important for circles and freehand
            %fManageLastRoi('setPos',obj.EventLast.Position);
            obj.EventLast = obj.EventLast.SetPosition(obj.EventLast.Position); % MUST have view as input
            
        end
        
        % =============================================
        function [yesItIs, index, isEdge, whichEdge_trbl] = isMouseOverRectangle(obj)
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
            global Par
            
            yesItIs = false;
            index = -1;
            isEdge = false;
            whichEdge_trbl = [false false false false];
            
            point = get(obj.hAxes, 'CurrentPoint');
            
            sz = length(obj.EventList);
            for i=1:sz
                [isOverRectangle, isEdge, whichEdge_trbl] = isMouseOverEdge(point, obj.EventList{i}.Position);
                if isOverRectangle, % && EventList{i}.Active, % Active helps when one of the rectangles is under editing
                    % check if the selection tool fits EventList{i}.Type
                    switch buttonState,
                        case BUTTON_TYPES.RECT,
                            if obj.EventList{i}.Type ~= ROI_TYPES.RECT,
                                continue;
                            end
                        case BUTTON_TYPES.ELLIPSE
                            if obj.EventList{i}.Type ~= ROI_TYPES.ELLIPSE,
                                continue;
                            end
                        case BUTTON_TYPES.FREEHAND
                            if obj.EventList{i}.Type ~= ROI_TYPES.FREEHAND,
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
        
        % =============================================
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
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % =============================================
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
