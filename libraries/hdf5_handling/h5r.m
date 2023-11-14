function data = h5r(fid, tp, ch, fv, varargin)

    %each FOV has an attribute that describes how to displace the frame for
    %regular alignment. If true, the alignment is applied before the frame
    %is returned
    align_fov = true;

    %if a channel is requested that is missing, return empty array. If
    %false, produce error and print which dataset is missing
    ignore_missing_data = false;

    %parse kwargs
    for i = 1:2:nargin-4
        switch varargin{i}
            case 'align_fov'
                align_fov = varargin{i+1};
            case 'ignore_missing_data'
                ignore_missing_data = varargin{i+1};
        end
    end

    dset = ['/tp', num2str(tp), '/ch', num2str(ch), '/fv', num2str(fv), '/smooth'];
    try
        data = h5read(fid, dset);
    catch
        if ignore_missing_data
            data = [];
            return
        else
            ME = MException('MyComponent:incorrect_input', ['h5_read ', dset, ' not found']);
            throw(ME);
        end
    end

    if align_fov
        try
            %old files don't have the 'alignment' attribute but are
            %"hard-aligned', aka alignment written in frame
            %new files have it and need to be translated
            %get rid of this try eventually (once all files have the
            %'alignment' attribute)
            offs = h5r_attr(fid, tp, ch, fv, 'alignment');
            data = imtranslate(data, flip(offs'), 'Method', 'cubic');
        end
    end
    

end