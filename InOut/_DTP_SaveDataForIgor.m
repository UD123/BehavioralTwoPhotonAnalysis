
function DTP_SaveDataForIgor(FileName,Data,ColumnNames)
% DTP_AnalysisROI - performs analysis on Marya's data
% Inputs:
%	FileName - string that specifies the file to save must have .dat at the end
%   Data     - N x K matrix
% Outputs:
%   *.dat file
%
% In Igor : Data-> Load Delimited Text... Select this file name
%
%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 11.01 08.07.13 UD     column names changed in IF.
% 10.06 14.05.13 UD     small fix.
% 10.03 10.03.13 UD     Created.
%-----------------------------

if nargin < 1, FileName = 'Test'; end;
if nargin < 2, Data     = rand(100,5); end;
if nargin < 3, ColumnNames= num2str(num2cell(1:size(Data,2))); end;

% check
[rowNum,columnNum]   = size(Data);
if length(ColumnNames) ~= columnNum,
    error('Column names do not match the number of columns in the data ')
end;

SaveDirFile = FileName;

% print with headers
igorFileName  = [SaveDirFile,'_Igor.dat'];
fid   = fopen(igorFileName,'w'); 
if fid < 0, error('Can not open file load for Igor'); end;

for m = 1:columnNum,
    fprintf(fid, '%s \t',ColumnNames{m});
end;
fprintf(fid,'\n');
    
for r = 1: rowNum,
for m = 1:columnNum,
    fprintf(fid, '%9.6f \t',Data(r,m));
end;
fprintf(fid,'\n');
end;

    
%fprintf(fid, 'OpticTime \t OpticRawData \t OpticFiltData\n');
%fprintf(fid, '%9.6f     \t %9.6f        \t %9.6f\n', [StimTime opticValues y50]');
fclose(fid);
txt = sprintf('Data extracted to Igor : %s',SaveDirFile);

DTP_ManageText([], txt,  'I' ,0)


return