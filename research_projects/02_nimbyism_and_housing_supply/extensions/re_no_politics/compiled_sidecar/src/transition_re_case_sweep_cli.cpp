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
#include <unordered_map>
#include <utility>
#include <vector>

namespace {

struct CliOptions {
    std::filesystem::path input_dir;
    std::filesystem::path case_csv;
    std::filesystem::path output_dir;
    double gap_cutoff = 0.05;
    double price_bound_tol = 1.0e-6;
    bool write_case_results = false;
};

struct CaseSpec {
    std::string case_name;
    std::string guess_source;
    std::string input_dir;
    int max_iter = 0;
    std::vector<double> guess;
};

struct CaseResult {
    std::string case_name;
    std::string guess_source;
    double alpha = std::numeric_limits<double>::quiet_NaN();
    int horizon = 0;
    int max_iter = 0;
    std::string status = "ok";
    int iterations_completed = 0;
    bool converged = false;
    bool looks_stable = false;
    double residual_norm = std::numeric_limits<double>::quiet_NaN();
    double max_abs_gap = std::numeric_limits<double>::quiet_NaN();
    double max_abs_update = std::numeric_limits<double>::quiet_NaN();
    std::string accepted_update;
    std::string final_label;
    double price_min = std::numeric_limits<double>::quiet_NaN();
    double price_max = std::numeric_limits<double>::quiet_NaN();
    double path_span = std::numeric_limits<double>::quiet_NaN();
    double policy_reference_price_first_used = std::numeric_limits<double>::quiet_NaN();
    double policy_reference_price_last_used = std::numeric_limits<double>::quiet_NaN();
    double elapsed_seconds = std::numeric_limits<double>::quiet_NaN();
    std::vector<double> start_path;
    std::vector<double> final_path;
    std::vector<double> implied_path;
    std::vector<double> policy_reference_path;
    std::vector<double> Hdemand_path;
    std::vector<double> Hsupply_path;
    std::vector<double> excess_demand_path;
};

std::string trim(const std::string& value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) {
        return "";
    }
    const auto last = value.find_last_not_of(" \t\r\n");
    return value.substr(first, last - first + 1);
}

std::vector<std::string> split_csv_line(const std::string& line) {
    std::vector<std::string> fields;
    std::string current;
    bool in_quotes = false;
    for (char ch : line) {
        if (ch == '"') {
            in_quotes = !in_quotes;
            continue;
        }
        if (ch == ',' && !in_quotes) {
            fields.push_back(trim(current));
            current.clear();
        } else {
            current.push_back(ch);
        }
    }
    fields.push_back(trim(current));
    return fields;
}

std::string format_double(double value) {
    if (std::isnan(value)) {
        return "NaN";
    }
    std::ostringstream out;
    out.precision(17);
    out << value;
    return out.str();
}

std::string sanitize_token(std::string value) {
    for (char& ch : value) {
        const bool ok = (ch >= '0' && ch <= '9') ||
                        (ch >= 'A' && ch <= 'Z') ||
                        (ch >= 'a' && ch <= 'z') ||
                        ch == '_' || ch == '-';
        if (!ok) {
            ch = '_';
        }
    }
    return value;
}

CliOptions parse_args(int argc, char** argv) {
    if (argc < 3) {
        throw std::runtime_error(
            "Usage: nimby_transition_re_case_sweep_cli <input_dir> <case_csv> "
            "[--output-dir <path>] [--gap-cutoff <double>] [--price-bound-tol <double>] "
            "[--write-case-results]");
    }

    CliOptions options;
    options.input_dir = argv[1];
    options.case_csv = argv[2];
    options.output_dir = options.input_dir.parent_path() / (options.input_dir.filename().string() + "_case_sweep");

    for (int i = 3; i < argc; ++i) {
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
        } else if (arg == "--write-case-results") {
            options.write_case_results = true;
        } else {
            throw std::runtime_error("Unknown argument: " + arg);
        }
    }

    return options;
}

