# Ilyrium · GitHub setup · Step 2 of 2
# ---------------------------------------------------------------
# Adds the GitHub remote and pushes the local 'main' branch.
# Run ONLY after step 1 has completed and you've reviewed the commit.
#
# Authentication: uses HTTPS. On first push, Git Credential Manager
# will open a browser to authenticate with GitHub. Sign in as
# bHBeachsider when prompted.
# ---------------------------------------------------------------

$ErrorActionPreference = "Stop"
$RepoPath = "C:\Users\bradu\Documents\Ilyrium"
$RemoteUrl = "https://github.com/bHBeachsider/ilyrium-worldwide-productions.git"

Set-Location $RepoPath

Write-Host "================================================================"
Write-Host "  Ilyrium GitHub setup · Step 2 of 2 · PUSH TO PUBLIC REPO"
Write-Host "================================================================"
Write-Host ""
Write-Host "  Target: $RemoteUrl"
Write-Host "  Repo visibility: PUBLIC (world-readable)" -ForegroundColor Yellow
Write-Host ""

# ---- Preflight: must be a repo with a commit ----
if (-not (Test-Path ".git")) {
    Write-Error "No .git folder. Run step 1 first."
    exit 1
}
$commitCount = git rev-list --count HEAD 2>$null
if (-not $commitCount -or [int]$commitCount -lt 1) {
    Write-Error "No commits yet. Run step 1 first."
    exit 1
}
Write-Host "[1/4] Preflight OK — $commitCount commit(s) ready to push" -ForegroundColor Green
Write-Host ""

# ---- Final sanity check — no .env in staged history ----
Write-Host "[2/4] Final sanity check on history for sensitive files"
$leak = git log --all --pretty=format: --name-only --diff-filter=A | Select-String -Pattern "(^\.env$|^\.env\.|aws_info\.txt)"
if ($leak) {
    Write-Host "  ABORTING — sensitive file in commit history:" -ForegroundColor Red
    $leak | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "  Fix locally first (git rm --cached + amend / rebase), then re-run step 2." -ForegroundColor Red
    exit 1
}
Write-Host "  OK — no .env / aws_info.txt in commit history" -ForegroundColor Green
Write-Host ""

# ---- Add remote ----
Write-Host "[3/4] Configuring remote 'origin'"
$existing = git remote get-url origin 2>$null
if ($existing) {
    if ($existing -eq $RemoteUrl) {
        Write-Host "  origin already set correctly: $existing" -ForegroundColor Cyan
    } else {
        Write-Host "  Updating origin from $existing to $RemoteUrl" -ForegroundColor Yellow
        git remote set-url origin $RemoteUrl
    }
} else {
    git remote add origin $RemoteUrl
    Write-Host "  Added origin → $RemoteUrl" -ForegroundColor Green
}
Write-Host ""

# ---- Push ----
Write-Host "[4/4] Pushing 'main' to GitHub"
Write-Host "  (A browser may open for GitHub authentication on first push.)" -ForegroundColor Cyan
Write-Host ""
git push -u origin main
$exit = $LASTEXITCODE

Write-Host ""
if ($exit -eq 0) {
    Write-Host "================================================================"
    Write-Host "  Push successful." -ForegroundColor Green
    Write-Host "  View at: https://github.com/bHBeachsider/ilyrium-worldwide-productions"
    Write-Host "================================================================"
    Write-Host ""
    Write-Host "  Next: switch back to the Vercel tab and click Deploy."
    Write-Host "  See setup-vercel-notes.md in this folder for what to expect."
} else {
    Write-Host "================================================================"
    Write-Host "  Push FAILED (exit code $exit)." -ForegroundColor Red
    Write-Host "================================================================"
    Write-Host ""
    Write-Host "  Common fixes:"
    Write-Host "    1. Auth failed → re-run; Git Credential Manager should re-prompt."
    Write-Host "    2. Remote rejected (non-empty repo) → run:"
    Write-Host "         git pull origin main --allow-unrelated-histories"
    Write-Host "       resolve conflicts, then re-run this script."
    Write-Host "    3. Branch mismatch → check 'git branch' shows main."
}
