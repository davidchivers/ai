param(
    [string]$RunPrefix = "",
    [int]$T = 12,
    [int]$TailYears = 20,
    [int]$OuterIter = 6,
    [double]$PathRelaxation = 0.08,
    [double]$Eta = 0.090,
    [int]$ReferenceYear = 2020,
    [int]$TerminalIter = 10,
    [double]$TerminalRelaxation = 0.20,
    [string]$Candidates = "smooth:0.030,smooth:0.040,softnorm:0.030,logit:0.030",
    [string]$WarmStartRunTag = "",
    [switch]$WaitForIdle,
    [int]$MaxWaitHours = 10
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe"
if (-not (Test-Path $matlab)) {
    throw "MATLAB not found at $matlab"
}

if ([string]::IsNullOrWhiteSpace($RunPrefix)) {
    $RunPrefix = "smooth_func_smoke_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$fullReRoot = Join-Path $scriptRoot "truth\annual_political_full_re_price_path"
$smokeRoot = Join-Path $scriptRoot "truth\annual_full_re_smoothing_function_smoke"
$runRoot = Join-Path $smokeRoot $RunPrefix
$logRoot = Join-Path $runRoot "logs"
$initRoot = Join-Path $runRoot "initial_paths"
$statusPath = Join-Path $smokeRoot "latest_status.json"
$reportPath = Join-Path $runRoot "latest_report.md"
$summaryPath = Join-Path $runRoot "smoothing_smoke_summary.csv"
$stopPath = Join-Path $smokeRoot "STOP.flag"
New-Item -ItemType Directory -Force -Path $runRoot, $logRoot, $initRoot | Out-Null

function Write-SmokeStatus {
    param([string]$State, [string]$Message, [string]$Current = "")
    [pscustomobject]@{
        state = $State
        message = $Message
        current = $Current
        run_prefix = $RunPrefix
        updated_at = (Get-Date).ToString("s")
        report = $reportPath
        stop_file = $stopPath
    } | ConvertTo-Json | Set-Content -Path $statusPath -Encoding ASCII
}

function Write-Report {
    param([string]$Heading, [object[]]$Rows, [string]$Extra = "")
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Smoothing function smoke")
    $lines.Add("")
    $lines.Add("- Run prefix: ``$RunPrefix``")
    $lines.Add("- Scenario: ``forecast_median``")
    $lines.Add("- Reference year: ``$ReferenceYear``")
    $lines.Add("- T: ``$T``")
    $lines.Add("- Tail years: ``$TailYears``")
    $lines.Add("- Outer iterations: ``$OuterIter``")
    $lines.Add("- Path relaxation: ``$PathRelaxation``")
    $lines.Add("- Updated: " + (Get-Date).ToString("s"))
    $lines.Add("")
    $lines.Add("## Status")
    $lines.Add("")
    $lines.Add($Heading)
    $lines.Add("")
    $lines.Add("## Results")
    $lines.Add("")
    $lines.Add("| mode | vote scale | iter | path gap | vote resid | max price move | verdict |")
    $lines.Add("|---|---:|---:|---:|---:|---:|---|")
    foreach ($row in $Rows) {
        $lines.Add(("| {0} | {1:N3} | {2} | {3:N6} | {4:N6} | {5:N6} | {6} |" -f `
            $row.pressure_mode, $row.vote_scale, $row.outer_iter, $row.max_abs_path_gap, `
            $row.max_abs_vote_resid, $row.max_abs_log_price_move, $row.verdict))
    }
    if (-not [string]::IsNullOrWhiteSpace($Extra)) {
        $lines.Add("")
        $lines.Add("## Notes")
        $lines.Add("")
        $lines.Add($Extra)
    }
    $lines | Set-Content -Path $reportPath -Encoding ASCII
}

function Escape-MatlabString {
    param([string]$Value)
    return $Value.Replace("\", "/").Replace("'", "''")
}

function Wait-ForMatlabIdle {
    if (-not $WaitForIdle) {
        return
    }
    $deadline = (Get-Date).AddHours($MaxWaitHours)
    while ((Get-Date) -lt $deadline) {
        if (Test-Path $stopPath) {
            throw "Stop file exists: $stopPath"
        }
        $matlabProcesses = @(Get-Process | Where-Object { $_.ProcessName -like "*MATLAB*" })
        if ($matlabProcesses.Count -eq 0) {
            return
        }
        Write-SmokeStatus -State "waiting" -Message "Waiting for existing MATLAB run to finish." -Current ($matlabProcesses.Id -join ",")
        Write-Report -Heading "Waiting for existing MATLAB run to finish before starting smoke." -Rows @() -Extra ("Active MATLAB PIDs: ``{0}``" -f ($matlabProcesses.Id -join ", "))
        Start-Sleep -Seconds 60
    }
    throw "Timed out waiting for MATLAB to become idle."
}

function Find-WarmStartRunTag {
    if (-not [string]::IsNullOrWhiteSpace($WarmStartRunTag)) {
        return $WarmStartRunTag
    }

    $candidates = @(Get-ChildItem -Path $fullReRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*_T8" } |
        Sort-Object LastWriteTime -Descending)

    foreach ($dir in $candidates) {
        $summary = Join-Path $dir.FullName "summary_all.csv"
        $paths = Join-Path $dir.FullName "paths_all.csv"
        if (-not (Test-Path $summary) -or -not (Test-Path $paths)) {
            continue
        }
        $rows = @(Import-Csv $summary)
        if ($rows.Count -eq 0) {
            continue
        }
        $last = $rows[-1]
        if ($last.demographic_scenario -eq "forecast_median" -and $last.verdict -ne "dead") {
            return $dir.Name
        }
    }
    return ""
}

function New-WarmStartCsv {
    param([string]$RunTag)
    if ([string]::IsNullOrWhiteSpace($RunTag)) {
        return ""
    }

    $pathsFile = Join-Path (Join-Path $fullReRoot $RunTag) "paths_all.csv"
    if (-not (Test-Path $pathsFile)) {
        return ""
    }

    $paths = @(Import-Csv $pathsFile)
    if ($paths.Count -eq 0) {
        return ""
    }

    $lastIter = ($paths | ForEach-Object { [int]$_.outer_iter } | Measure-Object -Maximum).Maximum
    $selected = @($paths | Where-Object { [int]$_.outer_iter -eq $lastIter } | Sort-Object {[int]$_.period})
    if ($selected.Count -eq 0) {
        return ""
    }

    $out = Join-Path $initRoot ("warm_start_from_{0}.csv" -f $RunTag)
    $selected | ForEach-Object {
        [pscustomobject]@{ price = [double]$_.price_generated }
    } | Export-Csv -Path $out -NoTypeInformation -Encoding ASCII
    return $out
}

$rows = New-Object System.Collections.Generic.List[object]

try {
    Write-SmokeStatus -State "starting" -Message "Preparing smoothing function smoke."
    Write-Report -Heading "Preparing smoothing function smoke." -Rows @()
    Wait-ForMatlabIdle

    $chosenWarmStart = Find-WarmStartRunTag
    $warmStartCsv = New-WarmStartCsv -RunTag $chosenWarmStart
    $warmStartArg = ""
    if (-not [string]::IsNullOrWhiteSpace($warmStartCsv)) {
        $warmStartArg = ",'InitialPathCsv','$(Escape-MatlabString $warmStartCsv)'"
    }

    foreach ($candidate in ($Candidates -split ",")) {
        if (Test-Path $stopPath) {
            Write-SmokeStatus -State "stopped" -Message "Stop file found before next candidate."
            break
        }

        $parts = $candidate.Trim() -split ":"
        if ($parts.Count -ne 2) {
            throw "Candidate must be mode:vote_scale, got $candidate"
        }
        $mode = $parts[0].Trim()
        $voteScale = [double]$parts[1].Trim()
        $scaleTag = ("{0:F3}" -f $voteScale).Replace(".", "")
        $runTag = "{0}_T{1}_{2}_vs{3}" -f $RunPrefix, $T, $mode, $scaleTag
        $logPath = Join-Path $logRoot ("{0}.log" -f $runTag)

        Write-SmokeStatus -State "running" -Message ("Running {0}, vote scale {1}." -f $mode, $voteScale) -Current $runTag
        Write-Report -Heading ("Running ``{0}`` with vote scale ``{1}``." -f $mode, $voteScale) -Rows $rows -Extra ("Warm start: ``{0}``" -f $chosenWarmStart)

        $cmd = "cd('$(Escape-MatlabString $scriptRoot)'); run_annual_political_full_re_price_path('RunTag','$runTag','T',$T,'TailYears',$TailYears,'OuterIter',$OuterIter,'PathRelaxation',$PathRelaxation,'Eta',$Eta,'VoteScale',$voteScale,'PressureMode','$mode','DemographicScenario','forecast_median','ReferenceYear',$ReferenceYear,'TerminalAnchor','terminal_fixed_point','TerminalIter',$TerminalIter,'TerminalRelaxation',$TerminalRelaxation$warmStartArg)"
        & $matlab -singleCompThread -batch $cmd *> $logPath
        if ($LASTEXITCODE -ne 0) {
            throw "MATLAB failed for $runTag with exit code $LASTEXITCODE. See $logPath"
        }

        $summaryFile = Join-Path (Join-Path $fullReRoot $runTag) "summary_all.csv"
        if (-not (Test-Path $summaryFile)) {
            throw "Missing summary for $runTag"
        }
        $summaryRows = @(Import-Csv $summaryFile)
        $last = $summaryRows[-1]
        $row = [pscustomobject]@{
            run_tag = $runTag
            pressure_mode = $mode
            vote_scale = $voteScale
            outer_iter = [int]$last.outer_iter
            max_abs_path_gap = [double]$last.max_abs_path_gap
            max_abs_vote_resid = [double]$last.max_abs_vote_resid
            max_abs_log_price_move = [double]$last.max_abs_log_price_move
            verdict = [string]$last.verdict
            message = [string]$last.message
            warm_start = $chosenWarmStart
            log = $logPath
            summary = $summaryFile
        }
        $rows.Add($row)
        $rows | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding ASCII
        Write-Report -Heading ("Completed ``{0}`` with verdict ``{1}``." -f $mode, $row.verdict) -Rows $rows -Extra ("Warm start: ``{0}``" -f $chosenWarmStart)
    }

    Write-SmokeStatus -State "complete" -Message "Smoothing function smoke complete."
    Write-Report -Heading "Smoothing function smoke complete." -Rows $rows -Extra ("Warm start: ``{0}``" -f $chosenWarmStart)
}
catch {
    Write-SmokeStatus -State "failed" -Message $_.Exception.Message
    Write-Report -Heading "Smoothing function smoke failed." -Rows $rows -Extra $_.Exception.Message
    throw
}
