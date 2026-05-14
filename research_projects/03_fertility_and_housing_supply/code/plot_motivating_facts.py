"""
plot_motivating_facts.py
========================
Create motivating-fact figures for "Housing Scarcity, Delayed First Births,
and Fertility" (Gross & Chivers).

Figures produced:
  1. Real house price indices for 8 countries (US, UK, Canada, Australia,
     Germany, Japan, France, Sweden), indexed to 2000=100
  2. Total fertility rates over time for the same 8 countries
  3. Cross-country scatter: cumulative house price growth vs change in
     mean age at first birth (European countries with joint data)

Data sources:
  - data/raw/international/oecd_house_prices_annual.csv  (European OECD)
  - data/raw/international/fred_house_prices_global.csv   (US, JP, CA, AU)
  - data/raw/international/world_bank_tfr_global.csv      (global TFR)
  - data/processed/international_first_birth_timing_eu.csv (Eurostat)
  - data/processed/international_first_birth_timing_shocks_v1.csv
"""

import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator

# ── paths ──────────────────────────────────────────────────────────────────
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HP_OECD_PATH = os.path.join(ROOT, "data", "raw", "international",
                            "oecd_house_prices_annual.csv")
HP_FRED_PATH = os.path.join(ROOT, "data", "raw", "international",
                            "fred_house_prices_global.csv")
TFR_WB_PATH = os.path.join(ROOT, "data", "raw", "international",
                           "world_bank_tfr_global.csv")
FB_PATH = os.path.join(ROOT, "data", "processed",
                       "international_first_birth_timing_eu.csv")
SHOCKS_PATH = os.path.join(ROOT, "data", "processed",
                           "international_first_birth_timing_shocks_v1.csv")
OUT_DIR = os.path.join(ROOT, "notes", "build")
os.makedirs(OUT_DIR, exist_ok=True)

# ── style ──────────────────────────────────────────────────────────────────
plt.rcParams.update({
    "font.family": "serif",
    "font.size": 11,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.grid": False,
    "figure.dpi": 150,
    "savefig.bbox": "tight",
    "savefig.pad_inches": 0.15,
})

# ── country selection (8 countries: 4 anglophone/Pacific + 4 European) ────
COUNTRIES = ["US", "UK", "CA", "AU", "DE", "JP", "FR", "SE"]
COUNTRY_NAMES = {
    "US": "United States",
    "UK": "United Kingdom",
    "CA": "Canada",
    "AU": "Australia",
    "DE": "Germany",
    "JP": "Japan",
    "FR": "France",
    "SE": "Sweden",
}

COLOURS = {
    "US": "#1f77b4",
    "UK": "#ff7f0e",
    "CA": "#2ca02c",
    "AU": "#d62728",
    "DE": "#9467bd",
    "JP": "#8c564b",
    "FR": "#17becf",
    "SE": "#7f7f7f",
}

LINE_STYLES = {
    "US": "-",
    "UK": "-",
    "CA": "-",
    "AU": "-",
    "DE": "--",
    "JP": "--",
    "FR": "--",
    "SE": "--",
}

BASE_YEAR = 2005


def save(fig, stem):
    """Save figure as .pdf and .png."""
    fig.savefig(os.path.join(OUT_DIR, f"{stem}.pdf"))
    fig.savefig(os.path.join(OUT_DIR, f"{stem}.png"))
    print(f"  saved {stem}.pdf / .png")
    plt.close(fig)


# ═══════════════════════════════════════════════════════════════════════════
# Figure 1 — Real house price indices
# ═══════════════════════════════════════════════════════════════════════════
print("\n-- Figure 1: House price indices ---------------------")

# Load European OECD data
hp_oecd = pd.read_csv(HP_OECD_PATH)
hp_oecd = hp_oecd[hp_oecd["country_code"].isin(COUNTRIES)].copy()
hp_oecd = hp_oecd.dropna(subset=["oecd_house_price_index"])
hp_oecd = hp_oecd.rename(columns={"oecd_house_price_index": "hpi"})
hp_oecd = hp_oecd[["country_code", "year", "hpi"]]

