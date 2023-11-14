function h5w(fid, tp, ch, fv, data)
    [dx, dy] = size(data);
    dset = ['/tp', num2str(tp), '/ch', num2str(ch), '/fv', num2str(fv), '/smooth'];
    
    try
        %check how to see if dataset exists...
        h5create(fid, dset, [dx, dy]);
    end
    h5write(fid, dset, data);
end