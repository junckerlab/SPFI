function [pos_x_out, pos_y_out, success] = adjust_spot_positions(frame, pos_x, pos_y, varargin)
    %adjust list of spot positions to the image data in frame
    %Used for example to adjust between channels
    %success is logical array that indicates if a local extrema was found
    %in the image data withing the search range

    % Initialize default parameters
    brightness = 1;                 %1 fo bright spots, -1 for dark spots, 0 if undecided (use with 'highest_contrast' snapping)
    max_dist = 3;
    snap_to = 'highest_contrast'; % Can be 'nearest' or 'highest_contrast'

    % Parse variable input arguments
    for i = 1:2:length(varargin)
        switch varargin{i}
            case 'brightness'
                brightness = varargin{i+1};
            case 'max_dist'
                max_dist = varargin{i+1};
            case 'snap_to'
                snap_to = varargin{i+1};
        end
    end
    
    % Find local extrema based on the specified brightness
    if brightness == 0
        local_extrema = imregionalmin(frame) | imregionalmax(frame);
    elseif brightness == -1
        local_extrema = imregionalmin(frame);
    elseif brightness == 1
        local_extrema = imregionalmax(frame);
    end
    
    % Initialize dimensions and linear indices for the spots
    [dim_x, dim_y] = size(frame);
    spots_lin = sub2ind([dim_x, dim_y], pos_x, pos_y);
    neighbor_offsets = reshape(-max_dist:max_dist, [], 1) + reshape(-max_dist:max_dist, 1, []) * dim_x;
    
    % Prepare for position adjustment based on the snap_to mode
    if strcmp(snap_to, 'nearest')
        % Code for snapping to the nearest local extremum
        distance = zeros([2*max_dist+1, 2*max_dist+1]);
        distance(ceil((2*max_dist+1)^2 / 2)) = 1; %center
        distance = bwdist(distance);
        [~, dist_idx] = sort(distance(:));
        neighbor_offsets_sorted = neighbor_offsets(dist_idx);   %sort by distance to center

        search_ROI = bsxfun(@plus, spots_lin, neighbor_offsets_sorted');
        valid_extrema = local_extrema(search_ROI);
        for i = 1:size(valid_extrema, 1)
            io = find(valid_extrema(i,:) == 1, 1, 'first');
            if io
                spots_lin(i) = spots_lin(i) + neighbor_offsets_sorted(io);
            end
        end
        success = sum(valid_extrema, 2) > 0;

    elseif strcmp(snap_to, 'highest_contrast')
        % Code for snapping to the highest contrast local extremum within
        % search range
        search_ROI = bsxfun(@plus, spots_lin, neighbor_offsets(:)');
        valid_extrema = local_extrema(search_ROI);
        px_vals = frame(search_ROI);
        
        extrema_vals = px_vals .* valid_extrema;    
        if brightness == 0
            %take the max value of either brightness
            [~, I_max] = max(abs(extrema_vals-median(frame(:))), [], 2);
        elseif brightness == -1
            %bit shitty this all
            extrema_vals(extrema_vals==0) = 2;
            [~, I_max] = min(extrema_vals, [], 2);
        elseif brightness == 1
            [~, I_max] = max(extrema_vals, [], 2);
        end

        spots_lin = spots_lin + neighbor_offsets(I_max');
        success = sum(valid_extrema, 2) > 0;            %we have at least one localextremum to snap to
    end

    % Convert linear indices back to subscript indices
    [pos_x_out, pos_y_out] = ind2sub(size(frame), spots_lin);
end