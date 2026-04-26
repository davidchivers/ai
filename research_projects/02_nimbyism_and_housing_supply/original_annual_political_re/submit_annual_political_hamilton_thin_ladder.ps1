param(
    [ValidateSet("T20", "T40", "T80", "T80Refine", "T80Hard", "T80Boom", "T80Decline", "T80Lag", "T80Lag5", "T80Lag10", "T80Death", "T20T40")]
    [string]$Stage = "T20",
    [string]$RemoteAlias = "hamilton8",
    [string]$RemoteBaseDir = "/nobackup/hfnt93/nimby_annual_runs",
    [string]$Partition = "shared",
    [string]$WallTime = "12:00:00",
    [int]$MemoryGb = 18,
    [int]$CpusPerTask = 1,
    [int]$PeriodIter = 2,
    [switch]$LaggedPassThrough,
    [int]$PassThroughLagYears = 1,
    [ValidateSet("baseline", "terminal_half", "terminal_drop")]
    [string]$AgeWeightVariant = "baseline",
    [ValidateSet("smooth", "hard_sign")]
    [string]$PressureMode = "smooth",
    [ValidateSet("source_path", "flat_entrant", "baby_boom", "secular_decline")]
    [string]$DemographicScenario = "source_path",
    [double]$DemographicShockAmplitude = 0.25,
    [string]$MatlabModule = "matlab/R2025a",
    [string]$StatePath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

function Copy-DirectoryFiles {
    param(
        [string]$SourceDir,
        [string]$TargetDir,
        [string]$Filter = "*",
        [switch]$Recurse
    )
    if (-not (Test-Path -LiteralPath $SourceDir)) {
        throw "Source directory not found: $SourceDir"
    }
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    $items = if ($Recurse) {
        Get-ChildItem -LiteralPath $SourceDir -File -Filter $Filter -Recurse
    } else {
        Get-ChildItem -LiteralPath $SourceDir -File -Filter $Filter
    }
    $sourceRoot = (Resolve-Path -LiteralPath $SourceDir).ProviderPath.TrimEnd('\')
    foreach ($item in $items) {
        $relative = $item.FullName.Substring($sourceRoot.Length).TrimStart('\')
        $dest = Join-Path $TargetDir $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        Copy-Item -LiteralPath $item.FullName -Destination $dest -Force
    }
}

function Format-BashArray {
    param([object[]]$Values)
    return ($Values | ForEach-Object { '"' + [string]$_ + '"' }) -join " "
}

function Format-ScaleTag {
    param([double]$Value)
    return ("{0:F3}" -f $Value).Replace(".", "p")
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir "truth"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$stageName = "annpol_thin_${Stage}_${timestamp}"
$packetRoot = Join-Path $env:TEMP "nimby_annpol_ham_packets"
$stageDir = Join-Path $packetRoot $stageName
$annualDir = Join-Path $stageDir "annual"
$steadyRoot = Join-Path $stageDir "SteadyState"
$modIrfDir = Join-Path $steadyRoot "Mod_IRF"
$modDataDir = Join-Path $steadyRoot "Mod_Data"
$modFunctionsDir = Join-Path $steadyRoot "Mod_Functions"
$compeconDir = Join-Path $stageDir "COMPECON"
$hpcDir = Join-Path $stageDir "hpc"
New-Item -ItemType Directory -Force -Path $annualDir, $modIrfDir, $modDataDir, $modFunctionsDir, $compeconDir, $hpcDir | Out-Null

$localModIrf = "C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\Mod_IRF"
$localModData = "C:\Users\Dave_\Dropbox\Zac and David\Code\SteadyState\Mod_Data"
$localModFunctions = "D:\SteadyState\Mod_Functions"
$localCompecon = "C:\Users\Dave_\COMPECON"
$sourceMat = Join-Path $localModIrf "loop101_output_extended.mat"
$transitionMat = Join-Path $localModIrf "TransitionMatrix.mat"

foreach ($required in @(
    (Join-Path $scriptDir "run_annual_political_transition_fail_safe.m"),
    $sourceMat,
    $transitionMat,
    $localModData,
    $localModFunctions,
    (Join-Path $localCompecon "CEtools")
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required local input not found: $required"
    }
}

Copy-Item -LiteralPath (Join-Path $scriptDir "run_annual_political_transition_fail_safe.m") -Destination (Join-Path $annualDir "run_annual_political_transition_fail_safe.m") -Force
Copy-DirectoryFiles -SourceDir $localModIrf -TargetDir $modIrfDir -Filter "*.m"
Copy-Item -LiteralPath $sourceMat -Destination (Join-Path $modIrfDir "loop101_output_extended.mat") -Force
Copy-Item -LiteralPath $transitionMat -Destination (Join-Path $modIrfDir "TransitionMatrix.mat") -Force
Copy-DirectoryFiles -SourceDir $localModData -TargetDir $modDataDir -Filter "*"
Copy-DirectoryFiles -SourceDir $localModFunctions -TargetDir $modFunctionsDir -Filter "*.m"

# Copy the full CEtools tree so Hamilton can use Linux .mexa64 binaries and private MEX routines.
Copy-DirectoryFiles -SourceDir (Join-Path $localCompecon "CEtools") -TargetDir (Join-Path $compeconDir "CEtools") -Filter "*" -Recurse
if (Test-Path -LiteralPath (Join-Path $localCompecon "CEdemos")) {
    Copy-DirectoryFiles -SourceDir (Join-Path $localCompecon "CEdemos") -TargetDir (Join-Path $compeconDir "CEdemos") -Filter "*.m" -Recurse
}
if (Test-Path -LiteralPath (Join-Path $localCompecon "compecon2011_64")) {
    Copy-DirectoryFiles -SourceDir (Join-Path $localCompecon "compecon2011_64") -TargetDir (Join-Path $compeconDir "compecon2011_64") -Filter "*" -Recurse
}

if ($Stage -in @("T80Lag5", "T80Lag10")) {
    # Long-lag robustness around the usable lagged eta region.
    $candidateSpecs = @(
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.090 1.00]"; Label = "vs0p020_eta0p090"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.105 1.00]"; Label = "vs0p020_eta0p105"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.120 1.00]"; Label = "vs0p020_eta0p120"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.150 1.00]"; Label = "vs0p020_eta0p150"; AgeWeightVariant = $AgeWeightVariant }
    )
} elseif ($Stage -eq "T80Death") {
    $candidateSpecs = @()
    foreach ($eta in @("0.075", "0.090", "0.105")) {
        foreach ($variant in @("baseline", "terminal_half", "terminal_drop")) {
            $etaTag = $eta.Replace(".", "p")
            $candidateSpecs += [pscustomobject]@{
                VoteScale = 0.020
                Candidate = "[0 $eta 1.00]"
                Label = "vs0p020_eta${etaTag}_${variant}"
                AgeWeightVariant = $variant
            }
        }
    }
} elseif ($Stage -eq "T80Hard") {
    # Hard-sign tau = 0 comparison around the usable eta region.
    $candidateSpecs = @(
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.090 1.00]"; Label = "vs0p020_eta0p090_hard"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.105 1.00]"; Label = "vs0p020_eta0p105_hard"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.120 1.00]"; Label = "vs0p020_eta0p120_hard"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.150 1.00]"; Label = "vs0p020_eta0p150_hard"; AgeWeightVariant = $AgeWeightVariant }
    )
} elseif ($Stage -in @("T80Refine", "T80Lag", "T80Boom", "T80Decline")) {
    # One-parameter refinement: rho = 0, vote_scale = 0.020, gamma = 1, eta = phi.
    # This treats eta as direct political-pressure-to-log-price pass-through.
    $candidateSpecs = @(
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.060 1.00]"; Label = "vs0p020_eta0p060"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.075 1.00]"; Label = "vs0p020_eta0p075"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.090 1.00]"; Label = "vs0p020_eta0p090"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.105 1.00]"; Label = "vs0p020_eta0p105"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.120 1.00]"; Label = "vs0p020_eta0p120"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.150 1.00]"; Label = "vs0p020_eta0p150"; AgeWeightVariant = $AgeWeightVariant }
    )
} else {
    $candidateSpecs = @(
        [pscustomobject]@{ VoteScale = 0.015; Candidate = "[0 0.06 1.00]"; Label = "vs0p015_r0_phi0p06_g1p00"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.020; Candidate = "[0 0.15 0.50]"; Label = "vs0p020_r0_phi0p15_g0p50"; AgeWeightVariant = $AgeWeightVariant },
        [pscustomobject]@{ VoteScale = 0.030; Candidate = "[0 0.10 1.00]"; Label = "vs0p030_r0_phi0p10_g1p00"; AgeWeightVariant = $AgeWeightVariant }
    )
}

