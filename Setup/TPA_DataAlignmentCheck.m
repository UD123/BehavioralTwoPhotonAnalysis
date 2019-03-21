function varargout = TPA_DataAlignmentCheck(varargin)
% TPA_DATAALIGNMENTCHECK MATLAB code for TPA_DataAlignmentCheck.fig
%      TPA_DATAALIGNMENTCHECK, by itself, creates a new TPA_DATAALIGNMENTCHECK or raises the existing
%      singleton*.
%
%      H = TPA_DATAALIGNMENTCHECK returns the handle to a new TPA_DATAALIGNMENTCHECK or the handle to
%      the existing singleton*.
%
%      TPA_DATAALIGNMENTCHECK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TPA_DATAALIGNMENTCHECK.M with the given input arguments.
%
%      TPA_DATAALIGNMENTCHECK('Property','Value',...) creates a new TPA_DATAALIGNMENTCHECK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TPA_DataAlignmentCheck_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TPA_DataAlignmentCheck_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TPA_DataAlignmentCheck

% Last Modified by GUIDE v2.5 21-Oct-2014 09:02:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TPA_DataAlignmentCheck_OpeningFcn, ...
                   'gui_OutputFcn',  @TPA_DataAlignmentCheck_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before TPA_DataAlignmentCheck is made visible.
function TPA_DataAlignmentCheck_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TPA_DataAlignmentCheck (see VARARGIN)

% Choose default command line output for TPA_DataAlignmentCheck
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TPA_DataAlignmentCheck wait for user response (see UIRESUME)

