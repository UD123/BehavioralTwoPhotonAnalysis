% function DTP_TestROI
%% Testing ROI  

%-----------------------------
% Ver       Date        Who     Descr
%-----------------------------
% 00.01     03.07.12    UD     starting
%-----------------------------


%%%
% Params
%%%
imDir           = 'D:\5_11_12\TSeries-11052012-1415-014\';
imNamePattern   = '*_Ch2_*.tif';        % pattern that matches image names
delayBaseLine   = 10;                   % number of frames for delay
timeAverFiltLen = 4;                    % number of frames for time averaging
spatAverFiltLen = 3;                    % spatial averaging filter size 3 x 3
Fs              = 1;                    % image sample rate

% show
figPreviewNum   = 1;                    % set 0 to close preview
figAverNum      = 1;                    % set 0 to close average show


%%%
% Check image names
%%%
imNameTest      = fullfile(imDir,imNamePattern);
imDirec         = dir(imNameTest); filenames = {};
imNum           = length(imDirec);
if imNum < 1,
    errordlg('Can not find images in specified directory. Check directory name');
    return
end;

[imFilenames{1:imNum,1}]    = deal(imDirec.name);
% check image params
imName                      = fullfile(imDir,imFilenames{1});
imFrame                     = imread(imName);
[imRowNum,imColNum]         = size(imFrame);

imStack                     = zeros(imRowNum,imColNum,imNum,class(imFrame));

% preview

for k=1:imNum, 
    imName = fullfile(imDir,imFilenames{k});
    imFrame = imread(imName);
    imStack(:,:,k)      = imFrame;
    
    if figPreviewNum > 0,
        figure(figPreviewNum),
        imagesc(imFrame,[0 1200]);  colormap(gray); colorbar;  
        title(imFilenames{k},'interpreter','none')
        pause(0.4);
    end;
end;


[x,y,BW,xi,yi] = roipoly;



%%%
% Process 
%%%
% spatial averaging filter
filtSpatAver    = fspecial('average',[spatAverFiltLen spatAverFiltLen]);
filtTimeAver    = zeros(1,1,timeAverFiltLen);
filtTimeAver(1,1,:)    = hamming(timeAverFiltLen)';
filtAver3D      = repmat(filtSpatAver,[1 1 timeAverFiltLen]);
filtAver3D      = repmat(filtTimeAver,[spatAverFiltLen spatAverFiltLen 1]).*filtAver3D;
% make it integer
%filtAver3D      = filtAver3D; %uint16(4096*filtAver3D); %./sum(filtAver3D(:));

%imStackBL       = imStack*0;

% spatial averaging
imStackBL       = imfilter(imStack,filtAver3D,'symmetric');


% preview
if figAverNum > 0,
figure(figAverNum),

for k=1:imNum, 
    imagesc(imStackBL(:,:,k),[0 1200]);  colormap(gray); colorbar;  
    title(imFilenames{k},'interpreter','none')
    pause(0.2);
end;
end;


return;

for k=1:imNum,
    
    % spatial averaging
    imStack(:,:,k) = imfilter(imStack,filtAver3D,'symmetric');

end;
