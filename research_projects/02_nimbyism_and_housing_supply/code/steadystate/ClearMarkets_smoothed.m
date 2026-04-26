function Results = ClearMarkets_smoothed(options)
% Solve the steady state under a smoothed vote rule with tau homotopy.
%
% The legacy grid-search script remains in ClearMarkets.m. This driver keeps
% that path intact and adds a cleaner "smooth -> sharpen" workflow.

if nargin < 1 || isempty(options)
    options = struct();
end
options = apply_options_defaults_local(options);

tic
center_price = options.initial_price_center;
half_width = options.initial_half_width;
Results = struct([]);

for itau = 1:numel(options.tau_path)
    vote_params = struct( ...
        'mode','smooth_logit', ...
        'sigma',options.vote_sigma, ...
        'tau',options.tau_path(itau));
    [stage_result,center_price,half_width] = solve_homotopy_stage_local( ...
        center_price,half_width,options.rbPos,vote_params,options);
    stage_result.stage_label = sprintf('smooth_tau_%0.4f',options.tau_path(itau));
    Results = append_result_local(Results,stage_result);
end

hard_vote_params = struct( ...
    'mode','hard_sign', ...
    'sigma',options.vote_sigma, ...
    'tau',max(min(options.tau_path),1e-8));
[distance,a_price,rbPos,totalvote,debtstock,vote_diagnostics] = SolveSS_iter([center_price,options.rbPos],hard_vote_params);
Results = append_result_local(Results,struct( ...
    'stage_label','hard_sign_check', ...
    'mode',hard_vote_params.mode, ...
    'sigma',hard_vote_params.sigma, ...
    'tau',hard_vote_params.tau, ...
    'a_price',a_price, ...
    'rbPos',rbPos, ...
    'distance',distance, ...
    'totalvote',totalvote, ...
    'debtstock',debtstock, ...
    'solve_mode','direct_eval', ...
    'price_grid',center_price, ...
    'vote_grid',totalvote, ...
    'distance_grid',distance, ...
    'bracket',[NaN,NaN], ...
    'vote_diagnostics',vote_diagnostics));

save('ClearMarkets_smoothed_results.mat','Results','options');

disp('Smoothed steady-state homotopy complete.')
for iresult = 1:numel(Results)
    fprintf('%s: p=%0.6f, vote=%0.6f, distance=%0.6g\n', ...
        Results(iresult).stage_label, ...
        Results(iresult).a_price, ...
        Results(iresult).totalvote, ...
        Results(iresult).distance)
end
toc
end

function options = apply_options_defaults_local(options)
if ~isfield(options,'rbPos') || isempty(options.rbPos)
    options.rbPos = 0.03;
end
if ~isfield(options,'vote_sigma') || isempty(options.vote_sigma)
    options.vote_sigma = 0;
end
if ~isfield(options,'tau_path') || isempty(options.tau_path)
    options.tau_path = [1.0,0.5,0.25,0.1,0.05,0.02];
end
if ~isfield(options,'initial_price_center') || isempty(options.initial_price_center)
    options.initial_price_center = 2.0;
end
if ~isfield(options,'initial_half_width') || isempty(options.initial_half_width)
    options.initial_half_width = 0.2;
end
if ~isfield(options,'grid_points') || isempty(options.grid_points)
    options.grid_points = 9;
end
if ~isfield(options,'minimum_half_width') || isempty(options.minimum_half_width)
    options.minimum_half_width = 0.05;
end
if ~isfield(options,'half_width_shrink') || isempty(options.half_width_shrink)
    options.half_width_shrink = 0.6;
end
end

function [stage_result,next_center,next_half_width] = solve_homotopy_stage_local( ...
    center_price,half_width,rbPos,vote_params,options)
price_grid = linspace(center_price-half_width,center_price+half_width,options.grid_points);
vote_grid = NaN(size(price_grid));
distance_grid = NaN(size(price_grid));

for iprice = 1:numel(price_grid)
    [distance,~,~,totalvote] = SolveSS_iter([price_grid(iprice),rbPos],vote_params);
    vote_grid(iprice) = totalvote;
    distance_grid(iprice) = distance;
end

bracket = find_vote_bracket_local(price_grid,vote_grid);
if isempty(bracket)
    [~,imin] = min(abs(vote_grid));
    selected_price = price_grid(imin);
    solve_mode = 'grid_min_abs_vote';
elseif bracket(1) == bracket(2)
    selected_price = bracket(1);
    solve_mode = 'grid_exact_zero';
else
    selected_price = fzero(@(candidate_price) solve_vote_residual_local(candidate_price,rbPos,vote_params), bracket);
    solve_mode = 'fzero_bracketed';
end

[distance,a_price,rbPos,totalvote,debtstock,vote_diagnostics] = SolveSS_iter([selected_price,rbPos],vote_params);
stage_result = struct( ...
    'mode',vote_params.mode, ...
    'sigma',vote_params.sigma, ...
    'tau',vote_params.tau, ...
    'a_price',a_price, ...
    'rbPos',rbPos, ...
    'distance',distance, ...
    'totalvote',totalvote, ...
    'debtstock',debtstock, ...
    'solve_mode',solve_mode, ...
    'price_grid',price_grid, ...
    'vote_grid',vote_grid, ...
    'distance_grid',distance_grid, ...
    'bracket',bracket, ...
    'vote_diagnostics',vote_diagnostics);

next_center = a_price;
next_half_width = max(options.minimum_half_width,half_width*options.half_width_shrink);
end

function bracket = find_vote_bracket_local(price_grid,vote_grid)
bracket = [];
for iprice = 2:numel(price_grid)
    left_vote = vote_grid(iprice-1);
    right_vote = vote_grid(iprice);
    if sign(left_vote) == 0
        bracket = [price_grid(iprice-1),price_grid(iprice-1)];
        return
    end
    if sign(left_vote) ~= sign(right_vote)
        bracket = [price_grid(iprice-1),price_grid(iprice)];
        return
    end
end
end

function vote_residual = solve_vote_residual_local(a_price,rbPos,vote_params)
[~,~,~,vote_residual] = SolveSS_iter([a_price,rbPos],vote_params);
end

function Results = append_result_local(Results,new_result)
if isempty(Results)
    Results = new_result;
else
    Results(end+1) = new_result; %#ok<AGROW>
end
end
