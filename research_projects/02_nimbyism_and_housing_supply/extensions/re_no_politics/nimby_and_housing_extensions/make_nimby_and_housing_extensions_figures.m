function make_nimby_and_housing_extensions_figures()
% Build paper-style figures for the combined RE and coalition extensions note.

this_file = mfilename('fullpath');
this_dir = fileparts(this_file);
extension_dir = fileparts(this_dir);
fig_dir = fullfile(this_dir, 'figures');
re_section_dir = fullfile(extension_dir, 're_extension_section');

if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
set(groot, 'defaultFigureColor', 'w');
set(groot, 'defaultAxesColor', 'w');
set(groot, 'defaultAxesXColor', [0.1 0.1 0.1]);
set(groot, 'defaultAxesYColor', [0.1 0.1 0.1]);
set(groot, 'defaultTextColor', [0.1 0.1 0.1]);
set(groot, 'defaultAxesGridColor', [0.82 0.84 0.88]);
set(groot, 'defaultAxesGridAlpha', 0.7);
set(groot, 'defaultAxesMinorGridColor', [0.9 0.91 0.93]);
set(groot, 'defaultAxesMinorGridAlpha', 0.5);
set(groot, 'defaultLineLineWidth', 2.2);

addpath(re_section_dir);
make_re_extension_figures();

coalition_data = load(fullfile(extension_dir, 'coalition_benchmark_results.mat'));
coalition_summary = readtable(fullfile(extension_dir, 'coalition_benchmark_summary.csv'), 'TextType', 'string');

make_coalition_figure(coalition_data, coalition_summary, fig_dir);
end

function make_coalition_figure(coalition_data, coalition_summary, fig_dir)
raw_results = coalition_data.raw_results;
detailed_results = coalition_data.detailed_results;

benchmark_row = coalition_summary(coalition_summary.case_name == "benchmark_equal_weight", :);
plot_rows = coalition_summary(ismember(coalition_summary.case_name, ...
    ["owner_only", "old_owner_only", "leveraged_owner_only", "big_house_only", "combined_default"]), :);

price_shift_pct = 100 .* plot_rows.benchmark_price_diff ./ benchmark_row.best_price(1);

case_names = categorical( ...
    cellstr(plot_rows.case_name), ...
    {'owner_only', 'old_owner_only', 'leveraged_owner_only', 'big_house_only', 'combined_default'}, ...
    {'Owner', 'Old owner', 'Leveraged owner', 'Big house', 'Combined'});

benchmark_idx = find(strcmp(string({raw_results.case_name}), "benchmark_equal_weight"), 1, 'first');
combined_idx = find(strcmp(string({raw_results.case_name}), "combined_default"), 1, 'first');

benchmark_detail = detailed_results{benchmark_idx};
combined_detail = detailed_results{combined_idx};

price_grid = benchmark_detail.grid_meta.X1(:);
benchmark_distance = benchmark_detail.grid_results(1, :)';
combined_distance = combined_detail.grid_results(1, :)';

benchmark_price = raw_results(benchmark_idx).best_price;
combined_price = raw_results(combined_idx).best_price;

fig = figure( ...
    'Color', 'w', ...
    'Position', [100 100 1100 430], ...
    'Visible', 'off', ...
    'ToolBar', 'none', ...
    'MenuBar', 'none');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile;
bar_colors = [ ...
    0.74 0.33 0.18
    0.63 0.40 0.19
    0.55 0.57 0.61
    0.34 0.53 0.63
    0.12 0.44 0.36];
bh = bar(ax1, case_names, price_shift_pct, 0.62, 'FaceColor', 'flat', 'EdgeColor', 'none');
bh.CData = bar_colors;
hold(ax1, 'on');
yline(ax1, 0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
ylabel(ax1, 'Equilibrium price shift vs benchmark (%)');
title(ax1, '(a) Coalition-weighted price shifts');
apply_paper_axes(ax1);

ax2 = nexttile;
hold(ax2, 'on');
plot(ax2, price_grid, benchmark_distance, '-', 'Color', [0.12 0.12 0.12]);
plot(ax2, price_grid, combined_distance, '--', 'Color', [0.74 0.33 0.18]);
xline(ax2, benchmark_price, ':', 'Color', [0.12 0.12 0.12], 'LineWidth', 1.0);
xline(ax2, combined_price, ':', 'Color', [0.74 0.33 0.18], 'LineWidth', 1.0);
xlabel(ax2, 'House price');
ylabel(ax2, 'Distance objective');
title(ax2, '(b) Benchmark and combined coalition objectives');
lgd = legend(ax2, {'Benchmark equal weight', 'Combined coalition'}, ...
    'Location', 'northeast', 'Box', 'off', 'FontSize', 10);
lgd.Color = 'white';
lgd.TextColor = [0.1 0.1 0.1];
apply_paper_axes(ax2);

exportgraphics(fig, fullfile(fig_dir, 'coalition_extension.pdf'), ...
    'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(fig, fullfile(fig_dir, 'coalition_extension.png'), ...
    'Resolution', 300, 'BackgroundColor', 'white');
close(fig);
end

function apply_paper_axes(ax)
ax.Color = 'white';
ax.FontSize = 11;
ax.LineWidth = 0.9;
ax.XColor = [0.12 0.12 0.12];
ax.YColor = [0.12 0.12 0.12];
ax.GridColor = [0.82 0.84 0.88];
ax.GridAlpha = 0.7;
ax.MinorGridColor = [0.9 0.91 0.93];
ax.MinorGridAlpha = 0.5;
ax.Box = 'off';
ax.Layer = 'top';
grid(ax, 'on');
grid(ax, 'minor');
end
