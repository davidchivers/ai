import argparse
import csv
import math
import re
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "notes" / "build"
STATUS_MD = ROOT / "STATUS.md"
MEMORY_MD = ROOT / "memory.md"
SUMMARY_MD = BUILD_DIR / "fertility_benchmark_refresh_handoff.md"
SUMMARY_CSV = BUILD_DIR / "fertility_vs_nimby_benchmark_summary.csv"
REPRO_CSV = BUILD_DIR / "fertility_vs_nimby_reproduction_check.csv"


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--job-id", required=True)
    parser.add_argument("--state", required=True)
    parser.add_argument("--exit-code", default="")
    parser.add_argument("--elapsed", default="")
    parser.add_argument("--node", default="")
    parser.add_argument("--remote-run-dir", default="")
    parser.add_argument("--sync-trackers", action="store_true")
    return parser.parse_args()


def replace_once(text, pattern, replacement):
    new_text, count = re.subn(pattern, replacement, text, flags=re.S)
    if count != 1:
        raise RuntimeError(f"Expected one match for pattern: {pattern}")
    return new_text


def to_float(value):
    text = (value or "").strip()
    if text == "" or text.lower() == "nan":
        return math.nan
    return float(text)


def format_optional(value, digits=6):
    if math.isnan(value):
        return "n.a."
    return f"{value:.{digits}f}"


def load_summary():
    if not SUMMARY_CSV.exists():
        return {}

    out = {}
    with SUMMARY_CSV.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            out[row["model"]] = {
                "refined_price": to_float(row.get("refined_price")),
                "vote_per_mass": to_float(row.get("vote_per_mass")),
                "mass": to_float(row.get("mass")),
                "avg_birth_rate": to_float(row.get("avg_birth_rate")),
                "mean_age_first_birth": to_float(row.get("mean_age_first_birth")),
                "share_first_birth_30_plus": to_float(row.get("share_first_birth_30_plus")),
            }
    return out


def load_repro():
    if not REPRO_CSV.exists():
        return {}

    with REPRO_CSV.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        return {}
    row = rows[0]
    return {
        "distance_gap": to_float(row.get("distance_gap")),
        "vote_gap": to_float(row.get("vote_gap")),
        "debt_gap": to_float(row.get("debt_gap")),
    }


