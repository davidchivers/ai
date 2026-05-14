#include "nimby_sidecar/reduced_form_solver.hpp"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iomanip>
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

double require_scalar(const std::unordered_map<std::string, double>& values, const std::string& key) {
    const auto it = values.find(key);
    if (it == values.end()) {
        throw std::runtime_error("Missing scalar key: " + key);
    }
    return it->second;
}

std::vector<double> read_single_column_csv(const std::filesystem::path& path) {
    std::ifstream input(path);
    if (!input) {
        throw std::runtime_error("Could not open vector CSV: " + path.string());
    }

    std::string line;
    if (!std::getline(input, line)) {
        throw std::runtime_error("Vector CSV is empty: " + path.string());
    }

    std::vector<double> values;
    while (std::getline(input, line)) {
        if (trim(line).empty()) {
            continue;
        }
        values.push_back(std::stod(trim(line)));
    }
    return values;
}

ReducedFormOperator read_operator(const std::filesystem::path& input_dir) {
    ReducedFormOperator operator_data;

    const auto scalars = read_scalar_map(input_dir / "operator_scalars.csv");
    operator_data.intercept = require_scalar(scalars, "intercept");
    operator_data.pressure_coeff = require_scalar(scalars, "pressure_coeff");
    operator_data.next_price_coeff = require_scalar(scalars, "next_price_coeff");
    operator_data.baseline_price = require_scalar(scalars, "baseline_price");
    operator_data.tail_price = require_scalar(scalars, "tail_price");
    operator_data.log_baseline_price = require_scalar(scalars, "log_baseline_price");

    std::ifstream input(input_dir / "operator_path.csv");
    if (!input) {
        throw std::runtime_error("Could not open operator_path.csv");
    }

    std::string line;
    if (!std::getline(input, line)) {
        throw std::runtime_error("operator_path.csv is empty");
    }

    while (std::getline(input, line)) {
        if (trim(line).empty()) {
            continue;
        }
        const auto fields = split_csv_line(line);
        if (fields.size() != 5) {
            throw std::runtime_error("operator_path.csv must have 5 columns");
        }
        operator_data.periods.push_back(static_cast<int>(std::lround(std::stod(fields[0]))));
        operator_data.years.push_back(static_cast<int>(std::lround(std::stod(fields[1]))));
        operator_data.pressure_index.push_back(std::stod(fields[2]));
        operator_data.young_share_25_44.push_back(std::stod(fields[3]));
        operator_data.benchmark_price_path.push_back(std::stod(fields[4]));
    }

    return operator_data;
}

ReducedFormParams read_params(const std::filesystem::path& input_dir) {
    ReducedFormParams params;
    const auto values = read_scalar_map(input_dir / "params_scalars.csv");
    params.k = static_cast<int>(std::lround(require_scalar(values, "k")));
    params.start_index = static_cast<int>(std::lround(require_scalar(values, "start_index")));
    params.max_iter = static_cast<int>(std::lround(require_scalar(values, "max_iter")));
    params.tol = require_scalar(values, "tol");
    params.relaxation_weight = require_scalar(values, "relaxation_weight");
    params.re_weight = require_scalar(values, "re_weight");
    params.price_min = require_scalar(values, "price_min");
    params.price_max = require_scalar(values, "price_max");
    params.tail_price = require_scalar(values, "tail_price");
    return params;
}

std::vector<double> extend_guess(const std::vector<double>& initial_guess, double tail_price, int k) {
    if (initial_guess.empty()) {
        return std::vector<double>(static_cast<std::size_t>(k), tail_price);
    }

    std::vector<double> guess = initial_guess;
    if (static_cast<int>(guess.size()) >= k) {
        guess.resize(static_cast<std::size_t>(k));
        return guess;
    }

    guess.resize(static_cast<std::size_t>(k), tail_price);
    return guess;
}

struct ImpliedPath {
    std::vector<double> unbounded;
    std::vector<double> bounded;
    std::vector<double> next_reference;
};

