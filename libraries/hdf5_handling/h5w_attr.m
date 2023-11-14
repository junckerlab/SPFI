function h5w_attr(fid, tp, ch, fv, attr, val)
    %tp, ch, fv can either be single values or lists
    %attr and val are only single values
    for t = tp
        for c = ch
            for f = fv
                loc = ['/tp', num2str(t), '/ch', num2str(c), '/fv', num2str(f)];
                try
                    h5writeatt(fid, loc, attr, val);
                catch
                    %if the channel does not exists - sjip

                    a=1;
                end
            end
        end
    end
    
    %h5disp(fid, loc);
    
end