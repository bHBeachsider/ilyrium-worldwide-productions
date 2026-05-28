# Ilyrium · GitHub setup · RECOVERY
# ---------------------------------------------------------------
# Why this exists:
#   Step 1's `git add .` silently failed because the .gitignore at
#   that moment didn't exclude apps/comfyui (53K files) and the
#   `Out-Null` pipe swallowed the error. The fix script added the
#   exclusions but couldn't amend a commit that was never actually
#   created.
#
# What this does:
#   - Re-runs git add with the now-complete .gitignore in place
#   - Verifies the index before committing
#   - Makes the initial commit
# ---------------------------------------------------------------

$ErrorActionPreference = "Stop"
Set-Location "C:\Users\bradu\Documents\Ilyrium"

Write-Host "================================================================"
Write-Host "  Ilyrium GitHub setup · RECOVERY"
Write-Host "================================================================"
Write-Host ""

# ---- 1. Verify .gitignore is complete before adding ----
Write-Host "[1/5] Verifying .gitignore exclusions"
$gi = Get-Content .gitignore -Raw
$required = @(
    ".env",
    "aws_info.txt",
    ".venv",
    "films/",
    "scratch/",
    "shared-assets/",
    "apps/davinci-resolve/",
    "apps/comfyui/",
    "apps/igniter/"
)
$missing = @()
foreach ($p in $required) {
    if (-not $gi.Contains($p)) { $missing += $p }
}
if ($missing.Count -gt 0) {
    Write-Host "  Missing patterns in .gitignore — aborting:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    exit 1
}
Write-Host "  OK — all 9 required patterns present" -ForegroundColor Green
Write-Host ""

# ---- 2. Fresh git add (now with full exclusions in place) ----
Write-Host "[2/5] Running git add . (with full .gitignore in effect)"
git add . 2>&1 | Tee-Object -Variable addOutput | Out-Null
if ($addOutput) {
    Write-Host "  git add output:" -ForegroundColor Cyan
    $addOutput | ForEach-Object { Write-Host "    $_" }
}
Write-Host "  done" -ForegroundColor Green
Write-Host ""

# ---- 3. Verify the stage ----
Write-Host "[3/5] Verifying staged files"
$stagedCount = (git diff --cached --name-only | Measure-Object).Count
Write-Host "  Files staged: $stagedCount" -ForegroundColor $(if ($stagedCount -gt 10 -and $stagedCount -lt 500) { "Green" } elseif ($stagedCount -lt 10) { "Yellow" } else { "Yellow" })

if ($stagedCount -lt 10) {
    Write-Host "  WARNING: staged file count looks low — expected 30–100" -ForegroundColor Yellow
    Write-Host "  Aborting before commit. Diagnose with:" -ForegroundColor Yellow
    Write-Host "    git status --short | head -50" -ForegroundColor Yellow
    exit 1
}

if ($stagedCount -gt 500) {
    Write-Host "  WARNING: staged file count is high — some heavy content may have leaked" -ForegroundColor Red
    Write-Host "  Top of staged list (look for large dirs):" -ForegroundColor Red
    git diff --cached --name-only | Select-Object -First 30 | ForEach-Object { Write-Host "    $_" }
    Write-Host "  Aborting before commit. Investigate." -ForegroundColor Red
    exit 1
}

# Show a sample of what's staged
Write-Host "  Sample of staged files:" -ForegroundColor Cyan
git diff --cached --name-only | Select-Object -First 25 | ForEach-Object { Write-Host "    $_" }
if ($stagedCount -gt 25) { Write-Host "    ...and $($stagedCount - 25) more" }
Write-Host ""

# Sensitive-file safety check
$leak = git diff --cached --name-only | Select-String -Pattern "(^\.env$|^\.env\.|aws_info\.txt|apps/davinci-resolve/|apps/comfyui/|apps/igniter/)"
if ($leak) {
    Write-Host "  ABORTING — sensitive or bulk content in stage:" -ForegroundColor Red
    $leak | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    exit 1
}
Write-Host "  Sanity check passed — no sensitive or bulk content staged" -ForegroundColor Green
Write-Host ""

# ---- 4. Commit ----
Write-Host "[4/5] Creating initial commit"

# Configure user if not set (idempotent)
$userName = git config user.name 2>$null
if (-not $userName) {
    git config user.name "Brad Burns"
    git config user.email "4vj6ptzrpj@privaterelay.appleid.com"
    Write-Host "  Set local git user.name/email" -ForegroundColor Cyan
}

# Use explicit error-throwing
& git commit -m "Initial commit: Ilyrium founding documents, tools, Control Panel scaffold"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  git commit failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}
Write-Host "  Committed" -ForegroundColor Green
Write-Host ""

# ---- 5. Verify ----
Write-Host "[5/5] Verification"
$commits = git rev-list --all --count
Write-Host "  Commits: $commits" -ForegroundColor Green
$tracked = (git ls-files | Measure-Object).Count
Write-Host "  Tracked files: $tracked" -ForegroundColor Green

# Estimate push size
$treeSize = git ls-files | ForEach-Object {
    if (Test-Path $_) { (Get-Item $_).Length } else { 0 }
} | Measure-Object -Sum
$totalMB = [math]::Round($treeSize.Sum / 1MB, 2)
Write-Host "  Estimated push size: $totalMB MB" -ForegroundColor $(if ($totalMB -lt 50) { "Green" } else { "Yellow" })
Write-Host ""

git log --oneline
Write-Host ""
Write-Host "================================================================"
Write-Host "  Recovery complete. One clean commit, no leaks." -ForegroundColor Green
Write-Host "================================================================"
Write-Host ""
Write-Host "  Push to GitHub:"
Write-Host "    pwsh -File C:\Users\bradu\Documents\Ilyrium\setup-github-step2.ps1"
