#include "nimby_sidecar/transition_re_solver.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

struct CliOptions {
    std::filesystem::path input_dir;
    std::filesystem::path output_dir;
    int max_k = -1;
    std::vector<double> alpha_grid;
    std::filesystem::path anchor_path_csv;
    std::string anchor_source;
    double gap_cutoff = 0.05;
    double price_bound_tol = 1.0e-6;
    bool resume = false;
};

struct FrontierCaseRun {
    nimby_sidecar::TransitionReResults results;
    std::string status;
    int iterations_completed = 0;
    int attempt_count = 1;
    std::string warm_start_source;
    double elapsed_seconds = 0.0;
    bool looks_stable = false;
};

struct SummaryRow {
    int k = 0;
    double alpha = std::numeric_limits<double>::quiet_NaN();
    std::string status;
    int iterations_completed = 0;
    bool converged = false;
    bool looks_stable = false;
    double residual_norm = std::numeric_limits<double>::quiet_NaN();
    double max_abs_gap = std::numeric_limits<double>::quiet_NaN();
    double max_abs_update = std::numeric_limits<double>::quiet_NaN();
    double price_min = std::numeric_limits<double>::quiet_NaN();
    double price_max = std::numeric_limits<double>::quiet_NaN();
    double path_span = std::numeric_limits<double>::quiet_NaN();
    double policy_reference_price_first_used = std::numeric_limits<double>::quiet_NaN();
    double policy_reference_price_last_used = std::numeric_limits<double>::quiet_NaN();
    std::string warm_start_source;
    double elapsed_seconds = std::numeric_limits<double>::quiet_NaN();
};

struct FrontierRow {
    int k = 0;
    double max_stable_alpha = std::numeric_limits<double>::quiet_NaN();
    double first_unstable_alpha = std::numeric_limits<double>::quiet_NaN();
    std::string frontier_status;
    double last_stable_max_abs_gap = std::numeric_limits<double>::quiet_NaN();
    double last_stable_price_min = std::numeric_limits<double>::quiet_NaN();
    double last_stable_price_max = std::numeric_limits<double>::quiet_NaN();
};

struct ResumeState {
    std::vector<SummaryRow> summary_rows;
    std::vector<FrontierRow> frontier_rows;
    std::vector<std::vector<std::optional<FrontierCaseRun>>> all_results;
    int next_k = 1;
    int current_alpha_idx = 0;
    int previous_frontier_idx = 0;
    bool is_complete = false;
};

std::string trim(const std::string& value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) {
        return "";
    }
    const auto last = value.find_last_not_of(" \t\r\n");
    std::string trimmed = value.substr(first, last - first + 1);
    if (trimmed.size() >= 2 && trimmed.front() == '"' && trimmed.back() == '"') {
        trimmed = trimmed.substr(1, trimmed.size() - 2);
    }
    return trimmed;
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

std::vector<double> read_numeric_csv(const std::filesystem::path& path) {
    std::ifstream input(path);
    if (!input) {
        throw std::runtime_error("Could not open CSV: " + path.string());
    }

    std::vector<double> values;
    std::string line;
    while (std::getline(input, line)) {
        for (const auto& field : split_csv_line(line)) {
            if (!field.empty()) {
                values.push_back(std::stod(field));
            }
        }
    }
    return values;
}

std::vector<std::unordered_map<std::string, std::string>> read_table_csv(const std::filesystem::path& path) {
    std::ifstream input(path);
    if (!input) {
        throw std::runtime_error("Could not open CSV: " + path.string());
    }

    std::string line;
    if (!std::getline(input, line)) {
        return {};
    }
    const auto headers = split_csv_line(line);
    std::vector<std::unordered_map<std::string, std::string>> rows;
    while (std::getline(input, line)) {
        if (trim(line).empty()) {
            continue;
        }
        const auto fields = split_csv_line(line);
        std::unordered_map<std::string, std::string> row;
        for (std::size_t i = 0; i < headers.size(); ++i) {
            row.emplace(headers[i], i < fields.size() ? fields[i] : "");
        }
        rows.push_back(std::move(row));
    }
    return rows;
}

double parse_optional_double(const std::string& text) {
    const auto value = trim(text);
    if (value.empty() || value == "NaN") {
        return std::numeric_limits<double>::quiet_NaN();
    }
    return std::stod(value);
}

