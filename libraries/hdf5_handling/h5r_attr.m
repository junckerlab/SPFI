function val = h5r_attr(fid, tp, ch, fv, attr)
    loc = ['/tp', num2str(tp), '/ch', num2str(ch), '/fv', num2str(fv)];
    
    try
        val = h5readatt(fid, loc, attr);
    catch
        %fprintf(['Tp', num2str(tp), ' Ch', num2str(ch), 'FOV', num2str(fv), ...
        %    ' - ', attr, ' not found']);
        val = [0, 0];   %using this for the alignment exclusively rn...
    end
    %h5disp(fid, loc);

    %stupid legacy stuff.Forcelinevectors
    [c,l] = size(val);
    if l<c
        val = val';
    end
    
end