

% Validation test of applying Blacklab's small FOV for VNIR radiometer, to
% 3"x6" samples; in comparison to large FOV (which is used for 12"x12").
% Copied 2026/09/25 from v1.1, which was used to make SPIE O+P 2026 plot.



% JPK
% v1.0 2026/07/19 - draft figures;
% v1.1 08/05 - better figure formatting;
% v1.2 09/25 - validation check of small FOV (just changing the 3x6in file)

% Plotting Blacklab data for SPIE BRDF manuscript.

% =========

clc, clearvars, close all

% Load data:

% FORMAT: filepaths = {12x12, 3x6 (large FOV), 3x6 (small FOV)};
filepaths = {"C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\blacklab\lazuli\control_set\AnoBlateNiTE_on_INVAR36_12x12in\vnir\20260706\20260706_AnoBlateNiTE_on_INVAR36_12x12in_sample.txt", ...
    "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\blacklab\lazuli\control_set\AnoBlackNiTE_on_INVAR36_3x6in\vnir\20260715\20260715_AnoBlackNiTE_on_INVAR36_3x6in_sample.txt", ...
             "C:\Users\jakep\Documents\Optics_local\UofA\bsdf-tools\data\raw\blacklab\lazuli\control_set\AnoBlackNiTE_on_INVAR36_3x6in\vnir\20260909_LOFT_Anoblack_NITE_3x6_smallFOV\20260909_LOFT_Anoblack_NITE_3x6_smallFOV_sample.txt"};

nk = length(filepaths);
data = cell(nk, 1);
nBRF = 114; % number of datapoints per sample
src_z = nan(nBRF, nk);
src_a = nan(nBRF, nk);
view_z = nan(nBRF, nk);
view_a = nan(nBRF, nk);
BRF_385nm = nan(nBRF, nk);
% BRF_631nm = nan(nBRF, nk);
BRF_1061nm = nan(nBRF, nk);

for k = 1:nk
    filepath = filepaths{k};
    data{k, 1} = readmatrix(filepath);
    
    % Parse data:
    src_z(:, k) = data{k, 1}(:, 1);
    src_a(:, k) = data{k, 1}(:, 2);
    view_z(:, k) = data{k, 1}(:, 3);
    view_a(:, k) = data{k, 1}(:, 4);
    BRF_385nm(:, k) = data{k, 1}(:, 5);
    % % BRF_631nm(:, k) = data{k, 1}(:, 6);
    % if strcmp(data_filenames{k}, "20260706_Aeroglaze_9929Primer_Z307Black_on_Al6061T6_sample.txt") % if aeroglaze on aluminum then need to skip 632nm measurements
    %     BRF_1061nm(:, k) = data{k, 1}(:, 7);
    % else
        BRF_1061nm(:, k) = data{k, 1}(:, 6);
    % end

end

% Other:
AOIs = [10 30 50 70];

% As Nicodemus convention:
theta_i = src_z;
theta_r = view_z;
phi_r = 180 + view_a;
f_r = cell(2, 1);
f_r{1} = BRF_385nm / pi;
f_r{2} = BRF_1061nm / pi;

% Set phi_r to 0 and let theta_r be negative:
phi_r(abs(phi_r - 360) < 1e-3) = 0;
m = abs(phi_r - 180) < 1e-3;
theta_r(m) = -theta_r(m);
phi_r(m) = 0;





%% FIGURE: BRDF comparison across 12x12 and 3x6 mounting configurations

% Round data from outside of plot bounds:
k = 2;
m = and(theta_r(:, k) == 50, theta_i(:, k) == 50);
f_r{1}(m, k) = 0.42; % set 0.420201 to 0.42

fig_v = 1; % version of figures (for naming saved png)
fs_title = 11; %16;
fs_legend = 9; %10;
fs_subtitle = 11; %12;
fs_label = 11; %10;
fs_ylabel = 11; %12;
fs_xlabel = 11; %12;
fs_ticks = 11;
AR = 0.5; % height / width
npix = 500;
fig_Position_2x2 = [1   1   npix   AR*npix]; % as pixels
fig_Position_traces = [1   1   500   500]; % as pixels
fig_Position_map = [0 0 0 0]; % as pixels
line_width = 1.0;
markers = ["^", "v", ">", "<", "diamond"];
mkr_size = 3; % marker size

printable_width = 8.5 - 2*0.875; % in, from letter and SPIE's 0.875" left/right margin
fig_Position_2x2_asInches = [0 0 printable_width AR*printable_width];

colors = orderedcolors("gem");

line_styles     = {'-', ':', '-.'}; % {12x12, 3x6 (large FOV), 3x6 (small FOV)}
lambdas = [385 1061];
n_lambdas = length(lambdas);

