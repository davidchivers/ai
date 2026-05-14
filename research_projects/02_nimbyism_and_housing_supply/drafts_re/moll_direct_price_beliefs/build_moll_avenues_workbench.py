from __future__ import annotations

import csv
import math
from datetime import date
from pathlib import Path


PROJECT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "workbench"

BOUNDED_PATH = (
    PROJECT
    / "drafts_re"
    / "bounded_price_expectations"
    / "source"
    / "bound40_baby_rss_l4_paths_all.csv"
)
NORE_PATH = (
    PROJECT
    / "drafts_re"
    / "bounded_price_expectations"
    / "source"
    / "nore80bv4_006_paths_T80.csv"
)
RANKED_PATH = (
    PROJECT / "drafts_re" / "bounded_price_expectations" / "source" / "re_alt_ranked_0512.csv"
)
LINEAR_ITER_PATH = PROJECT / "extensions" / "re_no_politics" / "linear_age_price_rule_iterations.csv"
REDUCED_K_SUMMARY_PATH = (
    PROJECT / "extensions" / "re_no_politics" / "transition_re_reduced_form_k_step_summary.csv"
)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: clean_cell(row.get(k, "")) for k in fieldnames})


def clean_cell(value: object) -> object:
    if isinstance(value, float):
        if not math.isfinite(value):
            return ""
        return f"{value:.12g}"
    if value is None:
        return ""
    return value


def f(row: dict[str, str], key: str, default: float | None = None) -> float:
    value = row.get(key, "")
    if value == "" or value is None:
        if default is None:
            raise KeyError(f"Missing numeric field {key}")
        return default
    return float(value)


def i(row: dict[str, str], key: str, default: int | None = None) -> int:
    value = row.get(key, "")
    if value == "" or value is None:
        if default is None:
            raise KeyError(f"Missing integer field {key}")
        return default
    return int(float(value))


def rmse(errors: list[float]) -> float | None:
    if not errors:
        return None
    return math.sqrt(sum(e * e for e in errors) / len(errors))


def max_abs(errors: list[float]) -> float | None:
    if not errors:
        return None
    return max(abs(e) for e in errors)


def solve_linear_system(a: list[list[float]], b: list[float]) -> list[float] | None:
    n = len(b)
    aug = [row[:] + [rhs] for row, rhs in zip(a, b)]
    for col in range(n):
        pivot = max(range(col, n), key=lambda r: abs(aug[r][col]))
        if abs(aug[pivot][col]) < 1e-12:
            return None
        if pivot != col:
            aug[col], aug[pivot] = aug[pivot], aug[col]
        scale = aug[col][col]
        for j in range(col, n + 1):
            aug[col][j] /= scale
        for r in range(n):
            if r == col:
                continue
            factor = aug[r][col]
            if factor == 0:
                continue
            for j in range(col, n + 1):
                aug[r][j] -= factor * aug[col][j]
    return [aug[r][n] for r in range(n)]


def ols(x: list[list[float]], y: list[float], ridge: float = 1e-8) -> list[float] | None:
    if not x:
        return None
    k = len(x[0])
    xtx = [[0.0 for _ in range(k)] for _ in range(k)]
    xty = [0.0 for _ in range(k)]
    for row, yy in zip(x, y):
        for c in range(k):
            xty[c] += row[c] * yy
            for d in range(k):
                xtx[c][d] += row[c] * row[d]
    for c in range(k):
        xtx[c][c] += ridge
    return solve_linear_system(xtx, xty)


def predict(beta: list[float] | None, x: list[float]) -> float | None:
    if beta is None:
        return None
    return sum(b * xx for b, xx in zip(beta, x))


