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
    double price_multiplier = 1.01;
};

struct SweepRow {
    double price = std::numeric_limits<double>::quiet_NaN();
    double distance = std::numeric_limits<double>::quiet_NaN();
    double totalvote = std::numeric_limits<double>::quiet_NaN();
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
            "Usage: nimby_steady_state_political_sweep_cli <input_dir> "
            "[--output-dir <path>] [--price-min <double>] [--price-max <double>] "
            "[--price-count <int>] [--price-grid-csv <path>] [--price-multiplier <double>]");
    }

    CliOptions options;
    options.input_dir = argv[1];
    options.output_dir = options.input_dir.parent_path() / (options.input_dir.filename().string() + "_political_sweep");

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
        } else if (arg == "--price-multiplier") {
            if (i + 1 >= argc) {
                throw std::runtime_error("--price-multiplier requires a value");
            }
            options.price_multiplier = std::stod(argv[++i]);
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

    output << "price,distance,totalvote,debtstock\n";
    output << std::setprecision(17);
    for (const auto& row : rows) {
        output << row.price << ','
               << row.distance << ','
               << row.totalvote << ','
               << row.debtstock << '\n';
    }
}

void write_summary_csv(
    const std::filesystem::path& path,
    double price_multiplier,
    const SweepRow& best_row,
    double best_distance_price,
    bool has_vote_bracket,
    double bracket_low_price,
    double bracket_high_price,
    double bracket_low_vote,
    double bracket_high_vote) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write summary CSV: " + path.string());
    }

    output << "price_multiplier,best_distance,best_distance_price,best_vote_abs,best_vote_abs_price,has_vote_bracket,"
              "bracket_low_price,bracket_high_price,bracket_low_vote,bracket_high_vote\n";
    output << std::setprecision(17);
    output << price_multiplier << ','
           << best_row.distance << ','
           << best_distance_price << ','
           << std::abs(best_row.totalvote) << ','
           << best_row.price << ','
           << (has_vote_bracket ? 1 : 0) << ','
           << bracket_low_price << ','
           << bracket_high_price << ','
           << bracket_low_vote << ','
           << bracket_high_vote << '\n';
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

        SweepRow best_vote_row;
        SweepRow best_distance_row;
        bool have_best = false;
        bool have_best_distance = false;
        bool has_vote_bracket = false;
        double bracket_low_price = std::numeric_limits<double>::quiet_NaN();
        double bracket_high_price = std::numeric_limits<double>::quiet_NaN();
        double bracket_low_vote = std::numeric_limits<double>::quiet_NaN();
        double bracket_high_vote = std::numeric_limits<double>::quiet_NaN();

        for (double price : prices) {
            auto candidate_input = base_input;
            candidate_input.a_price = price;

            const auto results =
                nimby_sidecar::solve_steady_state_political_reference(candidate_input, options.price_multiplier);

            SweepRow row;
            row.price = price;
            row.distance = results.distance;
            row.totalvote = results.totalvote;
            row.debtstock = results.baseline.debtstock;
            rows.push_back(row);

            if (!have_best || std::abs(row.totalvote) < std::abs(best_vote_row.totalvote)) {
                best_vote_row = row;
                have_best = true;
            }
            if (!have_best_distance || row.distance < best_distance_row.distance) {
                best_distance_row = row;
                have_best_distance = true;
            }

            if (!has_vote_bracket && rows.size() >= 2) {
                const auto& previous = rows[rows.size() - 2];
                if (previous.totalvote * row.totalvote <= 0.0) {
                    has_vote_bracket = true;
                    bracket_low_price = previous.price;
                    bracket_high_price = row.price;
                    bracket_low_vote = previous.totalvote;
                    bracket_high_vote = row.totalvote;
                }
            }
        }

        if (!have_best || !have_best_distance) {
            throw std::runtime_error("No political sweep results were produced.");
        }

        write_sweep_csv(options.output_dir / "sidecar_steady_state_political_sweep.csv", rows);
        write_summary_csv(
            options.output_dir / "sidecar_steady_state_political_summary.csv",
            options.price_multiplier,
            best_vote_row,
            best_distance_row.price,
            has_vote_bracket,
            bracket_low_price,
            bracket_high_price,
            bracket_low_vote,
            bracket_high_vote);

        std::cout << "Solved NIMBY steady-state political sweep\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  price_grid_count: " << prices.size() << '\n';
        std::cout << "  best_vote_abs_price: " << best_vote_row.price << '\n';
        std::cout << "  best_vote_abs: " << std::abs(best_vote_row.totalvote) << '\n';
        std::cout << "  best_distance_price: " << best_distance_row.price << '\n';
        std::cout << "  best_distance: " << best_distance_row.distance << '\n';
        if (has_vote_bracket) {
            std::cout << "  bracket_low_price: " << bracket_low_price << '\n';
            std::cout << "  bracket_high_price: " << bracket_high_price << '\n';
        } else {
            std::cout << "  bracket: none\n";
        }
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_steady_state_political_sweep_cli error: " << ex.what() << '\n';
        return 1;
    }
}
