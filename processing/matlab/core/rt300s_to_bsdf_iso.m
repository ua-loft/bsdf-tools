% =========================================================================
% =========================================================================
% 
% rt300s_to_bsdf_iso.m
% 
% Description:
%   - Process raw data from J&C's RT-300S scatterometer, into format for
%     Zemax's BSDF file. Assumes isoptropic and monochromatic.
% 
% Assumptions:
%   1) Data files are in default Excel format as output by BRDF machine.
%       1a) [A; I; R] are in degrees.
%       1b) [A; I; R] cycles through steps like Boolean 000, 001, 010, etc.
%   2) Sample is isotropic; therefore, [A,R] and [-A,-R] measurements may 
%      be treated an unique measurements and no sample rotations exist.
%   3) Light source is monochromatic (or only data from first wavelength 
%      gets read).
%   4) Blank data has identical [A; I; R] values in same order as sample.
%   5) Multiple datasets are averaged, and all share the same light-source
%      alignment, meaning all data is shifted by same amount to compensate
%      for systematic error.
%   6) Isotropic redundancy is removed by assuming FRED only needs entries 
%      for: \phi_i=0 for all, \phi_s=0 at \theta_s=0, \phi_s \in [0,180].
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
% | 2025.10.01 | JPK  | Copied from 'BSDF_raw_to_processed_v4o3';         |
% | 2025.10.04 | JPK  | Methods added to average multiple datasets and    |
% |            |      | automate BSDF file generation/comments/etc.; also |
% |            |      | finalized plots and cleaned code to be more user- |
% |            |      | and developer-friendly; added TIS calculation and |
% |            |      | verified against BrownVinyl                       |
% | 2026.01.24 | JPK  | Initialized support for FRED format; not yet      |
% |            |      | validated and code is messy;                      |
% | 2026.02.03 | JPK  | Revised FRED format to remove redundancy of       |
% |            |      | isotropic data manually hardcoded to full         |
% |            |      | anisotropic angles (see Assumption 6);            |
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

OUTPUT_TO_FRED = true; % output to FRED txt format
OUTPUT_TO_ZEMAX = false; % output to Zemax BSDF file format

if OUTPUT_TO_FRED
    OUTPUT_FULL_AZIMUTH = true; % define \psi_s \in [0,360), else [0,180]
end

% Filenames of measurements, where first element is the blank data used
% to zero the sample measurements:
    % - include '.xls' extension;
% filenames = ["blank_v2o0_20250911.xls"; ... % blank
%              "NiTE_on_invar_v1o0A_20250915.xls"; ... % measured dataset 1
%              "NiTE_on_invar_v1o0B_20250916.xls"; ... % ...
%              "NiTE_on_invar_v1o0C_20250916.xls"]; % measured dataset M
% filenames = ["blank_v2o0_20250911.xls"; ... % blank
%              "NiTE_on_steel_v1o0A_20250915.xls"; ... % measured dataset 1
%              "NiTE_on_steel_v1o0B_20250916.xls"; ... % ...
%              "NiTE_on_steel_v1o0C_20250916.xls"]; % measured dataset M
% filenames = ["blank_v2o0_20250911.xls"; ... % blank
%              "ANOPLATE_AnoBlack_EC1_Alum6061_v1o0_20251115.xls"]; ... % measured dataset 1
filenames = ["blank_v2o0_20250911.xls"; ... % blank
             "ANOPLATE_AnoBlack_EC2_Alum6061_v1o0_20251115.xls"]; ... % measured dataset 1

% Legend entries for plots of each dataset:
% legend_names_for_datasets = ["v1.0A", "v1.0B", "v1.0C", ...
%         "-v1.0A", "-v1.0B", "-v1.0C"]; % negative is for mirrored A=[0,90]
legend_names_for_datasets = ["v1.0", "-v1.0"]; % negative is for mirrored A=[0,90]

% Information for BSDF file:

% name_sample = "Anoplate AnoBlack NiTE w/ Blast on INVAR 36"; 
%     % name of sample measured
% name_sample = "Anoplate AnoBlack NiTE w/ Blast on Steel 1008 (So #: 1117496)"; 
%     % name of sample measured
% name_sample = "Anoplate AnoBlack EC1 on Alum 6061 (So #: 1114817)";
name_sample = "Anoplate AnoBlack EC2 on Alum 6061 (So #: 1114818)";
    % name of sample measured

name_source = "red laser (650 nm, 3.5mm spot diam.)"; 
    % name of light source used
name_angles = "(10:20:70, -90:10:90, -80:10:80)"; % in (I,A,R) order
% name_dates = ["2025/09/15", "2025/09/16"]; % date(s) measurements were made
name_dates = ["2025/11/15"]; % date(s) measurements were made
name_contact = "Jacob P. Krell (jacobpkrell@arizona.edu)"; % name of person
    % to contact, most likely you or whoever made the measurement; consider
    % including email or phone number in parentheses too

% name_file = "AnoBlackNiTEonINVAR"; % name of new BSDF file to output 
%     % results to (do not include '.bsdf' or 'txt' extension)
% name_file = "AnoBlackNiTEonSteel"; % name of new BSDF file to output 
%     % results to (do not include '.bsdf' or 'txt' extension)
% name_file = "AnoBlackEC1onAlum"; % name of new BSDF file to output 
%     % results to (do not include '.bsdf' or 'txt' extension)
name_file = "AnoBlackEC2onAlum"; % name of new BSDF file to output 
    % results to (do not include '.bsdf' or 'txt' extension)

if OUTPUT_TO_ZEMAX
    name_bsdf_file = name_file + '.bsdf';
end
if OUTPUT_TO_FRED
    if OUTPUT_FULL_AZIMUTH
        name_txt_file = name_file + '_fullAz.txt';
    else
        name_txt_file = name_file + '.txt';
    end
end
repo_version = "v1.1.0";

% Logicals for returning plots:
RETURNPLOT_RT_PlaneSymmetrical = false;
if OUTPUT_TO_ZEMAX
    RETURNPLOT_RT_AzRz = false;
    RETURNPLOT_RT_iso_AzRz = true;
    RETURNPLOT_BRDF_AzRz = true;
end

if OUTPUT_TO_ZEMAX
    % Logical for attempting to correct light source misalignment:
        % - note, fails to apply to when averaging A=[-90,0] and A=[0,90] of 
        %   same dataset, because would need to convert new (Az,Rz) to a new
        %   (A,R), which no longer would be common between datasets, and
        %   therefore would need to interpolate RT on those uncommon (A,R)
        %   values to a common grid prior to averaging;
    APPLY_SHIFT_CORRECTION = true;
end

% Machine dimensions:
beamdiam = 3.5; % [mm], spot diameter of light source (used to determine
    % the solid angle of the specular beam)
armlength = 82; % [mm], length of RT-300S's detector arm, i.e., the radius
    % from the sample placed at the machine's origin to the detector

if OUTPUT_TO_ZEMAX

    % FOR VALIDATION TESTING OF BRDF MEASUREMENT AGAINST MAGICBLACK:
        % - overrides above inputs
        % - only can validate values on Az=[0,90], since known 
        %   'MagicBlack_VIS.bsdf' only provides Az=[0,90],[270,360)
    VALIDATE_BRDF_VIA_MAGICBLACK = false;
    
    % FOR VALIDATION TESTING OF TIS CALCULATION AGAINST BROWNVINYL:
        % - overrides 'VALIDATE_BRDF_VIA_MAGICBLACK'
        % - uses BRDF values from known 'BrownVinyl.bsdf'
        % - divides TIS by two, so quarter-sphere; this matches BrownVinyl but
        %   otherwise TIS is defined here as twice that value for the full
        %   hemisphere;
    VALIDATE_TIS_VIA_BROWNVINYL = false;

end

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
% [BEGIN] ADJUST INPUTS IF USER REQUESTED VALIDATION TESTING:

if OUTPUT_TO_ZEMAX

    if VALIDATE_BRDF_VIA_MAGICBLACK % FOR VALIDATION TESTING
        filenames = ["blank_v2o0_20250911.xls"; ...
                 "MagicBlack_v2o0_20250902.xls"];
        legend_names_for_datasets = ["v1.0A", "-v1.0A"];
        name_sample = "Validation test of BRDF conversion using " + ...
            "measured RT values of Magic Black on Aluminum"; 
        name_dates = ["2025/09/02"];
        name_bsdf_file = "ValidationTest_of_BRDF_via_MagicBlack.bsdf";
    end
    
    if VALIDATE_TIS_VIA_BROWNVINYL % FOR VALIDATION TESTING
        filenames = filenames(1:2); % want M=1 to create a single cell in which
            % to later load BrownVinyl BRDF values
        name_sample = "Validation test of TIS calculation using " + ...
            "known BrownVinyl BRDF values"; 
        name_dates = ["n/a"];
        name_bsdf_file = "ValidationTest_of_TIS_via_BrownVinyl.bsdf";
    end

end

% [END] ADJUST INPUTS IF USER REQUESTED VALIDATION TESTING.
% =========================================================================
% =========================================================================
% [BEGIN] LOAD DATA:
%   - Outputs 'blank' and 'sample' arrays; 6 rows are [A; I; R; RT; RT/nm;
%     \lambda].

% Directory of this script:
dir_script = fileparts(mfilename('fullpath'));

% Directory of 'bsdf-tools' project:
dir_project = dir_script; % init
for j = 1:3 % project is three folders upstream of script
    dir_project = fileparts(dir_project); % make path go upstream
end

% Directory of raw measurements, relative to project:
dir = fullfile(dir_project, 'data', 'raw', 'rt-300s'); % combine path

% First, check bsdf filename is available:
if OUTPUT_TO_ZEMAX
    filepath_bsdf_file = fullfile(dir_project, 'data', 'processed', 'zemax', name_bsdf_file); 
        % full filepath to where bsdf file is to be saved
    FILENAME_IS_AVAILABLE = true;
    if exist(filepath_bsdf_file, 'file')
        FILENAME_IS_AVAILABLE = false;
        error('BSDF file with user-specified name already exists. Specify different filename.', name_bsdf_file);
    end
end

% Load data:
[sample, blank] = load_data(dir, filenames);

% [END] LOAD DATA.
% =========================================================================
% =========================================================================
% [BEGIN] DATA PROCESSING:

if OUTPUT_TO_ZEMAX
    if VALIDATE_BRDF_VIA_MAGICBLACK % FOR VALIDATION TESTING
        sample = fudge_data(sample);
    end
end

% Constants:
M = length(sample); % number of measurements (not including blank)

% Check if angles from sample and blank are the same:
A = blank(1, :); % RT-300S's azimuth angle
I = blank(2, :); % RT-300S's incident angle
R = blank(3, :); % RT-300S's receive angle
for m = 1:M % for sample measurement
    Am = sample{m}(1, :);
    Im = sample{m}(2, :);
    Rm = sample{m}(3, :);
    if ~all([all(A == Am), all(I == Im), all(R == Rm)]) % if any sample 
        % ... data point is at an angle not corresponding to blank
        error("Measured angles for 'blank' and 'sample' do not " + ...
              "perfectly align. Format data manually or measure again.")
    end
end
clear Am Im Rm

