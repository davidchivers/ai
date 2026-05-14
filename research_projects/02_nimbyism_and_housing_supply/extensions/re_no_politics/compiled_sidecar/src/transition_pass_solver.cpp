#include "nimby_sidecar/transition_pass_solver.hpp"
#include "nimby_sidecar/steady_state_solver.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <numeric>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace nimby_sidecar {
namespace {

constexpr double kNaNSentinel = -9.87654321e307;

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

double require_scalar(const std::unordered_map<std::string, double>& values, const std::string& key) {
    const auto it = values.find(key);
    if (it == values.end()) {
        throw std::runtime_error("Missing scalar key: " + key);
    }
    return it->second;
}

double scalar_or_default(const std::unordered_map<std::string, double>& values, const std::string& key, double default_value) {
    const auto it = values.find(key);
    return (it == values.end()) ? default_value : it->second;
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
        if (field.empty()) {
            continue;
        }
        values.push_back(std::stod(field));
    }
    return values;
}

std::vector<int> read_single_column_int_csv(const std::filesystem::path& path) {
    std::ifstream input(path);
    if (!input) {
        throw std::runtime_error("Could not open CSV: " + path.string());
    }

    std::vector<int> values;
    std::string line;
    while (std::getline(input, line)) {
        const auto field = trim(line);
        if (field.empty()) {
            continue;
        }
        values.push_back(static_cast<int>(std::lround(std::stod(field))));
    }
    return values;
}

std::size_t idx3(int i, int j, int k, int I, int J, int /*K*/) {
    return static_cast<std::size_t>(i + I * (j + J * k));
}

std::size_t idx4(int i, int j, int k, int a, int I, int J, int K, int /*A*/) {
    return static_cast<std::size_t>(i + I * (j + J * (k + K * a)));
}

std::size_t idx5(int i, int j, int k, int a, int t, int I, int J, int K, int A, int /*T*/) {
    return static_cast<std::size_t>(i + I * (j + J * (k + K * (a + A * t))));
}

struct CoalitionVoteStats {
    double equal_weight_vote = 0.0;
    double weighted_vote = 0.0;
    double weighted_total_mass = 0.0;
    double weighted_vote_share = 0.0;
    double owner_share = 0.0;
    double old_owner_share = 0.0;
    double leveraged_owner_share = 0.0;
};

double target_age_mass_at(const TransitionPassInput& input, int t, int age) {
    return input.target_age_masses[static_cast<std::size_t>(t + input.T * age)];
}

double transition_prob_at(const TransitionPassInput& input, int current_z, int next_z, int age) {
    return input.transitionmatrix[static_cast<std::size_t>(current_z + input.K * (next_z + input.K * age))];
}

double sign_value(double value) {
    if (value > 0.0) {
        return 1.0;
    }
    if (value < 0.0) {
        return -1.0;
    }
    return 0.0;
}

CoalitionVoteStats compute_coalition_vote_stats(
    const TransitionPassInput& input,
    const std::vector<double>& density_by_period_age,
    const std::vector<double>& preference_sign,
    int t) {
    CoalitionVoteStats stats;
    double total_mass = 0.0;
    const double house_price = input.price_path[static_cast<std::size_t>(t)];
    const double housing_scale_denom = std::max(house_price * input.housing_scale, input.eps_value);

    for (int age = 0; age < input.age_n; ++age) {
        const bool old_age = (25.0 + 5.0 * static_cast<double>(age)) >= input.old_age_cutoff;
        for (int iz = 0; iz < input.K; ++iz) {
            for (int jj = 0; jj < input.J; ++jj) {
                const double housing = input.a[static_cast<std::size_t>(jj)];
                const bool owner = housing > input.owner_cutoff;
                const bool old_owner = owner && old_age;
                const double housing_value = std::max(housing * house_price, input.eps_value);
                const double housing_share = housing_value / housing_scale_denom;
                for (int ii = 0; ii < input.I; ++ii) {
                    const std::size_t idx = idx5(ii, jj, iz, age, t, input.I, input.J, input.K, input.age_n, input.T);
                    const double mass = density_by_period_age[idx];
                    const double pref = preference_sign[idx];
                    const double leverage_ratio = std::max(-input.b[static_cast<std::size_t>(ii)], 0.0) / housing_value;
                    const bool leveraged_owner = owner && (leverage_ratio >= input.leverage_cutoff);
                    const double weight = 1.0 +
                        input.alpha_owner * static_cast<double>(owner) +
                        input.alpha_old_owner * static_cast<double>(old_owner) +
                        input.alpha_leverage * static_cast<double>(leveraged_owner) +
                        input.alpha_bighouse * housing_share;

                    stats.equal_weight_vote += mass * pref;
                    stats.weighted_vote += weight * mass * pref;
                    stats.weighted_total_mass += weight * mass;
                    total_mass += mass;
                    if (owner) {
                        stats.owner_share += mass;
                    }
                    if (old_owner) {
                        stats.old_owner_share += mass;
                    }
                    if (leveraged_owner) {
                        stats.leveraged_owner_share += mass;
                    }
                }
            }
        }
    }

    stats.weighted_vote_share = stats.weighted_vote / std::max(stats.weighted_total_mass, input.eps_value);
    stats.owner_share /= std::max(total_mass, input.eps_value);
    stats.old_owner_share /= std::max(total_mass, input.eps_value);
    stats.leveraged_owner_share /= std::max(total_mass, input.eps_value);
    return stats;
}

