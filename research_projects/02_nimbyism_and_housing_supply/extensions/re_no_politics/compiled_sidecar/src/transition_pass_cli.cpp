#include "nimby_sidecar/transition_pass_solver.hpp"

#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

struct CliOptions {
    std::filesystem::path input_dir;
    std::filesystem::path output_dir;
};

CliOptions parse_args(int argc, char** argv) {
    if (argc < 2) {
        throw std::runtime_error("Usage: nimby_transition_pass_cli <input_dir> [--output-dir <path>]");
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
        const auto input = nimby_sidecar::read_transition_pass_input_pack(options.input_dir);
        const auto results = nimby_sidecar::solve_transition_pass(input);
        nimby_sidecar::write_transition_pass_results(options.output_dir, results);

        std::cout << "Solved NIMBY structural transition pass\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  horizon: " << input.T << '\n';
        std::cout << "  max_abs_gap: " << results.max_abs_gap << '\n';
        std::cout << "  residual_norm: " << results.residual_norm << '\n';
        if (!results.implied_price_path.empty()) {
            std::cout << "  first_implied_price: " << results.implied_price_path.front() << '\n';
            std::cout << "  last_implied_price: " << results.implied_price_path.back() << '\n';
        }
        if (!results.equal_weight_vote_path.empty()) {
            std::cout << "  first_equal_weight_vote: " << results.equal_weight_vote_path.front() << '\n';
            std::cout << "  last_equal_weight_vote: " << results.equal_weight_vote_path.back() << '\n';
        }
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_transition_pass_cli error: " << ex.what() << '\n';
        return 1;
    }
}
