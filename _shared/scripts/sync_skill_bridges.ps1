param(
    [switch]$Prune
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\\..")).Path
$sharedSkills = Join-Path $repoRoot "_shared\\skills"
$bridgeRoots = @(
    (Join-Path $repoRoot ".agents\\skills")
    (Join-Path $repoRoot ".claude\\skills")
)

if (-not (Test-Path -LiteralPath $sharedSkills)) {
    throw "Shared skills folder not found: $sharedSkills"
}

$skills = @()

Get-ChildItem -LiteralPath $sharedSkills -File -Filter "*-SKILL.md" | ForEach-Object {
    $skills += [PSCustomObject]@{
        Name = $_.BaseName -replace "-SKILL$", ""
        SkillFile = $_.FullName
        PackageRoot = $null
    }
}

Get-ChildItem -LiteralPath $sharedSkills -Directory | ForEach-Object {
    $packageSkill = Join-Path $_.FullName "SKILL.md"
    if (Test-Path -LiteralPath $packageSkill -PathType Leaf) {
        $skills += [PSCustomObject]@{
            Name = $_.Name
            SkillFile = $packageSkill
            PackageRoot = $_.FullName
        }
    }
}

$duplicateNames = $skills | Group-Object Name | Where-Object Count -gt 1
if ($duplicateNames) {
    $names = ($duplicateNames.Name | Sort-Object) -join ", "
    throw "Duplicate flat and packaged skill definitions found: $names"
}

$invalidNames = $skills | Where-Object { $_.Name -notmatch "^[a-z0-9]+(?:-[a-z0-9]+)*$" }
if ($invalidNames) {
    $names = ($invalidNames.Name | Sort-Object) -join ", "
    throw "Invalid skill folder names found: $names"
}

$skills = $skills | Sort-Object Name
$skillNames = @($skills.Name)
$resourceFolders = @("agents", "references", "scripts", "assets")

foreach ($root in $bridgeRoots) {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
}

foreach ($skill in $skills) {
    foreach ($root in $bridgeRoots) {
        $skillDir = Join-Path $root $skill.Name
        $skillDest = Join-Path $skillDir "SKILL.md"

        if (Test-Path -LiteralPath $skillDir) {
            Remove-Item -LiteralPath $skillDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
        New-Item -ItemType HardLink -Path $skillDest -Target $skill.SkillFile | Out-Null

        if ($skill.PackageRoot) {
            foreach ($folderName in $resourceFolders) {
                $sourceFolder = Join-Path $skill.PackageRoot $folderName
                if (-not (Test-Path -LiteralPath $sourceFolder -PathType Container)) {
                    continue
                }

                Get-ChildItem -LiteralPath $sourceFolder -File -Recurse | ForEach-Object {
                    $relativePath = $_.FullName.Substring($skill.PackageRoot.Length).TrimStart("\")
                    $resourceDest = Join-Path $skillDir $relativePath
                    $resourceDestDir = Split-Path -Parent $resourceDest
                    New-Item -ItemType Directory -Path $resourceDestDir -Force | Out-Null
                    New-Item -ItemType HardLink -Path $resourceDest -Target $_.FullName | Out-Null
                }
            }
        }
    }
}

if ($Prune) {
    foreach ($root in $bridgeRoots) {
        Get-ChildItem -LiteralPath $root -Directory | Where-Object {
            $_.Name -notin $skillNames
        } | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
    }
}

$report = foreach ($root in $bridgeRoots) {
    [PSCustomObject]@{
        Root = $root
        SkillCount = (Get-ChildItem -LiteralPath $root -Directory | Measure-Object).Count
        PackageCount = ($skills | Where-Object PackageRoot | Measure-Object).Count
    }
}

$report | Format-Table -AutoSize
