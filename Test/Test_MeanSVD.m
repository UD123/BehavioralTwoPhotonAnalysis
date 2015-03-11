% Test_MeanGSVD  - Test vector signal estimation
% from many noise samples.
% Ussume gradient info is known. Signal gradients are higher than noise.

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 17.07 24.03.14 UD     GSVD is not working well - SVD 
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
% Compute matrices for SVD
%%%
[N,numV]   = size(X);

% signal by remove noise

% Formula for SNR
% max a'*X'X*a/Tr((X-X*a1')*(X-X*a1')')
%  a
%
% assume that X*1 = 0
% we get GSVD
%
% max a'*X'X*a/a'*a
%  a : |a|^2 = 1

% normalize X
Y          = X - repmat(mean(X,2),1,numV);
%Y          = Y*diag(1./std(Y));

%%%
% Find optimal coeff
%%%
% svd
[U,S,V]     = svd(Y);
S           = diag(S);

ind             = [1 2 3 numV];
figure(figNum+1)
plot(U(:,ind)),legend(num2str(S(ind)))
title('Time Vectors')
figure(figNum+2)
plot(V(:,ind)),legend(num2str(S(ind)))
title('Segmentation')








