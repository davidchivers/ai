import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import re

OUT = "C:/Users/Dave_/AI/metal archive/"
BG = '#f5f0eb'
PURPLE_MAIN = '#9333ea'

print("Loading data...")
df = pd.read_csv("C:/Users/Dave_/AI/bands_and_first_releases.csv")

def primary_genre(g):
    if pd.isna(g):
        return 'Unknown'
    return g.strip().split('/')[0].strip()

df['primary_genre'] = df['genre'].apply(primary_genre)

# Compute longevity from years_active
def compute_longevity(s):
    if pd.isna(s):
        return np.nan
    years = re.findall(r'\b(1[89]\d{2}|20\d{2})\b', str(s))
    if not years:
        return np.nan
    years = [int(y) for y in years]
    if 'Present' in str(s):
        end = 2026
    else:
        end = max(years)
    start = min(years)
    return end - start

df['longevity'] = df['years_active'].apply(compute_longevity)

# Work with bands that have year_creation
df_yr = df.dropna(subset=['year_creation']).copy()
df_yr['year_creation'] = df_yr['year_creation'].astype(int)
df_yr['cg'] = df_yr['country'] + '|||' + df_yr['primary_genre']

print(f"Bands with year_creation: {len(df_yr)}")

# --- Scene density at time of entry ---
# For each band, count how many bands in same country+genre existed BEFORE this band (year < this band's year)
print("Computing scene density (this may take a moment)...")

# Sort by year
df_yr = df_yr.sort_values('year_creation').reset_index(drop=True)

# Use groupby cumcount approach
df_yr['scene_density'] = df_yr.groupby('cg').cumcount()  # bands before this one in same cg

print(f"Scene density computed. Max={df_yr['scene_density'].max()}, Median={df_yr['scene_density'].median():.1f}")

# --- 07a: Histogram of scene density ---
print("07a: scene density...")
fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)
ax.set_facecolor(BG)
# log-scale x: use log bins
data = df_yr['scene_density'] + 1  # +1 to avoid log(0)
bins = np.logspace(0, np.log10(data.max()), 50)
ax.hist(data, bins=bins, color=PURPLE_MAIN, alpha=0.85, edgecolor='white', linewidth=0.3)
ax.set_xscale('log')
ax.set_title('Scene Density at Time of Band Entry\n(# prior bands in same country+genre, log scale)', fontweight='bold', fontsize=13)
ax.set_xlabel('Scene Density at Entry + 1 (log scale)')
ax.set_ylabel('Number of Bands')
ax.spines[['top','right']].set_visible(False)
fig.tight_layout()
fig.savefig(OUT + '07a_scene_density.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 07a")

# --- 07b: Scene density vs longevity (binned scatter) ---
print("07b: density vs longevity...")
df_both = df_yr.dropna(subset=['longevity']).copy()
df_both = df_both[df_both['longevity'] <= 60]
df_both['log_density'] = np.log1p(df_both['scene_density'])

# Bin log_density into 20 bins
df_both['density_bin'] = pd.cut(df_both['log_density'], bins=20)
binned = df_both.groupby('density_bin', observed=True)['longevity'].agg(['mean','sem','count']).reset_index()
binned = binned[binned['count'] >= 10]
bin_centers = binned['density_bin'].apply(lambda x: x.mid)

fig, ax = plt.subplots(figsize=(11, 5), facecolor=BG)
ax.set_facecolor(BG)
ax.errorbar(bin_centers, binned['mean'], yerr=binned['sem']*1.96,
            color='#6b21a8', linewidth=2, marker='o', markersize=4,
            ecolor='#c084fc', elinewidth=1, capsize=3)
ax.fill_between(bin_centers, binned['mean'] - binned['sem']*1.96,
                binned['mean'] + binned['sem']*1.96, alpha=0.15, color='#9333ea')
ax.set_title('Scene Density at Entry vs Band Longevity\n(binned mean ± 95% CI)', fontweight='bold', fontsize=13)
ax.set_xlabel('log(Scene Density + 1) at Entry')
ax.set_ylabel('Mean Band Longevity (years)')
ax.spines[['top','right']].set_visible(False)
fig.tight_layout()
fig.savefig(OUT + '07b_density_vs_longevity.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 07b")

# --- 07c: Event study — cumulative band formations + milestone releases ---
print("07c: event study...")

def parse_release_year(s):
    if pd.isna(s):
        return np.nan
    try:
        return int(str(s).split('-')[0])
    except:
        return np.nan

df['first_release_year'] = df['first_release'].apply(parse_release_year)
df['primary_genre'] = df['genre'].apply(primary_genre)
df['cg'] = df['country'] + '|||' + df['primary_genre']

# Top 5 cg by total band count (requiring year_creation)
cg_counts = df.dropna(subset=['year_creation'])['cg'].value_counts().head(5)
top5_cg = cg_counts.index.tolist()

palette5 = ['#3b0764','#6b21a8','#9333ea','#c084fc','#d97706']

fig, axes = plt.subplots(1, 5, figsize=(22, 6), facecolor=BG)
fig.patch.set_facecolor(BG)

for i, cg in enumerate(top5_cg):
    ax = axes[i]
    ax.set_facecolor(BG)
    country, genre = cg.split('|||')

    sub = df[df['cg'] == cg].dropna(subset=['year_creation'])
    sub = sub[(sub['year_creation'] >= 1970) & (sub['year_creation'] <= 2024)]
    sub_sorted = sub.sort_values('year_creation')
    cumulative = sub_sorted.groupby('year_creation').size().cumsum()

    ax.plot(cumulative.index, cumulative.values, color=palette5[i], linewidth=2)
    ax.fill_between(cumulative.index, cumulative.values, alpha=0.15, color=palette5[i])

    # Find 1st, 5th, 10th release in this cg
    sub_rel = df[(df['cg'] == cg)].dropna(subset=['first_release_year'])
    sub_rel = sub_rel.sort_values('first_release_year')
    milestones = {}
    for n, label in [(1, '1st'), (5, '5th'), (10, '10th')]:
        if len(sub_rel) >= n:
            yr_m = int(sub_rel.iloc[n-1]['first_release_year'])
            milestones[label] = yr_m

    ymax = cumulative.max()
    for label, yr_m in milestones.items():
        if yr_m in cumulative.index or (yr_m >= cumulative.index.min() and yr_m <= cumulative.index.max()):
            ax.axvline(yr_m, color='#dc2626', linestyle='--', linewidth=1, alpha=0.7)
            ax.text(yr_m + 0.5, ymax * 0.5, f'{label}\nrelease', fontsize=6, color='#dc2626', rotation=90)

    ax.set_title(f'{country}\n{genre}', fontweight='bold', fontsize=8)
    ax.set_xlabel('Year', fontsize=8)
    ax.set_ylabel('Cumul. Bands', fontsize=8)
    ax.tick_params(labelsize=7)
    ax.spines[['top','right']].set_visible(False)

fig.suptitle('Cumulative Band Formations — Top 5 Country+Genre Combinations\n(Red dashed: 1st/5th/10th release)', fontweight='bold', fontsize=12)
fig.tight_layout()
fig.savefig(OUT + '07c_event_study.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 07c")
print("Script 07 complete.")
