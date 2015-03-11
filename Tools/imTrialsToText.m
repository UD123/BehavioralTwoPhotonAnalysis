function imTrialsToText(DataDir, FileBaseName, inclFiles, outPath,...
    outName, chans, chanKeeper)

%DataDir - self-explanatory, no filesep at end
%FileBaseName - wildcard, e.g. *main*
%inclFiles - vector of files to include by their numbering in the
%directory, e.g. [1:50] includes the first 50 files. Leve empty for ALL
%outPath - where you want the text files to go
%outName - what you want the textfile called, '+_chan1/2'
%chans - how many channels?
%chanKeeper - vector, e.g. [1 2] of the channels to keep...works only for
%two channels now

%default
DataSize = [512 512];

%generate xy indices for these images
colIndsPix=repmat(1:DataSize(1),1,DataSize(1));
rowIndsPix=repmat(1:DataSize(1),[DataSize(2),1]);
rowIndsPix=rowIndsPix(:);
z=ones(size(rowIndsPix));
files = dir([DataDir filesep FileBaseName '*tif*']);

if isempty(inclFiles)
    
    FileNums = 1:numel(files);
else
    FileNums = 1:numel(files);
    FileNums=FileNums(inclFiles);
end

%output arrays. +3 is for the xys coords
finalData{1}=zeros(prod(DataSize),numel(files)+3); %chan1 raw
finalData{2}=finalData{1};                         %chan2 raw
d1=zeros(size(finalData{1}));                      %delta chan1
d2=zeros(size(finalData{2}));                      %delta chan2
d1_d=zeros(size(finalData{1}));                    %delta chan1/ chan1
d2_d=zeros(size(finalData{2}));                    %delta chan2/ chan2

%get info for first file and just assume all the rest look like this
FileTif=[DataDir filesep files(1).name];
InfoImage=imfinfo(FileTif);

%for datasize, assume all images look like the first
DataSize(1)=InfoImage(1).Width;
DataSize(2)=InfoImage(1).Height;

%pre-allocate outputs
finalData_chan1=zeros(DataSize(1)*DataSize(2),numel(FileNums)*(numel(InfoImage)/chans),'uint8');
finalData_chan2=finalData_chan1;

%loop to populate arrays
imCountBegin=1;
for ii=1:numel(FileNums)
    ii
    %stack info
    FileTif=[DataDir filesep files(ii).name];
    InfoImage=imfinfo(FileTif);
    mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height;
    NumberImages=length(InfoImage);
    imCountEnd=imCountBegin+((NumberImages/chans)-1);
    
    %load the stack
    FileID=tifflib('open',FileTif,'r');
    rps = tifflib('getField',FileID,Tiff.TagID.RowsPerStrip);
    
    imData=zeros(nImage,mImage,NumberImages,'uint8');
    
    % Go through each strip of data and load.
    for m=1:1:NumberImages
        tifflib('setDirectory',FileID,m-1);
        rps = min(rps,nImage);
        for r = 1:rps:nImage-rps
            row_inds = r:min(nImage,r+rps-1);
            stripNum = tifflib('computeStrip',FileID,r);
            imData(row_inds,:,m) = tifflib('readEncodedStrip',FileID,stripNum);
        end
    end
    
    %split channels ---
    if numel(chanKeeper)==1
        %reshape to a 1-vect
        index=1:2:numel(InfoImage);
        finalData_chan1(:,imCountBegin:imCountEnd)=reshape(imData(:,:,index),DataSize(1)*DataSize(2),numel(InfoImage)/chans);
    else
        %%CHANNEL 1
        
        %reshape to a 1-vect
        index=1:2:numel(InfoImage);
        finalData_chan1(:,imCountBegin:imCountEnd)=reshape(imData(:,:,index),DataSize(1)*DataSize(2),numel(InfoImage)/chans);
        
        %%CHANNEL 2
        
        %reshape to a 1-vect
        index=2:2:numel(InfoImage);
        finalData_chan2(:,imCountBegin:imCountEnd)=reshape(imData(:,:,index),DataSize(1)*DataSize(2),numel(InfoImage)/chans);
        
    end
 tifflib('close',FileID);
 clear imData
 imCountBegin=imCountEnd;
end


%averages across time
mean_1=uint8(repmat(mean(finalData_chan1,2),1,(numel(FileNums)*(numel(InfoImage)/chans))));
d1=finalData_chan1-mean_1;
d1_d=d1./finalData_chan1;
dG_r=d1./finalData_chan2;
clear mean_1

mean_2=uint8(repmat(mean(finalData_chan2,2),1,(numel(FileNums)*(numel(InfoImage)/chans))));
d2=finalData_chan2-mean_2;
clear mean_2

%add the pixel indices
finalData_chan1=double(finalData_chan1);
finalData_chan2=double(finalData_chan2);

finalData_chan1(:,1:3)=[colIndsPix' rowIndsPix z];
finalData_chan2(:,1:3)=[colIndsPix' rowIndsPix z];
d1(:,1:3)=[colIndsPix' rowIndsPix z];
d2(:,1:3)=[colIndsPix' rowIndsPix z];
d1_d(:,1:3)=[colIndsPix' rowIndsPix z];


%save the .mats in case of write failure
save([outName '_chan1.mat'],'finalData_chan1');
save([outName '_chan2.mat'],'finalData_chan2');
save([outName '_chan1_d1.mat'],'d1');
save([outName '_chan2_d2.mat'],'d2');
save([outName '_chan1_d1d.mat'],'d1_d');
save([outName '_chan1_dG_R.mat'],'dG_r');

tic
%print to text files using dlmwrite, space delimited
dlmwrite('finalData_chan1.txt',finalData_chan1,'delimiter',' ');
dlmwrite('finalData_chan2.txt',finalData_chan2,'delimiter',' ');
dlmwrite('finalData_chan1_delta.txt',d1,'delimiter',' ');
dlmwrite('finalData_chan2_delta.txt',d2,'delimiter',' ');
dlmwrite('finalData_chan1_deltaD.txt',d1_d,'delimiter',' ');
dlmwrite('finalData_chan1_deltaD.txt',dG_r,'delimiter',' ');
toc

close all
clear all
end

