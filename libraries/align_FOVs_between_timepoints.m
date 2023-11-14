function params = align_FOVs_between_timepoints(params, varargin)    
    %Frames between timepoints in SPFI imaging can be misaligned due to holder
    %movements from manual sample pipetting or from imprecise stage movements
    %Different channels of the same FOV are well matched
    %Use the iSCAT channel to align the images. The algorithm searches for
    %diffraction limited spots (small particles in the pre-incubation image or
    %EVs if multiple timepoints are taken after sample incubation) and tries to
    %find the matching spots in all timepoints. This allows robust alignment
    %even with many added spots from the sample
    %script handles two timepoints but can easily be extended to multiple ones

    contrast_range = [0.95, 0.999];
    gauss_kernel = 1;
    image_border = 50;

    %parse kwargs
    for i = 1:2:nargin-1
        switch varargin{i}
            case 'contrast_range'
                contrast_range = varargin{i+1};
            case 'gauss_kernel'
                gauss_kernel = varargin{i+1};
        end
    end

    h = waitbar(0, 'Aligning FOVs ... ');
    offsets = zeros(params.num_FOVs, 2);
    for f = 1:params.num_FOVs

        %first align images 1 and 2, always use channel 1
        frame1 = h5r(params.h5_file, 1, 1, f, 'align_fov', false);
        frame2 = h5r(params.h5_file, 2, 1, f, 'align_fov', false);

        if gauss_kernel > 0
            %blur to remove technical noise and allow better spot
            %localization
            frame1 = imgaussfilt(frame1, gauss_kernel);
            frame2 = imgaussfilt(frame2, gauss_kernel);
        end

        %select spots in defined contrast range
        [x_1, y_1] = find_spots_for_alignment(frame1, 'thresh', contrast_range, ...
            'crud_min_radius', 15, 'border', image_border, 'min_dist', 10);

        %find spots in frame2, use same contrst threshs
        [x_2, y_2] = find_spots_for_alignment(frame2, 'thresh', contrast_range, ...
            'crud_min_radius', 15, 'border', image_border, 'min_dist', 0);

        %{
            figure()
            axes('OuterPosition', [0, 0, 0.5, 1]);
            imshow(frame1, [0.99, 1.005]);
            hold on
            plot(y_1, x_1, 'o');
            axes('OuterPosition', [0.5, 0, 0.5, 1]);
            imshow(frame2, [0.99, 1.005]);
            hold on
            plot(y_2, x_2, 'o');
        %}

        %align frame 1
        if isempty(x_1) || isempty(x_2)
            fprintf(1, ['Warning: no spots found to align FOV ', num2str(f)', '\n'])
        end
        
        %find the most common displacement btw the spot lists
        grid_offset = round(find_displacement_from_spot_coordinates([x_1, y_1], [x_2, y_2]));
        offsets(f, :) = grid_offset;
        h5w_attr(params.h5_file, 1, 1:params.num_channels, f, 'alignment', grid_offset);

        %write a zero into tp 2
        h5w_attr(params.h5_file, 2, 1:params.num_channels, f, 'alignment', [0,0]);
        
        progress = f / params.num_FOVs;
        waitbar(progress, h, sprintf('Aligning FOVs ... %d%%', int32(100*progress)));
    end

    %prepare QC plot to quickly check for potential outliers
    fprintf(1, 'Image diplacement QC: check for outliers')
    figure()
    hold on
    box on
    plot(offsets(:,1), offsets(:,2), 'x-', 'Color', [0.3,0.3,0.3])

    %apply minimum axis limits
    xl = xlim();
    yl = ylim();
    % Set minimum range to 50 if the current range is less than 50
    if diff(xl) < 50
        xlim([xl(1)-20, xl(2)+20]);
    end
    
    if diff(yl) < 50
        ylim([yl(1)-20, yl(2)+20]);
    end
    for j = 1:params.num_FOVs
        text(offsets(j,1), offsets(j,2), num2str(j));
    end
    xlabel('x-axis displacement (pixels)')
    ylabel('y-axis displacement (pixels)')

    close(h);
    clear h
end

