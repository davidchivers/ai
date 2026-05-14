function make_re_extension_figures()
% Build paper-style figures for the standalone RE extension section.

this_file = mfilename('fullpath');
section_dir = fileparts(this_file);
extension_dir = fileparts(section_dir);
fig_dir = fullfile(section_dir, 'figures');

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

lambda_data = load(fullfile(extension_dir, 'transition_re_lambda_continuation_results.mat'));
lambda_summary = readtable(fullfile(extension_dir, 'transition_re_lambda_continuation_summary.csv'), 'TextType', 'string');

candidate_data = load(fullfile(extension_dir, 'transition_re_candidate_selection_results.mat'));

make_lambda_figure(lambda_data, lambda_summary, fig_dir);
make_solver_comparison_figure(candidate_data, fig_dir);
make_benchmark_overlay_figure(section_dir, lambda_data, fig_dir);
end

function make_lambda_figure(lambda_data, lambda_summary, fig_dir)
details = lambda_data.detailed_results;
raw_results = lambda_data.raw_results;

selected_lambdas = [0.0, 0.5, 1.0];
selected_idx = zeros(size(selected_lambdas));
for i = 1:numel(selected_lambdas)
    selected_idx(i) = find(abs([raw_results.lambda] - selected_lambdas(i)) < 1e-10, 1, 'first');
end

T = numel(details{selected_idx(1)}.final_price_path);
years = (2010:(2010 + T - 1))';
price_reference = 2.0;

colors = [0.09 0.32 0.54; 0.78 0.31 0.14; 0.18 0.49 0.28];
line_styles = {'-', '--', '-.'};

fig = figure( ...
    'Color', 'w', ...
    'Position', [100 100 1100 430], ...
    'Visible', 'off', ...
    'ToolBar', 'none', ...
    'MenuBar', 'none');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile;
hold on;
for i = 1:numel(selected_idx)
    path = details{selected_idx(i)}.final_price_path(:);
    plot(years, 100 .* log(path ./ price_reference), ...
        'Color', colors(i, :), 'LineStyle', line_styles{i});
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
xline(2012, ':', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.0);
xlabel('Year');
ylabel('Log deviation from baseline price level (%)');
title('(a) Price path continuation');
lgd = legend({'\lambda = 0', '\lambda = 0.5', '\lambda = 1.0'}, ...
    'Location', 'northwest', 'Box', 'off', 'FontSize', 10);
lgd.Color = 'white';
lgd.TextColor = [0.1 0.1 0.1];
apply_paper_axes(ax1);

ax2 = nexttile;
yyaxis left;
plot(lambda_summary.lambda, lambda_summary.residual_norm, '-o', 'LineWidth', 2.0, ...
    'Color', [0.12 0.36 0.62], 'MarkerFaceColor', [0.12 0.36 0.62], 'MarkerSize', 6);
ylabel('Residual norm');

yyaxis right;
plot(lambda_summary.lambda, lambda_summary.max_abs_gap, '-s', 'LineWidth', 2.0, ...
    'Color', [0.75 0.25 0.15], 'MarkerFaceColor', [0.75 0.25 0.15], 'MarkerSize', 6);
ylabel('Max absolute gap');
xlabel('\lambda');
title('(b) Continuation diagnostics');
apply_paper_axes(ax2);
xticks(lambda_summary.lambda);

