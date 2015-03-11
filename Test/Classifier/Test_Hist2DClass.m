% Test 2D histograms using different classifiers
% Try to use 3D data for 3D histograms
% addpath(genpath('C:\Uri\Projects\Technion\Maria\TwoPhotonJanelia'));
% addpath(genpath('C:\Uri\Code\Matlab\ImageProcessing\People\piotr_toolbox_V3.25'));

%addpath(genpath('C:\LabUsers\Uri\Projects\Maria\DendritesTwoPhoton\TwoPhotonAnalysis'));
%addpath(genpath('C:\Uri\Code\Matlab\ImageProcessing\People\piotr_toolbox_V3.25'));


%%% Params
Par.binSize = 32;
Par.nOrient = 9;

cvTimes     = 1;        % number of cross validation
figNum      = 1;        % -100 to disable figure show 

%%% Data 0
%D           = uint16(imread('circuit.tif'));
D           = uint16(imread('coins.png'));

%%% 
% Encode
[Par,x0]    = Test_Hist2DEncode(Par,D, figNum + 11);


%%% Data 1
D           = uint16(imread('tire.tif'));
%D           = uint16(imread('rice.png'));

%%% 
% Encode
[Par,x1]    = Test_Hist2DEncode(Par,D, figNum + 21);


%%% 
% Prepare data
featMtrx    = double([x0;x1]); 
classVect   = [ones(size(x0,1),1);ones(size(x1,1),1)*2];
featNum     = size(featMtrx,1);

figure(figNum + 1),imagesc(x0),title('x0')
figure(figNum + 2),imagesc(x1),title('x1')


%%%
% Init classifiers
fernPrm         = struct('S',10,'M',50,'thrr',[0 0.5],'bayes',1,'ferns',[]);
boostPrm        = struct('nWeak',256,'verbose',0,'pTree',struct('maxDepth',5));
pTrain          ={'maxDepth',50,'F1',2,'M',150,'minChild',5};


for cvi     = 1:cvTimes,

fprintf('Iter %d\n',cvi)
    
randInd     = randperm(featNum);
trainNum    = ceil(featNum*2/3);

trainInd    = randInd(1:trainNum);
testInd     = randInd(1+trainNum:featNum);

hs0         = classVect(trainInd); 
hs1         = classVect(testInd); 
xs0         = featMtrx(trainInd,:);
xs1         = featMtrx(testInd,:);



%%% 
% Classify Ferns

% % gen class
% N=5000; H=5; d=2; [xs0,hs0,xs1,hs1]=demoGenData(N,N,H,d,1,1);
%fernPrm             = struct('S',4,'M',50,'thrr',[-1 1],'bayes',1);
tic, [ferns,hsPr0]  = fernsClfTrain(xs0,hs0,fernPrm); %toc
tic, [hsPr1,cProb]  = fernsClfApply(xs1, ferns ); %toc
e0                  = mean(hsPr0~=hs0); e1=mean(hsPr1~=hs1);
fprintf('Fern errors trn=%f tst=%f\n',e0,e1); 
fernPrm.ferns       = ferns;


% figure(3);
% subplot(2,2,1); visualizeData(xs0,2,hs0);
% subplot(2,2,2); visualizeData(xs0,2,hsPr0);
% subplot(2,2,3); visualizeData(xs1,2,hs1);
% subplot(2,2,4); visualizeData(xs1,2,hsPr1);

%%% 
% Classify Boost
%  % output should be: 'Testing err=0.0145 fp=0.0165 fn=0.0125'
%  N=5000; F=5000; sep=.01; RandStream.getGlobalStream.reset();
%  [xTrn,hTrn,xTst,hTst]=demoGenData(N,N,2,F/10,sep,.5,0);

%boostPrm        = struct('nWeak',256,'verbose',16,'pTree',struct('maxDepth',5));
model           = adaBoostTrain( xs0(hs0==1,:), xs0(hs0==2,:), boostPrm );
fp              = mean(adaBoostApply( xs1(hs1==1,:), model )>0);
fn              = mean(adaBoostApply( xs1(hs1==2,:), model )<0);
fprintf('Boost Testing err=%.4f fp=%.4f fn=%.4f\n',(fp+fn)/2,fp,fn);

%%% 
% Classify Forest
% EXAMPLE
%  N=10000; H=5; d=2; [xs0,hs0,xs1,hs1]=demoGenData(N,N,H,d,1,1);
%  xs0=single(xs0); xs1=single(xs1);

 tic, forest=forestTrain(single(xs0),hs0,pTrain{:}); %toc
 hsPr0 = forestApply(single(xs0),forest);
 hsPr1 = forestApply(single(xs1),forest);
 e0=mean(hsPr0~=hs0); e1=mean(hsPr1~=hs1);
 fprintf('Forest errors trn=%f tst=%f\n',e0,e1); 
 
end; % cvi
 
%  subplot(2,2,1); visualizeData(xs0,2,hs0);
%  subplot(2,2,2); visualizeData(xs0,2,hsPr0);
%  subplot(2,2,3); visualizeData(xs1,2,hs1);
%  subplot(2,2,4); visualizeData(xs1,2,hsPr1);

return
%%% 
% Classify by Angles
[u0,s0,v0]      = svd(x0,'econ');
[u1,s1,v1]      = svd(x1,'econ');

cs0             = cumsum(diag(s0)); cs0 = cs0./cs0(end);
cs1             = cumsum(diag(s1)); cs1 = cs1./cs1(end);
vectNum         = min(sum(cs0<0.8),sum(cs1<0.8));


figure(5),plot(v0(:,1:vectNum)),title('v0')
figure(6),plot(v1(:,1:vectNum)),title('v1')

A = orth(x0');
B = orth(x1');
s = svd(A'*B);
a = acos(min(s));

fprintf('Subspace Angle=%f \n',a); 



