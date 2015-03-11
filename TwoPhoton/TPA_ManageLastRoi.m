function [RoiLast,Data] = TPA_ManageLastRoi(RoiLast,Cmnd,Data, Data2)
% TPA_ManageLastRoi - manages Last/Selected ROI data
% Last ROI Management
% It written is similar to clas strcuture but it is not standard
% There are performance and management issues

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 16.10 21.02.14 UD     Get 4 windows sync back on move
%-----------------------------
global Par;                                 % connects to global definitions
if nargin < 1, RoiLast = [];        end;    % standalone run
if nargin < 2, Cmnd = 'init';       end;
if nargin < 3, Data = 0;            end;
if nargin < 4, Data2 = 0;           end;   % used only in freehand

switch Cmnd,
    
    case 'init',
        % init general params 
        
        roiType                 = Data;  
        
        RoiLast.Type            = roiType;
        RoiLast.Active          = true;        % designates if this pointer structure is in use
        RoiLast.Color           = rand(1,3);   % generate colors
        RoiLast.Name            = 'Rect';
        RoiLast.Position        = [0 0 1 1];   % position in Matlab notation
        RoiLast.NameShow        = false;       % manage show name
        RoiLast.AverType        = Par.ROI_AVERAGE_TYPES.MEAN; % props
        RoiLast.zInd            = 1;           % location in Z stack
        RoiLast.tInd            = 1;           % location in T stack
        
        % help varibles
        RoiLast.rectangleInitialPosition = RoiLast.Position;
        RoiLast.shapeInitialDrawing = [0 0];

        
        % init view handles/graphics
        view.isActive           = false;       % init view XY - desigates that active/assigned
        view.hAxes              = [];          % which axes it belongs
        view.hShape             = [];          % actual shape
        view.hBoundBox          = [];          % bounding box
        view.hCornRect          = [];          % corners of the box
        view.hText              = [];          % text
        view.clr                = 'm';       % shape editing
        view.pos                = RoiLast.Position;       % shape editing
        view.curv               = [0 0];        % difff between rect and elipse
        
        % shape specific params
        pos                     = view.pos;
        switch roiType,
            case Par.ROI_TYPES.RECT,
                xy              = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
            case Par.ROI_TYPES.ELLIPSE,
                xy              = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
                view.curv       = [1 1]; 
            case Par.ROI_TYPES.FREEHAND,
                if numel(Data2) > 4, 
                    xy           = Data2; % first point
                    view.pos     = [min(xy) max(xy) - min(xy)];
                else
                    xy           = point1(1,1:2);%hFree.getPosition;
                    view.pos     = pos + [xy 0 0];
                end;
                
            otherwise
                error('Bad roiType')
        end
        view.xy                 = xy;        
        
        [RoiLast, view]         = TPA_ManageLastRoi(RoiLast,'initShapes',view);
        
        
        RoiLast.XY              = view;        % init view XY - desigates that active
        RoiLast.YT              = view;         % init view
        
%     case 'activateViewXY'
%         % puts view in the active mode
%         
%         % check
%         if RoiLast.YT.isActive, error('Only one at a time View could be active YT'); end;
%         RoiLast.XY.isActive     = Data > 0;
%  
%    case 'activateViewYT'
%         % puts view in the active mode
%         
%         % check
%         if RoiLast.XY.isActive, error('Only one at a time View could be active XY'); end;
%         RoiLast.YT.isActive     = Data > 0;
        
        
                        
        %RoiLast   = TPA_ManageLastRoi(RoiLast,'initViewXY',1);


    case 'initViewXY',
        % init which view is 
        
        hAxis                   = Data;
        
        %Check if handle at least
        if ~ishandle(hAxis), error('Init XY data must be handle to axes');          end
        view.hAxes              = hAxis;
        view.isActive          = true;
        [RoiLast, view]         = TPA_ManageLastRoi(RoiLast,'initShapes',view);
        
         RoiLast.XY             = view ;
 
       
    case 'initShapes',
        % initalizes all lines and figures for view
        
        view                = Data;        
        
        view.hShape  =  line('xdata',view.xy(:,1),'ydata',view.xy(:,2),...
            'lineStyle','--',...
            'lineWidth',1, ...
            'Color',view.clr);
        view.hBoundBox = rectangle('position',view.pos,...
            'lineStyle',':',...
            'lineWidth',0.5, ...
            'curvature',view.curv,... % added                            
            'edgeColor',view.clr);
       view.hCornRect  =  line('xdata',view.xy(:,1),'ydata',view.xy(:,2),...
           'lineStyle','--',...
           'Marker','s',...
           'MarkerSize',12,...
           'Color',view.clr);
        view.hText      =  text(view.pos(1),view.pos(2),RoiLast.Name,'color',RoiLast.Color,'interpreter','none');
        
        %  hide it
        set(view.hShape,   'visible','off')
        set(view.hBoundBox,'visible','off')
        set(view.hCornRect,'visible','off')
        set(view.hText,    'visible','off')
        
        % add context menu
        cntxMenu                = TPA_RoiContextMenu();
        set(view.hBoundBox,'uicontextmenu',cntxMenu)
        
        % output
        Data = view;
            
    case 'addPoint',
        % add point to a freehand line
        newPoint                = Data;
        if isempty(newPoint), return; end;
        
        %if RoiLast.XY.isActive && ~RoiLast.YT.isActive,
            view                  = RoiLast.XY;
