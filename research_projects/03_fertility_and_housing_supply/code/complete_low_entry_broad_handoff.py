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
SUMMARY_MD = BUILD_DIR / "nimby_annual_low_entry_broad_screen_handoff.md"
CANDIDATES_CSV = BUILD_DIR / "nimby_annual_low_entry_broad_screen_candidates.csv"


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


def load_candidates():
    if not CANDIDATES_CSV.exists():
        return []

    with CANDIDATES_CSV.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))

    out = []
    for row in rows:
        out.append(
            {
                "candidate_id": int(row["candidate_id"]),
                "label": row["label"],
                "eval_vote_per_mass": to_float(row.get("eval_vote_per_mass")),
                "eval_debt_per_mass": to_float(row.get("eval_debt_per_mass")),
                "score": to_float(row.get("score")),
                "crossing_exists": int(float(row.get("crossing_exists") or 0)),
                "crossing_is_unique": int(float(row.get("crossing_is_unique") or 0)),
                "crossing_refined_price": to_float(row.get("crossing_refined_price")),
                "early_vote_rmse": to_float(row.get("early_vote_rmse")),
                "early_owner_share_rmse": to_float(row.get("early_owner_share_rmse")),
                "early_liquid_asset_rmse": to_float(row.get("early_liquid_asset_rmse")),
            }
        )
    return out


def format_optional(value, digits=6):
    if math.isnan(value):
        return "n.a."
    return f"{value:.{digits}f}"


