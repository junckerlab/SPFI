function [out_x, out_y] = find_spots_for_alignment(input_frame, varargin)
    % FIND_SPOTS_FOR_ALIGNMENT Identifies spots within a specific contrast range
    % that can be used for image alignment.
    % input_frame: Image data to find spots in
    % varargin: Optional key-value pairs for function customization
    
    % Input argument defaults
    p = inputParser;
    addParameter(p, 'remove_crud', true, @islogical);
    addParameter(p, 'crud_min_radius', 10, @isnumeric);
    addParameter(p, 'crud_contrast_thresh', [0.997, 1.002], @(x) isnumeric(x) && numel(x) == 2);
    addParameter(p, 'crud_dilation_radius', 10, @isnumeric);
    addParameter(p, 'border', 5, @isnumeric);
    addParameter(p, 'thresh', [0.95, 0.99], @(x) isnumeric(x) && numel(x) == 2);
    addParameter(p, 'min_dist', 10, @isnumeric);
    addParameter(p, 'spot_brightness', -1, @(x) any(x == [-1, 1]));
    
    parse(p, varargin{:});
    
    % Assign parsed parameters
    remove_crud = p.Results.remove_crud;
    crud_min_radius = p.Results.crud_min_radius;
    border = p.Results.border;
    thresh = p.Results.thresh;
    min_dist = p.Results.min_dist;
    crud_dilation_radius = p.Results.crud_dilation_radius;
    spot_brightness = p.Results.spot_brightness;
    
    % Image dimensions
    [dy, dx] = size(input_frame);
    
    % Exclude the image borders
    valid_area = false(dy, dx);
    valid_area(border+1:end-border, border+1:end-border) = true; 

    % Crud removal
    if remove_crud
        crud = find_image_crud(input_frame, 'crud_min_radius', crud_min_radius, ...
                         'crud_contrast_thresh', [0.997, 1.003], ...
                         'crud_dilation_radius', crud_dilation_radius);
        valid_area = valid_area & ~crud;
    end

    % Find regional extrema based on spot brightness
    if spot_brightness == -1
        regex = imregionalmin(input_frame);
    else
        regex = imregionalmax(input_frame);
    end
    regex = regex & valid_area;

    % Allow only the spots within the correct contrast range
    valid_spots = input_frame > thresh(1) & input_frame < thresh(2);    
    valid_regmin = regex & valid_spots;

    % Exclude spots that are too close to each other
    if min_dist > 0
        % Dilate around each potential spot
        dilated_spots = imdilate(valid_regmin, strel('disk', min_dist));
        
        % Remove dilated areas that touch (accounting for imperfect strel disks
        too_close = bwareaopen(dilated_spots, ceil(1.1*pi * min_dist^2));
        valid_regmin = valid_regmin & ~too_close;
    end

    % Return the coordinates of the valid spots
    [out_x, out_y] = find(valid_regmin);

    %{

    figure()
    imshow(input_frame, [0.99, 1.005]);
    hold on
    plot(out_y, out_x, 'o')

    %}
end