% More constants:
n = size(blank, 2); % n == "number of data points"
Au = unique(A); % Au == "A unique"
nA = length(Au); % nA == "number of A unique"
Iu = unique(I); % Iu == "I unique"
nI = length(Iu); % nI == "number of I unique"
Ru = unique(R); % Ru == "R unique"
nR = length(Ru); % nR == "number of R unique"

% Convert measurement angles to scatter-cone coordinates:
if OUTPUT_TO_ZEMAX
    [Az, Rz] = IAR_to_AzRz(I, A, R); % [deg]
    AzRz_as_x = -Rz .* sind(Az); % for making polar plot in Cartesian space
    AzRz_as_y = Rz .* cosd(Az); % for making polar plot in Cartesian space
end

% Corrections to RT measurements:

RT = cell(M, 1);
fig_RT_AR = cell(M, 1);
mObscured = cell(M, 1);
fig_RT_AR_PlaneSymmetrical{m} = cell(M, 1);
if OUTPUT_TO_ZEMAX
    fig_RT_AzRz = cell(M, 1);
    specular_error = zeros(M, nI); % offset of max RT from incident plane
end
for m = 1:M

    % First correction (zeroing system by subtracting blank measurement):
        % - from [1] and [2]
    RT{m} = sample{m}(4, :) - blank(4, :);

    % Second correction (setting new floor to zero):
        % - if following [1] and [2], then:
    RT{m} = RT{m} - min(RT{m}); % shift all values so min=0
        % - or, if opting instead to not touch positive RT values:
    % RT{m}(RT{m} < 0) = 0; % set only negative values to 0

    % Check visual of RT vs. (A, R), and index (nearly) obscured angles:
    [fig_RT_AR{m}, mObscured{m}] = ...
        plot_RT(nI, Iu, I, A, R, RT{m});

    % NOTE, in future development, decouple 'mObscured' from figure.

    % Third correction (remove obscured measurements):
        % - from [1] and [2], but expanded for outside incident plane too
    for i = 1:nI
        RT{m}(mObscured{m}{i}) = nan;
    end

    % Check visual of RT vs. (A, R), but with A>0 transformed to A=[-90,0]:
    if RETURNPLOT_RT_PlaneSymmetrical
            fig_RT_AR_PlaneSymmetrical{m} = ... 
                plot_RT_PlaneSymmetrical(nI, Iu, I, A, R, RT{m});
    end

    if OUTPUT_TO_ZEMAX

        % Check visual of polar heatmap, i.e., RT vs. (Az, Rz):
        if RETURNPLOT_RT_AzRz
            fig_RT_AzRz{m} = ...
                plot_RT_AzRz(nI, Iu, I, AzRz_as_x, AzRz_as_y, RT{m});
        end
        
        % Fourth correction (shift max RT to incident plane to compensate
        % for systematic error):
            % - introduced by JPK
        for i = 1:nI
            mI = I == Iu(i);
            [~, id_of_maxRT] = max(RT{m}(mI));
            AzRz_as_x_mI = AzRz_as_x(mI);
            specular_error(m, i) = AzRz_as_x_mI(id_of_maxRT); % offset from 
                % incident plane
        end

    end

end
clear blank

if OUTPUT_TO_ZEMAX

    % Fourth correction (cont.):
    specular_error = mean(specular_error(:)); % average across datasets and 
        % incident angles
    if APPLY_SHIFT_CORRECTION
        AzRz_as_x = AzRz_as_x - specular_error; % shift specular to origin
            % slong sagittal plane (i..e, Az=(90,270) axis) which on RT-300S is 
            % controlled by the micrometer, hence how this corrects systematic
            % error, assuming all datasets had same light source alignment
        Az = atan2d(-AzRz_as_x, AzRz_as_y); % solve for new Az given new x
        Rz = sqrt(AzRz_as_x.^2 + AzRz_as_y.^2); % solve for new Rz given new x
            % == AzRz_as_y ./ cosd(Az_new) == -AzRz_as_x ./ sind(Az_new)
        [Az, Rz] = ensure_AzRz_domain(Az*pi/180, Rz*pi/180); % [rad]
        Az = Az * 180/pi; % [deg]
        Rz = Rz * 180/pi; % [deg]
    end
    
    % Check visual of shifted polar heatmap, i.e., RT vs. (Az, Rz), again but
    % this time after the shift:
    if and(APPLY_SHIFT_CORRECTION, RETURNPLOT_RT_AzRz)
        fig_RT_AzRz_shifted = cell(M, 1);
        for m = 1:M
            fig_RT_AzRz_shifted{m} = ...
                plot_RT_AzRz(nI, Iu, I, AzRz_as_x, AzRz_as_y, RT{m});
        end
    end

end

% % Average RT measurements and get standard deviation:
% RT_arr = zeros(M, n);
% for m = 1:M
%     RT_arr(m, :) = RT{m};
% end
% [RT_std, RT_avg] = std(RT_arr);

% Setup treating A>0 as unique dataset:
    % - assumes measurements are symmetric, i.e., both A and R symmetric 
    %   about their 0;
mA = A <= 0; % using A=[-90,0] as range to put A>0 on
n_iso = sum(mA); % number of data points with A <= 0
I_iso = I(mA);
A_iso = A(mA); % note (A,R) are original values
R_iso = R(mA);
if OUTPUT_TO_ZEMAX
    Az_iso = Az(mA); % note (Az,Rz) are shifted, if APPLY_SHIFT_CORRECTION=1
    Rz_iso = Rz(mA);
    AzRz_as_x_iso = AzRz_as_x(mA); % shifted if APPLY_SHIFT_CORRECTION=1
    AzRz_as_y_iso = AzRz_as_y(mA);
    mFlip = Az_iso > 180; % R>0 in A=[-90,0] corresponds with quadrant III
        % where Az is roughly [180,270], and R<0 corresponds with quadrant I
        % where Az is roughly [0,90]; so, flipping [180,270] about incident 
        % plane which is valid because isometric assumption
    Az_iso(mFlip) = 360 - Az_iso(mFlip);
    AzRz_as_x_iso(mFlip) = -AzRz_as_x_iso(mFlip);
end

% Again, average but with A>0 as unique dataset:
    % - in v1.0, [A,R] were not updated to correspond with the shift, but
    %   this should be added so that 'RT_iso' is correctly stacking
    %   corresponding measurements; right now, in v1.0, the shift does not
    %   impact how they are stacked and therefore 'RT_iso_avg' fails to 
    %   account for the shift; for future development, note that the 
    %   shifted [A,R] may be obtained via '[A,R]=IAzRz_to_AR(I,Az,Rz)'
    %   where [Az,Rz] are obtained after the shift; then, however, these
    %   no-longer-discrete [A,R] coordinates must be used to interpolate
    %   RT values to a common discrete grid such that coordinates from
    %   the A=[-90,0] and A=[0,90] ranges may correspond;
RT_iso = zeros(2*M, n_iso); % isometric, so two unique measurements from 
    % +/- A
for m = 1:M % first M rows are from A=[-90,0] measurements
    RT_iso(m, :) = RT{m}(mA);
end
Au_pos = Au(Au >= 0); % Au positive
nA_pos = length(Au_pos); % number of Au positive
for i = 1:nI
    mI = I == Iu(i);
    mI_iso = I_iso == Iu(i);
    for j = 1:nA_pos
        mA = A == Au_pos(j);
        mA_iso = A_iso == -Au_pos(j); % flip sign because isometric range 
            % defined on other half
        mIA = and(mI, mA); % data points at I and A
        mIA_iso = and(mI_iso, mA_iso);
        for m = (M + 1) : (2*M) % second M rows are from A=[0,90]
            RT_iso(m, mIA_iso) = flip(RT{m - M}(mIA)); % flip order at 
                % constant (I,A) is equivalent to applying negative sign 
                % to R, sorting low to high, then sorting RT in same order
        end
    end
end
[RT_iso_std, RT_iso_avg] = std(RT_iso);

% Output to FRED if requested (without fourth correction, since that
% requires polar (Az,Rz) coordinates):
if OUTPUT_TO_FRED
    BRDF_in_RT300S_frame = RT_iso_avg ./ (pi * cosd(R_iso)); % equation 4.6 of [2]
    save_as_fred(I_iso, A_iso, R_iso, BRDF_in_RT300S_frame, ...
        name_txt_file, OUTPUT_FULL_AZIMUTH);
end

% =========================================================================
% [BEGIN] CODE ONLY FOR ZEMAX BSDF FILE:
    % - All subsequent code (aside from functions at end of script) are for
    %   exporting to Zemax BSDF file only. Run only if BSDF file requested.
if OUTPUT_TO_ZEMAX

% Check visual of polar heatmap, i.e., RT vs. (Az, Rz), with all overlayed 
% measurements, to confirm flipping (A,R) to -(A,R) worked correctly:
if RETURNPLOT_RT_iso_AzRz
    fig_RT_iso_AzRz = ...
        plot_RT_iso_AzRz(nI, Iu, I_iso, AzRz_as_x_iso, AzRz_as_y_iso, ...
                         RT_iso, legend_names_for_datasets);
end

% Interpolate RT values to desired Zemax output (Az,Rz) grid, with 0 for
    % out-of-range values:
Azq = 0 : 10 : 180; % Az query points
Rzq = [0 : 5 : 20, 30 : 10 : 80, 90]; % adding 90 to be 0 floor, note
    % BrownVinyl does this with 80; note 90 really will have some RT value,
    % but need to ensure Zemax's interpolation does not give value to >90
nAzq = length(Azq);
nRzq = length(Rzq);
[Rzq_grid, Azq_grid] = meshgrid(Rzq, Azq);
RT_eval = cell(nI, 1); % interpolated RT values evaluated on (Az,Rz) grid
Az_iso_mirror = quads_I_II_to_nIV_III(Az_iso); % need to copy/mirror 
    % Az=[0,180] to other side so can interpolate near Az=0 and Az=180; 
    % specifically, copying Az=[0,90) to Az=(-90,0] and Az=(90,180] to 
    % Az=[180,270); that is, quadrants [I, II] mirrored to produce 
    % [-IV, I, II, III];
Az_data = [Az_iso, Az_iso_mirror]; % scatter data mirrored to full azimuth
Rz_data = [Rz_iso, Rz_iso]; % scatter data mirrored to full azimuth
Az0 = -90 : 10 : 270; % copy RT value of specular ray at (Az,Rz)=(0,0) 
    % to (Az,Rz)=(Az0,0) for interpolation, so data is not only at Az=0
