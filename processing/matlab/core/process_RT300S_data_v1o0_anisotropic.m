% =========================================================================
% =========================================================================
% 
% process_RT300S_data.m
% (v1.1 - anisotropic)
% 
% Description:
%   - Process raw data from J&C's RT-300S scatterometer, into format for
%     Zemax's BSDF file. Assumes anisotropic and monochromatic.
% 
% Assumptions:
%   1) Data files are in default Excel format as output by BRDF machine.
%       1a) [A; I; R] are in degrees.
%       1b) [A; I; R] cycles through steps like Boolean 000, 001, 010, etc.
%   2) Sample is anisotropic, with sample rotations provided by different
%      dataset files. Additionally, each measurement is assumed to be at 
%      unique sample rotation, i.e., no averaging occurs.
%   3) Light source is monochromatic (or only data from first wavelength 
%      gets read).
%   4) Blank data has identical [A; I; R] values in same order as sample.
%   5) All datasets share the same light-source alignment, meaning all data 
%      is shifted by same amount to compensate for systematic error.
%   6) Sample rotation angles map to scatter-cone azimuth angles; e.g., if
%      Azq = [0, 10, ..., 43.2, 50, ..., 90, 100, ..., 133.2, 140, ...]
%      would be needed for sample rotations of 90 degrees. See 
%      'Interpolation' section of ANSYS article "How to use tabular BSDF 
%      data to define the surface scattering distribution" detailing this.
%      With sample rotation steps of 10 degrees, and azimuth steps also of 
%      10 degrees, should be fine. Any issues would be from how Zemax
%      interpolates, not noticeable in this data processing.
%   7) The anisotropic sample is symmetric about its x and y axes, meaning
%      only [0,90] sample rotations need to be measured. These measurements
%      are then copied (mirrored) to (90,360). But, either way, Zemax 
%      requires [0,360] be defined.
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
% | 2025.10.07 | JPK  | Adapted into new script for anisotropic sample;   |
% | 2025.11.20 | JPK  | [v1.1] Debugging missing quadrants in BSDF files; |
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

% Filenames of measurements, where first element is the blank data used
% to zero the sample measurements:
    % - include '.xls' extension;
filenames = ["blank_v2o0_20250911_eitherWayItsATragedy.xls"; ... % blank
             "IMX455_stageRotation0_20250922.xls"; ... % sample rotation 1
             "IMX455_stageRotation10_20250922.xls"; ... % ...
             "IMX455_stageRotation20_20250922.xls"; ... % ...
             "IMX455_stageRotation30_20250922.xls"; ... % ...
             "IMX455_stageRotation40_20250922.xls"; ... % ...
             "IMX455_stageRotation50_20250922.xls"; ... % ...
             "IMX455_stageRotation60_20250922.xls"; ... % ...
             "IMX455_stageRotation70_20250922.xls"; ... % ...
             "IMX455_stageRotation80_20250922.xls"; ... % ...
             "IMX455_stageRotation90_20250922.xls"]; % sample rotation M

% Legend entries for plots of each dataset:
legend_names_for_datasets = ["$\psi = 0^{\circ}$", "$10^{\circ}$", ...
    "$20^{\circ}$", "$30^{\circ}$", "$40^{\circ}$", "$50^{\circ}$", ...
    "$60^{\circ}$", "$70^{\circ}$", "$80^{\circ}$", "$90^{\circ}$"];

% Information for BSDF file:
name_sample = "IMX455 lenslet array w/o cover glass"; 
    % name of sample measured
name_source = "red laser (650 nm, 3.5mm spot diam.)"; 
    % name of light source used
name_angles = "(10:20:70, -90:10:90, -80:10:80)"; % in (I,A,R) order
name_dates = ["2025/09/22"]; % date(s) measurements were made
name_contact = "Jacob P. Krell (jacobpkrell@arizona.edu)"; % name of person
    % to contact, most likely you or whoever made the measurement; consider
    % including email or phone number in parentheses too
name_bsdf_file = "IMX455.bsdf"; % name of new BSDF file to output 
    % results to; include '.bsdf' extension

% Logicals for returning plots:
RETURNPLOT_RT_AzRz = false;
RETURNPLOT_BRDF_AzRz = false;

