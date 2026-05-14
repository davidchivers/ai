#!/usr/bin/env python3
"""Rank the 2026-05-12 RE alternatives packet."""

import argparse
import csv
import math
from pathlib import Path


def fnum(value):
    try:
        return float(value)
    except Exception:
        return float("nan")


def verdict_from_gap(gap, route):
    if route in {"partial_equilibrium_pf"}:
        if math.isfinite(gap):
            return "diagnostic"
        return "missing"
    if route in {"local_linear_proxy"}:
        if not math.isfinite(gap):
            return "missing"
        if gap <= 0.001:
            return "diagnostic_usable"
        if gap <= 0.003:
            return "diagnostic_survivor"
        return "diagnostic_dead"
    if not math.isfinite(gap):
        return "missing"
    if gap <= 0.0002:
        return "paper_safe"
    if gap <= 0.001:
        return "usable"
    if gap <= 0.003:
        return "survivor"
    return "dead"


def read_rows(path):
    if not path.exists():
        return []
    with path.open(newline="") as fh:
        return list(csv.DictReader(fh))


def path_stats(path, outer=None):
    rows = read_rows(path)
    if not rows:
        return {}
    if outer is not None and "outer_iter" in rows[0]:
        rows = [r for r in rows if str(r.get("outer_iter", "")) == str(outer)]
    rows = sorted(rows, key=lambda r: fnum(r.get("period", "")))
    if not rows:
        return {}
    if "price_guess" in rows[0]:
        price_col = "price_guess"
    elif "price" in rows[0]:
        price_col = "price"
    else:
        return {}
    prices = [fnum(r.get(price_col, "")) for r in rows if math.isfinite(fnum(r.get(price_col, "")))]
    if not prices:
        return {}
    ref = prices[0]
    logs = [math.log(p / ref) for p in prices if p > 0 and ref > 0]
    if not logs:
        return {}
    generated = []
    if "price_generated" in rows[0]:
        generated = [fnum(r.get("price_generated", "")) for r in rows if math.isfinite(fnum(r.get("price_generated", "")))]
    stats = {
        "peak_log_price": max(logs),
        "trough_log_price": min(logs),
        "final_log_price": logs[-1],
        "peak_pct": 100.0 * (math.exp(max(logs)) - 1.0),
        "trough_pct": 100.0 * (math.exp(min(logs)) - 1.0),
    }
    if generated and len(generated) == len(prices):
        gaps = [abs(math.log(g / p)) for g, p in zip(generated, prices) if g > 0 and p > 0]
        if gaps:
            stats["max_generated_fixed_gap"] = max(gaps)
    return stats


def best_re(annual_dir, row):
    run_tag = row["run_tag"]
    root = annual_dir / "truth" / "annual_political_full_re_price_path" / run_tag
    summary_path = root / "summary_all.csv"
    rows = [r for r in read_rows(summary_path) if math.isfinite(fnum(r.get("max_abs_path_gap", "")))]
    if not rows:
        return {"state": "missing", "best_gap": "", "best_outer": "", "vote_resid": "", "log_price_move": "", "last_outer": "", "last_gap": ""}
    best = min(rows, key=lambda r: fnum(r.get("max_abs_path_gap", "")))
    last = max(rows, key=lambda r: fnum(r.get("outer_iter", "")))
    stats = path_stats(root / "paths_all.csv", best.get("outer_iter", ""))
    out = {
        "state": "complete_or_running",
        "best_gap": best.get("max_abs_path_gap", ""),
        "best_outer": best.get("outer_iter", ""),
        "vote_resid": best.get("max_abs_vote_resid", ""),
        "log_price_move": best.get("max_abs_log_price_move", ""),
        "last_outer": last.get("outer_iter", ""),
        "last_gap": last.get("max_abs_path_gap", ""),
    }
    out.update({k: f"{v:.12g}" for k, v in stats.items()})
    return out


