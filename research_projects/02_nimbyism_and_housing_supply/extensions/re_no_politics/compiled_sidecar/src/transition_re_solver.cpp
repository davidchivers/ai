#include "nimby_sidecar/transition_re_solver.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <limits>
#include <sstream>
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
        if (!field.empty()) {
            values.push_back(std::stod(field));
        }
    }
    return values;
}

struct UpdateDiagnostics {
    std::vector<double> smoothed_implied_price_path;
    std::vector<double> log_update_step;
    std::vector<int> targeted_periods;  // zero-based
    std::vector<std::pair<int, int>> targeted_blocks;
};

struct FocusMetrics {
    double gap = 0.0;
    double excess = 0.0;
};

struct CandidateSelectionAssessment {
    double candidate_focus_gap = 0.0;
    double candidate_focus_excess = 0.0;
    double incumbent_focus_gap = 0.0;
    double incumbent_focus_excess = 0.0;
    bool wins_focus = false;
    bool wins_global = false;
    bool sequential_wins = false;
    bool greedy_global = false;
    bool greedy_sequential = false;
    std::string sequential_reason;
    std::string greedy_reason;
};

std::string candidate_selection_mode(const TransitionReOptions& options);

double max_abs_diff(const std::vector<double>& a, const std::vector<double>& b) {
    double max_value = 0.0;
    for (std::size_t i = 0; i < a.size(); ++i) {
        max_value = std::max(max_value, std::abs(a[i] - b[i]));
    }
    return max_value;
}

double quiet_nan() {
    return std::numeric_limits<double>::quiet_NaN();
}

std::vector<int> to_one_based_periods(const std::vector<int>& zero_based_periods) {
    std::vector<int> one_based;
    one_based.reserve(zero_based_periods.size());
    for (int period : zero_based_periods) {
        one_based.push_back(period + 1);
    }
    return one_based;
}

std::vector<std::pair<int, int>> to_one_based_blocks(const std::vector<std::pair<int, int>>& zero_based_blocks) {
    std::vector<std::pair<int, int>> one_based;
    one_based.reserve(zero_based_blocks.size());
    for (const auto& block : zero_based_blocks) {
        one_based.emplace_back(block.first + 1, block.second + 1);
    }
    return one_based;
}

std::string selection_reason(const std::string& mode, bool focus_flag, bool global_flag, bool overall_flag) {
    if (!overall_flag) {
        return "none";
    }
    if (mode == "focus") {
        return "focus";
    }
    if (mode == "hybrid_focus") {
        if (focus_flag && global_flag) {
            return "focus+global";
        }
        if (focus_flag) {
            return "focus";
        }
        return "global";
    }
    return "global";
}

IterationSelectionDiagnostic initialize_iteration_selection_detail(
    int iteration,
    const std::string& current_label,
    const TransitionPassResults& current_run,
    const UpdateDiagnostics& diagnostics,
    const TransitionReOptions& options) {
    IterationSelectionDiagnostic detail;
    detail.iteration = iteration;
    detail.candidate_selection_mode = candidate_selection_mode(options);
    detail.current_label = current_label;
    detail.current_residual_norm = current_run.residual_norm;
    detail.current_max_abs_gap = current_run.max_abs_gap;
    detail.targeted_periods = to_one_based_periods(diagnostics.targeted_periods);
    detail.targeted_blocks = to_one_based_blocks(diagnostics.targeted_blocks);
    return detail;
}

SequentialDiagnostic initialize_sequential_detail(const std::string& current_label, const TransitionReOptions& options) {
    SequentialDiagnostic detail;
    detail.selection_mode = candidate_selection_mode(options);
    detail.start_label = current_label;
    return detail;
}

PassDiagnostic initialize_pass_detail(
    int pass,
    const std::string& current_label,
    const std::vector<int>& zero_based_focus_periods,
    const std::vector<int>& zero_based_block_starts,
    const UpdateDiagnostics& diagnostics) {
    PassDiagnostic detail;
    detail.pass = pass;
    detail.start_label = current_label;
    detail.focus_periods = to_one_based_periods(zero_based_focus_periods);
    detail.targeted_periods = to_one_based_periods(diagnostics.targeted_periods);
    detail.targeted_blocks = to_one_based_blocks(diagnostics.targeted_blocks);
    detail.block_starts.reserve(zero_based_block_starts.size());
    for (int start_idx : zero_based_block_starts) {
        detail.block_starts.push_back(start_idx + 1);
    }
    return detail;
}

void append_candidate_detail(
    std::vector<CandidateDiagnostic>& details,
    const std::string& stage,
    int pass,
    const std::string& candidate_label,
    const TransitionPassResults& candidate_run,
    const std::string& incumbent_label,
    const TransitionPassResults& incumbent_run,
    const std::vector<int>& zero_based_focus_periods,
    const CandidateSelectionAssessment& assessment,
    double block_start,
    double block_stop,
    double scale,
    bool became_best,
    bool accepted_greedily) {
    CandidateDiagnostic entry;
    entry.stage = stage;
    entry.pass = static_cast<double>(pass);
    entry.candidate_label = candidate_label;
    entry.incumbent_label = incumbent_label;
    entry.block_start = block_start;
    entry.block_stop = block_stop;
    entry.scale = scale;
    entry.focus_periods = to_one_based_periods(zero_based_focus_periods);
    entry.candidate_residual_norm = candidate_run.residual_norm;
    entry.candidate_max_abs_gap = candidate_run.max_abs_gap;
    entry.candidate_focus_gap = assessment.candidate_focus_gap;
    entry.candidate_focus_excess = assessment.candidate_focus_excess;
    entry.incumbent_residual_norm = incumbent_run.residual_norm;
    entry.incumbent_max_abs_gap = incumbent_run.max_abs_gap;
    entry.incumbent_focus_gap = assessment.incumbent_focus_gap;
    entry.incumbent_focus_excess = assessment.incumbent_focus_excess;
    entry.wins_focus = assessment.wins_focus;
    entry.wins_global = assessment.wins_global;
    entry.wins_sequential = assessment.sequential_wins;
    entry.greedy_global = assessment.greedy_global;
    entry.greedy_sequential = assessment.greedy_sequential;
    entry.selection_reason = assessment.sequential_reason;
    entry.greedy_reason = assessment.greedy_reason;
    entry.became_best = became_best;
    entry.accepted_greedily = accepted_greedily;
    details.push_back(std::move(entry));
}