bool parse_optional_bool(const std::string& text) {
    const auto value = trim(text);
    return value == "1" || value == "true" || value == "True";
}

std::vector<double> parse_alpha_grid(const std::string& text) {
    if (trim(text).empty()) {
        return {};
    }
    std::vector<double> values;
    for (const auto& field : split_csv_line(text)) {
        if (!field.empty()) {
            values.push_back(std::stod(field));
        }
    }
    std::sort(values.begin(), values.end());
    values.erase(std::unique(values.begin(), values.end()), values.end());
    return values;
}

std::string format_double(double value) {
    if (std::isnan(value)) {
        return "NaN";
    }
    std::ostringstream out;
    out << std::setprecision(17) << value;
    return out.str();
}

std::string format_alpha_token(double alpha) {
    std::string token = format_double(alpha);
    while (!token.empty() && token.back() == '0' && token.find('.') != std::string::npos) {
        token.pop_back();
    }
    if (!token.empty() && token.back() == '.') {
        token.pop_back();
    }
    std::replace(token.begin(), token.end(), '.', '_');
    std::replace(token.begin(), token.end(), '-', 'm');
    return token;
}

CliOptions parse_args(int argc, char** argv) {
    if (argc < 2) {
        throw std::runtime_error(
            "Usage: nimby_transition_re_frontier_cli <input_dir> [--output-dir <path>] [--max-k <int>] "
            "[--alpha-grid <comma-separated>] [--anchor-path-csv <path>] [--anchor-source <label>] "
            "[--gap-cutoff <double>] [--price-bound-tol <double>] [--resume]");
    }

    CliOptions options;
    options.input_dir = argv[1];
    options.output_dir = options.input_dir.parent_path() / (options.input_dir.filename().string() + "_frontier");

    for (int i = 2; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--output-dir") {
            options.output_dir = argv[++i];
        } else if (arg == "--max-k") {
            options.max_k = std::stoi(argv[++i]);
        } else if (arg == "--alpha-grid") {
            options.alpha_grid = parse_alpha_grid(argv[++i]);
        } else if (arg == "--anchor-path-csv") {
            options.anchor_path_csv = argv[++i];
        } else if (arg == "--anchor-source") {
            options.anchor_source = argv[++i];
        } else if (arg == "--gap-cutoff") {
            options.gap_cutoff = std::stod(argv[++i]);
        } else if (arg == "--price-bound-tol") {
            options.price_bound_tol = std::stod(argv[++i]);
        } else if (arg == "--resume") {
            options.resume = true;
        } else {
            throw std::runtime_error("Unknown argument: " + arg);
        }
    }

    return options;
}

template <typename T>
std::vector<T> take_prefix(const std::vector<T>& values, std::size_t count) {
    if (values.size() < count) {
        throw std::runtime_error("Cannot take prefix larger than vector length.");
    }
    return std::vector<T>(values.begin(), values.begin() + static_cast<std::ptrdiff_t>(count));
}

std::vector<double> truncate_target_age_masses(const std::vector<double>& values, int original_t, int age_n, int k) {
    std::vector<double> truncated(static_cast<std::size_t>(k * age_n), 0.0);
    for (int age = 0; age < age_n; ++age) {
        for (int t = 0; t < k; ++t) {
            truncated[static_cast<std::size_t>(t + k * age)] = values[static_cast<std::size_t>(t + original_t * age)];
        }
    }
    return truncated;
}

template <typename T>
std::vector<T> truncate_time_outer_tensor(const std::vector<T>& values, int original_t, int block_size, int k) {
    if (values.empty()) {
        return {};
    }
    const std::size_t expected_size = static_cast<std::size_t>(original_t * block_size);
    if (values.size() != expected_size) {
        throw std::runtime_error("Unexpected tensor length while truncating frontier input.");
    }
    std::vector<T> truncated;
    truncated.reserve(static_cast<std::size_t>(k * block_size));
    for (int t = 0; t < k; ++t) {
        const auto begin = values.begin() + static_cast<std::ptrdiff_t>(t * block_size);
        const auto end = begin + block_size;
        truncated.insert(truncated.end(), begin, end);
    }
    return truncated;
}