% Logical for attempting to correct light source misalignment:
    % - note, fails to apply to when averaging A=[-90,0] and A=[0,90] of 
    %   same dataset, because would need to convert new (Az,Rz) to a new
    %   (A,R), which no longer would be common between datasets, and
    %   therefore would need to interpolate RT on those uncommon (A,R)
    %   values to a common grid prior to averaging;
    % - probably not good for anisotropic, because uses max RT value, which
    %   may not be from "specular" ray;
APPLY_SHIFT_CORRECTION = false;

% Machine dimensions:
beamdiam = 3.5; % [mm], spot diameter of light source (used to determine
    % the solid angle of the specular beam)
armlength = 82; % [mm], length of RT-300S's detector arm, i.e., the radius
    % from the sample placed at the machine's origin to the detector

% Anisoptropic sample rotations (corresponding to datasets):
sample_rotations = 0 : 10 : 90; % [deg], vector of sample rotation angles
    % that gets written to BSDF file; assumes [0,90] range

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
filepath_bsdf_file = fullfile(dir_project, 'data', 'processed', 'zemax', name_bsdf_file); 
    % full filepath to where bsdf file is to be saved
FILENAME_IS_AVAILABLE = true;
if exist(filepath_bsdf_file, 'file')
    FILENAME_IS_AVAILABLE = false;
    error('BSDF file with user-specified name already exists. Specify different filename.', name_bsdf_file);
end

% Load data:
[sample, blank] = load_data(dir, filenames);

% [END] LOAD DATA.
% =========================================================================
% =========================================================================
% [BEGIN] DATA PROCESSING:

% Constants:
M = length(sample); % number of measurements (not including blank)
    % - for anisotropic, each measurement is assumed to be at unique sample
    %   rotation, i.e., no averaging

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
[Az, Rz] = IAR_to_AzRz(I, A, R); % [deg]
AzRz_as_x = -Rz .* sind(Az); % for making polar plot in Cartesian space
AzRz_as_y = Rz .* cosd(Az); % for making polar plot in Cartesian space

% Corrections to RT measurements:

RT = cell(M, 1);
fig_RT_AR = cell(M, 1);
mObscured = cell(M, 1);
fig_RT_AzRz = cell(M, 1);
specular_error = zeros(M, nI); % offset of max RT from incident plane
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

    % Check visual of polar heatmap, i.e., RT vs. (Az, Rz):
    if RETURNPLOT_RT_AzRz
        fig_RT_AzRz{m} = ...
            plot_RT_AzRz(nI, Iu, I, AzRz_as_x, AzRz_as_y, RT{m});
    end
    
    % Fourth correction (shift max RT to incident plane to compensate for
    % systematic error):
        % - introduced by JPK
    for i = 1:nI
        mI = I == Iu(i);
        [~, id_of_maxRT] = max(RT{m}(mI));
        AzRz_as_x_mI = AzRz_as_x(mI);
        specular_error(m, i) = AzRz_as_x_mI(id_of_maxRT); % offset from 
            % incident plane
    end

end
clear blank

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

% Interpolate RT values to desired Zemax output (Az,Rz) grid, with 0 for
    % out-of-range values:
Azq = 0 : 10 : 360; % Az query points
% Rzq = [0 : 5 : 20, 30 : 10 : 80, 90]; % adding 90 to be 0 floor, note
%     % BrownVinyl does this with 80; note 90 really will have some RT value,
%     % but need to ensure Zemax's interpolation does not give value to >90
Rzq = [0 : 5 : 20, 30 : 10 : 180]; % define full hemisphere
nAzq = length(Azq);
nRzq = length(Rzq);
[Rzq_grid, Azq_grid] = meshgrid(Rzq, Azq);
RT_eval = cell(nI, M); % interpolated RT values evaluated on (Az,Rz) grid
[Az_expanded, mAz_IV, mAz_I] = quads_IV_I_to_nIV_pI(Az); % need to copy Az=[0,360) to 
    % Az = (<0,>360) so can interpolate near Az=0 and Az=360; specifically, 
    % copying Az=[0,90) to Az=[360,450) and Az=(270,360) to Az=(-90,0); 
    % that is, quadrants [IV, I] copied to produce [IV, I, II, III IV, I];
Az_data = [Az, Az_expanded]; % scatter data copied to full azimuth
Rz_data = [Rz, Rz(mAz_IV), Rz(mAz_I)]; % scatter data copied to full azimuth
I_data_wo_Az0 = [I, I(mAz_IV), I(mAz_I)]; % need to include expanded mAz in this way
    % so can use mI mask later
