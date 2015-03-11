function [Par,DataStr] = TPA_ImportDataFromExcel(Par,ExcelFileName)
% TPA_ImportDataFromExcel - brings in data from JAABA in excel format

% Inputs:

%   Par             - control structure 
%   ExcelFileName   - file name
%   
% Outputs:
%   Par      - control structure updated
%	DataStr    - ROI,Event structure

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 18.12 09.07.14 UD     Created
%-----------------------------

if nargin < 1, Par           = TPA_ParInit;         end;
if nargin < 2, ExcelFileName = 'D3_ForTPA.xlsx';    end;

% %%%%%%%%%%%%%%%%%%%%%%
% % What kind of export
% %%%%%%%%%%%%%%%%%%%%%%
% if ~strcmp(ExcelExportType,'MultiTrial'),
%     DTP_ManageText([], sprintf('Multi Trial : Only Multi Trial Export to excel is supported.'),  'W' ,0);
%     return
% end
% warning('off', 'MATLAB:xlswrite:AddSheet');

%%%%%%%%%%%%%%%%%%%%%%
% Setup output file
%%%%%%%%%%%%%%%%%%%%%%
% dataPath                = Par.DMT.RoiDir;
% saveFileName            = fullfile(dataPath,Par.ExcelFileName);

DataStr                 = [];


%%%%%%%%%%%%%%%%%%%%%%
% Import the data
%%%%%%%%%%%%%%%%%%%%%%
[ndata, txt, allData]  = xlsread(ExcelFileName);

% clean
allData(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),allData)) = {''};

%%%%%%%%%%%%%%%%%%%%%%
% Process to find valid columns
%%%%%%%%%%%%%%%%%%%%%%

% find columns with numbers
allData(cellfun(@(x) strcmp(x,'NaN'),allData)) = {0};
allDataBool         = cellfun(@(x) isnumeric(x),allData);
validNumColBool     = all(allDataBool(2:end,:)); % skip col names

% find column with names
allDataBool         = cellfun(@(x) strncmp(x,'Basler',6),allData);
validNameColBool    = all(allDataBool(2:end,:)); % skip col names

%%%%%%%%%%%%%%%%%%%%%%
% extract 
%%%%%%%%%%%%%%%%%%%%%%
validColInd         = find(validNumColBool);
if isempty(validColInd),
    DTP_ManageText([], sprintf('Multi Trial : Excel import is failed. Data in columns is not numeric.'),  'E' ,0);
    return
end


columnNames         = allData(1,validColInd);
trialNames          = allData(2:end,validNameColBool);


%%%%%%%%%%%%%%%%%%%%%%
% Ask User
%%%%%%%%%%%%%%%%%%%%%%
[sel,OK]            = listdlg('ListString',columnNames, 'PromptString','Select columns to use:','Name','JAABA Event Import','ListSize',[300 500]);
if ~OK, return; end;

eventData           = cell2mat(allData(2:end,validColInd(sel)));

%%%%%%%%%%%%%%%%%%%%%%
% Save
%%%%%%%%%%%%%%%%%%%%%%
DataStr.EventNames  = columnNames(sel);
DataStr.FileNames   = trialNames;
DataStr.EventTime   = eventData;


colNum              = length(sel);   
trialNum            = length(trialNames);
DTP_ManageText([], sprintf('Multi Trial : Excel Data is succesfully imported (%d Events, %d Trials).',colNum,trialNum),  'I' ,0);

return


