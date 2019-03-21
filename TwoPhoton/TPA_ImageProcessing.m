function [Par,ImgData]    = TPA_ImageProcessing(Par,ImgData,ProcessType,FigNum)
% TPA_ImageProcessing - performs different image processing operations 
% Inputs:
%        Par - different params for use
%    ImgData - image data 
% Outputs:
%        Par - different params for next use
%    ImgData - image data after processing

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 13.09 18.06.14 UD     Updating filters
% 11.00 18.04.13 UD     Adopted for Inbar from GroupTest_1000
%-----------------------------

%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1,     Par      = TPA_ParInit;      end;
if nargin < 2,     ImgData  = rand(300,200);  ImgData(101:151,51:54) = 10*exp(-repmat((1:51)'/20,1,4));  end;
if nargin < 3,     ProcessType   = 'none';      end;
if nargin < 4,     FigNum   = 1;                end;

%%%%%%%%%%%%%%%%%%%%%%
% Params
%%%%%%%%%%%%%%%%%%%%%%

[rowNum,colNum]            = size(ImgData);

% CHECK IF NEEDeD
if isempty(ProcessType)
ProcessType = 'none';
end


%%%%%%%%%%%%%%%%%%%%%%
% Compute 
%%%%%%%%%%%%%%%%%%%%%%
switch ProcessType,
    case 'none',
        % do nothing
    
    case 'smooth',
        H               = ones(5)/25;
        ImgData         = imfilter(ImgData,H);
        
    case 'timeDown', % filtering along with time arrow 
        [Par,ImgData]   = local_TimeFilter(Par,ImgData);
        
    case {'timeUp','bleach1'},      % filtering against time arrow 
        [Par,ImgData]   = local_TimeFilter(Par,ImgData(end:-1:1,:));
        ImgData         = ImgData(end:-1:1,:);
  
    case 'spaceLeft', % filtering along with time arrow 
        [Par,ImgData]   = local_TimeFilter(Par,ImgData');
        ImgData         = ImgData';       

    case 'spaceRight', % filtering along with time arrow 
        ImgData         = ImgData(:,end:-1:1)';       
        [Par,ImgData]   = local_TimeFilter(Par,ImgData);
        ImgData         = ImgData(:,end:-1:1)';       
        
        
    case 'baseline',
        [Par,ImgData]  = local_BaseLine(Par,ImgData);
        
    case 'timeFiltVerySlow',
        Par.TimeFilterType = 13;
        [Par,ImgData]  = local_TimeFilter(Par,ImgData);        
        
        
    case 'timeFiltSlow',
        Par.TimeFilterType = 12;
        [Par,ImgData]  = local_TimeFilter(Par,ImgData);
 
    case 'timeFiltFast',
        Par.TimeFilterType = 11;
        [Par,ImgData]  = local_TimeFilter(Par,ImgData);
        
        
    case 'norm',
        [Par,ImgData] = local_Normalization(Par,ImgData);
        
        
     case 'dF/F',
        Par.BaseLineType = 5;
        [Par,RoiBL]    = local_BaseLine(Par,ImgData);         
        %[Par,RoiNorm]  = local_Normalization(Par,ImgData);
        RoiNorm        = abs(RoiBL); % in case if BL is negative
        ImgData        = (ImgData - RoiBL)./(RoiNorm+eps);
        
     case 'dF/std',
        Par.BaseLineType = 1;  % mean        
        [Par,RoiBL]    = local_BaseLine(Par,ImgData);     
        Par.ImageNormType = 2; % std
        [Par,RoiNorm]  = local_Normalization(Par,ImgData);
        ImgData        = (ImgData - RoiBL)./(RoiNorm+eps);
        

     case 'Konnerth',
        tau0           = 1; %round(0.2  * SampFreq);  % samples weight filter w = exp(-|t|/tau0)
        tau1           = 5; % round(0.75 * SampFreq);  % samples average filter for F average
        tau2           = 10; % round(3    * SampFreq);  % samples minuimum for F0
        
        
        % input signal - fluorescence
        F              = ImgData;
        
        % compute average
        filtAv         = ones(tau1,1)/tau1;
        Par.TimeFilterType          = 6;
        [Par,Fav]       = local_TimeFilter(Par,F, filtAv);
        
        % compute baseline
        Par.BaseLineType           = 10;
        [Par,F0]        = local_BaseLine(Par,Fav,tau2);    
        
        % Response 
        R               = (F - F0)./(F0+eps);
        
        % filter response -  design weight filter
        tau            = -3*tau0:3*tau0;
        filtW          = exp(-abs(tau)./tau0);
        filtW          = filtW/sum(filtW);
        
        Par.TimeFilterType          = 6;
        [Par,dFF]       = local_TimeFilter(Par,R, filtW);
      
        % output
        ImgData         = dFF;
        
        
    otherwise
        error('Unknown processing type')
end;




%%%%%%%%%%%%%%%%%%%%%%
% Output
%%%%%%%%%%%%%%%%%%%%%%
% Par.ColStart     = ColStart;
% Par.ColEnd       = ColEnd;
% Par.ColColor     = ColColor;
% Par.ColName      = ColName;
% Par.CellLabelNum = CellLabelNum;

if FigNum < 1, return; end;


% show
figure(FigNum + 2),
imagesc(ImgData),colormap(gray),colorbar
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
switch Par.TimeFilterType
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
        
    case 11,	% LP filter
        alpha		= 0.95;
        startData   = repmat(mean(ImgData(1:10,:)),100,1);
        ImgData     = filtfilt((1-alpha),[1 -alpha],[startData;ImgData]);
        ImgData     = ImgData(101:end,:);
        
    case 12,	% LP filter
        alpha		= 0.97;
        startData   = repmat(mean(ImgData(1:10,:)),100,1);
        ImgData     = filtfilt((1-alpha),[1 -alpha],[startData;ImgData]);
        ImgData     = ImgData(101:end,:);
        
    case 13,	% LP filter
        alpha		= 0.99;
        startData   = repmat(mean(ImgData(1:10,:)),100,1);
        ImgData     = filtfilt((1-alpha),[1 -alpha],[startData;ImgData]);
        ImgData     = ImgData(101:end,:);
        
        
    otherwise
        error('Unsupported TimeFilterType')
end;


return

% ----------------------------------------------------------------
function [Par,ImgData]    = local_BaseLine(Par,ImgData, WinLen)
% estimate base line of the data

if nargin < 3, WinLen = 1; end;

[RowNum,ColNum]            = size(ImgData);

%%%%%%%%%%%%%%%%%%%%%%
% Compute baseline image
%%%%%%%%%%%%%%%%%%%%%%
switch Par.BaseLineType,
    case 0, % no Baseline
        BaseLine    = ImgData*0;
        
    case 1,	% mean value substraction - image is constant over the columns
        BaseLine	= repmat(mean(ImgData),RowNum,1);
        
%     case 2, % neuro phil and mean value substraction
%         ImgData  =  ImgData - repmat(mean(ImgDataNeuroPhil(RowInd,:),2),1,ColNum);
%         BaseLine	= repmat( mean(ImgData),RowNum,1);
        
    case 3, % minimum value reductions
        BaseLine	= repmat(min(ImgData),RowNum,1);
        
    case 5, % mean of 10 % minimum values reductions
        ImSort      = sort(ImgData);
        MinNumber   = ceil(0.1*RowNum); % take 10 %
        BaseLine	= repmat(mean(ImSort(1:MinNumber,:)),RowNum,1);
       
    case 6,	% LP filter
        alpha		= 0.9;
        BaseLine	= filtfilt((1-alpha),[1 -alpha],ImgData);
        
        
    case 7,	% LP filter
        alpha		= 0.99;
        BaseLine	= filtfilt((1-alpha),[1 -alpha],ImgData);
        
    case 10, % minimum adaptive window
        
        BaseLine    = ImgData;
        for k = WinLen+1:RowNum,
            suppInd = k - (0:WinLen-1);
            minVal  = min(ImgData(suppInd,:));
            BaseLine(k,:) = minVal;
        end;
        % correct the starting index
        BaseLine(1:WinLen,:) = repmat(BaseLine(WinLen+1,:),WinLen,1);
        
        
    otherwise error('Unknown BaseLineType')
end;
ImgData		= BaseLine;


return

% ----------------------------------------------------------------
function [Par,ImgData]    = local_Normalization(Par,ImgData)
% do normalization over the data

[RowNum,ColNum]            = size(ImgData);

% Compute dF/F image
%%%%%%%%%%%%%%%%%%%%%%
% normalize according to :
switch Par.ImageNormType,
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

