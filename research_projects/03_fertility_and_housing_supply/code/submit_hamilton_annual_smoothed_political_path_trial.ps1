param(
    [string]$RemoteHost = "hfnt93@hamilton8.dur.ac.uk",
    [string]$RemoteBaseDir = "/nobackup/hfnt93/fert_runs",
    [string]$OutputStem = "nimby_vs_fertility_smoothed_political_path_trial",
    [double]$SmoothRho = 0.65,
    [double]$BoomAmp = 0.10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-RemoteOutput {
    param([object[]]$OutputLines)

    $clean = New-Object System.Collections.Generic.List[string]
    foreach ($entry in @($OutputLines)) {
        if ($null -eq $entry) {
            continue
        }
        $text = ([string]$entry) -replace "`r", ""
        if ($text -match '^(Connection|Shared connection) to .+ closed\.$') {
            continue
        }
        if ($text -match '^client_loop: send disconnect: ') {
            continue
        }
        $clean.Add($text)
    }
    return $clean
}

function Invoke-RemoteCapture {
    param(
        [string]$RemoteHostName,
        [string[]]$SshBaseArgs,
        [string]$RemoteCommand,
        [int]$MaxAttempts = 4,
        [int]$RetryDelaySeconds = 20
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $output = & ssh -tt -o ConnectTimeout=10 @SshBaseArgs $RemoteHostName $RemoteCommand 2>$null
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        if ($LASTEXITCODE -eq 0) {
            return (Normalize-RemoteOutput -OutputLines $output)
        }
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    throw "Remote command failed after $MaxAttempts attempts: $RemoteCommand"
}

function Copy-RemoteItem {
    param(
        [string]$RemoteHostName,
        [string[]]$SshBaseArgs,
        [string]$LocalPath,
        [string]$RemotePath,
        [int]$MaxAttempts = 4,
        [int]$RetryDelaySeconds = 20
    )

    $payload = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($LocalPath))
    $escapedRemotePath = $RemotePath -replace "'", "'\''"
    $remoteBase64Path = "$escapedRemotePath.b64"
    $chunkLength = 6000

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Invoke-RemoteCapture -RemoteHostName $RemoteHostName -SshBaseArgs $SshBaseArgs -RemoteCommand "mkdir -p '$(Split-Path $escapedRemotePath -Parent)' && : > '$remoteBase64Path'" | Out-Null
            for ($offset = 0; $offset -lt $payload.Length; $offset += $chunkLength) {
                $length = [Math]::Min($chunkLength, $payload.Length - $offset)
                $chunk = $payload.Substring($offset, $length)
                Invoke-RemoteCapture -RemoteHostName $RemoteHostName -SshBaseArgs $SshBaseArgs -RemoteCommand "printf '%s' '$chunk' >> '$remoteBase64Path'" | Out-Null
            }
            Invoke-RemoteCapture -RemoteHostName $RemoteHostName -SshBaseArgs $SshBaseArgs -RemoteCommand "base64 -d '$remoteBase64Path' > '$escapedRemotePath' && rm -f '$remoteBase64Path'" | Out-Null
            return
        } catch {
            if ($attempt -ge $MaxAttempts) {
                throw
            }
        }
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    throw "Remote copy failed after $MaxAttempts attempts: $LocalPath -> $RemotePath"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$keyPath = Join-Path $HOME ".ssh\id_ed25519"
if (-not (Test-Path $keyPath)) {
    throw "SSH key not found: $keyPath"
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runLabel = "annual_smoothed_political_path_trial_hamilton"
$localStageDir = Join-Path $logsRoot ("{0}_{1}" -f $runLabel, $timestamp)
New-Item -ItemType Directory -Path $localStageDir | Out-Null

$submissionPath = Join-Path $localStageDir "submission.txt"
$activePointer = Join-Path $logsRoot "active_annual_smoothed_political_path_trial_hamilton.txt"

$sshArgs = @(
    "-F", "NUL",
    "-i", $keyPath,
    "-o", "IdentitiesOnly=yes",
    "-o", "StrictHostKeyChecking=accept-new"
)

$remoteRunDir = "{0}/{1}_{2}" -f $RemoteBaseDir.TrimEnd("/"), $runLabel, $timestamp

$files = @(
    [pscustomobject]@{ Local = (Join-Path $projectRoot "README.md"); Remote = "$remoteRunDir/03_fertility_and_housing_supply/README.md" },
    [pscustomobject]@{ Local = (Join-Path $projectRoot "STATUS.md"); Remote = "$remoteRunDir/03_fertility_and_housing_supply/STATUS.md" },
    [pscustomobject]@{ Local = (Join-Path $projectRoot "memory.md"); Remote = "$remoteRunDir/03_fertility_and_housing_supply/memory.md" },
    [pscustomobject]@{ Local = (Join-Path $projectRoot "code/nimby_fertility_transition_bridge.py"); Remote = "$remoteRunDir/03_fertility_and_housing_supply/code/nimby_fertility_transition_bridge.py" },
    [pscustomobject]@{ Local = (Join-Path $projectRoot "code/build_nimby_vs_fertility_smoothed_political_path_trial.py"); Remote = "$remoteRunDir/03_fertility_and_housing_supply/code/build_nimby_vs_fertility_smoothed_political_path_trial.py" },
    [pscustomobject]@{ Local = (Join-Path $projectRoot "code/hpc/run_annual_smoothed_political_path_trial.sh"); Remote = "$remoteRunDir/03_fertility_and_housing_supply/code/hpc/run_annual_smoothed_political_path_trial.sh" },
    [pscustomobject]@{ Local = (Join-Path $projectRoot "code/hpc/annual_smoothed_political_path_trial.slurm"); Remote = "$remoteRunDir/03_fertility_and_housing_supply/code/hpc/annual_smoothed_political_path_trial.slurm" }
)

Invoke-RemoteCapture -RemoteHostName $RemoteHost -SshBaseArgs $sshArgs -RemoteCommand "mkdir -p '$remoteRunDir/03_fertility_and_housing_supply/code/hpc' '$remoteRunDir/03_fertility_and_housing_supply/notes/build'" | Out-Null
foreach ($file in $files) {
    Copy-RemoteItem -RemoteHostName $RemoteHost -SshBaseArgs $sshArgs -LocalPath $file.Local -RemotePath $file.Remote
}

$remoteCommand = @"
set -euo pipefail
cd '$remoteRunDir/03_fertility_and_housing_supply/code/hpc'
python3 - <<'PY'
from pathlib import Path
for path in Path('.').glob('*'):
    if path.suffix in {'.sh', '.slurm'}:
        text = path.read_text(encoding='utf-8')
        path.write_text(text.replace('\r\n', '\n'), encoding='utf-8')
PY
chmod +x run_annual_smoothed_political_path_trial.sh annual_smoothed_political_path_trial.slurm
sbatch --nice=10000 --export=ALL,OUTPUT_STEM=$OutputStem,SMOOTH_RHO=$SmoothRho,BOOM_AMP=$BoomAmp annual_smoothed_political_path_trial.slurm
"@

$submitOutput = Invoke-RemoteCapture -RemoteHostName $RemoteHost -SshBaseArgs $sshArgs -RemoteCommand $remoteCommand
$jobLine = $submitOutput | Where-Object { $_ -match 'Submitted batch job (\d+)' } | Select-Object -Last 1
if (-not $jobLine) {
    throw "Could not parse sbatch output."
}
$jobId = [regex]::Match($jobLine, 'Submitted batch job (\d+)').Groups[1].Value

@(
    "job_id=$jobId"
    "remote_run_dir=$remoteRunDir"
    "output_stem=$OutputStem"
    "smooth_rho=$SmoothRho"
    "boom_amp=$BoomAmp"
) | Set-Content -Path $submissionPath

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "job_id=$jobId"
    "remote_run_dir=$remoteRunDir"
    "submission_path=$submissionPath"
    "output_stem=$OutputStem"
) | Set-Content -Path $activePointer

Write-Output $submissionPath
