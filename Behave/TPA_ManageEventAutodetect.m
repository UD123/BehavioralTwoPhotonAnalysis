classdef TPA_ManageEventAutodetect
    % TPA_ManageRoiAutodetect - finds intersting events in the Behavioral data
    % Inputs:
    %       none
    % Outputs:
    %       strEvent    -  event descriptions
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 19.06 21.09.14 UD     Adding JAABA features  - only hog and optical flow
    % 18.10 08.07.14 UD     Adding boosting
    % 18.08 01.07.14 UD     Event Names
    % 18.03 26.04.14 UD     Updated
    % 17.09 07.04.14 UD     Created for Event data analysis
    %-----------------------------
    
    
    properties
        
        % image input related
        ImgData                     = [];               % 3D array (nR x nC x nT) of image data
        ImgSize                     = [0 0 0];          % input array size
        ImgClass                    = [];               % pixel type
        
        ImgDataIs4D                 = false;            % remember that image data was
        DecimationFactor            = [2 2 1 ];         % decimate real data [nR x nR x nT]
        
        % class Params
        binSize                     = 32;               % histogram related
        nOrient                     = 9;                % hist related
        FeatMtrx                    = [];               % nVect x nFeat feature matrix
        FeatSize                    = [];               % contains binning info sizr
        FeatType                    = 'JAABA'  ;        % Feature options are - FHOG3D,JAABA, etc
        
        % events
        DMB                         = [];               % behavior database object
        ClassType                   = 'Fern';           % Class types : Fern or Boost
        ClassPrm                    = [];               % classifier structure
        ClassMtrx                   = [];               % nVect x nEvent classifier matrix
        ClassVect                   = [];               % nVect x 1 classifier vector with nEvent+1 values
        ClassVectEst                = [];               % nVect x 1 classifier vector with nEvent+1 values - estimated
        ClassNames                  = {};               % 1 x nEvent classifier names
        ClassNum                    = 1;                % number of classifiers
        EventNameOptions            = {};               % possible event names
        
        
    end % properties
    
    methods
        
        % ==========================================
        function obj = TPA_ManageEventAutodetect(Par)
            % TPA_ManageEventAutodetect - constructor
            % Input:
            %   none
            % Output:
            %     default values
            
            % connect to different algorithms
            %addpath(genpath('C:\LabUsers\Uri\Code\Matlab\piotr_toolbox_V3.24\toolbox'));
            if nargin < 1, 
                Par.Event.NameOptions = fieldnames(struct('None',1,'Grab',2,'Chew',3,'GrabMiss',4));
            end
            
            obj.EventNameOptions  = Par.Event.NameOptions;
            %obj                   = InitClassifier(obj);
            
            
        end
        % ---------------------------------------------
        % ==========================================
        function obj = DeleteData(obj)
            % DeleteData - will remove stored video data
            % Input:
            %   internal -
            % Output:
            %   default
            
            % clean it up
            obj.ImgData     = [];
            obj.FeatMtrx    = [];
            obj.ClassMtrx   = [];
            obj.ClassVect   = [];
            obj.DMB         = [];
            obj.ClassPrm     = [];
            DTP_ManageText([], sprintf('AutoDetect : Clearing intermediate results.'), 'W' ,0);
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj, imgData] = LoadImageData(obj,fileDirName)
            % LoadImageData - loads image for fileName into memory
            % Input:
            %     currTrial - integer that specifies trial to load
            % Output:
            %     imgData   - 3D array image data
            
            if nargin < 2, fileDirName = 'C:\Uri\DataJ\Janelia\Videos\M2\2_20_14\Basler_side_20_02_2014_m2_6.avi'; end;
            imgData             = [];
            
            % check
            if ~exist(fileDirName,'file')
                showTxt     = sprintf('AutoDetect : No data found. Aborting');
                DTP_ManageText([], showTxt, 'E' ,0) ;
                return;
            end
            
            if verLessThan('matlab', '8.1.0')
                readObj             = mmreader(fileDirName);
            else
                readObj             = VideoReader(fileDirName);
            end
            imgData             = read(readObj);
            imgSize             = size(imgData);
            
            % save
            obj.ImgSize         = imgSize;
            DTP_ManageText([], sprintf('AutoDetect : %d images (Z=1) are loaded from file %s successfully',imgSize(3),fileDirName), 'I' ,0)   ;
            
            % set data to internal structure and convert to single
            obj                 = SetImageData(obj,imgData);
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = SetImageData(obj,imgData)
            % SetImageData - check the data before convert it to 3D
            % Input:
            %   imgData - 3D-4D data stored after Image Load
            % Output:
            %   obj.ImgData - (nRxnCxnT)  3D array
            
            if nargin < 2, error('Reuires image data as input'); end;
            % remove dim
            [nR,nC,nZ,nT] = size(imgData);
            DTP_ManageText([], sprintf('AutoDetect : Inout image dimensions R-%d,C-%d,Z-%d,T-%d.',nR,nC,nZ,nT), 'I' ,0)   ;
            
            % data is 4D :  make it 3D by stacking each channel
            if nT > 1 && nZ > 1,
                DTP_ManageText([], sprintf('AutoDetect : Multiple Z stacks are detected. Creating single image from multiple channels.'), 'W' ,0);
                imgData         = squeeze(imgData(:,:,1,:));
                obj.ImgDataIs4D = true;
            elseif nT == 1, % 3D - do nothing
            end
            % make it 3D
           
            % check decimation
            if nR > 400 && nC > 600, %any(obj.DecimationFactor > 1),
                DTP_ManageText([], sprintf('AutoDetect : Image data is decimated. Check decimation factors '), 'W' ,0)   ;
                % indexing
                sz              = size(imgData);
                imgData         = imgData(1:obj.DecimationFactor(2):sz(1),1:obj.DecimationFactor(1):sz(2),1:obj.DecimationFactor(3):sz(3));
            end
            imgSize             = size(imgData);
            
            
            % output
            obj.ImgData     = single(imgData);
            obj.ImgClass    = class(obj.ImgData);
            obj.ImgSize     = imgSize;
            
            DTP_ManageText([], sprintf('AutoDetect : %d images are in use.',imgSize(3)), 'I' ,0)   ;
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = ComputeFeatureFHOG3D(obj)
            % ComputeFeatureFHOG3D encodes video stream D into 3D histograms using fhog features
            % encoded by Piotr toolbox
            %
            % Inputs:
            %       obj         - parameters
            %       ImgData     - nR x nC x nT image array (in object)
            % Outputs:
            %       obj         - parameters updated
            %       FeatMtrx    - nVect x nFeat output after hist encoding
            
            if nargin < 1, error('Reuires additional input');            end;
            
            
            %%% Data
            %
            
            obj.ImgData = single(squeeze(obj.ImgData));
            [nR,nC,nT]  = size(obj.ImgData);
            % centers
            %[nRc,nCc,nTc] = deal(round(nR/2),round(nC/2),round(nT/2));
            if nT < 2, 
                  DTP_ManageText([], sprintf('AutoDetect : Requires valid image data for load'), 'E' ,0)   ;
                  return
            end
            
            %%% Collect different dim
            tH  = {}; k = 1;
            for t = 1:obj.binSize:nT,
                I       = squeeze(obj.ImgData(:,:,t));
                H       = fhog(I,obj.binSize,obj.nOrient);
                tH{k}   = H; k = k + 1;
            end
            % V   = hogDraw(H,25,1);
            % figure(11); im(I);
            % figure(12); montage2(H);
            % figure(13); im(V)
            
            cH  = {}; k = 1;
            for c = 1:obj.binSize:nC,
                I       = squeeze(obj.ImgData(:,c,:));
                H       = fhog(I,obj.binSize,obj.nOrient);
                cH{k}   = H; k = k + 1;
            end
            
            rH  = {}; k = 1;
            for r = 1:obj.binSize:nR,
                I       = squeeze(obj.ImgData(r,:,:));
                H       = fhog(I,obj.binSize,obj.nOrient);
                rH{k}   = H; k = k + 1;
            end
            
            
            %%% Form feature vector
            [nRBin,nCBin,nFeat] = size(tH{1});
            [~,nTBin,nFeat]     = size(rH{1});
            
            [rInd,cInd,tInd]    = meshgrid(1:nRBin,1:nCBin,1:nTBin);
            [rInd,cInd,tInd]    = deal(rInd(:),cInd(:),tInd(:));
            featNum             = length(rInd);
            featMtrx            = zeros(featNum,3*nFeat,'single');
            for k = 1:featNum,
                rcMtrx          = tH{tInd(k)};
                rcVect          = rcMtrx(rInd(k),cInd(k),:);
                rtMtrx          = rH{rInd(k)};
                rtVect          = rtMtrx(cInd(k),tInd(k),:);
                ctMtrx          = cH{cInd(k)};
                ctVect          = ctMtrx(rInd(k),tInd(k),:);
                featVect        = cat(3,rcVect,rtVect,ctVect);
                featMtrx(k,:)   = shiftdim(featVect,1);
            end
            
            % I   = squeeze(D(nRc,:,:));
            % H   = fhog(I,8,9);
            % V   = hogDraw(H,25,1);
            % figure(31); im(I);
            % figure(32); montage2(H);
            % figure(33); im(V)
            
            obj.FeatMtrx       = double(featMtrx);
            obj.FeatSize       = [nRBin nCBin nTBin];
            
            DTP_ManageText([], sprintf('AutoDetect : Feature matrix created'), 'I' ,0)   ;
            
            
        end
        % ---------------------------------------------

        
        % ==========================================
        function obj = ComputeFeatureJAABA(obj)
            % ComputeFeatureJAABA encodes video straem D into feature vectors
            % using JAABA encoding style - optical flow and hog histograms
            %
            % Inputs:
            %       obj         - parameters
            %       ImgData     - nR x nC x nT image array (in object)
            % Outputs:
            %       obj         - parameters updated
            %       FeatMtrx   - nVect x nFeat output after hist encoding
            
            if nargin < 1, error('Reuires additional input');            end;
            
            
            %%% Data
            %
            
            obj.ImgData = single(squeeze(obj.ImgData));
            [nR,nC,nT]  = size(obj.ImgData);
            % centers
            %[nRc,nCc,nTc] = deal(round(nR/2),round(nC/2),round(nT/2));
            if nT < 2, 
                  DTP_ManageText([], sprintf('AutoDetect : Requires valid image data for load'), 'E' ,0)   ;
                  return
            end
            
            % initialize HOG, HOF buffer
            patchCurr   = obj.ImgData(:,:,1);
            psize       = obj.binSize;
            nbins       = obj.nOrient;
            nFeat       = 9; % dimensions of the hog
            
            % prepare
            [nRBin,nCBin]   = deal(floor(nR/psize),floor(nC/psize));
            Fall            = zeros(nRBin*nCBin*nFeat,nT,'single');
            %Hall            = Fall; 
             
            DTP_ManageText([], sprintf('AutoDetect : JAABA Feature matrix in process... Please Wait ...'), 'I' ,0)   ;
      
            for t = 1:nT,

              patchPrev = patchCurr;
              patchCurr = obj.ImgData(:,:,t);

              % HOG
              % step size is two for gradient computation
              % approx equiv Matlab code, ignoring borders
              % gx = patchCurr(2:end-1,3:end)-patchCurr(2:end-1,1:end-2); 
              % gy = patchCurr(3:end,2:end-1)-patchCurr(1:end-2,2:end-1);
              % M = sqrt(gx.^2+gy.^2)/2;
              % O = modrange(atan2(gy,gx),0,pi);