def select_bounded_path() -> tuple[list[dict[str, str]], int]:
    ranked = read_csv(RANKED_PATH)
    best_outer = None
    for row in ranked:
        if row.get("run_tag") == "bound40_baby_rss_l4":
            best_outer = i(row, "best_outer")
            break
    rows = read_csv(BOUNDED_PATH)
    if best_outer is None:
        best_outer = max(i(row, "outer_iter") for row in rows)
    selected = [row for row in rows if i(row, "outer_iter") == best_outer and i(row, "period") <= 40]
    if not selected:
        best_outer = max(i(row, "outer_iter") for row in rows)
        selected = [row for row in rows if i(row, "outer_iter") == best_outer and i(row, "period") <= 40]
    selected.sort(key=lambda row: i(row, "period"))
    return selected, best_outer


def expanding_plm_predictions(
    log_prices: list[float],
    age_signal: list[float],
    min_train: int = 8,
) -> tuple[list[float | None], list[float] | None, list[float]]:
    preds: list[float | None] = [None] * len(log_prices)
    errors: list[float] = []
    for t in range(1, len(log_prices)):
        train_stop = t
        if train_stop < min_train:
            continue
        x_train = [
            [1.0, log_prices[j - 1], age_signal[j]]
            for j in range(1, train_stop)
        ]
        y_train = [log_prices[j] for j in range(1, train_stop)]
        beta = ols(x_train, y_train)
        pred = predict(beta, [1.0, log_prices[t - 1], age_signal[t]])
        preds[t] = pred
        if pred is not None:
            errors.append(pred - log_prices[t])
    final_x = [[1.0, log_prices[j - 1], age_signal[j]] for j in range(1, len(log_prices))]
    final_y = [log_prices[j] for j in range(1, len(log_prices))]
    final_beta = ols(final_x, final_y)
    return preds, final_beta, errors


def expanding_ar1_predictions(
    log_prices: list[float],
    min_train: int = 8,
) -> tuple[list[float | None], list[float] | None, list[float]]:
    preds: list[float | None] = [None] * len(log_prices)
    errors: list[float] = []
    for t in range(1, len(log_prices)):
        train_stop = t
        if train_stop < min_train:
            continue
        x_train = [[1.0, log_prices[j - 1]] for j in range(1, train_stop)]
        y_train = [log_prices[j] for j in range(1, train_stop)]
        beta = ols(x_train, y_train)
        pred = predict(beta, [1.0, log_prices[t - 1]])
        preds[t] = pred
        if pred is not None:
            errors.append(pred - log_prices[t])
    final_x = [[1.0, log_prices[j - 1]] for j in range(1, len(log_prices))]
    final_y = [log_prices[j] for j in range(1, len(log_prices))]
    final_beta = ols(final_x, final_y)
    return preds, final_beta, errors


