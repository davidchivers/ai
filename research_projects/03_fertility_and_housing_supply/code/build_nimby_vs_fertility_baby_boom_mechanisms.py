from __future__ import annotations

from dataclasses import replace
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from nimby_fertility_transition_bridge import BridgeParams, age_homeownership_proxy, simulate_baby_boom


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

BOOM_AMP = 0.10
BOOM_START = 0
BOOM_END = 9
POST_START = 40
SUPPORT_TIMES = (5, 20, 50)

VARIANTS = [
    {
        "key": "nimby_proxy",
        "label": "NIMBY proxy",
        "color": "#111111",
        "mode": "old_proxy",
        "params": lambda p: p,
        "family_penalty": False,
    },
    {
        "key": "full_fertility",
        "label": "Full fertility",
        "color": "#b24c2a",
        "mode": "fertility",
        "params": lambda p: p,
        "family_penalty": True,
    },
    {
        "key": "no_crowding",
        "label": "No crowding",
        "color": "#275d8c",
        "mode": "fertility",
        "params": lambda p: replace(p, n_home_demand=0.0, lambda_crowd=0.0),
        "family_penalty": False,
    },
    {
        "key": "no_price_births",
        "label": "No price-sensitive births",
        "color": "#2d7f5e",
        "mode": "fertility",
        "params": lambda p: replace(p, f_price_semi_elasticity=0.0),
        "family_penalty": True,
    },
]


def set_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "serif",
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.titleweight": "bold",
            "axes.titlesize": 10.5,
            "axes.labelsize": 9.5,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "legend.fontsize": 8.5,
        }
    )


def load_upstream_nimby() -> pd.DataFrame:
    nimby = pd.read_csv(BUILD / "nimby_baby_boom_reference_full.csv").replace([np.inf, -np.inf], np.nan)
    nimby["house_price_dev"] = nimby["house_price_index"] / float(nimby["house_price_index"].iloc[0]) - 1.0
    nimby["birthrate_dev"] = nimby["birthrate_index"] - 1.0
    return nimby


def build_variant_frame(base: pd.DataFrame, shock: pd.DataFrame, key: str, label: str) -> pd.DataFrame:
    out = shock.copy()
    base_price_index = np.exp(base["price"] - float(base["price"].iloc[0]))
    shock_price_index = np.exp(shock["price"] - float(shock["price"].iloc[0]))
    out["variant"] = key
    out["label"] = label
    out["birthrate_index"] = shock["births"] / base["births"]
    out["birthrate_dev"] = out["birthrate_index"] - 1.0
    out["house_price_index"] = shock_price_index
    out["house_price_dev"] = shock_price_index - base_price_index
    out["fertility_rate_dev"] = shock["fertility_rate"] - base["fertility_rate"]
    out["n_home_dev"] = shock["n_home"] - base["n_home"]
    out["average_age_dev"] = shock["average_age"] - base["average_age"]
    out["young_homeownership_proxy_dev"] = shock["young_homeownership_proxy"] - base["young_homeownership_proxy"]
    out["old_homeownership_proxy_dev"] = shock["old_homeownership_proxy"] - base["old_homeownership_proxy"]
    return out


def support_proxy(params: BridgeParams, age: float, price_gap: float, n_home: float, family_penalty: bool) -> float:
    ownership = age_homeownership_proxy(params, age, price_gap)
    if not np.isfinite(ownership):
        return np.nan
    owner_component = 2.0 * ownership - 1.0
    if not family_penalty:
        return float(np.clip(owner_component, -1.0, 1.0))
    family_exposure = float(
        np.interp(age, np.asarray(params.age_grid, dtype=float), np.asarray(params.family_age_exposure, dtype=float))
    )
    scaled_n_home = n_home / max(params.f_level, 1e-9)
    penalty = 0.35 * family_exposure * scaled_n_home
    return float(np.clip(owner_component - penalty, -1.5, 1.5))


