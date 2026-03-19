import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import geopandas as gpd
import zipfile, urllib.request, os, tempfile

OUT = "C:/Users/Dave_/AI/metal archive/"
BG = '#f5f0eb'

print("Loading data...")
df = pd.read_csv("C:/Users/Dave_/AI/bands_and_first_releases.csv")

def parse_release_year(s):
    if pd.isna(s):
        return np.nan
    parts = str(s).strip().split('-')
    try:
        return int(parts[0])
    except:
        return np.nan

df['first_release_year'] = df['first_release'].apply(parse_release_year)

# Earliest first release year per country
earliest = df.groupby('country')['first_release_year'].min().reset_index()
earliest.columns = ['country', 'earliest_release_year']
earliest = earliest.dropna(subset=['earliest_release_year'])
print(f"Countries with release data: {len(earliest)}")

# Country name mapping (dataset -> shapefile)
name_map = {
    'United States': 'United States of America',
    'United Kingdom': 'United Kingdom',
    'Russia': 'Russia',
    'Czechia': 'Czechia',
    'Türkiye': 'Turkey',
    'South Korea': 'South Korea',
    'North Korea': 'North Korea',
    'Bosnia and Herzegovina': 'Bosnia and Herz.',
    'Dominican Republic': 'Dominican Rep.',
    'Ivory Coast': "Côte d'Ivoire",
    'Democratic Republic of the Congo': 'Dem. Rep. Congo',
    'Republic of the Congo': 'Congo',
    'Macedonia': 'North Macedonia',
    'Moldova': 'Moldova',
    'Myanmar': 'Myanmar',
    'Laos': 'Laos',
    'Palestine': 'Palestine',
    'UAE': 'United Arab Emirates',
    'International': None,
}

earliest['shp_name'] = earliest['country'].apply(lambda x: name_map.get(x, x))
earliest = earliest[earliest['shp_name'].notna()]

# Download shapefile
shp_url = "https://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_countries.zip"
shp_cache = "C:/Users/Dave_/AI/ne_110m_admin_0_countries.zip"
if not os.path.exists(shp_cache):
    print("Downloading shapefile...")
    urllib.request.urlretrieve(shp_url, shp_cache)
    print("Downloaded.")
else:
    print("Using cached shapefile.")

tmp_dir = tempfile.mkdtemp()
with zipfile.ZipFile(shp_cache, 'r') as z:
    z.extractall(tmp_dir)

shp_files = [f for f in os.listdir(tmp_dir) if f.endswith('.shp')]
print("Shapefile:", shp_files)
world = gpd.read_file(os.path.join(tmp_dir, shp_files[0]))
print("World shape cols:", world.columns.tolist()[:10])

# Merge
world = world.merge(earliest, left_on='NAME', right_on='shp_name', how='left')

# --- 03a: Choropleth ---
print("03a: diffusion map...")
fig, ax = plt.subplots(figsize=(18, 9), facecolor=BG)
ax.set_facecolor(BG)
fig.patch.set_facecolor(BG)

# Countries without data in light grey
world_no_data = world[world['earliest_release_year'].isna()]
world_data = world[world['earliest_release_year'].notna()]

world_no_data.plot(ax=ax, color='#d1d5db', edgecolor='white', linewidth=0.3)

cmap = plt.cm.get_cmap('BuPu')
norm = mcolors.Normalize(vmin=world_data['earliest_release_year'].min(),
                          vmax=world_data['earliest_release_year'].max())
world_data.plot(ax=ax, column='earliest_release_year', cmap=cmap, norm=norm,
                edgecolor='white', linewidth=0.3)

sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
sm.set_array([])
cbar = fig.colorbar(sm, ax=ax, fraction=0.02, pad=0.01, shrink=0.7)
cbar.set_label('Year of Earliest Metal Release', fontsize=10)
cbar.ax.set_facecolor(BG)

ax.set_title('Year Metal Arrived — Earliest Known First Release by Country', fontweight='bold', fontsize=14)
ax.axis('off')
fig.tight_layout()
fig.savefig(OUT + '03a_diffusion_map.png', dpi=150, facecolor=BG, bbox_inches='tight')
plt.close()
print("  Saved 03a")

# --- 03b: Cumulative countries with >= 1 band by year ---
print("03b: cumulative countries...")
# For each band with a first_release_year, get country+year
band_yr = df[['country','first_release_year']].dropna(subset=['first_release_year'])
band_yr = band_yr[band_yr['country'] != 'International']
band_yr['first_release_year'] = band_yr['first_release_year'].astype(int)

# First appearance year per country
first_per_country = band_yr.groupby('country')['first_release_year'].min()
year_range = range(int(first_per_country.min()), 2026)

cumulative = []
for yr in year_range:
    n = (first_per_country <= yr).sum()
    cumulative.append((yr, n))

cum_df = pd.DataFrame(cumulative, columns=['year','n_countries'])

fig, ax = plt.subplots(figsize=(12, 5), facecolor=BG)
ax.set_facecolor(BG)
ax.plot(cum_df['year'], cum_df['n_countries'], color='#6b21a8', linewidth=2.5)
ax.fill_between(cum_df['year'], cum_df['n_countries'], alpha=0.15, color='#9333ea')
ax.set_title('Cumulative Number of Countries with at Least 1 Metal Band\n(by Year of First Release)', fontweight='bold', fontsize=13)
ax.set_xlabel('Year')
ax.set_ylabel('Number of Countries')
ax.spines[['top','right']].set_visible(False)
fig.tight_layout()
fig.savefig(OUT + '03b_cumulative_countries.png', dpi=150, facecolor=BG)
plt.close()
print("  Saved 03b")
print("Script 03 complete.")
