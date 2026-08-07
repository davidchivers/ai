[CmdletBinding()]
param(
    [string]$RepoUrl = 'https://github.com/meleantonio/awesome-econ-ai-stuff.git',
    [string]$RepoWebUrl = 'https://github.com/meleantonio/awesome-econ-ai-stuff',
    [string]$RepoName = 'meleantonio/awesome-econ-ai-stuff',
    [string]$Ref = 'main',
    [string]$Destination,
    [string]$ManifestPath,
    [switch]$Apply,
    [switch]$Force,
    [string[]]$ExcludeSkills = @('codex-review', 'lit-review-assistant')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Force -and -not $Apply) {
    throw '-Force requires -Apply. The default mode is read-only audit.'
}

$sharedRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $Destination) {
    $Destination = Join-Path $sharedRoot 'skills'
}
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $Destination '_sync\\awesome_econ_ai_stuff_manifest.json'
}

function Get-Sha256 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash
}

function Get-ManifestLookup {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Manifest
    )

    $lookup = @{}
    if ($null -eq $Manifest) {
        return $lookup
    }

    $entries = @()
    if ($Manifest.PSObject.Properties.Name -contains 'skills') {
        $entries = @($Manifest.skills)
    }

    foreach ($entry in $entries) {
        if ($null -ne $entry -and $entry.PSObject.Properties.Name -contains 'name') {
            $lookup[$entry.name] = $entry
        }
    }

    return $lookup
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = 'git'
    $startInfo.Arguments = (($Arguments | ForEach-Object {
                if ($_ -match '\s') {
                    '"' + $_ + '"'
                }
                else {
                    $_
                }
            }) -join ' ')
    if ($WorkingDirectory) {
        $startInfo.WorkingDirectory = $WorkingDirectory
    }
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdout
        StdErr = $stderr
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required to sync awesome-econ-ai-stuff skills.'
}

$spilloverTemp = 'D:\AI_storage\spillover\temp'
$tempBase = if (Test-Path -LiteralPath $spilloverTemp -PathType Container) {
    $spilloverTemp
}
else {
    [System.IO.Path]::GetTempPath()
}
$tmpRoot = Join-Path $tempBase ('awesome_econ_ai_stuff_' + [System.Guid]::NewGuid().ToString('N'))
$repoPath = Join-Path $tmpRoot 'repo'

New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null
New-Item -ItemType Directory -Path $Destination -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path -Parent $ManifestPath) -Force | Out-Null

$existingManifest = $null
if (Test-Path -LiteralPath $ManifestPath) {
    $existingManifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
}
$manifestLookup = Get-ManifestLookup -Manifest $existingManifest

$results = @()
$newManifestEntries = @()

