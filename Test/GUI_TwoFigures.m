function [] = GUI_TwoFigures(guiNum)
% Demonstrate the use of a uicontrol to manipulate an axes from a GUI,
% and how to link two figures to close together.  
% The slider here controls the extent of the x lims up to a certain point.
%
% Suggested exercise: Alter the code so that an axes handle could be passed
% in as an argument.  Or a two-slider GUI could be made that controls both 
% the x and y limits.  Even more advanced:  Allow the GUI to replot if the
% limits go beyond current data.  This would require another input
% argument.
%
%
% Author:  Matt Fig
% Date:  7/15/2009

if nargin < 1, guiNum = 1; end;


% Now create the other GUI
S.fh = figure('units','pixels',...
              'position',[400+guiNum*400 400 500 400],...
              'menubar','none',...
              'name',sprintf('GUI_%d',guiNum),...
              'numbertitle','off',...
              'resize','off');
          
S.ax = axes;  % This axes will be controlled.
% First create the figure and plot to manipulate with the slider.
x = 0:.1:100;  % Some simple data.  Notice the data goes beyond xlim.
xlim([0,pi]);  % Set the beginning x/y limits.
ylim([-1,1])
plot(x,sin(x));
          
S.sl = uicontrol('style','slide',...
                 'unit','pixel',...
                 'position',[10 10 200 20],...
                 'min',1,'value',pi,'max',100,...
                 'callback',{@sl_call,guiNum});
                 
                 %'deletefcn',{@delete,f});
             
setappdata(S.fh,'S',S);
%set(f,'deletef',{@delete,S.fh})  % Closing one closes the other.
 

function [] = sl_call(varargin) 
% find another GUI
guiNumOther = 1 - varargin{3};
hFig        = findobj('name',sprintf('GUI_%d',guiNumOther));
otherS      = getappdata(hFig,'S');
% Callback for the slider.
hSlide      = varargin{1};  % Get the calling handle and structure.
set(otherS.ax,'xlim',[0 get(hSlide,'val')],'ylim',[-1,1])

