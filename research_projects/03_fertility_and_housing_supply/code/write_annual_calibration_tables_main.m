function write_annual_calibration_tables_main()
% write_annual_calibration_tables_main.m
%
% Build a single paper-style annual calibration pack:
%   - notes/build/annual_calibration_tables.md
%   - notes/build/annual_calibration_targets_table.csv
%   - notes/build/annual_calibration_parameters_table.csv
%   - drafts/tables/annual_targeted_moments.tex
%   - drafts/tables/annual_calibration_implementation.tex

project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
tables_dir = fullfile(project_root, 'drafts', 'tables');

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
if ~exist(tables_dir, 'dir')
    mkdir(tables_dir);
end

this_code_dir = fullfile(project_root, 'code');
addpath(this_code_dir, '-begin');

cfg = fertility_benchmark_annual_config();
spec = fertility_annual_ownership_balance_sheet_branch_spec();

wealth_csv = fullfile(out_dir, 'scf_wealth_age_target_recent_pool.csv');
if ~exist(wealth_csv, 'file')
    error('SCF wealth target file not found: %s. Run build_scf_wealth_age_target_review.py first.', wealth_csv);
end

fertility_targets = target_ranges_to_table(fertility_annual_target_ranges(), "fertility");
homeownership_targets = target_ranges_to_table(annual_homeownership_target_ranges(), "homeownership");
wealth_targets = readtable(wealth_csv, 'TextType', 'string');
wealth_targets.block = repmat("wealth", height(wealth_targets), 1);
wealth_targets.name = wealth_targets.target_name;

target_table = [ ...
    select_target_columns(fertility_targets); ...
    select_target_columns(homeownership_targets); ...
    select_target_columns(wealth_targets)];
writetable(target_table, fullfile(out_dir, 'annual_calibration_targets_table.csv'));

parameter_table = build_parameter_table(cfg, spec);
writetable(parameter_table, fullfile(out_dir, 'annual_calibration_parameters_table.csv'));

write_markdown(fullfile(out_dir, 'annual_calibration_tables.md'), target_table, parameter_table, spec);
write_target_tex(fullfile(tables_dir, 'annual_targeted_moments.tex'), target_table);
write_parameter_tex(fullfile(tables_dir, 'annual_calibration_implementation.tex'), parameter_table);
end

function out = select_target_columns(tbl)
vars = {'block', 'name', 'role', 'unit', 'reference', 'lower', 'upper', 'source', 'comment', 'model_mapping'};
out = tbl(:, vars);
end

function tbl = target_ranges_to_table(ranges, block_name)
rows = struct('block', {}, 'name', {}, 'role', {}, 'unit', {}, 'reference', {}, 'lower', {}, 'upper', {}, 'source', {}, 'comment', {}, 'model_mapping', {});
fields = {'primary', 'support', 'validation'};

for ifield = 1:numel(fields)
    field_name = fields{ifield};
    if ~isfield(ranges, field_name)
        continue;
    end
    targets = ranges.(field_name);
    if isempty(targets)
        continue;
    end
    if ~isstruct(targets)
        targets = targets(:);
    end
    if numel(targets) == 1
        targets = targets(:);
    end
    for i = 1:numel(targets)
        rows(end + 1) = struct( ... %#ok<AGROW>
            'block', string(block_name), ...
            'name', string(targets(i).name), ...
            'role', string(targets(i).role), ...
            'unit', string(targets(i).unit), ...
            'reference', double(targets(i).reference), ...
            'lower', double(targets(i).lower), ...
            'upper', double(targets(i).upper), ...
            'source', string(targets(i).source), ...
            'comment', string(targets(i).comment), ...
            'model_mapping', default_mapping(block_name, string(targets(i).role)));
    end
end

tbl = struct2table(rows);
end

function mapping = default_mapping(block_name, role)
if block_name == "fertility"
    if role == "validation"
        mapping = "Annual fertility validation only.";
    else
        mapping = "Scored directly in the annual fertility screens.";
    end
