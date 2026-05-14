#include "nimby_sidecar/steady_state_solver.hpp"

#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

struct CliOptions {
    std::filesystem::path input_dir;
    std::filesystem::path output_dir;
    double price_multiplier = 1.01;
    double trial_price = 0.0;
    bool has_trial_price = false;
};

CliOptions parse_args(int argc, char** argv) {
    if (argc < 2) {
        throw std::runtime_error(
            "Usage: nimby_steady_state_political_cli <input_dir> "
            "[--output-dir <path>] [--price-multiplier <double>] [--trial-price <double>]");
    }

    CliOptions options;
    options.input_dir = argv[1];
    options.output_dir = options.input_dir.parent_path() / (options.input_dir.filename().string() + "_political_object");

    for (int i = 2; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--output-dir") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--output-dir requires a path");
            }
            options.output_dir = argv[++i];
        } else if (arg == "--price-multiplier") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-multiplier requires a value");
            }
            options.price_multiplier = std::stod(argv[++i]);
        } else if (arg == "--trial-price") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--trial-price requires a value");
            }
            options.trial_price = std::stod(argv[++i]);
            options.has_trial_price = true;
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
        auto input = nimby_sidecar::read_steady_state_input_pack(options.input_dir);
        if (options.has_trial_price) {
            input.a_price = options.trial_price;
        }
        const auto results = nimby_sidecar::solve_steady_state_political_reference(input, options.price_multiplier);
        nimby_sidecar::write_steady_state_political_results(options.output_dir, results);

        std::cout << "Solved NIMBY steady-state political prototype\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  trial_price: " << results.trial_price << '\n';
        std::cout << "  perturbed_price: " << results.perturbed_price << '\n';
        std::cout << "  price_multiplier: " << results.price_multiplier << '\n';
        std::cout << "  totalvote: " << results.totalvote << '\n';
        std::cout << "  distance: " << results.distance << '\n';
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_steady_state_political_cli error: " << ex.what() << '\n';
        return 1;
    }
}
