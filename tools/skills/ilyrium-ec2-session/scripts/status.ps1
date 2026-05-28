# status.ps1
# -------------------------------------------------------------------
# Quick status report on Brad's Ilyrium EC2 GPU workstation.
#
# Reports:
#   - Instance state (running/stopped/etc)
#   - Public IP if running, plus uptime + approximate cost so far
#   - Security group's current SSH allowlist
#   - Whether a local SSH tunnel is forwarding port 8188
#   - Whether ComfyUI is responding through the tunnel
# -------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$InstanceId = "i-030994c5371ee5de9",
    [string]$Region = "us-east-1",
    [string]$SecurityGroupId = "sg-03fd18b34e0bceb8f",
    [int]$ComfyPort = 8188,
    [double]$HourlyRate = 1.20
)

$ErrorActionPreference = "Continue"

Write-Host "================================================================"
Write-Host "  Ilyrium EC2 - STATUS"
Write-Host "================================================================"

# ---- EC2 instance state ----
Write-Host ""
Write-Host "Instance state:"
$info = aws ec2 describe-instances --region $Region --instance-ids $InstanceId --output json 2>$null | ConvertFrom-Json
$instance = $info.Reservations[0].Instances[0]
$state = $instance.State.Name
Write-Host "  state:        $state"

if ($state -eq "running") {
    Write-Host "  public IP:    $($instance.PublicIpAddress)"
    Write-Host "  type:         $($instance.InstanceType)"
    try {
        $launch = [datetime]::Parse($instance.LaunchTime).ToUniversalTime()
        $hours = ([datetime]::UtcNow - $launch).TotalHours
        $cost = $hours * $HourlyRate
        Write-Host "  uptime:       $([Math]::Round($hours, 2)) hours"
        Write-Host "  cost so far:  `$$([Math]::Round($cost, 2)) at `$$HourlyRate/hr"
    } catch {
        Write-Host "  uptime:       (could not compute)"
    }
} else {
    Write-Host "  (instance is $state, no further details)"
}

# ---- Security group SSH allowlist ----
Write-Host ""
Write-Host "SSH allowlist (port 22):"
$allowed = aws ec2 describe-security-groups --region $Region --group-ids $SecurityGroupId `
    --query 'SecurityGroups[0].IpPermissions[?ToPort==`22`].IpRanges[].CidrIp' --output text 2>$null
if (-not $allowed) {
    Write-Host "  (none - SSH is fully blocked. start_session.ps1 will fix this.)"
} else {
    ($allowed -split '\s+') | ForEach-Object { Write-Host "  $_" }
}

# Compare with current home IP
try {
    $myIp = (Invoke-RestMethod "https://api.ipify.org" -TimeoutSec 5).Trim()
    if (($allowed -split '\s+') -notcontains "$myIp/32") {
        Write-Host "  WARNING: your current home IP $myIp/32 is NOT allowed."
        Write-Host "           Run start_session.ps1 to refresh."
    }
} catch {
    Write-Host "  (could not check home IP)"
}

# ---- Local SSH tunnel on port 8188? ----
Write-Host ""
Write-Host "Local SSH tunnel on port $ComfyPort`:"
$tunnel = Test-NetConnection -ComputerName 127.0.0.1 -Port $ComfyPort -InformationLevel Quiet -WarningAction SilentlyContinue
if ($tunnel) {
    Write-Host "  [OK] Listening locally (tunnel appears active)"

    # Try a quick HTTP request to confirm ComfyUI is responding
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:$ComfyPort" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            Write-Host "  [OK] ComfyUI responding (HTTP 200, $($resp.RawContentLength) bytes)"
        } else {
            Write-Host "  HTTP returned $($resp.StatusCode) (unexpected)"
        }
    } catch {
        Write-Host "  Tunnel forwards but ComfyUI not responding (may not be launched on EC2)"
    }
} else {
    Write-Host "  Not listening - no SSH tunnel active"
    if ($state -eq "running") {
        Write-Host "  To connect: pwsh $PSScriptRoot\connect_comfyui.ps1"
    }
}

Write-Host ""
Write-Host "================================================================"
