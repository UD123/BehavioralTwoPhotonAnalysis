%function nameConvert(D
% Renames files that have signature : XXX_A.tif to file XXX_00A.tif
% where A is a number from 1-999


% default
filePattern  = '.avi';
DataDir      = 'C:\LabUsers\Uri\Data\Janelia\Videos\M75\2_21_14\';  % current directory

% get all files in the daat directory
direc       = dir([DataDir filesep '*' filePattern]);
fileNum     = length(direc);
if fileNum<1
    error('Can not find tif files in the directory %s',DataDir)
end
[filenames{1:fileNum,1}] = deal(direc.name);

searchStr       = ['_(\d{1,2})(\',filePattern,')+'] ; % not starting with zero
replaceStr      = ['_%03d',filePattern];

% start replace
for m = 1:fileNum,
    [startIndex,endIndex] = regexp(filenames{m},searchStr);
    
    if isempty(startIndex),
        fprintf('File name %s does not match expected pattern XXX_A%s\n',filenames{m},filePattern)
        continue
    end
    
    [fileDigit,ok]     = str2num(filenames{m}(startIndex+1:endIndex-4));
    if ~ok,
        error('Can not detect last digit A in the file %s (pattern XXX_A%s)',filenames{m},filePattern)
    end
       
    % put format string
    fileNewNamePattern = regexprep(filenames{m},searchStr,replaceStr);
    fileNewName        = sprintf(fileNewNamePattern,fileDigit); % extend with zeros
    
    % rename
    system(['rename ',fullfile(DataDir,filenames{m}),' ',fileNewName]);
    
end


