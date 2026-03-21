


% Convert FRED file to Zemax BSDF file:

clc, clearvars, close all



filepath = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\fred\AnoBlackEC1onAlum.txt';

% Query points for FRED-to-Zemax interpolation:
Az_q = 0 : 10 : 180; % [0, 180] if isotropic, [0, 360) if anisotropic
Rz_q = [0 : 5 : 15, 20 : 10 : 180]; % [0, 180]

ISOTROPIC = true;
OVERWRITE = true;
MAX_IS_SPECULAR= true;






% end user inputs
% ======

[Pi, Ai, Ps, As, BRDF] = load_fred(filepath);

[S, I, Az, Rz] = fred_frame_to_zemax(Pi, Ai, Ps, As);




% NOT YET VALIDATED, BUT ON SURFACE NO BUGS:
[S, I, Az, Rz, BRDF] = interpolate_zemax(S, I, Az, Rz, BRDF, Az_q, Rz_q, ISOTROPIC, MAX_IS_SPECULAR);



% Write to BSDF file:
filepath = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\zemax\test.bsdf';
write_zemax(S, I, Az, Rz, BRDF, filepath, ISOTROPIC, OVERWRITE);








