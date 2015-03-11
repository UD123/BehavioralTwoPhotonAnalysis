function Par = TPA_ParInit
% TPA_ParInit - Initializes different parameters used in the analysis
% Inputs:
%       none
% Outputs:
%        Par - different params for next use

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 19.21 20.01.15 UD     Support CSV file save for Mac
% 19.16 30.12.14 UD     Multi dimensional registration support. Adding new hide names button.
% 19.15 17.12.14 UD     STD image support
% 19.14 17.11.14 UD     Group dir save
% 19.04 12.08.14 UD     Adding JAABA file (new format from Adam)
% 18.09 06.07.14 UD     Janelia back. Adding ROI tag of depth
% 18.01 12.03.14 UD     Add Elect Phys support
% 17.00 04.03.14 UD     ROI names management.
% 16.07 20.02.14 UD     channel sync and definition gathering
% 16.06 19.02.14 UD     collecting definitions constants
% 16.05 18.02.14 UD     Adding structures to support muti window interactions
% 16.03 16.02.14 UD     Data Manager changes. Adding Sync structures
% 16.00 13.02.14 UD     Janelia Data integration
% 13.01 20.11.13 UD     adding Janelia support
% 11.09 20.08.13 UD     cursor data to save
% 10.11 08.07.13 UD     Big update
% 10.07 18.06.13 UD     Adopted for Maria
%-----------------------------

%%%%%%%%%%%%%%%%%%%%%%
% Main Constants and Defines
%%%%%%%%%%%%%%%%%%%%%%
% define list of GUI windows
Par.CHANNEL_TYPES          = struct('BEHAVIOR',1,'TWOPHOTON',2);    % chnnel in use        
Par.GUI_TYPES               = struct('MAIN_GUI',1,'TWO_PHOTON_XY',2,'TWO_PHOTON_YT',3,'BEHAVIOR_XY',4,'BEHAVIOR_YT',5,'ELECTROPHYS_YT',6);
Par.ListGuiHandles          = [];  % container of the GUI handles
Par.EVENT_TYPES             = struct('NONE',1,'UPDATE_IMAGE',2,'UPDATE_ROI',3,'UPDATE_POS',4);

% states of the GUI
Par.GUI_STATES              = struct('INIT',0,'ROI_INIT',1,'ROI_DRAW',2,'ROI_SELECTED',3,'ROI_EDIT',4,'ROI_MOVE',5,'ROI_MOVEALL',7,'HIDEALL',8,...
                                    'BROWSE_ABSPOS',11,'BROWSE_DIFFPOS',12,'PLAYING',21);

% which ROI averaging to perform
%Par.ROIAVER_TYPE            = struct('AVER',1,'MAX',2,'LINE',3);
Par.ROI_TYPES               = struct('RECT',1,'ELLIPSE',2,'FREEHAND',3);
Par.IMAGE_TYPES             = struct('RAW',1,'MEAN',3,'MAX',2,'GRADT',4,'GRADXY',5,'STD',6,'DFF',7);  % which type of image representation to support
Par.VIEW_TYPES              = struct('XY',1,'YT',2);
Par.BUTTON_TYPES            = struct('NONE',1,'RECT',2,'ELLIPSE',3,'FREEHAND',4,'BROWSE',5,'PLAYER',6,'MOVEALL',7,'HIDEALL',8);
Par.ROI_AVERAGE_TYPES       = struct('MEAN',1,'LOCAL_MAXIMA',2,'LINE_ORTHOG',3);
Par.ROI_DELTAFOVERF_TYPES   = struct('MEAN',1,'MIN10',2,'STD',3,'MIN10CONT',4);
Par.ROI_CELLPART_TYPES      = struct('SOMA_5',1,'SOMA_23',2,'APICAL_PROXIMAL',3,'APICAL_DISTAL',4,'APICAL_TUFT',5,'ROI',6);


%%%%%%%%%%%%%%%%%%%%%%
% Flow / Show Control
%%%%%%%%%%%%%%%%%%%%%%
%Par.UserDataFileName        = 'TPA_UserData.mat';      % file name to save user input for each experiment
Par.DataDir                 = '..\..\Data\';            % setup data management directories
Par.SetupDir                = '.\Setup\';               % setup session management directories
Par.SetupFileName           = 'TPA_Session.mat';        % file name to save the current config
Par.ExpDataDirFileName      = 'TPC_ExperimentDataDir.xlsx';     % file name to manage directories of the experiment
Par.ExpFileName             = 'TPC_Experiment.mat';     % file name to save the current experiment
Par.CsvDataDirFileName      = 'TPC_ExperimentDataDir.csv';     % file name to manage directories of the experiment

% 
% Par.doDataLoad              = 1;                    % set 0 to skip data load
% Par.doDataShow              = 0;                    % set 0 to skip data show
% Par.doExportToIgor          = 0;                    % export data to Igor

Par.FigNum                  = 100;                  % 0-no show 1,2,..-shows the image,

% show
Par.Debug.AverFluorFigNum   = 10;                   % show figure for average fluorescence
Par.Debug.DeltaFOverFigNum  = 20;                   % show figure for average fluorescence


%%%%%%%%%%%%%%%%%%%%%%
% GUI Managements
%%%%%%%%%%%%%%%%%%%%%%
% define list of GUI windows

% GUI related - must be removed
Par.PlayerMovieTime        = 10;           % total time for movie


