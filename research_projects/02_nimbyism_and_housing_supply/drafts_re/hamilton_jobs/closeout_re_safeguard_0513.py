#!/usr/bin/env python3
"""Close out the safeguarded full-T80 RE packet."""

import argparse
import csv
import math
import subprocess
import sys
from pathlib import Path


USABLE_GAP = 0.001
PAPER_SAFE_GAP = 0.0002
NON_HEADLINE_ROUTES = {
    "partial_equilibrium_pf",
    "local_linear_proxy",
    "bounded_horizon_expectations",
    "homotopy_diagnostic",
    "lag_sweep",
    "seed_diagnostic",
    "blind_restart",
}


def fnum(value):
    try:
        return float(value)
    except Exception:
        return float("nan")


def read_rows(path):
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def is_headline_full_re(row):
    route = row.get("route", "")
    if row.get("family") != "re":
        return False
    if row.get("horizon_t") != "80":
        return False
    if route in NON_HEADLINE_ROUTES:
        return False
    if "bound" in route.lower() or "diagnostic" in route.lower():
        return False
    return True


def write_failure_memo(path, rows, final, packet_label, method_summary, include_next_solver):
    path.parent.mkdir(parents=True, exist_ok=True)
    ranked = [r for r in rows if math.isfinite(fnum(r.get("best_gap")))]
    best = ranked[0] if ranked else {}
    missing = [r for r in rows if r.get("state") == "missing"]
    lines = [
        f"# Full T80 RE {packet_label} Closeout",
        "",
        f"Final flag: `{final}`.",
        "",
        "## Verdict",
        "",
    ]
    if best:
        lines.append(
            f"No {packet_label} full-T80 row cleared the usable gate. "
            f"Best row is `{best.get('run_tag','')}` with gap `{best.get('best_gap','')}`, "
            f"outer `{best.get('best_outer','')}`, verdict `{best.get('verdict','')}`."
        )
    else:
        lines.append(f"No {packet_label} row produced a finite ranked gap.")
    lines.extend([
        "",
        "The headline full-T80 RE figure should not be reported unless a row clears "
        f"`max_abs_path_gap <= {USABLE_GAP}`.",
        "",
        "## Ranked Rows",
        "",
        "| run_tag | state | verdict | gap | outer | notes |",
        "|---|---|---|---:|---:|---|",
    ])
    for row in rows:
        lines.append("| `{}` | {} | {} | {} | {} | {} |".format(
            row.get("run_tag", ""),
            row.get("state", ""),
            row.get("verdict", ""),
            row.get("best_gap", ""),
            row.get("best_outer", ""),
            row.get("notes", ""),
        ))
    lines.extend([
        "",
        "## Missing Or Timed-Out Rows",
        "",
        ", ".join(f"`{r.get('run_tag','')}`" for r in missing) if missing else "None.",
        "",
    ])
    if include_next_solver:
        lines.extend([
            "## Prepared Next Solver, Not Submitted",
            "",
            "If the user explicitly asks to continue after this closeout, the next prepared route is "
            "the sequential black-box LM/Gauss-Newton residual-minimization fallback. It is a "
            "different numerical formulation of the same full-T80 RE fixed-point problem, not a "
            "bounded-horizon or partial-equilibrium relabeling.",
            "",
            "- Driver: `run_re_lm_0513.m`.",
            "- Wrapper: `bb80relm_0513.slurm`.",
            "- Design note: `next_full_t80_re_solver_design_0513.md`.",
            "- Expected ranking grid after a run: `truth/re_lm_0513/lm80_from_w80_b60hold_o4_grid.csv`.",
            "- Expected ranked output after a run: `truth/re_lm_0513/ranked/re_wide_ranked_0512.csv`.",
            "",
            "Do not submit this fallback while `bb80safe13` / job `17145335` is live. If launched "
            "later, accept any result only through the same gates: full T80, headline-eligible RE "
            "route, `max_abs_path_gap <= 0.001` for usable and `<= 0.0002` for paper-safe, then "
            "the guarded RE-vs-no-RE figure builder and validation table.",
            "",
        ])
    lines.extend([
        "## Paper-Safe Wording",
        "",
        "> We explored full perfect-foresight rational-expectations transition paths for the "
        "80-year baby-boom experiment. Across "
        f"{method_summary}, the best full-T80 candidates "
        "remained above our pre-specified numerical acceptance threshold. We therefore do "
        "not report a full-T80 RE transition figure as a headline result. Instead, we treat "
        "bounded-horizon expectations and stationary RE calculations as robustness/mechanism "
        "exercises, distinct from the original no-RE transition.",
        "",
    ])
    path.write_text("\n".join(lines), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--annual-dir", default=".")
    parser.add_argument("--grid", default="model_re_safeguard_0513.csv")
    parser.add_argument("--rank-out-dir", default="truth/re_safeguard_0513")
    parser.add_argument("--figure-out-dir", default="truth/re_safeguard_0513/figure")
    parser.add_argument("--failure-memo", default="truth/re_safeguard_0513/full_t80_re_failure_memo_0513.md")
    parser.add_argument("--packet-label", default="Safeguarded")
    parser.add_argument(
        "--method-summary",
        default="continuation, bridge, basis-projection, residual-focus, and safeguarded fixed-point searches",
    )
    parser.add_argument("--no-next-solver-section", action="store_true")
    parser.add_argument("--final", action="store_true")
    args = parser.parse_args()

    annual = Path(args.annual_dir).resolve()
    rank_cmd = [
        sys.executable,
        "rank_re_wide_0512.py",
        "--annual-dir", ".",
        "--grid", args.grid,
        "--out-dir", args.rank_out_dir,
    ]
    subprocess.run(rank_cmd, cwd=annual, check=True)
    ranked_path = annual / args.rank_out_dir / "re_wide_ranked_0512.csv"
    rows = read_rows(ranked_path)
    if not rows:
        print("No ranked rows found.")
        return 4

    usable = [
        r for r in rows
        if is_headline_full_re(r)
        and math.isfinite(fnum(r.get("best_gap")))
        and fnum(r.get("best_gap")) <= USABLE_GAP
    ]
    if usable:
        best = min(usable, key=lambda r: fnum(r.get("best_gap")))
        figure_cmd = [
            sys.executable,
            "build_re_vs_nore_figure_0513.py",
            "--annual-dir", ".",
            "--ranked", str(Path(args.rank_out_dir) / "re_wide_ranked_0512.csv"),
            "--run-tag", best["run_tag"],
            "--out-dir", args.figure_out_dir,
        ]
        subprocess.run(figure_cmd, cwd=annual, check=True)
        print(f"SUCCESS usable full-T80 RE row: {best['run_tag']} gap {best.get('best_gap','')}")
        if fnum(best.get("best_gap")) <= PAPER_SAFE_GAP:
            print("Paper-safe gate cleared.")
        return 0

    missing = [r for r in rows if r.get("state") == "missing"]
    if missing and not args.final:
        print("PENDING no usable row yet; missing rows remain: " + ", ".join(r.get("run_tag", "") for r in missing))
        return 3

    write_failure_memo(
        annual / args.failure_memo,
        rows,
        args.final,
        args.packet_label,
        args.method_summary,
        not args.no_next_solver_section,
    )
    best = next((r for r in rows if math.isfinite(fnum(r.get("best_gap")))), rows[0])
    print(f"FAIL no usable full-T80 RE row. Best visible: {best.get('run_tag','')} gap {best.get('best_gap','')}")
    print(f"Wrote {annual / args.failure_memo}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
