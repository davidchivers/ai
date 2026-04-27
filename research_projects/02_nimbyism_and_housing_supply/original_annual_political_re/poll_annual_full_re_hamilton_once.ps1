[CmdletBinding()]
param(
    [string]$SshHost = "hamilton8",
    [string[]]$JobIds = @("16894032", "16894205", "16894254"),
    [string[]]$Stages = @("reT4BBTail_04261648", "reT80A_04262004", "reT40D_04262131"),
    [string]$RemoteRoot = "/nobackup/hfnt93/nimby_annual_runs",
    [string]$TaskName = "NimbyAnnualFullREPoll",
    [int]$ExpectedSummaryCount = 7,
    [switch]$NoUnregister
)

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutRoot = Join-Path $ScriptDir "truth\annual_full_re_hamilton_poll"
$CsvRoot = Join-Path $OutRoot "csv"
New-Item -ItemType Directory -Force -Path $OutRoot, $CsvRoot | Out-Null

$CheckedAt = Get-Date
$JobList = ($JobIds -join ",")

$SqueueLines = @(& ssh $SshHost "squeue -h -j $JobList -o '%i|%T|%M|%R'" 2>&1)
$SqueueExit = $LASTEXITCODE
$ActiveJobs = @()
if ($SqueueExit -eq 0) {
    $ActiveJobs = @($SqueueLines | Where-Object { $_ -and $_.Trim().Length -gt 0 })
}

$AllJobsInactive = ($SqueueExit -eq 0 -and $ActiveJobs.Count -eq 0)
$RemoteCsvPattern = if ($AllJobsInactive) { "*.csv" } else { "summary_all.csv" }

$SummaryRows = @()
$FetchErrors = @()
$FetchedCsvCount = 0
foreach ($Stage in $Stages) {
    $RemoteTruth = "$RemoteRoot/$Stage/annual/truth/annual_political_full_re_price_path"
    $RemoteCsvs = @(& ssh $SshHost "if [ -d '$RemoteTruth' ]; then find '$RemoteTruth' -name '$RemoteCsvPattern' -print 2>/dev/null; fi" 2>&1)
    if ($LASTEXITCODE -ne 0) {
        $FetchErrors += "find failed for $Stage"
        continue
    }

    foreach ($RemoteCsv in $RemoteCsvs) {
        if (-not $RemoteCsv -or $RemoteCsv.Trim().Length -eq 0) {
            continue
        }

        $RemoteCsv = $RemoteCsv.Trim()
        $RunName = ($RemoteCsv -split "/")[-2]
        $FileName = ($RemoteCsv -split "/")[-1]
        $LocalStageDir = Join-Path $CsvRoot $Stage
        $LocalRunDir = Join-Path $LocalStageDir $RunName
        New-Item -ItemType Directory -Force -Path $LocalRunDir | Out-Null
        $LocalCsv = Join-Path $LocalRunDir $FileName

        & scp "$SshHost`:$RemoteCsv" $LocalCsv 1>$null 2>$null
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $LocalCsv)) {
            $FetchErrors += "scp failed for $RemoteCsv"
            continue
        }
        $FetchedCsvCount += 1

        if ($FileName -ne "summary_all.csv") {
            continue
        }

        try {
            $Rows = @(Import-Csv -Path $LocalCsv)
            if ($Rows.Count -gt 0) {
                $Last = $Rows[-1]
                $SummaryRows += [pscustomobject]@{
                    stage              = $Stage
                    run_name           = $RunName
                    outer_iter         = $Last.outer_iter
                    report_T           = $Last.report_T
                    internal_T         = $Last.internal_T
                    tail_years         = $Last.tail_years
                    eta                = $Last.eta
                    scenario           = $Last.demographic_scenario
                    max_abs_path_gap   = $Last.max_abs_path_gap
                    max_abs_vote_resid = $Last.max_abs_vote_resid
                    verdict            = $Last.verdict
                    local_summary      = $LocalCsv
                }
            }
        } catch {
            $FetchErrors += "parse failed for $LocalCsv`: $($_.Exception.Message)"
        }
    }
}

$HaveExpectedSummaries = ($SummaryRows.Count -ge $ExpectedSummaryCount)
$ShouldStop = ($AllJobsInactive -and $HaveExpectedSummaries -and $FetchErrors.Count -eq 0 -and -not $NoUnregister)

$State = [pscustomobject]@{
    checked_at             = $CheckedAt.ToString("s")
    ssh_host               = $SshHost
    job_ids                = $JobIds
    stages                 = $Stages
    squeue_exit            = $SqueueExit
    active_jobs            = $ActiveJobs
    remote_csv_pattern     = $RemoteCsvPattern
    fetched_csv_count      = $FetchedCsvCount
    fetched_summary_count  = $SummaryRows.Count
    expected_summary_count = $ExpectedSummaryCount
    fetch_errors           = $FetchErrors
    all_jobs_inactive      = $AllJobsInactive
    have_expected_summaries = $HaveExpectedSummaries
    will_unregister_task   = $ShouldStop
    summaries              = $SummaryRows
}

$StatePath = Join-Path $OutRoot "latest_state.json"
$State | ConvertTo-Json -Depth 6 | Set-Content -Path $StatePath -Encoding UTF8

$ReportPath = Join-Path $OutRoot "latest_report.md"
$CheckedAtText = $CheckedAt.ToString("yyyy-MM-dd HH:mm:ss")
$Lines = @()
$Lines += "# Annual full-RE Hamilton poll"
$Lines += ""
$Lines += "- Checked at: $CheckedAtText"
$Lines += "- Jobs: $JobList"
$Lines += "- Active jobs: $($ActiveJobs.Count)"
$Lines += "- Remote CSV pattern: $RemoteCsvPattern"
$Lines += "- Fetched CSV files: $FetchedCsvCount"
$Lines += "- Fetched summaries: $($SummaryRows.Count) / $ExpectedSummaryCount"
$Lines += "- Scheduler stop condition met: $ShouldStop"
$Lines += ""
if ($ActiveJobs.Count -gt 0) {
    $Lines += "## Active Hamilton jobs"
    foreach ($Job in $ActiveJobs) {
        $Lines += ("- ``{0}``" -f $Job)
    }
    $Lines += ""
}
if ($SummaryRows.Count -gt 0) {
    $Lines += "## Latest summary rows"
    $Lines += "| stage | scenario | iter | T | tail | path gap | vote resid | verdict |"
    $Lines += "|---|---:|---:|---:|---:|---:|---:|---|"
    foreach ($Row in $SummaryRows | Sort-Object stage, run_name) {
        $Lines += "| $($Row.stage) | $($Row.scenario) | $($Row.outer_iter) | $($Row.report_T) | $($Row.tail_years) | $($Row.max_abs_path_gap) | $($Row.max_abs_vote_resid) | $($Row.verdict) |"
    }
    $Lines += ""
}
if ($FetchErrors.Count -gt 0) {
    $Lines += "## Fetch errors"
    foreach ($Err in $FetchErrors) {
        $Lines += "- $Err"
    }
    $Lines += ""
}
if ($ShouldStop) {
    $Lines += "## Final action"
    $Lines += "Hamilton jobs are inactive and expected summaries were fetched. Unregistering scheduled task `$TaskName`."
}
$Lines | Set-Content -Path $ReportPath -Encoding UTF8

if ($ShouldStop) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
}

if ($SqueueExit -ne 0) {
    exit 2
}
if ($FetchErrors.Count -gt 0) {
    exit 1
}
exit 0
