


% Convert FRED file to Zemax BSDF file:

clc, clearvars, close all



filepath = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\fred\AnoBlackEC1onAlum.txt';

dAz = 10;
dRz = 10;

ISOTROPIC = true;






% end user inputs
% ======

[Pi, Ai, Ps, As, BRDF] = load_fred(filepath);

[S, I, Az, Rz] = fred_frame_to_zemax(Pi, Ai, Ps, As);




% NOT YET VALIDATED, BUT ON SURFACE NO BUGS:
[S, I, Az, Rz, BRDF] = interpolate_zemax(S, I, Az, Rz, BRDF, dAz, dRz, ISOTROPIC);



% Write to BSDF file:
filepath = 'C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\zemax\test.bsdf';
write_zemax(S, I, Az, Rz, BRDF, filepath);








