<#
.SYNOPSIS
Blocks accidental commits of large local data, media, and cache files.

.DESCRIPTION
This script is intended to run as a Git pre-commit hook. It checks staged
files only. The goal is to catch the files that make the C: drive swell during
agentic coding: raw media, model/data dumps, VM bundles, browser caches, and
large files that belong on D: rather than in git.

.PARAMETER RepoRoot
Repository root. Defaults to the current directory.

.PARAMETER MaxMB
Maximum staged file size in MB before blocking the commit.
#>
param(
    [string]$RepoRoot = (Get-Location).Path,
    [int]$MaxMB = 50
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRootResolved = (Resolve-Path -LiteralPath $RepoRoot).Path
$staged = @(git -C $repoRootResolved diff --cached --name-only --diff-filter=ACMRT)

if ($staged.Count -eq 0) {
    exit 0
}

$blockedExtensions = @(
    ".avi",
    ".db",
    ".dta",
    ".feather",
    ".m4a",
    ".mat",
    ".mkv",
    ".mov",
    ".mp3",
    ".mp4",
    ".parquet",
    ".rds",
    ".sav",
    ".sqlite",
    ".vhdx",
    ".wav",
    ".webm",
    ".zst"
)

$blockedPathPatterns = @(
    "^_playground/browser-msforms-profile/",
    "^_playground/browser_profile_",
    "^_playground/browser_tools/.+_chrome_profile/",
    "^book/interviews/.+/audio/"
)

$violations = @()

foreach ($path in $staged) {
    if (-not $path) {
        continue
    }

    $objectSize = git -C $repoRootResolved cat-file -s ":$path" 2>$null
    if (-not $objectSize) {
        continue
    }

    $sizeBytes = [int64]$objectSize
    $sizeMB = [math]::Round($sizeBytes / 1MB, 1)
    $extension = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
    $normalized = $path -replace "\\", "/"

    $reasons = @()
    if ($sizeBytes -gt ($MaxMB * 1MB)) {
        $reasons += "larger than $MaxMB MB"
    }

    if ($blockedExtensions -contains $extension) {
        $reasons += "blocked local-data/media extension"
    }

    foreach ($pattern in $blockedPathPatterns) {
        if ($normalized -match $pattern) {
            $reasons += "blocked spillover/cache/media path"
            break
        }
    }

    if ($reasons.Count -gt 0) {
        $violations += [pscustomobject]@{
            SizeMB = $sizeMB
            Path = $path
            Reason = ($reasons -join "; ")
        }
    }
}

if ($violations.Count -eq 0) {
    exit 0
}

Write-Host ""
Write-Host "Commit blocked by git_size_guard.ps1" -ForegroundColor Red
Write-Host "These staged files look like C:-filling spillover rather than git source:"
Write-Host ""
$violations |
    Sort-Object SizeMB -Descending |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Move large data/media to D:\research_data or D:\AI_storage\spillover."
Write-Host "If a file is genuinely source material, reduce it or discuss before forcing it into git."
exit 1
