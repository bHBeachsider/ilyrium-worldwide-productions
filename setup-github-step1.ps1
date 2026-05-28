# Ilyrium · GitHub setup · Step 1 of 2
# ---------------------------------------------------------------
# What this does:
#   - Audits the folder and lists sensitive files
#   - Creates a strong .gitignore (won't overwrite if present)
#   - Creates a README.md (won't overwrite if present)
#   - git init + initial commit — LOCAL ONLY, no push yet
# What this DOESN'T do:
#   - Add a remote
#   - Push anything to GitHub
# Review the commit before running step 2.

$ErrorActionPreference = "Stop"
$RepoPath = "C:\Users\bradu\Documents\Ilyrium"
Set-Location $RepoPath

Write-Host "================================================================"
Write-Host "  Ilyrium GitHub setup · Step 1 of 2 · LOCAL COMMIT ONLY"
Write-Host "================================================================"
Write-Host ""

# ---- Audit ----
Write-Host "[1/6] Folder audit"
Write-Host "  Path: $RepoPath"
Write-Host ""
Write-Host "  Subdirectory sizes:"
Get-ChildItem -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $mb = [math]::Round($size / 1MB, 1)
    Write-Host ("    {0,-25} {1,10:N1} MB" -f $_.Name, $mb)
}
Write-Host ""

$sensitive = @(".env", "aws_info.txt")
Write-Host "  Sensitive files detected (these WILL be excluded):"
foreach ($f in $sensitive) {
    if (Test-Path $f) {
        $bytes = (Get-Item $f).Length
        Write-Host ("    [SENSITIVE] {0} ({1} bytes)" -f $f, $bytes) -ForegroundColor Yellow
    }
}
Write-Host ""

# ---- .gitignore ----
Write-Host "[2/6] .gitignore"
if (Test-Path ".gitignore") {
    Write-Host "  .gitignore exists — leaving it alone (review it before commit)" -ForegroundColor Cyan
} else {
    $gitignore = @'
# ----- Secrets — NEVER commit -----
.env
.env.*
*.env.local
*.pem
*.key
**/credentials
**/secrets/
aws_info.txt

# ----- Python -----
.venv/
venv/
env/
__pycache__/
*.pyc
*.pyo
*.egg-info/
.pytest_cache/
.mypy_cache/

# ----- Node -----
node_modules/
.next/
.vercel/
dist/
build/
*.log
npm-debug.log*
yarn-debug.log*

# ----- Large media (default-excluded; opt back in case by case) -----
films/
scratch/
archive/
shared-assets/
*.mp4
*.mov
*.avi
*.mkv
*.exr
*.dpx
*.tif
*.tiff
*.raw
*.psd
*.psb
*.blend1
*.blend2
*.fbx
*.obj
*.usd
*.uasset

# ----- 3D / Game engine caches -----
Saved/
Intermediate/
DerivedDataCache/
Binaries/

# ----- OS / IDE -----
.DS_Store
Thumbs.db
desktop.ini
*.swp
*~
.vscode/
.idea/

# ----- Build artifacts -----
out/
output/
exports/
tmp/
'@
    $gitignore | Out-File -FilePath ".gitignore" -Encoding utf8 -NoNewline
    Write-Host "  Created .gitignore" -ForegroundColor Green
}
Write-Host ""

# ---- README ----
Write-Host "[3/6] README.md"
if (Test-Path "README.md") {
    Write-Host "  README.md exists — leaving it alone" -ForegroundColor Cyan
} else {
    $readme = @'
# Ilyrium Worldwide Productions

AI-native filmmaking studio. Original IP, audience-validated, control-plane architected.

## Active projects

- **New Harmony** — civic-satire universe (Mayor Pengold cycle)
- **Kathy Flyover** — first recurring character / velocity-test IP

## Studio operating documents

- 90-Day Implementation Plan (founding architecture)
- COO Implementation Plan (phased, tasked)
- Tool Inventory & Agentic-Stack Ownership Map
- Control Panel + Orchestration Layer Design

## Repo layout

```
apps/             # Studio OS / Control Panel app code
tools/            # CLI scripts, skill bundles, automation
requirements.txt  # Python dependencies
```

Large media, renders, and secrets are excluded via .gitignore.
'@
    $readme | Out-File -FilePath "README.md" -Encoding utf8 -NoNewline
    Write-Host "  Created README.md" -ForegroundColor Green
}
Write-Host ""

# ---- git init ----
Write-Host "[4/6] git init"
if (Test-Path ".git") {
    Write-Host "  .git already exists — skipping init" -ForegroundColor Cyan
} else {
    git init | Out-Null
    git branch -M main
    Write-Host "  Initialized empty repo on branch 'main'" -ForegroundColor Green
}
Write-Host ""

# ---- Stage and preview ----
Write-Host "[5/6] Staging files"
git add . 2>&1 | Out-Null
Write-Host ""
Write-Host "  Files about to be committed:"
git status --short
Write-Host ""
Write-Host "  Sanity check — searching staged files for the word 'env':"
$envFiles = git ls-files --cached | Select-String -Pattern "\.env"
if ($envFiles) {
    Write-Host "  WARNING: .env-like files found in stage!" -ForegroundColor Red
    $envFiles | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
} else {
    Write-Host "  OK — no .env files staged" -ForegroundColor Green
}
$awsFile = git ls-files --cached | Select-String -Pattern "aws_info"
if ($awsFile) {
    Write-Host "  WARNING: aws_info.txt staged!" -ForegroundColor Red
} else {
    Write-Host "  OK — aws_info.txt not staged" -ForegroundColor Green
}
Write-Host ""

# ---- Commit ----
Write-Host "[6/6] Initial commit"
$existingCommits = git rev-list --count HEAD 2>$null
if ($existingCommits -and $existingCommits -gt 0) {
    Write-Host "  Repo already has commits — skipping initial commit" -ForegroundColor Cyan
} else {
    # Configure user if not set
    $userName = git config user.name 2>$null
    if (-not $userName) {
        git config user.name "Brad Burns"
        git config user.email "4vj6ptzrpj@privaterelay.appleid.com"
        Write-Host "  Set local git user (using AppleID privaterelay email)" -ForegroundColor Cyan
    }
    git commit -m "Initial commit: Ilyrium founding documents, tools, and structure" | Out-Null
    Write-Host "  Committed locally" -ForegroundColor Green
}
Write-Host ""

Write-Host "================================================================"
Write-Host "  Step 1 complete. Local commit is done. Nothing has been pushed."
Write-Host "================================================================"
Write-Host ""
Write-Host "  Review the commit:"
Write-Host "    git log --oneline"
Write-Host "    git show --stat HEAD"
Write-Host ""
Write-Host "  When ready to push to GitHub, run step 2:"
Write-Host "    pwsh C:\Users\bradu\Documents\Ilyrium\setup-github-step2.ps1"
Write-Host ""