def build_summary(args, candidates):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines = [
        "# Hamilton low-entry broad-screen handoff",
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

    if args.state == "COMPLETED" and args.exit_code == "0:0" and candidates:
        best = candidates[0]
        row_count = len(candidates)
        crossing_count = sum(
            1
            for row in candidates
            if row["crossing_exists"] == 1 and row["crossing_is_unique"] == 1 and not math.isnan(row["crossing_refined_price"])
        )
        lines.extend(
            [
                f"- Completed full broad-screen run with `{row_count}` scored candidates.",
                f"- Best candidate: `{best['label']}`.",
                f"- Eval vote-per-mass: `{format_optional(best['eval_vote_per_mass'])}`.",
                f"- Eval debt-per-mass: `{format_optional(best['eval_debt_per_mass'])}`.",
                f"- Score: `{format_optional(best['score'])}`.",
            ]
        )
        if crossing_count > 0:
            lines.append(f"- Unique crossing candidates found: `{crossing_count}`.")
            lines.append(
                f"- Best-candidate crossing price: `{format_optional(best['crossing_refined_price'])}`."
            )
        else:
            lines.append("- No unique crossing appears in the scored candidate set.")
        lines.extend(
            [
                "",
                "## Interpretation",
                "",
                "- This handoff packet stops after collecting and summarizing the broad-screen result.",
                "- It does not auto-launch a second design branch while you are away.",
            ]
        )
    else:
        lines.extend(
            [
                "- The broad-screen run did not finish cleanly inside this handoff packet.",
                "- Read the synced logs before resubmitting or broadening scope.",
                "",
                "## Interpretation",
                "",
                "- This is a blocker report, not a successful result packet.",
            ]
        )

    SUMMARY_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def prepend_status_entry(text, args, candidates):
    date_tag = datetime.now().strftime("%Y-%m-%d")
    lines = [
        f"- Last updated: {date_tag} (away handoff collected Hamilton broad-screen result)",
        f"- {date_tag} away handoff on Hamilton job `{args.job_id}`:",
        f"  - state: `{args.state}`",
        f"  - exit code: `{args.exit_code or 'n.a.'}`",
        f"  - elapsed: `{args.elapsed or 'n.a.'}`",
        f"  - node: `{args.node or 'n.a.'}`",
        "  - synced outputs:",
        "    - `notes/build/nimby_annual_low_entry_broad_screen.md`",
        "    - `notes/build/nimby_annual_low_entry_broad_screen_candidates.csv`",
        "    - `notes/build/nimby_annual_low_entry_broad_screen_candidate_paths.csv`",
        "    - `notes/build/nimby_annual_low_entry_broad_screen_candidate_blocks.csv`",
        "    - `notes/build/nimby_annual_low_entry_broad_screen_target_blocks.csv`",
        "    - `notes/build/nimby_annual_low_entry_broad_screen_handoff.md`",
    ]
    if args.remote_run_dir:
        lines.append(f"  - remote run dir: `{args.remote_run_dir}`")
    if args.state == "COMPLETED" and args.exit_code == "0:0" and candidates:
        best = candidates[0]
        lines.extend(
            [
                "  - main read:",
                f"    - scored candidates collected: `{len(candidates)}`",
                f"    - best candidate: `{best['label']}`",
                f"    - eval vote-per-mass: `{format_optional(best['eval_vote_per_mass'])}`",
                f"    - eval debt-per-mass: `{format_optional(best['eval_debt_per_mass'])}`",
            ]
        )
        if best["crossing_exists"] == 1 and best["crossing_is_unique"] == 1 and not math.isnan(best["crossing_refined_price"]):
            lines.append(f"    - best-candidate crossing price: `{format_optional(best['crossing_refined_price'])}`")
        else:
            lines.append("    - no unique crossing in the scored candidate set")
        lines.extend(
            [
                "  - stopping rule hit:",
                "    - collected and summarized one clean broad-screen milestone",
                "    - did not auto-launch a second annual design branch while the user was away",
            ]
        )
    else:
        lines.extend(
            [
                "  - blocker:",
                "    - the broad-screen run did not finish cleanly, so the handoff packet stopped after syncing the available logs and outputs",
            ]
        )

    entry = "\n".join(lines) + "\n"
    return text.replace("## Snapshot\n\n", "## Snapshot\n\n" + entry, 1)


def replace_next_tasks(text, args, candidates):
    if args.state == "COMPLETED" and args.exit_code == "0:0" and candidates:
        best = candidates[0]
        if best["crossing_exists"] == 1 and best["crossing_is_unique"] == 1 and not math.isnan(best["crossing_refined_price"]):
            replacement = (
                "## Next 3 Tasks\n\n"
                f"1. Read `notes/build/nimby_annual_low_entry_broad_screen_handoff.md` and confirm whether promoted candidate `{best['label']}` is strong enough to treat as the new annual leader.\n"
                "2. If that promoted candidate is acceptable, rerun the age-block comparison around it before broadening to any new design branch.\n"
                "3. Keep annual fertility and RE / transition work off the table until the promoted annual steady-state candidate is stabilized.\n\n"
                "## Blockers"
            )
        else:
            replacement = (
                "## Next 3 Tasks\n\n"
                "1. Read `notes/build/nimby_annual_low_entry_broad_screen_handoff.md` and the full `nimby_annual_low_entry_broad_screen.md` as the canonical closeout for this broad screen.\n"
                "2. Decide the next annual design branch after reviewing the full broad-screen result; do not auto-extend to a second branch from this away packet.\n"
                "3. Keep annual fertility and RE / transition work off the table until the next steady-state branch is chosen from the collected broad-screen evidence.\n\n"
                "## Blockers"
            )
    else:
        replacement = (
            "## Next 3 Tasks\n\n"
            "1. Read `notes/build/nimby_annual_low_entry_broad_screen_handoff.md` and the synced Hamilton logs to diagnose why the broad screen did not finish cleanly.\n"
            "2. Decide whether to rerun the same broad screen or narrow the failure before launching another annual job.\n"
            "3. Keep annual fertility and RE / transition work off the table until the annual steady-state screen completes cleanly.\n\n"
            "## Blockers"
        )
    return replace_once(text, r"## Next 3 Tasks\s+.*?\n## Blockers", replacement)


def prepend_memory_entry(text, args, candidates):
    date_tag = datetime.now().strftime("%Y-%m-%d")
    lines = [
        f"### Session: {date_tag} (away handoff collected Hamilton broad-screen result)",
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
            "  - `notes/build/nimby_annual_low_entry_broad_screen.md`",
            "  - `notes/build/nimby_annual_low_entry_broad_screen_candidates.csv`",
            "  - `notes/build/nimby_annual_low_entry_broad_screen_candidate_paths.csv`",
            "  - `notes/build/nimby_annual_low_entry_broad_screen_candidate_blocks.csv`",
            "  - `notes/build/nimby_annual_low_entry_broad_screen_target_blocks.csv`",
            "  - `notes/build/nimby_annual_low_entry_broad_screen_handoff.md`",
        ]
    )
    if args.state == "COMPLETED" and args.exit_code == "0:0" and candidates:
        best = candidates[0]
        lines.extend(
            [
                "- Main read from the completed broad-screen handoff:",
                f"  - scored candidates collected: `{len(candidates)}`",
                f"  - best candidate: `{best['label']}`",
                f"  - eval vote-per-mass: `{format_optional(best['eval_vote_per_mass'])}`",
                f"  - eval debt-per-mass: `{format_optional(best['eval_debt_per_mass'])}`",
            ]
        )
        if best["crossing_exists"] == 1 and best["crossing_is_unique"] == 1 and not math.isnan(best["crossing_refined_price"]):
            lines.append(f"  - best-candidate crossing price: `{format_optional(best['crossing_refined_price'])}`")
        else:
            lines.append("  - no unique crossing in the scored candidate set")
        lines.extend(
            [
                "- Stopping rule hit:",
                "  - collected and summarized one clean broad-screen milestone",
                "  - did not auto-launch a second annual design branch while the user was away",
            ]
        )
    else:
        lines.extend(
            [
                "- Blocker read:",
                "  - the broad-screen run did not finish cleanly, so the away packet stopped after syncing the available logs and outputs",
            ]
        )

    entry = "\n".join(lines) + "\n\n---\n\n"
    return text.replace("Most recent session first.\n\n---\n\n", "Most recent session first.\n\n---\n\n" + entry, 1)


def sync_trackers(args, candidates):
    status_text = STATUS_MD.read_text(encoding="utf-8")
    status_text = prepend_status_entry(status_text, args, candidates)
    status_text = replace_next_tasks(status_text, args, candidates)
    STATUS_MD.write_text(status_text, encoding="utf-8")

    memory_text = MEMORY_MD.read_text(encoding="utf-8")
    memory_text = prepend_memory_entry(memory_text, args, candidates)
    MEMORY_MD.write_text(memory_text, encoding="utf-8")


def main():
    args = parse_args()
    candidates = load_candidates()
    build_summary(args, candidates)
    if args.sync_trackers:
        sync_trackers(args, candidates)


if __name__ == "__main__":
    main()