std::vector<double> read_exact_length(const std::filesystem::path& path, std::size_t expected_size) {
    auto values = read_single_column_csv(path);
    if (values.size() != expected_size) {
        throw std::runtime_error("Unexpected length in " + path.string());
    }
    return values;
}

std::vector<int> read_exact_length_int(const std::filesystem::path& path, std::size_t expected_size) {
    auto values = read_single_column_int_csv(path);
    if (values.size() != expected_size) {
        throw std::runtime_error("Unexpected length in " + path.string());
    }
    return values;
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

void write_summary_csv(const std::filesystem::path& path, const TransitionPassResults& results) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write summary CSV: " + path.string());
    }
    output << "name,value\n";
    output << std::setprecision(17);
    output << "max_abs_gap," << results.max_abs_gap << '\n';
    output << "residual_norm," << results.residual_norm << '\n';
}

std::vector<double> copy_age_slice(const std::vector<double>& packed, int age, int I, int J, int K, int age_n) {
    std::vector<double> slice(static_cast<std::size_t>(I * J * K));
    for (int iz = 0; iz < K; ++iz) {
        for (int ij = 0; ij < J; ++ij) {
            for (int ii = 0; ii < I; ++ii) {
                slice[idx3(ii, ij, iz, I, J, K)] = packed[idx4(ii, ij, iz, age, I, J, K, age_n)];
            }
        }
    }
    return slice;
}

double utility_from_choice(double consumption, double housing_term, double omega, double eta) {
    return std::pow(std::pow(consumption, omega) * std::pow(housing_term, 1.0 - omega), 1.0 - eta) / (1.0 - eta);
}

SteadyStateInput make_steady_state_input(const TransitionPassInput& input, double price) {
    SteadyStateInput ss;
    ss.age_n = input.age_n;
    ss.I = input.I;
    ss.J = input.J;
    ss.K = input.K;
    ss.bzero = input.bzero;
    ss.a_price = price;
    ss.rb_pos = input.rb_pos;
    ss.rb_neg = input.rb_neg;
    ss.ra = input.ra;
    ss.r_price = input.r_price;
    ss.omega = input.omega;
    ss.theta_r = input.theta_r;
    ss.beta = input.beta;
    ss.eta = input.eta;
    ss.ka = input.ka;
    ss.bequestweight1 = input.bequestweight1;
    ss.bequestweight2 = input.bequestweight2;
    ss.CC = input.CC;
    ss.penalty = input.penalty;
    ss.supply_Hbar = input.supply_Hbar;
    ss.supply_Pbar = input.supply_Pbar;
    ss.supply_eta_s = input.supply_eta_s;
    ss.a = input.a;
    ss.b = input.b;
    ss.z = input.z;
    ss.Zlifecycle = input.Zlifecycle;
    ss.initialdist = input.initialdist;
    ss.transitionmatrix = input.transitionmatrix;
    return ss;
}

std::string build_steady_state_cache_key(const TransitionPassInput& input, double price) {
    std::ostringstream out;
    out << std::fixed << std::setprecision(10)
        << "p=" << price
        << "|rb=" << input.rb_pos
        << "|rh=" << input.supply_Hbar
        << "|rp=" << input.supply_Pbar
        << "|eta=" << input.supply_eta_s;
    return out.str();
}

const SteadyStateResults& get_steady_state_reference(const TransitionPassInput& input, double price) {
    static std::unordered_map<std::string, SteadyStateResults> cache;
    const std::string key = build_steady_state_cache_key(input, price);
    const auto it = cache.find(key);
    if (it != cache.end()) {
        return it->second;
    }
    auto [inserted_it, inserted] = cache.emplace(key, solve_steady_state_reference(make_steady_state_input(input, price)));
    (void)inserted;
    return inserted_it->second;
}

double decode_optional_scalar(double value) {
    return (value <= kNaNSentinel / 2.0) ? std::numeric_limits<double>::quiet_NaN() : value;
}

