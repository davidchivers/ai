param(
    [ValidateSet('0.15','0.20')]
    [string]$Alpha = '0.15',
    [string]$OutputDir,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'tools\portable_toolchain.ps1')

$null = Set-NimbySidecarPortableToolchain

$extensionDir = Split-Path $scriptDir -Parent
$alphaNumber = [double]$Alpha
$alphaTag = $Alpha.Replace('.', '_')

switch ($Alpha) {
    '0.15' {
        $referenceSummaryPath = Join-Path $extensionDir 'transition_re_policy_bridge_alpha_0_15_k4_restart_checks.csv'
        $alphaResultsPath = Join-Path $extensionDir 'transition_re_policy_bridge_alpha_frontier_single_0_15_k6_results.mat'
    }
    '0.20' {
        $referenceSummaryPath = Join-Path $extensionDir 'transition_re_policy_bridge_alpha_0_20_k4_restart_checks.csv'
        $alphaResultsPath = Join-Path $extensionDir 'transition_re_policy_bridge_alpha_frontier_single_0_20_k6_results.mat'
    }
    default {
        throw "Unsupported alpha: $Alpha"
    }
}

$referenceK6Path = Join-Path $extensionDir 'transition_re_policy_bridge_alpha_frontier_single_0_14_k6_results.mat'

foreach ($requiredPath in @($referenceSummaryPath, $alphaResultsPath, $referenceK6Path)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required restart-check source file not found: $requiredPath"
    }
}

if (-not $OutputDir) {
    $OutputDir = Join-Path $scriptDir ("truth\transition_re_policy_bridge_k4_restart_checks_sidecar_alpha_{0}" -f $alphaTag)
}

if (-not $SkipBuild) {
    & (Join-Path $scriptDir 'build.ps1')
}

$exe = Join-Path $scriptDir 'build\nimby_transition_re_case_sweep_cli.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "Transition-RE case-sweep CLI executable not found: $exe"
}

function Get-RestartCheckCasePayload {
    param(
        [string]$AlphaResultsPath,
        [string]$ReferenceK6Path,
        [string]$AlphaTag
    )

    $pythonScript = @'
import json
import sys
from pathlib import Path

import scipy.io as sio


def as_list(value):
    squeezed = value.squeeze()
    if hasattr(squeezed, "tolist"):
        squeezed = squeezed.tolist()
    if isinstance(squeezed, (float, int)):
        return [float(squeezed)]
    return [float(v) for v in squeezed]


alpha_results = Path(sys.argv[1])
reference_k6 = Path(sys.argv[2])
alpha_tag = sys.argv[3]

alpha_state = sio.loadmat(alpha_results, squeeze_me=True, struct_as_record=False)["state"]
reference_state = sio.loadmat(reference_k6, squeeze_me=True, struct_as_record=False)["state"]

anchor = as_list(alpha_state.anchor_price_path)
k3_final = as_list(alpha_state.all_results[2].final_price_path)
k4_final = as_list(alpha_state.all_results[3].final_price_path)
k6_final = as_list(reference_state.all_results[5].final_price_path)

payload = {
    "cases": [
        {
            "case_name": "default_same_alpha_k3_iter50",
            "guess_source": f"alpha_{alpha_tag}_k3_extended_with_anchor_period_4",
            "max_iter": 50,
            "guess": k3_final[:3] + [anchor[3]],
        },
        {
            "case_name": f"restart_from_failed_alpha_{alpha_tag}_k4",
            "guess_source": f"alpha_{alpha_tag}_k4_final_price_path",
            "max_iter": 25,
            "guess": k4_final[:4],
        },
        {
            "case_name": "restart_from_alpha_0_14_k6_prefix",
            "guess_source": "alpha_0_14_k6_final_price_path_prefix",
            "max_iter": 25,
            "guess": k6_final[:4],
        },
    ]
}

print(json.dumps(payload))
'@

    $tempPath = [System.IO.Path]::GetTempFileName()
    try {
        $pyPath = [System.IO.Path]::ChangeExtension($tempPath, '.py')
        Move-Item -LiteralPath $tempPath -Destination $pyPath
        Set-Content -LiteralPath $pyPath -Value $pythonScript -Encoding UTF8
        $json = & python $pyPath $AlphaResultsPath $ReferenceK6Path $AlphaTag
        if ($LASTEXITCODE -ne 0) {
            throw "Python helper failed while extracting restart-check case payload."
        }
        return ($json | ConvertFrom-Json)
    } finally {
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Force
        }
        $pyPath = [System.IO.Path]::ChangeExtension($tempPath, '.py')
        if (Test-Path -LiteralPath $pyPath) {
            Remove-Item -LiteralPath $pyPath -Force
        }
    }
}

if (Test-Path -LiteralPath $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

$guessDir = Join-Path $OutputDir 'guess_paths'
New-Item -ItemType Directory -Path $guessDir | Out-Null

$payload = Get-RestartCheckCasePayload -AlphaResultsPath $alphaResultsPath -ReferenceK6Path $referenceK6Path -AlphaTag $alphaTag
$caseSpecs = @()

foreach ($case in $payload.cases) {
    $safeCaseName = ($case.case_name -replace '[^A-Za-z0-9_-]', '_')
    $guessPath = Join-Path $guessDir ("{0}.csv" -f $safeCaseName)
    $case.guess | ForEach-Object {
        ([double]$_).ToString('R', [System.Globalization.CultureInfo]::InvariantCulture)
    } | Set-Content -LiteralPath $guessPath

    $packName = "transition_re_k4_restart_checks_alpha_{0}_{1}_input_only" -f $alphaTag, $safeCaseName
    $packDir = Join-Path $scriptDir ("truth\{0}" -f $packName)

    if (Test-Path -LiteralPath $packDir) {
        Remove-Item -Recurse -Force $packDir
    }
    & (Join-Path $scriptDir 'export_transition_re_input_only.ps1') `
        -PackName $packName `
        -Horizon 4 `
        -PriceLevel 2.0 `
        -TransitionPolicyMode 'steady_state_by_period_price' `
        -PolicyReferencePrice 2.0 `
        -TerminalReferenceMode 'fixed_price' `
        -TerminalReferencePrice 2.0 `
        -PolicyReferenceMode 'blended_current_and_fixed_price' `
        -PolicyReferenceBlendWeight $alphaNumber `
        -SolverProfile 'frontier_fertility_style' `
        -InitialPricePathCsv $guessPath

    $caseSpecs += [pscustomobject]@{
        case_name = [string]$case.case_name
        guess_source = [string]$case.guess_source
        input_dir = $packDir
        max_iter = [int]$case.max_iter
        start_price_1 = [double]$case.guess[0]
        start_price_2 = [double]$case.guess[1]
        start_price_3 = [double]$case.guess[2]
        start_price_4 = [double]$case.guess[3]
    }
}

$caseSpecPath = Join-Path $OutputDir 'case_specs.csv'
$caseSpecs | Export-Csv -NoTypeInformation -Path $caseSpecPath

$fallbackInputDir = [string]$caseSpecs[0].input_dir
& $exe $fallbackInputDir $caseSpecPath --output-dir $OutputDir
