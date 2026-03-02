"""04_analysis_stub.py

Pipeline stub: specify baseline and robustness models for later estimation.
No estimation is run in this stub.
"""

from dataclasses import dataclass
from pathlib import Path


@dataclass
class ModelSpec:
    name: str
    formula: str
    outcome: str
    notes: str


def specs() -> list[ModelSpec]:
    return [
        ModelSpec(
            name="baseline_shift_share",
            formula=(
                "inflation ~ retiree_share * pension_shock * pensioner_category "
                "+ controls + region_fe + time_fe"
            ),
            outcome="category-region inflation",
            notes="Primary test of demand-composition channel.",
        ),
        ModelSpec(
            name="basket_differential",
            formula="pensioner_basket_minus_headline ~ pension_shock + controls",
            outcome="national inflation differential",
            notes="Tracks pensioner-weighted inflation wedge.",
        ),
        ModelSpec(
            name="cost_channel_extension",
            formula=(
                "inflation ~ retiree_share * pension_shock + labor_intensity * payroll_tax_proxy "
                "+ controls + fixed_effects"
            ),
            outcome="sectoral inflation",
            notes="Separates demand and potential payroll-tax cost channel.",
        ),
    ]


def main() -> None:
    out = Path(__file__).resolve().parent.parent / "outputs" / "tables" / "analysis_specs_stub.txt"
    lines = []
    for s in specs():
        lines.append(f"[{s.name}]\nOutcome: {s.outcome}\nFormula: {s.formula}\nNotes: {s.notes}\n")
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote analysis spec stub: {out}")


if __name__ == "__main__":
    main()