nAz0 = length(Az0);
Az_data = [Az_data, Az0]; % include also the specular ray data
Rz_data = [Rz_data, zeros(1, nAz0)]; % include also the specular ray data
for i = 1:nI
    mI = I_iso == Iu(i);
    RT_data = [RT_iso_avg, RT_iso_avg, ...
        repelem(max(RT_iso_avg(mI)), 1, nAz0)]; % note RT values are 
        % duplicated because of 'Az_mirror', and note 'repelem' is to copy 
        % the specular ray's RT value to the additional Rz=0 entries
    % Find where RT is nan, and remove those entries because they cause bug
    % in interpolation (they cause evaluated values to be 0 or nan):
    mKeep = and([mI, mI, true(1, nAz0)], ...
        ~isnan(RT_data)); % mask to not remove, i.e., keep all elements at 
        % incident angle I and with unobscured RT values; note need to call
        % mI twice because of how quadrants are duplicated, and Rz=0
        % entries requires true(1, nAz0)
    Az_for_interp = Az_data(mKeep); % remove obscured entries
    Rz_for_interp = Rz_data(mKeep); % remove obscured entries
    RT_for_interp = RT_data(mKeep); % remove obscured entries
    % Define interpolation function:
    RT_interp = scatteredInterpolant(Az_for_interp', Rz_for_interp', ...
        RT_for_interp', 'natural', 'none');
    % Evaluate to target (Az,Rz) query grid:
    RT_eval{i} = RT_interp(Azq_grid(:), Rzq_grid(:));
    RT_eval{i}(isnan(RT_eval{i})) = 0; % handle exception of interpolation
        % function returning nan
    RT_eval{i} = reshape(RT_eval{i}, nAzq, nRzq); % format interpolated 
        % RT values into grid corresponding with (Az,Rz)
end

% % Plot results of RT interpolated to query (Az,Rz) grid:
% [fig, ~, ~] = plot_RT_AzRzHeatmap(nI, Iu, nan, ...
%         Az_out_grid(:), Rz_out_grid(:), RT_eval, 3, ...
%         "Interpolated RT values on Zemax's $(A_Z, R_Z)$ grid");
% come back to function

% Set values at and beyond receive angle |R|>=90 equal to zero, as these
% would be transmission through the sample:
for i = 1:nI
    Ii = Iu(i); % incident angle
    mAz_gt90 = Azq_grid > 90; % since max(Rzq)<=90, then Az>=90 must be 
        % true in order for |R|>=90
    Rz1 = (90 - Ii) ./ cosd(180 - Azq_grid); % upper limit of Rz at (I,Az)
    mRz_gtRz1 = Rzq_grid >= Rz1; % these angles produce |R|>=90
    mTranmission = and(mAz_gt90, mRz_gtRz1);
    RT_eval{i}(mTranmission) = 0; % set angles of transmission equal to 0
end

% % Plot correction (i.e., RT=0 where angle is transmission):
% [fig, ~, ~] = plot_RT_AzRzHeatmap(nI, Iu, nan, ...
%         Az_out_grid(:), Rz_out_grid(:), RT_eval, 3, ...
%         "Interpolated RT values on Zemax's $(A_Z, R_Z)$ grid" + ...
%         ", with RT=0 where transmission");
% come back to function, which is same as one above

% Convert query (Az,Rz) grid to receive angle R and convert RT to BRDF:
Aq_grid = cell(nI, 1);
Rq_grid = cell(nI, 1);
BRDF = cell(nI, 1);
for i = 1:nI
    Ii = Iu(i);
    [Aq_grid{i}, Rq_grid{i}] = IAzRz_to_AR( ...
        repelem(Ii, nAzq * nRzq, 1), Azq_grid(:), Rzq_grid(:));
    Aq_grid{i} = reshape(Aq_grid{i}, nAzq, nRzq);
    Rq_grid{i} = reshape(Rq_grid{i}, nAzq, nRzq);
    BRDF{i} = RT_eval{i} ./ (pi * cosd(Rq_grid{i})); % equation 4.6 of [2]
    % Confirm values are zero if |R|>=90, or practically use lower
    % threshold, e.g., |R|>80; note BrownVinyl uses |R|>=80; if |R|>80:
        % - note 80 is also good cutoff because cosine-->0 means BRDF
        %   value explodes... practically, ~80 is this cutoff
    BRDF{i}(abs(Rq_grid{i}) > 80) = 0;
end

% Check visual of polar heatmap, i.e., BRDF vs. (Az, Rz):
if RETURNPLOT_BRDF_AzRz
    fig_BRDF_AzRz = ...
        plot_BRDF_AzRz(nI, Iu, Azq_grid, Rzq_grid, BRDF);
end

% =========================================================================
% Calculate TIS:
    % - https://www.synopsys.com/glossary/...
    %   what-is-total-integrated-scattering.html
% TIS = 2*pi * integral(BRDF(R) * abs(sind(R)) * cosd(R) * dR); % from max

% Development of TIS integral:
% - https://www.synopsys.com/glossary/...
%   what-is-total-integrated-scattering.html
% - dR is vertical (meridional) span of differential spherical surface
%   area;
% - sin(R)*dA is horizontal width of azimuth of differential spherical 
%   surface area;
% - So, solid angle is sin(R)*dR*dA
% - Need to integrate BRDF values along entire spherical surface area, 
%   making difference between scatter and specular;
% - The azimuth A of RT-300S changes, but for isotropic sample this may
%   be considered constant and rather it is the azimuth of the scatter
%   cone that is changing; For anisotropic, consider later in future 
%   development;
% - Now,
%   - integral of BRDF over sphere is hemisphere here because BRDF=0 for
%     R > 90, meaning only upper portion of sphere matters;
%   - \int_{0}^{2\pi} \int_{0}^{\pi/2} BRDF(R,A) \sin(R) dR dA
%     - may need to redefine variables, e.g., to (Rz,Az); not sure if (R,A)
%       provides what is meant by TIS integral;
% - About coordinates,
%   - for a given light source angle (incidence and azimuth), integrate 
%     the hemisphere;
%     - however, RT-300S changes azimuth of the light source while keeping
%       the azimuth of the detector plane constant; so, need to consider
%       azimuth A as global reference while integrating; maybe can do this
%       in reference to (Az,Rz);
%       - yes, if in reference to (Az,Rz), then the hemisphere is:
%         \int_{A_Z=0}^{2\pi} \int_{R_Z=0}^{pi}
%         but where reflection (i.e., defined BRDF values) are only on:
%         -(\pi/2 - I) <= R_Z \cos(A_Z) <= \pi/2 + I
%         at these angles, we are on the sample surface or above.
%         --> BRDF=0 at: I - \pi/2 > R_Z \cos(A_Z) > \pi/2 + I
% - Therefore, the integral is:
%   TIS = \int_{Az=0}^{2\pi} \int_{Rz=0}^{\pi} BRDF(Rz,Az) \sin(Rz) dRz dAz

% Assuming BRDF=0 for (Az,Rz) values not in (Azq,Rzq), so integrating
% numerically over 'j' and 'k' indices:

% If validation testing:
if VALIDATE_TIS_VIA_BROWNVINYL
    BRDF = hardcode_BrownVinyl_BRDF(BRDF);
    name_source = "n/a"; 
    name_angles = "n/a";
    filenames = ["n/a"; "n/a"];
    Iu(1) = 15; % BrownVinyl does not have I=10 measurement
end

% Calculate TIS:

dRz_specular = asin( (beamdiam/2) / armlength); % [rad], approximate dRz 
    % of specular beam

TIS = zeros(nI, 1);
for i = 1:nI

    % Calculate integral of total BRDF:
    TIS_total = 0; % initialize
    for j = 1 : (nAzq - 1) % minus one because forward integration
        for k = 1 : (nRzq - 1) % minus one because forward integration
            TIS_total = TIS_total ...
                + (BRDF{i}(j,k) + BRDF{i}(j,k+1) ...
                   + BRDF{i}(j+1,k) + BRDF{i}(j+1,k+1)) / 4 ... 
                   ... % times average BRDF(Az,Rz) over differential area
                * (sind(Rzq(k)) + sind(Rzq(k+1))) / 2 ...
                   ... % times average sin(Rz) over differential area
                * (Rzq(k+1) - Rzq(k))*pi/180 ...
                   ... % times dRz [rad] of differential area
                * (Azq(j+1) - Azq(j))*pi/180;
                       % times dAz [rad] of differential area
        end
    end

    % Calculate integral of BRDF in approximate region of specular beam:
        % - For light source spot diameter of phi, and detector-arm length
        %   L (i.e., distance from detector to R-300S origin), the receive
        %   and radial angles corresponding to the beam diameter are, via
        %   trigonometry:
        %   --> R2 - R1 = Rz2 - Rz1 = 2 * asin( (phi/2) / L )
        % - Therefore, sum of specular BRDF is:
    % TIS_specular = BRDF{i}(1, 1) ... % times BRDF of specular ray
    %         * (sin(0) + sin(dRz_specular)) / 2 ...
    %            ... % times average of sin(Rz) over specular beam
    %         * dRz_specular ... % times dRz [rad] of specular beam
    %         * pi; % times dAz [rad] of specular beam
        % Note the pi is from the integral over half of Az, the 
        % asin(beamdiam/2/armlength) is from radial spread of specular
        % beam, and BRDF{i}(1,1) is the value for the specular ray; note
        % any azimuth value BRDF{i}(:,1) can be used, since what is needed 
        % is just Rz=0.

    % But, noting how BRDF, dRz, and pi are constants across the Rz width,
    % can take symbolic integral of sin and plug in Rz limits:
    TIS_specular = BRDF{i}(1, 1) ...
            * (-cos(dRz_specular) + cos(0)) ...
            * dRz_specular ...
            * pi;

    % Subtract specular from total to get just scatter (which is TIS):
    TIS(i) = 2 * (TIS_total - TIS_specular); % x2 because Az = [0, 180], 
        % but need [0, 360]

    if VALIDATE_TIS_VIA_BROWNVINYL
        % Adjust to Zemax format:
            % - not sure why but BrownVinyl appears to only integrate on 
            %   limits Az=[0,180] so provide TIS/2 instead;
        TIS(i) = TIS(i) / 2;
    end

end

% [END] DATA PROCESSING.
% =========================================================================
% =========================================================================
% [BEGIN] WRITE TO ZEMAX BSDF FILE:
    % - mostly following BrownVinyl as template;

% =========================================================================
% Setup:

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
    % e.g.: 
    % "# Angles measured: (I,A,R) = (10:20:70, -90:10:90, -80:10:80)\n"
line_blankdataset = ...
    "# Blank dataset: '" + filenames(1) + "'\n";
    % e.g.: "# Blank dataset: 'blank_measurement.xls'\n"

line_datasets = "# Dataset(s): "; % initialize
for m = 1:M
    if m > 1 % if not first dataset
        line_datasets = line_datasets + ", "; % add comma between datasets
    end
    line_datasets = line_datasets + "'" + filenames(m + 1) + "'";
    % note first element in 'filenames' is blank, so add 1 to m
end
line_datasets = line_datasets + "\n"; % finalize
    % e.g.: "# Dataset(s): 'sample_measurement_1.xls', ...
    % 'sample_measurement_2.xls', 'sample_measurement_3.xls'\n"

line_dates = "# Date(s) measured: "; % initialize
for date_id = 1 : length(name_dates)
    if date_id > 1 % if not first date
        line_dates = line_dates + ", "; % add comma between dates
    end
    line_dates = line_dates + name_dates(date_id);
end
line_dates = line_dates + "\n"; % finalize
    % e.g.: "# Date(s) measured: 2025/09/15, 2025/09/16\n"

line_Iu = "%i"; % initialize
if nI > 1
    for i = 2:nI
        line_Iu = line_Iu + "	%i"; % note space between %i needs to be 
            % tab else Zemax fails to read BSDF file, and cannot have tab 
            % after last element
    end
end
line_Iu = line_Iu + "\n"; % finalize

line_Az = "%i"; % initialize
if nAzq > 1
    for j = 2:nAzq
        line_Az = line_Az + "	%i"; % note space between %i needs to be 
            % tab else Zemax fails to read BSDF file, and cannot have tab 
            % after last element
    end
end
line_Az = line_Az + "\n"; % finalize

line_Rz = "%i"; % initialize
if nRzq > 1
    for k = 2:nRzq
        line_Rz = line_Rz + "	%i"; % note space between %i needs to be 
            % tab else Zemax fails to read BSDF file, and cannot have tab 
            % after last element
    end
end
line_Rz = line_Rz + "\n"; % finalize

line_BRDF = "%1.3e"; % initialize
if nRzq > 1
    for k = 2:nRzq % Rz here because BRDF row is constant (I,Az) across Rz
        line_BRDF = line_BRDF + "	%1.3e"; % note space between %1.3e 
            % needs to be tab else Zemax fails to read BSDF file, and
            % cannot have tab after last element
    end
end
line_BRDF = line_BRDF + "\n"; % finalize

% =========================================================================
% Write to file:

% Open file:
if FILENAME_IS_AVAILABLE
    fid = fopen(filepath_bsdf_file, 'wt');
end

% Write:

fprintf(fid, line_break);
fprintf(fid, line_break);
fprintf(fid, "# [BEGIN] DEVELOPMENT INFORMATION:\n");
fprintf(fid, "# \n");
fprintf(fid, line_sample);
fprintf(fid, "# Scatterometer: Wyant College's J&C RT-300S\n");
fprintf(fid, line_source);
fprintf(fid, line_angles);
fprintf(fid, sprintf("# Number of measurements averaged: %i\n", 2*M));
    % 2*M for isotropic, but would be M for anisotropic
fprintf(fid, line_blankdataset);
fprintf(fid, line_datasets);
fprintf(fid, "# Processing script: '" + mfilename() + ".m'\n");
    % e.g.: "# Processing script: 'rt300s_to_bsdf_iso.m'\n"
fprintf(fid, "# Processing source: https://github.com/ua-loft/bsdf-tools/tree/" + repo_version + "\n");
fprintf(fid, line_dates);
fprintf(fid, sprintf("# Note(s): - data from (A=[-90,0],R) and " + ...
    "(A=[0,90],-R) considered unique because isotropic sample and " + ...
    "therefore PlaneSymmetrical, hence %i measurements from %i " + ...
    "datasets;\n" + ...
    "#          - TIS calculated over entire hemisphere, i.e., " + ...
    "Az=[0,360), but only from BRDF values reported here so " + ...
    "assuming BRDF=0 beyond Rz>=90;\n", 2*M, M));
    % assuming isotropic, and that datasets included A=[0,90] measurements
fprintf(fid, "# Point of contact: " + name_contact + "\n");
    % e.g.: 
    % "# Point of contact: Jacob P. Krell (jacobpkrell@arizona.edu)\n"
fprintf(fid, "# \n");
fprintf(fid, "# [END] DEVELOPMENT INFORMATION.\n");
fprintf(fid, "# ======================================================\n");
fprintf(fid, "# ======================================================\n");
fprintf(fid, "# \n");

fprintf(fid, "Source	Measured\n"); % space is tab
fprintf(fid, "Symmetry	PlaneSymmetrical\n"); % space is tab
    % assuming isotropic sample
fprintf(fid, "SpectralContent	Monochrome\n"); % space is tab
    % assuming monochromatic light source
fprintf(fid, "ScatterType	BRDF\n"); % space is tab
fprintf(fid, "SampleRotation	1\n"); % space is tab
    % assuming no sample rotations
fprintf(fid, "0\n");

fprintf(fid, "AngleOfIncidence	%i\n", nI); % space is tab
fprintf(fid, line_Iu, Iu);
fprintf(fid, "ScatterAzimuth	%i\n", nAzq); % space is tab
fprintf(fid, line_Az, Azq);
fprintf(fid, "ScatterRadial	%i\n", nRzq); % space is tab
fprintf(fid, line_Rz, Rzq);
fprintf(fid, "\n");

fprintf(fid, "Monochrome\n");
    % assuming monochromatic light source
fprintf(fid, "DataBegin\n");

for i = 1:nI
    fprintf(fid, "TIS	%.6f\n", TIS(i)); % space is tab
    for j = 1:nAzq
        fprintf(fid, line_BRDF, BRDF{i}(j, :)); % write row of BRDF values
    end
end

fprintf(fid, "DataEnd\n");

% Values have been written, so may close file:
fclose(fid);

% [END] WRITE TO ZEMAX BSDF FILE.
% =========================================================================

end

% [END] CODE ONLY FOR ZEMAX BSDF FILE.
% =========================================================================
% =========================================================================
% [BEGIN] FUNCTIONS:

function [sample, blank] = load_data(dir, filenames)
    M = length(filenames) - 1; % number of sample measurements
    sample = cell(M, 1);
    m = 0; % initialize sample index
    for j = 1 : (M + 1)
        filepath = fullfile(dir, filenames(j));
        sheets = sheetnames(filepath);
        data = zeros(6, 1);
        i0 = 1;
        for k = 1:length(sheets)
            raw = readmatrix(filepath, 'Sheet', sheets{k});
            if ~isempty(raw) % handle last sheet being empty by default
                iL = size(raw, 2) - 1; % minus 1 b/c first column empty
                i1 = i0 + iL - 1;
                data(1:3, i0:i1) = raw(7:9, 2:end);
                data(4:6, i0:i1) = raw(22:24, 2:end);
                i0 = i1 + 1;
            end
        end
        if j == 1 % then data is from 'blank' measurement
            blank = data;
        else % data is from a 'sample' measurement
            m = m + 1;
            sample{m} = data;
        end
    end
    clear data
end


function [Az, Rz] = IAR_to_AzRz(I, A, R)
    % Convert angles in machine's coordinate frame to Zemax's frame.
    %   - see JPK's 2025/09/09 notebook for derivation, and MATLAB file
    %     "debug_BSDFmachine_to_Zemax_coordinates_20250909.m";
    % Angles are in degrees.
    
    % Parse inputs:
    rad_deg = pi / 180; % radians per degree
    A = A * rad_deg; % convert degrees to radians
    I = I * rad_deg;
    R = R * rad_deg;
    cA = cos(A);
    sA = sin(A);
    cI = cos(I);
    sI = sin(I);
    cR = cos(R);
    sR = sin(R);

    % Calculate X,Y,Z (from solution of 3 eq.'s, 3 unknowns):
    X = sI.*cR + sA.*cI.*sR;
    Y = -cA.*sR;
    Z = cI.*cR - sA.*sI.*sR;
        
    % For numerical robustness, normalize:
    n = sqrt(X.^2 + Y.^2 + Z.^2); % == 1, analytically
        % == 1, from X := sRz.*cAz, Y := sRz.*sAz, Z := cRz
    X = X ./ n; Y = Y ./ n; Z = Z ./ n;
    Z = max(-1, min(1, Z)); % clamp

    % Solve:
    Az = atan2(Y, X); % atan2 form is stable near poles [rad]
    Rz = atan2(hypot(X, Y), Z); % == acos(Z), but more stable [rad]
    
    % Adjust solution to proper domain:
    [Az, Rz] = ensure_AzRz_domain(Az, Rz); % [rad]

    % Convert units:
    Az = Az / rad_deg; % [deg]
    Rz = Rz / rad_deg; % [deg]

end


function [AzN, RzN] = ensure_AzRz_domain(Az, Rz)
    % Maintaining same vector orientation, format (Az, Rz) to be on 
    % domains [0,2*pi) and [0,pi], respectively.
    % Do NOT assume plane symmetry about incident plane.
    % Angles are in radians.
    
    % Wrap Az to [0, 2*pi):
    AzN = mod(Az, 2*pi);
    
    % Bring Rz into [0, 2*pi):
    RzN = mod(Rz, 2*pi);
    
    % If Rz in (pi, 2*pi), reflect and rotate Az by pi to keep same vector:
    mask = (RzN > pi);
    RzN(mask) = 2*pi - RzN(mask);
    AzN(mask) = AzN(mask) + pi;
    
    % Wrap Az again in case pi was added:
    AzN = mod(AzN, 2*pi);

    % Snap values near endpoints to 0 and values near apex/antipode to pi:
    tol = 1e-12;
    Rz_near0 = abs(RzN) < tol;
    Rz_nearPi = abs(RzN - pi) < tol;
    Az_near0 = abs(AzN) < tol;
    Az_nearPi = abs(AzN - pi) < tol;
    Az_near2Pi = abs(AzN - 2*pi) < tol;
    RzN(Rz_near0) = 0;
    RzN(Rz_nearPi) = pi;
    AzN(Az_near0) = 0;
    AzN(Az_nearPi) = pi;
    AzN(Az_near2Pi) = 0;
    
    % Additionally, define Az = 0 if Rz = (0,pi) by convention:
    AzN(Rz_near0 | Rz_nearPi) = 0;

end


function [fig, mObscured_arr] = plot_RT(nI, Iu, I, A, R, RT)
    dA_obscured = 30; % +/- required clearance about A = +/-90
    dR_obscured = 10; % +/- required clearance about R = -I
    
    % [BEGIN] COPY/PASTE FORMATTING:
    width = 6.75; % inches, == 8.5" - 2*margin
    height = width * 1;
    fig = figure('Color', 'w');
    fig.Units = 'inches';
    fig.Position = [0, 0, width, height];
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0, 0, width, height];
    fig.PaperSize = [8.5, 11];
    tfig  = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', ...
        'Padding', 'compact'); % assuming nI = 4
    tfig.TileSpacing = 'compact';
    tfig.Padding = 'none';
    % [END] COPY/PASTE FORMATTING.

    mObscured_arr = cell(nI, 1);
    for i = 1:nI

        ax = nexttile(tfig);
        ax.Color = 'w';
        % ax.Visible = 'off';

        Ii = Iu(i);
        mI = I == Ii; % mask of I
        mA = and(A < 90 - dA_obscured, -90 + dA_obscured < A); % unobscured
        mR = or(-sign(A).*R < -Ii - dR_obscured, ...
            -Ii + dR_obscured < -sign(A).*R); % unobscured
        mAR = ~and(~mA, ~mR); % unobscured
        mUnobscured = and(mI, mAR);
        mObscured = and(mI, ~mAR);
        mObscured_arr{i} = mObscured; % save for later

        hold on
        s1 = scatter3(A(mUnobscured), R(mUnobscured), RT(mUnobscured), ...
            12, 'filled', 'MarkerFaceColor', 'b');
        s2 = scatter3(A(mObscured), R(mObscured), RT(mObscured), ...
            12, 'filled', 'MarkerFaceColor', 'r');
        hold off

        % xlabel("Azimuth, $A$ [deg]", 'Interpreter', 'latex')
        % ylabel("Receive, $R$ [deg]", 'Interpreter', 'latex')
        % zlabel("$\mathrm{RT} - \mathrm{RT}_0$", 'Interpreter', 'latex')
        % title(sprintf("Raw measurements zeroed by blank, " + ...
        %     "$I = %i^{\\circ}$", Ii), ...
        %     'Interpreter', 'latex')

        xlabel("$A$ [deg]", 'Interpreter', 'latex')
        ylabel("$R$ [deg]", 'Interpreter', 'latex')
        zlabel("RT", 'Interpreter', 'latex')
        title(sprintf("$I = %i^{\\circ}$", Ii), ...
            'Interpreter', 'latex')

        ax.XAxis.TickLabelInterpreter = 'latex';
        ax.YAxis.TickLabelInterpreter = 'latex';
        ax.ZAxis.TickLabelInterpreter = 'latex';

        grid on
        % ax.XDir = 'reverse'; % flip aximuth axis direction
        ax.View = [-65, 10]; % viewing angle for 3D
        h = get(ax, 'DataAspectRatio');
        set(ax, 'DataAspectRatio', [mean(h(1:2)), mean(h(1:2)), h(3)])

    end

    leg = legend("Unobscured", "Obscured", 'Interpreter', 'latex');
    sgtitle("All RT measurements, after zeroing", 'Interpreter', 'latex')

    % [BEGIN] COPY/PASTE FORMATTING:
    leg.Location = 'none';
    leg.AutoUpdate = 'off';
    ip = tfig.InnerPosition;
    cx = ip(1) + ip(3)/2; % center x
    cy = ip(2) + ip(4)/2; % center y
    leg_pos = leg.Position;
    leg_w = leg_pos(3);
    leg_h = leg_pos(4);
    leg.Position = [cx - leg_w/2, cy - leg_h/2, leg_w, leg_h];
        % place legend so its center is at (cx, cy)
    % [END] COPY/PASTE FORMATTING.

