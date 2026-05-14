#!/usr/bin/env python3
"""Build the full-T80 RE versus no-RE comparator figure and validation table."""

import argparse
import csv
import math
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


def same_outer(left, right):
    left_num = fnum(left)
    right_num = fnum(right)
    if math.isfinite(left_num) and math.isfinite(right_num):
        return abs(left_num - right_num) <= 1e-9
    return str(left) == str(right)


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


def choose_re_row(rows, run_tag, allow_survivor=False):
    if run_tag:
        matched = [r for r in rows if r.get("run_tag") == run_tag]
        if not matched:
            raise SystemExit(f"Requested run_tag not found in ranked file: {run_tag}")
        row = matched[0]
        gap = fnum(row.get("best_gap"))
        if not is_headline_full_re(row):
            raise SystemExit(f"Requested run_tag is not eligible as a headline full-T80 RE row: {run_tag}")
        if gap > USABLE_GAP and not allow_survivor:
            raise SystemExit(
                f"Requested run_tag is not usable as full RE: {run_tag} gap {row.get('best_gap')}; "
                "rerun with --allow-survivor only for diagnostics."
            )
        return row
    candidates = [
        r for r in rows
        if is_headline_full_re(r)
        and r.get("verdict") in {"paper_safe", "usable"}
        and fnum(r.get("best_gap")) <= USABLE_GAP
    ]
    if not candidates:
        raise SystemExit("No usable full-T80 RE row found; not building a headline figure.")
    return min(candidates, key=lambda r: fnum(r.get("best_gap")))


def normalized_series(rows, price_col, outer=None):
    if outer is not None and rows and "outer_iter" in rows[0]:
        rows = [r for r in rows if same_outer(r.get("outer_iter"), outer)]
    rows = sorted(rows, key=lambda r: fnum(r.get("period")))
    rows = [r for r in rows if fnum(r.get(price_col)) > 0]
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


def write_csv(path, rows, fields):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def write_svg(path_svg, combined, title):
    width, height = 760, 460
    margin_left, margin_right, margin_top, margin_bottom = 72, 24, 52, 58
    plot_w = width - margin_left - margin_right
    plot_h = height - margin_top - margin_bottom
    xs = [r["year"] or r["period"] for r in combined]
    ys = [r["pct_dev"] for r in combined]
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)
    pad = max(0.05, 0.08 * (ymax - ymin if ymax > ymin else 1.0))
    ymin, ymax = ymin - pad, ymax + pad

    def sx(x):
        if xmax == xmin:
            return margin_left
        return margin_left + plot_w * (x - xmin) / (xmax - xmin)

    def sy(y):
        if ymax == ymin:
            return margin_top + plot_h / 2
        return margin_top + plot_h * (1 - (y - ymin) / (ymax - ymin))

    def points(label):
        sub = [r for r in combined if r["series"] == label]
        return " ".join(f"{sx(r['year'] or r['period']):.2f},{sy(r['pct_dev']):.2f}" for r in sub)

    y0 = sy(0.0)
    y_ticks = [ymin + i * (ymax - ymin) / 4 for i in range(5)]
    x_ticks = [xmin + i * (xmax - xmin) / 4 for i in range(5)]
    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<style>text{font-family:Arial,Helvetica,sans-serif;fill:#222} .axis{stroke:#333;stroke-width:1} .grid{stroke:#ddd;stroke-width:1} .nore{fill:none;stroke:#1f77b4;stroke-width:2.8} .re{fill:none;stroke:#d62728;stroke-width:2.8;stroke-dasharray:7 5}</style>',
        f'<text x="{margin_left}" y="28" font-size="18" font-weight="600">{title}</text>',
    ]
    for yt in y_ticks:
        y = sy(yt)
        svg.append(f'<line class="grid" x1="{margin_left}" x2="{width - margin_right}" y1="{y:.2f}" y2="{y:.2f}"/>')
        svg.append(f'<text x="{margin_left - 10}" y="{y + 4:.2f}" font-size="12" text-anchor="end">{yt:.2f}</text>')
    for xt in x_ticks:
        x = sx(xt)
        svg.append(f'<text x="{x:.2f}" y="{height - margin_bottom + 22}" font-size="12" text-anchor="middle">{xt:.0f}</text>')
    if margin_top <= y0 <= height - margin_bottom:
        svg.append(f'<line x1="{margin_left}" x2="{width - margin_right}" y1="{y0:.2f}" y2="{y0:.2f}" stroke="#777" stroke-width="1"/>')
    svg.append(f'<line class="axis" x1="{margin_left}" x2="{margin_left}" y1="{margin_top}" y2="{height - margin_bottom}"/>')
    svg.append(f'<line class="axis" x1="{margin_left}" x2="{width - margin_right}" y1="{height - margin_bottom}" y2="{height - margin_bottom}"/>')
    svg.append(f'<polyline class="nore" points="{points("No RE")}"/>')
    svg.append(f'<polyline class="re" points="{points("Full RE")}"/>')
    svg.append(f'<text x="{margin_left}" y="{height - 14}" font-size="13">Year</text>')
    svg.append(f'<text transform="translate(18 {height / 2}) rotate(-90)" font-size="13">House price, percent deviation from period 1</text>')
    svg.append(f'<line x1="{width - 170}" x2="{width - 135}" y1="70" y2="70" class="nore"/><text x="{width - 126}" y="74" font-size="13">No RE</text>')
    svg.append(f'<line x1="{width - 170}" x2="{width - 135}" y1="94" y2="94" class="re"/><text x="{width - 126}" y="98" font-size="13">Full RE</text>')
    svg.append("</svg>")
    path_svg.write_text("\n".join(svg), encoding="utf-8")


