import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
from matplotlib.colors import LinearSegmentedColormap
import numpy as np

# ── Load data ──────────────────────────────────────────────────────────────
df = pd.read_csv('C:/Users/Dave_/AI/bands_and_first_releases.csv')
counts = df['country'].value_counts().reset_index()
counts.columns = ['country', 'n_bands']

# ── Load world shapefile ───────────────────────────────────────────────────
world = gpd.read_file(
    'https://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_countries.zip'
)

# ── Name mapping: Metal Archive → Natural Earth NAME ──────────────────────
name_map = {
    'United States':     'United States of America',
    'United Kingdom':    'United Kingdom',
    'Russia':            'Russia',
    'Czechia':           'Czechia',
    'Türkiye':           'Turkey',
    'South Korea':       'South Korea',
    'North Korea':       'North Korea',
    'Bosnia and Herzegovina': 'Bosnia and Herz.',
    'Dominican Republic': 'Dominican Rep.',
    'Trinidad and Tobago': 'Trinidad and Tobago',
    'El Salvador':       'El Salvador',
    'Costa Rica':        'Costa Rica',
    'Puerto Rico':       'Puerto Rico',
    'Ivory Coast':       "Côte d'Ivoire",
    'Democratic Republic of the Congo': 'Dem. Rep. Congo',
    'Republic of the Congo': 'Congo',
    'Macedonia':         'North Macedonia',
    'Moldova':           'Moldova',
    'Myanmar':           'Myanmar',
    'Laos':              'Laos',
    'Palestine':         'Palestine',
    'UAE':               'United Arab Emirates',
    'International':     None,  # skip
}

counts['ne_name'] = counts['country'].apply(
    lambda x: name_map.get(x, x) if name_map.get(x, x) is not None else None
)
counts = counts[counts['ne_name'].notna()]

# ── Merge with world ───────────────────────────────────────────────────────
world = world.merge(counts, left_on='NAME', right_on='ne_name', how='left')

# Per-capita: bands per million people
world['bands_per_mil'] = world['n_bands'] / (world['POP_EST'] / 1e6)

# ── Plotting function ──────────────────────────────────────────────────────
def make_map(ax, col, title, cmap, label, log=True):
    world_plot = world[world['NAME'] != 'Antarctica'].copy()
    if log:
        vals = np.log10(world_plot[col].replace(0, np.nan))
    else:
        vals = world_plot[col]

    world_plot['_val'] = vals

    # no-data countries in light grey
    world_plot[world_plot['_val'].isna()].plot(
        ax=ax, color='#d4d4d4', edgecolor='white', linewidth=0.3
    )
    # countries with data
    world_plot[world_plot['_val'].notna()].plot(
        ax=ax, column='_val', cmap=cmap,
        edgecolor='white', linewidth=0.3,
        legend=False
    )

    ax.set_title(title, fontsize=14, fontweight='bold', pad=10)
    ax.set_axis_off()

    # colorbar
    sm = plt.cm.ScalarMappable(
        cmap=cmap,
        norm=mcolors.Normalize(vmin=vals.min(), vmax=vals.max())
    )
    sm.set_array([])
    cbar = plt.colorbar(sm, ax=ax, orientation='horizontal',
                        fraction=0.03, pad=0.02, aspect=40)
    if log:
        ticks = np.arange(np.floor(vals.min()), np.ceil(vals.max()) + 1)
        cbar.set_ticks(ticks)
        cbar.set_ticklabels([f'{10**t:,.0f}' for t in ticks])
    cbar.set_label(label, fontsize=9)


# ── Draw ───────────────────────────────────────────────────────────────────
fig, axes = plt.subplots(2, 1, figsize=(16, 14), facecolor='#f5f0eb')

# Purple scale for both maps
cmap_purple = LinearSegmentedColormap.from_list(
    'metal_purple',
    ['#f2e8ff', '#c084fc', '#9333ea', '#6b21a8', '#3b0764']
)

make_map(axes[0], 'n_bands',
         'Metal Bands by Country (Total)',
         cmap_purple, 'Number of bands (log scale)', log=True)

make_map(axes[1], 'bands_per_mil',
         'Metal Bands per Million People',
         cmap_purple, 'Bands per million population (log scale)', log=True)

fig.suptitle('Metal Archive – Band Geography', fontsize=17, fontweight='bold', y=0.98)
plt.tight_layout()
plt.savefig('C:/Users/Dave_/AI/metal_maps.png', dpi=150, bbox_inches='tight', facecolor='#f5f0eb')
print('Saved metal_maps.png')
