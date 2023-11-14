function [num_tps, num_chs, num_fvs, dim_x, dim_y] = h5struct(fid)
    info = h5info(fid);
    

    %we might not have all the channels for each timepoint. Find the max
    num_chs = 1;

    %accout for crud and [ossibly other dsets
    dsets = {info.Groups.Name};
    num_tps = 0;
    for t = 1:size(dsets, 2)
        name = char(dsets(t));
        if strcmp(name(1:3), '/tp')
            %good sign. But sometimes we have faulty h5s where there are
            %just some spots accidentally saved in high tps. check if we
            %have real data. Kind of shitty
            
            %if any of the datasets are called 'smooth' we are good. Other
            %datasets in the structure are the 'spots' and possibly
            %'candidates'
            if any(strcmp({info.Groups(t).Groups(1).Groups(1).Datasets(:).Name}, 'smooth'))
                num_tps = num_tps + 1;
            end

            %figure out how many channels there are in this timepoint
            num_chans = size(info.Groups(t).Groups, 1);
            %go to the highest one and see what chan id it has
            ch_name = info.Groups(t).Groups(num_chans).Name;
            ch_id = str2num(ch_name(end));
            %save if it's bigger than what we had before
            num_chs = max(num_chs, ch_id);
        end
    end
        

    
    %find the \tp group (can this be done better(?)
    for t = 1:size(info.Groups, 1)
        if strcmp(info.Groups(t).Name, '/tp1')

            num_fvs = size(info.Groups(t).Groups(1).Groups, 1);
            dim_x = info.Groups(t).Groups(1).Groups(1).Datasets(1).Dataspace.Size(1);
            dim_y = info.Groups(t).Groups(1).Groups(1).Datasets(1).Dataspace.Size(2);
        end
    end
end