elseif block_name == "homeownership"
    if contains(role, "validation")
        mapping = "Validation only; not part of the main annual pass rule.";
    else
        mapping = "Loose annual support target for owner-share shape.";
    end
else
    mapping = "Annual balance-sheet support / validation target.";
end
end

function tbl = build_parameter_table(cfg, spec)
rows = [ ...
    make_param_row("annualized_nimby_block", "beta", cfg.overrides.beta, "Discount factor", "Inherited from the 5-year benchmark and annualized into annual time."), ...
    make_param_row("annualized_nimby_block", "bequest weight", cfg.overrides.bequestweight, "Bequest weight", "Inherited from the 5-year benchmark and annualized into annual time."), ...
    make_param_row("annualized_nimby_block", "ra", cfg.overrides.ra, "Saving rate", "Inherited from the 5-year benchmark and annualized into annual time."), ...
    make_param_row("annualized_nimby_block", "rspread", cfg.overrides.rspread, "Borrowing spread", "Inherited from the 5-year benchmark and annualized into annual time."), ...
    make_param_row("annualized_nimby_block", "ka", cfg.overrides.ka, "Housing adjustment cost", "Inherited from the 5-year benchmark and annualized into annual time."), ...
    make_param_row("annualized_nimby_block", "d price", cfg.overrides.d_a_price, "Vote-shock price multiplier", "Inherited from the 5-year benchmark and annualized into annual time."), ...
    make_param_row("annual_anchor", "phi by parity", spec.anchor.birth_utility_by_parity, "Parity-specific birth utility", "Fixed annual fertility anchor from the narrow annual timing-stock frontier."), ...
    make_param_row("annual_anchor", "child utility", spec.anchor.child_utility, "Child-at-home utility", "Fixed annual fertility anchor."), ...
    make_param_row("annual_anchor", "birth cost", spec.anchor.birth_cost, "Common birth cost", "Fixed annual fertility anchor."), ...
    make_param_row("annual_anchor", "birth price coeff", spec.anchor.birth_price_coeff, "Price-sensitive birth cost", "Fixed annual fertility anchor."), ...
    make_param_row("annual_anchor", "lambda crowd", spec.anchor.lambda_crowd, "Crowding strength", "Fixed annual fertility anchor."), ...
    make_param_row("annual_anchor", "theta r", spec.anchor.theta_r, "Renter housing-services conversion", "Owner-access anchor carried into the annual ownership branch."), ...
    make_param_row("annual_anchor", "housingmax", spec.anchor.housingmax, "Maximum housing grid point", "Owner-access anchor carried into the annual ownership branch."), ...
    make_param_row("annual_anchor", "rent markup", spec.anchor.rent_markup, "Rental-rate markup", "Owner-access anchor carried into the annual ownership branch."), ...
    make_param_row("annual_anchor", "ka anchor", spec.anchor.ka, "Anchor housing adjustment cost", "Annual owner-side anchor used in the live ownership / balance-sheet branch."), ...
    make_param_row("annual_anchor", "first-birth realized weights", [1.00, 0.25, 0.040, 0.008], "Age-profile shifters for first births by five-year bin", "Mapped to the CDC 2020-2024 first-birth timing profile."), ...
    make_param_row("heterogeneity_screen", "constrained share grid", spec.families(1).constrained_share_grid, "Share of constrained entrants", "Screened to recover young-homeownership and wealth shape without forcing one-off wedges."), ...
    make_param_row("heterogeneity_screen", "helped share grid", spec.families(1).helped_share_grid, "Share of helped entrants", "Screened to recover young-homeownership and wealth shape without forcing one-off wedges."), ...
    make_param_row("heterogeneity_screen", "constrained a_{max}", spec.families(1).constrained_housingmax_grid, "Constrained entrant owner-grid cap", "Reduced-form owner-access screen."), ...
    make_param_row("heterogeneity_screen", "helped a_{max}", spec.families(1).helped_housingmax_grid, "Helped entrant owner-grid cap", "Reduced-form owner-access screen."), ...
    make_param_row("heterogeneity_screen", "constrained \theta_r", spec.families(1).constrained_theta_r_grid, "Constrained entrant renter disadvantage", "Reduced-form renter-side screen."), ...
    make_param_row("heterogeneity_screen", "helped \theta_r", spec.families(1).helped_theta_r_grid, "Helped entrant renter disadvantage", "Reduced-form renter-side screen."), ...
    make_param_row("heterogeneity_screen", "helped transfer boost", spec.families(1).helped_parental_transfer_b_boost_grid, "Helped entrant initial asset boost", "Reduced-form down-payment help screen around the entrant mixture branch.") ...
    ];

