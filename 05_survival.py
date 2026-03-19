import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

OUT = "C:/Users/Dave_/AI/metal archive/"
BG = '#f5f0eb'

print("Loading data...")
df = pd.read_csv("C:/Users/Dave_/AI/bands_and_first_releases.csv")

# Normalize status
df['status'] = df['status'].fillna('Unknown')
status_order = ['Active', 'Split-up', 'On hold', 'Changed name', 'Unknown', 'Disputed']
# Only keep statuses that exist
status_order = [s for s in status_order if s in df['status'].unique()]

# Color per status
status_colors = {
    'Active': '#6b21a8',
    'Split-up': '#c084fc',
    'On hold': '#d97706',
    'Changed name': '#059669',
    'Unknown': '#9ca3af',
    'Disputed': '#dc2626',
}

def primary_genre(g):
    if pd.isna(g):
        return 'Unknown'
    return g.strip().split('/')[0].strip()

df['primary_genre'] = df['genre'].apply(primary_genre)

# Decade of formation
df['decade'] = df['year_creation'].apply(
    lambda y: f"{int(y)//10*10}s" if pd.notna(y) else np.nan
)

def stacked_bar_chart(data_col, groups, title, fname, xlabel=''):
    """data_col: the grouping column, groups: ordered list of group labels"""
    fig, ax = plt.subplots(figsize=(13, 6), facecolor=BG)
    ax.set_facecolor(BG)
    fig.patch.set_facecolor(BG)

    pivot = data_col.groupby(data_col.index).value_counts(normalize=True).unstack(fill_value=0)
    # reindex to keep only existing statuses
    pivot = pivot.reindex(columns=[s for s in status_order if s in pivot.columns], fill_value=0)
    pivot = pivot.reindex(groups).dropna(how='all')

    bottom = np.zeros(len(pivot))
    for status in pivot.columns:
        vals = pivot[status].values
        color = status_colors.get(status, '#aaa')
        bars = ax.bar(range(len(pivot)), vals * 100, bottom=bottom, color=color,
                      label=status, width=0.7)
        bottom += vals

    ax.set_xticks(range(len(pivot)))
    ax.set_xticklabels(pivot.index, rotation=30, ha='right', fontsize=10)
    ax.set_ylabel('Share (%)')
    ax.set_xlabel(xlabel)
    ax.set_title(title, fontweight='bold', fontsize=13)
    ax.legend(loc='upper right', fontsize=9)
    ax.set_ylim(0, 105)
    ax.spines[['top','right']].set_visible(False)
    fig.tight_layout()
    fig.savefig(OUT + fname, dpi=150, facecolor=BG)
    plt.close()

# --- 05a: By decade ---
print("05a: by decade...")
df_dec = df.dropna(subset=['decade'])
decades = sorted(df_dec['decade'].unique())
# Filter to sensible range
decades = [d for d in decades if d >= '1960s' and d <= '2020s']
sub = df_dec[df_dec['decade'].isin(decades)].set_index('decade')['status']
stacked_bar_chart(sub, decades, 'Band Status by Decade of Formation', '05a_status_by_decade.png', 'Decade')
print("  Saved 05a")

# --- 05b: By top 8 countries ---
print("05b: by country...")
top8_countries = df['country'].value_counts().head(8).index.tolist()
sub = df[df['country'].isin(top8_countries)].set_index('country')['status']
stacked_bar_chart(sub, top8_countries, 'Band Status by Country (Top 8)', '05b_status_by_country.png', 'Country')
print("  Saved 05b")

# --- 05c: By top 6 genres ---
print("05c: by genre...")
top6_genres = df['primary_genre'].value_counts().head(6).index.tolist()
sub = df[df['primary_genre'].isin(top6_genres)].set_index('primary_genre')['status']
stacked_bar_chart(sub, top6_genres, 'Band Status by Genre (Top 6)', '05c_status_by_genre.png', 'Genre')
print("  Saved 05c")
print("Script 05 complete.")
