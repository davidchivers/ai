param(
    [ValidateSet("T4", "T4BBTail", "T4Proj", "T20", "T20Proj", "T40", "T40Proj", "T80", "T80All", "T80SecDamp", "T80Proj")]
    [string]$Stage = "T4",
    [string]$RemoteAlias = "hamilton8",
    [string]$RemoteBaseDir = "/nobackup/hfnt93/nimby_annual_runs",
    [string]$Partition = "shared",
    [string]$WallTime = "12:00:00",
    [int]$MemoryGb = 22,
    [int]$CpusPerTask = 1,
    [int]$OuterIter = 3,
    [int]$TailYears = 20,
    [ValidateSet("reference", "terminal_fixed_point")]
    [string]$TerminalAnchor = "reference",
    [int]$TerminalIter = 20,
    [double]$TerminalRelaxation = 0.25,
    [double]$PathRelaxation = 0.25,
    [double]$VoteScale = 0.020,
    [double]$DemographicShockAmplitude = 0.25,
    [string]$MatlabModule = "matlab/R2025a",
    [string]$StatePath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Checked {
    param([scriptblock]$Script, [string]$FailureMessage)
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

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir "truth"
$timestamp = Get-Date -Format "MMddHHmm"
$stageCode = switch ($Stage) {
    "T4BBTail" { "T4B" }
    "T4Proj" { "T4P" }
    "T20Proj" { "T20P" }
    "T40Proj" { "T40P" }
    "T80Proj" { "T80P" }
    "T80All" { "T80A" }
    "T80SecDamp" { "T80D" }
    default { $Stage }
}
$stageName = "re${stageCode}_${timestamp}"
$packetRoot = Join-Path $env:TEMP "nimby_annre_ham_packets"
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
$runner = Join-Path $scriptDir "run_annual_political_full_re_price_path.m"
$sourceMat = Join-Path $localModIrf "loop101_output_extended.mat"
$transitionMat = Join-Path $localModIrf "TransitionMatrix.mat"

foreach ($required in @($runner, $sourceMat, $transitionMat, $localModData, $localModFunctions, (Join-Path $localCompecon "CEtools"))) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required local input not found: $required"
    }
}

Copy-Item -LiteralPath $runner -Destination (Join-Path $annualDir "run_annual_political_full_re_price_path.m") -Force
Copy-DirectoryFiles -SourceDir $localModIrf -TargetDir $modIrfDir -Filter "*.m"
Copy-Item -LiteralPath $sourceMat -Destination (Join-Path $modIrfDir "loop101_output_extended.mat") -Force
Copy-Item -LiteralPath $transitionMat -Destination (Join-Path $modIrfDir "TransitionMatrix.mat") -Force
Copy-DirectoryFiles -SourceDir $localModData -TargetDir $modDataDir -Filter "*"
Copy-DirectoryFiles -SourceDir $localModFunctions -TargetDir $modFunctionsDir -Filter "*.m"
Copy-DirectoryFiles -SourceDir (Join-Path $localCompecon "CEtools") -TargetDir (Join-Path $compeconDir "CEtools") -Filter "*" -Recurse
if (Test-Path -LiteralPath (Join-Path $localCompecon "CEdemos")) {
    Copy-DirectoryFiles -SourceDir (Join-Path $localCompecon "CEdemos") -TargetDir (Join-Path $compeconDir "CEdemos") -Filter "*.m" -Recurse
}
if (Test-Path -LiteralPath (Join-Path $localCompecon "compecon2011_64")) {
    Copy-DirectoryFiles -SourceDir (Join-Path $localCompecon "compecon2011_64") -TargetDir (Join-Path $compeconDir "compecon2011_64") -Filter "*" -Recurse
}