try {
    $cloneArgs = @(
        'clone',
        '--depth', '1',
        '--branch', $Ref,
        $RepoUrl,
        $repoPath
    )
    $cloneResult = Invoke-Git -Arguments $cloneArgs
    if ($cloneResult.ExitCode -ne 0) {
        throw ("git clone failed:`n" + $cloneResult.StdErr + $cloneResult.StdOut)
    }

    $commitResult = Invoke-Git -Arguments @('-C', $repoPath, 'rev-parse', 'HEAD')
    if ($commitResult.ExitCode -ne 0) {
        throw ("git rev-parse failed:`n" + $commitResult.StdErr + $commitResult.StdOut)
    }
    $commit = $commitResult.StdOut.Trim()

    $skillFiles = Get-ChildItem -Path (Join-Path $repoPath '_skills') -Recurse -Filter 'SKILL.md' |
        Sort-Object FullName

    foreach ($skillFile in $skillFiles) {
        $skillName = Split-Path -Path $skillFile.DirectoryName -Leaf
        $relativeSourcePath = $skillFile.FullName.Substring($repoPath.Length + 1).Replace('\', '/')

        $previousEntry = $null
        if ($manifestLookup.ContainsKey($skillName)) {
            $previousEntry = $manifestLookup[$skillName]
        }

        if ($skillName -in $ExcludeSkills) {
            $results += [pscustomobject]@{
                Skill = $skillName
                Action = 'retired_skipped'
                Destination = $null
                UpstreamHash = Get-Sha256 -Path $skillFile.FullName
                LocalHash = $null
            }
            continue
        }

        $destinationRelative = $skillName + '-SKILL.md'
        if ($null -ne $previousEntry -and $previousEntry.PSObject.Properties.Name -contains 'destination') {
            $destinationRelative = $previousEntry.destination
        }
        $destinationPath = Join-Path $Destination ($destinationRelative.Replace('/', '\'))
        $upstreamHash = Get-Sha256 -Path $skillFile.FullName
        $localExists = Test-Path -LiteralPath $destinationPath
        $localHash = $null
        $action = $null

        if ($localExists) {
            $localHash = Get-Sha256 -Path $destinationPath
        }

        if (-not $localExists) {
            if ($Apply) {
                New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) -Force | Out-Null
                Copy-Item -LiteralPath $skillFile.FullName -Destination $destinationPath -Force
                $action = 'installed'
                $localHash = $upstreamHash
            }
            else {
                $action = 'would_install'
            }
        }
        elseif ($localHash -eq $upstreamHash) {
            $action = 'current'
        }
        else {
            $lastSyncedHash = $null
            if ($null -ne $previousEntry -and $previousEntry.PSObject.Properties.Name -contains 'last_synced_upstream_hash') {
                $lastSyncedHash = $previousEntry.last_synced_upstream_hash
            }

            $safeToOverwrite = $Force.IsPresent -or ($lastSyncedHash -and $localHash -eq $lastSyncedHash)

            if ($safeToOverwrite) {
                if ($Apply) {
                    Copy-Item -LiteralPath $skillFile.FullName -Destination $destinationPath -Force
                    $action = 'updated'
                    $localHash = $upstreamHash
                }
                else {
                    $action = 'would_update'
                }
            }
            else {
                $action = 'conflict_skipped'
            }
        }

        $lastSyncedUpstreamHash = $null
        if ($action -in @('installed', 'updated', 'current')) {
            $lastSyncedUpstreamHash = $upstreamHash
        }
        elseif ($null -ne $previousEntry -and $previousEntry.PSObject.Properties.Name -contains 'last_synced_upstream_hash') {
            $lastSyncedUpstreamHash = $previousEntry.last_synced_upstream_hash
        }

        $newManifestEntries += [pscustomobject]@{
            name = $skillName
            source_path = $relativeSourcePath
            destination = $destinationRelative.Replace('\', '/')
            last_synced_upstream_hash = $lastSyncedUpstreamHash
        }

        $results += [pscustomobject]@{
            Skill = $skillName
            Action = $action
            Destination = $destinationRelative
            UpstreamHash = $upstreamHash
            LocalHash = $localHash
        }
    }

    if ($Apply) {
        $manifest = [pscustomobject]@{
            source = [pscustomobject]@{
                repo = $RepoName
                repo_url = $RepoWebUrl
                git_url = $RepoUrl
                ref = $Ref
            }
            last_sync_utc = [DateTime]::UtcNow.ToString('o')
            last_commit = $commit
            excluded_skills = @($ExcludeSkills)
            skills = $newManifestEntries
        }

        $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ManifestPath -Encoding ascii

        $bridgeScript = Join-Path $PSScriptRoot 'sync_skill_bridges.ps1'
        if (Test-Path -LiteralPath $bridgeScript -PathType Leaf) {
            & $bridgeScript -Prune
        }
    }
    else {
        Write-Host 'Audit only: no skills or manifest were changed. Re-run with -Apply after reviewing conflicts.'
    }

    $grouped = $results | Group-Object -Property Action
    foreach ($group in $grouped) {
        Write-Host ("{0}: {1}" -f $group.Name, $group.Count)
    }

    $results | Sort-Object Skill | Format-Table -AutoSize
}
finally {
    if (Test-Path -LiteralPath $tmpRoot) {
        Remove-Item -LiteralPath $tmpRoot -Recurse -Force
    }
}
