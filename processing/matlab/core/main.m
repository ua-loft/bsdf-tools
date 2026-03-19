
clc, clearvars, close all

% Filepaths of RT-300S data (include '.xls' file extension):
blankpath_rt300s = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\blank_v2o0_20250911.xls';
filepaths_rt300s = {'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation0_20250922.xls', ...
    'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation10_20250922.xls', ...
    'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation20_20250922.xls', ...
    'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation30_20250922.xls', ...
    'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation40_20250922.xls', ...
    'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation50_20250922.xls', ...
    'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation60_20250922.xls', ...
    'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation70_20250922.xls', ...
    'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation80_20250922.xls', ...
    'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\rt-300s\IMX455_stageRotation90_20250922.xls'};

S = 0 : 10: 90; % stage rotation [deg]; if isotropic set to integer 0, otherwise define as vector corresponding to 'filenames'

ISOTROPIC = false;
ANISO_W_XZ_SYMM = true;
ANISO_W_YZ_SYMM = true;

% Filepath of output FRED file (include '.txt' file extension):
filepath_fred = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\fred\imx455_test.txt';
OVERWRITE = false; % if true and FRED file already exists, will overwrite







% end user input
% =======

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
[Pi, Ai, Ps, As] = rt300s_to_fred(A, I, R, S);

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

