function correct_for_chromatic_abberation(params, varargin)
    %load a distortion map to correct chromatic aberration (defualt) or
    %generate the distortion map on the data itself

    %default setting - load the distortion map
    %note that it is advisable to generate a full frame map and apply it to
    %all datasets (both faster and more accurate)
    load_abberation_correction = false;

    %if the distortion map is generated from the data itself, specify
    %timepoint in which there are matching spots
    tp_selection = 2 + zeros(size(params.chans_to_correct));

    %contrast range for spots that are used for generating the correction
    %map. If a spot' is too dim it might be noise, if it's too bright it
    %might not be Gaussian and therefor a poor marker
    fluo_range = [20, 200];
    iscat_range = [0.96, 0.998];

    %max distance in which spots in different channels are matched
    max_dist = 8;

    %exclude the image border (there are camera artifacts
    image_border = 60;

    %Gaussian blur the image to get rid of techical noise and localize spot
    %center with more accuracy
    gauss_kernel = 1;

    %parse kwargs
    for i = 1:2:nargin-1
        switch varargin{i}
            case 'gauss_kernel'
                gauss_kernel = varargin{i+1};
            case 'fluo_range'
                fluo_range = varargin{i+1};
            case 'iscat_range'
                iscat_range = varargin{i+1};
            case 'max_dist'
                max_dist = varargin{i+1};
            case 'image_border'
                image_border = varargin{i+1};
            case 'load_abberation_correction'
                load_abberation_correction = varargin{i+1};
            case 'tp_selection'
                tp_selection = varargin{i+1};
        end
    end
    
    if ~isfield(params, 'dim_x')
        [dim_x, dim_y] = size(h5r(params.h5_file, 1, 1, 1));
        params.dim_x = dim_x;
        params.dim_y = dim_y;
    end
    
    warning('off','all');
    num_chans = size(params.chans_to_correct, 2);
    h = waitbar(0, 'Correcting chromatic aberration');
    for j = 1:num_chans
        %loop over all channels that are supposed to be corrected
        c = params.chans_to_correct(j);        

        %figure out what channel we dealing with
        if params.iscat_chans(c) == true
            rng = iscat_range;
            brightness = -1;        %only allow dark for alignment
            plt_rng = [0.99, 1.005];
        elseif params.fluo_chans(c) == true
            rng = fluo_range;
            brightness = 1;
            plt_rng = [-50, 200];
        end

        if load_abberation_correction
            %load the correction map
            fdir = dir(params.fpath);
            files = {fdir.name};
            id = contains(files, ['Correction_map_ch', num2str(c)]);
            load([params.fpath, files{id}], 'diffX', 'diffY');
            %the map is full 1608x1608 FOV, cut the map to FOV size
            st = floor((1608 - params.dim_x) / 2);
            en = ceil((1608 - params.dim_x) / 2);
            diffX = diffX(st+1:1608-en, st+1:1608-en);
            diffY = diffY(st+1:1608-en, st+1:1608-en);
        else
            %non-default way: calculate based on the current image data
            t = tp_selection(j);
            [pos_all, diff_all] = deal([]);
            for f = 1:params.num_FOVs
                %read iSCAT image
                reference = h5r(params.h5_file, t, 1, f);
                reference = imgaussfilt(reference, gauss_kernel);                       %remove technical noise

                %select spots in defined contrast range
                [pos_x, pos_y] = find_spots_for_alignment(reference, 'thresh', iscat_range, 'crud_min_radius', 8, 'border', image_border);

                frame = h5r(params.h5_file, t, c, f);
                frame = imgaussfilt(frame, gauss_kernel);                       %remove technical noise
                %search for fluorescnce spots nearby iSCAT positions
                [pos_x_adj, pos_y_adj, adjusted] = adjust_spot_positions(frame, pos_x, pos_y, ...
                    'brightness', brightness, 'max_dist', max_dist, 'snap_to', 'nearest');

                [~, ~, valid_range] = select_spots_in_contrast_range(frame, pos_x_adj, pos_y_adj, rng);
                %remove spots outside of contrast range
                valid = adjusted & valid_range;
                pos_x2 = pos_x_adj(valid);
                pos_y2 = pos_y_adj(valid);

                pos_x1 = pos_x(valid);
                pos_y1 = pos_y(valid);

                %combine all coordinatesfrom all FOVs
                pos_all = [pos_all; [pos_x1, pos_y1]];
                diff_all = [diff_all; [pos_x1 - pos_x2, pos_y1 - pos_y2]];

                %%
                if f == 1
                    %plot for one FOV
                    fprintf(['Chan ', num2str(c), 'before alignment:']);
                    fig = figure();
                    fig.Position = [0, 0, 1200, 600];

                    axes('Position', [0.03, 0.05, 0.45, 0.9]);
                    imshow(reference, [0.99, 1.005]);
                    hold on
                    plot(pos_y1, pos_x1, 'o', 'Markersize', 12, 'LineWidth', 2);
                    plot(pos_y2, pos_x2, 'd', 'Markersize', 12, 'LineWidth', 2);
                    legend('iSCAT', 'Fluo')
                    
                    axes('Position', [0.53, 0.05, 0.45, 0.9]);
                    imshow(frame, plt_rng);
                    hold on
                    plot(pos_y1, pos_x1, 'o', 'Markersize', 12, 'LineWidth', 2);
                    plot(pos_y2, pos_x2, 'd', 'Markersize', 12, 'LineWidth', 2);
                    legend({'iSCAT reference', 'Corrected channel'}, 'FontSize', 15)
                    %saveas(gcf, [params.fpath, 'eval_plots\abberation_correction_', num2str(j), '_1.png']);
                    %% 
                    %savefig([params.fpath, 'eval_plots\abberation_correction_', num2str(j), '_1.fig']);

                end
                progress = f / params.num_FOVs;
                waitbar(progress, h, sprintf(['Sampling displacement map for channel ', num2str(c), ' ... %d%%'], int32(100*progress)));
            end

            %Combine the points from all FOVs
            %bin into n by n subsampled array - this will average closeby
            %values where EVs in different FOVs are at about the same pos
            n = 24;   % Number of bins (should divide the dimension of the image)
            edges = linspace(1, params.dim_x, n);
            binSize = edges(2) - edges(1);

            % Determine the bin indices for each position
            binIndices = [discretize(pos_all(:,1), edges), discretize(pos_all(:,2), edges)];

            % Sum up the values of each component in each bin and count the non-zero values
            diff_x = accumarray(binIndices, diff_all(:,1), [n, n], @median);
            diff_y = accumarray(binIndices, diff_all(:,2), [n, n], @median);
            binCounts = accumarray(binIndices, diff_all(:,1) ~= 0, [n, n], @sum);

            %kick out the ones where we don't have data
            vld = binCounts > 0;
            diff_x = diff_x(vld);
            diff_y = diff_y(vld);

            %we also need the positions of these spots so
            %generate centre positions of downsampled aray
            %and the kick out the invalid ones
            [Ygrid, Xgrid] = meshgrid(0:n-1, 0:n-1);
            Ygrid = round(binSize/2) + binSize*Ygrid;
            Xgrid = round(binSize/2) + binSize*Xgrid;
            pos_x = Ygrid(vld);
            pos_y = Xgrid(vld);

            %Interpolate the differences between original and transformed positions
            [Ygrid, Xgrid] = meshgrid(1:params.dim_x, 1:params.dim_y);
            waitbar(progress, h, sprintf(['Interpolating displacement map for channel ', num2str(c), ' ... %d%%'], int32(0)));
            diffX = griddata(pos_x, pos_y, diff_x, Ygrid, Xgrid, 'v4');
            waitbar(progress, h, sprintf(['Interpolating displacement map for channel ', num2str(c), ' ... %d%%'], int32(50)));
            diffY = griddata(pos_x, pos_y, diff_y, Ygrid, Xgrid, 'v4');
            waitbar(progress, h, sprintf(['Interpolating displacement map for channel ', num2str(c), ' ... %d%%'], int32(100)));

            %blur for good measure (check eventually if this should be kept)
            diffY = imgaussfilt(diffY, 100);
            diffX = imgaussfilt(diffX, 100);
            
            save([params.fpath, 'Correction_map_ch', num2str(c),  '.mat'], 'diffX', 'diffY');
        end

        % %now transform the images
        for t = 1:params.num_timepoints
            for f = 1:params.num_FOVs
                %transform the fluorescence chan
                frame = h5r(params.h5_file, t, c, f, 'align_fov', false, 'ignore_missing_data', true);  

                %if the channel is missing in the h5 ignore it
                if not(isempty(frame))
                    final_frame = zeros(size(frame));
                    % Apply inverse transform to approximate the original image
                    for y = 1:params.dim_y
                        for x = 1:params.dim_x
                            newX = round(x - diffX(x, y));
                            newY = round(y - diffY(x, y));
                            
                            % Keep reconstructed pixels within image boundaries
                            newX = max(newX, 1);
                            newX = min(newX, params.dim_x);
                            newY = max(newY, 1);
                            newY = min(newY, params.dim_y);
                            
                            final_frame(x, y) = frame(newX, newY);
                        end
                    end
                    h5w(params.h5_file, t, c, f, final_frame);
                end
                current_iteration = (t-1)*params.num_FOVs + f;
                progress = current_iteration / (params.num_timepoints*params.num_FOVs);
                waitbar(progress, h, sprintf(['Correcting for chromatic abberation in channel ', num2str(c), ' ... %d%%'], int32(100*progress)));
            end
        end  
    
        %%
        %plot
        reference = h5r(params.h5_file, t, 1, f);
        reference = imgaussfilt(reference, gauss_kernel);                       %remove technical noise
    
        %select spots in defined contrast range
        [pos_x, pos_y] = find_spots_for_alignment(reference, 'thresh', iscat_range, 'crud_min_radius', 8, 'border', image_border);
    
        frame = h5r(params.h5_file, t, c, f);
        frame = imgaussfilt(frame, gauss_kernel);                               %remove technical noise
        %search for fluorescnce spots nearby iSCAT positions
        [pos_x_adj, pos_y_adj, adjusted] = adjust_spot_positions(frame, pos_x, pos_y, ...
            'brightness', brightness, 'max_dist', max_dist, 'snap_to', 'nearest');
    
        [~, ~, valid_range] = select_spots_in_contrast_range(frame, pos_x_adj, pos_y_adj, rng);
        %remove spots outside of contrast range
        valid = adjusted & valid_range;
        pos_x2 = pos_x_adj(valid);
        pos_y2 = pos_y_adj(valid);
    
        pos_x1 = pos_x(valid);
        pos_y1 = pos_y(valid);
    
        %prepare quiver plot
        downsampling_factor = 40;
        [Ygrid, Xgrid] = meshgrid(1:params.dim_x, 1:params.dim_y);
        Xs =  transpose(downsample(transpose(downsample(Xgrid, downsampling_factor)), downsampling_factor));
        Ys =  transpose(downsample(transpose(downsample(Ygrid, downsampling_factor)), downsampling_factor));
        diffXs =  transpose(downsample(transpose(downsample(diffX, downsampling_factor)), downsampling_factor));
        diffYs =  transpose(downsample(transpose(downsample(diffY, downsampling_factor)), downsampling_factor));
    
        fprintf(['Chan ', num2str(c), ' alignment map:']);
        fig = figure();            
        fig.Position = [0, 0, 1200, 600];
        axes('Position', [0.03, 0.05, 0.45, 0.9]);
        quiver(Ys, Xs, diffYs, diffXs);
        xlim([1, params.dim_x]);
        ylim([1, params.dim_y]);
        ax1.XTickLabel = {};
        ax1.YTickLabel = {};
    
        axes('Position', [0.53, 0.05, 0.45, 0.9]);
        imshow(frame, plt_rng);
        hold on
        plot(pos_y1, pos_x1, 'o', 'Markersize', 12, 'LineWidth', 2);
        plot(pos_y2, pos_x2, 'd', 'Markersize', 12, 'LineWidth', 2);
        legend({'Reference channel', 'Corrected channel'}, 'FontSize', 15)
    end
    close(h);
    clear h
end