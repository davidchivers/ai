param(
    [string]$ProjectRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$processedDir = Join-Path $ProjectRoot "data\processed"
$notesBuildDir = Join-Path $ProjectRoot "notes\build"
$panelPath = Join-Path $processedDir "us_fertility_housing_panel_v1.csv"
$dictPath = Join-Path $notesBuildDir "us_panel_data_dictionary.md"
$missingPath = Join-Path $notesBuildDir "us_panel_missingness_report.md"

New-Item -ItemType Directory -Force -Path $processedDir | Out-Null
New-Item -ItemType Directory -Force -Path $notesBuildDir | Out-Null

$columns = @(
    "fips",
    "cbsa",
    "metarea",
    "metareano",
    "state_fips",
    "year",
    "asfr_15_19",
    "asfr_20_24",
    "asfr_25_29",
    "asfr_30_34",
    "asfr_35_39",
    "asfr_40_44",
    "gfr_15_44",
    "first_birth_proxy",
    "completed_fertility_proxy",
    "permits_total_pc",
    "permits_mf_pc",
    "permits_sf_pc",
    "housing_stock_growth",
    "real_house_price_index",
    "real_rent_index",
    "price_to_income",
    "reform_date",
    "event_time",
    "treated",
    "exposure_intensity",
    "female_pop_15_44",
    "native_female_pop_15_44",
    "foreign_born_female_pop_15_44",
    "foreign_born_share_15_44",
    "net_migration_rate",
    "international_migration_rate",
    "unemployment_rate",
    "real_income_pc",
    "college_share",
    "marriage_rate",
    "housing_demand_shifter",
    "source_fertility",
    "source_housing",
    "source_population",
    "source_controls",
    "qa_passed"
)

# Write header-only CSV scaffold.
$columns -join "," | Set-Content -Encoding UTF8 $panelPath

$generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$dictLines = @(
    "# US panel data dictionary",
    "",
    "- Generated: $generated",
    "- Panel file: data/processed/us_fertility_housing_panel_v1.csv",
    "",
    "## Key identifiers",
    "",
    "| variable | type | description |",
    "| --- | --- | --- |",
    "| fips | string | county FIPS code (preferred local key) |",
    "| cbsa | string | CBSA code (fallback local key) |",
    "| metarea | string | NIMBY-project metro identifier (legacy compatibility) |",
    "| metareano | string | NIMBY-project metro numeric identifier (legacy compatibility) |",
    "| state_fips | string | state FIPS code |",
    "| year | int | calendar year |",
    "",
    "## Fertility outcomes",
    "",
    "| variable | type | description |",
    "| --- | --- | --- |",
    "| asfr_15_19 | float | age-specific fertility rate, ages 15-19 |",
    "| asfr_20_24 | float | age-specific fertility rate, ages 20-24 |",
    "| asfr_25_29 | float | age-specific fertility rate, ages 25-29 |",
    "| asfr_30_34 | float | age-specific fertility rate, ages 30-34 |",
    "| asfr_35_39 | float | age-specific fertility rate, ages 35-39 |",
    "| asfr_40_44 | float | age-specific fertility rate, ages 40-44 |",
    "| gfr_15_44 | float | general fertility rate, ages 15-44 |",
    "| first_birth_proxy | float | first-birth share/proxy where available |",
    "| completed_fertility_proxy | float | cohort-completed fertility proxy |",
    "",
    "## Housing outcomes",
    "",
    "| variable | type | description |",
    "| --- | --- | --- |",
    "| permits_total_pc | float | total permits per capita |",
    "| permits_mf_pc | float | multifamily permits per capita |",
    "| permits_sf_pc | float | single-family permits per capita |",
    "| housing_stock_growth | float | annual housing stock growth rate |",
    "| real_house_price_index | float | real house price index |",
    "| real_rent_index | float | real rent index |",
    "| price_to_income | float | price to income ratio |",
    "",
    "## Policy timing",
    "",
    "| variable | type | description |",
    "| --- | --- | --- |",
    "| reform_date | string | policy reform effective date |",
    "| event_time | int | years relative to reform date |",
    "| treated | int | treated indicator (0/1) |",
    "| exposure_intensity | float | ex-ante reform bite/intensity |",
    "",
    "## Demographics and immigration",
    "",
    "| variable | type | description |",
    "| --- | --- | --- |",
    "| female_pop_15_44 | float | female population ages 15-44 |",
    "| native_female_pop_15_44 | float | native-born female population ages 15-44 |",
    "| foreign_born_female_pop_15_44 | float | foreign-born female population ages 15-44 |",
    "| foreign_born_share_15_44 | float | foreign-born share in female 15-44 population |",
    "| net_migration_rate | float | net migration rate |",
    "| international_migration_rate | float | international migration rate |",
    "",
    "## Controls and metadata",
    "",
    "| variable | type | description |",
    "| --- | --- | --- |",
    "| unemployment_rate | float | unemployment rate |",
    "| real_income_pc | float | real income per capita |",
    "| college_share | float | share college educated |",
    "| marriage_rate | float | marriage rate (if available) |",
    "| housing_demand_shifter | float | demand shifter summary variable |",
    "| source_fertility | string | source tag for fertility fields |",
    "| source_housing | string | source tag for housing fields |",
    "| source_population | string | source tag for population/immigration fields |",
    "| source_controls | string | source tag for controls |",
    "| qa_passed | int | quality check pass flag (0/1) |",
    "",
    "## Build note",
    "",
    "This is a schema scaffold. Data rows are not loaded yet."
)

$dictLines | Set-Content -Encoding UTF8 $dictPath

$missingLines = @(
    "# US panel missingness report",
    "",
    "- Generated: $generated",
    "- Panel file: data/processed/us_fertility_housing_panel_v1.csv",
    "",
    "## Current status",
    "",
    "- This is a scaffold-only build.",
    "- Row count: 0",
    "- Missingness rates are not computed yet because no source data are merged.",
    "",
    "## Planned checks after first merge",
    "",
    "1. Coverage by year and geography (county, MSA, state).",
    "2. Missingness by variable block:",
    "   - fertility outcomes",
    "   - housing outcomes",
    "   - policy timing",
    "   - immigration/demographics",
    "   - controls",
    "3. Structural breaks from geography boundary changes.",
    "4. Outlier and impossible-value checks.",
    "",
    "## Required follow-up outputs",
    "",
    "1. Variable-level missingness table with percentages.",
    "2. Heatmap of missingness by year.",
    "3. Data retention summary under baseline sample restrictions."
)

$missingLines | Set-Content -Encoding UTF8 $missingPath

Write-Output "Created:"
Write-Output " - $panelPath"
Write-Output " - $dictPath"
Write-Output " - $missingPath"
