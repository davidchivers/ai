<#
.SYNOPSIS
Reports and optionally cleans local spillover storage.

.DESCRIPTION
This script is for the Windows research workspace where C: is the fast,
space-limited workbench and D: is the large spillover drive.

By default it only reports:
- free space on C: and D:
- configured spillover environment variables
- largest local cache/worktree/session folders
- recent growth under common agentic-coding locations

Use -PruneGitDangling to remove unreachable loose git objects from the repo.
That does not touch checked-out files or current branches, but it does remove
git's short-term recovery copies of failed/stale object writes.

.PARAMETER RepoRoot
Repository root path. Defaults to two levels above this script.

.PARAMETER SpillRoot
Spillover root path. Defaults to AI_SPILLOVER_ROOT or D:\AI_storage\spillover.

.PARAMETER PruneGitDangling
Prune unreachable loose git objects in RepoRoot.

.PARAMETER CleanTempOlderThanDays
Delete files/folders in SpillRoot\temp older than this many days. Omit to skip.

.PARAMETER Top
Number of rows to show in ranked folder tables.

.EXAMPLE
./_shared/scripts/spillover_audit.ps1

.EXAMPLE
./_shared/scripts/spillover_audit.ps1 -PruneGitDangling

.EXAMPLE
./_shared/scripts/spillover_audit.ps1 -CleanTempOlderThanDays 7
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
    [string]$SpillRoot = $(if ($env:AI_SPILLOVER_ROOT) { $env:AI_SPILLOVER_ROOT } else { "D:\AI_storage\spillover" }),
    [switch]$PruneGitDangling,
    [int]$CleanTempOlderThanDays = -1,
    [int]$Top = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FolderSizeRow {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $files = @(Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue)
    $measure = $files | Measure-Object -Property Length -Sum
    $sum = if ($null -eq $measure -or $null -eq $measure.Sum) { 0 } else { $measure.Sum }
    $latest = if ($files.Count -gt 0) {
        ($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    } else {
        $null
    }
    [pscustomobject]@{
        Path = $Path
        GB = [math]::Round(($sum / 1GB), 2)
        LatestWrite = $latest
    }
}

function Show-DriveSpace {
    Write-Host ""
    Write-Host "Drive space"
    Get-PSDrive -Name C,D -ErrorAction SilentlyContinue |
        Select-Object Name,
            @{Name = "UsedGB"; Expression = { [math]::Round($_.Used / 1GB, 2) }},
            @{Name = "FreeGB"; Expression = { [math]::Round($_.Free / 1GB, 2) }} |
        Format-Table -AutoSize
}

function Show-Env {
    Write-Host ""
    Write-Host "Spillover environment"
    $vars = @(
        "AI_SPILLOVER_ROOT",
        "TEMP",
        "TMP",
        "PIP_CACHE_DIR",
        "UV_CACHE_DIR",
        "NPM_CONFIG_CACHE",
        "HF_HOME",
        "TRANSFORMERS_CACHE",
        "TORCH_HOME",
        "PLAYWRIGHT_BROWSERS_PATH"
    )

    $rows = foreach ($var in $vars) {
        [pscustomobject]@{
            Variable = $var
            Process = [Environment]::GetEnvironmentVariable($var, "Process")
            User = [Environment]::GetEnvironmentVariable($var, "User")
        }
    }
    $rows | Format-Table -AutoSize
}

function Show-KeyFolders {
    Write-Host ""
    Write-Host "Largest known spillover folders"
    $paths = @(
        $SpillRoot,
        "$SpillRoot\temp",
        "$SpillRoot\caches",
        "$SpillRoot\worktrees",
        "$SpillRoot\browser_profiles",
        "$RepoRoot\.git",
        "$RepoRoot\.claude\worktrees",
        "$RepoRoot\_playground\worktrees",
        "$RepoRoot\_playground\browser-msforms-profile",
        "$env:USERPROFILE\.codex\sessions",
        "$env:USERPROFILE\.codex\logs_2.sqlite",
        "$env:LOCALAPPDATA\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\vm_bundles"
    )

    $rows = @()
    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
            if ($null -eq $item) {
                continue
            }
            if ($item.PSIsContainer) {
                $rows += Get-FolderSizeRow -Path $path
            } else {
                $rows += [pscustomobject]@{
                    Path = $path
                    GB = [math]::Round(($item.Length / 1GB), 2)
                    LatestWrite = $item.LastWriteTime
                }
            }
        }
    }

    $rows | Sort-Object GB -Descending | Select-Object -First $Top | Format-Table -AutoSize
}