$tasks = @()
if ($Stage -eq "T4") {
    foreach ($spec in @(
        [pscustomobject]@{ Scenario = "fixed_age_share"; Label = "fix" },
        [pscustomobject]@{ Scenario = "baby_boom"; Label = "bb" },
        [pscustomobject]@{ Scenario = "secular_decline"; Label = "dec" }
    )) {
        $tasks += [pscustomobject]@{ T = 4; TailYears = $TailYears; Eta = 0.090; Scenario = $spec.Scenario; Label = "t4_$($spec.Label)_e09" }
    }
} elseif ($Stage -eq "T4BBTail") {
    $tasks += [pscustomobject]@{ T = 4; TailYears = $TailYears; Eta = 0.090; Scenario = "baby_boom"; Label = "t4_bb_tail_e09" }
} elseif ($Stage -eq "T4Proj") {
    foreach ($spec in @(
        [pscustomobject]@{ Scenario = "forecast_low"; Label = "pl" },
        [pscustomobject]@{ Scenario = "forecast_median"; Label = "pm" },
        [pscustomobject]@{ Scenario = "forecast_high"; Label = "ph" }
    )) {
        $tasks += [pscustomobject]@{ T = 4; TailYears = $TailYears; Eta = 0.090; Scenario = $spec.Scenario; Label = "t4_$($spec.Label)_e09" }
    }
} elseif ($Stage -eq "T20") {
    foreach ($spec in @(
        [pscustomobject]@{ Scenario = "baby_boom"; Label = "bb" },
        [pscustomobject]@{ Scenario = "secular_decline"; Label = "dec" }
    )) {
        foreach ($eta in @(0.090, 0.105)) {
            $etaTag = ("{0:F2}" -f (100 * $eta)).Replace(".", "")
            $tasks += [pscustomobject]@{ T = 20; TailYears = $TailYears; Eta = $eta; Scenario = $spec.Scenario; Label = "t20_$($spec.Label)_e$etaTag" }
        }
    }
} elseif ($Stage -eq "T20Proj") {
    foreach ($spec in @(
        [pscustomobject]@{ Scenario = "forecast_low"; Label = "pl" },
        [pscustomobject]@{ Scenario = "forecast_median"; Label = "pm" },
        [pscustomobject]@{ Scenario = "forecast_high"; Label = "ph" }
    )) {
        $tasks += [pscustomobject]@{ T = 20; TailYears = $TailYears; Eta = 0.090; Scenario = $spec.Scenario; Label = "t20_$($spec.Label)_e09" }
    }
} elseif ($Stage -eq "T40") {
    foreach ($spec in @(
        [pscustomobject]@{ Scenario = "fixed_age_share"; Label = "fix" },
        [pscustomobject]@{ Scenario = "secular_decline"; Label = "dec" }
    )) {
        $tasks += [pscustomobject]@{ T = 40; TailYears = $TailYears; Eta = 0.090; Scenario = $spec.Scenario; Label = "t40_$($spec.Label)_e09" }
    }
} elseif ($Stage -eq "T40Proj") {
    foreach ($spec in @(
        [pscustomobject]@{ Scenario = "forecast_low"; Label = "pl" },
        [pscustomobject]@{ Scenario = "forecast_median"; Label = "pm" },
        [pscustomobject]@{ Scenario = "forecast_high"; Label = "ph" }
    )) {
        $tasks += [pscustomobject]@{ T = 40; TailYears = $TailYears; Eta = 0.090; Scenario = $spec.Scenario; Label = "t40_$($spec.Label)_e09" }
    }
} elseif ($Stage -eq "T80Proj") {
    foreach ($spec in @(
        [pscustomobject]@{ Scenario = "forecast_low"; Label = "pl" },
        [pscustomobject]@{ Scenario = "forecast_median"; Label = "pm" },
        [pscustomobject]@{ Scenario = "forecast_high"; Label = "ph" }
    )) {
        foreach ($eta in @(0.090, 0.105)) {
            $etaTag = ("{0:F2}" -f (100 * $eta)).Replace(".", "")
            $tasks += [pscustomobject]@{ T = 80; TailYears = $TailYears; Eta = $eta; Scenario = $spec.Scenario; Label = "t80_$($spec.Label)_e$etaTag" }
        }
    }
} elseif ($Stage -eq "T80All") {
    foreach ($spec in @(
        [pscustomobject]@{ Scenario = "fixed_age_share"; Label = "fix" },
        [pscustomobject]@{ Scenario = "baby_boom"; Label = "bb" },
        [pscustomobject]@{ Scenario = "secular_decline"; Label = "dec" },
        [pscustomobject]@{ Scenario = "forecast_low"; Label = "pl" },
        [pscustomobject]@{ Scenario = "forecast_median"; Label = "pm" },
        [pscustomobject]@{ Scenario = "forecast_high"; Label = "ph" }
    )) {
        $tasks += [pscustomobject]@{ T = 80; TailYears = $TailYears; Eta = 0.090; Scenario = $spec.Scenario; Label = "t80_$($spec.Label)_e09" }
    }
} elseif ($Stage -eq "T80SecDamp") {
    foreach ($eta in @(0.090, 0.105)) {
        $etaTag = ("{0:F2}" -f (100 * $eta)).Replace(".", "")
        $tasks += [pscustomobject]@{ T = 80; TailYears = $TailYears; Eta = $eta; Scenario = "secular_decline"; Label = "t80_dec_d$etaTag" }
    }
} else {
    foreach ($spec in @(
        [pscustomobject]@{ Scenario = "baby_boom"; Label = "bb" },
        [pscustomobject]@{ Scenario = "secular_decline"; Label = "dec" }
    )) {
        foreach ($eta in @(0.090, 0.105)) {
            $etaTag = ("{0:F2}" -f (100 * $eta)).Replace(".", "")
            $tasks += [pscustomobject]@{ T = 80; TailYears = $TailYears; Eta = $eta; Scenario = $spec.Scenario; Label = "t80_$($spec.Label)_e$etaTag" }
        }
    }
}

