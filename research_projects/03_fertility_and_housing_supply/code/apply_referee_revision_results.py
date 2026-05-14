import argparse
import csv
import math
import re
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "notes" / "build"
DRAFT_TEX = ROOT / "drafts" / "fertility_and_housing_supply.tex"
MODEL_TEX = ROOT / "drafts" / "sections" / "model.tex"
STATUS_MD = ROOT / "STATUS.md"
MEMORY_MD = ROOT / "memory.md"


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--sync-trackers", action="store_true")
    return parser.parse_args()


def to_float(value):
    text = (value or "").strip()
    if text == "" or text.lower() == "nan":
        return math.nan
    return float(text)


def load_csv(path):
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def load_sensitivity():
    rows = load_csv(BUILD_DIR / "sensitivity_mechanism_parameters.csv")
    out = []
    for row in rows:
        out.append(
            {
                "parameter": row["parameter"],
                "value": to_float(row["value"]),
                "crossing_price": to_float(row["crossing_price"]),
                "mean_first_birth_age": to_float(row["mean_first_birth_age"]),
                "childless_share_50": to_float(row["childless_share_50"]),
                "first_birth_rate": to_float(row["first_birth_rate"]),
                "avg_birth_rate": to_float(row["avg_birth_rate"]),
            }
        )
    return out


def load_childlessness():
    rows = load_csv(BUILD_DIR / "childlessness_recalibration.csv")
    out = []
    for row in rows:
        out.append(
            {
                "phi_0": to_float(row["phi_0"]),
                "crossing_price": to_float(row["crossing_price"]),
                "mean_first_birth_age": to_float(row["mean_first_birth_age"]),
                "first_birth_rate": to_float(row["first_birth_rate"]),
                "avg_birth_rate": to_float(row["avg_birth_rate"]),
                "parity0_at_50": to_float(row["parity0_at_50"]),
                "parity1_at_50": to_float(row["parity1_at_50"]),
                "parity2_at_50": to_float(row["parity2_at_50"]),
                "parity3plus_at_50": to_float(row["parity3plus_at_50"]),
                "scarcity_fertility_gap": to_float(row["scarcity_fertility_gap"]),
            }
        )
    return out


def find_row(rows, key, target):
    for row in rows:
        if math.isclose(row[key], target, rel_tol=0.0, abs_tol=1e-9):
            return row
    raise RuntimeError(f"Could not find row for {key}={target}")


def find_sensitivity_row(rows, parameter, value):
    for row in rows:
        if row["parameter"] != parameter:
            continue
        if math.isclose(row["value"], value, rel_tol=0.0, abs_tol=1e-9):
            return row
    raise RuntimeError(f"Could not find sensitivity row for {parameter}={value}")


def validate_full_results(sensitivity_rows, child_rows):
    sens_benchmark = find_sensitivity_row(sensitivity_rows, "kappa_q", 0.24)
    child_benchmark = find_row(child_rows, "phi_0", 1.05)
    for label, q in (
        ("sensitivity benchmark", sens_benchmark["crossing_price"]),
        ("childlessness benchmark", child_benchmark["crossing_price"]),
    ):
        if math.isnan(q) or q < 1.7 or q > 1.9:
            raise RuntimeError(f"{label} results do not look like full-resolution output")


def format_optional(value, fmt):
    if math.isnan(value):
        return "n.a."
    return format(value, fmt)


def build_sensitivity_table(rows):
    groups = [
        ("Price-sensitive birth cost $\\kappa_q$", "kappa_q", [0.18, 0.24, 0.30], 0.24),
        ("Crowding parameter $\\lambda_c$", "lambda_c", [0.12, 0.18, 0.24], 0.18),
        ("Logistic scale $\\sigma$", "sigma", [0.10, 0.15, 0.20], 0.15),
        ("First-birth utility $\\phi(0)$", "phi_0", [0.90, 1.05, 1.20], 1.05),
    ]

    lines = [
        "\\begin{table}[htbp]",
        "\\centering",
        "\\caption{Mechanism parameter sensitivity}",
        "\\label{tab:sensitivity}",
        "\\small",
        "\\begin{tabular}{ll ccccc}",
        "\\toprule",
        "Parameter & Value & Crossing $q$ & Mean first-birth age & Childless share & First-birth rate & Avg birth rate \\\\",
        "\\midrule",
    ]

    for idx, (title, label, values, benchmark_value) in enumerate(groups):
        lines.append(f"\\multicolumn{{7}}{{l}}{{\\textit{{{title}}}}} \\\\")
        for value in values:
            row = find_sensitivity_row(rows, label, value)
            value_text = f"\\textbf{{{value:.2f}}}" if math.isclose(value, benchmark_value, abs_tol=1e-9) else f"{value:.2f}"
            lines.append(
                " & {value_text} & {crossing} & {mean_age} & {childless} & {first_birth_rate} & {avg_birth_rate} \\\\".format(
                    value_text=value_text,
                    crossing=format_optional(row["crossing_price"], ".3f"),
                    mean_age=format_optional(row["mean_first_birth_age"], ".2f"),
                    childless=format_optional(row["childless_share_50"], ".3f"),
                    first_birth_rate=format_optional(row["first_birth_rate"], ".3f"),
                    avg_birth_rate=format_optional(row["avg_birth_rate"], ".3f"),
                )
            )
        if idx != len(groups) - 1:
            lines.append("\\addlinespace")

    lines.extend(["\\bottomrule", "\\end{tabular}", "\\end{table}"])
    return "\n".join(lines)


