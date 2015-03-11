function Par = DTP_ExportDataToIgor(Par,strRecord,strROI)
% DTP_ExportDataToIgor - saves diffferent paarmeters and results in Igor file format

% Inputs:

%   Par       - control structure 
%   strRecord - structure with Physiology data recordings
%	strROI    - ROI structure
%   
% Outputs:
%   Par      - control structure updated

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 12.01 14.09.13 UD     Support Z stack
% 11.09 20.08.13 UD     export measurements of cursors to data directory
% 11.04 23.07.13 UD     export data original exp directory
% 10.11 08.07.13 UD     New format.
%-----------------------------

%%%%%%%%%%%%%%%%%%%%%%
% What kind of export
%%%%%%%%%%%%%%%%%%%%%%
           
% ask for sync
[s,ok]              = listdlg('PromptString','Select Export Type:','ListString',Par.IgorExportOptions,'SelectionMode','single');
if ~ok, return; end;
Par.IgorExportType        = Par.IgorExportOptions{s};
            


%%%%%%%%%%%%%%%%%%%%%%
% Setup
%%%%%%%%%%%%%%%%%%%%%%
% decipher the file name
% dataPath                = Par.dataPath;
% ai                      = strfind(dataPath,'TSeries');
% saveFileName            = fullfile('.\Temp\',dataPath(ai:end-1));

% dataPath                = Par.dataPath;
% ai                      = strfind(dataPath,'TSeries');
saveFileName            = fullfile(Par.dataPath,'TPA_');


nZ                      = Par.imSize(3);
nT                      = Par.imSize(4);
zStackInd               = Par.ZStackInd;
numROI                  = length(strROI);
% 
% if nZ > 1,
% % IMPORTANT
% % two frames are blank frames - time requires to piezo get back to initial position
% skipNum     = nZ + 2;
% timeImage  = tt(strRecord.frameStart(ZStackInd - 1 + 2 + (1:skipNum:minImNum*skipNum)));
% else
% timeImage  = tt(strRecord.frameStart);
% end;

timeImage           = 1:nT;


if strcmp(Par.IgorExportType,Par.IgorExportOptions{1}),

%     Data            = [timeRecord strRecord.recordValue(:,chanIndToIgor)];
%     ColumnNames     = cat(1,{'TimePhysio'},showNames{chanIndToIgor}); %{'Ops','Bop','Taf'};
%     DTP_SaveDataForIgor([saveFileName,'ElectroPhysiology'],Data,ColumnNames);

    warndlg('Non supported yet','Warning','modal')
    
end;


% fluorescence
for k = 1:numROI,
    
    ColumnNames          = {};
    ColumnNames{1}       = 'TimeImage';
    for m = 1:length(strROI{k}.lineInd),
        ColumnNames{m+1}       = sprintf('Pixel_%d',m);
    end;
    
    if strcmp(Par.IgorExportType,Par.IgorExportOptions{2}),
    
    %ColumnNames         = cat(1,{'TimeImage'},num2str((1:length(strROI{k}.lineInd))'));
    dataROI         = strROI{k}.procROI';  % time is in rows
    Data            = [timeImage,dataROI((1:minImNum),:)];
    zStackInd       = strROI{k}.nZ;
    roiName         = sprintf('Z%d_ROI%d',zStackInd,k);
    
    DTP_SaveDataForIgor([saveFileName,'dFF_',roiName],Data,ColumnNames);
    end;
    
    
    if strcmp(Par.IgorExportType,Par.IgorExportOptions{3}),

    % check if exists
    if ~isfield(strROI{k},'measROI'), continue; end;
    if isempty(strROI{k}.measROI), continue; end;
    

    % the last line in measROI Physiology
    ColumnNames{1}              = 'ElectroPhysiology';
    
    for c = 1:size(strROI{k}.measROI,3),

        measROI         = strROI{k}.measROI(:,:,c); % nLines+1 x 5 x cursorNum (mean, max, area, mean-bl, max-bl in columns) array
        Data            = measROI';
        measName        = sprintf('Z%d_ROI%d_Curs%d',zStackInd,k,c);
        
        DTP_SaveDataForIgor([saveFileName,'Meas_',measName],Data,ColumnNames);
    
    end;
    end;
    
end;

