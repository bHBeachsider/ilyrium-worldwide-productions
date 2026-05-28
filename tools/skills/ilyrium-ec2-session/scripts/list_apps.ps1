# list_apps.ps1
# -------------------------------------------------------------------
# Discovers what apps are installed/running on Brad's Ilyrium EC2 GPU
# workstation. Runs LOCALLY - SSHes in and inspects the remote box.
#
# Reports for each known app:
#   - installed?         (Test-Path on canonical install location)
#   - running?           (process check)
#   - port + tunneled?   (only for web-UI apps like ComfyUI)
#   - launch command     (how to start it on EC2)
#   - connect command    (local SSH tunnel + launch shortcut)
#
# Output: structured table + JSON dump to stdout.
#
# Catalog is defined in this script - add new apps by appending to the
# $AppCatalog array below.
# -------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$InstanceId = "i-030994c5371ee5de9",
    [string]$Region = "us-east-1",
    [string]$PemPath = "$env:USERPROFILE\.ssh\ilyrium-ue.pem",
    [switch]$JsonOnly
)

$ErrorActionPreference = "Continue"

# -------------------------------------------------------------------
# CATALOG of known apps on the Ilyrium GPU workstation.
# To register a new app, add an entry here. The remote inspector will
# check Test-Path on install_check and Get-Process on process_name.
# -------------------------------------------------------------------
$AppCatalog = @(
    @{
        name              = "ComfyUI"
        install_check     = "C:\ComfyUI\Launch-ComfyUI.ps1"
        process_name      = "python_embeded"
        web_port          = 8188
        launch_command    = "& 'C:\ComfyUI\Launch-ComfyUI.ps1'"
        description       = "AI image/video generation. Node-based editor."
        web_ui            = $true
    },
    @{
        name              = "Unreal Engine 5.7"
        install_check     = "C:\Program Files\Epic Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe"
        process_name      = "UnrealEditor"
        web_port          = $null
        launch_command    = "& 'C:\Program Files\Epic Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe'"
        description       = "Unreal Engine 5.7 Editor. Full 3D scene + render pipeline."
        web_ui            = $false
    },
    @{
        name              = "Epic Games Launcher"
        install_check     = "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
        process_name      = "EpicGamesLauncher"
        web_port          = $null
        launch_command    = "& 'C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe'"
        description       = "Manages UE installs and Fab marketplace plugins."
        web_ui            = $false
    },
    @{
        name              = "Cesium for Unreal"
        install_check     = "C:\Program Files\Epic Games\UE_5.7\Engine\Plugins\Marketplace\CesiumForUnreal"
        process_name      = $null
        web_port          = $null
        launch_command    = "(plugin loaded inside UE 5.7)"
        description       = "Geospatial tiles plugin for UE. Loaded inside UE editor."
        web_ui            = $false
    },
    @{
        name              = "Quixel Bridge (UE 5.7)"
        install_check     = "C:\Program Files\Epic Games\UE_5.7\Engine\Plugins\Bridge"
        process_name      = $null
        web_port          = $null
        launch_command    = "(plugin loaded inside UE 5.7)"
        description       = "Quixel Megascans asset library inside UE."
        web_ui            = $false
    },
    @{
        name              = "Python (system)"
        install_check     = "C:\Python311\python.exe"
        process_name      = $null
        web_port          = $null
        launch_command    = "python --version"
        description       = "Python 3.11 for scripting. Pip-managed."
        web_ui            = $false
    },
    @{
        name              = "AWS CLI"
        install_check     = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
        process_name      = $null
        web_port          = $null
        launch_command    = "aws --version"
        description       = "AWS CLI v2 for S3 + EC2 management from the instance itself."
        web_ui            = $false
    },
    @{
        name              = "Git"
        install_check     = "C:\Program Files\Git\bin\git.exe"
        process_name      = $null
        web_port          = $null
        launch_command    = "git --version"
        description       = "Git CLI for cloning Ilyrium script repos."
        web_ui            = $false
    },
    @{
        name              = "FFmpeg"
        install_check     = "C:\ProgramData\chocolatey\bin\ffmpeg.exe"
        process_name      = $null
        web_port          = $null
        launch_command    = "ffmpeg -version"
        description       = "Video encoding/transcoding (GPU-accelerated)."
        web_ui            = $false
    },
    @{
        name              = "7-Zip"
        install_check     = "C:\Program Files\7-Zip\7z.exe"
        process_name      = $null
        web_port          = $null
        launch_command    = "7z"
        description       = "Archive handler (used for ComfyUI portable extraction etc.)."
        web_ui            = $false
    }
)