nimby_sidecar::TransitionPassInput truncate_transition_pass_input(
    const nimby_sidecar::TransitionPassInput& base_input,
    int k) {
    if (k < 1 || k > base_input.T) {
        throw std::runtime_error("Requested horizon is outside the base transition-pass input.");
    }

    nimby_sidecar::TransitionPassInput truncated = base_input;
    truncated.T = k;
    truncated.price_path = take_prefix(base_input.price_path, static_cast<std::size_t>(k));
    truncated.target_age_masses =
        truncate_target_age_masses(base_input.target_age_masses, base_input.T, base_input.age_n, k);

    const int tensor_block = base_input.I * base_input.J * base_input.K * base_input.age_n;
    truncated.reference_policy_idx_b =
        truncate_time_outer_tensor(base_input.reference_policy_idx_b, base_input.T, tensor_block, k);
    truncated.reference_policy_idx_a =
        truncate_time_outer_tensor(base_input.reference_policy_idx_a, base_input.T, tensor_block, k);
    truncated.reference_valuefunctions =
        truncate_time_outer_tensor(base_input.reference_valuefunctions, base_input.T, tensor_block, k);
    return truncated;
}

nimby_sidecar::TransitionReInput make_frontier_case_input(
    const nimby_sidecar::TransitionReInput& base_input,
    int k,
    double alpha,
    const std::vector<double>& guess) {
    nimby_sidecar::TransitionReInput input = base_input;
    input.transition_input = truncate_transition_pass_input(base_input.transition_input, k);
    input.transition_input.policy_reference_blend_weight = alpha;
    input.initial_price_path = guess;
    input.transition_input.price_path = guess;
    return input;
}

std::vector<double> extend_guess(const std::vector<double>& current_guess, const std::vector<double>& anchor_price_path, int k) {
    if (anchor_price_path.size() < static_cast<std::size_t>(k)) {
        throw std::runtime_error("Anchor price path is shorter than the requested horizon.");
    }
    if (current_guess.empty()) {
        return std::vector<double>(anchor_price_path.begin(), anchor_price_path.begin() + k);
    }
    if (current_guess.size() >= static_cast<std::size_t>(k)) {
        return std::vector<double>(current_guess.begin(), current_guess.begin() + k);
    }

    std::vector<double> guess = current_guess;
    guess.insert(guess.end(), anchor_price_path.begin() + static_cast<std::ptrdiff_t>(current_guess.size()), anchor_price_path.begin() + k);
    return guess;
}

bool looks_stable(
    const nimby_sidecar::TransitionReResults& results,
    const nimby_sidecar::TransitionReInput& input,
    double gap_cutoff,
    double price_bound_tol) {
    if (results.final_price_path.empty()) {
        return false;
    }

    const auto [min_it, max_it] =
        std::minmax_element(results.final_price_path.begin(), results.final_price_path.end());
    return results.final_max_abs_gap < gap_cutoff &&
           *min_it > input.options.fixed_point_price_min + price_bound_tol &&
           *max_it < input.options.fixed_point_price_max - price_bound_tol;
}

SummaryRow build_summary_row(
    int k,
    double alpha,
    const FrontierCaseRun& run) {
    SummaryRow row;
    row.k = k;
    row.alpha = alpha;
    row.status = run.status;
    row.iterations_completed = run.iterations_completed;
    row.converged = run.results.converged;
    row.looks_stable = run.looks_stable;
    row.residual_norm = run.results.final_residual_norm;
    row.max_abs_gap = run.results.final_max_abs_gap;
    row.max_abs_update = run.results.iteration_log.empty() ? std::numeric_limits<double>::quiet_NaN()
                                                           : run.results.iteration_log.back().max_abs_update;
    if (!run.results.final_price_path.empty()) {
        const auto [min_it, max_it] =
            std::minmax_element(run.results.final_price_path.begin(), run.results.final_price_path.end());
        row.price_min = *min_it;
        row.price_max = *max_it;
        row.path_span = *max_it - *min_it;
    }
    if (!run.results.policy_reference_price_path_used.empty()) {
        row.policy_reference_price_first_used = run.results.policy_reference_price_path_used.front();
        row.policy_reference_price_last_used = run.results.policy_reference_price_path_used.back();
    }
    row.warm_start_source = run.warm_start_source;
    row.elapsed_seconds = run.elapsed_seconds;
    return row;
}

