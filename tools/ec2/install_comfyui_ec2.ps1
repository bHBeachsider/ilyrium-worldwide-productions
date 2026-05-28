# install_comfyui_ec2.ps1
# -------------------------------------------------------------------
# Installs ComfyUI portable on the EC2 GPU instance.
# Downloads the latest ComfyUI Windows portable release from GitHub,
# extracts it to C:\ComfyUI, and creates a launch helper.
#
# After install, access ComfyUI from your LOCAL browser via SSH
# tunnel - no need to open port 8188 in the security group.
#
# Prerequisites:
#   - install_ec2_essentials.ps1 must have run first (needs 7-Zip)
#   - NVIDIA L4 GPU with drivers (already on this AMI)
#
# Usage (from LOCAL PC after copying via scp):
#   scp -i C:\Users\bradu\.ssh\ilyrium-ue.pem `
#       C:\Users\bradu\Documents\Ilyrium\tools\ec2\install_comfyui_ec2.ps1 `
#       Administrator@<EC2-IP>:C:/install_comfyui.ps1
#
#   ssh -i C:\Users\bradu\.ssh\ilyrium-ue.pem Administrator@<EC2-IP> `
#       'Set-ExecutionPolicy Bypass -Scope Process -Force; & C:\install_comfyui.ps1'
# -------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$InstallDir = "C:\ComfyUI",
    [int]$Port = 8188,
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================"
Write-Host "  Ilyrium ComfyUI Install (EC2)"
Write-Host "================================================================"

# ---- Step 1: verify 7-Zip is available ----
Write-Host ""
Write-Host "[1/5] Checking prerequisites..."
$sevenZip = "C:\Program Files\7-Zip\7z.exe"
if (-not (Test-Path $sevenZip)) {
    # Try alternate location
    $sevenZip = (Get-Command 7z -ErrorAction SilentlyContinue).Source
    if (-not $sevenZip) {
        Write-Error "7-Zip not found. Run install_ec2_essentials.ps1 first."
        return
    }
}
Write-Host "  [OK] 7-Zip at: $sevenZip"

# Verify GPU is present
$nvidia = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($nvidia) {
    Write-Host "  [OK] NVIDIA GPU detected (nvidia-smi available)"
} else {
    Write-Warning "  nvidia-smi not on PATH - GPU acceleration may not work"
}

# ---- Step 2: find latest ComfyUI portable release ----
Write-Host ""
Write-Host "[2/5] Finding latest ComfyUI portable release..."
$downloadPath = "C:\ComfyUI_portable.7z"

if ($SkipDownload -and (Test-Path $downloadPath)) {
    Write-Host "  [OK] -SkipDownload set, using existing $downloadPath"
} else {
    try {
        $release = Invoke-RestMethod "https://api.github.com/repos/comfyanonymous/ComfyUI/releases/latest" `
            -Headers @{ "User-Agent" = "Ilyrium-Setup" }
        $asset = $release.assets | Where-Object {
            $_.name -match "windows_portable.*nvidia" -and $_.name -notmatch "cpu"
        } | Select-Object -First 1
        if (-not $asset) {
            Write-Error "Could not find Windows NVIDIA portable in latest release."
            return
        }
        $url = $asset.browser_download_url
        $sizeMB = [Math]::Round($asset.size / 1MB, 0)
        Write-Host "  [OK] Found: $($asset.name) ($sizeMB MB)"
        Write-Host "       URL: $url"

        # ---- Step 3: download ----
        Write-Host ""
        Write-Host "[3/5] Downloading (this can take 5-10 minutes)..."
        $progressPreference = 'silentlyContinue'   # speeds up Invoke-WebRequest
        Invoke-WebRequest -Uri $url -OutFile $downloadPath -UseBasicParsing
        $progressPreference = 'Continue'
        $downloadedMB = [Math]::Round((Get-Item $downloadPath).Length / 1MB, 0)
        Write-Host "  [OK] Downloaded $downloadedMB MB to $downloadPath"
    } catch {
        Write-Error "Failed to download ComfyUI: $_"
        return
    }
}

# ---- Step 4: extract ----
Write-Host ""
Write-Host "[4/5] Extracting to C:\ ..."
if (Test-Path "C:\ComfyUI_windows_portable") {
    Write-Host "  [WARN] C:\ComfyUI_windows_portable already exists. Skipping extract."
    Write-Host "         Delete it first if you want a fresh install."
} else {
    & $sevenZip x $downloadPath -oC:\ -y | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "7-Zip extraction failed with exit code $LASTEXITCODE"
        return
    }
    Write-Host "  [OK] Extracted to C:\ComfyUI_windows_portable"
}

# Move/rename to the requested InstallDir for consistency
$portableDir = "C:\ComfyUI_windows_portable"
if ($InstallDir -ne $portableDir -and -not (Test-Path $InstallDir)) {
    Write-Host "  Moving to $InstallDir..."
    Move-Item $portableDir $InstallDir
}
$comfyRoot = if (Test-Path $InstallDir) { $InstallDir } else { $portableDir }

# ---- Step 5: create launch helper ----
Write-Host ""
Write-Host "[5/5] Creating launch helper..."
$launchScript = @"
# Launch-ComfyUI.ps1 - start ComfyUI bound to localhost only
# Access from your LOCAL browser via SSH tunnel:
#   ssh -i ~/.ssh/ilyrium-ue.pem -L $Port`:localhost:$Port Administrator@<EC2-IP>
# Then open http://localhost:$Port in your local Chrome.

Set-Location '$comfyRoot'
& .\python_embeded\python.exe -s ComfyUI\main.py ``
    --windows-standalone-build ``
    --listen 127.0.0.1 ``
    --port $Port
"@
Set-Content -Path "$comfyRoot\Launch-ComfyUI.ps1" -Value $launchScript -Encoding ASCII
Write-Host "  [OK] Launch helper at $comfyRoot\Launch-ComfyUI.ps1"

# Cleanup the .7z (saves ~3 GB)
if (Test-Path $downloadPath) {
    Remove-Item $downloadPath -Force
    Write-Host "  [OK] Removed download archive (saved space)"
}

# ---- Final summary ----
Write-Host ""
Write-Host "================================================================"
Write-Host "  COMFYUI INSTALL COMPLETE"
Write-Host "================================================================"
Write-Host ""
Write-Host "Location: $comfyRoot"
Write-Host ""
Write-Host "TO START COMFYUI (run this in an SSH session to EC2):"
Write-Host ""
Write-Host "  & '$comfyRoot\Launch-ComfyUI.ps1'"
Write-Host ""
Write-Host "TO ACCESS FROM YOUR LOCAL BROWSER (run on LOCAL PC):"
Write-Host ""
Write-Host "  # 1. Open SSH tunnel forwarding port $Port to local"
Write-Host "  ssh -i C:\Users\bradu\.ssh\ilyrium-ue.pem -L $Port`:localhost:$Port Administrator@<EC2-IP>"
Write-Host ""
Write-Host "  # 2. While tunnel is open, in another local PowerShell:"
Write-Host "  Start-Process http://localhost:$Port"
Write-Host ""
Write-Host "  # 3. Inside the SSH session, start ComfyUI:"
Write-Host "  & '$comfyRoot\Launch-ComfyUI.ps1'"
Write-Host ""
Write-Host "NEXT: download model checkpoints to $comfyRoot\ComfyUI\models\checkpoints\"
Write-Host "      Or sync from S3:"
Write-Host "        aws s3 sync s3://ilyrium/apps/comfyui/models/ $comfyRoot\ComfyUI\models\"
Write-Host ""