%         elseif ~RoiLast.XY.isActive && RoiLast.YT.isActive,
%             view                  = RoiLast.YT;
%         elseif ~RoiLast.XY.isActive && ~RoiLast.YT.isActive
%             error('Need to activate view first');
%         else
%             error('Both views can not be active');
%         end
        
        xData                   = [get(view.hShape,'xdata') newPoint(1)];
        yData                   = [get(view.hShape,'ydata') newPoint(2)];
        set(view.hShape,'xdata',xData,'ydata',yData ,'color','b');
        
        % no scaling after position set
        %ViewXY.Position   
        view.pos                = [min(xData) min(yData) max(xData)-min(xData) max(yData)-min(yData)];
        
        %  show it
        set(view.hShape,   'visible','on');
        
          
        %if RoiLast.XY.isActive && ~RoiLast.YT.isActive,
            RoiLast.XY      = view ;
%         elseif ~RoiLast.XY.isActive && RoiLast.YT.isActive,
%             RoiLast.YT      = view ;
%         end
      
        
        
    case 'setPosXY',
        % redraw the last ROI object pos
        pos                     = Data;
        view                   = RoiLast.XY;
        
        switch RoiLast.Type,
            case Par.ROI_TYPES.RECT,
                xy          = repmat(pos(1:2),5,1) + [0 0;pos(3) 0;pos(3) pos(4); 0 pos(4);0 0];
            case Par.ROI_TYPES.ELLIPSE,
                xyr         = pos(3:4)/2;        % radius
                xyc         = pos(1:2)+ xyr;     % center
                tt          = linspace(0,2*pi,30)';
                xy          = [cos(tt)*xyr(1) + xyc(1), sin(tt)*xyr(2) + xyc(2)];
            case Par.ROI_TYPES.FREEHAND,
                pos_old     = RoiLast.rectangleInitialPosition;
                xy_old      = RoiLast.shapeInitialDrawing;
                % rescale
                xyc         = pos(1:2)      + pos(3:4)/2;     % center
                xyc_old     = pos_old(1:2)  + pos_old(3:4)/2;     % center
                x           = (xy_old(:,1) - xyc_old(1))*pos(3)/(eps+pos_old(3)) + xyc(1);
                y           = (xy_old(:,2) - xyc_old(2))*pos(4)/(eps+pos_old(4)) + xyc(2);
                xy          = [x(:) y(:)];
        end;
        RoiLast.Position        = pos; %[x,y,w,h]
        view.pos                = pos;
        xyc                     = PosToRect(pos);
        %[pos;pos_old]
        
        % rect to xy
        set(view.hShape,     'xdata',xy(:,1),'ydata',xy(:,2),'visible','on');
        set(view.hBoundBox,  'position',pos,'visible','on');
        set(view.hCornRect, 'xdata',xyc(:,1),'ydata',xyc(:,2),'visible','on');
        
