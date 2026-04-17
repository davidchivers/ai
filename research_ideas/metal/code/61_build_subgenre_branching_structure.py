from __future__ import annotations

import importlib.util
import math
import re
import unicodedata
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"
ANALYZE_PATH = PROJECT_ROOT / "code" / "05_analyze_genre_trends.py"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

FIGURE_PATH = OUTPUT_DIR / "subgenre_branching_structure.png"
SVG_PATH = OUTPUT_DIR / "subgenre_branching_structure.svg"
SUMMARY_PATH = OUTPUT_DIR / "subgenre_branching_structure_summary.md"

ROOT_FAMILIES = ["heavy metal", "thrash metal", "death metal", "doom metal", "black metal"]
THRESHOLDS_BY_DEPTH = {0: 0, 1: 100, 2: 20, 3: 5}
FAMILY_COLORS = {
    "heavy metal": "#58508d",
    "thrash metal": "#bc5090",
    "death metal": "#ff6361",
    "doom metal": "#ffa600",
    "black metal": "#2f4b7c",
}


def load_genre_module():
    spec = importlib.util.spec_from_file_location("metal_genre_trends", ANALYZE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def normalize_text(value: str) -> str:
    text = unicodedata.normalize("NFKD", str(value)).encode("ascii", "ignore").decode("ascii").lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def title_case_family(value: str) -> str:
    return str(value).title()


def build_tag_summary() -> pd.DataFrame:
    genre_module = load_genre_module()
    bands = pd.read_csv(INPUT_PATH, usecols=["genre_raw", "entry_year"], dtype={"genre_raw": "string"})
    bands["entry_year"] = pd.to_numeric(bands["entry_year"], errors="coerce")
    bands = bands.loc[bands["entry_year"].notna() & bands["genre_raw"].notna()].copy()
    bands["entry_year"] = bands["entry_year"].astype(int)

    token_cache, _ = genre_module.build_genre_cache(bands["genre_raw"])
    rows: list[dict[str, object]] = []
    for row in bands.itertuples(index=False):
        for tag in token_cache.get(str(row.genre_raw), []):
            rows.append({"tag": tag, "entry_year": int(row.entry_year)})

    summary = (
        pd.DataFrame(rows)
        .groupby("tag", as_index=False)
        .agg(first_year=("entry_year", "min"), count=("entry_year", "size"))
    )
    summary["norm"] = summary["tag"].map(normalize_text)
    summary = (
        summary.sort_values(["norm", "count", "first_year", "tag"], ascending=[True, False, True, True])
        .drop_duplicates(subset=["norm"], keep="first")
        .reset_index(drop=True)
    )
    return summary


def choose_parents(summary: pd.DataFrame) -> tuple[dict[str, str | None], dict[str, str | None], dict[str, int | None]]:
    lookup = summary.set_index("norm")[["tag", "first_year", "count"]].to_dict("index")
    root_norms = {normalize_text(root): root for root in ROOT_FAMILIES}

    parent_norm: dict[str, str | None] = {}
    root_of: dict[str, str | None] = {}
    depth_of: dict[str, int | None] = {}

    for row in summary.itertuples(index=False):
        norm = row.norm
        words = norm.split()
        candidates: list[tuple[str, int, int, int]] = []
        for idx in range(len(words)):
            candidate = " ".join(words[:idx] + words[idx + 1 :]).strip()
            if candidate in lookup and int(lookup[candidate]["first_year"]) <= int(row.first_year):
                candidates.append(
                    (
                        candidate,
                        len(candidate.split()),
                        int(lookup[candidate]["count"]),
                        -int(lookup[candidate]["first_year"]),
                    )
                )
        parent_norm[norm] = max(candidates, key=lambda item: (item[1], item[2], item[3]))[0] if candidates else None

    for norm in summary["norm"]:
        seen: set[str] = set()
        cur = norm
        root = None
        while cur is not None and cur not in seen:
            seen.add(cur)
            if cur in root_norms:
                root = cur
                break
            cur = parent_norm.get(cur)
        root_of[norm] = root

    for norm in summary["norm"]:
        root = root_of[norm]
        if root is None:
            depth_of[norm] = None
            continue
        depth = 0
        cur = norm
        while cur != root and cur is not None:
            cur = parent_norm.get(cur)
            depth += 1
        depth_of[norm] = depth

    return parent_norm, root_of, depth_of


def build_kept_nodes(summary: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, str | None], dict[str, str | None]]:
    parent_norm, root_of, depth_of = choose_parents(summary)
    summary = summary.copy()
    summary["root_norm"] = summary["norm"].map(root_of)
    summary["depth"] = summary["norm"].map(depth_of)
    summary = summary.loc[summary["root_norm"].notna()].copy()

    keep_mask = summary["depth"].map(lambda depth: int(summary.loc[summary["depth"].eq(depth), "count"].median()) if False else 0)
    del keep_mask
    summary["keep_i"] = summary.apply(
        lambda row: int(int(row["count"]) >= THRESHOLDS_BY_DEPTH.get(int(row["depth"]), 10)),
        axis=1,
    )
    kept = summary.loc[summary["keep_i"].eq(1)].copy()

    kept_norms = set(kept["norm"])
    display_parent: dict[str, str | None] = {}
    display_root: dict[str, str | None] = {}

    for row in kept.itertuples(index=False):
        norm = row.norm
        root = row.root_norm
        display_root[norm] = root
        if norm == root:
            display_parent[norm] = None
            continue
        cur = parent_norm.get(norm)
        while cur is not None and cur not in kept_norms:
            cur = parent_norm.get(cur)
        display_parent[norm] = cur

    kept["display_parent"] = kept["norm"].map(display_parent)
    kept["display_root"] = kept["norm"].map(display_root)
    return kept, display_parent, display_root