tbl = struct2table(rows);
end

function row = make_param_row(block, param, value, description, basis)
row = struct( ...
    'block', string(block), ...
    'parameter', string(param), ...
    'value', string(format_value(value)), ...
    'description', string(description), ...
    'calibration_basis', string(basis));
end

function txt = format_value(value)
if isnumeric(value)
    if isscalar(value)
        txt = sprintf('%.4f', value);
    else
        parts = arrayfun(@(x) sprintf('%.3f', x), value(:)', 'UniformOutput', false);
        txt = ['[', strjoin(parts, ', '), ']'];
    end
elseif isstring(value) || ischar(value)
    txt = char(string(value));
else
    txt = char(string(value));
end
end

function write_markdown(path, target_table, parameter_table, spec)
fid = fopen(path, 'w');
fprintf(fid, '# Annual calibration tables\n\n');
fprintf(fid, 'This note consolidates the live annual-branch targets and implementation objects into one place. It is designed to mirror the paper-style calibration tables used in the necessity project, while staying specific to the active annual fertility branch.\n\n');
fprintf(fid, '## Target table\n\n');
fprintf(fid, '| Block | Object | Role | Reference | Lower | Upper | Current use |\n');
fprintf(fid, '|---|---|---|---:|---:|---:|---|\n');
for i = 1:height(target_table)
    fprintf(fid, '| %s | %s | %s | `%.3f` | `%.3f` | `%.3f` | %s |\n', ...
        char(target_table.block(i)), char(target_table.name(i)), char(target_table.role(i)), ...
        target_table.reference(i), target_table.lower(i), target_table.upper(i), ...
        escape_pipes(char(target_table.model_mapping(i))));
end
fprintf(fid, '\n');
fprintf(fid, '## Calibration implementation table\n\n');
fprintf(fid, '| Block | Parameter | Value | Description | Calibration basis |\n');
fprintf(fid, '|---|---|---|---|---|\n');
for i = 1:height(parameter_table)
    fprintf(fid, '| %s | %s | `%s` | %s | %s |\n', ...
        char(parameter_table.block(i)), escape_pipes(char(parameter_table.parameter(i))), ...
        char(parameter_table.value(i)), escape_pipes(char(parameter_table.description(i))), ...
        escape_pipes(char(parameter_table.calibration_basis(i))));
end
fprintf(fid, '\n');
fprintf(fid, '## Current annual anchor read\n\n');
fprintf(fid, '- mean age first birth target read: `%.2f`\n', spec.anchor.target_read.mean_age_first_birth);
fprintf(fid, '- share first births age `30+` target read: `%.3f`\n', spec.anchor.target_read.share_first_birth_30_plus);
fprintf(fid, '- childless share at `50` target read: `%.4f`\n\n', spec.anchor.target_read.childless_share_at_50);
fprintf(fid, '## Interpretation\n\n');
fprintf(fid, '- fertility targets remain the primary annual moment block\n');
fprintf(fid, '- ACS owner shares remain the current support block\n');
fprintf(fid, '- SCF wealth ratios are added as balance-sheet support / validation objects for the entrant-mixture branch\n');
fprintf(fid, '- the ownership / balance-sheet screen should be read as the live mechanism branch rather than a one-off parental-transfer wedge\n');
fclose(fid);
end

function write_target_tex(path, target_table)
fid = fopen(path, 'w');
fprintf(fid, '\\begin{table}[H]\n');
fprintf(fid, '\\caption{Annual branch targets: data moments and screening bands}\n');
fprintf(fid, '\\label{tab:annual_targeted_moments}\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\scriptsize\n');
fprintf(fid, '\\setlength{\\tabcolsep}{3pt}\n');
fprintf(fid, '\\renewcommand{\\arraystretch}{1.03}\n');
fprintf(fid, '\\begin{tabularx}{0.98\\linewidth}{@{}>{\\raggedright\\arraybackslash}p{1.25cm}>{\\raggedright\\arraybackslash}p{3.10cm}>{\\raggedright\\arraybackslash}p{1.80cm}ccc>{\\raggedright\\arraybackslash}X@{}}\n');
fprintf(fid, '\\toprule\n');
fprintf(fid, 'Block & Moment & Role & Ref. & Lower & Upper & Source / use \\\\\n');
fprintf(fid, '\\midrule\n');
for i = 1:height(target_table)
    source_use = sprintf('%s %s', char(target_table.source(i)), char(target_table.model_mapping(i)));
    fprintf(fid, '%s & %s & %s & %.3f & %.3f & %.3f & %s \\\\\n', ...
        escape_tex(char(target_table.block(i))), ...
        escape_tex(char(target_table.name(i))), ...
        escape_tex(char(target_table.role(i))), ...
        target_table.reference(i), target_table.lower(i), target_table.upper(i), ...
        escape_tex(source_use));
end
fprintf(fid, '\\bottomrule\n');
fprintf(fid, '\\end{tabularx}\n');
fprintf(fid, '\\begin{minipage}{0.94\\textwidth}\\vspace{4pt}\\scriptsize\n');
fprintf(fid, '\\textit{Notes.} Fertility targets are the primary annual calibration moments. ACS homeownership bins are loose support targets. SCF wealth targets are age-profile support and validation objects intended to discipline entrant balance-sheet heterogeneity rather than literal dollar matching in the normalized model.\n');
fprintf(fid, '\\end{minipage}\n');
fprintf(fid, '\\end{table}\n');
fclose(fid);
end

function write_parameter_tex(path, parameter_table)
fid = fopen(path, 'w');
fprintf(fid, '\\begin{table}[H]\n');
fprintf(fid, '\\caption{Annual branch calibration: implementation objects}\n');
fprintf(fid, '\\label{tab:annual_calibration_implementation}\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\scriptsize\n');
fprintf(fid, '\\setlength{\\tabcolsep}{2pt}\n');
fprintf(fid, '\\renewcommand{\\arraystretch}{1.03}\n');
fprintf(fid, '\\begin{tabularx}{0.98\\linewidth}{@{}>{\\raggedright\\arraybackslash}p{1.70cm}>{\\raggedright\\arraybackslash}p{1.70cm}>{\\centering\\arraybackslash}p{2.10cm}>{\\raggedright\\arraybackslash}p{2.70cm}>{\\raggedright\\arraybackslash}X@{}}\n');
fprintf(fid, '\\toprule\n');
fprintf(fid, 'Block & Parameter & Value & Description & Calibration basis \\\\\n');
fprintf(fid, '\\midrule\n');
for i = 1:height(parameter_table)
    fprintf(fid, '%s & %s & %s & %s & %s \\\\\n', ...
        escape_tex(char(parameter_table.block(i))), ...
        escape_tex(char(parameter_table.parameter(i))), ...
        escape_tex(char(parameter_table.value(i))), ...
        escape_tex(char(parameter_table.description(i))), ...
        escape_tex(char(parameter_table.calibration_basis(i))));
end
fprintf(fid, '\\bottomrule\n');
fprintf(fid, '\\end{tabularx}\n');
fprintf(fid, '\\end{table}\n');
fclose(fid);
end

function out = escape_pipes(text)
out = strrep(text, '|', '&#124;');
end

function out = escape_tex(text)
out = text;
repls = { ...
    '_', '\_'; ...
    '%', '\%'; ...
    '&', '\&'; ...
    '#', '\#'; ...
    '$', '\$'};
for i = 1:size(repls, 1)
    out = strrep(out, repls{i, 1}, repls{i, 2});
end
end
