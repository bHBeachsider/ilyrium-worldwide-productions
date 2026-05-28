# setup_ssh_access.ps1
# -------------------------------------------------------------------
# RUN THIS ONCE on the EC2 Windows instance (via RDP).
# Enables OpenSSH Server with key-based auth using your EC2 key pair.
# After this runs successfully, you can SSH in from your local PC and
# never need RDP again.
#
# What it does:
#   1. Installs OpenSSH Server (Windows capability)
#   2. Starts and sets sshd to auto-start on boot
#   3. Adds Windows Firewall rule for port 22
#   4. Sets PowerShell as the default SSH shell
#   5. Pulls the EC2 key pair public key from instance metadata
#      and configures Administrator-level authorized_keys
#   6. Prints the exact SSH command to use from your local PC
#
# Usage on EC2 (after RDP):
#   1. Right-click PowerShell on Start menu -> Run as Administrator
#   2. Paste this entire script and press Enter
#      (or: save to file, then run: .\setup_ssh_access.ps1)
#   3. Wait ~30 seconds for completion
#
# Then on your LOCAL PC, also open port 22 in the security group:
#   aws ec2 authorize-security-group-ingress --region us-east-1 `
#       --group-id sg-03fd18b34e0bceb8f --protocol tcp --port 22 `
#       --cidr 73.138.177.179/32
#
# Then connect from local PC:
#   ssh -i C:\Users\bradu\.ssh\ilyrium-ue.pem Administrator@<public-ip>
# -------------------------------------------------------------------

$ErrorActionPreference = "Stop"

Write-Host "================================================================"
Write-Host "  Ilyrium EC2 OpenSSH Setup"
Write-Host "================================================================"

# ---- Step 1: Install OpenSSH Server ----
Write-Host ""
Write-Host "[1/6] Installing OpenSSH Server..."
$sshd = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($sshd.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $sshd.Name | Out-Null
    Write-Host "  [OK] OpenSSH Server installed"
} else {
    Write-Host "  [OK] OpenSSH Server already installed"
}

# ---- Step 2: Start and auto-start sshd ----
Write-Host ""
Write-Host "[2/6] Starting and enabling sshd service..."
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
$svc = Get-Service sshd
Write-Host "  [OK] sshd status: $($svc.Status), startup: $((Get-WmiObject -Query "SELECT StartMode FROM Win32_Service WHERE Name='sshd'").StartMode)"

# ---- Step 3: Firewall rule for port 22 ----
Write-Host ""
Write-Host "[3/6] Configuring Windows Firewall..."
$existing = Get-NetFirewallRule -Name "sshd" -ErrorAction SilentlyContinue
if (-not $existing) {
    New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    Write-Host "  [OK] Firewall rule 'sshd' added (port 22 inbound)"
} else {
    Write-Host "  [OK] Firewall rule already exists"
}

# ---- Step 4: PowerShell as default SSH shell ----
Write-Host ""
Write-Host "[4/6] Setting PowerShell as default SSH shell..."
if (-not (Test-Path "HKLM:\SOFTWARE\OpenSSH")) {
    New-Item -Path "HKLM:\SOFTWARE\OpenSSH" -Force | Out-Null
}
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
    -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -PropertyType String -Force | Out-Null
Write-Host "  [OK] SSH sessions will land in PowerShell (not cmd)"

# ---- Step 5: Pull EC2 key pair public key from instance metadata ----
Write-Host ""
Write-Host "[5/6] Fetching EC2 key pair public key from instance metadata..."
$adminKeysPath = "C:\ProgramData\ssh\administrators_authorized_keys"
try {
    # IMDSv2 - get token first
    $token = Invoke-RestMethod -Uri "http://169.254.169.254/latest/api/token" `
        -Method PUT `
        -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"}
    # Use token to fetch public key
    $publicKey = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key" `
        -Headers @{"X-aws-ec2-metadata-token" = $token}

    # Write to administrators_authorized_keys (special location for admin users)
    Set-Content -Path $adminKeysPath -Value $publicKey -Encoding ASCII -NoNewline

    # Lock down permissions - only SYSTEM and Administrators can read
    # (OpenSSH refuses to use the file otherwise)
    icacls $adminKeysPath /inheritance:r | Out-Null
    icacls $adminKeysPath /grant "Administrators:F" | Out-Null
    icacls $adminKeysPath /grant "SYSTEM:F" | Out-Null

    Write-Host "  [OK] Public key written to: $adminKeysPath"
    Write-Host "  [OK] Permissions: SYSTEM + Administrators only"
} catch {
    Write-Host "  [WARN] Could not fetch key from EC2 metadata. Error: $_"
    Write-Host "         You can still SSH in if you manually add your public key to:"
    Write-Host "         $adminKeysPath"
}

# ---- Step 6: Get public IP for the connection string ----
Write-Host ""
Write-Host "[6/6] Fetching public IP..."
try {
    $token = Invoke-RestMethod -Uri "http://169.254.169.254/latest/api/token" `
        -Method PUT `
        -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"}
    $publicIp = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/public-ipv4" `
        -Headers @{"X-aws-ec2-metadata-token" = $token}
    Write-Host "  [OK] Public IP: $publicIp"
} catch {
    $publicIp = "<check-AWS-console-for-current-public-IP>"
    Write-Host "  [WARN] Could not fetch public IP"
}

# Restart sshd to pick up authorized_keys + DefaultShell changes
Write-Host ""
Write-Host "Restarting sshd to apply config..."
Restart-Service sshd
Write-Host "  [OK] sshd restarted"

# ---- Final summary ----
Write-Host ""
Write-Host "================================================================"
Write-Host "  SSH SETUP COMPLETE"
Write-Host "================================================================"
Write-Host ""
Write-Host "From your LOCAL PC PowerShell, connect with:"
Write-Host ""
Write-Host "    ssh -i C:\Users\bradu\.ssh\ilyrium-ue.pem Administrator@$publicIp"
Write-Host ""
Write-Host "First connection: you'll be prompted to trust the host fingerprint."
Write-Host "Type 'yes' and press Enter."
Write-Host ""
Write-Host "----------------------------------------------------------------"
Write-Host "  IMPORTANT: open port 22 in the security group from your LOCAL"
Write-Host "  PC (the EC2 security group only has port 3389/RDP open right"
Write-Host "  now). Run this on your local PowerShell:"
Write-Host "----------------------------------------------------------------"
Write-Host ""
Write-Host "    aws ec2 authorize-security-group-ingress --region us-east-1 ``"
Write-Host "        --group-id sg-03fd18b34e0bceb8f --protocol tcp --port 22 ``"
Write-Host "        --cidr 73.138.177.179/32"
Write-Host ""
Write-Host "After that, ssh should work. Test, then disconnect RDP."
Write-Host ""
Write-Host "Optional: when you confirm SSH works, you can REMOVE the RDP rule:"
Write-Host ""
Write-Host "    aws ec2 revoke-security-group-ingress --region us-east-1 ``"
Write-Host "        --group-id sg-03fd18b34e0bceb8f --protocol tcp --port 3389 ``"
Write-Host "        --cidr 73.138.177.179/32"
Write-Host ""