if nargin < 4,
    %addpath('..\SetUp\');
    Par  = TPA_ParInit;  % requires path to be set
end    
Par                 = varargin{1};  % assumes that exists
if ~isfield(Par,'SetupDir'),
    error('Input must be Par structure initialized')
end

setappdata(handles.figure1,'ParIn',  Par);  % keep original
setappdata(handles.figure1,'ParEdit',Par); % in edit mode

% init all listbox
fUpdateListBox(handles);

uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = TPA_DataAlignmentCheck_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% % support of the X box close
% if isempty(handles), return; end

% Get default command line output from handles structure
Par          = getappdata(handles.figure1,'ParEdit');  % 
%varargout{1} = handles.output;
varargout{1} = Par; %handles.output;
delete(handles.figure1)


% --- Executes on selection change in listboxTIF.
function listboxTIF_Callback(hObject, eventdata, handles)
% hObject    handle to listboxTIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxTIF contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxTIF

get(handles.figure1,'SelectionType');
% If double click
if ~strcmp(get(handles.figure1,'SelectionType'),'open'), return; end
% % delete entry
% index_selected = get(handles.listboxTIF,'Value');
% Par          = getappdata(handles.figure1,'ParEdit');  % 
% Par.DMT      = Par.DMT.RemoveRecord(index_selected);
% setappdata(handles.figure1,'ParEdit',Par);
% 
% fUpdateListBox(handles)

pushDeleteTIF_Callback(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function listboxTIF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxTIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white','Max',10);
end


% --- Executes on selection change in listboxTRF.
function listboxTRF_Callback(hObject, eventdata, handles)
% hObject    handle to listboxTRF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxTRF contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxTRF


get(handles.figure1,'SelectionType');
% If double click
if ~strcmp(get(handles.figure1,'SelectionType'),'open'), return; end
% % delete entry
% index_selected = get(handles.listboxTRF,'Value');
% Par            = getappdata(handles.figure1,'ParEdit');  % 
% Par.DMT        = Par.DMT.RemoveRecord(index_selected);
% setappdata(handles.figure1,'ParEdit',Par);
% 
% fUpdateListBox(handles)
pushDeleteTRF_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function listboxTRF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxTRF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white','Max',10);
end


% --- Executes on selection change in listboxBIF.
function listboxBIF_Callback(hObject, eventdata, handles)
% hObject    handle to listboxBIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxBIF contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxBIF


get(handles.figure1,'SelectionType');
% If double click
if ~strcmp(get(handles.figure1,'SelectionType'),'open'), return; end
% % delete entry
% index_selected = get(handles.listboxBIF,'Value');
% Par            = getappdata(handles.figure1,'ParEdit');  % 
% Par.DMB        = Par.DMB.RemoveRecord(index_selected);
% setappdata(handles.figure1,'ParEdit',Par);
% 
% fUpdateListBox(handles)
pushDeleteBIF_Callback(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function listboxBIF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxBIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white','Max',10);
end


% --- Executes on selection change in listboxBEF.
function listboxBEF_Callback(hObject, eventdata, handles)
% hObject    handle to listboxBEF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listboxBEF contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listboxBEF



get(handles.figure1,'SelectionType');
% If double click
if ~strcmp(get(handles.figure1,'SelectionType'),'open'), return; end
% % delete entry
% index_selected = get(handles.listboxBEF,'Value');
% Par            = getappdata(handles.figure1,'ParEdit');  % 
% Par.DMB        = Par.DMB.RemoveRecord(index_selected);
% setappdata(handles.figure1,'ParEdit',Par);
% 
% fUpdateListBox(handles)
pushDeleteBEF_Callback(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function listboxBEF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxBEF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white','Max',10);
end

% --- Executes on button press in pushDeleteTIF.
function pushDeleteTIF_Callback(hObject, eventdata, handles)
% hObject    handle to pushDeleteTIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% delete entry
index_selected = get(handles.listboxTIF,'Value');
Par          = getappdata(handles.figure1,'ParEdit');  % 
Par.DMT      = Par.DMT.RemoveRecord(index_selected,1);
setappdata(handles.figure1,'ParEdit',Par);

fUpdateListBox(handles)


% --- Executes on button press in pushBackTIF.
function pushBackTIF_Callback(hObject, eventdata, handles)
% hObject    handle to pushBackTIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% recover data back
ParIn        = getappdata(handles.figure1,'ParIn');  % 
ParEdit      = getappdata(handles.figure1,'ParEdit');  % 
ParEdit.DMT  = ParIn.DMT;  % 
setappdata(handles.figure1,'ParEdit', ParEdit)

fUpdateListBox(handles);

% --- Executes on button press in pushDeleteTRF.
function pushDeleteTRF_Callback(hObject, eventdata, handles)
% hObject    handle to pushDeleteTRF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% delete entry
index_selected = get(handles.listboxTRF,'Value');
Par            = getappdata(handles.figure1,'ParEdit');  % 
Par.DMT        = Par.DMT.RemoveRecord(index_selected,4);
setappdata(handles.figure1,'ParEdit',Par);

fUpdateListBox(handles)

% --- Executes on button press in pushBackTRF.
function pushBackTRF_Callback(hObject, eventdata, handles)
% hObject    handle to pushBackTRF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% recover data back
ParIn        = getappdata(handles.figure1,'ParIn');  % 
ParEdit      = getappdata(handles.figure1,'ParEdit');  % 
ParEdit.DMT  = ParIn.DMT;  % 
setappdata(handles.figure1,'ParEdit', ParEdit)

fUpdateListBox(handles);

% --- Executes on button press in pushDeleteBIF.
function pushDeleteBIF_Callback(hObject, eventdata, handles)
% hObject    handle to pushDeleteBIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% delete entry
index_selected = get(handles.listboxBIF,'Value');
Par            = getappdata(handles.figure1,'ParEdit');  % 
Par.DMB        = Par.DMB.RemoveRecord(index_selected,3);
setappdata(handles.figure1,'ParEdit',Par);

fUpdateListBox(handles)


% --- Executes on button press in pushBackBIF.
function pushBackBIF_Callback(hObject, eventdata, handles)
% hObject    handle to pushBackBIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% recover data back
ParIn        = getappdata(handles.figure1,'ParIn');  %
ParEdit      = getappdata(handles.figure1,'ParEdit');  % 
ParEdit.DMB  = ParIn.DMB;  % 
setappdata(handles.figure1,'ParEdit', ParEdit)

fUpdateListBox(handles);

% --- Executes on button press in pushDeleteBEF.
function pushDeleteBEF_Callback(hObject, eventdata, handles)
% hObject    handle to pushDeleteBEF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% delete entry
index_selected = get(handles.listboxBEF,'Value');
Par            = getappdata(handles.figure1,'ParEdit');  % 
Par.DMB        = Par.DMB.RemoveRecord(index_selected,4);
setappdata(handles.figure1,'ParEdit',Par);

fUpdateListBox(handles)


% --- Executes on button press in pushBackBEF.
function pushBackBEF_Callback(hObject, eventdata, handles)
% hObject    handle to pushBackBEF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% recover data back
ParIn        = getappdata(handles.figure1,'ParIn');  % 
ParEdit      = getappdata(handles.figure1,'ParEdit');  % 
ParEdit.DMB  = ParIn.DMB;  % 
setappdata(handles.figure1,'ParEdit', ParEdit)

fUpdateListBox(handles);

% --- Executes on button press in pushCheck.
function pushCheck_Callback(hObject, eventdata, handles)
% hObject    handle to pushCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check that number of files is the same
ParEdit      = getappdata(handles.figure1,'ParEdit');  % 
return
fileNum      = [ParEdit.DMT.VideoFileNum ParEdit.DMT.RoiFileNum ParEdit.DMB.VideoFileNum ParEdit.DMB.EventFileNum];
listHand     = [handles.listboxTIF handles.listboxTRF  handles.listboxBIF  handles.listboxBEF ];
clr          = get(handles.listboxTIF,'BackgroundColor');

% find outliers
[s,si]      = sort(fileNum);
v           = diff(s);
zi          = find(v == 0);
maxv        = length(zi);
ai          = 1:4;

clrInfo(2,:)= clr;  % matrix will alternate between colors

if maxv < 1, % all different
    redInd = ai;
    clrInfo(1,:) = [1 0.6 0.6];
elseif maxv == 2,
    if any(zi == 2), % in the middle - 2 and 2 are equal groups
        clrInfo = [1 1 0;1 0 1];
        redInd  = si(1:2);
    else
        redInd  = setdiff(ai,si([zi zi+1]));
        clrInfo(1,:) = [1 0.6 0.6];   
    end
    
elseif maxv == 1,
    redInd  = setdiff(ai,si([zi zi+1]));
    clrInfo(1,:) = [1 0.6 0.6];
    
else
    redInd  = ai;
    clrInfo(1,:) = [ 0.7569    0.8667    0.7765];    
end

for k = 1:3,
    set(listHand(redInd),'BackgroundColor',clrInfo(1,:)); pause(0.3);
    set(listHand(redInd),'BackgroundColor',clrInfo(2,:)); pause(0.3);
end
set(listHand,'BackgroundColor',clr)


% --- Executes on button press in pushSaveExit.
function pushSaveExit_Callback(hObject, eventdata, handles)
% hObject    handle to pushSaveExit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% assume that 
uiresume(handles.figure1);

% --- Executes on button press in pushExitNoSave.
function pushExitNoSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushExitNoSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% recover input data
Par          = getappdata(handles.figure1,'ParIn');  % 
setappdata(handles.figure1,'ParEdit',Par); % in edit mode
uiresume(handles.figure1);



% --- Init
function fUpdateListBox(handles)
% init all list boxes


% get data
Par          = getappdata(handles.figure1,'ParEdit');  % 
if isa(Par.DMT,'TPA_DataManagerPrarie') || isa(Par.DMT,'TPA_DataManagerTwoChannel')
fileNames    = Par.DMT.VideoDirNames;
else
fileNames    = Par.DMT.VideoFileNames;
end
set(handles.listboxTIF,'String',fileNames,'Value',1)

% get data
Par          = getappdata(handles.figure1,'ParEdit');  % 
fileNames    = Par.DMT.RoiFileNames;
set(handles.listboxTRF,'String',fileNames,'Value',1)

% get data
% Remove comb_video.avi
Par          = getappdata(handles.figure1,'ParEdit');  
if isa(Par.DMT,'TPA_DataManagerPrarie') || isa(Par.DMT,'TPA_DataManagerTwoChannel')
fileNames    = Par.DMT.VideoDirNames;
else
fileNames    = Par.DMB.VideoFrontFileNames; % cat(1,,Par.DMB.VideoSideFileNames);
end
set(handles.listboxBIF,'String',fileNames,'Value',1)

% get data
Par          = getappdata(handles.figure1,'ParEdit');  % 
fileNames    = Par.DMB.EventFileNames;
set(handles.listboxBEF,'String',fileNames,'Value',1)

return
