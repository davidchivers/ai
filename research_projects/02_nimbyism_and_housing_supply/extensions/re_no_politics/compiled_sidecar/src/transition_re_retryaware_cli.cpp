#include "nimby_sidecar/transition_re_solver.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

struct CliOptions {
    std::filesystem::path input_dir;
    std::filesystem::path output_dir;
    double gap_cutoff = 0.05;
    double price_bound_tol = 1.0e-6;
    int per_attempt_max_iter = -1;
};

struct AttemptSummary {
    int attempt = 0;
    std::string status;
    bool looks_stable = false;
    bool converged = false;
    int iterations = 0;
    std::string final_label;
    double final_max_abs_gap = std::numeric_limits<double>::quiet_NaN();
    double final_residual_norm = std::numeric_limits<double>::quiet_NaN();
    double price_min = std::numeric_limits<double>::quiet_NaN();
    double price_max = std::numeric_limits<double>::quiet_NaN();
    std::filesystem::path output_dir;
};

std::string format_double(double value) {
    if (std::isnan(value)) {
        return "NaN";
    }
    std::ostringstream out;
    out.precision(17);
    out << value;
    return out.str();
}

CliOptions parse_args(int argc, char** argv) {
    if (argc < 2) {
        throw std::runtime_error(
            "Usage: nimby_transition_re_retryaware_cli <input_dir> [--output-dir <path>] "
            "[--gap-cutoff <double>] [--price-bound-tol <double>] [--per-attempt-max-iter <int>]");
    }

    CliOptions options;
    options.input_dir = argv[1];
    options.output_dir = options.input_dir.parent_path() / (options.input_dir.filename().string() + "_retryaware");

    for (int i = 2; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--output-dir") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--output-dir requires a path");
            }
            options.output_dir = argv[++i];
        } else if (arg == "--gap-cutoff") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--gap-cutoff requires a value");
            }
            options.gap_cutoff = std::stod(argv[++i]);
        } else if (arg == "--price-bound-tol") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-bound-tol requires a value");
            }
            options.price_bound_tol = std::stod(argv[++i]);
        } else if (arg == "--per-attempt-max-iter") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--per-attempt-max-iter requires an integer value");
            }
            options.per_attempt_max_iter = std::stoi(argv[++i]);
        } else {
            throw std::runtime_error("Unknown argument: " + arg);
        }
    }

    return options;
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

AttemptSummary build_attempt_summary(
    int attempt,
    const std::string& status,
    const nimby_sidecar::TransitionReResults& results,
    const nimby_sidecar::TransitionReInput& input,
    const std::filesystem::path& output_dir,
    double gap_cutoff,
    double price_bound_tol) {
    AttemptSummary summary;
    summary.attempt = attempt;
    summary.status = status;
    summary.looks_stable = looks_stable(results, input, gap_cutoff, price_bound_tol);
    summary.converged = results.converged;
    summary.iterations = results.iterations;
    summary.final_label = results.final_label;
    summary.final_max_abs_gap = results.final_max_abs_gap;
    summary.final_residual_norm = results.final_residual_norm;
    summary.output_dir = output_dir;
    if (!results.final_price_path.empty()) {
        const auto [min_it, max_it] =
            std::minmax_element(results.final_price_path.begin(), results.final_price_path.end());
        summary.price_min = *min_it;
        summary.price_max = *max_it;
    }
    return summary;
}

void write_attempts_csv(const std::filesystem::path& path, const std::vector<AttemptSummary>& attempts) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write retry-aware attempts CSV: " + path.string());
    }
    output << "attempt,status,looks_stable,converged,iterations,final_label,final_max_abs_gap,final_residual_norm,price_min,price_max,output_dir\n";
    for (const auto& attempt : attempts) {
        output << attempt.attempt << ','
               << attempt.status << ','
               << (attempt.looks_stable ? 1 : 0) << ','
               << (attempt.converged ? 1 : 0) << ','
               << attempt.iterations << ','
               << attempt.final_label << ','
               << format_double(attempt.final_max_abs_gap) << ','
               << format_double(attempt.final_residual_norm) << ','
               << format_double(attempt.price_min) << ','
               << format_double(attempt.price_max) << ','
               << attempt.output_dir.string() << '\n';
    }
}

void write_summary_csv(
    const std::filesystem::path& path,
    int attempt_count,
    int selected_attempt,
    const AttemptSummary& final_attempt) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write retry-aware summary CSV: " + path.string());
    }
    output << "name,value\n";
    output << "attempt_count," << attempt_count << '\n';
    output << "selected_attempt," << selected_attempt << '\n';
    output << "looks_stable," << (final_attempt.looks_stable ? 1 : 0) << '\n';
    output << "final_max_abs_gap," << format_double(final_attempt.final_max_abs_gap) << '\n';
    output << "final_residual_norm," << format_double(final_attempt.final_residual_norm) << '\n';
    output << "price_min," << format_double(final_attempt.price_min) << '\n';
    output << "price_max," << format_double(final_attempt.price_max) << '\n';
}