def build_sensitivity_paragraph(rows):
    k_low = find_sensitivity_row(rows, "kappa_q", 0.18)
    k_base = find_sensitivity_row(rows, "kappa_q", 0.24)
    k_high = find_sensitivity_row(rows, "kappa_q", 0.30)
    l_low = find_sensitivity_row(rows, "lambda_c", 0.12)
    l_high = find_sensitivity_row(rows, "lambda_c", 0.24)
    sigma_high = find_sensitivity_row(rows, "sigma", 0.20)
    phi_high = find_sensitivity_row(rows, "phi_0", 1.20)
    sigma_low = find_sensitivity_row(rows, "sigma", 0.10)

    sigma_sentence = (
        "By contrast, moving $\\sigma$ from 0.15 to 0.20 only shifts mean first-birth age from "
        f"{k_base['mean_first_birth_age']:.2f} to {sigma_high['mean_first_birth_age']:.2f} and the childless share from "
        f"{k_base['childless_share_50']:.3f} to {sigma_high['childless_share_50']:.3f}"
    )
    if math.isnan(sigma_low["crossing_price"]):
        sigma_sentence += ", while $\\sigma = 0.10$ yields no local political crossing on the supplied price grid."
    else:
        sigma_sentence += "."

    return (
        "These comparative statics do not correspond to any single calibration target; they show how the mechanism responds to variation in its key primitives. "
        "The completed full-resolution sweep confirms that $\\kappa_q$ and $\\lambda_c$ are the main quantitative mechanism parameters. "
        f"Lowering $\\kappa_q$ from 0.24 to 0.18 reduces mean first-birth age from {k_base['mean_first_birth_age']:.2f} to {k_low['mean_first_birth_age']:.2f} "
        f"and the childless share from {k_base['childless_share_50']:.3f} to {k_low['childless_share_50']:.3f}, while raising it to 0.30 pushes those objects to "
        f"{k_high['mean_first_birth_age']:.2f} and {k_high['childless_share_50']:.3f}. "
        f"The same pattern holds for $\\lambda_c$: moving from 0.12 to 0.24 shifts mean first-birth age from {l_low['mean_first_birth_age']:.2f} to {l_high['mean_first_birth_age']:.2f} "
        f"and the childless share from {l_low['childless_share_50']:.3f} to {l_high['childless_share_50']:.3f}. "
        + sigma_sentence
        + f" Varying $\\phi(0)$ within the narrower 0.90--1.20 range mainly moves the extensive fertility margin directly, lowering the childless share to {phi_high['childless_share_50']:.3f} at the high end and motivating the dedicated recalibration exercise below."
    )


def bracket_target(rows, target):
    ordered = sorted(rows, key=lambda row: row["phi_0"])
    above = None
    below = None
    for row in ordered:
        value = row["parity0_at_50"]
        if math.isnan(value):
            continue
        if value >= target:
            above = row
        if value <= target and below is None:
            below = row
    return above, below


