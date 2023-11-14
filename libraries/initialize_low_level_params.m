function params = initialize_low_level_params(params)

    %cound the channels that are being processed
    params.num_channels = size(params.iscat_chans, 2);
    params.num_iscat_chans = sum(params.iscat_chans);
    params.num_fluo_chans = sum(params.fluo_chans);

    %channel for candidates spot localization
    params.localization_chan = 1;       

    %crud parameters
    params.min_pixel_crud = 80;
    params.border = 30;
    params.min_spot_distance = 8;

    %check for user error
    if params.twocolor_iscat && params.num_iscat_chans < 2
        fprintf(1, 'Warning: Two-color iSCAT not possible with only one iSCAT channel\n')
        params.twocolor_iscat = false;
    end
    params.h5_file = [params.fpath, 'spfi.h5'];
end