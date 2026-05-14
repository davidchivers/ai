#pragma once

#include <filesystem>
#include <string>
#include <vector>

namespace nimby_sidecar {

struct TransitionPassInput {
    int T = 0;
    int age_n = 0;
    int I = 0;
    int J = 0;
    int K = 0;
    int bzero = 0;  // zero-based in C++

    double rb_pos = 0.0;
    double rb_neg = 0.0;
    double ra = 0.0;
    double r_price = 0.0;
    double omega = 0.0;
    double theta_r = 0.0;
    double beta = 0.0;
    double eta = 0.0;
    double ka = 0.0;
    double bequestweight1 = 0.0;
    double bequestweight2 = 0.0;
    double CC = 0.0;
    double penalty = 0.0;

    double supply_Hbar = 0.0;
    double supply_Pbar = 0.0;
    double supply_eta_s = 0.0;
    std::string terminal_reference_mode = "path_end_price";
    double terminal_reference_price = 0.0;
    std::string transition_policy_mode = "full_backward";
    std::string policy_reference_mode = "path_current_prices";
    double policy_reference_price = 0.0;
    double policy_reference_blend_weight = 0.0;
    double policy_reference_price_floor = 0.0;
    double policy_reference_price_cap = 0.0;
    bool save_period_details = false;
    bool compute_political_path = false;
    bool save_political_details = false;
    double price_preference_multiplier = 1.01;
    double alpha_owner = 0.50;
    double alpha_old_owner = 0.50;
    double alpha_leverage = 0.25;
    double alpha_bighouse = 0.10;
    double owner_cutoff = 1.0e-8;
    double old_age_cutoff = 55.0;
    double leverage_cutoff = 0.60;
    double housing_scale = 1.0;
    double eps_value = 1.0e-12;

    std::vector<double> a;
    std::vector<double> b;
    std::vector<double> z;
    std::vector<double> Zlifecycle;
    std::vector<double> price_path;
    std::vector<double> initialdist;
    std::vector<double> target_age_masses;    // T * age_n
    std::vector<double> transitionmatrix;     // K * K * age_n
    std::vector<double> initial_density;      // I * J * K * age_n
    std::vector<double> terminal_age_values;  // I * J * K * age_n
    std::vector<int> reference_policy_idx_b;  // T * age_n * I * J * K, one-based
    std::vector<int> reference_policy_idx_a;  // T * age_n * I * J * K, one-based
    std::vector<double> reference_valuefunctions;  // T * age_n * I * J * K
};

struct TransitionPassResults {
    std::vector<int> policy_idx_b;       // T * age_n * I * J * K, one-based to match MATLAB
    std::vector<int> policy_idx_a;       // T * age_n * I * J * K, one-based to match MATLAB
    std::vector<double> valuefunctions;  // T * age_n * I * J * K
    std::vector<double> Hdemand_path;    // T
    std::vector<double> Hsupply_guess_path;
    std::vector<double> excess_demand_guess_path;
    std::vector<double> implied_price_path;
    std::vector<double> log_price_residual_raw;
    std::vector<double> debt_path;
    std::vector<double> rent_share_path;
    std::vector<double> policy_reference_price_path_used;
    double terminal_reference_price_used = 0.0;
    std::vector<double> density_by_period_age;  // T * age_n * I * J * K
    std::vector<double> equal_weight_vote_path;
    std::vector<double> weighted_vote_path;
    std::vector<double> weighted_vote_share_path;
    std::vector<double> equal_weight_distance_path;
    std::vector<double> weighted_distance_path;
    std::vector<double> owner_share_path;
    std::vector<double> old_owner_share_path;
    std::vector<double> leveraged_owner_share_path;
    double max_abs_gap = 0.0;
    double residual_norm = 0.0;
};

TransitionPassInput read_transition_pass_input_pack(const std::filesystem::path& input_dir);
TransitionPassResults solve_transition_pass(const TransitionPassInput& input);
void write_transition_pass_results(const std::filesystem::path& output_dir, const TransitionPassResults& results);

}  // namespace nimby_sidecar
