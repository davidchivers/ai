"""
Metal Archive – summary analysis
Outputs: analysis_summary.txt + several PNGs
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import os

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "bands_and_first_releases.csv")
OUT  = HERE

df = pd.read_csv(DATA, low_memory=False)

# ── clean ────────────────────────────────────────────────────────────────────
df["year_creation"] = pd.to_numeric(df["year_creation"], errors="coerce")
df["first_release"] = pd.to_datetime(df["first_release"], errors="coerce")
df["release_year"]  = df["first_release"].dt.year

# primary genre (first tag before /)
df["primary_genre"] = df["genre"].str.split("/").str[0].str.strip()

lines = []

# ── 1. overall counts ────────────────────────────────────────────────────────
lines.append("=== Metal Archive – Summary Analysis ===\n")
lines.append(f"Total bands:       {len(df):,}")
lines.append(f"Countries covered: {df['country'].nunique():,}")
lines.append(f"Unique genres:     {df['primary_genre'].nunique():,}")
lines.append(f"Bands with release year: {df['release_year'].notna().sum():,}\n")

# ── 2. top 15 countries ──────────────────────────────────────────────────────
top_countries = df["country"].value_counts().head(15)
lines.append("--- Top 15 Countries by Band Count ---")
for c, n in top_countries.items():
    lines.append(f"  {c:<30} {n:,}")
lines.append("")

fig, ax = plt.subplots(figsize=(10, 6))
top_countries.sort_values().plot.barh(ax=ax, color="steelblue")
ax.set_xlabel("Number of bands")
ax.set_title("Top 15 Countries by Band Count")
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{int(x):,}"))
plt.tight_layout()
fig.savefig(os.path.join(OUT, "08a_top_countries.png"), dpi=150)
plt.close(fig)

# ── 3. top 15 primary genres ─────────────────────────────────────────────────
top_genres = df["primary_genre"].value_counts().head(15)
lines.append("--- Top 15 Primary Genres ---")
for g, n in top_genres.items():
    lines.append(f"  {g:<35} {n:,}")
lines.append("")

fig, ax = plt.subplots(figsize=(10, 6))
top_genres.sort_values().plot.barh(ax=ax, color="firebrick")
ax.set_xlabel("Number of bands")
ax.set_title("Top 15 Primary Genres")
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{int(x):,}"))
plt.tight_layout()
fig.savefig(os.path.join(OUT, "08b_top_genres.png"), dpi=150)
plt.close(fig)

# ── 4. band status breakdown ─────────────────────────────────────────────────
status_counts = df["status"].value_counts()
lines.append("--- Band Status Breakdown ---")
for s, n in status_counts.items():
    lines.append(f"  {s:<25} {n:,}")
lines.append("")

fig, ax = plt.subplots(figsize=(7, 5))
status_counts.plot.bar(ax=ax, color="darkorange", rot=30)
ax.set_ylabel("Number of bands")
ax.set_title("Band Status Breakdown")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{int(x):,}"))
plt.tight_layout()
fig.savefig(os.path.join(OUT, "08c_status_breakdown.png"), dpi=150)
plt.close(fig)

# ── 5. formations per decade ─────────────────────────────────────────────────
df["decade"] = (df["year_creation"] // 10 * 10).dropna()
decade_counts = (
    df.dropna(subset=["year_creation"])
      .assign(decade=lambda x: (x["year_creation"] // 10 * 10).astype(int))
      .groupby("decade")
      .size()
)
decade_counts = decade_counts[decade_counts.index >= 1960]
lines.append("--- Band Formations by Decade ---")
for d, n in decade_counts.items():
    lines.append(f"  {int(d)}s  {n:,}")
lines.append("")

fig, ax = plt.subplots(figsize=(9, 5))
decade_counts.plot.bar(ax=ax, color="seagreen", rot=0)
ax.set_xlabel("Decade")
ax.set_ylabel("Bands formed")
ax.set_title("Band Formations by Decade")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{int(x):,}"))
plt.tight_layout()
fig.savefig(os.path.join(OUT, "08d_formations_by_decade.png"), dpi=150)
plt.close(fig)

# ── 6. UK deep-dive ──────────────────────────────────────────────────────────
uk = df[df["country"] == "United Kingdom"]
lines.append(f"--- United Kingdom Deep-Dive ({len(uk):,} bands) ---")
lines.append("  Top genres:")
for g, n in uk["primary_genre"].value_counts().head(10).items():
    lines.append(f"    {g:<35} {n:,}")
lines.append("  Status:")
for s, n in uk["status"].value_counts().items():
    lines.append(f"    {s:<25} {n:,}")
lines.append("")

# ── write summary ────────────────────────────────────────────────────────────
summary_path = os.path.join(OUT, "analysis_summary.txt")
with open(summary_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print("\n".join(lines))
print(f"\nSaved: analysis_summary.txt + 08a–08d PNGs")
