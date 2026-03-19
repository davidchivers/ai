import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

OUT = "C:/Users/Dave_/AI/metal archive/"
BG = '#f5f0eb'
PURPLE_MAIN = '#9333ea'

print("Loading data...")
df = pd.read_csv("C:/Users/Dave_/AI/bands_and_first_releases.csv")

# Parse first_release year
def parse_release_year(s):
    if pd.isna(s):
        return np.nan
    s = str(s).strip()
    # format: YYYY-MM-DD or YYYY-00-00
    parts = s.split('-')
    if len(parts) >= 1:
        try:
            return int(parts[0])
        except:
            return np.nan
    return np.nan

df['first_release_year'] = df['first_release'].apply(parse_release_year)

# Compute lag
df['lag'] = df['first_release_year'] - df['year_creation']

# Drop outliers: negatives > 5 and positives > 30
df_lag = df.dropna(subset=['lag'])
df_lag = df_lag[(df_lag['lag'] >= -5) & (df_lag['lag'] <= 30)]
print(f"Lag dataset: {len(df_lag)} rows after filtering")

# Parse primary genre
def primary_genre(g):
    if pd.isna(g):
        return 'Unknown'
    return g.strip().split('/')[0].strip()

df_lag['primary_genre'] = df_lag['genre'].apply(primary_genre)

# --- 02a: Overall lag distribution ---
print("02a: lag distribution...")
fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)
ax.set_facecolor(BG)
ax.hist(df_lag['lag'], bins=range(-5, 32), color=PURPLE_MAIN, alpha=0.85, edgecolor='white', linewidth=0.5)
ax.set_title('Distribution of Release Lag\n(First Release Year − Formation Year)', fontweight='bold', fontsize=13)
ax.set_xlabel('Lag (years)')
ax.set_ylabel('Number of Bands')
ax.spines[['top','right']].set_visible(False)
median_lag = df_lag['lag'].median()
ax.axvline(median_lag, color='#3b0764', linestyle='--', linewidth=1.5, label=f'Median = {median_lag:.1f} yr')
ax.legend()
fig.tight_layout()
fig.savefig(OUT + '02a_lag_distribution.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 02a")

# --- 02b: Lag by top genre ---
print("02b: lag by genre...")
top_genres = df_lag['primary_genre'].value_counts().head(6).index.tolist()
palette6 = ['#3b0764','#6b21a8','#9333ea','#c084fc','#059669','#d97706']

fig, axes = plt.subplots(2, 3, figsize=(16, 9), facecolor=BG)
axes = axes.flatten()
for i, genre in enumerate(top_genres):
    ax = axes[i]
    ax.set_facecolor(BG)
    sub = df_lag[df_lag['primary_genre'] == genre]['lag']
    ax.hist(sub, bins=range(-5, 32), color=palette6[i], alpha=0.85, edgecolor='white', linewidth=0.5)
    med = sub.median()
    ax.axvline(med, color='#1f2937', linestyle='--', linewidth=1.2, label=f'Median={med:.1f}')
    ax.set_title(genre, fontweight='bold', fontsize=11)
    ax.set_xlabel('Lag (years)')
    ax.set_ylabel('Bands')
    ax.spines[['top','right']].set_visible(False)
    ax.legend(fontsize=8)

fig.suptitle('Release Lag Distribution — Top 6 Genres', fontweight='bold', fontsize=14)
fig.patch.set_facecolor(BG)
fig.tight_layout()
fig.savefig(OUT + '02b_lag_by_genre.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 02b")
print("Script 02 complete.")
