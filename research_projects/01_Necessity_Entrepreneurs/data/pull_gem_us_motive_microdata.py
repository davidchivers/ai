from __future__ import annotations

import collections
import collections.abc
import io
import re
import shutil
import tempfile
import zipfile
from pathlib import Path
from typing import Iterable
from urllib.request import Request, urlopen

import matplotlib.pyplot as plt
import pandas as pd

# savReaderWriter uses deprecated imports on Python 3.13.
collections.Iterable = collections.abc.Iterable
collections.Mapping = collections.abc.Mapping
collections.MutableMapping = collections.abc.MutableMapping
collections.Sequence = collections.abc.Sequence

try:
    from savReaderWriter import SavHeaderReader, SavReader
except ModuleNotFoundError:
    SavHeaderReader = None
    SavReader = None


DATASETS_URL = "https://www.gemconsortium.org/data/sets"
FILE_URL = "https://www.gemconsortium.org/file/open?fileId={file_id}"
TARGET_YEARS = [2019, 2020, 2021]
OUTPUT_DIR = Path(__file__).resolve().parent
FIGURES_DIR = OUTPUT_DIR.parent / "figures"
OUT_WIDE_CSV = OUTPUT_DIR / "us_gem_tea_motive_shares_2019_2021.csv"
OUT_LONG_CSV = OUTPUT_DIR / "us_gem_tea_motive_shares_2019_2021_long.csv"
OUT_MOTIVE_PNG = OUTPUT_DIR / "us_gem_tea_motive_shares_2019_2021.png"
OUT_OVERLAP_CSV = OUTPUT_DIR / "us_gem_jobs_income_overlap_2019_2021.csv"
OUT_OVERLAP_LONG_CSV = OUTPUT_DIR / "us_gem_jobs_income_overlap_2019_2021_long.csv"
OUT_OVERLAP_PNG = OUTPUT_DIR / "us_gem_jobs_income_overlap_2019_2021.png"
OUT_OVERLAP_FIG_TEX = FIGURES_DIR / "us_gem_jobs_income_overlap_2019_2021.tex"
OUT_SUMMARY_TEX = OUTPUT_DIR / "us_gem_jobs_income_overlap_summary_2019_2021.tex"

TEA_MOTIVE_VARS = [
    "teayymot1yes",
    "teayymot2yes",
    "teayymot3yes",
    "teayymot4yes",
]

MOTIVE_LABELS = {
    "teayymot1yes": "Make a difference",
    "teayymot2yes": "High income / wealth",
    "teayymot3yes": "Family tradition",
    "teayymot4yes": "Jobs are scarce",
}

OVERLAP_LABELS = {
    "jobs_only_share": "Jobs scarce only",
    "jobs_and_income_share": "Both motives",
    "income_only_share": "High income only",
    "neither_jobs_nor_income_share": "Neither",
}


def fetch_text(url: str) -> str:
    request = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urlopen(request) as response:
        return response.read().decode("utf-8", errors="ignore")


def fetch_bytes(url: str) -> bytes:
    request = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urlopen(request) as response:
        return response.read()


def parse_file_ids(html: str, years: Iterable[int]) -> dict[int, str]:
    pattern = re.compile(
        r"<td>(GEM\s+(\d{4})\s+APS\s+Global\s+Individual\s+Level\s+Data[^<]*)</td>\s*"
        r"<td>\s*<button[^>]*file=\"(\d+)\"",
        flags=re.I | re.S,
    )
    file_ids: dict[int, str] = {}
    wanted = set(years)
    for title, year_str, file_id in pattern.findall(html):
        year = int(year_str)
        title_clean = re.sub(r"\s+", " ", title).strip()
        if year not in wanted:
            continue
        if "optional" in title_clean.lower() or "special topic" in title_clean.lower():
            continue
        file_ids[year] = file_id
    missing = wanted - set(file_ids)
    if missing:
        raise RuntimeError(f"Missing public GEM APS individual files for years: {sorted(missing)}")
    return file_ids


def extract_first_sav(zip_bytes: bytes, temp_dir: Path) -> Path:
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as zf:
        sav_names = [name for name in zf.namelist() if name.lower().endswith(".sav")]
        if not sav_names:
            raise RuntimeError("Downloaded GEM archive did not contain an SPSS .sav file")
        sav_name = sav_names[0]
        zf.extract(sav_name, path=temp_dir)
        return temp_dir / sav_name


