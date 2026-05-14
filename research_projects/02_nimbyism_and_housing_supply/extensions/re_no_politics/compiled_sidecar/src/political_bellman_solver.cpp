#include "nimby_sidecar/political_bellman_solver.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <limits>
#include <numeric>
#include <sstream>
#include <stdexcept>

namespace nimby_sidecar {
namespace {

std::string trim(std::string value) {
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

template <typename T>
void write_vector_csv(std::ofstream& output, const std::vector<T>& values) {
    output << std::setprecision(17);
    for (const auto& value : values) {
        output << value << '\n';
    }
}

double max_abs_value(const std::vector<double>& values) {
    double result = 0.0;
    for (double value : values) {
        result = std::max(result, std::abs(value));
    }
    return result;
}

std::vector<double> resolve_vote_path(const TransitionPassResults& pass, const std::string& target) {
    const std::string normalized = lowercase(trim(target));
    if (normalized == "equal_weight_vote") {
        return pass.equal_weight_vote_path;
    }
    throw std::runtime_error("Unsupported political_target in compiled wrapper: " + target);
}

std::vector<double> build_updated_price_path(
    const std::vector<double>& current_price_path,
    const std::vector<double>& vote_path,
    const std::vector<double>& previous_price_path,
    const std::vector<double>& previous_vote_path,
    const PoliticalBellmanOptions& options,
    std::string& rule_used,
    int& secant_periods) {
    if (lowercase(trim(options.price_update_mode)) != "political_only") {
        throw std::runtime_error("Compiled political wrapper currently supports price_update_mode = political_only only.");
    }

    std::vector<double> log_shift(vote_path.size(), 0.0);
    for (std::size_t i = 0; i < vote_path.size(); ++i) {
        log_shift[i] = options.political_update_weight * vote_path[i];
    }

    rule_used = "fixed_step";
    secant_periods = 0;

    const std::string update_rule = lowercase(trim(options.political_update_rule));
    if (update_rule == "diagonal_secant") {
        if (!previous_price_path.empty() && previous_price_path.size() == current_price_path.size() &&
            !previous_vote_path.empty() && previous_vote_path.size() == vote_path.size()) {
            std::vector<double> secant_shift(vote_path.size(), 0.0);
            std::vector<bool> valid(vote_path.size(), false);
            for (std::size_t i = 0; i < vote_path.size(); ++i) {
                const double delta_state = current_price_path[i] - previous_price_path[i];
                const double delta_vote = vote_path[i] - previous_vote_path[i];
                const double slope = delta_vote / delta_state;
                const bool can_use = std::isfinite(delta_state) && std::isfinite(delta_vote) &&
                    std::isfinite(slope) && std::abs(delta_state) > 1.0e-8 &&
                    std::abs(slope) >= options.secant_min_abs_slope;
                if (can_use) {
                    secant_shift[i] = -options.secant_damping * (vote_path[i] / slope);
                    valid[i] = std::isfinite(secant_shift[i]);
                }
            }
            for (std::size_t i = 0; i < vote_path.size(); ++i) {
                if (valid[i]) {
                    log_shift[i] = secant_shift[i];
                    ++secant_periods;
                }
            }
            rule_used = (secant_periods > 0) ? "diagonal_secant" : "diagonal_secant_fallback";
        } else {
            rule_used = "diagonal_secant_fallback";
        }
    } else if (update_rule != "fixed_step") {
        throw std::runtime_error("Unsupported political_update_rule in compiled wrapper: " + options.political_update_rule);
    }

    const double max_log_step = std::log(1.0 + options.max_update_frac);
    for (double& value : log_shift) {
        value = std::min(std::max(value, -max_log_step), max_log_step);
    }

    std::vector<double> updated(current_price_path.size(), 0.0);
    for (std::size_t i = 0; i < current_price_path.size(); ++i) {
        updated[i] = current_price_path[i] * std::exp(log_shift[i]);
        updated[i] = std::min(std::max(updated[i], options.price_floor), options.price_cap);
    }
    return updated;
}

void write_iteration_summary_csv(const std::filesystem::path& path, const std::vector<PoliticalBellmanIterationLog>& log) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write CSV: " + path.string());
    }
    output << "iteration,guess_source,political_target,price_update_mode,political_update_rule,max_abs_vote,mean_vote,max_abs_gap,residual_norm,price_min,price_max,housing_anchor_min,housing_anchor_max,max_abs_political_step\n";
    output << std::setprecision(17);
    for (const auto& row : log) {
        output << row.iteration << ','
               << row.guess_source << ','
               << row.political_target << ','
               << row.price_update_mode << ','
               << row.political_update_rule << ','
               << row.max_abs_vote << ','
               << row.mean_vote << ','
               << row.max_abs_gap << ','
               << row.residual_norm << ','
               << row.price_min << ','
               << row.price_max << ','
               << row.housing_anchor_min << ','
               << row.housing_anchor_max << ','
               << row.max_abs_political_step << '\n';
    }
}

}  // namespace

