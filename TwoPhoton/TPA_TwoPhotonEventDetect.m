classdef TPA_TwoPhotonEventDetect < handle
    % TPA_TwoPhotonEventDetect - detects events/spikes on dF/F data
    % Make only one over entire project.
    % Inputs:
    %       DffData - N x roiNum - dF/F traces
    % Outputs:
    %       DffData - N x roiNum - dF/F detected events
    
    %-----------------------------
    % Ver	Date	 Who	Descr
    %-----------------------------
    % 25.08 23.04.17 UD     Adding manual event 
    % 25.07 18.04.17 UD     Improving fast
    % 25.06 09.04.17 UD     Slow event detection
    % 23.03 15.02.16 UD     Update all df/f traces
    % 21.22 29.12.15 UD     Improving filter - not in seconds
    % 21.07 13.10.15 UD     Adding result show
    % 21.06 10.10.15 UD     Created
    %-----------------------------
    
    
    properties
        
        DeconvType              = 1;       % type of deconvolution to use
        %SmoothFiltDur           = .1;       % smoothing filter (N.A. in Fast Rise)
        DeconvFiltDur           = .2;       % smoothing filter duration in sec
        DeconvFiltTau           = .2;       % filter slope in 1/sec (N.A. in Fast Rise)
        DeconvFiltRiseTime      = .2;       % rise time in dF/F for peak detection
        DeconvFiltRiseAmp       = .2;       % rise value Max-Min in dF/F for peak detection
        DeconvRespMinWidth      = .1;       % min cell response dF/F duration in sec
        DeconvRespMaxWidth      = 2;        % max cell response dF/F duration in sec
        ImageSampleTime         = 1/30;     % sampling time per line in sec
        
        % intermediate results
        ImgDataCol              = [];
        ImgDataFilt             = [];
        ImgDffSpike              = [];
        
        % GUI support
        FigHandle2              = [];
        FigHandle3              = [];
        
        
    end % properties
    
    methods
        
        % ==========================================
        function obj = TPA_TwoPhotonEventDetect()
            % TPA_TwoPhotonEventDetect - constructor
            % Input:
            %   none
            % Output:
            %     default values
            
            % init algorithm objams
            obj = Init(obj);
            
        end
        
        % ==========================================
        function obj = Init(obj)
            % init local objams
            
            %%%%%%%%%%%%%%%%%%%%%%
            % Deconvolution - spike finder
            %%%%%%%%%%%%%%%%%%%%%%
            obj.DeconvType              = 1;       % type of deconvolution to use
            obj.DeconvFiltTau           = .8;       % filter slope in 1/sec (N.A. in Fast Rise)
            obj.DeconvFiltDur           = .2;       % smoothing filter duration in sec
            obj.DeconvFiltRiseTime      = .1;       % rise time in dF/F for peak detection
            obj.DeconvFiltRiseAmp       = .2;       % rise value Max-Min in dF/F for peak detection
            obj.DeconvRespMinWidth      = .2;       % min cell response dF/F duration in sec
            obj.DeconvRespMaxWidth      = 2;        % max cell response dF/F duration in sec
            obj.ImageSampleTime         = 1/30;   % sampling time per line in sec
        end
        
        
        % ==========================================
        function [obj,isOK] = SetDeconvolutionParams(obj,FigNum)
            % SetDeconvolutionParams - set objams for deconvolution filter
            % Inputs:
            %   obj         - control structure
            %
            % Outputs:
            %   obj         - control structure updated
            
            if nargin < 2, FigNum = 145; end
            isOK = false;
            
            
            prompt          = { 
                'Deconvolution Alg Type - N.A. :',...
                'Calcium Response Tau [sec]:',...
                'Calcium Response Duration [sec]:',...
                'Max Rise Time [sec]:',...
                'Min Rise Amplitude [dF/F]:',...
                'Min Response Width/Time [sec]:',...
                'Max Response Width/Time [sec]:',...
                'Image Sampling Period [sec]:',...
                };
            defaultanswer   =  {...
                num2str(obj.DeconvType),...
                num2str(obj.DeconvFiltTau),...
                num2str(obj.DeconvFiltDur),...
                num2str(obj.DeconvFiltRiseTime),...       % rise time in dF/F for peak detection
                num2str(obj.DeconvFiltRiseAmp),...        % rise value Max-Min in dF/F for peak detection
                num2str(obj.DeconvRespMinWidth),...       % min response duration
                num2str(obj.DeconvRespMaxWidth),...       % max response duration
                num2str(obj.ImageSampleTime),...          % sampling time
                };
            name            = 'Set Spike Detector Parameters';
            numlines        = 1;
            
            options.Resize      = 'on';
            options.WindowStyle = 'modal';
            options.Interpreter = 'none';
            
            % user input required
            answer          = inputdlg(prompt,name,numlines,defaultanswer,options);
            
            % check
            if isempty(answer), return; end % cancel
            
            % else
            obj.DeconvType          = str2num(answer{1});
            obj.DeconvFiltTau       = str2num(answer{2});
            obj.DeconvFiltDur       = str2num(answer{3});
            obj.DeconvFiltRiseTime  = str2num(answer{4});
            obj.DeconvFiltRiseAmp   = str2num(answer{5});
            obj.DeconvRespMinWidth  = str2num(answer{6});
            obj.DeconvRespMaxWidth  = str2num(answer{7});
            obj.ImageSampleTime     = str2num(answer{8});
            
            isOK = true;
            DTP_ManageText([], sprintf('TwoPhoton : Deconvolution filter is updated'),  'I' ,0);
            
            %obj = ShowFilter(obj,FigNum);
        end
        
        % ==========================================
        function [obj,DffData] = FastEventDetect(obj,DffData,FigNum)
            % FastEventDetect - performs spike extraction from ROI dF/F data
            % using local fast transition from low to high
            % Inputs:
            %   obj         - control structure
            %   DffData      - nTime x nRoi value at each ROI line
            %
            % Outputs:
            %   obj         - control structure updated
            %   DffData      - nTime x nRoi spikes
            
            
            if nargin < 2, DffData = rand(360,4); end;
            if nargin < 3, FigNum = 1; end;
            
            
            % check for multiple Z ROIs
            numROI          = size(DffData,2);
            if numROI < 1,
                errordlg('Reuires ROI structure to be loaded / defined')
                return
            end
            % check that processing is in place
            nR              = size(DffData,1);
            if nR < 1,
                errordlg('Reuires ROI structure to be processed with dF/F')
                return
            end
            imgDataFilt     = zeros(nR,numROI);
            imgDataCol      = zeros(nR,numROI);
            
            %%%%%
            % Define Filter
            %%%%%
            sampFreq        = 1/obj.ImageSampleTime;
            filtDur         = obj.DeconvFiltDur * sampFreq;      % filter duration in sec
            %filtTau     = obj.DeconvFiltTau * sampFreq;     % filter slope in 1/sec
            filtLenH        = ceil(filtDur/2);
            filtLen         = filtLenH*2;
            
            % preobje for deconvolution - freq domain
            %filtSmooth  = ones(filtLen,1);
            filtSmooth          = hamming(filtLen);
            %filtSmooth  = gausswin(filtLen);
            filtSmooth          = filtSmooth./sum(filtSmooth);
            
            % additional objams
            MaxMinThr           = obj.DeconvFiltRiseAmp;  % determine the difference in rize time
            %MinSpikeWidth       = ceil(filtTau);     % samples for average spike
            ArtifactTime        = 2;    % samples in the initial time to remove spikes
            SupWinSize          = ceil(obj.DeconvFiltRiseTime * sampFreq);
            respMinWidth        = ceil(obj.DeconvRespMinWidth * sampFreq); % minimal width
            respMaxWidth        = ceil(obj.DeconvRespMaxWidth * sampFreq); % max width
            
            
            %%%%%
            % Process one by one
            %%%%%
            
            for k = 1:numROI,
                
                % Processing works on columns
                traceSig            = DffData(:,k);
                
                % smooth
                dFFFilt             = filtfilt(filtSmooth,1,traceSig);
                
                % prepare for transition
