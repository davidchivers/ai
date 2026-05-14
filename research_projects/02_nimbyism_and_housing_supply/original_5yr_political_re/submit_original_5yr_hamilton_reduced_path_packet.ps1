param(
    [string]$RemoteAlias = "hamilton8",
    [string]$RemoteProject = "",
    [string]$Partition = "shared",
    [string]$WallTime = "12:00:00",
    [int]$MemoryGb = 10,
    [int]$CpusPerTask = 1,
    [string]$MatlabModule = "matlab/R2021a",
    [string]$SeedPricePathCsv = "",
    [string]$PacketProfile = "baseline",
    [string]$DemographicSourceMode = "historical_1950"
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

function New-RemoteSbatchContent {
    param(
        [string]$RemoteOriginalDir,
        [string]$RemoteJobDir,
        [string]$RemoteExternalRoot,
        [hashtable]$Candidate,
        [string]$Partition,
        [string]$WallTime,
        [int]$MemoryGb,
        [int]$CpusPerTask,
        [string]$MatlabModule,
        [string]$DemographicSourceMode
    )

    $jobName = $Candidate.StageName
    $candidateScalesExpr = "[" + (($Candidate.CandidateScales | ForEach-Object {
        $_.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture)
    }) -join "; ") + "]"
    $matlabCommand = @(
        "cd('$RemoteOriginalDir')"
        ("run_original_5yr_transition_reduced_path_jacobian({0}, {1}, {2}, '{3}', '{4}', '{5}', {6}, {7}, {8}, {9}, 0.65, 0.05, 5.0)" -f `
            $Candidate.MaxK, `
            $Candidate.MaxOuterIter, `
            $Candidate.BasisCount, `
            $Candidate.RemoteSeedCsv, `
            $Candidate.StageName, `
            $DemographicSourceMode, `
            $Candidate.FiniteDiffStep.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture), `
            $Candidate.RidgeLambda.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture), `
            $candidateScalesExpr, `
            $Candidate.TrustRegionLogStep.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture))
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
export ZAC_DAVID_EXTERNAL_ROOT="$RemoteExternalRoot"
cd "$RemoteOriginalDir"
matlab -singleCompThread -batch "$matlabCommand"
"@
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$truthDir = Join-Path $scriptDir "truth"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ([string]::IsNullOrWhiteSpace($SeedPricePathCsv)) {
    $SeedPricePathCsv = Join-Path $scriptDir "original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv"
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

$externalRootPathFile = Join-Path $truthDir "hamilton_external_root.txt"
if (-not (Test-Path -LiteralPath $externalRootPathFile)) {
    throw "Hamilton external root path file not found: $externalRootPathFile"
}
$remoteExternalRoot = (Get-Content -Raw $externalRootPathFile).Trim()
if ([string]::IsNullOrWhiteSpace($remoteExternalRoot)) {
    throw "Hamilton external root path is empty."
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
$remoteJobDir = "$remoteOriginalDir/hamilton_reduced_path_$timestamp"
$remoteSeedCsv = "$remoteOriginalDir/$(Split-Path -Leaf $SeedPricePathCsv)"

$filesToSync = @(
    @{ Local = (Join-Path $scriptDir "run_original_5yr_transition_reduced_path_jacobian.m"); Remote = "$remoteOriginalDir/run_original_5yr_transition_reduced_path_jacobian.m" },
    @{ Local = (Join-Path $scriptDir "build_original_5yr_demographic_path_from_historical_age_shares.m"); Remote = "$remoteOriginalDir/build_original_5yr_demographic_path_from_historical_age_shares.m" },
    @{ Local = (Join-Path $scriptDir "build_original_5yr_demographic_two_group_proxy.m"); Remote = "$remoteOriginalDir/build_original_5yr_demographic_two_group_proxy.m" },
    @{ Local = (Join-Path $scriptDir "build_original_5yr_demographic_path_from_age_state_csv.m"); Remote = "$remoteOriginalDir/build_original_5yr_demographic_path_from_age_state_csv.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\solve_transition_re_no_politics.m"); Remote = "$remoteExtensionDir/solve_transition_re_no_politics.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\solve_household_path_nimby.m"); Remote = "$remoteExtensionDir/solve_household_path_nimby.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\build_stationary_cross_section_nimby.m"); Remote = "$remoteExtensionDir/build_stationary_cross_section_nimby.m" },
    @{ Local = (Join-Path $projectRoot "extensions\re_no_politics\load_transition_matrix_data.m"); Remote = "$remoteExtensionDir/load_transition_matrix_data.m" },
    @{ Local = (Join-Path $projectRoot "code\steadystate\solve_original_5yr_bellman_core.m"); Remote = "$remoteSteadyDir/solve_original_5yr_bellman_core.m" },
    @{ Local = (Join-Path $projectRoot "code\steadystate\solve_original_5yr_political_steady_state.m"); Remote = "$remoteSteadyDir/solve_original_5yr_political_steady_state.m" },
    @{ Local = (Join-Path $projectRoot "code\steadystate\SolveSS_iter.m"); Remote = "$remoteSteadyDir/SolveSS_iter.m" },
    @{ Local = $SeedPricePathCsv; Remote = $remoteSeedCsv }
)

