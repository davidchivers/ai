#pragma once

#include "nimby_sidecar/transition_pass_solver.hpp"

#include <filesystem>
#include <string>
#include <vector>

namespace nimby_sidecar {

struct PoliticalBellmanOptions {
    int max_iter = 4;
    double tol_vote = 1.0e-3;
    std::string political_target = "equal_weight_vote";
    std::string price_update_mode = "political_only";
    std::string political_update_rule = "fixed_step";
    double political_update_weight = 0.005;
    double max_update_frac = 0.02;
    double price_floor = 0.40;
    double price_cap = 5.00;
    double secant_damping = 0.75;
    double secant_min_abs_slope = 1.0e-3;
    std::string guess_source = "transition_re_no_politics_results.final_price_path_prefix";
};

struct PoliticalBellmanIterationLog {
    int iteration = 0;
    std::string guess_source;
    std::string political_target;
    std::string price_update_mode;
    std::string political_update_rule;
    double max_abs_vote = 0.0;
    double mean_vote = 0.0;
    double max_abs_gap = 0.0;
    double residual_norm = 0.0;
    double price_min = 0.0;
    double price_max = 0.0;
    double housing_anchor_min = 0.0;
    double housing_anchor_max = 0.0;
    double max_abs_political_step = 0.0;
    std::vector<double> vote_path;
    std::vector<double> current_price_path;
    std::vector<double> anchor_price_path;
    std::vector<double> updated_price_path;
};

struct PoliticalBellmanResults {
    bool converged = false;
    int iterations = 0;
    std::vector<double> initial_price_path;
    std::vector<double> final_price_path;
    std::vector<double> final_vote_path;
    std::vector<double> final_anchor_path;
    std::string guess_source;
    std::string political_target;
    std::string price_update_mode;
    std::string political_update_rule;
    PoliticalBellmanOptions options;
    std::vector<PoliticalBellmanIterationLog> iteration_log;
    TransitionPassResults last_transition_pass;
    TransitionPassResults final_transition_pass;
    std::string message;
};

PoliticalBellmanResults solve_political_bellman(
    const TransitionPassInput& base_input,
    const PoliticalBellmanOptions& options = PoliticalBellmanOptions{});
void write_political_bellman_results(
    const std::filesystem::path& output_dir,
    const PoliticalBellmanResults& results);

}  // namespace nimby_sidecar