FrontierRow make_frontier_row(
    int k,
    double max_stable_alpha,
    double first_unstable_alpha,
    const std::string& frontier_status,
    const std::optional<SummaryRow>& last_stable_row) {
    FrontierRow row;
    row.k = k;
    row.max_stable_alpha = max_stable_alpha;
    row.first_unstable_alpha = first_unstable_alpha;
    row.frontier_status = frontier_status;
    if (last_stable_row.has_value()) {
        row.last_stable_max_abs_gap = last_stable_row->max_abs_gap;
        row.last_stable_price_min = last_stable_row->price_min;
        row.last_stable_price_max = last_stable_row->price_max;
    }
    return row;
}

void write_summary_csv(const std::filesystem::path& path, const std::vector<SummaryRow>& rows) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write frontier summary CSV: " + path.string());
    }
    output << "k,policy_reference_blend_weight,status,iterations_completed,converged,looks_stable,residual_norm,max_abs_gap,max_abs_update,price_min,price_max,path_span,policy_reference_price_first_used,policy_reference_price_last_used,warm_start_source,elapsed_seconds\n";
    for (const auto& row : rows) {
        output << row.k << ','
               << format_double(row.alpha) << ','
               << row.status << ','
               << row.iterations_completed << ','
               << (row.converged ? 1 : 0) << ','
               << (row.looks_stable ? 1 : 0) << ','
               << format_double(row.residual_norm) << ','
               << format_double(row.max_abs_gap) << ','
               << format_double(row.max_abs_update) << ','
               << format_double(row.price_min) << ','
               << format_double(row.price_max) << ','
               << format_double(row.path_span) << ','
               << format_double(row.policy_reference_price_first_used) << ','
               << format_double(row.policy_reference_price_last_used) << ','
               << row.warm_start_source << ','
               << format_double(row.elapsed_seconds) << '\n';
    }
}

void write_frontier_csv(const std::filesystem::path& path, const std::vector<FrontierRow>& rows) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write frontier frontier CSV: " + path.string());
    }
    output << "k,max_stable_alpha,first_unstable_alpha,frontier_status,last_stable_max_abs_gap,last_stable_price_min,last_stable_price_max\n";
    for (const auto& row : rows) {
        output << row.k << ','
               << format_double(row.max_stable_alpha) << ','
               << format_double(row.first_unstable_alpha) << ','
               << row.frontier_status << ','
               << format_double(row.last_stable_max_abs_gap) << ','
               << format_double(row.last_stable_price_min) << ','
               << format_double(row.last_stable_price_max) << '\n';
    }
}

void write_attempt_summary_csv(const std::filesystem::path& path, const std::vector<FrontierCaseRun>& attempts) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write frontier attempt CSV: " + path.string());
    }
    output << "attempt,status,looks_stable,converged,iterations,final_label,final_max_abs_gap,final_residual_norm,price_min,price_max\n";
    for (std::size_t i = 0; i < attempts.size(); ++i) {
        const auto& run = attempts[i];
        double price_min = std::numeric_limits<double>::quiet_NaN();
        double price_max = std::numeric_limits<double>::quiet_NaN();
        if (!run.results.final_price_path.empty()) {
            const auto [min_it, max_it] =
                std::minmax_element(run.results.final_price_path.begin(), run.results.final_price_path.end());
            price_min = *min_it;
            price_max = *max_it;
        }
        output << (i + 1) << ','
               << run.status << ','
               << (run.looks_stable ? 1 : 0) << ','
               << (run.results.converged ? 1 : 0) << ','
               << run.results.iterations << ','
               << run.results.final_label << ','
               << format_double(run.results.final_max_abs_gap) << ','
               << format_double(run.results.final_residual_norm) << ','
               << format_double(price_min) << ','
               << format_double(price_max) << '\n';
    }
}

