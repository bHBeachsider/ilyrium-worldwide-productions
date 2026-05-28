# stop_session.ps1
# -------------------------------------------------------------------
# Stops Brad's Ilyrium EC2 GPU workstation cleanly. Calculates rough
# billing for the current session and reports it.
#
# Idempotent: safe if instance is already stopped.
# -------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$InstanceId = "i-030994c5371ee5de9",
    [string]$Region = "us-east-1",
    [double]$HourlyRate = 1.20
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================"
Write-Host "  Ilyrium EC2 - STOP SESSION"
Write-Host "  Instance: $InstanceId"
Write-Host "================================================================"

# ---- Step 1: get state + uptime ----
Write-Host ""
Write-Host "[1/3] Checking instance state and uptime..."
$info = aws ec2 describe-instances --region $Region --instance-ids $InstanceId --output json | ConvertFrom-Json
$instance = $info.Reservations[0].Instances[0]
$state = $instance.State.Name
$launchTime = $instance.LaunchTime
Write-Host "  Current state:  $state"
Write-Host "  Last started:   $launchTime"

if ($state -eq "stopped") {
    Write-Host "  [OK] Already stopped. Nothing to do."
    Write-Host ""
    Write-Host "  Storage continues at ~`$0.30/day for the 300 GB EBS volume."
    return
}
if ($state -eq "stopping") {
    Write-Host "  [OK] Already stopping. Will wait for stopped state."
} elseif ($state -eq "running") {
    # Calculate session cost
    try {
        $launch = [datetime]::Parse($launchTime).ToUniversalTime()
        $now = [datetime]::UtcNow
        $hours = ($now - $launch).TotalHours
        $cost = $hours * $HourlyRate
        Write-Host "  Session uptime: $([Math]::Round($hours, 2)) hours"
        Write-Host "  Estimated cost: `$$([Math]::Round($cost, 2)) at `$$HourlyRate/hr"
    } catch {
        Write-Host "  (Could not compute uptime)"
    }

    Write-Host ""
    Write-Host "[2/3] Stopping instance..."
    aws ec2 stop-instances --region $Region --instance-ids $InstanceId | Out-Null
    Write-Host "  [OK] Stop requested."
} else {
    Write-Error "Instance in unexpected state: $state."
    return
}

# ---- Step 3: wait for stopped ----
Write-Host ""
Write-Host "[3/3] Waiting for stopped state..."
aws ec2 wait instance-stopped --region $Region --instance-ids $InstanceId
Write-Host "  [OK] Instance is stopped."

Write-Host ""
Write-Host "================================================================"
Write-Host "  STOPPED. ~`$$HourlyRate/hr compute billing has ended."
Write-Host "  Storage continues at ~`$0.30/day for the EBS volume."
Write-Host "================================================================"
Write-Host ""
Write-Host "  To resume later:"
Write-Host "    pwsh C:\Users\bradu\Documents\Ilyrium\tools\skills\ilyrium-ec2-session\scripts\start_session.ps1"
