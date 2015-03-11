function [Par,strROI] = DTP_MeasurementsROI(Par,ImStack,strRecord,strROI,FigNum)
% DTP_MeasurementsROI - displays time beahivios for each ROI.
% Allows different manual measurments
% Inputs:
%   Par         - control structure 
%   ImStack     -  nR x nC x nZstack x nTime  image in the directory
%   strRecord   - structure with Physiology data recordings
%	strROI      - ROI structure
%   
% Outputs:
%   Par         - control structure updated
%               - print to screen/matlab window
%	strROI      - ROI structure with measurements

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 14.00 25.12.13 UD     Janelia no Physiology
% 12.01 14.09.13 UD     Support Z stack
% 11.09 20.08.13 UD     Fix baseline
% 11.08 13.08.13 UD     Created
%-----------------------------

if nargin < 3,  error('Need 3 parameters');        end;
if nargin < 4,  FigNum      = 11;                  end;

if FigNum < 1, return; end;


%%%%%%%%%%%%%%%%%%%%%%
% Setup
%%%%%%%%%%%%%%%%%%%%%%


[nR,nC,nZ,nT]           = size(ImStack);
zStackInd               = Par.ZStackInd;
numROI                  = length(strROI);


% fixed with correct record load
timeImage               = (1:nT);
frameTime               = median(diff(timeImage));  % time between consequitive frames
roiData                 = zeros(numROI,nT);



%%%%%%%%%%%%%%%%%%%%%%
% Show
%%%%%%%%%%%%%%%%%%%%%%
hcross = []; hrect = []; hRoiLine = [];
ax     = zeros(3,numROI);
% FOR MARIA
for k = 1:numROI,
    %subplot(numROI,1,k),
    figure(FigNum + k),set(gcf,'Tag','AnalysisROI'),clf;
    %subplot(6,1,[1 4]),imagesc(timeImage,1:size(strROI{k}.meanROI,1),strROI{k}.meanROI,Par.DataRange), %colorbar;
    subplot(7,1,[1 4]),imagesc(timeImage,1:size(strROI{k}.procROI,1),strROI{k}.procROI,Par.dFFRange), %colorbar;
    colorbar('NorthOutside')
    hold on;
    hcross(k) = plot([0 0],[0 0],'color','k','LineStyle','-.','LineWidth',2);
    hold off;
    ax(1,k) = gca;
    title(sprintf('dF/F : %s',strROI{k}.name)),
    ylabel('Line Pix'),
    
    subplot(7,1,[5 6]),plot(timeImage, timeImage*0);
    hold on;
    hrect(k) = plot([0 0],[0 0],'color','k','LineStyle',':');
    hold off;
    ax(2,k) = gca;
    ylabel('Amp [Volt]'),
    
    
    subplot(7,1,[7]),
    hRoiLine(k) = plot(timeImage, strROI{k}.procROI(1,:));
    ylim(Par.dFFRange)
    ax(3,k) = gca;

    ylabel(sprintf('dF/F : %d',1)),
    xlabel('Time [sec]'),


    linkaxes(ax(:,k),'x')
    
    % save data for next image
    roiData(k,:) = strROI{k}.procROI(1,:);
    
    
    % Install Cross Probing
    set(gcf,'WindowButtonDownFcn',@hFig1_wbdcb)
    %set(gcf,'WindowButtonMotionFcn',@hFig1_wbdcb)
    
    set(ax(:,k),'DrawMode','fast');

    
end;

%%%%%%%%%%%%%%%%%%%%%%
% Prepare image data
%%%%%%%%%%%%%%%%%%%%%%

% selection
m = 1;
k = k + 1;  % figure numbering    
figure(FigNum + k),hFig2 = gcf; set(hFig2,'Tag','AnalysisROI')
hIm         = imagesc(ImStack(:,:,zStackInd,m),Par.DataRange);  colorbar('east'); colormap(gray); 
hTtl        = title(sprintf('Fluorescence Image %s Time %d, ZStack %d',Par.expName,m,zStackInd),'interpreter','none');
hold on
roiNames    = cell(numROI,1);
hRoi        = []; hLine = [];
for n = 1:numROI,
    %subplot(numROI,1,k),
        
    hRoi(n)  = plot(strROI{n}.xy(:,1),strROI{n}.xy(:,2),'color',strROI{n}.color);
    roiNames{n} = strROI{n}.name; %sprintf('Border : %s',strROI{k}.name);