def resolve_var_names(sav_path: Path, requested_lower: Iterable[str]) -> dict[str, str]:
    if SavHeaderReader is None:
        raise RuntimeError("savReaderWriter is not installed in this Python environment")
    requested = list(requested_lower)
    with SavHeaderReader(str(sav_path), ioUtf8=True) as header:
        lookup = {name.lower(): name for name in header.varNames}
    missing = [name for name in requested if name not in lookup]
    if missing:
        raise RuntimeError(f"Missing expected variables in {sav_path.name}: {missing}")
    return {name: lookup[name] for name in requested}


def compute_year_summary(sav_path: Path, year: int) -> dict[str, float]:
    if SavReader is None:
        raise RuntimeError("savReaderWriter is not installed in this Python environment")
    requested = ["ctryalp", "country_name", "weight_a", "teayy", *TEA_MOTIVE_VARS]
    resolved = resolve_var_names(sav_path, requested)
    select_vars = [resolved[name] for name in requested]
    weighted_counts = {var: 0.0 for var in TEA_MOTIVE_VARS}
    overlap_counts = {
        "jobs_only_share": 0.0,
        "jobs_and_income_share": 0.0,
        "income_only_share": 0.0,
        "neither_jobs_nor_income_share": 0.0,
    }
    weight_total = 0.0
    raw_n = 0

    with SavReader(str(sav_path), ioUtf8=True, returnHeader=True, selectVars=select_vars) as reader:
        header_row = next(reader)
        index = {name.lower(): i for i, name in enumerate(header_row)}
        for row in reader:
            if row == header_row:
                continue
            ctryalp = row[index[resolved["ctryalp"].lower()]]
            country_name = row[index[resolved["country_name"].lower()]]
            weight_a = row[index[resolved["weight_a"].lower()]]
            teayy = row[index[resolved["teayy"].lower()]]
            if ctryalp != "US" or country_name != "United States":
                continue
            if teayy != 1.0 or weight_a in (None, 0.0):
                continue

            weight = float(weight_a)
            weight_total += weight
            raw_n += 1

            motive_values: dict[str, bool] = {}
            for var in TEA_MOTIVE_VARS:
                value = row[index[resolved[var].lower()]]
                motive_values[var] = value == 1.0
                if motive_values[var]:
                    weighted_counts[var] += weight

            jobs = motive_values["teayymot4yes"]
            income = motive_values["teayymot2yes"]
            if jobs and income:
                overlap_counts["jobs_and_income_share"] += weight
            elif jobs:
                overlap_counts["jobs_only_share"] += weight
            elif income:
                overlap_counts["income_only_share"] += weight
            else:
                overlap_counts["neither_jobs_nor_income_share"] += weight

    summary: dict[str, float] = {
        "year": year,
        "us_tea_raw_n": raw_n,
        "us_tea_weight_sum": weight_total,
    }
    for var in TEA_MOTIVE_VARS:
        summary[var] = weighted_counts[var] / weight_total if weight_total else float("nan")
    for var in overlap_counts:
        summary[var] = overlap_counts[var] / weight_total if weight_total else float("nan")
    return summary


def write_motive_figure(long_df: pd.DataFrame) -> None:
    plt.style.use("seaborn-v0_8-whitegrid")
    fig, ax = plt.subplots(figsize=(9.5, 5.2))
    colors = {
        "Make a difference": "#0b6e4f",
        "High income / wealth": "#d17b0f",
        "Family tradition": "#6b7280",
        "Jobs are scarce": "#b42318",
    }
    for label, plot_df in long_df.groupby("motive_label"):
        ax.plot(
            plot_df["year"],
            plot_df["share_pct"],
            marker="o",
            linewidth=2.2,
            markersize=6,
            label=label,
            color=colors.get(label),
        )

    ax.set_title("United States GEM microdata: TEA motive shares")
    ax.set_xlabel("Survey year")
    ax.set_ylabel("Weighted share of early-stage entrepreneurs (%)")
    ax.set_ylim(0, 100)
    ax.set_xticks(TARGET_YEARS)
    ax.set_xlim(min(TARGET_YEARS) - 0.1, max(TARGET_YEARS) + 0.1)
    ax.legend(frameon=True, ncols=2)
    ax.text(
        0.01,
        -0.18,
        "Notes: weighted by GEM WEIGHT_A; shares are not mutually exclusive because respondents can endorse multiple motives.",
        transform=ax.transAxes,
        fontsize=9,
    )
    fig.tight_layout()
    fig.savefig(OUT_MOTIVE_PNG, dpi=200)
    plt.close(fig)


