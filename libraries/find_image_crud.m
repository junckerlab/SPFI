function [crud, cleaned_data] = find_image_crud(data, varargin)
    % FIND_CRUD Identify and remove large image features like dust or dirt
    % in iSCAT images
    % data: Image data to be cleaned
    % varargin: Optional key-value pairs for function customization

    % Default parameters
    crud_min_radius = 8;
    crud_contrast_thresh = [0.95, 1.002];
    crud_dilation_radius = 10;
    display_result = false; % Default not to display result

    % Parse input key-value pairs
    for i = 1:2:length(varargin)
        switch varargin{i}
            case 'crud_min_radius'
                crud_min_radius = varargin{i+1};
            case 'crud_contrast_thresh'
                crud_contrast_thresh = varargin{i+1};
            case 'crud_dilation_radius'
                crud_dilation_radius = varargin{i+1};
            case 'display_result'
                display_result = varargin{i+1};
            otherwise
                error('Unknown parameter name: %s', varargin{i});
        end
    end

    % Validate contrast threshold
    if ~isnumeric(crud_contrast_thresh) || numel(crud_contrast_thresh) ~= 2
        error('Contrast threshold must be a numeric array with two elements.');
    end

    % Identify potential crud by thresholding
    crud = data < crud_contrast_thresh(1) | data > crud_contrast_thresh(2);

    % Morphological closing to fill holes
    crud = imclose(crud, strel('disk', crud_min_radius));

    % Remove small objects
    crud = bwareaopen(crud, round(pi * crud_min_radius^2));

    % Dilate identified crud regions
    crud = imdilate(crud, strel('disk', crud_dilation_radius));

    % Optionally return cleaned data
    if nargout > 1
        cleaned_data = data .* ~crud;
    end

    % Optional result visualization
    if display_result
        figure();
        subplot(1, 2, 1);
        imshow(data, [0.99, 1.005]);
        title('Original Data');

        subplot(1, 2, 2);
        imshow(cleaned_data, [0.99, 1.005]);
        title('Cleaned Data');
    end
end