end;
hMark = plot(1,0,'oy','MarkerSize',1);

hold off
legend(roiNames,'interpreter','none')
%set(hFig2,'WindowButtonDownFcn',@hFig2_wbdcb)
%set(hFig2,'WindowButtonMotionFcn',@hFig2_wbdcb)


%%%%%%%%%%%%%%%%%%%%%%
% Collect All ROIs
%%%%%%%%%%%%%%%%%%%%%%

% selection
m = 1;
k = k + 1;  % figure numbering    
figure(FigNum + k),hFig3 = gcf; set(hFig3,'Tag','AnalysisROI'); 

% delete previous toolbar
delete(findobj('Tag','TbCurs'));
 
cax = zeros(2,1);
subplot(7,1,[1 3]),cax(1) = gca;
plot(timeImage, timeImage*0);
%legend(showNames{recordInd})
title(sprintf('Electro Physiology %s Time %d, ZStack %d',Par.expName,m,zStackInd),'interpreter','none')
ylabel('Amp [Volt]')

hRoiAll     = []; 
subplot(7,1,[4 7]), cax(2) = gca;
for n = 1:numROI,
    %subplot(numROI,1,k),
        
    hRoiAll(n)  = plot(timeImage,roiData(n,:),'color',strROI{n}.color); hold on;

end;
ylim(Par.dFFRange)

hold off
legend(roiNames,'interpreter','none')
ylabel(sprintf('All Current ROIs dF/F ')),
xlabel('Time [sec]'),
linkaxes(cax,'x')

% put cursors
%DTP_ManageCursors(hFig3,cax(2))

%%%%%%%%%%%%%%%%%%%%%%
% Install Cursors
%%%%%%%%%%%%%%%%%%%%%%


% Pictures for the toolbar buttons
pics    = CreatePics();

% Create the figure and controls
handles.Fig    = hFig3; %figure('Tag','Fig','Name','Cursors Demo','NumberTitle','off','MenuBar','none','Toolbar','none','Position',[200 200 550 550],'Color',[1 1 1]);
handles.Axe    = cax(2); %axes('Parent',handles.Fig,'Tag','Axe','Units','pixels','Position',[50 200 450 325]);
handles.TbCurs = uitoolbar('Parent',handles.Fig,'Tag','TbCurs');

handles.PtAdd1  = uipushtool('Parent',handles.TbCurs,'Tag','PtAdd1','CData',pics.Plus,  'ClickedCallback',@PtAdd1_ClickedCallback,'TooltipString','Add cursor');
handles.PtDel1  = uipushtool('Parent',handles.TbCurs,'Tag','PtDel1','CData',pics.Minus, 'ClickedCallback',@PtDel1_ClickedCallback,'TooltipString','Remove last cursor');
handles.PtVal1  = uipushtool('Parent',handles.TbCurs,'Tag','PtVal1','CData',pics.Val,   'ClickedCallback',@PtVal1_ClickedCallback,'TooltipString','Display cursors measurements');
handles.PtSave  = uipushtool('Parent',handles.TbCurs,'Tag','PtSave','CData',pics.Save,  'ClickedCallback',@PtSave_ClickedCallback,'TooltipString','Save cursor measurements and exit');


% Init Cursor structure
mycurs1 = [];
mycurs2 = [];
if isfield(Par,'strCursor')
    if ~isempty(Par.strCursor),
        PtInit_Cursors(Par.strCursor.mycurs1val,Par.strCursor.mycurs2val)
    end;
end;

% wait for figure to end
uiwait(gcf);

%%%%%%%%%%%%%%%%%%%%%%
% Compute measurements for all Cursors and ROIs
%%%%%%%%%%%%%%%%%%%%%%

for k = 1:numROI,
    roiData                     = strROI{k}.procROI;
    fMeasResults                = local_measureCursors(roiData);
    strROI{k}.measROI           = fMeasResults;
end;

%%%%%%%%%%%%%%%%%%%%%%
% Close all figures
%%%%%%%%%%%%%%%%%%%%%%
% disable cursors
hc  =  mycurs1.hdl(); 
if ~isempty(hc), delete(hc); end; %set(hc,'Visible','off');
hc  =  mycurs2.hdl(); 
if ~isempty(hc), delete(hc); end; %set(hc,'Visible','off');

