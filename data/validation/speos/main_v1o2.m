
clearvars, clc, close all

XY_ARE_GLOBAL = false; % false means speos output is polar plot
theta_r_limit = 80; % [deg] upper limit (<=) for theta_r in polar plot
SAVE_FIG = false;
save_name = "C:\Users\jakep\Documents\Optics_github\UofA\LOFT\SPIE_OP_2026\figs\speos_sim\v1o0_autosave.png";

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

% Assume x,y same for all Ivec:
if all(x(:, 1) == x(:, 2)) ...
&& all(x(:, 1) == x(:, 3)) ...
&& all(x(:, 1) == x(:, 4))
    x = x(:, 1);
else
    error("Not all same. Manually adjust processing.")
end
if all(y(:, 1) == y(:, 2)) ...
&& all(y(:, 1) == y(:, 3)) ...
&& all(y(:, 1) == y(:, 4))
    y = y(:, 1);
else
    error("Not all same. Manually adjust processing.")
end

% General processing:

theta_i = Ivec; % [deg] polar angle

x_radius = (max(x(:)) - min(x(:))) / 2;
y_radius = (max(y(:)) - min(y(:))) / 2;
radius = (x_radius + y_radius) / 2;
x = x ./ radius; % unit sphere
y = y ./ radius;
r = x.^2 + y.^2;
m = r <= 1; % mask keep

x = x(m);
y = y(m);
value = value(m, :);

if XY_ARE_GLOBAL
    z = sqrt(1 - x.^2 - y.^2);
    theta_r = acosd(z); % [deg] polar angle
    phi_r = atan2d(-x, y); % [deg] azimuth
else % then assume x,y are polar plot image
    theta_r = 90 * sqrt(x.^2 + y.^2);
    phi_r = atan2d(-x, y);
end

m = theta_r <= theta_r_limit;
theta_r = theta_r(m);
phi_r = phi_r(m);
x = x(m);
y = y(m);
value = value(m, :);

P_inc = 1; % [W] total incident power, known speos simulation parameter
I_r = value; % [W/sr] measured/simulated intensity on detector/pixels
BRDF_speos = I_r ./ (P_inc * cosd(theta_r));
    % derived from (in Nicodemus nomenclature):
    % f_r = L_r / E_i
    % E_i = P_inc / A_s = P_inc / (A_beam/cos(theta_i))
    % dPhi_r = L_r cos(theta_r) A_s dOmega_r
    %      --> L_r = dPhi_r / (cos(theta_r) (A_beam/cos(theta_i)) dOmega_r)
    % --> L_r / E_i = [ dPhi_r / (cos(theta_r) (A_beam/cos(theta_i)) ...
    %               ... dOmega_r) ] / [ P_inc / (A_beam/cos(theta_i)) ]
    %               = dPhi_r / (P_inc cos(theta_r) dOmega_r)
    % And, by definition of radiant intensity I_r == dPhi_r / dOmega_r,
    % --> f_r = I_r / (P_inc cos(theta_r))
    % 
    % So, since "value / cosd(theta_i)" empirically gives peak values
    % closest to known BRDF values, assuming I_r is what speos simulation
    % is outputting.
    % 
    % Therefore, 
    % BRDF_speos = I_r ./ (P_inc * cosd(theta_r));

% Plot:

function plot_speos_polar_heatmap(theta_r, phi_r, BRDF_speos, Ivec, mkr_size)
    if nargin < 5
        mkr_size = 20;
    end

    printable_width = 8.5 - 2*0.875; % in, from letter and SPIE's 0.875" left/right margin
    AR = 0.8;
    want_width = printable_width * 1;
    fig_Position_asInches = [0 0 want_width AR*want_width];
    figure('Units', 'inches', 'Position', fig_Position_asInches, 'Color', 'white');
    set(gcf, 'Color', 'white'); % set figure background to white
    tiledlayout(2, 2, 'TileSpacing', 'compact')

    for Ii = 1:numel(Ivec)
        nexttile
        polarscatter(deg2rad(phi_r), theta_r, mkr_size, BRDF_speos(:, Ii), 'filled')
        title(sprintf('$\\theta_i = %d^{\\circ}$', Ivec(Ii)), 'Interpreter', 'latex')
        rlim([0 90])
        colormap(gca, 'jet')
        cb = colorbar;
        % cb.Label.String = 'BRDF';
        cb.Label.Interpreter = 'latex';
        cb.TickLabelInterpreter = 'latex';
        cb.Limits = [0, max(BRDF_speos(:, Ii))];
        cb.Ticks = linspace(0, max(BRDF_speos(:, Ii)), 10);
        ax = gca;
        ax.ThetaZeroLocation = 'top';
        ax.ThetaDir = 'counterclockwise';
        
        % Make radial grid:
        hold on
        ax.RTick = 0:10:90;
        ax.RGrid = 'off';
        hold(ax, 'on')
        th_full = linspace(0, 2*pi, 200);
        gray_color = 0 * [1 1 1];
        for rt = ax.RTick(2:end)   % skip r=0
            polarplot(ax, th_full, rt*ones(size(th_full)), 'Color', gray_color, 'LineWidth', 0.75)
        end
        ax.RTickLabel = {'$0^{\circ}$', '$10^{\circ}$', '$20^{\circ}$', '$30^{\circ}$', '$40^{\circ}$', '$50^{\circ}$', '$60^{\circ}$', '$70^{\circ}$', '$80^{\circ}$', '$90^{\circ}$'};
        ax.TickLabelInterpreter = 'latex';
        ax.RColor = gray_color;
        ax.ThetaTickLabel = {};
        hold off

    end
end

plot_speos_polar_heatmap(theta_r, phi_r, BRDF_speos, Ivec, 20)

% Save figure:
if SAVE_FIG
    drawnow
    exportgraphics(gcf, save_name, 'Resolution', 600, ...
        'BackgroundColor', 'white', 'ContentType', 'vector')
end

