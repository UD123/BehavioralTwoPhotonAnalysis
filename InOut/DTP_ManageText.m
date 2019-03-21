function DTP_ManageText(handles,  txt, severity ,quiet)
% This manages info display

% Ver    Date     Who  Description
% ------ -------- ---- -------
% 01.01  12/09/12 UD   adopted from SMT  

if nargin < 1, handles = [];                    end;
if nargin < 2, txt = 'connect';                 end;
if nargin < 3, severity = 'I';                  end;
if nargin < 4, quiet = 0;                       end;

if quiet > 0, return; end
% print to screen
NoGUI = isempty(handles);


if strcmp(severity,'I')
    col = 'k';
elseif strcmp(severity,'W')
    col = 'b';
elseif strcmp(severity,'E')
    col = 'r';
else
    col = 'k';
end

if NoGUI
    fprintf('%s : %s\n',severity,txt);
    %fprintf('%s',txt);
else
    set(handles.textConsole,'string',txt,'ForegroundColor',col);
end