$arrayMax = $tasks.Count - 1
$tArray = Format-BashArray -Values ($tasks | ForEach-Object { $_.T })
$tailArray = Format-BashArray -Values ($tasks | ForEach-Object { $_.TailYears })
$etaArray = Format-BashArray -Values ($tasks | ForEach-Object { "{0:F3}" -f $_.Eta })
$scenarioArray = Format-BashArray -Values ($tasks | ForEach-Object { $_.Scenario })
$labelArray = Format-BashArray -Values ($tasks | ForEach-Object { $_.Label })

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
TAIL_VALUES=(__TAIL_ARRAY__)
ETA_VALUES=(__ETA_ARRAY__)
SCENARIOS=(__SCENARIO_ARRAY__)
LABELS=(__LABEL_ARRAY__)

IDX="$SLURM_ARRAY_TASK_ID"
T="${T_VALUES[$IDX]}"
TAIL="${TAIL_VALUES[$IDX]}"
ETA="${ETA_VALUES[$IDX]}"
SCENARIO="${SCENARIOS[$IDX]}"
LABEL="${LABELS[$IDX]}"
RUNTAG="__STAGE_NAME___$LABEL"

matlab -singleCompThread -batch "addpath(fullfile('$RUN_ROOT','COMPECON','CEtools')); rehash; fprintf('lookup path: %s\n', which('lookup')); run_annual_political_full_re_price_path('RunTag','$RUNTAG','T',str2double('$T'),'TailYears',str2double('$TAIL'),'TerminalAnchor','__TERMINAL_ANCHOR__','TerminalIter',__TERMINAL_ITER__,'TerminalRelaxation',__TERMINAL_RELAXATION__,'OuterIter',__OUTER_ITER__,'PathRelaxation',__PATH_RELAXATION__,'Eta',str2double('$ETA'),'VoteScale',__VOTE_SCALE__,'DemographicScenario','$SCENARIO','DemographicShockAmplitude',__DEMOGRAPHIC_SHOCK_AMPLITUDE__,'ModIrfDir','$RUN_ROOT/SteadyState/Mod_IRF','ModFunctionsDir','$RUN_ROOT/SteadyState/Mod_Functions','CompeconDir','$RUN_ROOT/COMPECON')"
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
    Replace("__TAIL_ARRAY__", $tailArray).
    Replace("__ETA_ARRAY__", $etaArray).
    Replace("__SCENARIO_ARRAY__", $scenarioArray).
    Replace("__LABEL_ARRAY__", $labelArray).
    Replace("__TERMINAL_ANCHOR__", $TerminalAnchor).
    Replace("__TERMINAL_ITER__", [string]$TerminalIter).
    Replace("__TERMINAL_RELAXATION__", [string]$TerminalRelaxation).
    Replace("__OUTER_ITER__", [string]$OuterIter).
    Replace("__PATH_RELAXATION__", [string]$PathRelaxation).
    Replace("__VOTE_SCALE__", [string]$VoteScale).
    Replace("__DEMOGRAPHIC_SHOCK_AMPLITUDE__", [string]$DemographicShockAmplitude)

$slurmPath = Join-Path $hpcDir "annual_full_re_price_path_array.slurm"
Set-Content -LiteralPath $slurmPath -Value $slurmContent -NoNewline

$archivePath = Join-Path $packetRoot "$stageName.tar.gz"
if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}
Invoke-Checked -Script { & tar -czf $archivePath -C $stageDir . } -FailureMessage "Failed to create Hamilton packet archive."

$remoteRunDir = "$($RemoteBaseDir.TrimEnd('/'))/$stageName"
$remoteArchive = "$remoteRunDir/$stageName.tar.gz"
Invoke-Checked -Script { & ssh $RemoteAlias "mkdir -p '$remoteRunDir'" } -FailureMessage "Failed to create remote run directory."
Invoke-Checked -Script { & scp $archivePath "${RemoteAlias}:$remoteArchive" } -FailureMessage "Failed to upload Hamilton packet archive."
Invoke-Checked -Script { & ssh $RemoteAlias "tar -xzf '$remoteArchive' -C '$remoteRunDir' && mkdir -p '$remoteRunDir/hpc/logs' && chmod +x '$remoteRunDir/hpc/annual_full_re_price_path_array.slurm'" } -FailureMessage "Failed to unpack Hamilton packet."

$submitOutput = & ssh $RemoteAlias "cd '$remoteRunDir/hpc' && sbatch --nice=10000 annual_full_re_price_path_array.slurm"
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
    outer_iter = $OuterIter
    tail_years = $TailYears
    terminal_anchor = $TerminalAnchor
    terminal_iter = $TerminalIter
    terminal_relaxation = $TerminalRelaxation
    path_relaxation = $PathRelaxation
    workflow = "perfect-foresight-house-price-path-re"
    tasks = $tasks
}

$resolvedStatePath = if ([string]::IsNullOrWhiteSpace($StatePath)) {
    Join-Path (Join-Path $truthDir "annual_full_re_hamilton") "annual_full_re_hamilton_latest.json"
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
