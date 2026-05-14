#include "nimby_sidecar/steady_state_solver.hpp"

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
        throw std::runtime_error("Usage: nimby_steady_state_cli <input_dir> [--output-dir <path>]");
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
        const auto input = nimby_sidecar::read_steady_state_input_pack(options.input_dir);
        const auto results = nimby_sidecar::solve_steady_state_reference(input);
        nimby_sidecar::write_steady_state_results(options.output_dir, results);

        std::cout << "Solved NIMBY steady-state reference\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  a_price: " << input.a_price << '\n';
        std::cout << "  Hdemand: " << results.Hdemand << '\n';
        std::cout << "  Hsupply: " << results.Hsupply << '\n';
        std::cout << "  debtstock: " << results.debtstock << '\n';
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_steady_state_cli error: " << ex.what() << '\n';
        return 1;
    }
}
