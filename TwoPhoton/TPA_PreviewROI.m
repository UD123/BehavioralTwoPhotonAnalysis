function [Par,StrROI]    = TPA_PreviewROI(Par, ImStack, StrROI, FigNum)
% TPA_PreviewROI - show ROI data on image.
% Inputs:
%        Par - different params for use
%       Cmnd - command - what to do 
%    ImStack -  nR x nC x nTime x nZstack image in the directory
%       StrRoi - old ROI is exists
% Outputs:
%        Par - different params for next use
%    StrROI - roi data

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 15.01 14.01.14 UD     created for preview only
%-----------------------------

if nargin < 1,      Par      = DTP_ParInit;         end;
if nargin < 2,      ImStack  = DTP_LoadImages();    end;
if nargin < 3,      StrROI   = {};                  end;
if nargin < 4,      FigNum   = 11;                  end;

%%%
% Params 
%%%
zStackInd      = Par.ZStackInd;

[nR,nC,nZ,nT] = size(ImStack);
if nZ < zStackInd,
    errordlg('Data contains less dimensions than requested')
    return;
end;

% params
numROI              = length(StrROI);
%%%
% Average over ROI according to the selected region
%%%
imMaxProject        = squeeze(mean(mean(ImStack,4),3));

figure(FigNum),set(gcf,'Tag','AnalysisROI'),clf;
imagesc(imMaxProject,Par.Roi.DataRange);  colormap(gray); colorbar;
title('Total ROI Preview')
% update structure
for k = 1:numROI,
    
    
    % show info
    xy_pos          = round(mean(StrROI{k}.xy));
    
    hold on;    
    xy              = [StrROI{k}.xy; StrROI{k}.xy(1,:)];
    plot(xy(:,1),xy(:,2),'color',StrROI{k}.color);
    text(xy_pos(1),xy_pos(2),StrROI{k}.name,'Color',StrROI{k}.color);
    hold off;
    
    
end;



return

%%%%%