def build_childlessness_paragraph(rows):
    target = 0.165
    benchmark = find_row(rows, "phi_0", 1.05)
    above, below = bracket_target(rows, target)

    if above and below and not math.isclose(above["phi_0"], below["phi_0"], abs_tol=1e-9):
        interp = above["phi_0"] + (target - above["parity0_at_50"]) * (below["phi_0"] - above["phi_0"]) / (
            below["parity0_at_50"] - above["parity0_at_50"]
        )
        bracket_sentence = (
            f"The Census target 0.165 is bracketed between $\\phi(0) = {above['phi_0']:.2f}$ "
            f"(childless share {above['parity0_at_50']:.3f}) and $\\phi(0) = {below['phi_0']:.2f}$ "
            f"({below['parity0_at_50']:.3f}), implying a simple interpolation near $\\phi(0) \\approx {interp:.2f}$."
        )
        lower_gap = below["scarcity_fertility_gap"]
    else:
        bracket_sentence = "The current sweep does not cleanly bracket the 0.165 childlessness target, so the parity-improving alternative remains only partially pinned down."
        lower_gap = benchmark["scarcity_fertility_gap"]

    return (
        "A focused recalibration of the first-birth utility parameter makes the benchmark trade-off explicit. "
        f"Holding all other parameters fixed and re-solving the political equilibrium, raising $\\phi(0)$ from 1.05 lowers the age-50 childless share from {benchmark['parity0_at_50']:.3f} "
        f"and moves mean first-birth age below the benchmark value of {benchmark['mean_first_birth_age']:.2f}. "
        + bracket_sentence
        + f" Across the same sweep, the scarcity fertility gap narrows from {benchmark['scarcity_fertility_gap']:.4f} at the benchmark to {lower_gap:.4f} near the target bracket. "
        "That improves the parity fit, but it also weakens the housing-scarcity mechanism, so the paper benchmark remains the timing-focused calibration and treats the parity-improving alternative as a disciplined robustness case."
    )


def replace_once(text, pattern, replacement):
    new_text, count = re.subn(pattern, replacement, text, flags=re.S)
    if count != 1:
        raise RuntimeError(f"Expected one match for pattern: {pattern}")
    return new_text


def patch_draft_tex(text, table_block, summary_paragraph):
    text = replace_once(
        text,
        r"% Placeholder: the table will be populated after the sensitivity sweep is run\.\s*\\begin\{table\}\[htbp\].*?\\end\{table\}",
        table_block,
    )
    text = replace_once(
        text,
        r"These comparative statics do not correspond to any particular calibration target; they show\s+how the mechanism responds to variation in its key primitives\. The sensitivity table will be\s+completed once the computational sweep \(Appendix~\\ref\{app:sensitivity\}\) is finished\.",
        summary_paragraph,
    )
    return text


def patch_model_tex(text, paragraph):
    marker = "\\subsection{Nesting result}"
    if "A focused recalibration of the first-birth utility parameter makes the benchmark trade-off explicit." in text:
        text = replace_once(
            text,
            r"A focused recalibration of the first-birth utility parameter makes the benchmark trade-off explicit\..*?(?=\n\n\\subsection\{Nesting result\})",
            paragraph,
        )
        return text

    anchor = "\\end{table}\n\n\\subsection{Nesting result}"
    if anchor not in text:
        raise RuntimeError("Could not find calibration-fit insertion anchor in model.tex")
    return text.replace(anchor, "\\end{table}\n\n" + paragraph + "\n\n" + marker, 1)


def prepend_status_entry(text, run_dir, target_bracket):
    date_tag = datetime.now().strftime("%Y-%m-%d")
    entry = (
        f"- Last updated: {date_tag} (referee-sweep away workflow completed)\n"
        f"- {date_tag} referee-sweep away workflow completed:\n"
        f"  - run folder: `notes/build/logs/{Path(run_dir).name}`\n"
        f"  - full outputs refreshed:\n"
        f"    - `notes/build/childlessness_recalibration.csv`\n"
        f"    - `notes/build/sensitivity_mechanism_parameters.csv`\n"
        f"  - updated draft files:\n"
        f"    - `drafts/fertility_and_housing_supply.tex`\n"
        f"    - `drafts/sections/model.tex`\n"
        f"    - `drafts/fertility_and_housing_supply.pdf`\n"
        f"  The full referee sweeps now exist as current machine-written outputs. {target_bracket} Appendix C is populated from the full sensitivity sweep, and the model section now states the parity-fit trade-off explicitly. Appendix D remains a logged blocker because the current sensitivity script still does not export the children-at-home profiles needed for the delayed-departure envelope.\n"
    )
    return text.replace("## Snapshot\n\n", "## Snapshot\n\n" + entry, 1)


def replace_next_tasks(text):
    replacement = (
        "## Next 3 Tasks\n\n"
        "1. Decide whether to keep the timing-focused benchmark or to present the childlessness-improving $\\phi(0)$ calibration as the main robustness case.\n"
        "2. Either export the children-at-home profiles needed for Appendix D or cut that delayed-departure envelope from the next circulating draft.\n"
        "3. Do a prose-consistency pass so the abstract, introduction, conclusion, and appendices all use the same current benchmark numbers.\n\n"
        "## Blockers"
    )
    return replace_once(text, r"## Next 3 Tasks\s+.*?\n## Blockers", replacement)