std::vector<CaseSpec> read_case_specs(const std::filesystem::path& path, int expected_horizon) {
    std::ifstream input(path);
    if (!input) {
        throw std::runtime_error("Could not open case spec CSV: " + path.string());
    }

    std::string header_line;
    if (!std::getline(input, header_line)) {
        throw std::runtime_error("Case spec CSV is empty: " + path.string());
    }

    const auto headers = split_csv_line(header_line);
    std::unordered_map<std::string, std::size_t> header_index;
    for (std::size_t i = 0; i < headers.size(); ++i) {
        header_index.emplace(headers[i], i);
    }

    for (const auto& required : {"case_name", "guess_source", "max_iter"}) {
        if (header_index.find(required) == header_index.end()) {
            throw std::runtime_error("Missing required case-spec column: " + std::string(required));
        }
    }

    std::vector<std::size_t> price_columns;
    price_columns.reserve(static_cast<std::size_t>(expected_horizon));
    for (int period = 1; period <= expected_horizon; ++period) {
        const std::string column = "start_price_" + std::to_string(period);
        const auto it = header_index.find(column);
        if (it == header_index.end()) {
            throw std::runtime_error("Missing required case-spec column: " + column);
        }
        price_columns.push_back(it->second);
    }

    std::vector<CaseSpec> cases;
    std::string line;
    while (std::getline(input, line)) {
        if (trim(line).empty()) {
            continue;
        }
        const auto fields = split_csv_line(line);
        if (fields.size() < headers.size()) {
            throw std::runtime_error("Case-spec row has too few fields: " + line);
        }

        CaseSpec spec;
        spec.case_name = fields[header_index.at("case_name")];
        spec.guess_source = fields[header_index.at("guess_source")];
        if (header_index.find("input_dir") != header_index.end()) {
            spec.input_dir = fields[header_index.at("input_dir")];
        }
        spec.max_iter = std::stoi(fields[header_index.at("max_iter")]);
        spec.guess.reserve(static_cast<std::size_t>(expected_horizon));
        for (const auto index : price_columns) {
            spec.guess.push_back(std::stod(fields[index]));
        }
        cases.push_back(std::move(spec));
    }

    if (cases.empty()) {
        throw std::runtime_error("Case spec CSV has no rows: " + path.string());
    }
    return cases;
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

CaseResult run_case(
    const CaseSpec& spec,
    const nimby_sidecar::TransitionReInput& base_input,
    const CliOptions& options,
    const std::filesystem::path& output_dir) {
    CaseResult result;
    result.case_name = spec.case_name;
    result.guess_source = spec.guess_source;
    result.alpha = base_input.transition_input.policy_reference_blend_weight;
    result.horizon = base_input.transition_input.T;
    result.max_iter = spec.max_iter;
    result.start_path = spec.guess;

    auto case_input = base_input;
    case_input.initial_price_path = spec.guess;
    case_input.transition_input.price_path = spec.guess;
    case_input.options.max_iter = spec.max_iter;

    const auto start = std::chrono::steady_clock::now();
    try {
        const auto solved = nimby_sidecar::solve_transition_re(case_input);
        const auto stop = std::chrono::steady_clock::now();
        result.elapsed_seconds = std::chrono::duration<double>(stop - start).count();
        result.iterations_completed = solved.iterations;
        result.converged = solved.converged;
        result.looks_stable = looks_stable(solved, case_input, options.gap_cutoff, options.price_bound_tol);
        result.residual_norm = solved.final_residual_norm;
        result.max_abs_gap = solved.final_max_abs_gap;
        result.final_label = solved.final_label;
        result.final_path = solved.final_price_path;
        result.implied_path = solved.implied_price_path;
        result.policy_reference_path = solved.policy_reference_price_path_used;
        result.Hdemand_path = solved.Hdemand_path;
        result.Hsupply_path = solved.Hsupply_path;
        result.excess_demand_path = solved.excess_demand_path;

        if (!solved.iteration_log.empty()) {
            const auto& iter = solved.iteration_log.back();
            result.max_abs_update = iter.max_abs_update;
            result.accepted_update = iter.accepted_update;
        }

        if (!result.final_path.empty()) {
            const auto [min_it, max_it] = std::minmax_element(result.final_path.begin(), result.final_path.end());
            result.price_min = *min_it;
            result.price_max = *max_it;
            result.path_span = result.price_max - result.price_min;
        }
        if (!result.policy_reference_path.empty()) {
            result.policy_reference_price_first_used = result.policy_reference_path.front();
            result.policy_reference_price_last_used = result.policy_reference_path.back();
        }

        if (options.write_case_results) {
            const auto case_dir = output_dir / sanitize_token(spec.case_name);
            if (std::filesystem::exists(case_dir)) {
                std::filesystem::remove_all(case_dir);
            }
            std::filesystem::create_directories(case_dir);
            nimby_sidecar::write_transition_re_results(case_dir, solved);
        }
    } catch (const std::exception&) {
        const auto stop = std::chrono::steady_clock::now();
        result.elapsed_seconds = std::chrono::duration<double>(stop - start).count();
        result.status = "error";
        result.looks_stable = false;
    }

    return result;
}

void write_summary_csv(
    const std::filesystem::path& path,
    const std::vector<CaseResult>& results,
    int horizon) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write case-sweep summary CSV: " + path.string());
    }

    output << "case_name,guess_source,alpha,k,max_iter,status,iterations_completed,converged,looks_stable,"
              "residual_norm,max_abs_gap,max_abs_update,accepted_update,final_label,price_min,price_max,path_span,"
              "policy_reference_price_first_used,policy_reference_price_last_used,elapsed_seconds";
    for (int period = 1; period <= horizon; ++period) {
        output << ",start_price_" << period;
    }
    for (int period = 1; period <= horizon; ++period) {
        output << ",final_price_" << period;
    }
    for (int period = 1; period <= horizon; ++period) {
        output << ",implied_price_" << period;
    }
    output << '\n';

    for (const auto& result : results) {
        output << result.case_name << ','
               << result.guess_source << ','
               << format_double(result.alpha) << ','
               << result.horizon << ','
               << result.max_iter << ','
               << result.status << ','
               << result.iterations_completed << ','
               << (result.converged ? 1 : 0) << ','
               << (result.looks_stable ? 1 : 0) << ','
               << format_double(result.residual_norm) << ','
               << format_double(result.max_abs_gap) << ','
               << format_double(result.max_abs_update) << ','
               << result.accepted_update << ','
               << result.final_label << ','
               << format_double(result.price_min) << ','
               << format_double(result.price_max) << ','
               << format_double(result.path_span) << ','
               << format_double(result.policy_reference_price_first_used) << ','
               << format_double(result.policy_reference_price_last_used) << ','
               << format_double(result.elapsed_seconds);
        for (double value : result.start_path) {
            output << ',' << format_double(value);
        }
        for (int idx = 0; idx < horizon; ++idx) {
            const double value = idx < static_cast<int>(result.final_path.size())
                                     ? result.final_path[static_cast<std::size_t>(idx)]
                                     : std::numeric_limits<double>::quiet_NaN();
            output << ',' << format_double(value);
        }
        for (int idx = 0; idx < horizon; ++idx) {
            const double value = idx < static_cast<int>(result.implied_path.size())
                                     ? result.implied_path[static_cast<std::size_t>(idx)]
                                     : std::numeric_limits<double>::quiet_NaN();
            output << ',' << format_double(value);
        }
        output << '\n';
    }
}

