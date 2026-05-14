param(
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$extensionDir = Split-Path -Parent $scriptDir
$truthDir = Join-Path $scriptDir 'truth'
$auditDir = Join-Path $truthDir 'political_bellman_one_iteration_audit'
$statusPath = Join-Path $auditDir 'status.txt'
$summaryPath = Join-Path $auditDir 'summary.md'
$manifestPath = Join-Path $auditDir 'manifest.csv'
$matlabRunner = Join-Path $extensionDir 'run_transition_political_bellman_bounded.ps1'
$compiledRunner = Join-Path $scriptDir 'run_political_bellman_cli.ps1'
$validator = Join-Path $scriptDir 'validate_political_bellman.ps1'

New-Item -ItemType Directory -Path $auditDir -Force | Out-Null
Set-Content -LiteralPath $statusPath -Value ''

function Write-Status {
    param([string]$Message)
    Add-Content -LiteralPath $statusPath -Value ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
}

function Export-NoPoliticsPrefixCsv {
    param(
        [int]$Horizon,
        [string]$OutputPath
    )

    $matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
    $sourceMat = Join-Path $extensionDir 'transition_re_no_politics_results.mat'
    if (-not (Test-Path -LiteralPath $sourceMat)) {
        throw "No-politics results MAT file not found: $sourceMat"
    }

    $matlabSource = $sourceMat.Replace('\', '/').Replace("'", "''")
    $matlabOutput = $OutputPath.Replace('\', '/').Replace("'", "''")
    $batch = "load('$matlabSource'); writematrix(results.final_price_path(1:$Horizon), '$matlabOutput');"
    & $matlab -batch $batch
    if ($LASTEXITCODE -ne 0) {
        throw "MATLAB export failed with exit code $LASTEXITCODE."
    }
}

function Read-SingleColumnCsv {
    param([string]$Path)
    return @(Get-Content -LiteralPath $Path | Where-Object { $_ -ne '' } | ForEach-Object { [double]$_ })
}

function Compare-Vector {
    param(
        [string]$LeftPath,
        [string]$RightPath
    )

    $left = Read-SingleColumnCsv -Path $LeftPath
    $right = Read-SingleColumnCsv -Path $RightPath

    if ($left.Count -ne $right.Count) {
        throw "Vector length mismatch: $LeftPath ($($left.Count)) vs $RightPath ($($right.Count))"
    }

    $maxDiff = 0.0
    for ($i = 0; $i -lt $left.Count; $i++) {
        $maxDiff = [math]::Max($maxDiff, [math]::Abs($left[$i] - $right[$i]))
    }
    return $maxDiff
}

function Get-LastRow {
    param([string]$Path)
    $rows = @(Import-Csv -LiteralPath $Path)
    if ($rows.Count -eq 0) {
        throw "CSV has no rows: $Path"
    }
    return $rows[-1]
}

if (-not $SkipBuild) {
    Write-Status 'RUN build.ps1'
    & (Join-Path $scriptDir 'build.ps1')
    if ($LASTEXITCODE -ne 0) {
        throw "build.ps1 failed with exit code $LASTEXITCODE"
    }
    Write-Status 'DONE build.ps1'
}

$cases = @(
    [pscustomobject]@{
        horizon = 4
        pack_name = 'transition_pass_t4_political_diag'
        update_rule = 'fixed_step'
        matlab_run_tag = 'audit_t4_i1_fixed_step'
        prefix_csv = Join-Path $auditDir 'no_politics_prefix_t4.csv'
        compiled_output_dir = Join-Path $auditDir 'sidecar_t4_i1_fixed_step'
    },
    [pscustomobject]@{
        horizon = 9
        pack_name = 'transition_pass_t9_political_diag'
        update_rule = 'fixed_step'
        matlab_run_tag = 'audit_t9_i1_fixed_step'
        prefix_csv = Join-Path $auditDir 'no_politics_prefix_t9.csv'
        compiled_output_dir = Join-Path $auditDir 'sidecar_t9_i1_fixed_step'
    }
)

$manifest = New-Object System.Collections.Generic.List[object]

foreach ($case in $cases) {
    Write-Status ("CASE horizon={0} rule={1}" -f $case.horizon, $case.update_rule)
    Export-NoPoliticsPrefixCsv -Horizon $case.horizon -OutputPath $case.prefix_csv

    & $matlabRunner `
        -MaxK $case.horizon `
        -MaxIter 1 `
        -PriceUpdateMode 'political_only' `
        -PoliticalTarget 'equal_weight_vote' `
        -PoliticalUpdateWeight 0.005 `
        -PoliticalUpdateRule $case.update_rule `
        -RunTag $case.matlab_run_tag
    if ($LASTEXITCODE -ne 0) {
        throw "MATLAB bounded political runner failed for horizon $($case.horizon)"
    }

    & $compiledRunner `
        -PackName $case.pack_name `
        -OutputDir $case.compiled_output_dir `
        -InitialPricePathCsv $case.prefix_csv `
        -MaxIter 1 `
        -PoliticalUpdateRule $case.update_rule `
        -PoliticalUpdateWeight 0.005 `
        -SkipBuild
    if ($LASTEXITCODE -ne 0) {
        throw "Compiled political runner failed for horizon $($case.horizon)"
    }

    $matlabSummaryPath = Join-Path $extensionDir ("transition_political_bellman_{0}_summary.csv" -f $case.matlab_run_tag)
    $matlabFinalPricePath = Join-Path $extensionDir ("transition_political_bellman_{0}_final_price_path.csv" -f $case.matlab_run_tag)
    $matlabFinalVotePath = Join-Path $extensionDir ("transition_political_bellman_{0}_final_vote_path.csv" -f $case.matlab_run_tag)
    $matlabFinalAnchorPath = Join-Path $extensionDir ("transition_political_bellman_{0}_final_anchor_path.csv" -f $case.matlab_run_tag)

    $sidecarSummaryPath = Join-Path $case.compiled_output_dir 'sidecar_summary.csv'
    $sidecarFinalPricePath = Join-Path $case.compiled_output_dir 'sidecar_final_price_path.csv'
    $sidecarFinalVotePath = Join-Path $case.compiled_output_dir 'sidecar_final_vote_path.csv'
    $sidecarFinalAnchorPath = Join-Path $case.compiled_output_dir 'sidecar_final_anchor_path.csv'

    $summaryOutput = & $validator -TruthSummaryPath $matlabSummaryPath -SidecarSummaryPath $sidecarSummaryPath 2>&1
    $summaryMaxAbsDiff = [double](($summaryOutput | Where-Object { $_ -like 'max_abs_diff=*' }) -replace 'max_abs_diff=', '')

    $pricePathMaxAbsDiff = Compare-Vector -LeftPath $matlabFinalPricePath -RightPath $sidecarFinalPricePath
    $votePathMaxAbsDiff = Compare-Vector -LeftPath $matlabFinalVotePath -RightPath $sidecarFinalVotePath
    $anchorPathMaxAbsDiff = Compare-Vector -LeftPath $matlabFinalAnchorPath -RightPath $sidecarFinalAnchorPath

    $matlabLast = Get-LastRow -Path $matlabSummaryPath
    $sidecarLast = Get-LastRow -Path $sidecarSummaryPath

    $manifest.Add([pscustomobject]@{
        horizon = $case.horizon
        update_rule = $case.update_rule
        matlab_run_tag = $case.matlab_run_tag
        summary_max_abs_diff = $summaryMaxAbsDiff
        matlab_max_abs_vote = [double]$matlabLast.max_abs_vote
        sidecar_max_abs_vote = [double]$sidecarLast.max_abs_vote
        matlab_max_abs_gap = [double]$matlabLast.max_abs_gap
        sidecar_max_abs_gap = [double]$sidecarLast.max_abs_gap
        matlab_residual_norm = [double]$matlabLast.residual_norm
        sidecar_residual_norm = [double]$sidecarLast.residual_norm
        final_price_path_max_abs_diff = $pricePathMaxAbsDiff
        final_vote_path_max_abs_diff = $votePathMaxAbsDiff
        final_anchor_path_max_abs_diff = $anchorPathMaxAbsDiff
    }) | Out-Null

    Write-Status ("RESULT horizon={0} summary_diff={1} vote_path_diff={2} price_path_diff={3}" -f `
        $case.horizon, $summaryMaxAbsDiff, $votePathMaxAbsDiff, $pricePathMaxAbsDiff)
}

$manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Political Bellman one-iteration audit')
$lines.Add('')
$lines.Add('- Object: compare one outer political iteration between MATLAB and the compiled sidecar on the same no-politics prefix path.')
$lines.Add('- Update mode: `political_only`')
$lines.Add('- Political target: `equal_weight_vote`')
$lines.Add('- Iterations: `1`')
$lines.Add('- Weight: `0.005`')
$lines.Add('')
$lines.Add('| horizon | rule | summary max diff | vote path max diff | price path max diff | anchor path max diff | matlab vote | sidecar vote |')
$lines.Add('|---:|---|---:|---:|---:|---:|---:|---:|')
foreach ($row in $manifest) {
    $lines.Add(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |' -f `
        $row.horizon, `
        $row.update_rule, `
        $row.summary_max_abs_diff, `
        $row.final_vote_path_max_abs_diff, `
        $row.final_price_path_max_abs_diff, `
        $row.final_anchor_path_max_abs_diff, `
        $row.matlab_max_abs_vote, `
        $row.sidecar_max_abs_vote))
}
$lines.Add('')
$lines.Add(('- Manifest: `{0}`' -f $manifestPath))
$lines.Add(('- Status log: `{0}`' -f $statusPath))
[System.IO.File]::WriteAllLines($summaryPath, $lines)

Write-Status 'DONE audit'
Write-Host "One-iteration audit finished. Summary: $summaryPath"