void write_status_file(const std::filesystem::path& path, const std::string& status) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write retry-aware status file: " + path.string());
    }
    output << status << '\n';
}

nimby_sidecar::TransitionReResults solve_and_write_attempt(
    const nimby_sidecar::TransitionReInput& input,
    const std::filesystem::path& output_dir) {
    if (std::filesystem::exists(output_dir)) {
        std::filesystem::remove_all(output_dir);
    }
    std::filesystem::create_directories(output_dir);
    const auto results = nimby_sidecar::solve_transition_re(input);
    nimby_sidecar::write_transition_re_results(output_dir, results);
    return results;
}

}  // namespace

int main(int argc, char** argv) {
    try {
        const auto options = parse_args(argc, argv);
        std::filesystem::create_directories(options.output_dir);

        auto input = nimby_sidecar::read_transition_re_input_pack(options.input_dir);
        if (options.per_attempt_max_iter > 0) {
            input.options.max_iter = options.per_attempt_max_iter;
        }

        std::vector<AttemptSummary> attempts;

        const auto attempt1_dir = options.output_dir / "attempt1";
        const auto start1 = std::chrono::steady_clock::now();
        const auto attempt1_results = solve_and_write_attempt(input, attempt1_dir);
        const auto stop1 = std::chrono::steady_clock::now();
        auto attempt1 = build_attempt_summary(
            1,
            "ok",
            attempt1_results,
            input,
            attempt1_dir,
            options.gap_cutoff,
            options.price_bound_tol);
        attempts.push_back(attempt1);

        int selected_attempt = 1;
        std::string final_status = "ok";
        AttemptSummary final_attempt = attempt1;
        const double elapsed1 = std::chrono::duration<double>(stop1 - start1).count();

        if (!attempt1.looks_stable) {
            auto retry_input = input;
            retry_input.initial_price_path = attempt1_results.final_price_path;
            retry_input.transition_input.price_path = retry_input.initial_price_path;

            const auto attempt2_dir = options.output_dir / "attempt2";
            const auto start2 = std::chrono::steady_clock::now();
            const auto attempt2_results = solve_and_write_attempt(retry_input, attempt2_dir);
            const auto stop2 = std::chrono::steady_clock::now();
            auto attempt2 = build_attempt_summary(
                2,
                "ok_retry_failed",
                attempt2_results,
                retry_input,
                attempt2_dir,
                options.gap_cutoff,
                options.price_bound_tol);
            attempts.push_back(attempt2);

            selected_attempt = 2;
            final_attempt = attempt2;
            if (attempt2.looks_stable) {
                final_status = "ok_after_retry";
                final_attempt.status = final_status;
                attempts.back().status = final_status;
            } else {
                final_status = "ok_retry_failed";
            }

            const double elapsed2 = std::chrono::duration<double>(stop2 - start2).count();
            std::cout << "attempt_1_elapsed_seconds=" << format_double(elapsed1) << '\n';
            std::cout << "attempt_2_elapsed_seconds=" << format_double(elapsed2) << '\n';
        } else {
            std::cout << "attempt_1_elapsed_seconds=" << format_double(elapsed1) << '\n';
        }

        write_attempts_csv(options.output_dir / "sidecar_retryaware_attempts.csv", attempts);
        write_summary_csv(
            options.output_dir / "sidecar_retryaware_summary.csv",
            static_cast<int>(attempts.size()),
            selected_attempt,
            final_attempt);
        write_status_file(options.output_dir / "sidecar_retryaware_status.txt", final_status);

        std::cout << "Solved NIMBY retry-aware transition RE\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  per_attempt_max_iter: "
                  << (options.per_attempt_max_iter > 0 ? std::to_string(options.per_attempt_max_iter) : "input_default")
                  << '\n';
        std::cout << "  retryaware_status: " << final_status << '\n';
        std::cout << "  selected_attempt: " << selected_attempt << '\n';
        std::cout << "  looks_stable: " << (final_attempt.looks_stable ? 1 : 0) << '\n';
        std::cout << "  final_max_abs_gap: " << format_double(final_attempt.final_max_abs_gap) << '\n';
        std::cout << "  final_residual_norm: " << format_double(final_attempt.final_residual_norm) << '\n';
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_transition_re_retryaware_cli error: " << ex.what() << '\n';
        return 1;
    }
}
