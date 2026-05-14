#!/usr/bin/env python3
"""Build bounded price-expectations versus no-RE comparison artifacts."""

import argparse
import csv
import math
from pathlib import Path


USABLE_GAP = 0.001
PAPER_SAFE_GAP = 0.0002


def fnum(value):
    try:
        return float(value)
    except Exception:
        return float("nan")


def read_rows(path):
    with path.open(newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def write_csv(path, rows, fields):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def rows_for_outer(rows, outer):
    return [
        r for r in rows
        if "outer_iter" not in r or abs(fnum(r.get("outer_iter")) - float(outer)) <= 1e-9
    ]


def normalized_series(rows, price_col, horizon):
    rows = sorted(rows, key=lambda r: fnum(r.get("period")))
    rows = [r for r in rows if fnum(r.get("period")) <= horizon and fnum(r.get(price_col)) > 0]
    if not rows:
        return []
    base = fnum(rows[0][price_col])
    out = []
    for r in rows:
        price = fnum(r[price_col])
        log_dev = math.log(price / base)
        out.append({
            "period": int(fnum(r.get("period"))),
            "year": int(fnum(r.get("year"))) if math.isfinite(fnum(r.get("year"))) else "",
            "price": price,
            "log_dev": log_dev,
            "pct_dev": 100.0 * (math.exp(log_dev) - 1.0),
        })
    return out


def path_gap(rows, horizon):
    gaps = []
    for r in rows:
        if fnum(r.get("period")) > horizon:
            continue
        guess = fnum(r.get("price_guess"))
        generated = fnum(r.get("price_generated"))
        if guess > 0 and generated > 0:
            gaps.append(abs(math.log(generated / guess)))
    return max(gaps) if gaps else float("nan")


def write_svg(path_svg, combined, title):
    width, height = 780, 460
    ml, mr, mt, mb = 76, 26, 52, 58
    pw, ph = width - ml - mr, height - mt - mb
    xs = [r["year"] or r["period"] for r in combined]
    ys = [r["pct_dev"] for r in combined]
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)
    pad = max(0.03, 0.10 * (ymax - ymin if ymax > ymin else 1.0))
    ymin, ymax = ymin - pad, ymax + pad

    def sx(x):
        return ml + pw * (x - xmin) / (xmax - xmin) if xmax != xmin else ml

    def sy(y):
        return mt + ph * (1 - (y - ymin) / (ymax - ymin)) if ymax != ymin else mt + ph / 2

    def points(label):
        sub = [r for r in combined if r["series"] == label]
        return " ".join(f"{sx(r['year'] or r['period']):.2f},{sy(r['pct_dev']):.2f}" for r in sub)

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<style>text{font-family:Arial,Helvetica,sans-serif;fill:#222}.axis{stroke:#333;stroke-width:1}.grid{stroke:#ddd;stroke-width:1}.nore{fill:none;stroke:#1f77b4;stroke-width:2.8}.bounded{fill:none;stroke:#d62728;stroke-width:2.8;stroke-dasharray:7 5}</style>',
        f'<text x="{ml}" y="28" font-size="18" font-weight="600">{title}</text>',
    ]
    for i in range(5):
        yt = ymin + i * (ymax - ymin) / 4
        y = sy(yt)
        svg.append(f'<line class="grid" x1="{ml}" x2="{width - mr}" y1="{y:.2f}" y2="{y:.2f}"/>')
        svg.append(f'<text x="{ml - 10}" y="{y + 4:.2f}" font-size="12" text-anchor="end">{yt:.2f}</text>')
    for i in range(5):
        xt = xmin + i * (xmax - xmin) / 4
        x = sx(xt)
        svg.append(f'<text x="{x:.2f}" y="{height - mb + 22}" font-size="12" text-anchor="middle">{xt:.0f}</text>')
    y0 = sy(0.0)
    if mt <= y0 <= height - mb:
        svg.append(f'<line x1="{ml}" x2="{width - mr}" y1="{y0:.2f}" y2="{y0:.2f}" stroke="#777" stroke-width="1"/>')
    svg.append(f'<line class="axis" x1="{ml}" x2="{ml}" y1="{mt}" y2="{height - mb}"/>')
    svg.append(f'<line class="axis" x1="{ml}" x2="{width - mr}" y1="{height - mb}" y2="{height - mb}"/>')
    svg.append(f'<polyline class="nore" points="{points("No-RE comparator")}"/>')
    svg.append(f'<polyline class="bounded" points="{points("Bounded price expectations")}"/>')
    svg.append(f'<text x="{ml}" y="{height - 14}" font-size="13">Year</text>')
    svg.append(f'<text transform="translate(18 {height / 2}) rotate(-90)" font-size="13">House price, percent deviation from period 1</text>')
    svg.append(f'<line x1="{width - 246}" x2="{width - 211}" y1="70" y2="70" class="nore"/><text x="{width - 202}" y="74" font-size="13">No-RE comparator</text>')
    svg.append(f'<line x1="{width - 246}" x2="{width - 211}" y1="94" y2="94" class="bounded"/><text x="{width - 202}" y="98" font-size="13">Bounded price expectations</text>')
    svg.append("</svg>")
    path_svg.write_text("\n".join(svg), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bounded-paths", required=True)
    parser.add_argument("--nore-paths", required=True)
    parser.add_argument("--ranked", required=True)
    parser.add_argument("--grid", required=True)
    parser.add_argument("--run-tag", default="bound40_baby_rss_l4")
    parser.add_argument("--nore-tag", default="nore80bv4_006")
    parser.add_argument("--out-dir", required=True)
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    ranked = read_rows(Path(args.ranked))
    grid = read_rows(Path(args.grid))
    chosen = next((r for r in ranked if r.get("run_tag") == args.run_tag), None)
    grid_row = next((r for r in grid if r.get("run_tag") == args.run_tag), None)
    if chosen is None or grid_row is None:
        raise SystemExit(f"Could not find run tag {args.run_tag} in ranked/grid files.")
    if chosen.get("route") != "bounded_expectations":
        raise SystemExit(f"Run tag is not bounded expectations: {args.run_tag}")

    best_outer = chosen.get("best_outer")
    report_horizon = int(fnum(chosen.get("horizon_t")))
    internal_t = int(report_horizon + fnum(chosen.get("tail_years")))
    bounded_rows = rows_for_outer(read_rows(Path(args.bounded_paths)), best_outer)
    nore_rows = read_rows(Path(args.nore_paths))
    bounded_series = normalized_series(bounded_rows, "price_guess", report_horizon)
    nore_series = normalized_series(nore_rows, "price", report_horizon)
    if not bounded_series or not nore_series:
        raise SystemExit("Could not construct bounded/no-RE series.")

    combined = []
    for left, right in zip(bounded_series, nore_series):
        combined.append(dict(series="Bounded price expectations", **left))
        combined.append(dict(series="No-RE comparator", **right))

    bounded_peak = max(r["pct_dev"] for r in bounded_series)
    nore_peak = max(r["pct_dev"] for r in nore_series)
    bounded_trough = min(r["pct_dev"] for r in bounded_series)
    nore_trough = min(r["pct_dev"] for r in nore_series)
    recomputed_gap = path_gap(bounded_rows, report_horizon)
    validation = [{
        "expectations_object": "bounded_price_expectations",
        "not_full_t80_re": "true",
        "run_tag": args.run_tag,
        "route": chosen.get("route", ""),
        "demographic_scenario": chosen.get("demographic_scenario", ""),
        "report_horizon": report_horizon,
        "tail_years": chosen.get("tail_years", ""),
        "internal_t": internal_t,
        "best_outer": best_outer,
        "ranked_max_abs_path_gap": chosen.get("best_gap", ""),
        "recomputed_report_horizon_path_gap": f"{recomputed_gap:.15g}",
        "usable_gate": USABLE_GAP,
        "paper_safe_gate": PAPER_SAFE_GAP,
        "usable": str(fnum(chosen.get("best_gap")) <= USABLE_GAP).lower(),
        "paper_safe": str(fnum(chosen.get("best_gap")) <= PAPER_SAFE_GAP).lower(),
        "post_report_mode": grid_row.get("post_report_mode", ""),
        "terminal_anchor": grid_row.get("terminal_anchor", ""),
        "terminal_blend_weight": grid_row.get("terminal_blend_weight", ""),
        "terminal_relaxation": grid_row.get("terminal_relaxation", ""),
        "shock_amplitude": grid_row.get("shock_amplitude", ""),
        "pass_through": grid_row.get("pass_through", ""),
        "ttb_proxy_lag_years": grid_row.get("ttb_proxy_lag_years", ""),
        "path_update_method": grid_row.get("path_update_method", ""),
        "basis_dim": grid_row.get("basis_dim", ""),
        "basis_focus_start": grid_row.get("basis_focus_start", ""),
        "basis_focus_end": grid_row.get("basis_focus_end", ""),
        "basis_focus_weight": grid_row.get("basis_focus_weight", ""),
        "path_relaxation": grid_row.get("path_relaxation", ""),
        "vote_scale": grid_row.get("vote_scale", ""),
        "nore_tag": args.nore_tag,
        "bounded_price_column": "price_guess",
        "nore_price_column": "price",
        "plotted_periods": report_horizon,
        "normalization": "percent deviation from period-1 price, separately by series",
        "bounded_peak_pct": f"{bounded_peak:.12g}",
        "nore_peak_pct": f"{nore_peak:.12g}",
        "bounded_trough_pct": f"{bounded_trough:.12g}",
        "nore_trough_pct": f"{nore_trough:.12g}",
        "trough_difference_bounded_minus_nore_pctpt": f"{bounded_trough - nore_trough:.12g}",
    }]

    write_csv(
        out_dir / "bounded_price_expectations_vs_nore_0513.csv",
        combined,
        ["series", "period", "year", "price", "log_dev", "pct_dev"],
    )
    write_csv(out_dir / "bounded_price_expectations_validation_0513.csv", validation, list(validation[0].keys()))
    write_svg(
        out_dir / "bounded_price_expectations_vs_nore_0513.svg",
        combined,
        "Baby-boom house-price transition: bounded expectations vs no RE",
    )
    print(f"Selected bounded row: {args.run_tag}, outer {best_outer}, gap {chosen.get('best_gap', '')}")
    print(f"Wrote {out_dir / 'bounded_price_expectations_vs_nore_0513.csv'}")
    print(f"Wrote {out_dir / 'bounded_price_expectations_validation_0513.csv'}")
    print(f"Wrote {out_dir / 'bounded_price_expectations_vs_nore_0513.svg'}")


if __name__ == "__main__":
    raise SystemExit(main())
