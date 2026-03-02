param(
    [ValidateSet('baseline','ui_020','ui_010','ui_005','ui_000')]
    [string]$Scenario = 'baseline',
    [string]$UiOverride = '',
    [switch]$SkipTransition,
    [string]$FixedTheta = '',
    [string]$FixedRho = '',
    [string]$FixedR = '',
    [string]$FixedW = '',
    [string]$UpdateStep1 = '',
    [string]$MarketGapClamp = '',
    [switch]$AdaptiveGE,
    [string]$AdaptiveMinStep = '',
    [string]$AdaptiveMaxStep = '',
    [string]$AdaptiveTighten = '',
    [string]$AdaptiveRelax = '',
    [string]$AdaptiveImproveRatio = '',
    [string]$AdaptiveWorsenRatio = '',
    [string]$VacancyMode = '',
    [string]$VacancyFloor = '',
    [string]$VacancyScale = '',
    [int]$MaxIterAgg = -1,
    [int]$MaxTransitionIter = -1,
    [double]$TransitionTol = -1.0,
    [int]$RngSeed = -1,
    [int]$TimeoutSeconds = -1,
    [string]$RunTag = '',
    [string]$SourceFile = '',
    [string]$SingleCase = '51',
    [switch]$SkipCompile
)

$ErrorActionPreference = 'Stop'
# Keep native executable stderr warnings in logs without promoting them to terminating errors.
if ($null -ne (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue)) {
    $PSNativeCommandUseErrorActionPreference = $false
}
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runtime = Join-Path $root 'runtime'
$exe = Join-Path $root 'cfv_red_final_ai.exe'
$src = $null
$parentCalibration = Split-Path -Parent $root
$canonicalRoot = Join-Path $parentCalibration 'canonical_dropbox'
$canonicalMain = $null
if (Test-Path $canonicalRoot) {
    $canonicalMain = Get-ChildItem -Path $canonicalRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName 'main_2025_v1_case113.cpp' } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1
}

if (-not [string]::IsNullOrWhiteSpace($SourceFile)) {
    $sourceCandidate = $SourceFile
    if (-not [System.IO.Path]::IsPathRooted($sourceCandidate)) {
        $sourceCandidate = Join-Path $root $sourceCandidate
    }
    if (-not (Test-Path $sourceCandidate)) {
        Write-Error ("Source file not found: {0}" -f $sourceCandidate)
    }
    $src = (Resolve-Path $sourceCandidate).Path
} else {
    $srcCandidates = @(
        $canonicalMain,
        (Join-Path $root 'cfv_red_final.cpp'),
        (Join-Path $root 'cfv_red_final_coauthor.cpp'),
        (Join-Path $parentCalibration 'cfv_red_final.cpp')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($candidate in $srcCandidates) {
        if (Test-Path $candidate) {
            $src = $candidate
            break
        }
    }
}

function Set-OrClearEnv {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $false)][string]$Value
    )
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Remove-Item "Env:$Name" -ErrorAction SilentlyContinue
    } else {
        Set-Item "Env:$Name" -Value $Value
    }
}

function Sanitize-Tag {
    param([string]$Tag)
    if ([string]::IsNullOrWhiteSpace($Tag)) { return '' }
    return (($Tag -replace '[^a-zA-Z0-9_-]', '_').Trim('_'))
}

$required = @(
    'policy_functions_v17_in.txt',
    'rnd_100k.txt',
    'x_shk_iid.txt',
    'input_pi_x_iid_1.txt',
    'input_pi_x.txt'
)

$inputDir = Join-Path $runtime 'data/input/CFV'
$missing = @()
foreach ($name in $required) {
    if (-not (Test-Path (Join-Path $inputDir $name))) {
        $missing += $name
    }
}
if ($missing.Count -gt 0) {
    Write-Error ("Missing input files in {0}: {1}" -f $inputDir, ($missing -join ', '))
}

