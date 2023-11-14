function spfi_selections = spfi_plot(params, chans_x, chans_y, xlim, ylim, varargin)

    %load the SPFI data
    load([params.fpath, 'spfi.mat'], "spfi", "spfi_selections");

    %zero for chans_y means all fluoresncec channels
    if chans_y == 0
        st = params.twocolor_iscat+params.num_iscat_chans + 1;
        en = st + params.num_lbl_chans - 1;
        chans_y = st:en;
    end

    %scaling exponents
    %default: use third root scaling. Any exponent is possible, use 1/2 for
    %square root or 1 for linear scaling. Log scaling currently not implemented
    exp_x = 1/3;
    exp_y = 1/3;

    %indicate if we should calibrate the x-axis. Note that the
    %params.channel_wavelengths need to be set correctly for this
    calibrate_xaxis = false;
    %refractive index of sample. Pass empty for default EV value (set in
    %calibrate_ctr2d.m
    n_vesicle = [];

    %plot the contrast thresholds
    plot_gates = true;

    %limit the number of actual EVs above the iSCAT threshold. Normalize
    %plots btw measurements (cannot notmalize well on total number)
    num_gated = -1;

    %plot settings
    color_density = true;
    highres_colors = false;
    color_clip_percentile = 1;
    max_points = 0;     %we will initialize it down below
    limit_plot_points = false;   %flag if max_points is set 
    %parse kwargs

    for i = 1:2:nargin-5
        switch varargin{i}
            case 'refractive_index_vesicle'
                n_vesicle = varargin{i+1};
            case 'color_density'
                color_density = varargin{i+1};
            case 'highres_colors'
                highres_colors = varargin{i+1};
            case 'plot_gates'
                plot_gates = varargin{i+1};
            case 'calibrate_xaxis'
                calibrate_xaxis = varargin{i+1};            
            case 'color_clip_percentile'
                 color_clip_percentile = varargin{i+1};
            case 'max_points'
                max_points = varargin{i+1};
                limit_plot_points = true;
            case 'num_gated'
                num_gated = varargin{i+1};
            case 'exp_x'
                exp_x = varargin{i+1};
            case 'exp_y'
                exp_y = varargin{i+1};
        end
    end

    %check if all points are supposed to be plotted
    if limit_plot_points == false
        max_points = size(spfi, 1);
    end

    %plot for each channel    
    for i = chans_x
        for j = chans_y
            scatter_data = [abs(table2array(spfi(:,i))).^exp_x .* sign(table2array(spfi(:,i))), ...
                            abs(table2array(spfi(:,j))).^exp_y .* sign(table2array(spfi(:,j)))]';
        
            xlbl = [spfi.Properties.VariableNames{i}, '$^{1/', num2str(1/exp_x), '}$'];
            ylbl = [spfi.Properties.VariableNames{j}, '$^{1/', num2str(1/exp_y), '}$'];

            %to calibrate the x-axis, pass the iscat wavelength. 
            %Pass zero to not do that
            iscat_wavelength = 0;
            if calibrate_xaxis
                iscat_wavelength = params.channel_wavelengths(1);
            end
        
            gates = [get_SPFI_gates(params, i), get_SPFI_gates(params, j)];    
            figWidth = 800;
            figHeight = 600;
            [fig, ax] = draw_scatterplot(scatter_data, xlim, ylim, figWidth, figHeight, xlbl, ylbl, ...
                'gates', gates, ...
                'plot_gates', plot_gates, ...
                'iscat_wavelength', iscat_wavelength, ...
                'color_density', color_density, ...
                'highres_colors', highres_colors, ...
                'max_points', max_points, ...
                'num_gated', num_gated, ...
                'color_clip_percentile', color_clip_percentile, ...
                'refractive_index_vesicle', n_vesicle);

            %save figure
            fname = [params.fpath, 'plots\SPFI_', spfi.Properties.VariableNames{i}, '_vs_', spfi.Properties.VariableNames{j}, '.png'];
            saveas(fig, fname);
        end
    end
end