% delete toolbar
delete(findobj('Tag','TbCurs'));
% no figure at all
close(FigNum + (1:numROI))
close(hFig2);
close(hFig3);

    
DTP_ManageText([], sprintf('saving Cursor mesurements for each ROI '), 'I' ,0)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%
%%%      CALLBACKS
%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%
% Install Cross Probing
%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%
    % hFig1 - Callbacks
    %%%%%%%%%%%%%%
    function hFig1_wbdcb(src,evnt)
        hFig1       = src;
        roiInd      = hFig1 - FigNum;  % which image has been clicked
        if strcmp(get(hFig1,'SelectionType'),'normal')
            %set(src,'pointer','circle')
            cp = get(ax(1,roiInd),'CurrentPoint');
            
            xinit = cp(1,1);
            xinit = (xinit) + [1 1]*0;
            XLim = get(gca,'XLim');        
            % check the point location
            if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
            
            %yinit = [yinit yinit];
            yinit = cp(1,2);
            yinit = round(yinit) + [1 1]*0;
            YLim = get(gca,'YLim');         
            if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
            
            % get all the info
            lineInd     = yinit(1);        % which ROI line index
            frameInd    = min(nT,ceil(xinit(1)/frameTime));        % frame number in time
            zStackInd   = strROI{roiInd}.zInd;
           
            
            % show cross
            figure(hFig1),
            axes(ax(1,roiInd))
            lineX     = [xinit NaN XLim];
            lineY     = [YLim NaN  yinit];
            set(hcross(roiInd),'XData',lineX,'YData',lineY);
            
            axes(ax(2,roiInd))
            YLim      = get(gca,'YLim'); 
            rectX     = [xinit xinit + frameTime xinit(1)];
            rectY     = [YLim YLim([2 1])         YLim(1)];
            set(hrect(roiInd),'XData',rectX,'YData',rectY);
            
            
            % show selected line of ROI
            axes(ax(3,roiInd))
            set(hRoiLine(roiInd) ,'ydata', strROI{roiInd}.procROI(lineInd,:));
            ylabel(sprintf('dF/F : %d',lineInd))
            
            % update image
            figure(hFig2),
            set(hIm,'cdata',ImStack(:,:,zStackInd,frameInd));
            set(hTtl,'string',sprintf('Image %s  : Time %4.2f, ZStack %d',Par.expName,xinit(1),zStackInd),'interpreter','none')
            % highlight appropritae ROI
            set(hRoi,'Visible','off');
            set(hRoi(roiInd),'Visible','on');
           
            % draw mark of location
            [rLine,cLine] = ind2sub([nR,nC],strROI{roiInd}.lineInd);
            set(hMark, 'xdata',cLine(lineInd),'ydata',rLine(lineInd),'MarkerSize',16);
            
            % update ROI image
            figure(hFig3),        
            roiData(roiInd,:) = strROI{roiInd}.procROI(lineInd,:); % compute ROI props after markers
            set(hRoiAll(roiInd) ,'ydata', roiData(roiInd,:));
            
            

            % return attention to figure 1
            figure(hFig1), 
            
            
        end
    end


%*******************************************************************************

 function PtInit_Cursors(val1,val2)
    % Adds a cursor on the graph from init - not a callback

    % If no cursor was created, simply initializes one
    mycurs1 = mycursors(handles.Axe,'k',val1(1)); % Create the first cursor and store the structure of function handles
    mycurs2 = mycursors(handles.Axe,'r',val2(1)); % Create the first cursor and store the structure of function handles
    for c = 2:length(val1)
        mycurs1.add(val1(c)); % Add a cursor to the graph
        mycurs2.add(val2(c)); % Add a cursor to the graph
    end

  end