std::vector<double> smooth_price_path(const std::vector<double>& raw_path, const std::vector<double>& current_path, const TransitionReOptions& options) {
    const int T = static_cast<int>(raw_path.size());
    if (T == 1) {
        return raw_path;
    }

    std::vector<double> log_raw(T), log_current(T), local_average(T), smoothed_log(T);
    for (int t = 0; t < T; ++t) {
        log_raw[t] = std::log(raw_path[static_cast<std::size_t>(t)]);
        log_current[t] = std::log(current_path[static_cast<std::size_t>(t)]);
    }

    for (int t = 0; t < T; ++t) {
        const int left = std::max(0, t - 1);
        const int right = std::min(T - 1, t + 1);
        double sum = 0.0;
        for (int j = left; j <= right; ++j) {
            sum += log_raw[static_cast<std::size_t>(j)];
        }
        local_average[static_cast<std::size_t>(t)] = sum / static_cast<double>(right - left + 1);
    }

    const double mix_weight = options.smoothing_weight / (1.0 + options.smoothing_weight);
    for (int t = 0; t < T; ++t) {
        smoothed_log[static_cast<std::size_t>(t)] =
            (1.0 - mix_weight) * log_raw[static_cast<std::size_t>(t)] +
            mix_weight * local_average[static_cast<std::size_t>(t)];
    }
    smoothed_log.back() =
        (1.0 - options.terminal_anchor_weight) * smoothed_log.back() +
        options.terminal_anchor_weight * log_current.back();

    std::vector<double> smoothed_path(static_cast<std::size_t>(T));
    for (int t = 0; t < T; ++t) {
        smoothed_path[static_cast<std::size_t>(t)] = std::max(std::exp(smoothed_log[static_cast<std::size_t>(t)]), 1.0e-8);
    }
    return smoothed_path;
}

std::vector<int> find_targeted_periods(const std::vector<double>& clipped_log_gap, int max_targeted_periods) {
    std::vector<int> order(clipped_log_gap.size());
    for (std::size_t i = 0; i < order.size(); ++i) {
        order[i] = static_cast<int>(i);
    }
    std::sort(order.begin(), order.end(), [&](int lhs, int rhs) {
        return std::abs(clipped_log_gap[static_cast<std::size_t>(lhs)]) > std::abs(clipped_log_gap[static_cast<std::size_t>(rhs)]);
    });
    if (max_targeted_periods < static_cast<int>(order.size())) {
        order.resize(static_cast<std::size_t>(max_targeted_periods));
    }
    std::sort(order.begin(), order.end());
    return order;
}

std::vector<std::pair<int, int>> build_target_blocks(const std::vector<int>& targeted_periods, int T, int half_width) {
    std::vector<std::pair<int, int>> blocks;
    for (int period : targeted_periods) {
        const int left = std::max(0, period - half_width);
        const int right = std::min(T - 1, period + half_width);
        if (!blocks.empty() && left <= blocks.back().second + 1) {
            blocks.back().second = std::max(blocks.back().second, right);
        } else {
            blocks.emplace_back(left, right);
        }
    }
    return blocks;
}

std::vector<double> solve_dense_system(std::vector<double> matrix, std::vector<double> rhs, int n) {
    auto at = [&](int row, int col) -> double& {
        return matrix[static_cast<std::size_t>(row * n + col)];
    };

    for (int pivot = 0; pivot < n; ++pivot) {
        int pivot_row = pivot;
        double pivot_abs = std::abs(at(pivot, pivot));
        for (int row = pivot + 1; row < n; ++row) {
            const double candidate_abs = std::abs(at(row, pivot));
            if (candidate_abs > pivot_abs) {
                pivot_abs = candidate_abs;
                pivot_row = row;
            }
        }
        if (pivot_abs <= 1.0e-14) {
            throw std::runtime_error("Singular dense system in solve_dense_system.");
        }
        if (pivot_row != pivot) {
            for (int col = pivot; col < n; ++col) {
                std::swap(at(pivot, col), at(pivot_row, col));
            }
            std::swap(rhs[static_cast<std::size_t>(pivot)], rhs[static_cast<std::size_t>(pivot_row)]);
        }

        const double pivot_value = at(pivot, pivot);
        for (int row = pivot + 1; row < n; ++row) {
            const double factor = at(row, pivot) / pivot_value;
            if (factor == 0.0) {
                continue;
            }
            at(row, pivot) = 0.0;
            for (int col = pivot + 1; col < n; ++col) {
                at(row, col) -= factor * at(pivot, col);
            }
            rhs[static_cast<std::size_t>(row)] -= factor * rhs[static_cast<std::size_t>(pivot)];
        }
    }

    std::vector<double> x(static_cast<std::size_t>(n), 0.0);
    for (int row = n - 1; row >= 0; --row) {
        double value = rhs[static_cast<std::size_t>(row)];
        for (int col = row + 1; col < n; ++col) {
            value -= at(row, col) * x[static_cast<std::size_t>(col)];
        }
        x[static_cast<std::size_t>(row)] = value / at(row, row);
    }
    return x;
}

std::vector<double> solve_regularized_log_update(
    const std::vector<double>& log_current,
    const std::vector<double>& clipped_log_gap,
    const TransitionReOptions& options) {
    const int T = static_cast<int>(log_current.size());
    std::vector<double> target_log(T), rhs(T);
    for (int t = 0; t < T; ++t) {
        target_log[static_cast<std::size_t>(t)] = log_current[static_cast<std::size_t>(t)] + options.damping * clipped_log_gap[static_cast<std::size_t>(t)];
        rhs[static_cast<std::size_t>(t)] = target_log[static_cast<std::size_t>(t)];
    }

    std::vector<double> system_matrix(static_cast<std::size_t>(T * T), 0.0);
    auto at = [&](int row, int col) -> double& {
        return system_matrix[static_cast<std::size_t>(row * T + col)];
    };
    for (int t = 0; t < T; ++t) {
        at(t, t) = 1.0;
    }

    if (T >= 3 && options.smoothing_weight > 0.0) {
        for (int row = 0; row < T - 2; ++row) {
            const int cols[3] = {row, row + 1, row + 2};
            const double vals[3] = {1.0, -2.0, 1.0};
            for (int left = 0; left < 3; ++left) {
                for (int right = 0; right < 3; ++right) {
                    at(cols[left], cols[right]) += options.smoothing_weight * vals[left] * vals[right];
                }
            }
        }
    }

    if (options.terminal_anchor_weight > 0.0) {
        at(T - 1, T - 1) += options.terminal_anchor_weight;
        rhs.back() += options.terminal_anchor_weight * log_current.back();
    }

    return solve_dense_system(std::move(system_matrix), std::move(rhs), T);
}