def build_support_proxy_table(
    base_by_variant: dict[str, pd.DataFrame],
    shock_by_variant: dict[str, pd.DataFrame],
    params_by_variant: dict[str, BridgeParams],
) -> pd.DataFrame:
    rows: list[dict[str, float | int | str]] = []
    ages = np.asarray(BridgeParams().age_grid, dtype=float)
    for spec in VARIANTS:
        key = str(spec["key"])
        params = params_by_variant[key]
        family_penalty = bool(spec["family_penalty"])
        base = base_by_variant[key]
        shock = shock_by_variant[key]
        for t in SUPPORT_TIMES:
            base_price_gap = float(base.loc[base["t"] == t, "price"].iloc[0] - base["price"].iloc[0])
            shock_price_gap = float(shock.loc[shock["t"] == t, "price"].iloc[0] - shock["price"].iloc[0])
            base_n_home = float(base.loc[base["t"] == t, "n_home"].iloc[0])
            shock_n_home = float(shock.loc[shock["t"] == t, "n_home"].iloc[0])
            for age in ages:
                base_support = support_proxy(params, float(age), base_price_gap, base_n_home, family_penalty)
                shock_support = support_proxy(params, float(age), shock_price_gap, shock_n_home, family_penalty)
                rows.append(
                    {
                        "variant": key,
                        "label": str(spec["label"]),
                        "t": int(t),
                        "age": float(age),
                        "baseline_support_proxy": base_support,
                        "shock_support_proxy": shock_support,
                        "support_proxy_dev": shock_support - base_support,
                    }
                )
    return pd.DataFrame(rows)


def build_summary_table(variants: pd.DataFrame, support: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, float | str]] = []
    for spec in VARIANTS:
        key = str(spec["key"])
        group = variants[variants["variant"] == key]
        support_mid = support[(support["variant"] == key) & (support["t"] == 20) & (support["age"] == 35.0)]
        support_late = support[(support["variant"] == key) & (support["t"] == 50) & (support["age"] == 35.0)]
        rows.append(
            {
                "variant": key,
                "label": str(spec["label"]),
                "post_price_response": float(group.loc[group["t"] >= POST_START, "house_price_dev"].mean()),
                "peak_price_response": float(group["house_price_dev"].max()),
                "boom_fertility_response": float(group.loc[(group["t"] >= BOOM_START) & (group["t"] <= BOOM_END), "fertility_rate_dev"].mean()),
                "post_fertility_response": float(group.loc[group["t"] >= POST_START, "fertility_rate_dev"].mean()),
                "peak_children_at_home_response": float(group["n_home_dev"].max()),
                "young_homeownership_trough": float(group["young_homeownership_proxy_dev"].min()),
                "shock_support_age35_t20": float(support_mid["shock_support_proxy"].iloc[0]),
                "shock_support_age35_t50": float(support_late["shock_support_proxy"].iloc[0]),
            }
        )
    return pd.DataFrame(rows)


def write_note(summary: pd.DataFrame) -> None:
    full = summary[summary["variant"] == "full_fertility"].iloc[0]
    no_crowding = summary[summary["variant"] == "no_crowding"].iloc[0]
    no_price = summary[summary["variant"] == "no_price_births"].iloc[0]
    nimby = summary[summary["variant"] == "nimby_proxy"].iloc[0]

    lines = [
        "# Baby-boom mechanism decomposition",
        "",
        "This note treats the baby-boom experiment as a stress test of the family-housing-demand channel.",
        "It adds three new objects to the current NIMBY-versus-fertility transition pack:",
        "- a mechanism chain from the common boom shock to children at home, house prices, and later fertility",
        "- a channel shutoff comparison inside the fertility bridge",
        "- an age-support proxy that highlights the family-years shift away from NIMBYism",
        "",
        "## Channel read",
        "",
        f"- NIMBY proxy post-window price response: `{nimby['post_price_response']:.3f}`",
        f"- Full fertility post-window price response: `{full['post_price_response']:.3f}`",
        f"- No crowding post-window price response: `{no_crowding['post_price_response']:.3f}`",
        f"- No price-sensitive births post-window price response: `{no_price['post_price_response']:.3f}`",
        "",
        "## Interpretation",
        "",
        f"- Shutting off crowding pulls the post-window price response down from `{full['post_price_response']:.3f}` to `{no_crowding['post_price_response']:.3f}`.",
        f"- Shutting off price-sensitive births leaves a large price response (`{no_price['post_price_response']:.3f}`) but weakens the later fertility correction from `{full['post_fertility_response']:.4f}` to `{no_price['post_fertility_response']:.4f}`.",
        f"- At age 35 and t=20, the support proxy for higher prices is `{full['shock_support_age35_t20']:.3f}` in the full model, versus `{no_crowding['shock_support_age35_t20']:.3f}` with crowding shut off and `{nimby['shock_support_age35_t20']:.3f}` in the NIMBY proxy.",
        "",
        "## Read",
        "",
        "- The baby boom is useful because it makes the family-demand channel visible.",
        "- The extra price amplification comes mainly from children-at-home crowding, not just from a different birth rule.",
        "- The family years become less supportive of higher house prices, and that shift fades later in life as children leave home.",
        "",
    ]
    (BUILD / "nimby_vs_fertility_baby_boom_mechanisms.md").write_text("\n".join(lines), encoding="utf-8")