FrontierCaseRun solve_frontier_case(
    const nimby_sidecar::TransitionReInput& input,
    const std::string& warm_start_source,
    const std::filesystem::path& output_dir,
    double gap_cutoff,
    double price_bound_tol) {
    std::filesystem::create_directories(output_dir);
    std::vector<FrontierCaseRun> attempts;

    auto run_once = [&](const nimby_sidecar::TransitionReInput& case_input, const std::filesystem::path& attempt_dir, const std::string& status_label) {
        const auto start = std::chrono::steady_clock::now();
        const auto results = nimby_sidecar::solve_transition_re(case_input);
        const auto stop = std::chrono::steady_clock::now();
        nimby_sidecar::write_transition_re_results(attempt_dir, results);

        FrontierCaseRun run;
        run.results = results;
        run.status = status_label;
        run.iterations_completed = results.iterations;
        run.warm_start_source = warm_start_source;
        run.elapsed_seconds = std::chrono::duration<double>(stop - start).count();
        run.looks_stable = looks_stable(results, case_input, gap_cutoff, price_bound_tol);
        attempts.push_back(run);
    };

    const auto attempt1_dir = output_dir / "attempt1";
    run_once(input, attempt1_dir, "ok");
    if (attempts.front().looks_stable) {
        write_attempt_summary_csv(output_dir / "sidecar_retryaware_attempts.csv", attempts);
        return attempts.front();
    }

    nimby_sidecar::TransitionReInput retry_input = input;
    retry_input.initial_price_path = attempts.front().results.final_price_path;
    retry_input.transition_input.price_path = retry_input.initial_price_path;
    const auto attempt2_dir = output_dir / "attempt2";
    run_once(retry_input, attempt2_dir, "ok_retry_failed");
    attempts.back().warm_start_source = warm_start_source + " -> retry_from_failed_endpoint";
    attempts.back().iterations_completed = attempts.front().results.iterations + attempts.back().results.iterations;
    attempts.back().elapsed_seconds += attempts.front().elapsed_seconds;
    if (attempts.back().looks_stable) {
        attempts.back().status = "ok_after_retry";
    }

    write_attempt_summary_csv(output_dir / "sidecar_retryaware_attempts.csv", attempts);
    return attempts.back();
}

std::pair<std::vector<double>, std::string> select_warm_start(
    int k,
    int alpha_idx,
    const std::vector<std::vector<std::optional<FrontierCaseRun>>>& all_results,
    const std::vector<double>& anchor_price_path,
    const std::string& anchor_source,
    int previous_frontier_idx) {
    if (k > 1) {
        const auto& same_alpha_prior = all_results[static_cast<std::size_t>(k - 2)][static_cast<std::size_t>(alpha_idx)];
        if (same_alpha_prior.has_value()) {
            return {
                extend_guess(same_alpha_prior->results.final_price_path, anchor_price_path, k),
                "same_alpha_k_" + std::to_string(k - 1)
            };
        }
    }

    if (k > 1 && previous_frontier_idx >= 0 &&
        previous_frontier_idx < static_cast<int>(all_results[static_cast<std::size_t>(k - 2)].size())) {
        const auto& prior_frontier = all_results[static_cast<std::size_t>(k - 2)][static_cast<std::size_t>(previous_frontier_idx)];
        if (prior_frontier.has_value()) {
            return {
                extend_guess(prior_frontier->results.final_price_path, anchor_price_path, k),
                "frontier_k_" + std::to_string(k - 1) + "_alpha_idx_" + std::to_string(previous_frontier_idx + 1)
            };
        }
    }

    for (int higher_alpha_idx = alpha_idx + 1; higher_alpha_idx < static_cast<int>(all_results[static_cast<std::size_t>(k - 1)].size()); ++higher_alpha_idx) {
        const auto& same_k_higher_alpha = all_results[static_cast<std::size_t>(k - 1)][static_cast<std::size_t>(higher_alpha_idx)];
        if (same_k_higher_alpha.has_value()) {
            return {
                extend_guess(same_k_higher_alpha->results.final_price_path, anchor_price_path, k),
                "same_k_higher_alpha_idx_" + std::to_string(higher_alpha_idx + 1)
            };
        }
    }

    return {
        extend_guess({}, anchor_price_path, k),
        "anchor_prefix_" + anchor_source
    };
}

int alpha_to_index(double alpha, const std::vector<double>& alpha_grid) {
    for (int i = 0; i < static_cast<int>(alpha_grid.size()); ++i) {
        if (std::abs(alpha_grid[static_cast<std::size_t>(i)] - alpha) < 1.0e-12) {
            return i;
        }
    }
    throw std::runtime_error("Could not map alpha to frontier grid index.");
}

