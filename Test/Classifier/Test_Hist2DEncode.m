function [Par,X] = Test_Hist2DEncode(Par,D,FigNum)
% Test_Hist2DEncode encodes single image into 2D histograms for classifier
%
%
% Inputs:
%       Par - parameters
%       D   - nR x nC image array
% Outputs:
%       Par - parameters updated
%       X   - nVect x nFeat output after hist encoding

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 18.09 07.07.14 UD     Created
%-----------------------------
    
if nargin < 1, Par = [];            end;
%if nargin < 2, D   = uint16(imread('cell.tif')); end;
if nargin < 2, D   = uint16(imread('circuit.tif')); end;
if nargin < 3, FigNum = 0; end;


%%% Params
binSize     = 8;
nOrient     = 9;
vClip       = 0.2;   % hist clip value


% check Par
if isfield(Par,'binSize'), binSize = Par.binSize; end
if isfield(Par,'nOrient'), nOrient = Par.nOrient; end

%addpath(genpath('C:\Uri\Projects\Technion\Maria\TwoPhotonJanelia_1802'));
%addpath(genpath('C:\Uri\Code\Matlab\ImageProcessing\People\piotr_toolbox_V3.25'));


%%% Data
%

D           = single(squeeze(D));
[nR,nC,nT]  = size(D);
if nT > 1,
    warning('INput data has several dimensions (time or color). Using only first one.');
    nT = 1;
end
% centers
%[nRc,nCc,nTc] = deal(round(nR/2),round(nC/2),round(nT/2));

%%% Collect different dim
I       = squeeze(D(:,:,nT));
H       = fhog(I,binSize,nOrient,vClip);
    
% V   = hogDraw(H,25,1);
% figure(11); im(I); 
% figure(12); montage2(H);
% figure(13); im(V)

%%% Form feature vector
[nRBin,nCBin,nFeat] = size(H);
[rInd,cInd]         = meshgrid(1:nRBin,1:nCBin);
[rInd,cInd]         = deal(rInd(:),cInd(:));
featNum             = length(rInd);
featMtrx            = zeros(featNum,nFeat,'single');
rcMtrx              = H;
for k = 1:featNum,
    featVect        = rcMtrx(rInd(k),cInd(k),:);
    featMtrx(k,:)   = shiftdim(featVect,1);
end

% I   = squeeze(D(nRc,:,:));
% H   = fhog(I,8,9); 

X       = featMtrx;

if FigNum < 1, return; end;

V               = hogDraw(H,25,1);
figure(FigNum + 1); im(I); 
figure(FigNum + 2); montage2(H);
figure(FigNum + 3); im(V)
figure(FigNum + 4); imagesc(featMtrx)



return

