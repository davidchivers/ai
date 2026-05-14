#include "nimby_sidecar/steady_state_solver.hpp"

#include <cmath>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

struct CliOptions {
    std::filesystem::path input_dir;
    std::filesystem::path output_dir;
    std::filesystem::path price_grid_csv;
    double price_min = std::numeric_limits<double>::quiet_NaN();
    double price_max = std::numeric_limits<double>::quiet_NaN();
    int price_count = 30;
};

struct SweepRow {
    double price = std::numeric_limits<double>::quiet_NaN();
    double Hdemand = std::numeric_limits<double>::quiet_NaN();
    double Hsupply = std::numeric_limits<double>::quiet_NaN();
    double excess_demand = std::numeric_limits<double>::quiet_NaN();
    double distance = std::numeric_limits<double>::quiet_NaN();
    double debtstock = std::numeric_limits<double>::quiet_NaN();
};

std::string trim(const std::string& value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) {
        return "";
    }
    const auto last = value.find_last_not_of(" \t\r\n");
    return value.substr(first, last - first + 1);
}

CliOptions parse_args(int argc, char** argv) {
    if (argc < 2) {
        throw std::runtime_error(
            "Usage: nimby_steady_state_sweep_cli <input_dir> "
            "[--output-dir <path>] [--price-min <double>] [--price-max <double>] "
            "[--price-count <int>] [--price-grid-csv <path>]");
    }

    CliOptions options;
    options.input_dir = argv[1];
    options.output_dir = options.input_dir.parent_path() / (options.input_dir.filename().string() + "_steady_state_sweep");

    for (int i = 2; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--output-dir") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--output-dir requires a path");
            }
            options.output_dir = argv[++i];
        } else if (arg == "--price-min") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-min requires a value");
            }
            options.price_min = std::stod(argv[++i]);
        } else if (arg == "--price-max") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-max requires a value");
            }
            options.price_max = std::stod(argv[++i]);
        } else if (arg == "--price-count") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-count requires a value");
            }
            options.price_count = std::stoi(argv[++i]);
        } else if (arg == "--price-grid-csv") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-grid-csv requires a path");
            }
            options.price_grid_csv = argv[++i];
        } else {
            throw std::runtime_error("Unknown argument: " + arg);
        }
    }

    return options;
}

std::vector<double> read_price_grid_csv(const std::filesystem::path& path) {
    std::ifstream input(path);
    if (!input) {
        throw std::runtime_error("Could not open price-grid CSV: " + path.string());
    }

    std::vector<double> prices;
    std::string line;
    while (std::getline(input, line)) {
        const auto field = trim(line);
        if (!field.empty()) {
            prices.push_back(std::stod(field));
        }
    }

    if (prices.empty()) {
        throw std::runtime_error("Price-grid CSV is empty: " + path.string());
    }
    return prices;
}

std::vector<double> build_price_grid(const CliOptions& options, double anchor_price) {
    if (!options.price_grid_csv.empty()) {
        return read_price_grid_csv(options.price_grid_csv);
    }

    if (options.price_count <= 0) {
        throw std::runtime_error("--price-count must be positive");
    }

    const double price_min = std::isnan(options.price_min) ? (anchor_price - 0.2) : options.price_min;
    const double price_max = std::isnan(options.price_max) ? (anchor_price + 0.2) : options.price_max;
    if (price_min > price_max) {
        throw std::runtime_error("--price-min cannot exceed --price-max");
    }

    std::vector<double> prices(static_cast<std::size_t>(options.price_count), price_min);
    if (options.price_count == 1) {
        prices.front() = price_min;
        return prices;
    }

    const double step = (price_max - price_min) / static_cast<double>(options.price_count - 1);
    for (int idx = 0; idx < options.price_count; ++idx) {
        prices[static_cast<std::size_t>(idx)] = price_min + step * static_cast<double>(idx);
    }
    return prices;
}

void write_sweep_csv(const std::filesystem::path& path, const std::vector<SweepRow>& rows) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write sweep CSV: " + path.string());
    }

    output << "price,Hdemand,Hsupply,excess_demand,distance,debtstock\n";
    output << std::setprecision(17);
    for (const auto& row : rows) {
        output << row.price << ','
               << row.Hdemand << ','
               << row.Hsupply << ','
               << row.excess_demand << ','
               << row.distance << ','
               << row.debtstock << '\n';
    }
}

void write_best_summary_csv(const std::filesystem::path& path, const SweepRow& best_row, std::size_t best_index) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write best-summary CSV: " + path.string());
    }

    output << "name,value\n";
    output << std::setprecision(17);
    output << "best_grid_index," << static_cast<double>(best_index + 1) << '\n';
    output << "best_price," << best_row.price << '\n';
    output << "best_Hdemand," << best_row.Hdemand << '\n';
    output << "best_Hsupply," << best_row.Hsupply << '\n';
    output << "best_excess_demand," << best_row.excess_demand << '\n';
    output << "best_distance," << best_row.distance << '\n';
    output << "best_debtstock," << best_row.debtstock << '\n';
}

}  // namespace

int main(int argc, char** argv) {
    try {
        const auto options = parse_args(argc, argv);
        const auto base_input = nimby_sidecar::read_steady_state_input_pack(options.input_dir);
        const auto prices = build_price_grid(options, base_input.a_price);

        std::filesystem::create_directories(options.output_dir);

        std::vector<SweepRow> rows;
        rows.reserve(prices.size());

        nimby_sidecar::SteadyStateResults best_results;
        SweepRow best_row;
        std::size_t best_index = 0;
        bool have_best = false;

        for (std::size_t idx = 0; idx < prices.size(); ++idx) {
            auto candidate_input = base_input;
            candidate_input.a_price = prices[idx];

            const auto results = nimby_sidecar::solve_steady_state_reference(candidate_input);
            const double excess_demand = results.Hdemand - results.Hsupply;

            SweepRow row;
            row.price = prices[idx];
            row.Hdemand = results.Hdemand;
            row.Hsupply = results.Hsupply;
            row.excess_demand = excess_demand;
            row.distance = excess_demand * excess_demand;
            row.debtstock = results.debtstock;
            rows.push_back(row);

            if (!have_best || row.distance < best_row.distance) {
                best_results = results;
                best_row = row;
                best_index = idx;
                have_best = true;
            }
        }

        if (!have_best) {
            throw std::runtime_error("No steady-state sweep results were produced.");
        }

        write_sweep_csv(options.output_dir / "sidecar_steady_state_sweep.csv", rows);
        write_best_summary_csv(options.output_dir / "sidecar_best_summary.csv", best_row, best_index);
        nimby_sidecar::write_steady_state_results(options.output_dir / "best", best_results);

        std::cout << "Solved NIMBY steady-state sweep\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  price_grid_count: " << prices.size() << '\n';
        std::cout << "  best_grid_index: " << (best_index + 1) << '\n';
        std::cout << "  best_price: " << best_row.price << '\n';
        std::cout << "  best_Hdemand: " << best_row.Hdemand << '\n';
        std::cout << "  best_Hsupply: " << best_row.Hsupply << '\n';
        std::cout << "  best_excess_demand: " << best_row.excess_demand << '\n';
        std::cout << "  best_distance: " << best_row.distance << '\n';
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_steady_state_sweep_cli error: " << ex.what() << '\n';
        return 1;
    }
}