UpdateDiagnostics update_price_path(
    const std::vector<double>& current_price_path,
    const std::vector<double>& implied_price_path,
    const TransitionReOptions& options,
    std::vector<double>& updated_price_path) {
    const int T = static_cast<int>(current_price_path.size());
    UpdateDiagnostics diagnostics;
    diagnostics.smoothed_implied_price_path = smooth_price_path(implied_price_path, current_price_path, options);

    std::vector<double> log_current(T), log_smoothed(T), log_gap(T), clipped_log_gap(T);
    const double max_log_step = std::log(1.0 + options.max_update_frac);
    for (int t = 0; t < T; ++t) {
        log_current[static_cast<std::size_t>(t)] = std::log(current_price_path[static_cast<std::size_t>(t)]);
        log_smoothed[static_cast<std::size_t>(t)] = std::log(diagnostics.smoothed_implied_price_path[static_cast<std::size_t>(t)]);
        log_gap[static_cast<std::size_t>(t)] = log_smoothed[static_cast<std::size_t>(t)] - log_current[static_cast<std::size_t>(t)];
        clipped_log_gap[static_cast<std::size_t>(t)] =
            std::min(std::max(log_gap[static_cast<std::size_t>(t)], -max_log_step), max_log_step);
    }

    std::vector<double> target_log_path(T);
    for (int t = 0; t < T; ++t) {
        target_log_path[static_cast<std::size_t>(t)] = log_current[static_cast<std::size_t>(t)] + options.damping * clipped_log_gap[static_cast<std::size_t>(t)];
    }

    auto proposed_log_path = solve_regularized_log_update(log_current, clipped_log_gap, options);
    diagnostics.targeted_periods = find_targeted_periods(clipped_log_gap, options.max_targeted_periods);
    diagnostics.targeted_blocks = build_target_blocks(diagnostics.targeted_periods, T, options.target_block_half_width);

    for (const auto& block : diagnostics.targeted_blocks) {
        const int left = block.first;
        const int right = block.second;
        const double left_anchor = proposed_log_path[static_cast<std::size_t>(std::max(0, left - 1))];
        const double right_anchor = proposed_log_path[static_cast<std::size_t>(std::min(T - 1, right + 1))];
        const int block_size = right - left + 1;
        for (int idx = 0; idx < block_size; ++idx) {
            const double weight = (block_size == 1) ? 0.0 : static_cast<double>(idx) / static_cast<double>(block_size - 1);
            const double local_anchor = (1.0 - weight) * left_anchor + weight * right_anchor;
            const int t = left + idx;
            const double blended_target = 0.5 * target_log_path[static_cast<std::size_t>(t)] + 0.5 * local_anchor;
            proposed_log_path[static_cast<std::size_t>(t)] =
                (1.0 - options.targeted_correction_weight) * proposed_log_path[static_cast<std::size_t>(t)] +
                options.targeted_correction_weight * blended_target;
        }
    }

    diagnostics.log_update_step.resize(static_cast<std::size_t>(T));
    updated_price_path.resize(static_cast<std::size_t>(T));
    for (int t = 0; t < T; ++t) {
        diagnostics.log_update_step[static_cast<std::size_t>(t)] = proposed_log_path[static_cast<std::size_t>(t)] - log_current[static_cast<std::size_t>(t)];
        updated_price_path[static_cast<std::size_t>(t)] = std::exp(proposed_log_path[static_cast<std::size_t>(t)]);
    }
    return diagnostics;
}

std::string build_cache_key(const std::vector<double>& price_path) {
    std::ostringstream out;
    out << std::fixed << std::setprecision(8);
    for (double value : price_path) {
        out << value << '|';
    }
    return out.str();
}

const TransitionPassResults& get_transition_pass(
    const TransitionPassInput& base_input,
    const std::vector<double>& price_path,
    std::unordered_map<std::string, TransitionPassResults>& cache) {
    const std::string key = build_cache_key(price_path);
    const auto it = cache.find(key);
    if (it != cache.end()) {
        return it->second;
    }

    TransitionPassInput candidate = base_input;
    candidate.price_path = price_path;
    auto [inserted_it, inserted] = cache.emplace(key, solve_transition_pass(candidate));
    (void)inserted;
    return inserted_it->second;
}

bool is_better_candidate(const TransitionPassResults& candidate, const TransitionPassResults& incumbent, const TransitionReOptions& options) {
    const double tolerance = 1.0e-8;
    if (candidate.max_abs_gap < incumbent.max_abs_gap - options.candidate_gap_improvement_tol &&
        candidate.residual_norm <= incumbent.residual_norm + options.candidate_residual_slack) {
        return true;
    }
    if (candidate.residual_norm < incumbent.residual_norm - tolerance) {
        return true;
    }
    if (std::abs(candidate.residual_norm - incumbent.residual_norm) <= tolerance &&
        candidate.max_abs_gap < incumbent.max_abs_gap) {
        return true;
    }
    return false;
}

bool improves_enough(const TransitionPassResults& candidate, const TransitionPassResults& incumbent, const TransitionReOptions& options) {
    const double gap_tol = std::max(options.candidate_gap_improvement_tol, options.candidate_improvement_tol);
    return candidate.residual_norm < incumbent.residual_norm - options.candidate_improvement_tol ||
        (candidate.max_abs_gap < incumbent.max_abs_gap - gap_tol &&
         candidate.residual_norm <= incumbent.residual_norm + options.candidate_residual_slack);
}

bool use_fertility_style_outer_loop(const TransitionReOptions& options) {
    return lowercase(trim(options.outer_iteration_mode)) == "fertility_style";
}

