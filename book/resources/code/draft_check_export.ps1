param(
    [Parameter(Mandatory = $true)]
    [string]$MdPath,
    [string]$OutputDocx,
    [switch]$SkipPlaceholderCheck
)

$ErrorActionPreference = "Stop"

function Resolve-AbsPath([string]$PathValue) {
    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $PathValue))
}

function Test-FilePlaceholders([string]$PathValue) {
    $patternA = '\?[A-Za-z][^?\r\n]{0,60}\?'
    $patternB = '[A-Za-z]\?[A-Za-z]'

    $matches = Select-String -Path $PathValue -Pattern $patternA, $patternB
    if (-not $matches) { return @() }

    $hits = @()
    foreach ($m in $matches) {
        $hits += [pscustomobject]@{
            Line = $m.LineNumber
            Text = $m.Line.Trim()
        }
    }
    return $hits
}

$mdFull = Resolve-AbsPath $MdPath
if (-not (Test-Path $mdFull)) {
    Write-Error "Markdown file not found: $MdPath"
    exit 2
}

if ([System.IO.Path]::GetExtension($mdFull).ToLowerInvariant() -ne ".md") {
    Write-Error "Input must be a .md file: $MdPath"
    exit 2
}

if ([string]::IsNullOrWhiteSpace($OutputDocx)) {
    $OutputDocx = [System.IO.Path]::ChangeExtension($mdFull, ".docx")
}
$docxFull = Resolve-AbsPath $OutputDocx

if (-not $SkipPlaceholderCheck) {
    $placeholderHits = Test-FilePlaceholders $mdFull
    if ($placeholderHits.Count -gt 0) {
        Write-Output "FAIL: placeholder markers found in $mdFull"
        $placeholderHits | ForEach-Object {
            Write-Output ("Line {0}: {1}" -f $_.Line, $_.Text)
        }
        exit 1
    }
}

$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
if (-not $pandoc) {
    Write-Error "pandoc is not installed or not on PATH. Install pandoc, then rerun."
    exit 3
}

$outDir = Split-Path -Parent $docxFull
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

& pandoc $mdFull -f gfm -t docx -o $docxFull
if ($LASTEXITCODE -ne 0) {
    Write-Error "pandoc export failed for: $mdFull"
    exit 4
}

Write-Output "PASS: exported DOCX"
Write-Output ("MD:   {0}" -f $mdFull)
Write-Output ("DOCX: {0}" -f $docxFull)
Write-Output "Note: this script does not sync markdown files."
