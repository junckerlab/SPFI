function [tp, ch] = get_spfi_channel_info(params, spfi_id)
    %get the timepoint and channel (and other info) from the SPPFI ID
    %WIP, this will be painful for DEI data
    %SPFI ID 1 is twocolor iscat (if applicable)
    %then it's the iscat chanenls, fluorescence chanels and DEI channels
    %all in order

    if spfi_id == 1
        %it's an iscat channel
        tp = params.num_EVinc_tps;
        ch = 1;
        return
    end

    %figure out the channel number by subtracting
    if params.twocolor_iscat
        spfi_id = spfi_id - 1;
    end

    if spfi_id <= params.num_iscat_chans
        %it's an iscat label channel
        ch = spfi_id;
        tp = params.num_EVinc_tps;
        return
    end
    spfi_id = spfi_id - params.num_iscat_chans;


    if spfi_id <= params.num_lbl_chans
        %it's a fluorescence label channel
        ch = find(params.lbl_chans);
        ch = ch(spfi_id);
        tp = params.lbl_tps(spfi_id);
        return
    end
    spfi_id = spfi_id - params.num_lbl_chans;
    
    %DEI tbd
    dei_chans = find(params.dei_chans);
    [c, t] = ind2sub([params.num_dei_chans, params.num_cycles], spfi_id);
    tp = params.num_EVinc_tps + t;
    ch = dei_chans(c);
end