classdef TPA_BehaviorTwoPhotonOverlay
    %TPA_BehaviorTwoPhotonOverlay -  overlays Two Photon ROI dF/F data on behavior image data.
    %
    
    %-----------------------------------------------------
    % Ver       Date        Who     What
    %-----------------------------------------------------
    % 2010      28.07.15    UD      Fixing bugs.    
    % 2008      15.07.15    UD      Created.    
    %-----------------------------------------------------
    properties (Constant)
        %MaxFrameNum         = 10000;  % number of frames
    end
    
    properties
        
        % color
        ColorScale          = 50;   % scaling dF/F to video
        
        
        % Average Trajectory
       % TrajectoryData         = [];   % contains trajectory info - average N x 3 array
        
        % diplay for debug
        videoReader
        videoPlayer
        
        % for display only
%         VisiblePoints           = [];
%         NewPoints               = [];
%         LostPoints              = [];
%         PrunePoints             = [];
        VideoSize                       % nR,nC,nD,nT
        VideoOut                    % array that holds nR,nC,3,nT data
        
        % debug
        FigNum                  = 1;   % 0-no debug is shown
        TrialNum                = 0;   % which trial is in use
        
        
    end
    
    methods
        
        
        % ======================================
        function obj = TPA_BehaviorTwoPhotonOverlay()
            % TPA_BehaviorTwoPhotonOverlay - constructor
            % Input:
            %   none
            % Output:
            %   default values
            
            %obj = Initialize(obj);
            
        end
        
        
        % ======================================
        function obj = Initialize(obj)
            % Initialize - % create an empty array of tracks
            % Input:
            %   obj         - default
            % Output:
            %   obj         - updated object
            
        end
        
        
        % ======================================
        function obj = Close(obj)
            %%% Close
            % Stop tracking - release resources
            if ~isempty(obj.videoReader),
                release(obj.videoReader);
            end
            if ~isempty(obj.videoPlayer),
                release(obj.videoPlayer);
            end
        end
        
        
        
        % ======================================
        function obj = InputInit(obj)
            % Initialize Video Input
            % Create objects for reading a video from a file,
            
            % Create a video file reader.
            %obj.videoReader = vision.VideoFileReader('atrium.avi'); % vippedtracking.avi visiontraffic.avi
            %obj.videoReader     = vision.VideoFileReader('visiontraffic.avi'); % vippedtracking.avi visiontraffic.avi
            %objSys.reader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\ZoomIn\OnTable.MP4'); % vippedtracking.avi visiontraffic.avi
            %objSys.reader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\ZoomIn\OnCup.MP4'); % vippedtracking.avi visiontraffic.avi
            %obj.videoReader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\ZoomIn\OnUri.MP4'); % vippedtracking.avi visiontraffic.avi
            %obj.videoReader = vision.VideoFileReader('C:\Projects\Tyto\Data\Video\CamShake\CamShake_Far.avi');

            fname               = 'C:\Uri\DataJ\Janelia\Videos\d10\Basler_side_06_08_2014_d10_015.avi';
            obj.videoReader     = vision.VideoFileReader(fname);
        end
        
        % ======================================
        function obj = ShowInit(obj, figNum)
            % Initialize Video I/O
            if nargin < 2, figNum = 0; end;
            obj.FigNum      = figNum ; 
            obj.TrialNum    = figNum; % trial
            if figNum < 1, return; end;
            
            
            obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 640, 480]);
            
        end
        
        
        % ======================================
        function [obj,videoFrame] = ShowUpdate(obj,videoFrame)
            % ShowUpdate - updates video player
            % Input:
            %   videoFrame - image frame RGB
            % Output:
            %   obj         - updated object
            %   videoFrame - image frame with symbols
            
            % not initialized - no show
            
%             trackIds   =   obj.TrackIds  ;
%             oldPoints  =   obj.OldPoints ;
            
            % make it RGB
            if size(videoFrame,3) < 2,
            videoFrame = repmat(videoFrame(:,:,1),[1 1 3]);
            end
            
