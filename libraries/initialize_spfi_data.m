function [spfi, spfi_selections] = initialize_spfi_data(params)
    %combine contrast measurements for all FOVs into single table called spfi
    %we allow to select up to 5 groups of points in spfi_selections in
    %spfi_plot.m (see this function for workflow)
    %spfi_selections is structure variable that saves indices of points in the selection as spfi_selections(i).indices

    %load candidates data
    load([params.fpath, 'candidates.mat'], "candidates");

    %get the total number of candidates, only consider 'valid' FOVs
    num_candidates_total = 0;
    for f = params.valid_fovs
        num_candidates_total = num_candidates_total + candidates(f).num_candidates;
    end

    %collect all contrast values into one big array
    arr = zeros(params.twocolor_iscat + params.num_iscat_chans + params.num_fluo_chans, num_candidates_total);
    
    i0 = 1;
    for f = params.valid_fovs
        candidate_in_FOV = candidates(f).num_candidates;      %num cnddts in FOV
    
        if params.twocolor_iscat
            %get the combined wavelength size measurement
            arr(1, i0:i0+candidate_in_FOV-1) = candidates(f).iscat_ctr;
        end
    
        for c = 1:params.num_iscat_chans
            %add all iSCAT contrasts
            arr(params.twocolor_iscat+c, i0:i0+candidate_in_FOV-1) = candidates(f).iscat(c).ctr;
        end  
    
        for c = 1:params.num_fluo_chans
            %add all label intensities
            arr(params.twocolor_iscat+params.num_iscat_chans+c, i0:i0+candidate_in_FOV-1) = ...
                candidates(f).fluo(c).ctr;
        end
        
        i0 = i0+candidate_in_FOV;
    end

    %create labels for the data
    labels = cell(1, size(arr, 1));
    if params.twocolor_iscat
        labels{1} = 'SP';
    end
    
    for c = 1:params.num_iscat_chans
        labels{params.twocolor_iscat+c} = ['iSCAT', num2str(params.channel_wavelengths(c)*1e9)];
    end  
    
    for c = 1:params.num_fluo_chans
        labels{params.twocolor_iscat+params.num_iscat_chans+c} = ...
            params.lbl_names{c};
    end
    
    %print out the channel mapping
    fprintf(1, 'SPFI channel indices:\n')
    for i = 1:numel(labels)
        fprintf([sprintf('%02d', i), ' -> ' labels{i}, '\n']);
    end
    
    %put into table
    %transpose so features (channels) are rows and observations (EVs) are columns
    spfi = array2table(arr', 'VariableNames', labels);
   
    save([params.fpath, 'spfi.mat'], 'spfi');
end
