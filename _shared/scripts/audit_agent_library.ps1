param(
    [switch]$Strict
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$issues = [System.Collections.Generic.List[object]]::new()

function Add-Issue {
    param(
        [string]$Severity,
        [string]$Category,
        [string]$Path,
        [string]$Detail
    )

    $issues.Add([PSCustomObject]@{
        Severity = $Severity
        Category = $Category
        Path = $Path
        Detail = $Detail
    })
}

function Get-RelativeRepoPath {
    param([string]$Path)
    return $Path.Substring($repoRoot.Length).TrimStart("\")
}

$sharedSkills = Join-Path $repoRoot "_shared\skills"
$skills = @()

Get-ChildItem -LiteralPath $sharedSkills -File -Filter "*-SKILL.md" | ForEach-Object {
    $skills += [PSCustomObject]@{
        Name = $_.BaseName -replace "-SKILL$", ""
        Path = $_.FullName
        PackageRoot = $null
    }
}

Get-ChildItem -LiteralPath $sharedSkills -Directory | ForEach-Object {
    $skillFile = Join-Path $_.FullName "SKILL.md"
    if (Test-Path -LiteralPath $skillFile -PathType Leaf) {
        $skills += [PSCustomObject]@{
            Name = $_.Name
            Path = $skillFile
            PackageRoot = $_.FullName
        }
    }
}

$skills | Group-Object Name | Where-Object Count -gt 1 | ForEach-Object {
    Add-Issue "Error" "Skill" "_shared\skills" "Duplicate skill definition: $($_.Name)"
}

foreach ($skill in $skills) {
    $relativePath = Get-RelativeRepoPath $skill.Path
    $lines = @(Get-Content -LiteralPath $skill.Path -Encoding UTF8)

    if ($lines.Count -gt 500) {
        Add-Issue "Warning" "Skill" $relativePath "SKILL.md has $($lines.Count) lines; review progressive disclosure."
    }

    if ($lines.Count -lt 4 -or $lines[0] -ne "---") {
        Add-Issue "Error" "Skill" $relativePath "Missing opening YAML frontmatter delimiter."
        continue
    }

    $closingIndex = [Array]::IndexOf($lines, "---", 1)
    if ($closingIndex -lt 2) {
        Add-Issue "Error" "Skill" $relativePath "Missing closing YAML frontmatter delimiter."
        continue
    }

    $keys = @(
        $lines[1..($closingIndex - 1)] |
            Where-Object { $_ -match "^([A-Za-z0-9_-]+):" } |
            ForEach-Object { $Matches[1] }
    )

    if (($keys -join ",") -ne "name,description") {
        Add-Issue "Error" "Skill" $relativePath "Frontmatter keys must be exactly name,description; found $($keys -join ',')."
    }

    $declaredName = $lines[1] -replace "^name:\s*", ""
    if ($declaredName -ne $skill.Name) {
        Add-Issue "Error" "Skill" $relativePath "Declared name '$declaredName' does not match source name '$($skill.Name)'."
    }

    foreach ($bridgeRelative in @(".agents\skills", ".claude\skills")) {
        $bridgeFile = Join-Path (Join-Path (Join-Path $repoRoot $bridgeRelative) $skill.Name) "SKILL.md"
        if (-not (Test-Path -LiteralPath $bridgeFile -PathType Leaf)) {
            Add-Issue "Error" "Bridge" $bridgeRelative "Missing bridge for $($skill.Name)."
            continue
        }

        $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $skill.Path).Hash
        $bridgeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $bridgeFile).Hash
        if ($sourceHash -ne $bridgeHash) {
            Add-Issue "Error" "Bridge" (Get-RelativeRepoPath $bridgeFile) "Hash differs from canonical source for $($skill.Name)."
        }

        if ($skill.PackageRoot) {
            $bridgeSkillRoot = Split-Path -Parent $bridgeFile
            foreach ($resourceFolder in @("agents", "references", "scripts", "assets")) {
                $sourceResourceRoot = Join-Path $skill.PackageRoot $resourceFolder
                if (-not (Test-Path -LiteralPath $sourceResourceRoot -PathType Container)) {
                    continue
                }

                Get-ChildItem -LiteralPath $sourceResourceRoot -File -Recurse | ForEach-Object {
                    $relativeResource = $_.FullName.Substring($skill.PackageRoot.Length).TrimStart("\")
                    $bridgeResource = Join-Path $bridgeSkillRoot $relativeResource
                    if (-not (Test-Path -LiteralPath $bridgeResource -PathType Leaf)) {
                        Add-Issue "Error" "Bridge" $bridgeRelative "Missing packaged resource for $($skill.Name): $relativeResource"
                    } else {
                        $sourceResourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
                        $bridgeResourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $bridgeResource).Hash
                        if ($sourceResourceHash -ne $bridgeResourceHash) {
                            Add-Issue "Error" "Bridge" (Get-RelativeRepoPath $bridgeResource) "Hash differs from packaged resource for $($skill.Name)."
                        }
                    }
                }
            }
        }
    }
}