$tValuesForStage = switch ($Stage) {
    "T20" { @(20) }
    "T40" { @(40) }
    "T80" { @(80) }
    "T80Refine" { @(80) }
    "T80Hard" { @(80) }
    "T80Boom" { @(80) }
    "T80Decline" { @(80) }
    "T80Lag" { @(80) }
    "T80Lag5" { @(80) }
    "T80Lag10" { @(80) }
    "T80Death" { @(80) }
    "T20T40" { @(20, 40) }
}

$useLaggedPassThrough = $LaggedPassThrough.IsPresent -or $Stage -in @("T80Lag", "T80Lag5", "T80Lag10")
if ($Stage -eq "T80Lag5") {
    $PassThroughLagYears = 5
} elseif ($Stage -eq "T80Lag10") {
    $PassThroughLagYears = 10
}
$laggedMatlabLiteral = if ($useLaggedPassThrough) { "true" } else { "false" }
$pressureModeForStage = if ($Stage -eq "T80Hard") { "hard_sign" } else { $PressureMode }
$demographicScenarioForStage = switch ($Stage) {
    "T80Boom" { "baby_boom" }
    "T80Decline" { "secular_decline" }
    default { $DemographicScenario }
}

$tasks = @()
foreach ($t in $tValuesForStage) {
    foreach ($candidate in $candidateSpecs) {
        $tasks += [pscustomobject]@{
            T = $t
            VoteScale = $candidate.VoteScale
            Candidate = $candidate.Candidate
            Label = "T${t}_$($candidate.Label)"
            AgeWeightVariant = $candidate.AgeWeightVariant
        }
    }
}

