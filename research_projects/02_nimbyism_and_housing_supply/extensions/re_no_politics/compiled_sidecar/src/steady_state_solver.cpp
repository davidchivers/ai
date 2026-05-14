#include "nimby_sidecar/steady_state_solver.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <limits>
#include <numeric>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace nimby_sidecar {
namespace {

std::string trim(const std::string& value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) {
        return "";
    }
    const auto last = value.find_last_not_of(" \t\r\n");
    return value.substr(first, last - first + 1);
}

std::string lowercase(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    return value;
}

std::vector<std::string> split_csv_line(const std::string& line) {
    std::vector<std::string> fields;
    std::string current;
    for (char ch : line) {
        if (ch == ',') {
            fields.push_back(trim(current));
            current.clear();
        } else {
            current.push_back(ch);
        }
    }
    fields.push_back(trim(current));
    return fields;
}

std::unordered_map<std::string, std::string> read_optional_string_map(const std::filesystem::path& path) {
    std::unordered_map<std::string, std::string> values;
    if (!std::filesystem::exists(path)) {
        return values;
    }

    std::ifstream input(path);
    if (!input) {
        throw std::runtime_error("Could not open string CSV: " + path.string());
    }

    std::string line;
    if (!std::getline(input, line)) {
        throw std::runtime_error("String CSV is empty: " + path.string());
    }

    while (std::getline(input, line)) {
        if (trim(line).empty()) {
            continue;
        }
        const auto fields = split_csv_line(line);
        if (fields.size() != 2) {
            throw std::runtime_error("Expected 2 columns in string CSV: " + path.string());
        }
        values.emplace(fields[0], fields[1]);
    }
    return values;
}

std::unordered_map<std::string, double> read_scalar_map(const std::filesystem::path& path) {
    std::ifstream input(path);
    if (!input) {
        throw std::runtime_error("Could not open scalar CSV: " + path.string());
    }

    std::string line;
    if (!std::getline(input, line)) {
        throw std::runtime_error("Scalar CSV is empty: " + path.string());
    }

    std::unordered_map<std::string, double> values;
    while (std::getline(input, line)) {
        if (trim(line).empty()) {
            continue;
        }
        const auto fields = split_csv_line(line);
        if (fields.size() != 2) {
            throw std::runtime_error("Expected 2 columns in scalar CSV: " + path.string());
        }
        values.emplace(fields[0], std::stod(fields[1]));
    }
    return values;
}

double require_scalar(const std::unordered_map<std::string, double>& values, const std::string& key) {
    const auto it = values.find(key);
    if (it == values.end()) {
        throw std::runtime_error("Missing scalar key: " + key);
    }
    return it->second;
}

std::string string_or_default(
    const std::unordered_map<std::string, std::string>& values,
    const std::string& key,
    std::string default_value) {
    const auto it = values.find(key);
    return (it == values.end()) ? std::move(default_value) : it->second;
}

std::vector<double> read_single_column_csv(const std::filesystem::path& path) {
    std::ifstream input(path);
    if (!input) {
        throw std::runtime_error("Could not open CSV: " + path.string());
    }

    std::vector<double> values;
    std::string line;
    while (std::getline(input, line)) {
        const auto field = trim(line);
        if (!field.empty()) {
            values.push_back(std::stod(field));
        }
    }
    return values;
}

std::vector<double> read_exact_length(const std::filesystem::path& path, std::size_t expected_size) {
    auto values = read_single_column_csv(path);
    if (values.size() != expected_size) {
        throw std::runtime_error("Unexpected length in " + path.string());
    }
    return values;
}

std::size_t idx3(int i, int j, int k, int I, int J, int /*K*/) {
    return static_cast<std::size_t>(i + I * (j + J * k));
}

std::size_t idx4(int i, int j, int k, int age, int I, int J, int K, int /*A*/) {
    return static_cast<std::size_t>(i + I * (j + J * (k + K * age)));
}

bool is_original_solve_ss_iter_mode(const SteadyStateInput& input) {
    return lowercase(trim(input.steady_state_mode)) == "original_solve_ss_iter";
}