end


function fig = plot_RT_PlaneSymmetrical(nI, Iu, I, A, R, RT)
    
    % [BEGIN] COPY/PASTE FORMATTING:
    width = 6.75; % inches, == 8.5" - 2*margin
    height = width * 1;
    fig = figure('Color', 'w');
    fig.Units = 'inches';
    fig.Position = [0, 0, width, height];
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0, 0, width, height];
    fig.PaperSize = [8.5, 11];
    tfig  = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', ...
        'Padding', 'compact'); % assuming nI = 4
    tfig.TileSpacing = 'compact';
    tfig.Padding = 'none';
    % [END] COPY/PASTE FORMATTING.

    for i = 1:nI

        ax = nexttile(tfig);
        ax.Color = 'w';
        % ax.Visible = 'off';
        
        Ii = Iu(i);
        mI = I == Ii; % mask of I
        mA = A <= 0; % measurements to NOT transform coordinates
        mIA = and(mI, mA);
        mInA = and(mI, ~mA); % measurements to transform
        
        hold on
        s1 = scatter3(A(mIA), R(mIA), RT(mIA), ...
            12, 'filled', 'MarkerFaceColor', 'b');
        s2 = scatter3(-A(mInA), -R(mInA), RT(mInA), ... % flip A,R signs
            12, 'filled', 'MarkerFaceColor', 'r');
        hold off
        
        % xlabel("Azimuth angle, $A$ (degrees)", 'Interpreter', 'latex')
        % ylabel("Receive angle, $R$ (degrees)", 'Interpreter', 'latex')
        % zlabel("$\mathrm{RT} - \mathrm{RT}_0$", 'Interpreter', 'latex')
        % title(sprintf("Raw measurements zeroed by blank, " + ...
        %     "$I = %i^{\\circ}$", Ii), ...
        %     'Interpreter', 'latex')
        
        xlabel("$A$ [deg]", 'Interpreter', 'latex')
        ylabel("$R$ [deg]", 'Interpreter', 'latex')
        zlabel("RT", 'Interpreter', 'latex')
        title(sprintf("$I = %i^{\\circ}$", Ii), ...
            'Interpreter', 'latex')

        ax.XAxis.TickLabelInterpreter = 'latex';
        ax.YAxis.TickLabelInterpreter = 'latex';
        ax.ZAxis.TickLabelInterpreter = 'latex';
        
        grid on
        % ax.XDir = 'reverse'; % flip aximuth axis direction
        ax.View = [-65, 10]; % viewing angle for 3D
        h = get(ax, 'DataAspectRatio');
        set(ax, 'DataAspectRatio', [mean(h(1:2)), mean(h(1:2)), h(3)])

    end

    leg = legend("$(A,R)$", "$-(A,R)$", 'Interpreter', 'latex');
    sgtitle("Unobscured RT measurements, after zeroing and " + ...
        "overlaying plane symmetry", 'Interpreter', 'latex')

    % [BEGIN] COPY/PASTE FORMATTING:
    leg.Location = 'none';
    leg.AutoUpdate = 'off';
    ip = tfig.InnerPosition;
    cx = ip(1) + ip(3)/2; % center x
    cy = ip(2) + ip(4)/2; % center y
    leg_pos = leg.Position;
    leg_w = leg_pos(3);
    leg_h = leg_pos(4);
    leg.Position = [cx - leg_w/2, cy - leg_h/2, leg_w, leg_h];
        % place legend so its center is at (cx, cy)
    % [END] COPY/PASTE FORMATTING.