Az0 = -90 : 10 : 450; % copy RT value of specular ray at (Az,Rz)=(0,0) 
    % to (Az,Rz)=(Az0,0) for interpolation, so data is not only at Az=0
nAz0 = length(Az0);
Az_data = [Az_data, Az0]; % include also the specular ray data
Rz_data = [Rz_data, zeros(1, nAz0)]; % include also the specular ray data
for m = 1:M % for measurement, i.e., for each sample rotation
    RT_data_wo_Az0 = [RT{m}, RT{m}(mAz_IV), RT{m}(mAz_I)]; % scatter data copied to full
        % azimuth without Az0 additional datapoints
    for i = 1:nI
        mI = I_data_wo_Az0 == Iu(i); % uses expanded [-IV, ..., +I]
        mI_og = I == Iu(i); % uses original [I, ..., IV]
        % RT_data = [RT_data_wo_Az0, repelem(max(RT{m}(mI_og)), 1, nAz0)]; % add max
        %     % RT values to (Az,Rz)=(:,0), assuming the max RT value is the 
        %     % specular ray and corresponds to (Az,Rz)=(0,0)
        
        % =================================================================
        % [v1.1] CORRECTION, BECAUSE MAX RT IS NOT GOOD ASSUMPTION:
        mSpec1 = and(I == Iu(i), and(A == -90, R == Iu(i)));
        mSpec2 = and(I == Iu(i), and(A == 90, R == -Iu(i)));
        RT_spec1 = RT{m}(mSpec1); % expecting single value, from specular
            % ray measured at A = -90, R = I
        RT_spec2 = RT{m}(mSpec2); % expecting single value, from specular
            % ray measured at A = +90, R = -I
        RT_spec = mean([RT_spec1, RT_spec2]); % average the two measurements
        RT_data = [RT_data_wo_Az0, repelem(RT_spec, 1, nAz0)]; 
            % [v1.1] correction: copy RT value from specular ray to 
            % (Az,Rz)=(:,0), because assumption that max RT value is
            % specular ray is not stable assumption
        % =================================================================
            
        % Find where RT is nan, and remove those entries because they cause bug
        % in interpolation (they cause evaluated values to be 0 or nan):
        mKeep = and([mI, true(1, nAz0)], ~isnan(RT_data)); % mask to not 
            % remove, i.e., keep all elements at incident angle I and with 
            % unobscured RT values; note 'mI' defined with 'I_data_wo_Az0'
            % because of how quadrants are expanded, and Rz=0 entries require
            % 'true(1, nAz0)'
        Az_for_interp = Az_data(mKeep); % remove obscured entries
        Rz_for_interp = Rz_data(mKeep); % remove obscured entries
        RT_for_interp = RT_data(mKeep); % remove obscured entries
        % Define interpolation function:
        RT_interp = scatteredInterpolant(Az_for_interp', Rz_for_interp', ...
            RT_for_interp', 'natural', 'none');
        % Evaluate to target (Az,Rz) query grid:
        RT_eval{i, m} = RT_interp(Azq_grid(:), Rzq_grid(:));
        RT_eval{i, m}(isnan(RT_eval{i, m})) = 0; % handle exception of interpolation
            % function returning nan
        RT_eval{i, m} = reshape(RT_eval{i, m}, nAzq, nRzq); % format interpolated 
            % RT values into grid corresponding with (Az,Rz)
    end
end

% Set values at and beyond receive angle |R|>=90 equal to zero, as these
% would be transmission through the sample:
for i = 1:nI
    Ii = Iu(i); % incident angle
    mAz_gt90 = Azq_grid > 90; % since max(Rzq)<=90, then Az>=90 must be 
        % true in order for |R|>=90
    mAz_lt270 = Azq_grid < 270; % v1.1 correction, because really it is
        % 270>=Az>=90 that must be true in order for |R|>=90
    mAz_gt90_lt270 = and(mAz_gt90, mAz_lt270);
    Rz1 = (90 - Ii) ./ cosd(180 - Azq_grid); % upper limit of Rz at (I,Az)
    mRz_gtRz1 = Rzq_grid >= Rz1; % these angles produce |R|>=90
    mTranmission = and(mAz_gt90_lt270, mRz_gtRz1);
    for m = 1:M % for measurement, i.e., for each sample rotation
        RT_eval{i, m}(mTranmission) = 0; % set angles of transmission equal to 0
    end
end

% Convert query (Az,Rz) grid to receive angle R and convert RT to BRDF:
Aq_grid = cell(nI, 1);
Rq_grid = cell(nI, 1);
BRDF = cell(nI, M);
for i = 1:nI
    Ii = Iu(i);
    [Aq_grid{i}, Rq_grid{i}] = IAzRz_to_AR( ...
        repelem(Ii, nAzq * nRzq, 1), Azq_grid(:), Rzq_grid(:));
    Aq_grid{i} = reshape(Aq_grid{i}, nAzq, nRzq);
    Rq_grid{i} = reshape(Rq_grid{i}, nAzq, nRzq);
    for m = 1:M % for measurement, i.e., for each sample rotation
        BRDF{i, m} = RT_eval{i, m} ./ (pi * cosd(Rq_grid{i})); % equation 4.6 of [2]
        % Confirm values are zero if |R|>=90, or practically use lower
        % threshold, e.g., |R|>80; note BrownVinyl uses |R|>=80; if |R|>80:
            % - note 80 is also good cutoff because cosine-->0 means BRDF
            %   value explodes... practically, ~80 is this cutoff
        BRDF{i, m}(abs(Rq_grid{i}) > 80) = 0;
    end
end

% Check visual of polar heatmap, i.e., BRDF vs. (Az, Rz):
if RETURNPLOT_BRDF_AzRz
    fig_BRDF_AzRz = cell(M, 1);
    for m = 1:M
        fig_BRDF_AzRz{m} = ...
            plot_BRDF_AzRz(nI, Iu, Azq_grid, Rzq_grid, BRDF{:, m});
    end
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

% Calculate TIS:

dRz_specular = asin( (beamdiam/2) / armlength); % [rad], approximate dRz 
    % of specular beam

TIS = zeros(nI, M);
for i = 1:nI
    for m = 1:M

        % Calculate integral of total BRDF:
        TIS_total = 0; % initialize
        for j = 1 : (nAzq - 1) % minus one because forward integration
            for k = 1 : (nRzq - 1) % minus one because forward integration
                TIS_total = TIS_total ...
                    + (BRDF{i, m}(j,k) + BRDF{i, m}(j,k+1) ...
                       + BRDF{i, m}(j+1,k) + BRDF{i, m}(j+1,k+1)) / 4 ... 
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
        TIS_specular = BRDF{i, m}(1, 1) ...
                * (-cos(dRz_specular) + cos(0)) ...
                * dRz_specular ...
                * pi;

        % Subtract specular from total to get just scatter (which is TIS):
        TIS(i, m) = 2 * (TIS_total - TIS_specular); % x2 because Az = [0, 180], 
            % but need [0, 360]

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

line_SampleRot = "%i"; % initialize
if M > 1

    % for m = 2:M
    %     line_SampleRot = line_SampleRot + "	%i"; % note space between %i needs to be 
    %         % tab else Zemax fails to read BSDF file, and cannot have tab 
    %         % after last element
    % end

    % Need to define [0,360], but assuming only [0,90] is measured.
    % Therefore, M is number of datasets for [0,90]. To mirror, skip 90
    % and copy in reverse to map measured (90,0] to inferred (90,180].
    % However, also need to flip Az direction for sample rotations
    % (90,180] --> 360-Az. Then, copy (0,180] to (180,360] without any 
    % Az change. In total, this will be 4*(M-1)+1 sample rotations.

    for dummy_rotation = 2 : (4 * (M - 1) + 1)
        line_SampleRot = line_SampleRot + "	%i"; % note space between %i needs to be 
            % tab else Zemax fails to read BSDF file, and cannot have tab 
            % after last element
    end

end
line_SampleRot = line_SampleRot + "\n"; % finalize

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
fprintf(fid, "# Number of measurements averaged: n/a\n");
    % for anisotropic, each dataset is unique sample rotation and therefore
    % no measurements are averaged
fprintf(fid, line_blankdataset);
fprintf(fid, line_datasets);
fprintf(fid, "# Processing script: '" + mfilename() + ".m'\n");
    % e.g.: "# Processing script: 'process_RT300S_data_v1o0.m'\n"
fprintf(fid, line_dates);
fprintf(fid, "# Note(s): - sample is anisotropic;\n" + ...
    "#          - TIS calculated over entire hemisphere, i.e., " + ...
    "Az=[0,360), but only from BRDF values reported here so " + ...
    "assuming BRDF=0 beyond Rz>=90;\n");
fprintf(fid, "# Point of contact: " + name_contact + "\n");
    % e.g.: 
    % "# Point of contact: Jacob P. Krell (jacobpkrell@arizona.edu)\n"
fprintf(fid, "# \n");
fprintf(fid, "# [END] DEVELOPMENT INFORMATION.\n");
fprintf(fid, "# ======================================================\n");
fprintf(fid, "# ======================================================\n");
fprintf(fid, "# \n");

fprintf(fid, "Source	Measured\n"); % space is tab
fprintf(fid, "Symmetry	Asymmetrical4D\n"); % space is tab
    % assuming anisotropic sample
fprintf(fid, "SpectralContent	Monochrome\n"); % space is tab
    % assuming monochromatic light source
fprintf(fid, "ScatterType	BRDF\n"); % space is tab

sample_rotations_all = [sample_rotations, ...
    sample_rotations(2:end) + 90, sample_rotations(2:end) + 180, ...
    sample_rotations(2:end) + 270]; % make [0,90] into [0,360]
fprintf(fid, sprintf("SampleRotation	%i\n", length(sample_rotations_all))); % space is tab
fprintf(fid, line_SampleRot, sample_rotations_all);

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

% Zemax requires [0,360] sample rotations be defined; so, copy/mirror
% BRDF values (with Az flipped accordingly) from [0,90] sample rotation
% measurements. To do this,

% First, write measured BRDF values for [0,90] sample rotations:
for m = 1:M % for sample rotation
    for i = 1:nI % for incident angle
        fprintf(fid, "TIS	%.6f\n", TIS(i, m)); % space is tab
        for j = 1:nAzq
            fprintf(fid, line_BRDF, BRDF{i, m}(j, :)); % write row of BRDF values
        end
    end
end
% Second, copy measured [0,90] to inferred (90,180] sample rotation values:
    % - need 360-Az, and to go in reverse order (from 90 back to 0)
for m = (M - 1) : -1 : 1 % for sample rotation, flipped from [0,90] to (90,0]
    for i = 1:nI % for incident angle
        fprintf(fid, "TIS	%.6f\n", TIS(i, m)); % space is tab
        for j = nAzq : -1 : 1 % flipped because need 360-Az (to flip about incident plane),
                % and Azq=[0,360] with equal steps can simply be flipped in
                % element order to achieve 360-Az
            fprintf(fid, line_BRDF, BRDF{i, m}(j, :)); % write row of BRDF values
        end
    end
end
% Third, copy to (180,270] sample rotation values:
    % - exact same as 'First' except starting at m=2 b/c m=1 in 'Second'
for m = 2:M % for sample rotation
    for i = 1:nI % for incident angle
        fprintf(fid, "TIS	%.6f\n", TIS(i, m)); % space is tab
        for j = 1:nAzq
            fprintf(fid, line_BRDF, BRDF{i, m}(j, :)); % write row of BRDF values
        end
    end
end
% Fourth, copy to (270,360] sample rotation values:
    % - exact same as 'Second'
for m = (M - 1) : -1 : 1 % for sample rotation, flipped from [0,90] to (90,0]
    for i = 1:nI % for incident angle
        fprintf(fid, "TIS	%.6f\n", TIS(i, m)); % space is tab
        for j = nAzq : -1 : 1 % flipped because need 360-Az (to flip about incident plane),
                % and Azq=[0,360] with equal steps can simply be flipped in
                % element order to achieve 360-Az
            fprintf(fid, line_BRDF, BRDF{i, m}(j, :)); % write row of BRDF values
        end
    end
end

fprintf(fid, "DataEnd\n");

% Values have been written, so may close file:
fclose(fid);

% [END] WRITE TO ZEMAX BSDF FILE.
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


function [Az_expanded, mAz_IV, mAz_I] = quads_IV_I_to_nIV_pI(Az)
    % Assuming Az on domain Az=[0,360) convert quadrant IV (i.e., 
    % Az=(270,360)) to -IV (i.e., Az=(-90,0)) and quadrant I (i.e., 
    % Az=[0,90)) to +I (i.e., Az=[360,450)).
    % Returned is not [-IV, I, II, III, IV, +I], but just [-IV, +I].
    % Units are degrees.
    mAz_IV = Az > 270;
    mAz_I = Az < 90;
    Az_expanded = [Az(mAz_IV) - 360, Az(mAz_I) + 360];
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

