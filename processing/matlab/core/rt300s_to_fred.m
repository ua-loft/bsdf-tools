% =========================================================================
% =========================================================================
% 
% rt300s_to_fred.m
% 
% Description:
%   - Process raw monochromatic measurement data from J&C's RT-300S 
%     scatterometer into FRED format, and save FRED file.
% 
% Assumptions:
%   1) Data files are in default Excel format as output by RT-300S.
%   2) Light source is monochromatic.
%   3) Blank has identical angles and same wavelength as sample file(s).
%   4) Sample files (if multiple) are averaged.
%   5) FRED interprets $\phi_s = 0$ at $\theta_s = 0$ as applying to all 
%      $\phi_s \in [0, 360)$.
%   6) FRED interprets having only $\phi_i = 0$ data with 
%      $\phi_s \in [0, 180]$ as meaning $\phi_i \in [0, 360)$ with BRDF
%      data mirrored across the incident plane and 
%      $\phi_s \in [0, 180] + \phi_i$, i.e., isotropic.
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
% | 2026.03.18 | JPK  | Refactored from single-script MATLAB code         |
% |            |      | ('rt300s_to_bsdf_(an)iso.m') into main script     |
% |            |      | calling decoupled functions; RT-300S to FRED;     |
% 
% References:
% [1] Max Duque's whitepaper on RT-300S
% [2] Max Duque's masters thesis
% 
% =========================================================================
% =========================================================================
% =========================================================================
% =========================================================================

clearvars, clc, close all

% =========================================================================
% [BEGIN] USER INPUTS:

% Measured sample(s):
S = 0; % 0 : 10: 90; % stage rotation [deg]; if isotropic set to integer 0, 
    % otherwise define as vector corresponding to 'filepaths_rt300s'
% filepaths_rt300s = {'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation0_20250922.xls', ...
%     'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation10_20250922.xls', ...
%     'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation20_20250922.xls', ...
%     'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation30_20250922.xls', ...
%     'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation40_20250922.xls', ...
%     'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation50_20250922.xls', ...
%     'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation60_20250922.xls', ...
%     'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation70_20250922.xls', ...
%     'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation80_20250922.xls', ...
%     'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation90_20250922.xls'};
%     % cell of filepath(s) to measured RT-300S data (include '.xls')
filepaths_rt300s = {'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\Aeroglaze_9924Primer_2307Black_v1o0A_20260407.xls'};
ISOTROPIC = true; % set true if sample is isotropic
ANISO_W_XZ_SYMM = false; % set true if sample is anisotropic but exhibits 
    % plane-symmetric features (e.g., lenslet array) across YZ plane when 
    % oriented at S=0 (zero stage rotation) and wanting to assume mirroring
    % of measured BRDF values
ANISO_W_YZ_SYMM = false; % same, but for XZ plane

% Filepath of 'blank' (no light source) RT-300S data (include '.xls'):
blankpath_rt300s = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\blank_v3o2_20260412.xls';

% New FRED file's target filepath to save to (include '.txt'):
filepath_fred = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\fred\Aeroglaze_9924Primer_2307Black_onAlum_Aonly_blank3o2.txt';
OVERWRITE = false; % if true and FRED file already exists, will overwrite

% [END] USER INPUTS.
% =========================================================================
% =========================================================================
% ================= The rest of this script is automated. =================
% =========================================================================
% =========================================================================
% ================= The rest of this script is automated. =================
% =========================================================================
% =========================================================================
% ================= The rest of this script is automated. =================
% =========================================================================
% =========================================================================
% ================= The rest of this script is automated. =================
% =========================================================================
% =========================================================================
% ================= The rest of this script is automated. =================
% =========================================================================
% =========================================================================
% ================= The rest of this script is automated. =================
% =========================================================================
% =========================================================================
% ================= The rest of this script is automated. =================
% =========================================================================
% =========================================================================
% [BEGIN] CONVERT RAW RT-300S MEASUREMENT DATA TO BSDF FILE IN FRED FORMAT:

% Check if FRED file already exists:
if exist(filepath_fred, 'file')
    if OVERWRITE
        warning('FRED file already exists. It will be overwritten.')
    else
        error("FRED file already exists. Change target filename or set 'OVERWRITE' to true.")
    end
end

% Check user input logic:
if ISOTROPIC
    if or(ANISO_W_XZ_SYMM, ANISO_W_YZ_SYMM)
        warning("Setting 'ANISO_W_XZ_SYMM' and 'ANISO_W_YZ_SYMM' to false because 'ISOTROPIC' is true.")
        ANISO_W_XZ_SYMM = false;
        ANISO_W_YZ_SYMM = false;
    end
end

% Load RT-300S raw data and process into FRED coordinates:
[A, I, R, S, BRDF] = process_rt300s(blankpath_rt300s, filepaths_rt300s, S);
[Pi, Ai, Ps, As] = rt300s_frame_to_fred(A, I, R, S);

% If the sample is anisotropic, but exhibits plane symmetry about the XZ 
% and/or YZ planes as defined by FRED coordinates when the sample is 
% oriented at S = 0, then can apply the following to get a full azimuthal
% dataset for FRED from limited RT-300S stage rotations:

% Apply YZ symmetry first so later XZ symmetry may drive S \in [0, 90]
% measurements to full S \in [0, 360) FRED equivalent:
if ANISO_W_YZ_SYMM
    [Pi, Ai, Ps, As, BRDF] = apply_yz_symm_to_fred(Pi, Ai, Ps, As, BRDF);
end

% Apply XZ symmetry:
if ANISO_W_XZ_SYMM
    [Pi, Ai, Ps, As, BRDF] = apply_xz_symm_to_fred(Pi, Ai, Ps, As, BRDF);
end

% Remove FRED redundancy (at Ps=0 only need one As angle, and average-out 
% any duplicated angles):
[Pi, Ai, Ps, As, BRDF] = remove_fred_redundancy(Pi, Ai, Ps, As, BRDF);

% Remove FRED redundancy for isotropic data (only need one Ai angle, and 
% only need $As - Ai \in [0, 180]$ defined):
if ISOTROPIC
    [Pi, Ai, Ps, As, BRDF] = remove_fred_redundancy_iso(Pi, Ai, Ps, As, BRDF);
end

% Write to FRED file:
write_fred(Pi, Ai, Ps, As, BRDF, filepath_fred);

% [END] CONVERT RAW RT-300S MEASUREMENT DATA TO BSDF FILE IN FRED FORMAT.
% =========================================================================
% =========================================================================

