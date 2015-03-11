function [Par,X] = Test_Hist3DVideoEncode(Par,D)
% Test_Hist3DVideoEncode encodes video straem D into 3D histograms for Fern classifier
%
%
% Inputs:
%       Par - parameters
%       D   - nR x nC x nT image array
% Outputs:
%       Par - parameters updated
%       X   - nVect x nFeat output after hist encoding

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 18.02 22.04.14 UD     Created
%-----------------------------
    
if nargin < 1, Par = [];            end;
if nargin < 2, load('mri.mat','D'); end;

%%% Params
binSize     = 16;
nOrient     = 9;
vClip       = 0.2;   % hist clip value
figNum      = 31;


% check Par
if isfield(Par,'binSize'), binSize = Par.binSize; end
if isfield(Par,'nOrient'), nOrient = Par.nOrient; end

%addpath(genpath('C:\Uri\Projects\Technion\Maria\TwoPhotonJanelia_1802'));
%addpath(genpath('C:\Uri\Code\Matlab\ImageProcessing\People\piotr_toolbox_V3.25'));


%%% Data
%

D           = single(squeeze(D));
[nR,nC,nT]  = size(D);
% centers
%[nRc,nCc,nTc] = deal(round(nR/2),round(nC/2),round(nT/2));

%%% Collect different dim
tH  = {}; k = 1;
for t = 1:binSize:nT,
    I       = squeeze(D(:,:,t));
    H       = fhog(I,binSize,nOrient,vClip);
    tH{k}   = H; k = k + 1;
end
V   = hogDraw(H,25,0);
figure(figNum);  im(I); 
figure(figNum+1); montage2(H);
figure(figNum+2); im(V)

cH  = {}; k = 1;
for c = 1:binSize:nC,
    I       = squeeze(D(:,c,:));
    H       = fhog(I,binSize,nOrient,vClip);
    cH{k}   = H; k = k + 1;
end

rH  = {}; k = 1;
for r = 1:binSize:nR,
    I       = squeeze(D(r,:,:));
    H       = fhog(I,binSize,nOrient,vClip);
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


X       = featMtrx;

return