SummaryRow parse_summary_row(const std::unordered_map<std::string, std::string>& values) {
    SummaryRow row;
    row.k = static_cast<int>(std::lround(std::stod(values.at("k"))));
    row.alpha = parse_optional_double(values.at("policy_reference_blend_weight"));
    row.status = values.at("status");
    row.iterations_completed = static_cast<int>(std::lround(std::stod(values.at("iterations_completed"))));
    row.converged = parse_optional_bool(values.at("converged"));
    row.looks_stable = parse_optional_bool(values.at("looks_stable"));
    row.residual_norm = parse_optional_double(values.at("residual_norm"));
    row.max_abs_gap = parse_optional_double(values.at("max_abs_gap"));
    row.max_abs_update = parse_optional_double(values.at("max_abs_update"));
    row.price_min = parse_optional_double(values.at("price_min"));
    row.price_max = parse_optional_double(values.at("price_max"));
    row.path_span = parse_optional_double(values.at("path_span"));
    row.policy_reference_price_first_used = parse_optional_double(values.at("policy_reference_price_first_used"));
    row.policy_reference_price_last_used = parse_optional_double(values.at("policy_reference_price_last_used"));
    row.warm_start_source = values.at("warm_start_source");
    row.elapsed_seconds = parse_optional_double(values.at("elapsed_seconds"));
    return row;
}

FrontierRow parse_frontier_row(const std::unordered_map<std::string, std::string>& values) {
    FrontierRow row;
    row.k = static_cast<int>(std::lround(std::stod(values.at("k"))));
    row.max_stable_alpha = parse_optional_double(values.at("max_stable_alpha"));
    row.first_unstable_alpha = parse_optional_double(values.at("first_unstable_alpha"));
    row.frontier_status = values.at("frontier_status");
    row.last_stable_max_abs_gap = parse_optional_double(values.at("last_stable_max_abs_gap"));
    row.last_stable_price_min = parse_optional_double(values.at("last_stable_price_min"));
    row.last_stable_price_max = parse_optional_double(values.at("last_stable_price_max"));
    return row;
}

std::filesystem::path selected_attempt_dir(
    const std::filesystem::path& output_dir,
    int k,
    double alpha,
    const std::string& status) {
    const auto case_dir =
        output_dir / ("k_" + std::to_string(k)) / ("alpha_" + format_alpha_token(alpha));
    if (status == "ok") {
        return case_dir / "attempt1";
    }
    return case_dir / "attempt2";
}

