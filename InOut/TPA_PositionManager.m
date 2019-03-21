classdef TPA_PositionManager
    % TPA_PositionManager - Detects position info and update this info according to view.
    % Resonsible for time zone and data rescaling
    % Inputs:
    %       different
    % Outputs:
    %        different
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 24.07 26.10.16 UD     Fixing SliceNum.
    % 24.05 16.08.16 UD     Resolution is not an integer.
    % 18.01 13.04.14 UD     Support Electro Phys
    % 16.10 22.02.14 UD     Sync of time
    % 16.07 20.02.14 UD     create and integration
    %-----------------------------
    
    
    properties
        
        % GUI info
        
        PrevPos             = [0 0 0 0]; % previous 4D pos
        
        % bookeeping
        TxCount             = 0;  % tx message counter
        RxCount             = 0;  % rx message counter
% 
%         % output
%         %srcId               = 0;  % sending object : user info, roi
%         %msgId               = 0;  % message type: update/delete ...
%         data                = [];
        
        % Time rescaling 
        Behavior_Resolution  = [1 1 1 1];  % init from outside according to the 
        Behavior_Offset      = [0 0 0 0];
        TwoPhoton_Resolution = [1 1 1 1];
        TwoPhoton_Offset     = [0 0 0 0];
        
        % TYPES (shouild be defined globaly)
        % message
        EVENT_TYPES         = []; %struct('NONE',1,'UPDATE_IMAGE',2,'UPDATE_ROI',3);
        % sources
        GUI_TYPES           = []; %struct('MAIN_GUI',1,'TWO_PHOTON_XY',2,'TWO_PHOTON_YT',3,'BEHAVIOR_XY',4,'BEHAVIOR_YT',5);
        
        
    end % properties
    properties (SetAccess = private)
        MyId                = 0;           % my address
        MyType              = 0;            % GUI Type
        DstId               = 255;         % broadcast - not in use
        TimeConvertFact     = 1;           % time conversion >= 1 between behav - fast and twophoton - slow
    end

    methods
        
        % ==========================================
        function obj = TPA_PositionManager(Par, MyGuiType, MyGuiId)
            % TPA_CommManager - constructor
            % Input:
            %    Par        - structure with defines
            %     MyGuiType - whos creates me
            % Output:
            %     default values
            if nargin < 2, error('Must have these'); end;
            
            % not testing it
            obj.EVENT_TYPES = Par.EVENT_TYPES;
            obj.GUI_TYPES   = Par.GUI_TYPES;
            
            % check Id
            switch MyGuiType,
                case obj.GUI_TYPES.TWO_PHOTON_XY,
                case obj.GUI_TYPES.TWO_PHOTON_YT,
                case obj.GUI_TYPES.BEHAVIOR_XY,
                case obj.GUI_TYPES.BEHAVIOR_YT,
                case obj.GUI_TYPES.ELECTROPHYS_YT,
                otherwise error('msgId must be GUI_TYPES')
            end
            
            obj.MyType                   = MyGuiType;
            obj.MyId                     = MyGuiId;
            
            % resolution updates
            obj.Behavior_Resolution     = Par.DMB.Resolution;
            obj.Behavior_Offset         = Par.DMB.Offset;
            obj.TwoPhoton_Resolution    = Par.DMT.Resolution;
            obj.TwoPhoton_Offset        = Par.DMT.Offset;
            
            % check
            if obj.Behavior_Resolution(4) < 1,
                obj.Behavior_Resolution(4) = 1;
            end
            if obj.TwoPhoton_Resolution(4) < 1,
                obj.TwoPhoton_Resolution(4) = 1;
            end
            obj.TimeConvertFact      = (obj.Behavior_Resolution(4)/obj.TwoPhoton_Resolution(4)*Par.DMT.SliceNum);   

            
            
        end
        % ---------------------------------------------
     
        % ==========================================
        function tcFact = GetTimeConvertFact(obj)
            % GetTimeConvertFact - conversion factor
            % Input:
            %   dataPos     - 4D position - must be integer  
            % Output:
            %    msgObj     - meassge structure
            
            tcFact = obj.TimeConvertFact;
        end
        
        
        
        % ==========================================
        function [obj,msgObj] = Encode(obj, msgId, dataObj)
            % Encode - puts header on the dataObj to send
            % and defines message type
            % Input:
            %     msgId, dataObj - header properties
            % Output:
            %     msgObj - meassge structure
            
            if nargin < 2, msgId   = 2; end;
            if nargin < 3, dataObj = cputime; end;
            
            msgObj.skip      = true;
            
            % check
            switch msgId,
                case obj.EVENT_TYPES.UPDATE_POS,
                    [obj,msgObj] = SendPosition(obj,dataObj);
                case obj.EVENT_TYPES.UPDATE_IMAGE,
                case obj.EVENT_TYPES.UPDATE_ROI,
                otherwise error('msgId must be EVENT_TYPES')
            end