# -------------------------------------------------------------------
# Step 1: verify EC2 is reachable
# -------------------------------------------------------------------
$state = aws ec2 describe-instances --region $Region --instance-ids $InstanceId `
    --query 'Reservations[0].Instances[0].State.Name' --output text 2>$null
if ($state -ne "running") {
    if (-not $JsonOnly) {
        Write-Host "EC2 is '$state'. Start it first:"
        Write-Host "  pwsh $PSScriptRoot\start_session.ps1"
    } else {
        Write-Output (@{ error = "EC2 not running"; state = $state } | ConvertTo-Json -Compress)
    }
    return
}

$publicIp = aws ec2 describe-instances --region $Region --instance-ids $InstanceId `
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# -------------------------------------------------------------------
# Step 2: build remote inspector script and run via SSH
# -------------------------------------------------------------------
# Build a JSON-emitting PowerShell snippet that runs ON the EC2.
# We pass the catalog as serialized JSON and the snippet parses it,
# then probes each entry and emits results.

$catalogJson = ($AppCatalog | ConvertTo-Json -Compress -Depth 5).Replace('"', '\"')

$remoteScript = @"
`$catalog = '$catalogJson' | ConvertFrom-Json
`$results = @()
foreach (`$app in `$catalog) {
    `$installed = Test-Path `$app.install_check
    `$running = `$false
    if (`$app.process_name) {
        `$proc = Get-Process -Name `$app.process_name -ErrorAction SilentlyContinue
        `$running = (`$proc -ne `$null)
    }
    `$portListening = `$false
    if (`$app.web_port) {
        try {
            `$portListening = (Get-NetTCPConnection -LocalPort `$app.web_port -State Listen -ErrorAction SilentlyContinue) -ne `$null
        } catch { `$portListening = `$false }
    }
    `$results += [PSCustomObject]@{
        name = `$app.name
        installed = `$installed
        running = `$running
        port_listening = `$portListening
        port = `$app.web_port
    }
}
`$results | ConvertTo-Json -Compress
"@

# Run on EC2 via SSH. Output is one line of JSON.
$remoteOutput = ssh -i $PemPath -o StrictHostKeyChecking=no -o LogLevel=ERROR `
    "Administrator@$publicIp" "powershell -NoProfile -Command `"$remoteScript`""

if (-not $remoteOutput) {
    Write-Error "SSH inspector returned no output. Check the SSH connection."
    return
}

try {
    $remoteResults = $remoteOutput | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse remote output as JSON: $remoteOutput"
    return
}

# -------------------------------------------------------------------
# Step 3: merge with catalog metadata + render
# -------------------------------------------------------------------
$merged = foreach ($app in $AppCatalog) {
    $remote = $remoteResults | Where-Object { $_.name -eq $app.name } | Select-Object -First 1
    [PSCustomObject]@{
        name           = $app.name
        installed      = if ($remote) { $remote.installed } else { $null }
        running        = if ($remote) { $remote.running } else { $null }
        port_listening = if ($remote) { $remote.port_listening } else { $null }
        port           = $app.web_port
        web_ui         = $app.web_ui
        description    = $app.description
        launch_command = $app.launch_command
    }
}

if ($JsonOnly) {
    $merged | ConvertTo-Json -Depth 5
    return
}

# Human-readable rendering
Write-Host "================================================================"
Write-Host "  Ilyrium EC2 - APPS DISCOVERY"
Write-Host "  Instance: $InstanceId    Public IP: $publicIp"
Write-Host "================================================================"
Write-Host ""

foreach ($app in $merged) {
    if ($app.installed -eq $true) {
        $marker = "[OK]   "
    } elseif ($app.installed -eq $false) {
        $marker = "[MISS] "
    } else {
        $marker = "[??]   "
    }

    Write-Host "$marker$($app.name)"
    Write-Host "       $($app.description)"

    if ($app.running) {
        if ($app.web_ui -and $app.port_listening) {
            Write-Host "       Status: RUNNING (web UI on port $($app.port), tunnel via SSH -L)"
        } elseif ($app.web_ui) {
            Write-Host "       Status: RUNNING (web UI, port $($app.port) but not currently listening?)"
        } else {
            Write-Host "       Status: RUNNING"
        }
    } elseif ($app.installed) {
        if ($app.web_ui) {
            Write-Host "       Status: installed, not running (web UI port $($app.port))"
            Write-Host "       Launch: $($app.launch_command)"
        } elseif ($app.launch_command -like "(plugin*") {
            # Plugin - no separate launch
        } else {
            Write-Host "       Status: installed, not running"
            Write-Host "       Launch: $($app.launch_command)"
        }
    }
    Write-Host ""
}

Write-Host "================================================================"
Write-Host "  To launch a web-UI app via tunnel from your local PC:"
Write-Host "  pwsh $PSScriptRoot\connect_comfyui.ps1   (or similar for other apps)"
Write-Host "================================================================"
