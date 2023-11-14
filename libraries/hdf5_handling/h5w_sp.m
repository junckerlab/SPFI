function h5w_sp(fid, t, c, f, spots_pos_x, spots_pos_y, varargin)
    %hdf5 wants to keep the dataset sizes constant. So we allocate for a max number
    %of spots and pad around that
    %spots_pos_x/y are [1,n arrays]
    %'dataset' varargin is between 'spots' and 'candidates'
    
    dataset = 'spots';
    for i = 1:2:nargin-6
        switch varargin{i}
            case 'dataset'
                dataset = varargin{i+1};
        end
    end
    
    max_spots = 50000;
    spots_pad = zeros(2, max_spots);
    spots_pad(1, 1:size(spots_pos_x, 2)) = spots_pos_x;
    spots_pad(2, 1:size(spots_pos_y, 2)) = spots_pos_y;
    
    dset = ['/tp', num2str(t), '/ch', num2str(c), '/fv', num2str(f), '/', dataset];
    
    try
        %check how to see if dataset exists...
        h5create(fid, dset, [2, max_spots]);
    end
    h5write(fid, dset, spots_pad);
end