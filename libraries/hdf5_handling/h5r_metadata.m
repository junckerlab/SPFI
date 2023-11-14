function metadata = h5r_metadata(fid)
    %get all attributes on the top level of the h5 file and pack them into
    %struct as metadata
    hinfo = h5info(fid);
    num_attr = size(hinfo.Attributes, 1);
    metadata = struct();
    
    for f = 1:num_attr
        fname = hinfo.Attributes(f).Name;
        metadata.(fname) = hinfo.Attributes(f).Value;
    end
end