Invoke-Checked -Script {
    & ssh -tt $RemoteAlias "mkdir -p '$remoteOriginalDir' '$remoteExtensionDir' '$remoteSteadyDir' '$remoteJobDir' '$remoteExternalRoot/Code/Codes_ABB' '$remoteExternalRoot/Code/SteadyState'"
} -FailureMessage "Failed to create remote directories on $RemoteAlias"

foreach ($file in $filesToSync) {
    if (-not (Test-Path -LiteralPath $file.Local)) {
        throw "Required file not found: $($file.Local)"
    }
    Copy-ToRemoteScp -LocalFile $file.Local -RemotePath $file.Remote -RemoteAlias $RemoteAlias
}

Copy-ToRemoteScp -LocalFile $localCodesAbbTransition -RemotePath "$remoteExternalRoot/Code/Codes_ABB/TransitionMatrix.mat" -RemoteAlias $RemoteAlias
Copy-ToRemoteScp -LocalFile $localSteadyTransition -RemotePath "$remoteExternalRoot/Code/SteadyState/TransitionMatrix.mat" -RemoteAlias $RemoteAlias

switch ($PacketProfile.ToLowerInvariant()) {
    "baseline" {
        $candidates = @(
            @{
                StageName = "ham_k14_redjac_b3_i3_$timestamp"
                MaxK = 14
                MaxOuterIter = 3
                BasisCount = 3
                FiniteDiffStep = 2.5e-4
                RidgeLambda = 1e-3
                CandidateScales = @(1.0, 0.5, 0.25, 0.1)
                TrustRegionLogStep = 0.002
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_redjac_b4_i3_$timestamp"
                MaxK = 14
                MaxOuterIter = 3
                BasisCount = 4
                FiniteDiffStep = 2.5e-4
                RidgeLambda = 1e-3
                CandidateScales = @(1.0, 0.5, 0.25, 0.1)
                TrustRegionLogStep = 0.002
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_redjac_b4wide_i3_$timestamp"
                MaxK = 14
                MaxOuterIter = 3
                BasisCount = 4
                FiniteDiffStep = 2.5e-4
                RidgeLambda = 7.5e-4
                CandidateScales = @(1.0, 0.5, 0.25, 0.1)
                TrustRegionLogStep = 0.003
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_redjac_b5_i4_$timestamp"
                MaxK = 14
                MaxOuterIter = 4
                BasisCount = 5
                FiniteDiffStep = 2.0e-4
                RidgeLambda = 2e-3
                CandidateScales = @(1.0, 0.5, 0.25, 0.1)
                TrustRegionLogStep = 0.0015
                RemoteSeedCsv = $remoteSeedCsv
            }
        )
    }
    "aggressive" {
        $candidates = @(
            @{
                StageName = "ham_k14_redjac_b3wide_i4_$timestamp"
                MaxK = 14
                MaxOuterIter = 4
                BasisCount = 3
                FiniteDiffStep = 3.5e-4
                RidgeLambda = 5e-4
                CandidateScales = @(1.0, 0.75, 0.5, 0.25)
                TrustRegionLogStep = 0.004
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_redjac_b4aggr_i4_$timestamp"
                MaxK = 14
                MaxOuterIter = 4
                BasisCount = 4
                FiniteDiffStep = 3.0e-4
                RidgeLambda = 7.5e-4
                CandidateScales = @(1.0, 0.75, 0.5, 0.25)
                TrustRegionLogStep = 0.005
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_redjac_b5aggr_i5_$timestamp"
                MaxK = 14
                MaxOuterIter = 5
                BasisCount = 5
                FiniteDiffStep = 2.5e-4
                RidgeLambda = 1e-3
                CandidateScales = @(1.0, 0.75, 0.5, 0.25)
                TrustRegionLogStep = 0.0035
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_redjac_b6aggr_i5_$timestamp"
                MaxK = 14
                MaxOuterIter = 5
                BasisCount = 6
                FiniteDiffStep = 2.5e-4
                RidgeLambda = 2e-3
                CandidateScales = @(1.0, 0.75, 0.5, 0.25)
                TrustRegionLogStep = 0.003
                RemoteSeedCsv = $remoteSeedCsv
            }
        )
    }
    "exploratory" {
        $candidates = @(
            @{
                StageName = "ham_k14_redjac_b2global_i5_$timestamp"
                MaxK = 14
                MaxOuterIter = 5
                BasisCount = 2
                FiniteDiffStep = 4.0e-4
                RidgeLambda = 2.5e-4
                CandidateScales = @(1.0, 0.75, 0.5, 0.25, 0.125)
                TrustRegionLogStep = 0.008
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_redjac_b4loose_i6_$timestamp"
                MaxK = 14
                MaxOuterIter = 6
                BasisCount = 4
                FiniteDiffStep = 4.0e-4
                RidgeLambda = 3.5e-4
                CandidateScales = @(1.0, 0.75, 0.5, 0.25, 0.125)
                TrustRegionLogStep = 0.007
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_redjac_b6loose_i6_$timestamp"
                MaxK = 14
                MaxOuterIter = 6
                BasisCount = 6
                FiniteDiffStep = 3.0e-4
                RidgeLambda = 7.5e-4
                CandidateScales = @(1.0, 0.75, 0.5, 0.25, 0.125)
                TrustRegionLogStep = 0.005
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_redjac_b7explore_i6_$timestamp"
                MaxK = 14
                MaxOuterIter = 6
                BasisCount = 7
                FiniteDiffStep = 2.5e-4
                RidgeLambda = 1.0e-3
                CandidateScales = @(1.0, 0.75, 0.5, 0.25, 0.125)
                TrustRegionLogStep = 0.0045
                RemoteSeedCsv = $remoteSeedCsv
            }
        )
    }
    default {
        throw "Unsupported PacketProfile: $PacketProfile"
    }
}

