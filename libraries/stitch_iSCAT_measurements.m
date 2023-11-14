function candidates = stitch_iSCAT_measurements(params, varargin)
    %stitch together SP sizing ranges for dual color iSCAT imaging

    if params.twocolor_iscat == false
        return
    end

    %load candidates data
    load([params.fpath, 'candidates.mat'], 'candidates');

    %plot limits
    xl = [0, 0.5];
    yl = [0, 35];
    
    %lower and upper thresholds for fitting the data
    low_threshold = 0.11;
    high_threshold = 0.15;
    
    %read in varagrin
    for i = 1:2:nargin-1
        switch varargin{i}
            case 'low_threshold'
                low_threshold = varargin{i+1};
            case 'high_threshold'
                high_threshold = varargin{i+1};
            case 'xl'
                xl = varargin{i+1};
            case 'yl'
                yl = varargin{i+1};
        end
    end

    %combine candidates  
    num_candidates_total = 0;
    for fov = 1:size(params.valid_fovs, 2)
        %restrict to 'valid' FOVS (can be selected in main script)
        f = params.valid_fovs(fov);
        num_candidates_total = num_candidates_total + candidates(f).num_candidates;
    end
    iscat_ctr_cmb = zeros(2, num_candidates_total);
    fluo_ctr_cmb = zeros(1, num_candidates_total);
    
    i0 = 1;
    for fov = 1:size(params.valid_fovs, 2)
        f = params.valid_fovs(fov);
        candidates_in_FOV = candidates(f).num_candidates;
    
        %combine both iSCAT channels
        channel_ids = find(params.iscat_chans);
        for c = 1:2
            iscat_ctr_cmb(c, i0:i0+candidates_in_FOV-1) = ...
                abs(candidates(f).iscat(channel_ids(c)).ctr).^(1/3) .* sign(candidates(f).iscat(channel_ids(c)).ctr);
        end

        %add fluorescence channel
        fluo_ctr_cmb(:, i0:i0+candidates_in_FOV-1) = ...
            abs(candidates(f).fluo(1).ctr).^(1/2) .* sign(candidates(f).fluo(1).ctr);

        i0 = i0+candidates_in_FOV;
    end
    
    %only use positive data
    valid = and(iscat_ctr_cmb(1,:)>0, iscat_ctr_cmb(2,:)>0);
    iscat_1 = iscat_ctr_cmb(1,valid)';
    iscat_2 = iscat_ctr_cmb(2,valid)';
    fluo_ctr = fluo_ctr_cmb(1, valid)';

    %fit the data in the intermediate range
    fitted = iscat_1>low_threshold & iscat_2>low_threshold & iscat_2<high_threshold;
    P = fitlm(iscat_1(fitted), iscat_2(fitted), 'Intercept', false);
    m = P.Coefficients{1,1};

    %define dataranges and stitch SP contrasts
    iscat_ctr = iscat_1;
    iscat_ctr(fitted) = (iscat_1(fitted) + 1/m*iscat_2(fitted)) / 2;
    high = iscat_2>high_threshold;          %only use iscat_2 here!
    iscat_ctr(high) = 1/m*iscat_2(high);
    low = ~fitted & ~high;
    
    clr = [0.2627    0.5765    0.7647; ...
        0.6458    0.4    0.6458;...
        0.8392    0.3765    0.3020];
    
    %plotting
    marker_size = 20;
    fig = figure('DefaultAxesFontSize', 12);
    fig.Position = [0, 0, 2*624/2, 2*624/2];

    %axes 1: low wavelength iSCAT data
    ax1 = axes('OuterPosition', [0.0, 0.5, 0.5, 0.5]);
    ax1.LineWidth = 1.5;
    hold on
    box on
    scatter(iscat_1, fluo_ctr, marker_size, '.', 'MarkerEdgeColor', clr(1,:));
    xlim(xl);
    xticks(xl(1):0.1:xl(2))
    ylim(yl);
    xlabel('$\sqrt[3]{C_{440 nm}}$', 'Interpreter', 'latex')
    ylabel('$\sqrt[3]{I_{DiI}}$', 'Interpreter', 'latex')
    
    %axes 2: high wavelength iSCAT data
    ax2 = axes('OuterPosition', [0.5, 0.5, 0.5, 0.5]);
    ax2.LineWidth = 1.5;
    hold on
    box on
    scatter(iscat_2, fluo_ctr, marker_size, '.', 'MarkerEdgeColor', clr(3,:));
    xlim(xl);
    xticks(xl(1):0.1:xl(2))
    ylim(yl);
    xlabel('$\sqrt[3]{C_{740 nm}}$', 'Interpreter', 'latex')
    ylabel('$\sqrt[3]{I_{DiI}}$', 'Interpreter', 'latex')

    %axes 3: SP correlation plot
    ax3 = axes('OuterPosition', [0.0, 0.0, 0.5, 0.5]);
    ax3.LineWidth = 1.5;
    hold on
    box on
    scatter(iscat_1, iscat_2, marker_size, '.', 'HandleVisibility', 'off', 'MarkerEdgeColor', [0.5, 0.5, 0.5]);
    scatter(iscat_1(fitted), iscat_2(fitted), marker_size, '.', 'HandleVisibility', 'off', 'MarkerEdgeColor', clr(2,:));
    xplot = linspace(xl(1), xl(2), 1000);
    plot(xplot, m*xplot, 'k', 'LineWidth', 1.5)
    xlim(xl);
    xticks(xl(1):0.1:xl(2))
    ylim(xl);
    xlabel('$\sqrt[3]{C_{440 nm}}$', 'Interpreter', 'latex')
    ylabel('$\sqrt[3]{C_{740 nm}}$', 'Interpreter', 'latex')
    
    %axes 3: SP combined
    ax4 = axes('OuterPosition', [0.5, 0.0, 0.5, 0.5]);
    ax4.LineWidth = 1.5;
    hold on
    box on
    
    scatter(iscat_ctr(high), fluo_ctr(high), marker_size, '.', 'MarkerEdgeColor', clr(3,:));
    scatter(iscat_ctr(fitted), fluo_ctr(fitted), marker_size, '.', 'MarkerEdgeColor', clr(2,:));
    scatter(iscat_ctr(low), fluo_ctr(low), marker_size, '.', 'MarkerEdgeColor', clr(1,:));

    xlim(xl);
    xticks(xl(1):0.1:xl(2))
    ylim(yl);
    xlabel('$\sqrt[3]{C_{combined}}$', 'Interpreter', 'latex')
    ylabel('$\sqrt[3]{I_{DiI}}$', 'Interpreter', 'latex')
    drawnow;
    
    %add the stitched contrast measurement to the candidates struct
    channel_ids = find(params.iscat_chans);
    for f=1:params.num_FOVs
        iscat_1 = abs(candidates(f).iscat(1).ctr).^(1/3) .* sign(candidates(f).iscat(1).ctr);
        iscat_2 = abs(candidates(f).iscat(channel_ids(c)).ctr).^(1/3) .* sign(candidates(f).iscat(channel_ids(c)).ctr);
    
        %stitch
        iscat_ctr = iscat_1;
        middle = iscat_1>low_threshold & iscat_2>low_threshold & iscat_2<high_threshold;
        iscat_ctr(middle) = (iscat_1(middle) + 1/m*iscat_2(middle)) / 2;
        high = iscat_2>high_threshold;
        iscat_ctr(high) = 1/m*iscat_2(high);
    
        %write to candidates without applying scaling
        candidates(f).iscat_ctr = iscat_ctr.^3;
    end
    %save candidates data
    save([params.fpath, 'candidates.mat'], 'candidates')
end