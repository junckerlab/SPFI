function h5w_border(fid, fv, border_mask, flag)

    %flag == 0: crash
    %flag == 1: append
    %flag == 2: overwrite
    if ~exist('flag', 'var')
        flag = 1;
    end

    [dx, dy] = size(border_mask);
    dset = ['/border/fv', num2str(fv)];
    
    if flag == 0
        %create dataset - error if it exists
        h5create(fid, dset, [dx, dy]);
    end

    try
        %check how to see if dataset exists...
        h5create(fid, dset, [dx, dy]);
    catch
        if flag == 1
            %already exists, so read the old one
            old_border = h5r_border(fid, fv);
            border_mask = double(or(old_border, border_mask));
        end
    end

    h5write(fid, dset, border_mask);
end