%                dFFMinFix           = [zeros(SupWinSize-1,1)+10;  dFFFilt(1:end-SupWinSize+1) ];
%                 dFFMaxFix           = [dFFFilt(SupWinSize:end); zeros(SupWinSize-1,1)+0 ];
                dFFMinFix           = dFFFilt;
                dFFMaxFix           = dFFFilt*0;%[dFFFilt(SupWinSize:end); zeros(SupWinSize-1,1)+0 ];
                for n = 1:nR-SupWinSize,
                    dFFMaxFix(n) = max(dFFFilt(n:n+SupWinSize-1));
                end
                
                % find places with bif difference betwen min and max
                dMaxMin             = dFFMaxFix - dFFMinFix;
                dMaxMin(1:ArtifactTime) = 0;  % if any artifact
                dMaxMinInd          = find(dMaxMin > MaxMinThr & [dMaxMin(2:end); 0] < dMaxMin & dMaxMin >= [10; dMaxMin(1:end-1)]);
                
                % determine width of the response
                s_num       = numel(dMaxMinInd);
                SpikeArea   = zeros(s_num,1); % contains response width
                SpikeWidth  = zeros(s_num,1); % contains response width
                SpikeHeight = zeros(s_num,1); % contains response width
                for s = 1:s_num,
                    first_point  = dMaxMinInd(s);
                    last_point   = min(nR,first_point + 1); %min(nR,first_point + MinSpikeWidth);
                    if s == s_num,
                        lastPos      = nR;
                    else
                        lastPos      = min(nR,dMaxMinInd(s+1) - 3);  % go to the next rise. small gap
                    end
                    localThr    = dFFFilt(first_point)*1.00; % max(dFFFilt(lastPos),dFFFilt(first_point))*1.1;
                    while dFFFilt(last_point) >= localThr && last_point < lastPos,
                        last_point = last_point + 1;
                    end;
                    
                    
                    % record only above minimal width
                    currWidth       = (last_point - first_point);
                    if currWidth >= respMinWidth && currWidth < respMaxWidth,
                        SpikeHeight(s) = max(dFFFilt(first_point:last_point)) - dFFFilt(first_point);
                        SpikeArea(s)   = sum(dFFFilt(first_point:last_point) - dFFFilt(first_point)) ; % resolves when signal below 0
                        SpikeWidth(s)  = currWidth;
                    end
                end;
                
                
                
                % create spike train
                SpikeTrain  = dFFFilt*0;
                for s = 1:s_num,
                    SpikeTrain(dMaxMinInd(s):dMaxMinInd(s)+SpikeWidth(s)) = SpikeHeight(s)*1;
                end;
                SpikeTrain              = SpikeTrain(1:nR);
                
                % valid spikes
                %validInd                = find(SpikeWidth > 1);
                
                
                % save
                imgDataCol(:,k)         = DffData(:,k); % save for test
                imgDataFilt(:,k)        = dFFFilt ;     % filtered
                DffData(:,k)            = SpikeTrain;   % detected
                
            end;
            
            obj.ImgDataCol  = imgDataCol;
            obj.ImgDataFilt = imgDataFilt;
            obj.ImgDffSpike = DffData;
            
            % output
            %DTP_ManageText([], sprintf('TwoPhoton : Spike Decoding of dF/F ROI is computed'),  'I' ,0)
        end
        
        % ==========================================
        function [obj,DffData] = SlowEventDetect(obj,DffData,FigNum)
            % SlowEventDetect - performs spike extraction from ROI dF/F data
            % using local fast transition from low to high
            % Inputs:
            %   obj         - control structure
            %   DffData      - nTime x nRoi value at each ROI line
            %
            % Outputs:
            %   obj         - control structure updated
            %   DffData      - nTime x nRoi spikes
            
            
            if nargin < 2, DffData = rand(360,4); end;
            if nargin < 3, FigNum = 1; end;
            
            
            % check for multiple Z ROIs
            numROI          = size(DffData,2);
            if numROI < 1,
                errordlg('Reuires ROI structure to be loaded / defined')
                return
            end
            % check that processing is in place
            nR              = size(DffData,1);
            if nR < 51,
                errordlg('Reuires ROI structure to be processed with dF/F')
                return
            end
                
            alpha               = obj.DeconvFiltTau;
            
            %Par                 = [];
            for k = 1:numROI,

                dffData             = DffData(:,k);  

                % remove trend
                startData           = repmat(mean(dffData(1:15)),100,1);
                dffDataAv           = filtfilt((1-alpha),[1 -alpha],[startData;dffData]);
                dffDataAv           = dffDataAv(101:end,:);  
                