def write_overlap_figure(overlap_long_df: pd.DataFrame, wide_df: pd.DataFrame) -> None:
    plt.style.use("seaborn-v0_8-whitegrid")
    fig, (ax_left, ax_right) = plt.subplots(
        1,
        2,
        figsize=(10.6, 5.2),
        gridspec_kw={"width_ratios": [1.0, 1.15]},
    )

    years = wide_df["year"].tolist()
    x_positions = list(range(len(years)))
    bar_width = 0.32

    jobs_pct = 100 * wide_df["teayymot4yes"]
    income_pct = 100 * wide_df["teayymot2yes"]
    ax_left.bar(
        [x - bar_width / 2 for x in x_positions],
        jobs_pct,
        width=bar_width,
        color="#b42318",
        label="Jobs are scarce",
    )
    ax_left.bar(
        [x + bar_width / 2 for x in x_positions],
        income_pct,
        width=bar_width,
        color="#d17b0f",
        label="High income / wealth",
    )
    for x, value in zip([x - bar_width / 2 for x in x_positions], jobs_pct):
        ax_left.text(x, value + 1.5, f"{value:.0f}", ha="center", va="bottom", fontsize=9)
    for x, value in zip([x + bar_width / 2 for x in x_positions], income_pct):
        ax_left.text(x, value + 1.5, f"{value:.0f}", ha="center", va="bottom", fontsize=9)

    ax_left.set_title("Marginal motive shares")
    ax_left.set_ylabel("Share of U.S. TEA (%)")
    ax_left.set_xticks(x_positions, years)
    ax_left.set_ylim(0, 100)
    ax_left.legend(frameon=False, loc="upper left")
    ax_left.grid(axis="y", alpha=0.25, linewidth=0.7)
    ax_left.grid(axis="x", visible=False)

    stack_order = [
        "jobs_only_share",
        "jobs_and_income_share",
        "income_only_share",
        "neither_jobs_nor_income_share",
    ]
    colors = {
        "jobs_only_share": "#d95f02",
        "jobs_and_income_share": "#7f0000",
        "income_only_share": "#f1a340",
        "neither_jobs_nor_income_share": "#bdbdbd",
    }
    bottom = pd.Series(0.0, index=wide_df.index)
    for var in stack_order:
        shares_pct = 100 * wide_df[var]
        ax_right.bar(
            years,
            shares_pct,
            bottom=bottom,
            color=colors[var],
            label=OVERLAP_LABELS[var],
            width=0.62,
        )
        for x, start, height in zip(years, bottom, shares_pct):
            if height >= 8:
                ax_right.text(
                    x,
                    start + height / 2,
                    f"{height:.0f}",
                    ha="center",
                    va="center",
                    fontsize=9,
                    color="white" if var != "income_only_share" else "black",
                )
        bottom += shares_pct

    ax_right.set_title("Overlap in necessity and opportunity signals")
    ax_right.set_ylabel("Share of U.S. TEA (%)")
    ax_right.set_xticks(years, years)
    ax_right.set_ylim(0, 100)
    ax_right.grid(axis="y", alpha=0.25, linewidth=0.7)
    ax_right.grid(axis="x", visible=False)
    ax_right.legend(frameon=False, loc="upper left")

    fig.suptitle("United States GEM microdata: necessity and opportunity motives", y=0.99)
    fig.text(
        0.01,
        0.01,
        "Notes: weighted by GEM WEIGHT_A; TEA = early-stage entrepreneurs in the public 2019-2021 APS files; multiple motives can be endorsed by the same respondent.",
        ha="left",
        va="bottom",
        fontsize=8.8,
    )
    fig.tight_layout(rect=(0, 0.05, 1, 0.95))
    fig.savefig(OUT_OVERLAP_PNG, dpi=220, facecolor="white")
    plt.close(fig)