%             % Display tracked points
%             videoFrame = insertMarker(videoFrame, obj.VisiblePoints, '+', ...
%                 'Color', 'white');
%             % Display new points
%             videoFrame = insertMarker(videoFrame, obj.NewPoints, 's', ...
%                 'Color', 'green');
%             % Display lost points
%             videoFrame = insertMarker(videoFrame, obj.LostPoints, 'o', ...
%                 'Color', 'c');
%             % Display points that are too close - -to be pruned
%             videoFrame = insertMarker(videoFrame, obj.PrunePoints, 'x', ...
%                 'Color', 'red');
%             
%             
%             % show text Draw the objects on the frame.
%             showTrackIds        = 1:15:trackIds(end);
%             %pointsNum           = size(oldPoints,1);
%             % find matching indexes
%             [~,ids]             = intersect(trackIds,showTrackIds);
%             %ids                 = (1:17:pointsNum);
%             labels              = cellstr(int2str(trackIds(ids)));
%             circPos             = [oldPoints(ids,:) ones(numel(ids),1,'single')*2];
%             videoFrame          = insertObjectAnnotation(videoFrame, 'circle', circPos, labels,'color','y','TextBoxOpacity',0.2);
            
            if isempty(obj.videoPlayer), return; end;
            obj.videoPlayer.step(videoFrame);
        end
        
        % ======================================
        function obj = ShowFinal(obj)
            % Show movie at the end
            if isempty(obj.VideoOut), return; end
            h = implay(obj.VideoOut);
            %f = get(h.Parent);
            %f.Name = sprintf('Trial %d',obj.TrialNum);
        end
        
        
        % ======================================
        function obj = Overlay(obj,viewType)
            % Overlay - shows side by side two photon data over behavioral image data
            % Assumes it is global
            if nargin < 2, viewType = 'side'; end;
            
            global SData 
            
            % use only side info
            sId         = find(strcmp({'side','front'},viewType));
            if isempty(sId),error('viewType must be side or front'); end;
            
            % check
            [nR,nC,nD,nT] = size(SData.imBehaive);
            vClass        = class(SData.imBehaive);
            obj.VideoSize = size(SData.imBehaive); % for display
            if nT < 2, 
                DTP_ManageText([], sprintf('Overlay : Please load beahvior image data first.'), 'W' ,0)   ;             
                return; 
            end;
            
            % check two photon data
            roiNum        = length(SData.strROI);
            if roiNum < 1,
                DTP_ManageText([], sprintf('Overlay : Please load Two Photon ROI data.'), 'E' ,0)   ;             
                return; 
            end
            % check dF/F
            tpFrameNum = size(SData.strROI{1}.procROI,1);
            if tpFrameNum < 10,
                DTP_ManageText([], sprintf('Overlay : Two Photon ROI data does not contain valid dF/F info. Please fix it.'), 'E' ,0)   ;             
                return; 
            end
            % check frame number compatability
            decimFact = 6;
            if (nT == tpFrameNum*6),
                DTP_ManageText([], sprintf('Overlay : Behavior data has %d frames, Two Photon %d frames : OK.',nT,tpFrameNum), 'I' ,0)   ;             
            elseif (nT == tpFrameNum*18),
                DTP_ManageText([], sprintf('Overlay : Behavior data has %d frames, Two Photon %d frames and 3 stacks : OK.',nT,tpFrameNum), 'I' ,0)   ;             
                decimFact = 18;
            else
                DTP_ManageText([], sprintf('Overlay : Behavior data has %d frames, Two Photon %d frames : Incopmatible.',nT,tpFrameNum), 'W' ,0)   ;             
                DTP_ManageText([], sprintf('Overlay : Continuing : Results could be inaccurate.'), 'W' ,0)   ;             
                %return; 
            end   
            
            % assume Two Photon image data 512 x 512
            DTP_ManageText([], sprintf('Overlay : Assuming Two Photon frame size is 512 x 512.'), 'W' ,0) ; 
            nImR         = 512;
            nImC         = 512;
            meanData     = zeros(nT,roiNum);
            dffData      = zeros(nT,roiNum);
            vidInd       = (1:nT)';
            imgInd       = round(linspace(1,nT,tpFrameNum))'; %(1:decimFact:nT)'+ decimFact/2;
            % collect and interpolate dF/F data
            for m = 1:roiNum,
                
                dffRoi = SData.strROI{m}.procROI;
                if size(dffRoi,1) ~= tpFrameNum,
                    DTP_ManageText([], sprintf('Overlay : ROI %s does not have any dFF data.',SData.strROI{m}.Name), 'W' ,0);          ;
                    continue;
                end
                
                dffRoiInt       = interp1(imgInd,dffRoi,vidInd,'pchip');
                dffData(:,m)    = dffRoiInt;
                
                meanRoi         = SData.strROI{m}.meanROI;
                meanRoiInt      = interp1(imgInd,meanRoi,vidInd,'pchip');
                meanData(:,m)   = meanRoiInt;
                
            end
            % show
            figure(obj.FigNum + 300),set(gcf,'Tag','AnalysisROI','Name',sprintf('Trial %d',obj.TrialNum));%clf;colordef(gcf,'none')
            imagesc(meanData')
            ylabel('Cells'),xlabel('Interpolated Time [frames]');title(sprintf('Mean Fluorescence Trial %d',obj.TrialNum))
            figure(obj.FigNum + 400),set(gcf,'Tag','AnalysisROI','Name',sprintf('Trial %d',obj.TrialNum));%clf;colordef(gcf,'none')
            imagesc(dffData')
            ylabel('Cells'),xlabel('Interpolated Time [frames]');title(sprintf('Dff for Trial %d',obj.TrialNum))
            
            % init IO
            %obj         = InputInit(obj);
            %obj         = ShowInit(obj,1);
            
            % init Tracker
            videoFrame      = SData.imBehaive(:,:,sId,1);
            resizeFact      = nR./nImR;
            imgFrame        = zeros(nImR,nImC,'like',videoFrame);
            imgFrameResized = imresize(imgFrame,resizeFact);
            [nRResized,nCResized] = size(imgFrameResized);
            obj.VideoOut    = zeros(nR,nC+nCResized,1,nT,'like',videoFrame);
            % Detect moving objects, and track them across video frames.
            DTP_ManageText([], sprintf('Behavior : Start Embedding ...'), 'I' ,0) ;
            for  n = 1:nT,
                
                % get frame
                videoFrame       = SData.imBehaive(:,:,sId,n);
                
                % create empty
                imgFrame        = zeros(nImR,nImC,'like',videoFrame);
                                
                % step
                for m = 1:roiNum,
                    ind             = SData.strROI{m}.Ind;
                    dff2clr         = dffData(n,m)^3;
                    clrs            = cast(dff2clr*obj.ColorScale,'like',videoFrame);
                    imgFrame(ind)   = clrs;
                end
                
                % resize to insert
                imgFrameResized     = imresize(imgFrame,resizeFact);
                %videoFrame(1:embedSize,nC-embedSize+1:nC) = imgFrameResized;
                videoFrame          = cat(2,videoFrame,imgFrameResized);
                
                % return back
                obj.VideoOut(:,:,1,n)        = videoFrame;
                
                % show
                obj             = ShowUpdate(obj,videoFrame);

                
            end
            DTP_ManageText([], sprintf('Behavior : Done.'), 'I' ,0) ;
            
            
        end
       
        % ======================================
        function obj = OverlayColor(obj,viewType)
            % OverlayColor - shows side by side two photon data over behavioral image data
            % Assumes video input is global
            % Inserts numbers
            if nargin < 2, viewType = 'side'; end;
            
            global SData 
            
            % use only side info
            sId         = find(strcmp({'side','front'},viewType));
            if isempty(sId),error('viewType must be side or front'); end;
            
            % check
            [nR,nC,nD,nT] = size(SData.imBehaive);
            vClass        = class(SData.imBehaive);
            obj.VideoSize = size(SData.imBehaive); % for display
            if nT < 2, 
                DTP_ManageText([], sprintf('Overlay : Please load beahvior image data first.'), 'W' ,0)   ;             
                return; 
            end;
            
            % check two photon data
            roiNum        = length(SData.strROI);
            if roiNum < 1,
                DTP_ManageText([], sprintf('Overlay : Please load Two Photon ROI data.'), 'E' ,0)   ;             
                return; 
            end
            % check dF/F
            tpFrameNum = size(SData.strROI{1}.procROI,1);
            if tpFrameNum < 10,
                DTP_ManageText([], sprintf('Overlay : Two Photon ROI data does not contain valid dF/F info. Please fix it.'), 'E' ,0)   ;             
                return; 
            end
            % check frame number compatability
            decimFact = 6;
            if (nT == tpFrameNum*6),
                DTP_ManageText([], sprintf('Overlay : Behavior data has %d frames, Two Photon %d frames : OK.',nT,tpFrameNum), 'I' ,0)   ;             
            elseif (nT == tpFrameNum*18),
                DTP_ManageText([], sprintf('Overlay : Behavior data has %d frames, Two Photon %d frames and 3 stacks : OK.',nT,tpFrameNum), 'I' ,0)   ;             
                decimFact = 18;
            else
                DTP_ManageText([], sprintf('Overlay : Behavior data has %d frames, Two Photon %d frames : Incopmatible.',nT,tpFrameNum), 'W' ,0)   ;             
                DTP_ManageText([], sprintf('Overlay : Continuing : Results could be inaccurate.'), 'W' ,0)   ;             
                %return; 
            end   
            
            % assume Two Photon image data 512 x 512
            DTP_ManageText([], sprintf('Overlay : Assuming Two Photon frame size is 512 x 512.'), 'W' ,0) ; 
            nImR         = 512;
            nImC         = 512;
            meanData     = zeros(nT,roiNum);
            dffData      = zeros(nT,roiNum);
            vidInd       = (1:nT)';
            imgInd       = round(linspace(1,nT,tpFrameNum))'; %(1:decimFact:nT)'+ decimFact/2;
            % collect and interpolate dF/F data
            for m = 1:roiNum,
                
                dffRoi = SData.strROI{m}.procROI;
                if size(dffRoi,1) ~= tpFrameNum,
                    DTP_ManageText([], sprintf('Overlay : ROI %s does not have any dFF data.',SData.strROI{m}.Name), 'W' ,0);          ;
                    continue;
                end
                
                dffRoiInt       = interp1(imgInd,dffRoi,vidInd,'pchip');
                dffData(:,m)    = dffRoiInt;
                
                meanRoi         = SData.strROI{m}.meanROI;
                meanRoiInt      = interp1(imgInd,meanRoi,vidInd,'pchip');
                meanData(:,m)   = meanRoiInt;
                
            end
            % show
            figure(obj.FigNum + 300),set(gcf,'Tag','AnalysisROI','Name',sprintf('Trial %d',obj.TrialNum));%clf;colordef(gcf,'none')
            imagesc(meanData')
            ylabel('Cells'),xlabel('Interpolated Time [frames]');title(sprintf('Mean Fluorescence Trial %d',obj.TrialNum))
            figure(obj.FigNum + 400),set(gcf,'Tag','AnalysisROI','Name',sprintf('Trial %d',obj.TrialNum));%clf;colordef(gcf,'none')
            imagesc(dffData',[0 4])
            ylabel('Cells'),xlabel('Interpolated Time [frames]');title(sprintf('Dff for Trial %d',obj.TrialNum))
            impixelinfo;
            
            % init IO
            %obj         = InputInit(obj);
            %obj         = ShowInit(obj,1);
            
            % init Tracker
            videoFrame      = SData.imBehaive(:,:,sId,1);
            resizeFact      = nR./nImR;
            imgFrame        = zeros(nImR,nImC,'like',videoFrame);
            imgFrameResized = imresize(imgFrame,resizeFact);
            [nRResized,nCResized] = size(imgFrameResized);
            obj.VideoOut    = zeros(nR,nC+nCResized,3,nT,'like',videoFrame);
            
            % prepare for text embedding
            text_pos        = zeros(roiNum,2);
            for m = 1:roiNum,
                text_pos(m,:)  = mean(SData.strROI{m}.xyInd);
            end
            text_str        = (1:roiNum)';
            
            % Detect moving objects, and track them across video frames.
            DTP_ManageText([], sprintf('Behavior : Start Embedding ...'), 'I' ,0) ;
            for  n = 1:nT,
                
                % get frame
                videoFrame       = SData.imBehaive(:,:,sId,n);
                
                % create empty
                imgFrame        = zeros(nImR,nImC,'like',videoFrame);
                                
                % step
                vind                = false(roiNum,1); % do not show silent rois
                for m = 1:roiNum,
                    ind             = SData.strROI{m}.Ind;
                    %dff2clr         = dffData(n,m)^2;
                    dff2clr         = dffData(n,m) > 1; % Liora
                    clrs            = cast(dff2clr*obj.ColorScale*2,'like',videoFrame);
                    imgFrame(ind)   = clrs;
                    vind(m)         = dff2clr;
                end
                
                % insert cell number annotation
                if any(vind),
                imgFrameRGB          = insertText(imgFrame,text_pos(vind,:),text_str(vind),'FontSize',10,'TextColor','m','BoxColor','y','BoxOpacity',0);
                else
                imgFrameRGB          = insertText(imgFrame,[10 10],'No Cell Found','FontSize',20,'TextColor','m','BoxColor','y','BoxOpacity',0);                    
                end
                vidFrameRGB          = insertText(videoFrame,[5 5],sprintf('T:%2d,F:%4d',obj.TrialNum,n),'FontSize',18,'BoxColor','y','BoxOpacity',0.3);
                
                
                % resize to insert
                imgFrameResized     = imresize(imgFrameRGB,resizeFact);
                %videoFrame(1:embedSize,nC-embedSize+1:nC) = imgFrameResized;
                videoFrame          = cat(2,vidFrameRGB,imgFrameResized);
                
                % return back
                obj.VideoOut(:,:,:,n)        = videoFrame;
                
                % show
                obj             = ShowUpdate(obj,videoFrame);

                
            end
            DTP_ManageText([], sprintf('Behavior : Done.'), 'I' ,0) ;
            
            
        end
        
        
        % ======================================
        function obj = OverlayEmbed(obj,viewType)
            % Overlay - implants two photon data over behavioral image data
            % Assumes it is global
            if nargin < 2, viewType = 'side'; end;
            
            global SData
            
            % use only side info
            sId         = find(strcmp({'side','front'},viewType));
            if isempty(sId),error('viewType must be side or front'); end;
            
            % check
            [nR,nC,nD,nT] = size(SData.imBehaive);
            vClass        = class(SData.imBehaive);
            obj.VideoSize = size(SData.imBehaive); % for display
            if nT < 2, 
                DTP_ManageText([], sprintf('Overlay : Please load beahvior image data first.'), 'W' ,0)   ;             
                return; 
            end;
            
            % check two photon data
            roiNum        = length(SData.strROI);
            if roiNum < 1,
                DTP_ManageText([], sprintf('Overlay : Please load Two Photon ROI data.'), 'E' ,0)   ;             
                return; 
            end
            % check dF/F
            tpFrameNum = size(SData.strROI{1}.procROI,1);
            if tpFrameNum < 10,
                DTP_ManageText([], sprintf('Overlay : Two Photon ROI data does not contain valid dF/F info. Please fix it.'), 'E' ,0)   ;             
                return; 
            end
            % check frame number compatability
            decimFact = 6;
            if (nT == tpFrameNum*6),
                DTP_ManageText([], sprintf('Overlay : Behavior data has %d frames, Two Photon %d frames : OK.',nT,tpFrameNum), 'I' ,0)   ;             
            elseif (nT == tpFrameNum*18),
                DTP_ManageText([], sprintf('Overlay : Behavior data has %d frames, Two Photon %d frames and 3 stacks : OK.',nT,tpFrameNum), 'I' ,0)   ;             
                decimFact = 18;
            else
                DTP_ManageText([], sprintf('Overlay : Behavior data has %d frames, Two Photon %d frames : Incopmatible.',nT,tpFrameNum), 'E' ,0)   ;             
                return; 
            end   
            
            % assume Two Photon image data 512 x 512
            DTP_ManageText([], sprintf('Overlay : Assuming Two Photon frame size is 512 x 512.'), 'W' ,0) ; 
            nImR         = 512;
            nImC         = 512;
            dffData      = zeros(nT,roiNum);
            vidInd       = (1:nT)';
            imgInd       = (1:decimFact:nT)'+ decimFact/2;
            % collect and interpolate dF/F data
            for m = 1:roiNum,
                
                dffRoi = SData.strROI{m}.procROI;
                if size(dffRoi,1) ~= tpFrameNum,
                    DTP_ManageText([], sprintf('Overlay : ROI %s does not have any dFF data.',SData.strROI{m}.Name), 'W' ,0);          ;
                    continue;
                end
                
                dffRoiInt       = interp1(imgInd,dffRoi,vidInd,'pchip');
                dffData(:,m)    = dffRoiInt;
                
            end
            
            
            % init IO
            %obj         = InputInit(obj);
            %obj         = ShowInit(obj,1);
            
            % init Tracker
            videoFrame      = SData.imBehaive(:,:,sId,1);
            obj.VideoOut    = zeros(nR,nC,1,nT,'like',videoFrame);
            embedSize       = ceil(nC/3);
            
            % Detect moving objects, and track them across video frames.
            DTP_ManageText([], sprintf('Behavior : Start Embedding ...'), 'I' ,0) ;
            for  n = 1:nT,
                
                % get frame
                videoFrame       = SData.imBehaive(:,:,sId,n);
                
                % create empty
                imgFrame        = zeros(nImR,nImC,'like',videoFrame);
                                
                % step
                for m = 1:roiNum,
                    ind             = SData.strROI{m}.Ind;
                    clr             = cast(dffData(n,m)*obj.ColorScale,'like',videoFrame);
                    imgFrame(ind)   = clr;
                end
                
                % resize to insert
                imgFrameResized     = imresize(imgFrame,[embedSize embedSize]);
                videoFrame(1:embedSize,nC-embedSize+1:nC) = imgFrameResized;
                
                % return back
                obj.VideoOut(:,:,1,n)        = videoFrame;
                
                % show
                obj             = ShowUpdate(obj,videoFrame);

                
            end
            DTP_ManageText([], sprintf('Behavior : Done.'), 'I' ,0) ;
            
            
        end
        
        
        % ======================================
        function obj = TestOverlay(obj)
            % Test system 
            
            
        end
        
        
        
    end % methods
end % class


