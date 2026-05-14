function run_fertility_solver_integrity_checks()
project_root = fileparts(fileparts(mfilename('fullpath')));
out_dir = fullfile(project_root, 'notes', 'build');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

this_code_dir = fullfile(project_root, 'code');
project02_steady = fullfile(fileparts(project_root), '02_nimbyism_and_housing_supply', 'code', 'steadystate');
addpath(this_code_dir, '-begin');
if exist(project02_steady, 'dir')
    addpath(project02_steady, '-begin');
end
cd(this_code_dir);
clear SolveSS_function SolveSS_fertility ClearMarkets_fertility

ensure_external_matlab_data_paths();

cfg = fertility_benchmark_config();
annual_cfg = fertility_benchmark_annual_config();
repro_overrides = build_nimby_shutoff_overrides(cfg.overrides);

[distance_fertility, ~, ~, vote_fertility, debt_fertility, diagnostics] = SolveSS_fertility([2.0, cfg.rbPos], repro_overrides);
upstream = load('SS_function.mat');
fertility_state = load('SS_fertility.mat');
vote_upstream = sum(upstream.dens4 .* upstream.pref4, 'all');
debt_upstream = sum(upstream.bbbb .* upstream.dens4, 'all');

assert(abs(vote_fertility - vote_upstream) < 1e-10, 'Reproduction vote gap is not zero.');
assert(abs(debt_fertility - debt_upstream) < 1e-10, 'Reproduction debt gap is not zero.');
assert(abs(fertility_state.totalvote - vote_upstream) < 1e-10, 'Saved reproduction vote does not match upstream.');
assert(abs(fertility_state.debtstock - debt_upstream) < 1e-10, 'Saved reproduction debt does not match upstream.');
assert(abs(fertility_state.distance - distance_fertility) < 1e-12, 'Saved reproduction distance does not match returned distance.');

dens_size = size(diagnostics.dens4);
assert(numel(diagnostics.b_grid) == dens_size(1), 'Reproduction b_grid length does not match dens4.');
assert(numel(diagnostics.a_grid) == dens_size(2), 'Reproduction a_grid length does not match dens4.');
assert(max(abs(diagnostics.mass_pre_policy(:) - diagnostics.age_mass(:))) < 1e-12, ...
    'Reproduction mass_pre_policy is inconsistent with age_mass.');
assert(max(abs(diagnostics.mass_post_policy(:) - diagnostics.age_mass(:))) < 1e-12, ...
    'Reproduction mass_post_policy is inconsistent with age_mass.');

assert(abs(annual_cfg.rbPos - annualize_net_rate(annual_cfg.rbPos_five_year, 5)) < 1e-12, ...
    'Annual rbPos is not annualized from the 5-year benchmark.');
assert(abs(annual_cfg.overrides.beta - annualize_discount(annual_cfg.beta_five_year, 5)) < 1e-12, ...
    'Annual beta is not annualized from the 5-year benchmark.');
assert(abs(annual_cfg.overrides.bequestweight - annualize_discount(annual_cfg.bequestweight_five_year, 5)) < 1e-12, ...
    'Annual bequestweight is not annualized from the 5-year benchmark.');
assert(abs(annual_cfg.overrides.rspread - annualize_spread(annual_cfg.rbPos_five_year, annual_cfg.rb_spread_five_year, 5)) < 1e-12, ...
    'Annual rspread is not annualized from the 5-year benchmark.');
assert(abs(annual_cfg.overrides.ra - annualize_net_rate(annual_cfg.ra_five_year, 5)) < 1e-12, ...
    'Annual ra is not annualized from the 5-year benchmark.');
assert(abs(annual_cfg.overrides.rent_markup - annualize_net_rate(annual_cfg.rent_markup_five_year, 5)) < 1e-12, ...
    'Annual rent markup is not annualized from the 5-year benchmark.');
assert(abs(annual_cfg.overrides.ka - annualize_adjustment_cost(annual_cfg.ka_five_year, 5)) < 1e-12, ...
    'Annual ka is not annualized from the 5-year benchmark.');
assert(abs(annual_cfg.overrides.d_a_price - annualize_price_multiplier(annual_cfg.d_a_price_five_year, 5)) < 1e-12, ...
    'Annual vote shock is not annualized from the 5-year benchmark.');

report_path = fullfile(out_dir, 'fertility_solver_integrity_checks.md');
fid = fopen(report_path, 'w');
fprintf(fid, '# Fertility solver integrity checks\n\n');
fprintf(fid, '- Reproduction saved distance: `%.12g`\n', distance_fertility);
fprintf(fid, '- Reproduction vote gap: `%.12g`\n', vote_fertility - vote_upstream);
fprintf(fid, '- Reproduction debt gap: `%.12g`\n', debt_fertility - debt_upstream);
fprintf(fid, '- Reproduction dens4 size: `%d x %d x %d x %d`\n', dens_size(1), dens_size(2), dens_size(3), dens_size(4));
fprintf(fid, '- Reproduction grid lengths: `b = %d`, `a = %d`\n', numel(diagnostics.b_grid), numel(diagnostics.a_grid));
fprintf(fid, '- Annualized `rbPos`: `%.12f`\n', annual_cfg.rbPos);
fprintf(fid, '- Annualized `beta`: `%.12f`\n', annual_cfg.overrides.beta);
fprintf(fid, '- Annualized `bequestweight`: `%.12f`\n', annual_cfg.overrides.bequestweight);
fprintf(fid, '- Annualized `rspread`: `%.12f`\n', annual_cfg.overrides.rspread);
fprintf(fid, '- Annualized `ra`: `%.12f`\n', annual_cfg.overrides.ra);
fprintf(fid, '- Annualized `rent_markup`: `%.12f`\n', annual_cfg.overrides.rent_markup);
fprintf(fid, '- Annualized `ka`: `%.12f`\n', annual_cfg.overrides.ka);
fprintf(fid, '- Annualized `d_a_price`: `%.12f`\n', annual_cfg.overrides.d_a_price);
fclose(fid);
end

function beta_annual = annualize_discount(beta_period, years_per_period)
beta_annual = beta_period .^ (1 / years_per_period);
end

function spread_annual = annualize_spread(rb_pos, spread, years_per_period)
rb_neg = rb_pos + spread;
spread_annual = annualize_net_rate(rb_neg, years_per_period) - annualize_net_rate(rb_pos, years_per_period);
end

function r_annual = annualize_net_rate(r_period, years_per_period)
r_annual = (1 + r_period) .^ (1 / years_per_period) - 1;
end

function ka_annual = annualize_adjustment_cost(ka_period, years_per_period)
ka_annual = 1 - (1 - ka_period) .^ (1 / years_per_period);
end

function d_a_price_annual = annualize_price_multiplier(d_a_price_period, years_per_period)
d_a_price_annual = d_a_price_period .^ (1 / years_per_period);
end
