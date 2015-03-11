function [Par,DffData] = TPA_FastEventDetect(Par,DffData,FigNum)
% TPA_FastEventDetect - performs spike extraction from ROI dF/F data
% using local fast transition from low to high 
% Inputs:
%   Par         - control structure
%   DffData      - nTime x nRoi value at each ROI line
%
% Outputs:
%   Par         - control structure updated
%   strROI      - nTime x nRoi detected spikes

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 19.22 16.02.15 UD     Adopted for traces.
% 13.24 05.08.14 UD     max response time limit. Resolves area when signal below 0
% 13.23 17.06.14 UD     only valid
% 13.18 11.06.14 UD     created
%-----------------------------

if nargin < 1,  Par = localParInit(); end;
if nargin < 2, DffData = rand(360,4); end;
if nargin < 3, FigNum = 1; end;

% params
if isempty(Par), Par = localParInit(); end;

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
sampFreq        = 1/Par.ImageSampleTime;
filtDur         = Par.DeconvFiltDur * sampFreq;      % filter duration in sec
%filtTau     = Par.DeconvFiltTau * sampFreq;     % filter slope in 1/sec
filtLenH        = ceil(filtDur/2);
filtLen         = filtLenH*2;

%filtSmoothLen = ceil(Par.SmoothFiltDur * sampFreq);
%filtShape   = exp(-(0:filtLen-1)'./(filtTau));

% prepare for deconvolution - freq domain
% domain      = true(filtLen,1);
% patt        = [1;2;1];
%filtSmooth  = ones(filtLen,1);
filtSmooth          = hamming(filtLen); 
%filtSmooth  = gausswin(filtLen); 

filtSmooth          = filtSmooth./sum(filtSmooth);

% additional params
MaxMinThr           = Par.DeconvFiltRiseAmp;  % determine the difference in rize time
%MinSpikeWidth       = ceil(filtTau);     % samples for average spike
ArtifactTime        = 2;    % samples in the initial time to remove spikes
SupWinSize          = ceil(Par.DeconvFiltRiseTime * sampFreq);
respMinWidth        = ceil(Par.DeconvRespMinWidth * sampFreq); % minimal width
respMaxWidth        = ceil(Par.DeconvRespMaxWidth * sampFreq); % max width


%%%%%
% Process one by one
%%%%%

for k = 1:numROI,
    
    % Processing works on columns
    traceSig            = DffData(:,k);
    
    % smooth
    dFFFilt             = filtfilt(filtSmooth,1,traceSig);
    
    % prepare for transition
    dFFMinFix           = [zeros(SupWinSize-1,1)+10;  dFFFilt(1:end-SupWinSize+1) ];
    dFFMaxFix           = [dFFFilt(SupWinSize:end); zeros(SupWinSize-1,1)+0 ];


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
            lastPos      = min(nR,dMaxMinInd(s+1));  % go to the next rise
        end
            
        while dFFFilt(last_point) >= dFFFilt(first_point) && last_point < lastPos,
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
        SpikeTrain(dMaxMinInd(s):dMaxMinInd(s)+SpikeWidth(s)) = SpikeHeight(s);
    end;
    SpikeTrain              = SpikeTrain(1:nR); 
    
    % valid spikes
    %validInd                = find(SpikeWidth > 1);
    
    
    % save
    imgDataCol(:,k)         = DffData(:,k); % save for test
    imgDataFilt(:,k)        = dFFFilt ;     % filtered
    DffData(:,k)            = SpikeTrain;   % detected
    
end;

% output
%DTP_ManageText([], sprintf('Spike Decoding of dF/F ROI is computed'),  'I' ,0)


if FigNum < 1, return; end;

timeImage       = (1:nR)*Par.ImageSampleTime;

figure(FigNum), set(gcf,'Tag','TwoPhotonAnalysis'),clf; hFig2 = gcf;
imagesc(1:numROI,1:nR,imgDataCol);colormap(gray);impixelinfo
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
plot(timeImage, imgDataCol(:,cellShowId),'b',timeImage,imgDataFilt(:,cellShowId),'k', timeImage,DffData(:,cellShowId),'r')
xlabel('Time [sec]'), ylabel('Amplitude [Volt]')
legend('dF/F','dF/F Smooth','Spike Deconv')
title(sprintf('Cell %s : Deconvolution Results',strROI{cellShowId}.name))


% Init neurophil figure
figure(hFig2)
set(hFig2,'WindowButtonDownFcn',@hFig2_wbdcb)
set(gca,'DrawMode','fast');

% use wheele to do cell browsing
figure(hFig2)
set(hFig2,'WindowScrollWheelFcn',@hFig2_scroll)
set(gca,'DrawMode','fast');



%%%%%%%%%%%%%%
% hFig2 - Callbacks
%%%%%%%%%%%%%%
    function hFig2_wbdcb(src,evnt)
        
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
            
            Fig1_Redraw();
            
        end
    end



%%%%%%%%%%%%%%
% hFig - Wheele Callbacks
%%%%%%%%%%%%%%
    function hFig2_scroll(src,evnt)
        
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
        Fig1_Redraw();
        
    end %figScroll



% redraw the image
    function Fig1_Redraw()
        
        %%%%%
        % show trace
        %%%%%
        figure(hFig3),
        %plot(timeImage, strROI{cellShowId}.procROI,'b', timeImage,strROI{cellShowId}.spikeData,'r')
        plot(timeImage, imgDataCol(:,cellShowId),'b',timeImage,imgDataFilt(:,cellShowId),'k', timeImage,DffData(:,cellShowId),'r')
        
        xlabel('Time [sec]'), ylabel('Amplitude [Volt]')
        legend('dF/F','dF/F Smooth','Spike Deconv')
        title(sprintf('Cell %s : Deconvolution Results',strROI{cellShowId}.name))
        
        
        % return attention to figure 1
        figure(hFig2),
    end
    
    
    
    % init local params
    function Par = localParInit()
        
    %%%%%%%%%%%%%%%%%%%%%%
    % Deconvolution - spike finder
    %%%%%%%%%%%%%%%%%%%%%%
    Par.DeconvType              = 1;       % type of deconvolution to use
    Par.SmoothFiltDur           = .1;       % smoothing filter (N.A. in Fast Rise)
    Par.DeconvFiltDur           = .2;       % smoothing filter duration in sec 
    Par.DeconvFiltTau           = .2;       % filter slope in 1/sec (N.A. in Fast Rise)
    Par.DeconvFiltRiseTime      = .1;       % rise time in dF/F for peak detection 
    Par.DeconvFiltRiseAmp       = .1;       % rise value Max-Min in dF/F for peak detection 
    Par.DeconvRespMinWidth      = .1;       % min cell response dF/F duration in sec 
    Par.DeconvRespMaxWidth      = 2;        % max cell response dF/F duration in sec 
    Par.ImageSampleTime         = 10e-3;   % sampling time per line in sec
    end


end