$arrayMax = $tasks.Count - 1
$tArray = Format-BashArray -Values ($tasks | ForEach-Object { $_.T })
$scaleArray = Format-BashArray -Values ($tasks | ForEach-Object { "{0:F3}" -f $_.VoteScale })
$candidateArray = Format-BashArray -Values ($tasks | ForEach-Object { $_.Candidate })
$labelArray = Format-BashArray -Values ($tasks | ForEach-Object { $_.Label })
$ageWeightVariantArray = Format-BashArray -Values ($tasks | ForEach-Object { $_.AgeWeightVariant })

$slurmTemplate = @'
#!/bin/bash
#SBATCH -J __STAGE_NAME__
#SBATCH -p __PARTITION__
#SBATCH -t __WALLTIME__
#SBATCH --cpus-per-task=__CPUS__
#SBATCH --mem=__MEMORY__G
#SBATCH --array=0-__ARRAY_MAX__
#SBATCH -o logs/__STAGE_NAME___%A_%a.out
#SBATCH -e logs/__STAGE_NAME___%A_%a.err

set -euo pipefail
module load __MATLAB_MODULE__
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="$(cd "$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "$RUN_ROOT/hpc/logs"
cd "$RUN_ROOT/annual"

T_VALUES=(__T_ARRAY__)
SCALE_VALUES=(__SCALE_ARRAY__)
CANDIDATES=(__CANDIDATE_ARRAY__)
LABELS=(__LABEL_ARRAY__)
AGE_WEIGHT_VARIANTS=(__AGE_WEIGHT_VARIANT_ARRAY__)

IDX="$SLURM_ARRAY_TASK_ID"
T="${T_VALUES[$IDX]}"
VS="${SCALE_VALUES[$IDX]}"
CAND="${CANDIDATES[$IDX]}"
LABEL="${LABELS[$IDX]}"
AWV="${AGE_WEIGHT_VARIANTS[$IDX]}"
RUNTAG="__STAGE_NAME___$LABEL"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; fprintf('lookup path: %s\n', which('lookup')); run_annual_political_transition_fail_safe('RunTag','$RUNTAG','TSchedule',[$T],'PeriodIter',__PERIOD_ITER__,'LaggedPassThrough',__LAGGED_PASS_THROUGH__,'PassThroughLagYears',__PASS_THROUGH_LAG_YEARS__,'AgeWeightVariant','$AWV','PressureMode','__PRESSURE_MODE__','DemographicScenario','__DEMOGRAPHIC_SCENARIO__','DemographicShockAmplitude',__DEMOGRAPHIC_SHOCK_AMPLITUDE__,'VoteScale',$VS,'Candidates',$CAND,'ModIrfDir','$RUN_ROOT/SteadyState/Mod_IRF','ModFunctionsDir','$RUN_ROOT/SteadyState/Mod_Functions','CompeconDir','$RUN_ROOT/COMPECON')"
'@

