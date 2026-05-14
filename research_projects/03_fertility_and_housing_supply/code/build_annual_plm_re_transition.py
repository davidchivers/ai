from __future__ import annotations

from dataclasses import dataclass
from math import exp, log
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import (
    INPUT_SUMMARY,
    STATE_ORDER,
    Scenario,
    adjust_matrix,
    build_base_transition_matrices,
    load_initial_cross_section,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_plm_re_transition"
TERMINAL_DRIFT = 1.05
PRICE_BOX = (0.60, 1.40)
T = 21
MAX_ITER = 200
TOL = 1.0e-8


@dataclass(frozen=True)
class PLMScenario:
    name: str
    deposit_help_weight: float
    qualification_weight: float
    re_weight: float
    targeted_support: bool = True
    support_center: float = 0.18
    support_width: float = 0.04
    mid_age_scale: float = 0.80


def summary_to_pop(summary: pd.DataFrame) -> np.ndarray:
    block_masses = summary["block_mass"].to_numpy(dtype=float)
    return summary.loc[:, STATE_ORDER].to_numpy(dtype=float) * block_masses[:, None]


def pop_to_summary(pop: np.ndarray, template: pd.DataFrame) -> pd.DataFrame:
    block_masses = template["block_mass"].to_numpy(dtype=float)
    shares = pop / block_masses[:, None]
    out = template.loc[:, ["age_block", "age_lo", "age_hi", "block_mass"]].copy()
    for i, state in enumerate(STATE_ORDER):
        out[state] = shares[:, i]
    return out


def housing_pressure_from_summary(summary: pd.DataFrame) -> float:
    row_25 = summary.loc[summary["age_block"] == "25-34"].iloc[0]
    row_35 = summary.loc[summary["age_block"] == "35-44"].iloc[0]
    young_mortgaged = float(row_25["owner_with_mortgage"])
    young_renter_debt = float(row_25["renter_with_debt"])
    owner_35_44 = float(row_35["owner_with_mortgage"] + row_35["owner_outright"])
    return young_mortgaged + young_renter_debt + 0.5 * (1.0 - owner_35_44)


def transition_one_period(summary: pd.DataFrame, scenario: PLMScenario, price_ratio: float, t: int) -> pd.DataFrame:
    base_matrices = build_base_transition_matrices()
    age_blocks = list(summary["age_block"])
    widths = (summary["age_hi"] - summary["age_lo"] + 1).to_numpy(dtype=float)
    block_masses = summary["block_mass"].to_numpy(dtype=float)
    pop = summary_to_pop(summary)
    entrant_mix = summary.loc[
        summary["age_block"] == "25-34", STATE_ORDER
    ].iloc[0].to_numpy(dtype=float)

    post = np.zeros_like(pop)
    for i, age_block in enumerate(age_blocks):
        matrix = adjust_matrix(
            base_matrices[age_block],
            age_block=age_block,
            price_ratio=price_ratio,
            deposit_help_weight=scenario.deposit_help_weight,
            qualification_weight=scenario.qualification_weight,
            deposit_help_horizon=0,
            qualification_horizon=0,
            targeted_support=scenario.targeted_support,
            support_center=scenario.support_center,
            support_width=scenario.support_width,
            mid_age_scale=scenario.mid_age_scale,
            t=t,
        )
        post[i, :] = pop[i, :] @ matrix

    new_pop = np.zeros_like(pop)
    outflows = np.zeros_like(pop)
    for i in range(len(age_blocks)):
        outflows[i, :] = post[i, :] / widths[i]
        new_pop[i, :] += post[i, :] - outflows[i, :]
    for i in range(1, len(age_blocks)):
        new_pop[i, :] += outflows[i - 1, :]

    entrant_mass = float(outflows[-1, :].sum())
    new_pop[0, :] += entrant_mass * entrant_mix
    return pop_to_summary(new_pop, summary)


def solve_one_step_re_from_state(
    summary: pd.DataFrame,
    scenario: PLMScenario,
    slope: float,
    pressure_anchor: float,
    min_q: float,
    max_q: float,
) -> float:
    q = TERMINAL_DRIFT
    for _ in range(300):
        next_summary = transition_one_period(summary, scenario, q, t=0)
        pressure = housing_pressure_from_summary(next_summary)
        implied_q = exp(log(TERMINAL_DRIFT) + scenario.re_weight * slope * (pressure - pressure_anchor))
        updated_q = 0.5 * q + 0.5 * implied_q
        if not np.isfinite(updated_q):
            return float("nan")
        if abs(updated_q - q) < 1.0e-10:
            q = updated_q
            break
        q = updated_q
    if q < min_q or q > max_q:
        return q
    return q


def build_anchor_slope(summary: pd.DataFrame) -> tuple[float, float, float]:
    baseline = PLMScenario("baseline", 0.0, 0.0, re_weight=0.25)
    no_shock_next = transition_one_period(summary, baseline, 1.0, t=0)
    drift_next = transition_one_period(summary, baseline, TERMINAL_DRIFT, t=0)
    pressure_no = housing_pressure_from_summary(no_shock_next)
    pressure_drift = housing_pressure_from_summary(drift_next)
    slope = log(TERMINAL_DRIFT) / (pressure_drift - pressure_no)
    return pressure_no, pressure_drift, slope


def fit_plm_coefficients(
    pressure: np.ndarray,
    log_q_prev: np.ndarray,
    log_q_target: np.ndarray,
) -> np.ndarray:
    X = np.column_stack(
        [
            np.ones(len(pressure), dtype=float),
            pressure,
            log_q_prev,
        ]
    )
    beta, *_ = np.linalg.lstsq(X, log_q_target, rcond=None)
    return beta


def run_plm_iteration(
    summary0: pd.DataFrame,
    scenario: PLMScenario,
    slope: float,
    pressure_anchor: float,
    coeffs: np.ndarray,
    min_q: float,
    max_q: float,
    horizon: int,
) -> tuple[pd.DataFrame, np.ndarray]:
    rows: list[dict[str, float | int | str]] = []
    summary = summary0.copy()
    q_prev = 1.0
    for t in range(horizon):
        pressure_t = housing_pressure_from_summary(summary)
        log_q_hat = float(coeffs[0] + coeffs[1] * pressure_t + coeffs[2] * log(q_prev))
        q_hat = float(np.clip(exp(log_q_hat), min_q, max_q))
        q_star = solve_one_step_re_from_state(
            summary,
            scenario,
            slope=slope,
            pressure_anchor=pressure_anchor,
            min_q=min_q,
            max_q=max_q,
        )
        next_summary = transition_one_period(summary, scenario, q_hat, t=t)

        row_25 = next_summary.loc[next_summary["age_block"] == "25-34"].iloc[0]
        row_35 = next_summary.loc[next_summary["age_block"] == "35-44"].iloc[0]
        rows.append(
            {
                "t": t,
                "pressure_t": pressure_t,
                "q_prev": q_prev,
                "q_hat": q_hat,
                "q_star": q_star,
                "young_owner_share_25_34": float(
                    row_25["owner_with_mortgage"] + row_25["owner_outright"]
                ),
                "young_mortgaged_owner_share_25_34": float(row_25["owner_with_mortgage"]),
                "owner_share_35_44": float(
                    row_35["owner_with_mortgage"] + row_35["owner_outright"]
                ),
            }
        )
        summary = next_summary
        q_prev = q_hat

    frame = pd.DataFrame.from_records(rows)
    beta_new = fit_plm_coefficients(
        pressure=frame["pressure_t"].to_numpy(dtype=float),
        log_q_prev=np.log(frame["q_prev"].to_numpy(dtype=float)),
        log_q_target=np.log(np.clip(frame["q_star"].to_numpy(dtype=float), 1.0e-12, None)),
    )
    return frame, beta_new


def solve_plm(
    summary0: pd.DataFrame,
    scenario: PLMScenario,
    slope: float,
    pressure_anchor: float,
    min_q: float,
    max_q: float,
    horizon: int,
) -> tuple[dict[str, float | int | str], pd.DataFrame]:
    coeffs = np.array([log(TERMINAL_DRIFT) - scenario.re_weight * slope * pressure_anchor, scenario.re_weight * slope, 0.0], dtype=float)
    final_frame = pd.DataFrame()
    status = "max_iter"
    distance = float("nan")
    for iteration in range(1, MAX_ITER + 1):
        frame, beta_new = run_plm_iteration(
            summary0=summary0,
            scenario=scenario,
            slope=slope,
            pressure_anchor=pressure_anchor,
            coeffs=coeffs,
            min_q=min_q,
            max_q=max_q,
            horizon=horizon,
        )
        distance = float(np.max(np.abs(beta_new - coeffs)))
        coeffs = 0.5 * coeffs + 0.5 * beta_new
        final_frame = frame
        if not np.all(np.isfinite(coeffs)):
            status = "non_finite"
            break
        if distance < TOL:
            status = "converged"
            break

    q_min = float(final_frame["q_hat"].min())
    q_max = float(final_frame["q_hat"].max())
    rmse = float(
        np.sqrt(np.mean((np.log(final_frame["q_hat"]) - np.log(final_frame["q_star"])) ** 2))
    )
    result = {
        "scenario": scenario.name,
        "re_weight": scenario.re_weight,
        "status": status,
        "iterations": iteration,
        "coef_const": float(coeffs[0]),
        "coef_pressure": float(coeffs[1]),
        "coef_log_q_prev": float(coeffs[2]),
        "coef_distance": distance,
        "rmse_log_q": rmse,
        "q_min": q_min,
        "q_max": q_max,
        "q1_hat": float(final_frame.loc[final_frame["t"] == 0, "q_hat"].iloc[0]),
        "q1_star": float(final_frame.loc[final_frame["t"] == 0, "q_star"].iloc[0]),
        "young_mortgage_t1": float(
            final_frame.loc[final_frame["t"] == 0, "young_mortgaged_owner_share_25_34"].iloc[0]
        ),
        "young_mortgage_t5": float(
            final_frame.loc[final_frame["t"] == 5, "young_mortgaged_owner_share_25_34"].iloc[0]
        ),
        "young_mortgage_t20": float(
            final_frame.loc[final_frame["t"] == 20, "young_mortgaged_owner_share_25_34"].iloc[0]
        ),
    }
    final_frame.insert(0, "scenario", scenario.name)
    final_frame.insert(1, "re_weight", scenario.re_weight)
    final_frame.insert(2, "status", status)
    return result, final_frame


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    summary0 = load_initial_cross_section(INPUT_SUMMARY)
    _, pressure_anchor, slope = build_anchor_slope(summary0)

    scenarios = [
        PLMScenario("benchmark_plm_re_025", 0.15, 0.25, 0.25),
        PLMScenario("benchmark_plm_re_050", 0.15, 0.25, 0.50),
        PLMScenario("robustness_plm_re_025", 0.30, 0.40, 0.25),
        PLMScenario("robustness_plm_re_050", 0.30, 0.40, 0.50),
    ]

    results_rows: list[dict[str, float | int | str]] = []
    path_frames: list[pd.DataFrame] = []
    for scenario in scenarios:
        result, frame = solve_plm(
            summary0=summary0,
            scenario=scenario,
            slope=slope,
            pressure_anchor=pressure_anchor,
            min_q=PRICE_BOX[0],
            max_q=PRICE_BOX[1],
            horizon=T,
        )
        results_rows.append(result)
        path_frames.append(frame.loc[frame["t"].isin((0, 1, 2, 5, 10, 20))].copy())

    results = pd.DataFrame.from_records(results_rows)
    paths = pd.concat(path_frames, ignore_index=True)
    results.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    paths.to_csv(BUILD / f"{OUTPUT_STEM}_paths.csv", index=False)

    lines = [
        "# Annual PLM RE transition",
        "",
        "This note is the next rung after one-step and k-step bounded RE.",
        "Instead of forecasting a raw future price path directly, agents use a perceived law of motion for the next-period price ratio:",
        "",
        "`log q_(t+1) = a + b * pressure_t + c * log q_t`",
        "",
        "The coefficients are updated until the forecast law is consistent with the reduced-form one-step market-clearing price mapping along the simulated annual transition path.",
        "",
        "## Setup",
        "",
        f"- terminal drift anchor entering the one-step market-clearing map: `{TERMINAL_DRIFT:.3f}`",
        f"- admissible price box during PLM iteration: `[{PRICE_BOX[0]:.2f}, {PRICE_BOX[1]:.2f}]`",
        "- cases:",
        "  - `benchmark`: qualification `0.25`, family help `0.15`",
        "  - `robustness`: qualification `0.40`, family help `0.30`",
        "  - each at RE weights `0.25` and `0.50`",
        "",
        "## Coefficient results",
        "",
        "| Scenario | RE weight | Status | Iterations | a | b (pressure) | c (lagged log q) | RMSE log q | q1 hat | q1 star |",
        "|---|---:|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in results.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.re_weight:.2f}` | `{row.status}` | `{int(row.iterations)}` | "
            f"`{row.coef_const:.3f}` | `{row.coef_pressure:.3f}` | `{row.coef_log_q_prev:.3f}` | "
            f"`{row.rmse_log_q:.4f}` | `{row.q1_hat:.3f}` | `{row.q1_star:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints",
            "",
            "| Scenario | t | q hat | q star | Young mortgaged-owner 25-34 | Young owner 25-34 | Owner 35-44 |",
            "|---|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in paths.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {int(row.t)} | `{row.q_hat:.3f}` | `{row.q_star:.3f}` | "
            f"`{row.young_mortgaged_owner_share_25_34:.3f}` | `{row.young_owner_share_25_34:.3f}` | `{row.owner_share_35_44:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the first RE layer in this project that forecasts prices through a low-dimensional state rather than directly solving a raw finite path of `q` values.",
            "- If the PLM converges with small forecast errors, that means the bounded annual RE object is robust to switching from raw-path expectations to a state-law expectation.",
            "- If it does not converge, then the next RE step should stay with explicit `k-step` prices rather than moving further toward a Krusell-Smith style law.",
        ]
    )

    (BUILD / f"{OUTPUT_STEM}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
