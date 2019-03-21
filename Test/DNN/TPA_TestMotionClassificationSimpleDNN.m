% TPA_TestMotionClassificationSimpleDNN - Test Motion analysis
% using stack of several images.

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 27.01 14.10.17 UD     Created .
%-----------------------------

%% load data
[XTrain,YTrain] = digitTrain4DArrayData;

%% select small training set and large test set
[uv,ia,ic]      = unique(YTrain);
sampNum         = 128;  % number training examples
chanNum         = 4;   % number of channels
repNum          = 16;
batchNum        = 128;
b               = false(size(ic));
for k = 1:length(uv)
    b(find(YTrain == uv(k),sampNum,'first')) = true;
end
xValid         = XTrain(:,:,:,~b);
yValid         = YTrain(~b);
xTrain         = XTrain(:,:,:,b);
yTrain         = YTrain(b);
% check
figure,montage(xTrain(:,:,:,1:9))

%% build motion
[xTrain,yTrain]     = CreateMotionField(xTrain,yTrain,chanNum);
[xValid,yValid]     = CreateMotionField(xValid,yValid,chanNum);
[nR,nC,nD,nT]       = size(xTrain);

%% build net
imageSize       = [nR,nC,nD];

layers = [
    imageInputLayer(imageSize)
    
    convolution2dLayer(3,16,'Padding',1)
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
       
    convolution2dLayer(3,32,'Padding',1)
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
       
    convolution2dLayer(3,64,'Padding',1)
    batchNormalizationLayer
    reluLayer
        
    fullyConnectedLayer(2)
    softmaxLayer
    classificationLayer];

%% train
opts = trainingOptions('sgdm', ...
    'MaxEpochs',32, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{xValid,yValid},...
    'MiniBatchSize',batchNum,...
    'InitialLearnRate',1e-3);

net = trainNetwork(xTrain,yTrain,layers,opts);


%% Test
[XTest,YTest]       = digitTest4DArrayData;

%% build motion
[xTest,yTest]       = CreateMotionField(XTest,YTest,chanNum);
% check
figure,montage(xTest(:,:,:,randi(numel(yTest),[1 9])))

%% Check
pTest               = classify(net,xTest);
accuracy            = mean(pTest == yTest)