%               % will match M(2:end-1,2:end-1) and O(2:end-1,2:end-1)
%               [M,O] = gradientMag(patchCurr/16); 
%               H     = gradientHist(M,O,psize,nbins,1);
%               %Hall{t} = H;
%               Hall(:,:,t) = reshape(H,[],nFeat); % makes 3D matrx into 2D keeping vectors at row


              [Vx,Vy,~] = optFlowLk(patchPrev,patchCurr,[],3);
              % Gradient hist requires orientation to be between 0 and pi. Makes sense for
              % image gradients. But for flow pi/2 is different than -pi/2. So adjust for
              % that.

              M = sqrt(Vx.^2 + Vy.^2);
              O = mod(atan2(Vy,Vx)/2,pi);
              O = min(O,pi-1e-6);
              H = gradientHist(single(M),single(O),psize,nbins,1);
              G = reshape(H,[],nFeat); % makes 3D matrx into 2D keeping vectors at row
              Fall(:,t) = reshape(G',[],1); % take them one by one
          end
  
% 
%           if first,
%             flowftrs = zeros([size(curFall),numel(ts)],'single');
%             hogftrs = zeros([size(curFall),numel(ts)],'single');
%           end
              
            
            %%% Form feature vector
            %[nRBin,nCBin]       = size(H);
            nTBin               = nT;
            
            %[rInd,cInd,tInd]    = meshgrid(1:nRBin,1:nCBin,1:nTBin);
            %[rInd,cInd,tInd]    = deal(rInd(:),cInd(:),tInd(:));
            %featNum             = length(rInd);
            %featMtrx            = cat(2,reshape(Fall,[],nFeat),reshape(Hall,[],nFeat));
            featMtrx            = Fall'; %reshape(Fall,[],nFeat);
            
            % shift in time around this point
            featMtrx            = [featMtrx([nT 1:nT-1],:) featMtrx([2:nT 1],:)]; %reshape(Fall,[],nFeat);
            
%             for k = 1:featNum,
%                 rcMtrx          = tH{tInd(k)};
%                 rcVect          = rcMtrx(rInd(k),cInd(k),:);
%                 rtMtrx          = rH{rInd(k)};
%                 rtVect          = rtMtrx(cInd(k),tInd(k),:);
%                 ctMtrx          = cH{cInd(k)};
%                 ctVect          = ctMtrx(rInd(k),tInd(k),:);
%                 featVect        = cat(2,rcVect,rtVect,ctVect);
%                 featMtrx(k,:)   = shiftdim(featVect,1);
%             end
            
            % I   = squeeze(D(nRc,:,:));
            % H   = fhog(I,8,9);
            % V   = hogDraw(H,25,1);
            % figure(31); im(I);
            % figure(32); montage2(H);
            % figure(33); im(V)
            
            obj.FeatMtrx       = double(featMtrx);
            obj.FeatSize       = [nRBin nCBin nTBin];
            
            DTP_ManageText([], sprintf('AutoDetect : JAABA style Feature matrix created'), 'I' ,0)   ;
            
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = ConvertImageToFeatures(obj, featType)
            % ConvertImageToFeatures encodes video stream D into feature matrix
            % using different feature encoding options.
            %
            % Inputs:
            %       obj - parameters
            %       ImgData   - nR x nC x nT image array (in object)
            %       featType  - FHOG3D/JAABA - availabke options
            % Outputs:
            %       obj - parameters updated
            %       FeatMtrx   - nVect x nFeat output after hist encoding
            
            if nargin < 1, error('Reuires additional input');            end;
            if nargin < 2, featType = obj.FeatType;                       end;
            
            
            %%% 
            % Check
            %%%
            switch featType,
                case 'FHOG3D',
                    obj = ComputeFeatureFHOG3D(obj);
                case 'JAABA'
                    obj = ComputeFeatureJAABA(obj);
                otherwise
                    error('Unupported feature type %s',featType)
            end
                    
            
            %DTP_ManageText([], sprintf('AutoDetect : Feature matrix created'), 'I' ,0)   ;
            
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function [obj,strEvent] = ConvertEventToClass(obj,strEvent)
            % ConvertEventToClass - get event data and translates it to classifier format
            % Input:
            %   strEvent   - event structure array
            % Output:
            %   strEvent    - cell list of events with classValue vector equal to the feature length
            
            % this code helps with sequential processing of the ROIs: use old one in the new image
            nEvent               = length(strEvent);
            if nEvent < 1,
                DTP_ManageText([], sprintf('AutoDetect : There are no events.'),  'E' ,0);
                return
            end
            
            % take the image data matrix and using bining estimate new position of the events
            [nVect,nFeat]       = size(obj.FeatMtrx);
            if nVect < 1,
                DTP_ManageText([], sprintf('AutoDetect : load image data first.'),  'E' ,0);
                return
            end
            
            classMtrx           = zeros(nVect,nEvent);
            classNames          = cell(1,nEvent+1);
            timeFactor          = prod(obj.ImgSize(1:2))/obj.binSize^3;  % dependes on encoding of time
            
            % read the info
            classNames{1}       = 'None'; % empty event
            for eInd = 1:nEvent,
                
                if isfield(strEvent{eInd},'zInd')
                    if strEvent{eInd}.zInd > 1,
                        DTP_ManageText([], sprintf('AutoDetect : Event %d from other Z stack is used.',eInd),  'W' ,0);
                    end
                end
                
                classNames{eInd+1} = strEvent{eInd}.Name;      % name
                xy               = strEvent{eInd}.xyInd;          % shape in xy plane
                timeInd          = round([min(xy(:,1)) max(xy(:,1))]);  % time/frame indices
                timeInd          = round(timeInd.*timeFactor);
                if any(timeInd < 1) || any(timeInd > nVect), continue; end;
                classMtrx(timeInd(1):timeInd(2),eInd) = eInd+1;
            end
            
            % check overlap
            if any(sum(classMtrx > 0,2) > 1),
                DTP_ManageText([], sprintf('AutoDetect : Classifiers overlap. Possibly event time marks overlap. Recheck event data'),  'E' ,0);
                return
            end
            % collapse for toolbox representation
            classVect           = sum(classMtrx,2);
            classVect(classVect < 1) = 1; % Mark none
            
            % output
            obj.ClassVect   = classVect;  %
            obj.ClassMtrx   = classMtrx;  % debug
            obj.ClassNames  = classNames;
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,strEvent] = ConvertEvent3DToClass(obj,strEvent)
            % ConvertEvent3DToClass - get event data which defined 3D box and translates it to classifier format
            % Input:
            %   strEvent   - event structure array
            % Output:
            %   strEvent    - cell list of events with classValue vector equal to the feature length
            
            % this code helps with sequential processing of the ROIs: use old one in the new image
            nEvent                    = length(strEvent);
            if nEvent < 1,
                DTP_ManageText([], sprintf('AutoDetect : There are no events.'),  'E' ,0);
                return
            end
            
            % take the image data matrix and using bining estimate new position of the events
            [nVect,nFeat]               = size(obj.FeatMtrx);
            if nVect < 1,
                DTP_ManageText([], sprintf('AutoDetect : load image data first.'),  'E' ,0);
                return
            end
            
            % generate indices
            nRBin               = obj.FeatSize(1);
            nCBin               = obj.FeatSize(2);
            nTBin               = obj.FeatSize(3);
            [rInd,cInd,tInd]    = meshgrid(1:nRBin,1:nCBin,1:nTBin);
            [rInd,cInd,tInd]    = deal(rInd(:),cInd(:),tInd(:));
            
            classMtrx           = zeros(nVect,nEvent);
            classNames          = cell(1,nEvent+1);
            
            % read the info
            classNames{1}       = 'None'; % empty event
            for eInd = 1:nEvent,
                
                if isfield(strEvent{eInd},'zInd')
                    if strEvent{eInd}.zInd > 1,
                        DTP_ManageText([], sprintf('AutoDetect : Event %d from other Z stack is used.',eInd),  'W' ,0);
                    end
                end
                
                if ~isfield(strEvent{eInd},'tInd')
                    strEvent{eInd}.tInd = [1,nVect];
                    DTP_ManageText([], sprintf('AutoDetect : Event %d extended in time (no tInd found).',eInd),  'W' ,0);
                end
                
                if ~isfield(strEvent{eInd},'xyInd')
                    strEvent{eInd}.xyInd = [1 1;100 100];
                    DTP_ManageText([], sprintf('AutoDetect : Event %d extended in XY (no xyInd found).',eInd),  'W' ,0);
                end
                
                % deal with names
                eventId          = find(strcmp(obj.EventNameOptions,strEvent{eInd}.Name));
                if isempty(eventId),  
                    eventId      = 1; 
                    DTP_ManageText([], sprintf('AutoDetect : Can not find name of of the event %s in the list. Converting to NONE .',strEvent{eInd}.Name),  'W' ,0);
                end; % none
                    
                
                
                xy              = strEvent{eInd}.xyInd + obj.binSize/2;          % shape in xy plane
                tb              = strEvent{eInd}.tInd + obj.binSize/2;
                rBB             = [floor(min(xy(:,2))/obj.binSize) ceil(max(xy(:,2))/obj.binSize)];
                cBB             = [floor(min(xy(:,1))/obj.binSize) ceil(max(xy(:,1))/obj.binSize)];
                tBB             = [floor(tb(1)/obj.binSize) ceil(tb(2)/obj.binSize)];
                
                % classifier location
                classVect       = rBB(1) <= rInd & rInd <= rBB(2) & ...
                                  cBB(1) <= cInd & cInd <= cBB(2) & ...
                                  tBB(1) <= tInd & tInd <= tBB(2) ;
                
                
                classNames{eInd+1} = strEvent{eInd}.Name;      % name
                classMtrx(:,eInd)  = classVect*eventId;
            end
            
            % check overlap
            if any(sum(classMtrx > 0,2) > 1),
                DTP_ManageText([], sprintf('AutoDetect : Classifiers overlap. Possibly event time marks overlap. Recheck event data'),  'E' ,0);
                return
            end
            % collapse for toolbox representation
            classVect           = sum(classMtrx,2);
            classVect(classVect < 1) = 1; % Mark none
            
            % output
            obj.ClassVect   = classVect;  %
            obj.ClassMtrx   = classMtrx;  % debug
            obj.ClassNames  = classNames;
            
        end
        % ---------------------------------------------
        % ==========================================
        function [obj,strEvent] = ConvertClassToEvent(obj)
            % ConvertClassToEvent - get classifier results and translates it to event structure for one trial
            % Input:
            %   ClassVectEst   - classifier results
            % Output:
            %   strEvent        - cell list of events with classified regions
            
            strEvent            = {};
            
            % take the image data matrix and using bining estimate new position of the events
            [nVect,~]           = size(obj.ClassVectEst);
            if nVect < 1,
                DTP_ManageText([], sprintf('AutoDetect : Run classifier first.'),  'E' ,0);
                return
            end
            % check results
            nClass              = max(obj.ClassVectEst);
            if nClass < 2,
                DTP_ManageText([], sprintf('AutoDetect : Classifier has not detected any valid event.'),  'E' ,0);
                return
            end
            
            % generate indices
            nRBin               = obj.FeatSize(1);
            nCBin               = obj.FeatSize(2);
            nTBin               = obj.FeatSize(3);
            [rInd,cInd,tInd]    = meshgrid(1:nRBin,1:nCBin,1:nTBin);
            [rInd,cInd,tInd]    = deal(rInd(:),cInd(:),tInd(:));
            
            % detrmine different classifier events per time
            classCount          = zeros(nTBin,nClass);
            for ti   = 1:nTBin,
                for ei  = 1:nClass,
                    % classifier reposnses
                    iiBool              = obj.ClassVectEst == ei & tInd == ti;
                    classCount(ti,ei)   = sum(iiBool);
                end
            end
            
            % find events
            eventThr        = 1;   % threshold for counts should be related to image size !!!!
            eventCount      = 1;
            tStart = 0; tEnd = 0; iClass = 0;
            for ti   = 1:nTBin,
                
                % find classifier that has response
                [mv,mi]         = max(classCount(ti,2:nClass));
                
                % check if we need to close an event
                eventClose      = false;
                if mv < eventThr,
                    if tStart > 0 && iClass > 0,
                        tEnd        = ti;
                        eventClose  = true;
                    else
                        tStart = 0; tEnd = 0; iClass = 0;
                    end
                else
                    % check if we need to start an event
                    if tStart < 1 && iClass < 1,
                        tStart  = ti;
                        iClass  = mi + 1;
                    end
                    
                end
                
                % create an event
                if eventClose,
                    
                    % classifier location
                    tStart                = (tStart)*obj.binSize - obj.binSize/2;
                    tEnd                  = (tEnd)*obj.binSize - obj.binSize/2;
                    
                    % create event
                    strEvent{eventCount}.Name    = obj.ClassNames{iClass} ;      % name
                    strEvent{eventCount}.xyInd   = [tStart 100; tEnd 300];
                    strEvent{eventCount}.tInd    = [tStart tEnd];
                    strEvent{eventCount}.zInd    = 1;
                    
                    eventCount                   = eventCount + 1;
                    tStart = 0; tEnd = 0; iClass = 0;
                    
                end
                
                
            end
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = DefineClassifier(obj,classType)
            % DefineClassifier - defines classifier type.
            % Input:
            %   classType - see below all the possible options
            % Output:
            %   obj  - updated
            
            % later we can change this also
            obj.binSize                     = 32;               % histogram related
            obj.nOrient                     = 9;                % hist related
            obj.ClassNum                    = length(obj.EventNameOptions);
            
            
            switch classType,
                case 'Fern',
                case 'Boost',
                otherwise
                    errordlg('Bad Class type specified')
            end
            obj.ClassType = classType;
            DTP_ManageText([], sprintf('AutoDetect : Classifier %s is specified.',obj.ClassType), 'I' ,0);
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = InitClassifier(obj)
            % Train - init classifier.
            % Input:
            %   internal -
            % Output:
            %   FernStr  -
            % init
            %obj.ClassPrm             = struct('S',8,'M',50,'thrr',[0 1],'bayes',1,'ferns', []);
            
            % later we can change this also
            obj.binSize                     = 32;               % histogram related
            obj.nOrient                     = 9;                % hist related
            obj.ClassNum                    = length(obj.EventNameOptions);
            
            % chack max value
            switch obj.FeatType,
                case 'FHOG3D',
                    maxV = 0.2;
                case 'JAABA'
                    maxV = 1;
                otherwise
                    error('Unupported feature type %s',featType)
            end
            
            
            switch obj.ClassType,
                case 'Fern',
                    obj.ClassPrm        = struct('S',16,'M',50,'thrr',[0 maxV],'bayes',1,'ferns', [],'H',16); %obj.ClassNum);
                case 'Boost',
                    obj.ClassPrm        = struct('nWeak',256,'verbose',0,'pTree',struct('maxDepth',5),'model',[]);
                otherwise
                    error('Bad Class type')
            end
            DTP_ManageText([], sprintf('AutoDetect : Classifier %s is intialized.',obj.ClassType), 'I' ,0);
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TrainClassifier(obj)
            % TrainClassifier - train classifier.
            % Input:
            %   FeatMtrx       - data feature matrix
            %   ClassVect      - data class vector with labels from 1 : nEvent+1
            % Output:
            %   ClassPrm.ferns  -  updated
            
            if isempty(obj.ClassVect),
                DTP_ManageText([], sprintf('AutoDetect : Requires input data load first and preprocessing.'), 'E' ,0);
                return
            end
            if isempty(obj.ClassPrm),
                obj = InitClassifier(obj);
            end
            
            % train
            DTP_ManageText([], sprintf('AutoDetect : Training ....'), 'I' ,0);
            
            tic
            switch obj.ClassType,
                case 'Fern',
                    [obj.ClassPrm.ferns,hsPr0]  = fernsClfTrain((obj.FeatMtrx),obj.ClassVect,obj.ClassPrm);
                    %obj.ClassPrm.ferns  = ferns;
                    e0                          = mean(hsPr0~=obj.ClassVect);
                case 'Boost',
                    classPrm            = obj.ClassPrm;
                    for m = 1:obj.ClassNum,
                        model                   = adaBoostTrain( obj.FeatMtrx(obj.ClassVect ~= m,:), obj.FeatMtrx(obj.ClassVect == m,:), classPrm );
                        obj.ClassPrm.model{m}   = model;
                        fp                      = mean(adaBoostApply( obj.FeatMtrx(obj.ClassVect ~= m,:), model )>0);
                        fn                      = mean(adaBoostApply( obj.FeatMtrx(obj.ClassVect == m,:), model )<0);
                        e0                      = (fp+fn)/2;
                    end
                otherwise
                    error('Bad Class type')
            end
            
            DTP_ManageText([], sprintf('AutoDetect : Done in %4.3f [sec]. Training error %4.3f',toc,e0), 'I' ,0);
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestClassifier(obj)
            % TestClassifier - test classifier.
            % Input:
            %   ClassPrm.ferns  -  classifier
            %   FeatMtrx       - data feature matrix
            % Output:
            %   ClassPrm.ferns  -  updated
            
            if isempty(obj.FeatMtrx),
                DTP_ManageText([], sprintf('AutoDetect : Requires input feature matrix to be defined first.'), 'E' ,0);
                return
            end
            % train
            DTP_ManageText([], sprintf('AutoDetect : Testing ....'), 'I' ,0);
            
            tic
            switch obj.ClassType,
                case 'Fern',
                    [hsPr1,cProb]       = fernsClfApply(obj.FeatMtrx,obj.ClassPrm.ferns);
                    obj.ClassVectEst    = hsPr1;
                case 'Boost',
                    classVect           = obj.ClassVect*0;
                    for m = 1:obj.ClassNum,
                        model           = obj.ClassPrm.model{m};
                        classVectTmp    = adaBoostApply( obj.FeatMtrx, model );
                        classVect       = classVect + classVectTmp*m;
                    end
                     obj.ClassVectEst    = classVect;
               otherwise
                    error('Bad Class type')
            end
            
            
            DTP_ManageText([], sprintf('AutoDetect : Done in %4.3f [sec]. ',toc), 'I' ,0);
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = PlayImgData(obj,FigNum)
            % PlayImgData - plays stored video.
            % Input:
            %   internal -
            % Output:
            %   ImgData  -  is played
            if nargin  < 2, FigNum = 1; end;
            
            if isempty(obj.ImgData),
                DTP_ManageText([], sprintf('AutoDetect : requires input data load first.'), 'E' ,0);
                return
            end
            % player plays 3 dim movies
            implay(obj.ImgData)
            
        end
        % ---------------------------------------------
        % ==========================================
        function obj = ShowClassData(obj,FigNum)
            % ShowClassData - shows classifier data.
            % Input:
            %   internal -
            % Output:
            %   FeatMtrx,ClassMtrx  -  is shown
            
            if nargin  < 2, FigNum = 1; end;
            
            if isempty(obj.FeatMtrx),
                DTP_ManageText([], sprintf('AutoDetect : Data Classifer should be called first.'), 'E' ,0);
                return
            end
            if isempty(obj.ClassMtrx),
                DTP_ManageText([], sprintf('AutoDetect : Event conversion should be called first.'), 'E' ,0);
                return
            end
            if ~isequal(size(obj.FeatMtrx,1),size(obj.ClassMtrx,1)),
                DTP_ManageText([], sprintf('AutoDetect : Feat and Class Mtrx missmatch.'), 'E' ,0);
                return
            end
            
            % show
            figure(FigNum)
            imagesc([obj.FeatMtrx obj.ClassMtrx>0]),
            title('Features and Class Data')
            %obj.ClassNames
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = ShowClassResults(obj,FigNum)
            % ShowClassResults - shows classifier results.
            % Input:
            %   internal -
            % Output:
            %   FeatMtrx,ClassVec,ClassVecEst  -  are shown
            
            if nargin  < 2, FigNum = 2; end;
            
            if isempty(obj.FeatMtrx),
                DTP_ManageText([], sprintf('AutoDetect : Data for Classifer should be init first.'), 'E' ,0);
                return
            end
            if isempty(obj.ClassVect),
                DTP_ManageText([], sprintf('AutoDetect : Event conversion should be called first.'), 'E' ,0);
                return
            end
            if isempty(obj.ClassVectEst),
                DTP_ManageText([], sprintf('AutoDetect : Classifier test should be called first.'), 'E' ,0);
                return
            end
            
            % show
            figure(FigNum)
            imagesc([obj.FeatMtrx obj.ClassVect>1 obj.ClassVectEst>1]),
            title('Features, Class Data and Results')
            %obj.ClassNames
            
        end
        % ---------------------------------------------
        
        % ==========================================
        function obj = TestLoadImageData(obj, selType)
            % TestLoadImageData - test image data load
            % from different sources
            
            if nargin < 2, selType = 1; end
            
            % init
            switch selType,
                case 1, % true image data
                    %dataPath        = 'C:\UsersJ\Uri\Data\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_016.avi';
                    dataPath        = 'C:\Uri\DataJ\Janelia\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_016.avi';
                    obj             = LoadImageData(obj, dataPath);
                case 2,
                    %dataPath        = 'C:\UsersJ\Uri\Data\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_016.avi';
                    dataPath        = 'C:\Uri\DataJ\Janelia\Videos\M2\4_4_14\Basler_side_04_04_2014_m2_016.avi';
                    obj             = LoadImageData(obj, dataPath);
                case 11, % using DMB
                    testVideoDir   = 'C:\Uri\DataJ\Janelia\Analysis\m8\02_10_14';
                    testTrial      = 3;
                    
                    dm             = TPA_DataManagerBehavior();
                    dm             = dm.SelectAllData(testVideoDir);
                    [dm, vidData]  = dm.LoadAllData(testTrial);
                    obj            = SetImageData(obj,vidData);
                    obj.DMB        = dm;
                    
                case 21, % synthetic
                    load('mri.mat','D');
                    obj            = SetImageData(obj,D);
                    
                case 22, % synthetic
                    dm             = TPA_MotionCorrectionManager();
                    dm             = dm.GenData(5,5);
                    obj            = SetImageData(obj,dm.ImgData);
                    
                case 31, % true data loaded straighforward
                    dm             = TPA_MotionCorrectionManager();
                    dm             = dm.GenData(13,6);
                    obj            = SetImageData(obj,dm.ImgData);
                    
                case 51, % small region confined to x,y,t
                    imgData        = zeros(80,96,128,'uint16');
                    imgData(30:50,40:56,60:68) = 128;
                    obj.DecimationFactor = [1 1 1];
                    obj            = SetImageData(obj,imgData);
                    
                case 52, % small region confined to x,y,t
                    imgData        = zeros(128,220,128,'uint16');
                    imgData(50:70,100:156,50:78) = 128;
                    imgData(50:70,100:156,60:61) = 0;
                    obj.DecimationFactor = [1 1 1];
                    obj            = SetImageData(obj,imgData);
                    
                    
                otherwise
                    error('Bad selType %d',selType)
            end
            % show
            %obj                     = PlayImgData(obj);
        end
        % ---------------------------------------------
        
        % ==========================================
        function [obj,strEvent] = TestLoadEventData(obj, selType)
            % TestLoadEventData - test event data load
            % selType - should be compatible with TestLoadImageData
            
            if nargin < 2, selType = 1; end
            
            strEvent = {};
            %[nR,nC,nT] = size(obj.ImgData);
            nR = obj.ImgSize(1);
            nC = obj.ImgSize(2);
            nT = obj.ImgSize(3);
            if nT < 2,
                DTP_ManageText([], sprintf('AutoDetect : requires input data load first.'), 'E' ,0);
                return
            end
            
            
            % init
            switch selType,
                case 1, % using True data
                    
                    strEvent{1}.Name    = 'Grab';
                    %strEvent{1}.xyInd   = [11 10;11 nR-10 ;nT-10 nR-10; nT-10 10; 11 10];
                    strEvent{1}.xyInd   = [nT-120 10;nT-120 nR-10 ;nT-60 nR-10; nT-60 10; nT-120 10];
                    
                case 2, % using True data
                    
                    strEvent{1}.Name    = 'Chew';
                    strEvent{1}.xyInd   = [11 10    ;11 nR-10       ;nC-10 nR-10; nC-10 10; 11 10];
                    strEvent{1}.tInd    = [nT-120 10;nT-120 nR-10   ;nT-60 nR-10; nT-60 10; nT-120 10];

                    
                case 11, % using DMB
                    
                    if isempty(obj.DMB),
                        error('Image data along with DMB objects must be loaded first')
                    end
                    [obj.DMB, strEvent]   = obj.DMB.LoadAnalysisData(obj.DMB.Trial,'strEvent');
                    
                case 22, % using MotionCorrection synthetic data
                    
                    strEvent{1}.Name    = 'Grab';
                    strEvent{1}.xyInd   = [11 10;11 nR-10 ;60-10 nR-10; 60-10 10; 11 10];
                    %strEvent{1}.xyInd   = [20 10;20 nR-10 ;60 nR-10; 60 10; 20 10];
                    strEvent{2}.Name    = 'Chew';
                    strEvent{2}.xyInd   = [60 10;60 nR-10 ;68 nR-10; 68 10; 60 10];
                    %strEvent{2}.xyInd   = [40 10;40 nR-10 ;80 nR-10; 80 10; 40 10];
                    
                case 51, % using synthetic data
                    
                    strEvent{1}.Name    = 'Grab';
                    strEvent{1}.xyInd   = [40 30;40 50 ;56 50;56 30;40 30];
                    strEvent{1}.tInd    = [60 68];
                    
                case 52, % using synthetic data
                    
                    strEvent{1}.Name    = 'GrabMiss';
                    strEvent{1}.xyInd   = [100 50;156 70];
                    strEvent{1}.tInd    = [50 78];
                    
                    
                otherwise
                    error('Bad selType %d',selType)
            end
            % show
            %obj                     = PlayImgData(obj);
            
            
        end
        % ---------------------------------------------
        
        
        % ==========================================
        function obj = TestDataPrepare(obj, selType)
            
            % TestDataPrepare - performs image load encoding and event classifier preparation
            if nargin < 2,
                selType                 = 1;  % which data to load
            end
            
            % deal with image
            obj                     = TestLoadImageData(obj, selType);
            obj                     = ConvertImageToFeatures(obj);
            
            % deal with events
            [obj,strEvent]          = TestLoadEventData(obj, selType);
            obj                     = ConvertEventToClass(obj, strEvent);
            
            %show
            obj                     = ShowClassData(obj,1);
            %obj                     = DeleteData(obj);
            
        end
        % ---------------------------------------------
        % ==========================================
        function obj = TestClass3D(obj, selType, classType)
            
            % TestDataPrepare - performs image load encoding and event classifier preparation
            if nargin < 2,
                selType             = 2;  % which data to load
            end
            if nargin < 3,
                 classType          = 'Fern';
            end
            % deal with image
            obj                     = TestLoadImageData(obj, selType);
            obj                     = ConvertImageToFeatures(obj);
            
            % deal with events
            [obj,strEvent]          = TestLoadEventData(obj, selType);
            obj                     = ConvertEvent3DToClass(obj, strEvent);
            
            % train
            obj                     = DefineClassifier(obj,classType);
            obj                     = InitClassifier(obj);
            obj                     = TrainClassifier(obj);
            
            % test and conevert back to events
            obj                     = TestClassifier(obj);
            [obj,strEventEst]       = ConvertClassToEvent(obj);
            
            
            %show
            obj                     = ShowClassData(obj,1);
            obj                     = ShowClassResults(obj,2);
            %obj                     = DeleteData(obj);
            
        end
        % ---------------------------------------------
        
        
        
    end% methods
end% classdef
