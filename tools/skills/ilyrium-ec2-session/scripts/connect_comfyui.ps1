# connect_comfyui.ps1
# -------------------------------------------------------------------
# Convenience helper: ensures the EC2 is running, then opens an
# INTERACTIVE SSH session in a new PowerShell window with port 8188
# forwarded for ComfyUI. Inside the new window, the user pastes the
# Launch-ComfyUI.ps1 command (printed at the bottom for copy/paste).
#
# We can't fully automate this because the SSH session must stay open
# while ComfyUI runs, and starting it from a script would orphan the
# terminal. The pattern: this script handles the prep, then drops a
# new shell into the user's hands.
# -------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$InstanceId = "i-030994c5371ee5de9",
    [string]$Region = "us-east-1",
    [string]$PemPath = "$env:USERPROFILE\.ssh\ilyrium-ue.pem",
    [int]$Port = 8188,
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================"
Write-Host "  Ilyrium EC2 - CONNECT (ComfyUI session)"
Write-Host "================================================================"

# ---- Step 1: confirm instance is running ----
Write-Host ""
Write-Host "[1/4] Confirming instance is running..."
$state = aws ec2 describe-instances --region $Region --instance-ids $InstanceId `
    --query 'Reservations[0].Instances[0].State.Name' --output text

if ($state -ne "running") {
    Write-Host "  Instance is '$state'. Use start_session.ps1 first, then re-run this."
    Write-Host ""
    Write-Host "    pwsh $PSScriptRoot\start_session.ps1"
    return
}
Write-Host "  [OK] Instance is running."

# ---- Step 2: get current public IP ----
Write-Host ""
Write-Host "[2/4] Getting public IP..."
$publicIp = aws ec2 describe-instances --region $Region --instance-ids $InstanceId `
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
Write-Host "  Public IP: $publicIp"

# ---- Step 3: spawn an interactive SSH session in a new PowerShell window ----
Write-Host ""
Write-Host "[3/4] Opening a new PowerShell window with the SSH tunnel..."
$sshArgs = "-i `"$PemPath`" -L $Port`:127.0.0.1:$Port Administrator@$publicIp"

# The "& 'C:\ComfyUI\Launch-ComfyUI.ps1'" line is auto-executed after the SSH
# session connects, so the user just has to leave the window alone.
# We pass the launch command via the SSH command field so it runs in PS on EC2.
$launchOnConnect = '& ''C:\ComfyUI\Launch-ComfyUI.ps1'''

# Use Start-Process so the new PS window stays open with ssh as foreground
Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoExit",
    "-Command",
    "ssh $sshArgs '$launchOnConnect'"
)
Write-Host "  [OK] SSH+ComfyUI window spawned. Wait ~10 sec for ComfyUI startup."

# ---- Step 4: open local browser ----
if (-not $NoBrowser) {
    Write-Host ""
    Write-Host "[4/4] Opening http://127.0.0.1:$Port in 15 seconds..."
    Start-Sleep -Seconds 15
    Start-Process "http://127.0.0.1:$Port"
    Write-Host "  [OK] Browser launched."
} else {
    Write-Host ""
    Write-Host "[4/4] -NoBrowser given, skipping browser launch."
    Write-Host "  Open manually: http://127.0.0.1:$Port"
}

Write-Host ""
Write-Host "================================================================"
Write-Host "  CONNECTED"
Write-Host "================================================================"
Write-Host ""
Write-Host "  Browser:    http://127.0.0.1:$Port"
Write-Host "  SSH window: keep open while using ComfyUI"
Write-Host ""
Write-Host "  When done:"
Write-Host "    1. Close the browser tab"
Write-Host "    2. In the SSH window: Ctrl+C (stops ComfyUI), then 'exit'"
Write-Host "    3. Run stop_session.ps1 to stop the instance and end billing"
Write-Host ""
Write-Host "================================================================"