end


function fig = plot_RT_AzRz(nI, Iu, I, AzRz_as_x, AzRz_as_y, RT)
    % [I, AzRz_as_x, AzRz_as_y, RT] are corresponding vectors.
    
    % [BEGIN] COPY/PASTE FORMATTING:
    width = 6.75; % inches, == 8.5" - 2*margin
    height = width * 1;
    fig = figure('Color', 'w');
    fig.Units = 'inches';
    fig.Position = [0, 0, width, height];
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0, 0, width, height];
    fig.PaperSize = [8.5, 11];
    tfig  = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', ...
        'Padding', 'compact'); % assuming nI = 4
    tfig.TileSpacing = 'compact';
    tfig.Padding = 'none';
    % [END] COPY/PASTE FORMATTING.
    
    for i = 1:nI
        
        ax = nexttile(tfig);
        ax.Color = 'w';
        % ax.Visible = 'off';
        
        Ii = Iu(i);
        mI = I == Ii; % mask of I
        dRT = max(RT(mI)) - min(RT(mI));
        RT_lower = 0;
        RT_upper = max(RT(mI)) + dRT*0.1;
        
        hold on
        s1 = scatter3(AzRz_as_x(mI), AzRz_as_y(mI), RT(mI), ...
            12, 'filled', 'MarkerFaceColor', 'b');
        plot3([0, 0], [0, 0], [RT_lower, RT_upper], 'r', 'LineWidth', 2)
            % nominal specular ray
        hold off
        
        xlabel("$R_Z$ along sagittal plane", ...
            'Interpreter', 'latex')
            % "$R_Z$ along $A_Z = (90^{\circ}, 270^{\circ})$"
        ylabel("$R_Z$ along meridional (incident) plane", ...
            'Interpreter', 'latex')
            % "$R_Z$ along $A_Z = (0^{\circ}, 180^{\circ})$"
        zlabel("RT", 'Interpreter', 'latex') 
            % "$\mathrm{RT} - \mathrm{RT}_0$"
        title(sprintf("$I = %i^{\\circ}$", Ii), ...
            'Interpreter', 'latex')

        ax.XAxis.TickLabelInterpreter = 'latex';
        ax.YAxis.TickLabelInterpreter = 'latex';
        ax.ZAxis.TickLabelInterpreter = 'latex';
        
        grid on
        ax.View = [-65, 10]; % viewing angle for 3D
        h = get(ax, 'DataAspectRatio');
        set(ax, 'DataAspectRatio', [mean(h(1:2)), mean(h(1:2)), h(3)])
        
        xlim([-90, 90])
        ylim([-90, 90])
        zlim([RT_lower, RT_upper])

    end
    
    leg = legend("measured scatter", "nominal specular", ...
        'Interpreter', 'latex');
    sgtitle("Unobscured RT measurements, after zeroing and " + ...
        "converting to scatter-cone coordinates", ...
        'Interpreter', 'latex')

    % [BEGIN] COPY/PASTE FORMATTING:
    leg.Location = 'none';
    leg.AutoUpdate = 'off';
    ip = tfig.InnerPosition;
    cx = ip(1) + ip(3)/2; % center x
    cy = ip(2) + ip(4)/2; % center y
    leg_pos = leg.Position;
    leg_w = leg_pos(3);
    leg_h = leg_pos(4);
    leg.Position = [cx - leg_w/2, cy - leg_h/2, leg_w, leg_h];
        % place legend so its center is at (cx, cy)
    % [END] COPY/PASTE FORMATTING.

end


function fig = plot_RT_iso_AzRz(nI, Iu, I, AzRz_as_x, AzRz_as_y, RT, ...
    legend_str)
    % [I, AzRz_as_x, AzRz_as_y] are corresponding vectors.
    % RT is 2D array with rows being unique measurements, and columns
    % corresponding to elements of the vectors.
    
    % [BEGIN] COPY/PASTE FORMATTING:
    width = 6.75; % inches, == 8.5" - 2*margin
    height = width * 1;
    fig = figure('Color', 'w');
    fig.Units = 'inches';
    fig.Position = [0, 0, width, height];
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0, 0, width, height];
    fig.PaperSize = [8.5, 11];
    tfig  = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', ...
        'Padding', 'compact'); % assuming nI = 4
    tfig.TileSpacing = 'compact';
    tfig.Padding = 'none';
    % [END] COPY/PASTE FORMATTING.

    M = size(RT, 1); % number of unique measurements
    
    for i = 1:nI
        
        ax = nexttile(tfig);
        ax.Color = 'w';
        % ax.Visible = 'off';
        
        Ii = Iu(i);
        mI = I == Ii; % mask of I
        RT_all_mI = RT(:, mI);
        dRT = max(RT_all_mI(:)) - min(RT_all_mI(:));
        RT_lower = 0;
        RT_upper = max(RT_all_mI(:)) + dRT*0.1;
        
        hold on
        plot3([0, 0], [0, 0], [RT_lower, RT_upper], 'r', 'LineWidth', 2)
            % nominal specular ray
        for m = 1:M % for unique measurement
            scatter3(AzRz_as_x(mI), AzRz_as_y(mI), RT(m, mI), ...
                12, 'filled');
        end
        hold off
        
        xlabel("$R_Z$ along sagittal plane", ...
            'Interpreter', 'latex')
            % "$R_Z$ along $A_Z = (90^{\circ}, 270^{\circ})$"
        ylabel("$R_Z$ along meridional (incident) plane", ...
            'Interpreter', 'latex')
            % "$R_Z$ along $A_Z = (0^{\circ}, 180^{\circ})$"
        zlabel("RT", 'Interpreter', 'latex') 
            % "$\mathrm{RT} - \mathrm{RT}_0$"
        title(sprintf("$I = %i^{\\circ}$", Ii), ...
            'Interpreter', 'latex')

        ax.XAxis.TickLabelInterpreter = 'latex';
        ax.YAxis.TickLabelInterpreter = 'latex';
        ax.ZAxis.TickLabelInterpreter = 'latex';
        
        grid on
        ax.View = [65, 10]; % viewing angle for 3D
        h = get(ax, 'DataAspectRatio');
        set(ax, 'DataAspectRatio', [mean(h(1:2)), mean(h(1:2)), h(3)])
        
        xlim([-90, 90])
        ylim([-90, 90])
        zlim([RT_lower, RT_upper])

    end
    
    leg = legend(["nominal specular", legend_str], 'Interpreter', 'latex');
    sgtitle("All unobscured RT measurements, after zeroing and " + ...
        "converting to scatter-cone coordinates", ...
        'Interpreter', 'latex')

    % [BEGIN] COPY/PASTE FORMATTING:
    leg.Location = 'none';
    leg.AutoUpdate = 'off';
    ip = tfig.InnerPosition;
    cx = ip(1) + ip(3)/2; % center x
    cy = ip(2) + ip(4)/2; % center y
    leg_pos = leg.Position;
    leg_w = leg_pos(3);
    leg_h = leg_pos(4);
    leg.Position = [cx - leg_w/2, cy - leg_h/2, leg_w, leg_h];
        % place legend so its center is at (cx, cy)
    % [END] COPY/PASTE FORMATTING.

