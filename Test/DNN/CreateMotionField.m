function [xTrain,yTrain] = CreateMotionField(xTrain,yTrain,chanNum)
% build motion from training examples
[nR,nC,nD,nT] = size(xTrain);
assert(nD==1);
assert(nT>1);

% rep
yTrain         = double(yTrain);
xTrain         = repmat(xTrain,[1,1,chanNum,1]);


% motion fields
angL             = linspace(-10,10,chanNum);
angR             = linspace(10,-10,chanNum);
for m = 1:nT
    yTrain(m) = rem(yTrain(m),2);
    if yTrain(m) > 0.5 
        ang     = angL;
    else
        ang     = angR;
    end
    for a = 1:chanNum
        xTrain(:,:,a,m) = imrotate(xTrain(:,:,a,m),ang(a),'bilin','crop');
    end
end
yTrain  = categorical(yTrain);
xTrain  = reshape(xTrain,[nR,nC*chanNum,1,nT]);
