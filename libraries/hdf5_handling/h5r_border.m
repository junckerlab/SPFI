function crud = h5r_border(fid, fv)
    dset = ['/border/fv', num2str(fv)];
    
    crud = h5read(fid, dset);
end