end


function Az_mirror = quads_I_II_to_nIV_III(Az)
    % Assuming Az on domain Az=[0,180] convert quadrant I (i.e., 
    % Az=[0,90)) to -IV (i.e., Az=(-90,0]) and quadrant II (i.e., 
    % Az=[90,180])to III (i.e., Az=[180,270]).
    % Units are degrees.
    Az_mirror = 360 - Az;
    mAz = Az_mirror > 270; % mask of +IV
    Az_mirror(mAz) = Az_mirror(mAz) - 360; % convert +IV to -IV
end


% function plot_RT_AzRzHeatmap()
%     ...
% end


function fig = plot_BRDF_AzRz(nI, Iu, Az, Rz, BRDF)
    % [Az, Rz, BRDF{i}] are corresponding grids. Note Az and Rz are the 
    % same for all i, where i = 1:nI. Angles are in degrees.
    
    % [BEGIN] COPY/PASTE FORMATTING:
    width = 6.75; % inches, == 8.5" - 2*margin
    height = width * 1;
    fig = figure('Color', 'w');
    fig.Units = 'inches';
    fig.Position = [0, 0, width, height];
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0, 0, width, height];
    fig.PaperSize = [8.5, 11];
    tfig  = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', ...
        'Padding', 'compact'); % assuming nI = 4
    tfig.TileSpacing = 'compact';
    tfig.Padding = 'none';
    % [END] COPY/PASTE FORMATTING.

    AzRz_as_x = -Rz .* sind(Az); % for making polar plot in Cartesian space
    AzRz_as_y = Rz .* cosd(Az); % for making polar plot in Cartesian space

    for i = 1:nI
        
        ax = nexttile(tfig);
        ax.Color = 'w';
        % ax.Visible = 'off';
        
        Ii = Iu(i);
        dBRDF = max(BRDF{i}(:)) - min(BRDF{i}(:));
        % BRDF_lower = 0;
        BRDF_lower = min(BRDF{i}(:)) - dBRDF*0.1;
        BRDF_upper = max(BRDF{i}(:)) + dBRDF*0.1;
        
        hold on
        plot3([0, 0], [0, 0], [BRDF_lower, BRDF_upper], ...
            'r', 'LineWidth', 2) % nominal specular ray
        scatter3(AzRz_as_x(:), AzRz_as_y(:), BRDF{i}(:), ...
            12, 'filled');
        hold off
        
        xlabel("$R_Z$ along sagittal plane", ...
            'Interpreter', 'latex')
            % "$R_Z$ along $A_Z = (90^{\circ}, 270^{\circ})$"
        ylabel("$R_Z$ along meridional (incident) plane", ...
            'Interpreter', 'latex')
            % "$R_Z$ along $A_Z = (0^{\circ}, 180^{\circ})$"
        zlabel("BRDF", 'Interpreter', 'latex') 
        title(sprintf("$I = %i^{\\circ}$", Ii), ...
            'Interpreter', 'latex')

        ax.XAxis.TickLabelInterpreter = 'latex';
        ax.YAxis.TickLabelInterpreter = 'latex';
        ax.ZAxis.TickLabelInterpreter = 'latex';
        
        grid on
        ax.View = [65, 10]; % viewing angle for 3D
        h = get(ax, 'DataAspectRatio');
        set(ax, 'DataAspectRatio', [mean(h(1:2)), mean(h(1:2)), h(3)])
        
        xlim([-90, 90])
        ylim([-90, 90])
        zlim([BRDF_lower, BRDF_upper])

    end
    
    leg = legend("nominal specular", "BRDF", 'Interpreter', 'latex');
    sgtitle("BRDF, after interpolating RT to scatter-cone grid", ...
        'Interpreter', 'latex')

    % [BEGIN] COPY/PASTE FORMATTING:
    leg.Location = 'none';
    leg.AutoUpdate = 'off';
    ip = tfig.InnerPosition;
    cx = ip(1) + ip(3)/2; % center x
    cy = ip(2) + ip(4)/2; % center y
    leg_pos = leg.Position;
    leg_w = leg_pos(3);
    leg_h = leg_pos(4);
    leg.Position = [cx - leg_w/2, cy - leg_h/2, leg_w, leg_h];
        % place legend so its center is at (cx, cy)
    % [END] COPY/PASTE FORMATTING.

end


function [A, R] = IAzRz_to_AR(I, Az, Rz)
    % This function converts (Az,Rz) at given I to (A,R).
    % Angles are in degrees.

    % Parse inputs:
    cI = cosd(I);
    sI = sind(I);
    cAz = cosd(Az);
    sAz = sind(Az);
    cRz = cosd(Rz);
    sRz = sind(Rz);

    % Calculate intermediate values:
    X = sRz.*cAz; 
    Y = sRz.*sAz; 
    Z = cRz;

    % Solve for (A, R):
    A = atand((sI.*Z - cI.*X) ./ Y); % \in [-90, 90]
    cA = cosd(A);
    sA = sind(A);
    R = atan2d(sA.*cI.*X - cA.*Y - sA.*sI.*Z, sI.*X + cI.*Z);
    R(isnan(R)) = 0; % assume something in equations yields NaN
        % when (by inspection) should be 0

    % Ensure (A, R) are in domain:
    [A, R] = ensure_AR_domain(A, R);

end

function [A, R] = ensure_AR_domain(A, R)
    % Preserving direction of (A,R) unit vector, outputs A \in [-90, 270)
    % and R \in [-180, 180).

    % Constants:
    tol = 1e-12;

    % Wrap:
    A = mod(A - (-90), 360) - 90; % \in [-90, 270)
    R = mod(R - (-180), 360) - 180; % \in [-180, 180)

    % Empirically, 
    A(isnan(A)) = 0; % really, A = all real numbers, but default to 0

    % Snap endpoints:
    A(abs(A - (-90)) < tol) = -90;
    A(abs(A - 0) < tol) =   0;
    R(abs(R - (-80)) < tol) =  -80;
    R(abs(R - 0) < tol) = 0;
    R(abs(R - 80) < tol) = 80;

    % Degeneracy exists at R=0, since all A angles produce (Az,Rz)=(0,I):
    A(R == 0) = 0; % default to A=0 for A in all real numbers

end

% [END] FUNCTIONS.
% =========================================================================
% =========================================================================
% [BEGIN] FUNCTIONS SPECIFICALLY FOR VALIDATION TESTING:

function sample_new_cell = fudge_data(sample)
    % FOR VALIDATION TEST, BY MAKING MAGIC BLACK MEASUREMENT HAVE VALUES
    % AT A=+90, WHICH WAS NOT CAPTURED IN 'MagicBlack_v2o0_20250902.xls' 
    % MEASUREMENT.

    % "MagicBlack_v2o0_20250902.xls" failed to capture A = 90, so copy ...
    % ... from A = -90 and flip R.
    sample = sample{1};
    A = sample(1, :);
    I = sample(2, :);
    Iu = unique(I);
    nA = length(unique(A));
    nI = length(Iu);
    nR = length(unique(sample(3, :)));
    sample_new = zeros(6, size(sample, 2) + nI*nR); % add columns for 
        % missed A = 90 measurements
    mA = A == -90; % mask of A = -90
    k1 = 0; % initialize
    for i = 1:nI
        mI = I == Iu(i);
        mAI = and(mA, mI);
        k0 = k1 + 1; % next index, at which to copy/paste 'sample'
        k1 = k0 + sum(mI) - 1; % assume all I are adjacent; note 'sum(mI)'
        sample_new(:, k0:k1) = sample(:, mI); % ... is length
        k0 = k1 + 1; % next index, at which to insert A = +90 set
        k1 = k0 + nR - 1;
        sample_new(1, k0:k1) = repelem(90, nR); % paste A = +90
        sample_new(2, k0:k1) = repelem(Iu(i), nR); % paste I
        sample_new(3:6, k0:k1) = flip(sample(3:6, mAI), 2); % flip R order
        sample_new(3, k0:k1) = -sample_new(3, k0:k1); % flip sign of R
    end
    sample_new_cell = cell(1, 1);
    sample_new_cell{1} = sample_new;
end


