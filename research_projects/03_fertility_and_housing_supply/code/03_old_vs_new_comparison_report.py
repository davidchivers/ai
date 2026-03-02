#!/usr/bin/env python3
"""Generate a side-by-side old-vs-new model comparison PDF with graphs."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.backends.backend_pdf import PdfPages

from fertility_extension_experiment import Params, simulate


@dataclass
class ComparisonConfig:
    damping: float = 0.25
    policy_shift: float = 0.20
    policy_start: int = 15


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = PROJECT_ROOT / "notes" / "build"


def simulate_old_model_proxy(p: Params, damping: float, policy_shift: float = 0.0, shock_start: int = 15) -> pd.DataFrame:
    """Legacy proxy: fertility is exogenous and decoupled from housing.

    This proxy emulates the pre-fertility-extension structure:
    - no fertility response to price
    - no family-supply effect on fertility
    - no birth-driven housing demand channel
    """
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

    fertile0 = float(M[0, list(p.fertile_idx)].sum())
    fixed_births = p.f_level * fertile0

    for t in range(p.T):
        young_share[t] = M[t, 0] + M[t, 1]
        old_share[t] = M[t, 5] + M[t, 6] + M[t, 7]

        births[t] = fixed_births
        fert_rate[t] = births[t] / max(float(M[t, list(p.fertile_idx)].sum()), 1e-9)

        theta[t] = float(np.clip(p.theta0 + p.theta_old * old_share[t] - p.theta_young * young_share[t], 0.0, 0.95))

        # Policy shift has no fertility channel in legacy proxy by construction.
        _ = policy_shift if t >= shock_start else 0.0

        demand = p.d0 + p.d_young * young_share[t]
        supply = p.s0 + p.eps0 * (1.0 - theta[t]) * np.exp(np.clip(-prices[t], -20.0, 20.0))
        desired_price = prices[t] + p.price_gain * (demand - supply)

        prices[t + 1] = (1.0 - damping) * prices[t] + damping * desired_price
        prices[t + 1] = float(np.clip(prices[t + 1], -6.0, 6.0))

        M[t + 1, 0] = births[t]
        for j in range(1, p.J):
            M[t + 1, j] = p.surv[j - 1] * M[t, j - 1]

        if M[t + 1].sum() > 0:
            M[t + 1] /= M[t + 1].sum()

    return pd.DataFrame(
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


def summarize(df: pd.DataFrame, label: str) -> dict[str, float | str]:
    return {
        "scenario": label,
        "avg_price_t10_49": float(df.loc[df["t"] >= 10, "price"].mean()),
        "avg_fertility_t10_49": float(df.loc[df["t"] >= 10, "fertility_rate"].mean()),
        "avg_births_t10_49": float(df.loc[df["t"] >= 10, "births"].mean()),
        "final_price": float(df["price"].iloc[-1]),
        "final_fertility": float(df["fertility_rate"].iloc[-1]),
        "max_abs_price_change": float(df["price"].diff().abs().max(skipna=True)),
    }


def write_pdf(report_path: Path, summary: pd.DataFrame, paths: dict[str, pd.DataFrame], cfg: ComparisonConfig) -> None:
    with PdfPages(report_path) as pdf:
        fig = plt.figure(figsize=(11, 8.5))
        fig.suptitle("Fertility model: old vs new side-by-side comparison", fontsize=16, y=0.97)
        ax = fig.add_axes([0.06, 0.08, 0.88, 0.84])
        ax.axis("off")
        utc = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        lines = [
            f"Generated: {utc}",
            "",
            "What is compared:",
            "1) New model (project 03 extension): endogenous fertility responds to prices and family-sized supply.",
            "2) Old-model proxy (project 02 logic): exogenous births, no fertility-price feedback, no birth-demand channel.",
            "",
            "Policy experiment used in both series:",
            f"- family supply shift: +{cfg.policy_shift:.2f}",
            f"- starts at t = {cfg.policy_start}",
            f"- damping = {cfg.damping:.2f}",
            "",
            "Interpretation note:",
            "The old model in project 02 is a large MATLAB codebase and is not runnable here (no MATLAB in environment).",
            "This proxy isolates the conceptual pre-extension mechanism for a clean apples-to-apples comparison.",
        ]
        ax.text(0.0, 1.0, "\n".join(lines), va="top", fontsize=11)
        pdf.savefig(fig)
        plt.close(fig)

        fig, axs = plt.subplots(2, 2, figsize=(11, 8.5))
        fig.suptitle("Dynamic paths: old vs new", fontsize=14)
        new_base = paths["new_baseline"]
        old_base = paths["old_baseline"]
        new_pol = paths["new_policy"]
        old_pol = paths["old_policy"]

        axs[0, 0].plot(new_base["t"], new_base["price"], label="New baseline")
        axs[0, 0].plot(old_base["t"], old_base["price"], label="Old baseline proxy")
        axs[0, 0].set_title("Price path (baseline)")
        axs[0, 0].set_xlabel("t")
        axs[0, 0].set_ylabel("log price index")
        axs[0, 0].legend(frameon=False)

        axs[0, 1].plot(new_base["t"], new_base["fertility_rate"], label="New baseline")
        axs[0, 1].plot(old_base["t"], old_base["fertility_rate"], label="Old baseline proxy")
        axs[0, 1].set_title("Fertility rate (baseline)")
        axs[0, 1].set_xlabel("t")
        axs[0, 1].set_ylabel("fertility rate")
        axs[0, 1].legend(frameon=False)

        axs[1, 0].plot(new_pol["t"], new_pol["price"], label="New policy")
        axs[1, 0].plot(old_pol["t"], old_pol["price"], label="Old policy proxy")
        axs[1, 0].set_title("Price path (policy)")
        axs[1, 0].set_xlabel("t")
        axs[1, 0].set_ylabel("log price index")
        axs[1, 0].legend(frameon=False)

        axs[1, 1].plot(new_pol["t"], new_pol["fertility_rate"], label="New policy")
        axs[1, 1].plot(old_pol["t"], old_pol["fertility_rate"], label="Old policy proxy")
        axs[1, 1].set_title("Fertility rate (policy)")
        axs[1, 1].set_xlabel("t")
        axs[1, 1].set_ylabel("fertility rate")
        axs[1, 1].legend(frameon=False)

        fig.tight_layout(rect=[0, 0, 1, 0.95])
        pdf.savefig(fig)
        plt.close(fig)

        fig, axs = plt.subplots(1, 2, figsize=(11, 8.5))
        fig.suptitle("Policy effect by model (policy minus baseline)", fontsize=14)

        new_delta_f = new_pol["fertility_rate"] - new_base["fertility_rate"]
        old_delta_f = old_pol["fertility_rate"] - old_base["fertility_rate"]
        axs[0].plot(new_base["t"], new_delta_f, label="New model")
        axs[0].plot(old_base["t"], old_delta_f, label="Old proxy")
        axs[0].axhline(0.0, color="black", linewidth=0.8)
        axs[0].set_title("Delta fertility rate")
        axs[0].set_xlabel("t")
        axs[0].set_ylabel("policy effect")
        axs[0].legend(frameon=False)

        new_delta_p = new_pol["price"] - new_base["price"]
        old_delta_p = old_pol["price"] - old_base["price"]
        axs[1].plot(new_base["t"], new_delta_p, label="New model")
        axs[1].plot(old_base["t"], old_delta_p, label="Old proxy")
        axs[1].axhline(0.0, color="black", linewidth=0.8)
        axs[1].set_title("Delta price")
        axs[1].set_xlabel("t")
        axs[1].set_ylabel("policy effect")
        axs[1].legend(frameon=False)

        fig.tight_layout(rect=[0, 0, 1, 0.95])
        pdf.savefig(fig)
        plt.close(fig)

        fig = plt.figure(figsize=(11, 8.5))
        fig.suptitle("Summary metrics and explanation", fontsize=14, y=0.97)
        ax1 = fig.add_axes([0.05, 0.48, 0.90, 0.42])
        ax1.axis("off")
        tbl = summary.copy()
        for c in tbl.columns:
            if c != "scenario":
                tbl[c] = tbl[c].map(lambda x: f"{x:.4f}")
        table = ax1.table(
            cellText=tbl.values,
            colLabels=tbl.columns,
            cellLoc="center",
            loc="center",
        )
        table.auto_set_font_size(False)
        table.set_fontsize(9)
        table.scale(1, 1.4)

        ax2 = fig.add_axes([0.05, 0.07, 0.90, 0.34])
        ax2.axis("off")
        explanation = [
            "Why this happened:",
            "1) In the new model, lower prices increase fertility and births, adding household-size demand feedback.",
            "2) The extra births feed back into demand, so the dynamics differ from the old model baseline.",
            "3) In the old proxy, fertility is fixed exogenously, so policy shifts targeted at family-sized supply",
            "   do not propagate through a fertility channel by construction.",
            "4) Both models can still show falling prices when supply is relatively elastic versus demand pressure,",
            "   but only the new model converts that into a strong fertility response.",
        ]
        ax2.text(0, 1, "\n".join(explanation), va="top", fontsize=11)
        pdf.savefig(fig)
        plt.close(fig)


def main() -> None:
    cfg = ComparisonConfig()
    p = Params()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    new_baseline = simulate(p, damping=cfg.damping, family_supply_shift=0.0, shock_start=cfg.policy_start)
    new_policy = simulate(p, damping=cfg.damping, family_supply_shift=cfg.policy_shift, shock_start=cfg.policy_start)

    old_baseline = simulate_old_model_proxy(p, damping=cfg.damping, policy_shift=0.0, shock_start=cfg.policy_start)
    old_policy = simulate_old_model_proxy(p, damping=cfg.damping, policy_shift=cfg.policy_shift, shock_start=cfg.policy_start)

    out_paths = {
        "new_baseline": new_baseline,
        "new_policy": new_policy,
        "old_baseline": old_baseline,
        "old_policy": old_policy,
    }

    for key, df in out_paths.items():
        df.to_csv(OUT_DIR / f"comparison_{key}.csv", index=False)

    summary = pd.DataFrame(
        [
            summarize(new_baseline, "new_baseline"),
            summarize(old_baseline, "old_baseline_proxy"),
            summarize(new_policy, "new_policy"),
            summarize(old_policy, "old_policy_proxy"),
        ]
    )
    summary.to_csv(OUT_DIR / "comparison_summary_old_vs_new.csv", index=False)

    report_pdf = OUT_DIR / "old_vs_new_model_comparison_report.pdf"
    write_pdf(report_pdf, summary, out_paths, cfg)


if __name__ == "__main__":
    main()