%             switch srcId,
%                 case obj.GUI_TYPES.TWO_PHOTON_XY,
%                 case obj.GUI_TYPES.TWO_PHOTON_YT,
%                 case obj.GUI_TYPES.BEHAVIOR_XY,
%                 case obj.GUI_TYPES.BEHAVIOR_YT,
%                 otherwise error('msgId must be GUI_TYPES')
%             end
            
            
            
               
            %DTP_ManageText([], sprintf('CommTx : message %d from %d is encoded',msgObj.msgId,msgObj.srcId), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,msgObj] = SendPosition(obj,dataPos)
            % SendPosition - sends 4D user position vector
            % Input:
            %   dataPos     - 4D position - must be integer  
            % Output:
            %    msgObj     - meassge structure
            
            if nargin < 2, dataPos = 112; end;
            
            % check
            if numel(dataPos) ~= 4, error('Bad number of elements must be 4'); end;
            if ~all(dataPos == round(dataPos)), error('Position must be integer'); end;
            
            
            % output
            msgObj.dstId            = obj.DstId;    % whom
            msgObj.srcId            = obj.MyId;     % from
            msgObj.srcType          = obj.MyType;     % from
            msgObj.msgId            = obj.EVENT_TYPES.UPDATE_POS;        % what
            msgObj.msgCount         = obj.TxCount;
            msgObj.data             = dataPos;
            
            % bookeeping
            obj.TxCount             = obj.TxCount + 1;
            
            % output
            %[obj,msgObj]            = Encode(obj, obj.EVENT_TYPES.UPDATE_POS, dataPos) ;
            
            %DTP_ManageText([], sprintf('CommTx : Sending position info'), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,msgObj] = Decode(obj,msgObj)
            % Decode - decodes header and extracts the data
            % Calls time rescaling options
            % Input:
            %     msgObj - meassge structure
            % Output:
            %     msgObj - structure srcId, msgId, dataObj - 
            
            if nargin < 2, error('No messge'); end;
            
            % bookeeping
            obj.RxCount             = obj.RxCount + 1;
            %DTP_ManageText([], sprintf('CommRx : message %d from %d is decoded',msgObj.msgId,msgObj.srcId), 'I' ,0)   ;             
            
            
            % decode and rescale when coming from different "time zone"
            switch msgObj.msgId,
                case obj.EVENT_TYPES.UPDATE_IMAGE,
                    % change in Z usually
                    
                case obj.EVENT_TYPES.UPDATE_ROI,
                    % Last Roi info
                    %[obj,msgObj] = RecvRoi(obj, msgObj)   ;
                    
                case obj.EVENT_TYPES.UPDATE_POS,
                    % Last Position info
                    % change in Z usually
                    %[obj,msgObj] = RecvPosition(obj, msgObj)   ;
                    [obj,msgObj] = RecvPosition(obj, msgObj)   ;
                    
                    
                otherwise error('msgId must be EVENT_TYPES')
            end
%             switch msgObj.srcId,
%                 case obj.GUI_TYPES.TWO_PHOTON_XY,
%                 case obj.GUI_TYPES.TWO_PHOTON_YT,
%                 case obj.GUI_TYPES.BEHAVIOR_XY,
%                 case obj.GUI_TYPES.BEHAVIOR_YT,
%                 otherwise error('srcId must be GUI_TYPES')
%             end
%                 
%             
%            
%             % output
%             msgObj.dstId            = obj.dstId;    % whom
%             msgObj.srcId            = srcId;        % from
%             msgObj.msgId            = msgId;        % what
%             dataObj                 = msgObj.data ;
               
        end
        % ---------------------------------------------
          % ==========================================
        function [obj,msgObj] = RecvPosition(obj, msgObj)
            % RecvPosition - receives 4D user position vector
            % Input:
            %   dataPos     - 4D position - must be integer  
            % Output:
            %    msgObj     - meassge structure
            
            if nargin < 2, dataPos = 112; end;
            
            % function list to call
            %msgObj.funCall  = {};
            msgObj.skip     = true;  % do not execute it
            msgObj.updateRefreshImage = false;
            msgObj.updateShowImage    = false;
            msgObj.updateRoiArray     = false;

            