double collateral_price_for_branch(
    const SteadyStateInput& input,
    bool perturbed_branch,
    double price_multiplier) {
    if (is_original_solve_ss_iter_mode(input)) {
        return input.a_price;
    }
    return input.a_price * (perturbed_branch ? price_multiplier : 1.0);
}

double housing_price_for_branch(const SteadyStateInput& input, bool perturbed_branch, double price_multiplier) {
    return input.a_price * (perturbed_branch ? price_multiplier : 1.0);
}

double rent_factor_for_branch(
    const SteadyStateInput& input,
    bool terminal_age,
    bool perturbed_branch,
    double price_multiplier) {
    const bool original_mode = is_original_solve_ss_iter_mode(input);
    double denominator_scale = perturbed_branch ? price_multiplier : 1.0;
    if (original_mode && !terminal_age && !perturbed_branch) {
        denominator_scale = price_multiplier;
    }
    const double denominator = input.r_price * denominator_scale;
    if (original_mode && !terminal_age && perturbed_branch) {
        return input.theta_r * input.omega / denominator;
    }
    return ((1.0 - input.omega) / input.omega) * input.theta_r / denominator;
}

double transition_prob_at(const SteadyStateInput& input, int current_z, int next_z, int age) {
    return input.transitionmatrix[static_cast<std::size_t>(current_z + input.K * (next_z + input.K * age))];
}

double utility_from_choice(double consumption, double housing_term, double omega, double eta) {
    return std::pow(std::pow(consumption, omega) * std::pow(housing_term, 1.0 - omega), 1.0 - eta) / (1.0 - eta);
}

void write_vector_csv(const std::filesystem::path& path, const std::vector<double>& values) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write CSV: " + path.string());
    }
    output << std::setprecision(17);
    for (double value : values) {
        output << value << '\n';
    }
}

void write_vector_csv(const std::filesystem::path& path, const std::vector<int>& values) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write CSV: " + path.string());
    }
    for (int value : values) {
        output << value << '\n';
    }
}

void write_summary_csv(const std::filesystem::path& path, const SteadyStateResults& results) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write summary CSV: " + path.string());
    }
    output << "name,value\n";
    output << std::setprecision(17);
    output << "Hdemand," << results.Hdemand << '\n';
    output << "Hsupply," << results.Hsupply << '\n';
    output << "debtstock," << results.debtstock << '\n';
}

void write_political_summary_csv(
    const std::filesystem::path& path,
    const SteadyStatePoliticalResults& results) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write political summary CSV: " + path.string());
    }
    output << "name,value\n";
    output << std::setprecision(17);
    output << "trial_price," << results.trial_price << '\n';
    output << "perturbed_price," << results.perturbed_price << '\n';
    output << "price_multiplier," << results.price_multiplier << '\n';
    output << "baseline_Hdemand," << results.baseline.Hdemand << '\n';
    output << "baseline_Hsupply," << results.baseline.Hsupply << '\n';
    output << "baseline_debtstock," << results.baseline.debtstock << '\n';
    output << "perturbed_Hdemand," << results.perturbed.Hdemand << '\n';
    output << "perturbed_Hsupply," << results.perturbed.Hsupply << '\n';
    output << "perturbed_debtstock," << results.perturbed.debtstock << '\n';
    output << "totalvote," << results.totalvote << '\n';
    output << "distance," << results.distance << '\n';
}

}  // namespace

