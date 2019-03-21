function [Par,StrROI] = TPA_ProcessROI(Par,StrROI,FigNum)
% TPA_ProcessROI - performs different ROI processing operations for dF/F computation
% Inputs:
%   Par         - control structure 
%   StrROI      - updated with nTime x nLen mean value at each ROI line 
%   FigNum      = debug/show
% Outputs:
%   Par         - control structure updated
%   StrROI      - updated with nTime x nLen mean value at each ROI line 

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 28.06 35.01.18 UD     Multi trial baseline.
% 28.04 15.01.18 UD     Adding Inhibitory ROI option.
% 23.02 06.02.16 UD  	Debug roi class 
% 21.19 08.12.15 UD     Support dF/F with small bias
% 17.09 07.04.14 UD     Support different dF/F
% 12.01 14.09.13 UD     Support Z stack
% 11.06 06.08.13 UD 	support two channel processing
% 11.02 15.07.13 UD     rename
% 10.11 09.07.13 UD     created 
%-----------------------------

if nargin < 1,  error('Requires input params');         end;


%%%%
% Check
%%%%

% check for multiple Z ROIs
numROI              = length(StrROI);
if numROI < 1
    DTP_ManageText([], sprintf('ROI Process : No ROI data is found. Please select/load ROIs'),  'E' ,0);
    return
end
% check for multiple Z ROIs
if ~isprop(StrROI{1},'Data') 
    DTP_ManageText([], sprintf('ROI Process :Something wrong with ROI data. You should review this ROI structure'),  'E' ,0);
    return
end
% check if empty
if isempty(StrROI{1}.Data) 
    DTP_ManageText([], sprintf('ROI Process : No average fluorescence data found. May be you need to do averaging first.'),  'E' ,0);
    return
end

%%%%
% Run
%%%%

DTP_ManageText([], sprintf('ROI Process : Started ...'),  'I' ,0), tic;

baseLineROIs    = repmat(StrROI{1}.Data(:,1),1,numROI);
    
for k = 1:numROI
    
    % Processing works on columns
    meanROI                 = StrROI{k}.Data(:,1);
    baseLine                = StrROI{k}.DataBaseLine;

    % compute dF/F
     [Par,procROI,baselineROI]       = local_ProcessingROI(Par,meanROI,baseLine,0);
     %procROI             = procROI;  % time info is along x axis
    
    % save
    StrROI{k}.Data(:,2)    = procROI;
    baseLineROIs(:,k)      = baselineROI;
    
end

% output
DTP_ManageText([], sprintf('ROI Process : dF/F ROI is computed in %4.3f [sec] ...',toc),  'I' ,0);

if FigNum < 1, return; end
    
%%% Concatenate all the ROIs in one Image
procROI             = StrROI{1}.Data(:,2);
namePos             = ones(numROI,1);  % where to show the name
nT                  = size(procROI,1);
tt                  = (1:nT)';

TraceColorMap       = Par.Roi.TraceColorMap ;
MaxColorNum         = Par.Roi.MaxColorNum;

for k = 2:numROI
    %procROI         = [procROI StrROI{k}.procROI];
    namePos(k)      = namePos(k-1) +length(StrROI{k}.LineInd);
end