%             %  check Id
%             switch msgObj.msgId,
%                 case obj.EVENT_TYPES.UPDATE_POS,
%                     % Last Position info
%                     % change in Z usually
%                     %[obj,msgObj] = RecvPosition(obj, msgObj)   ;
%                     %[obj,msgObj] = RecvPosition(obj, msgObj)   ;
%                 otherwise 
%                     return
%             end

            
            % get data 
            dataPos                 = msgObj.data;
            srcType                 = msgObj.srcType;     % from
            
            % check
            if numel(dataPos) ~= 4, error('Bad number of elements must be 4'); end;
            if ~all(dataPos == round(dataPos)), error('Position must be integer'); end;
            
            % decide if I should execute it  - any change
            % if the data is similar
            whatIsChanged   = obj.PrevPos ~= dataPos;
            if all(whatIsChanged == false), % no change
                action = 'no change';
                
            else
                % check Id : Sync time
                switch obj.MyType,
                    case obj.GUI_TYPES.TWO_PHOTON_XY,
                        msgObj.updateRefreshImage = true;
                        if srcType == obj.GUI_TYPES.BEHAVIOR_XY || srcType == obj.GUI_TYPES.BEHAVIOR_YT,
                            msgObj.data(4)         = dataPos(4) / obj.TimeConvertFact;
                        end;
                        if any(whatIsChanged(3:4)), % new image
                            msgObj.updateShowImage    = true;
                        end
                    case obj.GUI_TYPES.TWO_PHOTON_YT,
                        msgObj.updateRefreshImage = true;
                        if srcType == obj.GUI_TYPES.BEHAVIOR_XY || srcType == obj.GUI_TYPES.BEHAVIOR_YT,
                            msgObj.data(4)         = dataPos(4) / obj.TimeConvertFact;
                        end;
                         if whatIsChanged(1) || whatIsChanged(3), % X,Z
                            msgObj.updateShowImage    = true;
                        end
                   case obj.GUI_TYPES.BEHAVIOR_XY,
                        msgObj.updateRefreshImage = true;
                        if srcType == obj.GUI_TYPES.TWO_PHOTON_XY || srcType == obj.GUI_TYPES.TWO_PHOTON_YT,
                            msgObj.data(4)         = dataPos(4) * obj.TimeConvertFact;
                        end;
                        if any(whatIsChanged(3:4)), % T
                            msgObj.updateShowImage    = true;
                        end
                    case obj.GUI_TYPES.BEHAVIOR_YT,
                        msgObj.updateRefreshImage = true;
                         if srcType == obj.GUI_TYPES.TWO_PHOTON_XY ||srcType ==  obj.GUI_TYPES.TWO_PHOTON_YT,
                            msgObj.data(4)         = dataPos(4) * obj.TimeConvertFact;
                        end;
                       if whatIsChanged(1) || whatIsChanged(3), % X,Z
                            msgObj.updateShowImage    = true;
                       end
                    case obj.GUI_TYPES.ELECTROPHYS_YT,
                        msgObj.updateRefreshImage = true;
                         if srcType == obj.GUI_TYPES.TWO_PHOTON_XY ||srcType ==  obj.GUI_TYPES.TWO_PHOTON_YT,
                            msgObj.data(4)         = dataPos(4) * obj.TimeConvertFact;
                        end;
                       if whatIsChanged(1) || whatIsChanged(3), % X,Z
                            msgObj.updateShowImage    = true;
                       end
                        
                    otherwise error('msgId must be GUI_TYPES')
                end
                msgObj.skip     = false;  %  execute it
                action = 'update';
                
            end
            % remember
            obj.PrevPos             = dataPos; 
            
            
            
            %DTP_ManageText([], sprintf('CommRx : Receiving position info : %s',action), 'I' ,0)   ;             
        end
        % ---------------------------------------------
      
%          
%         % ==========================================
%         function obj = TestComm(obj)
%             
%             % Test4 - analysis data save and load
%             
%             testAnalysisDir  = 'C:\UsersJ\Uri\Data\Analysis\m8\02_10_14';
%             tempTrial     = 3;
%            
%             % select again using Full Load function
%             obj            = obj.SelectAnalysisData(testAnalysisDir);
% 
%             % load dta should fail
%             [obj, usrData] = obj.LoadAnalysisData(tempTrial);
%             if isempty(usrData), 
%                 DTP_ManageText([], sprintf('1 OK.'), 'I' ,0)   ;
%             end;
%             
%             StrROI          = 5;
%             StrEvent        = 10;
%             
%             obj            = obj.SaveAnalysisData(tempTrial,'StrROI',StrROI);
%             obj            = obj.SaveAnalysisData(tempTrial,'StrEvent',StrEvent);
%             
%             [obj, usrData] = obj.LoadAnalysisData(tempTrial);
%             if ~isempty(usrData), 
%                 DTP_ManageText([], sprintf('2 OK.'), 'I' ,0)   ;
%             end;
%             
%          
%         end
%         % ---------------------------------------------
    
        
        
    end% methods
end% classdef