function BRDF = hardcode_BrownVinyl_BRDF(BRDF)
    % FOR VALIDATION TEST OF TIS CALCULATION, AGAINST AZ=[0,180] VALUES
    % HARDCODED FROM 'BrownVinyl.BSDF'. EXPECTING VERY CLOSE EXACT 
    % AGREEMENT, BECAUSE TRUSTING BROWNVINYL DATASET.

    BRDF_15 = [...
        6.375E-02	6.180E-02	5.879E-02	5.529E-02	5.190E-02	4.618E-02	4.038E-02	3.689E-02	3.463E-02	3.304E-02	3.219E-02   0; ...
        6.375E-02	6.199E-02	5.886E-02	5.563E-02	5.220E-02	4.724E-02	4.073E-02	3.693E-02	3.480E-02	3.324E-02	3.252E-02   0; ...
        6.375E-02	6.215E-02	5.940E-02	5.591E-02	5.241E-02	4.649E-02	4.088E-02	3.726E-02	3.506E-02	3.355E-02	3.255E-02   0; ...
        6.375E-02	6.217E-02	5.975E-02	5.624E-02	5.249E-02	4.656E-02	4.085E-02	3.783E-02	3.553E-02	3.397E-02	3.319E-02   0; ...
        6.375E-02	6.246E-02	6.003E-02	5.674E-02	5.328E-02	4.689E-02	4.172E-02	3.797E-02	3.594E-02	3.453E-02	3.342E-02   0; ...
        6.375E-02	6.255E-02	6.036E-02	5.707E-02	5.347E-02	4.734E-02	4.190E-02	3.852E-02	3.658E-02	3.501E-02	3.410E-02   0; ...
        6.375E-02	6.264E-02	6.070E-02	5.720E-02	5.405E-02	4.798E-02	4.227E-02	3.913E-02	3.708E-02	3.550E-02	3.575E-02   0; ...
        6.375E-02	6.303E-02	6.078E-02	5.772E-02	5.438E-02	4.798E-02	4.312E-02	3.976E-02	3.760E-02	3.634E-02	9.277E-03   0; ...
        6.375E-02	6.314E-02	6.126E-02	5.895E-02	5.489E-02	4.862E-02	4.370E-02	4.043E-02	3.813E-02	3.695E-02	3.492E-03   0; ...
        6.375E-02	6.302E-02	6.136E-02	5.852E-02	5.517E-02	4.881E-02	4.395E-02	4.109E-02	3.891E-02	3.763E-02	3.749E-02   0; ...
        6.375E-02	6.343E-02	6.182E-02	5.889E-02	5.571E-02	4.959E-02	4.467E-02	4.139E-02	3.959E-02	3.821E-02	4.049E-02   0; ...
        6.375E-02	6.363E-02	6.182E-02	5.916E-02	5.594E-02	4.994E-02	4.529E-02	4.215E-02	4.044E-02	3.911E-02	0.000E+00   0; ...
        6.375E-02	6.366E-02	6.210E-02	5.947E-02	5.649E-02	5.063E-02	4.586E-02	4.293E-02	4.113E-02	4.078E-02	0.000E+00   0; ...
        6.375E-02	6.371E-02	6.210E-02	5.975E-02	5.692E-02	5.087E-02	4.643E-02	4.372E-02	4.191E-02	4.207E-02	0.000E+00   0; ...
        6.375E-02	6.372E-02	6.238E-02	6.003E-02	5.713E-02	5.176E-02	4.737E-02	4.474E-02	4.302E-02	4.613E-02	0.000E+00   0; ...
        6.375E-02	6.390E-02	6.248E-02	6.028E-02	5.763E-02	5.233E-02	4.808E-02	4.564E-02	4.388E-02	4.473E-02	0.000E+00   0; ...
        6.375E-02	6.404E-02	6.289E-02	6.061E-02	5.803E-02	5.286E-02	4.897E-02	4.626E-02	4.530E-02	0.000E+00	0.000E+00   0; ...
        6.375E-02	6.410E-02	6.277E-02	6.124E-02	5.827E-02	5.327E-02	4.961E-02	4.706E-02	4.580E-02	0.000E+00	0.000E+00   0; ...
        6.375E-02	6.406E-02	6.266E-02	6.103E-02	5.838E-02	5.400E-02	4.977E-02	4.729E-02	4.650E-02	0.000E+00	0.000E+00   0];
    
    BRDF_30 = [...
        7.662E-02	7.180E-02	6.634E-02	6.025E-02	5.476E-02	4.545E-02	3.893E-02	3.545E-02	3.402E-02	3.232E-02	3.099E-02   0; ...
        7.662E-02	7.210E-02	6.663E-02	6.140E-02	5.534E-02	4.639E-02	3.935E-02	3.576E-02	3.388E-02	3.204E-02	3.086E-02   0; ...
        7.662E-02	7.231E-02	6.726E-02	6.120E-02	5.552E-02	4.604E-02	3.968E-02	3.578E-02	3.349E-02	3.209E-02	3.124E-02   0; ...
        7.662E-02	7.273E-02	6.747E-02	6.198E-02	5.609E-02	4.676E-02	4.076E-02	3.662E-02	3.387E-02	3.252E-02	3.157E-02   0; ...
        7.662E-02	7.322E-02	6.824E-02	6.259E-02	5.691E-02	4.729E-02	4.155E-02	3.682E-02	3.454E-02	3.318E-02	3.239E-02   0; ...
        7.662E-02	7.333E-02	6.879E-02	6.331E-02	5.774E-02	4.805E-02	4.167E-02	3.778E-02	3.523E-02	3.398E-02	3.317E-02   0; ...
        7.662E-02	7.372E-02	6.959E-02	6.413E-02	5.848E-02	4.918E-02	4.250E-02	3.868E-02	3.609E-02	3.475E-02	3.373E-02   0; ...
        7.662E-02	7.437E-02	7.035E-02	6.491E-02	5.939E-02	5.015E-02	4.370E-02	3.977E-02	3.741E-02	3.600E-02	3.493E-02   0; ...
        7.662E-02	7.485E-02	7.110E-02	6.592E-02	6.103E-02	5.159E-02	4.503E-02	4.074E-02	3.835E-02	3.691E-02	3.635E-02   0; ...
        7.662E-02	7.523E-02	7.193E-02	6.734E-02	6.211E-02	5.275E-02	4.654E-02	4.229E-02	3.990E-02	3.786E-02	3.573E-02   0; ...
        7.662E-02	7.613E-02	7.325E-02	6.884E-02	6.387E-02	5.475E-02	4.828E-02	4.391E-02	4.154E-02	3.929E-02	0.000E+00   0; ...
        7.662E-02	7.672E-02	7.438E-02	7.050E-02	6.578E-02	5.725E-02	5.049E-02	4.617E-02	4.370E-02	4.396E-02	0.000E+00   0; ...
        7.662E-02	7.724E-02	7.543E-02	7.229E-02	6.786E-02	5.970E-02	5.270E-02	4.894E-02	4.616E-02	0.000E+00	0.000E+00   0; ...
        7.662E-02	7.792E-02	7.681E-02	7.402E-02	7.032E-02	6.309E-02	5.692E-02	5.238E-02	5.168E-02	0.000E+00	0.000E+00   0; ...
        7.662E-02	7.813E-02	7.749E-02	7.572E-02	7.296E-02	6.652E-02	6.117E-02	5.678E-02	3.815E-03	0.000E+00	0.000E+00   0; ...
        7.662E-02	7.870E-02	7.863E-02	7.744E-02	7.526E-02	7.033E-02	6.620E-02	6.453E-02	0.000E+00	0.000E+00	0.000E+00   0; ...
        7.662E-02	7.904E-02	7.950E-02	7.883E-02	7.722E-02	7.404E-02	7.153E-02	7.274E-02	0.000E+00	0.000E+00	0.000E+00   0; ...
        7.662E-02	7.903E-02	7.997E-02	8.005E-02	7.873E-02	7.572E-02	7.481E-02	8.026E-02	0.000E+00	0.000E+00	0.000E+00   0; ...
        7.662E-02	7.921E-02	7.986E-02	8.056E-02	7.952E-02	7.792E-02	7.717E-02	8.369E-02	0.000E+00	0.000E+00	0.000E+00   0];
    
    BRDF_50 = [...
        1.695E-01	1.429E-01	1.184E-01	9.932E-02	8.307E-02	5.954E-02	4.569E-02	3.862E-02	3.394E-02	3.174E-02	3.105E-02   0; ...
        1.695E-01	1.432E-01	1.190E-01	1.003E-01	8.401E-02	6.046E-02	4.655E-02	3.856E-02	3.444E-02	3.235E-02	3.136E-02   0; ...
        1.695E-01	1.453E-01	1.219E-01	9.961E-02	8.366E-02	6.013E-02	4.695E-02	3.914E-02	3.543E-02	3.285E-02	3.185E-02   0; ...
        1.695E-01	1.461E-01	1.217E-01	1.014E-01	8.405E-02	6.114E-02	4.739E-02	4.010E-02	3.617E-02	3.370E-02	3.254E-02   0; ...
        1.695E-01	1.477E-01	1.234E-01	1.022E-01	8.458E-02	6.102E-02	4.817E-02	4.061E-02	3.694E-02	3.489E-02	3.366E-02   0; ...
        1.695E-01	1.490E-01	1.258E-01	1.035E-01	8.542E-02	6.125E-02	4.886E-02	4.182E-02	3.802E-02	3.629E-02	3.504E-02   0; ...
        1.695E-01	1.515E-01	1.280E-01	1.056E-01	8.644E-02	6.269E-02	4.983E-02	4.296E-02	3.934E-02	3.769E-02	3.653E-02   0; ...
        1.695E-01	1.566E-01	1.323E-01	1.099E-01	8.895E-02	6.409E-02	5.110E-02	4.448E-02	4.113E-02	3.897E-02	3.790E-02   0; ...
        1.695E-01	1.599E-01	1.368E-01	1.136E-01	9.373E-02	6.657E-02	5.297E-02	4.613E-02	4.246E-02	4.069E-02	3.862E-02   0; ...
        1.695E-01	1.620E-01	1.419E-01	1.189E-01	9.817E-02	6.946E-02	5.525E-02	4.799E-02	4.417E-02	4.169E-02	4.253E-02   0; ...
        1.695E-01	1.680E-01	1.501E-01	1.283E-01	1.058E-01	7.504E-02	5.844E-02	5.051E-02	4.642E-02	3.392E-02	0.000E+00   0; ...
        1.695E-01	1.717E-01	1.588E-01	1.389E-01	1.156E-01	8.280E-02	6.329E-02	5.397E-02	8.440E-03	0.000E+00	0.000E+00   0; ...
        1.695E-01	1.778E-01	1.701E-01	1.522E-01	1.298E-01	9.443E-02	6.984E-02	7.133E-02	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.695E-01	1.837E-01	1.813E-01	1.680E-01	1.501E-01	1.116E-01	8.628E-02	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.695E-01	1.867E-01	1.914E-01	1.875E-01	1.761E-01	1.419E-01	9.272E-02	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.695E-01	1.921E-01	2.042E-01	2.079E-01	2.077E-01	1.864E-01	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.695E-01	1.952E-01	2.155E-01	2.293E-01	2.396E-01	2.499E-01	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.695E-01	1.967E-01	2.213E-01	2.440E-01	2.663E-01	3.259E-01	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.695E-01	1.984E-01	2.236E-01	2.503E-01	2.788E-01	3.680E-01	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0];
    
    BRDF_70 = [...
        1.880E+00	1.158E+00	7.027E-01	4.389E-01	2.885E-01	1.363E-01	7.973E-02	5.362E-02	4.069E-02	3.505E-02	3.142E-02   0; ...
        1.880E+00	1.156E+00	7.014E-01	4.445E-01	2.870E-01	1.387E-01	7.935E-02	5.406E-02	4.144E-02	3.489E-02	3.215E-02   0; ...
        1.880E+00	1.172E+00	7.011E-01	4.162E-01	2.677E-01	1.280E-01	7.657E-02	5.304E-02	4.152E-02	3.578E-02	3.313E-02   0; ...
        1.880E+00	1.153E+00	6.601E-01	3.942E-01	2.438E-01	1.200E-01	7.138E-02	5.139E-02	4.154E-02	3.616E-02	3.388E-02   0; ...
        1.880E+00	1.175E+00	6.342E-01	3.632E-01	2.246E-01	1.064E-01	6.681E-02	4.953E-02	4.204E-02	3.747E-02	3.535E-02   0; ...
        1.880E+00	1.176E+00	6.130E-01	3.383E-01	2.040E-01	9.604E-02	6.278E-02	4.941E-02	4.309E-02	3.960E-02	3.703E-02   0; ...
        1.880E+00	1.163E+00	5.922E-01	3.223E-01	1.850E-01	8.926E-02	5.976E-02	4.945E-02	4.396E-02	4.089E-02	3.862E-02   0; ...
        1.880E+00	1.216E+00	5.989E-01	3.163E-01	1.760E-01	8.402E-02	5.813E-02	4.951E-02	4.542E-02	4.244E-02	4.021E-02   0; ...
        1.880E+00	1.277E+00	6.139E-01	3.136E-01	1.738E-01	8.079E-02	5.823E-02	4.989E-02	4.649E-02	4.317E-02	4.217E-02   0; ...
        1.880E+00	1.283E+00	6.315E-01	3.145E-01	1.726E-01	7.760E-02	5.851E-02	5.074E-02	4.795E-02	4.861E-02	0.000E+00   0; ...
        1.880E+00	1.449E+00	7.136E-01	3.474E-01	1.805E-01	8.214E-02	5.972E-02	3.514E-03	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.880E+00	1.514E+00	8.079E-01	3.938E-01	1.924E-01	9.491E-02	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.880E+00	1.705E+00	9.632E-01	4.805E-01	2.347E-01	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.880E+00	1.968E+00	1.221E+00	6.276E-01	1.119E-01	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.880E+00	2.110E+00	1.554E+00	9.510E-01	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.880E+00	2.402E+00	2.101E+00	9.303E-01	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.880E+00	2.720E+00	2.915E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.880E+00	2.822E+00	3.651E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0; ...
        1.880E+00	2.920E+00	4.041E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00	0.000E+00   0];
    
    BRDF{1} = BRDF_15;
    BRDF{2} = BRDF_30;
    BRDF{3} = BRDF_50;
    BRDF{4} = BRDF_70;