std::vector<double> build_fertility_style_price_update(
    const std::vector<double>& current_price_path,
    const std::vector<double>& implied_price_path,
    const TransitionReOptions& options) {
    std::vector<double> updated(current_price_path.size(), 0.0);
    if (lowercase(trim(options.fixed_point_relaxation_space)) == "log") {
        for (std::size_t i = 0; i < updated.size(); ++i) {
            const double log_current = std::log(std::max(current_price_path[i], 1.0e-8));
            const double log_implied = std::log(std::max(implied_price_path[i], 1.0e-8));
            updated[i] = std::exp(
                (1.0 - options.fixed_point_relaxation_weight) * log_current +
                options.fixed_point_relaxation_weight * log_implied);
        }
    } else {
        for (std::size_t i = 0; i < updated.size(); ++i) {
            updated[i] =
                (1.0 - options.fixed_point_relaxation_weight) * current_price_path[i] +
                options.fixed_point_relaxation_weight * implied_price_path[i];
        }
    }
    for (double& value : updated) {
        value = std::min(std::max(value, options.fixed_point_price_min), options.fixed_point_price_max);
    }
    return updated;
}

std::string candidate_selection_mode(const TransitionReOptions& options) {
    return trim(options.candidate_selection_mode);
}

FocusMetrics focus_metrics(const TransitionPassResults& run, std::vector<int> focus_periods) {
    std::sort(focus_periods.begin(), focus_periods.end());
    focus_periods.erase(std::unique(focus_periods.begin(), focus_periods.end()), focus_periods.end());

    FocusMetrics metrics;
    if (focus_periods.empty()) {
        for (std::size_t i = 0; i < run.log_price_residual_raw.size(); ++i) {
            metrics.gap = std::max(metrics.gap, std::abs(run.log_price_residual_raw[i]));
            metrics.excess = std::max(metrics.excess, std::abs(run.excess_demand_guess_path[i]));
        }
        return metrics;
    }

    for (int period : focus_periods) {
        const std::size_t idx = static_cast<std::size_t>(period);
        metrics.gap = std::max(metrics.gap, std::abs(run.log_price_residual_raw[idx]));
        metrics.excess = std::max(metrics.excess, std::abs(run.excess_demand_guess_path[idx]));
    }
    return metrics;
}

bool improves_focus_metric(
    const TransitionPassResults& candidate,
    const TransitionPassResults& incumbent,
    const std::vector<int>& focus_periods,
    const TransitionReOptions& options) {
    const auto candidate_focus = focus_metrics(candidate, focus_periods);
    const auto incumbent_focus = focus_metrics(incumbent, focus_periods);

    if (candidate.residual_norm > incumbent.residual_norm + options.focus_residual_slack) {
        return false;
    }

    if (candidate_focus.gap < incumbent_focus.gap - options.focus_gap_improvement_tol) {
        return true;
    }
    return std::abs(candidate_focus.gap - incumbent_focus.gap) <= options.focus_gap_improvement_tol &&
        candidate_focus.excess < incumbent_focus.excess - options.focus_excess_improvement_tol;
}

CandidateSelectionAssessment assess_candidate_selection(
    const TransitionPassResults& candidate,
    const TransitionPassResults& incumbent,
    const std::vector<int>& focus_periods,
    const TransitionReOptions& options) {
    CandidateSelectionAssessment assessment;
    const auto candidate_focus = focus_metrics(candidate, focus_periods);
    const auto incumbent_focus = focus_metrics(incumbent, focus_periods);
    assessment.candidate_focus_gap = candidate_focus.gap;
    assessment.candidate_focus_excess = candidate_focus.excess;
    assessment.incumbent_focus_gap = incumbent_focus.gap;
    assessment.incumbent_focus_excess = incumbent_focus.excess;
    assessment.wins_focus = improves_focus_metric(candidate, incumbent, focus_periods, options);
    assessment.wins_global = is_better_candidate(candidate, incumbent, options);
    assessment.greedy_global = improves_enough(candidate, incumbent, options);

    const std::string mode = candidate_selection_mode(options);
    if (mode == "focus") {
        assessment.sequential_wins = assessment.wins_focus;
        assessment.greedy_sequential = assessment.wins_focus;
    } else if (mode == "hybrid_focus") {
        assessment.sequential_wins = assessment.wins_focus || assessment.wins_global;
        assessment.greedy_sequential = assessment.wins_focus || assessment.greedy_global;
    } else {
        assessment.sequential_wins = assessment.wins_global;
        assessment.greedy_sequential = assessment.greedy_global;
    }
    assessment.sequential_reason =
        selection_reason(mode, assessment.wins_focus, assessment.wins_global, assessment.sequential_wins);
    assessment.greedy_reason =
        selection_reason(mode, assessment.wins_focus, assessment.greedy_global, assessment.greedy_sequential);
    return assessment;
}

std::vector<int> find_focus_periods(const TransitionPassResults& current_run, const UpdateDiagnostics& diagnostics) {
    int worst_gap_period = 0;
    int worst_excess_period = 0;
    double max_gap = -1.0;
    double max_excess = -1.0;

    for (std::size_t i = 0; i < current_run.log_price_residual_raw.size(); ++i) {
        const double gap = std::abs(current_run.log_price_residual_raw[i]);
        const double excess = std::abs(current_run.excess_demand_guess_path[i]);
        if (gap > max_gap) {
            max_gap = gap;
            worst_gap_period = static_cast<int>(i);
        }
        if (excess > max_excess) {
            max_excess = excess;
            worst_excess_period = static_cast<int>(i);
        }
    }

    std::vector<int> focus = diagnostics.targeted_periods;
    focus.push_back(worst_gap_period);
    focus.push_back(worst_excess_period);
    std::sort(focus.begin(), focus.end());
    focus.erase(std::unique(focus.begin(), focus.end()), focus.end());
    return focus;
}