SAVE_FIG = true;
save_name = "blacklab_validation_of_VNIR_small_FOV_for_3x6in_mount.png";

% ==========
% ==========

% Init figure:
fig = figure('Units', 'inches', 'Position', fig_Position_2x2_asInches, 'Color', 'white');
t = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'none');
% title(t, "Comparison of $12^{\prime\prime}\times12^{\prime\prime}$ and $3^{\prime\prime}\times6^{\prime\prime}$ Blacklab mounts (NiTE on INVAR)", ...
%     'Interpreter', 'latex', 'FontSize', fs_title);
set(gcf, 'Color', 'white'); % set figure background to white

% Plot:

ax_num = 0;
for w = 1:n_lambdas % wavelength index
    ax_num = ax_num + 1;
    ax = nexttile;
    % axis(ax, 'tight')
    hold(ax, 'on')

    k_ls = 0; % linestyle index
    for k = 1:nk % [1 2 3] % sample indices of 12x12, 3x6 (large FOV), 3x6 (small FOV)
        k_ls = k_ls + 1;

        AOI_id = 0;
        for AOI = AOIs   % angle of incidence, one panel per AOI
            AOI_id = AOI_id + 1;

            mask_aoi = abs(src_z(:, k) - AOI) < 1e-6;

            if AOI == 70
                yyaxis right
            else
                yyaxis left
            end

            plot(theta_r(mask_aoi), f_r{w}(mask_aoi, k), ...
                'Color', colors(AOI_id, :), 'LineStyle', line_styles{k_ls}, 'LineWidth', line_width, ...
                'Marker', markers(AOI_id), 'MarkerSize', mkr_size, 'MarkerFaceColor', colors(AOI_id, :), 'MarkerEdgeColor', colors(AOI_id, :));
        end
    end

    yyaxis left

    hold(ax, 'off')
    grid(ax, 'on')
    set(ax, 'TickLabelInterpreter', 'latex')
        set(ax, 'Box', 'on')  % Adds border around the axes
        set(ax, 'XMinorTick', 'on', 'YMinorTick', 'on', ...
            'XMinorGrid', 'on', 'YMinorGrid', 'on')

    % % Add labels if, and remove axis numbers if not, the left-most or bottom-most:
    % if any(ax_num == [1 3])
    %     % ylabel(ax, "BRDF", "Interpreter", "latex", ...
    %     %     'FontSize', fs_ylabel)
    % else
    %     set(ax, 'YTickLabel', [])
    % end
    % if any(ax_num == [3 4])
    %     % xlabel(ax, "$\theta_s$ [deg]", "Interpreter", "latex", ...
    %     %     'FontSize', fs_xlabel)
    % else
        % set(ax, 'XTickLabel', [])
    % end
    
    subtitle(sprintf("$\\lambda = %i \\mathrm{nm}$", lambdas(w)), "Interpreter", "latex", ...
        'FontSize', fs_subtitle)
    
    % y_limits = ylim;
    % ylim(ax, [0 y_limits(2)])
    xlim(ax, [-90 90])

    xticks(-90 : 30 : 90)
    xticklabels({"-$90^{\circ}$", "-$60^{\circ}$", "-$30^{\circ}$", "$0^{\circ}$", "$30^{\circ}$", "$60^{\circ}$", "$90^{\circ}$"})

    if w == 1
        % ylim(ax, [0 0.42]) % left
        % yticks( linspace(0, 0.42, 7) )
        % ax.YAxis(1).MinorTickValues = linspace(0, 0.42, 13);
        ylim(ax, [0 0.6]) % left
        yticks( linspace(0, 0.6, 7) )
        ax.YAxis(1).MinorTickValues = linspace(0, 0.6, 13);
        yyaxis right
        ylim(ax, [0 2.4]) % right
        yticks( linspace(0, 2.4, 7) )
        ax.YAxis(2).MinorTickValues = linspace(0, 2.4, 13);
    elseif w ==2
        ylim(ax, [0 0.6]) % left
        yticks( linspace(0, 0.6, 7) )
        ax.YAxis(1).MinorTickValues = linspace(0, 0.6, 13);
        yyaxis right
        % ylim(ax, [0 1.8]) % right
        % yticks( linspace(0, 1.8, 7) )
        % ax.YAxis(2).MinorTickValues = linspace(0, 1.8, 13);
        ylim(ax, [0 2.4]) % right
        yticks( linspace(0, 2.4, 7) )
        ax.YAxis(2).MinorTickValues = linspace(0, 2.4, 13);
    end
    yyaxis left

    ax.XAxis.MinorTickValues = -90 : 10 : 90;

    ax.YAxis(1).Color = 'k';
    ax.YAxis(2).Color = 'k';

    % if w == 1
        ax.YAxis(2).TickLabels = {'0', '0.4', '0.8', '1.2', '1.6', '2.0', '2.4\ \ \'};
    % end

    set(ax, 'XMinorTick', 'on', 'YMinorTick', 'on');
    set(ax, 'XMinorGrid', 'on', 'YMinorGrid', 'on')
    yyaxis right
    set(ax, 'XMinorTick', 'on', 'YMinorTick', 'on');
    yyaxis left

end

hold on
% for k = 1:nk
    for AOI_id = 1:4
        plot([-200 -199], [-100 -100], 'Color', colors(AOI_id, :), 'LineStyle', '-', 'LineWidth', line_width, 'Marker', markers(AOI_id), 'MarkerSize', mkr_size, 'MarkerFaceColor', colors(AOI_id, :), 'MarkerEdgeColor', colors(AOI_id, :))
    end
% end
plot([-200 -199], [-100 -100], 'k-', 'LineWidth', line_width, 'Marker', 'none')
plot([-200 -199], [-100 -100], 'k:', 'LineWidth', line_width, 'Marker', 'none')
plot([-200 -199], [-100 -100], 'k-.', 'LineWidth', line_width, 'Marker', 'none')
hold off
% l1 = legend(ax, "", "", "", "", "", "", ...
%                 "$\theta_i = 10^{\circ}$", "$30^{\circ}$", "$50^{\circ}$", "$70^{\circ}$ (right y-axis)", ...
%                 "$12^{\prime\prime}\times12^{\prime\prime}$", "$3^{\prime\prime}\times6^{\prime\prime}$");

% l1 = legend(ax, "", "", "", "", "", "", ...
%                 "$\theta_i = 10^{\circ}$\hspace{10pt}", "$30^{\circ}$\hspace{10pt}", "$50^{\circ}$\hspace{10pt}", "$70^{\circ}$ (right y-axis)\hspace{10pt}", ...
%                 "$12^{\prime\prime}\times12^{\prime\prime}$\hspace{10pt}", "$3^{\prime\prime}\times6^{\prime\prime}\\ \text{(large FOV)}$\hspace{10pt}", "$3^{\prime\prime}\times6^{\prime\prime}\\ \text{(small FOV)}$\hspace{10pt}");


% l1 = legend(ax, "", "", "", "", "", "", "", "", "", ... % "" times 3 (because 4 AOI minus the 1 on the right y-axis) times nk
%                 "$\theta_i = 10^{\circ}$\hspace{10pt}", "$30^{\circ}$\hspace{10pt}", "$50^{\circ}$\hspace{10pt}", "$70^{\circ}$ (right y-axis)\hspace{10pt}", ...
%                 "$12^{\prime\prime}\times12^{\prime\prime}$\hspace{10pt}", "$3^{\prime\prime}\times6^{\prime\prime}\\ \text{(large FOV)}$", "$3^{\prime\prime}\times6^{\prime\prime}\\ \text{(small FOV)}$");

l1 = legend(ax, "", "", "", "", "", "", "", "", "", ... % "" times 3 (because 4 AOI minus the 1 on the right y-axis) times nk
                "$\theta_i = 10^{\circ}$\hspace{10pt}", "$30^{\circ}$\hspace{10pt}", "$50^{\circ}$\hspace{10pt}", "$70^{\circ}$ (right y-axis)\hspace{10pt}", ...
                "$12^{\prime\prime}\times12^{\prime\prime}$\hspace{10pt}", "$3^{\prime\prime}\times6^{\prime\prime}$\hspace{10pt}", "$3^{\prime\prime}\times6^{\prime\prime}$ (small FOV)");




l1.Interpreter = 'latex';
l1.Box = 'off'; % optional, for cleaner look
l1.Layout.Tile = "north"; % places it above all tiles
l1.Orientation = 'horizontal';
% l1.NumColumns = 6;  % spread out across width
l1.ItemTokenSize = [14, 2];  % tighten spacing between marker and label
l1.FontSize = fs_legend;  % slightly smaller for compactness

xlabel(t, "$\theta_r$, at $|\phi_r - \phi_i| = 180^{\circ}$", "Interpreter", "latex", ...
            'FontSize', fs_xlabel);
       t.XLabel.VerticalAlignment = 'top';
       % t.XLabel.FontSize = fs_xlabel;
ylabel(t, "BRDF,\ $f_r$", "Interpreter", "latex", ...
            'FontSize', fs_ylabel);
   t.YLabel.VerticalAlignment = 'bottom';
%    % t.YLabel.FontSize = fs_ylabel;
t.Title.VerticalAlignment = 'bottom';

if SAVE_FIG
    exportgraphics(gcf, save_name, 'Resolution', 600)
end





