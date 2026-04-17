param(
    [Parameter(Mandatory = $true)]
    [int]$Horizon,
    [Parameter(Mandatory = $true)]
    [string]$InitialQPath,
    [string]$ProfileName = "standard_tail",
    [string]$CaseStarts = "6,5,4,3",
    [switch]$IncludeSuffixAnchor,
    [switch]$CoordinateEdgePolish,
    [int]$CoordinateEdgeHeadPeriods = 3,
    [int]$CoordinateEdgeTailPeriods = 1,
    [string]$RemoteHost = "hfnt93@hamilton8.dur.ac.uk",
    [string]$RemoteBaseDir = "/nobackup/hfnt93/fert_runs",
    [int]$MaxIter = 5,
    [string]$WallTime = "08:00:00",
    [int]$CpusPerTask = 8,
    [string]$Memory = "16G"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-RemoteOutput {
    param([object[]]$OutputLines)

    $clean = New-Object System.Collections.Generic.List[string]
    foreach ($entry in @($OutputLines)) {
        if ($null -eq $entry) {
            continue
        }
        $text = ([string]$entry) -replace "`r", ""
        if ($text -match '^(Connection|Shared connection) to .+ closed\.$') {
            continue
        }
        if ($text -match '^client_loop: send disconnect: ') {
            continue
        }
        $clean.Add($text)
    }
    return $clean
}

function Invoke-RemoteCapture {
    param(
        [string]$RemoteHostName,
        [string[]]$SshBaseArgs,
        [string]$RemoteCommand,
        [int]$MaxAttempts = 4,
        [int]$RetryDelaySeconds = 20
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $output = & ssh -tt -o ConnectTimeout=10 @SshBaseArgs $RemoteHostName $RemoteCommand 2>$null
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        if ($LASTEXITCODE -eq 0) {
            return (Normalize-RemoteOutput -OutputLines $output)
        }
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    throw "Remote command failed after $MaxAttempts attempts: $RemoteCommand"
}

function Copy-RemoteItem {
    param(
        [string]$RemoteHostName,
        [string[]]$SshBaseArgs,
        [string]$LocalPath,
        [string]$RemotePath,
        [int]$MaxAttempts = 4,
        [int]$RetryDelaySeconds = 20
    )

    $payload = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($LocalPath))
    $escapedRemotePath = $RemotePath -replace "'", "'\''"
    $remoteBase64Path = "$escapedRemotePath.b64"
    $chunkLength = 6000

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Invoke-RemoteCapture -RemoteHostName $RemoteHostName -SshBaseArgs $SshBaseArgs -RemoteCommand "mkdir -p '$(Split-Path $escapedRemotePath -Parent)' && : > '$remoteBase64Path'" | Out-Null
            for ($offset = 0; $offset -lt $payload.Length; $offset += $chunkLength) {
                $length = [Math]::Min($chunkLength, $payload.Length - $offset)
                $chunk = $payload.Substring($offset, $length)
                Invoke-RemoteCapture -RemoteHostName $RemoteHostName -SshBaseArgs $SshBaseArgs -RemoteCommand "printf '%s' '$chunk' >> '$remoteBase64Path'" | Out-Null
            }
            Invoke-RemoteCapture -RemoteHostName $RemoteHostName -SshBaseArgs $SshBaseArgs -RemoteCommand "base64 -d '$remoteBase64Path' > '$escapedRemotePath' && rm -f '$remoteBase64Path'" | Out-Null
            return
        } catch {
            if ($attempt -ge $MaxAttempts) {
                throw
            }
        }
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    throw "Remote copy failed after $MaxAttempts attempts: $LocalPath -> $RemotePath"
}

function New-MaskString {
    param(
        [int]$Length,
        [int]$StartIndex
    )

    $values = for ($i = 1; $i -le $Length; $i++) {
        if ($i -ge $StartIndex) { "1" } else { "0" }
    }
    return ($values -join ",")
}