ResumeState initialize_resume_state(
    const CliOptions& options,
    int max_k,
    const std::vector<double>& alpha_grid) {
    ResumeState state;
    state.all_results.assign(
        static_cast<std::size_t>(max_k),
        std::vector<std::optional<FrontierCaseRun>>(alpha_grid.size()));
    state.previous_frontier_idx = static_cast<int>(alpha_grid.size()) - 1;
    state.current_alpha_idx = state.previous_frontier_idx;

    if (!options.resume) {
        return state;
    }

    const auto live_summary = options.output_dir / "sidecar_frontier_summary_live.csv";
    const auto live_frontier = options.output_dir / "sidecar_frontier_live.csv";
    const auto final_summary = options.output_dir / "sidecar_frontier_summary.csv";
    const auto final_frontier = options.output_dir / "sidecar_frontier.csv";

    const auto summary_path = std::filesystem::exists(live_summary) ? live_summary : final_summary;
    const auto frontier_path = std::filesystem::exists(live_frontier) ? live_frontier : final_frontier;

    if (std::filesystem::exists(summary_path)) {
        for (const auto& row_values : read_table_csv(summary_path)) {
            auto row = parse_summary_row(row_values);
            state.summary_rows.push_back(row);

            FrontierCaseRun run;
            run.status = row.status;
            run.iterations_completed = row.iterations_completed;
            run.warm_start_source = row.warm_start_source;
            run.elapsed_seconds = row.elapsed_seconds;
            run.looks_stable = row.looks_stable;
            run.results.converged = row.converged;
            run.results.iterations = row.iterations_completed;
            run.results.final_residual_norm = row.residual_norm;
            run.results.final_max_abs_gap = row.max_abs_gap;

            const auto attempt_dir = selected_attempt_dir(options.output_dir, row.k, row.alpha, row.status);
            const auto final_price_path = attempt_dir / "sidecar_re_final_price_path.csv";
            const auto policy_ref_path = attempt_dir / "sidecar_re_policy_reference_price_path_used.csv";
            if (std::filesystem::exists(final_price_path)) {
                run.results.final_price_path = read_numeric_csv(final_price_path);
            }
            if (std::filesystem::exists(policy_ref_path)) {
                run.results.policy_reference_price_path_used = read_numeric_csv(policy_ref_path);
            }
            const int alpha_idx = alpha_to_index(row.alpha, alpha_grid);
            state.all_results[static_cast<std::size_t>(row.k - 1)][static_cast<std::size_t>(alpha_idx)] = std::move(run);
        }
    }

    if (std::filesystem::exists(frontier_path)) {
        for (const auto& row_values : read_table_csv(frontier_path)) {
            state.frontier_rows.push_back(parse_frontier_row(row_values));
        }
    }

    while (static_cast<int>(state.frontier_rows.size()) < max_k) {
        const int current_k = static_cast<int>(state.frontier_rows.size()) + 1;
        bool found_stable = false;
        bool found_any = false;
        SummaryRow best_stable_row;
        double first_unstable_alpha = std::numeric_limits<double>::quiet_NaN();
        for (const auto& row : state.summary_rows) {
            if (row.k != current_k) {
                continue;
            }
            found_any = true;
            if (row.looks_stable) {
                best_stable_row = row;
                found_stable = true;
                break;
            }
            if (std::isnan(first_unstable_alpha)) {
                first_unstable_alpha = row.alpha;
            }
        }
        if (!found_stable) {
            break;
        }
        state.frontier_rows.push_back(make_frontier_row(
            current_k,
            best_stable_row.alpha,
            first_unstable_alpha,
            "found_stable_alpha",
            best_stable_row));
    }

    if (!state.frontier_rows.empty()) {
        const auto& last = state.frontier_rows.back();
        state.next_k = last.k + 1;
        if (std::isnan(last.max_stable_alpha)) {
            state.previous_frontier_idx = 0;
        } else {
            state.previous_frontier_idx = alpha_to_index(last.max_stable_alpha, alpha_grid);
        }
        state.current_alpha_idx = state.previous_frontier_idx;
    }

    if (state.next_k <= max_k) {
        int lowest_tested_idx = std::numeric_limits<int>::max();
        bool found_row_for_next_k = false;
        for (const auto& row : state.summary_rows) {
            if (row.k != state.next_k) {
                continue;
            }
            found_row_for_next_k = true;
            lowest_tested_idx = std::min(lowest_tested_idx, alpha_to_index(row.alpha, alpha_grid));
        }
        if (found_row_for_next_k) {
            state.current_alpha_idx = lowest_tested_idx - 1;
        }
    }

    if (state.next_k > max_k) {
        state.is_complete = true;
    }

    return state;
}

}  // namespace

