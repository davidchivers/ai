from pathlib import Path

import numpy as np
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots


ROOT = Path(r"C:\Users\Dave_\AI\research_ideas\metal")
DIFFUSION = ROOT / "data" / "processed" / "scene_networks" / "diffusion"
OUT_DIR = DIFFUSION / "figures"
OUT_DIR.mkdir(parents=True, exist_ok=True)

PANEL_PATH = DIFFUSION / "black_metal_scene_diffusion_panel.csv"
OUT_PNG = OUT_DIR / "black_metal_diffusion_snapshots_flat.png"
OUT_MD = DIFFUSION / "black_metal_diffusion_snapshots_flat_summary.md"

SNAPSHOT_YEARS = [1990, 1995, 2000, 2010]
MARKER_COLOR = "#8c1d18"


def _sizeref(values, max_marker=26.0):
    vmax = max(float(max(values)), 1.0)
    return 2.0 * vmax / (max_marker ** 2)


def build():
    panel = pd.read_csv(PANEL_PATH)
    panel = panel[panel["snapshot_year"].isin(SNAPSHOT_YEARS)].copy()
    panel["plot_marker_size"] = np.sqrt(panel["genre_active_bands"].clip(lower=1))
    panel = panel.sort_values(["snapshot_year", "genre_active_bands"], ascending=[True, False])

    sizeref = _sizeref(panel["plot_marker_size"], max_marker=17.0)

    fig = make_subplots(
        rows=2,
        cols=2,
        specs=[[{"type": "geo"}, {"type": "geo"}], [{"type": "geo"}, {"type": "geo"}]],
        subplot_titles=[str(y) for y in SNAPSHOT_YEARS],
        horizontal_spacing=0.035,
        vertical_spacing=0.07,
    )

    for idx, year in enumerate(SNAPSHOT_YEARS):
        row = idx // 2 + 1
        col = idx % 2 + 1
        year_df = panel[panel["snapshot_year"] == year]
        fig.add_trace(
            go.Scattergeo(
                lon=year_df["longitude"],
                lat=year_df["latitude"],
                text=year_df["city_country"],
                customdata=year_df[["genre_active_bands", "first_band_year", "emergence_year"]],
                hovertemplate=(
                    "%{text}<br>"
                    "Active bands: %{customdata[0]}<br>"
                    "First band year: %{customdata[1]}<br>"
                    "Emergence year: %{customdata[2]}<extra></extra>"
                ),
                mode="markers",
                marker=dict(
                    size=year_df["plot_marker_size"],
                    sizemode="area",
                    sizeref=sizeref,
                    sizemin=1.8,
                    color=MARKER_COLOR,
                    opacity=0.58,
                    line=dict(color="white", width=0.2),
                ),
                name="Active local band stock",
                legendgroup="active_band_stock",
                showlegend=(idx == 0),
            ),
            row=row,
            col=col,
        )
        fig.update_geos(
            projection_type="equirectangular",
            showland=True,
            landcolor="#fcfbf7",
            showcountries=True,
            countrycolor="#cccccc",
            showcoastlines=True,
            coastlinecolor="#c4c4c4",
            showocean=False,
            showframe=False,
            lataxis_range=[-58, 80],
            lonaxis_range=[-170, 190],
            bgcolor="white",
            row=row,
            col=col,
        )

    fig.update_layout(
        width=1700,
        height=1080,
        paper_bgcolor="white",
        plot_bgcolor="white",
        margin=dict(l=20, r=20, t=85, b=20),
        title=dict(text="Black metal diffusion snapshots", x=0.5, xanchor="center"),
        legend=dict(
            orientation="h",
            x=0.5,
            xanchor="center",
            y=1.01,
            yanchor="bottom",
        ),
        font=dict(size=15),
    )

    fig.write_image(str(OUT_PNG), scale=1.5)

    with OUT_MD.open("w", encoding="utf-8") as f:
        f.write("# Black metal diffusion snapshots flat map\n\n")
        f.write("- Figure file: `data/processed/scene_networks/diffusion/figures/black_metal_diffusion_snapshots_flat.png`\n")
        f.write(f"- Snapshot years: {', '.join(str(y) for y in SNAPSHOT_YEARS)}\n")
        f.write("- Layout: four-panel flat world map using an equirectangular projection\n")
        f.write("- Marker size: square-root scaled active local black-metal bands in the city-year\n")
        f.write("- Marker color: single-color map showing active local black-metal bands only\n\n")
        f.write("## Snapshot counts\n\n")
        for year in SNAPSHOT_YEARS:
            year_df = panel[panel["snapshot_year"] == year]
            active = int(len(year_df))
            bands = int(year_df["genre_active_bands"].sum())
            f.write(f"- {year}: {active} active matched cities, {bands} active bands\n")


if __name__ == "__main__":
    build()