def build_summary(args, summary, repro):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines = [
        "# Hamilton fertility benchmark refresh handoff",
        "",
        f"Generated: {now}",
        f"Job: `{args.job_id}`",
        f"State: `{args.state}`",
        f"Exit code: `{args.exit_code or 'n.a.'}`",
        f"Elapsed: `{args.elapsed or 'n.a.'}`",
        f"Node: `{args.node or 'n.a.'}`",
    ]

    if args.remote_run_dir:
        lines.append(f"Remote run dir: `{args.remote_run_dir}`")
    lines.extend(["", "## Outcome", ""])

    if args.state == "COMPLETED" and args.exit_code == "0:0" and summary:
        nimby = summary.get("nimby", {})
        fertility = summary.get("fertility", {})
        lines.extend(
            [
                "- Completed the long 5-year benchmark refresh.",
                f"- NIMBY refined crossing price: `{format_optional(nimby.get('refined_price', math.nan))}`.",
                f"- Fertility refined crossing price: `{format_optional(fertility.get('refined_price', math.nan))}`.",
                f"- NIMBY vote-per-mass at crossing: `{format_optional(nimby.get('vote_per_mass', math.nan))}`.",
                f"- Fertility vote-per-mass at crossing: `{format_optional(fertility.get('vote_per_mass', math.nan))}`.",
                f"- Fertility average birth rate at crossing: `{format_optional(fertility.get('avg_birth_rate', math.nan))}`.",
                f"- Fertility mean age at first birth at crossing: `{format_optional(fertility.get('mean_age_first_birth', math.nan))}`.",
                f"- Fertility share of first births at age 30+: `{format_optional(fertility.get('share_first_birth_30_plus', math.nan))}`.",
            ]
        )
        if repro:
            lines.extend(
                [
                    f"- Reproduction distance gap: `{format_optional(repro.get('distance_gap', math.nan), 12)}`.",
                    f"- Reproduction vote gap: `{format_optional(repro.get('vote_gap', math.nan), 12)}`.",
                    f"- Reproduction debt gap: `{format_optional(repro.get('debt_gap', math.nan), 12)}`.",
                ]
            )
        lines.extend(
            [
                "",
                "## Interpretation",
                "",
                "- This handoff packet stops after rebuilding and syncing the benchmark layer.",
                "- It does not auto-launch another benchmark or annual workflow branch.",
            ]
        )
    else:
        lines.extend(
            [
                "- The benchmark refresh did not finish cleanly inside this handoff packet.",
                "- Read the synced logs before rerunning the public benchmark layer.",
                "",
                "## Interpretation",
                "",
                "- This is a blocker report, not a successful refresh packet.",
            ]
        )

    SUMMARY_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def prepend_status_entry(text, args, summary, repro):
    date_tag = datetime.now().strftime("%Y-%m-%d")
    lines = [
        f"- Last updated: {date_tag} (away handoff collected Hamilton 5-year benchmark refresh)",
        f"- {date_tag} away handoff on Hamilton job `{args.job_id}`:",
        f"  - state: `{args.state}`",
        f"  - exit code: `{args.exit_code or 'n.a.'}`",
        f"  - elapsed: `{args.elapsed or 'n.a.'}`",
        f"  - node: `{args.node or 'n.a.'}`",
        "  - synced outputs:",
        "    - `notes/build/fertility_run_ge_report.md`",
        "    - `notes/build/fertility_reproduction_check.csv`",
        "    - `notes/build/fertility_price_sweep.csv`",
        "    - `notes/build/fertility_market_clearing_grid.csv`",
        "    - `notes/build/fertility_local_benchmark_search.csv`",
        "    - `notes/build/fertility_vs_nimby_benchmark_report.md`",
        "    - `notes/build/fertility_vs_nimby_benchmark_summary.csv`",
        "    - `notes/build/fertility_vs_nimby_common_price_grid.csv`",
        "    - `notes/build/fertility_benchmark_refresh_handoff.md`",
    ]
    if args.remote_run_dir:
        lines.append(f"  - remote run dir: `{args.remote_run_dir}`")
    if args.state == "COMPLETED" and args.exit_code == "0:0" and summary:
        nimby = summary.get("nimby", {})
        fertility = summary.get("fertility", {})
        lines.extend(
            [
                "  - main read:",
                f"    - nimby refined crossing price: `{format_optional(nimby.get('refined_price', math.nan))}`",
                f"    - fertility refined crossing price: `{format_optional(fertility.get('refined_price', math.nan))}`",
                f"    - fertility vote-per-mass at crossing: `{format_optional(fertility.get('vote_per_mass', math.nan))}`",
                f"    - fertility avg birth rate at crossing: `{format_optional(fertility.get('avg_birth_rate', math.nan))}`",
                f"    - fertility mean age at first birth at crossing: `{format_optional(fertility.get('mean_age_first_birth', math.nan))}`",
            ]
        )
        if repro:
            lines.append(f"    - reproduction vote gap: `{format_optional(repro.get('vote_gap', math.nan), 12)}`")
        lines.extend(
            [
                "  - stopping rule hit:",
                "    - collected and summarized one clean benchmark-refresh milestone",
                "    - did not auto-launch a second benchmark or annual branch while the user was away",
            ]
        )
    else:
        lines.extend(
            [
                "  - blocker:",
                "    - the benchmark refresh did not finish cleanly, so the handoff packet stopped after syncing the available logs and outputs",
            ]
        )

    entry = "\n".join(lines) + "\n"
    return text.replace("## Snapshot\n\n", "## Snapshot\n\n" + entry, 1)


def replace_next_tasks(text, args, summary):
    if args.state == "COMPLETED" and args.exit_code == "0:0" and summary:
        replacement = (
            "## Next 3 Tasks\n\n"
            "1. Monitor Hamilton job `16602541` and collect `nimby_annual_owner_grid_compromise_screen*` when the run finishes.\n"
            "2. Read the full `nimby_annual_owner_grid_compromise_screen.md` report to see whether intermediate `housingmax` values improve the vote/access tradeoff relative to both `10` and `15`.\n"
            "3. Use the refreshed 5-year benchmark layer when discussing the benchmark comparison; the stale benchmark-refresh caveat is now cleared.\n\n"
            "## Blockers"
        )
    else:
        replacement = (
            "## Next 3 Tasks\n\n"
            "1. Read `notes/build/fertility_benchmark_refresh_handoff.md` and the synced Hamilton logs to diagnose why the benchmark refresh did not finish cleanly.\n"
            "2. Decide whether to rerun the same 5-year benchmark refresh before leaning on the public benchmark note.\n"
            "3. Monitor Hamilton job `16602541` and keep the annual decision workflow focused on the owner-grid compromise screen.\n\n"
            "## Blockers"
        )
    return replace_once(text, r"## Next 3 Tasks\s+.*?\n## Blockers", replacement)