def best_nore(annual_dir, row):
    run_tag = row["run_tag"]
    T = row.get("horizon_t", "80")
    root = annual_dir / "truth" / "annual_political_transition_fail_safe" / run_tag
    summary = read_rows(root / "summary_all.csv")
    state = "complete_or_running" if summary else "missing"
    stats = path_stats(root / f"paths_T{T}.csv")
    out = {
        "state": state,
        "best_gap": "",
        "best_outer": "",
        "vote_resid": "",
        "log_price_move": "",
        "last_outer": "",
        "last_gap": "",
    }
    if summary:
        last = summary[-1]
        out["vote_resid"] = last.get("max_abs_vote_resid", last.get("max_vote_resid", ""))
        out["log_price_move"] = last.get("max_abs_log_price_move", "")
    out.update({k: f"{v:.12g}" for k, v in stats.items()})
    return out


def sort_key(row):
    gap = fnum(row.get("best_gap", ""))
    if math.isfinite(gap):
        return (0, gap)
    if row.get("state") != "missing" and row.get("family") == "nore":
        return (2, row.get("run_tag", ""))
    if row.get("state") != "missing" and row.get("route") == "partial_equilibrium_pf":
        return (3, row.get("run_tag", ""))
    if row.get("state") != "missing":
        return (4, row.get("run_tag", ""))
    return (9, row.get("run_tag", ""))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--annual-dir", default=".")
    parser.add_argument("--grid", default="model_re_alt_0512.csv")
    parser.add_argument("--out-dir", default="truth/re_alt_0512")
    args = parser.parse_args()

    annual_dir = Path(args.annual_dir).resolve()
    out_dir = annual_dir / args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    grid = read_rows(annual_dir / args.grid)

    ranked = []
    for row in grid:
        if row.get("family", "").lower() == "nore":
            metrics = best_nore(annual_dir, row)
            verdict = "diagnostic_nore" if metrics["state"] != "missing" else "missing"
        else:
            metrics = best_re(annual_dir, row)
            verdict = verdict_from_gap(fnum(metrics.get("best_gap", "")), row.get("route", ""))
        ranked.append(dict(row, **metrics, verdict=verdict))
    ranked.sort(key=sort_key)

    fields = [
        "row_id", "run_tag", "family", "route", "demographic_scenario", "horizon_t",
        "tail_years", "shock_amplitude", "state", "verdict", "best_gap",
        "best_outer", "vote_resid", "log_price_move", "last_outer", "last_gap",
        "peak_pct", "trough_pct", "final_log_price", "max_generated_fixed_gap", "notes",
    ]
    out_csv = out_dir / "re_alt_ranked_0512.csv"
    with out_csv.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(ranked)

    out_md = out_dir / "re_alt_report_0512.md"
    with out_md.open("w", encoding="utf-8") as fh:
        fh.write("# RE Alternatives 2026-05-12\n\n")
        converged = [r for r in ranked if r["verdict"] in {"paper_safe", "usable", "diagnostic_usable"}]
        if converged:
            best = converged[0]
            fh.write(f"Best clearing/usable row: `{best['run_tag']}` gap `{best.get('best_gap','')}` verdict `{best['verdict']}`.\n\n")
        elif ranked:
            best = ranked[0]
            fh.write(f"Best visible row: `{best['run_tag']}` gap `{best.get('best_gap','')}` verdict `{best['verdict']}`.\n\n")
        fh.write("| verdict | run_tag | route | scenario | T | amp | gap | outer | peak pct | notes |\n")
        fh.write("|---|---|---|---|---:|---:|---:|---:|---:|---|\n")
        for row in ranked:
            fh.write("| {} | `{}` | {} | {} | {} | {} | {} | {} | {} | {} |\n".format(
                row.get("verdict", ""), row.get("run_tag", ""), row.get("route", ""),
                row.get("demographic_scenario", ""), row.get("horizon_t", ""),
                row.get("shock_amplitude", ""), row.get("best_gap", ""),
                row.get("best_outer", ""), row.get("peak_pct", ""), row.get("notes", "")
            ))

    print(f"Wrote {out_csv}")
    print(f"Wrote {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
