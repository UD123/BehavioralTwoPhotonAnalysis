function TPA_EventListenChild



  fh   = figure('Pos', [400 400 300 300]);
  graph= axes('parent',fh, 'units', 'pixel','pos',[30 50 250 220]);
  lbl1 = uicontrol(fh,'style', 'text', 'pos',[0 0 100 20]);
  

  
  % when child is created it registers itself
  global handFigList;
  
  hMainGui = getappdata(0, 'hMainGui');
  %fSyncAll = getappdata(hMainGui, 'fSyncAll');
  %addlistener(hMainGui,'fSyncAll',@fUpdateText);
  hListener = handle.listener(fh,'fSyncAll',@fUpdateText);
  setappdata(fh, 'listeners', hListener);
  
  % add
  childNum  = length(handFigList);
  handFigList(childNum+1) = fh;
  set(fh,'Name',sprintf('Child %d',childNum+1));
  set(fh, 'WindowButtonMotion',@fUserInput);
  set(fh,'CloseRequestFcn', {@fCloseRequestFcn});

  

  %lh=addlistener(fh, 'WindowButtonMotion',@lbl1_cb);
  function fUserInput(src, eventdata)
    pos = get(graph,'currentpoint');
    %set(lbl1,'string', pos(1,1));
    %fUpdateText(src, eventdata, pos(1,1))  
    
   %updEvent = TPA_EventListen( pos(1,1), pos(1,2));
   %notify(obj,'fSyncAll',updEvent)
   evtData = handle.EventData(fh, 'fSyncAll');
   fh.send('fSyncAll', evtData) 
   %notify(hMainGui,'fSyncAll',evtData);
    % sync all of them
    %feval(fSyncAll,pos(1,1));
    
  end 

 function fUpdateText(src, eventdata, pos)
    set(lbl1,'string', pos(1,1));
  end 


   function fCloseRequestFcn(~, ~)
        % remove from the list
        ii = find(handFigList == fh);
        handFigList(ii) = [];
        delete(fh);
   end


end