SteadyStateInput read_steady_state_input_pack(const std::filesystem::path& input_dir) {
    SteadyStateInput input;

    const auto meta = read_scalar_map(input_dir / "meta_scalars.csv");
    const auto meta_strings = read_optional_string_map(input_dir / "meta_strings.csv");
    input.age_n = static_cast<int>(std::lround(require_scalar(meta, "age_n")));
    input.I = static_cast<int>(std::lround(require_scalar(meta, "I")));
    input.J = static_cast<int>(std::lround(require_scalar(meta, "J")));
    input.K = static_cast<int>(std::lround(require_scalar(meta, "K")));
    input.bzero = static_cast<int>(std::lround(require_scalar(meta, "bzero")));

    input.a_price = require_scalar(meta, "a_price");
    input.rb_pos = require_scalar(meta, "rb_pos");
    input.rb_neg = require_scalar(meta, "rb_neg");
    input.ra = require_scalar(meta, "ra");
    input.r_price = require_scalar(meta, "r_price");
    input.omega = require_scalar(meta, "omega");
    input.theta_r = require_scalar(meta, "theta_r");
    input.beta = require_scalar(meta, "beta");
    input.eta = require_scalar(meta, "eta");
    input.ka = require_scalar(meta, "ka");
    input.bequestweight1 = require_scalar(meta, "bequestweight1");
    input.bequestweight2 = require_scalar(meta, "bequestweight2");
    input.CC = require_scalar(meta, "CC");
    input.penalty = require_scalar(meta, "penalty");
    input.supply_Hbar = require_scalar(meta, "supply_Hbar");
    input.supply_Pbar = require_scalar(meta, "supply_Pbar");
    input.supply_eta_s = require_scalar(meta, "supply_eta_s");
    input.steady_state_mode =
        string_or_default(meta_strings, "steady_state_mode", input.steady_state_mode);

    input.a = read_exact_length(input_dir / "a.csv", static_cast<std::size_t>(input.J));
    input.b = read_exact_length(input_dir / "b.csv", static_cast<std::size_t>(input.I));
    input.z = read_exact_length(input_dir / "z.csv", static_cast<std::size_t>(input.K));
    input.Zlifecycle = read_exact_length(input_dir / "Zlifecycle.csv", static_cast<std::size_t>(input.age_n));
    input.initialdist = read_exact_length(input_dir / "initialdist.csv", static_cast<std::size_t>(input.K));
    input.transitionmatrix = read_exact_length(
        input_dir / "transitionmatrix.csv",
        static_cast<std::size_t>(input.K * input.K * (input.age_n - 1)));

    return input;
}

