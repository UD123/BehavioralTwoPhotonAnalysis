% Increate Data Size using Augment

%-----------------------------
% Ver	Date	 Who	Descr
%-----------------------------
% 27.01 14.10.17 UD     Created .
%-----------------------------

%% load data
[XTrain,YTrain] = digitTrain4DArrayData;

%% select small training set and large test set
[uv,ia,ic]      = unique(YTrain);
sampNum         = 4;
repNum          = 16;
batchNum        = sampNum * repNum;
b               = false(size(ic));
for k = 1:length(uv)
    b(find(YTrain == uv(k),sampNum,'first')) = true;
end
xTest           = XTrain(:,:,:,~b);
yTest           = YTrain(~b);
xTtrain         = XTrain(:,:,:,b);
yTtrain         = YTrain(b);
xTtrain         = repmat(xTtrain,[1,1,1,repNum]);
yTtrain         = repmat(yTtrain,[repNum,1]);
% check
figure,montage(xTtrain(:,:,:,randi(numel(yTtrain),[1 16])))


%% define aug
%imageAugmenter = imageDataAugmenter('RandRotation',[-20 20]); % Working
%imageAugmenter = imageDataAugmenter('RandXScale',[0.7 1.2],'RandYScale',[0.7 1.2]);
imageAugmenter = imageDataAugmenter('RandXScale',[1 1],'RandYScale',[1 1]);

imageSize = [28 28 1];
datasource = augmentedImageSource(imageSize,XTrain,YTrain,'DataAugmentation',imageAugmenter)

%% build net
layers = [
    imageInputLayer([28 28 1])
    
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
        
    fullyConnectedLayer(10)
    softmaxLayer
    classificationLayer];

%% train
opts = trainingOptions('sgdm', ...
    'MaxEpochs',10, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{xTest,yTest},...
    'MiniBatchSize',batchNum,...
    'InitialLearnRate',1e-3);

net = trainNetwork(datasource,layers,opts);


%% Test
[XTest,YTest]   = digitTest4DArrayData;
figure,montage(XTest(:,:,:,randi(numel(YTest),[1 16])))


%% Check
pTest = classify(net,XTest);
accuracy = mean(pTest == YTest)
