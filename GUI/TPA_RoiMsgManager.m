classdef TPA_RoiMsgManager
    % TPA_RoiManager - Detects Roi update info and commands to call certain functions
    % Inputs:
    %       different
    % Outputs:
    %        different
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 18.01 13.04.14 UD     Support Electro Phys
    % 16.09 20.02.14 UD     create and integration
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
    end

    methods
        
        % ==========================================
        function obj = TPA_RoiMsgManager(Par, MyGuiType, MyGuiId)
            % TPA_RoiMsgManager - constructor
            % Input:
            %    Par        - structure with defines
            %     MyGuiType - whos creates me
            %     MyGuiId   - whos creates me
            % Output:
            %     default values
            if nargin < 3, error('Must have these'); end;
            
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
            
            
        end
        % ---------------------------------------------
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
                case obj.EVENT_TYPES.UPDATE_IMAGE,
                case obj.EVENT_TYPES.UPDATE_ROI,
                    [obj,msgObj] = SendRoi(obj,dataObj);
                otherwise error('msgId must be EVENT_TYPES')
            end
%             switch srcId,
%                 case obj.GUI_TYPES.TWO_PHOTON_XY,
%                 case obj.GUI_TYPES.TWO_PHOTON_YT,
%                 case obj.GUI_TYPES.BEHAVIOR_XY,
%                 case obj.GUI_TYPES.BEHAVIOR_YT,
%                 otherwise error('msgId must be GUI_TYPES')
%             end
            
            
            
               
            DTP_ManageText([], sprintf('CommTx : message %d from %d is encoded',msgObj.msgId,msgObj.srcId), 'I' ,0)   ;             
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,msgObj] = SendRoi(obj,dataObj)
            % SendRoi - roi info
            % Input:
            %   dataObj     - structure ???  
            % Output:
            %    msgObj     - meassge structure
            
            if nargin < 2, dataObj = 112; end;
            
%             % check
%             if numel(dataPos) ~= 4, error('Bad number of elements must be 4'); end;
%             if ~all(dataPos == round(dataPos)), error('Position must be integer'); end;
            
            
            % output
            msgObj.dstId            = obj.DstId;    % whom
            msgObj.srcId            = obj.MyId;     % from
            msgObj.msgId            = obj.EVENT_TYPES.UPDATE_ROI;        % what
            msgObj.msgCount         = obj.TxCount;
            msgObj.data             = dataObj;
            
            % bookeeping
            obj.TxCount             = obj.TxCount + 1;
            
            % output
            %[obj,msgObj]            = Encode(obj, obj.EVENT_TYPES.UPDATE_POS, dataPos) ;
            
            DTP_ManageText([], sprintf('CommTx : Sending ROI info'), 'I' ,0)   ;             
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
            msgObj.skip                 = true;  % do not execute it
            msgObj.updateRefreshImage   = false;
            msgObj.updateShowImage      = false;
            msgObj.updateRoiArray       = false;
            
            DTP_ManageText([], sprintf('CommRx : message %d from %d is decoded',msgObj.msgId,msgObj.srcId), 'I' ,0)   ;             
            
            
            % decode and rescale when coming from different "time zone"
            switch msgObj.msgId,
                case obj.EVENT_TYPES.UPDATE_IMAGE,
                    % change in Z usually
                    
                case obj.EVENT_TYPES.UPDATE_ROI,
                    % Last Roi info
                    %[obj,msgObj] = RecvRoi(obj, msgObj)   ;
                    [obj,msgObj] = RecvRoi(obj, msgObj)   ;
                    
                case obj.EVENT_TYPES.UPDATE_POS,
                    % Last Position info
                    % change in Z usually
                    %[obj,msgObj] = RecvPosition(obj, msgObj)   ;
                    
                    
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
        function [obj,msgObj] = RecvRoi(obj, msgObj)
            % RecvRoi - receives ROI info
            % Input:
            %   msgObj     - message with ROI info  
            % Output:
            %    msgObj     - meassge structure
            
            if nargin < 2, msgObj = 112; end;
            
            % function list to call
           % msgObj.funCall  = {};

            obj.RxCount             = obj.RxCount + 1;
            
            
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

            
%             % get data 
%             dataPos                 = msgObj.data;
%             
%             % check
%             if numel(dataPos) ~= 4, error('Bad number of elements must be 4'); end;
%             if ~all(dataPos == round(dataPos)), error('Position must be integer'); end;
%             
            % decide if I should execute it  - self execution are prohibited
            isItMyMessage   = obj.MyId == msgObj.srcId;
            if isItMyMessage, % no change
                action = 'no change : my message';
            else
                % check Id
                action = 'skip';
                switch obj.MyType,
                    case obj.GUI_TYPES.TWO_PHOTON_XY,
                        msgObj.updateRefreshImage = true;
                        msgObj.updateRoiArray     = true;
                        action = 'update';
                    case obj.GUI_TYPES.TWO_PHOTON_YT,
                        msgObj.updateRefreshImage = true;
                        msgObj.updateRoiArray     = true;
                        action = 'update';
                    case obj.GUI_TYPES.BEHAVIOR_XY,
                    case obj.GUI_TYPES.BEHAVIOR_YT,
                        
                    case obj.GUI_TYPES.ELECTROPHYS_YT,
                        
                    otherwise error('msgId must be GUI_TYPES')
                end
                msgObj.skip     = false;  %  execute it
                
            end
            
            
            
            DTP_ManageText([], sprintf('CommRx : Receiving Roi info : %s',action), 'I' ,0)   ;             
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