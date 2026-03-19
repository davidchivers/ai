import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import re

OUT = "C:/Users/Dave_/AI/metal archive/"
BG = '#f5f0eb'
PURPLE_MAIN = '#9333ea'

print("Loading data...")
df = pd.read_csv("C:/Users/Dave_/AI/bands_and_first_releases.csv")

# Parse all genre tags: split on '/', ',', ';', and strip parenthetical qualifiers
def parse_tags(g):
    if pd.isna(g):
        return []
    # remove parenthetical content
    g = re.sub(r'\([^)]*\)', '', g)
    # split on / , ;
    parts = re.split(r'[/,;]', g)
    tags = [p.strip().lower() for p in parts if p.strip()]
    return tags

df['tags'] = df['genre'].apply(parse_tags)

# Explode
exploded = df.explode('tags')
exploded = exploded[exploded['tags'].notna() & (exploded['tags'] != '')]

# Tag frequency
tag_counts = exploded['tags'].value_counts()
top25 = tag_counts.head(25)
print(f"Top tag: {top25.index[0]} ({top25.iloc[0]})")

# --- 04a: Bar chart top 25 genre tags ---
print("04a: genre frequency...")
fig, ax = plt.subplots(figsize=(14, 8), facecolor=BG)
ax.set_facecolor(BG)
colors = plt.cm.BuPu(np.linspace(0.3, 0.9, 25))[::-1]
bars = ax.barh(top25.index[::-1], top25.values[::-1], color=colors[::-1], alpha=0.9)
ax.set_title('Top 25 Genre Tags by Band Count', fontweight='bold', fontsize=14)
ax.set_xlabel('Number of Bands')
ax.spines[['top','right']].set_visible(False)
for bar, val in zip(bars, top25.values[::-1]):
    ax.text(bar.get_width() + 50, bar.get_y() + bar.get_height()/2,
            f'{val:,}', va='center', fontsize=8)
fig.tight_layout()
fig.savefig(OUT + '04a_genre_frequency.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 04a")

# --- 04b: Heatmap top 10 genres x top 10 countries ---
print("04b: genre-country heatmap...")
top10_tags = tag_counts.head(10).index.tolist()
top10_countries = df['country'].value_counts().head(10).index.tolist()

# For each band, get its tags and country
# Use primary tag (first tag) for simplicity, but count band once per unique tag
heat = pd.DataFrame(0, index=top10_tags, columns=top10_countries)

sub = exploded[exploded['tags'].isin(top10_tags) & exploded['country'].isin(top10_countries)]
# drop duplicate band_id + tag + country combos
sub = sub.drop_duplicates(subset=['band_id', 'tags', 'country'])
pivot = sub.groupby(['tags', 'country']).size().unstack(fill_value=0)
pivot = pivot.reindex(index=top10_tags, columns=top10_countries, fill_value=0)

fig, ax = plt.subplots(figsize=(14, 7), facecolor=BG)
ax.set_facecolor(BG)
fig.patch.set_facecolor(BG)
im = ax.imshow(pivot.values, cmap='BuPu', aspect='auto')
ax.set_xticks(range(len(top10_countries)))
ax.set_xticklabels(top10_countries, rotation=35, ha='right', fontsize=10)
ax.set_yticks(range(len(top10_tags)))
ax.set_yticklabels(top10_tags, fontsize=10)
cbar = fig.colorbar(im, ax=ax, pad=0.01)
cbar.set_label('Band Count')
cbar.ax.set_facecolor(BG)
ax.set_title('Top 10 Genres × Top 10 Countries — Band Count', fontweight='bold', fontsize=13)
# Annotate cells
for i in range(len(top10_tags)):
    for j in range(len(top10_countries)):
        val = pivot.values[i, j]
        color = 'white' if val > pivot.values.max() * 0.5 else '#1f2937'
        ax.text(j, i, f'{val:,}', ha='center', va='center', fontsize=7, color=color)
fig.tight_layout()
fig.savefig(OUT + '04b_genre_country_heatmap.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 04b")

# --- 04c: Genre tag share over time (smoothed 3yr rolling) ---
print("04c: genre trends...")
top6_tags = tag_counts.head(6).index.tolist()

df_yr = df.dropna(subset=['year_creation'])
df_yr = df_yr[(df_yr['year_creation'] >= 1980) & (df_yr['year_creation'] <= 2024)]
df_yr['year_creation'] = df_yr['year_creation'].astype(int)

# Explode for year analysis
df_yr2 = df_yr.copy()
df_yr2['tags'] = df_yr2['genre'].apply(parse_tags)
exp_yr = df_yr2.explode('tags')
exp_yr = exp_yr[exp_yr['tags'].notna() & (exp_yr['tags'] != '')]

total_by_year = df_yr.groupby('year_creation').size()

tag_by_year = {}
for tag in top6_tags:
    sub = exp_yr[exp_yr['tags'] == tag].drop_duplicates(subset=['band_id','year_creation'])
    c = sub.groupby('year_creation').size()
    share = (c / total_by_year * 100).reindex(total_by_year.index, fill_value=0)
    tag_by_year[tag] = share.rolling(3, center=True, min_periods=1).mean()

palette6 = ['#3b0764','#6b21a8','#9333ea','#c084fc','#059669','#d97706']

fig, ax = plt.subplots(figsize=(14, 6), facecolor=BG)
ax.set_facecolor(BG)
for i, tag in enumerate(top6_tags):
    ax.plot(tag_by_year[tag].index, tag_by_year[tag].values,
            color=palette6[i], linewidth=2, label=tag)
ax.set_title('Top 6 Genre Tags — Share of New Bands per Year\n(3-Year Rolling Average)', fontweight='bold', fontsize=13)
ax.set_xlabel('Year')
ax.set_ylabel('Share of Bands (%)')
ax.spines[['top','right']].set_visible(False)
ax.legend(fontsize=9, loc='upper left')
fig.tight_layout()
fig.savefig(OUT + '04c_genre_trends.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 04c")
print("Script 04 complete.")
