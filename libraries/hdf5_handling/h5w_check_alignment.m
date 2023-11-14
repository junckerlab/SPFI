function is_aligned = h5w_check_alignment(fid, t, c, f)
    %just check the first FOV if it has some alignment on it
    is_aligned = false;

    try
        h5r_attr(fid, t, c, f, 'alignment');
        is_aligned = true;
    end
%     try
%         %check how to see if dataset exists...
%         dset = '/border/fv1';
%         border = h5read(fid, dset);
%         
%         %if the border exists set the flag to true
%         is_aligned = true;
%     end

end