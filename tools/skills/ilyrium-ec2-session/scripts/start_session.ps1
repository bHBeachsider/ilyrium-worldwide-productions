# start_session.ps1
# -------------------------------------------------------------------
# Starts Brad's Ilyrium EC2 GPU workstation, waits for running state,
# retrieves the new public IP, refreshes the security group with his
# current home IP, then prints the SSH command for him to paste in a
# fresh PowerShell window.
#
# Idempotent: safe to run if the instance is already running.
# -------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$InstanceId = "i-030994c5371ee5de9",
    [string]$Region = "us-east-1",
    [string]$SecurityGroupId = "sg-03fd18b34e0bceb8f",
    [string]$PemPath = "$env:USERPROFILE\.ssh\ilyrium-ue.pem",
    [int]$Port = 8188
)

$ErrorActionPreference = "Stop"

function Write-Step($n, $total, $msg) {
    Write-Host "[$n/$total] $msg"
}

Write-Host "================================================================"
Write-Host "  Ilyrium EC2 - START SESSION"
Write-Host "  Instance: $InstanceId"
Write-Host "  Billing begins at ~`$1.20/hr once running."
Write-Host "================================================================"

# ---- Step 1: get current state ----
Write-Host ""
Write-Step 1 5 "Checking current instance state..."
$state = aws ec2 describe-instances --region $Region --instance-ids $InstanceId `
    --query 'Reservations[0].Instances[0].State.Name' --output text
Write-Host "  Current state: $state"

if ($state -eq "running") {
    Write-Host "  [OK] Already running. Skipping start."
} elseif ($state -eq "stopped") {
    Write-Step 2 5 "Starting instance..."
    aws ec2 start-instances --region $Region --instance-ids $InstanceId | Out-Null
    Write-Host "  [OK] Start requested."
    Write-Host "  Waiting for running state (60-90 sec)..."
    aws ec2 wait instance-running --region $Region --instance-ids $InstanceId
    Write-Host "  [OK] Instance is running."
} else {
    Write-Error "Instance is in unexpected state: $state. Cannot proceed automatically."
    return
}

# ---- Step 3: get current public IP ----
Write-Host ""
Write-Step 3 5 "Getting current public IP (changes on every stop/start)..."
$publicIp = aws ec2 describe-instances --region $Region --instance-ids $InstanceId `
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
Write-Host "  Public IP: $publicIp"

# ---- Step 4: check + update home IP allowlist in security group ----
Write-Host ""
Write-Step 4 5 "Checking your home IP against security group allowlist..."
try {
    $myIp = (Invoke-RestMethod "https://api.ipify.org" -TimeoutSec 10).Trim()
    Write-Host "  Your current home IP: $myIp"
} catch {
    Write-Warning "  Could not detect home IP. You may need to manually update the SG."
    $myIp = $null
}

if ($myIp) {
    $allowed = aws ec2 describe-security-groups --region $Region --group-ids $SecurityGroupId `
        --query 'SecurityGroups[0].IpPermissions[?ToPort==`22`].IpRanges[].CidrIp' --output text
    $allowedTrimmed = ($allowed -split '\s+') | ForEach-Object { $_.Trim() } | Where-Object { $_ }

    $myCidr = "$myIp/32"
    if ($allowedTrimmed -contains $myCidr) {
        Write-Host "  [OK] $myCidr already allowed for SSH"
    } else {
        Write-Host "  Updating security group: removing stale rules, adding $myCidr..."
        # Remove stale entries (any IPs that aren't yours)
        foreach ($stale in $allowedTrimmed) {
            if ($stale -ne $myCidr) {
                Write-Host "    revoking $stale"
                aws ec2 revoke-security-group-ingress --region $Region --group-id $SecurityGroupId `
                    --protocol tcp --port 22 --cidr $stale 2>&1 | Out-Null
            }
        }
        # Add current IP
        aws ec2 authorize-security-group-ingress --region $Region --group-id $SecurityGroupId `
            --protocol tcp --port 22 --cidr $myCidr 2>&1 | Out-Null
        Write-Host "  [OK] SSH allowed from $myCidr"
    }
}

# ---- Step 5: print connect command ----
Write-Host ""
Write-Step 5 5 "Ready to connect."
Write-Host ""
Write-Host "================================================================"
Write-Host "  CONNECTION INFO"
Write-Host "================================================================"
Write-Host ""
Write-Host "  Public IP:  $publicIp"
Write-Host "  Username:   Administrator"
Write-Host "  PEM file:   $PemPath"
Write-Host ""
Write-Host "  Paste this in a FRESH PowerShell window to connect"
Write-Host "  (with ComfyUI port-forward):"
Write-Host ""
Write-Host "    ssh -i $PemPath -L $Port`:127.0.0.1:$Port Administrator@$publicIp"
Write-Host ""
Write-Host "  Once at the EC2 prompt, launch ComfyUI:"
Write-Host ""
Write-Host "    & 'C:\ComfyUI\Launch-ComfyUI.ps1'"
Write-Host ""
Write-Host "  Then in your local browser:"
Write-Host ""
Write-Host "    http://127.0.0.1:$Port"
Write-Host ""
Write-Host "================================================================"
Write-Host "  STOP THE INSTANCE WHEN DONE:"
Write-Host "    pwsh C:\Users\bradu\Documents\Ilyrium\tools\skills\ilyrium-ec2-session\scripts\stop_session.ps1"
Write-Host "================================================================"