def assign_local_y_positions(nodes: list[str], children: dict[str, list[str]], root: str) -> dict[str, float]:
    ordered_children = {
        parent: sorted(kids, key=lambda item: (nodes_lookup[item]["first_year"], -nodes_lookup[item]["count"], nodes_lookup[item]["tag"]))
        for parent, kids in children.items()
    }

    y_positions: dict[str, float] = {}
    next_leaf = 0

    def walk(node: str) -> float:
        nonlocal next_leaf
        kids = ordered_children.get(node, [])
        if not kids:
            y_positions[node] = float(next_leaf)
            next_leaf += 1
            return y_positions[node]
        child_positions = [walk(child) for child in kids]
        y_positions[node] = sum(child_positions) / len(child_positions)
        return y_positions[node]

    walk(root)
    root_y = y_positions[root]
    for key in list(y_positions):
        y_positions[key] = y_positions[key] - root_y
    return y_positions


def build_layout(kept: pd.DataFrame) -> pd.DataFrame:
    global nodes_lookup
    nodes_lookup = kept.set_index("norm")[["tag", "first_year", "count", "display_parent", "display_root", "depth"]].to_dict("index")

    base_positions = {
        "heavy metal": 8.0,
        "thrash metal": 6.0,
        "death metal": 4.0,
        "doom metal": 2.0,
        "black metal": 0.0,
    }

    y_map: dict[str, float] = {}
    for root in [normalize_text(root_family) for root_family in ROOT_FAMILIES]:
        family_nodes = kept.loc[kept["display_root"].eq(root), "norm"].tolist()
        children: dict[str, list[str]] = defaultdict(list)
        for node in family_nodes:
            parent = nodes_lookup[node]["display_parent"]
            if parent is not None:
                children[parent].append(node)
        local_y = assign_local_y_positions(family_nodes, children, root)
        scale = 0.34
        family_name = nodes_lookup[root]["tag"]
        base_y = base_positions[family_name]
        for node, offset in local_y.items():
            y_map[node] = base_y + offset * scale

    kept = kept.copy()
    kept["x"] = kept["first_year"].astype(float)
    kept["y"] = kept["norm"].map(y_map)
    return kept


