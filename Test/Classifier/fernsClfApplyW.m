function [hs,probs] = fernsClfApplyW( data, ferns, inds )
% Apply learned fern classifier - using weigths.
%
% USAGE
%  [hs,probs] = fernsClfApply( data, ferns, [inds] )
%
% INPUTS
%  data     - [NxF] N length F binary feature vectors
%  ferns    - learned fern classification model
%  inds     - [NxM] cached inds (from previous call to fernsInds)
%
% OUTPUTS
%  hs       - [Nx1] predicted output labels
%  probs    - [NxH] predicted output label probabilities
%
% EXAMPLE
%
% See also fernsClfTrain, fernsInds
%
% Piotr's Image&Video Toolbox      Version 2.50
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]
if( nargin<3 || isempty(inds) )
    inds = fernsInds(data,ferns.fids,ferns.thrs); 
end


% UD - compute when needed
% convert fern leaf class counts into probabilities
if( ferns.bayes<=0 )
  norm          = 1./sum(ferns.pFern,2);
  ferns.pFern   = bsxfun(@times,ferns.pFern,norm);
else
  norm          = 1./sum(ferns.pFern,1);
  ferns.pFern   = bsxfun(@times,ferns.pFern,norm);
  %ferns.pFern   = log(ferns.pFern);
end

% define prob for all M ferns
[N,M]           = size(inds); 
H               = ferns.H; 
probs           = zeros(N,H);
probf           = zeros(N,H,M); % UD
wghts           = ferns.wghts;
for m = 1:M, 
    probs        = probs + ferns.pFern(inds(:,m),:,m).*wghts(m); 
    probf(:,:,m) = ferns.pFern(inds(:,m),:,m);  
end
% UD the next line does not contribute much
if(ferns.bayes<=0), probs=probs./M; end; 

% output
[~,hs]          = max(probs,[],2);
probs           = probf; % weight calculation

end