exportgraphics(fig, fullfile(fig_dir, 're_lambda_continuation.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(fig, fullfile(fig_dir, 're_lambda_continuation.png'), 'Resolution', 300, 'BackgroundColor', 'white');
close(fig);
end

function make_solver_comparison_figure(candidate_data, fig_dir)
raw_results = candidate_data.raw_results;
details = candidate_data.detailed_results;

control_idx = find(strcmp(string({raw_results.case_name}), "config11_global_control"), 1, 'first');
challenger_idx = find(strcmp(string({raw_results.case_name}), "aggressive_p2_b8_hybrid_relaxed"), 1, 'first');

control = details{control_idx};
challenger = details{challenger_idx};

T = numel(control.final_price_path);
years = (2010:(2010 + T - 1))';
price_reference = 2.0;

fig = figure( ...
    'Color', 'w', ...
    'Position', [100 100 1100 430], ...
    'Visible', 'off', ...
    'ToolBar', 'none', ...
    'MenuBar', 'none');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile;
hold on;
plot(years, 100 .* log(control.final_price_path(:) ./ price_reference), '-', ...
    'Color', [0.13 0.36 0.58]);
plot(years, 100 .* log(challenger.final_price_path(:) ./ price_reference), '--', ...
    'Color', [0.76 0.32 0.14]);
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
xline(2012, ':', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.0);
xlabel('Year');
ylabel('Log deviation from baseline price level (%)');
title('(a) Benchmark and challenger RE paths');
lgd = legend({'Benchmark RE control', 'Relaxed hybrid challenger'}, ...
    'Location', 'northwest', 'Box', 'off', 'FontSize', 10);
lgd.Color = 'white';
lgd.TextColor = [0.1 0.1 0.1];
apply_paper_axes(ax1);

ax2 = nexttile;
hold on;
plot(years, 100 .* control.log_price_residual_raw(:), '-', ...
    'Color', [0.13 0.36 0.58]);
plot(years, 100 .* challenger.log_price_residual_raw(:), '--', ...
    'Color', [0.76 0.32 0.14]);
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
xline(2012, ':', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.0);
xlabel('Year');
ylabel('Raw log-price residual (%)');
title('(b) Residual localization under RE');
lgd = legend({'Benchmark RE control', 'Relaxed hybrid challenger'}, ...
    'Location', 'southwest', 'Box', 'off', 'FontSize', 10);
lgd.Color = 'white';
lgd.TextColor = [0.1 0.1 0.1];
apply_paper_axes(ax2);

exportgraphics(fig, fullfile(fig_dir, 're_solver_comparison.pdf'), 'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(fig, fullfile(fig_dir, 're_solver_comparison.png'), 'Resolution', 300, 'BackgroundColor', 'white');
close(fig);
end

function make_benchmark_overlay_figure(section_dir, lambda_data, fig_dir)
benchmark_tbl = readtable( ...
    fullfile(section_dir, 'digitized_paper_benchmark_2010_2018.csv'), ...
    'TextType', 'string');

raw_results = lambda_data.raw_results;
details = lambda_data.detailed_results;
re_idx = find(abs([raw_results.lambda] - 1.0) < 1e-10, 1, 'first');
re_path = details{re_idx}.final_price_path(:);

years = benchmark_tbl.year(:);
benchmark_price = benchmark_tbl.benchmark_price_digitized(:);
re_years = (2010:(2010 + numel(re_path) - 1))';

benchmark_log_change = 100 .* log(benchmark_price ./ benchmark_price(1));
re_log_change = 100 .* log(re_path ./ re_path(1));

fig = figure( ...
    'Color', 'w', ...
    'Position', [100 100 780 430], ...
    'Visible', 'off', ...
    'ToolBar', 'none', ...
    'MenuBar', 'none');

ax = axes(fig);
hold(ax, 'on');
plot(ax, years, benchmark_log_change, '-', ...
    'Color', [0.10 0.10 0.10], 'LineWidth', 2.4);
plot(ax, re_years, re_log_change, '--', ...
    'Color', [0.74 0.29 0.12], 'LineWidth', 2.2);
yline(ax, 0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
xline(ax, 2013, ':', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.0);
xlim(ax, [2010 2018]);
xticks(ax, years);
xlabel(ax, 'Year');
ylabel(ax, 'Log change since 2010 (%)');
title(ax, '(c) Published benchmark versus RE extension');
lgd = legend(ax, ...
    {'Published benchmark (digitized)', 'Full-shock RE extension'}, ...
    'Location', 'northwest', 'Box', 'off', 'FontSize', 10);
lgd.Color = 'white';
lgd.TextColor = [0.1 0.1 0.1];
apply_paper_axes(ax);

exportgraphics(fig, fullfile(fig_dir, 're_vs_paper_benchmark.pdf'), ...
    'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(fig, fullfile(fig_dir, 're_vs_paper_benchmark.png'), ...
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
