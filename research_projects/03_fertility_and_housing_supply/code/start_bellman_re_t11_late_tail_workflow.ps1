Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "bellman_re_t11_late_tail_workflow.ps1"
if (-not (Test-Path $scriptPath)) {
    throw "Workflow script not found: $scriptPath"
}

Start-Process -FilePath "powershell.exe" `
    -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $scriptPath
    ) `
    -WorkingDirectory (Split-Path -Parent $PSScriptRoot) `
    -WindowStyle Hidden | Out-Null
