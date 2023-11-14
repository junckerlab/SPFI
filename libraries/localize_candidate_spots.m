    %Find candidate spots as local extrema in a slightly blurred endpoint
    %image. Threshold valid iSCAT spots on the contrast difference in the
    %first two endpoint images. If there is a third endpoint, check which
    %spots have deteched before the immunofluorescence measurement. Also
    %exclude spots that are too close to each other and might not match the
    %fluorescence images well due to chromatic abberations.
    %return candidate list and write thresholded spots to h5 file

    function candidates = localize_candidate_spots(params, varargin)

    %this is specific to the two colo iSCAT localization. We want to start
    %with the long wl channel and localize the high contrast spots and then
    %go to the short wl channel to localize the rest. This is the contrast
    %value (in third root) above which candidates are registered
    ctr_localization_cutoff = 0.2;
    
    %apply Gaussian filter to data before contrast measurement to eliminate
    gauss_kernel = 1;
        
    %crud detection parameters
    crud_contrast_thresh = [0.99, 1.005];
    crud_min_radius = 8;
    crud_dilation_radius = 10;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%min_contrast = 2*params.g1;
    
    for i = 1:2:nargin-1
        switch varargin{i}
            case 'crud_contrast_thresh'
                crud_contrast_thresh = varargin{i+1};
            case 'crud_min_radius'
                crud_min_radius = varargin{i+1};
            case 'crud_dilation_radius'
                crud_dilation_radius = varargin{i+1};
            case 'ctr_localization_cutoff'
                ctr_localization_cutoff = varargin{i+1};
            case 'gauss_kernel'
                gauss_kernel = varargin{i+1};
        end
    end
        
    candidates = struct();
    for f = 1:params.num_FOVs
        %load the EV image
        im2 = h5r(params.h5_file, 2, params.localization_chan, f);
        im1 = h5r(params.h5_file, 1, params.localization_chan, f);
        [dim_x, dim_y] = size(im2);

        %Mask small area around the image border (artifacts)
        border_mask = true(dim_x, dim_y); 
        border_mask(params.border+1:end-params.border, params.border+1:end-params.border) = false;

        %exclude all the non-overlapping areas in different timepoints
        for t = 1:2
            offs = h5r_attr(params.h5_file, t, 1, f, 'alignment');
            alignment_mask = true(size(im1));
            alignment_mask = imtranslate(alignment_mask, flip(offs), 'Method', 'cubic');
            border_mask = border_mask | not(alignment_mask);
        end

        %additional crud detection
        crud1 = find_image_crud(im1, 'crud_contrast_thresh', crud_contrast_thresh, ...
            'crud_min_radius', 0, 'crud_dilation_radius', crud_dilation_radius);
        crud2 = find_image_crud(im2, 'crud_contrast_thresh', crud_contrast_thresh, ...
            'crud_min_radius', crud_min_radius, 'crud_dilation_radius', crud_dilation_radius);
        crud = border_mask | crud1 | crud2;
        h5w_crud(params.h5_file, f, int8(crud));
        
        if f == 1
            %plot crud detection for visual inspection
            fprintf('Timepoint 1 crud detection\n');
            fig = figure();
            fig.Position = [0, 0, 1200, 600];

            axes('Position', [0, 0, 0.48, 0.96]);
            imshow(im1, [0.99, 1.005]);
            axes('Position', [0.5, 0, 0.48, 0.96]);
            imshow(im1.*not(crud), [0.99, 1.005]);

            fprintf('Timepoint 2 crud detection');
            fig = figure();
            fig.Position = [0, 0, 1200, 600];

            axes('Position', [0, 0, 0.48, 0.96]);
            imshow(im2, [0.99, 1.005]);
            axes('Position', [0.5, 0, 0.48, 0.96]);
            imshow(im2.*not(crud), [0.99, 1.005]);
        end

        %candidate selection here------------------
        chans = find(params.iscat_chans);
        [pos_x, pos_y] = deal([]);
        for ch = flip(1:params.num_iscat_chans)
            %go through iSCAT channels from the longest wavelength to the
            %shortest. We want to detect the largest dark(!) EVs first and finish the
            %candidate selection in the most sensitive channel. 
            c = chans(ch);
                
            im2 = h5r(params.h5_file, 2, c, f);
            im1 = h5r(params.h5_file, 1, c, f);
                
            %reduce high freq noise in DiPPI image (use same kernel here as
            %later when the contrast is measured
            imdiff = im2 - im1;
            imdiff = imgaussfilt(imdiff, gauss_kernel);
    
            %additional blur for the candidate localization. -> reduce the
            %number of candidates in the image background
            blur = 2;
            imdiff_blur = imgaussfilt(imdiff, blur);
        
            %dark_candidates
            cnddts_new = imregionalmin(imdiff_blur);
            cnddts_new = and(cnddts_new, not(crud));            
            cnddts_lin = find(cnddts_new);

            [pos_x_new, pos_y_new] = ind2sub(size(imdiff), cnddts_lin');

            if ch > 1
                %if we have two color iSCAT data keep only the strongest ones in the larger wavelength.
                %Note that we go from high wl to low wl here
                ctr = -1 * imdiff(cnddts_lin);
                valid = (ctr).^(1/3) > ctr_localization_cutoff;
                pos_x_new = pos_x_new(valid);
                pos_y_new = pos_y_new(valid);

                %now add the spots that we already localized to the crud so they
                %are not picked up again for the lower wl channels
                spot_mask = false(dim_x, dim_y);
                spot_mask(cnddts_lin(valid)) = true;
                spot_mask = imdilate(spot_mask, strel('disk', 10));
                crud = or(crud, spot_mask);
            end

            %commit to list
            pos_y = [pos_y, pos_y_new];
            pos_x = [pos_x, pos_x_new];
        end

        %candidate localization done, save to struct
        candidates(f).num_candidates = size(pos_x, 2);
        candidates(f).pos_x = pos_x;
        candidates(f).pos_y = pos_y;

        %now measure contrasts in all channels
        chans = find(params.iscat_chans);
        for ch = 1:params.num_iscat_chans
            c = chans(ch);

            %read images and measure contrast
            im2 = h5r(params.h5_file, 2, c, f);
            im1 = h5r(params.h5_file, 1, c, f);
            imdiff = im2 - im1;

            %filter high freq spatial noise
            if gauss_kernel > 0
                imdiff = imgaussfilt(imdiff, gauss_kernel);
            end

            candidate_ind = sub2ind(size(imdiff), pos_x, pos_y);
            ctr = -1 * imdiff(candidate_ind);
            candidates(f).iscat(ch).ctr = ctr;
        end

        %find valid spots, i.e. thoise that are above the threshold in
        %any channel
        gated = false(size(pos_x));
        for j = 1:params.num_iscat_chans
            gated = or(gated, candidates(f).iscat(j).ctr > params.iscat_thresh^3);
        end

        for t = 1:2
            h5w_sp(params.h5_file, t, 1, f, pos_x(gated), pos_y(gated));
        end
    end
    save([params.fpath, 'candidates.mat'], 'candidates')
end