std::vector<int> build_block_start_order(const std::vector<int>& targeted_periods, int T, int block_size, int max_blocks_per_pass) {
    std::vector<int> base_starts;
    for (int start = 0; start < T; start += block_size) {
        base_starts.push_back(start);
    }
    std::vector<int> starts;
    for (int period : targeted_periods) {
        const int start_idx = std::max(0, std::min(T - block_size, period - (block_size - 1) / 2));
        starts.push_back(start_idx);
        if (start_idx - block_size >= 0) {
            starts.push_back(start_idx - block_size);
        }
        if (start_idx + block_size <= T - block_size) {
            starts.push_back(start_idx + block_size);
        }
    }
    starts.insert(starts.end(), base_starts.begin(), base_starts.end());
    std::sort(starts.begin(), starts.end());
    starts.erase(std::unique(starts.begin(), starts.end()), starts.end());
    if (max_blocks_per_pass > 0 && static_cast<int>(starts.size()) > max_blocks_per_pass) {
        starts.resize(static_cast<std::size_t>(max_blocks_per_pass));
    }
    return starts;
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

void write_row_major_matrix_csv(
    const std::filesystem::path& path,
    const std::vector<double>& values,
    int rows,
    int cols) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write CSV: " + path.string());
    }
    output << std::setprecision(17);
    for (int row = 0; row < rows; ++row) {
        for (int col = 0; col < cols; ++col) {
            if (col > 0) {
                output << ',';
            }
            output << values[static_cast<std::size_t>(row * cols + col)];
        }
        output << '\n';
    }
}

void write_iteration_log_csv(const std::filesystem::path& path, const std::vector<IterationSummary>& iterations) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write iteration log CSV: " + path.string());
    }
    output << "residual_norm,max_abs_gap,max_abs_update,accepted_update\n";
    output << std::setprecision(17);
    for (const auto& iter : iterations) {
        output << iter.residual_norm << ','
               << iter.max_abs_gap << ','
               << iter.max_abs_update << ','
               << iter.accepted_update << '\n';
    }
}

std::string serialize_int_list(const std::vector<int>& values) {
    std::ostringstream out;
    for (std::size_t i = 0; i < values.size(); ++i) {
        if (i > 0) {
            out << ';';
        }
        out << values[i];
    }
    return out.str();
}

std::string serialize_block_list(const std::vector<std::pair<int, int>>& blocks) {
    std::ostringstream out;
    for (std::size_t i = 0; i < blocks.size(); ++i) {
        if (i > 0) {
            out << ';';
        }
        out << blocks[i].first << '-' << blocks[i].second;
    }
    return out.str();
}

void write_csv_double(std::ostream& output, double value) {
    if (std::isnan(value)) {
        output << "NaN";
    } else {
        output << value;
    }
}

void write_selection_iterations_csv(
    const std::filesystem::path& path,
    const std::vector<IterationSelectionDiagnostic>& diagnostics) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write selection iteration CSV: " + path.string());
    }
    output << "iteration,candidate_selection_mode,current_label,current_residual_norm,current_max_abs_gap,targeted_periods,targeted_blocks,has_sequential,sequential_selection_mode,sequential_start_label,sequential_final_label,sequential_final_residual_norm,sequential_final_max_abs_gap,final_selected_label,final_residual_norm,final_max_abs_gap\n";
    output << std::setprecision(17);
    for (const auto& detail : diagnostics) {
        output << detail.iteration << ','
               << detail.candidate_selection_mode << ','
               << detail.current_label << ','
               << detail.current_residual_norm << ','
               << detail.current_max_abs_gap << ','
               << serialize_int_list(detail.targeted_periods) << ','
               << serialize_block_list(detail.targeted_blocks) << ','
               << (detail.has_sequential ? 1 : 0) << ',';
        if (detail.has_sequential) {
            output << detail.sequential.selection_mode << ','
                   << detail.sequential.start_label << ','
                   << detail.sequential.final_label << ','
                   << detail.sequential.final_residual_norm << ','
                   << detail.sequential.final_max_abs_gap << ',';
        } else {
            output << ",,,NaN,NaN,";
        }
        output << detail.final_selected_label << ','
               << detail.final_residual_norm << ','
               << detail.final_max_abs_gap << '\n';
    }
}

void write_selection_passes_csv(
    const std::filesystem::path& path,
    const std::vector<IterationSelectionDiagnostic>& diagnostics) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write selection pass CSV: " + path.string());
    }
    output << "iteration,pass,start_label,focus_periods,targeted_periods,targeted_blocks,block_starts,selected_label,selected_residual_norm,selected_max_abs_gap,accepted_in_pass,greedy_accept_label\n";
    output << std::setprecision(17);
    for (const auto& detail : diagnostics) {
        if (!detail.has_sequential) {
            continue;
        }
        for (const auto& pass : detail.sequential.passes) {
            output << detail.iteration << ','
                   << pass.pass << ','
                   << pass.start_label << ','
                   << serialize_int_list(pass.focus_periods) << ','
                   << serialize_int_list(pass.targeted_periods) << ','
                   << serialize_block_list(pass.targeted_blocks) << ','
                   << serialize_int_list(pass.block_starts) << ','
                   << pass.selected_label << ','
                   << pass.selected_residual_norm << ','
                   << pass.selected_max_abs_gap << ','
                   << (pass.accepted_in_pass ? 1 : 0) << ','
                   << pass.greedy_accept_label << '\n';
        }
    }
}

void write_selection_candidates_csv(
    const std::filesystem::path& path,
    const std::vector<IterationSelectionDiagnostic>& diagnostics) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write selection candidate CSV: " + path.string());
    }
    output << "iteration,stage,pass,candidate_label,incumbent_label,block_start,block_stop,scale,focus_periods,candidate_residual_norm,candidate_max_abs_gap,candidate_focus_gap,candidate_focus_excess,incumbent_residual_norm,incumbent_max_abs_gap,incumbent_focus_gap,incumbent_focus_excess,wins_focus,wins_global,wins_sequential,greedy_global,greedy_sequential,selection_reason,greedy_reason,became_best,accepted_greedily\n";
    output << std::setprecision(17);

    auto write_candidate = [&](int iteration, const CandidateDiagnostic& entry) {
        output << iteration << ','
               << entry.stage << ',';
        write_csv_double(output, entry.pass);
        output << ','
               << entry.candidate_label << ','
               << entry.incumbent_label << ',';
        write_csv_double(output, entry.block_start);
        output << ',';
        write_csv_double(output, entry.block_stop);
        output << ',';
        write_csv_double(output, entry.scale);
        output << ','
               << serialize_int_list(entry.focus_periods) << ','
               << entry.candidate_residual_norm << ','
               << entry.candidate_max_abs_gap << ','
               << entry.candidate_focus_gap << ','
               << entry.candidate_focus_excess << ','
               << entry.incumbent_residual_norm << ','
               << entry.incumbent_max_abs_gap << ','
               << entry.incumbent_focus_gap << ','
               << entry.incumbent_focus_excess << ','
               << (entry.wins_focus ? 1 : 0) << ','
               << (entry.wins_global ? 1 : 0) << ','
               << (entry.wins_sequential ? 1 : 0) << ','
               << (entry.greedy_global ? 1 : 0) << ','
               << (entry.greedy_sequential ? 1 : 0) << ','
               << entry.selection_reason << ','
               << entry.greedy_reason << ','
               << (entry.became_best ? 1 : 0) << ','
               << (entry.accepted_greedily ? 1 : 0) << '\n';
    };

    for (const auto& detail : diagnostics) {
        for (const auto& entry : detail.initial_candidates) {
            write_candidate(detail.iteration, entry);
        }
        if (!detail.has_sequential) {
            continue;
        }
        for (const auto& pass : detail.sequential.passes) {
            for (const auto& entry : pass.candidate_evaluations) {
                write_candidate(detail.iteration, entry);
            }
        }
    }
}