def write_overlap_pgfplots(wide_df: pd.DataFrame) -> None:
    FIGURES_DIR.mkdir(exist_ok=True)
    ymin = 0.0
    ymax = 100.0
    years = ",".join(str(year) for year in wide_df["year"].tolist())
    stack_order = [
        ("jobs_only_share", "Jobs scarce only", "orange!85!black"),
        ("jobs_and_income_share", "Both motives", "red!70!black"),
        ("income_only_share", "High income only", "yellow!70!orange"),
        ("neither_jobs_nor_income_share", "Neither", "black!25"),
    ]
    lines = [
        "% Auto-generated by pull_gem_us_motive_microdata.py",
        "\\begin{tikzpicture}",
        "\\begin{axis}[",
        "width=0.82\\textwidth,",
        "height=0.50\\textwidth,",
        "ybar stacked,",
        "bar width=18pt,",
        "title={US GEM microdata: overlap in necessity and opportunity signals},",
        "ylabel={Share of U.S. TEA (\\%)},",
        "xlabel={},",
        f"symbolic x coords={{{years}}},",
        f"xtick=data, ymin={ymin:.1f}, ymax={ymax:.1f},",
        "ymajorgrids=true,",
        "grid style={gray!30},",
        "tick align=outside,",
        "axis line style={black!70},",
        "tick style={black!70},",
        "legend cell align={left},",
        "legend style={draw=none, fill=none, at={(0.02,0.98)}, anchor=north west, font=\\small},",
        "nodes near coords,",
        "every node near coord/.append style={font=\\scriptsize, /pgf/number format/fixed, /pgf/number format/precision=0},",
        "point meta=explicit symbolic,",
        "]",
    ]
    for var, _, color in stack_order:
        coords = " ".join(
            f"({int(row.year)},{100 * getattr(row, var):.4f}[{100 * getattr(row, var):.0f}])"
            for row in wide_df.itertuples(index=False)
        )
        lines.append(f"\\addplot+[draw=none, fill={color}] coordinates {{{coords}}};")
    legend_items = ",".join(label for _, label, _ in stack_order)
    lines.extend(
        [
            f"\\legend{{{legend_items}}}",
            "\\end{axis}",
            "\\end{tikzpicture}",
            "",
        ]
    )
    OUT_OVERLAP_FIG_TEX.write_text("\n".join(lines), encoding="utf-8")


