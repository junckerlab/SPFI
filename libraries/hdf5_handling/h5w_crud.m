function h5w_crud(fid, fv, crud, varargin)
    %write the crud into file
    %varagin to write overexposed areas
    %creat extra dataset for the overexposure since it can only be detected in the raw files and the crud is often
    %deleted

    dset = '/crud/fv';

     for i = 1:2:nargin-3
        switch varargin{i}
            case 'overexposure'
                dset = '/overexposure/fv';
        end
     end
    
    [dx, dy] = size(crud);
    dset = [dset, num2str(fv)];
    
    try
        %check how to see if dataset exists...
        h5create(fid, dset, [dx, dy]);
    end
    h5write(fid, dset, crud);
end