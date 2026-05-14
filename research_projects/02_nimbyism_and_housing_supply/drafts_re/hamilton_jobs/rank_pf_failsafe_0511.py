#!/usr/bin/env python3
"""Rank the 2026-05-11 perfect-foresight failsafe probes."""

import argparse
import csv
from pathlib import Path


def fnum(value):
    try:
        return float(value)
    except Exception:
        return float("nan")


def verdict_from_gap(gap):
    if gap != gap:
        return "missing"
    if gap <= 0.0002:
        return "paper_safe"
    if gap <= 0.001:
        return "usable"
    if gap <= 0.003:
        return "survivor"
    return "dead"


def best_row(annual_dir, run_tag):
    summary_path = annual_dir / "truth" / "annual_political_full_re_price_path" / run_tag / "summary_all.csv"
    if not summary_path.exists():
        return {"state": "missing", "best_gap": "", "best_outer": "", "vote_resid": "", "log_price_move": "", "last_outer": "", "last_gap": ""}
    with summary_path.open(newline="") as fh:
        rows = [r for r in csv.DictReader(fh) if r.get("max_abs_path_gap", "") not in ("", "NaN", "nan")]
    if not rows:
        return {"state": "no_rows", "best_gap": "", "best_outer": "", "vote_resid": "", "log_price_move": "", "last_outer": "", "last_gap": ""}
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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--annual-dir", default=".")
    parser.add_argument("--grid", default="model_pf_failsafe_0511.csv")
    parser.add_argument("--out-dir", default="truth/pf_failsafe_0511")
    args = parser.parse_args()

    annual_dir = Path(args.annual_dir).resolve()
    out_dir = annual_dir / args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    with (annual_dir / args.grid).open(newline="") as fh:
        grid = list(csv.DictReader(fh))

    ranked = []
    for row in grid:
        metrics = best_row(annual_dir, row["run_tag"])
        gap = fnum(metrics["best_gap"])
        ranked.append(dict(row, **metrics, verdict=verdict_from_gap(gap)))
    ranked.sort(key=lambda r: fnum(r["best_gap"]) if r["best_gap"] else 1e99)

    fields = ["row_id", "run_tag", "probe_type", "horizon_t", "tail_years", "shock_amplitude", "state", "verdict", "best_gap", "best_outer", "vote_resid", "log_price_move", "last_outer", "last_gap", "notes"]
    out_csv = out_dir / "pf_failsafe_ranked_0511.csv"
    with out_csv.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(ranked)

    out_md = out_dir / "pf_failsafe_report_0511.md"
    with out_md.open("w", encoding="utf-8") as fh:
        fh.write("# Perfect-Foresight Failsafe 2026-05-11\n\n")
        if ranked:
            best = ranked[0]
            fh.write("Best row: `{}` gap `{}` verdict `{}`.\n\n".format(best["run_tag"], best["best_gap"], best["verdict"]))
        fh.write("| verdict | run_tag | probe | T | amp | gap | outer | notes |\n")
        fh.write("|---|---|---|---:|---:|---:|---:|---|\n")
        for row in ranked:
            fh.write("| {} | `{}` | {} | {} | {} | {} | {} | {} |\n".format(row["verdict"], row["run_tag"], row["probe_type"], row["horizon_t"], row["shock_amplitude"], row["best_gap"], row["best_outer"], row["notes"]))

    print("Wrote {}".format(out_csv))
    print("Wrote {}".format(out_md))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
