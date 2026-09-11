
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








r_proj_xy = sqrt(x.^2 + y.^2);
r = max(r_proj_xy);
x = x ./ r; % unit sphere
y = y ./ r;
z = sqrt(1 - x.^2 - y.^2);
phi = atan2d(y, x); % [deg] azimuth
theta = acosd(z); % [deg] polar angle

A_det = 1;
% r = sqrt(x(1, 1)^2 + y(1, 1)^2); % assume first entry gives radius of hemisphere
theta_s = theta; % asind(sqrt(x.^2 + y.^2));
theta_i = Ivec; % (Ii);
P_inc = 1; % [W]

P_det = value;
Omega_det = 1; % A_det .* cosd(theta_s) ./ r.^2;
% BRDF_est = P_det ./ (P_inc .* cosd(theta_i) .* Omega_det);
% BRDF_est = value ./ cosd(theta_s);

% BRDF_est = value;









% r_proj_xy = sqrt(x.^2 + y.^2);
% r = max(r_proj_xy);
% x = x ./ r; % unit sphere
% y = y ./ r;
% z = sqrt(1 - x.^2 - y.^2);
% phi = atan2d(y, x); % [deg] azimuth
% theta = acos(z); % [deg] polar angle
dphi = 5; % [deg] spacing of pixels in SPEOS
dtheta = 5; % [deg] spacing of pixels in SPEOS
dcostheta = abs(cosd(theta + dtheta/2) - cosd(theta - dtheta/2));
Omega = dphi * dcostheta * pi/180; % [sr] solid angle

% BRDF_est = BRDF_est .* Omega;
% BRDF_est = P_det ./ (P_inc .* cosd(theta_i) .* Omega);
BRDF_est = P_det ./ (P_inc .* cosd(theta_i));
% BRDF_est = P_det .* cosd(theta_s) ./ (P_inc .* cosd(theta_i));







peak_values_BRDF = [0.0348, 0.0420, 0.1407, 1.6020]; % from Zemax BSDF file
scales = zeros(1, nI);
for Ii = 1:nI
    % scales(Ii) = peak_values_BRDF(Ii) / max(value(:, Ii));
    scales(Ii) = peak_values_BRDF(Ii) / max(BRDF_est(:, Ii));
    % BRDF_est(:, Ii) = BRDF_est(:, Ii) * scales(Ii);
end
scales

















for Ii = 1:nI

    % Visualize:
    fig = figure;
    % scatter3(x(:, 2), y(:, 2), value(:, 2))
    % imagesc([x(:, 2), y(:, 2), value(:, 2)])

    x_unique = unique(x(:, Ii));
    y_unique = unique(y(:, Ii));
    [Xg,Yg] = meshgrid(x_unique, y_unique);
    % Zimg = griddata(x(:, Ii), y(:, Ii), value(:, Ii), Xg, Yg);
    Zimg = griddata(x(:, Ii), y(:, Ii), BRDF_est(:, Ii), Xg, Yg);
    imagesc(x_unique, y_unique, Zimg)
    axis xy
    colorbar
    xlabel('x')
    ylabel('y')
    hcb = colorbar;
    ylabel(hcb, 'value')
    axis equal
    colormap jet

end
