void write_paths_csv(
    const std::filesystem::path& path,
    const std::vector<CaseResult>& results) {
    std::ofstream output(path);
    if (!output) {
        throw std::runtime_error("Could not write case-sweep paths CSV: " + path.string());
    }

    output << "case_name,guess_source,alpha,k,max_iter,period,start_price,final_price,implied_price,"
              "policy_reference_price_used,Hdemand,Hsupply,excess_demand\n";
    for (const auto& result : results) {
        for (int idx = 0; idx < result.horizon; ++idx) {
            const std::size_t period_index = static_cast<std::size_t>(idx);
            const double start_price = period_index < result.start_path.size()
                                           ? result.start_path[period_index]
                                           : std::numeric_limits<double>::quiet_NaN();
            const double final_price = period_index < result.final_path.size()
                                           ? result.final_path[period_index]
                                           : std::numeric_limits<double>::quiet_NaN();
            const double implied_price = period_index < result.implied_path.size()
                                             ? result.implied_path[period_index]
                                             : std::numeric_limits<double>::quiet_NaN();
            const double policy_reference_price = period_index < result.policy_reference_path.size()
                                                      ? result.policy_reference_path[period_index]
                                                      : std::numeric_limits<double>::quiet_NaN();
            const double hdemand = period_index < result.Hdemand_path.size()
                                       ? result.Hdemand_path[period_index]
                                       : std::numeric_limits<double>::quiet_NaN();
            const double hsupply = period_index < result.Hsupply_path.size()
                                       ? result.Hsupply_path[period_index]
                                       : std::numeric_limits<double>::quiet_NaN();
            const double excess = period_index < result.excess_demand_path.size()
                                      ? result.excess_demand_path[period_index]
                                      : std::numeric_limits<double>::quiet_NaN();

            output << result.case_name << ','
                   << result.guess_source << ','
                   << format_double(result.alpha) << ','
                   << result.horizon << ','
                   << result.max_iter << ','
                   << (idx + 1) << ','
                   << format_double(start_price) << ','
                   << format_double(final_price) << ','
                   << format_double(implied_price) << ','
                   << format_double(policy_reference_price) << ','
                   << format_double(hdemand) << ','
                   << format_double(hsupply) << ','
                   << format_double(excess) << '\n';
        }
    }
}

}  // namespace

