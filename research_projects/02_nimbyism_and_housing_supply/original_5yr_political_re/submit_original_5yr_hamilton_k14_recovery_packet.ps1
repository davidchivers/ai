param(
    [string]$RemoteAlias = "hamilton8",
    [string]$RemoteProject = "",
    [string]$Partition = "shared",
    [string]$WallTime = "08:00:00",
    [int]$MemoryGb = 8,
    [int]$CpusPerTask = 1,
    [string]$MatlabModule = "matlab/R2021a",
    [string]$SeedPricePathCsv = "",
    [switch]$IncludeActiveClustersCont
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
        [hashtable]$Candidate,
        [string]$Partition,
        [string]$WallTime,
        [int]$MemoryGb,
        [int]$CpusPerTask,
        [string]$MatlabModule
    )

    $jobName = $Candidate.StageName
    $matlabCommand = @(
        "cd('$RemoteOriginalDir')"
        ("run_original_5yr_transition_political_bellman_bounded({0}, {1}, 'political_only', 'equal_weight_vote', {2}, '{3}', '{4}', 0.34013605902777766, 'historical_1950', [{5}], 1e-6, {6}, {7}, '{8}', '{9}', {10}, {11})" -f `
            $Candidate.MaxK, `
            $Candidate.MaxIter, `
            $Candidate.PoliticalUpdateWeight.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture), `
            $Candidate.StageName, `
            $Candidate.PoliticalUpdateRule, `
            (($Candidate.OuterLineSearchScales | ForEach-Object { $_.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture) }) -join "; "), `
            $Candidate.MaxTargetedPeriods, `
            $Candidate.TargetBlockHalfWidth, `
            $Candidate.TargetMaskMode, `
            $Candidate.RemoteSeedCsv, `
            $Candidate.OuterStepNormalizationExpr, `
            $Candidate.OuterTargetLogStepExpr)
    ) -join "; "

    return @"
#!/bin/bash
#SBATCH -J $jobName
#SBATCH -p $Partition
#SBATCH -t $WallTime
#SBATCH --cpus-per-task=$CpusPerTask
#SBATCH --mem=${MemoryGb}G
#SBATCH -o $RemoteJobDir/${jobName}_%j.out
#SBATCH -e $RemoteJobDir/${jobName}_%j.err

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

if ([string]::IsNullOrWhiteSpace($SeedPricePathCsv)) {
    $SeedPricePathCsv = Join-Path $scriptDir "original_5yr_transition_political_bellman_hist_k12_segmentunion_cont_i2_final_price_path.csv"
}
if (-not (Test-Path -LiteralPath $SeedPricePathCsv)) {
    throw "Seed price path CSV not found: $SeedPricePathCsv"
}

if ([string]::IsNullOrWhiteSpace($RemoteProject)) {
    $statePath = Join-Path $truthDir "hamilton_offload_state.json"
    if (-not (Test-Path -LiteralPath $statePath)) {
        throw "RemoteProject not provided and $statePath was not found."
    }
    $state = Get-Content -Raw $statePath | ConvertFrom-Json
    $RemoteProject = [string]$state.remote_project
}

$remoteExternalRoot = ""
$externalRootPathFile = Join-Path $truthDir "hamilton_external_root.txt"
if (Test-Path -LiteralPath $externalRootPathFile) {
    $remoteExternalRoot = (Get-Content -Raw $externalRootPathFile).Trim()
}

$remoteOriginalDir = "$RemoteProject/original_5yr_political_re"
$remoteExtensionDir = "$RemoteProject/extensions/re_no_politics"
$remoteSteadyDir = "$RemoteProject/code/steadystate"
$remoteJobDir = "$remoteOriginalDir/hamilton_k14_recovery_$timestamp"
$remoteSeedCsv = "$remoteOriginalDir/$(Split-Path -Leaf $SeedPricePathCsv)"
$localTransitionMatrix = Join-Path $scriptDir "truth\micro_ss\TransitionMatrix.mat"

