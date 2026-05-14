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

function Convert-ToMatlabVectorExpr {
    param([double[]]$Values)
    if ($null -eq $Values -or $Values.Count -eq 0) {
        return "[]"
    }
    $formatted = $Values | ForEach-Object {
        [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $_)
    }
    return "[" + ($formatted -join "; ") + "]"
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
        [string]$MatlabModule
    )

    $candidateScalesExpr = Convert-ToMatlabVectorExpr -Values $Candidate.CandidateScales
    $kScheduleExpr = Convert-ToMatlabVectorExpr -Values $Candidate.KSchedule
    $matlabCommand = @(
        "cd('$RemoteOriginalDir')"
        ("run_original_5yr_transition_joint_supply_wedge_continuation({0}, {1}, {2}, '{3}', '{4}', '{5}', {6}, {7}, {8}, {9}, 0.65, {10}, {11}, {12}, {13})" -f `
            $Candidate.MaxK, `
            $Candidate.MaxOuterIter, `
            $Candidate.BasisCount, `
            $Candidate.RemoteSeedCsv, `
            $Candidate.StageName, `
            $Candidate.DemographicSourceMode, `
            $Candidate.FiniteDiffStep.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture), `
            $Candidate.RidgeLambda.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture), `
            $candidateScalesExpr, `
            $Candidate.TrustRegionLogStep.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture), `
            $Candidate.WedgeFloor.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture), `
            $Candidate.WedgeCap.ToString("R", [System.Globalization.CultureInfo]::InvariantCulture), `
            $kScheduleExpr, `
            $Candidate.HousingClearMaxIter)
    ) -join "; "

    return @"
#!/bin/bash
#SBATCH -J $($Candidate.StageName)
#SBATCH -p $Partition
#SBATCH -t $WallTime
#SBATCH --cpus-per-task=$CpusPerTask
#SBATCH --mem=${MemoryGb}G
#SBATCH -o $RemoteJobDir/$($Candidate.StageName)_%j.out
#SBATCH -e $RemoteJobDir/$($Candidate.StageName)_%j.err

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
$remoteJobDir = "$remoteOriginalDir/hamilton_joint_supply_wedge_$timestamp"
$remoteSeedCsv = "$remoteOriginalDir/$(Split-Path -Leaf $SeedPricePathCsv)"

