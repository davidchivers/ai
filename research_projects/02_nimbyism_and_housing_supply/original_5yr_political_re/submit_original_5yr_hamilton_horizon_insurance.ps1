param(
    [string]$RemoteAlias = "hamilton8",
    [string]$RemoteProject = "",
    [int]$StartK = 7,
    [int]$EndK = 14,
    [int]$MaxIter = 2,
    [double]$PoliticalUpdateWeight = 0.005,
    [double]$PriceGuessLevel = 0.34013605902777766,
    [string]$TargetMaskMode = "union_only",
    [string]$PoliticalUpdateRule = "fixed_step_targeted_linesearch",
    [string]$Partition = "shared",
    [string]$WallTime = "08:00:00",
    [int]$MemoryGb = 8,
    [int]$CpusPerTask = 1,
    [string]$MatlabModule = "matlab/R2021a"
)

$ErrorActionPreference = "Stop"

function Invoke-Checked {
    param(
        [scriptblock]$Script,
        [string]$FailureMessage
    )

    & $Script
    if ($LASTEXITCODE -ne 0) {
        throw $FailureMessage
    }
}

function Copy-ToRemote {
    param(
        [string]$LocalFile,
        [string]$RemotePath,
        [string]$RemoteAlias
    )

    $resolved = Resolve-Path -LiteralPath $LocalFile
    $bytes = [System.IO.File]::ReadAllBytes($resolved)
    $encoded = [Convert]::ToBase64String($bytes)
    $chunkSize = 3500
    $remoteDir = $RemotePath -replace '/[^/]+$',''
    $remoteEncodedPath = "$RemotePath.codex_b64"

    Invoke-Checked -Script {
        & ssh -tt $RemoteAlias "mkdir -p '$remoteDir'"
    } -FailureMessage "Remote directory creation failed for $RemotePath"

    Invoke-Checked -Script {
        & ssh -tt $RemoteAlias ": > '$remoteEncodedPath'"
    } -FailureMessage "Remote temp file init failed for $LocalFile"

    for ($offset = 0; $offset -lt $encoded.Length; $offset += $chunkSize) {
        $length = [Math]::Min($chunkSize, $encoded.Length - $offset)
        $chunk = $encoded.Substring($offset, $length)
        Invoke-Checked -Script {
            & ssh -tt $RemoteAlias "printf '%s' '$chunk' >> '$remoteEncodedPath'"
        } -FailureMessage "Remote chunk upload failed for $LocalFile at offset $offset"
    }

    $decodeCommand = "python3 -c 'import base64, pathlib, sys; pathlib.Path(sys.argv[1]).write_bytes(base64.b64decode(pathlib.Path(sys.argv[2]).read_text()))' '$RemotePath' '$remoteEncodedPath'; rm -f '$remoteEncodedPath'"
    Invoke-Checked -Script {
        & ssh -tt $RemoteAlias $decodeCommand
    } -FailureMessage "Remote decode failed for $LocalFile"
}

function New-RemoteSbatchContent {
    param(
        [string]$RemoteOriginalDir,
        [string]$RemoteJobDir,
        [int]$K,
        [int]$MaxIter,
        [double]$PoliticalUpdateWeight,
        [double]$PriceGuessLevel,
        [string]$RunTag,
        [string]$PoliticalUpdateRule,
        [string]$TargetMaskMode,
        [string]$Partition,
        [string]$WallTime,
        [int]$MemoryGb,
        [int]$CpusPerTask,
        [string]$MatlabModule
    )

    $jobName = "nimby_k{0:00}" -f $K
    $matlabCommand = "cd('$RemoteOriginalDir'); run_original_5yr_transition_political_bellman_bounded($K, $MaxIter, 'political_only', 'equal_weight_vote', $PoliticalUpdateWeight, '$RunTag', '$PoliticalUpdateRule', $PriceGuessLevel, 'historical_1950', [1], 1e-6, 3, 0, '$TargetMaskMode');"
    return @"
#!/bin/bash
#SBATCH -J $jobName
#SBATCH -p $Partition
#SBATCH -t $WallTime
#SBATCH --cpus-per-task=$CpusPerTask
#SBATCH --mem=${MemoryGb}G
#SBATCH -o $RemoteJobDir/${RunTag}_%j.out
#SBATCH -e $RemoteJobDir/${RunTag}_%j.err

set -euo pipefail
module load $MatlabModule
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
cd "$RemoteOriginalDir"
matlab -singleCompThread -batch "$matlabCommand"
"@
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$truthDir = Join-Path $scriptDir "truth"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$remoteExternalRoot = ""

if ([string]::IsNullOrWhiteSpace($RemoteProject)) {
    $statePath = Join-Path $truthDir "hamilton_offload_state.json"
    if (-not (Test-Path -LiteralPath $statePath)) {
        throw "RemoteProject not provided and $statePath was not found."
    }
    $state = Get-Content -Raw $statePath | ConvertFrom-Json
    $RemoteProject = [string]$state.remote_project
}

$externalRootPathFile = Join-Path $truthDir "hamilton_external_root.txt"
if (Test-Path -LiteralPath $externalRootPathFile) {
    $remoteExternalRoot = (Get-Content -Raw $externalRootPathFile).Trim()
}

$remoteOriginalDir = "$RemoteProject/original_5yr_political_re"
$remoteExtensionDir = "$RemoteProject/extensions/re_no_politics"
$remoteJobDir = "$remoteOriginalDir/hamilton_horizon_insurance_$timestamp"
$localTransitionMatrix = Join-Path $scriptDir "truth\micro_ss\TransitionMatrix.mat"

$filesToSync = @(
    (Join-Path $scriptDir "run_original_5yr_transition_political_bellman_bounded.m"),
    (Join-Path $scriptDir "build_original_5yr_demographic_path_from_historical_age_shares.m"),
    (Join-Path $scriptDir "build_original_5yr_demographic_path_from_age_state_csv.m"),
    (Join-Path $projectRoot "extensions\re_no_politics\solve_transition_political_bellman_nimby.m")
)

Invoke-Checked -Script {
    & ssh -tt $RemoteAlias "mkdir -p '$remoteOriginalDir' '$remoteExtensionDir' '$remoteJobDir'"
} -FailureMessage "Failed to create remote directories on $RemoteAlias"

foreach ($file in $filesToSync) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Required file not found: $file"
    }
}
if (-not (Test-Path -LiteralPath $localTransitionMatrix)) {
    throw "Required transition matrix bundle not found: $localTransitionMatrix"
}

