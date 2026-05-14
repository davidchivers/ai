from __future__ import annotations

from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
CDC_REVIEW_PATH = ROOT / "notes" / "build" / "cdc_first_birth_timing_target_review_target_ranking.csv"
CDC_SHAPE_PATH = ROOT / "notes" / "build" / "cdc_first_birth_timing_target_review_25plus_target_comparison.csv"
CHILDLESS_PATH = ROOT / "notes" / "build" / "childlessness_recalibration.csv"
TFR_PATH = ROOT / "data" / "raw" / "international" / "world_bank_tfr_global.csv"
ANNUAL_SWEEP_PATH = ROOT / "notes" / "build" / "fertility_price_sweep_annual.csv"

OUT_CSV = ROOT / "notes" / "build" / "annual_fertility_target_ranges.csv"
OUT_MD = ROOT / "notes" / "build" / "annual_fertility_target_ranges.md"


def build_target_table() -> pd.DataFrame:
    review = pd.read_csv(CDC_REVIEW_PATH)
    shape = pd.read_csv(CDC_SHAPE_PATH)
    childless = pd.read_csv(CHILDLESS_PATH)
    tfr = pd.read_csv(TFR_PATH)

    mean_age_ref = float(review.loc[review["object"] == "mean_age_first_birth", "recent_mean"].iloc[0])
    share30_ref = float(review.loc[review["object"] == "share_first_birth_30_plus", "recent_mean"].iloc[0])

    tfr_recent = tfr.loc[(tfr["country_code"] == "US") & (tfr["year"].between(2020, 2023)), "total_fertility_rate"]
    tfr_ref = float(tfr_recent.mean())

    phi_window = childless.loc[childless["phi_0"].between(1.25, 1.85)]
    childless_ref = 0.165
    childless_recal_low = float(phi_window["parity0_at_50"].min())
    childless_recal_high = float(phi_window["parity0_at_50"].max())

    rows = [
        {
            "object": "mean_age_first_birth",
            "role": "primary",
            "unit": "years",
            "reference_window": "CDC pooled 2020-2024",
            "reference_value": mean_age_ref,
            "screen_lower": 25.0,
            "screen_upper": 31.0,
            "source": "cdc_first_birth_timing_target_review_target_ranking.csv",
            "why": "Economic-model timing target. Wide tolerance by years, not months.",
        },
        {
            "object": "share_first_birth_30_plus",
            "role": "primary",
            "unit": "share",
            "reference_window": "CDC pooled 2020-2024",
            "reference_value": share30_ref,
            "screen_lower": 0.20,
            "screen_upper": 0.55,
            "source": "cdc_first_birth_timing_target_review_target_ranking.csv",
            "why": "Main delay-timing share. Wide band screens out only clearly wrong models.",
        },
        {
            "object": "childless_share_at_50",
            "role": "primary",
            "unit": "share",
            "reference_window": "US Census target with recalibration guide",
            "reference_value": childless_ref,
            "screen_lower": 0.10,
            "screen_upper": 0.35,
            "source": "childlessness_recalibration.csv",
            "why": (
                "Broad stock-fertility band. The phi(0) recalibration window "
                f"[1.25, 1.85] spans {childless_recal_low:.3f}-{childless_recal_high:.3f}."
            ),
        },
        {
            "object": "us_total_fertility_rate",
            "role": "validation",
            "unit": "children_per_woman",
            "reference_window": "World Bank pooled 2020-2023",
            "reference_value": tfr_ref,
            "screen_lower": 1.40,
            "screen_upper": 1.95,
            "source": "world_bank_tfr_global.csv",
            "why": "Validation-only level check. Do not score tightly because the model object is not literal TFR.",
        },
    ]

    support_bands = {
        "25-29": (0.35, 0.52),
        "30-34": (0.30, 0.46),
        "35-39": (0.10, 0.22),
        "40-44+": (0.02, 0.06),
    }
    for bucket, lower_upper in support_bands.items():
        row = shape.loc[shape["bucket"] == bucket].iloc[0]
        rows.append(
            {
                "object": f"share_first_birth_{bucket.replace('+', '_plus').replace('-', '_')}",
                "role": "primary_timing_shape",
                "unit": "share",
                "reference_window": "CDC pooled 2020-2024",
                "reference_value": float(row["share_25_plus"]),
                "screen_lower": lower_upper[0],
                "screen_upper": lower_upper[1],
                "source": "cdc_first_birth_timing_target_review_25plus_target_comparison.csv",
                "why": "Moderately tight grouped-age timing-shape target around the CDC pooled reference.",
            }
        )

    return pd.DataFrame(rows)


def build_markdown(targets: pd.DataFrame) -> str:
    annual_eval = pd.read_csv(ANNUAL_SWEEP_PATH)
    eval_row = annual_eval.loc[annual_eval["a_price"] == 2.0].iloc[0]

    lines = [
        "# Annual fertility target ranges",
        "",
        "These are deliberately wide screening bands for the annual fertility calibration.",
        "They are meant to reject obviously wrong models, not to force simulation-style moment matching.",
        "",
        "## Main read",
        "",
        "- Treat these as screening ranges, not exact targets.",
        "- Fit timing within years, not months.",
        "- Treat the pooled 25+ first-birth shape as the main annual timing target.",
        "- Use mean age first birth and share 30+ as lighter summary checks rather than the main timing pass/fail rule.",
        "- In code, the rough-shape screen focuses on having enough mass after age 35 and avoiding too much piling into `25-29` relative to `30-34`, rather than forcing exact bin-by-bin matches.",
        "- Keep TFR as validation-only because the model object is `avg_birth_rate`, not literal TFR.",
        "- Comparative-static signs still matter: higher house prices should delay births and lower fertility.",
        "",
        "## Suggested bands",
        "",
        "| Object | Role | Reference | Wide screen band | Why |",
        "| --- | --- | ---: | ---: | --- |",
    ]

    for _, row in targets.iterrows():
        lines.append(
            f"| `{row['object']}` | `{row['role']}` | `{row['reference_value']:.4f}` | "
            f"`[{row['screen_lower']:.2f}, {row['screen_upper']:.2f}]` | {row['why']} |"
        )

    lines.extend(
        [
            "",
            "## Current annual prototype check",
            "",
            f"- At `a_price = 2.00`, the current annual prototype still lands at mean age first birth `{eval_row['mean_age_first_birth']:.2f}` and share first births `30+` `{eval_row['share_first_birth_30_plus']:.3f}`.",
            "- So even under these widened bands, the current annual prototype is still clearly too delayed.",
            "",
            "## Qualitative rules",
            "",
            "- Higher house prices should raise mean age at first birth.",
            "- Higher house prices should raise the share of first births at age `30+`.",
            "- Higher house prices should lower average birth rates and lower fertility levels.",
            "- Inside-band misses should be treated as acceptable; outside-band misses should be penalized only gradually unless the sign pattern is wrong.",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    targets = build_target_table()
    targets.to_csv(OUT_CSV, index=False)
    OUT_MD.write_text(build_markdown(targets), encoding="utf-8")


if __name__ == "__main__":
    main()
