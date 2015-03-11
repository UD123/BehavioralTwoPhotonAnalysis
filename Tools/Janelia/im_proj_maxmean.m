function frame_proj = im_proj_maxmean(frames, len_filter)
%method to project multiple frames to single frame in 2 steps: 1) biggest pixel at each position; 2) remove the mean

%input: mutliple frames in 3-d matrix and length of averaging along 3ed dims
%       filter length(optional, default = 5)

%created by Wenzhi, 8/28/2012

frame_proj = [];

if nargin < 2, len_filter = 5; end
if isempty(frames), return; end

nsize = size(frames);
if ndims(frames) < 3
    fprintf('this is not a 3-d image stack!');
    return; 
end %this is not a 3-d image stack.

if (nsize(3) < len_filter)
    fprintf('too few frames to do average!');
    return;
end %too few frames to do average.

frames = smooth3(frames, 'box', [1 1 len_filter]);

frames = sort(frames, 3, 'descend');
frame_proj = frames(:,:,1) - mean(frames(:));
frame_proj(frame_proj(:)<0) = 0;

return;