% figure(FigNum),set(gcf,'Tag','AnalysisROI'),clf;
% imagesc(procROI',Par.Roi.dFFRange), colorbar; colormap(gray);
% hold on
% for k = 1:numROI,
%     text(10,namePos(k),StrROI{k}.Name,'color','y')
% end
% hold off
% ylabel('ROI Line Pixels'),xlabel('Frame Num')
% title(sprintf('dF/F for Trial %s',Par.DMT.VideoFileNames{Par.DMT.Trial}), 'interpreter','none'),

maxRange    = 100;
figure(FigNum),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none')
for k = 1:numROI,
    clr             = TraceColorMap(mod(k,MaxColorNum)+1,:);
    plot(tt,StrROI{k}.Data(:,1)             + namePos(k)*maxRange,'color',clr); hold on
    plot(tt,baseLineROIs(:,k)               + namePos(k)*maxRange,'color',clr,  'linestyle','--');
    if k == 1, legend('Trace','BaseLine'); end
    %plot(tt,ones(nT,1)                          + namePos(k)*maxRange,'color',[1 1 1]*0.6,'linestyle',':');
    text(10,baseLineROIs(10,k)              + namePos(k)*maxRange,StrROI{k}.Name,'color','y')
end
hold off
ylabel('Fluorescence (Increamental)'),xlabel('Frame Num')
title(sprintf('Fo - Mean Fluorescence and BL for Trial%s',Par.DMT.VideoFileNames{Par.DMT.Trial}), 'interpreter','none'),


maxRange            = 1; %max(Par.DataRange);
figure(FigNum+1),set(gcf,'Tag','AnalysisROI','Color','b'),clf; colordef(gcf,'none');
for k = 1:numROI,
    clr             = TraceColorMap(mod(k,MaxColorNum)+1,:);    
    plot(tt,StrROI{k}.Data(:,2) + namePos(k)*maxRange,'color',clr); hold on
    plot(tt,ones(nT,1)        + namePos(k)*maxRange,'color',[1 1 1]*0.6);
    text(10,namePos(k)*maxRange,StrROI{k}.Name,'color','y')
end
hold off
ylabel('dF/F (Increamental)'),xlabel('Frame Num')
title(sprintf('dF/F for Trial %s',Par.DMT.VideoFileNames{Par.DMT.Trial}), 'interpreter','none'),


drawnow

return
    

%%%%%%%%%%%%%%%%%%%%%%
% Local Functions
%%%%%%%%%%%%%%%%%%%%%%


function [Par,RoiData,RoiBL]    = local_ProcessingROI(Par,RoiData,BaseLine,FigNum)
% local_ProcessingROI - performs different ROI processing operations 
% Inputs:
%        Par - different params for use
%    RoiData - image data 
%    BaseLine - base line image data 
% Outputs:
%        Par - different params for next use
%    RoiData - image data after processing
%    RoiBL   - baseline for monitoring

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 17.09 07.04.14 UD     New processing
% 10.10 02.07.13 UD     Adopted from Imagine
% 12.00 21.05.13 UD     For Inbar
% 11.00 18.04.13 UD     Adopted for Inbar from GroupTest_1000
%-----------------------------

%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1,     Par      = DTP_ParInit;      end
if nargin < 2,     RoiData  = rand(300,200);  RoiData(101:151,51:54) = 10*exp(-repmat((1:51)'/20,1,4));  end;
if nargin < 3,     FigNum   = 1;                end
if nargin < 4,     FigNum   = 1;                end


[rowNum,colNum]            = size(RoiData);

%%%%%%%%%%%%%%%%%%%%%%
% Smooth
%%%%%%%%%%%%%%%%%%%%%%
RoiDataSave = RoiData;


%%%%%%%%%%%%%%%%%%%%%%
% Compute 
%%%%%%%%%%%%%%%%%%%%%%
switch Par.Roi.ProcessType

     case Par.ROI_DELTAFOVERF_TYPES.MEAN  % 'dF/F',
        % standard dF/F Fo = mean
        Par.Roi.BaseLineType = 1;
        [Par,RoiBL]    = local_BaseLine(Par,RoiData);         
        RoiNorm        = abs(RoiBL); % in case if BL is negative
        RoiData        = (RoiData - RoiBL)./(RoiNorm+eps);
        
    case Par.ROI_DELTAFOVERF_TYPES.MIN10  % 'dF/F',
        % 10% min dF/F Fo = 10% min values
        Par.Roi.BaseLineType = 5;
        [Par,RoiBL]    = local_BaseLine(Par,RoiData);         
        %[Par,RoiNorm]  = local_Normalization(Par,RoiData);
        RoiNorm        = max(0,RoiBL); % in case if BL is negative
        RoiData        = (RoiData - RoiBL)./(RoiNorm+eps);
        
        
     case Par.ROI_DELTAFOVERF_TYPES.STD %'dF/std',
        Par.Roi.BaseLineType = 1;  % mean        
        [Par,RoiBL]    = local_BaseLine(Par,RoiData);     
        Par.Roi.ImageNormType = 2; % std
        [Par,RoiNorm]  = local_Normalization(Par,RoiData);
        RoiData        = (RoiData - RoiBL)./(RoiNorm+eps);
        
        
     case Par.ROI_DELTAFOVERF_TYPES.MIN10CONT %'dF/F F - 10% min continious',
        Par.Roi.BaseLineType = 6;
        [Par,RoiBL]    = local_BaseLine(Par,RoiData);         
        %[Par,RoiNorm]  = local_Normalization(Par,RoiData);
        RoiNorm        = abs(RoiBL); % in case if BL is negative
        RoiData        = (RoiData - RoiBL)./(RoiNorm+eps);
        
        
     case Par.ROI_DELTAFOVERF_TYPES.MIN10BIAS %'dF/F F - 10% min + bias',
        Par.Roi.BaseLineType = 5;
        [Par,RoiBL]    = local_BaseLine(Par,RoiData);         
        %[Par,RoiNorm]  = local_Normalization(Par,RoiData);
        RoiBL          = max(0,RoiBL); % in case if BL is negative
        RoiData        = (RoiData - RoiBL)./(RoiBL + Par.Roi.MinFluorescentLevel);

    case Par.ROI_DELTAFOVERF_TYPES.MAX10 % Fo = 10%Max. dF/F =  Fo - F / Fo 
        % 10% max dF/F Fo = 10% max values
        Par.Roi.BaseLineType = 4;
        [Par,RoiBL]    = local_BaseLine(Par,RoiData);         
        %[Par,RoiNorm]  = local_Normalization(Par,RoiData);
        RoiBL          = max(0,RoiBL); % in case if BL is negative
        RoiData        = (RoiBL - RoiData)./(RoiBL+eps);
        
    case Par.ROI_DELTAFOVERF_TYPES.MANY_TRIAL  % 'dF/F' with BIAS from many 
        % 10% min dF/F Fo = 10% min values
        %Par.Roi.BaseLineType = 5;
        if isempty(BaseLine)
            error('Baseline is not computed correctly');
        end
        RoiBL          = BaseLine;
        %[Par,RoiBL]    = local_BaseLine(Par,RoiData);         
        %[Par,RoiNorm]  = local_Normalization(Par,RoiData);
        RoiNorm        = max(0,RoiBL); % in case if BL is negative
        RoiData        = (RoiData - RoiBL)./(RoiNorm+eps);
        
        
        
    otherwise
        error('Unknown processing type')
end

%ImgData          = (ImgDataF - ImgDataBL)./(ImgDataStd + eps);



%%%%%%%%%%%%%%%%%%%%%%
% Output
%%%%%%%%%%%%%%%%%%%%%%
% Par.ColStart     = ColStart;
% Par.ColEnd       = ColEnd;
% Par.ColColor     = ColColor;
% Par.ColName      = ColName;
% Par.CellLabelNum = CellLabelNum;

if FigNum < 1, return; end

% show
figure(FigNum + 1),
imagesc(RoiDataSave),colormap(gray),colorbar
xlabel('Columns')
ylabel('Rows')
title('Original Image Data')
impixelinfo


% show
figure(FigNum + 2),
imagesc(RoiData),colormap(gray),colorbar
xlabel('Columns')
ylabel('Rows')
title('Image Data dF/F')
impixelinfo


% hold on;
% for k = 1:ColNum,
%     nind		= ColStart(k):ColEnd(k)-1;
%     subLineX	= RefLineXY(nind,1);
%     subLineY	= RefLineXY(nind,2);
%     line('XData',subLineX,'YData', subLineY,'Color', ColColor(k,:));
%     text(subLineX(1)-3, subLineY(1)-3, ColName{k},'Color', ColColor(k,:),'FontSize',13,'FontName','FixedWidth','FontWeight','bold','Interpreter','none');
% end;
% hold off;




return

%%%%%%%%%%%%%%%%%%%%%%
% Local Functions
%%%%%%%%%%%%%%%%%%%%%%

% ----------------------------------------------------------------
function [Par,ImgData]    = local_TimeFilter(Par,ImgData, FiltCoeff)
% do time filtering over the data

if nargin < 3, FiltCoeff = 1; end;

[rowNum,colNum]            = size(ImgData);

% post processing
switch Par.Roi.TimeFilterType
    case 0, % Do nothing
        %ImgDataDF      = ImgDataDF;
        
    case 1, % Substract mean
        ImgData = ImgData - repmat(mean(ImgData),rowNum,1);
        
    case 2, % small filter
        FiltLen    = 3;
        ImgData     = filtfilt(ones(FiltLen,1)/FiltLen,1,ImgData);
 
    case 3, % small filter with delay
        FiltLen    = 5;
        ImgData     = filter(ones(FiltLen,1)/FiltLen,1,ImgData);
      
    case 5, % external filter with no delay correction : 
        ImgData     = filter(FiltCoeff,1,ImgData);

    case 6, % external filter with delay correction : replicate data at the end
        FiltLen     = numel(FiltCoeff);
        FiltlenHalf = ceil(FiltLen/2);
        ImgDataRep  = [ImgData;repmat(ImgData(end,:),FiltlenHalf,1)];
        %ImgDataRep  = padarray(ImgData,FiltlenHalf,ImgData(end,:),'post');
        ImgDataRep  = filter(FiltCoeff,1,ImgDataRep);
        % correct delay
        ImgData     = ImgDataRep(FiltlenHalf+(1:size(ImgData,1)),:);
        
    otherwise
        error('Unsupported TimeFilterType')
end


return

% ----------------------------------------------------------------
function [Par,ImgData]    = local_BaseLine(Par,ImgData, WinLen)
% estimate base line of the data

if nargin < 3, WinLen = 1; end

[RowNum,ColNum]            = size(ImgData);

%%%%%%%%%%%%%%%%%%%%%%
% Compute baseline image
%%%%%%%%%%%%%%%%%%%%%%
switch Par.Roi.BaseLineType
    case 0 % no Baseline
        BaseLine    = ImgData*0;
        
    case 1	% mean value substraction - image is constant over the columns
        BaseLine	= repmat(mean(ImgData),RowNum,1);
        
%     case 2, % neuro phil and mean value substraction
%         ImgData  =  ImgData - repmat(mean(ImgDataNeuroPhil(RowInd,:),2),1,ColNum);
%         BaseLine	= repmat( mean(ImgData),RowNum,1);
        
    case 3 % minimum value reductions
        BaseLine	= repmat(min(ImgData),RowNum,1);
        
    case 4 % mean of 10 % maximum values 
        ImSort      = sort(ImgData,'descend');
        MinNumber   = ceil(0.1*RowNum); % take 10 %
        BaseLine	= repmat(mean(ImSort(1:MinNumber,:)),RowNum,1);
        
        
    case 5 % mean of 10 % minimum values reductions
        ImSort      = sort(ImgData);
        MinNumber   = ceil(0.1*RowNum); % take 10 %
        BaseLine	= repmat(mean(ImSort(1:MinNumber,:)),RowNum,1);
   
    case 6 % mean of 10 % minimum on consecutive data of 10% length - filter of with 10 support
        MinNumber   = ceil(0.05*RowNum); % take 10 %
        
        % filter to find low area
        filtNum		= ones(MinNumber,1)/MinNumber;
        ImgData     = filtfilt(filtNum,1,ImgData);
        
        % replicate minima
        BaseLine	= repmat(min(ImgData),RowNum,1);
        
    case 7	% LP filter
        alpha		= 0.99;
        BaseLine	= filtfilt((1-alpha),[1 -alpha],ImgData);
        
    case 10 % minimum adaptive window
        
        BaseLine    = ImgData;
        for k = WinLen+1:RowNum,
            suppInd = k - (0:WinLen-1);
            minVal  = min(ImgData(suppInd,:));
            BaseLine(k,:) = minVal;
        end
        % correct the starting index
        BaseLine(1:WinLen,:) = repmat(BaseLine(WinLen+1,:),WinLen,1);
        
        
    otherwise error('Unknown BaseLineType')
end
ImgData		= BaseLine;


return

% ----------------------------------------------------------------
function [Par,ImgData]    = local_Normalization(Par,ImgData)
% do normalization over the data

[RowNum,ColNum]            = size(ImgData);

% Compute dF/F image
%%%%%%%%%%%%%%%%%%%%%%
% normalize according to :
switch Par.Roi.ImageNormType,
    case 0, % no normalization
        ImgDataStd	= repmat(ones(1,ColNum),RowNum,1);
        
    case 1,	% mean value normalization - image is constant over the columns
        ImgDataStd	= repmat(mean(ImgData),RowNum,1);
        
    case 2,	% std value normalization - image is constant over the columns
        ImgDataStd	= repmat(std(ImgData,[],1),RowNum,1);
        
    case 3, % std value  normalization - bounded
        ImgDataStd	= repmat(std(ImgData,[],1),RowNum,1) + 200;
        
    case 4, % sqrt(std) value  normalization - bounded
        ImgDataStd	= repmat(sqrt(std(ImgData,[],1)),RowNum,1) + 100;
        
        
    case 6, % minimum value normalization
        ImgDataStd	= repmat(min(ImgData),RowNum,1);
        
    case 7, % minimum value normalization + constant
        ImgDataStd	= repmat(min(ImgData),RowNum,1) + 500;
        
        
    case 8, % mean of 10 % minimum values reductions
        ImSort      = sort(ImgData);
        MinNumber = ceil(0.1*LineNum); % take 10 %
        ImgDataStd	= repmat(mean(ImSort(1:MinNumber,:)),RowNum,1);
        
    case 11,	% LP filter
        alpha		= 0.99;
        ImgDataStd	= filtfilt((1-alpha),[1 -alpha],ImgData);
        
    case 20,	% baseLine
        [Par,ImgDataStd]   = local_BaseLine(Par,ImgData);
        
        
    otherwise error('Unknown ImageNormType')
end;

ImgData	= ImgDataStd;

return


