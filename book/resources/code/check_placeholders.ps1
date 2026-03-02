param(
    [string]$Root = "projects/book",
    [switch]$StrictStyleNotes = $true
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Root)) {
    Write-Error "Path not found: $Root"
    exit 2
}

# Pattern A: unresolved wrapper placeholders like ?interesting?
$patternA = '\?[A-Za-z][^?\r\n]{0,60}\?'
# Pattern B: broken OCR/placeholder joins like first?person
$patternB = '[A-Za-z]\?[A-Za-z]'

$files = Get-ChildItem $Root -Recurse -File -Filter *.md |
    Where-Object { $_.FullName -notmatch '[\\/]+Resources[\\/]Literature[\\/]markdown[\\/]' }

$hits = @()
foreach ($file in $files) {
    $matches = Select-String -Path $file.FullName -Pattern $patternA, $patternB
    foreach ($m in $matches) {
        $hits += [pscustomobject]@{
            Rule = "placeholder_or_broken_join"
            Path = $file.FullName
            Line = $m.LineNumber
            Text = $m.Line.Trim()
        }
    }

    if ($StrictStyleNotes -and $file.Name -like "STYLE_NOTES*.md") {
        $strictMatches = Select-String -Path $file.FullName -Pattern '\?'
        foreach ($m in $strictMatches) {
            $hits += [pscustomobject]@{
                Rule = "strict_style_notes_no_question_mark"
                Path = $file.FullName
                Line = $m.LineNumber
                Text = $m.Line.Trim()
            }
        }
    }
}

if ($hits.Count -eq 0) {
    Write-Output "PASS: no unresolved markdown placeholder markers found under $Root."
    exit 0
}

Write-Output "FAIL: unresolved markdown placeholder markers found:"
$hits | ForEach-Object {
    Write-Output ("[{0}] {1}:{2}  {3}" -f $_.Rule, $_.Path, $_.Line, $_.Text)
}
exit 1
