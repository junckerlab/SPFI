function crud = h5r_crud(fid, fv, varargin)
    %read the crud or optionally the overexposure areas

    dset = '/crud/fv';
     for i = 1:2:nargin-3
        switch varargin{i}
            case 'overexposure'
                dset = '/overexposure/fv';
        end
     end

    dset = [dset, num2str(fv)];
    
    try
        crud = h5read(fid, dset);
    catch
        %if we're here that means there is no crud saved in the h5 file
        %leave the file as it is but return an empty array
        [~, ~, ~, dim_x, dim_y] = h5struct(fid);
        crud = false(dim_x, dim_y);
    end
end