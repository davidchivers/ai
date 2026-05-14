[CmdletBinding()]
param(
    [string]$OutputRoot = "",
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

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$codeDir = Split-Path -Parent $scriptDir
$projectRoot = Split-Path -Parent $codeDir
$researchProjectsRoot = Split-Path -Parent $projectRoot
$workspaceRoot = Split-Path -Parent $researchProjectsRoot

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $datedRoot = Join-Path $workspaceRoot ("_playground\backups\" + (Get-Date -Format "yyyy-MM-dd"))
    $OutputRoot = Join-Path $datedRoot "03_fertility_and_housing_supply_hpc"
}

Ensure-Directory -PathValue $OutputRoot

$bundleStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$bundleRoot = Join-Path $OutputRoot ("annual_transition_mechanism_bundle_" + $bundleStamp)
$projectDest = Join-Path $bundleRoot "03_fertility_and_housing_supply"

Ensure-Directory -PathValue $projectDest
Ensure-Directory -PathValue (Join-Path $projectDest "notes\build")
Ensure-Directory -PathValue (Join-Path $projectDest "code\hpc")

Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "README.md") -DestinationPath (Join-Path $projectDest "README.md")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "STATUS.md") -DestinationPath (Join-Path $projectDest "STATUS.md")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "memory.md") -DestinationPath (Join-Path $projectDest "memory.md")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "code\build_annual_transition_mechanism_scenarios.py") -DestinationPath (Join-Path $projectDest "code\build_annual_transition_mechanism_scenarios.py")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "code\nimby_fertility_transition_bridge.py") -DestinationPath (Join-Path $projectDest "code\nimby_fertility_transition_bridge.py")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "code\hpc\run_annual_transition_mechanism_scenarios.sh") -DestinationPath (Join-Path $projectDest "code\hpc\run_annual_transition_mechanism_scenarios.sh")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "code\hpc\annual_transition_mechanism_scenarios.slurm") -DestinationPath (Join-Path $projectDest "code\hpc\annual_transition_mechanism_scenarios.slurm")
Copy-PathIntoBundle -SourcePath (Join-Path $projectRoot "notes\build\fertility_annual_transition_path_state_grid_mapping_summary.csv") -DestinationPath (Join-Path $projectDest "notes\build\fertility_annual_transition_path_state_grid_mapping_summary.csv")

$manifestPath = Join-Path $bundleRoot "bundle_manifest.md"
$zipPath = $null

@(
    "# Annual transition mechanism Hamilton bundle"
    ""
    "- Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    ('- Bundle root: `' + $bundleRoot + '`')
    "- Contains only the transition bridge packet, not the full annual MATLAB stack."
    ""
    "## Included files"
    ""
    '- `03_fertility_and_housing_supply/code/build_annual_transition_mechanism_scenarios.py`'
    '- `03_fertility_and_housing_supply/code/nimby_fertility_transition_bridge.py`'
    '- `03_fertility_and_housing_supply/code/hpc/run_annual_transition_mechanism_scenarios.sh`'
    '- `03_fertility_and_housing_supply/code/hpc/annual_transition_mechanism_scenarios.slurm`'
    '- `03_fertility_and_housing_supply/notes/build/fertility_annual_transition_path_state_grid_mapping_summary.csv`'
    ""
    "## Recommended submit"
    ""
    '- `sbatch --nice=10000 --export=ALL,PACK=hamilton,OUTPUT_STEM=annual_transition_mechanism_scenarios_hamilton code/hpc/annual_transition_mechanism_scenarios.slurm`'
) | Set-Content -Path $manifestPath

if (-not $SkipZip) {
    $zipPath = $bundleRoot + ".zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    Compress-Archive -Path $bundleRoot -DestinationPath $zipPath -Force
}

$latestPointerPath = Join-Path $OutputRoot "latest_transition_mechanism_bundle.txt"
@(
    "bundle_root=$bundleRoot"
    "zip_path=$zipPath"
    "manifest_path=$manifestPath"
) | Set-Content -Path $latestPointerPath

Write-Output "Created annual transition mechanism Hamilton bundle:"
Write-Output $bundleRoot
if ($zipPath) {
    Write-Output "Zip archive:"
    Write-Output $zipPath
}
Write-Output "Latest pointer:"
Write-Output $latestPointerPath
