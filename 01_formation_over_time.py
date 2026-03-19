import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

OUT = "C:/Users/Dave_/AI/metal archive/"
BG = '#f5f0eb'
PURPLE_MAIN = '#9333ea'
PURPLES = ['#3b0764','#6b21a8','#9333ea','#c084fc','#e9d5ff','#f3e8ff','#a855f7','#7c3aed']

print("Loading data...")
df = pd.read_csv("C:/Users/Dave_/AI/bands_and_first_releases.csv")

# Parse primary genre: first word/token before '/' or ' '
def primary_genre(g):
    if pd.isna(g):
        return 'Unknown'
    g = g.strip()
    # split on / first
    g = g.split('/')[0].strip()
    return g

df['primary_genre'] = df['genre'].apply(primary_genre)

# --- 01a: Total bands formed per year ---
print("01a: total formation...")
yr = df.dropna(subset=['year_creation'])
yr = yr[(yr['year_creation'] >= 1960) & (yr['year_creation'] <= 2025)]
counts = yr.groupby('year_creation').size()

fig, ax = plt.subplots(figsize=(12, 5), facecolor=BG)
ax.set_facecolor(BG)
ax.bar(counts.index, counts.values, color=PURPLE_MAIN, width=0.8, alpha=0.85)
ax.set_title('Metal Bands Formed Per Year', fontweight='bold', fontsize=14)
ax.set_xlabel('Year of Formation')
ax.set_ylabel('Number of Bands')
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x):,}'))
ax.spines[['top','right']].set_visible(False)
ax.set_facecolor(BG)
fig.tight_layout()
fig.savefig(OUT + '01a_formation_total.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 01a")

# --- 01b: By top 6 genres ---
print("01b: by genre...")
top_genres = df['primary_genre'].value_counts().head(6).index.tolist()
palette6 = ['#3b0764','#6b21a8','#9333ea','#c084fc','#059669','#d97706']

fig, axes = plt.subplots(2, 3, figsize=(16, 9), facecolor=BG)
axes = axes.flatten()
for i, genre in enumerate(top_genres):
    ax = axes[i]
    ax.set_facecolor(BG)
    sub = yr[yr['primary_genre'] == genre]
    c = sub.groupby('year_creation').size()
    ax.bar(c.index, c.values, color=palette6[i], width=0.8, alpha=0.85)
    ax.set_title(genre, fontweight='bold', fontsize=11)
    ax.set_xlabel('Year')
    ax.set_ylabel('Bands')
    ax.spines[['top','right']].set_visible(False)
    ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x):,}'))

fig.suptitle('Band Formations Per Year — Top 6 Genres', fontweight='bold', fontsize=14)
fig.patch.set_facecolor(BG)
fig.tight_layout()
fig.savefig(OUT + '01b_formation_by_genre.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 01b")

# --- 01c: By top 8 countries ---
print("01c: by country...")
top_countries = df['country'].value_counts().head(8).index.tolist()
palette8 = ['#3b0764','#6b21a8','#9333ea','#c084fc','#059669','#d97706','#dc2626','#0284c7']

fig, axes = plt.subplots(2, 4, figsize=(20, 8), facecolor=BG)
axes = axes.flatten()
for i, country in enumerate(top_countries):
    ax = axes[i]
    ax.set_facecolor(BG)
    sub = yr[yr['country'] == country]
    c = sub.groupby('year_creation').size()
    ax.bar(c.index, c.values, color=palette8[i], width=0.8, alpha=0.85)
    ax.set_title(country, fontweight='bold', fontsize=11)
    ax.set_xlabel('Year')
    ax.set_ylabel('Bands')
    ax.spines[['top','right']].set_visible(False)
    ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x):,}'))

fig.suptitle('Band Formations Per Year — Top 8 Countries', fontweight='bold', fontsize=14)
fig.patch.set_facecolor(BG)
fig.tight_layout()
fig.savefig(OUT + '01c_formation_by_country.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 01c")
print("Script 01 complete.")