$instructionFiles = @(
    (Join-Path $repoRoot "AGENTS.md"),
    (Join-Path $repoRoot "CLAUDE.md")
)
$instructionFiles += Get-ChildItem -LiteralPath (Join-Path $repoRoot "_shared") -File -Recurse |
    Where-Object Extension -in @(".md", ".ps1", ".do") |
    Select-Object -ExpandProperty FullName

foreach ($file in $instructionFiles | Sort-Object -Unique) {
    if ($file -eq $PSCommandPath) {
        continue
    }
    $text = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    $relativePath = Get-RelativeRepoPath $file
    $badLead1 = [char]0x00C3
    $badLead2 = [char]0x00C2
    $badSequence = ([char]0x00E2).ToString() + ([char]0x20AC)
    if ($text.Contains($badLead1) -or $text.Contains($badLead2) -or $text.Contains($badSequence)) {
        Add-Issue "Error" "Encoding" $relativePath "Possible mojibake."
    }
    if ($text -match "fertility/compiled-sidecar") {
        Add-Issue "Error" "Instruction" $relativePath "Hard-coded stale root branch name."
    }
}

$projectRoot = Join-Path $repoRoot "research_projects"
Get-ChildItem -LiteralPath $projectRoot -Directory | ForEach-Object {
    $statusFile = Join-Path $_.FullName "STATUS.md"
    if (-not (Test-Path -LiteralPath $statusFile -PathType Leaf)) {
        return
    }

    $statusLines = @(Get-Content -LiteralPath $statusFile -Encoding UTF8)
    foreach ($heading in @("## Snapshot", "## Completed", "## In Progress", "## Next 3 Tasks", "## Blockers", "## Open Decisions", "## References")) {
        $count = @($statusLines | Where-Object { $_ -eq $heading }).Count
        if ($count -ne 1) {
            Add-Issue "Warning" "Status" (Get-RelativeRepoPath $statusFile) "'$heading' occurs $count times."
        }
    }

    if ($statusLines.Count -gt 300) {
        Add-Issue "Warning" "Status" (Get-RelativeRepoPath $statusFile) "$($statusLines.Count) lines; consider extracting historical detail after worktree reconciliation."
    }

    $memoryFile = Join-Path $_.FullName "memory.md"
    if (Test-Path -LiteralPath $memoryFile -PathType Leaf) {
        $memoryLines = @(Get-Content -LiteralPath $memoryFile -Encoding UTF8).Count
        if ($memoryLines -gt 300) {
            Add-Issue "Warning" "Memory" (Get-RelativeRepoPath $memoryFile) "$memoryLines lines; check for session-diary accumulation."
        }
    }
}

$summary = [PSCustomObject]@{
    Skills = $skills.Count
    Errors = @($issues | Where-Object Severity -eq "Error").Count
    Warnings = @($issues | Where-Object Severity -eq "Warning").Count
}

$summary | Format-List
if ($issues.Count) {
    $issues | Sort-Object Severity, Category, Path | Format-Table -Wrap -AutoSize
}

if ($summary.Errors -gt 0 -or ($Strict -and $summary.Warnings -gt 0)) {
    exit 1
}
