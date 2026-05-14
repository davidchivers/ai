#pragma once

#include <filesystem>
#include <string>
#include <vector>

namespace nimby_sidecar {

struct SteadyStateInput {
    int age_n = 0;
    int I = 0;
    int J = 0;
    int K = 0;
    int bzero = 0;  // zero-based

    double a_price = 0.0;
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
    std::string steady_state_mode = "re_no_politics";

    std::vector<double> a;
    std::vector<double> b;
    std::vector<double> z;
    std::vector<double> Zlifecycle;
    std::vector<double> initialdist;
    std::vector<double> transitionmatrix;  // K * K * (age_n - 1)
};

struct SteadyStateResults {
    std::vector<int> age_policy_idx_b;       // I * J * K * age_n, one-based
    std::vector<int> age_policy_idx_a;       // I * J * K * age_n, one-based
    std::vector<double> age_valuefunctions;  // I * J * K * age_n
    std::vector<double> dens4;               // I * J * K * age_n
    double Hdemand = 0.0;
    double Hsupply = 0.0;
    double debtstock = 0.0;
};

struct SteadyStatePoliticalResults {
    SteadyStateResults baseline;
    SteadyStateResults perturbed;
    std::vector<int> preference_sign;  // -1, 0, 1 by state
    double trial_price = 0.0;
    double perturbed_price = 0.0;
    double price_multiplier = 1.0;
    double totalvote = 0.0;
    double distance = 0.0;
};

SteadyStateInput read_steady_state_input_pack(const std::filesystem::path& input_dir);
SteadyStateResults solve_steady_state_reference(const SteadyStateInput& input);
SteadyStatePoliticalResults solve_steady_state_political_reference(
    const SteadyStateInput& input,
    double price_multiplier = 1.01);
void write_steady_state_results(const std::filesystem::path& output_dir, const SteadyStateResults& results);
void write_steady_state_political_results(
    const std::filesystem::path& output_dir,
    const SteadyStatePoliticalResults& results);

}  // namespace nimby_sidecar