$filesToSync = @(
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
        $commonSchedule = @(2, 3, 4, 5, 6, 8, 10, 12, 14)
        $candidates = @(
            @{
                StageName = "ham_k14_jointwedge_full_b3_i4_$timestamp"
                MaxK = 14
                MaxOuterIter = 4
                BasisCount = 3
                DemographicSourceMode = "historical_1950"
                FiniteDiffStep = 1.0e-2
                RidgeLambda = 1.0e-3
                CandidateScales = @(1.0, 0.5, 0.25)
                TrustRegionLogStep = 0.08
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 4
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_jointwedge_full_b4_i4_$timestamp"
                MaxK = 14
                MaxOuterIter = 4
                BasisCount = 4
                DemographicSourceMode = "historical_1950"
                FiniteDiffStep = 1.0e-2
                RidgeLambda = 1.0e-3
                CandidateScales = @(1.0, 0.5, 0.25)
                TrustRegionLogStep = 0.06
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 4
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_jointwedge_proxy_b3_i4_$timestamp"
                MaxK = 14
                MaxOuterIter = 4
                BasisCount = 3
                DemographicSourceMode = "historical_1950_two_group"
                FiniteDiffStep = 1.0e-2
                RidgeLambda = 1.0e-3
                CandidateScales = @(1.0, 0.5, 0.25)
                TrustRegionLogStep = 0.08
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 4
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_jointwedge_proxy_b4_i4_$timestamp"
                MaxK = 14
                MaxOuterIter = 4
                BasisCount = 4
                DemographicSourceMode = "historical_1950_two_group"
                FiniteDiffStep = 1.0e-2
                RidgeLambda = 1.0e-3
                CandidateScales = @(1.0, 0.5, 0.25)
                TrustRegionLogStep = 0.06
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 4
                RemoteSeedCsv = $remoteSeedCsv
            }
        )
    }
    "repair" {
        $commonSchedule = @(2, 3, 4, 5, 6, 8, 10, 12, 14)
        $candidates = @(
            @{
                StageName = "ham_k14_jointwedge_full_b4fix_i4_$timestamp"
                MaxK = 14
                MaxOuterIter = 4
                BasisCount = 4
                DemographicSourceMode = "historical_1950"
                FiniteDiffStep = 1.0e-2
                RidgeLambda = 1.0e-3
                CandidateScales = @(1.0, 0.5, 0.25)
                TrustRegionLogStep = 0.06
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 4
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_jointwedge_proxy_b3fix_i4_$timestamp"
                MaxK = 14
                MaxOuterIter = 4
                BasisCount = 3
                DemographicSourceMode = "historical_1950_two_group"
                FiniteDiffStep = 1.0e-2
                RidgeLambda = 1.0e-3
                CandidateScales = @(1.0, 0.5, 0.25)
                TrustRegionLogStep = 0.08
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 4
                RemoteSeedCsv = $remoteSeedCsv
            }
        )
    }
    "aggressive" {
        $commonSchedule = @(2, 3, 4, 5, 6, 8, 10, 12, 14)
        $candidates = @(
            @{
                StageName = "ham_k14_jointwedge_full_b2_i5_$timestamp"
                MaxK = 14
                MaxOuterIter = 5
                BasisCount = 2
                DemographicSourceMode = "historical_1950"
                FiniteDiffStep = 1.25e-2
                RidgeLambda = 7.5e-4
                CandidateScales = @(1.0, 0.75, 0.5, 0.25)
                TrustRegionLogStep = 0.10
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 5
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_jointwedge_full_b4wide_i5_$timestamp"
                MaxK = 14
                MaxOuterIter = 5
                BasisCount = 4
                DemographicSourceMode = "historical_1950"
                FiniteDiffStep = 1.0e-2
                RidgeLambda = 7.5e-4
                CandidateScales = @(1.0, 0.75, 0.5, 0.25)
                TrustRegionLogStep = 0.08
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 5
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_jointwedge_proxy_b2_i5_$timestamp"
                MaxK = 14
                MaxOuterIter = 5
                BasisCount = 2
                DemographicSourceMode = "historical_1950_two_group"
                FiniteDiffStep = 1.25e-2
                RidgeLambda = 7.5e-4
                CandidateScales = @(1.0, 0.75, 0.5, 0.25)
                TrustRegionLogStep = 0.10
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 5
                RemoteSeedCsv = $remoteSeedCsv
            },
            @{
                StageName = "ham_k14_jointwedge_proxy_b4wide_i5_$timestamp"
                MaxK = 14
                MaxOuterIter = 5
                BasisCount = 4
                DemographicSourceMode = "historical_1950_two_group"
                FiniteDiffStep = 1.0e-2
                RidgeLambda = 7.5e-4
                CandidateScales = @(1.0, 0.75, 0.5, 0.25)
                TrustRegionLogStep = 0.08
                WedgeFloor = -0.50
                WedgeCap = 0.50
                KSchedule = $commonSchedule
                HousingClearMaxIter = 5
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
        -MatlabModule $MatlabModule

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
        demographic_source_mode = $candidate.DemographicSourceMode
        finite_diff_step = $candidate.FiniteDiffStep
        ridge_lambda = $candidate.RidgeLambda
        candidate_scales = $candidate.CandidateScales
        trust_region_log_step = $candidate.TrustRegionLogStep
        k_schedule = $candidate.KSchedule
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
    seed_price_csv = $SeedPricePathCsv
    jobs = $jobs
}

$statePath = if ([string]::IsNullOrWhiteSpace($StatePath)) {
    Join-Path $truthDir "hamilton_joint_supply_wedge_packet_latest.json"
} else {
    $StatePath
}
$state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath
$jobs | Format-Table -AutoSize
