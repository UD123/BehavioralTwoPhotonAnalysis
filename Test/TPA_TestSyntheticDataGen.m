classdef TPA_TestSyntheticDataGen
    % TPA_TestSyntheticDataGen - test function to generate synthetic data for two photon
    % images. Puts several files in the Imaging directory.
    % Inputs:
    %       none
    % Outputs:
    %        tif movies
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 23.22 30.08.16 UD     Z-stack testing
    % 17.08 05.04.14 UD     Created to test ROI problems
    %-----------------------------
    
    
    properties
        
        CellArray                   = {};               % cell params array
        ImgData                     = [];               % 3D array of image data
            
        FileDirPattern              = 'C:\Uri\DataJ\Janelia\Imaging\T2\01\01_mT2_%03d.tif';
        
    end % properties
    
    methods
        
        % ==========================================
        function obj = TPA_TestSyntheticDataGen()
            % TPA_TestSyntheticDataGen - constructor
            % Input:
            %   imgData - 3D dim data
            % Output:
            %     default values
                        
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = DeleteData(obj)
            % DeleteData - will remove stored video
            % Input:
            %   internal -
            % Output:
            %   ImgData,ImgDataFix  -  removed
            
            % clean it up
            obj.ImgData    = [];
            DTP_ManageText([], sprintf('Data Gen : Clearing intermediate results .'), 'W' ,0);
           
        end
        % ---------------------------------------------
      
        % ==========================================
        function obj = GenCellData(obj, cellType)
            % GenCellData - generate cells for testing.
            % Define number, size, fluorescence
            % Input:
            %   cellType  - which cell to use as input - could be an array
            % Output:
            %   CellArray - cell structure 
            
            if nargin < 2, cellType = 1; end;
            cellNum   = length(cellType);
            cellArray = cell(cellNum,1);
            
            % define cells
            for k = 1:cellNum,
            switch cellType(k),
                
                case 1, % cell params - silent
                    cellStr.pos        = [100 100 25 25]; % cell ret in XY
                    cellStr.xy         = [];               % actual boundary - TBD
                    cellStr.fluorAver  = 100;              % average fluorescnce
                    cellStr.fluorResp  = 100;              % response fluorescnce
                    cellStr.respTime   = [40 50];          % list of responses
                    
                case 2, % cell params - active
                    cellStr.pos        = [40 100 25 25]; % cell ret in XY
                    cellStr.xy         = [];               % actual boundary - TBD
                    cellStr.fluorAver  = 60;              % average fluorescnce
                    cellStr.fluorResp  = 100;              % response fluorescnce
                    cellStr.respTime   = [40 60];          % list of responses
                    
                case 3, % cell params - double resp
                    cellStr.pos        = [130 160 25 25]; % cell ret in XY
                    cellStr.xy         = [];               % actual boundary - TBD
                    cellStr.fluorAver  = 120;              % average fluorescnce
                    cellStr.fluorResp  = 150;              % response fluorescnce
                    cellStr.respTime   = [30 50; 90 100];  % list of responses
                    
                case 11, % 1 cells  - single resp
                    cellStr.pos        = [30 30 25 25]; % cell ret in XY
                    cellStr.xy         = [];               % actual boundary - TBD
                    cellStr.fluorAver  = 100;              % average fluorescnce
                    cellStr.fluorResp  = 140;              % response fluorescnce
                    cellStr.respTime   = [40 50];          % list of responses
                
                case 12, % 1 cells  - single resp
                    cellStr.pos        = [180 20 35 15]; % cell ret in XY
                    cellStr.xy         = [];               % actual boundary - TBD
                    cellStr.fluorAver  = 50;              % average fluorescnce
                    cellStr.fluorResp  = 70;              % response fluorescnce
                    cellStr.respTime   = [120 150];        % list of responses
                    
                otherwise
                    error('Bad cellType')
            end
            cellArray{k} = cellStr;
            end
            obj.CellArray = cellArray;
            
            
        end
        % ---------------------------------------------
        
      
        % ==========================================
        function obj = GenImgData(obj, imgType)
            % GenImgData - gen img data for testing.
            % Utilizes CellArray
            % Input:
            %   imgType  - which image to use as input
            % Output:
            %   ImgData - image data with shifts
            
            if nargin < 2, imgType = 1; end;
            if isempty(obj.CellArray),
                DTP_ManageText([], sprintf('Data Gen : Must init cell array first.'), 'E' ,0); return;
            end
            cellNum = length(obj.CellArray);   
            
            % find bounds on time
            nT          = 0;
            for k = 1:cellNum,
                nT      = max(nT,max(obj.CellArray{k}.respTime(:,2)));
            end
            nT          = ceil(nT*1.2);
            % image bounds are fixed
            nR          = 256; 
            nC          = 256;
            
            % gen data
            imgData     = uint16(rand(nR,nC,nT)*10);
            
            % add cells
            for k = 1:cellNum,
                
                % average
                xInd    = obj.CellArray{k}.pos(1):sum(obj.CellArray{k}.pos([1 3]));
                yInd    = obj.CellArray{k}.pos(2):sum(obj.CellArray{k}.pos([2 4]));
                imgData(yInd,xInd,:) = obj.CellArray{k}.fluorAver;
                
                % time responses
                for t = 1:size(obj.CellArray{k}.respTime,1),
                    tInd    = obj.CellArray{k}.respTime(t,1):obj.CellArray{k}.respTime(t,2);
                    imgData(yInd,xInd,tInd) = obj.CellArray{k}.fluorResp;
                    
                end
            end
            
            % noise and artifacts
            switch imgType,
                case 1, % poisson noise
                    imgData     = imnoise(imgData,'poisson');
               case 2, % rand
                otherwise
                    error('Bad imgType')
            end
            
            % assign
            obj.ImgData         = imgData;
            
            DTP_ManageText([], sprintf('Data Gen : Inout image dimensions R-%d,C-%d,Z-%d,T-%d.',nR,nC,1,nT), 'I' ,0)   ;
            
            
        end
        % ---------------------------------------------
        % ==========================================
        function obj = FileWrite(obj,fileNum)
            % FileWrite - writes tif file of the image data
            % Input:
            %   fileNum - file num to write
            % Output:
            %   ImgData  -  gen data
            if nargin  < 2, fileNum = 1; end;
            if isempty(obj.ImgData),
                DTP_ManageText([], sprintf('Data Gen : requires input file gen first.'), 'E' ,0);
                return
            end
            
            % tiff file write
            fileDirName         = sprintf(obj.FileDirPattern,fileNum);
            
            % check dir
            [fPath,fName]      = fileparts(fileDirName);
            if ~exist(fPath,'dir'),mkdir(fPath); end
            
            % inform
            DTP_ManageText([], sprintf('Data Gen : Writing data to file %s. Please Wait ...',fileDirName), 'I' ,0)   ;             


            %  working for 16 bit samples, 16 TBD
            saveastiff(uint16(obj.ImgData), fileDirName);
            
            DTP_ManageText([], sprintf('Data Gen : Done'), 'I' ,0)   ;             
            
        end
        % ---------------------------------------------
  
        
        % ==========================================
        function obj = ViewVideo(obj,FigNum)
            % ViewData - plays stored video.
            % Supports two and separate channels
            % Input:
            %   internal -
            % Output:
            %   ImgData,ImgDataFix  -  are played together
             if nargin  < 2, FigNum = 1; end;
           
            if isempty(obj.ImgData),
                DTP_ManageText([], sprintf('Data Gen : requires input file gen first.'), 'E' ,0);
                return
            end
            % player plays 3 dim movies
            D                      = obj.ImgData;
            %figure(FigNum),
            implay(D)
            %title(sprintf('Original Left, Corrected-Right '))
            
        end
        % ---------------------------------------------
            
        % ==========================================
        function obj = TestSingleFile(obj)
            
            % TestSingleFile - generates 1 file for test
            
            cellType            = [1 2 3];
            imgType             = 1; % noise
            fileNum             = 1;
            obj.FileDirPattern  = 'C:\\Uri\\DataJ\\Janelia\\Imaging\\T2\\01\\01_mT2_%03d.tif';
            
            % cells
            obj                 = GenCellData(obj, cellType);
            obj                 = GenImgData(obj, imgType);
            obj                 = FileWrite(obj,fileNum);
            obj                 = ViewVideo(obj);
            obj                 = DeleteData(obj);
            
        end
        % ---------------------------------------------
        % ==========================================
        function obj = TestMultiFile(obj)
            
            % TestMultieFile - generates several files for test
            
            cellType            = [1 2 3 11 12];
            imgType             = 1; % camera man
            fileNum             = 5;
            obj.FileDirPattern  = 'C:\\LabUsers\\Uri\\Data\\Janelia\\Imaging\\T2\\02\\02_T2_%03d.tif';
            
            % cells
            obj                 = GenCellData(obj, cellType);
            
            % file gen
            for k = 1:fileNum,
                obj                 = GenImgData(obj, imgType);
                obj                 = FileWrite(obj,k);
            end
            
            obj             = FileWrite(obj,fileNum);
            obj             = ViewVideo(obj);
            obj             = DeleteData(obj);
            
        end
        % ---------------------------------------------
        % ==========================================
        function obj = TestMultiZStack(obj)
            
            % TestMultieFile - generates several files for test
            
            cellType            = [1 2 3 11 12];
            imgType             = 1; % 
            zNum                = 3;
            obj.FileDirPattern  = 'C:\\LabUsers\\Uri\\Data\\Janelia\\Imaging\\T2\\03\\03_T2_%03d.tif';
            
            % cells
            imgData             = [];
            
            % file gen
            for z = 1:zNum,
                if      z == 1, cellType            = [1 2 3 ]; 
                elseif  z == 2, cellType            = [11 12];
                end
                obj                 = GenCellData(obj, cellType);
                obj                 = GenImgData(obj, imgType);
                [nR,nC,nT]          = size(obj.ImgData);
                if isempty(imgData), 
                    imgData          = repmat(obj.ImgData(:,:,1),[1 1 zNum*nT]); 
                end
                imgData(:,:,z + (0:nT-1)*zNum)     = obj.ImgData;
            end
            
            obj.ImgData     = imgData;
            obj             = FileWrite(obj,1);
            obj             = ViewVideo(obj);
            obj             = DeleteData(obj);
            
        end
        % ---------------------------------------------
        
              
       
    end% methods
end% classdef