void write_summary_csv(const std::filesystem::path& path, const TransitionReResults& results) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write summary CSV: " + path.string());
    }
    output << "name,value\n";
    output << std::setprecision(17);
    output << "converged," << (results.converged ? 1 : 0) << '\n';
    output << "iterations," << results.iterations << '\n';
    output << "final_label," << results.final_label << '\n';
    output << "final_max_abs_gap," << results.final_max_abs_gap << '\n';
    output << "final_residual_norm," << results.final_residual_norm << '\n';
}

}  // namespace

TransitionReInput read_transition_re_input_pack(const std::filesystem::path& input_dir) {
    TransitionReInput input;
    input.transition_input = read_transition_pass_input_pack(input_dir);
    input.initial_price_path = read_single_column_csv(input_dir / "re_initial_price_path.csv");

    const auto params = read_scalar_map(input_dir / "re_params_scalars.csv");
    const auto string_params = read_optional_string_map(input_dir / "re_params_strings.csv");
    input.options.max_iter = static_cast<int>(std::lround(require_scalar(params, "max_iter")));
    input.options.tol = require_scalar(params, "tol");
    input.options.damping = require_scalar(params, "damping");
    input.options.update_scheme = string_or_default(string_params, "update_scheme", input.options.update_scheme);
    input.options.outer_iteration_mode =
        string_or_default(string_params, "outer_iteration_mode", input.options.outer_iteration_mode);
    input.options.max_update_frac = require_scalar(params, "max_update_frac");
    input.options.smoothing_weight = require_scalar(params, "smoothing_weight");
    input.options.terminal_anchor_weight = require_scalar(params, "terminal_anchor_weight");
    input.options.fixed_point_relaxation_weight =
        scalar_or_default(params, "fixed_point_relaxation_weight", input.options.fixed_point_relaxation_weight);
    input.options.fixed_point_relaxation_space =
        string_or_default(string_params, "fixed_point_relaxation_space", input.options.fixed_point_relaxation_space);
    input.options.fixed_point_price_min =
        scalar_or_default(params, "fixed_point_price_min", input.options.fixed_point_price_min);
    input.options.fixed_point_price_max =
        scalar_or_default(params, "fixed_point_price_max", input.options.fixed_point_price_max);
    input.options.targeted_correction_weight = require_scalar(params, "targeted_correction_weight");
    input.options.max_targeted_periods = static_cast<int>(std::lround(require_scalar(params, "max_targeted_periods")));
    input.options.target_block_half_width = static_cast<int>(std::lround(require_scalar(params, "target_block_half_width")));
    input.options.sequential_block_size = static_cast<int>(std::lround(require_scalar(params, "sequential_block_size")));
    input.options.block_sweep_passes = static_cast<int>(std::lround(require_scalar(params, "block_sweep_passes")));
    input.options.max_blocks_per_pass = static_cast<int>(std::lround(require_scalar(params, "max_blocks_per_pass")));
    input.options.greedy_block_accept = require_scalar(params, "greedy_block_accept") != 0.0;
    input.options.candidate_improvement_tol = require_scalar(params, "candidate_improvement_tol");
    input.options.candidate_gap_improvement_tol = require_scalar(params, "candidate_gap_improvement_tol");
    input.options.candidate_residual_slack = require_scalar(params, "candidate_residual_slack");
    input.options.candidate_selection_mode =
        string_or_default(string_params, "candidate_selection_mode", input.options.candidate_selection_mode);
    input.options.focus_gap_improvement_tol =
        scalar_or_default(params, "focus_gap_improvement_tol", input.options.focus_gap_improvement_tol);
    input.options.focus_excess_improvement_tol =
        scalar_or_default(params, "focus_excess_improvement_tol", input.options.focus_excess_improvement_tol);
    input.options.focus_residual_slack =
        scalar_or_default(params, "focus_residual_slack", input.options.focus_residual_slack);
    input.options.sequential_return_endpoint = require_scalar(params, "sequential_return_endpoint") != 0.0;
    input.options.save_candidate_history =
        scalar_or_default(params, "save_candidate_history", input.options.save_candidate_history ? 1.0 : 0.0) != 0.0;
    input.options.line_search_scales = read_single_column_csv(input_dir / "line_search_scales.csv");
    return input;
}

