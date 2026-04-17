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
OUT_PNG = OUT_DIR / "black_metal_diffusion_snapshots.png"
OUT_MD = DIFFUSION / "black_metal_diffusion_snapshots_summary.md"

SNAPSHOT_YEARS = [1990, 2000]
MARKER_COLOR = "#3f5873"


def _sizeref(values, max_marker=22.0):
    vmax = max(float(max(values)), 1.0)
    return 2.0 * vmax / (max_marker ** 2)


def build():
    panel = pd.read_csv(PANEL_PATH)
    panel = panel[panel["snapshot_year"].isin(SNAPSHOT_YEARS)].copy()
    panel["plot_marker_size"] = np.sqrt(panel["genre_active_bands"].clip(lower=1))
    panel = panel.sort_values(["snapshot_year", "genre_active_bands"], ascending=[True, False])

    sizeref = _sizeref(panel["plot_marker_size"], max_marker=11.5)

    fig = make_subplots(
        rows=2,
        cols=1,
        specs=[[{"type": "geo"}], [{"type": "geo"}]],
        subplot_titles=[str(y) for y in SNAPSHOT_YEARS],
        vertical_spacing=0.08,
    )

    for idx, year in enumerate(SNAPSHOT_YEARS):
        row = idx + 1
        col = 1
        year_df = panel[panel["snapshot_year"] == year]
        fig.add_trace(
            go.Scattergeo(
                lon=year_df["longitude"],
                lat=year_df["latitude"],
                text=year_df["city_country"],
                customdata=year_df[["genre_active_bands", "emergence_year", "first_band_year"]],
                hovertemplate=(
                    "%{text}<br>"
                    "Active bands: %{customdata[0]}<br>"
                    "First band year: %{customdata[2]}<br>"
                    "Emergence year: %{customdata[1]}<extra></extra>"
                ),
                mode="markers",
                marker=dict(
                    size=year_df["plot_marker_size"],
                    sizemode="area",
                    sizeref=sizeref,
                    sizemin=1.2,
                    color=MARKER_COLOR,
                    opacity=0.38,
                    line=dict(color="white", width=0.12),
                ),
                name="Active local band stock",
                legendgroup="active_band_stock",
                showlegend=(idx == 0),
            ),
            row=row,
            col=col,
        )
        fig.update_geos(
            projection_type="natural earth",
            showland=True,
            landcolor="#f4f1e8",
            showcountries=True,
            countrycolor="#bfbfbf",
            showcoastlines=True,
            coastlinecolor="#bfbfbf",
            showocean=True,
            oceancolor="#eef5fb",
            lataxis_range=[-58, 80],
            lonaxis_range=[-170, 190],
            bgcolor="white",
            row=row,
            col=col,
        )

    fig.update_layout(
        width=1380,
        height=1300,
        paper_bgcolor="white",
        plot_bgcolor="white",
        margin=dict(l=20, r=20, t=85, b=20),
        title=dict(
            text="Black metal diffusion snapshots",
            x=0.5,
            xanchor="center",
            font=dict(family="STIX Two Text, STIXGeneral, Times New Roman, serif", size=24),
        ),
        legend=dict(
            orientation="h",
            x=0.5,
            xanchor="center",
            y=1.01,
            yanchor="bottom",
        ),
        font=dict(family="STIX Two Text, STIXGeneral, Times New Roman, serif", size=15, color="#222222"),
    )

    fig.write_image(str(OUT_PNG), scale=2)

    with OUT_MD.open("w", encoding="utf-8") as f:
        f.write("# Black metal diffusion snapshots\n\n")
        f.write("- Figure file: `data/processed/scene_networks/diffusion/figures/black_metal_diffusion_snapshots.png`\n")
        f.write(f"- Snapshot years: {', '.join(str(y) for y in SNAPSHOT_YEARS)}\n")
        f.write("- Layout: two stacked natural-earth world maps for early and later diffusion\n")
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