int main(int argc, char** argv) {
    try {
        const auto options = parse_args(argc, argv);
        std::filesystem::create_directories(options.output_dir);

        const auto fallback_input = nimby_sidecar::read_transition_re_input_pack(options.input_dir);
        const auto cases = read_case_specs(options.case_csv, fallback_input.transition_input.T);
        std::unordered_map<std::string, nimby_sidecar::TransitionReInput> input_cache;

        std::vector<CaseResult> results;
        results.reserve(cases.size());
        for (const auto& spec : cases) {
            const nimby_sidecar::TransitionReInput* case_input = &fallback_input;
            if (!spec.input_dir.empty()) {
                auto it = input_cache.find(spec.input_dir);
                if (it == input_cache.end()) {
                    it = input_cache.emplace(
                        spec.input_dir,
                        nimby_sidecar::read_transition_re_input_pack(spec.input_dir)).first;
                }
                case_input = &it->second;
            }

            auto result = run_case(spec, *case_input, options, options.output_dir);
            std::cout << "case_name=" << result.case_name
                      << " status=" << result.status
                      << " looks_stable=" << (result.looks_stable ? 1 : 0)
                      << " max_abs_gap=" << format_double(result.max_abs_gap)
                      << " residual_norm=" << format_double(result.residual_norm)
                      << '\n';
            results.push_back(std::move(result));
        }

        write_summary_csv(options.output_dir / "sidecar_case_sweep_summary.csv", results, fallback_input.transition_input.T);
        write_paths_csv(options.output_dir / "sidecar_case_sweep_paths.csv", results);
        const auto copied_case_specs = options.output_dir / "case_specs.csv";
        if (std::filesystem::weakly_canonical(options.case_csv) != std::filesystem::weakly_canonical(copied_case_specs)) {
            std::filesystem::copy_file(
                options.case_csv,
                copied_case_specs,
                std::filesystem::copy_options::overwrite_existing);
        }

        std::cout << "Solved NIMBY transition RE case sweep\n";
        std::cout << "  input_dir: " << options.input_dir.string() << '\n';
        std::cout << "  case_csv: " << options.case_csv.string() << '\n';
        std::cout << "  output_dir: " << options.output_dir.string() << '\n';
        std::cout << "  case_count: " << results.size() << '\n';
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "nimby_transition_re_case_sweep_cli error: " << ex.what() << '\n';
        return 1;
    }
}
