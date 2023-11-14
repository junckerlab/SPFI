function gates = get_SPFI_gates(params, spfi_chans)
    
    all_gates = params.iscat_thresh + zeros(1, params.num_iscat_chans);
    if params.twocolor_iscat
        all_gates(end+1) = params.iscat_thresh;
    end
    
    for c = 1:params.num_fluo_chans
        all_gates(end+1) = params.lbl_threshs(c);
    end
    
    gates = all_gates(spfi_chans);
end