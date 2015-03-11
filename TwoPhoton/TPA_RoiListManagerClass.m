
classdef TPA_RoiListManager %< handle
    % TPA_RoiListManager - defines list of ROI objects and
    % performes management of them
    % Inputs:
    %       global variables and more
    % Outputs:
    %        different functions
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 16.06 19.02.14 UD     Created
    %-----------------------------
    
    properties
        % Init roi list
        roiLast             = [];  % init working instance
        
        % contains all the rois - populated by roiLast
        roiStr              = {};
        
        % tracking og the list
        activeRectangleIndex = -1; %used when moving selection
        
        
        
        %Testing
        hFigure             = [];
        hAxes               = []; % actual handle axis are created
        hImage              = [];
        
        
        
    end
    methods
        
        % =============================================
        function obj = TPA_RoiListManager(hAxes)
            % Constructor
            
            % check 
            if nargin < 1, error('Must define handle to the axis to work on'); end
            
            obj.hAxes               = hAxes;
            obj.roiLast             = TPA_RoiManager();  % init working instance
            
        end
        
        % =============================================
        function obj = CopyFromList(obj,activeIndx)
            % CopyFromList -  % redraw the last ROI object pos
            % Input
            %   activeIndx  - which ROI to create
            % Output
            %   obj     - updated
            global Par
            roiNum                  = length(obj.roiStr);
            if activeIndx < 1 || activeIndx > roiNum, error('Bad value for activeIndx'); end;
            
            obj.roiLast                 = obj.roiStr{activeIndx};
            obj.roiStr{activeIndx}.Active = false;
            
            % non active ROI do not need curvature? : check it out
            switch obj.roiLast.Type,
                case Par.ROI_TYPES.ELLIPSE,
                    curv           = [1,1]; % curvature
                otherwise
                    curv           = [0,0]; % curvature
            end;
            
            clr                     = obj.roiStr{activeIndx}.Color;
            set(obj.roiLast.hShape,     'color',    clr,'visible','on');
            set(obj.roiLast.hBoundBox,  'edgeColor',clr,'visible','on', 'curvature', curv);
            set(obj.roiLast.hCornRect,  'edgeColor',clr,'visible','on');
            set(obj.roiLast.hText,      'color',    clr,'visible','on')
            
            % gui support
            obj.roiLast.rectangleInitialPosition    = obj.roiStr{activeIndx}.Position;
            obj.roiLast.shapeInitialDrawing         = [get(obj.roiLast.hShape,'xdata')' get(obj.roiLast.hShape,'ydata')'];
        end
        
        % =============================================
        function obj = CopyToList(obj,activeIndx)
            % copyToList -  % returns the last ROI object pos
            % Input
            %   activeIndx  - which ROI to create
            % Output
            %   obj     - updated
            roiNum                  = length(obj.roiStr);
            if activeIndx < 1 || activeIndx > roiNum, error('Bad value for activeIndx'); end;
            
            % update shape - important for circles and freehand
            %fManageLastRoi('setPos',roiLast.Position);
            obj.roiLast = obj.roiLast.SetPosition(obj.roiLast.Position); % MUST have view as input
            
            % update name
            %obj.roiLast = obj.roiLast.SetName(sprintf('ROI_%2d',activeIndx));
            
            
            obj.roiStr{activeIndx}      = obj.roiLast;
            clr                     = 'y';
            set(obj.roiStr{activeIndx}.hShape,     'Color',     clr,'visible','on');
            set(obj.roiStr{activeIndx}.hBoundBox,  'edgeColor', clr,'visible','off', 'curvature', [0,0]);
            set(obj.roiStr{activeIndx}.hCornRect,  'edgeColor', clr,'visible','off');
            set(obj.roiStr{activeIndx}.hText,      'color',     clr,'visible','on')
            %obj.roiStr{activeIndx}.Active = true;
            
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
            roiNum                  = length(obj.roiStr);
            if activeIndx < 1 || activeIndx > roiNum, error('Bad value for activeIndx'); end;
            
            %remove the rectangle at the index given
            delete(obj.roiStr{activeIndx}.hShape);
            delete(obj.roiStr{activeIndx}.hBoundBox);
            delete(obj.roiStr{activeIndx}.hCornRect);
            delete(obj.roiStr{activeIndx}.hText);
            obj.roiStr(activeIndx)      = [];
            
        end
        
        % =============================================
        function obj = Add(obj)
            % Add -  add the last rectangle ROI to the list of Rectangle ROIs
            % Input
            %   activeIndx  - which ROI to create
            % Output
            %   obj     - updated
            
            activeIndx              = length(obj.roiStr) + 1;
            
            % update name
            obj.roiLast = obj.roiLast.SetName(sprintf('ROI_%2d',activeIndx));
            %fManageLastRoi('setName',sprintf('ROI:%2d Z:%d %s',activeIndx,roiLast.zInd,roiLast.AverType));
            
            
            obj.roiStr{activeIndx}      = obj.roiLast;
            clr                     = 'r';
            set(obj.roiStr{activeIndx}.hShape,     'Color',     clr,'visible','on');
            set(obj.roiStr{activeIndx}.hBoundBox,  'edgeColor', clr,'visible','on');
            set(obj.roiStr{activeIndx}.hCornRect,  'edgeColor', clr,'visible','on');
            set(obj.roiStr{activeIndx}.hText,      'color',     clr,'visible','on');
            
            
            
            % when added - still selected
            obj.activeRectangleIndex     = activeIndx;
            obj.roiLast.rectangleInitialPosition = obj.roiLast.Position; % no scaling
            obj.roiLast.shapeInitialDrawing      = [get(obj.roiLast.hShape,'xdata')' get(obj.roiLast.hShape,'ydata')'];
            
            % update shape - important for circles and freehand
            %fManageLastRoi('setPos',obj.roiLast.Position);
            obj.roiLast = obj.roiLast.SetPosition(obj.roiLast.Position); % MUST have view as input
            
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
            
            sz = length(obj.roiStr);
            for i=1:sz
                [isOverRectangle, isEdge, whichEdge_trbl] = isMouseOverEdge(point, obj.roiStr{i}.Position);
                if isOverRectangle, % && roiStr{i}.Active, % Active helps when one of the rectangles is under editing
                    % check if the selection tool fits roiStr{i}.Type
                    switch buttonState,
                        case BUTTON_TYPES.RECT,
                            if obj.roiStr{i}.Type ~= ROI_TYPES.RECT,
                                continue;
                            end
                        case BUTTON_TYPES.ELLIPSE
                            if obj.roiStr{i}.Type ~= ROI_TYPES.ELLIPSE,
                                continue;
                            end
                        case BUTTON_TYPES.FREEHAND
                            if obj.roiStr{i}.Type ~= ROI_TYPES.FREEHAND,
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
