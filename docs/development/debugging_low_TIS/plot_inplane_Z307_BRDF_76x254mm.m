
% JPK
% 2026/08/11

% Debugging low TIS in Z307.

% =====================

clc, clearvars, close all



filepath_fred = "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\processed\fred\Aeroglaze_9924Primer_Z307Black_onAlum.txt";

[Pi, Ai, Ps, As, BRDF] = load_fred(filepath_fred);

mAi = Ai == 0; % (refers to specular ray; should all be 0 b/c isotropic)

mAiAs0 = and(mAi, As == 0); % (in-plane, specular side)
mAiAs180 = and(mAi, As == 180); % (in-plane, backscatter side)

figure
hold on
grid on
title('Corrected BRDF Data for Aeroglaze Z307 (76.4x254.0mm) [Jacob K, 2026/08/11]')
ylabel('BRDF')
xlabel('Receive Angle [deg]')

colors = [ 68   1  84; ...
           49 104 142; ...
           53 183 121; ...
          253 231  37] / 255;

% Pi_j = unique(Pi);
Pi_j = 10:20:70; % ignore other than these angles

for j = 1:length(Pi_j)

    mPi = Pi == Pi_j(j);

    mAiAs0Pi = and(mAiAs0, mPi);
    mAiAs180Pi = and(mAiAs180, mPi);

    receive_j = [-Ps(mAiAs180Pi); Ps(mAiAs0Pi)];
    BRDF_j = [BRDF(mAiAs180Pi); BRDF(mAiAs0Pi)];

    scatter(receive_j, BRDF_j, [], colors(j, :), 'filled')

end

set(gca, 'YScale', 'log')
pbaspect([605 352 1])
ylim([5e-3, 7e-1])

legend('Incidence 10°', 'Incidence 30°', 'Incidence 50°', 'Incidence 70°', ...
    'Location', 'northwest')

box on


