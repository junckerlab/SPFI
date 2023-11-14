function [fig, ax] = draw_scatterplot(scatter_data, xl, yl, figWidth, figHeight, xlbl, ylbl, varargin)
    %create figure and draw SPFI scatterplot
    
    %default vars
    plot_gates = false;     %draw thresholds as lines
    gates = [0,0];          %threshold values
    font_size = 20;

    %generate colorscale based on spot density
    highres_colordensity = false;
    color_clip_percentile = 1;      %clip colorscale at percentatge of maximum value    

    %limit plot points
    max_points = size(scatter_data, 2); %overall
    num_gated = -1;                     %above iSCAT threshold

    %pass the iscat imaging wavelength to calibrate the x axis
    iscat_wavelength = 0;

    %refractive index EV (for calibration)
    n_vesicle = [];

    %parse kwargs
    for i = 1:2:nargin-7
        switch varargin{i}
            case 'gates'
                gates = varargin{i+1};
                plot_gates = true;
            case 'plot_gates'
                plot_gates = varargin{i+1};
            case 'highres_colordensity'
                highres_colordensity = varargin{i+1};
            case 'color_clip_percentile'
                color_clip_percentile = varargin{i+1};
            case 'font_size'
                font_size = varargin{i+1};
            case 'max_points'
                max_points = varargin{i+1};
            case 'num_gated'
                num_gated = varargin{i+1};
            case 'iscat_wavelength'
                iscat_wavelength = varargin{i+1};
            case 'refractive_index_vesicle'
                n_vesicle = varargin{i+1};
                
        end
    end
    
    x = (scatter_data(1,:)');
    y = (scatter_data(2,:)');

    %remove points outside of the plot window
    vld = x>xl(1) & x<xl(2) & y>yl(1) & y<yl(2);
    
    %limit total number of points (if requested)
    cs = cumsum(vld);
    i_max = find(cs == max_points);
    if not(isempty(i_max))
        vld(i_max:end) = false;
    end
    x = x(vld);
    y = y(vld);

    %limit number of valid points above x-axis threshold
    %supersedes max_points
    if num_gated > 0
        gated = cumsum(x > gates(1));
        vld = gated <= num_gated;
        x = x(vld);
        y = y(vld);
    end

    %creat figure and start drawing
    fig = figure('DefaultAxesFontSize', font_size);
    fig.Position = [500, 300, figWidth, figHeight];
    t = tiledlayout(1,1);
    warning off
    ax = axes(t, 'Position',  [0.17, 0.23, 0.76, 0.7], 'XAxisLocation', 'bottom');


    if highres_colordensity
        %slow but accurate calculation of spot density in plot
        color = ksdensity([x, fx], [x, fx]);
    else
        %faster way to calculate spot density -> bin the data and sum
        %number of spots in each bin
        % Define the number of bins
        bins = 200;
        
        % Initialize the 2D grid for bin counts
        grid = zeros(bins, bins);
        
        % Discretize x and y data into bins
        iX = discretize(x, linspace(xl(1), xl(2), bins));
        iY = discretize(y, linspace(yl(1), yl(2), bins));
        
        % Count occurrences in each bin
        for i = 1:length(x)
            if ~isnan(iX(i)) && ~isnan(iY(i))
                grid(iY(i), iX(i)) = grid(iY(i), iX(i)) + 1;
            end
        end
        
        % Normalize and clip the grid for color mapping
        grid = grid / max(grid(:)) * color_clip_percentile;
        grid(grid > 1) = 1;
        
        % Map the grid to colors for each point
        color = grid(sub2ind(size(grid), iY, iX))';
    end

    %plot
    scatter(ax, x, y, [], color', '.');

    %apply axis labels etc
    xlabel(ax, xlbl, 'Interpreter', 'latex');
    ylabel(ax, ylbl, 'Interpreter', 'latex');
    ax.XLim = xl;
    ax.YLim = yl;
    ax.FontSize = 20;
    ax.LineWidth = 1.5;

    %plot the gates if requested
    if plot_gates
        hold on;
        plot(ax, xl, [gates(2), gates(2)], 'k--');
        plot(ax, [gates(1), gates(1)], [yl(1), yl(2)], 'k--');

        %calculate number of spots in each quadrerant and write into Figure
        gated = zeros(2,size(x,1));    
        gated(1,:) = x > gates(1);
        gated(2,:) = y > gates(2);
        pops = zeros(1, 4);
        pops(1) = sum(and(not(gated(2,:)), not(gated(1,:))));     % ~X & ~Y
        pops(2) = sum(and(gated(1,:), not(gated(2,:))));          %  X & ~Y
        pops(3) = sum(and(gated(2,:), not(gated(1,:))));          % ~X &  Y
        pops(4) = sum(and(gated(2,:), gated(1,:)));               %  X &  Y

        %create new axis to draw grid and write spot counts
        ax2 = axes('Color','none','XColor','none','YColor','none');
        %need to place the inset at slightly different position if we have
        %a top axis (if the data is calibrated)
        p = [0.18, 0.75, 0.25, 0.12];
        if iscat_wavelength > 0
            p(2) = 0.68;
        end

        set(ax2, 'Position', p);
        set(ax2,'FontSize', font_size);
        hold on;
        pgon = polyshape([0,0;1,0;1,1;0,1]);
        plot(pgon, 'FaceColor', [1,1,1], 'FaceAlpha', 1);
        plot(ax2, [0,1], [0.5,0.5], 'k');
        plot(ax2, [0.5,0.5], [0,1], 'k');
        xlim(ax2, [0,1]);
        ylim(ax2, [0,1]);        
        text(ax2, 0.48, 0.25, num2str(pops(1),'%.0f'), 'HorizontalAlignment', 'right', 'FontSize', font_size);        
        text(ax2, 0.52, 0.25, num2str(pops(2),'%.0f'), 'HorizontalAlignment', 'left', 'FontSize', font_size);
        text(ax2, 0.48, 0.75, num2str(pops(3),'%.0f'), 'HorizontalAlignment', 'right', 'FontSize', font_size);
        text(ax2, 0.52, 0.75, num2str(pops(4),'%.0f'), 'HorizontalAlignment', 'left', 'FontSize', font_size);
    end

    if iscat_wavelength > 0
        %calibrate the iSCAT contrast data
        diams_nm = calibrate_ctr2d(xl, 'refractive_index_vesicle', n_vesicle);
        ax3 = axes(t, 'Position',  ax.Position, 'XAxisLocation', 'top', 'Color', 'none');
        ax3.YTick = [];
        ax3.FontSize = font_size;
        ax3.LineWidth = 1.5;
        ax3.XLim = diams_nm;
        xlabel(ax3, 'EV Diameter (nm)', 'Interpreter', 'latex');
        %fake a box
        hold on
        plot([0,0]+diams_nm(2), yl, 'k', 'linewidth', 1.5)
    end
end