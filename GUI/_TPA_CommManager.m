classdef TPA_CommManager
    % TPA_CommManager - Responsible for multi Window GUI communication.
    % Creates, sends, receives and decodes messages.
    % Resonsible for time zone and data rescaling
    % Inputs:
    %       different
    % Outputs:
    %        different
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 16.07 20.02.14 UD     create and integration
    %-----------------------------
    
    
    properties
        
        % 
        
        % bookeeping
        TxCount             = 0;  % tx message counter
        RxCount             = 0;  % rx message counter

        % output
        dstId               = 255;  % destination object : 255 - broadcast
        %srcId               = 0;  % sending object : user info, roi
        %msgId               = 0;  % message type: update/delete ...
        data                = [];
        
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
        MyId                = 0;          % my address
    end

    methods
        
        % ==========================================
        function obj = TPA_CommManager(Par,MyGuiType)
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
                otherwise error('msgId must be GUI_TYPES')
            end
            
            obj.MyId        = MyGuiType;
            
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
            
            % check
            switch msgId,
                case obj.EVENT_TYPES.UPDATE_POS,
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
            
            
            % bookeeping
            obj.TxCount             = obj.TxCount + 1;
            
            % output
            msgObj.dstId            = obj.dstId;    % whom
            msgObj.srcId            = obj.MyId;     % from
            msgObj.msgId            = msgId;        % what
            msgObj.msgCount         = obj.TxCount;
            msgObj.data             = dataObj;
               
            DTP_ManageText([], sprintf('CommTx : message %d from %d is encoded',msgObj.msgId,msgObj.srcId), 'I' ,0)   ;             
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
            if ~all(dataPos ~= round(dataObj)), error('Position must be integer'); end;
            
            % output
            [obj,msgObj]            = Encode(obj, obj.EVENT_TYPES.UPDATE_POS, dataPos) ;
            
            DTP_ManageText([], sprintf('CommTx : Sending position info'), 'I' ,0)   ;             
        end
        % ---------------------------------------------

        % ==========================================
        function [obj,msgObj] = SendRoi(obj,roiObj)
            % SendRoi - sends ROI structure
            % Input:
            %   roiObj     - 4D position - must be integer  
            % Output:
            %    msgObj     - meassge structure
            
            if nargin < 2, roiObj = 123; end;
            
            % check
            if isfield(roiObj,'Name') ~= 4, error('This is not ROI structure???'); end;
            
            % output
            [obj,msgObj]    = Encode(obj, obj.EVENT_TYPES.UPDATE_ROI, roiObj) ;
            
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
            obj.RxCount             = obj.RxCount + 1;
            
            % decode and rescale when coming from different "time zone"
            switch msgObj.msgId,
                case obj.EVENT_TYPES.UPDATE_IMAGE,
                    % change in Z usually
                    [obj,msgObj] = RecvPosition(obj, msgObj)   ;
                    
                case obj.EVENT_TYPES.UPDATE_ROI,
                    % Last Roi info
                    [obj,msgObj] = RecvRoi(obj, msgObj)   ;
                    
                case obj.EVENT_TYPES.UPDATE_POS,
                    % Last Position info
                    % change in Z usually
                    [obj,msgObj] = RecvPosition(obj, msgObj)   ;
                    
                    
                otherwise error('msgId must be EVENT_TYPES')
            end
            switch msgObj.srcId,
                case obj.GUI_TYPES.TWO_PHOTON_XY,
                case obj.GUI_TYPES.TWO_PHOTON_YT,
                case obj.GUI_TYPES.BEHAVIOR_XY,
                case obj.GUI_TYPES.BEHAVIOR_YT,
                otherwise error('srcId must be GUI_TYPES')
            end
                
            
           
            % output
            msgObj.dstId            = obj.dstId;    % whom
            msgObj.srcId            = srcId;        % from
            msgObj.msgId            = msgId;        % what
            dataObj                 = msgObj.data ;
               
            DTP_ManageText([], sprintf('CommRx : message %d from %d is decoded',msgId,srcId), 'I' ,0)   ;             
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
            
            % check
            if numel(dataPos) ~= 4, error('Bad number of elements must be 4'); end;
            if ~all(dataPos ~= round(dataObj)), error('Position must be integer'); end;
            
            % output
            msgId                   = obj.EVENT_TYPES.UPDATE_POS;
            [obj,msgObj]            = Encode(obj, msgId, dataPos) ;
            
            DTP_ManageText([], sprintf('CommTx : Sending position info'), 'I' ,0)   ;             
        end
        % ---------------------------------------------
          % ==========================================
        function [obj,msgObj] = RecvRoi(obj, msgObj)
            % RecvRoi - receives roi data object
            % Input:
            %   dataPos     - 4D position - must be integer  
            % Output:
            %    msgObj     - meassge structure
            
            if nargin < 2, dataPos = 112; end;
            
            % check
            if numel(dataPos) ~= 4, error('Bad number of elements must be 4'); end;
            if ~all(dataPos ~= round(dataObj)), error('Position must be integer'); end;
            
            % output
            msgId                   = obj.EVENT_TYPES.UPDATE_POS;
            [obj,msgObj]            = Encode(obj, msgId, dataPos) ;
            
            DTP_ManageText([], sprintf('CommTx : Sending position info'), 'I' ,0)   ;             
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
         
        end
        % ---------------------------------------------
    
        
        
    end% methods
end% classdef