def best_restricted_heuristic(log_prices: list[float]) -> tuple[list[float | None], dict[str, float], list[float]]:
    benchmark = sum(log_prices[: min(4, len(log_prices))]) / min(4, len(log_prices))
    best: tuple[float, float, float, list[float | None], list[float]] | None = None
    lambda_grid = [x / 20.0 for x in range(0, 26)]
    anchor_grid = [0.0, 0.025, 0.05, 0.10, 0.20, 0.40, 0.80]
    for lam in lambda_grid:
        for anchor in anchor_grid:
            preds: list[float | None] = [None] * len(log_prices)
            errors: list[float] = []
            for t in range(2, len(log_prices)):
                last_growth = log_prices[t - 1] - log_prices[t - 2]
                pred = log_prices[t - 1] + lam * last_growth - anchor * (log_prices[t - 1] - benchmark)
                preds[t] = pred
                errors.append(pred - log_prices[t])
            score = rmse(errors)
            if score is None:
                continue
            if best is None or score < best[0]:
                best = (score, lam, anchor, preds, errors)
    if best is None:
        return [None] * len(log_prices), {"lambda": 0.0, "anchor": 0.0, "benchmark": benchmark}, []
    _, lam, anchor, preds, errors = best
    return preds, {"lambda": lam, "anchor": anchor, "benchmark": benchmark}, errors


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    bounded, best_outer = select_bounded_path()
    nore_rows = [row for row in read_csv(NORE_PATH) if i(row, "period") <= 40]
    nore_rows.sort(key=lambda row: i(row, "period"))

    log_realized = [math.log(f(row, "price_generated")) for row in bounded]
    log_guess = [math.log(f(row, "price_guess")) for row in bounded]
    years = [i(row, "year") for row in bounded]
    periods = [i(row, "period") for row in bounded]
    age_raw = [f(row, "age_col_used") for row in bounded]
    age_signal = [x - age_raw[0] for x in age_raw]
    pressure = [f(row, "pressure", 0.0) for row in bounded]
    restriction = [f(row, "restriction", 0.0) for row in bounded]

    nore_by_period = {i(row, "period"): math.log(f(row, "price")) for row in nore_rows}

    te_errors = [g - b for g, b in zip(log_guess, log_realized)]
    lsl_preds, lsl_beta, lsl_errors = expanding_plm_predictions(log_realized, age_signal)
    ar1_preds, ar1_beta, ar1_errors = expanding_ar1_predictions(log_realized)
    heur_preds, heur_params, heur_errors = best_restricted_heuristic(log_realized)

    linear_rows = read_csv(LINEAR_ITER_PATH)
    reduced_rows = read_csv(REDUCED_K_SUMMARY_PATH)
    reduced_k8 = [
        row for row in reduced_rows if i(row, "k") == 8 and abs(f(row, "re_weight") - 1.0) < 1e-9
    ]
    reduced_ref = reduced_k8[0] if reduced_k8 else None

    summary_rows: list[dict[str, object]] = [
        {
            "route_id": "temporary_equilibrium_bounded_t40",
            "route_family": "A",
            "moll_avenue": "temporary equilibrium with specified direct price beliefs",
            "input_object": "bound40_baby_rss_l4 best outer",
            "status": "numeric_smoke_available",
            "tractable": "yes",
            "empirical_discipline": "weak_internal_only",
            "belief_feedback": "weak_fixed_belief_path",
            "rmse_log_price": rmse(te_errors),
            "max_abs_log_error": max_abs(te_errors),
            "selected_parameter": f"best_outer={best_outer}",
            "read": "Useful baseline, but this is not yet Moll's preferred object because beliefs are not measured or updated.",
            "decision": "keep_as_baseline_only",
        },
        {
            "route_id": "survey_or_measured_price_beliefs",
            "route_family": "A_empirical",
            "moll_avenue": "temporary equilibrium disciplined by measured expectations",
            "input_object": "no local survey-expectations moments wired in",
            "status": "blocked_by_missing_expectations_data",
            "tractable": "yes",
            "empirical_discipline": "required_not_yet_added",
            "belief_feedback": "policy_contingent_or_reestimated_needed",
            "rmse_log_price": None,
            "max_abs_log_error": None,
            "selected_parameter": "",
            "read": "This is paper-facing only after adding external house-price-expectations moments.",
            "decision": "data_gate_before_claim",
        },
        {
            "route_id": "least_squares_learning_age_price",
            "route_family": "B",
            "moll_avenue": "least-squares learning over a low-dimensional direct price law",
            "input_object": "recursive OLS on available bounded-path realized prices",
            "status": "numeric_smoke_available",
            "tractable": "yes",
            "empirical_discipline": "weak_until_expectations_moments_added",
            "belief_feedback": "yes_coefficients_update_from_realized_prices",
            "rmse_log_price": rmse(lsl_errors),
            "max_abs_log_error": max_abs(lsl_errors),
            "selected_parameter": "logP_t = a + rho logP_{t-1} + beta age_signal_t",
            "read": "Best immediate Moll route: direct price beliefs, low-dimensional state, and explicit feedback.",
            "decision": "build_first",
        },
        {
            "route_id": "restricted_perceptions_adaptive_anchor",
            "route_family": "C",
            "moll_avenue": "restricted perceptions / simple heuristic forecasting",
            "input_object": "adaptive extrapolation plus anchor grid on available realized prices",
            "status": "numeric_smoke_available",
            "tractable": "yes",
            "empirical_discipline": "candidate_if_calibrated_to_expectations_evidence",
            "belief_feedback": "yes_if_rule_is_reestimated_or_market_clearing_iterated",
            "rmse_log_price": rmse(heur_errors),
            "max_abs_log_error": max_abs(heur_errors),
            "selected_parameter": f"lambda={heur_params['lambda']:.3g}; anchor={heur_params['anchor']:.3g}",
            "read": "Main robustness route; transparent but can become ad hoc without evidence.",
            "decision": "develop_as_robustness",
        },
        {
            "route_id": "price_only_aggregate_law_ar1",
            "route_family": "D",
            "moll_avenue": "price-only aggregate law / Krusell-Smith-style price forecast",
            "input_object": "recursive AR(1) on available realized prices",
            "status": "numeric_smoke_available",
            "tractable": "yes",
            "empirical_discipline": "weak_internal_only",
            "belief_feedback": "yes_if_reestimated_from_model_prices",
            "rmse_log_price": rmse(ar1_errors),
            "max_abs_log_error": max_abs(ar1_errors),
            "selected_parameter": "logP_t = a + rho logP_{t-1}",
            "read": "Useful computational scaffold, but thinner than the age-price learning route.",
            "decision": "use_as_cross_check",
        },
        {
            "route_id": "reduced_form_price_operator_k8",
            "route_family": "D",
            "moll_avenue": "price-only aggregate operator already solved in no-politics branch",
            "input_object": "extensions/re_no_politics transition_re_reduced_form_k_step",
            "status": "existing_numeric_operator_converged" if reduced_ref else "missing",
            "tractable": "yes",
            "empirical_discipline": "weak_internal_only",
            "belief_feedback": "operator_based_feedback_not_structural_political_feedback",
            "rmse_log_price": None,
            "max_abs_log_error": f(reduced_ref, "max_abs_log_gap") if reduced_ref else None,
            "selected_parameter": "re_weight=1; k=8" if reduced_ref else "",
            "read": "Confirms that price-only aggregate closures are numerically tame, but not yet the annual political model.",
            "decision": "infrastructure_not_headline",
        },
        {
            "route_id": "reinforcement_learning",
            "route_family": "E",
            "moll_avenue": "reinforcement learning / experience-based learning",
            "input_object": "not attempted",
            "status": "not_suitable_for_current_14h_route",
            "tractable": "unknown_for_current_code",
            "empirical_discipline": "would_need_separate_design",
            "belief_feedback": "potentially_yes",
            "rmse_log_price": None,
            "max_abs_log_error": None,
            "selected_parameter": "",
            "read": "Legitimate Moll-adjacent future direction, but too large and hard to validate here.",
            "decision": "future_work_only",
        },
    ]

    coefficients: list[dict[str, object]] = [
        {
            "route_id": "temporary_equilibrium_bounded_t40",
            "coefficient": "best_outer",
            "value": best_outer,
            "note": "Ranked best outer for bound40_baby_rss_l4.",
        },
        {
            "route_id": "restricted_perceptions_adaptive_anchor",
            "coefficient": "lambda",
            "value": heur_params["lambda"],
            "note": "Best grid value for adaptive extrapolation.",
        },
        {
            "route_id": "restricted_perceptions_adaptive_anchor",
            "coefficient": "anchor",
            "value": heur_params["anchor"],
            "note": "Best grid value for pull back to benchmark.",
        },
        {
            "route_id": "restricted_perceptions_adaptive_anchor",
            "coefficient": "log_benchmark",
            "value": heur_params["benchmark"],
            "note": "Mean log price over the first four periods.",
        },
    ]
    if lsl_beta:
        for name, value in zip(["intercept", "rho_lag_log_price", "beta_age_signal"], lsl_beta):
            coefficients.append(
                {
                    "route_id": "least_squares_learning_age_price",
                    "coefficient": name,
                    "value": value,
                    "note": "Full-sample OLS coefficient used only as a smoke benchmark.",
                }
            )
    if ar1_beta:
        for name, value in zip(["intercept", "rho_lag_log_price"], ar1_beta):
            coefficients.append(
                {
                    "route_id": "price_only_aggregate_law_ar1",
                    "coefficient": name,
                    "value": value,
                    "note": "Full-sample AR(1) coefficient used only as a smoke benchmark.",
                }
            )
    for row in linear_rows[:2]:
        coefficients.append(
            {
                "route_id": "existing_linear_age_price_rule",
                "coefficient": f"iteration_{i(row, 'iteration')}_rmse",
                "value": f(row, "rmse"),
                "note": "Existing no-politics template diagnostic.",
            }
        )
        coefficients.append(
            {
                "route_id": "existing_linear_age_price_rule",
                "coefficient": f"iteration_{i(row, 'iteration')}_stable_update",
                "value": i(row, "stable_update"),
                "note": "Existing no-politics template diagnostic.",
            }
        )

    path_rows: list[dict[str, object]] = []
    for idx, row in enumerate(bounded):
        p = periods[idx]
        path_rows.append(
            {
                "period": p,
                "year": years[idx],
                "log_price_realized": log_realized[idx],
                "log_price_belief_guess": log_guess[idx],
                "log_price_nore": nore_by_period.get(p),
                "age_signal": age_signal[idx],
                "pressure": pressure[idx],
                "restriction": restriction[idx],
                "least_squares_learning_pred": lsl_preds[idx],
                "restricted_heuristic_pred": heur_preds[idx],
                "price_only_ar1_pred": ar1_preds[idx],
            }
        )

    write_csv(
        OUT / "moll_avenues_summary.csv",
        summary_rows,
        [
            "route_id",
            "route_family",
            "moll_avenue",
            "input_object",
            "status",
            "tractable",
            "empirical_discipline",
            "belief_feedback",
            "rmse_log_price",
            "max_abs_log_error",
            "selected_parameter",
            "read",
            "decision",
        ],
    )
    write_csv(OUT / "moll_avenues_coefficients.csv", coefficients, ["route_id", "coefficient", "value", "note"])
    write_csv(
        OUT / "moll_avenues_paths.csv",
        path_rows,
        [
            "period",
            "year",
            "log_price_realized",
            "log_price_belief_guess",
            "log_price_nore",
            "age_signal",
            "pressure",
            "restriction",
            "least_squares_learning_pred",
            "restricted_heuristic_pred",
            "price_only_ar1_pred",
        ],
    )

    report = build_report(summary_rows, coefficients, best_outer)
    (OUT / "moll_avenues_report.md").write_text(report, encoding="utf-8")


