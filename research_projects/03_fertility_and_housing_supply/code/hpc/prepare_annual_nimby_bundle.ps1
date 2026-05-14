[CmdletBinding()]
param(
    [string]$OutputRoot = "",
    [switch]$SkipTransitionSource,
    [switch]$SkipZip
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    if (-not (Test-Path $PathValue)) {
        New-Item -ItemType Directory -Path $PathValue | Out-Null
    }
}

function Copy-PathIntoBundle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path $SourcePath)) {
        throw "Required source path not found: $SourcePath"
    }

    $destinationParent = Split-Path -Parent $DestinationPath
    if ($destinationParent) {
        Ensure-Directory -PathValue $destinationParent
    }

    Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse -Force
}

function Copy-OptionalPattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDir,
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(Mandatory = $true)]
        [string]$DestinationDir
    )

    if (-not (Test-Path $SourceDir)) {
        return
    }

    $matches = Get-ChildItem -Path $SourceDir -Filter $Pattern -File -ErrorAction SilentlyContinue
    if (-not $matches) {
        return
    }

    Ensure-Directory -PathValue $DestinationDir
    foreach ($match in $matches) {
        Copy-Item -Path $match.FullName -Destination (Join-Path $DestinationDir $match.Name) -Force
    }
}

function Find-ExternalSteadyStateFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    $candidates = @(
        $(if ($env:ZAC_DAVID_EXTERNAL_ROOT) { Join-Path $env:ZAC_DAVID_EXTERNAL_ROOT ("Code\SteadyState\" + $FileName) }),
        ("D:\research_data\zac_and_david\Code\SteadyState\" + $FileName),
        (Join-Path $env:USERPROFILE ("Dropbox\Zac and David\Code\SteadyState\" + $FileName))
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$codeDir = Split-Path -Parent $scriptDir
$projectRoot = Split-Path -Parent $codeDir
$researchProjectsRoot = Split-Path -Parent $projectRoot
$workspaceRoot = Split-Path -Parent $researchProjectsRoot
$upstreamRoot = Join-Path $researchProjectsRoot "02_nimbyism_and_housing_supply"

if (-not (Test-Path $upstreamRoot)) {
    throw "Could not find sibling upstream project at $upstreamRoot"
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $datedRoot = Join-Path $workspaceRoot ("_playground\backups\" + (Get-Date -Format "yyyy-MM-dd"))
    $OutputRoot = Join-Path $datedRoot "03_fertility_and_housing_supply_hpc"
}

Ensure-Directory -PathValue $OutputRoot

$bundleStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$bundleRoot = Join-Path $OutputRoot ("annual_nimby_bundle_" + $bundleStamp)
$project03Dest = Join-Path $bundleRoot "03_fertility_and_housing_supply"
$project02Dest = Join-Path $bundleRoot "02_nimbyism_and_housing_supply"
$externalDest = Join-Path $bundleRoot "external_assets\Code\SteadyState"

Ensure-Directory -PathValue $project03Dest
Ensure-Directory -PathValue $project02Dest

# Core project-03 sources.
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "code") -DestinationPath (Join-Path $project03Dest "code")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "README.md") -DestinationPath (Join-Path $project03Dest "README.md")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "STATUS.md") -DestinationPath (Join-Path $project03Dest "STATUS.md")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "memory.md") -DestinationPath (Join-Path $project03Dest "memory.md")

# Annual NIMBY runtime assets and comparison outputs.
$notesBuildDest = Join-Path $project03Dest "notes\build"
Ensure-Directory -PathValue $notesBuildDest
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "notes\build\TransitionMatrix_annual.mat") -DestinationPath (Join-Path $notesBuildDest "TransitionMatrix_annual.mat")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "notes\build\TransitionMatrix_5y_25_80.mat") -DestinationPath (Join-Path $notesBuildDest "TransitionMatrix_5y_25_80.mat")

$notePatterns = @(
    "nimby_annual_recalibration_stage2*",
    "nimby_local_age_block_periodization*",
    "nimby_annual_housing_access_screen*",
    "nimby_annual_access_followup*",
    "nimby_annual_low_entry_vote_followup*",
    "nimby_annual_low_entry_broad_screen*",
    "nimby_annual_owner_grid_compromise_screen*",
    "annual_fertility_target_ranges*",
    "fertility_annual_broad_calibration_screen*",
    "fertility_annual_timing_stock_screen*",
    "fertility_annual_timing_stock_bridge_screen*",
    "fertility_annual_timing_stock_bridge_theory_note*",
    "fertility_annual_anticipated_price_drift_screen*",
    "acs_homeownership_age_target_review*",
    "annual_homeownership_model_data_comparison*",
    "fertility_annual_re_price_drift_workflow*"
)
foreach ($pattern in $notePatterns) {
    Copy-OptionalPattern -SourceDir (Join-Path $projectRoot "notes\build") -Pattern $pattern -DestinationDir $notesBuildDest
}

# Upstream NIMBY source files used by the annual steady-state runs.
Copy-PathIntoBundle -SourcePath (Join-Path $upstreamRoot "code\steadystate") -DestinationPath (Join-Path $project02Dest "code\steadystate")
Copy-PathIntoBundle -SourcePath (Join-Path $upstreamRoot "code\codes_abb") -DestinationPath (Join-Path $project02Dest "code\codes_abb")

$transitionSource = $null
$benchmarkTransitionSource = $null
if (-not $SkipTransitionSource) {
    $transitionSource = Find-ExternalSteadyStateFile -FileName "nl_zbl.mat"
    if ($transitionSource) {
        Ensure-Directory -PathValue $externalDest
        Copy-Item -Path $transitionSource -Destination (Join-Path $externalDest "nl_zbl.mat") -Force
    }

    $benchmarkTransitionSource = Find-ExternalSteadyStateFile -FileName "TransitionMatrix.mat"
    if ($benchmarkTransitionSource) {
        Ensure-Directory -PathValue $externalDest
        Copy-Item -Path $benchmarkTransitionSource -Destination (Join-Path $externalDest "TransitionMatrix.mat") -Force
    }
}

$activeRunFile = Join-Path $projectRoot "notes\build\logs\active_annual_nimby_away.txt"
$activeRunSummary = "No active annual NIMBY away pointer found."
if (Test-Path $activeRunFile) {
    $activeRunSummary = (Get-Content $activeRunFile -Raw).Trim()
}

$manifestPath = Join-Path $bundleRoot "bundle_manifest.md"
$zipPath = $null

@(
    "# Annual NIMBY HPC bundle"
    ""
    "- Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    '- Bundle root: `' + $bundleRoot + '`'
    '- Project 03 root inside bundle: `03_fertility_and_housing_supply/`'
    '- Project 02 root inside bundle: `02_nimbyism_and_housing_supply/`'
    '- Transition matrices bundled: `TransitionMatrix_annual.mat`, `TransitionMatrix_5y_25_80.mat`'
    '- Bundled `nl_zbl.mat`: ' + $(if ($transitionSource) { 'yes' } else { 'no' })
    '- Bundled upstream `TransitionMatrix.mat`: ' + $(if ($benchmarkTransitionSource) { 'yes' } else { 'no' })
    ""
    "## Included project-03 outputs"
    ""
    '- `notes/build/nimby_annual_recalibration_stage2*`'
    '- `notes/build/nimby_local_age_block_periodization*`'
    '- `notes/build/nimby_annual_housing_access_screen*`'
    '- `notes/build/nimby_annual_access_followup*`'
    '- `notes/build/nimby_annual_low_entry_vote_followup*`'
    '- `notes/build/nimby_annual_low_entry_broad_screen*`'
    '- `notes/build/nimby_annual_owner_grid_compromise_screen*`'
    '- `notes/build/annual_fertility_target_ranges*`'
    '- `notes/build/fertility_annual_broad_calibration_screen*`'
    '- `notes/build/fertility_annual_timing_stock_screen*`'
    '- `notes/build/fertility_annual_timing_stock_bridge_screen*`'
    '- `notes/build/fertility_annual_timing_stock_bridge_theory_note*`'
    '- `notes/build/fertility_annual_anticipated_price_drift_screen*`'
    '- `notes/build/acs_homeownership_age_target_review*`'
    '- `notes/build/annual_homeownership_model_data_comparison*`'
    '- `notes/build/fertility_annual_re_price_drift_workflow*`'
    ""
    "## Current local run pointer at bundle time"
    ""
    '```text'
    $activeRunSummary
    '```'
    ""
    "## Recommended cluster restart"
    ""
    '- full workflow: `bash 03_fertility_and_housing_supply/code/hpc/run_annual_nimby_workflow.sh`'
    '- resume current heavy step only:'
    '- `export START_AT_STEP=4`'
    '- `export END_AT_STEP=4`'
    '- `bash 03_fertility_and_housing_supply/code/hpc/run_annual_nimby_workflow.sh`'
    ""
    "## Notes"
    ""
    '- The staged layout preserves sibling project paths so existing MATLAB `fileparts(project_root)` logic still resolves.'
    '- The prebuilt transition matrices mean the cluster run should not need to rebuild them.'
) | Set-Content -Path $manifestPath

if (-not $SkipZip) {
    $zipPath = $bundleRoot + ".zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    Compress-Archive -Path $bundleRoot -DestinationPath $zipPath -Force
}

$latestPointerPath = Join-Path $OutputRoot "latest_bundle.txt"
@(
    "bundle_root=$bundleRoot"
    "zip_path=$zipPath"
    "manifest_path=$manifestPath"
) | Set-Content -Path $latestPointerPath

Write-Output "Created annual NIMBY HPC bundle:"
Write-Output $bundleRoot
if ($zipPath) {
    Write-Output "Zip archive:"
    Write-Output $zipPath
}
Write-Output "Latest pointer:"
Write-Output $latestPointerPath
