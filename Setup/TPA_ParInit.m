function Par = TPA_ParInit(currVersion)
% TPA_ParInit - Initializes different parameters used in the analysis
% Inputs:
%       none
% Outputs:
%        Par - different params for next use

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 28.14 01.04.18 UD     Range for Behavioral data
% 28.06 25.01.18 UD     many trial baseline for dF/F.
% 28.05 20.01.18 UD     Inhibitory cell dF/F.
% 28.04 15.01.18 UD     Adding F Range.
% 28.01 28.12.17 UD     Two channel system support
% 26.00 01.06.17 UD     new system from Janelia
% 23.19 16.08.16 UD     File seprator fix
% 23.16 28.06.16 UD     Fast matrix inverse registration
% 23.14 21.05.16 UD     Adding effective ROI control 
% 23.11 12.04.16 UD     Changing MinFluorLevel to 10
% 21.19 08.12.15 UD     Changing to Roi.dFFrange. Adding MinFluorLevel
% 21.06 10.10.15 UD     Adding Event Detector
% 21.04 25.08.15 UD     Artifact removal support in ROI data
% 20.13 18.08.15 UD     ROI names from XML file
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
if nargin < 1, currVersion = '01.00'; end;

%%%%%%%%%%%%%%%%%%%%%%
% Main Constants and Defines
%%%%%%%%%%%%%%%%%%%%%%
% define list of GUI windows
Par.EXPERIMENT_TYPES        = struct('TWOPHOTON_JANELIA',1,'TWOPHOTON_PRARIE',2,'TWOCHANNEL_PRARIE',3,'TWOPHOTON_ELECTROPHYS',4,'TWOPHOTON_SHEET',5);    % experiment type       
Par.CHANNEL_TYPES           = struct('BEHAVIOR',1,'TWOPHOTON',2);    % chnnel in use        
Par.GUI_TYPES               = struct('MAIN_GUI',1,'TWO_PHOTON_XY',2,'TWO_PHOTON_YT',3,'BEHAVIOR_XY',4,'BEHAVIOR_YT',5,'ELECTROPHYS_YT',6);
Par.ListGuiHandles          = [];  % container of the GUI handles
Par.EVENT_TYPES             = struct('NONE',1,'UPDATE_IMAGE',2,'UPDATE_ROI',3,'UPDATE_POS',4); % Sync events

% states of the GUI
Par.GUI_STATES              = struct('INIT',0,'ROI_INIT',1,'ROI_DRAW',2,'ROI_SELECTED',3,'ROI_EDIT',4,'ROI_MOVE',5,'ROI_MOVEALL',7,'ROI_ROTSCALEALL',8,'HIDEALL',9,'ANCHORS',10,...
                                    'BROWSE_ABSPOS',11,'BROWSE_DIFFPOS',12,'PLAYING',21);

% which ROI averaging to perform
Par.IMAGE_TYPES             = struct('RAW',1,'MEAN',3,'MAX',2,'GRADT',4,'GRADXY',5,'STD',6,'DFF',7);  % which type of image representation to support
Par.VIEW_TYPES              = struct('XY',1,'YT',2,'XYYT',3);
Par.BUTTON_TYPES            = struct('NONE',1,'RECT',2,'ELLIPSE',3,'FREEHAND',4,'BROWSE',5,'PLAYER',6,'MOVEALL',7,'ROI_ROTSCALEALL',8,'HIDEALL',9,'ANCHORS',10,'HIDENAMES',11);
Par.ROI_TYPES               = struct('RECT',1,'ELLIPSE',2,'FREEHAND',3);
Par.ROI_AVERAGE_TYPES       = struct('MEAN',1,'LOCAL_MAXIMA',2,'LINE_ORTHOG',3);
Par.ROI_ARTIFACT_TYPES      = struct('NONE',1,'BLEACHING',2,'SLOW_TIME_WAVE',3,'FAST_TIME_WAVE',4,'POLYFIT2',5);
Par.ROI_DELTAFOVERF_TYPES   = struct('MEAN',1,'MIN10',2,'STD',3,'MIN10CONT',4,'MIN10BIAS',5,'MAX10',6,'MANY_TRIAL',7);
Par.ROI_CELLPART_TYPES      = struct('ROI',1,'SOMA_5',2,'SOMA_23',3,'APICAL_PROXIMAL',4,'APICAL_DISTAL',5,'APICAL_TUFT',6);


%%%%%%%%%%%%%%%%%%%%%%
% Flow / Show Control
%%%%%%%%%%%%%%%%%%%%%%
Par.ExpType                 = Par.EXPERIMENT_TYPES.TWOPHOTON_JANELIA;
Par.ExpDataDirFileName      = 'TPC_ExperimentDataDir.xlsx';     % file name to manage directories of the experiment
Par.ExpFileName             = 'TPC_Experiment.mat';              % file name to save the current experiment
Par.SetupDir                = ['.',filesep,'Setup'];               % setup session management directories
Par.SetupFileName           = 'TPA_Session.mat';        % file name to save the current config
Par.CsvDataDirFileName      = 'TPC_ExperimentDataDir.csv';     % file name to manage directories of the experiment

