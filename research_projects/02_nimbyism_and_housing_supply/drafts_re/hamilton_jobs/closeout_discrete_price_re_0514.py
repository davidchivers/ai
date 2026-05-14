#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path


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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--annual-dir", default=".")
    parser.add_argument("--grid", default="model_discrete_price_re_0514.csv")
    args = parser.parse_args()

    annual = Path(args.annual_dir)
    grid = read_csv(annual / args.grid)
    out_root = annual / "truth" / "discrete_price_re"
    rows = []

    for cfg in grid:
        run_tag = cfg["run_tag"]
        run_dir = out_root / run_tag
        iters = read_csv(run_dir / "discrete_iterations.csv")
        status_rows = read_csv(run_dir / "status.csv")
        if not iters:
            rows.append({
                "row_id": cfg["row_id"],
                "run_tag": run_tag,
                "grid_points": cfg["grid_points"],
                "horizon_t": cfg["horizon_t"],
                "seed_mode": cfg["seed_mode"],
                "status": "missing_or_running",
                "iterations_completed": 0,
                "final_changed_report_count": "",
                "best_changed_report_count": "",
                "best_max_abs_log_quantized_gap": "",
                "best_iter": "",
                "read": "pending",
            })
            continue
        final = iters[-1]
        best = min(
            iters,
            key=lambda r: (
                f(r, "changed_report_count", float("inf")),
                f(r, "max_abs_log_quantized_gap", float("inf")),
            ),
        )
        status = status_rows[-1]["status"] if status_rows else "complete_no_status"
        if status.startswith("fixed_sequence"):
            read = "discrete_fixed_point"
        elif status.startswith("cycle"):
            read = "cycle_detected"
        else:
            read = "best_partial_sequence"
        rows.append({
            "row_id": cfg["row_id"],
            "run_tag": run_tag,
            "grid_points": cfg["grid_points"],
            "horizon_t": cfg["horizon_t"],
            "seed_mode": cfg["seed_mode"],
            "status": status,
            "iterations_completed": len(iters),
            "final_changed_report_count": final.get("changed_report_count", ""),
            "best_changed_report_count": best.get("changed_report_count", ""),
            "best_max_abs_log_quantized_gap": best.get("max_abs_log_quantized_gap", ""),
            "best_iter": best.get("discrete_iter", ""),
            "read": read,
        })

    rows.sort(key=lambda r: (
        1 if r["status"] == "missing_or_running" else 0,
        float(r["best_changed_report_count"] or "inf"),
        float(r["best_max_abs_log_quantized_gap"] or "inf"),
    ))
    fieldnames = [
        "row_id", "run_tag", "grid_points", "horizon_t", "seed_mode", "status",
        "iterations_completed", "final_changed_report_count",
        "best_changed_report_count", "best_max_abs_log_quantized_gap",
        "best_iter", "read",
    ]
    write_csv(out_root / "discrete_price_ranked_0514.csv", rows, fieldnames)

    report = ["# Discrete-price RE closeout", ""]
    report.append("| Run | Grid | T | Seed | Status | Best changed periods | Best quantized gap | Read |")
    report.append("|---|---:|---:|---|---|---:|---:|---|")
    for row in rows:
        report.append(
            "| {run} | {grid} | {t} | {seed} | {status} | {changed} | {gap} | {read} |".format(
                run=row["run_tag"],
                grid=row["grid_points"],
                t=row["horizon_t"],
                seed=row["seed_mode"],
                status=row["status"],
                changed=row["best_changed_report_count"],
                gap=row["best_max_abs_log_quantized_gap"],
                read=row["read"],
            )
        )
    (out_root / "discrete_price_closeout_0514.md").write_text("\n".join(report) + "\n", encoding="utf-8")

    complete = sum(1 for row in rows if row["status"] != "missing_or_running")
    print("Discrete price closeout: {}/{} rows have outputs".format(complete, len(rows)))
    for row in rows:
        print(
            "{run}: {status}, best_changed={changed}, best_gap={gap}, read={read}".format(
                run=row["run_tag"],
                status=row["status"],
                changed=row["best_changed_report_count"],
                gap=row["best_max_abs_log_quantized_gap"],
                read=row["read"],
            )
        )
    return 0 if complete == len(rows) else 3


if __name__ == "__main__":
    raise SystemExit(main())