$filesToSync = @(
    @{ Local = (Join-Path $scriptDir "run_original_5yr_transition_political_bellman_bounded.m"); Remote = "$remoteOriginalDir/run_original_5yr_transition_political_bellman_bounded.m" },
    @{ Local = (Join-Path $scriptDir "build_original_5yr_demographic_path_from_historical_age_shares.m"); Remote = "$remoteOriginalDir/build_original_5yr_demographic_path_from_historical_age_shares.m" },
    @{ Local = (Join-Path $scriptDir "build_original_5yr_demographic_path_from_age_state_csv.m"); Remote = "$remoteOriginalDir/build_original_5yr_demographic_path_from_age_state_csv.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\solve_transition_political_bellman_nimby.m"); Remote = "$remoteExtensionDir/solve_transition_political_bellman_nimby.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\solve_transition_re_no_politics.m"); Remote = "$remoteExtensionDir/solve_transition_re_no_politics.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\solve_household_path_nimby.m"); Remote = "$remoteExtensionDir/solve_household_path_nimby.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\build_stationary_cross_section_nimby.m"); Remote = "$remoteExtensionDir/build_stationary_cross_section_nimby.m" },
    @{ Local = (Join-Path $projectRoot "code\steadystate\solve_original_5yr_bellman_core.m"); Remote = "$remoteSteadyDir/solve_original_5yr_bellman_core.m" },
    @{ Local = (Join-Path $projectRoot "code\steadystate\solve_original_5yr_political_steady_state.m"); Remote = "$remoteSteadyDir/solve_original_5yr_political_steady_state.m" },
    @{ Local = (Join-Path $projectRoot "code\steadystate\SolveSS_iter.m"); Remote = "$remoteSteadyDir/SolveSS_iter.m" },
    @{ Local = $SeedPricePathCsv; Remote = $remoteSeedCsv }
)

Invoke-Checked -Script {
    & ssh -tt $RemoteAlias "mkdir -p '$remoteOriginalDir' '$remoteExtensionDir' '$remoteSteadyDir' '$remoteJobDir'"
} -FailureMessage "Failed to create remote directories on $RemoteAlias"

foreach ($file in $filesToSync) {
    if (-not (Test-Path -LiteralPath $file.Local)) {
        throw "Required file not found: $($file.Local)"
    }
    Copy-ToRemote -LocalFile $file.Local -RemotePath $file.Remote -RemoteAlias $RemoteAlias
}

if ((-not [string]::IsNullOrWhiteSpace($remoteExternalRoot)) -and (Test-Path -LiteralPath $localTransitionMatrix)) {
    Copy-ToRemote -LocalFile $localTransitionMatrix -RemotePath "$remoteExternalRoot/Code/Codes_ABB/TransitionMatrix.mat" -RemoteAlias $RemoteAlias
    Copy-ToRemote -LocalFile $localTransitionMatrix -RemotePath "$remoteExternalRoot/Code/SteadyState/TransitionMatrix.mat" -RemoteAlias $RemoteAlias
}

$candidates = @(
    @{
        StageName = "ham_k14_unionblock_cont_i2_$timestamp"
        MaxK = 14
        MaxIter = 2
        PoliticalUpdateWeight = 0.005
        PoliticalUpdateRule = "fixed_step_targeted_linesearch"
        OuterLineSearchScales = @(8.0, 4.0, 2.0, 1.0, 0.5)
        MaxTargetedPeriods = 3
        TargetBlockHalfWidth = 1
        TargetMaskMode = "union_and_block"
        RemoteSeedCsv = $remoteSeedCsv
        OuterStepNormalizationExpr = "[]"
        OuterTargetLogStepExpr = "[]"
    },
    @{
        StageName = "ham_k14_signsplit_smallw_cont_i2_$timestamp"
        MaxK = 14
        MaxIter = 2
        PoliticalUpdateWeight = 0.0025
        PoliticalUpdateRule = "fixed_step_targeted_linesearch"
        OuterLineSearchScales = @(8.0, 4.0, 2.0, 1.0, 0.5)
        MaxTargetedPeriods = 3
        TargetBlockHalfWidth = 0
        TargetMaskMode = "sign_split"
        RemoteSeedCsv = $remoteSeedCsv
        OuterStepNormalizationExpr = "[]"
        OuterTargetLogStepExpr = "[]"
    },
    @{
        StageName = "ham_k14_activeclusters_norm_i2_$timestamp"
        MaxK = 14
        MaxIter = 2
        PoliticalUpdateWeight = 0.005
        PoliticalUpdateRule = "fixed_step_targeted_linesearch"
        OuterLineSearchScales = @(4.0, 2.0, 1.0, 0.5)
        MaxTargetedPeriods = 3
        TargetBlockHalfWidth = 1
        TargetMaskMode = "active_clusters"
        RemoteSeedCsv = $remoteSeedCsv
        OuterStepNormalizationExpr = "'maxabs'"
        OuterTargetLogStepExpr = "0.001"
    },
    @{
        StageName = "ham_k14_unionblock_norm_i2_$timestamp"
        MaxK = 14
        MaxIter = 2
        PoliticalUpdateWeight = 0.005
        PoliticalUpdateRule = "fixed_step_targeted_linesearch"
        OuterLineSearchScales = @(4.0, 2.0, 1.0, 0.5)
        MaxTargetedPeriods = 3
        TargetBlockHalfWidth = 1
        TargetMaskMode = "union_and_block"
        RemoteSeedCsv = $remoteSeedCsv
        OuterStepNormalizationExpr = "'maxabs'"
        OuterTargetLogStepExpr = "0.001"
    },
    @{
        StageName = "ham_k14_segmentunion_norm_i2_$timestamp"
        MaxK = 14
        MaxIter = 2
        PoliticalUpdateWeight = 0.005
        PoliticalUpdateRule = "fixed_step_targeted_linesearch"
        OuterLineSearchScales = @(4.0, 2.0, 1.0, 0.5)
        MaxTargetedPeriods = 3
        TargetBlockHalfWidth = 1
        TargetMaskMode = "segment_union"
        RemoteSeedCsv = $remoteSeedCsv
        OuterStepNormalizationExpr = "'maxabs'"
        OuterTargetLogStepExpr = "0.001"
    },
    @{
        StageName = "ham_k14_activeclusters_norm_i3_$timestamp"
        MaxK = 14
        MaxIter = 3
        PoliticalUpdateWeight = 0.005
        PoliticalUpdateRule = "fixed_step_targeted_linesearch"
        OuterLineSearchScales = @(2.0, 1.0, 0.5)
        MaxTargetedPeriods = 3
        TargetBlockHalfWidth = 1
        TargetMaskMode = "active_clusters"
        RemoteSeedCsv = $remoteSeedCsv
        OuterStepNormalizationExpr = "'maxabs'"
        OuterTargetLogStepExpr = "0.001"
    }
)

