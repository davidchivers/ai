#include "nimby_sidecar/political_bellman_solver.hpp"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

std::string trim(const std::string& value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) {
        return "";
    }
    const auto last = value.find_last_not_of(" \t\r\n");
    return value.substr(first, last - first + 1);
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

struct CliOptions {
    std::filesystem::path input_dir;
    std::filesystem::path output_dir;
    std::filesystem::path initial_price_path_csv;
    nimby_sidecar::PoliticalBellmanOptions political_options;
};

CliOptions parse_args(int argc, char** argv) {
    if (argc < 2) {
        throw std::runtime_error(
            "Usage: nimby_political_bellman_cli <input_dir> [--output-dir <path>] [--max-iter N] "
            "[--political-target equal_weight_vote] [--price-update-mode political_only] "
            "[--political-update-rule fixed_step|diagonal_secant] [--political-update-weight W] "
            "[--initial-price-path-csv <path>]");
    }

    CliOptions options;
    options.input_dir = argv[1];
    options.output_dir = options.input_dir;

    for (int i = 2; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--output-dir") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--output-dir requires a path");
            }
            options.output_dir = argv[++i];
        } else if (arg == "--initial-price-path-csv") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--initial-price-path-csv requires a path");
            }
            options.initial_price_path_csv = argv[++i];
        } else if (arg == "--max-iter") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--max-iter requires an integer");
            }
            options.political_options.max_iter = std::stoi(argv[++i]);
        } else if (arg == "--tol-vote") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--tol-vote requires a value");
            }
            options.political_options.tol_vote = std::stod(argv[++i]);
        } else if (arg == "--political-target") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--political-target requires a value");
            }
            options.political_options.political_target = argv[++i];
        } else if (arg == "--price-update-mode") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-update-mode requires a value");
            }
            options.political_options.price_update_mode = argv[++i];
        } else if (arg == "--political-update-rule") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--political-update-rule requires a value");
            }
            options.political_options.political_update_rule = argv[++i];
        } else if (arg == "--political-update-weight") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--political-update-weight requires a value");
            }
            options.political_options.political_update_weight = std::stod(argv[++i]);
        } else if (arg == "--max-update-frac") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--max-update-frac requires a value");
            }
            options.political_options.max_update_frac = std::stod(argv[++i]);
        } else if (arg == "--price-floor") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-floor requires a value");
            }
            options.political_options.price_floor = std::stod(argv[++i]);
        } else if (arg == "--price-cap") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-cap requires a value");
            }
            options.political_options.price_cap = std::stod(argv[++i]);
        } else if (arg == "--secant-damping") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--secant-damping requires a value");
            }
            options.political_options.secant_damping = std::stod(argv[++i]);
        } else if (arg == "--secant-min-abs-slope") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--secant-min-abs-slope requires a value");
            }
            options.political_options.secant_min_abs_slope = std::stod(argv[++i]);
        } else if (arg == "--guess-source") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--guess-source requires a value");
            }
            options.political_options.guess_source = argv[++i];
        } else {
            throw std::runtime_error("Unknown argument: " + arg);
        }
    }

    return options;
}

}  // namespace

int main(int argc, char** argv) {
    try {
        const auto options = parse_args(argc, argv);
        auto input = nimby_sidecar::read_transition_pass_input_pack(options.input_dir);
        if (!options.initial_price_path_csv.empty()) {
            const auto initial_price_path = read_single_column_csv(options.initial_price_path_csv);
            if (initial_price_path.size() != input.price_path.size()) {
                throw std::runtime_error("Initial price path length mismatch for " + options.initial_price_path_csv.string());
            }
            input.price_path = initial_price_path;
        }
        const auto results = nimby_sidecar::solve_political_bellman(input, options.political_options);
        nimby_sidecar::write_political_bellman_results(options.output_dir, results);

        std::cout << "Solved NIMBY compiled political Bellman wrapper\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  iterations: " << results.iterations << '\n';
        std::cout << "  converged: " << (results.converged ? 1 : 0) << '\n';
        std::cout << "  final_max_abs_vote: " << (results.iteration_log.empty() ? 0.0 : results.iteration_log.back().max_abs_vote) << '\n';
        std::cout << "  final_residual_norm: " << (results.iteration_log.empty() ? 0.0 : results.iteration_log.back().residual_norm) << '\n';
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_political_bellman_cli error: " << ex.what() << '\n';
        return 1;
    }
}
