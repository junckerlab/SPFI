function candidates = measure_fluorescence_intensities(params, varargin)
    %load candidates data
    load([params.fpath, 'candidates.mat'], 'candidates');

    %apply Gaussian filter to data before contrast measurement to eliminate
    gauss_kernel = 1;

    %read in varagrin
    for i = 1:2:nargin-1
        switch varargin{i}
            case 'gauss_kernel'
                gauss_kernel = varargin{i+1};
        end
    end

    num_canddts_total = 0;
    for f = 1:params.num_FOVs
        %load spot positions from the candidates
        pos_x = candidates(f).pos_x;
        pos_y = candidates(f).pos_y;
        num_cnddts_in_FOV = size(pos_x, 2);
        num_canddts_total = num_canddts_total + num_cnddts_in_FOV;         
        
        %evaluate the endogenous labels
        for c = 1:params.num_fluo_chans
            chan = find(params.fluo_chans);
            
            %read the image files
            im2 = h5r(params.h5_file, 2, chan(c), f);
            im1 = h5r(params.h5_file, 1, chan(c), f);
            imdiff = im2 - im1;

            if gauss_kernel > 0
                %apply filter to eliminate technical pixel noise
                imdiff = imgaussfilt(imdiff, gauss_kernel);
            end

            %measure fluoresncee intensities
            candidate_ind = sub2ind(size(imdiff), pos_x, pos_y);
            contrasts = imdiff(candidate_ind);

            %save to candidate file
            candidates(f).fluo(c).ctr = contrasts;

            %plot some FOV for visual inspection
            if f == 1
                fprintf(['chan ', num2str(c)'])
                gated = contrasts > params.lbl_threshs(c)^3;
                figure();
                imshow(im2, [-50, 200]);
                hold on;
                plot(pos_y, pos_x, 'ok');
                plot(pos_y(gated), pos_x(gated), 'og');
                legend('All', 'Above Threshold')
            end

            %gate based on specified intensity threshold
            gated = contrasts > params.lbl_threshs(c)^3;
            h5w_sp(params.h5_file, params.lbl_tps, chan(c), f, pos_x(gated), pos_y(gated));
        end
    end

    %save candidates data
    save([params.fpath, 'candidates.mat'], 'candidates')
end