def write_summary(kept: pd.DataFrame) -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Subgenre branching structure summary\n\n")
        handle.write(
            "This figure is a lexical branching structure built from nested genre descriptors. It is "
            "not a literal historical genealogy. Only the main family trunks are labelled; smaller "
            "descendant nodes show sub / sub-sub / sub-sub-sub differentiation.\n\n"
        )
        handle.write("## Kept nodes by family\n\n")
        counts = kept.groupby("display_root")["norm"].count().rename("nodes_kept").reset_index()
        counts["display_root"] = counts["display_root"].map(lambda value: title_case_family(nodes_lookup[value]["tag"]))
        handle.write(counts.to_markdown(index=False))
        handle.write("\n\n## Example descendants\n\n")
        for family in ROOT_FAMILIES:
            family_norm = normalize_text(family)
            family_df = kept.loc[kept["display_root"].eq(family_norm), ["tag", "first_year", "count", "depth"]].copy()
            family_df["tag"] = family_df["tag"].map(title_case_family)
            family_df = family_df.sort_values(["depth", "count", "first_year"], ascending=[True, False, True]).head(12)
            handle.write(f"### {title_case_family(family)}\n\n")
            handle.write(family_df.to_markdown(index=False))
            handle.write("\n\n")


def plot_structure(kept: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(13.5, 8.5))

    # Draw edges first.
    for row in kept.itertuples(index=False):
        if pd.isna(row.display_parent) or row.display_parent is None:
            continue
        parent = kept.loc[kept["norm"].eq(row.display_parent)].iloc[0]
        color = FAMILY_COLORS.get(parent["tag"] if parent["depth"] == 0 else nodes_lookup[row.display_root]["tag"], "#666666")
        alpha = 0.65 if row.depth <= 1 else 0.35 if row.depth == 2 else 0.20
        lw = 2.2 if row.depth <= 1 else 1.2 if row.depth == 2 else 0.8
        ax.plot([parent["x"], row.x], [parent["y"], row.y], color=color, alpha=alpha, linewidth=lw, solid_capstyle="round")

    # Draw nodes.
    for row in kept.itertuples(index=False):
        root_tag = nodes_lookup[row.display_root]["tag"]
        color = FAMILY_COLORS.get(root_tag, "#666666")
        if row.depth == 0:
            size = 140
            edge = "white"
            alpha = 1.0
        elif row.depth == 1:
            size = 28 + 7 * math.log1p(row.count)
            edge = "none"
            alpha = 0.85
        elif row.depth == 2:
            size = 16 + 4 * math.log1p(row.count)
            edge = "none"
            alpha = 0.45
        else:
            size = 8 + 2.5 * math.log1p(row.count)
            edge = "none"
            alpha = 0.25
        ax.scatter(row.x, row.y, s=size, color=color, edgecolors=edge, linewidths=0.6, alpha=alpha, zorder=3)

    # Label only the main trunks.
    for family in ROOT_FAMILIES:
        root_norm = normalize_text(family)
        row = kept.loc[kept["norm"].eq(root_norm)].iloc[0]
        ax.text(
            row.x - 0.8,
            row.y,
            f"{title_case_family(family)} ({int(row.first_year)})",
            ha="right",
            va="center",
            fontsize=11,
            fontweight="bold",
            color=FAMILY_COLORS.get(family, "#333333"),
        )

    ax.set_title("Branching structure of metal subgenre descriptors", fontsize=16, weight="bold")
    ax.set_xlabel("First appearance year in the data")
    ax.set_yticks([])
    ax.set_xlim(1960, max(kept["x"]) + 4)
    ax.grid(axis="x", alpha=0.20, linewidth=0.6)
    for spine in ["left", "right", "top"]:
        ax.spines[spine].set_visible(False)

    note = (
        "Only main family trunks are labelled. Smaller nodes show later nested descriptors.\n"
        "This is a descriptor hierarchy from the data, not a literal causal genealogy of metal."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(FIGURE_PATH, dpi=220)
    fig.savefig(SVG_PATH)
    plt.close(fig)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    summary = build_tag_summary()
    kept, _, _ = build_kept_nodes(summary)
    layout = build_layout(kept)
    plot_structure(layout)
    write_summary(layout)
    print(f"Wrote {FIGURE_PATH}")
    print(f"Wrote {SVG_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
