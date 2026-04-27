param(
    [string]$Rungs = "4,8,12,20",
    [int]$OuterIter = 6,
    [double]$PathRelaxation = 0.08,
    [double]$Eta = 0.090,
    [double]$VoteScale = 0.020,
    [int]$ReferenceYear = 2020,
    [int]$ShortTailYears = 20,
    [int]$LongTailYears = 40,
    [int]$TerminalIter = 10,
    [double]$TerminalRelaxation = 0.20,
    [double]$StopPathGap = 0.060,
    [string]$RunPrefix = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe"
if (-not (Test-Path $matlab)) {
    throw "MATLAB not found at $matlab"
}

if ([string]::IsNullOrWhiteSpace($RunPrefix)) {
    $RunPrefix = "local_medproj_2020_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$outRoot = Join-Path $scriptRoot "truth\annual_political_full_re_price_path"
$ladderRoot = Join-Path $scriptRoot "truth\annual_full_re_median_projection_ladder"
$runRoot = Join-Path $ladderRoot $RunPrefix
$logRoot = Join-Path $runRoot "logs"
$initRoot = Join-Path $runRoot "initial_paths"
$lockPath = Join-Path $ladderRoot "local_median_projection_ladder.lock.json"
$reportPath = Join-Path $runRoot "latest_report.md"
$summaryPath = Join-Path $runRoot "ladder_summary.csv"
$statusPath = Join-Path $ladderRoot "latest_status.json"

New-Item -ItemType Directory -Force -Path $runRoot, $logRoot, $initRoot | Out-Null

if ((Test-Path $lockPath) -and (-not $Force)) {
    throw "Local median projection ladder lock exists at $lockPath. Use -Force only after confirming no ladder is running."
}

$lock = [ordered]@{
    pid = $PID
    run_prefix = $RunPrefix
    started_at = (Get-Date).ToString("s")
    report = $reportPath
}
$lock | ConvertTo-Json | Set-Content -Path $lockPath -Encoding ASCII

function Write-LadderStatus {
    param(
        [string]$State,
        [string]$Message,
        [Nullable[int]]$CurrentT = $null
    )
    $payload = [ordered]@{
        state = $State
        message = $Message
        current_T = $CurrentT
        run_prefix = $RunPrefix
        updated_at = (Get-Date).ToString("s")
        report = $reportPath
    }
    $payload | ConvertTo-Json | Set-Content -Path $statusPath -Encoding ASCII
}

function Write-Report {
    param(
        [string]$Heading,
        [System.Collections.IEnumerable]$Rows,
        [string]$Extra = ""
    )
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Local median projection ladder")
    $lines.Add("")
    $lines.Add("- Run prefix: ``$RunPrefix``")
    $lines.Add("- Scenario: ``forecast_median``")
    $lines.Add("- Reference year: ``$ReferenceYear``")
    $lines.Add("- Eta: ``$Eta``")
    $lines.Add("- Vote scale: ``$VoteScale``")
    $lines.Add("- Path relaxation: ``$PathRelaxation``")
    $lines.Add("- Outer iterations per rung: ``$OuterIter``")
    $lines.Add("- Updated: " + (Get-Date).ToString("s"))
    $lines.Add("")
    $lines.Add("## Status")
    $lines.Add("")
    $lines.Add($Heading)
    $lines.Add("")
    $lines.Add("## Results")
    $lines.Add("")
    $lines.Add("| T | tail | iter | path gap | vote resid | max price move | verdict |")
    $lines.Add("|---:|---:|---:|---:|---:|---:|---|")
    foreach ($row in $Rows) {
        $lines.Add(("| {0} | {1} | {2} | {3:N6} | {4:N6} | {5:N6} | {6} |" -f `
            $row.T, $row.tail_years, $row.outer_iter, $row.max_abs_path_gap, `
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

function New-InitialPathCsv {
    param(
        [string]$PreviousRunTag,
        [int]$T
    )
    if ([string]::IsNullOrWhiteSpace($PreviousRunTag)) {
        return ""
    }

    $previousPaths = Join-Path (Join-Path $outRoot $PreviousRunTag) "paths_all.csv"
    if (-not (Test-Path $previousPaths)) {
        return ""
    }

    $paths = Import-Csv -Path $previousPaths
    if ($paths.Count -eq 0) {
        return ""
    }

    $lastIter = ($paths | ForEach-Object { [int]$_.outer_iter } | Measure-Object -Maximum).Maximum
    $selected = $paths | Where-Object { [int]$_.outer_iter -eq $lastIter } | Sort-Object {[int]$_.period}
    if ($selected.Count -eq 0) {
        return ""
    }

    $initPath = Join-Path $initRoot ("initial_T{0}.csv" -f $T)
    $selected | ForEach-Object {
        [pscustomobject]@{ price = [double]$_.price_generated }
    } | Export-Csv -Path $initPath -NoTypeInformation -Encoding ASCII
    return $initPath
}

$rows = New-Object System.Collections.Generic.List[object]
$rungValues = $Rungs -split "," | ForEach-Object { [int]$_.Trim() } | Where-Object { $_ -gt 0 }
$previousRunTag = ""

try {
    Write-LadderStatus -State "running" -Message "Starting local median projection ladder." -CurrentT $null
    Write-Report -Heading "Running." -Rows $rows

    foreach ($T in $rungValues) {
        $tailYears = if ($T -le 12) { $ShortTailYears } else { $LongTailYears }
        $runTag = "{0}_T{1}" -f $RunPrefix, $T
        $logPath = Join-Path $logRoot ("T{0}.log" -f $T)
        $initPath = New-InitialPathCsv -PreviousRunTag $previousRunTag -T $T
        $initialArg = ""
        if (-not [string]::IsNullOrWhiteSpace($initPath)) {
            $initialArg = ",'InitialPathCsv','$(Escape-MatlabString $initPath)'"
        }

        Write-LadderStatus -State "running" -Message ("Running T={0}." -f $T) -CurrentT $T
        Write-Report -Heading ("Running T={0}." -f $T) -Rows $rows -Extra ("Current log: ``{0}``" -f $logPath)

        $cmd = "cd('$(Escape-MatlabString $scriptRoot)'); run_annual_political_full_re_price_path('RunTag','$runTag','T',$T,'TailYears',$tailYears,'OuterIter',$OuterIter,'PathRelaxation',$PathRelaxation,'Eta',$Eta,'VoteScale',$VoteScale,'DemographicScenario','forecast_median','ReferenceYear',$ReferenceYear,'TerminalAnchor','terminal_fixed_point','TerminalIter',$TerminalIter,'TerminalRelaxation',$TerminalRelaxation$initialArg)"

        & $matlab -singleCompThread -batch $cmd *> $logPath
        if ($LASTEXITCODE -ne 0) {
            throw "MATLAB failed on T=$T with exit code $LASTEXITCODE. See $logPath"
        }

        $summaryFile = Join-Path (Join-Path $outRoot $runTag) "summary_all.csv"
        if (-not (Test-Path $summaryFile)) {
            throw "Missing summary after T=$T at $summaryFile"
        }

        $summaryRows = Import-Csv -Path $summaryFile
        $final = $summaryRows | Select-Object -Last 1
        $row = [pscustomobject]@{
            run_tag = $runTag
            T = $T
            tail_years = [int]$final.tail_years
            outer_iter = [int]$final.outer_iter
            eta = [double]$final.eta
            vote_scale = [double]$final.vote_scale
            max_abs_path_gap = [double]$final.max_abs_path_gap
            max_abs_vote_resid = [double]$final.max_abs_vote_resid
            max_abs_log_price_move = [double]$final.max_abs_log_price_move
            verdict = [string]$final.verdict
            message = [string]$final.message
            log = $logPath
            summary = $summaryFile
        }
        $rows.Add($row)
        $rows | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding ASCII
        $previousRunTag = $runTag

        $extra = "Latest run: ``$runTag``"
        Write-Report -Heading ("Completed T={0} with verdict ``{1}``." -f $T, $row.verdict) -Rows $rows -Extra $extra

        if (($row.verdict -eq "dead") -or ($row.max_abs_path_gap -gt $StopPathGap)) {
            Write-LadderStatus -State "stopped" -Message ("Stopped after T={0}: verdict={1}, path gap={2:N6}." -f $T, $row.verdict, $row.max_abs_path_gap) -CurrentT $T
            Write-Report -Heading ("Stopped after T={0}: verdict ``{1}``." -f $T, $row.verdict) -Rows $rows -Extra "The fail-safe stop fired before the next rung."
            exit 0
        }
    }

    Write-LadderStatus -State "complete" -Message "Median projection ladder completed all requested rungs." -CurrentT $null
    Write-Report -Heading "Completed all requested rungs." -Rows $rows
}
catch {
    Write-LadderStatus -State "failed" -Message $_.Exception.Message -CurrentT $null
    Write-Report -Heading "Failed." -Rows $rows -Extra $_.Exception.Message
    throw
}
finally {
    Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
}