Copy-ToRemote -LocalFile $filesToSync[0] -RemotePath "$remoteOriginalDir/run_original_5yr_transition_political_bellman_bounded.m" -RemoteAlias $RemoteAlias
Copy-ToRemote -LocalFile $filesToSync[1] -RemotePath "$remoteOriginalDir/build_original_5yr_demographic_path_from_historical_age_shares.m" -RemoteAlias $RemoteAlias
Copy-ToRemote -LocalFile $filesToSync[2] -RemotePath "$remoteOriginalDir/build_original_5yr_demographic_path_from_age_state_csv.m" -RemoteAlias $RemoteAlias
Copy-ToRemote -LocalFile $filesToSync[3] -RemotePath "$remoteExtensionDir/solve_transition_political_bellman_nimby.m" -RemoteAlias $RemoteAlias
if (-not [string]::IsNullOrWhiteSpace($remoteExternalRoot)) {
    Copy-ToRemote -LocalFile $localTransitionMatrix -RemotePath "$remoteExternalRoot/Code/Codes_ABB/TransitionMatrix.mat" -RemoteAlias $RemoteAlias
    Copy-ToRemote -LocalFile $localTransitionMatrix -RemotePath "$remoteExternalRoot/Code/SteadyState/TransitionMatrix.mat" -RemoteAlias $RemoteAlias
}

$jobs = @()
for ($k = $StartK; $k -le $EndK; $k++) {
    $runTag = "ham_k${k}_uniononly_i${MaxIter}_insurance_$timestamp"
    $localTempScript = Join-Path $env:TEMP "$runTag.sbatch"
    $remoteScript = "$remoteJobDir/$runTag.sbatch"
    $content = New-RemoteSbatchContent `
        -RemoteOriginalDir $remoteOriginalDir `
        -RemoteJobDir $remoteJobDir `
        -K $k `
        -MaxIter $MaxIter `
        -PoliticalUpdateWeight $PoliticalUpdateWeight `
        -PriceGuessLevel $PriceGuessLevel `
        -RunTag $runTag `
        -PoliticalUpdateRule $PoliticalUpdateRule `
        -TargetMaskMode $TargetMaskMode `
        -Partition $Partition `
        -WallTime $WallTime `
        -MemoryGb $MemoryGb `
        -CpusPerTask $CpusPerTask `
        -MatlabModule $MatlabModule
    Set-Content -LiteralPath $localTempScript -Value $content -NoNewline
    try {
        Copy-ToRemote -LocalFile $localTempScript -RemotePath $remoteScript -RemoteAlias $RemoteAlias
    }
    finally {
        if (Test-Path -LiteralPath $localTempScript) {
            Remove-Item -LiteralPath $localTempScript -Force
        }
    }

    $submissionOutput = & ssh -tt $RemoteAlias "sbatch '$remoteScript'"
    if ($LASTEXITCODE -ne 0) {
        throw "sbatch failed for k=$k"
    }
    $submissionText = ($submissionOutput | Out-String)
    $jobIdMatch = [regex]::Match($submissionText, 'Submitted batch job (\d+)')
    if (-not $jobIdMatch.Success) {
        throw "Could not parse Slurm job id for k=$k. Output: $submissionText"
    }

    $jobs += [pscustomobject]@{
        k = $k
        run_tag = $runTag
        job_id = $jobIdMatch.Groups[1].Value
        remote_script = $remoteScript
    }
}

$stateOut = [pscustomobject]@{
    created_at = (Get-Date).ToString("s")
    remote_alias = $RemoteAlias
    remote_project = $RemoteProject
    remote_job_dir = $remoteJobDir
    start_k = $StartK
    end_k = $EndK
    max_iter = $MaxIter
    target_mask_mode = $TargetMaskMode
    political_update_rule = $PoliticalUpdateRule
    political_update_weight = $PoliticalUpdateWeight
    jobs = $jobs
}

$timestampedStatePath = Join-Path $truthDir "hamilton_horizon_insurance_$timestamp.json"
$latestStatePath = Join-Path $truthDir "hamilton_horizon_insurance_latest.json"
$json = $stateOut | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $timestampedStatePath -Value $json
Set-Content -LiteralPath $latestStatePath -Value $json

Write-Host "Submitted Hamilton insurance packet:"
$jobs | ForEach-Object {
    Write-Host ("k={0} -> job {1}" -f $_.k, $_.job_id)
}
Write-Host "Saved state to $timestampedStatePath"