def try_plot(path_png, path_pdf, path_svg, combined, title):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception as exc:
        write_svg(path_svg, combined, title)
        return f"matplotlib unavailable; wrote SVG fallback: {exc}"

    fig, ax = plt.subplots(figsize=(7.2, 4.4))
    for label, style in [("No RE", "-"), ("Full RE", "--")]:
        sub = [r for r in combined if r["series"] == label]
        ax.plot([r["year"] or r["period"] for r in sub], [r["pct_dev"] for r in sub], style, linewidth=2.2, label=label)
    ax.axhline(0, color="0.35", linewidth=0.8)
    ax.set_title(title)
    ax.set_ylabel("House price, percent deviation from period 1")
    ax.set_xlabel("Year")
    ax.legend(frameon=False)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    fig.tight_layout()
    fig.savefig(path_png, dpi=300)
    fig.savefig(path_pdf)
    fig.savefig(path_svg)
    plt.close(fig)
    return "ok"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--annual-dir", default=".")
    parser.add_argument("--ranked", default="truth/re_safeguard_0513/re_wide_ranked_0512.csv")
    parser.add_argument("--run-tag", default="")
    parser.add_argument("--nore-tag", default="nore80bv4_006")
    parser.add_argument("--out-dir", default="truth/re_safeguard_0513/figure")
    parser.add_argument("--allow-survivor", action="store_true")
    args = parser.parse_args()

    annual = Path(args.annual_dir).resolve()
    out_dir = annual / args.out_dir
    ranked_rows = read_rows(annual / args.ranked)
    if not ranked_rows:
        raise SystemExit(f"Missing ranked file: {annual / args.ranked}")

    chosen = choose_re_row(ranked_rows, args.run_tag or "", args.allow_survivor)
    run_tag = chosen["run_tag"]
    best_outer = chosen.get("best_outer", "")
    best_gap = fnum(chosen.get("best_gap"))

    re_root = annual / "truth" / "annual_political_full_re_price_path" / run_tag
    nore_root = annual / "truth" / "annual_political_transition_fail_safe" / args.nore_tag
    re_rows = read_rows(re_root / "paths_all.csv")
    nore_rows = read_rows(nore_root / "paths_T80.csv")
    if not re_rows:
        raise SystemExit(f"Missing RE paths: {re_root / 'paths_all.csv'}")
    if not nore_rows:
        raise SystemExit(f"Missing no-RE paths: {nore_root / 'paths_T80.csv'}")

    re_series = normalized_series(re_rows, "price_guess", best_outer)
    nore_series = normalized_series(nore_rows, "price", None)
    if not re_series or not nore_series:
        raise SystemExit("Could not construct normalized RE/no-RE series.")

    T = min(80, len(re_series), len(nore_series))
    combined = []
    for i in range(T):
        combined.append(dict(series="Full RE", **re_series[i]))
        combined.append(dict(series="No RE", **nore_series[i]))

    re_peak = max(r["pct_dev"] for r in re_series[:T])
    nore_peak = max(r["pct_dev"] for r in nore_series[:T])
    re_trough = min(r["pct_dev"] for r in re_series[:T])
    nore_trough = min(r["pct_dev"] for r in nore_series[:T])

    validation = [{
        "re_run_tag": run_tag,
        "re_family": chosen.get("family", ""),
        "re_route": chosen.get("route", ""),
        "re_demographic_scenario": chosen.get("demographic_scenario", ""),
        "re_horizon_t": chosen.get("horizon_t", ""),
        "re_post_report_mode": chosen.get("post_report_mode", ""),
        "re_tail_years": chosen.get("tail_years", ""),
        "re_terminal_anchor": chosen.get("terminal_anchor", ""),
        "re_terminal_blend_weight": chosen.get("terminal_blend_weight", ""),
        "re_terminal_relaxation": chosen.get("terminal_relaxation", ""),
        "re_terminal_iter": chosen.get("terminal_iter", ""),
        "re_shock_amplitude": chosen.get("shock_amplitude", ""),
        "re_pass_through": chosen.get("pass_through", ""),
        "re_ttb_proxy_lag_years": chosen.get("ttb_proxy_lag_years", ""),
        "re_vote_shift_mode": chosen.get("vote_shift_mode", ""),
        "re_vote_shift_horizon": chosen.get("vote_shift_horizon", ""),
        "re_vote_block_length": chosen.get("vote_block_length", ""),
        "re_source_mode": chosen.get("source_mode", ""),
        "re_source_run_tag": chosen.get("source_run_tag", ""),
        "re_source_outer": chosen.get("source_outer", ""),
        "re_path_update_method": chosen.get("path_update_method", ""),
        "re_basis_dim": chosen.get("basis_dim", ""),
        "re_basis_focus_start": chosen.get("basis_focus_start", ""),
        "re_basis_focus_end": chosen.get("basis_focus_end", ""),
        "re_basis_focus_weight": chosen.get("basis_focus_weight", ""),
        "re_path_relaxation": chosen.get("path_relaxation", ""),
        "re_vote_scale": chosen.get("vote_scale", ""),
        "re_best_outer": best_outer,
        "re_max_abs_path_gap": chosen.get("best_gap", ""),
        "re_max_generated_fixed_gap": chosen.get("max_generated_fixed_gap", ""),
        "headline_full_t80_re": str(is_headline_full_re(chosen)),
        "usable_gate": USABLE_GAP,
        "paper_safe_gate": PAPER_SAFE_GAP,
        "usable": str(best_gap <= USABLE_GAP),
        "paper_safe": str(best_gap <= PAPER_SAFE_GAP),
        "nore_run_tag": args.nore_tag,
        "re_path_source": str(re_root / "paths_all.csv"),
        "nore_path_source": str(nore_root / "paths_T80.csv"),
        "re_price_column": "price_guess",
        "nore_price_column": "price",
        "plotted_periods": T,
        "normalization": "percent deviation from period-1 price, separately by series",
        "re_peak_pct": f"{re_peak:.12g}",
        "nore_peak_pct": f"{nore_peak:.12g}",
        "re_trough_pct": f"{re_trough:.12g}",
        "nore_trough_pct": f"{nore_trough:.12g}",
        "peak_difference_re_minus_nore_pctpt": f"{re_peak - nore_peak:.12g}",
    }]

    write_csv(out_dir / "full_t80_re_vs_nore_0513.csv", combined, ["series", "period", "year", "price", "log_dev", "pct_dev"])
    write_csv(out_dir / "full_t80_re_validation_0513.csv", validation, list(validation[0].keys()))
    plot_status = try_plot(
        out_dir / "full_t80_re_vs_nore_0513.png",
        out_dir / "full_t80_re_vs_nore_0513.pdf",
        out_dir / "full_t80_re_vs_nore_0513.svg",
        combined,
        f"Baby-boom house-price transition: full RE versus no RE ({run_tag})",
    )
    print(f"Selected RE row: {run_tag}, outer {best_outer}, gap {chosen.get('best_gap', '')}")
    print(f"Wrote {out_dir / 'full_t80_re_vs_nore_0513.csv'}")
    print(f"Wrote {out_dir / 'full_t80_re_validation_0513.csv'}")
    print(f"Plot status: {plot_status}")


if __name__ == "__main__":
    raise SystemExit(main())