%                 % make it discrete
%                 %dffDataAv           = round(dffDataAv*1000);
%                 
                % estimate noise distribution on X lowest values
                dffDataSort         = sort(dffDataAv);
                dffNoise            = dffDataSort(120);%:50);
%                 dffNoise(dffNoise < eps) = eps;
%                 pf                  = fitdist(dffNoise,'Poisson');
%                 %ci                  = paramci(pf,'Alpha',.00001);
%                 dffSpike            = pdf(pf,dffDataAv);% dffDataAv > ci(2); %pdf(pf,dffDataAv);
                %dffSpike            = dffDataAv./(eps+mean(dffNoise));
                dffSpike            = dffDataAv > dffNoise;

                % save
                DffData(:,k)        = double(dffSpike);

            end
            obj.ImgDffSpike = DffData;
            
            % output
            %DTP_ManageText([], sprintf('TwoPhoton : Spike Decoding of dF/F ROI is computed'),  'I' ,0)
        end
        
        % ==========================================
        function [obj,DffData] = ManualEventDetect(obj,DffData,FigNum)
            % ManualEventDetect - performs spike extraction from ROI dF/F data
            % using only threshold
            % Inputs:
            %   obj         - control structure
            %   DffData      - nTime x nRoi value at each ROI line
            %
            % Outputs:
            %   obj         - control structure updated
            %   DffData      - nTime x nRoi spikes
            
            
            if nargin < 2, DffData = rand(360,4); end;
            if nargin < 3, FigNum = 1; end;
            
            
            % check for multiple Z ROIs
            numROI          = size(DffData,2);
            if numROI < 1,
                errordlg('Reuires ROI structure to be loaded / defined')
                return
            end
            % check that processing is in place
            nR              = size(DffData,1);
            if nR < 1,
                errordlg('Reuires ROI structure to be processed with dF/F')
                return
            end
            imgDataFilt     = zeros(nR,numROI);
            imgDataCol      = zeros(nR,numROI);
            
            %%%%%
            % Define Filter
            %%%%%
            sampFreq        = 1/obj.ImageSampleTime;
            filtDur         = obj.DeconvFiltDur * sampFreq;      % filter duration in sec
            %filtTau     = obj.DeconvFiltTau * sampFreq;     % filter slope in 1/sec
            filtLenH        = ceil(filtDur/2);
            filtLen         = filtLenH*2;
            
            % preobje for deconvolution - freq domain
            %filtSmooth  = ones(filtLen,1);
            filtSmooth          = hamming(filtLen);
            %filtSmooth  = gausswin(filtLen);
            filtSmooth          = filtSmooth./sum(filtSmooth);
            
            % additional objams
            MaxMinThr           = obj.DeconvFiltRiseAmp;  % determine the difference in rize time
            %MinSpikeWidth       = ceil(filtTau);     % samples for average spike
            ArtifactTime        = 2;    % samples in the initial time to remove spikes
            SupWinSize          = ceil(obj.DeconvFiltRiseTime * sampFreq);
            respMinWidth        = ceil(obj.DeconvRespMinWidth * sampFreq); % minimal width
            respMaxWidth        = ceil(obj.DeconvRespMaxWidth * sampFreq); % max width
            
            
            %%%%%
            % Process one by one
            %%%%%
            
            for k = 1:numROI,
                
                % Processing works on columns
                traceSig            = DffData(:,k);
                
                % smooth
                dFFFilt             = filtfilt(filtSmooth,1,traceSig);
                
                % prepare for transition