# Load FRED global data (US, JP, CA, AU)
hp_fred = pd.read_csv(HP_FRED_PATH)
hp_fred = hp_fred.rename(columns={"house_price_index": "hpi"})
hp_fred = hp_fred[["country_code", "year", "hpi"]]

# Combine
hp = pd.concat([hp_oecd, hp_fred], ignore_index=True)
hp = hp.drop_duplicates(subset=["country_code", "year"], keep="first")

# Re-index to BASE_YEAR = 100
fig1, ax1 = plt.subplots(figsize=(8, 5))
for cc in COUNTRIES:
    sub = hp[hp["country_code"] == cc].sort_values("year")
    base_row = sub[sub["year"] == BASE_YEAR]
    if len(base_row) == 0 or len(sub) == 0:
        print(f"  skipping {cc} (no {BASE_YEAR} base)")
        continue
    base_val = base_row["hpi"].iloc[0]
    idx = sub["hpi"] / base_val * 100
    # Restrict to 1990+ for cleaner plot
    mask = sub["year"] >= 1990
    ax1.plot(sub.loc[mask, "year"], idx[mask],
             label=COUNTRY_NAMES[cc],
             color=COLOURS[cc],
             linestyle=LINE_STYLES[cc],
             linewidth=1.6)
    print(f"  {COUNTRY_NAMES[cc]:20s}  base={base_val:.1f}  "
          f"latest={sub['hpi'].iloc[-1]:.1f}  "
          f"indexed={idx.iloc[-1]:.1f}")

ax1.set_xlabel("Year")
ax1.set_ylabel(f"Real house price index ({BASE_YEAR} = 100)")
ax1.legend(loc="upper left", frameon=False, fontsize=9)
ax1.xaxis.set_major_locator(MaxNLocator(integer=True))
save(fig1, "motivating_house_prices")


# ═══════════════════════════════════════════════════════════════════════════
# Figure 2 — Total fertility rates
# ═══════════════════════════════════════════════════════════════════════════
print("\n-- Figure 2: Total fertility rates -------------------")

# Load Eurostat TFR (European countries)
fb_eu = pd.read_csv(FB_PATH)
fb_eu = fb_eu[fb_eu["country_code"].isin(COUNTRIES)].copy()
fb_eu = fb_eu.dropna(subset=["total_fertility_rate"])
fb_eu = fb_eu[["country_code", "year", "total_fertility_rate"]]

# Load World Bank TFR (global)
tfr_wb = pd.read_csv(TFR_WB_PATH)
tfr_wb = tfr_wb[tfr_wb["country_code"].isin(COUNTRIES)].copy()
tfr_wb = tfr_wb[["country_code", "year", "total_fertility_rate"]]

# Combine, preferring World Bank for broader coverage
tfr = pd.concat([tfr_wb, fb_eu], ignore_index=True)
tfr = tfr.drop_duplicates(subset=["country_code", "year"], keep="first")

fig2, ax2 = plt.subplots(figsize=(8, 5))
for cc in COUNTRIES:
    sub = tfr[tfr["country_code"] == cc].sort_values("year")
    # Restrict to 1960+ for cleaner plot
    sub = sub[sub["year"] >= 1960]
    if len(sub) == 0:
        print(f"  skipping {cc} (no TFR data)")
        continue
    ax2.plot(sub["year"], sub["total_fertility_rate"],
             label=COUNTRY_NAMES[cc],
             color=COLOURS[cc],
             linestyle=LINE_STYLES[cc],
             linewidth=1.6)
    print(f"  {COUNTRY_NAMES[cc]:20s}  years {sub.year.min()}-{sub.year.max()}  "
          f"latest TFR={sub['total_fertility_rate'].iloc[-1]:.2f}")