% --- FIRST CURSOR SET ----------------------------------------------

  function PtAdd1_ClickedCallback(varargin)
    % Adds a cursor on the graph

    % If no cursor was created, simply initializes one
    if isempty(mycurs1)
      mycurs1 = mycursors(handles.Axe,'k'); % Create the first cursor and store the structure of function handles
      mycurs2 = mycursors(handles.Axe,'r'); % Create the first cursor and store the structure of function handles
    else
      mycurs1.add(); % Add a cursor to the graph
      mycurs2.add(); % Add a cursor to the graph
    end

  end

  function PtDel1_ClickedCallback(varargin)
    % Removes the last cursor added

    % Execute code only if at least one cursor has already been added
    if ~isempty(mycurs1)
      mycurs1.off('last');
      mycurs2.off('last');
    end

  end

  function PtVal1_ClickedCallback(varargin)
    % Displays the positions of all cursors

    % Execute code only if at least one cursor has already been added
    if ~isempty(mycurs1)

      % Get cursors positions
      data1t = mycurs1.val();
      data2t = mycurs2.val();
      
      % Ignore cursor order and round values
      data1 = (min(data1t,data2t));
      data2 = (max(data1t,data2t));
      
      % compute base line for cursor pair 1
      eBaseLineVal = 0;
      iBaseLineVal = zeros(numROI,1);
      
      % valid indixes for electrophysiology and  image frames
      
      for c = 1:length(data1),
          
          %evInd = data1(c) <= timeRecord & timeRecord <= data2(c);
          ivInd = data1(c) <= timeImage  & timeImage <= data2(c);
          
          if  ~any(ivInd),
              
              fprintf(' Cursors %d \t : Placement is out of range or too close\n\n',c)
              continue;
              
          end;
          
          % statistics
          %dVal      = strRecord.recordValue(evInd,recordInd(1));
          %dValLen   = length(dVal);
          
          fprintf(' Cursor  %2d   \t : Statistics : \n',c)
          fprintf(' --------------------------------\n')
          
          for n = 1:numROI,
              
              dVal      = roiData(n,ivInd);
              dValLen   = length(dVal);
              
              dMean     = mean(dVal) ;
              dMax      = max(dVal)  ;
              
              
              % first Cursor acts like Base Line
              if c == 1,   iBaseLineVal(n) = dMean; end;
              
              dMeanBL  = mean(dVal) - iBaseLineVal(n);
              dMaxBL   = max(dVal)  - iBaseLineVal(n);
              
              
              txt       = sprintf('Mean : %4.3f, Max : %4.3f, Area : %4.3f, Mean-BL : %4.3f, Max-BL : %4.3f ',dMean,dMax,dMean*dValLen,dMeanBL,dMaxBL);
              fprintf(' %12s\t : %s \n',roiNames{n},txt);
          end;
          
          fprintf('\n')
          
          
      end;
% 
      
    end

  end

  % exit from the entire sequence
  function PtSave_ClickedCallback(varargin)
    % Removes the last cursor added

      % Save cursor data
      Par.strCursor.mycurs1val = mycurs1.val();
      Par.strCursor.mycurs2val = mycurs2.val();
      
      uiresume(gcbf)

  end