SteadyStateResults solve_steady_state_reference_branch(
    const SteadyStateInput& input,
    double price_multiplier,
    bool perturbed_branch) {
    const int A = input.age_n;
    const int I = input.I;
    const int J = input.J;
    const int K = input.K;
    const std::size_t state_count = static_cast<std::size_t>(I * J * K * A);
    const double housing_price = housing_price_for_branch(input, perturbed_branch, price_multiplier);
    const double collateral_price = collateral_price_for_branch(input, perturbed_branch, price_multiplier);

    SteadyStateResults results;
    results.age_policy_idx_b.assign(state_count, 0);
    results.age_policy_idx_a.assign(state_count, 0);
    results.age_valuefunctions.assign(state_count, 0.0);
    results.dens4.assign(state_count, 0.0);

    std::vector<int> policy_b0(state_count, 0);
    std::vector<int> policy_a0(state_count, 0);
    std::vector<double> next_age_values(static_cast<std::size_t>(I * J * K), 0.0);

    for (int age = A - 1; age >= 0; --age) {
        std::vector<double> expected_value(static_cast<std::size_t>(I * J * K), 0.0);
        const bool terminal_age = (age == A - 1);

        if (!terminal_age) {
            #ifdef _OPENMP
            #pragma omp parallel for collapse(3) schedule(static)
            #endif
            for (int iz = 0; iz < K; ++iz) {
                for (int jj = 0; jj < J; ++jj) {
                    for (int ii = 0; ii < I; ++ii) {
                        double value = 0.0;
                        for (int iz_next = 0; iz_next < K; ++iz_next) {
                            value += transition_prob_at(input, iz, iz_next, age) *
                                next_age_values[idx3(ii, jj, iz_next, I, J, K)];
                        }
                        expected_value[idx3(ii, jj, iz, I, J, K)] = value;
                    }
                }
            }
        }

        std::vector<double> current_age_values(static_cast<std::size_t>(I * J * K), 0.0);
        #ifdef _OPENMP
        #pragma omp parallel for collapse(3) schedule(static)
        #endif
        for (int iz = 0; iz < K; ++iz) {
            const double labor_income =
                std::exp(input.z[static_cast<std::size_t>(iz)]) * input.Zlifecycle[static_cast<std::size_t>(age)];
            for (int jj = 0; jj < J; ++jj) {
                const double current_a = input.a[static_cast<std::size_t>(jj)];
                for (int ii = 0; ii < I; ++ii) {
                    const double current_b = input.b[static_cast<std::size_t>(ii)];
                    const double wealth_flow =
                        labor_income +
                        current_b * ((current_b >= 0.0) ? input.rb_pos : input.rb_neg) +
                        current_a * housing_price;

                    double best_value = -std::numeric_limits<double>::infinity();
                    int best_b = 0;
                    int best_a = 0;
                    const double rent_factor =
                        rent_factor_for_branch(input, terminal_age, perturbed_branch, price_multiplier);

                    for (int choice_a = 0; choice_a < J; ++choice_a) {
                        const double next_a = input.a[static_cast<std::size_t>(choice_a)];
                        const double adjust_cost = (next_a == current_a) ? 0.0 : input.ka;
                        for (int choice_b = 0; choice_b < I; ++choice_b) {
                            const double next_b = input.b[static_cast<std::size_t>(choice_b)];
                            const double raw_resources =
                                wealth_flow - next_a * housing_price * (1.0 + adjust_cost) + current_b - next_b;
                            double consumption;
                            double rent = 0.0;
                            if (choice_a == 0) {
                                consumption = raw_resources / (1.0 + ((1.0 - input.omega) / input.omega * input.theta_r));
                                rent = consumption * rent_factor;
                            } else {
                                consumption = raw_resources;
                            }
                            consumption = std::max(consumption, 1.0e-20);

                            const double housing_term = next_a + input.theta_r * rent;
                            double value = utility_from_choice(consumption, housing_term, input.omega, input.eta);
                            if (-next_b > next_a * collateral_price * input.CC) {
                                value -= input.penalty;
                            }

                            if (terminal_age) {
                                const double bequest = std::max(1.0e-20, next_b + housing_price * next_a);
                                value += input.bequestweight1 * std::pow(1.0 + bequest / input.bequestweight2, 1.0 - input.eta);
                            } else {
                                value += input.beta * expected_value[idx3(choice_b, choice_a, iz, I, J, K)];
                            }

                            if (value > best_value) {
                                best_value = value;
                                best_b = choice_b;
                                best_a = choice_a;
                            }
                        }
                    }

                    const std::size_t out_idx = idx4(ii, jj, iz, age, I, J, K, A);
                    policy_b0[out_idx] = best_b;
                    policy_a0[out_idx] = best_a;
                    results.age_policy_idx_b[out_idx] = best_b + 1;
                    results.age_policy_idx_a[out_idx] = best_a + 1;
                    results.age_valuefunctions[out_idx] = best_value;
                    current_age_values[idx3(ii, jj, iz, I, J, K)] = best_value;
                }
            }
        }

        next_age_values = std::move(current_age_values);
    }

    std::vector<double> density_prev(static_cast<std::size_t>(I * J * K), 0.0);
    std::vector<double> density(static_cast<std::size_t>(I * J * K), 0.0);
    for (int age = 0; age < A; ++age) {
        std::fill(density.begin(), density.end(), 0.0);

        if (age == 0) {
            std::fill(density_prev.begin(), density_prev.end(), 0.0);
            for (int iz = 0; iz < K; ++iz) {
                density_prev[idx3(input.bzero, 0, iz, I, J, K)] = input.initialdist[static_cast<std::size_t>(iz)];
            }
        } else {
            std::vector<double> transitioned(static_cast<std::size_t>(I * J * K), 0.0);
            for (int iz = 0; iz < K; ++iz) {
                for (int iz_next = 0; iz_next < K; ++iz_next) {
                    const double prob = transition_prob_at(input, iz, iz_next, age - 1);
                    if (prob == 0.0) {
                        continue;
                    }
                    for (int jj = 0; jj < J; ++jj) {
                        for (int ii = 0; ii < I; ++ii) {
                            transitioned[idx3(ii, jj, iz_next, I, J, K)] +=
                                prob * density_prev[idx3(ii, jj, iz, I, J, K)];
                        }
                    }
                }
            }
            density_prev = std::move(transitioned);
        }

        for (int iz = 0; iz < K; ++iz) {
            for (int jj = 0; jj < J; ++jj) {
                for (int ii = 0; ii < I; ++ii) {
                    const double mass = density_prev[idx3(ii, jj, iz, I, J, K)];
                    if (mass == 0.0) {
                        continue;
                    }
                    const std::size_t policy_idx = idx4(ii, jj, iz, age, I, J, K, A);
                    density[idx3(policy_b0[policy_idx], policy_a0[policy_idx], iz, I, J, K)] += mass;
                }
            }
        }

        density_prev = density;
        for (int iz = 0; iz < K; ++iz) {
            for (int jj = 0; jj < J; ++jj) {
                for (int ii = 0; ii < I; ++ii) {
                    const double mass = density[idx3(ii, jj, iz, I, J, K)] / static_cast<double>(A);
                    const std::size_t out_idx = idx4(ii, jj, iz, age, I, J, K, A);
                    results.dens4[out_idx] = mass;
                    results.Hdemand += input.a[static_cast<std::size_t>(jj)] * mass;
                    results.debtstock += input.b[static_cast<std::size_t>(ii)] * mass;
                }
            }
        }
    }

    results.Hsupply =
        input.supply_Hbar * std::pow(std::max(housing_price / input.supply_Pbar, 1.0e-8), input.supply_eta_s);

    return results;
}

