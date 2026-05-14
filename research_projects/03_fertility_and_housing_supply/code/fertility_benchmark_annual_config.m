function cfg = fertility_benchmark_annual_config()
base = fertility_benchmark_config();
project_root = fileparts(fileparts(mfilename('fullpath')));
transition_matrix_file = fullfile(project_root, 'notes', 'build', 'TransitionMatrix_annual.mat');

beta_five_year = 0.98;
bequestweight_five_year = 0.98;
rbPos_five_year = base.rbPos;
rb_spread_five_year = 0.02;
ra_five_year = -0.03;
rent_markup_five_year = 0.02;
ka_five_year = 0.06;
d_a_price_five_year = 1.01;

annual_ages = 25:80;
annual_birth_ages = 25:44;
annual_birth_age_weights = expand_birth_age_bin_shares(base.target_first_birth_age_share_25plus, annual_birth_ages);
annual_first_birth_realized_weights = annual_birth_age_weights ./ max(annual_birth_age_weights);
annual_cohort_weights = expand_cohort_profile(annual_ages);

benchmark_overrides = base.overrides;
benchmark_overrides.agemin = annual_ages(1);
benchmark_overrides.agemax = annual_ages(end);
benchmark_overrides.dage = 1;
benchmark_overrides.birth_ages = annual_birth_ages;
benchmark_overrides.birth_age_weights = annual_birth_age_weights;
benchmark_overrides.realized_birth_weights = ones(size(annual_birth_ages));
benchmark_overrides.first_birth_realized_weights = annual_first_birth_realized_weights;
benchmark_overrides.cohort_weights_by_age = annual_cohort_weights;
benchmark_overrides.transition_matrix_file = transition_matrix_file;
benchmark_overrides.beta = annualize_discount(beta_five_year, 5);
benchmark_overrides.bequestweight = annualize_discount(bequestweight_five_year, 5);
benchmark_overrides.rspread = annualize_spread(rbPos_five_year, rb_spread_five_year, 5);
benchmark_overrides.ra = annualize_net_rate(ra_five_year, 5);
benchmark_overrides.rent_markup = annualize_net_rate(rent_markup_five_year, 5);
benchmark_overrides.ka = annualize_adjustment_cost(ka_five_year, 5);
benchmark_overrides.d_a_price = annualize_price_multiplier(d_a_price_five_year, 5);

smoke_overrides = benchmark_overrides;
smoke_overrides.I = 20;
smoke_overrides.J = 6;

cfg = struct();
cfg.eval_price = base.eval_price;
cfg.eval_age = base.eval_age;
cfg.rbPos = annualize_net_rate(rbPos_five_year, 5);
cfg.rbPos_five_year = rbPos_five_year;
cfg.beta_five_year = beta_five_year;
cfg.bequestweight_five_year = bequestweight_five_year;
cfg.rb_spread_five_year = rb_spread_five_year;
cfg.ra_five_year = ra_five_year;
cfg.rent_markup_five_year = rent_markup_five_year;
cfg.ka_five_year = ka_five_year;
cfg.d_a_price_five_year = d_a_price_five_year;
cfg.home_report_ages = base.home_report_ages;
cfg.target_parity = base.target_parity;
cfg.target_first_birth_age_bin_share_25plus = base.target_first_birth_age_share_25plus;
cfg.target_first_birth_age_share_annual = annual_birth_age_weights;
cfg.target_ranges = fertility_annual_target_ranges();
cfg.homeownership_target_ranges = annual_homeownership_target_ranges();
cfg.wealth_target_ranges = annual_wealth_target_ranges();
cfg.target_band_policy = "wide_screening_bands";
cfg.annual_ages = annual_ages;
cfg.annual_birth_ages = annual_birth_ages;
cfg.transition_matrix_file = transition_matrix_file;
cfg.overrides = benchmark_overrides;
cfg.smoke_overrides = smoke_overrides;
cfg.full_price_grid = base.full_price_grid;
cfg.market_price_grid = base.market_price_grid;
cfg.local_market_price_grid = [1.50, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00];
cfg.smoke_full_price_grid = [1.75, 2.00, 2.25];
cfg.smoke_market_price_grid = [1.50, 2.00, 2.50];
cfg.smoke_local_market_price_grid = [1.75, 2.00, 2.25];
end

function weights = expand_birth_age_bin_shares(bin_shares, ages)
weights = zeros(1, numel(ages));
bin_starts = [25, 30, 35, 40];
bin_ends = [29, 34, 39, 44];

for ib = 1:numel(bin_shares)
    mask = ages >= bin_starts(ib) & ages <= bin_ends(ib);
    weights(mask) = bin_shares(ib) / max(sum(mask), 1);
end

weights = weights ./ sum(weights);
end

function weights = expand_cohort_profile(ages)
base_ages = 25:5:90;
base_weights = [14 12 10 10 10 10 9 8 7 5 4 2 1 1];
weights = zeros(1, numel(ages));

for ia = 1:numel(ages)
    idx = find(base_ages <= ages(ia), 1, 'last');
    if isempty(idx)
        idx = 1;
    end
    weights(ia) = base_weights(min(idx, numel(base_weights)));
end

weights = weights ./ mean(weights);
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
