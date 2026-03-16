function stats = compute_coalition_vote(density, pref_sign, housing_grid, liquid_grid, age_grid, params)
% Coalition-weighted political aggregator for NIMBY extensions.
% The baseline model uses equal political weight. This helper allows owner-
% and coalition-weighted voting while preserving the same preference object.

if nargin < 6 || isempty(params)
    params = struct();
end

validateattributes(density, {'double'}, {'nonempty'}, mfilename, 'density');
validateattributes(pref_sign, {'double'}, {'size', size(density)}, mfilename, 'pref_sign');
validateattributes(housing_grid, {'double'}, {'size', size(density)}, mfilename, 'housing_grid');
validateattributes(liquid_grid, {'double'}, {'size', size(density)}, mfilename, 'liquid_grid');

if numel(age_grid) ~= size(density, 4)
    error('age_grid length must match the age dimension of density.');
end

params = set_default_params(params);

owner = housing_grid > params.owner_cutoff;
old_age = reshape(age_grid >= params.old_age_cutoff, 1, 1, 1, []);
old_owner = owner .* old_age;

housing_value = max(housing_grid .* params.house_price, params.eps_value);
leverage_ratio = max(-liquid_grid, 0) ./ housing_value;
leveraged_owner = owner .* (leverage_ratio >= params.leverage_cutoff);

housing_share = housing_value ./ max(params.house_price * params.housing_scale, params.eps_value);

weights = 1 ...
    + params.alpha_owner .* owner ...
    + params.alpha_old_owner .* old_owner ...
    + params.alpha_leverage .* leveraged_owner ...
    + params.alpha_bighouse .* housing_share;

weighted_density = weights .* density;
weighted_vote_mass = weighted_density .* pref_sign;

stats = struct();
stats.weights = weights;
stats.equal_weight_vote = sum(density .* pref_sign, 'all');
stats.weighted_vote = sum(weighted_vote_mass, 'all');
stats.weighted_total_mass = sum(weighted_density, 'all');
stats.weighted_vote_share = stats.weighted_vote ./ max(stats.weighted_total_mass, params.eps_value);
stats.owner_share = sum(density(owner), 'all') ./ max(sum(density, 'all'), params.eps_value);
stats.old_owner_share = sum(density(logical(old_owner)), 'all') ./ max(sum(density, 'all'), params.eps_value);
stats.leveraged_owner_share = sum(density(logical(leveraged_owner)), 'all') ./ max(sum(density, 'all'), params.eps_value);
end

function params = set_default_params(params)
defaults = struct( ...
    'alpha_owner', 0.50, ...
    'alpha_old_owner', 0.50, ...
    'alpha_leverage', 0.25, ...
    'alpha_bighouse', 0.10, ...
    'owner_cutoff', 1e-8, ...
    'old_age_cutoff', 55, ...
    'leverage_cutoff', 0.60, ...
    'house_price', 1.0, ...
    'housing_scale', 1.0, ...
    'eps_value', 1e-12);

names = fieldnames(defaults);
for i = 1:numel(names)
    name = names{i};
    if ~isfield(params, name) || isempty(params.(name))
        params.(name) = defaults.(name);
    end
end
end
