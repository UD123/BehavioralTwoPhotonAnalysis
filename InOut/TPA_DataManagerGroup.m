classdef TPA_DataManagerGroup
    % TPA_DataManagerGroup - Collects Behavioral and TwoPhoton and user selection information
    % to form a group that can be analtzed and compared
    % Inputs:
    %       BDA_XXX.mat, TPA_YYY.mat - data base
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 19.14 18.11.14 UD     Adding group change name
    % 18.10 09.07.14 UD     Created
    %-----------------------------
    
    
    properties
        
        
        % containers of events and rois
        DbROI               = {};
        DbEvent             = {};
        AverDff             = [];   % average dF/F data
        
        % frame number in the data
        FrameNum            = 0;    % Two Photon and Behavior aligned

        % copy of the containers with file info
        DMB                 = [];   % behaivior
        DMT                 = [];   % two photon
               
        % group name pattern
        GroupName           = '';               % how this called
        GroupFilePattern    = 'GBT_*.mat';      % expected name for analysis
        GroupDir            = '';               % group location
        
        
    end % properties
    properties (SetAccess = private)
        %TimeConvertFact     = 1;           % time conversion >= 1 between behav - fast and twophoton - slow
        TimeEventAligned    = false;        % if the events has been time aligned
    end

    methods
        
        % ==========================================
        function obj = TPA_DataManagerGroup()
            % TPA_DataManagerGroup - constructor
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = Init(obj,Par)
            % Init - init Par structure related managers of the DB
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            
            if nargin < 1, error('Must have Par'); end;
            
            % manager copy
            obj.DMB                     = Par.DMB;
            obj.DMT                     = Par.DMT;
            
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SetRoiData(obj,dbROI) 
           % SetRoiData - extracts data about ROIs
            % Input:
            %    dbROI - created by MultiTrialDataManager
            % Output:
            %    obj   - updated 
        
            if isempty(dbROI),
                 DTP_ManageText([], sprintf('Group : No ROI data found for this selection.'),  'W' ,0);
                 return
            end

            frameNum            = size(dbROI{1,4},1);
            traceNum            = size(dbROI,1);
        
            % stupid protect when no dF/F data
            if frameNum < 1,
                mtrxTraces          = [dbROI(:,4)];
                frameNum            = max(100,size(mtrxTraces,1));
            end
       
            % save it for Events
             obj.FrameNum       = frameNum;
             
            % traces to be collected        
            meanTrace           = zeros(frameNum,1);
            meanTraceCnt        = 0;
            currTraces          = zeros(frameNum,traceNum);

            % get them
            for p = 1:traceNum,
                % traces
                if ~isempty(dbROI{p,4}), % protect from empty
                    meanTrace           = meanTrace + dbROI{p,4};
                    meanTraceCnt        = meanTraceCnt + 1;
                    currTraces(:,p)     = dbROI{p,4};                
                end
            end
            obj.AverDff         = meanTrace./max(1,meanTraceCnt);
            obj.DbROI           = dbROI;
            
        end
        % ---------------------------------------------
        
          
        % ==========================================
        function obj = SetEventData(obj,dbEvent) 
           % SetEventData - extracts data about Events
            % Input:
            %    dbEvent - created by MultiTrialDataManager
            % Output:
            %    obj   - updated 
        
            if isempty(dbEvent),
                 DTP_ManageText([], sprintf('Group : No Event data found for this selection.'),  'W' ,0);
                 return
            end
            % specify at least one event to reset axis
            eventNum            = size(dbEvent,1);

            % this time should be already aligned to TwoPhoton
            timeBehavior           = (1:obj.FrameNum)';
            %currEvents             = zeros(imFrameNum,eventNum);

            % get the data      
            for p = 1:eventNum,

                eventData   = timeBehavior*0;
                % draw traces
                if ~isempty(dbEvent{p,4}), % protect from empty
                    tt          = max(1,min(obj.FrameNum,round(dbEvent{p,4}))); % vector
                    eventData(tt(1):tt(2)) = 0.5;
                end
            end
            
            % save
            obj.DbEvent           = dbEvent;
            
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SetGroupInfo(obj,DataStr) 
           % SetGroupInfo - set information about the group from the current selection
            % Input:
            %     DataStr - contains dbROI and dbEvent selections
            % Output:
            %     obj - updated
            
            if nargin < 1, error('DataStr is required'); end;
            if ~isfield(DataStr,'Roi'), 
                errordlg('Must have Roi structure. Could be that no Events or ROIs are found'); 
                return
            end;
            if ~isfield(DataStr,'Event'), 
                errordlg('Must have Event structure. Could be that no Events or ROIs are found'); 
                return
            end;
        
            dbROI               = DataStr.Roi ;
            obj                 = SetRoiData(obj,dbROI);
            dbEvent             = DataStr.Event ;
            obj                 = SetEventData(obj,dbEvent);
            
            DTP_ManageText([], sprintf('Group : New group is formed.'),  'W' ,0);            
            
        end
         % ---------------------------------------------
   
        % ==========================================
        function [obj,fileName]  = CreateGroupName(obj) 
           % CreateGroupName - creates unique file name using sellected ROIs and Events. 
            % Input:
            %     obj - with dir structure initialization
            % Output:
            %     obj - updated GroupName
                       
            fileName            = '';
            
            % get experiment directory and extract experiment info
            dirPath             = obj.GroupDir;
            if ~exist(dirPath,'dir'),
                    showTxt     = sprintf('Group : Can not find directory %s.',dirPath);
                    DTP_ManageText([], showTxt, 'W' ,0)
                    return
            end
            % try to extract directory
            dirPathStart          = regexp(dirPath,'Analysis');  % put in analysis
            
            % check if replacement is done
            if isempty(dirPathStart),
                 DTP_ManageText([], 'Group : Group path does not have Analysis directory. Can not create file. Aborting', 'E' ,0)   ;   
                 return
            end;
            
             % deal with crasy names like . inside
             experName          = dirPath(dirPathStart+9:end); % skip Analysis
             experName          = obj.GroupName; %regexprep(experName,'[\W+]','_');
             
             % prepare file pattern
             patternName        = regexprep(obj.GroupFilePattern,'*','%s');

             
             % encode user selection into the name
             trialInd           = [obj.DbROI{:,1}];
             roiInd             = [obj.DbROI{:,2}];
             eventInd           = [obj.DbEvent{:,2}];
             
             % strings for min and max values
             userSelect         = sprintf('T%d_R%d_E%d',sum(trialInd),sum(roiInd),sum(eventInd));
             
             % finally
             uniqueName         = sprintf('%s_%s',experName,userSelect);
             fileName           = sprintf(patternName,uniqueName);
             
             % would you like to rename
             txtAsk             = sprintf('The new group name is %s. Would you like to rename it?',fileName);
             buttonName         = questdlg(txtAsk);  
             if strcmp(buttonName,'Yes'),  
                
                options.Resize          ='on';
                options.WindowStyle     ='modal';
                options.Interpreter     ='none';
                prompt                  = {'Please select new name for the group:',...
                                          };
                name                    ='Config Data Parameters';
                numlines                = 1;
                defaultanswer           = {fileName};
                answer                  = inputdlg(prompt,name,numlines,defaultanswer,options);
                if isempty(answer), return; end;
                % try to configure
                fileName                = answer{1};
             end;
            
            
        end
         % ---------------------------------------------
        % ==========================================
        function obj = SaveToFile(obj) 
           % SaveToFile - saves group info to a file. Check that name is unique.
            % Input:
            %     obj - with dir structure initialization
            % Output:
            %     obj - updated
            
            % check
            dirPath             = obj.DMT.RoiDir;
            if ~exist(dirPath,'dir'),
                    showTxt     = sprintf('Group : Can not find directory %s.',dirPath);
                    DTP_ManageText([], showTxt, 'W' ,0)
                    return
            end
            % save dir already
            obj.GroupDir        = dirPath;
            obj.GroupName       = obj.DMT.RoiFileNames{1}(5:end-8); % dump TPA_ .mat and 3 digits
            
            % get unique name
            [obj, fileName]     = CreateGroupName(obj);
            fileNameFull        = fullfile(dirPath,fileName);
            obj.GroupName       = fileName;
            
            
            % check exist
            if exist(fileNameFull,'file'),
                showTxt = sprintf('File %s already exist in the directory %s. Oevrwrite?.',fileName,dirPath);
                buttonName = questdlg(showTxt, 'Warning');
                if ~strcmp(buttonName,'Yes'), return; end;
            end;
            
            % save
            GroupObj            = obj;
            try
                save(fileNameFull,'GroupObj'); % load all info
                DTP_ManageText([], sprintf('Group : Created and saved to file %s.',fileNameFull),  'W' ,0);            
            catch ex
                errordlg(ex.getReport('basic'),'File Save Error','modal');
            end
            
        end
         % ---------------------------------------------
         
    
        % ==========================================
        function obj = TestDataExtract(obj)
            
            
         
        end
        % ---------------------------------------------
        
        
    end% methods
end% classdef