% --- OTHER NESTED FUNCTIONS ----------------------------------------

  function pics = CreatePics()
    % Generate pictures matrices to use in the toolbar
    
    % + sign
    pics.Plus  = repmat([ ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN   ...
      ],[1,1,3]);
    
    % - sign
    pics.Minus = repmat([ ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN   ...
      ],[1,1,3]);
    
    % Matrix
    pics.Val = repmat([ ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN   0   0 NaN NaN   0   0   0 NaN NaN   0   0   0 NaN NaN ; ...
      NaN   0 NaN   0 NaN NaN NaN NaN   0 NaN NaN NaN NaN   0 NaN NaN ; ...
      NaN NaN NaN   0 NaN NaN   0   0   0 NaN NaN NaN   0   0 NaN NaN ; ...
      NaN NaN NaN   0 NaN NaN   0 NaN NaN NaN NaN NaN NaN   0 NaN NaN ; ...
      NaN NaN NaN   0 NaN NaN   0   0   0 NaN NaN   0   0   0 NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN   0 NaN NaN NaN NaN   0   0   0 NaN NaN   0   0   0 NaN NaN ; ...
      NaN   0 NaN   0 NaN NaN   0 NaN NaN NaN NaN   0 NaN NaN NaN NaN ; ...
      NaN   0   0   0 NaN NaN   0   0   0 NaN NaN   0   0   0 NaN NaN ; ...
      NaN NaN NaN   0 NaN NaN NaN NaN   0 NaN NaN   0 NaN   0 NaN NaN ; ...
      NaN NaN NaN   0 NaN NaN   0   0   0 NaN NaN   0   0   0 NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN   ...
      ],[1,1,3]);
  
    % - save
    pics.Save = repmat([ ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN   0   0 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN   0   0 NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN   0   0   0   0   0   0   0   0   0   0 NaN NaN NaN ; ...
      NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN   ...
      ],[1,1,3]);
  
    
    pS = [16 16 3];
    col = [1 0 0]; % Red
    
    % + sign in red
    pics.PlusR = pics.Plus;
    pics.PlusR(pics.PlusR==0) = 1;
    pics.PlusR = reshape( repmat(col,pS(1)*pS(2),1) .* reshape(pics.PlusR,pS(1)*pS(2),3) , pS );
    
    % - sign in red
    pics.MinusR = pics.Minus;
    pics.MinusR(pics.MinusR==0) = 1;
    pics.MinusR = reshape( repmat(col,pS(1)*pS(2),1) .* reshape(pics.MinusR,pS(1)*pS(2),3) , pS );
    
    % Matrix in red
    pics.ValR = pics.Val;
    pics.ValR(pics.ValR==0) = 1;
    pics.ValR = reshape( repmat(col,pS(1)*pS(2),1) .* reshape(pics.ValR,pS(1)*pS(2),3) , pS );

  end


 function fMeasResults = local_measureCursors(roiData)
    % Computes roiData values from all cursors
    % roiData - nLines x nT matrix
    
    nLines  = size(roiData,1);
    measNum = 5; % number of measurements Mean,Max,Area,Mean-Bl, Max-BL
    
    %fMeasResults  = [];  % electro phsiology results
    fMeasResults = []; % fluorescence results
    
    % Execute code only if at least one cursor has already been added
    if ~isempty(mycurs1)

      % Get cursors positions
      data1t = mycurs1.val();
      data2t = mycurs2.val();
      
      % Ignore cursor order and round values
      data1 = (min(data1t,data2t));
      data2 = (max(data1t,data2t));
      
    
      cursorNum = length(data1);
      fMeasResults = zeros(nLines+1,measNum,cursorNum); % fluorescence + electro phsiology results
      
      
      % compute base line for cursor pair 1
      eBaseLineVal = 0;
      iBaseLineVal = zeros(nLines,1);
      
      % valid indixes for electrophysiology and  image frames
      
      for c = 1:length(data1),
          
          evInd = data1(c) <= timeRecord & timeRecord <= data2(c);
          ivInd = data1(c) <= timeImage  & timeImage <= data2(c);
          
          if ~any(evInd) || ~any(ivInd),
              
              fprintf(' Cursors %d \t : Placement is out of range or too close\n\n',c)
              continue;
              
          end;
          
          % statistics
          dVal      = strRecord.recordValue(evInd,recordInd(1));
          dValLen   = length(dVal);
                              
          dMean     = mean(dVal) ;
          dMax      = max(dVal)  ;
          
          % first Cursor acts like Base Line
          if c == 1,   eBaseLineVal = dMean; end;
          
          dMeanBL  = mean(dVal) - eBaseLineVal;
          dMaxBL   = max(dVal)  - eBaseLineVal;
          
          fMeasResults(nLines+1,1,c) = dMean;
          fMeasResults(nLines+1,2,c) = dMax;
          fMeasResults(nLines+1,3,c) = dMean*dValLen;
          fMeasResults(nLines+1,4,c) = dMeanBL;
          fMeasResults(nLines+1,5,c) = dMaxBL;
          
          for n = 1:nLines,
              
              dVal      = roiData(n,ivInd);
              dValLen   = length(dVal);
              
              dMean     = mean(dVal) ;
              dMax      = max(dVal)  ;
              
              % first Cursor acts like Base Line
              if c == 1,   iBaseLineVal(n) = dMean; end;
              
              dMeanBL  = mean(dVal) - iBaseLineVal(n);
              dMaxBL   = max(dVal)  - iBaseLineVal(n);
              
              fMeasResults(n,1,c) = dMean;
              fMeasResults(n,2,c) = dMax;
              fMeasResults(n,3,c) = dMean*dValLen;
              fMeasResults(n,4,c) = dMeanBL;
              fMeasResults(n,5,c) = dMaxBL;
          end;
          
          
      end;
      
    end

  end

  end