ImpliedPath compute_implied_path(
    const std::vector<double>& guess,
    const ReducedFormOperator& operator_data,
    int k,
    const ReducedFormParams& params,
    int start_index_zero) {

    ImpliedPath path;
    path.unbounded.resize(static_cast<std::size_t>(k));
    path.bounded.resize(static_cast<std::size_t>(k));
    path.next_reference.resize(static_cast<std::size_t>(k));

    if (k == 1) {
        path.next_reference[0] = params.tail_price;
    } else {
        for (int i = 0; i < k - 1; ++i) {
            path.next_reference[static_cast<std::size_t>(i)] = guess[static_cast<std::size_t>(i + 1)];
        }
        path.next_reference[static_cast<std::size_t>(k - 1)] = params.tail_price;
    }

    for (int i = 0; i < k; ++i) {
        const double next_log_gap =
            std::log(path.next_reference[static_cast<std::size_t>(i)]) - operator_data.log_baseline_price;
        const double implied_log_price =
            operator_data.intercept +
            operator_data.pressure_coeff * operator_data.pressure_index[static_cast<std::size_t>(start_index_zero + i)] +
            params.re_weight * operator_data.next_price_coeff * next_log_gap;
        const double implied_unbounded = std::exp(implied_log_price);
        const double implied_bounded = std::min(std::max(implied_unbounded, params.price_min), params.price_max);
        path.unbounded[static_cast<std::size_t>(i)] = implied_unbounded;
        path.bounded[static_cast<std::size_t>(i)] = implied_bounded;
    }

    return path;
}

void write_solution_path_csv(const std::filesystem::path& path, const ReducedFormResults& results) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write solution path CSV: " + path.string());
    }

    output << "period,year,pressure_index,young_share_25_44,final_price,implied_price,implied_price_unbounded,next_price_reference\n";
    output << std::setprecision(17);
    for (std::size_t i = 0; i < results.final_price_path.size(); ++i) {
        output << results.periods[i] << ','
               << results.years[i] << ','
               << results.pressure_index[i] << ','
               << results.young_share_25_44[i] << ','
               << results.final_price_path[i] << ','
               << results.implied_price_path[i] << ','
               << results.implied_price_path_unbounded[i] << ','
               << results.next_price_reference[i] << '\n';
    }
}

void write_iteration_log_csv(const std::filesystem::path& path, const ReducedFormResults& results) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write iteration log CSV: " + path.string());
    }

    output << "iteration,max_abs_gap,max_abs_log_gap,price_min,price_max\n";
    output << std::setprecision(17);
    for (const auto& record : results.iteration_log) {
        output << record.iteration << ','
               << record.max_abs_gap << ','
               << record.max_abs_log_gap << ','
               << record.price_min << ','
               << record.price_max << '\n';
    }
}

void write_summary_csv(const std::filesystem::path& path, const ReducedFormResults& results) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write summary CSV: " + path.string());
    }

    output << "name,value\n";
    output << std::setprecision(17);
    output << "status," << results.status << '\n';
    output << "converged," << (results.converged ? "true" : "false") << '\n';
    output << "iterations_completed," << results.iterations_completed << '\n';
    output << "k," << results.k << '\n';
    output << "start_index," << results.start_index << '\n';
    output << "re_weight," << results.re_weight << '\n';
    output << "relaxation_weight," << results.relaxation_weight << '\n';
    output << "price_min," << results.price_min << '\n';
    output << "price_max," << results.price_max << '\n';
    output << "tail_price," << results.tail_price << '\n';
    output << "max_abs_gap," << results.max_abs_gap << '\n';
    output << "max_abs_log_gap," << results.max_abs_log_gap << '\n';
    output << "path_span," << results.path_span << '\n';
    output << "hits_bound," << (results.hits_bound ? "true" : "false") << '\n';
    output << "looks_stable," << (results.looks_stable ? "true" : "false") << '\n';
}

}  // namespace

ReducedFormInputPack read_reduced_form_input_pack(const std::filesystem::path& input_dir) {
    if (!std::filesystem::exists(input_dir)) {
        throw std::runtime_error("Input directory does not exist: " + input_dir.string());
    }

    ReducedFormInputPack pack;
    pack.input_dir = input_dir;
    pack.operator_data = read_operator(input_dir);
    pack.params = read_params(input_dir);
    pack.initial_guess = read_single_column_csv(input_dir / "initial_guess.csv");
    return pack;
}

