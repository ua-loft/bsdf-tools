
% JPK
% 2026/08/11

% Convert data in custom export format to standard FRED tabulated BSDF
% format, so can convert to Zemax then Speos.

% See 'rt300s_to_fred.m' for reference; this script is utility.



clc, clearvars, close all

% =====================
% =======
% user inputs:

% Data to load:
filepath_raw = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\_imported\Z306_from_FRED_20260811\tabulated_FRED_Z306_TIS0o08_specAzi0d.txt';

% File to create:
filepath_fred = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\fred\Z306_from_FRED_20260811\Aeroglaze_Z306_from_PEs_FRED_binomial_model_20260811_8percNormTIS.txt';


% end user.
% =======
% =======




% Load:
data = readmatrix(filepath_raw);
Pi = data(:, 1)';
Ai = data(:, 2)';
Ps = data(:, 3)';
As = data(:, 4)';
BRDF = data(:, 5)';

% Remove nan (text, etc. entries in the file):
mkeep = ~isnan(BRDF);
Pi = Pi(mkeep);
Ai = Ai(mkeep);
Ps = Ps(mkeep);
As = As(mkeep);
BRDF = BRDF(mkeep);

% % Remove normal incidence (b/c cannot define incident plane):
% mkeep = Pi ~= 0;
% Pi = Pi(mkeep);
% Ai = Ai(mkeep);
% Ps = Ps(mkeep);
% As = As(mkeep);
% BRDF = BRDF(mkeep);

% Average rings of same Ps for normal Pi=0 (since cannot define incident
% plane):
mPi = Pi == 0;
for Ps_val = unique(Ps(mPi))
    mPiPs = and(mPi, Ps == Ps_val);
    BRDF(mPiPs) = mean(BRDF(mPiPs));
end

% Remove multiple BRDF entries at surface normal scatter:
for Pi_val = unique(Pi)
    m = and(Pi == Pi_val, Ps == 0);
    BRDF(m) = mean(BRDF(m));
    m = and(m, As ~= 0);
    mkeep = ~m;
    Pi = Pi(mkeep);
    Ai = Ai(mkeep);
    Ps = Ps(mkeep);
    As = As(mkeep);
    BRDF = BRDF(mkeep);
end

% % Remove Ps > 80:
% mkeep = ~(Ps > 80);
% Pi = Pi(mkeep);
% Ai = Ai(mkeep);
% Ps = Ps(mkeep);
% As = As(mkeep);
% BRDF = BRDF(mkeep);

% =============

% Copy from 'rt300s_to_fred.m':

% Remove FRED redundancy for isotropic data (only need one Ai angle, and 
% only need $As - Ai \in [0, 180]$ defined):
[Pi, Ai, Ps, As, BRDF, ~] = remove_fred_redundancy_iso(Pi, Ai, Ps, As, BRDF);

% Write to FRED file:
write_fred(Pi, Ai, Ps, As, BRDF, filepath_fred);

