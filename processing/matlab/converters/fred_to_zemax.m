


% Convert FRED file to Zemax BSDF file:

clc, clearvars, close all



filepath_fred = "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\fred\AnoBlackNiTEonINVAR.txt";


% Query points for FRED-to-Zemax interpolation:
Az_q = 0 : 10 : 180; % [0, 180] if isotropic, [0, 360) if anisotropic
Rz_q = [0 : 5 : 15, 20 : 10 : 180]; % [0, 180]

ISOTROPIC = true;
OVERWRITE = true;
MAX_IS_SPECULAR= true;


filepath_zemax = "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\zemax\AnoBlackNiTEonINVAR_test.bsdf";
    % name of new BSDF file to output results to; include '.bsdf' extension




repo_version = "v1.4.0"; % tag of 'bsdf-tools' repo release at time Zemax BSDF file is processed
name_contact = "Jacob P. Krell (jacobpkrell@arizona.edu)"; % name of person
    % to contact, most likely you or whoever made the measurement; consider
    % including email or phone number in parentheses too
name_sample = "Anoplate AnoBlack NiTE w/ Blast on INVAR 36"; 
    % name of sample measured
name_source = "red laser (650 nm, 3.5mm spot diam.)"; 
    % name of light source used
name_angles = "(10:20:70, -90:10:90, -80:10:80)"; % in (I,A,R) order

% Filenames of measurements, where first element is the blank data used
% to zero the sample measurements:
    % - include '.xls' extension;
filenames = ["blank_v2o0_20250911.xls"; ... % blank
             "NiTE_on_invar_v1o0A_20250915.xls"; ... % measured dataset 1
             "NiTE_on_invar_v1o0B_20250916.xls"; ... % ...
             "NiTE_on_invar_v1o0C_20250916.xls"]; % measured dataset M

name_dates = ["2025/09/15", "2025/09/16"]; % date(s) measurements were made
















% end user inputs
% ======

[Pi, Ai, Ps, As, BRDF] = load_fred(filepath_fred);

[S, I, Az, Rz] = fred_frame_to_zemax(Pi, Ai, Ps, As);




% NOT YET VALIDATED, BUT ON SURFACE NO BUGS:
[S, I, Az, Rz, BRDF] = interpolate_zemax(S, I, Az, Rz, BRDF, Az_q, Rz_q, ISOTROPIC, MAX_IS_SPECULAR);



% Write to BSDF file:
header_info = generate_rt300s_header_info(...
    repo_version, ...
    name_contact, ...
    name_sample, ...
    name_source, ...
    name_angles, ...
    filenames, ...
    name_dates);
write_zemax(S, I, Az, Rz, BRDF, filepath_zemax, ISOTROPIC, OVERWRITE, header_info);