TransitionReResults solve_transition_re(const TransitionReInput& input) {
    std::unordered_map<std::string, TransitionPassResults> cache;
    std::vector<double> current_price_path = input.initial_price_path;
    TransitionReResults results;
    results.horizon = static_cast<int>(current_price_path.size());
    results.initial_price_path = current_price_path;

    TransitionPassResults last_run;
    std::string last_label = "current_path";

    for (int iter = 0; iter < input.options.max_iter; ++iter) {
        const auto& base_run = get_transition_pass(input.transition_input, current_price_path, cache);
        results.iteration_current_price_paths.insert(
            results.iteration_current_price_paths.end(),
            current_price_path.begin(),
            current_price_path.end());
        results.iteration_implied_price_paths.insert(
            results.iteration_implied_price_paths.end(),
            base_run.implied_price_path.begin(),
            base_run.implied_price_path.end());
        std::vector<double> updated_price_path;
        const UpdateDiagnostics diagnostics = update_price_path(current_price_path, base_run.implied_price_path, input.options, updated_price_path);

        const TransitionPassResults* selected_run = &base_run;
        std::vector<double> selected_price_path = current_price_path;
        std::string selected_label = "current_path";
        IterationSelectionDiagnostic iteration_detail;
        if (input.options.save_candidate_history) {
            iteration_detail = initialize_iteration_selection_detail(iter + 1, selected_label, base_run, diagnostics, input.options);
        }

        if (use_fertility_style_outer_loop(input.options)) {
            selected_price_path = build_fertility_style_price_update(current_price_path, base_run.implied_price_path, input.options);
            selected_run = &get_transition_pass(input.transition_input, selected_price_path, cache);
            selected_label = "fertility_style_relaxation";
        } else {
            const auto& full_update_run = get_transition_pass(input.transition_input, updated_price_path, cache);
            const auto full_focus_periods = find_focus_periods(base_run, diagnostics);
            const auto full_assessment = assess_candidate_selection(full_update_run, *selected_run, full_focus_periods, input.options);
            if (input.options.save_candidate_history) {
                append_candidate_detail(
                    iteration_detail.initial_candidates,
                    "initial_regularized_full",
                    0,
                    "regularized_full_update",
                    full_update_run,
                    selected_label,
                    *selected_run,
                    full_focus_periods,
                    full_assessment,
                    quiet_nan(),
                    quiet_nan(),
                    quiet_nan(),
                    full_assessment.sequential_wins,
                    false);
            }
            if (is_better_candidate(full_update_run, *selected_run, input.options)) {
                selected_run = &full_update_run;
                selected_price_path = updated_price_path;
                selected_label = "regularized_full_update";
            }

            const int T = static_cast<int>(current_price_path.size());
            const int block_size = std::min(input.options.sequential_block_size, T);
            std::vector<double> current_candidate_price_path = selected_price_path;
            const TransitionPassResults* current_candidate_run = selected_run;
            std::string current_candidate_label = selected_label;
            const TransitionPassResults* best_run = selected_run;
            std::vector<double> best_price_path = selected_price_path;
            std::string best_label = selected_label;
            SequentialDiagnostic sequential_detail;
            if (input.options.save_candidate_history) {
                sequential_detail = initialize_sequential_detail(current_candidate_label, input.options);
            }

            for (int pass = 0; pass < input.options.block_sweep_passes; ++pass) {
                std::vector<double> pass_updated_price_path;
                const UpdateDiagnostics pass_diagnostics =
                    update_price_path(current_candidate_price_path, current_candidate_run->implied_price_path, input.options, pass_updated_price_path);
                const auto focus_periods = find_focus_periods(*current_candidate_run, pass_diagnostics);
                const auto block_starts = build_block_start_order(focus_periods, T, block_size, input.options.max_blocks_per_pass);

                const auto& pass_full_run = get_transition_pass(input.transition_input, pass_updated_price_path, cache);
                const TransitionPassResults* pass_best_run = current_candidate_run;
                std::vector<double> pass_best_price_path = current_candidate_price_path;
                std::string pass_best_label = current_candidate_label;
                bool accepted_in_pass = false;
                PassDiagnostic pass_detail;
                if (input.options.save_candidate_history) {
                    pass_detail = initialize_pass_detail(pass + 1, current_candidate_label, focus_periods, block_starts, pass_diagnostics);
                }

                const auto full_assessment = assess_candidate_selection(pass_full_run, *pass_best_run, focus_periods, input.options);
                if (input.options.save_candidate_history) {
                    append_candidate_detail(
                        pass_detail.candidate_evaluations,
                        "sequential_regularized_full",
                        pass + 1,
                        "regularized_full_p" + std::to_string(pass + 1),
                        pass_full_run,
                        pass_best_label,
                        *pass_best_run,
                        focus_periods,
                        full_assessment,
                        quiet_nan(),
                        quiet_nan(),
                        quiet_nan(),
                        full_assessment.sequential_wins,
                        input.options.greedy_block_accept && full_assessment.greedy_sequential);
                }
                if (full_assessment.sequential_wins) {
                    pass_best_run = &pass_full_run;
                    pass_best_price_path = pass_updated_price_path;
                    std::ostringstream label;
                    label << "regularized_full_p" << (pass + 1);
                    pass_best_label = label.str();
                    if (input.options.greedy_block_accept && full_assessment.greedy_sequential) {
                        accepted_in_pass = true;
                    }
                }

                if (!accepted_in_pass) {
                    const std::vector<double> log_current([&]() {
                        std::vector<double> values(current_candidate_price_path.size(), 0.0);
                        for (std::size_t i = 0; i < values.size(); ++i) {
                            values[i] = std::log(current_candidate_price_path[i]);
                        }
                        return values;
                    }());

                    for (int start_idx : block_starts) {
                        const int stop_idx = std::min(T - 1, start_idx + block_size - 1);
                        for (double scale : input.options.line_search_scales) {
                            std::vector<double> candidate_price_path = current_candidate_price_path;
                            for (int t = start_idx; t <= stop_idx; ++t) {
                                candidate_price_path[static_cast<std::size_t>(t)] =
                                    std::exp(log_current[static_cast<std::size_t>(t)] + scale * pass_diagnostics.log_update_step[static_cast<std::size_t>(t)]);
                            }

                            const auto& candidate_run = get_transition_pass(input.transition_input, candidate_price_path, cache);
                            const auto candidate_assessment =
                                assess_candidate_selection(candidate_run, *pass_best_run, focus_periods, input.options);
                            std::ostringstream label;
                            label << "sequential_block_p" << (pass + 1) << '_' << (start_idx + 1) << '_' << (stop_idx + 1) << '_' << scale;
                            const std::string candidate_label = label.str();
                            if (input.options.save_candidate_history) {
                                append_candidate_detail(
                                    pass_detail.candidate_evaluations,
                                    "sequential_block",
                                    pass + 1,
                                    candidate_label,
                                    candidate_run,
                                    pass_best_label,
                                    *pass_best_run,
                                    focus_periods,
                                    candidate_assessment,
                                    static_cast<double>(start_idx + 1),
                                    static_cast<double>(stop_idx + 1),
                                    scale,
                                    candidate_assessment.sequential_wins,
                                    input.options.greedy_block_accept && candidate_assessment.greedy_sequential);
                            }
                            if (candidate_assessment.sequential_wins) {
                                pass_best_run = &candidate_run;
                                pass_best_price_path = candidate_price_path;
                                pass_best_label = candidate_label;
                                if (input.options.greedy_block_accept && candidate_assessment.greedy_sequential) {
                                    accepted_in_pass = true;
                                    if (input.options.save_candidate_history) {
                                        pass_detail.greedy_accept_label = candidate_label;
                                    }
                                    break;
                                }
                            }
                        }
                        if (accepted_in_pass) {
                            break;
                        }
                    }
                }

                if (is_better_candidate(*pass_best_run, *best_run, input.options)) {
                    best_run = pass_best_run;
                    best_price_path = pass_best_price_path;
                    best_label = pass_best_label;
                }

                if (input.options.save_candidate_history) {
                    pass_detail.selected_label = pass_best_label;
                    pass_detail.selected_residual_norm = pass_best_run->residual_norm;
                    pass_detail.selected_max_abs_gap = pass_best_run->max_abs_gap;
                    pass_detail.accepted_in_pass = accepted_in_pass;
                    sequential_detail.passes.push_back(std::move(pass_detail));
                }

                if (pass_best_label == current_candidate_label) {
                    break;
                }

                current_candidate_run = pass_best_run;
                current_candidate_price_path = pass_best_price_path;
                current_candidate_label = pass_best_label;
            }

            if (input.options.sequential_return_endpoint) {
                selected_run = current_candidate_run;
                selected_price_path = current_candidate_price_path;
                selected_label = current_candidate_label;
            } else {
                selected_run = best_run;
                selected_price_path = best_price_path;
                selected_label = best_label;
            }

            if (input.options.save_candidate_history) {
                sequential_detail.final_label = selected_label;
                sequential_detail.final_residual_norm = selected_run->residual_norm;
                sequential_detail.final_max_abs_gap = selected_run->max_abs_gap;
                iteration_detail.has_sequential = true;
                iteration_detail.sequential = std::move(sequential_detail);
            }
        }

        results.iteration_log.push_back(IterationSummary{
            selected_run->residual_norm,
            selected_run->max_abs_gap,
            max_abs_diff(selected_price_path, current_price_path),
            selected_label});
        results.iteration_selected_price_paths.insert(
            results.iteration_selected_price_paths.end(),
            selected_price_path.begin(),
            selected_price_path.end());
        if (input.options.save_candidate_history) {
            iteration_detail.final_selected_label = selected_label;
            iteration_detail.final_residual_norm = selected_run->residual_norm;
            iteration_detail.final_max_abs_gap = selected_run->max_abs_gap;
            results.selection_diagnostics.push_back(std::move(iteration_detail));
        }

        current_price_path = selected_price_path;
        last_run = *selected_run;
        last_label = selected_label;

        if (selected_run->max_abs_gap < input.options.tol) {
            break;
        }
    }

    results.iterations = static_cast<int>(results.iteration_log.size());
    results.final_price_path = current_price_path;
    results.implied_price_path = last_run.implied_price_path;
    results.Hdemand_path = last_run.Hdemand_path;
    results.Hsupply_path = last_run.Hsupply_guess_path;
    results.excess_demand_path = last_run.excess_demand_guess_path;
    results.log_price_residual_raw = last_run.log_price_residual_raw;
    results.policy_reference_price_path_used = last_run.policy_reference_price_path_used;
    results.terminal_reference_price_used = last_run.terminal_reference_price_used;
    results.density_by_period_age = last_run.density_by_period_age;
    results.final_label = last_label;
    results.final_max_abs_gap = last_run.max_abs_gap;
    results.final_residual_norm = last_run.residual_norm;
    results.converged = last_run.max_abs_gap < input.options.tol;
    return results;
}

