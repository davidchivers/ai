param(
    [string]$OutputDir,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'tools\portable_toolchain.ps1')

$null = Set-NimbySidecarPortableToolchain
if (-not $OutputDir) {
    $OutputDir = Join-Path $scriptDir 'truth\transition_re_policy_bridge_k4_warm_start_sidecar_alpha_0_14'
}

$matlabSummaryPath = Join-Path (Split-Path $scriptDir -Parent) 'transition_re_policy_bridge_k4_warm_start_diagnostics_summary.csv'
if (-not (Test-Path $matlabSummaryPath)) {
    throw "MATLAB warm-start summary not found: $matlabSummaryPath"
}

if (-not $SkipBuild) {
    & (Join-Path $scriptDir 'build.ps1')
}

$exe = Join-Path $scriptDir 'build\nimby_transition_re_case_sweep_cli.exe'
if (-not (Test-Path $exe)) {
    throw "Transition-RE case-sweep CLI executable not found: $exe"
}

$caseSpecPath = Join-Path $OutputDir 'case_specs.csv'
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
$guessDir = Join-Path $OutputDir 'guess_paths'
New-Item -ItemType Directory -Path $guessDir | Out-Null

$sourceRows = @(
    Import-Csv $matlabSummaryPath |
    Select-Object case_name, guess_source, max_iter, start_price_1, start_price_2, start_price_3, start_price_4
)
if ($sourceRows.Count -eq 0) {
    throw "MATLAB warm-start summary has no rows: $matlabSummaryPath"
}

$caseRows = @(
foreach ($row in $sourceRows) {
    $safeCase = (($row.case_name -replace '[^A-Za-z0-9_-]', '_'))
    $guessPath = Join-Path $guessDir ("{0}.csv" -f $safeCase)
    @(
        [double]$row.start_price_1,
        [double]$row.start_price_2,
        [double]$row.start_price_3,
        [double]$row.start_price_4
    ) | ForEach-Object { $_.ToString('R', [System.Globalization.CultureInfo]::InvariantCulture) } | Set-Content -Path $guessPath

    $packName = "transition_re_k4_warm_start_alpha_0_14_{0}_input_only" -f $safeCase
    $packDir = Join-Path $scriptDir ("truth\{0}" -f $packName)
    if (-not (Test-Path $packDir)) {
        & (Join-Path $scriptDir 'export_transition_re_input_only.ps1') `
            -PackName $packName `
            -Horizon 4 `
            -PriceLevel 2.0 `
            -TransitionPolicyMode 'steady_state_by_period_price' `
            -PolicyReferencePrice 2.0 `
            -TerminalReferenceMode 'fixed_price' `
            -TerminalReferencePrice 2.0 `
            -PolicyReferenceMode 'blended_current_and_fixed_price' `
            -PolicyReferenceBlendWeight 0.14 `
            -SolverProfile 'frontier_fertility_style' `
            -InitialPricePathCsv $guessPath
    }

    [pscustomobject]@{
        case_name = $row.case_name
        guess_source = $row.guess_source
        input_dir = $packDir
        max_iter = $row.max_iter
        start_price_1 = $row.start_price_1
        start_price_2 = $row.start_price_2
        start_price_3 = $row.start_price_3
        start_price_4 = $row.start_price_4
    }
}
)

$caseRows | Export-Csv -NoTypeInformation -Path $caseSpecPath
$fallbackInputDir = [string]$caseRows[0].input_dir

& $exe $fallbackInputDir $caseSpecPath --output-dir $OutputDir
