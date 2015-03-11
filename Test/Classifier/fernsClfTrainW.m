function [ferns,hsPr] = fernsClfTrainW( data, hs, varargin )
% Train random fern classifier - with weights.
%
% See "Fast Keypoint Recognition in Ten Lines of Code" by Mustafa Ozuysal,
% Pascal Fua and Vincent Lepetit, CVPR07.
%
% Dimensions:
%  M - number ferns
%  S - fern depth
%  F - number features
%  N - number input vectors
%  H - number classes
%
% USAGE
%  [ferns,hsPr] = fernsClfTrain( data, hs, [varargin] )
%
% INPUTS
%  data     - [NxF] N length F feature vectors
%  hs       - [Nx1] target output labels in [1,H]
%  varargin - additional params (struct or name/value pairs)
%   .S        - [10] fern depth (ferns are exponential in S)
%   .M        - [50] number of ferns to train
%   .thrr     - [0 1] range for randomly generated thresholds
%   .bayes    - [1] if true combine probs using bayes assumption
%   .ferns    - [] if given reuse previous ferns (recompute pFern)
%
% OUTPUTS
%  ferns    - learned fern model w the following fields
%   .fids     - [MxS] feature ids for each fern for each depth
%   .thrs     - [MxS] threshold corresponding to each fid
%   .pFern    - [2^SxHxM] learned log probs at fern leaves
%   .bayes    - if true combine probs using bayes assumption
%   .inds     - [NxM] cached indices for original training data
%   .H        - number classes
%  hsPr     - [Nx1] predicted output labels
%
% EXAMPLE
%  N=5000; H=5; d=2; [xs0,hs0,xs1,hs1]=demoGenData(N,N,H,d,1,1);
%  fernPrm=struct('S',4,'M',50,'thrr',[-1 1],'bayes',1);
%  tic, [ferns,hsPr0]=fernsClfTrain(xs0,hs0,fernPrm); toc
%  tic, hsPr1 = fernsClfApply( xs1, ferns ); toc
%  e0=mean(hsPr0~=hs0); e1=mean(hsPr1~=hs1);
%  fprintf('errors trn=%f tst=%f\n',e0,e1); figure(1);
%  subplot(2,2,1); visualizeData(xs0,2,hs0);
%  subplot(2,2,2); visualizeData(xs0,2,hsPr0);
%  subplot(2,2,3); visualizeData(xs1,2,hs1);
%  subplot(2,2,4); visualizeData(xs1,2,hsPr1);
%
% See also fernsClfApply, fernsInds
%
% Piotr's Image&Video Toolbox      Version 2.61
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

% get additional parameters and check dimensions
%UD 
dfs={'S',10,'M',50,'thrr',[0 1],'bayes',1,'ferns',[],'H',8};
%dfs={'S',10,'M',50,'thrr',[0 1],'bayes',1,'ferns',[]};
%[S,M,thrr,bayes,ferns]=getPrmDflt(varargin,dfs,1);
[S,M,thrr,bayes,ferns,H]=getPrmDflt(varargin,dfs,1);
[N,F]=size(data); assert(length(hs)==N);
% UD  multi trial support
%H=max(hs); 
%H   = ferns.H;
assert(all(hs>0)); assert(S<=20); assert(max(hs) <= H);

if( isempty(ferns) )
  % create ferns model and compute inds (w/o field pFern)
  thrs  = rand(M,S)*(thrr(2)-thrr(1))+thrr(1);
  fids  = uint32(floor(rand(M,S)*F+1)); 
  inds  = fernsInds(data,fids,thrs);
  %ferns = struct('fids',fids,'thrs',thrs,'bayes',bayes,'H',H,'inds',inds);
  % UD adding total pattern count
  nums  = zeros(1,H);
  wghts = ones(1,M)./M;
  ferns = struct('fids',fids,'thrs',thrs,'bayes',bayes,'H',H,'inds',inds,'nums',nums,'wghts',wghts);
  firstTimeInit = true;
else
  % re-use cached model (will need to recompute pFern)
  %ferns.H=H; %ferns.pFern=[]; inds=ferns.inds; %assert(size(inds,1)==N);
  % UD - support different data size from first init
  inds          = fernsInds(data,ferns.fids,ferns.thrs);
  firstTimeInit = false;
end

% get counts for each leaf for each class for each fern
%UD pFern = zeros(2^S,H,M); edges = 1:2^S;
pFern = zeros(2^S,H,M,'single'); edges = 1:2^S; % save some space
nums  = zeros(1,H);
for h=1:H, 
  inds1     = inds(hs==h,:);
  % UD - multi class with additional training examples
  nums(h)   = size(inds1,1);
  if nums(h) < 1, continue; end;
  for m=1:M, 
      pFern(:,h,m) = histc(inds1(:,m),edges); 
  end
end
% pFern = pFern + bayes;

% % convert fern leaf class counts into probabilities
% if( bayes<=0 )
%   norm  = 1./sum(pFern,2);
%   pFern = bsxfun(@times,pFern,norm);
% else
%   norm  = 1./sum(pFern,1);
%   pFern = bsxfun(@times,pFern,norm);
%   pFern = log(pFern);
% end

% add previous fern info
if ~firstTimeInit,
    pFern           = pFern      + ferns.pFern;
    ferns.nums      = ferns.nums + nums;
else
     pFern           = pFern     + single(1);    
%     ferns.nums      = ones(1,H) + nums; % at least one time has apeeared
    ferns.nums      = nums; % at least one time has apeeared
end

% store pFern and compute output values
ferns.pFern        = pFern; clear pFern;
% if(nargout==2), 
%     hsPr=fernsClfApplyW([],ferns,inds); 
% end

% compute weights
[hsPr,probs]      = fernsClfApplyW([],ferns,inds); 
[~,hsMtrx]        = max(probs,[],2); % max over all classes

hsMtrx            = squeeze(hsMtrx);

errVal            = sum(bsxfun(@ne,hsMtrx,hs),1)./N;
wghts             = (1 - errVal).^2; %log((1 - errVal)./errVal);
ferns.wghts       = wghts ./sum(wghts);

end
