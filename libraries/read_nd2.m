function ch = read_nd2(file)
    %Read nd2 file containing multiple channels and FOVs
    reader = bfGetReader(file);
    
    omeMeta = reader.getMetadataStore();
    num_fov = omeMeta.getImageCount();
    num_chans = omeMeta.getChannelCount(0);
    [dx, dy] = size(bfGetPlane(reader, 1));
    
    %preallocate last element
    ch(num_chans).fov(num_fov).raw = zeros(dx, dy);
    for i = 1:num_fov
        reader.setSeries(i-1);
            for j = 1:num_chans
                ch(j).fov(i).raw = double(bfGetPlane(reader, j));
            end
    end
    reader.close();
end

