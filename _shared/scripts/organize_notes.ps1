param(
    [string[]]$ProjectPaths,
    [string]$ProjectsRoot = "research_projects",
    [switch]$AllProjects,
    [switch]$FailOnViolations
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$canonicalFiles = @(
    "01_project_overview.md",
    "02_literature_and_synthesis.md",
    "03_model_notes.md",
    "04_empirical_notes.md",
    "05_research_plan.md"
)

$baseMappings = @(
    [PSCustomObject]@{ OldRel = "overview/project_overview.md"; NewRel = "01_project_overview.md" },
    [PSCustomObject]@{ OldRel = "model/model_notes.md"; NewRel = "03_model_notes.md" },
    [PSCustomObject]@{ OldRel = "empirical/design_memo.md"; NewRel = "04_empirical_notes.md" },
    [PSCustomObject]@{ OldRel = "literature/literature_synthesis.md"; NewRel = "02_literature_and_synthesis.md" },
    [PSCustomObject]@{ OldRel = "project_overview.md"; NewRel = "01_project_overview.md" },
    [PSCustomObject]@{ OldRel = "literature_synthesis.md"; NewRel = "02_literature_and_synthesis.md" },
    [PSCustomObject]@{ OldRel = "model_notes.md"; NewRel = "03_model_notes.md" },
    [PSCustomObject]@{ OldRel = "design_memo.md"; NewRel = "04_empirical_notes.md" }
)

$legacyCategoryDirs = @("overview", "model", "empirical", "literature")
$textExtensions = @(".md", ".tex", ".txt", ".qmd")
$managedExtensions = @(".md", ".tex", ".txt", ".qmd")

function Normalize-Slash {
    param([string]$PathText)
    return ($PathText -replace "\\", "/")
}

function Get-RelativeUnixPath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $resolvedBase = (Resolve-Path $BasePath).Path
    $resolvedTarget = (Resolve-Path $TargetPath).Path
    $baseUri = New-Object System.Uri(($resolvedBase.TrimEnd("\") + "\"))
    $targetUri = New-Object System.Uri($resolvedTarget)
    $relative = $baseUri.MakeRelativeUri($targetUri).ToString()
    return Normalize-Slash ([System.Uri]::UnescapeDataString($relative))
}

function Get-TemplateContent {
    param(
        [string]$FileName,
        [string]$ProjectName
    )

    switch ($FileName) {
        "01_project_overview.md" {
            return @"
# 01 Project overview

Last updated: $(Get-Date -Format "yyyy-MM-dd")
Status: living document

## A. Priority: 1 (highest)
Project objective, scope, and core estimand.

## B. Priority: 2
Key hypotheses and mechanisms.

## C. Priority: 3
Open decisions and risks.
"@
        }
        "02_literature_and_synthesis.md" {
            return @"
# 02 Literature review and synthesis

## Scope
Synthesize what we know and identify what this project can contribute.

## Core strands
Use clear area headings and paragraph-first writing.
"@
        }
        "03_model_notes.md" {
            return @"
# 03 Model notes

## Family 1: [name]
### Intuition
### Minimal setup
### Key predictions
### Links to literature
"@
        }
        "04_empirical_notes.md" {
            return @"
# 04 Empirical notes

## Strategy 1: [name]
### Data
### Identification
### Baseline regression
### Threats and robustness
### Feasibility
"@
        }
        "05_research_plan.md" {
            return @"
# 05 Research plan

Last updated: $(Get-Date -Format "yyyy-MM-dd")
Status: planning handoff (post-brainstorm)

## A. Priority: 1 (highest)
Chosen question and estimand.

## B. Priority: 2
Top 1-2 model choices and why.

## C. Priority: 3
Top 1-2 empirical strategies and why.

## D. Priority: 4
Data access decision and fallback.

## E. Priority: 5
Next 3 tasks (owner, deliverable, deadline).
"@
        }
        default {
            throw "Unknown canonical notes file: $FileName"
        }
    }
}

function Ensure-CanonicalFiles {
    param(
        [string]$NotesPath,
        [string]$ProjectName
    )

    foreach ($name in $canonicalFiles) {
        $path = Join-Path $NotesPath $name
        if (-not (Test-Path $path)) {
            $template = Get-TemplateContent -FileName $name -ProjectName $ProjectName
            Set-Content -Path $path -Value $template -Encoding UTF8
        }
    }
}

function Get-UniqueDestinationPath {
    param(
        [string]$NotesPath,
        [string]$PreferredName
    )

    $base = [System.IO.Path]::GetFileNameWithoutExtension($PreferredName)
    $ext = [System.IO.Path]::GetExtension($PreferredName)
    $candidate = Join-Path $NotesPath $PreferredName
    $counter = 2

    while (Test-Path $candidate) {
        $candidate = Join-Path $NotesPath ("{0}_{1}{2}" -f $base, $counter, $ext)
        $counter++
    }
    return $candidate
}

function Migrate-LegacySubfolderFiles {
    param([string]$NotesPath)

    $mappings = New-Object System.Collections.Generic.List[object]

    foreach ($m in $baseMappings) {
        $oldPath = Join-Path $NotesPath ($m.OldRel -replace "/", "\")
        $newPath = Join-Path $NotesPath $m.NewRel

        if (-not (Test-Path $oldPath)) {
            continue
        }

        $resolvedOld = (Resolve-Path $oldPath).Path
        $resolvedNew = if (Test-Path $newPath) { (Resolve-Path $newPath).Path } else { $newPath }
        if ($resolvedOld -eq $resolvedNew) {
            continue
        }

        if (-not (Test-Path $newPath)) {
            Move-Item -LiteralPath $oldPath -Destination $newPath -Force
            $mappings.Add($m) | Out-Null
        } else {
            $legacyName = "legacy_" + ($m.OldRel -replace "/", "_")
            $legacyPath = Get-UniqueDestinationPath -NotesPath $NotesPath -PreferredName $legacyName
            Move-Item -LiteralPath $oldPath -Destination $legacyPath -Force
            $mappings.Add([PSCustomObject]@{
                OldRel = $m.OldRel
                NewRel = [System.IO.Path]::GetFileName($legacyPath)
            }) | Out-Null
        }
    }

    $legacyFiles = Get-ChildItem -Path $NotesPath -Recurse -File | Where-Object {
        if (-not ($managedExtensions -contains $_.Extension.ToLowerInvariant())) { return $false }
        $rel = Get-RelativeUnixPath -BasePath $NotesPath -TargetPath $_.FullName
        return ($rel -match "^(overview|model|empirical|literature)/")
    }

    foreach ($file in $legacyFiles) {
        $oldRel = Get-RelativeUnixPath -BasePath $NotesPath -TargetPath $file.FullName
        $legacyName = "legacy_" + ($oldRel -replace "/", "_")
        $destPath = Get-UniqueDestinationPath -NotesPath $NotesPath -PreferredName $legacyName
        Move-Item -LiteralPath $file.FullName -Destination $destPath -Force

        $mappings.Add([PSCustomObject]@{
            OldRel = $oldRel
            NewRel = [System.IO.Path]::GetFileName($destPath)
        }) | Out-Null
    }

    return $mappings
}

function Remove-EmptyLegacyCategoryDirs {
    param([string]$NotesPath)

    foreach ($dirName in $legacyCategoryDirs) {
        $dirPath = Join-Path $NotesPath $dirName
        if (-not (Test-Path $dirPath)) { continue }

        $items = Get-ChildItem -Path $dirPath -Force -ErrorAction SilentlyContinue
        if ($null -eq $items -or $items.Count -eq 0) {
            cmd /c "rd /s /q `"$dirPath`"" > $null 2>&1
        }
    }
}

function Flatten-UnexpectedSubfolders {
    param([string]$NotesPath)

    $unexpectedDirs = Get-ChildItem -Path $NotesPath -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notin @("old")
    }

    foreach ($dir in $unexpectedDirs) {
        $files = Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $rel = Get-RelativeUnixPath -BasePath $dir.FullName -TargetPath $file.FullName
            $flatName = "legacy_{0}_{1}" -f $dir.Name, ($rel -replace '/', '_')
            $dest = Get-UniqueDestinationPath -NotesPath $NotesPath -PreferredName $flatName
            Move-Item -LiteralPath $file.FullName -Destination $dest -Force
        }

        cmd /c "rd /s /q `"$($dir.FullName)`"" > $null 2>&1
    }
}

function Update-TextReferences {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [object[]]$Mappings
    )

    $allMappings = New-Object System.Collections.Generic.List[object]
    foreach ($m in $baseMappings) { $allMappings.Add($m) | Out-Null }
    foreach ($m in $Mappings) { $allMappings.Add($m) | Out-Null }

    $distinctMappings = $allMappings | Sort-Object OldRel, NewRel -Unique

    $textFiles = Get-ChildItem -Path $ProjectPath -Recurse -File | Where-Object {
        if ($_.FullName -match "\\[Nn]otes\\old\\") { return $false }
        $textExtensions -contains $_.Extension.ToLowerInvariant()
    }

    foreach ($file in $textFiles) {
        $content = Get-Content -Raw $file.FullName
        $original = $content

        foreach ($m in $distinctMappings) {
            $oldRel = $m.OldRel
            $newRel = $m.NewRel
            $oldRelWindows = $oldRel -replace '/', '\\'
            $newRelWindows = $newRel -replace '/', '\\'
            $oldTick = '`' + $oldRel + '`'
            $newTick = '`' + $newRel + '`'

            $content = $content.Replace("notes/$oldRel", "notes/$newRel")
            $content = $content.Replace("notes\\$oldRelWindows", "notes\\$newRelWindows")
            $content = $content.Replace("$ProjectsRoot/$ProjectName/notes/$oldRel", "$ProjectsRoot/$ProjectName/notes/$newRel")
            $content = $content.Replace("Notes/$oldRel", "notes/$newRel")
            $content = $content.Replace("Notes\\$oldRelWindows", "notes\\$newRelWindows")
            $content = $content.Replace("$ProjectsRoot/$ProjectName/notes/$oldRel", "$ProjectsRoot/$ProjectName/notes/$newRel")
            $content = $content.Replace($oldTick, $newTick)
        }

        if ($content -ne $original) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        }
    }
}

function Rebuild-NotesReadme {
    param([string]$ProjectName, [string]$NotesPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $null = $lines.Add("# Notes - $ProjectName")
    $null = $lines.Add("")
    $null = $lines.Add("This folder is the canonical workspace for brainstorming and pre-paper planning.")
    $null = $lines.Add("")
    $null = $lines.Add("## Core files")
    $null = $lines.Add('- `01_project_overview.md`')
    $null = $lines.Add('- `02_literature_and_synthesis.md`')
    $null = $lines.Add('- `03_model_notes.md`')
    $null = $lines.Add('- `04_empirical_notes.md`')
    $null = $lines.Add('- `05_research_plan.md`')
    $null = $lines.Add("")
    $null = $lines.Add("## Workflow")
    $null = $lines.Add('1. Brainstorm in `01`-`04`.')
    $null = $lines.Add('2. Commit decisions to `05_research_plan.md`.')
    $null = $lines.Add('3. Sync next tasks in `STATUS.md`.')

    Set-Content -Path (Join-Path $NotesPath "README.md") -Value $lines -Encoding UTF8
}

function Normalize-TopHeadings {
    param([string]$NotesPath)

    $expectedTopHeadings = @{
        "01_project_overview.md" = "# 01 Project overview"
        "02_literature_and_synthesis.md" = "# 02 Literature review and synthesis"
        "03_model_notes.md" = "# 03 Model notes"
        "04_empirical_notes.md" = "# 04 Empirical notes"
        "05_research_plan.md" = "# 05 Research plan"
    }

    foreach ($kv in $expectedTopHeadings.GetEnumerator()) {
        $path = Join-Path $NotesPath $kv.Key
        if (-not (Test-Path $path)) { continue }
        $lines = Get-Content $path
        if ($lines.Count -eq 0) {
            $lines = @($kv.Value)
        } elseif ($lines[0] -cne $kv.Value) {
            $lines[0] = $kv.Value
        } else {
            continue
        }
        Set-Content -Path $path -Value $lines -Encoding UTF8
    }
}

function Test-NotesCompliance {
    param(
        [string]$NotesPath,
        [string]$ProjectName
    )

    $violations = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    foreach ($name in $canonicalFiles) {
        $path = Join-Path $NotesPath $name
        if (-not (Test-Path $path)) {
            $violations.Add("Missing canonical file: notes/$name") | Out-Null
        }
    }

    $unexpectedDirs = Get-ChildItem -Path $NotesPath -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notin @("old")
    }
    foreach ($dir in $unexpectedDirs) {
        $violations.Add("Unexpected subfolder in notes/: $($dir.Name)") | Out-Null
    }

    $expectedTopHeadings = @{
        "01_project_overview.md" = "# 01 Project overview"
        "02_literature_and_synthesis.md" = "# 02 Literature review and synthesis"
        "03_model_notes.md" = "# 03 Model notes"
        "04_empirical_notes.md" = "# 04 Empirical notes"
        "05_research_plan.md" = "# 05 Research plan"
    }

    foreach ($kv in $expectedTopHeadings.GetEnumerator()) {
        $path = Join-Path $NotesPath $kv.Key
        if (-not (Test-Path $path)) { continue }
        $firstLine = (Get-Content -TotalCount 1 $path)
        if ($firstLine -cne $kv.Value) {
            $warnings.Add("Heading style mismatch in notes/$($kv.Key): expected '$($kv.Value)'") | Out-Null
        }
    }

    $planPath = Join-Path $NotesPath "05_research_plan.md"
    if (Test-Path $planPath) {
        $planHasSections = @(Get-Content $planPath | Select-String -Pattern "^## ").Count -gt 0
        if (-not $planHasSections) {
            $warnings.Add("Planning handoff file has no section headers: notes/05_research_plan.md") | Out-Null
        }
    }

    return [PSCustomObject]@{
        Violations = $violations
        Warnings = $warnings
    }
}

function Organize-ProjectNotes {
    param([string]$ProjectPath)

    $resolvedProject = (Resolve-Path $ProjectPath).Path
    $projectName = Split-Path -Leaf $resolvedProject
    $notesPath = Join-Path $resolvedProject "notes"
    if (-not (Test-Path $notesPath)) {
        $legacyNotesPath = Join-Path $resolvedProject "Notes"
        if (Test-Path $legacyNotesPath) {
            $notesPath = $legacyNotesPath
        }
    }
    if (-not (Test-Path $notesPath)) {
        Write-Host "[skip] $projectName (no notes folder)"
        return [PSCustomObject]@{ Violations = @(); Warnings = @() }
    }

    Ensure-CanonicalFiles -NotesPath $notesPath -ProjectName $projectName
    $migrations = @(Migrate-LegacySubfolderFiles -NotesPath $notesPath)
    Remove-EmptyLegacyCategoryDirs -NotesPath $notesPath
    Flatten-UnexpectedSubfolders -NotesPath $notesPath
    Update-TextReferences -ProjectPath $resolvedProject -ProjectName $projectName -Mappings $migrations
    Rebuild-NotesReadme -ProjectName $projectName -NotesPath $notesPath
    Normalize-TopHeadings -NotesPath $notesPath
    $compliance = Test-NotesCompliance -NotesPath $notesPath -ProjectName $projectName

    $migrationCount = ($migrations | Measure-Object).Count
    if ($migrationCount -gt 0) {
        Write-Host "[ok] $projectName ($migrationCount legacy note-path mappings applied)"
    } else {
        Write-Host "[ok] $projectName (already in standardized notes format)"
    }

    foreach ($w in $compliance.Warnings) {
        Write-Host "[warn] $projectName - $w"
    }
    foreach ($v in $compliance.Violations) {
        Write-Host "[violation] $projectName - $v"
    }

    return $compliance
}

if ($AllProjects) {
    $projects = Get-ChildItem -Path $ProjectsRoot -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName "notes")) -or (Test-Path (Join-Path $_.FullName "Notes"))
    } | Select-Object -ExpandProperty FullName
} elseif ($ProjectPaths -and $ProjectPaths.Count -gt 0) {
    $projects = $ProjectPaths
} else {
    throw "Provide -ProjectPaths <path1,path2,...> or use -AllProjects."
}

$allViolations = New-Object System.Collections.Generic.List[string]

foreach ($project in $projects) {
    $result = Organize-ProjectNotes -ProjectPath $project
    foreach ($v in $result.Violations) {
        $allViolations.Add($v) | Out-Null
    }
}

if ($FailOnViolations -and $allViolations.Count -gt 0) {
    throw "Notes-phase violations detected: $($allViolations.Count)."
}

