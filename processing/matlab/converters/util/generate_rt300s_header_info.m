
function header_info = generate_rt300s_header_info(...
    repo_version, ...
    name_contact, ...
    name_sample, ...
    name_source, ...
    name_angles, ...
    filenames, ...
    name_dates, ...
    num_avg_per_rot, ...
    notes)
    % 'notes' is cell of strings; leave empty (notes = []) is none.

    header_info = ""; % initialize

    % Generate lines to comment:
    line_break = ...
        "# ======================================================\n";
    line_sample = ...
        "# Sample: " + name_sample + "\n";
        % e.g.: "# Sample: NiTE on Invar\n"
    line_source = ...
        "# Light source: " + name_source + "\n";
        % e.g.: "# Light source: red laser\n"
    line_angles = ...
        "# Angles measured: (I,A,R) = " + name_angles + "\n";
        % e.g.: "# Angles measured: (I,A,R) = (10:20:70, -90:10:90, -80:10:80)\n"
    line_blankdataset = ...
        "# Blank dataset: '" + filenames(1) + "'\n";
        % e.g.: "# Blank dataset: 'blank_measurement.xls'\n"
    line_datasets = "# Dataset(s): "; % initialize
    for m = 2 : length(filenames) % first element is blank, so start at 2
        if m > 1 % if not first dataset
            line_datasets = line_datasets + ", "; % add comma between datasets
        end
        line_datasets = line_datasets + "'" + filenames(m) + "'";
    end
    line_datasets = line_datasets + "\n"; % finalize
        % e.g.: "# Dataset(s): 'sample_measurement_1.xls', 'sample_measurement_2.xls', 'sample_measurement_3.xls'\n"
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
    header_info = header_info + "# Scatterometer: Wyant College's J&C RT-300S\n";
    header_info = header_info + line_source;
    header_info = header_info + line_angles;
    header_info = header_info + sprintf("# Number of measurements averaged (per sample rotation): %i\n", num_avg_per_rot);
        % for anisotropic, each dataset is unique sample rotation and therefore
        % no measurements are averaged
    header_info = header_info + line_blankdataset;
    header_info = header_info + line_datasets;
    header_info = header_info + "# Processing script: '" + mfilename() + ".m'\n";
        % e.g.: "# Processing script: 'rt300s_to_bsdf_aniso.m'\n"
    header_info = header_info + "# Processing source: https://github.com/ua-loft/bsdf-tools/tree/" + repo_version + "\n";
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