double resolve_terminal_reference_price(const TransitionPassInput& input) {
    const std::string mode = lowercase(trim(input.terminal_reference_mode));
    if (mode == "path_end_price") {
        return input.price_path.back();
    }
    if (mode == "initial_path_price") {
        return input.price_path.front();
    }
    if (mode == "fixed_price") {
        return input.terminal_reference_price;
    }
    if (mode == "mean_path_price") {
        double sum = 0.0;
        for (double value : input.price_path) {
            sum += value;
        }
        return sum / static_cast<double>(input.price_path.size());
    }
    throw std::runtime_error("Unsupported terminal_reference_mode in sidecar: " + input.terminal_reference_mode);
}

double resolve_policy_reference_price(const TransitionPassInput& input) {
    const std::string mode = lowercase(trim(input.policy_reference_mode));
    if (mode == "path_initial_price") {
        return input.price_path.front();
    }
    if (mode == "path_end_price") {
        return input.price_path.back();
    }
    if (mode == "path_mean_price") {
        double sum = 0.0;
        for (double value : input.price_path) {
            sum += value;
        }
        return sum / static_cast<double>(input.price_path.size());
    }
    if (mode == "fixed_price") {
        return input.policy_reference_price;
    }
    throw std::runtime_error("Unsupported policy_reference_mode in sidecar: " + input.policy_reference_mode);
}

std::vector<double> apply_policy_reference_price_bounds(const TransitionPassInput& input, std::vector<double> path) {
    const double floor_value = decode_optional_scalar(input.policy_reference_price_floor);
    const double cap_value = decode_optional_scalar(input.policy_reference_price_cap);
    if (!std::isnan(floor_value)) {
        for (double& value : path) {
            value = std::max(value, floor_value);
        }
    }
    if (!std::isnan(cap_value)) {
        for (double& value : path) {
            value = std::min(value, cap_value);
        }
    }
    return path;
}

std::vector<double> resolve_policy_reference_price_path(const TransitionPassInput& input) {
    const std::string mode = lowercase(trim(input.policy_reference_mode));
    if (mode == "path_current_prices") {
        return apply_policy_reference_price_bounds(input, input.price_path);
    }
    if (mode == "path_initial_price" || mode == "path_end_price" || mode == "path_mean_price" || mode == "fixed_price") {
        return apply_policy_reference_price_bounds(
            input, std::vector<double>(input.price_path.size(), resolve_policy_reference_price(input)));
    }
    if (mode == "blended_current_and_fixed_price") {
        std::vector<double> path(input.price_path.size(), 0.0);
        for (std::size_t i = 0; i < path.size(); ++i) {
            path[i] = (1.0 - input.policy_reference_blend_weight) * input.policy_reference_price +
                input.policy_reference_blend_weight * input.price_path[i];
        }
        return apply_policy_reference_price_bounds(input, std::move(path));
    }
    throw std::runtime_error("Unsupported policy_reference_mode for path resolution in sidecar: " + input.policy_reference_mode);
}

}  // namespace