$slurmContent = $slurmTemplate.
    Replace("__STAGE_NAME__", $stageName).
    Replace("__PARTITION__", $Partition).
    Replace("__WALLTIME__", $WallTime).
    Replace("__CPUS__", [string]$CpusPerTask).
    Replace("__MEMORY__", [string]$MemoryGb).
    Replace("__ARRAY_MAX__", [string]$arrayMax).
    Replace("__MATLAB_MODULE__", $MatlabModule).
    Replace("__T_ARRAY__", $tArray).
    Replace("__SCALE_ARRAY__", $scaleArray).
    Replace("__CANDIDATE_ARRAY__", $candidateArray).
    Replace("__LABEL_ARRAY__", $labelArray).
    Replace("__AGE_WEIGHT_VARIANT_ARRAY__", $ageWeightVariantArray).
    Replace("__PERIOD_ITER__", [string]$PeriodIter).
    Replace("__LAGGED_PASS_THROUGH__", $laggedMatlabLiteral).
    Replace("__PASS_THROUGH_LAG_YEARS__", [string]$PassThroughLagYears).
    Replace("__PRESSURE_MODE__", $pressureModeForStage).
    Replace("__DEMOGRAPHIC_SCENARIO__", $demographicScenarioForStage).
    Replace("__DEMOGRAPHIC_SHOCK_AMPLITUDE__", [string]$DemographicShockAmplitude)

$slurmPath = Join-Path $hpcDir "annual_political_thin_ladder_array.slurm"
Set-Content -LiteralPath $slurmPath -Value $slurmContent -NoNewline

$archivePath = Join-Path $packetRoot "$stageName.tar.gz"
if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}
Invoke-Checked -Script {
    & tar -czf $archivePath -C $stageDir .
} -FailureMessage "Failed to create Hamilton packet archive."

$remoteRunDir = "$($RemoteBaseDir.TrimEnd('/'))/$stageName"
$remoteArchive = "$remoteRunDir/$stageName.tar.gz"

Invoke-Checked -Script {
    & ssh $RemoteAlias "mkdir -p '$remoteRunDir'"
} -FailureMessage "Failed to create remote run directory."

Invoke-Checked -Script {
    & scp $archivePath "${RemoteAlias}:$remoteArchive"
} -FailureMessage "Failed to upload Hamilton packet archive."

Invoke-Checked -Script {
    & ssh $RemoteAlias "tar -xzf '$remoteArchive' -C '$remoteRunDir' && mkdir -p '$remoteRunDir/hpc/logs' && chmod +x '$remoteRunDir/hpc/annual_political_thin_ladder_array.slurm'"
} -FailureMessage "Failed to unpack Hamilton packet."

$submitOutput = & ssh $RemoteAlias "cd '$remoteRunDir/hpc' && sbatch --nice=10000 annual_political_thin_ladder_array.slurm"
if ($LASTEXITCODE -ne 0) {
    throw "sbatch failed."
}
$submitText = $submitOutput | Out-String
$jobIdMatch = [regex]::Match($submitText, 'Submitted batch job (\d+)')
if (-not $jobIdMatch.Success) {
    throw "Could not parse Slurm job id. Output: $submitText"
}
$jobId = $jobIdMatch.Groups[1].Value

$state = [pscustomobject]@{
    remote_alias = $RemoteAlias
    remote_run_dir = $remoteRunDir
    remote_archive = $remoteArchive
    submitted_at = (Get-Date).ToString("s")
    stage_name = $stageName
    slurm_array_job_id = $jobId
    stage = $Stage
    walltime = $WallTime
    period_iter = $PeriodIter
    lagged_pass_through = $useLaggedPassThrough
    pass_through_lag_years = $PassThroughLagYears
    age_weight_variant = $AgeWeightVariant
    tasks = $tasks
    workflow = "thin-one-candidate-per-task-with-compecon-mexa64"
}

$resolvedStatePath = if ([string]::IsNullOrWhiteSpace($StatePath)) {
    Join-Path (Join-Path $truthDir "annual_political_hamilton") "annual_political_hamilton_thin_latest.json"
} else {
    $StatePath
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $resolvedStatePath) | Out-Null
$state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $resolvedStatePath

[pscustomobject]@{
    JobId = $jobId
    StageName = $stageName
    RemoteRunDir = $remoteRunDir
    StatePath = $resolvedStatePath
    Tasks = $tasks.Count
    WallTime = $WallTime
} | Format-List
