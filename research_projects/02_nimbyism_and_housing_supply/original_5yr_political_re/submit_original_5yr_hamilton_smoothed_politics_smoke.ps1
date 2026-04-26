param(
    [string]$RemoteAlias = "hamilton8",
    [string]$RemoteProject = "",
    [string]$RemoteExternalRoot = "",
    [string]$Partition = "test",
    [string]$WallTime = "00:15:00",
    [int]$MemoryGb = 10,
    [int]$CpusPerTask = 1,
    [string]$MatlabModule = "matlab/R2021a",
    [string]$SeedPricePathCsv = "",
    [double]$PoliticalResponseSigma = 0.05,
    [string]$StatePath = ""
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

function Copy-ToRemoteScp {
    param(
        [string]$LocalFile,
        [string]$RemotePath,
        [string]$RemoteAlias
    )

    $resolved = (Resolve-Path -LiteralPath $LocalFile).ProviderPath
    $remoteDir = $RemotePath -replace '/[^/]+$',''
    Invoke-Checked -Script {
        & ssh -tt $RemoteAlias "mkdir -p '$remoteDir'"
    } -FailureMessage "Remote directory creation failed for $RemotePath"

    Invoke-Checked -Script {
        & scp $resolved "${RemoteAlias}:$RemotePath"
    } -FailureMessage "scp failed for $LocalFile"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$truthDir = Join-Path $scriptDir "truth"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ([string]::IsNullOrWhiteSpace($SeedPricePathCsv)) {
    $SeedPricePathCsv = "C:\Users\Dave_\AI\research_projects\02_nimbyism_and_housing_supply\original_5yr_political_re\original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv"
}
if (-not (Test-Path -LiteralPath $SeedPricePathCsv)) {
    throw "Seed price path CSV not found: $SeedPricePathCsv"
}

if ([string]::IsNullOrWhiteSpace($RemoteProject) -or [string]::IsNullOrWhiteSpace($RemoteExternalRoot)) {
    $offloadStatePath = "C:\Users\Dave_\AI\.claude\worktrees\nimby_dual_solver_boss_project_20260420_152442\research_projects\02_nimbyism_and_housing_supply\original_5yr_political_re\truth\hamilton_offload_state.json"
    if (-not (Test-Path -LiteralPath $offloadStatePath)) {
        throw "Hamilton offload state not found: $offloadStatePath"
    }
    $offloadState = Get-Content -Raw $offloadStatePath | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($RemoteProject)) {
        $RemoteProject = [string]$offloadState.remote_project
    }
    if ([string]::IsNullOrWhiteSpace($RemoteExternalRoot)) {
        $RemoteExternalRoot = [string]$offloadState.remote_external_root
    }
}

$localCodesAbbTransition = "C:\Users\Dave_\Dropbox\Zac and David\Code\Codes_ABB\TransitionMatrix.mat"
$localSteadyTransition = "C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\TransitionMatrix.mat"
foreach ($required in @($localCodesAbbTransition, $localSteadyTransition)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required transition file not found: $required"
    }
}

$remoteOriginalDir = "$RemoteProject/original_5yr_political_re"
$remoteExtensionDir = "$RemoteProject/extensions/re_no_politics"
$remoteSteadyDir = "$RemoteProject/code/steadystate"
$remoteJobDir = "$remoteOriginalDir/hamilton_smoothed_politics_smoke_$timestamp"
$remoteSeedCsv = "$remoteOriginalDir/$(Split-Path -Leaf $SeedPricePathCsv)"
$stageName = "ham_smoothpermits_smoke_k2_b2_s$($PoliticalResponseSigma.ToString('0.###', [System.Globalization.CultureInfo]::InvariantCulture).Replace('.','p'))_$timestamp"

$filesToSync = @(
    @{ Local = (Join-Path $scriptDir "run_original_5yr_joint_wedge_smoothed.m"); Remote = "$remoteOriginalDir/run_original_5yr_joint_wedge_smoothed.m" },
    @{ Local = (Join-Path $scriptDir "run_original_5yr_joint_wedge_smooth.m"); Remote = "$remoteOriginalDir/run_original_5yr_joint_wedge_smooth.m" },
    @{ Local = (Join-Path $scriptDir "run_original_5yr_transition_joint_supply_wedge_smoothed_politics.m"); Remote = "$remoteOriginalDir/run_original_5yr_transition_joint_supply_wedge_smoothed_politics.m" },
    @{ Local = (Join-Path $scriptDir "run_original_5yr_transition_joint_supply_wedge_smoothed_politics.ps1"); Remote = "$remoteOriginalDir/run_original_5yr_transition_joint_supply_wedge_smoothed_politics.ps1" },
    @{ Local = (Join-Path $scriptDir "run_original_5yr_transition_joint_supply_wedge_continuation.m"); Remote = "$remoteOriginalDir/run_original_5yr_transition_joint_supply_wedge_continuation.m" },
    @{ Local = (Join-Path $scriptDir "build_original_5yr_demographic_path_from_age_state_csv.m"); Remote = "$remoteOriginalDir/build_original_5yr_demographic_path_from_age_state_csv.m" },
    @{ Local = (Join-Path $scriptDir "build_original_5yr_demographic_path_from_historical_age_shares.m"); Remote = "$remoteOriginalDir/build_original_5yr_demographic_path_from_historical_age_shares.m" },
    @{ Local = (Join-Path $scriptDir "build_original_5yr_demographic_two_group_proxy.m"); Remote = "$remoteOriginalDir/build_original_5yr_demographic_two_group_proxy.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\solve_transition_re_no_politics.m"); Remote = "$remoteExtensionDir/solve_transition_re_no_politics.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\update_price_path_re_no_politics.m"); Remote = "$remoteExtensionDir/update_price_path_re_no_politics.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\solve_household_path_nimby.m"); Remote = "$remoteExtensionDir/solve_household_path_nimby.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\build_stationary_cross_section_nimby.m"); Remote = "$remoteExtensionDir/build_stationary_cross_section_nimby.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\load_transition_matrix_data.m"); Remote = "$remoteExtensionDir/load_transition_matrix_data.m" },
    @{ Local = (Join-Path $projectRoot "code\steadystate\solve_original_5yr_bellman_core.m"); Remote = "$remoteSteadyDir/solve_original_5yr_bellman_core.m" },
    @{ Local = (Join-Path $projectRoot "code\steadystate\solve_original_5yr_political_steady_state.m"); Remote = "$remoteSteadyDir/solve_original_5yr_political_steady_state.m" },
    @{ Local = (Join-Path $projectRoot "code\steadystate\SolveSS_iter.m"); Remote = "$remoteSteadyDir/SolveSS_iter.m" },
    @{ Local = $SeedPricePathCsv; Remote = $remoteSeedCsv }
)

