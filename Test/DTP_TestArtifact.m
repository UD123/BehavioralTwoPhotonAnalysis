% function DTP_TestArtifact
%% Testing artifact computation procedure  

%-----------------------------
% Ver       Date        Who     Descr
%-----------------------------
% 11.08     13.08.13    UD     prooooove the validity of computationss
% 00.01     03.07.12    UD     starting
%-----------------------------


%%%
% Params
%%%
nT1                 = 100;  % frame num
lineLen1            = 1;  
M                   = 5;   % signal


% define ROI data

N                   = nT1;
F1                  = sin((1:N)'./N*2*pi*5)*20     + .02 *randn(N,1) + 100 + linspace(200,100,N)';
F2                  = sin((1:N)'./N*2*pi*5)*10     + .02 *randn(N,1) + 200;
F2(40+(1:M))        = F2(40+(1:M)) + 50*hamming(M) ;


mtrxTime            = repmat(1:nT1,lineLen1,1)';
mtrxConst           = ones(lineLen1,nT1)';
meanROI1            = F1;
meanROI2            = F2;

% build matrix for 
F2                  = meanROI2(:);  % columnwise
F1T1                = [meanROI1(:) mtrxTime(:) mtrxConst(:)];

% find coeff
coeff               = pinv(F1T1)*F2;

% remove effect
F2predict           = F1T1*coeff;
% predicted values
meanROI2predict     = reshape(F2predict,nT1,lineLen1);

% recove dim back
meanROI1            = meanROI1;
meanROI2fixed       = meanROI2 - meanROI2predict;

% add predicted base line back
meanROI2fixedBL     = meanROI2fixed + repmat(mean(meanROI2predict,1),nT1,1);


% show coeff
%DTP_ManageText([], sprintf('ROI %d : Alpha %5.3f, Gamma %5.3f, Betta %5.3f ',1,coeff(1),coeff(2),coeff(3)),  'I' ,0)


figure,
plot([meanROI1 meanROI2predict meanROI2 meanROI2fixed, meanROI2fixedBL])
legend('ROI1','ROI1 Predict','ROI2','ROI2-ROI1 Predict','Sig + BL')
ylabel('Fluor.')
xlabel('Frames')
title('Ch2 Ch1 artifact removal')