TransitionPassInput read_transition_pass_input_pack(const std::filesystem::path& input_dir) {
    TransitionPassInput input;

    const auto meta = read_scalar_map(input_dir / "meta_scalars.csv");
    const auto meta_strings = read_optional_string_map(input_dir / "meta_strings.csv");
    input.T = static_cast<int>(std::lround(require_scalar(meta, "T")));
    input.age_n = static_cast<int>(std::lround(require_scalar(meta, "age_n")));
    input.I = static_cast<int>(std::lround(require_scalar(meta, "I")));
    input.J = static_cast<int>(std::lround(require_scalar(meta, "J")));
    input.K = static_cast<int>(std::lround(require_scalar(meta, "K")));
    input.bzero = static_cast<int>(std::lround(require_scalar(meta, "bzero")));

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
    input.terminal_reference_mode =
        string_or_default(meta_strings, "terminal_reference_mode", input.terminal_reference_mode);
    input.terminal_reference_price =
        decode_optional_scalar(scalar_or_default(meta, "terminal_reference_price", kNaNSentinel));
    input.transition_policy_mode =
        string_or_default(meta_strings, "transition_policy_mode", input.transition_policy_mode);
    input.policy_reference_mode =
        string_or_default(meta_strings, "policy_reference_mode", input.policy_reference_mode);
    input.policy_reference_price =
        decode_optional_scalar(scalar_or_default(meta, "policy_reference_price", kNaNSentinel));
    input.policy_reference_blend_weight =
        decode_optional_scalar(scalar_or_default(meta, "policy_reference_blend_weight", kNaNSentinel));
    input.policy_reference_price_floor =
        decode_optional_scalar(scalar_or_default(meta, "policy_reference_price_floor", kNaNSentinel));
    input.policy_reference_price_cap =
        decode_optional_scalar(scalar_or_default(meta, "policy_reference_price_cap", kNaNSentinel));
    input.save_period_details = scalar_or_default(meta, "save_period_details", input.save_period_details ? 1.0 : 0.0) != 0.0;
    input.compute_political_path =
        scalar_or_default(meta, "compute_political_path", input.compute_political_path ? 1.0 : 0.0) != 0.0;
    input.save_political_details =
        scalar_or_default(meta, "save_political_details", input.save_political_details ? 1.0 : 0.0) != 0.0;
    input.price_preference_multiplier =
        scalar_or_default(meta, "price_preference_multiplier", input.price_preference_multiplier);
    input.alpha_owner = scalar_or_default(meta, "alpha_owner", input.alpha_owner);
    input.alpha_old_owner = scalar_or_default(meta, "alpha_old_owner", input.alpha_old_owner);
    input.alpha_leverage = scalar_or_default(meta, "alpha_leverage", input.alpha_leverage);
    input.alpha_bighouse = scalar_or_default(meta, "alpha_bighouse", input.alpha_bighouse);
    input.owner_cutoff = scalar_or_default(meta, "owner_cutoff", input.owner_cutoff);
    input.old_age_cutoff = scalar_or_default(meta, "old_age_cutoff", input.old_age_cutoff);
    input.leverage_cutoff = scalar_or_default(meta, "leverage_cutoff", input.leverage_cutoff);
    input.housing_scale = scalar_or_default(meta, "housing_scale", input.housing_scale);
    input.eps_value = scalar_or_default(meta, "eps_value", input.eps_value);

    input.a = read_exact_length(input_dir / "a.csv", static_cast<std::size_t>(input.J));
    input.b = read_exact_length(input_dir / "b.csv", static_cast<std::size_t>(input.I));
    input.z = read_exact_length(input_dir / "z.csv", static_cast<std::size_t>(input.K));
    input.Zlifecycle = read_exact_length(input_dir / "Zlifecycle.csv", static_cast<std::size_t>(input.age_n));
    input.price_path = read_exact_length(input_dir / "price_path.csv", static_cast<std::size_t>(input.T));
    input.initialdist = read_exact_length(input_dir / "initialdist.csv", static_cast<std::size_t>(input.K));
    input.target_age_masses = read_exact_length(
        input_dir / "target_age_masses.csv",
        static_cast<std::size_t>(input.T * input.age_n));
    input.transitionmatrix = read_exact_length(
        input_dir / "transitionmatrix.csv",
        static_cast<std::size_t>(input.K * input.K * (input.age_n - 1)));
    input.initial_density = read_exact_length(
        input_dir / "initial_density.csv",
        static_cast<std::size_t>(input.I * input.J * input.K * input.age_n));
    input.terminal_age_values = read_exact_length(
        input_dir / "terminal_age_values.csv",
        static_cast<std::size_t>(input.I * input.J * input.K * input.age_n));
    const std::size_t state_count_5 = static_cast<std::size_t>(input.I * input.J * input.K * input.age_n * input.T);
    if (std::filesystem::exists(input_dir / "reference_policy_idx_b.csv")) {
        input.reference_policy_idx_b = read_exact_length_int(input_dir / "reference_policy_idx_b.csv", state_count_5);
        input.reference_policy_idx_a = read_exact_length_int(input_dir / "reference_policy_idx_a.csv", state_count_5);
        input.reference_valuefunctions = read_exact_length(input_dir / "reference_valuefunctions.csv", state_count_5);
    }

    return input;
}

