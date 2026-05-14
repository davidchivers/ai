#pragma once

#include "nimby_sidecar/transition_pass_solver.hpp"

#include <filesystem>
#include <string>
#include <utility>
#include <vector>

namespace nimby_sidecar {

struct TransitionReOptions {
    int max_iter = 3;
    double tol = 1.0e-3;
    double damping = 0.25;
    std::string update_scheme = "sequential_blocks";
    std::string outer_iteration_mode = "candidate_search";
    double max_update_frac = 0.10;
    double smoothing_weight = 5.0;
    double terminal_anchor_weight = 0.50;
    double fixed_point_relaxation_weight = 0.40;
    std::string fixed_point_relaxation_space = "level";
    double fixed_point_price_min = 0.40;
    double fixed_point_price_max = 5.00;
    double targeted_correction_weight = 0.35;
    int max_targeted_periods = 3;
    int target_block_half_width = 1;
    int sequential_block_size = 3;
    int block_sweep_passes = 2;
    int max_blocks_per_pass = 4;
    bool greedy_block_accept = true;
    double candidate_improvement_tol = 1.0e-6;
    double candidate_gap_improvement_tol = 1.0e-6;
    double candidate_residual_slack = 5.0e-5;
    std::string candidate_selection_mode = "global";
    double focus_gap_improvement_tol = 1.0e-4;
    double focus_excess_improvement_tol = 1.0e-5;
    double focus_residual_slack = 2.0e-4;
    bool sequential_return_endpoint = false;
    bool save_candidate_history = false;
    std::vector<double> line_search_scales;
};

struct IterationSummary {
    double residual_norm = 0.0;
    double max_abs_gap = 0.0;
    double max_abs_update = 0.0;
    std::string accepted_update;
};

struct CandidateDiagnostic {
    std::string stage;
    double pass = 0.0;
    std::string candidate_label;
    std::string incumbent_label;
    double block_start = 0.0;
    double block_stop = 0.0;
    double scale = 0.0;
    std::vector<int> focus_periods;
    double candidate_residual_norm = 0.0;
    double candidate_max_abs_gap = 0.0;
    double candidate_focus_gap = 0.0;
    double candidate_focus_excess = 0.0;
    double incumbent_residual_norm = 0.0;
    double incumbent_max_abs_gap = 0.0;
    double incumbent_focus_gap = 0.0;
    double incumbent_focus_excess = 0.0;
    bool wins_focus = false;
    bool wins_global = false;
    bool wins_sequential = false;
    bool greedy_global = false;
    bool greedy_sequential = false;
    std::string selection_reason;
    std::string greedy_reason;
    bool became_best = false;
    bool accepted_greedily = false;
};

struct PassDiagnostic {
    int pass = 0;
    std::string start_label;
    std::vector<int> focus_periods;
    std::vector<int> targeted_periods;
    std::vector<std::pair<int, int>> targeted_blocks;
    std::vector<int> block_starts;
    std::vector<CandidateDiagnostic> candidate_evaluations;
    std::string selected_label;
    double selected_residual_norm = 0.0;
    double selected_max_abs_gap = 0.0;
    bool accepted_in_pass = false;
    std::string greedy_accept_label;
};

struct SequentialDiagnostic {
    std::string selection_mode;
    std::string start_label;
    std::vector<PassDiagnostic> passes;
    std::string final_label;
    double final_residual_norm = 0.0;
    double final_max_abs_gap = 0.0;
};

struct IterationSelectionDiagnostic {
    int iteration = 0;
    std::string candidate_selection_mode;
    std::string current_label;
    double current_residual_norm = 0.0;
    double current_max_abs_gap = 0.0;
    std::vector<int> targeted_periods;
    std::vector<std::pair<int, int>> targeted_blocks;
    std::vector<CandidateDiagnostic> initial_candidates;
    bool has_sequential = false;
    SequentialDiagnostic sequential;
    std::string final_selected_label;
    double final_residual_norm = 0.0;
    double final_max_abs_gap = 0.0;
};

struct TransitionReInput {
    TransitionPassInput transition_input;
    std::vector<double> initial_price_path;
    TransitionReOptions options;
};

struct TransitionReResults {
    bool converged = false;
    int iterations = 0;
    int horizon = 0;
    std::vector<double> initial_price_path;
    std::vector<double> final_price_path;
    std::vector<double> implied_price_path;
    std::vector<double> Hdemand_path;
    std::vector<double> Hsupply_path;
    std::vector<double> excess_demand_path;
    std::vector<double> log_price_residual_raw;
    std::vector<double> policy_reference_price_path_used;
    double terminal_reference_price_used = 0.0;
    std::vector<double> density_by_period_age;
    std::vector<IterationSummary> iteration_log;
    std::vector<double> iteration_current_price_paths;
    std::vector<double> iteration_implied_price_paths;
    std::vector<double> iteration_selected_price_paths;
    std::vector<IterationSelectionDiagnostic> selection_diagnostics;
    std::string final_label;
    double final_max_abs_gap = 0.0;
    double final_residual_norm = 0.0;
};

TransitionReInput read_transition_re_input_pack(const std::filesystem::path& input_dir);
TransitionReResults solve_transition_re(const TransitionReInput& input);
void write_transition_re_results(const std::filesystem::path& output_dir, const TransitionReResults& results);

}  // namespace nimby_sidecar
