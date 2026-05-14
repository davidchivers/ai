#!/usr/bin/env python3
"""Rank stationary old-model RE benchmark rows."""

import argparse
import csv
import math
from pathlib import Path


def fnum(x):
    try:
        return float(x)
    except Exception:
        return float("nan")


def read_rows(path):
    if not path.exists():
        return []
    with path.open(newline="") as fh:
        return list(csv.DictReader(fh))


def verdict(gap):
    if not math.isfinite(gap):
        return "missing"
    if gap <= 1e-5:
        return "solved"
    if gap <= 1e-4:
        return "usable"
    return "loose"


def diag_for(annual_dir, tag):
    path = annual_dir / "truth" / "annual_political_full_re_price_path" / tag / "terminal_anchor.csv"
    rows = read_rows(path)
    if not rows:
        return {}
    return rows[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--annual-dir", default=".")
    ap.add_argument("--grid", default="model_stationary_re_0512.csv")
    ap.add_argument("--out-dir", default="truth/stationary_re_0512")
    args = ap.parse_args()

    annual_dir = Path(args.annual_dir).resolve()
    out_dir = annual_dir / args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    grid = read_rows(annual_dir / args.grid)

    rows = []
    baseline_by_pt = {}
    for row in grid:
        d = diag_for(annual_dir, row["run_tag"])
        out = dict(row)
        if d:
            ref = fnum(d.get("reference_price", ""))
            price = fnum(d.get("terminal_price", ""))
            gap = fnum(d.get("terminal_abs_log_gap", ""))
            out.update({
                "state": "complete_or_running",
                "verdict": verdict(gap),
                "reference_price": d.get("reference_price", ""),
                "terminal_price": d.get("terminal_price", ""),
                "terminal_generated_price": d.get("terminal_generated_price", ""),
                "terminal_abs_log_gap": d.get("terminal_abs_log_gap", ""),
                "terminal_vote_resid": d.get("terminal_vote_resid", ""),
                "terminal_pressure": d.get("terminal_pressure", ""),
                "terminal_restriction": d.get("terminal_restriction", ""),
                "terminal_homeownership": d.get("terminal_homeownership", ""),
                "terminal_housing_demand": d.get("terminal_housing_demand", ""),
                "log_price_vs_reference": f"{math.log(price / ref):.12g}" if price > 0 and ref > 0 else "",
                "pct_price_vs_reference": f"{100*(math.exp(math.log(price / ref))-1):.12g}" if price > 0 and ref > 0 else "",
            })
            if row["age_case"] == "baseline":
                baseline_by_pt[row["pass_through"]] = price
        else:
            out.update({"state": "missing", "verdict": "missing"})
        rows.append(out)

    for out in rows:
        price = fnum(out.get("terminal_price", ""))
        b = baseline_by_pt.get(out.get("pass_through", ""))
        if b and math.isfinite(price) and price > 0 and b > 0:
            out["pct_price_vs_baseline_case"] = f"{100*(price/b-1):.12g}"
            out["log_price_vs_baseline_case"] = f"{math.log(price/b):.12g}"
        else:
            out["pct_price_vs_baseline_case"] = ""
            out["log_price_vs_baseline_case"] = ""

    rows.sort(key=lambda r: (fnum(r.get("pass_through", "")), int(r.get("row_id", "999"))))
    fields = [
        "row_id", "run_tag", "age_case", "pass_through", "growth_rate", "projection_year",
        "state", "verdict", "terminal_abs_log_gap", "reference_price", "terminal_price",
        "pct_price_vs_reference", "pct_price_vs_baseline_case", "terminal_vote_resid",
        "terminal_pressure", "terminal_restriction", "terminal_homeownership",
        "terminal_housing_demand", "notes",
    ]
    out_csv = out_dir / "stationary_re_ranked_0512.csv"
    with out_csv.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)

    out_md = out_dir / "stationary_re_report_0512.md"
    with out_md.open("w", encoding="utf-8") as fh:
        fh.write("# Stationary RE Benchmarks 2026-05-12\n\n")
        fh.write("These are stationary old-model benchmarks, not full transition-path RE solves.\n\n")
        fh.write("| pass-through | scenario | price vs baseline case | price vs reference | gap | homeownership | notes |\n")
        fh.write("|---:|---|---:|---:|---:|---:|---|\n")
        for r in rows:
            fh.write("| {} | `{}` | {} | {} | {} | {} | {} |\n".format(
                r.get("pass_through", ""), r.get("run_tag", ""),
                r.get("pct_price_vs_baseline_case", ""), r.get("pct_price_vs_reference", ""),
                r.get("terminal_abs_log_gap", ""), r.get("terminal_homeownership", ""),
                r.get("notes", "")
            ))
    print(f"Wrote {out_csv}")
    print(f"Wrote {out_md}")


if __name__ == "__main__":
    main()