TransitionPassResults solve_transition_pass(const TransitionPassInput& input) {
    const int T = input.T;
    const int A = input.age_n;
    const int I = input.I;
    const int J = input.J;
    const int K = input.K;
    const std::size_t state_count_4 = static_cast<std::size_t>(I * J * K * A);
    const std::size_t state_count_5 = static_cast<std::size_t>(I * J * K * A * T);

    TransitionPassResults results;
    results.policy_idx_b.assign(state_count_5, 0);
    results.policy_idx_a.assign(state_count_5, 0);
    results.valuefunctions.assign(state_count_5, 0.0);
    results.Hdemand_path.assign(static_cast<std::size_t>(T), 0.0);
    results.Hsupply_guess_path.assign(static_cast<std::size_t>(T), 0.0);
    results.excess_demand_guess_path.assign(static_cast<std::size_t>(T), 0.0);
    results.implied_price_path.assign(static_cast<std::size_t>(T), 0.0);
    results.log_price_residual_raw.assign(static_cast<std::size_t>(T), 0.0);
    results.debt_path.assign(static_cast<std::size_t>(T), 0.0);
    results.rent_share_path.assign(static_cast<std::size_t>(T), 0.0);
    const bool need_density_by_period = input.save_period_details || input.compute_political_path || input.save_political_details;
    if (need_density_by_period) {
        results.density_by_period_age.assign(state_count_5, 0.0);
    }
    if (input.compute_political_path) {
        results.equal_weight_vote_path.assign(static_cast<std::size_t>(T), 0.0);
        results.weighted_vote_path.assign(static_cast<std::size_t>(T), 0.0);
        results.weighted_vote_share_path.assign(static_cast<std::size_t>(T), 0.0);
        results.equal_weight_distance_path.assign(static_cast<std::size_t>(T), 0.0);
        results.weighted_distance_path.assign(static_cast<std::size_t>(T), 0.0);
        results.owner_share_path.assign(static_cast<std::size_t>(T), 0.0);
        results.old_owner_share_path.assign(static_cast<std::size_t>(T), 0.0);
        results.leveraged_owner_share_path.assign(static_cast<std::size_t>(T), 0.0);
    }

    std::vector<int> policy_b0(state_count_5, 0);
    std::vector<int> policy_a0(state_count_5, 0);
    const std::string policy_mode = lowercase(trim(input.transition_policy_mode));
    if (input.compute_political_path && !(policy_mode.empty() || policy_mode == "full_backward")) {
        throw std::runtime_error("compute_political_path is currently supported only for transition_policy_mode = full_backward.");
    }
    if (policy_mode.empty() || policy_mode == "full_backward") {
        results.terminal_reference_price_used = resolve_terminal_reference_price(input);
        const auto& terminal_reference = get_steady_state_reference(input, results.terminal_reference_price_used);
        for (int t = T - 1; t >= 0; --t) {
            const double a_price = input.price_path[static_cast<std::size_t>(t)];
            std::vector<double> Ipen(static_cast<std::size_t>(I * J), 0.0);
            for (int jj = 0; jj < J; ++jj) {
                for (int ii = 0; ii < I; ++ii) {
                    Ipen[static_cast<std::size_t>(ii + I * jj)] =
                        (-input.b[static_cast<std::size_t>(ii)] > input.a[static_cast<std::size_t>(jj)] * a_price * input.CC) ? 1.0 : 0.0;
                }
            }

            for (int age = A - 1; age >= 0; --age) {
                std::vector<double> expected_value(static_cast<std::size_t>(I * J * K), 0.0);
                bool terminal_age = (age == A - 1);

                if (!terminal_age) {
                    #ifdef _OPENMP
                    #pragma omp parallel for collapse(3) schedule(static)
                    #endif
                    for (int iz = 0; iz < K; ++iz) {
                        for (int jj = 0; jj < J; ++jj) {
                            for (int ii = 0; ii < I; ++ii) {
                                double value = 0.0;
                                for (int iz_next = 0; iz_next < K; ++iz_next) {
                                    const double prob = transition_prob_at(input, iz, iz_next, age);
                                    const double next_value =
                                        (t == T - 1)
                                            ? terminal_reference.age_valuefunctions[idx4(ii, jj, iz_next, age + 1, I, J, K, A)]
                                            : results.valuefunctions[idx5(ii, jj, iz_next, age + 1, t + 1, I, J, K, A, T)];
                                    value += prob * next_value;
                                }
                                expected_value[idx3(ii, jj, iz, I, J, K)] = value;
                            }
                        }
                    }
                }

                #ifdef _OPENMP
                #pragma omp parallel for collapse(3) schedule(static)
                #endif
                for (int iz = 0; iz < K; ++iz) {
                    const double labor_income = std::exp(input.z[static_cast<std::size_t>(iz)]) * input.Zlifecycle[static_cast<std::size_t>(age)];
                    for (int jj = 0; jj < J; ++jj) {
                        const double current_a = input.a[static_cast<std::size_t>(jj)];
                        for (int ii = 0; ii < I; ++ii) {
                            const double current_b = input.b[static_cast<std::size_t>(ii)];
                            const double wealth_flow =
                                labor_income +
                                current_b * ((current_b >= 0.0) ? input.rb_pos : input.rb_neg) +
                                current_a * a_price;

                            double best_value = -std::numeric_limits<double>::infinity();
                            int best_b = 0;
                            int best_a = 0;

                            for (int choice_a = 0; choice_a < J; ++choice_a) {
                                const double next_a = input.a[static_cast<std::size_t>(choice_a)];
                                const double adjust_cost = (next_a == current_a) ? 0.0 : input.ka;

                                for (int choice_b = 0; choice_b < I; ++choice_b) {
                                    const double next_b = input.b[static_cast<std::size_t>(choice_b)];
                                    double consumption;
                                    if (choice_a == 0) {
                                        consumption =
                                            (wealth_flow - next_a * a_price * (1.0 + adjust_cost) + current_b - next_b) /
                                            (1.0 + ((1.0 - input.omega) / input.omega * input.theta_r));
                                    } else {
                                        consumption = wealth_flow - next_a * a_price * (1.0 + adjust_cost) + current_b - next_b;
                                    }
                                    consumption = std::max(consumption, 1.0e-20);

                                    double housing_term = next_a;
                                    if (choice_a == 0) {
                                        const double rent = consumption * ((1.0 - input.omega) / input.omega / input.r_price * input.theta_r);
                                        housing_term += input.theta_r * rent;
                                    }

                                    double value = utility_from_choice(consumption, housing_term, input.omega, input.eta) -
                                        Ipen[static_cast<std::size_t>(choice_b + I * choice_a)] * input.penalty;

                                    if (terminal_age) {
                                        const double bequest = std::max(1.0e-20, next_b + a_price * next_a);
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

                            const std::size_t out_idx = idx5(ii, jj, iz, age, t, I, J, K, A, T);
                            policy_b0[out_idx] = best_b;
                            policy_a0[out_idx] = best_a;
                            results.policy_idx_b[out_idx] = best_b + 1;
                            results.policy_idx_a[out_idx] = best_a + 1;
                            results.valuefunctions[out_idx] = best_value;
                        }
                    }
                }
            }
        }
    } else if (policy_mode == "steady_state_fixed_price" || policy_mode == "steady_state_by_period_price") {
        std::vector<double> policy_reference_path;
        if (!input.reference_policy_idx_b.empty() && !input.reference_policy_idx_a.empty() &&
            !input.reference_valuefunctions.empty() && policy_mode == "steady_state_fixed_price") {
            results.policy_reference_price_path_used = resolve_policy_reference_price_path(input);
            results.policy_idx_b = input.reference_policy_idx_b;
            results.policy_idx_a = input.reference_policy_idx_a;
            results.valuefunctions = input.reference_valuefunctions;
            for (std::size_t idx = 0; idx < state_count_5; ++idx) {
                policy_b0[idx] = results.policy_idx_b[idx] - 1;
                policy_a0[idx] = results.policy_idx_a[idx] - 1;
            }
        } else {
            policy_reference_path = resolve_policy_reference_price_path(input);
            results.policy_reference_price_path_used = policy_reference_path;
            for (int t = 0; t < T; ++t) {
                const auto& reference = get_steady_state_reference(input, policy_reference_path[static_cast<std::size_t>(t)]);
                for (int age = 0; age < A; ++age) {
                    for (int iz = 0; iz < K; ++iz) {
                        for (int jj = 0; jj < J; ++jj) {
                            for (int ii = 0; ii < I; ++ii) {
                                const std::size_t ref_idx = idx4(ii, jj, iz, age, I, J, K, A);
                                const std::size_t out_idx = idx5(ii, jj, iz, age, t, I, J, K, A, T);
                                results.policy_idx_b[out_idx] = reference.age_policy_idx_b[ref_idx];
                                results.policy_idx_a[out_idx] = reference.age_policy_idx_a[ref_idx];
                                results.valuefunctions[out_idx] = reference.age_valuefunctions[ref_idx];
                                policy_b0[out_idx] = reference.age_policy_idx_b[ref_idx] - 1;
                                policy_a0[out_idx] = reference.age_policy_idx_a[ref_idx] - 1;
                            }
                        }
                    }
                }
            }
        }
    } else {
        throw std::runtime_error("Unsupported transition_policy_mode in sidecar: " + input.transition_policy_mode);
    }

    std::vector<double> current_density = input.initial_density;
    for (int t = 0; t < T; ++t) {
        std::vector<double> fallback(state_count_4, 0.0);
        for (int iz = 0; iz < K; ++iz) {
            fallback[idx4(input.bzero, 0, iz, 0, I, J, K, A)] = input.initialdist[static_cast<std::size_t>(iz)];
        }

        for (int age = 0; age < A; ++age) {
            double current_mass = 0.0;
            for (int iz = 0; iz < K; ++iz) {
                for (int jj = 0; jj < J; ++jj) {
                    for (int ii = 0; ii < I; ++ii) {
                        current_mass += current_density[idx4(ii, jj, iz, age, I, J, K, A)];
                    }
                }
            }

            const double target_mass = target_age_mass_at(input, t, age);
            if (current_mass > 0.0) {
                const double scale = target_mass / current_mass;
                for (int iz = 0; iz < K; ++iz) {
                    for (int jj = 0; jj < J; ++jj) {
                        for (int ii = 0; ii < I; ++ii) {
                            current_density[idx4(ii, jj, iz, age, I, J, K, A)] *= scale;
                        }
                    }
                }
            } else {
                for (int iz = 0; iz < K; ++iz) {
                    for (int jj = 0; jj < J; ++jj) {
                        for (int ii = 0; ii < I; ++ii) {
                            current_density[idx4(ii, jj, iz, age, I, J, K, A)] =
                                fallback[idx4(ii, jj, iz, 0, I, J, K, A)] * target_mass;
                        }
                    }
                }
            }
        }

        double period_housing = 0.0;
        double period_debt = 0.0;
        double period_renters = 0.0;
        for (int age = 0; age < A; ++age) {
            for (int iz = 0; iz < K; ++iz) {
                for (int jj = 0; jj < J; ++jj) {
                    double housing_mass = 0.0;
                    for (int ii = 0; ii < I; ++ii) {
                        const double mass = current_density[idx4(ii, jj, iz, age, I, J, K, A)];
                        if (need_density_by_period) {
                            results.density_by_period_age[idx5(ii, jj, iz, age, t, I, J, K, A, T)] = mass;
                        }
                        housing_mass += mass;
                        period_debt += input.b[static_cast<std::size_t>(ii)] * mass;
                        if (jj == 0) {
                            period_renters += mass;
                        }
                    }
                    period_housing += input.a[static_cast<std::size_t>(jj)] * housing_mass;
                }
            }
        }

        results.Hdemand_path[static_cast<std::size_t>(t)] = period_housing;
        results.debt_path[static_cast<std::size_t>(t)] = period_debt;
        results.rent_share_path[static_cast<std::size_t>(t)] = period_renters;

        if (t == T - 1) {
            continue;
        }

        std::vector<double> next_density(state_count_4, 0.0);
        for (int iz = 0; iz < K; ++iz) {
            next_density[idx4(input.bzero, 0, iz, 0, I, J, K, A)] = input.initialdist[static_cast<std::size_t>(iz)];
        }

        for (int age = 0; age < A - 1; ++age) {
            for (int iz = 0; iz < K; ++iz) {
                for (int jj = 0; jj < J; ++jj) {
                    for (int ii = 0; ii < I; ++ii) {
                        const double mass = current_density[idx4(ii, jj, iz, age, I, J, K, A)];
                        if (mass == 0.0) {
                            continue;
                        }

                        const std::size_t policy_idx = idx5(ii, jj, iz, age, t, I, J, K, A, T);
                        const int next_b = policy_b0[policy_idx];
                        const int next_a = policy_a0[policy_idx];
                        for (int iz_next = 0; iz_next < K; ++iz_next) {
                            next_density[idx4(next_b, next_a, iz_next, age + 1, I, J, K, A)] +=
                                transition_prob_at(input, iz, iz_next, age) * mass;
                        }
                    }
                }
            }
        }

        current_density = std::move(next_density);
    }

    for (int t = 0; t < T; ++t) {
        results.implied_price_path[static_cast<std::size_t>(t)] =
            input.supply_Pbar * std::pow(std::max(results.Hdemand_path[static_cast<std::size_t>(t)] / input.supply_Hbar, 1.0e-8), 1.0 / input.supply_eta_s);
        results.Hsupply_guess_path[static_cast<std::size_t>(t)] =
            input.supply_Hbar * std::pow(input.price_path[static_cast<std::size_t>(t)] / input.supply_Pbar, input.supply_eta_s);
        results.excess_demand_guess_path[static_cast<std::size_t>(t)] =
            results.Hdemand_path[static_cast<std::size_t>(t)] - results.Hsupply_guess_path[static_cast<std::size_t>(t)];
        results.log_price_residual_raw[static_cast<std::size_t>(t)] =
            std::log(results.implied_price_path[static_cast<std::size_t>(t)]) - std::log(input.price_path[static_cast<std::size_t>(t)]);
        results.max_abs_gap = std::max(
            results.max_abs_gap,
            std::abs(results.implied_price_path[static_cast<std::size_t>(t)] - input.price_path[static_cast<std::size_t>(t)]));
        results.residual_norm += std::pow(results.log_price_residual_raw[static_cast<std::size_t>(t)], 2.0);
    }
    results.residual_norm = std::sqrt(results.residual_norm);

    if (input.compute_political_path) {
        TransitionPassInput perturbed_input = input;
        for (double& price : perturbed_input.price_path) {
            price *= input.price_preference_multiplier;
        }
        perturbed_input.compute_political_path = false;
        perturbed_input.save_political_details = false;
        perturbed_input.save_period_details = false;
        perturbed_input.terminal_reference_mode = "path_end_price";
        perturbed_input.terminal_reference_price = 0.0;

        const auto perturbed_results = solve_transition_pass(perturbed_input);
        std::vector<double> preference_sign(state_count_5, 0.0);
        for (std::size_t idx = 0; idx < state_count_5; ++idx) {
            preference_sign[idx] = sign_value(perturbed_results.valuefunctions[idx] - results.valuefunctions[idx]);
        }

        for (int t = 0; t < T; ++t) {
            const auto stats = compute_coalition_vote_stats(input, results.density_by_period_age, preference_sign, t);
            results.equal_weight_vote_path[static_cast<std::size_t>(t)] = stats.equal_weight_vote;
            results.weighted_vote_path[static_cast<std::size_t>(t)] = stats.weighted_vote;
            results.weighted_vote_share_path[static_cast<std::size_t>(t)] = stats.weighted_vote_share;
            results.equal_weight_distance_path[static_cast<std::size_t>(t)] = stats.equal_weight_vote * stats.equal_weight_vote;
            results.weighted_distance_path[static_cast<std::size_t>(t)] = stats.weighted_vote * stats.weighted_vote;
            results.owner_share_path[static_cast<std::size_t>(t)] = stats.owner_share;
            results.old_owner_share_path[static_cast<std::size_t>(t)] = stats.old_owner_share;
            results.leveraged_owner_share_path[static_cast<std::size_t>(t)] = stats.leveraged_owner_share;
        }
    }

    return results;
}

void write_transition_pass_results(const std::filesystem::path& output_dir, const TransitionPassResults& results) {
    std::filesystem::create_directories(output_dir);
    write_vector_csv(output_dir / "sidecar_policy_idx_b.csv", results.policy_idx_b);
    write_vector_csv(output_dir / "sidecar_policy_idx_a.csv", results.policy_idx_a);
    write_vector_csv(output_dir / "sidecar_valuefunctions.csv", results.valuefunctions);
    write_vector_csv(output_dir / "sidecar_Hdemand_path.csv", results.Hdemand_path);
    write_vector_csv(output_dir / "sidecar_Hsupply_guess_path.csv", results.Hsupply_guess_path);
    write_vector_csv(output_dir / "sidecar_excess_demand_guess_path.csv", results.excess_demand_guess_path);
    write_vector_csv(output_dir / "sidecar_implied_price_path.csv", results.implied_price_path);
    write_vector_csv(output_dir / "sidecar_log_price_residual_raw.csv", results.log_price_residual_raw);
    write_vector_csv(output_dir / "sidecar_debt_path.csv", results.debt_path);
    write_vector_csv(output_dir / "sidecar_rent_share_path.csv", results.rent_share_path);
    if (!results.equal_weight_vote_path.empty()) {
        write_vector_csv(output_dir / "sidecar_equal_weight_vote_path.csv", results.equal_weight_vote_path);
        write_vector_csv(output_dir / "sidecar_weighted_vote_path.csv", results.weighted_vote_path);
        write_vector_csv(output_dir / "sidecar_weighted_vote_share_path.csv", results.weighted_vote_share_path);
        write_vector_csv(output_dir / "sidecar_equal_weight_distance_path.csv", results.equal_weight_distance_path);
        write_vector_csv(output_dir / "sidecar_weighted_distance_path.csv", results.weighted_distance_path);
        write_vector_csv(output_dir / "sidecar_owner_share_path.csv", results.owner_share_path);
        write_vector_csv(output_dir / "sidecar_old_owner_share_path.csv", results.old_owner_share_path);
        write_vector_csv(output_dir / "sidecar_leveraged_owner_share_path.csv", results.leveraged_owner_share_path);
    }
    if (!results.policy_reference_price_path_used.empty()) {
        write_vector_csv(output_dir / "sidecar_policy_reference_price_path_used.csv", results.policy_reference_price_path_used);
    }
    if (results.terminal_reference_price_used != 0.0) {
        std::ofstream output(output_dir / "sidecar_terminal_reference_price_used.csv");
        if (!output) {
            throw std::runtime_error("Could not write CSV: " + (output_dir / "sidecar_terminal_reference_price_used.csv").string());
        }
        output << std::setprecision(17) << results.terminal_reference_price_used << '\n';
    }
    if (!results.density_by_period_age.empty()) {
        write_vector_csv(output_dir / "sidecar_density_by_period_age.csv", results.density_by_period_age);
    }
    write_summary_csv(output_dir / "sidecar_summary.csv", results);
}

}  // namespace nimby_sidecar