%                dFFMinFix           = [zeros(SupWinSize-1,1)+10;  dFFFilt(1:end-SupWinSize+1) ];
%                 dFFMaxFix           = [dFFFilt(SupWinSize:end); zeros(SupWinSize-1,1)+0 ];
%                 dFFMinFix           = dFFFilt;
%                 dFFMaxFix           = dFFFilt*0;%[dFFFilt(SupWinSize:end); zeros(SupWinSize-1,1)+0 ];
%                 for n = 1:nR-SupWinSize,
%                     dFFMaxFix(n) = max(dFFFilt(n:n+SupWinSize-1));
%                 end
                
                % find places with bif difference betwen min and max
                dMaxMin             = dFFFilt; %dFFMaxFix - dFFMinFix;
                dMaxMin(1:ArtifactTime) = 0;  % if any artifact
                dMaxMinBool         = dMaxMin > MaxMinThr;
                %dMaxMinInd          = find(dMaxMin > MaxMinThr & [dMaxMin(2:end); 0] < dMaxMin & dMaxMin >= [10; dMaxMin(1:end-1)]);
                dMaxMinInd          = find(~dMaxMinBool(1:end-1) & dMaxMinBool(2:end));
                
                % determine width of the response
                s_num       = numel(dMaxMinInd);
                SpikeArea   = zeros(s_num,1); % contains response width
                SpikeWidth  = zeros(s_num,1); % contains response width
                SpikeHeight = zeros(s_num,1); % contains response width
                for s = 1:s_num,
                    first_point  = dMaxMinInd(s);
                    last_point   = min(nR,first_point + 1); %min(nR,first_point + MinSpikeWidth);
                    if s == s_num,
                        lastPos      = nR;
                    else
                        lastPos      = min(nR,dMaxMinInd(s+1) - 3);  % go to the next rise. small gap
                    end
                    localThr    = MaxMinThr; %dFFFilt(first_point)*1.00; % max(dFFFilt(lastPos),dFFFilt(first_point))*1.1;
                    while dFFFilt(last_point) >= localThr && last_point < lastPos,
                        last_point = last_point + 1;
                    end;
                    
                    
                    % record only above minimal width
                    currWidth       = (last_point - first_point);
                    if currWidth >= respMinWidth && currWidth < respMaxWidth,
                        SpikeHeight(s) = max(dFFFilt(first_point:last_point)) - dFFFilt(first_point);
                        SpikeArea(s)   = sum(dFFFilt(first_point:last_point) - dFFFilt(first_point)) ; % resolves when signal below 0
                        SpikeWidth(s)  = currWidth;
                    end
                end;
                
                
                
                % create spike train
                SpikeTrain  = dFFFilt*0;
                for s = 1:s_num,
                    SpikeTrain(dMaxMinInd(s):dMaxMinInd(s)+SpikeWidth(s)) = SpikeHeight(s)*1;
                end;
                SpikeTrain              = SpikeTrain(1:nR);
                
                % valid spikes
                %validInd                = find(SpikeWidth > 1);
                
                
                % save
                imgDataCol(:,k)         = DffData(:,k); % save for test
                imgDataFilt(:,k)        = dFFFilt ;     % filtered
                DffData(:,k)            = SpikeTrain;   % detected
                
            end;
            
            obj.ImgDataCol  = imgDataCol;
            obj.ImgDataFilt = imgDataFilt;
            obj.ImgDffSpike = DffData;
            
            % output
            %DTP_ManageText([], sprintf('TwoPhoton : Spike Decoding of dF/F ROI is computed'),  'I' ,0)
        end
        
        
        
        % ==========================================
        function obj = ShowFilter(obj,FigNum)
            % ShowFilter - show shape of the filter
            % Inputs:
            %   obj         - control structure
            %
            % Outputs:
            %   obj         - control structure updated
            
            if nargin < 2, FigNum = 145; end
            if FigNum < 1, return; end
            
            % show filter
            sampFreq    = 1/obj.ImageSampleTime;
            
            riseTime    = obj.DeconvFiltRiseTime;
            riseSamp    = ceil(obj.DeconvFiltRiseTime * sampFreq);
            riseAmp     = obj.DeconvFiltRiseAmp;
            filtDur     = obj.DeconvRespMaxWidth * sampFreq;      % filter duration in sec
            filtTau     = obj.DeconvFiltTau * sampFreq;     % filter slope in 1/sec
            minWidth    = obj.DeconvRespMinWidth  * 1;
            maxWidth    = obj.DeconvRespMaxWidth  * 1;
            filtLen     = ceil(filtDur);
            filtShape   = exp(-(0:filtLen-1)'./(filtTau))*riseAmp;
            tt          = (0:filtLen-1)';
            tt          = [-riseSamp*2;tt]*obj.ImageSampleTime; filtShape = [0;filtShape];
            xr          = -[2 1 1 2]*riseTime;
            yr          = [0 0 1 1]*riseAmp;
            xm          = [0 1 1 0]*(maxWidth - minWidth) + minWidth + riseTime*2;
            ym          = [0 0 1 1]*riseAmp;
            
            % show filter
            figure(FigNum), set(gcf,'Tag','TwoPhotonAnalysis'),clf; colordef(gcf,'none')
            plot(tt,filtShape,'y');
            patch(xr,yr,'red','FaceColor','none','EdgeColor','r')            
            patch(xm,ym,'g','FaceColor','none','EdgeColor','g')            
            title('Calcium Response Approximation Filter')
            xlabel('Time [sec]')
            
        end
        
        % ==========================================
        function obj = ShowResults(obj,FigNum)
            % ShowResults - show processing results
            % Inputs:
            %   obj         - control structure
            %
            % Outputs:
            %   obj         - control structure updated
            
            if FigNum < 1, return; end;
            
            timeImage       = (1:nR)*Par.ImageSampleTime;
            
            figure(FigNum), set(gcf,'Tag','TwoPhotonAnalysis'),clf; hFig2 = gcf;
            imagesc(1:numROI,1:nR,obj.ImgDataCol);colormap(gray);impixelinfo
            xlabel('Column number'),ylabel('Row number')
            hold on;
            for k = 1:numROI,
                %colStart         = StrROI{k}.xy(1,1);
                %colEnd           = StrROI{k}.xy(2,1);
                %text(k,20+rem(k,2)*20,strROI{k}.name,'Color', strROI{k}.color,'FontWeight','bold','Interpreter','none')
            end;
            hold off;
            title(sprintf('Spike Extracted Data : %d - cells,  ',numROI),'interpreter','none')
            
            cellShowId = k;
            
            figure(FigNum+1), set(gcf,'Tag','TwoPhotonAnalysis'),clf; hFig3 = gcf;
            plot(timeImage, obj.ImgDataCol(:,cellShowId),'b',timeImage,obj.ImgDataFilt(:,cellShowId),'k', timeImage,obj.ImgDffSpike(:,cellShowId),'r')
            xlabel('Time [sec]'), ylabel('Amplitude [Volt]')
            legend('dF/F','dF/F Smooth','Spike Deconv')
            %title(sprintf('Cell %s : Deconvolution Results',strROI{cellShowId}.name))
            title(sprintf('Cell %d : Deconvolution Results',cellShowId))
            
            % Init neurophil figure
            figure(hFig2)
            set(hFig2,'WindowButtonDownFcn',@(o,e)obj.hFig2_wbdcb(o,e))
            %set(gca,'DrawMode','fast');
            
            % use wheele to do cell browsing
            figure(hFig2)
            set(hFig2,'WindowScrollWheelFcn',@(o,e)obj.hFig2_scroll(o,e))
            %set(gca,'DrawMode','fast');
            
            obj.FigHandle2              = hFig2;
            obj.FigHandle3              = hFig3;

            
        end
        
        
        %%%%%%%%%%%%%%
        % hFig2 - Callbacks
        %%%%%%%%%%%%%%
        function obj = hFig2_wbdcb(obj,src,evnt)
            
            hFig2 = obj.FigHandle2;
            
            if strcmp(get(src,'SelectionType'),'normal')
                %set(src,'pointer','circle')
                cp = get(gca,'CurrentPoint');
                xinit = cp(1,1);
                xinit = round(xinit) + [1 1]*0;
                XLim = get(gca,'XLim');
                % check the point location
                if xinit(1) < XLim(1) || XLim(2) < xinit(1) , return; end;
                
                %yinit = [yinit yinit];
                yinit = cp(1,2);
                yinit = round(yinit) + [1 1]*0;
                YLim = get(gca,'YLim');
                if yinit(1) < YLim(1) || YLim(2) < yinit(1) , return; end;
                
                figure(hFig2),
                hcross(1) = line('XData',xinit,'YData',YLim,'color','m','LineStyle',':');
                
                hcross_old = getappdata(hFig2,'hcross');
                if ~isempty(hcross_old),
                    if ishandle(hcross_old),
                        delete(hcross_old); % delete previous cross
                    end;
                end;
                setappdata(hFig2,'hcross',hcross);% store new
                
                cellShowId          = xinit(1);
                
                % define data
                [numL,numC]         = size(imgDataCol);
                if cellShowId < 1 || cellShowId > numC,
                    disp('CellTraceProbing - wrong cell number. Exiting without update')
                    return;
                end;
                
                obj = Fig1_Redraw(obj,cellShowId);
                
            end
        end
        
        
        
        %%%%%%%%%%%%%%
        % hFig - Wheele Callbacks
        %%%%%%%%%%%%%%
        function obj = hFig2_scroll(obj,src,evnt)
            
            hFig2 = obj.FigHandle2;            
            
            % define data
            [numL,numC]     = size(imgDataCol);
            if evnt.VerticalScrollCount < 0 && cellShowId < numC,
                cellShowId = cellShowId + 1;
            elseif evnt.VerticalScrollCount > 0 && cellShowId > 1,
                cellShowId = cellShowId - 1;
            end
            
            % show line
            figure(hFig2),
            hcross(1) = line('XData',ones(2,1)*cellShowId,'YData',get(gca,'YLim'),'color','m','LineStyle',':');
            hcross_old = getappdata(hFig2,'hcross');
            if ~isempty(hcross_old),
                if ishandle(hcross_old),
                    delete(hcross_old); % delete previous cross
                end;
            end;
            setappdata(hFig2,'hcross',hcross);% store new
            
            obj = Fig1_Redraw(obj,cellShowId);
            
        end %figScroll
        
        
        
        % redraw the image
        function obj = Fig1_Redraw(obj,cellShowId)
            
            if nargin < 2, cellShowId = 1; end            
            
            hFig3 = obj.FigHandle3;

            
            %%%%%
            % show trace
            %%%%%
            figure(hFig3),
            %plot(timeImage, strROI{cellShowId}.procROI,'b', timeImage,strROI{cellShowId}.spikeData,'r')
            plot(timeImage, obj.ImgDataCol(:,cellShowId),'b',timeImage,obj.ImgDataFilt(:,cellShowId),'k', timeImage,obj.ImgDffSpike(:,cellShowId),'r')
            
            xlabel('Time [sec]'), ylabel('Amplitude [Volt]')
            legend('dF/F','dF/F Smooth','Spike Deconv')
            title(sprintf('Cell %d : Deconvolution Results',cellShowId))
            
            
            % return attention to figure 1
            figure(hFig2),
        end
        
        
        
        
        %         % ==========================================
        %         function obj = TestDFF(obj)
        %
        %             % TestDFF - performs testing of the mstrix inversion method on random data
        %
        %             figNum          = 11;
        %             %dataPath        = 'C:\Uri\DataJ\Janelia\Imaging\M2\2_20_14\2_20_14_m2__002.tif';
        %             dataPath                = 'C:\Uri\DataJ\Janelia\Imaging\m8\02_10_14\2_9_14_m8__003.tif';
        %             dffType         = 1;   % dff type
        %             emphType        = 5;   % signal emphsize type
        %
        %
        %             [obj, imgData]  = LoadImageData(obj, dataPath);
        %             %obj                     = SetData(obj, imgData);
        %             %obj             = GetNeighborhoodIndexes(obj, 8);
        %             obj             = ComputeDFF(obj,dffType);
        %             % Signal Emphasize
        %             obj             = SignalEmphasizeDFF(obj, emphType);
        %
        %             obj             = PlayImgData(obj, figNum);
        %             obj             = PlayImgDFF(obj, figNum+1);
        %             obj             = DeleteData(obj);
        %
        %         end
        %
        
        
    end% methods
end% classdef