$jobs = @()
foreach ($candidate in $candidates) {
    $localTempScript = Join-Path $env:TEMP ($candidate.StageName + ".sbatch")
    $remoteScript = "$remoteJobDir/$($candidate.StageName).sbatch"
    $content = New-RemoteSbatchContent `
        -RemoteOriginalDir $remoteOriginalDir `
        -RemoteJobDir $remoteJobDir `
        -RemoteExternalRoot $remoteExternalRoot `
        -Candidate $candidate `
        -Partition $Partition `
        -WallTime $WallTime `
        -MemoryGb $MemoryGb `
        -CpusPerTask $CpusPerTask `
        -MatlabModule $MatlabModule `
        -DemographicSourceMode $DemographicSourceMode
    Set-Content -LiteralPath $localTempScript -Value $content -NoNewline
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
        throw "sbatch failed for stage $($candidate.StageName)"
    }
    $submissionText = ($submissionOutput | Out-String)
    $jobIdMatch = [regex]::Match($submissionText, 'Submitted batch job (\d+)')
    if (-not $jobIdMatch.Success) {
        throw "Could not parse Slurm job id for stage $($candidate.StageName). Output: $submissionText"
    }

    $jobs += [pscustomobject]@{
        stage_name = $candidate.StageName
        job_id = $jobIdMatch.Groups[1].Value
        max_k = $candidate.MaxK
        max_outer_iter = $candidate.MaxOuterIter
        basis_count = $candidate.BasisCount
        finite_diff_step = $candidate.FiniteDiffStep
        ridge_lambda = $candidate.RidgeLambda
        candidate_scales = $candidate.CandidateScales
        trust_region_log_step = $candidate.TrustRegionLogStep
        seed_price_csv = $SeedPricePathCsv
        remote_seed_csv = $candidate.RemoteSeedCsv
    }
}

$state = [pscustomobject]@{
    remote_alias = $RemoteAlias
    remote_project = $RemoteProject
    remote_external_root = $remoteExternalRoot
    remote_job_dir = $remoteJobDir
    submitted_at = (Get-Date).ToString("s")
    packet_profile = $PacketProfile
    demographic_source_mode = $DemographicSourceMode
    seed_price_csv = $SeedPricePathCsv
    jobs = $jobs
}

$statePath = Join-Path $truthDir "hamilton_reduced_path_packet_latest.json"
$state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath
$jobs | Format-Table -AutoSize
