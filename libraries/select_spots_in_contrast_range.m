function [pos_x, pos_y, valid] = select_spots_in_contrast_range(frame, pos_x, pos_y, range)
    pos_lin = sub2ind(size(frame), pos_x, pos_y);
    values = frame(pos_lin);
    valid = and(values > range(1), values < range(2));
    pos_x = pos_x(valid);
    pos_y = pos_y(valid);    
end