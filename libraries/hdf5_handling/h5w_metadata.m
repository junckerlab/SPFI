function h5w_metadata(fid, metadata)
    %assume metadata is a struct, write all fields of it into the h5 file
    fnames = fieldnames(metadata);
    n = size(fnames, 1);
    for f=1:n
        fname = char(fnames(f));
        h5writeatt(fid, '/', fname, metadata.(fname));
    end
end