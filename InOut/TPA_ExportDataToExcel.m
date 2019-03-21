function Par = TPA_ExportDataToExcel(Par,ExcelExportType,DataStr, enableBrightShow)
% TPA_ExportDataToExcel - saves diffferent paarmeters and results in Excel file format

% Inputs:

%   Par       - control structure 
%   ExcelExportType - which type of export to do
%	DataStr    - ROI,Event structure
%   
% Outputs:
%   Par      - control structure updated

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 28.04 15.01.18 UD     Fixing export and adding enableBrightShow
% 27.13 26.12.17 UD     Fix event export
% 18.04 28.04.14 UD     Export to excel
% 13.07 27.10.13 UD     min value export
% 13.06 22.10.13 UD     rescaling data for excel
% 13.05 15.10.13 UD     fixing for Inbar
% 12.01 14.09.13 UD     Support Z stack
% 11.09 20.08.13 UD     export measurements of cursors to data directory
% 11.04 23.07.13 UD     export data original exp directory
% 10.11 08.07.13 UD     New format.
%-----------------------------
if nargin < 4, enableBrightShow = false; end

%%%%%%%%%%%%%%%%%%%%%%
% What kind of export
%%%%%%%%%%%%%%%%%%%%%%
if ~strcmp(ExcelExportType,'MultiTrial'),
    DTP_ManageText([], sprintf('Multi Trial : Only Multi Trial Export to excel is supported.'),  'W' ,0);
    return
end
warning('off', 'MATLAB:xlswrite:AddSheet');

%%%%%%%%%%%%%%%%%%%%%%
% Setup output file
%%%%%%%%%%%%%%%%%%%%%%
dataPath                = Par.DMT.RoiDir;
saveFileName            = fullfile(dataPath,Par.ExcelFileName);


%%%%%%%%%%%%%%%%%%%%%%
% ROI first
%%%%%%%%%%%%%%%%%%%%%%
dbROI                   = DataStr.Roi ;
if isempty(dbROI)
     DTP_ManageText([], sprintf('Multi Trial : No ROI data found for this selection.'),  'W' ,0);
     return
end

frameNum            = size(dbROI{1,4},1);
traceNum            = size(dbROI,1);

% stupid protect when no dF/F data
if frameNum < 1
    mtrxTraces          = [dbROI(:,4)];
    frameNum            = max(100,size(mtrxTraces,1));
end
meanTrace           = zeros(frameNum,1);
meanTraceCnt        = 0;
columnNames{1,1}    = 'Image Frames';
columnData          = zeros(frameNum,traceNum+1);
columnData(:,1)     = (1:frameNum)';

for p = 1:traceNum

    % traces
    if ~isempty(dbROI{p,4}) % protect from empty
        meanTrace       = meanTrace + dbROI{p,4};
        meanTraceCnt    = meanTraceCnt + 1;
       if enableBrightShow
            columnData(:,p+1) = dbROI{p,6};
       else
            columnData(:,p+1) = dbROI{p,4};
       end
    end
    columnNames{1,p+1}    = sprintf('T-%2d:%s',dbROI{p,1},dbROI{p,3});

end

% deal with average
meanTrace       = meanTrace/max(1,meanTraceCnt);

stat            = xlswrite(saveFileName,columnNames,       'TwoPhoton','A1');
stat            = xlswrite(saveFileName,columnData,        'TwoPhoton','A2');
stat            = xlswrite(saveFileName,{'Average'},       'TwoPhotonAverage','A1');
stat            = xlswrite(saveFileName,meanTrace,         'TwoPhotonAverage','A2');


%%%%%%%%%%%%%%%%%%%%%%
% Event Data
%%%%%%%%%%%%%%%%%%%%%%
dbEvent               = DataStr.Event ;
if isempty(dbEvent),
     DTP_ManageText([], sprintf('Multi Trial : No Event data found for this selection.'),  'W' ,0);
     %return
end
% specify at least one event to reset axis
eventNum            = size(dbEvent,1);
        
% this time should be already aligned to TwoPhoton
columnNames         = {};
columnNames{1,1}    = 'Image Frames';
columnData          = zeros(frameNum,eventNum+1);
columnData(:,1)     = (1:frameNum)';

for p = 1:eventNum

    % draw traces
    if ~isempty(dbEvent{p,4}) % protect from empty
        %tId         = dbEvent{p,1};
        %tt          = max(1,min(frameNum,round(dbEvent{p,4}))); % vector
        columnData(:,p+1) = dbEvent{p,4};
    end
    columnNames{1,p+1}    = sprintf('T-%2d:%s',dbEvent{p,1},dbEvent{p,3});
    

end
stat            = xlswrite(saveFileName,columnNames,       'Behavior','A1');
stat            = xlswrite(saveFileName,columnData,        'Behavior','A2');


DTP_ManageText([], sprintf('Excel File Extraction is Finished. Saved in : %s ',dataPath),   'I' ,0)