void write_transition_re_results(const std::filesystem::path& output_dir, const TransitionReResults& results) {
    std::filesystem::create_directories(output_dir);
    write_vector_csv(output_dir / "sidecar_re_final_price_path.csv", results.final_price_path);
    write_vector_csv(output_dir / "sidecar_re_implied_price_path.csv", results.implied_price_path);
    write_vector_csv(output_dir / "sidecar_re_Hdemand_path.csv", results.Hdemand_path);
    write_vector_csv(output_dir / "sidecar_re_Hsupply_path.csv", results.Hsupply_path);
    write_vector_csv(output_dir / "sidecar_re_excess_demand_path.csv", results.excess_demand_path);
    write_vector_csv(output_dir / "sidecar_re_log_price_residual_raw.csv", results.log_price_residual_raw);
    if (!results.policy_reference_price_path_used.empty()) {
        write_vector_csv(output_dir / "sidecar_re_policy_reference_price_path_used.csv", results.policy_reference_price_path_used);
    }
    if (!results.density_by_period_age.empty()) {
        write_vector_csv(output_dir / "sidecar_re_density_by_period_age.csv", results.density_by_period_age);
    }
    if (results.horizon > 0 && results.iterations > 0) {
        write_row_major_matrix_csv(
            output_dir / "sidecar_re_iteration_current_price_paths.csv",
            results.iteration_current_price_paths,
            results.iterations,
            results.horizon);
        write_row_major_matrix_csv(
            output_dir / "sidecar_re_iteration_implied_price_paths.csv",
            results.iteration_implied_price_paths,
            results.iterations,
            results.horizon);
        write_row_major_matrix_csv(
            output_dir / "sidecar_re_iteration_selected_price_paths.csv",
            results.iteration_selected_price_paths,
            results.iterations,
            results.horizon);
    }
    write_iteration_log_csv(output_dir / "sidecar_re_iteration_log.csv", results.iteration_log);
    if (!results.selection_diagnostics.empty()) {
        write_selection_iterations_csv(output_dir / "sidecar_re_selection_iterations.csv", results.selection_diagnostics);
        write_selection_passes_csv(output_dir / "sidecar_re_selection_passes.csv", results.selection_diagnostics);
        write_selection_candidates_csv(output_dir / "sidecar_re_selection_candidates.csv", results.selection_diagnostics);
    }
    write_summary_csv(output_dir / "sidecar_re_summary.csv", results);
}

}  // namespace nimby_sidecar
