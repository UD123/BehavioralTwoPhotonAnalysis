function [output frames_reg] = im_reg_dft(frame_ref, frames, usfac)

% Using dftregistration.m to register imagies from multiple frames.

% input: ref frame, frames to be registered and usfac (optional) ppsampling factor (integer). Images will be registered to 
% within 1/usfac of a pixel. For example usfac = 20 means the images will be registered within 1/20 of a pixel. (default = 1)

% output =  [error,diffphase,net_row_shift,net_col_shift]
% error     Translation invariant normalized RMS error between f and g
% diffphase     Global phase difference between the two images (should be
%               zero if images are non-negative).
% net_row_shift net_col_shift   Pixel shifts between images
% frames_reg (Optional) registered version of frames, the global phase difference and Pixel shifts are compensated for.

% created by Wenzhi, 8/28/2012

if nargin < 3, usfac = 1; end

nsize = size(frames);

if ndims(frames)<3
   frame_reg = frames;    
   nsize(3) = 1; %changed on 2/1/2013, wenzhi
end
frames_reg = zeros(nsize);
% for j=1:nsize(3);
% use paralell computering 12/13/2012
output = zeros(4, nsize(3));

%to use maxium workers at local
% myCluster = parcluster('local');
% nworkers = myCluster.NumWorkers;

% isOpen = matlabpool('size') > 0;
% if isOpen
%     disp('The resource requested is being used ...');
%     return;
% end
% matlabpool open local;
parfor j=1:nsize(3);
%for j=1:nsize(3),    
   [output(:,j), fft_frame_reg]  = dftregistration(fft2(double(frame_ref)),fft2(double(frames(:,:,j))),usfac);
   frames_reg(:,:,j) = abs(ifft2(fft_frame_reg));
end
% matlabpool close;
return;