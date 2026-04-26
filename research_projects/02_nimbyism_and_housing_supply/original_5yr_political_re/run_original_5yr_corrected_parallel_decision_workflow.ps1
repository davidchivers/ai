param(
    [string]$RunTag = "local_corrected_s020_flat_k4_10_i1"
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param(
        [string]$State,
        [string]$Message,
        [hashtable]$Extra = @{}
    )
    $payload = [ordered]@{
        state = $State
        message = $Message
        run_tag = $RunTag
        updated_at = (Get-Date).ToString("o")
    }
    foreach ($key in $Extra.Keys) {
        $payload[$key] = $Extra[$key]
    }
    $payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $script:StatusPath -Encoding UTF8
}

$ThisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ThisDir
$LiveRoot = Join-Path $ThisDir "truth\corrected_parallel_decision_live"
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$script:StatusPath = Join-Path $LiveRoot "latest_status.json"
$MatlabLog = Join-Path $LiveRoot "$RunTag`_matlab.log"
$BatchPath = Join-Path $LiveRoot "$RunTag`_batch.m"

$MatlabCmd = (Get-Command matlab -ErrorAction Stop).Source

Write-Status -State "running" -Message "Starting corrected-weight smoothed k=[4,6,8,10] ladder." -Extra @{
    matlab_log = $MatlabLog
    batch_path = $BatchPath
}

$ProjectRootMatlab = $ProjectRoot.Replace("\", "\\")
$RunTagMatlab = $RunTag.Replace("'", "''")

$batch = @"
try
    cd('$ProjectRootMatlab');
    addpath('original_5yr_political_re');
    seed_price = fullfile('original_5yr_political_re', 'truth', 'seeds', 'flat_s020_k02_price.csv');
    seed_wedge = fullfile('original_5yr_political_re', 'truth', 'seeds', 'flat_s020_k02_wedge.csv');
    [summary, results] = run_original_5yr_transition_joint_supply_wedge_continuation( ...
        10, 1, 4, seed_price, '$RunTagMatlab', 'entrant_survival_flat', ...
        1e-2, 1e-3, [1.0; 0.5; 0.25], 0.08, 0.65, ...
        -0.50, 0.50, [4; 6; 8; 10], 4, ...
        'smooth_tanh', 0.20, seed_wedge, 0, 'stage_init_only', 0);
    disp(summary);
catch err
    disp(getReport(err, 'extended', 'hyperlinks', 'off'));
    exit(1);
end
exit(0);
"@
$batch | Set-Content -LiteralPath $BatchPath -Encoding ASCII

try {
    & $MatlabCmd -batch "run('$($BatchPath.Replace('\', '\\'))')" *> $MatlabLog
    $exitCode = $LASTEXITCODE
} catch {
    $exitCode = 1
    $_ | Out-String | Add-Content -LiteralPath $MatlabLog
}

$SummaryPath = Join-Path $ThisDir "truth\joint_supply_wedge\$RunTag\$RunTag`_summary.csv"
if ($exitCode -eq 0 -and (Test-Path -LiteralPath $SummaryPath)) {
    Copy-Item -LiteralPath $SummaryPath -Destination (Join-Path $LiveRoot "latest_summary.csv") -Force
    Write-Status -State "completed" -Message "Corrected-weight smoothed ladder completed." -Extra @{
        matlab_log = $MatlabLog
        summary_csv = $SummaryPath
        latest_summary_csv = (Join-Path $LiveRoot "latest_summary.csv")
    }
} else {
    Write-Status -State "failed" -Message "Corrected-weight smoothed ladder failed or did not write summary." -Extra @{
        matlab_log = $MatlabLog
        summary_csv = $SummaryPath
        exit_code = $exitCode
    }
    exit 1
}
