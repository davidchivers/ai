$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$logDir = Join-Path $thisDir 'workflow_logs'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

function Invoke-MatlabStage {
    param(
        [Parameter(Mandatory = $true)][string]$StageName,
        [Parameter(Mandatory = $true)][string]$BatchCommand
    )

    $stdout = Join-Path $logDir ($StageName + '_stdout.log')
    $stderr = Join-Path $logDir ($StageName + '_stderr.log')
    $args = "-batch `"$BatchCommand`""

    Write-Host "=== $StageName ==="
    Write-Host "stdout: $stdout"
    Write-Host "stderr: $stderr"

    $proc = Start-Process -FilePath $matlab -ArgumentList $args -WorkingDirectory $thisDir `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru -Wait

    if ($proc.ExitCode -ne 0) {
        throw "MATLAB stage '$StageName' failed with exit code $($proc.ExitCode)."
    }
}

$stages = @(
    @{
        Name = 'stage1_transition_diagnostic'
        Command = "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); run_demographic_forecast_re_no_politics"
    },
    @{
        Name = 'stage2_tuning_grid'
        Command = "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); run_transition_re_tuning_grid"
    }
)

foreach ($stage in $stages) {
    Invoke-MatlabStage -StageName $stage.Name -BatchCommand $stage.Command
}

Write-Host 'Workflow finished successfully.'