Invoke-Checked -Script {
    & ssh -tt $RemoteAlias "mkdir -p '$remoteOriginalDir' '$remoteExtensionDir' '$remoteSteadyDir' '$remoteJobDir' '$RemoteExternalRoot/Code/Codes_ABB' '$RemoteExternalRoot/Code/SteadyState'"
} -FailureMessage "Failed to create remote directories on $RemoteAlias"

foreach ($file in $filesToSync) {
    if (-not (Test-Path -LiteralPath $file.Local)) {
        throw "Required file not found: $($file.Local)"
    }
    Copy-ToRemoteScp -LocalFile $file.Local -RemotePath $file.Remote -RemoteAlias $RemoteAlias
}

Copy-ToRemoteScp -LocalFile $localCodesAbbTransition -RemotePath "$RemoteExternalRoot/Code/Codes_ABB/TransitionMatrix.mat" -RemoteAlias $RemoteAlias
Copy-ToRemoteScp -LocalFile $localSteadyTransition -RemotePath "$RemoteExternalRoot/Code/SteadyState/TransitionMatrix.mat" -RemoteAlias $RemoteAlias

$matlabCommand = @(
    "cd('$remoteOriginalDir')"
    ("run_original_5yr_joint_wedge_smooth({0}, {1}, {2}, '{3}', '{4}', '{5}', {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15})" -f `
        2, `
        1, `
        2, `
        $remoteSeedCsv, `
        $stageName, `
        'historical_1950', `
        '1.0e-2', `
        '1.0e-3', `
        '[1.0; 0.5]', `
        '0.08', `
        '0.65', `
        '-0.50', `
        '0.50', `
        '[2]', `
        1, `
        $PoliticalResponseSigma.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture))
) -join "; "

$sbatchContent = @"
#!/bin/bash
#SBATCH -J $stageName
#SBATCH -p $Partition
#SBATCH -t $WallTime
#SBATCH --cpus-per-task=$CpusPerTask
#SBATCH --mem=${MemoryGb}G
#SBATCH -o $remoteJobDir/${stageName}_%j.out
#SBATCH -e $remoteJobDir/${stageName}_%j.err

set -euo pipefail
module load $MatlabModule
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export ZAC_DAVID_EXTERNAL_ROOT="$RemoteExternalRoot"
cd "$remoteOriginalDir"
matlab -singleCompThread -batch "$matlabCommand"
"@

$localTempScript = Join-Path $env:TEMP ($stageName + ".sbatch")
$remoteScript = "$remoteJobDir/$stageName.sbatch"
Set-Content -LiteralPath $localTempScript -Value $sbatchContent -NoNewline
try {
    Copy-ToRemoteScp -LocalFile $localTempScript -RemotePath $remoteScript -RemoteAlias $RemoteAlias
}
finally {
    if (Test-Path -LiteralPath $localTempScript) {
        Remove-Item -LiteralPath $localTempScript -Force
    }
}

$submissionOutput = & ssh -tt $RemoteAlias "sbatch '$remoteScript'"
if ($LASTEXITCODE -ne 0) {
    throw "sbatch failed for stage $stageName"
}
$submissionText = ($submissionOutput | Out-String)
$jobIdMatch = [regex]::Match($submissionText, 'Submitted batch job (\d+)')
if (-not $jobIdMatch.Success) {
    throw "Could not parse Slurm job id. Output: $submissionText"
}

$state = [pscustomobject]@{
    remote_alias = $RemoteAlias
    remote_project = $RemoteProject
    remote_external_root = $RemoteExternalRoot
    remote_job_dir = $remoteJobDir
    submitted_at = (Get-Date).ToString("s")
    packet_profile = "smoothed_politics_smoke"
    political_response_sigma = $PoliticalResponseSigma
    seed_price_csv = $SeedPricePathCsv
    jobs = @(
        [pscustomobject]@{
            stage_name = $stageName
            job_id = $jobIdMatch.Groups[1].Value
            max_k = 2
            max_outer_iter = 1
            basis_count = 2
            demographic_source_mode = "historical_1950"
            finite_diff_step = 0.01
            ridge_lambda = 0.001
            candidate_scales = @(1.0, 0.5)
            trust_region_log_step = 0.08
            k_schedule = @(2)
            housing_clear_max_iter = 1
            political_response_mode = "smooth_tanh"
            political_response_sigma = $PoliticalResponseSigma
            remote_seed_csv = $remoteSeedCsv
        }
    )
}

$resolvedStatePath = if ([string]::IsNullOrWhiteSpace($StatePath)) {
    Join-Path $truthDir "hamilton_smoothed_politics_smoke_latest.json"
} else {
    $StatePath
}
$state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resolvedStatePath
$state.jobs | Format-Table -AutoSize
