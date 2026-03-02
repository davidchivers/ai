param(
  [string]$DriveRoot = 'G:\My Drive\The Target Trap (Book Project)',
  [string]$LocalRoot = 'C:\Users\Dave_\OneDrive\Desktop\Economics\projects\book'
)

$ErrorActionPreference = 'Stop'

function Get-RelativePath([string]$base, [string]$full) {
  $basePath = [System.IO.Path]::GetFullPath($base)
  $fullPath = [System.IO.Path]::GetFullPath($full)
  if (-not $fullPath.StartsWith($basePath, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $null
  }
  return $fullPath.Substring($basePath.Length).TrimStart('\')
}

function Ensure-Dir([string]$path) {
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
}

$driveDocs = Get-ChildItem -Path $DriveRoot -Recurse -Filter *.docx
$localDocs = Get-ChildItem -Path $LocalRoot -Recurse -Filter *.docx

$driveMap = @{}
foreach ($f in $driveDocs) {
  $rel = Get-RelativePath $DriveRoot $f.FullName
  if ($rel) { $driveMap[$rel] = $f }
}

$localMap = @{}
foreach ($f in $localDocs) {
  $rel = Get-RelativePath $LocalRoot $f.FullName
  if ($rel) { $localMap[$rel] = $f }
}

$allRels = ($driveMap.Keys + $localMap.Keys) | Sort-Object -Unique

$toLocal = @()
$toDrive = @()

foreach ($rel in $allRels) {
  $d = $driveMap[$rel]
  $l = $localMap[$rel]
  if ($d -and -not $l) {
    $toLocal += $rel
  } elseif ($l -and -not $d) {
    $toDrive += $rel
  } elseif ($d -and $l) {
    if ($d.LastWriteTime -gt $l.LastWriteTime) {
      $toLocal += $rel
    } elseif ($l.LastWriteTime -gt $d.LastWriteTime) {
      $toDrive += $rel
    }
  }
}

foreach ($rel in $toLocal) {
  $src = Join-Path $DriveRoot $rel
  $dst = Join-Path $LocalRoot $rel
  Ensure-Dir $dst
  Copy-Item -Path $src -Destination $dst -Force
}

foreach ($rel in $toDrive) {
  $src = Join-Path $LocalRoot $rel
  $dst = Join-Path $DriveRoot $rel
  Ensure-Dir $dst
  Copy-Item -Path $src -Destination $dst -Force
}

Write-Output "Copied to local: $($toLocal.Count)"
Write-Output "Copied to drive: $($toDrive.Count)"
