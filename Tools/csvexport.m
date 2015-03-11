function out=csvexport(filename,cellVals)

% (C) Nov 25, 2014, Pratik Chhatbar, Feng Lab
% MUSC Stroke Center, Charleston, SC
% chhatbar@musc.edu, pratikchhatbar@gmail.com

out=0;
if length(filename)<5 || ~strncmp(filename(end-3:end),'.csv',4)
    outfile=[filename '.csv'];
else
    outfile=filename;
end

fh = fopen(outfile,'w'); % open a file with write privileges, will overwrite old versions
for ii = 1:size(cellVals,1)
    for  jj = 1:size(cellVals,2)
        if jj==1
            addcoma=[];
        else
            addcoma=', ';
        end
        if ischar(cellVals{ii,jj})
            fwrite(fh,[addcoma,cellVals{ii,jj}]);
        else
            fwrite(fh,[addcoma,num2str(cellVals{ii,jj},'%f')]);
        end
    end
    fwrite(fh,sprintf('\r\n')); % print line break
end
fclose(fh); % close file out when done writing
out=1;
