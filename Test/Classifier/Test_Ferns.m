% Test_Ferns  - Test fern classifier with sequential data training

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 19.05 16.09.14 UD     created 
%-----------------------------


%%%
% Params
%%%
testType    = 4;
figNum      = 1;  % show


%%%
% Data Define
%%%


switch testType,
    case 1,  % noise only
        DataNum     = 32; % data size
        ClassNum    = 2;    % pattern number - H
        FeatDim     = 5;    % feature dimension
        TrainNum    = 2;    % training data number
        DataVar     = 4;    % define data variation spread
        Sigma       = 0.01;  % noise sigma
        S           = 8;
        M           = 20;
        
    case 2,  % more
        DataNum     = 64;   % data size
        ClassNum    = 3;    % pattern number - H
        FeatDim     = 5;    % feature dimension
        TrainNum    = 4;    % training data number
        DataVar     = 2;    % define data variation spread
        Sigma       = 0.01;  % noise sigma
        S           = 10;
        M           = 20;
        
    case 3,  % more
        DataNum     = 128;   % data size
        ClassNum    = 6;    % pattern number - H
        FeatDim     = 5;    % feature dimension
        TrainNum    = 4;    % training data number
        DataVar     = 2;    % define data variation spread
        Sigma       = 0.05;  % noise sigma
        S           = 10;
        M           = 4;
        
    case 4,  % more
        DataNum     = 256;   % data size
        ClassNum    = 8;    % pattern number - H
        FeatDim     = 6;    % feature dimension
        TrainNum    = 4;    % training data number
        DataVar     = 8;    % define data variation spread
        Sigma       = 0.05;  % noise sigma
        S           = 10;
        M           = 8;
        
    otherwise error('sigGenType')
end

%%% 
% Prepare data
%%%

% class vectors
featVect    = randi(DataVar,ClassNum,FeatDim);
featVect    = (featVect - 1)./DataVar;  % 0:1 range
classVect   = (1:ClassNum)';

% replicate
featMtrx    = kron(featVect, ones(DataNum,1));
classVect   = kron(classVect,ones(DataNum,1));
featNum     = size(featMtrx,1);

% add noise
featMtrx    =  featMtrx + randn(size(featMtrx))*Sigma;


%%% 
% Classify Ferns
%%% 
%fernPrm         = struct('S',8,'M',50,'thrr',[0.0 1],'bayes',0,'H',8);
fernPrm         = struct('S',S,'M',M,'thrr',[0 1],'bayes',1,'H',8,'ferns',[]);
fernPrmW        = struct('S',S,'M',M,'thrr',[0 1],'bayes',1,'H',8,'ferns',[]);


% define train and test sets
for m = 1:TrainNum,
    randInd             = randperm(featNum);
    trainNum            = ceil(featNum*3/4);

    trainInd            = randInd(1:trainNum);
    testInd             = randInd(1+trainNum:featNum);

    hs0                 = classVect(trainInd); 
    hs1                 = classVect(testInd); 
    xs0                 = featMtrx(trainInd,:);
    xs1                 = featMtrx(testInd,:);

    % gen class
    tic, [ferns,hsPr0]  = fernsClfTrain(xs0,hs0,fernPrm); %toc
    tic, [hsPr1,cProb]  = fernsClfApply(xs1, ferns ); %toc
    e0                  = mean(hsPr0~=hs0); e1=mean(hsPr1~=hs1);
    fernPrm.ferns       = ferns;
    
    % show
%     figure(1),imagesc(xs0),title('x0')
%     figure(2),imagesc(xs1),title('x1')
    fprintf('Round %2d: Fern  errors trn=%f tst=%f\n',m,e0,e1); 
    
    % weighted class
    tic, [ferns,hsPr0]  = fernsClfTrainW(xs0,hs0,fernPrmW); %toc
    tic, [hsPr1,cProb]  = fernsClfApplyW(xs1, ferns ); %toc
    e0                  = mean(hsPr0~=hs0); e1=mean(hsPr1~=hs1);
    fernPrmW.ferns      = ferns;

    fprintf('Round %2d: FernW errors trn=%f tst=%f\n',m,e0,e1); 
    
end





return