def build_report(summary_rows: list[dict[str, object]], coefficients: list[dict[str, object]], best_outer: int) -> str:
    def metric(route_id: str, key: str) -> str:
        row = next(r for r in summary_rows if r["route_id"] == route_id)
        value = row.get(key)
        if value is None or value == "":
            return ""
        if isinstance(value, float):
            return f"{value:.6g}"
        return str(value)

    def coef(route_id: str, name: str) -> str:
        for row in coefficients:
            if row["route_id"] == route_id and row["coefficient"] == name:
                value = row["value"]
                return f"{value:.6g}" if isinstance(value, float) else str(value)
        return ""

    lines = [
        "# Moll direct-price-beliefs avenues workbench",
        "",
        f"Built: {date.today().isoformat()}",
        "",
        "Source: Benjamin Moll, rational-expectations challenge PDF,",
        "https://benjaminmoll.com/wp-content/uploads/2024/07/challenge.pdf",
        "",
        "## Bottom line",
        "",
        "This workbench treats Moll as giving a route menu, not a single command",
        "to use the existing bounded T40 object. The common denominator is direct",
        "price beliefs: agents forecast prices directly, the forecast rule is low",
        "dimensional, and the rule should be disciplined by expectations evidence",
        "or updated from model outcomes.",
        "",
        "For this project, the best immediate route is still Route B: least-squares",
        "learning over a direct price law. Route C, restricted perceptions or",
        "heuristics, is the best robustness route. Route A is useful only as a",
        "baseline until measured or calibrated expectations are added. Route D is",
        "infrastructure. Route E is future work.",
        "",
        "## Numeric smoke results",
        "",
        "| Route | Status | RMSE log price | Max abs log error | Decision |",
        "|---|---|---:|---:|---|",
    ]
    for row in summary_rows:
        lines.append(
            "| {route} | {status} | {rmse} | {maxerr} | {decision} |".format(
                route=row["route_id"],
                status=row["status"],
                rmse=metric(str(row["route_id"]), "rmse_log_price"),
                maxerr=metric(str(row["route_id"]), "max_abs_log_error"),
                decision=row["decision"],
            )
        )
    lines += [
        "",
        "## Route reads",
        "",
        f"- Temporary-equilibrium baseline: uses `bound40_baby_rss_l4` outer `{best_outer}`.",
        "  It is tractable and numerically usable, but still weak on empirical",
        "  discipline and weak on belief feedback.",
        "- Survey or measured expectations: conceptually important for Moll, but",
        "  this local workbench has no external expectations moments wired in yet.",
        "  This is a data gate, not a computational failure.",
        "- Least-squares learning: the smoke rule is",
        "  `logP_t = a + rho logP_{t-1} + beta age_signal_t`.",
        f"  Full-sample smoke coefficients are a = {coef('least_squares_learning_age_price', 'intercept')},",
        f"  rho = {coef('least_squares_learning_age_price', 'rho_lag_log_price')},",
        f"  beta = {coef('least_squares_learning_age_price', 'beta_age_signal')}.",
        "  This is the closest operational match to Moll because realized prices",
        "  feed back into the perceived law of motion.",
        "- Restricted perceptions: the best smoke heuristic is adaptive growth with",
        f"  lambda = {coef('restricted_perceptions_adaptive_anchor', 'lambda')} and",
        f"  anchor = {coef('restricted_perceptions_adaptive_anchor', 'anchor')}.",
        "  It is a good robustness candidate if calibrated to expectations evidence.",
        "- Price-only aggregate law: the AR(1) smoke is useful as a price-only",
        "  scaffold, but it is thinner than the age-price learning rule because it",
        "  ignores demographic information.",
        "- Existing reduced-form operator: the no-politics k-step price operator has",
        "  already converged through k = 8 at re_weight = 1. It supports using a",
        "  price-only aggregate closure as infrastructure, not as the headline",
        "  annual political model.",
        "- Reinforcement learning: a real avenue in the broad Moll menu, but not",
        "  credible for the current paper timeline without a separate design.",
        "",
        "## Next implementation step",
        "",
        "Port Route B into the annual political baby-boom runner as the main Moll",
        "route: generate subjective price paths from a low-dimensional perceived",
        "law, solve temporary equilibrium, update coefficients from realized",
        "model prices, and write coefficient and forecast-error diagnostics each",
        "outer iteration. In parallel, keep Route C as a calibrated robustness",
        "rule and Route A as a measured-expectations baseline once external",
        "expectations moments are added.",
        "",
        "## Limits",
        "",
        "These are smoke checks on available small outputs. They do not by",
        "themselves prove a new structural equilibrium and they do not supply the",
        "missing empirical expectations calibration.",
        "",
    ]
    return "\n".join(lines)


if __name__ == "__main__":
    main()
