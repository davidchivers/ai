#pragma once

#include <filesystem>
#include <string>
#include <vector>

namespace nimby_sidecar {

struct ReducedFormOperator {
    double intercept = 0.0;
    double pressure_coeff = 0.0;
    double next_price_coeff = 0.0;
    double baseline_price = 0.0;
    double tail_price = 0.0;
    double log_baseline_price = 0.0;
    std::vector<int> periods;
    std::vector<int> years;
    std::vector<double> pressure_index;
    std::vector<double> young_share_25_44;
    std::vector<double> benchmark_price_path;
};

struct ReducedFormParams {
    int k = 1;
    int start_index = 1;
    int max_iter = 100;
    double tol = 1.0e-8;
    double relaxation_weight = 0.50;
    double re_weight = 1.0;
    double price_min = 1.75;
    double price_max = 2.25;
    double tail_price = 0.0;
};

struct IterationRecord {
    int iteration = 0;
    double max_abs_gap = 0.0;
    double max_abs_log_gap = 0.0;
    double price_min = 0.0;
    double price_max = 0.0;
};

struct ReducedFormResults {
    std::string status;
    bool converged = false;
    int iterations_completed = 0;
    int k = 0;
    int start_index = 1;
    double re_weight = 0.0;
    double relaxation_weight = 0.0;
    double price_min = 0.0;
    double price_max = 0.0;
    double tail_price = 0.0;
    std::vector<double> final_price_path;
    std::vector<double> implied_price_path;
    std::vector<double> implied_price_path_unbounded;
    std::vector<double> next_price_reference;
    double max_abs_gap = 0.0;
    double max_abs_log_gap = 0.0;
    double path_span = 0.0;
    bool hits_bound = false;
    bool looks_stable = false;
    std::vector<double> pressure_index;
    std::vector<double> young_share_25_44;
    std::vector<int> periods;
    std::vector<int> years;
    std::vector<IterationRecord> iteration_log;
};

struct ReducedFormInputPack {
    std::filesystem::path input_dir;
    ReducedFormOperator operator_data;
    ReducedFormParams params;
    std::vector<double> initial_guess;
};

ReducedFormInputPack read_reduced_form_input_pack(const std::filesystem::path& input_dir);
ReducedFormResults solve_reduced_form_price_path(
    const ReducedFormOperator& operator_data,
    ReducedFormParams params,
    const std::vector<double>& initial_guess);
void write_reduced_form_results(const std::filesystem::path& output_dir, const ReducedFormResults& results);

}  // namespace nimby_sidecar
