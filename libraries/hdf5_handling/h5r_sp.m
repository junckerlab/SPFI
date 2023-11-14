function [spots_pos_x, spots_pos_y] = h5r_sp(fid, t, c, f, varargin)
    %hdf5 wants to keep the dataset sizes constant. So we allocate for a max number
    %of spots and pad around that
    
        
    dataset = 'spots';
    for i = 1:2:nargin-4
        switch varargin{i}
            case 'dataset'
                dataset = varargin{i+1};
        end
    end
    
    dset = ['/tp', num2str(t), '/ch', num2str(c), '/fv', num2str(f), '/', dataset];
    try
        %check if dset exists!
        spots_pad = h5read(fid, dset);
        spots_pos_x = spots_pad(1, :);
        spots_pos_x = spots_pos_x(spots_pos_x ~= 0);
        spots_pos_y = spots_pad(2, :);
        spots_pos_y = spots_pos_y(spots_pos_y ~= 0);
    catch
        spots_pos_x = [];
        spots_pos_y = [];
    end

end