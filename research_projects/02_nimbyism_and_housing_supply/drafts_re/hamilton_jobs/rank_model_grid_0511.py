#!/usr/bin/env python3
"""Rank the 2026-05-11 NIMBY T80 model grid outputs.

Run from the Hamilton annual directory after the Slurm array has written
summary folders under truth/annual_political_full_re_price_path.
"""

import argparse
import csv
from pathlib import Path


def fnum(value: str) -> float:
    try:
        return float(value)
    except Exception:
        return float("nan")


def verdict_from_gap(gap: float) -> str:
    if gap != gap:
        return "missing"
    if gap <= 0.0002:
        return "paper_safe"
    if gap <= 0.001:
        return "usable"
    if gap <= 0.003:
        return "survivor"
    return "dead"


def read_grid(path):
    with path.open(newline="") as fh:
        return list(csv.DictReader(fh))


def best_re_row(annual_dir, run_tag):
    summary_path = annual_dir / "truth" / "annual_political_full_re_price_path" / run_tag / "summary_all.csv"
    if not summary_path.exists():
        return {
            "state": "missing",
            "best_gap": "",
            "best_outer": "",
            "vote_resid": "",
            "log_price_move": "",
            "last_outer": "",
            "last_gap": "",
        }
    with summary_path.open(newline="") as fh:
        rows = [r for r in csv.DictReader(fh) if r.get("max_abs_path_gap", "") not in ("", "NaN", "nan")]
    if not rows:
        return {
            "state": "no_rows",
            "best_gap": "",
            "best_outer": "",
            "vote_resid": "",
            "log_price_move": "",
            "last_outer": "",
            "last_gap": "",
        }
    best = min(rows, key=lambda r: fnum(r.get("max_abs_path_gap", "")))
    last = max(rows, key=lambda r: fnum(r.get("outer_iter", "")))
    return {
        "state": "complete_or_running",
        "best_gap": best.get("max_abs_path_gap", ""),
        "best_outer": best.get("outer_iter", ""),
        "vote_resid": best.get("max_abs_vote_resid", ""),
        "log_price_move": best.get("max_abs_log_price_move", ""),
        "last_outer": last.get("outer_iter", ""),
        "last_gap": last.get("max_abs_path_gap", ""),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--annual-dir", default=".", help="Hamilton annual directory")
    parser.add_argument("--grid", default="model_grid_0511.csv")
    parser.add_argument("--out-dir", default="truth/model_grid_0511")
    args = parser.parse_args()

    annual_dir = Path(args.annual_dir).resolve()
    grid_path = annual_dir / args.grid
    out_dir = annual_dir / args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    ranked = []
    for row in read_grid(grid_path):
        if row.get("family", "").lower() != "re":
            continue
        metrics = best_re_row(annual_dir, row["run_tag"])
        gap = fnum(metrics["best_gap"])
        ranked.append({**row, **metrics, "verdict": verdict_from_gap(gap)})

    ranked.sort(key=lambda r: fnum(r["best_gap"]) if r["best_gap"] else 1e99)

    out_csv = out_dir / "model_grid_ranked_0511.csv"
    fieldnames = [
        "row_id",
        "run_tag",
        "family",
        "terminal_anchor",
        "tail_years",
        "post_report_demographic_mode",
        "pass_through",
        "ttb_proxy_lag_years",
        "source_run_tag",
        "source_outer",
        "state",
        "verdict",
        "best_gap",
        "best_outer",
        "vote_resid",
        "log_price_move",
        "last_outer",
        "last_gap",
        "notes",
    ]
    with out_csv.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(ranked)

    out_md = out_dir / "model_grid_report_0511.md"
    with out_md.open("w", encoding="utf-8") as fh:
        fh.write("# T80 Model Grid 2026-05-11\n\n")
        if ranked:
            best = ranked[0]
            fh.write(
                f"Best row: `{best['run_tag']}` with gap `{best['best_gap']}` "
                f"and verdict `{best['verdict']}`.\n\n"
            )
        fh.write("| verdict | run_tag | gap | outer | vote_resid | move | notes |\n")
        fh.write("|---|---:|---:|---:|---:|---:|---|\n")
        for r in ranked:
            fh.write(
                f"| {r['verdict']} | `{r['run_tag']}` | {r['best_gap']} | "
                f"{r['best_outer']} | {r['vote_resid']} | {r['log_price_move']} | {r['notes']} |\n"
            )

    print(f"Wrote {out_csv}")
    print(f"Wrote {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