PoliticalBellmanResults solve_political_bellman(const TransitionPassInput& base_input, const PoliticalBellmanOptions& options) {
    if (base_input.price_path.empty()) {
        throw std::runtime_error("Political Bellman wrapper requires a non-empty price path guess.");
    }

    PoliticalBellmanResults results;
    results.initial_price_path = base_input.price_path;
    results.guess_source = options.guess_source;
    results.political_target = options.political_target;
    results.price_update_mode = options.price_update_mode;
    results.political_update_rule = options.political_update_rule;
    results.options = options;

    std::vector<double> current_price_path = base_input.price_path;
    std::vector<double> previous_price_path;
    std::vector<double> previous_vote_path;
    std::vector<double> last_vote_path;
    std::vector<double> last_anchor_path;
    TransitionPassResults last_pass;
    TransitionPassResults final_pass;

    for (int iter = 1; iter <= options.max_iter; ++iter) {
        TransitionPassInput pass_input = base_input;
        pass_input.price_path = current_price_path;
        pass_input.compute_political_path = true;
        pass_input.save_political_details = true;
        pass_input.save_period_details = true;

        auto current_pass = solve_transition_pass(pass_input);
        const auto vote_path = resolve_vote_path(current_pass, options.political_target);
        const auto anchor_path = current_price_path;

        std::string rule_used;
        int secant_periods = 0;
        const auto updated_price_path = build_updated_price_path(
            anchor_path,
            vote_path,
            previous_price_path,
            previous_vote_path,
            options,
            rule_used,
            secant_periods);

        PoliticalBellmanIterationLog row;
        row.iteration = iter;
        row.guess_source = options.guess_source;
        row.political_target = options.political_target;
        row.price_update_mode = options.price_update_mode;
        row.political_update_rule = rule_used;
        row.max_abs_vote = max_abs_value(vote_path);
        row.mean_vote = vote_path.empty() ? 0.0 : std::accumulate(vote_path.begin(), vote_path.end(), 0.0) / static_cast<double>(vote_path.size());
        row.max_abs_gap = current_pass.max_abs_gap;
        row.residual_norm = current_pass.residual_norm;
        row.price_min = *std::min_element(updated_price_path.begin(), updated_price_path.end());
        row.price_max = *std::max_element(updated_price_path.begin(), updated_price_path.end());
        row.housing_anchor_min = *std::min_element(anchor_path.begin(), anchor_path.end());
        row.housing_anchor_max = *std::max_element(anchor_path.begin(), anchor_path.end());
        row.max_abs_political_step = [&]() {
            double step = 0.0;
            for (std::size_t i = 0; i < updated_price_path.size(); ++i) {
                step = std::max(step, std::abs(updated_price_path[i] - anchor_path[i]));
            }
            return step;
        }();
        row.vote_path = vote_path;
        row.current_price_path = current_price_path;
        row.anchor_price_path = anchor_path;
        row.updated_price_path = updated_price_path;

        results.iteration_log.push_back(row);
        last_vote_path = vote_path;
        last_anchor_path = anchor_path;
        last_pass = current_pass;
        current_price_path = updated_price_path;
        previous_price_path = anchor_path;
        previous_vote_path = vote_path;
        final_pass = current_pass;

        if (row.max_abs_vote < options.tol_vote) {
            break;
        }
    }

    results.iterations = static_cast<int>(results.iteration_log.size());
    results.converged = !results.iteration_log.empty() && results.iteration_log.back().max_abs_vote < options.tol_vote;
    results.final_price_path = current_price_path;
    results.final_vote_path = last_vote_path;
    results.final_anchor_path = last_anchor_path;
    results.last_transition_pass = last_pass;
    results.final_transition_pass = final_pass;
    results.message = "Compiled political Bellman wrapper completed using the inner transition-pass political vote path.";
    return results;
}

void write_political_bellman_results(const std::filesystem::path& output_dir, const PoliticalBellmanResults& results) {
    std::filesystem::create_directories(output_dir);
    write_iteration_summary_csv(output_dir / "sidecar_summary.csv", results.iteration_log);

    if (!results.final_price_path.empty()) {
        std::ofstream output(output_dir / "sidecar_final_price_path.csv");
        if (!output) {
            throw std::runtime_error("Could not write CSV: " + (output_dir / "sidecar_final_price_path.csv").string());
        }
        write_vector_csv(output, results.final_price_path);
    }
    if (!results.final_vote_path.empty()) {
        std::ofstream output(output_dir / "sidecar_final_vote_path.csv");
        if (!output) {
            throw std::runtime_error("Could not write CSV: " + (output_dir / "sidecar_final_vote_path.csv").string());
        }
        write_vector_csv(output, results.final_vote_path);
    }
    if (!results.final_anchor_path.empty()) {
        std::ofstream output(output_dir / "sidecar_final_anchor_path.csv");
        if (!output) {
            throw std::runtime_error("Could not write CSV: " + (output_dir / "sidecar_final_anchor_path.csv").string());
        }
        write_vector_csv(output, results.final_anchor_path);
    }

    std::ofstream summary(output_dir / "sidecar_results.txt");
    if (!summary) {
        throw std::runtime_error("Could not write CSV: " + (output_dir / "sidecar_results.txt").string());
    }
    summary << "converged=" << (results.converged ? 1 : 0) << '\n';
    summary << "iterations=" << results.iterations << '\n';
    summary << "guess_source=" << results.guess_source << '\n';
    summary << "political_target=" << results.political_target << '\n';
    summary << "price_update_mode=" << results.price_update_mode << '\n';
    summary << "political_update_rule=" << results.political_update_rule << '\n';
    summary << "message=" << results.message << '\n';
}

}  // namespace nimby_sidecar
