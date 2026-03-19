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

# --- 06a: Missingness summary ---
print("06a: missingness...")
miss_summary = []
for col in df.columns:
    n_miss = df[col].isna().sum()
    pct = n_miss / len(df) * 100
    miss_summary.append({'column': col, 'n_missing': n_miss, 'pct_missing': round(pct, 2), 'n_present': len(df) - n_miss})
miss_df = pd.DataFrame(miss_summary)

fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)
ax.set_facecolor(BG)
colors = ['#9333ea' if p > 0 else '#d1d5db' for p in miss_df['pct_missing']]
bars = ax.barh(miss_df['column'], miss_df['pct_missing'], color=colors, alpha=0.85)
for bar, val in zip(bars, miss_df['pct_missing']):
    ax.text(bar.get_width() + 0.3, bar.get_y() + bar.get_height()/2,
            f'{val:.1f}%', va='center', fontsize=9)
ax.set_title('Data Missingness by Column', fontweight='bold', fontsize=13)
ax.set_xlabel('% Missing')
ax.spines[['top','right']].set_visible(False)
ax.set_xlim(0, miss_df['pct_missing'].max() * 1.15)
fig.tight_layout()
fig.savefig(OUT + '06a_missingness.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 06a")

miss_df.to_csv(OUT + '06_data_quality_summary.csv', index=False)
print("  Saved 06_data_quality_summary.csv")

# --- 06b: Missing vs present year_creation — status and genre comparison ---
print("06b: missing vs present...")
df['has_year'] = df['year_creation'].notna()

def primary_genre(g):
    if pd.isna(g):
        return 'Unknown'
    return g.strip().split('/')[0].strip()

df['primary_genre'] = df['genre'].apply(primary_genre)

status_pivot = df.groupby(['has_year','status']).size().unstack(fill_value=0)
status_pivot_pct = status_pivot.div(status_pivot.sum(axis=1), axis=0) * 100

fig, axes = plt.subplots(1, 2, figsize=(14, 6), facecolor=BG)
fig.patch.set_facecolor(BG)

# Status comparison
ax = axes[0]
ax.set_facecolor(BG)
x = np.arange(len(status_pivot_pct.columns))
w = 0.35
colors = ['#9333ea', '#c084fc']
for i, (idx, label) in enumerate([(False, 'year_creation MISSING'), (True, 'year_creation PRESENT')]):
    if idx in status_pivot_pct.index:
        vals = status_pivot_pct.loc[idx]
        ax.bar(x + i*w, vals, w, label=label, color=colors[i], alpha=0.85)
ax.set_xticks(x + w/2)
ax.set_xticklabels(status_pivot_pct.columns, rotation=25, ha='right', fontsize=9)
ax.set_ylabel('Share (%)')
ax.set_title('Status Distribution:\nMissing vs Present year_creation', fontweight='bold', fontsize=11)
ax.legend(fontsize=8)
ax.spines[['top','right']].set_visible(False)

# Genre comparison
ax = axes[1]
ax.set_facecolor(BG)
top8_genres = df['primary_genre'].value_counts().head(8).index.tolist()
genre_pivot = df[df['primary_genre'].isin(top8_genres)].groupby(['has_year','primary_genre']).size().unstack(fill_value=0)
genre_pivot_pct = genre_pivot.div(genre_pivot.sum(axis=1), axis=0) * 100
x = np.arange(len(genre_pivot_pct.columns))
for i, (idx, label) in enumerate([(False, 'year_creation MISSING'), (True, 'year_creation PRESENT')]):
    if idx in genre_pivot_pct.index:
        vals = genre_pivot_pct.loc[idx]
        ax.bar(x + i*w, vals, w, label=label, color=colors[i], alpha=0.85)
ax.set_xticks(x + w/2)
ax.set_xticklabels(genre_pivot_pct.columns, rotation=35, ha='right', fontsize=8)
ax.set_ylabel('Share (%)')
ax.set_title('Genre Distribution:\nMissing vs Present year_creation', fontweight='bold', fontsize=11)
ax.legend(fontsize=8)
ax.spines[['top','right']].set_visible(False)

fig.tight_layout()
fig.savefig(OUT + '06b_missing_vs_present_status.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 06b")

# --- 06c: Partial dates cross-tab ---
print("06c: partial dates...")
def parse_date_parts(s):
    if pd.isna(s):
        return np.nan, np.nan
    parts = str(s).strip().split('-')
    if len(parts) == 3:
        return parts[1], parts[2]  # month, day
    return np.nan, np.nan

df[['rel_month','rel_day']] = pd.DataFrame(df['first_release'].apply(parse_date_parts).tolist(), index=df.index)
df['month_zero'] = df['rel_month'] == '00'
df['day_zero'] = df['rel_day'] == '00'

cross = pd.crosstab(df['month_zero'], df['day_zero'], margins=True)
cross.index = ['Month nonzero', 'Month=00', 'All']
cross.columns = ['Day nonzero', 'Day=00', 'All']

fig, ax = plt.subplots(figsize=(8, 4), facecolor=BG)
ax.set_facecolor(BG)
ax.axis('off')
tbl = ax.table(cellText=cross.values.tolist(),
               rowLabels=cross.index.tolist(),
               colLabels=cross.columns.tolist(),
               cellLoc='center', loc='center')
tbl.auto_set_font_size(False)
tbl.set_fontsize(11)
tbl.scale(1.5, 2)
# Style header
for (row, col), cell in tbl.get_celld().items():
    cell.set_facecolor(BG)
    if row == 0 or col == -1:
        cell.set_facecolor('#e9d5ff')
        cell.set_text_props(fontweight='bold')
ax.set_title('Cross-tab: Zero Month vs Zero Day in first_release', fontweight='bold', fontsize=12, pad=20)
fig.tight_layout()
fig.savefig(OUT + '06c_partial_dates.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 06c")

# --- 06d: year_creation vs first year in years_active ---
print("06d: year discrepancy...")
def first_year_active(s):
    if pd.isna(s):
        return np.nan
    m = re.search(r'\b(1[89]\d{2}|20\d{2})\b', str(s))
    return int(m.group()) if m else np.nan

df['first_active_year'] = df['years_active'].apply(first_year_active)
df_both = df.dropna(subset=['year_creation','first_active_year'])
df_both['year_diff'] = df_both['year_creation'] - df_both['first_active_year']
# Filter to reasonable range
df_both = df_both[(df_both['year_diff'] >= -10) & (df_both['year_diff'] <= 10)]
print(f"  year_diff range: {df_both['year_diff'].min()} to {df_both['year_diff'].max()}, n={len(df_both)}")

fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)
ax.set_facecolor(BG)
ax.hist(df_both['year_diff'], bins=range(-10, 12), color=PURPLE_MAIN, alpha=0.85, edgecolor='white', linewidth=0.5)
ax.axvline(0, color='#3b0764', linestyle='--', linewidth=1.5, label='No discrepancy')
ax.set_title('Discrepancy: year_creation − First Year in years_active', fontweight='bold', fontsize=13)
ax.set_xlabel('Difference (years)')
ax.set_ylabel('Number of Bands')
ax.spines[['top','right']].set_visible(False)
ax.legend()
fig.tight_layout()
fig.savefig(OUT + '06d_year_discrepancy.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 06d")
print("Script 06 complete.")
