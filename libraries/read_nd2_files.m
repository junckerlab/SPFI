function read_nd2_files(params)
    %read the nd2 files and sort everything into the h5 file
    
    if ismac
        slash = '/';
    elseif ispc
        slash = '\';
    end

    h = waitbar(0, 'Writing h5 file ...');
    for t = 1:params.num_timepoints
        %get all files in the folder (folder is called just '1', '2', etc)
        fstr = dir([params.fpath, num2str(t), slash]);
        fnames = {fstr(:).name};

        for c = 1:params.num_channels
            %first figure out if there are high-res iSCAT channels
            valid = contains(fnames, ['channel', num2str(c)]);
            num_files_found = sum(valid);
            if num_files_found == 0
                ME = MException('MATLAB:FileIO:FileNotFound', ['Timepoint ', num2str(t), ' Channel ', num2str(c), ' file missing']);
                throw(ME);  
            elseif num_files_found > 1
                ME = MException('MATLAB:FileIO:InvalidFid', ['Timepoint ', num2str(t), ' Channel ', num2str(c), ' multiple files found']);
                throw(ME);  
            end

            is_iscat = params.iscat_chans(c);
            if is_iscat
                %this is an iSCAT channel
                flatfield_id = find(contains(fnames, ['flatfield', num2str(c)]));
                if isempty(flatfield_id)
                    ME = MException('MATLAB:FileIO:FileNotFound', ['Timepoint ', num2str(t), ' Channel ', num2str(c), ' flatfield file missing']);
                    throw(ME);  
                elseif size(flatfield_id, 2) > 1
                    ME = MException('MATLAB:FileIO:InvalidFid', ['Timepoint ', num2str(t), ' Channel ', num2str(c), ' multiple flatfield files found']);
                    throw(ME);
                end 

                %read in the flatfield file
                flatfield_file = [params.fpath,  num2str(t), slash, fnames{flatfield_id}];
                ch = read_nd2(flatfield_file);
                flatfield = ch(1).fov(1).raw;

                %read in the iSCAT file
                iscat_file = [params.fpath,  num2str(t), slash, fnames{valid}];
                ch_raw = read_nd2(iscat_file);  
                for f = 1:params.num_FOVs
                    frame = double(ch_raw(1).fov(f).raw);
                    %pre-process the frame
                    frame = frame ./ flatfield;                     %flatfield it
                    frame = frame ./ imgaussfilt(frame, 10);        %pseudo flatfield
                    frame = frame / median(frame, "all");           %re-normalize
                    
                    %write into h5 file
                    h5w(params.h5_file, t, c, f, frame);  

                    %update waitbar
                    current_iteration = (t-1)*params.num_channels*params.num_FOVs + ...
                                        (c-1)*params.num_FOVs + ...
                                        f;
                    progress = current_iteration / (params.num_timepoints*params.num_channels*params.num_FOVs);
                    waitbar(progress, h, sprintf('Writing h5 file ... %d%%', int32(100*progress)));    
                end
            else
                %this is a fluorescence channel
                iscat_file = [params.fpath,  num2str(t), slash, fnames{valid}];
                ch_raw = read_nd2(iscat_file);
                for f = 1:params.num_FOVs
                    frame = double(ch_raw(1).fov(f).raw);
    
                    %Subtract background inhomogeneities from the frame. Sort of like the pseudo flatfield. 
                    % However, the fluo channels have much greater dynamic range so we cap the
                    % intensity values before creating the pseudo flatfield,
                    % else we produce dark ring artifacts around them
                    med_frame = median(frame(:));
                    std_frame = 50;
                    clipped_frame = frame;
                    clipped_frame(frame > med_frame+std_frame) = med_frame+std_frame;
                    clipped_frame(frame < med_frame-std_frame) = med_frame-std_frame;
                    frame = frame - imgaussfilt(clipped_frame, 10);                     %pseudo flatfield
                    frame = frame - median(frame, "all");                               %normalize
    
                    %write into h5 file
                    h5w(params.h5_file, t, c, f, frame);

                    %update waitbar
                    current_iteration = (t-1)*params.num_channels*params.num_FOVs + ...
                                        (c-1)*params.num_FOVs + ...
                                        f;
                    progress = current_iteration / (params.num_timepoints*params.num_channels*params.num_FOVs);
                    waitbar(progress, h, sprintf('Writing h5 file ... %d%%', int32(100*progress)));                     
                end
            end
        end
    end
    close(h);
    clear h
end