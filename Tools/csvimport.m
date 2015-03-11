function out=csvimport(filename)

% (C) Nov 25, 2014, Pratik Chhatbar, Feng Lab
% MUSC Stroke Center, Charleston, SC
% chhatbar@musc.edu, pratikchhatbar@gmail.com

% line delimiter is \r\n, or 13 10 in sequence
% element delimiter is ', '
fh=fopen(filename);
filenum=fread(fh);
fclose(fh);

rin=find(filenum==13);
nin=find(filenum==10);
cin=find(filenum==44);
sin=find(filenum==32);
csins=intersect(cin+1,sin);
rninn=intersect(rin+1,nin);
% assuming each line has same number of elements
csrninn=sort([csins;rninn]);
lrninn=length(rninn);
lcsins=length(csins);

csvcell=cell(lcsins/lrninn+1,lrninn);

for ii=1:lrninn+lcsins
    if ii==1
        csvcell{ii}=char(filenum(1:csrninn(ii)-2));
    else
        csvcell{ii}=char(filenum(csrninn(ii-1)+1:csrninn(ii)-2));
    end
end

out=csvcell';