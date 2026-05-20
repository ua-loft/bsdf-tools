


% Convert FRED file to Zemax BSDF file:

clc, clearvars, close all



filepath_fred = "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\fred\blacklab\test_blacklab_dev_*nm.txt";
    % If multiwavelength, use format: 
        % filepath_fred = "C:\...\my_fred_file_*nm.txt"
    % for filenames like "my_fred_file_1243o53nm.txt", 
    % "my_fred_file_1380o83nm.txt", ...


% Query points for FRED-to-Zemax interpolation:
Az_q = 0 : 10 : 180; % [0, 180] if isotropic, [0, 360) if anisotropic
Rz_q = [0 : 5 : 15, 20 : 10 : 180]; % [0, 180]

ISOTROPIC = true;
OVERWRITE = true;
MAX_IS_SPECULAR= false;
MULTI_WAVELENGTH = true;


filepath_zemax = "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\zemax\blacklab\test_blacklab_dev.bsdf";
    % name of new BSDF file to output results to; include '.bsdf' extension

    % If multiwavelength, use format: 
        % filepath_zemax = "C:\...\my_zemax_file.bsdf"
    % to generate filenames like "my_zemax_file_1243o53nm.bsdf", 
    % "my_zemax_file_1380o83nm.bsdf", ... assuming the FRED files are in
    % that format of "..._XXXXoXXnm".




repo_version = "v1.4.1"; % tag of 'bsdf-tools' repo release at time Zemax BSDF file is processed
name_contact = "Jacob P. Krell (jacobpkrell@arizona.edu)"; % name of person
    % to contact, most likely you or whoever made the measurement; consider
    % including email or phone number in parentheses too

name_sample = "test blacklab dev";
    % name of sample measured


name_source = "multi (RSG's Blacklab)"; 
    % name of light source used

name_angles = "blah";

% Filenames of raw measurements, where first element is the blank data used
% to zero the sample measurements:
    % - include '.xls' extension (or other extension if not RT-300S);
    % - use double quotations;
    % - use filename only, not filepath;
filenames = ["20250409_S7_swir_sample.txt"];

name_dates = ["sometime CE"]; % date(s) measurements were made

num_avg_per_rot = 1; % number of measurements per stage rotation angle 
    % (which get averaged; note assumes same number per each rotation);

    % NOTE IF ISOTROPIC AND RT-300S, and have (A,R) = (-A,-R) data, then 
    % double number of measurement files because R>0 for A \in [-90,0] is 
    % same as R<0 for A \in [0,90].

notes = []; 
    % [] or {'my first note', 'my second note'};








% end user inputs
% ======


% Get all filepaths if multiple files:
if MULTI_WAVELENGTH
    D = dir(filepath_fred);
    filepaths_fred = cell(size(D));
    dirpath_fred = string(fileparts(filepath_fred)) + filesep;
    filenames_fred = string({D.name});
    for j = 1 : length(filenames_fred)
        filepaths_fred{j} = dirpath_fred + filenames_fred(j);
    end

    % Generate corresponding Zemax file names:
        % - assumes suffix of FRED file name, defined by last underscore
        % and subsequent characters, is to be appended to given Zemax
        % filename target
    filepath_zemax = filepath_zemax{1}(1 : end-5); % remove '.bsdf'
    filepath_zemax = convertCharsToStrings(filepath_zemax);
    filepaths_zemax = cell(size(filepaths_fred));
    for j = 1 : length(filepaths_fred)
        suffix = filepaths_fred{j};
        suffix = suffix{1}(1 : end-4); % remove '.txt'
        IS_UNDERSCORE = false;
        k = -1; % initialize so k=0 on first iteration
        while ~IS_UNDERSCORE
            k = k + 1;
            if strcmp(suffix(end - k), '_')
                IS_UNDERSCORE = true;
            end
        end
        suffix = suffix(end-k : end); % '..._XXXXoXXnm' of FRED file
        filepaths_zemax{j} = filepath_zemax + suffix + ".bsdf";
    end

else
    filepaths_fred = {filepath_fred}; % formatting as cell allows generalized code later
    filepaths_zemax = {filepath_zemax};
end




% Per file, load and process data:

for j = 1 : length(filepaths_fred)

filepath_fred = filepaths_fred{j};
filepath_zemax = filepaths_zemax{j};




% =========================================================================
% [BEGIN] SAME CODE AS FOR ORIGINAL (I.E., RT-300S PRIOR TO INCLUSION OF 
% BLACKLAB) MONOCHROMATIC CASE:


[Pi, Ai, Ps, As, BRDF] = load_fred(filepath_fred);

[S, I, Az, Rz] = fred_frame_to_zemax(Pi, Ai, Ps, As);



% Calculate TIS per stage rotation and incident angle pair:
TIS = calculate_TIS(Pi, Ai, Ps, As, BRDF, ISOTROPIC);
    % Format: TIS(S_inde, I_index)



% NOT YET VALIDATED (well probably is, with newer ppt slides showing 
% IMX455 results... but hold off on full "validated" claim), BUT ON 
% SURFACE NO BUGS:
[S, I, Az, Rz, BRDF] = interpolate_zemax(S, I, Az, Rz, BRDF, Az_q, Rz_q, ISOTROPIC, MAX_IS_SPECULAR);





% Write to BSDF file:
mfilename_parent = mfilename(); % = "fred_to_zemax"
header_info = generate_rt300s_header_info(...
    repo_version, ...
    name_contact, ...
    name_sample, ...
    name_source, ...
    name_angles, ...
    filenames, ...
    name_dates, ...
    num_avg_per_rot, ...
    notes, ...
    mfilename_parent);
write_zemax(S, I, Az, Rz, BRDF, TIS, filepath_zemax, ISOTROPIC, OVERWRITE, header_info);







end

% [END] SAME CODE AS FOR ORIGINAL (I.E., RT-300S PRIOR TO INCLUSION OF 
% BLACKLAB) MONOCHROMATIC CASE.
% =========================================================================