$compiler = $null
$compilerPath = $null
$needsCompile = (-not $SkipCompile) -or (-not (Test-Path $exe))
if ($needsCompile) {
    if (-not $src) {
        Write-Error 'No source file found. Expected canonical_dropbox/*/main_2025_v1_case113.cpp, cfv_red_final.cpp, cfv_red_final_coauthor.cpp, or ../cfv_red_final.cpp'
    }
    if (Get-Command g++ -ErrorAction SilentlyContinue) {
        $compiler = 'g++'
        $compilerPath = 'g++'
    } elseif (Test-Path 'C:/msys64/ucrt64/bin/g++.exe') {
        $compiler = 'g++'
        $compilerPath = 'C:/msys64/ucrt64/bin/g++.exe'
    } elseif (Get-Command clang++ -ErrorAction SilentlyContinue) {
        $compiler = 'clang++'
        $compilerPath = 'clang++'
    } elseif (Get-Command cl -ErrorAction SilentlyContinue) {
        $compiler = 'cl'
        $compilerPath = 'cl'
    }

    if (-not $compiler) {
        Write-Error 'No compiler found (g++, clang++, or cl). Install one and rerun.'
    }

    # Ensure compiler runtime DLLs are discoverable (required for MSYS2 g++).
    if ($compiler -eq 'g++' -and (Test-Path $compilerPath)) {
        $compilerBin = Split-Path -Parent $compilerPath
        if ($compilerBin -and -not (($env:Path -split ';') -contains $compilerBin)) {
            $env:Path = "$compilerBin;$env:Path"
        }
    }
}

# Ensure runtime DLLs are discoverable even when reusing an existing exe with -SkipCompile.
$msysBin = 'C:/msys64/ucrt64/bin'
if (Test-Path (Join-Path $msysBin 'g++.exe')) {
    if (-not (($env:Path -split ';') -contains $msysBin)) {
        $env:Path = "$msysBin;$env:Path"
    }
}