function New-FullPrevMask {
    param([int]$Length)
    if ($Length -le 0) {
        return ""
    }
    $values = @("0")
    if ($Length -gt 1) {
        $values += @(for ($i = 2; $i -le $Length; $i++) { "1" })
    }
    return ($values -join ",")
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$compiledRoot = Join-Path $projectRoot "compiled_sidecar"
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$mode = "t{0}_diag" -f $Horizon
$inputDir = Join-Path $compiledRoot ("truth\transition_input_{0}" -f $mode)
if (-not (Test-Path $inputDir)) {
    & (Join-Path $compiledRoot "export_transition_input.ps1") -Mode $mode | Out-Null
}

$caseStartList = @(
    $CaseStarts -split "," |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^\d+$' } |
        ForEach-Object { [int]$_ } |
        Where-Object { $_ -ge 1 -and $_ -le $Horizon }
) | Sort-Object -Descending
if ($caseStartList.Count -eq 0) {
    throw "No valid case starts provided."
}

$fullPrevMask = New-FullPrevMask -Length $Horizon
$caseSpecs = New-Object System.Collections.Generic.List[object]
foreach ($start in $caseStartList) {
    $caseSpecs.Add([pscustomobject]@{
        label = ("late{0}_{1}" -f $start, $Horizon)
        continuity = New-MaskString -Length $Horizon -StartIndex $start
        previous = $fullPrevMask
    })
}
if ($IncludeSuffixAnchor) {
    foreach ($start in $caseStartList) {
        $mask = New-MaskString -Length $Horizon -StartIndex $start
        $caseSpecs.Add([pscustomobject]@{
            label = ("late{0}_{1}_suffix_anchor" -f $start, $Horizon)
            continuity = $mask
            previous = $mask
        })
    }
}

$runLabel = "bellman_re_t{0}_suffix_ladder_hamilton" -f $Horizon
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$localStageDir = Join-Path $logsRoot ("{0}_{1}" -f $runLabel, $timestamp)
New-Item -ItemType Directory -Path $localStageDir | Out-Null

$archivePath = Join-Path $localStageDir ("compiled_sidecar_t{0}_suffix_ladder.tar.gz" -f $Horizon)
$scriptPath = Join-Path $localStageDir ("run_t{0}_suffix_ladder.sh" -f $Horizon)
$submissionPath = Join-Path $localStageDir "submission.txt"
$activePointer = Join-Path $logsRoot ("active_{0}.txt" -f $runLabel)
$keyPath = Join-Path $HOME ".ssh\id_ed25519"
$remoteRunDir = "{0}/{1}_{2}" -f $RemoteBaseDir.TrimEnd("/"), $runLabel, $timestamp

if (-not (Test-Path $keyPath)) {
    throw "SSH key not found: $keyPath"
}

$seedParts = @(
    $InitialQPath -split "," |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" }
)
if ($seedParts.Count -ne $Horizon) {
    throw "InitialQPath length $($seedParts.Count) does not match horizon $Horizon."
}
$seedString = ($seedParts -join ",")

$caseLines = foreach ($case in $caseSpecs) {
    'run_case "{0}" "{1}" "{2}"' -f $case.label, $case.continuity, $case.previous
}

$edgePolishLines = @()
if ($CoordinateEdgePolish) {
    $edgePolishLines += '    --coordinate-edge-polish \'
    if ($CoordinateEdgeHeadPeriods -gt 0) {
        $edgePolishLines += ('    --coordinate-edge-head-periods {0} \' -f $CoordinateEdgeHeadPeriods)
    }
    if ($CoordinateEdgeTailPeriods -gt 0) {
        $edgePolishLines += ('    --coordinate-edge-tail-periods {0} \' -f $CoordinateEdgeTailPeriods)
    }
}

$scriptLines = @(
    "#!/bin/bash"
    "#SBATCH --job-name=fert_t{0}_tail" -f $Horizon
    "#SBATCH --time={0}" -f $WallTime
    "#SBATCH --cpus-per-task={0}" -f $CpusPerTask
    "#SBATCH --mem={0}" -f $Memory
    "#SBATCH --output=slurm-%j.out"
    "#SBATCH --error=slurm-%j.err"
    ""
    "set -euo pipefail"
    ""
    'RUN_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"'
    'COMPILED_DIR="${RUN_DIR}/compiled_sidecar"'
    'BUILD_DIR="${RUN_DIR}/build"'
    'OUTPUT_DIR="${RUN_DIR}/outputs"'
    'STATUS_PATH="${RUN_DIR}/status.txt"'
    ('RESULTS_PATH="${RUN_DIR}/t' + $Horizon + '_cases.csv"')
    'SUMMARY_PATH="${RUN_DIR}/summary.txt"'
    ('INPUT_DIR="${COMPILED_DIR}/truth/transition_input_t' + $Horizon + '_diag"')
    'SEED="{0}"' -f $seedString
    'FULL_PREV_MASK="{0}"' -f $fullPrevMask
    ""
    "timestamp() {"
    "  date '+%Y-%m-%d %H:%M:%S'"
    "}"
    ""
    "log_status() {"
    '  printf ''%s %s\n'' "$(timestamp)" "$1" | tee -a "${STATUS_PATH}" >/dev/null'
    "}"
    ""
    "parse_field() {"
    '  local stdout_path="$1"'
    '  local pattern="$2"'
    '  python3 - "$stdout_path" "$pattern" <<''PY'''
    "import pathlib"
    "import re"
    "import sys"
    ""
    "text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace')"
    "match = re.search(sys.argv[2], text)"
    "print(match.group(1) if match else '')"
    "PY"
    "}"
    ""
    "extract_line_payload() {"
    '  local stdout_path="$1"'
    '  local prefix="$2"'
    '  python3 - "$stdout_path" "$prefix" <<''PY'''
    "import pathlib"
    "import sys"
    ""
    "text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace').splitlines()"
    "prefix = sys.argv[2]"
    "for line in text:"
    "    if line.startswith(prefix):"
    "        print(line.split(':', 1)[1].strip())"
    "        break"
    "PY"
    "}"
    ""
    "append_result() {"
    '  local label="$1"'
    '  local continuity_mask="$2"'
    '  local previous_mask="$3"'
    '  local maxres="$4"'
    '  local iterations="$5"'
    '  local stalled="$6"'
    '  local exit_code="$7"'
    '  local stdout_path="$8"'
    '  local stderr_path="$9"'
    '  local q_path="${10}"'
    '  local implied_q_path="${11}"'
    '  local residual_path="${12}"'
    ""
    '  python3 - "$RESULTS_PATH" "$label" "$continuity_mask" "$previous_mask" "$maxres" "$iterations" "$stalled" "$exit_code" "$stdout_path" "$stderr_path" "$q_path" "$implied_q_path" "$residual_path" <<''PY'''
    "import csv"
    "import os"
    "import sys"
    ""
    "results_path = sys.argv[1]"
    "row = sys.argv[2:]"
    "header = ["
    "    'case_label',"
    "    'continuity_mask',"
    "    'previous_implied_mask',"
    "    'max_abs_residual',"
    "    'iterations',"
    "    'stalled',"
    "    'exit_code',"
    "    'stdout_path',"
    "    'stderr_path',"
    "    'q_path',"
    "    'implied_q_path',"
    "    'residual_path',"
    "]"
    "write_header = not os.path.exists(results_path)"
    "with open(results_path, 'a', newline='', encoding='utf-8') as handle:"
    "    writer = csv.writer(handle)"
    "    if write_header:"
    "        writer.writerow(header)"
    "    writer.writerow(row)"
    "PY"
    "}"
    ""
    "run_case() {"
    '  local label="$1"'
    '  local continuity_mask="$2"'
    '  local previous_mask="$3"'
    '  local stdout_path="${OUTPUT_DIR}/${label}_stdout.log"'
    '  local stderr_path="${OUTPUT_DIR}/${label}_stderr.log"'
    ""
    '  log_status "START ${label}"'
    ""
    "  set +e"
    '  "${BUILD_DIR}/fertility_transition_re_cli" \'
    '    "${INPUT_DIR}" \'
    '    --initial-q-path "${SEED}" \'
    '    --q-search-grid "1.5,1.70,1.72,1.73,1.74,1.75,1.80,1.85,1.90,2.00,2.25,2.35,2.40,2.50" \'
    '    --damping 0.2 \'
    '    --max-iter {0} \' -f $MaxIter
    '    --vote-dp-scope remaining_path \'
    '    --backtracking-line-search \'
    '    --backtracking-activate-residual 0.5 \'
    '    --backtracking-accept-worsen-ratio 1.0 \'
    '    --backtracking-accept-worsen-abs-tol 0.0 \'
    '    --backtracking-shrink-factor 0.5 \'
    '    --max-backtracking-rounds 6 \'
    ('    --min-damping-path "{0}" \' -f ((1..$Horizon | ForEach-Object { "0.0125" }) -join ","))
    '    --coordinate-backtracking-line-search \'
    '    --coordinate-backtracking-activate-residual 0.2 \'
    '    --max-coordinate-backtracking-periods 1 \'
    '    --max-coordinate-backtracking-rounds 8 \'
    '    --coordinate-backtracking-require-improvement \'
    '    --coordinate-backtracking-improve-tol 0.0 \'
    ('    --coordinate-min-damping-path "{0}" \' -f ((1..$Horizon | ForEach-Object { "0.0015625" }) -join ","))
    $edgePolishLines
    '    --branch-continuity-mask "${continuity_mask}" \'
    '    --branch-continuity-vote-slack 1.0 \'
    '    --root-selection-lookahead \'
    '    --root-selection-lookahead-min-brackets 2 \'
    '    --root-selection-anchor previous_implied \'
    '    --root-selection-previous-implied-mask "${previous_mask}" \'
    '    --branch-hysteresis-mask "${FULL_PREV_MASK}" \'
    '    --branch-tie-break-mask "${FULL_PREV_MASK}" \'
    '    >"${stdout_path}" 2>"${stderr_path}"'
    '  local exit_code=$?'
    '  set -e'
    ""
    '  local maxres'
    '  maxres="$(parse_field "${stdout_path}" ''max abs residual:\s+([0-9Ee+\-\.]+)'')"'
    '  local iterations'
    '  iterations="$(parse_field "${stdout_path}" ''iterations run:\s+([0-9]+)'')"'
    '  local stalled'
    '  stalled="$(parse_field "${stdout_path}" ''stalled:\s+([01])'')"'
    '  local q_path'
    '  q_path="$(extract_line_payload "${stdout_path}" ''q path:'')"'
    '  local implied_q_path'
    '  implied_q_path="$(extract_line_payload "${stdout_path}" ''implied q path:'')"'
    '  local residual_path'
    '  residual_path="$(extract_line_payload "${stdout_path}" ''residual path:'')"'
    ""
    '  append_result \'
    '    "${label}" \'
    '    "${continuity_mask}" \'
    '    "${previous_mask}" \'
    '    "${maxres}" \'
    '    "${iterations}" \'
    '    "${stalled}" \'
    '    "${exit_code}" \'
    '    "${stdout_path}" \'
    '    "${stderr_path}" \'
    '    "${q_path}" \'
    '    "${implied_q_path}" \'
    '    "${residual_path}"'
    ""
    '  log_status "DONE ${label} maxres=${maxres} stalled=${stalled} exit=${exit_code}"'
    "}"
    ""
    'mkdir -p "${OUTPUT_DIR}"'
    ': > "${STATUS_PATH}"'
    'rm -f "${RESULTS_PATH}" "${SUMMARY_PATH}"'
    ""
    'log_status "CONFIGURE build_dir=${BUILD_DIR}"'
    'cmake -S "${COMPILED_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release >/dev/null'
    'log_status "BUILD target=fertility_transition_re_cli"'
    'cmake --build "${BUILD_DIR}" --target fertility_transition_re_cli -j "${SLURM_CPUS_PER_TASK:-8}" >/dev/null'
    ""
) + $caseLines + @(
    ""
    'python3 - "$RESULTS_PATH" "$SUMMARY_PATH" <<''PY'''
    "import csv"
    "import pathlib"
    "import sys"
    ""
    "results_path = pathlib.Path(sys.argv[1])"
    "summary_path = pathlib.Path(sys.argv[2])"
    "rows = list(csv.DictReader(results_path.open(encoding='utf-8')))"
    "rows.sort(key=lambda row: (float(row['max_abs_residual']), row['case_label']))"
    "best = rows[0]"
    "summary_path.write_text("
    "    '\\n'.join("
    "        ["
    "            'Workflow: success',"
    '            f"Best case: {best[''case_label'']}",'
    '            f"Best maxres: {best[''max_abs_residual'']}",'
    '            f"Results path: {results_path}",'
    "        ]"
    "    )"
    "    + '\\n',"
    "    encoding='utf-8',"
    ")"
    "PY"
    ""
    'log_status "SUCCESS summary=${SUMMARY_PATH}"'
)
[System.IO.File]::WriteAllText(
    $scriptPath,
    ($scriptLines -join "`n"),
    (New-Object System.Text.UTF8Encoding($false))
)

$sshBaseArgs = @(
    "-F", "NUL",
    "-o", "IdentitiesOnly=yes",
    "-i", $keyPath
)

Set-Location $compiledRoot
& tar.exe -czf $archivePath CMakeLists.txt include src ("truth/transition_input_{0}" -f $mode)
Set-Location $projectRoot

Invoke-RemoteCapture -RemoteHostName $RemoteHost -SshBaseArgs $sshBaseArgs -RemoteCommand "mkdir -p '$remoteRunDir'" | Out-Null
Copy-RemoteItem -RemoteHostName $RemoteHost -SshBaseArgs $sshBaseArgs -LocalPath $archivePath -RemotePath "$remoteRunDir/compiled_sidecar.tar.gz"
Copy-RemoteItem -RemoteHostName $RemoteHost -SshBaseArgs $sshBaseArgs -LocalPath $scriptPath -RemotePath "$remoteRunDir/run_t${Horizon}_suffix_ladder.sh"

$remoteSubmitCommand = @"
set -euo pipefail
cd '$remoteRunDir'
mkdir -p compiled_sidecar
tar -xzf compiled_sidecar.tar.gz -C compiled_sidecar
chmod +x run_t${Horizon}_suffix_ladder.sh
sbatch run_t${Horizon}_suffix_ladder.sh
"@

$sbatchOutput = Invoke-RemoteCapture -RemoteHostName $RemoteHost -SshBaseArgs $sshBaseArgs -RemoteCommand $remoteSubmitCommand
if ([string]::IsNullOrWhiteSpace($sbatchOutput)) {
    throw "Hamilton submission returned no output for $remoteRunDir."
}
$jobIdMatch = [regex]::Match($sbatchOutput, "Submitted batch job\s+([0-9]+)")
$jobId = if ($jobIdMatch.Success) { $jobIdMatch.Groups[1].Value } else { "" }
if ([string]::IsNullOrWhiteSpace($jobId)) {
    throw "Could not parse Hamilton job id from submission output: $sbatchOutput"
}

@(
    "submitted_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "profile_name=$ProfileName"
    "case_starts=$($caseStartList -join ',')"
    "include_suffix_anchor=$([bool]$IncludeSuffixAnchor)"
    "max_iter=$MaxIter"
    "wall_time=$WallTime"
    "remote_host=$RemoteHost"
    "remote_run_dir=$remoteRunDir"
    "job_id=$jobId"
    "local_stage_dir=$localStageDir"
    "archive_path=$archivePath"
    "submission_output=$sbatchOutput"
) | Set-Content -LiteralPath $activePointer

@(
    "Hamilton submission complete"
    "horizon=$Horizon"
    "profile_name=$ProfileName"
    "case_starts=$($caseStartList -join ',')"
    "include_suffix_anchor=$([bool]$IncludeSuffixAnchor)"
    "max_iter=$MaxIter"
    "wall_time=$WallTime"
    "remote_host=$RemoteHost"
    "remote_run_dir=$remoteRunDir"
    "job_id=$jobId"
    "submission_output=$sbatchOutput"
) | Set-Content -LiteralPath $submissionPath

Write-Output $submissionPath
