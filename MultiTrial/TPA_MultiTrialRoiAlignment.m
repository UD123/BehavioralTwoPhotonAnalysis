function [Par,dbROI] = TPA_MultiTrialRoiAlignment(Par,FigNum)
% TPA_MultiTrialRoiAlignment - loads ROI data from the experiment.
% Preprocess it to build the full list of all cells detected in all trials.
% Find unique cells/ROIs and project them all over the database.
% If ROI in different trials has been moved/renamed - this info will be lost.
% Inputs:
%   Par         - control structure 
%   
% Outputs:
%   Par         - control structure updated
%  dbROI        - data bases

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 19.23 17.02.15 UD     Assign all files without bug fix.
% 17.08 05.03.14 UD     Extend to all video files. Fixing bug in old index file generation - inpolygon must be run again
% 17.02 10.03.14 UD     Created
%-----------------------------

if nargin < 1,  error('Need Par structure');        end;
if nargin < 2,  FigNum      = 11;                  end;


% attach
%global SData SGui

% containers of events and rois
dbROI               = {};
dbRoiRowCount       = 0;


%%%%%%%%%%%%%%%%%%%%%%
% Setup & Get important parameters
%%%%%%%%%%%%%%%%%%%%%%
%tpSize          = Par.DMT.VideoSize;
%bhSize          = Par.DMB.VideoSideSize;
%timeConvertFact      = Par.DMB.Resolution(4)/Par.DMT.Resolution(4);
                
                
%%%%%%%%%%%%%%%%%%%%%%
% Run over all files/trials and load the Analysis data
%%%%%%%%%%%%%%%%%%%%%%
validTrialNum           = length(Par.DMT.RoiFileNames);
if validTrialNum < 1,
    DTP_ManageText([], sprintf('Multi Trial : No TwoPhoton Analysis data in directory %s. Please check the folder or run Data Check',Par.DMT.RoiDir),  'E' ,0);
    return
end

%%%%%%%%%%%%%%%%%%%%%%
% Select which trial
%%%%%%%%%%%%%%%%%%%%%%

[s,ok] = listdlg('PromptString','Select Trial to Assign :','ListString',Par.DMT.RoiFileNames,'SelectionMode','multiple');
if ~ok, return; end;

selecteInd          = s;
selectedTrialNum    = length(s);     

% for ind fix
% nR          = Par.DMT.VideoDataSize(1);
% nC          = Par.DMT.VideoDataSize(2);
% [X,Y]       = meshgrid(1:nR,1:nC);  % 

for sInd = 1:selectedTrialNum,
    
        % show
        trialInd                    = selecteInd(sInd);
    
    
        [Par.DMT, strROI]           = Par.DMT.LoadAnalysisData(trialInd,'strROI');
        % this code helps with sequential processing of the ROIs: use old one in the new image
        numROI                      = length(strROI);
        if numROI < 1,
            DTP_ManageText([], sprintf('Multi Trial : There are no ROIs in trial %d. Trying to continue',trialInd),  'E' ,0);
        end
        
        
        
        % read the info
        for rInd = 1:numROI,
            
%             % bug FIX
%             xy                  = strROI{rInd}.xyInd  ; 
%             maskIN              = inpolygon(X,Y,xy(:,1),xy(:,2));
%             strROI{rInd}.Ind    = find(maskIN);
            
            
           dbRoiRowCount = dbRoiRowCount + 1;
           dbROI{dbRoiRowCount,1} = trialInd;
           dbROI{dbRoiRowCount,2} = rInd;                   % roi num
           dbROI{dbRoiRowCount,3} = strROI{rInd}.Name;      % name 
           dbROI{dbRoiRowCount,4} = strROI{rInd};           % save entire structure
        end

end
DTP_ManageText([], sprintf('Multi Trial : Database Ready.'),  'I' ,0);



%%%%%%%%%%%%%%%%%%%%%%
% Find Unique names
%%%%%%%%%%%%%%%%%%%%%%
% find unique patterns and their first occurance
[namesROI,ia]       = unique(strvcat(dbROI{:,3}),'rows','first');

% recover back the entire struture of ROIs
strROI              = {};
for m = 1:length(ia),
    strROI{m}       = dbROI{ia(m),4};
end
numROI              = length(strROI);

%%%%%%%%%%%%%%%%%%%%%%
% Write data back
%%%%%%%%%%%%%%%%%%%%%%

for trialInd = 1:validTrialNum,
    
        Par.DMT     = Par.DMT.SaveAnalysisData(trialInd,'strROI',strROI);

end

DTP_ManageText([], sprintf('Multi Trial : %d ROIs  are aligned to %d trial files',numROI,validTrialNum),  'I' ,0);

return

