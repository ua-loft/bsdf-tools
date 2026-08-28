
clearvars, clc, close all

Ivec = [10, 30, 50, 70]; % [deg] incident angle
folder = "AnoBlackEC1Aluminum__fromCasey20260629"; 
    % folder containing SPEOS output files

% Load data from SPEOS simulation:
nI = length(Ivec);
x = zeros(1296, nI);
y = zeros(1296, nI);
value = zeros(1296, nI);
for Ii = 1:nI
    I = Ivec(Ii);
    filename = sprintf(folder + "/%idegrees.Intensity.1.txt", I);
    data = readmatrix(filename);
    x(:, Ii) = data(:, 1);
    y(:, Ii) = data(:, 2);
    value(:, Ii) = data(:, 3);
end

% General processing:

theta_i = Ivec; % [deg] polar angle
r_proj_xy = sqrt(x.^2 + y.^2);
r = max(r_proj_xy);
x = x ./ r; % unit sphere
y = y ./ r;

% z = sqrt(1 - x.^2 - y.^2);
% phi_r = atan2d(y, x); % [deg] azimuth
% theta_r = acosd(z); % [deg] polar angle

theta_r = 90 * sqrt(x.^2 + y.^2); % assume x,y are polar plot image
phi_r = atan2d(-x, y);

% Plot raw data:
figure
t1 = tiledlayout(2, 2);
for Ii = 1:nI
    ax = nexttile;
    x_unique = unique(x(:, Ii));
    y_unique = unique(y(:, Ii));
    [Xg,Yg] = meshgrid(x_unique, y_unique);
    Zimg = griddata(x(:, Ii), y(:, Ii), value(:, Ii), Xg, Yg);
    imagesc(x_unique, y_unique, Zimg)
    axis xy
    colorbar
    xlabel('x')
    ylabel('y')
    hcb = colorbar;
    ylabel(hcb, 'value')
    axis equal
    colormap jet
    subtitle(sprintf('AOI = %i', Ivec(Ii)))
end

% =========================================================================
% Process Speos output into inferred BRDF values:

A_det = 1;
P_inc = 1; % [W], total incident power in simulation was set to 1 W
P_det = value; % [W], it seems the Speos units is "total power hitting detector"

% dphi_r = 5; % [deg] spacing of pixels in SPEOS
% dtheta_r = 5; % [deg] spacing of pixels in SPEOS
% dcostheta_r = abs(cosd(theta_r + dtheta_r/2) - cosd(theta_r - dtheta_r/2));
% Omega = dphi_r * dcostheta_r * pi/180; % [sr] solid angle

% domega_i = sind(theta_i) * dtheta_i * dphi_i; % [sr] solid angle
const = 1;
domega_i = sind(theta_i) * const;
dOmega_i = cosd(theta_i) .* domega_i;

% BRDF = P_det ./ (P_inc .* cosd(theta_i));

% dE = L * cos(theta) * domega
% E = L * cos(theta) * omega
% L = E / (cos(theta) * omega)
% so... assuming:
domega_r = sind(theta_r) * const;
E_r = value;
dL_r = E_r ./ (cosd(theta_r) .* domega_r);

L_i = 1;
% dL_r = value ./ dOmega_r;
BRDF = dL_r ./ (L_i * dOmega_i);
% BRDF = value .* sind(theta_r) ./ (L_i * cosd(theta_i) .* sind(theta_i));





% BRDF = value ./ (pi * cosd(theta_r)); % if speos is relative reflectance




% Speos is power. From Max thesis,
%   RT / cos(theta_r) = P_r / P_i, where P is power
%   BRDF = RT / (pi cos(theta_r) )
%   --> BRDF = P_r * cos(theta_r) / (P_i pi cos(theta_r) )
% BRDF = value .* cosd(theta_r) ./ (pi * cosd(theta_r));
% BRDF = value / pi;








% =========================================================================
% Plot BRDF data:
figure
t2 = tiledlayout(2, 2);
for Ii = 1:nI
    ax = nexttile;
    x_unique = unique(x(:, Ii));
    y_unique = unique(y(:, Ii));
    [Xg,Yg] = meshgrid(x_unique, y_unique);
    Zimg = griddata(x(:, Ii), y(:, Ii), BRDF(:, Ii), Xg, Yg);
    imagesc(x_unique, y_unique, Zimg)
    axis xy
    colorbar
    xlabel('x')
    ylabel('y')
    hcb = colorbar;
    ylabel(hcb, 'value')
    axis equal
    colormap jet
    subtitle(sprintf('AOI = %i', Ivec(Ii)))
end