% 
% Par.doDataLoad              = 1;                    % set 0 to skip data load
% Par.doDataShow              = 0;                    % set 0 to skip data show
% Par.doExportToIgor          = 0;                    % export data to Igor

Par.FigNum                  = 100;                  % 0-no show 1,2,..-shows the image,
Par.Version                 = currVersion;                 % current sw version

% show
Par.Debug.AverFluorFigNum   = 10;                   % show figure for average fluorescence
Par.Debug.ArtifactFigNum    = 20;                   % show figure for artifact fluorescence
Par.Debug.DeltaFOverFigNum  = 30;                   % show figure for df/f fluorescence


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
%Par.DME                     = TPA_DataManagerElectroPhys();
Par.TPED                    = TPA_TwoPhotonEventDetect();
Par.DMF                     = TPA_DataManagerFileDir(Par.CsvDataDirFileName);

% management of ROIs and Events
%Par.roiCount                = 0;
%Par.eventCount              = 0;

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
Par.Event.DataRange           = [0 1];              % data range to display event data


%%%%%%%%%%%%%%%%%%%%%%
% Image Correction related
%%%%%%%%%%%%%%%%%%%%%%
Par.Image.MotionCorrectType         = 'none';       % designates motion correction type: 0-none, 1-'T',2-'Z'
Par.Image.MotionCorrectAlgType      = 4;       % designates motion correction algo type: 0-none, 4 - template, 3 - mtrx inverse
%Par.Image.MultiStackIgnoreLastFrame = 1;            % 1 - ignores last frame in the multistack data


%%%%%%%%%%%%%%%%%%%%%%
% ROI Definition Params
%%%%%%%%%%%%%%%%%%%%%%
Par.Roi.AverageType              = Par.ROI_AVERAGE_TYPES.MEAN;     % how to average ROI : PointAver, LineMax,LineOrthog,  (see TPA_AverageMultiROI)
Par.Roi.ImposeAverageType        = true;        % override individual ROI types and use only average
Par.Roi.OrthRoiWidthPix          = 2;           % OrthRoiWidthPix*2+1 will be the orthogonal line width
Par.Roi.AverageRadius            = 1;           % how many pixels to average for big ROI
Par.Roi.UseEffectiveROI          = false;        % override user ROI contour by effective one
Par.Roi.MaxMovementRadius        = 3;           % max distance from ROI line that searched for maximu fluorescence
                                                % accounts for dendrites max distance movements
                                            
Par.Roi.MaxNum                  = 256;          % max number of ROIs allowed                                            
Par.Roi.AverageOptions          = fieldnames(Par.ROI_AVERAGE_TYPES);
Par.Roi.TmpData                 = [];         % is used as temp data holder during average calculations
%Par.DataRange                   = [0 1000];         % data range for display images
Par.Roi.DataRange               = [0 1000];     % data range to display fluorescence images

% init names
if exist('TPA_RoiNames.xml','file')
    roiNameStr                  = xml_read('TPA_RoiNames.xml');
else
    roiNameStr                  = Par.ROI_CELLPART_TYPES;
end
Par.Roi.CellPartOptions         = fieldnames(roiNameStr);

%%%%%%%%%%%%%%%%%%%%%%
% ROI Artifact remove params
%%%%%%%%%%%%%%%%%%%%%%
Par.Roi.ArtifactCorrected       = false;    % designates if artifact correction is already done
Par.Roi.ArtifactType            = Par.ROI_ARTIFACT_TYPES.NONE;


%%%%%%%%%%%%%%%%%%%%%%
% ROI Processing params
%%%%%%%%%%%%%%%%%%%%%%
Par.Roi.MinFluorescentLevel     = 20;       % system dependent - minimal flurescence on image data
Par.Roi.ProcessType             = Par.ROI_DELTAFOVERF_TYPES.MEAN;     % how to proceess ROI : dF/F, Konnerth,... (see TOA_ProcessingROI.m) 
Par.Roi.TimeFilterType          = 0;        % Time data smoothing, 0 -none
Par.Roi.BaseLineType            = 0;		% Parameter controls Baseline computation (Mean Substraction)
Par.Roi.ImageNormType           = 0;		% Parameter controls  : Image normalization (dF/F)
Par.Roi.PreEmphType             = 11;       % Parameter controls emphasise of peak values in the data and NeuroPhil substraction 0-none, 3-factor 2
Par.Roi.dFFRange                = [-0.3 4]; % range of dF/F data for display

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
