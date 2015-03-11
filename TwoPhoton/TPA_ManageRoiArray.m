function [RoiLast,Data] = TPA_ManageRoiArray(RoiLast,Cmnd,Data)
% TPA_ManageRoiArray - manages List of ROI data
% It written is similar to clas strcuture but it is not standard
% There are performance and management issues

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 16.10 21.02.14 UD     Get 4 windows sync back on move
%-----------------------------
global Par;                                 % connects to global definitions
if nargin < 1, Par = TPA_ParInit(); end;    % standalone run
if nargin < 2, Cmnd = 'init';       end;
if nargin < 3, Data = 0;            end;


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
        
        
        clr                     = SData.strROI{activeIndx}.Color;
        set(roiLast.XY.hShape,     'color',    clr,'visible','on');
        set(roiLast.XY.hBoundBox,  'edgeColor',clr,'visible','on', 'curvature', curv);
        set(roiLast.XY.hCornRect,  'edgeColor',clr,'visible','on');
        set(roiLast.XY.hText,      'color',    clr,'visible','on')
        
        foiLast   = TPA_ManageLastRoi(foiLast,'OnOffBoundBox',1);
        
        % gui support
        rectangleInitialPosition    = SData.strROI{activeIndx}.Position;
        shapeInitialDrawing         = [get(roiLast.XY.hShape,'xdata')' get(roiLast.XY.hShape,'ydata')'];
        
        foiLast   = TPA_ManageLastRoi(foiLast,'saveInitRef',1);
        
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


