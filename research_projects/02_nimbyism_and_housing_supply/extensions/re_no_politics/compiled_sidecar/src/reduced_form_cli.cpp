#include "nimby_sidecar/reduced_form_solver.hpp"

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
        throw std::runtime_error("Usage: nimby_reduced_form_cli <input_dir> [--output-dir <path>]");
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
        const auto pack = nimby_sidecar::read_reduced_form_input_pack(options.input_dir);
        const auto results = nimby_sidecar::solve_reduced_form_price_path(
            pack.operator_data,
            pack.params,
            pack.initial_guess);
        nimby_sidecar::write_reduced_form_results(options.output_dir, results);

        std::cout << "Solved NIMBY reduced-form RE path\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  status: " << results.status << '\n';
        std::cout << "  iterations_completed: " << results.iterations_completed << '\n';
        std::cout << "  k: " << results.k << '\n';
        std::cout << "  start_index: " << results.start_index << '\n';
        std::cout << "  max_abs_gap: " << results.max_abs_gap << '\n';
        std::cout << "  max_abs_log_gap: " << results.max_abs_log_gap << '\n';
        if (!results.final_price_path.empty()) {
            std::cout << "  first_price: " << results.final_price_path.front() << '\n';
            std::cout << "  last_price: " << results.final_price_path.back() << '\n';
        }

        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_reduced_form_cli error: " << ex.what() << '\n';
        return 1;
    }
}
