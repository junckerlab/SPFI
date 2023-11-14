%find common displacement btw input and reference spots for image alignment
%both lists will contain plenty spots that are not present in the other
%Strategy: find the diplacement vector btw. all spots, apply binning to
%account for small jitter in spot localization, and find the correct
%displacement from searching for the winning bucket

function best_disp = find_displacement_from_spot_coordinates(reference_spots, input_spots)
    max_jitter = 2;
    bucket_size = max_jitter * 2 + 1;
    max_displacement = 250;
    
    votes = containers.Map('KeyType', 'char', 'ValueType', 'any');

    if isempty(reference_spots) || isempty(input_spots)
        best_disp = [0, 0];
        return
    end
    
    for i = 1:size(reference_spots, 1)
        for j = 1:size(input_spots, 1)
            dx = input_spots(j, 1) - reference_spots(i, 1);
            dy = input_spots(j, 2) - reference_spots(i, 2);
            
            % Bucketing the displacements
            bucket_dx = round(dx / bucket_size);
            bucket_dy = round(dy / bucket_size);
            
            bucket_key = sprintf('%d,%d', bucket_dx, bucket_dy);
            
            if isKey(votes, bucket_key)
                votes(bucket_key) = [votes(bucket_key); dx, dy];
            else
                votes(bucket_key) = [dx, dy];
            end
        end
    end
    
    % Finding the bucket with the most votes within max_displacement
    all_keys = keys(votes);
    all_counts = zeros(length(all_keys), 1);
    for k = 1:length(all_keys)
        key = all_keys{k};
        [bucket_dx, bucket_dy] = strtok(key, ',');
        bucket_dx = str2double(bucket_dx) * bucket_size;
        bucket_dy = str2double(bucket_dy(2:end)) * bucket_size;
        if abs(bucket_dx) <= max_displacement && abs(bucket_dy) <= max_displacement
            all_counts(k) = size(votes(key), 1); % Each vote has 2 components (dx, dy)
        end
    end
    [~, max_index] = max(all_counts);
    
    best_bucket_values = votes(all_keys{max_index});
    
    % Calculating the mean of the displacements in the winning bucket
    %(to reverse binning)
    best_disp = [mean(best_bucket_values(:, 1)), mean(best_bucket_values(:, 2))];
end
