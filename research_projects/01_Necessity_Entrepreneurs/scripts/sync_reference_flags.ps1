param(
    [string]$ChecklistPath = "$PSScriptRoot/../literature/checklist/reference_checklist.csv",
    [string[]]$TargetFiles = @(
        "$PSScriptRoot/../drafts/necessity_entrepreneurship.lyx",
        "$PSScriptRoot/../drafts/old_drafts/source_tex/necessity_entrepreneurship.tex"
    )
)

if (-not (Test-Path -LiteralPath $ChecklistPath)) {
    throw "Checklist not found: $ChecklistPath"
}

$rows = @(Import-Csv -LiteralPath $ChecklistPath)
if ($rows.Count -eq 0) {
    throw "Checklist is empty: $ChecklistPath"
}

$pending = @(
    $rows | Where-Object {
        $value = "$($_.confirm_yn)".Trim()
        -not ($value -imatch "^(y|yes)$")
    }
)

if ($pending.Count -gt 0) {
    Write-Host ("No changes applied. Pending confirmations: {0}/{1}" -f $pending.Count, $rows.Count)
    exit 0
}

$updated = 0
foreach ($file in $TargetFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
        continue
    }

    $text = Get-Content -Raw -LiteralPath $file
    $newText = $text -replace '\s*\[\!\?\]', '' -replace '\s*\[CHECK\]', ''
    if ($newText -ne $text) {
        [System.IO.File]::WriteAllText($file, $newText, (New-Object System.Text.UTF8Encoding($false)))
        $updated++
    }
}

Write-Host ("Removed reference flags in {0} file(s)." -f $updated)