function Show-RecentGrowth {
    Write-Host ""
    Write-Host "Recent growth in common roots"
    $cut = (Get-Date).AddDays(-1)
    $roots = @(
        $RepoRoot,
        "$env:APPDATA",
        "$env:LOCALAPPDATA",
        "$env:USERPROFILE\.codex",
        "$env:USERPROFILE\.cache",
        $SpillRoot
    )

    $rows = foreach ($root in $roots) {
        if (Test-Path -LiteralPath $root) {
            $files = @(Get-ChildItem -LiteralPath $root -Force -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -ge $cut })
            $measure = $files | Measure-Object -Property Length -Sum
            $sum = if ($null -eq $measure -or $null -eq $measure.Sum) { 0 } else { $measure.Sum }
            [pscustomobject]@{
                Path = $root
                RecentGB = [math]::Round(($sum / 1GB), 2)
                RecentFiles = ($files | Measure-Object).Count
            }
        }
    }

    $rows | Sort-Object RecentGB -Descending | Select-Object -First $Top | Format-Table -AutoSize
}

function Invoke-GitPrune {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot ".git"))) {
        throw "No .git directory found under $RepoRoot"
    }

    Write-Host ""
    Write-Host "Pruning dangling git objects"
    $beforeFree = (Get-PSDrive -Name C).Free
    $before = git -C $RepoRoot count-objects -vH
    git -C $RepoRoot prune --expire now | Out-Null
    $after = git -C $RepoRoot count-objects -vH
    $afterFree = (Get-PSDrive -Name C).Free

    Write-Host "Before:"
    $before
    Write-Host "After:"
    $after
    [pscustomobject]@{
        FreeBeforeGB = [math]::Round($beforeFree / 1GB, 2)
        FreeAfterGB = [math]::Round($afterFree / 1GB, 2)
        FreedGB = [math]::Round(($afterFree - $beforeFree) / 1GB, 2)
    } | Format-List
}

function Invoke-TempClean {
    param([Parameter(Mandatory = $true)][int]$Days)

    if ($Days -lt 0) {
        return
    }

    $tempPath = Join-Path $SpillRoot "temp"
    if (-not (Test-Path -LiteralPath $tempPath)) {
        Write-Host "No spillover temp folder found: $tempPath"
        return
    }

    $resolvedTemp = (Resolve-Path -LiteralPath $tempPath).Path
    $resolvedSpill = (Resolve-Path -LiteralPath $SpillRoot).Path
    $spillPrefix = $resolvedSpill.TrimEnd("\") + "\"
    if (-not ($resolvedTemp + "\").StartsWith($spillPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean temp outside spillover root: $resolvedTemp"
    }

    Write-Host ""
    Write-Host "Cleaning spillover temp files older than $Days days"
    $cut = (Get-Date).AddDays(-$Days)
    $targets = Get-ChildItem -LiteralPath $resolvedTemp -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cut }
    $bytes = 0
    foreach ($target in $targets) {
        if ($target.PSIsContainer) {
            $measure = Get-ChildItem -LiteralPath $target.FullName -Force -Recurse -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum
            $bytes += if ($null -eq $measure -or $null -eq $measure.Sum) { 0 } else { $measure.Sum }
        } else {
            $bytes += $target.Length
        }
        Remove-Item -LiteralPath $target.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

    [pscustomobject]@{
        RemovedItems = ($targets | Measure-Object).Count
        FreedGB = [math]::Round($bytes / 1GB, 2)
    } | Format-List
}

Show-DriveSpace
Show-Env
Show-KeyFolders
Show-RecentGrowth

if ($PruneGitDangling) {
    Invoke-GitPrune
}

if ($CleanTempOlderThanDays -ge 0) {
    Invoke-TempClean -Days $CleanTempOlderThanDays
}
