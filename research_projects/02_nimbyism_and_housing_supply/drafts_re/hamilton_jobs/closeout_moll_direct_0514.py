#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path
from typing import Any, Dict, List, Optional


def read_csv(path):
    if not path.is_file():
        return []
    with path.open(newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def write_csv(path, rows, fieldnames):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k, "") for k in fieldnames})


def f(row, key, default=None):
    value = row.get(key, "")
    if value == "" or value is None:
        if default is None:
            raise KeyError(key)
        return default
    return float(value)


def i(row, key, default=None):
    value = row.get(key, "")
    if value == "" or value is None:
        if default is None:
            raise KeyError(key)
        return default
    return int(float(value))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--annual-dir", default=".")
    parser.add_argument("--grid", default="model_moll_direct_0514.csv")
    args = parser.parse_args()

    annual = Path(args.annual_dir)
    grid = read_csv(annual / args.grid)
    out_root = annual / "truth" / "moll_direct_price_beliefs"
    ranked = []  # type: List[Dict[str, Any]]

    for row in grid:
        run_tag = row["run_tag"]
        route = row["route"]
        run_dir = out_root / run_tag
        iters = read_csv(run_dir / "belief_iterations.csv")
        if not iters:
            ranked.append(
                {
                    "row_id": row["row_id"],
                    "run_tag": run_tag,
                    "route": route,
                    "status": "missing_or_running",
                    "iterations_completed": 0,
                    "final_rmse_log_forecast_error": "",
                    "final_max_abs_log_forecast_error": "",
                    "final_max_abs_log_belief_update": "",
                    "best_rmse_log_forecast_error": "",
                    "best_iter": "",
                    "decision_read": "pending",
                }
            )
            continue
        iters.sort(key=lambda r: i(r, "learning_iter"))
        final = iters[-1]
        best = min(iters, key=lambda r: f(r, "rmse_log_forecast_error", float("inf")))
        decision = "baseline_only" if route == "temporary_fixed_path" else "candidate_route"
        if route == "price_only_ar1":
            decision = "cross_check_not_main"
        if route == "restricted_heuristic":
            decision = "robustness_candidate"
        if route == "learning_age_price":
            decision = "main_moll_candidate"
        ranked.append(
            {
                "row_id": row["row_id"],
                "run_tag": run_tag,
                "route": route,
                "status": "complete",
                "iterations_completed": len(iters),
                "final_rmse_log_forecast_error": final.get("rmse_log_forecast_error", ""),
                "final_max_abs_log_forecast_error": final.get("max_abs_log_forecast_error", ""),
                "final_max_abs_log_belief_update": final.get("max_abs_log_belief_update", ""),
                "best_rmse_log_forecast_error": best.get("rmse_log_forecast_error", ""),
                "best_iter": best.get("learning_iter", ""),
                "decision_read": decision,
            }
        )

    ranked.sort(
        key=lambda r: (
            1 if r["status"] != "complete" else 0,
            float(r["best_rmse_log_forecast_error"] or "inf"),
        )
    )

    fieldnames = [
        "row_id",
        "run_tag",
        "route",
        "status",
        "iterations_completed",
        "final_rmse_log_forecast_error",
        "final_max_abs_log_forecast_error",
        "final_max_abs_log_belief_update",
        "best_rmse_log_forecast_error",
        "best_iter",
        "decision_read",
    ]
    write_csv(out_root / "moll_direct_ranked_0514.csv", ranked, fieldnames)

    report = ["# Moll direct-price-beliefs closeout", ""]
    report.append("| Run | Route | Status | Best RMSE | Final update | Read |")
    report.append("|---|---|---|---:|---:|---|")
    for row in ranked:
        report.append(
            "| {run} | {route} | {status} | {rmse} | {update} | {read} |".format(
                run=row["run_tag"],
                route=row["route"],
                status=row["status"],
                rmse=row["best_rmse_log_forecast_error"],
                update=row["final_max_abs_log_belief_update"],
                read=row["decision_read"],
            )
        )
    (out_root / "moll_direct_closeout_0514.md").write_text("\n".join(report) + "\n", encoding="utf-8")

    complete = sum(1 for row in ranked if row["status"] == "complete")
    print(f"Moll direct closeout: {complete}/{len(ranked)} rows complete")
    for row in ranked:
        print(
            f"{row['run_tag']}: {row['status']}, best_rmse={row['best_rmse_log_forecast_error']}, "
            f"final_update={row['final_max_abs_log_belief_update']}, read={row['decision_read']}"
        )
    return 0 if complete == len(ranked) else 3


if __name__ == "__main__":
    raise SystemExit(main())
