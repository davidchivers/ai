<#
.SYNOPSIS
Moves root-level LaTeX technical files out of visible drafts/slides folders.

.DESCRIPTION
For each project under `research_projects/`, this script enforces a cleaner view:
- Keep latest `.lyx` and `.pdf` in `drafts/` and `slides/`.
- Move root-level technical source files (`.tex`, `.sty`, `.cls`, `.bst`) into:
  - `drafts/old_drafts/source_tex/`
  - `slides/old_slides/source_tex/`
- Move root-level LaTeX build artifacts into:
  - `drafts/old_drafts/build_artifacts/`
  - `slides/old_slides/build_artifacts/`

It only targets lowercase `drafts/` and `slides/` folders.

.PARAMETER RepoRoot
Repository root path. Defaults to two levels above this script.

.PARAMETER DryRun
Show planned moves without changing files.

.EXAMPLE
./_shared/scripts/hide_tex_and_artifacts.ps1

.EXAMPLE
./_shared/scripts/hide_tex_and_artifacts.ps1 -DryRun
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectsRoot = Join-Path $RepoRoot "research_projects"
if (-not (Test-Path -LiteralPath $projectsRoot)) {
    throw "research_projects/ folder not found under: $RepoRoot"
}

$artifactNames = @(
    ".aux",
    ".bbl",
    ".blg",
    ".brf",
    ".log",
    ".out",
    ".toc",
    ".nav",
    ".snm",
    ".fdb_latexmk",
    ".fls",
    ".synctex.gz"
)

$movedSourceFiles = 0
$movedArtifacts = 0

function Move-IfNeeded {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestPath
    )

    if ($DryRun) {
        Write-Host "[DryRun] Move: $SourcePath -> $DestPath"
        return $true
    }

    $destDir = Split-Path -Parent $DestPath
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Move-Item -LiteralPath $SourcePath -Destination $DestPath -Force
    Write-Host "Moved: $SourcePath -> $DestPath"
    return $true
}

function Handle-WorkingFolder {
    param(
        [Parameter(Mandatory = $true)][string]$FolderPath,
        [Parameter(Mandatory = $true)][string]$ArchiveRootName
    )

    if (-not (Test-Path -LiteralPath $FolderPath)) {
        return
    }

    $archiveRoot = Join-Path $FolderPath $ArchiveRootName
    $sourceTexDir = Join-Path $archiveRoot "source_tex"
    $artifactDir = Join-Path $archiveRoot "build_artifacts"

    $rootFiles = Get-ChildItem -LiteralPath $FolderPath -File
    foreach ($file in $rootFiles) {
        $nameLower = $file.Name.ToLowerInvariant()
        $extLower = $file.Extension.ToLowerInvariant()

        if ($extLower -in @(".tex", ".sty", ".cls", ".bst")) {
            $dest = Join-Path $sourceTexDir $file.Name
            if (Move-IfNeeded -SourcePath $file.FullName -DestPath $dest) {
                $script:movedSourceFiles++
            }
            continue
        }

        $isArtifact = $artifactNames -contains $extLower
        if (-not $isArtifact -and $nameLower.EndsWith(".synctex.gz")) {
            $isArtifact = $true
        }

        if ($isArtifact) {
            $dest = Join-Path $artifactDir $file.Name
            if (Move-IfNeeded -SourcePath $file.FullName -DestPath $dest) {
                $script:movedArtifacts++
            }
        }
    }
}

$projectDirs = Get-ChildItem -LiteralPath $projectsRoot -Directory
foreach ($project in $projectDirs) {
    $drafts = Join-Path $project.FullName "drafts"
    $slides = Join-Path $project.FullName "slides"
    Handle-WorkingFolder -FolderPath $drafts -ArchiveRootName "old_drafts"
    Handle-WorkingFolder -FolderPath $slides -ArchiveRootName "old_slides"
}

Write-Host ("Done. Moved source files: {0}; moved build artifacts: {1}" -f $movedSourceFiles, $movedArtifacts)
