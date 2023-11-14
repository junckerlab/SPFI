function diams_nm = calibrate_ctr2d(xl, varargin)
    %calibrate the contrast to diameter scaling for EVs based on silica calibration data
    %xl: x_lims (in third root iSCAT contrast, typically [0, 0.6] of plots that are supposed to be calibrated

    %We found the following silica diameter to contrast values (in SI units) for 440 nm iSCAT:
    silica_calibration = 5.9308*1e19;
    
    %particle refractive index
    %default is EV refractive index estimation
    refractive_index_vesicle = 1.40;

    %refrative index of silica particles
    refractive_index_silica = 1.4663;

    %parse kwargs
    for i = 1:2:nargin-2
        switch varargin{i}
            case 'refractive_index_vesicle'
                if not(isempty(varargin{i+1}))
                    refractive_index_vesicle = varargin{i+1};
                end
            case 'refractive_index_silica'
                refractive_index_silica = varargin{i+1};
        end
    end
    
    %calculate the contrast ratio for silica vs particle of interest
    n_medium = 1.33;
    ctr_ratio = ((refractive_index_vesicle^2 - n_medium^2) / (refractive_index_vesicle^2 + 2*n_medium^2)) / ...
                ((refractive_index_silica^2 - n_medium^2) / (refractive_index_silica^2 + 2*n_medium^2));

    %scale the calibration data
    particle_calibration = silica_calibration * ctr_ratio;
    
    %invert
    ctr2d_particle = (1./particle_calibration).^(1/3);

    %in nanometers
    diams_nm = xl .* ctr2d_particle*1e9;
end