def plot_mechanism_chain(nimby: pd.DataFrame, variants: pd.DataFrame) -> None:
    full = variants[variants["variant"] == "full_fertility"]
    nimby_proxy = variants[variants["variant"] == "nimby_proxy"]
    c_nimby = "#111111"
    c_full = "#b24c2a"
    c_blue = "#275d8c"
    c_gray = "#666666"

    fig, axes = plt.subplots(2, 2, figsize=(11.8, 8.0), constrained_layout=True)
    shock_line = np.where((full["t"] >= BOOM_START) & (full["t"] <= BOOM_END), 1.0 + BOOM_AMP, 1.0)

    ax = axes[0, 0]
    ax.plot(full["t"], shock_line, color=c_gray, lw=2.3)
    ax.set_title("A. Common imposed baby-boom shock")
    ax.set_xlabel("Time")
    ax.set_ylabel("Birth multiplier")

    ax = axes[0, 1]
    ax.plot(full["t"], full["n_home_dev"], color=c_blue, lw=2.3)
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.set_title("B. Children-at-home response")
    ax.set_xlabel("Time")
    ax.set_ylabel("Shock minus baseline")

    ax = axes[1, 0]
    ax.plot(nimby["t"], nimby["house_price_dev"], color=c_nimby, lw=2.2, label="NIMBY")
    ax.plot(full["t"], full["house_price_dev"], color=c_full, lw=2.2, label="Fertility extension")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.set_title("C. House-price response")
    ax.set_xlabel("Time")
    ax.set_ylabel("Deviation from baseline")
    ax.legend(frameon=False, loc="best")

    ax = axes[1, 1]
    ax.plot(nimby_proxy["t"], nimby_proxy["fertility_rate_dev"], color=c_nimby, lw=2.2, label="NIMBY proxy")
    ax.plot(full["t"], full["fertility_rate_dev"], color=c_full, lw=2.2, label="Fertility extension")
    ax.axhline(0, color=c_gray, lw=1.0, ls="--")
    ax.set_title("D. Fertility-rate response")
    ax.set_xlabel("Time")
    ax.set_ylabel("Shock minus baseline")
    ax.legend(frameon=False, loc="best")

    fig.suptitle("Baby boom as a family-demand mechanism", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_vs_fertility_baby_boom_mechanism.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_baby_boom_mechanism.pdf", bbox_inches="tight")
    plt.close(fig)


def plot_channel_decomposition(variants: pd.DataFrame, summary: pd.DataFrame) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(12.2, 8.1), constrained_layout=True)
    c_gray = "#666666"

    for spec in VARIANTS:
        group = variants[variants["variant"] == spec["key"]]
        axes[0, 0].plot(group["t"], group["house_price_dev"], lw=2.0, color=spec["color"], label=spec["label"])
        axes[0, 1].plot(group["t"], group["fertility_rate_dev"], lw=2.0, color=spec["color"], label=spec["label"])
        axes[1, 0].plot(group["t"], group["n_home_dev"], lw=2.0, color=spec["color"], label=spec["label"])

    axes[0, 0].axhline(0, color=c_gray, lw=1.0, ls="--")
    axes[0, 0].set_title("A. House-price response by channel")
    axes[0, 0].set_xlabel("Time")
    axes[0, 0].set_ylabel("Deviation from baseline")
    axes[0, 0].legend(frameon=False, loc="best")

    axes[0, 1].axhline(0, color=c_gray, lw=1.0, ls="--")
    axes[0, 1].set_title("B. Fertility-rate response by channel")
    axes[0, 1].set_xlabel("Time")
    axes[0, 1].set_ylabel("Shock minus baseline")
    axes[0, 1].legend(frameon=False, loc="best")

    axes[1, 0].axhline(0, color=c_gray, lw=1.0, ls="--")
    axes[1, 0].set_title("C. Children-at-home response by channel")
    axes[1, 0].set_xlabel("Time")
    axes[1, 0].set_ylabel("Shock minus baseline")
    axes[1, 0].legend(frameon=False, loc="best")

    order = summary["label"].tolist()
    x = np.arange(len(order))
    axes[1, 1].bar(x, summary["post_price_response"], color=[spec["color"] for spec in VARIANTS])
    axes[1, 1].set_xticks(x, order, rotation=15)
    axes[1, 1].set_title("D. Average post-window price response")
    axes[1, 1].set_ylabel("Mean deviation, t >= 40")

    fig.suptitle("Baby-boom channel decomposition", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_vs_fertility_baby_boom_channels.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_baby_boom_channels.pdf", bbox_inches="tight")
    plt.close(fig)


def plot_age_support_proxy(support: pd.DataFrame) -> None:
    fig, axes = plt.subplots(1, len(SUPPORT_TIMES), figsize=(13.0, 3.9), constrained_layout=True)
    c_gray = "#666666"

    for ax, t in zip(axes, SUPPORT_TIMES):
        group = support[support["t"] == t]
        for spec in VARIANTS:
            panel = group[group["variant"] == spec["key"]]
            ax.plot(panel["age"], panel["shock_support_proxy"], lw=2.1, color=spec["color"], label=spec["label"])
        ax.axhline(0, color=c_gray, lw=1.0, ls="--")
        ax.set_title(f"{chr(64 + list(SUPPORT_TIMES).index(t) + 1)}. Support proxy at t = {t}")
        ax.set_xlabel("Age")
        ax.set_ylabel("Support for higher prices")
        ax.legend(frameon=False, loc="best")

    fig.suptitle("Age-support proxy for higher house prices", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "nimby_vs_fertility_age_support_proxy.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "nimby_vs_fertility_age_support_proxy.pdf", bbox_inches="tight")
    plt.close(fig)


def main() -> None:
    set_style()
    base_params = BridgeParams()
    nimby = load_upstream_nimby()

    base_by_variant: dict[str, pd.DataFrame] = {}
    shock_by_variant: dict[str, pd.DataFrame] = {}
    params_by_variant: dict[str, BridgeParams] = {}
    variant_frames: list[pd.DataFrame] = []

    for spec in VARIANTS:
        key = str(spec["key"])
        params = spec["params"](base_params)
        params_by_variant[key] = params
        base = simulate_baby_boom(params, spec["mode"], damping=0.25, boom_amp=0.0, boom_start=BOOM_START, boom_end=BOOM_END)
        shock = simulate_baby_boom(params, spec["mode"], damping=0.25, boom_amp=BOOM_AMP, boom_start=BOOM_START, boom_end=BOOM_END)
        base_by_variant[key] = base
        shock_by_variant[key] = shock
        variant_frames.append(build_variant_frame(base, shock, key, str(spec["label"])))

    variants = pd.concat(variant_frames, ignore_index=True)
    support = build_support_proxy_table(base_by_variant, shock_by_variant, params_by_variant)
    summary = build_summary_table(variants, support)

    variants.to_csv(BUILD / "nimby_vs_fertility_baby_boom_channel_variants.csv", index=False)
    support.to_csv(BUILD / "nimby_vs_fertility_age_support_proxy.csv", index=False)
    summary.to_csv(BUILD / "nimby_vs_fertility_baby_boom_mechanism_summary.csv", index=False)

    write_note(summary)
    plot_mechanism_chain(nimby, variants)
    plot_channel_decomposition(variants, summary)
    plot_age_support_proxy(support)


if __name__ == "__main__":
    main()