def write_summary_table_tex(wide_df: pd.DataFrame) -> None:
    lines = [
        "% Auto-generated by pull_gem_us_motive_microdata.py",
        "\\begin{tabular}{lrrrr}",
        "\\hline",
        "Year & Jobs scarce & High income & Both motives & Jobs scarce only \\\\",
        "\\hline",
    ]
    for row in wide_df.itertuples(index=False):
        lines.append(
            f"{int(row.year)} & {100 * row.teayymot4yes:.1f}\\% & {100 * row.teayymot2yes:.1f}\\% & {100 * row.jobs_and_income_share:.1f}\\% & {100 * row.jobs_only_share:.1f}\\% \\\\"
        )
    lines.extend(
        [
            "\\hline",
            "\\end{tabular}",
            "",
        ]
    )
    OUT_SUMMARY_TEX.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    if SavReader is None or SavHeaderReader is None:
        if not OUT_WIDE_CSV.exists():
            raise RuntimeError(
                "savReaderWriter is not installed and no cached GEM summary CSV exists at "
                f"{OUT_WIDE_CSV}"
            )
        wide_df = pd.read_csv(OUT_WIDE_CSV).sort_values("year")
    else:
        html = fetch_text(DATASETS_URL)
        file_ids = parse_file_ids(html, TARGET_YEARS)

        summaries = []
        temp_root = Path(tempfile.mkdtemp(prefix="gem_us_motives_"))
        try:
            for year in TARGET_YEARS:
                year_dir = temp_root / str(year)
                year_dir.mkdir(parents=True, exist_ok=True)

                zip_bytes = fetch_bytes(FILE_URL.format(file_id=file_ids[year]))
                sav_path = extract_first_sav(zip_bytes, year_dir)
                summaries.append(compute_year_summary(sav_path, year))
        finally:
            for _ in range(3):
                try:
                    import time

                    time.sleep(0.25)
                    shutil.rmtree(temp_root)
                    break
                except Exception:
                    continue

        wide_df = pd.DataFrame(summaries).sort_values("year")
    wide_df.to_csv(OUT_WIDE_CSV, index=False)

    long_df = wide_df.melt(
        id_vars=["year", "us_tea_raw_n", "us_tea_weight_sum"],
        value_vars=TEA_MOTIVE_VARS,
        var_name="motive_var",
        value_name="share",
    )
    long_df["motive_label"] = long_df["motive_var"].map(MOTIVE_LABELS)
    long_df["share_pct"] = 100 * long_df["share"]
    long_df.to_csv(OUT_LONG_CSV, index=False)

    overlap_vars = list(OVERLAP_LABELS)
    overlap_df = wide_df[["year", "us_tea_raw_n", "us_tea_weight_sum", *overlap_vars]].copy()
    overlap_df.to_csv(OUT_OVERLAP_CSV, index=False)
    overlap_long_df = overlap_df.melt(
        id_vars=["year", "us_tea_raw_n", "us_tea_weight_sum"],
        value_vars=overlap_vars,
        var_name="overlap_var",
        value_name="share",
    )
    overlap_long_df["overlap_label"] = overlap_long_df["overlap_var"].map(OVERLAP_LABELS)
    overlap_long_df["share_pct"] = 100 * overlap_long_df["share"]
    overlap_long_df.to_csv(OUT_OVERLAP_LONG_CSV, index=False)

    write_motive_figure(long_df)
    write_overlap_figure(overlap_long_df, wide_df)
    write_overlap_pgfplots(wide_df)
    write_summary_table_tex(wide_df)

    note = OUTPUT_DIR / "gem_us_microdata_note.md"
    note.write_text(
        "\n".join(
            [
                "# GEM U.S. microdata note",
                "",
                "Status: sidecar extract from official GEM APS individual-level public files.",
                "",
                "Last updated: 2026-03-08",
                "",
                "## What this file set is",
                "",
                "- `us_gem_tea_motive_shares_2019_2021.csv`: wide annual summary for the United States.",
                "- `us_gem_tea_motive_shares_2019_2021_long.csv`: long-format version for plotting.",
                "- `us_gem_tea_motive_shares_2019_2021.png`: broad four-motive trend figure.",
                "- `us_gem_jobs_income_overlap_2019_2021.csv`: overlap shares for jobs-scarce and high-income motives.",
                "- `us_gem_jobs_income_overlap_2019_2021_long.csv`: long-format overlap version.",
                "- `us_gem_jobs_income_overlap_2019_2021.png`: recommended figure for the introduction.",
                "- `us_gem_jobs_income_overlap_summary_2019_2021.tex`: compact TeX summary table for prose or footnote use.",
                "- `../figures/us_gem_jobs_income_overlap_2019_2021.tex`: optional paper-facing pgfplots figure.",
                "",
                "## Data construction",
                "",
                "- Source page: https://www.gemconsortium.org/data/sets",
                "- Public APS individual-level files used: 2019, 2020, 2021.",
                "- Country filter: `ctryalp == \"US\"` and `country_name == \"United States\"`.",
                "- Entrepreneur filter: `TEAyy == 1`.",
                "- Weights: `WEIGHT_A`.",
                "- Motive variables:",
                "  - `TEAyyMOT1yes`: make a difference in the world",
                "  - `TEAyyMOT2yes`: build great wealth or a very high income",
                "  - `TEAyyMOT3yes`: continue a family tradition",
                "  - `TEAyyMOT4yes`: earn a living because jobs are scarce",
                "",
                "## Interpretation cautions",
                "",
                "- These are motive shares among early-stage entrepreneurs, not population shares.",
                "- The four motives are not mutually exclusive, so the shares do not sum to 100.",
                "- The overlap figure is the key reason the GEM evidence is informative: it shows that necessity and opportunity signals coexist within the same observed entrepreneurial spell.",
                "- The jobs-scarce item is the cleanest public necessity-style motive in the current APS file.",
                "- The public APS individual-level page currently exposes 2021 as the latest cleanly verifiable microdata release; 2022-2023 U.S. motive updates therefore still rely on report evidence rather than public respondent-level files.",
                "",
                "## Why this matters for the paper",
                "",
                "- This provides direct U.S. motive evidence from microdata rather than only report summaries.",
                "- It supports opening the paper with the identification problem and then using recession evidence as a complementary, not exclusive, source of motivation.",
                "- The most informative visual is the overlap between `jobs are scarce` and `high income / wealth`, not a generic four-line time-series chart.",
                "- The compact TeX table is the easiest object to cite in the main text if we keep GEM as prose rather than as a headline figure.",
            ]
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