Push-Location $root
try {
    if (-not $SkipCompile -or -not (Test-Path $exe)) {
        $srcDir = Split-Path -Parent $src
        if ($compiler -eq 'g++') {
            & $compilerPath -O2 -std=gnu++14 "-I$root" "-I$srcDir" $src -o $exe
        } elseif ($compiler -eq 'clang++') {
            & $compilerPath -O2 -std=gnu++14 "-I$root" "-I$srcDir" $src -o $exe
        } else {
            & $compilerPath /EHsc /O2 "/I$root" "/I$srcDir" $src /Fe:$exe
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Error 'Compilation failed.'
        }
    }

    # Core runtime root.
    $env:CFV_WORKINGPATH = $runtime

    # Scenario -> UI mapping, unless explicit override is passed.
    if (-not [string]::IsNullOrWhiteSpace($UiOverride)) {
        Set-OrClearEnv -Name 'CFV_UI_REPLACEMENT' -Value $UiOverride
    } else {
        switch ($Scenario) {
            'baseline' { Set-OrClearEnv -Name 'CFV_UI_REPLACEMENT' -Value $null }
            'ui_020'   { Set-OrClearEnv -Name 'CFV_UI_REPLACEMENT' -Value '0.20' }
            'ui_010'   { Set-OrClearEnv -Name 'CFV_UI_REPLACEMENT' -Value '0.10' }
            'ui_005'   { Set-OrClearEnv -Name 'CFV_UI_REPLACEMENT' -Value '0.05' }
            'ui_000'   { Set-OrClearEnv -Name 'CFV_UI_REPLACEMENT' -Value '0.00' }
        }
    }

    if ($SkipTransition) {
        Set-OrClearEnv -Name 'CFV_SKIP_TRANSITION' -Value '1'
    } else {
        Set-OrClearEnv -Name 'CFV_SKIP_TRANSITION' -Value $null
    }
    Set-OrClearEnv -Name 'CFV_SINGLE_CASE' -Value $SingleCase

    Set-OrClearEnv -Name 'CFV_FIXED_THETA' -Value $FixedTheta
    Set-OrClearEnv -Name 'CFV_FIXED_RHO' -Value $FixedRho
    Set-OrClearEnv -Name 'CFV_FIXED_R' -Value $FixedR
    Set-OrClearEnv -Name 'CFV_FIXED_W' -Value $FixedW
    Set-OrClearEnv -Name 'CFV_UPDATE_STEP1' -Value $UpdateStep1
    Set-OrClearEnv -Name 'CFV_MARKET_GAP_CLAMP' -Value $MarketGapClamp
    if ($AdaptiveGE) {
        Set-OrClearEnv -Name 'CFV_ADAPTIVE_GE' -Value '1'
    } else {
        Set-OrClearEnv -Name 'CFV_ADAPTIVE_GE' -Value $null
    }
    Set-OrClearEnv -Name 'CFV_ADAPTIVE_MIN_STEP' -Value $AdaptiveMinStep
    Set-OrClearEnv -Name 'CFV_ADAPTIVE_MAX_STEP' -Value $AdaptiveMaxStep
    Set-OrClearEnv -Name 'CFV_ADAPTIVE_TIGHTEN' -Value $AdaptiveTighten
    Set-OrClearEnv -Name 'CFV_ADAPTIVE_RELAX' -Value $AdaptiveRelax
    Set-OrClearEnv -Name 'CFV_ADAPTIVE_IMPROVE_RATIO' -Value $AdaptiveImproveRatio
    Set-OrClearEnv -Name 'CFV_ADAPTIVE_WORSEN_RATIO' -Value $AdaptiveWorsenRatio
    Set-OrClearEnv -Name 'CFV_VACANCY_MODE' -Value $VacancyMode
    Set-OrClearEnv -Name 'CFV_VACANCY_FLOOR' -Value $VacancyFloor
    Set-OrClearEnv -Name 'CFV_VACANCY_SCALE' -Value $VacancyScale

    if ($MaxIterAgg -gt 0) {
        Set-OrClearEnv -Name 'CFV_MAX_ITER_AGG' -Value ([string]$MaxIterAgg)
    } else {
        Set-OrClearEnv -Name 'CFV_MAX_ITER_AGG' -Value $null
    }

    if ($MaxTransitionIter -gt 0) {
        Set-OrClearEnv -Name 'CFV_MAX_TRANSITION_ITER' -Value ([string]$MaxTransitionIter)
    } else {
        Set-OrClearEnv -Name 'CFV_MAX_TRANSITION_ITER' -Value $null
    }

    if ($TransitionTol -gt 0) {
        Set-OrClearEnv -Name 'CFV_TRANSITION_TOL' -Value ([string]$TransitionTol)
    } else {
        Set-OrClearEnv -Name 'CFV_TRANSITION_TOL' -Value $null
    }

    if ($RngSeed -ge 0) {
        Set-OrClearEnv -Name 'CFV_RNG_SEED' -Value ([string]$RngSeed)
    } else {
        Set-OrClearEnv -Name 'CFV_RNG_SEED' -Value $null
    }

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $tag = Sanitize-Tag -Tag $RunTag
    $logDir = Join-Path $runtime 'data/output/case_1'
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null

    if ([string]::IsNullOrWhiteSpace($tag)) {
        $logFile = Join-Path $logDir ("run_{0}_{1}.log" -f $Scenario, $stamp)
    } else {
        $logFile = Join-Path $logDir ("run_{0}_{1}_{2}.log" -f $Scenario, $tag, $stamp)
    }

    $meta = @(
        "[ABLT] scenario=$Scenario",
        "[ABLT] source_file=$src",
        "[ABLT] ui_override=$($env:CFV_UI_REPLACEMENT)",
        "[ABLT] skip_transition=$($env:CFV_SKIP_TRANSITION)",
        "[ABLT] single_case=$($env:CFV_SINGLE_CASE)",
        "[ABLT] fixed_theta=$($env:CFV_FIXED_THETA)",
        "[ABLT] fixed_rho=$($env:CFV_FIXED_RHO)",
        "[ABLT] fixed_r=$($env:CFV_FIXED_R)",
        "[ABLT] fixed_w=$($env:CFV_FIXED_W)",
        "[ABLT] update_step1=$($env:CFV_UPDATE_STEP1)",
        "[ABLT] market_gap_clamp=$($env:CFV_MARKET_GAP_CLAMP)",
        "[ABLT] adaptive_ge=$($env:CFV_ADAPTIVE_GE)",
        "[ABLT] adaptive_min_step=$($env:CFV_ADAPTIVE_MIN_STEP)",
        "[ABLT] adaptive_max_step=$($env:CFV_ADAPTIVE_MAX_STEP)",
        "[ABLT] adaptive_tighten=$($env:CFV_ADAPTIVE_TIGHTEN)",
        "[ABLT] adaptive_relax=$($env:CFV_ADAPTIVE_RELAX)",
        "[ABLT] adaptive_improve_ratio=$($env:CFV_ADAPTIVE_IMPROVE_RATIO)",
        "[ABLT] adaptive_worsen_ratio=$($env:CFV_ADAPTIVE_WORSEN_RATIO)",
        "[ABLT] vacancy_mode=$($env:CFV_VACANCY_MODE)",
        "[ABLT] vacancy_floor=$($env:CFV_VACANCY_FLOOR)",
        "[ABLT] vacancy_scale=$($env:CFV_VACANCY_SCALE)",
        "[ABLT] max_iter_agg=$($env:CFV_MAX_ITER_AGG)",
        "[ABLT] max_transition_iter=$($env:CFV_MAX_TRANSITION_ITER)",
        "[ABLT] transition_tol=$($env:CFV_TRANSITION_TOL)",
        "[ABLT] rng_seed=$($env:CFV_RNG_SEED)",
        "[ABLT] started_utc=$((Get-Date).ToUniversalTime().ToString('s'))Z"
    )
    Set-Content -Path $logFile -Value $meta

    $runExitCode = 0
    $timedOut = $false

    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath $exe -WorkingDirectory $root -NoNewWindow -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        if ($TimeoutSeconds -gt 0) {
            if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
                $timedOut = $true
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            } else {
                $null = $proc.WaitForExit()
            }
        } else {
            $null = $proc.WaitForExit()
        }

        if (-not $timedOut) {
            if ($null -eq $proc.ExitCode) {
                $runExitCode = 999
            } else {
                $runExitCode = [int]$proc.ExitCode
            }
        }

        Set-Content -Path $logFile -Value $meta
        if (Test-Path $outFile) {
            Add-Content -Path $logFile -Value (Get-Content -Path $outFile)
        }
        if (Test-Path $errFile) {
            Add-Content -Path $logFile -Value (Get-Content -Path $errFile)
        }
        if ($timedOut) {
            Add-Content -Path $logFile -Value ("[ABLT] timeout_seconds={0}" -f $TimeoutSeconds)
        }
        if ($runExitCode -eq 999) {
            Add-Content -Path $logFile -Value "[ABLT] warning=process_exit_code_missing"
        }
    } finally {
        Remove-Item $outFile -Force -ErrorAction SilentlyContinue
        Remove-Item $errFile -Force -ErrorAction SilentlyContinue
    }

    Add-Content -Path $logFile -Value ("[ABLT] finished_utc={0}Z" -f ((Get-Date).ToUniversalTime().ToString('s')))
    Add-Content -Path $logFile -Value ("[ABLT] exit_code={0}" -f $runExitCode)
    $timedOutInt = 0
    if ($timedOut) { $timedOutInt = 1 }
    Add-Content -Path $logFile -Value ("[ABLT] timed_out={0}" -f $timedOutInt)

    if ($timedOut) {
        Write-Error ("Run timed out after {0}s. Log: {1}" -f $TimeoutSeconds, $logFile)
    }
    if ($runExitCode -ne 0 -and $runExitCode -ne 999) {
        Write-Error ("Run failed with exit code {0}. Log: {1}" -f $runExitCode, $logFile)
    }
    if ($runExitCode -eq 999) {
        Write-Warning ("Run completed but process exit code was not available. Log: {0}" -f $logFile)
    }

    Write-Host "Run complete. Log: $logFile" -ForegroundColor Green
}
finally {
    Pop-Location
}
