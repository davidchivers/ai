param(
    [string]$RemoteAlias = "hamilton8",
    [string]$RemoteBaseDir = "/nobackup/hfnt93/nimby_annual_runs",
    [string]$Partition = "shared",
    [string]$WallTime = "06:00:00",
    [int]$MemoryGb = 16,
    [int]$CpusPerTask = 1,
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

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir "truth"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$stageName = "annpol_lad_${timestamp}"
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
    $localCompecon
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
Copy-DirectoryFiles -SourceDir (Join-Path $localCompecon "CEdemos") -TargetDir (Join-Path $compeconDir "CEdemos") -Filter "*.m" -Recurse
Copy-DirectoryFiles -SourceDir (Join-Path $localCompecon "compecon2011_64") -TargetDir (Join-Path $compeconDir "compecon2011_64") -Filter "*" -Recurse

$slurmPath = Join-Path $hpcDir "annual_political_ladder_array.slurm"
$slurmContent = @"
#!/bin/bash
#SBATCH -J $stageName
#SBATCH -p $Partition
#SBATCH -t $WallTime
#SBATCH --cpus-per-task=$CpusPerTask
#SBATCH --mem=${MemoryGb}G
#SBATCH --array=0-5
#SBATCH -o logs/${stageName}_%A_%a.out
#SBATCH -e logs/${stageName}_%A_%a.err

set -euo pipefail
module load $MatlabModule
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

RUN_ROOT="`$(cd "`$SLURM_SUBMIT_DIR/.." && pwd)"
mkdir -p "`$RUN_ROOT/hpc/logs"
cd "`$RUN_ROOT/annual"

T_VALUES=(20 20 20 40 40 40)
SCALE_VALUES=(0.015 0.020 0.030 0.015 0.020 0.030)
CANDIDATES=(
"[0 0.1 0.5; 0 0.03 1.5; 0 0.06 1]"
"[0 0.06 1; 0 0.1 0.5; 0 0.15 0.5]"
"[0 0.06 1.5; 0 0.1 1; 0 0.15 0.5]"
"[0 0.1 0.5; 0 0.03 1.5; 0 0.06 1]"
"[0 0.06 1; 0 0.1 0.5; 0 0.15 0.5]"
"[0 0.06 1.5; 0 0.1 1; 0 0.15 0.5]"
)

IDX="`$SLURM_ARRAY_TASK_ID"
T="`${T_VALUES[`$IDX]}"
VS="`${SCALE_VALUES[`$IDX]}"
CAND="`${CANDIDATES[`$IDX]}"
VSTAG="`$(printf "%.3f" "`$VS" | tr '.' 'p')"
RUNTAG="${stageName}_T`${T}_vs`$VSTAG"

matlab -singleCompThread -batch "run_annual_political_transition_fail_safe('RunTag','`$RUNTAG','TSchedule',[`$T],'PeriodIter',2,'VoteScale',`$VS,'Candidates',`$CAND,'ModIrfDir','`$RUN_ROOT/SteadyState/Mod_IRF','ModFunctionsDir','`$RUN_ROOT/SteadyState/Mod_Functions','CompeconDir','`$RUN_ROOT/COMPECON')"
"@
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
    & ssh $RemoteAlias "tar -xzf '$remoteArchive' -C '$remoteRunDir' && mkdir -p '$remoteRunDir/hpc/logs' && chmod +x '$remoteRunDir/hpc/annual_political_ladder_array.slurm'"
} -FailureMessage "Failed to unpack Hamilton packet."

$submitOutput = & ssh $RemoteAlias "cd '$remoteRunDir/hpc' && sbatch --nice=10000 annual_political_ladder_array.slurm"
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
    t_values = @(20, 40)
    vote_scales = @(0.015, 0.020, 0.030)
    candidates_by_vote_scale = [ordered]@{
        "0.015" = @("rho=0 phi=0.10 gamma=0.50", "rho=0 phi=0.03 gamma=1.50", "rho=0 phi=0.06 gamma=1.00")
        "0.020" = @("rho=0 phi=0.06 gamma=1.00", "rho=0 phi=0.10 gamma=0.50", "rho=0 phi=0.15 gamma=0.50")
        "0.030" = @("rho=0 phi=0.06 gamma=1.50", "rho=0 phi=0.10 gamma=1.00", "rho=0 phi=0.15 gamma=0.50")
    }
}

$resolvedStatePath = if ([string]::IsNullOrWhiteSpace($StatePath)) {
    Join-Path (Join-Path $truthDir "annual_political_hamilton") "annual_political_hamilton_ladder_latest.json"
} else {
    $StatePath
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $resolvedStatePath) | Out-Null
$state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resolvedStatePath

[pscustomobject]@{
    JobId = $jobId
    StageName = $stageName
    RemoteRunDir = $remoteRunDir
    StatePath = $resolvedStatePath
} | Format-List