ReducedFormResults solve_reduced_form_price_path(
    const ReducedFormOperator& operator_data,
    ReducedFormParams params,
    const std::vector<double>& initial_guess) {

    const int total_periods = static_cast<int>(operator_data.periods.size());
    const int start_index_zero = params.start_index - 1;
    if (start_index_zero < 0 || start_index_zero >= total_periods) {
        throw std::runtime_error("start_index is outside the operator horizon");
    }
    const int max_horizon = total_periods - start_index_zero;
    const int k = std::min(std::max(params.k, 1), max_horizon);
    params.k = k;

    std::vector<double> guess = extend_guess(initial_guess, params.tail_price, k);
    std::vector<IterationRecord> iteration_log;
    iteration_log.reserve(static_cast<std::size_t>(params.max_iter));

    bool converged = false;
    int iterations_completed = 0;

    for (int iter = 1; iter <= params.max_iter; ++iter) {
        const auto implied = compute_implied_path(guess, operator_data, k, params, start_index_zero);
        std::vector<double> updated_guess(static_cast<std::size_t>(k));

        double max_abs_gap = 0.0;
        double max_abs_log_gap = 0.0;
        for (int i = 0; i < k; ++i) {
            const double log_guess = std::log(guess[static_cast<std::size_t>(i)]);
            const double log_implied = std::log(implied.bounded[static_cast<std::size_t>(i)]);
            const double updated_log_guess =
                (1.0 - params.relaxation_weight) * log_guess +
                params.relaxation_weight * log_implied;
            updated_guess[static_cast<std::size_t>(i)] = std::exp(updated_log_guess);

            max_abs_gap = std::max(
                max_abs_gap,
                std::abs(implied.bounded[static_cast<std::size_t>(i)] - guess[static_cast<std::size_t>(i)]));
            max_abs_log_gap = std::max(max_abs_log_gap, std::abs(log_implied - log_guess));
        }

        iteration_log.push_back(IterationRecord{
            iter,
            max_abs_gap,
            max_abs_log_gap,
            *std::min_element(updated_guess.begin(), updated_guess.end()),
            *std::max_element(updated_guess.begin(), updated_guess.end())});

        guess = std::move(updated_guess);
        iterations_completed = iter;
        if (max_abs_log_gap < params.tol) {
            converged = true;
            break;
        }
    }

    const auto implied = compute_implied_path(guess, operator_data, k, params, start_index_zero);
    const double tol = 1.0e-8;
    const bool hits_bound =
        std::any_of(guess.begin(), guess.end(), [&](double price) {
            return price <= params.price_min + tol || price >= params.price_max - tol;
        });

    ReducedFormResults results;
    results.converged = converged;
    results.iterations_completed = iterations_completed;
    results.k = k;
    results.start_index = params.start_index;
    results.re_weight = params.re_weight;
    results.relaxation_weight = params.relaxation_weight;
    results.price_min = params.price_min;
    results.price_max = params.price_max;
    results.tail_price = params.tail_price;
    results.final_price_path = guess;
    results.implied_price_path = implied.bounded;
    results.implied_price_path_unbounded = implied.unbounded;
    results.next_price_reference = implied.next_reference;
    results.iteration_log = std::move(iteration_log);
    results.hits_bound = hits_bound;
    results.max_abs_gap = 0.0;
    results.max_abs_log_gap = 0.0;

    for (int i = 0; i < k; ++i) {
        results.max_abs_gap = std::max(
            results.max_abs_gap,
            std::abs(results.implied_price_path[static_cast<std::size_t>(i)] - results.final_price_path[static_cast<std::size_t>(i)]));
        results.max_abs_log_gap = std::max(
            results.max_abs_log_gap,
            std::abs(std::log(results.implied_price_path[static_cast<std::size_t>(i)]) -
                     std::log(results.final_price_path[static_cast<std::size_t>(i)])));
    }

    const auto [min_it, max_it] = std::minmax_element(results.final_price_path.begin(), results.final_price_path.end());
    results.path_span = *max_it - *min_it;
    results.looks_stable = results.converged && !results.hits_bound && results.max_abs_gap < 0.01;

    results.pressure_index.assign(
        operator_data.pressure_index.begin() + start_index_zero,
        operator_data.pressure_index.begin() + start_index_zero + k);
    results.young_share_25_44.assign(
        operator_data.young_share_25_44.begin() + start_index_zero,
        operator_data.young_share_25_44.begin() + start_index_zero + k);
    results.periods.assign(
        operator_data.periods.begin() + start_index_zero,
        operator_data.periods.begin() + start_index_zero + k);
    results.years.assign(
        operator_data.years.begin() + start_index_zero,
        operator_data.years.begin() + start_index_zero + k);

    if (results.converged) {
        results.status = "converged";
    } else if (results.hits_bound) {
        results.status = "out_of_bounds";
    } else {
        results.status = "max_iter";
    }

    return results;
}

void write_reduced_form_results(const std::filesystem::path& output_dir, const ReducedFormResults& results) {
    std::filesystem::create_directories(output_dir);
    write_solution_path_csv(output_dir / "sidecar_solution_path.csv", results);
    write_iteration_log_csv(output_dir / "sidecar_iteration_log.csv", results);
    write_summary_csv(output_dir / "sidecar_summary.csv", results);
}

}  // namespace nimby_sidecar
