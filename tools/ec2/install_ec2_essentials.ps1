# install_ec2_essentials.ps1
# -------------------------------------------------------------------
# Installs the studio-essential CLI tools on a fresh EC2 Windows
# instance. Run AFTER UE/Cesium are installed but BEFORE you snapshot
# as ilyrium-ue57-base AMI.
#
# Installs via Chocolatey (Windows package manager):
#   - AWS CLI v2          (S3 transfers, EC2 management)
#   - Python 3.11         (running Ilyrium pipeline scripts)
#   - Git                 (cloning script repos)
#   - 7zip                (handling .upack, ComfyUI portable .7z)
#   - ffmpeg              (video encoding/transcoding on GPU)
#
# Usage on EC2:
#   1. Open PowerShell as Administrator
#   2. Paste this entire script (or save to file and run)
#   3. Wait ~5 minutes for all installs
#
# After this runs, you can SSH in from local PC (assuming SSH setup
# was already done via setup_ssh_access.ps1) and use these tools.
# -------------------------------------------------------------------

$ErrorActionPreference = "Stop"

Write-Host "================================================================"
Write-Host "  Ilyrium EC2 Essentials Install"
Write-Host "================================================================"

# ---- Step 1: Install Chocolatey (package manager) ----
Write-Host ""
Write-Host "[1/6] Checking for Chocolatey..."
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    # Refresh PATH so 'choco' is callable in this session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "  [OK] Chocolatey installed"
} else {
    Write-Host "  [OK] Chocolatey already installed"
}

# ---- Step 2-6: Install packages ----
$packages = @(
    @{ Name = "awscli";   Display = "AWS CLI v2";  Verify = "aws"     },
    @{ Name = "python311"; Display = "Python 3.11"; Verify = "python" },
    @{ Name = "git";      Display = "Git";         Verify = "git"     },
    @{ Name = "7zip";     Display = "7-Zip";       Verify = "7z"      },
    @{ Name = "ffmpeg";   Display = "FFmpeg";      Verify = "ffmpeg"  }
)

$stepNum = 2
foreach ($pkg in $packages) {
    Write-Host ""
    Write-Host "[$stepNum/6] Installing $($pkg.Display)..."
    if (Get-Command $pkg.Verify -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] $($pkg.Display) already installed"
    } else {
        choco install $pkg.Name -y --no-progress
        # Refresh PATH for this session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        if (Get-Command $pkg.Verify -ErrorAction SilentlyContinue) {
            Write-Host "  [OK] $($pkg.Display) installed and on PATH"
        } else {
            Write-Host "  [WARN] $($pkg.Display) installed but not yet on PATH (will work in new shell)"
        }
    }
    $stepNum++
}

# ---- Verification ----
Write-Host ""
Write-Host "================================================================"
Write-Host "  Verification"
Write-Host "================================================================"
$tests = @(
    @{ Cmd = "aws";    Display = "AWS CLI" },
    @{ Cmd = "python"; Display = "Python"  },
    @{ Cmd = "git";    Display = "Git"     },
    @{ Cmd = "7z";     Display = "7-Zip"   },
    @{ Cmd = "ffmpeg"; Display = "FFmpeg"  }
)
foreach ($t in $tests) {
    try {
        $version = & $t.Cmd --version 2>&1 | Select-Object -First 1
        Write-Host "  [OK] $($t.Display): $version"
    } catch {
        Write-Host "  [FAIL] $($t.Display) not callable"
    }
}

Write-Host ""
Write-Host "================================================================"
Write-Host "  ESSENTIALS INSTALL COMPLETE"
Write-Host "================================================================"
Write-Host ""
Write-Host "Next steps (also run via SSH from local PC if SSH is set up):"
Write-Host ""
Write-Host "  1. Configure AWS CLI with the ilyrium-admin credentials:"
Write-Host "       aws configure"
Write-Host "     (or copy ~/.aws/credentials from your local PC via scp)"
Write-Host ""
Write-Host "  2. Test S3 access (verifies AWS setup):"
Write-Host "       aws s3 ls s3://ilyrium/"
Write-Host ""
Write-Host "  3. Snapshot this instance as an AMI to save all installs:"
Write-Host "       (run from your LOCAL PC)"
Write-Host "       aws ec2 create-image --region us-east-1 ``"
Write-Host "           --instance-id i-030994c5371ee5de9 ``"
Write-Host "           --name ilyrium-ue57-base ``"
Write-Host "           --description 'UE 5.7 + Cesium + essentials' ``"
Write-Host "           --no-reboot"
Write-Host ""
Write-Host "  4. Optional: install ComfyUI for AI image gen on this GPU."
Write-Host "     See install_comfyui_ec2.ps1 (next script)."
Write-Host ""
