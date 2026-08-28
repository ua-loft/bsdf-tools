
function header_info = generate_zemax_header_info(...
    name_sample, ...
    name_scatterometer, ...
    name_source, ...
    name_angles, ...
    num_avg_per_rot, ...
    blank_dataset_filename, ...
    dataset_filenames, ...
    mfilename_parent, ...
    repo_version, ...
    name_dates, ...
    notes, ...
    name_contact)
    % Use double quotes for all, not single (not char). E.g., 'var = "s"'.
    % If leaving blank, set input to "" or "n/a" or similar; not to [].
    % Except, set 'notes = []' if 'notes' is none.
    % For blank and dataset filenames, include quotes in string; e.g.,
    %     blank_dataset_filename = "'example.txt'";
    % For multiple dataset filenames, 

    header_info = ""; % initialize

    if isinteger(num_avg_per_rot)
        num_avg_per_rot_as_str = num2str(num_avg_per_rot);
    else
        num_avg_per_rot_as_str = num_avg_per_rot; % assume "" or "n/a", etc.; not []
    end

    if ~blank_dataset_filename == "" % if blank, do not add quotes
        blank_dataset_filename = "'" + blank_dataset_filename + "'"; % add quotes
    end

    % Generate lines to comment:
    line_break = ...
        "# ======================================================\n";
    line_sample = ...
        "# Sample: " + name_sample + "\n";
        % e.g.: "# Sample: NiTE on Invar\n"
    line_scatterometer = ...
        "# Scatterometer: " + name_scatterometer + "\n";
        % e.g.: "# Scatterometer: Wyant College's J&C RT-300S\n"
    line_source = ...
        "# Light source: " + name_source + "\n";
        % e.g.: "# Light source: red laser\n"
    line_angles = ...
        "# Angles measured: " + name_angles + "\n";
        % e.g.: "# Angles measured: (I,A,R) = (10:20:70, -90:10:90, -80:10:80)\n"
    line_num_avg_per_rot = ...
        "# Number of measurements averaged (per sample rotation): " + num_avg_per_rot_as_str + "\n";
        % for anisotropic, each dataset is unique sample rotation and therefore
        % no measurements are averaged
    line_blankdataset = ...
        "# Blank dataset: " + blank_dataset_filename + "\n";
        % e.g.: "# Blank dataset: 'blank_measurement.xls'\n"
    line_datasets = "# Dataset(s): "; % initialize
    for m = 1 : length(dataset_filenames) % assuming 'dataset_filenames' is cell
        if m > 1 % if not first dataset
            line_datasets = line_datasets + ", "; % add comma between datasets
        end
        line_datasets = line_datasets + "'" + dataset_filenames(m) + "'";
    end
    line_datasets = line_datasets + "\n"; % finalize
        % e.g.: "# Dataset(s): 'sample_measurement_1.xls', 'sample_measurement_2.xls', 'sample_measurement_3.xls'\n"
    line_processing_script = ...
        "# Processing script: '" + mfilename_parent + ".m'\n";
        % e.g.: "# Processing script: 'fred_to_zemax.m'\n"
    line_processing_source = ...
        "# Processing source: https://github.com/ua-loft/bsdf-tools/tree/" + repo_version + "\n";
        % e.g.: "# Processing source: https://github.com/ua-loft/bsdf-tools/tree/v1.5.1\n"
    line_dates = "# Date(s) measured: "; % initialize
    for date_id = 1 : length(name_dates)
        if date_id > 1 % if not first date
            line_dates = line_dates + ", "; % add comma between dates
        end
        line_dates = line_dates + name_dates(date_id);
    end
    line_dates = line_dates + "\n"; % finalize
        % e.g.: "# Date(s) measured: 2025/09/15, 2025/09/16\n"

    % Compile comments into single string:
    header_info = header_info + line_break;
    header_info = header_info + line_break;
    header_info = header_info + "# [BEGIN] DEVELOPMENT INFORMATION:\n";
    header_info = header_info + "# \n";
    header_info = header_info + line_sample;
    header_info = header_info + line_scatterometer;
    header_info = header_info + line_source;
    header_info = header_info + line_angles;
    header_info = header_info + line_num_avg_per_rot;
    header_info = header_info + line_blankdataset;
    header_info = header_info + line_datasets;
    header_info = header_info + line_processing_script;
    header_info = header_info + line_processing_source;
    header_info = header_info + line_dates;
    header_info = header_info + "# Note(s): ";
    if ~isempty(notes) % if not empty
        header_info = header_info + sprintf("- %s;\n", notes{1}); % first
        if length(notes) > 1 % need to indent non-first notes
            for j = 2:length(notes) % first already written
                header_info = header_info + sprintf("#          - %s;\n", notes{j});
            end
        end
    else
        header_info = header_info + "\n";
    end
    header_info = header_info + "# Point of contact: " + name_contact + "\n";
        % e.g.: 
        % "# Point of contact: Jacob P. Krell (jacobpkrell@arizona.edu)\n"
    header_info = header_info + "# \n";
    header_info = header_info + "# [END] DEVELOPMENT INFORMATION.\n";
    header_info = header_info + "# ======================================================\n";
    header_info = header_info + "# ======================================================\n";
    header_info = header_info + "# \n";

end

