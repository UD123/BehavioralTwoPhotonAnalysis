function TPA_ListenTestMain

% creates main gui to manage childs figures
% figures are opened according to user will
% sync user action over different childs

% WORKING

hMainGui   = figure('Pos', [400 400 300 100]);
%graph=axes('parent',hMainGui, 'units', 'pixel','pos',[30 50 250 220]);
lbl1 = uicontrol(hMainGui,'style', 'text', 'pos',[0 0 100 20]);
set(hMainGui,'CloseRequestFcn', {@fCloseRequestFcn});

set(hMainGui,'Name',sprintf('Main'));

% another global info
setappdata(0, 'hMainGui',hMainGui);
setappdata(hMainGui, 'fSyncAll', @fSyncAll);
setappdata(hMainGui, 'posInfo', [0]); % global info

% child list
global handFigList;
handFigList = [];

%lh=addlistener(hMainGui, 'WindowButtonMotion',@lbl1_cb);
%set(hMainGui, 'WindowButtonMotion',@fSyncAll);

    function fSyncAll(posInfo)
        
        %posInfo = getappdata(hMainGui, 'posInfo'); % global info
        
        for m = 1:length(handFigList),
            fUpdateText = getappdata(handFigList(m), 'fUpdateText');
            feval(fUpdateText,0,0,posInfo);
        end
        
        % update GUI
        set(lbl1,'string', posInfo);
    end



    function fCloseRequestFcn(~, ~)
        % remove all
        delete(handFigList)
        delete(hMainGui);
    end


end
