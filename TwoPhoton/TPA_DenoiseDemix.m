function strROI = TPA_DenoiseDemix(strROI,imTwoPhoton)

[nR,nC,nT]      = size(imTwoPhoton);
n_clust         = length(strROI);
mergedROI       = false(nR*nC,n_clust);
for k = 1:n_clust
    mergedROI(strROI{k}.PixInd,k) = true;
end


%% params
overlap_thresh = 0.1;

%%
if exist('embedding','var')
    embedding_all = [embedding.Psi];
end

tmp_bkgnd = reshape(imTwoPhoton,[],nT);
doSizeThresh = true;
%% calculate spatial overlap between ROIs
overlap = double(mergedROI)'*double(mergedROI);
% remove diagonal
overlap(1:n_clust+1:n_clust^2) = 0;
% make overlap relative to ROI size
overlap = rdivide(overlap, sum(mergedROI)');

% ignore overlaps smaller than threshold
overlap(overlap < overlap_thresh) = 0;
% number of overlapping ROIs for every ROI
num_overlap = sum(overlap > overlap_thresh,2);
% sort ROIs in increasing percentage of overlap
[~,denoise_inds] = sortrows([num_overlap, sum(overlap,2)]);

% intialize output structs
% ROI_wavelet = zeros(n_clust,nT); % weighted wavelet denoised delta_F over F
% F           = zeros(n_clust,nT); % F
% baseline    = zeros(n_clust,N_TRIALS); % baseline of F
% mean_clust  = zeros(n_clust,nT); % weigthed average time-series (no denoising)
% mean_clust_orig = zeros(n_clust,nT); % avergae time-series (no denoising)
%temp2D = zeros(NROWS,NCOLS);

overlap2 = overlap;
k =0;
% iterate over all ROIs starting with "pure" ROIs
while k < n_clust
    k = k+1;
    
    % get first ROI in list and remove it
    i = denoise_inds(1);
    denoise_inds(1) = [];
    temp_trace = zeros(1,nT);
    % all timeseries of pixels belonging to the ROI
    tmp_clust = tmp_bkgnd(mergedROI(:,i),:);
    
    % pixel indices belonging to ROI
    pix_inds = find(mergedROI(:,i));
    % any overlapping pixels with remaining ROIs in list
    all_others = mergedROI(pix_inds,denoise_inds);
    pix_overlap = any(all_others,2);
    
    % dson't remember why `if' has both arguments
    if num_overlap(i) > 0 && sum(pix_overlap) > 0
        % calculate first principal component of ROI
        [~,score1,latent1,~,explained1,~]=pca(tmp_clust,'NumComponents',1);
        % extract sub-matrix corresponding to pure pixels
        if sum(overlap2(i,:)) < 0.5
            thresh_sign = -median(sign(score1(pix_overlap)));
        else
            thresh_sign = median(sign(score1(~pix_overlap)));
        end
        clst1 = tmp_clust(sign(score1)==thresh_sign,:);
        
        % decrease 1 from all ROIs this ROI overlaps with
        num_overlap(overlap(:,i) > 0) = num_overlap(overlap(:,i) > 0) - 1;
        overlap2(:,i) = 0;
        
        % recalculate sorted list of ROIs based on overlap
        [~,new_inds] = sortrows([num_overlap(denoise_inds),sum(overlap2(denoise_inds,:),2)]);
        denoise_inds = denoise_inds(new_inds);
    else
        clst1 = tmp_clust;
    end
    
    % calculate weight of each pixel as its association with the ROI based
    % on embedding (prefer to move this to struct itself so not load embedding every time)
    % this is problematic when using sub-regions, need to think about it
    if ~exist('embedding_all_regions','var') && exist('embedding_all','var')
        s = sum(embedding_all(mergedROI(:,i),: )).^2 ;
        tempPsi = embedding_all(mergedROI(:,i),(s/max(s)>0.1));
        weight = sum(tempPsi.^2,2);
    else
        weight = ones(length(pix_inds),1);
    end
    %temp2D(mergedROI(:,i)) = weight;
    weight = weight/sum(weight);
    
    % calculate projection on to first PC of `pure pixels'
    %if num_overlap(i) > 0 && sum(pix_overlap) > 0
    [U,S,V] = svd(clst1);
    proj = V(:,1)*V(:,1)';
    tmp_clust = tmp_clust*proj;
    % remove activity of ROI
    tmp_bkgnd(mergedROI(:,i),:) = max(0,tmp_bkgnd(mergedROI(:,i),:) - tmp_clust);
    %end
    
    % trial-based wavelet denoising with spin_cycling
    
    shift = 4;
    lev = 7;
    
    X = zeros(1,nT);
    mean_clust = weight'*tmp_clust;
    
    % rewrite this as wavelet decomposition of all time shifts
    % ot of all trials at once
    parfor nn = -shift:shift
        clst_shift = circshift(mean_clust,[0 nn]);
        [XD,~] = wden(clst_shift,'sqtwolog','h','sln',lev,'db4');
        x_temp = circshift(XD,[0, -nn]);
        X = X + x_temp;
    end
    X(X(:)<0)=0;
    F_kt = X /(2*shift+1);
    
    %         % calculate dF/F
    %         thresh = quantile(F_kt,0.1);
    %         clustBaseInds = (F_kt <= thresh);
    %         baseline(i,trial_ind) = mean(F_kt(clustBaseInds(:)));
    %         if baseline(i,trial_ind) <1e-2
    %             baseline(i,trial_ind) = 1;
    %         end
    %         temp_trace(:,time_inds) = (F_kt - baseline(i,trial_ind))./baseline(i,trial_ind);
    %         F(i,time_inds) = F_kt;

    strROI{k}.Data(:,1) = F_kt(:);
end


%%