# Replacement level
ax2.axhline(2.1, color="black", linestyle="--", linewidth=0.9, alpha=0.6)
ax2.text(ax2.get_xlim()[1] + 0.5, 2.1, "Replacement", va="center",
         fontsize=9, color="black", alpha=0.7)

ax2.set_xlabel("Year")
ax2.set_ylabel("Total fertility rate")
ax2.legend(loc="upper right", frameon=False, fontsize=9, ncol=2)
ax2.xaxis.set_major_locator(MaxNLocator(integer=True))
save(fig2, "motivating_fertility_rates")


# ═══════════════════════════════════════════════════════════════════════════
# Figure 3 — Scatter: house prices vs age at first birth
# ═══════════════════════════════════════════════════════════════════════════
print("\n-- Figure 3: Scatter - prices vs first-birth age ----")
shocks = pd.read_csv(SHOCKS_PATH)
shocks = shocks.dropna(subset=["oecd_house_price_index", "mean_age_first_birth"])

# For each country, compute cumulative real house price growth (%) and
# the change in mean age at first birth over the observation window.
# Exclude Turkey (extreme outlier with >500% cumulative growth).
records = []
for cc, grp in shocks.groupby("country_code"):
    if cc == "TR":
        continue
    grp = grp.sort_values("year")
    if len(grp) < 5:
        continue
    hp_first = grp["oecd_house_price_index"].iloc[0]
    hp_last = grp["oecd_house_price_index"].iloc[-1]
    if hp_first <= 0:
        continue
    n_years = grp["year"].iloc[-1] - grp["year"].iloc[0]
    if n_years < 5:
        continue
    cum_growth = (hp_last / hp_first - 1.0) * 100
    fab_change = (grp["mean_age_first_birth"].iloc[-1]
                  - grp["mean_age_first_birth"].iloc[0])
    records.append({
        "country_code": cc,
        "cum_hp_growth": cum_growth,
        "fab_change": fab_change,
        "n_obs": len(grp),
        "year_start": int(grp["year"].iloc[0]),
        "year_end": int(grp["year"].iloc[-1]),
    })

cmeans = pd.DataFrame(records)
print(f"  {len(cmeans)} countries (excl. Turkey)")

fig3, ax3 = plt.subplots(figsize=(7, 6))
ax3.scatter(cmeans["cum_hp_growth"], cmeans["fab_change"],
            s=45, color="#1f77b4", edgecolors="white", linewidths=0.5,
            zorder=3)

# Label each point
for _, row in cmeans.iterrows():
    ax3.annotate(row["country_code"],
                 (row["cum_hp_growth"], row["fab_change"]),
                 textcoords="offset points", xytext=(5, 4),
                 fontsize=8, color="#333333")

# OLS fit
slope, intercept = np.polyfit(cmeans["cum_hp_growth"], cmeans["fab_change"], 1)
x_line = np.linspace(cmeans["cum_hp_growth"].min() - 10,
                     cmeans["cum_hp_growth"].max() + 10, 100)
ax3.plot(x_line, intercept + slope * x_line,
         color="#d62728", linewidth=1.2, linestyle="--", zorder=2)

corr = cmeans["cum_hp_growth"].corr(cmeans["fab_change"])
ax3.text(0.05, 0.95,
         f"$r = {corr:.2f}$\n$N = {len(cmeans)}$ countries",
         transform=ax3.transAxes, fontsize=10, va="top",
         bbox=dict(facecolor="white", edgecolor="none", alpha=0.8))
print(f"  correlation = {corr:.3f},  slope = {slope:.5f},  "
      f"intercept = {intercept:.2f}")

ax3.set_xlabel("Cumulative real house price growth (%)")
ax3.set_ylabel("Change in mean age at first birth (years)")
save(fig3, "motivating_scatter_prices_timing")

print("\nDone.")