%         cornerRectangles        = getCornerRectangles(RoiLast.Position);
%         for j=1:8,
%             set(RoiLast.XY.hCornRect(j), 'position',cornerRectangles{j},'visible','on');
%         end
        set(view.hText,'pos',pos(1:2)+[5,5], 'visible','on')
        
        RoiLast.XY      = view ;
       
    case 'setColor',
        % redraw the last ROI object pos
        clr                         = Data;
        RoiLast.Color               = clr;   % remember
        set(RoiLast.XY.hShape,     'Color',    clr, 'visible','on');
        set(RoiLast.XY.hBoundBox,  'edgeColor',clr);
        set(RoiLast.XY.hCornRect,  'Color',    clr);
        set(RoiLast.XY.hText,      'color',    clr)
        
    case 'setName',
        % redraw the last ROI object pos
        RoiLast.Name        = Data;   % remember
        set(RoiLast.XY.hText,  'string', RoiLast.Name,   'visible','on')
        %set(RoiLast.YT.hText,  'string', RoiLast.Name,   'visible','on')
        
    case 'setAverType',
        % properties for the subsequent processing
        RoiLast.AverType        = Data;   % remember
        
    case 'setZInd',
        % stack position
        RoiLast.zInd            = Data;
        
    case 'setTInd',
        RoiLast.tInd             = Data;           % location in T stack
        
    case 'removeHandles',
        % delete graphics of the lastROI
        %if activeRectangleIndex < 1, return; end;
        
        %remove the rectangle at the index given
        delete(RoiLast.XY.hShape);
        delete(RoiLast.XY.hBoundBox);
        delete(RoiLast.XY.hCornRect);
        delete(RoiLast.XY.hText);
        
    case 'OnOffShape',
        % turn graphics on
        turnOn  = 'off';
        if Data > 0, turnOn  = 'on';  end;
        
        set(RoiLast.XY.hShape,     'visible',turnOn);
        set(RoiLast.XY.hBoundBox,  'visible',turnOn);
        set(RoiLast.XY.hCornRect,  'visible',turnOn);
        set(RoiLast.XY.hText,      'visible',turnOn);
        
    case 'OnOffBoundBox',
        % turn bound box on/off
        if Data > 0,
            turnOn  = 'on';
            curv    = RoiLast.XY.curv;
            clr     = RoiLast.XY.clr;
        else
            turnOn  = 'off';
            curv    = [0 0];
            clr    = 'g';
        end;
        
        
        set(RoiLast.XY.hShape,     'Color',     clr,'visible','on');
        set(RoiLast.XY.hBoundBox,  'edgeColor', clr,'visible',turnOn, 'curvature', curv);
        set(RoiLast.XY.hCornRect,  'Color',     clr,'visible',turnOn);
        set(RoiLast.XY.hText,      'color',     clr,'visible','on');
 
   case 'OnOffShapeOnly',
        % turn bound box on/off
        if Data > 0,
            turnOn  = 'on';
            curv    = RoiLast.XY.curv;
            clr     = RoiLast.XY.clr;
        else
            turnOn  = 'off';
            curv    = [0 0];
            clr    = 'g';
        end;
        
        
        set(RoiLast.XY.hShape,     'Color',     clr,'visible','on');
        set(RoiLast.XY.hBoundBox,  'edgeColor', clr,'visible',turnOn, 'curvature', curv);
        set(RoiLast.XY.hCornRect,  'Color',     clr,'visible',turnOn);
        set(RoiLast.XY.hText,      'color',     clr,'visible',turnOn);
         
        
    case 'saveInitRef',
        
        % help varibles
        RoiLast.rectangleInitialPosition    = Data; %RoiLast.Position;
        RoiLast.shapeInitialDrawing         = [get(RoiLast.XY.hShape,'xdata')' get(RoiLast.XY.hShape,'ydata')']; 
        
        
    case 'updateView',
        
        % redraw XY view according to info from YT view
        
        % check if YT is initialized
        if ~isfield(RoiLast.YT,'hBoundBox'), return; end;
        
        % extract Y length from YT space
        posXY                = get(RoiLast.XY.hBoundBox,'pos');
        posYT                = get(RoiLast.YT.hBoundBox,'pos');
        
        % position is defined by
        posXY([2 4])         = posYT([2 4]);
        
        % redefine the shape
        TPA_ManageLastRoi('setPos',posXY);
        % update color
        TPA_ManageLastRoi('setClr',RoiLast.Color);
        
        
    otherwise
        error('Unknown Cmnd : %s',Cmnd)
        
end % switch
end

%%%%%%%
% Help Fun
%%%%%%%
% =============================================
function xy = PosToRect(pos)
    % Helper function that transforms position to corner rectangles
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

