classdef TPA_DataManagerMemory
    % TPA_DataManagerMemory - manages data in memory
    % Inputs:
    %       
    % Outputs:
    %       data for different graphs and searches
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 25.08 19.04.17 UD     making handle
    % 23.22 23.08.16 UD     Created
    %-----------------------------
    
    
    properties
        
        % in memory big data
        imBehaive    % behavioral data
        imTwoPhoton  % two photon data
        strROI       % two phton roi
        strEvent     % behavioral events
        strManager % strManager will manage counters
      
        
    end % properties
    properties (SetAccess = private)
        %TimeConvertFact     = 1;           % time conversion >= 1 between behav - fast and twophoton - slow
        %TimeEventAligned    = false;        % if the events has been time aligned
    end
    
    methods
        
        % ==========================================
        function obj = TPA_DataManagerMemory()
            % TPA_DataManagerFileDir - constructor
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            
            obj = Init(obj);
        end
        
        % ==========================================
        function obj = Init(obj)
            % Init - init Par structure related managers of the DB
            % Input:
            %    Par        - structure with defines
            % Output:
            %     default values
            
            % manager 
            % in memory big data
            obj.imBehaive   = [];
            obj.imTwoPhoton = [];
            obj.strROI      = [];
            obj.strEvent    = [];
            obj.strManager  = struct('roiCount',0,'eventCount',0); % strManager will manage counters
            
            
        end
        
        
        
    end% methods
end% classdef
