#!/usr/bin/env python3
"""Version-0 experiment for endogenous fertility + housing-price feedback.

Purpose:
- Stress-test the convergence intuition in the model-setup note.
- Produce simple diagnostics for price/fertility transitions under different damping choices.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


@dataclass
class Params:
    T: int = 50
    J: int = 8
    fertile_idx: tuple = (2, 3, 4)
    leave_home_lag: int = 2
    surv: tuple = (0.98, 0.995, 0.995, 0.992, 0.99, 0.985, 0.97)

    # fertility block
    f_level: float = 0.22
    f_price_semi_elasticity: float = 0.20
    f_family_supply: float = 0.30

    # politics/supply block
    theta0: float = 0.20
    theta_old: float = 0.90
    theta_young: float = 0.35
    eps0: float = 0.90

    # price adjustment
    d0: float = 0.95
    d_young: float = 1.00
    d_birth: float = 0.30
    s0: float = 1.00
    price_gain: float = 0.35



def simulate(p: Params, damping: float, family_supply_shift: float = 0.0, shock_start: int = 15):
    M = np.zeros((p.T + 1, p.J))
    M[0] = np.array([0.14, 0.13, 0.14, 0.14, 0.13, 0.12, 0.11, 0.09])
    M[0] /= M[0].sum()

    prices = np.zeros(p.T + 1)
    prices[0] = 0.0

    births = np.zeros(p.T)
    fert_rate = np.zeros(p.T)
    theta = np.zeros(p.T)
    young_share = np.zeros(p.T)
    old_share = np.zeros(p.T)

    lagged_births = [0.0] * (p.leave_home_lag + 1)

    for t in range(p.T):
        young_share[t] = M[t, 0] + M[t, 1]
        old_share[t] = M[t, 5] + M[t, 6] + M[t, 7]

        family_supply = family_supply_shift if t >= shock_start else 0.0
        n_home_proxy = sum(lagged_births[:-1])

        # fertility decision: decreases in prices, increases in family-suitable supply
        f_exp_arg = float(np.clip(-p.f_price_semi_elasticity * prices[t], -20.0, 20.0))
        base_f = p.f_level * math.exp(f_exp_arg) * (1.0 + p.f_family_supply * family_supply)
        fert_rate[t] = float(np.clip(base_f, 0.05, 0.85))

        births[t] = fert_rate[t] * M[t, list(p.fertile_idx)].sum()

        # political tightness rises with older cohort share, falls with younger share
        theta[t] = float(np.clip(p.theta0 + p.theta_old * old_share[t] - p.theta_young * young_share[t], 0.0, 0.95))

        demand = p.d0 + p.d_young * young_share[t] + p.d_birth * births[t] + 0.15 * n_home_proxy
        s_exp_arg = float(np.clip(-prices[t], -20.0, 20.0))
        supply = p.s0 + p.eps0 * (1.0 - theta[t]) * math.exp(s_exp_arg)
        desired_price = prices[t] + p.price_gain * (demand - supply)

        prices[t + 1] = (1.0 - damping) * prices[t] + damping * desired_price
        prices[t + 1] = float(np.clip(prices[t + 1], -6.0, 6.0))

        # demographic transition
        M[t + 1, 0] = births[t]
        for j in range(1, p.J):
            M[t + 1, j] = p.surv[j - 1] * M[t, j - 1]

        if M[t + 1].sum() > 0:
            M[t + 1] = M[t + 1] / M[t + 1].sum()

        lagged_births = [births[t]] + lagged_births[:-1]

    out = pd.DataFrame(
        {
            "t": np.arange(p.T),
            "price": prices[:-1],
            "births": births,
            "fertility_rate": fert_rate,
            "young_share": young_share,
            "old_share": old_share,
            "theta": theta,
        }
    )
    return out


def main() -> None:
    p = Params()
    out_dir = Path("projects/03_fertility_and_housing_supply/notes/build")
    out_dir.mkdir(parents=True, exist_ok=True)

    # 1) convergence sensitivity
    no_damp = simulate(p, damping=1.0, family_supply_shift=0.0)
    damped = simulate(p, damping=0.25, family_supply_shift=0.0)

    # 2) policy experiment under stable damping
    policy = simulate(p, damping=0.25, family_supply_shift=0.20)

    no_damp.to_csv(out_dir / "model_experiment_no_damping.csv", index=False)
    damped.to_csv(out_dir / "model_experiment_damped.csv", index=False)
    policy.to_csv(out_dir / "model_experiment_policy.csv", index=False)

    # summary metrics
    summary = pd.DataFrame(
        {
            "scenario": ["no_damping", "damped", "damped_policy"],
            "avg_price_t10_49": [
                no_damp.loc[no_damp.t >= 10, "price"].mean(),
                damped.loc[damped.t >= 10, "price"].mean(),
                policy.loc[policy.t >= 10, "price"].mean(),
            ],
            "avg_fertility_t10_49": [
                no_damp.loc[no_damp.t >= 10, "fertility_rate"].mean(),
                damped.loc[damped.t >= 10, "fertility_rate"].mean(),
                policy.loc[policy.t >= 10, "fertility_rate"].mean(),
            ],
            "avg_births_t10_49": [
                no_damp.loc[no_damp.t >= 10, "births"].mean(),
                damped.loc[damped.t >= 10, "births"].mean(),
                policy.loc[policy.t >= 10, "births"].mean(),
            ],
            "max_abs_price_change": [
                no_damp.price.diff().abs().max(),
                damped.price.diff().abs().max(),
                policy.price.diff().abs().max(),
            ],
        }
    )
    summary.to_csv(out_dir / "model_experiment_summary.csv", index=False)

    # figures
    fig, ax = plt.subplots(1, 2, figsize=(10, 4.3))
    ax[0].plot(no_damp.t, no_damp.price, label="No damping")
    ax[0].plot(damped.t, damped.price, label="Damping 0.25")
    ax[0].set_title("Price Path: Damping Test")
    ax[0].set_xlabel("t")
    ax[0].set_ylabel("log price index")
    ax[0].legend(frameon=False)

    ax[1].plot(damped.t, damped.fertility_rate, label="Baseline")
    ax[1].plot(policy.t, policy.fertility_rate, label="Family-size supply shift")
    ax[1].set_title("Fertility Rate: Policy Experiment")
    ax[1].set_xlabel("t")
    ax[1].set_ylabel("fertility rate")
    ax[1].legend(frameon=False)

    fig.tight_layout()
    fig.savefig(out_dir / "model_experiment_paths.png", dpi=180)


if __name__ == "__main__":
    main()