def prepend_memory_entry(text, args, summary, repro):
    date_tag = datetime.now().strftime("%Y-%m-%d")
    lines = [
        f"### Session: {date_tag} (away handoff collected Hamilton 5-year benchmark refresh)",
        f"- Hamilton job `{args.job_id}` final state: `{args.state}`",
        f"- Exit code: `{args.exit_code or 'n.a.'}`",
        f"- Elapsed: `{args.elapsed or 'n.a.'}`",
        f"- Node: `{args.node or 'n.a.'}`",
    ]
    if args.remote_run_dir:
        lines.append(f"- Remote run dir: `{args.remote_run_dir}`")
    lines.extend(
        [
            "- Synced outputs:",
            "  - `notes/build/fertility_run_ge_report.md`",
            "  - `notes/build/fertility_reproduction_check.csv`",
            "  - `notes/build/fertility_price_sweep.csv`",
            "  - `notes/build/fertility_market_clearing_grid.csv`",
            "  - `notes/build/fertility_local_benchmark_search.csv`",
            "  - `notes/build/fertility_vs_nimby_benchmark_report.md`",
            "  - `notes/build/fertility_vs_nimby_benchmark_summary.csv`",
            "  - `notes/build/fertility_vs_nimby_common_price_grid.csv`",
            "  - `notes/build/fertility_benchmark_refresh_handoff.md`",
        ]
    )
    if args.state == "COMPLETED" and args.exit_code == "0:0" and summary:
        nimby = summary.get("nimby", {})
        fertility = summary.get("fertility", {})
        lines.extend(
            [
                "- Main read from the completed benchmark-refresh handoff:",
                f"  - nimby refined crossing price: `{format_optional(nimby.get('refined_price', math.nan))}`",
                f"  - fertility refined crossing price: `{format_optional(fertility.get('refined_price', math.nan))}`",
                f"  - fertility vote-per-mass at crossing: `{format_optional(fertility.get('vote_per_mass', math.nan))}`",
                f"  - fertility avg birth rate at crossing: `{format_optional(fertility.get('avg_birth_rate', math.nan))}`",
                f"  - fertility mean age at first birth at crossing: `{format_optional(fertility.get('mean_age_first_birth', math.nan))}`",
            ]
        )
        if repro:
            lines.append(f"  - reproduction vote gap: `{format_optional(repro.get('vote_gap', math.nan), 12)}`")
        lines.extend(
            [
                "- Stopping rule hit:",
                "  - collected and summarized one clean benchmark-refresh milestone",
                "  - did not auto-launch a second benchmark or annual branch while the user was away",
            ]
        )
    else:
        lines.extend(
            [
                "- Blocker read:",
                "  - the benchmark refresh did not finish cleanly, so the away packet stopped after syncing the available logs and outputs",
            ]
        )

    entry = "\n".join(lines) + "\n\n---\n\n"
    return text.replace("Most recent session first.\n\n---\n\n", "Most recent session first.\n\n---\n\n" + entry, 1)


def sync_trackers(args, summary, repro):
    status_text = STATUS_MD.read_text(encoding="utf-8")
    status_text = prepend_status_entry(status_text, args, summary, repro)
    status_text = replace_next_tasks(status_text, args, summary)
    STATUS_MD.write_text(status_text, encoding="utf-8")

    memory_text = MEMORY_MD.read_text(encoding="utf-8")
    memory_text = prepend_memory_entry(memory_text, args, summary, repro)
    MEMORY_MD.write_text(memory_text, encoding="utf-8")


def main():
    args = parse_args()
    summary = load_summary()
    repro = load_repro()
    build_summary(args, summary, repro)
    if args.sync_trackers:
        sync_trackers(args, summary, repro)


if __name__ == "__main__":
    main()
