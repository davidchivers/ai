from __future__ import annotations

import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt


PROJECT_DIR = Path(__file__).resolve().parents[1]
DEFAULT_TRANSITION_CSV = (
    PROJECT_DIR
    / "calibration"
    / "self_employment_baseline"
    / "runtime"
    / "data"
    / "Output"
    / "case_test_new_147"
    / "mit_lowedu_sep010_from_baseline_20260310_122209_direct"
    / "transition_path.csv"
)
DEFAULT_MATRIX_CSV = PROJECT_DIR / "notes" / "self_employment_experiment_matrix.csv"
DEFAULT_BASELINE_BEST_RESULT = (
    PROJECT_DIR
    / "calibration"
    / "self_employment_baseline"
    / "runtime"
    / "data"
    / "Output"
    / "case_test_new_147_baseline_transition_init_20260310_122209"
    / "best_result.txt"
)
DEFAULT_OUTPUT_STEM = PROJECT_DIR / "figures" / "case147_mit_lowedu_sep010_irf"


def load_matrix_baseline(matrix_csv: Path) -> dict[str, float]:
    with matrix_csv.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        baseline = {}
        for row in reader:
            key = row["Parameter"]
            value = row["baseline_ui040"]
            if value == "":
                continue
            try:
                baseline[key] = float(value)
            except ValueError:
                continue
    return baseline


def load_transition(transition_csv: Path, max_period: int) -> list[dict[str, float]]:
    rows: list[dict[str, float]] = []
    with transition_csv.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            period = int(row["period"])
            if period > max_period:
                break
            rows.append({key: float(value) for key, value in row.items()})
    return rows


def load_low_education_unemployment(best_result_path: Path) -> float:
    lines = best_result_path.read_text(encoding="utf-8").strip().splitlines()
    low_education_line = lines[1].split()
    return float(low_education_line[1])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--transition-csv", type=Path, default=DEFAULT_TRANSITION_CSV)
    parser.add_argument("--matrix-csv", type=Path, default=DEFAULT_MATRIX_CSV)
    parser.add_argument("--baseline-best-result", type=Path, default=DEFAULT_BASELINE_BEST_RESULT)
    parser.add_argument("--output-stem", type=Path, default=DEFAULT_OUTPUT_STEM)
    parser.add_argument("--max-period", type=int, default=24)
    args = parser.parse_args()

    baseline = load_matrix_baseline(args.matrix_csv)
    baseline_low_unemployment = load_low_education_unemployment(args.baseline_best_result)
    transition = load_transition(args.transition_csv, args.max_period)

    periods = [row["period"] for row in transition]
    entrepreneur_pp = [
        100.0 * (row["entrepreneur_share"] - baseline["Entrepreneur share (all households)"])
        for row in transition
    ]
    entrepreneur_low_pp = [
        100.0 * (row["entrepreneur_share_low"] - baseline["Entrepreneur share (low education)"])
        for row in transition
    ]
    self_employed_pp = [
        100.0
        * (
            row["self_employed_share_among_entrepreneurs"]
            - baseline["Self-employed among entrepreneurs (all)"]
        )
        for row in transition
    ]
    unemployment_low_pp = [
        100.0 * (row["unemployment_share_low"] - baseline_low_unemployment)
        for row in transition
    ]

    plt.rcParams.update(
        {
            "font.size": 10,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.grid": False,
        }
    )

    fig, axes = plt.subplots(2, 2, figsize=(9.6, 6.2), constrained_layout=True)
    colors = {
        "primary": "#1f4e79",
        "secondary": "#8c2d04",
        "accent": "#2f6b2f",
        "neutral": "#444444",
    }

    panels = [
        (axes[0, 0], entrepreneur_pp, "Entrepreneurship", colors["primary"]),
        (axes[0, 1], entrepreneur_low_pp, "Entrepreneurship, low education", colors["secondary"]),
        (axes[1, 0], self_employed_pp, "Self-employment share", colors["accent"]),
        (axes[1, 1], unemployment_low_pp, "Unemployment, low education", colors["neutral"]),
    ]

    for axis, series, title, color in panels:
        axis.axhline(0.0, color="black", linewidth=0.8, alpha=0.6)
        axis.plot(periods, series, color=color, linewidth=2.2)
        axis.set_title(title)
        axis.margins(x=0.02)
        series_min = min(series)
        series_max = max(series)
        series_range = max(series_max - series_min, 0.25)
        pad = 0.12 * series_range
        axis.set_ylim(series_min - pad, series_max + pad)

    axes[1, 0].set_xlabel("Periods after shock")
    axes[1, 1].set_xlabel("Periods after shock")

    png_path = args.output_stem.with_suffix(".png")
    pdf_path = args.output_stem.with_suffix(".pdf")
    fig.savefig(png_path, dpi=220)
    fig.savefig(pdf_path)
    print(png_path.relative_to(PROJECT_DIR).as_posix())
    print(pdf_path.relative_to(PROJECT_DIR).as_posix())


if __name__ == "__main__":
    main()