int main(int argc, char** argv) {
    try {
        const auto options = parse_args(argc, argv);
        const auto base_input = nimby_sidecar::read_transition_re_input_pack(options.input_dir);

        const int base_horizon = static_cast<int>(base_input.initial_price_path.size());
        const int max_k = (options.max_k < 1) ? base_horizon : std::min(options.max_k, base_horizon);
        std::vector<double> alpha_grid = options.alpha_grid;
        if (alpha_grid.empty()) {
            alpha_grid.push_back(base_input.transition_input.policy_reference_blend_weight);
        }
        std::sort(alpha_grid.begin(), alpha_grid.end());
        alpha_grid.erase(std::unique(alpha_grid.begin(), alpha_grid.end()), alpha_grid.end());

        std::vector<double> anchor_price_path = options.anchor_path_csv.empty()
            ? base_input.initial_price_path
            : read_numeric_csv(options.anchor_path_csv);
        if (anchor_price_path.size() < static_cast<std::size_t>(max_k)) {
            throw std::runtime_error("Anchor path is shorter than the requested max horizon.");
        }
        const std::string anchor_source =
            options.anchor_source.empty()
                ? (options.anchor_path_csv.empty() ? "base_input_initial_price_path" : options.anchor_path_csv.string())
                : options.anchor_source;

        std::filesystem::create_directories(options.output_dir);

        auto resume_state = initialize_resume_state(options, max_k, alpha_grid);
        auto& all_results = resume_state.all_results;
        auto& summary_rows = resume_state.summary_rows;
        auto& frontier_rows = resume_state.frontier_rows;
        int previous_frontier_idx = resume_state.previous_frontier_idx;
        int next_k = resume_state.next_k;
        int initial_alpha_idx = resume_state.current_alpha_idx;

        if (resume_state.is_complete) {
            std::cout << "Solved NIMBY frontier scan\n";
            std::cout << "  input_dir: " << options.input_dir.string() << '\n';
            std::cout << "  output_dir: " << options.output_dir.string() << '\n';
            std::cout << "  max_k: " << max_k << '\n';
            std::cout << "  alpha_count: " << alpha_grid.size() << '\n';
            std::cout << "  resume_status: already_complete\n";
            return 0;
        }

        for (int k = next_k; k <= max_k; ++k) {
            double max_stable_alpha = std::numeric_limits<double>::quiet_NaN();
            double first_unstable_alpha = std::numeric_limits<double>::quiet_NaN();
            std::optional<SummaryRow> last_stable_row;
            int current_alpha_idx = (k == next_k) ? initial_alpha_idx : previous_frontier_idx;

            while (current_alpha_idx >= 0) {
                const double alpha = alpha_grid[static_cast<std::size_t>(current_alpha_idx)];
                if (all_results[static_cast<std::size_t>(k - 1)][static_cast<std::size_t>(current_alpha_idx)].has_value()) {
                    const auto& prior_run = all_results[static_cast<std::size_t>(k - 1)][static_cast<std::size_t>(current_alpha_idx)].value();
                    const SummaryRow row = build_summary_row(k, alpha, prior_run);
                    if (row.looks_stable) {
                        max_stable_alpha = alpha;
                        last_stable_row = row;
                        frontier_rows.push_back(make_frontier_row(
                            k,
                            max_stable_alpha,
                            first_unstable_alpha,
                            "found_stable_alpha",
                            last_stable_row));
                        previous_frontier_idx = current_alpha_idx;
                        break;
                    }
                    if (std::isnan(first_unstable_alpha)) {
                        first_unstable_alpha = alpha;
                    }
                    --current_alpha_idx;
                    continue;
                }

                const auto [guess, warm_start_source] = select_warm_start(
                    k, current_alpha_idx, all_results, anchor_price_path, anchor_source, previous_frontier_idx);
                auto case_input = make_frontier_case_input(base_input, k, alpha, guess);

                const auto case_dir =
                    options.output_dir / ("k_" + std::to_string(k)) / ("alpha_" + format_alpha_token(alpha));
                const auto run = solve_frontier_case(
                    case_input,
                    warm_start_source,
                    case_dir,
                    options.gap_cutoff,
                    options.price_bound_tol);

                all_results[static_cast<std::size_t>(k - 1)][static_cast<std::size_t>(current_alpha_idx)] = run;
                summary_rows.push_back(build_summary_row(k, alpha, run));

                if (run.looks_stable) {
                    max_stable_alpha = alpha;
                    last_stable_row = summary_rows.back();
                    frontier_rows.push_back(make_frontier_row(
                        k,
                        max_stable_alpha,
                        first_unstable_alpha,
                        "found_stable_alpha",
                        last_stable_row));
                    previous_frontier_idx = current_alpha_idx;
                    break;
                }

                if (std::isnan(first_unstable_alpha)) {
                    first_unstable_alpha = alpha;
                }
                --current_alpha_idx;
            }

            if (current_alpha_idx < 0) {
                frontier_rows.push_back(make_frontier_row(
                    k,
                    max_stable_alpha,
                    first_unstable_alpha,
                    "no_stable_alpha_found",
                    last_stable_row));
                previous_frontier_idx = 0;
            }

            write_summary_csv(options.output_dir / "sidecar_frontier_summary_live.csv", summary_rows);
            write_frontier_csv(options.output_dir / "sidecar_frontier_live.csv", frontier_rows);
        }

        write_summary_csv(options.output_dir / "sidecar_frontier_summary.csv", summary_rows);
        write_frontier_csv(options.output_dir / "sidecar_frontier.csv", frontier_rows);

        std::cout << "Solved NIMBY frontier scan\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  max_k: " << max_k << '\n';
        std::cout << "  alpha_count: " << alpha_grid.size() << '\n';
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_transition_re_frontier_cli error: " << ex.what() << '\n';
        return 1;
    }
}
