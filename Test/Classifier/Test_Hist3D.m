% Test 3D histograms
% Try to use 3D data for 3D histograms
%addpath(genpath('C:\Uri\Projects\Technion\Maria\TwoPhotonJanelia_1801'));
%addpath(genpath('C:\Uri\Code\Matlab\ImageProcessing\People\piotr_toolbox_V3.25'));

%%% Data
%load('mri.mat','D');

dm          = TPA_MotionCorrectionManager();
dm          = dm.GenData(5,6);
D           = dm.ImgData;


D           = im2single(squeeze(D));
[nR,nC,nT]  = size(D);
% centers
[nRc,nCc,nTc] = deal(round(nR/2),round(nC/2),round(nT/2));

%%% Show different dim
I   = D(:,:,nTc);
H   = fhog(I,8,9); 
V   = hogDraw(H,25,1);
figure(11); im(I); 
figure(12); montage2(H);
figure(13); im(V)

I   = squeeze(D(:,nCc,:));
H   = fhog(I,8,9); 
V   = hogDraw(H,25,1);
figure(21); im(I); 
figure(22); montage2(H);
figure(23); im(V)

I   = squeeze(D(nRc,:,:));
H   = fhog(I,8,9); 
V   = hogDraw(H,25,1);
figure(31); im(I); 
figure(32); montage2(H);
figure(33); im(V)

return

% gen class
%N=5000; H=5; d=2; [xs0,hs0,xs1,hs1]=demoGenData(N,N,H,d,1,1);
N=5000; H=2; d=20; [xs0,hs0,xs1,hs1]=demoGenData(N,N,H,d,1,1);
fernPrm             = struct('S',4,'M',50,'thrr',[-1 1],'bayes',1);
tic, [ferns,hsPr0]  = fernsClfTrain(xs0,hs0,fernPrm); toc
tic, hsPr1          = fernsClfApply( xs1, ferns ); toc
e0                  = mean(hsPr0~=hs0); e1=mean(hsPr1~=hs1);
fprintf('errors trn=%f tst=%f\n',e0,e1); figure(1);
subplot(2,2,1); visualizeData(xs0,2,hs0);
subplot(2,2,2); visualizeData(xs0,2,hsPr0);
subplot(2,2,3); visualizeData(xs1,2,hs1);
subplot(2,2,4); visualizeData(xs1,2,hsPr1);

