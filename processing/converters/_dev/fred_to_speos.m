
% DO NOT USE. THIS IS UNFINISHED PSEUDOCODE.
% USE EXTERNAL PYTHON FUNCTION.
% SEE: 
    % -https://github.com/ansys/optical-automation/blob/main/ansys_optical_automation/application/BSDF_converter_example.py

% =========================================================================
% =========================================================================

% =========================================================================
% =========================================================================

% =========================================================================
% =========================================================================
% 
% fred_to_speos.m
% 
% Description:
%   - Convert FRED BRDF file to SPEOS format.
% 
% Assumptions:
%   1) 
% 
% Developer(s):
%   - Jacob P. Krell (JPK)
%       - LOFT research assistant
%       - MS Optomechanical Engineering, 
%         Wyant College of Optical Sciences, University of Arizona
%       - jacobpkrell@arizona.edu, jakepkrell@gmail.com
%
% Development History:
% | Date       | Dev. | Comment(s)                                        |
% |------------|------|---------------------------------------------------|
% | 2026.05.21 | JPK  | Initialized using 'fred_to_zemax' as template;    |
% 
% References:
% [1] 
% 
% =========================================================================
% =========================================================================
% =========================================================================
% =========================================================================

clearvars, clc, close all

% =========================================================================
% [BEGIN] USER INPUTS:

filepath_fred = "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\fred\MagicBlackOnAlum.txt";

% % Query points for FRED-to-SPEOS interpolation:
% Az_q = 0 : 10 : 180; % [0, 180] if isotropic, [0, 360) if anisotropic
% Rz_q = [0 : 5 : 15, 20 : 10 : 180]; % [0, 180]

% ISOTROPIC = true;
OVERWRITE = true;
% MAX_IS_SPECULAR= false;


filepath_speos = "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\zemax\MagicBlackOnAlum.bsdf";
    % name of new BSDF file to output results to; include '.bsdf' extension

repo_version = "v1.4.0"; % tag of 'bsdf-tools' repo release at time Zemax BSDF file is processed

name_contact = "Jacob P. Krell (jacobpkrell@arizona.edu)"; % name of person
    % to contact, most likely you or whoever made the measurement; consider
    % including email or phone number in parentheses too

name_sample = "Magic Black on Aluminum";
    % name of sample measured

name_source = "red laser (650 nm, 3.5mm spot diam.)"; 
    % name of light source used

name_angles = "(I,A,R) = (10:20:70, -90:10:80, -80:10:80)";

% Filenames of measurements, where first element is the blank data used
% to zero the sample measurements:
    % - include '.xls' extension;
    % - use double quotations;
    % - use filename only, not filepath;
filenames = ["blank_v2o0_20250911.xls"; ... % blank
             "NiTE_on_invar_v1o0A_20250915.xls"; ... % measured dataset 1
             "NiTE_on_invar_v1o0B_20250916.xls"; ... % ...
             "NiTE_on_invar_v1o0C_20250916.xls"]; % measured dataset M

name_dates = ["2025/09/15", "2025/09/16"]; % date(s) measurements were made

num_avg_per_rot = 2; % number of measurements per stage rotation angle 
    % (which get averaged; note assumes same number per each rotation);
    % NOTE IF ISOTROPIC, and have (A,R) = (-A,-R) data, then double number
    % of measurement files because R>0 for A \in [-90,0] is same as R<0 for
    % A \in [0,90].

notes = {"WARNING! Sample was scratched; order of magnitude is accurate but exact scatter pattern is not"}; 
    % [] or {'my first note', 'my second note'};









% end user inputs
% ======

[Pi, Ai, Ps, As, BRDF] = load_fred(filepath_fred);

[S, I, Az, Rz] = fred_frame_to_speos(Pi, Ai, Ps, As);



% Calculate TIS per stage rotation and incident angle pair:
TIS = calculate_TIS(Pi, Ai, Ps, As, BRDF, ISOTROPIC);
    % Format: TIS(S_index, I_index)



% NOT YET VALIDATED (well probably is, with newer ppt slides showing 
% IMX455 results... but hold off on full "validated" claim), BUT ON 
% SURFACE NO BUGS:
[S, I, Az, Rz, BRDF] = interpolate_zemax(S, I, Az, Rz, BRDF, Az_q, Rz_q, ISOTROPIC, MAX_IS_SPECULAR);





% Write to BSDF file:
mfilename_parent = mfilename(); % = "fred_to_speos"
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
write_speos(S, I, Az, Rz, BRDF, TIS, filepath_speos, ISOTROPIC, OVERWRITE, header_info);








