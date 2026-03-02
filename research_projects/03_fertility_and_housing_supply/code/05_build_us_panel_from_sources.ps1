param(
    [string]$ProjectRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$rawDir = Join-Path $ProjectRoot "data\raw"
$processedDir = Join-Path $ProjectRoot "data\processed"
$notesBuildDir = Join-Path $ProjectRoot "notes\build"

New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
New-Item -ItemType Directory -Force -Path $processedDir | Out-Null
New-Item -ItemType Directory -Force -Path $notesBuildDir | Out-Null

$panelPath = Join-Path $processedDir "us_fertility_housing_panel_v1.csv"
$sourceCoveragePath = Join-Path $notesBuildDir "us_panel_source_coverage.md"
$missingPath = Join-Path $notesBuildDir "us_panel_missingness_report.md"

$finalColumns = @(
    "fips","cbsa","metarea","metareano","state_fips","year",
    "asfr_15_19","asfr_20_24","asfr_25_29","asfr_30_34","asfr_35_39","asfr_40_44","gfr_15_44",
    "first_birth_proxy","completed_fertility_proxy",
    "permits_total_pc","permits_mf_pc","permits_sf_pc","housing_stock_growth","real_house_price_index","real_rent_index","price_to_income",
    "reform_date","event_time","treated","exposure_intensity",
    "female_pop_15_44","native_female_pop_15_44","foreign_born_female_pop_15_44","foreign_born_share_15_44","net_migration_rate","international_migration_rate",
    "unemployment_rate","real_income_pc","college_share","marriage_rate","housing_demand_shifter",
    "source_fertility","source_housing","source_population","source_controls","qa_passed"
)

$sourceSpecs = @(
    @{
        name = "fertility"
        file = Join-Path $rawDir "cdc_fertility_county_year.csv"
        cols = @("fips","cbsa","metarea","metareano","state_fips","year","asfr_15_19","asfr_20_24","asfr_25_29","asfr_30_34","asfr_35_39","asfr_40_44","gfr_15_44","first_birth_proxy","completed_fertility_proxy")
        sourceCol = "source_fertility"
        sourceVal = "cdc"
    },
    @{
        name = "housing"
        file = Join-Path $rawDir "housing_county_year.csv"
        cols = @("fips","cbsa","metarea","metareano","state_fips","year","permits_total_pc","permits_mf_pc","permits_sf_pc","housing_stock_growth","real_house_price_index","real_rent_index","price_to_income","housing_demand_shifter")
        sourceCol = "source_housing"
        sourceVal = "census_fhfa_bls"
    },
    @{
        name = "policy"
        file = Join-Path $rawDir "policy_reforms_county_year.csv"
        cols = @("fips","cbsa","metarea","metareano","state_fips","year","reform_date","event_time","treated","exposure_intensity")
        sourceCol = "source_controls"
        sourceVal = "policy_coding"
    },
    @{
        name = "population_immigration"
        file = Join-Path $rawDir "population_immigration_county_year.csv"
        cols = @("fips","cbsa","metarea","metareano","state_fips","year","female_pop_15_44","native_female_pop_15_44","foreign_born_female_pop_15_44","foreign_born_share_15_44","net_migration_rate","international_migration_rate")
        sourceCol = "source_population"
        sourceVal = "census_pep_acs"
    },
    @{
        name = "controls"
        file = Join-Path $rawDir "controls_county_year.csv"
        cols = @("fips","cbsa","metarea","metareano","state_fips","year","unemployment_rate","real_income_pc","college_share","marriage_rate")
        sourceCol = "source_controls"
        sourceVal = "bls_bea_acs"
    }
)

# Canonical column aliases for compatibility with project-02 (NIMBY) style files.
$columnAliases = @{
    fips = @("fips","FIPS","stcou","STCOU","county_fips","geoid")
    cbsa = @("cbsa","CBSA","msa","MSA","smsa")
    metarea = @("metarea","metaread","metro","msa_code")
    metareano = @("metareano","met2013","metno","metnum")
    state_fips = @("state_fips","statefips","STATEFIPS","stateicp","STATE")
    year = @("year","YEAR","yr")
}

function Get-FieldFromRow {
    param(
        [object]$Row,
        [string]$Canonical
    )
    $props = @($Row.PSObject.Properties.Name)
    if ($props -contains $Canonical) { return [string]$Row.$Canonical }
    if ($columnAliases.ContainsKey($Canonical)) {
        foreach ($a in $columnAliases[$Canonical]) {
            if ($props -contains $a) { return [string]$Row.$a }
        }
    }
    return ""
}

function Read-Source {
    param(
        [hashtable]$Spec
    )

    $exists = Test-Path $Spec.file
    $rows = @()
    $missingCols = @()
    $rowCount = 0

    if ($exists) {
        $rows = @(Import-Csv -Path $Spec.file)
        $rowCount = $rows.Count
        if ($rowCount -gt 0) {
            $headers = @($rows[0].PSObject.Properties.Name)
            $missingCols = @()
            foreach ($c in $Spec.cols) {
                if ($headers -contains $c) { continue }
                if ($columnAliases.ContainsKey($c)) {
                    $aliasHit = $false
                    foreach ($a in $columnAliases[$c]) {
                        if ($headers -contains $a) { $aliasHit = $true; break }
                    }
                    if (-not $aliasHit) { $missingCols += $c }
                } else {
                    $missingCols += $c
                }
            }
        }
    }

    return [pscustomobject]@{
        name = $Spec.name
        file = $Spec.file
        exists = $exists
        row_count = $rowCount
        missing_cols = ($missingCols -join ";")
        rows = $rows
        cols = $Spec.cols
        source_col = $Spec.sourceCol
        source_val = $Spec.sourceVal
    }
}

function Ensure-Record {
    param(
        [hashtable]$Map,
        [string]$Key,
        [string[]]$Columns
    )
    if (-not $Map.ContainsKey($Key)) {
        $rec = [ordered]@{}
        foreach ($c in $Columns) { $rec[$c] = "" }
        $Map[$Key] = $rec
    }
}

function Set-SourceTag {
    param(
        [hashtable]$Rec,
        [string]$SourceCol,
        [string]$SourceVal
    )
    if ([string]::IsNullOrWhiteSpace($SourceCol)) { return }
    if (-not $Rec.Contains($SourceCol)) { return }
    if ([string]::IsNullOrWhiteSpace($Rec[$SourceCol])) {
        $Rec[$SourceCol] = $SourceVal
    } elseif ($Rec[$SourceCol] -notmatch [regex]::Escape($SourceVal)) {
        $Rec[$SourceCol] = "$($Rec[$SourceCol]);$SourceVal"
    }
}

$sourceLoads = @()
foreach ($spec in $sourceSpecs) {
    $sourceLoads += Read-Source -Spec $spec
}

$panelMap = @{}

foreach ($src in $sourceLoads) {
    foreach ($row in $src.rows) {
        $rowFips = Get-FieldFromRow -Row $row -Canonical "fips"
        $rowCbsa = Get-FieldFromRow -Row $row -Canonical "cbsa"
        $rowMetarea = Get-FieldFromRow -Row $row -Canonical "metarea"
        $rowMetareano = Get-FieldFromRow -Row $row -Canonical "metareano"
        $rowYear = Get-FieldFromRow -Row $row -Canonical "year"

        if ([string]::IsNullOrWhiteSpace($rowYear)) { continue }
        if ([string]::IsNullOrWhiteSpace($rowFips) -and [string]::IsNullOrWhiteSpace($rowCbsa) -and [string]::IsNullOrWhiteSpace($rowMetarea) -and [string]::IsNullOrWhiteSpace($rowMetareano)) {
            continue
        }

        $geoKey = ""
        if (-not [string]::IsNullOrWhiteSpace($rowFips)) {
            $geoKey = "fips:$rowFips"
        } elseif (-not [string]::IsNullOrWhiteSpace($rowCbsa)) {
            $geoKey = "cbsa:$rowCbsa"
        } elseif (-not [string]::IsNullOrWhiteSpace($rowMetarea)) {
            $geoKey = "metarea:$rowMetarea"
        } else {
            $geoKey = "metareano:$rowMetareano"
        }
        $key = "$geoKey|$rowYear"
        Ensure-Record -Map $panelMap -Key $key -Columns $finalColumns
        $rec = $panelMap[$key]

        if (-not [string]::IsNullOrWhiteSpace($rowFips)) { $rec["fips"] = $rowFips }
        if (-not [string]::IsNullOrWhiteSpace($rowCbsa)) { $rec["cbsa"] = $rowCbsa }
        if (-not [string]::IsNullOrWhiteSpace($rowMetarea)) { $rec["metarea"] = $rowMetarea }
        if (-not [string]::IsNullOrWhiteSpace($rowMetareano)) { $rec["metareano"] = $rowMetareano }
        if (-not [string]::IsNullOrWhiteSpace($rowYear)) { $rec["year"] = $rowYear }
        $rowState = Get-FieldFromRow -Row $row -Canonical "state_fips"
        if (-not [string]::IsNullOrWhiteSpace($rowState)) { $rec["state_fips"] = $rowState }

        foreach ($c in $src.cols) {
            $v = Get-FieldFromRow -Row $row -Canonical $c
            if (-not [string]::IsNullOrWhiteSpace([string]$v)) {
                if ($rec.Contains($c)) {
                    $rec[$c] = $v
                }
            }
        }
        Set-SourceTag -Rec $rec -SourceCol $src.source_col -SourceVal $src.source_val
    }
}

# Final QA flag.
foreach ($k in $panelMap.Keys) {
    $r = $panelMap[$k]
    $hasGeo = (-not [string]::IsNullOrWhiteSpace($r.fips)) -or (-not [string]::IsNullOrWhiteSpace($r.cbsa)) -or (-not [string]::IsNullOrWhiteSpace($r.metarea)) -or (-not [string]::IsNullOrWhiteSpace($r.metareano))
    $hasId = $hasGeo -and (-not [string]::IsNullOrWhiteSpace($r.year))
    $hasFertility = -not [string]::IsNullOrWhiteSpace($r.gfr_15_44)
    $hasHousing = -not [string]::IsNullOrWhiteSpace($r.real_house_price_index)
    $hasPop = -not [string]::IsNullOrWhiteSpace($r.female_pop_15_44)
    if ($hasId -and $hasFertility -and $hasHousing -and $hasPop) {
        $r.qa_passed = "1"
    } else {
        $r.qa_passed = "0"
    }
}

$records = @()
foreach ($k in ($panelMap.Keys | Sort-Object)) {
    $r = $panelMap[$k]
    $obj = [pscustomobject]([ordered]@{})
    foreach ($c in $finalColumns) {
        Add-Member -InputObject $obj -NotePropertyName $c -NotePropertyValue $r[$c]
    }
    $records += $obj
}

if ($records.Count -eq 0) {
    # Keep schema even when no rows are present.
    $header = $finalColumns -join ","
    Set-Content -Encoding UTF8 -Path $panelPath -Value $header
} else {
    $records | Select-Object $finalColumns | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $panelPath
}

# Source coverage report.
$cov = @(
    "# US panel source coverage",
    "",
    "- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")",
    "- Panel file: data/processed/us_fertility_housing_panel_v1.csv",
    "",
    "| source | file | exists | rows | missing_required_columns |",
    "| --- | --- | --- | ---: | --- |"
)
foreach ($s in $sourceLoads) {
    $miss = if ([string]::IsNullOrWhiteSpace($s.missing_cols)) { "" } else { $s.missing_cols }
    $cov += "| $($s.name) | $($s.file.Replace($ProjectRoot + '\','')) | $($s.exists) | $($s.row_count) | $miss |"
}
$cov | Set-Content -Encoding UTF8 $sourceCoveragePath

# Missingness report.
$rowCount = $records.Count
$missLines = @(
    "# US panel missingness report",
    "",
    "- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")",
    "- Panel file: data/processed/us_fertility_housing_panel_v1.csv",
    "- Row count: $rowCount",
    "",
    "## Variable missingness"
)

if ($rowCount -eq 0) {
    $missLines += ""
    $missLines += "No rows are currently merged. Missingness percentages will be computed after source ingestion."
} else {
    $missLines += ""
    $missLines += "| variable | missing_count | missing_pct |"
    $missLines += "| --- | ---: | ---: |"
    foreach ($c in $finalColumns) {
        $missingCount = 0
        foreach ($r in $records) {
            $v = $r.$c
            if ([string]::IsNullOrWhiteSpace([string]$v)) { $missingCount++ }
        }
        $pct = [math]::Round((100.0 * $missingCount / $rowCount), 2)
        $missLines += "| $c | $missingCount | $pct |"
    }
}
$missLines | Set-Content -Encoding UTF8 $missingPath

Write-Output "Created/updated:"
Write-Output " - $panelPath"
Write-Output " - $sourceCoveragePath"
Write-Output " - $missingPath"