end

% [END] FUNCTIONS SPECIFICALLY FOR VALIDATION TESTING.
% =========================================================================
% =========================================================================
% [BEGIN] FUNCTION SPECIFICALLY FOR EXPORTING TO FRED FORMAT.

function status = save_as_fred(I_iso, A_iso, R_iso, ...
    BRDF_in_RT300S_frame, name_txt_file, OUTPUT_FULL_AZIMUTH)
    % Assumption(s):
    %   1) 'A_iso' \in [-90, 0], and if full [-90,90] was measured then
    %       (0,90] was averaged with [-90,0) data (isotropic condition).

    status = 0;

    % % Copy 'A_iso' values from [-90,0] to (0,90] to get \phi_s \in (90,180)
    % % and (270,360); otherwise only [0,90],[180,270] defined.
    % mA = ~(A_iso == 0); % assuming last entries of 'A_iso' are 0, and so 
    %     % intending to apply flip only to negative values
    % A = [A_iso, -flip(A_iso(mA))]; % mirrors [-90,0) to make [-90,90]
    % I = [I_iso, flip(I_iso(mA))]; % match 'A_full'
    % R = [R_iso, -flip(R_iso(mA))]; % match 'A_full'; negative for '-A'
    % BRDF = [BRDF_in_RT300S_frame, flip(BRDF_in_RT300S_frame(mA))]; % match

    % Copy 'A_iso' values from [-90,0] to [-90,90) to get \phi_s \in 
    % [0,180) and [180,360); otherwise only [0,90] and [180,270] defined.
    mA = ~or(A_iso == -90, A_iso == 0); % assuming first entries of 'A_iso'
        % are -90 and last entries are 0, so fliping (-90,0) to produce 
        % [-90,90); not sure if this mask and flip break with first/last 
        % entries are not -90/0;
    A = [A_iso, -flip(A_iso(mA))]; % mirrors (-90,0) to make [-90,90)
    I = [I_iso, flip(I_iso(mA))]; % match 'A_full'
    R = [R_iso, -flip(R_iso(mA))]; % match 'A_full'; BRDF at (A,R) equal to 
        % BRDF at (-A,-R) is the isotropic assumption
    BRDF = [BRDF_in_RT300S_frame, flip(BRDF_in_RT300S_frame(mA))]; % match

    % Process:
    Iu = unique(I);
    Au = unique(A);
    nI = length(Iu);
    nA = length(Au);

    % Arbitrary (because iso) RT-300S coordinate:
    rot = -(0 : abs(Au(2) - Au(1)) : 360); % sample rotation; all real 
        % numbers [0,360); make negative so phi_i becomes positive;
    rot = rot(1 : end - 1); % [0,360] to [0,360);
    % NOTE: 'rot' requires same spacing as 'A' to keep \phi_s
    % aligned with 0, i.e., [0,360), else would need to adjust \phi_i 
    % (which is arbitrary for isotropic and therefore could be
    % adjusted, but the FRED format examples have equidistant \phi_i
    % values; the heart of this constraint is that \phi_i - \phi_s is
    % what matters for isotropic, so changing \phi_s to align to 0
    % would requires changing \phi_i -- setting 'rot' spacing seems to
    % be only way to preserve both \phi_s aligned to 0 and \phi_i
    % equidistant);

    % FRED coordinates:
    theta_i = Iu;
    phi_i = -rot;
    mR = R > 0; % treat R=0 separately; ignore R<0 because need for loop to
        % behave like: 
            % Iter 1: (R= +5, for Ai)
            % Iter 2: (R= -5, for Ai)
            % Iter 3: (R=+10, for Ai)
            % ...
    theta_s = unique(R(mR));
    % \phi_s defined later

    % Prepare structure of BRDF data:

    out_arr = cell(nI, length(rot), length(theta_s)); % (\theta_i, \phi_i, 
        % \theta_s); for storing BRDF values prior to re-ordering \phi_s 
        % from [rot, rot + 360) to [0,360)

    for Ii = 1:nI % for \theta_i
        mI = I == Iu(Ii);
        for rotj = 1:length(rot) % for \phi_i

            % % FOR DEBUGGING / UNDERSTANDING FOR LOOP:
            % fprintf('==================================================\n')
            % fprintf('%i     %i\n', theta_i(Ii), phi_i(rotj))
            % fprintf('==================================================\n')

            for k = 1:length(theta_s)
                out_arr{Ii, rotj, k} = nan(2*nA, 2);
                current_row = 0;
                for R_sign = [+1, -1] % for sign of what R actually is
                    mR = R == R_sign * theta_s(k); % important to 
                        % mask for 'R' not '|R|' else 'mIRA' will return 
                        % two measurements
                    mIR = and(mI, mR);
                    for Ai = 1:nA % for \phi_s
                        current_row = current_row + 1;
                        mA = A == Au(Ai);
                        mIRA = and(mIR, mA); % should be single true value
                        j = mIRA == 1; % index of (hopefully) single value
                    
                        phi_s = 90 + Au(Ai) - rot(rotj) ...
                            + (1 - R_sign)*90; % adds 180 if R<0
                    
                        % % FOR DEBUGGING / UNDERSTANDING FOR LOOP:
                        % fprintf('%i     %i\n', theta_s(k), phi_s)

                        out_arr{Ii, rotj, k}(current_row, :) = ...
                            [phi_s, BRDF(j)];
                    end
                end
            end
        end
    end

    % Because \phi_s picks up \Delta{\phi_i} each new \phi_i, need to
    % re-order \phi_s to [0,360) in each (\theta_i, \phi_i, \theta_s) set:

    for Ii = 1:nI % for \theta_i
        for rotj = 1:length(rot) % for \phi_i
            for k = 1:length(theta_s)
                
                % Shift to [0,360) domain:
                mphis_lo = out_arr{Ii, rotj, k}(:, 1) < 0; % initialize
                mphis_hi = out_arr{Ii, rotj, k}(:, 1) >= 360;
                while any([mphis_lo; mphis_hi])
                    out_arr{Ii, rotj, k}(mphis_lo, 1) = ...
                        out_arr{Ii, rotj, k}(mphis_lo, 1) + 360; % shift
                    out_arr{Ii, rotj, k}(mphis_hi, 1) = ...
                        out_arr{Ii, rotj, k}(mphis_hi, 1) - 360;
                    mphis_lo = out_arr{Ii, rotj, k}(:, 1) < 0; % update
                    mphis_hi = out_arr{Ii, rotj, k}(:, 1) >= 360;
                end
                
                % Re-order to [0,360):
                [~, sort_id] = sort(out_arr{Ii, rotj, k}(:, 1));
                out_arr{Ii, rotj, k} = out_arr{Ii, rotj, k}(sort_id, :);
                
            end
        end
    end

    % Open text file:
    fid = fopen(name_txt_file, 'w');

    % % Write development notes (pre header):
    % fprintf(fid, '# IS THIS A COMMENT ?\n');

    % Write header:
    fprintf(fid, 'type bsdf_data\n');
    fprintf(fid, 'format angles=deg bsdf=value scale=1\n');

    % Write BRDF data to FRED file (now that \phi_s is sorted):

    % For isotropic, need only phi_i = 0

    mR = R == 0;
    for Ii = 1:nI % for \theta_i
        mRI = and(mR, I == Iu(Ii));

        % % OUTDATED: Define all incident azimuths for isotropic:
        % for rotj = 1:length(rot) % for \phi_i
        % CORRECTION: Only need one incident azimuth for isotropic:
        rotj = 1;

            fprintf(fid, '%i	%i\n', theta_i(Ii), phi_i(rotj)); 
                % space is tab

            % Write for \theta_s = 0:
            BRDF_at_R0 = BRDF(mRI); % average values from all 'A'
            BRDF_at_R0 = mean(BRDF_at_R0(~isnan(BRDF_at_R0))); 
                % average only non-nan entries
            % % OUTDATED: Define all scatter azimuths for \theta_s = 0:
            % for phi_s_dummy = -rot
            %     fprintf(fid, '0	%i	%.6f\n', phi_s_dummy, BRDF_at_R0);
            %         % space is tab
            % end
            % CORRECTION: Only need one scatter azimuth for \theta_s = 0:
            fprintf(fid, '0	0	%.6f\n', BRDF_at_R0); % space is tab

            % Write for \theta_s > 0:
            for k = 1:length(theta_s) % for \theta_s > 0
                current = 0;
                for R_sign = [+1, -1] % for sign of what R actually is
                    for Ai = 1:nA % for \phi_s
                        current = current + 1;
                        phi_s_current = out_arr{Ii, rotj, k}(current, 1);

                        % OPTIONAL CORRECTION: Only need to define \phi_s 
                        % \in [0, 180] deg; FRED mirrors to (180, 360).
                        if OUTPUT_FULL_AZIMUTH % then no correction
                            DEFINE_PSI_S = true;
                        else % then apply correction
                            if phi_s_current >= 0 && phi_s_current <= 180
                                DEFINE_PSI_S = true; % within range
                            else
                                DEFINE_PSI_S = false; % outside range
                            end
                        end

                        if DEFINE_PSI_S
                            BRDF_current = out_arr{Ii, rotj, ...
                                k}(current, 2);
                            if ~isnan(BRDF_current) % ONLY WRITE IF NOT NAN
                                fprintf(fid, '%i	%i	%.6f\n', ...
                                    theta_s(k), phi_s_current, ...
                                    BRDF_current); % space is tab
                            end
                        end

                    end
                end
            end

        % end % OUTDATED
    end

    % Close text file and return status=1 success:
    fclose(fid);
    status = 1;

end

% [END] FUNCTION SPECIFICALLY FOR EXPORTING TO FRED FORMAT.
% =========================================================================
% =========================================================================

