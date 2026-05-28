# Ilyrium · GitHub setup · FIX
# ---------------------------------------------------------------
# Discovered in audit: apps/davinci-resolve (20.5 GB), apps/igniter
# (8.7 GB), and apps/comfyui (5.6 GB) were included in the initial
# commit. None of them should be in a public git repo.
#
# This script:
#   1. Appends explicit exclusions to .gitignore
#   2. Removes the bulk apps content from the git index (keeps files on disk)
#   3. Amends the existing commit
#   4. Shows the new tracked-file inventory
# ---------------------------------------------------------------

$ErrorActionPreference = "Stop"
Set-Location "C:\Users\bradu\Documents\Ilyrium"

Write-Host "================================================================"
Write-Host "  Ilyrium GitHub setup · FIX (untrack heavy apps, amend commit)"
Write-Host "================================================================"
Write-Host ""

# ---- 1. Append .gitignore additions ----
Write-Host "[1/5] Appending .gitignore exclusions for heavy apps"
$additions = @"

# ----- Heavy apps — excluded from git (canonical storage = R2/S3 per Phase A) -----
# DaVinci Resolve operates on local SSD for editing performance — working media
# stays on disk, finished masters move to R2 in COO Plan task A1.2.
apps/davinci-resolve/
apps/comfyui/
apps/igniter/

# UE engine caches (in case any UE project gets bigger later)
apps/**/Saved/
apps/**/Intermediate/
apps/**/DerivedDataCache/
apps/**/Binaries/

# Blender autosaves
apps/**/*.blend1
apps/**/*.blend2
"@
Add-Content -Path ".gitignore" -Value $additions -NoNewline
Write-Host "  Appended 11 patterns" -ForegroundColor Green
Write-Host ""

# ---- 2. Remove bulk apps content from the index ----
Write-Host "[2/5] Untracking bulk content from git index (files stay on disk)"
foreach ($p in @("apps/davinci-resolve", "apps/comfyui", "apps/igniter")) {
    if (Test-Path $p) {
        git rm -r --cached --quiet $p 2>&1 | Out-Null
        Write-Host "  untracked: $p" -ForegroundColor Cyan
    }
}
git add .gitignore | Out-Null
Write-Host ""

# ---- 3. Show what's about to be amended ----
Write-Host "[3/5] Current index after exclusions"
$count = (git ls-files | Measure-Object).Count
Write-Host "  Tracked files now: $count" -ForegroundColor Green
Write-Host "  Top 30 tracked files:"
git ls-files | Select-Object -First 30 | ForEach-Object { Write-Host "    $_" }
if ($count -gt 30) {
    Write-Host "    ...and $($count - 30) more"
}
Write-Host ""

# ---- 4. Amend the commit ----
Write-Host "[4/5] Amending the existing commit"
git commit --amend --no-edit | Out-Null
Write-Host "  Amended" -ForegroundColor Green
Write-Host ""

# ---- 5. Final sanity checks ----
Write-Host "[5/5] Sanity checks"

# Confirm no .env or aws_info
$leak = git ls-files | Select-String -Pattern "(^\.env$|^\.env\.|aws_info\.txt)"
if ($leak) {
    Write-Host "  WARNING: sensitive file still tracked:" -ForegroundColor Red
    $leak | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
} else {
    Write-Host "  OK — no .env / aws_info.txt tracked" -ForegroundColor Green
}

# Confirm no davinci/comfyui/igniter
$bulk = git ls-files | Select-String -Pattern "apps/(davinci-resolve|comfyui|igniter)/"
if ($bulk) {
    Write-Host "  WARNING: bulk content still tracked:" -ForegroundColor Red
    $bulk | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    Write-Host "  ($($bulk.Count) total — fix not applied correctly)" -ForegroundColor Red
} else {
    Write-Host "  OK — apps/davinci-resolve, apps/comfyui, apps/igniter NOT tracked" -ForegroundColor Green
}

# Confirm control-panel + key files ARE tracked
$expected = @("apps/control-panel/package.json", "apps/control-panel/app/page.tsx", "apps/control-panel/db/migrations/0001_studio_os_spine.sql", "README.md", ".gitignore")
foreach ($f in $expected) {
    $f_unix = $f -replace "\\", "/"
    $tracked = git ls-files $f_unix
    if ($tracked) {
        Write-Host "  OK — tracked: $f_unix" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: missing from index: $f_unix" -ForegroundColor Yellow
    }
}

# Commit size estimate (tree size)
$treeSize = git ls-files | ForEach-Object {
    if (Test-Path $_) { (Get-Item $_).Length } else { 0 }
} | Measure-Object -Sum
$totalMB = [math]::Round($treeSize.Sum / 1MB, 2)
Write-Host ""
Write-Host "  Estimated push size: $totalMB MB" -ForegroundColor $(if ($totalMB -lt 100) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "================================================================"
Write-Host "  Fix complete. Ready to push."
Write-Host "================================================================"
Write-Host ""
Write-Host "  Inspect what's in the commit:"
Write-Host "    git show --stat HEAD | head -40"
Write-Host ""
Write-Host "  When you're satisfied, run step 2 to push:"
Write-Host "    pwsh -File C:\Users\bradu\Documents\Ilyrium\setup-github-step2.ps1"
