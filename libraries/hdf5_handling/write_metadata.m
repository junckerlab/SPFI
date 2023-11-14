function params = write_metadata(params)
    if ismac
        slash = '/';
    elseif ispc
        slash = '\';
    end

    for i = params.evaluate
            %read the metadata
            
            fstr = dir([params.fpath,  num2str(1), slash]);
            fnames = {fstr(:).name};
    
            id = find(contains(fnames,'fluorescence'));
            
            if size(id, 2) < 1
                ME = MException('MyComponent:incorrect_input', 'No Fluorescence file found');
                throw(ME);
            elseif size(id, 2) > 1
                ME = MException('MyComponent:incorrect_input', 'Multiple Fluorescence files found');
                throw(ME);
            end
        
            file = [params.fpath,  num2str(1), slash, char(fnames(id))];
            metadata = read_nd2_metadata(file);
            metadata.num_tps = params.h5(i).num_tps;
            metadata.num_fovs = params.num_fovs;
            metadata.num_chans = params.num_chans;
            metadata.chan_names = params.OC_names;
            metadata.is_iscat = params.iscat;
            metadata.channel_wavelengths = params.channel_wavelengths;

            h5w_metadata(params.h5(i).fid, metadata);
            
            fn = fieldnames(metadata);
            for k = 1:size(fn, 1)
                %check if it's in the params struct
                field_name = char(fn(k));
                if isfield(params, field_name)
                    %check if the field name is already in the params (i.e.
                    %it is user input. Then we don't override but we check
                    %if the values match and generate some output to warn
                    %the user.

                    if not(isnumeric(params.(field_name)))
                        %special case of non-numeric metadata. Right now
                        %that is only the channel names and there is no
                        %user input for it. But it is in the params strucct
                        %if we execute this function here multiple times
                    else
                        if not(params.(field_name) == metadata.(field_name))
                            fprintf(['Warning: User input ', field_name, ' = ', num2str(params.(field_name)), ...
                                ' whereas nd2 file contains ', num2str(metadata.(field_name))]);
                        end
                    end
                else
                    %if its not there just write into params
                    params.(field_name) = metadata.(field_name);
                end
            end
            
    end
end