SteadyStateResults solve_steady_state_reference(const SteadyStateInput& input) {
    return solve_steady_state_reference_branch(input, 1.0, false);
}

SteadyStatePoliticalResults solve_steady_state_political_reference(
    const SteadyStateInput& input,
    double price_multiplier) {
    if (!(price_multiplier > 0.0) || !std::isfinite(price_multiplier)) {
        throw std::runtime_error("price_multiplier must be positive and finite");
    }

    auto baseline = solve_steady_state_reference_branch(input, price_multiplier, false);
    auto perturbed = solve_steady_state_reference_branch(input, price_multiplier, true);

    if (baseline.age_valuefunctions.size() != perturbed.age_valuefunctions.size() ||
        baseline.dens4.size() != perturbed.dens4.size()) {
        throw std::runtime_error("Baseline and perturbed steady-state results have inconsistent sizes");
    }

    SteadyStatePoliticalResults results;
    results.baseline = std::move(baseline);
    results.perturbed = std::move(perturbed);
    results.price_multiplier = price_multiplier;
    results.trial_price = input.a_price;
    results.perturbed_price = input.a_price * price_multiplier;
    results.preference_sign.resize(results.baseline.age_valuefunctions.size(), 0);

    for (std::size_t idx = 0; idx < results.preference_sign.size(); ++idx) {
        const double diff = results.perturbed.age_valuefunctions[idx] - results.baseline.age_valuefunctions[idx];
        const int sign = (diff > 0.0) ? 1 : (diff < 0.0 ? -1 : 0);
        results.preference_sign[idx] = sign;
        results.totalvote += results.baseline.dens4[idx] * static_cast<double>(sign);
    }
    results.distance = results.totalvote * results.totalvote;
    return results;
}

void write_steady_state_results(const std::filesystem::path& output_dir, const SteadyStateResults& results) {
    std::filesystem::create_directories(output_dir);
    write_vector_csv(output_dir / "sidecar_age_policy_idx_b.csv", results.age_policy_idx_b);
    write_vector_csv(output_dir / "sidecar_age_policy_idx_a.csv", results.age_policy_idx_a);
    write_vector_csv(output_dir / "sidecar_age_valuefunctions.csv", results.age_valuefunctions);
    write_vector_csv(output_dir / "sidecar_dens4.csv", results.dens4);
    write_summary_csv(output_dir / "sidecar_summary.csv", results);
}

void write_steady_state_political_results(
    const std::filesystem::path& output_dir,
    const SteadyStatePoliticalResults& results) {
    std::filesystem::create_directories(output_dir);
    write_steady_state_results(output_dir / "baseline", results.baseline);
    write_steady_state_results(output_dir / "perturbed", results.perturbed);
    write_vector_csv(output_dir / "sidecar_age_preference_sign.csv", results.preference_sign);
    write_political_summary_csv(output_dir / "sidecar_political_summary.csv", results);
}

}  // namespace nimby_sidecar
