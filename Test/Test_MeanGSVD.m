% Test_MeanGSVD  - Test vector signal estimation
% from many noise samples.
% Ussume gradient info is known. Signal gradients are higher than noise.

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 17.06 23.03.14 UD     Improving the formula 
%-----------------------------


%%%
% Params
%%%
sigGenType  = 2;

figNum      = 1;  % show


%%%
% Sig Gen
%%%
switch sigGenType,
    case 0,  % noise only
        N       = 1024; % sig len
        M       = 3;    % number of informative signals
        K       = 5;   % number of unrelevant signals
        sigma   = 0.1;  % noise sigma
        
        X       = zeros(N,K+M);
        X       =  X + randn(size(X))*sigma;
    
    case 1,  % sinus
        N       = 1024; % sig len
        M       = 3;    % number of informative signals
        K       = 5;   % number of unrelevant signals
        sigma   = 0.1;  % noise sigma
        
        s       = mean(sin(2*pi*linspace(0,1,N)'*[5 7]),2);
        X       = [repmat(s,1,M) zeros(N,K)];
        X       =  X + randn(size(X))*sigma;
        
    case 2,  % exponents
        N       = 1024; % sig len
        M       = 3;    % number of informative signals
        K       = 15;   % number of unrelevant signals
        sigma   = 0.1;  % noise sigma
        
        t       = (1:N)';
        t0      = [round(N/10) round(N/5) round(N/5*4)];
        s       = zeros(N,1);
        for m = 1:length(t0)
           s    = s + double(t > t0(m)).*exp(-(t-t0(m))/9); 
        end
        X       = [repmat(s,1,M) zeros(N,K)];
        X       =  X + randn(size(X))*sigma;
        
    otherwise error('sigGenType')
end

figure(figNum)
plot(X)
title('Input vectors')

%%%
% Compute matrices for GSVD
%%%
[N,numV]   = size(X);

% signal by remove noise
Z          = X;
noiseStd   = mean(std(Z));
Z(abs(Z) < noiseStd*3) = 0;

% gradient
%Z          = X*0;
dt         = 1:N-2;
Z(dt,:)    = Z(dt+2,:)- Z(dt,:);



A          = Z'*Z;

% Formula for SNR
% max a'*X'X*a/Tr((X-X*a1')*(X-X*a1')')
%  a
%
% assume that X*1 = 0
% we get GSVD
%
% max a'*X'X*a/a'*(Tr(X'X)-N*X'X)*a
%  a : |a|^2 = 1



% normalize X
Y          = X - repmat(mean(X,2),1,numV);
%Y          = Y*diag(1./std(Y));

%B          = numV*eye(numV) + Y'*Y;
%B          = diag(std(Y).^2) + Y'*Y;
B          = sum(std(Y).^2)*eye(numV) + N*Y'*Y;

%%%
% Find optimal coeff
%%%
% gsvd
[U,V,X,C,S] = gsvd(A,B);
eVal        =  sqrt(diag(C'*C)./diag(S'*S));
X(:,[1 2 3 numV]),
%U(:,[1 numV]),

% % eig - not working well
% [Ub,Sb]     = eig(B);
% Sinv        = diag(1./sqrt(diag(Sb)));
% A2          = Sinv*Ub'*A*Ub*Sinv;
% 
% [Ua,Sa]     = eig(A2);
% sVal        = diag(Sa)
% Ua

% % svd - not working
% [Ub,Sb,Vb]  = svd(B);
% Sinv        = diag(1./diag(Sb));
% A2          = Sinv*Vb'*A*Vb*Sinv;
% 
% [Ua,Sa,Va]  = svd(A2);
% sVal        = diag(Sa)
% Ua

ind             = [1 2 3 numV-1 numV];
figure(figNum+1)
plot(X(:,ind)),legend(num2str(eVal(ind)))
title('Segmentation')








