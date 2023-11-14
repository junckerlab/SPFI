function plot_candidate_spot_histograms(params)
    % This function loads candidate spot data and plots histograms for each iSCAT channel.

    % Load candidates data
    load([params.fpath, 'candidates.mat'], 'candidates');

    % Tally up all candidates, allocate arrays
    num_candidates_total = 0;
    for f = 1:params.num_FOVs
        num_candidates_total = num_candidates_total + candidates(f).num_candidates;
    end
    iscat_ctr_cmb = zeros(1, num_candidates_total);
    
    % Aggregate contrast data from all fields of view
    i0 = 1;
    for f = 1:params.num_FOVs    
        numCandInFOV = candidates(f).num_candidates;
        for c = 1:params.num_iscat_chans
            iscat_ctr_cmb(c, i0:i0+numCandInFOV-1) = candidates(f).iscat(c).ctr;
        end
        i0 = i0+numCandInFOV;
    end
    
    % Create histograms and plot
    figure('DefaultAxesFontSize', 10, 'Position',  [100, 100, 800, 300]);
    
    % Create individual subplots for all iSCAT channels
    for c = 1:params.num_iscat_chans
        d = 1 / params.num_iscat_chans;
        axes('OuterPosition', [(c-1)*d, 0, d, 1]);
        iscat_third_root = abs(iscat_ctr_cmb(c,:)).^(1/3) .* sign(iscat_ctr_cmb(c,:));
        edges = linspace(-0.2, 0.5, 50);
        [N, ~] = histcounts(iscat_third_root, edges);            
        bar(edges(1:end-1)+diff(edges), N)
        hold on
        set(gca, 'YScale', 'Log')
        hold on;
        yl = ylim();
        plot([0,0]+params.iscat_thresh, yl, '--k');
        xlabel(['$\sqrt[3]{C_{', num2str(params.channel_wavelengths(c)*1e9), ' nm}}$'], 'Interpreter', 'latex');
        ylabel('Occurence');
        title(['iSCAT ', num2str(params.channel_wavelengths(c)*1e9), ' nm'])
    end
end