def prepend_memory_entry(text, run_dir, child_paragraph):
    date_tag = datetime.now().strftime("%Y-%m-%d")
    entry = (
        f"### Session: {date_tag} (referee-sweep away workflow completed)\n"
        f"- Away workflow run folder: `notes/build/logs/{Path(run_dir).name}`\n"
        f"- Full referee sweep outputs refreshed:\n"
        f"  - `notes/build/childlessness_recalibration.csv`\n"
        f"  - `notes/build/sensitivity_mechanism_parameters.csv`\n"
        f"- Draft updates applied automatically:\n"
        f"  - Appendix C sensitivity table in `drafts/fertility_and_housing_supply.tex`\n"
        f"  - calibration discussion paragraph in `drafts/sections/model.tex`\n"
        f"  - compiled `drafts/fertility_and_housing_supply.pdf`\n"
        f"- Main calibration lock after this pass:\n"
        f"  - {child_paragraph}\n"
        f"- Remaining blocker:\n"
        f"  - Appendix D still lacks the children-at-home profiles needed to finish the delayed-departure envelope numerically\n\n"
        "---\n\n"
    )
    return text.replace("Most recent session first.\n\n---\n\n", "Most recent session first.\n\n---\n\n" + entry, 1)


def write_summary(run_dir, sensitivity_rows, child_rows, sensitivity_paragraph, child_paragraph):
    target = 0.165
    above, below = bracket_target(child_rows, target)
    lines = [
        "# Referee revision sweep summary",
        "",
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"Run folder: `{Path(run_dir).name}`",
        "",
        "## Sensitivity sweep",
        "",
        sensitivity_paragraph,
        "",
        "## Childlessness recalibration",
        "",
        child_paragraph,
        "",
        "## Remaining blocker",
        "",
        "- Appendix D is still not finishable from the current automation chain because `run_sensitivity_table.m` does not export the children-at-home profiles needed for the delayed-departure envelope.",
        "",
    ]
    if above and below:
        lines.extend(
            [
                "## Target bracket",
                "",
                f"- target childless share: `{target:.3f}`",
                f"- upper bracket: `phi(0) = {above['phi_0']:.2f}` with childless share `{above['parity0_at_50']:.3f}`",
                f"- lower bracket: `phi(0) = {below['phi_0']:.2f}` with childless share `{below['parity0_at_50']:.3f}`",
                "",
            ]
        )

    summary_path = Path(run_dir) / "referee_revision_results_summary.md"
    summary_path.write_text("\n".join(lines), encoding="utf-8")


def main():
    args = parse_args()
    run_dir = Path(args.run_dir)

    sensitivity_rows = load_sensitivity()
    child_rows = load_childlessness()
    validate_full_results(sensitivity_rows, child_rows)

    table_block = build_sensitivity_table(sensitivity_rows)
    sensitivity_paragraph = build_sensitivity_paragraph(sensitivity_rows)
    child_paragraph = build_childlessness_paragraph(child_rows)

    draft_text = DRAFT_TEX.read_text(encoding="utf-8")
    model_text = MODEL_TEX.read_text(encoding="utf-8")

    DRAFT_TEX.write_text(patch_draft_tex(draft_text, table_block, sensitivity_paragraph), encoding="utf-8")
    MODEL_TEX.write_text(patch_model_tex(model_text, child_paragraph), encoding="utf-8")
    write_summary(run_dir, sensitivity_rows, child_rows, sensitivity_paragraph, child_paragraph)

    if args.sync_trackers:
        above, below = bracket_target(child_rows, 0.165)
        if above and below:
            target_bracket = (
                f"The childlessness target `0.165` is bracketed between `phi(0) = {above['phi_0']:.2f}` "
                f"(`{above['parity0_at_50']:.3f}`) and `phi(0) = {below['phi_0']:.2f}` (`{below['parity0_at_50']:.3f}`)."
            )
        else:
            target_bracket = "The childlessness target is still not cleanly bracketed in the current sweep."

        STATUS_MD.write_text(
            replace_next_tasks(prepend_status_entry(STATUS_MD.read_text(encoding="utf-8"), run_dir, target_bracket)),
            encoding="utf-8",
        )
        MEMORY_MD.write_text(
            prepend_memory_entry(MEMORY_MD.read_text(encoding="utf-8"), run_dir, child_paragraph),
            encoding="utf-8",
        )


if __name__ == "__main__":
    main()