if ($IncludeActiveClustersCont) {
    $candidates = @(
        @{
            StageName = "ham_k14_activeclusters_cont_i2_$timestamp"
            MaxK = 14
            MaxIter = 2
            PoliticalUpdateWeight = 0.005
            PoliticalUpdateRule = "fixed_step_targeted_linesearch"
            OuterLineSearchScales = @(8.0, 4.0, 2.0, 1.0, 0.5)
            MaxTargetedPeriods = 3
            TargetBlockHalfWidth = 1
            TargetMaskMode = "active_clusters"
            RemoteSeedCsv = $remoteSeedCsv
            OuterStepNormalizationExpr = "[]"
            OuterTargetLogStepExpr = "[]"
        }
    ) + $candidates
}

$jobs = @()
foreach ($candidate in $candidates) {
    $localTempScript = Join-Path $env:TEMP ($candidate.StageName + ".sbatch")
    $remoteScript = "$remoteJobDir/$($candidate.StageName).sbatch"
    $content = New-RemoteSbatchContent `
        -RemoteOriginalDir $remoteOriginalDir `
        -RemoteJobDir $remoteJobDir `
        -Candidate $candidate `
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
        throw "sbatch failed for stage $($candidate.StageName)"
    }
    $submissionText = ($submissionOutput | Out-String)
    $jobIdMatch = [regex]::Match($submissionText, 'Submitted batch job (\d+)')
    if (-not $jobIdMatch.Success) {
        throw "Could not parse Slurm job id for stage $($candidate.StageName). Output: $submissionText"
    }

    $jobs += [pscustomobject]@{
        stage_name = $candidate.StageName
        target_mask_mode = $candidate.TargetMaskMode
        max_iter = $candidate.MaxIter
        political_update_weight = $candidate.PoliticalUpdateWeight
        outer_step_normalization = if ($candidate.OuterStepNormalizationExpr -eq "[]") { "" } else { "maxabs" }
        outer_target_log_step = if ($candidate.OuterTargetLogStepExpr -eq "[]") { [double]::NaN } else { 0.001 }
        job_id = $jobIdMatch.Groups[1].Value
        remote_script = $remoteScript
    }
}

$stateOut = [pscustomobject]@{
    created_at = (Get-Date).ToString("s")
    remote_alias = $RemoteAlias
    remote_project = $RemoteProject
    remote_job_dir = $remoteJobDir
    remote_seed_csv = $remoteSeedCsv
    packet_type = "k14_recovery"
    jobs = $jobs
}

$timestampedStatePath = Join-Path $truthDir "hamilton_k14_recovery_$timestamp.json"
$latestStatePath = Join-Path $truthDir "hamilton_k14_recovery_latest.json"
$json = $stateOut | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $timestampedStatePath -Value $json
Set-Content -LiteralPath $latestStatePath -Value $json

Write-Host "Submitted Hamilton k14 recovery packet:"
$jobs | ForEach-Object {
    Write-Host ("{0} -> job {1}" -f $_.stage_name, $_.job_id)
}
Write-Host "Saved state to $timestampedStatePath"
