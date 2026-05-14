#include "nimby_sidecar/transition_re_solver.hpp"

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
        throw std::runtime_error("Usage: nimby_transition_re_cli <input_dir> [--output-dir <path>]");
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
        const auto input = nimby_sidecar::read_transition_re_input_pack(options.input_dir);
        const auto results = nimby_sidecar::solve_transition_re(input);
        nimby_sidecar::write_transition_re_results(options.output_dir, results);

        std::cout << "Solved NIMBY bounded outer RE\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  iterations: " << results.iterations << '\n';
        std::cout << "  converged: " << (results.converged ? 1 : 0) << '\n';
        std::cout << "  final_label: " << results.final_label << '\n';
        std::cout << "  final_max_abs_gap: " << results.final_max_abs_gap << '\n';
        std::cout << "  final_residual_norm: " << results.final_residual_norm << '\n';
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_transition_re_cli error: " << ex.what() << '\n';
        return 1;
    }
}