%%%%%%%%%%%%%%%%%%%%%%
% Input/output file managing objects
%%%%%%%%%%%%%%%%%%%%%%
Par.DMT                     = TPA_DataManagerTwoPhoton();
Par.DMB                     = TPA_DataManagerBehavior(); Par.DMB.DecimationFactor = [2 2 1 1];
Par.DMJ                     = TPA_DataManagerJaaba();
Par.DMC                     = TPA_DataManagerCalcium();
Par.DME                     = TPA_DataManagerElectroPhys();

% management of ROIs and Events
Par.roiCount                = 0;
Par.eventCount              = 0;

%%%%%%%%%%%%%%%%%%%%%%
% Behavior Event Params
%%%%%%%%%%%%%%%%%%%%%%
% init names
if exist('TPA_EventNames.xml','file')
    eventNameStr              = xml_read('TPA_EventNames.xml');
else
    eventNameStr              = struct('None',1,'Grab',2,'Chew',3,'GrabMiss',4);
end
Par.Event.NameOptions         = fieldnames(eventNameStr);
Par.Event.JaabaExcelFileName  = '';                 % export file from JAABA
Par.Event.JaabaExcelFileDir   = '';                 % export file from JAABA directory

%%%%%%%%%%%%%%%%%%%%%%
% Image Correction related
%%%%%%%%%%%%%%%%%%%%%%
Par.Image.MotionCorrectType         = 'none';       % designates motion correction type: 0-none, 1-'T',2-'Z'
%Par.Image.MultiStackIgnoreLastFrame = 1;            % 1 - ignores last frame in the multistack data


%%%%%%%%%%%%%%%%%%%%%%
% ROI Definition Params
%%%%%%%%%%%%%%%%%%%%%%
Par.Roi.AverageType              = Par.ROI_AVERAGE_TYPES.MEAN;     % how to average ROI : PointAver, LineMax,LineOrthog,  (see TPA_AverageMultiROI)
Par.Roi.ImposeAverageType        = true;        % override individual ROI types and use only average
Par.Roi.OrthRoiWidthPix          = 2;           % OrthRoiWidthPix*2+1 will be the orthogonal line width
Par.Roi.AverageRadius            = 1;           % how many pixels to average for big ROI
Par.Roi.MaxMovementRadius        = 3;           % max distance from ROI line that searched for maximu fluorescence
                                            % accounts for dendrites max distance movements
                                            
Par.Roi.MaxNum                  = 256;          % max number of ROIs allowed                                            
Par.Roi.AverageOptions          = fieldnames(Par.ROI_AVERAGE_TYPES);
Par.Roi.TmpData                 = [];         % is used as temp data holder during average calculations
Par.DataRange                   = [0 1000];         % data range for display images
Par.Roi.CellPartOptions         = fieldnames(Par.ROI_CELLPART_TYPES);


%%%%%%%%%%%%%%%%%%%%%%
% ROI Processing params
%%%%%%%%%%%%%%%%%%%%%%
Par.Roi.ProcessType             = Par.ROI_DELTAFOVERF_TYPES.MEAN;     % how to proceess ROI : dF/F, Konnerth,... (see TOA_ProcessingROI.m) 
Par.Roi.TimeFilterType          = 0;        % Time data smoothing, 0 -none
Par.Roi.BaseLineType            = 0;		% Parameter controls Baseline computation (Mean Substraction)
Par.Roi.ImageNormType           = 0;		% Parameter controls  : Image normalization (dF/F)
Par.Roi.PreEmphType             = 11;       % Parameter controls emphasise of peak values in the data and NeuroPhil substraction 0-none, 3-factor 2
Par.dFFRange                    = [-0.3 4]; % range of dF/F data for display
Par.ArtifactCorrected           = false;    % designates if artifact correction is already done

% roi auto detect manager
%Par.DMROIAD                     = TPA_ManageRoiAutodetect();

% ROI color management
MaxColorNum                     = 64;
TraceColorMap                   = jet(MaxColorNum); 
Par.Roi.TraceColorMap           = TraceColorMap(randperm(MaxColorNum),:);
Par.Roi.MaxColorNum             = MaxColorNum;

%%%%%%%%%%%%%%%%%%%%%%
% Cursor params
%%%%%%%%%%%%%%%%%%%%%%
%Par.strCursor               = [];       % support cursor measurements ; save a nd load

%%%%%%%%%%%%%%%%%%%%%%
% Group params
%%%%%%%%%%%%%%%%%%%%%%
%Par.Group.Dir               = pwd;     % save last directory for group

%%%%%%%%%%%%%%%%%%%%%%
% Auto Peak Detection
%%%%%%%%%%%%%%%%%%%%%%
Par.ResponseDetectThr       = 2;       % number of STD that response is above baseline


%%%%%%%%%%%%%%%%%%%%%%
% Export data
%%%%%%%%%%%%%%%%%%%%%%
Par.IgorExportType           = 'Behavior'; % what kind of export data : see DTP_ExportDataToIgor.m 
Par.IgorExportOptions        = {'Behavior','dFF4ROI','meas4ROI'};
Par.ExcelExportType          = 'ElectroPhisiology'; % what kind of export data : see DTP_ExportDataToIgor.m 
Par.ExcelExportOptions       = {'ElectroPhisiology','Mean Fluor per ROI','dFF per ROI','Mean Fluor Total','MultiTrial'};
Par.ExcelFileName            = 'TPD_MultiTrialExplorer.xls'; % what kind of export data : see DTP_ExportDataToIgor.m 


return
